import 'package:expense_splitter/helper/border.dart';
import 'package:expense_splitter/helper/color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomField extends StatefulWidget {
  final String htext;
  final IconData preicon;
  final String title;
  final TextEditingController controller;
  final FormFieldValidator<String> valid;
  final IconData? sufIcon;
  final IconData? sufIcon2;
  const CustomField({
    super.key,
    required this.size,
    required this.htext,
    required this.preicon,
    required this.title,
    required this.controller,
    required this.valid,
    this.sufIcon,
    this.sufIcon2,
  });

  final Size size;

  @override
  State<CustomField> createState() => _CustomFieldState();
}

class _CustomFieldState extends State<CustomField> {
  bool temp = false;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.size.width * 0.03),
          child: Text(
            widget.title,
            style: GoogleFonts.inter(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.bold,
              color: dark_blue,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(widget.size.width * 0.03),
          child: TextFormField(
            obscureText: temp,
            controller: widget.controller,
            style: GoogleFonts.inter(
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.bold,
              color: dark_blue,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: light_blue,
              enabledBorder: border,
              focusedBorder: border,
              focusedErrorBorder: border,
              errorBorder: border,
              prefixIcon: Icon(widget.preicon, color: dark_blue),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    temp = !temp;
                  });
                },
                child:
                    temp
                        ? Icon(widget.sufIcon, color: dark_blue)
                        : Icon(widget.sufIcon2, color: dark_blue),
              ),
              border: InputBorder.none,
              errorStyle: GoogleFonts.spaceGrotesk(color: Colors.red),
              hintText: widget.htext,
              hintStyle: GoogleFonts.inter(
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.bold,
                color: dark_blue,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: widget.size.height * 0.018,
              ),
            ),
            validator: widget.valid,
          ),
        ),
      ],
    );
  }
}
