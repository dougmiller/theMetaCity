#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Setting up COM tables"
echo "====== BEGIN ======"

$POSTGRES <<SQL
\c themetacity;
SET ROLE ${COM_ADMIN_USER};

CREATE TABLE com.articles (
  id UUID PRIMARY KEY default uuidv7(),
  title character varying NOT NULL,
  url character varying NOT NULL,
  blurb character varying NOT NULL,
  variant com.variant DEFAULT 'blog'::com.variant NOT NULL,
  content character varying NOT NULL,
  created_at timestamp with time zone GENERATED ALWAYS AS (uuid_extract_timestamp(id)) STORED,
  updated_at timestamp with time zone,
  parent_id UUID DEFAULT null
);
ALTER TABLE ONLY com.articles ADD CONSTRAINT articles_title_key UNIQUE (title);
ALTER TABLE ONLY com.articles ADD CONSTRAINT articles_url_key UNIQUE (url);
ALTER TABLE ONLY com.articles ADD CONSTRAINT articles_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES com.articles(id) ON DELETE SET NULL ON UPDATE CASCADE;

CREATE OR REPLACE FUNCTION com.set_updated_at_from_uuid_initial()
RETURNS TRIGGER AS \$\$
BEGIN
  NEW.updated_at = uuid_extract_timestamp(NEW.id);
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_on_insert_from_id_UUID
BEFORE INSERT ON com.articles
FOR EACH ROW
EXECUTE FUNCTION com.set_updated_at_from_uuid_initial();

CREATE TABLE com.tags (
  id SERIAL PRIMARY KEY,
  tag character varying NOT NULL,
  blurb character varying
);

CREATE TABLE com.article_tags_joiner (
  article_id UUID NOT NULL,
  tag_id integer NOT NULL
);
ALTER TABLE ONLY com.article_tags_joiner ADD CONSTRAINT tags_joiner_pkey PRIMARY KEY (tag_id, article_id);
ALTER TABLE ONLY com.article_tags_joiner ADD CONSTRAINT tags_joiner_article_id_fkey FOREIGN KEY (article_id) REFERENCES com.articles(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ONLY com.article_tags_joiner ADD CONSTRAINT tags_joiner_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES com.tags(id) ON DELETE CASCADE ON UPDATE CASCADE;



SQL

echo "====== END ======"