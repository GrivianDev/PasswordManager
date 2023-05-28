import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/implementation/account.dart';
import 'package:passwordmanager/pages/account_display_page.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/persistance.dart';

class ListElement extends StatelessWidget {
  const ListElement(
      {Key? key, required Account account, bool isSearchResult = false})
      : _account = account,
        _isSearchResult = isSearchResult,
        super(key: key);

  final Account _account;
  final bool _isSearchResult;

  Future<void> _save(BuildContext context) async {
    try {
      if (!context.mounted) return;
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      await context.read<LocalDatabase>().save();
    } on ArgumentError catch (_) {
    } finally {
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        if (_isSearchResult) Navigator.pop(context);
      }
    }
  }

  void _copyClicked(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _account.password));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          'Copied password of "${_account.name}" to clipboard',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _deleteClicked(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Are you sure ?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        content: Text(
          'Are you sure that you want to delete all information about your "${_account.name}" account ?\nAction can not be undone!',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: ElevatedButton(
              onPressed: () {
                context.read<LocalDatabase>().removeAccount(_account);
                if (context.read<Settings>().isAutoSaving) {
                  _save(context);
                } else {
                  if (_isSearchResult) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                  }
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'DELETE',
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: ElevatedButton(
        style: ButtonStyle(
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              return states.contains(MaterialState.hovered)
                  ? Colors.blueAccent.shade100
                  : null;
            },
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          backgroundColor:
              MaterialStateProperty.all<Color>(Theme.of(context).primaryColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _account.name,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _copyClicked(context),
              icon: Icon(
                Icons.copy,
                color: Theme.of(context).highlightColor,
              ),
            ),
            IconButton(
              onPressed: () => _deleteClicked(context),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            ),
          ],
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccountDisplay(
                account: _account,
                accessedThroughSearch: _isSearchResult,
              ),
            ),
          );
        },
      ),
    );
  }
}
