# Aura AI Chat

Aura is a Flutter chat app with Google sign-in, Gemini responses, saved chat
history, image/file/video attachments, English and Arabic UI, and light/dark
themes. Features are organized under `lib/features/` with domain, data, and
presentation layers; Cubits manage authentication, chat, and settings state.

## Authentication and local chat storage

Firebase Authentication provides Google sign-in and Firebase AI provides
Gemini responses. Configure Google as a Firebase Authentication provider and
set up the Android OAuth client and signing certificate fingerprints.

Chat history and attachment bytes are stored on-device in Hive. Each signed-in
Firebase account has its own local chat database, keyed by its stable user ID.
The user's display name is also stored locally in Hive, while SharedPreferences
tracks whether that account has completed the first-login welcome screen.
This data is not uploaded or synchronized, and is only available on the device
where it was created. All selected attachments are sent to Gemini with their
file names and MIME types when a prompt is submitted. Gemini can only process
formats supported by its multimodal API (such as images, PDFs, plain text, and
supported audio/video formats); other file formats may be rejected by the
service.

The Settings page can protect the app with a password and, when biometrics are
enrolled on the device, fingerprint or another supported biometric. Lock
credentials are stored in the platform's secure storage, and logging out
removes that account's app-lock settings.

## Run

```shell
flutter pub get
flutter run
```

Google sign-in requires the platform OAuth setup above. Web and desktop Firebase
options are not configured in this project.
The app checks for internet access before initializing and displays a
localized offline notice if the connection is unavailable or lost. Internet
access is required for Google sign-in and AI responses; locally saved chats
remain on the device.

## Splash screen

The native splash screen uses the Aura mark and branding assets in `assets/`.
After Flutter starts, an animated Aura splash appears before the auth screen.
After changing the native splash configuration or those images, regenerate the
platform resources with:

```shell
dart run flutter_native_splash:create
```
