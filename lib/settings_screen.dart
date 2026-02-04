import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gccabo/auth/login_screen.dart';
import 'package:gccabo/theme_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  int totalQuestions = 0;
  String _userName = '';
  bool _loadingUserName = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _countTotalQuestions();
    _loadUserName();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String name = '';
        if (doc.exists && doc.data() != null) {
          name = doc['displayName'] ?? '';
        }
        if (name.isEmpty) {
          name = user.uid.length >= 6 ? user.uid.substring(user.uid.length - 6) : user.uid;
        }
        setState(() {
          _userName = name;
          _userNameController.text = name;
          _loadingUserName = false;
        });
      } catch (e) {
        debugPrint('Error loading user name: $e');
        setState(() => _loadingUserName = false);
      }
    }
  }

  Future<void> _saveUserName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || newName.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': newName,
        'uid': user.uid,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _userName = newName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre actualizado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar nombre: $e')),
      );
    }
  }

  Future<void> _countTotalQuestions() async {
    int count = 0;
    List<String> jsonPaths = [
      'assets/Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL/ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL.json',
      'assets/Tema 2 RÉGIMEN INTERIOR/Regimen interior.json',
      'assets/Tema 3 DEONTOLOGÍA PROFESIONAL/Deontologia profesional.json',
      'assets/Tema 4 DERECHOS HUMANOS/Derechos Humanos.json',
      'assets/Tema 5 DERECHO ADMINISTRATIVO/Derecho administrativo.json',
      'assets/Tema 6 PROTECCIÓN DE LA SEGURIDAD CIUDADANA/Seguridad ciudadana.json',
      'assets/Tema 7 DERECHO FISCAL/Derecho fiscal.json',
      'assets/Tema 8 ARMAS, EXPLOSIVOS, ARTÍCULOS PIROTÉCNICOS Y CARTUCHERÍA/reglamento de armas.json',
      'assets/Tema 9 PATRIMONIO NATURAL Y BIODIVERSIDAD/Patrimonio natural.json',
      'assets/Tema 10 PROTECCIÓN INTEGRAL CONTRA LA VIOLENCIA DE GÉNERO Y ACTUACIÓN CON MENORES/Genero y menores.json',
      'assets/Tema 11 DERECHO PENAL/derecho penal.json',
      'assets/Tema 12 PODER JUDICIAL/poder judicial.json',
      'assets/Tema 13 LEY DE ENJUICIAMIENTO CRIMINAL/Ley enjuiciamiento criminal.json',
      'assets/Tema 14 IGUALDAD EFECTIVA DE MUJERES Y HOMBRES/igualdad.json',
      'assets/Tema 15 PROTECCION CIVIL/Proteccion Civil.json',
      'assets/Tema 16 TECNOLOGIAS DE LA INFORMACION Y LA COMUNICACION/Tecnologias.json',
      'assets/TEMA 17 TOPOGRAFIA/Topografia.json',
    ];
    for (String path in jsonPaths) {
      try {
        String jsonString = await rootBundle.loadString(path);
        dynamic data = json.decode(jsonString);
        
        // data es [[{...}]], así que data[0] es [{...}]
        if (data is List && data.isNotEmpty) {
          dynamic firstElement = data[0];
          
          if (firstElement is List) {
            // Si es una lista de diccionarios
            for (var item in firstElement) {
              if (item is Map && item.containsKey('preguntas')) {
                count += (item['preguntas'] as List).length;
              }
            }
          } else if (firstElement is Map && firstElement.containsKey('preguntas')) {
            // Si es directamente un diccionario con preguntas
            count += (firstElement['preguntas'] as List).length;
          }
        }
      } catch (e) {
        debugPrint('Error cargando $path: $e');
      }
    }
    setState(() => totalQuestions = count);
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay usuario autenticado.')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _changingPassword = true);

    final current = _currentPasswordController.text.trim();
    final next = _newPasswordController.text.trim();

    try {
      // Reauthenticate
      final cred = EmailAuthProvider.credential(email: user.email!, password: current);
      await user.reauthenticateWithCredential(cred);

      // Update
      await user.updatePassword(next);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña cambiada con éxito')));

      // Clear fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Error: ${e.code}';
      if (e.code == 'wrong-password') msg = 'Contraseña actual incorrecta.';
      if (e.code == 'weak-password') msg = 'La nueva contraseña es demasiado débil.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cambiar contraseña: $e')));
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UID: ${FirebaseAuth.instance.currentUser?.uid ?? 'No disponible'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  if (_loadingUserName)
                    const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    Column(
                      children: [
                        TextField(
                          controller: _userNameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre de usuario',
                            hintText: (FirebaseAuth.instance.currentUser?.uid.length ?? 0) >= 6
                                ? 'ej: ${FirebaseAuth.instance.currentUser?.uid.substring((FirebaseAuth.instance.currentUser?.uid ?? '').length - 6)}'
                                : 'Ingresa tu nombre',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty && value != _userName) {
                              _saveUserName(value);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _userNameController.text.isNotEmpty && _userNameController.text != _userName
                              ? () => _saveUserName(_userNameController.text)
                              : null,
                          child: const Text('Guardar nombre'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text('Correo: ${FirebaseAuth.instance.currentUser?.email ?? 'No disponible'}'),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          decoration: InputDecoration(
                            labelText: 'Contraseña actual',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Introduce la contraseña actual' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Introduce la nueva contraseña';
                            if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Repite la nueva contraseña',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirma la nueva contraseña';
                            if (v != _newPasswordController.text) return 'Las contraseñas no coinciden';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _changingPassword ? null : _changePassword,
                          child: _changingPassword ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Cambiar contraseña'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text('Tema oscuro'),
            value: _darkMode,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(context).colorScheme.primary.withAlpha(102),
            inactiveThumbColor: isDark ? Colors.white : Colors.grey.shade700,
            inactiveTrackColor: isDark ? Colors.white24 : Colors.grey.shade300,
            onChanged: (v) async {
              setState(() => _darkMode = v);
              await _setPref('darkMode', v);
              // Update global theme notifier
              themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
            },
          ),

          const SizedBox(height: 20),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Creado por Moreausoft', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Diseñado especialmente para el Gua. Marrero.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Text('Total preguntas $totalQuestions', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}
