import 'dart:io';
import 'package:flutter/material.dart';

// Para seleccionar imágenes de la galería
import 'package:image_picker/image_picker.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Model y Service
import '../modelos/receta.dart';
import '../modelos/receta_servicio.dart';

// ============================================================
// PANTALLA PARA AGREGAR UNA NUEVA RECETA
// ============================================================
class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

// Instancia única del servicio
final RecipeService _recipeService = RecipeService();

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  // Form key para validación
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _titleCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();

  // Categoría por defecto
  String _selectedCategory = 'Comida';

  // Lista de categorías
  final List<String> _categories = [
    'Desayuno',
    'Comida',
    'Cena',
    'Postres',
    'Bebidas',
  ];

  // ImagePicker
  final ImagePicker _picker = ImagePicker();

  // Lista de imágenes seleccionadas (puedes subir varias si quieres)
  List<XFile> _pickedImages = [];

  // ============================================================
  // SELECCIONAR IMAGEN DESDE GALERÍA
  // ============================================================
  Future<void> pickImage() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (img != null) {
      setState(() => _pickedImages.add(img));
    }
  }

  // ============================================================
  // GUARDAR RECETA USANDO RecipeService
  // ============================================================
  Future<void> saveRecipe() async {
    // Validar formulario primero
    if (!_formKey.currentState!.validate()) return;

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // UID del usuario
      final String uid = FirebaseAuth.instance.currentUser!.uid;

      // Crear un ID único para la receta
      final String recipeId = DateTime.now().millisecondsSinceEpoch.toString();

      // Crear objeto Recipe con tus campos
      final recipe = Recipe(
        id: recipeId,
        title: _titleCtrl.text.trim(),
        category: _selectedCategory,
        ingredients: _ingredientsCtrl.text
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList(),
        steps: _stepsCtrl.text.trim(),
        images: [], // las imágenes reales se añadirán en el service
        authorUid: uid,
        createdAt:
            DateTime.now(), // puedes dejar null si prefieres serverTimestamp
      );

      // Llamar al service para guardar (sube imagenes si las hay)
      await _recipeService.saveRecipe(recipe, _pickedImages);

      // Cerrar loader
      if (mounted) Navigator.pop(context);

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Receta guardada con éxito 🎉"),
            backgroundColor: Colors.green,
          ),
        );

        // Regresar al home indicando éxito
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Cerrar loader si hay error
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // WIDGET PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(title: const Text('Agregar receta')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey, // Form validado
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // TÍTULO
              // --------------------------------------------------
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingresa un título' : null,
              ),
              const SizedBox(height: 12),

              // --------------------------------------------------
              // CATEGORÍAS (Dropdown)
              // --------------------------------------------------
              DropdownButtonFormField(
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 12),

              // --------------------------------------------------
              // INGREDIENTES
              // --------------------------------------------------
              TextFormField(
                controller: _ingredientsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ingredientes (uno por línea)',
                ),
                maxLines: 6,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingresa ingredientes' : null,
              ),
              const SizedBox(height: 12),

              // --------------------------------------------------
              // PASOS / PREPARACIÓN
              // --------------------------------------------------
              TextFormField(
                controller: _stepsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pasos / Preparación',
                ),
                maxLines: 8,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingresa los pasos' : null,
              ),
              const SizedBox(height: 12),

              // --------------------------------------------------
              // BOTÓN PARA SELECCIONAR IMAGEN
              // --------------------------------------------------
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar foto'),
              ),

              // Mostrar miniaturas de imágenes seleccionadas
              if (_pickedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _pickedImages.map((img) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(img.path),
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Botón para borrar imagen
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _pickedImages.remove(img));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // BOTÓN PARA GUARDAR RECETA
              // --------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Guardar receta"),
                  onPressed: saveRecipe,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
