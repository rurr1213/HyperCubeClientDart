import 'package:flutter/foundation.dart';

import 'CommonCppDartCode/Messages/HyperCubeMessagesCommon_generated.dart';
import 'Data/system_info.dart';

import 'tools/logger.dart';
import 'tools/msg_ext.dart';
import 'hk_client.dart';

import 'string_line_list.dart';

class LogLineList extends StringLineList {
  LogLineList(backChannelMgr) : super(backChannelMgr);

  requestLogs() {
    int startIndex = list.length;
    int numItems = 10;
    return hyperCubeMgr.getLogLines(startIndex, numItems);
  }

  bool onLogLines(LineList _lineList) {
    return super.onAddLines(_lineList);
  }
}

class StatusLineList extends StringLineList {
  StatusLineList(backChannelMgr) : super(backChannelMgr);

  requestStatus() {
    int startIndex = list.length;
    int numItems = 10;
    return hyperCubeMgr.getStatusLines(startIndex, numItems);
  }

  bool onStatusLines(LineList _lineList) {
    return super.onReplaceLines(_lineList);
  }
}

class GroupInfoList extends ChangeNotifier {
  List<GroupInfo> _list = [];
  bool onGroupInfoList(List<GroupInfo> _groupInfoList) {
    _list = _groupInfoList;
    notifyListeners();
    return true;
  }

  List<GroupInfo> getList() => _list;
  String getFirst() {
    return (_list.isNotEmpty) ? _list[0].groupName : "";
  }

  clear() {
    _list.clear();
  }
}

class HKDevice extends HkClient {
  HyperCubeHost hyperCubeHost;
  late LogLineList logLineList;
  late StatusLineList statusLineList;
  HKDevice(Logger logger, this.hyperCubeHost) : super(logger, hyperCubeHost) {
    logLineList = LogLineList(this);
    statusLineList = StatusLineList(this);
  }
//  static const String activeServerRemoteIpAddress = "192.168.1.216";
//  String remoteIpAddress = "3.141.6.1";
//  static const int activeServerRemoteIpPort = 5054;

  GroupInfoList groupInfoList = GroupInfoList();

  //@override
  bool initWithSystemInfo({SystemInfo? systemInfo}) {
    ConnectionInfo connectionInfo = ConnectionInfo();
    connectionInfo.connectionName = systemInfo!.appName;
    connectionInfo.appUUID = systemInfo.appUUID;
    connectionInfo.appInstallUUID = systemInfo.appInstallUUID;
    connectionInfo.systemName = systemInfo.systemName;
    connectionInfo.userName = systemInfo.userName;
    connectionInfo.userUUID = systemInfo.userUUID;
    connectionInfo.displayName = systemInfo.displayName;
    connectionInfo.access = CONNECTIONINFO_ACCESS.ANY;

    super.init(connectionInfo);
    return true;
  }

  String currentGroup = "";

  @override
  bool onConnection() {
    super.onConnection();
    return true;
  }

  bool onDisconnection() {
    super.onDisconnection();
    return true;
  }

  @override
  onConnectionDataOpen(String groupName) {
    super.onConnectionDataOpen(groupName);
  }

  @override
  onConnectionDataClosed() {
    super.onConnectionDataClosed();
    hyperCubeHost.onConnectionClosed();
  }

  @override
  onMsgForHost(MsgExt msgExt) {
    super.onMsgForHost(msgExt);
  }

  bool hostSendBinary(List<int> data, [int size = 0]) {
    return super.sendBinary(data, size);
  }

  @override
  bool onGroupInfoList(List<GroupInfo> _groupInfoList) {
    groupInfoList.onGroupInfoList(_groupInfoList);
    return super.onGroupInfoList(_groupInfoList);
  }

  @override
  bool onLogLines(LineList _lineList) {
    logLineList.onLogLines(_lineList);
    return super.onLogLines(_lineList);
  }

  @override
  bool onStatusLines(LineList _lineList) {
    statusLineList.onStatusLines(_lineList);
    return super.onStatusLines(_lineList);
  }

  @override
  bool getConnectionInfo(List<String> _list) {
    return super.getConnectionInfo(_list);
  }
}
