//import 'dart:ffi';
import 'dart:io';
// import 'package:watchman_fl/GlobalDataModel.dart';
import 'Logger.dart';

const _defaultMulticastAddress = "239.0.0.10";
const _defaultMulticastPort = 4545;

class MulticastMgr {
  var multicastAddressString = _defaultMulticastAddress;
  int multicastPort = _defaultMulticastPort;
  InternetAddress multicastAddress = InternetAddress(_defaultMulticastAddress);
  final Logger logger;

  late RawDatagramSocket _multicastSocket;
  static bool receiveOpened = false;

  MulticastMgr(this.logger,
      {this.multicastAddressString = _defaultMulticastAddress,
      this.multicastPort = _defaultMulticastPort});

  bool open(Function(Datagram) onReceiveCallback) {
    // only open once
    if (receiveOpened) return false;
    receiveOpened = true;

    RawDatagramSocket.bind(InternetAddress.anyIPv4, multicastPort)
        .catchError((onError) {
      logger.add(
          EVENTTYPE.ERROR, "Multicast", "bind failed for $multicastPort");
//          print("Bind failed");
      return onError;
    }).then((RawDatagramSocket socket) {
      socket.joinMulticast(multicastAddress);
      socket.broadcastEnabled = true;
      socket.multicastHops = 32;
      _multicastSocket = socket;
      // gdm.logger.add(EVENTTYPE.INFO, "Multicast", "Listening for hello on $multicastAddressString");
      socket.listen((RawSocketEvent e) {
        Datagram? d = socket.receive();
        if (d == null) return;
        onReceiveCallback(d);
      });
    });
    return true;
  }

  int send(String msg) {
    int numSent =
        _multicastSocket.send(msg.codeUnits, multicastAddress, multicastPort);
    return numSent;
  }

  void close() {
    _multicastSocket.close();
    logger.add(EVENTTYPE.INFO, "Multicast",
        "Stopped listening for hello on $multicastAddressString");
  }
}
