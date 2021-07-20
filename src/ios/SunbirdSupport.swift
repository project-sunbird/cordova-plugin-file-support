import Foundation


 @objc(SunbirdSupport) class SunbirdSupport : CDVPlugin { 

    //  Plugin Initializer
    override func pluginInitialize() {
            self.mHandler = []

    }

     @objc
     func makeEntryInSunbirdSupportFile(_ command: CDVInvokedUrlCommand) {
         var pluginResult: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR)
          pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: [])
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
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: [])
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
     }

 }