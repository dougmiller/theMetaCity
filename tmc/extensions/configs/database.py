import os
import click
from flask.cli import with_appcontext
from dotenv import load_dotenv, dotenv_values
from tmc.extensions.configs.connectors import PSQLDatabaseConfig


class DatabaseConfig:
	"""Handles basic environment validation and CLI inspection."""

	REQUIRED_BIND_NAMES = [
		'themetacity.master',
		'themetacity.com.admin',
		'themetacity.com.selector',
		'themetacity.media.admin',
		'themetacity.media.selector',
		'everyday_ordinary.admin',
		'everyday_ordinary.selector'
	]
	
	CONNECTION_PARAMETERS = {
		'hostname',
		'port',
		'name',
		'user'
	}
	
	def __init__(self, app = None):
		if app is not None:
			self.init_app(app)
	
	def init_app(self, app):
		app.cli.add_command(check_db)
		app.cli.add_command(test_db)
		app.config.from_object(self.load_basic_env())
	
	def load_basic_env(self):
		"""Load .env.basic and validate required environment variables."""
		return dotenv_values(".env.database")
	
	def get_basic_summary(self, mask=True):
		"""Return a dict of environment variable values (optionally masked)."""
		summary = {}
		connection_details = dotenv_values(".env.database")
		for bind_name in self.REQUIRED_BIND_NAMES:
			for connection_paramter in self.CONNECTION_PARAMETERS:
				key = bind_name+'.'+connection_paramter
				summary[key] = connection_details.get(key)
		return summary

	def get_connections(self):
		"""Return a dict of environment variable values (optionally masked)."""
		connections = {}
		connection_details = dotenv_values(".env.database")
		for bind_name in self.REQUIRED_BIND_NAMES:
			connections[bind_name] = {}

			for connection_parameter in self.CONNECTION_PARAMETERS:
				bind_connection_parameter = bind_name+'.'+connection_parameter
				connections[bind_name][connection_parameter] = connection_details.get(bind_connection_parameter)
		return connections


database_config = DatabaseConfig()

@click.command("check-db")
@with_appcontext
def check_db():
	click.echo("🔍 Checking required DB variables...")
	envs = database_config.get_basic_summary()
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


@click.command("test-db")
@with_appcontext
def test_db():
	click.echo("🔍 Testing DB connections...")
	connections = database_config.get_connections()

	for bind_name, connection in connections.items():
		c = PSQLDatabaseConfig(
			host=connection['hostname'],
			port=connection['port'],
			name=connection['name'],
			user=connection['user']
		)
		click.echo(f"🔍 {bind_name} - {'✅' if c.test_psql_connection() else '❌'}")

	click.echo("\n✅ All required environment variables are set.")
