//
//  BatteryState.swift
//  Gizo
//
//  Created by Meysam Farmani on 2/23/24.
//

import Foundation

public enum BatteryStatus: Float {
    case warning = 0.25
    case stop = 0.15
    case normal = 1
}

public enum BatteryStatusNoCamera: Float {
    case warning = 0.15
    case stop = 0.05
    case normal = 1
}
