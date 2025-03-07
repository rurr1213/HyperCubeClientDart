import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'Data/system_info.dart';
import 'hk_client.dart';
import 'hk_device.dart';

import 'CommonCppDartCode/Messages/MessagesCommon_generated.dart';
import 'CommonCppDartCode/Messages/HyperCubeMessagesCommon_generated.dart';
import 'CommonCppDartCode/dart/utils.dart';

import 'tools/ser_des.dart';
import 'tools/logger.dart';
import 'tools/msg_ext.dart';

import 'group_activity_data.dart';
import 'hk_api.dart';

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

class HkDeviceMgr extends CommMgr implements HKIAPI {
  StreamController<MsgExt> backChanneltreamCtrl = StreamController<MsgExt>();
  Stream? backChannelStream;
  String autoConnectLocalIp = "";
  GroupActivityData groupActivityData = GroupActivityData();
  StreamSubscription<dynamic>? deviceMgrStreamSubscription;

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

    deviceMgrStreamSubscription = backChannelStream!.listen((msg) {
      processMsg(msg);
    }, onDone: () {
      streamClosed();
    }, onError: (error) {
      logger.add(
          EVENTTYPE.ERROR, "HkDeviceMgr", "backChannelStream.listen(), error!");
    });

    return res;
  }

  bool streamClosed() {
    logger.add(EVENTTYPE.WARNING, "DeviceMgr", "onCloseStream()", 0);
    return true;
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

  bool processMsg(MsgExt msgExt) {
    bool proceesed = false;
    switch (msgExt.subSys) {
      case SUBSYS_CMD:
        switch (msgExt.command) {
          case CMD_JSON:
//            MsgJsonCmd msgJsonCmd = msgExt.getMsgJson() as MsgJsonCmd;
            MsgJsonCmd msgJsonCmd = msgExt.getMsg() as MsgJsonCmd;
            proceesed = processMsgJson(msgJsonCmd);
            break;
          default:
        }
        break;
      default:
    }
    return proceesed;
  }

  bool processMsgJson(MsgJsonCmd msgJsonCmd) {
    String jsonString = msgJsonCmd.jsonData;
    bool processed = false;
    HyperCubeCommand hyperCubeCommand =
        HyperCubeCommand(HYPERCUBECOMMANDS.NONE, null, true);
    try {
      hyperCubeCommand.fromJson(jsonDecode(jsonString));

      switch (hyperCubeCommand.command) {
        case HYPERCUBECOMMANDS.PUBLISHINFOACK:
          processed = onPublishInfoAck(hyperCubeCommand);
          break;
        default:
      }
    } catch (e) {
      logger.add(
          EVENTTYPE.ERROR,
          "SignallingObject::processMsgJson()",
          jsonString +
              ", field not found " +
              e.toString() +
              " on command " +
              hyperCubeCommand.command.toString());
    }
    return processed;
  }

  bool onPublishInfoAck(HyperCubeCommand hyperCubeCommand) {
    PublishInfoAck publishInfoAck = PublishInfoAck();
    publishInfoAck.fromJson(hyperCubeCommand.jsonData);
    String _groupName = publishInfoAck.groupName;
    groupActivityData.add(
        _groupName, HYPERCUBECOMMANDS.PUBLISHINFOACK, publishInfoAck);
    logger.add(
        EVENTTYPE.INFO,
        "HkDeviceMgr",
        "processMsgJson(), received publishInfoAck " +
            publishInfoAck.publishAckData);

    return true;
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

  StringUuid? publish(String groupName, String data, {bool ack = true}) {
    PublishInfo publishInfo = PublishInfo();
    publishInfo.groupName = groupName;
    publishInfo.publishData = data;
    publishInfo.ack = ack;
    if (!hkDevice.publish(publishInfo)) {
      logger.add(
          EVENTTYPE.ERROR, "DeviceMgr::publish() failed", "$groupName : $data");
      return null;
    }

    //logger.add(EVENTTYPE.INFO, "DeviceMgr::publish()", "$groupName : $data");
    return publishInfo.uuid;
  }

  Future<String> publishAndWait(String groupName, String data) async {
    StringUuid? uuid = publish(groupName, data);
    if (uuid == null) return "";
    CommonInfoBase? commonInfoBase = null;

    //int maxLoops = 50;
    while (commonInfoBase == null) {
      await Future.delayed(Duration(milliseconds: 1000)); // Sleep for 1 second
      commonInfoBase = await groupActivityData.findWait(
          groupName, HYPERCUBECOMMANDS.PUBLISHINFOACK, uuid);
      /*
      if (maxLoops-- == 0) {
        logger.add(EVENTTYPE.ERROR, "DeviceMgr::publishAndWait()",
            "timeout waiting for response");
        return "";
      }
      */
    }
    PublishInfoAck? publishInfoAck = commonInfoBase as PublishInfoAck;
    return publishInfoAck.publishAckData;
  }

  bool createGroup(GroupInfo groupInfo) {
    return hkDevice.createGroup(groupInfo);
  }

  bool destroyGroup(GroupInfo groupInfo) {
    return hkDevice.destroyGroup(groupInfo);
  }

  bool subscribe(SubscriberInfo subscriberInfo) {
    return hkDevice.subscribe(subscriberInfo);
  }

  bool unsubscribe(SubscriberInfo subscriberInfo) {
    return hkDevice.unsubscribe(subscriberInfo);
  }
}
