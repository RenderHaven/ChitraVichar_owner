import 'package:chitraowner/ApiManagment/ProductApi.dart';
import 'package:chitraowner/HomePage.dart';
import 'package:chitraowner/MyOrders.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:get/get.dart';

class Userview extends StatelessWidget {
  final HomepageController Homecontroller = Get.put(HomepageController());
  final String userId;
  
  Userview({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userData = Homecontroller.userList.value?.firstWhere(
      (user) => userId == user['id'],
      orElse: () => {},
    );

    int totalOrders = 0;
    int completedOrders = 0;
    
    Homecontroller.orderList.value?.where((item) => item['user_id'] == userId).forEach((value) {
      if (value['status'] == 'DELIVERED') completedOrders++;
      totalOrders++;
    });

    return Scaffold(
      body:userData!=null && userData.isNotEmpty? SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:Column(
          children: [
            _buildUserCard(userData, context),
            const SizedBox(height: 16),
            _buildEmailCard(context, userData['email']),
            const SizedBox(height: 16),
            _buildOrderStatsCard(completedOrders, totalOrders),
            const SizedBox(height: 16),
            _buildOrdersSection(context, userId, userData['first_name'] ?? 'Customer'),
          ],
        ),
      ):Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No User',style: TextStyle(fontSize: 16),),
            Text('Somthing Went Wrong')
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: user['profile_picture'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.network(
                        user['profile_picture'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      user['first_name'][0],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user['first_name']} ${user['last_name']}",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildUserDetailRow(Icons.email, user['email'] ?? 'N/A'),
                  _buildUserDetailRow(Icons.phone, user['number'] ?? 'N/A'),
                  _buildUserDetailRow(Icons.cake, user['dob'] ?? 'N/A'),
                  _buildUserDetailRow(
                    Icons.transgender,
                    "Gender: ${user['gender']?.toString().toUpperCase() ?? 'N/A'}",
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // Add delete functionality
              },
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Delete user',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCard(BuildContext context, String? email) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEmailDialog(context, email),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Text(
                'Send Email',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmailDialog(BuildContext context, String? email) {
    final toController = TextEditingController(text: email);
    final subjectController = TextEditingController(text: 'Order Update');
    final messageController = TextEditingController(text: 'Your Order With OrderId=[ID] is ready to [STATUS]');

    Future<void> sendEmail() async {
      final to = Uri.encodeComponent(toController.text.trim());
      final subject = Uri.encodeComponent(subjectController.text.trim());
      final body = Uri.encodeComponent(messageController.text.trim());

      if (to.isEmpty || subject.isEmpty || body.isEmpty) {
        Homepage.showOverlayMessage(context, 'Please fill all fields');
        return;
      }

      final ans = await HomeApi.sendEmail(
        recipients: [to],
        subject: subject,
        message: body,
      );

      Homepage.showOverlayMessage(context, ans);
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Compose Email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: toController,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: sendEmail,
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderStatsCard(int completedOrders, int totalOrders) {
    
    final progress = totalOrders > 0 ? completedOrders / totalOrders : 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Order Summary",
              // style: theme.textTheme.titleMedium?.copyWith(
              //   fontWeight: FontWeight.bold,
              // ),
            ),
            const SizedBox(height: 20),
            CircularPercentIndicator(
              radius: 60.0,
              lineWidth: 12.0,
              percent: progress,
              center: Text(
                "$completedOrders/$totalOrders",
                
              ),
              // progressColor: theme.colorScheme.primary,
              // backgroundColor: theme.colorScheme.surfaceVariant,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBadge(
                  "Completed",
                  completedOrders,
                  Colors.blue
                ),
                _buildStatBadge(
                  "Pending",
                  totalOrders - completedOrders,
                  Colors.grey
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersSection(BuildContext context, String userId, String name) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (Homecontroller.orderList.value == null) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final userOrders = Homecontroller.orderList.value!
                  .where((item) => item['user_id'] == userId)
                  .toList();

              if (userOrders.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No orders found'),
                  ),
                );
              }

              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: userOrders.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  return MyOrders.OrderCard(userOrders[index], context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}