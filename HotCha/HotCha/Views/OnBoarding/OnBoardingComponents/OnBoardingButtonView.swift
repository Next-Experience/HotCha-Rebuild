//
//  OnBoardingButtonView.swift
//  HotCha
//
//  Created by 문재윤 on 3/12/25.
//

import SwiftUI
import SwiftData

struct OnboardingButtonview: View {
    @State private var isTapped: Bool = false
    @AppStorage("OnBoarding_True") var OnBoardingTrue: Bool = false
    @StateObject private var viewModel = BusRouteViewModel()
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        HStack {
            Spacer()
            Text("바로 시작하기")
                .padding(.vertical, 15)
                .font(.pretendard(.semibold, size: 20))
                .foregroundStyle(Color("gray900"))
            Spacer()
            
        }
        .background(isTapped ? Color("purplec") : Color("mainpurple"))
        .cornerRadius(8)
        .onAppear {
            viewModel.fetchBusRoutes(searchStr: "")
        }
        
        .onTapGesture {
            withAnimation {
                isTapped = true
                viewModel.fetchBusRoutes(searchStr: "")
                
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isTapped = false
                    OnBoardingTrue = true
                    viewModel.fetchBusRoutes(searchStr: "")
                    saveBusRoutesToDatabase(routes: viewModel.busRoutes, context: modelContext)
                    print("gjf")
                    
                }
            }
        }
    }
}

#Preview {
    OnboardingButtonview()
}
