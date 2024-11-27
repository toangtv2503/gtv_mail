import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:country_flags/country_flags.dart';
import 'package:country_phone_validator/country_phone_validator.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gtv_mail/components/otp_dialog.dart';
import 'package:gtv_mail/models/user.dart';
import 'package:gtv_mail/services/user_service.dart';
import 'package:gtv_mail/utils/country_codes.dart';
import 'package:lottie/lottie.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/image_default.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _registerKey = GlobalKey<FormState>();
  String? username;
  String? phoneNumber;
  String? password;
  String? confirmPassword;
  String? email;

  String isoCode = "VN";
  String dialCode = "+84";
  int? currentIndex;

  bool _isLoading = false;

  @override
  void initState() {
    currentIndex =
        MyCountry.countries.indexWhere((country) => country.isoCode == isoCode);
    super.initState();
  }

  void _showPhoneExistsDialog() {
    showOkAlertDialog(
      context: context,
      title: "Phone Number Exists",
      message: "Your phone number already exists. Please use a different phone number.",
    );
  }

  void _showEmailExistsDialog() {
    showOkAlertDialog(
      context: context,
      title: "Email Exists",
      message: "Your email address already exists. Please use a different email address.",
    );
  }

  void _showCountriesModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        currentIndex = MyCountry.countries
            .indexWhere((country) => country.isoCode == isoCode);
        return ScrollablePositionedList.separated(
          initialScrollIndex: currentIndex!,
          itemCount: MyCountry.countries.length,
          itemBuilder: (context, index) => ListTile(
            leading: CountryFlag.fromCountryCode(
              MyCountry.countries[index].isoCode,
            ),
            title: Text(MyCountry.countries[index].name),
            subtitle: Text(MyCountry.countries[index].dialCode),
            trailing: MyCountry.countries[index].isoCode == isoCode
                ? const Icon(
                    Icons.check,
                    color: Colors.green,
                  )
                : null,
            onTap: () {
              setState(() {
                isoCode = MyCountry.countries[index].isoCode;
                dialCode = MyCountry.countries[index].dialCode;
              });
              Navigator.pop(context);
            },
          ),
          separatorBuilder: (context, index) => const Divider(),
        );
      },
    );
  }

  void _handleRegister() async {
    if (_registerKey.currentState!.validate()) {
      _registerKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      bool phoneExists = await userService.checkPhoneNumberExists(phoneNumber!);
      bool emailExists = await userService.checkEmailExisted(email!);

      if (phoneExists) {
        _showPhoneExistsDialog();
        setState(() {
          _isLoading = false;
        });
      } else if (emailExists) {
        _showEmailExistsDialog();
        setState(() {
          _isLoading = false;
        });
      } else {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (_) {},
          verificationFailed: (FirebaseAuthException e) {
            showOkAlertDialog(
            context: context,
            title: "Verification Failed",
            message: "Your phone number not support. Please try another one.",
            );
          },
          codeSent: (String verificationId, int? resendToken) async {
            var credential = await showDialog(
              context: context,
              builder: (context) => OtpDialog(verificationId: verificationId),
            );

            if (credential != null) {
              try {
                UserCredential userCredential = await FirebaseAuth.instance
                    .signInWithCredential(credential);
                User? user = userCredential.user;

                if (user != null) {
                  MyUser newUser = MyUser(
                      uid: user.uid,
                      name: username,
                      phone: phoneNumber,
                      email: email,
                      imageUrl: DEFAULT_AVATAR,
                      password: BCrypt.hashpw(password.toString(), BCrypt.gensalt()));

                  await userService.registerAccount(newUser, user);


                  context.pushNamed('home');
                }
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });

                showOkAlertDialog(
                  context: context,
                  title: "Verification Failed",
                  message: "Your OTP code is wrong.",
                );
              }
            }
          },
          codeAutoRetrievalTimeout: (verificationId) {},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _registerKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Register', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 20),
          TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your username';
              } else if (value!.length > 256) {
                return 'Your username so long';
              }
              return null;
            },
            onSaved: (value) => username = value,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          TextFormField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      _showCountriesModal();
                    },
                    icon: CountryFlag.fromCountryCode(
                      isoCode,
                      height: 15,
                      width: 20,
                    ),
                  ),
                  Text("$dialCode ")
                ],
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your username';
              } else if (!CountryUtils.validatePhoneNumber(value!, dialCode)) {
                return 'Your phone number is invalid';
              }
              return null;
            },
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11)
            ],
            onSaved: (value) => phoneNumber = "$dialCode$value",
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your email';
              } else if (value!.length > 256) {
                return 'Your email so long';
              } else if (!EmailValidator.validate(value)) {
                return "Your email is invalid";
              }

              return null;
            },
            onSaved: (value) => email = value,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your password';
              } else if (value!.length > 256) {
                return 'Your password so long';
              }
              password = value;
              return null;
            },
            onSaved: (value) => password = value,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.check),
            ),
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please confirm your password';
              } else if (value != password) {
                return 'Your password does not matched';
              }
              return null;
            },
            onSaved: (value) => confirmPassword = value,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleRegister,
            child: _isLoading
                ? Lottie.asset(
                    'assets/lottiefiles/circle_loading.json',
                    fit: BoxFit.fill,
                  )
                : const Text('Register'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
