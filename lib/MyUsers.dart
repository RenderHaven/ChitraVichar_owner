import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'HomePage.dart';
import 'UserView.dart';

class MyUsers extends StatefulWidget {
  @override
  _MyUsersState createState() => _MyUsersState();
}

class _MyUsersState extends State<MyUsers> {
  final TextEditingController _searchController = TextEditingController();
  final HomepageController homeController = Get.put(HomepageController());
  String tag = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    if (homeController.userList.value == null) {
      await homeController.searchUsers();
    }
    homeController.userSearchList.value = List.from(homeController.userList.value ?? []);
  }

  void _filterUsers() {
    final users = homeController.userList.value ?? [];
    if (tag.isEmpty) {
      homeController.userSearchList.value = users;
    } else {
      homeController.userSearchList.value = users
          .where((user) =>
              user['first_name'].toLowerCase().contains(tag) ||
              (user['last_name']??"").toLowerCase().contains(tag))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Obx(() => Text(
          '${homeController.userSearchList.value?.length ?? 'NA'}',
          style: TextStyle(color: Colors.white),
        )),
        onPressed: () {},
        elevation: 2,
      ),
      appBar: AppBar(
        title: Text('My Users', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () => homeController.searchUsers(),
          ),
        ],
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by Name',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (v) {
                  tag = _searchController.text.toLowerCase();
                  _filterUsers();
                },
              ),
            ),
            
            // SizedBox(height: 20),
            
            // // Stats Cards
            // Details(),
            
            SizedBox(height: 20),
            
            // User List
            Expanded(
              child: Obx(() {
                return homeController.isUserLoading.value
                    ? Center(child: CircularProgressIndicator())
                    : (homeController.userSearchList.value ?? []).isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_alt_outlined, size: 60, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (tag.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      tag = '';
                                      _filterUsers();
                                    },
                                    child: Text('Clear search'),
                                  ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: (homeController.userSearchList.value?.length ?? 0) + 1, // +1 for header
                            separatorBuilder: (context, index) => index == 0 
                                ? SizedBox.shrink() // No separator after header
                                : SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              // Header item (first index)
                              if (index == 0) {
                                return Details();
                              }
                              
                              // Adjust index for user items (subtract 1 to account for header)
                              final user = homeController.userSearchList.value?[index - 1] ?? {};
                              return user.containsKey('id') 
                                  ? _buildUserCard(context, user)
                                  : SizedBox.shrink();
                            },
                          );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) =>  Userview(userId: user['id']),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: (user['profile_picture'] != null) 
                  ? ClipOval(child: Image.network(user['profile_picture'], fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        user['first_name'][0],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
            ),
            
            SizedBox(width: 16),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user['first_name']} ${user['last_name']}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    user['email'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Gender indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (user['gender'] == 'male' 
                    ? Colors.blue[100] 
                    : Colors.pink[100])?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user['gender']?.toUpperCase() ?? 'N/A',
                style: TextStyle(
                  fontSize: 12,
                  color: user['gender'] == 'male' 
                      ? Colors.blue[800] 
                      : Colors.pink[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget Details() {
    return Obx(() {
      final users = homeController.userSearchList.value ?? [];
      int totalUsers = users.length;
      int maleUsers = users.where((user) => user['gender'] == 'male').length;
      int femaleUsers = users.where((user) => user['gender'] == 'female').length;

      return homeController.isUserLoading.value
          ? SizedBox.shrink()
          : Container(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  statCard("Total Users", totalUsers, Icons.people_alt, Colors.blue),
                  
                  statCard("Male Users", maleUsers, Icons.male, Colors.blue),
                  
                  statCard("Female Users", femaleUsers, Icons.female, Colors.pink),
                  
                ],
              ),
            );
    });
  }

  Widget statCard(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),),
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}