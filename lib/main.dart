import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('favorites');
  await Hive.openBox('settings');
  runApp(const MilliyTaomlarApp());
}

class MilliyTaomlarApp extends StatelessWidget {
  const MilliyTaomlarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, box, _) {
        final isDarkMode = box.get('darkMode', defaultValue: false);
        return MaterialApp(
          title: 'Milliy Taomlar',
          theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredDishes = [];

  final List<Map<String, dynamic>> _allDishes = [
    {'name': 'Osh', 'desc': "Eng mashhur o'zbek taomi", 'time': '90 daqiqa', 'servings': '4'},
    {'name': 'Manti', 'desc': "Go'shtli xamirli taom", 'time': '120 daqiqa', 'servings': '3'},
    {'name': "Lag'mon", 'desc': "'Uyg'ur milliy taomi'", 'time': '30 daqiqa', 'servings': '2'},
    {'name': 'Qazi', 'desc': "Odatiy go'shtli taom", 'time': '120 daqiqa', 'servings': '6'},
    {'name': 'Dimlama', 'desc': "Go'shtli va sabzavotli taom", 'time': '90 daqiqa', 'servings': '5'},
    {'name': 'Shashlik', 'desc': "qiymali go'sht", 'time': '40 daqiqa', 'servings': '2'},
  ];



  @override
  void initState() {
    super.initState();
    _filteredDishes = _allDishes;
    _searchController.addListener(_searchDishes);
  }

  void _searchDishes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDishes = _allDishes.where((dish) {
        return dish['name'].toLowerCase().contains(query) ||
            dish['desc'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleFavorite(String dishName) {
    final favoritesBox = Hive.box('favorites');
    setState(() {
      if (favoritesBox.containsKey(dishName)) {
        favoritesBox.delete(dishName);
      } else {
        favoritesBox.put(dishName, true);
      }
    });
  }

  bool _isFavorite(String dishName) {
    return Hive.box('favorites').containsKey(dishName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MILLIY TAOMLAR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DishSearchDelegate(_allDishes),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildSectionTitle("Eng mashhur o'zbek taomlari"),
            _buildPopularDishes(),
            _buildSectionTitle('Barcha Taomlar'),
            _buildAllDishes(),
            _buildSectionTitle('Sevimlilar'),
            _buildFavorites(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Bosh'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Kategoriya'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Sozlamalar'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const CategoryScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsScreen()));
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPopularDishes() {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _allDishes.take(3).map((dish) =>
            _buildDishCard(dish)
        ).toList(),
      ),
    );
  }

  Widget _buildDishCard(Map<String, dynamic> dish) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => RecipeDetailScreen(
            dish: dish,
            isFavorite: _isFavorite(dish['name']),
            onFavoriteToggle: _toggleFavorite,
          ),
        ));
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fastfood, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(
              dish['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                dish['desc'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllDishes() {
    return Column(
      children: _filteredDishes.map((dish) =>
          _buildDishItem(dish)
      ).toList(),
    );
  }

  Widget _buildDishItem(Map<String, dynamic> dish) {
    return ListTile(
      leading: Icon(Icons.fastfood, color: Theme.of(context).primaryColor),
      title: Text(dish['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(dish['desc']),
      trailing: IconButton(
        icon: Icon(
          _isFavorite(dish['name']) ? Icons.favorite : Icons.favorite_border,
          color: Colors.red,
        ),
        onPressed: () => _toggleFavorite(dish['name']),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => RecipeDetailScreen(
            dish: dish,
            isFavorite: _isFavorite(dish['name']),
            onFavoriteToggle: _toggleFavorite,
          ),
        ));
      },
    );
  }

  Widget _buildFavorites() {
    final favoritesBox = Hive.box('favorites');
    final favoriteDishes = _allDishes.where((dish) =>
        favoritesBox.containsKey(dish['name'])
    ).toList();

    if (favoriteDishes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Hozircha sevimli taomlar ro'yxati mavjud emas"),
      );
    }

    return Column(
      children: favoriteDishes.map((dish) =>
          ListTile(
            leading: Icon(Icons.favorite, color: Colors.red),
            title: Text(dish['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${dish['time']} • ${dish['servings']} kishi'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _toggleFavorite(dish['name']),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => RecipeDetailScreen(
                  dish: dish,
                  isFavorite: true,
                  onFavoriteToggle: _toggleFavorite,
                ),
              ));
            },
          ),
      ).toList(),
    );
  }
}

class DishSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> dishes;

  DishSearchDelegate(this.dishes);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = dishes.where((dish) =>
    dish['name'].toLowerCase().contains(query.toLowerCase()) ||
        dish['desc'].toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final dish = results[index];
        return ListTile(
          title: Text(dish['name']),
          subtitle: Text(dish['desc']),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(
                dish: dish,
                isFavorite: Hive.box('favorites').containsKey(dish['name']),
                onFavoriteToggle: (dishName) {
                  final favoritesBox = Hive.box('favorites');
                  if (favoritesBox.containsKey(dishName)) {
                    favoritesBox.delete(dishName);
                  } else {
                    favoritesBox.put(dishName, true);
                  }
                },
              ),
            ));
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? dishes
        : dishes.where((dish) =>
    dish['name'].toLowerCase().contains(query.toLowerCase()) ||
        dish['desc'].toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final dish = suggestions[index];
        return ListTile(
          title: Text(dish['name']),
          subtitle: Text(dish['desc']),
          onTap: () {
            query = dish['name'];
            showResults(context);
          },
        );
      },
    );
  }
}

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategoriyalar'),
      ),
      body: ListView(
        children: [
          _buildCategoryItem(context, "Go'shtli taomlar", Icons.fastfood),
          _buildCategoryItem(context, "Sabzavotli taomlar", Icons.eco),
          _buildCategoryItem(context, "Sho'rvalar", Icons.soup_kitchen),
          _buildCategoryItem(context, "Shirinliklar", Icons.cake),
          _buildCategoryItem(context, "Ichimliklar", Icons.local_drink),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Bosh'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Kategoriya'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Sozlamalar'),
        ],
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsScreen()));
          }
        },
      ),
    );
  }


  Widget _buildCategoryItem(BuildContext context, String name, IconData icon) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(name, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryDetailScreen(categoryName: name),
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dish['name']),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: Colors.red,
            onPressed: () => onFavoriteToggle(dish['name']),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dish['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${dish['time']} • ${dish['servings']} kishi'),
            const SizedBox(height: 16),
            const Text(
              'Kerakli Mahsulotlar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("- Go'sht"),
            const Text("- Sabzavotlar"),
            const Text("- meva va ziravorlar"),
            const SizedBox(height: 16),
            const Text(
              'Tayyorlash usuli',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("1. Barcha mahsulotlarni tozalang"),
            const Text("2. Go'shtni maydalab qo'ying"),
            const Text("3. Dasturxonga tortish uchun tayyorlang"),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Saqlash'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Bosh'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Kategoriya'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Sozlamalar'),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const CategoryScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsScreen()));
          }
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');
    final isDarkMode = settingsBox.get('darkMode', defaultValue: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sozlamalar'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Mavzuni almashtirish"),
            value: isDarkMode,
            onChanged: (value) {
              settingsBox.put('darkMode', value);
            },
          ),


          ListTile(
            title: const Text('Ilova haqida'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutAppScreen()),
              );
            },
          ),

        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Bosh'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Kategoriya'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Sozlamalar'),
        ],
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const CategoryScreen()));
          }
        },
      ),
    );
  }
}

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  final TextEditingController _controller = TextEditingController();

  void _showEnteredText() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisplayTextScreen(text: _controller.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ilova haqida')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Matn kiriting',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showEnteredText,
              child: const Text('Ko‘rsatish'),
            ),
          ],
        ),
      ),
    );
  }
}

class DisplayTextScreen extends StatelessWidget {
  final String text;

  const DisplayTextScreen({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kiritilgan matn")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;

  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: Center(
        child: Text(
          '$categoryName sahifasi',
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }