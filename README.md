# Private Law Society Nostr Relay

This repository contains the code and infrastructure configuration for the production backup relay used by the Private Law Society project.

## Purpose

The relay stores the Nostr events the project needs to retain:

- Kind `0` events contain user profile data.
- Kind `30078` events contain application-specific data, currently used for ratings.

These events contribute to the project's Web of Trust (WoT) table and graph search.
The relay exists as a backup because the project previously lost data when every relay in its group pruned older events.
Keeping a dedicated relay helps prevent that loss from happening again.

The deployment uses Azure resources to keep the initial infrastructure cost low.
Azure's pay-as-you-go billing lets the relay and database scale to zero while idle, while Azure Files preserves the database data.

## Configuration

[`config.toml`](config.toml) is the Jinja template for the relay's runtime configuration.
The Dockerfile copies it into the image as `/usr/src/app/config.toml.template`, so the template is present at image build time.

When the container starts, [`docker-entrypoint.sh`](docker-entrypoint.sh) runs [`render_config.py`](render_config.py).
The renderer applies the container's environment variables to the Jinja template and writes the interpreted configuration to `/usr/src/app/config.toml`; the entrypoint then starts the relay.
String values are encoded as TOML strings, and numeric settings are converted to integers by the template.

The template configures the relay to accept only event kinds `0` and `30078`.
The values used to render it include the relay URL, name and description, database URL, listening port, future-event limit, and per-minute subscription limit.
Development defaults are in [`.env.example`](.env.example).

## Run in development

Docker Compose starts the relay and its Postgres database locally:

```sh
cp .env.example .env
docker compose up --build
```

The relay is available at `ws://localhost:8080/` by default.
Set `RELAY_HOST_PORT` in `.env` to change the host port.
To stop the services, run:

```sh
docker compose down
```

Compose keeps Postgres data in a named Docker volume.
Running `docker compose down` preserves that volume; `docker compose down -v` removes it and its data.

## Azure deployment

The [`terraform/`](terraform/) directory provisions the production Azure Container Apps environment, relay, Postgres container, and Azure Files storage.
See [`terraform/README.md`](terraform/README.md) for image publishing and deployment instructions.
