import 'package:exam_score_collection_tool/pages/exams_page.dart';
import 'package:exam_score_collection_tool/pages/submit_page.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

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
