-- Biathlon Data Exchange XML Protocol 

function beforeFisresults(t)
	base:SetGlobalVariable({'table', 'record'}); -- tName => table Name, rName => record Name
	base:SetBaseFormatChrono('BIATH');
	
	if mode == 'import' then
		tEvenement:AddRow();
		
		rEpreuve:Set('Code_epreuve', 1);
		rEpreuve:Set('Nombre_de_manche', 1);
		tEpreuve:AddRow();

		rEpreuve_Nordique:Set('Code_epreuve', 1);
		tEpreuve_Nordique:AddRow();
		
		tResultat_Copy = tResultat:Copy(false, true);
		tResultat_Manche_Copy = tResultat_Manche:Copy(false, true);
		tResultat_Inter_Copy = tResultat_Inter:Copy(false, true);
	end
end

function afterFisresults(t)
	xmlError = xmlError or {};
	if mode == 'import' then
		if #xmlError == 0 then
			-- Verification table Evenement - Mise de valeurs par défaut ...
			if tEvenement:IsCellNull('Code_activite', 0) then tEvenement:SetCell('Code_activite', 0, 'BIATH') end
			if tEvenement:IsCellNull('Code_entite', 0) then tEvenement:SetCell('Code_entite', 0, 'FFS') end
			
			-- Verification table Epreuve - Mise de valeurs par défaut ...
			if tEpreuve:IsCellNull('Code_grille_categorie', 0) then tEpreuve:SetCell('Code_grille_categorie', 0, 'FFS-BIAT') end
			if tEpreuve:IsCellNull('Code_categorie', 0) then tEpreuve:SetCell('Code_categorie', 0, '*') end

			-- Ajout Code ' . ' pour faire gestion VOLA ou SKIFFS 
			tEpreuve:SetCell('Tir', 0, tEpreuve:GetCell('Tir',0)..' . ');

			-- Transfert Final des tables Resultats ...
			tResultat:RemoveAllRows(); tResultat:AddRow(tResultat_Copy);
			tResultat_Manche:RemoveAllRows(); tResultat_Manche:AddRow(tResultat_Manche_Copy);
			tResultat_Inter:RemoveAllRows(); tResultat_Inter:AddRow(tResultat_Inter_Copy);
			base:InsertBaseEvenement();
		end
	end
end

function afterRaceheader(t)
	if mode == 'import' then
		-- Sexe
		if t.attributes.Sex == 'L' or t.attributes.Sex == 'F' then tEpreuve:SetCell('Sexe', 0, 'F');
		elseif t.attributes.Sex == 'A' then tEpreuve:SetCell('Sexe', 0, 'T');
		else tEpreuve:SetCell('Sexe', 0, 'M');
		end

		-- Homologation
		if t.attributes.FFS_Homologation == 'OUI' then
			tEpreuve:SetCell('Codex_obligatoire', 0, 'O');
			tEpreuve:SetCell('Code_gestion', 0, etatEpreuve.Homologation);
		else
			tEpreuve:SetCell('Codex_obligatoire', 0, 'N');
			tEpreuve:SetCell('Code_gestion', 0, etatEpreuve.Course);
		end
	else
		SetAttributes(t, 'Sector', 'BH');
		if tEpreuve:GetCell('Sexe', 0) == 'F' then t.attributes.Sex = 'F';
		elseif tEpreuve:GetCell('Sexe', 0) == 'T' then t.attributes.Sex = 'A';
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

function beforeBH_ranked(t)
	if mode == 'import' then
		tResultat:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps > 0');
	end
end

function beforeBH_notranked(t)
	if mode == 'import' then
		tResultat:AddRow();
	
		local status = t.attributes.Status or 'DNS';
		rResultat_Manche:Set('Tps_chrono', status); 
		tResultat_Manche:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps <= 0');
	end
end

