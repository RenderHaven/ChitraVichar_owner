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
      floatingActionButton: Obx((){return CircleAvatar(backgroundColor: Colors.blue, child: Text('${homeController.userSearchList.value?.length??'NA'}'));}),
      appBar: AppBar(title: Row(
        children: [
          Text('My Users'),
          IconButton(onPressed:()=> homeController.searchUsers(), icon: Icon(Icons.refresh))
        ],
      )),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    tag = _searchController.text.toLowerCase();
                    _filterUsers();
                  },
                ),
              ),
              onChanged: (v) {
                tag = _searchController.text.toLowerCase();
                _filterUsers();
              },
            ),
            SizedBox(height: 20),
            Details(),
            SizedBox(height: 10),
            Obx(() {
              return homeController.isUserLoading.value
                  ? CircularProgressIndicator()
                  : Expanded(
                child: (homeController.userSearchList.value ?? []).isNotEmpty
                    ? ListView.builder(
                  itemCount: homeController.userSearchList.value?.length ?? 0,
                  itemBuilder: (context, index) {
                    final user = homeController.userSearchList.value?[index] ?? {};
                    return user.containsKey('id') ? 
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          child:(user['profile_picture'] != null) ? Image.network(user['profile_picture'])
                              : Text(user['first_name'][0]),
                        ),
                        title: Text(
                          "${user['first_name']} ${user['last_name']}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📧 ${user['email'] ?? 'N/A'}"),
                            Text("📞 ${user['number'] ?? 'N/A'}"),
                            Text("🎂 ${user['dob'] ?? 'N/A'}"),
                            Text(
                                "🧑‍💼 Gender: ${user['gender']?.toUpperCase() ?? 'N/A'}"),
                          ],
                        ),
                        trailing: IconButton(
                            onPressed:(){
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content:Userview(userId: user['id']),
                                  );
                                },
                              );
                            } , 
                            icon: Icon(Icons.remove_red_eye_outlined,size: 16,)),
                      ),
                    )
                        : Text('NO DATA');
                  },
                )
                    : Text('NO DATA'),
              );
            }),
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
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: statCard("Total Users", totalUsers)),
          Expanded(child: statCard("Male Users", maleUsers)),
          Expanded(child: statCard("Female Users", femaleUsers)),
        ],
      );
    });
  }

  Widget statCard(String title, int value) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blueAccent, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
