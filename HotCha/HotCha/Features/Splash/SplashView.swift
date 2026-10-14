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
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("내릴 때는")
                    .foregroundStyle(.primary)
                Text("\(Text("핫챠").foregroundStyle(Color("mainpurple")))가 알려드려요")
                    .foregroundStyle(.primary)
                Image(Clay.bus.rawValue)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.bottom, 70)
                    .accessibilityHidden(true)
            }
            .font(.pretendard(.bold, size: 36))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
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
            && alarmRinger.isAuthorized
    }
}


#Preview {
    SplashView()
}
