//
//  HomeStatusBanner.swift
//  HotCha
//
//  홈 맨 위의 상태 배너. 지금 상황에 맞는 것 하나만 보여 준다.
//  안내 중의 단계와 문구는 HotChaGuidance, 모양은 잠금 화면과 같은 HotChaGuidanceCard 다. 바탕색만 다르다.
//

import SwiftUI

struct HomeStatusBanner: View {
    enum Status: Equatable {
        /// 진행 중인 안내가 없다. 누르면 목적지 검색이 열린다.
        case idle
        /// 안내 중이다. currentStop 은 지금 정류장 이름(정류장 알림은 빈 값),
        /// marker 는 막대의 버스 자리에 둘 노선 유형 버스 그림(정류장 알림은 nil)이다.
        case guiding(HotChaGuidance, currentStop: String, marker: String?)
    }

    let status: Status
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                switch status {
                case .idle:
                    IdleBannerCard()
                case .guiding(let guidance, let currentStop, let marker):
                    GuidingBannerCard(guidance: guidance, currentStop: currentStop, marker: marker)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(status == .idle ? "목적지 검색을 엽니다" : "안내 화면을 엽니다")
    }
}

/// 안내가 없을 때. 흰 카드에 하차벨.
private struct IdleBannerCard: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("내릴 정류장을 적어주세요")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Text("절대 놓치지 않게 해드려요!")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("mainpurple"))
            }
            Spacer(minLength: 0)
            BannerArt(name: "HotChaStopBell")
        }
        .padding(.leading, 20)
        .padding(.trailing, 12)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

/// 안내 중. 잠금 화면 Live Activity 와 같은 HotChaGuidanceCard 를 mainpurple 바탕 위에 흰색으로 그린다 —
/// 버스 번호 → 남은 정류장 수(숫자만 크게) → 정류장 막대 → 지금 · 내릴 정류장.
/// 움직임은 남은 수가 실제로 바뀔 때의 숫자 전환과 막대의 점이 하나 줄어드는 것뿐이다.
private struct GuidingBannerCard: View {
    let guidance: HotChaGuidance
    let currentStop: String
    let marker: String?

    var body: some View {
        HotChaGuidanceCard(guidance: guidance, currentStop: currentStop, markerImage: marker, style: .onPurple)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("mainpurple"))
            .animation(.smooth, value: guidance)
    }
}

private struct BannerArt: View {
    let name: String

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 76, height: 76)
            .accessibilityHidden(true)
    }
}
