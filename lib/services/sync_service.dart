import 'dart:developer' show log;

import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_item.dart';

Future<User> signInAnonymouslyIfNeeded() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    final cred = await auth.signInAnonymously();
    return cred.user!;
  }
  return auth.currentUser!;
}

Future<void> initialSync() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final db = FirebaseFirestore.instance;

  final box = Hive.box<BudgetItem>('itemsBox');

  final snap = await db
      .collection('users')
      .doc(uid)
      .collection('budgets')
      .get();

  for (var doc in snap.docs) {
    final data = doc.data();
    final item = BudgetItem.fromMap(data);
    final local = box.get(item.id);

    if (local == null || item.dateTime.isAfter(local.dateTime)) {
      box.put(item.id, item);
    }
  }
}

Future<void> syncLocalItemsToCloud() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final db = FirebaseFirestore.instance;
  final box = Hive.box<BudgetItem>('itemsBox');

  // 1. Get cloud items
  final remoteSnap = await db
      .collection('users')
      .doc(uid)
      .collection('budgets')
      .get();

  final remoteIds = remoteSnap.docs.map((d) => d.id).toSet();

  // 2. Upload all local items that are missing in Cloud
  for (var localItem in box.values) {
    if (!remoteIds.contains(localItem.id)) {
      await db
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(localItem.id)
          .set(localItem.toMap());

      log("Uploaded missing local item: ${localItem.id}");
    }
  }
}


void listenForLocalChanges() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final box = Hive.box<BudgetItem>('itemsBox');

  box.watch().listen((event) async {
    final item = box.get(event.key);
    if (item == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(item.id)
        .set(item.toMap(), SetOptions(merge: true));

    log("🔥 Synced new/updated item from overlay: ${item.id}");
  });
}

Future<void> migrateUuidToDateTimeIds() async {
  final box = Hive.box<BudgetItem>('itemsBox');

  final keysToDelete = <dynamic>[];

  for (final key in box.keys) {
    final item = box.get(key);
    if (item == null) continue;

    // New ID from dateTime
    final newId = item.dateTime.millisecondsSinceEpoch.toString();

    // If key is already correct → skip
    if (key == newId) {
      continue;
    }

    // Otherwise → re-save using the new DateTime ID
    await box.put(newId, BudgetItem(
      id: newId,
      name: item.name,
      quantity: item.quantity,
      price: item.price,
      dateTime: item.dateTime,
      imagePath: item.imagePath,
    ));

    // Mark old entry for deletion
    keysToDelete.add(key);
  }

  // Remove old UUID entries
  for (final key in keysToDelete) {
    await box.delete(key);
  }

  log("UUID → DateTime migration complete");
}



