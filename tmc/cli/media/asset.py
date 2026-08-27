import click
from flask.cli import AppGroup
from sqlalchemy import select

from tmc import db
from tmc.models.media import Asset

from .video import video

assets = AppGroup(
    "assets",
    help="Manage assets",
    short_help="Manage assets",
)

assets.add_command(video, name="video")


@assets.command("list")
@click.option("--count", default=10, help="Number of entries to show (default: 10)")
def list_assets(count) -> None:
    """
    List the latest assets and their types.
    """
    assets_list = db.session.execute(select(Asset).order_by(Asset.date_published.desc()).limit(count)).scalars().all()

    for asset in assets_list:
        click.echo(click.style(f"{asset.id}", bold=True) + ": " + click.style(asset.title, fg="green"))
