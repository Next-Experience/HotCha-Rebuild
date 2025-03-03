//
//  hide_keyboards.swift
//  HotCha
//
//  Created by 문재윤 on 3/4/25.
//
import SwiftUI

//되도록 사용 지양하고 FocusState사용하시오 !!~!!
func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
