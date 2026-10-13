import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/brand.dart';
import 'core/theme.dart';
import 'data/sentiment_api.dart';
import 'shell.dart';

class SentimentApp extends StatefulWidget {
  const SentimentApp({super.key});

  @override
  State<SentimentApp> createState() => _SentimentAppState();
}

class _SentimentAppState extends State<SentimentApp> {
  final SentimentApi _api = SentimentApi();
  late final ThemeData _theme = buildTheme();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${Brand.name} | ${Brand.title}',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Shell(api: _api),
    );
  }
}
