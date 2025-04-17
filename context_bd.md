# Script completo MySQL – Aplicación de Entrenamiento para Corredores

```sql
-- ================================================================
-- SCRIPT COMPLETO PARA APP DE ENTRENAMIENTO DE CORREDORES
-- ================================================================
-- Este script implementa una base de datos MySQL para una aplicación 
-- de entrenamiento para corredores con alta escalabilidad, arquitectura 
-- multi-esquema y optimizaciones para millones de usuarios.
-- ================================================================


-- Desactivar verificación de claves foráneas durante la creación
SET foreign_key_checks = 0;


-- ================================================================
-- PARTE 1: ARQUITECTURA MULTI-ESQUEMA PARA ALTA ESCALABILIDAD
-- ================================================================
-- Esta parte divide la base de datos en múltiples esquemas organizados 
-- por dominio funcional para mejorar la escalabilidad y mantenibilidad.
-- ================================================================


-- --------------------------------------
-- 1.1 ESQUEMA DE USUARIOS (integrado con Firebase/Supabase)
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `users`;

-- Tabla principal de usuarios (sincronizada con Firebase/Supabase)
CREATE TABLE IF NOT EXISTS `users`.`Users` (
  `UserId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `ExternalAuthId` VARCHAR(128) NOT NULL COMMENT 'ID único de Firebase/Supabase',
  `FirstName` VARCHAR(50) COMMENT 'Nombre del usuario',
  `LastName` VARCHAR(50) COMMENT 'Apellido del usuario',
  `Email` VARCHAR(100) NOT NULL COMMENT 'Email verificado por el proveedor de autenticación',
  `PhoneNumber` VARCHAR(20) COMMENT 'Número de teléfono opcional',
  `ProfilePhotoUrl` VARCHAR(255) COMMENT 'URL de foto de perfil (puede provenir del proveedor)',
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `LastLogin` DATETIME COMMENT 'Última sesión registrada',
  `Status` VARCHAR(20) DEFAULT 'active' COMMENT 'Estado: active, inactive, suspended',
  `LastUpdated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX `IX_Users_ExternalAuthId` (`ExternalAuthId`),
  UNIQUE INDEX `IX_Users_Email` (`Email`)
) ENGINE=InnoDB COMMENT='Tabla principal de usuarios sincronizada con proveedor de autenticación';

-- Tabla de roles para autorización interna
CREATE TABLE IF NOT EXISTS `users`.`Roles` (
  `RoleId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `RoleName` VARCHAR(30) NOT NULL COMMENT 'Nombre del rol',
  `Description` VARCHAR(255) COMMENT 'Descripción del rol',
  UNIQUE INDEX `IX_Roles_RoleName` (`RoleName`)
) ENGINE=InnoDB COMMENT='Roles para autorización interna';

