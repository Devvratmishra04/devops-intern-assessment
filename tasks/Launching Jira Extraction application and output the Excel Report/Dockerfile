# ── Jira Extraction Application ──────────────────────────────
# Multi-stage build – lean production image
# Base: python:3.12-slim  |  Non-root user  |  Volume: /app/output
# ─────────────────────────────────────────────────────────────

FROM python:3.12-slim AS base

# Prevent Python from writing .pyc files and enable unbuffered stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create a non-root application user
RUN groupadd --gid 1000 appgroup && \
    useradd  --uid 1000 --gid appgroup --shell /bin/bash --create-home appuser

WORKDIR /app

# Install dependencies first (layer caching optimisation)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY jira_extraction.py .
COPY config.json .

# Create output directory and give ownership to appuser
RUN mkdir -p /app/output && chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Persistent volume for generated Excel reports
VOLUME ["/app/output"]

# Health-check: verify the script can at least parse arguments
HEALTHCHECK --interval=60s --timeout=10s --retries=3 \
    CMD python jira_extraction.py --help > /dev/null 2>&1 || exit 1

# Default entrypoint – runs the extraction with any CLI args passed at runtime
ENTRYPOINT ["python", "jira_extraction.py"]
CMD []
