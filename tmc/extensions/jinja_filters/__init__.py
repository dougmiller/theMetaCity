from flask import Flask, current_app
from markupsafe import Markup


def tmc_markdown(raw_markdown) -> Markup:
    """Render Markdown safely as HTML."""
    return Markup(current_app.extensions["markdown"].md.convert(raw_markdown))


def register_filters(app: Flask) -> None:
    """Register custom filters with the Flask app."""
    app.jinja_env.filters["markdown"] = tmc_markdown
