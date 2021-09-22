-- FIS Alpine Data Exchange XML Protocol version 1 (FFS - VOLA SKIPRO - Compatibilité)
function beforeFisresults(t)
	base:SetGlobalVariable({'table', 'record'}); -- tName => table Name, rName => record Name
	base:SetBaseFormatChrono('ALP');
	
	if mode == 'import' then
		tEvenement:AddRow();
		
		rEpreuve:Set('Code_epreuve', 1);
		tEpreuve:AddRow();

		rEpreuve_Alpine:Set('Code_epreuve', 1);
		tEpreuve_Alpine:AddRow();
		
		rEpreuve_Alpine_Manche:Set('Code_epreuve', 1);
		rEpreuve_Alpine_Manche:Set('Code_manche', 1);
		tEpreuve_Alpine_Manche:AddRow();
		
		tPistes:AddRow();
	
		tResultat_Copy = tResultat:Copy(false, true);	--  parametre 1 : false = copie de la structure, true = copie de la structure et des rows. parametre 2 : true va dans le garbage collector
		tResultat_Manche_Copy = tResultat_Manche:Copy(false, true);
		tResultat_Inter_Copy = tResultat_Inter:Copy(false, true);
	end
end

function afterFisresults(t)
	xmlError = xmlError or {};
	if mode == 'import' then
		if #xmlError == 0 then
			-- Verification table Evenement - Mise de valeurs par défaut ...
			if tEvenement:IsCellNull('Code_activite', 0) then tEvenement:SetCell('Code_activite', 0, 'ALP') end
			if tEvenement:IsCellNull('Code_entite', 0) then tEvenement:SetCell('Code_entite', 0, 'FFS') end
			
			local codeEntite = tEvenement:GetCell('Code_entite', 0);
			
			-- Verification table Epreuve - Mise de valeurs par défaut ...
			if codeEntite == 'FIS' then
				if tEpreuve:IsCellNull('Code_grille_categorie', 0) then tEpreuve:SetCell('Code_grille_categorie', 0, 'FIS-ALP') end
				if tEpreuve:IsCellNull('Code_categorie', 0) then tEpreuve:SetCell('Code_categorie', 0, '*') end
			else
				if tEpreuve:IsCellNull('Code_grille_categorie', 0) then tEpreuve:SetCell('Code_grille_categorie', 0, 'FFS-ALP') end
				if tEpreuve:IsCellNull('Code_categorie', 0) then tEpreuve:SetCell('Code_categorie', 0, '*') end
			end

			-- Prise du Matricule Piste ..
			local homologation = tPistes:GetCell('Homologation_fis', 0);
			if string.len(homologation) > 0 and tEpreuve_Alpine_Manche:GetNbRows() > 0 then
				if codeEntite == 'FIS' then
					base:TableLoad(tPistes, "Select * From Pistes Where Code_activite = 'ALP' And Homologation_fis = '"..homologation.."'");
				else
					base:TableLoad(tPistes, "Select * From Pistes Where Code_activite = 'ALP' And Homologation_ffs = '"..homologation.."'");
					if tPistes:GetNbRows() == 0 then	
						-- tentative avec le code FIS
						base:TableLoad(tPistes, "Select * From Pistes Where Code_activite = 'ALP' And Homologation_fis = '"..homologation.."'");
					end
				end
				if tPistes:GetNbRows() > 0 then
					tEpreuve_Alpine_Manche:SetCell("Code_piste", 0, tPistes:GetCell('Matricule', 0));
				end
			end

			-- Transfert Final tables Resultats ...
			tResultat:RemoveAllRows(); tResultat:AddRow(tResultat_Copy);
			tResultat_Manche:RemoveAllRows(); tResultat_Manche:AddRow(tResultat_Manche_Copy);
			tResultat_Inter:RemoveAllRows(); tResultat_Inter:AddRow(tResultat_Inter_Copy);
			base:InsertBaseEvenement();
		end
	end
end

