import '../CommonCppDartCode/Messages/HyperCubeMessagesCommon_generated.dart';

class PlatformInfo {
  int hyperCubeAppId = HC_APPID_VORTEX;
  String appName = "Vortex";
  String appUUID = "";
  String appInstallUUID = "";
  String systemName = "";
  String userName = "";
  String userId = "";
  String displayName = "";
  String colocatedMatrixIp = "";

  PlatformInfo();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> jdata = {};
    jdata['HyperCubeAppId'] = hyperCubeAppId;
    jdata['AppUUID'] = appUUID;
    jdata['AppInstallUUID'] = appInstallUUID;
    jdata['SystemName'] = systemName;
    jdata['UserName'] = userName;
    jdata['UserId'] = userId;
    jdata['DisplayName'] = displayName;
    jdata['ColocatedMatrixIp'] = displayName;
    return jdata;
  }

  fromJson(Map<String, dynamic> jdata) {
    hyperCubeAppId = jdata["HyperCubeAppId"];
    appUUID = jdata["AppUUID"];
    appInstallUUID = jdata["AppInstallUUID"];
    systemName = jdata['SystemName'];
    userName = jdata['UserName'];
    userId = jdata['UserId'];
    displayName = jdata['DisplayName'];
    displayName = jdata['ColocatedMatrixIp'];
  }
}
