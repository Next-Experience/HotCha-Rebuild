//
//  Bookmarkcardcustom.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//


import SwiftUI

struct BookmarkCardCustomView: View {
    let isEditMode: Bool
    var bookmark: Bookmarkmodel
    var alarmActive: Bool
    @State private var isTapped: Bool = false
    @State private var showingAlert = false
    @Environment(\.modelContext) private var modelContext
    @State var isBookmark: Bool = false // 필요 x, but navigate 에 필요
    @Binding var type_name: String // 필요 x, but navigate 에 필요
    
    @ObservedObject var modalStateViewModel: AlarmModalViewModel
    @ObservedObject var busStopSeoulViewModel: BusStopSeoulViewModel
    @ObservedObject var nearestBusViewModel: NearestBusViewModel
    @ObservedObject var sheetManager: AlarmSettingModalSheetManager
    
    @State private var shouldNavigate = false  // 네비게이션 트리거
    
    private func deleteBookmark(_ bookmark: Bookmarkmodel) {
        modelContext.delete(bookmark)
        do {
            try modelContext.save()
        } catch {
            print("즐겨찾기 삭제 실패: \(error)")
        }
    }
    
    //
    
    
    
    var body: some View {
        VStack {
            VStack(spacing: 14 ) {
                HStack {
                    
                    if bookmark.bookmark_type ==  1 {
                        Image("houseicon")
                        Text(bookmark.bookmark_label)
                            .font(.pretendard(.bold, size: 14))
                    }
                    else if bookmark.bookmark_type ==  2 {
                        Image("buildingicon")
                        Text(bookmark.bookmark_label)
                            .font(.pretendard(.bold, size: 14))
                    }
                    else {
                        Image("staricon")
                        Text(bookmark.bookmark_label)
                            .font(.pretendard(.bold, size: 14))
                    }
                    Spacer()
                    
                    Image(isEditMode ? "deleteicon" :"chevron-righticon")
                        .onTapGesture {
                            withAnimation {
                                if isEditMode == true {
                                    deleteBookmark(bookmark)
                                }
                            }
                        }
                    
                }
                
                VStack(spacing: 6) {
                    HStack {
                        //                        BookmarkBusNoView(busNo: bookmark.bus_no, route_type: bookmark.route_type)
                        SearchBusUtil.CustomBusNoView(busNo: bookmark.bus_no, routeType: bookmark.route_type)
                        Spacer()
                        
                    }
                    HStack {
                        Text(bookmark.destination_stop_name)
                            .font(.pretendard(.semibold, size: 16))
                        Spacer()
                    }
                }
                .frame(height: 42)
                
                
            }
            .padding(12)
        }
        .background(isTapped ? Color("gray300") : Color("gray150"))
        .cornerRadius(8)
        .onTapGesture {
                    if isEditMode == false {
                        if alarmActive {
                            showingAlert = true
                        } else {
                            withAnimation {
                                isTapped = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    isTapped = false
                                }
                            }
                            isBookmark = false
                            
                            // 알람 시작
                            busStopSeoulViewModel.shortcutDestinationId = bookmark.destination_stop_id
                            busStopSeoulViewModel.isReload = true
                            modalStateViewModel.modalState = .alertStopsMedium
                            busStopSeoulViewModel.shortcutExecute = true // 알람 실행에 필요한 데이터를 로드하기 위한  트리거
                            shouldNavigate = true  // 네비게이션 트리거
                        }
                    }
                }
                .navigationDestination(isPresented: $shouldNavigate) {
                    AlarmSettingView(
                        bus: Bus_info_seoul(from:bookmark.bus),
                        cityCode: .constant(Int(bookmark.bus.city_code) ?? 1),
                        isBookmark: $isBookmark,
                        type_name: $type_name,
                        modalStateViewModel: modalStateViewModel,
                        busStopSeoulViewModel: busStopSeoulViewModel,
                        nearestBusViewModel: nearestBusViewModel,
                        sheetManager: sheetManager
                    )
                }
        .alert("새로운 알림을 시작하시겠어요?", isPresented: $showingAlert) {
            Button("그만두기", role: .cancel) {
                // 취소 동작
            }
            Button("실행하기") {
                // 기존 알림 취소 후 새 알림 설정
                
            }
        } message: {
            Text("알림은 한 개만 설정할 수 있어요. 새로운 알림을 시작하면 기존의 설정한 알림이 취소돼요.")
        }
    }
}
