import 'package:flutter/material.dart';

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
  late TextEditingController imageController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle ?? '');
    imageController = TextEditingController(text: widget.initialImage ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTitle != null ? 'Editar Catálogo' : 'Novo Catálogo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: 'Título'),
          ),
          TextField(
            controller: imageController,
            decoration: InputDecoration(labelText: 'URL da Imagem'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final title = titleController.text.trim();
            final image = imageController.text.trim();
            if (title.isNotEmpty && image.isNotEmpty) {
              widget.onAdd(title, image);
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

