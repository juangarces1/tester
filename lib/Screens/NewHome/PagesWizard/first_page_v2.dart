import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Screens/NewHome/Components/dispatch_card.dart';
import 'package:tester/Screens/NewHome/PagesWizard/faces_list_page.dart';
import 'package:tester/Providers/experimental/alt_despachos_provider.dart';
import 'package:tester/Providers/experimental/alt_dispatch_control.dart';

import 'package:tester/constans.dart';

class FirstPageV2 extends StatefulWidget {
  const FirstPageV2({super.key});

  @override
  State<FirstPageV2> createState() => _FirstPageV2State();
}

class _FirstPageV2State extends State<FirstPageV2> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Logic from V1 to ensure engine state
    });
  }

  bool _isVisible(AltDispatchControl d) {
    return d.stage == DispatchStage.authorizing ||
        d.stage == DispatchStage.authorized ||
        d.stage == DispatchStage.dispatching ||
        d.stage == DispatchStage.unpaid ||
        d.canRetry;
  }

  bool _canDelete(AltDispatchControl d) {
    return d.stage == DispatchStage.readyToAuthorize || d.canRetry;
  }

  @override
  Widget build(BuildContext context) {
    final despachosProv = Provider.of<AltDespachosProvider>(context);
    final all = despachosProv.despachos;
    final despachos = all.where(_isVisible).toList();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Items count:
    // 0: Action Hub (Hero Card)
    // 1: Section Header (if active dispatches exist)
    // 2+: Dispatches OR Empty State illustration
    final hasDispatches = despachos.isNotEmpty;
    // If we have dispatches, we need Hub + Header + N items.
    // If we don't, we need Hub + Empty State Widget.
    final itemCount = hasDispatches ? (2 + despachos.length) : 2;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF12151A), // kNewsurface style match
        body: ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 80 + bottomInset),
          itemCount: itemCount,
          separatorBuilder: (ctx, index) {
            // No separator after the hub if we have dispatches (Header takes care of spacing)
            if (index == 0) return const SizedBox(height: 24);
            return const SizedBox(height: 16);
          },
          itemBuilder: (ctx, index) {
            if (index == 0) {
              return _buildActionHub(context);
            }

            if (!hasDispatches) {
              // Index 1 in empty state is the "No Data" placeholder
              return _buildEmptyState();
            }

            if (index == 1) {
              return _buildSectionHeader(despachos.length);
            }

            // Real items start at index 2
            final dispatchIndex = index - 2;
            final d = despachos[dispatchIndex];
            return _buildDispatchItem(context, d);
          },
        ),
      ),
    );
  }

  Widget _buildActionHub(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: kGradientHome, // Using the Red/Blue gradient
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _startNewFlow(context),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Stack(
            children: [
              // 1. Background Large Icon (Watermark effect)
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.local_gas_station_rounded,
                  size: 180,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),

              // 2. Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nuevo Despacho",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Toca para configurar e iniciar",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          const Text(
            "Disposiciones Activas",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kNewborder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: kNewtextSec,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.dashboard_outlined,
                size: 60, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              "Sin actividad reciente",
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatchItem(BuildContext context, AltDispatchControl d) {
    return Dismissible(
      key: ObjectKey(d),
      direction:
          _canDelete(d) ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: kNewred.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kNewred.withOpacity(0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: kNewred),
            SizedBox(width: 8),
            Text('Eliminar',
                style: TextStyle(color: kNewred, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (dir) async {
        if (!_canDelete(d)) return false;
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: kNewsurface,
                title: const Text('Eliminar despacho',
                    style: TextStyle(color: Colors.white)),
                content: const Text(
                    '¿Seguro que quieres eliminar este despacho?',
                    style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(_, false),
                      child: const Text('Cancelar',
                          style: TextStyle(color: Colors.white54))),
                  TextButton(
                      onPressed: () => Navigator.pop(_, true),
                      child: const Text('Eliminar',
                          style: TextStyle(color: kNewred))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        final prov = Provider.of<AltDespachosProvider>(context, listen: false);
        prov.removeDispatch(d);
      },
      child: DispatchCard(d: d),
    );
  }

  Future<void> _startNewFlow(BuildContext ctx) async {
    final despachosProv = Provider.of<AltDespachosProvider>(ctx, listen: false);
    final dispatchId = DateTime.now().millisecondsSinceEpoch.toString();

    final dispatch = AltDispatchControl(
      id: dispatchId,
      onComplete: () {
        despachosProv.removeById(dispatchId);
      },
    );

    despachosProv.addDispatch(dispatch);

    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => FacesListPage(dispatchId: dispatch.id),
      ),
    );

    final keepStages = {
      DispatchStage.readyToAuthorize,
      DispatchStage.authorizing,
      DispatchStage.authorized,
      DispatchStage.dispatching,
      DispatchStage.completed,
      DispatchStage.unpaid,
    };

    if (!keepStages.contains(dispatch.stage)) {
      despachosProv.removeById(dispatch.id);
    }
  }
}
