//
//  Item.swift
//  NotBad
//
//  Created by YIMING LIAO on 8/20/25.
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
