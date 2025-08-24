import 'package:chitraowner/MyCoupens.dart';
import 'package:chitraowner/MyDescription.dart';
import 'package:chitraowner/MyItems.dart';
import 'package:chitraowner/MyOrders.dart';
import 'package:chitraowner/MyTemplates.dart';
import 'package:chitraowner/MyUsers.dart';
import 'package:chitraowner/MyVariation.dart';
import 'package:chitraowner/OverView.dart';
import 'package:chitraowner/ProductTree.dart';
import 'package:chitraowner/Reviews.dart';
import 'package:chitraowner/SendMail.dart';
import 'package:chitraowner/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:product_personaliser/product_personaliser.dart';
import 'dart:html' as html;
import 'ApiManagment/ProductApi.dart';


class HomepageController extends GetxController {
  var selectedRoute = Rx<String>('/overview');

  var userSummery = Rxn<Map<String, dynamic>>();
  var itemSummery = Rxn<Map<String, dynamic>>();
  var isSummeryLoading = false.obs;


  var variationList = Rxn<List<Map<String, dynamic>>>();
  var variationSearchList = Rxn<List<Map<String, dynamic>>>();
  var isVariationLoading = false.obs;

  var templateList = Rxn<List<DesignTemplate>>();
  var templateSearchList = Rxn<List<DesignTemplate>>();
  var isTemplateLoading = false.obs;

  var orderList = Rxn<List<Map<String, dynamic>>>();
  var orderSearchList = Rxn<List<Map<String, dynamic>>>();
  var isOrderLoading = false.obs;

  var userList = Rxn<List<Map<String, dynamic>>>();
  var userSearchList = Rxn<List<Map<String, dynamic>>>();
  var isUserLoading = false.obs;

  var itemList = Rxn<List<Map<String, dynamic>>>();
  var itemSearchList = Rxn<List<Map<String, dynamic>>>();
  var isItemLoading = false.obs;

  var productList = Rxn<List<Map<String, dynamic>>>();
  var productSearchList = Rxn<List<Map<String, dynamic>>>();
  var isProductLoading = false.obs;

  var descriptionList = Rxn<List<Map<String, dynamic>>>();
  var descriptionSearchList = Rxn<List<Map<String, dynamic>>>();
  var isDescriptionLoading = false.obs;

  var couponList = Rxn<List<Map<String, dynamic>>>();
  var couponSearchList = Rxn<List<Map<String, dynamic>>>();
  var isCouponLoading = false.obs;

  var productsData = <String, dynamic>{}.obs;
  var isTreeLoading = false.obs;
  @override
  void onInit() async{
    super.onInit();
    await searchUsers();
    searchOrders();
    fetchSummery();
    fetchProductsTree();
    searchVariations();
    searchDescriptions();
  }


  Future<void> fetchSummery() async {

    isSummeryLoading.value = true;
    try{
      final responseData=await HomeApi.getSummery();

      itemSummery.value=Map<String,dynamic>.from(responseData['itemData'] ?? {});
      userSummery.value=Map<String,dynamic>.from(responseData['userData'] ?? {});

    }catch(e){
      print(e);
    }finally{
      print("done getting");
      isSummeryLoading.value = false;
    }
  }



  Future<void> fetchProductsTree() async {

    isTreeLoading.value = true;
    try{
      final responseData=await ProductApi.fetchTree();
      responseData.forEach((productId, productData) {
        if (productData != null && productData is Map<String, dynamic>) {
          final pData = productData;
          pData['sub_products']=List<String>.from(productData['sub_products'] ?? []);
          // if(pData['is_new'])latestProducts.add(pData);
          // if(pData['is_promotion'])promotionProducts.add(pData);
          // if(pData['c_id']=='Home')homeProducts.add(pData);
          productsData[productId]=pData;
        } else {
          print("Warning: No data found for product ID $productId");
        }
      });
    }catch(e){
      print(e);
    }finally{
      print("done getting");
      isTreeLoading.value = false;
    }
  }
  // ✅ Search Variations
  Future<void> searchVariations({String tag = '<all>'}) async {
    isVariationLoading.value = true;
    try {
      final results = await ProductApi.search(query: tag, searchType: "variation");
      variationList.value = results;
    } catch (e) {
      print("Error fetching variations: $e");
    } finally {
      isVariationLoading.value = false;
    }
  }

  Future<void> fetchCoupons() async {
    isCouponLoading.value = true;
    try {
      final results = await CouponApi.getAllCoupons();
      couponList.value = results;
    } catch (e) {
      print("Error fetching variations: $e");
    } finally {
      isCouponLoading.value = false;
    }
  }

  // ✅ Search Orders
  Future<void> searchOrders() async {
    isOrderLoading.value = true;
    try {
      final results = await OrderApi.getAllOrders();

      // Attach user_name to each order
      final updatedOrders = results.map((order) {
        final user = userList.value?.firstWhere(
          (user) => order['user_id'] == user['id'],
          orElse: () => {'first_name': 'Unknown'},
        );
        order['user_name'] = user?['first_name'] ?? 'Unknown';
        return order;
      }).toList();

      orderList.value = updatedOrders;
    } catch (e) {
      print("Error fetching orders: $e");
    } finally {
      isOrderLoading.value = false;
    }
  }


