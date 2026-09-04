import click
from flask.cli import AppGroup, with_appcontext

from tmc import db
from tmc.extensions import read_session
from tmc.services import blog as blog_service

from .tags import tags

blog = AppGroup(
    "blog",
    help="Manage Blog records (list, add, delete)",
    short_help="Manage blog posts",
)

blog.add_command(tags, name="tags")

_VARIANT_COLOURS = {"blog": "green", "workshop": "blue"}


@blog.command("list")
@click.option("--count", default=10, help="Number of entries to show (default: 10)")
def list_articles(count) -> None:
    """List the latest blog articles and their types."""
    for article in blog_service.list_recent_articles(read_session(), count):
        variant_value = article.variant.value
        colour = _VARIANT_COLOURS.get(variant_value, "white")
        click.echo(
            click.style(f"{article.id}", bold=True)
            + ": "
            + click.style(article.title, fg="green")
            + " "
            + click.style(f"({variant_value})", fg=colour)
        )


@blog.command("process")
@click.argument("file", type=str)
@with_appcontext
def process(file) -> None:
    """Process a Markdown file (with frontmatter) and insert/update a blog record."""
    try:
        result = blog_service.process_markdown_file(db.session, file)
    except blog_service.BlogProcessingError as err:
        click.echo(click.style(str(err), fg="red"))
        return

    if result.variant_changed:
        click.echo(click.style("Variant changed — record recreated.", fg="yellow"))
    if result.action == "inserted":
        click.echo(click.style(f"Inserted article: {result.article_id}", fg="green"))
    else:
        click.echo(f"Updated article: {result.article_id} - {result.title}")
    click.echo("Finished processing.")


@blog.command("process-published")
@click.option("--dir", "subdir", default="published", help="Subdirectory under the documents folder to import (default: published)")
@with_appcontext
def process_published(subdir) -> None:
    """Bulk-import every Markdown file in the published directory.

    Each record is (re)created under the UUIDv7 id from its frontmatter, so the
    generated created_at/updated_at columns derive from that id's timestamp.
    Safe to re-run: existing records are updated in place. Intended as a one-off
    after recreating the database.
    """
    try:
        summary = blog_service.process_published_directory(db.session, subdir)
    except blog_service.BlogProcessingError as err:
        click.echo(click.style(str(err), fg="red"))
        return

    click.echo(click.style(f"Inserted: {summary.inserted}", fg="green"))
    click.echo(f"Updated:  {summary.updated}")
    if summary.failures:
        click.echo(click.style(f"Failed:   {len(summary.failures)}", fg="red"))
        for name, message in summary.failures:
            click.echo(click.style(f"  - {name}: {message}", fg="red"))
    click.echo("Finished processing published directory.")


@blog.command("rm")
@click.argument("record", nargs=1, type=click.UUID, required=True)
def rm(record) -> None:
    """Remove a Blog record."""
    click.echo(click.style(f"Going to rm: {record}", fg="red"))
    article = blog_service.get_article(db.session, record)
    if article is None:
        click.echo(click.style(f"No record found with ID: {record}", fg="yellow"))
        return

    click.confirm(click.style(f"Are you sure you want to delete '{article.id}'?", fg="yellow"), abort=True)
    blog_service.delete_article(db.session, article)
    click.echo(click.style(f"Deleted Blog article: {record}", fg="red"))
