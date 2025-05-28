
import 'package:chitraowner/MyCoupens.dart';
import 'package:chitraowner/MyDescription.dart';
import 'package:chitraowner/MyItems.dart';
import 'package:chitraowner/MyOrders.dart';
import 'package:chitraowner/MyUsers.dart';
import 'package:chitraowner/MyVariation.dart';
import 'package:chitraowner/OverView.dart';
import 'package:chitraowner/ProductTree.dart';
import 'package:chitraowner/SendMail.dart';
import 'package:chitraowner/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ApiManagment/ProductApi.dart';

class HomepageController extends GetxController {
  var selectedRoute = Rx<String>('/overview');

  var userSummery = Rxn<Map<String, dynamic>>();
  var itemSummery = Rxn<Map<String, dynamic>>();
  var isSummeryLoading = false.obs;


  var variationList = Rxn<List<Map<String, dynamic>>>();
  var variationSearchList = Rxn<List<Map<String, dynamic>>>();
  var isVariationLoading = false.obs;

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
  void onInit() {
    super.onInit();
    searchUsers();
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
      // print(results);
      orderList.value = results;
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
}

class Homepage extends StatefulWidget {

  static void showOverlayMessage(BuildContext context,String msg) {
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
            ),
            child: Text(
              msg,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove after 3 seconds
    Future.delayed(Duration(seconds: 3)).then((_) => overlayEntry.remove());
  }
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final HomepageController Homecontroller = Get.put(HomepageController());
  final TextEditingController _keyController=TextEditingController();
  final GlobalKey<NavigatorState> _contentNavigatorKey = GlobalKey<NavigatorState>();

  final _key='Chitra@1234';
  String? password;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: _buildColumnLayout(),
      body: Stack(
        children: [
          // Main page content
          Center(
            child: _buildColumnLayout(),
          ),

          // Conditional overlay
          if (password!=_key)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8), // semi-transparent background
                child: Center(
                  child: Card(
                    margin: EdgeInsets.all(5),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 500),
                      // color: Colors.blueGrey,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Hello Admin",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text("Enter your key"),
                          SizedBox(height: 10),
                          TextField(
                            obscureText: true,
                            controller: _keyController,
                            decoration: InputDecoration(
                              labelText: 'Key',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                password=_keyController.text.trim(); // hide overlay on submit
                              });
                            },
                            child: Text("Submit"),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

    );
  }



  /// **Column Layout for Small Screens (Options on top, Content below)**
  Widget _buildColumnLayout() {
    return Column(
      children: [
        /// Options at Top
        Container(
          width: double.infinity,
          color: Colors.grey[200],
          padding: EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildMenuOptions(),
            ),
          ),
        ),

        /// Content Below with its own Navigator
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
                  page=MyCoupons();
                  break;
                case '/dashboard':
                  page=Dashboard();
                  break;
                case '/overview':
                  page=Overview();
                  break;
                case '/promotion':
                  page=PromotionPage();
                  break;
                default:
                  page = Overview();
              }
              return MaterialPageRoute(builder: (_) => page);
            },
          ),
        ),
      ],
    );
  }
  /// **Menu Options**
  List<Widget> _buildMenuOptions() {
    return [
      _buildMenuItem('OverView', '/overview'),
      _buildMenuItem('Dashboard', '/dashboard'),
      _buildMenuItem('My Items', '/items'),
      _buildMenuItem('My Orders', '/orders'),
      _buildMenuItem('My Users', '/users'),
      _buildMenuItem('My Variation', '/variation'),
      _buildMenuItem('My Descriptions', '/description'),
      _buildMenuItem('My Coupons', '/coupon'),
      _buildMenuItem('Promotion', '/promotion'),
    ];
  }

  /// **Menu Item Builder**
  Widget _buildMenuItem(String title, String routeName) {
    return InkWell(
      onTap: () {
        _contentNavigatorKey.currentState?.pushReplacementNamed(routeName);
        Homecontroller.selectedRoute.value=routeName;
      },
      child: Obx((){
        bool isSelected = Homecontroller.selectedRoute.value==routeName;
        return Card(
          color: isSelected?Colors.blue.shade100: null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color:isSelected?Colors.blueAccent:  Colors.greenAccent, width: 1),
          ),
          child: Padding(
            padding:EdgeInsets.all(isSelected?15:12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color:Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      })
    );
  }
}

