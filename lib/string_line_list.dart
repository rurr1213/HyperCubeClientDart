import 'package:flutter/foundation.dart';
import 'CommonCppDartCode/Messages/HyperCubeMessagesCommon_generated.dart';

import 'hk_device.dart';

class StringLineList extends ChangeNotifier {
  static const int maxLength = 1000;
  HKDevice hyperCubeMgr;
  List<String> list = [];
  StringLineList(this.hyperCubeMgr);
  int dumpedLines = 0;

  bool onList(List<String> _stringList) {
    list = _stringList;
    notifyListeners();
    return true;
  }

  List<String> getList() => list;
  String getFirst() {
    return (list.isNotEmpty) ? list[0] : "";
  }

  bool onReplaceList(int start, int end, List<String> _list) {
    _list.replaceRange(start - dumpedLines, end - dumpedLines, _list);
    notifyListeners();
    return true;
  }

  bool onAddLines(LineList _lineList) {
    if (_lineList.list.length <= 0) return false;
    int itemNum = 0;
    _lineList.list.forEach((element) {
      int destIndex = _lineList.startingIndex - dumpedLines + itemNum;
      if (list.length <= destIndex) {
        list.add(element);
      } else {
        list[destIndex] = element;
      }
      itemNum++;
    });

    if (list.length > maxLength) {
      list.removeRange(0, 9);
      dumpedLines += 10;
    }
    notifyListeners();
    return true;
  }

  bool onReplaceLines(LineList _lineList) {
    if (_lineList.list.length <= 0) return false;
    list = _lineList.list;
    notifyListeners();
    return true;
  }

  clear() {
    list.clear();
  }
}
