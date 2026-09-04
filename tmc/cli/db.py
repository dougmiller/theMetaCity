"""Database connectivity check — the live counterpart to boot-time preflight.

Preflight validates config *shape* (offline, deterministic); this command
opens each configured engine and runs ``SELECT 1``, so a down database or a
wrong password shows up on demand rather than slowing every ``create_app``.

Named ``db-check`` because Flask-Alembic already owns ``flask db check``
(the migration up-to-date check).

    flask db-check
"""

import click
from flask.cli import with_appcontext
from sqlalchemy import text

from tmc.extensions.sqlalchemy import db


@click.command("db-check")
@with_appcontext
def db_check() -> None:
    """Open each configured engine and run SELECT 1."""
    failures = 0

    for name, engine in db.engines.items():
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
        except Exception as ex:  # report any driver/connection error
            failures += 1
            click.echo(f"  FAIL  {name}: {type(ex).__name__}: {ex}")
        else:
            click.echo(f"  OK    {name}  ({engine.url.render_as_string(hide_password=True)})")

    if failures:
        raise click.ClickException(f"{failures} engine(s) unreachable")
    click.echo("All engines reachable.")
