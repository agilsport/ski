-- FIS Alpine Data Exchange XML Protocol version 3.7 du 16-12-2021 => https://www.fis-ski.com/en/inside-fis/document-library/timing-data
-- Envoi FIS OK
-- Version 1.3 le 16-12-2021
-- verifier les code regroupement avec marlene
-- verifier les fonction beforeCourseIntermediate et afterCourseIntermediate
-- verifier le calcul de diff en M2 pour la balise Timediff ou on doit envoyer la diff de départ pour la poursuite
-- afterTotalTime à vérifier la fonction pour voir sil'atribut se met bien par rapport statu du concurent
-- en import poursuite le tps manche se met en M1 au lieu de M2


function beforeFisresults(t)
	base:SetGlobalVariable({'table', 'record'}); -- tName => table Name, rName => record Name
	
	base:SetBaseFormatChrono('FOND');
	Message('Xml version = xmlCCv2');
	-- Message('Fmt Manche='..tResultat_Manche:GetColumnFormat('Tps'));
	-- Message('Fmt='..tResultat:GetColumnFormat('Tps'));
	
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
		SetAttributes(t, 'Version', '3.7'); -- Version du XML
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

function beforeCC_ranked(t)
	if mode == 'import' then
		tResultat:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps > 0 Order By Tps, Dossard');
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
	end
end

function afterCC_rank(t)
	if mode == 'import' then
	-- atribut a mettre si resultats departager par camera finish ou autre moyen de departage (juge ou iphone)**************************************************** 
	-- le laisser car en FIS on a toujours un systeme de cam finish en nordique mais on ne le renseigne pas encore dans skiffs************************************
	else
		SetAttributes(t, 'Pf', 'y');
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

function beforeCC_notranked(t)
	if mode == 'import' then
		tResultat:AddRow();
		
		local status = t.attributes.Status or 'DNS';
		rResultat_Manche:Set('Tps_chrono', status); 
		tResultat_Manche:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps < 0 Order By Dossard');
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

function afterCC_notranked(t)
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
			" And Lower(Fonction) In ('TECHNICALDELEGATE', 'TECHNICALDELEGATEASSISTANT', 'COORDINATOR', 'RACEDIRECTOR', 'TECHNICALDELEGATEASSISTANTNATIONAL', 'CHIEFCOMPETITION','CHEIEFTIMING')"..
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

function beforeIntermediate(t)
	if mode == 'import' then
		if code_Manche == 'tot' then code_Manche = -1 end
		tResultat_Inter:GetRecord():SetNull();
		tResultat_Inter:GetRecord():Set({ Code_manche = Code_manche, Code_inter = t.attributes.i });
		tResultat_Inter:AddRow();
	else
		Code_manche = 1;
		return base:TableLoad(tResultat_Inter, 
			"Select * From Resultat_Inter"..
			" Where Code_evenement = "..Code_evenement..
			--" And Code_manche = "..rEpreuve_Alpine_Manche:GetString('Code_manche')..  -- pas la bonne formule pour avoir le code manche en nordique
			" And Code_manche = "..Code_manche..   --rResultat_Manche:GetString('Code_manche').. -- ?? voir si ok en nordique
			" And Code_coureur = '"..rResultat:GetString('Code_coureur').."'"..
			" And Tps_chrono > 0 "..
			" Order By Code_inter ");
	end
end

function beforeHD(t) 
	if mode == 'export' then 
		Denivele =  tEpreuve:GetCellInt('Point_haut', 0) - tEpreuve:GetCellInt('Point_bas', 0);
		return Denivele

	end
end

function beforeDistance(t) 
	--MessageWarning('Distance ='..tInformationInter:GetRecord():GetString("Distance"));
	if mode == 'export' then 
		--local Distance =  tonumber(tEpreuve:GetCell('Distance', 0)) * 1000;
		local Distance =  tonumber(tInformationInter:GetRecord():GetString("Distance")) * 1000;
		return math.floor(Distance)
	else
		if tonumber(t.content) > 100 then
			Distance = string.format('%.1f', tonumber(t.content)/1000.0);
		else 
			Distance = tonumber(t.content);
		end
		if string.sub(Distance, -1) == '0' then
			--MessageWarning('O detected');
			Distance = string.sub(Distance, 1, string.len(Distance)-2);
		end
		return Distance
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


