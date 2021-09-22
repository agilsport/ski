-- FIS Alpine Data Exchange XML Protocol version 2.11 => https://www.fis-ski.com/en/inside-fis/document-library/timing-data
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
		tDiscipline:AddRow();
		
		tResultat_Copy = tResultat:Copy(false, true);	--  parametre 1 : false = copie de la structure, true = copie de la structure et des rows. parametre 2 : true va dans le garbage collector
		tResultat_Manche_Copy = tResultat_Manche:Copy(false, true);
		tResultat_Inter_Copy = tResultat_Inter:Copy(false, true);
	else
		SetAttributes(t, 'Version', '2.11'); -- Version du XML
	end
end

function afterFisresults(t)
	xmlError = xmlError or {};
	if mode == 'import' then
		if #xmlError == 0 then
			-- Verification table Evenement - Mise de valeurs par défaut ...
			if tEvenement:IsCellNull('Code_activite', 0) then tEvenement:SetCell('Code_activite', 0, 'ALP') end
			if tEvenement:IsCellNull('Code_entite', 0) then tEvenement:SetCell('Code_entite', 0, 'FIS') end
			
			local codeEntite = tEvenement:GetCell('Code_entite', 0);
			if codeEntite == 'FIS' then
				local codex = tEvenement:GetCell('Codex', 0);
				if codex:len() == 4	then	
					-- FIS, ajout du code nation
					tEvenement:SetCell('Codex', 0, tEvenement:GetCell('Code_nation', 0)..codex);
				end
			end
			-- Verification table Epreuve - Mise de valeurs par défaut avec prise en compte des Master.
			local codeRegroupement = tEpreuve:GetCell('Code_regroupement', 0);
			if codeEntite == 'FIS' then
				if codeRegroupement == 'MAS' then tEpreuve:SetCell('Code_grille_categorie', 0, 'FIS-MAS') end
				if tEpreuve:IsCellNull('Code_grille_categorie', 0) then tEpreuve:SetCell('Code_grille_categorie', 0, 'FIS-ALP') end
				if tEpreuve:IsCellNull('Code_categorie', 0) then tEpreuve:SetCell('Code_categorie', 0, '*') end
			else
				if codeRegroupement == 'MAS' then tEpreuve:SetCell('Code_grille_categorie', 0, 'FFS-MA-A') end
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

function afterRaceheader(t)
	if mode == 'import' then
		-- Gender <=> Sexe 
		if t.attributes.Gender == 'W' then tEpreuve:SetCell('Sexe', 0, 'F');
		elseif t.attributes.Gender == 'A' then tEpreuve:SetCell('Sexe', 0, 'T');
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
		if tEpreuve:GetCell('Code_grille_categorie', 0):find('MAS') then 
			SetAttributes(t, 'Sector', 'MA') ;
		else
			SetAttributes(t, 'Sector', 'AL') ;
		end;
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

function beforeAL_ranked(t)
	if mode == 'import' then
		tResultat:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps > 0 Order By Tps, Dossard');
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
		
		local status = t.attributes.Status or 'DNS';
		rResultat_Manche:Set('Tps_chrono', status); 
		tResultat_Manche:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps < 0 Order By Dossard');
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
		-- Recherche du premier Temps KO (DNS, DNF, DSQ, ...)
		local cmd = 
			"Select * From Resultat_Manche"..
			" Where Code_evenement = "..Code_evenement..
			" And Code_coureur = '"..rResultat:GetString('Code_coureur').."'"..
			" And Tps_chrono < 0"..
			" Order By Code_manche"..
			" Limit 1"
		;
		base:TableLoad(tResultat_Manche, cmd);
		if tResultat_Manche:GetNbRows() > 0 then
			SetAttributes(t, 'Status', ranking.CodeInter(tResultat_Manche:GetCellInt('Tps_chrono',0))..tResultat_Manche:GetCellInt('Code_manche', 0));
		else
			SetAttributes(t, 'Status', "DNQ");
		end
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
			" And Code_coureur = '"..rResultat:GetString('Code_coureur').."'" ..
			" And Tps_chrono > 0 "	-- Uniquement les Temps OK ...
		);
	end
