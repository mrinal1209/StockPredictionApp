import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Stocks HomePage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    setState(() {
      const oneSecond = const Duration(seconds: 60);
      new Timer.periodic(oneSecond, (Timer t) => setState(() {}));
    });
  }

  Future<List<StockHomePage>> _getAllStocks() async {
      var data = await http.get("http://192.168.43.231:5002/homepage");
    //var data = await http.get(
      //"https://raw.githubusercontent.com/mrinal1209/Spring_CRUD_Demo_with_REDIS/master/hack");

    var jsonData = json.decode(data.body);

    print(jsonData);

    List<StockHomePage> stocks = [];

    for (var s in jsonData) {
      StockHomePage stock = StockHomePage(
          s["company_current_price"],
          s["company_detailed_url"],
          s["company_img_url"],
          s["company_id"],
          s["company_name"],
          s["company_stock_price_delta"]);
      print(stock);
      stocks.add(stock);
    }

    print(stocks.length);

    return stocks;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: Container(
        child: FutureBuilder(
          future: _getAllStocks(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            print(snapshot.data);
            if (snapshot.data == null) {
              return Container(child: Center(child: Text("Loading...")));
            } else {
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: <Widget>[
                      Container(
                          constraints: BoxConstraints.expand(
                            height:
                                Theme.of(context).textTheme.display1.fontSize *
                                        1.1 +
                                    110.0,
                          ),
                          color: Colors.white10,
                          alignment: Alignment.center,
                          child: Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Row(children: [
                                  Expanded(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        radius: 36,
                                        backgroundImage: NetworkImage(
                                            snapshot.data[index].productImgUrl),
                                      ),
                                      title: Text(
                                          snapshot.data[index].productName),
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            new MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailPage(
                                                        snapshot.data[index])));
                                      },
                                    ),
                                  ),
                                  Container(
                                      padding:
                                          EdgeInsets.fromLTRB(0, 45, 20, 50),
                                      child: Column(
                                        children: <Widget>[
                                          new Text(snapshot.data[index]
                                                  .productCurrentPrice +
                                              " INR"),
                                          if (double.parse(snapshot.data[index]
                                                  .productPriceDelta) >=
                                              0.0)
                                            new Row(
                                              children: <Widget>[
                                                Icon(Icons.arrow_upward,
                                                    color: Colors.green),
                                                Text(
                                                    snapshot.data[index]
                                                        .productPriceDelta,
                                                    style: TextStyle(
                                                        color: Colors.green))
                                              ],
                                            )
                                          else
                                            new Row(
                                              children: <Widget>[
                                                Icon(Icons.arrow_downward,
                                                    color: Colors.red),
                                                Text(
                                                    snapshot.data[index]
                                                        .productPriceDelta,
                                                    style: TextStyle(
                                                        color: Colors.red))
                                              ],
                                            )
                                        ],
                                      )),
                                ]),
                              ],
                            ),
                          )),
                    ],
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final StockHomePage stocks;

  DetailPage(this.stocks);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(title: new Text("Details")),
      body: new ItemDetailsPage(stocks),
    );
  }
}

class ItemDetailsPage extends StatefulWidget {
  final StockHomePage stocks;

  ItemDetailsPage(this.stocks);
  @override
  _ItemDetailsPageState createState() => new _ItemDetailsPageState(stocks);
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final StockHomePage stocks;

  _ItemDetailsPageState(this.stocks);

  String url = "https://raw.githubusercontent.com/mrinal1209/Spring_CRUD_Demo_with_REDIS/master/dt";
  List dataJSON;
  Prices price;
  Future<String> getCoinsTimeSeries() async {
    var response = await http.get(url);
   // var response = await http.get(this.stocks.prdouctDetailedUrl);
    if (this.mounted) {
      this.setState(() {
        var extractdata = json.decode(response.body);
        print(extractdata);
        dataJSON = extractdata['graph_price'];
        price = new Prices(
            extractdata['buy_price'].toString(),
            extractdata['sell_price'].toString(),
            extractdata['final_predicted_price'].toString());
        print(dataJSON);
      });
    }
  }

