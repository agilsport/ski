-- FIS SB Data Exchange XML Protocol version 3.8 

function beforeFisresults(t)
	base:SetGlobalVariable({'table', 'record'}); -- tName => table Name, rName => record Name
	
	base:SetBaseFormatChrono('SB');
	Message('Code_discipline: '..base:GetRecord('Epreuve'):GetString('Code_discipline'));
	
	if mode == 'import' then
		tEvenement:AddRow();
		
		rEpreuve:Set('Code_epreuve', 1);
		tEpreuve:AddRow();

		rEpreuve_Nordique:Set('Code_epreuve', 1);
		tEpreuve_Nordique:AddRow();
		
		tPistes:AddRow();
		tDiscipline:AddRow();
		
		tResultat_Copy = tResultat:Copy(false, true);	--  parametre 1 : false = copie de la structure, true = copie de la structure et des rows. parametre 2 : true va dans le garbage collector
		tResultat_Manche_Copy = tResultat_Manche:Copy(false, true);
		tResultat_Inter_Copy = tResultat_Inter:Copy(false, true);
	else
		SetAttributes(t, 'Version', '3.8'); -- Version du XML

		-- Vérification Rang de Départ 
		if tRanking:GetNbRows() > 0 then
			if tRanking:GetCellInt('Rang', 0) == 0 then
				tRanking:OrderBy("Dossard");
				for i=0,tRanking:GetNbRows()-1 do
					tRanking:SetCell("Rang",i, i+1);
				end
			end
		end
		
		-- Clt_total 
		if tRanking:GetIndexColumn('Clt_total') < 0 then
			tRanking:AddColumn('Clt_total', 'ranking');
			for i=0,tRanking:GetNbRows()-1 do
				tRanking:SetCell("Clt_total",i, tRanking:GetCellInt('Clt',i));
			end
		end
		
		-- Suppression Clt_total ko ...
		local i = 0;
		while i < tRanking:GetNbRows() do
			if tRanking:GetCellInt("Clt_total",i) <= 0 then
				tRanking:RemoveRowAt(i);
			else
				i = i+1;
			end
		end
		
		Message('Nb Course = '..tostring(GetNbCourse()));
		Message('Nb Manche Course 1 = '..tostring(GetNbManche(1)));
		Message('Nb Juge Course 1 = '..tostring(GetNbJuge(1)));
	end
end

function afterFisresults(t)
	xmlError = xmlError or {};
	if mode == 'import' then
		if #xmlError == 0 then
			-- Verification table Evenement - Mise de valeurs par défaut ...
			if tEvenement:IsCellNull('Code_activite', 0) then tEvenement:SetCell('Code_activite', 0, 'FOND') end
			if tEvenement:IsCellNull('Code_entite', 0) then tEvenement:SetCell('Code_entite', 0, 'FIS') end
			
			local codeEntite = tEvenement:GetCell('Code_entite', 0);
			if codeEntite == 'FIS' then
				local codex = tEvenement:GetCell('Codex', 0);
				if codex:len() == 4	then	
					-- FIS, ajout du code nation
					tEvenement:SetCell('Codex', 0, tEvenement:GetCell('Code_nation', 0)..codex);
				end
			end
			
			-- Verification table Epreuve - Mise de valeurs par défaut ...
			if codeEntite == 'FIS' then
				if tEpreuve:IsCellNull('Code_grille_categorie', 0) then tEpreuve:SetCell('Code_grille_categorie', 0, 'FIS-FSP') end
				if tEpreuve:IsCellNull('Code_categorie', 0) then tEpreuve:SetCell('Code_categorie', 0, '*') end
			else
				if tEpreuve:IsCellNull('Code_grille_categorie', 0) then tEpreuve:SetCell('Code_grille_categorie', 0, 'FFS-FSP') end
				if tEpreuve:IsCellNull('Code_categorie', 0) then tEpreuve:SetCell('Code_categorie', 0, '*') end
			end
			
			-- Prise de la Discipline à partir du Discipline.Code_international 
			local codeInter = tDiscipline:GetCell('Code_international', 0);
			base:TableLoad(tDiscipline, 
				"Select * From Discipline "..
				"Where Code_activite = 'FOND' "..
				"And Code_entite = 'FIS' "..
				"And Code_saison = '"..base:GetActiveSaison().."' "..
				"And Code_international = '"..codeInter.."' "
			);
			tEpreuve:SetCell('Code_discipline', 0, tDiscipline:GetCell('Code',0));

			-- Prise du Matricule Piste ..
			local homologation = tPistes:GetCell('Homologation_fis', 0);
			if string.len(homologation) > 0 and tEpreuve_Nordique:GetNbRows() > 0 then
				if codeEntite == 'FIS' then
					base:TableLoad(tPistes, "Select * From Pistes Where Code_activite = 'NOR' And Homologation_fis = '"..homologation.."'");
				else
					base:TableLoad(tPistes, "Select * From Pistes Where Code_activite = 'NOR' And Homologation_ffs = '"..homologation.."'");
				end
				if tPistes:GetNbRows() > 0 then
					tEpreuve_Nordique:SetCell("Homologation", 0, tPistes:GetCell('Matricule', 0));
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

