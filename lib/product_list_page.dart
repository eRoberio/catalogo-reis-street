import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'cart_page.dart'; // Importa a tela de carrinho

class ProductListPage extends StatelessWidget {
  final String catalogId;
  final String catalogTitle;

  ProductListPage({required this.catalogId, required this.catalogTitle});

  Future<void> _editProduct(BuildContext context, String productId) async {
    final nameController = TextEditingController();
    final imageController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();

    final productDoc =
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
    final productData = productDoc.data();

    if (productData != null) {
      nameController.text = productData['name'];
      imageController.text = productData['image'];
      priceController.text = productData['price'].toString();
      descController.text = productData['description'];
    }

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Editar Produto'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Nome'),
                  ),
                  TextField(
                    controller: imageController,
                    decoration: InputDecoration(labelText: 'URL da Imagem'),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Preço'),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(labelText: 'Descrição'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final image = imageController.text.trim();
                  final priceText = priceController.text.trim();
                  final desc = descController.text.trim();

                  double price = 0.0;
                  if (priceText.isNotEmpty) {
                    final parsedPrice = double.tryParse(
                      priceText.replaceAll(',', '.'),
                    );
                    if (parsedPrice != null) {
                      price = parsedPrice;
                    } else {
                      debugPrint('Erro: O preço não é válido');
                      return;
                    }
                  }

                  if (name.isNotEmpty && image.isNotEmpty && desc.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(productId)
                        .update({
                          'name': name,
                          'image': image,
                          'price': price,
                          'description': desc,
                        });
                    Navigator.pop(ctx);
                  }
                },
                child: Text('Salvar'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteProduct(BuildContext context, String productId) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Produto excluído com sucesso')));
  }

  Future<void> _addProduct(BuildContext context) async {
    final nameController = TextEditingController();
    final imageController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Novo Produto'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Nome'),
                  ),
                  TextField(
                    controller: imageController,
                    decoration: InputDecoration(labelText: 'URL da Imagem'),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Preço'),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(labelText: 'Descrição'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final image = imageController.text.trim();
                  final priceText = priceController.text.trim();
                  final desc = descController.text.trim();

                  double price = 0.0;
                  if (priceText.isNotEmpty) {
                    final parsedPrice = double.tryParse(
                      priceText.replaceAll(',', '.'),
                    );
                    if (parsedPrice != null) {
                      price = parsedPrice;
                    } else {
                      debugPrint('Erro: O preço não é válido');
                      return;
                    }
                  }

                  if (name.isNotEmpty && image.isNotEmpty && desc.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('products')
                        .add({
                          'name': name,
                          'image': image,
                          'price': price,
                          'description': desc,
                          'catalogId': catalogId,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                    Navigator.pop(ctx);
                  }
                },
                child: Text('Adicionar'),
              ),
            ],
          ),
    );
  }

  // Função para adicionar ao carrinho
  void _addToCart(BuildContext context, Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .add({
          'name': product['name'],
          'price': product['price'],
          'quantity': 1,
          'image': product['image'],
        });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} adicionado ao carrinho!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produtos de $catalogTitle', style: TextStyle(
  color: const Color.fromARGB(255, 255, 255, 255),
),

        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('products')
                .where('catalogId', isEqualTo: catalogId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nenhum produto encontrado.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _addProduct(context),
                    child: Text('Adicionar Produto'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final product = docs[index];
              final price = (product['price'] as num?)?.toDouble() ?? 0.0;

              return Dismissible(
                key: ValueKey(product.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteProduct(context, product.id);
                },
                child: ListTile(
                  leading: Image.network(
                    product['image'],
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(product['name']),
                  subtitle: Text(
                    'R\$ ${price.toStringAsFixed(2)}\n${product['description']}',
                  ),
                  isThreeLine: true,
                  onTap: () => _editProduct(context, product.id),
                  trailing: IconButton(
                    icon: Icon(Icons.add_shopping_cart),
                    onPressed: () {
                      // Adiciona o produto ao carrinho
                      final productData = {
                        'name': product['name'],
                        'price': product['price'],
                        'image': product['image'],
                        'quantity': 1,
                      };
                      _addToCart(context, productData);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addProduct(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.black,
      ),
    );
  }
}