  // ✅ Search Users
  Future<void> searchUsers() async {
    isUserLoading.value = true;
    try {
      final results = await UserApi.getAllUsers();
      userList.value = results;
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      isUserLoading.value = false;
    }
  }

  // ✅ Search Items
  Future<void> searchItems() async {
    isItemLoading.value = true;
    try {
      final results = await ItemApi.getAll();
      itemList.value = results;
    } catch (e) {
      print("Error fetching items: $e");
    } finally {
      isItemLoading.value = false;
    }
  }

  // ✅ Search Products
  Future<void> searchProducts({String productName = '<all>'}) async {
    isProductLoading.value = true;
    try {
      final results = await ProductApi.search(query: productName, searchType: 'product');
      productList.value = results;
    } catch (e) {
      print("Error fetching products: $e");
    } finally {
      isProductLoading.value = false;
    }
  }

  // ✅ Search Descriptions
  Future<void> searchDescriptions({String tag = '<all>'}) async {
    isDescriptionLoading.value = true;
    try {
      final results = await ProductApi.search(query: tag, searchType: "description");
      descriptionList.value = results;
    } catch (e) {
      print("Error fetching descriptions: $e");
    } finally {
      isDescriptionLoading.value = false;
    }
  }

  Future<void> fetchTemplates() async {
    isTemplateLoading.value = true;
    try {
      final List<Map<String, dynamic>> data = await TemplateApi.getAll();

      final templates = data.map((json) => DesignTemplate.fromData(json)).toList();

      templateList.value = templates;
    } catch (e) {
      print("Error fetching templates: $e");
    } finally {
      isTemplateLoading.value = false;
    }
  }
}

class Homepage extends StatefulWidget {
  static void showOverlayMessage(BuildContext context, String msg) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 30,
        right: 30,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  msg,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(Duration(seconds: 3)).then((_) => overlayEntry.remove());
  }

  Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final HomepageController homeController = Get.put(HomepageController());
  final GlobalKey<NavigatorState> _contentNavigatorKey = GlobalKey<NavigatorState>();
  bool _isDrawerOpen = false;

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    html.window.location.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.store, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'ChitraVichar Admin',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _clearAuth,
          ),
        ],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[800]!, Colors.blue[600]!],
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: Row(
        children: [
          // Sidebar for larger screens
          if (MediaQuery.of(context).size.width > 800) _buildDesktopSidebar(),
          // Main content area
          Expanded(
            child: Navigator(
              key: _contentNavigatorKey,
              onGenerateRoute: (settings) {
                Widget page;
                switch (settings.name) {
                  case '/items':
                    page = MyItems();
                    break;
                  case '/orders':
                    page = MyOrders();
                    break;
                  case '/users':
                    page = MyUsers();
                    break;
                  case '/variation':
                    page = MyVariation();
                    break;
                  case '/description':
                    page = MyDescription();
                    break;
                  case '/coupon':
                    page = MyCoupons();
                    break;
                  case '/dashboard':
                    page = Dashboard();
                    break;
                  case '/overview':
                    page = Overview();
                    break;
                  case '/templates':
                    page = MyTemplates();
                    break;
                  case '/promotion':
                    page = PromotionPage();
                    break;
                  case '/reviews':
                    page = ReviewPage();
                    break;
                  default:
                    page = Overview();
                }
                return MaterialPageRoute(builder: (_) => page);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[800]!, Colors.blue[600]!],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store, size: 40, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _buildMenuOptions(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 250,
      color: Colors.grey[100],
      child: Column(
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[800]!, Colors.blue[600]!],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 40, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _buildMenuOptions(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuOptions() {
    final List<Map<String, dynamic>>  menuItems = [
      {'title': 'Dashboard', 'route': '/overview', 'icon': Icons.dashboard},
      {'title': 'Overview', 'route': '/dashboard', 'icon': Icons.analytics},
      {'title': 'Products', 'route': '/items', 'icon': Icons.inventory},
      {'title': 'Orders', 'route': '/orders', 'icon': Icons.shopping_cart},
      {'title': 'Customers', 'route': '/users', 'icon': Icons.people},
      {'title': 'Variations', 'route': '/variation', 'icon': Icons.category},
      {'title': 'Descriptions', 'route': '/description', 'icon': Icons.description},
      {'title': 'Coupons', 'route': '/coupon', 'icon': Icons.local_offer},
      {'title': 'Templates', 'route': '/templates', 'icon': Icons.pages},
      {'title': 'Reviews', 'route': '/reviews', 'icon': Icons.reviews},
      {'title': 'Promotions', 'route': '/promotion', 'icon': Icons.campaign},
    ];

    return menuItems.map((item) {
      return Obx(() {
        bool isSelected = homeController.selectedRoute.value == item['route'];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              item['icon'],
              color: isSelected ? Colors.blue[800] : Colors.grey[700],
            ),
            title: Text(
              item['title'],
              style: TextStyle(
                color: isSelected ? Colors.blue[800] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            tileColor: isSelected ? Colors.blue[50] : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () {
              _contentNavigatorKey.currentState?.pushReplacementNamed(item['route']);
              homeController.selectedRoute.value = item['route'];
              if (MediaQuery.of(context).size.width <= 800) {
                Navigator.of(context).pop();
                setState(() {
                  _isDrawerOpen = false;
                });
              }
            },
          ),
        );
      });
    }).toList();
  }
}
