from marshmallow import fields
from marshmallow_sqlalchemy import SQLAlchemyAutoSchema, SQLAlchemySchema, auto_field

from tmc.models.edo import EDO, EdoMedia


class EdoMediaSchema(SQLAlchemySchema):
    """Serialises a single media object attached to a post (dump only)."""

    class Meta:
        model = EdoMedia

    id = auto_field()
    key = auto_field(column_name="s3_key")
    content_type = auto_field()
    kind = auto_field()
    position = auto_field()


class EDOSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = EDO
        load_instance = True

    id = auto_field()
    content = auto_field()
    media = fields.Nested(EdoMediaSchema, many=True, dump_only=True)
    created_at = fields.Method("get_created_at")
    updated_at = fields.Method("get_modified_at")

    def get_created_at(self, obj) -> str | None:
        return obj.created_at.isoformat() if obj.created_at else None

    def get_modified_at(self, obj) -> str | None:
        return obj.updated_at.isoformat() if obj.updated_at else None
