import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/pages/cloud_access_page.dart';

class OnlinePage extends StatelessWidget {
  const OnlinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            SizedBox(
              width: 560,
              height: 120,
              child: context.read<Settings>().isLightMode ? SvgPicture.asset('assets/lightLogo.svg') : SvgPicture.asset('assets/darkLogo.svg'),
            ),
            Text(
              'Access existing cloud storage:',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 15.0),
            ElevatedButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
              ),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CloudAccessPage(login: true))),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 2.5),
                child: Icon(
                  Icons.login,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        const SizedBox(height: 35),
        Column(
          children: [
            Text(
              'No cloud storage?',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CloudAccessPage(login: false),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  'Register a new storage',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}