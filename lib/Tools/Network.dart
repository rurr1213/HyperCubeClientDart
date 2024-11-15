// import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';

class Ifconfig {
  String ip;
  String gateway;
  String netmask;
  String broadcast;

  Ifconfig({
    this.ip = "0.0.0.0",
    this.gateway = "0.0.0.0",
    this.netmask = "0.0.0.0",
    this.broadcast = "0.0.0.0",
  });

  @override
  String toString() {
    return 'ip:$ip\n localIP:$gateway\n netmask:$netmask\n broadcast:$broadcast';
  }
}

class NetworkManager {
  // String platformVersion = 'Unknown';
  String status = "Not ready";
  var ifconfig = Ifconfig();

  NetworkManager();

  // Platform messages are asynchronous, so we initialize in an async method.
  // Future<void> initPlatformState() async {
  //   // Platform messages may fail, so we use a try/catch PlatformException.

  //   // try {
  //   //   platformVersion = await Gateway.platformVersion;
  //   // } on PlatformException {
  //   //   platformVersion = 'Failed to get platform version.';
  //   // }
  // }

  Future<void> initGatewayState() async {
    final info = NetworkInfo();
    // Gateway? gt;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      ifconfig.gateway = (await info.getWifiGatewayIP())!;
      ifconfig.ip = (await info.getWifiIP())!;
      ifconfig.netmask = (await info.getWifiSubmask())!;
      ifconfig.broadcast = (await info.getWifiBroadcast())!;

      // gt = await Gateway.info;
    } on Exception {
      
      status = 'Failed to get network information.';
      // status = 'Failed to get platform version.';
    }

    // ifconfig.gateway = gt!.ip;
    // ifconfig.ip = gt.localIP;
    // ifconfig.netmask = gt.netmask;
    // ifconfig.broadcast = gt.broadcast;
  }

  Future<bool> initState() async {
    // await initPlatformState();
    await initGatewayState();
    return true;
  }

  printInfo() {
    // print("Platform version is : $platformVersion");
    print("Gateway is : $ifconfig.toString()");
  }

  @override
  String toString() {
    return 'ifconfig:$ifconfig.toString()';
    // return 'Platform:$platformVersion\n ifconfig:$ifconfig.toString()';
  }
}

class NetworkUDP {}
