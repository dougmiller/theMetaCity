import json
from flask import jsonify, request, current_app
from sqlalchemy.sql.expression import func
from tmc.utils.responses import api_response
from . import video
from tmc.models.media import MediaAsset
from tmc.models.media.video import Video, VideoSelector
from tmc.schemas.media import MediaAssetSchema

from tmc.utils.responses import api_response
from tmc import db


@video.route("/")
def all_videos():
    all = VideoSelector.all()
    
    if all is None:
        return api_response(
            message="No matching records found",
            success=False,
            status=404
        )
    
    media_item_schema = MediaAssetSchema(many=True)
    
    return api_response(
        data=media_item_schema.dump(all)
    )


@video.route("/<int:video>")
def video_details(video=None):
    one = db.session.execute(
        VideoSelector.select()
        .where(VideoSelector.id == video)
    ).scalars().one_or_none()
    
    if one is None:
        return api_response(
            message="No matching record found",
            success=False,
            status=404
        )
    
    media_item_schema = MediaAssetSchema()
    
    return api_response(
        data=media_item_schema.dump(one)
    )


@video.route("/follow_on/<int:video>/")
@video.route("/follow_on/")
def video_follow_on(video=None):
	v_query = db.select(Video).order_by(func.random()).limit(2)
	
	if video is not None:
		v_query = v_query.where(Video.id != video)
	
	follow_ons = db.session.execute(
		v_query
	).scalars().all()

	media_item_schema = MediaAssetSchema(many=True)

	return api_response(
		data=media_item_schema.dump(follow_ons)
	)

