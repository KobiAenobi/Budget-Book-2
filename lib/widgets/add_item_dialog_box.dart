import 'package:budget_book_app/models/budget_item.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// ============================================================================
/// ➕ ADD ITEM DIALOG BOX
/// ----------------------------------------------------------------------------
/// This dialog is used for BOTH:
///   • Adding a new budget item
///   • Editing an existing one (via isEditing flag)
///
/// Features:
///  - Autocomplete for item name (based on Hive data)
///  - Auto-fill quantity & price when selecting an existing item
///  - Pre-fills fields when editing
///  - Returns a map of details back to the caller
///
/// NOTHING has been changed. Only comments added.
/// ============================================================================
class AddItemDialogBox extends StatefulWidget {
  final BudgetItem? existingItem; // ← ADD THIS
  final String? existingName;
  final String? existingQuantity;
  final String? existingPrice;
  final bool isEditing;

  const AddItemDialogBox({
    super.key,
    this.existingItem, // ← ADD THIS
    this.existingName,
    this.existingQuantity,
    this.existingPrice,
    this.isEditing = false,
  });

  @override
  State<AddItemDialogBox> createState() => _AddItemDialogBoxState();
}

class _AddItemDialogBoxState extends State<AddItemDialogBox> {
  /// Hive box reference for stored items
  final itemsBox = Hive.box<BudgetItem>('itemsBox');

  /// Text controllers for input fields
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController quantityCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  /// ==========================================================================
  /// initState()
  /// --------------------------------------------------------------------------
  /// Preloads values based on whether user is editing or adding.
  /// When adding: default quantity = "1"
  /// ==========================================================================
  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      // Pre-fill values when editing item
      nameCtrl.text = widget.existingName ?? "";
      quantityCtrl.text = widget.existingQuantity ?? "";
      priceCtrl.text = widget.existingPrice ?? "";
    } else {
      // Default quantity for new item
      quantityCtrl.text = "1"; // by default quantity text field has 1
    }
  }

  /// ==========================================================================
  /// dispose()
  /// --------------------------------------------------------------------------
  /// Controller cleanup
  /// ==========================================================================
  @override
  void dispose() {
    nameCtrl.dispose();
    quantityCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  /// ==========================================================================
  /// build()
  /// --------------------------------------------------------------------------
  /// Creates the dialog UI:
  ///   • Autocomplete field for item name
  ///   • Quantity + Price fields
  ///   • Cancel / Add or Save buttons
  /// ==========================================================================
  @override
  Widget build(BuildContext context) {
    /// Suggestions list (unique item names)
    final List<String> suggestions = itemsBox.values
        .map((e) => e.name)
        .toSet()
        .toList();

    return AlertDialog(
      backgroundColor: Colors.black,

      content: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Title
            Text(widget.isEditing ? 'Edit Item' : 'Add Item'),

            // ==================================================================
            // ITEM NAME FIELD — USING AUTOCOMPLETE
            // ==================================================================
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                // No input? No suggestions.
                if (value.text.isEmpty) return const Iterable<String>.empty();

                // Case-insensitive matching
                return suggestions.where(
                  (name) =>
                      name.toLowerCase().contains(value.text.toLowerCase()),
                );
              },

              onSelected: (selection) {
                // Set selected name
                nameCtrl.text = selection;

                /// Try to auto-fill based on previously saved item
                BudgetItem? existing;

                try {
                  existing = itemsBox.values.firstWhere(
                    (item) => item.name == selection,
                  );
                } catch (e) {
                  existing = null;
                }

                if (existing != null) {
                  priceCtrl.text = existing.price.toString();
                  quantityCtrl.text = existing.quantity.toString();
                }

                // Additional loop-based match (kept exactly as written)
                BudgetItem? matchedItem;

                for (var item in itemsBox.values) {
                  if (item.name.toLowerCase() == selection.toLowerCase()) {
                    matchedItem = item;
                    break;
                  }
                }

                if (matchedItem != null) {
                  priceCtrl.text = matchedItem.price.toString();
                  quantityCtrl.text = matchedItem.quantity.toString();
                }
              },

              // ==================================================================
              // FIELD VIEW BUILDER — Custom handling of TextField
              // ==================================================================
              fieldViewBuilder:
                  (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    // Sync internal Autocomplete controller ONCE
                    if (textEditingController.text.isEmpty) {
                      textEditingController.text = nameCtrl.text;
                    }

                    return TextField(
                      controller: nameCtrl, // YOUR BASE CONTROLLER (respected)
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: "Name"),

                      // Sync internal Autocomplete controller on every change
                      onChanged: (value) {
                        textEditingController.value = TextEditingValue(
                          text: value,
                          selection: TextSelection.collapsed(
                            offset: value.length,
                          ),
                        );
                      },
                    );
                  },

              // ==================================================================
              // OPTIONS LIST (Dropdown suggestions UI)
              // ==================================================================
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Color(0xFF1A1A1A),
                    elevation: 6,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      constraints: BoxConstraints(maxHeight: 180),

                      child: ListView.builder(
                        itemCount: options.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);

                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child: Text(
                                option,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 20),

            // ==================================================================
            // QUANTITY + PRICE FIELDS
            // ==================================================================
            Row(
              children: [
                /// QUANTITY FIELD
                Expanded(
                  child: TextField(
                    controller: quantityCtrl,
                    onTap: () {
                      // Auto-select full text for quick editing
                      quantityCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: quantityCtrl.text.length,
                      );
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "quantity"),
                  ),
                ),

                SizedBox(width: 10),

                /// PRICE FIELD
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    onTap: () {
                      // Auto-select full text
                      priceCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: priceCtrl.text.length,
                      );
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Price"),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // ==================================================================
            // ACTION BUTTONS — CANCEL & ADD/SAVE
            // ==================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /// CANCEL BUTTON
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.white)),
                ),

                /// ADD / SAVE BUTTON
                MaterialButton(
                  onPressed: () {
                    // Validation
                    if (nameCtrl.text.trim().isEmpty ||
                        quantityCtrl.text.trim().isEmpty ||
                        priceCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please fill all fields"),
                          backgroundColor: Colors.red,
                        ),
                      );

                      return; // DO NOT close dialog
                    }

                    // Generate unique ID only when ADDING new item
                    // final id = widget.isEditing
                    //     ? widget
                    //           .existingItem!
                    //           .id // keep same ID for editing
                    //     : const Uuid().v4(); // new unique ID

                    final id = widget.isEditing && widget.existingItem != null
                        ? widget.existingItem!.id
                        : DateTime.now().millisecondsSinceEpoch.toString();

                    final item = BudgetItem(
                      id: id,
                      name: nameCtrl.text.trim(),
                      quantity: int.parse(quantityCtrl.text.trim()),
                      price: int.parse(priceCtrl.text.trim()),

                      // dateTime: DateTime.now(),
                      dateTime: widget.isEditing && widget.existingItem != null
                          ? widget
                                .existingItem!
                                .dateTime // keep original
                          : DateTime.now(),

                      imagePath: "", // add later if needed
                    );

                    // Pass back data to caller (Homescreen)

                    Navigator.pop(context, item);

                    // Navigator.pop(context, {
                    //   "name": nameCtrl.text,
                    //   "date": DateTime.now(),
                    //   "quantity": int.tryParse(quantityCtrl.text) ?? 0,
                    //   "price": int.tryParse(priceCtrl.text) ?? 0.0,
                    // });
                  },

                  child: Text(
                    widget.isEditing ? 'Save' : 'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
