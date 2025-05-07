from flask import Flask
from markupsafe import Markup


def tmc_markdown(text):
	"""Render Markdown safely as HTML."""
	from tmc.extensions import md
	return Markup(md.convert(text))

def register_filters(app: Flask):
	"""Register custom filters with the Flask app."""
	app.jinja_env.filters["tmc_markdown"] = tmc_markdown