function afterBH_ranked(t)
	if mode == 'import' then
		Code_coureur = tResultat:GetCell('Code_coureur', 0);
		for i=0, tResultat_Manche:GetNbRows()-1 do tResultat_Manche:SetCell('Code_coureur',i, Code_coureur) end
		for i=0, tResultat_Inter:GetNbRows()-1 do tResultat_Inter:SetCell('Code_coureur',i, Code_coureur) end
		tResultat_Copy:AddRow(tResultat); tResultat:RemoveAllRows();
		tResultat_Manche_Copy:AddRow(tResultat_Manche); tResultat_Manche:RemoveAllRows();
		tResultat_Inter_Copy:AddRow(tResultat_Inter); tResultat_Inter:RemoveAllRows();
	else
		SetAttributes(t, 'Status', 'QLF');
	end
end

function afterBH_notranked(t)
	if mode == 'import' then
		Code_coureur = tResultat:GetCell('Code_coureur', 0);
		for i=0, tResultat_Manche:GetNbRows()-1 do tResultat_Manche:SetCell('Code_coureur',i, Code_coureur) end
		for i=0, tResultat_Inter:GetNbRows()-1 do tResultat_Inter:SetCell('Code_coureur',i, Code_coureur) end
		tResultat_Copy:AddRow(tResultat); tResultat:RemoveAllRows();
		tResultat_Manche_Copy:AddRow(tResultat_Manche); tResultat_Manche:RemoveAllRows();
		tResultat_Inter_Copy:AddRow(tResultat_Inter); tResultat_Inter:RemoveAllRows();
	end
end

function synchroResultatManche(t, manche)
	if mode == 'import' then
		while tResultat_Manche:GetNbRows() < manche do 
			rResultat_Manche:SetNull(); 
			rResultat_Manche:Set("Code_manche", tResultat_Manche:GetNbRows()+1);
			rResultat_Manche:Set("Code_coureur", tResultat:GetCell('Code_coureur',0));
			tResultat_Manche:AddRow();
		end
		rowResultat_Manche = manche-1;
		
		if tEpreuve:GetCellInt('Nombre_de_manche', 0, -1) < manche then
			tEpreuve:SetCell('Nombre_de_manche', 0, manche);
		end
		
	else
		return base:TableLoad(tResultat_Manche, 
			"Select * From Resultat_Manche"..
			" Where Code_evenement = "..Code_evenement..
			" And Code_manche = "..manche..
			" And Code_coureur = '"..rResultat:GetString('Code_coureur').."'" ..
			" And Tps_chrono > 0 ");
	end
end

function beforeFFS_Officiel(t)
	if mode == 'import' then
		ordreJury = ordreJury or 0;
		ordreJury = ordreJury + 1;
		
		if tCorrespondanceFonction == nil then
			tCorrespondanceFonction = { 
				FFS_DT = 'TechnicalDelegate',
				FFS_DT_ADJOINT = 'TechnicalDelegateAssistant',
				FFS_DIRECTEUR_EPREUVE = 'RaceDirector',
				FFS_ARBITRE = 'Referee',
				FFS_ARBITRE_ASSISTANT = 'AssistantReferee',
				FFS_CHEF_PISTE = 'ChiefCourse',
				FFS_JUGE_DEPART = 'StartReferee',
				FFS_JUGE_ARRIVEE = 'FinishReferee',
				FFS_CHRONOMETREUR = 'TimingBy'
			};
		end
		
		local codeFonction = t.attributes.FFS_Fonction;
		local codeFonction = tCorrespondanceFonction[codeFonction] or codeFonction;

		tEvenement_Officiel:GetRecord():SetNull(); 
		tEvenement_Officiel:GetRecord():Set({ Ordre = ordreJury, Fonction = codeFonction }); 
		tEvenement_Officiel:AddRow();
	else
		return base:TableLoad(tEvenement_Officiel, 
			"Select * From Evenement_Officiel"..
			" Where Code_evenement = "..Code_evenement..
			" Order By Ordre" );
	end
end

