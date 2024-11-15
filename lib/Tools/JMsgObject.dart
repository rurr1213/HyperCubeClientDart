import 'dart:convert';

import '../CommonCppDartCode/Messages/MessagesCommon_generated.dart';
import '../CommonCppDartCode/Common_generated.dart';
import 'Logger.dart';

class JDataOnOff {
  bool on;
  JDataOnOff(this.on);
  JDataOnOff.fromJson(Map<String, dynamic> json) : on = json["On"];
  Map<String, dynamic> toJson() {
    Map<String, dynamic> jdata = {};
    jdata['On'] = on;
    return jdata;
  }
}

class JQueryFunction {
  QUERY_FUNCTION function = QUERY_FUNCTION.INVALID;
  JQueryFunction() : function = QUERY_FUNCTION.INVALID;
  JQueryFunction.fromFunction(this.function);
  JQueryFunction.fromJson(Map<String, dynamic> json) {
    int index = json["Function"];
    switch (index) {
      case 0:
        function = QUERY_FUNCTION.INVALID;
        break;
      case 1:
        function = QUERY_FUNCTION.AVG;
        break;
      case 2:
        function = QUERY_FUNCTION.MAX;
        break;
      case 3:
        function = QUERY_FUNCTION.MIN;
        break;
      case 4:
        function = QUERY_FUNCTION.COUNT;
        break;
      case 5:
        function = QUERY_FUNCTION.SUMMARY1;
        break;
    }
  }
  Map<String, dynamic> toJson() => {'Function': function.index};
}

class JGroupIdStatId {
  GROUPIDS groupId = GROUPIDS.INVALID;
  STATIDS statId = STATIDS.INVALID;
  JGroupIdStatId(this.groupId, this.statId);
  JGroupIdStatId.fromJson(Map<String, dynamic> json)
      : groupId = json["GroupId"],
        statId = json["StatId"];
  Map<String, dynamic> toJson() =>
      {'GroupId': groupId.index, 'StatId': statId.index};
}

class JDataQuery {
  JGroupIdStatId jgroupIdStatId;
  JQueryFunction jqueryFunction;
  int startTime;
  int endTime;
  JDataQuery(GROUPIDS _groupId, STATIDS _statId, QUERY_FUNCTION function,
      this.startTime, this.endTime)
      : jgroupIdStatId = JGroupIdStatId(_groupId, _statId),
        jqueryFunction = JQueryFunction.fromFunction(function);
  JDataQuery.fromJson(Map<String, dynamic> json)
      : jqueryFunction = JQueryFunction.fromJson(json),
        jgroupIdStatId = JGroupIdStatId.fromJson(json),
        startTime = json["StartTime"],
        endTime = json["EndTime"];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> jdata = jgroupIdStatId.toJson();
    jdata.addAll(jqueryFunction.toJson());
    jdata['StartTime'] = startTime;
    jdata['EndTime'] = endTime;
    return jdata;
  }
}

class JDataSetValue {
  JGroupIdStatId jgroupIdStatId;
  int timeStamp;
  int value;
  JDataSetValue(GROUPIDS _groupId, STATIDS _statId, this.timeStamp, this.value)
      : jgroupIdStatId = JGroupIdStatId(_groupId, _statId);
  JDataSetValue.fromJson(Map<String, dynamic> json)
      : jgroupIdStatId = JGroupIdStatId.fromJson(json),
        timeStamp = json["StartTime"],
        value = json["EndTime"];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> jdata = jgroupIdStatId.toJson();
    jdata['TimeStamp'] = timeStamp;
    jdata['Value'] = value;
    return jdata;
  }
}

class JDataDel {
  JGroupIdStatId jgroupIdStatId;
  int startTime;
  int endTime;
  JDataDel(GROUPIDS _groupId, STATIDS _statId, this.startTime, this.endTime)
      : jgroupIdStatId = JGroupIdStatId(_groupId, _statId);
  JDataDel.fromJson(Map<String, dynamic> json)
      : jgroupIdStatId = JGroupIdStatId.fromJson(json),
        startTime = json["StartTime"],
        endTime = json["EndTime"];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> jdata = jgroupIdStatId.toJson();
    jdata['StartTime'] = startTime;
    jdata['EndTime'] = endTime;
    return jdata;
  }
}

class JMsgObject extends MsgObject {
  int refNum = 0;
  int code = 0;
  dynamic data = Map();
  bool status = true;
  String message = "";
  Map<String, dynamic> jsonObject = Map<String, dynamic>();
  Logger? logger;

  JMsgObject(int objDom, int objId, this.code, this.refNum, this.data,
      [this.message = "", this.logger])
      : super(objDom, objId, "") {
    jsonObjectString = jsonEncode(thisToJson());
  }
  JMsgObject.fromBase(MsgObject mo)
      : super(mo.command, mo.objectId, mo.jsonObjectString) {
    try {
      fromJsonToThis(jsonDecode(jsonObjectString));
    } catch (e) {
      logger!.add(EVENTTYPE.ERROR, "JMsgObject::decode()",
          "field not found " + e.toString());
    }
  }

  fromJsonToThis(Map<String, dynamic> jsonObject) {
    // these have to be present
    code = jsonObject["code"];
    refNum = jsonObject["refNum"];
    // these may not be present
    data = Map();
    status = true;
    message = "";
    try {
      data = jsonObject["data"];
      status = jsonObject["status"];
      message = jsonObject["message"];
    } catch (e) {
      logger!.add(EVENTTYPE.ERROR, "JMsgObject::decode()",
          "field not found " + e.toString());
    }
  }

  Map<String, dynamic> thisToJson() {
    return {
      "code": code,
      "refNum": refNum,
      "data": data,
      "status": true,
      "message": message
    };
  }
}
