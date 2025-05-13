import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupButton extends StatelessWidget {
  final String txt;
  final IconData icon;
  final Color bgColor;
  final Color txtColor;
  final Color iconColor;
  final VoidCallback fn;
  const GroupButton({
    super.key,
    required this.size, required this.txt, required this.icon, required this.bgColor, required this.fn, required this.txtColor, required this.iconColor,
  });

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(size.width*0.03),
      child: SizedBox(
        width: size.width * 0.95,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(size.width*0.03),
            backgroundColor: bgColor,
            foregroundColor: txtColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)
            )
          ),
          onPressed: fn,
          icon: Icon(icon, color: iconColor),
          label: Text(
            txt,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
