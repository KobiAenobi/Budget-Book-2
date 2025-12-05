import 'package:budget_book_app/models/budget_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

class TopCard1 extends StatefulWidget {
  const TopCard1({super.key});

  @override
  State<TopCard1> createState() => _TopCard1State();
}

class _TopCard1State extends State<TopCard1> {
  /// Hive box reference
  final itemsBox = Hive.box<BudgetItem>('itemsBox');

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------------
    // Convert Hive box to list & sort newest → oldest
    // ---------------------------------------------------------
    final items = itemsBox.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // ---------------------------------------------------------
    // Calculate Grand Total
    // ---------------------------------------------------------

    int currentMonth = DateTime.now().month;
    int grandTotal = 0;

    // final grandTotal = items
    // .where((item) => item.dateTime.month == currentMonth)
    // .fold(0, (sum, item) => sum + (item.price * item.quantity));

    // for (var item in items) {
    //   grandTotal += item.price * item.quantity;
    // }

    for (var item in items) {
      if (item.dateTime.month == currentMonth) {
        grandTotal += item.price * item.quantity;
      }
    }
    //Top Card Design
    return Container(
      // margin: EdgeInsets.only(bottom: 0, top: 5, left: 0, right: 0),
      // shape: RoundedRectangleBorder(
      //   side: BorderSide(color: const Color.fromARGB(255, 105, 99, 97)),
      //   borderRadius: BorderRadius.circular(10),
      // ),
      color: const Color.fromARGB(255, 24, 8, 2),

      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  // width: MediaQuery.of(context).size.width*0.5,
                  padding: EdgeInsets.only(left: 5),
                  // color: Colors.amber,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      child: Center(
                        child: Text(
                          "Total",
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: "Impact",
                            fontWeight: FontWeight.bold,
                            fontSize: 500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(5),
                    // color: Colors.red,
                    child: Align(
                      alignment: Alignment.center,
                      child: FittedBox(child: Center(child: Text(""))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.65,
                  padding: EdgeInsets.all(3),
                  // color: Colors.blue,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      child: Center(
                        child: Text(
                          "Expense",
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: "Impact",
                            fontWeight: FontWeight.bold,
                            fontSize: 500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(top: 12, right: 5),
                    // color: Colors.white,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        child: Center(
                          child: Text(
                            "₹$grandTotal",
                            style: TextStyle(
                              color: Colors.green,
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              fontWeight: FontWeight.w900,
                              fontSize: MediaQuery.of(context).size.width * 0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
