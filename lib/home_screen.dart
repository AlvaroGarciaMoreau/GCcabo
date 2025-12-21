import 'package:flutter/material.dart';
import 'package:gccabo/quiz_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gccabo/auth/login_screen.dart';
import 'package:gccabo/settings_screen.dart';
import 'package:gccabo/results_list_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final Map<String, String> topics = {
    'Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL':
        'assets/Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL/ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL.json',
    'Tema 2 RÉGIMEN INTERIOR':
        'assets/Tema 2 RÉGIMEN INTERIOR/Regimen anterior.json',
    'Tema 3 DEONTOLOGÍA PROFESIONAL':
        'assets/Tema 3 DEONTOLOGÍA PROFESIONAL/Deontologia profesional.json',
    'Tema 4 DERECHOS HUMANOS':
        'assets/Tema 4 DERECHOS HUMANOS/Derechos Humanos.json',
    'Tema 5 DERECHO ADMINISTRATIVO':
        'assets/Tema 5 DERECHO ADMINISTRATIVO/Derecho administrativo.json',
    'Tema 6 PROTECCIÓN DE LA SEGURIDAD CIUDADANA':
        'assets/Tema 6 PROTECCIÓN DE LA SEGURIDAD CIUDADANA/Seguridad ciudadana.json',
    'Tema 7 DERECHO FISCAL': 'assets/Tema 7 DERECHO FISCAL/Derecho fiscal.json',
    'Tema 8 ARMAS, EXPLOSIVOS, ARTÍCULOS PIROTÉCNICOS Y CARTUCHERÍA':
        'assets/Tema 8 ARMAS, EXPLOSIVOS, ARTÍCULOS PIROTÉCNICOS Y CARTUCHERÍA/reglamento de armas.json',
    'Tema 9 PATRIMONIO NATURAL Y BIODIVERSIDAD':
        'assets/Tema 9 PATRIMONIO NATURAL Y BIODIVERSIDAD/Patrimonio natural.json',
    'Tema 10 PROTECCIÓN INTEGRAL CONTRA LA VIOLENCIA DE GÉNERO Y ACTUACIÓN CON MENORES':
        'assets/Tema 10 PROTECCIÓN INTEGRAL CONTRA LA VIOLENCIA DE GÉNERO Y ACTUACIÓN CON MENORES/Genero y menores.json',
    'Tema 11 DERECHO PENAL':
        'assets/Tema 11 DERECHO PENAL/derecho penal.json',
    'Tema 12 PODER JUDICIAL':
        'assets/Tema 12 PODER JUDICIAL/poder judicial.json',
    'Tema 13 LEY DE ENJUICIAMIENTO CRIMINAL':
        'assets/Tema 13 LEY DE ENJUICIAMIENTO CRIMINAL/Ley enjuiciamiento criminal.json',
    'Tema 14 IGUALDAD EFECTIVA DE MUJERES Y HOMBRES':
        'assets/Tema 14 IGUALDAD EFECTIVA DE MUJERES Y HOMBRES/igualdad.json',
    'Tema 15 PROTECCION CIVIL':
        'assets/Tema 15 PROTECCION CIVIL/Proteccion Civil.json',
    'Tema 16 TECNOLOGIAS DE LA INFORMACION Y LA COMUNICACION':
        'assets/Tema 16 TECNOLOGIAS DE LA INFORMACION Y LA COMUNICACION/Tecnologias.json',
    'TEMA 17 TOPOGRAFIA': 'assets/TEMA 17 TOPOGRAFIA/Topografia.json',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temario Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Consultar resultados',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ResultsListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          String topic = topics.keys.elementAt(index);
          return Card(
            color: Colors.green[200],
            child: ListTile(
              title: Text(topic),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      topicJson: topics[topic]!,
                      topic: topic,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
