import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exam_score_collection_tool/pages/score_checking.dart';
import 'package:exam_score_collection_tool/type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

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
