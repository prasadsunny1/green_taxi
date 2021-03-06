import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:green_taxi/model/card_model.dart';
import 'package:green_taxi/model/place_model.dart';
import 'package:green_taxi/model/ride_option_model.dart';
import 'package:green_taxi/pages/taxi_movement_page.dart';
import 'package:green_taxi/utils/constants.dart';
import 'package:green_taxi/utils/styles.dart';
import 'package:place_picker/uuid.dart';
import 'package:green_taxi/provider/google_map_service.dart';

class BookTaxiPage extends StatefulWidget {
  static final routeName = "book-taxi-page";

  @override
  _BookTaxiPageState createState() => _BookTaxiPageState();
}

class _BookTaxiPageState extends State<BookTaxiPage> {
  LatLng myLocation;
  Set<Marker> _markers = {};
  String _mapStyle;
  BitmapDescriptor _taxilocation;
  BitmapDescriptor _mylocation;
  Completer<GoogleMapController> _controller = Completer();
  bool isMapCreated = false;
  final Key _mapKey = UniqueKey();
  int _selectedIndex = -1;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _fromLocationController = TextEditingController();
  final TextEditingController _toLocationController = TextEditingController();
  var uuid = Uuid();
  var sessionToken;
  var googleMapServices;
  PlaceDetail _fromPlaceDetail;
  PlaceDetail _toPlaceDetail;
  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  bool _hasGottenCordinates = false;

  List<UserCardModel> _cards = [
    UserCardModel(
        id: "1",
        imageUrl: 'assets/images/img_visa_logo.png',
        cardNumber: "**** **** **** 5687"),
    UserCardModel(
        id: "2",
        imageUrl: 'assets/images/img_visa_logo.png',
        cardNumber: "**** **** **** 9987"),
    UserCardModel(
        id: "3",
        imageUrl: 'assets/images/img_visa_logo.png',
        cardNumber: "**** **** **** 7879")
  ];

  List<RideOptionModel> ridesOptions = [
    RideOptionModel(
        id: "1",
        price: 9.90,
        estimatedTime: "5 MIN",
        rideType: "Standard",
        index: 0,
        imageUrl: "assets/images/standard.png"),
    RideOptionModel(
        id: "2",
        price: 10.90,
        index: 1,
        estimatedTime: "6 MIN",
        rideType: "Comfort",
        imageUrl: "assets/images/comfort.png"),
    RideOptionModel(
        id: "3",
        price: 49.90,
        index: 2,
        estimatedTime: "5 MIN",
        rideType: "Luxury",
        imageUrl: "assets/images/luxury.png"),
  ];

  UserCardModel _selectedalvalue;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5), 'assets/images/taxi.png')
        .then((onValue) {
      _taxilocation = onValue;
    });

    BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),
            'assets/images/mylocation.png')
        .then((onValue) {
      _mylocation = onValue;
    });

    super.initState();
    rootBundle.loadString('assets/images/map_style.txt').then((string) {
      _mapStyle = string;
    });

    _selectedalvalue = _cards[0];

    myLocation = LatLng(37.382782, 127.1189054);
    _markers.add(Marker(
        markerId: MarkerId("my location"),
        position: LatLng(myLocation.latitude, myLocation.longitude),
        icon: _mylocation,
        infoWindow: InfoWindow(
          title: "Pick Up Location",
        ),
        onTap: () {}));
  }

//   Future<void> getMyLocation() async {
//     Position position = await Geolocator()
//         .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
// //    myLocation = LatLng(position.latitude, position.longitude);
//     setState(() {
//       myLocation = LatLng(6.31, 5.2139453);
//     });

