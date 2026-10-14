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
                    // 꼬리표를 오른쪽 끝에 두면 아일랜드의 둥근 모서리에 잘린다. 문장 앞에 붙인다.
                    Text(guidance.phaseTag.map { "\($0) · \(guidance.detail)" } ?? guidance.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
/// mainpurple 은 버스 번호와 큰 수치에만 쓴다.
private struct LockScreenView: View {
    let attributes: HotChaActivityAttributes
    let state: HotChaActivityAttributes.ContentState

    var body: some View {
        let guidance = HotChaGuidance(attributes: attributes, state: state)
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(guidance.label)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("mainpurple"))
                    if let tag = guidance.phaseTag {
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(guidance.headline)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(guidance.phase == .locating ? Color.secondary : Color("mainpurple"))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(guidance.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(guidance.showsStopBell ? "HotChaStopBell" : attributes.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
        }
        .padding(16)
    }
}
