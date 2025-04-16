//
//  Untitled.swift
//  HotCha
//
//  Created by 문재윤 on 2/4/25.
//

import SwiftUI
import SwiftData
import ActivityKit

struct MainView: View {
    @State var isEditMode: Bool = false
    @State var searchActivate: Bool = false
    @State var textfiledValue: String = ""
    @Binding var isSwipeDisabled : Bool
    //swift data에 저장유무
    @AppStorage("Bus_info_seoul_True") var Bus_info_seoul_True: Bool = false
    
    @StateObject private var viewModel = BusRouteViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        // 메인뷰 전체
        VStack(spacing: 12) {
            
            // '버스번호를 알려주세요' 텍스트 필드
            MainTextfiled(isEditMode: $isEditMode, textfiledValue: $textfiledValue, searchActivate: $searchActivate)
            
            
            if searchActivate {
                // 서치뷰 전환
                SearchView(textfiledValue: $textfiledValue, searchActivate: $searchActivate)
//                    .onAppear{isSwipeDisabled = true}
                
            } else {
                // 즐겨찾기 항목들
                BookmarkView(isEditMode: $isEditMode)
//                    .onAppear{isSwipeDisabled = false}
                    .padding(.top,12)
            }
            Spacer()
//            VStack {
//                Button {
//                    let attributes = BeforeBusStopAttributes(name: "BusStop Sample")
//                    let contentState = BeforeBusStopAttributes.ContentState()
//                    let content = ActivityContent(state: contentState, staleDate: nil)
//                    do {
//                        _ = try Activity<BeforeBusStopAttributes>.request(attributes: attributes, content: content, pushType: nil)
//                        print("LiveActivity 성공적으로 시작됨")
//                    } catch {
//                        print("LiveActivityManager: Error in LiveActivityManager: \(error.localizedDescription)")
//                    }
//                } label: {
//                    Text("Test Live Activity")
//                }
//            }
//            .padding()
        }
        .padding(20)
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("gray50"))
        .onAppear{
            if !Bus_info_seoul_True {
                viewModel.fetchBusRoutes(searchStr: "")
                saveBusRoutesToDatabase(routes: viewModel.busRoutes, context: modelContext)
                Bus_info_seoul_True = true
            }
        }

    }
        
}



struct Main_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