end

function beforeRuninfo(t) 
	if mode == 'import' then 
		Code_manche = tonumber(t.attributes.No);
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
		return tEpreuve_Alpine_Manche;
	end 
end

function afterRuninfo(t) 
	if mode == 'export' then
		SetAttributes(t, 'No', rEpreuve_Alpine_Manche:GetString('Code_manche'));
	end
end

function beforeRun(t) 
	if mode == 'import' then 
		if t.attributes.No == 'tot' then Code_manche = -1 else Code_manche = t.attributes.No end
	else
		return base:TableLoad(tEpreuve_Alpine_Manche, 
			"Select * From Epreuve_Alpine_Manche"..
			" Where Code_evenement = "..Code_evenement..
			" Order By Code_manche ");
	end 
end

function afterRun(t) 
	if mode == 'export' then
		SetAttributes(t, 'No', rEpreuve_Alpine_Manche:GetString('Code_manche'));
	end
end

function beforeForerunner(t)
	if mode == 'import' then
		tEpreuve_Alpine_Manche_Ouvreur:GetRecord():SetNull(); 
		tEpreuve_Alpine_Manche_Ouvreur:GetRecord():Set({ Code_manche = Code_manche, Code = t.attributes.Order }); 
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

function beforeJury(t)
	if mode == 'import' then
		ordreJury = ordreJury or 0;
		ordreJury = ordreJury + 1;

		tEvenement_Officiel:GetRecord():SetNull(); 
		tEvenement_Officiel:GetRecord():Set({ Ordre = ordreJury, Fonction = t.attributes.Function }); 
		tEvenement_Officiel:AddRow();
	else
		base:TableLoad(tEvenement_Officiel, 
			"Select * From Evenement_Officiel"..
			" Where Code_evenement = "..Code_evenement..
			" And Lower(Fonction) In ('technicaldelegate', 'chiefrace', 'referee', 'assistantreferee', 'chiefcourse', 'startreferee', 'finishreferee', 'chieftiming')"..
			" Order By Ordre" );
		return tEvenement_Officiel;
	end
end

function afterJury(t)
	if mode == 'export' then 
		SetAttributes(t, 'Function', rEvenement_Officiel:GetString("Fonction"));
	end
end

function contentNumber(t)
	local codeFunction = rEvenement_Officiel:GetString('Fonction'):lower();
	if codeFunction == 'technicaldelegate' then
		local codex = tEvenement:GetCell('Codex',0);
		local pos = string.find(codex, '%.');
		if pos ~= nil and pos > 1 then
			return codex:sub(pos+1);
		end
	end
	return '';
end

function beforeTimingBy(t)
	if mode == 'import' then 
	else
		base:TableLoad(tEvenement_Officiel, 
			"Select * From Evenement_Officiel"..
			" Where Code_evenement = "..Code_evenement..
			" And Fonction Like 'timingby%' ");
		local name = tEvenement_Officiel:GetCell('Nom', 0)..' '..tEvenement_Officiel:GetCell('Prenom', 0);
		tEvenement_Officiel:SetCell('Nom', 0, name)
		return tEvenement_Officiel;
	end
end

function beforeIntermediate(t)
	if mode == 'import' then
		if code_Manche == 'tot' then code_Manche = -1 end
		tResultat_Inter:GetRecord():SetNull();
		tResultat_Inter:GetRecord():Set({ Code_manche = Code_manche, Code_inter = t.attributes.i });
		tResultat_Inter:AddRow();
	else
		return base:TableLoad(tResultat_Inter, 
			"Select * From Resultat_Inter"..
			" Where Code_evenement = "..Code_evenement..
			" And Code_manche = "..rEpreuve_Alpine_Manche:GetString('Code_manche')..
			" And Code_coureur = '"..rResultat:GetString('Code_coureur').."'"..
			" And Tps_chrono > 0 "..
			" Order By Code_inter ");
	end
end

function afterIntermediate(t) 
	if mode == 'export' then 
		SetAttributes(t, 'i', rResultat_Inter:GetString("Code_inter"));
	end
end

