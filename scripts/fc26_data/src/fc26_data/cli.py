from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sqlite3
from urllib.parse import urlparse
from urllib.request import Request, urlopen
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ALIASES = {
    "id": ("id", "player_id", "club_id", "external_id"),
    "name": ("name", "long_name", "player_name", "club_name"),
    "club_id": ("club_id", "currentTeamId", "team_id"),
    "country_code": ("country_code", "nation_code", "iso2"),
    "position": ("position", "player_positions"),
    "overall": ("overall", "rating", "ovr"),
    "potential": ("potential",),
    "height_cm": ("height_cm", "height", "height_in_cm"),
}

KIND_PREFIXES = {
    "countries": "country",
    "leagues": "league",
    "clubs": "club",
    "players": "player",
}


def value(record: dict[str, Any], field: str) -> Any:
    for alias in ALIASES[field]:
        if record.get(alias) not in (None, ""):
            return record[alias]
    return None


def load_records(path: Path, kind: str) -> list[dict[str, Any]]:
    if path.suffix.lower() == ".csv":
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            return list(csv.DictReader(handle))
    payload = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        selected = payload.get(kind, payload.get("data", []))
        if isinstance(selected, list):
            return [item for item in selected if isinstance(item, dict)]
    raise ValueError(f"Expected a JSON array or object containing '{kind}': {path}")


def normalize(record: dict[str, Any], kind: str, source_name: str) -> dict[str, Any]:
    external_id = value(record, "id")
    name = value(record, "name")
    if external_id in (None, "") or not name:
        raise ValueError(f"Record needs an id and name: {record}")
    canonical: dict[str, Any] = {
        "id": f"{KIND_PREFIXES[kind]}:{source_name}:{external_id}",
        "sourceIds": {source_name: str(external_id)},
        "name": str(name).strip(),
        "retired": False,
    }
    if kind == "players":
        canonical.update({
            "clubId": value(record, "club_id"),
            "countryCode": value(record, "country_code"),
            "position": value(record, "position"),
            "overall": integer(value(record, "overall")),
            "potential": integer(value(record, "potential")),
            "heightCm": integer(value(record, "height_cm")),
            "attributes": {key: integer(record.get(key)) for key in
                           ("pace", "shooting", "passing", "dribbling", "defending", "physical")
                           if record.get(key) not in (None, "")},
            "subAttributes": {key: item for key, item in record.items()
                              if key not in ALIASES_KEYS and item not in (None, "")},
        })
    elif kind == "clubs":
        canonical.update({
            "leagueId": record.get("league_id") or record.get("leagueId"),
            "countryCode": value(record, "country_code"),
            "rating": integer(value(record, "overall")),
            "colors": {"primary": record.get("primaryColor"), "secondary": record.get("secondaryColor")},
            "assets": {"logo": {"url": record.get("logo_url"), "localPath": record.get("logo_path")}},
        })
    elif kind == "countries":
        canonical.update({"iso2": record.get("iso2") or record.get("code")})
    elif kind == "leagues":
        canonical.update({"countryCode": value(record, "country_code")})
    return canonical


ALIASES_KEYS = {alias for aliases in ALIASES.values() for alias in aliases}


def integer(item: Any) -> int | None:
    if item in (None, ""):
        return None
    try:
        return int(float(str(item).replace(",", ".")))
    except ValueError:
        return None


