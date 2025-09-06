import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tester/constans.dart';
import 'package:tester/sizeconfig.dart';

class CustomAppBar extends StatelessWidget {
 
  final int index;
 
  // ignore: use_key_in_widget_constructors
  const CustomAppBar({
   
    required this.index,    
  
  });

  // AppBar().preferredSize.height provide us the height that appy on our app bar
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: kContrateFondoOscuro,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              SizedBox(
                height: getProportionateScreenWidth(40),
                width: getProportionateScreenWidth(40),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(60),
                    ),
                    
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => Navigator.of(context,rootNavigator: true).pop(context),
                  child: SvgPicture.asset(
                    "assets/Back ICon.svg",
                    height: 15,
                  ),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(20),),
              Text(
                "Detalle Producto",
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(18),
                  fontWeight: FontWeight.bold,
                  color:kPrimaryColor,
                )
              ),
             
              
            ],
          ),
        ),
      ),
    );
  }
}