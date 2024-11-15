import 'dart:collection';
import 'dart:convert';

import '../CommonCppDartCode/Messages/MessagesCommon_generated.dart';
import 'JMsgObject.dart';
import '../RemoteDeviceMgr.dart';

enum EVENTTYPE {
  INIT,
  ERROR,
  EXCEPTION,
  WARNING,
  NOTE,
  INFO,
  CON,
  DBG,
  DBGDATA,
  STRING
}

enum EVENT {
  STARTED,
  ENDED,
}

enum SOURCE { LOCAL, REMOTE }

class LoggerPerformance {
  int opens = 0;
  int closes = 0;
  int errors = 0;
  int warnings = 0;
  int logs = 0;
  reset() {
    opens = 0;
    closes = 0;
    errors = 0;
    warnings = 0;
    logs = 0;
  }
}

class StateItem {
  final String value;
  final int domain;
  StateItem(this.value, this.domain);
}

class LoggerStateMap {
  SplayTreeMap<String, StateItem> _map = SplayTreeMap<String, StateItem>();
  add(String key, String value, int domain) {
    _map[key] = StateItem(value, domain);
  }

  fromJson(Map<String, dynamic> jsonMap) {
    _map.clear();
    jsonMap.forEach((key, value) {
      StateItem si = StateItem(value[0], value[1]);
      _map[key] = si;
    });
  }

  length() => _map.length;
  elementAt(int index) => _map.keys.elementAt(index);
  valueAt(String key) => _map[key]?.value.toString();
}

class LoggerEvent {
  final SOURCE source;
  final double timeMSecs;
  final EVENTTYPE type;
  final String name;
  final String description;
  final String file;
  final String function;
  final int line;
  final int value;
  double timeUTCMSecs = 0;
  final StackTrace current = StackTrace.current;

  LoggerEvent(
      this.timeMSecs, this.type, this.name, this.description, this.value)
      : this.source = SOURCE.LOCAL,
        this.file = "",
        this.function = "",
        this.line = 0;

  LoggerEvent.fromJson(var jsonList)
      : this.timeMSecs = jsonList[0] * 1000,
        this.type = EVENTTYPE.values[jsonList[1]],
        this.name = jsonList[2],
        this.description = jsonList[3],
        this.file = jsonList[4],
        this.function = jsonList[5],
        this.line = jsonList[6],
        this.value = jsonList[7],
        this.source = SOURCE.REMOTE {
    if (type == EVENTTYPE.INIT) {
      this.timeUTCMSecs = jsonList[8] * 1000;
    }
  }

  LoggerEvent.fromString(var _string)
      : this.timeMSecs = 0,
        this.type = EVENTTYPE.STRING,
        this.name = "",
        this.description = _string,
        this.value = 0,
        this.file = "",
        this.function = "",
        this.line = 0,
        this.source = SOURCE.REMOTE;

  String typeToString(EVENTTYPE type) {
    String string = "";
    switch (type) {
      case EVENTTYPE.INIT:
        string = " INIT:";
        break;
      case EVENTTYPE.ERROR:
        string = " ERR:";
        break;
      case EVENTTYPE.EXCEPTION:
        string = " EXC:";
        break;
      case EVENTTYPE.WARNING:
        string = " WAR:";
        break;
      case EVENTTYPE.NOTE:
        string = " NOTE:";
        break;
      case EVENTTYPE.INFO:
        string = " INFO:";
        break;
      case EVENTTYPE.CON:
        string = ">";
        break;
      case EVENTTYPE.STRING:
        string = "> ";
        break;
      case EVENTTYPE.DBG:
        string = " DBG:";
        break;
      case EVENTTYPE.DBGDATA:
        string = " DBGD:";
        break;
      default:
        string = " ???:";
        break;
    }
    return string;
  }

  toString() {
    double secs = timeMSecs / 1000.0;
    String log = "";
    if (source == SOURCE.REMOTE) {
      log = "R ";
      log += secs.toString();
    } else {
      log = secs.toString();
    }

    String typeAsString = typeToString(type);

    switch (type) {
      case EVENTTYPE.CON:
        log = typeAsString;
        log += description;
        return log;
      case EVENTTYPE.STRING:
        log += typeAsString;
        log += description;
        return log;
      default:
        break;
    }
    log += typeAsString;

    if (name != "") log += " " + name;
    if (description != "") log += ", " + description;
    if (file != "") log += ", " + file;
    if (function != "") {
      log += ", " + function + "()";
      log += ", #" + line.toString();
    }
    log += ", " + value.toString();
    if (type == EVENTTYPE.INIT) {
      double utcSecs = timeUTCMSecs / 1000.0;
      log += ", " + utcSecs.toString();
    }
    return log;
  }

