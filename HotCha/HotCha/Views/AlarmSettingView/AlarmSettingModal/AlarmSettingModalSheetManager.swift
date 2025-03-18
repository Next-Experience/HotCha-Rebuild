//
//  AlarmSettingModalSheetManager.swift
//  HotCha
//
//  Created by Yeji Seo on 3/18/25.
//

import SwiftUI

// AlarmSettingView의 modal sheet를 관리
class AlarmSettingModalSheetManager: ObservableObject {
    @Published var showAlarmSearchSheet1: Bool = false
    @Published var showAlarmInfoSheet2: Bool = false
}
