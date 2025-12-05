import 'dart:developer' show log;

import 'package:budget_book_app/screens/activities.dart';
import 'package:budget_book_app/screens/homeScreen.dart';
import 'package:budget_book_app/services/sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountSettingsDialog {
  final currUser = FirebaseAuth.instance.currentUser;

  // static ChatUser me;
  void showAccountSettingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(255, 24, 8, 2),
          insetPadding: EdgeInsets.only(top: 60, right: 10),
          alignment: Alignment.topRight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: SingleChildScrollView(
            child: Container(
              // color: Colors.amber,
              width: 320,
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== MAIN ACCOUNT HEADER =====
                  InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: () {
                      // Navigator.pop(context);

                      // Navigator.pop(context);
                      log("user name clicked");
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,

                          // backgroundImage:NetworkImage(currUser!.photoURL.toString()),
                          // child:Icon(Icons.person),
                          backgroundImage: currUser?.photoURL != null
                              ? NetworkImage(currUser!.photoURL!)
                              : null,
                          child: currUser?.photoURL == null
                              ? Icon(Icons.person, color: Colors.white70)
                              : null,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currUser?.displayName ?? "Guest",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currUser?.email ?? "guest",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),
                  Divider(),

                  // ===== MANAGE =====
                  InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: () {
                      _handleLoginButtonClick();

                      // Navigator.pushReplacement(
                      //   context,
                      //   MaterialPageRoute(builder: (_) => Homescreen()),
                      // );
                      Navigator.pop(context, MaterialPageRoute(builder: (_)=> Homescreen()));

                      // Navigator.pop(context);
                      log("Manage account");
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          "Manage your Google Account",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Divider(),

                  // ===== Settings Tiles =====
                  otherTile(
                    "Budget Book Settings",
                    Icons.settings,
                    context,
                    Activities(),
                  ),

                  // SizedBox(height: 16),
                  Divider(),

                  
                  Row(
                    children: [
                      // ===== SIGN OUT =====
                      Flexible(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(7),
                          onTap: () {
                            signOut();
                        
                            Navigator.pop(context);
                            log("Sign out Clicked");
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: SizedBox(
                              // width: double.infinity,
                              child: Text(
                                "Sign out",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 10,),
                      // ===== Sync =====
                  Flexible(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(7),
                      onTap: () {
                        syncLocalItemsToCloud();
                        // migrateKeysToId();
                    
                        Navigator.pop(context);
                        log("Sync Data Clicked");
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          // width: double.infinity,
                          child: Text(
                            "Sync Data",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                    ],
                  ),

                  
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget otherTile(String name, IconData Iconss, BuildContext context, screen) {
  return InkWell(
    borderRadius: BorderRadius.circular(7),
    onTap: () {
      log("Switched to");
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Iconss, color: Colors.white60),
          SizedBox(width: 14),
          Text(
            name,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

/// --------------------- Login Logic ---------------------
_handleLoginButtonClick() {
  signInWithGoogle().then((user) async {
    if (user != null) {
      log('\nUser: ${user.user}');
      log('\nUserAdditionalInfo: ${user.additionalUserInfo}');

      // ⭐ RUN INITIAL SYNC AFTER LOGIN
      await initialSync(); // Cloud -> Local
      await syncLocalItemsToCloud(); // Local -> Cloud

      // OPTIONAL: Also start realtime listener
      // startRemoteListener();
    } else {
      log('\nLogin canceled by user');
    }
  });
}

Future<UserCredential?> signInWithGoogle() async {
  await GoogleSignIn.instance.initialize();

  try {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    // if (googleUser == null) return null;

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (e) {
    log('\nCANCELLED LOGIN');
    // Dialogs.showSnackbar(context, 'Something went wrong! Try again...');
    return null;
  }
}

Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
  await GoogleSignIn.instance.signOut();
  await GoogleSignIn.instance.disconnect();
}

// Future<void> migrateKeysToId() async {
//   final box = Hive.box<BudgetItem>('itemsBox');

//   final oldKeys = <dynamic>[];

//   for (var key in box.keys) {
//     final item = box.get(key);
//     if (item == null) continue;

//     // If the key is NOT the item.id, migrate it
//     if (key != item.id) {
//       await box.put(item.id, item);
//       oldKeys.add(key);
//     }
//   }

//   for (var k in oldKeys) {
//     await box.delete(k);
//   }
// }