function beforeRaceheader(t)
	if mode == 'import' then
		if t.attributes.FFS_Entite ~= nil then
			tEvenement:SetCell('Code_entite', 0, t.attributes.FFS_Entite);
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
			tEpreuve:SetCell('Code_gestion', 0, etatEpreuve.Course);
		end
	else
		SetAttributes(t, 'Sector', 'AL');
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

function beforeAL_ranked(t)
	if mode == 'import' then
		tResultat:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps > 0');
	end
end

function afterAL_ranked(t)
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

function beforeAL_notranked(t)
	if mode == 'import' then
		tResultat:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps < 0');
	end
end

function afterAL_notranked(t)
	if mode == 'import' then
		Code_coureur = tResultat:GetCell('Code_coureur', 0);
		for i=0, tResultat_Manche:GetNbRows()-1 do tResultat_Manche:SetCell('Code_coureur',i, Code_coureur) end
		for i=0, tResultat_Inter:GetNbRows()-1 do tResultat_Inter:SetCell('Code_coureur',i, Code_coureur) end
		tResultat_Copy:AddRow(tResultat); tResultat:RemoveAllRows();
		tResultat_Manche_Copy:AddRow(tResultat_Manche); tResultat_Manche:RemoveAllRows();
		tResultat_Inter_Copy:AddRow(tResultat_Inter); tResultat_Inter:RemoveAllRows();
	else
		SetAttributes(t, 'Status', ranking.CodeInter(rResultat:GetInt('Tps')));
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
	else
		return base:TableLoad(tResultat_Manche, 
			"Select * From Resultat_Manche"..
			" Where Code_evenement = "..Code_evenement..
			" And Code_manche = "..manche..
			" And Code_coureur = '"..rResultat:GetString('Code_coureur').."'" 
		);
	end
end

function beforeCourse(t) 
	if mode == 'import' then 
		Code_manche = tonumber(t.attributes.run);

		while tEpreuve_Alpine_Manche:GetNbRows() < Code_manche do 
			tEpreuve_Alpine_Manche:GetRecord():SetNull(); 
			rEpreuve_Alpine_Manche:Set("Code_manche", tEpreuve_Alpine_Manche:GetNbRows()+1);
			tEpreuve_Alpine_Manche:AddRow();
		end
		rowEpreuve_Alpine_Manche = Code_manche-1;

		if tEpreuve:GetCellInt('Nombre_de_manche', 0, -1) <= Code_manche then
			tEpreuve:SetCell('Nombre_de_manche', 0, Code_manche);
		end
	else
		return base:TableLoad(tEpreuve_Alpine_Manche, 
			"Select * From Epreuve_Alpine_Manche"..
			" Where Code_evenement = "..Code_evenement..
			" And Code_manche >= 1 "..
			" Order By Code_manche ");
	end 
end

function afterCourse(t) 
	if mode == 'export' then
		SetAttributes(t, 'run', rEpreuve_Alpine_Manche:GetString('Code_manche'));
	end
end

function beforeFFS_Ouvreur(t)
	if mode == 'import' then
		ordreOuvreur = ordreOuvreur or 0;
		ordreOuvreur = ordreOuvreur +1;
	
		tEpreuve_Alpine_Manche_Ouvreur:GetRecord():SetNull(); 
		tEpreuve_Alpine_Manche_Ouvreur:GetRecord():Set({ Code_manche = Code_manche, Code = ordreOuvreur }); 
		tEpreuve_Alpine_Manche_Ouvreur:AddRow();
	else
		return base:TableLoad(tEpreuve_Alpine_Manche_Ouvreur, 
			"Select * From Epreuve_Alpine_Manche_Ouvreur"..
			" Where Code_evenement = "..Code_evenement..
			" And Code_manche = "..rEpreuve_Alpine_Manche:GetString('Code_manche')..
			" And Tps > 0 "..
			" Order By Code" );
	end
end

