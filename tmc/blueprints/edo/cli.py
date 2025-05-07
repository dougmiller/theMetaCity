import click
from tmc import db
from . import edo
from tmc.models.edo import EDO, EDO_Admin


@edo.cli.command("list")
def list():
	import pprint
	edo_list = db.session.execute(
		db.select(EDO)
			.order_by(EDO.created_at.desc())
			.limit(10)
	).scalars().all()

	click.echo('\n'.join(str(e) for e in edo_list))


@edo.cli.command("add")
@click.argument('record', nargs=-1, type=click.STRING, required=True)
def add(record):
	click.echo(f'\033[1;33mGoing to add: {' '.join(record)}')
	new_edo = EDO_Admin(content=' '.join(record))
	db.session.add(new_edo)
	db.session.commit()
	click.echo(f'\033[32mAdded EDO: {new_edo.id}')
	

@edo.cli.command("rm")
@click.argument('record', nargs=1, type=click.UUID, required=True)
def rm(record):
	click.echo(f'\033[1;33mGoing to rm: {record}')
	edo_record = db.session.get(EDO_Admin, record)
	
	if not edo_record:
		click.echo(f"\033[31mNo record found with ID: {record}")
		return
	
	confirm = click.confirm(f"\033[34mAre you sure you want to delete '{edo_record}'?", abort=True)
	
	db.session.delete(edo_record)
	db.session.commit()
	click.echo(f"\033[0;32mDeleted EDO: {record}")