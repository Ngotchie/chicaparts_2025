import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:chicaparts_partner/models/model_operation.dart';
import 'dart:convert';
import 'dart:async';

import 'package:chicaparts_partner/services/api.dart';

class ApiOperation {
  ApiUrl url = ApiUrl();

  Future<dynamic> getMaintenances(partner, pending, nature) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse(
              "${apiUrl}apikey/partners/maintenances?partner=$partner&pending=$pending&keyword=" +
                  nature),
          headers: {
            'Accept': 'application/json',
            'X-Authorization': apiKey,
          });
      var jsonData = jsonDecode(data.body);
      return jsonData;
    } catch (e) {
      print(e);
      client.close();
      return e;
    }
  }

  Future<dynamic> getSinisters(partner, pending, filter) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse(
              "${apiUrl}apikey/partners/sinisters?partner=$partner&pending=$pending&keyword=" +
                  filter),
          headers: {
            'Accept': 'application/json',
            'X-Authorization': apiKey,
          });
      var jsonData = jsonDecode(data.body);
      return jsonData;
    } catch (e) {
      print(e);
      client.close();
      return e;
    }
  }

  Future<dynamic> getOneMaintenance(id) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client
          .get(Uri.parse("${apiUrl}apikey/one/maintenance/$id"), headers: {
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      });
      if (data.statusCode == 200) {
        var jsonData = jsonDecode(data.body);
        Maintenance mt = Maintenance(
          id,
          jsonData["ref"] ?? "",
          jsonData["accommodation"] ?? "",
          jsonData["title"] ?? "",
          jsonData["estimation"] ?? 0,
          jsonData["real_cost"] ?? 0,
          jsonData["handler"] ?? "",
          jsonData["priority"] ?? "",
          jsonData["step"] ?? "",
          jsonData["natures"] ?? "",
          jsonData["status"] ?? "",
          jsonData["fixed_date"] ?? "",
          jsonData["fixed_percentage"] != null
              ? int.parse(jsonData["fixed_percentage"])
              : 0,
          jsonData["log_date"] ?? "",
          jsonData["description"] != null
              ? Text(jsonData["description"])
              : const Text(""),
          jsonData["currency"] ?? "",
          jsonData["ref_accommodation"] ?? "",
        );

        return mt;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      client.close();
      return e;
    }
  }

  Future<dynamic> getOneSinister(id) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client
          .get(Uri.parse("${apiUrl}apikey/one/sinister/$id"), headers: {
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      });
      if (data.statusCode == 200) {
        var jsonData = jsonDecode(data.body);
        Sinister sn = Sinister(
            id,
            jsonData["ref"] ?? "",
            jsonData["author"] ?? "",
            jsonData["ref_accommodation"] ?? "",
            jsonData["accommodation"] ?? "",
            jsonData["referer"] ?? "",
            jsonData["apiReference"] ?? "",
            jsonData["guestFirstName"] ?? "",
            jsonData["guestName"] ?? "",
            jsonData["firstNight"] ?? "",
            jsonData["lastNight"] ?? "",
            jsonData["currency"] ?? "",
            jsonData["title"] ?? "",
            jsonData["status"] ?? "",
            jsonData["found_date"] ?? "",
            jsonData["folder_link"] ?? "",
            jsonData["description"] != null
                ? Text(jsonData["description"])
                : const Text(""),
            jsonData["guarantee_type"] ?? "",
            jsonData["payment_status"] ?? "",
            jsonData["refunded_amount"] ?? 0,
            jsonData["ticket_ref"] ?? "",
            jsonData["ticket_link"] ?? "",
            jsonData["requested_amount"] ?? 0,
            jsonData["start_date"] ?? "",
            jsonData["close_date"] ?? "",
            jsonData["actions"] ?? []);

        return sn;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      client.close();
      return e;
    }
  }
}
