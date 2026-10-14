//
//  HotChaApp.swift
//  HotCha
//
//  Created by 문재윤 on 2/4/25.
//

import SwiftUI
import SwiftData

@main
struct HotChaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var HotchaContainer: ModelContainer = {
            // 스키마는 데이터 모델을 정의하는 역할
            let schema = Schema([Bookmarkmodel.self, Usage_history.self, Bus_info_seoul.self])
            // 데이터 저장 방식 설정 가능
            let config = ModelConfiguration(schema: schema)
            // 스키마와 컨피그를 바탕으로 데이터베이스 생성
            // 저장소를 못 열면 앱이 할 수 있는 일이 없다.
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: schema, configurations: [config])
        }()
    
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .modelContainer(HotchaContainer)
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 안내 중에 앱이 꺼졌으면 주인 없는 Live Activity 가 남아 있다. 새로 시작할 때 치운다.
        LiveActivityController.shared.endAll()
        return true
    }
}
