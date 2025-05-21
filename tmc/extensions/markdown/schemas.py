import re
from marshmallow import Schema, fields, ValidationError, validates, validates_schema, pre_load


class TMCBlogMetadataSchema(Schema):
    id = fields.String(allow_none=True)
    title = fields.String(required=True)
    url = fields.String(required=True)
    type = fields.String(load_default="blog")
    blurb = fields.String(required=True)

    @pre_load
    def normalize_type(self, data, **kwargs):
        if "type" in data and isinstance(data["type"], str):
            data["type"] = data["type"].lower().strip()
        return data

    @validates("title")
    def validate_title(self, value, **kwargs):
        if not value.strip():
            raise ValidationError("Title cannot be blank")

    @validates("blurb")
    def validate_blurb(self, value, **kwargs):
        if not value.strip():
            raise ValidationError("Blurb cannot be blank")

    @validates("url")
    def validate_url(self, value, **kwargs):
        if not value.strip():
            raise ValidationError("URL cannot be blank")

        slug_pattern = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
        if not slug_pattern.match(value):
            raise ValidationError("URL must be a valid slug (lowercase, no spaces, use hyphens)")

    @validates("type")
    def validate_type(self, value, **kwargs):
        if value not in {"blog", "workshop"}:
            raise ValidationError("Type must be either 'blog' or 'workshop'.")

    @validates_schema
    def check_blank_id(self, data, **kwargs):
        if "id" in data and data["id"] is not None and not data["id"].strip():
            raise ValidationError("'id' is present but blank")
