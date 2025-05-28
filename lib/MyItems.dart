import 'package:chitraowner/ApiManagment/ProductApi.dart';
import 'package:chitraowner/IteamView.dart';
import 'package:chitraowner/additeam.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'HomePage.dart';

class MyItems extends StatefulWidget {
  @override
  _MyItemsState createState() => _MyItemsState();
}

class _MyItemsState extends State<MyItems> {
  final TextEditingController _searchController = TextEditingController();
  final HomepageController Homecontroller = Get.put(HomepageController());
  String tag = '';
  bool all=true;
  @override
  void initState() {
    super.initState();
    fetchData();
  }


  void fetchData() async {
    if (Homecontroller.itemList.value == null) {
      await Homecontroller.searchItems();
    }
    Homecontroller.itemSearchList.value = List.from(Homecontroller.itemList.value ?? []);
  }

  void _filterItems() {
    final items = Homecontroller.itemList.value ?? [];
    if (tag.isEmpty) {
      Homecontroller.itemSearchList.value = items;
    } else {
      Homecontroller.itemSearchList.value = items
          .where((item) => item['name'].toLowerCase().contains(tag))
          .toList();
    }
  }

  void _addNewItem() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(5),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Item'),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close))
            ],
          ),
          content: AddIteam(),
        );
      },
    ).then((value) async {
      if (value == "Done") {
        _filterItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Obx((){return CircleAvatar(backgroundColor: Colors.blue, child: Text('${Homecontroller.itemSearchList.value?.where((item){
        return item.containsKey('i_id') && (all || item['has_products']);
      }).length??'NA'}'));}),
      appBar: AppBar(
        title: Text('My Items'),
        actions: [
          Text('All Items'),
          Switch(
            value: all, onChanged: (v){
            setState(() {
              all=!all;
            });
          }),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewItem,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Item Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    tag = _searchController.text.toLowerCase();
                    _filterItems();
                  },
                ),
              ),
              onChanged: (v) {
                tag = _searchController.text.toLowerCase();
                _filterItems();
              },
            ),
            SizedBox(height: 20),
            Obx(() {
              return Homecontroller.isItemLoading.value
                  ? CircularProgressIndicator()
                  : Expanded(
                child: (Homecontroller.itemSearchList.value ?? []).isNotEmpty
                    ? ListView(
                    children:[
                      ...(Homecontroller.itemSearchList.value??[]).where((item){
                        return item.containsKey('i_id') && (all || item['has_products']);
                      }).map((item){
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          child: ListTile(
                            trailing:(item['has_products']??true)?null:Icon(Icons.public_off_outlined),
                            leading: item['image_url'] != null
                                ? Image.network(
                              item['image_url'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                                : Icon(Icons.image, size: 50),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['i_id'] ?? 'Unknown',
                                  style: TextStyle(fontSize: 15),
                                ),
                                Text(
                                  item['name'] ?? 'Unknown',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              "₹${item['price'] ?? 'N/A'}",
                              style: TextStyle(color: Colors.green, fontSize: 16),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemViewPage(itemId: item['i_id']),
                                ),
                              ).then((value) async {
                                if (value == "Done") {
                                  await Homecontroller.searchItems();
                                  _filterItems();
                                }
                              });
                            },
                          ),
                        );
                      })
                    ]
                )
                    : Text('NO DATA'),
              );
            })
          ],
        ),
      ),
    );
  }
}

