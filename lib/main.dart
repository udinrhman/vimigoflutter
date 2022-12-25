import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vimigoflutter/search.dart';
import 'package:vimigoflutter/userForm.dart';
import 'package:vimigoflutter/user.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  runApp(MyApp(showHome: showHome));
}

class MyApp extends StatelessWidget {
  final bool showHome;

  const MyApp({
    Key? key,
    required this.showHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: "root",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.purple),
      home: showHome ? MainPage() : OnboardingPage(),
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
      duration: Duration(milliseconds: 800),
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

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final controller = PageController();
  bool isLastPage = false;

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  Widget buildPage({
    required Color color,
    required String urlImage,
    required String title,
    required String subtitle,
  }) =>
      Container(
        color: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              urlImage,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
            const SizedBox(height: 64),
            Text(
              title,
              style: TextStyle(
                color: Colors.purple.shade700,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(subtitle,
                    style: const TextStyle(color: Colors.black54))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          padding: const EdgeInsets.only(bottom: 80),
          child: PageView(
            controller: controller,
            onPageChanged: (index) {
              setState(() => isLastPage = index == 3);
            },
            children: [
              buildPage(
                  color: Colors.purple.shade50,
                  urlImage: 'assets/add.png',
                  title: 'ADD ATTENDANCE',
                  subtitle: 'Click add icon to insert new attendance'),
              buildPage(
                  color: Colors.purple.shade50,
                  urlImage: 'assets/clock.png',
                  title: 'DATE FORMAT',
                  subtitle: 'Click clock icon to change the date format'),
              buildPage(
                  color: Colors.purple.shade50,
                  urlImage: 'assets/search.png',
                  title: 'SEARCH',
                  subtitle:
                      'Click search icon to display textfield and insert any input'),
              buildPage(
                  color: Colors.purple.shade50,
                  urlImage: 'assets/share.png',
                  title: 'SHARE',
                  subtitle:
                      'Choose a list and click share button to share with other apps'),
            ],
          ),
        ),
        bottomSheet: isLastPage
            ? TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  backgroundColor: Colors.purple.shade300,
                  minimumSize: const Size.fromHeight(80),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 24),
                ),
                onPressed: () async {
                  //naviagate directly to main page
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setBool('showHome', true);

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainPage()),
                  );
                },
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: const Text('SKIP'),
                      onPressed: () => controller.jumpToPage(3),
                    ),
                    Center(
                      child: SmoothPageIndicator(
                        controller: controller,
                        count: 4,
                        effect: WormEffect(
                          spacing: 16,
                          dotColor: Colors.black26,
                          activeDotColor: Colors.purple.shade300,
                        ),
                        onDotClicked: (index) => controller.animateToPage(index,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeIn),
                      ),
                    ),
                    TextButton(
                      child: const Text('NEXT'),
                      onPressed: () => controller.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ],
                ),
              ),
      );
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
