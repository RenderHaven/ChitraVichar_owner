import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chitraowner/ApiManagment/ProductApi.dart';
import 'package:chitraowner/HomePage.dart';

class MyCoupons extends StatefulWidget {
  @override
  _MyCouponsState createState() => _MyCouponsState();
}

class _MyCouponsState extends State<MyCoupons> {
  final TextEditingController _searchController = TextEditingController();
  final HomepageController controller = Get.put(HomepageController());
  String searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    if (controller.couponList.value == null) {
      await controller.fetchCoupons();
    }
    _filterCoupons();
  }

  void _filterCoupons() {
    final couponList = controller.couponList.value ?? [];
    if (searchQuery.isEmpty) {
      controller.couponSearchList.value = List.from(couponList);
    } else {
      controller.couponSearchList.value = couponList
          .where((coupon) =>
              coupon['code'].toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
  }

  Future<void> _addNewCoupon() async {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final maxUsesController = TextEditingController(text: '1');
    final minOrderAmountController = TextEditingController(text: '0');
    String selectedDiscountType = 'percentage';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Create New Coupon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      decoration: InputDecoration(
                        labelText: 'Coupon Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: discountController,
                            decoration: InputDecoration(
                              labelText: 'Discount Amount',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: selectedDiscountType,
                            items: ['percentage', 'fixed']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type.capitalize!),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedDiscountType = value;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: maxUsesController,
                      decoration: InputDecoration(
                        labelText: 'Max Uses (0 for unlimited)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: minOrderAmountController,
                      decoration: InputDecoration(
                        labelText: 'Min Order Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final code = codeController.text.trim();
                                final discount = discountController.text.trim();

                                if (code.isEmpty || discount.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Code and discount are required'),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isLoading = true);
                                final data = {
                                  'code': code,
                                  'discount_amount': double.parse(discount),
                                  'discount_type': selectedDiscountType,
                                  'max_uses': maxUsesController.text
                                          .trim()
                                          .isNotEmpty
                                      ? int.parse(maxUsesController.text.trim())
                                      : 1,
                                  'min_order_amount': minOrderAmountController
                                          .text
                                          .trim()
                                          .isNotEmpty
                                      ? double.parse(
                                          minOrderAmountController.text.trim())
                                      : 0,
                                };

                                final result = await CouponApi.addCoupon(data);

                                if (result) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Coupon added successfully')),
                                  );
                                  Navigator.pop(context);
                                  await controller.fetchCoupons();
                                  _filterCoupons();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Failed to add coupon')),
                                  );
                                }
                                setState(() => _isLoading = false);
                              },
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Create Coupon'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCouponDetails(Map<String, dynamic> coupon) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    coupon['code'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildCouponDetailRow(
                      'Discount',
                      '${coupon['discount_amount']} ${coupon['discount_type'] == 'percentage' ? '%' : '₹'}',
                    ),
                    Divider(),
                    _buildCouponDetailRow(
                      'Max Uses',
                      coupon['max_uses'] == 0
                          ? 'Unlimited'
                          : coupon['max_uses'].toString(),
                    ),
                    Divider(),
                    _buildCouponDetailRow(
                      'Min Order',
                      '₹${coupon['min_order_amount']}',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDeleteCoupon(coupon['id']);
                      },
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _editCoupon(coupon);
                      },
                      child: Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCoupon(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this coupon?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCoupon(id);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCoupon(String id) async {
    final result = await CouponApi.deleteCoupon(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(result ? 'Coupon deleted' : 'Failed to delete coupon')),
    );
    if (result) {
      await controller.fetchCoupons();
      _filterCoupons();
    }
  }

  Future<void> _editCoupon(Map<String, dynamic> coupon) async {
    final codeController = TextEditingController(text: coupon['code']);
    final discountController =
        TextEditingController(text: coupon['discount_amount'].toString());
    final maxUsesController =
        TextEditingController(text: coupon['max_uses'].toString());
    final minOrderAmountController =
        TextEditingController(text: coupon['min_order_amount'].toString());
    String selectedDiscountType = coupon['discount_type'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Coupon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      decoration: InputDecoration(
                        labelText: 'Coupon Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: discountController,
                            decoration: InputDecoration(
                              labelText: 'Discount Amount',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: selectedDiscountType,
                            items: ['percentage', 'fixed']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type.capitalize!),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedDiscountType = value;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: maxUsesController,
                      decoration: InputDecoration(
                        labelText: 'Max Uses (0 for unlimited)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: minOrderAmountController,
                      decoration: InputDecoration(
                        labelText: 'Min Order Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final code = codeController.text.trim();
                                final discount = discountController.text.trim();

                                if (code.isEmpty || discount.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Code and discount are required'),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isLoading = true);
                                final data = {
                                  'code': code,
                                  'discount_amount': double.parse(discount),
                                  'discount_type': selectedDiscountType,
                                  'max_uses': maxUsesController.text
                                          .trim()
                                          .isNotEmpty
                                      ? int.parse(maxUsesController.text.trim())
                                      : 1,
                                  'min_order_amount': minOrderAmountController
                                          .text
                                          .trim()
                                          .isNotEmpty
                                      ? double.parse(
                                          minOrderAmountController.text.trim())
                                      : 0,
                                };

                                final result = await CouponApi.updateCoupon(
                                    coupon['id'], data);

                                if (result) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Coupon updated successfully')),
                                  );
                                  Navigator.pop(context);
                                  await controller.fetchCoupons();
                                  _filterCoupons();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Failed to update coupon')),
                                  );
                                }
                                setState(() => _isLoading = false);
                              },
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Update Coupon'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _addNewCoupon,
      ),
      appBar: AppBar(
        title: Text('Coupon Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await controller.fetchCoupons();
              _filterCoupons();
            },
          ),
        ],
      ),
      body: Padding(
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
                  hintText: 'Search coupons...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            searchQuery = '';
                            _filterCoupons();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  searchQuery = value.toLowerCase();
                  _filterCoupons();
                },
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isCouponLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }

                final coupons = controller.couponSearchList.value ?? [];
                if (coupons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer,
                            size: 48, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No coupons available'
                              : 'No matching coupons found',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        if (searchQuery.isNotEmpty) ...[
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              searchQuery = '';
                              _filterCoupons();
                            },
                            child: Text('Clear search'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: coupons.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    return _buildCouponCard(coupon);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCouponDetails(coupon),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    coupon['code'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      coupon['discount_type'] == 'percentage'
                          ? '${coupon['discount_amount'] ?? 'NA'}% OFF'
                          : '₹${coupon['discount_amount'] ?? 'NA'} OFF',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Min Order: ₹${coupon['min_order_amount']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    coupon['max_uses'] == 0
                        ? 'Unlimited uses'
                        : 'Max ${coupon['max_uses']} uses',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  coupon['use_count'].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
