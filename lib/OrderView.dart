import 'package:chitraowner/ApiManagment/ProductApi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderController extends GetxController {
  final String orderId;
  var isLoading = true.obs;
  var orderData = <String, dynamic>{}.obs;
  OrderController({required this.orderId});
  // Fetch Order Data from API (Mocked for now)
  void onInit(){
    super.onInit();
    fetchOrderData();
  }
  Future<void> fetchOrderData() async {
    try {
      isLoading(true);
      final data=await OrderApi.getOrder(orderId);
      orderData.value = data??{};
    } finally {
      isLoading(false);
    }
  }
}

// Order Info Page
class OrderInfoPage extends StatelessWidget {
  final String orderId;
  late OrderController controller;
  OrderInfoPage({required this.orderId}){
    controller=Get.put(OrderController(orderId: orderId), tag: orderId);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Order Details")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        var order = controller.orderData;
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("#${order['id']}", style: TextStyle(fontSize: 16, color: Colors.black)),
              Text("Order Status: ${order['status']}", style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text("Order Date: ${order['datetime']}", style: TextStyle(fontSize: 16, color: Colors.grey)),
              // Text("Estimated Delivery: May 14, 2022", style: TextStyle(fontSize: 16, color: Colors.green)),
              SizedBox(height: 20),

              // Order Items
              Expanded(
                child: ListView.builder(
                  itemCount: order['items'].length,
                  itemBuilder: (context, index) {
                    var item = order['items'][index];
                    return Card(
                      child: ListTile(
                        leading: Image.network(item['image_url'], width: 50, height: 50, fit: BoxFit.cover),
                        title: Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: SelectableText(item['other_details']),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${item['price']}Rs", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("${item['original_price']}Rs", style: TextStyle(fontWeight: FontWeight.bold,decoration: TextDecoration.lineThrough,)),
                            Text("Qty: ${item['quantity']}", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Divider(),

              // Payment & Delivery
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, // Aligns items to the top
                children: [
                  Expanded( // Expands to take available space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Payment", style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Expanded(
                              child: Text("${order['payINFO']}", style: TextStyle(fontSize: 14), softWrap: true),
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.credit_card, size: 16, color: Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Delivery", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(order['address'], style: TextStyle(fontSize: 14), softWrap: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${order['total_price']}", style: TextStyle(fontSize: 14), softWrap: true),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      }),
    );
  }
}
