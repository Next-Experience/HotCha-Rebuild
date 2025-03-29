//
//  NetworkError.swift
//  HotCha
//
//  Created by 문호 on 3/14/25.
//

import Foundation

// NetworkError.swift - 네트워크 에러 정의
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case networkFailure(Error)
    case apiError(String, String)   // (resultCode, resultMsg)
    case decodingError(Error)
    case emptyResponse
    case unknownError
    
    var description: String {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .invalidResponse:
            return "유효하지 않은 응답입니다."
        case .invalidData:
            return "유효하지 않은 데이터입니다."
        case .networkFailure(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API 오류[\(code)]: \(message)"
        case .decodingError(let error):
            return "데이터 디코딩 오류: \(error.localizedDescription)"
        case .emptyResponse:
            return "데이터가 비어있습니다."
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
