import click
import os
from flask import current_app
from flask.cli import with_appcontext
from tmc import db
from . import blog
from tmc.models.blog import Blog


@blog.cli.command("list")
def list():
	import pprint
	blog_list = db.session.execute(
		db.select(Blog)
			.order_by(Blog.created_at.desc())
			.limit(10)
	).scalars().all()

	click.echo('\n'.join(str(e) for e in blog_list))




# Custom type to check if the file exists within the base directory
def check_file_in_subdirectory(ctx, param, value):
	# Combine the base directory with the provided file path
	BASE_DIR = "uploads"
	
	click.echo("Folder Path")
	click.echo(f"Current config keys: {list(current_app.config.keys())}")
	#click.echo(current_app.config['DOCUMENTS']['FOLDER_PATH'])

	file_path = os.path.join(BASE_DIR, value)

	# Check if the file exists in the specified path
	if not os.path.isfile(file_path):
		raise click.BadParameter(f"The file {file_path} does not exist.")
	
	# Return the full path of the file
	return file_path
	

@blog.cli.command("process")
@with_appcontext
@click.argument('file', type=str, metavar="<filename>", required=True, callback=check_file_in_subdirectory)
def process(file):
	click.echo(file)