

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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
          title: const Text(
            '법적 고지',
            style: TextStyle(
              fontFamily: 'ChungjuKimSaeng',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: '개발자 정보'),
              Tab(text: '이용약관'),
              Tab(text: '개인정보처리방침'),
            ],
            labelColor: Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white60,
            indicatorColor: Color(0xFFD4AF37),
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
    return FutureBuilder<String>(
      future: loadAsset('assets/legal/developer_info.txt'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('정보를 불러오지 못했습니다.', style: TextStyle(color: Colors.white)));
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
    return FutureBuilder<String>(
      future: loadAsset('assets/legal/terms_of_service.txt'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('정보를 불러오지 못했습니다.', style: TextStyle(color: Colors.white)));
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
    return FutureBuilder<String>(
      future: loadAsset('assets/legal/privacy_policy.txt'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('정보를 불러오지 못했습니다.', style: TextStyle(color: Colors.white)));
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