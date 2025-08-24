import 'package:chitraowner/additeam.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:product_personaliser/product_personaliser.dart';
import 'ApiManagment/ProductApi.dart';
import 'EditItem.dart';
import 'GetXmodels/ItemModel.dart';
import 'HomePage.dart';
import 'dashboard.dart';
import 'Tools.dart';

class ItemViewPage extends StatefulWidget {
  final String itemId;

  const ItemViewPage({Key? key, required this.itemId}) : super(key: key);

  @override
  _ItemViewPageState createState() => _ItemViewPageState();
}

class _ItemViewPageState extends State<ItemViewPage> {
  String? selectedImage;
  late ItemController controller;

  @override
  void initState() {
    super.initState();
    controller =
        Get.put(ItemController(widget.itemId), tag: widget.itemId.toString());
  }

  void _addDublicateItem() async {
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
      // await homeController.searchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.edit, color: Colors.white),
        onPressed: () {
          if (controller.item.value == null) return;
          showModalBottomSheet(
            context: context,
            isScrollControlled:
                true, // Allows the sheet to expand when keyboard appears
            backgroundColor:
                Colors.transparent, // For the drag handle to be visible
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // Accounts for keyboard
              ),
              child: EditItem(itemId: widget.itemId),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: Obx(() => Text(
              controller.item.value?.name ?? 'Item Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Special Label Banner
              if (widget.itemId == 'Lable')
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Special Item Notice',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Item Mockups → Banner/Label on Site\n'
                        '• Price → Min Price For An Order\n'
                        '• Description → Return Policy',
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                    ],
                  ),
                ),

              // Image Gallery Section
              _buildImageSection(),

              SizedBox(height: 24),

              // Price Section
              _buildPriceSection(),

              SizedBox(height: 16),

              // Template Section
              Obx(() {
                if (controller.item.value?.template != null) {
                  return _buildTemplateCard(controller.item.value!.template!);
                }
                return SizedBox();
              }),

              SizedBox(height: 24),

              // Variations Section
              _buildVariationsSection(),

              SizedBox(height: 16),

              // Description Section
              _buildDescriptionSection(),

              SizedBox(height: 16),

              // Associated Products Section
              _buildAssociatedProductsSection(),

              SizedBox(height: 32),

              // Delete Button
              if (widget.itemId != 'Lable')
                Center(
                  child: Row(
                    spacing: 5,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.delete_outline),
                        label: Text('Delete Item'),
                        style: ElevatedButton.styleFrom(
                          // disabledForegroundColor: ,
                          // primary: Colors.red.shade50,
                          // onPrimary: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.red.shade100),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: _confirmDelete,
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.copy),
                        label: Text('Duplicate Item'),
                        style: ElevatedButton.styleFrom(
                          // disabledForegroundColor: ,
                          // primary: Colors.red.shade50,
                          // onPrimary: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.red.shade100),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: _addDublicateItem,
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

  Widget _buildImageSection() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      final images = controller.item.value?.images ?? [];
      final hasImages = images.isNotEmpty;
      final imageUrl =
          selectedImage ?? (hasImages ? images[0]['image_url'] : null);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Images',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),

          // Main Image
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Image not available'),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No images available'),
                      ],
                    ),
                  ),
          ),
          SizedBox(height: 12),

          // Thumbnails
          if (hasImages)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (context, index) => SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final imageUrl = images[index]['image_url'];
                  return GestureDetector(
                    onTap: () => setState(() => selectedImage = imageUrl),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedImage == imageUrl
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    });
  }

  Widget _buildPriceSection() {
    return Obx(() {
      final item = controller.item.value;
      if (item == null) return SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                '₹${item.price}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.discount != null &&
                  double.parse(item.discount!) > 0) ...[
                SizedBox(width: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.discount}% OFF',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    });
  }

  Widget _buildTemplateCard(DesignTemplate template) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Design Template',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.design_services, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        template.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoPill(
                      icon: Icons.insert_drive_file,
                      text: '${template.pages.length} pages',
                    ),
                    SizedBox(width: 8),
                    _buildInfoPill(
                      icon: Icons.code,
                      text: 'ID: ${template.id ?? 'N/A'}',
                    ),
                  ],
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.remove_red_eye, size: 18),
                    label: Text('Preview Template'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) =>
                            ProductDesigner(template: template),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariationsSection() {
    return Obx(() {
      final variations = controller.item.value?.variations ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Variations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),
          if (variations.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'No variations available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...variations.map((variation) {
              String variationName = variation['variation_name'] ?? 'NA';
              List<dynamic> options = variation['options'] ?? [];

              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variationName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: options.map((option) {
                        return Chip(
                          label: Text(
                            option['value'] ?? 'NA',
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue.shade50,
                          side: BorderSide(color: Colors.blue.shade100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      );
    });
  }

  Widget _buildDescriptionSection() {
    return Obx(() {
      final description = controller.item.value?.description;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),
          if (description == null || description.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'No description available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                description,
                style: TextStyle(height: 1.5),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildAssociatedProductsSection() {
    return Obx(() {
      final products = controller.item.value?.associatedProducts ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Associated Products',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),
          if (products.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'No associated products',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: products.map((product) {
                return ActionChip(
                  label: Text(product['name']),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onPressed: () {
                    final HomepageController homeController =
                        Get.put(HomepageController());
                    homeController.selectedRoute.value = '/dashboard';
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Dashboard(productId: product['p_id']),
                      ),
                    ).then((_) => controller.fetchItemDetails());
                  },
                );
              }).toList(),
            ),
        ],
      );
    });
  }

  Widget _buildInfoPill({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item?'),
        content: Text(
            'Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteItem();
    }
  }

  Future<void> _deleteItem() async {
    try {
      if (widget.itemId == 'Lable') {
        Homepage.showOverlayMessage(context, 'Cannot delete special item');
        return;
      }

      final response = await ItemApi.deleteItemById(widget.itemId);
      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      Get.delete<ItemController>(tag: widget.itemId);
      Homepage.showOverlayMessage(context, 'Item deleted successfully');
      Navigator.pop(context, 'Done');
    } catch (e) {
      Homepage.showOverlayMessage(context, 'Failed to delete item: $e');
    }
  }
}