  bool containsString(String word) {
    bool containes = false;
    if (name.toUpperCase().contains(word.toUpperCase())) containes = true;
    if (description.toUpperCase().contains(word.toUpperCase()))
      containes = true;
    if (file.toUpperCase().contains(word.toUpperCase())) containes = true;
    if (function.toUpperCase().contains(word.toUpperCase())) containes = true;
    String typeAsString = typeToString(type);
    if (typeAsString.toUpperCase().contains(word.toUpperCase()))
      containes = true;
    return containes;
  }
}

class Logger {
  static const int BOTEVENTLISTSIZE = 5000;
  List<LoggerEvent> dumpList = [];
  late Function() onSysErrorNotify;

  Queue<LoggerEvent> eventList = Queue<LoggerEvent>();
  SplayTreeMap<String, String> stateList = SplayTreeMap<String, String>();
  LoggerPerformance performance = LoggerPerformance();
  LoggerPerformance remotePerformance = LoggerPerformance();

  Stopwatch timer = Stopwatch();

  int testValue = 0;

  LoggerStateMap remoteStateMap = LoggerStateMap();
  RemoteDeviceMgr? _remoteDeviceMgr;

  Logger() {
    timer.start();
  }

  setup(Function() _onSysErrorNotify) {
    onSysErrorNotify = _onSysErrorNotify;
  }

  setDeviceMgr(RemoteDeviceMgr __deviceMgr) {
    _remoteDeviceMgr = __deviceMgr;
  }

  lateInit() {
    setStateInt("App-opens", ++performance.opens);
  }

  earlyDeinit() {
    setStateInt("App-closes", ++performance.closes);
  }

  void assertTrue(bool isTrue, String _name,
      [String _disc = "", int _value = 0]) {
    if (!isTrue) {
      add(EVENTTYPE.ERROR, _name, _disc, _value);
    }
  }

  bool add(EVENTTYPE _type, String _name, String _description,
      [int _value = 0]) {
    var event = new LoggerEvent(timer.elapsedMilliseconds.toDouble(), _type,
        _name, _description, _value);

    return addEvent(event);
  }

  bool addEvent(LoggerEvent event) {
    if (performance.errors > 0) return false; // no more events accepted/freeze

    if (event.type != EVENTTYPE.DBGDATA) {
      _newEventAdded = EVENTADDED;
      eventList.add(event);
    }

    dumpList.add(event);
    if (dumpList.length > 50) dumpList.removeAt(0);

    // limit length of list
    if (eventList.length > BOTEVENTLISTSIZE) {
      eventList.removeFirst();
    }
    processEvent(event);
    return true;
  }

  bool isAtMaxEventLength() {
    return eventList.length >= BOTEVENTLISTSIZE;
  }

  /// use a counter rather than a flag to make it pass two checks
  /// rather than 1, to avoid case its cleared between read and setting
  /// in checkAndResetNewEventAdded()
  /// Alternatively use a semaphore/event or stream for this. Counter is simpler.
  static const int EVENTADDED = 2;
  int _newEventAdded = 0;

  bool checkAndResetNewEventAdded() {
    bool update = _newEventAdded > 0;
    _newEventAdded = 0;
//    int _oldState = _newEventAdded;
//    _newEventAdded = _newEventAdded > 0 ? _newEventAdded -= 1 : 0;
//    return (_oldState != 0);
    return update;
  }

  clearLogs() {
    eventList.clear();
    _newEventAdded = EVENTADDED;
  }

  onMsg(MsgObject mo) {
    switch (mo.objectId) {
      case OBJ_LOGGER_LOGLINE:
        onMsgLogLine(mo);
        break;

      case OBJ_LOGGER_STATELIST:
        onMsgLogStateList(mo);
        break;

      case OBJ_LOGGER_COMMAND_TO_MATRIX:
        onMsgCommand(mo);
        break;

      case OBJ_LOGGER_JRESPONSE_FROM_MATRIX:
        onMsgResponse(mo);
        break;

      default:
        break;
    }
  }

  /// Use this to filter events and only receive events that meet a criteria
  /// This allows for removing clutter and focusing on events of interest
  filterAndAddEvent(LoggerEvent event) {
    //      if (event.type == EVENTTYPE.WARNING)
    addEvent(event);
  }

