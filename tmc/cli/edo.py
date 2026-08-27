import click
from flask.cli import AppGroup, with_appcontext
from sqlalchemy import String, cast, select

from tmc import queries
from tmc.extensions import db, read_session
from tmc.models.edo import EDO
from tmc.queries import edo as edo_queries

edo = AppGroup(
    "edo",
    help="Manage EDO records (list, add, delete)",
    short_help="EDO record managment",
)


@edo.command("list")
@click.option("--count", default=10, help="Number of entries to show (defaults to 10)")
@click.option("--filter", "id_filter", help="Filter entries by the starting ID value")
def list_records(count, id_filter) -> None:
    """Show the latest (by creation date) (--count==10) number of EDO records"""
    edo_list = edo_queries.latest(read_session(), limit=count)
    for e in edo_list:
        click.echo(f"{e.command_line_listing_str()}")


@edo.command("find")
@click.argument("terms", nargs=-1, type=click.STRING, required=True)
def find(terms) -> None:
    """Show the records which match the supplied filter"""
    filter_str = " ".join(terms)
    edo_list = read_session().scalars(select(EDO).where(cast(EDO.id, String).like(f"{filter_str}%")).order_by(EDO.created_at.desc())).all()

    if not edo_list:
        click.echo("No matches")
        return

    for e in edo_list:
        click.echo(f"{e.command_line_listing_str()}")


@edo.command("add")
@click.argument("record", nargs=-1, type=click.STRING, required=True)
def add(record) -> None:
    """Adds a new record to EDO"""
    click.echo(click.style(f"Going to add: {' '.join(record)}", fg="yellow"))

    new_edo: EDO = EDO(content=" ".join(record))
    queries.save(db.session, new_edo)
    click.echo(click.style(f"Added EDO: {new_edo.id}", fg="green"))


@edo.command("rm")
@click.argument("record", nargs=1, type=click.UUID, required=True)
@with_appcontext
def rm(record) -> None:
    """Removes an EDO record"""
    click.echo(click.style(f"Going to rm: {record}", fg="red"))
    edo_record: EDO | None = edo_queries.by_id(db.session, record)

    if not edo_record:
        click.echo(click.style(f"No record found with ID: {record}", fg="yellow"))
        return

    click.confirm(click.style(f"Are you sure you want to delete '{edo_record.command_line_str()}'?", fg="yellow"), abort=True)

    queries.delete(db.session, edo_record)
    click.echo(click.style(f"Deleted EDO: {record}", fg="red"))
