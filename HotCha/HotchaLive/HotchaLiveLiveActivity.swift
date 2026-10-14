//
//  HotchaLiveLiveActivity.swift
//  HotchaLive
//
//  안내 중에 잠금 화면과 다이내믹 아일랜드에 뜨는 화면.
//  데이터 모양은 LiveActivityShared/HotChaActivityAttributes.swift 에 있다.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct HotchaLiveLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HotChaActivityAttributes.self) { context in
            // 바탕을 칠하지 않는다. 잠금 화면 바탕은 시스템이 외관(라이트 · 다크)에 맞춰 정한다.
            LockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            let guidance = HotChaGuidance(attributes: context.attributes, state: context.state)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(guidance.label, systemImage: symbolName(guidance))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("mainpurple"))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(guidance.compact)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color("mainpurple"))
                        .contentTransition(.numericText())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        // 꼬리표를 오른쪽 끝에 두면 아일랜드의 둥근 모서리에 잘린다. 문장 앞에 붙인다.
                        Text(guidance.phaseTag.map { "\($0) · \(guidance.detail)" } ?? guidance.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        StopTrack(
                            guidance: guidance,
                            markerImage: context.attributes.kind == .route ? context.attributes.imageName : nil,
                            compact: true
                        )
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // 좁은 자리에는 버스 번호와 남은 양만 둔다.
                if context.attributes.kind == .route && !guidance.hasAlarmFired {
                    Text(context.attributes.busNumber)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("mainpurple"))
                } else {
                    Image(systemName: symbolName(guidance))
                        .foregroundStyle(Color("mainpurple"))
                }
            } compactTrailing: {
                Text(guidance.compact)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("mainpurple"))
                    .contentTransition(.numericText())
            } minimal: {
                Image(systemName: symbolName(guidance))
                    .foregroundStyle(Color("mainpurple"))
            }
            .keylineTint(Color("mainpurple"))
        }
    }
}

/// 알람이 울린 뒤에는 종, 아니면 버스(정류장 알림은 핀)
private func symbolName(_ guidance: HotChaGuidance) -> String {
    if guidance.hasAlarmFired { return "bell.fill" }
    return guidance.kind == .route ? "bus.fill" : "mappin.and.ellipse"
}

/// 잠금 화면과 알림 배너에 뜨는 모양. 홈 배너와 문구는 같고, 바탕은 시스템 것을 쓴다.
/// 위에서부터 버스 번호 → 남은 정류장 수(숫자만 크게) → 정류장 막대 → 지금 · 내릴 정류장.
/// mainpurple 은 버스 번호와 큰 수치, 앞으로 갈 길에만 쓴다.
private struct LockScreenView: View {
    let attributes: HotChaActivityAttributes
    let state: HotChaActivityAttributes.ContentState

    var body: some View {
        let guidance = HotChaGuidance(attributes: attributes, state: state)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Text(guidance.label)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(attributes.kind == .route ? Color.white : Color("mainpurple"))
                    .padding(.horizontal, attributes.kind == .route ? 7 : 0)
                    .padding(.vertical, attributes.kind == .route ? 2 : 0)
                    .background {
                        if attributes.kind == .route {
                            RoundedRectangle(cornerRadius: HotChaRadius.badge).fill(Color("mainpurple"))
                        }
                    }
                if let tag = guidance.phaseTag {
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
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
            Headline(guidance: guidance)
            StopTrack(guidance: guidance, markerImage: attributes.kind == .route ? attributes.imageName : nil)
            TrackLabels(guidance: guidance, currentStop: state.currentStop)
        }
        .padding(16)
    }
}

/// 큰 글자. 숫자가 있으면 숫자만 크게 그리고 나머지 말은 옆에 작게 붙인다.
private struct Headline: View {
    let guidance: HotChaGuidance

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if let number = guidance.headlineNumber {
                Text(number)
                    .font(.system(size: 40, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(guidance.phase == .passed ? Color.secondary : Color("mainpurple"))
                    .contentTransition(.numericText())
                Text(guidance.headlineRest)
                    .font(.title3.weight(.semibold))
            } else {
                Text(guidance.headlineRest)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(guidance.phase == .locating ? Color.secondary : Color("mainpurple"))
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

    var body: some View {
        // 내릴 정류장 이름이 먼저다. 지금 정류장 이름이 길면 그쪽이 줄어든다.
        let destination = Text(guidance.destination).fontWeight(.semibold).foregroundStyle(.primary)
            .layoutPriority(1)
        // 도착하면 지금 정류장이 곧 내릴 정류장이라 한 번만 적는다.
        let current = Text(guidance.phase == .arrived ? "" : currentStop).foregroundStyle(.secondary)
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
                            .foregroundStyle(Color("mainpurple"))
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
        if let markerImage {
            // 버스 그림은 옆으로 길다. 높이에 맞추고 너비를 넉넉히 준다.
            Image(markerImage)
                .resizable()
                .scaledToFit()
                .frame(width: markerSize * 1.6, height: markerSize)
        } else {
            Image(systemName: "location.circle.fill")
                .font(.system(size: markerSize * 0.8))
                .foregroundStyle(Color("mainpurple"))
                .frame(width: markerSize, height: markerSize)
        }
    }

    private var stopDot: some View { stopDot(passive: false) }

    private func stopDot(passive: Bool) -> some View {
        Circle()
            .strokeBorder(passive ? Color.secondary : Color("mainpurple"), lineWidth: 2)
            .background(Circle().fill(.background))
            .frame(width: compact ? 7 : 9, height: compact ? 7 : 9)
    }

    private func destinationMark(active: Bool) -> some View {
        Circle()
            .strokeBorder(active ? Color("mainpurple") : Color.secondary, lineWidth: compact ? 3 : 4)
            .frame(width: compact ? 12 : 16, height: compact ? 12 : 16)
    }

    private func line(dashed: Bool = false, passive: Bool = false) -> some View {
        TrackLine()
            .stroke(
                passive || dashed ? Color.secondary.opacity(0.5) : Color("mainpurple"),
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
