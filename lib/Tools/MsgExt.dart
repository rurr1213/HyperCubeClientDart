import 'dart:typed_data';

import '../CommonCppDartCode/Messages/MessagesCommon_generated.dart';
import 'SerDes.dart';

const MSGHEADERLENGTH_MAX = 64;

class MsgExt {
  Msg _msg = Msg();

  MsgExt();

  MsgExt.copy(MsgExt otherMsgExt) {
    copyMsgExt(otherMsgExt);
  }

  copyMsgExt(MsgExt otherMsgExt) {
    _msg.copy(otherMsgExt._msg);
  }

  int load(Uint8List? _data) {
    try {
      if (_data == null) return 0;
      if (_data.elementSizeInBytes == 0) return 0;
      SerDes sdm = SerDes(_data);
      _msg.deserialize(sdm);
      if (_msg.prot != PROTOCOL_CODE) {
        return -1;
      }
    } catch (e) {
      return -1;
    }
    return _msg.length;
  }

  int calcMsgHeaderLength() {
    Uint8List _data = Uint8List(256);
    SerDes _sdm = SerDes(_data);
    Msg _msg = Msg();
    return _msg.serialize(_sdm);
  }

  @override
  String toString() {
    String line = "[";
    line += "L: $_msg.length";
    line += ", D: ${_msg.deviceAppKey.toRadixString(16)}";
    line += ", SE: $_msg.sessionKey";
    line += ", SQ: $_msg.seqNumber";

    switch (_msg.subSys) {
      case SUBSYS_DISCOVERY:
        line += ", S: " + "DISC";
        switch (_msg.command) {
          case DISCOVERY_HELLO:
            line += ", C: HELLO";
            break;
          case DISCOVERY_HELLOACK:
            line += ", C: HELLOACK";
            break;
          case DISCOVERY_CLOSESOCKET:
            line += ", C: CLOSESOCKET";
            break;
          default:
            line += ", C: UNKNOWN!: " + _msg.command.toString();
        }
        break;

      case SUBSYS_STATS:
        line += ", S: " + "STATS";
        switch (_msg.command) {
          case STATS_STATINFO:
            line += ", C: STATINFO";
            break;
          case STATS_IDDITEMSET:
            line += ", C: IDDITEMSET";
            break;
          default:
            line += ", C: UNKNOWN!: " + _msg.command.toString();
        }
        break;

      case SUBSYS_CMD:
        line += ", S: " + "CMD";
        switch (_msg.command) {
          case CMD_PCJSON:
            line += ", C: PCJSON";
            break;
          case CMD_PINGFROMPC:
            line += ", C: PINGFROMPC";
            break;
          case CMD_PINGFROMPCACK:
            line += ", C: PINGFROMPCACK";
            break;
          case CMD_PINGTOPC:
            line += ", C: PINGTOPC";
            break;
          case CMD_PINGTOPCACK:
            line += ", C: PINGTOPCACK";
            break;
          case CMD_BOTEVENT:
            line += ", C: PINGTOPCACK";
            break;
          default:
            line += ", C: UNKNOWN!: " + _msg.command.toString();
        }
        break;

      case SUBSYS_OBJ:
        line += ", S: " + "OBJ";
        switch (_msg.command) {
          case OBJ_UNKNOWN:
            line += ", C: UNKNOWN";
            break;
          case OBJ_LOGGER:
            line += ", C: LOGGER";
            break;
          case OBJ_APPMGR:
            line += ", C: APPMGR";
            break;
          case OBJ_STATSMGR:
            line += ", C: STATSMGR";
            break;
          default:
            line += ", C: UNKNOWN!: " + _msg.command.toString();
        }
        break;
    }

    line += ", A: $_msg.argument";
    line += ", c: ${_msg.crc.toRadixString(16)}";
    return line;
  }

  static MsgExt factoryMethod(Uint8List? _data) {
    MsgExt _msgExt = MsgExt();
    if (_data == null) return _msgExt;
    if (_data.elementSizeInBytes == 0) return _msgExt;

    SerDes sdm = SerDes(_data);
    _msgExt._msg.deserialize(sdm);

    SerDes sd = SerDes(_data);

    switch (_msgExt._msg.subSys) {
      case SUBSYS_SIG:
        _msgExt._msg = SigMsg("");
        _msgExt._msg.deserialize(sd);
        break;
      case SUBSYS_DISCOVERY:
        switch (_msgExt._msg.command) {
          case DISCOVERY_HELLO:
            _msgExt._msg = MsgDiscoveryMulticastHello();
            _msgExt._msg.deserialize(sd);
            break;
          case DISCOVERY_HELLOACK:
            _msgExt._msg = MsgDiscoveryHelloAck();
            _msgExt._msg.deserialize(sd);
            break;
          case DISCOVERY_CLOSESOCKET:
            break;
          default:
            break;
        }
        break;
      case SUBSYS_STATS:
        switch (_msgExt._msg.command) {
          case STATS_IDDITEMSET:
            _msgExt._msg = MsgIddStatItemSet();
            _msgExt._msg.deserialize(sd);
            break;
          case STATS_STATINFO:
            _msgExt._msg = MsgStatInfo();
            _msgExt._msg.deserialize(sd);
            break;
          default:
            break;
        }
        break;

      case SUBSYS_CMD:
        switch (_msgExt._msg.command) {
          case CMD_PCJSON:
            _msgExt._msg = MsgCmd("");
            _msgExt._msg.deserialize(sd);
            break;
          default:
            break;
        }
        break;

      case SUBSYS_OBJ:
        _msgExt._msg = MsgObject(SUBSYS_OBJ, OBJ_UNKNOWN, "");
        _msgExt._msg.deserialize(sd);
        break;
      default:
        break;
    }

    return _msgExt;
  }

  MsgDiscoveryMulticastHello getMsgDiscoveryMulticastHello() {
    return _msg as MsgDiscoveryMulticastHello;
  }

  int get subSys => _msg.subSys;
  int get command => _msg.command;

  MsgCmd getMsgCmd() {
    return _msg as MsgCmd;
  }

  MsgIddStatItemSet getMsgIddStatItemSet() {
    return _msg as MsgIddStatItemSet;
  }

  MsgStatInfo getMsgStatInfo() {
    return _msg as MsgStatInfo;
  }

  SigMsg getSigMsg() {
    return _msg as SigMsg;
  }

  MsgObject getMsgObject() {
    return _msg as MsgObject;
  }

  Msg getMsg() {
    return _msg;
  }

  bool validProtocolCode() {
    if (_msg.prot == PROTOCOL_CODE) {
      return true;
    }
    return false;
  }

  bool validHeaderCrc() {
    if (_msg.crc == _msg.calcCrc()) {
      return true;
    }
    return false;
  }
}

class CloseMsg extends Msg {
  CloseMsg() : super() {
    subSys = SUBSYS_DISCOVERY;
    command = DISCOVERY_CLOSESOCKET;
  }
}

class CloseMsgExt extends MsgExt {
  CloseMsgExt() : super() {
    _msg.subSys = SUBSYS_DISCOVERY;
    _msg.command = DISCOVERY_CLOSESOCKET;
  }
}
