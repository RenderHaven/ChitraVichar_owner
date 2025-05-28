import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'ApiManagment/ProductApi.dart';
import 'HomePage.dart';
import 'UserView.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PageState();
}

class _PageState extends State<PromotionPage> {
  bool _isSending=false;
  final Set<String> toList={};
  final HomepageController Homecontroller = Get.put(HomepageController());
  // final toController = TextEditingController(text: 'vikrambalai1002@gmail.com');
  final subjectController = TextEditingController(text: 'New');
  final messageController = TextEditingController(text: 'Try');

  Future<void> sendEmail() async {
    setState(() {
      _isSending=true;
    });
    final subject = subjectController.text.trim();
    final body =messageController.text.trim();
    if(toList.isEmpty||subject.isEmpty ||body.isEmpty){
      Homepage.showOverlayMessage(context, 'Fill All Field');
      return;
    };
    final ans=await HomeApi.sendEmail(recipients: toList.toList(), subject:subject, message:body) ;

    Homepage.showOverlayMessage(context, ans);
    setState(() {
      _isSending=false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Email ')),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 4,
              ),
              SizedBox(height: 10,),
              CustomerList(context),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:_isSending?null:sendEmail,
                child: _isSending?Text('Sending...'):const Text('Send Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget CustomerList(BuildContext context){
    return Container(
      width: 500,
      padding: EdgeInsets.symmetric(horizontal:5,vertical: 10),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10)
      ),
      // color: Colors.grey,
      child: Column(
        children: [
          Text('Select Customers',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),),
          Obx(() {
            if (Homecontroller.userList.value == null) {
              return SizedBox.shrink();
            }
            return Container(
              constraints: BoxConstraints(maxHeight: 500),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...Homecontroller.userList.value!.map((user) {
                    return ListTile(
                      onTap: (){
                        setState(() {
                          if(toList.contains(user['email']))toList.remove(user['email']);
                          else toList.add(user['email']);
                        });
                      },
                      leading: (Homecontroller.userSummery.value??{}).containsKey(user['id'])?Icon(Icons.verified_user):null,
                      selectedColor: Colors.green,
                      selected: toList.contains(user['email']),
                      title: Text(user['first_name']??'NA'),
                      subtitle:Text(user['email']??'NA') ,
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
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
