import 'package:flutter/material.dart';

class ListViewAnimadoVideos extends StatefulWidget {
  @override
  _ListViewAnimadoVideosState createState() =>
      _ListViewAnimadoVideosState();
}

class _ListViewAnimadoVideosState extends State<ListViewAnimadoVideos> {
  final List<String> items = List.generate(10, (index) => "Item $index");
  int currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Horizontal ListView"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Indicador de índice
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Selecionado: ${items[currentIndex]}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Flexible(
            flex: 3,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemCount: items.length,
              itemBuilder: (context, index) {
                final bool isSelected = index == currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(
                    horizontal: isSelected ? 12 : 8,
                    vertical: isSelected ? 10 : 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white12,
                    image: const DecorationImage(
                      opacity: 0.9,
                      image: NetworkImage(
                          "https://via.placeholder.com/150"), // Imagem de exemplo
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.grey,
                      width: isSelected ? 4 : 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.play_circle_fill,
                          size: isSelected ? 60 : 50,
                          color: Colors.white70,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Text(
                          items[index],
                          style: TextStyle(
                            fontSize: isSelected ? 18 : 14,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
