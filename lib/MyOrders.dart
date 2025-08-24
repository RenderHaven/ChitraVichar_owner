import 'package:chitraowner/ApiManagment/ProductApi.dart';
import 'package:chitraowner/OrderView.dart';
import 'package:chitraowner/UserView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'HomePage.dart';

class MyOrders extends StatefulWidget {
  static Color getStatusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'SHIPPED':
        return Colors.blue;
      case 'NEW':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static void showUpdateStatusDialog(
      BuildContext context, String currentStatus, Function(String) onStatusUpdated) {
    String selectedStatus = currentStatus;
    List<MapEntry<String, Color>> options = [
      MapEntry('NEW', Colors.purple),
      MapEntry("IN_PROGRESS", Colors.orange),
      MapEntry("SHIPPED", Colors.blue),
      MapEntry("DELIVERED", Colors.green),
      MapEntry("CANCELLED", Colors.red),
    ];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Update Order Status", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedStatus,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedStatus = newValue;
                          });
                        }
                      },
                      items: options.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: entry.value.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              entry.key.replaceAll('_', ' '),
                              style: TextStyle(
                                color: entry.value,
                                fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    onStatusUpdated(selectedStatus);
                    Navigator.pop(context);
                  },
                  child: Text("Confirm", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  static Widget OrderCard(Map<String, dynamic> result, BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Colors.grey.withOpacity(0.2),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderInfoPage(orderId: result['id']),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "#${result['id']}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800]),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Status",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4),
                          InkWell(
                            onTap: () =>  MyOrders.showUpdateStatusDialog(
                                context,
                                result['status'],
                                (status) async {
                                  if (await OrderApi.updateOrderStatus(result['id'], status)) {
                                    setState(() {
                                      result['status'] = status;
                                    });
                                  }
                                },
                              ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: getStatusColor(result['status'])
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: getStatusColor(result['status'])
                                      .withOpacity(0.5))),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    result['status']?.replaceAll('_', ' ') ?? 'N/A',
                                    style: TextStyle(
                                      color: getStatusColor(result['status']),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.edit,
                                    size: 14,
                                    color: getStatusColor(result['status'])),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                  ),
                  Text(
                    result['datetime'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey[200]),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                builder: (context) =>  Userview(userId:result['user_id']),
                              );
                            },
                            child: Text(
                              "${result['user_name'] ?? 'NA'}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "₹${result['total_price']}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 3,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Payment",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.5))),
                            child: Text(
                              result['payINFO'] ?? 'N/A',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                              size: 16,
                              color: Colors.redAccent),
                            
                            Expanded(
                              child: Text(
                                "${result['address']}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800]),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  _MyOrdersState createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  final dateFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss z');
  final TextEditingController _searchController = TextEditingController();
  final HomepageController homeController = Get.put(HomepageController());
  String tag = '';
  bool newest = true;
  String _selectedFilter = 'all';
  List<String> _statusFilters = ['all', 'new', 'in_progress', 'shipped', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    if (homeController.orderList.value == null) {
      await homeController.searchOrders();
    }
    homeController.orderSearchList.value = List.from(homeController.orderList.value ?? []);

    sortByDate();
  }

  void sortByDate() {
    var list = homeController.orderSearchList.value ?? [];
    list.sort((a, b) {
      DateTime dateA = dateFormat.parse(a['datetime'] ?? 'N/A');
      DateTime dateB = dateFormat.parse(b['datetime'] ?? 'N/A');
      return newest ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });
    homeController.orderSearchList.value = list;
  }

  void _filterOrders() {
    final orders = homeController.orderList.value ?? [];
    List<Map<String, dynamic>> filteredOrders = [];
    
    // Apply search filter
    if (tag.isNotEmpty) {
      filteredOrders = orders.where((order) => 
        order['user_name'].toString().toLowerCase().contains(tag.toLowerCase()) ||
        order['id'].toString().contains(tag) ||
        order['address'].toString().toLowerCase().contains(tag.toLowerCase())
      ).toList();
    } else {
      filteredOrders = List.from(orders);
    }
    
    // Apply status filter
    if (_selectedFilter != 'all') {
      filteredOrders = filteredOrders.where((order) => 
        order['status'].toString().toLowerCase().contains(_selectedFilter.toLowerCase())
      ).toList();
    }
    
    homeController.orderSearchList.value = filteredOrders;
    sortByDate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: Obx(() {
        return FloatingActionButton(
          backgroundColor: Colors.blue,
          mini: true,
          onPressed: null,
          child: Text(
            '${homeController.orderSearchList.value?.length ?? '0'}',
            style: TextStyle(color: Colors.white),
          ),
        );
      }),
      appBar: AppBar(
        title: Row(
          children: [
            Text('Order Management', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Obx(() => homeController.isOrderLoading.value 
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: Icon(Icons.refresh, size: 20),
                  onPressed: () => homeController.searchOrders(),
                ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: newest ? 'Newest First' : 'Oldest First',
            icon: newest 
              ? Icon(Icons.arrow_downward, size: 20)
              : Icon(Icons.arrow_upward, size: 20),
            onPressed: () {
              setState(() {
                newest = !newest;
              });
              sortByDate();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            SizedBox(height: 16),
            _buildStatusFilter(),
            SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await homeController.searchOrders();
                  _filterOrders();
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: AnalyticsSection()),
                    SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(child: _buildOrderStats()),
                    SliverToBoxAdapter(child: SizedBox(height: 16)),
                    Obx(() {
                      return homeController.isOrderLoading.value
                          ? SliverFillRemaining(
                              child: Center(child: CircularProgressIndicator()))
                          : (homeController.orderSearchList.value ?? []).isEmpty
                              ? SliverFillRemaining(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long, 
                                          size: 48, 
                                          color: Colors.grey[400]),
                                        SizedBox(height: 16),
                                        Text('No orders found',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final result = homeController.orderSearchList.value?[index] ?? {};
                                      return result.containsKey('id')
                                          ? MyOrders.OrderCard(result, context)
                                          : SizedBox.shrink();
                                    },
                                    childCount: homeController.orderSearchList.value?.length ?? 0,
                                  ),
                                );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: 'Search by customer, order ID or address',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    tag = '';
                    _filterOrders();
                  },
                )
              : null,
          border: InputBorder.none,
        ),
        onChanged: (v) {
          tag = _searchController.text.toLowerCase();
          _filterOrders();
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final isSelected = _selectedFilter == filter;
          return ChoiceChip(
            label: Text(
              filter.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
            selected: isSelected,
            selectedColor: Colors.blue,
            backgroundColor: Colors.grey[200],
            onSelected: (selected) {
              setState(() {
                _selectedFilter = selected ? filter : 'all';
              });
              _filterOrders();
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderStats() {
    return Obx(() {
      final orders = homeController.orderSearchList.value ?? [];
      final allOrders = homeController.orderList.value ?? [];
      
      if (allOrders.isEmpty) return SizedBox.shrink();
      
      // Calculate order statistics
      int totalOrders = allOrders.length;
      int completedOrders = allOrders.where((order) => order['status'] == 'DELIVERED').length;
      int pendingOrders = allOrders.where((order) => 
        (order['status'] != 'DELIVERED' && order['status'] != 'CANCELLED')).length;
      int cancelledOrders = allOrders.where((order) => order['status'] == 'CANCELLED').length;
      
      // Calculate revenue
      double totalRevenue = allOrders.fold(0, (sum, order) => sum + (double.tryParse(order['total_price'].toString()) ?? 0));
      double filteredRevenue = orders.fold(0, (sum, order) => sum + (double.tryParse(order['total_price'].toString()) ?? 0));
      
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Analytics', 
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800])),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem(Icons.receipt, 'Total Orders', '$totalOrders', Colors.blue),
                  _buildStatItem(Icons.check_circle, 'Completed', '$completedOrders', Colors.green),
                  _buildStatItem(Icons.pending, 'Pending', '$pendingOrders', Colors.orange),
                  _buildStatItem(Icons.cancel, 'Cancelled', '$cancelledOrders', Colors.red),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[200]),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Showing ${orders.length} of $totalOrders orders',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600])),
                  Text('Revenue: ₹${filteredRevenue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800])),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatItem(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(height: 4),
          Text(title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600])),
          Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color)),
        ],
      ),
    );
  }
}

class AnalyticsSection extends StatelessWidget {
  final HomepageController homeController = Get.find<HomepageController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = homeController.orderList.value ?? [];
      if (orders.isEmpty) return SizedBox.shrink();
      
      // Prepare data for charts
      Map<String, int> statusCounts = {};
      Map<String, double> revenueByStatus = {};
      
      for (var order in orders) {
        String status = order['status'] ?? 'UNKNOWN';
        double amount = double.tryParse(order['total_price'].toString()) ?? 0;
        
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        revenueByStatus[status] = (revenueByStatus[status] ?? 0) + amount;
      }
      
      List<ChartData> statusData = statusCounts.entries.map((e) => 
          ChartData(
              e.key.replaceAll('_', ' '), 
              e.value.toDouble(), 
              MyOrders.getStatusColor(e.key)
          ) // This parenthesis closes the ChartData constructor
      ).toList(); // This parenthesis closes the map() function
      
      List<ChartData> revenueData = revenueByStatus.entries.map((e) => 
        ChartData(e.key.replaceAll('_', ' '), e.value, MyOrders.getStatusColor(e.key)))
        .toList();
      
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Distribution', 
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800])),
              SizedBox(height: 16),
              Container(
                height: 200,
                child: SfCircularChart(
                  legend: Legend(
                    isVisible: true,
                    overflowMode: LegendItemOverflowMode.wrap,
                    position: LegendPosition.bottom,
                  ),
                  series: <CircularSeries>[
                    DoughnutSeries<ChartData, String>(
                      dataSource: statusData,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                      pointColorMapper: (ChartData data, _) => data.color,
                      dataLabelSettings: DataLabelSettings(isVisible: true),
                      enableTooltip: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 200,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  primaryYAxis: NumericAxis(
                    numberFormat: NumberFormat.currency(symbol: '₹')),
                  series: <CartesianSeries>[
                    ColumnSeries<ChartData, String>(
                      dataSource: revenueData,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                      
                      // colorMapper: (ChartData data, _) => data.color,
                      dataLabelSettings: DataLabelSettings(isVisible: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class ChartData {
  final String x;
  final double y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}