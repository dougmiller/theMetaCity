"""Shared configuration source.

The merged environment used by the config-owning extensions on the normal
boot path: development ``.env`` files overlaid by the process environment
(``os.environ`` wins). The injected-config path (tests) never calls this.
"""

import os

from dotenv import dotenv_values


def raw_env() -> dict[str, str | None]:
    return {
        **dotenv_values(".env.basic"),  # shared development variables
        **dotenv_values(".env.database"),  # connection variables
        **os.environ,  # environment overrides
    }
