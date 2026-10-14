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
            LockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color("mainpurple"))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let tint = context.state.hasAlarmFired ? Color.orange : Color("mainpurple")
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(badgeText(context.attributes), systemImage: symbolName(context.attributes))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.shortRemaining)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(tint)
                        .contentTransition(.numericText())
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.destination)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    JourneyLine(attributes: context.attributes, state: context.state)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.hasAlarmFired ? "bell.fill" : symbolName(context.attributes))
                    .foregroundStyle(tint)
            } compactTrailing: {
                Text(context.state.shortRemaining)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
            } minimal: {
                Image(systemName: context.state.hasAlarmFired ? "bell.fill" : symbolName(context.attributes))
                    .foregroundStyle(tint)
            }
            .keylineTint(tint)
        }
    }
}

private func badgeText(_ attributes: HotChaActivityAttributes) -> String {
    attributes.kind == .route ? "\(attributes.busNumber)번" : "정류장"
}

private func symbolName(_ attributes: HotChaActivityAttributes) -> String {
    attributes.kind == .route ? "bus.fill" : "mappin.and.ellipse"
}

/// 잠금 화면과 알림 배너에 뜨는 모양. 홈의 상태 배너와 같은 카드를 쓴다.
private struct LockScreenView: View {
    let attributes: HotChaActivityAttributes
    let state: HotChaActivityAttributes.ContentState

    var body: some View {
        HotChaBannerCard(
            title: state.hasAlarmFired ? "곧 내릴 정류장이에요" : "지금 목적지를 향해 가는 중이에요",
            detail: detail,
            symbol: state.hasAlarmFired ? "figure.walk.departure" : symbolName(attributes),
            image: state.hasAlarmFired ? "HotChaStopBell" : attributes.imageName
        )
    }

    /// 홈 배너와 같은 문장. "152번 버스 · OO역까지 3정류장 남음" / "OO역까지 540m 남음"
    private var detail: String {
        let name = attributes.destination
        if let stops = state.remainingStops {
            let prefix = "\(attributes.busNumber)번 버스 · "
            if stops > 0 { return "\(prefix)\(name)까지 \(stops)정류장 남음" }
            return stops == 0 ? "\(prefix)\(name)에 도착했어요" : "\(prefix)\(name)을 \(-stops)정류장 지났어요"
        }
        if let meters = state.remainingMeters {
            return "\(name)까지 \(HotChaActivityAttributes.ContentState.format(meters: meters)) 남음"
        }
        return name
    }
}

/// "지금 있는 곳 → 알람이 울리는 곳" 한 줄
private struct JourneyLine: View {
    let attributes: HotChaActivityAttributes
    let state: HotChaActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 6) {
            Text(state.currentStop.isEmpty ? "이동 중" : state.currentStop)
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
            Image(systemName: state.hasAlarmFired ? "bell.fill" : "bell")
            Text(attributes.alarmPoint)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}
