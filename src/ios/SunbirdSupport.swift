import Foundation
import CommonCrypto

let SUPPORT_FILE: String = "_support.txt"
let CONFIG_FILE: String = ".txt"
let SUPPORT_DIRECTORY: String = "support"
let DIRECTORY_NAME_SEPERATOR: String = "-"
let SEPERATOR: String = "~"

enum CryptoAlgorithm {
    case SHA256
    var HMACAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .SHA256:   result = kCCHmacAlgSHA256
        }
        return CCHmacAlgorithm(result)
    }
    
    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    func hmac(algorithm: CryptoAlgorithm, key: String) -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = Int(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = algorithm.digestLength
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        let keyStr = key.cString(using: String.Encoding.utf8)
        let keyLen = Int(key.lengthOfBytes(using: String.Encoding.utf8))
        CCHmac(algorithm.HMACAlgorithm, keyStr!, keyLen, str!, strLen, result)
        let digest = stringFromResult(result: result, length: digestLen)
        result.deallocate(capacity: digestLen)
        return digest
    }
    
    private func stringFromResult(result: UnsafeMutablePointer<CUnsignedChar>, length: Int) -> String {
        let hash = NSMutableString()
        for i in 0..<length {
            hash.appendFormat("%02x", result[i])
        }
        return String(hash).lowercased()
    }
    
    func convertToBase64URL() -> String {
        let inputString = self
        let utf8str = inputString.data(using: .utf8)
        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            return base64Encoded
        }
        return inputString
    }
}

class DeviceSpec {
    static func getDeviceId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    static func getDeviceModel() -> String {
        return UIDevice.current.model
    }
    
    static func getDeviceMaker() -> String {
        return UIDevice.current.name
    }
    
    static func getDeviceOSVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    static func getFileSize(for key: FileAttributeKey) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard
            let lastPath = paths.last,
            let attributeDictionary = try? FileManager.default.attributesOfFileSystem(forPath: lastPath) else { return "0" }
        
        if let size = attributeDictionary[key] as? NSNumber {
            return String(size.int64Value)
        } else {
            return "0"
        }
    }
    
    static func getScreenResolution() -> String {
        let screen = UIScreen.main
        let width = screen.bounds.size.width
        let height = screen.bounds.size.height
        return width.description + "x" + height.description
    }
    
    static func getDeviceDataString(_ configDictionary: [String: String]) -> String {
        let userCount = configDictionary["userCount"] ?? "0"
        let localContentCount = configDictionary["localContentCount"] ?? "0"
        let supportFileVersionHistory = configDictionary["supportFileVersionHistory"] ?? ""
        let deviceId = self.getDeviceId()
        let deviceData: [String: String] = [
            "did:": deviceId,
            "mdl:": self.getDeviceModel(),
            "mak:": self.getDeviceMaker(),
            "cwv:": "",
            "uno:": userCount,
            "cno:": localContentCount,
            "dos:": self.getDeviceOSVersion(),
            "wv:": "",
            "res:": self.getScreenResolution(),
            "dpi:": "",
            "tsp:": self.getFileSize(for: .systemSize),
            "fsp:": self.getFileSize(for: .systemFreeSize),
            "ts:": String(Int64(Date().timeIntervalSince1970.rounded() * 1000))
        ]
        
        var configString =  deviceData.reduce("", { (accumulator: String, keyValue: (String, String)) -> String in
            return accumulator + "\(keyValue.0)\(keyValue.1)||"
        })
        
        let checkSum = configString.hmac(algorithm: .SHA256, key: deviceId)
        let base64EncodedCheckSum = checkSum.convertToBase64URL()
        configString = configString + "csm:\(base64EncodedCheckSum)||sv:\(supportFileVersionHistory)"
        return configString
    }
}

@objc(SunbirdSupport) class SunbirdSupport : CDVPlugin {
    
    private var bundleInfoDictionary: [String: Any]?
    