//     print(position);
//   }

  setPolylines() async {
    polylineCoordinates.clear();
    _polylines.clear();
    List<PointLatLng> result = await polylinePoints?.getRouteBetweenCoordinates(
        Constatnts.API_KEY,
        _fromPlaceDetail.lat,
        _fromPlaceDetail.lng,
        _toPlaceDetail.lat,
        _toPlaceDetail.lng);
    if (result.isNotEmpty) {
      result.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    setState(() {
      // create a Polyline instance

      Polyline polyline = Polyline(
          polylineId: PolylineId('poly'),
          color: Colors.black,
          width: 4,
          points: polylineCoordinates);
      _polylines.add(polyline);
      _hasGottenCordinates = true;
    });
  }

  void _moveCamera(
      PlaceDetail _fromplaceDetail, PlaceDetail _toPlaceDetail) async {
    if (_markers.length > 0) {
      setState(() {
        _markers.clear();
      });
    }
    if (_toLocationController.text != null && _toPlaceDetail != null) {
      GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(
        LatLng(_toPlaceDetail.lat, _toPlaceDetail.lng),
      ));
    }

    setState(() {
      if (_fromLocationController.text != null && _fromplaceDetail != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(_fromplaceDetail.placeId),
            position: LatLng(_fromplaceDetail.lat, _fromplaceDetail.lng),
            icon: _mylocation,
            infoWindow: InfoWindow(
              title: "pick up",
              snippet: _fromplaceDetail.formattedAddress,
            ),
          ),
        );
      }

      if (_toLocationController.text != null && _toPlaceDetail != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(_toPlaceDetail.placeId),
            position: LatLng(_toPlaceDetail.lat, _toPlaceDetail.lng),
            infoWindow: InfoWindow(
              title: "destination",
              snippet: _toPlaceDetail.formattedAddress,
            ),
          ),
        );
      }
    });

    if (_toLocationController.text != null &&
        _toPlaceDetail != null &&
        _fromLocationController.text != null &&
        _fromplaceDetail != null) {
      await setPolylines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(),
      body: Stack(
        children: <Widget>[
          Container(
              height: MediaQuery.of(context).size.height, //- 230.0,
              child: myLocation == null
                  ? Center(
                      child: Text("Loading Map"),
                    )
                  : GoogleMap(
                      key: _mapKey,
                      mapType: MapType.normal,

                      zoomGesturesEnabled: true,
                      // myLocationEnabled: true,
                      markers: _markers,
                      polylines: _polylines,
                      initialCameraPosition:
                          CameraPosition(target: myLocation, zoom: 15),
                      onMapCreated: (GoogleMapController controller) {
                        controller.setMapStyle(_mapStyle);
                        _controller.complete(controller);
                        // setState(() {
                        //   _markers.add(
                        //     Marker(
                        //         markerId: MarkerId("1"),
                        //         position: LatLng(6.465422, 3.406448),
                        //         icon: _taxilocation,
                        //         onTap: () {}),
                        //   );

                        //   _markers.add(
                        //     Marker(
                        //         markerId: MarkerId("2"),
                        //         position: LatLng(6.30, 3.2145634),
                        //         icon: _taxilocation,
                        //         onTap: () {}),
                        //   );

                        //   _markers.add(
                        //     Marker(
                        //         markerId: MarkerId("3"),
                        //         position: LatLng(6.35, 3.2139453),
                        //         icon: _taxilocation,
                        //         onTap: () {}),
                        //   );
                        // });
                      },
                    )),
          Positioned(top: 65, left: 5, right: 5, child: _buildHelloWidget()),
          _hasGottenCordinates
              ? _buildSelectRideWidget()
              : _buildToFromDestination(),
          Positioned(
            top: 25.0,
            left: 5.0,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState.openDrawer();
                  }),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToFromDestination() {
    return Positioned(
        bottom: 5,
        left: 5,
        right: 5,
        child: Card(
          child: Container(
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Column(
              children: <Widget>[
                TypeAheadField(
                  direction: AxisDirection.up,
                  debounceDuration: Duration(milliseconds: 500),
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _fromLocationController,
                    autofocus: true,
                    style: TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                        icon: new Icon(
                          FontAwesomeIcons.taxi,
                          color: Colors.green,
                        ),
                        suffixIcon: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 15,
                            ),
                            onPressed: () {
                              _fromLocationController.clear();
                            }),
                        labelText: "From"),
                  ),
                  suggestionsCallback: (pattern) async {
                    if (sessionToken == null) {
                      sessionToken = uuid.generateV4();
                    }
                    googleMapServices =
                        GoogleMapServices(sessionToken: sessionToken);
                    return await googleMapServices.getSuggestions(pattern);
                  },
                  itemBuilder: (context, suggetion) {
                    return ListTile(
                      title: Text(
                        suggetion.description,
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                  onSuggestionSelected: (suggetion) async {
                    _fromLocationController.text = suggetion.description;
                    _fromPlaceDetail = await googleMapServices.getPlaceDetail(
                      suggetion.placeId,
                      sessionToken,
                    );

                    _moveCamera(_fromPlaceDetail, _toPlaceDetail);
                    sessionToken = null;
                  },
                ),
                TypeAheadField(
                  direction: AxisDirection.up,
                  debounceDuration: Duration(milliseconds: 500),
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _toLocationController,
                    autofocus: true,
                    style: TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                        icon: new Icon(
                          FontAwesomeIcons.dotCircle,
                          color: Colors.red,
                        ),
                        suffixIcon: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 15,
                            ),
                            onPressed: () {
                              _toLocationController.clear();
                            }),
                        labelText: "To"),
                  ),
                  suggestionsCallback: (pattern) async {
                    if (sessionToken == null) {
                      sessionToken = uuid.generateV4();
                    }
                    googleMapServices =
                        GoogleMapServices(sessionToken: sessionToken);
                    return await googleMapServices.getSuggestions(pattern);
                  },
                  itemBuilder: (context, suggetion) {
                    return ListTile(
                      title: Text(
                        suggetion.description,
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                  onSuggestionSelected: (suggetion) async {
                    _toLocationController.text = suggetion.description;
                    _toPlaceDetail = await googleMapServices.getPlaceDetail(
                      suggetion.placeId,
                      sessionToken,
                    );
                    _moveCamera(_fromPlaceDetail, _toPlaceDetail);
                    sessionToken = null;
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    MaterialButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(new MaterialPageRoute(builder: (context) {
                          return TaxiMovementPage(
                            fromPlaceDetail: _fromPlaceDetail,
                            toPlaceDetail: _toPlaceDetail,
                            polylines: _polylines,
                            polylineCoordinates: polylineCoordinates,
                          );
                        }));
                      },
                      color: Colors.green,
                      textColor: Colors.white,
                      child: Icon(
                        Icons.arrow_forward,
                        size: 15,
                      ),
                      padding: EdgeInsets.all(6),
                      shape: CircleBorder(),
                    )
                  ],
                )
              ],
            ),
          ),
        ));
  }

  Widget _buildHelloWidget() {
    return Card(
      child: Container(
        color: Colors.white,
        child: ListTile(
          leading: Icon(
            FontAwesomeIcons.user,
            color: Constatnts.primaryColor,
            size: 40,
          ),
          title: Text(
            "Hello Dennis",
            style: CustomStyles.smallTextStyle,
          ),
          subtitle: Text(
            "Where are you Going to ?",
            style: CustomStyles.normalTextStyle,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectRideWidget() {
    return Positioned(
      bottom: 5,
      left: 5,
      right: 5,
      child: Card(
        child: Container(
          margin: EdgeInsets.all(10),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "Select Ride",
                style: CustomStyles.normalTextStyle,
              ),
              Container(
                height: 140,
                child: ListView.builder(
                    itemCount: ridesOptions.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.all(15.0),
                          elevation: 10,
                          color: _selectedIndex == ridesOptions[index].index
                              ? Constatnts.primaryColor
                              : Colors.white,
                          child: Container(
                            child: Container(
                              width: 200,
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  children: <Widget>[
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          ridesOptions[index].rideType,
                                          style: _selectedIndex ==
                                                  ridesOptions[index].index
                                              ? CustomStyles.cardBoldTextStyle
                                              : CustomStyles
                                                  .cardBoldDarkTextStyle,
                                        ),
                                        Text(
                                          "N ${ridesOptions[index].price.toString()}",
                                          style: _selectedIndex ==
                                                  ridesOptions[index].index
                                              ? CustomStyles.cardNormalTextStyle
                                              : CustomStyles
                                                  .cardNormalDarkTextStyle,
                                        ),
                                        Text(
                                          ridesOptions[index].estimatedTime,
                                          style: _selectedIndex ==
                                                  ridesOptions[index].index
                                              ? CustomStyles.cardNormalTextStyle
                                              : CustomStyles
                                                  .cardNormalDarkTextStyle,
                                        )
                                      ],
                                    ),
                                    Expanded(
                                        child: Image.asset(
                                            ridesOptions[index].imageUrl))
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: 200,
                    height: 50.0,
                    child: DropdownButton<UserCardModel>(
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.green,
                      ),
                      items: _cards.map((UserCardModel value) {
                        return new DropdownMenuItem<UserCardModel>(
                            value: value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Image.asset(
                                  value.imageUrl,
                                  height: 10,
                                ),
                                Text(
                                  value.cardNumber,
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ));
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          _selectedalvalue = value;
                        });
                      },
                      underline: SizedBox(),
                      isExpanded: true,
                      elevation: 0,
                      value: _selectedalvalue,

                      // onSaved: (value) {

                      // },
                    ),
                  ),
                  MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: Constatnts.primaryColor,
                    onPressed: () {
                      Navigator.of(context)
                          .push(new MaterialPageRoute(builder: (context) {
                        return TaxiMovementPage(
                          fromPlaceDetail: _fromPlaceDetail,
                          toPlaceDetail: _toPlaceDetail,
                          polylines: _polylines,
                          polylineCoordinates: polylineCoordinates,
                        );
                      }));
                    },
                    child: Text(
                      "Confirm",
                      style: CustomStyles.cardBoldTextStyle,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
