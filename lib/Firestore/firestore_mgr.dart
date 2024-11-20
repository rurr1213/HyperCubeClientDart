import 'firestore_access.dart' as db;
import 'package:firedart/firedart.dart';
import '../Tools/logger.dart';


class FirestoreMgr {
  static final FirestoreMgr _instance = FirestoreMgr._internal();
  FirebaseAuth? firebaseAuthConnection;

  factory FirestoreMgr() {
    return _instance;
  }

  FirestoreMgr._internal() {
    fireDartInit();
  }

  Future<bool> fireDartInit() async {
    if (!FirebaseAuth.initialized) {
      try {
        FirebaseAuth.initialize(db.apiKey, VolatileStore());
        Logger().addInfo("Firebase initialized");
      } catch (e) {
        Logger().add(EVENTTYPE.WARNING, "auth_Mgr/fireDartInit",
            "FireAuth Init Fail:$e");
        return false;
      }
    }
    if (!Firestore.initialized) {
      try {
        Firestore.initialize(db.projectId); // Firestore reuses the auth client
        Logger().addInfo("Firestore initialized");
      } catch (e) {
        Logger().add(EVENTTYPE.WARNING, "auth_Mgr/fireDartInit",
            "FireStore Init Fail:$e");
        return false;
      }
    }
    firebaseAuthConnection = FirebaseAuth.instance;
    return true;
  }

  void attemptSignIn({required String email, required String pass,}) async {
    try {
      var tempUser = await firebaseAuthConnection?.signIn(email, pass);
      if (firebaseAuthConnection!.isSignedIn && tempUser != null) {
        var currUser = tempUser;
        Logger().addInfo("SignIn Sucess: ${currUser.toString()}");
        //pass Condition
        //return true;
        return;
      }
    } catch (e) {
      Logger().addWarning("Auth/AuthMgr/attemptSignIn", "Try failed: $e");
      if (e.toString() == "AuthException: INVALID_PASSWORD") {
        Logger().addError("Invalid Password");
      } else if (e.toString() == "AuthException: INVALID_EMAIL") {
        Logger().addError("Email Not Found");
      } else {
        Logger().addError("Failed error ident: Sign In: ${e.toString()}");
      }
      return;
    }
    // return false;
    return;
  }

}
