//
//  DriveManager.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/5.
//

import SwiftUI
import Combine
import AVFoundation
import UIKit

class DriveManager : NSObject{
    
    var isRecording: Bool = false
    var isStartRecording: Bool = false
    var isStartSensors: Bool = false
//    var isRecordingNoCamera: Bool = false
    var recordingState: RecordingState = RecordingState.STILL
    var recordingPage: RecordingState = RecordingState.STILL
    var isAutoStop: Bool = true
    var batteryStatus: BatteryStatus = BatteryStatus.normal
    var thermalState: ProcessInfo.ThermalState = ProcessInfo.ThermalState.nominal

    private var cameraManager = CameraManager.shared
    private var gpsManager = GPSManager.shared
    private var imuManager = IMUManager.shared
    private var activityManager = ActivityManager.shared
//    private var appManager = AppManager.shared
    private var phoneEventManager = PhoneEventManager.shared
    private var batteryManager = BatteryManager.shared
    private var thermalManager = ThermalManager.shared
    private var dataManager = DataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var suppressDangerAlertsUntil: Date?
    
    private var stillJob: DispatchWorkItem?
    private var lastActivity: ActivityType = .still
    
    static let shared = DriveManager()
    
    public var delegate: GizoAnalysisDelegate?
    var gizoOption = GizoCommon.shared.options
    
    func initialVideoCapture(){
        
        let videoSetting = self.gizoOption?.videoSetting
        if((videoSetting?.allowRecording != nil && videoSetting?.allowRecording ?? false)){
            startCamera()
        }
        
        let userActivitySetting = gizoOption?.userActivitySetting
        if (userActivitySetting?.allowUserActivity != nil && (userActivitySetting?.allowUserActivity)!) {
            setupActivityProcessing()
        }
        
         let gpsSetting = gizoOption?.gpsSetting
         if (gpsSetting?.allowGps != nil && (gpsSetting?.allowGps)!) {
             setupGPSProcessing()
         }
        
        let imuSetting = gizoOption?.imuSetting
        if ((imuSetting?.allowAccelerationSensor != nil && (imuSetting?.allowAccelerationSensor)!) ||
            (imuSetting?.allowGyroscopeSensor != nil && (imuSetting?.allowGyroscopeSensor)!) ||
            (imuSetting?.allowMagneticSensor != nil && (imuSetting?.allowMagneticSensor)!)) {
            
            setupIMUProcessing()
        }
        
        let batterySetting = gizoOption?.batterySetting
        if (batterySetting?.checkBattery != nil && (batterySetting?.checkBattery)!) {
            setupBatteryProcessing()
        }
        if (batterySetting?.checkThermal != nil && (batterySetting?.checkThermal)!) {
            setupThermalProcessing()
        }
        
        isStartSensors = true
    }
    
    func stopVideoCapture(){
        stopCamera()
        stopSensors()
    }
    
    func startRecording() {
        startRecordingCamera()
    }
    
    
    func attachPreview(previewView: UIView){
        preview(to: previewView)
    }
    
    
    func lockPreview(){
        self.cameraManager.previewLayer?.isHidden = true
    }
    
    
    func unlockPreview(previewView: UIView?){
        self.cameraManager.previewLayer?.isHidden = false
    }
    
    func startInitSensors(){
        setupActivityProcessing()
        setupGPSProcessing()
    }
    
    func startCamera(){
        cameraManager.checkPermissionsAndSetupSession()

        setupCameraProcessing()
        
        if !isStartSensors{
            startSensors()
        }
    
    }
    
    func startNoCamera(){
        if !isStartSensors{
            startSensors()
        }
    }
    
    func startSensors(){
        setupIMUProcessing()
        setupBatteryProcessing()
        setupThermalProcessing()
        isStartSensors = true
    }
    
    func stopCamera(){
        stopSession()
        
        if isRecording {
            stopRecording()
        }
        
        if !isRecording {
            stopSensors()
        }
    }
    
    func stopSensors(){
//        if isRecording {
//            stopRecording()
//        }
//        gpsManager.stopGPS()
        imuManager.stopMotion()
//        activityManager.stopUpdateMotionActivity()
        batteryManager.stopBatteryStatus()
        thermalManager.stopThermalState()
        
        isStartSensors = false
    }
    
