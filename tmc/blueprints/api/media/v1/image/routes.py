from tmc.models.media import Image
from tmc.schemas.media.image import ImageSchema
from tmc.utils.responses import api_response

from . import image


@image.route("/")
def all_audios():
    all = Image.all()
    
    if all is None:
        return api_response(
            message="No matching records found",
            success=False,
            status=404
        )
    
    media_item_schema = ImageSchema(many=True)
    
    return api_response(
        data=media_item_schema.dump(all)
    )


@image.route("/<uuid:image>")
def image_details(image=None):
    one = Image.get(image)

    if one is None:
        return api_response(
            message="No matching record found",
            success=False,
            status=404
        )
    
    image_item_schema = ImageSchema()
    
    return api_response(
        data=image_item_schema.dump(one)
    )
