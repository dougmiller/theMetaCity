from tmc.models.edo import EDO
from tmc.extensions.marshmallow import ma
from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field
from marshmallow import fields

__all__ = ('EDOSchema')


class EDOSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = EDO
        load_instance = True
    
    id = auto_field()
    content = auto_field()
    created_at = fields.Method("get_created_at")
    updated_at = fields.Method("get_modified_at")
    
    def get_created_at(self, obj):
        return obj.created_at.isoformat() if obj.created_at else None
    
    def get_modified_at(self, obj):
        return obj.created_at.isoformat() if obj.created_at else None