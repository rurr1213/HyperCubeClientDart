import 'dart:typed_data';
import 'dart:convert';

class SerDes {
  bool _badMessageDontDeserialize = false;
  Endian? useEndian;
  int offset = 0;
  Uint8List _data;
  ByteData? _bdata;
  int serializingLengthOffset = 0;
  int serializingCrcOffset = 0;
  int serializingMsgCrcOffset = 0;

  SerDes(this._data, {this.offset = 0, this.useEndian = Endian.big}) {
    _bdata = _data.buffer.asByteData();
    _badMessageDontDeserialize = false;
  }

  int getProtocolCodeAndCheckEndian(int _protocolCode) {
    int protocolCode = getInt16();
    if (protocolCode != _protocolCode) {
      //swap endianess and try again
      _swapEndian();
      _goBackNumBytes(2);
      protocolCode = getInt16();
      if (protocolCode != _protocolCode) {
        _setBadMessageDontDeserialize();
      }
    }
    return protocolCode;
  }

  void _swapEndian() {
    if (useEndian == Endian.big)
      useEndian = Endian.little;
    else
      useEndian = Endian.big;
  }

  void _goBackNumBytes(int numBytes) {
    offset -= numBytes;
    assert(offset >= 0);
  }

  void _setBadMessageDontDeserialize() {
    _badMessageDontDeserialize = true;
  }

  int _getInt(int size, int value) {
    assert(((offset + size) <= _bdata!.lengthInBytes));
    offset += size;
    return value;
  }

  int getInt16() {
    if (_badMessageDontDeserialize) return 0;
    return _getInt(2, _bdata!.getInt16(offset, useEndian!));
  }

  int getInt32() {
    if (_badMessageDontDeserialize) return 0;
    return _getInt(4, _bdata!.getInt32(offset, useEndian!));
  }

  int getInt64() {
    if (_badMessageDontDeserialize) return 0;
    return _getInt(8, _bdata!.getInt64(offset, useEndian!));
  }

  String getString() {
    if (_badMessageDontDeserialize) return "";
    String? word;
    int endIndex = _data.indexOf(0, offset);
    if (endIndex > -1) {
      word = utf8.decode(_data.sublist(offset, endIndex));
      offset = endIndex + 1;
    }
    assert(offset <= _bdata!.lengthInBytes);
    assert(word != null);
    return word!;
  }

  ///
  _setInt(int size) {
    assert(((offset + size) <= _bdata!.lengthInBytes));
    offset += size;
  }

  void setLength32(value) {
    serializingLengthOffset = offset;
    _bdata!.setInt32(offset, value, useEndian!);
    _setInt(4);
  }

  void updateLength32(value) {
    if (serializingLengthOffset > 0) {
      _bdata!.setInt32(serializingLengthOffset, value, useEndian!);
    }
  }

  void setCrc16(value) {
    serializingCrcOffset = offset;
    _bdata!.setInt16(offset, value, useEndian!);
    _setInt(2);
  }

  void updateCrc16(value) {
    if (serializingCrcOffset > 0) {
      _bdata!.setInt16(serializingCrcOffset, value, useEndian!);
    }
  }

  void setMsgCrc16(value) {
    serializingMsgCrcOffset = offset;
    _bdata!.setInt16(offset, value, useEndian!);
    _setInt(2);
  }

  void updateMsgCrc16(value) {
    if (serializingMsgCrcOffset > 0) {
      _bdata!.setInt16(serializingMsgCrcOffset, value, useEndian!);
    }
  }

  void setInt16(value) {
    _bdata!.setInt16(offset, value, useEndian!);
    _setInt(2);
  }

  void setInt32(value) {
    _bdata!.setInt32(offset, value, useEndian!);
    _setInt(4);
  }

  void setInt64(value) {
    _bdata!.setInt64(offset, value, useEndian!);
    _setInt(8);
  }

  void setString(value) {
    var encodedString = utf8.encode(value);
    int length = encodedString.length;
    assert(((offset + length + 1) <= _bdata!.lengthInBytes));
    _data.setRange(offset, offset + length, encodedString);
    _data[offset + length + 1] = 0; // null terminate the string
    offset += length + 1;
  }

  int length() {
    updateLength32(offset);
    return offset;
  }

  int updateLength() {
    return length();
  }

  void updateCrc(value) {
    updateCrc16(value);
  }

  void updateMsgCrc(value) {
    updateMsgCrc16(value);
  }

  int finalize() {
    return length();
  }

  int getLengthUnusedData() {
    return (_bdata!.lengthInBytes - offset);
  }
}