  @override
  void initState() {
    this.getCoinsTimeSeries();
    setState(() {
      const oneSecond = const Duration(seconds: 55);
      new Timer.periodic(oneSecond, (Timer t) => setState(() {}));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: chartWidget(),
    );
  }

  Widget chartWidget() {
    List<TimeSeriesPrice> liveGraph = [];
    List<TimeSeriesPrice> predictionGraph = [];
    if (dataJSON != null) {
      for (var m in dataJSON) {
        try {
          liveGraph.add(new TimeSeriesPrice(
              new DateTime.fromMillisecondsSinceEpoch(m['time'] * 1000,
                  isUtc: true),
              m['close']));
          predictionGraph.add(new TimeSeriesPrice(
              new DateTime.fromMillisecondsSinceEpoch(m['time'] * 1000,
                  isUtc: true),
              m["predicted_price"]));
        } catch (e) {
          print(e.toString());
        }
      }
    } else {
      // Dummy list to prevent dataJSON = NULL
      liveGraph.add(new TimeSeriesPrice(new DateTime.now(), 0.0));
      predictionGraph.add(new TimeSeriesPrice(new DateTime.now(), 0.0));
    }

    var series = [
      new charts.Series<TimeSeriesPrice, DateTime>(
        id: 'Live Prices',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (TimeSeriesPrice coinsPrice, _) => coinsPrice.time,
        measureFn: (TimeSeriesPrice coinsPrice, _) => coinsPrice.price,
        data: liveGraph,
      ),
      /*new charts.Series<TimeSeriesPrice, DateTime>(
        id: 'Predicted Prices',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesPrice coinsPrice, _) => coinsPrice.time,
        measureFn: (TimeSeriesPrice coinsPrice, _) => coinsPrice.price,
        data: predictionGraph,
      ),*/
    ];

    var chart = new charts.TimeSeriesChart(
      series,
      animate: true,
      primaryMeasureAxis: new charts.NumericAxisSpec(
          tickProviderSpec:
              new charts.BasicNumericTickProviderSpec(zeroBound: false)),
    );

    return new Container(
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.fromLTRB(10, 5, 0, 100),
            child: new SizedBox(
              height: 500,
              child: chart,
            ),
          ),
          Row(
            children: <Widget>[
              MaterialButton(
                padding: EdgeInsets.all(30),
                color: Colors.orange[300],
                child: Text(() {
                  if(price != null)
                    return  'BUY \n' + price.buyPrice;
                  else
                    return 'BUY';
                }()),
                onPressed: null,
              ),
              MaterialButton(
                padding: EdgeInsets.all(30),
                color: Colors.orange[300],
                child: Text(() {
                  if(price != null)
                    return  'SELL \n' + price.sellPrice;
                  else
                    return 'SELL';
                }()),
                onPressed: null,
              ),
              MaterialButton(
                //padding: EdgeInsets.all(30),
                color: Colors.orange[300],
                child: Text(() {
                  if(price != null)
                    return  'Prediction \n' + price.predictedPrice;
                  else
                    return 'Prediction';
                }()),
                onPressed: null,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class StockHomePage {
  final String productCurrentPrice;
  final String prdouctDetailedUrl;
  final String productImgUrl;
  final String productId;
  final String productName;
  final String productPriceDelta;

  StockHomePage(
      this.productCurrentPrice,
      this.prdouctDetailedUrl,
      this.productImgUrl,
      this.productId,
      this.productName,
      this.productPriceDelta);
}

class TimeSeriesPrice {
  final DateTime time;
  final double price;
  TimeSeriesPrice(this.time, this.price);
}

class Prices {
  final String buyPrice;
  final String sellPrice;
  final String predictedPrice;

  Prices(this.buyPrice, this.sellPrice, this.predictedPrice);
}
