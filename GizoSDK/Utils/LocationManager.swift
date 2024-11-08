//
//  LocationManager.swift
//  Gizo
//
//  Created by Hepburn on 2023/9/20.
//

import Foundation
import CoreLocation

public protocol MBLocationManagerDelegate : NSObjectProtocol {
    func didUpdateLocation(model: LocationModel)
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    public var locationModel: LocationModel?
    public var speedLimit: Double = 0
    public var isLocation: Bool = false
    public var isUpdating: Bool = false
    public var isSpeedOver: Bool = false
    public var delegate: MBLocationManagerDelegate!
    
    private let passiveLocationManager = CLLocationManager()
    private var isInUse: Bool = true
    
    static let shared = LocationManager()
    
    override init() {
        super.init()
//        locationManager = CLLocationManager.init()
//        if (CLLocationManager.locationServicesEnabled()) {
//            print("locationServicesEnabled true");
//            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//            self.locationManager.distanceFilter = kCLDistanceFilterNone;
//            self.locationManager.delegate = self;
//        }
//        else {
//            MTAlert.showAlertWithTitle(title: "Tips", message: "Location services not available")
//            print("locationServicesEnabled false");
//        }
    }
    
    func checkSpeedOver() {
        if (self.locationModel == nil || self.locationModel?.speed == nil) {
            return
        }
        let speed = Double((self.locationModel?.speed)!)!
        if (speedLimit > 0 && speed > speedLimit) {
            self.isSpeedOver = true
        }
        else {
            self.isSpeedOver = false
        }
    }
    
    //CLLocationManagerDelegate
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if (locations.count > 0) {
//            let location = locations.last!
//            updateLocation(location: location)
//            let speed = max(location.speed, 0)
//            print("didUpdateLocations \(location.speed) \(location.coordinate.latitude) \(location.coordinate.longitude)")
//            if (self.locationModel == nil) {
//                self.locationModel = LocationModel.init()
//            }
//            self.locationModel!.latitude = location.coordinate.latitude
//            self.locationModel!.longitude = location.coordinate.longitude
//            self.locationModel!.course = location.course
//            self.locationModel!.altitude = location.altitude
//            self.locationModel!.speed = String(Int(round(speed*3.6)))
//            self.checkSpeedOver()
//            self.delegate?.didUpdateLocation(model: self.locationModel!)
//            self.isLocation = true
//        }
//    }
    
    func updateLocation(location: CLLocation) {
        let speed = max(location.speed, 0)
        print("didUpdateLocations \(location.speed) \(location.coordinate.latitude) \(location.coordinate.longitude)")
        if (self.locationModel == nil) {
            self.locationModel = LocationModel.init()
        }
        self.locationModel!.latitude = location.coordinate.latitude
        self.locationModel!.longitude = location.coordinate.longitude
        self.locationModel!.course = location.course
        self.locationModel!.altitude = location.altitude
        self.locationModel!.speedValue = Int(round(speed*3.6))
        self.locationModel!.speed = String(Int(round(speed*3.6)))
        self.checkSpeedOver()
        self.isLocation = true
        self.delegate?.didUpdateLocation(model: self.locationModel!)
    }
    
    public func requestAlwaysAuth() {

    }
    
    public func startLocationWithAuth(inUse: Bool=true) {

    }
    
    public func startLocation() {
       
    }
    
    public func stopLocation() {
      
    }
    
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
        updateLocation(location: location)
    }
}
