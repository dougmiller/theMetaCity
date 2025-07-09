import click
from flask.cli import AppGroup, with_appcontext
from sqlalchemy import String, cast

from tmc.extensions import db
from tmc.models.edo import EDO, EDO_Admin

edo = AppGroup(
    'edo',
    help="Manage EDO records (list, add, delete)",
    short_help="EDO record managment",
)

@edo.command("list")
@click.option("--count", default=10, help="Number of entries to show (defaults to 10)")
@click.option("--filter", help="Filter entries by the starting ID value")
def list(count, filter):
    """Show the latest (by creation date) (--count==10) number of EDO records"""

    edo_list = EDO.some(limit=count)

    for e in edo_list:
        click.echo(f"{e.command_line_listing_str()}")


@edo.command("find")
@click.argument("filter", nargs=-1, type=click.STRING, required=True)
def find(filter):
    """Show the records which match the supplied filter"""

    filter_str = " ".join(filter)
    edo_list = EDO.find_by_expression(
        cast(EDO.id, String).like(f"{filter_str}%"),
        order_by=EDO.created_at.desc()
    )

    if not edo_list:
        click.echo("No matches")
        return

    for e in edo_list:
        click.echo(f"{e.command_line_listing_str()}")


@edo.command("add")
@click.argument("record", nargs=-1, type=click.STRING, required=True)
def add(record):
    """Adds a new record to EDO"""
    click.echo(click.style(f"Going to add: {' '.join(record)}", fg="yellow"))
    
    new_edo = EDO_Admin(content=" ".join(record))
    new_edo.save()
    click.echo(click.style(f"Added EDO: {new_edo.id}", fg="green"))
    db.session.commit()
    db.session.remove()

@edo.command("rm")
@click.argument("record", nargs=1, type=click.UUID, required=True)
@with_appcontext
def rm(record):
    """Removes an EDO record"""
    click.echo(click.style(f"Going to rm: {record}", fg="red"))
    edo_record = EDO_Admin.get(record)

    if not edo_record:
        click.echo(click.style(f"No record found with ID: {record}", fg="yellow"))
        return

    click.confirm(click.style(f"Are you sure you want to delete '{edo_record.command_line_str()}'?", fg="yellow"), abort=True)

    edo_record.delete()
    db.session.commit()
    db.session.remove()

    click.echo(click.style(f"Deleted EDO: {record}", fg="red"))
