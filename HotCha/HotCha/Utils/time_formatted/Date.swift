//
//  date.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//

import Foundation

func formattedDate(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"  // 년-월-일 형식
    return formatter.string(from: date)
}
