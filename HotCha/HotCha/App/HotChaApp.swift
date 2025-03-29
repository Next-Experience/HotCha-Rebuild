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
    var HotchaContainer: ModelContainer = {
            // 스키마는 데이터 모델을 정의하는 역할
            let schema = Schema([Bookmarkmodel.self, Usage_history.self])
            // 데이터 저장 방식 설정 가능
            let config = ModelConfiguration(schema: schema)
            // 스키마와 컨피그를 바탕으로 데이터베이스 생성
            return try! ModelContainer(for: schema, configurations: [config])
        }()
    
    
    var body: some Scene {
        WindowGroup {
//            SplashView()
            SoundTestView()
                .modelContainer(HotchaContainer)
        }
    }
}