def record_hash(record: dict[str, Any]) -> str:
    encoded = json.dumps(record, ensure_ascii=True, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def sync(input_path: Path, kind: str, output_dir: Path, state_path: Path, source_name: str) -> None:
    records = [normalize(item, kind, source_name) for item in load_records(input_path, kind)]
    output_dir.mkdir(parents=True, exist_ok=True)
    state_path.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(state_path) as database:
        columns = {
            row[1]
            for row in database.execute("PRAGMA table_info(records)").fetchall()
        }
        if columns and "source_name" not in columns:
            database.execute("ALTER TABLE records RENAME TO records_legacy")
            columns = set()
        database.execute(
            "CREATE TABLE IF NOT EXISTS records ("
            "kind TEXT, source_name TEXT, record_id TEXT, hash TEXT, retired INTEGER NOT NULL DEFAULT 0, "
            "PRIMARY KEY(kind, source_name, record_id))"
        )
        changed = 0
        current_ids = set()
        for record in records:
            digest = record_hash(record)
            current_ids.add(record["id"])
            old = database.execute(
                "SELECT hash FROM records WHERE kind = ? AND source_name = ? AND record_id = ?",
                (kind, source_name, record["id"]),
            ).fetchone()
            if old is None or old[0] != digest:
                changed += 1
            database.execute(
                "INSERT OR REPLACE INTO records VALUES (?, ?, ?, ?, 0)",
                (kind, source_name, record["id"], digest),
            )
        if current_ids:
            placeholders = ",".join("?" for _ in current_ids)
            database.execute(
                f"UPDATE records SET retired = 1 WHERE kind = ? AND source_name = ? AND record_id NOT IN ({placeholders})",
                (kind, source_name, *current_ids),
            )
        else:
            database.execute(
                "UPDATE records SET retired = 1 WHERE kind = ? AND source_name = ?",
                (kind, source_name),
            )
        database.commit()

    catalog_path = output_dir / "catalog.json"
    catalog = json.loads(catalog_path.read_text(encoding="utf-8")) if catalog_path.exists() else {
        "schemaVersion": 1, "game": "EA Sports FC 26", "generatedAt": "", "countries": [], "leagues": [], "clubs": [], "players": []
    }
    with sqlite3.connect(state_path) as database:
        retired_ids = {
            record_id
            for (record_id,) in database.execute(
                "SELECT record_id FROM records WHERE kind = ? AND source_name = ? AND retired = 1",
                (kind, source_name),
            )
        }
    by_id = {item["id"]: item for item in catalog[kind]}
    for item in by_id.values():
        if item["id"] in retired_ids:
            item["retired"] = True
    by_id.update({item["id"]: item for item in records})
    catalog[kind] = sorted(by_id.values(), key=lambda item: item["id"])
    catalog["generatedAt"] = datetime.now(timezone.utc).isoformat()
    catalog_path.write_text(json.dumps(catalog, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    (output_dir / f"{kind}.json").write_text(json.dumps(catalog[kind], ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    (output_dir / "manifest.json").write_text(json.dumps({"schemaVersion": 1, "generatedAt": catalog["generatedAt"], "counts": {key: len(catalog[key]) for key in ("countries", "leagues", "clubs", "players")}}, indent=2) + "\n", encoding="utf-8")
    print(f"{kind}: {len(records)} read, {changed} changed, {len(catalog[kind])} total")


def fetch(url: str, destination: Path) -> None:
    parsed = urlparse(url)
    if parsed.scheme != "https" or not parsed.netloc:
        raise ValueError("Only absolute HTTPS source URLs are allowed")
    request = Request(url, headers={"User-Agent": "FC26-Conquest-data-pipeline/0.1"})
    with urlopen(request, timeout=30) as response:
        content = response.read()
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(content)
    print(f"fetched: {url} -> {destination} ({len(content)} bytes)")


def validate(catalog_path: Path) -> None:
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    required = {"schemaVersion", "game", "generatedAt", "countries", "leagues", "clubs", "players"}
    missing = required.difference(catalog)
    if missing:
        raise ValueError(f"Missing catalog keys: {', '.join(sorted(missing))}")
    for kind in ("countries", "leagues", "clubs", "players"):
        ids = [item.get("id") for item in catalog[kind]]
        if any(not item for item in ids) or len(ids) != len(set(ids)):
            raise ValueError(f"{kind} contains missing or duplicate IDs")
    print(f"valid: {catalog_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Normalize FC 26 source snapshots")
    commands = parser.add_subparsers(dest="command", required=True)
    sync_parser = commands.add_parser("sync")
    sync_parser.add_argument("--input", type=Path, required=True)
    sync_parser.add_argument("--kind", choices=("countries", "leagues", "clubs", "players"), required=True)
    sync_parser.add_argument("--output-dir", type=Path, default=Path("output"))
    sync_parser.add_argument("--state", type=Path, default=Path("cache/catalog.sqlite3"))
    sync_parser.add_argument("--source-name", default="input")
    fetch_parser = commands.add_parser("fetch")
    fetch_parser.add_argument("--url", required=True)
    fetch_parser.add_argument("--destination", type=Path, required=True)
    validate_parser = commands.add_parser("validate")
    validate_parser.add_argument("--catalog", type=Path, required=True)
    args = parser.parse_args()
    if args.command == "sync":
        sync(args.input, args.kind, args.output_dir, args.state, args.source_name)
    elif args.command == "fetch":
        fetch(args.url, args.destination)
    else:
        validate(args.catalog)


if __name__ == "__main__":
    main()
