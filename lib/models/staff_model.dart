import 'dart:ui';

import 'package:flutter/material.dart';

class Staff {
  final int id;
  final String name;
  final String contact;
  final String department_id;
  final String profileImg;
  final String email;
  final String createdBy;
  final String department_name;
  final String companyName;
  final String userName;

  Staff({
    required this.id,
    required this.name,
    required this.contact,
    required this.companyName,
    required this.department_id,
    required this.profileImg,
    required this.email,
    required this.createdBy,
    required this.department_name,
    required this.userName
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],
      name: json['name'] ?? '',
      companyName: json['company_name'] ?? '',
      contact: json['contact'] ?? '',
      department_id: json['department_id'] ?? '',
      profileImg: json['profile_img'] ?? '',
      email: json['email'] ?? '',
      createdBy: json['created_by'] ?? '',
      department_name: json['department_name'] ?? '',
      userName: json['department_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'contact': contact,
      'companyName': companyName,
      'department_id': department_id,
      'department_name': department_name,
      'profileImg': profileImg,
      'createdBy': createdBy,
      'userName': userName,
    };
  }
}

class Order {
  final int? id;
  final int? status;
  final String? bottles;
  final double? totalAmount;
  final double? cashReceived;
  final double? balance;
  final String? address;
  final DateTime? createdAt;
  final DateTime? processAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final DateTime? assignedAt;
  final List<String>? itemNames;
  final List<double>? unitPrices;
  final String? latitude;
  final String? longitude;
  final String? customerName;
  final String? quantity;

  final String equipmentName;
  final String equipmentArea;
  final String equipmentLocatoin;
  final String failedChecklistKey;
  final String department;
  final String inspectorName;
  final String inspectionDate;
  final String caseNo;
  final String technicianName;

  Order({
    this.status,
    this.id,
    this.bottles,
    this.totalAmount,
    this.cashReceived,
    this.balance,
    this.address,
    this.createdAt,
    this.processAt,
    this.dispatchedAt,
    this.deliveredAt,
    this.assignedAt,
    this.itemNames,
    this.unitPrices,
    this.latitude,
    this.longitude,
    this.customerName,
    this.quantity,
    required this.equipmentName,
    required this.equipmentArea,
    required this.equipmentLocatoin,
    required this.failedChecklistKey,
    required this.department,
    required this.inspectorName,
    required this.inspectionDate,
    required this.caseNo,
    required this.technicianName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<String> itemNames = List<String>.from(json['item_names'] ?? []);
    List<String> unitPricesStr = (json['unit_price'] as String).split(',');
    List<double> unitPrices =
        unitPricesStr.map((e) => double.parse(e.trim())).toList();

    return Order(
      id: json['id'],
      quantity: json['buying_qty'],
      bottles: json['bottles'] ?? '0',
      customerName: json['customer_name'] ?? 'unknown Customer',
      status: int.tryParse(json['status'].toString()) ?? 0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      cashReceived: double.tryParse(json['cash_received'].toString()) ?? 0.0,
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      address: json['address'] ?? 'Unknown',
      latitude: json['latitude'] ?? 'null',
      longitude: json['longitude'] ?? 'null',
      createdAt: DateTime.parse(json['created_at']),
      processAt: json['process_at'] != null
          ? DateTime.parse(json['process_at'])
          : null,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : null,
      dispatchedAt: json['dispatched_at'] != null
          ? DateTime.parse(json['dispatched_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      itemNames: itemNames,
      unitPrices: unitPrices,
      equipmentName: json['company_equipment_name'] ?? 'Unknown',
      equipmentArea: json['area'] ?? 'Unknown',
      equipmentLocatoin: json['location_id'] ?? 'Unknown',
      failedChecklistKey: json['bad_factor_name'] ?? 'Unknown',
      department: json['address'] ?? 'Unknown',
      inspectorName: json['inspector_name'] ?? 'Unknown',
      inspectionDate: json['inspection_date'] ?? 'Unknown',
      caseNo: json['case_no'] ?? 'Unknown',
      technicianName: json['technician_name'] ?? 'Unknown',
    );
  }

  Color getStatusColor() {
    switch (status) {
      case 2:
        return const Color.fromARGB(255, 255, 243, 229); // In Process
      case 3:
        return const Color.fromARGB(255, 255, 229, 229); // Delivering
      case 4:
        return const Color.fromARGB(255, 229, 255, 242); // Delivered
      default:
        return Colors.white; // Unknown status
    }
  }

  Color getStatusTextColor() {
    switch (status) {
      case 2:
        return const Color.fromARGB(255, 255, 194, 76); // In Process
      case 3:
        return const Color.fromARGB(255, 255, 56, 56); // Delivering
      case 4:
        return const Color.fromARGB(255, 56, 204, 113); // Delivered
      default:
        return Colors.grey; // Unknown status
    }
  }
}
