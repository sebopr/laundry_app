import 'package:flutter/material.dart';
import 'package:laundry_app/pages/enroll_page.dart';
import 'package:laundry_app/pages/generate_qr_page.dart';
import 'package:laundry_app/pages/settings_page.dart';
import '../services/auth/auth_service.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void logout() {
    //get auth service
    final auth = AuthService();
    auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              //logo
              DrawerHeader(
                child: Center(
                  child: Icon(
                    Icons.local_laundry_service,
                    color: Theme.of(context).colorScheme.primary,
                    size: 90,
                  ),
                ),
              ),

              //home list
              Padding(
                padding: const EdgeInsets.only(left: 25, top: 55),
                child: ListTile(
                  title: const Text("H O M E"),
                  leading: const Icon(Icons.home),
                  onTap: () {
                    //pop the drawer
                    Navigator.pop(context);
                  },
                ),
              ),
              //QR code generator
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: ListTile(
                  title: const Text("G E N E R A T E  Q R"),
                  leading: const Icon(Icons.qr_code_sharp),
                  onTap: () {
                    //pop the drawer
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GenerateQrPage(),
                        ));
                  },
                ),
              ),
              //Enroll Washing machine
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: ListTile(
                  title: const Text("E N R O L L"),
                  leading: const Icon(Icons.qr_code_scanner),
                  onTap: () {
                    //pop the drawer
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnrollPage(),
                        ));
                  },
                ),
              ),
              //settings list
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: ListTile(
                  title: const Text("S E T T I N G S"),
                  leading: const Icon(Icons.settings),
                  onTap: () {
                    //pop the drawer
                    Navigator.pop(context);
                    //navigate to settings page
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ));
                  },
                ),
              ),
            ],
          ),
          //logout tile
          Padding(
            padding: const EdgeInsets.only(left: 25, bottom: 35),
            child: ListTile(
              title: const Text("L O G O U T"),
              leading: const Icon(Icons.logout),
              onTap: () {
                logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}
