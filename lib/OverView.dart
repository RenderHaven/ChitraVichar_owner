import 'package:chitraowner/EditItem.dart';
import 'package:chitraowner/HomePage.dart';
import 'package:chitraowner/IteamView.dart';
import 'package:chitraowner/MyItems.dart';
import 'package:chitraowner/MyOrders.dart';
import 'package:chitraowner/MyUsers.dart';
import 'package:chitraowner/UserView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Overview extends StatelessWidget {
  final HomepageController homeController = Get.put(HomepageController());
  final Map<String, String> nameList = {};

  Overview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              
              Obx(() {
                double totalPrice = 0;
                int total = 0;
                int completed = 0;
                int newOrders = 0;
                int totalUsers = 0;
                int female = 0;
                int male = 0;

                if (homeController.orderList.value != null) {
                  total = homeController.orderList.value!.length;
                  for (var data in homeController.orderList.value!) {
                    if (data['status'] == 'NEW') newOrders++;
                    if (data['status'] == 'DELIVERED') completed++;
                    try {
                      if (data['status'] == 'CANCELLED') continue;
                      totalPrice += data['total_price'];
                    } catch (e) {
                      print(e.toString());
                    }
                  }
                }

                if (homeController.userList.value != null) {
                  totalUsers = homeController.userList.value!.length;
                  for (var v in homeController.userList.value!) {
                    try {
                      if ((homeController.userSummery.value ?? {}).containsKey(v['id'])) {
                        nameList[v['id']] = v['first_name'];
                      }
                      if (v['gender'] == 'Male') male++;
                      else if (v['gender'] == 'Female') female++;
                    } catch (e) {
                      print(e.toString());
                    }
                  }
                }

                return Column(
                  children: [
                    _buildHeader(),
                    
                    _StatCard(title: 'Home', value: 'Banner/Offers', icon: Icons.home, color:Colors.grey,
                    mxWidth: double.infinity,
                     onTap: ()=>{
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemViewPage(itemId: 'Lable'),
                          ),
                        )
                      },
                    
                    ),
                    _buildStatsGrid(
                      context,
                      totalBalance: totalPrice,
                      newOrders: newOrders,
                      totalItems: homeController.itemList.value?.length ?? 0,
                      totalUsers: totalUsers,
                      maleUsers: male,
                      femaleUsers: female,
                    ),
                    SizedBox(height: 20),
                    _buildOrderAnalytics(
                      completedOrders: completed,
                      totalOrders: total,
                    ),
                  ],
                );
              }),
              SizedBox(height: 20),
              _buildNewOrdersSection(context),
              SizedBox(height: 20),
              _buildBottomRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Dashboard Overview",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: () => homeController.searchOrders(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
  BuildContext context, {
  required double totalBalance,
  required int newOrders,
  required int totalItems,
  required int totalUsers,
  required int maleUsers,
  required int femaleUsers,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Calculate number of columns based on available width
      final crossAxisCount = (constraints.maxWidth ~/ 180).clamp(1, 4);
      final cardWidth = constraints.maxWidth / crossAxisCount - (10 * (crossAxisCount - 1));
      
      return GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: EdgeInsets.all(10),
        children: [
          SizedBox(
            width: cardWidth,
            child: _StatCard(
              title: "Total Revenue",
              value: "₹${totalBalance.toStringAsFixed(2)}",
              icon: Icons.account_balance_wallet,
              color: Colors.blue,
              onTap: null,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _StatCard(
              title: "New Orders",
              value: newOrders.toString(),
              icon: Icons.fiber_new,
              color: Colors.green,
              onTap: () {
                homeController.selectedRoute.value = '/orders';
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyOrders()),
                );
              },
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _StatCard(
              title: "Total Products",
              value: totalItems.toString(),
              icon: Icons.inventory,
              color: Colors.orange,
              onTap: () {
                homeController.selectedRoute.value = '/items';
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyItems()),
                );
              },
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _StatCard(
              title: "Total Customers",
              value: totalUsers.toString(),
              icon: Icons.people,
              color: Colors.purple,
              onTap: () {
                homeController.selectedRoute.value = '/users';
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyUsers()),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildOrderAnalytics({
    required int completedOrders,
    required int totalOrders,
  }) {
    final pendingOrders = totalOrders - completedOrders;
    final completionRate = totalOrders > 0 ? completedOrders / totalOrders : 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Order Analytics",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CircularPercentIndicator(
                        radius: 60,
                        lineWidth: 12,
                        percent: completionRate.toDouble(),
                        center: Text(
                          "${(completionRate * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        progressColor: Colors.teal,
                        // backgroundColor: Colors.grey[200],
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Completion Rate",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SfCircularChart(
                        series: <CircularSeries>[
                          DoughnutSeries<MapEntry<String, int>, String>(
                            dataSource: [
                              MapEntry("Completed", completedOrders),
                              MapEntry("Pending", pendingOrders),
                            ],
                            xValueMapper: (entry, _) => entry.key,
                            yValueMapper: (entry, _) => entry.value,
                            pointColorMapper: (entry, _) =>
                                entry.key == "Completed" ? Colors.teal : Colors.orange,
                            dataLabelSettings: DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.teal, "Completed", completedOrders),
                _buildLegendItem(Colors.orange, "Pending", pendingOrders),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          "$text: $value",
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildNewOrdersSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Orders",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    homeController.selectedRoute.value = '/orders';
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MyOrders()),
                    );
                  },
                  child: Text("View All"),
                ),
              ],
            ),
            SizedBox(height: 16),
            Obx(() {
              if (homeController.orderList.value == null) {
                return Center(child: CircularProgressIndicator());
              }
              
              final newOrders = homeController.orderList.value!
                  .where((item) => item['status'] == 'NEW')
                  .take(3)
                  .toList();

              if (newOrders.isEmpty) {
                return Center(
                  child: Text(
                    "No new orders",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: newOrders.map((value) {
                  final name = homeController.userList.value
                      ?.firstWhere(
                        (user) => value['user_id'] == user['id'],
                        orElse: () => {'first_name': 'Unknown'},
                      )['first_name'];
                  return MyOrders.OrderCard(value, context);
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Column(
      children: [
        _buildTopProductsSection(context),
        SizedBox(height: 16),
         _buildTopCustomersSection(context),
      ],
    );
  }

  Widget _buildTopProductsSection(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 200),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Top Products",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(height: 16),
              Obx(() {
                if (homeController.itemSummery.value == null) {
                  return Center(child: CircularProgressIndicator());
                }
                
                final topProducts = homeController.itemSummery.value!.entries
                    .take(5)
                    .toList();
      
                return Column(
                  children: topProducts.map((entry) {
                    final value = entry.value;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: value['image_url'] != '' 
                            ? NetworkImage(value['image_url'])
                            : null,
                        radius: 20,
                        child: value['image_url'] == '' 
                            ? Icon(Icons.inventory, size: 20)
                            : null,
                      ),
                      title: Text(value['name'] ?? 'NA'),
                      subtitle: Text("${value['totalOrders']} orders"),
                      trailing: Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemViewPage(itemId: entry.key),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCustomersSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Top Customers",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 16),
            Obx(() {
              if (homeController.userSummery.value == null) {
                return Center(child: CircularProgressIndicator());
              }
              
              final topCustomers = homeController.userSummery.value!.entries
                  .take(5)
                  .toList();

              return Column(
                children: topCustomers.map((entry) {
                  final value = entry.value;
                  final name = nameList[entry.key] ?? entry.key;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(name[0].toUpperCase()),
                    ),
                    title: Text(name),
                    subtitle: Text("${value['total_orders']} orders"),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                          child: Userview(userId: entry.key),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double? mxWidth;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.mxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: mxWidth??250),
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}