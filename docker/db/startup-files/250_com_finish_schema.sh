#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Finalising COM schema"
echo "====== BEGIN ======"

$POSTGRES <<SQL
\c themetacity;
SET ROLE ${COM_ADMIN_USER};

CREATE OR REPLACE FUNCTION com.set_updated_at_if_changed()
RETURNS TRIGGER AS \$\$
BEGIN
  IF ROW(NEW.*) IS DISTINCT FROM ROW(OLD.*) THEN
    NEW.updated_at = NOW();
  END IF;
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

CREATE TRIGGER updated_at_on_article_update
BEFORE UPDATE ON com.articles
FOR EACH ROW
EXECUTE FUNCTION com.set_updated_at_if_changed();
SQL

echo "====== END ======"