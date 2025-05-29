import json
from flask import jsonify, request, current_app
from sqlalchemy.sql.expression import func
from . import v1, api_response
from tmc.models.media import MediaItem, Video
from tmc.models.schemas.media import MediaItemSchema

from tmc.utils.responses import api_response
from tmc import db


@v1.route("/help/")
@v1.route("/")
def media_v1_index():
	# return openAPI swagger doc (YAML)

	return jsonify(
		{
			'info': 'Media api endpoints ',
			'routes': [
				{"endoint": "/help", "description": "This information"},
				{"endoint": "/video", "description": "Returns a video's details"},
			]
		}
	)


@v1.route("/all")
def all():
	all = db.session.execute(
		db.select(MediaItem)
	).scalars().all()

	media_item_schema = MediaItemSchema(many=True)
		
	return api_response(
		data=media_item_schema.dump(all)
	)


@v1.route("/video/<int:video>/")
def video_details(video=None):
	one = db.session.execute(
		db.select(Video)
		.where(Video.id == video)
	).scalars().one_or_none()
	
	if one is None:
		return api_response(
			message="No matching record found",
			success=False,
			status=404
		)
			
	return api_response(
		data=jsonify(one)
	)


@v1.route("/follow_on/<int:video>/")
@v1.route("/follow_on/")
def video_follow_on(video=None):
	v_query = db.select(Video).order_by(func.random()).limit(2)
	
	if video is not None:
		v_query = v_query.where(Video.id != video)
	
	follow_ons = db.session.execute(
		v_query
	).scalars().all()

	media_item_schema = MediaItemSchema(many=True)

	return api_response(
		data=media_item_schema.dump(follow_ons)
	)

