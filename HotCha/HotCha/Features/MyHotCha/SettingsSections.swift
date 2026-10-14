import SwiftUI

/// 설정 항목들. 「나의 핫챠」 목록 안에 섹션으로 들어간다.
struct SettingsSections: View {
    @AppStorage(AlarmSound.storageKey) private var soundName = AlarmSound.classic.rawValue
    @AppStorage("soundToggle") private var soundOn = true
    @AppStorage("vibrationToggle") private var vibrationOn = true
    @AppStorage("alarmStopDistanceFromDestination") private var stopsBefore = 2
    @AppStorage("stopAlarmRadius") private var stopAlarmRadius: Double = 500

    @AppStorage("developerMode") private var developerMode = false

    private static let supportEmail = "tenedict@gmail.com"

    var body: some View {
        Section {
            NavigationLink {
                AlarmSoundPicker(selection: $soundName)
            } label: {
                LabeledContent("알림음", value: (AlarmSound(rawValue: soundName) ?? .classic).title)
            }
            Toggle("소리", isOn: $soundOn)
            Toggle("진동", isOn: $vibrationOn)
        } header: {
            Text("알림 소리")
        } footer: {
            Text("소리를 켜면 무음 모드에서도 알림음이 울려요.")
        }

        Section {
            Stepper(value: $stopsBefore, in: 1...5) {
                LabeledContent("버스 알림", value: "\(stopsBefore)정류장 전")
            }
            Picker("정류장 알림", selection: $stopAlarmRadius) {
                Text("300m 전").tag(300.0)
                Text("500m 전").tag(500.0)
                Text("1km 전").tag(1000.0)
            }
        } header: {
            Text("알림 시점")
        } footer: {
            Text("알림을 맞출 때마다 바꿀 수도 있어요.")
        }

        Section("고객지원") {
            if let url = URL(string: "mailto:\(Self.supportEmail)?subject=%ED%95%AB%EC%B1%A0%20%EB%AC%B8%EC%9D%98") {
                Link(destination: url) {
                    LabeledContent {
                        Text(Self.supportEmail).foregroundStyle(Color.secondary)
                    } label: {
                        Label {
                            Text("핫챠 문의하기").foregroundStyle(Color.primary)
                        } icon: {
                            Image(systemName: "envelope")
                        }
                    }
                }
            }
            NavigationLink {
                FAQScreen()
            } label: {
                Label("자주 묻는 질문", systemImage: "questionmark.circle")
            }
            NavigationLink {
                PrivacyScreen()
            } label: {
                Label("개인정보 처리 안내", systemImage: "hand.raised")
            }
        }

        Section("앱 정보") {
            LabeledContent("버전", value: getAppVersion() ?? "1.0.0")
                .contentShape(Rectangle())
                // 버전을 다섯 번 누르면 개발자 메뉴가 열리고 닫힌다.
                .onTapGesture(count: 5) { developerMode.toggle() }
        }

        if developerMode {
            Section {
                Button {
                    NotificationCenter.default.post(name: .previewAlarmRinging, object: nil)
                } label: {
                    Label("알람 울려 보기", systemImage: "bell.and.waves.left.and.right")
                }
                Button("개발자 메뉴 닫기", role: .destructive) { developerMode = false }
            } header: {
                Text("개발자")
            } footer: {
                Text("실제 알람처럼 소리·진동과 함께 알람 화면이 떠요. 버전을 다섯 번 누르면 이 메뉴가 열리고 닫혀요.")
            }
        }
    }
}

/// 이 앱이 실제로 다루는 정보를 적은 안내. 코드가 하는 일만 적는다.
private struct PrivacyScreen: View {
    private struct Item: Identifiable {
        let title: String
        let body: String
        var id: String { title }
    }

    private let items = [
        Item(
            title: "회원가입이 없어요",
            body: "핫챠는 계정을 만들지 않아요. 이름, 전화번호, 이메일을 받지 않아요."
        ),
        Item(
            title: "위치는 내 휴대폰 안에서만 써요",
            body: "안내 중에 지금 어느 정류장인지 알아내려고 위치를 써요. 위치는 핫챠 서버로 보내지 않아요. 핫챠에는 서버가 없어요."
        ),
        Item(
            title: "기록은 내 휴대폰에만 남아요",
            body: "즐겨찾기, 이용 기록, 닉네임, 이동 거리와 시간은 이 휴대폰에만 저장돼요. 앱을 지우면 함께 지워져요."
        ),
        Item(
            title: "밖으로 나가는 정보",
            body: "버스 안내를 시작하면 그 노선의 정류장 목록을 받으려고 공공데이터포털에 노선 번호를 보내요. 장소를 검색하면 검색어가 애플 지도로 가요. 두 경우 모두 내가 누구인지는 보내지 않아요."
        ),
    ]

