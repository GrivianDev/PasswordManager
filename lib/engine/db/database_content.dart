import 'package:passwordmanager/engine/account.dart';

final class DatabaseContent {
  final List<Account> accounts;

  DatabaseContent({required this.accounts});

  factory DatabaseContent.empty() => DatabaseContent(accounts: List.empty());
}