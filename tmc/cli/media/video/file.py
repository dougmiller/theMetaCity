import click
from flask.cli import AppGroup
from sqlalchemy import select

from tmc import db
from tmc.extensions import read_session
from tmc.models.media.video import File
from tmc.queries import media as media_queries

files = AppGroup(
    "file",
    help="Manage video files in the system",
    short_help="Manage files attached to video files",
)


@files.command("list")
@click.option("--count", default=10, help="Number of entries to show (default: 10)")
def list_files(count) -> None:
    """
    List the latest video assets
    """
    video_files = db.session.execute(select(File).order_by(File.id.desc()).limit(count)).scalars().all()

    for file in video_files:
        file_id = click.style(file.id, bold=True)
        title = click.style(file.asset.title, fg="green")  # type: ignore[attr-defined]
        file_size = click.style(file.file_size_human_readable(), fg="green")
        resolution = click.style(file.resolution, fg="green")

        click.echo(f"{file_id}: {title} {file_size} {resolution}")


@files.command("record", help="Specific video file meta")
@click.argument("record", nargs=1, type=click.INT, required=True)
def specific_record(record) -> None:
    """
    Get the details of a specific video file
    """
    video_record = media_queries.video_by_id(read_session(), record)

    if not video_record:
        click.echo(click.style(f"No video found with ID: {record}", fg="yellow"))
        return

    v_id = click.style(f"Video: {video_record.id}", fg="yellow")
    v_title = click.style(f"{video_record.title}", fg="green")
    click.echo(f"{v_id} -> {v_title}")

    click.echo(f"Files: ({len(video_record.files)})")
    for file in video_record.files:
        click.echo(f"   {file}")

    click.echo(f"tracks: ({len(video_record.tracks)})")
    for track in video_record.tracks:
        click.echo(f"   {track}")
