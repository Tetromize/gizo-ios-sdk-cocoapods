//
//  GPSManager.swift
//  Gizo
//
//  Created by Meysam Farmani on 2/22/24.
//

import Foundation
import MapboxCoreNavigation
import MapboxNavigation
import CoreLocation
import Combine

class GPSManager: NSObject, PassiveLocationManagerDelegate {
    public var locationModel: LocationModel?
    public var isSpeedOver: Bool = false
    private var timer: DispatchSourceTimer?
    
    private let passiveLocationManager = PassiveLocationManager()
    private lazy var passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
    private var isInUse: Bool = true
    var locationUpdatePublisher = PassthroughSubject<LocationModel, Never>()
    
    private var dataManager = DataManager.shared
    
    static let shared = GPSManager()
    
    override init() {
        super.init()
        passiveLocationManager.systemLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        passiveLocationManager.systemLocationManager.distanceFilter = kCLDistanceFilterNone
        passiveLocationManager.systemLocationManager.allowsBackgroundLocationUpdates = true
        passiveLocationManager.systemLocationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // Check if the app has authorization to use GPS
    static func checkGPSPermission() -> AuthorizationStatus {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        switch authorizationStatus {
        case .authorizedAlways:
            return .authorizedAlways
        case .authorizedWhenInUse:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        }
    }

    // Request GPS authorization if not determined or denied
    static func requestGPSAuthorization() {
        let locationManager = CLLocationManager()
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func checkSpeedOver() {
        if (self.locationModel?.speed == nil) {
            return
        }
        let speed = self.locationModel?.speed ?? 0
        let speedLimit = self.locationModel?.speedLimit ?? 0
        if (speedLimit > 0 && speed > speedLimit) {
            self.isSpeedOver = true
        }
        else {
            self.isSpeedOver = false
        }
    }
    
    func updateLocation(location: CLLocation) {
        let speed = max(location.speed, 0)
        
        if (self.locationModel == nil) {
            self.locationModel = LocationModel.init()
        }
        self.locationModel?.latitude = location.coordinate.latitude
        self.locationModel?.longitude = location.coordinate.longitude
        self.locationModel?.course = location.course
        self.locationModel?.altitude = location.altitude
        self.locationModel?.speed = round(speed*3.6)
        if let model = self.locationModel {
            locationUpdatePublisher.send(model)
        }
        self.checkSpeedOver()
    }
    public func requestAlwaysAuth() {
        if (passiveLocationProvider.authorizationStatus == .authorizedWhenInUse && !isInUse) {
            passiveLocationManager.systemLocationManager.allowsBackgroundLocationUpdates = true
            passiveLocationManager.systemLocationManager.pausesLocationUpdatesAutomatically = false
            passiveLocationManager.delegate = self
            passiveLocationProvider.requestAlwaysAuthorization()
        }
        startGPS()
    }
    
    public func requestAuth() {
        
        if (passiveLocationProvider.authorizationStatus == .notDetermined) {
            passiveLocationManager.systemLocationManager.allowsBackgroundLocationUpdates = true
            passiveLocationManager.systemLocationManager.pausesLocationUpdatesAutomatically = false
            passiveLocationManager.delegate = self
            passiveLocationProvider.requestAlwaysAuthorization()
        }
        else if (passiveLocationProvider.authorizationStatus == .denied || passiveLocationProvider.authorizationStatus == .restricted) {
            MTAlert.showAlertWithTitle(title: "Tips", message: "Location denied authorization")
        }
        else {
            requestAlwaysAuth()
        }
    }
    
    public func startLocationWithAuth(inUse: Bool=false) {
        isInUse = inUse
        
        if (passiveLocationProvider.authorizationStatus == .notDetermined) {
            if (inUse) {
                passiveLocationProvider.requestWhenInUseAuthorization()
            }
            else {
                passiveLocationManager.systemLocationManager.allowsBackgroundLocationUpdates = true
                passiveLocationManager.systemLocationManager.pausesLocationUpdatesAutomatically = false
                passiveLocationProvider.requestAlwaysAuthorization()
            }
            startGPS()
        }
        else if (passiveLocationProvider.authorizationStatus == .denied || passiveLocationProvider.authorizationStatus == .restricted) {
            MTAlert.showAlertWithTitle(title: "Tips", message: "Location denied authorization")
        }
        else {
            requestAlwaysAuth()
        }
    }
    
    public func startGPS() {
        passiveLocationManager.delegate = self
        passiveLocationProvider.startUpdatingLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdatePassiveLocation), name: Notification.Name.passiveLocationManagerDidUpdate, object: nil)
    }
    
    public func stopGPS() {
        passiveLocationManager.delegate = nil
        passiveLocationProvider.stopUpdatingLocation()
        NotificationCenter.default.removeObserver(self, name: Notification.Name.passiveLocationManagerDidUpdate, object: nil)
    }
    
    func passiveLocationManagerDidChangeAuthorization(_ manager: PassiveLocationManager) {
        
        if (passiveLocationProvider.authorizationStatus == .authorizedWhenInUse) {
            passiveLocationProvider.requestAlwaysAuthorization()
        }
    }
    
    func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
        updateLocation(location: location)
    }
    
    func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateHeading newHeading: CLHeading) {
        
    }
    
    func passiveLocationManager(_ manager: PassiveLocationManager, didFailWithError error: Error) {
        
    }
    
    @objc func didUpdatePassiveLocation(_ notification: Notification) {
        let speedLimitObj = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey]
        if (speedLimitObj != nil) {
            let speedLimit: Measurement<UnitSpeed> = speedLimitObj! as! Measurement<UnitSpeed>
            
            self.locationModel?.speedLimit = speedLimit.value
            if (speedLimit.unit == UnitSpeed.metersPerSecond) {
                self.locationModel?.speedLimit = speedLimit.value*3.6
            }
            self.checkSpeedOver()
        }
        else {
            self.locationModel?.speedLimit = nil
        }
    }
    
    func startRecording(){
        if (timer == nil) {
            timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
            timer?.schedule(deadline: .now(), repeating: 1)
            timer?.setEventHandler {
                self.recordGPS()
            }
            timer?.activate()
        }
    }
    
    func recordGPS() {
        var model = TripCSVGPSModel.init()
        model.altitude = locationModel?.altitude
        model.latitude = locationModel?.latitude
        model.longitude = locationModel?.longitude
        model.speed = locationModel?.speed
        model.course = locationModel?.course
        model.speedLimit = locationModel?.speedLimit
        
        dataManager.appendGPSCSV(model: model)
    }
    
    func stopRecording(){
        if (timer != nil) {
            timer?.cancel()
            timer = nil
        }
    }
}
