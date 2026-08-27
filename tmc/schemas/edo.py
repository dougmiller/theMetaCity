from marshmallow import fields
from marshmallow_sqlalchemy import SQLAlchemyAutoSchema, auto_field

from tmc.models.edo import EDO


class EDOSchema(SQLAlchemyAutoSchema):
    class Meta:
        model = EDO
        load_instance = True

    id = auto_field()
    content = auto_field()
    created_at = fields.Method("get_created_at")
    updated_at = fields.Method("get_modified_at")

    def get_created_at(self, obj) -> str | None:
        return obj.created_at.isoformat() if obj.created_at else None

    def get_modified_at(self, obj) -> str | None:
        return obj.updated_at.isoformat() if obj.updated_at else None
