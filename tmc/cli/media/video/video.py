import click
from flask.cli import AppGroup

from tmc import db
from tmc.models.media.video import Video
from .file import files

video = AppGroup(
    "video",
    help="Manage videos in the system",
    short_help="Manage blog posts",
)

video.add_command(files, name="files")

@video.command("list")
@click.option("--count", default=10, help="Number of entries to show (default: 10)")
def list_videos(count):
    """
    List the latest video assets
    """
    video_list = db.session.execute(
        db.select(Video)
        .order_by(Video.date_published.desc()
    ).limit(count)).scalars().all()

    for video in video_list:
        click.echo(
            click.style(f"{video.id}", bold=True)
            + ": "
            + click.style(video.title, fg="green")
        )

@video.command("record", help="Specific video meta")
@click.argument("record", nargs=1, type=click.INT, required=True)
def specific_record(record):
    """
    Get the details of a specific video file
    """
    video_record = Video.get(record)
    
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
    for Track in video_record.tracks:
        click.echo(f"   {track}")
