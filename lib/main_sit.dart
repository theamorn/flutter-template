import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertemplate/main.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  runZonedGuarded(() async {
    final baseURL = "https://testAPI-sit.com";
    runApp(MyApp(baseURL));
  }, (Object error, StackTrace stack) {
    // FirebaseCrashlytics.instance.recordError(error, stack);
  });
}
