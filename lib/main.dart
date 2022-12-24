import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vimigoflutter/search.dart';
import 'package:vimigoflutter/userForm.dart';
import 'package:vimigoflutter/user.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: "root",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.purple),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with RestorationMixin {
  final controllerUser = TextEditingController();
  final controller = TextEditingController();
  late ScrollController _controller;

  final f = DateFormat('yyyy-MM-dd hh:mm a');
  RestorableBool date = RestorableBool(true);
  Icon cusIcon = const Icon(Icons.search);
  Icon dateIcon = const Icon(Icons.access_time);
  Widget cusSearchBar = const Text("Attendance List");

  String name = "";

  @override
  Widget build(BuildContext context) => Scaffold(
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
                        name = value;
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              //redirect to UserForm.dart
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const UserForm();
                },
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder<List<User>>(
            stream: readUsers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Something went wrong! ${snapshot.error}');
              } else if (snapshot.hasData) {
                final users = snapshot.data!;

                return ListView(
                  controller: _controller,
                  children: users.map(buildUser).toList(),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),
      );

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
            //Text(), //normal format
            Text(
                date.value
                    ? timeago.format(user.checkin)
                    : f.format(user.checkin),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                )), //to change .ago format
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserInfo(value: user.id),
            ),
          );
        },
      );

  Stream<List<User>> readUsers() => FirebaseFirestore.instance
      .collection('users')
      .orderBy('checkin', descending: true) //order by recent date
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => User.fromJson(doc.data())).toList());

  @override
  String? get restorationId => "home_screen";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(date, "date");
  }

  showSnackBar(context) {
    //appear when user reach end of list
    const snackBar = SnackBar(
      content: Text('You have reached the end of the list'),
      backgroundColor: Color.fromARGB(255, 215, 158, 226),
      duration: Duration(milliseconds: 500),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      //if scroll reach bottom
      return showSnackBar(context);
    }
  }

  @override
  void initState() {
    _controller = ScrollController();
    _controller.addListener(_scrollListener);
    super.initState();
  }
}

class User {
  String id;
  final String user;
  final int phone;
  final DateTime checkin;

  User({
    this.id = "",
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
        id: json['id'],
        user: json['user'],
        phone: json['phone'],
        checkin: (json['checkin'] as Timestamp).toDate(),
      );
}
