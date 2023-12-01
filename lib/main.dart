import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'meal_plan_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calories Calculator',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //Initialize database
  final dbHelper = DatabaseHelper();

  //Initialize variables
  int targetCalories = 0;
  DateTime selectedDate = DateTime.now();
  int totalConsumedCalories = 0;
  TextEditingController foodController = TextEditingController();
  int calories = 0;
  bool usePredefinedList = true;

  @override
  void initState() {
    super.initState();
    _loadTotalConsumedCalories();
  }

  //Custom function to pick date
  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _loadTotalConsumedCalories();
      });
    }
  }

  //Custom function to load total calories after food items are added
  void _loadTotalConsumedCalories() async {
    final consumedFoods =
    await dbHelper.getMealPlanForDate(_formatDate(selectedDate));
    int totalCalories = consumedFoods.fold(0, (sum, food) => sum + food.calories);
    setState(() {
      totalConsumedCalories = totalCalories;
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  //Custom function which builds a dialog box full of foods
  Future<void> _showFoodSelectionDialog() async {
    List<Map<String, dynamic>> foods = await dbHelper.getFoods();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Food'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text('Use Predefined List'),
                Column(
                  children: foods.map((food) {
                    return ListTile(
                      title: Text(food['name']),
                      onTap: () {
                        if (food['name'] != null && food['name'].isNotEmpty) {
                          setState(() {
                            foodController.text = food['name'];
                            calories = food['calories'];
                          });
                        }
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //Custom function which allows the addition of food
  void _addFood() async {
    //Check if a date is selected
    if (selectedDate == null) {
      _showSnackBar('Please select a date.');
      return;
    }

    //Check if target calories is inputted
    if (targetCalories==0){
      _showSnackBar('Please enter target calories');
      return;
    }

    await _showFoodSelectionDialog();

    if (calories > 0) {
      // Check if calories is greater than 0 before adding to total.
      if (totalConsumedCalories + calories > targetCalories) {
        _showSnackBar('Exceeding Target Calories!');
        return;
      }

      //Insert food item to database
      await dbHelper.insertFood(
        foodController.text,
        calories,
        _formatDate(selectedDate),
      );

      //Update total calories
      _loadTotalConsumedCalories();

      //reset state
      setState(() {
        foodController.text = '';
        calories = 0;
      });
    }
  }

  //Custom function to remove food
  void _deleteFood(int calories) {
    //remove food from state
    setState(() {
      totalConsumedCalories -= calories;
    });
  }

  //Custom function which switch pages
  void _viewMealPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealPlanScreen(
          selectedDate: selectedDate,
          onDeleteFood: _deleteFood,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calories Calculator'),
      ),
      body: Column(
        children: [
          _buildTargetCaloriesInput(),
          _buildSelectedDateRow(),
          _buildAddFoodButton(),
          _buildTotalConsumedCaloriesText(),
          if (totalConsumedCalories > targetCalories)
            _buildExceedingCaloriesWarning(),
          _buildViewMealPlanButton(),
        ],
      ),
    );
  }

  Widget _buildTargetCaloriesInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Target Calories:'),
            SizedBox(height: 10),
            Container(
              width: 100,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center, // Center the content within the TextField
                onChanged: (value) {
                  setState(() {
                    targetCalories = int.parse(value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildSelectedDateRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Selected Date: ${_formatDate(selectedDate)}'),
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildAddFoodButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _addFood,
                child: Text('Add Food'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalConsumedCaloriesText() {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
      child: Center(
        child: Text(
          'Total Consumed Calories: $totalConsumedCalories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }


  Widget _buildExceedingCaloriesWarning() {
    return Text(
      'Warning: Exceeding Target Calories!',
      style: TextStyle(color: Colors.red),
    );
  }

  Widget _buildViewMealPlanButton() {
    return ElevatedButton(
      onPressed: _viewMealPlan,
      child: Text('View Meal Plan'),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 5),
      ),
    );
  }
}
