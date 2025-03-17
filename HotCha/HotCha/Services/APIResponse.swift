//
//  APIResponse.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

import Foundation

// API 응답 구조 정의
struct APIResponse<T: Codable>: Codable {
    let response: ResponseBody
    
    struct ResponseBody: Codable {
        let header: Header
        let body: Body?
        
        struct Header: Codable {
            let resultCode: String
            let resultMsg: String
        }
        
        struct Body: Codable {
            let items: Items?
            let numOfRows: Int?
            let pageNo: Int?
            let totalCount: Int?
            
            struct Items: Codable {
                let item: [T]?
            }
        }
    }
}

