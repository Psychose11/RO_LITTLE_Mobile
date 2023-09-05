import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

void main() {
  runApp(MyApp());
}

class CityDistance {
  final String city;
  final int distance;

  CityDistance(this.city, this.distance);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Problème du Voyageur de Commerce',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> cities = [];
  List<List<double>> distances = [];
  List<int> minimalPath = [];
  List<int> values = [];

  TextEditingController cityCountController = TextEditingController();

  @override
  void dispose() {
    cityCountController.dispose();
    super.dispose();
  }

  void generateTable() {
    int cityCount = int.tryParse(cityCountController.text) ?? 0;

    if (cityCount < 2 || cityCount > 26) {
      return;
    }

    cities = List.generate(cityCount, (index) => String.fromCharCode(65 + index));
    distances = List.generate(cityCount, (index) => List<double>.filled(cityCount, 0.0));

    setState(() {});
  }

  void calculateMinimalPath() {
    int cityCount = cities.length;

    if (cityCount < 2) {
      return;
    }

    distances.forEach((row) {
      for (int i = 0; i < row.length; i++) {
        row[i] = double.tryParse(row[i].toStringAsFixed(1)) ?? 0.0;
      }
    });

    List<List<double>> copyDistances = List.from(distances);
    List<List<double>> originalDistances = List.from(distances);

    double b = subtractMinimum(copyDistances);
    double r = calculateRegret(copyDistances);
    double b1 = b + r;

    double b2 = b;
    List<int> zeroRows = [];
    List<int> zeroCols = [];

    while (true) {
      zeroRows = findZeroRows(copyDistances);
      zeroCols = findZeroCols(copyDistances);

      if (zeroRows.length != cityCount || zeroCols.length != cityCount) {
        b2 += subtractMinimumWithBlockedArc(copyDistances, zeroRows, zeroCols);
      } else {
        break;
      }
    }

    double minimalCost = b1 < b2 ? b1 : b2;

    minimalPath = [];
    List<int> path = List.generate(cityCount - 1, (index) => index + 1);

    calculateMinimalPathRecursive(path, 0, 0, [0]);

    values = minimalPath.map((city) => originalDistances[city][minimalPath[(minimalPath.indexOf(city) + 1) % minimalPath.length]].toInt()).toList();

    setState(() {});
  }

  double calculateMinimalPathRecursive(List<int> path, int currentCity, double currentDistance, List<int> currentPath) {
    if (path.isEmpty) {
      minimalPath = List.from(currentPath);
      return currentDistance + distances[currentCity][0];
    }

    double minDistance = double.infinity;
    List<int> minPath = [];

    for (int i = 0; i < path.length; i++) {
      int nextCity = path[i];
      List<int> newPath = List.from(path)..removeAt(i);
      double newDistance = currentDistance + distances[currentCity][nextCity];
      List<int> newPathSoFar = List.from(currentPath)..add(nextCity);

      double distance = calculateMinimalPathRecursive(newPath, nextCity, newDistance, newPathSoFar);

      if (distance < minDistance) {
        minDistance = distance;
        minPath = List.from(minimalPath);
      }
    }

    minimalPath = List.from(minPath);

    return minDistance;
  }

  double subtractMinimum(List<List<double>> distances) {
    double b = 0;

    for (int i = 0; i < distances.length; i++) {
      double min = distances[i].reduce((value, element) => value < element ? value : element);

      if (min != double.infinity) {
        for (int j = 0; j < distances[i].length; j++) {
          if (distances[i][j] != double.infinity) {
            distances[i][j] -= min;
          }
        }

        b += min;
      }
    }

    return b;
  }

  double calculateRegret(List<List<double>> distances) {
    double maxRegret = 0;

    for (int i = 0; i < distances.length; i++) {
      double min1 = double.infinity;
      double min2 = double.infinity;

      for (int j = 0; j < distances[i].length; j++) {
        if (distances[i][j] < min1) {
          min2 = min1;
          min1 = distances[i][j];
        } else if (distances[i][j] < min2) {
          min2 = distances[i][j];
        }
      }

      double regret = min2 - min1;

      if (regret > maxRegret) {
        maxRegret = regret;
      }
    }

    return maxRegret;
  }

  double subtractMinimumWithBlockedArc(List<List<double>> distances, List<int> zeroRows, List<int> zeroCols) {
    List<List<double>> copyDistances = List.from(distances);

    for (int i = 0; i < copyDistances.length; i++) {
      for (int j = 0; j < copyDistances[i].length; j++) {
        if (zeroRows.contains(i) || zeroCols.contains(j)) {
          copyDistances[i][j] = double.infinity;
        }
      }
    }

    return subtractMinimum(copyDistances);
  }

