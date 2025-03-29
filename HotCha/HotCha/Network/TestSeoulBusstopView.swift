//
//  TestSeoulBusstop.swift
//  HotCha
//
//  Created by Yeji Seo on 3/29/25.
//


// 버스 정류장 선택하는 뷰입니다.
import SwiftUI
import SwiftData

struct SelectBusStopView: View {
    //    let city: City // 도시 정보
    let bus: Bus // 선택된 버스 정보
    let cityCode: Int // ← 추가된 부분
    @Environment(\.dismiss) private var dismiss
    @StateObject private var busStopSeoulviewModel = BusStopSeoulViewModel()
   
    var body: some View {
        VStack{
            HStack {
                Text("\(bus.routeno)")
                    .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 0))
                Spacer()
                Image("magnifyingglass")
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 20.67)
            }
            .cornerRadius(20)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
            }
            .padding(EdgeInsets(top: 44, leading: 0, bottom: 24, trailing: 0))

                    SeoulBusStopScrollView()

        }
        .padding(.horizontal, 20)
        .navigationTitle("버스 검색")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 닫기 버튼
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("뒤로")
                            .padding(.leading, -7)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            if cityCode == 1 {
                await busStopSeoulviewModel.fetchBusStations(routeid: bus.routeid)
                print(busStopSeoulviewModel.fetchBusStations(routeid: bus.routeid),"테스트 프린트")
            }
        }
        .background(ignoresSafeAreaEdges: .horizontal)
    }
    
    /// Bus List 뷰
    private func SeoulBusStopScrollView() -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                ForEach(busStopSeoulviewModel.busStations, id: \.nodeord) { busstop in
                    VStack {
                        Spacer()
                        HStack {
                                Text("\(busstop.nodenm)")
                                    .padding(.leading, 24)
                            Spacer()
                        }
                        Spacer()
                        Divider()
                    }
                    .frame(height: 60)
                }
            }
            .onAppear{
                print(busStopSeoulviewModel.busStations,"온어피어 프린트")
            }
        }
    }
}

