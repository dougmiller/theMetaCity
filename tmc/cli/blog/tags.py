import random
from collections import deque

import click
from flask.cli import AppGroup

from tmc.models.blog import Tag

tags = AppGroup(
    "tags",
    help="Manage Blog Tags (list)",
    short_help="Manage Blog Tags",
)


@tags.command("list")
def list_tags() -> None:
    """
    List the tags (and article count) currently in the database
    """
    tags_list = Tag.all()
    colours = ["red", "green", "yellow", "blue", "magenta", "cyan", "white"]
    recent_colours = deque(maxlen=3)

    styled_tags = []
    for tag in tags_list:
        available_colours = [c for c in colours if c not in recent_colours] or colours
        colour = random.choice(available_colours)
        styled_tags.append(click.style(f"{tag.tag} ({len(tag.articles)})", fg=colour))
        recent_colours.append(colour)

    click.echo(",".join(styled_tags))
    

@tags.command("details")
@click.argument("tag", nargs=1, type=click.STRING, required=True)
def tag_details(tag) -> None:
    """
    Show details for a specific tag and list its associated articles.

    The "tag" must match exactly (case-sensitive). No fuzzy or partial matching is performed.
    Articles are printed in color with recent colors avoided for readability.
    
    Arguments:
        tag (str): A case-sensitive tag to get the details on.
    """
    if not tag.strip():
        click.echo(click.style("Queried 'tag' must not be empty.", fg="red"))
        return
    
    found_tag = Tag.first(tag=tag)

    if not found_tag:
        click.echo(click.style(f"No match for: {tag}", fg='yellow'))
        return

    click.echo(click.style(f"Listing {len(found_tag.articles)} articles for: {tag}", fg='yellow'))
    
    colours = ["red", "green", "yellow", "blue", "magenta", "cyan", "white"]
    recent_colours = deque(maxlen=3)
    
    for article in found_tag.articles:
        available_colours = [c for c in colours if c not in recent_colours] or colours
        colour = random.choice(available_colours)
        click.echo(click.style(f"{article.id}: {article.title} ({article.variant.value})", fg=colour))
        recent_colours.append(colour)
