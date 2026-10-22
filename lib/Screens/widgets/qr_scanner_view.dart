import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerView extends StatefulWidget {
  final MobileScannerController controller;

  final void Function(BarcodeCapture) onDetect;

  const QrScannerView(
      {super.key, required this.controller, required this.onDetect});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  double _zoom = 0.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
              child: MobileScanner(
            controller: widget.controller,
            onDetect: widget.onDetect,
          )),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => widget.controller.toggleTorch(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: widget.controller,
                  builder: (context, state, child) {
                    return Icon(
                      state == TorchState.on
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color:
                          state == TorchState.on ? Colors.amber : Colors.white,
                      size: 22,
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.zoom_out_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: const Color(0xff0DC5B9),
                        inactiveTrackColor: Colors.white24,
                        thumbColor: const Color(0xff0DC5B9),
                      ),
                      child: Slider(
                        value: _zoom,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() {
                            _zoom = value;
                          });
                          widget.controller.setZoomScale(value);
                        },
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.zoom_in_rounded,
                    color: Colors.white,
                    size: 16,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
