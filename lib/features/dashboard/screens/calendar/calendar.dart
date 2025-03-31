import 'package:flutter/material.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

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
                // Sección "Today" con fecha
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: TSizes.defaultSpace,
                    vertical: TSizes.spaceBtwItems,
                  ),
                  child: DateHeader(),
                ),

                // Días de la semana con checkmarks
                const WeekdayTracker(),

                // Contenido desplazable (tarjetas)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(TSizes.defaultSpace),
                    children: const [
                      SizedBox(height: TSizes.spaceBtwItems),

                      // Tarjeta de Favoritos
                      FavoritesCard(),
                      SizedBox(height: TSizes.spaceBtwItems),

                      // Tarjeta de Desafío Diario
                      ChallengeCard(),
                      SizedBox(height: TSizes.spaceBtwItems),

                      // Tarjeta de Imagen con Cita
                      QuoteCard(),
                      SizedBox(height: TSizes.spaceBtwItems),
                    ],
                  ),
                ),
              ],
            ),
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
            Color(0xFFf78314), // Naranja inicial
            Color(0xFFfbc05e), // Naranja ligeramente más claro
            Color(0xFFfdd884), // Naranja aún más claro
            Color(0xFFfff3e0), // Amarillo muy pálido (casi blanco)
          ],
          stops: [0.0, 0.4, 0.6, 1.0],
        ),
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
        const SizedBox(height: TSizes.spaceBtwItems),
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
                  color: Color(0xFF555555), // Cambiado a gris oscuro
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
                  color: const Color(0xFFfff3e0)
                      .withAlpha(204), // Cambiado a tono claro de la paleta
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Have more to share?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF555555), // Cambiado a gris oscuro
                      ),
                    ),
                    Icon(
                      Icons.add,
                      color: Color(0xFFf78314), // Cambiado a naranja
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
              color: const Color(0xFFf78314), // Cambiado a naranja
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
        color: const Color(0xFFf78314), // Cambiado a naranja
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
          image: AssetImage(TImages.fitnessIllustration),
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

// // Botón flotante central para añadir
// class AddButton extends StatelessWidget {
//  const AddButton({super.key});

//  @override
//  Widget build(BuildContext context) {
//    return Positioned(
//      bottom: 40,
//      left: 0,
//      right: 0,
//      child: Center(
//        child: Container(
//          height: 60,
//          width: 60,
//          decoration: BoxDecoration(
//            color: const Color(0xFFFF7E7E),
//            borderRadius: BorderRadius.circular(30),
//            boxShadow: [
//              BoxShadow(
//                color: const Color(0xFFFF7E7E).withAlpha(104),
//                blurRadius: 10,
//                offset: const Offset(0, 4),
//              ),
//            ],
//          ),
//          child: const Icon(
//            Icons.add,
//            color: Colors.white,
//            size: 30,
//          ),
//        ),
//      ),
//    );
//  }
// }
