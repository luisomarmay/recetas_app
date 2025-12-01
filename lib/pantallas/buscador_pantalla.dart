import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/pantallas/detalle_receta.dart'; // ← AJUSTA ESTE IMPORT

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = "";
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Buscar recetas")),
      body: Column(
        children: [
          // CAMPO DE TEXTO
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: "Escribe un nombre…",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: searchQuery.isEmpty
                  ? FirebaseFirestore.instance
                        .collection('recetas')
                        .where('authorUid', isEqualTo: uid)
                        .snapshots()
                  : FirebaseFirestore.instance
                        .collection('recetas')
                        .where('authorUid', isEqualTo: uid)
                        .where(
                          'title_lower',
                          isGreaterThanOrEqualTo: searchQuery.toLowerCase(),
                        )
                        .where(
                          'title_lower',
                          isLessThanOrEqualTo:
                              "${searchQuery.toLowerCase()}\uf8ff",
                        )
                        .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(child: Text("No se encontraron recetas"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      leading:
                          data['images'] != null &&
                              (data['images'] as List).isNotEmpty
                          ? Image.network(
                              data['images'][0],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.fastfood),
                      title: Text(data['title'] ?? ""),
                      subtitle: Text(data['category'] ?? ""),

                      // 👇 AQUÍ SE AGREGA la navegación
                      onTap: () {
                        final recetaCompleta = {...data, 'id': doc.id};

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RecipeDetailScreen(receta: recetaCompleta),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
