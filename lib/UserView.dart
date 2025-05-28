import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'ApiManagment/ProductApi.dart';
import 'HomePage.dart';
import 'package:get/get.dart';

import 'MyOrders.dart';
class Userview extends StatelessWidget {
  final HomepageController Homecontroller = Get.put(HomepageController());
  final String userId;
  Userview({super.key,required this.userId});

  @override
  Widget build(BuildContext context) {

    final userData=Homecontroller.userList.value?.firstWhere((user){return userId==user['id'];});
    int totalOrders=0;
    int completedOrders=0;
    Homecontroller.orderList.value!.where((item){return item['user_id']==userId;}).forEach((value) {
      if(value['status']=='DELIVERED')completedOrders++;
      totalOrders++;
    });

    return SingleChildScrollView(
      child: Column(
        children: [
          if(userData!=null)UserDetails(userData),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              onTap: (){
                showDialog(
                  context: context,
                  builder: (context) {
                    final toController = TextEditingController(text: userData?['email']);
                    final subjectController = TextEditingController(text: 'Order Update');
                    final messageController = TextEditingController(text: 'Your Order With OrderId=[ID] is ready to [STATUS]');

                    Future<void> sendEmail() async {
                      final to = Uri.encodeComponent(toController.text.trim());
                      final subject = Uri.encodeComponent(subjectController.text.trim());
                      final body = Uri.encodeComponent(messageController.text.trim());

                      if(to.isEmpty||subject.isEmpty ||body.isEmpty){
                        Homepage.showOverlayMessage(context, 'Fill All Field');
                        return;
                      };

                      final ans=await HomeApi.sendEmail(recipients: [to], subject:subject, message:body) ;

                      Homepage.showOverlayMessage(context, ans);
                      Navigator.pop(context);
                    }

                    return AlertDialog(
                      content:IntrinsicHeight(
                        child: Column(
                          children: [
                            TextField(
                              controller: toController,
                              decoration: const InputDecoration(labelText: 'To'),
                            ),
                            TextField(
                              controller: subjectController,
                              decoration: const InputDecoration(labelText: 'Subject'),
                            ),
                            TextField(
                              controller: messageController,
                              decoration: const InputDecoration(labelText: 'Message'),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed:sendEmail,
                              child: const Text('Send Email'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
                title:Text('Send Mail',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold) ,)
            ),
          ),
          SizedBox(height: 10,),
          statusCard(completedOrders, totalOrders),
          SizedBox(height: 10,),
          Orders(context, userId, userData?['first_name']??'NA')
        ],
      ),
    );
  }

  Widget statusCard(int completedOrders,int totalOrders){
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        constraints: BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Order Summery", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 20.0,
              percent: (completedOrders/totalOrders),
              center: Text("Total ${(totalOrders).toInt()}"),
              progressColor: Colors.tealAccent.shade400,
              backgroundColor: Colors.black12,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Completed Orders ${((completedOrders)).toInt()}"),
                Text("Pending Orders ${((totalOrders-completedOrders)).toInt()}"),
              ],
            )
          ],
        ),
      ),
    );
  }
  Widget Orders(BuildContext context,String userId,String name){
    return Container(
      constraints: BoxConstraints(maxWidth: 1000),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10)
      ),
      // color: Colors.grey,
      child: Column(
        children: [
          Text('My Orders',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),),
          Obx(() {
            if (Homecontroller.orderList.value == null) {
              return SizedBox.shrink();
            }
            return Column(
              children: [
                ...Homecontroller.orderList.value!.where((item){return item['user_id']==userId;}).map((value) {
                  return MyOrders.OrderCard(value, context,name);
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget UserDetails(Map<String,dynamic>user){
    return Card(
      margin:
      EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          child:(user['profile_picture'] != null) ? Image.network(user['profile_picture'])
              : Text(user['first_name'][0]),
        ),
        title: Text(
          "${user['first_name']} ${user['last_name']}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📧 ${user['email'] ?? 'N/A'}"),
            Text("📞 ${user['number'] ?? 'N/A'}"),
            Text("🎂 ${user['dob'] ?? 'N/A'}"),
            Text(
                "🧑‍💼 Gender: ${user['gender']?.toUpperCase() ?? 'N/A'}"),
          ],
        ),
        trailing: IconButton(
            onPressed: (){

            },
            icon: Icon(Icons.delete_rounded,color: Colors.red, size: 16)
        ),
      ),
    );
  }
}
