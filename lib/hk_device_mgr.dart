import 'dart:async';
import 'dart:typed_data';

import 'Data/system_info.dart';
import 'hk_client.dart';
import 'hk_device.dart';

import 'CommonCppDartCode/Messages/MessagesCommon_generated.dart';
import 'CommonCppDartCode/Messages/HyperCubeMessagesCommon_generated.dart';

import 'tools/ser_des.dart';
import 'tools/logger.dart';
import 'tools/msg_ext.dart';

class CommMgr implements HyperCubeHost {
  final Logger logger;
  late HKDevice hkDevice;

  CommMgr(this.logger) {
    hkDevice = HKDevice(logger, this);
  }

  onInfo(String name) {}

  bool onOpenStream(MsgExt msgExt) {
    return true;
  }

  bool onCloseStream() {
    return true;
  }

  bool onConnectionClosed() {
    return true;
  }

  onMsg(MsgExt msgExt) {}

  bool onConnection() {
    return true;
  }

  bool onDisconnection() {
    return true;
  }
}

// -----------------------------------------------------------------------
enum CHANNEL { NONE, LOCALCHANNEL, BACKCHANNEL }

class HkDeviceMgr extends CommMgr {
  StreamController<MsgExt> backChanneltreamCtrl = StreamController<MsgExt>();
  Stream? backChannelStream;
  String autoConnectLocalIp = "";

  final Logger logger;

  int numRecvdMsgs = 0;
  int numSentMsgs = 0;

  HkDeviceMgr(this.logger) : super(logger) {
    backChannelStream = backChanneltreamCtrl.stream;
  }

  bool init(SystemInfo? systemInfo) {
    bool res = false;
    autoConnectLocalIp = systemInfo!.colocatedMatrixIp;

    res = hkDevice.initWithSystemInfo(systemInfo: systemInfo);
    logger.add(EVENTTYPE.INFO, "DeviceMgr", "init()", (res == true) ? 1 : 0);

    return res;
  }

  Future<bool> deinit() async {
    logger.add(EVENTTYPE.INFO, "DeviceMgr", "deinit()", 0);
    backChanneltreamCtrl.close();
    return hkDevice.deinit();
  }

  bool _sendBinary(List<int> data, [int size = 0]) {
    logger.setStateInt("DeviceMgr-NumSentMsgs", ++numSentMsgs);
    return backChannelSendBinary(data, size);
  }

  bool sendMsg(Msg msg) {
    const int bufferSize = 1024 * 8;
    Uint8List data = Uint8List(bufferSize);
    SerDes sd = SerDes(data);
    int size = msg.serialize(sd);
    if (!_sendBinary(data, size)) return false;
    assert(size < bufferSize); // else buffer is too small
    return size != 0;
  }

  // ----------------------------------------------------------

  @override
  onInfo(String groupName) {
    logger.setStateString("DeviceMgr-Channel", "backChannel-" + groupName);
  }

  bool onConnection() {
    logger.add(EVENTTYPE.INFO, "DeviceMgr", "onConnection()", 0);
    return true;
  }

  bool onDisconnection() {
    logger.add(EVENTTYPE.INFO, "DeviceMgr", "onDisconnection()", 0);
    return true;
  }

  @override
  bool onOpenStream(MsgExt msgExt) {
    if (!backChanneltreamCtrl.hasListener) {
      logger.add(
          EVENTTYPE.WARNING, "DeviceMgr", "onBackChannelOpen(), No listener");
    }
    logger.add(
        EVENTTYPE.INFO, "DeviceMgr", "onBackChannelOpen(), opened channel");
    backChanneltreamCtrl.add(msgExt);
    return true;
  }

  @override
  bool onCloseStream() {
    logger.add(
        EVENTTYPE.INFO, "DeviceMgr", "onBackChannelClose(), closed channel");
    logger.setStateString("DeviceMgr-Channel", "");
    var closeMsgExt = CloseMsgExt();
    backChanneltreamCtrl.add(closeMsgExt);
    return true;
  }

  @override
  bool onConnectionClosed() {
    return true;
  }

  @override
  onMsg(MsgExt msgExt) {
    logger.setStateInt("DeviceMgr-NumRecvdMsgs", ++numRecvdMsgs);
    backChanneltreamCtrl.add(msgExt);
  }

  bool backChannelSendBinary(List<int> data, [int size = 0]) {
    return hkDevice.hostSendBinary(data, size);
  }

  // --------------------------------------------------------------------------
  // These methods are called by MatrixConnectionStateMachine to do stuff

  bool startOpenBackChannel(String channelName) {
    logger.add(EVENTTYPE.INFO, "DeviceMgr::startOpenBackChannel()",
        "connect to back channel, $channelName");
    return true;
  }

  bool startCloseBackChannel() {
    logger.add(EVENTTYPE.INFO, "DeviceMgr::startCloseBackChannel()", "");
    return onCloseStream();
  }

  bool closeAll() {
    onCloseStream();
    logger.add(EVENTTYPE.INFO, "DeviceMgr::closeAll()", "");
    return true;
  }

  List<String> queryChannels(String name) {
    List<String> channelList = [];
    return channelList;
  }

  bool publish(String groupName, String data) {
    PublishInfo publishInfo = PublishInfo();
    publishInfo.groupName = groupName;
    publishInfo.publishData = data;
    hkDevice.publish(publishInfo);
    logger.add(EVENTTYPE.INFO, "DeviceMgr::publish()", "$groupName : $data");
    return true;
  }
}
