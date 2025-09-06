import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/product_card.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/home/components/icon_btn_with_counter.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';
import 'package:provider/provider.dart';

class ProductsPage extends StatefulWidget {
  final int index;
  const ProductsPage({super.key, required this.index});


  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _showLoader =false;
  List<Product> products = [];
  String  _search ='';
  bool _showFilter =false;
 
  List<Product>  backup = [];
  @override
  void initState() {

    super.initState();
    _updateProducts();
  }


  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child: Scaffold(
        backgroundColor: kColorFondoOscuro,
        appBar:  MyCustomAppBar(
            title: 'Aceites & Otros',
            elevation: 6,
            shadowColor: kColorFondoOscuro,
            automaticallyImplyLeading: true,
            foreColor: Colors.white,
            backgroundColor: kBlueColorLogo,
            actions: <Widget>[
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipOval(child:  Image.asset(
                    'assets/splash.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),), // Ícono de perfil de usuario
              ),
            ],      
          ),
        body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10 , right: 20),
            child: Column( 
               children: [
                  SizedBox(height: getProportionateScreenWidth(20)),
                 searchBarCartIcon(context),
                 SizedBox(height: getProportionateScreenWidth(10)),
                 SizedBox(height: getProportionateScreenWidth(10)),
                  Expanded(  // Envuelve el GridView en un Expanded
                 child: RefreshIndicator(
                   onRefresh: () async {
                     _updateProducts();
                   },
                   child: GridView.builder(
                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                       crossAxisCount: 2, // Dos columnas
                       crossAxisSpacing: 10, // Espacio horizontal entre los elementos
                       mainAxisSpacing: 10, // Espacio vertical entre los elementos
                       childAspectRatio: 1 / 1.4, // Ajusta esta relación para modificar la altura
                     ),
                     itemCount: products.length,
                     itemBuilder: (context, index) {
                       return ProductCard(
                         product: products[index],
                         index: widget.index,
                       );
                     },
                   ),
                 ),
               ),
               ],
             ),
          ),
           _showLoader ? const LoaderComponent(loadingText: 'Cargando...',): Container(),
        ],
      ),
      ),
    );
}

  void _updateProducts() async {
    setState(() {
      _showLoader =true;
    });
    Invoice facturaC = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);

    Response response = await ApiHelper.getProducts(facturaC.cierre!.idzona);
   setState(() {
    
      _showLoader=false;
    });
  
    if (!response.isSuccess) {
        if (mounted) {       
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content:  Text(response.message),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Aceptar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }  
       return;
     }

   
    setState(() {
     products = response.result;
      backup=products;
    });
  }

Widget searchBarCartIcon(context){
return Padding(
    padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: SizeConfig.screenWidth * 0.6,
          decoration: BoxDecoration(
            color: kContrateFondoOscuro,
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            // ignore: avoid_print
            controller: TextEditingController(text: _search),
            onChanged: (value) => _search = value,
            decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(20),
                    vertical: getProportionateScreenWidth(9)),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                hintText: "Buscar Producto",
            ),
          ),
        ),
        const SizedBox(width: 10,),
        InkWell(            
          borderRadius: BorderRadius.circular(100),
          onTap: () => _filter(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(getProportionateScreenWidth(12)),
                height: getProportionateScreenWidth(46),
                width: getProportionateScreenWidth(46),
                decoration: const BoxDecoration(
                  color: kContrateFondoOscuro,
                  shape: BoxShape.circle,
                ),
                // ignore: deprecated_member_use
                child: SvgPicture.asset("assets/Search Icon.svg", color: kTextColorBlack,),
              ),
            ],
          ),
        ),
        const Spacer(),
        _showFilter ?  IconBtnWithCounter(
          svgSrc: "assets/filter-slash-svgrepo-com.svg",  
          numOfitem:  products.length,  
                  
          press: removeFilter,                     
            
        ) : Container(),
      ],
    ),
  );
 }

   void _filter() {
    if (_search.isEmpty) {      
      return;
    }
    
    
    List<Product> filteredList = [];
    for (Product product in products) {
      if (product.detalle.toLowerCase().contains(_search.toLowerCase())) {
        filteredList.add(product);
      }
    }

   

    setState(() {
      products = filteredList;  
     _showFilter = ! _showFilter;
      
    });   
  }

   removeFilter() {
     setState(() {
      _search = "";
      products = backup;  
     _showFilter = ! _showFilter;
      
    });  
  }

}