//
//  BatteryManager.swift
//  Gizo
//
//  Created by Meysam Farmani on 2/23/24.
//

import Foundation
import Combine
import UIKit

class BatteryManager: NSObject {
    
    private var dataManager = DataManager.shared
    var batteryStatusPublisher = PassthroughSubject<BatteryStatus, Never>()
//    var batteryStatusNoCameraPublisher = PassthroughSubject<BatteryStatusNoCamera, Never>()
    
    static let shared = BatteryManager()
    
    override init() {
        super.init()
    }
    
    func startBatteryStatus(){
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryDidChange), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        batteryDidChange()
    }
    
    @objc fileprivate func batteryDidChange() {
        let batteryState = UIDevice.current.batteryState
        
        if (batteryState == .unplugged || batteryState == .charging) {
            let batteryLevel = UIDevice.current.batteryLevel
            
            switch batteryLevel {
                case BatteryStatus.stop.rawValue..<BatteryStatus.warning.rawValue:
                    batteryStatusPublisher.send(BatteryStatus.warning)
                case 0..<BatteryStatus.stop.rawValue:
                    batteryStatusPublisher.send(BatteryStatus.stop)
                default:
                    batteryStatusPublisher.send(BatteryStatus.normal)
            }
//            
//            switch batteryLevel {
//                case BatteryStatusNoCamera.stop.rawValue..<BatteryStatusNoCamera.warning.rawValue:
//                    batteryStatusNoCameraPublisher.send(BatteryStatusNoCamera.warning)
//                case 0..<BatteryStatusNoCamera.stop.rawValue:
//                    batteryStatusNoCameraPublisher.send(BatteryStatusNoCamera.stop)
//                default:
//                    batteryStatusNoCameraPublisher.send(BatteryStatusNoCamera.normal)
//            }
        }
    }

    func stopBatteryStatus() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryStateDidChangeNotification, object: nil)
        UIDevice.current.isBatteryMonitoringEnabled = false    }
}

