//
//  DataManager.swift
//  Gizo

import Foundation

class DataManager {
    var folderPath: URL?
    private var docPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    static let shared = DataManager()

    private init() {}

    func createTripFolder(){
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        let folderName = dateFormatter.string(from: Date())
        let tripFolderURL = documentsDirectory.appendingPathComponent("Trips/\(folderName)")

        do {
            try fileManager.createDirectory(at: tripFolderURL, withIntermediateDirectories: true, attributes: nil)
            self.folderPath = tripFolderURL
        } catch {
            print("Error creating trip folder: \(error)")
        }
    }
    
    func removeDamagedLockFiles(){
        let tripPath = NSString.init(string: docPath).appendingPathComponent("Trips")
        do {
            if (!FileManager.default.fileExists(atPath: tripPath)) {
                return
            }
            var tripFilePaths = try FileManager.default.contentsOfDirectory(atPath: tripPath)
            tripFilePaths = tripFilePaths.sorted()
            
            for dirPath in tripFilePaths {
                var isDirectory: ObjCBool = false
                let path = NSString.init(string: tripPath).appendingPathComponent(dirPath)
                
                let lockPath = NSString.init(string: path).appendingPathComponent("trip.lock")
                if (FileManager.default.fileExists(atPath: lockPath, isDirectory: &isDirectory)) {
                    do {
                        try FileManager.default.removeItem(atPath: lockPath)
                    }
                    catch {
                        
                    }
                }
            }
        } catch {
            print("Faild to remove lock files \(error)")
        }
    }
    
    //Lock
    func createLockFile(fileName: String = Constants.lockFileName) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)
        do {
            try "".write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            
        }
    }
    
    func removeLockFile(fileName: String = Constants.lockFileName) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
        }
        catch {
            
        }
    }
    
    // TXT
    func saveTXT(fileName: String , text: String) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved successfully at \(fileURL)")
        } catch {
            print("Error saving file: \(error)")
        }
    }
    
    //TTC
    func createTTCCSV(fileName: String = Constants.ttcFileName) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        do {
            try TripCSVTTCModel.csvDesc.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {

        }
    }
    
    public func appendTTCCSV(fileName: String = Constants.ttcFileName, model: TripCSVTTCModel) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)
        
        appendCSVLine(in: fileURL, text: model.csvValue)
    }
    
    //GPS
    func createGPSCSV(fileName: String = Constants.gpsFileName) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        do {
            try TripCSVGPSModel.csvDesc.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {

        }
    }
    
    public func appendGPSCSV(fileName: String = Constants.gpsFileName, model: TripCSVGPSModel) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        appendCSVLine(in: fileURL, text: model.csvValue)
    }
    
    //IMU
    func createIMUCSV(fileName: String = Constants.imuFileName) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        do {
            try TripCSVIMUModel.csvDesc.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {

        }
    }
    
    public func appendIMUCSV(fileName: String = Constants.imuFileName, model: TripCSVIMUModel) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        appendCSVLine(in: fileURL, text: model.csvValue)
    }
    
    //Activity
    func createActivityCSV(fileName: String = Constants.actFileName) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        do {
            try TripCSVActivityModel.csvDesc.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {

        }
    }
    
    public func appendActivityCSV(fileName: String = Constants.actFileName, model: TripCSVActivityModel) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        appendCSVLine(in: fileURL, text: model.csvValue)
    }
    
    //App
    func createAppCSV(fileName: String = Constants.appFileName) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        do {
            try TripCSVAppModel.csvDesc.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {

        }
    }
    
    public func appendAppCSV(fileName: String = Constants.appFileName, model: TripCSVAppModel) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        appendCSVLine(in: fileURL, text: model.csvValue)
    }
    
    //PhoneEvent
    func createPhoneEventCSV(fileName: String = Constants.phoneEventsFileName) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        do {
            try TripCSVPhoneModel.csvDesc.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {

        }
    }
    
    public func appendPhoneEventCSV(fileName: String = Constants.phoneEventsFileName, model: TripCSVPhoneModel) {
        let fileURL = self.folderPath!.appendingPathComponent(fileName)

        appendCSVLine(in: fileURL, text: model.csvValue)
    }

    
    private func appendCSVLine(in filePath: URL, text: String) {
        let outFile: FileHandle? = FileHandle.init(forWritingAtPath: filePath.path)
        if (outFile == nil) {
            
        }
        let content = "\n"+text
        outFile?.seekToEndOfFile()
        let buffer = content.data(using: String.Encoding.utf8)
        if buffer != nil {
            outFile?.write(buffer!)
        }
        outFile?.closeFile()
    }
    
    func dict2JsonStr(dict: NSDictionary) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String.init(data: data, encoding: String.Encoding.utf8)
        } catch {
            
        }
        return nil
    }
}
