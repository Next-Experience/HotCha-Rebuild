//
//  HotChaGuidanceCard.swift
//
//  안내 중 카드의 모양. 잠금 화면 Live Activity(위젯)와 홈 배너(앱)가 이 파일 하나를 함께 컴파일해
//  같은 순서로 그린다 — 버스 번호 → 남은 정류장 수(숫자만 크게) → 정류장 막대 → 지금 · 내릴 정류장.
//  다른 것은 색뿐이다. 잠금 화면은 시스템 바탕 위 mainpurple 포인트, 홈 배너는 mainpurple 바탕 위 흰 글자.
//

import SwiftUI

/// 카드를 어느 바탕 위에 그리는가에 따라 바뀌는 색
struct HotChaGuidanceStyle {
    /// 버스 번호 배지 · 큰 숫자 · 앞으로 갈 길
    var accent: AnyShapeStyle
    /// 배지 안 글자
    var onAccent: AnyShapeStyle
    var primary: AnyShapeStyle
    var secondary: AnyShapeStyle
    /// 지나온 쪽 · 아직 모르는 길
    var muted: AnyShapeStyle
    /// 막대 점의 속. 바탕과 같은 색이어야 선이 점 안으로 비치지 않는다.
    var hole: AnyShapeStyle
    /// 버스 그림 뒤에 깔 판. 버스 그림 색이 바탕에 묻힐 때만 둔다.
    var markerPlate: AnyShapeStyle?

    /// 잠금 화면 · 아일랜드. 바탕을 칠하지 않고 시스템 것을 쓴다.
    static let system = HotChaGuidanceStyle(
        accent: AnyShapeStyle(Color("mainpurple")),
        onAccent: AnyShapeStyle(Color.white),
        primary: AnyShapeStyle(.primary),
        secondary: AnyShapeStyle(.secondary),
        muted: AnyShapeStyle(Color.secondary),
        hole: AnyShapeStyle(.background),
        markerPlate: nil
    )

    /// 홈 배너. mainpurple 단색 바탕 위에 흰색으로 그린다. 파란 · 보라 버스가 바탕에 묻혀 흰 판에 올린다.
    static let onPurple = HotChaGuidanceStyle(
        accent: AnyShapeStyle(Color.white),
        onAccent: AnyShapeStyle(Color("mainpurple")),
        primary: AnyShapeStyle(Color.white),
        secondary: AnyShapeStyle(Color.white.opacity(0.75)),
        muted: AnyShapeStyle(Color.white.opacity(0.55)),
        hole: AnyShapeStyle(Color("mainpurple")),
        markerPlate: AnyShapeStyle(Color.white)
    )
}

/// 안내 중 카드의 내용. 바탕과 안쪽 여백은 쓰는 쪽이 정한다.
struct HotChaGuidanceCard: View {
    let guidance: HotChaGuidance
    /// 지금 있는 정류장 이름. 정류장 알림이나 아직 모를 때는 비어 있다.
    let currentStop: String
    /// 막대에서 버스 자리에 둘 그림. 정류장 알림은 nil 이라 위치 표시를 쓴다.
    let markerImage: String?
    var style: HotChaGuidanceStyle = .system

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                LabelBadge(guidance: guidance, style: style)
                if let tag = guidance.phaseTag {
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(style.secondary)
                }
                Spacer(minLength: 0)
                if guidance.showsStopBell {
                    Image("HotChaStopBell")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .padding(.vertical, -8)
                        .accessibilityHidden(true)
                }
            }
            Headline(guidance: guidance, style: style)
            StopTrack(guidance: guidance, markerImage: markerImage, style: style)
            TrackLabels(guidance: guidance, currentStop: currentStop, style: style)
        }
        .foregroundStyle(style.primary)
    }
}

/// 노선 안내는 버스 번호 배지, 정류장 알림은 배지 없는 글자
private struct LabelBadge: View {
    let guidance: HotChaGuidance
    let style: HotChaGuidanceStyle

    var body: some View {
        let isRoute = guidance.kind == .route
        Text(guidance.label)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(isRoute ? style.onAccent : style.accent)
            .padding(.horizontal, isRoute ? 7 : 0)
            .padding(.vertical, isRoute ? 2 : 0)
            .background {
                if isRoute {
                    RoundedRectangle(cornerRadius: HotChaRadius.badge).fill(style.accent)
                }
            }
    }
}

