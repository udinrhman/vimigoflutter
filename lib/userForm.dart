import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';

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
      home: const UserForm(),
    );
  }
}

class UserForm extends StatefulWidget {
  const UserForm({super.key});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final controllerUser = TextEditingController();
  final controllerPhone = TextEditingController();
  final controllerCheckin = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Add Attendance'),
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: <Widget>[
          TextField(
            controller: controllerUser,
            decoration: decoration('User'),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controllerPhone,
            decoration: decoration('Phone'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          DateTimeField(
            controller: controllerCheckin,
            decoration: decoration('Checkin'),
            format: DateFormat('yyyy-MM-dd HH:mm'),
            onShowPicker: (context, currentValue) async {
              final date = await showDatePicker(
                  //get date
                  context: context,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                  initialDate: currentValue ?? DateTime.now());
              if (date != null) {
                final time = await showTimePicker(
                  //get time
                  context: context,
                  initialTime:
                      TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
                );
                return DateTimeField.combine(date, time);
              } else {
                return currentValue;
              }
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            child: const Text('Add User'),
            onPressed: () {
              final user = User(
                user: controllerUser.text,
                phone: int.parse(controllerPhone.text),
                checkin: DateTime.parse(controllerCheckin.text),
              ); // User

              createUser(user);
              showSnackBar(context); //display success message
              Navigator.pop(context);
            },
          ),
        ]),
      );

  InputDecoration decoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      );

  Future createUser(User user) async {
    // Reference to document
    final docUser = FirebaseFirestore.instance.collection('users').doc();
    user.id = docUser.id;

    final json = user.toJson();
    await docUser.set(json);
  }

  showSnackBar(context) {
    const snackBar = SnackBar(
      content: Text('Attendance Added!'),
      backgroundColor: Color.fromARGB(255, 106, 180, 107),
      duration: Duration(milliseconds: 1000),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
        'id': id,
        'user': user,
        'phone': phone,
        'checkin': checkin,
      };
}
