#!/usr/bin/env python3
"""앱에 내장하는 TrainStations.json (기차역 이름 목록) 을 만든다.

  코레일   : 「한국철도공사_역 위치 정보」 CSV (cp949, 202개 역)
  공단     : 「국가철도공단_철도역 정보」 CSV (cp949, 215개 역)
  손으로   : Tools/train_stations_extra.csv — 두 파일에 없는 역 (SRT 역, 새 노선)

두 공공 파일의 좌표는 서로 수십 km 씩 어긋나는 역이 있고, 0,0 으로 비어 있는 역도 있다.
그래서 이 목록은 **어느 역이 있는지**와 **어디쯤인지(힌트)** 만 믿는다. 알람에 쓰는 좌표는
앱이 역을 고를 때 MapKit 으로 힌트 근처에서 다시 찾는다. 두 파일이 1km 안에서 일치하는 역만
`coord` 를 남겨, MapKit 을 못 쓸 때(오프라인) 그 좌표로 대신한다.

사용법:
  python3 Tools/build_train_stations.py <코레일.csv> <공단.csv> [출력.json]
"""
import csv
import json
import math
import os
import re
import sys

EXTRA = os.path.join(os.path.dirname(__file__), "train_stations_extra.csv")
DEFAULT_OUT = os.path.join(os.path.dirname(__file__), "..", "HotCha", "HotCha", "Resources", "TrainStations.json")
AGREE_METERS = 1000
# 같은 역인데 두 파일의 이름이 다르다. 왼쪽 이름을 오른쪽으로 합친다.
ALIASES = {"신경주": "경주"}


def normalize(name):
    name = name.strip()
    name = re.sub(r"역$", "", name)
    return ALIASES.get(name, name)


def valid(lat, lon):
    return 32.5 < lat < 39.0 and 124.0 < lon < 132.0


def decimals(text):
    return len(text.split(".")[1]) if "." in text else 0


def distance(a, b):
    p = math.pi / 180
    x = (b[1] - a[1]) * p * math.cos((a[0] + b[0]) / 2 * p)
    y = (b[0] - a[0]) * p
    return 6_371_000 * math.hypot(x, y)


def read(path):
    with open(path, encoding="cp949", newline="") as f:
        return list(csv.DictReader(f))


def point(lat_text, lon_text):
    """(위도, 경도, 정밀도) 또는 None. 정밀도는 소수 자릿수 중 작은 쪽이다."""
    try:
        lat, lon = float(lat_text), float(lon_text)
    except ValueError:
        return None
    if not valid(lat, lon):
        return None
    return (lat, lon, min(decimals(lat_text), decimals(lon_text)))


def base_lines(related):
    """'경부선(고속),경전선(고속),경부선' -> ['경부선', '경전선']"""
    seen = []
    for part in related.split(","):
        line = re.sub(r"\(.*?\)", "", part).strip()
        if line and line not in seen:
            seen.append(line)
    return seen


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    korail_path, kr_path = sys.argv[1], sys.argv[2]
    out = sys.argv[3] if len(sys.argv) > 3 else DEFAULT_OUT

    stations = {}

    def entry(name):
        return stations.setdefault(name, {"name": name, "lines": [], "region": "", "points": [], "extra": []})

    for row in read(korail_path):
        e = entry(normalize(row["역명"]))
        e["region"] = e["region"] or row["지역본부"].strip()
        if p := point(row["위도"], row["경도"]):
            e["points"].append(p)

    for row in read(kr_path):
        e = entry(normalize(row["역이름"]))
        e["lines"] = base_lines(row["관련노선"])
        e["region"] = e["region"] or row["소속지사"].strip()
        if p := point(row["위도좌표"], row["경도좌표"]):
            e["points"].append(p)

    with open(EXTRA, encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            e = entry(normalize(row["역명"]))
            e["lines"] = e["lines"] or [s for s in row["노선"].split("·") if s]
            e["extra"].append((float(row["위도"]), float(row["경도"])))

    result, report = [], {"agree": 0, "disagree": [], "single": [], "extra": [], "none": []}
    for name in sorted(stations):
        e = stations[name]
        pts = e["points"]
        coord = None
        if len(pts) >= 2 and distance(pts[0], pts[1]) <= AGREE_METERS:
            best = max(pts, key=lambda p: p[2])
            coord = [round(best[0], 6), round(best[1], 6)]
            report["agree"] += 1
        elif len(pts) >= 2:
            report["disagree"].append(f"{name}({distance(pts[0], pts[1]) / 1000:.1f}km)")
        elif len(pts) == 1:
            report["single"].append(name)
        hints = [[round(p[0], 4), round(p[1], 4)] for p in pts] + [[p[0], p[1]] for p in e["extra"]]
        if e["extra"]:
            report["extra"].append(name)
        if not hints:
            report["none"].append(name)
            continue
        item = {"name": name, "lines": e["lines"][:3], "region": e["region"], "hints": hints}
        if coord:
            item["coord"] = coord
        result.append(item)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")

    print(f"역 {len(result)}개 → {out}")
    print(f"  두 파일 일치(좌표 남김) {report['agree']}개")
    print(f"  두 파일 불일치(힌트만) {len(report['disagree'])}개: {' '.join(report['disagree'])}")
    print(f"  한 파일만(힌트만) {len(report['single'])}개: {' '.join(report['single'])}")
    print(f"  손으로 넣음 {len(report['extra'])}개: {' '.join(report['extra'])}")
    if report["none"]:
        print(f"  좌표가 하나도 없어 뺌 {len(report['none'])}개: {' '.join(report['none'])}")


if __name__ == "__main__":
    main()
