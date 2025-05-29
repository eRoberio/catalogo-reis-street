import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class AddProductDialog extends StatefulWidget {
  final String categoryId;

  AddProductDialog({required this.categoryId});

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
  
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _titleController = TextEditingController();
  final _imageController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _saveProduct() async {
    final title = _titleController.text.trim();
    final image = _imageController.text.trim();
    final priceText = _priceController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || image.isEmpty || priceText.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preço inválido')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('products').add({
      'title': title,
      'image': image,
      'price': price,
      'description': description,
      'categoryId': widget.categoryId,
      'createdAt': FieldValue.serverTimestamp(),
      'localCreatedAt': Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adicionar Produto'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _imageController,
              decoration: InputDecoration(labelText: 'URL da imagem'),
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Preço'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Salvar'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          onPressed: _saveProduct,
        ),
      ],
    );
  }
}
