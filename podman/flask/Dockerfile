FROM python:3.14-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
        netcat-openbsd curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir uv

# Dependencies (frozen lock) first, for layer caching.
COPY pyproject.toml uv.lock README.md ./
RUN uv sync --no-dev --frozen --no-install-project

# Application code.
COPY tmc ./tmc
COPY theMetaCity.py ./
RUN uv sync --no-dev --frozen

COPY podman/flask/gunicorn.conf.py ./
COPY podman/flask/entrypoint.sh ./
RUN chmod +x entrypoint.sh

ENV FLASK_APP=theMetaCity.py
ENV FLASK_ENV=production
ENV UV_NO_SYNC=1
ENV PGPASSFILE=/app/.pgpass

EXPOSE 5000
ENTRYPOINT ["./entrypoint.sh"]
