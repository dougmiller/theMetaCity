import os
import click
from flask.cli import with_appcontext
from dotenv import load_dotenv, dotenv_values


class BasicConfig:
	"""Handles basic environment validation and CLI inspection."""

	REQUIRED_ENV_VARS = [
		'SERVER_NAME',
		'DEBUG',
		'SECRET_KEY',
		'CSRF_ENABLED',
		'EDO_UPLOAD_PATH',
		'ASSETS_PATH'
	]
	
	SENSITIVE_KEYS = {
		'SECRET_KEY',
	}
	
	def __init__(self, app = None):
		if app is not None:
			self.init_app(app)
	
	def init_app(self, app):
		app.cli.add_command(check_env)
		app.config.from_object(self.load_basic_env())

	def load_basic_env(self):
		"""Load .env.basic and validate required environment variables."""
		return dotenv_values(".env.basic")
	
	def get_basic_summary(self, mask=True):
		"""Return a dict of environment variable values (optionally masked)."""
		summary = {}
		basic_values = dotenv_values(".env.basic")
		for key in self.REQUIRED_ENV_VARS:
			val = basic_values.get(key)
			if mask and key in self.SENSITIVE_KEYS:
				val = val[:3] + '...' + val[-3:] if val else None
			summary[key] = val
		return summary


basic_config = BasicConfig()

@click.command("check-env")
@with_appcontext
def check_env():
	click.echo("🔍 Checking required environment variables...")
	envs = basic_config.get_basic_summary()
	missing = []

	for key, value in envs.items():
		if value is None:
			missing.append(key)
			click.echo(f"❌ {key} is missing")
		else:
			click.echo(f"✅ {key} = {value}")

	if missing:
		click.echo("\n❌ A required option was missing.")
		raise SystemExit(1)

	click.echo("\n✅ All required environment variables are set.")