function afterIntermediate(t) 
	if mode == 'export' then 
		SetAttributes(t, 'i', rResultat_Inter:GetString("Code_inter"));
	end
end

function beforeCourseIntermediate(t)
	if mode == 'export' then
		-- Neutralisation ... (Il faudrait renvoyer une table avec autant de lignes que de temps inter avec les zones "distance" ...)
		-- On renvoie ici une table vide avec par default que le final qui est en index 99 et un time
		if tInformationInter == nil then
			tInformationInter = sqlTable.Create();
			tInformationInter:AddColumn({ name = 'Index', type = sqlType.LONG, label = '' });
			tInformationInter:AddColumn({ name = 'Type_Inter', type = sqlType.TEXT, label = '' });
			tInformationInter:AddColumn({ name = 'Nom_Inter', type = sqlType.TEXT, label = '' });
			tInformationInter:AddColumn({ name = 'Distance', type = sqlType.LONG, label = '' });
			base:AddTable('tInformationInter');
		end

		-- Temps Inter ...
		for i=0, tEpreuve_Nordique:GetCellInt('Nb_temps_inter', 0, 0)-1 do
			tInformationInter:GetRecord():SetNull();
			tInformationInter:GetRecord():Set({Index = i+1, Type_Inter = 'time', Nom_Inter = 'Inter '..tostring(i+1), Distance = '0'});
			tInformationInter:AddRow();
		end
		-- Temps Final
		tInformationInter:GetRecord():SetNull();
		tInformationInter:GetRecord():Set({ Index = 99, Type_Inter = 'time', Nom_Inter = 'Finish', Distance = tEpreuve:GetCell('Distance',0)});
		tInformationInter:AddRow();
		
		MessageWarning('tInformationInter:GetNbRows() ='..tInformationInter:GetNbRows());
		return tInformationInter;
	else	
		-- if tonumber(t.attributes.i) < 99 then import = false 
		-- end
	end
end

function afterCourseIntermediate(t)
	--cmd = "select * from tInformationInter "
	--base:TableLoad(tInformationInter, cmd);
	if mode == 'export' then
	-- il faudrais mettre la valeur de les valeurs de la tables table tInformationInter ****************************************************************		
		SetAttributes(t, 'i', tInformationInter:GetRecord():GetString("Index"));
		SetAttributes(t, 'type', tInformationInter:GetRecord():GetString("Type_Inter"));
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

function synchroCompetitors(t,Status)
	if mode == 'export' then
		local cmd = 
			"Select * From Resultat"..
			" Where Code_evenement = "..Code_evenement..
			" And Tps = '"..Status..
			" ' Order By Dossard"
		;
		base:TableLoad(tResultat, cmd);
		NbCompetitors = tResultat:GetNbRows();
	t.content = NbCompetitors; 
	-- MessageWarning('synchroCompetitors '..NbCompetitors);
	end
end

