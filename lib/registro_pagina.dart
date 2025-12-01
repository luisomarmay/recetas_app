import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/inicio_pagina.dart';

/* -StatelessWidget
    Pantallas o widgets que NO cambian.
    Son inmutables.

  -StatefulWidget
    Pantallas que SÍ cambian (valores, loading, inputs, listas, peticiones).

  -Keys
  Identifican widgets únicos dentro de listas o UI dinámica.

  -Separación Widget/State
Porque Flutter reconstruye widgets constantemente.
El Estado necesita vivir en otro lugar para no perderse. */

// ----------- Pantalla de Registro ------------
/* Estás creando una clase llamada RegistroScreen.
Hereda de StatefulWidget, lo cual significa:

esta pantalla puede cambiar con el tiempo.
puede usar setState() para actualizar la UI.

se usa cuando:
-hay formularios
-inputs del usuario
-estados que cambian (loading, validaciones, etc.) */
class RegistroScreen extends StatefulWidget {
  /* const indica que este widget puede ser constante (optimiza el rendimiento).
  -{Key? key} es un parámetro opcional que puede recibir una llave única para identificar este widget en el árbol de widgets.
  -super(key: key) le pasa esa llave al constructor del StatefulWidget padre. */
  const RegistroScreen({Key? key}) : super(key: key);

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

/* En un StatefulWidget necesitas dos clases:
numero uan. La clase del widget → RegistroScreen
numero to. La clase del estado → _RegistroScreenState */
class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool passwordConfirmed() {
    return _passwordController.text.trim() ==
        _confirmPasswordController.text.trim();
  }

  Future<void> registrarUsuario() async {
    if (_formKey.currentState!.validate()) {
      if (!passwordConfirmed()) {
        _mostrarSnackBar("Las contraseñas no coinciden.");
        return;
      }

      try {
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        await guardarDatosUsuario(userCredential.user!.uid);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Registro exitoso 🎉')));
        }
      } on FirebaseAuthException catch (e) {
        _mostrarSnackBar(e.message ?? "Error al registrar.");
      } catch (e) {
        _mostrarSnackBar("Error desconocido: $e");
      }
    }
  }

  // future para guardar el usuario en la db
  Future<void> guardarDatosUsuario(String uid) async {
    await _db.collection('usuarios').doc(uid).set({
      'nombre': _nombreController.text.trim(),
      'email': _emailController.text.trim(),
      'fecha_creacion': Timestamp.now(),
    });
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(
                  Icons.person_add,
                  size: 100,
                  color: const Color(0xFF5D4037),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.isEmpty
                      ? "Ingresa tu nombre."
                      : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu correo.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Correo inválido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  validator: (value) => value != null && value.length >= 6
                      ? null
                      : 'Mínimo 6 caracteres.',
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "Confirma tu contraseña."
                      : null,
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: registrarUsuario,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Registrarme'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
