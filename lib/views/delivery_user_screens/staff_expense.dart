import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:techno_shield/helper/style.dart'; // Ensure you have correct import path
import 'package:techno_shield/models/staff_model.dart'; // Ensure you have correct import path
import 'package:techno_shield/view_models/staff_view_model.dart';
import 'package:provider/provider.dart'; // Ensure you have correct import path

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesState();
}

class _ExpensesState extends State<ExpensesPage> {
  File? _imageFile;
  String? _imagePath;
  bool isVisible = false;
  bool isLoadingCategories = true;

  final _formKey = GlobalKey<FormState>();

  // Define TextEditingController for amount field
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionNotes = TextEditingController();

  // Define variables for storing selected values
  DateTime selectedDate = DateTime.now();
  Categories? selectedCategory;

  List<Categories> categoriesList = [];

  @override
  void initState() {
    super.initState();
    fetchData(); // Fetch categories on init
  }

  // Function to fetch expense categories from API
  Future<void> fetchData() async {
    try {
      final response = await http.get(
          Uri.parse('https://jalmanagementsystem.com/api/expense_category'));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        List<Categories> categories =
            data.map((item) => Categories.fromJson(item)).toList();
        setState(() {
          categoriesList = categories;
          isLoadingCategories = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      // Handle error state
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: appColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imagePath = pickedFile.path;
        isVisible = true;
      });
    }
  }

  Future<void> _sendExpenses() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final staffViewModel = Provider.of<StaffViewModel>(context, listen: false);
    final staffId = staffViewModel.currentStaff?.id;

    if (staffId == null) {
      print('User is not logged in');
      return;
    }

    String date = '${selectedDate.toLocal()}'.split(' ')[0];
    int categoryId = selectedCategory?.id ?? 0;
    String amount = amountController.text;
    String notes = descriptionNotes.text;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://jalmanagementsystem.com/api/add_expense'),
    );

    request.fields['date'] = date;
    request.fields['category_id'] = categoryId.toString();
    request.fields['staff_id'] = staffId.toString();
    request.fields['amount'] = amount;
    request.fields['note'] = notes;

    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('expense_img', _imageFile!.path),
      );
    }

    print('Request Fields:');
    request.fields.forEach((key, value) {
      print('$key: $value');
    });

    if (_imageFile != null) {
      print('Request Files:');
      print('expense_img: ${_imageFile!.path}');
    }

    try {
      // Show circular progress indicator while sending
      showDialog(
        context: context,
        barrierDismissible: false, // prevent dismiss by tapping outside
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        print('Expense submitted successfully');
        // Close the loading dialog
        Navigator.of(context).pop();

        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Expense sent successfully.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();

                    // Clear form fields after successful submission
                    amountController.clear();
                    descriptionNotes.clear();
                    setState(() {
                      selectedDate = DateTime.now();
                      selectedCategory = null;
                      _imageFile = null;
                      _imagePath = null;
                      isVisible = false;
                    });
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Close the loading dialog
        Navigator.of(context).pop();
        print('Failed to submit expense: ${response.statusCode}');
        print('Response body: $responseBody');
      }
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();
      print('Error submitting expense: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _selectDate(context);
                  },
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all<Color>(appColor),
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    shape: WidgetStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: const BorderSide(color: appColor),
                      ),
                    ),
                  ),
                  child: Text(
                    '${selectedDate.toLocal()}'.split(' ')[0],
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                isLoadingCategories
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<Categories>(
                        initialValue: selectedCategory,
                        onChanged: (Categories? newValue) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        },
                        items: categoriesList.map((Categories category) {
                          return DropdownMenuItem<Categories>(
                            value: category,
                            child: Text(category.name),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: appColor, width: 2.0),
                          ),
                          border: OutlineInputBorder(),
                          hintText: 'Select category',
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 16),
                const Text(
                  'Amount',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appColor, width: 2.0),
                    ),
                    hintText: 'Enter amount',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  maxLines: 3,
                  controller: descriptionNotes,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: appColor, width: 2.0),
                    ),
                    hintText: 'Description Notes',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    pickImage(ImageSource.camera);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: appColor),
                  child: Text(
                    'Take Receipt Picture',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Visibility(
                  visible: isVisible,
                  child: _imagePath != null
                      ? Container(
                          margin: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: appColor, width: 1.5),
                          ),
                          child: Image.file(
                            File(_imagePath!),
                            height: 200,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (!isVisible)
                  const Text(
                    'Please add a receipt image',
                    style: TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 8),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    _sendExpenses();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: appColor),
                  child: Text(
                    'Send Expenses',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Model class for categories
class Categories {
  final int id;
  final String name;

  Categories({
    required this.id,
    required this.name,
  });

  factory Categories.fromJson(Map<String, dynamic> json) {
    return Categories(
      id: json['id'],
      name: json['name'],
    );
  }
}
