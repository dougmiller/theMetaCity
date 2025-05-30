from sqlalchemy import delete, select, update
from sqlalchemy.orm.util import _class_to_mapper


def _get_polymorphic_base_and_bind(cls):
    mapper = _class_to_mapper(cls)
    base_cls = cls
    while not mapper.polymorphic_identity and mapper.inherits:
        base_cls = mapper.inherits.class_
        mapper = _class_to_mapper(base_cls)

    bind_key = getattr(cls, "__bind_key__", None)
    return base_cls, bind_key


def select_with_bind(cls):
    base_cls, bind_key = _get_polymorphic_base_and_bind(cls)
    stmt = select(base_cls)
    if bind_key:
        stmt = stmt.execution_options(bind_key=bind_key)
    return stmt


def update_with_bind(cls):
    base_cls, bind_key = _get_polymorphic_base_and_bind(cls)
    stmt = update(base_cls)
    if bind_key:
        stmt = stmt.execution_options(bind_key=bind_key)
    return stmt


def delete_with_bind(cls):
    base_cls, bind_key = _get_polymorphic_base_and_bind(cls)
    stmt = delete(base_cls)
    if bind_key:
        stmt = stmt.execution_options(bind_key=bind_key)
    return stmt
