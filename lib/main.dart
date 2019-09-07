import 'dart:convert';

import 'package:auto_load_api/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'movie.dart';
import 'router.dart' as router;

// todo dive deep into async/await

void main() => runApp(BaseWidget());

class BaseWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //home: ApiList(),
      onGenerateRoute: router.generateRoute,
      initialRoute: HomeRoute,
    );
  }
}

class ApiList extends StatefulWidget {
  @override
  _ApiListState createState() => _ApiListState();
}

class _ApiListState extends State<ApiList> {
  List<Movie> films = <Movie>[];

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int pageNumber = 1;
  bool isLoading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();

    fetch();
    _scrollController.addListener(_onScrollChanged);
  }

  void _onScrollChanged() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        pageNumber++;
        isLoading = true;
      });
      print('get page $pageNumber');

      WidgetsBinding.instance.scheduleFrameCallback((_) => _scrollController
          .animateTo(_scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.bounceInOut));

      fetch();
    }
  }

  Future<void> fetch() async {
    final Response response = await get(
        'https://yts.lt/api/v2/list_movies.json?page=$pageNumber&limit=50');

    try {
      if (response.statusCode == 200) {
        print('OK');
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<Map<String, dynamic>> movies =
            List<Map<String, dynamic>>.from(decodedData['data']['movies']);

        setState(() {
          for (Map<String, dynamic> film in movies) {
            final Movie movie = Movie.fromJson(film);
            films.add(movie);
            // print(movie);
          }
        });
      } else {
        setState(() => error = true);
      }
    } catch (e) {
      setState(() => error = true);
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Get Data From An API'),
        actions: <Widget>[
          if (error)
            IconButton(
              icon: Icon(
                Icons.error_outline,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  error = false;
                  isLoading = true;
                });
                fetch();
              },
            ),
        ],
      ),
      body: ListView.separated(
        controller: _scrollController,
        itemCount: films.length,
        padding: const EdgeInsetsDirectional.only(bottom: 24.0),
        itemBuilder: (BuildContext context, int index) {
          final Movie movie = films[index];

          return Column(
            children: <Widget>[
              ListTile(
                  leading: Image.network(
                    movie.image,
                    filterQuality: FilterQuality.medium,
                  ),
                  title: films.isEmpty
                      ? const Text('Loading')
                      : Text(
                          movie.title,
                          style: TextStyle(fontSize: 20.0),
                        ),
                  subtitle: Text(
                    movie.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.0),
                  ),
                  trailing: Text(
                    'Rating\n${movie.rating.toString()}',
                    textAlign: TextAlign.center,
                  ),
                  onTap: () => Navigator.pushNamed(context, MovieDetailRoute,
                      arguments: movie)),
              if (isLoading && index == films.length - 1)
                const CircularProgressIndicator()
            ],
          );
        },
        separatorBuilder: (BuildContext context, int index) => Divider(
          color: Colors.black,
        ),
      ),
    );
  }
}