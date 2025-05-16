import click
from tmc import db
from . import edo
from tmc.models.edo import EDO, EDO_Admin


edo.cli.help = "Manage EDO record (add, deleted)"
edo.cli.short_help = "EDO record managment"

@edo.cli.command("list")
@click.option('--count', default=10, help='Number of entries to show (defaults to 10)')
@click.option('--filter', help='Filter entries by the starting ID value')
def list(count, filter):
	"""Show the latest (by creation date) (--count==10) number of EDO records"""
	query = db.select(EDO).order_by(EDO.created_at.desc()).limit(count)

	if filter is not None:
		from sqlalchemy import cast, String
		query = query.filter(cast(EDO.id, String).like(f"{filter}%"))

	edo_list = db.session.execute(query).scalars().all()
	
	for e in edo_list:
		click.echo(f'{e.command_line_listing_str()}')


@edo.cli.command("add")
@click.argument('record', nargs=-1, type=click.STRING, required=True)
def add(record):
	"""Adds a new record to EDO"""
	click.echo(click.style(f'Going to add: {' '.join(record)}',fg="yellow"))
	new_edo = EDO_Admin(content=' '.join(record))
	db.session.add(new_edo)
	db.session.commit()
	click.echo(click.style(f'Added EDO: {new_edo.id}', fg='green'))
	

@edo.cli.command("rm")
@click.argument('record', nargs=1, type=click.UUID, required=True)
def rm(record):
	"""Removes an EDO record"""
	click.echo(click.style(f'Going to rm: {record}', fg='red'))
	edo_record = db.session.get(EDO_Admin, record)
	
	if not edo_record:
		click.echo(click.style(f"No record found with ID: {record}", fg='yellow'))
		return
	
	confirm = click.confirm(click.style(f"Are you sure you want to delete '{edo_record.command_line_str()}'?", fg="yellow"), abort=True)
	
	db.session.delete(edo_record)
	db.session.commit()
	click.echo(click.style(f"Deleted EDO: {record}", fg='red'))
