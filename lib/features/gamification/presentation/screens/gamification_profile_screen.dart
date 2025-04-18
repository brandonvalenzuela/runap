import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/data/models/gamification/achievement.dart';
import 'package:runap/data/models/gamification/challenge.dart';
import 'package:runap/data/models/gamification/user_achievement.dart';
import 'package:runap/data/models/gamification/user_challenge.dart';
import 'package:runap/features/gamification/presentation/manager/gamification_view_model.dart';
// --- Importaciones para Skeletons ---
import 'package:runap/common/widgets/loaders/skeleton_loader.dart'; // Ajusta la ruta si es necesario
import 'package:shimmer/shimmer.dart';
// --- Import para Animaciones ---
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class GamificationProfileScreen extends StatefulWidget {
  const GamificationProfileScreen({super.key});

  @override
  State<GamificationProfileScreen> createState() => _GamificationProfileScreenState();
}

class _GamificationProfileScreenState extends State<GamificationProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimationLevel;
  late Animation<Offset> _slideAnimationAchievements;
  late Animation<Offset> _slideAnimationChallenges;

  final GamificationViewModel viewModel = Get.find<GamificationViewModel>();
  bool _animationStarted = false; // Flag para iniciar animación solo una vez

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimationLevel = Tween<Offset>(begin: Offset(0.0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimationAchievements = Tween<Offset>(begin: Offset(-0.5, 0.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimationChallenges = Tween<Offset>(begin: Offset(0.5, 0.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Ya no iniciamos la animación aquí ni usamos 'ever'
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil de Progreso'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
               // Reiniciar flag de animación si refrescamos manualmente
               _animationStarted = false; 
               _animationController.reset();
               viewModel.loadUserData();
            },
          )
        ],
      ),
      body: Obx(() {
        final profileStatusValue = viewModel.profileStatus;

        // Iniciar animación la primera vez que el estado sea 'loaded'
        if (profileStatusValue == LoadingStatus.loaded && !_animationStarted) {
          // Usar addPostFrameCallback para asegurar que se llame después del build inicial
          WidgetsBinding.instance.addPostFrameCallback((_) { 
            if (mounted) { // Comprobar si sigue montado
              _animationController.forward();
              _animationStarted = true;
            }
          });
        }

        if (profileStatusValue == LoadingStatus.loading) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLevelSectionSkeleton(context),
                const SizedBox(height: 24),
                _buildAchievementsSectionSkeleton(context),
                const SizedBox(height: 24),
                _buildChallengesSectionSkeleton(context),
              ],
            ),
          );
        }
        
        if (profileStatusValue == LoadingStatus.error) {
          return Center(
            child: Text('Error: ${viewModel.errorMessage}'),
          );
        }
        
        final profile = viewModel.profile;
        if (profile == null && profileStatusValue != LoadingStatus.loading) {
          return const Center(
            child: Text('No se encontró información de perfil'),
          );
        }

        // Evitar mostrar contenido brevemente si profile es null mientras carga
        if (profile == null) {
            return const Center(child: CircularProgressIndicator()); // O mostrar Skeleton
        }
        
        // --- El contenido principal ahora se anima --- 
        return RefreshIndicator(
          onRefresh: () async {
            _animationStarted = false;
            _animationController.reset();
            await viewModel.loadUserData();
          },
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de nivel y puntos con animación
                  SlideTransition(
                    position: _slideAnimationLevel,
                    child: _buildLevelSection(profile.totalPoints, profile.level),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección de logros recientes con animación escalonada
                  SlideTransition(
                    position: _slideAnimationAchievements,
                    child: AnimationLimiter( // Envolver con AnimationLimiter
                      child: _buildRecentAchievementsSection(
                        profile.recentAchievements ?? [], 
                        profile.achievementsCount
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección de retos activos con animación escalonada
                  SlideTransition(
                    position: _slideAnimationChallenges,
                    child: AnimationLimiter( // Envolver con AnimationLimiter
                      child: _buildActiveChallengesSection(
                        profile.activeChallenges ?? [],
                        profile.challengesCompletedCount
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
  
  Widget _buildLevelSection(int totalPoints, dynamic level) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar de nivel o ícono
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade700, width: 2),
              ),
              child: Center(
                child: level != null 
                  ? level.iconUrl != null
                    ? Image.network(level.iconUrl)
                    : Text(
                        'Nv ${level.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blue,
                        ),
                      )
                  : const Icon(Icons.emoji_events, size: 40, color: Colors.blue),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Nombre de nivel y puntos
            Text(
              level?.name ?? 'Nivel Principiante',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '$totalPoints puntos',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Barra de progreso
            if (level != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _calculateLevelProgress(totalPoints, level),
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Texto de progreso
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${level.minPoints} pts',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '${level.maxPoints} pts',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  
                  if (level.benefits != null && level.benefits!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Beneficios de este nivel:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(level.benefits!),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  double _calculateLevelProgress(int points, dynamic level) {
    // Si los puntos están por debajo del mínimo, retornar 0
    if (points < level.minPoints) return 0.0;
    
    // Si los puntos están por encima del máximo, retornar 1
    if (points >= level.maxPoints) return 1.0;
    
    // Calcular el progreso proporcional dentro del nivel
    final pointsInLevel = points - level.minPoints;
    final totalPointsInLevel = level.maxPoints - level.minPoints;
    
    return pointsInLevel / totalPointsInLevel;
  }
  
  Widget _buildRecentAchievementsSection(List<UserAchievement> achievements, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Logros Recientes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navegar a la pantalla de todos los logros
                // Get.toNamed('/achievements');
              },
              child: Text('Ver todos ($total)'),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        achievements.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Aún no has desbloqueado ningún logro. ¡Completa tus entrenamientos para ganar logros!',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: achievements.length > 3 ? 3 : achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  // Añadir widget de animación escalonada
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildAchievementCard(achievement),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
  
  Widget _buildAchievementCard(UserAchievement userAchievement) {
    final Achievement? achievement = userAchievement.achievement;
    
    if (achievement == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: achievement.iconUrl != null
                ? Image.network(achievement.iconUrl!)
                : const Icon(Icons.emoji_events, color: Colors.amber),
          ),
        ),
        title: Text(
          achievement.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 4),
            Text(
              'Desbloqueado el ${_formatDate(userAchievement.unlockedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+${achievement.points}',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActiveChallengesSection(List<UserChallenge> challenges, int completed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Retos Activos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navegar a la pantalla de todos los retos
                // Get.toNamed('/challenges');
              },
              child: Text('Ver todos (${challenges.length + completed})'),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        challenges.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '¡No tienes retos activos! Revisa la sección de retos para participar en nuevos desafíos.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: challenges.length > 3 ? 3 : challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                   // Añadir widget de animación escalonada
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildChallengeCard(challenge),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
  
  Widget _buildChallengeCard(UserChallenge userChallenge) {
    final Challenge? challenge = userChallenge.challenge;
    
    if (challenge == null) {
      return const SizedBox.shrink();
    }
    
    // Calcular progreso
    final progress = userChallenge.currentValue / challenge.goalValue;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  challenge.type == 'distance' ? Icons.directions_run : Icons.timer,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challenge.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${challenge.points}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(challenge.description),
            
            const SizedBox(height: 12),
            
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  userChallenge.completed ? Colors.green : Colors.blue,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Valores de progreso
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${userChallenge.currentValue.toStringAsFixed(1)} ${challenge.goalUnit}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${challenge.goalValue.toStringAsFixed(1)} ${challenge.goalUnit}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Fecha límite
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Finaliza el ${_formatDate(challenge.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Función helper para formatear fechas
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // --- WIDGETS SKELETON ---

  Widget _buildLevelSectionSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: baseColor, // Fondo de la tarjeta
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SkeletonCircle(radius: 40),
              const SizedBox(height: 16),
              Container(width: 150, height: 22, color: highlightColor),
              const SizedBox(height: 8),
              Container(width: 100, height: 18, color: highlightColor),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 12, color: highlightColor),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 50, height: 12, color: highlightColor),
                  Container(width: 50, height: 12, color: highlightColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSectionSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 180, height: 20, color: highlightColor),
              Container(width: 80, height: 20, color: highlightColor),
            ],
          ),
          const SizedBox(height: 16),
          // Skeleton para 2 tarjetas de logros
          ...List.generate(2, (_) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: baseColor,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const SkeletonCircle(radius: 25),
              title: Container(width: 150, height: 16, color: highlightColor),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Container(width: 200, height: 12, color: highlightColor),
                  const SizedBox(height: 4),
                  Container(width: 100, height: 10, color: highlightColor),
                ],
              ),
              trailing: Container(width: 40, height: 20, decoration: BoxDecoration(color: highlightColor, borderRadius: BorderRadius.circular(12))),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChallengesSectionSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 150, height: 20, color: highlightColor),
              Container(width: 100, height: 20, color: highlightColor),
            ],
          ),
          const SizedBox(height: 16),
          // Skeleton para 2 tarjetas de retos
          ...List.generate(2, (_) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: baseColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonWidget(height: 16, width: 16, borderRadius: 4), // Icon
                      const SizedBox(width: 8),
                      Expanded(child: Container(width: double.infinity, height: 16, color: highlightColor)), // Title
                      const SizedBox(width: 8),
                      Container(width: 40, height: 20, decoration: BoxDecoration(color: highlightColor, borderRadius: BorderRadius.circular(12))), // Points
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 12, color: highlightColor), // Description line 1
                  const SizedBox(height: 4),
                  Container(width: 180, height: 12, color: highlightColor), // Description line 2
                  const SizedBox(height: 12),
                  Container(width: double.infinity, height: 10, color: highlightColor), // Progress bar
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 80, height: 12, color: highlightColor),
                      Container(width: 80, height: 12, color: highlightColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(width: 100, height: 12, color: highlightColor),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
} 