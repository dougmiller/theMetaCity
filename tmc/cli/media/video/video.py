import click
from flask.cli import AppGroup

from tmc import db
from tmc.models.media.video import Video

video = AppGroup(
    "video",
    help="Manage videos in the system",
    short_help="Manage blog posts",
)


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
@click.argument("record", nargs=-1, type=click.STRING, required=True)
def specific_record(record):
    """
    Get the details of a specific video file
    """
    
    #todo get filter for existing video (by id)
    #todo retrieve the value
    #todo show the video meta
    pass

# track info
# file info