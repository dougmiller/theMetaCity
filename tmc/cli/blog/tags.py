import random
from collections import deque

import click
from flask.cli import AppGroup

from tmc.models.blog import TagSelector

tags = AppGroup(
    "tags",
    help="Manage Blog Tags (list)",
    short_help="Manage Blog Tags",
)


@tags.command("list")
def list_tags():
    """
    List the tags currently in the database
    """
    tags_list = TagSelector.all()
    colours = ["red", "green", "yellow", "blue", "magenta", "cyan", "white"]
    recent_colours = deque(maxlen=3)

    styled_tags = []
    for tag in tags_list:
        available_colours = [c for c in colours if c not in recent_colours] or colours
        colour = random.choice(available_colours)
        styled_tags.append(click.style(f"{tag.tag} ({len(tag.articles)})", fg=colour))
        recent_colours.append(colour)

    click.echo(",".join(styled_tags))
