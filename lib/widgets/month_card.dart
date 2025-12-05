import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthCard extends StatefulWidget {
  final String month;
  final int total;
  const MonthCard({super.key, required this.month, required this.total});

  @override
  State<MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<MonthCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      // Space between cards in list
      margin: EdgeInsets.only(bottom: 1, top: 1, left: 0, right: 0),

      // shape: RoundedRectangleBorder(
      //   side: BorderSide(color: const Color.fromARGB(255, 105, 99, 97)),
      //   borderRadius: BorderRadius.circular(10),
      // ),
      color: const Color.fromARGB(255, 44, 16, 16),

      child: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ==================================================================
            // 🛒 ITEM ICON
            // ==================================================================
            Container(
              // decoration: BoxDecoration(color: Colors.black),
              constraints: BoxConstraints(
                maxHeight: 45,
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              child: FittedBox(
                child: Text(
                  widget.month,
                  // style: TextStyle(fontSize: 500, color: Colors.white54, fontFamily: 'Impact',),
                  style: GoogleFonts.prociono(
                    fontSize: 500,
                    color: Colors.white54,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // ==================================================================
            // 📝 ITEM NAME + DATE SECTION
            // ==================================================================
            // Container(
            //   child: SizedBox(
            //     width: MediaQuery.of(context).size.width * 0.4,

            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [

            //         // SINGLE-LINE SCROLLABLE ITEM NAME
            //         Api.oneLineScroll(
            //           widget.name,
            //           TextStyle(
            //             color: Colors.white,
            //             fontSize: 14,
            //             fontWeight: FontWeight.w700,
            //             fontFamily: GoogleFonts.manrope().fontFamily,
            //           ),
            //         ),

            //         // ----------------------------------------------------------------
            //         // Formatted date/time below item name
            //         // formatDateTime() is your custom helper function
            //         // ----------------------------------------------------------------
            //         Api.oneLineScroll(
            //           formatDateTime(widget.date),
            //           TextStyle(fontSize: 11, color: Colors.white54),
            //         ),

            //         // ----------------------------------------------------------------
            //         // COMMENTED OUT — EXACTLY KEPT AS PROVIDED
            //         // ----------------------------------------------------------------
            //         // Text(
            //         //   "${widget.date.day} ${monthNames[widget.date.month - 1]} ",
            //         // ),
            //       ],
            //     ),
            //   ),
            // ),

            // ==================================================================
            // 📦 QUANTITY DISPLAY
            // ==================================================================
            // Container(
            //   child: SizedBox(
            //     width: MediaQuery.of(context).size.width * 0.17,
            //     child: Text("qty: ${widget.quantity}"),
            //   ),
            // ),

            // ==================================================================
            // 💰 PRICE DISPLAY (price × quantity)
            // ==================================================================
            Container(
              // decoration: BoxDecoration(color: Colors.amber),
              constraints: BoxConstraints(maxHeight: 30, maxWidth: MediaQuery.of(context).size.width*0.4),
              child: FittedBox(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "₹${widget.total.toString()}",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.green,
                      fontFamily: GoogleFonts.workSans().fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: 500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
