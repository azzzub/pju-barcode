import 'dart:async';
import 'dart:convert';

import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan/qrscan.dart' as scanner;

void main() => runApp(MaterialApp(
      home: MyApp(),
      theme: ThemeData(
        primaryColor: Colors.green[800],
        fontFamily: 'MaisonNeue',
      ),
      debugShowCheckedModeBanner: false,
    ));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum daftarMenu { keluar, info }

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPref();
  }

  bool switchLampu = false, switchPanel = false, switchKendali = false;

  String kodePju;

  bool statusMasuk = false;
  bool loading = false;

  final _key = new GlobalKey<FormState>();

  cek() {
    final form = _key.currentState;
    if (form.validate()) {
      form.save();
      setState(() {
        loading = true;
      });
      masuk();
    }
  }

  masuk() async {
    final response = await http.post(
        "http://lectro-pju.000webhostapp.com/login.php",
        body: {"kode": kodePju});
    final data = jsonDecode(response.body);
    int value = data['value'];
    String pesan = data['message'];
    String id = data['id'];
    String kode = data['kode'];
    if (value == 1) {
      setState(() {
        statusMasuk = true;
        savePref(value, id, kode);
        loading = true;
        ambilData();
      });
      print(pesan);
    } else {
      Toast.show("Kode PJU tidak dikenali!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
      print(pesan);
    }
    setState(() => loading = false);
  }

  keluar() {
    setState(() {
      savePref(null, null, null);
      statusMasuk = false;
    });
  }

  savePref(int value, String id, String kode) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      preferences.setInt("value", value);
      preferences.setString("id", id);
      preferences.setString("kode", kode);
      preferences.commit();
    });
  }

  getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      int value = preferences.getInt("value");
      kodePju = preferences.getString("kode");
      if (value == 1) {
        statusMasuk = true;
        loading = true;
        ambilData();
      } else {
        statusMasuk = false;
      }
      print(statusMasuk);
      print(kodePju);
    });
  }

  Future scan() async {
    String barcode = await scanner.scan();
    setState(() {
      kodePju = barcode;
      setState(() => loading = true);
      masuk();
    });
  }

  Widget tampilanMasuk() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Lectro PJU",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ModalProgressHUD(
        dismissible: true,
        inAsyncCall: loading,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              Image.asset(
                "asset/image/lectro-logo.png",
                width: 250.0,
              ),
              SizedBox(
                height: 12.0,
              ),
              Form(
                key: _key,
                child: TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.blur_linear),
                    hintText: 'Masukan kode PJU',
                    labelText: 'Kode PJU',
                  ),
                  initialValue: kodePju,
                  validator: (String value) =>
                      value.isEmpty ? "Harap mengisi kode PJU" : null,
                  onSaved: (String value) => kodePju = value,
                ),
              ),
              SizedBox(
                height: 16.0,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  MaterialButton(
                    color: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.camera_alt),
                        SizedBox(
                          width: 8.0,
                        ),
                        Text("Scan QR"),
                      ],
                    ),
                    onPressed: () {
                      scan();
                    },
                  ),
                  SizedBox(
                    width: 16.0,
                  ),
                  MaterialButton(
                    color: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.input),
                        SizedBox(
                          width: 8.0,
                        ),
                        Text("Masuk"),
                      ],
                    ),
                    onPressed: () {
                      print(kodePju);
                      cek();
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 24.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Versi 0.1-alpha"),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String tegangan = "0", arus = "0", temperatur = "0", waktu = "0", daya = "0";

  ambilData() async {
    final response = await http.post(
        "http://lectro-pju.000webhostapp.com/get.php",
        body: {"kode": kodePju});
    final data = jsonDecode(response.body);
    int value = data['value'];
    String pesan = data['message'];
    setState(() {
      tegangan = data['tegangan'];
      arus = data['arus'];
      temperatur = data['temperatur'];
      waktu = data['waktu'];
      daya = (double.parse(arus) * double.parse(tegangan))
          .roundToDouble()
          .toString();
      switchKendali = data['manual'] == '1' ? true : false;
      switchLampu = data['lampu'] == '1' ? true : false;
    });
    if (value == 1) {
      print(pesan);
      Toast.show("Berhasil diperbarui!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    } else {
      setState(() {
        tegangan = "...";
        arus = "...";
        temperatur = "...";
        waktu = "...";
        daya = "...";
      });
      Toast.show("Ambil data gagal!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      print(pesan);
    }
    setState(() => loading = false);
  }

  postManual() async {
    final response = await http
        .post("http://lectro-pju.000webhostapp.com/newManual.php", body: {
      "kode": kodePju,
      "manual": (switchKendali ? 1 : 0).toString(),
      "lampu": (switchLampu ? 1 : 0).toString(),
      "solar": (switchPanel ? 1 : 0).toString()
    });
    final data = jsonDecode(response.body);
    int value = data['value'];
    String pesan = data['message'];
    if (value == 1) {
      print(pesan);
      Toast.show("Berhasil diperbarui!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    } else {
      setState(() {
        tegangan = "0";
        arus = "0";
        temperatur = "0";
        waktu = "0";
        daya = "0";
      });
      Toast.show("Ambil data gagal!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      print(pesan);
    }
    setState(() => loading = false);
  }

  Future<Null> _onRefresh() {
    Completer<Null> completer = new Completer<Null>();
    new Timer(new Duration(seconds: 1), () {
      setState(() {
        loading = true;
        ambilData();
      });
      completer.complete();
    });
    return completer.future;
  }

  String persen(String tegangan) {
    return ((double.parse(tegangan) / 15.4) * 100).toStringAsFixed(0);
  }

  String baterai(String persen) {
    double persenConv = double.parse(persen);
    if (persenConv <= 25) {
      return "asset/image/batt-25.png";
    } else if (persenConv > 25 && persenConv <= 50) {
      return "asset/image/batt-50.png";
    } else if (persenConv > 50 && persenConv <= 75) {
      return "asset/image/batt-75.png";
    } else {
      return "asset/image/batt-100.png";
    }
  }

  Widget tampilanBeranda() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Beranda",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (result) {
              setState(() {
                print(result);
                if (result == daftarMenu.keluar) {
                  keluar();
                }
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<daftarMenu>>[
              const PopupMenuItem<daftarMenu>(
                value: daftarMenu.info,
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text("Info"),
                ),
              ),
              const PopupMenuItem<daftarMenu>(
                value: daftarMenu.keluar,
                child: ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text("Keluar"),
                ),
              ),
            ],
          ),
        ],
      ),
      body: new RefreshIndicator(
        onRefresh: _onRefresh,
        child: ModalProgressHUD(
          inAsyncCall: loading,
          child: ListView(
            children: <Widget>[
              Column(
                children: <Widget>[
                  SizedBox(
                    height: 16.0,
                  ),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 20.0,
                      ),
                      Text(
                        "Perbarui terakhir:  $waktu",
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                          "asset/image/solar-panel.png",
                          width: 50.0,
                        ),
                        SizedBox(
                          width: 8.0,
                        ),
                        Image.asset(
                          "asset/image/animated-arrow.gif",
                          width: 30.0,
                        ),
                        SizedBox(
                          width: 8.0,
                        ),
                        Stack(
                          alignment: AlignmentDirectional.center,
                          children: <Widget>[
                            Image.asset(
                              baterai(persen(tegangan)),
                              width: 120.0,
                            ),
                            Column(
                              children: <Widget>[
                                Text(
                                  persen(tegangan) + "%",
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  height: 4.0,
                                ),
                                Text('$tegangan Volt'),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 8.0,
                        ),
                        Image.asset(
                          "asset/image/animated-arrow.gif",
                          width: 30.0,
                        ),
                        SizedBox(
                          width: 8.0,
                        ),
                        Image.asset(
                          "asset/image/lampu-on.png",
                          width: 45.0,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, top: 4.0),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.data_usage),
                          SizedBox(
                            width: 6.0,
                          ),
                          Text(
                            "Data",
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 12.0,
                  ),
                  Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: 32.0, top: 4.0, bottom: 4.0),
                      child: Text(
                        "Daya:  $daya Watt",
                        style: TextStyle(),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 12.0,
                  ),
                  Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: 32.0, top: 4.0, bottom: 4.0),
                      child: Text(
                        "Arus:  $arus Amp",
                        style: TextStyle(),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 12.0,
                  ),
                  Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: 32.0, top: 4.0, bottom: 4.0),
                      child: Text(
                        "Suhu:  $temperatur °C",
                        style: TextStyle(),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 12.0,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      MaterialButton(
                        color: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0)),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.insert_chart),
                            SizedBox(
                              width: 8.0,
                            ),
                            Text("Tampilkan Seluruh Data"),
                          ],
                        ),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => SemuaData()));
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20.0,
                    ),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.settings),
                          SizedBox(
                            width: 6.0,
                          ),
                          Text(
                            "Pengaturan",
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 12.0,
                  ),
                  Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: SwitchListTile(
                          title: const Text('Kendali Manual'),
                          value: switchKendali,
                          onChanged: (bool value) {
                            setState(() {
                              loading = true;
                              switchKendali = value;
                              postManual();
                            });
                          },
                          secondary: const Icon(Icons.edit)),
                    ),
                  ),
                  SizedBox(
                    height: 4.0,
                  ),
                  // Container(
                  //   width: double.infinity,
                  //   color: Colors.grey[200],
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(left: 14.0),
                  //     child: SwitchListTile(
                  //       title: const Text('Panel Surya'),
                  //       value: switchPanel,
                  //       onChanged: switchKendali
                  //           ? (bool value) {
                  //               setState(() {
                  //                 loading = true;
                  //                 switchPanel = value;
                  //                 postManual();
                  //               });
                  //             }
                  //           : null,
                  //       secondary: const Icon(Icons.grid_on),
                  //     ),
                  //   ),
                  // ),
                  Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: SwitchListTile(
                        title: const Text('Lampu'),
                        value: switchLampu,
                        onChanged: switchKendali
                            ? (bool value) {
                                setState(() {
                                  loading = true;
                                  switchLampu = value;
                                  postManual();
                                });
                              }
                            : null,
                        secondary: const Icon(Icons.lightbulb_outline),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (statusMasuk) {
      case false:
        return tampilanMasuk();
        break;
      case true:
        return tampilanBeranda();
        break;
    }
  }
}

class SemuaData extends StatefulWidget {
  @override
  _SemuaDataState createState() => _SemuaDataState();
}

class _SemuaDataState extends State<SemuaData> {
  void initState() {
    // TODO: implement initState
    super.initState();
    getPref();
  }

  String kodePju;
  getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      kodePju = preferences.getString("kode");
      print('web $kodePju');
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
      url: "https://lectro-pju.000webhostapp.com/tabel.php?kode=$kodePju",
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Seluruh Data",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      withZoom: false,
    );
  }
}