    override func pluginInitialize() {
        print(DIRECTORY_NAME_SEPERATOR)
        print(SUPPORT_FILE)
        if let bundleInfoDictionary = Bundle.main.infoDictionary {
            self.bundleInfoDictionary = bundleInfoDictionary
        }
    }
    
    private func checkIfPathExists(_ filePath: String, _ isDir: UnsafeMutablePointer<ObjCBool>) -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath, isDirectory: isDir)
    }
    
    private func readFromFile(_ fileURL: URL) throws -> String {
        do {
            let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
            return fileContents
        } catch let error {
            print("error reading from the file \(error)")
            throw error
        }
    }
    
    private func writeToFile(_ fileURL: URL, _ text: String) throws {
        try text.write(to: fileURL, atomically: false, encoding: .utf8)
    }
    
    private func createSupportDirectory(_ supportDirectoryPath: String) throws -> URL {
        do {
            let fileManager = FileManager.default
            let applicationDir = try fileManager.url(for: .applicationDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let supportDir = applicationDir.appendingPathComponent(supportDirectoryPath)
            var isDirectory: ObjCBool = true
            if !self.checkIfPathExists(supportDir.path, &isDirectory) {
                try fileManager.createDirectory(atPath: supportDir.path,withIntermediateDirectories: true, attributes: nil)
            }
            return supportDir
        } catch let error {
            throw error
        }
    }
    
    @objc
    func supportfile(_ command: CDVInvokedUrlCommand) {
        let functionNameToInvoke = command.arguments[0] as! String
        if functionNameToInvoke == "makeEntryInSunbirdSupportFile" {
            self.makeEntryInSunbirdSupportFile(command)
        } else if functionNameToInvoke == "shareSunbirdConfigurations" {
            self.shareSunbirdConfigurations(command)
        } else if functionNameToInvoke == "removeFile" {
            self.removeFile(command)
        }
    }
    
    @objc
    func makeEntryInSunbirdSupportFile(_ command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        if let bundleInfoDictionary = self.bundleInfoDictionary {
            if let appName = bundleInfoDictionary["CFBundleName"] as? String, let appFlavour = bundleInfoDictionary["FLAVOR"] as? String, let appVersion = bundleInfoDictionary["CFBundleShortVersionString"] as? String {
                do {
                    let pathComponent = appName + DIRECTORY_NAME_SEPERATOR + appFlavour + DIRECTORY_NAME_SEPERATOR + SUPPORT_DIRECTORY
                    let supportDir = try self.createSupportDirectory(pathComponent)
                    let supportFilePath = supportDir.appendingPathComponent(appName + DIRECTORY_NAME_SEPERATOR + appFlavour + SUPPORT_FILE)
                    let currentTimeInMilliseconds = String(Int64(Date().timeIntervalSince1970.rounded() * 1000))
                    var entryToFile = appVersion + SEPERATOR + currentTimeInMilliseconds +  SEPERATOR + "1"
                    var isDirectory: ObjCBool = false
                    if self.checkIfPathExists(supportFilePath.path, &isDirectory) {
                        let fileContents = try self.readFromFile(supportFilePath)
                        var lines = fileContents.split(separator:"\n")
                        if let lastEntry = lines.last {
                            let partsOfLastLine = lastEntry.split(separator: Character(SEPERATOR))
                            if partsOfLastLine.indices.contains(0) && appVersion.lowercased().elementsEqual(partsOfLastLine[0].lowercased()){
                                lines.remove(at: lines.count - 1)
                                let previousCount = partsOfLastLine.indices.contains(2) ? String(partsOfLastLine[2]) : "0"
                                let count = String((Int(previousCount) ?? 0) + 1)
                                let timeStamp = partsOfLastLine.indices.contains(1) ? String(partsOfLastLine[1]) : currentTimeInMilliseconds
                                entryToFile = appVersion + SEPERATOR + timeStamp +  SEPERATOR + count
                            }
                        }
                        try self.writeToFile(supportFilePath, entryToFile)
                    } else {
                        let fileManager = FileManager.default
                        fileManager.createFile(atPath: supportFilePath.path, contents: entryToFile.data(using: .utf8), attributes: [:])
                    }
                    pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: supportFilePath.path)
                } catch let error {
                    print("Error while making entry in Sunbird Support File \(error)")
                }
            }
        }
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc
    func shareSunbirdConfigurations(_ command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        let usersCount = command.arguments.indices.contains(1) ? command.arguments[1] as! NSNumber : 0
        let localContentCount = command.arguments.indices.contains(2) ? command.arguments[2] as! NSNumber: 0
        if let bundleInfoDictionary = self.bundleInfoDictionary {
            if let appName = bundleInfoDictionary["CFBundleName"] as? String, let appFlavour = bundleInfoDictionary["FLAVOR"] as? String, let appVersion = bundleInfoDictionary["CFBundleShortVersionString"] as? String {
                do {
                    let pathComponent = appName + DIRECTORY_NAME_SEPERATOR + appFlavour + DIRECTORY_NAME_SEPERATOR + SUPPORT_DIRECTORY
                    let supportDir = try self.createSupportDirectory(pathComponent)
                    let currentTimeInMilliseconds = String(Int64(Date().timeIntervalSince1970.rounded() * 1000))
                    let deviceId = DeviceSpec.getDeviceId()
                    let configFilePath = supportDir.appendingPathComponent("Details_" + deviceId + "_" + currentTimeInMilliseconds + CONFIG_FILE)
                    let supportFilePath = supportDir.appendingPathComponent(appName + DIRECTORY_NAME_SEPERATOR + appFlavour + SUPPORT_FILE)
                    var supportFileVersionHistory = ""
                    var isDirectory: ObjCBool = false
                    if self.checkIfPathExists(supportFilePath.path, &isDirectory) {
                        let fileContents = try self.readFromFile(supportFilePath)
                        let lines = fileContents.split(separator:"\n")
                        supportFileVersionHistory = lines.joined(separator: ",")
                    }
                    let input: [String: String] = ["userCount": usersCount.stringValue, "localContentCount": localContentCount.stringValue, "supportFileVersionHistory": supportFileVersionHistory]
                    let firstEntry = appVersion + SEPERATOR + currentTimeInMilliseconds +  SEPERATOR + "1"
                    let configString = DeviceSpec.getDeviceDataString(input)
                    let sharedData = configString + "," + firstEntry
                    FileManager.default.createFile(atPath: configFilePath.path, contents: sharedData.data(using: .utf8), attributes: [:])
                    pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs:configFilePath.path)
                } catch let error {
                    print("Error while sharing Sunbird Configuration \(error)")
                }
            }
        }
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc
    func removeFile(_ command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        let fileManager = FileManager.default
        if let bundleInfoDictionary = self.bundleInfoDictionary {
            if let appName = bundleInfoDictionary["CFBundleName"] as? String, let appFlavor = bundleInfoDictionary["FLAVOR"] as? String {
                do {
                    let applicationDir = try fileManager.url(for: .applicationDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let pathComponent = appName + DIRECTORY_NAME_SEPERATOR + appFlavor + DIRECTORY_NAME_SEPERATOR + SUPPORT_DIRECTORY
                    let supportFilesDirectoryPath =  applicationDir.appendingPathComponent(pathComponent, isDirectory: true)
                    let fileURLs = try fileManager.contentsOfDirectory(at: supportFilesDirectoryPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    for url in fileURLs {
                        if url.lastPathComponent.starts(with: "Details_") {
                            try fileManager.removeItem(at: url)
                        }
                    }
                    pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK)
                } catch let error {
                    print("Error while removing support file \(error)")
                }
            }
        }
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
}
