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
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();

      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        setState(() {
          isOwner = role != 'user';
        });
        print('Usuário: ${authUser.email} - Papel: $role - isOwner: $isOwner');
      } else {
        setState(() {
          isOwner = false;
        });
      }
    }
  }

  Future<void> _addCatalog(BuildContext context, String title, String image) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao adicionar catálogo: $e")),
      );
    }
  }

  Future<void> _editCatalog(BuildContext context, String id, String title, String image) async {
    try {
      await FirebaseFirestore.instance.collection('catalogs').doc(id).update({
        'title': title,
        'image': image,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Catálogo atualizado com sucesso!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao atualizar catálogo: $e")),
      );
    }
  }

  Future<void> _deleteCatalog(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
        await FirebaseFirestore.instance.collection('catalogs').doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Catálogo deletado com sucesso!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao deletar catálogo: $e")),
        );
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage())),
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
              child: Image.asset('assets/logo.png', height: 120, fit: BoxFit.contain),
            ),
            SizedBox(
              height: 60,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
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
                                    builder: (_) => ProductListPage(
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
                                color: selectedCatalogId == docId ? Colors.white : Colors.black,
                              ),
                            ),
                            if (isOwner) ...[
                              IconButton(
                                icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddCatalogDialog(
                                      onAdd: (newTitle, newImage) =>
                                          _editCatalog(context, docId, newTitle, newImage),
                                      initialTitle: title,
                                      initialImage: image,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 18, color: Colors.red),
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
           
           //CARROCEL DE PRODUTOS
           
           ],
        ),
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AddCatalogDialog(
                    onAdd: (title, image) => _addCatalog(context, title, image),
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
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? Icon(Icons.person, color: Colors.black) : null,
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
