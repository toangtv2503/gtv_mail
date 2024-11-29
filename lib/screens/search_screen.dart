import 'dart:convert';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dynamic_searchbar/dynamic_searchbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:gtv_mail/services/mail_service.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attachment.dart';
import '../models/mail.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/app_theme.dart';
import '../utils/image_default.dart';

class SearchScreen extends StatefulWidget {
  SearchScreen({super.key, required this.userMail});
  String userMail;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool isLoading = true;
  late SharedPreferences prefs;
  late Map<String, dynamic> displayMode = {
    'mode': 'Basic',
    'isShowAvatar': false,
    'isShowAttachment': false,
  };
  late Map<String, MyUser> userCache = Map();

  final List<FilterAction> mailFilter = [
    FilterAction(
      title: 'Subject',
      field: 'subject',
      type: FilterType.stringFilter,
    ),
    FilterAction(
      title: 'From Email',
      field: 'from',
      type: FilterType.stringFilter,
    ),
    FilterAction(
      title: 'Date',
      field: 'sentDate',
      type: FilterType.dateRangeFilter,
      dateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now(),
      ),
    ),
  ];

  final List<SortAction> mailSort = [
    SortAction(
      title: 'Subject ASC',
      field: 'subject',
      order: OrderType.asc
    ),
    SortAction(
      title: 'Subject DESC',
      field: 'subject',
      order: OrderType.desc
    ),
    SortAction(
      title: 'Email ASC',
      field: 'from',
      order: OrderType.asc,
    ),
    SortAction(
      title: 'Email DESC',
      field: 'from',
      order: OrderType.desc,
    ),
    SortAction(
      title: 'Date ASC',
      field: 'sentDate',
      order: OrderType.asc,
    ),
    SortAction(
      title: 'Date DESC',
      field: 'sentDate',
      order: OrderType.desc,
    ),
  ];

  late List<Mail> mails = List.empty();
  late List<Mail> filteredMails = List.empty();

  Future<void> fetchMails(String userEmail) async {
    mails = await mailService.getDataForSearch(userEmail);
    filteredMails = List.from(mails);
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    await fetchMails(widget.userMail);
    prefs = await SharedPreferences.getInstance();
    userCache = await userService.fetchSenderCached();

    displayMode = jsonDecode(prefs.getString('default_display_mode') ??
        jsonEncode({
          'mode': 'Basic',
          'isShowAvatar': true,
          'isShowAttachment': false,
        }));

    await _fetchDisplayMode();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchDisplayMode() async {
    final defaultDisplayMode = jsonEncode({
      'mode': 'Basic',
      'isShowAvatar': true,
      'isShowAttachment': false,
    });
    displayMode = jsonDecode(prefs.getString('default_display_mode') ?? defaultDisplayMode);
    if (mounted) {
      setState(() {});
    }

  }

  void _handleDetailMail(Mail mail, MyUser senderInfo) async {
    if (mail.isDraft) {
      var result = await context.pushNamed('compose',
          queryParameters: {'type': 'draft'}, extra: {'id': mail.uid!});
    } else {
      var result = await context.pushNamed('detail',
          pathParameters: {'id': mail.uid!},
          extra: {'mail': mail, 'senderInfo': senderInfo});

      if (result.runtimeType == Mail) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('1 item has been moved to the trash.'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
                label: 'Undo',
                onPressed: () => _handleUndoDelete(result as Mail)),
          ),
        );
      } else if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('1 item has been deleted.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      setState(() {});
    }
  }

  void _handleUndoDelete(Mail mailDelete) async {
    mailDelete.isDelete = false;
    await mailService.updateMail(mailDelete);
  }

  void _handleStaredMail(Mail mail) async {
    mail.isStarred = !mail.isStarred;
    await mailService.updateMail(mail);
  }

  void _handleSearch(List<Mail> mailsToSearch) {
    setState(() {
      filteredMails = mailsToSearch;
    });
  }

  void _handleFilter(Map<dynamic, dynamic> filters) {
    List<Mail> filtered = List.from(mails);

    List filterList = [];
    if (filters['filter'] is String) {
      try {
        filterList = jsonDecode(filters['filter']) as List;
      } catch (e) {
        print("Error decoding 'filter': $e");
      }
    } else if (filters['filter'] is List) {
      filterList = filters['filter'];
    } else {
      print("Expected a List or String for 'filter' but got: ${filters['filter']}");
    }

    for (var filter in filterList) {
      String field = filter['field'];

      if (filter['type'] == 'stringFilter') {
        String searchKey = filter['searchKey']?.toLowerCase() ?? '';

        filtered = filtered.where((mail) {
          if (field == 'subject') {
            return mail.subject?.toLowerCase().contains(searchKey) ?? false;
          } else if (field == 'from') {
            return mail.from?.toLowerCase().contains(searchKey) ?? false;
          }
          return false;
        }).toList();
      }

      else if (filter['type'] == 'dateRangeFilter') {
        String startDateStr = filter['dateRange']?['start'] ?? '';
        String endDateStr = filter['dateRange']?['end'] ?? '';

        DateTime? startDate = DateTime.tryParse(startDateStr);
        DateTime? endDate = DateTime.tryParse(endDateStr);

        filtered = filtered.where((mail) {
          DateTime? sentDate = mail.sentDate;

          if (sentDate != null) {
            bool isAfterStart = startDate == null || sentDate.isAfter(startDate);
            bool isBeforeEnd = endDate == null || sentDate.isBefore(endDate);

            return isAfterStart && isBeforeEnd;
          }

          return false;
        }).toList();
      }
    }

    List sortList = [];
    if (filters['sort'] is String) {
      try {
        sortList = jsonDecode(filters['sort']) as List;
      } catch (e) {
        print("Error decoding 'sort': $e");
      }
    } else if (filters['sort'] is List) {
      sortList = filters['sort'];
    } else {
      print("Expected a List or String for 'sort' but got: ${filters['sort']}");
    }

    for (var sort in sortList) {
      String field = sort['field'];
      String order = sort['order'] ?? 'asc';

      if (order == 'asc') {
        filtered.sort((a, b) {
          if (field == 'subject') {
            return a.subject?.compareTo(b.subject ?? '') ?? 0;
          } else if (field == 'sentDate') {
            return a.sentDate?.compareTo(b.sentDate ?? DateTime.now()) ?? 0;
          }
          return 0;
        });
      } else if (order == 'desc') {
        filtered.sort((a, b) {
          if (field == 'subject') {
            return b.subject?.compareTo(a.subject ?? '') ?? 0;
          } else if (field == 'sentDate') {
            return b.sentDate?.compareTo(a.sentDate ?? DateTime.now()) ?? 0;
          }
          return 0;
        });
      }
    }

    setState(() {
      filteredMails = filtered;
    });
  }

  void _handleDelete(Mail mail) async {
    if (mail.isDelete) {
      final result = await showOkCancelAlertDialog(
          context: context,
          message:
          'You are about to permanently delete this mail. Do you want to continue?',
          cancelLabel: "Cancel");
      if (result.name == "ok") {
        await mailService.deleteMail(mail);
      }
    } else {
      mail.isDelete = true;
      await mailService.updateMail(mail);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('1 item has been moved to the trash.'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _handleUndoDelete(mail)),
        ),
      );
    }
  }

  void _handleHide(Mail mail) async {
    if (mail.isHidden) {
      mail.isHidden = false;
      await mailService.updateMail(mail);
    } else {
      mail.isHidden = true;
      await mailService.updateMail(mail);
    }
  }

  void _handleSpam(Mail mail) async {
    if (mail.isSpam) {
      mail.isSpam = false;
      await mailService.updateMail(mail);
    } else {
      mail.isSpam = true;
      await mailService.updateMail(mail);
    }
  }

  void _handleImportant(Mail mail) async {
    if (mail.isImportant) {
      mail.isImportant = false;
      await mailService.updateMail(mail);
    } else {
      mail.isImportant = true;
      await mailService.updateMail(mail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text("Search Mail", style: Theme.of(context).textTheme.titleMedium,),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).primaryColor,
                    border: const Border(
                      bottom: BorderSide(color: Colors.black),
                      right: BorderSide(color: Colors.black),
                      top: BorderSide(color: Colors.black),
                      left: BorderSide(color: Colors.black),
                    ),
                  ),
                  child: SearchField(
                    disableFilter: false,
                    filters: mailFilter,
                    sorts: mailSort,
                    initialData: mails,
                    onChanged: (List<Mail> query) => _handleSearch(query),
                    onFilter: (Map<dynamic, dynamic> filters) => _handleFilter(filters),
                  ),
                ),
              ),
              filteredMails.isEmpty && !isLoading ? Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Row(),
                    SizedBox(
                      width: 400,
                      child: Lottie.asset(
                        'assets/lottiefiles/search_empty.json',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "No results found.",
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ) : Expanded(
                child: ListView.builder(
                  itemCount: filteredMails.length,
                  itemBuilder: (context, index) {
                    final mail = filteredMails[index];
                    final user = userCache[mail.from];
                    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

                    return Column(
                      children: [
                        Slidable(
                          key: ValueKey(mail.uid ?? index),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 1,
                            children: [
                              SlidableAction(
                                onPressed: (context) => _handleImportant(mail),
                                backgroundColor: AppTheme.blueColor,
                                foregroundColor: Colors.white,
                                icon: mails[index].isImportant ? Icons.undo : Icons.label_important_outline_rounded,
                                label: mails[index].isImportant ? 'Un Important' : 'Important',
                              ),
                              SlidableAction(
                                onPressed: (context) => _handleSpam(mail),
                                backgroundColor: AppTheme.yellowColor,
                                foregroundColor: Colors.white,
                                icon: mails[index].isSpam ? Icons.undo : Icons.warning,
                                label: mails[index].isSpam ? 'Un Spam' : 'Spam',
                              ),
                              SlidableAction(
                                onPressed: (context) => _handleHide(mail),
                                backgroundColor: AppTheme.greenColor,
                                foregroundColor: Colors.white,
                                icon: mails[index].isHidden ? Icons.undo :  Icons.access_time,
                                label: mails[index].isHidden ? 'Re-Active' : 'Snoozed',
                              ),
                              SlidableAction(
                                onPressed: (context) => _handleDelete(mail),
                                backgroundColor: AppTheme.redColor,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: () => _handleDetailMail(mail, user!),
                            leading: displayMode['isShowAvatar'] ? buildAvatar(user) : null,
                            title: buildMailTitle(context, mail, user?.name, isDarkMode),
                            subtitle: buildMailSubtitle(context, mail, displayMode, isDarkMode),
                            trailing: buildMailTrailing(context, mail),
                          ),
                        ),
                        if (index < filteredMails.length - 1)
                          const Divider(
                            endIndent: 80,
                            indent: 70,
                            color: Colors.grey,
                          ),
                      ],
                    );

                  },
                ),
              ),
            ],
          ),
          if (isLoading)
            Center(
              child: SizedBox(
                width: 50,
                child: Lottie.asset(
                  'assets/lottiefiles/circle_loading.json',
                  fit: BoxFit.fill,
                ),
              ),
            ),
        ],
      )
    );
  }

  Widget buildAvatar(MyUser? user) {
    return CircleAvatar(
      backgroundColor: AppTheme.blueColor,
      child: CachedNetworkImage(
        imageUrl: user?.imageUrl ?? DEFAULT_AVATAR,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            border: const GradientBoxBorder(
              gradient: LinearGradient(colors: [
                AppTheme.redColor,
                AppTheme.greenColor,
                AppTheme.yellowColor,
                AppTheme.blueColor,
              ]),
            ),
            shape: BoxShape.circle,
            image: DecorationImage(image: imageProvider),
          ),
        ),
        placeholder: (context, url) => Lottie.asset(
          'assets/lottiefiles/circle_loading.json',
          fit: BoxFit.fill,
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  Widget buildMailTitle(BuildContext context, Mail mail, String? senderName, bool isDarkMode) {
    return Text(
      senderName ?? 'Sender',
      style: (mail.isRead
          ? Theme.of(context).textTheme.titleMedium
          : Theme.of(context).textTheme.titleLarge)?.copyWith(
        color: mail.isRead
            ? Colors.grey
            : isDarkMode
            ? Colors.white
            : Colors.black,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget buildMailSubtitle(BuildContext context, Mail mail, Map<String, dynamic> displayMode, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mail.subject ?? 'No Subject',
          style: (mail.isRead
              ? Theme.of(context).textTheme.titleSmall
              : Theme.of(context).textTheme.titleMedium)?.copyWith(
            color: mail.isRead
                ? Colors.grey
                : isDarkMode
                ? Colors.white
                : Colors.black,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (displayMode['isShowAttachment'] ?? false)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: mail.attachments?.map((att) {
                int colorIndex = mail.attachments!.indexOf(att);
                return buildAttachmentChip(att, colorIndex);
              }).toList() ??
                  [],
            ),
          ),
      ],
    );
  }

  Widget buildAttachmentChip(Attachment att, int colorIndex) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        backgroundColor: [
          AppTheme.redColor,
          AppTheme.greenColor,
          AppTheme.yellowColor,
          AppTheme.blueColor,
        ][colorIndex % 4],
        avatar: Image.asset(
          "assets/images/${att.extension}.png",
          height: 20,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            "assets/images/unknown.png",
            height: 20,
          ),
        ),
        label: Text(att.extension ?? 'Unknown'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget buildMailTrailing(BuildContext context, Mail mail) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          mail.sentDate != null
              ? DateFormat('dd/MM/yyyy').format(mail.sentDate!)
              : 'No Date',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        IconButton(
          onPressed: () => _handleStaredMail(mail),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: mail.isStarred
              ? const Icon(Icons.star, color: AppTheme.yellowColor)
              : const Icon(Icons.star_border_outlined),
        ),
      ],
    );
  }


}