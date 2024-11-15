import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gtv_mail/services/user_service.dart';
import 'package:lottie/lottie.dart';

class ListMailComponent extends StatefulWidget {
  const ListMailComponent({super.key});

  @override
  State<ListMailComponent> createState() => _ListMailComponentState();
}

class _ListMailComponentState extends State<ListMailComponent> {
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return ListTile(
            onTap: () {},
            leading: CircleAvatar(
              child: CachedNetworkImage(
                imageUrl: userService.getCurrentUser()!.photoURL!,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(image: imageProvider),
                  ),
                ),
                placeholder: (context, url) => Lottie.asset(
                  'assets/lottiefiles/circle_loading.json',
                  fit: BoxFit.fill,
                ),
                errorWidget: (context, url, error) =>
                const Icon(Icons.error),
              ),
            ),
            title: Text(
              "Ten mail",
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              "noi dung cua mail",
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: SizedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "11 thg 11",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  IconButton(
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.star_border_outlined,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: 20,
      ),
    );
  }
}
