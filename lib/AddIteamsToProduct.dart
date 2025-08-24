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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and Add Item Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: "Search items",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add, size: 32),
                  tooltip: 'Add new item',
                  onPressed: _showAddItemBottomSheet,
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Items List
            Obx(() {
              return controller.isItemLoading.value
                  ? Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: _buildItemsList(),
                    );
            }),
            
            // Add Selected Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _addItemsToProduct(widget.productId),
                child: Text(
                  'Add ${_selectedItems.length} Selected Items',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    final items = controller.itemSearchList.value ?? [];
    
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item['i_id'] == 'Lable' || 
            !item.containsKey('name') || 
            widget.MyItemsId.contains(item['i_id'] ?? '')) {
          return SizedBox.shrink();
        }

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          elevation: 1,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            title: Text(item['name']),
            trailing: Checkbox(
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
          ),
        );
      },
    );
  }

  void _showAddItemBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Accounts for keyboard
        ),
        child: AddIteam(productId: widget.productId),
      ),
    ).then((value) {
      if (value == 'Done') {
        _filterItems();
        Navigator.pop(context);
      }
    });
  }
}