function synchroCompetitorsrank(t,Status)
	if mode == 'export' then
		local cmd = 
			"Select * From Resultat"..
			" Where Code_evenement = "..Code_evenement..Status
		;
		base:TableLoad(tResultat, cmd);
		NbCompetitors = tResultat:GetNbRows();
	t.content = NbCompetitors; 
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
-- debut de la création du xml -> xmlDescription
Competitor = {
	children = {
		{ name = 'FisCode', content = contentFisCode, field = 'Resultat.Code_coureur' },
		{ name = 'Lastname', field = 'Resultat.Nom' },
		{ name = 'Firstname', field = 'Resultat.Prenom' },
		{ name = 'Gender', content = {'M', 'F'} , field = 'Resultat.Sexe', required = '0-1' },	-- >= 2.10
		{ name = 'Sex', before = beforeSex, field = 'Resultat.Sexe', required = '0-1', export = false },-- 2.1 Compatibility  --required
		{ name = 'Nation', field = 'Resultat.Nation' },		
		{ name = 'YearOfBirth', field = 'Resultat.An', required = '0-1' },
		{ name = 'ClubName', field = 'Resultat.Club', required = '0-1' },  --required
		
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
		{ name = 'StartTime', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Heure_depart', required = '0-1' },  -- heure de depart du concurent
		{ name = 'Timediff', content = Calculdiff, attributes = {{ name = 'wave', value = 'y', optional = true}}, after = afterTimediff, required = '0-1', import = false},  -- Départ en retard (poursuite), attribuer le temps des vagues pour les deniers si depart grouper
		{ name = 'TotalTime', before = synchroResultatManche, arg = 1, after = afterTotalTime, attributes = {{ name = 'TL', value = 'y', optional = true }}, field = 'Resultat_Manche.Tps_chrono' }, -- HH:MM:SS.Z(Z) Temps total de la course, attribuer le temps limite pour les épreuves par étapes / le temps net pour les courses de poursuite dans les épreuves par étapes pour le calcul des points FIS (selon l'article 2.4 du règlement des points FIS)
		{ name = 'Diff', field = 'Resultat_Manche.Diff_chrono'}, --Décalage horaire pour le temps total à l'arrivée
		{ name = 'RacePoints', field = 'Resultat.Pts' },  -- Race (FIS) points
		{ name = 'Bonustime', content = 'string', required = '0-1' },	-- Bonus de temps à l'arrivée (courses par étapes) au format horaire HH:MM:SS.Z(Z)
		{ name = 'Bonuscuppoints', content = 'string', required = '0-1' }, --Bonus cup points on finish
		{ name = 'Penaltytime', content = 'string', required = '0-1' },	-- Temps de pénalité d'une sanction au format horaire HH:MM:SS.Z(Z)
		{ name = 'Arrivalrank', content = 'string', field = 'Resultat.Clt', required = '0-1' }, -- Classement pour l'heure d'arrivée
		{ name = 'Arrivaltime', content = 'string', field = 'Resultat.Tps', required = '0-1' },	-- Heure d'arrivée (= temps total) uniquement pour les courses de poursuite dans les épreuves par étapes
		{ name = 'Arrivaldiff', content = Arrivaldiff, field = 'Resultat.Diff', required = '0-1', import = false }, -- Différence d'heure d'arrivée étape à l'arrivée
		{ name = 'Level', content = 'string', value = 'final|smallfinal|semifinal|quarterfinal|eightfinal|qualification', required = '0-1' },  -- comment mettre le niveau acqui en ko  ????????? Tour atteint (Final, Small final,1/4 final, Semifinal, Quarter final, Eight final, qualification)
		
		{ name = 'FFS_Tps1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Tps2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono', required = '0-1', export = tags_ffs }
	}
};

CC_result_notclassified = {
	children = {
		{ name = 'StartTime', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Heure_depart', required = '0-1' },  -- heure de depart du concurent
		{ name = 'Timediff', before = synchroResultatManche, arg = 2, attributes = {{ name = 'wave', value = 'y', optional = true}}, after = afterTimediff, field = 'Resultat_Manche.Diff', required = '0-1', import = false },  -- Départ en retard (poursuite), attribuer le temps des vagues je ne suis pas sure de Resultat_Manche.Diff MM:SS
		{ name = 'TotalTime', before = synchroResultatManche, arg = 1, after = afterTotalTime, attributes = {{ name = 'TL', value = 'y' }}, field = 'Resultat_Manche.Tps_chrono', required = '0-1' }, 
		{ name = 'Bonustime', content = 'string', required = '0-1' },	-- Bonus de temps à l'arrivée (courses par étapes) au format horaire HH:MM:SS.Z(Z)
		{ name = 'Bonuscuppoints', content = 'string', required = '0-1' }, --Bonus cup points on finish
		{ name = 'Penaltytime', content = 'string', required = '0-1' },	-- Temps de pénalité d'une sanction au format horaire HH:MM:SS.Z(Z)
		{ name = 'Arrivalrank', content = 'string', field = 'Resultat.Clt', required = '0-1' }, -- Classement pour l'heure d'arrivée
		{ name = 'Arrivaltime', content = 'string', field = 'Resultat.Tps', required = '0-1' },	-- Heure d'arrivée (= temps total) uniquement pour les courses de poursuite dans les épreuves par étapes
		{ name = 'Arrivaldiff', content = 'string', field = 'Resultat.Diff', required = '0-1' }, -- Différence d'heure d'arrivée à l'arrivée
		{ name = 'Level', content = 'string', value = 'final|smallfinal|semifinal|quarterfinal|eightfinal|qualification', required = '0-1' },  -- comment mettre le niveau acqui en ko  ????????? Tour atteint (Final, Small final,1/4 final, Semifinal, Quarter final, Eight final, qualification)
		
		{ name = 'FFS_Tps1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Tps2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono', required = '0-1', export = tags_ffs }
	}
};


--  a finir c'est l'envoi des temps inter
CC_resultdetail = {
	required = '0-15', children = {
		{ name = 'Intermediate', required = '0-99', after = afterIntermediate, before = beforeIntermediate, attributes = {{ name = 'i', field = 'Resultat_Inter.Code_inter', type_value = 'integer', optional = true }}, 
			children = { 
					{ name = 'Time', field = 'Resultat_Inter.Tps_chrono'},	-- Normalement pas tout optionel ...
					{ name = 'Diff', field = 'Resultat_Inter.Diff', required = '0-1' },
					{ name = 'Rank', field = 'Resultat_Inter.Clt', },
					{ name = 'SectorTime', content = 'string', required = '0-1' },
					{ name = 'SectorDiff', content = 'string', required = '0-1' },
					{ name = 'SectorRank', content = 'integer', required = '0-1' },
					{ name = 'Bonustime', content = 'integer', required = '0-1' },
					{ name = 'Bonuspoints', content = 'string', required = '0-1' },
					{ name = 'Bonuscuppoints', content = 'integer', required = '0-1' },
					{ name = 'Speed', content = 'integer', required = '0-1' }
				}
		},
		
		{ name = 'Run', required = '0-4', before = beforeRun, after = afterRun, attributes = {{ name = 'No', value = '1|2|3|tot'},  { name = 'Status', value = 'DSQ|DNS|DNF|NPS|RAL'}},
			children = {
				{ name = 'Rank', field = 'Resultat_Inter.Clt', required = '0-1' },
				{ name = 'Time', field = 'Resultat_Inter.Tps_chrono', required = '0-1' },	-- Normalement pas tout optionel ...
				{ name = 'Diff', field = 'Resultat_Inter.Diff', required = '0-1' }                                                                                 
			}
		}
	}
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
	
Statistics = {
	required = '0-9999', children = {
		{ name = 'Entries', children = {
				{ name = 'Competitors', after = synchroCompetitorsrank, arg = '', field = 'Epreuve.Nb_participants' }, 
				{ name = 'Nations', after = synchroNationrank, arg = '', required = '0-1', import = false } 
			}
		},
		{ name = 'Ranked', children = {
				{ name = 'Competitors', after = synchroCompetitorsrank, arg = ' And Tps > 0',field = 'Epreuve.Nb_classes' },
				{ name = 'Nations', after = synchroNationrank, arg = ' And Tps > 0', required = '0-1', import = false }  -- metre le nb de nation ayants des compétitor ranked
			}
		},
		{ name = 'DSQ', required = '0-1',  children = {
				{ name = 'Competitors', after = synchroCompetitors, arg = -800, required = '0-1', import = false},
				{ name = 'Nations', after = synchroNation, arg = -800, required = '0-1', import = false }
			}
		},
		{ name = 'DNS',  children = {
				{ name = 'Competitors', after = synchroCompetitors, arg = -600, required = '0-1', import = false},
				{ name = 'Nations', after = synchroNation, arg = -600, required = '0-1', import = false }
			}
		},
		{ name = 'DNF',  children = {
				{ name = 'Competitors', after = synchroCompetitors, arg = -500, required = '0-1', import = false},
				{ name = 'Nations', after = synchroNation, arg = -500, required = '0-1', import = false }
			}
		},
		{ name = 'DQB',  required = '0-1', children = {
				{ name = 'Competitors', after = synchroCompetitors, arg = -810, required = '0-1', import = false},
				{ name = 'Nations', after = synchroNation, arg = -810, required = '0-1', import = false }
			}
		},
		{ name = 'NPS',  required = '0-1', children = {
				{ name = 'Competitors', after = synchroCompetitors, arg = -610, required = '0-1', import = false},
				{ name = 'Nations', after = synchroNation, arg = -610, required = '0-1', import = false }
			}
		},
		--Nombre de concurrents et de pays ayant joué dans une course a voir si on peu faire
		{ name = 'LAP',  children = {
				{ name = 'Competitors', after = synchroCompetitors, arg = -1, import = false},
				{ name = 'Nations', after = synchroNation, arg = -1, import = false }
			}
		}
	}
};

-- fisheader
	-- version xml
	-- Réalisation du Race header
Raceheader = { 
	attributes = { 
		{name = 'Sector', value = 'CC'}, 
		{name = 'Gender', value = 'M|W|A'},
		{name = 'FFS_Homologation', value = 'OUI|NON', optional=true },
	}, 
	children = {
		{ name = 'Season', field = 'Evenement.Code_saison' },
		{ name = 'Codex', content = contentCodex, field = 'Evenement.Codex' },
		{ name = 'Nation', field = 'Evenement.Code_nation', maxlen=3 },
		{ name = 'Discipline', content = {'DI','SP','TE','Tsp','Mar','MS','PUR'}, field = 'Discipline.Code_international' },  -- field = 'Epreuve.Code_discipline' OU field = 'Discipline.Code_international' en FIS
		{ name = 'Category', field = 'Epreuve.Code_regroupement' },  --verifier les code regroupement
		{ name = 'Type', content = { 'Startlist', 'Partial' ,'Unofficial', 'Official' }, after = afterType },
		{ name = 'Training', required = '0-1', content = 'string' },
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
		{ name = 'CC_photof', required = '0-1' },  -- a verif c'est si utilisation de photo phinish
		--{ name = 'WindUnit', required = '0-1', before = function(t) t.content = 'FFS'end, field = 'Evenement.Organisateur', export = false },
		
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

-- création du CC_race
CC_race = {
	children = { 
		{ name = 'CC_raceinfo', children = {
				{ name = 'Jury', required = '0-999', before = beforeJury, attributes = {
						{ name = 'Function', value = 'CHIEFCOMPETITION|TECHNICALDELEGATE|RACEDIRECTOR|RACEDIRECTORASSISTANT|TECHNICALDELEGATEASSISTANT|TECHNICALDELEGATEASSISTANTNATIONAL|MEMBER|CHIEFTIMING|COORDINATOR'}
					},
					children = {
						--{ name = 'Number', content = contentNumber, required = '0-1' }, -- A QUOI SERT CETTE LIGNE  ?????????????????????????
						{ name = 'lastname', field = 'Evenement_Officiel.Nom' },
						{ name = 'firstname', field = 'Evenement_Officiel.Prenom' },
						{ name = 'nation', field = 'Evenement_Officiel.Nation' },
						{ name = 'Email', field = 'Evenement_Officiel.Email', required = '0-1', export = tags_ffs},
						{ name = 'Phonenbr', field = 'Evenement_Officiel.Tel_mobile', required = '0-1', export = tags_ffs },
						{ name = 'FFS_Code_coureur', field = 'Evenement_Officiel.Code_coureur', required = '0-1', export = tags_ffs},

					}, after = afterJury
				},
	-- a priori pas obligatoire en CC sauf pour les catégories WC, OWG, WSC
				-- { name = 'Member', required = '0-999', before = beforeJury, export = false, attributes = 
					-- {{ name = 'Function', value = 'ChiefRace|Referee|AssistantReferee|ChiefCourse|StartReferee|FinishReferee|ChiefTiming'}},
					-- children = {
						-- { name = 'Lastname', field = 'Evenement_Officiel.Nom' },
						-- { name = 'Firstname', field = 'Evenement_Officiel.Prenom' },
						-- { name = 'Nation', field = 'Evenement_Officiel.Nation' }
					-- }, after = afterJury
				-- },
				{ name = 'Runinfo', before = beforeRuninfo, attributes = {{ name ='No', value = '1|2', optional = true }}, 
					children = {
							{ name = 'Course',before = beforeCourse, attributes = {{ name ='No', value = '1|2'}}, 
								children = {
										{ name = 'Name', required = '0-1', field = 'Epreuve.Code_categorie' },
										{ name = 'FFS_Point_haut', field = 'Epreuve.Point_haut', export = tags_ffs, required = '0-1'},
										{ name = 'FFS_Point_bas', field = 'Epreuve.Point_bas', export = tags_ffs, required = '0-1'},			  
										{ name = 'HD', content = beforeHD, import = false },
										{ name = 'MC', field = 'Epreuve.Montee_maxi' },
										{ name = 'TC', field = 'Epreuve.Montee_tot' },
										{ name = 'Laplength', required = '0-1' },
										{ name = 'Lapnumber', field = 'Epreuve_Nordique.Nb_temps_inter' }, 
										{ name = 'Style', content = beforeStyle, field = 'Epreuve.Style'},
										--on pourras faire mieux avec une table intermediaire av la distance de chaque point *******************************************
										{ name = 'Intermediate', required = '0-99', before = beforeCourseIntermediate, after = afterCourseIntermediate, attributes = {
												{ name = 'i', type_value = 'integer' },
												{ name = 'type', value = 'time|speed' }
											}, 
											children = {
												{ name = 'Distance', content = beforeDistance, field = 'Epreuve.Distance' }
											}
										}
									},after = afterCourse
								}, 
							{ name = 'StartTime', field = 'Epreuve.Heure_depart' },
							{ name = 'EndTime', required = '0-1' },
							{ name = 'Weather', props = Weather },
							{ name = 'Statistics', props = Statistics},
						}, after = afterRuninfo
					},						
				{ name = 'UsedFisList', field = 'Evenement.Code_liste', required = '0-1' },
				{ name = 'AppliedPenalty', field = 'Epreuve.Penalite_appliquee', required = '0-1' },
				{ name = 'CalculatedPenalty', field = 'Epreuve.Penalite_calculee', required = '0-1' },
				{ name = 'Fvalue', field = 'Epreuve.Facteur_f', required = '0-1' },
				{ name = 'TimingBy', before = beforeTimingBy, field = 'Evenement_Officiel.Nom', required = '0-1' }, -- ok
				{ name = 'DataProcessingBy', before = beforeDataProcessingBy, field = 'Evenement_Officiel.Nom', required = '0-1' },
				{ name = 'Softwarecompany', import = false, content = beforeSoftwarecompany, required = '0-1' },
				{ name = 'Softwarename', import = false, content = app.GetName, required = '0-1' },
				{ name = 'Softwareversion', import = false, content = app.GetVersion, required ="0-1" },
				{ name = 'FFS_Homologation_chrono', field = 'Epreuve_Nordique.Homologation_chrono', required = '0-1', export = tags_ffs }
			}
		},

-- Création du CC_classified
		
		{ name = 'CC_classified', children = {
				{ name = 'CC_ranked', required = '0-99999', before = beforeCC_ranked,  attributes = {{name ='Status', value = 'QLF'}}, children = {
						{ name = 'Rank', attributes = {{name ='Pf', value = 'y', optional = true}}, after = afterCC_rank, field = 'Resultat.Clt', required = '0-1' },
						{ name = 'Order', field = 'Resultat.Rang', required = '0-1' },	-- voir si dans skiffs la colonne rang en M1 est rempli ?????,
						-- a verifier pour mettre la couleur de dos leader ??????????????????????????????????????????????????????????????????????????????????????
						--{ name = 'Bib', attributes = {{name ='Color', value = 'yellow|red|green|blue|white|black|turquoise|grey'}}, after = afterBib, field = 'Resultat.Dossard', required = '0-1' },	-- 2.10			
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },	-- 2.10
						{ name = 'Competitor', props = Competitor },	-- reste a verifier la construction de competitor
						{ name = 'CC_result', props = CC_result_classified }, -- reste a verifier la construction de CC_result_classified
						{ name = 'CC_resultdetail', props = CC_resultdetail } -- reste a verifier la construction de CC_resultdetail
					}, after = afterCC_ranked 
				}
			}
		},
		
		-- Création du CC_notclassified
		{ name = 'CC_notclassified', children = {
				{ name = 'CC_notranked', required = '0-99999', before = beforeCC_notranked,
					attributes = {{name = 'Status', value = 'DNS|DSQ|DNF|DPO|NPS|DQB|OUT'}},
					children =
					{
						--{ name = 'Run', content = "integer" },
						--{ name = 'Bib', attributes = {{name ='Color', value = 'yellow|red|green|blue|white|black|turquoise|grey| '}}, after = afterBib, field = 'Resultat.Dossard', required = '0-1' },	-- 2.10 
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },	-- 2.10
						{ name = 'Competitor', props = Competitor },
						{ name = 'Reason', required = '0-1', content = 'string' }, -- c'etais une demande dans le excell si on pourais avoir une zonz de saisie de disqua au lieu du numero de porte en alpin ???
						--{ name = 'CC_result', props = CC_result_notclassified },
						{ name = 'CC_resultdetail', props = CC_resultdetail }, -- reste a verifier la construction de CC_resultdetail
						{ name = 'Level', required = '0-1', content = 'string' } 
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
	attributes = { { name = 'Version', type_value = "string", optional = true }},
	children = {
		{ name = 'RaceHeader', props = Raceheader },
		{ name = 'CC_Race', props = CC_race }
	},
	after = afterFisresults
};
