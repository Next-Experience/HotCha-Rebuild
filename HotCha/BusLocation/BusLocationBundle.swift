//
//  BusLocationBundle.swift
//  BusLocation
//
//  Created by 문호 on 4/9/25.
//

import WidgetKit
import SwiftUI

@main
struct BusLocationBundle: WidgetBundle {
    var body: some Widget {
        BusLocation()
        BusLocationControl()
        BusLocationLiveActivity()
    }
}