    var body: some View {
        List {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.body.weight(.semibold))
                    Text(item.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HotChaContentBackground())
        .navigationTitle("개인정보 처리 안내")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 알림음 고르기. 누르면 잠깐 들려준다.
private struct AlarmSoundPicker: View {
    @Binding var selection: String

    var body: some View {
        List {
            Section {
                ForEach(AlarmSound.allCases) { sound in
                    Button {
                        selection = sound.rawValue
                        preview(sound)
                    } label: {
                        HStack {
                            Text(sound.title)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selection == sound.rawValue {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("누르면 미리 들을 수 있어요. 알림음은 앞으로 더 추가될 예정이에요.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(HotChaContentBackground())
        .navigationTitle("알림음")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { SoundManager.shared.stopSound() }
    }

    private func preview(_ sound: AlarmSound) {
        SoundManager.shared.playSound(fileName: sound.fileName)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            SoundManager.shared.stopSound()
        }
    }
}

private struct FAQScreen: View {
    private struct Item: Identifiable {
        let question: String
        let answer: String
        var id: String { question }
    }

    private let items = [
        Item(
            question: "알림이 안 울려요",
            answer: "아이폰 설정 > 핫챠에서 위치를 ‘항상’으로, 알림을 ‘허용’으로 바꿔 주세요. 위치가 ‘앱을 사용하는 동안’이면 화면을 껐을 때 버스를 따라가지 못해요. 안내 중에는 앱을 완전히 종료하지 마세요."
        ),
        Item(
            question: "버스 알림과 정류장 알림은 뭐가 달라요?",
            answer: "버스 알림은 탄 버스와 내릴 정류장을 고르면 몇 정류장 전에 알려 줘요. 정류장 알림은 버스를 고르지 않고 내릴 정류장만 고르면, 그 정류장에 가까워졌을 때 거리로 알려 줘요."
        ),
        Item(
            question: "남은 정류장 수가 실제와 달라요",
            answer: "핫챠는 버스가 아니라 내 휴대폰의 위치로 정류장을 세요. 터널이나 고층 건물 사이에서는 위치가 늦게 잡혀 한두 정류장 차이가 날 수 있어요. 정류장을 놓쳐도 다음 위치에서 따라잡고, 알림은 지나치지 않고 울려요."
        ),
        Item(
            question: "무음 모드에서도 울리나요?",
            answer: "설정에서 ‘소리’를 켜 두면 무음 모드에서도 알림음이 스피커로 울려요. 조용히 받고 싶다면 소리를 끄고 진동만 켜 주세요."
        ),
        Item(
            question: "찾는 버스나 정류장이 안 나와요",
            answer: "버스와 정류장 목록은 앱에 들어 있는 자료라, 최근에 생기거나 바뀐 노선은 앱을 업데이트해야 나와요. 정류장 이름이 기억나지 않으면 근처 장소 이름으로 검색해 지도에서 골라 보세요."
        ),
        Item(
            question: "배터리를 많이 쓰나요?",
            answer: "안내 중에만 위치를 계속 확인해요. 안내를 끝내면 위치 확인도 멈춰요. 내린 뒤에는 ‘안내 종료’를 눌러 주세요."
        ),
        Item(
            question: "버스에 물건을 두고 내렸어요",
            answer: "이용 기록에서 탔던 버스 번호와 내린 시각, 운수사 이름을 확인할 수 있어요. 운수사나 해당 지역 버스 분실물 센터에 이 정보를 알려 주세요."
        ),
        Item(
            question: "즐겨찾기는 몇 개까지 되나요?",
            answer: "집과 회사를 포함해 6개까지 저장할 수 있어요. 즐겨찾기를 누르면 도착 정류장을 다시 고르지 않고 바로 안내가 시작돼요."
        ),
    ]

    var body: some View {
        List(items) { item in
            DisclosureGroup {
                Text(item.answer)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } label: {
                Text(item.question)
                    .font(.body.weight(.semibold))
            }
        }
        .scrollContentBackground(.hidden)
        .background(HotChaContentBackground())
        .navigationTitle("자주 묻는 질문")
        .navigationBarTitleDisplayMode(.inline)
    }
}
