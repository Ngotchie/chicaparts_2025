import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chicaparts_partner/api/api_accommodation.dart';
import 'package:chicaparts_partner/models/model_accommodation.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/menu/appBar.dart';
import 'package:chicaparts_partner/widgets/menu/drawer.dart';

import '../../methods.dart';

class AccommodationIndexWidget extends StatefulWidget {
  const AccommodationIndexWidget({super.key, required this.user});
  final User user;
  @override
  _AccommodationIndexWidgetState createState() =>
      _AccommodationIndexWidgetState();
}

class _AccommodationIndexWidgetState extends State<AccommodationIndexWidget> {
  final apiAcc = ApiAccommodation();

  Future<dynamic> callApiAcc(id) {
    return apiAcc.getOneAccommodations(id);
  }

  Future<dynamic> callApiListAcc(partner) {
    return apiAcc.getAccommodations(partner);
  }

  Future<List<SpaceAccommodation>> callApiSpcAcc(id) {
    return apiAcc.spacesAccommodation(id);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.6;
    return Scaffold(
      appBar: appBar("ACCOMMODATIONS", context, 0),
      drawer: drawer(widget.user, context),
      body: Container(
          color: Colors.white,
          child: Column(children: <Widget>[
            FutureBuilder(
                future: callApiListAcc(widget.user.id),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.data == null) {
                    return Container(
                      child: const Center(
                        child: Text("Loading..."),
                      ),
                    );
                  } else {
                    final accommodations = snapshot.data["accommodations"];
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.87,
                      child: SingleChildScrollView(
                        child: Flex(
                          direction: Axis.vertical,
                          children: [
                            Card(
                              child: Column(
                                children: [
                                  ListTile(
                                    tileColor: Colors.grey[200],
                                    leading: const Icon(Icons.house),
                                    title: const Text("My Accommodations"),
                                  ),
                                  ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      itemCount: accommodations.length,
                                      itemBuilder: (context, i) {
                                        return GestureDetector(
                                            onTap: () {
                                              showAccommodation(
                                                  context, accommodations[i]);
                                            },
                                            child: Container(
                                              height: 75,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey,
                                                    width: 0.5),
                                                borderRadius: const BorderRadius
                                                    .all(Radius.circular(
                                                        5.0) //         <--- border radius here
                                                    ),
                                              ),
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.all(2),
                                              child: Row(
                                                children: <Widget>[
                                                  Column(
                                                    children: [
                                                      Flexible(
                                                        child: SizedBox(
                                                          width: 100,
                                                          height: 52,
                                                          child: Center(
                                                              child: Text(
                                                                  accommodations[
                                                                          i]
                                                                      ["ref"])),
                                                        ),
                                                      ),
                                                      Flexible(
                                                          child: Container(
                                                              child: Center(
                                                        child:
                                                            _statusAccommodation(
                                                                accommodations[
                                                                        i]
                                                                    ["status"]),
                                                      )))
                                                    ],
                                                  ),
                                                  Flexible(
                                                    flex: 1,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          Text(
                                                              accommodations[i][
                                                                  "internal_name"],
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      // color: Colors.grey,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold)),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          SizedBox(
                                                            width: width,
                                                            child: Text(
                                                              address(
                                                                  accommodations[
                                                                      i]),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 10,
                                                                // color: Colors.grey[500],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          SizedBox(
                                                            width: width,
                                                            child: RichText(
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                text: TextSpan(
                                                                  text: accommodations[
                                                                          i][
                                                                      "external_name"],
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                )),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ));
                                      })
                                ],
                              ),
                            ),
                            Card(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ListTile(
                                    tileColor: Colors.grey[200],
                                    leading: const Icon(Icons.book),
                                    title: const Text("Contracts"),
                                  ),
                                  Container(
                                      child: ListView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          scrollDirection: Axis.vertical,
                                          itemCount:
                                              snapshot.data["contracts"].length,
                                          itemBuilder: (context, i) {
                                            return GestureDetector(
                                                onTap: () {
                                                  showContract(
                                                      context,
                                                      snapshot.data["contracts"]
                                                          [i]["id"]);
                                                },
                                                child: Container(
                                                  height: 90,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey,
                                                        width: 0.5),
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                            Radius.circular(
                                                                5.0) //         <--- border radius here
                                                            ),
                                                  ),
                                                  margin:
                                                      const EdgeInsets.all(8),
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Column(
                                                        children: [
                                                          Flexible(
                                                            child: SizedBox(
                                                              width: 100,
                                                              height: 50,
                                                              child: Center(
                                                                  child: Text(snapshot
                                                                              .data[
                                                                          "contracts"]
                                                                      [
                                                                      i]["ref"])),
                                                            ),
                                                          ),
                                                          Flexible(
                                                              child: Container(
                                                                  child: Center(
                                                            child: _statusContract(
                                                                snapshot.data[
                                                                        "contracts"][i]
                                                                    [
                                                                    "contract_status"]),
                                                          )))
                                                        ],
                                                      ),
                                                      Flexible(
                                                        flex: 1,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(2.0),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: <Widget>[
                                                              Text(
                                                                  snapshot.data["contracts"]
                                                                              [
                                                                              i]
                                                                          [
                                                                          "internal_name"] +
                                                                      " (" +
                                                                      snapshot.data["contracts"]
                                                                              [
                                                                              i]
                                                                          [
                                                                          "name"] +
                                                                      ") ",
                                                                  style: const TextStyle(
                                                                      fontSize: 14,
                                                                      // color: Colors.grey,
                                                                      fontWeight: FontWeight.bold)),
                                                              const SizedBox(
                                                                height: 5,
                                                              ),
                                                              SizedBox(
                                                                width: width,
                                                                child: Text(
                                                                  "${"Start date: " + snapshot.data["contracts"][i]["start_date"]}  \nEnd date:   " +
                                                                      snapshot.data["contracts"]
                                                                              [
                                                                              i]
                                                                          [
                                                                          "end_date"],
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    height: 1.5,
                                                                    // color: Colors.grey[500],
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 5,
                                                              ),
                                                              SizedBox(
                                                                width: width,
                                                                child:
                                                                    const Text(
                                                                  "",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    // color: Colors.grey[500],
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ));
                                          })),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                })
          ])),
    );
  }
}

String address(accommodation) {
  String add1 = accommodation["address1"] ?? "";
  String add2 = accommodation["address2"] ?? "";
  String add3 = accommodation["address3"] ?? "";

  return "$add1, $add2, $add3";
}

showAccommodation(context, accomodation) {
  //print(accomodation.hosting);
  final apiAcc = ApiAccommodation();
  Future<List<SpaceAccommodation>> callApiSpcAcc(id) {
    return apiAcc.spacesAccommodation(id);
  }

  Future<dynamic> callApiAcc(id) {
    return apiAcc.getOneAccommodations(id);
  }

  var chMethodController = TextEditingController();
  var chInFrMethodController = TextEditingController();
  var chInEnMethodController = TextEditingController();
  var chOutFrMethodController = TextEditingController();
  var chOutEnMethodController = TextEditingController();
  var wifiIdentifierController = TextEditingController();
  return showDialog(
      context: context,
      builder: (context) {
        final methods = Methods();
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(15),
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    FutureBuilder(
                        future: callApiAcc(accomodation["id"]),
                        builder: (context, AsyncSnapshot snap) {
                          if (snap.data == null) {
                            return Container(
                              child: const Center(
                                child: Text("Loading..."),
                              ),
                            );
                          } else {
                            var accomodation = snap.data;
                            chMethodController.text = allWordsCapitilize(
                                accomodation.checkingMethod
                                    .replaceAll(RegExp('_'), ' '));
                            chInFrMethodController.text =
                                accomodation.accessInstructionFr.data;
                            chInEnMethodController.text =
                                accomodation.accessInstructionEn.data;
                            chOutFrMethodController.text =
                                accomodation.checkoutInstructionFr.data;
                            chOutEnMethodController.text =
                                accomodation.checkoutInstructionEn.data;
                            wifiIdentifierController.text =
                                accomodation.wifiIdentifiers.data;
                            // print(accomodation);
                            return Column(children: <Widget>[
                              ExpansionTile(
                                title: const Text(
                                  "Accommodation Description",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                children: <Widget>[
                                  Row(children: <Widget>[
                                    methods.label("Reference: "),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    methods.element(accomodation.ref),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                                  Row(children: <Widget>[
                                    methods.label("Status: "),
                                    const SizedBox(
                                      width: 45,
                                    ),
                                    methods.element(methods.allWordsCapitilize(
                                        accomodation.status)),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Internal Name: "),
                                      methods
                                          .element(accomodation.internalName),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("External Name: "),
                                      methods
                                          .element(accomodation.externalName),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Type: "),
                                      const SizedBox(
                                        width: 55,
                                      ),
                                      methods.element(
                                          methods.allWordsCapitilize(
                                              accomodation.typeAccommodation)),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Entire Palace: "),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      methods.element(accomodation.entirePlace
                                          ? "True"
                                          : "False"),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Capacity: "),
                                      const SizedBox(
                                        width: 35,
                                      ),
                                      methods.element(
                                          accomodation.capacity.toString()),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Area(m²): "),
                                      const SizedBox(
                                        width: 35,
                                      ),
                                      methods.element(
                                          accomodation.area.toString()),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Floor Number: "),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      methods.element(
                                          accomodation.floorNumber.toString()),
                                      const SizedBox(
                                        height: 40,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Door Number: "),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      methods.element(accomodation.doorNumber),
                                      const SizedBox(
                                        height: 40,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Has Elevator: "),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      methods.element(accomodation.hasElevator
                                          ? "True"
                                          : "False"),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Desabled Acces: "),
                                      methods.element(accomodation.hasElevator
                                          ? "True"
                                          : "False"),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Description: "),
                                      const SizedBox(
                                        width: 15,
                                      ),
                                      methods.elementText(
                                          accomodation.description),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              ExpansionTile(
                                title: const Text(
                                  "Checks Instructions",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      methods.elementCheck("Check-in Method",
                                          chMethodController, context),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.elementCheck(
                                          "Check-in Instructions-Fr",
                                          chInFrMethodController,
                                          context),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.elementCheck(
                                          "Check-in Instructions-EN",
                                          chInEnMethodController,
                                          context),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.elementCheck(
                                          "Check-out Instructions-FR",
                                          chOutFrMethodController,
                                          context),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.elementCheck(
                                          "Check-out Instructions-EN",
                                          chOutEnMethodController,
                                          context),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              ExpansionTile(
                                title: const Text(
                                  "Location and other informations",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      methods.label("Address: "),
                                      methods.elementAdresseMap(
                                          accomodation.adresse1 +
                                              ", " +
                                              accomodation.adresse2 +
                                              ", " +
                                              accomodation.adresse3),
                                      TextButton(
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(
                                                    text: accomodation
                                                            .adresse1 +
                                                        ", " +
                                                        accomodation.adresse2 +
                                                        ", " +
                                                        accomodation.adresse3))
                                                .then((value) {
                                              //only if ->
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text('Copied')),
                                              );
                                            });
                                          },
                                          child: const Icon(
                                            Icons.copy,
                                            size: 20,
                                            color: Colors.black,
                                          )),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Geolocalisation: "),
                                      methods.element(
                                          "Lat: ${accomodation.latitude}"),
                                      methods.element(
                                          "Long: ${accomodation.longitude}"),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Mailbox Name: "),
                                      methods
                                          .element(accomodation.mailBoxeName),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Mailbox Number: "),
                                      methods
                                          .element(accomodation.mailBoxNumber),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Mailbox Location: "),
                                      methods.elementText(
                                          accomodation.mailBoxLocation),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Heating System: "),
                                      methods.elementText(
                                          accomodation.headingSystem),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods
                                          .label("Public Transport Nearby: "),
                                      methods.elementText(
                                          accomodation.publicTransportNearby),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods
                                          .label("Energie Line Identifier: "),
                                      methods.elementText(
                                          accomodation.energyLineIdentifiere),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods
                                          .label("Telecom Line Identifier: "),
                                      methods.elementText(
                                          accomodation.telecomLineIdentifiere),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Hotplate System: "),
                                      methods.elementText(
                                          accomodation.hotplatesystem),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Coffee Machine Type: "),
                                      methods.elementText(
                                          accomodation.coffeeMachineType),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Wifi Identifiers: "),
                                      methods.elementText(
                                          accomodation.wifiIdentifiers),
                                      TextButton(
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(
                                                    text: accomodation
                                                        .wifiIdentifiers.data))
                                                .then((value) {
                                              //only if ->
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text('Copied')),
                                              );
                                            });
                                          },
                                          child: const Icon(
                                            Icons.copy,
                                            size: 20,
                                            color: Colors.black,
                                          )),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Trash Location: "),
                                      methods.elementText(
                                          accomodation.transactionLocation),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Profil Selection Level: "),
                                      methods.element(
                                          accomodation.profilSelection),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Photos: "),
                                      methods.elementHyperLink(
                                          accomodation.photos),
                                      TextButton(
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(
                                                    text: accomodation.photos))
                                                .then((value) {
                                              //only if ->
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text('Copied')),
                                              );
                                            });
                                          },
                                          child: const Icon(
                                            Icons.copy,
                                            size: 20,
                                            color: Colors.black,
                                          )),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              ExpansionTile(
                                title: const Text(
                                  "Pricing Plan",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                children: [
                                  accomodation.pricingPlan,
                                  TextButton(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                                text: accomodation
                                                    .pricingPlan.data))
                                            .then((value) {
                                          //only if ->
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text('Copied')),
                                          );
                                        });
                                      },
                                      child: const Icon(
                                        Icons.copy,
                                        size: 20,
                                        color: Colors.black,
                                      )),
                                  const SizedBox(
                                    height: 10,
                                  )
                                ],
                              ),
                              ExpansionTile(
                                title: const Text(
                                  "Spaces",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                children: <Widget>[
                                  FutureBuilder(
                                      future: callApiSpcAcc(accomodation.id),
                                      builder: (context, AsyncSnapshot snap) {
                                        if (snap.data == null) {
                                          return Container(
                                            child: const Center(
                                              child: Text("Loading..."),
                                            ),
                                          );
                                        } else {
                                          return Center(
                                            child: ListView.builder(
                                              scrollDirection: Axis.vertical,
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: snap.data.length,
                                              itemBuilder: (context, i) {
                                                return Card(
                                                  child: Column(
                                                    children: <Widget>[
                                                      Row(
                                                        children: [
                                                          methods
                                                              .label("Name: "),
                                                          methods.element(snap
                                                              .data[i].name),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                        ],
                                                      ),
                                                      Row(children: [
                                                        methods.label("Type: "),
                                                        methods.element(
                                                            snap.data[i].type),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                      ]),
                                                      Row(
                                                        children: [
                                                          methods.label(
                                                              "Size(m²): "),
                                                          methods.element(snap
                                                              .data[i].size
                                                              .toString()),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                        ],
                                                      ),
                                                      if (snap.data[i].heigh !=
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.label(
                                                                "Heigh(m): "),
                                                            methods.element(snap
                                                                .data[i].heigh
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbAirConditioner >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Air Condionner: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbHeater
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbHeater >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Heater: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbHeater
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbSingleBed >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Single Beds(90): "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbSingleBed
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbDoubleBed >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Double Beds(140): "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbDoubleBed
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbLargeBed >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Large Beds(160): "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbLargeBed
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbExtraLargeBed >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Extra Large Beds(180): "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbExtraLargeBed
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbSingleSofaBed >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Sofa Beds: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbSingleSofaBed
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbDoubleSofaBed >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number Double Sofa Beds: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbDoubleSofaBed
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i].nbSofa >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number Sofa: "),
                                                            methods.element(snap
                                                                .data[i].nbSofa
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbSingleFloorMattress >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Single Floor Mattress: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbSingleFloorMattress
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbDoubleFloorMattress >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Double Floor Mattress: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbDoubleFloorMattress
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbSingleAirMattress >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Single Air Mattress: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbSingleAirMattress
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbDoubleAirMattress >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Double Air Mattress: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbDoubleAirMattress
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i].nbCrib >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Cribs: "),
                                                            methods.element(snap
                                                                .data[i].nbCrib
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbToddlerBed >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Toddler Beds: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbToddlerBed
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbWaterBed >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Water Beds: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbWaterBed
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        ),
                                                      if (snap.data[i]
                                                              .nbHammock >
                                                          0)
                                                        Row(
                                                          children: [
                                                            methods.labelFlex(
                                                                "Number of Hammocks: "),
                                                            methods.element(snap
                                                                .data[i]
                                                                .nbHammock
                                                                .toString()),
                                                            const SizedBox(
                                                              height: 10,
                                                            )
                                                          ],
                                                        )
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        }
                                      })
                                ],
                              ),
                            ]);
                          }
                        }),
                  ],
                ),
              ),
            ),
          ),
        );
      });
}

Widget _statusAccommodation(status) {
  if (status == "exploiting") {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: const Color(0xFF05A8CF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(allWordsCapitilize(status),
          style: const TextStyle(fontSize: 10, color: Colors.white)),
    );
  } else if (status == "prospecting") {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        allWordsCapitilize(status),
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  } else {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(allWordsCapitilize(status),
          style: const TextStyle(fontSize: 10, color: Colors.white)),
    );
  }
}

String allWordsCapitilize(String str) {
  return str.toLowerCase().split(' ').map((word) {
    String leftText = (word.length > 1) ? word.substring(1, word.length) : '';
    return word[0].toUpperCase() + leftText;
  }).join(' ');
}

showContract(context, id) {
  final apiAcc = ApiAccommodation();
  Future<dynamic> callApiContract(id) {
    return apiAcc.getOneContract(id);
  }

  final methods = Methods();
  return showDialog(
    context: context,
    builder: (context) {
      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(15),
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FutureBuilder(
                      future: callApiContract(id),
                      builder: (context, AsyncSnapshot snap) {
                        var contract = snap.data;
                        if (snap.data == null) {
                          return Container(
                            child: const Center(
                              child: Text("Loading..."),
                            ),
                          );
                        } else {
                          return Column(children: [
                            ExpansionTile(
                                title: const Text(
                                  "Base Information",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                children: [
                                  Row(
                                    children: <Widget>[
                                      methods.label("Reference: "),
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      methods.element(contract.ref),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Status: "),
                                      const SizedBox(
                                        width: 45,
                                      ),
                                      methods.element(methods
                                          .allWordsCapitilize(contract.status)),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Offer: "),
                                      const SizedBox(
                                        width: 55,
                                      ),
                                      methods.element(contract.offer),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Currency: "),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      methods.element(contract.currency),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Accommodation: "),
                                      const SizedBox(
                                        width: 0,
                                      ),
                                      methods.element(contract.accommodation),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Partner: "),
                                      const SizedBox(
                                        width: 40,
                                      ),
                                      methods.element(contract.partner),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Partner type: "),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      methods.element(
                                          methods.allWordsCapitilize(
                                              contract.partnerType)),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Start date: "),
                                      const SizedBox(
                                        width: 25,
                                      ),
                                      methods.element(contract.startDate),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("End date: "),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      methods.element(contract.endDate),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Commitment period: "),
                                      const SizedBox(
                                        width: 0,
                                      ),
                                      methods.element(
                                          contract.commitmentPeriod.toString()),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      methods.label("Signing date: "),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      methods.element(contract.endDate),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                ]),
                            ExpansionTile(
                              title: const Text(
                                "Cost Information",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              children: [
                                Row(
                                  children: [
                                    methods.label("Commission:"),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    methods.element(contract.offer == "Chic'Zen"
                                        ? "${contract.commission} " +
                                            contract.currency
                                        : "${contract.commission} %"),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    methods.label("Guaranteed deposit:"),
                                    const SizedBox(
                                      width: 0,
                                    ),
                                    methods.element(
                                        "${contract.guaranteedDeposit} " +
                                            contract.currency),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    methods.label("Cleaning fees:"),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    methods.element(
                                        "${contract.cleaningFees} " +
                                            contract.currency),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  children: [
                                    methods.label("Cleaning fees for partner:"),
                                    const SizedBox(
                                      width: 0,
                                    ),
                                    methods.element(
                                        "${contract.cleaningFeesForPartner} " +
                                            contract.currency),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    methods.label("Travelers deposit:"),
                                    const SizedBox(
                                      width: 0,
                                    ),
                                    methods.element(
                                        "${contract.travelersDeposit} " +
                                            contract.currency),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    methods.label("Emergency envelope:"),
                                    const SizedBox(
                                      width: 0,
                                    ),
                                    methods.element(
                                        "${contract.emergencyEnvelop} " +
                                            contract.currency),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    methods.label("Supplies base price:"),
                                    const SizedBox(
                                      width: 0,
                                    ),
                                    methods.element(
                                        "${contract.suppliesBasePrise} " +
                                            contract.currency),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ExpansionTile(
                              title: const Text(
                                "Payment Process Details",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              children: [
                                Row(
                                  children: [
                                    methods.label("IBAN:"),
                                    const SizedBox(
                                      width: 45,
                                    ),
                                    methods.element(contract.iban),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    methods.label("BIC:"),
                                    const SizedBox(
                                      width: 55,
                                    ),
                                    methods.element(contract.bic),
                                    const SizedBox(
                                      height: 50,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    methods.label("Bank Owner:"),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    methods.element(contract.bankOwner),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    methods.label("Bank name:"),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    methods.element(contract.bankName),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    methods.label("Bank country:"),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    methods.element(contract.bankCountry),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    methods.label("Payment Date :"),
                                    const SizedBox(
                                      width: 0,
                                    ),
                                    methods.element(contract.paymentDate +
                                        " (day in month)"),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ExpansionTile(
                              title: const Text(
                                "Additional Details",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              children: [
                                Row(
                                  children: [
                                    methods.label("Is breakfast included ? :"),
                                    const SizedBox(
                                      width: 17,
                                    ),
                                    methods.element(contract.breakfastIncluded
                                        ? "True"
                                        : "False"),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    methods.label("Supplies managed by :"),
                                    const SizedBox(
                                      width: 17,
                                    ),
                                    methods.element(contract.suppliesManageBy),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    methods.label("Retraction delay :"),
                                    const SizedBox(
                                      width: 17,
                                    ),
                                    methods.element(
                                        "${contract.retractionDelay} days"),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    methods.label("Cleaning duration  :"),
                                    const SizedBox(
                                      width: 17,
                                    ),
                                    methods.element(
                                        "${contract.cleaningDuration} minutes per person"),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    methods
                                        .label("Termination notice duration :"),
                                    const SizedBox(
                                      width: 17,
                                    ),
                                    methods.element(
                                        "${contract.terminaisonNotice} months"),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    methods
                                        .label("Reservation notice duration :"),
                                    const SizedBox(
                                      width: 17,
                                    ),
                                    methods.element(
                                        "${contract.reservationNotice} months"),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    methods.label("Partner booking range :"),
                                    const SizedBox(
                                      width: 17,
                                    ),
                                    methods.element(
                                        "${contract.partnerBookingRange} months"),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    methods.label("Special clauses :"),
                                    const SizedBox(
                                      width: 17,
                                    ),
                                    methods.elementText(contract.specialClose),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ExpansionTile(
                              title: const Text(
                                "Supplies List",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              children: [
                                Center(
                                  child: ListView.builder(
                                      scrollDirection: Axis.vertical,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: contract.supplies.length,
                                      itemBuilder: (context, i) {
                                        return Card(
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    methods.label("Name:"),
                                                    const SizedBox(
                                                      width: 15,
                                                    ),
                                                    methods.element(contract
                                                        .supplies[i]["name"]),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    methods.label("Price:"),
                                                    const SizedBox(
                                                      width: 20,
                                                    ),
                                                    methods.element(
                                                        "${contract.supplies[i]["price"]} " +
                                                            contract.currency),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    methods.label("Quantity:"),
                                                    const SizedBox(
                                                      width: 0,
                                                    ),
                                                    methods.element(contract
                                                        .supplies[i]["quantity"]
                                                        .toString()),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    methods.label("Total:"),
                                                    const SizedBox(
                                                      width: 20,
                                                    ),
                                                    methods.element(
                                                        "${product(int.parse(contract.supplies[i]["quantity"].toString()), double.parse(contract.supplies[i]["price"].toString()))} " +
                                                            contract.currency),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                )
                              ],
                            )
                          ]);
                        }
                      })
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _statusContract(status) {
  if (status == "active") {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: const Color(0xFF05A8CF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(allWordsCapitilize(status),
          style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  } else if (status == "draft") {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        allWordsCapitilize(status),
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  } else {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(allWordsCapitilize(status),
          style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  }
}

double product(int a, double b) {
  double temp = 0;
  while (a != 0) {
    temp += b;
    a--;
  }
  return temp;
}
