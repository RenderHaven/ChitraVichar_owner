import 'package:chitraowner/GetXmodels/ItemModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chitraowner/ApiManagment/ProductApi.dart';
import 'package:chitraowner/IteamView.dart';
import 'package:chitraowner/additeam.dart';
import 'package:chitraowner/HomePage.dart';

class MyItems extends StatefulWidget {
  @override
  _MyItemsState createState() => _MyItemsState();
}

class _MyItemsState extends State<MyItems> {
  final TextEditingController _searchController = TextEditingController();
  final HomepageController homeController = Get.put(HomepageController());
  String tag = '';
  bool public = true;
  bool nonPublic = true;
  String _sortBy = 'popularity'; // 'popularity' or 'price'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    if (homeController.itemList.value == null) {
      await homeController.searchItems();
    }
    _filterAndSortItems();
  }

  void _filterAndSortItems() {
    final items = homeController.itemList.value ?? [];

    // Filter by search term
    List<Map<String, dynamic>> filteredItems = tag.isEmpty
        ? List.from(items)
        : items
            .where((item) => item['name'].toLowerCase().contains(tag))
            .toList();

    // Filter by public/non-public status
    filteredItems = filteredItems.where((item) {
      final hasProducts = item['has_products'] ?? false;
      return (public && hasProducts) || (nonPublic && !hasProducts);
    }).toList();

    // Sort items
    filteredItems.sort((a, b) {
      if (_sortBy == 'price') {
        final priceA = double.tryParse(a['price']?.toString() ?? '0') ?? 0;
        final priceB = double.tryParse(b['price']?.toString() ?? '0') ?? 0;
        return _sortAscending
            ? priceA.compareTo(priceB)
            : priceB.compareTo(priceA);
      } else {
        // Default sort by popularity (cart_count)
        final countA = a['cart_count'] ?? 0;
        final countB = b['cart_count'] ?? 0;
        return _sortAscending
            ? countA.compareTo(countB)
            : countB.compareTo(countA);
      }
    });

    homeController.itemSearchList.value = filteredItems;
  }

  void _addDuplicateItem(itemId) async {
    final controller =
        await Get.put(ItemController(itemId), tag: itemId.toString());
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // Ensures content avoids notches and status bars
      builder: (context) => AddIteam(
        controller: controller,
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width > 500
            ? 500
            : double.infinity, // Limits width on larger screens
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      clipBehavior: Clip.antiAlias, // Ensures clean rounded corners
    );

    if (result == "Done") {
      await homeController.searchItems();
    }
  }

  void _addNewItem() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // Ensures content avoids notches and status bars
      builder: (context) => AddIteam(),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width > 500
            ? 500
            : double.infinity, // Limits width on larger screens
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      clipBehavior: Clip.antiAlias, // Ensures clean rounded corners
    );

    if (result == "Done") {
      await homeController.searchItems();
      _filterAndSortItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _addNewItem,
      ),
      appBar: AppBar(
        title: Text('Product Inventory',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          FilterChip(
            label: Text('Public'),
            selected: public,
            onSelected: (selected) {
              setState(() {
                public = selected;
                _filterAndSortItems();
              });
            },
            selectedColor: Colors.blue.withOpacity(0.2),
            checkmarkColor: Colors.blue,
            labelStyle: TextStyle(
              color: public ? Colors.blue : Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Non-Public'),
            selected: nonPublic,
            onSelected: (selected) {
              setState(() {
                nonPublic = selected;
                _filterAndSortItems();
              });
            },
            selectedColor: Colors.orange.withOpacity(0.2),
            checkmarkColor: Colors.orange,
            labelStyle: TextStyle(
              color: nonPublic ? Colors.orange : Colors.grey[700],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await homeController.searchItems();
              _filterAndSortItems();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          _buildSortOptions(),
          Expanded(
            child: _buildItemList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          tag = '';
                          _filterAndSortItems();
                        },
                      )
                    : null,
                border: InputBorder.none,
              ),
              onChanged: (v) {
                tag = v.toLowerCase();
                _filterAndSortItems();
              },
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text('Sort by:', style: TextStyle(color: Colors.grey[600])),
          SizedBox(width: 8),
          ChoiceChip(
            label: Text('Popularity'),
            selected: _sortBy == 'popularity',
            onSelected: (selected) {
              setState(() {
                _sortBy = 'popularity';
                _filterAndSortItems();
              });
            },
            selectedColor: Colors.blue,
            labelStyle: TextStyle(
              color: _sortBy == 'popularity' ? Colors.white : Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          ChoiceChip(
            label: Text('Price'),
            selected: _sortBy == 'price',
            onSelected: (selected) {
              setState(() {
                _sortBy = 'price';
                _filterAndSortItems();
              });
            },
            selectedColor: Colors.blue,
            labelStyle: TextStyle(
              color: _sortBy == 'price' ? Colors.white : Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
                _filterAndSortItems();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    return Obx(() {
      if (homeController.isItemLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      final items = homeController.itemSearchList.value ?? [];
      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory, size: 48, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              if (tag.isNotEmpty || !public || !nonPublic) ...[
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      tag = '';
                      public = true;
                      nonPublic = true;
                      _searchController.clear();
                      _filterAndSortItems();
                    });
                  },
                  child: Text('Reset filters'),
                ),
              ],
            ],
          ),
        );
      }

      return ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildItemCard(item);
        },
      );
    });
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final isPublic = item['has_products'] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemViewPage(itemId: item['i_id']),
            ),
          ).then((value) async {
            if (value == "Done") {
              await homeController.searchItems();
              _filterAndSortItems();
            }
          });
        },
        // onLongPress: () {
        //   showDialog(
        //     context: context,
        //     builder: (context) {
        //       return AlertDialog(
        //         title: Text("Duplicate Item"),
        //         content: Text("Do you want to create a duplicate item?"),
        //         actions: [
        //           TextButton(
        //             onPressed: () {
        //               Navigator.pop(context); // Close dialog
        //             },
        //             child: Text("Cancel"),
        //           ),
        //           ElevatedButton(
        //             onPressed: () {
        //               if (item['i_id'] == null) return;
        //               Navigator.pop(context); // Close dialog first
        //               _addDuplicateItem(
        //                   item['i_id']); // Your duplicate function here
        //             },
        //             child: Text("Yes, Duplicate"),
        //           ),
        //         ],
        //       );
        //     },
        //   );
        // },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item['image_url'] != null && item['image_url'].isNotEmpty
                    ? Image.network(
                        item['image_url'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderIcon(),
                      )
                    : _buildPlaceholderIcon(),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? 'NA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isPublic)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.visibility_off,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID: ${item['i_id'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${item['price'] ?? 'NA'}',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${item['cart_count'] ?? '0'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
      ),
    );
  }
}
