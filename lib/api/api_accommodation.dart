import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:chicaparts_partner/models/model_accommodation.dart';
import 'dart:convert';
import 'dart:async';

import 'package:chicaparts_partner/services/api.dart';

class ApiAccommodation {
  ApiUrl url = ApiUrl();

  Future<dynamic> getOneAccommodations(id) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse('${apiUrl}apikey/hostings/accommodation/$id'),
          headers: {
            'Accept': 'application/json',
            'X-Authorization': apiKey,
          });
      if (data.statusCode == 200) {
        var jsonData = jsonDecode(data.body);
        var accomodation = jsonData["data"];
        OneAccommodation acc = OneAccommodation(
          accomodation["id"],
          accomodation["ref"] ?? "",
          accomodation["status"] ?? "",
          accomodation["internal_name"] ?? "",
          accomodation["external_name"] ?? "",
          accomodation["other_name"] ?? "",
          accomodation["type_accommodation"] ?? "",
          accomodation["checkin_method"] ?? "",
          accomodation["entire_place"] ?? false,
          accomodation["capacity"] ?? 0,
          accomodation["area"] ?? 0,
          accomodation["floor_number"] ?? 0,
          accomodation["door_number"] ?? "",
          accomodation["has_elevator"] ?? false,
          accomodation["self_checkin"] ?? false,

          // Strings simples → Text(...)
          accomodation["description"] != null
              ? Text(accomodation["description"])
              : const Text(""),
          accomodation["details"] != null
              ? Text(accomodation["details"])
              : const Text(""),
          accomodation["access_instruction_fr"] != null
              ? Text(accomodation["access_instruction_fr"])
              : const Text(""),

          // Numériques
          (accomodation["latitude"] ?? 0).toDouble(),
          (accomodation["longitude"] ?? 0).toDouble(),

          // URL photos (string)
          accomodation["photos"] ?? "",

          // mailbox_* (nouveaux noms, fallback anciens)
          (accomodation["mailbox_location"] ??
                      accomodation["mail_box_location"]) !=
                  null
              ? Text(accomodation["mailbox_location"] ??
                  accomodation["mail_box_location"])
              : const Text(""),
          accomodation["mailbox_number"] ??
              accomodation["mail_box_number"] ??
              "",
          accomodation["mailbox_name"] ?? accomodation["mail_boxe_name"] ?? "",

          // Adresse
          accomodation["address1"] ?? "",
          accomodation["address2"] ?? "",
          accomodation["address3"] ?? "",
          accomodation["state"] ?? "",
          accomodation["country_id"] ?? 0,
          accomodation["city"] ?? "",
          accomodation["zip"] ?? "",

          // access_instructions_* (nouveaux noms, fallback anciens)
          (accomodation["access_instructions_to_the_building"] ??
                      accomodation["access_instruction_to_the_building"]) !=
                  null
              ? Text(accomodation["access_instructions_to_the_building"] ??
                  accomodation["access_instruction_to_the_building"])
              : const Text(""),
          (accomodation["access_instructions_to_the_apartment"] ??
                      accomodation["access_instruction_to_the_apartment"]) !=
                  null
              ? Text(accomodation["access_instructions_to_the_apartment"] ??
                  accomodation["access_instruction_to_the_apartment"])
              : const Text(""),

          // *company_details (nouveaux noms)
          accomodation["building_management_company_details"] != null
              ? Text(accomodation["building_management_company_details"])
              : const Text(""),
          accomodation["elevator_management_company_details"] != null
              ? Text(accomodation["elevator_management_company_details"])
              : const Text(""),

          // heating_system (nouveau)  — ancien: heading_transport (on garde en fallback visuel)
          (accomodation["heating_system"] ??
                      accomodation["heading_transport"]) !=
                  null
              ? Text(accomodation["heating_system"] ??
                  accomodation["heading_transport"])
              : const Text(""),

          // public_transports_nearby (nouveau)
          accomodation["public_transports_nearby"] != null
              ? Text(accomodation["public_transports_nearby"])
              : const Text(""),

          // energy_line_identifier (nouveau)
          accomodation["energy_line_identifier"] != null
              ? Text(accomodation["energy_line_identifier"])
              : const Text(""),

          // access_instruction_en (string → Text)
          accomodation["access_instruction_en"] != null
              ? Text(accomodation["access_instruction_en"])
              : const Text(''),

          // checkout_instructions_*
          accomodation["checkout_instructions_en"] != null
              ? Text(accomodation["checkout_instructions_en"])
              : const Text(""),
          accomodation["checkout_instructions_fr"] != null
              ? Text(accomodation["checkout_instructions_fr"])
              : const Text(""),

          // coffee_machine_type
          accomodation["coffee_machine_type"] != null
              ? Text(accomodation["coffee_machine_type"])
              : const Text(""),

          // currency → l'API renvoie désormais currency_id (int). On garde String attendu.
          (accomodation["currency"] ??
              (accomodation["currency_id"] != null
                  ? accomodation["currency_id"].toString()
                  : "")),

          // disabled_access (nouveau)
          accomodation["disabled_access"] ??
              accomodation["disable_acces"] ??
              false,

          // hotplate_system (nouveau)
          accomodation["hotplate_system"] != null
              ? Text(accomodation["hotplate_system"])
              : const Text(""),

          // pricing_plan (string → Text)
          accomodation["pricing_plan"] != null
              ? Text(accomodation["pricing_plan"])
              : const Text(""),

          // profile_selection (nouveau)
          accomodation["profile_selection"] ??
              accomodation["profil_selection"] ??
              "",

          // telcom_line_identifier (nouveau)
          (accomodation["telcom_line_identifier"] ??
                      accomodation["telecomLine_identifiere"]) !=
                  null
              ? Text(accomodation["telcom_line_identifier"] ??
                  accomodation["telecomLine_identifiere"])
              : const Text(""),

          // trash_location (nouveau)
          (accomodation["trash_location"] ??
                      accomodation["transaction_location"]) !=
                  null
              ? Text(accomodation["trash_location"] ??
                  accomodation["transaction_location"])
              : const Text(""),

          // wifi_identifiers (string → Text)
          accomodation["wifi_identifiers"] != null
              ? Text(accomodation["wifi_identifiers"])
              : const Text(""),

          // hosting_platforms (liste telle quelle)
          accomodation["hosting_platforms"],
        );

        return acc;
      } else {
        return null;
      }
      // accommodations.add(newAcc);
    } catch (e) {
      client.close();
      return e;
    }
  }

  Future<dynamic> getAccommodations(partner) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data = await client.get(
          Uri.parse("${apiUrl}apikey/partners/properties/$partner"),
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

  Future<List<SpaceAccommodation>> spacesAccommodation(id) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    List<SpaceAccommodation> spacesAccommodation = [];
    try {
      var data = await client.get(
          Uri.parse('${apiUrl}hostings/accommodation_space/$id'),
          headers: {
            'Accept': 'application/json',
            'X-Authorization': apiKey,
          });
      //print(data.body);
      var jsonData = jsonDecode(data.body);
      for (var space in jsonData["data"]) {
        SpaceAccommodation sp = SpaceAccommodation(
          space["name"] ?? "",
          space["nb_double_bed"] ?? 0,
          space["nb_heater"] ?? 0,
          space["size"] ?? 0,
          space["heigh"] != null ? double.parse(space["heigh"]) : 0,
          space["type_space"] ?? "",
          space["nb_air_conditioner"] ?? 0,
          space["nb_air_crib"] != null ? space["nb_crib"] : 0,
          space["nb_double_air_mattress"] ?? 0,
          space["nb_double_sofa_bed"] ?? 0,
          space["nb_extra_large_bed"] ?? 0,
          space["nb_hammock"] ?? 0,
          space["nb_large_bed"] ?? 0,
          space["nb_single_air_mattress"] ?? 0,
          space["nb_single_bed"] ?? 0,
          space["nb_single_floor_mattress"] ?? 0,
          space["nb_double_floor_mattress"] ?? 0,
          space["nb_single_sofa_bed"] ?? 0,
          space["nb_sofa"] ?? 0,
          space["nb_toddler_bled"] != null ? space["nb_toddler_bed"] : 0,
          space["nb_water_bed"] ?? 0,
        );
        spacesAccommodation.add(sp);
      }
    } catch (e) {
      client.close();
    }
    //print(spacesAccommodation);
    return spacesAccommodation;
  }

  Future<dynamic> getOneContract(id) async {
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    try {
      var data =
          await client.get(Uri.parse("${apiUrl}apikey/contract/$id"), headers: {
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      });
      if (data.statusCode == 200) {
        var contract = jsonDecode(data.body);
        contract = contract[0];
        var bName = contract["business_name"] ?? "";
        var fName = contract["first_name"] ?? "";
        var lName = contract["last_name"] ?? "";
        var supplies = jsonDecode(contract["supplies_list"]);
        OneContract cnt = OneContract(
            contract["id"],
            contract["ref"] ?? "",
            contract["name"] ?? "",
            contract["status"] ?? "",
            contract["currency"] ?? "",
            contract["accommodation"] ?? "",
            bName + "" + fName + " " + lName,
            contract["partner_type"] ?? "",
            contract["start_date"] ?? "",
            contract["end_date"] ?? "",
            contract["commitment_period_in_months"] ?? 0,
            contract["contract_signing_date"] ?? "",
            contract["commission_rate"] ?? 0,
            contract["guaranteed_deposit"] ?? 0,
            contract["cleaning_fees"] ?? 0,
            contract["cleaning_fees_for_partner"] ?? 0.0,
            contract["travelers_deposit"] ?? 0,
            contract["emergency_envelope"] ?? 0,
            contract["supplies_base_price"] ?? 0,
            contract["bank_details"] != null
                ? Text(contract["bank_details"])
                : const Text(""),
            contract["iban"] ?? "",
            contract["bic"] ?? "",
            contract["bank_owner"] ?? "",
            contract["bank_name"] ?? "",
            contract["bank_country"] ?? "",
            contract["payment_date"] ?? "",
            contract["breakfast_included"] ?? false,
            contract["supplies_managed_by"] ?? "",
            contract["retraction_delay"] ?? 0,
            contract["cleaning_duration"] ?? 0,
            contract["termination_notice_duration"] ?? 0,
            contract["reservation_notice_duration"] ?? 0,
            contract["partner_booking_range"] ?? 0,
            contract["special_clauses"] != null
                ? Text(contract["special_clauses"])
                : const Text(""),
            supplies);

        return cnt;
      } else {
        return null;
      }
    } catch (e) {
      return e;
    }
  }
}
