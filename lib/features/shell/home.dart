import 'package:flutter/material.dart';
import '../personalization/personalization_screen.dart';
import '../live_asr/live_asr_screen.dart';

class HomeController extends StatefulWidget {
  const HomeController({super.key});

  @override
  State<HomeController> createState() => _HomeControllerState();
}

class _HomeControllerState extends State<HomeController> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const PersonalizationScreen(),
    const LiveAsrScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Semantics(
          label: 'Soutify',
          child: Image.asset(
            'assets/images/Soutify.PNG',
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
      ),      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(Icons.mic),
              label: "التخصيص"),
          BottomNavigationBarItem(
            icon: const Icon(Icons.hearing),
            label:"الإستماع و التصحيح",
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }


}