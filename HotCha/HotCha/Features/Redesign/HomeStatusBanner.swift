//
//  HomeStatusBanner.swift
//  HotCha
//
//  홈 맨 위의 상태 배너. 지금 상황에 맞는 것 하나만 보여 준다.
//  안내 중의 단계와 문구는 잠금 화면과 같은 HotChaGuidance 에서 오고, 모양은 여기서 따로 그린다.
//

import SwiftUI

struct HomeStatusBanner: View {
    enum Status: Equatable {
        /// 진행 중인 안내가 없다. 누르면 목적지 검색이 열린다.
        case idle
        /// 안내 중이다. image 는 노선 유형에 맞는 버스 그림이나 정류장 그림이다.
        case guiding(HotChaGuidance, image: String)
    }

    let status: Status
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                switch status {
                case .idle:
                    IdleBannerCard()
                case .guiding(let guidance, let image):
                    GuidingBannerCard(guidance: guidance, image: image)
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

/// 안내 중. 버스 번호 → 남은 정류장 수 → 내릴 정류장 순으로 읽힌다.
/// 움직임은 남은 수가 실제로 바뀔 때의 숫자 전환뿐이다.
private struct GuidingBannerCard: View {
    let guidance: HotChaGuidance
    let image: String

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(guidance.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    if let tag = guidance.phaseTag {
                        Text(tag)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("mainpurple"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.white, in: RoundedRectangle(cornerRadius: HotChaRadius.badge, style: .continuous))
                    }
                }
                Text(guidance.headline)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(guidance.detail)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            BannerArt(name: guidance.showsStopBell ? "HotChaStopBell" : image)
        }
        .padding(.leading, 20)
        .padding(.trailing, 12)
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
