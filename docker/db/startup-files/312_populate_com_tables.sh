#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"


$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${COM_ADMIN_USER};
  COPY com.article_tags_joiner (tag_id, article_id) FROM stdin;
  1	1
  2	1
  4	2
  6	2
  4	3
  6	3
  4	4
  6	4
  4	5
  6	5
  7	6
  7	7
  8	7
  4	8
  4	9
  7	9
  9	10
  10	11
  11	12
  5	12
  11	13
  5	13
  11	14
  5	14
  11	15
  5	15
  11	16
  5	16
  3	17
  3	18
  7	19
  5	20
  11	20
  6	22
  12	22
  8	23
  14	24
  15	24
  16	21
\.

SQL


echo "======"