-- TEST MF 16-03-2021		
-- FIS Alpine Data Exchange XML Protocol version 3.7 du 03-11-2020 => https://www.fis-ski.com/en/inside-fis/document-library/timing-data
-- verifier les code regroupement avec marlene
-- verifier les fonction beforeCourseIntermediate et afterCourseIntermediate
-- verifier le calcul de diff en M2 pour la balise Timediff ou on doit envoyer la diff de départ pour la poursuite
-- afterTotalTime à vérifier la fonction pour voir sil'atribut se met bien par rapport statu du concurent
-- en import poursuite le tps manche se met en M1 au lieu de M2


function beforeFisresults(t)
	base:SetGlobalVariable({'table', 'record'}); -- tName => table Name, rName => record Name
	
	base:SetBaseFormatChrono('FOND');
	
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
			if tEvenement:IsCellNull('Code_entite', 0) then tEvenement:SetCell('Code_entite', 0, 'FFS') end -- MF Code_entite', 0, 'FIS' remplacé par 'FFS'
			
			local codeEntite = tEvenement:GetCell('Code_entite', 0);
			if codeEntite ~= 'FFS' then codeEntite = 'FIS' end
			
--			if codeEntite == 'FIS' then
--				local codex = tEvenement:GetCell('Codex', 0);
--				if codex:len() == 4	then	
--					-- FIS, ajout du code nation
--					tEvenement:SetCell('Codex', 0, tEvenement:GetCell('Code_nation', 0)..codex);
--				end
--			end
			
			-- Verification table Epreuve - Mise de valeurs par défaut ...
			if codeEntite == 'FIS' then
				if tEpreuve:IsCellNull('Code_grille_categorie', 0) then tEpreuve:SetCell('Code_grille_categorie', 0, 'FIS-FSP') end
				if tEpreuve:IsCellNull('Code_categorie', 0) then tEpreuve:SetCell('Code_categorie', 0, '*') end
			else
				if tEpreuve:IsCellNull('Code_grille_categorie', 0) then tEpreuve:SetCell('Code_grille_categorie', 0, 'FFS-FSP') end
				if tEpreuve:IsCellNull('Code_categorie', 0) then tEpreuve:SetCell('Code_categorie', 0, '*') end
			end
			
			-- Prise de la Discipline à partir du Discipline.Code_international  -- MF retrait de ce bloc la discipline ne remontait pas
		--	local codeInter = tDiscipline:GetCell('Code_international', 0);
		--	base:TableLoad(tDiscipline, 
		--		"Select * From Discipline "..
		--		"Where Code_activite = 'FOND' "..
		--		"And Code_entite = 'FIS' "..
		--		"And Code_saison = '"..base:GetActiveSaison().."' "..
		--		"And Code_international = '"..codeInter.."' "
		--	);
		--	tEpreuve:SetCell('Code_discipline', 0, tDiscipline:GetCell('Code',0));

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


function beforeRaceheader(t) -- MF rajout de ce bloc
	if mode == 'import' then
		if t.attributes.FFS_Entite ~= nil then
			tEvenement:SetCell('Code_entite', 0, t.attributes.FFS_Entite);
		end
	end
end

function afterRaceheader(t)
	if mode == 'import' then
		-- Sexe 
		-- if t.attributes.Gender == 'W' then tEpreuve:SetCell('Sexe', 0, 'F'); RETRAIT MF
		if t.attributes.Sex == 'L' or t.attributes.Sex == 'F' then tEpreuve:SetCell('Sexe', 0, 'F'); -- AJOUT MF
		-- elseif t.attributes.Gender == 'A' then tEpreuve:SetCell('Sexe', 0, 'T'); RETRAIT mf
		elseif t.attributes.Sex == 'A' then tEpreuve:SetCell('Sexe', 0, 'T'); -- AJOUT MF
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
		--if tEpreuve:GetCell('Sexe', 0) == 'F' then t.attributes.Gender = 'W'; retrait mf
		if tEpreuve:GetCell('Sexe', 0) == 'F' then t.attributes.Sex = 'F'; -- AJOUT MF
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

function beforeCC_notranked(t) -- MF Rajout de ce bloc present en biathlon
	if mode == 'import' then
		tResultat:AddRow();
	
		local status = t.attributes.Status or 'DNS';
		rResultat_Manche:Set('Tps_chrono', status); 
		tResultat_Manche:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps <= 0');
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


-- function afterCC_rank(t)	-- MF RETRAIT de cette fonction
--	if mode == 'import' then
	-- atribut a mettre si resultats departager par camera finish ou autre moyen de departage (juge ou iphone)**************************************************** 
	-- le laisser car en FIS on a toujours un systeme de cam finish en nordique mais on ne le renseigne pas encore dans skiffs************************************
