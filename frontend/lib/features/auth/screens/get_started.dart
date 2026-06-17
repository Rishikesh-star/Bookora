import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
class GetStartedPage extends StatelessWidget{
  const GetStartedPage({super.key});
  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration:  BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surface.withOpacity(0.3),
                  AppColors.background.withOpacity(0.9),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),
                  Text(
                    'Welcome to',
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),                  ),
                  Text(
                    "Bookora",
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Read. Discover. Repeat.\nYour next adventure is\njust a page away.",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 5),
                  SizedBox(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen(),),);

                      },
                      child: const Text(
                        "Get Started",
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?',style: TextStyle(color: AppColors.textMuted),),

                        TextButton(
                            onPressed: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const LoginScreen(),),);
                            },
                            child: Text('Login',style: TextStyle(color: Colors.blueAccent,),),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}