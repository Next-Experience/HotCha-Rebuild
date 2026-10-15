//
//  ClayIcon.swift
//  HotCha
//
//  에셋의 클레이 그림(Assets.xcassets/Clay)을 목록 줄의 아이콘 자리에 놓는다.
//

import SwiftUI

enum Clay: String {
    case bus = "HotChaClayBus"
    case busStop = "HotChaClayBusStop"
    case bell = "HotChaClayBell"
    case house = "HotChaClayHouse"
    case office = "HotChaClayOffice"
    case school = "HotChaClaySchool"
    case magnifier = "HotChaClayMagnifier"
    case star = "HotChaClayStar"

    /// 즐겨찾기 이름에 맞는 그림. "학교" 가 들어 있으면 학교를 쓴다.
    static func forBookmark(type: Int, label: String) -> Clay {
        switch type {
        case 1: return .house
        case 2: return .office
        default: return label.contains("학교") ? .school : .star
        }
    }
}

/// 연보라 바탕 위의 클레이 그림. 목록 줄 왼쪽에 쓴다.
struct ClayIcon: View {
    /// 에셋 그림 이름. 클레이 그림이나 버스 그림(KoreanBuses)
    let imageName: String
    var size: CGFloat = 48

    init(clay: Clay, size: CGFloat = 48) {
        self.imageName = clay.rawValue
        self.size = size
    }

    init(imageName: String, size: CGFloat = 48) {
        self.imageName = imageName
        self.size = size
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .padding(size * 0.1)
            .frame(width: size, height: size)
            .background(
                Color("mainpurple").opacity(0.10),
                in: RoundedRectangle(cornerRadius: HotChaRadius.tile, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}