function beforeSex(t)
	if mode == "import" then
		if t.attributes.Sex == 'M' then
			t.content = 'M';
		elseif t.attributes.Sex == 'F' or t.attributes.Sex == 'W' or t.attributes.Sex == 'L' then
			t.content = 'F'; -- W, L ou F
		else
			MessageWarning('Competitor Balise Sex ?'.. t.attributes.Sex);
			t.content = 'M';
		end
	end
end

function contentFisCode(t) 
	if mode == 'import' then 
		local contentValue = t.content or '';
		if contentValue:len() == 0 then	
			MessageWarning("Présence d'une Balise <FisCode> Vide !!!");
		end
		if t.attributes ~= nil and t.attributes.FFS_Origine ~= nil then
			return t.attributes.FFS_Origine..contentValue;
		else
			return 'FFS'..contentValue; 
		end
	else 
		return t.content:sub(4);
	end 
end

--------------------------- XML Description tables ---------------------------
Raceheader = { 
	attributes = { 
		{name = 'Sector', value = 'BH'}, 
		{name = 'Sex', value = 'M|F|L'},
		{name = 'FFS_Homologation', value = 'OUI|NON' },
		{name = 'FFS_Entite', value = 'FFS|IBU' },

	}, children = {
		{ name = 'Season', field = 'Evenement.Code_saison' },
		{ name = 'Codex', field = 'Epreuve.Fichier_transfert' },
		{ name = 'Nation', field = 'Evenement.Code_nation', maxlen = 3 },
		{ name = 'Discipline', content = {'IND','SPR','POURS','MASS','SPR-QLF','SUP-SPR','IND-COUR','SPR-COUR', 'TIR' }, field = 'Epreuve.Code_discipline' },
		
		{ name = 'Category', field = 'Epreuve.Code_regroupement' },
		{ name = 'Type', content = { 'Startlist', 'Partial', 'Unofficial', 'Official', 'Offical' }, after = afterType },	-- Bug Vola 'Offical' ...
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
		
		{ name = 'FFS_Club', field = 'Evenement.Club', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Comite', field = 'Evenement.Code_comite', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Organisateur', field = 'Evenement.Organisateur', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Commentaire', field = 'Evenement.Commentaire', required = '0-1', export = tags_ffs },
		
		{ name = 'FFS_Entite', field = 'Evenement.Code_entite', required = '0-1', export = tags_ffs },
		{ name = 'FFS_GrilleCategorie', field = 'Epreuve.Code_grille_categorie', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Categorie', field = 'Epreuve.Code_categorie', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Niveau', field = 'Epreuve.Code_niveau', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Regroupement', field = 'Epreuve.Code_regroupement', required = '0-1', export = tags_ffs },
		
		{ name = 'FFS_Liste_Support', field = 'Evenement.Code_liste', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Homologation_Date', field = 'Epreuve.Date_calendrier', required = '0-1', export = tags_ffs },

		{ name = 'FFS_Homologation_Commentaire', content = 'string' , required = '0-1', export = tags_ffs },
		{ name = 'FFS_Homologation_Date_transmission', content = 'string' , required = '0-1', export = tags_ffs },
		{ name = 'FFS_Homologation_Heure_transmission', content = 'string' , required = '0-1', export = tags_ffs },
		{ name = 'FFS_Homologation_Qualite_transmetteur', content = 'string' , required = '0-1', export = tags_ffs },

		{ name = 'FFS_Logiciel', content = 'string' , required = '0-1', export = tags_ffs },

		{ name = 'TD', required = '0-2', children = {	-- Ignoré au profit de FFS_Officiel
			{ name = 'Tdnumber', content = "string", required = '0-1' } ,
			{ name = 'Tdlastname', content = "string", required = '0-1' } ,
			{ name = 'Tdfirstname', content = "string", required = '0-1' } ,
			{ name = 'Tdnation', content = "string", required = '0-1' } ,
		}},
	},
	after = afterRaceheader
};

Competitor = {
	children = {
		{ name = 'FisCode', content = contentFisCode, attributes = {{ name = 'FFS_Origine', type_value = 'string' }}, field = 'Resultat.Code_coureur' },
		
		{ name = 'Lastname', field = 'Resultat.Nom' },
		{ name = 'Firstname', field = 'Resultat.Prenom' },
		{ name = 'Sex', before = beforeSex, field = 'Resultat.Sexe', required = '0-1' },
		{ name = 'Nation', field = 'Resultat.Nation' , required='0-1' },
		{ name = 'YearOfBirth', field = 'Resultat.An', required='0-1' },
		{ name = 'ClubName', field = 'Resultat.Club', required = '0-1' },
		
		{ name = 'FFS_Code_coureur', field = 'Resultat.Code_coureur', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Club', field = 'Resultat.Club', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Comite', field = 'Resultat.Comite', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Groupe', field = 'Resultat.Groupe', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Equipe', field = 'Resultat.Equipe', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Critere', field = 'Resultat.Critere', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Distance', field = 'Resultat.Distance', required = '0-1', export = tags_ffs }
	}
};

BH_result_classified = {
	children = {
		{ name = 'Starttime', required = '0-1' },
		{ name = 'Timediff', required = '0-1' },
		{ name = 'TotalTime', field = 'Resultat.Tps_chrono' },
		{ name = 'Diff', field = 'Resultat.Diff', required = '0-1' },
		{ name = 'RacePoints', field = 'Resultat.Pts' },
		{ name = 'Bonuscuppoints', required = '0-1' },
		{ name = 'Arrivalrank', required = '0-1' },
		{ name = 'Arrivaltime', required = '0-1' },
		{ name = 'Arrivaldiff', required = '0-1' },
		{ name = 'Level', content = 'string', required = '0-1' },
		
		{ name = 'Bonustime', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_bonus', required = '0-1' },
		{ name = 'Penaltytime', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_penalite', required = '0-1' },
		
		{ name = 'TimeRun1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps' , required = '0-1'},
		{ name = 'TimeRun2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps' , required = '0-1' },
		
		{ name = 'FFS_Chrono1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono', required = '0-1' },
		{ name = 'FFS_Chrono2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono', required = '0-1' },

		{ name = 'FFS_Penalite1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Penalite', required = '0-1' },
		{ name = 'FFS_Penalite2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Penalite', required = '0-1' },
		
		{ name = 'FFS_TimeRun1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps', required = '0-1' },
		{ name = 'FFS_TimeRun2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps', required = '0-1' },
	}
};

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

StatCompetitorNation = {
	required = '0-1', children = {
		{ name = 'Competitors', content = 'integer' },
		{ name = 'Nations', content = 'integer' }
	}
};

BH_race = {
	children = { 
		{ name = 'BH_raceinfo', children = {
				{ name = 'Runinfo', required = '0-3', before = beforeRuninfo, attributes = {{ name = 'No', type_value = 'integer'}}, 
					children = {
						{ name = 'Course', props = Course },
						{ name = 'StartTime', content = 'string' },
						{ name = 'EndTime', required = '0-1', content = 'string' },
					}, after = afterRuninfo
				},
				
				{ name = 'FFS_Officiel', required = '0-99', before = beforeFFS_Officiel,
					attributes = { 
						{ name='FFS_Fonction' , value='FFS_DT|FFS_DT_ADJOINT|FFS_DIRECTEUR_EPREUVE|FFS_ARBITRE|FFS_ARBITRE_ASSISTANT|FFS_CHEF_PISTE|FFS_JUGE_DEPART|FFS_JUGE_ARRIVEE|FFS_CHRONOMETREUR'} ,
					},
					children = {
						{ name = 'FFS_Identite', field = 'Evenement_Officiel.Nom' },
						{ name = 'FFS_Code', field = 'Evenement_Officiel.Code_coureur' },
						{ name = 'FFS_Nation', field = 'Evenement_Officiel.Nation' }
					}
				},
				
				{ name = 'Course', props = Course },
				
				{ name = 'Weather', required = '0-1',
					children = {
						{ name = 'Weather', field = 'Epreuve_Nordique.Meteo' },
						{ name = 'Snow', field = 'Epreuve_Nordique.Info' },
						{ name = 'Temperatureair', field = 'Epreuve_Nordique.Temperature_air' },
						{ name = 'Temperaturesnow', field = 'Epreuve_Nordique.Temperature_neige' },
					}
				},
				
				{ name = 'UsedFisList', content = 'string', required = '0-1' },
				{ name = 'AppliedPenalty', field = 'Epreuve.Penalite_appliquee', required = '0-1' },
				{ name = 'CalculatedPenalty', field = 'Epreuve.Penalite_calculee', required = '0-1' },
				{ name = 'Fvalue', field = 'Epreuve.Facteur_f', required = '0-1' },

				{ name = 'FFS_Tir', field = 'Epreuve.Tir', required = '0-1' },
				{ name = 'FFS_Penalite_tir', field = 'Epreuve.Penalite_tir', required = '0-1' },
				{ name = 'FFS_Distance', field = 'Epreuve.Distance', required = '0-1' },
				{ name = 'FFS_Point_haut', field = 'Epreuve.Point_haut', required = '0-1' },
				{ name = 'FFS_Point_bas', field = 'Epreuve.Point_bas', required = '0-1' },
				{ name = 'FFS_Montee_tot', field = 'Epreuve.Montee_tot', required = '0-1' },
				{ name = 'FFS_Montee_maxi', field = 'Epreuve.Montee_maxi', required = '0-1' },
				
				{ name = 'TimingBy', content = 'string', required = '0-1' },  -- nom du chronometreur
				{ name = 'DataProcessingBy', content = 'string', required = '0-1' }, -- nom du gestionaire infor
				{ name = 'SoftwareCompany', content = 'string', required = '0-1' }, -- nom de la societe du logiciel
				{ name = 'SoftwareName', content = 'string', required = '0-1' }, -- nom du logiciel de chrono et notation
				{ name = 'SoftwareVersion', content = 'string', required ="0-1" }, -- version du logiciel
			}
		},
		
		{ name = 'Jury', required = '0-999', attributes = {
				{ name = 'Function', value = 'TechnicalDelegate|ChiefRace|Referee|AssistantReferee|ChiefCourse|StartReferee|FinishReferee|ChiefTiming'}
			},	children = {
				{ name = 'Jurylastname', required = '0-1', content = 'string' },
				{ name = 'Juryfirstname', required = '0-1', content = 'string' },
				{ name = 'Jurynation', required = '0-1', content = 'string' },
			}
		},
		
		{ name = 'BH_classified', children = {
				{ name = 'BH_ranked', required = '0-99999', before = beforeBH_ranked, 
						attributes = {{name = 'Status', value = 'QLF'}},
						children = {
						{ name = 'Rank', field = 'Resultat.Clt', required = '0-1' },
						{ name = 'Order', field = 'Resultat.Rang', required = '0-1' },
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },
						{ name = 'Competitor', props = Competitor },
						{ name = 'BH_result', props = BH_result_classified },
					}, after = afterBH_ranked 
				}
			}
		},
		{ name = 'BH_notclassified', children = {
				{ name = 'BH_notranked', required = '0-99999', before = beforeBH_notranked,
					attributes = {{name = 'Status', value = 'DNS|DNF|DSQ|DPO|DQB'}},
					children =
					{
						{ name = 'Run', field = 'Resultat_Manche.Code_manche' },
						{ name = 'Bib', field = 'Resultat.Dossard', required = '1' },
						{ name = 'Competitor', props = Competitor },
						{ name = 'Reason', required = '0-1', content = 'string' },
						{ name = 'Level', required = '0-1', content = 'string' },
						{ name = 'Gate', required = '0-1', content = 'string' },	-- Gate en Biathlon ? ...
					},
					after = afterBH_notranked
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
		{ name = 'XMLversion', content = 'string', required = '0-1' },
		{ name = 'RaceHeader', props = Raceheader },
		{ name = 'BH_Race', props = BH_race }
	},
	after = afterFisresults
};
