// ShowItems.dart
import 'package:chitraowner/AddIteamsToProduct.dart';
import 'package:chitraowner/IteamView.dart';
import 'package:flutter/material.dart';
import 'ApiManagment/ProductApi.dart';
import 'EditItem.dart';
import 'HomePage.dart';
import 'Tools.dart';

class ShowItems extends StatefulWidget {
  final String productId;
  
  const ShowItems({
    this.productId = 'Cat1',
    Key? key,
  }) : super(key: key);

  @override
  State<ShowItems> createState() => _ShowItemsState();
}

class _ShowItemsState extends State<ShowItems> {
  List<Map<String, dynamic>> itemsData = [];
  bool isLoading = true;
  bool showDeleteConfirmation = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => isLoading = true);
    
    try {
      final response = await ProductApi.getItemsByProduct(widget.productId);
      setState(() => itemsData = response);
    } catch (e) {
      Homepage.showOverlayMessage(context, 'Error loading items: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildItemsGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Text(
            "Items (${itemsData.length})",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        IconButton(onPressed: _showAddItemSheet, icon: Icon(Icons.add))
      ],
    );
  }

  Widget _buildItemsGrid() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (itemsData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No items found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 500,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemsData.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) => _buildItemCard(itemsData[index]),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemViewPage(itemId: item['i_id']),
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                    child: item['image_url']?.isNotEmpty == true
                        ? ClickableImageNetwork(imageUrl: item['image_url'])
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.image, size: 48, color: Colors.grey),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'No name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item['price'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditItemSheet(item['i_id']),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _confirmItemRemoval(item),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 
  void _showEditItemSheet(String itemId) {
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
        child: EditItem(itemId: itemId),
      ),
    );
  }

  void _showAddItemSheet() {
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
        child:  AddItemsToProduct(
          productId: widget.productId,
          MyItemsId: itemsData.map((d) => d["i_id"].toString()).toList(),
        ),
      ),
    ).then((_) => _fetchItems());
    
  }

  Future<void> _confirmItemRemoval(Map<String, dynamic> item) async {
    if (!showDeleteConfirmation) {
      await _removeItem(item);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text('Are you sure you want to remove this item?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) await _removeItem(item);
  }

  Future<void> _removeItem(Map<String, dynamic> item) async {
    try {
      final success = await ProductApi.removeItemFromProduct(
        itemId: item['i_id'],
        productId: widget.productId,
      );
      
      if (success) {
        Homepage.showOverlayMessage(context, 'Item removed successfully');
        _fetchItems();
      } else {
        throw Exception('Failed to remove item');
      }
    } catch (e) {
      Homepage.showOverlayMessage(context, 'Failed to remove item: $e');
    }
  }
}