import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("Home", style: Theme.of(context).textTheme.displayLarge,),
      floatingActionButton: FloatingActionButton(onPressed: () {
        FirebaseAuth.instance.signOut();
      }, child: Text("Logout"),),
    );
  }
}
