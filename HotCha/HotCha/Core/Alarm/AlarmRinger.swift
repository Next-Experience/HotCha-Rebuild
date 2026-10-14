//
//  AlarmRinger.swift
//  HotCha
//
//  내릴 때가 되면 AlarmKit 시스템 알람을 바로 울린다. 무음 모드 · 집중 모드에서도 울린다 (결정 0005).
//  언제 울릴지는 알람 엔진(노선 · 정류장)이 정하고, 여기서는 울리고 끄기만 한다.
//

import AlarmKit
import Foundation
import SwiftUI

/// 알람에 따로 실어 보낼 값은 없다. AlarmKit 이 메타데이터 타입을 요구해서 둔다.
struct HotChaAlarmMetadata: AlarmMetadata {}

extension Notification.Name {
    /// 사용자가 시스템 알람 화면에서 알람을 껐다. 앱의 알람 화면도 닫는다.
    static let systemAlarmStopped = Notification.Name("HotChaSystemAlarmStopped")
}

@MainActor
final class AlarmRinger: ObservableObject {
    static let shared = AlarmRinger()

    @Published private(set) var authorization: AlarmManager.AuthorizationState

    private let manager = AlarmManager.shared
    /// 지금 울리고 있는 알람. 없으면 nil 이다.
    private var ringingID: Alarm.ID?
    /// 시스템 알람 목록에서 그 알람을 한 번이라도 봤는가. 건 직후 목록에 아직 없을 때를 꺼진 것으로 읽지 않는다.
    private var seenInSystem = false
    /// 알람을 지금보다 이만큼 뒤로 건다. AlarmKit 은 지난 시각의 `.fixed` 알람을 받지 않는다.
    private static let scheduleLead: TimeInterval = 1

    private init() {
        authorization = manager.authorizationState
        Task { [weak self] in
            guard let updates = self?.manager.authorizationUpdates else { return }
            for await state in updates {
                self?.authorization = state
            }
        }
        Task { [weak self] in
            guard let updates = self?.manager.alarmUpdates else { return }
            for await alarms in updates {
                self?.handle(alarms)
            }
        }
    }

    /// 아직 묻지 않았으면 알람 권한을 묻는다. 안내를 시작할 때 부른다.
    func requestAuthorizationIfNeeded() {
        guard authorization == .notDetermined else { return }
        Task {
            if let state = try? await manager.requestAuthorization() {
                authorization = state
            }
        }
    }

    /// 지금 바로 울린다. 이미 울리고 있으면 그대로 둔다.
    /// - Parameter title: 시스템 알람 화면의 제목. "미아초교에서 내려요"
    func ring(title: String) {
        guard ringingID == nil else { return }
        let id = UUID()
        ringingID = id
        seenInSystem = false
        let attributes = AlarmAttributes<HotChaAlarmMetadata>(
            presentation: AlarmPresentation(alert: .init(title: LocalizedStringResource(stringLiteral: title))),
            metadata: HotChaAlarmMetadata(),
            tintColor: Color("mainpurple")
        )
        Task {
            do {
                // 권한을 아직 묻지 않았으면 여기서 묻는다. 거절하면 아래에서 실패한다.
                if manager.authorizationState == .notDetermined {
                    authorization = try await manager.requestAuthorization()
                }
                // 지금 시각으로 걸면 시스템에 닿을 때는 이미 지난 시각이라 거절된다(invalidInput). 조금 뒤로 건다.
                _ = try await manager.schedule(
                    id: id,
                    configuration: .alarm(
                        schedule: .fixed(Date().addingTimeInterval(Self.scheduleLead)), attributes: attributes)
                )
            } catch {
                // 권한이 없거나 한도에 걸리면 시스템 알람은 못 울린다. 앱 안 알람 화면은 그대로 뜬다.
                if ringingID == id { ringingID = nil }
            }
        }
    }

    /// 울리는 알람을 끈다. 앱의 「확인했어요」 · 「안내 종료」가 부른다.
    func stop() {
        guard let id = ringingID else { return }
        ringingID = nil
        try? manager.stop(id: id)
        try? manager.cancel(id: id)
    }

    /// 시스템 알람 화면에서 끄면 목록에서 사라진다. 그때 앱에도 알린다.
    private func handle(_ alarms: [Alarm]) {
        guard let id = ringingID else { return }
        if alarms.contains(where: { $0.id == id }) {
            seenInSystem = true
            return
        }
        guard seenInSystem else { return }
        ringingID = nil
        NotificationCenter.default.post(name: .systemAlarmStopped, object: nil)
    }
}
