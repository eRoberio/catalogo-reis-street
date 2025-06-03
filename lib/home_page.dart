import 'package:catalogo_reinstreet/cart_page.dart';
import 'package:catalogo_reinstreet/product_list_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/widgets/add_catalog_dialog.dart' show AddCatalogDialog;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedCatalogId;
  String? selectedCatalogTitle;
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkOwner();
  }

  Future<void> _checkOwner() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(authUser.uid)
              .get();

      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        setState(() {
          isOwner = role != 'user';
        });
      } else {
        setState(() {
          isOwner = false;
        });
      }
    }
  }

  Future<void> _addCatalog(
    BuildContext context,
    String title,
    String image,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('catalogs').add({
        'title': title,
        'image': image,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Catálogo adicionado com sucesso!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao adicionar catálogo: $e")));
    }
  }

  Future<void> _editCatalog(
    BuildContext context,
    String id,
    String title,
    String image,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('catalogs').doc(id).update({
        'title': title,
        'image': image,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Catálogo atualizado com sucesso!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao atualizar catálogo: $e")));
    }
  }

  Future<void> _deleteCatalog(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Confirmar Exclusão"),
            content: Text("Tem certeza que deseja excluir este catálogo?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Excluir", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('catalogs')
            .doc(id)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Catálogo deletado com sucesso!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao deletar catálogo: $e")));
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 191, 191, 191),
      appBar: AppBar(
        title: Text('Catálogo', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 18, 18, 18),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartPage()),
                ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Image.asset(
                'assets/logo.png',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(
              height: 60,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('catalogs')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return SizedBox();
                  final catalogs = snapshot.data!.docs;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: catalogs.length,
                    itemBuilder: (context, index) {
                      final catalog = catalogs[index];
                      final title = catalog['title'];
                      final image = catalog['image'];
                      final docId = catalog.id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(
                              label: Text(title),
                              selected: selectedCatalogId == docId,
                              onSelected: (_) {
                                setState(() {
                                  selectedCatalogId = docId;
                                  selectedCatalogTitle = title;
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ProductListPage(
                                          catalogId: docId,
                                          catalogTitle: title,
                                        ),
                                  ),
                                );
                              },
                              shape: StadiumBorder(),
                              selectedColor: Colors.black,
                              backgroundColor: Colors.grey.shade300,
                              labelStyle: TextStyle(
                                color:
                                    selectedCatalogId == docId
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                            if (isOwner) ...[
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => AddCatalogDialog(
                                          onAdd:
                                              (newTitle, newImage) =>
                                                  _editCatalog(
                                                    context,
                                                    docId,
                                                    newTitle,
                                                    newImage,
                                                  ),
                                          initialTitle: title,
                                          initialImage: image,
                                        ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteCatalog(context, docId),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // SizedBox(
            //   height: 220,
            //   child: StreamBuilder<QuerySnapshot>(
            //     stream: FirebaseFirestore.instance
            //         .collection('products')
            //         .where('showCarrocel', isEqualTo: true)
            //         //.orderBy('createdAt', descending: true)  // Comentei por possível índice ausente, pode habilitar se índice existir
            //         .limit(10)
            //         .snapshots(),
            //     builder: (context, snapshot) {
            //       if (snapshot.hasError) {
            //         return Center(
            //           child: Text('Erro ao carregar produtos: ${snapshot.error}'),
            //         );
            //       }
            //       if (snapshot.connectionState == ConnectionState.waiting) {
            //         return Center(child: CircularProgressIndicator());
            //       }
            //       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            //         return Center(child: Text("Nenhum produto disponível."));
            //       }

            //       final products = snapshot.data!.docs;

            //       return ListView.builder(
            //         scrollDirection: Axis.horizontal,
            //         itemCount: products.length,
            //         itemBuilder: (context, index) {
            //           final productDoc = products[index];
            //           final data = productDoc.data() as Map<String, dynamic>;

            //           final title = data['title'] ?? 'Sem título';
            //           final image = data['image'] ?? '';
            //           final price = (data['price'] != null) ? data['price'].toDouble() : 0.0;

            //           return Container(
            //             width: 150,
            //             margin: EdgeInsets.all(8),
            //             decoration: BoxDecoration(
            //               color: Colors.white,
            //               borderRadius: BorderRadius.circular(16),
            //               boxShadow: [
            //                 BoxShadow(
            //                   color: Colors.black12,
            //                   blurRadius: 6,
            //                   offset: Offset(0, 2),
            //                 ),
            //               ],
            //             ),
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 ClipRRect(
            //                   borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            //                   child: image.isNotEmpty
            //                       ? Image.network(
            //                           image,
            //                           height: 100,
            //                           width: double.infinity,
            //                           fit: BoxFit.cover,
            //                         )
            //                       : Container(
            //                           height: 100,
            //                           width: double.infinity,
            //                           color: Colors.grey[300],
            //                           child: Icon(Icons.image, size: 40),
            //                         ),
            //                 ),
            //                 Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: Text(
            //                     title,
            //                     style: TextStyle(fontWeight: FontWeight.bold),
            //                     maxLines: 1,
            //                     overflow: TextOverflow.ellipsis,
            //                   ),
            //                 ),
            //                 Padding(
            //                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
            //                   child: Text(
            //                     "R\$ ${price.toStringAsFixed(2)}",
            //                     style: TextStyle(color: Colors.green),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           );
            //         },
            //       );
            //     },
            //   ),
            // ),
            SizedBox(
              height: 220,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('products')
                        .where('showCarrossel', isEqualTo: true)
                        .limit(10)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar produtos: ${snapshot.error}',
                      ),
                    );
                  }

                  final products = snapshot.data?.docs ?? [];

                  if (products.isEmpty) {
                    return Center(
                      child: Text("Nenhum produto disponível no carrossel."),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final productDoc = products[index];
                      final data = productDoc.data() as Map<String, dynamic>;

                      final title = data['title'] ?? 'Sem título';
                      final image = data['image'] ?? '';
                      final price =
                          (data['price'] != null)
                              ? double.tryParse(data['price'].toString()) ?? 0.0
                              : 0.0;

                      return Container(
                        width: 150,
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child:
                                  image.isNotEmpty
                                      ? Image.network(
                                        image,
                                        height: 100,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                      : Container(
                                        height: 100,
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.image, size: 40),
                                      ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                title,
                                style: TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                "R\$ ${price.toStringAsFixed(2)}",
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
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
      floatingActionButton:
          isOwner
              ? FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (_) => AddCatalogDialog(
                          onAdd:
                              (title, image) =>
                                  _addCatalog(context, title, image),
                        ),
                  );
                },
                child: Icon(Icons.add),
                backgroundColor: Colors.black,
              )
              : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'Usuário'),
            accountEmail: Text(user?.email ?? 'email@exemplo.com'),
            currentAccountPicture: CircleAvatar(
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child:
                  user?.photoURL == null
                      ? Icon(Icons.person, color: Colors.black)
                      : null,
            ),
            decoration: BoxDecoration(color: Colors.black),
          ),
          ListTile(title: Text('Início'), onTap: () => Navigator.pop(context)),
          ListTile(title: Text('Sair'), onTap: () => _logout(context)),
        ],
      ),
    );
  }
}
