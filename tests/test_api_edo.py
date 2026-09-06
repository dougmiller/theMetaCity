"""EDO API v1 — DB-backed. Ported from the BrunoAPI/EDO collection."""

import uuid

import pytest
from flask.testing import FlaskClient
from werkzeug.test import TestResponse

from tests._seed import make_edo

pytestmark = pytest.mark.usefixtures("db_session")


@pytest.fixture()
def client_edo(client) -> FlaskClient:
    # The api blueprint lives on the `api` subdomain.
    return client


def _get(client, path) -> TestResponse:
    return client.get(path, base_url="http://api.themetacity.test")


def test_list_edo_empty(client, db_session) -> None:
    resp = _get(client, "/edo/v1/list/")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["success"] is True
    # `data` is always present; empty result → routes is an empty list.
    assert body["data"] == {"routes": []}


def test_list_edo_with_row(client, db_session) -> None:
    make_edo(db_session, content="first post")
    db_session.commit()
    resp = _get(client, "/edo/v1/list/")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["success"] is True
    contents = [row["content"] for row in body["data"]["routes"]]
    assert "first post" in contents


def test_one_edo_found(client, db_session) -> None:
    edo = make_edo(db_session, content="findme")
    db_session.commit()
    resp = _get(client, f"/edo/v1/list/{edo.id}")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["success"] is True
    assert body["data"]["content"] == "findme"


def test_one_edo_not_found(client, db_session) -> None:
    absent = uuid.uuid4()
    resp = _get(client, f"/edo/v1/list/{absent}")
    assert resp.status_code == 404
    body = resp.get_json()
    assert body["success"] is False
    assert "No matching record" in body["message"]


def test_one_edo_bad_uuid_format(client, db_session) -> None:
    # Non-UUID path segment is rejected by the <uuid:> converter → Flask 404 (HTML).
    resp = _get(client, "/edo/v1/list/not-a-uuid")
    assert resp.status_code == 404
