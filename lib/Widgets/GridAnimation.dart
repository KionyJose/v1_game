// ignore_for_file: file_names, library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectGrid extends StatefulWidget {
  final int crossAxisCount;
  final double ratio;
  final List<FocusNode>? focusNodeSetas;

  const ProjectGrid({
    Key? key,
    this.focusNodeSetas,
    this.crossAxisCount = 3,
    this.ratio = 1.3,
  }) : super(key: key);

  @override
  _ProjectGridState createState() => _ProjectGridState();
}

class _ProjectGridState extends State<ProjectGrid> {
  late List<bool> hovers;

  @override
  void initState() {
    super.initState();
    hovers = List.generate(widget.focusNodeSetas!.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          // Verifica a tecla pressionada
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            navigate(-1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            navigate(1);
          }
        }
      },
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        itemCount: 4,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: widget.ratio,
        ),
        itemBuilder: (context, index) {
          return Focus(
            focusNode: widget.focusNodeSetas![index],
            onFocusChange: (hasFocus) {
              setState(() {
                hovers[index] = hasFocus;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [
                    Colors.pinkAccent.withOpacity(hovers[index] ? 1.0 : 0.0),
                    Colors.blue.withOpacity(hovers[index] ? 1.0 : 0.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink,
                    offset: const Offset(-2, 0),
                    blurRadius: hovers[index] ? 20 : 10,
                  ),
                  BoxShadow(
                    color: Colors.blue,
                    offset: const Offset(2, 0),
                    blurRadius: hovers[index] ? 20 : 10,
                  ),
                ],
              ),
              child: MouseRegion(
                onEnter: (event) {
                  onHover(index, true);
                },
                onExit: (value) {
                  onHover(index, false);
                },
                child: AnimatedContainer(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xFF000515),
                  ),
                  duration: const Duration(milliseconds: 500),
                  child: const Text(
                    "TEXT",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void onHover(int index, bool value) {
    setState(() {
      hovers[index] = value;
    });
  }

  void navigate(int direction) {
    int currentFocus = widget.focusNodeSetas!.indexWhere((node) => node.hasFocus);
    int newIndex = currentFocus + direction;

    if (newIndex >= 0 && newIndex < widget.focusNodeSetas!.length) {
      FocusScope.of(context).requestFocus(widget.focusNodeSetas![newIndex]);
    }
  }
}
