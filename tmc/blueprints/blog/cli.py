import click
import os
from flask import current_app
from flask.cli import with_appcontext
from tmc import db
from . import blog
from tmc.models.blog import BlogSelector as Blog, BlogAdmin
from tmc.extensions import md


blog.cli.help = "Blog management commands"
blog.cli.short_help = "Manage blog posts"

@blog.cli.command("list")
@click.option('--count', default=10, help='Number of entries to show on the command line (defaults to 10)')
def list(count):
	"""Lists latest Blog articles (and their type)."""
	blog_list = db.session.execute(
		db.select(Blog)
			.order_by(Blog.created_at.desc())
			.limit(count)
	).scalars().all()

	click.echo('\n'.join(str(e) for e in blog_list))



def check_file_in_subdirectory(filename, base_dir=None):
    """
    Check if the file exists in any subdirectory of base_dir.
    Returns the full path if found, else None.
    """
    if base_dir is None:
        base_dir = current_app.config.get('DOCUMENTS_FOLDER_PATH', '.')
    
    for root, dirs, files in os.walk(base_dir):
        if filename in files:
            return os.path.join(root, filename)
    return None 
	

@blog.cli.command("process")
@with_appcontext
@click.argument('file', type=str)
def process(file):
    """Take an existing file and insert the contents as a record up update an existing one (if the ID mathces."""
    if not file.lower().endswith('.md'):
        click.echo("Error: Only Markdown (.md) files are supported.")
        return

    full_path = check_file_in_subdirectory(file)
    if not full_path:
        click.echo(f"Error: File '{file}' not found in the current directory or subdirectories.")
        return

    try:
        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()
        html = md.convert(content)
        #click.echo(html)
        #click.echo(md.Meta)
        
        #todo add in the blog updating section
        
    except Exception as e:
        click.echo(f"An error occurred: {e}")
