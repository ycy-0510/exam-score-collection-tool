import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:exam_score_collection_tool/pages/photo_view_page.dart';
import 'package:exam_score_collection_tool/type.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toastification/toastification.dart';

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
                              String? output = await FilePicker.platform
                                  .saveFile(
                                      dialogTitle:
                                          'Please select an output file:',
                                      fileName:
                                          'exam_score_${widget.examId}.csv',
                                      initialDirectory: downloadDir,
                                      allowedExtensions: ['csv'],
                                      type: FileType.custom,
                                      bytes: csvFile.readAsBytesSync());
                              await csvFile.delete();
                              if (output != null) {
                                toastification.show(
                                  type: ToastificationType.success,
                                  style: ToastificationStyle.flatColored,
                                  title: Text('Exported successfully'),
                                  description: Text('File saved to $output'),
                                  autoCloseDuration: const Duration(seconds: 5),
                                  showProgressBar: false,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              }
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
                                scores[studentIdx].approved = false;
                                if (studentIdx < scores.length - 1) {
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
                                scores[studentIdx].approved = true;
                                if (studentIdx < scores.length - 1) {
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
