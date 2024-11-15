// import 'package:watchman_fl/GlobalDataModel.dart';
// import 'dart:ffi';

// import 'CommonCppDartCode/Messages/MessagesCommon_generated.dart';
import 'Packet.dart';
import 'SerDes.dart';
import 'MsgExt.dart';
import 'Logger.dart';

class WorkingPacket extends Packet {
  final Function(MsgExt msg) onMsgCallBack;
  final MsgExt workingMsg;
  int msgHeaderLength = 0;
  final Logger logger;
//  late Uint8List _data = Uint8List();

  WorkingPacket(
    this.logger,
    this.workingMsg,
    this.onMsgCallBack,
  ) : super(null);

  init() {
    msgHeaderLength = workingMsg.calcMsgHeaderLength();
  }

  void process() {
    while (hasMsgHeaderLength() == true) {
      int neededLength = workingMsg.load(data!);

      // if this is an invalid packet/data, dump all data
      if (neededLength == -1) {
        SerDes sd = SerDes(data!);
        String line = "";
        for (int i = 0; i < 4; i++) {
          int word = sd.getInt32();
          line += "0x" + word.toRadixString(16) + ", ";
        }
        logger.add(EVENTTYPE.DBGDATA, "WorkingPacket", "data() " + line);
        logger.add(EVENTTYPE.DBGDATA, "WorkingPacket",
            "msg() " + workingMsg.toString());
        logger.add(EVENTTYPE.ERROR, "WorkingPacket::process()",
            "msg() " + workingMsg.toString());
        data = null;
        break;
      }

      if (neededLength <= data!.length) {
        logger.add(EVENTTYPE.DBGDATA, "", " " + workingMsg.toString());

        logger.assertTrue(workingMsg.validProtocolCode(), "WorkingPacket",
            "process() " + "Bad protocol code");
        logger.assertTrue(workingMsg.validHeaderCrc(), "WorkingPacket",
            "process() " + "Bad header crc");
        MsgExt msgExt = MsgExt.factoryMethod(data);
        onMsgCallBack(msgExt);
        logger.assertTrue(neededLength >= 0, "WorkingPacket",
            "process() " + "Bad needed length : " + neededLength.toString());
        data = data!.sublist(neededLength);
      } else
        break;
    }
  }

  add(Packet packet) {
    if ((data == null) || (data!.length == 0)) {
      data = packet.data;
      return;
    }
    appendData(packet);
  }

  bool hasMsgHeaderLength() =>
      (data != null) ? data!.length >= msgHeaderLength : false;
}

class PacketCtrl {
  List<Packet> packetList = [];

  late WorkingPacket workingPacket;
  MsgExt workingMsg = MsgExt();
  final Logger logger;

  PacketCtrl(this.logger, Function(MsgExt msg) onMsgCallBack) {
    workingPacket = WorkingPacket(logger, workingMsg, onMsgCallBack);
  }

  init() {
    workingPacket.init();
  }

  onPacket(Packet packet) {
    packetList.add(packet);
  }

  void processPackets() {
    workingPacket.process();
    while (packetList.length > 0) {
      workingPacket.add(packetList.removeLast());
      workingPacket.process();
    }
  }
}
