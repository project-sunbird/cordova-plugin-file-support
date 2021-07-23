import Foundation


let SUPPORT_FILE: String = "_support.txt"
let CONFIG_FILE: String = ".txt"
let SUPPORT_DIRECTORY: String = "support"
let DIRECTORY_NAME_SEPERATOR: String = "-"
let SEPERATOR: String = "~"

@objc(SunbirdSupport) class SunbirdSupport : CDVPlugin {
    

    private var bundleInfoDictionary: [String: Any]?
    
    override func pluginInitialize() {
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
    
    @objc
    func makeEntryInSunbirdSupportFile(_ command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        if let bundleInfoDictionary = self.bundleInfoDictionary {
            if let _ = Bundle.main.bundleIdentifier, let appName = bundleInfoDictionary["CFBundleName"] as? String, let appFlavour = bundleInfoDictionary["BUILD_TYPE"] as? String, let appVersion = bundleInfoDictionary["CFBundleShortVersionString"] as? String {
                do {
                    let fileManager = FileManager.default
                    let applicationDir = try fileManager.url(for: .applicationDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let pathComponent = appName + DIRECTORY_NAME_SEPERATOR + appFlavour + DIRECTORY_NAME_SEPERATOR + SUPPORT_DIRECTORY
                    let supportDir = applicationDir.appendingPathComponent(pathComponent)
                    var isDirectory: ObjCBool = true
                    if !self.checkIfPathExists(supportDir.path, &isDirectory) {
                        try fileManager.createDirectory(atPath: supportDir.path,
                                                        withIntermediateDirectories: true, attributes: nil)
                    }
                    isDirectory = false
                    let supportFilePath = supportDir.appendingPathComponent(appName + DIRECTORY_NAME_SEPERATOR + appFlavour + SUPPORT_FILE)
                    let currentTimeInMilliseconds = String(Date().timeIntervalSince1970 * 1000)
                    var entryToFile = appVersion + SEPERATOR + currentTimeInMilliseconds +  SEPERATOR + "1"
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
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: [])
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc
    func removeFile(_ command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
        let fileManager = FileManager.default
        if let bundleInfoDictionary = self.bundleInfoDictionary {
            if let appName = bundleInfoDictionary["CFBundleName"] as? String, let buildType = bundleInfoDictionary["BUILD_TYPE"] as? String {
                do {
                    let applicationDir = try fileManager.url(for: .applicationDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let pathComponent = appName + DIRECTORY_NAME_SEPERATOR + buildType + DIRECTORY_NAME_SEPERATOR + SUPPORT_DIRECTORY
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
