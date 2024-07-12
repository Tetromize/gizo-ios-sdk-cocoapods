//
//  IMUManager.swift
//  Gizo
//
//  Created by Meysam Farmani on 2/23/24.
//

import UIKit
import Foundation
import CoreMotion
import Combine

class IMUManager: NSObject {
    private var motionManager: CMMotionManager!
    public var shootingOrientation: UIDeviceOrientation = UIDeviceOrientation.portrait
    public var isValidOrientation: Bool = false
    private var timer: DispatchSourceTimer?
    var orientationUpdatePublisher = PassthroughSubject<Bool, Never>()
    public var accX: Double?
    public var accY: Double?
    public var accZ: Double?
    public var accLinX: Double?
    public var accLinY: Double?
    public var accLinZ: Double?
    public var gyrX: Double?
    public var gyrY: Double?
    public var gyrZ: Double?
    public var graX: Double?
    public var graY: Double?
    public var graZ: Double?
    public var magX: Double?
    public var magY: Double?
    public var magZ: Double?
    public var updateInterval: Double=0.01
    
    private var dataManager = DataManager.shared
    static let shared = IMUManager()
    
    override init() {
        super.init()
        motionManager = CMMotionManager.init()
        motionManager.deviceMotionUpdateInterval = updateInterval
    }

    public func startUpdateAccelerometer() {
        if (self.motionManager.isAccelerometerAvailable) {
            self.motionManager.accelerometerUpdateInterval = updateInterval
            self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (accelerometerData, error) in
                let x = accelerometerData?.acceleration.x ?? 0
                let y = accelerometerData?.acceleration.y ?? 0
                let z = accelerometerData?.acceleration.z ?? 0
                self.accX = x*9.81
                self.accY = y*9.81
                self.accZ = z*9.81
                if ((fabs(y) + 0.1) >= fabs(x)) {
                    if (y >= 0.1) {
                        self.shootingOrientation = UIDeviceOrientation.portraitUpsideDown
                    }
                    else {
                        self.shootingOrientation = UIDeviceOrientation.portrait
                    }
                }
                else {
                    if (x >= 0.1) {
                        self.shootingOrientation = UIDeviceOrientation.landscapeRight
                    }
                    else if (x <= 0.1) {
                        self.shootingOrientation = UIDeviceOrientation.landscapeLeft
                    }
                    else {
                        self.shootingOrientation = UIDeviceOrientation.portrait
                    }
                }
                if (fabs(z) < 0.4) {
                    self.isValidOrientation = true
                }
                else {
                    self.isValidOrientation = false
                }
                
                if ((self.shootingOrientation == UIDeviceOrientation.landscapeLeft || self.shootingOrientation == UIDeviceOrientation.landscapeRight) && self.isValidOrientation) {
                    self.orientationUpdatePublisher.send(true)
                }
            }
        }
    }

    public func stopUpdateAccelerometer() {
        if (self.motionManager.isAccelerometerActive) {
            self.motionManager.stopAccelerometerUpdates()
        }
    }

    public func startUpdateGyro() {
        if (self.motionManager.isGyroAvailable) {
            self.motionManager.gyroUpdateInterval = updateInterval
            self.motionManager.startGyroUpdates(to: OperationQueue.current!) { (gyroData, error) in
                self.gyrX = gyroData?.rotationRate.x ?? 0
                self.gyrY = gyroData?.rotationRate.y ?? 0
                self.gyrZ = gyroData?.rotationRate.z ?? 0
            }
        }
    }
    
    public func stopUpdateGyro() {
        if (self.motionManager.isGyroActive) {
            self.motionManager.stopGyroUpdates()
        }
    }
    
    public func startUpdateMagnetometer() {
        if (self.motionManager.isMagnetometerAvailable) {
            self.motionManager.magnetometerUpdateInterval = updateInterval
            self.motionManager.startMagnetometerUpdates(to: OperationQueue.current!) { (magData, error) in
                self.magX = magData?.magneticField.x ?? 0
                self.magY = magData?.magneticField.y ?? 0
                self.magZ = magData?.magneticField.z ?? 0
            }
        }
    }
    
    public func stopUpdateMagnetometer() {
        if (self.motionManager.isMagnetometerActive) {
            self.motionManager.stopMagnetometerUpdates()
        }
    }
    
    public func startUpdateDeviceMotion() {
        if (motionManager.isDeviceMotionAvailable) {
            motionManager.deviceMotionUpdateInterval = updateInterval
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (motion, error) in
                self.graX = motion?.gravity.x ?? 0
                self.graY = motion?.gravity.y ?? 0
                self.graZ = motion?.gravity.z ?? 0
                self.accLinX = motion?.userAcceleration.x ?? 0*9.81
                self.accLinY = motion?.userAcceleration.y ?? 0*9.81
                self.accLinZ = motion?.userAcceleration.z ?? 0*9.81
            })
        }
    }
    
    public func stopUpdateDeviceMotion() {
        if (motionManager.isDeviceMotionAvailable) {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    public func startMotion() {
        startUpdateAccelerometer()
        startUpdateGyro()
        startUpdateMagnetometer()
        startUpdateDeviceMotion()
    }
    
    public func stopMotion() {
        stopUpdateAccelerometer()
        stopUpdateGyro()
        stopUpdateMagnetometer()
        stopUpdateDeviceMotion()
    }
    
    func startRecording(){
        if (timer == nil) {
            timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
            timer?.schedule(deadline: .now(), repeating: 0.01)
            timer?.setEventHandler {
                self.recordIMU()
            }
            timer?.activate()
        }
    }
    
    func recordIMU() {
        var model = TripCSVIMUModel.init()
        
        model.accX = String(self.accX ?? 0)
        model.accY = String(self.accY ?? 0)
        model.accZ = String(self.accZ ?? 0)
        
        model.gyrX = String(self.gyrX ?? 0)
        model.gyrY = String(self.gyrY ?? 0)
        model.gyrZ = String(self.gyrZ ?? 0)
        
        model.magX = String(self.magX ?? 0)
        model.magY = String(self.magY ?? 0)
        model.magZ = String(self.magZ ?? 0)
        
        model.graX = String(self.graX ?? 0)
        model.graY = String(self.graY ?? 0)
        model.graZ = String(self.graZ ?? 0)
        
        model.accLinX = String(self.accLinX ?? 0)
        model.accLinY = String(self.accLinY ?? 0)
        model.accLinZ = String(self.accLinZ ?? 0)

        dataManager.appendIMUCSV(model: model)
    }
    
    func stopRecording(){
        if (timer != nil) {
            timer?.cancel()
            timer = nil
        }
    }
}