  onMsgLogLine(MsgObject mo) {
    try {
      if (mo.jsonObjectString[0] == "[") {
        // if this is json
        LoggerEvent event =
            LoggerEvent.fromJson(jsonDecode(mo.jsonObjectString));
        filterAndAddEvent(event);
      } else {
        add(EVENTTYPE.ERROR, "onMsgLogLine()", "LogEvent not a json string");
      }
    } catch (e) {
      add(EVENTTYPE.ERROR, "onMsgLogLine()",
          "Bad Msg Error detected in: Logger::onMsgLogLine()" + e.toString());
    }
  }

  onMsgLogStateList(MsgObject mo) {
    try {
      // if this is json
      remoteStateMap.fromJson(jsonDecode(mo.jsonObjectString));
    } catch (e) {
      add(
          EVENTTYPE.ERROR,
          "onMsgLogStateList()",
          "Bad Msg Error detected in: Logger::onMsgLogStateList()" +
              e.toString());
    }
  }

  onMsgCommand(MsgObject mo) {
    try {
      // if this is json
      String response = mo.jsonObjectString;
      add(EVENTTYPE.INFO, "Logger::onMsgCommand()",
          "received a command response " + response);
    } catch (e) {
      add(EVENTTYPE.ERROR, "onMsgCommand()",
          "Bad Msg Error detected in: Logger::onMsgCommand()" + e.toString());
    }
  }

  onMsgResponse(MsgObject mo) {
    try {
      // if this is json
      String response = mo.jsonObjectString;
      add(EVENTTYPE.INFO, "Logger::onMsgResponse()",
          "received a command response " + response);
    } catch (e) {
      add(EVENTTYPE.ERROR, "onMsgResponse()",
          "Bad Msg Error detected in: Logger::onMsgResponse()" + e.toString());
    }
  }

  showDbgData() {
    dumpLast50("Debug Data");
  }

  onSysError() {
    dumpLast50("SYSERROR");
    try {
      onSysErrorNotify();
    } catch (e) {}
    // if (onSysErrorNotify != null) onSysErrorNotify();
  }

  /// request logs from matrix
  ///
  bool requestLogs() {
    /// Format for requesting logs
    if (_remoteDeviceMgr == null) return false;
    Map<String, dynamic> requestLogsData = {"eventLevel": 3, "eventFlags": 0x4};

    int requestLogsNumber = 0;
    JMsgObject jMsgObject = JMsgObject(OBJ_LOGGER, OBJ_LOGGER_COMMAND_TO_MATRIX,
        OBJ_LOGGER_JCOMMAND_REQUEST_LOGS, requestLogsNumber, requestLogsData);

    bool stat = false;
    stat = _remoteDeviceMgr!.sendMsg(jMsgObject);
    return stat;
  }

  bool deleteRemoteLogs() {
    /// Format for requesting logs
    if (_remoteDeviceMgr == null) return false;
    Map<String, dynamic> deleteLogsData = {"all": true};

    JMsgObject jMsgObject = JMsgObject(OBJ_LOGGER, OBJ_LOGGER_COMMAND_TO_MATRIX,
        OBJ_LOGGER_JCOMMAND_DELETE_LOGS, 0, deleteLogsData);

    bool stat = false;
    stat = _remoteDeviceMgr!.sendMsg(jMsgObject);
    return stat;
  }

  bool processEvent(LoggerEvent botEvent) {
    if (botEvent.type != EVENTTYPE.DBGDATA)
      setStateInt("App-logs", ++performance.logs);

    switch (botEvent.type) {
      case EVENTTYPE.ERROR:
        if (botEvent.source == SOURCE.LOCAL) {
          setStateInt("App-errors", ++performance.errors);
          onSysError();
        } else {
          setStateInt("Rem-errors", ++remotePerformance.errors);
        }
        break;
      case EVENTTYPE.WARNING:
        if (botEvent.source == SOURCE.LOCAL)
          setStateInt("App-warnings", ++performance.warnings);
        else
          setStateInt("Rem-warnings", ++remotePerformance.warnings);
        break;
      case EVENTTYPE.INFO:
        break;
      default:
        break;
    }
    return true;
  }

  void setStateInt(String keyName, int value) {
    stateList[keyName] = value.toString();
  }

  void setStateString(String keyName, String value) {
    stateList[keyName] = value;
  }

  void dumpLast50(String title) {
    eventList.add(LoggerEvent(
        timer.elapsedMilliseconds.toDouble(), EVENTTYPE.CON, "", title, 0));
    print(title);
    for (int i = 0; i < dumpList.length; i++) {
      var be = dumpList[i];
      print(be.toString());
      eventList.add(LoggerEvent(timer.elapsedMilliseconds.toDouble(),
          EVENTTYPE.CON, "", be.toString(), 0));
    }
  }
}
