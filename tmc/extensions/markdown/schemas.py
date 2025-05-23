import re
from marshmallow import Schema, fields, ValidationError, validates, validates_schema, pre_load
from tmc.models.blog import ArticleType


class TMCBlogMetadataSchema(Schema):
    id = fields.String(allow_none=True)
    title = fields.String(required=True)
    url = fields.String(required=True)
    variant = fields.Enum(ArticleType, load_default=ArticleType.blog)
    blurb = fields.String(required=True)
    tags = fields.List(fields.String(), load_default=[])
    parent = fields.String(allow_none=True)

    @pre_load
    def normalize_keys(self, data, **kwargs):
        # Convert keys to lowercase
        return {k.lower(): v for k, v in data.items()}

    @pre_load
    def normalize_type(self, data, **kwargs):
        if "variant" in data and isinstance(data["variant"], str):
            raw_variant = data["variant"].lower().strip()
            data["variant"] = ArticleType(raw_variant)
        return data

    @pre_load
    def parse_tags(self, data, **kwargs):
        if isinstance(data.get("tags"), str):
            # Split by comma and strip whitespace
            data["tags"] = [tag.strip() for tag in data["tags"].split(",") if tag.strip()]
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

    @validates("variant")
    def validate_type(self, value, **kwargs):
        if value not in {ArticleType.blog, ArticleType.workshop}:
            raise ValidationError("Type must be either 'blog' or 'workshop'.")

    @validates_schema
    def check_blank_id(self, data, **kwargs):
        if "id" in data and data["id"] is not None and not data["id"].strip():
            raise ValidationError("'id' is present but blank")
