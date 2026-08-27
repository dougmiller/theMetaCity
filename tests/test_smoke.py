"""Toolchain smoke test — no database required.

Confirms the app factory is importable and callable. Real behavioural tests
arrive in Phase 1.
"""

import importlib


def test_factory_importable() -> None:
    module = importlib.import_module("tmc")
    assert callable(module.create_app)
