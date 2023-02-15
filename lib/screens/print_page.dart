import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:another_brother/printer_info.dart' as pi;
import 'package:demo_project/widget/test_para_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:another_brother/label_info.dart';

import 'package:demo_project/models/print_item.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

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

  WidgetsToImageController controller = WidgetsToImageController();
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
    printerInfo.printerModel = pi.Model.PT_P710BT;
    printerInfo.paperSize = pi.PaperSize.CUSTOM;
    printerInfo.printMode = pi.PrintMode.FIT_TO_PAGE;
    printerInfo.orientation = pi.Orientation.LANDSCAPE;
    // Disable cutting after every page
    printerInfo.isAutoCut = false;
    // Disable end cut.
    printerInfo.isCutAtEnd = true;
    // Allow for cutting mid page
    printerInfo.isHalfCut = false;
    printerInfo.port = pi.Port.BLUETOOTH;
    // Set the label type.
   printerInfo.labelNameIndex = PT.ordinalFromID(PT.W12.getId());

    double width = 12.0;
    double rightMargin = 0.0;
    double leftMargin = 0.0;
    double topMargin = 0.0;

    final Map<dynamic, dynamic> paperMap = {
      'printerModel' : pi.Model.PT_P710BT.toMap(),
      'paperKind' : pi.PaperKind.ROLL.toMap(),
      'unit': pi.Unit.Mm.toMap(),
      'tapeWidth': width,
    'tapeLength': 20.0,
    'rightMargin':rightMargin,
    'leftMargin':rightMargin,
    'topMargin':rightMargin,
    'bottomMargin':rightMargin,
    'labelPitch':rightMargin,
    'markPosition':rightMargin,
    'markHeight':rightMargin,
    };

    pi.CustomPaperInfo? customPaperInfo = pi.CustomPaperInfo.fromMap(paperMap);

    printerInfo.customPaperInfo = customPaperInfo;

    // Set the printer info so we can use the SDK to get the printers.
    await printer.setPrinterInfo(printerInfo);
    setState(() {
      printerSet = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        title: const Text('Select Printer'),
      ),
      body: printerSet
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            item(),
            TestParaWidget(printItem: widget.printItem,),
            const Divider(),
            printersList(),
          ],
        ),
      )
          : _loading(),
    );
  }

  Widget _loading() {
    return const Center(
      child: CupertinoActivityIndicator(
        animating: true,
      ),
    );
  }

  Widget printersList() {
    return FutureBuilder<List<pi.BluetoothPrinter>>(
      future: printer.getBluetoothPrinters([printerModelName.getName()]),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return _loading();

          case ConnectionState.done:
            {
              if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              } else {
                if (snapshot.data != null) {
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Device Found',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Visibility(
                            visible: snapshot.data!.isNotEmpty,
                            child: const Text(
                              'Tap on printer to print',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Divider(),
                          ListView.builder(
                            shrinkWrap: true,

                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return _printerTile(
                                printers: snapshot.data!,
                                  printer: snapshot.data![index]);
                            },
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  return const Center(
                    child: Text(
                      'Cannot fetch devices',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
              }
            }

          default:
            return _loading();
        }
      },
    );
  }

  Widget item() {
    return WidgetsToImage(
      controller: controller,
      child: ListTile(
        leading: Text(
          widget.printItem.title,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
        trailing: Image.asset(widget.printItem.imageAsset),
      ),
    );
  }

  Widget _printerTile({required List<pi.BluetoothPrinter> printers, required pi.BluetoothPrinter printer,}) {
    return ListTile(
      onTap: () => _print(printers, printer,),
      leading: const Icon(Icons.print),
      title: Text(
        printer.modelName,
      ),
      subtitle: Text(printer.macAddress),
    );
  }

  Future<void> _print(List<pi.BluetoothPrinter> printers, pi.BluetoothPrinter selectedPrinter,) async {
    try {
      /// capture the widget image
      //final bytes = await controller.capture();

      // Get the IP Address from the first printer found.
      printerInfo.macAddress = printers.single.macAddress;

      await printer.setPrinterInfo(printerInfo);

      ///Text Style
      ui.TextStyle style = ui.TextStyle(
        color: Colors.black,
        fontSize: 60,
      );

      final paragraphStyle = ui.ParagraphStyle(
        textDirection: TextDirection.ltr,
      );

      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(style)
        ..addText(widget.printItem.title);
        //..addPlaceholder(
          //20,
          //100,
          //PlaceholderAlignment.middle,
        //);
      ///paragraph constraints required, w/o it optimized out error
      const constraints = ui.ParagraphConstraints(width: 200);
      final paragraph = paragraphBuilder.build();
      paragraph.layout(constraints);
      ///Setting offset in negative doesn't help, as it clips of the initial characters of the text
      final status = await printer.printText(paragraph);

      ///Image port, this works good.
      //final bytes = await rootBundle.load(widget.printItem.imageAsset);
      //final imgStatus = await printer.printImage(await bytesToImage(bytes.buffer.asUint8List()));
      print('Got Status : $status');
      //print('Got Status : $imgStatus');
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: ${e.toString()}'),
        ),
      );
    }
  }

  Future<ui.Image> bytesToImage(Uint8List imgBytes) async {
    ui.Codec codec = await ui.instantiateImageCodec(imgBytes);
    ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }
}

///Properties to look for :
///1) Tape length
///2) Font size
///3) Tape width (9 mm may be)
///4) Text direction (Horizontal only)
///5) Label Alignment (Left)