function GetNbCourse()
	return tInfo_Notation_Slopestyle:GetNbRows();
end

function GetNbManche(course)
	if course >= 1 and course <= tInfo_Notation_Slopestyle:GetNbRows() then
		return tInfo_Notation_Slopestyle:GetCellInt("Nb_manche", course - 1);
	else
		return 0;
	end
end

function GetNbJuge(course)
	if course >= 1 and course <= tInfo_Notation_Slopestyle:GetNbRows() then
		return tInfo_Notation_Slopestyle:GetCellInt("Nb_juge", course - 1);
	else
		return 0;
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
		SetAttributes(t, 'Sector', 'SB');
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

function beforeSB_ranked(t)
	if mode == 'import' then
		tResultat:AddRow();
	else
		return tRanking;
	end
end

function afterSB_ranked(t)
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

function afterSB_rank(t)
	if mode == 'import' then
	-- atribut a mettre si resultats departager par camera finish ou autre moyen de departage (juge ou iphone)**************************************************** 
	-- le laisser car en FIS on a toujours un systeme de cam finish en nordique mais on ne le renseigne pas encore dans skiffs************************************
	else
--		SetAttributes(t, 'Pf', 'y');
	end
end

function Calculdiff(t)
	if mode == 'export' then
		local cmd =
			"Select Min(Tps_chrono) Tps_min from Resultat_Manche "..
			"Where Code_evenement = "..Code_evenement..
			" And Code_manche = 1 "..
			" And Tps_chrono > 0"
		;		
		local tMin = base:TableLoad(cmd);
		local BestTime = tonumber(tMin:GetCell('Tps_min', 0)) or -1;
		
		-- recherche du besttime de la manche 1
		local cmd2 =
			"Select Tps_chrono Tps_Comp from Resultat_Manche "..
			"Where Code_evenement = "..Code_evenement..
			" And Code_coureur = '"..tResultat_Manche:GetCell('Code_coureur', 0)..
			"' And Code_manche = 1 "..
			" And Tps_chrono > 0"
		;		
		local tComp = base:TableLoad(cmd2);
		local Timeconcurent = tonumber(tComp:GetCell('Tps_Comp', 0)) or -1;
		-- calcul de la diff
		local DiffManche1 = tonumber(Timeconcurent) - tonumber(BestTime);
		-- mise de la Diff au bon format temps de la FIS
		local DiffPours = app.TimeToString(tonumber(DiffManche1), "%2m:%2s");
		return DiffPours
	end
end

function Arrivaldiff(t)
	if mode == 'export' then
		local cmd =
			"Select Min(Tps) Tps_min from Resultat "..
			"Where Code_evenement = "..Code_evenement..
			" And Tps > 0"
		;		
		local tMin = base:TableLoad(cmd);
		local BestTime = tonumber(tMin:GetCell('Tps_min', 0)) or -1;
		
		-- recherche du besttime du Tps Total
		local cmd2 =
			"Select Tps Tps_Comp from Resultat "..
			"Where Code_evenement = "..Code_evenement..
			" And Code_coureur = '"..tResultat_Manche:GetCell('Code_coureur', 0)..
			"' And Tps > 0"
		;		
		local tComp = base:TableLoad(cmd2);
		local Timeconcurent = tonumber(tComp:GetCell('Tps_Comp', 0)) or -1;
		-- calcul de la diff
		local DiffManche1 = tonumber(Timeconcurent) - tonumber(BestTime);
		-- mise de la Diff au bon format temps de la FIS pour le XML
		local DiffPours = app.TimeToString(tonumber(DiffManche1), "%2m:%2s.%1f");
		return DiffPours
	end
end

function afterTimediff(t)
	if mode == 'import' then
	else
		-- l'atribut wave doit s'afficher que si c'est des départs en vague ou en mass
		if tEpreuve:GetCell('Code_discipline', 0) == 'MASS' or tEpreuve:GetCell('Code_discipline', 0) == 'POP' then
			SetAttributes(t, 'wave', 'y');
		end
	end
end

