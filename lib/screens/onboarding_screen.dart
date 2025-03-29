import 'package:flutter/material.dart';
import 'package:travelcompanionfinder/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: PageView(
          controller: _pageController,
          children: [
            OnboardingPage(
              image: "assets/onboarding.png", // Add your image here
              title: "Explore the World",
              description: "Find people with similar interests to travel with.",
            ),
            OnboardingPage(
              image: "assets/onboarding.png", // Add your image here
              title: "Connect with Others",
              description: "Meet like-minded travelers for your journey.",
            ),
            OnboardingPage(
              image: "assets/onboarding.png", // Add your image here
              title: "Enjoy the Ride",
              description: "Experience unforgettable trips with companions.",
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AnimatedScale(
            scale: 1.1,
            duration: Duration(seconds: 1),
            child: Image.asset(image),
          ),
        ),
        SizedBox(height: 30),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => LoginScreen())),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(
            'Get Started',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 10,
              height: 10,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: index == 0 ? Colors.white : Colors.grey,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
      ],
    );
  }
}