function beforeCourseIntermediate(t)
	if mode == 'export' then
		-- Neutralisation ... (Il faudrait renvoyer une table avec autant de lignes que de temps inter avec les zones "distance" ...)
		-- On renvoie ici une table vide 
		if tInformationInter == nil then
			tInformationInter = sqlTable.Create();
			tInformationInter:SetName('_InformationInter_');
			base:AddTable(tInformationInter);
		end
		tInformationInter:RemoveAllRows();
		return tInformationInter;
	end
end

function contentFisCode(t) 
	if mode == 'import' then 
		return 'FIS'..t.content; 
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

function beforeCategory(t)
	if mode == "export" then
		if tEpreuve:GetCell('Code_entite', 0) == 'FIS' then
			base:TableLoad(tRegroupement, 
				'Select * From Regroupement Where Code_activite = "ALP" And Code_entite = "FIS"'..
				' And Code_saison = "'..tEvenement:GetCell("Code_saison", 0)..'"'..
				' And Code = "'..tEpreuve:GetCell('Code_regroupement', 0)..'"'
				);
			tEpreuve:SetCell('Code_regroupement', 0, tRegroupement:GetCell('Code_international',0));
			return tEpreuve;
		end
	end
end

function afterType(t)
	if mode == "export" then
		t.content = 'Official';
	end
end

function contentCodex(t)
	if mode == 'import' then
		return t.content;
	else
		local codeEntite = tEvenement:GetCell('Code_entite', 0);
		local codex = tEvenement:GetCell('Codex', 0);
		-- export
		if codeEntite == 'FIS' then
			-- Suppression du Code Nation
			return string.sub(codex,4,7);
		else
			return codex;
		end
	end
end

function contentSoftwarecompany(t)
	return 'Agil Informatique - FFS';
end

function afterPlace(t)
	if mode == 'export' then
		t.content = 'Start';
	end
end

--------------------------- XML Description tables ---------------------------
Raceheader = { 
	attributes = { 
		{name = 'Sector', value = 'AL|MA'}, 
		{name = 'Gender', value = 'M|W|A'},
		{name = 'FFS_Homologation', value = 'OUI|NON', optional=true },
	}, 
	children = {
		{ name = 'Season', field = 'Evenement.Code_saison' },
		{ name = 'Codex', content = contentCodex, field = 'Evenement.Codex' },
		{ name = 'Nation', field = 'Evenement.Code_nation', maxlen=3 },
		{ name = 'Discipline', content = { 'DH','SL','GS','SG','AC','TE','KOS','KOG','PGS','PSL','CE','IND','P','CAR' }, field = 'Epreuve.Code_discipline' },
		{ name = 'Category', before = beforeCategory, field = 'Epreuve.Code_regroupement' },
		{ name = 'Type', content = { 'Startlist', 'Partial' ,'Unofficial', 'Official' }, after = afterType },
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
		
		{ name = 'FFS_Organisateur', field = 'Evenement.Organisateur', required = '0-1', export = tags_ffs },
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
		{ name = 'FFS_Critere', field = 'Resultat.Critere', required = '0-1', export = tags_ffs }
	}
};

AL_result_classified = {
	children = {
		{ name = 'TimeRun1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono' },
		{ name = 'TimeRun2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono' , required = '0-1' },
		{ name = 'TimeRun3', before = synchroResultatManche, arg = 3, field = 'Resultat_Manche.Tps_chrono' , required = '0-1' },
		{ name = 'TotalTime', field = 'Resultat.Tps_chrono' },
		{ name = 'Diff', field = 'Resultat.Diff', required = '0-1' },
		{ name = 'RacePoints', field = 'Resultat.Pts' },
		{ name = 'Level', content = 'string', required = '0-1' }
	}
};

AL_result_notclassified = {
	required = '0-1', children = {
		{ name = 'TimeRun1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono' , required = '0-1' },
		{ name = 'TimeRun2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono' , required = '0-1' },
		{ name = 'TimeRun3', before = synchroResultatManche, arg = 3, field = 'Resultat_Manche.Tps_chrono' , required = '0-1' },
	}
};

