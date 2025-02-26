// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:v1_game/Metodos/videoYT.dart';
class DbYoutube{                                                              // TESTE DB                                 // V1 GAME
  static String chaveAPI = "AIzaSyCaZ85AK0n2Str5xB39MP4CCVdCrwslSJU";//AIzaSyCWnlJPV5St9wxuV29jPx-CmNBACLIsAMA  //AIzaSyCaZ85AK0n2Str5xB39MP4CCVdCrwslSJU


  fakeVideos(){
    final fake = mapFake();
    List<VideoYT> videosFake = [];
    for (Map<String, dynamic> map in fake['items']) {      
      VideoYT videoFake = VideoYT();
      videoFake.fromMap(map,"Fake");
      videosFake.add(videoFake);
    }
    return videosFake;
  }

  Future<List<VideoYT>> buscarVideosNoYouTube(String palavraChave,String nomegame) async {
   if(palavraChave.isNotEmpty) return fakeVideos();
    final url = Uri.https(
      'www.googleapis.com',
      '/youtube/v3/search',
      {
        'part': 'snippet',
        'q': palavraChave,
        'key': chaveAPI,
        'maxResults': '6', // Limita a 5 resultados
        'type': 'video',   // Garante que apenas vídeos sejam retornados
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dados = json.decode(response.body);
        List<VideoYT> videos = [];

        for (Map<String, dynamic> map in dados['items']) {
          VideoYT video = VideoYT();
          video.fromMap(map,nomegame);
          // final videoId = item['id']['videoId'];
          // final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
          videos.add(video);
        }

        return videos;
      } else {
        throw Exception('Falha ao carregar vídeos do YouTube: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro durante a requisição: $e');
    }
  }


  Map<String, dynamic>mapFake(){
    return {
      "kind": "youtube#searchListResponse",
      "etag": "eXHh0_BoTNhUEroSv5Mg5wnjzeY",
      "nextPageToken": "CAUQAA",
      "regionCode": "BR",
      "pageInfo": {
        "totalResults": 1000000,
        "resultsPerPage": 5
      },
      "items": [
        {
          "kind": "youtube#searchResult",
          "etag": "rRRd2oKtbKywJuzqFSkBlagud4E",
          "id": {
            "kind": "youtube#video",
            "videoId": "A1BaZr82XJI"
          },
          "snippet": {
            "publishedAt": "2023-06-07T18:37:18Z",
            "channelId": "UCcv8cb3woqO0n7WW4NEaK_Q",
            "title": "Se nao aprender PROGRAMAÇÃO com esse video. - ̗̀  DESISTE   ̖́-",
            "description": "Caso voce queira aprender JAVA comigo - https://encurtador.com.br/OgEam Está procurando um curso de PROGRAMAÇÃO?",
            "thumbnails": {
              "default": {
                "url": "https://i.ytimg.com/vi/A1BaZr82XJI/default.jpg",
                "width": 120,
                "height": 90
              },
              "medium": {
                "url": "https://i.ytimg.com/vi/A1BaZr82XJI/mqdefault.jpg",
                "width": 320,
                "height": 180
              },
              "high": {
                "url": "https://i.ytimg.com/vi/A1BaZr82XJI/hqdefault.jpg",
                "width": 480,
                "height": 360
              }
            },
            "channelTitle": "Fiasco",
            "liveBroadcastContent": "none",
            "publishTime": "2023-06-07T18:37:18Z"
          }
        },
        {
          "kind": "youtube#searchResult",
          "etag": "GUegvY8Yu4mzCbWsj-2E7shDMzs",
          "id": {
            "kind": "youtube#video",
            "videoId": "C-AA7wX-Lqc"
          },
          "snippet": {
            "publishedAt": "2024-07-12T14:45:00Z",
            "channelId": "UCiXIMp68A1907c8a3zlSM5w",
            "title": "👉COMECE PROGRAMAÇÃO POR AQUI👈",
            "description": "Neste vídeo eu respondo uma pergunta muito feita pelos iniciantes em programação: por onde começar ?! Vou pegar na sua ...",
            "thumbnails": {
              "default": {
                "url": "https://i.ytimg.com/vi/C-AA7wX-Lqc/default.jpg",
                "width": 120,
                "height": 90
              },
              "medium": {
                "url": "https://i.ytimg.com/vi/C-AA7wX-Lqc/mqdefault.jpg",
                "width": 320,
                "height": 180
              },
              "high": {
                "url": "https://i.ytimg.com/vi/C-AA7wX-Lqc/hqdefault.jpg",
                "width": 480,
                "height": 360
              }
            },
            "channelTitle": "CriaScript",
            "liveBroadcastContent": "none",
            "publishTime": "2024-07-12T14:45:00Z"
          }
        },
        {
          "kind": "youtube#searchResult",
          "etag": "gS5MpnQ2ndqgOTls5hoJgrcDRvM",
          "id": {
            "kind": "youtube#video",
            "videoId": "Q0YYA8hSV8g"
          },
          "snippet": {
            "publishedAt": "2024-08-08T17:46:37Z",
            "channelId": "UC3uYvpJ3J6oNoNYRXfZXjEw",
            "title": "Especialista RESPONDE se VALE A PENA estudar PROGRAMAÇÃO",
            "description": "TECNOLOGIA E IA [+ FABIO AKITA] youtube.com/live/--slRywdonM ~~~~~~~ AACD Sua saúde merece a excelência do Hospital ...",
            "thumbnails": {
              "default": {
                "url": "https://i.ytimg.com/vi/Q0YYA8hSV8g/default.jpg",
                "width": 120,
                "height": 90
              },
              "medium": {
                "url": "https://i.ytimg.com/vi/Q0YYA8hSV8g/mqdefault.jpg",
                "width": 320,
                "height": 180
              },
              "high": {
                "url": "https://i.ytimg.com/vi/Q0YYA8hSV8g/hqdefault.jpg",
                "width": 480,
                "height": 360
              }
            },
            "channelTitle": "Cortes do Flow [OFICIAL]",
            "liveBroadcastContent": "none",
            "publishTime": "2024-08-08T17:46:37Z"
          }
        },
        {
          "kind": "youtube#searchResult",
          "etag": "nH0ZWCjFQH0Brd5AwgOWVoLtf_s",
          "id": {
            "kind": "youtube#video",
            "videoId": "o17EjWGHYBo"
          },
          "snippet": {
            "publishedAt": "2023-11-18T22:55:41Z",
            "channelId": "UCMGNoYQ66DDvzwy3AOQj6wg",
            "title": "Como FUNCIONA cada MALDITA LINGUAGEM DE PROGRAMAÇÃO?",
            "description": "Hoje é dia de entender, como cada linguagem funciona, e para que cada uma delas serve. Se voce estiver começando na ...",
            "thumbnails": {
              "default": {
                "url": "https://i.ytimg.com/vi/o17EjWGHYBo/default.jpg",
                "width": 120,
                "height": 90
              },
              "medium": {
                "url": "https://i.ytimg.com/vi/o17EjWGHYBo/mqdefault.jpg",
                "width": 320,
                "height": 180
              },
              "high": {
                "url": "https://i.ytimg.com/vi/o17EjWGHYBo/hqdefault.jpg",
                "width": 480,
                "height": 360
              }
            },
            "channelTitle": "JovemScript",
            "liveBroadcastContent": "none",
            "publishTime": "2023-11-18T22:55:41Z"
          }
        },
        {
          "kind": "youtube#searchResult",
          "etag": "bd8gQViX8fSNzoym9d3TD889Qik",
          "id": {
            "kind": "youtube#video",
            "videoId": "OqiuC8bdxb4"
          },
          "snippet": {
            "publishedAt": "2024-08-05T21:07:41Z",
            "channelId": "UC_-uuuZbY0AAt9CViNzvc-Q",
            "title": "Como aprender programação de forma INTELIGENTE, sem perder tempo com coisas INÚTEIS",
            "description": "Se você ainda não estuda programação na Alura, não deixe de usar meu link de 15% de desconto: https://alura.tv/rafaballerini (lá ...",
            "thumbnails": {
              "default": {
                "url": "https://i.ytimg.com/vi/OqiuC8bdxb4/default.jpg",
                "width": 120,
                "height": 90
              },
              "medium": {
                "url": "https://i.ytimg.com/vi/OqiuC8bdxb4/mqdefault.jpg",
                "width": 320,
                "height": 180
              },
              "high": {
                "url": "https://i.ytimg.com/vi/OqiuC8bdxb4/hqdefault.jpg",
                "width": 480,
                "height": 360
              }
            },
            "channelTitle": "Rafaella Ballerini",
            "liveBroadcastContent": "none",
            "publishTime": "2024-08-05T21:07:41Z"
          }
        },{
          "kind": "youtube#searchResult",
          "etag": "rRRd2oKtbKywJuzqFSkBlagud4E",
          "id": {
            "kind": "youtube#video",
            "videoId": "A1BaZr82XJI"
          },
          "snippet": {
            "publishedAt": "2023-06-07T18:37:18Z",
            "channelId": "UCcv8cb3woqO0n7WW4NEaK_Q",
            "title": "Se nao aprender PROGRAMAÇÃO com esse video. - ̗̀  DESISTE   ̖́-",
            "description": "Caso voce queira aprender JAVA comigo - https://encurtador.com.br/OgEam Está procurando um curso de PROGRAMAÇÃO?",
            "thumbnails": {
              "default": {
                "url": "https://i.ytimg.com/vi/A1BaZr82XJI/default.jpg",
                "width": 120,
                "height": 90
              },
              "medium": {
                "url": "https://i.ytimg.com/vi/A1BaZr82XJI/mqdefault.jpg",
                "width": 320,
                "height": 180
              },
              "high": {
                "url": "https://i.ytimg.com/vi/A1BaZr82XJI/hqdefault.jpg",
                "width": 480,
                "height": 360
              }
            },
            "channelTitle": "Fiasco",
            "liveBroadcastContent": "none",
            "publishTime": "2023-06-07T18:37:18Z"
          }
        },
      ]
    };
  }
}
