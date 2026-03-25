import 'package:flutter/material.dart';
import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter_application_1/main.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.whiteColor,

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  icon: Icon(
                    AmazingIconFilled.arrowLeft2,
                    size: 30,
                    color: AppColors.darkBlueColor,
                  ),
                ),
                Text(
                  'About Us',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppColors.darkBlueColor,
                    fontFamily: 'main',
                  ),
                ),
                Container(),
              ],
            ),
            Center(
              child: Container(
                width: width * 0.4,
                height: height * 0.15,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage(
                      'lib/assets/splash.png',
                    ), // <-- replace with your logo
                    fit: BoxFit.contain,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Title
            Text(
              'Who We Are',
              style: TextStyle(
                color: AppColors.darkBlueColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "We are a creative digital agency specializing in mobile app and web development, "
              "as well as advertising and design solutions. Our goal is to help businesses grow "
              "by building powerful digital experiences that connect with their audience.",
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // Mission
            Text(
              'Our Mission',
              style: TextStyle(
                color: AppColors.darkBlueColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              "To deliver innovative, high-quality, and cost-effective digital products that empower "
              "our clients and enhance their brand reputation.",
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // Vision
            Text(
              'Our Vision',
              style: TextStyle(
                color: AppColors.darkBlueColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              "To become one of the top digital solution providers in the Arab world, "
              "known for creativity, reliability, and innovation.",
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // Our Values Section
            Text(
              'Our Values',
              style: TextStyle(
                color: AppColors.darkBlueColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            _buildValueTile(
              icon: AmazingIconOutlined.activity,
              title: "Innovation",
              subtitle:
                  "We embrace technology to create better user experiences.",
            ),
            _buildValueTile(
              icon: AmazingIconOutlined.chart,
              title: "Trust",
              subtitle:
                  "We build strong and long-lasting partnerships with our clients.",
            ),
            _buildValueTile(
              icon: AmazingIconOutlined.user,
              title: "Teamwork",
              subtitle:
                  "Our diverse team works collaboratively to achieve success.",
            ),
            _buildValueTile(
              icon: AmazingIconOutlined.award,
              title: "Excellence",
              subtitle:
                  "We strive to deliver exceptional results in every project.",
            ),

            const SizedBox(height: 40),

            // Contact Info
            Text(
              'Contact Us',
              style: TextStyle(
                color: AppColors.darkBlueColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            ListTile(
              leading: Icon(
                Icons.email_outlined,
                color: AppColors.darkBlueColor,
              ),
              title: Text('info@yourcompany.com'),
            ),
            ListTile(
              leading: Icon(
                Icons.phone_outlined,
                color: AppColors.darkBlueColor,
              ),
              title: Text('+20 123 456 7890'),
            ),
            ListTile(
              leading: Icon(
                Icons.location_on_outlined,
                color: AppColors.darkBlueColor,
              ),
              title: Text('Cairo, Egypt'),
            ),

            const SizedBox(height: 40),

            // Footer
            Center(
              child: Text(
                "© ${DateTime.now().year} Your Company Name\nAll Rights Reserved.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkBlueColor, size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
