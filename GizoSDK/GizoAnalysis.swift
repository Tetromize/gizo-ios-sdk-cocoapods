//
//  GizoAnalysis.swift
//  GizoSDK
//
//  Created by Hepburn on 2023/12/4.
//

import UIKit

public typealias doneCallback = () -> ()

public class GizoAnalysis: NSObject {
    
    public func start(lifecycleOwner: GizoAnalysisDelegate, onDone: doneCallback?) {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        DriveManager.shared.delegate = lifecycleOwner
        DriveManager.shared.initialVideoCapture()
        if (onDone != nil) {
            onDone!()
        }
    }
    
    public func stop() {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        DriveManager.shared.stopVideoCapture()
        DriveManager.shared.delegate = nil
    }
    
    public func startSavingSession() {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        GizoCommon.shared.isSavingSession = true
        DriveManager.shared.startRecording()
    }
    
    public func stopSavingSession() {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        GizoCommon.shared.isSavingSession = false
        if DriveManager.shared.isRecording {
            DriveManager.shared.stopRecording()
        }
    }
    
    public func attachPreview(preview: UIView) {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        DriveManager.shared.attachPreview(previewView: preview)
    }
    
    public func lockPreview() {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        DriveManager.shared.lockPreview()
    }
    
    public func unlockPreview(preview: UIView?) {
        if (!TokenValidateManager.shared.isValidate) {
            print("Token Invalidate")
            return
        }
        DriveManager.shared.unlockPreview(previewView: preview)
    }
}
