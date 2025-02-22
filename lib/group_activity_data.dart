import 'dart:async';
import 'package:synchronized/synchronized.dart';
import 'CommonCppDartCode/Messages/HyperCubeMessagesCommon_generated.dart';

class GroupActivityData {
  final GroupToCommandInfo mapGroupNameToCommands = GroupToCommandInfo();

  Future<CommonInfoBase?> add(String groupName, HYPERCUBECOMMANDS command,
      CommonInfoBase commandInstanceInfo) async {
    return mapGroupNameToCommands.add(groupName, command, commandInstanceInfo);
  }

  Future<CommonInfoBase?> removeWait(
      String groupName, HYPERCUBECOMMANDS command,
      {int timeoutMsSecs = 0}) async {
    return mapGroupNameToCommands.removeWait(groupName, command,
        timeoutMsSecs: timeoutMsSecs);
  }

  Future<CommonInfoBase?> findWait(
      String groupName, HYPERCUBECOMMANDS command, String uuid,
      {int timeoutMsSecs = 0}) async {
    return mapGroupNameToCommands.findWait(groupName, command, uuid,
        timeoutMsSecs: timeoutMsSecs);
  }

  Future<bool> contains(String groupName) {
    return mapGroupNameToCommands.contains(groupName);
  }

  Future<bool> erase(String groupName) {
    return mapGroupNameToCommands.erase(groupName);
  }
}

class GroupToCommandInfo {
  final Map<String, CommandsToCommandInstances> _groupToCommandInfo = {};
  final _lock = Lock();

  Future<CommonInfoBase?> add(String groupName, HYPERCUBECOMMANDS command,
      CommonInfoBase commandInstanceInfo) async {
    return await _lock.synchronized(() async {
      CommandsToCommandInstances? commandToCommandInstances =
          _groupToCommandInfo[groupName];
      if (commandToCommandInstances == null) {
        commandToCommandInstances = CommandsToCommandInstances();
        _groupToCommandInfo[groupName] = commandToCommandInstances;
      }
      return await commandToCommandInstances.add(command, commandInstanceInfo);
    });
  }

  Future<CommonInfoBase?> removeWait(
      String groupName, HYPERCUBECOMMANDS command,
      {int timeoutMsSecs = 0}) async {
    return await _lock.synchronized(() async {
      CommandsToCommandInstances? commandsMap = _groupToCommandInfo[groupName];

      if (commandsMap == null) {
        return null;
      }
      return await commandsMap.removeWait(command,
          timeoutMsSecs: timeoutMsSecs);
    });
  }

  Future<CommonInfoBase?> findWait(
      String groupName, HYPERCUBECOMMANDS command, String uuid,
      {int timeoutMsSecs = 0}) async {
    return await _lock.synchronized(() async {
      CommandsToCommandInstances? commandToCommandInstances =
          _groupToCommandInfo[groupName];

      if (commandToCommandInstances == null) {
        return null;
      }
      return await commandToCommandInstances.findWait(command, uuid,
          timeoutMsSecs: timeoutMsSecs);
    });
  }

  Future<bool> contains(String groupName) async {
    return await _lock.synchronized(() {
      return _groupToCommandInfo.containsKey(groupName);
    });
  }

  Future<bool> erase(String groupName) async {
    return await _lock.synchronized(() {
      return _groupToCommandInfo.remove(groupName) != null;
    });
  }
}

class CommandsToCommandInstances {
  final Map<HYPERCUBECOMMANDS, CommandInstanceList> _commands = {};
  final _lock = Lock();

  Future<CommonInfoBase?> add(
      HYPERCUBECOMMANDS command, CommonInfoBase commandInstanceInfo) async {
    return await _lock.synchronized(() async {
      CommandInstanceList? commandInstanceList = _commands[command];
      if (commandInstanceList == null) {
        commandInstanceList = CommandInstanceList();
        _commands[command] = commandInstanceList;
      }
      return await commandInstanceList.add(commandInstanceInfo);
    });
  }

