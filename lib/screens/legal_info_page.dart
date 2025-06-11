

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../l10n/app_localizations.dart';


Future<String> loadAsset(String path) async {
  return await rootBundle.loadString(path);
}

class LegalInfoPage extends StatelessWidget {
  const LegalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1A17),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1A17),
          iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
          title: Text(
            AppLocalizations.of(context)!.legalInfoTitle,
            style: const TextStyle(
              fontFamily: 'ChungjuKimSaeng',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.developerInfoTab),
              Tab(text: AppLocalizations.of(context)!.termsOfServiceTab),
              Tab(text: AppLocalizations.of(context)!.privacyPolicyTab),
            ],
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white60,
            indicatorColor: const Color(0xFFD4AF37),
          ),
        ),
        body: const TabBarView(
          children: [
            _DeveloperInfo(),
            _TermsOfService(),
            _PrivacyPolicy(),
          ],
        ),
      ),
    );
  }
}

class _DeveloperInfo extends StatelessWidget {
  const _DeveloperInfo();

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final assetPath = localeCode == 'ko'
        ? 'assets/legal/developer_info_ko.txt'
        : 'assets/legal/developer_info_en.txt';

    return FutureBuilder<String>(
      future: loadAsset(assetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(
            AppLocalizations.of(context)!.loadError,
            style: const TextStyle(color: Colors.white),
          ));
        } else {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(
                snapshot.data ?? '',
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class _TermsOfService extends StatelessWidget {
  const _TermsOfService();

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final assetPath = localeCode == 'ko'
        ? 'assets/legal/terms_of_service_ko.txt'
        : 'assets/legal/terms_of_service_en.txt';
    return FutureBuilder<String>(
      future: loadAsset(assetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(
            AppLocalizations.of(context)!.loadError,
            style: const TextStyle(color: Colors.white),
          ));
        } else {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(
                snapshot.data ?? '',
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class _PrivacyPolicy extends StatelessWidget {
  const _PrivacyPolicy();

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final assetPath = localeCode == 'ko'
        ? 'assets/legal/privacy_policy_ko.txt'
        : 'assets/legal/privacy_policy_en.txt';
    return FutureBuilder<String>(
      future: loadAsset(assetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(
            AppLocalizations.of(context)!.loadError,
            style: const TextStyle(color: Colors.white),
          ));
        } else {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(
                snapshot.data ?? '',
                style: const TextStyle(
                  fontFamily: 'ChungjuKimSaeng',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}