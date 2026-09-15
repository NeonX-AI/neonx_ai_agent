FROM openclaw/openclaw:2026.9.4

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends python3.11-venv \
 && rm -rf /var/lib/apt/lists/*