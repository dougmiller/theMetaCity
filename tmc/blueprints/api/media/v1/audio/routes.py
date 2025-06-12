from tmc.models.media import Audio
from tmc.schemas.media.audio import AudioSchema
from tmc.utils.responses import api_response

from . import audio


@audio.route("/")
def all_audios():
    all = Audio.all()
    
    if all is None:
        return api_response(
            message="No matching records found",
            success=False,
            status=404
        )
    
    media_item_schema = AudioSchema(many=True)
    
    return api_response(
        data=media_item_schema.dump(all)
    )


@audio.route("/<int:audio>")
def audio_details(audio=None):
    one = Audio.get(audio)

    if one is None:
        return api_response(
            message="No matching record found",
            success=False,
            status=404
        )
    
    audio_item_schema = AudioSchema()
    
    return api_response(
        data=audio_item_schema.dump(one)
    )
