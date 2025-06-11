import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class RuleTutorialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> rules = [
      {
        'title': AppLocalizations.of(context)!.rule1Title,
        'desc': AppLocalizations.of(context)!.rule1Desc,
        'asset': 'lib/img/tutorial/1.gif',
      },
      {
        'title': AppLocalizations.of(context)!.rule2Title,
        'desc': AppLocalizations.of(context)!.rule2Desc,
        'asset': 'lib/img/tutorial/2.gif',
      },
      {
        'title': AppLocalizations.of(context)!.rule3Title,
        'desc': AppLocalizations.of(context)!.rule3Desc,
        'asset': 'lib/img/tutorial/3.gif',
      },
      {
        'title': AppLocalizations.of(context)!.rule4Title,
        'desc': AppLocalizations.of(context)!.rule4Desc,
        'asset': 'lib/img/tutorial/4.gif',
      },
      {
        'title': AppLocalizations.of(context)!.rule5Title,
        'desc': AppLocalizations.of(context)!.rule5Desc,
        'asset': 'lib/img/tutorial/5.gif',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1A17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1A17),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        title: Text(
          AppLocalizations.of(context)!.gameRulesTitle,
          style: const TextStyle(
            fontFamily: 'ChungjuKimSaeng',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PageView.builder(
          itemCount: rules.length,
          itemBuilder: (context, index) {
            final rule = rules[index];
            return Column(
              children: [
                Text(rule['title']!,
                    style: const TextStyle(
                      fontFamily: 'ChungjuKimSaeng',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    )),
                const SizedBox(height: 12),
                Text(rule['desc']!,
                    style: const TextStyle(
                      fontFamily: 'ChungjuKimSaeng',
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Image.asset(rule['asset']!, fit: BoxFit.contain),
                    // 또는: VideoPlayerController.asset('...') 를 사용한 영상도 가능
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}