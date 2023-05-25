import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/implementation/account.dart';
import 'package:passwordmanager/pages/account_display_page.dart';

import '../../engine/local_database.dart';

class ListElement extends StatelessWidget {
  const ListElement({Key? key, required Account account, required this.parent})
      : _account = account,
        super(key: key);

  final State parent;
  final Account _account;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
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
              onPressed: () {
                //TODO
              },
              icon: Icon(
                Icons.copy,
                color: Theme.of(context).highlightColor,
              ),
            ),
            IconButton(
              onPressed: () {
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
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.fontSize,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: ElevatedButton(
                          onPressed: () {
                            parent.setState(() {
                              LocalDataBase().removeAccount(_account);
                            });
                            Navigator.pop(context);
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.red),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'DELETE',
                              style: TextStyle(
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.fontSize,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
              builder: (context) => AccountDisplay(account: _account),
            ),
          );
        },
      ),
    );
  }
}
