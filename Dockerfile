FROM python:3.13.5-slim

ENV PYTHONDONTWRITEBYTECODE="1"
ENV PYTHONUNBUFFERED="1"
ENV PORT="8080"

WORKDIR /mediaflow_proxy

RUN useradd -m mediaflow_proxy
RUN chown -R mediaflow_proxy:mediaflow_proxy /mediaflow_proxy

# Install Poetry secara global
RUN pip install --no-cache-dir poetry

# Tetap set PATH untuk keamanan (optional jika global install sudah benar)
ENV PATH="/usr/local/bin:$PATH"

# Copy only requirements untuk cache
COPY --chown=mediaflow_proxy:mediaflow_proxy pyproject.toml poetry.lock* /mediaflow_proxy/

# Switch ke user non-root
USER mediaflow_proxy

RUN poetry config virtualenvs.in-project true \
    && poetry install --no-interaction --no-ansi --no-root --only main

COPY --chown=mediaflow_proxy:mediaflow_proxy . /mediaflow_proxy

EXPOSE 8080

CMD ["sh", "-c", "exec poetry run gunicorn mediaflow_proxy.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8888 --timeout 120 --max-requests 500 --max-requests-jitter 200 --access-logfile - --error-logfile - --log-level info --forwarded-allow-ips \"${FORWARDED_ALLOW_IPS:-127.0.0.1}\""]
