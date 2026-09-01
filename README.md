# hoopR-mbb-raw

```mermaid
  graph LR;
    A[hoopR-mbb-raw]-->B[hoopR-mbb-data];
    B[hoopR-mbb-data]-->C1[espn_mens_college_basketball_pbp];
    B[hoopR-mbb-data]-->C2[espn_mens_college_basketball_team_boxscores];
    B[hoopR-mbb-data]-->C3[espn_mens_college_basketball_player_boxscores];

```

## hoopR ESPN MBB workflow diagram

```mermaid
  graph LR;
    A[hoopR-mbb-raw]-->B[hoopR-mbb-data];
    B[hoopR-mbb-data]-->C1[espn_mens_college_basketball_schedules];
    B[hoopR-mbb-data]-->C2[espn_mens_college_basketball_pbp];
    B[hoopR-mbb-data]-->C3[espn_mens_college_basketball_team_boxscores];
    B[hoopR-mbb-data]-->C4[espn_mens_college_basketball_player_boxscores];
    B[hoopR-mbb-data]-->C5[espn_mens_college_basketball_rosters];
    B[hoopR-mbb-data]-->C6[espn_mens_college_basketball_game_rosters];
    B[hoopR-mbb-data]-->C7[espn_mens_college_basketball_player_core];
    B[hoopR-mbb-data]-->C8[espn_mens_college_basketball_player_season_stats];
    B[hoopR-mbb-data]-->C9[espn_mens_college_basketball_team_season_stats];
    B[hoopR-mbb-data]-->C10[espn_mens_college_basketball_standings];
    B[hoopR-mbb-data]-->C11[espn_mens_college_basketball_officials];
    B[hoopR-mbb-data]-->C12[espn_mens_college_basketball_shots];
    B[hoopR-mbb-data]-->C13[mbb_crosswalk];
```

```mermaid
flowchart TB;
    subgraph A[hoopR-mbb-raw];
        direction TB;
        A0[scripts/daily_mbb_scraper.sh]-->A1[python/espn_mbb_01_schedules_scrape.py];
        A1[python/espn_mbb_01_schedules_scrape.py]-->A2[python/espn_mbb_02_pbp_scrape.py];
        A2[python/espn_mbb_02_pbp_scrape.py]-->A3[python/espn_mbb_03_standings_scrape.py];
        A3[python/espn_mbb_03_standings_scrape.py]-->A4[python/espn_mbb_04_game_rosters_scrape.py];
        A4[python/espn_mbb_04_game_rosters_scrape.py]-->A5[python/espn_mbb_06_player_stats_scrape.py];
        A5[python/espn_mbb_06_player_stats_scrape.py]-->A6[python/espn_mbb_07_team_stats_scrape.py];
        A6[python/espn_mbb_07_team_stats_scrape.py]-->A7[python/espn_mbb_08_team_rosters_scrape.py];
        A7[python/espn_mbb_08_team_rosters_scrape.py]-->A8[python/espn_mbb_09_player_core_scrape.py];
    end;

    subgraph B[hoopR-mbb-data];
        direction TB;
        B0[scripts/daily_mbb_data_processor.sh]-->B1[python/espn_mbb_01_pbp_creation.py];
        B1[python/espn_mbb_01_pbp_creation.py]-->B2[python/espn_mbb_02_team_box_creation.py];
        B2[python/espn_mbb_02_team_box_creation.py]-->B3[python/espn_mbb_03_player_box_creation.py];
        B3[python/espn_mbb_03_player_box_creation.py]-->B4[python/espn_mbb_04_rosters_creation.py];
        B4[python/espn_mbb_04_rosters_creation.py]-->B5[python/espn_mbb_05_player_season_stats_creation.py];
        B5[python/espn_mbb_05_player_season_stats_creation.py]-->B6[python/espn_mbb_06_team_season_stats_creation.py];
        B6[python/espn_mbb_06_team_season_stats_creation.py]-->B7[python/espn_mbb_07_standings_creation.py];
        B7[python/espn_mbb_07_standings_creation.py]-->B8[python/espn_mbb_09_game_rosters_creation.py];
        B8[python/espn_mbb_09_game_rosters_creation.py]-->B9[python/espn_mbb_10_officials_creation.py];
        B9[python/espn_mbb_10_officials_creation.py]-->B10[python/espn_mbb_11_team_crosswalk_creation.py];
        B10[python/espn_mbb_11_team_crosswalk_creation.py]-->B11[python/espn_mbb_12_schedule_crosswalk_creation.py];
        B11[python/espn_mbb_12_schedule_crosswalk_creation.py]-->B12[python/espn_mbb_13_player_crosswalk_creation.py];
        B12[python/espn_mbb_13_player_crosswalk_creation.py]-->B13[python/espn_mbb_14_schedules_creation.py];
        B13[python/espn_mbb_14_schedules_creation.py]-->B14[python/espn_mbb_15_shots_creation.py];
        B14[python/espn_mbb_15_shots_creation.py]-->B15[python/espn_mbb_16_player_core_creation.py];
    end;

    subgraph C[sportsdataverse-data Releases];
        direction TB;
        C1[espn_mens_college_basketball_schedules];
        C2[espn_mens_college_basketball_pbp];
        C3[espn_mens_college_basketball_team_boxscores];
        C4[espn_mens_college_basketball_player_boxscores];
        C5[espn_mens_college_basketball_rosters];
        C6[espn_mens_college_basketball_game_rosters];
        C7[espn_mens_college_basketball_player_core];
        C8[espn_mens_college_basketball_player_season_stats];
        C9[espn_mens_college_basketball_team_season_stats];
        C10[espn_mens_college_basketball_standings];
        C11[espn_mens_college_basketball_officials];
        C12[espn_mens_college_basketball_shots];
        C13[mbb_crosswalk];
    end;

    A-->B;
    B-->C;
```

