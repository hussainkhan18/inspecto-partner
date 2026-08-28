import 'package:flutter/material.dart';

class DisplayScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DisplayScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Report ID: ${data['report_id']}'),
            Text('Equipment ID: ${data['equipment_id']}'),
            Text('Checklist ID: ${data['checklist_id']}'),
            Text('Equipment Category: ${data['equipment_category']}'),
            Text('Equipment Sub Category: ${data['equipment_sub_category']}'),
            Text('Equipment Type: ${data['equipment_type']}'),
            Text('Checklist: ${data['checklist']}'),
            Text('Area ID: ${data['area_id']}'),
            Text('Area: ${data['area']}'),
            Text('Location: ${data['location']}'),
            Text('Location Description: ${data['location_description']}'),
            Text('Location ID: ${data['location_id']}'),
            Text('Equipment Name: ${data['equipment_name']}'),
            Text('Description: ${data['description']}'),
            Text('Certificate Permission: ${data['certificate_permission']}'),
            Text('Issuance Date: ${data['issuance_date']}'),
            Text('Expiry Date: ${data['expiry_date']}'),
            Image.network(data['equipment_img']),
            Text('Tags: ${data['tags'].join(", ")}'),
          ],
        ),
      ),
    );
  }
}
