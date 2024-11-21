import 'dart:convert';
import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:email_validator/email_validator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:gtv_mail/models/attachment.dart';
import 'package:gtv_mail/models/mail.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/file_service.dart';
import 'package:gtv_mail/services/user_service.dart';
import 'package:gtv_mail/utils/image_default.dart';
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/mail_service.dart';
import '../utils/app_theme.dart';
import '../utils/button_data.dart';

class ComposeMail extends StatefulWidget {
  ComposeMail({super.key, this.isDraft = true, this.draftId});
  bool? isDraft;
  String? draftId;

  @override
  State<ComposeMail> createState() => _ComposeMailState();
}

class _ComposeMailState extends State<ComposeMail> {
  final QuillController _bodyController = QuillController.basic();
  late SharedPreferences prefs;
  final TextEditingController _fromController = TextEditingController();
  var _key = GlobalKey<FormState>();
  bool isSending = false;
  String? _subject;
  bool isShowMore = false;
  List<Attachment> attachments = [];
  List<PlatformFile> fileCached = [];

  void init() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _fromController.text = prefs.getString('email') ?? '';
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _fromController.dispose();
    _toEmailsController.dispose();
    _ccEmailsController.dispose();
    _bccEmailsController.dispose();
    super.dispose();
  }

  void _handleDeleteFile(Attachment attachment) async {
      final result = await showOkCancelAlertDialog(
      context: context,
      title: 'Delete Attachment',
      message: 'Are you sure you want to delete "${attachment.fileName}"?',
      okLabel: 'Yes',
      cancelLabel: 'Cancel',
    );

    if (result.name == "ok") {
      setState(() {
        attachments.remove(attachment);
        fileCached.removeWhere((cached) => cached.path == attachment.url);
      });
    }
  }

  void _openFile(Attachment attachment) async {
    if (attachment.url != null) {
      final filePath = attachment.url!;
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        showOkAlertDialog(
          context: context,
          title: "Error",
          message: "Could not open the file.",
        );
      }
    }
  }

  void _handleAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (!fileCached.any((cachedFile) => cachedFile.name == file.name)) {
            fileCached.add(file);
          }
        }

        for (var file in result.files) {
          if (!attachments
              .any((attachment) => attachment.fileName == file.name)) {
            attachments.add(Attachment(
              url: kIsWeb && file.bytes != null
                  ? base64Encode(file.bytes!)
                  : file.path,
              fileName: file.name,
              extension: file.extension,
              size: file.size,
            ));
          }
        }
      });
    }
  }

  void _handleSend() async {
    if (_key.currentState?.validate() ?? false) {
      _key.currentState!.save();

      List<String> toEmails =
          _toEmailsController.getTags?.map((tag) => tag.tag).toList() ?? [];
      List<String> ccEmails =
          _ccEmailsController.getTags?.map((tag) => tag.tag).toList() ?? [];
      List<String> bccEmails =
          _bccEmailsController.getTags?.map((tag) => tag.tag).toList() ?? [];

      if (toEmails.length + ccEmails.length + bccEmails.length == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please add at least one recipient!'),
        ));
        return;
      }

      setState(() {
        isSending = true;
      });

      List<Attachment> sendAttachments = [];
      if (attachments.isNotEmpty) {
        sendAttachments = await fileService.mapFilesToAttachments(fileCached);
      }

      String uid = const Uuid().v8();
      Mail newMail = Mail(
        uid: uid,
        from: _fromController.text,
        subject: _subject,
        to: toEmails.isEmpty ? null : toEmails,
        cc: ccEmails.isEmpty ? null : ccEmails,
        bcc: bccEmails.isEmpty ? null : bccEmails,
        body: _bodyController.document,
        sentDate: DateTime.now(),
        attachments: sendAttachments.isNotEmpty ? sendAttachments : null,
      );

      await mailService.sendEmail(newMail);

      Navigator.pop(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  late double _distanceToField;
  final DynamicTagController<DynamicTagData<ButtonData>> _toEmailsController =
      DynamicTagController<DynamicTagData<ButtonData>>();
  DynamicTagController<DynamicTagData<ButtonData>> _ccEmailsController =
      DynamicTagController<DynamicTagData<ButtonData>>();
  DynamicTagController<DynamicTagData<ButtonData>> _bccEmailsController =
      DynamicTagController<DynamicTagData<ButtonData>>();
  final random = Random();

  Future<List<DynamicTagData<ButtonData>>> fetchMails() async {
    List<MyUser> users = await userService.fetchUsers();

    return users.map((user) {
      final color = Color.fromARGB(random.nextInt(256), random.nextInt(256),
          random.nextInt(256), random.nextInt(256));
      return DynamicTagData<ButtonData>(
        user.email.toString(),
        ButtonData(color, user.imageUrl!),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close)),
        actions: [
          IconButton(
              onPressed: _handleAttachment, icon: const Icon(Icons.attachment)),
          IconButton(
              onPressed: _handleSend,
              icon: isSending
                  ? Lottie.asset(
                      'assets/lottiefiles/circle_loading.json',
                      fit: BoxFit.fill,
                    )
                  : const Icon(Icons.send_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _key,
          child: Column(
            children: [
              Autocomplete<DynamicTagData<ButtonData>>(
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final DynamicTagData<ButtonData> option =
                                options.elementAt(index);
                            return TextButton(
                              onPressed: () {
                                onSelected(option);
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.blueColor,
                                  child: CachedNetworkImage(
                                    imageUrl: option.data.emoji,
                                    imageBuilder: (context, imageProvider) =>
                                        Container(
                                      decoration: BoxDecoration(
                                        border: const GradientBoxBorder(
                                          gradient: LinearGradient(colors: [
                                            AppTheme.redColor,
                                            AppTheme.greenColor,
                                            AppTheme.yellowColor,
                                            AppTheme.blueColor
                                          ]),
                                        ),
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                            image: imageProvider),
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
                                title: Text(option.tag),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  return TextFieldTags<DynamicTagData<ButtonData>>(
                    textfieldTagsController: _toEmailsController,
                    textEditingController: textEditingController,
                    focusNode: focusNode,
                    textSeparators: const [' ', ','],
                    letterCase: LetterCase.normal,
                    validator: (DynamicTagData<ButtonData> tag) {
                      if (tag.tag.isEmpty) {
                        return 'Please enter your email';
                      } else if (tag.tag.length > 256) {
                        return 'Your email so long';
                      } else if (!EmailValidator.validate(tag.tag)) {
                        return "Your email is invalid";
                      } else if (_toEmailsController.getTags!
                          .any((element) => element.tag == tag.tag)) {
                        return 'This email already enter';
                      }

                      return null;
                    },
                    inputFieldBuilder: (context, inputFieldValues) {
                      return TextField(
                        controller: inputFieldValues.textEditingController,
                        focusNode: inputFieldValues.focusNode,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isShowMore = !isShowMore;
                                  if (!isShowMore) {
                                    _ccEmailsController.dispose();
                                    _bccEmailsController.dispose();
                                  } else {
                                    _ccEmailsController = DynamicTagController<
                                        DynamicTagData<ButtonData>>();
                                    _bccEmailsController = DynamicTagController<
                                        DynamicTagData<ButtonData>>();
                                  }
                                });
                              },
                              icon: isShowMore
                                  ? const Icon(Icons.keyboard_arrow_up)
                                  : const Icon(Icons.keyboard_arrow_down)),
                          isDense: true,
                          border: const UnderlineInputBorder(),
                          labelText: "to",
                          errorText: inputFieldValues.error,
                          prefixIconConstraints:
                              BoxConstraints(maxWidth: _distanceToField * 0.75),
                          prefixIcon: inputFieldValues.tags.isNotEmpty
                              ? SingleChildScrollView(
                                  controller:
                                      inputFieldValues.tagScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      children: inputFieldValues.tags.map(
                                          (DynamicTagData<ButtonData> tag) {
                                    return Chip(
                                      label: Text(tag.tag),
                                      onDeleted: () =>
                                          inputFieldValues.onTagRemoved(tag),
                                      backgroundColor: tag.data.buttonColor,
                                      avatar: CircleAvatar(
                                        backgroundColor: AppTheme.blueColor,
                                        child: CachedNetworkImage(
                                          imageUrl: tag.data.emoji,
                                          imageBuilder:
                                              (context, imageProvider) =>
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: const GradientBoxBorder(
                                                    gradient: LinearGradient(colors: [
                                                      AppTheme.redColor,
                                                      AppTheme.greenColor,
                                                      AppTheme.yellowColor,
                                                      AppTheme.blueColor
                                                    ]),
                                                  ),
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                      image: imageProvider),
                                                ),
                                              ),
                                          placeholder: (context, url) =>
                                              Lottie.asset(
                                            'assets/lottiefiles/circle_loading.json',
                                            fit: BoxFit.fill,
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        ),
                                      ),
                                    );
                                  }).toList()),
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          final getColor = Color.fromARGB(
                              random.nextInt(256),
                              random.nextInt(256),
                              random.nextInt(256),
                              random.nextInt(256));

                          final button = ButtonData(getColor, DEFAULT_AVATAR);
                          final tagData = DynamicTagData(value, button);
                          inputFieldValues.onTagChanged(tagData);
                        },
                        onSubmitted: (value) {
                          final getColor = Color.fromARGB(
                              random.nextInt(256),
                              random.nextInt(256),
                              random.nextInt(256),
                              random.nextInt(256));
                          final button = ButtonData(getColor, DEFAULT_AVATAR);
                          final tagData = DynamicTagData(value, button);
                          inputFieldValues.onTagSubmitted(tagData);
                        },
                      );
                    },
                  );
                },
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text == '') {
                    return const Iterable<DynamicTagData<ButtonData>>.empty();
                  }
                  List<MyUser> users = await userService.fetchUsers();
                  return users
                      .where(
                          (user) => user.email!.contains(textEditingValue.text))
                      .map((user) {
                    final color = Color.fromARGB(
                        random.nextInt(256),
                        random.nextInt(256),
                        random.nextInt(256),
                        random.nextInt(256));
                    print(user.email!);
                    return DynamicTagData<ButtonData>(
                      user.email!,
                      ButtonData(color, user.imageUrl!),
                    );
                  });
                },
                onSelected: (option) =>
                    _toEmailsController.onTagSubmitted(option),
              ),
              if (isShowMore)
                Autocomplete<DynamicTagData<ButtonData>>(
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final DynamicTagData<ButtonData> option =
                                  options.elementAt(index);
                              return TextButton(
                                onPressed: () {
                                  onSelected(option);
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.blueColor,
                                    child: CachedNetworkImage(
                                      imageUrl: option.data.emoji,
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                            decoration: BoxDecoration(
                                              border: const GradientBoxBorder(
                                                gradient: LinearGradient(colors: [
                                                  AppTheme.redColor,
                                                  AppTheme.greenColor,
                                                  AppTheme.yellowColor,
                                                  AppTheme.blueColor
                                                ]),
                                              ),
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                  image: imageProvider),
                                            ),
                                          ),
                                      placeholder: (context, url) =>
                                          Lottie.asset(
                                        'assets/lottiefiles/circle_loading.json',
                                        fit: BoxFit.fill,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                  title: Text(option.tag),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    return TextFieldTags<DynamicTagData<ButtonData>>(
                      textfieldTagsController: _ccEmailsController,
                      textEditingController: textEditingController,
                      focusNode: focusNode,
                      textSeparators: const [' ', ','],
                      letterCase: LetterCase.normal,
                      validator: (DynamicTagData<ButtonData> tag) {
                        if (tag.tag.isEmpty) {
                          return 'Please enter your email';
                        } else if (tag.tag.length > 256) {
                          return 'Your email so long';
                        } else if (!EmailValidator.validate(tag.tag)) {
                          return "Your email is invalid";
                        } else if (_ccEmailsController.getTags!
                            .any((element) => element.tag == tag.tag)) {
                          return 'This email already enter';
                        }

                        return null;
                      },
                      inputFieldBuilder: (context, inputFieldValues) {
                        return TextField(
                          controller: inputFieldValues.textEditingController,
                          focusNode: inputFieldValues.focusNode,
                          decoration: InputDecoration(
                            isDense: true,
                            border: const UnderlineInputBorder(),
                            labelText: "cc",
                            errorText: inputFieldValues.error,
                            prefixIconConstraints: BoxConstraints(
                                maxWidth: _distanceToField * 0.75),
                            prefixIcon: inputFieldValues.tags.isNotEmpty
                                ? SingleChildScrollView(
                                    controller:
                                        inputFieldValues.tagScrollController,
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                        children: inputFieldValues.tags.map(
                                            (DynamicTagData<ButtonData> tag) {
                                      return Chip(
                                        label: Text(tag.tag),
                                        onDeleted: () =>
                                            inputFieldValues.onTagRemoved(tag),
                                        backgroundColor: tag.data.buttonColor,
                                        avatar: CircleAvatar(
                                          backgroundColor: AppTheme.blueColor,
                                          child: CachedNetworkImage(
                                            imageUrl: tag.data.emoji,
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                    Container(
                                              decoration: BoxDecoration(
                                                border: const GradientBoxBorder(
                                                  gradient: LinearGradient(colors: [
                                                    AppTheme.redColor,
                                                    AppTheme.greenColor,
                                                    AppTheme.yellowColor,
                                                    AppTheme.blueColor
                                                  ]),
                                                ),
                                                  shape: BoxShape.circle,
                                                image: DecorationImage(
                                                    image: imageProvider),
                                              ),
                                            ),
                                            placeholder: (context, url) =>
                                                Lottie.asset(
                                              'assets/lottiefiles/circle_loading.json',
                                              fit: BoxFit.fill,
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ),
                                      );
                                    }).toList()),
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            final getColor = Color.fromARGB(
                                random.nextInt(256),
                                random.nextInt(256),
                                random.nextInt(256),
                                random.nextInt(256));

                            final button = ButtonData(getColor, DEFAULT_AVATAR);
                            final tagData = DynamicTagData(value, button);
                            inputFieldValues.onTagChanged(tagData);
                          },
                          onSubmitted: (value) {
                            final getColor = Color.fromARGB(
                                random.nextInt(256),
                                random.nextInt(256),
                                random.nextInt(256),
                                random.nextInt(256));
                            final button = ButtonData(getColor, DEFAULT_AVATAR);
                            final tagData = DynamicTagData(value, button);
                            inputFieldValues.onTagSubmitted(tagData);
                          },
                        );
                      },
                    );
                  },
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text == '') {
                      return const Iterable<DynamicTagData<ButtonData>>.empty();
                    }
                    List<MyUser> users = await userService.fetchUsers();
                    return users
                        .where((user) =>
                            user.email!.contains(textEditingValue.text))
                        .map((user) {
                      final color = Color.fromARGB(
                          random.nextInt(256),
                          random.nextInt(256),
                          random.nextInt(256),
                          random.nextInt(256));
                      print(user.email!);
                      return DynamicTagData<ButtonData>(
                        user.email!,
                        ButtonData(color, user.imageUrl!),
                      );
                    });
                  },
                  onSelected: (option) =>
                      _ccEmailsController.onTagSubmitted(option),
                ),
              if (isShowMore)
                Autocomplete<DynamicTagData<ButtonData>>(
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final DynamicTagData<ButtonData> option =
                                  options.elementAt(index);
                              return TextButton(
                                onPressed: () {
                                  onSelected(option);
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.blueColor,
                                    child: CachedNetworkImage(
                                      imageUrl: option.data.emoji,
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                            decoration: BoxDecoration(
                                              border: const GradientBoxBorder(
                                                gradient: LinearGradient(colors: [
                                                  AppTheme.redColor,
                                                  AppTheme.greenColor,
                                                  AppTheme.yellowColor,
                                                  AppTheme.blueColor
                                                ]),
                                              ),
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                  image: imageProvider),
                                            ),
                                          ),
                                      placeholder: (context, url) =>
                                          Lottie.asset(
                                        'assets/lottiefiles/circle_loading.json',
                                        fit: BoxFit.fill,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                  title: Text(option.tag),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    return TextFieldTags<DynamicTagData<ButtonData>>(
                      textfieldTagsController: _bccEmailsController,
                      textEditingController: textEditingController,
                      focusNode: focusNode,
                      textSeparators: const [' ', ','],
                      letterCase: LetterCase.normal,
                      validator: (DynamicTagData<ButtonData> tag) {
                        if (tag.tag.isEmpty) {
                          return 'Please enter your email';
                        } else if (tag.tag.length > 256) {
                          return 'Your email so long';
                        } else if (!EmailValidator.validate(tag.tag)) {
                          return "Your email is invalid";
                        } else if (_bccEmailsController.getTags!
                            .any((element) => element.tag == tag.tag)) {
                          return 'This email already enter';
                        }

                        return null;
                      },
                      inputFieldBuilder: (context, inputFieldValues) {
                        return TextField(
                          controller: inputFieldValues.textEditingController,
                          focusNode: inputFieldValues.focusNode,
                          decoration: InputDecoration(
                            isDense: true,
                            border: const UnderlineInputBorder(),
                            labelText: "bcc",
                            errorText: inputFieldValues.error,
                            prefixIconConstraints: BoxConstraints(
                                maxWidth: _distanceToField * 0.75),
                            prefixIcon: inputFieldValues.tags.isNotEmpty
                                ? SingleChildScrollView(
                                    controller:
                                        inputFieldValues.tagScrollController,
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                        children: inputFieldValues.tags.map(
                                            (DynamicTagData<ButtonData> tag) {
                                      return Chip(
                                        label: Text(tag.tag),
                                        onDeleted: () =>
                                            inputFieldValues.onTagRemoved(tag),
                                        backgroundColor: tag.data.buttonColor,
                                        avatar: CircleAvatar(
                                          backgroundColor: AppTheme.blueColor,
                                          child: CachedNetworkImage(
                                            imageUrl: tag.data.emoji,
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: const GradientBoxBorder(
                                                      gradient: LinearGradient(colors: [
                                                        AppTheme.redColor,
                                                        AppTheme.greenColor,
                                                        AppTheme.yellowColor,
                                                        AppTheme.blueColor
                                                      ]),
                                                    ),
                                                    shape: BoxShape.circle,
                                                    image: DecorationImage(
                                                        image: imageProvider),
                                                  ),
                                                ),
                                            placeholder: (context, url) =>
                                                Lottie.asset(
                                              'assets/lottiefiles/circle_loading.json',
                                              fit: BoxFit.fill,
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ),
                                      );
                                    }).toList()),
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            final getColor = Color.fromARGB(
                                random.nextInt(256),
                                random.nextInt(256),
                                random.nextInt(256),
                                random.nextInt(256));

                            final button = ButtonData(getColor, DEFAULT_AVATAR);
                            final tagData = DynamicTagData(value, button);
                            inputFieldValues.onTagChanged(tagData);
                          },
                          onSubmitted: (value) {
                            final getColor = Color.fromARGB(
                                random.nextInt(256),
                                random.nextInt(256),
                                random.nextInt(256),
                                random.nextInt(256));
                            final button = ButtonData(getColor, DEFAULT_AVATAR);
                            final tagData = DynamicTagData(value, button);
                            inputFieldValues.onTagSubmitted(tagData);
                          },
                        );
                      },
                    );
                  },
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text == '') {
                      return const Iterable<DynamicTagData<ButtonData>>.empty();
                    }
                    List<MyUser> users = await userService.fetchUsers();
                    return users
                        .where((user) =>
                            user.email!.contains(textEditingValue.text))
                        .map((user) {
                      final color = Color.fromARGB(
                          random.nextInt(256),
                          random.nextInt(256),
                          random.nextInt(256),
                          random.nextInt(256));
                      print(user.email!);
                      return DynamicTagData<ButtonData>(
                        user.email!,
                        ButtonData(color, user.imageUrl!),
                      );
                    });
                  },
                  onSelected: (option) =>
                      _bccEmailsController.onTagSubmitted(option),
                ),
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  prefixText: "From ",
                ),
                controller: _fromController,
              ),
              const SizedBox(
                height: 8,
              ),
              TextFormField(
                decoration: const InputDecoration(
                    border: UnderlineInputBorder(), hintText: "Subject"),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Please enter your subject";
                  } else if (value!.length > 256) {
                    return "Your subject so long";
                  }
                  return null;
                },
                onSaved: (value) => _subject = value,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(
                height: 8,
              ),
              QuillSimpleToolbar(
                controller: _bodyController,
                configurations: const QuillSimpleToolbarConfigurations(
                    multiRowsDisplay: false,
                    showSmallButton: true,
                    showLineHeightButton: true,
                    showAlignmentButtons: true,
                    showDirection: true,
                    decoration: BoxDecoration()),
              ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: QuillEditor.basic(
                    controller: _bodyController,
                    configurations: const QuillEditorConfigurations(
                      placeholder: "Body",
                    ),
                  ),
                ),
              ),
              if (attachments.isNotEmpty)
                Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: attachments.map((attachment) {
                          return GestureDetector(
                            onTap: () => _openFile(attachment),
                            onLongPress: () => _handleDeleteFile(attachment),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SingleChildScrollView(
                                child: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: Card(
                                    elevation: 5.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          10.0), // Rounded corners
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Image.asset(
                                            "assets/images/${attachment.extension}.png",
                                            height: 42,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Image.asset(
                                              "assets/images/unknown.png",
                                              height: 42,
                                            ),
                                          ), // Attachment icon
                                          Text(
                                            attachment.fileName!,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(fileService.formatFileSize(
                                              attachment.size!)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ))
            ],
          ),
        ),
      ),
    );
  }
}
