from tmc import db
from . import blog
from tmc.models.blog import Blog


@blog.cli.command("list")
def list():
	import pprint
	blog_list = db.session.execute(
		db.select(Blog)
			.order_by(Blog.created_at.desc())
			.limit(10)
	).scalars().all()

	pprint.pp(blog_list)


