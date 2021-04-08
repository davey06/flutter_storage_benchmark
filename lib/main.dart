import 'dart:math';

import 'package:chips_choice/chips_choice.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:storage_benchmark/benchmark.dart';

void main() async {
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  TabController controller;

  @override
  void initState() {
    super.initState();
    choices = listPackages;
    choices.sort();

    controller = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Container(
            // padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Text(
                    "Storage Benchmark",
                    style: TextStyle(fontSize: 30),
                  ),
                ),
                SizedBox(height: 15),
                TabBar(
                  tabs: <Widget>[
                    Tab(text: "write"),
                    Tab(text: "read"),
                    Tab(text: "delete"),
                  ],
                  labelColor: const Color(0xff7589a2),
                  controller: controller,
                  onTap: (index) {
                    setState(() {});
                  },
                ),
                ChipsChoice<String>.multiple(
                  value: choices,
                  onChanged: (v) {
                    v.sort();
                    setState(() => choices = v);
                  },
                  choiceItems: C2Choice.listFrom<String, String>(
                    source: listPackages,
                    value: (i, v) => v,
                    label: (i, v) => v,
                  ),
                ),
                SizedBox(height: 25),
                Expanded(
                  child: BenchmarkWidget(BenchmarkType.values[controller.index]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum BenchmarkType { read, write, delete }

class BenchmarkWidget extends StatefulWidget {
  final BenchmarkType type;

  BenchmarkWidget(this.type);

  @override
  _BenchmarkWidgetState createState() => _BenchmarkWidgetState();
}

class _BenchmarkWidgetState extends State<BenchmarkWidget> {
  static const entrySteps = [10, 20, 50, 100, 200, 500, 1000];

  var entryValue = 0.0;
  int get entries => entrySteps[entryValue.round()];

  var benchmarkRunning = false;
  List<Result> benchmarkResults;

  @override
  void didChangeDependencies() {
    benchmarkResults = null;
    benchmarkRunning = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (benchmarkResults == null)
          Expanded(
            child: Center(
              child: Text('Run benchmark to show data'),
            ),
          )
        else
          Expanded(
            child: Center(
              child: BenchmarkResult(benchmarkResults),
            ),
          ),
        SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: Slider(
                value: entryValue,
                min: 0,
                max: (entrySteps.length - 1).toDouble(),
                divisions: entrySteps.length - 2,
                onChanged: (newValue) {
                  setState(() {
                    entryValue = newValue;
                  });
                },
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(entries.toString() + " Entries"),
            ),
          ],
        ),
        Center(
          child: RaisedButton(
            onPressed: !benchmarkRunning ? _performBenchmark : null,
            child: !benchmarkRunning ? Text("Benchmark") : CircularProgressIndicator(),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  _performBenchmark() async {
    var entries = this.entries;
    setState(() {
      benchmarkRunning = true;
    });

    List<Result> results;
    switch (widget.type) {
      case BenchmarkType.read:
        results = await benchmarkRead(entries);
        break;
      case BenchmarkType.write:
        results = await benchmarkWrite(entries);
        break;
      case BenchmarkType.delete:
        results = await benchmarkDelete(entries);
        break;
    }

    setState(() {
      benchmarkRunning = false;
      benchmarkResults = results;
    });
  }
}

class BenchmarkResult extends StatelessWidget {
  final Color leftBarColor = Color(0xff53fdd7);
  final Color rightBarColor = Color(0xffff5182);
  final double width = 12;

  final List<Result> results;

  BenchmarkResult(this.results);

  List<String> get labels {
    return results.map((r) => r.runner.name).toList();
  }

  int get maxResultTime {
    var max = 0;
    for (var result in results) {
      if (result.intTime > max) {
        max = result.intTime;
      }
      if (result.stringTime > max) {
        max = result.stringTime;
      }
    }
    return max;
  }

  List<BarChartGroupData> get barGroups {
    var x = 0;
    return results.map((result) {
      return BarChartGroupData(
        barsSpace: 2,
        x: x++,
        barRods: [
          BarChartRodData(
            y: max(result.intTime.toDouble(), 1),
            colors: [leftBarColor],
            width: width,
            borderRadius: BorderRadius.circular(20),
          ),
          BarChartRodData(
            y: max(result.stringTime.toDouble(), 1),
            colors: [rightBarColor],
            width: width,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 15,
                height: 15,
                child: Container(
                  color: leftBarColor,
                ),
              ),
              SizedBox(width: 5),
              Text(
                'Integers',
                style: TextStyle(
                  color: const Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 15,
                height: 15,
                child: Container(
                  color: rightBarColor,
                ),
              ),
              SizedBox(width: 5),
              Text(
                'Strings',
                style: TextStyle(
                  color: const Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: _buildChart(),
        ),
      ],
    );
  }

  _buildChart() {
    var maxTime = maxResultTime;
    print(maxTime);
    return Container(
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchCallback: (res) {
              return res.spot != null ? res.spot.props : null;
            },
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.grey,
            ),
          ),
          maxY: maxTime.toDouble(),
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: SideTitles(
              showTitles: true,
              getTextStyles: (value) {
                return TextStyle(
                  color: const Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                );
              },
              margin: 10,
              getTitles: (double value) {
                return labels[(value ?? 0).toInt()];
              },
            ),
            leftTitles: SideTitles(
              showTitles: true,
              getTextStyles: (value) {
                return TextStyle(
                  color: const Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                );
              },
              margin: 2,
              reservedSize: 35,
              getTitles: (value) {
                if (value % (maxTime / 5).floor() == 0) {
                  return value.toInt().toString() + 'ms';
                }
                return '';
              },
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }
}
