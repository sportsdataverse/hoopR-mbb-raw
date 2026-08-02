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
flowchart TB;
    subgraph A[hoopR-mbb-raw];
        direction TB;
        A1[python/espn_mbb_01_schedules_scrape.py]-->A2[python/espn_mbb_02_pbp_scrape.py];
    end;

    subgraph B[hoopR-mbb-data];
        direction TB;
        B1[R/espn_mbb_01_pbp_creation.R]-->B2[R/espn_mbb_02_team_box_creation.R];
        B2[R/espn_mbb_02_team_box_creation.R]-->B3[R/espn_mbb_03_player_box_creation.R];
    end;

    subgraph C[sportsdataverse Releases];
        direction TB;
        C1[espn_mens_college_basketball_pbp];
        C2[espn_mens_college_basketball_team_boxscores];
        C3[espn_mens_college_basketball_player_boxscores];
    end;

    A-->B;
    B-->C1;
    B-->C2;
    B-->C3;

```

Script numbers are run order — `01` writes the season schedule that `02` reads
to enumerate games. `05` (draft) is an intentional hole: the stage numbering is
shared across the nba/mbb/wnba raw repos, and MBB has no draft dataset.

[hoopR-nba-raw data repository (source: ESPN)](https://github.com/sportsdataverse/hoopR-nba-raw)

[hoopR-nba-data repository (source: ESPN)](https://github.com/sportsdataverse/hoopR-nba-data)

[hoopR-nba-stats-data Repo (source: NBA Stats)](https://github.com/sportsdataverse/hoopR-nba-stats-data)

[hoopR-mbb-raw data repository (source: ESPN)](https://github.com/sportsdataverse/hoopR-mbb-raw)

[hoopR-mbb-data repository (source: ESPN)](https://github.com/sportsdataverse/hoopR-mbb-data)

[hoopR-kp-data Repo (source: KenPom)](https://github.com/sportsdataverse/hoopR-kp-data)