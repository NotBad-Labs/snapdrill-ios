//
//  Item.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/7/21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
