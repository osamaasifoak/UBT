import 'package:UBT/constants/shared_preference_constants.dart';
import 'package:UBT/models/trend_model.dart';
import 'package:UBT/screens/components/alert_dialog.dart';
import 'package:UBT/screens/components/trend_cards.dart';
import 'package:UBT/screens/components/trend_cards_minutes.dart';
import 'package:UBT/screens/components/trend_cards_pace.dart';
import 'package:UBT/screens/components/trend_cards_score.dart';
import 'Circular_progress.dart';
import 'package:UBT/services/shared_preference.dart';
import 'package:UBT/states/progress_screen_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:UBT/constants/Colors.dart' as CustomColors;
import 'package:UBT/constants/pedometer_icons.dart' as CustomIcons;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:UBT/screens/progress_screens/progress_chart.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'dart:math';

import 'Circular_progress.dart';

class Userdata extends StatefulWidget {
  @override
  UserdataState createState() => UserdataState();
}

class UserdataState extends State<Userdata> {
  String userUID;
  Container userentry;
  String n;
  int goalSteps = 200;
  int totalSteps = 10000;

  //y axis
  List graphlists = [];
  // x axis
  List d = [];
  // var lists;
  // var d;
  int len;
  String minutes;
  double totalminuites;
  int totaldistance;
  double distance;
  double score;
  String monthnow;
  String userSelectedValue;
  String userSelectedYear = "2021";
  double s; //score
  // C for rounding score values
  int c;

  var abc;
  var valuesList, keysList;
  final uploadAuth = FirebaseAuth.instance.currentUser.uid;
  final databaseReference = FirebaseDatabase.instance.reference();
  // List<Map> lists = [];
  Item selectedUser;
  var providerProgressScreen;
  List<String> users = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  List<String> years = <String>[
    '2021',
    '2020',
  ];

  Query _ref;

  @override
  void initState() {
    super.initState();
    var trendProvider =
        Provider.of<ProgressScreenProvider>(context, listen: false);
    var date = new DateTime.now();
    // readData();
    providerProgressScreen =
        Provider.of<ProgressScreenProvider>(context, listen: false);
    SharedPreferenceServiceClass()
        .getStringInSF(SharedPreferencesConstant.scoreValue)
        .then((value) {
      if (value != null && providerProgressScreen.score == null) {
        providerProgressScreen.setScoreAndGoalToAchieve(double.parse(value));
      }
    });
    _ref = FirebaseDatabase.instance.reference().child(uploadAuth);
    databaseReference
      ..child(uploadAuth)
          .child(date.year.toString())
          .child(date.month.toString())
          .once()
          .then((DataSnapshot snapshot) {
        try {
          Map snapshotData = snapshot.value;
          final currentDate = DateTime.now();
          double distance_trend = 0.0;
          double score_trend = 0.0;
          double pace = 0.0;
          double totalMinutes = 0;
          snapshotData.forEach(
            (key, value) {
              var formatedDate = DateTime.parse(value["DateString"]);
              final forGettingDifference = DateTime(
                  formatedDate.year, formatedDate.month, formatedDate.day);
              final difference =
                  currentDate.difference(forGettingDifference).inDays;
              if (difference <= 6 && difference != 0) {
                distance_trend =
                    distance_trend + double.parse(value["Distance"].toString());
                score_trend =
                    score_trend + double.parse(value["Score"].toString());
                pace = pace + double.parse(value["Pace"].toString());
              }
              if (difference <= 7 && difference != 0) {
                totalMinutes =
                    totalMinutes + double.parse(value["Minutes"].toString());
              }
              if (difference == 0) {
                trendProvider.todayTrend.distance =
                    double.parse(value["Distance"].toString())
                        .toStringAsFixed(2);
                trendProvider.todayScore.score =
                    double.parse(value["Score"].toString()).toStringAsFixed(2);
                trendProvider.todayPace.pace =
                    double.parse(value["Pace"].toString()).toStringAsFixed(2);
                trendProvider.totalMinutes =
                    double.parse(value["Minutes"].toString())
                        .toStringAsFixed(2);
                print(totalMinutes);
              }
            },
          );
          trendProvider
              .setTrendDistance((distance_trend / 5).toStringAsFixed(2));
          trendProvider.setTrendScore((score_trend / 5).toStringAsFixed(2));
          trendProvider.setTrendPace((pace / 5).toStringAsFixed(2));
          trendProvider.setTotalMinutes((totalMinutes / 7).toStringAsFixed(0));
          // print(trendCard)
        } catch (_) {
          print(_);
          // date = ["0"];
          // score = [0];
          print(uploadAuth);
        }
      });
    var now = new DateTime.now();
    var formatter = new DateFormat('MM');
    monthnow = formatter.format(now);
    // print(monthnow);
  }

