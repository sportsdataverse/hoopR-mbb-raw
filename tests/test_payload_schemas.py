"""Every committed payload family matches its declared shape in sdv-py.

No fixtures directory on purpose. This is a `-raw` repo -- the payloads *are*
committed here, so copying a few into ``tests/fixtures/`` would duplicate data
sitting one directory over, and would test the copy rather than the archive.
These tests read the real tree. Ported from the wehoop-wbb-raw template pair.

Schemas live in ``sportsdataverse.schemas`` (one per payload family, shared by
every league's -raw repo) rather than here, so a provider shape change is
described in one place instead of eight.
"""

from __future__ import annotations

import json
import os
import random
from pathlib import Path

import pytest
from sportsdataverse.schemas import validate_payload

REPO_ROOT = Path(__file__).resolve().parents[1]

# schema name -> glob of the committed captures it describes.
# MBB has no officials scrape; player_season_stats is flat/athlete-keyed here
# (no per-season subdirectory), unlike the WBB tree.
FAMILIES: list[tuple[str, str]] = [
    ("espn_summary", "mbb/json/final/*.json"),
    ("espn_summary", "mbb/json/raw/*.json"),
    ("espn_game_rosters", "mbb/game_rosters/json/*.json"),
    ("espn_player_core", "mbb/player_core/json/*.json"),
    ("espn_standings", "mbb/standings/json/*.json"),
    ("espn_team_stats", "mbb/team_stats/json/*/*.json"),
    ("espn_player_season_stats", "mbb/player_season_stats/json/*.json"),
]

# The archive is huge; a full sweep takes minutes. Sample per family by
# default and let CI or an operator widen it. Seeded so a failure is
# reproducible from the reported path.
SAMPLE = int(os.environ.get("MBB_SCHEMA_SAMPLE", "40"))

# Every test here reads the committed mbb/ tree, which PR CI does not check out.
pytestmark = pytest.mark.archive


def _sample(pattern: str) -> list[Path]:
    paths = sorted(REPO_ROOT.glob(pattern))
    if not paths:
        return []
    rng = random.Random(pattern)  # stable per family across runs
    return paths if len(paths) <= SAMPLE else rng.sample(paths, SAMPLE)


@pytest.mark.parametrize("schema,pattern", FAMILIES, ids=[p for _, p in FAMILIES])
def test_committed_payloads_match_their_schema(schema, pattern):
    paths = _sample(pattern)
    if not paths:
        pytest.skip(f"no captures under {pattern}")
    problems: list[str] = []
    for path in paths:
        payload = json.loads(path.read_text(encoding="utf-8"))
        for message in validate_payload(schema, payload):
            problems.append(f"{path.relative_to(REPO_ROOT)}: {message}")
    assert problems == [], "\n".join(problems[:20])


def test_every_family_has_captures():
    """A family that silently stopped being scraped looks like a passing skip
    above; this is what actually notices."""
    empty = [pattern for _, pattern in FAMILIES if not sorted(REPO_ROOT.glob(pattern))]
    assert empty == [], f"no captures for: {empty}"


def test_schedule_master_is_readable_and_keyed():
    """The cross-season master is the join spine the -data sibling reads."""
    import pyarrow.parquet as pq

    path = REPO_ROOT / "mbb" / "mbb_schedule_master.parquet"
    if not path.exists():
        pytest.skip("no schedule master committed")
    table = pq.read_table(path, columns=None)
    assert table.num_rows > 0
    assert "game_id" in table.schema.names
