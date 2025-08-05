from __future__ import annotations

from typing import Any, TypeVar
import uuid

from flask import abort
from sqlalchemy import and_, or_
from sqlalchemy import delete as sa_delete
from sqlalchemy import select as sa_select
from sqlalchemy import update as sa_update
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import object_session
from sqlalchemy.orm.util import _class_to_mapper
from sqlalchemy.sql import Delete, Select, Update

from tmc.extensions import db

__all__ = ("SmartQueryMixin")

T = TypeVar("T", bound="SmartQueryMixin")


class SmartQueryMixin:
    """Unified mixin for query and bind-aware operations."""

    # ========== Session-based Methods ==========

    def save(self) -> None:
        session = object_session(self) or db.session
        bind_key = self._resolve_bind_and_base()[1]

        try:
            if bind_key:
                # Trigger bind resolution, useful if your session uses multiple binds
                session.get_bind(mapper=self.__mapper__, bind_key=bind_key)

            session.add(self)
            session.flush()
        except SQLAlchemyError:
            session.rollback()
            raise  # Re-raise the exception to let the caller handle/log it

    def delete(self) -> None:
        session = object_session(self) or db.session
        bind_key = self._resolve_bind_and_base()[1]

        try:
            if bind_key:
                session.get_bind(mapper=self.__mapper__, bind_key=bind_key)

            session.delete(self)
            session.flush()
        except SQLAlchemyError:
            session.rollback()
            raise


    # ========== Class-based Methods ==========

    @classmethod
    def all(cls: type[T], order_by: Any = None) -> list[T]:
        stmt = cls._select_stmt()

        identity = getattr(cls.__mapper__, "polymorphic_identity", None)
        if identity:
            stmt = stmt.where(cls.variant == identity)

        # Use the explicitly passed order_by
        if order_by is not None:
            stmt = stmt.order_by(order_by)
    
        # Use class-defined __default_order_by__
        elif hasattr(cls, "__default_order_by__"):
            stmt = stmt.order_by(getattr(cls, "__default_order_by__"))
    
        # Fallback to created_at.desc() if available
        elif hasattr(cls, "created_at"):
            stmt = stmt.order_by(getattr(cls, "created_at").desc())
    
        # No order_by at all if none of the above
    
        return db.session.scalars(stmt).all()

    @classmethod
    def latest(cls: type[T], limit: int = 10) -> list[T]:
        stmt = cls._select_stmt().order_by(cls.created_at.desc()).limit(limit)
        return db.session.scalars(stmt).all()

    @classmethod
    def latest_by_id(cls: type[T], limit: int = 10) -> list[T]:
        stmt = cls._select_stmt().order_by(cls.id.desc()).limit(limit)
        return db.session.scalars(stmt).all()

    @classmethod
    def first(cls: type[T], **kwargs: Any) -> T | None:
        stmt = cls._select_stmt().filter_by(**kwargs).limit(1)
        return db.session.scalars(stmt).first()

    @classmethod
    def first_or_404(cls: type[T], **kwargs: Any) -> T:
        item = cls.first(**kwargs)
        if item is None:
            abort(404)
        return item

    @classmethod
    def get(cls: type[T], pk: Any) -> T | None:
        pk_col = cls.__mapper__.primary_key[0]
        pk_type = getattr(pk_col.type, "python_type", None)
        is_uuid = isinstance(pk_type, type) and issubclass(pk_type, uuid.UUID)

        try:
            if isinstance(pk, str):
                if is_uuid:
                    pk = uuid.UUID(pk)
                elif pk.isdigit():
                    pk = int(pk)
            elif isinstance(pk, float):
                return None

            # Range check for PostgreSQL INTEGER
            if isinstance(pk, int) and issubclass(pk_type, int):
                if not -(2**31) <= pk <= 2**31 - 1:
                    return None
        except (ValueError, TypeError, OverflowError):
            return None

        stmt = cls._select_stmt().filter(pk_col == pk).limit(1)
        
        identity = getattr(cls.__mapper__, "polymorphic_identity", None)
        if identity:
            stmt = stmt.where(cls.media_type == identity)
        
        return db.session.scalars(stmt).first()

    @classmethod
    def get_or_404(cls: type[T], pk: Any) -> T:
        obj = cls.get(pk)
        if obj is None:
            abort(404)
        return obj

    @classmethod
    def exists(cls, **kwargs: Any) -> bool:
        return db.session.query(cls._and_query(kwargs).exists()).scalar() or False

    @classmethod
    def find(cls: type[T], **kwargs: Any) -> Any:
        return cls._and_query(kwargs)

    @classmethod
    def find_or(cls: type[T], **kwargs: Any) -> Any:
        return cls._or_query(kwargs)

    @classmethod
    def find_by_expression(cls: type[T], *expressions: Any, order_by: Any | None = None) -> list[T]:
        stmt = cls._select_stmt().filter(*expressions)
        if order_by is not None:
            stmt = stmt.order_by(order_by)
        return db.session.scalars(stmt).all()

    @classmethod
    def find_in(cls: type[T], _or: bool = False, **kwargs: Any) -> Any:
        return cls._or_in_query(kwargs) if _or else cls._and_in_query(kwargs)

    @classmethod
    def find_not_in(cls: type[T], _or: bool = False, **kwargs: Any) -> Any:
        return cls._or_not_in_query(kwargs) if _or else cls._and_not_in_query(kwargs)

    @classmethod
    def find_not_null(cls: type[T], *args: str) -> Any:
        filters = [getattr(cls, attr) is not None for attr in args]
        return cls.query.filter(*filters)

    # ========== Bind-aware Builders ==========

    @classmethod
    def select(cls) -> Select:
        return cls._select_stmt()

    @classmethod
    def update(cls) -> Update:
        base_cls, bind_key = cls._resolve_bind_and_base()
        stmt = sa_update(base_cls)
        return stmt.execution_options(bind_key=bind_key) if bind_key else stmt

    @classmethod
    def delete_stmt(cls) -> Delete:
        base_cls, bind_key = cls._resolve_bind_and_base()
        stmt = sa_delete(base_cls)
        return stmt.execution_options(bind_key=bind_key) if bind_key else stmt

    # ========== Internals ==========

    @classmethod
    def _resolve_bind_and_base(cls) -> tuple[type, str | None]:
        """Walks up inheritance chain to find base polymorphic class and its bind."""
        mapper = _class_to_mapper(cls)
        base_cls = cls
        while not mapper.polymorphic_identity and mapper.inherits:
            base_cls = mapper.inherits.class_
            mapper = _class_to_mapper(base_cls)
        bind_key = getattr(base_cls, "__bind_key__", None)
        return base_cls, bind_key

    @classmethod
    def _select_stmt(cls) -> Select:
        base_cls, bind_key = cls._resolve_bind_and_base()
        stmt = sa_select(cls)
        return stmt.execution_options(bind_key=bind_key) if bind_key else stmt

    # ========== Filter Builders ==========

    @classmethod
    def _filters(cls, filters: dict[str, Any]) -> list[Any]:
        return [getattr(cls, attr) == value for attr, value in filters.items()]

    @classmethod
    def _filters_in(cls, filters: dict[str, list[Any]]) -> list[Any]:
        return [getattr(cls, attr).in_(values) for attr, values in filters.items()]

    @classmethod
    def _filters_not_in(cls, filters: dict[str, list[Any]]) -> list[Any]:
        return [getattr(cls, attr).notin_(values) for attr, values in filters.items()]

    @classmethod
    def _and_query(cls, filters: dict[str, Any]) -> Any:
        return cls.query.filter(and_(*cls._filters(filters)))

    @classmethod
    def _or_query(cls, filters: dict[str, Any]) -> Any:
        return cls.query.filter(or_(*cls._filters(filters)))

    @classmethod
    def _and_in_query(cls, filters: dict[str, list[Any]]) -> Any:
        return cls.query.filter(and_(*cls._filters_in(filters)))

    @classmethod
    def _or_in_query(cls, filters: dict[str, list[Any]]) -> Any:
        return cls.query.filter(or_(*cls._filters_in(filters)))

    @classmethod
    def _and_not_in_query(cls, filters: dict[str, list[Any]]) -> Any:
        return cls.query.filter(and_(*cls._filters_not_in(filters)))

    @classmethod
    def _or_not_in_query(cls, filters: dict[str, list[Any]]) -> Any:
        return cls.query.filter(or_(*cls._filters_not_in(filters)))