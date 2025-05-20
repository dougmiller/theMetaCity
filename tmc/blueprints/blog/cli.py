import os
import re
import click
from sqlalchemy.exc import IntegrityError
from psycopg.errors import UniqueViolation
from marshmallow import ValidationError
from flask import current_app
from flask.cli import with_appcontext

from tmc import db
from . import blog
from tmc.models.blog import BlogSelector as Blog, BlogAdmin
from tmc.extensions import md
from tmc.extensions.markdown import TMCBlogMetadataSchema

blog.cli.help = "Blog management commands"
blog.cli.short_help = "Manage blog posts"


@blog.cli.command("list")
@click.option('--count', default=10, help='Number of entries to show (default: 10)')
def list_articles(count):
    """List the latest blog articles and their types."""
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

    for root, _, files in os.walk(base_dir):
        if filename in files:
            return os.path.join(root, filename)
    return None


@blog.cli.command("process")
@with_appcontext
@click.argument('file', type=str)
def process(file):
    """
    Process a Markdown file and insert/update a blog record.
    """
    if not file.lower().endswith('.md'):
        click.echo("Error: Only Markdown (.md) files are supported.")
        return

    full_path = check_file_in_subdirectory(file)
    if not full_path:
        click.echo(
            f"Error: File '{file}' not found in the documents directory "
            f"({current_app.config.get('DOCUMENTS_FOLDER_PATH', '.')})."
        )
        return

    try:
        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()

        text = md.convert(content)
        schema = TMCBlogMetadataSchema()

        try:
            meta_raw = {k: v[0] for k, v in md.Meta.items() if v}
            meta = schema.load(meta_raw)
        except ValidationError as err:
            click.echo("Metadata validation failed:")
            for field, messages in err.messages.items():
                for message in messages:
                    click.echo(click.style(f"{message}", fg="red"))
            return

        click.echo(f'Processing: {meta["title"]}')

        if meta.get("id"):
            blog_entry = BlogAdmin.query.get(meta["id"])
            blog_entry.title = meta["title"]
            blog_entry.url = meta["url"]
            blog_entry.blurb = meta["blurb"]
            blog_entry.text = text
            db.session.commit()
        else:
            blog_entry = BlogAdmin(
                title=meta["title"],
                url=meta["url"],
                blurb=meta["blurb"],
                text=text
            )

            # Commit first so the ID is assigned
            db.session.add(blog_entry)
            db.session.commit()

            # Prepend the new ID to the markdown file
            new_id = str(blog_entry.id)

            with open(full_path, 'r', encoding='utf-8') as f:
                original_content = f.read()

            updated_content = f"id: {new_id}\n" + original_content

            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(updated_content)

        click.echo('Finished processing.')
    except IntegrityError as err:
        if isinstance(err.orig, UniqueViolation):
            db.session.rollback()
    
            # Try to extract the field name from the error message
            match = re.search(r'Key \((.*?)\)=', str(err.orig))
            if match:
                field_name = match.group(1)
                click.echo(click.style(
                    f"Error: The {field_name} '{meta.get(field_name, '')}' already exists (must be unique).",
                    fg="red"
                ))
            else:
                click.echo(click.style("Error: Duplicate value violates a unique constraint.", fg="red"))
        else:
            raise
    except Exception as e:
        click.echo(click.style(f"An error occurred: {e}", fg="red"))
