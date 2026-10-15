//
//  HistoryEntry.swift
//  HotCha
//
//  이용 기록 한 줄. 버스 알림과 정류장 알림을 한 목록에서 다룬다.
//

import SwiftUI

enum HistoryEntry: Identifiable {
    case bus(Usage_history)
    case stop(StopAlarmRecord)

    enum Kind: String, CaseIterable, Identifiable {
        case bus = "버스"
        case stop = "정류장"
        case train = "기차역"
        var id: String { rawValue }
    }

    /// 버스 기록과 정류장 기록을 최근 것부터 한 줄로 섞는다.
    static func merged(buses: [Usage_history], stops: [StopAlarmRecord]) -> [HistoryEntry] {
        (buses.map(HistoryEntry.bus) + stops.map(HistoryEntry.stop)).sorted { $0.date > $1.date }
    }

    var id: String {
        switch self {
        case .bus(let history): return "bus-\(history.persistentModelID.hashValue)"
        case .stop(let record): return "stop-\(record.id.uuidString)"
        }
    }

    var kind: Kind {
        switch self {
        case .bus: return .bus
        case .stop(let record): return record.stop.isTrainStation ? .train : .stop
        }
    }

    var date: Date {
        switch self {
        case .bus(let history): return history.get_off_timestamp
        case .stop(let record): return record.date
        }
    }

    var title: String {
        switch self {
        case .bus(let history): return "\(history.bus_no)번 · \(history.destination_stop_name)"
        case .stop(let record): return record.stop.name
        }
    }

    /// "버스 · 10월 14일 오전 2:45" 처럼 종류와 시각을 함께 적는다. 색에만 기대지 않는다.
    var subtitle: String {
        // 화면 문구가 한국어라 날짜도 기기 언어와 상관없이 한국어로 적는다.
        let format = Date.FormatStyle(date: .abbreviated, time: .shortened).locale(Locale(identifier: "ko_KR"))
        return "\(kind.rawValue) · \(date.formatted(format))"
    }

    /// 클레이 그림이 없는 종류는 시스템 기호로 그린다. 기차역이 그렇다.
    var symbolName: String? {
        kind == .train ? "train.side.front.car" : nil
    }

    var imageName: String {
        switch self {
        case .bus(let history):
            return BusArt.imageName(routeType: history.route_type, busNumber: history.bus_no, cityCode: history.city_code)
        case .stop:
            return Clay.busStop.rawValue
        }
    }

    /// 같은 곳으로 다시 안내를 시작하는 화면
    var destination: SearchDestination {
        switch self {
        case .bus(let history):
            return .route(Bus_info_seoul(from: history.bus), startingAt: history.destination_stop_id)
        case .stop(let record):
            return .stop(record.stop)
        }
    }
}

/// 홈과 이용 기록 탭이 함께 쓰는 한 줄
struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        HStack(spacing: 14) {
            if let symbol = entry.symbolName {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color("mainpurple"))
                    .frame(width: 48, height: 48)
                    .background(
                        Color("mainpurple").opacity(0.10),
                        in: RoundedRectangle(cornerRadius: HotChaRadius.tile, style: .continuous)
                    )
                    .accessibilityHidden(true)
            } else {
                ClayIcon(imageName: entry.imageName)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(entry.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}
