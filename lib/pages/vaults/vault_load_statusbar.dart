import 'package:flutter/material.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_provider.dart';
import 'package:provider/provider.dart';

class VaultStatusBar extends StatelessWidget {
  const VaultStatusBar({super.key});

  void _showErrors(BuildContext context, List errors) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(25),
            children: errors.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  spacing: 8,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    Expanded(
                      child: Text(
                        e.toString(),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final StorageProvider provider = context.watch();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 2),
        ),
      ),
      child: Row(
        children: [
          if (provider.isLoadingAny)
            Expanded(
              child: Row(
                spacing: 12,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Flexible(
                    child: Text(
                      'Loading...',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              spacing: 12,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    '${provider.allFiles.length} vaults',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                if (provider.errors.isNotEmpty)
                  InkWell(
                    onTap: () => _showErrors(context, provider.errors),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${provider.errors.length}',
                            style: Theme.of(context).textTheme.displaySmall!.copyWith(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
