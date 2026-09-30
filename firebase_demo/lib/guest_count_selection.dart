import 'package:flutter/material.dart';
 
/// Lets the signed-in user pick how many people they're bringing
/// (including themselves), from 0 up to [max].
class GuestCountSelection extends StatelessWidget {
  const GuestCountSelection({
    super.key,
    required this.count,
    required this.onChanged,
    this.max = 20,
  });
 
  final int count;
  final void Function(int) onChanged;
  final int max;
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Text('How many are coming?'),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove),
            // A null onPressed disables the button, so you can't go below 0.
            onPressed: count > 0 ? () => onChanged(count - 1) : null,
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: count < max ? () => onChanged(count + 1) : null,
          ),
        ],
      ),
    );
  }
}
 