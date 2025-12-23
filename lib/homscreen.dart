import 'package:flutter/material.dart';
import 'package:oruma_app/eq_registeration.dart';
import 'package:oruma_app/eq_supply.dart';
import 'package:oruma_app/homevisit.dart';
import 'package:oruma_app/pt_registration.dart' show patientrigister;

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
          width: 120,
          child: Column(children: [
            TextButton(onPressed: (){}, child: Text("Setting")),
            TextButton(onPressed: (){}, child: Text("About us")),
            TextButton(onPressed: (){}, child: Text("Gellery"))
            
          ],),
        ),
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildButton(
                    context,
                    title: "Patient Registration",
                    icon: Icons.person_add_alt_1,
                    page: const patientrigister(),
                  ),
                  _buildButton(
                    context,
                    title: "Medicine Register",
                    icon: Icons.local_hospital,
                    page: const Homevisit(),
                  ),
                  _buildButton(
                    context,
                    title: "Equipment Register",
                    icon: Icons.inventory_2,
                    page: EquipmentRegistration(),
                  ),
                  _buildButton(
                    context,
                    title: "Home Visit",
                    icon: Icons.home_filled,
                    page: const Homevisit(),
                  ),
        
                  _buildButton(
                    context,
                    title: "Equipment Supply",
                    icon: Icons.medical_services_outlined,
                    page: const EqSupply(),
                  ),
                  _buildButton(
                    context,
                    title: "Medicine Supply",
                    icon: Icons.local_hospital,
                    page: const EqSupply(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget page,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.black,
      ),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.blueAccent),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
