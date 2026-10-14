//
//  JourneyLog.swift
//  HotCha
//
//  안내 한 번의 거리와 시간. 「나의 핫챠」의 숫자가 여기서 나온다.
//  안내를 끝낼 때 한 줄씩 쌓는다.
//

import Foundation

struct Journey: Codable, Identifiable {
    enum Kind: String, Codable {
        case bus
        case stop
    }

    var id = UUID()
    let kind: Kind
    let startedAt: Date
    let endedAt: Date
    /// 안내받는 동안 이동한 거리(m)
    let meters: Double

    var seconds: TimeInterval { max(endedAt.timeIntervalSince(startedAt), 0) }
}

enum JourneyLog {
    private static let key = "journeyLog"
    private static let maxCount = 1_000

    static func load() -> [Journey] {
        guard let data = UserDefaults.standard.data(forKey: key),
            let journeys = try? JSONDecoder().decode([Journey].self, from: data)
        else {
            return []
        }
        return journeys
    }

    static func add(_ journey: Journey) {
        guard let data = try? JSONEncoder().encode(Array(([journey] + load()).prefix(maxCount))) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }
}
