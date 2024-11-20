import '../CommonCppDartCode/Messages/HyperCubeMessagesCommon_generated.dart';

class SystemInfo {
  int hyperCubeAppId = HC_APPID_VORTEX;
  String appName = "Vortex";
  String appUUID = "";
  String appInstallUUID = "";
  String systemName = "";
  String userName = "";
  String userUUID = "";
  String displayName = "";
  String colocatedMatrixIp = "";

  SystemInfo();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> jdata = {};
    jdata['HyperCubeAppId'] = hyperCubeAppId;
    jdata['AppName'] = appName;
    jdata['AppUUID'] = appUUID;
    jdata['AppInstallUUID'] = appInstallUUID;
    jdata['SystemName'] = systemName;
    jdata['UserName'] = userName;
    jdata['UserUUID'] = userUUID;
    jdata['DisplayName'] = displayName;
    jdata['ColocatedMatrixIp'] = displayName;
    return jdata;
  }

  fromJson(Map<String, dynamic> jdata) {
    hyperCubeAppId = jdata["HyperCubeAppId"];
    appName = jdata["AppName"];
    appUUID = jdata["AppUUID"];
    appInstallUUID = jdata["AppInstallUUID"];
    systemName = jdata['SystemName'];
    userName = jdata['UserName'];
    userUUID = jdata['UserUUID'];
    displayName = jdata['DisplayName'];
    colocatedMatrixIp = jdata['ColocatedMatrixIp'];
  }
}
