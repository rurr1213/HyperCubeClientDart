import 'dart:typed_data';

class Packet {
  Uint8List? data;
  Packet(this.data);
  appendData(Packet other) {
    try {
      if (other.data == null) return;
      if (other.data!.length == 0) return;
      Uint8List _newData = Uint8List(data!.length + other.data!.length);
      int i = 0;
      for (i = 0; i < data!.length; i++) {
        _newData[i] = data![i];
      }
      for (int j = 0; j < other.data!.length; j++) {
        _newData[i + j] = other.data![j];
      }
      data = _newData;
    } catch (e) {
      print(e);
      assert(false);
    }
  }
}
