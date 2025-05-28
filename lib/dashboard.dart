
import 'package:chitraowner/ProductTree.dart';
import 'package:chitraowner/SearchProducts.dart';
import 'package:chitraowner/ShowItems.dart';
import 'package:chitraowner/ShowProducts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'HomePage.dart';

class Dashboard extends StatefulWidget {
  String? productId;
  String path;
  Dashboard({this.productId=null,this.path='MyProducts'});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final HomepageController homeController = Get.put(HomepageController());
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    // print("building again ${widget.productId}");
    final scWidth=MediaQuery.of(context).size.width;
    return Row(
      children: [
        Visibility(
          visible: scWidth > 600,
          child: Expanded(
            flex: 1,
            child: ProductTreeView(selectedId: widget.productId),
          ),
        ),
        Visibility(
          visible: scWidth > 600,
          child: VerticalDivider(
            width: 10,
            thickness: 5,
            color: Colors.black,
          ),
        ),
        Expanded(
          flex: 2,
          child: Scaffold(
            drawer: scWidth<=600?SizedBox(
                width: scWidth*0.7,
                child: ProductTreeView(selectedId: widget.productId,)
            ):null,
            appBar:AppBar(
              title: Obx((){return Text("${homeController.productsData[widget.productId??'null']?['name']??'Root'}",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),);}),
              actions: [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SearchBarWidget(searchType: 'product'), // You can pass 'product' or 'item' based on the need
                        );
                      },
                    ).then((result){
                      if(result?['p_id']!=null)Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Dashboard(productId:result['p_id'] ,path: '....${result['name']}',)));
                    });

                  },
                ),
              ],
            ) ,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 30,),
                  Showproducts(categoryId:widget.productId=='Root'?null:widget.productId,oldpath: widget.path,),
                  Divider(),
                  SizedBox(height: 30,),
                  if(widget.productId!=null && widget.productId!='Root')ShowItems(productId: widget.productId!),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
