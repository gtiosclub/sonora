//
//  Finding.swift
//  Sonora
//
//  Created by Judy Hsu on 10/8/26.
//
import Foundation

struct Finding: Codable, Equatable {
    var start: TimeInterval
    var duration: TimeInterval  // 0 for instant things
    var message: String         // "You paused for 2.1 s"
}
