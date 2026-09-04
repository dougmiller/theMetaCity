"""Unit tests for TMCBlogMetadataSchema variant handling.

Pure marshmallow — no app context or database, so these run everywhere.
Guards the fix where ``variant`` normalisation was moved out of ``@pre_load``
(which raised a bare ValueError on a bad value) into the Enum field (which
raises a ValidationError the caller actually catches).
"""

import pytest
from marshmallow import ValidationError

from tmc.extensions.tmc_markdown.schemas import TMCBlogMetadataSchema
from tmc.models.blog import Variant

_BASE = {"title": "Hello World", "url": "hello-world", "blurb": "A greeting"}


def _load(**overrides) -> dict:
    return TMCBlogMetadataSchema().load({**_BASE, **overrides})


def test_variant_defaults_to_blog_when_absent() -> None:
    assert _load()["variant"] is Variant.blog


def test_variant_accepts_exact_values() -> None:
    assert _load(variant="blog")["variant"] is Variant.blog
    assert _load(variant="workshop")["variant"] is Variant.workshop


def test_variant_is_case_insensitive() -> None:
    assert _load(variant="WORKSHOP")["variant"] is Variant.workshop


def test_variant_strips_surrounding_whitespace() -> None:
    assert _load(variant="  Blog  ")["variant"] is Variant.blog


def test_variant_typo_raises_validation_error_not_value_error() -> None:
    with pytest.raises(ValidationError) as exc_info:
        _load(variant="foo")
    assert "variant" in exc_info.value.messages
