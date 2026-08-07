# hoopR-mbb-raw Copilot Instructions

## Project Context

This repo is the Python ESPN-scrape stage for men's college basketball.
It writes per-game JSON under `mbb/json/final/{game_id}.json` and
schedules under `mbb/schedules/` and commits results to `main`. Every
push wakes the downstream R parser in `hoopR-mbb-data` via
`repository_dispatch` (event-type `daily_mbb_data`, defined in
`.github/workflows/hoopR_mbb_data_trigger.yaml`).

Pipeline: `ESPN -> hoopR-mbb-raw [HERE] -> hoopR-mbb-data -> sportsdataverse-data -> hoopR`.

Sister repo (same shape, NBA): `hoopR-nba-raw`. Downstream R parser
companion: `hoopR-mbb-data`.

## Repository Workflow

- Branch from `main`; `main` is the default and release branch.
- The CI / cron entry point is
  `scripts/daily_mbb_scraper.sh -s <START> -e <END> -r <true|false>`.
- Scrapers shell out to `sportsdataverse-py`. Fix ESPN parser bugs
  upstream there, not here.
- Don't reorganize the `mbb/` output tree without aligning
  `hoopR-mbb-data/R/espn_mbb_0[1-3]_*.R`.
- The daily umbrella commit subject `"MBB Raw Updated (Start: YYYY End: YYYY)"`
  is parsed by the trigger workflow downstream — keep it intact.

## Build & Development Commands

```sh
bash scripts/daily_mbb_scraper.sh -s 2025 -e 2025 -r false
uv run python python/espn_mbb_01_schedules_scrape.py -s 2025 -e 2025 -r false
uv run python python/espn_mbb_02_pbp_scrape.py       -s 2025 -e 2025 -r false
uv run python python/add_game_links_to_schedule.py
```

`-r true` forces re-scrape; `-r false` skips files already on disk.
Seasons are integer end-years (`2025` = 2024–25 season).

Outputs:

- `mbb/schedules/{rds,csv,parquet}/mbb_schedule_{year}.{ext}`
- `mbb/mbb_schedule_master.parquet` (cross-season master)
- `mbb/json/final/{game_id}.json` (consumed downstream)
- `mbb/json/raw/{game_id}.json`, `mbb/errors/` (forensics)

## Code Style

- Follow the parent SDK's Python conventions: `snake_case`, 4-space indent.
- Prefer `pathlib.Path`, `concurrent.futures` for parallelism, `tqdm` for
  progress.
- Don't add bespoke ESPN parsing here — call into `sportsdataverse.mbb.*`
  and persist its output. Schedule scrape uses
  `sdv.mbb.espn_mbb_calendar()` + `sdv.mbb.espn_mbb_schedule()`; JSON
  scrape uses `sdv.mbb.espn_mbb_pbp(game_id, raw=True)`.
- Deps are uv-managed (`pyproject.toml` + `uv.lock`); `uv sync` to install.
  There is no `requirements.txt`.
- Filter `season_type ∈ {2, 3}` when assembling schedules (regular
  season + postseason; preseason and exhibitions excluded).
- Game IDs are integers as strings; do not zero-pad.

## Cross-Repo References

- Shared conventions: <https://github.com/sportsdataverse/hoopR/blob/main/CLAUDE.md>
- SDK internals: <https://github.com/sportsdataverse/sportsdataverse-py/blob/main/CLAUDE.md>
- Downstream parser: <https://github.com/sportsdataverse/hoopR-mbb-data>

## Conventional Commits

Use: `type(scope): description` for manual work. Common types: `feat`,
`fix`, `chore`, `ci`, `docs`, `refactor`. Use `type!:` or a
`BREAKING CHANGE:` footer for breaking changes.

**Exception**: daily umbrella commits emitted by
`scripts/daily_mbb_scraper.sh` keep the literal subject
`"MBB Raw Updated (Start: YYYY End: YYYY)"` — required by the
downstream dispatch workflow.

**Important: Never include AI agents or assistants (e.g., Claude, Copilot, Cursor, GPT, Gemini) as co-authors on commits.** Omit all `Co-Authored-By` trailers referencing AI tools. This applies whether the change was generated, refactored, or reviewed with AI assistance — the human author is the sole attributable contributor.
