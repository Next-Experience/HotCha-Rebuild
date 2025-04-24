//
//  Untitled.swift
//  HotCha
//
//  Created by 문재윤 on 2/4/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @State var isEditMode: Bool = false
    @State var searchActivate: Bool = false
    @State var textfiledValue: String = ""
    @Binding var isSwipeDisabled : Bool
    
    // 알람 활성화 상태
    @State private var alarmActive: Bool = false
    
    // 알람 정보 저장
    @State private var alarmBusNo: String = ""
    @State private var alarmBusType: String = ""
    @State private var alarmDestination: String = ""
    @State private var alarmRemainingStops: Int = 0
    
    // 알람 설정 화면 복원을 위한 정보
    @State private var savedBus: Bus_info_seoul? = nil
    @State private var savedCityCode: Int = 1
    @State private var shouldNavigateToAlarmView: Bool = false
    
    //swift data에 저장유무
    @AppStorage("Bus_info_seoul_True") var Bus_info_seoul_True: Bool = false
    
    // 앱 시작 여부 플래그
    @State private var isAppStart = true
    
    @StateObject private var viewModel = BusRouteViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        // 메인뷰 전체
        VStack(spacing: 12) {
            // 알람이 활성화되었을 때는 DoAlarmView를 표시, 그렇지 않거나 앱이 시작될 때는 MainTextfiled 표시
            if alarmActive && !searchActivate {
                NavigationLink(
                    destination: AlarmSettingView(bus: savedBus!, cityCode: savedCityCode)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                forceCheckAlarmStatus()
                                // searchActivate 플래그를 명시적으로 false로 설정
                                searchActivate = false
                            }
                        },
                    isActive: $shouldNavigateToAlarmView
                ) {
                    EmptyView()
                }
                
                DoAlarmView()
                    .padding(.bottom, 12)
                    .onTapGesture {
                        // DoAlarmView를 탭하면 이전 알람 설정 화면으로 이동
                        if let bus = savedBus {
                            print("DoAlarmView 탭됨, 알람 설정 화면으로 이동")
                            shouldNavigateToAlarmView = true
                        }
                    }
            } else {
                // '버스번호를 알려주세요' 텍스트 필드
                MainTextfiled(isEditMode: $isEditMode, textfiledValue: $textfiledValue, searchActivate: $searchActivate)
            }
            
            if searchActivate {
                // 서치뷰 전환
                SearchView(textfiledValue: $textfiledValue, searchActivate: $searchActivate)
            } else {
                // 즐겨찾기 항목들
                BookmarkView(isEditMode: $isEditMode)
                    .padding(.top,12)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("gray50"))
        .onAppear{
            if !Bus_info_seoul_True {
                viewModel.fetchBusRoutes(searchStr: "")
                saveBusRoutesToDatabase(routes: viewModel.busRoutes, context: modelContext)
                Bus_info_seoul_True = true
            }
            
            // 앱 시작 시에는 항상 알람 상태를 초기화하고 MainTextfield 표시
            if isAppStart {
                // 알람 상태 초기화
                resetAlarmState()
                textfiledValue = ""
                searchActivate = false
                isEditMode = false
                isAppStart = false
            } else {
                // 앱이 시작된 후에는 알람 상태에 따라 뷰 결정
                print("MainView onAppear: 앱 시작 아님, 알람 상태 확인")
                forceCheckAlarmStatus()
                
                if !alarmActive {
                    searchActivate = false
                    textfiledValue = ""
                }
            }
        }
        .onChange(of: shouldNavigateToAlarmView) { newValue in
            print("shouldNavigateToAlarmView 변경됨: \(newValue)")
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AlarmStatusChanged"))) { notification in
            // 알람 상태가 변경되었을 때
            print("AlarmStatusChanged 알림 수신됨")
            
            if let userInfo = notification.userInfo,
               let alarmState = userInfo["alarmActive"] as? Bool {
                // 명시적으로 전달된 알람 상태 사용
                print("알림에서 받은 알람 상태: \(alarmState)")
                alarmActive = alarmState
                
                // 알람이 활성화된 경우 검색 상태를 false로 설정
                if alarmState {
                    searchActivate = false
                }
            } else {
                // UserDefaults에서 알람 상태 확인
                let newState = UserDefaults.standard.bool(forKey: "alarmActive")
                print("UserDefaults에서 가져온 알람 상태: \(newState)")
                alarmActive = newState
                
                // 알람이 횔성화된 경우 검색 상태를 false로 설정
                if newState {
                    searchActivate = false
                }
            }
            
            // 알람 정보 갱신
            forceCheckAlarmStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ResetSearchText"))) { _ in
            // 알람이 설정되었을 때 검색 텍스트 초기화
            print("ResetSearchText 알림 수신됨, 텍스트 초기화")
            textfiledValue = ""
            searchActivate = false
            isEditMode = false
        }
    }
    
    // 강제로 알람 상태 확인 (UserDefaults 직접 읽음)
    private func forceCheckAlarmStatus() {
        // UserDefaults에서 알람 상태 직접 확인
        let forcedAlarmActive = UserDefaults.standard.bool(forKey: "alarmActive")
        print("강제 확인된 알람 상태: \(forcedAlarmActive)")
        
        // 상태 업데이트
        alarmActive = forcedAlarmActive
        searchActivate = false
        
        // 알람 정보 가져오기
        alarmBusNo = UserDefaults.standard.string(forKey: "alarmBusNo") ?? ""
        alarmBusType = UserDefaults.standard.string(forKey: "alarmBusType") ?? ""
        alarmDestination = UserDefaults.standard.string(forKey: "alarmDestination") ?? ""
        alarmRemainingStops = UserDefaults.standard.integer(forKey: "alarmRemainingStops")
        
        // 알람이 활성화되어 있으면 버스 정보 로드
        if forcedAlarmActive {
            loadSavedBusInfo()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: Notification.Name("AlarmStatusChanged"),
                object: nil,
                userInfo: ["alarmActive": forcedAlarmActive]
            )
        }
    }
    
    // 알람 상태 확인 및 데이터 로드
    private func checkAlarmStatus() {
        // UserDefaults에서 알람 상태 확인
        let newAlarmActive = UserDefaults.standard.bool(forKey: "alarmActive")
        print("checkAlarmStatus - 알람 상태: \(newAlarmActive)")
        alarmActive = newAlarmActive
        
        // 알람 정보 가져오기
        alarmBusNo = UserDefaults.standard.string(forKey: "alarmBusNo") ?? ""
        alarmBusType = UserDefaults.standard.string(forKey: "alarmBusType") ?? ""
        alarmDestination = UserDefaults.standard.string(forKey: "alarmDestination") ?? ""
        alarmRemainingStops = UserDefaults.standard.integer(forKey: "alarmRemainingStops")
        
        // 알람이 활성화되어 있으면 버스 정보 로드
        if newAlarmActive {
            loadSavedBusInfo()
        }
    }
    
    // 저장된 버스 정보 로드
    private func loadSavedBusInfo() {
        if let busRouteId = UserDefaults.standard.string(forKey: "alarmBusRouteId") {
            print("버스 ID 로드: \(busRouteId)")
            let descriptor = FetchDescriptor<Bus_info_seoul>(
                predicate: #Predicate<Bus_info_seoul> { $0.busRouteId == busRouteId }
            )
            
            do {
                let buses = try modelContext.fetch(descriptor)
                if let bus = buses.first {
                    print("버스 정보 로드 성공: \(bus.busRouteNm)")
                    savedBus = bus
                    savedCityCode = UserDefaults.standard.integer(forKey: "alarmCityCode")
                } else {
                    print("검색된 버스 없음")
                }
            } catch {
                print("버스 정보 로드 실패: \(error)")
            }
        } else {
            print("저장된 버스 ID 없음")
        }
    }
    
    // 알람 상태 초기화 함수
    private func resetAlarmState() {
        print("알람 상태 초기화")
        UserDefaults.standard.set(false, forKey: "alarmActive")
        UserDefaults.standard.synchronize()
        alarmActive = false
    }
}

struct Main_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
