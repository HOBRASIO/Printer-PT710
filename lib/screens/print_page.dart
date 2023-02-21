import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:another_brother/printer_info.dart' as pi;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:another_brother/label_info.dart';

import 'package:demo_project/models/print_item.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PrintPage extends StatefulWidget {
  final PrintItem printItem;

  const PrintPage({required this.printItem, Key? key}) : super(key: key);

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  List<pi.BluetoothPrinter> printers = [];

  pi.Printer printer = pi.Printer();
  pi.PrinterInfo printerInfo = pi.PrinterInfo();
  bool printerSet = false;

  final printerModelName = pi.Model.PT_P710BT;

  double fontSize = 20;
  double tapeLength = 35;
  double position = 150;

  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    try {
      initializePrinter();
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  Future<void> initializePrinter() async {
    printerInfo
      ..printerModel = pi.Model.PT_P710BT
      ..isAutoCut = true
      ..labelNameIndex = PT.ordinalFromID(PT.W12.getId())
      ..orientation = pi.Orientation.LANDSCAPE;
    // // Set the printer info so we can use the SDK to get the printers.
    // await printer.setPrinterInfo(printerInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        title: const Text('Select Printer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _body(),
            const Divider(),
            // printersList(),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              onPressed: () {
                setState(() {
                  position -= 5;
                });
              },
              child: const Icon(Icons.arrow_upward)),
          FloatingActionButton(
              onPressed: () {
                setState(() {
                  position += 5;
                });
              },
              child: const Icon(Icons.arrow_downward)),
          FloatingActionButton(
            onPressed: () {
              _print(context);
            },
            tooltip: 'Print',
            child: const Icon(Icons.print),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _body() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          children: [
            const Text(
              'Font Size',
              style: TextStyle(fontSize: 25),
            ),
            Slider(
              label: 'Font Size',
              value: fontSize,
              divisions: 40,
              min: 10,
              max: 50,
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  fontSize = value;
                });
              },
            ),
            const Text(
              'Tape Length',
              style: TextStyle(
                fontSize: 25,
              ),
            ),
            Slider(
              label: 'Tape length',
              value: tapeLength,
              divisions: 4,
              min: 35,
              max: 65,
              onChanged: (value) {
                setState(
                      () {
                    tapeLength = value;
                  },
                );
              },
            ),
            FutureBuilder(
              future: _getWidgetImage(),
              builder:
                  (BuildContext context, AsyncSnapshot<ByteData> snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(Uint8List.view(snapshot.data!.buffer));
                }

                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _print(BuildContext context) async {
    // Request Permissions if they have not been granted.
    // Note: If storage permission is not granted printing will fail
    // with ERROR_WRONG_LABEL
    if (!await Permission.storage.request().isGranted) {
      _showSnack(context, "Access to storage is needed in order print.",
          duration: const Duration(seconds: 2));
      return;
    }

    // TODO Replace this by the image generation method.
    ui.Image imageToPrint = await _generateImage(
      fontSize: fontSize,
      position: position,
      tapeLength: tapeLength,
    );

    // pi.Printer printer = pi.Printer();
    await printer.setPrinterInfo(printerInfo);
    pi.PrinterStatus status = await printer.printImage(imageToPrint);

    if (status.errorCode != pi.ErrorCode.ERROR_NONE) {
      // Show toast with error.
      _showSnack(context,
          "Print failed with error code: ${status.errorCode.getName()}",
          duration: const Duration(seconds: 2));
    }
  }

  void _showSnack(BuildContext context, String content,
      {Duration duration = const Duration(seconds: 1)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      content: Container(
        padding: const EdgeInsets.all(8.0),
        child: Text(content),
      ),
    ));
  }

  Future<ui.Image> _generateImage({
    required double fontSize,
    required double position,
    required double tapeLength,
  }) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);

    double labelWidthPx = tapeLength * 7.5;
    double labelHeightPx = 90;
    double qrSizePx = labelHeightPx;
    // Start Padding of the QR Code
    double qrPaddingStart = 30;
    // Start Padding of the Paragraph in relation to the QR Code
    double paraPaddingStart = 10;
    // Font Size for largest text
    double primaryFontSize = fontSize;

    Paint paint = Paint();
    paint.color = const Color.fromRGBO(255, 255, 255, 1);
    Rect bounds = Rect.fromLTWH(0, 0, labelWidthPx, labelHeightPx);
    canvas.save();
    canvas.drawRect(bounds, paint);

    // Create Paragraph
    ui.ParagraphBuilder paraBuilder =
    ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.start));
    // Add line
    paraBuilder.pushStyle(
        ui.TextStyle(fontSize: primaryFontSize, color: Colors.black));
    paraBuilder.addText(widget.printItem.title);
    Offset paraOffset = Offset(paraPaddingStart, position);
    ui.Paragraph infoPara = paraBuilder.build();
    // Layout the paragraph in the remaining space.
    infoPara.layout(ui.ParagraphConstraints(
        width: labelWidthPx - qrSizePx - qrPaddingStart - paraPaddingStart));
    // Draw paragraph on canvas.
    canvas.drawParagraph(infoPara, paraOffset);

    // TODO Create QR Code
    final qrImage = await QrPainter(
      dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square, color: Colors.black),
      eyeStyle:
      const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
      data: widget.printItem.title,
      version: QrVersions.auto,
      gapless: true,
    ).toImage(labelHeightPx);

    // Draw QR Code
    // Center the QR vertically with a 20 px padding on start
    Offset qrOffset =
    Offset(labelWidthPx - qrSizePx, (labelHeightPx - qrSizePx) / 2);
    canvas.drawImage(qrImage, qrOffset, paint);

    ///by default widthPx = 9 * 200, default lengthPx = 3 * 200

    ///Max 24 mm = 180 p
    ///1mm = 180/24 = 7.5
    ///12mm = 90

    ///35mm (269.5 according to above calculation)
    ///45mm (337.5)
    ///55mm (412.5)
    ///65mm (487.5)
    var picture = await recorder
        .endRecording()
        .toImage(labelWidthPx.toInt(), labelHeightPx.toInt());

    return picture;
  }

  Future<ByteData> _getWidgetImage() async {
    ui.Image generatedImage = await _generateImage(
        fontSize: fontSize, position: position, tapeLength: tapeLength);
    ByteData? bytes =
    await generatedImage.toByteData(format: ui.ImageByteFormat.png);
    return bytes!;
  }
}

///Properties to look for :
///1) Tape length
///2) Font size
///3) Tape width (9 mm may be)
///4) Text direction (Horizontal only)
///5) Label Alignment (Left)
