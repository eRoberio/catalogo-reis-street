import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddCatalogDialog extends StatefulWidget {
  final Function(String, String) onAdd;
  final String? initialTitle;
  final String? initialImage;

  const AddCatalogDialog({
    required this.onAdd,
    this.initialTitle,
    this.initialImage,
    Key? key,
  }) : super(key: key);

  @override
  _AddCatalogDialogState createState() => _AddCatalogDialogState();
}

class _AddCatalogDialogState extends State<AddCatalogDialog> {
  late TextEditingController titleController;
  String? imageUrl;
  bool isUploading = false;

  final picker = ImagePicker();
  final imgbbApiKey = '960c92b32a7e7f97cc1141d774dde922'; // Substitua pela sua chave de API do imgbb

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle ?? '');
    imageUrl = widget.initialImage;
  }

  Future<void> pickImageAndUpload() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => isUploading = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
        body: {
          'image': base64Image,
        },
      );

      final data = jsonDecode(response.body);

      if (data is Map && data['success'] == true && data['data']?['url'] != null) {
        setState(() {
          imageUrl = data['data']['url'];
        });
      } else {
        throw Exception('Resposta inesperada da API');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar imagem: $e')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTitle != null ? 'Editar Catálogo' : 'Novo Catálogo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            isUploading
                ? CircularProgressIndicator()
                : imageUrl != null
                    ? Column(
                        children: [
                          Image.network(imageUrl!, height: 100),
                          TextButton(
                            onPressed: pickImageAndUpload,
                            child: Text('Trocar Imagem'),
                          ),
                        ],
                      )
                    : TextButton.icon(
                        icon: Icon(Icons.image),
                        label: Text('Selecionar Imagem'),
                        onPressed: pickImageAndUpload,
                      ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final title = titleController.text.trim();
            if (title.isNotEmpty && imageUrl != null && imageUrl!.isNotEmpty) {
              widget.onAdd(title, imageUrl!);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Preencha todos os campos')),
              );
            }
          },
          child: Text(widget.initialTitle != null ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}
