#!/bin/bash
# Scrape raw ESPN MBB game JSON, schedules and per-dataset payloads
# Usage: bash scripts/daily_mbb_scraper.sh -s 2025 -e 2025

while getopts s:e:r: flag
do
    case "${flag}" in
        s) START_YEAR=${OPTARG};;
        e) END_YEAR=${OPTARG};;
        r) RESCRAPE=${OPTARG};;
    esac
done

RESCRAPE=${RESCRAPE:-TRUE}
echo "Rescrape set to: $RESCRAPE"
mkdir -p logs

# Fail fast on a stale sportsdataverse, BEFORE any scraping.
#
# This repo has already lost a stage to exactly that -- see the note below:
# espn_mbb_06 aborted at import on a removed symbol every day for two release
# cycles while the run stayed green. run_scraper (added for that incident)
# turns such a day red at the END; this turns it red before it starts, and
# names the fix. wehoop-wnba-raw lost three weeks of in-season scraping to the
# same class on 2026-08-02: a persistent runner sat on sportsdataverse 0.0.50
# because pip does not upgrade an already-satisfied `>=` requirement.
if ! python3 - <<'PY'
from sportsdataverse.dl_utils import download  # noqa: F401
from sportsdataverse.scrape.espn.cli import str2bool  # noqa: F401
from sportsdataverse.scrape.espn.persist import write_payload  # noqa: F401
import sportsdataverse.mbb  # noqa: F401
PY
then
    echo "FATAL: the sportsdataverse surface these scrapers need is missing."
    echo "       Fix: pip install --upgrade -r requirements.txt"
    echo "         && pip install --force-reinstall --no-deps \\"
    echo "            'sportsdataverse @ git+https://github.com/sportsdataverse/sportsdataverse-py@main'"
    echo "       The second line is required, not belt-and-braces: pip decides"
    echo "       satisfaction by VERSION, so a git branch whose version string"
    echo "       has not changed is a silent no-op even with --upgrade."
    exit 1
fi

# Scraper failures used to be swallowed: each scraper ran bare, so a crash left
# the loop running, the partial day got committed, and the job still exited 0.
# espn_mbb_06_player_stats_scrape.py sat dead for two sportsdataverse-py release cycles
# that way -- aborting at import on a removed symbol, every day, silently green.
#
# run_scraper keeps that resilience (one dead scraper must not stop the others,
# and whatever DID scrape should still be committed) but records the failure so
# the run goes RED at the end and someone actually looks.
#
# NOTE: the scrapers run inside `{ ... } | tee`, and a pipe is a SUBSHELL -- a
# counter variable incremented in there is discarded when it exits. That's why
# failures go to a FILE. Do not "simplify" this to a FAILED=$((FAILED+1)) var.
FAILLOG=$(mktemp "/tmp/hoopR_mbb_raw_failures.XXXXXX")
trap 'rm -f "$FAILLOG"' EXIT

run_scraper() {
    local label="$1"; shift
    "$@"
    local rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "!!! SCRAPER FAILED (rc=$rc): $label"
        echo "$label rc=$rc" >> "$FAILLOG"
    fi
    return 0
}
for i in $(seq "${START_YEAR}" "${END_YEAR}")
do
    LOGFILE="logs/hoopR_mbb_raw_logfile_${i}.log"
    TMPLOG=$(mktemp "/tmp/hoopR_mbb_raw_logfile_${i}.XXXXXX.log")
    echo "=== Processing season $i ==="
    # Tee inside the block writes to /tmp (untracked) so the `git pull` calls
    # don't trip over their own log output being written to a tracked file.
    {
        git pull >> /dev/null
        git config --local user.email "action@github.com"
        git config --local user.name "Github Action"
        run_scraper schedules    python3 python/espn_mbb_01_schedules_scrape.py    -s $i -e $i -r $RESCRAPE
        run_scraper json         python3 python/espn_mbb_02_pbp_scrape.py          -s $i -e $i -r $RESCRAPE
        run_scraper standings    python3 python/espn_mbb_03_standings_scrape.py    -s $i -e $i -r $RESCRAPE
        run_scraper game_rosters python3 python/espn_mbb_04_game_rosters_scrape.py -s $i -e $i -r $RESCRAPE
        run_scraper player_stats python3 python/espn_mbb_06_player_stats_scrape.py -s $i -e $i -r $RESCRAPE
        run_scraper player_core  python3 python/espn_mbb_09_player_core_scrape.py  -s $i -e $i -r $RESCRAPE
        run_scraper team_stats   python3 python/espn_mbb_07_team_stats_scrape.py   -s $i -e $i -r $RESCRAPE
        run_scraper team_rosters python3 python/espn_mbb_08_team_rosters_scrape.py -s $i -e $i -r $RESCRAPE
        git pull >> /dev/null
        git add mbb/* >> /dev/null
        git add mbb/mbb_schedule_master.* >> /dev/null
        git pull >> /dev/null
        git add . >> /dev/null
        git commit -m "MBB Raw Updated (Start: $i End: $i)" || echo "No changes to commit"
        git pull >> /dev/null
        git push >> /dev/null
    } 2>&1 | tee "$TMPLOG"

    # Block is finished and pushed; tee has closed $TMPLOG. Now copy the log
    # into its tracked location and commit/push it on its own.
    cp "$TMPLOG" "$LOGFILE"
    git pull --rebase >> /dev/null || true
    git add "$LOGFILE"
    git commit -m "MBB Raw log update (Start: $i End: $i)" >> /dev/null || echo "No log changes to commit"
    git push >> /dev/null
    rm -f "$TMPLOG"
done

# Everything that could scrape has scraped, and every partial result is
# committed and pushed -- only now do we decide the exit code. A dead scraper
# must turn the run RED; a green run over silently-missing data is worse than
# an obvious failure.
if [ -s "$FAILLOG" ]; then
    echo ""
    echo "=================================================="
    echo "SCRAPER FAILURES (data for these is NOT up to date)"
    cat "$FAILLOG"
    echo "=================================================="
    exit 1
fi
echo "All scrapers OK."
