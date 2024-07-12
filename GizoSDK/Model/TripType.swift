//
//  TripType.swift
//  Gizo
//
//  Created by mahyar on 04.02.24.
//

import Foundation

enum TripType: String, CaseIterable {
    case Full = "Full"
    case Imu = "Imu"
    case ImuGps = "ImuGps"
    case NoAnalyze = "NoAnalyze"
    
    var index: Int {
        return TripType.allCases.firstIndex(of: self) ?? 0
    }
}
