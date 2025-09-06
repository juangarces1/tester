
import 'package:flutter/material.dart';
import 'package:tester/sizeconfig.dart';

//Nueva Paleta Fondo Oscuro

  const kNewbg = Color(0xFF0B0D10);
  const kNewsurface = Color(0xFF12151A);
  const kNewsurfaceHi = Color(0xFF171B22);
  const kNewborder = Color(0xFF2A3038);
  const kNewtextPri = Color(0xFFE8EDF2);
  const kNewtextSec = Color(0xFFB1B8C3);
  const kNewtextMut = Color(0xFF7C8696);
  const kNewred = Color(0xFFD64045);
  const kNewredPressed = Color(0xFFC1363A);
  const kNewgreen = Color(0xFF1BBF84);

const kRegularColor =  Color(0xFFec1c24);
const kSuperColor =Color(0xFFb634b8);
const kDieselColor =Color(0xFF1dbd4a);
const kExoColor =Color(0xFF00a8f3);
const kPrimaryColor = Color(0xFFFC0102);
const kPrimaryLightColor = Color(0xFFFFECDF);
const kTextColorBlack = Colors.black87;
const kTextColorWhite= Color.fromARGB(204, 236, 231, 231);
const kColorMenu= Color.fromARGB(251, 251, 245, 245);
const kGradientHome = LinearGradient(
  colors: [kPrimaryColor, kBlueColorLogo], // Colores del degradado
  begin: Alignment.topLeft,               // Dirección inicial
  end: Alignment.bottomRight,             // Dirección final
  stops: [0.0, 0.98],                      // Posiciones relativas de cada color (opcional)
  tileMode: TileMode.mirror,              // Comportamiento fuera de límites
  transform: GradientRotation(0.2),      // Rotación del degradado (opcional)
);

const kGradientHomeReverse = LinearGradient(colors: [kBlueColorLogo, kPrimaryColor ]);

const kPrimaryGradientColor = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFF7643), Color(0xFFFC0102)],
);
const kBlueGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color.fromARGB(255, 13, 35, 73), kBlueColorLogo],
);
const kYellowGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color.fromRGBO(255, 171, 64, 1), Colors.amber],
);

InputDecoration kDecorationModalMonto =   InputDecoration(

    labelStyle:  const TextStyle(                     // cuando el campo NO está enfocado
      color: Colors.white70,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle:  const TextStyle(             // cuando el label “flota” (focus)
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    floatingLabelBehavior: FloatingLabelBehavior.always,
   

    filled: true,
    fillColor: Colors.white10,
    contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

    enabledBorder: OutlineInputBorder(               // borde normal
      borderRadius: BorderRadius.circular(12),
      borderSide:  const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(               // borde al enfocar
      borderRadius: BorderRadius.circular(12),
      borderSide:  const BorderSide(
        color: Colors.greenAccent,
        width: 2,
      ),
    ),
  );

const kGreenGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color.fromARGB(255, 17, 50, 19),  Colors.green],
);

const kSecondaryColor = Color(0xFF979797);
const kTextColor = Color(0xFF757575);
const kBlueColorLogo =Color(0xFF175fb1);
const inActiveIconColor =  Color(0xFFB6B6B6);
const kColorFondoOscuro = Color.fromARGB(255, 70, 72, 77);
const kContrateFondoOscuro = Color.fromARGB(255, 232, 236, 240);
const kPrimaryText = Color(0xFFFF7643);

const kAnimationDuration = Duration(milliseconds: 200);

final myHeadingStyleBlack = TextStyle(
  fontSize: getProportionateScreenWidth(22),
  fontWeight: FontWeight.bold,
  color: Colors.black,
  height: 1.5,
);

final myHeadingStylePrymary = TextStyle(
  fontSize: getProportionateScreenWidth(22),
  fontWeight: FontWeight.bold,
  color: kPrimaryColor,
  height: 1.5,
);

final mySubHeadingStyleWhite = TextStyle(
  fontSize: getProportionateScreenWidth(20),
  fontWeight: FontWeight.bold,
  color: Colors.white,
  height: 1.5,
);

final mySubHeadingStyleBlacb = TextStyle(
  fontSize: getProportionateScreenWidth(18),
  fontWeight: FontWeight.bold,
  color: Colors.black,
  height: 1.5,
);

final myEnfasisBlack = TextStyle(
  fontSize: getProportionateScreenWidth(16),
  fontWeight: FontWeight.bold,
  color: Colors.black,
  height: 1.5,
);

final headingStyle = TextStyle(
  fontSize: getProportionateScreenWidth(28),
  fontWeight: FontWeight.bold,
  color: Colors.black,
  height: 1.5,
);

final headingStyleKprimary = TextStyle(
  fontSize: getProportionateScreenWidth(28),
  fontWeight: FontWeight.bold,
  color: kPrimaryColor,
  height: 1.5,
);

const defaultDuration = Duration(milliseconds: 250);

// Form Error
final RegExp emailValidatorRegExp =
    RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
const String kEmailNullError = "Please Enter your email";
const String kInvalidEmailError = "Please Enter Valid Email";
const String kPassNullError = "Please Enter your password";
const String kShortPassError = "Password is too short";
const String kMatchPassError = "Passwords don't match";
const String kNamelNullError = "Please Enter your name";
const String kPhoneNumberNullError = "Please Enter your phone number";
const String kAddressNullError = "Please Enter your address";

final otpInputDecoration = InputDecoration(
  contentPadding:
      const EdgeInsets.all(30),
  border: outlineInputBorderColor(),
  focusedBorder: outlineInputBorderColor(),
  enabledBorder: outlineInputBorderColor(),
);

OutlineInputBorder outlineInputBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(getProportionateScreenWidth(15)),
    borderSide: const BorderSide(color: kTextColor),
  );
}

OutlineInputBorder outlineInputBorderColor() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(getProportionateScreenWidth(15)),
    borderSide: const BorderSide(color: kPrimaryColor),
  );
}

OutlineInputBorder darkBorder({
  Color color = kNewborder,
  double width = 1.5,
  double radius = 10,
}) {
  return OutlineInputBorder(
    borderSide: BorderSide(color: color, width: width),
    borderRadius: BorderRadius.circular(radius),
  );
}

InputDecoration darkDecoration({
  String? label,
  String? hint,
  String? errorText,
  Widget? suffixIcon,
  Color fillColor = kNewsurfaceHi,
  EdgeInsetsGeometry contentPadding =
      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

  // Bordes opcionales (si no los pasas, usa defaults)
  InputBorder? enabledBorder,
  InputBorder? focusedBorder,
  InputBorder? errorBorder,
  InputBorder? focusedErrorBorder,
  TextStyle labelStyle = const TextStyle(color: kNewtextSec),
  TextStyle hintStyle  = const TextStyle(color: kNewtextMut),
}) {
  return InputDecoration(
    filled: true,
    fillColor: fillColor,
    labelText: label,
    labelStyle: labelStyle,
    hintText: hint,
    hintStyle: hintStyle,
    errorText: errorText,
    suffixIcon: suffixIcon,
    contentPadding: contentPadding,
    enabledBorder: enabledBorder ?? darkBorder(),
    focusedBorder: focusedBorder ?? darkBorder(color: kNewred, width: 1.8),
    errorBorder:   errorBorder   ?? darkBorder(color: kNewred, width: 1.8),
    focusedErrorBorder:
        focusedErrorBorder ?? darkBorder(color: kNewred, width: 1.8),
  );
}