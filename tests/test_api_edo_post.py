"""EDO v1 presign + post ingestion.

Presign tests are offline (``generate_presigned_post`` does no network I/O).
Post tests are DB-backed and stub the S3 existence check so no real bucket is
touched.
"""

import pytest
from werkzeug.test import TestResponse

from tmc.utils.media import kind_from_content_type

API_BASE = "http://api.themetacity.test"


# --------------------------------------------------------------------------- #
# kind_from_content_type (pure)
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize(
    ("content_type", "expected"),
    [
        ("image/jpeg", "image"),
        ("video/mp4", "video"),
        ("audio/mpeg", "audio"),
        ("application/pdf", "file"),
        ("", "file"),
        (None, "file"),
    ],
)
def test_kind_from_content_type(content_type, expected) -> None:
    assert kind_from_content_type(content_type) == expected


# --------------------------------------------------------------------------- #
# presign (offline)
# --------------------------------------------------------------------------- #
def _presign(client, **form) -> TestResponse:
    return client.post("/edo/v1/media/presign", data=form, base_url=API_BASE)


def test_presign_returns_namespaced_key(client_offline) -> None:
    resp = _presign(client_offline, filename="my photo.jpg", content_type="image/jpeg")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["success"] is True
    key = body["data"]["key"]
    # Server-chosen key: random prefix + sanitised filename (never the raw name).
    assert key.endswith("/my_photo.jpg")
    assert "/" in key and key.split("/", 1)[0] != ""
    assert body["data"]["method"] == "PUT"
    assert body["data"]["url"].startswith("http")
    assert body["data"]["headers"] == {"Content-Type": "image/jpeg"}


def test_presign_without_content_type(client_offline) -> None:
    resp = _presign(client_offline, filename="notes.txt")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["data"]["key"].endswith("/notes.txt")
    assert body["data"]["method"] == "PUT"
    assert body["data"]["headers"] == {}


def test_presign_missing_filename(client_offline) -> None:
    resp = _presign(client_offline)
    assert resp.status_code == 400
    assert resp.get_json()["success"] is False


def test_presign_two_calls_differ(client_offline) -> None:
    a = _presign(client_offline, filename="same.jpg").get_json()["data"]["key"]
    b = _presign(client_offline, filename="same.jpg").get_json()["data"]["key"]
    assert a != b  # random prefix prevents overwrite


# --------------------------------------------------------------------------- #
# post (DB-backed)
# --------------------------------------------------------------------------- #
@pytest.fixture()
def stub_s3(app, monkeypatch) -> set[str]:
    """Make every object appear present in storage unless overridden."""
    present: set[str] = set()

    def _exists(key: str) -> bool:
        return "__MISSING__" not in key and (not present or key in present)

    monkeypatch.setattr(app.extensions["s3"], "object_exists", _exists)
    return present


def _post(client, payload) -> TestResponse:
    return client.post("/edo/v1/post", json=payload, base_url=API_BASE)


@pytest.mark.usefixtures("db_session")
def test_post_text_and_media(client, stub_s3) -> None:
    resp = _post(
        client,
        {
            "text": "a day at the beach",
            "media": [
                {"key": "abc/one.jpg", "content_type": "image/jpeg"},
                {"key": "abc/two.mp4", "content_type": "video/mp4"},
            ],
        },
    )
    assert resp.status_code == 201
    data = resp.get_json()["data"]
    assert data["content"] == "a day at the beach"
    assert [m["key"] for m in data["media"]] == ["abc/one.jpg", "abc/two.mp4"]
    assert [m["position"] for m in data["media"]] == [0, 1]
    assert [m["kind"] for m in data["media"]] == ["image", "video"]
    assert "id" in data


@pytest.mark.usefixtures("db_session")
def test_post_media_only(client, stub_s3) -> None:
    resp = _post(client, {"media": ["only/pic.png"]})
    assert resp.status_code == 201
    data = resp.get_json()["data"]
    assert data["content"] == ""
    assert data["media"][0]["key"] == "only/pic.png"
    # A bare string key has no declared content type -> kind "file".
    assert data["media"][0]["kind"] == "file"


@pytest.mark.usefixtures("db_session")
def test_post_text_only(client, stub_s3) -> None:
    resp = _post(client, {"text": "just words"})
    assert resp.status_code == 201
    data = resp.get_json()["data"]
    assert data["content"] == "just words"
    assert data["media"] == []


@pytest.mark.usefixtures("db_session")
def test_post_rejects_empty(client, stub_s3) -> None:
    resp = _post(client, {"text": "   ", "media": []})
    assert resp.status_code == 400
    assert resp.get_json()["success"] is False


@pytest.mark.usefixtures("db_session")
def test_post_rejects_non_json(client, stub_s3) -> None:
    resp = client.post("/edo/v1/post", data="nope", base_url=API_BASE)
    assert resp.status_code == 400


@pytest.mark.usefixtures("db_session")
def test_post_rejects_bad_media_entry(client, stub_s3) -> None:
    resp = _post(client, {"media": [{"content_type": "image/jpeg"}]})  # no key
    assert resp.status_code == 400


@pytest.mark.usefixtures("db_session")
def test_post_rejects_missing_media(client, stub_s3) -> None:
    resp = _post(client, {"text": "x", "media": ["gone/__MISSING__.jpg"]})
    assert resp.status_code == 400
    body = resp.get_json()
    assert body["success"] is False
    assert body["data"]["missing"] == ["gone/__MISSING__.jpg"]


@pytest.mark.usefixtures("db_session")
def test_post_media_shows_in_list(client, stub_s3) -> None:
    created = _post(client, {"text": "listed", "media": ["a/b.jpg"]}).get_json()["data"]
    listing = client.get("/edo/v1/list/", base_url=API_BASE).get_json()
    row = next(r for r in listing["data"]["routes"] if r["id"] == created["id"])
    assert [m["key"] for m in row["media"]] == ["a/b.jpg"]
