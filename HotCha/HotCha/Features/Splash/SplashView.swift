//
//  SplashView.swift
//  HotCha
//
//  Created by 문재윤 on 3/11/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isSplashActive = false
    @AppStorage("OnBoarding_True") var OnBoardingTrue: Bool = false
    @StateObject private var onboardingLocation = LocationViewModel()
    @ObservedObject private var alarmRinger = AlarmRinger.shared
    
    var body: some View {
        if isSplashActive {
            if OnBoardingTrue && requiredPermissionsAreGranted {
                NavigationView()
            } else {
                OnBoardingView(
                    locationViewModel: onboardingLocation,
                    alarmRinger: alarmRinger,
                    startsAtPermissions: OnBoardingTrue
                )
            }
            
        } else {
            VStack {
                Spacer()
                HStack {
                    Text("안전하게")
                        .font(.pretendard(.bold, size: 36))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 30)
                HStack {
                    Text("핫챠")
                        .font(.pretendard(.bold, size: 36))
                        .foregroundStyle(Color("mainpurple"))
                    Text("하세요")
                        .font(.pretendard(.bold, size: 36))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 30)
                Image("splashbus")
                    .padding(.bottom, 70)
            }
            .background(HotChaContentBackground())
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    isSplashActive = true
                    
                }
            }
        }
        
        
    }

    private var requiredPermissionsAreGranted: Bool {
        onboardingLocation.authorizationStatus == .authorizedAlways
            && alarmRinger.authorization == .authorized
    }
}


#Preview {
    SplashView()
}
