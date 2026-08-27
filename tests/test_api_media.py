"""Media API v1 — DB-backed. Ported from the BrunoAPI/Media collection."""

import pytest
from werkzeug.test import TestResponse

from tests._seed import make_audio

pytestmark = pytest.mark.usefixtures("db_session")


def _get(client, path) -> TestResponse:
    return client.get(path, base_url="http://api.themetacity.test")


# --- All assets ----------------------------------------------------------- #
def test_all_assets_empty(client, db_session) -> None:
    resp = _get(client, "/media/v1/all")
    assert resp.status_code == 200
    assert resp.get_json()["success"] is True


def test_all_assets_with_audio(client, db_session) -> None:
    make_audio(db_session, title="Track One")
    db_session.commit()
    resp = _get(client, "/media/v1/all")
    assert resp.status_code == 200
    titles = [row["title"] for row in resp.get_json().get("data", [])]
    assert "Track One" in titles


# --- Audio single --------------------------------------------------------- #
def test_audio_single_found(client, db_session) -> None:
    audio = make_audio(db_session, title="Solo")
    db_session.commit()
    resp = _get(client, f"/media/v1/audio/{audio.id}")
    assert resp.status_code == 200
    assert resp.get_json()["data"]["title"] == "Solo"


def test_audio_single_not_found(client, db_session) -> None:
    resp = _get(client, "/media/v1/audio/999999")
    assert resp.status_code == 404
    assert resp.get_json()["success"] is False


# --- List endpoints (fixed in Phase 2: polymorphic loading, not cls.variant) --- #
def test_audio_list(client, db_session) -> None:
    make_audio(db_session, title="Listed")
    db_session.commit()
    resp = _get(client, "/media/v1/audio/")
    assert resp.status_code == 200
    titles = [row["title"] for row in resp.get_json().get("data", [])]
    assert "Listed" in titles


def test_video_list_empty(client, db_session) -> None:
    resp = _get(client, "/media/v1/video/")
    assert resp.status_code == 200
    assert resp.get_json()["success"] is True


def test_gallery_list_empty(client, db_session) -> None:
    resp = _get(client, "/media/v1/gallery/")
    assert resp.status_code == 200
    assert resp.get_json()["success"] is True


# --- Schema-fix regression tests (Phase 5) -------------------------------- #
def test_image_single_is_not_an_asset(client, db_session) -> None:
    from tests._seed import make_image

    img = make_image(db_session)
    db_session.commit()
    resp = _get(client, f"/media/v1/image/{img.id}")
    assert resp.status_code == 200
    data = resp.get_json()["data"]
    assert data["path"] == img.path
    # Image is NOT an Asset: no title/postcard/licence keys leak in.
    assert "title" not in data and "postcard" not in data and "licence" not in data


def test_gallery_single_dumps_images(client, db_session) -> None:
    from tests._seed import make_gallery, make_image

    gallery = make_gallery(db_session, title="Shiny")
    make_image(db_session, gallery_id=gallery.id)
    db_session.commit()
    resp = _get(client, f"/media/v1/gallery/{gallery.id}")
    assert resp.status_code == 200
    data = resp.get_json()["data"]
    assert data["title"] == "Shiny"
    assert len(data["images"]) == 1


def test_audio_single_dumps_audio_file_fields(client, db_session) -> None:
    from tests._seed import make_audio, make_audio_file

    audio = make_audio(db_session, title="WithFile")
    make_audio_file(db_session, audio)
    db_session.commit()
    resp = _get(client, f"/media/v1/audio/{audio.id}")
    assert resp.status_code == 200
    files = resp.get_json()["data"]["files"]
    assert len(files) == 1
    # Audio file schema now maps audio columns (not video columns).
    assert files[0]["bit_rate"] == 320
