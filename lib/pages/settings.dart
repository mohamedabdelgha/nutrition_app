import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';

class settingsPage extends StatefulWidget {
  const settingsPage({super.key});

  @override
  State<settingsPage> createState() => _settingsPageState();
}

class _settingsPageState extends State<settingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeScope = ThemeScope.of(context);
    // Determine icon based on current mode for the OptionContainer
    final themeIcon = themeScope.isDarkMode
        ? AmazingIconOutlined.moon
        : AmazingIconOutlined.sun;
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Text(
            'Settings',
            style: TextStyle(
              color: AppColors.darkBlueColor,
              fontSize: 24,
              fontFamily: 'main',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 100),

          OptionContainer(
            switchBtn: true,
            title: 'Dark Mode',
            // Pass IconData
            iconData: themeIcon,
            // Correctly pass the external state and callback from ThemeScope
            onSwitchChanged: themeScope.toggleTheme,
            isSwitchOn: themeScope.isDarkMode,
          ),
          OptionContainer(
            switchBtn: true,
            title: 'Notifications',
            // Pass IconData
            iconData: AmazingIconOutlined.notification1,
            // Correctly pass the external state and callback from ThemeScope
            onSwitchChanged: themeScope.toggleTheme,
            isSwitchOn: false,
          ),
        ],
      ),
    );
  }
}

// --- OptionContainer (Refactored to be Stateless and accept external control for the custom switch) ---
class OptionContainer extends StatelessWidget {
  // Flag to indicate if this is a switch row or a tap row
  final bool switchBtn;
  final String title;
  // Use IconData for type safety and easy theming
  final IconData iconData;
  // State and callback for the custom switch
  final bool? isSwitchOn;
  final ValueChanged<bool>? onSwitchChanged;
  const OptionContainer({
    super.key,
    required this.switchBtn,
    required this.title,
    required this.iconData, // Changed from Widget icon to IconData
    this.isSwitchOn,
    this.onSwitchChanged,
  });

  // Custom switch implementation using BoxDecoration and AnimatedAlign
  Widget _buildCustomSwitch(BuildContext context) {
    final theme = Theme.of(context);
    final isActivated = isSwitchOn ?? false;
    void showTopSnackBar(BuildContext context, String message) {
      final overlay = Overlay.of(context);
      final entry = OverlayEntry(
        builder: (context) => Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkBlueColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontFamily: 'main',
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );

      overlay.insert(entry);

      Future.delayed(Duration(seconds: 3)).then((_) => entry.remove());
    }

    // Use GestureDetector to handle the tap and call the external change handler
    return GestureDetector(
      onTap: () {
        showTopSnackBar(context, 'changes have been applied ');

        // Only call the external callback if the switch is meant to be controllable
        if (onSwitchChanged != null) {
          onSwitchChanged!(!isActivated);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 60,
        height: 30,
        alignment: isActivated ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isActivated
              ? theme.colorScheme.secondary
              : theme.colorScheme.onSurface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: theme.cardColor, // Use card color for the toggle button
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onBackground.withOpacity(0.2),
                blurRadius: 2,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              iconData,
              size: 30,
              color: AppColors.darkBlueColor, // Primary color for icon
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color: AppColors.darkBlueColor,
                fontFamily: 'main',
                fontSize: 20,
              ),
            ),
          ],
        ),
        if (switchBtn)
          _buildCustomSwitch(context)
        else
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onBackground.withOpacity(0.5),
          ),
      ],
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
      child: InkWell(
        // Only allow card tap if it's a navigational element
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: content,
        ),
      ),
    );
  }
}
