// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:horizontal_scroll_view/horizontal_scroll_view.dart';

class ListHorizontalIcons extends StatefulWidget {
  const ListHorizontalIcons({super.key});

  @override
  State<ListHorizontalIcons> createState() => _ListHorizontalIconsState();
}

class _ListHorizontalIconsState extends State<ListHorizontalIcons> {
  final PageController _controller = PageController(viewportFraction: 0.6);
  int _currentPage = 0;

  void _scrollToPage(int page) {
    _controller.animateToPage(
      page,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lista horizontal de ícones
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: PageView.builder(
              controller: _controller,
              itemCount: 12,
              itemBuilder: (context, index) {
                double scale = 0.6;
                Color backgroundColor = Colors.transparent;
                if (_controller.position.haveDimensions) {
                  scale = (_controller.page! - index).abs() < 0.5 ? 1.0 : 0.6;
                  backgroundColor = (_controller.page! - index).abs() < 0.5
                      ? Colors.green
                      : Colors.transparent;
                }
                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.star,
                        size: 50,
                        color: Colors.primaries[index % Colors.primaries.length],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Botões para rolar para a esquerda ou direita
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                if (_currentPage > 0) {
                  _scrollToPage(_currentPage - 1);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                if (_currentPage < 11) {
                  _scrollToPage(_currentPage + 1);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
