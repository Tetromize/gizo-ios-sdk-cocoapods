//
//  ThermalManager.swift
//  Gizo
//
//  Created by Meysam Farmani on 2/23/24.
//

import Foundation
import Combine

class ThermalManager: NSObject {
    
    private var dataManager = DataManager.shared
    var thermalStatePublisher = PassthroughSubject<ProcessInfo.ThermalState, Never>()
    
    public var delegate: GizoAnalysisDelegate?
    static let shared = ThermalManager()
    
    override init() {
        super.init()
    }
    
    func startThermalState(){
        NotificationCenter.default.addObserver(self, selector: #selector(thermalStateDidChange), name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
        thermalStateDidChange()
    }
    
    @objc private func thermalStateDidChange() {
        let thermalState = ProcessInfo.processInfo.thermalState
        thermalStatePublisher.send(thermalState)
        self.delegate?.onThermalStatusChange(state: thermalState)
    }
    
    func stopThermalState() {
        NotificationCenter.default.removeObserver(self)
    }
}
