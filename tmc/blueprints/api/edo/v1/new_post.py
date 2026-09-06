"""EDO post ingestion.

The android client uploads each media object directly to S3 first (see
``POST /media/presign``), then calls ``POST /post`` with the post text and the
list of object keys it uploaded. The server verifies each key really landed in
storage, then records the post and its media.
"""

from typing import Any

from flask import current_app, request
from flask.typing import ResponseReturnValue

from tmc import queries
from tmc.extensions import db
from tmc.models.edo import EDO, EdoMedia
from tmc.schemas.edo import EDOSchema
from tmc.utils.media import kind_from_content_type
from tmc.utils.responses import api_response

from .bp import bp


@bp.route("/prepost", methods=["POST"])
def prepost() -> ResponseReturnValue:
    edo = EDO()
    edo.content = request.form.get("text") or ""
    queries.save(db.session, edo)

    return api_response(data={"id": str(edo.id)}, status=201)


def _normalise_media(raw: Any) -> tuple[list[dict[str, Any]], str | None]:
    """Coerce the request's ``media`` into ``[{key, content_type}, ...]``.

    Accepts a bare key string or a ``{"key": ..., "content_type": ...}`` object
    per entry. Returns ``(items, error_message)``; ``error_message`` is non-None
    when the payload is malformed.
    """
    if not isinstance(raw, list):
        return [], "'media' must be a list"

    items: list[dict[str, Any]] = []
    for entry in raw:
        if isinstance(entry, str):
            key: Any = entry
            content_type: Any = None
        elif isinstance(entry, dict):
            key = entry.get("key")
            content_type = entry.get("content_type")
        else:
            return [], "Each media entry must be a string key or an object"

        if not key or not isinstance(key, str):
            return [], "Each media entry needs a non-empty 'key'"
        if content_type is not None and not isinstance(content_type, str):
            return [], "'content_type' must be a string"
        items.append({"key": key, "content_type": content_type})

    return items, None


@bp.route("/post", methods=["POST"])
def post() -> ResponseReturnValue:
    """Create an EDO post from JSON ``{text, media: [{key, content_type}]}``.

    ``media`` references objects the client already uploaded via the presign
    pathway. A post must carry text or at least one media item. Every media key
    is confirmed present in S3 before the post is committed. Returns the created
    post (id + media) serialised with :class:`EDOSchema`.
    """
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        return api_response(message="Expected a JSON object body", success=False, status=400)

    text = (payload.get("text") or "").strip()

    media_items, error = _normalise_media(payload.get("media") or [])
    if error is not None:
        return api_response(message=error, success=False, status=400)

    if not text and not media_items:
        return api_response(message="A post needs text or at least one media item", success=False, status=400)

    # Confirm every referenced object actually landed in storage before we
    # commit a post that points at it.
    s3 = current_app.extensions["s3"]
    missing = [item["key"] for item in media_items if not s3.object_exists(item["key"])]
    if missing:
        return api_response(
            data={"missing": missing},
            message="Some media were not found in storage",
            success=False,
            status=400,
        )

    edo = EDO()
    edo.content = text
    for position, item in enumerate(media_items):
        edo.media.append(
            EdoMedia(
                s3_key=item["key"],
                content_type=item["content_type"],
                kind=kind_from_content_type(item["content_type"]),
                position=position,
            )
        )

    queries.save(db.session, edo)

    return api_response(data=EDOSchema().dump(edo), status=201)
