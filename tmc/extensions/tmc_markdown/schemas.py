import re

from marshmallow import Schema, ValidationError, fields, pre_load, validates

from tmc.models.blog import Variant


class TMCBlogMetadataSchema(Schema):
    id = fields.UUID(allow_none=True)
    title = fields.String(required=True)
    url = fields.String(required=True)
    variant = fields.Enum(Variant, by_value=True, load_default=Variant.blog)
    blurb = fields.String(required=True)
    tags = fields.List(fields.String(), load_default=[])
    parent = fields.UUID(allow_none=True)

    @pre_load
    def normalize_keys(self, data, **kwargs) -> dict:
        # Convert keys to lowercase
        return {k.lower(): v for k, v in data.items()}

    @pre_load
    def normalize_variant(self, data, **kwargs) -> dict:
        # Normalise only the raw string (case/whitespace); let the Enum field do
        # the conversion so a bad value raises ValidationError (caught by the
        # caller), not a bare ValueError that escapes it.
        variant = data.get("variant")
        if isinstance(variant, str):
            data["variant"] = variant.lower().strip()
        return data

    @pre_load
    def parse_tags(self, data, **kwargs) -> dict:
        if isinstance(data.get("tags"), str):
            # Split by comma and strip whitespace
            data["tags"] = [tag.strip() for tag in data["tags"].split(",") if tag.strip()]
        return data

    @validates("title")
    def validate_title(self, value, **kwargs) -> None:
        if not value.strip():
            raise ValidationError("Title cannot be blank")

    @validates("blurb")
    def validate_blurb(self, value, **kwargs) -> None:
        if not value.strip():
            raise ValidationError("Blurb cannot be blank")

    @validates("url")
    def validate_url(self, value, **kwargs) -> None:
        if not value.strip():
            raise ValidationError("URL cannot be blank")

        slug_pattern = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
        if not slug_pattern.match(value):
            raise ValidationError("URL must be a valid slug (lowercase, no spaces, use hyphens)")
