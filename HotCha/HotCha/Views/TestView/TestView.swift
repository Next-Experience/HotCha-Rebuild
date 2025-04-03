//
//  TestView.swift
//  APITest3
//
//  Created by 문호 on 3/14/25.
//

import SwiftUI
import Combine

struct TestView: View {
    @StateObject private var viewModel = BusSearchViewModel()
    
    @State private var cityCode: String = ""
    @State private var selectedRouteId: String? = nil
    @State private var showStations: Bool = false
    
    // 키보드 상태 관리를 위한 변수
    @FocusState private var isCityCodeFocused: Bool
    @FocusState private var isBusNumberFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 제목
            Text("버스 정보 검색")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // 지역코드 및 버스 번호 입력 영역
            VStack(spacing: 16) {
                HStack {
                    Text("지역코드:")
                        .font(.headline)
                    
                    TextField("지역코드 입력", text: $cityCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 100)
                        .focused($isCityCodeFocused)
                    
                    Text("(예: 25=대전, 21=부산)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 키보드 해제 버튼 (지역코드 필드에 포커스가 있을 때만 표시)
                    if isCityCodeFocused {
                        Button("완료") {
                            isCityCodeFocused = false
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                HStack {
                    Text("버스 번호:")
                        .font(.headline)
                    
                    TextField("버스 번호 입력", text: $viewModel.busNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .focused($isBusNumberFocused)
                    
                    // 키보드 해제 버튼 (버스 번호 필드에 포커스가 있을 때만 표시)
                    if isBusNumberFocused {
                        Button("완료") {
                            isBusNumberFocused = false
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Button("검색") {
                        // 검색 시 키보드 해제
                        isCityCodeFocused = false
                        isBusNumberFocused = false
                        
                        viewModel.cityCode = cityCode
                        viewModel.searchBusRoute()
                        selectedRouteId = nil
                        showStations = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // 검색 결과 영역에 탭 제스처 추가하여 키보드 해제
            if showStations, let selectedRoute = viewModel.routeList.first(where: { $0.routeId == selectedRouteId }) {
                stationListView(for: selectedRoute)
                    .onTapGesture {
                        isCityCodeFocused = false
                        isBusNumberFocused = false
                    }
            } else {
                busSearchResultView
                    .onTapGesture {
                        isCityCodeFocused = false
                        isBusNumberFocused = false
                    }
            }
            
            Spacer()
        }
        // 전체 화면에 탭 제스처 추가
        .contentShape(Rectangle())
        .onTapGesture {
            isCityCodeFocused = false
            isBusNumberFocused = false
        }
        .onDisappear {
            viewModel.cancelAllRequests()
        }
    }
    
    // 버스 검색 결과 뷰
    var busSearchResultView: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("로딩 중...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if !viewModel.routeList.isEmpty {
                // 노선 목록
                VStack {
                    Text("검색 결과: \(viewModel.routeList.count)개")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.routeList) { route in
                                busRouteCard(route)
                                    .onTapGesture {
                                        // 탭 시 키보드 해제 후 노선 선택
                                        isCityCodeFocused = false
                                        isBusNumberFocused = false
                                        
                                        selectedRouteId = route.routeId
                                        viewModel.selectRoute(route)
                                        showStations = true
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else if viewModel.busNumber.isEmpty {
                // 초기 상태 안내
                VStack {
                    Image(systemName: "bus.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .padding()
                    
                    Text("지역코드와 버스 번호를 입력하고 검색 버튼을 눌러주세요.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Text("지역코드 예시: 25=대전, 21=부산, 22=대구, 23=인천, 24=광주")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    Text("26=울산, 12=세종, 31=경기, 32=강원, 33=충북, 34=충남")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding()
            } else {
                // 검색 결과 없음
                Text("검색 결과가 없습니다.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    // 버스 노선 카드 뷰
    func busRouteCard(_ route: BusRouteInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("버스: \(route.routeName)")
                .font(.headline)
            
            Text("유형: \(route.routeTypeName)")
                .font(.subheadline)
            
            Text("\(route.startStationName) → \(route.endStationName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("첫차: \(route.firstBusTime), 막차: \(route.lastBusTime)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
    }
    
    // 정류장 목록 뷰
    func stationListView(for selectedRoute: BusRouteInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 노선 기본 정보
            VStack(alignment: .leading, spacing: 4) {
                Text("버스: \(selectedRoute.routeName)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("유형: \(selectedRoute.routeTypeName)")
                
                Text("\(selectedRoute.startStationName) → \(selectedRoute.endStationName)")
                
                Text("첫차: \(selectedRoute.firstBusTime), 막차: \(selectedRoute.lastBusTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // 정류장 목록
            Text("정류장 목록")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView("정류장 정보 로딩 중...")
                    .padding()
            } else if viewModel.selectedRouteStations.isEmpty {
                Text("정류장 정보가 없습니다.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.selectedRouteStations) { station in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(station.stationName)")
                                    .font(.headline)
                                
                                Text("정류장 번호: \(station.stationId)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 뒤로 가기 버튼
            Button("버스 목록으로 돌아가기") {
                showStations = false
                selectedRouteId = nil
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
}

// iOS 13/14 호환성을 위한 키보드 해제 확장
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
