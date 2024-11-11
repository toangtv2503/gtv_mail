import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gtv_mail/components/custom_appbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                        "https://cdn.tuoitre.vn/thumb_w/1200/471584752817336320/2024/7/14/anh-man-hinh-2024-07-14-luc-094147-1720924975975239845544.png"),
                    radius: 40,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "ToanGTV",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        "521H0486@gmail.com",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      )
                    ],
                  )
                ],
              ),
            ),

          ],
        ),
      ),
      // body: Column(
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   crossAxisAlignment: CrossAxisAlignment.center,
      //   children: [
      //     const Row(),
      //     Text(
      //       "Home",
      //       style: Theme.of(context).textTheme.displayLarge,
      //     ),
      //     Switch(
      //         value: false,
      //         onChanged: (value) {
      //           AdaptiveTheme.of(context).toggleThemeMode(useSystem: false);
      //         }),
      //     ElevatedButton(onPressed: () {
      //       GoRouter.of(context).go('/error');
      //     }, child: Text("Nhan di"))
      //   ],
      // ),
      body: CustomAppbar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FirebaseAuth.instance.signOut();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
