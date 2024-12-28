import 'dart:developer';
import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_to_pdf_converter/image_to_pdf_converter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: Scaffold(
        body: AppBody(),
      ),
    );
  }
}

class AppBody extends StatefulWidget {
  const AppBody({super.key});

  @override
  State<AppBody> createState() => _AppBodyState();
}

class _AppBodyState extends State<AppBody> {
  List<ImageData> data = [];
  int quality = 60;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => PreviewPhoto(
                                        imageProvider: MemoryImage(
                                            data[index].compressedFile))));
                              },
                              child: Image.memory(
                                data[index].compressedFile,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => PreviewPhoto(
                                        imageProvider: MemoryImage(
                                            data[index].originalFile))));
                              },
                              child: Image.memory(
                                data[index].originalFile,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                          '''Original size: ${data[index].originalFile.lengthInBytes / 1024} KB
Compressed size: ${data[index].compressedFile.lengthInBytes / 1024} KB
Compressed ratio: ${data[index].compressedFile.lengthInBytes / data[index].originalFile.lengthInBytes * 100}%'''),
                    ],
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Quality (1-100)',
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        quality = int.tryParse(value) ?? 60;
                      });
                    },
                  ),
                ),
                Expanded(child: SizedBox()),
                SizedBox(
                  height: 100,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                data.clear();
                              });
                            },
                            child: Icon(Icons.delete)),
                        FloatingActionButton.extended(
                          onPressed: () async {
                            print('Scan Document');
                            try {
                              List<String>? scanData =
                                  await CunningDocumentScanner.getPictures();
                              if (scanData == null) {
                                return;
                              }
                              print(scanData.runtimeType);
                              for (var img in scanData) {
                                log('img: $img');
                                var file = File(img);
                                //compress to 256kb
                                Uint8List result =
                                    await FlutterImageCompress.compressWithList(
                                        file.readAsBytesSync(),
                                        format: CompressFormat.jpeg,
                                        minHeight: 960,
                                        minWidth: 540,
                                        quality: quality);
                                setState(() {
                                  data.add(ImageData(
                                      file.readAsBytesSync(), result));
                                });
                                print(
                                    'Compressed size: ${(result.lengthInBytes / 1024).toStringAsFixed(2)} KB');
                                print(
                                    'Original size: ${(file.readAsBytesSync().lengthInBytes / 1024).toStringAsFixed(2)} KB');
                                print(
                                    'Compressed ratio: ${(result.lengthInBytes / file.readAsBytesSync().lengthInBytes * 100).round()}%');
                              }
                            } catch (e) {
                              if (kDebugMode) {
                                print(e);
                              }
                            }
                          },
                          label: Text('Scan Document'),
                        ),
                        FloatingActionButton(
                            onPressed: () async {
                              final Directory tempDir =
                                  await getTemporaryDirectory();
                              try {
                                List<File> files = [];
                                for (var img in data) {
                                  //File from original image uint8list
                                  var file = File(
                                      '${tempDir.path}/${DateTime.now().toIso8601String()}.jpg');
                                  file.create();
                                  await file.writeAsBytes(img.compressedFile);
                                  files.add(file);
                                }
                                final File result = await ImageToPdf.imageList(
                                    listOfFiles: files);
                                String? outputFile =
                                    await FilePicker.platform.saveFile(
                                  dialogTitle: 'Please select an output file:',
                                  fileName:
                                      '${DateTime.now().toIso8601String()}.pdf',
                                  initialDirectory:
                                      (await getDownloadsDirectory())?.path,
                                  allowedExtensions: ['pdf'],
                                  type: FileType.custom,
                                  bytes: result.readAsBytesSync(),
                                );

                                if (outputFile == null) {
                                  // User canceled the picker
                                }
                                // print(await checkAndRequestPermissions(
                                //     skipIfExists: false));
                                // if (await checkAndRequestPermissions(
                                //     skipIfExists: false)) {
                                //   for (var img in data) {
                                //     final result = await SaverGallery.saveImage(
                                //       img.originalFile,
                                //       fileName:
                                //           "${DateTime.now().toIso8601String()}.jpg",
                                //       androidRelativePath:
                                //           "Pictures/scanner/images",
                                //       skipIfExists: false,
                                //     );
                                //     print(result.toString());
                                //   }
                                // }
                              } catch (e) {
                                print(e);
                              }
                            },
                            child: Icon(Icons.compress)),
                        FloatingActionButton(
                            onPressed: () async {
                              final Directory tempDir =
                                  await getTemporaryDirectory();
                              try {
                                List<File> files = [];
                                for (var img in data) {
                                  //File from original image uint8list
                                  var file = File(
                                      '${tempDir.path}/${DateTime.now().toIso8601String()}.jpg');
                                  file.create();
                                  await file.writeAsBytes(img.originalFile);
                                  files.add(file);
                                }
                                final File result = await ImageToPdf.imageList(
                                    listOfFiles: files);
                                String? outputFile =
                                    await FilePicker.platform.saveFile(
                                  dialogTitle: 'Please select an output file:',
                                  fileName:
                                      '${DateTime.now().toIso8601String()}.pdf',
                                  initialDirectory:
                                      (await getDownloadsDirectory())?.path,
                                  allowedExtensions: ['pdf'],
                                  type: FileType.custom,
                                  bytes: result.readAsBytesSync(),
                                );

                                if (outputFile == null) {
                                  // User canceled the picker
                                }
                                // print(await checkAndRequestPermissions(
                                //     skipIfExists: false));
                                // if (await checkAndRequestPermissions(
                                //     skipIfExists: false)) {
                                //   for (var img in data) {
                                //     final result = await SaverGallery.saveImage(
                                //       img.originalFile,
                                //       fileName:
                                //           "${DateTime.now().toIso8601String()}.jpg",
                                //       androidRelativePath:
                                //           "Pictures/scanner/images",
                                //       skipIfExists: false,
                                //     );
                                //     print(result.toString());
                                //   }
                                // }
                              } catch (e) {
                                print(e);
                              }
                            },
                            child: Icon(Icons.save)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> checkAndRequestPermissions({required bool skipIfExists}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false; // Only Android and iOS platforms are supported
    }

    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      if (skipIfExists) {
        // Read permission is required to check if the file already exists
        return sdkInt >= 33
            ? await Permission.photos.request().isGranted
            : await Permission.storage.request().isGranted;
      } else {
        // No read permission required for Android SDK 29 and above
        return sdkInt >= 29
            ? true
            : await Permission.storage.request().isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS permission for saving images to the gallery
      print(await Permission.photosAddOnly.status);
      return skipIfExists
          ? await Permission.photos.request().isGranted
          : await Permission.photosAddOnly.request().isGranted;
    }

    return false; // Unsupported platforms
  }
}

class PreviewPhoto extends StatelessWidget {
  const PreviewPhoto({this.imageProvider, super.key});
  final ImageProvider<Object>? imageProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview'),
      ),
      body: Center(
          child: PhotoView(
        imageProvider: imageProvider,
      )),
    );
  }
}

class ImageData {
  final Uint8List originalFile;
  final Uint8List compressedFile;
  ImageData(this.originalFile, this.compressedFile);
}