`scripts/daily_mbb_scraper.sh` and `scripts/daily_mbb_data_processor.sh` are the
daily drivers (the `00` role); stage numbers are intended build order, not run order.

Stage numbers are stable cross-repo identifiers, so holes are expected —
`05` (draft) is NBA-only and intentionally vacant on the MBB side.

[hoopR-mbb-raw repository (source: ESPN)](https://github.com/sportsdataverse/hoopR-mbb-raw)

[hoopR-mbb-data repository (source: ESPN)](https://github.com/sportsdataverse/hoopR-mbb-data)

[hoopR-nba-raw repository (source: ESPN)](https://github.com/sportsdataverse/hoopR-nba-raw)

[hoopR-nba-data repository (source: ESPN)](https://github.com/sportsdataverse/hoopR-nba-data)

[hoopR-nba-stats-raw repository (source: NBA Stats)](https://github.com/sportsdataverse/hoopR-nba-stats-raw)

[hoopR-nba-stats-data repository (source: NBA Stats)](https://github.com/sportsdataverse/hoopR-nba-stats-data)

[ncaa-mbb-hoops-raw repository (source: stats.ncaa.org)](https://github.com/sportsdataverse/ncaa-mbb-hoops-raw)

[ncaa-mbb-hoops-data repository (source: stats.ncaa.org)](https://github.com/sportsdataverse/ncaa-mbb-hoops-data)

[hoopR-kp-data repository (source: KenPom, dormant)](https://github.com/sportsdataverse/hoopR-kp-data)

## Reports & explainers

<!-- BEGIN GENERATED: reports -->

| Report | What it is | Last updated |
|---|---|---|
| _none yet_ | — | — |

<!-- END GENERATED: reports -->

## Automation & status

<!-- BEGIN GENERATED: status -->

| workflow | schedule | last run |
|---|---|---|
| [![orphan_scripts.yml](https://github.com/sportsdataverse/hoopR-mbb-raw/actions/workflows/orphan_scripts.yml/badge.svg)](https://github.com/sportsdataverse/hoopR-mbb-raw/actions/workflows/orphan_scripts.yml) | on push / PR / dispatch | 2026-08-19 |
| [![tests.yml](https://github.com/sportsdataverse/hoopR-mbb-raw/actions/workflows/tests.yml/badge.svg)](https://github.com/sportsdataverse/hoopR-mbb-raw/actions/workflows/tests.yml) | on push / PR / dispatch | 2026-08-19 |
| [![hoopR_mbb_data_trigger.yaml](https://github.com/sportsdataverse/hoopR-mbb-raw/actions/workflows/hoopR_mbb_data_trigger.yaml/badge.svg)](https://github.com/sportsdataverse/hoopR-mbb-raw/actions/workflows/hoopR_mbb_data_trigger.yaml) | on push / dispatch | 2026-08-19 |

<!-- END GENERATED: status -->
