import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:exam_score_collection_tool/firebase_options.dart';
import 'package:exam_score_collection_tool/loading_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:toastification/toastification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Experiment',
        theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Exam Score Collection App Example'),
          ),
          body: MainBody(),
        ),
      ),
    );
  }
}

class MainBody extends StatefulWidget {
  const MainBody({super.key});

  @override
  State<MainBody> createState() => _MainBodyState();
}

class _MainBodyState extends State<MainBody> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              'This is an example app to demonstrate collecting exam scores by scanning the answer sheet. In production, the app will be used to collect the scores of the students and auto link the scores to the student info.'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: Colors.blue.shade50,
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.camera_alt),
                    title: Text('Submit Score'),
                    subtitle: Text('Submit score by Scanning the answer sheet'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubmitScorePage(),
                        ),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.view_list),
                    title: Text('View Score'),
                    subtitle: Text('View the score of the students'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewScorePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 100,
        )
      ],
    );
  }
}

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

class ViewScorePage extends StatelessWidget {
  const ViewScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Score'),
      ),
      body: ViewScoreBody(),
    );
  }
}

class ViewScoreBody extends StatefulWidget {
  const ViewScoreBody({super.key});

  @override
  State<ViewScoreBody> createState() => _ViewScoreBodyState();
}

class _ViewScoreBodyState extends State<ViewScoreBody> {
  bool loading = true;
  List<Exam> exams = [];

  @override
  void initState() {
    final db = FirebaseFirestore.instance;
    db.collection('/test/examscore/examIds').get().then((value) {
      exams = value.docs.map((e) => Exam(e.id, e['name'])).toList();
      loading = false;
      if (mounted) {
        setState(() {});
      }
    }).catchError((e) {
      if (kDebugMode) {
        print(e);
      }
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text('An error occurred'),
        description: Text('$e'),
        autoCloseDuration: const Duration(seconds: 5),
        showProgressBar: false,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              'You can select the exam, check the score of the students and export the score to a CSV file.'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
                color: Colors.blue.shade50,
                child: Builder(builder: (context) {
                  if (loading) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  }
                  return ListView.separated(
                    itemCount: exams.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.view_list),
                        title: Text(exams[index].name),
                        subtitle:
                            Text('View the score of ${exams[index].name} exam'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ScoreCheckPage(exams[index].id),
                            ),
                          );
                        },
                      );
                    },
                  );
                })),
          ),
        ),
        SizedBox(
          height: 100,
        )
      ],
    );
  }
}

class ScoreCheckPage extends StatelessWidget {
  const ScoreCheckPage(this.examId, {super.key});
  final String examId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Score'),
      ),
      body: ScoreCheckBody(examId),
    );
  }
}

class ScoreCheckBody extends StatefulWidget {
  const ScoreCheckBody(this.examId, {super.key});
  final String examId;

  @override
  State<ScoreCheckBody> createState() => _ScoreCheckBodyState();
}

class _ScoreCheckBodyState extends State<ScoreCheckBody> {
  bool loading = true;
  List<ScoreData> scores = [];
  List<File> images = [];
  int studentIdx = 0;
  bool allDone = false;