function afterForerunner(t)
	if mode == 'export' then
		SetAttributes(t, 'Order', rEpreuve_Alpine_Manche_Ouvreur:GetString("Code"));
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
				FFS_DIRECTEUR_EPREUVE = 'ChiefRace',
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

function beforeFFS_Code(t)
	if mode == 'import' then 
		if t.content then
			if not string.find(t.content, 'FFS') then
				t.content = 'FFS'..t.content;
			end
		end
	end
end

function contentFisCode(t) 
	if mode == 'import' then 
		if t.attributes ~= nil and t.attributes.FFS_Origine ~= nil then
			return t.attributes.FFS_Origine..t.content;
		elseif string.len(tEvenement:GetCell('Code_entite', 0)) == 3 then 
			return tEvenement:GetCell('Code_entite', 0)..t.content; 
		else
			return 'FIS'..t.content; 
		end
	else 
		return t.content:sub(4);
	end 
end

function beforeSex(t)
	if mode == "import" then
		if t.attributes.Sex == 'M' then
			t.content = 'M';
		else
			t.content = 'F'; -- W, L ou F
		end
	end
end

function afterType(t)
	if mode == "export" then
		t.content = 'Official';
	end
end

--------------------------- XML Description tables ---------------------------
Raceheader = { 
	before = beforeRaceheader,
	
	attributes = { 
		{name = 'Sector', value = 'AL'}, 
		{name = 'Sex', value = 'M|L'}, 	-- M=Men, L=Ladies
		{name = 'FFS_Entite', value = 'FFS|FIS', optional = true},
		{name = 'FFS_Homologation', value = 'OUI|NON', optional = true}
	},
	children = {
		{ name = 'Season', field = 'Evenement.Code_saison' },
		{ name = 'Codex', field = 'Epreuve.Fichier_transfert' },
		{ name = 'Nation', field = 'Evenement.Code_nation' },
		{ name = 'Discipline', content = { 'DH','SL','GS','SG','AC','TE','KOS','KOG','PGS','PSL','CE','IND','P','CAR' }, field = 'Epreuve.Code_discipline' },
		{ name = 'Category', field = 'Epreuve.Code_regroupement' },
		{ name = 'Type', content = { 'Startlist', 'Partial' ,'Unofficial', 'Official', 'Offical' }, after = afterType }, -- Bug Vola 'Offical' ...
		{ name = 'Training', required = '0-1', content = 'string' },
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
		{ name = 'SpeedUnit', required = '0-1', after = function(t) t.content = 'Km/h' end },
		{ name = 'WindUnit', required = '0-1', after = function(t) t.content = 'Km/h' end },
		
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
		{ name = 'FisCode', content = contentFisCode , attributes = {{ name = 'FFS_Origine', type_value = 'string', optional=true }}, field = 'Resultat.Code_coureur' },
		
		{ name = 'Lastname', field = 'Resultat.Nom' },
		{ name = 'Firstname', field = 'Resultat.Prenom' },
		{ name = 'Gender', content = {'M', 'F'} , field = 'Resultat.Sexe', required = '0-1' },	-- >= 2.10
		{ name = 'Sex', before = beforeSex, field = 'Resultat.Sexe', required = '0-1', export = false },-- 2.1 Compatibility
		{ name = 'Nation', field = 'Resultat.Nation' },
		{ name = 'YearOfBirth', field = 'Resultat.An' },
		{ name = 'ClubName', field = 'Resultat.Club', required = '0-1' },
		
		{ name = 'FFS_Code_coureur', field = 'Resultat.Code_coureur', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Club', field = 'Resultat.Club', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Comite', field = 'Resultat.Comite', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Groupe', field = 'Resultat.Groupe', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Equipe', field = 'Resultat.Equipe', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Critere', field = 'Resultat.Critere', required = '0-1', export = tags_ffs }
	}
};

AL_result_classified = {
	children = {
		{ name = 'TimeRun1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono' , required = '0-1'},
		{ name = 'TimeRun2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono' , required = '0-1' },
		{ name = 'TimeRun3', before = synchroResultatManche, arg = 3, field = 'Resultat_Manche.Tps_chrono' , required = '0-1' },
		
		{ name = 'TotalTime', field = 'Resultat.Tps_chrono' },
		{ name = 'Diff', field = 'Resultat.Diff', required = '0-1' },
		{ name = 'RacePoints', field = 'Resultat.Pts' , required = '0-1' },
		{ name = 'Level', content = 'string', required = '0-1' },
		
		{ name = 'FFS_Timerun1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono', required = '0-1' },
		{ name = 'FFS_Timerun2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono', required = '0-1' }
	}
};

Course = {
	required = '0-3',
	attributes = { {name='run', type_value = 'integer'} },
	before = beforeCourse,
	
	children = {
		{ name = 'Name', required = '0-1' },
		{ name = 'Homologation', field = 'Pistes.Homologation_fis' },
		{ name = 'Length', required = '0-1', field = 'Epreuve_Alpine_Manche.Longueur' },
		{ name = 'Gates', field = 'Epreuve_Alpine_Manche.Nombre_de_portes' },
		{ name = 'TurningGates', field = 'Epreuve_Alpine_Manche.Changement_de_directions' },
		{ name = 'StartElev', required = '0-1', field = 'Epreuve_Alpine_Manche.Altitude_Depart' },
		{ name = 'FinishElev', required = '0-1', field = 'Epreuve_Alpine_Manche.Altitude_Arrivee' },
		{ name = 'Starttime', required = '0-1', field = 'Epreuve_Alpine_Manche.Heure_depart' },

		{ name = 'FFS_Traceur', required = '0-99',
			children = {
				{ name = 'FFS_Traceur_Matric', field = 'Epreuve_Alpine_Manche.Matricule_traceur', required = '0-1' },
				{ name = 'FFS_Traceur_Identite', field = 'Epreuve_Alpine_Manche.Nom_traceur', required = '0-1' },
				{ name = 'FFS_Traceur_Nation', field = 'Epreuve_Alpine_Manche.Code_nation_traceur', required = '0-1' },
			}
		},
	
		{ name = 'FFS_Ouvreur', required = '0-99', before = beforeFFS_Ouvreur,
			children = {
				{ name = 'FFS_Ouvreur_Identite', field = 'Epreuve_Alpine_Manche_Ouvreur.Nom', required = '0-1' },
				{ name = 'FFS_Ouvreur_Nom', field = 'Epreuve_Alpine_Manche_Ouvreur.Nom', required = '0-1' },
				{ name = 'FFS_Ouvreur_Prenom', field = 'Epreuve_Alpine_Manche_Ouvreur.Prenom', required = '0-1' },
				
				{ name = 'FFS_Ouvreur_Nation', field = 'Epreuve_Alpine_Manche_Ouvreur.Nation', required = '0-1' },
				{ name = 'FFS_Ouvreur_Matric', field = 'Epreuve_Alpine_Manche_Ouvreur.Matric', required = '0-1'}, 
			}, after = afterForerunner
		}
	}
};
	
AL_race = {
	children = { 
		{ name = 'AL_raceinfo', children = {
				{ name = 'UsedFisList', content = 'string', required = '0-1' },
				{ name = 'AppliedPenalty', field = 'Epreuve.Penalite_appliquee', required = '0-1' },
				{ name = 'CalculatedPenalty', field = 'Epreuve.Penalite_calculee', required = '0-1' },
				{ name = 'Fvalue', field = 'Epreuve.Facteur_f', required = '0-1' },
				
				{ name = 'FFS_Alt_depart', required = '0-1' },	-- Ignoré => prise en compte balise StartElev
				{ name = 'FFS_Alt_arrivee', required = '0-1' },	-- Ignoré => prise en compte balise Finishelev
				
				{ name = 'Snow', field = 'Epreuve_Alpine_Manche.Neige_course', required = '0-1' },
				{ name = 'Weather', field = 'Epreuve_Alpine_Manche.Meteo_course', required = '0-1' },
				{ name = 'Temperatureatstart', field = 'Epreuve_Alpine_Manche.Temperature_air_depart', required = '0-1' },
				{ name = 'Temperatureatfinish', field = 'Epreuve_Alpine_Manche.Temperature_air_arrivee', required = '0-1' },
				
				{ name = 'TimingBy', required = '0-1' },
				{ name = 'DataProcessingBy', content = 'string', required = '0-1' },
				{ name = 'SoftwareCompany', content = 'string', required = '0-1' },
				{ name = 'SoftwareName', content = 'string', required = '0-1' },
				{ name = 'Version', content = 'string', required ="0-1" },
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

		{ name = 'FFS_Officiel', required = '0-99', before = beforeFFS_Officiel,
			attributes = { 
				{ name='FFS_Fonction' , value='FFS_DT|FFS_DT_ADJOINT|FFS_DIRECTEUR_EPREUVE|FFS_ARBITRE|FFS_ARBITRE_ASSISTANT|FFS_CHEF_PISTE|FFS_JUGE_DEPART|FFS_JUGE_ARRIVEE|FFS_CHRONOMETREUR'} ,
			},
			children = {
				{ name = 'FFS_Identite', field = 'Evenement_Officiel.Nom' },
				{ name = 'FFS_Code', before = beforeFFS_Code, field = 'Evenement_Officiel.Code_coureur', export = false },
				{ name = 'FFS_Nation', field = 'Evenement_Officiel.Nation' }
			}
		},
		
		{ name = 'Course', props = Course },
		
		{ name = 'AL_classified', children = {
				{ name = 'AL_ranked', required = '0-99999', before = beforeAL_ranked,  attributes = {{name ='Status', value = 'QLF'}}, children = {
						{ name = 'Rank', field = 'Resultat.Clt', required = '0-1' },	-- 2.10
						{ name = 'Order', field = 'Resultat.Rang', required = '0-1' },	-- 2.10
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },	-- 2.10
						{ name = 'Competitor', props = Competitor },
						{ name = 'AL_result', props = AL_result_classified },
					}, after = afterAL_ranked 
				}
			}
		},
		{ name = 'AL_notclassified', children = {
				{ name = 'AL_notranked', required = '0-99999', before = beforeAL_notranked,
					attributes = {{name = 'Status', value = 'DNS|DNS1|DNS2|DSQ|DSQ1|DSQ2|DNF|DNF1|DNF2|DNQ|DNQ1|DPO|NPS|DQB|DQO'}},
					children =
					{
						{ name = 'Run', content = "integer" },
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },	-- 2.10 
						{ name = 'Competitor', props = Competitor },
						{ name = 'Gate', content = "integer", required = '0-1' },

						{ name = 'TimeRun1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono' , required = '0-1' },
						{ name = 'TimeRun2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono' , required = '0-1' },
						{ name = 'TimeRun3', before = synchroResultatManche, arg = 3, field = 'Resultat_Manche.Tps_chrono' , required = '0-1' },
						{ name = 'TotalTime', field = 'Resultat.Tps_chrono', required = '0-1' },
						{ name = 'Diff', field = 'Resultat.Diff', required = '0-1' },
						{ name = 'RacePoints', content = 'decimal', required = '0-1' },
						{ name = 'Level', content = 'string', required = '0-1' },
						
						{ name = 'FFS_Timerun1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono', required = '0-1' },
						{ name = 'FFS_Timerun2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono', required = '0-1' }
					},
					after = afterAL_notranked
				}
			}
		}
	}
};

-- Point d'entrée principale de la Grammaire XML 
xmlDescription = {
	name = 'Fisresults', 
	before = beforeFisresults,
	attributes = { { name = 'Version', type_value = "string", optional = true }},
	children = {
		{ name = 'RaceHeader', props = Raceheader },
		{ name = 'AL_Race', props = AL_race }
	},
	after = "afterFisresults"
};
