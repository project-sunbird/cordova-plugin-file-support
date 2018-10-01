var exec = require('cordova/exec');

var PLUGIN_NAME = 'supportfile';

var supportfile = {
  makeEntryInSunbirdSupportFile: function (success, error) {
    exec(success, error, PLUGIN_NAME, PLUGIN_NAME, ["makeEntryInSunbirdSupportFile"]);
  },
  makeEntryInSunbirdConfiguration: function (success, error) {
    exec(success, error, PLUGIN_NAME, PLUGIN_NAME, ["makeEntryInSunbirdConfiguration"]);
  },
  removeCertainFile: function (success, error) {
    exec(success, error, PLUGIN_NAME, PLUGIN_NAME, ["removeCertainFile"]);
  },
};


module.exports = supportfile;
