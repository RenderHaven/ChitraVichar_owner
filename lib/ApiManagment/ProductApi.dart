import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiUrl ="https://chitravichar-api.onrender.com"; //"http://127.0.0.1:5000";//
const String _apiKey='<@pap@a123>';

class HomeApi{

  static Future<String> sendEmail({
    required List<String> recipients,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/home/send_email'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': _apiKey, // If your API requires it
        },
        body: jsonEncode({
          'emails': recipients,
          'subject': subject,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        print('Email sent successfully!');
        return 'Mail Sent';
      } else if(response.statusCode == 500){
        return 'Wrong Email';
      }
      else {
        print('Failed to send email: ${response.statusCode}');
        print('Response: ${response.body}');
        return 'Failed';
      }
    } catch (e) {
      print('Error sending email: $e');
      return 'Error';
    }
  }


  static Future<Map<String, dynamic>> getSummery() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/home/get_summery'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to get product: ${response.body}'};
      }
    } catch (e) {
      print('Error: $e');
      return {'error': 'Error: $e'};
    }
  }
}
class ProductApi {
  // Function to add a product
  static Future<String> addProduct({
    required String name,
    required String? c_id,
    String description = '',
    double? discount,
    String? type,
    required bool is_active,
    required bool is_new,
    required bool  is_promotion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/product/add_product'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
        body: json.encode({
          'c_id': c_id,
          'name': name,
          'description': description,
          'discount': discount,
          'type': type,
          'is_active':is_active,
          'is_new':is_new,
          'is_promotion':is_promotion,
        }),
      );
      return response.statusCode == 201?json.decode(response.body)['product_id']:'ERROR';
    } catch (e) {
      print('Error: $e');
      return 'ERROR';
    }
  }

  static Future<bool> editProduct({
    required String productId,
    required String name,
    double? discount,
    String? type,
    String? image,
    required bool is_active,
    required bool is_new,
    required bool is_promotion
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/product/edit_product/$productId'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
        body: json.encode({
          'name': name,
          'discount': discount,
          'type': type,
          'image': image,
          'is_active':is_active,
          'is_new':is_new,
          'is_promotion':is_promotion,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  static Future<bool> moveProduct({
    required String productId,
    required String parent_productId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/product/move_product/$productId'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
        body: json.encode({
          'c_id':parent_productId
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  static Future<bool> addProductImage({
    required String product_id,
    required String? image,
  }) async {
    final response = await http.post(
      Uri.parse('$apiUrl/product/upload_product_image'),
      body: jsonEncode({
        "product_id": product_id,
        "display_img":image,
      }),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey, // Security key always included
      },
    );

    return response.statusCode == 201;
  }
  // Function to get products by category
  static Future<List<Map<String, dynamic>>> getProductsByCategory(String? categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/product/get_products_by_category/$categoryId'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          print('Error: Invalid response format');
          return [];
        }
      } else {
        throw();
      }
    } catch (e) {
      print('Error: $e');
      throw(e);
    }
  }

  // Function to get product details by ID
  static Future<Map<String, dynamic>> getProductById(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/product/get_product/$productId'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to get product: ${response.body}'};
      }
    } catch (e) {
      print('Error: $e');
      return {'error': 'Error: $e'};
    }
  }

  // Function to remove product by ID
  static Future<Map<String, dynamic>> removeProduct(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/product/remove_product/$productId'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to remove product: ${response.body}'};
      }
    } catch (e) {
      print('Error: $e');
      return {'error': 'Error: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> search({
    required String query,
    required String searchType, // 'product' or 'item'
  }) async {
    if (query.length < 3) {
      return [{'error': 'Query must be at least 3 characters long'}]; // Return a list with error map
    }

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/$searchType/search?query=$query'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );

      print('Search Response: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [{
          'error': 'Failed to search $searchType',
          'status': response.statusCode,
          'details': response.body,
        }];
      }
    } catch (e) {
      print('Error: $e');
      return [{
        'error': 'An unexpected error occurred.',
        'details': e.toString(),
      }];
    }
  }




  // Function to add items to a product
  static Future<void> addItemsToProduct({
    required String productId,
    required List<String> itemIds, // List of item IDs
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/item/add_items_to_product/$productId'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
        body: json.encode({'item_ids': itemIds}),
      );

      if (response.statusCode == 200) {
        print('Items added to product successfully');
      } else {
        throw Exception('Failed to add items to product');
      }
    } catch (e) {
      throw Exception('Error occurred while adding items: $e');
    }
  }

  static Future<Map<String,dynamic>> fetchTree() async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/product/get_products_treeAdmin'),
        headers: {'Content-Type': 'application/json',"X-API-KEY": _apiKey},
        body: json.encode({}),
      );
      if (response.statusCode == 200) {
        try {

          final Map<String, dynamic> responseData = json.decode(response.body);
          print("Response: ${responseData.keys.toList().length}");
          return responseData;

        } catch (e) {
          print("Error parsing JSON response: $e");
          return {};
        }
      } else {
        print('Failed to fetch data. Status code: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('Error: $e');
      return {};
    }
  }

  static Future<bool> removeItemFromProduct({
    required String productId,
    required String itemId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/product/remove_item_from_product/$productId'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
        body: json.encode({'item_id': itemId}),
      );

      if (response.statusCode == 200) {
        print('Item removed from product successfully');
        return true;
      } else {
        print('Failed to remove item: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  // Function to get product list by category
  static Future<List<Map<String, dynamic>>> getItemsByProduct(String Id) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/product/get_items_by_product/$Id'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          print('Error: Invalid response format');
          return [];
        }
      } else {
        throw(response.body);
      }
    } catch (e) {
      print('Error: $e');
      throw(e);
    }
  }
}
class ItemApi {

