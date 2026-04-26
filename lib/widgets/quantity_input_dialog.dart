
import 'package:flutter/material.dart';

class QuantityInputDialog extends StatefulWidget {
  final String giftName;
  final Function(int) onConfirm;

  const QuantityInputDialog({Key? key, required this.giftName, required this.onConfirm}) : super(key: key);

  @override
  _QuantityInputDialogState createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<QuantityInputDialog> {
  final _controller = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Send ${widget.giftName}'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Quantity',
          hintText: 'e.g., 10',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final quantity = int.tryParse(_controller.text) ?? 1;
            if (quantity > 0) {
              widget.onConfirm(quantity);
              Navigator.pop(context); // Close the dialog
            }
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}
