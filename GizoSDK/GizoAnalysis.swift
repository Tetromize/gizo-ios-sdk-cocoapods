//
//  GizoAnalysis.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/4.
//

import UIKit

public typealias doneCallback = () -> ()

public class GizoAnalysis: NSObject {
    var driveManager: DriveManager=DriveManager()
    
    public func start(lifecycleOwner: GizoAnalysisDelegate, onDone: doneCallback?) {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        driveManager.delegate = lifecycleOwner
        driveManager.initialVideoCapture()
        if (onDone != nil) {
            onDone!()
        }
    }
    
    public func stop() {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        driveManager.stopVideoCapture()
        driveManager.delegate = nil
    }
    
    public func startSavingSession() {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        GizoCommon.shared.isSavingSession = true
        driveManager.startRecording()
    }
    
    public func stopSavingSession() {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        GizoCommon.shared.isSavingSession = false
        driveManager.stopRecording()
    }
    
    public func attachPreview(preview: UIView) {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        driveManager.attachPreview(previewView: preview)
    }
    
    public func lockPreview() {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        driveManager.lockPreview()
    }
    
    public func unlockPreview(preview: UIView?) {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        driveManager.unlockPreview(previewView: preview)
    }
}
