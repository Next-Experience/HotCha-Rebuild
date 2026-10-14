//
//  OnBoardingView.swift
//  HotCha
//
//  첫 실행에 현재 앱의 핵심 흐름만 짧게 소개한다.
//

import SwiftUI

struct OnBoardingView: View {
    @AppStorage("OnBoarding_True") private var hasCompletedOnboarding = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                header
                JourneyPreview()
                featureCard
                permissionNote
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 20)
            .padding(.top, 36)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .background(HotChaContentBackground())
        .safeAreaInset(edge: .bottom) {
            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("핫챠 시작하기")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("mainpurple"))
            .frame(maxWidth: 420)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("안전하게, 핫챠")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("mainpurple"))

            Text("내릴 곳만 정하면\n핫챠가 깨워드려요")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("버스나 정류장을 찾고 안내를 시작하세요.\n도착 전에 시스템 알람으로 알려드릴게요.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var featureCard: some View {
        VStack(spacing: 0) {
            OnboardingFeatureRow(
                symbol: "magnifyingglass",
                title: "한 번에 찾기",
                detail: "버스 · 정류장 · 장소를 검색해요"
            )
            Divider().padding(.leading, 56)
            OnboardingFeatureRow(
                symbol: "location.fill",
                title: "이동 중 확인",
                detail: "남은 정류장과 거리를 계속 보여줘요"
            )
            Divider().padding(.leading, 56)
            OnboardingFeatureRow(
                symbol: "alarm.fill",
                title: "놓치지 않는 알람",
                detail: "무음 모드에서도 시스템 알람이 울려요"
            )
        }
        .padding(.horizontal, 16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous)
        )
    }

    private var permissionNote: some View {
        Label {
            Text("위치와 알람 권한은 기능을 시작할 때 안내해요.")
                .font(.footnote)
        } icon: {
            Image(systemName: "hand.raised.fill")
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct JourneyPreview: View {
    var body: some View {
        HStack(spacing: 8) {
            step(clay: .magnifier, label: "찾고")
            arrow
            step(clay: .bus, label: "이동하고")
            arrow
            step(clay: .bell, label: "알림 받아요")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("목적지를 찾고 이동하면 내릴 때 알림을 받아요")
    }

    private func step(clay: Clay, label: String) -> some View {
        VStack(spacing: 8) {
            ClayIcon(clay: clay, size: 64)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var arrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption.bold())
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

private struct OnboardingFeatureRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("mainpurple"))
                .frame(width: 40, height: 40)
                .background(
                    Color("mainpurple").opacity(0.10),
                    in: RoundedRectangle(cornerRadius: HotChaRadius.tile, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    OnBoardingView()
}