  Future<CommonInfoBase?> removeWait(HYPERCUBECOMMANDS command,
      {int timeoutMsSecs = 0}) async {
    return await _lock.synchronized(() async {
      CommandInstanceList? commandInstanceList = _commands[command];

      if (commandInstanceList == null) {
        return null;
      }
      return await commandInstanceList.removeWait(timeoutMsSecs: timeoutMsSecs);
    });
  }

  Future<CommonInfoBase?> findWait(HYPERCUBECOMMANDS command, String uuid,
      {int timeoutMsSecs = 0}) async {
    return await _lock.synchronized(() async {
      CommandInstanceList? commandInstanceList = _commands[command];
      if (commandInstanceList == null) {
        return null;
      }
      return await commandInstanceList.findWait(uuid,
          timeoutMsSecs: timeoutMsSecs);
    });
  }
}

class CommandInstanceList {
  final List<CommonInfoBase> _list = [];
  final Map<String, int> _uuidToIndexMap = {}; // Store UUIDs and their index
  final _lock = Lock();
  Completer<void> _activityIn = Completer<void>();

  Future<CommonInfoBase?> add(CommonInfoBase commandInstanceInfo) async {
    return await _lock.synchronized(() async {
      try {
        _list.add(commandInstanceInfo);
        _uuidToIndexMap[commandInstanceInfo.uuid] = _list.length - 1;
        if (!_activityIn.isCompleted) {
          _activityIn.complete(); // Signal that data is available
        }
        return commandInstanceInfo;
      } catch (e) {
        return null;
      }
    });
  }

  Future<CommonInfoBase?> removeWait({int timeoutMsSecs = 0}) async {
    if (timeoutMsSecs > 0) {
      // Use a Timer to simulate a timeout
      bool timedOut = false;
      Timer? timer;
      final timeoutCompleter = Completer<void>();

      timer = Timer(Duration(milliseconds: timeoutMsSecs), () {
        timedOut = true;
        if (!timeoutCompleter.isCompleted) {
          timeoutCompleter.complete();
        }
      });

      await Future.any([
        _activityIn.future,
        timeoutCompleter.future,
      ]);

      timer.cancel(); // Cancel the timer if it hasn't already timed out

      if (timedOut) {
        return null; // Timed out
      }
    } else {
      // Wait indefinitely for activity
      await _activityIn.future;
    }

    return await _lock.synchronized(() async {
      if (_list.isEmpty) {
        return null;
      }
      try {
        final commandInstanceInfo = _list.removeAt(0);
        _uuidToIndexMap.remove(commandInstanceInfo.uuid);
        // Reset _activityIn if the list is now empty
        if (_list.isEmpty) {
          _resetActivityIn();
        }
        return commandInstanceInfo;
      } catch (e) {
        return null;
      }
    });
  }

  Future<CommonInfoBase?> findWait(String uuid, {int timeoutMsSecs = 0}) async {
    if (timeoutMsSecs > 0) {
      // Use a Timer to simulate a timeout
      bool timedOut = false;
      Timer? timer;
      final timeoutCompleter = Completer<void>();

      timer = Timer(Duration(milliseconds: timeoutMsSecs), () {
        timedOut = true;
        if (!timeoutCompleter.isCompleted) {
          timeoutCompleter.complete();
        }
      });

      await Future.any([
        _activityIn.future,
        timeoutCompleter.future,
      ]);

      timer.cancel(); // Cancel the timer if it hasn't already timed out

      if (timedOut) {
        return null; // Timed out
      }
    } else {
      // Wait indefinitely for activity
      await _activityIn.future;
    }

    return await _lock.synchronized(() async {
      if (_uuidToIndexMap.containsKey(uuid) == false) {
        return null;
      }

      try {
        final index = _uuidToIndexMap[uuid]!;
        final commandInstanceInfo = _list.removeAt(index);
        _uuidToIndexMap.remove(uuid);
        // Reset _activityIn if the list is now empty
        if (_list.isEmpty) {
          _resetActivityIn();
        }
        return commandInstanceInfo;
      } catch (e) {
        return null;
      }
    });
  }

  void _resetActivityIn() {
    if (_activityIn.isCompleted) {
      _activityIn = Completer<void>();
    }
  }
}
