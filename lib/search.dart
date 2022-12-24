import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

// ignore: must_be_immutable
class Search extends StatefulWidget {
  String value;
  Search({super.key, required this.value});

  @override
  _SearchState createState() => _SearchState(value);
}

class _SearchState extends State<Search> with RestorationMixin {
  String value;
  _SearchState(this.value);

  final controllerUser = TextEditingController();
  final controller = TextEditingController();
  final f = DateFormat('yyyy-MM-dd hh:mm a');
  RestorableBool date = RestorableBool(true);
  Icon cusIcon = const Icon(Icons.search);
  Icon dateIcon = const Icon(Icons.access_time);
  Widget cusSearchBar = const Text("Search Result");

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
            icon: dateIcon,
            onPressed: () {
              setState(() {
                if (dateIcon.icon == Icons.access_time) {
                  date.value = !date.value;
                  dateIcon = const Icon(Icons.access_time_filled);
                } else {
                  date.value = !date.value;
                  dateIcon = const Icon(Icons.access_time);
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<User>>(
          stream: readUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final users = snapshot.data!;

              return ListView(
                children: users.map(buildUser).toList(),
              );
            } else if (snapshot.hasError) {
              return Text('Something went wrong! ${snapshot.error}');
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Widget buildUser(User user) => ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color.fromARGB(255, 182, 98, 171),
          child: Icon(Icons.account_circle_sharp),
        ),
        title: Text(user.user),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.start, //align left
          children: [
            Text('${user.phone}',
                style: const TextStyle(height: 1, fontSize: 12)),
            const Text('   '),
            Text(
                date.value
                    ? timeago.format(user.checkin)
                    : f.format(user.checkin),
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
      .where('user', isGreaterThanOrEqualTo: value)
      .where('user', isLessThan: value + 'z')
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

  @override
  String? get restorationId => "search_screen";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(date, "date");
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
