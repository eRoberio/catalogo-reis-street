import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .get();

    // Agrupar itens por nome
    final Map<String, Map<String, dynamic>> groupedItems = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('name') ||
          !data.containsKey('price') ||
          !data.containsKey('quantity')) {
        continue; 
      }

      final itemName = data['name'];

      if (groupedItems.containsKey(itemName)) {
        // Já existe: soma quantidade e preço
        groupedItems[itemName]!['quantity'] += data['quantity'];
        groupedItems[itemName]!['totalPrice'] +=
            data['price'] * data['quantity'];
      } else {
        // Novo item
        groupedItems[itemName] = {
          'name': data['name'],
          'image': data['image'],
          'quantity': data['quantity'],
          'price': data['price'], // preço unitário
          'totalPrice': data['price'] * data['quantity'],
          'docIds': [doc.id], // salvar todos os docId relacionados
        };
      }
    }

    setState(() {
      cartItems = groupedItems.values.toList();
    });
  }

  Future<void> _removeFromCart(List<String> docIds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final docId in docIds) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(docId);
      batch.delete(docRef);
    }
    await batch.commit();

    _loadCartItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Carrinho de Compras',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body:
          cartItems.isEmpty
              ? Center(child: Text('Seu carrinho está vazio.'))
              : ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return ListTile(
                    leading: Image.network(
                      item['image'],
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(item['name']),
                    subtitle: Text(
                      'R\$ ${item['price'].toStringAsFixed(2)} x ${item['quantity']}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeFromCart(item['docIds']),
                    ),
                  );
                },
              ),
    );
  }
}
