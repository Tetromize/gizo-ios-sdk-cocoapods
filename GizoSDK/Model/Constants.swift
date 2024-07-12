//
//  Constants.swift
//  Gizo
//
//  Created by Meysam Farmani on 1/31/24.
//

import Foundation

struct Constants {
    static let baseUrl = "https://api.artificient.de"
    static let lockFileName = "trip.lock"
    static let videoFileName = "video.mp4"
    static let infoFileName = "info.txt"
    static let matrixFileName = "matrix.txt"
    static let ttcFileName = "ttc.csv"
    static let gpsFileName = "gps.csv"
    static let imuFileName = "imu.csv"
    static let actFileName = "act.csv"
    static let appFileName = "app.csv"
    static let phoneEventsFileName = "phone_events.csv"
    
    static let FULL = "Full"
    static let BACKGROUND = "IMU"
    static let NO_CAMERA = "ImuGps"
}
