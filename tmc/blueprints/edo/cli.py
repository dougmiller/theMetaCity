from tmc import db
from . import edo
from tmc.models.edo import EDO


@edo.cli.command("list")
def list():
	import pprint
	edo_list = db.session.execute(
		db.select(EDO)
			.order_by(EDO.created_at.desc())
			.limit(10)
	).scalars().all()

	pprint.pp(edo_list)


