import 'package:flutter/material.dart';
import 'package:laundry_app/pages/login_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool _showLogin = true;

  void _toggle() => setState(() => _showLogin = !_showLogin);

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginPage(onRegisterTap: _toggle);
    } else {
      return RegisterPage(onLoginTap: _toggle);
    }
  }
}
