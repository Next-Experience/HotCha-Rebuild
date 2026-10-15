//
//  version.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//
// 버전 정보 가져오는 전역 함수
import Foundation

func getAppVersion() -> String? {
    guard let dictionary = Bundle.main.infoDictionary,
          let version = dictionary["CFBundleShortVersionString"] as? String else {
        return nil
    }
    return version
}
