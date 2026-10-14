//
//  HomeStatusBanner.swift
//  HotCha
//
//  홈 맨 위의 상태 배너. 지금 상황에 맞는 것 하나만 보여 준다.
//  모양은 Live Activity 와 같은 카드(HotChaBannerCard)를 쓴다.
//

import SwiftUI

struct HomeStatusBanner: View {
    enum Status: Equatable {
        /// 진행 중인 알람이 없다. 누르면 목적지 검색이 열린다.
        case idle
        /// 안내 중이다. detail 은 "152번 버스 · OO역까지 3정류장 남음" 같은 한 줄.
        /// image 는 노선 유형에 맞는 버스 그림이나 정류장 그림이다.
        case travelling(detail: String, image: String)
        /// 알람이 울렸고 아직 안내를 끝내지 않았다.
        case arriving(detail: String)
    }

    let status: Status
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Group {
                if isMoving {
                    TimelineView(.animation) { context in
                        card(phase: context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000))
                    }
                } else {
                    card(phase: nil)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(status == .idle ? "목적지 검색을 엽니다" : "안내 화면을 엽니다")
    }

    private func card(phase: Double?) -> some View {
        HotChaBannerCard(
            title: title, detail: detail, symbol: "bell.fill", image: image, motionPhase: phase,
            style: status == .idle ? .light : .accent)
            .animation(.default, value: detail)
    }

    /// 목적지로 가는 중일 때만 바탕이 움직인다. 움직임 줄이기나 저전력 모드에서는 멈춘다.
    private var isMoving: Bool {
        guard case .travelling = status else { return false }
        return !reduceMotion && !ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    private var title: String {
        switch status {
        case .idle: return "내릴 정류장을 적어주세요"
        case .travelling: return "지금 목적지를 향해 가는 중이에요"
        case .arriving: return "곧 내릴 정류장이에요"
        }
    }

    private var detail: String {
        switch status {
        case .idle: return "절대 놓치지 않게 해드려요!"
        case .travelling(let detail, _), .arriving(let detail): return detail
        }
    }

    private var image: String {
        switch status {
        case .idle, .arriving: return "HotChaStopBell"
        case .travelling(_, let image): return image
        }
    }
}
