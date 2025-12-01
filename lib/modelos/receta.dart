/*Nota: FieldValue y Timestamp vienen de cloud_firestore. 
Si pones este código en tu archivo, importa lo necesario: */
import 'package:cloud_firestore/cloud_firestore.dart';

/* los metodos que se usaron en el archivo receta_servicio. dart son todos de tipo recipe
    -saveRecipe(...)
    -updateRecipe(...)
    -_uploadImage(...)
    Usan objetos de tipo Recipe para guardar y actualizar recetas en firebase. */
class Recipe {
  // Datos que se guardaran en firebase
  final String id; // ID del documento en Firestore
  final String title; // título de la receta
  final String category; // categoría
  final List<String> ingredients; // lista de strings
  final String steps; // Pasos
  final List<String> images; // URLs en storage
  final String authorUid; //UID del creador en FirebaseAuth
  final DateTime? createdAt; //fecha de creación

  Recipe({
    //require significa que se deben pasar siiiiii o siii estos valores al crear la receta
    required this.id,
    required this.title,
    required this.category,
    required this.ingredients,
    required this.steps,
    required this.images,
    required this.authorUid,
    this.createdAt,
  });

  // convertir valores a toMap
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'title_lower': title.toLowerCase(),
      'category': category,
      'ingredients': ingredients,
      'steps': steps,
      'images': images,
      'authorUid': authorUid,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }
  /* porque Firebase no guarda objetos, solo guarda Map<String, dynamic>. este método convierte 
  la receta a un mapa que Firestore puede guardar. */

  factory Recipe.fromMap(Map<String, dynamic> map, String id) {
    return Recipe(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      steps: map['steps'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      authorUid: map['authorUid'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
