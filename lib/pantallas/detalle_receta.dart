import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> receta;

  const RecipeDetailScreen({super.key, required this.receta});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _modoEdicion = false;
  bool _guardando = false;

  // Controladores para edición
  late TextEditingController _tituloController;
  late TextEditingController _ingredientesController;
  late TextEditingController _pasosController;
  String? _categoriaSeleccionada;

  final List<String> _categorias = [
    'Desayuno',
    'Comida',
    'Cena',
    'Postres',
    'Bebidas',
  ];

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(
      text: widget.receta['title'] ?? '',
    );
    _categoriaSeleccionada = widget.receta['category'];

    // Convertir lista de ingredientes a texto
    final ingredientes = List<String>.from(widget.receta['ingredients'] ?? []);
    _ingredientesController = TextEditingController(
      text: ingredientes.join('\n'),
    );

    _pasosController = TextEditingController(
      text: widget.receta['steps'] ?? '',
    );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _ingredientesController.dispose();
    _pasosController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (_tituloController.text.trim().isEmpty ||
        _ingredientesController.text.trim().isEmpty ||
        _pasosController.text.trim().isEmpty ||
        _categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final recetaId = widget.receta['id'];

      final ingredientesList = _ingredientesController.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      await FirebaseFirestore.instance
          .collection('recetas')
          .doc(recetaId)
          .update({
            'title': _tituloController.text.trim(),
            'category': _categoriaSeleccionada,
            'ingredients': ingredientesList,
            'steps': _pasosController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Actualizar el mapa local para reflejar los cambios
      widget.receta['title'] = _tituloController.text.trim();
      widget.receta['category'] = _categoriaSeleccionada;
      widget.receta['ingredients'] = ingredientesList;
      widget.receta['steps'] = _pasosController.text.trim();

      setState(() => _modoEdicion = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receta actualizada correctamente ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = widget.receta['images'] ?? [];
    final ingredientes = List<String>.from(widget.receta['ingredients'] ?? []);
    final pasos = widget.receta['steps'] ?? '';
    final titulo = widget.receta['title'] ?? 'Sin título';
    final categoria = widget.receta['category'] ?? '';
    final fecha = (widget.receta['createdAt'] != null)
        ? widget.receta['createdAt'].toDate()
        : null;

    final recetaId = widget.receta['id'] ?? '';
    final authorUid = widget.receta['authorUid'] ?? '';
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final esAutor = authorUid == currentUserUid;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        title: Text(
          _modoEdicion ? "Editar receta" : "Detalles de la receta",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF5D4037),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (esAutor && !_modoEdicion)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              tooltip: 'Editar receta',
              onPressed: () {
                setState(() => _modoEdicion = true);
              },
            ),
          if (_modoEdicion)
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              tooltip: 'Cancelar',
              onPressed: () {
                setState(() {
                  _modoEdicion = false;
                  // Restaurar valores originales
                  _tituloController.text = widget.receta['title'] ?? '';
                  _categoriaSeleccionada = widget.receta['category'];
                  final ingredientes = List<String>.from(
                    widget.receta['ingredients'] ?? [],
                  );
                  _ingredientesController.text = ingredientes.join('\n');
                  _pasosController.text = widget.receta['steps'] ?? '';
                });
              },
            ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO PRINCIPAL
            if (imagenes.isNotEmpty)
              Image.network(
                imagenes[0],
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 240,
                alignment: Alignment.center,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported, size: 60),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MODO VISTA
                  if (!_modoEdicion) ...[
                    // TÍTULO
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // CATEGORÍA
                    Text(
                      "Categoría: $categoria",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    // FECHA
                    if (fecha != null)
                      Text(
                        "Creado el: ${fecha.day}/${fecha.month}/${fecha.year}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                    const SizedBox(height: 20),

                    // INGREDIENTES
                    const Text(
                      "Ingredientes",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...ingredientes.map(
                      (ing) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8),
                            const SizedBox(width: 8),
                            Expanded(child: Text(ing)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // PASOS
                    const Text(
                      "Preparación",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      pasos,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ],

                  // MODO EDICIÓN
                  if (_modoEdicion) ...[
                    // TÍTULO
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título de la receta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CATEGORÍA
                    DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _categoriaSeleccionada = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // INGREDIENTES
                    TextField(
                      controller: _ingredientesController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Ingredientes (uno por línea)',
                        border: OutlineInputBorder(),
                        hintText: 'Ejemplo:\n2 huevos\n1 taza de harina\n...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PASOS
                    TextField(
                      controller: _pasosController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'Preparación',
                        border: OutlineInputBorder(),
                        hintText: 'Describe los pasos de preparación...',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // BOTÓN GUARDAR
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardarCambios,
                        icon: _guardando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _guardando ? 'Guardando...' : 'Guardar cambios',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
