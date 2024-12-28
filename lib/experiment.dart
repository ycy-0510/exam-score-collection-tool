import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:exam_score_collection_tool/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_to_pdf_converter/image_to_pdf_converter.dart';
import 'package:path_provider/path_provider.dart';

class ExperimentApp extends StatelessWidget {
  const ExperimentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: Scaffold(
        body: ExperimentAppBody(),
      ),
    );
  }
}

class ExperimentAppBody extends StatefulWidget {
  const ExperimentAppBody({super.key});

  @override
  State<ExperimentAppBody> createState() => _ExperimentAppBodyState();
}

class _ExperimentAppBodyState extends State<ExperimentAppBody> {
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
                          '''Original size: ${(data[index].originalFile.lengthInBytes / 1024).round()} KB
Compressed size: ${(data[index].compressedFile.lengthInBytes / 1024).round()} KB
Compressed ratio: ${(data[index].compressedFile.lengthInBytes / data[index].originalFile.lengthInBytes * 100).round()}%'''),
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
                            if (kDebugMode) {
                              print('Scan Document');
                            }
                            try {
                              List<String>? scanData =
                                  await CunningDocumentScanner.getPictures();
                              if (scanData == null) {
                                return;
                              }
                              for (var img in scanData) {
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
                                FilePicker.platform.saveFile(
                                  dialogTitle: 'Please select an output file:',
                                  fileName:
                                      '${DateTime.now().toIso8601String()}.pdf',
                                  initialDirectory:
                                      (await getDownloadsDirectory())?.path,
                                  allowedExtensions: ['pdf'],
                                  type: FileType.custom,
                                  bytes: result.readAsBytesSync(),
                                );
                              } catch (e) {
                                if (kDebugMode) {
                                  print(e);
                                }
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
}

class ImageData {
  final Uint8List originalFile;
  final Uint8List compressedFile;
  ImageData(this.originalFile, this.compressedFile);
}
