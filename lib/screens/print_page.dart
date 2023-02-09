import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:another_brother/printer_info.dart' as pi;
import 'package:another_brother/printer_info.dart';
import 'package:another_brother/printer_info.dart';
import 'package:another_brother/type_b_printer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart';

import 'package:demo_project/models/print_item.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

class PrintPage extends StatefulWidget {
  final PrintItem printItem;

  const PrintPage({required this.printItem, Key? key}) : super(key: key);

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  List<BluetoothPrinter> printers = [];

  Printer printer = Printer();
  PrinterInfo printerInfo = PrinterInfo();
  bool printerSet = false;

  final printerModelName = Model.PT_P710BT;

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
    printerInfo.printerModel = Model.PT_P710BT;
    printerInfo.paperSize = PaperSize.CUSTOM;
    printerInfo.printMode = PrintMode.FIT_TO_PAGE;
    printerInfo.orientation = pi.Orientation.LANDSCAPE;
    // Disable cutting after every page
    printerInfo.isAutoCut = false;
    // Disable end cut.
    printerInfo.isCutAtEnd = true;
    // Allow for cutting mid page
    printerInfo.isHalfCut = false;
    printerInfo.port = Port.BLUETOOTH;
    // Set the label type.
   printerInfo.labelNameIndex = PT.ordinalFromID(PT.W24.getId());

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
    return FutureBuilder<List<BluetoothPrinter>>(
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

  Widget _printerTile({required List<BluetoothPrinter> printers, required BluetoothPrinter printer}) {
    return ListTile(
      onTap: () => _print(printers, printer,),
      leading: const Icon(Icons.print),
      title: Text(
        printer.modelName,
      ),
      subtitle: Text(printer.macAddress),
    );
  }

  Future<void> _print(List<BluetoothPrinter> printers, BluetoothPrinter selectedPrinter,) async {
    try {
      /// capture the widget image
      final bytes = await controller.capture();

      // Get the IP Address from the first printer found.
      printerInfo.macAddress = printers.single.macAddress;
      await printer.setPrinterInfo(printerInfo);

      ///Text Style
      TextStyle style =const TextStyle(
        color: Colors.black,
        fontSize: 24,
      );

      final para = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 14, ))..pushStyle(style.getTextStyle())..addText(widget.printItem.title);

      final p = para.build()..layout(const ui.ParagraphConstraints(width: 35));

      final status = await printer.printText(p);
      //final status = await printer.printImage(await bytesToImage(bytes!));
      print('Got Status : $status');
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
