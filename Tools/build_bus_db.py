#!/usr/bin/env python3
"""앱에 내장하는 BusData.sqlite 를 만든다.

  stops  : 국토교통부 「전국 버스정류장 위치정보」 CSV (공공데이터포털 파일데이터)
  routes : 서울 버스노선 API + TAGO 버스노선정보 API 의 노선 목록

사용법:
  HOTCHA_API_KEY=<인코딩된 서비스키> python3 Tools/build_bus_db.py <정류장.csv> [출력.sqlite]

노선 목록은 도시당 한두 번만 호출한다(전체 약 150회). 노선별 정류장 순서는
여기서 받지 않고 앱이 알람을 맞출 때 한 번 조회한다.
"""
import csv
import json
import os
import sqlite3
import sys
import time
import urllib.request
import xml.etree.ElementTree as ET

SEOUL_ROUTES = "http://ws.bus.go.kr/api/rest/busRouteInfo/getBusRouteList"
TAGO = "https://apis.data.go.kr/1613000/BusRouteInfoInqireService"
SEOUL_CITY_CODE = "1"  # 앱이 서울 API 를 고르는 기준값
PAGE = 1000

METRO_SUFFIXES = ("특별자치시", "특별자치도", "특별시", "광역시")


def short_city_name(full):
    """'경상북도 안동시' -> '안동시', '서울특별시' -> '서울'"""
    last = full.split("/")[0].split()[-1]
    for suffix in METRO_SUFFIXES:
        if last.endswith(suffix):
            return last[: -len(suffix)]
    return "제주" if last == "제주도" else last


def get(url, retries=3):
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(url, timeout=60) as res:
                return res.read()
        except Exception as error:  # noqa: BLE001 - 재시도 후 그대로 올린다
            if attempt == retries - 1:
                raise
            print(f"  재시도 {attempt + 1}: {error}", file=sys.stderr)
            time.sleep(2)


def load_stops(path):
    with open(path, encoding="cp949", newline="") as f:
        for row in csv.DictReader(f):
            try:
                lat, lon = float(row["위도"]), float(row["경도"])
            except ValueError:
                continue
            # 좌표가 한국 밖이면 수집 오류다
            if not (32.5 < lat < 39.0 and 124.0 < lon < 132.0):
                continue
            yield (
                row["정류장번호"].strip(),
                row["정류장명"].strip(),
                lat,
                lon,
                row["모바일단축번호"].strip(),
                row["도시코드"].strip(),
                row["도시명"].strip(),
            )


def seoul_routes(key):
    root = ET.fromstring(get(f"{SEOUL_ROUTES}?serviceKey={key}&strSrch="))
    for item in root.iter("itemList"):
        f = lambda tag: (item.findtext(tag) or "").strip()  # noqa: E731
        yield (
            SEOUL_CITY_CODE, f("busRouteId"), f("busRouteNm"), f("busRouteAbrv"),
            f("routeType"), f("stStationNm"), f("edStationNm"),
            f("firstBusTm"), f("lastBusTm"), f("corpNm"), f("term"), f("length"),
        )


def tago_cities(key):
    data = json.loads(get(f"{TAGO}/getCtyCodeList?serviceKey={key}&_type=json"))
    return [(str(c["citycode"]), c["cityname"]) for c in data["response"]["body"]["items"]["item"]]


def tago_routes(key, city_code):
    page = 1
    while True:
        url = (f"{TAGO}/getRouteNoList?serviceKey={key}&_type=json"
               f"&cityCode={city_code}&numOfRows={PAGE}&pageNo={page}")
        body = json.loads(get(url))["response"]["body"]
        items = body.get("items") or {}
        rows = items.get("item", []) if isinstance(items, dict) else []
        if isinstance(rows, dict):  # 한 건이면 배열이 아니라 객체로 온다
            rows = [rows]
        for r in rows:
            s = lambda k: str(r.get(k, "")).strip()  # noqa: E731
            yield (
                city_code, s("routeid"), s("routeno"), s("routeno"),
                s("routetp"), s("startnodenm"), s("endnodenm"),
                s("startvehicletime"), s("endvehicletime"), "", "", "",
            )
        if page * PAGE >= int(body.get("totalCount") or 0):
            return
        page += 1


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    csv_path = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else "HotCha/HotCha/Resources/BusData.sqlite"
    key = os.environ.get("HOTCHA_API_KEY")
    if not key:
        sys.exit("HOTCHA_API_KEY 환경변수가 필요합니다.")

    if os.path.exists(out_path):
        os.remove(out_path)
    db = sqlite3.connect(out_path)
    db.executescript("""
        CREATE TABLE stops (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, lat REAL NOT NULL, lon REAL NOT NULL,
            ars TEXT NOT NULL, city_code TEXT NOT NULL
        ) WITHOUT ROWID;
        CREATE TABLE routes (
            city_code TEXT NOT NULL, route_id TEXT NOT NULL, route_no TEXT NOT NULL,
            abrv TEXT NOT NULL, route_type TEXT NOT NULL, start_name TEXT NOT NULL,
            end_name TEXT NOT NULL, first_time TEXT NOT NULL, last_time TEXT NOT NULL,
            corp TEXT NOT NULL, term TEXT NOT NULL, length TEXT NOT NULL,
            PRIMARY KEY (city_code, route_id)
        ) WITHOUT ROWID;
        CREATE TABLE cities (code TEXT PRIMARY KEY, name TEXT NOT NULL) WITHOUT ROWID;
        CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL) WITHOUT ROWID;
    """)

    cities = {}
    stop_count = 0
    for sid, name, lat, lon, ars, city_code, city_name in load_stops(csv_path):
        db.execute("INSERT OR IGNORE INTO stops VALUES (?,?,?,?,?,?)",
                   (sid, name, lat, lon, ars, city_code))
        cities.setdefault(city_code, short_city_name(city_name))
        stop_count += 1
    print(f"정류장 {stop_count}개")

    routes = list(seoul_routes(key))
    cities[SEOUL_CITY_CODE] = "서울"
    print(f"서울 노선 {len(routes)}개")
    for code, name in tago_cities(key):
        cities.setdefault(code, short_city_name(name))
        found = list(tago_routes(key, code))
        routes.extend(found)
        print(f"  {code} {name}: {len(found)}개")
    db.executemany("INSERT OR IGNORE INTO routes VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", routes)
    print(f"노선 합계 {len(routes)}개")

    db.executemany("INSERT INTO cities VALUES (?,?)", cities.items())
    db.executemany("INSERT INTO meta VALUES (?,?)", [
        ("built_at", time.strftime("%Y-%m-%d")),
        ("stops_source", os.path.basename(csv_path)),
    ])
    db.executescript("""
        CREATE INDEX stops_lat ON stops (lat);
        CREATE INDEX routes_no ON routes (route_no);
    """)
    db.commit()
    db.execute("VACUUM")
    db.close()
    print(f"{out_path}: {os.path.getsize(out_path) / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
