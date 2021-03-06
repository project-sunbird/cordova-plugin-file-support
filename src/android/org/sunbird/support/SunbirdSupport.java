package org.sunbird.support;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;


import org.sunbird.config.BuildConfigUtil;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import java.io.IOException;

/**
 * Created on 4/4/18. shriharsh
 * Edited by Subranil on 31/10/18.
 */
public class SunbirdSupport extends CordovaPlugin {

    private CallbackContext callbackContext;
    private CordovaInterface cordova;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        this.cordova = cordova;
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (args.get(0).equals("makeEntryInSunbirdSupportFile")) {
            this.callbackContext = callbackContext;
            String filePath = null;
            try {
                final String packageName = this.cordova.getActivity().getPackageName();
                PackageInfo packageInfo = this.cordova.getActivity().getPackageManager().getPackageInfo(packageName, 0);
                final String versionName = packageInfo.versionName;
                final String appFlavor = BuildConfigUtil.getBuildConfigValue("org.sunbird.app", "FLAVOR");
                String appName = cordova.getActivity().getString(getIdOfResource(cordova, "_app_name", "string"));
                filePath = SunbirdFileHandler.makeEntryInSunbirdSupportFile(packageName, cordova.getActivity(), versionName, appName,
                        appFlavor);
                callbackContext.success(filePath);
            } catch (PackageManager.NameNotFoundException | IOException e) {
                e.printStackTrace();
                callbackContext.error(filePath);
            }
        }
        if (args.get(0).equals("shareSunbirdConfigurations")) {
            String getUserCount = args.optString(1,"getUserCount");
            String getLocalContentCount = args.optString(2,"getLocalContentCount");
            this.callbackContext = callbackContext;
            String filePath = null;
            try {
                final String packageName = this.cordova.getActivity().getPackageName();
                PackageInfo packageInfo = this.cordova.getActivity().getPackageManager().getPackageInfo(packageName, 0);
                final String versionName = packageInfo.versionName;
                final String appFlavor = BuildConfigUtil.getBuildConfigValue("org.sunbird.app", "FLAVOR");
                String appName = cordova.getActivity().getString(getIdOfResource(cordova, "_app_name", "string"));
                filePath = SunbirdFileHandler.shareSunbirdConfigurations(packageName, versionName, appName, appFlavor,
                        cordova.getContext(), getUserCount, getLocalContentCount);
                callbackContext.success(filePath);
            } catch (PackageManager.NameNotFoundException | IOException e) {
                e.printStackTrace();
                callbackContext.error(filePath);
            }
        }
        if (args.get(0).equals("removeFile")) {
            this.callbackContext = callbackContext;
            final String appFlavor = BuildConfigUtil.getBuildConfigValue("org.sunbird.app", "FLAVOR");
            String appName = cordova.getActivity().getString(getIdOfResource(cordova, "_app_name", "string"));
            SunbirdFileHandler.removeFile(cordova.getActivity(), appName, appFlavor);
        }
        return true;
    }

    private int getIdOfResource(CordovaInterface cordova, String name, String resourceType) {
        return cordova.getActivity().getResources().getIdentifier(name, resourceType,
                cordova.getActivity().getApplicationInfo().packageName);
    }
}