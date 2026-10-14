//
//  HotChaBannerCard.swift
//
//  홈의 상태 배너와 잠금 화면 Live Activity 가 함께 쓰는 카드.
//  두 곳이 같은 모양이어야 해서 앱과 위젯이 이 파일 하나를 함께 컴파일한다.
//

import SwiftUI

/// 모서리 반경. 앱과 위젯의 모든 둥근 모서리는 이 셋 중 하나다. 숫자를 직접 적지 않는다.
enum HotChaRadius {
    /// 카드 · 배너 · 큰 버튼
    static let card: CGFloat = 12
    /// 아이콘 타일 같은 작은 면
    static let tile: CGFloat = 8
    /// 버스 번호 배지
    static let badge: CGFloat = 4
}

struct HotChaBannerCard: View {
    enum Style {
        /// 강조색 바탕에 흰 글자. 안내 중 · 알람 뒤 · 잠금 화면
        case accent
        /// 흰 바탕에 기본 글자. 홈에서 아직 안내가 없을 때
        case light
    }

    let title: String
    let detail: String
    let symbol: String
    /// 에셋 카탈로그의 그림 이름. 주면 SF Symbol 대신 이 그림을 쓴다.
    var image: String?
    /// 안내 중일 때만 준다. 주면 바탕에 옅은 동그라미들이 그 시각만큼 흘러간 자리에 그려진다.
    var motionPhase: Double?
    var style: Style = .accent

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(style == .light ? Color.primary : Color.white)
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(style == .light ? Color("mainpurple") : Color.white.opacity(0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    // 남은 정류장·거리가 바뀌면 숫자만 부드럽게 넘어간다.
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
            if let image {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
            } else {
                Image(systemName: symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(style == .light ? Color("mainpurple") : Color.white)
                    .frame(width: 52, height: 52)
                    .background(
                        style == .light ? Color("mainpurple").opacity(0.12) : Color.white.opacity(0.2), in: Circle())
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, image == nil ? 20 : 12)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 바탕은 한 가지 색이다. 가는 중일 때만 그 위로 옅은 동그라미가 흐른다.
        .background {
            ZStack {
                if style == .light {
                    Color(uiColor: .secondarySystemGroupedBackground)
                } else {
                    Color("mainpurple")
                }
                if let motionPhase {
                    BubbleField(phase: motionPhase)
                }
            }
        }
    }
}

/// 가는 중이라는 느낌을 주는 옅은 동그라미들. 오른쪽에서 왼쪽으로 천천히 흐르며 살짝 오르내린다.
private struct BubbleField: View {
    let phase: Double

    private struct Bubble {
        /// 처음 자리 (가로·세로, 0...1)
        let x: Double
        let y: Double
        /// 지름 (카드 높이에 대한 비율)
        let size: Double
        /// 1초에 흐르는 거리 (카드 너비에 대한 비율)
        let speed: Double
        let opacity: Double
    }

    // 글자를 가리지 않게 아주 옅게 둔다.
    private static let bubbles = [
        Bubble(x: 0.10, y: 0.25, size: 0.90, speed: 0.020, opacity: 0.06),
        Bubble(x: 0.36, y: 0.80, size: 0.50, speed: 0.034, opacity: 0.08),
        Bubble(x: 0.58, y: 0.28, size: 0.30, speed: 0.050, opacity: 0.10),
        Bubble(x: 0.74, y: 0.72, size: 0.70, speed: 0.026, opacity: 0.06),
        Bubble(x: 0.92, y: 0.22, size: 0.22, speed: 0.062, opacity: 0.11),
    ]

    var body: some View {
        Canvas { context, size in
            for (index, bubble) in Self.bubbles.enumerated() {
                let diameter = size.height * bubble.size
                // 왼쪽 끝을 지나면 오른쪽 끝에서 다시 들어온다.
                let span = size.width + diameter
                let travelled = (bubble.x * span - phase * bubble.speed * size.width)
                    .truncatingRemainder(dividingBy: span)
                let x = (travelled < 0 ? travelled + span : travelled) - diameter / 2
                let bob = sin(phase * 0.6 + Double(index) * 1.7) * size.height * 0.05
                let y = size.height * bubble.y + bob
                let rect = CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(bubble.opacity)))
            }
        }
        .allowsHitTesting(false)
    }
}