    func stopAllSensors(){
        stopSensors()
        gpsManager.stopGPS()
        activityManager.stopUpdateMotionActivity()
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer? {
        cameraManager.previewLayer
    }
    
    func setupCameraProcessing() {
        cameraManager.delegate = self.delegate
//        cameraManager.ttcAlertPublisher
//            .receive(on: RunLoop.main)
//            .sink { [weak self] alert in
//                guard let self = self else { return }
//
//                self.handleTTCAlert(alert)
//            }
//            .store(in: &cancellables)
//        
        startSession()
    }
    
    func setupGPSProcessing() {
        gpsManager.delegate = self.delegate
        gpsManager.locationUpdatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] locationModel in
                self?.handleLocationUpdate(locationModel)
            }
            .store(in: &cancellables)
        
        gpsManager.startLocationWithAuth(inUse: false)
    }
    
    func setupIMUProcessing() {
        imuManager.delegate = self.delegate
        imuManager.orientationUpdatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isHiddenOrientationCover in
                self?.handleOrientationScreen(isHiddenOrientationCover)
            }
            .store(in: &cancellables)
        
        imuManager.startMotion()
    }
    
    func setupActivityProcessing() {
        activityManager.delegate = self.delegate

        activityManager.activityTypePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] activityTpe in
                self?.onUserActivityTransitionChange(activityTpe)
            }
            .store(in: &cancellables)
        
        activityManager.startUpdateMotionActivity()
    }
    
    func setupBatteryProcessing() {
        batteryManager.delegate = self.delegate
        batteryManager.batteryStatusPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] batteryStatus in
                self?.handleBatteryStatusDidChange(batteryStatus)
            }
            .store(in: &cancellables)
        
//        batteryManager.batteryStatusNoCameraPublisher
//            .receive(on: RunLoop.main)
//            .sink { [weak self] batteryStatus in
//                self?.handleBatteryStatusNoCameraDidChange(batteryStatus)
//            }
//            .store(in: &cancellables)
        
        batteryManager.startBatteryStatus()
    }
    
    func setupThermalProcessing() {
        thermalManager.delegate = self.delegate
        thermalManager.thermalStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] thermalState in
                self?.handleThermalStateDidChange(thermalState)
            }
            .store(in: &cancellables)
        
        thermalManager.startThermalState()
    }
    
    private func handleLocationUpdate(_ locationModel: LocationModel) {
//        uiState.speedNotSafe = gpsManager.isSpeedOver
//        uiState.speed = Int(locationModel.speed ?? 0)
//        uiState.limitSpeed = Int(locationModel.speedLimit ?? 0)
    }
    
//    private func handleTTCAlert(_ alert: TTCAlert) {
//        switch alert {
//            case .none:
//                break
//
//            case .warning:
//                displayWarning()
//
//            case .danger:
//                displayDanger()
//        }
//    }
    
//    private func displayWarning() {
//        guard !uiState.warning else { return }
//        
//        uiState.warning = true
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.uiState.warning = false
//        }
//    }

//    private func displayDanger() {
//        guard !isDangerAlert, Date() >= (suppressDangerAlertsUntil ?? Date()) else { return }
//        
//        isDangerAlert = true
//        suppressDangerAlertsUntil = Date().addingTimeInterval(15)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.isDangerAlert = false
//        }
//    }
    
    private func handleOrientationScreen(_ isHiddenOrientationCover: Bool) {
//        if hiddenOrientationCover {
//            return
//        }
//        hiddenOrientationCover = isHiddenOrientationCover
    }
    
    private func handleBatteryStatusDidChange(_ batteryStatus: BatteryStatus) {
        self.batteryStatus = batteryStatus
        if batteryStatus != BatteryStatus.normal{
        }
        if isRecording == true && batteryStatus == BatteryStatus.stop {
//            uiState.isShowBatteryDialog = true
//            cameraManager.disableAi()
            stopRecording()
        }else if batteryStatus == BatteryStatus.stop {
//            cameraManager.disableAi()
        }
        else if batteryStatus == BatteryStatus.warning {
//            cameraManager.disableAi()
        }else if batteryStatus == BatteryStatus.normal {
            if thermalState != ProcessInfo.ThermalState.serious {
//                cameraManager.enableAi()
            }
        }
    }
    
