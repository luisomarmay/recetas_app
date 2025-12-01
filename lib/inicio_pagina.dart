import 'package:flutter/material.dart';
import 'package:my_app/pantallas/agregar_receta_pantalla.dart';
import 'package:my_app/pantallas/buscador_pantalla.dart';
import 'package:my_app/pantallas/perfil_pantalla.dart';
import 'package:my_app/pantallas/detalle_receta.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/* StatefulWidget significa que esta pantalla puede cambiar 
su estado (actualizar datos en pantalla). Se usa cuando necesitas que la interfaz reaccione a cambios.*/
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Lista de categorías (nombre, icono y color)
  final List<Map<String, dynamic>> categorias = [
    {
      'nombre': 'Desayuno',
      'icono': Icons.free_breakfast,
      'color': Color(0xFF5D4037),
    },
    {'nombre': 'Comida', 'icono': Icons.lunch_dining, 'color': Colors.orange},
    {
      'nombre': 'Cena',
      'icono': Icons.nightlife,
      'color': Color.fromARGB(255, 106, 142, 35),
    },
    {'nombre': 'Postres', 'icono': Icons.cake, 'color': Colors.pink},
    {'nombre': 'Bebidas', 'icono': Icons.local_drink, 'color': Colors.cyan},
  ];

  int _selectedIndex = 0; // Tab seleccionado del menú inferior
  String categoriaSeleccionada = 'Desayuno'; // Categoría activa
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // ---------- Variables para borrar recetas -----------
  bool modoSeleccion =
      false; // esta variable siempre será falso: ¿Está en modo borrar?
  Set<String> recetasSeleccionadas =
      {}; // almacenará losIDs de recetas marcadas para borrar
  /* -categorias: Lista con datos de cada categoría (nombre, icono, color)
         -set: Es como una lista pero no permite duplicados (ideal para IDs) */

  @override
  Widget build(BuildContext context) {
    /* Un Scaffold en Flutter es el widget que provee la estructura básica de diseño visual según 
    las guías de Material Design. Es como el “armazón” sobre el cual se construye la interfaz de usuario de una 
    aplicación Flutter.

    - Incluye componentes estándar:
- AppBar → Barra superior de navegación.
- Drawer → Menú lateral deslizable.
- BottomNavigationBar → Barra de navegación inferior.
- FloatingActionButton → Botón flotante de acción rápida.
- SnackBar → Mensajes temporales en la parte inferior.
- BottomSheet → Paneles que aparecen desde abajo.
- Gestión automática del layout: Se encarga de colocar estos elementos en posiciones correctas dentro de la pantalla.
 */
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      /* El operador ? : es un if ternario: si modoSeleccion es true, muestra el AppBar rojo; si no, muestra null, osea nada. */
      appBar: modoSeleccion
          ? AppBar(
              backgroundColor: Colors.red,
              title: Text(
                '${recetasSeleccionadas.length} seleccionadas',
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    modoSeleccion = false;
                    recetasSeleccionadas.clear();
                  });
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: recetasSeleccionadas.isEmpty
                      ? null
                      : () => _borrarRecetasSeleccionadas(),
                ),
              ],
            )
          : null,
      /* - SafeArea es un widget de Flutter que ajusta automáticamente su contenido para que no quede oculto
          detrás de elementos del sistema operativo, como:
              - La barra de estado (status bar).
              - El notch (muesca en pantallas modernas).
              - La barra de navegación inferior.
              - Básicamente, asegura que tu contenido se muestre en un área segura y visible de la pantalla.
 */
      body: SafeArea(
        child: Column(
          children: [
            // Bienvenida con nombre del usuario
            /*  es un widget que sirve para definir un espacio con un ancho y/o alto específico dentro de la interfaz. Puede contener un hijo y forzar que tenga esas dimensiones, o simplemente actuar como un bloque vacío para generar separación entre otros widgets.

  Características principales
- Definir tamaño fijo: Permite establecer width (ancho) y height (alto).
- Espaciador: Si no tiene hijo, funciona como un espacio vacío en el layout.
- Forzar dimensiones del hijo: Si se le pasa un widget hijo, lo obliga a ajustarse a las medidas indicadas.
- Alternativa ligera a Container: Similar a un Container pero con menos propiedades, ideal para casos simples.
- Adaptabilidad:
- SizedBox.expand → ocupa todo el espacio disponible del padre.
- SizedBox.fromSize → crea el cuadro con un tamaño específico.

 */
            SizedBox(
              width: double.infinity,
              /* FutureBuilder espera datos asíncronos (de Firebase). 
              Mientras carga muestra un indicador, y cuando llega el dato, muestra el nombre. 
              Es un widget que construye su interfaz en función del 
              estado de un proceso asíncrono (un Future). Es decir, te permite mostrar diferentes 
              elementos en pantalla mientras esperas que se complete una operación, como cargar datos de 
              una API o leer un archivo local.

              la palabra child se refiere al hijo de un widget, es decir, el contenido que ese widget va a mostrar
              dentro de tí.
              */
              child: FutureBuilder(
                future: obtenerNombreUsuario(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Error al cargar usuario"),
                    );
                  }

                  final nombre = snapshot.data;

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Bienvenid@ $nombre a MiRecetario",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Lista horizontal de categorías
            SizedBox(
              height: 56,
              // ListView crea una lista horizontal con separacion entre los items
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                // Agrega padding lateral de 16 px a la izquierda y 16 px a la derecha.
                // Sirve para que el contenido no pegue al borde de la pantalla.
                padding: const EdgeInsets.symmetric(horizontal: 16),
                /* Indica cuántos elementos tendrá la lista.
                    -categorias es una lista.
                    -.length devuelve el total. */
                itemCount: categorias.length,
                /* Define el espacio entre cada elemento.
                    -_ y __ son nombres ignorados (no necesitas usar esos parámetros).
                    -SizedBox(width: 12) crea un espacio horizontal de 12 px entre ítems.
                    Es lo que separa las tarjetas de categoría. */
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                /*Obtiene la categoría actual usando su índice.Si categorias es una lista de mapas */
                itemBuilder: (context, index) {
                  final cat = categorias[index];
                  final nombre = cat['nombre'];
                  final icono = cat['icono'];
                  final color = cat['color'];
                  /* Revisa si esta categoría es la que está seleccionada actualmente.
                    -Si coincide → selected = true
                    -Si no → selected = false */
                  final selected = nombre == categoriaSeleccionada;

                  return ElevatedButton.icon(
                    onPressed: () {
                      setState(
                        () => categoriaSeleccionada = nombre,
                      ); // Actualiza UI
                      /* setState() le dice a Flutter: "algo cambió, vuelve a dibujar la pantalla". */
                    },
                    icon: Icon(
                      icono,
                      color: selected ? Colors.white : Colors.black,
                    ),
                    label: Text(nombre),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected ? color : Colors.white,
                      foregroundColor: selected ? Colors.white : Colors.black,
                      elevation: selected ? 2 : 0,
                    ),
                  );
                },
              ),
            ),

            // Muestra las recetas filtradas por categoría en tiempo real
            Expanded(
              // Ocupa todo el espacio vertical restante en el layout
              child: StreamBuilder<QuerySnapshot>(
                // Escucha cambios en Firestore en tiempo real
                stream: FirebaseFirestore.instance
                    .collection('recetas')
                    .where('category', isEqualTo: categoriaSeleccionada)
                    .where(
                      'authorUid',
                      isEqualTo: uid,
                    ) // ← FILTRO QUE TE FALTABA
                    .orderBy('createdAt', descending: true)
                    .snapshots(),

                builder: (context, snapshot) {
                  // Construye la UI según el estado del stream

                  // Si ocurre un error al obtener los datos
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          16,
                        ), // Agrega espacio alrededor del mensaje
                        child: Text(
                          'Error al cargar recetas: ${snapshot.error}', // Muestra el error
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  // Mientras los datos están cargando
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    ); // Muestra un spinner
                  }

                  // Si no hay datos o la colección está vacía
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay recetas en "$categoriaSeleccionada".', // Mensaje de lista vacía
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  // Guarda las recetas obtenidas
                  final recetas = snapshot.data!.docs;

                  // Construye la lista de recetas
                  return ListView.builder(
                    padding: const EdgeInsets.all(
                      12,
                    ), // Margen alrededor de la lista
                    itemCount: recetas.length, // Cantidad de recetas
                    itemBuilder: (context, index) {
                      final doc = recetas[index]; // Documento actual
                      final data =
                          doc.data()
                              as Map<
                                String,
                                dynamic
                              >; // Conversión del documento a mapa
                      final recetaId = doc.id; // ID de la receta
                      final isSelected = recetasSeleccionadas.contains(
                        recetaId,
                      ); // Revisa si está seleccionada

                      return Card(
                        // Contenedor visual con borde y elevación
                        elevation: 3, // Sombra ligera
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                        ), // Espacio arriba y abajo
                        color: isSelected
                            ? Colors.red.shade50
                            : null, // Fondo diferente si está seleccionada
                        child: ListTile(
                          // Item de lista con icono, título, subtítulo y acciones

                          // Ícono de la izquierda
                          leading:
                              modoSeleccion // Si estamos en modo selección...
                              ? Checkbox(
                                  // Muestra una casilla
                                  value: isSelected, // Estado del checkbox
                                  onChanged: (val) {
                                    // Cuando lo tocan
                                    setState(() {
                                      // Actualiza el estado
                                      if (val == true) {
                                        recetasSeleccionadas.add(
                                          recetaId,
                                        ); // Selecciona
                                      } else {
                                        recetasSeleccionadas.remove(
                                          recetaId,
                                        ); // Deselecciona
                                      }
                                    });
                                  },
                                )
                              : data['images'] != null && // Si hay imágenes
                                    data['images'] is List &&
                                    (data['images'] as List).isNotEmpty
                              ? Image.network(
                                  // Muestra la primera imagen
                                  (data['images'] as List)[0],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                ), // Si no hay, muestra ícono genérico

                          title: Text(
                            data['title'] ?? 'Sin título',
                          ), // Título de la receta
                          subtitle: Text(
                            data['category'] ?? '',
                          ), // Categoría de la receta
                          // Cuando se toca un elemento
                          onTap: () {
                            if (modoSeleccion) {
                              // Si estamos en modo selección
                              setState(() {
                                if (recetasSeleccionadas.contains(recetaId)) {
                                  recetasSeleccionadas.remove(
                                    recetaId,
                                  ); // Quita si ya estaba
                                } else {
                                  recetasSeleccionadas.add(
                                    recetaId,
                                  ); // Selecciona si no estaba
                                }
                              });
                            } else {
                              // Navegar al detalle de receta
                              final recetaConId = {
                                ...data,
                                'id': doc.id,
                              }; // Agrega el ID al mapa

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailScreen(
                                    receta: recetaConId,
                                  ), // Abre pantalla de detalle
                                ),
                              );
                            }
                          },

                          // Mantener presionado para activar modo selección
                          onLongPress: () {
                            if (!modoSeleccion) {
                              // Solo si no estamos ya en modo selección
                              setState(() {
                                modoSeleccion = true; // Activa modo selección
                                recetasSeleccionadas.add(
                                  recetaId,
                                ); // Selecciona primera receta
                              });
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      /* WIDGETS IMPORTANTES
  1. Expanded
Sirve para que un widget ocupe todo el espacio disponible dentro de una columna o fila. Se usa para listas o contenido que debe crecer:
“Lléname todo el espacio que queda aquí”

  2. StreamBuilder
Recibe un stream, por ejemplo de Firestore, y reconstruye la UI cada vez que los datos cambian en tiempo real.
Ejemplo:
alguien agrega una receta → aparece al instante
alguien borra una receta → desaparece al instante
Es para contenido que cambia automáticamente.

  3. ListTile
Un widget prediseñado que muestra:
icono a la izquierda (leading)
título
subtítulo
ícono a la derecha (trailing)
acciones como onTap y onLongPress
Ideal para listas como Configuración, Chats, Recetas, Productos, etc.

  4. Card
Un contenedor visual con:
sombra (elevation)
bordes redondeados
fondo opcional
Se usa para mostrar contenido destacado con buena presentación.
Le da estilo elegante a cada item de la lista. */

      // Botón flotante para activar modo borrado
      /* la condicion !modoSeleccion dice que:
          -si no esta activo el modoSleccion > muestra el boton
          -si esta activo > oculta el boton */
      floatingActionButton: !modoSeleccion
          ? FloatingActionButton(
              /* el onPressed dice que cuando tocas el FAB:
              - cambia el estado
              - activa modoSeleccion = true
              - vuelve a dibujar la pantalla */
              onPressed: () {
                setState(() => modoSeleccion = true);
              },
              backgroundColor: const Color.fromARGB(255, 155, 20, 11),
              child: Icon(Icons.delete_sweep, color: Colors.white),
            )
          : null,

      // Barra de navaegacion inferior
      bottomNavigationBar: BottomNavigationBar(
        /* _selectedIndex es un int que guarda qué botón está activo.
          Si está en 0 > la primera pestaña se marca seleccionada. */
        currentIndex: _selectedIndex,
        //detecta cuando el usuario apezca el boton
        /*idx es el índice del botón que tocó el usuario:
          -0 es primera opción
          -1 es segunda opción
          -2 es tercera opción*/
        onTap: (idx) {
          setState(() => _selectedIndex = idx);
          switch (idx) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                //MaterialPageRoute te dirige a la pagina
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRecipeScreen(),
                ),
              );
              break;
          }
        },
        selectedItemColor: const Color.fromARGB(224, 201, 101, 19),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Usuario'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Agregar'),
        ],
      ),
    );
  }

  /* un future es un tipo de dato de Dart que representa algo que va a completarse en el futuro (tarda tiempo).
  Es similar a una promesa en JavaScript. 
  Ese “algo” puede ser:
  una consulta a Firestore, leer un archivo, escribir datos, mostrar un diálogo, esperar 2 segundos, hacer una petición a internet, etc.
  Todas esas acciones no son instantáneas, por eso Dart usa Future.*/

  // Nueva funcion para borrar las recetas
  Future<void> _borrarRecetasSeleccionadas() async {
    /* confirmar será: true si toca "Eliminar", false si toca "Cancelar"
       o null si cierra el diálogo por fuera */
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('¿Eliminar ${recetasSeleccionadas.length} receta(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // Borrar cada receta seleccionada
      /* bucle for que recorre cada ID de receta dentro de recetasSeleccionadas.
          Para cada una: Accede a Firestore → colección recetas, busca el documento por ID
          y lo elimina

        Usa await → significa que espera a que se elimine un elemento antes de pasar al siguiente, 
        evitando errores de conexiones simultáneas. */
      for (final recetaId in recetasSeleccionadas) {
        await FirebaseFirestore.instance
            .collection('recetas')
            .doc(recetaId)
            .delete();
      }

      setState(() {
        modoSeleccion = false; // desactiva el modo selección.
        recetasSeleccionadas.clear(); // vacia la lista
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recetas eliminadas correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }
}

// future para obtener el nombre del usuario en la firebase que se usara en la firebase
Future<String> obtenerNombreUsuario() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final doc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(uid)
      .get();

  if (!doc.exists || !doc.data()!.containsKey('nombre')) {
    return "Usuario";
  }

  return doc['nombre'];
}
