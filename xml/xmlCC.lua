-- FIS Cross-Country Data Exchange XML Protocol version 3.4 => https://www.fis-ski.com/en/inside-fis/document-library/timing-data
function beforeFisresults(t)
	base:SetGlobalVariable({'table', 'record'}); -- tName => table Name, rName => record Name
	
	if mode == 'import' then
		tEvenement:AddRow();
		tEpreuve:AddRow();
		tEpreuve_Nordique:AddRow();
		tDiscipline:AddRow();
		
		tResultat_Copy = tResultat:Copy(false, true);
		tResultat_Manche_Copy = tResultat_Manche:Copy(false, true);
		tResultat_Inter_Copy = tResultat_Inter:Copy(false, true);
	end
end

function afterFisresults(t)
	xmlError = xmlError or {};
	xmlWarning = xmlWarning or {};
	if mode == 'import' then
		if #xmlError == 0 then
			-- Verification table Evenement - Mise de valeurs par défaut ...
			if tEvenement:IsCellNull('Code_activite', 0) then tEvenement:SetCell('Code_activite', 0, 'FOND') end
			if tEvenement:IsCellNull('Code_entite', 0) then tEvenement:SetCell('Code_entite', 0, 'FIS') end
			local codex = tEvenement:GetCell('Code_nation', 0)..tEvenement:GetCell('Codex', 0);
			tEvenement:SetCell('Codex', 0, codex);
			
			-- Verification table Epreuve - Mise de valeurs par défaut ...
			if tEpreuve:IsCellNull('Code_grille_categorie', 0) then tEpreuve:SetCell('Code_grille_categorie', 0, 'FIS-ALP') end
			if tEpreuve:IsCellNull('Code_categorie', 0) then tEpreuve:SetCell('Code_categorie', 0, '*') end

			-- Epreuve.Code_discipline : Recherche par le Code International
			local codeInternational = tDiscipline:GetCell("Code_international", 0);
			base:TableLoad(tDiscipline, 
				"Select * From Discipline "..
				"Where Code_activite = '"..tEvenement:GetCell('Code_activite',0).."' "..
				"And Code_entite = '"..tEvenement:GetCell('Code_entite',0).."' "..
				"And Code_saison = '"..tEvenement:GetCell('Code_saison',0).."' "..
				"And Code_international = '"..codeInternational.."' ");
			if tDiscipline:GetCell('Code', 0) ~= '' then
				tEpreuve:SetCell('Code_discipline', 0, tDiscipline:GetCell('Code', 0));
			else
				tEpreuve:SetCell('Code_discipline', 0, codeInternational);
			end

			-- Transfert Final des tables Resultats ...
			tResultat:RemoveAllRows(); tResultat:AddRow(tResultat_Copy);
			tResultat_Manche:RemoveAllRows(); tResultat_Manche:AddRow(tResultat_Manche_Copy);
			tResultat_Inter:RemoveAllRows(); tResultat_Inter:AddRow(tResultat_Inter_Copy);
			base:InsertBaseEvenement();
		end
		if #xmlError == 0 then
			msg:AddLineSuccess('Import : Error(s) = '..#xmlError..', Warning(s) = '..#xmlWarning);
		else
			msg:AddLineError('Import : Error(s) = '..#xmlError..', Warning(s) = '..#xmlWarning);
		end
	else
		if #xmlError == 0 then
			msg:AddLineSuccess('Export : Error(s) = '..#xmlError..', Warning(s) = '..#xmlWarning);
		else
			msg:AddLineError('Export : Error(s) = '..#xmlError..', Warning(s) = '..#xmlWarning);
		end
	end
end

function afterRaceheader(t)
	if mode == 'import' then
		-- Gender <=> Sexe 
		if t.attributes.Gender == 'W' then tEpreuve:SetCell('Sexe', 0, 'F');
		elseif t.attributes.Gender == 'A' then tEpreuve:SetCell('Sexe', 0, 'T');
		else tEpreuve:SetCell('Sexe', 0, 'M');
		end
	else
		SetAttributes(t, 'Sector', 'CC');
		if tEpreuve:GetCell('Sexe', 0) == 'F' then t.attributes.Gender = 'W';
		elseif tEpreuve:GetCell('Sexe', 0) == 'T' then t.attributes.Gender = 'A';
		else t.attributes.Gender = 'M';
		end
	end
end

function afterRacedate(t)
	if mode == 'import' then
		tEpreuve:LoadCell('Date_epreuve', 0, t.children.Year[1].content..'/'..t.children.Month[1].content..'/'..t.children.Day[1].content);
	else
		t.children.Year[1].content = tEpreuve:GetCell('Date_epreuve', 0, '%4Y');
		t.children.Month[1].content = tEpreuve:GetCell('Date_epreuve', 0, '%2M');
		t.children.Day[1].content = tEpreuve:GetCell('Date_epreuve', 0, '%2D');
	end
end

function afterType(t)
	-- on pourrais mettre une condition si ds homologation DT == 'oui' then t.content = 'Official'; else t.content = 'UnOfficial';
	if mode == "export" then
		t.content = 'Official';
	end
end

function beforeJury(t)
	if mode == 'import' then
		ordreJury = ordreJury or 0;
		ordreJury = ordreJury + 1;

		tEvenement_Officiel:GetRecord():SetNull(); 
		tEvenement_Officiel:GetRecord():Set({ Ordre = ordreJury, Label_Fonction = t.attributes.Function }); 
		tEvenement_Officiel:AddRow();
	else
		return base:TableLoad(tEvenement_Officiel, 
			"Select * From Evenement_Officiel"..
			" Where Code_evenement = "..Code_evenement..
			" Order By Ordre" );
	end
end

function afterJury(t)
	if mode == 'export' then 
		SetAttributes(t, 'Function', rEvenement_Officiel:GetString("Label_Fonction"));
	end
end

function beforeCC_ranked(t)
	if mode == 'import' then
		tResultat:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps > 0');
	end
end

function afterCC_ranked(t)
	if mode == 'import' then
		Code_coureur = tResultat:GetCell('Code_coureur', 0);
		for i=0, tResultat_Manche:GetNbRows()-1 do tResultat_Manche:SetCell('Code_coureur',i, Code_coureur) end
		for i=0, tResultat_Inter:GetNbRows()-1 do tResultat_Inter:SetCell('Code_coureur',i, Code_coureur) end
		tResultat_Copy:AddRow(tResultat); tResultat:RemoveAllRows();
		tResultat_Manche_Copy:AddRow(tResultat_Manche); tResultat_Manche:RemoveAllRows();
		tResultat_Inter_Copy:AddRow(tResultat_Inter); tResultat_Inter:RemoveAllRows();
	else
		SetAttributes(t, 'Status', 'QLF');
		SetAttributes(t, 'Status2', 'RAL');
	end
end

--------------------------- XML Description tables ---------------------------
Raceheader = { 
	attributes = { {name = 'Sector', value = 'CC'}, {name = 'Gender', value = 'M|W|A'}},
	children = {
		{ name = 'Season', field = 'Evenement.Code_saison' },
		{ name = 'Codex', field = 'Evenement.Codex' },
		{ name = 'Nation', field = 'Evenement.Code_nation' },
		{ name = 'Discipline', content = {'DI','SP','TE','Tsp','Mar'}, field = 'Discipline.Code_international' },
		{ name = 'Category', field = 'Epreuve.Code_regroupement' },
		{ name = 'Type', content = { 'Startlist', 'Partial' ,'Unofficial', 'Official' }, after = afterType },
		{ name = 'Eventname', field = 'Evenement.Nom', required = '0-1' },
		{ name = 'Place', field = 'Evenement.Station', required = '0-1' },
		{ name = 'RaceDate', children = { 
			{ name = 'Day', content = "integer" } ,
			{ name = 'Month', content = "integer" },
			{ name = 'Year', content = "integer" },
			}, after = afterRacedate
		},
		{ name = 'TempUnit', required = '0-1', after = function(t) t.content = 'C' end },
		{ name = 'LongUnit', required = '0-1', after = function(t) t.content = 'm' end },
		{ name = 'SpeedUnit', required = '0-1', after = function(t) t.content = 'Kmh' end },
		{ name = 'WindUnit', required = '0-1', after = function(t) t.content = 'Kmh' end },
		{ name = 'CC_photof', required = '0-1' },
	
		{ name = 'FFS_Entite', field = 'Evenement.Code_entite', required = '0-1', export = tags_ffs },
		{ name = 'FFS_GrilleCategorie', field = 'Epreuve.Code_grille_categorie', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Categorie', field = 'Epreuve.Code_categorie', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Niveau', field = 'Epreuve.Code_niveau', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Regroupement', field = 'Epreuve.Code_regroupement', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Liste_Support', field = 'Evenement.Code_liste', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Homologation_Date', field = 'Epreuve.Date_calendrier', required = '0-1', export = tags_ffs },
	},
	after = afterRaceheader
};

Competitor = {
	children = {
		{ name = 'FisCode', content = contentFisCode, field = 'Resultat.Code_coureur' },
		{ name = 'Lastname', field = 'Resultat.Nom' },
		{ name = 'Firstname', field = 'Resultat.Prenom' },
		{ name = 'Gender', content = {'M', 'F'} , field = 'Resultat.Sexe', required = '0-1' },	-- >= 2.10
		{ name = 'Sex', before = beforeSex, field = 'Resultat.Sexe', required = '0-1', export = false },-- 2.1 Compatibility
		{ name = 'Nation', field = 'Resultat.Nation' },
		{ name = 'YearOfBirth', field = 'Resultat.An' },
		{ name = 'ClubName', field = 'Resultat.Club', required = '0-1' },
		
		{ name = 'FFS_Code_coureur', field = 'Resultat.Code_coureur', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Comite', field = 'Resultat.Comite', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Groupe', field = 'Resultat.Groupe', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Equipe', field = 'Resultat.Equipe', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Critere', field = 'Resultat.Critere', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Distance', field = 'Resultat.Distance', required = '0-1', export = tags_ffs }
	}
};

CC_result_classified = {
	children = {
		{ name = 'Starttime', required = '0-1' },
		{ name = 'Timediff', required = '0-1' },
		{ name = 'TotalTime', field = 'Resultat.Tps_chrono' },
		{ name = 'Diff', field = 'Resultat.Diff', required = '0-1' },
		{ name = 'RacePoints', field = 'Resultat.Pts' },
		{ name = 'Bonustime', required = '0-1' },
		{ name = 'Bonuscuppoints', required = '0-1' },
		{ name = 'Penaltytime', required = '0-1' },
		{ name = 'Arrivalrank', required = '0-1' },
		{ name = 'Arrivaltime', required = '0-1' },
		{ name = 'Arrivaldiff', required = '0-1' },
		{ name = 'Level', content = 'string', required = '0-1' }
	}
};

CC_result_notclassified = {
	required = '0-1', children = {
		{ name = 'Level', content = {'final|smallfinal|semifinal|quarterfinal|eightfinal|qualification'}, required = '0-1' }
	}
};

CC_resultdetail = {
	required = '0-1', children = {
		{ name = 'Intermediate', required = '0-99', after = afterIntermediate, before = beforeIntermediate, 
			attributes = {{ name = 'i', type_value = 'integer', optional = true }},
			children = {
					{ name = 'Time', field = 'Resultat_Inter.Tps_chrono', required = '0-1' },
					{ name = 'Diff', field = 'Resultat_Inter.Diff', required = '0-1' },
					{ name = 'Rank', field = 'Resultat_Inter.Clt', required = '0-1' },
					{ name = 'SectorTime', content = 'string', required = '0-1' },
					{ name = 'SectorDiff', content = 'string', required = '0-1' },
					{ name = 'SectorRank', content = 'integer', required = '0-1' },
					{ name = 'Bonustime', content = 'string', required = '0-1' },
					{ name = 'Bonuspoints', content = 'decimal', required = '0-1' },
					{ name = 'Speed', content = 'string', required = '0-1' },
			}
		},
		{ name = 'Run', required = '0-99', before = beforeRun, 
			attributes = {
				{ name = 'No', type_value = 'integer' , optional = true}, 
				{ name = 'Level', value = 'final|smallfinal|semifinal|quarterfinal|eightfinal|qualification' },
				{ name = 'Status', value = 'RAL|DNS|DNF|DSQ' }
			}
			, children = {
				{ name = 'Rank', field = 'Resultat_Manche.Clt', required = '0-1' },
				{ name = 'Time', field = 'Resultat_Manche.Tps_chrono', required = '0-1' },
				{ name = 'Diff', field = 'Resultat_Manche.Diff', required = '0-1' }
			}
		}
	}
};

-- ************** debut suite verif ************************************

Course = {
	required = '0-1',
	children = {
		{ name = 'Name', content = 'string', required = '0-1' }, 
		{ name = 'HD', content = 'integer', required = '0-1' },
		{ name = 'MC', content = 'integer', required = '0-1' },
		{ name = 'TC', content = 'integer', required = '0-1' },
		{ name = 'Laplength', content = 'integer', required = '0-1' },
		{ name = 'Lapnumber', content = 'integer', field = 'Epreuve_Nordique.Nb_temps_inter', required = '0-1' },
		{ name = 'Intermediate', required = '0-99', 
			attributes = {{ name = 'i', type_value = 'integer' },{ name = 'type', value = 'time|speed' }},
			children = {
				{ name = 'Distance', content = 'string' }
			}
		}
	}
};

Weather = {
	required = '0-99', children = {
		{ name = 'Starttime', content = 'string' },
		{ name = 'Endtime', content = 'string', required = '0-1' },
		{ name = 'Place', content = 'string' },
		{ name = 'Weather', content = 'string' },
		{ name = 'Snow', required = '0-1' },
		{ name = 'TemperatureAir', required = '0-1' },
		{ name = 'TemperatureSnow', required = '0-1' },
		{ name = 'Humidity', required = '0-1' },
		{ name = 'Maxwindspeed', required = '0-1' },
		{ name = 'Minwindspeed', required = '0-1' },
		{ name = 'Avgwindspeed', required = '0-1' },
		{ name = 'Winddirection', content = {'N','NNW','NW','WNW','W','WSW','SW','SSW','S','SSE','SE','ESE','E','ENE','NE','NNE'}, required = '0-1' }
	}
};

StatCompetitorNation = {
	required = '0-1', children = {
		{ name = 'Competitors', content = 'integer' },
		{ name = 'Nations', content = 'integer' }
	}
};

Statistics = {
	required = '0-99', children = {
		{ name = 'Entries', props = StatCompetitorNation },
		{ name = 'Ranked', props = StatCompetitorNation },
		{ name = 'DSQ', props = StatCompetitorNation },
		{ name = 'DQB', props = StatCompetitorNation },
		{ name = 'DNS', props = StatCompetitorNation },
		{ name = 'DNF', props = StatCompetitorNation },
		{ name = 'LAP', props = StatCompetitorNation }
	}
};

CC_race = {
	children = { 
		{ name = 'CC_raceinfo', children = {
				{ name = 'Jury', required = '0-999', before = beforeJury, attributes = 
					{{ name = 'Function', value = 'CHIEFCOMPETITION|TECHNICALDELEGATE|RACEDIRECTOR|RACEDIRECTORASSISTANT|TECHNICALDELEGATEASSISTANT|TECHNICALDELEGATEASSISTANTNATIONAL|MEMBER'}},
					children = {
						{ name = 'Lastname', field = 'Evenement_Officiel.Nom' },
						{ name = 'Firstname', field = 'Evenement_Officiel.Prenom' },
						{ name = 'Nation', field = 'Evenement_Officiel.Nation' },
						
						{ name = 'FFS_Email', field = 'Evenement_Officiel.Email', required = '0-1', export = tags_ffs },
						{ name = 'FFS_Tel', field = 'Evenement_Officiel.Tel', required = '0-1', export = tags_ffs }
						
					}, after = afterJury
				},

				{ name = 'Runinfo', required = '0-3', before = beforeRuninfo, attributes = {{ name = 'No', type_value = 'integer'}}, 
					children = {
						{ name = 'Course', props = Course },
						{ name = 'StartTime', content = 'string' },
						{ name = 'EndTime', required = '0-1', content = 'string' },
						{ name = 'Weather', props = Weather },
						{ name = 'Statistics', props = Statistics },
					}, after = afterRuninfo
				},
				
				{ name = 'UsedFisList', field = 'Evenement.Code_liste', required = '0-1' },
				{ name = 'AppliedPenalty', field = 'Epreuve.Penalite_appliquee', required = '0-1' },
				{ name = 'CalculatedPenalty', field = 'Epreuve.Penalite_calculee', required = '0-1' },
				{ name = 'Fvalue', field = 'Epreuve.Facteur_f', required = '0-1' },
				{ name = 'TimingBy', content = 'string', required = '0-1' },  -- nom du chronometreur
				{ name = 'DataProcessingBy', content = 'string', required = '0-1' }, -- nom du gestionaire infor
				{ name = 'SoftwareCompany', content = 'string', required = '0-1' }, -- nom de la societe du logiciel
				{ name = 'SoftwareName', content = 'string', required = '0-1' }, -- nom du logiciel de chrono et notation
				{ name = 'SoftwareVersion', content = 'string', required ="0-1" }, -- version du logiciel
			}
		},
		{ name = 'CC_classified', children = {
				{ name = 'CC_ranked', required = '0-99999', before = beforeCC_ranked, 
						attributes = {{name = 'Status', value = 'QLF'},{ name = 'Status2', value = 'LAP|RAL'}}, -- 4	<Fisresults/CC_Race/CC_classified/CC_ranked> line 44 : Attribute Status2 is empty
						children = {
						{ name = 'Rank', field = 'Resultat.Clt', required = '0-1' },
						{ name = 'Order', field = 'Resultat.Rang', required = '0-1' },
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },
						{ name = 'Competitor', props = Competitor },
						{ name = 'CC_result', props = CC_result_classified },
						{ name = 'CC_resultdetail', props = CC_resultdetail }
					}, after = afterCC_ranked 
				}
			}
		},
		{ name = 'CC_notclassified', children = {
				{ name = 'CC_notranked', required = '0-99999', before = beforeCC_notranked,
					attributes = {{name = 'Status', value = 'DNS|DNF|DPO|DQB'}},
					children =
					{
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },
						{ name = 'Competitor', props = Competitor },
						{ name = 'CC_result', props = CC_result_notclassified },
						{ name = 'CC_resultdetail', props = CC_resultdetail },
						{ name = 'Reason', required = '0-1', content = 'string' },
						{ name = 'Level', required = '0-1', content = 'string' },
					},
					after = afterCC_notranked
				}
			}
		}
	}
};

-- Point d'entrée principale de la Grammaire XML 
xmlDescription = {
	name = 'Fisresults', 
	before = beforeFisresults,
	children = {
		{ name = 'XMLversion', content = 'string', required = '0-1', after = function(t) if mode == 'export' then t.Content = '3.4' end end },
		{ name = 'RaceHeader', props = Raceheader },
		{ name = 'CC_Race', props = CC_race }
	},
	after = afterFisresults
};
