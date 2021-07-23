var exec = require('cordova/exec');

var PLUGIN_NAME = 'supportfile';

var supportfile = {
  makeEntryInSunbirdSupportFile: function (success, error) {
    exec(success, error, PLUGIN_NAME, "makeEntryInSunbirdSupportFile", ["makeEntryInSunbirdSupportFile"]);
  },
  shareSunbirdConfigurations: function (getUserCount, getLocalContentCount, success, error) {
      exec(success, error, PLUGIN_NAME, "shareSunbirdConfigurations", ["shareSunbirdConfigurations", getUserCount, getLocalContentCount]);
  },
  removeFile: function (success, error) {
    exec(success, error, PLUGIN_NAME, "removeFile", ["removeFile"]);
  },
};


module.exports = supportfile;
