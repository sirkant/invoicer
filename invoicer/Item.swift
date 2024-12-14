//
//  Item.swift
//  invoicer
//
//  Created by Luis Caceres on 2024-12-14.
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
