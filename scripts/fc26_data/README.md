# FC 26 data pipeline

This first slice imports local JSON or CSV snapshots. It does not scrape a site by default.
That keeps source licensing, rate limits, and provenance explicit before adding a source adapter.

## Setup

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
py -m pip install -e .
```

## Commands

```powershell
fc26-data fetch --url https://raw.githubusercontent.com/OWNER/REPO/main/players.json --destination raw/players.json
fc26-data sync --input raw/players.json --kind players --source-name github-datahub --output-dir output
fc26-data sync --input snapshot.json --kind players --output-dir output
fc26-data sync --input clubs.csv --kind clubs --output-dir output
fc26-data validate --catalog output/catalog.json
```

`fetch` accepts only explicit HTTPS URLs and stores the untouched response. Replace the example
GitHub URL only after checking the repository license, revision, and file format.

Input may be a JSON array or an object containing `countries`, `leagues`, `clubs`, or `players`.
The SQLite state file stores source-scoped IDs and record hashes, so unchanged records are skipped on later runs.
Records missing from a later snapshot remain in the catalog with `retired: true` instead of silently disappearing.

Do not commit raw datasets or downloaded images until their license and redistribution terms are recorded.