  @override
  void initState() {
    final db = FirebaseFirestore.instance;
    db
        .collection('/test/examscore/examData')
        .where('examid', isEqualTo: widget.examId)
        .get()
        .then((value) async {
      scores = value.docs
          .map((e) => ScoreData(e['studentid'], e['score'], false, e.id))
          .toList()
        ..sort((a, b) => a.studentId.compareTo(b.studentId));
      if (scores.isNotEmpty) {
        images = List.generate(scores.length, (index) => File(''));
      }
      for (int i = 0; i < min(scores.length, 2); i++) {
        final score = scores[i];
        final storage = FirebaseStorage.instance;
        final ref =
            storage.ref('/test/examscore/${widget.examId}/${score.id}.jpg');
        final url = await ref.getDownloadURL();
        images[i] = await DefaultCacheManager().getSingleFile(url);
        setState(() {});
      }
      loading = false;
      if (mounted) {
        setState(() {});
      }
    }).catchError((e) {
      if (kDebugMode) {
        print(e);
      }
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text('An error occurred'),
        description: Text('$e'),
        autoCloseDuration: const Duration(seconds: 5),
        showProgressBar: false,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
            'You have to check if the score is same as the the score on answer sheet. You can navigate to the next student score by clicking the next button.'),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(builder: (context) {
                  if (loading) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  }
                  if (allDone) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 150,
                            color: Colors.green,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text('All submitted scores are checked!',
                                style: TextStyle(fontSize: 20)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              List<List<dynamic>> listData = [
                                ['Student ID', 'Score']
                              ];
                              for (var score in scores) {
                                listData.add([
                                  score.studentId,
                                  score.approved ? score.score : '-'
                                ]);
                              }
                              String csv =
                                  ListToCsvConverter().convert(listData);
                              //csv file
                              String dir =
                                  (await getApplicationDocumentsDirectory())
                                      .path;
                              String downloadDir =
                                  (await getDownloadsDirectory())!.path;
                              File csvFile =
                                  File('$dir/exam_score_${widget.examId}.csv');
                              await csvFile.writeAsString(csv);
                              await FilePicker.platform.saveFile(
                                  dialogTitle: 'Please select an output file:',
                                  fileName: 'exam_score_${widget.examId}.csv',
                                  initialDirectory: downloadDir,
                                  allowedExtensions: ['csv'],
                                  type: FileType.custom,
                                  bytes: csvFile.readAsBytesSync());
                              await csvFile.delete();
                            },
                            icon: Icon(
                              Icons.download,
                              size: 20,
                            ),
                            label: Text('Export to CSV'),
                            style: ElevatedButton.styleFrom(
                                textStyle: TextStyle(fontSize: 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                          ),
                        ],
                      ),
                    );
                  }
                  if (scores.isEmpty) {
                    return Center(
                      child: Text('No data found'),
                    );
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Text(
                          '${scores[studentIdx].studentId} ${studentIdx + 1}/${scores.length}',
                          style: TextStyle(fontSize: 25)),
                      Text(
                        'Score: ${scores[studentIdx].score}',
                        style: TextStyle(fontSize: 40),
                      ),
                      Expanded(
                        child: Builder(builder: (context) {
                          if (images[studentIdx].path.isEmpty) {
                            return Icon(
                              Icons.photo,
                              size: 200,
                              color: Colors.grey,
                            );
                          }
                          return InkWell(
                              child: Image.file(images[studentIdx]),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => PreviewPhoto(
                                            imageProvider: FileImage(
                                                images[studentIdx]))));
                              });
                        }),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            height: 45,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (studentIdx < scores.length - 1) {
                                  scores[studentIdx].approved = false;
                                  setState(() {
                                    studentIdx++;
                                  });
                                  if (studentIdx < scores.length - 1) {
                                    final storage = FirebaseStorage.instance;
                                    final ref = storage.ref(
                                        '/test/examscore/${widget.examId}/${scores[studentIdx + 1].id}.jpg');
                                    final url = await ref.getDownloadURL();
                                    images[studentIdx + 1] =
                                        await DefaultCacheManager()
                                            .getSingleFile(url);
                                    setState(() {});
                                  }
                                } else {
                                  setState(() {
                                    allDone = true;
                                  });
                                }
                              },
                              icon: Icon(
                                Icons.close,
                                color: Colors.white,
                              ), //cross
                              label: Text('Decline'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                            ),
                          ),
                          SizedBox(
                            height: 45,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (studentIdx < scores.length - 1) {
                                  scores[studentIdx].approved = true;
                                  setState(() {
                                    studentIdx++;
                                  });
                                  if (studentIdx < scores.length - 1) {
                                    final storage = FirebaseStorage.instance;
                                    final ref = storage.ref(
                                        '/test/examscore/${widget.examId}/${scores[studentIdx + 1].id}.jpg');
                                    final url = await ref.getDownloadURL();

                                    images[studentIdx + 1] =
                                        await DefaultCacheManager()
                                            .getSingleFile(url);
                                    setState(() {});
                                  }
                                } else {
                                  setState(() {
                                    allDone = true;
                                  });
                                }
                              },
                              icon: Icon(
                                Icons.check,
                                color: Colors.white,
                              ), //check
                              label: Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              )),
        ),
      ),
    ]);
  }
}

class Exam {
  String id;
  String name;
  Exam(this.id, this.name);
}

class ScoreData {
  String studentId;
  int score;
  bool approved = false;
  String id;
  ScoreData(this.studentId, this.score, this.approved, this.id);
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
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        tightMode: true,
        imageProvider: imageProvider,
      )),
    );
  }
}
