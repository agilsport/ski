-- --------------------------------------------------------
-- Hôte:                         127.0.0.1
-- Version du serveur:           5.7.33 - MySQL Community Server (GPL)
-- SE du serveur:                Win64
-- HeidiSQL Version:             11.2.0.6213
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Listage de la structure de la table ski. Seeding_FS
CREATE TABLE IF NOT EXISTS `Seeding_FS` (
  `Code_SEEDING` char(9) DEFAULT NULL,
  `Place_Points` int(3) DEFAULT NULL,
  `Critere` char(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Listage des données de la table ski.Seeding_FS : ~223 rows (environ)
/*!40000 ALTER TABLE `Seeding_FS` DISABLE KEYS */;
INSERT IGNORE INTO `Seeding_FS` (`Code_SEEDING`, `Place_Points`, `Critere`) VALUES
	('SEEDING_2', 1, '001'),
	('SEEDING_2', 2, '002'),
	('SEEDING_2', 3, '002'),
	('SEEDING_2', 4, '001'),
	('SEEDING_2', 5, '001'),
	('SEEDING_2', 6, '002'),
	('SEEDING_2', 7, '002'),
	('SEEDING_2', 8, '001'),
	('SEEDING_2', 9, '001'),
	('SEEDING_2', 10, '002'),
	('SEEDING_2', 11, '002'),
	('SEEDING_2', 12, '001'),
	('SEEDING_2', 13, '001'),
	('SEEDING_2', 14, '002'),
	('SEEDING_2', 15, '002'),
	('SEEDING_2', 16, '001'),
	('SEEDING_2', 17, '001'),
	('SEEDING_2', 18, '002'),
	('SEEDING_2', 19, '002'),
	('SEEDING_2', 20, '001'),
	('SEEDING_2', 21, '001'),
	('SEEDING_2', 22, '002'),
	('SEEDING_2', 23, '002'),
	('SEEDING_2', 24, '001'),
	('SEEDING_2', 25, '001'),
	('SEEDING_2', 26, '002'),
	('SEEDING_2', 27, '002'),
	('SEEDING_2', 28, '001'),
	('SEEDING_2', 29, '001'),
	('SEEDING_2', 30, '002'),
	('SEEDING_2', 31, '002'),
	('SEEDING_2', 32, '001'),
	('SEEDING_2', 33, '001'),
	('SEEDING_2', 34, '002'),
	('SEEDING_2', 35, '002'),
	('SEEDING_2', 36, '001'),
	('SEEDING_2', 37, '001'),
	('SEEDING_2', 38, '002'),
	('SEEDING_2', 39, '002'),
	('SEEDING_2', 40, '001'),
	('SEEDING_2', 41, '001'),
	('SEEDING_2', 42, '002'),
	('SEEDING_2', 43, '002'),
	('SEEDING_2', 44, '001'),
	('SEEDING_2', 45, '001'),
	('SEEDING_2', 46, '002'),
	('SEEDING_2', 47, '002'),
	('SEEDING_2', 48, '001'),
	('SEEDING_2', 49, '001'),
	('SEEDING_2', 50, '002'),
	('SEEDING_2', 51, '002'),
	('SEEDING_2', 52, '001'),
	('SEEDING_2', 53, '001'),
	('SEEDING_2', 54, '002'),
	('SEEDING_2', 55, '002'),
	('SEEDING_2', 56, '001'),
	('SEEDING_2', 57, '001'),
	('SEEDING_2', 58, '002'),
	('SEEDING_2', 59, '002'),
	('SEEDING_2', 60, '001'),
	('SEEDING_2', 61, '001'),
	('SEEDING_2', 62, '002'),
	('SEEDING_2', 63, '002'),
	('SEEDING_2', 64, '001'),
	('SEEDING_2', 65, '001'),
	('SEEDING_2', 66, '002'),
	('SEEDING_2', 67, '002'),
	('SEEDING_2', 68, '001'),
	('SEEDING_2', 69, '001'),
	('SEEDING_2', 70, '002'),
	('SEEDING_2', 71, '002'),
	('SEEDING_2', 72, '001'),
	('SEEDING_2', 73, '001'),
	('SEEDING_2', 74, '002'),
	('SEEDING_2', 75, '002'),
	('SEEDING_2', 76, '001'),
	('SEEDING_2', 77, '001'),
	('SEEDING_2', 78, '002'),
	('SEEDING_2', 79, '002'),
	('SEEDING_2', 80, '001'),
	('SEEDING_2', 81, '001'),
	('SEEDING_2', 82, '002'),
	('SEEDING_2', 83, '002'),
	('SEEDING_2', 84, '001'),
	('SEEDING_2', 85, '001'),
	('SEEDING_2', 86, '002'),
	('SEEDING_2', 87, '002'),
	('SEEDING_2', 88, '001'),
	('SEEDING_2', 89, '001'),
	('SEEDING_2', 90, '002'),
	('SEEDING_2', 91, '002'),
	('SEEDING_2', 92, '001'),
	('SEEDING_2', 93, '001'),
	('SEEDING_2', 94, '002'),
	('SEEDING_2', 95, '002'),
	('SEEDING_2', 96, '001'),
	('SEEDING_2', 97, '001'),
	('SEEDING_2', 98, '002'),
	('SEEDING_2', 99, '002'),
	('SEEDING_3', 1, 'A'),
	('SEEDING_3', 2, 'B'),
	('SEEDING_3', 3, 'C'),
	('SEEDING_3', 4, 'C'),
	('SEEDING_3', 5, 'B'),
	('SEEDING_3', 6, 'A'),
	('SEEDING_3', 7, 'A'),
	('SEEDING_3', 8, 'B'),
	('SEEDING_3', 9, 'C'),
	('SEEDING_3', 10, 'C'),
	('SEEDING_3', 11, 'B'),
	('SEEDING_3', 12, 'A'),
	('SEEDING_3', 13, 'A'),
	('SEEDING_3', 14, 'B'),
	('SEEDING_3', 15, 'C'),
	('SEEDING_3', 16, 'C'),
	('SEEDING_3', 17, 'B'),
	('SEEDING_3', 18, 'A'),
	('SEEDING_3', 19, 'A'),
	('SEEDING_3', 20, 'B'),
	('SEEDING_3', 21, 'C'),
	('SEEDING_3', 22, 'C'),
	('SEEDING_3', 23, 'B'),
	('SEEDING_3', 24, 'A'),
	('SEEDING_3', 25, 'A'),
	('SEEDING_3', 26, 'B'),
	('SEEDING_3', 27, 'C'),
	('SEEDING_3', 28, 'C'),
	('SEEDING_3', 29, 'B'),
	('SEEDING_3', 30, 'A'),
	('SEEDING_3', 31, 'A'),
	('SEEDING_3', 32, 'B'),
	('SEEDING_3', 33, 'C'),
	('SEEDING_3', 34, 'C'),
	('SEEDING_3', 35, 'B'),
	('SEEDING_3', 36, 'A'),
	('SEEDING_3', 37, 'A'),
	('SEEDING_3', 38, 'B'),
	('SEEDING_3', 39, 'C'),
	('SEEDING_3', 40, 'C'),
	('SEEDING_3', 41, 'B'),
	('SEEDING_3', 42, 'A'),
	('SEEDING_3', 43, 'A'),
	('SEEDING_3', 44, 'B'),
	('SEEDING_3', 45, 'C'),
	('SEEDING_3', 46, 'C'),
	('SEEDING_3', 47, 'B'),
	('SEEDING_3', 48, 'A'),
	('SEEDING_3', 49, 'A'),
	('SEEDING_3', 50, 'B'),
	('SEEDING_3', 51, 'C'),
	('SEEDING_3', 52, 'C'),
	('SEEDING_3', 53, 'B'),
	('SEEDING_3', 54, 'A'),
	('SEEDING_3', 55, 'A'),
	('SEEDING_3', 56, 'B'),
	('SEEDING_3', 57, 'C'),
	('SEEDING_3', 58, 'C'),
	('SEEDING_3', 59, 'B'),
	('SEEDING_3', 60, 'A'),
	('SEEDING_3', 61, 'A'),
	('SEEDING_3', 62, 'B'),
	('SEEDING_3', 63, 'C'),
	('SEEDING_3', 64, 'C'),
	('SEEDING_3', 65, 'B'),
	('SEEDING_3', 66, 'A'),
	('SEEDING_3', 67, 'A'),
	('SEEDING_3', 68, 'B'),
	('SEEDING_3', 69, 'C'),
	('SEEDING_3', 70, 'C'),
	('SEEDING_3', 71, 'B'),
	('SEEDING_3', 72, 'A'),
	('SEEDING_3', 73, 'A'),
	('SEEDING_3', 74, 'B'),
	('SEEDING_3', 75, 'C'),
	('SEEDING_3', 76, 'C'),
	('SEEDING_3', 77, 'B'),
	('SEEDING_3', 78, 'A'),
	('SEEDING_3', 79, 'A'),
	('SEEDING_3', 80, 'B'),
	('SEEDING_3', 81, 'C'),
	('SEEDING_3', 82, 'C'),
	('SEEDING_3', 83, 'B'),
	('SEEDING_3', 84, 'A'),
	('SEEDING_3', 85, 'A'),
	('SEEDING_3', 86, 'B'),
	('SEEDING_3', 87, 'C'),
	('SEEDING_3', 88, 'C'),
	('SEEDING_3', 89, 'B'),
	('SEEDING_3', 90, 'A'),
	('SEEDING_3', 91, 'A'),
	('SEEDING_3', 92, 'B'),
	('SEEDING_3', 93, 'C'),
	('SEEDING_3', 94, 'C'),
	('SEEDING_3', 95, 'B'),
	('SEEDING_3', 96, 'A'),
	('SEEDING_3', 97, 'A'),
	('SEEDING_3', 98, 'B'),
	('SEEDING_3', 99, 'C'),
	('SEEDING_4', 1, 'A'),
	('SEEDING_4', 2, 'B'),
	('SEEDING_4', 3, 'C'),
	('SEEDING_4', 4, 'D'),
	('SEEDING_4', 5, 'D'),
	('SEEDING_4', 6, 'C'),
	('SEEDING_4', 7, 'B'),
	('SEEDING_4', 8, 'A'),
	('SEEDING_4', 9, 'A'),
	('SEEDING_4', 10, 'B'),
	('SEEDING_4', 11, 'C'),
	('SEEDING_4', 12, 'D'),
	('SEEDING_4', 13, 'D'),
	('SEEDING_4', 14, 'C'),
	('SEEDING_4', 15, 'B'),
	('SEEDING_4', 16, 'A'),
	('SEEDING_4', 17, 'A'),
	('SEEDING_4', 18, 'B'),
	('SEEDING_4', 19, 'C'),
	('SEEDING_4', 20, 'D'),
	('SEEDING_4', 21, 'D'),
	('SEEDING_4', 22, 'C'),
	('SEEDING_4', 23, 'B'),
	('SEEDING_4', 24, 'A'),
	('SEEDING_4', 25, 'A'),
	('SEEDING_4', 26, 'B'),
	('SEEDING_4', 27, 'C'),
	('SEEDING_4', 28, 'D'),
	('SEEDING_4', 29, 'D'),
	('SEEDING_4', 30, 'C'),
	('SEEDING_4', 31, 'B'),
	('SEEDING_4', 32, 'A'),
	('SEEDING_4', 33, 'A'),
	('SEEDING_4', 34, 'B'),
	('SEEDING_4', 35, 'C'),
	('SEEDING_4', 36, 'D'),
	('SEEDING_4', 37, 'D'),
	('SEEDING_4', 38, 'C'),
	('SEEDING_4', 39, 'B'),
	('SEEDING_4', 40, 'A'),
	('SEEDING_4', 41, 'A'),
	('SEEDING_4', 42, 'B'),
	('SEEDING_4', 43, 'C'),
	('SEEDING_4', 44, 'D'),
	('SEEDING_4', 45, 'D'),
	('SEEDING_4', 46, 'C'),
	('SEEDING_4', 47, 'B'),
	('SEEDING_4', 48, 'A'),
	('SEEDING_4', 49, 'A'),
	('SEEDING_4', 50, 'B'),
	('SEEDING_4', 51, 'C'),
	('SEEDING_4', 52, 'D'),
	('SEEDING_4', 53, 'D'),
	('SEEDING_4', 54, 'C'),
	('SEEDING_4', 55, 'B'),
	('SEEDING_4', 56, 'A'),
	('SEEDING_4', 57, 'A'),
	('SEEDING_4', 58, 'B'),
	('SEEDING_4', 59, 'C'),
	('SEEDING_4', 60, 'D'),
	('SEEDING_4', 61, 'D'),
	('SEEDING_4', 62, 'C'),
	('SEEDING_4', 63, 'B'),
	('SEEDING_4', 64, 'A'),
	('SEEDING_4', 65, 'A'),
	('SEEDING_4', 66, 'B'),
	('SEEDING_4', 67, 'C'),
	('SEEDING_4', 68, 'D'),
	('SEEDING_4', 69, 'D'),
	('SEEDING_4', 70, 'C'),
	('SEEDING_4', 71, 'B'),
	('SEEDING_4', 72, 'A'),
	('SEEDING_4', 73, 'A'),
	('SEEDING_4', 74, 'B'),
	('SEEDING_4', 75, 'C'),
	('SEEDING_4', 76, 'D'),
	('SEEDING_4', 77, 'D'),
	('SEEDING_4', 78, 'C'),
	('SEEDING_4', 79, 'B'),
	('SEEDING_4', 80, 'A'),
	('SEEDING_4', 81, 'A'),
	('SEEDING_4', 82, 'B'),
	('SEEDING_4', 83, 'C'),
	('SEEDING_4', 84, 'D'),
	('SEEDING_4', 85, 'D'),
	('SEEDING_4', 86, 'C'),
	('SEEDING_4', 87, 'B'),
	('SEEDING_4', 88, 'A'),
	('SEEDING_4', 89, 'A'),
	('SEEDING_4', 90, 'B'),
	('SEEDING_4', 91, 'C'),
	('SEEDING_4', 92, 'D'),
	('SEEDING_4', 93, 'D'),
	('SEEDING_4', 94, 'C'),
	('SEEDING_4', 95, 'B'),
	('SEEDING_4', 96, 'A'),
	('SEEDING_4', 97, 'A'),
	('SEEDING_4', 98, 'B'),
	('SEEDING_4', 99, 'C');
/*!40000 ALTER TABLE `Seeding_FS` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
