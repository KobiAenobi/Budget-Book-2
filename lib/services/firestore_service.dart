import 'package:budget_book_app/models/budget_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService._(this.uid);

  static Future<FirestoreService> forCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    return FirestoreService._(user!.uid);
  }

  CollectionReference<Map<String, dynamic>> get _budgets => _db.collection('users').doc(uid).collection('budgets');

  Future<void> uploadItem(BudgetItem item) async{
    await _budgets.doc(item.id).set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> updateItem(BudgetItem item) async{
    await _budgets.doc(item.id).update(item.toMap());
  }

  Future<void> deleteItem(String id) async{
    await _budgets.doc(id).delete();
  }

  Future<List<BudgetItem>> fetchAllItems() async {
    final snap = await _budgets.get();
    return snap.docs.map((d) => BudgetItem.fromMap(d.data())).toList();
  }




  Stream<List<BudgetItem>> listenToRemoteChanges(){
    return _budgets.snapshots().map((snap){
      return snap.docs.map((d)=> BudgetItem.fromMap(d.data())).toList();
    });
  }


//   Future<void> initialSync() async {
//   final service = await FirestoreService.forCurrentUser();
//   final remote = await service.fetchAllItems();
//   final box = Hive.box<BudgetItem>('itemsBox');

//   for (final r in remote) {
//     final local = box.get(r.id);
//     if (local == null) {
//       // remote item missing locally -> add
//       box.put(r.id, r);
//     } else {
//       // conflict resolution by last-write-wins using dateTime
//       if (r.dateTime.isAfter(local.dateTime)) {
//         box.put(r.id, r);
//       }
//     }
//   }
// }


}