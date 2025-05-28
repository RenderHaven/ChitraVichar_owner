import 'package:chitraowner/ApiManagment/ProductApi.dart';
import 'package:chitraowner/OrderView.dart';
import 'package:chitraowner/UserView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'HomePage.dart';

class MyOrders extends StatefulWidget {

  static Color getStatusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'IN_PROGRESS':
        return Colors.blueAccent;
      case 'SHIPPED':
        return Colors.cyan;
      case 'NEW':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  static void showUpdateStatusDialog(BuildContext context, String currentStatus, Function(String) onStatusUpdated) {
    String selectedStatus =currentStatus;
    List<MapEntry<String, Color>> options = [
      MapEntry('NEW', Colors.purple),
      MapEntry("IN_PROGRESS", Colors.orange),
      MapEntry("SHIPPED", Colors.blue),
      MapEntry("DELIVERED", Colors.green),
      MapEntry("CANCELLED", Colors.red),
    ];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context,setState) {
              return AlertDialog(
                title: Text("Update Order Status"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedStatus,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState((){
                            selectedStatus = newValue;
                          });
                        }
                      },
                      items: options.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.key,
                            style: TextStyle(color: entry.value), // Set text color dynamically
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Close the dialog
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onStatusUpdated(selectedStatus); // Call function to update status
                      Navigator.pop(context); // Close the dialog
                    },
                    child: Text("Confirm"),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  static Widget OrderCard(Map<String,dynamic>result,BuildContext context,String? name){

    return StatefulBuilder(builder: (context,setState){
      return InkWell(
        onTap:()=> Navigator.push(context,MaterialPageRoute(builder: (context)=>OrderInfoPage(orderId: result['id'],),)),
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3, // 80% of space
                      child: Text(
                        "Order ID: #${result['id']}",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.visible, // Allows wrapping
                      ),
                    ),
                    Expanded(
                      flex: 2, // 20% of space
                      child: Text(
                        result['datetime'] ?? 'N/A',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('User'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: (){
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content:Userview(userId: result['user_id']),
                          );
                        },
                      );

                    }, child: Text(
                      "${name??'NA'}",
                      style: TextStyle(fontSize: 14),
                    ),),
                    Text(
                      "${result['total_price']}rs",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      // constraints: BoxConstraints(maxWidth: 250),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Payment"),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              result['payINFO'] ?? 'N/A',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text("Status: "),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: getStatusColor(result['status']),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  result['status'] ?? 'N/A',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              IconButton(
                                  onPressed:()=>showUpdateStatusDialog(context,result['status'],
                                          (status)async{
                                        if(await OrderApi.updateOrderStatus(result['id'], status)){
                                          setState(() {
                                            result['status']=status;
                                          });
                                        }
                                      }
                                  ) , icon:Icon(Icons.edit))
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "${result['address']} ",  // Address text
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              WidgetSpan(
                                child: Icon(
                                  Icons.location_on,
                                  size: 16,  // Adjust size to match text
                                  color: Colors.redAccent, // Customize color
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,  // Prevents overflow
                          maxLines: 2,  // Keeps it on a single line
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
    });
  }
  @override
  _MyOrdersState createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  final dateFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss z'); // your forma
  final TextEditingController _searchController = TextEditingController();
  final HomepageController homeController = Get.put(HomepageController());
  String tag = '';
  bool newest=true;
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    if (homeController.orderList.value == null) {
      await homeController.searchOrders();
    }
    homeController.orderSearchList.value = List.from(homeController.orderList.value ?? []);
    sortByDate();
  }

  void sortByDate() {
    var list = homeController.orderSearchList.value ?? [];
    list.sort((a, b) {
      DateTime dateA = dateFormat.parse(a['datetime']??'N/A');
      DateTime dateB = dateFormat.parse(b['datetime']??'N/A');
      return newest
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
    });

    homeController.orderSearchList.value=list;
  }

  void _filterOrders() {
    final orders = homeController.orderList.value ?? [];
    if (tag.isEmpty) {
      homeController.orderSearchList.value = orders;
    } else {
      homeController.orderSearchList.value = orders
          .where((order) => order['user_name'].toLowerCase().contains(tag))
          .toList();
    }
    sortByDate();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Obx((){return CircleAvatar(backgroundColor: Colors.blue, child: Text('${homeController.orderSearchList.value?.length??'NA'}'));}),
      appBar: AppBar(
        title:  Row(
          children: [
            Text('My Orders'),
            IconButton(onPressed:()=> homeController.searchOrders(), icon: Icon(Icons.refresh))
          ],
        ),
        actions: [
          IconButton(onPressed: (){
            setState(() {
              newest=!newest;
            });
            sortByDate();
          }, icon:newest?Icon(Icons.arrow_upward):Icon(Icons.arrow_downward))
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Customer Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    tag = _searchController.text.toLowerCase();
                    _filterOrders();
                  },
                ),
              ),
              onChanged: (v) {
                tag = _searchController.text.toLowerCase();
                _filterOrders();
              },
            ),
            SizedBox(height: 20),
            Details(),
            SizedBox(height: 10),
            Obx(() {
              return homeController.isOrderLoading.value
                  ? CircularProgressIndicator()
                  : Expanded(
                    child: (homeController.orderSearchList.value ?? []).isNotEmpty?
                    ListView.builder(
                      itemCount: homeController.orderSearchList.value?.length ?? 0,
                      itemBuilder: (context, index) {
                        final result = homeController.orderSearchList.value?[index] ?? {};
                        final name=homeController.userList.value?.firstWhere((user){return result['user_id']==user['id'];})['first_name'];
                        return result.containsKey('id')? MyOrders.OrderCard(result,context,name): Text('NO DATA');
                      },
                    )
                    : Text('NO DATA'),
                  );
            })
          ],
        ),
      ),
    );
  }


  Widget Details() {
    return Obx(() {
      final orders = homeController.orderSearchList.value ?? [];
      // Calculate order statistics
      int totalOrders = orders.length;
      int completedOrders = orders.where((order) => order['status'] == 'DELIVERED').length;
      int pendingOrders = orders.where((order) =>(order['status'] != 'DELIVERED' && order['status'] != 'CANCELLED')).length;
      int returnedOrders = orders.where((order) => order['status'] == 'CANCELLED').length;

      return homeController.isOrderLoading.value?SizedBox.shrink():
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: statCard("Total Orders", totalOrders)),
          Expanded(child: statCard("Completed", completedOrders)),
          Expanded(child: statCard("Pending", pendingOrders)),
          Expanded(child: statCard("CANCELLED", returnedOrders)),
          // Expanded(child: statCard("Fulfilled Orders", fulfilledOrders)),
        ],
      );
    });
  }

  Widget statCard(String title, int value) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.greenAccent, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }


}
