//
//  ActivityManager.swift
//  Gizo
//
//  Created by Meysam Farmani on 2/23/24.
//

import UIKit
import CoreMotion
import Combine

public enum ActivityType : Int {
    case unknown = 0
    case still = 1
    case walking = 2
    case running = 3
    case in_vehicle = 4
    case cycling = 5
    case startRecording = 6
}

class ActivityManager: NSObject {
    private var activityManager: CMMotionActivityManager = CMMotionActivityManager.init()
    public var type: ActivityType = .unknown
    public var preType: ActivityType = .unknown
    public var typeName: String = "UNKNOWN"
    private var activityTimer: Timer?
    private var BufferSize: Int = 120
    private var BufferM: Int = 20
    private var C_thrsh: Float = 0.6
    private var activityBuffer: [ActivityType] = Array.init(repeating: .unknown, count: 120)
    private var confidence: String = "low"
    var activityTypePublisher = PassthroughSubject<ActivityType, Never>()
    
    var isRecordingActivity = false
    
    private var dataManager = DataManager.shared
    
    static let shared = ActivityManager()
    
    static func checkMotionPermission() -> AuthorizationStatus {
        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        }
    }
    
    static func requestMotionPermission() {
        // Check if motion activity is available on the device
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("Motion activity is not available on this device.")
            return
        }
        
        // Start and then immediately stop activity updates to prompt for permission
        let tempActivityManager = CMMotionActivityManager()
        tempActivityManager.startActivityUpdates(to: .main) { (activity) in
            // Optional: Handle the activity data if needed
        }
        tempActivityManager.stopActivityUpdates()
    }

    public func startUpdateMotionActivity() {
        if (!CMMotionActivityManager.isActivityAvailable()) {
            return
        }
        if (activityTimer == nil) {
            activityTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(onTimeCheck), userInfo: nil, repeats: true)
        }
        activityTypePublisher.send(type)
        activityManager.startActivityUpdates(to: OperationQueue.current!) { activity in
            if (activity != nil) {
                if (activity!.confidence == .low) {
                    self.confidence = "low"
                }
                else if (activity!.confidence == .medium) {
                    self.confidence = "mid"
                }
                else if (activity!.confidence == .high) {
                    self.confidence = "high"
                }
                self.type = .unknown
                self.typeName = "UNKNOWN"
                if (activity!.stationary) {
                    self.type = .still
                    self.typeName = "STILL"
                }
                else if (activity!.walking) {
                    self.type = .walking
                    self.typeName = "WALKING"
                }
                else if (activity!.running) {
                    self.type = .running
                    self.typeName = "RUNNING"
                }
                else if (activity!.automotive) {
                    self.type = .in_vehicle
                    self.typeName = "IN_VEHICLE"
                }
                else if (activity!.cycling) {
                    self.type = .cycling
                    self.typeName = "CYCLING"
                }
            }
        }
    }
    
    public func stopUpdateMotionActivity() {
        if (!CMMotionActivityManager.isActivityAvailable()) {
            return
        }
        activityManager.stopActivityUpdates()
        self.type = .unknown
        stopTimer()
    }
    
    func stopTimer(){
        if activityTimer != nil {
            activityTimer?.invalidate()
            activityTimer = nil
        }
    }
    
    @objc func onTimeCheck() {
        let model = LogActivityModel()
        print("ssssssssss")
        model.activity = self.typeName
        model.confidence = self.confidence
//        LogActivityManager.shared.appendActivityCSV(model: model)
        if (self.confidence == "low") {
            return
        }
        activityRecognize(activityType: self.type)
    }
    
    func activityRecognize(activityType: ActivityType) {
        activityBuffer.append(activityType)
        activityBuffer.remove(at: 0)
        
        let act_st = getMaxOccurActivity(suffix: true)
        let act_lt = getMaxOccurActivity(suffix: false)
        if (act_st == .unknown || act_st == .still) {
            if (act_st == act_lt) {
                updateActivity(type: act_st)
            }
            else {
            }
        }
        else {
            updateActivity(type: act_st)
        }
    }
    
    func updateActivity(type: ActivityType) {
        if (preType != type) {
            if isRecordingActivity {
                recordActivity(preType: preType, type: type)
            }
            preType = type
            activityTypePublisher.send(type)
        }
    }
    
    func getMaxOccurActivity(suffix: Bool=false) -> ActivityType {
        var buffer = activityBuffer
        var length = BufferSize
        if (suffix) {
            buffer = activityBuffer.suffix(BufferM)
            length = BufferM
        }
        var numbers: [Int:Int] = [:]
        for t in buffer {
            if (numbers[t.rawValue] == nil) {
                numbers[t.rawValue] = 0
            }
            numbers[t.rawValue]! += 1
        }
        var maxNum: Int = 0
        var maxType: ActivityType = .unknown
        for t in numbers.keys {
            if (numbers[t]! > maxNum) {
                maxNum = numbers[t]!
                maxType = ActivityType.init(rawValue: t)!
            }
        }
        let confidence: Float = Float(maxNum)/Float(length)
        if (confidence >= C_thrsh) {
            return maxType
        }
        return .unknown
    }
    
    func getActivityType(name: String) -> ActivityType {
        var type: ActivityType = .unknown
        if (name == "Stationary") {
            type = .still
        }
        else if (name == "Walking") {
            type = .walking
        }
        else if (name == "Running") {
            type = .running
        }
        else if (name == "Automotive") {
            type = .in_vehicle
        }
        else if (name == "Cycling") {
            type = .cycling
        }
        return type
    }
    
    func getActivityTypeName(type: ActivityType) -> String {
        var name: String = "UNKNOWN"
        if (type == .still) {
            name = "STILL"
        }
        else if (type == .walking) {
            name = "WALKING"
        }
        else if (type == .running) {
            name = "RUNNING"
        }
        else if (type == .in_vehicle) {
            name = "IN_VEHICLE"
        }
        else if (type == .cycling) {
            name = "CYCLING"
        }
        else if (type == .startRecording) {
            name = ""
        }
        return name
    }
    
    func startRecording(){
        self.isRecordingActivity = true
        recordActivity(preType: ActivityType.startRecording, type: self.type)
    }
    
    private func recordActivity(preType: ActivityType, type: ActivityType) {
        let model = TripCSVActivityModel.init()
        model.stopped = getActivityTypeName(type: preType)
        model.started = getActivityTypeName(type: type)
        
        dataManager.appendActivityCSV(model: model)
    }
    
    func stopRecording(){
        self.isRecordingActivity = false
    }
}
