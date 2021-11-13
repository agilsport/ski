CREATE TABLE `Context` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Mode` char(20) DEFAULT NULL,
  `Title` char(150) DEFAULT NULL,
  `Best_identity` char(150) DEFAULT NULL,
  `Best_time` char(12) DEFAULT NULL,
  `Best_time1` char(12) DEFAULT NULL,
  `Best_time2` char(12) DEFAULT NULL,
  `Best_time3` char(12) DEFAULT NULL,
  `Best_time4` char(12) DEFAULT NULL,
  `Best_timeMs` int(11) DEFAULT NULL,
  `Best_time1Ms` int(11) DEFAULT NULL,
  `Best_time2Ms` int(11) DEFAULT NULL,
  `Best_time3Ms` int(11) DEFAULT NULL,
  `Best_time4Ms` int(11) DEFAULT NULL,
  `Nb_inter` int(11) DEFAULT NULL,
  `Manche` int(11) DEFAULT NULL,
  `Time1Ms` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
INSERT INTO Context (ID) VALUES (1);

CREATE TABLE `Epreuve` (
  `Code` int(11) NOT NULL,
  `Start` int(11) DEFAULT NULL,
  PRIMARY KEY (`Code`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `Next` (
  `ID` int(11) NOT NULL,
  `Tick` char(12) DEFAULT NULL,
  `Bib` int(11) DEFAULT NULL,
  `Identity` char(150) DEFAULT NULL,
  `Team` char(30) DEFAULT NULL,
  `Time` char(12) DEFAULT NULL,
  `Rank` char(4) DEFAULT NULL,
  `Diff` char(12) DEFAULT NULL,
  `State` char(1) DEFAULT NULL,
  `Time1Ms` int(11) DEFAULT NULL,
  `Diff1Ms` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `Ping` (
  `ID` char(10) NOT NULL,
  `Tick` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `Ranking` (
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
  `Categ` char(12) DEFAULT NULL,
  `Sex` char(1) DEFAULT NULL,
  `Distance` char(12) DEFAULT NULL,
  `Epreuve` int(11) DEFAULT NULL,
  `Finish` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `Running` (
  `ID` int(11) NOT NULL,
  `Tick` char(12) DEFAULT NULL,
  `Bib` int(11) DEFAULT NULL,
  `Identity` char(150) DEFAULT NULL,
  `Team` char(30) DEFAULT NULL,
  `Time` char(12) DEFAULT NULL,
  `Rank` char(4) DEFAULT NULL,
  `State` char(1) DEFAULT NULL,
  `Diff` char(12) DEFAULT NULL,
  `TimeMs` int(11) DEFAULT NULL,
  `Passage` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `Startlist` (
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
  `Categ` char(12) DEFAULT NULL,
  `Sex` char(1) DEFAULT NULL,
  `Distance` char(12) DEFAULT NULL,
  `Epreuve` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

