import json
import time
from typing import Any, Dict, Optional
from .config import setup_logger

logger = setup_logger("KafkaProducer")

class ResilientKafkaProducer:
    """
    Resilient Kafka producer supporting JSON serialization, retry backoff,
    dead-letter queuing (DLQ), and local fallback simulation.
    """

    def __init__(self, bootstrap_servers: str, default_topic: str, dlq_topic: str = "extractions.dlq"):
        self.bootstrap_servers = bootstrap_servers
        self.default_topic = default_topic
        self.dlq_topic = dlq_topic
        self.producer = None
        self._init_producer()

    def _init_producer(self):
        try:
            from kafka import KafkaProducer # kafka-python
            self.producer = KafkaProducer(
                bootstrap_servers=self.bootstrap_servers.split(","),
                value_serializer=lambda v: json.dumps(v, default=str).encode("utf-8"),
                key_serializer=lambda k: str(k).encode("utf-8") if k else None,
                acks="all",
                retries=5,
                retry_backoff_ms=500,
                max_in_flight_requests_per_connection=1
            )
            logger.info(f"Connected to Kafka broker(s) at {self.bootstrap_servers}")
        except Exception as e:
            logger.warning(
                f"Could not connect to live Kafka broker at {self.bootstrap_servers}: {e}. "
                "Running in simulated producer mode (events logged locally)."
            )
            self.producer = None

    def publish(self, record: Dict[str, Any], key: Optional[str] = None, topic: Optional[str] = None) -> bool:
        target_topic = topic or self.default_topic
        payload = {
            "timestamp_utc": time.time(),
            "source_topic": target_topic,
            "data": record
        }

        if self.producer:
            try:
                future = self.producer.send(target_topic, key=key, value=payload)
                self.producer.flush()
                logger.debug(f"Published record {key} to {target_topic}")
                return True
            except Exception as exc:
                logger.error(f"Failed to publish record to {target_topic}: {exc}. Routing to DLQ.")
                return self._send_to_dlq(payload, error=str(exc))
        else:
            # Simulated mode
            logger.info(f"[SIMULATED KAFKA] -> Topic: {target_topic} | Key: {key} | Record: {json.dumps(record)[:120]}...")
            return True

    def _send_to_dlq(self, payload: Dict[str, Any], error: str) -> bool:
        dlq_record = {
            "failed_payload": payload,
            "error_reason": error,
            "failed_at": time.time()
        }
        if self.producer:
            try:
                self.producer.send(self.dlq_topic, value=dlq_record)
                self.producer.flush()
                logger.warning(f"Successfully routed failed record to DLQ: {self.dlq_topic}")
                return True
            except Exception as dlq_err:
                logger.critical(f"FATAL: Could not even route record to DLQ: {dlq_err}")
                return False
        return True

    def flush(self):
        if self.producer:
            self.producer.flush()

    def close(self):
        if self.producer:
            self.producer.close()
            logger.info("Kafka producer closed.")
