import uuid

from flask.typing import ResponseReturnValue

from tmc.extensions import read_session
from tmc.queries import media as media_queries
from tmc.schemas.media.image import ImageSchema
from tmc.utils.responses import api_response

from .bp import bp


@bp.route("/")
def all_images() -> ResponseReturnValue:
    items = media_queries.all_image(read_session())
    return api_response(data=ImageSchema(many=True).dump(items))


@bp.route("/<uuid:image>")
def image_details(image: uuid.UUID) -> ResponseReturnValue:
    one = media_queries.image_by_id(read_session(), image)
    if one is None:
        return api_response(message="No matching record found", success=False, status=404)
    return api_response(data=ImageSchema().dump(one))
