import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/file_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

import '../services/user_service.dart';
import '../utils/app_theme.dart';
import '../utils/image_default.dart';

class UserProfileScreen extends StatefulWidget {
  UserProfileScreen({super.key, required this.id});
  String id;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late MyUser user = MyUser();
  Widget buildEditIcon(Color color) => buildCircle(
        color: Colors.white,
        all: 3,
        child: buildCircle(
          color: color,
          all: 8,
          child: const Icon(
            Icons.edit,
            color: Colors.white,
            size: 20,
          ),
        ),
      );

  Widget buildCircle({
    required Widget child,
    required double all,
    required Color color,
  }) =>
      ClipOval(
        child: Container(
          padding: EdgeInsets.all(all),
          color: color,
          child: child,
        ),
      );

  late var _nameController = TextEditingController();
  late var _phoneController = TextEditingController();
  late String email = "";
  late var _2FAcontroller = ValueNotifier<bool>(false);
  var _key = GlobalKey<FormState>();

  void init() async {
    user = await userService.getUserByID(widget.id);
    setState(() {
      _nameController.text = user.name!;
      _phoneController.text = user.phone!;
      email = user.email!;
      _2FAcontroller.value = user.isEnable2FA;
    });

    _2FAcontroller.addListener(() {
      setState(() {});
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  void _handleSaveUpdate() async {
    MyUser user = await userService.getUserByID(widget.id);
    if (_key.currentState?.validate() ?? false) {
        if (_2FAcontroller.value != user.isEnable2FA || _nameController.text != user.name!) {
          user.isEnable2FA = _2FAcontroller.value;
          user.name = _nameController.text;
          await userService.updateUser(user);

          init();

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('All changes have been saved!'),
            backgroundColor: AppTheme.greenColor,
          ));
        }
    }
  }

  void _handleChangePassword() async {
    var password = '';
    MyUser user = await userService.getUserByID(widget.id);

    var result = await showTextInputDialog(
      title: "Change password",
      context: context,
      canPop: false,
      okLabel: "Save",
      textFields: [
        DialogTextField(
          hintText: "Old password",
          obscureText: true,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return "Please enter your password";
            } else if (value!.length < 6) {
              return "Password must have at least 6 characters";
            } else if (!BCrypt.checkpw(value, user.password!)) {
              return "Password is not correct";
            }
            return null;
          },
        ),
        DialogTextField(
          hintText: "New password",
          obscureText: true,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return "Please enter your new password";
            } else if (value!.length < 6) {
              return "Password must have at least 6 characters";
            }
            password = value;
            return null;
          },
        ),
        DialogTextField(
          hintText: "Confirm password",
          obscureText: true,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return "Please confirm your password";
            } else if (value != password) {
              return "Password does not match";
            }
            return null;
          },
        )
      ],
    );

    if (result != null) {
      user.password = BCrypt.hashpw(result.last, BCrypt.gensalt());

      await userService.updateUser(user);
      init();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Password has been changed!'),
              backgroundColor: AppTheme.greenColor,
            ));
    }
  }

  void _handleChangeAvatar() async {
    final result = await showModalActionSheet<String>(
      context: context,
      actions: const [
        SheetAction(
          icon: Icons.camera_alt_outlined,
          label: 'Camera',
          key: 'camera',
        ),
        SheetAction(
          icon: Icons.image_outlined,
          label: 'Gallery',
          key: 'gallery',
        ),
      ],
    );

    if (result != null) {
      final ImagePicker _picker = ImagePicker();
      late final XFile? image;
      switch (result) {
        case 'camera':
          image = await _picker.pickImage(source: ImageSource.camera);
          break;
        case 'gallery':
          image = await _picker.pickImage(source: ImageSource.gallery);
          break;
      }

      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The avatar has been changed; it will take some time to apply.'),
          backgroundColor: AppTheme.greenColor,
        ));

        String newAvatarUrl = await fileService.updateAvatar(image, '$email.png');

        MyUser user = await userService.getUserByID(widget.id);
        user.imageUrl = newAvatarUrl;

        await userService.updateUser(user);
        init();

        setState(() {

        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: _key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleChangeAvatar,
                        customBorder: const CircleBorder(),
                        child: CachedNetworkImage(
                          imageUrl: user.imageUrl ?? DEFAULT_AVATAR,
                          imageBuilder: (context, imageProvider) => Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              border: const GradientBoxBorder(
                                gradient: LinearGradient(colors: [
                                  AppTheme.redColor,
                                  AppTheme.greenColor,
                                  AppTheme.yellowColor,
                                  AppTheme.blueColor
                                ]),
                              ),
                              color: AppTheme.blueColor,
                              shape: BoxShape.circle,
                              image: DecorationImage(image: imageProvider),
                            ),
                          ),
                          placeholder: (context, url) => Lottie.asset(
                            'assets/lottiefiles/circle_loading.json',
                            fit: BoxFit.fill,
                            width: 128,
                            height: 128
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                              onTap: _handleChangeAvatar,
                              customBorder: const CircleBorder(),
                              child: buildEditIcon(
                                  Theme.of(context).colorScheme.primary))),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(email, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 24),
                TextField(
                  readOnly: true,
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: "Phone number",
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: CountryFlag.fromCountryCode(
                            "VN",
                            height: 15,
                            width: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    hintText: "Enter your Full Name",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: TextEditingController(
                      text:
                          "Two-step Verification is ${_2FAcontroller.value ? "enabled" : "disabled"}"),
                  readOnly: true,
                  decoration: InputDecoration(
                    enabled: true,
                    labelText: "Two-step Verification",
                    prefixIcon: const Icon(Icons.verified_user),
                    suffixIconConstraints:
                        BoxConstraints(minHeight: 30, maxHeight: 50),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: AdvancedSwitch(
                        controller: _2FAcontroller,
                        activeColor: Colors.green,
                        inactiveColor: Colors.grey,
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                        width: 50.0,
                        height: 30.0,
                        enabled: true,
                        disabledOpacity: 0.5,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _handleChangePassword,
                      child: const Text("Change password"),
                    )
                  ],
                ),
                ElevatedButton(
                    onPressed: _handleSaveUpdate,
                    child: const Text("Save all changes"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
