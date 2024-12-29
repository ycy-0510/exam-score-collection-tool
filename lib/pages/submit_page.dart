import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:exam_score_collection_tool/pages/photo_view_page.dart';
import 'package:exam_score_collection_tool/widgets/loading_dialog.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:toastification/toastification.dart';

class SubmitScorePage extends StatelessWidget {
  const SubmitScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Score'),
      ),
      body: SubmitScoreBody(),
    );
  }
}

class SubmitScoreBody extends StatefulWidget {
  const SubmitScoreBody({super.key});

  @override
  State<SubmitScoreBody> createState() => _SubmitScoreBodyState();
}

class _SubmitScoreBodyState extends State<SubmitScoreBody> {
  Uint8List _imageBytes = Uint8List(0);
  bool _isAgree = false;
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();
  static const String examid = 'Y4LVjWo2mxLRV1nqls8X';
  @override
  void initState() {
    _studentIdController.text = 'Student${Random().nextInt(1000)}';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                Text(
                    'You can submit the score by scanning the answer sheet. Please make sure the answer sheet is clear and the answer sheet is not folded.'),
                TextField(
                  autofocus: false,
                  controller: _studentIdController,
                  decoration: InputDecoration(
                    labelText: 'Student ID',
                    hintText: 'Enter the student ID',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTapOutside: (event) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
                TextField(
                  autofocus: false,
                  controller: _scoreController,
                  decoration: InputDecoration(
                    labelText: 'Your Score',
                    hintText: 'Enter your score (1-100)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onTapOutside: (event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }, // auto close keyboard
                ),
                Builder(builder: (context) {
                  if (_imageBytes.isNotEmpty) {
                    return InkWell(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_imageBytes),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PreviewPhoto(
                                      imageProvider:
                                          MemoryImage(_imageBytes))));
                        });
                  } else {
                    return Icon(
                      Icons.photo,
                      size: 200,
                      color: Colors.grey,
                    );
                  }
                }),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    textStyle: TextStyle(fontSize: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      List<String>? scanData =
                          await CunningDocumentScanner.getPictures(
                              noOfPages: 1);
                      if (scanData == null) {
                        return;
                      }
                      var file = File(scanData[0]);
                      Uint8List result =
                          await FlutterImageCompress.compressWithList(
                              file.readAsBytesSync(),
                              format: CompressFormat.jpeg,
                              minHeight: 960,
                              minWidth: 540,
                              quality: 70);
                      setState(() {
                        _imageBytes = result;
                      });
                      if (kDebugMode) {
                        print(
                            'Compressed size: ${(result.lengthInBytes / 1024).toStringAsFixed(2)} KB');
                        print(
                            'Original size: ${(file.readAsBytesSync().lengthInBytes / 1024).toStringAsFixed(2)} KB');
                        print(
                            'Compressed ratio: ${(result.lengthInBytes / file.readAsBytesSync().lengthInBytes * 100).round()}%');
                      }
                    } catch (e) {
                      SnackBar(content: Text('Error: $e'));
                      if (kDebugMode) {
                        print(e);
                      }
                    }
                  },
                  icon: Icon(Icons.scanner, size: 25),
                  label: Text('Scan Answer Sheet'),
                ),
                CheckboxListTile(
                  value: _isAgree,
                  onChanged: (v) {
                    if (v == null) {
                      return;
                    }
                    setState(() {
                      _isAgree = v;
                    });
                  },
                  title: Text(
                      'I make sure the answer sheet is clear and not folded.'),
                ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_scoreController.text.isEmpty) {
                        toastification.show(
                          type: ToastificationType.warning,
                          style: ToastificationStyle.flatColored,
                          title: Text('Warning'),
                          description: Text('Please enter the score.'),
                          autoCloseDuration: const Duration(seconds: 3),
                          showProgressBar: false,
                        );
                        return;
                      }
                      if (int.tryParse(_scoreController.text) == null) {
                        toastification.show(
                          type: ToastificationType.warning,
                          style: ToastificationStyle.flatColored,
                          title: Text('Warning'),
                          description: Text('Please enter a valid score.'),
                          autoCloseDuration: const Duration(seconds: 3),
                          showProgressBar: false,
                        );
                        return;
                      }
                      if (_imageBytes.isEmpty) {
                        toastification.show(
                          type: ToastificationType.warning,
                          style: ToastificationStyle.flatColored,
                          title: Text('Warning'),
                          description: Text('Please scan the answer sheet.'),
                          autoCloseDuration: const Duration(seconds: 3),
                          showProgressBar: false,
                        );
                        return;
                      }
                      if (!_isAgree) {
                        toastification.show(
                          type: ToastificationType.warning,
                          style: ToastificationStyle.flatColored,
                          title: Text('Warning'),
                          description: Text(
                              'Please make sure the answer sheet is clear and not folded.'),
                          autoCloseDuration: const Duration(seconds: 3),
                          showProgressBar: false,
                        );
                        return;
                      }
                      if (int.parse(_scoreController.text) < 0 ||
                          int.parse(_scoreController.text) > 100) {
                        toastification.show(
                          type: ToastificationType.warning,
                          style: ToastificationStyle.flatColored,
                          title: Text('Warning'),
                          description:
                              Text('Please enter a score between 0-100.'),
                          autoCloseDuration: const Duration(seconds: 3),
                          showProgressBar: false,
                        );
                        return;
                      }
                      showDialog(
                          context: context,
                          builder: (contextIn) {
                            return AlertDialog(
                              title: Text('Submit Score'),
                              content: Text(
                                  'Are you sure you want to submit the score?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(contextIn);
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(contextIn);
                                    showLoadingDialog(context, 'Submitting');
                                    final db = FirebaseFirestore.instance;
                                    db
                                        .collection('/test/examscore/examData')
                                        .add({
                                      'examid': examid,
                                      'studentid': _studentIdController.text,
                                      'score': int.parse(_scoreController.text),
                                      'timestamp': FieldValue.serverTimestamp(),
                                    }).then((value) async {
                                      final storage = FirebaseStorage.instance;
                                      final ref = storage.ref(
                                          '/test/examscore/$examid/${value.id}.jpg');
                                      await ref.putData(
                                          _imageBytes,
                                          SettableMetadata(
                                            contentType: "image/jpeg",
                                          ));
                                      // Navigator.pop(context);
                                      if (context.mounted) {
                                        hideLoadingDialog(context);
                                      }
                                      toastification.show(
                                        type: ToastificationType.success,
                                        style: ToastificationStyle.flatColored,
                                        title: Text('Submitted successfully'),
                                        description: Text('Score submitted'),
                                        autoCloseDuration:
                                            const Duration(seconds: 5),
                                        showProgressBar: false,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    }).catchError((e) {
                                      if (kDebugMode) {
                                        print(e);
                                      }
                                      if (mounted) {
                                        // Navigator.pop(context);
                                        toastification.show(
                                          type: ToastificationType.error,
                                          style:
                                              ToastificationStyle.flatColored,
                                          title: Text('An error occurred'),
                                          description: Text('$e'),
                                          autoCloseDuration:
                                              const Duration(seconds: 5),
                                          showProgressBar: false,
                                        );
                                      }
                                    });
                                  },
                                  child: Text('Submit'),
                                ),
                              ],
                            );
                          });
                    },
                    style: ElevatedButton.styleFrom(
                        textStyle: TextStyle(fontSize: 20),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    iconAlignment: IconAlignment.end,
                    icon: Icon(
                      Icons.send,
                      size: 25,
                      color: Colors.white,
                    ),
                    label: Text('Submit Score'),
                  ),
                ),
                Text(
                    'Once you submit the score, you cannot change it. If the score you submitted is incorrect or the image is not clear, the score will be rejected. You have responsibility to submit the correct score.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
