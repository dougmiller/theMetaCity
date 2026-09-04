from flask import Flask, current_app
from markupsafe import Markup


def tmc_markdown(raw_markdown) -> Markup:
    """Render Markdown safely as HTML."""
    return Markup(current_app.extensions["markdown"].convert(raw_markdown))


def init_app(app: Flask) -> None:
    app.jinja_env.filters["markdown"] = tmc_markdown
