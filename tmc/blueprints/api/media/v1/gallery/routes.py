from flask.typing import ResponseReturnValue

from tmc.extensions import read_session
from tmc.queries import media as media_queries
from tmc.schemas.media.gallery import GallerySchema
from tmc.utils.responses import api_response

from .bp import bp as gallery


@gallery.route("/")
def all_galleries() -> ResponseReturnValue:
    items = media_queries.all_gallery(read_session())
    return api_response(data=GallerySchema(many=True).dump(items))


@gallery.route("/<int:gallery>")
def gallery_details(gallery: int) -> ResponseReturnValue:
    one = media_queries.gallery_by_id(read_session(), gallery)
    if one is None:
        return api_response(message="No matching record found", success=False, status=404)
    return api_response(data=GallerySchema().dump(one))
