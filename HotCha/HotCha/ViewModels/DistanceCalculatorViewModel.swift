//
//  Untitled.swift
//  HotCha
//
//  Created by 문재윤 on 2/12/25.
//

import Foundation
import Combine



class DistanceCalculatorViewModel: ObservableObject {
    @Published var distance: Double = 0
    
    func calculateDistance(from origin: CGPoint, to destination: CGPoint) {
        let dx = Double(origin.x - destination.x)
        let dy = Double(origin.y - destination.y)
        distance = sqrt(dx * dx + dy * dy)
    }
}
