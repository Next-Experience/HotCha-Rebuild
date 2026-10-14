//
//  MyHotChaScreen.swift
//  HotCha
//
//  나의 핫챠. 닉네임, 핫챠와 함께 간 거리·시간, 그리고 설정이 한 화면에 있다.
//

import HotChaKit
import SwiftData
import SwiftUI

struct MyHotChaScreen: View {
    @AppStorage("nickname") private var nickname = ""
    @Query private var busHistories: [Usage_history]
    @State private var journeys = JourneyLog.load()
    @State private var stopHistories = StopAlarmHistory.load()
    @State private var isEditingNickname = false
    @State private var draftNickname = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    profileCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                        StatCard(image: Clay.busStop.rawValue, title: "편하게 간 거리", value: distanceText)
                        StatCard(image: Clay.bell.rawValue, title: "편하게 간 시간", value: durationText)
                        StatCard(image: Clay.star.rawValue, title: "함께한 횟수", value: "\(journeys.count)번")
                        StatCard(
                            image: mostRiddenBus.map { BusArt.imageName(routeType: $0.route_type, busNumber: $0.bus_no, cityCode: $0.city_code) }
                                ?? Clay.bus.rawValue,
                            title: "자주 탄 버스",
                            value: mostRiddenBus.map { "\($0.bus_no)번" } ?? "-"
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    if journeys.isEmpty {
                        Text("안내를 끝낼 때마다 거리와 시간이 쌓여요.")
                    }
                }

                if !favoritePlaces.isEmpty {
                    Section("자주 내린 곳") {
                        ForEach(favoritePlaces, id: \.name) { place in
                            LabeledContent(place.name, value: "\(place.count)번")
                        }
                    }
                }

                SettingsSections()
            }
            .scrollContentBackground(.hidden)
            .background(HotChaContentBackground())
            .navigationTitle("나의 핫챠")
            .alert("닉네임", isPresented: $isEditingNickname) {
                TextField("닉네임", text: $draftNickname)
                Button("저장") {
                    let trimmed = draftNickname.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { nickname = String(trimmed.prefix(20)) }
                }
                Button("랜덤으로 다시 뽑기") { nickname = NicknameGenerator.random() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("20자까지 쓸 수 있어요.")
            }
            .onAppear {
                // 처음 들어오면 색 · 음식 · 동물을 하나씩 뽑아 닉네임을 붙여 준다.
                if nickname.isEmpty { nickname = NicknameGenerator.random() }
                reload()
            }
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                reload()
            }
        }
    }

    // MARK: - 프로필

    private var profileCard: some View {
        Button {
            draftNickname = nickname
            isEditingNickname = true
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(nickname.isEmpty ? " " : nickname)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    Label("닉네임 바꾸기", systemImage: "pencil")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer(minLength: 0)
                Image(Clay.bus.rawValue)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
            }
            .padding(.leading, 20)
            .padding(.trailing, 12)
            .padding(.vertical, 18)
            .background(Color("mainpurple"))
            .clipShape(RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("닉네임을 바꿉니다")
    }

    // MARK: - 숫자

    private func reload() {
        journeys = JourneyLog.load()
        stopHistories = StopAlarmHistory.load()
    }

    private var distanceText: String {
        let meters = journeys.reduce(0) { $0 + $1.meters }
        guard meters >= 1000 else { return "\(Int(meters))m" }
        return String(format: "%.1fkm", meters / 1000)
    }

    private var durationText: String {
        let minutes = Int(journeys.reduce(0) { $0 + $1.seconds } / 60)
        guard minutes >= 60 else { return "\(minutes)분" }
        return "\(minutes / 60)시간 \(minutes % 60)분"
    }

    /// 가장 많이 탄 버스. 같은 횟수면 최근에 탄 것이다.
    private var mostRiddenBus: Usage_history? {
        var counts: [String: Int] = [:]
        for history in busHistories {
            counts["\(history.city_code)|\(history.bus_no)", default: 0] += 1
        }
        guard let top = counts.max(by: { $0.value < $1.value })?.key else { return nil }
        return busHistories
            .filter { "\($0.city_code)|\($0.bus_no)" == top }
            .max { $0.get_off_timestamp < $1.get_off_timestamp }
    }

    private struct PlaceCount {
        let name: String
        let count: Int
    }

    /// 버스와 정류장 기록을 합쳐 가장 자주 내린 정류장 셋
    private var favoritePlaces: [PlaceCount] {
        let names: [String] = busHistories.map(\.destination_stop_name) + stopHistories.map(\.stop.name)
        var counts: [String: Int] = [:]
        for name in names {
            counts[name, default: 0] += 1
        }
        let ranked: [PlaceCount] = counts
            .map { PlaceCount(name: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                lhs.count == rhs.count ? lhs.name < rhs.name : lhs.count > rhs.count
            }
        return Array(ranked.prefix(3))
    }
}

private struct StatCard: View {
    let image: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: HotChaRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