-- Relación entre usuarios y roles
CREATE TABLE IF NOT EXISTS `users`.`UserRoles` (
  `UserId` INT NOT NULL,
  `RoleId` INT NOT NULL,
  `AssignedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `AssignedBy` INT COMMENT 'Usuario que asignó el rol',
  PRIMARY KEY (`UserId`, `RoleId`),
  CONSTRAINT `FK_UserRoles_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE,
  CONSTRAINT `FK_UserRoles_Roles` FOREIGN KEY (`RoleId`) 
    REFERENCES `users`.`Roles` (`RoleId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Asignación de roles a usuarios';

-- Configuraciones de usuario (preferencias de aplicación)
CREATE TABLE IF NOT EXISTS `users`.`UserSettings` (
  `UserId` INT NOT NULL,
  `NotificationPreferences` JSON COMMENT 'Preferencias de notificación',
  `UIPreferences` JSON COMMENT 'Preferencias de interfaz',
  `Language` CHAR(2) NOT NULL DEFAULT 'es' COMMENT 'Idioma preferido',
  `Timezone` VARCHAR(50) DEFAULT 'UTC' COMMENT 'Zona horaria',
  `UpdatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`UserId`),
  CONSTRAINT `FK_UserSettings_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Configuraciones y preferencias de usuario';

-- Tabla de logs para seguimiento de actividad (simplificada)
CREATE TABLE IF NOT EXISTS `users`.`ActivityLogs` (
  `LogId` BIGINT NOT NULL,
  `YearCreated` INT NOT NULL COMMENT 'Año para particionamiento',
  `UserId` INT NOT NULL,
  `Activity` VARCHAR(100) NOT NULL COMMENT 'Tipo de actividad',
  `Details` JSON COMMENT 'Detalles de la actividad',
  `IPAddress` VARCHAR(45) COMMENT 'Dirección IP',
  `UserAgent` VARCHAR(255) COMMENT 'User agent del navegador',
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`YearCreated`, `LogId`),
  INDEX `IX_ActivityLogs_UserId` (`UserId`),
  INDEX `IX_ActivityLogs_CreatedAt` (`CreatedAt`)
) 
COMMENT='Registro de actividades de usuario para auditoría'
ENGINE=InnoDB
PARTITION BY RANGE (`YearCreated`) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION pfuture VALUES LESS THAN MAXVALUE
);

-- Datos iniciales para roles
INSERT INTO `users`.`Roles` (RoleName, Description) VALUES
('admin', 'Administrador con acceso completo'),
('trainer', 'Entrenador que puede crear planes y supervisar a usuarios'),
('member', 'Usuario regular con acceso a funciones básicas');

-- --------------------------------------
-- 1.2 ESQUEMA DE ENTRENAMIENTO
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `training`;

-- Planes de entrenamiento
CREATE TABLE IF NOT EXISTS `training`.`TrainingPlans` (
  `TrainingPlanId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL COMMENT 'Usuario propietario del plan',
  `Title` VARCHAR(100) NOT NULL COMMENT 'Título del plan',
  `Description` TEXT COMMENT 'Descripción detallada',
  `GeneratedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `IAOutput` MEDIUMTEXT COMMENT 'Salida detallada del algoritmo IA',
  `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
  `FocusArea` VARCHAR(50) COMMENT 'Enfoque: speed, endurance, race_prep, etc.',
  `DifficultyLevel` TINYINT NOT NULL DEFAULT 2 COMMENT 'Nivel 1-5',
  `WeeklyVolume` DECIMAL(6,2) COMMENT 'Volumen semanal en km',
  `AdaptationFrequency` INT DEFAULT 14 COMMENT 'Frecuencia de adaptación en días',
  `AIModelVersion` VARCHAR(20) COMMENT 'Versión del modelo IA que lo generó',
  `LastAdaptedAt` DATETIME COMMENT 'Última adaptación del plan',
  `AdaptationCount` INT NOT NULL DEFAULT 0 COMMENT 'Número de adaptaciones realizadas',
  `IntensityDistribution` JSON COMMENT 'Distribución de intensidades recomendada',
  INDEX `IX_TrainingPlans_UserId` (`UserId`),
  CONSTRAINT `FK_TrainingPlans_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Planes de entrenamiento generados por IA';

-- Entrenamientos específicos dentro de planes
CREATE TABLE IF NOT EXISTS `training`.`Workouts` (
  `WorkoutId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Name` VARCHAR(100) NOT NULL,
  `Description` TEXT,
  `DurationMinutes` INT NOT NULL,
  `Difficulty` TINYINT NOT NULL COMMENT '1-5 escala de dificultad',
  `EquipmentRequired` VARCHAR(255),
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `TrainingPlanId` INT NOT NULL,
  INDEX `IX_Workouts_TrainingPlanId` (`TrainingPlanId`),
  CONSTRAINT `FK_Workouts_TrainingPlans` FOREIGN KEY (`TrainingPlanId`) 
    REFERENCES `training`.`TrainingPlans` (`TrainingPlanId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Entrenamientos específicos dentro de planes';

-- Sesiones de entrenamiento programadas
CREATE TABLE IF NOT EXISTS `training`.`TrainingSessions` (
  `TrainingSessionId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `SessionDate` DATETIME NOT NULL,
  `Notes` TEXT,
  `Completed` TINYINT(1) NOT NULL DEFAULT 0,
  `WorkoutId` INT NOT NULL,
  `UserId` INT NOT NULL,
  `TrainingPlanId` INT NOT NULL,
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `SessionType` VARCHAR(30) COMMENT 'Tipo: recovery, easy, moderate, threshold, interval, repetition',
  `PrimaryGoal` VARCHAR(100) COMMENT 'Objetivo principal',
  `TargetDistanceKm` DECIMAL(6,2) COMMENT 'Distancia objetivo',
  `TargetPace` TIME COMMENT 'Ritmo objetivo',
  `TargetHeartRate` VARCHAR(20) COMMENT 'Zona de FC objetivo',
  `IntensityLevel` TINYINT COMMENT 'Nivel de intensidad 1-5',
  `Route` JSON COMMENT 'Ruta sugerida si aplica',
  INDEX `IX_TrainingSessions_UserId_SessionDate` (`UserId`, `SessionDate`),
  INDEX `IX_TrainingSessions_WorkoutId` (`WorkoutId`),
  INDEX `IX_TrainingSessions_TrainingPlanId` (`TrainingPlanId`),
  INDEX `IX_TrainingSessions_SessionDate` (`SessionDate`),
  CONSTRAINT `FK_TrainingSessions_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`),
  CONSTRAINT `FK_TrainingSessions_Workouts` FOREIGN KEY (`WorkoutId`) 
    REFERENCES `training`.`Workouts` (`WorkoutId`),
  CONSTRAINT `FK_TrainingSessions_TrainingPlans` FOREIGN KEY (`TrainingPlanId`) 
    REFERENCES `training`.`TrainingPlans` (`TrainingPlanId`)
) 
ENGINE=InnoDB
COMMENT='Sesiones de entrenamiento programadas';






-- Tabla para historial de adaptaciones de planes
CREATE TABLE IF NOT EXISTS `training`.`TrainingPlanHistory` (
  `HistoryId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `TrainingPlanId` INT NOT NULL,
  `PlanVersion` INT NOT NULL COMMENT 'Versión incremental del plan',
  `AdaptationReason` VARCHAR(100) NOT NULL COMMENT 'Razón de la adaptación',
  `AdaptationDetails` JSON COMMENT 'Detalles técnicos de la adaptación',
  `AdaptedAt` DATETIME NOT NULL,
  INDEX `IX_TrainingPlanHistory_TrainingPlanId` (`TrainingPlanId`),
  CONSTRAINT `FK_TrainingPlanHistory_TrainingPlans` FOREIGN KEY (`TrainingPlanId`) 
    REFERENCES `training`.`TrainingPlans` (`TrainingPlanId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Historial de versiones de planes de entrenamiento';


DELIMITER //
CREATE DEFINER=`root`@`%` PROCEDURE `ArchiveOldTrainingSessions`(IN archiveBeforeDate DATE)
BEGIN
    INSERT INTO `training`.`TrainingSessionsArchive` 
    SELECT * FROM `training`.`TrainingSessions` 
    WHERE `SessionDate` < archiveBeforeDate;
    
    DELETE FROM `training`.`TrainingSessions` 
    WHERE `SessionDate` < archiveBeforeDate;
END //
DELIMITER ;


-- --------------------------------------
-- 1.3 ESQUEMA DE CALENDARIO
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `calendar`;


-- Calendarios de usuario
CREATE TABLE IF NOT EXISTS `calendar`.`Calendars` (
  `CalendarId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `TrainingId` INT,
  `Name` VARCHAR(100),
  `Description` VARCHAR(255),
  `IsDefault` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si es el calendario por defecto',
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `IX_Calendars_UserId` (`UserId`),
  INDEX `IX_Calendars_TrainingId` (`TrainingId`),
  CONSTRAINT `FK_Calendars_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE,
  CONSTRAINT `FK_Calendars_TrainingPlans` FOREIGN KEY (`TrainingId`) 
    REFERENCES `training`.`TrainingPlans` (`TrainingPlanId`)
) ENGINE=InnoDB COMMENT='Calendarios de usuario';


-- Eventos de calendario
CREATE TABLE IF NOT EXISTS `calendar`.`Events` (
  `EventId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `CalendarId` INT NOT NULL,
  `Title` VARCHAR(100),
  `Description` TEXT,
  `StartTime` DATETIME NOT NULL,
  `EndTime` DATETIME,
  `Type` TINYINT NOT NULL COMMENT 'Tipo de evento: 1=Training, 2=Assessment, 3=Other',
  `SurveyId` INT,
  `TrainingSessionId` INT,
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `IX_Events_CalendarId` (`CalendarId`),
  INDEX `IX_Events_StartTime_EndTime` (`StartTime`, `EndTime`),
  INDEX `IX_Events_TrainingSessionId` (`TrainingSessionId`),
  CONSTRAINT `FK_Events_Calendars` FOREIGN KEY (`CalendarId`) 
    REFERENCES `calendar`.`Calendars` (`CalendarId`) ON DELETE CASCADE,
  CONSTRAINT `FK_Events_TrainingSessions` FOREIGN KEY (`TrainingSessionId`) 
    REFERENCES `training`.`TrainingSessions` (`TrainingSessionId`)
) 
ENGINE=InnoDB
COMMENT='Eventos en calendarios';


-- 1. Primero, crear la tabla de archivo
CREATE TABLE `calendar`.`EventsArchive` LIKE `calendar`.`Events`;


-- 2. Ahora crear el procedimiento de archivado
DELIMITER //
CREATE PROCEDURE `calendar`.`ArchiveOldEvents`(IN cutoffDate DATE)
BEGIN
    INSERT INTO `calendar`.`EventsArchive` 
    SELECT * FROM `calendar`.`Events` 
    WHERE `StartTime` < cutoffDate;
    
    DELETE FROM `calendar`.`Events` 
    WHERE `StartTime` < cutoffDate;
END //
DELIMITER ;






-- --------------------------------------
-- 1.4 ESQUEMA DE ENCUESTAS
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `survey`;


-- Encuestas
CREATE TABLE IF NOT EXISTS `survey`.`Surveys` (
  `SurveyId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Title` VARCHAR(100),
  `Description` TEXT,
  `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `CreatedBy` INT NOT NULL COMMENT 'Usuario que creó la encuesta',
  INDEX `IX_Surveys_CreatedBy` (`CreatedBy`),
  CONSTRAINT `FK_Surveys_Users` FOREIGN KEY (`CreatedBy`) 
    REFERENCES `users`.`Users` (`UserId`)
) ENGINE=InnoDB COMMENT='Encuestas para evaluación de usuarios';


-- Preguntas de encuestas
CREATE TABLE IF NOT EXISTS `survey`.`Questions` (
  `QuestionId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `SurveyId` INT NOT NULL,
  `QuestionText` VARCHAR(255),
  `QuestionType` VARCHAR(30) COMMENT 'Tipo: text, multiplechoice, rating, etc.',
  `IsRequired` TINYINT(1) NOT NULL DEFAULT 0,
  `QuestionOrder` INT NOT NULL DEFAULT 0,
  INDEX `IX_Questions_SurveyId` (`SurveyId`),
  CONSTRAINT `FK_Questions_Surveys` FOREIGN KEY (`SurveyId`) 
    REFERENCES `survey`.`Surveys` (`SurveyId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Preguntas dentro de encuestas';


-- Opciones para preguntas de selección múltiple
CREATE TABLE IF NOT EXISTS `survey`.`QuestionOptions` (
  `OptionId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `QuestionId` INT NOT NULL,
  `OptionText` VARCHAR(255) NOT NULL,
  `OptionOrder` INT NOT NULL DEFAULT 0,
  INDEX `IX_QuestionOptions_QuestionId` (`QuestionId`),
  CONSTRAINT `FK_QuestionOptions_Questions` FOREIGN KEY (`QuestionId`) 
    REFERENCES `survey`.`Questions` (`QuestionId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Opciones para preguntas de selección múltiple';


-- Respuestas a preguntas
CREATE TABLE IF NOT EXISTS `survey`.`Answers` (
  `AnswerId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `QuestionId` INT NOT NULL,
  `UserId` INT NOT NULL,
  `ResponseText` TEXT,
  `ResponseDate` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `IX_Answers_QuestionId` (`QuestionId`),
  INDEX `IX_Answers_UserId_ResponseDate` (`UserId`, `ResponseDate`),
  INDEX `IX_Answers_ResponseDate` (`ResponseDate`),
  CONSTRAINT `FK_Answers_Questions` FOREIGN KEY (`QuestionId`)
    REFERENCES `survey`.`Questions` (`QuestionId`),
  CONSTRAINT `FK_Answers_Users` FOREIGN KEY (`UserId`)
    REFERENCES `users`.`Users` (`UserId`)
) 
ENGINE=InnoDB
COMMENT='Respuestas a preguntas de encuestas';


-- --------------------------------------
-- 1.5 ESQUEMA DE FACTURACIÓN
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `billing`;


-- Planes de suscripción disponibles
CREATE TABLE IF NOT EXISTS `billing`.`SubscriptionPlans` (
  `PlanId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Name` VARCHAR(50) NOT NULL,
  `Description` TEXT,
  `Price` DECIMAL(10,2) NOT NULL,
  `BillingCycle` VARCHAR(20) NOT NULL COMMENT 'monthly, yearly, etc.',
  `Features` JSON COMMENT 'Características incluidas',
  `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE INDEX `IX_SubscriptionPlans_Name` (`Name`)
) ENGINE=InnoDB COMMENT='Planes de suscripción disponibles';


-- Suscripciones de usuarios
CREATE TABLE IF NOT EXISTS `billing`.`Subscriptions` (
  `SubscriptionId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `PlanId` INT NOT NULL,
  `StartDate` DATETIME NOT NULL,
  `EndDate` DATETIME NOT NULL,
  `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
  `AutoRenew` TINYINT(1) NOT NULL DEFAULT 1,
  `ExternalSubscriptionId` VARCHAR(100) COMMENT 'ID de referencia en pasarela de pago',
  `LastPaymentDate` DATETIME,
  `NextPaymentDate` DATETIME,
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `IX_Subscriptions_UserId_IsActive` (`UserId`, `IsActive`),
  INDEX `IX_Subscriptions_PlanId` (`PlanId`),
  CONSTRAINT `FK_Subscriptions_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`),
  CONSTRAINT `FK_Subscriptions_Plans` FOREIGN KEY (`PlanId`) 
    REFERENCES `billing`.`SubscriptionPlans` (`PlanId`)
) ENGINE=InnoDB COMMENT='Suscripciones activas de usuarios';


-- Pagos realizados
CREATE TABLE IF NOT EXISTS `billing`.`Payments` (
  `PaymentId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `SubscriptionId` INT NOT NULL,
  `Amount` DECIMAL(10,2) NOT NULL,
  `Currency` CHAR(3) NOT NULL DEFAULT 'USD',
  `PaymentDate` DATETIME NOT NULL,
  `PaymentMethod` VARCHAR(50) COMMENT 'credit_card, paypal, etc.',
  `PaymentStatus` VARCHAR(20) NOT NULL COMMENT 'succeeded, failed, pending',
  `TransactionId` VARCHAR(100) COMMENT 'ID de transacción en la pasarela',
  `ReceiptUrl` VARCHAR(255) COMMENT 'URL del comprobante',
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `IX_Payments_SubscriptionId` (`SubscriptionId`),
  INDEX `IX_Payments_PaymentDate` (`PaymentDate`),
  CONSTRAINT `FK_Payments_Subscriptions` FOREIGN KEY (`SubscriptionId`) 
    REFERENCES `billing`.`Subscriptions` (`SubscriptionId`)
) ENGINE=InnoDB COMMENT='Historial de pagos realizados';


-- Historial de cambios en suscripciones
CREATE TABLE IF NOT EXISTS `billing`.`SubscriptionHistory` (
  `HistoryId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `SubscriptionId` INT NOT NULL,
  `ChangeDate` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ChangedField` VARCHAR(50) NOT NULL,
  `OldValue` VARCHAR(100),
  `NewValue` VARCHAR(100),
  `ChangedBy` INT COMMENT 'Usuario o sistema que realizó el cambio',
  INDEX `IX_SubscriptionHistory_SubscriptionId` (`SubscriptionId`),
  CONSTRAINT `FK_SubscriptionHistory_Subscriptions` FOREIGN KEY (`SubscriptionId`) 
    REFERENCES `billing`.`Subscriptions` (`SubscriptionId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Historial de cambios en suscripciones';


-- Datos iniciales para planes de suscripción
INSERT INTO `billing`.`SubscriptionPlans` (Name, Description, Price, BillingCycle, Features, IsActive) VALUES
('Free', 'Plan básico gratuito', 0.00, 'monthly', '{"features":["basic_training_plans","basic_metrics","limited_content","basic_gamification"]}', 1),
('Premium', 'Plan premium con características avanzadas', 9.99, 'monthly', '{"features":["adaptive_plans","device_integration","full_gamification","advanced_metrics","partial_content_access"]}', 1),
('Annual', 'Plan anual con descuento', 99.99, 'yearly', '{"features":["highly_adaptive_plans","advanced_feedback","all_educational_content","full_device_integration","premium_social","all_features"]}', 1);


-- ================================================================
-- PARTE 2: EXTENSIONES PARA APP DE ENTRENAMIENTO DE CORREDORES
-- ================================================================
-- Esta parte añade las tablas específicas para las funcionalidades
-- de la aplicación de entrenamiento para corredores.
-- ================================================================


-- --------------------------------------
-- 2.1 ESQUEMA DE OBJETIVOS DE CORREDORES
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `goals`;


-- Tabla para tipos de objetivos
CREATE TABLE IF NOT EXISTS `goals`.`GoalTypes` (
  `GoalTypeId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Name` VARCHAR(50) NOT NULL COMMENT 'Race, Pace, General',
  `Description` VARCHAR(255) COMMENT 'Descripción del tipo de objetivo'
) ENGINE=InnoDB COMMENT='Tipos de objetivos disponibles';


-- Datos iniciales para tipos de objetivos
INSERT INTO `goals`.`GoalTypes` (Name, Description) VALUES
('Race', 'Participar en una carrera específica'),
('Pace', 'Alcanzar un ritmo determinado en una distancia'),
('General', 'Mantenerse activo sin objetivo específico');


-- Tabla para categorías de carreras
CREATE TABLE IF NOT EXISTS `goals`.`RaceCategories` (
  `RaceCategoryId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Name` VARCHAR(50) NOT NULL COMMENT '5K, 10K, Half Marathon, Marathon, etc.',
  `DistanceKm` DECIMAL(6,2) NOT NULL COMMENT 'Distancia en kilómetros'
) ENGINE=InnoDB COMMENT='Categorías de carreras comunes';


-- Datos iniciales para categorías de carreras
INSERT INTO `goals`.`RaceCategories` (Name, DistanceKm) VALUES
('5K', 5.00),
('10K', 10.00),
('Half Marathon', 21.10),
('Marathon', 42.20),
('Ultra Marathon', 50.00);


-- Tabla principal de objetivos del usuario
CREATE TABLE IF NOT EXISTS `goals`.`UserGoals` (
  `GoalId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `GoalTypeId` INT NOT NULL,
  `Title` VARCHAR(100) NOT NULL COMMENT 'Título descriptivo del objetivo',
  `Description` TEXT COMMENT 'Descripción detallada',
  `StartDate` DATE NOT NULL COMMENT 'Fecha de inicio',
  `TargetDate` DATE NOT NULL COMMENT 'Fecha objetivo',
  `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `LastEvaluatedAt` DATETIME COMMENT 'Última evaluación de viabilidad',
  `CompletedAt` DATETIME COMMENT 'Fecha de completado',
  `TrainingPlanId` INT COMMENT 'Plan asociado a este objetivo',
  INDEX `IX_UserGoals_UserId` (`UserId`),
  INDEX `IX_UserGoals_GoalTypeId` (`GoalTypeId`),
  INDEX `IX_UserGoals_TrainingPlanId` (`TrainingPlanId`),
  CONSTRAINT `FK_UserGoals_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE,
  CONSTRAINT `FK_UserGoals_GoalTypes` FOREIGN KEY (`GoalTypeId`) 
    REFERENCES `goals`.`GoalTypes` (`GoalTypeId`),
  CONSTRAINT `FK_UserGoals_TrainingPlans` FOREIGN KEY (`TrainingPlanId`) 
    REFERENCES `training`.`TrainingPlans` (`TrainingPlanId`)
) ENGINE=InnoDB COMMENT='Objetivos de entrenamiento de usuarios';


-- Detalles específicos para objetivos de tipo carrera
CREATE TABLE IF NOT EXISTS `goals`.`RaceGoals` (
  `GoalId` INT NOT NULL PRIMARY KEY,
  `RaceCategoryId` INT NOT NULL,
  `RaceName` VARCHAR(100) COMMENT 'Nombre del evento si existe',
  `RaceDate` DATE COMMENT 'Fecha de la carrera',
  `TargetCompletion` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Si solo busca completar',
  `TargetTime` TIME COMMENT 'Tiempo objetivo si aplica',
  CONSTRAINT `FK_RaceGoals_UserGoals` FOREIGN KEY (`GoalId`) 
    REFERENCES `goals`.`UserGoals` (`GoalId`) ON DELETE CASCADE,
  CONSTRAINT `FK_RaceGoals_RaceCategories` FOREIGN KEY (`RaceCategoryId`) 
    REFERENCES `goals`.`RaceCategories` (`RaceCategoryId`)
) ENGINE=InnoDB COMMENT='Detalles específicos para objetivos de carrera';


-- Detalles específicos para objetivos de tipo ritmo
CREATE TABLE IF NOT EXISTS `goals`.`PaceGoals` (
  `GoalId` INT NOT NULL PRIMARY KEY,
  `DistanceKm` DECIMAL(6,2) NOT NULL COMMENT 'Distancia objetivo',
  `TargetPaceMinKm` TIME NOT NULL COMMENT 'Ritmo objetivo (min/km)',
  CONSTRAINT `FK_PaceGoals_UserGoals` FOREIGN KEY (`GoalId`) 
    REFERENCES `goals`.`UserGoals` (`GoalId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Detalles específicos para objetivos de ritmo';


-- Historial de evaluaciones de viabilidad
CREATE TABLE IF NOT EXISTS `goals`.`GoalFeasibilityHistory` (
  `EvaluationId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `GoalId` INT NOT NULL,
  `EvaluationDate` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `IsFeasible` TINYINT(1) NOT NULL COMMENT 'Si es viable según IA',
  `ConfidenceScore` DECIMAL(5,2) COMMENT 'Puntuación de confianza (0-100)',
  `AnalysisDetails` JSON COMMENT 'Detalles del análisis',
  `Recommendations` TEXT COMMENT 'Recomendaciones alternativas',
  INDEX `IX_GoalFeasibilityHistory_GoalId` (`GoalId`),
  CONSTRAINT `FK_GoalFeasibilityHistory_UserGoals` FOREIGN KEY (`GoalId`) 
    REFERENCES `goals`.`UserGoals` (`GoalId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Historial de evaluaciones de viabilidad de objetivos';


-- --------------------------------------
-- 2.2 ESQUEMA DE DATOS DE RENDIMIENTO
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `performance`;


-- Tabla para almacenar datos de sesiones de entrenamiento
CREATE TABLE IF NOT EXISTS `performance`.`TrainingData` (
  `DataId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `TrainingSessionId` INT NOT NULL,
  `UserId` INT NOT NULL,
  `CompletionPercentage` DECIMAL(5,2) NOT NULL DEFAULT 100.00 COMMENT 'Porcentaje completado',
  `Duration` TIME COMMENT 'Duración total',
  `DistanceKm` DECIMAL(8,3) COMMENT 'Distancia en kilómetros',
  `AvgPace` TIME COMMENT 'Ritmo promedio (min/km)',
  `AvgHeartRate` INT COMMENT 'Frecuencia cardíaca promedio',
  `MaxHeartRate` INT COMMENT 'Frecuencia cardíaca máxima',
  `AvgCadence` INT COMMENT 'Cadencia promedio (pasos/min)',
  `ElevationGain` DECIMAL(8,2) COMMENT 'Ganancia de elevación (metros)',
  `PerceivedEffort` TINYINT COMMENT 'Esfuerzo percibido (1-10)',
  `PerceivedDifficulty` TINYINT COMMENT 'Dificultad percibida (1-5)',
  `Notes` TEXT COMMENT 'Notas del usuario',
  `WeatherConditions` VARCHAR(100) COMMENT 'Condiciones climáticas',
  `RecordedAt` DATETIME NOT NULL COMMENT 'Fecha y hora de grabación',
  `DataSource` VARCHAR(50) COMMENT 'Fuente de los datos (app, dispositivo)',
  INDEX `IX_TrainingData_TrainingSessionId` (`TrainingSessionId`),
  INDEX `IX_TrainingData_UserId_RecordedAt` (`UserId`, `RecordedAt`),
  CONSTRAINT `FK_TrainingData_TrainingSessions` FOREIGN KEY (`TrainingSessionId`) 
    REFERENCES `training`.`TrainingSessions` (`TrainingSessionId`) ON DELETE CASCADE,
  CONSTRAINT `FK_TrainingData_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`)
) ENGINE=InnoDB COMMENT='Datos de métricas de sesiones de entrenamiento';


-- Tabla para segmentos detallados (por km o intervalo)
CREATE TABLE IF NOT EXISTS `performance`.`TrainingSegments` (
  `SegmentId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `DataId` INT NOT NULL,
  `SegmentNumber` INT NOT NULL COMMENT 'Número de segmento/intervalo',
  `SegmentType` VARCHAR(20) NOT NULL COMMENT 'km, interval, lap',
  `Duration` TIME COMMENT 'Duración del segmento',
  `DistanceKm` DECIMAL(8,3) COMMENT 'Distancia en kilómetros',
  `Pace` TIME COMMENT 'Ritmo en el segmento',
  `HeartRate` INT COMMENT 'FC promedio en segmento',
  `Cadence` INT COMMENT 'Cadencia promedio en segmento',
  `ElevationChange` DECIMAL(8,2) COMMENT 'Cambio de elevación en segmento',
  INDEX `IX_TrainingSegments_DataId` (`DataId`),
  CONSTRAINT `FK_TrainingSegments_TrainingData` FOREIGN KEY (`DataId`) 
    REFERENCES `performance`.`TrainingData` (`DataId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Segmentos detallados de entrenamiento';


-- Tabla para GPS de recorridos
CREATE TABLE IF NOT EXISTS `performance`.`RouteData` (
  `RouteId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `DataId` INT NOT NULL,
  `RouteName` VARCHAR(100) COMMENT 'Nombre de la ruta si existe',
  `RoutePoints` JSON NOT NULL COMMENT 'Puntos GPS en formato GeoJSON',
  `TotalDistanceKm` DECIMAL(8,3) NOT NULL COMMENT 'Distancia total',
  `StartPoint` POINT NOT NULL COMMENT 'Punto de inicio',
  `EndPoint` POINT COMMENT 'Punto final',
  INDEX `IX_RouteData_DataId` (`DataId`),
  SPATIAL INDEX `IX_RouteData_StartPoint` (`StartPoint`),
  CONSTRAINT `FK_RouteData_TrainingData` FOREIGN KEY (`DataId`)
    REFERENCES `performance`.`TrainingData` (`DataId`) ON DELETE CASCADE
) 
ENGINE=InnoDB
COMMENT='Datos de rutas GPS';


-- Historial de progreso de usuario
CREATE TABLE IF NOT EXISTS `performance`.`UserProgressMetrics` (
  `ProgressId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `MetricDate` DATE NOT NULL,
  `MetricType` VARCHAR(50) NOT NULL COMMENT 'weekly_distance, best_5k, vo2max, etc.',
  `MetricValue` DECIMAL(10,4) NOT NULL COMMENT 'Valor numérico de la métrica',
  `ComparisonPercentage` DECIMAL(6,2) COMMENT 'Cambio porcentual respecto anterior',
  INDEX `IX_UserProgressMetrics_UserId_MetricType_MetricDate` (`UserId`, `MetricType`, `MetricDate`),
  CONSTRAINT `FK_UserProgressMetrics_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Historial de métricas de progreso de usuario';


-- --------------------------------------
-- 2.3 ESQUEMA DE GAMIFICACIÓN
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `gamification`;


-- Tabla de categorías de logros
CREATE TABLE IF NOT EXISTS `gamification`.`AchievementCategories` (
  `CategoryId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Name` VARCHAR(50) NOT NULL COMMENT 'Consistencia, Distancia, Velocidad, etc.',
  `Description` VARCHAR(255) COMMENT 'Descripción de la categoría',
  `IconUrl` VARCHAR(255) COMMENT 'URL del ícono'
) ENGINE=InnoDB COMMENT='Categorías para organizar logros';


-- Datos iniciales para categorías
INSERT INTO `gamification`.`AchievementCategories` (Name, Description) VALUES
('Consistency', 'Logros relacionados con constancia en entrenamientos'),
('Distance', 'Logros relacionados con distancias recorridas'),
('Speed', 'Logros relacionados con velocidad y ritmo'),
('Endurance', 'Logros relacionados con resistencia'),
('Special', 'Logros especiales y eventos');


-- Tabla de logros/medallas disponibles
CREATE TABLE IF NOT EXISTS `gamification`.`Achievements` (
  `AchievementId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `CategoryId` INT NOT NULL,
  `Name` VARCHAR(100) NOT NULL,
  `Description` TEXT NOT NULL,
  `PointsValue` INT NOT NULL DEFAULT 10 COMMENT 'Puntos otorgados',
  `Condition` JSON NOT NULL COMMENT 'Condición para desbloquear en formato JSON',
  `IconUrl` VARCHAR(255) COMMENT 'URL del ícono',
  `BadgeUrl` VARCHAR(255) COMMENT 'URL de la insignia',
  `Tier` TINYINT NOT NULL DEFAULT 1 COMMENT 'Nivel (1-3 bronce/plata/oro)',
  `IsHidden` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si es un logro oculto',
  `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
  INDEX `IX_Achievements_CategoryId` (`CategoryId`),
  CONSTRAINT `FK_Achievements_Categories` FOREIGN KEY (`CategoryId`) 
    REFERENCES `gamification`.`AchievementCategories` (`CategoryId`)
) ENGINE=InnoDB COMMENT='Logros disponibles para desbloquear';


-- Tabla de logros desbloqueados por usuarios
CREATE TABLE IF NOT EXISTS `gamification`.`UserAchievements` (
  `UserAchievementId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `AchievementId` INT NOT NULL,
  `UnlockedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `RelatedActivityId` INT COMMENT 'ID de la actividad relacionada si aplica',
  `SharedToSocial` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si fue compartido',
  UNIQUE INDEX `IX_UserAchievements_UserId_AchievementId` (`UserId`, `AchievementId`),
  INDEX `IX_UserAchievements_AchievementId` (`AchievementId`),
  CONSTRAINT `FK_UserAchievements_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE,
  CONSTRAINT `FK_UserAchievements_Achievements` FOREIGN KEY (`AchievementId`) 
    REFERENCES `gamification`.`Achievements` (`AchievementId`)
) ENGINE=InnoDB COMMENT='Logros desbloqueados por usuarios';


-- Tabla para el sistema de puntos
CREATE TABLE IF NOT EXISTS `gamification`.`UserPoints` (
  `PointsId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `TotalPoints` INT NOT NULL DEFAULT 0,
  `Level` INT NOT NULL DEFAULT 1,
  `PointsToNextLevel` INT NOT NULL DEFAULT 100,
  `LastUpdated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE INDEX `IX_UserPoints_UserId` (`UserId`),
  CONSTRAINT `FK_UserPoints_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Sistema de puntos y niveles de usuarios';


-- Historial de puntos ganados
CREATE TABLE IF NOT EXISTS `gamification`.`PointsHistory` (
  `HistoryId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `Points` INT NOT NULL COMMENT 'Puntos ganados/perdidos',
  `Reason` VARCHAR(100) NOT NULL COMMENT 'Razón de puntos',
  `RelatedEntityType` VARCHAR(50) COMMENT 'Tipo de entidad relacionada',
  `RelatedEntityId` INT COMMENT 'ID de entidad relacionada',
  `EarnedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `IX_PointsHistory_UserId` (`UserId`),
  INDEX `IX_PointsHistory_EarnedAt` (`EarnedAt`),
  CONSTRAINT `FK_PointsHistory_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Historial de puntos ganados/perdidos';


-- Tabla para retos (diarios, semanales, mensuales)
CREATE TABLE IF NOT EXISTS `gamification`.`Challenges` (
  `ChallengeId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Title` VARCHAR(100) NOT NULL,
  `Description` TEXT NOT NULL,
  `Type` VARCHAR(20) NOT NULL COMMENT 'daily, weekly, monthly, special',
  `Difficulty` TINYINT NOT NULL DEFAULT 1 COMMENT '1-5 dificultad',
  `PointsReward` INT NOT NULL DEFAULT 10,
  `StartDate` DATETIME NOT NULL,
  `EndDate` DATETIME NOT NULL,
  `Condition` JSON NOT NULL COMMENT 'Condición para completar en JSON',
  `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
  `IsGlobal` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Para todos o personalizado',
  `MaxParticipants` INT COMMENT 'Límite de participantes si aplica',
  `CreatedBy` INT COMMENT 'Usuario creador (sistema=NULL)',
  INDEX `IX_Challenges_Type_StartDate_EndDate` (`Type`, `StartDate`, `EndDate`),
  INDEX `IX_Challenges_IsActive` (`IsActive`)
) ENGINE=InnoDB COMMENT='Retos para usuarios';


-- Tabla para retos de usuario
CREATE TABLE IF NOT EXISTS `gamification`.`UserChallenges` (
  `UserChallengeId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `ChallengeId` INT NOT NULL,
  `JoinedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Status` VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT 'active, completed, failed',
  `CompletedAt` DATETIME COMMENT 'Fecha de finalización',
  `Progress` DECIMAL(5,2) DEFAULT 0.00 COMMENT 'Porcentaje completado',
  `RewardClaimed` TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE INDEX `IX_UserChallenges_UserId_ChallengeId` (`UserId`, `ChallengeId`),
  INDEX `IX_UserChallenges_ChallengeId` (`ChallengeId`),
  CONSTRAINT `FK_UserChallenges_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE,
  CONSTRAINT `FK_UserChallenges_Challenges` FOREIGN KEY (`ChallengeId`) 
    REFERENCES `gamification`.`Challenges` (`ChallengeId`)
) ENGINE=InnoDB COMMENT='Participación de usuarios en retos';


-- --------------------------------------
-- 2.4 ESQUEMA PARA COMUNIDAD SOCIAL
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `social`;


-- Tabla para equipos/grupos de usuarios
CREATE TABLE IF NOT EXISTS `social`.`Teams` (
  `TeamId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Name` VARCHAR(100) NOT NULL,
  `Description` TEXT,
  `CreatedBy` INT NOT NULL,
  `CreatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `IsPrivate` TINYINT(1) NOT NULL DEFAULT 0,
  `JoinCode` VARCHAR(20) COMMENT 'Código para unirse si es privado',
  `MemberCount` INT NOT NULL DEFAULT 1 COMMENT 'Contador de miembros',
  `AvatarUrl` VARCHAR(255) COMMENT 'URL de avatar de equipo',
  `Status` VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT 'active, inactive',
  INDEX `IX_Teams_CreatedBy` (`CreatedBy`),
  CONSTRAINT `FK_Teams_Users` FOREIGN KEY (`CreatedBy`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Equipos y grupos para funciones sociales';


-- Tabla para miembros de equipos
CREATE TABLE IF NOT EXISTS `social`.`TeamMembers` (
  `TeamId` INT NOT NULL,
  `UserId` INT NOT NULL,
  `Role` VARCHAR(20) NOT NULL DEFAULT 'member' COMMENT 'owner, admin, member',
  `JoinedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Status` VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT 'active, inactive, pending',
  PRIMARY KEY (`TeamId`, `UserId`),
  INDEX `IX_TeamMembers_UserId` (`UserId`),
  CONSTRAINT `FK_TeamMembers_Teams` FOREIGN KEY (`TeamId`) 
    REFERENCES `social`.`Teams` (`TeamId`) ON DELETE CASCADE,
  CONSTRAINT `FK_TeamMembers_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Miembros de equipos';


-- Tabla para actividades sociales (compartir logros, etc)
CREATE TABLE IF NOT EXISTS `social`.`SocialActivities` (
  `ActivityId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `ActivityType` VARCHAR(50) NOT NULL COMMENT 'achievement, training, race, challenge',
  `Title` VARCHAR(100) NOT NULL,
  `Description` TEXT,
  `ContentJson` JSON COMMENT 'Contenido detallado en JSON',
  `RelatedEntityType` VARCHAR(50) COMMENT 'Tipo de entidad relacionada',
  `RelatedEntityId` INT COMMENT 'ID de entidad relacionada',
  `IsPublic` TINYINT(1) NOT NULL DEFAULT 1,
  `AllowComments` TINYINT(1) NOT NULL DEFAULT 1,
  `LikesCount` INT NOT NULL DEFAULT 0,
  `CommentsCount` INT NOT NULL DEFAULT 0,
  `SharedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `IX_SocialActivities_UserId` (`UserId`),
  INDEX `IX_SocialActivities_ActivityType` (`ActivityType`),
  INDEX `IX_SocialActivities_SharedAt` (`SharedAt`),
  CONSTRAINT `FK_SocialActivities_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Actividades compartidas en funcionalidad social';


-- Tabla para comentarios en actividades sociales
CREATE TABLE IF NOT EXISTS `social`.`Comments` (
  `CommentId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `ActivityId` INT NOT NULL,
  `UserId` INT NOT NULL,
  `Content` TEXT NOT NULL,
  `PostedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ParentCommentId` INT COMMENT 'Para respuestas a comentarios',
  `LikesCount` INT NOT NULL DEFAULT 0,
  INDEX `IX_Comments_ActivityId` (`ActivityId`),
  INDEX `IX_Comments_UserId` (`UserId`),
  INDEX `IX_Comments_ParentCommentId` (`ParentCommentId`),
  CONSTRAINT `FK_Comments_Activities` FOREIGN KEY (`ActivityId`) 
    REFERENCES `social`.`SocialActivities` (`ActivityId`) ON DELETE CASCADE,
  CONSTRAINT `FK_Comments_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE,
  CONSTRAINT `FK_Comments_ParentComments` FOREIGN KEY (`ParentCommentId`) 
    REFERENCES `social`.`Comments` (`CommentId`) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Comentarios en actividades sociales';


-- Tabla para likes en actividades y comentarios
CREATE TABLE IF NOT EXISTS `social`.`Likes` (
  `LikeId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `EntityType` VARCHAR(20) NOT NULL COMMENT 'activity, comment',
  `EntityId` INT NOT NULL COMMENT 'ActivityId o CommentId',
  `LikedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE INDEX `IX_Likes_UserId_EntityType_EntityId` (`UserId`, `EntityType`, `EntityId`),
  INDEX `IX_Likes_EntityType_EntityId` (`EntityType`, `EntityId`),
  CONSTRAINT `FK_Likes_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Likes en contenido social';


-- --------------------------------------
-- 2.5 ESQUEMA DE CONTENIDO EDUCATIVO
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `education`;


-- Tabla para categorías de contenido educativo
CREATE TABLE IF NOT EXISTS `education`.`ContentCategories` (
  `CategoryId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Name` VARCHAR(100) NOT NULL,
  `Description` TEXT,
  `IconUrl` VARCHAR(255)
) ENGINE=InnoDB COMMENT='Categorías de contenido educativo';


-- Datos iniciales para categorías
INSERT INTO `education`.`ContentCategories` (Name, Description) VALUES
('Running Technique', 'Consejos sobre técnica de carrera'),
('Recovery', 'Estrategias de recuperación y descanso'),
('Nutrition', 'Información sobre nutrición para corredores'),
('Hydration', 'Consejos de hidratación'),
('Injury Prevention', 'Prevención de lesiones'),
('Race Strategy', 'Estrategias para carreras');


-- Tabla para contenido educativo
CREATE TABLE IF NOT EXISTS `education`.`EducationalContent` (
  `ContentId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `CategoryId` INT NOT NULL,
  `Title` VARCHAR(100) NOT NULL,
  `Summary` VARCHAR(255) NOT NULL,
  `Content` TEXT NOT NULL,
  `ContentType` VARCHAR(20) NOT NULL COMMENT 'article, video, interactive',
  `MediaUrl` VARCHAR(255) COMMENT 'URL a media si aplica',
  `DurationMinutes` INT COMMENT 'Duración en minutos si aplica',
  `RequiredLevel` TINYINT NOT NULL DEFAULT 1 COMMENT 'Nivel usuario requerido 1-5',
  `SubscriptionLevel` VARCHAR(20) NOT NULL DEFAULT 'free' COMMENT 'free, intermediate, premium',
  `PublishedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
  INDEX `IX_EducationalContent_CategoryId` (`CategoryId`),
  INDEX `IX_EducationalContent_ContentType_SubscriptionLevel` (`ContentType`, `SubscriptionLevel`),
  CONSTRAINT `FK_EducationalContent_Categories` FOREIGN KEY (`CategoryId`) 
    REFERENCES `education`.`ContentCategories` (`CategoryId`)
) ENGINE=InnoDB COMMENT='Contenido educativo sobre carrera y entrenamiento';


-- Tabla para seguimiento de contenido visto por usuarios
CREATE TABLE IF NOT EXISTS `education`.`UserContentProgress` (
  `ProgressId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `ContentId` INT NOT NULL,
  `StartedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `CompletedAt` DATETIME COMMENT 'Fecha de finalización',
  `ProgressPercentage` DECIMAL(5,2) NOT NULL DEFAULT 0 COMMENT 'Porcentaje completado',
  `LastPosition` VARCHAR(20) COMMENT 'Última posición (tiempo/página)',
  UNIQUE INDEX `IX_UserContentProgress_UserId_ContentId` (`UserId`, `ContentId`),
  INDEX `IX_UserContentProgress_ContentId` (`ContentId`),
  CONSTRAINT `FK_UserContentProgress_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE,
  CONSTRAINT `FK_UserContentProgress_EducationalContent` FOREIGN KEY (`ContentId`) 
    REFERENCES `education`.`EducationalContent` (`ContentId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Progreso de usuario en contenido educativo';


-- Tabla para recomendaciones personalizadas
CREATE TABLE IF NOT EXISTS `education`.`ContentRecommendations` (
  `RecommendationId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `ContentId` INT NOT NULL,
  `RecommendationReason` VARCHAR(255) NOT NULL,
  `RecommendedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Priority` TINYINT NOT NULL DEFAULT 3 COMMENT 'Prioridad 1-5',
  `Viewed` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si se vio la recomendación',
  `ClickedAt` DATETIME COMMENT 'Cuándo se hizo clic',
  INDEX `IX_ContentRecommendations_UserId` (`UserId`),
  INDEX `IX_ContentRecommendations_ContentId` (`ContentId`),
  CONSTRAINT `FK_ContentRecommendations_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE,
  CONSTRAINT `FK_ContentRecommendations_EducationalContent` FOREIGN KEY (`ContentId`) 
    REFERENCES `education`.`EducationalContent` (`ContentId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Recomendaciones de contenido personalizado';


-- --------------------------------------
-- 2.6 ESQUEMA PARA INTEGRACIÓN CON DISPOSITIVOS
-- --------------------------------------
CREATE SCHEMA IF NOT EXISTS `devices`;


-- Tabla para tipos de dispositivos soportados
CREATE TABLE IF NOT EXISTS `devices`.`DeviceTypes` (
  `DeviceTypeId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `Brand` VARCHAR(50) NOT NULL COMMENT 'Garmin, Apple, Fitbit, etc.',
  `Model` VARCHAR(100) NOT NULL,
  `DeviceCategory` VARCHAR(50) NOT NULL COMMENT 'watch, band, phone, sensor',
  `SupportLevel` VARCHAR(20) NOT NULL COMMENT 'full, partial, basic',
  `SupportedMetrics` JSON NOT NULL COMMENT 'Métricas soportadas en JSON'
) ENGINE=InnoDB COMMENT='Catálogo de tipos de dispositivos soportados';


-- Dispositivos conectados de usuarios
CREATE TABLE IF NOT EXISTS `devices`.`UserDevices` (
  `UserDeviceId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `DeviceTypeId` INT NOT NULL,
  `DeviceIdentifier` VARCHAR(100) NOT NULL COMMENT 'ID único del dispositivo',
  `FriendlyName` VARCHAR(100) COMMENT 'Nombre amigable',
  `ConnectionStatus` VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT 'active, inactive, paired',
  `LastSyncAt` DATETIME COMMENT 'Última sincronización',
  `ConnectedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `AuthToken` VARCHAR(255) COMMENT 'Token de autenticación si aplica',
  `SyncSettings` JSON COMMENT 'Configuración de sincronización',
  UNIQUE INDEX `IX_UserDevices_UserId_DeviceIdentifier` (`UserId`, `DeviceIdentifier`),
  INDEX `IX_UserDevices_DeviceTypeId` (`DeviceTypeId`),
  CONSTRAINT `FK_UserDevices_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE,
  CONSTRAINT `FK_UserDevices_DeviceTypes` FOREIGN KEY (`DeviceTypeId`) 
    REFERENCES `devices`.`DeviceTypes` (`DeviceTypeId`)
) ENGINE=InnoDB COMMENT='Dispositivos conectados por usuarios';


-- Historial de sincronización
CREATE TABLE IF NOT EXISTS `devices`.`SyncHistory` (
  `SyncId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserDeviceId` INT NOT NULL,
  `SyncStartTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `SyncEndTime` DATETIME COMMENT 'Tiempo de finalización',
  `SyncStatus` VARCHAR(20) NOT NULL DEFAULT 'in_progress' COMMENT 'success, error, in_progress',
  `DataSummary` JSON COMMENT 'Resumen de datos sincronizados',
  `ErrorDetails` TEXT COMMENT 'Detalles de error si aplica',
  INDEX `IX_SyncHistory_UserDeviceId` (`UserDeviceId`),
  CONSTRAINT `FK_SyncHistory_UserDevices` FOREIGN KEY (`UserDeviceId`) 
    REFERENCES `devices`.`UserDevices` (`UserDeviceId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Historial de sincronizaciones de dispositivos';


-- Integraciones con APIs externas
CREATE TABLE IF NOT EXISTS `devices`.`ExternalIntegrations` (
  `IntegrationId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `UserId` INT NOT NULL,
  `Provider` VARCHAR(50) NOT NULL COMMENT 'strava, garmin, apple_health, etc.',
  `AccessToken` VARCHAR(255) COMMENT 'Token de acceso',
  `RefreshToken` VARCHAR(255) COMMENT 'Token de actualización',
  `TokenExpiry` DATETIME COMMENT 'Expiración del token',
  `ConnectionStatus` VARCHAR(20) NOT NULL DEFAULT 'active',
  `IntegrationSettings` JSON COMMENT 'Configuración específica',
  `ProviderUserId` VARCHAR(100) COMMENT 'ID del usuario en el sistema del proveedor',
  `ConnectedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE INDEX `IX_ExternalIntegrations_UserId_Provider` (`UserId`, `Provider`),
  CONSTRAINT `FK_ExternalIntegrations_Users` FOREIGN KEY (`UserId`) 
    REFERENCES `users`.`Users` (`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Integraciones con servicios externos como Strava, Garmin, etc.';


-- --------------------------------------
-- 2.7 ACTUALIZAR RELACIONES ENTRE PLANES Y OBJETIVOS
-- --------------------------------------


-- Añadir relación con objetivo en planes de entrenamiento
ALTER TABLE `training`.`TrainingPlans` 
ADD COLUMN `GoalId` INT COMMENT 'Objetivo asociado a este plan',
ADD CONSTRAINT `FK_TrainingPlans_UserGoals` 
FOREIGN KEY (`GoalId`) REFERENCES `goals`.`UserGoals` (`GoalId`);


-- ================================================================
-- PARTE 3: SISTEMA DE NIVELES DE DIFICULTAD
-- ================================================================
-- Esta parte implementa un sistema de niveles de dificultad para
-- adaptar los entrenamientos según la capacidad de cada corredor.
-- ================================================================


-- --------------------------------------
-- 3.1 CATÁLOGOS DE DIFICULTAD
-- --------------------------------------


-- Tabla para definir niveles de dificultad
CREATE TABLE IF NOT EXISTS `training`.`DifficultyLevels` (
  `DifficultyId` TINYINT NOT NULL PRIMARY KEY,
  `Name` VARCHAR(50) NOT NULL COMMENT 'Nombre del nivel: Beginner, Intermediate, etc.',
  `Description` TEXT NOT NULL COMMENT 'Descripción detallada del nivel',
  `MinimumExperience` INT COMMENT 'Experiencia mínima recomendada (días)',
  `RecommendedWeeklyVolume` VARCHAR(20) COMMENT 'Volumen semanal recomendado (rango)',
  `RecommendedIntensity` VARCHAR(100) COMMENT 'Descripción de intensidad recomendada',
  `RecoveryGuidelines` TEXT COMMENT 'Guías de recuperación para este nivel',
  `IconUrl` VARCHAR(255) COMMENT 'URL del ícono representativo'
) ENGINE=InnoDB COMMENT='Niveles de dificultad para entrenamientos';


-- Datos iniciales para niveles de dificultad
INSERT INTO `training`.`DifficultyLevels` 
(DifficultyId, Name, Description, MinimumExperience, RecommendedWeeklyVolume, RecommendedIntensity, RecoveryGuidelines) 
VALUES
(1, 'Principiante', 
   'Para corredores nuevos con poca o ninguna experiencia. Enfocado en construir hábito y resistencia base con entrenamientos suaves y progresión gradual.', 
   0, '10-15 km', 
   'Principalmente zonas 1-2 (60-70% FCM), con introducción gradual a esfuerzos ligeramente más intensos',
   'Mínimo 1 día de descanso entre sesiones de carrera. 3-4 días de entrenamiento por semana máximo.'),
   
(2, 'Principiante avanzado', 
   'Para corredores con al menos 3-6 meses de experiencia consistente. Incremento gradual de volumen y primeras introducciones a entrenamientos estructurados.', 
   90, '15-25 km', 
   'Principalmente zonas 1-3 (60-80% FCM), con intervalos cortos en zona 4 ocasionalmente',
   'Al menos 1 día de descanso completo. Alternar días duros y fáciles.'),
   
(3, 'Intermedio', 
   'Para corredores regulares con 6-18 meses de experiencia. Incorpora variedad de entrenamientos y mayor estructura con objetivos específicos.', 
   180, '25-40 km', 
   'Distribución balanceada en zonas 1-4, con toques ocasionales de zona 5 en intervalos',
   'Al menos 1 día de descanso completo. Semanas de carga seguidas de semanas de recuperación.'),
   
(4, 'Intermedio avanzado', 
   'Para corredores experimentados con 18+ meses de entrenamiento consistente. Incorpora periodización y entrenamientos más específicos según objetivos.', 
   540, '40-60 km', 
   'Distribución polarizada con mayoría en zonas 1-2 y sesiones clave en zonas 4-5',
   'Recuperación activa entre sesiones duras. Ciclos de carga de 3 semanas seguidos de 1 de recuperación.'),
   
(5, 'Avanzado', 
   'Para corredores muy experimentados con 2+ años de entrenamiento consistente. Planes altamente estructurados y específicos para rendir al máximo nivel.', 
   730, '60+ km', 
   'Distribución polarizada optimizada. Sesiones muy específicas según evento objetivo.',
   'Recuperación optimizada con monitoreo de fatiga. Alternancia estratégica de cargas altas/bajas.');


-- Tabla para tipos de intensidad de entrenamiento
CREATE TABLE IF NOT EXISTS `training`.`IntensityTypes` (
  `IntensityTypeId` TINYINT NOT NULL PRIMARY KEY,
  `Name` VARCHAR(50) NOT NULL COMMENT 'Nombre del tipo: Easy, Tempo, Interval, etc.',
  `Description` TEXT NOT NULL COMMENT 'Descripción detallada',
  `HeartRateZone` VARCHAR(20) COMMENT 'Zonas de frecuencia cardíaca (rango)',
  `PercentOfVO2Max` VARCHAR(20) COMMENT 'Porcentaje de VO2Max (rango)',
  `PerceivedEffort` VARCHAR(20) COMMENT 'Esfuerzo percibido (rango 1-10)',
  `PurposeAndBenefits` TEXT COMMENT 'Propósito y beneficios de este tipo',
  `ColorCode` CHAR(7) COMMENT 'Código de color para UI (HEX)'
) ENGINE=InnoDB COMMENT='Tipos de intensidad para entrenamientos';


-- Datos iniciales para tipos de intensidad
INSERT INTO `training`.`IntensityTypes` 
(IntensityTypeId, Name, Description, HeartRateZone, PercentOfVO2Max, PerceivedEffort, PurposeAndBenefits, ColorCode) 
VALUES
(1, 'Recuperación', 
   'Carrera muy suave diseñada para promover recuperación activa sin añadir fatiga significativa.', 
   'Zona 1 (60-65% FCM)', '40-50%', '2-3/10', 
   'Mejora circulación sanguínea, elimina productos de desecho, promueve recuperación sin añadir estrés.',
   '#92d050'),
   
(2, 'Fácil', 
   'Carrera aeróbica de baja intensidad que construye resistencia sin acumular fatiga excesiva.', 
   'Zona 2 (65-75% FCM)', '50-60%', '3-4/10', 
   'Desarrolla sistema aeróbico, mejora economía de carrera, construye volumen de entrenamiento sostenible.',
   '#00b050'),
   
(3, 'Moderado', 
   'Carrera de intensidad media, sostenible pero requiere más concentración que ritmo fácil.', 
   'Zona 3 (75-80% FCM)', '60-70%', '5-6/10', 
   'Mejora capacidad aeróbica, prepara para entrenamientos más intensos, desarrolla resistencia cardiovascular.',
   '#ffc000'),
   
(4, 'Umbral', 
   'Carrera a ritmo cercano al umbral anaeróbico, sostenible entre 20-40 minutos.', 
   'Zona 4 (80-90% FCM)', '70-85%', '6-7/10', 
   'Mejora umbral anaeróbico, aumenta velocidad sostenible, prepara para ritmo de competición.',
   '#ed7d31'),
   
(5, 'Intervalo', 
   'Repeticiones de alta intensidad con periodos de recuperación, cercanas a ritmo de VO2Max.', 
   'Zona 5 (90-100% FCM)', '85-100%', '8-9/10', 
   'Mejora potencia aeróbica, consumo máximo de oxígeno, economía a ritmos rápidos.',
   '#ff0000'),
   
(6, 'Repetición', 
   'Repeticiones muy cortas a máxima o casi máxima intensidad con recuperación completa.', 
   '>100% FCM', '100-120%', '9-10/10', 
   'Mejora velocidad máxima, potencia anaeróbica, reclutamiento muscular, economía a ritmos de sprint.',
   '#7030a0');


-- ================================================================
-- PARTE 4: PROCEDIMIENTOS ALMACENADOS Y FUNCIONES
-- ================================================================
-- Esta parte implementa los procedimientos almacenados y funciones
-- necesarios para el funcionamiento de la aplicación.
-- ================================================================


DELIMITER //


-- --------------------------------------
-- 4.1 PROCEDIMIENTOS PARA EVALUACIÓN DE OBJETIVOS
-- --------------------------------------


-- Procedimiento para evaluar viabilidad de objetivos
CREATE PROCEDURE `goals`.`EvaluateGoalFeasibility`(
    IN p_goal_id INT,
    IN p_confidence_score DECIMAL(5,2),
    IN p_is_feasible TINYINT(1),
    IN p_analysis_details JSON,
    IN p_recommendations TEXT
)
BEGIN
    -- Registrar evaluación de viabilidad
    INSERT INTO `goals`.`GoalFeasibilityHistory` (
        GoalId, 
        EvaluationDate, 
        IsFeasible, 
        ConfidenceScore, 
        AnalysisDetails, 
        Recommendations
    ) VALUES (
        p_goal_id,
        NOW(),
        p_is_feasible,
        p_confidence_score,
        p_analysis_details,
        p_recommendations
    );
    
    -- Actualizar información en la tabla de objetivos
    UPDATE `goals`.`UserGoals` 
    SET 
        LastEvaluatedAt = NOW()
    WHERE 
        GoalId = p_goal_id;
        
    -- Si no es viable, crear un nuevo objetivo alternativo
IF p_is_feasible = 0 AND JSON_EXTRACT(p_analysis_details, '$.createAlternative') = 1 THEN
    -- Extraer información de recomendaciones
    SET @new_goal_type = JSON_EXTRACT(p_analysis_details, '$.alternativeGoalType');
    SET @new_target_date = JSON_EXTRACT(p_analysis_details, '$.alternativeTargetDate');
    
    -- Obtener información del objetivo original
    SELECT UserId, Description INTO @user_id, @description 
    FROM `goals`.`UserGoals` WHERE GoalId = p_goal_id;
    
    -- Crear objetivo alternativo
    INSERT INTO `goals`.`UserGoals` 
        (UserId, GoalTypeId, Title, Description, StartDate, TargetDate, IsActive)
    VALUES 
        (@user_id, @new_goal_type, 
         CONCAT('Alternativa: ', @description), 
         p_recommendations, 
         CURRENT_DATE, 
         @new_target_date, 
         1);
        END IF;
END //


-- --------------------------------------
-- 4.2 PROCEDIMIENTOS PARA ADAPTACIÓN DE PLANES
-- --------------------------------------


-- Procedimiento para adaptar plan de entrenamiento basado en rendimiento
CREATE PROCEDURE `training`.`AdaptTrainingPlan`(
    IN p_training_plan_id INT,
    IN p_adaptation_reason VARCHAR(100),
    IN p_adaptation_details JSON
)
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_current_date DATE;
    
    -- Obtener el usuario asociado al plan
    SELECT UserId INTO v_user_id 
    FROM `training`.`TrainingPlans` 
    WHERE TrainingPlanId = p_training_plan_id;
    
    SET v_current_date = CURDATE();
    
    -- Crear respaldo del plan actual antes de modificarlo
    INSERT INTO `training`.`TrainingPlanHistory` (
        TrainingPlanId,
        PlanVersion,
        AdaptationReason,
        AdaptationDetails,
        AdaptedAt
    ) VALUES (
        p_training_plan_id,
        (SELECT IFNULL(MAX(PlanVersion), 0) + 1 
         FROM `training`.`TrainingPlanHistory` 
         WHERE TrainingPlanId = p_training_plan_id),
        p_adaptation_reason,
        p_adaptation_details,
        NOW()
    );
    
    -- Actualizar el plan principal
    UPDATE `training`.`TrainingPlans`
    SET 
        LastAdaptedAt = NOW(),
        AdaptationCount = IFNULL(AdaptationCount, 0) + 1
    WHERE 
        TrainingPlanId = p_training_plan_id;
    
    -- Registrar el evento de adaptación
    INSERT INTO `users`.`ActivityLogs` (
        UserId,
        Activity,
        Details,
        CreatedAt
    ) VALUES (
        v_user_id,
        'plan_adaptation',
        JSON_OBJECT(
            'training_plan_id', p_training_plan_id,
            'reason', p_adaptation_reason,
            'adaptation_number', (SELECT AdaptationCount FROM `training`.`TrainingPlans` WHERE TrainingPlanId = p_training_plan_id)
        ),
        NOW()
    );
END //


-- Función para calcular la carga de entrenamiento (Training Load)
DELIMITER //


CREATE FUNCTION `training`.`CalculateTrainingLoad`(
    p_user_id INT,
    p_start_date DATE,
    p_end_date DATE
) RETURNS DECIMAL(10,2)
NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_training_load DECIMAL(10,2) DEFAULT 0;
    DECLARE v_data_quality VARCHAR(20) DEFAULT 'basic';
    DECLARE v_session_count INT DEFAULT 0;
    DECLARE v_has_hr_data BOOLEAN DEFAULT FALSE;
    DECLARE v_has_rpe_data BOOLEAN DEFAULT FALSE;
    
    -- 1. Determinar qué tipos de datos tenemos disponibles para este usuario
    SELECT 
        COUNT(*) > 0,
        COUNT(*) > 0
    INTO 
        v_has_hr_data,
        v_has_rpe_data
    FROM 
        `training`.`TrainingSessions` ts
    JOIN 
        `performance`.`TrainingData` td ON ts.TrainingSessionId = td.TrainingSessionId
    WHERE 
        ts.UserId = p_user_id
        AND ts.SessionDate BETWEEN p_start_date AND p_end_date
        AND ts.Completed = 1
        AND (td.AvgHeartRate IS NOT NULL OR td.PerceivedEffort IS NOT NULL);
    
    -- Determinar la calidad de datos disponible
    IF v_has_hr_data THEN
        SET v_data_quality = 'advanced';
    ELSEIF v_has_rpe_data THEN
        SET v_data_quality = 'intermediate';
    ELSE
        SET v_data_quality = 'basic';
    END IF;
    
    -- 2. ENFOQUE BÁSICO (funciona para TODOS los usuarios)
    -- Basado en distancia, duración e intensidad estimada
    SELECT 
        COUNT(*),
        SUM(
            COALESCE(td.DistanceKm, 0) * 
            CASE 
                WHEN ts.IntensityLevel IS NOT NULL THEN
                    CASE 
                        WHEN ts.IntensityLevel = 1 THEN 1.0
                        WHEN ts.IntensityLevel = 2 THEN 1.2
                        WHEN ts.IntensityLevel = 3 THEN 1.5
                        WHEN ts.IntensityLevel = 4 THEN 1.8
                        WHEN ts.IntensityLevel = 5 THEN 2.2
                        ELSE 1.0
                    END
                WHEN ts.SessionType IS NOT NULL THEN
                    CASE 
                        WHEN ts.SessionType = 'recovery' THEN 1.0
                        WHEN ts.SessionType = 'easy' THEN 1.2
                        WHEN ts.SessionType = 'moderate' THEN 1.5
                        WHEN ts.SessionType = 'threshold' THEN 1.8
                        WHEN ts.SessionType = 'interval' THEN 2.0
                        WHEN ts.SessionType = 'repetition' THEN 2.2
                        ELSE 1.0
                    END
                ELSE 1.0
            END *
            -- Factor de duración cuando no hay distancia
            CASE 
                WHEN td.DistanceKm IS NULL AND td.Duration IS NOT NULL THEN
                    GREATEST(TIME_TO_SEC(td.Duration) / 3600, 0.1) * 10
                WHEN td.DistanceKm IS NULL AND td.Duration IS NULL THEN
                    1 -- Valor mínimo si no hay métricas
                ELSE 1
            END
        )
    INTO 
        v_session_count,
        v_training_load
    FROM 
        `training`.`TrainingSessions` ts
    LEFT JOIN 
        `performance`.`TrainingData` td ON ts.TrainingSessionId = td.TrainingSessionId
    WHERE 
        ts.UserId = p_user_id
        AND ts.SessionDate BETWEEN p_start_date AND p_end_date
        AND ts.Completed = 1;
    
    -- 3. MEJORA CON RPE (si está disponible)
    IF v_data_quality IN ('intermediate', 'advanced') THEN
        SELECT 
            SUM(
                COALESCE(td.PerceivedEffort, 5) * -- Valor por defecto medio si falta
                CASE 
                    WHEN td.Duration IS NOT NULL THEN
                        GREATEST(TIME_TO_SEC(td.Duration) / 60, 10) -- Mínimo 10 minutos
                    ELSE
                        COALESCE(td.DistanceKm, 5) * 6 -- Estimación ~6 min/km
                END / 60 -- Convertir a horas para equilibrar escala
            ) INTO @rpe_load
        FROM 
            `training`.`TrainingSessions` ts
        JOIN 
            `performance`.`TrainingData` td ON ts.TrainingSessionId = td.TrainingSessionId
        WHERE 
            ts.UserId = p_user_id
            AND ts.SessionDate BETWEEN p_start_date AND p_end_date
            AND ts.Completed = 1
            AND td.PerceivedEffort IS NOT NULL;
        
        -- Ajustar carga combinando RPE si está disponible
        IF @rpe_load IS NOT NULL AND @rpe_load > 0 THEN
            -- Usar una media ponderada entre métodos
            SET v_training_load = (v_training_load + (@rpe_load * 2)) / 3;
        END IF;
    END IF;
    
    -- 4. MEJORA CON FRECUENCIA CARDÍACA (si está disponible)
    IF v_data_quality = 'advanced' THEN
        -- Obtener la FC máxima del usuario (o estimar por edad)
        SELECT 
            COALESCE(
                JSON_EXTRACT(us.UIPreferences, '$.max_hr'),
                220 - TIMESTAMPDIFF(YEAR, 
                                  JSON_EXTRACT(us.UIPreferences, '$.birth_date'), 
                                  CURDATE())
            ) INTO @max_hr
        FROM 
            `users`.`Users` u
        LEFT JOIN 
            `users`.`UserSettings` us ON u.UserId = us.UserId
        WHERE 
            u.UserId = p_user_id;
        
        -- Valor por defecto si no hay datos
        IF @max_hr IS NULL OR @max_hr <= 0 THEN
            SET @max_hr = 180;
        END IF;
        
        -- Calcular usando Impulso de Entrenamiento simplificado
        SELECT 
            SUM(
                CASE 
                    WHEN td.AvgHeartRate IS NOT NULL AND td.Duration IS NOT NULL THEN
                        TIME_TO_SEC(td.Duration) / 60 * -- Duración en minutos
                        ((td.AvgHeartRate / @max_hr) * 0.9) * -- Intensidad relativa
                        EXP(((td.AvgHeartRate / @max_hr) * 0.9) * 1.92) -- Función exponencial
                    ELSE 0
                END
            ) INTO @hr_load
        FROM 
            `training`.`TrainingSessions` ts
        JOIN 
            `performance`.`TrainingData` td ON ts.TrainingSessionId = td.TrainingSessionId
        WHERE 
            ts.UserId = p_user_id
            AND ts.SessionDate BETWEEN p_start_date AND p_end_date
            AND ts.Completed = 1
            AND td.AvgHeartRate IS NOT NULL;
        
        -- Si tenemos carga basada en FC, la incorporamos a la carga total
        IF @hr_load IS NOT NULL AND @hr_load > 0 THEN
            SET v_training_load = (v_training_load * 0.3) + (@hr_load * 0.7);
        END IF;
    END IF;
    
    -- 5. FACTOR DE EXPERIENCIA DEL CORREDOR
    -- Estimar experiencia basada en historial
    SELECT 
        CASE 
            WHEN COUNT(*) < 10 THEN 0.8   -- Principiante
            WHEN COUNT(*) < 50 THEN 1.0   -- Regular
            WHEN COUNT(*) < 200 THEN 1.1  -- Intermedio
            ELSE 1.2                      -- Avanzado
        END INTO @experience_factor
    FROM 
        `training`.`TrainingSessions` 
    WHERE 
        UserId = p_user_id 
        AND Completed = 1;
    
    -- Ajustar carga según experiencia
    SET v_training_load = v_training_load * @experience_factor;
    
        -- 6. AJUSTE FINAL: Escalar para tener valores en un rango razonable
    IF v_session_count > 0 THEN
        -- Escalar según calidad de datos (corregido)
        IF v_data_quality = 'advanced' THEN
            SET v_training_load = v_training_load * 1.0;
        ELSEIF v_data_quality = 'intermediate' THEN
            SET v_training_load = v_training_load * 1.0;
        ELSE
            SET v_training_load = v_training_load * 1.2; -- Compensar posible subestimación
        END IF;
        
        -- Guardar la última carga calculada para este usuario
        INSERT INTO `users`.`ActivityLogs` (
            UserId, 
            Activity, 
            Details, 
            CreatedAt
        ) VALUES (
            p_user_id,
            'training_load_calculation',
            JSON_OBJECT(
                'load', v_training_load,
                'data_quality', v_data_quality,
                'session_count', v_session_count,
                'start_date', p_start_date,
                'end_date', p_end_date
            ),
            NOW()
        );
    END IF;
    
    RETURN IFNULL(v_training_load, 0);
END //


-- Procedimiento complementario para interpretar la carga de entrenamiento
CREATE PROCEDURE `training`.`GetSimpleTrainingLoadReport`(
    IN p_user_id INT,
    IN p_period_days INT -- Últimos X días
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_end_date = CURRENT_DATE;
    SET v_start_date = DATE_SUB(v_end_date, INTERVAL p_period_days DAY);
    
    -- Calcular la carga para el período
    SET @current_load = `training`.`CalculateAdaptiveTrainingLoad`(p_user_id, v_start_date, v_end_date);
    
    -- Calcular carga del período anterior para comparación
    SET @previous_load = `training`.`CalculateAdaptiveTrainingLoad`(
        p_user_id, 
        DATE_SUB(v_start_date, INTERVAL p_period_days DAY),
        DATE_SUB(v_end_date, INTERVAL p_period_days DAY)
    );
    
    -- Devolver el reporte simplificado
    SELECT
        @current_load AS CurrentLoad,
        @previous_load AS PreviousLoad,
        CASE 
            WHEN @previous_load = 0 THEN 0
            ELSE ((@current_load - @previous_load) / @previous_load) * 100
        END AS ChangePercentage,
        CASE 
            WHEN @current_load < @previous_load * 0.7 THEN 'Reducción significativa de carga - riesgo de pérdida de fitness'
            WHEN @current_load < @previous_load * 0.9 THEN 'Reducción moderada de carga - posible recuperación'
            WHEN @current_load BETWEEN @previous_load * 0.9 AND @previous_load * 1.1 THEN 'Carga estable - mantenimiento'
            WHEN @current_load <= @previous_load * 1.3 THEN 'Incremento moderado - período de construcción'
            ELSE 'Incremento alto - posible riesgo de sobreentrenamiento'
        END AS TrainingStatus,
        -- Recomendaciones basadas en la tendencia
        CASE 
            WHEN @current_load > @previous_load * 1.3 THEN 'Considera reducir la intensidad en los próximos días para prevenir sobrecarga'
            WHEN @current_load < @previous_load * 0.7 THEN 'Incrementa gradualmente tu volumen para mantener tu nivel de fitness'
            WHEN @current_load BETWEEN @previous_load * 0.9 AND @previous_load * 1.1 THEN 'Continúa con tu rutina actual que mantiene un buen equilibrio'
            WHEN @current_load > @previous_load THEN 'Buen progreso, mantén este ritmo de incremento'
            ELSE 'Tu entrenamiento está en fase de recuperación'
        END AS Recommendation,
        -- Obtener la calidad de los datos
        (SELECT 
            JSON_UNQUOTE(JSON_EXTRACT(Details, '$.data_quality'))
         FROM `users`.`ActivityLogs`
         WHERE 
            UserId = p_user_id AND 
            Activity = 'training_load_calculation'
         ORDER BY CreatedAt DESC
         LIMIT 1) AS DataQuality;
END //


DELIMITER ;


-- --------------------------------------
-- 4.3 PROCEDIMIENTOS PARA INTEGRACIÓN DE DISPOSITIVOS
-- --------------------------------------


-- Procedimiento para procesar y almacenar datos de entrenamiento desde dispositivos
CREATE PROCEDURE `devices`.`ProcessDeviceData`(
    IN p_user_id INT,
    IN p_device_id INT,
    IN p_training_session_id INT,
    IN p_raw_data JSON,
    IN p_data_type VARCHAR(50)
)
BEGIN
    DECLARE v_data_id INT;
    DECLARE v_distance DECIMAL(8,3);
    DECLARE v_duration TIME;
    DECLARE v_avg_pace TIME;
    DECLARE v_avg_hr INT;
    DECLARE v_recorded_at DATETIME;
    
    -- Extraer datos principales del JSON
    SET v_distance = JSON_EXTRACT(p_raw_data, '$.distance');
    SET v_duration = JSON_EXTRACT(p_raw_data, '$.duration');
    SET v_avg_pace = JSON_EXTRACT(p_raw_data, '$.avg_pace');
    SET v_avg_hr = JSON_EXTRACT(p_raw_data, '$.avg_heart_rate');
    SET v_recorded_at = JSON_EXTRACT(p_raw_data, '$.timestamp');
    
    -- Si no hay fecha de grabación, usar la actual
    IF v_recorded_at IS NULL THEN
        SET v_recorded_at = NOW();
    END IF;
    
    -- Insertar datos principales
    INSERT INTO `performance`.`TrainingData` (
        TrainingSessionId,
        UserId,
        DistanceKm,
        Duration,
        AvgPace,
        AvgHeartRate,
        MaxHeartRate,
        AvgCadence,
        ElevationGain,
        RecordedAt,
        DataSource
    ) VALUES (
        p_training_session_id,
        p_user_id,
        v_distance,
        v_duration,
        v_avg_pace,
        v_avg_hr,
        JSON_EXTRACT(p_raw_data, '$.max_heart_rate'),
        JSON_EXTRACT(p_raw_data, '$.avg_cadence'),
        JSON_EXTRACT(p_raw_data, '$.elevation_gain'),
        v_recorded_at,
        CONCAT('device_', p_device_id)
    );
    
    -- Obtener el ID generado
    SET v_data_id = LAST_INSERT_ID();
    
    -- Procesar datos de segmentos si existen
    IF JSON_EXISTS(p_raw_data, '$.segments') THEN
        INSERT INTO `performance`.`TrainingSegments` (
            DataId,
            SegmentNumber,
            SegmentType,
            Duration,
            DistanceKm,
            Pace,
            HeartRate,
            Cadence,
            ElevationChange
        )
        SELECT 
            v_data_id,
            JSON_EXTRACT(segment, '$.number'),
            JSON_EXTRACT(segment, '$.type'),
            JSON_EXTRACT(segment, '$.duration'),
            JSON_EXTRACT(segment, '$.distance'),
            JSON_EXTRACT(segment, '$.pace'),
            JSON_EXTRACT(segment, '$.heart_rate'),
            JSON_EXTRACT(segment, '$.cadence'),
            JSON_EXTRACT(segment, '$.elevation_change')
        FROM 
            JSON_TABLE(
                JSON_EXTRACT(p_raw_data, '$.segments'),
                '$[*]' COLUMNS (
                    segment JSON PATH '$'
                )
            ) AS segments;
    END IF;
    
    -- Procesar datos de ruta si existen
    IF JSON_EXISTS(p_raw_data, '$.route') AND p_data_type = 'activity_with_gps' THEN
        INSERT INTO `performance`.`RouteData` (
            DataId,
            RouteName,
            RoutePoints,
            TotalDistanceKm,
            StartPoint,
            EndPoint
        ) VALUES (
            v_data_id,
            JSON_EXTRACT(p_raw_data, '$.route.name'),
            JSON_EXTRACT(p_raw_data, '$.route.points'),
            v_distance,
            POINT(
                JSON_EXTRACT(p_raw_data, '$.route.start_point.longitude'),
                JSON_EXTRACT(p_raw_data, '$.route.start_point.latitude')
            ),
            POINT(
                JSON_EXTRACT(p_raw_data, '$.route.end_point.longitude'),
                JSON_EXTRACT(p_raw_data, '$.route.end_point.latitude')
            )
        );
    END IF;
    
    -- Registrar sincronización
    INSERT INTO `devices`.`SyncHistory` (
        UserDeviceId,
        SyncStartTime,
        SyncEndTime,
        SyncStatus,
        DataSummary
    ) VALUES (
        p_device_id,
        NOW(),
        NOW(),
        'success',
        JSON_OBJECT(
            'data_id', v_data_id,
            'distance', v_distance,
            'duration', v_duration,
            'data_type', p_data_type
        )
    );
    
    -- Actualizar último sincronizado en dispositivo
    UPDATE `devices`.`UserDevices`
    SET LastSyncAt = NOW()
    WHERE UserDeviceId = p_device_id;
    
    -- Actualizar sesión de entrenamiento como completada
    UPDATE `training`.`TrainingSessions`
    SET 
        Completed = 1,
        Notes = CONCAT(IFNULL(Notes, ''), '\nSincronizado desde dispositivo: ', p_device_id)
    WHERE 
        TrainingSessionId = p_training_session_id;
        
    -- Devolver el ID de datos creado
    SELECT v_data_id AS DataId;
END //


DELIMITER $$


-- Procedimiento para procesar token de autenticación de API externa
CREATE PROCEDURE `devices`.`ProcessExternalAuthToken`(
    IN p_user_id INT,
    IN p_provider VARCHAR(50),
    IN p_access_token VARCHAR(255),
    IN p_refresh_token VARCHAR(255),
    IN p_expiry_timestamp DATETIME,
    IN p_provider_user_id VARCHAR(100),
    IN p_settings JSON
)
BEGIN
    -- Verificar si ya existe integración
    IF EXISTS (
        SELECT 1 FROM `devices`.`ExternalIntegrations` 
        WHERE UserId = p_user_id AND Provider = p_provider
    ) THEN
        -- Actualizar la integración existente
        UPDATE `devices`.`ExternalIntegrations`
        SET 
            AccessToken = p_access_token,
            RefreshToken = p_refresh_token,
            TokenExpiry = p_expiry_timestamp,
            ConnectionStatus = 'active',
            IntegrationSettings = p_settings,
            ProviderUserId = p_provider_user_id
        WHERE 
            UserId = p_user_id AND Provider = p_provider;
    ELSE
        -- Crear nueva integración
        INSERT INTO `devices`.`ExternalIntegrations` (
            UserId,
            Provider,
            AccessToken,
            RefreshToken,
            TokenExpiry,
            ConnectionStatus,
            IntegrationSettings,
            ProviderUserId,
            ConnectedAt
        ) VALUES (
            p_user_id,
            p_provider,
            p_access_token,
            p_refresh_token,
            p_expiry_timestamp,
            'active',
            p_settings,
            p_provider_user_id,
            NOW()
        );
    END IF;
    
    -- Registrar actividad de conexión
    INSERT INTO `users`.`ActivityLogs` (
        UserId,
        Activity,
        Details,
        CreatedAt
    ) VALUES (
        p_user_id,
        'external_integration',
        JSON_OBJECT(
            'provider', p_provider,
            'action', 'connect',
            'status', 'success'
        ),
        NOW()
    );
END //
DELIMITER $$


-- --------------------------------------
-- 4.4 PROCEDIMIENTOS Y TRIGGERS PARA GAMIFICACIÓN
-- --------------------------------------
// DEL
-- Trigger para verificar logros cuando se completa una sesión de entrenamiento
CREATE TRIGGER `training`.`TrainingSession_CheckAchievements`
AFTER UPDATE ON `training`.`TrainingSessions`
FOR EACH ROW
BEGIN
    -- Solo procesar cuando una sesión pasa a completada
    IF NEW.Completed = 1 AND OLD.Completed = 0 THEN
        -- Llamar a procedimiento que evalúa logros
        CALL `gamification`.`EvaluateUserAchievements`(NEW.UserId, 'training_completed', NEW.TrainingSessionId);
    END IF;
END //




DELIMITER //
-- Trigger para verificar retos cuando se completa una sesión
CREATE TRIGGER `training`.`TrainingSession_CheckChallenges` 
AFTER UPDATE ON `training`.`TrainingSessions`
FOR EACH ROW
BEGIN
    -- Solo procesar cuando una sesión pasa a completada
    IF NEW.Completed = 1 AND OLD.Completed = 0 THEN
        -- Llamar a procedimiento que evalúa retos
        CALL `gamification`.`UpdateUserChallengesProgress`(NEW.UserId, 'training_completed', NEW.TrainingSessionId);
    END IF;
END //
DELIMITER ;


DELIMITER //
-- Procedimiento principal para evaluar logros de usuario
CREATE PROCEDURE `gamification`.`EvaluateUserAchievements`(
    IN p_user_id INT,
    IN p_trigger_type VARCHAR(50),
    IN p_related_id INT
)
BEGIN
    -- Variables para datos temporales
    -- DECLARE v_completed_workouts INT; -- Variable declared but not used, removed for clarity
    DECLARE v_consecutive_days INT DEFAULT 0; -- Initialize to avoid NULL issues if no rows found
    DECLARE v_total_distance DECIMAL(10,2) DEFAULT 0.00; -- Initialize
    DECLARE v_best_5k_time TIME;
    DECLARE v_achievement_id INT;
    DECLARE v_points INT;


    -- 1. Verificar logros de consistencia (entrenamientos seguidos)
    IF p_trigger_type = 'training_completed' THEN
        -- Contar días ÚNICOS con entrenamientos en los últimos 30 días
        -- NOTA: Esta lógica NO verifica días estrictamente CONSECUTIVOS.
        -- Implementar una lógica de días consecutivos real es más complejo.
        SELECT
            COUNT(DISTINCT DATE(SessionDate)) INTO v_consecutive_days
        FROM
            `training`.`TrainingSessions`
        WHERE
            UserId = p_user_id
            AND Completed = 1
            AND SessionDate > DATE_SUB(NOW(), INTERVAL 30 DAY) -- Consider edge cases with timezones if critical
            AND SessionDate <= NOW();
            -- Removed GROUP BY UserId as we are filtering by p_user_id already


        -- Verificar logros de consistencia por niveles (basado en días únicos en el período)
        IF v_consecutive_days >= 7 THEN
            -- Desbloquear logro de 7 días (en el período) si no lo tiene
            SELECT AchievementId, PointsValue INTO v_achievement_id, v_points
            FROM `gamification`.`Achievements`
            WHERE
                CategoryId = (SELECT CategoryId FROM `gamification`.`AchievementCategories` WHERE Name = 'Consistency')
                -- *** FIX: Added backticks around Condition ***
                AND JSON_EXTRACT(`Condition`, '$.consecutive_days') = 7
                AND IsActive = 1
            LIMIT 1; -- Ensure only one achievement is selected if multiple match somehow


            IF v_achievement_id IS NOT NULL THEN
                CALL `gamification`.`UnlockAchievement`(p_user_id, v_achievement_id, v_points, p_related_id);
                SET v_achievement_id = NULL; -- Reset for next check
                SET v_points = NULL;         -- Reset for next check
            END IF;
        END IF;


        -- Similar para otros niveles (14 días, 30 días, etc.) - Añadir lógica aquí si es necesario
        -- IF v_consecutive_days >= 14 THEN ... END IF;
        -- IF v_consecutive_days >= 30 THEN ... END IF;


    END IF;


    -- 2. Verificar logros de distancia total
    IF p_trigger_type IN ('training_completed', 'periodic_check') THEN
        -- Calcular distancia total recorrida
        SELECT
            COALESCE(SUM(td.DistanceKm), 0) INTO v_total_distance -- Use COALESCE to handle cases with no training data
        FROM
            `performance`.`TrainingData` td
        JOIN
            `training`.`TrainingSessions` ts ON td.TrainingSessionId = ts.TrainingSessionId
        WHERE
            td.UserId = p_user_id
            AND ts.Completed = 1;


        -- Verificar logros de distancia por niveles
        IF v_total_distance >= 100 THEN
            -- Desbloquear logro de 100km si no lo tiene
            SELECT AchievementId, PointsValue INTO v_achievement_id, v_points
            FROM `gamification`.`Achievements`
            WHERE
                CategoryId = (SELECT CategoryId FROM `gamification`.`AchievementCategories` WHERE Name = 'Distance')
                -- *** FIX: Added backticks around Condition ***
                AND JSON_EXTRACT(`Condition`, '$.total_distance') = 100
                AND IsActive = 1
            LIMIT 1;


            IF v_achievement_id IS NOT NULL THEN
                -- Using NULL for related_id here, ensure this is intended for distance achievements
                CALL `gamification`.`UnlockAchievement`(p_user_id, v_achievement_id, v_points, NULL);
                SET v_achievement_id = NULL; -- Reset
                SET v_points = NULL;         -- Reset
            END IF;
        END IF;


        -- Verificar otros niveles de distancia (250km, 500km, etc.) - Añadir lógica aquí
        -- IF v_total_distance >= 250 THEN ... END IF;
        -- IF v_total_distance >= 500 THEN ... END IF;


    END IF;


    -- 3. Verificar mejores marcas personales (5K, 10K, etc.)
    IF p_trigger_type = 'training_completed' THEN
        -- Buscar mejor tiempo en 5K (aproximado)
        -- Using WITH requires MySQL 8.0+
        WITH FiveKRuns AS (
            SELECT
                td.Duration as RunTime
            FROM
                `performance`.`TrainingData` td
            JOIN
                `training`.`TrainingSessions` ts ON td.TrainingSessionId = ts.TrainingSessionId
            WHERE
                td.UserId = p_user_id
                AND ts.Completed = 1
                AND td.DistanceKm BETWEEN 4.9 AND 5.1 -- Allow slight variation around 5k
        )
        SELECT MIN(RunTime) INTO v_best_5k_time FROM FiveKRuns;


        -- Si hay una mejor marca, comprobar si desbloquea logros
        IF v_best_5k_time IS NOT NULL THEN
            SELECT AchievementId, PointsValue INTO v_achievement_id, v_points
            FROM `gamification`.`Achievements`
            WHERE
                CategoryId = (SELECT CategoryId FROM `gamification`.`AchievementCategories` WHERE Name = 'Speed')
                -- *** FIX: Added backticks around Condition ***
                AND JSON_EXTRACT(`Condition`, '$.distance') BETWEEN 4.9 AND 5.1 -- Match distance flexibly
                -- Compare time: unlock if new time is faster than threshold
                AND TIME_TO_SEC(v_best_5k_time) < TIME_TO_SEC(JSON_UNQUOTE(JSON_EXTRACT(`Condition`, '$.time_threshold')))
                AND IsActive = 1
            ORDER BY JSON_EXTRACT(`Condition`, '$.time_threshold') DESC -- Prioritize harder achievements if multiple match
            LIMIT 1;


            IF v_achievement_id IS NOT NULL THEN
                CALL `gamification`.`UnlockAchievement`(p_user_id, v_achievement_id, v_points, p_related_id);
                -- No need to reset vars here as it's the end of this block
            END IF;
        END IF;


        -- Similar para 10K, medio maratón, etc. - Añadir lógica aquí


    END IF;


    -- Podríamos seguir con más lógica para diferentes tipos de logros


END //


DELIMITER ; -- Reset delimiter back to default


-- Procedimiento para desbloquear un logro
CREATE PROCEDURE `gamification`.`UnlockAchievement`(
    IN p_user_id INT,
    IN p_achievement_id INT,
    IN p_points INT,
    IN p_related_activity_id INT
)
BEGIN
    -- Solo desbloquear si aún no lo tiene
    IF NOT EXISTS (
        SELECT 1 FROM `gamification`.`UserAchievements` 
        WHERE UserId = p_user_id AND AchievementId = p_achievement_id
    ) THEN
        -- Registrar el logro
        INSERT INTO `gamification`.`UserAchievements` (
            UserId,
            AchievementId,
            UnlockedAt,
            RelatedActivityId
        ) VALUES (
            p_user_id,
            p_achievement_id,
            NOW(),
            p_related_activity_id
        );
        
        -- Añadir puntos
        INSERT INTO `gamification`.`PointsHistory` (
            UserId,
            Points,
            Reason,
            RelatedEntityType,
            RelatedEntityId,
            EarnedAt
        ) VALUES (
            p_user_id,
            p_points,
            'achievement_unlocked',
            'achievement',
            p_achievement_id,
            NOW()
        );
        
        -- Actualizar puntos totales
        IF EXISTS (SELECT 1 FROM `gamification`.`UserPoints` WHERE UserId = p_user_id) THEN
            UPDATE `gamification`.`UserPoints`
            SET 
                TotalPoints = TotalPoints + p_points,
                LastUpdated = NOW()
            WHERE 
                UserId = p_user_id;
        ELSE
            INSERT INTO `gamification`.`UserPoints` (
                UserId,
                TotalPoints,
                Level,
                PointsToNextLevel,
                LastUpdated
            ) VALUES (
                p_user_id,
                p_points,
                1,
                100,
                NOW()
            );
        END IF;
        
        -- Comprobar si sube de nivel
        CALL `gamification`.`CheckLevelUp`(p_user_id);
    END IF;
END //


-- Procedimiento para actualizar progreso en retos
CREATE PROCEDURE `gamification`.`UpdateUserChallengesProgress`(
    IN p_user_id INT,
    IN p_activity_type VARCHAR(50),
    IN p_activity_id INT
)
BEGIN
    -- Variables para datos
    DECLARE v_challenge_id INT;
    DECLARE v_condition JSON;
    DECLARE v_current_progress DECIMAL(5,2);
    DECLARE v_updated_progress DECIMAL(5,2);
    DECLARE v_is_completed TINYINT(1);
    DECLARE v_points_reward INT;
    DECLARE done INT DEFAULT FALSE;
    
    -- Cursor para retos activos del usuario
    DECLARE cur_challenges CURSOR FOR 
        SELECT 
            uc.ChallengeId,
            c.Condition,
            uc.Progress,
            c.PointsReward
        FROM 
            `gamification`.`UserChallenges` uc
        JOIN 
            `gamification`.`Challenges` c ON uc.ChallengeId = c.ChallengeId
        WHERE 
            uc.UserId = p_user_id
            AND uc.Status = 'active'
            AND c.StartDate <= NOW()
            AND c.EndDate >= NOW()
            AND JSON_EXTRACT(c.Condition, '$.activity_type') = p_activity_type;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur_challenges;
    
    read_loop: LOOP
        FETCH cur_challenges INTO v_challenge_id, v_condition, v_current_progress, v_points_reward;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Lógica para calcular progreso según el tipo de reto
        -- Esto debería ser personalizado para cada tipo de condición
        SET v_updated_progress = v_current_progress;
        SET v_is_completed = 0;


        -- Ejemplo: reto de completar entrenamientos
        IF p_activity_type = 'training_completed' AND 
           JSON_EXTRACT(v_condition, '$.type') = 'complete_workouts' THEN
            -- Incrementar progreso
            SET v_updated_progress = v_current_progress + 
                (100.0 / JSON_EXTRACT(v_condition, '$.target_count'));
                
            -- Verificar si está completado
            IF v_updated_progress >= 100 THEN
                SET v_updated_progress = 100;
                SET v_is_completed = 1;
            END IF;
            
            -- Actualizar progreso
            UPDATE `gamification`.`UserChallenges`
            SET 
                Progress = v_updated_progress,
                Status = IF(v_is_completed, 'completed', 'active'),
                CompletedAt = IF(v_is_completed, NOW(), NULL)
            WHERE 
                UserId = p_user_id AND ChallengeId = v_challenge_id;
                
            -- Si se completó, otorgar recompensa
            IF v_is_completed = 1 THEN
                INSERT INTO `gamification`.`PointsHistory` (
                    UserId,
                    Points,
                    Reason,
                    RelatedEntityType,
                    RelatedEntityId,
                    EarnedAt
                ) VALUES (
                    p_user_id,
                    v_points_reward,
                    'challenge_completed',
                    'challenge',
                    v_challenge_id,
                    NOW()
                );
                
                -- Actualizar puntos totales
                UPDATE `gamification`.`UserPoints`
                SET 
                    TotalPoints = TotalPoints + v_points_reward,
                    LastUpdated = NOW()
                WHERE 
                    UserId = p_user_id;
                    
                -- Comprobar si sube de nivel
                CALL `gamification`.`CheckLevelUp`(p_user_id);
            END IF;
        END IF;
        
        -- Aquí añadiríamos más lógica para otros tipos de retos
    END LOOP;
    
    CLOSE cur_challenges;
END //


-- Procedimiento para verificar y realizar subida de nivel
CREATE PROCEDURE `gamification`.`CheckLevelUp`(
    IN p_user_id INT
)
BEGIN
    DECLARE v_current_points INT;
    DECLARE v_current_level INT;
    DECLARE v_points_to_next_level INT;
    DECLARE v_new_level INT;
    DECLARE v_level_up TINYINT DEFAULT 0;
    
    -- Obtener datos actuales
    SELECT 
        TotalPoints, 
        Level,
        PointsToNextLevel 
    INTO 
        v_current_points, 
        v_current_level,
        v_points_to_next_level
    FROM 
        `gamification`.`UserPoints`
    WHERE 
        UserId = p_user_id;
        
    -- Calcular nuevo nivel usando fórmula
    -- Fórmula simple: cada nivel requiere level*100 puntos
    -- Nivel 1: 0-99, Nivel 2: 100-299, Nivel 3: 300-599, etc.
    SET v_new_level = FLOOR(SQRT(v_current_points / 100) + 1);
    
    -- Si hay subida de nivel
    IF v_new_level > v_current_level THEN
        SET v_level_up = 1;
        
        -- Actualizar nivel
        UPDATE `gamification`.`UserPoints`
        SET 
            Level = v_new_level,
            PointsToNextLevel = (v_new_level * v_new_level * 100) - v_current_points,
            LastUpdated = NOW()
        WHERE 
            UserId = p_user_id;
            
        -- Registrar evento de subida de nivel
        INSERT INTO `users`.`ActivityLogs` (
            UserId,
            Activity,
            Details,
            CreatedAt
        ) VALUES (
            p_user_id,
            'level_up',
            JSON_OBJECT(
                'old_level', v_current_level,
                'new_level', v_new_level,
                'points', v_current_points
            ),
            NOW()
        );
        
        -- Aquí podríamos añadir lógica para desbloquear recompensas por nivel
    ELSE
        -- Actualizar puntos para siguiente nivel
        UPDATE `gamification`.`UserPoints`
        SET 
            PointsToNextLevel = (v_current_level * v_current_level * 100) - v_current_points
        WHERE 
            UserId = p_user_id AND PointsToNextLevel <> (v_current_level * v_current_level * 100) - v_current_points;
    END IF;
    
    -- Devolver si hubo subida de nivel
    SELECT v_level_up AS LeveledUp;
END //


-- --------------------------------------
-- 4.5 PROCEDIMIENTOS PARA EVALUACIÓN DE DIFICULTAD
-- --------------------------------------


-- Procedimiento para evaluar y recomendar nivel de dificultad
CREATE PROCEDURE `training`.`EvaluateAndRecommendDifficulty`(
    IN p_user_id INT,
    OUT p_recommended_difficulty TINYINT,
    OUT p_recommendation_reason TEXT
)
BEGIN
    -- Variables de análisis
    DECLARE v_running_experience_days INT DEFAULT 0;
    DECLARE v_avg_weekly_distance DECIMAL(6,2) DEFAULT 0;
    DECLARE v_max_weekly_distance DECIMAL(6,2) DEFAULT 0;
    DECLARE v_avg_session_distance DECIMAL(6,2) DEFAULT 0;
    DECLARE v_recent_sessions_count INT DEFAULT 0;
    DECLARE v_first_session_date DATE;
    DECLARE v_best_5k_pace TIME;
    DECLARE v_most_common_intensity TINYINT;
    
    -- Determinar experiencia (días desde primera sesión)
    SELECT 
        MIN(ts.SessionDate) INTO v_first_session_date
    FROM 
        `training`.`TrainingSessions` ts
    WHERE 
        ts.UserId = p_user_id
        AND ts.Completed = 1;
        
    IF v_first_session_date IS NOT NULL THEN
        SET v_running_experience_days = DATEDIFF(CURRENT_DATE, v_first_session_date);
    ELSE
        SET v_running_experience_days = 0;
    END IF;
    
    -- Calcular promedio y máximo de distancia semanal en últimos 3 meses
    WITH WeeklyDistance AS (
        SELECT 
            YEARWEEK(ts.SessionDate) AS WeekNumber,
            SUM(td.DistanceKm) AS TotalDistance
        FROM 
            `training`.`TrainingSessions` ts
        JOIN 
            `performance`.`TrainingData` td ON ts.TrainingSessionId = td.TrainingSessionId
        WHERE 
            ts.UserId = p_user_id
            AND ts.Completed = 1
            AND ts.SessionDate >= DATE_SUB(CURRENT_DATE, INTERVAL 3 MONTH)
        GROUP BY 
            YEARWEEK(ts.SessionDate)
    )
    SELECT 
        AVG(TotalDistance),
        MAX(TotalDistance)
    INTO 
        v_avg_weekly_distance,
        v_max_weekly_distance
    FROM 
        WeeklyDistance;
        
    -- Calcular sesiones recientes (último mes)
    SELECT 
        COUNT(*),
        AVG(td.DistanceKm)
    INTO 
        v_recent_sessions_count,
        v_avg_session_distance
    FROM 
        `training`.`TrainingSessions` ts
    JOIN 
        `performance`.`TrainingData` td ON ts.TrainingSessionId = td.TrainingSessionId
    WHERE 
        ts.UserId = p_user_id
        AND ts.Completed = 1
        AND ts.SessionDate >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH);
        
    -- Buscar mejor ritmo en 5K (si existe)
    WITH FiveKRuns AS (
        SELECT 
            td.AvgPace
        FROM 
            `performance`.`TrainingData` td
        JOIN 
            `training`.`TrainingSessions` ts ON td.TrainingSessionId = ts.TrainingSessionId
        WHERE 
            td.UserId = p_user_id
            AND ts.Completed = 1
            AND ABS(td.DistanceKm - 5.0) < 0.1
            AND td.AvgPace IS NOT NULL
    )
    SELECT MIN(AvgPace) INTO v_best_5k_pace FROM FiveKRuns;
    
    -- Nivel de intensidad más común
    SELECT 
        IntensityLevel,
        COUNT(*) AS Count
    INTO 
        v_most_common_intensity,
        @temp_count
    FROM 
        `training`.`TrainingSessions`
    WHERE 
        UserId = p_user_id
        AND Completed = 1
        AND IntensityLevel IS NOT NULL
    GROUP BY 
        IntensityLevel
    ORDER BY 
        Count DESC
    LIMIT 1;
    
    -- Algoritmo de recomendación
    -- Este es un algoritmo simplificado. En producción podría usar un modelo ML más complejo.
    
    -- Valores predeterminados
    SET p_recommended_difficulty = 1;
    SET p_recommendation_reason = 'Recomendamos nivel Principiante para comenzar de forma segura.';
    
    -- Experiencia > 2 años y volumen semanal alto
    IF v_running_experience_days > 730 AND v_avg_weekly_distance > 50 THEN
        SET p_recommended_difficulty = 5;
        SET p_recommendation_reason = 'Basado en tu experiencia de más de 2 años y volumen semanal promedio de más de 50km, recomendamos nivel Avanzado.';
    
    -- Experiencia > 18 meses y volumen semanal medio-alto
    ELSEIF v_running_experience_days > 540 AND v_avg_weekly_distance > 35 THEN
        SET p_recommended_difficulty = 4;
        SET p_recommendation_reason = 'Basado en tu experiencia de más de 18 meses y volumen semanal promedio de más de 35km, recomendamos nivel Intermedio Avanzado.';
    
    -- Experiencia > 6 meses y volumen semanal medio
    ELSEIF v_running_experience_days > 180 AND v_avg_weekly_distance > 20 THEN
        SET p_recommended_difficulty = 3;
        SET p_recommendation_reason = 'Basado en tu experiencia de más de 6 meses y volumen semanal promedio de más de 20km, recomendamos nivel Intermedio.';
    
    -- Experiencia > 3 meses y entrenamiento regular
    ELSEIF v_running_experience_days > 90 AND v_recent_sessions_count >= 8 THEN
        SET p_recommended_difficulty = 2;
        SET p_recommendation_reason = 'Basado en tu experiencia de más de 3 meses y constancia reciente, recomendamos nivel Principiante Avanzado.';
    END IF;
    
    -- Modificadores adicionales
    -- Si corre mucho pero con poca experiencia, reducir un nivel para evitar lesiones
    IF v_running_experience_days < 180 AND v_avg_weekly_distance > 30 AND p_recommended_difficulty > 2 THEN
        SET p_recommended_difficulty = p_recommended_difficulty - 1;
        SET p_recommendation_reason = CONCAT(p_recommendation_reason, ' Ajustado un nivel hacia abajo para prevenir lesiones debido a tu relativamente corta experiencia con alto volumen.');
    END IF;
    
    -- Si tiene buen ritmo de 5K, considerar aumentar un nivel
    IF v_best_5k_pace IS NOT NULL THEN
        -- Convertir pace a segundos para comparar
        SET @pace_seconds = TIME_TO_SEC(v_best_5k_pace);
        
        IF @pace_seconds < 1200 AND p_recommended_difficulty < 5 THEN -- Menos de 20min (4:00 min/km)
            SET p_recommended_difficulty = p_recommended_difficulty + 1;
            SET p_recommendation_reason = CONCAT(p_recommendation_reason, ' Ajustado un nivel hacia arriba debido a tu excelente ritmo en 5K.');
        END IF;
    END IF;
    
    -- Devolver recomendación y razonamiento
    SELECT 
        p_recommended_difficulty AS RecommendedDifficulty,
        p_recommendation_reason AS RecommendationReason,
        (SELECT Name FROM `training`.`DifficultyLevels` WHERE DifficultyId = p_recommended_difficulty) AS DifficultyName;
END //


-- Procedimiento para generar distribución recomendada de intensidades
CREATE PROCEDURE `training`.`GenerateIntensityDistribution`(
    IN p_difficulty_level TINYINT,
    IN p_goal_type VARCHAR(20), -- 'race', 'pace', 'general'
    IN p_race_distance DECIMAL(6,2), -- Solo relevante si goal_type = 'race'
    OUT p_intensity_distribution JSON
)
BEGIN
    -- Variables para almacenar la distribución
    DECLARE v_recovery DECIMAL(5,2);
    DECLARE v_easy DECIMAL(5,2);
    DECLARE v_moderate DECIMAL(5,2);
    DECLARE v_threshold DECIMAL(5,2);
    DECLARE v_interval DECIMAL(5,2);
    DECLARE v_repetition DECIMAL(5,2);
    
    -- Distribución base según nivel de dificultad (porcentajes)
    CASE p_difficulty_level
        WHEN 1 THEN -- Principiante
            SET v_recovery = 20;
            SET v_easy = 75;
            SET v_moderate = 5;
            SET v_threshold = 0;
            SET v_interval = 0;
            SET v_repetition = 0;
            
        WHEN 2 THEN -- Principiante avanzado
            SET v_recovery = 15;
            SET v_easy = 70;
            SET v_moderate = 10;
            SET v_threshold = 5;
            SET v_interval = 0;
            SET v_repetition = 0;
            
        WHEN 3 THEN -- Intermedio
            SET v_recovery = 10;
            SET v_easy = 65;
            SET v_moderate = 10;
            SET v_threshold = 10;
            SET v_interval = 5;
            SET v_repetition = 0;
            
        WHEN 4 THEN -- Intermedio avanzado
            SET v_recovery = 10;
            SET v_easy = 60;
            SET v_moderate = 5;
            SET v_threshold = 15;
            SET v_interval = 7.5;
            SET v_repetition = 2.5;
            
        WHEN 5 THEN -- Avanzado
            SET v_recovery = 10;
            SET v_easy = 55;
            SET v_moderate = 5;
            SET v_threshold = 15;
            SET v_interval = 10;
            SET v_repetition = 5;
            
        ELSE -- Default (principiante)
            SET v_recovery = 20;
            SET v_easy = 75;
            SET v_moderate = 5;
            SET v_threshold = 0;
            SET v_interval = 0;
            SET v_repetition = 0;
    END CASE;
    
    -- Ajustes según tipo de objetivo
    IF p_goal_type = 'race' THEN
        -- Ajustes según distancia de carrera
        IF p_race_distance <= 5 THEN -- 5K
            -- Más énfasis en intervalos/velocidad
            SET v_easy = v_easy - 5;
            SET v_threshold = v_threshold + 0;
            SET v_interval = v_interval + 3;
            SET v_repetition = v_repetition + 2;
            
        ELSEIF p_race_distance <= 10 THEN -- 10K
            -- Balance entre umbral e intervalos
            SET v_easy = v_easy - 5;
            SET v_threshold = v_threshold + 3;
            SET v_interval = v_interval + 2;
            
        ELSEIF p_race_distance <= 21.1 THEN -- Media Maratón
            -- Más énfasis en umbral
            SET v_easy = v_easy - 5;
            SET v_threshold = v_threshold + 5;
            
        ELSEIF p_race_distance <= 42.2 THEN -- Maratón
            -- Más énfasis en volumen aeróbico
            SET v_easy = v_easy + 0;
            SET v_moderate = v_moderate + 5;
            SET v_threshold = v_threshold - 5;
            
        ELSE -- Ultra
            -- Fuerte énfasis en volumen aeróbico
            SET v_easy = v_easy + 5;
            SET v_moderate = v_moderate + 5;
            SET v_threshold = v_threshold - 5;
            SET v_interval = v_interval - 5;
        END IF;
        
    ELSEIF p_goal_type = 'pace' THEN
        -- Para objetivos de ritmo, más énfasis en umbral
        SET v_easy = v_easy - 5;
        SET v_threshold = v_threshold + 5;
        
    ELSEIF p_goal_type = 'general' THEN
        -- Para objetivos generales, distribución más equilibrada
        -- No hacemos cambios adicionales
    END IF;
    
    -- Garantizar que los porcentajes no sean negativos
    IF v_recovery < 0 THEN SET v_recovery = 0; END IF;
    IF v_easy < 0 THEN SET v_easy = 0; END IF;
    IF v_moderate < 0 THEN SET v_moderate = 0; END IF;
    IF v_threshold < 0 THEN SET v_threshold = 0; END IF;
    IF v_interval < 0 THEN SET v_interval = 0; END IF;
    IF v_repetition < 0 THEN SET v_repetition = 0; END IF;
    
    -- Normalizar para que sumen 100%
    SET @total = v_recovery + v_easy + v_moderate + v_threshold + v_interval + v_repetition;
    SET v_recovery = (v_recovery / @total) * 100;
    SET v_easy = (v_easy / @total) * 100;
    SET v_moderate = (v_moderate / @total) * 100;
    SET v_threshold = (v_threshold / @total) * 100;
    SET v_interval = (v_interval / @total) * 100;
    SET v_repetition = (v_repetition / @total) * 100;
    
    -- Crear JSON con la distribución
    SET p_intensity_distribution = JSON_OBJECT(
        'recovery', ROUND(v_recovery, 1),
        'easy', ROUND(v_easy, 1),
        'moderate', ROUND(v_moderate, 1),
        'threshold', ROUND(v_threshold, 1),
        'interval', ROUND(v_interval, 1),
        'repetition', ROUND(v_repetition, 1),
        'difficulty_level', p_difficulty_level,
        'goal_type', p_goal_type,
        'race_distance', IF(p_goal_type = 'race', p_race_distance, NULL)
    );
    
    -- Devolver resultado directamente
    SELECT p_intensity_distribution AS IntensityDistribution;
END //


-- Procedimiento para ajustar dificultad de un plan basado en rendimiento
CREATE PROCEDURE `training`.`AdjustPlanDifficulty`(
    IN p_training_plan_id INT,
    IN p_completion_rate DECIMAL(5,2), -- % de sesiones completadas
    IN p_perceived_effort_avg DECIMAL(3,1), -- Promedio de esfuerzo percibido (1-10)
    IN p_heart_rate_compliance DECIMAL(5,2), -- % de tiempo en zonas objetivo
    OUT p_adjustment_applied TINYINT,
    OUT p_adjustment_reason TEXT
)
BEGIN
    DECLARE v_current_difficulty TINYINT;
    DECLARE v_user_id INT;
    DECLARE v_new_difficulty TINYINT;
    DECLARE v_goal_id INT;
    DECLARE v_goal_type VARCHAR(20);
    DECLARE v_race_distance DECIMAL(6,2);
    DECLARE v_intensity_distribution JSON;
    
    -- Obtener información actual del plan
    SELECT 
        UserId,
        DifficultyLevel,
        GoalId
    INTO 
        v_user_id,
        v_current_difficulty,
        v_goal_id
    FROM 
        `training`.`TrainingPlans`
    WHERE 
        TrainingPlanId = p_training_plan_id;
        
    -- Obtener información de objetivo si existe
    IF v_goal_id IS NOT NULL THEN
        SELECT 
            gt.Name,
            CASE 
                WHEN gt.Name = 'Race' THEN rg.DistanceKm
                ELSE NULL
            END
        INTO 
            v_goal_type,
            v_race_distance
        FROM 
            `goals`.`UserGoals` ug
        JOIN 
            `goals`.`GoalTypes` gt ON ug.GoalTypeId = gt.GoalTypeId
        LEFT JOIN 
            `goals`.`RaceGoals` rg ON ug.GoalId = rg.GoalId
        WHERE 
            ug.GoalId = v_goal_id;
    ELSE
        SET v_goal_type = 'general';
        SET v_race_distance = NULL;
    END IF;
    
    -- Valor predeterminado - sin cambios
    SET v_new_difficulty = v_current_difficulty;
    SET p_adjustment_applied = 0;
    SET p_adjustment_reason = 'No se requieren ajustes al nivel de dificultad.';
    
    -- Lógica de ajuste basada en métricas
    -- 1. Si tasa de finalización es baja, reducir dificultad
    IF p_completion_rate < 70 THEN
        SET v_new_difficulty = v_current_difficulty - 1;
        SET p_adjustment_reason = 'Tasa de finalización baja (menos del 70%). Reduciendo nivel de dificultad para mejorar adherencia.';
    END IF;
    
    -- 2. Si esfuerzo percibido es muy alto, reducir dificultad
    IF p_perceived_effort_avg > 8 AND v_new_difficulty = v_current_difficulty THEN
        SET v_new_difficulty = v_current_difficulty - 1;
        SET p_adjustment_reason = 'Esfuerzo percibido consistentemente alto (>8/10). Reduciendo nivel de dificultad para prevenir sobreesfuerzo.';
    END IF;
    
    -- 3. Si esfuerzo percibido es bajo y tasa de finalización alta, aumentar dificultad
    IF p_perceived_effort_avg < 5 AND p_completion_rate > 90 AND v_new_difficulty = v_current_difficulty THEN
        SET v_new_difficulty = v_current_difficulty + 1;
        SET p_adjustment_reason = 'Esfuerzo percibido bajo (<5/10) con alta tasa de finalización. Aumentando nivel para optimizar progreso.';
    END IF;
    
    -- 4. Cumplimiento de zonas de frecuencia cardíaca
    IF p_heart_rate_compliance < 60 AND v_new_difficulty = v_current_difficulty THEN
        SET v_new_difficulty = v_current_difficulty - 1;
        SET p_adjustment_reason = 'Bajo cumplimiento de zonas de frecuencia cardíaca objetivo. Reduciendo nivel para mejorar adaptaciones fisiológicas.';
    END IF;
    
    -- Restricciones de límites
    IF v_new_difficulty < 1 THEN
        SET v_new_difficulty = 1;
    ELSEIF v_new_difficulty > 5 THEN
        SET v_new_difficulty = 5;
    END IF;
    
    -- Aplicar cambios si hubo modificación
    IF v_new_difficulty <> v_current_difficulty THEN
        -- Generar nueva distribución de intensidades
        CALL `training`.`GenerateIntensityDistribution`(
            v_new_difficulty,
            v_goal_type,
            v_race_distance,
            v_intensity_distribution
        );
        
        -- Actualizar plan con nueva dificultad
        UPDATE `training`.`TrainingPlans`
        SET 
            DifficultyLevel = v_new_difficulty,
            IntensityDistribution = v_intensity_distribution,
            LastAdaptedAt = NOW(),
            AdaptationCount = IFNULL(AdaptationCount, 0) + 1
        WHERE 
            TrainingPlanId = p_training_plan_id;
            
        -- Registrar adaptación en historial
        INSERT INTO `training`.`TrainingPlanHistory` (
            TrainingPlanId,
            PlanVersion,
            AdaptationReason,
            AdaptationDetails,
            AdaptedAt
        ) VALUES (
            p_training_plan_id,
            (SELECT IFNULL(MAX(PlanVersion), 0) + 1 
             FROM `training`.`TrainingPlanHistory` 
             WHERE TrainingPlanId = p_training_plan_id),
            'difficulty_adjustment',
            JSON_OBJECT(
                'old_difficulty', v_current_difficulty,
                'new_difficulty', v_new_difficulty,
                'completion_rate', p_completion_rate,
                'perceived_effort_avg', p_perceived_effort_avg,
                'heart_rate_compliance', p_heart_rate_compliance,
                'reason', p_adjustment_reason,
                'new_intensity_distribution', v_intensity_distribution
            ),
            NOW()
        );
        
        SET p_adjustment_applied = 1;
    END IF;
    
    -- Devolver resultados de ajuste
    SELECT 
        p_adjustment_applied AS AdjustmentApplied,
        p_adjustment_reason AS AdjustmentReason,
        v_new_difficulty AS NewDifficultyLevel,
        (SELECT Name FROM `training`.`DifficultyLevels` WHERE DifficultyId = v_new_difficulty) AS DifficultyName,
        v_intensity_distribution AS NewIntensityDistribution;
END //


-- --------------------------------------
-- 4.6 EVENTOS PROGRAMADOS PARA MANTENIMIENTO
-- --------------------------------------
DELIMITER //


DELIMITER //
-- Evento para actualizar estadísticas de actividad diariamente
CREATE EVENT IF NOT EXISTS `training`.`DailyActivityUpdate`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 2 HOUR
DO
BEGIN
    -- Actualizar métricas de progreso
    INSERT INTO `performance`.`UserProgressMetrics` (
        UserId,
        MetricDate,
        MetricType,
        MetricValue,
        ComparisonPercentage
    )
    SELECT 
        u.UserId,
        CURRENT_DATE,
        'weekly_distance',
        IFNULL(SUM(td.DistanceKm), 0),
        CASE 
            WHEN prev.MetricValue IS NULL THEN NULL
            WHEN prev.MetricValue = 0 THEN 100
            ELSE ((SUM(td.DistanceKm) - prev.MetricValue) / prev.MetricValue) * 100
        END
    FROM 
        `users`.`Users` u
    LEFT JOIN 
        `training`.`TrainingSessions` ts ON u.UserId = ts.UserId AND 
            ts.SessionDate BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY) AND CURRENT_DATE AND 
            ts.Completed = 1
    LEFT JOIN 
        `performance`.`TrainingData` td ON ts.TrainingSessionId = td.TrainingSessionId
    LEFT JOIN (
        SELECT 
            UserId, 
            MetricValue
        FROM 
            `performance`.`UserProgressMetrics`
        WHERE 
            MetricType = 'weekly_distance' AND
            MetricDate = DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY)
    ) prev ON u.UserId = prev.UserId
    GROUP BY 
        u.UserId, prev.MetricValue;
        
    -- Más actualizaciones de métricas aquí
END //


DELIMITER ;


DELIMITER //
-- Evento para verificar y actualizar retos diarios
CREATE EVENT IF NOT EXISTS `gamification`.`DailyChallengesUpdate`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY
DO
BEGIN
    -- Marcar como fallidos retos vencidos
    UPDATE `gamification`.`UserChallenges` uc
    JOIN `gamification`.`Challenges` c ON uc.ChallengeId = c.ChallengeId
    SET 
        uc.Status = 'failed',
        uc.CompletedAt = NOW()
    WHERE 
        uc.Status = 'active' AND
        c.EndDate < NOW();
        
    -- Crear nuevos retos diarios si es necesario
    -- (Aquí iría lógica específica para crear retos diarios automáticos)
END //
DELIMITER ;


CREATE DATABASE maintenance;




DELIMITER //
-- Evento para optimizar tablas semanalmente
CREATE EVENT IF NOT EXISTS `maintenance`.`WeeklyDatabaseOptimization`
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_DATE + INTERVAL 2 DAY + INTERVAL 3 HOUR
DO
BEGIN
   OPTIMIZE TABLE 
       `performance`.`TrainingData`, 
       `performance`.`TrainingSegments`,
       `training`.`TrainingSessions`,
       `users`.`ActivityLogs`,
       `devices`.`SyncHistory`;
END //


DELIMITER ;


-- Volver a activar verificación de claves foráneas
SET foreign_key_checks = 1;


-- ================================================================
-- FIN DEL SCRIPT
-- ================================================================
-- Este script completo permite crear toda la estructura de base de datos 
-- para la aplicación de entrenamiento de corredores, incluyendo la 
-- arquitectura multi-esquema, integración con Firebase/Supabase, 
-- extensiones específicas para corredores, procedimientos y funciones
-- recomendados, y sistema de niveles de dificultad.
-- ================================================================

```