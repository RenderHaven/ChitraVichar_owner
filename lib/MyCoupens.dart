import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ApiManagment/ProductApi.dart';
import 'HomePage.dart';

class MyCoupons extends StatefulWidget {
  @override
  _MyCouponsState createState() => _MyCouponsState();
}

class _MyCouponsState extends State<MyCoupons> {
  final TextEditingController _searchController = TextEditingController();
  final HomepageController controller = Get.put(HomepageController());
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    if (controller.couponList.value == null) {
      await controller.fetchCoupons();
    }
    controller.couponSearchList.value = List.from(controller.couponList.value ?? []);
  }

  void _filterCoupons() {
    print('Filtering for $searchQuery');
    final couponList = controller.couponList.value ?? [];
    if (searchQuery.isEmpty) {
      controller.couponSearchList.value = couponList;
    } else {
      controller.couponSearchList.value = couponList
          .where((coupon) =>
          coupon['code'].toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
  }

  void _addNewCoupon() {
    final TextEditingController codeController = TextEditingController();
    final TextEditingController discountController = TextEditingController();
    final TextEditingController maxUsesController = TextEditingController();
    final TextEditingController minOrderAmountController = TextEditingController();
    String selectedDiscountType = 'percentage'; // Default value
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context,setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add New Coupon'),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close))
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(labelText: 'Coupon Code'),
                  ),
                  TextField(
                    controller: discountController,
                    decoration: InputDecoration(labelText: 'Discount Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedDiscountType,
                    items: ['fixed', 'percentage']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type.capitalize!)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedDiscountType = value;
                      }
                    },
                    decoration: InputDecoration(labelText: 'Discount Type'),
                  ),
                  TextField(
                    controller: maxUsesController,
                    decoration: InputDecoration(labelText: 'Max Uses'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: minOrderAmountController,
                    decoration: InputDecoration(labelText: 'Min Order Amount'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    print(isAdding);
                    if (isAdding) return;
                    setState(() {
                      isAdding = true;
                    });
                    final code = codeController.text.trim();
                    final discount = discountController.text.trim();
                    final maxUses = maxUsesController.text.trim();
                    final minOrderAmount = minOrderAmountController.text.trim();

                    if (code.isEmpty || discount.isEmpty) {
                      Homepage.showOverlayMessage(context, 'Code and discount cannot be empty');
                      return;
                    }

                    final data = {
                      'code': code,
                      'discount_amount': double.parse(discount),
                      'discount_type': selectedDiscountType,
                      'max_uses': maxUses.isNotEmpty ? int.parse(maxUses) : 1,
                      'min_order_amount': minOrderAmount.isNotEmpty ? double.parse(minOrderAmount) : 0,
                    };
                    final result = await CouponApi.addCoupon(data);

                    if (result) {
                      Homepage.showOverlayMessage(context, "Coupon Added");
                      Navigator.pop(context);
                      await controller.fetchCoupons();
                      _filterCoupons();
                    } else {
                      Homepage.showOverlayMessage(context, "Error adding coupon");                    }

                    setState(() {
                      isAdding = false;
                    });
                  },
                  child: isAdding ? CircularProgressIndicator() : Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showCouponDetails(Map<String, dynamic> coupon) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(coupon['code']),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close))
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Discount Amount: ${coupon['discount_amount']}"),
              Text("Discount Type: ${coupon['discount_type']}"),
              Text("Max Uses: ${coupon['max_uses']}"),
              Text("Min Order Amount: ${coupon['min_order_amount']}"),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCoupon(coupon['id']);
              },
              child: Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _editCoupon(coupon);
              },
              child: Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  void _editCoupon(Map<String, dynamic> coupon) {
    final TextEditingController codeController =
    TextEditingController(text: coupon['code']);
    final TextEditingController discountController =
    TextEditingController(text: coupon['discount_amount'].toString());
    final TextEditingController maxUsesController =
    TextEditingController(text: coupon['max_uses'].toString());
    final TextEditingController minOrderAmountController =
    TextEditingController(text: coupon['min_order_amount'].toString());
    String selectedDiscountType = coupon['discount_type'].toString(); // Default value
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context,setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Coupon'),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close))
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(labelText: 'Coupon Code'),
                  ),
                  TextField(
                    controller: discountController,
                    decoration: InputDecoration(labelText: 'Discount Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedDiscountType,
                    items: ['fixed', 'percentage']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type.capitalize!)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedDiscountType = value;
                      }
                    },
                    decoration: InputDecoration(labelText: 'Discount Type'),
                  ),
                  TextField(
                    controller: maxUsesController,
                    decoration: InputDecoration(labelText: 'Max Uses'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: minOrderAmountController,
                    decoration: InputDecoration(labelText: 'Min Order Amount'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (isSaving) return;
                    final newCode = codeController.text.trim();
                    final newDiscount = discountController.text.trim();

                    if (newCode.isEmpty || newDiscount.isEmpty) {
                      Homepage.showOverlayMessage(context, 'Code and discount cannot be empty');
                      return;
                    }

                    setState(() {
                      isSaving = true;
                    });
                    final data={
                      'discount_type':selectedDiscountType,
                      'code':newCode,
                      'discount_amount':double.parse(newDiscount),
                      'max_uses':maxUsesController.text.trim().isNotEmpty ? int.parse(maxUsesController.text.trim()) : 1,
                      'min_order_amount': minOrderAmountController.text.trim().isNotEmpty
                          ? double.parse(minOrderAmountController.text.trim())
                          : 0,
                    };
                    final result = await CouponApi.updateCoupon(coupon['id'],data);

                    if (result) {
                      Homepage.showOverlayMessage(context, "Coupon Updated");
                      Navigator.pop(context);
                      await controller.fetchCoupons();
                      _filterCoupons();
                    } else {
                      Homepage.showOverlayMessage(context, "Error updating coupon");
                    }

                    setState(() {
                      isSaving = false;
                    });
                  },
                  child: isSaving ? CircularProgressIndicator() : Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteCoupon(String id) async {
    final result = await CouponApi.deleteCoupon(id);
    if (result) {
      Homepage.showOverlayMessage(context, "Coupon Deleted");
      await controller.fetchCoupons();
      _filterCoupons();
    } else {
      Homepage.showOverlayMessage(context, "Error deleting coupon");    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Obx((){return CircleAvatar(backgroundColor: Colors.blue, child: Text('${controller.couponSearchList.value?.length??'NA'}'));}),
      appBar: AppBar(
        title: Text('My Coupons'),
        actions: [IconButton(icon: Icon(Icons.add), onPressed: _addNewCoupon)],
      ),
      body: Obx(() => controller.isCouponLoading.value
          ? Center(child: CircularProgressIndicator())
          : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by Code',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: (){
                        searchQuery=_searchController.text.toLowerCase()??'';
                        _filterCoupons();
                      },
                    ),
                  ),
                  // onSubmitted: (value) {
                  //   // Trigger search when Enter is pressed
                  //   _filterVariation();
                  // },
                  onChanged:(v){
                    searchQuery=_searchController.text.toLowerCase()??'';
                    _filterCoupons();
                  },
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView(
                          children: controller.couponSearchList.value
                    ?.map((coupon) => Card(
                      child: ListTile(
                                title: Text(coupon['code']),
                                onTap: () => _showCouponDetails(coupon),
                              ),
                    ))
                    .toList() ??
                    [],
                        ),
                ),
              ],
            ),
          )),
    );
  }
}
