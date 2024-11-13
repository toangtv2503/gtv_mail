import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late String email ='';
  late SharedPreferences prefs;

  void init() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? '';
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              child: CachedNetworkImage(
                imageUrl: FirebaseAuth.instance.currentUser!.photoURL!,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(image: imageProvider),
                  ),
                ),
                placeholder: (context, url) => Lottie.asset(
                  'assets/lottiefiles/circle_loading.json',
                  fit: BoxFit.fill,
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            accountName: Text(FirebaseAuth.instance.currentUser!.displayName!),
            accountEmail: Text(email!),
          ),
          ListTile(
            leading: Icon(Icons.all_inbox),
            title: Text("All inboxes"),
            trailing: Text("99+"),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.inbox_rounded),
            title: Text("Primary"),
            trailing: Text("99+"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.people_alt_outlined),
            title: Text("Social"),
            trailing: Text("99+"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.local_offer_outlined),
            title: Text("Promotion"),
            trailing: Text("99+"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.flag),
            title: Text("Update"),
            trailing: Text("99+"),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.star_border),
            title: Text("Starred"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text("Snoozed"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.label_important_outline),
            title: Text("Important"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.send_outlined),
            title: Text("Sent"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.cancel_schedule_send_outlined),
            title: Text("Scheduled"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.insert_drive_file_outlined),
            title: Text("Drafts"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.mark_as_unread_outlined),
            title: Text("All mail"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.report_gmailerrorred),
            title: Text("Spam"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text("Trash"),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.add),
            title: Text("Create new"),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text("Settings"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.feedback_outlined),
            title: Text("Send feedback"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.help_outline),
            title: Text("Help"),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Logout"),
            onTap: () async {
              var prefs = await SharedPreferences.getInstance();
              prefs.remove('email');
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}