AL_resultdetail = {
	required = '0-1', children = {
		{ name = 'Run', required = '0-4', before = beforeRun, after = afterRun, attributes = {{ name = 'No', value = '1|2|3|tot'}}, children = {
				{ name = 'Intermediate', required = '0-99', after = afterIntermediate, before = beforeIntermediate, 
					attributes = {{ name = 'i', type_value = 'integer', optional = true }},
					children = {
						{ name = 'Time', field = 'Resultat_Inter.Tps_chrono', required = '0-1' },	-- Normalement pas tout optionel ...
						{ name = 'Diff', field = 'Resultat_Inter.Diff', required = '0-1' },
						{ name = 'Rank', field = 'Resultat_Inter.Clt', required = '0-1' },
						{ name = 'Speed', content = 'decimal', required = '0-1' },
						{ name = 'SectorTime', content = 'string', required = '0-1' },
						{ name = 'SectorDiff', content = 'string', required = '0-1' },
						{ name = 'SectorRank', content = 'integer', required = '0-1' }
					}
				}
			}
		}
	}
};

Course = {
	children = {
		{ name = 'Name', required = '0-1', field = 'Pistes.Nom_piste' },
		{ name = 'Homologation', field = 'Pistes.Homologation_fis' },
		{ name = 'Length', required = '0-1', field = 'Epreuve_Alpine_Manche.Longueur' },
		{ name = 'Gates', field = 'Epreuve_Alpine_Manche.Nombre_de_portes' },
		{ name = 'TurningGates', field = 'Epreuve_Alpine_Manche.Changement_de_directions' },
		{ name = 'StartElev', required = '0-1', field = 'Epreuve_Alpine_Manche.Altitude_Depart' },
		{ name = 'FinishElev', required = '0-1', field = 'Epreuve_Alpine_Manche.Altitude_Arrivee' },
		
		{ name = 'CourseSetter', required = '0-1', 
			children = {
				{ name = 'Lastname', field = 'Epreuve_Alpine_Manche.Nom_traceur' },
				{ name = 'Firstname', field = 'Epreuve_Alpine_Manche.Prenom_traceur' },
				{ name = 'Nation', field = 'Epreuve_Alpine_Manche.Code_nation_traceur' }
			}
		},
		{ name = 'Forerunner', required = '0-99', before = beforeForerunner,
			attributes = {{ name = 'Order', type_value = 'integer' }},
			children = {
				{ name = 'Lastname', field = 'Epreuve_Alpine_Manche_Ouvreur.Nom' },
				{ name = 'Firstname', field = 'Epreuve_Alpine_Manche_Ouvreur.Prenom' },
				{ name = 'Nation', field = 'Epreuve_Alpine_Manche_Ouvreur.Nation' },
				
				{ name = 'FFS_Matric', field = 'Epreuve_Alpine_Manche_Ouvreur.Matric', export = tags_ffs, required = '0-1'}, 
				{ name = 'FFS_Comite', field = 'Epreuve_Alpine_Manche_Ouvreur.Comite', export = tags_ffs, required = '0-1'}, 
				{ name = 'FFS_Club', field = 'Epreuve_Alpine_Manche_Ouvreur.Club', export = tags_ffs, required = '0-1'}
			}, after = afterForerunner
		},
		{ name = 'Intermediate', required = '0-99', before = beforeCourseIntermediate, attributes = {
				{ name = 'i', type_value = 'integer' },
				{ name = 'type', value = 'time|speed' }
			},
			children = {
				{ name = 'Distance', content = 'string' }
			}
		}
	}
};

Weather = {
	required = '0-9999', children = {
		{ name = 'Time', field = 'Epreuve_Alpine_Manche.Heure_depart', required = '0-1' },
		{ name = 'Place', content = {'Start', 'Finish'}, after = afterPlace, required = '0-1' },
		{ name = 'Weather', field = 'Epreuve_Alpine_Manche.Meteo_course', required = '0-1' },
		{ name = 'Snow', field = 'Epreuve_Alpine_Manche.Neige_course', required = '0-1' },
		{ name = 'TemperatureAir', field = 'Epreuve_Alpine_Manche.Temperature_air_depart', required = '0-1' },
		{ name = 'TemperatureSnow', required = '0-1' },
		{ name = 'Humidity', required = '0-1' },
		{ name = 'WindSpeed', required = '0-1' },
		{ name = 'WindDirection', required = '0-1' }
	}
};
	
