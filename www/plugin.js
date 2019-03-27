var exec = require('cordova/exec');

var PLUGIN_NAME = 'supportfile';

var supportfile = {
  makeEntryInSunbirdSupportFile: function (success, error) {
    exec(success, error, PLUGIN_NAME, PLUGIN_NAME, ["makeEntryInSunbirdSupportFile"]);
  },
  shareSunbirdConfigurations: function (getUserCount, getLocalContentCount, success, error) {
      exec(success, error, PLUGIN_NAME, PLUGIN_NAME, ["shareSunbirdConfigurations", getUserCount, getLocalContentCount]);
  },
  removeFile: function (success, error) {
    exec(success, error, PLUGIN_NAME, PLUGIN_NAME, ["removeFile"]);
  },
};


module.exports = supportfile;
