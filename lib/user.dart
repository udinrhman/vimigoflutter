import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vimigoflutter/search.dart';
import 'package:share_plus/share_plus.dart';

// ignore: must_be_immutable
class UserInfo extends StatefulWidget {
  String value;
  String text = '';
  String subject = '';
  UserInfo({super.key, required this.value});

  @override
  _UserInfoState createState() => _UserInfoState(value);
}

class _UserInfoState extends State<UserInfo> {
  String value;
  _UserInfoState(this.value);

  final controllerUser = TextEditingController();
  final controller = TextEditingController();
  final f = DateFormat('yyyy-MM-dd hh:mm a');
  bool date = true;
  Icon cusIcon = const Icon(Icons.search);
  Widget cusSearchBar = const Text("User");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: cusSearchBar,
        actions: <Widget>[
          IconButton(
            icon: cusIcon,
            onPressed: () {
              setState(() {
                if (cusIcon.icon == Icons.search) {
                  cusIcon = const Icon(Icons.cancel);
                  cusSearchBar = TextField(
                    controller: controllerUser,
                    textInputAction: TextInputAction.go,
                    decoration: const InputDecoration(
                      hintText: "Search",
                    ),
                    onSubmitted: (value) {
                      value = value;
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => Search(value: value)));
                    },
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  );
                } else {
                  cusIcon = const Icon(Icons.search);
                  cusSearchBar = const Text("Attendance List");
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () {
              setState(() {
                date = !date;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<User>>(
          stream: readUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Something went wrong! ${snapshot.error}');
            } else if (snapshot.hasData) {
              final users = snapshot.data!;

              return ListView(
                children: users.map(buildUser).toList(),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Widget buildUser(User user) => ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color.fromARGB(255, 182, 98, 171),
          child: Icon(Icons.account_circle),
        ),
        title: Text(user.user),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.start, //align left
          children: [
            Text('${user.phone}',
                style: const TextStyle(height: 1, fontSize: 12)),
            const Text('   '),
            Text(date ? timeago.format(user.checkin) : f.format(user.checkin),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                )),
          ],
        ),
        trailing: Wrap(
          spacing: 12, // space between two icons
          children: <Widget>[
            IconButton(
                onPressed: () {
                  sharePressed(user);
                },
                icon: const Icon(
                  Icons.share,
                  color: Colors.purple,
                )),
          ],
        ),
      );

  Stream<List<User>> readUsers() => FirebaseFirestore.instance
      .collection('users')
      .orderBy('checkin', descending: true)
      .where(
        'id',
        isEqualTo: value,
      ) //order by recent date
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => User.fromJson(doc.data())).toList());

  sharePressed(User user) {
    String userName = user.user;
    String phoneNo = '${user.phone}';
    String checkindate = f.format(user.checkin);

    var message =
        'Name: $userName\nPhone no: +60$phoneNo\nLast checked in: $checkindate';
    Share.share(message, subject: 'Contact Information');
  }
}

class User {
  final String user;
  final int phone;
  final DateTime checkin;

  User({
    required this.user,
    required this.phone,
    required this.checkin,
  });
  Map<String, dynamic> toJson() => {
        'user': user,
        'phone': phone,
        'checkin': checkin,
      };

  static User fromJson(Map<String, dynamic> json) => User(
        user: json['user'],
        phone: json['phone'],
        checkin: (json['checkin'] as Timestamp).toDate(),
      );
}
