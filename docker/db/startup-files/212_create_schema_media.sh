#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Creating MEDIA schema"
echo "======"

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${TMC_MASTER_USER};
  CREATE SCHEMA media;
  GRANT CONNECT ON DATABASE themetacity TO ${MEDIA_ADMIN_USER};
  ALTER SCHEMA media OWNER TO ${MEDIA_ADMIN_USER};

  ALTER DEFAULT PRIVILEGES
  FOR USER ${MEDIA_ADMIN_USER}
  IN SCHEMA media
    GRANT SELECT ON
    TABLES TO ${MEDIA_SELECT_USER};
SQL

echo "======"
echo "Setting up MEDIA tables"
$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${MEDIA_ADMIN_USER};
  
  CREATE TYPE media.audio_audio_codec AS ENUM ('vorbis','mp3','wav');
  CREATE TYPE media.audio_file_extension AS ENUM ('ogg','mp3','wav');
  CREATE TYPE media.audio_mime_type AS ENUM ('ogg','webm','mp3','mpeg','wav');
  CREATE TYPE media.audio_track_type AS ENUM ('subtitles','captions','descriptions','chapters','metadata');
  CREATE TYPE media.type AS ENUM ('blog','workshop');
  CREATE TYPE media.video_audio_codec AS ENUM ('nill','vorbis','mp3','wav');
  CREATE TYPE media.video_file_extension AS ENUM ('webm','ogv','mp4');
  CREATE TYPE media.video_mime_type AS ENUM ('webm','mp4','ogg');
  CREATE TYPE media.video_track_type AS ENUM ('subtitles','captions','descriptions','chapters','metadata');
  CREATE TYPE media.video_video_codec AS ENUM ('vp8','h264','theora');

  -- Generic Media item that othes parent from
  CREATE TABLE media.licence (
      id SERIAL PRIMARY KEY,
      licence_name character varying,
      licence_text character varying,
      licence_url character varying,
      image_url character varying
  );
  --ALTER SEQUENCE media.licence_id_seq OWNED BY media.licence.id;
  ALTER TABLE ONLY media.licence ADD CONSTRAINT licence_image_url_key UNIQUE (image_url);
  ALTER TABLE ONLY media.licence ADD CONSTRAINT licence_licence_name_key UNIQUE (licence_name);
  ALTER TABLE ONLY media.licence ADD CONSTRAINT licence_licence_text_key UNIQUE (licence_text);
  ALTER TABLE ONLY media.licence ADD CONSTRAINT licence_licence_url_key UNIQUE (licence_url);


  CREATE TABLE media.postcard (
      id SERIAL PRIMARY KEY,
      url character varying,
      title character varying,
      alt_text character varying
  );
  ALTER TABLE ONLY media.postcard ADD CONSTRAINT postcard_alt_text_key UNIQUE (alt_text);
  ALTER TABLE ONLY media.postcard ADD CONSTRAINT postcard_title_key UNIQUE (title);
  ALTER TABLE ONLY media.postcard ADD CONSTRAINT postcard_url_key UNIQUE (url);


  CREATE TABLE media.tags (
      id SERIAL PRIMARY KEY,
      tag character varying NOT NULL
  );
  ALTER TABLE ONLY media.tags ADD CONSTRAINT tags_tag_key UNIQUE (tag);


  CREATE TABLE media.media_item (
      id SERIAL PRIMARY KEY,
      title character varying,
      about character varying,
      licence integer,
      date_published date,
      postcard integer DEFAULT 1
  );
  ALTER TABLE ONLY media.media_item ADD CONSTRAINT mediaitem_title_key UNIQUE (title);
  ALTER TABLE ONLY media.media_item ADD CONSTRAINT mediaitem_licence_fkey FOREIGN KEY (licence) REFERENCES media.licence(id);


  CREATE TABLE media.tags_joiner (
      tag_id integer NOT NULL,
      mediaitem_id integer NOT NULL
  );
  ALTER TABLE ONLY media.tags_joiner ADD CONSTRAINT tags_joiner_pkey PRIMARY KEY (tag_id, mediaitem_id);
  ALTER TABLE ONLY media.tags_joiner ADD CONSTRAINT tags_joiner_mediaitem_id_fkey FOREIGN KEY (mediaitem_id) REFERENCES media.media_item(id);


  -- Audio
  CREATE TABLE media.audio (
      id SERIAL PRIMARY KEY,
      parent_id integer,
      file_name character varying,
      running_time double precision,
      has_start_poster boolean,
      has_end_poster boolean
  );
  --ALTER SEQUENCE media.audio_id_seq OWNED BY media.audio.id;
  ALTER TABLE ONLY media.audio ADD CONSTRAINT audio_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES media.media_item(id);


  CREATE TABLE media.audio_file (
      id SERIAL PRIMARY KEY,
      parent_audio integer,
      audio_codec media.audio_audio_codec,
      mime_type media.audio_mime_type,
      extension media.audio_file_extension,
      bit_rate integer,
      bit_depth integer,
      sample_rate integer,
      vbr_encoded boolean,
      file_size integer
  );
  --ALTER SEQUENCE media.audio_file_id_seq OWNED BY media.audio_file.id;
  ALTER TABLE ONLY media.audio_file ADD CONSTRAINT audio_file_parent_audio_fkey FOREIGN KEY (parent_audio) REFERENCES media.audio(id);



  CREATE TABLE media.audio_track (
      id SERIAL PRIMARY KEY,
      parent_audio integer,
      type media.audio_track_type,
      src_lang character varying,
      label character varying
  );
  --ALTER SEQUENCE media.audio_track_id_seq OWNED BY media.audio_track.id;
  ALTER TABLE ONLY media.audio_track ADD CONSTRAINT audio_track_parent_audio_fkey FOREIGN KEY (parent_audio) REFERENCES media.audio(id);


  -- Code
  CREATE TABLE media.code (
      id SERIAL PRIMARY KEY,
      parent_id integer,
      file_name character varying,
      file_size integer,
      language character varying
  );
  --ALTER SEQUENCE media.code_id_seq OWNED BY media.code.id;
  ALTER TABLE ONLY media.code ADD CONSTRAINT code_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES media.media_item(id);

  -- Picture
  CREATE TABLE media.picture (
      id SERIAL PRIMARY KEY,
      parent_id integer,
      file_name character varying,
      resolution character varying,
      file_size integer
  );
  ALTER TABLE ONLY media.picture ADD CONSTRAINT picture_file_name_key UNIQUE (file_name);
  ALTER TABLE ONLY media.picture ADD CONSTRAINT picture_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES media.media_item(id);


  -- Video
  CREATE TABLE media.video (
    id SERIAL PRIMARY KEY,
    parent_id integer,
    file_name character varying(64),
    running_time double precision,
    has_start_poster boolean,
    has_end_poster boolean,
    has_fullscreen boolean,
    resolution character varying(16)
  );
  ALTER TABLE ONLY media.video ADD CONSTRAINT video_file_name_key UNIQUE (file_name);
  ALTER TABLE ONLY media.video ADD CONSTRAINT video_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES media.media_item(id);

  CREATE TABLE media.video_file (
    id SERIAL PRIMARY KEY,
    parent_video integer,
    video_codec media.video_video_codec,
    audio_codec media.video_audio_codec,
    mime_type media.video_mime_type,
    extension media.video_file_extension,
    resolution character varying(16),
    file_size integer,
    is_fullscreen boolean
  );
  ALTER TABLE ONLY media.video_file ADD CONSTRAINT video_file_parent_video_fkey FOREIGN KEY (parent_video) REFERENCES media.video(id);


  CREATE TABLE media.video_track (
    id SERIAL PRIMARY KEY,
    parent_video integer,
    type media.video_track_type,
    src_lang character varying(16),
    label character varying(16)
  );
  ALTER TABLE ONLY media.video_track ADD CONSTRAINT video_track_parent_video_fkey FOREIGN KEY (parent_video) REFERENCES media.video(id);

  SELECT pg_catalog.setval('media.audio_file_id_seq', 3, true);
  SELECT pg_catalog.setval('media.audio_id_seq', 2, true);
  SELECT pg_catalog.setval('media.audio_track_id_seq', 2, true);
  SELECT pg_catalog.setval('media.code_id_seq', 1, false);
  SELECT pg_catalog.setval('media.licence_id_seq', 1, true);
  SELECT pg_catalog.setval('media.media_item_id_seq', 7, true);
  SELECT pg_catalog.setval('media.picture_id_seq', 1, false);
  SELECT pg_catalog.setval('media.postcard_id_seq', 9, true);
  SELECT pg_catalog.setval('media.tags_id_seq', 16, true);
  SELECT pg_catalog.setval('media.video_file_id_seq', 16, true);
  SELECT pg_catalog.setval('media.video_id_seq', 6, true);
  SELECT pg_catalog.setval('media.video_track_id_seq', 2, true);

SQL

echo "======"