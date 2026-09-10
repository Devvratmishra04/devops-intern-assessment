import json
import os
import urllib.request
from typing import Any, Optional
from .config import setup_logger

logger = setup_logger("StateStore")

class StateStore:
    """
    Manages extraction checkpoint state (delta tokens, last synced timestamp, cursor).
    Supports either Consul KV storage or local JSON file storage.
    """

    def __init__(self, source_name: str, backend: str = "file", consul_addr: str = "http://127.0.0.1:8500"):
        self.source_name = source_name
        self.backend = backend.lower()
        self.consul_addr = consul_addr.rstrip("/")
        self.local_file = f"/tmp/{source_name}_state.json" if os.name != "nt" else f"C:/tmp/{source_name}_state.json"
        self._ensure_local_dir()

    def _ensure_local_dir(self):
        dirpath = os.path.dirname(self.local_file)
        if dirpath and not os.path.exists(dirpath):
            os.makedirs(dirpath, exist_ok=True)

    def get_cursor(self, key: str = "last_cursor", default: Any = None) -> Any:
        if self.backend == "consul":
            try:
                url = f"{self.consul_addr}/v1/kv/extractions/{self.source_name}/{key}?raw"
                req = urllib.request.Request(url)
                with urllib.request.urlopen(req, timeout=3) as resp:
                    if resp.status == 200:
                        val = resp.read().decode("utf-8")
                        return json.loads(val) if val.startswith("{") or val.startswith("[") else val
            except Exception:
                logger.debug(f"Consul KV key for {self.source_name}/{key} not found or unreachable. Falling back to local.")

        # Local file fallback
        if os.path.exists(self.local_file):
            try:
                with open(self.local_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    return data.get(key, default)
            except Exception as e:
                logger.warning(f"Error reading local state file: {e}")
        return default

    def set_cursor(self, key: str, value: Any):
        # 1. Update local state
        state = {}
        if os.path.exists(self.local_file):
            try:
                with open(self.local_file, "r", encoding="utf-8") as f:
                    state = json.load(f)
            except Exception:
                state = {}
        state[key] = value
        try:
            with open(self.local_file, "w", encoding="utf-8") as f:
                json.dump(state, f, indent=2, default=str)
        except Exception as e:
            logger.warning(f"Failed to persist state locally: {e}")

        # 2. Update Consul KV if enabled
        if self.backend == "consul":
            try:
                url = f"{self.consul_addr}/v1/kv/extractions/{self.source_name}/{key}"
                val_str = json.dumps(value) if isinstance(value, (dict, list)) else str(value)
                req = urllib.request.Request(url, data=val_str.encode("utf-8"), method="PUT")
                with urllib.request.urlopen(req, timeout=3) as resp:
                    if resp.status == 200:
                        logger.debug(f"Updated Consul KV state for {self.source_name}/{key}")
            except Exception as e:
                logger.debug(f"Could not persist to Consul KV ({e}). Local copy retained.")
