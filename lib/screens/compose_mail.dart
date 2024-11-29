import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:email_validator/email_validator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:gtv_mail/models/attachment.dart';
import 'package:gtv_mail/models/mail.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/file_service.dart';
import 'package:gtv_mail/services/user_service.dart';
import 'package:gtv_mail/utils/image_default.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:uuid/uuid.dart';

import '../services/mail_service.dart';
import '../utils/app_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/button_data.dart';

class ComposeMail extends StatefulWidget {
  ComposeMail({super.key, this.isDraft, this.id, this.isReply, this.isForward});
  String? id;
  bool? isDraft;
  bool? isReply;
  bool? isForward;

  @override
  State<ComposeMail> createState() => _ComposeMailState();
}

class _ComposeMailState extends State<ComposeMail> {
  late String _defaultFontSize = 'Normal';
  late String _defaultFontFamily = "Arial";

  final QuillController _bodyController = QuillController.basic();
  late SharedPreferences prefs;
  final TextEditingController _fromController = TextEditingController();
  var _key = GlobalKey<FormState>();
  bool isSending = false;
  String? _subject;
  final TextEditingController _subjectController = TextEditingController();
  bool isShowMore = false;
  List<Attachment> attachments = [];
  List<PlatformFile> fileCached = [];
  late bool isEmptyContent = true;
  late Mail? mail;
  Map<String, bool> loadingState = {};
  bool isSaving = false;

  void init() async {
    prefs = await SharedPreferences.getInstance();
    MyUser? user = await userService.getLoggedUser();
    if (user != null) {
      setState(() {
        _fromController.text = user.email!;
        _defaultFontSize = prefs.getString('default_font_size') ?? "Normal";
        _defaultFontFamily = prefs.getString('default_font_family') ?? "Arial";
      });
    }

    loadContent();
  }

  void loadContent() async {
    print(
        "isDraft ${widget.isDraft}, isReply ${widget.isReply}, isForward ${widget.isForward}, isNew ${widget.id == null}, id: ${widget.id}");
    if (widget.id?.isNotEmpty ?? false) {
      mail = await mailService.getMailById(widget.id!);

      if(mail!.body!.isEmpty()) {
        isEmptyContent = false;
      }

      if (widget.isDraft ?? false) {
        _subjectController.text = mail!.subject ?? 'Draft';
        _bodyController.document = (mail!.body!.isEmpty()) ? Document() : mail!.body!;
        if (mail!.attachments?.isNotEmpty ?? false) {
          attachments = mail!.attachments!;
        }
      } else if (widget.isReply ?? false) {
        _subjectController.text = 'Re: ${mail!.subject ?? ''}';
        _bodyController.document = (mail!.body!.isEmpty()) ? Document() : mail!.body!;
        _bodyController.document.insert(
          0,
          "At: ${DateFormat('E, dd MMM yyyy \'at\' hh:mm a').format(mail!.sentDate!)}\n"
          "${mail!.from} wrote: \n",
        );
      } else if (widget.isForward ?? false) {
        _subjectController.text = 'Fwd: ${mail!.subject ?? ''}';
        _bodyController.document = (mail!.body!.isEmpty()) ? Document() : mail!.body!;
        _bodyController.document.insert(
          0,
          "------Mail had been forward------\n"
          "From: ${mail!.from}\n"
          "Date: ${DateFormat('E, dd MMM yyyy \'at\' hh:mm a').format(mail!.sentDate!)}\n"
          "To: ${mail!.to!.first}\n\n",
        );
        if (mail!.attachments?.isNotEmpty ?? false) {
          attachments = mail!.attachments!;
        }
      }

      setState(() {});
    }
  }