  createData1() {
    double percentmax, vo2;

    percentmax = (0.8 +
        0.1894393 * (exp(-0.012778 * totalminuites)) +
        0.2989558 * (exp(-0.1932605 * totalminuites)));

    vo2 = ((-4.60 +
            0.182258 *
                (totaldistance *

                    // (int.parse(totaldistance.toString()) *
                    1000 /
                    totalminuites)) +
        0.000104 * pow(totaldistance * 1000 / totalminuites, 2));

    setState(() {
      score = vo2 / percentmax;
    });

    providerProgressScreen.setScoreAndGoalToAchieve(score);
    // return score;
  }

  Widget onTab() {
    Picker(
      adapter: NumberPickerAdapter(data: <NumberPickerColumn>[
        const NumberPickerColumn(begin: 1, end: 42, suffix: Text(' Km')),
      ]),
      delimiter: <PickerDelimiter>[
        PickerDelimiter(
          child: Container(
            width: 30.0,
            alignment: Alignment.center,
            child: Icon(Icons.more_vert),
          ),
        )
      ],
      hideHeader: true,
      confirmText: 'Ok',
      confirmTextStyle:
          TextStyle(inherit: false, color: Colors.red, fontSize: 22),
      title: const Text('Select Distance'),
      selectedTextStyle: TextStyle(color: Colors.green),
      onConfirm: (Picker picker, List<int> value) {
        Duration hours1 = Duration(hours: picker.getSelectedValues()[0]);

        // You get your duration here
        Duration _duration = Duration(
          hours: picker.getSelectedValues()[0],
        );

        // String a = picker.getSelectedValues()[0].toString();
        totaldistance = num.parse(picker.getSelectedValues()[0].toString());
        providerProgressScreen.setTotalDistance(totaldistance);
      },
    ).showDialog(context);
  }

  Widget onTap() {
    Picker(
      adapter: NumberPickerAdapter(data: <NumberPickerColumn>[
        const NumberPickerColumn(begin: 0, end: 6, suffix: Text(' hours')),
        const NumberPickerColumn(
            begin: 0, end: 60, suffix: Text(' minutes'), jump: 0),
        const NumberPickerColumn(begin: 0, end: 60, suffix: Text(' Sec')),
      ]),
      delimiter: <PickerDelimiter>[
        PickerDelimiter(
          child: Container(
            // width: 30.0,
            alignment: Alignment.center,
            child: Icon(Icons.more_vert),
          ),
        )
      ],
      hideHeader: true,
      confirmText: 'OK',
      confirmTextStyle:
          TextStyle(inherit: false, color: Colors.red, fontSize: 22),
      title: const Text('Select Minutes'),
      selectedTextStyle: TextStyle(color: Colors.green),
      onConfirm: (Picker picker, List<int> value) {
        Duration hours1 = Duration(hours: picker.getSelectedValues()[0]);
        Duration minutes1 = Duration(minutes: picker.getSelectedValues()[1]);
        Duration seconds1 = Duration(seconds: picker.getSelectedValues()[2]);

        // // You get your duration here
        Duration _duration = Duration(
          hours: picker.getSelectedValues()[0],
          minutes: picker.getSelectedValues()[1],
        );
        int hoursnew = num.parse(hours1.toString().substring(0, 1)) * 60;

        int minutesnew = num.parse(minutes1.toString().substring(2, 4));
        // int secondsnew = num.parse(seconds1.toString().substring(5, 6)) ~/ 60;

        String timeForShow =
            "0${picker.getSelectedValues()[0]}:${picker.getSelectedValues()[1].toString().length > 1 ? picker.getSelectedValues()[1] : (0.toString() + picker.getSelectedValues()[1].toString())}:${picker.getSelectedValues()[2].toString().length > 1 ? picker.getSelectedValues()[2] : (0.toString() + picker.getSelectedValues()[2].toString())}";
        // int hoursnew =
        //     num.parse((picker.getSelectedValues()[1] * 60).toString());

        // int minutesnew = num.parse(picker.getSelectedValues()[1].toString());

        double seconds =
            num.parse((picker.getSelectedValues()[2] / 60).toStringAsFixed(2));

        setState(() {
          totalminuites = (hoursnew + minutesnew).toDouble() + seconds;
        });

        // totalminuites = (hoursnew + minutesnew + seconds).toDouble();

        providerProgressScreen.setTotalHourAndMinutes(timeForShow);
      },
    ).showDialog(context);
  }

