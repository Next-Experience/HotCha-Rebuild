////
////  TestPrint.swift
////  HotCha
////
////  Created by Yeji Seo on 3/29/25.
////
//
//import SwiftUI
//
//struct TestSeoulBusPrint : View{
//    @State private var allBuses: [Bus] = []
//    @State private var filteredBuses: [Bus] = [] // 버스 번호 검색에 사용
//    @State private var routeNo: String = ""
//    
//    var body: some View{
//        NavigationStack {
//            VStack{
//                Button (action: {
//                    fetchSeoulBusAPI(citycode: 1) { fetchedBuses in
//                        // API 호출 후 데이터 받아오면 로딩 상태 해제
//                        self.allBuses = fetchedBuses.sorted(using: KeyPathComparator(\.routeno))
//                        self.filteredBuses = fetchedBuses.sorted(using: KeyPathComparator(\.routeno))
//                    }
//                    
//                }){
//                    Text("Click Me")
//                }
//                ScrollView(showsIndicators: false) {
//                    
//                        ForEach(filteredBuses) { bus in
//                            
//                            // 네비게이션 링크: 선택된 버스가 있을 때 SelectBusStopView로 이동
//                            NavigationLink(destination: SelectBusStopView(bus: bus, cityCode: 1)){
//                            VStack(alignment: .leading) {
//                                Spacer()
//                                VStack(alignment: .leading) {
//                                    Text("\(bus.routeno)")
//                                        .font(.body)
//                                        .foregroundStyle(.black)
//                                        .padding(.bottom, 4)
//                                    HStack {
//                                        Text("\(bus.startnodenm) - \(bus.endnodenm)")
//                                            .font(.caption2)
//                                            .foregroundStyle(.black)
//                                    }
//                                }
//                                .padding(.horizontal, 16)
//                                
//                                Divider()
//                                    .padding(.top, 20)
//                                    .padding(.bottom, 16)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//}
//
//#Preview {
//    TestSeoulBusPrint()
//}
