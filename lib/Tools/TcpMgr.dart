import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

// import 'package:watchman_fl/GlobalDataModel.dart';
import 'Logger.dart';

const _defaultTcpAddress = "";
const _defaultTcpPort = 4545;

class TcpManager {
  var remoteTcpAddressString = _defaultTcpAddress;
  int remoteTcpPort = _defaultTcpPort;
  late InternetAddress remoteTcpAddress;
  final Logger logger;
  String errorMessage = "";

  Socket? _tcpSocket;
  bool receiveOpened = false;

  String ownerName;

  int numConnectionAttemptSuccesses = 0;
  int numConnectionAttemptFails = 0;
  int numConnectionCloses = 0;

  TcpManager(this.ownerName, this.logger,
      {this.remoteTcpAddressString = _defaultTcpAddress,
      this.remoteTcpPort = _defaultTcpPort}) {
//    tcpAddress = InternetAddress(_defaultTcpAddress);
  }

  Future<bool> open(Function(Uint8List) onReceiveCallback,
      Function() onTcpCloseCallback, var _remoteIpAddressString,
      [_remoteTcpPort = 0, bool _logErrors = true]) async {
    // only open once
    if (remoteTcpAddressString == _remoteIpAddressString) return false;
    if (receiveOpened) return false;

    remoteTcpAddressString = _remoteIpAddressString;
    remoteTcpAddress = InternetAddress(remoteTcpAddressString);
    if (_remoteTcpPort != 0) remoteTcpPort = _remoteTcpPort;

    bool connectStat = true;
    try {
      _tcpSocket = await Socket.connect(remoteTcpAddress, remoteTcpPort,
          timeout: Duration(seconds: 5));
    } on SocketException catch (e) {
      errorMessage = e.toString();
      connectStat = false;
    } on Error catch (e) {
      errorMessage = e.toString();
      connectStat = false;
    }

    if (!connectStat) {
      if (_logErrors) {
        logger.add(EVENTTYPE.WARNING, "$ownerName-TCPManager::Connect failed",
            errorMessage.toString());
      }
      logger.setStateString("$ownerName-TCPManager-ConnectionIP", "");
      logger.setStateInt("$ownerName-TCPManager-NumConnectionAttemptFails",
          ++numConnectionAttemptFails);
      receiveOpened = false;
      remoteTcpAddressString = "";
      return false;
    }

    if (_tcpSocket == null) return false;

    // _tcpSocket.setOption(SocketOption.tcpNoDelay, true);
    // listen to the received data event stream
    _tcpSocket!.listen((Uint8List event) {
      onReceiveCallback(event);
    }, onDone: () {
      logger.add(EVENTTYPE.INFO, "$ownerName-TCPManager closed socket with",
          remoteTcpAddressString + ":" + remoteTcpPort.toString());
      remoteTcpAddressString = "";
      logger.setStateString("$ownerName-TCPManager-ConnectionIP", "");
      receiveOpened = false;
      logger.setStateInt(
          "$ownerName-TCPManager-NumConnectionCloses", ++numConnectionCloses);
      onTcpCloseCallback();
      return;
    }, onError: (error) {
      logger.add(
          EVENTTYPE.WARNING,
          "$ownerName-TCPManager::listen()  socket error with",
          remoteTcpAddressString + ":" + remoteTcpPort.toString());
      remoteTcpAddressString = "";
      logger.setStateString("$ownerName-TCPManager-ConnectionIP", "");
      receiveOpened = false;
      onTcpCloseCallback();
      return false;
    });

    logger.add(EVENTTYPE.INFO, "$ownerName-TcpManager",
        "open() opened connection to $remoteTcpAddressString:$remoteTcpPort");
    logger.setStateString(
        "$ownerName-TCPManager-ConnectionIP", remoteTcpAddressString);
    logger.setStateInt("$ownerName-TCPManager-NumConnectionAttemptSuccesses",
        ++numConnectionAttemptSuccesses);
    receiveOpened = true;
    return true;
  }

  void sendString(String msg) {
    _tcpSocket?.add(utf8.encode(msg));
  }

  bool sendBinary(List<int> data, [int size = 0]) {
    if (_tcpSocket == null) return false;
    if (!receiveOpened) return false;
    try {
      if (size > 0) {
        _tcpSocket!.add(data.sublist(0, size));
      } else
        _tcpSocket!.add(data);
    } catch (e) {
      logger.add(EVENTTYPE.WARNING, "TcpManager",
          "sendBinary(), failed with Exception  " + e.toString());
      return false;
    }
    return true;
  }

  Future<bool> close() async {
    logger.add(EVENTTYPE.INFO, "TcpManager",
        "close() closing connection with $remoteTcpAddressString:$remoteTcpPort");
    if (receiveOpened) {
      if (_tcpSocket != null) {
        await _tcpSocket!.flush();
        await _tcpSocket!.close();
      }
      receiveOpened = false;
      remoteTcpAddressString = "";
      logger.setStateString("TCPManager-ConnectionIP", "");
    }
    return true;
  }

  bool isOpen() {
    return receiveOpened;
  }
}
