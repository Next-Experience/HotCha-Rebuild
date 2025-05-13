//
//  MakeJunkdata.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//


// 임시 버스 생성 crud
import SwiftUI
import SwiftData

struct AddBookmarkView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var bus: Bus_info_seoul
    @State private var routeID: String = ""
    @State private var cityCode: String = ""
    @State private var destinationStopID: String = ""
    @State private var destinationStopName: String = ""
    @State private var busNo: String = ""
    @State private var routeType: String = ""
    @State private var bookmarkLabel: String = ""
    @State private var bookmarktype: Int = 0
    
    let type_name: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("상세정보 작성")) {
                    TextField("노선id", text: $routeID)
                    TextField("도시 코드", text: $cityCode)
                    TextField("정류장 id", text: $destinationStopID)
                    TextField("정류장 이름", text: $destinationStopName)
                    TextField("버스 번호", text: $busNo)
                    TextField("노선 타입", text: $routeType)
                    TextField("라벨", text: $bookmarkLabel)

                }
                }
                
                Button("저장") {
                    if type_name == "집" {
                        bookmarkLabel = "집"
                        bookmarktype = 1
                    } else if type_name == "회사" {
                        bookmarkLabel = "회사"
                        bookmarktype = 2
                    } else {
                        bookmarktype = 0
                    }

                    let newBookmark = Bookmarkmodel(
                        bus: bus,
                        route_id: routeID,
                        city_code: cityCode,
                        destination_stop_id: destinationStopID,
                        destination_stop_name: destinationStopName,
                        bus_no: busNo,
                        route_type: routeType,
                        bookmark_label: bookmarkLabel,
                        bookmark_type: bookmarktype
                    )
                    modelContext.insert(newBookmark)
                    dismiss()
                }
                .navigationTitle("즐겨찾기 추가")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") {
                            dismiss()
                        }
                    }
                }
            }
            
        }
    }


