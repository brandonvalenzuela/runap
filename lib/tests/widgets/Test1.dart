import 'package:flutter/material.dart';

class Test1 extends StatelessWidget {
  const Test1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF2F3F7),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and profile button
              const HeaderWidget(title: 'Your Entries'),
              const SizedBox(height: 16),

              // Stats Card
              const StatsCardWidget(),
              const SizedBox(height: 16),

              // Promo Card
              const PromoCardWidget(
                title: 'Just For You',
                subtitle: 'ENDS IN 11:53:59',
              ),
              const SizedBox(height: 24),

              // Date Header
              const DateHeaderWidget(
                day: '28',
                month: 'MAR',
                weekday: 'FRIDAY',
                label: 'Today',
              ),
              const SizedBox(height: 16),

              // Entries List
              Expanded(
                child: ListView(
                  children: const [
                    EntryCardWidget(
                      iconBackgroundColor: Color(0xFFF8E8E8),
                      iconColor: Color(0xFFE5A4A4),
                      title: 'Daily Reflection',
                      time: '11:26 AM',
                      content:
                          'My signature flavor of ice cream would be melon.',
                    ),
                    SizedBox(height: 16),
                    EntryCardWidget(
                      iconBackgroundColor: Color(0xFFF2F3F7),
                      iconColor: Color(0xFF8E8E93),
                      title: 'Nota de prueba 2',
                      time: '11:24 AM',
                      content: 'Nota de prueba 2',
                      tags: ['weather', 'blessed'],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFEF7A85),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// Widget para el encabezado
class HeaderWidget extends StatelessWidget {
  final String title;

  const HeaderWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEEEEEE),
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.person_outline,
            color: Colors.black54,
            size: 28,
          ),
        ),
      ],
    );
  }
}

// Widget para la tarjeta de estadísticas
class StatsCardWidget extends StatelessWidget {
  const StatsCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          StatItemWidget(number: '5', label: 'reflections'),
          StatItemWidget(number: '2', label: 'check-ins'),
          StatItemWidget(number: '1', label: 'photos'),
        ],
      ),
    );
  }
}

// Widget para el elemento de estadística individual
class StatItemWidget extends StatelessWidget {
  final String number;
  final String label;

  const StatItemWidget({
    super.key,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }
}

// Widget para la tarjeta promocional
class PromoCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const PromoCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF7A85), Color(0xFFEC6B76)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF7A85).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }
}

// Widget para el encabezado de fecha
class DateHeaderWidget extends StatelessWidget {
  final String day;
  final String month;
  final String weekday;
  final String label;

  const DateHeaderWidget({
    super.key,
    required this.day,
    required this.month,
    required this.weekday,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                month,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              weekday,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Widget para la tarjeta de entrada
class EntryCardWidget extends StatelessWidget {
  final Color iconBackgroundColor;
  final Color iconColor;
  final String title;
  final String time;
  final String content;
  final List<String>? tags;

  const EntryCardWidget({
    super.key,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.content,
    this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  title == 'Daily Reflection'
                      ? Icons.auto_awesome
                      : Icons.circle_outlined,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          if (tags != null && tags!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: tags!.map((tag) => TagWidget(label: tag)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget para las etiquetas
class TagWidget extends StatelessWidget {
  final String label;

  const TagWidget({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    );
  }
}

// Widget para la barra de navegación inferior
class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.wb_sunny_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {},
            ),
            const SizedBox(width: 40), // Espacio para el FAB
            IconButton(
              icon: const Icon(Icons.show_chart),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.document_scanner_outlined,
                  color: Colors.black87),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