AL_race = {
	children = { 
		{ name = 'AL_raceinfo', children = {
				{ name = 'UsedFisList', field = 'Evenement.Code_liste', required = '0-1' },
				{ name = 'AppliedPenalty', field = 'Epreuve.Penalite_appliquee', required = '0-1' },
				{ name = 'CalculatedPenalty', field = 'Epreuve.Penalite_calculee', required = '0-1' },
				{ name = 'Fvalue', field = 'Discipline.Facteur_f', required = '0-1' },

				{ name = 'Jury', required = '0-999', before = beforeJury, attributes = {
						{ name = 'Function', value = 'TechnicalDelegate|ChiefRace|Referee|AssistantReferee|ChiefCourse|StartReferee|FinishReferee|ChiefTiming'}
					},
					children = {
						{ name = 'Number', content = contentNumber, required = '0-1' },
						{ name = 'Lastname', field = 'Evenement_Officiel.Nom' },
						{ name = 'Firstname', field = 'Evenement_Officiel.Prenom' },
						{ name = 'Nation', field = 'Evenement_Officiel.Nation' },
						{ name = 'Email', field = 'Evenement_Officiel.Email', required = '0-1' },
						{ name = 'Phonenbr', field = 'Evenement_Officiel.Tel_mobile', required = '0-1' },
						
						{ name = 'FFS_Code_coureur', field = 'Evenement_Officiel.Code_coureur', required = '0-1'},

					}, after = afterJury
				},
				
				{ name = 'Member', required = '0-999', before = beforeJury, export = false, attributes = 
					{{ name = 'Function', value = 'ChiefRace|Referee|AssistantReferee|ChiefCourse|StartReferee|FinishReferee|ChiefTiming'}},
					children = {
						{ name = 'Lastname', field = 'Evenement_Officiel.Nom' },
						{ name = 'Firstname', field = 'Evenement_Officiel.Prenom' },
						{ name = 'Nation', field = 'Evenement_Officiel.Nation' }
					}, after = afterJury
				},
				
				{ name = 'Runinfo', required = '0-3', before = beforeRuninfo, attributes = {{ name = 'No', type_value = 'integer'}}, 
					children = {
						{ name = 'Course', props = Course },
						{ name = 'Weather', props = Weather },
						{ name = 'StartTime', field = 'Epreuve_Alpine_Manche.Heure_depart' },
						{ name = 'EndTime', required = '0-1' },
					}, after = afterRuninfo
				},
						
				{ name = 'TimingBy', before = beforeTimingBy, field = 'Evenement_Officiel.Nom', required = '0-1' },
				{ name = 'DataProcessingBy', content = 'string', required = '0-1' },
				{ name = 'Softwarecompany', content = contentSoftwarecompany, required = '0-1' },
				{ name = 'Softwarename', import = false, content = app.GetName, required = '0-1' },
				{ name = 'Softwareversion', import = false, content = app.GetVersion, required ="0-1" },
			}
		},
		{ name = 'AL_classified', children = {
				{ name = 'AL_ranked', required = '0-99999', before = beforeAL_ranked,  attributes = {{name ='Status', value = 'QLF'}}, children = {
						{ name = 'Rank', field = 'Resultat.Clt', required = '0-1' },	-- 2.10
						{ name = 'Order', field = 'Resultat.Rang', required = '0-1' },	-- 2.10
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },	-- 2.10
						{ name = 'Competitor', props = Competitor },
						{ name = 'AL_result', props = AL_result_classified },
						{ name = 'AL_resultdetail', props = AL_resultdetail }
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
						{ name = 'AL_result', props = AL_result_notclassified },
						{ name = 'AL_resultdetail', props = AL_resultdetail },
						{ name = 'Reason', required = '0-1', content = 'string' },
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
	after = afterFisresults
};
