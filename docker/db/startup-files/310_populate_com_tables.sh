#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Populating COM"
echo "======"

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${COM_ADMIN_USER};

  COPY com.article_tags (id, tag, blurb) FROM stdin;
  1	PostgreSQL	\N
  2	SSH	\N
  4	JavaScript	\N
  6	Automation	\N
  7	InfoVis	\N
  8	git	\N
  9	TLS	\N
  10	Travel	\N
  11	Markdown	\N
  3	theMetaCity	\N
  5	Python	\N
  12	Images	\N
  13	gitting good at git	\N
  14	Philosophy	\N
  15	Programming	\N
  16	Business	\N
\.

SQL

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${COM_ADMIN_USER};
  SELECT pg_catalog.setval('com.article_tags_id_seq', 16, true);
SQL

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${COM_ADMIN_USER};
  SELECT pg_catalog.setval('com.articles_id_seq', 25, true);
SQL
