import 'package:chitraowner/ApiManagment/ProductApi.dart';
import 'package:chitraowner/MyItems.dart';
import 'package:chitraowner/MyOrders.dart';
import 'package:chitraowner/MyUsers.dart';
import 'package:chitraowner/SendMail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'HomePage.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'IteamView.dart';
import 'UserView.dart';
class Overview extends StatelessWidget {
  final HomepageController Homecontroller = Get.put(HomepageController());

  final Map<String,String> nameList={};
  Overview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(10),
          child: Column(
            // runSpacing: 10,
            // alignment: WrapAlignment.center,
            children: [
              // TextButton(
              //     onPressed: ()async {
              //      final ans=await HomeApi.sendEmail(recipients: ['bhanikom@gmail.com'], subject:'Hello', message:'Vikram loves u') ;
              //       print(ans);
              //   }, child: Text('sdsds')),
              Obx((){
                double totalPrice=0;
                int total=0;
                int completed=0;
                int newOrders=0;
                int totalUsers=0;
                int female=0;
                int male=0;
                if(Homecontroller.orderList.value!=null ){
                  total=Homecontroller.orderList.value!.length;
                  List.generate(Homecontroller.orderList.value!.length, (i){
                    final data=Homecontroller.orderList.value![i];
                    if(data['status']=='NEW')newOrders++;
                    if(data['status']=='DELIVERED')completed++;
                    try{
                      if(data['status']=='CANCELLED')return;
                      totalPrice+=data['total_price'];
                    }
                    catch(e){
                      print(e.toString());
                    }
                  });
                }
                if(Homecontroller.userList.value!=null ){
                  totalUsers=Homecontroller.userList.value!.length;

                  List.generate(Homecontroller.userList.value!.length, (i){
                    final v=Homecontroller.userList.value![i];
                    try{
                      if((Homecontroller.userSummery.value??{}).containsKey(v['id'])){
                        nameList[v['id']]=v['first_name'];
                      }
                      if(v['gender']=='Male')male++;
                      else if(v['gender']=='Female')female++;
                    }
                    catch(e){
                      print(e.toString());
                    }
                  });
                }
                return DashboardWidget(
                  newOrders: newOrders,
                  completedOrders: completed,
                  totalOrders: total,
                  maleUsers: male,
                  femaleUsers: female,
                  totalUsers: totalUsers,
                  totalBalance: totalPrice,
                  context: context,
                );
              }),
              SizedBox(height: 10,),
              NewOrders(context),
              SizedBox(height: 10,),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  TopItems(context),
                  TopCustomer(context),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget NewOrders(BuildContext context){
    return Container(
      constraints: BoxConstraints(maxWidth: 1000),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10)
      ),
      // color: Colors.grey,
      child: Column(
        children: [
          Text('New Orders',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),),
          Obx(() {
            if (Homecontroller.orderList.value == null) {
              return SizedBox.shrink();
            }
            return Column(
              children: [
                ...Homecontroller.orderList.value!.where((item){return item['status']=='NEW';}).map((value) {
                  final name=Homecontroller.userList.value?.firstWhere((user){return value['user_id']==user['id'];})['first_name'];
                  return MyOrders.OrderCard(value, context,name);
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget TopCustomer(BuildContext context){
    return Container(
      width: 500,
      // height: 500,
      // margin: EdgeInsets.symmetric(horizontal:5,vertical: 50),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10)
      ),
      // color: Colors.grey,
      child: Column(
        children: [
          Text('Top Customers',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),),
          Column(
            children: [
              Card(
                color: Colors.grey,
                margin: EdgeInsets.all(5),
                child:Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5,vertical: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text('UserId')),
                      Expanded(child: Text('TotalOrders')),
                      Expanded(child: Text('CompleteOrders')),
                    ],
                  ),
                ),
              ),
              Obx(() {
                if (Homecontroller.userSummery.value == null) {
                  return SizedBox.shrink();
                }
                return Column(
                  children: [
                    ...Homecontroller.userSummery.value!.entries.map((entry) {
                      final value = entry.value;
                      final name =nameList[entry.key]??entry.key;
                      return InkWell(
                        onTap:(){
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                content:Userview(userId: entry.key),
                              );
                            },
                          );
                        } ,
                        child: Card(
                          margin: EdgeInsets.all(5),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(child: Text(name)),
                                Expanded(child: Center(child: Text(
                                    value['total_orders'].toString()))),
                                Expanded(child: Center(child: Text(
                                    value['completed'].toString()))),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget TopItems(BuildContext context){
    return Container(
      width: 500,
      // margin: EdgeInsets.symmetric(horizontal:5,vertical: 50),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10)
      ),
      // color: Colors.grey,
      child: Column(
        children: [
          Text('BestSeller',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),),
          Column(
            children: [
              Card(
                color: Colors.grey,
                margin: EdgeInsets.all(5),
                child:Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5,vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Name'),
                      SizedBox(width: 10,),
                      Text('Orders')
                    ],
                  ),
                ),
              ),
              Obx((){
                if(Homecontroller.itemSummery.value==null){
                  return SizedBox.shrink();
                }
                return Column(
                  children: [
                    ...Homecontroller.itemSummery.value!.entries.map((entry) {
                      final value = entry.value;
                      return Card(
                        margin: EdgeInsets.all(5),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                          child: Row(
                            children: [
                              IconButton(onPressed: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ItemViewPage(itemId: entry.key),
                                  ),
                                );
                              },
                                icon: CircleAvatar(
                                  backgroundImage:value['image_url']!=''? NetworkImage(value['image_url']):null,
                                  radius: 16,
                                ),
                              ),
                              Expanded(child: Text(value['name']??'NA')),
                              Expanded(child: Center(child: Text(value['totalOrders'].toString()))),
                              // Expanded(child: Center(child: Text(value['completed'].toString()))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }


  Widget DashboardWidget({
    required double totalBalance,
    required int totalUsers,
    required int maleUsers,
    required int femaleUsers,
    required int newOrders,
    required int completedOrders,
    required int totalOrders,
    required BuildContext context,
  }) {

    Widget buildCard(String title, String value, IconData icon, Color color) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 150,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 30, color: color),
              SizedBox(height: 10),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("${value}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            buildCard("Total Balance", "$totalBalance rs", Icons.account_balance_wallet, Colors.blue),
            buildCard("New Orders", newOrders.toString(), Icons.fiber_new_outlined, Colors.green),
            InkWell(
              onTap:(){
                Homecontroller.selectedRoute.value='/items';
                Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>MyItems()));
              },
              child: buildCard("Total Items",Homecontroller.itemList.value!=null?Homecontroller.itemList.value!.length.toString():'NA', Icons.stacked_bar_chart, Colors.orange),
            ),
            InkWell(
              onTap:(){
                Homecontroller.selectedRoute.value='/users';
                Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>MyUsers()));
              },
              child: buildCard("Total Users", Homecontroller.userList.value!=null?Homecontroller.userList.value!.length.toString():'NA', Icons.people, Colors.yellow),
            ),
            buildCard("Male Users", maleUsers.toString(), Icons.male, Colors.blue),
            buildCard("Female Users", femaleUsers.toString(), Icons.female, Colors.pink),
          ],
        ),
        SizedBox(height: 30),
        Card(
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
        ),
      ],
    );
  }

}
