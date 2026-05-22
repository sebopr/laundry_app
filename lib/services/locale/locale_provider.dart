import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _localeMap = {
  'English': Locale('en'),
  'Deutsch': Locale('de'),
  'Français': Locale('fr'),
  'Italiano': Locale('it'),
  'Rumantsch': Locale('rm'),
};

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  String get languageName =>
      _localeMap.entries
          .firstWhere(
            (e) => e.value.languageCode == _locale.languageCode,
            orElse: () => _localeMap.entries.first,
          )
          .key;

  Future<void> loadFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final lang = doc.data()?['language'] as String?;
      if (lang != null && _localeMap.containsKey(lang)) {
        _locale = _localeMap[lang]!;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String name) async {
    if (!_localeMap.containsKey(name)) return;
    _locale = _localeMap[name]!;
    notifyListeners();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'language': name});
    }
  }
}
