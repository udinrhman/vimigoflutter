import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

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

class _MainPageState extends State<MainPage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Attendance List'),
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

  Widget buildUser(User user) => ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color.fromARGB(255, 182, 98, 171),
          child: Icon(Icons.account_circle),
        ),
        title: Text(user.user),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.start, //align left
          children: [
            Text('${user.phone}', style: TextStyle(height: 1, fontSize: 12)),
            Text('   '),
            //Text(user.checkin.toIso8601String()), //normal format
            Text(timeago.format(user.checkin),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                )), //to change .ago format
          ],
        ),
      );

  Stream<List<User>> readUsers() => FirebaseFirestore.instance
      .collection('users')
      .orderBy('checkin')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => User.fromJson(doc.data())).toList());
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
