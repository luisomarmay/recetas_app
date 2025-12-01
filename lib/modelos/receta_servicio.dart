import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; // NUEVO
import 'package:image_picker/image_picker.dart';
import '../modelos/receta.dart';

class RecipeService {
  final _fire = FirebaseFirestore.instance;

  // se remplazo Firebase Storage por Cloudinary
  final _cloudinary = CloudinaryPublic(
    'dqowqwje1', // Cloud Name de Cloudinary
    'recetas_app', // Upload Preset (unsigned)
    cache: false,
  );

  // sube una imagen a Cloudinary y devuelve la URL
  Future<String> _uploadImage(
    // declara una función asíncrona que devolverá un String (la URL segura)
    XFile
    file, // parámetro: el archivo de imagen (XFile, por ejemplo de image_picker)
    String
    recipeId, // parámetro: id de la receta (se usa para identificar el archivo)
    String
    authorUid, // parámetro: uid del autor (se usa para la carpeta en Cloudinary)
  ) async {
    try {
      // inicia un bloque try para capturar errores durante la subida
      final bytes = await file
          .readAsBytes(); // lee todo el archivo como bytes (espera a que termine la lectura)

      // Subir a Cloudinary
      final response = await _cloudinary.uploadFile(
        // llama al SDK/cliente de Cloudinary para subir el archivo y espera la respuesta
        CloudinaryFile.fromBytesData(
          // crea un objeto CloudinaryFile usando los bytes
          bytes, // los bytes del archivo que se van a subir
          identifier: '${recipeId}_${DateTime.now().millisecondsSinceEpoch}',
          // identificador único para el archivo (combina id de receta + timestamp)
          folder:
              'recetas/$authorUid', // carpeta en Cloudinary donde se guardará la imagen (organiza por autor)
        ),
      );

      return response
          .secureUrl; // devuelve la URL segura (https) que Cloudinary retorna para la imagen
    } catch (e) {
      // si ocurre cualquier error en el try...
      throw Exception(
        'Error al subir imagen: $e',
      ); // lanza una excepción con un mensaje (propaga el error)
    }
  }

  // Guarda receta nueva (sube imágenes si vienen)
  Future<void> saveRecipe(Recipe recipe, List<XFile>? images) async {
    // función asíncrona que no devuelve valor (void): guarda la receta en Firestore
    final docRef = _fire.collection('recetas').doc(recipe.id);
    // crea una referencia al documento en la colección 'recetas' con id = recipe.id
    final List<String> imageUrls =
        []; // lista vacía para almacenar las URLs resultantes de las imágenes

    if (images != null && images.isNotEmpty) {
      // si se pasaron imágenes (no nulo y no vacío)...
      for (final img in images) {
        // recorre cada imagen en la lista
        final url = await _uploadImage(img, recipe.id, recipe.authorUid);
        // sube la imagen llamando a _uploadImage y espera la URL resultante
        imageUrls.add(url); // agrega la URL devuelta a la lista imageUrls
      }
    }

    final data = {...recipe.toMap(), 'images': imageUrls};
    // crea el mapa de datos a guardar:
    // -toma el mapa que devuelve recipe.toMap()
    // -añade/actualiza la clave 'images' con la lista de URLs
    await docRef.set(
      data,
    ); /* escribe/guarda el mapa en Firestore en la referencia docRef 
          (await espera a que termine) */
  }
  /*_uploadImage: 

lee la imagen como bytes.
sube esos bytes a Cloudinary dentro de una carpeta recetas/<authorUid> y con un identificador único.
devuelve la secureUrl que Cloudinary retorna (URL pública de la imagen).
maneja errores con try/catch y relanza una excepción si algo falla.

saveRecipe:

crea la referencia al documento de la receta en Firestore (recetas/<recipe.id>).
si hay imágenes, las sube una por una usando _uploadImage (esperando cada subida) y recoge las URLs.
construye el Map final combinando los datos de la receta y la lista de URLs bajo la clave images.
guarda todo en Firestore con docRef.set(data). */

  // Actualiza receta
  Future<void> updateRecipe(
    Recipe recipe, {
    List<XFile>? newImages, // imagenes nuevas que el usuario quiere agregar
    List<String>?
    removeImageUrls, // URLs de imágenes que el usuario quiere eliminar
  }) async {
    /* la linea a continuacion crea una referencia al documento de firestore:
        -Colección: "recetas"
        -Documento: ID = recipe.id
        Esto no obtiene los datos todavía, solo apunta al documento. */
    final docRef = _fire.collection('recetas').doc(recipe.id);
    /* Obtiene los datos actuales del documento en Firestore.
        -await docRef.get() → trae el snapshot
        -.data() → obtiene el contenido (un Map)
        -?? {} → si la receta no existe, usa {} para evitar errores
        Esto te da la receta tal como está actualmente en Firebase. */
    final current = (await docRef.get()).data() ?? {};
    /* toma la lista de imágenes actuales guardadas en Firestore.
        -current['images'] → obtiene la propiedad "images" del documento
        -?? [] → si no existía la clave, crea una lista vacía
        -List<String>.from(...) → convierte el contenido en una lista de Strings

        Esto que garantiza por si te lo estas preguntando:
        -que no habrá error si la lista viene vacía
        -que siempre tendrás una lista modificable (List<String>)*/
    final List<String> currentImages = List<String>.from(
      current['images'] ?? [],
    );

    // Eliminar imágenes de Cloudinary
    if (removeImageUrls != null && removeImageUrls.isNotEmpty) {
      for (final url in removeImageUrls) {
        try {
          await _deleteImageByUrl(url);
          currentImages.remove(url);
        } catch (_) {}
      }
    }

    // Subir nuevas imágenes
    if (newImages != null && newImages.isNotEmpty) {
      for (final img in newImages) {
        final url = await _uploadImage(img, recipe.id, recipe.authorUid);
        currentImages.add(url);
      }
    }

    final updatedData = {...recipe.toMap(), 'images': currentImages};
    await docRef.update(updatedData);
  }

  // Eliminar imagen de Cloudinary
  Future<void> _deleteImageByUrl(String url) async {
    try {
      // Extraer public_id de la URL de Cloudinary
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      // URL típica: .../upload/v1234567890/recetas/uid/imagen.jpg
      // Necesitas el path después de /upload/vXXXXXX/
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex + 2 < segments.length) {
        final publicId = segments
            .sublist(uploadIndex + 2)
            .join('/')
            .split('.')
            .first;

        // cosilla importante 🗣️​🗣️​🗣️​🗣️​: Para eliminar en Cloudinary necesitas hacer una llamada API autenticada
        // por mi propia seguridad, lo ideal es hacerlo desde un Cloud Function
        // ahora solo quitamos la referencia en Firestore
        print('Imagen a eliminar: $publicId');
      }
    } catch (e) {
      print('Error al eliminar imagen: $e');
    }
  }
}
