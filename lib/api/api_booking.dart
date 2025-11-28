import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/retry.dart';
import 'package:http/http.dart' as http;
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/services/api.dart';

class ApiBooking {
  ApiUrl url = ApiUrl();
  Future<List<Booking>> getBookings(partner, range, type) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    List<Booking> bookings = [];
    var se = range.split("=>");
    try {
      var data = await client.get(
          Uri.parse(
              '${'${apiUrl}apikey/partners/booking?partner=$partner&start=' + se[0] + '&end=' + se[1]}&type=' +
                  type),
          headers: {
            'Accept': 'application/json',
            'X-Authorization': apiKey,
          });
      // print(data.body);
      var jsonData = jsonDecode(data.body);
      for (var book in jsonData["data"]) {
        Booking booking = Booking(
          book["id"] ?? 0,
          book["bookId"] ?? 0,
          book["accommodation"] ?? "",
          book["lastNight"] ?? "",
          book["firstNight"] ?? "",
          book["bookingTime"] ?? "",
          book["guestFirstName"] ?? "",
          book["guestName"] ?? "",
          book["referer"] ?? "",
          book["status"] ?? 0,
          book["price"] ?? 0,
          book["currency"] ?? "",
          book["guestArrivalTime"] ?? "",
          book["numAdult"] ?? 0,
          book["numChild"] ?? 0,
          book["guestArrivalTime"] ?? "",
          book["validation_status"] ?? "",
          book["notes"] != null ? Text(book["notes"]) : const Text(""),
          book["roomId"] ?? 0,
          book["propId"] ?? 0,
          "",
          "",
          book["multiplier"] ?? "Not defined",
        );

        bookings.add(booking);
      }
    } catch (e) {
      client.close();
    }
    return bookings;
  }

  Future<dynamic> getData(partner) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse("${apiUrl}apikey/new/booking/infos/$partner"),
          headers: {
            'Accept': 'application/json',
            'X-Authorization': apiKey,
          });
      var jsonData = jsonDecode(data.body);
      return jsonData;
    } catch (e) {
      client.close();
      return e;
    }
  }

  Future<int> postBlockDate(formData) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.post(Uri.parse('${apiUrl}apikey/block/date'),
          headers: {
            'Accept': 'application/json',
            'content-type': 'application/json',
            'X-Authorization': apiKey,
          },
          body: jsonEncode(formData));

      return data.statusCode;
    } catch (e) {
      client.close();
      return throw Exception(e);
    }
  }

  Future<int> editBlockDate(formData, id) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.put(Uri.parse('${apiUrl}apikey/block/date/$id'),
          headers: {
            'Accept': 'application/json',
            'content-type': 'application/json',
            'X-Authorization': apiKey,
          },
          body: jsonEncode(formData));

      return data.statusCode;
    } catch (e) {
      client.close();
      return throw Exception(e);
    }
  }

  Future<dynamic> getOneBooking(id) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data =
          await client.get(Uri.parse("${apiUrl}apikey/booking/$id"), headers: {
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      });
      if (data.statusCode == 200) {
        var jsonData = jsonDecode(data.body);
        var booking = jsonData;
        OneBooking oneBooking = OneBooking(
            id,
            booking["referer"] ?? "",
            booking["bookId"] ?? 0,
            booking["propId"] ?? 0,
            booking["roomId"] ?? 0,
            booking["bookingTime"] ?? "",
            booking["firstNight"] ?? "",
            booking["lastNight"] ?? "",
            booking["numAdult"] ?? 0,
            booking["numChild"] ?? 0,
            booking["guestArrivalTime"] ?? "",
            booking["guestTitle"] ?? "",
            booking["guestFirstName"] ?? "",
            booking["guestName"] ?? "Partner",
            booking["guestEmail"] ?? "",
            booking["guestPhone"] ?? "",
            booking["guestMobile"] ?? "",
            booking["guestFax"] ?? "",
            booking["guestCompagny"] ?? "",
            booking["guestAddress"] ?? "",
            booking["guestCity"] ?? "",
            booking["guestState"] ?? "",
            booking["guestPostCode"] ?? "",
            booking["guestCountry"] ?? "",
            booking["guestComments"] != null
                ? Text(booking["guestComments"])
                : const Text(""),
            booking["notes"] != null ? Text(booking["notes"]) : const Text(""),
            booking["price"] ?? 0,
            booking["deposit"] ?? 0,
            booking["tax"] ?? 0,
            booking["commission"] ?? 0,
            booking["cleaning_fees_partner"] ?? 0,
            booking["transaction_fees"] ?? 0,
            booking["booking_fees"] ?? 0,
            booking["currency"] ?? "",
            booking["rateDescription"] != null
                ? Text(booking["rateDescription"])
                : const Text(""),
            booking["currency_id"] ?? 0,
            booking["validation_status"] ?? "");
        return oneBooking;
      } else {
        return null;
      }
      // accommodations.add(newAcc);
    } catch (e) {
      client.close();
      return e;
    }
  }
}
