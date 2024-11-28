import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:gtv_mail/models/answer_template.dart';
import 'package:gtv_mail/services/template_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/app_fonts.dart';
import '../utils/app_theme.dart';

class AutoAnswerMail extends StatefulWidget {
  AutoAnswerMail({super.key, required this.userId});
  String userId;

  @override
  State<AutoAnswerMail> createState() => _AutoAnswerMailState();
}

class _AutoAnswerMailState extends State<AutoAnswerMail> {
  final _subjectController = TextEditingController();
  final QuillController _bodyController = QuillController.basic();
  late SharedPreferences prefs;
  late String _defaultFontSize = 'Normal';
  late String _defaultFontFamily = "Arial";
  late bool isEmptyContent = true;
  late MyUser user;
  late bool isTemplateExisted = false;
  late AnswerTemplate? template;
  var _key = GlobalKey<FormState>();

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
    user = await userService.getUserByID(widget.userId);
    if (user != null) {
      setState(() {
        _defaultFontSize = prefs.getString('default_font_size') ?? "Normal";
        _defaultFontFamily = prefs.getString('default_font_family') ?? "Arial";
        _subjectController.text = "Thank You for Your Email";
      });
    }
    await fetchTemplate();
  }

  Future<void> fetchTemplate() async {
    template = await templateService.getTemplateByEmail(user.email!);

    if (template != null) {
      setState(() {
        isTemplateExisted = true;
        _subjectController.text = template!.subject ?? "";
        _bodyController.document = template!.body ?? Document();
      });
    } else {
      setState(() {
        _subjectController.text = "Thank You for Your Email";
        _bodyController.document.insert(0, "Hi [%recipient_name%]\n\n"
            "Thank you for contacting us. ❤️\n"
            "We’ve received email and will get back to you as soon as possible.\n"
            "For urgent matters, please contact me at [%your_phone%].\n\n"
            "Best regards,\n"
            "[%your_name%]");
      });
    }

  }

  void copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$value copied to clipboard!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleSaveTemplate() async {
    if(_key.currentState?.validate() ?? false) {
      _key.currentState!.save();

      print(_subjectController.text);
      print(_bodyController.document.toPlainText());

      if (isTemplateExisted) {
        AnswerTemplate updateTemplate = AnswerTemplate(
            id: template!.id,
            mail: template!.mail,
            subject: _subjectController.text,
            body: _bodyController.document
        );

        await templateService.updateTemplate(updateTemplate);
      } else {
        String id = Uuid().v4();
        AnswerTemplate newTemplate = AnswerTemplate(
            id: id,
            mail: user.email!,
            subject: _subjectController.text,
            body: _bodyController.document
        );

        await templateService.addTemplate(newTemplate);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Template has been saved!'),
        backgroundColor: AppTheme.greenColor,
        duration: Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text("Auto Answer Template", style: Theme.of(context).textTheme.titleLarge,),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _key,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              const SizedBox(height: 16,),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: "Subject",
                  hintText: "Enter Your Subject",
                  border: OutlineInputBorder()
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Please enter your subject";
                  } else if (value!.length > 256) {
                    return "Your subject so long";
                  }
                  return null;
                },
                onSaved: (value) => _subjectController.text = value ?? "",
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16,),
              Expanded(
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
                        placeholder: (isEmptyContent) ? "Loading content..." : "Body",
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => copyToClipboard(context, '[%recipient_name%]'),
                        child: const Chip(
                          label: Text('[%recipient_name%]'),
                          backgroundColor: AppTheme.redColor,
                        ),
                      ),
                      const SizedBox(width: 8,),
                      GestureDetector(
                        onTap: () => copyToClipboard(context, '[%your_phone%]'),
                        child: const Chip(
                          label: Text('[%your_phone%]'),
                          backgroundColor: AppTheme.greenColor,
                        ),
                      ),
                      const SizedBox(width: 8,),
                      GestureDetector(
                        onTap: () => copyToClipboard(context, '[%your_name%]'),
                        child: const Chip(
                          label: Text('[%your_name%]'),
                          backgroundColor: AppTheme.yellowColor,
                        ),
                      ),
                      const SizedBox(width: 8,),
                      GestureDetector(
                        onTap: () => copyToClipboard(context, '[%your_email%]'),
                        child: const Chip(
                          label: Text('[%your_email%]'),
                          backgroundColor: AppTheme.blueColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(onPressed: _handleSaveTemplate, child: const Text("Save Template")),
              )
            ],
          ),
        ),
      ),
    );
  }
}
