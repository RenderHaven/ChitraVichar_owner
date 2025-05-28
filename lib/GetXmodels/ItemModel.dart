import 'package:get/get.dart';

import '../ApiManagment/ProductApi.dart';

class ItemModel {
  String? itemId;
  String name;
  String? description;
  String price;
  int stockQuantity;
  String productId;
  bool isImgChanged;
  String displayImg;
  List<Map<String, dynamic>>? variations;
  List<Map<String, dynamic>>? associatedProducts;
  String? discId;
  String? tagName;
  String? discount;
  List<Map<String, dynamic>>? images;

  ItemModel({
    required this.itemId,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.productId,
    required this.isImgChanged,
    required this.displayImg,
    this.variations,
    this.discId,
    this.discount,
    this.associatedProducts,
    required this.tagName,
    required this.images,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      itemId: json['i_id'],
      name: json['name'] ?? 'NA',
      description: json['description'],
      price: json['price']?.toString() ?? 'NA',
      discount:json['discount']?.toString() ?? 'NA',// Ensure it's a string
      stockQuantity: json['stock_quantity'] ?? 0,  // Ensure it's an int
      productId: json['product_id'] ?? 'NA',
      isImgChanged: json['isImgChanged'] ?? false,
      displayImg: json['display_image_url'] ?? 'NA',
      images: json['images'] != null
          ? List<Map<String, dynamic>>.from(json['images'])
          : [],
      variations: json['variations'] != null
          ? List<Map<String, dynamic>>.from(json['variations'])
          : [],
      discId: json['disc_id'],
      tagName: json['tag_name'] ,
      associatedProducts:  json['products'] != null
          ? List<Map<String, dynamic>>.from(json['products'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'name': name,
      'description': description,
      'price': price,
      'stock_quantity': stockQuantity,
      'product_id': productId,
      'isImgChanged': isImgChanged,
      'display_image_url': displayImg,
      'variations': variations,
      'disc_id': discId,
      'tag_name': tagName,
      'images':images,
    };
  }


}

class ItemController extends GetxController {
  var item = Rxn<ItemModel>(); // Reactive item model
  final String itemId;
  var isLoading = false.obs;
  var isSaving = false.obs;
  ItemController(this.itemId);

  @override
  void onInit() {
    super.onInit();
    fetchItemDetails(); // Call the method when the controller initializes
  }

  Future<void> fetchItemDetails() async {
    try {
      isLoading.value = true;
      final details = await ItemApi.getItemById(itemId);
      if (details.containsKey('error')) {
        throw Exception(details['error']);
      }

      item.value = ItemModel.fromJson(details);
      print(details);
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch item: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addItem({
    required String name,
    required double price,
    required int qty,
    required String productId,
    required String description,
    required String tagName,
    required List<String> variationValueIds,
    String? discId,
    List<String>? images,
  }) async {
    try {
      isSaving.value = true;
      String itemId = await ItemApi.addItem(
        name: name,
        price: price,
        qty: qty,
        disc_id: discId,
        productId: productId,
        description: description.trim(),
        tag_name: tagName.isEmpty ? name : tagName,
        variation_value_ids: variationValueIds,
      );

      if (itemId != 'ERROR') {
        if (images != null && images.isNotEmpty) {
          await ItemApi.addItemImages(item_id: itemId, images: images);
        }
        //await fetchItemDetails(); // Fetch the newly added item
        Get.snackbar("Success", "Item added successfully!");
        return true;
      } else {
        Get.snackbar("Error", "Failed to add item.");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to add item: $e");
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> editItem({
    required String itemId,
    required String name,
    required double price,
    required int qty,
    required String productId,
    required String description,
    required String tagName,
    required List<String> variationValueIds,
    String? discId,
    String? displayImg,
    bool isImgChanged = false,
    List<Map<String, dynamic>>? images,
  }) async {
    try {
      isSaving.value = true;
      bool success = await ItemApi.editItem(
        itemId: itemId,
        name: name,
        productId: productId,
        price: price,
        qty: qty,
        displayImg: displayImg,
        variation_value_ids: variationValueIds,
        description: description.trim(),
        disc_id: discId,
        tag_name: tagName.length < 4 ? name : tagName,
        isImgChanged: isImgChanged,
      );

      if (success) {
        if (images != null && images.isNotEmpty) {
          await ItemApi.editItemImages(item_id: itemId, images: images);
        }
        //await fetchItemDetails(); // Fetch the updated item
        Get.snackbar("Success", "Item edited successfully!");
        return true;
      } else {
        Get.snackbar("Error", "Failed to edit item.");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to edit item: $e");
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}