function afterTotalTime(t)
	if mode == 'import' then
	else
		-- l'atribut wave doit s'afficher que si le concurent est Hors delais donc status == out
		if tResultat:GetCell('Tps', 0) == 'OUT' then
			SetAttributes(t, 'TL', 'y');
		end
	end
end

function beforeSB_notranked(t)
	if mode == 'import' then
		tResultat:AddRow();
		
		local status = t.attributes.Status or 'DNS';
		rResultat_Manche:Set('Tps_chrono', status); 
		tResultat_Manche:AddRow();
	else
--		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps < 0 Order By Dossard');
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Dossard > 9999 Order By Dossard');
	end
end

function afterBib(t)
	if mode == 'import' then
	else
		if tResultat:GetCellInt('Clt') == 1 then
			SetAttributes(t, 'Color', 'yellow');
		else
			SetAttributes(t, 'Color', '-');
		end
	end
end

function afterSB_notranked(t)
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
			-- SetAttributes(t, 'Status', ranking.CodeInter(tResultat_Manche:GetCellInt('Tps_chrono',0))..tResultat_Manche:GetCellInt('Code_manche', 0));
			SetAttributes(t, 'Status', ranking.CodeInter(tResultat_Manche:GetCellInt('Tps_chrono',0)));
		else
			SetAttributes(t, 'Status', "DNS");
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
	
	if mode == 'export' then
		return tEpreuve;
	else
		-- à garder le FIS vas peu etre mettre l'atribut dans le runinfo*************************
		Code_manche = tonumber(t.attributes.No);
		if tEpreuve:GetCellInt('Nombre_de_manche', 0, -1) <= Code_manche then
			tEpreuve:SetCell('Nombre_de_manche', 0, Code_manche);
		end
	end 
end
function beforeSoftwarecompany(t)
	return 'Agil Informatique';
end
function afterRuninfo(t) 
	if mode == 'export' then
		Code_manche = tEpreuve:GetCellInt('Nombre_de_manche', 0);
		SetAttributes(t, 'No', tEpreuve:GetCellInt('Nombre_de_manche', 0));
	end
end

function afterCourse(t) 
	if mode == 'export' then
		SetAttributes(t, 'No', tEpreuve:GetCellInt('Code_epreuve', 0));
	end
end
function beforeCourse(t) 
	if mode == 'import' then 
		Code_manche = tonumber(t.attributes.No);
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
			" And Fonction Like 'ChiefTiming%' ");
		local name = tEvenement_Officiel:GetCell('Nom', 0)..' '..tEvenement_Officiel:GetCell('Prenom', 0);
		tEvenement_Officiel:SetCell('Nom', 0, name)
		return tEvenement_Officiel;
	end
end 

function beforeDataProcessingBy(t)
	if mode == 'import' then 
	else
		base:TableLoad(tEvenement_Officiel, 
			"Select * From Evenement_Officiel"..
			" Where Code_evenement = "..Code_evenement..
			" And Fonction Like 'TIMEKEEPER%' ");
		local name = tEvenement_Officiel:GetCell('Nom', 0)..' '..tEvenement_Officiel:GetCell('Prenom', 0);
		tEvenement_Officiel:SetCell('Nom', 0, name)
		return tEvenement_Officiel;
	end
end

function beforeHD(t) 
	if mode == 'export' then 
		Denivele =  tEpreuve:GetCellInt('Point_haut', 0) - tEpreuve:GetCellInt('Point_bas', 0);
		return Denivele

	end
end

function beforeStyle(t)
	if mode == 'export' then
	local Code_manche = tEpreuve:GetCellInt('Nombre_de_manche', 0)
		if tEpreuve:GetCell('Style', 0) == 'C' then
			Style = 'Classic'; 
		elseif tEpreuve:GetCell('Style', 0) == 'L' then
			Style = 'FreeStyle';
		else
			Style = 'Mixed' ;	
		end
		return Style
	else
	-- MessageWarning('O detected'..t.content);
		local Style = t.content;
		if Style == 'Classic' then
			Style = 'C'
		elseif Style == 'FreeStyle' then
			Style = 'L'
		else 
			Style = 'L'
		end
		return Style
	end
end

function contentFisCode(t) 
	if mode == 'import' then 
		return 'FIS'..t.content; 
	else 
		return t.content:sub(4);
	end 
end

