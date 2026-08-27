"""Offline tests — no database required.

These lock in the app factory and the full route/blueprint registration, so the
Phase 2/3 refactor can't silently drop a route or break a blueprint.
"""

from flask import Flask


def test_app_factory_builds(app_offline) -> None:
    assert isinstance(app_offline, Flask)
    assert app_offline.config["TESTING"] is True
    assert app_offline.config["SERVER_NAME"] == "themetacity.test"


EXPECTED_BLUEPRINTS = {
    "home",
    "blog",
    "media",
    "media.audio",
    "media.video",
    "edo",
    "api",
    "api.edo",
    "api.edo.v1",
    "api.media",
    "api.media.v1",
    "api.media.v1.audio",
    "api.media.v1.video",
    "api.media.v1.gallery",
    "api.media.v1.image",
}


def test_all_blueprints_registered(app_offline) -> None:
    assert EXPECTED_BLUEPRINTS.issubset(set(app_offline.blueprints))


# Rule strings that must exist. Guards the API contract across the refactor.
EXPECTED_RULES = {
    "/edo/v1/list/",
    "/edo/v1/list/<uuid:record>",
    "/media/v1/all",
    "/media/v1/audio/",
    "/media/v1/audio/<int:audio>",
    "/media/v1/video/",
    "/media/v1/video/<int:video>",
    "/media/v1/gallery/",
    "/media/v1/gallery/<int:gallery>",
    "/media/v1/image/",
    "/media/v1/image/<uuid:image>",
}


def test_expected_routes_registered(app_offline) -> None:
    have = {r.rule for r in app_offline.url_map.iter_rules()}
    missing = EXPECTED_RULES - have
    assert not missing, f"missing routes: {sorted(missing)}"


def test_route_count_baseline(app_offline) -> None:
    # Baseline captured at Phase 1 (59 rules incl. static). Alert on large drops.
    rule_count = len(list(app_offline.url_map.iter_rules()))
    assert rule_count >= 55, f"route count dropped to {rule_count} (expected ~59)"
