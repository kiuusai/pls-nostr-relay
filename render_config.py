#!/usr/bin/env python3
"""Render the image-bundled relay config template using environment variables."""

import json
import os
from pathlib import Path

from jinja2 import Environment, FileSystemLoader, StrictUndefined


TEMPLATE_PATH = Path(
    os.environ.get("CONFIG_TEMPLATE", "/usr/src/app/config.toml.template")
)
OUTPUT_PATH = Path(os.environ.get("CONFIG_OUTPUT", "/usr/src/app/config.toml"))


def toml_string(value: object) -> str:
    """Encode a Python value as a TOML-compatible basic string."""
    return json.dumps(str(value), ensure_ascii=False)


def main() -> None:
    if not TEMPLATE_PATH.is_file():
        raise SystemExit(f"Config template not found: {TEMPLATE_PATH}")

    environment = Environment(
        loader=FileSystemLoader(str(TEMPLATE_PATH.parent)),
        undefined=StrictUndefined,
        autoescape=False,
        keep_trailing_newline=True,
    )
    environment.filters["toml_string"] = toml_string

    template = environment.get_template(TEMPLATE_PATH.name)
    rendered = template.render(**os.environ)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(rendered, encoding="utf-8")


if __name__ == "__main__":
    main()