function GetLabelTour(tour)
	tour = tonumber(tour);
	if nb_tour == 4 then
		if tour == 4 then return 'final';
		elseif tour == 3 then return 'semifinal';
		elseif tour == 2 then return 'quarterfinal';
		elseif tour == 1 then return 'eightfinal';
		else return 'qualification';
		end
	elseif nb_tour == 3 then
		if tour == 3 then return 'final';
		elseif tour == 2 then return 'semifinal';
		elseif tour == 1 then return 'quarterfinal';
		else return 'qualification';
		end
	elseif nb_tour == 2 then
		if tour == 2 then return 'final';
		elseif tour == 1 then return 'semifinal';
		else return 'qualification';
		end
	elseif nb_tour == 1 then
		if tour == 1 then return 'final';
		else return 'qualification';
		end
	else
		return 'qualification';
	end
end

function contentLevel(t) 
	if mode == 'export' then 
		return GetLabelTour(t.content);
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

function afterPlace(t)
	if mode == 'export' then
		t.content = 'Start';
	end
end

function Codemanche(t)
	if mode == 'export' then
		Codemanche = 1 --tEpreuve:GetCellInt('Nombre_de_manche', 0);
		return tonumber(Codemanche)
	end
end

function synchroNation(t,Status)
	if mode == 'export' then
		local cmd = 
			"Select DISTINCT Nation From Resultat"..
			" Where Code_evenement = "..Code_evenement..
			" And Tps = '"..Status..
			"'"
		;
		base:TableLoad(tResultat, cmd);
		NbNation = tResultat:GetNbRows();
	t.content = NbNation; 
	end
end
function synchroNationrank(t,Status)
	if mode == 'export' then
		local cmd = 
			"Select DISTINCT Nation From Resultat"..
			" Where Code_evenement = "..Code_evenement..Status
		;
		base:TableLoad(tResultat, cmd);
		NbNation = tResultat:GetNbRows();
	t.content = NbNation; 
	end
end