--	else
--		SetAttributes(t, 'Pf', 'y');
--	end
-- end

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
		rResultat_Manche:Set('Tps_chrono', status); -- MF question ou Tps ??
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
			SetAttributes(t, 'Status', ranking.CodeInter(tResultat_Manche:GetCellInt('Tps_chrono',0))); -- MF ou Tps ??
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
-- MF AJOUT DE CE BLOC POUR REMONTER LES OFFICIELS IDEM BIATHON
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
-- MF FIN AJOUT DE CE BLOC
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
		return base:TableLoad(tEpreuve_Alpine_Manche, 						-- COMMENTAIRE MF Pourquoi cette table
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

-- function contentFisCode(t)  MF REMPLACE PAR LE BLOC ALPIN MF Rajout de ce BLOC pris dans le LUA alpv1
	--if mode == 'import' then 
	--	return 'FIS'..t.content; 
	--else 
	--	return t.content:sub(4);
	--end 
--end

function contentFisCode(t) 
	if mode == 'import' then 
		if t.attributes ~= nil and t.attributes.FFS_Origine ~= nil then -- MF Rajout de ce BLOC pris dans le LUA alpv1 pour avoir le prefixe du code FIS
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

function afterDiscipline(t)
	if mode == 'import' then
		local codeDiscipline = t.content;

		local codeEntite = tEvenement:GetCell('Code_entite', 0);
		if codeEntite ~= 'FFS' then codeEntite = 'FIS' end
	
		base:SetBaseFormatChrono('FOND', codeEntite, codeDiscipline);
--		MessageWarning('afterDiscipline : Code_discipline='..t.content.. ', Code_entite='..codeEntite);
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
-- MF RECUP dESCRIPTIF BIATHLON
Raceheader = { 
	before = beforeRaceheader,
	
	attributes = { 
		{name = 'Sector', value = 'CC'}, 
		{name = 'Sex', value = 'M|F|L'},
		{name = 'FFS_Entite', value = 'FFS|FIS', optional = true}, -- mf RAJOUT , optional = true		
		{name = 'FFS_Homologation', value = 'OUI|NON' },


	}, children = {
		{ name = 'Season', field = 'Evenement.Code_saison' },
		{ name = 'Codex', field = 'Epreuve.Fichier_transfert' },
		{ name = 'Nation', field = 'Evenement.Code_nation', maxlen = 3 },
		{ name = 'Discipline', 
			content = {'FS','MASS','POURS-D','POURS','KO-QLF','KO','KO-2','FP','RELAIS','PATR','TEA-SP','PT'}, 
			field = 'Epreuve.Code_discipline',
			after = afterDiscipline,
		},
		
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

		{ name = 'TD', required = '0-2', children = {	-- Ignor?u profit de FFS_Officiel
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
		{ name = 'FisCode', content = contentFisCode, attributes = {{ name = 'FFS_Origine', type_value = 'string', optional=true }}, field = 'Resultat.Code_coureur' },-- MF RAJOUT de optional=true }},
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

CC_result_classified = {
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

		{ name = 'TimeRun1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono', required = '0-1' },
		{ name = 'TimeRun2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono', required = '0-1' },
		
		--{ name = 'FFS_Chrono1', before = synchroResultatManche, arg = 1, field = 'Resultat_Manche.Tps_chrono', required = '0-1' }, -- MF la balise FFS_chrono1 n exite pas resultat FIS fond
		--{ name = 'FFS_Chrono2', before = synchroResultatManche, arg = 2, field = 'Resultat_Manche.Tps_chrono', required = '0-1' },

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

CC_race = {
	children = { 
		{ name = 'CC_raceinfo', children = {
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
		
		{ name = 'CC_classified', children = {
				{ name = 'CC_ranked', required = '0-99999', before = beforeCC_ranked, 
						attributes = {{name = 'Status', value = 'QLF'}},
						children = {
						{ name = 'Rank', field = 'Resultat.Clt', required = '0-1' },
						{ name = 'Order', field = 'Resultat.Rang', required = '0-1' },
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },
						{ name = 'Competitor', props = Competitor },
						{ name = 'CC_result', props = CC_result_classified },
					}, after = afterCC_ranked 
				}
			}
		},
		{ name = 'CC_notclassified', children = {
				{ name = 'CC_notranked', required = '0-99999', before = beforeCC_notranked,
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
					after = afterCC_notranked
				}
			}
		}
	}
};



-- FIN RECUP BIATHLON

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
