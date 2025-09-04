import 'package:flutter/material.dart';
import 'package:vault_trip/views/home/component/document_section.dart';
import 'package:vault_trip/views/home/component/point_of_interest_section.dart';
import 'package:vault_trip/views/home/component/travel_plan_section.dart';

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: TravelPlanSectionWidget()),
        Expanded(child: PointOfInterestSectionWidget()),
        Expanded(child: DocumentSectionWidget()),
      ],
    );
  }
}