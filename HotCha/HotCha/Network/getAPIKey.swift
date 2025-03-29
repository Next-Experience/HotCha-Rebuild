//
//  getAPIKey.swift
//  HotCha
//
//  Created by Yeji Seo on 3/29/25.
//

// api키 받아오는 함수입니다.

import Foundation

func getAPIKey() -> String? {
    return Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String
}