  chart(String month) {
    final databaseReference = FirebaseDatabase.instance.reference();

    databaseReference
      ..child(uploadAuth)
          .child(userSelectedYear)
          .child(month)
          .once()
          .then((DataSnapshot snapshot) {
        var date = [];
        var score = [];
        try {
          Map snapshotData = snapshot.value;
          snapshotData.forEach((key, value) => {
                date.add(value["DateString"]
                    .substring(value["DateString"].length - 2)),
                score.add(value["Score"].truncate())
              });
        } catch (_) {
          date = ["0"];
          score = [0];
          print(uploadAuth);
        }

        setState(() {
          graphlists = date;
          keysList = score;
          d = score;
        });

        return InkWell(
            onTap: () {
              print(graphlists);
            },
            child: PointsLineChart(_createSampleData(d, graphlists)));
      });
  }

  List<charts.Series<LinearSales, int>> _createSampleData(date, score) {
    List<LinearSales> data = [];
    if (score.length != 0 && date.length != 0) {
      for (var i = 0; i < score.length; i++) {
        data.add(new LinearSales(
          int.parse(date[i].toString()),
          int.parse(score[i].toString()),
        ));
      }
    } else {
      data.add(new LinearSales(0, 0));
    }

    return [
      new charts.Series<LinearSales, int>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        fillColorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Dein Fortschritt'),
          centerTitle: true,
          backgroundColor: Colors.green,
        ),
        body: Container(
          height: double.infinity,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: DropdownButton(
                          hint: Text('Select year'),
                          value: userSelectedYear,
                          onChanged: (value) {
                            setState(
                              () {
                                userSelectedYear = value;
                              },
                            );
                          },
                          items: years.map((String year) {
                            return DropdownMenuItem<String>(
                              value: year,
                              // Row to Cloumn
                              child: Row(
                                children: <Widget>[
                                  Icon(Icons.calendar_today,
                                      color: Color(0xFF167F67)),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    year,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  //
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      _monthSelection(),
                      IconButton(
                        alignment: Alignment.topRight,
                        icon: Icon(Icons.info_outline),
                        color: Colors.green,
                        tooltip: 'Graph Info',
                        onPressed: () {
                          CustomAlertDialog.showDialogPopup(
                            context: context,
                            text:
                                'Mit deinem Zielwert kannst \nDu überprüfen, wie Du dich \n bezüglich einer \ngewünschten Leistung oder\n virtuellen Marke entwickelst \nund Du kannst dich für\n einzelne Aktivitäten \nherausfordern\n diese Marke zu erreichen.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Flexible(
                        child: Container(
                      width: 380,
                      height: 280,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.green)),
                      child: PointsLineChart(_createSampleData(
                        graphlists,
                        d,
                      )),
                    ))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.green)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ' Setze eine virtuelle Marke',
                                  style: TextStyle(
                                      height: 1.5,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24),
                                ),
                                IconButton(
                                  icon: Icon(Icons.info_outline),
                                  color: Colors.green,
                                  tooltip: 'More Info',
                                  onPressed: () {
                                    CustomAlertDialog.showDialogPopup(
                                        context: context,
                                        text:
                                            'Willst Du in absehbarer Zeit \n eine konkrete Strecke in einer \n bestimmten Zeit laufen?',
                                        text2:
                                            "Hast du kein konkretes Ziel eine \n bestimmte Zeit laufen zu \nwollen aber eine Idee über\n eine persönliche virtuelle\n Marke (Distanz / Zeit),\ndie Du ab und \nan herausfordern willst?");
                                  },
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Icon(
                                  Icons.trending_up,
                                  color: Colors.black,
                                  size: 36.0,
                                  semanticLabel:
                                      'Text to announce in accessibility modes',
                                ),
                                Icon(
                                  Icons.access_time,
                                  color: Colors.black,
                                  size: 36.0,
                                ),
                              ],
                            ),
                            Consumer<ProgressScreenProvider>(
                                builder: (context, consumer, childWidget) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Flexible(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: RaisedButton(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18.0),
                                        ),
                                        child: Text(
                                          consumer.totaldistance == null
                                              ? "Distanz auswählen"
                                                  .toUpperCase()
                                              : consumer.totaldistance
                                                      .toString() +
                                                  " Km",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.green,
                                          ),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            onTab();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: RaisedButton(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18.0),
                                        ),
                                        child: Text(
                                          consumer.totalHourWithMinutes == null
                                              ? "Zeit auswählen $totalminuites"
                                                  .toUpperCase()
                                              : consumer.totalHourWithMinutes,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.green,
                                          ),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            onTap();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                RaisedButton(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Consumer<ProgressScreenProvider>(
                                      builder:
                                          (context, consumer, childWidget) {
                                    return Row(
                                      children: [
                                        Text(
                                          consumer.score != null &&
                                                  consumer.score.isFinite
                                              ? "Score: ${consumer.score.toStringAsFixed(2)}"
                                                  .toUpperCase()
                                              : "Score berechnen",
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                  onPressed: () {
                                    createData1();
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.info_outline),
                                  color: Colors.green,
                                  tooltip: 'More Info',
                                  onPressed: () {
                                    CustomAlertDialog.showDialogPopup(
                                        context: context,
                                        text:
                                            'In Abhängigkeit von der Distanz \nund der Dauer variiert dein Score\n je Aktivität. Wenn Du eine gleiche\n Strecke in kürzerer Zeit läufst,\n steigt der Score. Zum Beispiel\n wäre der Score für 10 km\n in 55 Minuten 35,7 - für 10 km\n in 50 Minuten 40. ',
                                        text2:
                                            "Die Berechnung berücksichtigt aber auch, dass es für eine längere Strecke schwieriger ist die gleiche Pace zu laufen. Für 5 km in 27:30 Minuten (gleiche Pace wie 55 Minuten in 10 km) wäre der Score 34,2 - der Score steigt also um 1,5 Punkte, weil Du die Pace über einen längeren Zeitraum halten konntest.");
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Text(
                    //   ' Egal ob Du ein ambitioniertes Ziel verfolgst\n oder läufst, um einen Ausgleich zu haben \nsowie aktiv zu sein, wir wollen Dir zeigen,\n dass es sich lohnt regelmäßig laufen zu gehen.  ',
                    //   textAlign: TextAlign.center,
                    //   style: TextStyle(
                    //       height: 1.2,
                    //       fontWeight: FontWeight.normal,
                    //       fontSize: 18),
                    // ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Text(
                    //   ' Wie? Indem wir dir zeigen, dass dein Körper \n sich an deine Anstrengungen anpasst \nund mit dir wächst - ganz egal\n ob Du ans Limit gehst oder nach einem\n stressigen Tag den Kopf frei kriegen willst.',
                    //   textAlign: TextAlign.center,
                    //   style: TextStyle(
                    //       height: 1.2,
                    //       fontWeight: FontWeight.w300,
                    //       fontSize: 18),
                    // ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ' Unsere Vision',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          height: 1, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    IconButton(
                      icon: Icon(Icons.info_outline),
                      color: Colors.green,
                      tooltip: 'More Info',
                      onPressed: () {
                        CustomAlertDialog.showDialogPopup(
                            context: context,
                            text:
                                'Egal ob Du ein ambitioniertes \nZiel verfolgst oder läufst,\n um einen Ausgleich zu haben\n sowie aktiv zu sein,\n wir wollen Dir zeigen,\n dass es sich lohnt regelmäßig\n laufen zu gehen.',
                            text2:
                                "Wie? Indem wir dir zeigen\ndass dein Körper sich an deine\n Anstrengungen anpasst und\n mit dir wächst - ganz egal ob\n Du ans Limit gehst oder nach\n einem stressigen Tag den\n Kopf frei kriegen willst.");
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Wie kannst Du den Score nutzen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          height: 1, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    IconButton(
                      icon: Icon(Icons.info_outline),
                      color: Colors.green,
                      tooltip: 'More Info',
                      onPressed: () {
                        CustomAlertDialog.showDialogPopup(
                            context: context,
                            text:
                                'Der Score ermöglicht es dir\nAktivitäten mit unterschiedlichen\n Distanzen und Geschwindigkeiten\n zu vergleichen\ und\n deine Entwicklung zu \nverfolgen. Oft ist es dir \nvielleicht gar nicht bewusst,\n welche Auswirkungen\n das regelmäßige Laufen \ngehen auf deinen Körper\n hat und welche großartigen\n Scores Du bereits erzielt hast.\n Ziel es nicht, in jeder\n Aktivität einen besseren Score\n zu erzielen.',
                            text2:
                                'Ganz wie im Spitzensport auch\n kannst Du nicht in jedem Training\n einen neuen Weltrekord\n aufstellen. Aber gelegentliche\n individuelle Spitzenleistungen\n (hohe Scores) zeigen dir,\n dass sich dein Körper mit\n dir entwickelt\n und langfristig zahlen sich\n deine Anstrengungen aus.');
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Deine Trend Card',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          height: 1, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    IconButton(
                      icon: Icon(Icons.info_outline),
                      color: Colors.green,
                      tooltip: 'More Info',
                      onPressed: () {
                        CustomAlertDialog.showDialogPopup(
                            context: context,
                            text:
                                'Dein Trend zeigt Dir,\n wie sich bestimmte Parameter\n deiner Aktivität im Vergleich\n zum Durchschnitt der letzten\n sechs Aktivitäten entwickeln. ',
                            text2:
                                'Außerdem siehst Du wie\n viele intensive Aktivitätsminuten\n Du in den letzten sieben\n Tagen absolviert hast.\n Wenn Du mehr als 75\n intensive Aktivitätsminuten\n erreichst, wirkt sich\n deine körperliche Aktivität\n laut der WHO optimal\n auf deine Gesundheit aus.');
                      },
                    ),
                  ],
                ),
                Consumer<ProgressScreenProvider>(
                    builder: (context, consumer, childWidget) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 2,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              // for (int i = 0; i < 4; i++)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TrendCards(
                                  icons: Icon(Icons.assessment_outlined),
                                  title: "Distanz",
                                  description: double.parse(
                                              consumer.trendCard.distance) <
                                          double.parse(
                                              consumer.todayTrend.distance)
                                      ? "Hervorragend! Du bist bei deiner letzten Aktivität eine weitere Strecke als sonst gelaufen!"
                                      : "Großartig, dass Du aktiv bist. Jeder Kilometer tut Dir gut.",
                                  value: (double.parse(
                                              consumer.trendCard.distance) <
                                          double.parse(
                                              consumer.todayTrend.distance)
                                      ? "${consumer.trendCard.distance} < ${consumer.todayTrend.distance}"
                                      : "${consumer.trendCard.distance} > ${consumer.todayTrend.distance}"),
                                  icon: double.parse(
                                              consumer.trendCard.distance) <
                                          double.parse(
                                              consumer.todayTrend.distance)
                                      ? Icon(Icons.trending_up_rounded)
                                      : Icon(Icons.trending_down_rounded),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TrendCards(
                                  icons:
                                      Icon(Icons.assignment_turned_in_outlined),
                                  title: "Score",
                                  description: double.parse(
                                              consumer.trendScore.score) <
                                          double.parse(
                                              consumer.todayScore.score)
                                      ? "Hervorragend! Du hattest bei deiner letzten Aktivität einen höheren Score als sonst."
                                      : "Großartig, dass Du aktiv bist. Jeder Aktivität bringt dich weiter.",
                                  value: (double.parse(
                                              consumer.trendCard.score) <
                                          double.parse(
                                              consumer.todayTrend.score)
                                      ? "${consumer.trendScore.score} > ${consumer.todayScore.score}"
                                      : "${consumer.trendScore.score} < ${consumer.todayScore.score}"),
                                  icon:
                                      double.parse(consumer.trendScore.score) <
                                              double.parse(
                                                  consumer.todayScore.score)
                                          ? Icon(Icons.trending_up_rounded)
                                          : Icon(Icons.trending_down_rounded),

                                  // icon: Icon(Icons.trending_flat_rounded),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TrendCards(
                                  icons: Icon(Icons.av_timer_outlined),
                                  title: "Pace",
                                  description: double.parse(
                                              consumer.trendPace.pace) <
                                          double.parse(consumer.todayPace.pace)
                                      ? "Hervorragend! Du bist bei deiner letzten Aktivität im Durchschnitt schneller als sonst gelaufen"
                                      : "Großartig, dass Du aktiv bist. Jede Minute ist wertvoll.",
                                  value: (double.parse(
                                              consumer.trendPace.pace) <
                                          double.parse(consumer.todayPace.pace)
                                      ? "${consumer.trendPace.pace} < ${consumer.todayPace.pace}"
                                      : "${consumer.trendPace.pace} > ${consumer.todayPace.pace}"),
                                  icon: double.parse(consumer.trendPace.pace) <
                                          double.parse(consumer.todayPace.pace)
                                      ? Icon(Icons.trending_up_rounded)
                                      : Icon(Icons.trending_down_rounded),
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: 150,
                                    decoration: new BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              50, 5, 50, 0),
                                          child: Icon(
                                            Icons.av_timer_outlined,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              50, 2, 50, 5),
                                          child: Text(
                                            '75mins\nTarget',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: CircularPorogress(
                                            //instead of 35 we need a varaible with last 5 days miniutes and add them togther
                                            percentage: int.parse(
                                                    consumer.totalMinutes) /
                                                75 *
                                                100.toInt(),

                                            // percentage: this.totalSteps /
                                            //     this.goalSteps *
                                            //     100.toInt(),
                                            height: 80,
                                            child: Text(
                                              //Minutes variable to come instead of static 75 mins
                                              '${(int.parse(consumer.totalMinutes) * 7)} min',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            // child: Icon(
                                            //   CustomIcons.Pedometer
                                            //       .footsteps_silhouette_variant,
                                            //   size: 35,
                                            //   color: CustomColors.white,
                                            // ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              //CircularProgress Tab,
                            ],
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Icon(Icons.navigate_next_sharp),
                          Text(
                            'Swipe die \nBox weiter',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                height: 1,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ],
                      )
                    ],
                  );
                })
              ],
            ),
          ),
        ));
  }

  Flexible _monthSelection() {
    return Flexible(
      child: DropdownButton(
        hint: Text('Select Month'),
        value: userSelectedValue,
        onChanged: (value) {
          setState(
            () {
              userSelectedValue = value;
              switch (userSelectedValue) {
                case 'Jan':
                  {
                    userentry = chart('1');
                  }
                  break;
                case 'Feb':
                  {
                    userentry = chart('2');
                  }

                  break;

                case 'Mar':
                  {
                    userentry = chart('3');
                  }
                  break;
                case 'Apr':
                  {
                    userentry = chart('4');
                  }
                  break;
                case 'May':
                  {
                    userentry = chart('5');
                  }
                  break;
                case 'Jun':
                  {
                    userentry = chart('6');
                  }
                  break;
                case 'Jul':
                  {
                    userentry = chart('7');
                  }
                  break;
                case 'Aug':
                  {
                    userentry = chart('8');
                  }
                  break;
                case 'Sep':
                  {
                    userentry = chart('9');
                  }
                  break;
                case 'Oct':
                  {
                    userentry = chart('10');
                  }
                  break;
                case 'Nov':
                  {
                    userentry = chart('11');
                  }
                  break;
                case 'Dec':
                  {
                    userentry = chart('12');
                  }
                  break;
              }
            },
          );
        },
        items: users.map((String month) {
          return DropdownMenuItem<String>(
            value: month,

            // Row to Cloumn
            child: Row(
              children: <Widget>[
                Icon(Icons.calendar_today, color: Color(0xFF167F67)),
                SizedBox(
                  width: 10,
                ),
                Text(
                  month,
                  style: TextStyle(color: Colors.black),
                ),
                //
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class Item {
  const Item(this.name, this.icon);
  final String name;
  final Icon icon;
}
