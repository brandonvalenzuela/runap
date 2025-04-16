import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/data/models/gamification/achievement.dart';
import 'package:runap/data/models/gamification/challenge.dart';
import 'package:runap/data/models/gamification/user_achievement.dart';
import 'package:runap/data/models/gamification/user_challenge.dart';
import 'package:runap/features/gamification/presentation/manager/gamification_view_model.dart';

class GamificationProfileScreen extends StatelessWidget {
  const GamificationProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GamificationViewModel viewModel = Get.find<GamificationViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil de Progreso'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadUserData(),
          )
        ],
      ),
      body: Obx(() {
        final profileStatus = viewModel.profileStatus;
        
        if (profileStatus == LoadingStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (profileStatus == LoadingStatus.error) {
          return Center(
            child: Text('Error: ${viewModel.errorMessage}'),
          );
        }
        
        final profile = viewModel.profile;
        if (profile == null) {
          return const Center(
            child: Text('No se encontró información de perfil'),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => viewModel.loadUserData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de nivel y puntos
                _buildLevelSection(profile.totalPoints, profile.level),
                
                const SizedBox(height: 24),
                
                // Sección de logros recientes
                _buildRecentAchievementsSection(
                  profile.recentAchievements ?? [], 
                  profile.achievementsCount
                ),
                
                const SizedBox(height: 24),
                
                // Sección de retos activos
                _buildActiveChallengesSection(
                  profile.activeChallenges ?? [],
                  profile.challengesCompletedCount
                ),
              ],
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
                  return _buildAchievementCard(achievement);
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
                  return _buildChallengeCard(challenge);
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
} 