import 'package:flutter/material.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';


class DemoBottomAppBar extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const DemoBottomAppBar({
    this.fabLocation = FloatingActionButtonLocation.endDocked,
    this.shape = const CircularNotchedRectangle(),
    required this.total
  });

  final FloatingActionButtonLocation fabLocation;
  final NotchedShape? shape;
  final double total;

  static final List<FloatingActionButtonLocation> centerLocations = <FloatingActionButtonLocation>[
    FloatingActionButtonLocation.centerDocked,
    FloatingActionButtonLocation.centerFloat,
  ];

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: shape,
       color: kBlueColorLogo,
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Open navigation menu',
                icon: const Icon(Icons.menu),
                
                onPressed: () {},
              ),
              if (centerLocations.contains(fabLocation)) const Spacer(),
              const Text(
                'Total: ', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18
                ),              
              ),
              Text(
                 
                  VariosHelpers.formattedToCurrencyValue(total.toString()), 
                   style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18
                ),
                
              )
            ],
          ),
        ),
      ),
    );
  }
}