//    private func handleBatteryStatusNoCameraDidChange(_ batteryStatus: BatteryStatusNoCamera) {
//        self.batteryStatusNoCamera = batteryStatus
//        if batteryStatus != BatteryStatusNoCamera.normal{
//        }
//        if uiStateNoCamera.isRecording == true && batteryStatus == BatteryStatusNoCamera.stop {
//            if isAutoStop == true {
//                uiState.isShowBatteryDialog = true
//                stopRecording()
//            }
//        }else if batteryStatus == BatteryStatusNoCamera.stop {
//        }
//        else if batteryStatus == BatteryStatusNoCamera.warning {
//        }else if batteryStatus == BatteryStatusNoCamera.normal {
//        }
//        
//    }
    
    private func handleThermalStateDidChange(_ thermalState: ProcessInfo.ThermalState) {
        self.thermalState = thermalState
        if thermalState != .nominal{
        }
        if (isRecording) && thermalState == ProcessInfo.ThermalState.serious {
//            uiState.isShowThermalDialog = true
//            cameraManager.disableAi()
            stopRecording()
        } else if thermalState == ProcessInfo.ThermalState.serious {
//            cameraManager.disableAi()
        }else{
            if batteryStatus == BatteryStatus.normal{
//                cameraManager.enableAi()
            }
        }
    }

    func preview(to view: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let previewLayer = self.cameraManager.previewLayer else { return }
            previewLayer.frame = view.bounds
            self.adjustPreviewLayerOrientation(previewLayer)
            if previewLayer.superlayer == nil {
                view.layer.addSublayer(previewLayer)
            }
//            self.uiState.isPreviewAttached = true
        }
    }

    private func adjustPreviewLayerOrientation(_ previewLayer: AVCaptureVideoPreviewLayer) {
        if let previewConnection = previewLayer.connection, previewConnection.isVideoOrientationSupported {
            previewConnection.videoOrientation = .landscapeRight
        }
    }
    
