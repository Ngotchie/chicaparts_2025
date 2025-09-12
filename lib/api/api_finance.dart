import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/retry.dart';
import 'package:chicaparts_partner/models/model_finance.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:http/http.dart' as http;

class ApiFinance {
  ApiUrl url = ApiUrl();
  Future<dynamic> getMonthlyReports(partner, filter) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse(
              "${apiUrl}apikey/partners/monthly-report?partner=$partner&keyword=" +
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

  Future<dynamic> getOneReport(id) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse(
              "${apiUrl}apikey/partners/monthly-report/$id?no-relation=1"),
          headers: {
            'Accept': 'application/json',
            'X-Authorization': apiKey,
          });
      if (data.statusCode == 200) {
        var jsonData = jsonDecode(data.body);
        var getData = jsonData['data'];
        MonthlyRepport mr = MonthlyRepport(
          id,
          getData['accommodationRef'] ?? "",
          getData['external_name'] ?? "",
          getData['description'] != null
              ? Text(getData['description'])
              : const Text(""),
          getData['type_accommodation'] ?? "",
          getData['address1'] ?? "",
          getData['address2'] ?? "",
          getData['address3'] ?? "",
          getData['ref'] ?? "",
          getData['name'] ?? "",
          getData['start_date_str'] ?? "",
          getData['end_date_str'] ?? "",
          getData['report_lines'] ?? [],
          getData['occasional_losses'] ?? [],
          getData['occasional_gains'] ?? [],
          getData['status'] ?? "",
          getData['code'] ?? "",
          getData['total_payout'] ?? "",
          getData['total_supplies_price'] ?? 0,
          getData['total_occasional_fees'] ?? 0,
          getData['total_occasional_gains'] ?? 0,
          getData['total_chic_partner'] ?? 0,
          getData['blocked_nights'] ?? 0,
          getData['total_available_nights'] ?? 0,
          getData['total_occupied_nights'] ?? 0,
          getData['occupacy_rate'] ?? 0,
          getData['iban'] ?? "",
          getData['bank_owner'] ?? "",
          getData['bic'] ?? "",
          getData['supplies_base_price'] ?? 0,
        );
        return mr;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      client.close();
      return e;
    }
  }

  Future<dynamic> getPaymentOrders(partner, filter) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse(
              "${apiUrl}apikey/partners/payment-orders?partner=$partner&keyword=" +
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

  Future<dynamic> getPayouts(partner, filter) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse(
              "${apiUrl}apikey/partners/payouts?partner=$partner&no-relation=-1&keyword=" +
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

  Future<dynamic> getYearlyPayouts(partner, filter) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse(
              "${"${apiUrl}apikey/partners/payouts?partner=$partner&no-relation=1&keyword=" + filter}&year=1"),
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

  Future<dynamic> getOnePayout(id) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse("${apiUrl}apikey/partners/payout/$id?no-relation=1"),
          headers: {
            'Accept': 'application/json',
            'X-Authorization': apiKey,
          });
      if (data.statusCode == 200) {
        var jsonData = jsonDecode(data.body);
        var getData = jsonData['data'];
        Payout pt = Payout(
            id,
            getData['ref'],
            getData['contract_ref'],
            getData['accommodation_ref'],
            getData['internal_name'],
            getData['period_start'],
            getData['period_end'],
            getData['code'],
            getData['amount'],
            getData['supplies'],
            getData['chic_partner'],
            getData['og_amount'],
            getData['ol_amount'],
            getData['payout_date']);

        return pt;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      client.close();
      return e;
    }
  }

  Future<dynamic> dataForPdf(accommodation) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse(
              "${apiUrl}apikey/partners/yearly_pdf?accommodation=$accommodation"),
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

  // Future<File> generatePdf(contract, year) async {
  //   String apiUrl = url.getUrl();
  //   String apiKey = url.getKey();
  //   var client = RetryClient(http.Client());
  //   var data = await client.get(
  //       Uri.parse(apiUrl +
  //           'tools/document/download?document=DOC00006&object=' +
  //           contract.toString() +
  //           '&year=' +
  //           year +
  //           '&save=false'),
  //       headers: {
  //         'Accept': 'application/json',
  //         'Access-Control-Allow-Origin': '*',
  //         'Access-Control-Allow-Headers': '*',
  //         'X-Authorization': apiKey,
  //       });
  //   // var jsonData = jsonDecode(data.body);
  //   Directory tempDir = await getTemporaryDirectory();
  //   String tempPath = tempDir.path;
  //   File file = new File('$tempPath/$year.pdf');
  //   await file.writeAsBytes(data.bodyBytes);
  //   return file;
  // }
}
