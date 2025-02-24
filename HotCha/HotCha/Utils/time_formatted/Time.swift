//
//  time.swift
//  HotCha
//
//  Created by 문재윤 on 2/7/25.
//
import Foundation

func formattedTime(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"  // 24시간제 시:분 형식
    return formatter.string(from: date)
}
