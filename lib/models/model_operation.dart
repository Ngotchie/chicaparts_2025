import 'package:flutter/material.dart';

class Maintenance {
  int id;
  String ref;
  String accommodation;
  String title;
  num estimation;
  num realCost;
  String handler;
  String priority;
  String step;
  String nature;
  String status;
  String fixedDate;
  num completion;
  String logDate;
  Text description;
  String currency;
  String refAccommodation;

  Maintenance(
      this.id,
      this.ref,
      this.accommodation,
      this.title,
      this.estimation,
      this.realCost,
      this.handler,
      this.priority,
      this.step,
      this.nature,
      this.status,
      this.fixedDate,
      this.completion,
      this.logDate,
      this.description,
      this.currency,
      this.refAccommodation);
}

class Sinister {
  int id;
  String ref;
  String requester;
  String refAccommodation;
  String accommodation;
  String referer;
  String apiReference;
  String guestFirstName;
  String guestName;
  String firstNight;
  String lastNight;
  String currency;
  String title;
  String status;
  String foundDate;
  String folderLink;
  Text description;
  String guaranteeType;
  String paymentStatus;
  num refundedAmount;
  String ticketRef;
  String ticketLink;
  num requestedAmount;
  String startDate;
  String closeDate;
  dynamic actions;

  Sinister(
      this.id,
      this.ref,
      this.requester,
      this.refAccommodation,
      this.accommodation,
      this.referer,
      this.apiReference,
      this.guestFirstName,
      this.guestName,
      this.firstNight,
      this.lastNight,
      this.currency,
      this.title,
      this.status,
      this.foundDate,
      this.folderLink,
      this.description,
      this.guaranteeType,
      this.paymentStatus,
      this.refundedAmount,
      this.ticketRef,
      this.ticketLink,
      this.requestedAmount,
      this.startDate,
      this.closeDate,
      this.actions);
}
