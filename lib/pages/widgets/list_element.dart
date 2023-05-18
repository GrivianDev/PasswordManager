import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/pages/account_display_page.dart';

class ListElement extends StatelessWidget {
  const ListElement({Key? key, required this.account}) : super(key: key);

  final Account account;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: ElevatedButton(
        style: ButtonStyle(
          overlayColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
              return states.contains(MaterialState.hovered) ? Colors.blueAccent.shade100 : null;
            },
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          backgroundColor: MaterialStateProperty.all<Color>(Theme.of(context).primaryColor),
        ),
        child: Row(
          children: [
            Text(
              account.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
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
              builder: (context) => AccountDisplay(account: account),
            ),
          );
        },
      ),
    );
  }
}
