from flask import Flask
from markupsafe import Markup


def tmc_markdown(raw_markdown) -> Markup:
    """Render Markdown safely as HTML."""
    from tmc.extensions import md

    return Markup(md.convert(raw_markdown))


def register_filters(app: Flask) -> None:
    """Register custom filters with the Flask app."""
    app.jinja_env.filters["markdown"] = tmc_markdown
