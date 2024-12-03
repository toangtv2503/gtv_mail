
# Project Name: GTV Mail

## Project Description
GTV Mail is an email service application that simulates a platform similar to Gmail. It features Account Management, Compose and Send Email, View Emails, Search Functionality, Label Management, Notifications for New Emails, Auto-Answer Mode, Settings, and User Preferences. The application is designed to work across multiple platforms, including iOS, Android, and Web.

## Technologies Used
- Dart
- Flutter
- Firebase

## Building Instructions
To set up the project, follow these steps:

1. Unzip the `gtv_mail.zip` file in your `source` folder.
2. Open the unzipped project in Android Studio or Visual Studio Code.
3. Run the following command in the terminal of the project:
   ```bash
   flutter pub get
   ```
4. Open a platform device (e.g., emulator, web browser, or simulator).
5. Run the project by clicking the start button in the IDE or using the following command:
   ```bash
   flutter run
   ```

## Running Instructions
To build the project for specific platforms, use the following commands:

- For **Web**:
   ```bash
   flutter build web --release --web-renderer canvaskit --base-href "/"
   ```
- For **iOS**:
   ```bash
   flutter build ios --release --no-codesign
   ```
- For **Android**:
   ```bash
   flutter build apk --release --split-per-abi
   ```

## URL and Server Login Information
- **Public URL (Web version)**: [https://toangtv2503.github.io/gtv_mail/](https://toangtv2503.github.io/gtv_mail/)

### Test Account Information:
You can log in to the application using the following pre-loaded accounts for evaluation:

| Phone Number   | Email                 | Password | Verification Code (OTP) |
|----------------|-----------------------|----------|-------------------------|
| +84999999999   | demo@demo.demo        | 123123   | 000000                  |
| +84123123123   | 123123@gmail.com       | 123123   | 000000                  |
| +84111111111   | 111111111@gmail.com    | 123123   | 000000                  |
| +84987654321   | test@gmail.com         | 123123   | 000000                  |

### Test Account Registration:
To register a new account, use the following phone numbers and OTPs:

| Phone Number   | OTP    |
|----------------|--------|
| +84123456789   | 000000 |
| +84321321321   | 000000 |

### iOS Version:
If you're using the `.ipa` for the iOS version, you can use a real phone number with real SMS OTP for registration.

## Release Build Information
You can use the following release builds for each platform:

- **Android**:
    - `app-arm64-v8a-release.apk`
    - `app-armeabi-v7a-release.apk`
    - `app-x86_64-release.apk`

- **iOS**:
    - `app.ipa` (Use Sideloadly to sideload the `.ipa` file onto your iOS device)

- **Web**:
    - `web.zip` (Unzip and run the application locally with the following command):
      ```bash
      python -m http.server 8000
      ```
    - The app will run at [http://localhost:8000](http://localhost:8000). You can adjust the port if needed.
    - Or you can use the public URL: [https://toangtv2503.github.io/gtv_mail/](https://toangtv2503.github.io/gtv_mail/)

## Demo Video
Watch the demo video to see the application in action: [Demo Video](https://youtu.be/TzKRfAwHRk4)

### Developed by GTV Team ❤