  static Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/item/get_all'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [{
          'error': 'Failed to search Item',
          'status': response.statusCode,
          'details': response.body,
        }];
      }
    } catch (e) {
      print('Error: $e');
      return [{
        'error': 'An unexpected error occurred.',
        'details': e.toString(),
      }];
    }
  }
  // Function to add an item
  static Future<String> addItem({
    required String name,
    required String description,
    required double price,
    required int qty,
    required String? productId,
    String? displayImg,
    String? disc_id,
    String? tag_name,
    double? discount,
    List<String?>? variation_value_ids,
  }) async {
    print({
      "name": name,
      "description": description,
      "price": price,
      "stock_quantity": qty,
      "product_id": productId,
      "variation_value_ids": variation_value_ids,
      "disc_id":disc_id,
      "tag_name":tag_name,
      "display_img": displayImg,
      "discount":discount
    });
    final response = await http.post(
      Uri.parse('$apiUrl/item/add_item'),
      body: jsonEncode({
        "name": name,
        "description": description,
        "price": price,
        "stock_quantity": qty,
        "product_id": productId,
        "variation_value_ids": variation_value_ids,
        "disc_id":disc_id,
        "tag_name":tag_name,
        "display_img": displayImg,
        "discount":discount
      }),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey, // Security key always included
      },
    );

    return response.statusCode == 201?json.decode(response.body)['item_id']:'ERROR';
  }


  static Future<bool> addItemImages({
    required String item_id,
    required List<String?> images,
  }) async {
    final response = await http.post(
      Uri.parse('$apiUrl/item/upload_item_images'),
      body: jsonEncode({
        "item_id": item_id,
        "images":images,
      }),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey, // Security key always included
      },
    );

    return response.statusCode == 201;
  }

  static Future<bool> editItemImages({
    required String item_id,
    required List<Map<String, dynamic>> images,
  }) async {
    final response = await http.post(
      Uri.parse('$apiUrl/item/edit_item_images'),
      body: jsonEncode({
        "item_id": item_id,
        "images":images,
      }),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey, // Security key always included
      },
    );

    return response.statusCode == 200;
  }
  // Function to get item by ID
  static Future<Map<String, dynamic>> getItemById(String Id,{String all='true'}) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/item/get_item/$Id/$all'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to get item: ${response.body}'};
      }
    } catch (e) {
      print('Error: $e');
      return {'error': 'Error: $e'};
    }
  }

  // Function to delete an item by ID
  static Future<Map<String, dynamic>> deleteItemById(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/item/remove_item/$id'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'error': 'Failed to delete item',
          'status': response.statusCode,
          'details': response.body,
        };
      }
    } catch (e) {
      print('Error: $e');
      return {
        'error': 'An unexpected error occurred.',
        'details': e.toString(),
      };
    }
  }

  static Future<bool> editItem({
    required String itemId,
    required String name,
    required String description,
    required double price,
    required int qty,
    required String? productId,
    required bool isImgChanged,
    String? displayImg,
    String? disc_id,
    String? tag_name,
    List<dynamic>? variation_value_ids,
    double? discount,
  }) async {
    final response = await http.put(
      Uri.parse('$apiUrl/item/edit_item'),
      body: jsonEncode({
        "item_id": itemId,
        "name": name,
        "description": description,
        "price": price,
        "discount":discount,
        "stock_quantity": qty,
        "product_id": productId,
        "isImgChanged": isImgChanged,
        "display_img": displayImg,
        "variation_value_ids": variation_value_ids,
        "disc_id": disc_id,
        "tag_name": tag_name,
      }),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey, // Security key always included
      },
    );

    return response.statusCode == 200;
  }
  static Future<Map<String, dynamic>> getProductsByItem(String Id) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/item/get_products_by_item/$Id'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to get products: ${response.body}'};
      }
    } catch (e) {
      print('Error: $e');
      return {'error': 'Error: $e'};
    }
  }


}
class DescriptionApi {

