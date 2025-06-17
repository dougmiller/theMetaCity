from tmc.models.media import Gallery
from tmc.schemas.media.gallery import GallerySchema
from tmc.utils.responses import api_response

from . import gallery


@gallery.route("/")
def all_galleries():
    all = Gallery.all()
    
    if all is None:
        return api_response(
            message="No matching records found",
            success=False,
            status=404
        )
    
    media_item_schema = GallerySchema(many=True)
    
    return api_response(
        data=media_item_schema.dump(all)
    )


@gallery.route("/<int:gallery>")
def gallery_details(gallery=None):
    one = Gallery.get(gallery)

    if one is None:
        return api_response(
            message="No matching record found",
            success=False,
            status=404
        )
    
    image_item_schema = GallerySchema()
    
    return api_response(
        data=image_item_schema.dump(one)
    )
