//
//  Liveact.swift
//  HotCha
//
//  Created by 문재윤 on 5/6/25.
//

////
////  MyLiveActivityAttributes.swift
////  HotCha
////
////  Created by 문재윤 on 5/6/25.
////


import ActivityKit


struct HotchaLiveAttributes: ActivityAttributes {
    // 공통 속성 정의 (예: 제목, 설명 등)
    public struct ContentState: Codable, Hashable {
        var progress: Double       // 진행 상태 (0.0 ~ 1.0)
        var currentStop: String    // 현재 정류장
        var stopsRemaining: Int    // 남은 정류장 수
        var alarmstop: String       // 알람 정류장
        var destinationStation: String // 도착 정류장
        var Updatetime: String // 업데이트 시간
    }

    // 라이브 액티비티의 일반적인 속성 (변하지 않는 값)
    var title: String // 제목
    var description: String // 설명
    var busname: String         // 버스 이름
}


import ActivityKit
import Foundation

class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var currentActivity: Activity<HotchaLiveAttributes>?

    // 라이브 액티비티 시작
    func startLiveActivity(
        title: String,
        description: String,
        progress: Double,
        busname: String,
        currentStop: String,
        stopsRemaining: Int,
        alarmstop: String,
        destinationStation: String,
        Updatetime: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("라이브 액티비티 실행 불가: 권한이 비활성화되어 있습니다.")
            return
        }

        let activityAttributes = HotchaLiveAttributes(
            title: title,
            description: description,
            busname: busname
        )

        let initialState = HotchaLiveAttributes.ContentState(
            progress: progress,
            currentStop: currentStop,
            stopsRemaining: stopsRemaining,
            alarmstop: alarmstop,
            destinationStation: destinationStation,
            Updatetime: Updatetime
            
        )

        do {
            let activity = try Activity<HotchaLiveAttributes>.request(
                attributes: activityAttributes,
                content: .init(state: initialState, staleDate: Date().addingTimeInterval(3600)) // 1시간 만료
            )
            currentActivity = activity
            print("라이브 액티비티 시작됨: \(activity.id)")
        } catch {
            print("라이브 액티비티 시작 실패: \(error.localizedDescription)")
        }
    }

    // 라이브 액티비티 상태 업데이트
    func updateLiveActivity( progress: Double,
                             currentStop: String,
                             stopsRemaining: Int,
                             alarmstop: String,
                             destinationStation: String,
                             Updatetime: String) {
        guard let activity = currentActivity else {
            print("활동이 시작되지 않았습니다.")
            return
        }

        let newState = HotchaLiveAttributes.ContentState(
            progress: progress,
            currentStop: currentStop,
            stopsRemaining: stopsRemaining,
            alarmstop: alarmstop,
            destinationStation: destinationStation,
            Updatetime: Updatetime
        )

        Task {
            do {
                try await activity.update(using: newState)
                print("라이브 액티비티 업데이트 완료: \(progress)")
            } catch {
                print("라이브 액티비티 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }

    // 라이브 액티비티 종료
    func endLiveActivity() {
        guard let activity = currentActivity else {
            print("활동이 시작되지 않았습니다.")
            return
        }

        Task {
            do {
                await activity.end(dismissalPolicy: .immediate)
                print("라이브 액티비티 종료됨: \(activity.id)")
                currentActivity = nil
            } catch {
                print("라이브 액티비티 종료 실패: \(error.localizedDescription)")
            }
        }
    }
}
