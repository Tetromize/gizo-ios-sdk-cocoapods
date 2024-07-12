//
//  TripCSVPhoneModel.swift
//  Gizo
//
//  Created by Hepburn on 2023/12/25.
//

import UIKit

enum TripCSVPhoneType: String {
    case Microphone = "microphone"
    case Telephony = "telephony"
    case Screen = "SCREEN"
}

enum MicrophoneType: String {
    case IN_CALL = "IN_CALL"
    case AVAILABLE = "AVAILABLE"
}

enum TelephonyType: String {
    case CALL_STATE_IDLE = "CALL_STATE_IDLE"
    case CALL_STATE_RINGING = "CALL_STATE_RINGING"
    case CALL_STATE_OFFHOOK = "CALL_STATE_OFFHOOK"
}

enum ScreenType: String {
    case LOCKED = "LOCKED"
    case UNLOCK = "UNLOCK"
}

class TripCSVPhoneModel: Codable {
    var time: String  = DateTimeUtil.stringFromDateTime(date: Date(), format: "yyyy-MM-dd HH:mm:ss.SSS").appending("Z").replacingOccurrences(of: " ", with: "T")
    var event: String = "N/A"
    var value: String = "N/A"
    
    static var csvDesc: String {
        return "Time,Event,Value"
    }
    
    var csvValue: String {
        return "\(time),\(event),\(value)"
    }
}
