import 'package:flutter/material.dart';

class MonthlyRepport {
  int id;
  String accommodationRef;
  String externalName;
  Text accommodationDescription;
  String accommodationType;
  String address1;
  String address2;
  String address3;
  String monthlyRef;
  String offer;
  String startDate;
  String endDate;
  dynamic reportLine;
  dynamic occasionalFees;
  dynamic occasionalGains;
  String status;
  String currency;
  num totalPayout;
  num supplies;
  num totalOccasionalFees;
  num totalOccasionalGain;
  num chicPartner;
  int blockedNight;
  int availableNight;
  int occupiedNight;
  num occupationRate;
  String iban;
  String bankOwner;
  String bic;
  String suppliesBase;
  MonthlyRepport(
      this.id,
      this.accommodationRef,
      this.externalName,
      this.accommodationDescription,
      this.accommodationType,
      this.address1,
      this.address2,
      this.address3,
      this.monthlyRef,
      this.offer,
      this.startDate,
      this.endDate,
      this.reportLine,
      this.occasionalFees,
      this.occasionalGains,
      this.status,
      this.currency,
      this.totalPayout,
      this.supplies,
      this.totalOccasionalFees,
      this.totalOccasionalGain,
      this.chicPartner,
      this.blockedNight,
      this.availableNight,
      this.occupiedNight,
      this.occupationRate,
      this.iban,
      this.bankOwner,
      this.bic,
      this.suppliesBase);
}

class Payout {
  int id;
  String ref;
  String contractRef;
  String accommodationRef;
  String internalName;
  String periodStart;
  String periodEnd;
  String currency;
  num amount;
  String supplies;
  num chicPartner;
  num occasionalGain;
  num occasionalFees;
  String payoutDate;
  Payout(
      this.id,
      this.ref,
      this.contractRef,
      this.accommodationRef,
      this.internalName,
      this.periodStart,
      this.periodEnd,
      this.currency,
      this.amount,
      this.supplies,
      this.chicPartner,
      this.occasionalGain,
      this.occasionalFees,
      this.payoutDate);
}

class TabButton extends StatefulWidget {
  const TabButton(
      {super.key,
      required this.title,
      required this.pageNumber,
      required this.selectedPage,
      required this.onPressed});
  final String title;
  final int pageNumber;
  final int selectedPage;
  final VoidCallback onPressed;

  @override
  _TabButtonState createState() => _TabButtonState();
}

class _TabButtonState extends State<TabButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(microseconds: 1000),
        curve: Curves.fastLinearToSlowEaseIn,
        decoration: BoxDecoration(
            color: widget.selectedPage == widget.pageNumber
                ? Colors.orangeAccent[100]
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4)),
        padding: EdgeInsets.symmetric(
            vertical: widget.selectedPage == widget.pageNumber ? 8 : 4,
            horizontal: widget.selectedPage == widget.pageNumber ? 15 : 7),
        margin: EdgeInsets.symmetric(
            vertical: widget.selectedPage == widget.pageNumber ? 5 : 0,
            horizontal: widget.selectedPage == widget.pageNumber ? 8 : 2),
        child: Text(
          widget.title,
          style: const TextStyle(),
        ),
      ),
    );
  }
}
