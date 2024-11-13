import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gtv_mail/components/custom_appbar.dart';
import 'package:gtv_mail/components/custom_drawer.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  _handleComposeMail() async {
    context.pushNamed('compose', queryParameters: {'draft': 'new'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      body: CustomAppbar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleComposeMail,
        child: const Icon(Icons.add),
      ),
    );
  }
}
