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

-- Listage de la structure de la table tv. Ranking
CREATE TABLE IF NOT EXISTS `Ranking` (
  `ID` int(11) NOT NULL,
  `Tick` char(12) DEFAULT NULL,
  `Bib` int(11) DEFAULT NULL,
  `Identity` char(150) DEFAULT NULL,
  `Team` char(30) DEFAULT NULL,
  `Rank1` char(4) DEFAULT NULL,
  `Time1` char(12) DEFAULT NULL,
  `Rank2` char(4) DEFAULT NULL,
  `Time2` char(12) DEFAULT NULL,
  `Rank` char(4) DEFAULT NULL,
  `Time` char(12) DEFAULT NULL,
  `Cltc` int(11) DEFAULT NULL,
  `Cltc1` int(11) DEFAULT NULL,
  `Cltc2` int(11) DEFAULT NULL,
  `Categ` char(12) DEFAULT NULL,
  `Sex` char(1) DEFAULT NULL,
  `Distance` char(12) DEFAULT NULL,
  `Epreuve` int(11) DEFAULT NULL,
  `Finish` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- Listage des données de la table tv.Ranking : 3 rows
/*!40000 ALTER TABLE `Ranking` DISABLE KEYS */;
INSERT IGNORE INTO `Ranking` (`ID`, `Tick`, `Bib`, `Identity`, `Team`, `Rank1`, `Time1`, `Rank2`, `Time2`, `Rank`, `Time`, `Cltc`, `Cltc1`, `Cltc2`, `Categ`, `Sex`, `Distance`, `Epreuve`, `Finish`) VALUES
	(1, '144992092', 3, 'VERDIER PAULINE', 'SC DE BESSE', '1', '05.0', NULL, NULL, '1', '05.0', 1, 1, NULL, 'U15', 'F', '5', 1, 69901057),
/*!40000 ALTER TABLE `Ranking` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
