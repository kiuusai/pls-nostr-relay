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

## Run the published Docker image

The published image is [`docker.io/kiuusai/pls-nostr-rs-relay`](https://hub.docker.com/r/kiuusai/pls-nostr-rs-relay).
It requires a reachable PostgreSQL database.
Supply its connection URL and the relay settings as environment variables:

```sh
docker run --rm \
  --name pls-nostr-relay \
  --restart unless-stopped \
  --publish 8080:8080 \
  --env DATABASE_URL='postgresql://nostr:password@<database-host>:5432/nostr' \
  docker.io/kiuusai/pls-nostr-rs-relay
```

Replace `<database-host>` with a hostname or IP reachable from the container.
Set `RELAY_URL` to the relay's externally reachable WebSocket URL when using a public host; its default is `ws://localhost:8080/`, intended for local use.
The command publishes port 8080; change both sides of `--publish` and `RELAY_PORT` together to use another container port.
The image does not start PostgreSQL or persist database storage, so configure and operate the database separately.

## Relay environment variables

The image renders these variables into the relay's `config.toml` at startup:

| Variable                | Purpose                                                                                            | Example / default                                                                                  |
| ----------------------- | -------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `DATABASE_URL`          | PostgreSQL connection URL (`[database].connection`).                                               | Required; for example `postgresql://nostr:password@db.example:5432/nostr`                          |
| `RELAY_URL`             | WebSocket URL advertised by the relay (`[info].relay_url`).                                        | Optional; `ws://localhost:8080/`                                                                   |
| `RELAY_NAME`            | Relay name shown to clients (`[info].name`).                                                       | Optional; `Private Law Society Nostr relay`                                                        |
| `RELAY_DESCRIPTION`     | Relay description shown to clients (`[info].description`).                                         | Optional; `Private Law Society Nostr relay.`                                                       |
| `RELAY_PORT`            | Port the relay listens on inside the container (`[network].port`).                                 | Optional; `8080`                                                                                   |
| `REJECT_FUTURE_SECONDS` | Maximum number of seconds an event may be dated in the future (`[options].reject_future_seconds`). | Optional; `1800`                                                                                   |
| `SUBSCRIPTIONS_PER_MIN` | Subscription limit per client per minute (`[limits].subscriptions_per_min`).                       | Optional; `0` in the image template if unset (no configured limit); `.env.example` sets it to `10` |

The allowed event kinds are fixed in the template to `0` and `30078`; they are not environment variables.

## Build your own image

From the repository root, build the image and tag it with a name and version of your choice:

```sh
docker build --tag pls-nostr-rs-relay:local .
```

Run it the same way as the published image, replacing the image name with your local tag:

```sh
docker run --rm --detach \
  --name pls-nostr-relay \
  --publish 8080:8080 \
  --env DATABASE_URL='postgresql://nostr:password@<database-host>:5432/nostr' \
  pls-nostr-rs-relay:local
```

Replace `<database-host>` with a PostgreSQL hostname or IP reachable from the container.
The image uses the optional setting defaults listed above.
For a local relay and database, use `docker compose up --build` as described in [Run in development](#run-in-development).

## Publish an image with GitHub Actions

The [Publish Docker image workflow](.github/workflows/publish-image.yml) builds and pushes the image to Docker Hub when a GitHub release is published or edited.
Configure these repository settings before publishing a release:

- Actions variable `DOCKERHUB_USERNAME`: Docker Hub account or organization that owns the image.
- Actions variable `DOCKERHUB_REPOSITORY`: Docker Hub repository name.
- Actions secret `DOCKERHUB_TOKEN`: Docker Hub access token with permission to push to that repository.

The workflow tags the image with the GitHub release tag, for example `docker.io/kiuusai/pls-nostr-rs-relay:v1.2.3`.
When the release is the repository's latest release, it also pushes the `latest` tag.

## Azure deployment

The [`terraform/`](terraform/) directory provisions the production Azure Container Apps environment, relay, Postgres container, and Azure Files storage.
See [`terraform/README.md`](terraform/README.md) for image publishing and deployment instructions.
