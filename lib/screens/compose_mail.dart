import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:gtv_mail/utils/app_theme.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textfield_tags/textfield_tags.dart';

import '../utils/button_data.dart';

class ComposeMail extends StatefulWidget {
  ComposeMail({super.key, this.isDraft = true, this.draftId});
  bool? isDraft;
  String? draftId;

  @override
  State<ComposeMail> createState() => _ComposeMailState();
}

class _ComposeMailState extends State<ComposeMail> {
  final QuillController _controller = QuillController.basic();
  late SharedPreferences prefs;
  final TextEditingController _fromController = TextEditingController();
  final _stringTagController = StringTagController();
  var _key = GlobalKey<FormState>();

  void init() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _fromController.text = prefs.getString('email') ?? '';
    });
    _dynamicTagController = DynamicTagController<DynamicTagData<ButtonData>>();
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fromController.dispose();
    _dynamicTagController.dispose();
    super.dispose();
  }

  void _handleAttachment() {

  }

  void _handleSend() {
    if(_key.currentState?.validate() ?? false) {
      _key.currentState!.save();

      List<String> toEmails = _dynamicTagController.getTags!.map((tag) => tag.tag).toList();
      print(toEmails);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  late double _distanceToField;
  late DynamicTagController<DynamicTagData<ButtonData>> _dynamicTagController;
  final random = Random();

  static final List<DynamicTagData<ButtonData>> _initialTags = [
    DynamicTagData<ButtonData>(
      'cat',
      const ButtonData(
        Color.fromARGB(255, 202, 198, 253),
        "😽",
      ),
    ),
    DynamicTagData(
      'penguin',
      const ButtonData(
        Color.fromARGB(255, 199, 244, 255),
        '🐧',
      ),
    ),
    DynamicTagData(
      'tiger',
      const ButtonData(
        Color.fromARGB(255, 252, 195, 250),
        '🐯',
      ),
    ),
    DynamicTagData<ButtonData>(
      'whale',
      const ButtonData(
        Color.fromARGB(255, 209, 248, 193),
        "🐋",
      ),
    ),
    DynamicTagData<ButtonData>(
      'bear',
      const ButtonData(
        Color.fromARGB(255, 254, 237, 199),
        '🐻',
      ),
    ),
    DynamicTagData(
      'lion',
      const ButtonData(
        Color.fromARGB(255, 252, 196, 196),
        '🦁',
      ),
    ),
  ];

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
              onPressed: _handleSend, icon: const Icon(Icons.send_outlined)),
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
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: CachedNetworkImage(
                                      imageUrl: option.data.emoji,
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                        decoration: BoxDecoration(
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
                    textfieldTagsController: _dynamicTagController,
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
                      } else if (_dynamicTagController.getTags!
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
                          prefixText: "To ",
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
                                    return Container(
                                      height: 23,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(20.0),
                                        ),
                                        color: tag.data.buttonColor,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      padding:const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  child: CachedNetworkImage(
                                                    imageUrl: tag.data.emoji,
                                                    imageBuilder: (context, imageProvider) =>
                                                        Container(
                                                          decoration: BoxDecoration(
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
                                                Text(tag.tag)
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4.0),
                                          InkWell(
                                            child: const Icon(
                                              Icons.cancel,
                                              size: 14.0,
                                            ),
                                            onTap: () => inputFieldValues.onTagRemoved(tag),
                                          )
                                        ],
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

                          final button = ButtonData(getColor, '✨');
                          final tagData = DynamicTagData(value, button);
                          inputFieldValues.onTagChanged(tagData);
                        },

                        onSubmitted: (value) {
                          final getColor = Color.fromARGB(
                              random.nextInt(256),
                              random.nextInt(256),
                              random.nextInt(256),
                              random.nextInt(256));
                          final button = ButtonData(getColor, '✨');
                          final tagData = DynamicTagData(value, button);
                          inputFieldValues.onTagSubmitted(tagData);
                        },
                      );
                    },
                  );
                },
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<DynamicTagData<ButtonData>>.empty();
                  }
                  return _initialTags
                      .where((DynamicTagData<ButtonData> option) {
                    return option.tag
                        .contains(textEditingValue.text);
                  });
                },
                onSelected: (option) => _dynamicTagController.onTagSubmitted(option),
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
              ),
              const SizedBox(
                height: 8,
              ),
              QuillSimpleToolbar(
                controller: _controller,
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: QuillEditor.basic(
                    controller: _controller,
                    configurations: const QuillEditorConfigurations(
                      placeholder: "Body",
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
