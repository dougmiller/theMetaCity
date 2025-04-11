#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Creating COM schema"
echo "======"

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${TMC_MASTER_USER};
  CREATE SCHEMA com;
  GRANT CONNECT ON DATABASE themetacity TO ${COM_ADMIN_USER};
  ALTER SCHEMA com OWNER TO ${COM_ADMIN_USER};

  ALTER DEFAULT PRIVILEGES
  FOR USER ${COM_ADMIN_USER}
  IN SCHEMA com
    GRANT SELECT ON
    TABLES TO ${COM_SELECT_USER};
SQL

echo "======"
echo "Setting up COM tables"
$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${COM_ADMIN_USER};

  CREATE TYPE com.type AS ENUM ('blog','workshop');

  CREATE TABLE com.articles (
      id SERIAL PRIMARY KEY,
      title character varying,
      url character varying,
      type com.type DEFAULT 'blog'::com.type NOT NULL,
      text character varying NOT NULL,
      creation_date timestamp without time zone DEFAULT now(),
      update_date timestamp without time zone DEFAULT now(),
      date_date timestamp without time zone DEFAULT now(),
      blurb character varying,
      parent_id integer
  );
  ALTER TABLE ONLY com.articles ADD CONSTRAINT articles_title_key UNIQUE (title);
  ALTER TABLE ONLY com.articles ADD CONSTRAINT articles_url_key UNIQUE (url);
  ALTER TABLE ONLY com.articles ADD CONSTRAINT articles_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES com.articles(id);

  CREATE TABLE com.article_tags (
      id SERIAL PRIMARY KEY,
      tag character varying NOT NULL,
      blurb character varying
  );

  CREATE TABLE com.article_tags_joiner (
    article_id integer NOT NULL,
    tag_id integer NOT NULL
  );
  ALTER TABLE ONLY com.article_tags_joiner ADD CONSTRAINT tags_joiner_pkey PRIMARY KEY (tag_id, article_id);
  ALTER TABLE ONLY com.article_tags_joiner ADD CONSTRAINT tags_joiner_article_id_fkey FOREIGN KEY (article_id) REFERENCES com.articles(id);
  ALTER TABLE ONLY com.article_tags_joiner ADD CONSTRAINT tags_joiner_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES com.article_tags(id);

SQL