  @override
  void initState() {
    init();
    super.initState();
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

  Future<void> _openFile(Attachment attachment) async {
    setState(() {
      loadingState[attachment.fileName!] = true;
    });

    try {
      if (widget.isDraft ?? false) {
        final uri = Uri.parse(attachment.url!);
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final tempFilePath = '${tempDir.path}/${attachment.fileName}';

          final file = File(tempFilePath);
          await file.writeAsBytes(response.bodyBytes);

          final result = await OpenFile.open(tempFilePath);

          if (result.type != ResultType.done) {
            showOkAlertDialog(
              context: context,
              title: "Error",
              message: "Could not open the file.",
            );
          }
        }
      } else if (attachment.url != null) {
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
    } catch (e) {
      showOkAlertDialog(
        context: context,
        title: "Error",
        message: "An error occurred while opening the file.",
      );
    } finally {
      setState(() {
        loadingState[attachment.fileName!] = false;
      });
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

      if (widget.id?.isNotEmpty ?? false) {
        if (widget.isReply ?? false) {
          newMail.isReplyMail = true;
          mail = await mailService.getMailById(widget.id!);
          if (mail!.replies?.isEmpty ?? true) {
            mail!.replies = [newMail];
          } else {
            mail!.replies!.add(newMail);
          }
          await mailService.updateMail(mail!);
        }
      }

      await mailService.sendEmail(newMail);

      Navigator.pop(context);
    }
  }

  void _saveDraft() async {
    _key.currentState?.save();

    List<String> toEmails =
        _toEmailsController.getTags?.map((tag) => tag.tag).toList() ?? [];
    List<String> ccEmails =
        _ccEmailsController.getTags?.map((tag) => tag.tag).toList() ?? [];
    List<String> bccEmails =
        _bccEmailsController.getTags?.map((tag) => tag.tag).toList() ?? [];

    List<Attachment> sendAttachments = [];
    if (attachments.isNotEmpty) {
      sendAttachments = await fileService.mapFilesToAttachments(fileCached);
    }

    String uid = const Uuid().v8();

    Mail draft = Mail(
      uid: uid,
      from: _fromController.text,
      subject: _subject,
      to: toEmails.isEmpty ? null : toEmails,
      cc: ccEmails.isEmpty ? null : ccEmails,
      bcc: bccEmails.isEmpty ? null : bccEmails,
      body: _bodyController.document,
      sentDate: DateTime.now(),
      attachments: sendAttachments.isNotEmpty ? sendAttachments : null,
      isDraft: true,
    );

    _subject = _subject?.trim() ?? '';
    if ((_subject?.isEmpty ?? false) &&
        toEmails.isEmpty &&
        ccEmails.isEmpty &&
        bccEmails.isEmpty &&
        _bodyController.document.isEmpty() &&
        sendAttachments.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      isSaving = true;
    });

    const snackBar = SnackBar(
      content: Text('Draft is saving...'),
      duration: Duration(days: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    if (_subject?.isEmpty ?? true) draft.subject = "Draft";

    await mailService.sendEmail(draft);

    setState(() {
      isSaving = false;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Navigator.pop(context, draft);
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
              if (widget.id?.isEmpty ?? true) {
                _saveDraft();
              } else {
                Navigator.pop(context);
              }
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
                                                gradient: LinearGradient(
                                                    colors: [
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
                                                  gradient: LinearGradient(
                                                      colors: [
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
                                                  gradient: LinearGradient(
                                                      colors: [
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
                controller: _subjectController,
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
                configurations: QuillSimpleToolbarConfigurations(
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                        fontSize: QuillToolbarFontSizeButtonOptions(
                          rawItemsMap: const {
                            'Small': '8',
                            'Normal': '14',
                            'Medium': '24.5',
                            'Large': '46',
                            'Huge': '64',
                            'Clear': '0',
                          },
                          initialValue: _defaultFontSize ?? 'Normal',
                          onSelected: (value) => setState(() {
                            _defaultFontSize = value;
                          }),
                        ),
                        fontFamily: QuillToolbarFontFamilyButtonOptions(
                          rawItemsMap: appFonts,
                          initialValue: _defaultFontFamily,
                          onSelected: (value) => setState(() {
                            _defaultFontFamily = value;
                          }),
                        )),
                    multiRowsDisplay: false,
                    showSmallButton: true,
                    showLineHeightButton: true,
                    showAlignmentButtons: true,
                    showDirection: true,
                    decoration: const BoxDecoration()),
              ),
              const SizedBox(
                height: 24,
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
                      configurations: QuillEditorConfigurations(
                        showCursor: true,
                        keyboardAppearance: Theme.of(context).brightness,
                        placeholder: (widget.id != null && isEmptyContent) ? "Loading content..." : "Body",
                        customStyles: DefaultStyles(
                          paragraph: DefaultTextBlockStyle(
                            TextStyle(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyMedium!
                                  .color,
                              fontSize: {
                                    'Small': 8,
                                    'Normal': 14,
                                    'Medium': 24.5,
                                    'Large': 46,
                                    'Huge': 64,
                                    'Clear': 0,
                                  }[_defaultFontSize]
                                      ?.toDouble() ??
                                  14.0,
                              fontFamily: _defaultFontFamily,
                            ),
                            const HorizontalSpacing(0.0, 0.0),
                            const VerticalSpacing(10.0, 10.0),
                            const VerticalSpacing(1.5, 1.5),
                            null,
                          ),
                        ),
                      ),
                    )),
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
                                          if (loadingState[attachment.fileName!] == true)
                                            SizedBox(
                                                width: 42,
                                                child: Lottie.asset(
                                                  'assets/lottiefiles/circle_loading.json',
                                                  fit: BoxFit.fill,
                                                ))
                                          else
                                            Image.asset(
                                              "assets/images/${attachment.extension}.png",
                                              height: 42,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Image.asset(
                                                    "assets/images/unknown.png",
                                                    height: 42,
                                                  ),
                                            ), // At// tachment iAttachm
                                          Text(
                                            attachment.fileName!,
                                            style: const TextStyle(
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