/// 큰 글자. 숫자가 있으면 숫자만 크게 그리고 나머지 말은 옆에 작게 붙인다.
private struct Headline: View {
    let guidance: HotChaGuidance
    let style: HotChaGuidanceStyle

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if let number = guidance.headlineNumber {
                Text(number)
                    .font(.system(size: 40, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(guidance.phase == .passed ? style.secondary : style.accent)
                    .contentTransition(.numericText())
                Text(guidance.headlineRest)
                    .font(.title3.weight(.semibold))
            } else {
                Text(guidance.headlineRest)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(guidance.phase == .locating ? style.secondary : style.accent)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

/// 막대 양 끝의 이름. 막대와 같은 순서로 놓는다 — 지나쳤으면 내릴 정류장이 왼쪽이다.
private struct TrackLabels: View {
    let guidance: HotChaGuidance
    let currentStop: String
    let style: HotChaGuidanceStyle

    var body: some View {
        // 내릴 정류장 이름이 먼저다. 지금 정류장 이름이 길면 그쪽이 줄어든다.
        let destination = Text(guidance.destination).fontWeight(.semibold).foregroundStyle(style.primary)
            .layoutPriority(1)
        // 도착하면 지금 정류장이 곧 내릴 정류장이라 한 번만 적는다.
        let current = Text(guidance.phase == .arrived ? "" : currentStop).foregroundStyle(style.secondary)
        HStack(spacing: 8) {
            if guidance.phase == .passed {
                destination
                Spacer(minLength: 0)
                current
            } else {
                current
                Spacer(minLength: 0)
                destination
            }
        }
        .font(.caption)
        .lineLimit(1)
    }
}

/// 남은 정류장을 점으로 늘어놓은 막대. 전체 정류장 수는 모르므로 지나온 길은 그리지 않고
/// **앞으로 남은 정류장만** 그린다. 정류장을 하나 지날 때마다 점이 하나 줄어 버스가 내릴 곳에 다가간다.
/// 정류장 알림은 정류장 수가 없어서 점 없이 한 줄로만 잇는다.
struct StopTrack: View {
    let guidance: HotChaGuidance
    /// 버스 자리에 둘 그림. 없으면 위치 표시를 쓴다.
    let markerImage: String?
    var style: HotChaGuidanceStyle = .system
    /// 점을 이만큼까지만 그린다. 더 남았으면 앞쪽을 「⋯」로 줄인다.
    var maxDots = 6
    var compact = false

    private var markerSize: CGFloat { compact ? 20 : 28 }

    var body: some View {
        HStack(spacing: 0) {
            switch guidance.phase {
            case .locating:
                line(dashed: true)
                destinationMark(active: false)
            case .travelling, .preparing:
                marker
                if let stops = guidance.remainingStops {
                    let shown = min(stops, maxDots)
                    if stops > shown {
                        line()
                        Text("⋯")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(style.accent)
                            .padding(.horizontal, 2)
                    }
                    ForEach(0..<shown, id: \.self) { index in
                        line()
                        if index == shown - 1 { destinationMark(active: true) } else { stopDot }
                    }
                } else {
                    line()
                    destinationMark(active: true)
                }
            case .arrived:
                line()
                ZStack {
                    destinationMark(active: true)
                    marker
                }
            case .passed:
                destinationMark(active: false)
                let passed = min(-(guidance.remainingStops ?? 0), maxDots)
                ForEach(0..<passed, id: \.self) { index in
                    line(passive: true)
                    if index == passed - 1 { marker } else { stopDot(passive: true) }
                }
            }
        }
        .frame(height: markerSize)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var marker: some View {
        if let markerImage, let plate = style.markerPlate {
            // 판까지 합쳐 막대 높이 안에 들어가게 그림을 조금 줄인다.
            Image(markerImage)
                .resizable()
                .scaledToFit()
                .frame(width: (markerSize - 6) * 1.6, height: markerSize - 6)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(plate))
        } else if let markerImage {
            // 버스 그림은 옆으로 길다. 높이에 맞추고 너비를 넉넉히 준다.
            Image(markerImage)
                .resizable()
                .scaledToFit()
                .frame(width: markerSize * 1.6, height: markerSize)
        } else {
            Image(systemName: "location.circle.fill")
                .font(.system(size: markerSize * 0.8))
                .foregroundStyle(style.accent)
                .frame(width: markerSize, height: markerSize)
        }
    }

    private var stopDot: some View { stopDot(passive: false) }

    private func stopDot(passive: Bool) -> some View {
        Circle()
            .strokeBorder(passive ? style.muted : style.accent, lineWidth: 2)
            .background(Circle().fill(style.hole))
            .frame(width: compact ? 7 : 9, height: compact ? 7 : 9)
    }

    private func destinationMark(active: Bool) -> some View {
        Circle()
            .strokeBorder(active ? style.accent : style.muted, lineWidth: compact ? 3 : 4)
            .frame(width: compact ? 12 : 16, height: compact ? 12 : 16)
    }

    private func line(dashed: Bool = false, passive: Bool = false) -> some View {
        TrackLine()
            .stroke(
                passive || dashed ? AnyShapeStyle(style.muted.opacity(0.5)) : style.accent,
                style: StrokeStyle(lineWidth: compact ? 2 : 3, dash: dashed ? [4, 3] : [])
            )
            .frame(maxWidth: .infinity)
    }
}

/// 가운데를 가로지르는 한 줄
private struct TrackLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
