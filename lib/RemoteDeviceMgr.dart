import 'dart:async';
import 'dart:typed_data';

import 'Data/SystemInfo.dart';
import 'HyperCubeClient.dart';
import 'HyperCubeClientMgr.dart';

import 'CommonCppDartCode/Messages/MessagesCommon_generated.dart';
import 'Tools/SerDes.dart';
import 'Tools/Logger.dart';
import 'Tools/MsgExt.dart';

class CommMgr implements HyperCubeHost {
  final Logger logger;
  late HyperCubeMgr hyperCubeMgr;

  CommMgr(this.logger) {
    hyperCubeMgr = HyperCubeMgr(logger, this);
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
}

// -----------------------------------------------------------------------
enum CHANNEL { NONE, LOCALCHANNEL, BACKCHANNEL }

class RemoteDeviceMgr extends CommMgr {
  StreamController<MsgExt> backChanneltreamCtrl = StreamController<MsgExt>();
  Stream? backChannelStream;
  String autoConnectLocalIp = "";

  final Logger logger;

  CHANNEL activeChannel = CHANNEL.NONE;

  int numRecvdMsgs = 0;
  int numSentMsgs = 0;

  RemoteDeviceMgr(this.logger) : super(logger) {
    backChannelStream = backChanneltreamCtrl.stream;
  }

  init(SystemInfo? systemInfo) {
    bool res = false;
    autoConnectLocalIp = systemInfo!.colocatedMatrixIp;

    res = hyperCubeMgr.initWithSystemInfo(systemInfo: systemInfo);
    logger.add(EVENTTYPE.INFO, "DeviceMgr", "init()", (res == true) ? 1 : 0);
  }

  deinit() async {
    logger.add(EVENTTYPE.INFO, "DeviceMgr", "deinit()", 0);
    backChanneltreamCtrl.close();
    hyperCubeMgr.deinit();
  }

  bool _sendBinary(List<int> data, [int size = 0]) {
    logger.setStateInt("DeviceMgr-NumSentMsgs", ++numSentMsgs);
    if (activeChannel == CHANNEL.BACKCHANNEL)
      return backChannelSendBinary(data, size);
    return false;
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

  @override
  bool onOpenStream(MsgExt msgExt) {
    if (!backChanneltreamCtrl.hasListener) {
      logger.add(
          EVENTTYPE.WARNING, "DeviceMgr", "onBackChannelOpen(), No listener");
    }
    logger.add(
        EVENTTYPE.INFO, "DeviceMgr", "onBackChannelOpen(), opened channel");
    activeChannel = CHANNEL.BACKCHANNEL;
    backChanneltreamCtrl.add(msgExt);
    return true;
  }

  @override
  bool onCloseStream() {
    logger.add(
        EVENTTYPE.INFO, "DeviceMgr", "onBackChannelClose(), closed channel");
    logger.setStateString("DeviceMgr-Channel", "");
    if (activeChannel == CHANNEL.BACKCHANNEL) {
      var closeMsgExt = CloseMsgExt();
      backChanneltreamCtrl.add(closeMsgExt);
      activeChannel = CHANNEL.NONE;
    }
    return true;
  }

  @override
  bool onConnectionClosed() {
    return true;
  }

  @override
  onMsg(MsgExt msgExt) {
    logger.setStateInt("DeviceMgr-NumRecvdMsgs", ++numRecvdMsgs);
    if (activeChannel == CHANNEL.BACKCHANNEL) backChanneltreamCtrl.add(msgExt);
  }

  bool backChannelSendBinary(List<int> data, [int size = 0]) {
    return hyperCubeMgr.hostSendBinary(data, size);
  }

  // --------------------------------------------------------------------------
  // These methods are called by MatrixConnectionStateMachine to do stuff

  bool startOpenBackChannel(String channelName) {
    activeChannel = CHANNEL.BACKCHANNEL;
    bool stat = hyperCubeMgr.enable(channelName);
    logger.add(EVENTTYPE.INFO, "DeviceMgr::startOpenBackChannel()",
        "connect to back channel, $channelName");
    return stat;
  }

  bool startCloseBackChannel() {
    hyperCubeMgr.disable();
    activeChannel = CHANNEL.NONE;
    logger.add(EVENTTYPE.INFO, "DeviceMgr::startCloseBackChannel()", "");
    return onCloseStream();
  }

  bool closeAll() {
    hyperCubeMgr.disable();
    activeChannel = CHANNEL.NONE;
    onCloseStream();
    logger.add(EVENTTYPE.INFO, "DeviceMgr::closeAll()", "");
    return true;
  }

  List<String> queryChannels(String name) {
    List<String> channelList = [];
    return channelList;
  }
}
