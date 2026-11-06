FROM scsibug/nostr-rs-relay:latest

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --break-system-packages --no-cache-dir -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

COPY render_config.py /usr/local/bin/render_config.py
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY config.toml /usr/src/app/config.toml.template
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

WORKDIR /usr/src/app
USER $APP_USER
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/sh", "-c", "exec ./nostr-rs-relay --db \"$APP_DATA\""]
