import 'dart:convert';

import 'package:demo_project/models/print_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ui' as ui;


class TestParaWidget extends StatelessWidget {
  const TestParaWidget({required this.printItem, super.key});

  final PrintItem printItem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(300, 200),
        painter: MyPainter(printItem),
      ),
    );
  }

  Future<String> convertToBase64() async {
    ByteData bytes = await rootBundle.load(printItem.imageAsset);
    var buffer = bytes.buffer;
    var m = base64.encode(Uint8List.view(buffer));
    return m;
  }
}

class MyPainter extends CustomPainter {
  const MyPainter(this.printItem);

  final PrintItem printItem;

  @override
  void paint(Canvas canvas, Size size) {
    // const text =
    //     'Hello, world.\nAnother line of text.\nA line of text that wraps around.';

    // draw the text
    final textStyle = ui.TextStyle(
      color: Colors.black,
      fontSize: 30,
    );
    final paragraphStyle = ui.ParagraphStyle(
      textDirection: TextDirection.ltr,
    );
    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(printItem.title)
      ..addPlaceholder(
        20,
        100,
        PlaceholderAlignment.middle,
      );
    const constraints = ui.ParagraphConstraints(width: 200);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(constraints);
    const offset = Offset(0, 0);
    canvas.drawParagraph(paragraph, offset);

    // draw a rectangle around the text
    const left = 0.0;
    const top = 0.0;
    final right = paragraph.width;
    // final right = paragraph.longestLine;
    // final right = paragraph.maxIntrinsicWidth;
    //final right = paragraph.minIntrinsicWidth;
    final bottom = paragraph.height;
    final rect = Rect.fromLTRB(left, top, right, bottom);
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