//    func togglePreviewVisibility() {
//        uiState.isPreviewAttached.toggle()
//        isPreviewVisible.toggle()
//    }

    func startSession() {
        cameraManager.startSession()
//        isSessionRunning = true
    }

    func stopSession() {
        cameraManager.stopSession()
//        isSessionRunning = false
    }
    
    func checkBatteryStatus() -> Bool{
        if batteryStatus == BatteryStatus.stop {
//            uiState.isShowBatteryDialog = true
//            cameraManager.disableAi()
            return false
        }else if batteryStatus == BatteryStatus.warning {
//            cameraManager.disableAi()
            return true
        }else{
            return true
        }
    }
    
    func checkThermalState() -> Bool{
        if thermalState == ProcessInfo.ThermalState.serious {
//            uiState.isShowThermalDialog = true
//            uiStateNoCamera.isShowThermalDialog = true
//            cameraManager.disableAi()
            return false
        }else{
            return true
        }
    }
    
    func startRecordingCamera() {
        if !checkBatteryStatus() {
            return
        }
        
        if !checkThermalState() {
            return
        }
        
        if isRecording {
            isStartRecording = true
            stopRecording()
        }

        recordingState = RecordingState.Full
        let infoDect: [String : Any] = ["TripType": TripType.Full.rawValue]

        dataManager.createTripFolder(rootName: gizoOption?.folderName)
        dataManager.createLockFile()
        isRecording = true
        dataManager.saveTXT(fileName: Constants.infoFileName, text: dataManager.dict2JsonStr(dict: infoDect as NSDictionary) ?? "")
        let videoSetting = gizoOption?.videoSetting
        if (videoSetting?.allowRecording != nil && (videoSetting?.allowRecording)!) {
            cameraManager.startRecording(to: dataManager.folderPath!)
        }
        let gpsSetting = gizoOption?.gpsSetting
        if (gpsSetting?.allowGps != nil && (gpsSetting?.allowGps)!) {
            dataManager.createGPSCSV()
            gpsManager.startRecording()
        }
        let imuSetting = gizoOption?.imuSetting
        if ((imuSetting?.allowAccelerationSensor != nil && (imuSetting?.allowAccelerationSensor)!) ||
            (imuSetting?.allowGyroscopeSensor != nil && (imuSetting?.allowGyroscopeSensor)!) ||
            (imuSetting?.allowMagneticSensor != nil && (imuSetting?.allowMagneticSensor)!)) {
            dataManager.createIMUCSV()
            imuManager.startRecording()
        }
        let userActivitySetting = gizoOption?.userActivitySetting
        if (userActivitySetting?.saveCsvFile != nil && (userActivitySetting?.saveCsvFile)!) {
            dataManager.createActivityCSV()
            activityManager.startRecording()
        }
        dataManager.createAppCSV()
        //        appManager.startRecording()
        let phoneEventSetting = gizoOption?.phoneEventSetting
        if (phoneEventSetting?.saveCsvFile != nil && (phoneEventSetting?.saveCsvFile)!) {
            dataManager.createPhoneEventCSV()
            phoneEventManager.startRecording()
        }
    }
    
    func startRecordingNoCamera(autoStop: Bool = true) {
        self.isAutoStop = autoStop

        if autoStop == true {
            if !checkBatteryStatus() {
                return
            }
        }
        
        if !checkThermalState() {
            return
        }
        
        if isRecording {
            isStartRecording = true
            stopRecording()
        }

        recordingState = RecordingState.NoCamera
        
        let infoDect = ["TripType": TripType.ImuGps.rawValue] as [String : Any]
        dataManager.createTripFolder(rootName: gizoOption?.folderName)
        dataManager.createLockFile()
//        uiStateNoCamera.isRecording = true
//        uiStateNoCamera.startTimeNoCamera = Date()
        isRecording = true
        dataManager.saveTXT(fileName: Constants.infoFileName, text: dataManager.dict2JsonStr(dict: infoDect as NSDictionary) ?? "")
        let gpsSetting = gizoOption?.gpsSetting
        if (gpsSetting?.allowGps != nil && (gpsSetting?.allowGps)!) {
            dataManager.createGPSCSV()
            gpsManager.startRecording()
        }
        let imuSetting = gizoOption?.imuSetting
        if ((imuSetting?.allowAccelerationSensor != nil && (imuSetting?.allowAccelerationSensor)!) ||
            (imuSetting?.allowGyroscopeSensor != nil && (imuSetting?.allowGyroscopeSensor)!) ||
            (imuSetting?.allowMagneticSensor != nil && (imuSetting?.allowMagneticSensor)!)) {
            dataManager.createIMUCSV()
            imuManager.startRecording()
        }
        let userActivitySetting = gizoOption?.userActivitySetting
        if (userActivitySetting?.saveCsvFile != nil && (userActivitySetting?.saveCsvFile)!) {
            dataManager.createActivityCSV()
            activityManager.startRecording()
        }
        dataManager.createAppCSV()
        //        appManager.startRecording()
        let phoneEventSetting = gizoOption?.phoneEventSetting
        if (phoneEventSetting?.saveCsvFile != nil && (phoneEventSetting?.saveCsvFile)!) {
            dataManager.createPhoneEventCSV()
            phoneEventManager.startRecording()
        }
    }

    func startRecordingBackground() {
        if isRecording {
            isStartRecording = true
            stopRecording()
        }
        recordingState = RecordingState.Background
        let infoDect = ["TripType": TripType.Imu.rawValue] as [String : Any]

        dataManager.createTripFolder(rootName: gizoOption?.folderName)
        dataManager.createLockFile()
        isRecording = true
        dataManager.saveTXT(fileName: Constants.infoFileName, text: dataManager.dict2JsonStr(dict: infoDect as NSDictionary) ?? "")
        let gpsSetting = gizoOption?.gpsSetting
        if (gpsSetting?.allowGps != nil && (gpsSetting?.allowGps)!) {
            dataManager.createGPSCSV()
            gpsManager.startRecording()
        }
        let imuSetting = gizoOption?.imuSetting
        if ((imuSetting?.allowAccelerationSensor != nil && (imuSetting?.allowAccelerationSensor)!) ||
            (imuSetting?.allowGyroscopeSensor != nil && (imuSetting?.allowGyroscopeSensor)!) ||
            (imuSetting?.allowMagneticSensor != nil && (imuSetting?.allowMagneticSensor)!)) {
            dataManager.createIMUCSV()
            imuManager.startRecording()
        }
        let userActivitySetting = gizoOption?.userActivitySetting
        if (userActivitySetting?.saveCsvFile != nil && (userActivitySetting?.saveCsvFile)!) {
            dataManager.createActivityCSV()
            activityManager.startRecording()
        }
        dataManager.createAppCSV()
        //        appManager.startRecording()
        let phoneEventSetting = gizoOption?.phoneEventSetting
        if (phoneEventSetting?.saveCsvFile != nil && (phoneEventSetting?.saveCsvFile)!) {
            dataManager.createPhoneEventCSV()
            phoneEventManager.startRecording()
        }
    }
    
    func stopRecording() {
        isRecording = false
        
        if recordingState == RecordingState.Full {
            cameraManager.stopRecording()
//            cameraManager.stopRecordingTTC()
        }

        gpsManager.stopRecording()
        imuManager.stopRecording()
        activityManager.stopRecording()
//        appManager.stopRecording()
        phoneEventManager.stopRecording()
        dataManager.removeLockFile()
        recordingState = RecordingState.STILL
        if !isStartRecording {
            if lastActivity == .in_vehicle {
                stillPauseCancel()
                notifyInVehicle()
            } else if lastActivity != .still {
                stillPauseCancel()
                changeRecordState(to: .Background)
            }
        }
        
        isStartRecording = false
    }

    func onUserActivityTransitionChange(_ activityType: ActivityType) {
        var currentActivityType = activityType
        if activityType == ActivityType.still || activityType == ActivityType.unknown {
            currentActivityType = ActivityType.still
        }
        let isNewTransition = currentActivityType != lastActivity

        switch recordingState {
           case .STILL:
               if !isNewTransition { return }

            if currentActivityType == .in_vehicle {
                   stillPauseCancel()
                   notifyInVehicle()
               } else if currentActivityType != .still {
                   stillPauseCancel()
                   changeRecordState(to: .Background)
               }

           case .Background:
               if !isNewTransition { return }

               if currentActivityType == .in_vehicle {
                   stillPauseCancel()
                   notifyInVehicle()
               } else if currentActivityType == .still {
                   stillPauseStart(shortDuration: true) { [weak self] in
                       guard let self = self else { return }
                       if lastActivity == .still {
                           changeRecordState(to: .STILL)
                       }
                   }
               } else {
                   stillPauseCancel()
               }

           case .NoCamera:
               if !isNewTransition { return }

               if currentActivityType == .in_vehicle {
                   stillPauseCancel()
               } else if currentActivityType != .in_vehicle {
                   if !isStillPauseRunning() {
                       if currentActivityType == .still {
                           stillPauseStart(shortDuration: false) { [weak self] in
                               guard let self = self else { return }
                               if lastActivity == .still {
                                   changeRecordState(to: .STILL)
                               } else {
                                   changeRecordState(to: .Background)
                               }
                           }
                       } else {
                           stillPauseStart(shortDuration: true) { [weak self] in
                               guard let self = self else { return }
                               if lastActivity == .still {
                                   changeRecordState(to: .STILL)
                               } else {
                                   changeRecordState(to: .Background)
                               }
                           }
                       }
                   }
               }

           default: break
           }

        lastActivity = currentActivityType
    }

    func changeRecordState(to newRecordingState: RecordingState? = nil) {
        if isStartSensors {
            stopSensors()
        }

        switch newRecordingState {
            case nil:
                if lastActivity == ActivityType.still {
                    changeRecordState(to: RecordingState.STILL)
                } else {
                    changeRecordState(to: RecordingState.Background)
                }
            case .STILL:
                if isRecording {
                    stopRecording()
                }
            case .Background:
                recordingState = RecordingState.Background
                if !isStartSensors {
                    startSensors()
                }
                startRecordingBackground()
            case .NoCamera:
                recordingState = RecordingState.NoCamera
                if !isStartSensors {
                    startSensors()
                }
                startRecordingNoCamera(autoStop: false)
            default:
                break
        }
    }

    private func notifyInVehicle() {
        changeRecordState(to: .NoCamera)
    }

    private func stillPauseCancel() {
        stillJob?.cancel()
        stillJob = nil
    }

    private func stillPauseStart(shortDuration: Bool = false, onDone: @escaping () -> Void) {
        stillPauseCancel()
        let workItem = DispatchWorkItem { onDone() }
        DispatchQueue.main.asyncAfter(deadline: .now() + (shortDuration ? 30 : 5 * 60), execute: workItem)
        stillJob = workItem
    }

    private func isStillPauseRunning() -> Bool {
        stillJob?.isCancelled == false
    }
}



