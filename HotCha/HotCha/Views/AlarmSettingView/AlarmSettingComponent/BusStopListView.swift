//
//  BusStopList.swift
//  HotCha
//
//  Created by Yeji Seo on 2/9/25.
//

import SwiftUI


struct BusStopListView: View {
    let busStops: [BusStopElementCase] =
            Array(repeating: .disableStop, count: 5) +
    [.currentStop] +
            Array(repeating: .ableStop, count: 2) +
    [.alarmStop, .ableStop, .destinationStop]
    + Array(repeating: .ableStop, count: 2)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0){
                ForEach(busStops.indices, id: \.self) { index in
                    ZStack(alignment: .bottom) {
                        Divider()
                            .background(.gray100.opacity(0.15))
                        
                        BusStopElement(stopCase: busStops[index])
                    }
                }
                
                
            
                
                
            }
            .padding(0)
        }
        .ignoresSafeArea(.all)
        .background(.gray900)
    
    }
}

#Preview {
    AlarmSettingView()
}
