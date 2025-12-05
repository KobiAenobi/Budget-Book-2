import 'dart:async';
import 'dart:developer';

import 'package:budget_book_app/apis/api.dart';
import 'package:budget_book_app/helper/appBar.dart';
import 'package:budget_book_app/models/budget_item.dart';
import 'package:budget_book_app/services/firestore_service.dart';
import 'package:budget_book_app/services/sync_service.dart';
import 'package:budget_book_app/widgets/add_item_dialog_box.dart';
import 'package:budget_book_app/widgets/item_card.dart';
import 'package:budget_book_app/widgets/month_card.dart';
import 'package:budget_book_app/widgets/top_card1.dart';
import 'package:budget_book_app/widgets/top_card2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/adapters.dart';

/// ===============================================================
/// HOMESCREEN (Main Dashboard UI)
/// ---------------------------------------------------------------
/// This screen:
/// - Displays all budget items from Hive
/// - Shows total expense
/// - Provides edit & delete via Slidable
/// - Provides Add button (FAB)
/// - Periodically refreshes to update timestamps
/// - (Commented) Handles Android overlay → Flutter communication
/// ===============================================================
class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  //Page view controller
  final _pageViewController = PageController();

  // ---------------------------------------------------------------
  // (COMMENTED OUT) Android overlay channel:
  // This is the MethodChannel used to receive data from overlay.
  // It's currently disabled, but kept intact as you requested.
  // ---------------------------------------------------------------
  // static const overlayChannel = MethodChannel("overlay_channel");

  /// =============================================================
  /// EDIT ITEM FUNCTION
  /// -------------------------------------------------------------
  /// Opens the AddItemDialogBox in "edit mode".
  /// After editing, updates the Hive object directly.
  /// Hive objects are linked — `item.save()` triggers auto-update.
  /// =============================================================
  // void _editItem(BudgetItem item, int index) async {
  //   final result = await showDialog(
  //     context: context,
  //     builder: (_) => AddItemDialogBox(
  //       existingName: item.name,
  //       existingQuantity: item.quantity.toString(),
  //       existingPrice: item.price.toString(),
  //       isEditing: true, // <- Dialog knows this is an update
  //     ),
  //   );

  //   if (result != null) {
  //     // Apply updates to the existing Hive object
  //     item.name = result["name"];
  //     item.quantity = result["quantity"];
  //     item.price = result["price"];

  //     item.save(); // <-- HIVE AUTO-UPDATE
  //   }
  // }

  //FORMMATTED MONTH AND YEAR FOR THE LISTVIEWBUILDER
  String formatMonth(String key) {
    final year = int.parse(key.split('-')[0]);
    final month = int.parse(key.split('-')[1]);

    const monthNames = [
      "", // index 0 unused
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return "${monthNames[month]} $year";
  }

  void _editItem(BudgetItem item) async {
    final BudgetItem? updated = await showDialog(
      context: context,
      builder: (_) => AddItemDialogBox(
        isEditing: true,
        existingItem: item,
        existingName: item.name,
        existingQuantity: item.quantity.toString(),
        existingPrice: item.price.toString(),
      ),
    );

    if (updated != null) {
      itemsBox.put(updated.id, updated); // local
      setState(() {});
    }

    try {
      final service = await FirestoreService.forCurrentUser();
      await service.updateItem(updated!);
    } catch (e) {
      log('Failed update: $e');
    }
  }

  void _handleDeepLink() {
    final uri = Uri.base;

    if (uri.scheme == "budgetbook" &&
        uri.host == "dialog" &&
        uri.path == "/addItem") {
      // Open the dialog
      showDialog(context: context, builder: (_) => const AddItemDialogBox());
    }
  }

  /// Hive box reference
  final itemsBox = Hive.box<BudgetItem>('itemsBox');

  /// Periodic UI update timer (for timestamp refresh)
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLink();

      // NEW: start local-to-cloud sync listener
      if (FirebaseAuth.instance.currentUser != null) {
        listenForLocalChanges();
      }
    });

    // =============================================================
    // ⏱ Periodic UI refresh
    // -------------------------------------------------------------
    // This triggers every minute to update timestamps like:
    // "Added 5 minutes ago", "Added 1 hour ago", etc.
    // =============================================================
    _timer = Timer.periodic(Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // Cancel periodic refresh timer
    _timer?.cancel();
    super.dispose();
  }

  /// =============================================================
  /// BUILD METHOD — MAIN UI
  /// =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 44, 16, 16),

      // =============================================================
      // APP BAR (Custom Widget)
      // =============================================================
      appBar: customAppBar(title: "Budget Book"),

      // =============================================================
      // BODY — Item List + Summary Card
      // =============================================================
      body: ValueListenableBuilder(
        valueListenable: itemsBox.listenable(), // Rebuild on Hive change
        builder: (context, Box<BudgetItem> box, _) {
          // ---------------------------------------------------------
          // Empty State
          // ---------------------------------------------------------
          if (box.isEmpty) {
            return Center(child: Text("No Items Yet"));
          }

          // ---------------------------------------------------------
          // Convert Hive box to list & sort newest → oldest
          // ---------------------------------------------------------
          final items = box.values.toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

          final grouped = Api.groupItemsByMonth(items);

          final List<dynamic> displayList = [];

          final Map<String, int> monthlyTotal ={};

          // grouped.forEach((monthKey, montItem){
          //   montlyTotal.add(monthKey);
          //   montlyTotal.addAll(montItem.price)
          // });

          grouped.forEach((monthKey, monthItem) {

            int total = monthItem.fold(0, (sum, item)=> sum + (item.price* item.quantity));
            monthlyTotal[monthKey]=total;

            displayList.add(monthKey);
            displayList.addAll(monthItem);
          });

          // =========================================================
          // MAIN COLUMN
          // =========================================================
          return Column(
            children: [
              // =======================================================
              // TOP CARD → Total Expense Summary
              // =======================================================
              Expanded(
                flex: 3,
                child: Card(
                  margin: EdgeInsets.only(bottom: 0, top: 5, left: 0, right: 0),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: const Color.fromARGB(255, 105, 99, 97),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: const Color.fromARGB(255, 24, 8, 2),
                  //PAGEVIEW
                  child: PageView(
                    controller: _pageViewController,
                    children: [TopCard1(), TopCard2()],
                  ),
                ),
              ),

              // =======================================================
              // BOTTOM — LIST OF ITEMS
              // =======================================================
              Expanded(
                flex: 7,
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: 80, top: 5),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    // final item = items[index];

                    final entry = displayList[index];

                    //IF THE entry IS A STRING MEANING THE MONTH AND YEAR STRING FORM displayList
                    if (entry is String) {
                      // Hide the first month header
                      if (index == 0) {
                        return SizedBox.shrink();
                      }
                      // return MonthCard(month: formatMonth(entry));
                      return MonthCard(month: formatMonth(entry), total: monthlyTotal[entry]??0);
                    }
                    //IF THE entry IS A ITEM FROM BudgetItem
                    else {
                      final item = entry;

                      // ===================================================
                      // WRAPPED IN SLIDABLE → Swipe Left for Edit/Delete
                      // ===================================================
                      return Slidable(
                        key: ValueKey(item.id),

                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            // EDIT
                            SlidableAction(
                              onPressed: (context) => _editItem(item),
                              backgroundColor: const Color.fromARGB(
                                255,
                                44,
                                16,
                                16,
                              ),
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                          ],
                        ),
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            // DELETE
                            SlidableAction(
                              onPressed: (context) async {
                                // itemsBox.delete(item.key);
                                itemsBox.delete(item.id); // local

                                // remote
                                try {
                                  final service =
                                      await FirestoreService.forCurrentUser();
                                  await service.deleteItem(item.id);
                                } catch (e) {
                                  log('Failed remote delete: $e');
                                }
                              },
                              backgroundColor: const Color.fromARGB(
                                255,
                                44,
                                16,
                                16,
                              ),
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),

                        // ITEM UI CARD (Custom Widget)
                        child: ItemCard(
                          name: item.name,
                          date: item.dateTime,
                          quantity: item.quantity,
                          price: item.price,
                          onEdit: () {
                            _editItem(item);
                          },
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),

      // =============================================================
      // ➕ FLOATING ACTION BUTTON (Add New Item)
      // =============================================================
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        child: Icon(Icons.add),

        // onPressed: () async {
        //   final result = await showDialog(
        //     context: context,
        //     builder: (_) => AddItemDialogBox(),
        //   );

        //   if (result != null) {
        //     final item = BudgetItem(
        //       id: DateTime.now().millisecondsSinceEpoch.toString(),
        //       name: result["name"],
        //       quantity: result["quantity"],
        //       price: result["price"],
        //       dateTime: result["date"],
        //       imagePath: "",
        //     );

        //     itemsBox.add(item); // Save to Hive
        //     log('Saved item: ${item.id}');

        //     setState(() {}); // Refresh UI
        //   }
        // },
        onPressed: () async {
          final BudgetItem? item = await showDialog(
            context: context,
            builder: (_) => AddItemDialogBox(isEditing: false),
          );

          if (item != null) {
            // Save locally first
            itemsBox.put(item.id, item); // Save using ID as key
            log('Saved item: ${item.id}');
            setState(() {});

            // Then upload in background
            try {
              final service = await FirestoreService.forCurrentUser();
              await service.uploadItem(item);
              log('Uploaded item ${item.id} to Firestore');
            } catch (e) {
              log('Failed upload: $e');
              // optionally mark item as pending in Hive
            }
          }
        },
      ),
    );
  }
}
