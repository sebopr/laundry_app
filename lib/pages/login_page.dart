// ignore_for_file: use_build_context_synchronously
import 'package:laundry_app/auth/auth_service.dart';
import 'package:laundry_app/components/my_textfield.dart';
import 'package:laundry_app/components/my_button.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final void Function()? onTap;

  LoginPage({super.key, required this.onTap});

  get context => null;

  //tap to go to the register page

  void login(BuildContext context) async {
    //login method
    final authService = AuthService();
    try {
      await authService.signInWithEmailPassword(
          _emailController.text, _pwController.text);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //logo
            Icon(
              Icons.message,
              size: 60,
              color: Theme.of(context).colorScheme.secondary,
            ),

            const SizedBox(height: 30),

            //Welcome back message
            Text(
              "Welcome Back!!! We missed you!!!",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 25),

            //email text field
            MyTextField(
              hintText: "Email",
              obscureText: false,
              controller: _emailController,
            ),

            const SizedBox(height: 10),

            //pw field
            MyTextField(
              controller: _pwController,
              hintText: "Password",
              obscureText: true,

            ),

            //login button
            const SizedBox(height: 30),

            MyButton(
              text: "Login",
              onTap: () => login(context),
            ),

            //register now
            const SizedBox(height: 25),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                "Not a member?",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  "   Register now!",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
