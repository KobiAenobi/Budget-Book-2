import 'package:budget_book_app/models/budget_item.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';


/// ============================================================================
/// 📌 Api Utility Class
/// ----------------------------------------------------------------------------
/// This class holds reusable helper methods. Currently it contains:
///
///   • oneLineScroll → A horizontally scrollable single-line text widget
///
/// NOTHING has been changed — only explanatory comments were added.
/// ============================================================================
class Api {

  /// ==========================================================================
  /// 📝 oneLineScroll(String text, TextStyle? style)
  /// --------------------------------------------------------------------------
  /// Returns a horizontally scrollable Text widget.
  ///
  /// Useful when:
  ///   • Text is longer than the container width
  ///   • You want to avoid ellipsis ("...") and instead allow sideways scroll
  ///
  /// How it works:
  ///   - Wraps Text in SingleChildScrollView (horizontal)
  ///   - Forces single line using maxLines = 1
  ///   - Prevents automatic overflow truncation
  ///
  /// Example:
  ///   Api.oneLineScroll("Very long text...", TextStyle(...))
  ///
  /// NOTHING modified inside the method — exact logic preserved.
  /// ==========================================================================
  static Widget oneLineScroll(String text, TextStyle? style) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enables LEFT↔RIGHT scroll

      child: Text(
        text,
        style: style,                   // Custom text styling
        maxLines: 1,                    // Force single line
        overflow: TextOverflow.visible, // Full text visible (no ellipsis)
      ),
    );
  }

  // ===========================================================================
  // 💰 MONTHLY BUDGET (HIVE VERSION)
  // ===========================================================================
  static String getCurrentMonthId(){
    final now=DateTime.now();
    return "${now.year}-${now.month}";
  }

  Future<void> saveMonthlyBudget(int amount) async {
    final box=Hive.box("monthly_budget");
    final monthId=getCurrentMonthId();
    await box.put(monthId, amount);
  }

  static int? getMonthlyBudget(){
    final box = Hive.box("monthly_budget");
    final monthId=getCurrentMonthId();
    return box.get(monthId);
  }

  static int getMonthlySpent(){
    final expensesBox=Hive.box<BudgetItem>("expenses");
    final now=DateTime.now();

    return expensesBox.values.where((item)=> item.dateTime.year==now.year && item.dateTime.month == now.month).fold(0, (sum, item)=> sum +item.price);
  }

  /// Returns the remaining budget (or null if no monthly budget is set)
  static int? getRemainingBudget() {
    final limit = getMonthlyBudget();
    if (limit == null) return null;

    final spent = getMonthlySpent();
    return limit - spent;
  }

  /// Returns spending percentage (0–100)
  static double getSpendingPercentage() {
    final limit = getMonthlyBudget();
    if (limit == null) return 0;

    final spent = getMonthlySpent();
    return (spent / limit) * 100;
  }

  /// Returns animation state ("chill", "warning", "stressed")
  static String getAnimationState() {
    final pct = getSpendingPercentage();

    if (pct < 50) return "chill";
    if (pct < 80) return "warning";
    return "stressed";
  }


  //group by months

  static Map<String, List<BudgetItem>> groupItemsByMonth(List<BudgetItem> items){

    items.sort((a, b)=> b.dateTime.compareTo(a.dateTime));


    final Map<String, List<BudgetItem>> grouped = {};

    for(var item in items){

      String key = "${item.dateTime.year}-${item.dateTime.month.toString().padLeft(2, '0')}";

      if(!grouped.containsKey(key)){
        grouped[key]=[];
      }

      grouped[key]!.add(item);
    }

    return grouped;
  }
}
