import 'package:flutter/material.dart';

class Test2 extends StatelessWidget {
  const Test2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
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
      body: Stack(
        children: [
          // Fondo con gradiente
          const BackgroundGradient(),

          // Contenido principal
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra superior con avatar y perfil
                const TopBar(),

                // Sección "Today" con fecha
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: DateHeader(),
                ),

                // Días de la semana con checkmarks
                const WeekdayTracker(),

                // Contenido desplazable (tarjetas)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 24.0),
                    children: const [
                      SizedBox(height: 12),

                      // Tarjeta de Favoritos
                      FavoritesCard(),
                      SizedBox(height: 16),

                      // Tarjeta de Desafío Diario
                      ChallengeCard(),
                      SizedBox(height: 16),

                      // Tarjeta de Imagen con Cita
                      QuoteCard(),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barra de navegación inferior
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(),
          ),
        ],
      ),
    );
  }
}

// Widget de fondo con gradiente
class BackgroundGradient extends StatelessWidget {
  const BackgroundGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF6D91), // Rosa intenso
            Color(0xFFFF8F8F), // Rosa suave
            Color(0xFFF0F1F5), // Blanco grisáceo
            Color(0xFFF0F1F5), // Blanco grisáceo
          ],
          stops: [0.0, 0.4, 0.6, 1.0],
        ),
      ),
    );
  }
}

// Widget de barra superior con avatar y perfil
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hora actual
          const Text(
            '2:01',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Indicadores de estado del dispositivo
          Row(
            children: const [
              Text(
                '1.36 KB/s',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
              SizedBox(width: 8),
              Icon(Icons.bluetooth, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Icon(Icons.volume_off, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Icon(Icons.signal_cellular_alt, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Icon(Icons.wifi, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Icon(Icons.battery_charging_full, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(
                '81%',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget de encabezado de fecha
class DateHeader extends StatelessWidget {
  const DateHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/robot_avatar.png', // Asegúrate de tener esta imagen en tus assets
              height: 50,
              width: 50,
              // Alternativa: usa un icono en vez de la imagen
              // child: Icon(Icons.android, size: 40, color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Today',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Text(
          'FRIDAY, MARCH 28',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// Widget para el seguimiento de días de la semana
class WeekdayTracker extends StatelessWidget {
  const WeekdayTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWeekdayItem('Mon', true),
          _buildWeekdayItem('Tue', true),
          _buildWeekdayItem('Wed', true),
          _buildWeekdayItem('Thu', true),
          _buildWeekdayItem('Fri', true, isSelected: true),
          _buildWeekdayItem('Sat', false, label: '29'),
          _buildWeekdayItem('Sun', false, label: '30'),
        ],
      ),
    );
  }

  Widget _buildWeekdayItem(String day, bool isCompleted,
      {bool isSelected = false, String? label}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withAlpha(64) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(204),
            ),
          ),
          const SizedBox(height: 4),
          isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
        ],
      ),
    );
  }
}

// Widget de la tarjeta de Favoritos
// Widget de la tarjeta de Favoritos
class FavoritesCard extends StatelessWidget {
  const FavoritesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Tarjeta principal primero (estará en el fondo)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF526380),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Every Friday, share your favorite things',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Botón de "Have more to share?"
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Have more to share?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF526380),
                      ),
                    ),
                    Icon(
                      Icons.add,
                      color: Color(0xFFFF7E7E),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Círculo superior con check después (estará por encima)
        Positioned(
          top: -30,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7E7E),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

// Widget de la tarjeta de Desafío Diario
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7E7E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.flag,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ENDS IN 09:58:49',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              // Imagen de una bandera o algo similar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(77),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flag,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Título del desafío
          const Text(
            'Daily',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const Text(
            'Challenge',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Aquí iría la ilustración de la montaña con la bandera
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 100,
              height: 80,
              // En lugar de una imagen, usamos un placeholder
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.landscape,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de la tarjeta con cita e imagen
class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage(
              'assets/nature_image.jpg'), // Asegúrate de tener esta imagen
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(55),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Overlay oscuro para mejorar la legibilidad del texto
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withAlpha(77),
            ),
          ),

          // Texto de la cita
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(104),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Everything you can imagine is real.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Botón de expandir
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(104),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de la barra de navegación inferior
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(Icons.wb_sunny_outlined, true),
          _buildNavItem(Icons.chat_bubble_outline, false),
          const SizedBox(width: 60), // Espacio para el botón central
          _buildNavItem(Icons.show_chart, false),
          _buildNavItem(Icons.folder_outlined, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected) {
    return Icon(
      icon,
      size: 24,
      color: isSelected ? const Color(0xFF526380) : Colors.grey,
    );
  }
}

// Botón flotante central para añadir
class AddButton extends StatelessWidget {
  const AddButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7E7E),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7E7E).withAlpha(104),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}