  static Future<bool> addDescription({
    required String tag_name,
    required String content,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/description/add_disc'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
        body: json.encode({
          'tag_name' :tag_name,
          'content':content,
        }),
      );
      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> deleteDescription(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/description/remove_disc/$id'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Description deleted successfully'};
      } else {
        return {
          'success': false,
          'error': 'Failed to delete description',
          'status': response.statusCode,
          'details': response.body,
        };
      }
    } catch (e) {
      print('Error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred.',
        'details': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> editDescription(
      String id, String newTagName, String newContent) async {
    if (newTagName.isEmpty || newContent.isEmpty) {
      return {'success': false, 'error': 'Tag name and content cannot be empty'};
    }

    try {
      final response = await http.put(
        Uri.parse('$apiUrl/description/edit_disc/$id'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
        body: json.encode({
          'tag_name': newTagName,
          'content': newContent,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Description updated successfully'};
      } else {
        return {
          'success': false,
          'error': 'Failed to update description',
          'status': response.statusCode,
          'details': response.body,
        };
      }
    } catch (e) {
      print('Error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred.',
        'details': e.toString(),
      };
    }
  }
}
class VariationApi {

  // Function to fetch values for a specific variation
  static Future<List<Map<String, dynamic>>> fetchVariationValues(String variationId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/variation/get_variation_values/$variationId'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      } else {
        print('Failed to fetch variation values: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  // Function to edit variation
  static Future<Map<String, dynamic>> editVariation(String id, String newName, List<Map<String, dynamic>> newOptions) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/variation/edit_variation/$id'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
        body: json.encode({
          'name': newName,
          'options': newOptions,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Variation updated successfully'};
      } else {
        return {
          'success': false,
          'error': 'Failed to update variation',
          'status': response.statusCode,
          'details': response.body,
        };
      }
    } catch (e) {
      print('Error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred.',
        'details': e.toString(),
      };
    }
  }

  // Function to remove variation by ID
  static Future<Map<String, dynamic>> removeVariation(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/variation/delete_variation/$id'),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Variation deleted successfully'};
      } else {
        return {
          'success': false,
          'error': 'Failed to delete variation',
          'status': response.statusCode,
          'details': response.body,
        };
      }
    } catch (e) {
      print('Error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred.',
        'details': e.toString(),
      };
    }
  }
}

class OrderApi{
  /// Fetch all orders
  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    final response = await http.get(
        Uri.parse("$apiUrl/order/get_all"),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, 
        },
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load orders");
    }
  }

  /// Fetch a single order by ID
  static Future<Map<String, dynamic>?> getOrder(String orderId) async {
    final response = await http.get(Uri.parse("$apiUrl/order/get/$orderId"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null; // Order not found
    } else {
      throw Exception("Failed to fetch order");
    }
  }

  /// Update an order
  static Future<bool> updateOrder(String orderId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$apiUrl/order/edit/$orderId"),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey, // Security key always included
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateOrderStatus(String orderId,String status) async {
    final response = await http.put(
      Uri.parse("$apiUrl/order/update_status/$orderId"),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey, // Security key always included
      },
      body: jsonEncode({'status':status}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  /// Delete an order
  static Future<bool> deleteOrder(String orderId) async {
    final response = await http.delete(
        Uri.parse("$apiUrl/order/delete/$orderId"),
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": _apiKey, // Security key always included
        },
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}

class UserApi{
  /// Fetch all orders
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await http.get(Uri.parse("$apiUrl/user/get_all"));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load users");
    }
  }
  //
  // /// Fetch a single order by ID
  // static Future<Map<String, dynamic>?> getOrder(String orderId) async {
  //   final response = await http.get(Uri.parse("$apiUrl/order/get/$orderId"));
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else if (response.statusCode == 404) {
  //     return null; // Order not found
  //   } else {
  //     throw Exception("Failed to fetch order");
  //   }
  // }
  //
  // /// Update an order
  // static Future<bool> updateOrder(String orderId, Map<String, dynamic> data) async {
  //   final response = await http.put(
  //     Uri.parse("$apiUrl/order/edit/$orderId"),
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode(data),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }
  //
  // /// Delete an order
  // static Future<bool> deleteOrder(String orderId) async {
  //   final response = await http.delete(Uri.parse("$apiUrl/order/delete/$orderId"));
  //   if (response.statusCode == 200) {
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }
}

class CouponApi {

  /// Fetch all coupons
  static Future<List<Map<String, dynamic>>> getAllCoupons() async {
    final response = await http.get(
      Uri.parse("$apiUrl/coupon/get_all"),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey,
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load coupons");
    }
  }

  /// Fetch a single coupon by ID
  static Future<Map<String, dynamic>?> getCoupon(String couponId) async {
    final response = await http.get(
      Uri.parse("$apiUrl/coupon/get/$couponId"),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null; // Coupon not found
    } else {
      throw Exception("Failed to fetch coupon");
    }
  }

  /// Add a new coupon
  static Future<bool> addCoupon(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$apiUrl/coupon/add"),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey,
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 201;
  }

  /// Update an existing coupon
  static Future<bool> updateCoupon(String couponId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$apiUrl/coupon/update/$couponId"),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey,
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  /// Delete a coupon
  static Future<bool> deleteCoupon(String couponId) async {
    final response = await http.delete(
      Uri.parse("$apiUrl/coupon/delete/$couponId"),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey,
      },
    );

    return response.statusCode == 200;
  }

  /// Check if a coupon is valid
  static Future<Map<String, dynamic>?> checkCoupon(String couponCode) async {
    final response = await http.get(
      Uri.parse("$apiUrl/check/$couponCode"),
      headers: {
        "Content-Type": "application/json",
        "X-API-KEY": _apiKey,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400 || response.statusCode == 404) {
      return null; // Coupon is invalid or not found
    } else {
      throw Exception("Failed to check coupon");
    }
  }
}