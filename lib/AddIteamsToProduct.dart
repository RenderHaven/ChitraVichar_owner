import 'package:flutter/material.dart';
import 'dart:async';
import 'ApiManagment/ProductApi.dart';  // Make sure this has the search function
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'HomePage.dart';
import 'additeam.dart';


class AddItemsToProduct extends StatefulWidget {
  final String productId;
  final List<String> MyItemsId;
  AddItemsToProduct({required this.productId,this.MyItemsId=const []});

  @override
  _AddItemsToProductState createState() => _AddItemsToProductState();
}

class _AddItemsToProductState extends State<AddItemsToProduct> {
  TextEditingController _searchController = TextEditingController();
  // List<dynamic> _searchResults = [];  // Store search results
  List<String> _selectedItems = [];   // Store selected item IDs
  bool _isLoading = false;
  String tag='';
  Timer? _debounce;
  final HomepageController controller = Get.put(HomepageController());
  void initState(){
    super.initState();
    fetchData();
  }

  void fetchData()async{
    if(controller.itemList.value==null){
      await controller.searchItems();
    }
    controller.itemSearchList.value = List.from(controller.itemList.value ?? []);
  }

  void _filterItems() {
    print('filtering for $tag');
    final List=controller.itemList.value??[];
    if (tag.isEmpty) {
      controller.itemSearchList.value=List; // Reset to full list
    } else {
      controller.itemSearchList.value= List
          .where((variation) => variation['name'].toLowerCase().contains(tag))
          .toList();
    }
  }

  // Function to add items to a product (API call)
  Future<void> _addItemsToProduct(String productId) async {
    if (_selectedItems.isEmpty) {
      Homepage.showOverlayMessage(context, "Please select at least one item");
      return;
    }

    try {
      // Call the addItemsToProduct method in ProductApi
      await ProductApi.addItemsToProduct(
        productId: productId,
        itemIds: _selectedItems,
      );
      Homepage.showOverlayMessage(context,'Items added to product successfully');
    } catch (e) {
      print("Error occurred: $e");
      Homepage.showOverlayMessage(context,'Failed to add items');

    }
  }

  // Debounce input to avoid excessive API calls
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      tag=query;
      _filterItems(); // Call API after 300ms delay
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("Add Items to Product")),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            SizedBox(height: 15,),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search for items",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(onPressed:(){
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        contentPadding: EdgeInsets.all(5),
                        title: Text('Add Item'),
                        content: AddIteam(productId: widget.productId,), // The AddProduct widget appears in the dialog
                        actions: <Widget>[
                          // Add a Close button to close the dialog
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                            },
                            child: Text('Close'),
                          ),
                        ],
                      );
                    },
                  ).then((v) {
                    if(v=='Done'){
                      _filterItems();
                      Navigator.pop(context);
                    }

                  });
                } , icon:Icon(Icons.add))
              ),
              onChanged: _onSearchChanged, // Trigger search on text change
            ),
            SizedBox(height: 16),

            // Show loading spinner if searching
            Obx((){
              return controller.isItemLoading.value
                  ? CircularProgressIndicator()
                  : Expanded(
                child: (controller.itemSearchList.value??[]).isNotEmpty?ListView.builder(
                  itemCount: controller.itemSearchList.value?.length??0,
                  itemBuilder: (context, index) {
                    final item = controller.itemSearchList.value?[index]??{};
                    return (item['i_id']!='Lable' && item.containsKey('name') && ! widget.MyItemsId.contains(item['i_id']??''))?Card(
                      child: CheckboxListTile(
                          title: Text(item['name']),
                          value: _selectedItems.contains(item['i_id']),
                          onChanged: (bool? selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedItems.add(item['i_id']);
                              } else {
                                _selectedItems.remove(item['i_id']);
                              }
                            });
                          },
                      ),
                    ):SizedBox.shrink();
                  },
                ):Text('NO DATA'),
              );
            }),
            // Button to add selected items to a product
            ElevatedButton(
              onPressed: () {
                _addItemsToProduct(widget.productId); // Add selected items to product
              },
              child: Text('Add Selected Items'),
            ),
          ],
        ),
      ),
    );
  }
}

