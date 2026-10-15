//
//  OnBoardingView.swift
//  HotCha
//
//  첫 실행에 현재 앱의 핵심 흐름만 짧게 소개한다.
//

import AlarmKit
import CoreLocation
import SwiftUI

struct OnBoardingView: View {
    @AppStorage("OnBoarding_True") private var hasCompletedOnboarding = false
    @ObservedObject private var locationViewModel: LocationViewModel
    @ObservedObject private var alarmRinger: AlarmRinger
    @State private var step: Int

    @MainActor
    init(startsAtPermissions: Bool = false) {
        self.init(
            locationViewModel: LocationViewModel(),
            alarmRinger: AlarmRinger.shared,
            startsAtPermissions: startsAtPermissions
        )
    }

    @MainActor
    init(
        locationViewModel: LocationViewModel,
        alarmRinger: AlarmRinger,
        startsAtPermissions: Bool = false
    ) {
        self.locationViewModel = locationViewModel
        self.alarmRinger = alarmRinger
        _step = State(initialValue: startsAtPermissions ? 1 : 0)
    }

    var body: some View {
        ZStack {
            HotChaContentBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    stepIndicator

                    if step == 0 {
                        introduction
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    } else {
                        PermissionOnboardingView(
                            locationViewModel: locationViewModel,
                            alarmRinger: alarmRinger
                        )
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    if step == 0 {
                        withAnimation(.smooth) { step = 1 }
                    } else if permissionsAreReady {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text(primaryButtonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("mainpurple"))
                .disabled(step == 1 && !permissionsAreReady)
                .frame(maxWidth: 420)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var permissionsAreReady: Bool {
        locationViewModel.authorizationStatus == .authorizedAlways
            && alarmRinger.isAuthorized
    }

    private var primaryButtonTitle: String {
        if step == 0 { return "계속" }
        return permissionsAreReady ? "핫챠 시작하기" : "권한을 모두 허용해주세요"
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<2) { index in
                Circle()
                    .fill(index == step ? Color("mainpurple") : Color.secondary.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("온보딩 \(step + 1)단계, 전체 2단계")
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 28) {
            header
            JourneyPreview()
            featureCard
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
                detail: "버스 · 정류장 · 기차역 · 장소를 검색해요"
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

}

private struct PermissionOnboardingView: View {
    @ObservedObject var locationViewModel: LocationViewModel
    @ObservedObject var alarmRinger: AlarmRinger
    @Environment(\.openURL) private var openURL
    @State private var hasRequestedAlwaysPermission = false

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text("필요한 권한")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("mainpurple"))

                Text("두 가지만\n확인해주세요")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)

                Text("이동 중 위치를 확인하고, 내릴 때 확실하게 알려드리기 위해 필요해요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                OnboardingPermissionCard(
                    symbol: "location.fill",
                    title: "위치 권한",
                    detail: "화면이 꺼져도 안내를 이어가도록 항상 허용이 필요해요.",
                    isAuthorized: locationIsAuthorized,
                    actionTitle: locationActionTitle,
                    action: requestLocationPermission
                )
                OnboardingPermissionCard(
                    symbol: "alarm.fill",
                    title: "알람 권한",
                    detail: "무음 모드에서도 하차 알람을 울려요.",
                    isAuthorized: alarmRinger.isAuthorized,
                    actionTitle: alarmActionTitle,
                    action: requestAlarmPermission
                )
            }

            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("두 권한을 모두 허용해야 시작할 수 있어요")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("권한이 없으면 화면이 꺼졌을 때 위치를 확인하거나 시스템 알람을 울릴 수 없어 하차 안내를 보장할 수 없어요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(Color("mainpurple"))
            }
            .padding(16)
            .background(
                Color("mainpurple").opacity(0.10),
                in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous)
            )
        }
    }

    private var locationIsAuthorized: Bool {
        locationViewModel.authorizationStatus == .authorizedAlways
    }

    private var locationActionTitle: String? {
        if locationIsAuthorized { return nil }
        switch locationViewModel.authorizationStatus {
        case .notDetermined: return "사용 중 위치 허용"
        case .authorizedWhenInUse:
            return hasRequestedAlwaysPermission ? "설정에서 항상 허용" : "항상 허용하기"
        case .denied, .restricted: return "설정 열기"
        case .authorizedAlways: return nil
        @unknown default: return "설정 열기"
        }
    }

    private var alarmActionTitle: String? {
        switch alarmRinger.authorization {
        case .authorized: return nil
        case .notDetermined: return "허용하기"
        case .denied: return "설정 열기"
        @unknown default: return nil
        }
    }

    private func requestLocationPermission() {
        switch locationViewModel.authorizationStatus {
        case .notDetermined:
            locationViewModel.requestPermission()
        case .authorizedWhenInUse:
            if hasRequestedAlwaysPermission {
                openSettings()
            } else {
                hasRequestedAlwaysPermission = true
                locationViewModel.requestalwaysPermission()
            }
        case .denied, .restricted:
            openSettings()
        case .authorizedAlways:
            break
        @unknown default:
            openSettings()
        }
    }

    private func requestAlarmPermission() {
        if alarmRinger.authorization == .notDetermined {
            alarmRinger.requestAuthorizationIfNeeded()
        } else {
            openSettings()
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

private struct OnboardingPermissionCard: View {
    let symbol: String
    let title: String
    let detail: String
    let isAuthorized: Bool
    let actionTitle: String?
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color("mainpurple"))
                    .frame(width: 44, height: 44)
                    .background(
                        Color("mainpurple").opacity(0.10),
                        in: RoundedRectangle(cornerRadius: HotChaRadius.tile, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if isAuthorized {
                Label("허용됨", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("mainpurple"))
            } else if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .tint(Color("mainpurple"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous)
        )
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
