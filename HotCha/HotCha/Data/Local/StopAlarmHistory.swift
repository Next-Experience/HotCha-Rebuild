//
//  StopAlarmHistory.swift
//  HotCha
//
//  정류장 알림을 쓴 기록. 버스 이용 기록(SwiftData)과 달리 정류장 하나와 시각뿐이라 UserDefaults 에 둔다.
//

import Foundation

struct StopAlarmRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    let stop: BusStopRecord
    let date: Date
}

enum StopAlarmHistory {
    private static let key = "stopAlarmHistory"
    private static let maxCount = 50

    static func load() -> [StopAlarmRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
            let records = try? JSONDecoder().decode([StopAlarmRecord].self, from: data)
        else {
            return []
        }
        return records
    }

    static func add(_ stop: BusStopRecord, date: Date = Date()) {
        save([StopAlarmRecord(stop: stop, date: date)] + load())
    }

    static func remove(_ id: UUID) {
        save(load().filter { $0.id != id })
    }

    private static func save(_ records: [StopAlarmRecord]) {
        guard let data = try? JSONEncoder().encode(Array(records.prefix(maxCount))) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
