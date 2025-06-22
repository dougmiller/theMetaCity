import os
import re

import click
from flask import current_app
from flask.cli import AppGroup, with_appcontext
from marshmallow import ValidationError
from psycopg.errors import UniqueViolation
from sqlalchemy.exc import IntegrityError

from tmc import db
from tmc.extensions import md
from tmc.extensions.markdown import TMCBlogMetadataSchema
from tmc.models.media import Asset


assets = AppGroup(
    'assets',
    help="Manage assets",
    short_help="Manage assets",
)


@assets.command("list")
@click.option("--count", default=10, help="Number of entries to show (default: 10)")
def list_assets(count):
    """
    List the latest assets and their types.
    """
    assets_list = db.session.execute(
        db.select(Asset)
        .order_by(Asset.date_published.desc())
        .limit(count)
    ).scalars().all()

    colour_map = {
        "blog": "green",
        "workshop": "blue",
    }

    for asset in assets_list:
        media_type = asset.media_type
        colour = colour_map.get(media_type, "white")

        click.echo(
            click.style(f"{asset.id}", bold=True) + ": " +
            click.style(asset.title, fg="green") + " " +
            click.style(f"({media_type.value})", fg=colour)
        )
