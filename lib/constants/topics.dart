import 'package:flutter/material.dart';

class Topics {
  static const Map<String, String> items = {
    'Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL':
        'assets/Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL/ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL.json',
    'Tema 2 RÉGIMEN INTERIOR':
        'assets/Tema 2 RÉGIMEN INTERIOR/Regimen interior.json',
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

  static IconData getIcon(String topic) {
    final iconMap = {
      'Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL': Icons.gavel,
      'Tema 2 RÉGIMEN INTERIOR': Icons.rule,
      'Tema 3 DEONTOLOGÍA PROFESIONAL': Icons.psychology,
      'Tema 4 DERECHOS HUMANOS': Icons.volunteer_activism,
      'Tema 5 DERECHO ADMINISTRATIVO': Icons.description,
      'Tema 6 PROTECCIÓN DE LA SEGURIDAD CIUDADANA': Icons.security,
      'Tema 7 DERECHO FISCAL': Icons.attach_money,
      'Tema 8 ARMAS, EXPLOSIVOS, ARTÍCULOS PIROTÉCNICOS Y CARTUCHERÍA': Icons.precision_manufacturing,
      'Tema 9 PATRIMONIO NATURAL Y BIODIVERSIDAD': Icons.nature,
      'Tema 10 PROTECCIÓN INTEGRAL CONTRA LA VIOLENCIA DE GÉNERO Y ACTUACIÓN CON MENORES': Icons.child_care,
      'Tema 11 DERECHO PENAL': Icons.warning,
      'Tema 12 PODER JUDICIAL': Icons.balance,
      'Tema 13 LEY DE ENJUICIAMIENTO CRIMINAL': Icons.gavel_sharp,
      'Tema 14 IGUALDAD EFECTIVA DE MUJERES Y HOMBRES': Icons.diversity_2,
      'Tema 15 PROTECCION CIVIL': Icons.emergency,
      'Tema 16 TECNOLOGIAS DE LA INFORMACION Y LA COMUNICACION': Icons.computer,
      'TEMA 17 TOPOGRAFIA': Icons.terrain,
    };
    return iconMap[topic] ?? Icons.book;
  }
}
