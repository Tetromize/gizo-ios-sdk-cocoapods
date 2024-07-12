//
//  LocationModel.swift
//  Gizo
//
//  Created by Hepburn on 2023/9/21.
//

import Foundation

public struct LocationModel: Codable {
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var speed: Double?
    var speedLimit: Double?
    var course: Double?
}
