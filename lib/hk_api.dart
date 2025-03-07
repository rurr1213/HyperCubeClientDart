import 'CommonCppDartCode/dart/utils.dart';
import 'CommonCppDartCode/Messages/HyperCubeMessagesCommon_generated.dart';

abstract class HKIAPI {
  StringUuid? publish(String groupName, String data, {bool ack = true});
  Future<String> publishAndWait(String groupName, String data);
  bool createGroup(GroupInfo groupInfo);
  bool destroyGroup(GroupInfo groupInfo);
  bool subscribe(SubscriberInfo subscriberInfo);
  bool unsubscribe(SubscriberInfo subscriberInfo);
}