  List<int> findZeroRows(List<List<double>> distances) {
    List<int> zeroRows = [];

    for (int i = 0; i < distances.length; i++) {
      bool hasZero = distances[i].any((value) => value == 0);

      if (hasZero) {
        zeroRows.add(i);
      }
    }

    return zeroRows;
  }

  List<int> findZeroCols(List<List<double>> distances) {
    List<int> zeroCols = [];

    for (int i = 0; i < distances[0].length; i++) {
      bool hasZero = false;

      for (int j = 0; j < distances.length; j++) {
        if (distances[j][i] == 0) {
          hasZero = true;
          break;
        }
      }

      if (hasZero) {
        zeroCols.add(i);
      }
    }

    return zeroCols;
  }

  Widget buildIllustration() {
    var points = <Map<String, double>>[];

    var radius = 200.0;
    var angle = (2 * 3.141592653589793) / cities.length;

    for (var i = 0; i < cities.length; i++) {
      var x = 500 + (radius * cos(i * angle));
      var y = 300 + (radius * sin(i * angle));
      points.add({'x': x, 'y': y});
    }

    var svgCode = '''
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1"
        width="1000" height="600" viewBox="0 0 1000 600" style="enable-background:new 0 0 1000 600;"
        xml:space="preserve">
        <defs>
          <marker id="arrowhead" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto">
            <path d="M0,0 L0,6 L9,3 z" fill="black"/>
          </marker>
        </defs>
        <g id="graph">
          <!-- Dessin des cercles des villes -->
          ${points.map((point) => '<circle class="city-circle" cx="${point['x']}" cy="${point['y']}" r="25" fill="whitesmoke"/>').join('\n')}

          <!-- Dessin des flèches et des valeurs de chemin -->
          ${minimalPath.asMap().entries.map((entry) {
      var start = entry.value;
      var end = minimalPath[(entry.key + 1) % minimalPath.length];
      var startPoint = points[start];
      var endPoint = points[end];
      var value = values[entry.key];
      var dx = endPoint['x']! - startPoint['x']!;
      var dy = endPoint['y']! - startPoint['y']!;
      var dr = sqrt((dx * dx) + (dy * dy));

      return '''
            <path d="M${startPoint['x']},${startPoint['y']} C${(startPoint['x']! + endPoint['x']!) / 2},${(startPoint['y']! + endPoint['y']!) / 2 - (dr / 2)} ${endPoint['x']},${endPoint['y']}"
                  fill="none" stroke="black" marker-end="url(#arrowhead)"/>
            <text x="${(startPoint['x']! + endPoint['x']!) / 2}" y="${(startPoint['y']! + endPoint['y']!) / 2 - (dr / 2) - 10}"
                  text-anchor="middle" alignment-baseline="middle" class="path-label">${value}</text>
          ''';
    }).join('\n')}

          <!-- Dessin du retour au point de départ -->
          ${minimalPath.isNotEmpty ? '''
            <path d="M${points[minimalPath.last]['x']},${points[minimalPath.last]['y']} C${(points.first['x']! + points[minimalPath.last]['x']!) / 2},${(points.first['y']! + points[minimalPath.last]['y']!) / 2 + 100} ${points.first['x']},${points.first['y']}"
                  fill="none" stroke="black" marker-end="url(#arrowhead)"/>
          ''' : ''}
          
          <!-- Ajout des étiquettes des villes -->
          ${cities.asMap().entries.map((entry) => '<text x="${points[entry.key]['x']}" y="${points[entry.key]['y']! - 12}" text-anchor="middle" alignment-baseline="middle" class="city-label">${entry.value}</text>').join('\n')}
        </g>
      </svg>
  ''';

    return HtmlWidget(
      svgCode,

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Problème du Voyageur de Commerce'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nombre de villes :',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCountController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 16.0),
                  ElevatedButton(
                    child: Text('Générer le tableau'),
                    onPressed: generateTable,
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              if (cities.isNotEmpty)
                Table(
                  border: TableBorder.all(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        TableCell(child: Container()),
                        ...cities.map((city) => TableCell(child: Text(city))).toList(),
                      ],
                    ),
                    ...cities.asMap().entries.map(
                          (entry) => TableRow(
                        children: [
                          TableCell(child: Text(entry.value)),
                          ...List.generate(
                            cities.length,
                                (index) {
                              bool isDiagonal = index == entry.key;
                              return TableCell(
                                child: TextField(
                                  enabled: !isDiagonal,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (value) {
                                    double numericValue = double.tryParse(value) ?? 0.0;
                                    distances[entry.key][index] = numericValue;
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 16.0),
              if (minimalPath.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chemin minimal :',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Distance totale : ${values.reduce((value, element) => value + element)}',
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Chemin : ${minimalPath.map((index) => cities[index]).join(' -> ')} -> A',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              SizedBox(height: 16.0),
              buildIllustration(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.play_arrow),
        onPressed: calculateMinimalPath,
      ),
    );
  }
}
