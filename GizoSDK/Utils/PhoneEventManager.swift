//
//  PhoneEventManager.swift
//  Gizo
//
//  Created by Meysam Farmani on 2/23/24.
//

import Foundation
import CallKit

class PhoneEventManager: NSObject, CXCallObserverDelegate {
    
    private var callObserver: CXCallObserver = CXCallObserver.init()
    var isRecordingPhoneEvent = false

    private var dataManager = DataManager.shared

    static let shared = PhoneEventManager()
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        var event = ""
        var value = ""
        if (!call.isOutgoing) {
            event = TripCSVPhoneType.Telephony.rawValue
            if (!call.isOnHold && call.hasConnected && !call.hasEnded) {
                value = TelephonyType.CALL_STATE_OFFHOOK.rawValue
            }
            else if (!call.isOnHold && call.hasEnded) {
                value = TelephonyType.CALL_STATE_IDLE.rawValue
            }
            else if (!call.hasConnected && !call.hasEnded) {
                value = TelephonyType.CALL_STATE_RINGING.rawValue
            }
            if isRecordingPhoneEvent {
                recordPhoneEvent(event: event, value: value)
            }
        }
    }
    
    func startRecording(){
        self.isRecordingPhoneEvent = true
    }
    
    private func recordPhoneEvent(event: String, value: String) {
        let model: TripCSVPhoneModel = TripCSVPhoneModel.init()

        model.event = event
        model.value = value
        
        dataManager.appendPhoneEventCSV(model: model)
    }
    
    func stopRecording(){
        self.isRecordingPhoneEvent = false
    }
}
