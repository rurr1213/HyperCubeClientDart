import 'package:firedart/firedart.dart';

import 'Core/HyperCubeClientBase.dart';
import 'Core/SignallingObject.dart';
import 'Tools/Logger.dart';
import 'Tools/PacketCtrl.dart';
import 'Tools/MsgExt.dart';
import 'Tools/Packet.dart';
import 'CommonCppDartCode/Messages/MessagesCommon_generated.dart';
import 'CommonCppDartCode/Messages/HyperCubeMessagesCommon_generated.dart';

abstract class HyperCubeHost {
  onInfo(String groupName);
  bool onOpenStream(MsgExt msgExt);
  onMsg(MsgExt msgExt);
  bool onCloseStream();
  bool onConnectionClosed();
}

class CloudConfigInfo {
  static String primaryKeyValue = "primaryServer";
  static String primaryPortKeyValue = "primaryPort";
  static String secondaryKeyValue = "secondaryServer";
  static String secondaryPortKeyValue = "secondaryPort";
  String primaryServer = PRIMARY_SERVERNAME;
  String secondaryServer = SECONDARY_SERVERNAME;
  int primaryIpPort = DEFAULT_SERVERPORT;
  int secondaryIpPort = DEFAULT_SERVERPORT;
  Map<String, dynamic> toMap() {
    return {
      primaryKeyValue: primaryServer,
      primaryPortKeyValue: primaryIpPort,
      secondaryKeyValue: secondaryServer,
      secondaryPortKeyValue: secondaryIpPort
    };
  }
}

class HyperCubeClient extends HyperCubeClientBase {
  late PacketCtrl packetCtrl;
  HyperCubeHost hyperCubeHost;
  CloudConfigInfo cloudConfigInfo = CloudConfigInfo();

  HyperCubeClient(Logger logger, this.hyperCubeHost) : super(logger) {
    packetCtrl = PacketCtrl(logger, onMsg);
  }

  initCloudConfig() {
    var collection = Firestore.instance.collection("HyperCube");
    var document = collection.document("globalConfig");
    CloudConfigInfo initCloudConfingInfo = CloudConfigInfo();
    var map = initCloudConfingInfo.toMap();
    document.update(map);
  }

  Future<bool> getCloudConfig(CloudConfigInfo _cloudConfigInfo) async {
    bool found = false;
    try {
      var collection = Firestore.instance.collection("HyperCube");
      DocumentReference documentReference = collection.document("globalConfig");

      var config = await documentReference.get();
      if (config.map.containsKey(CloudConfigInfo.primaryKeyValue)) {
        _cloudConfigInfo.primaryServer =
            config.map[CloudConfigInfo.primaryKeyValue];
        found = true;
      }
      if (config.map.containsKey(CloudConfigInfo.primaryPortKeyValue)) {
        _cloudConfigInfo.primaryIpPort =
            config.map[CloudConfigInfo.primaryPortKeyValue];
      }
      if (config.map.containsKey(CloudConfigInfo.secondaryKeyValue)) {
        _cloudConfigInfo.secondaryServer =
            config.map[CloudConfigInfo.secondaryKeyValue];
        found = true;
      }
      if (config.map.containsKey(CloudConfigInfo.secondaryPortKeyValue)) {
        _cloudConfigInfo.secondaryIpPort =
            config.map[CloudConfigInfo.secondaryPortKeyValue];
      }
    } catch (e) {
      initCloudConfig();
      found = false;
    }
    return found;
  }

  init(ConnectionInfo connectionInfo,
      {HyperCubeServerAddresses? paramServerAddresses}) async {
    packetCtrl.init();

    HyperCubeServerAddresses? hyperCubeServerAddressing;

    // if input address is given use that
    if (paramServerAddresses != null) {
      hyperCubeServerAddressing = paramServerAddresses;
    }

    bool res = await getCloudConfig(cloudConfigInfo);

    // if there is a config from the cloud, use that
    if (res) {
      hyperCubeServerAddressing = HyperCubeServerAddresses.setDetail(
          cloudConfigInfo.primaryServer,
          cloudConfigInfo.primaryIpPort,
          cloudConfigInfo.secondaryServer,
          cloudConfigInfo.secondaryIpPort);
    }

    res = super
        .init(connectionInfo, paramServerAddresses: hyperCubeServerAddressing);
    return res;
  }

  @override
  onPacket(Packet packet) {
    super.onPacket(packet);
    packetCtrl.onPacket(packet);
    packetCtrl.processPackets();
  }

  @override
  onMsg(MsgExt msgExt) {
    super.onMsg(msgExt);
    switch (msgExt.getMsg().subSys) {
      case SUBSYS_SIG:
        signallingObject!.processHostMsg(msgExt);
        break;
      case SUBSYS_DISCOVERY:
        {
          switch (msgExt.getMsg().command) {
            case DISCOVERY_HELLO:
              onOpenStream(msgExt);
              break;
            case DISCOVERY_CLOSESOCKET:
              onCloseStream();
              break;
          }
        }
        break;
      default:
        {
          onMsgForHost(msgExt);
        }
        break;
    }
  }

  @override
  bool onConnection() {
    super.onConnection();
    return true;
  }

  @override
  bool onDisconnection() {
    super.onDisconnection();
    onCloseStream();
    return true;
  }

  onMsgForHost(MsgExt msgExt) {
    // if (!checkReadyForData()) return;
    hyperCubeHost.onMsg(msgExt);
  }

  @override
  onConnectionDataOpen(String groupName) {
    super.onConnectionDataOpen(groupName);
    hyperCubeHost.onInfo(groupName);
  }

  @override
  onConnectionDataClosed() {
    super.onConnectionDataClosed();
    onCloseStream();
  }

  onOpenStream(MsgExt msgExt) {
    if (signallingObject!.state != SignallingObjectState.inDataState) {
      bool status = hyperCubeHost.onOpenStream(msgExt);
      setStateAsData(status);
    }
  }

  onCloseStream() {
    if ((signallingObject!.state == SignallingObjectState.inDataState) ||
        (signallingObject!.state == SignallingObjectState.connected) ||
        (signallingObject!.state == SignallingObjectState.disconnected)) {
      bool status = hyperCubeHost.onCloseStream();
      setStateAsData(!status);
    }
  }

  bool searchForGroupsWithKeyword(String keyword) {
    return signallingObject!.getGroups(keyword);
  }

  bool getLogLines([startingIndex = 0, maxItems = 10]) {
    return signallingObject!.getLogLines(startingIndex, maxItems);
  }

  bool getStatusLines([startingIndex = 0, maxItems = 10]) {
    return signallingObject!.getStatusLines(startingIndex, maxItems);
  }
}
