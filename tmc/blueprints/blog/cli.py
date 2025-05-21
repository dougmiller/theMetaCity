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
from tmc.models.blog import ArticleSelector as Article, ArticleAdmin
from tmc.extensions import md
from tmc.extensions.markdown import TMCBlogMetadataSchema

blog.cli.help = "Blog management commands"
blog.cli.short_help = "Manage blog posts"


@blog.cli.command("list")
@click.option('--count', default=10, help='Number of entries to show (default: 10)')
def list_articles(count):
    """List the latest blog articles and their types."""
    blog_list = db.session.execute(
        db.select(Article)
        .order_by(Article.created_at.desc())
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

def strip_metadata(markdown_text):
    """
    Removes YAML-style metadata lines (key: value) from the beginning of a Markdown string.
    Stops stripping after the first non-meta line.
    """
    lines = markdown_text.splitlines()
    body_lines = []

    meta_done = False
    for line in lines:
        if not meta_done and (line.strip() == "" or ":" in line):
            continue  # Skip metadata
        else:
            meta_done = True
            body_lines.append(line)

    return "\n".join(body_lines)

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

        md.convert(content)
        article_without_meta = strip_metadata(content)
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

        click.echo(f'File looks OK. Proceeding...')

        if meta.get("id"):
            blog_entry = db.session.get(ArticleAdmin, int(meta["id"]))
            
            if blog_entry.variant != meta["variant"]:
                # Save the new values
                updated_fields = {
                    "id": meta["id"],
                    "title": meta["title"],
                    "url": meta["url"],
                    "blurb": meta["blurb"],
                    "variant": meta["variant"],
                    "text": article_without_meta,
                }
        
                # Delete the old entry
                db.session.delete(blog_entry)
                db.session.commit()
        
                # Recreate using the appropriate polymorphic class
                new_entry = ArticleAdmin(**updated_fields)
                db.session.add(new_entry)
                db.session.commit()
        
                click.echo(f"Replaced article {meta['id']} with new variant: {meta['variant'].value}")
            else:
                # Safe to update in place
                blog_entry.title = meta["title"]
                blog_entry.url = meta["url"]
                blog_entry.blurb = meta["blurb"]
                blog_entry.text = article_without_meta
                db.session.commit()
                click.echo(f"Updated article: {blog_entry.id}")
        else:
            click.echo(f"Inserting new article")

            blog_entry = ArticleAdmin(
                title=meta["title"],
                url=meta["url"],
                blurb=meta["blurb"],
                variant = meta["variant"],
                text=article_without_meta
            )

            # Commit first so the ID is assigned
            db.session.add(blog_entry)
            db.session.commit()

            # Prepend the new ID to the markdown file
            new_id = str(blog_entry.id)
            click.echo(f"Inserted article: {blog_entry.id}")
            
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
