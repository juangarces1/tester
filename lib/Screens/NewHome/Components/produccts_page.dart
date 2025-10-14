import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/product_card.dart';

import 'package:tester/Models/product.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';


class ProductsPage extends StatefulWidget {
  final int index;
  const ProductsPage({super.key, required this.index});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  bool _showClear = false;
  bool _showToTop = false;
  String _query = '';
  List<Product> _all = [];
  List<Product> _filtered = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final facturaC = context.read<FacturasProvider>().getInvoiceByIndex(widget.index);
      final Response resp = await ApiHelper.getProducts(facturaC.cierre!.idzona);

      if (!mounted) return;

      if (!resp.isSuccess) {
        setState(() {
          _loading = false;
          _error = resp.message;
        });
        return;
      }

      final List<Product> items = List<Product>.from(resp.result);
      setState(() {
        _loading = false;
        _all = items;
        _filtered = items;
        _showClear = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels > 300 && !_showToTop) {
      setState(() => _showToTop = true);
    } else if (_scroll.position.pixels <= 300 && _showToTop) {
      setState(() => _showToTop = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      setState(() {
        _query = value.trim();
      });
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      setState(() {
        _filtered = _all;
        _showClear = false;
      });
      return;
    }
    final q = _query.toLowerCase();
    final filtered = _all.where((p) => p.detalle.toLowerCase().contains(q)).toList();
    setState(() {
      _filtered = filtered;
      _showClear = true;
    });
  }

  void _clearFilter() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _filtered = _all;
      _showClear = false;
    });
  }

  int _crossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1100) return 5;
    if (w >= 900) return 4;
    if (w >= 650) return 3;
    return 2;
    // sí, como pantalón ajustado: lo justo sin pasarse.
  }

  @override
  Widget build(BuildContext context) {
    final bg = Scaffold(
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _showToTop ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showToTop ? 1 : 0,
          child: FloatingActionButton(
            onPressed: () => _scroll.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic),
            backgroundColor: kBlueColorLogo,
            child: const Icon(Icons.arrow_upward),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // slate-900 → slate-800 vibes
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          color: kBlueColorLogo,
          onRefresh: _fetch,
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              _Header(
                searchCtrl: _searchCtrl,
                onChanged: _onSearchChanged,
                onClear: _clearFilter,
                showClear: _showClear,
                results: _filtered.length,
              ),
              if (_loading) _ShimmerGrid(count: 8, crossAxisCount: _crossAxisCount(context)),
              if (!_loading && _error != null) _ErrorState(message: _error!, onRetry: _fetch),
              if (!_loading && _error == null && _filtered.isEmpty) const _EmptyState(),
              if (!_loading && _error == null && _filtered.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _crossAxisCount(context),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = _filtered[index];
                        return _AnimatedItem(
                          key: ValueKey('prod_${p.codigoArticulo}_$index'),
                          child: ProductCard(product: p, index: widget.index),
                        );
                      },
                      childCount: _filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return SafeArea(child: bg);
  }
}

/// Encabezado con SliverAppBar + búsqueda “sticky”
class _Header extends StatelessWidget {
  final TextEditingController searchCtrl;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final bool showClear;
  final int results;

  const _Header({
    required this.searchCtrl,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    const double kLeadingWidth = 56; // espacio para el back button

    return SliverAppBar(
      pinned: true,
      expandedHeight: 96,
      elevation: 0,
      backgroundColor: Colors.transparent,
      // 1) TÍTULO PERSISTENTE (no más FlexibleSpaceBar.title)
      title: const Text(
        'Aceites & Otros',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      centerTitle: false,
      foregroundColor: Colors.white,          // texto/íconos blancos
      iconTheme: const IconThemeData(color: Colors.white),
      toolbarHeight: 48,

      // 2) Botón atrás con ancho reservado para que no pise el título
      leadingWidth: kLeadingWidth,
      leading: const Padding(
        padding: EdgeInsets.only(left: 12, top: 4),
        child: GlassBackButton(),             // tu botón “glass”
      ),

      // 3) Gradiente solo como fondo (sin título dentro)
      flexibleSpace: const FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      // 4) Search bar debajo; ajusto el translate para que no tape el título
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          transform: Matrix4.translationValues(0, 10, 0), // antes 12–18
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SearchBar(
            controller: searchCtrl,
            onChanged: onChanged,
            onClear: onClear,
            showClear: showClear,
            results: results,
          ),
        ),
      ),
    );
  }
}


/// Botón atrás con look “glass”, buen área táctil y sombra sutil.
class GlassBackButton extends StatelessWidget {
 
  const GlassBackButton({super.key,});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: InkWell(
         onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final bool showClear;
  final int results;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );

    return Material(
      elevation: 10,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), // slate-50
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Buscar producto',
                  border: InputBorder.none,
                ),
              ),
            ),
            if (showClear)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.close_rounded, color: Colors.black45),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            _ResultPill(count: results),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  final int count;
  const _ResultPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0), // slate-200
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Animación sutil para cada ítem del grid
class _AnimatedItem extends StatelessWidget {
  final Widget child;
  const _AnimatedItem({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, scale, _) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: scale == 1 ? 1 : 0.0 + (scale - 0.94) * 16, // empieza suave
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}

/// Grid shimmer sin dependencias (para el “Cargando…” guapo)
class _ShimmerGrid extends StatelessWidget {
  final int count;
  final int crossAxisCount;
  const _ShimmerGrid({required this.count, required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ShimmerCard(),
          childCount: count,
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _shimmerBox(height: 120, base: base, highlight: highlight),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _shimmerBox(height: 16, base: base, highlight: highlight),
                    const SizedBox(height: 8),
                    _shimmerBox(height: 14, base: base, highlight: highlight, widthFactor: 0.7),
                    const SizedBox(height: 16),
                    _shimmerBox(height: 20, base: base, highlight: highlight, widthFactor: 0.5),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({double height = 16, required Color base, required Color highlight, double widthFactor = 1}) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth * widthFactor;
        return Container(
          width: w,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1 + _c.value * 2, 0),
              end: Alignment(1 + _c.value * 2, 0),
              colors: [base, highlight, base],
              stops: const [0.1, 0.3, 0.6],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset("assets/empty-box.svg", width: 92, height: 92, color: Colors.white70, fit: BoxFit.contain),
            const SizedBox(height: 14),
            const Text(
              "Sin resultados",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              "Prueba con otro término de búsqueda",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 56),
              const SizedBox(height: 12),
              Text(
                "Ups…",
                style: TextStyle(color: Colors.white.withValues(alpha: .95), fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlueColorLogo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
