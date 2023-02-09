import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:demo_project/models/print_item.dart';
import 'package:demo_project/screens/print_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<PrintItem> _printItems = [
    PrintItem(title: 'Demo Text', imageAsset: 'assets/images/demotext.png'),
    PrintItem(title: 'Qr code', imageAsset: 'assets/images/qrcode.png'),
  ];

  int _selectedItemIndex = 0;

  @override
  void initState() {
    super.initState();
    requestAccess();
  }

  Future<void> requestAccess() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();
    // _storagePermissionGranted = await Permission.storage.request().isGranted;
    // _blePermissionGranted = await requestBLEAccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.separated(
          itemCount: _printItems.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return _listItem(
              title: _printItems[index].title,
              imageAsset: _printItems[index].imageAsset,
              isSelected: _selectedItemIndex == index,
              index: index,
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                // return PtChainPrintBluetoothPrintPage(title: 'Print');
                return PrintPage(
                  printItem: _printItems[_selectedItemIndex],
                );
              },
            ),
          );
        },
        child: const Icon(Icons.print),
      ),
    );
  }

  Widget _listItem({
    required String title,
    required String imageAsset,
    required int index,
    bool isSelected = false,
  }) {
    return ListTile(
      onTap: () {
        setState(() {
          _selectedItemIndex = index;
        });
      },
      leading: Icon(
        Icons.check_circle,
        color: isSelected ? Colors.blueAccent : Colors.grey,
      ),
      title: Text(
        title,
      ),
      trailing: Image.asset(imageAsset),
    );
  }
}
