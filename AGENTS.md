# Private Law Society Nostr relay

This is a document instructing how agents should work in this repository.
It's destinated for agents and subagents.
The objective is describe general rules for project.

## Project structure

This project has a simple structure.

In root folder it have a `Dockerfil`e and code to up the Nostr relay.
You can see more details reading the `Dockerfile` and `docker-compose.yml` file to understand infrastrucute logic.

In `terraform/` folder, the IaC code.

This project uses a simple Python script to apply Jinja template for the `config.toml` file adding environment variables to it.
The objective is just configure the project to accept custom env vars for production facility.

## Coding suggestions and good practices

- Write the least code as you can
  - The ZEN of Python
    - Flat is better than nested
    - Sparse is better than dense
- Maintain the code as most readable as possible
  - Again, Then ZEN of Python
    - Beautiful is better than ugly
    - Explicit is better than implicit
    - Simple is better than complex
    - Readability counts

## Security rules

- Errors should not occurs in production
  - Check written code ensuring it will not breaks on production
  - Again, the ZEN of Python
    - Errors should never pass silently unless explicitly silenced
    - In the face of ambiguity, refuse the tempation of guess
- Any created or used env var should be described in `.env.example` with a functional value for testing/development environments
- Don't read real secrets and sensitive environment variables.
  - Environment variables like `DATABASE_URL`, `POSTGRES_*` or any credential access MAINLY Azure credentials should not be directly read
  - To handle them, use environment variables or tfvars
  - For testing, use the ones provided in `.env.example`
- Don't do any destructive commands unless explicitly requested by the user
  - Commands like
    - `git reset --hard HEAD~1`
    - `git push --force`
    - `docker volume rm <volume>`
- Don't do any production change without explicit user authorization
  - Also, describe each action you want to do, commands and how it will affects the production environment
- Any modification on `terraform/` folder should be warned and explained
  - Also, ensure that user wants all the side effects on modified terraform code
