import os
import logging
from dataclasses import dataclass

def get_env(key: str, default: str = "") -> str:
    return os.getenv(key, default).strip()

@dataclass
class BaseConfig:
    source_name: str
    kafka_bootstrap_servers: str
    kafka_topic: str
    kafka_dlq_topic: str
    poll_interval_seconds: int
    batch_size: int
    state_backend: str
    consul_http_addr: str
    log_level: str

    @classmethod
    def from_env(cls, source_name: str) -> "BaseConfig":
        return cls(
            source_name=source_name,
            kafka_bootstrap_servers=get_env("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092"),
            kafka_topic=get_env("KAFKA_TOPIC", f"extractions.{source_name}"),
            kafka_dlq_topic=get_env("KAFKA_DLQ_TOPIC", "extractions.dlq"),
            poll_interval_seconds=int(get_env("POLL_INTERVAL_SECONDS", "60")),
            batch_size=int(get_env("BATCH_SIZE", "100")),
            state_backend=get_env("STATE_BACKEND", "file"), # 'file' or 'consul'
            consul_http_addr=get_env("CONSUL_HTTP_ADDR", "http://127.0.0.1:8500"),
            log_level=get_env("LOG_LEVEL", "INFO")
        )

def setup_logger(name: str, level: str = "INFO") -> logging.Logger:
    logger = logging.getLogger(name)
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            "[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    logger.setLevel(getattr(logging, level.upper(), logging.INFO))
    return logger
