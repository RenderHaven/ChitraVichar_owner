import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ApiManagment/ProductApi.dart';
import 'EditProduct.dart';
import 'HomePage.dart';
import 'SearchProducts.dart';
import 'Tools.dart';
import 'addproduct.dart';
import 'dashboard.dart';

class Showproducts extends StatefulWidget {
  final String? categoryId;
  final String oldpath;
  
  const Showproducts({
    this.categoryId,
    this.oldpath = 'New',
    Key? key,
  }) : super(key: key);

  @override
  State<Showproducts> createState() => _ShowproductsState();
}

class _ShowproductsState extends State<Showproducts> {
  final HomepageController homepageController = Get.put(HomepageController());
  List<dynamic> productsData = [];
  bool isLoading = true;
  bool _showDeleteConfirmationDialog = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    
    try {
      final response = await ProductApi.getProductsByCategory(widget.categoryId);
      setState(() => productsData = response);
    } catch (e) {
      Homepage.showOverlayMessage(context, 'Error loading products: $e');
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
        _buildProductsList(),
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
            "Products (${productsData.length})",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        IconButton(onPressed: _showAddProductDialog , icon: Icon(Icons.add))
      ],
    );
  }

  Widget _buildProductsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (productsData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No products found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productsData.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildProductCard(productsData[index]),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isActive = product['is_active'] ?? true;
    final isNew = product['is_new'] ?? false;
    final canEdit = product['c_id'] != null;

    return SizedBox(
      width: 180,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToProductDashboard(product),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Image
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? Colors.blue[50] 
                          : Colors.red[50],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: product['image_url']?.isNotEmpty == true
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: ClickableImageNetwork(
                              imageUrl: product['image_url'],
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image, size: 48, color: Colors.grey),
                          ),
                  ),
                  
                  // Product Info
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'No name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${product['type'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discount: ${product['discount'] ?? '0'}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Status Badges
              if (isNew)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              if (!isActive)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'INACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              // Action Buttons
              if (canEdit) ...[
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditProductDialog(product),
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
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _confirmProductDeletion(product),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.drive_file_move_outline, size: 20),
                    onPressed: () => _showMoveProductSheet(product),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProductDashboard(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Dashboard(
          productId: product['p_id'],
          path: '${widget.oldpath} > ${product['name']}',
        ),
      ),
    );
  }

  void _showAddProductDialog() {
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
        child: AddProduct(categoryId: widget.categoryId),
      ),
    ).then((value) {
      if (value == 'Done') _fetchProducts();
    });
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
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
        child: EditProduct(
          productId: product['p_id'],
          productData: product,
        ),
      ),
    ).then((value) {
      if (value == 'Done') _fetchProducts();
    });
  }

  void _showMoveProductSheet(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Move Product To',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            SearchBarWidget(searchType: 'product'),
          ],
        ),
      ),
    ).then((result) async {
      if (result?['p_id'] == null) return;
      try {
        await ProductApi.moveProduct(
          productId: product['p_id'],
          parent_productId: result['p_id'],
        );
        _fetchProducts();
        Homepage.showOverlayMessage(context, 'Product moved successfully');
      } catch (e) {
        Homepage.showOverlayMessage(context, 'Failed to move product: $e');
      }
    });
  }

  Future<void> _confirmProductDeletion(Map<String, dynamic> product) async {
    if (!_showDeleteConfirmationDialog) {
      await _deleteProduct(product);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Product',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this product?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: This will also delete all sub-products',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: !_showDeleteConfirmationDialog,
                  onChanged: (value) {
                    setState(() {
                      _showDeleteConfirmationDialog = !(value ?? false);
                    });
                    Navigator.pop(context, false);
                  },
                ),
                const Text("Don't show again"),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) await _deleteProduct(product);
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    try {
      final response = await ProductApi.removeProduct(product['p_id']);
      
      if (!response.containsKey('error')) {
        Homepage.showOverlayMessage(context, 'Product deleted successfully');
        _fetchProducts();
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      Homepage.showOverlayMessage(context, 'Failed to delete product: $e');
    }
  }
}