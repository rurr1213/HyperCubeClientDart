import 'package:flutter/foundation.dart';

import 'CommonCppDartCode/Messages/HyperCubeMessagesCommon_generated.dart';
import 'Data/SystemInfo.dart';

import 'Tools/Logger.dart';
import 'Tools/MsgExt.dart';
import 'HyperCubeClient.dart';

class StringLineList extends ChangeNotifier {
  static const int maxLength = 1000;
  HyperCubeMgr backChannelMgr;
  List<String> _list = [];
  StringLineList(this.backChannelMgr);
  int dumpedLines = 0;

  bool onList(List<String> _stringList) {
    _list = _stringList;
    notifyListeners();
    return true;
  }

  List<String> getList() => _list;
  String getFirst() {
    return (_list.isNotEmpty) ? _list[0] : "";
  }

  bool onReplaceList(int start, int end, List<String> _list) {
    _list.replaceRange(start - dumpedLines, end - dumpedLines, _list);
    notifyListeners();
    return true;
  }

  bool onAddLines(LineList _lineList) {
    if (_lineList.list.length <= 0) return false;
    int itemNum = 0;
    _lineList.list.forEach((element) {
      int destIndex = _lineList.startingIndex - dumpedLines + itemNum;
      if (_list.length <= destIndex) {
        _list.add(element);
      } else {
        _list[destIndex] = element;
      }
      itemNum++;
    });

    if (_list.length > maxLength) {
      _list.removeRange(0, 9);
      dumpedLines += 10;
    }
    notifyListeners();
    return true;
  }

  bool onReplaceLines(LineList _lineList) {
    if (_lineList.list.length <= 0) return false;
    _list = _lineList.list;
    notifyListeners();
    return true;
  }

  clear() {
    _list.clear();
  }
}

class LogLineList extends StringLineList {
  LogLineList(backChannelMgr) : super(backChannelMgr);

  requestLogs() {
    int startIndex = _list.length;
    int numItems = 10;
    return backChannelMgr.getLogLines(startIndex, numItems);
  }

  bool onLogLines(LineList _lineList) {
    return super.onAddLines(_lineList);
  }
}

class StatusLineList extends StringLineList {
  StatusLineList(backChannelMgr) : super(backChannelMgr);

  requestStatus() {
    int startIndex = _list.length;
    int numItems = 10;
    return backChannelMgr.getStatusLines(startIndex, numItems);
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

class HyperCubeMgr extends HyperCubeClient {
  HyperCubeHost hyperCubeHost;
  late LogLineList logLineList;
  late StatusLineList statusLineList;
  HyperCubeMgr(Logger logger, this.hyperCubeHost)
      : super(logger, hyperCubeHost) {
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

  bool backChannelEnabled = false;
  String currentGroup = "";

  @override
  bool onConnection() {
    super.onConnection();
    return true;
  }

  bool onDisconnection() {
    super.onDisconnection();
    if (backChannelEnabled) backChannelEnabled = false;
    return true;
  }

  @override
  onConnectionDataOpen(String groupName) {
    super.onConnectionDataOpen(groupName);
  }

  @override
  onConnectionDataClosed() {
    super.onConnectionDataClosed();
    backChannelEnabled = false;
    hyperCubeHost.onConnectionClosed();
  }

  @override
  onMsgForHost(MsgExt msgExt) {
    if (backChannelEnabled) {
      super.onMsgForHost(msgExt);
    }
  }

  bool hostSendBinary(List<int> data, [int size = 0]) {
    bool stat = false;
    if (backChannelEnabled) {
      return super.sendBinary(data, size);
    }
    return stat;
  }

  bool subscribe(String groupName) {
    return super.subscribe(groupName);
  }

  bool unsubscribe(String groupName) {
    return super.unsubscribe(groupName);
  }

  bool enable(String group) {
    bool stat = false;
    if (!backChannelEnabled) {
      stat = subscribe(group);
      if (stat) {
        backChannelEnabled = true;
        currentGroup = group;
      }
    }
    return stat;
  }

  bool disable() {
    bool stat = false;
    if (backChannelEnabled) {
      stat = unsubscribe(currentGroup);
      if (stat) backChannelEnabled = false;
    }
    return stat;
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
