# CLAUDE.md — hoopR-mbb-raw Development Guide

## Repo Overview

`hoopR-mbb-raw` is the Python-side scraper that pulls ESPN men's college
basketball schedules and per-game JSON, persists them to disk under
`mbb/schedules/` and `mbb/json/final/{game_id}.json`, and commits the
results back to this repo. Every push to `main` fires a `repository_dispatch`
that wakes up the downstream R parser in `hoopR-mbb-data`. This repo is
the authoritative cache of raw ESPN MBB payloads — the parsing layer
never re-hits ESPN, it reads from here.

## Pipeline Position

```
ESPN APIs --[python scrape]--> hoopR-mbb-raw [HERE]
                                    | push trigger
                                    v
                               hoopR-mbb-data --[release upload]--> sportsdataverse-data
                                                                          | piggyback
                                                                          v
                                                                       hoopR R package
```

The push trigger is `.github/workflows/hoopR_mbb_data_trigger.yaml`, which
fires `repository_dispatch` event-type `daily_mbb_data` against
`sportsdataverse/hoopR-mbb-data`.

## Build & Development Commands

The repo is driven by `scripts/daily_mbb_scraper.sh`, which sequences
schedule scraping then per-game JSON scraping, then commits + pushes.
Seasons are integer end-years (e.g. the 2024–25 NCAA MBB season is `2025`).

```sh
# Full daily flow for one or more seasons (CI entry point)
bash scripts/daily_mbb_scraper.sh -s 2025 -e 2025 -r false

# Or call the scrapers directly when iterating
python3 python/scrape_mbb_schedules.py -s 2025 -e 2025 -r false
python3 python/scrape_mbb_json.py      -s 2025 -e 2025 -r false

# Helpers
python3 python/process_mbb_schedules.py
python3 python/add_game_links_to_schedule.py
```

`-r true` forces re-scrape of games already on disk; `-r false` skips
existing files. Output paths the scrapers write under:

- `mbb/schedules/{rds,csv,parquet}/mbb_schedule_{year}.{ext}`
- `mbb/mbb_schedule_master.parquet` — concatenated cross-season master schedule
- `mbb/json/final/{game_id}.json` — clean payload, consumed by `hoopR-mbb-data`
- `mbb/json/raw/{game_id}.json`   — raw ESPN response (kept for forensics)
- `mbb/errors/`                   — failed-game records

## Project Structure

```
python/
  scrape_mbb_schedules.py      # ESPN schedule scrape -> mbb/schedules/
  scrape_mbb_json.py           # Per-game JSON scrape -> mbb/json/final/{game_id}.json
  process_mbb_schedules.py     # Schedule post-processing -> mbb_schedule_master.parquet
  add_game_links_to_schedule.py
scripts/
  daily_mbb_scraper.sh         # CI entry point
mbb/                           # Committed scraped output (consumed downstream)
.github/workflows/
  hoopR_mbb_data_trigger.yaml  # Fires repository_dispatch on push
```

## Daily Workflow

The shell entry point `scripts/daily_mbb_scraper.sh` loops over the
requested year range and, for each season, runs the two scrapers
sequentially then commits + pushes a single time. Each push fires
`hoopR_mbb_data_trigger.yaml`, which dispatches `daily_mbb_data` to
`hoopR-mbb-data`.

- **Commit message format**: the script emits
  `"MBB Raw Updated (Start: $i End: $i)"`. The downstream
  trigger workflow parses the year span out of this subject line, so
  the wording is load-bearing — do not reformat it.
- The Python scrapers depend on `sportsdataverse-py`; they call
  `sdv.mbb.espn_mbb_pbp(game_id, raw=True)`, `sdv.mbb.espn_mbb_calendar()`,
  `sdv.mbb.espn_mbb_schedule()` and similar helpers. Bug fixes to ESPN
  parsing belong in `sportsdataverse-py` MBB modules — not here.
- Schedule scrape: iterates `espn_mbb_calendar(season, ondays=True)` →
  per-day `espn_mbb_schedule(dates=d)` → concatenated, filtered to
  `season_type ∈ {2, 3}` (regular season + postseason), de-duplicated on
  `game_id`, written to `rds`/`parquet` (and `csv` where wired up).
- JSON scrape: per `game_id` from the schedule, calls
  `espn_mbb_pbp(game_id, raw=True)` and writes the final payload under
  `mbb/json/final/{game_id}.json` plus the raw response under
  `mbb/json/raw/{game_id}.json`. Failures land in `mbb/errors/`.

## Cross-Repo References

- Downstream parser: <https://github.com/sportsdataverse/hoopR-mbb-data>
- Sister repo (NBA, ESPN side): <https://github.com/sportsdataverse/hoopR-nba-raw>
- Shared conventions and broader context: <https://github.com/sportsdataverse/hoopR/blob/main/CLAUDE.md>
- Python scraper internals (the SDK this repo calls): <https://github.com/sportsdataverse/sportsdataverse-py/blob/main/CLAUDE.md>

## Project-Specific Gotchas

- `python/scrape_mbb_json.py` writes JSON under `mbb/json/final/{game_id}.json`. Downstream `hoopR-mbb-data` reads from `https://raw.githubusercontent.com/sportsdataverse/hoopR-mbb-raw/main/mbb/...`, so the file paths and commit-to-main are load-bearing.
- The per-push `hoopR_mbb_data_trigger.yaml` workflow only fires on `push` and `workflow_dispatch`. Force-pushes can land changes without firing downstream jobs — push normally.
- Large additions of `mbb/json/final/*.json` files inflate the repo. Don't reorganize the `mbb/` tree without coordinating the change in `hoopR-mbb-data`'s creation scripts (`R/espn_mbb_0[1-3]_*.R`).
- ESPN JSON schema drift is handled in `sportsdataverse-py` (the call boundary). If a scraper starts dropping fields, fix the SDK first; this repo should stay thin.
- The commit subject string is parsed downstream — keep `"MBB Raw Updated (Start: <year> End: <year>)"` intact in `scripts/daily_mbb_scraper.sh`.
- College basketball season type 3 (postseason / NCAA Tournament) IDs surface late in the calendar — re-scrape (`-r true`) targeted dates around Selection Sunday and the First Four to catch the bracket fully.

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) for
manual / feature commits:

```
feat(scrape): handle NCAA Tournament bracket ID range in scrape_mbb_schedules.py
fix(scrape): retry HTTP 429s in scrape_mbb_json with backoff
chore(deps): bump sportsdataverse-py pin in requirements.txt
ci: tighten secret scoping in hoopR_mbb_data_trigger.yaml
```

Prefer scoped subjects (`feat(scrape): ...`, `ci(trigger): ...`). Use
`type!:` or a `BREAKING CHANGE:` footer for breaking changes. Split
unrelated work into separate commits for reviewability.

**Exception**: daily umbrella commits emitted by `scripts/daily_mbb_scraper.sh`
must keep the literal subject `"MBB Raw Updated (Start: YYYY End: YYYY)"`
— the downstream dispatch workflow parses years out of that subject.

**Important: Never include AI agents or assistants (e.g., Claude, Copilot, Cursor, GPT, Gemini) as co-authors on commits.** Omit all `Co-Authored-By` trailers referencing AI tools. This applies whether the change was generated, refactored, or reviewed with AI assistance — the human author is the sole attributable contributor.