--------------------------- XML Description tables ---------------------------
Competitor = {
	children = {
		{ name = 'FisCode', content = contentFisCode, field = 'Ranking.Code_coureur' },
		{ name = 'Lastname', field = 'Ranking.Nom' },
		{ name = 'Firstname', field = 'Ranking.Prenom' },
		{ name = 'Gender', content = {'M', 'F'} , field = 'Ranking.Sexe', required = '0-1' },
		{ name = 'Nation', field = 'Ranking.Nation' },		
		{ name = 'YearOfBirth', field = 'Ranking.An', required = '0-1' },
		{ name = 'Clubname', field = 'Ranking.Club', required = '0-1', export = false },
		
		{ name = 'FFS_Code_coureur', field = 'Ranking.Code_coureur', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Comite', field = 'Ranking.Comite', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Groupe', field = 'Ranking.Groupe', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Equipe', field = 'Ranking.Equipe', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Critere', field = 'Ranking.Critere', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Distance', field = 'Ranking.Distance', required = '0-1', export = tags_ffs }
	}
};

SB_result_classified = {
	children = {
		{ name = 'Totaltime', field = 'Ranking.Notation' },
		{ name = 'Timerun1', field = 'Ranking.Notation_C1' },
		{ name = 'Totalscore', field = 'Ranking.Notation' },
		{ name = 'Racepoint',  field = 'Ranking.Pts' }
	}
};

SB_result_notclassified = {
};

Weather = {
	required = '0-9999', children = {
		{ name = 'Starttime', field = 'Epreuve.Heure_depart'},
		{ name = 'Endtime', required = '0-1'},  --- pour avoir l'heure de fin de course
		{ name = 'Place', required = '0-1' }, -- Lieu d'évaluation météorologique a voir si on met créer une colonne dans épreuve
		{ name = 'Weather', field = 'Epreuve_Nordique.Meteo'}, -- Description of weather conditions
		{ name = 'Snow', required = '0-1' },
		{ name = 'TemperatureAir', field = 'Epreuve_Nordique.Temperature_air'},
		{ name = 'TemperatureSnow', field = 'Epreuve_Nordique.Temperature_neige'},
		{ name = 'Humidity', required = '0-1' },
		{ name = 'Maxwindspeed', required = '0-1' },
		{ name = 'Minwindspeed', required = '0-1' },
		{ name = 'Avgwindspeed', required = '0-1' },
		{ name = 'Winddirection', required = '0-1' }
	}
};

-- fisheader
	-- version xml
	-- Réalisation du Race header
Raceheader = { 
	attributes = { 
		{name = 'Sector', value = 'SB'}, 
		{name = 'Gender', value = 'M|W|A'},
		{name = 'FFS_Homologation', value = 'OUI|NON', optional=true },
	}, 
	children = {
		{ name = 'Season', field = 'Evenement.Code_saison' },
		{ name = 'Codex', content = contentCodex, field = 'Evenement.Codex' },
		{ name = 'Nation', field = 'Evenement.Code_nation', maxlen=3 },
		{ name = 'Discipline', content = {'BA','SS','SBX','HP','PGS','PSL','PRT','BXT','SL','GS','TSL','XT' }, field = 'Discipline.Code_international' }, 
		{ name = 'Category', field = 'Epreuve.Code_regroupement' },
		{ name = 'Type', content = { 'Startlist', 'Partial' ,'Unofficial', 'Official' }, after = afterType },
		{ name = 'Eventname', field = 'Evenement.Nom' },
		{ name = 'Place', field = 'Evenement.Station' },
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
		
		{ name = 'FFS_Comite', field = 'Evenement.Code_comite', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Club', field = 'Evenement.Club', required = '0-1', export = tags_ffs },
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
-- fin du Race_header	

-- création du SB_race
SB_race = {
	children = { 
		{ name = 'SB_raceinfo', children = {
				{ name = 'Jury', required = '0-999', before = beforeJury, attributes = {
						{ name = 'Function', value = 'CHIEFCOMPETITION|TECHNICALDELEGATE|RACEDIRECTOR|RACEDIRECTORASSISTANT|TECHNICALDELEGATEASSISTANT|TECHNICALDELEGATEASSISTANTNATIONAL|MEMBER|CHIEFTIMING|COORDINATOR'}
					},
					children = {
						{ name = 'lastname', field = 'Evenement_Officiel.Nom' },
						{ name = 'firstname', field = 'Evenement_Officiel.Prenom' },
						{ name = 'nation', field = 'Evenement_Officiel.Nation' },
						{ name = 'Email', field = 'Evenement_Officiel.Email', required = '0-1', export = tags_ffs},
						{ name = 'Phonenbr', field = 'Evenement_Officiel.Tel_mobile', required = '0-1', export = tags_ffs },
						{ name = 'FFS_Code_coureur', field = 'Evenement_Officiel.Code_coureur', required = '0-1', export = tags_ffs},

					}, after = afterJury
				},

				{ name = 'UsedFisList', field = 'Evenement.Code_liste', required = '0-1' },
				{ name = 'AppliedPenalty', field = 'Epreuve.Penalite_appliquee', required = '0-1' },
				{ name = 'CalculatedPenalty', field = 'Epreuve.Penalite_calculee', required = '0-1' },
				{ name = 'TimingBy', before = beforeTimingBy, field = 'Evenement_Officiel.Nom', required = '0-1' }, -- ok
				{ name = 'DataProcessingBy', before = beforeDataProcessingBy, field = 'Evenement_Officiel.Nom', required = '0-1' },
				{ name = 'Softwarecompany', import = false, content = beforeSoftwarecompany, required = '0-1' },
				{ name = 'Softwarename', import = false, content = app.GetName, required = '0-1' },
				{ name = 'Softwareversion', import = false, content = app.GetVersion, required ="0-1" },
				{ name = 'FFS_Homologation_chrono', field = 'Epreuve_Nordique.Homologation_chrono', required = '0-1', export = tags_ffs }
			}
		},

		-- Création du SB_classified
		{ name = 'SB_classified', children = {
				{ name = 'SB_ranked', required = '0-99999', before = beforeSB_ranked,  attributes = {{name ='Status', value = 'QLF'}}, children = {
						{ name = 'Rank', attributes = {{name ='Pf', value = 'y', optional = true}}, after = afterSB_rank, field = 'Ranking.Clt_total', required = '0-1' },
						{ name = 'Order', field = 'Ranking.Rang', required = '0-1' },	
						{ name = 'Bib', field = 'Ranking.Dossard' },
						{ name = 'Competitor', props = Competitor },
						{ name = 'SB_result', props = SB_result_classified },
					}, after = afterSB_ranked 
				}
			}
		},
		
		-- Création du SB_notclassified
		{ name = 'SB_notclassified', children = {
				{ name = 'SB_notranked', required = '0-99999', before = beforeSB_notranked,
					attributes = {{name = 'Status', value = 'DNS|DSQ|DNF|DPO|NPS|DQB|OUT'}},
					children =
					{
						{ name = 'Bib', field = 'Resultat.Dossard' },	
						{ name = 'Competitor', props = Competitor },
						{ name = 'Reason', required = '0-1', content = 'string' }, -- c'etais une demande dans le excell si on pourais avoir une zonz de saisie de disqua au lieu du numero de porte en alpin ???
						{ name = 'SB_result', props = SB_result_notclassified },
						{ name = 'Level', required = '0-1', content = 'string' } 
					},
					after = afterSB_notranked
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
		{ name = 'SB_Race', props = SB_race }
	},
	after = afterFisresults
};
