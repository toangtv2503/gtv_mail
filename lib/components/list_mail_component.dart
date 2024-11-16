import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/user_service.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

import '../models/mail.dart';
import '../services/mail_service.dart';

class ListMailComponent extends StatefulWidget {
  ListMailComponent({super.key, required this.category, required this.userEmail});
  String category;
  String userEmail;


  @override
  State<ListMailComponent> createState() => _ListMailComponentState();
}

class _ListMailComponentState extends State<ListMailComponent> with SingleTickerProviderStateMixin{
  late final controller = SlidableController(this);

  late Map<String, MyUser> userCache = Map();

  void init() async {
    userCache = await userService.fetchSenderCached();
    setState(() {});
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Mail>>(
      stream: mailService.streamMailsByUser(widget.userEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(
              child: SizedBox(
                width: 400,
                child: Lottie.asset(
                  'assets/lottiefiles/circle_loading.json',
                  fit: BoxFit.fill,
                ),
              ),
            )
          );
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(
                child: Text('Error: ${snapshot.error}', style: Theme.of(context).textTheme.displayLarge,)
              )
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Row(),
                  SizedBox(
                    width: 400,
                    child: Lottie.asset(
                      'assets/lottiefiles/empty_animation.json',
                      fit: BoxFit.fill,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "No thing in ${widget.category}",
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
          );
        } else {
          final mails = snapshot.data!.where((mail) => mailService.isPrimaryMail(mail)).toList();

          return SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Slidable(
                      key: ValueKey(index),
                      startActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        // dismissible: DismissiblePane(onDismissed: () {}),
                        children: [
                          SlidableAction(
                            onPressed: (context) {},
                            backgroundColor: Color(0xFFFE4A49),
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                          SlidableAction(
                            onPressed: (context) {},
                            backgroundColor: Color(0xFF21B7CA),
                            foregroundColor: Colors.white,
                            icon: Icons.share,
                            label: 'Share',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            flex: 2,
                            onPressed: (_) => controller.openEndActionPane(),
                            backgroundColor: const Color(0xFF7BC043),
                            foregroundColor: Colors.white,
                            icon: Icons.archive,
                            label: 'Archive',
                          ),
                          SlidableAction(
                            onPressed: (_) => controller.close(),
                            backgroundColor: const Color(0xFF0392CF),
                            foregroundColor: Colors.white,
                            icon: Icons.save,
                            label: 'Save',
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {},
                        leading: CircleAvatar(
                          child: CachedNetworkImage(
                            imageUrl: userCache[mails[index].from]!.imageUrl!,
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
                          userCache[mails[index].from]!.name!,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          mails[index].subject!,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: SizedBox(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                              DateFormat('dd/MM/yyyy').format(mails[index].sentDate!),
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
                      ),
                    );
              },
              childCount: mails.length,
            ),
          );
        }
      },
    );
  }
}

