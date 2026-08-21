-- Verification des Compétitions Alpines par Philippe Guérindon
dofile('./edition/functionPG.lua');

local function CreateTablePortesDenivele()
	local tPortes_Denivele = sqlTable.Create("Portes_Denivele");
	tPortes_Denivele:AddColumn({ name = "Code_saison", label = "Code_saison", type = sqlType.CHAR, size = 6 });
	tPortes_Denivele:AddColumn({ name = "Code_activite", label = "Code_activite", type = sqlType.CHAR, size = 8 });
	tPortes_Denivele:AddColumn({ name = "Code_discipline", label = "Code_discipline", type = sqlType.CHAR, size = 10});
	tPortes_Denivele:AddColumn({ name = "Code_entite", label = "Code_entite", type = sqlType.CHAR, size = 6});
	tPortes_Denivele:AddColumn({ name = "Code_niveau", label = "Code_niveau", type = sqlType.CHAR, size = 8});
	tPortes_Denivele:AddColumn({ name = "Code_categ", label = "Code_categ", type = sqlType.CHAR, size = 20});
	tPortes_Denivele:AddColumn({ name = "Sexe", label = "Sexe", type = sqlType.CHAR, size = 1});
	tPortes_Denivele:AddColumn({ name = "VD_mini", label = "VD_mini", type = sqlType.LONG, style = sqlStyle.NULL });
	tPortes_Denivele:AddColumn({ name = "VD_maxi", label = "VD_maxi", type = sqlType.LONG, style = sqlStyle.NULL });
	tPortes_Denivele:AddColumn({ name = "Mini", label = "Mini", type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tPortes_Denivele:AddColumn({ name = "Maxi", label = "Maxi", type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tPortes_Denivele:AddColumn({ name = "Plus_moins", label = "Plus_moins", type = sqlType.LONG, style = sqlStyle.NULL });
	tPortes_Denivele:SetPrimary('Code_saison, Code_activite, Code_discipline, Code_entite, Code_niveau, Code_categ, Sexe');
	tPortes_Denivele:SetName('Portes_Denivele');
	local strCreate = tPortes_Denivele:GetStringCreate(base);
	if strCreate then
		base:Query(strCreate);
	end
	ReplaceTableEnvironnement(tPortes_Denivele, 'Portes_Denivele');
end

function SetEquivalenceFonctions(params)
	local p = params;
	tFonction = {};
	tFonction.TechnicalDelegate = {SqlMinimum = 'DelegueTechniqueFederalAlpin', Minimum = 'Délégué Technique Fédéral Alpin', Fonction = 'Délégué Technique Fédéral Alpin', api_function="DelegueTechnique"};
	tFonction.TechnicalDelegateAssistant = {SqlMinimum = 'DelegueTechniqueFederalAlpin', Minimum = 'Délégué Technique Fédéral Alpin', Fonction = 'Délégué Technique Fédéral Alpin Assistant', api_function="DelegueTechnique"};
	tFonction.Referee = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = 'Arbitre', api_function="Arbitre"};
	tFonction.AssistantReferee = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = 'Arbitre assistant', api_function="Arbitre"};
	tFonction.ChiefRace = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = 'Directeur d\'épreuve', api_function="DirecteurEpreuve"};
	tFonction.ChiefCompetition = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = 'Directeur d\'épreuve', api_function=''};
	tFonction.TraceurFederal = {SqlMinimum = 'TraceurFederal', Minimum = 'Traceur Fédéral', Fonction = 'Traceur', api_function="Traceur" };
	tFonction.TraceurFederalExpert = {SqlMinimum = 'TraceurFederalExpert', Minimum = 'Traceur Fédéral Expert', Fonction = 'Traceur', api_function="Traceur"};
	tFonction.ChiefTiming = {SqlMinimum = 'Chronometreur', Minimum = 'Chronométreur', Fonction = 'Chef des calculs', api_function=''};
	tFonction.TimingBy = {SqlMinimum = 'Chronometreur', Minimum = 'Chronométreur', Fonction = 'Chronométreur', api_function=''};
	tFonction.ffs_chef_controleur = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = 'Chef contrôleur', api_function=''};
	tFonction.StartReferee = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = 'Juge au départ', api_function=''};
	tFonction.ffs_juge_start = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = 'Juge au départ', api_function=''};
	tFonction.FinishReferee = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = "Juge à l'arrivée", api_function=''};
	tFonction.ffs_juge_stop = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = "Juge à l'arrivée", api_function=''};
	tFonction.ffs_chr_manuel_start = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = 'Doublage manuel départ', api_function=''};
	tFonction.ffs_chr_manuel_stop = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = 'Doublage manuel arrivée', api_function=''};
	tFonction.ffs_chr_manuel_B = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Chonométreur', Fonction = 'Chronométreur Système B', api_function=''};
	tFonction.ffs_chr_starter = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = "Starter", api_function=''};
	tFonction.ffs_juge_porte = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = "Juge de porte", api_function=''};
	tFonction.ffs_juge_porte = {SqlMinimum = 'JugeCompetitionAlpin', Minimum = 'Juge de compétition', Fonction = "Juge de porte", api_function=''};
	p.tFonction = tFonction;
	return p;
end

function ChargeOfficiels(file, p)
	local tEvenement_Officiel = base:GetTable('_Evenement_Officiel')
	local filter = "$(licence_numero):In('-1'"
	for row = 0, tEvenement_Officiel:GetNbRows() -1 do
		filter = filter..",'"..tEvenement_Officiel:GetCell('Code_coureur', row):sub(4).."'";
	end
	filter = filter..')';
	local licence = tEvenement_Officiel:GetCell('Code_coureur', row);
	local tofficiels_comite = {};
	local header = true;
	local utf8 = true;
	local tOfficiels_ALP = sqlTable.ImportCSV(file, ';', header, utf8);
	if tOfficiels_ALP ~= nil then
		adv.Success('Téléchargement des Officiels du Comité '..p.comite..' réussi ('..tOfficiels_ALP:GetNbRows()..' lignes)');
		tOfficiels_ALP:Filter(filter, true);
		for i = 0, tOfficiels_ALP:GetNbRows() -1 do
			local licence = 'FFS'..	tOfficiels_ALP:GetCell(0,i);
			local appelation = tOfficiels_ALP:GetCell(1,i);
			local annee = tonumber(tOfficiels_ALP:GetCell(2,i)) or 0;
			tofficiels_comite[licence] = tofficiels_comite[licence] or {};
			tofficiels_comite[licence][appelation] = {};
			tofficiels_comite[licence][appelation].Annee = annee;
		end
		for row = 0, tEvenement_Officiel:GetNbRows() -1 do
			local licence = tEvenement_Officiel:GetCell('Code_coureur', row);
			local diplome_verifie = tEvenement_Officiel:GetCell('Diplome_verifie', row);
			if type(tofficiels_comite[licence]) == 'table' then
				if type(tofficiels_comite[licence][diplome_verifie]) == 'table' then
					local annee = tofficiels_comite[licence][diplome_verifie].Annee;
					tEvenement_Officiel:SetCell('Annee', row, annee);
				end
			end
		end
		tOfficiels_ALP:Delete();
	end
end

function Check_piste(params)
    local p = params;
	local reponse = 'La piste ';
	local ajouter = 0;
	local ctrlPiste = true;
	local saison_short = p.saison_num - 2000;   -- pour la saison 2025 => 25
	if p.code_discipline:In('SG', 'DH') then
		ajouter = 5;
	else
		ajouter = 10;
	end
	local tPistes = base:GetTable('Pistes');
	if p.matricule_piste > 0 then
		local r = tPistes:GetIndexRow('Matricule', p.matricule_piste);
		if r >= 0 then
			local bolDateValide = true;
			local nom_station = tPistes:GetCell('Nom_station', r);
			local nom_piste = tPistes:GetCell('Nom_piste', r);
			reponse = reponse..nom_piste;
			local homologation_ffs = tPistes:GetCell('Homologation_ffs', r);
			local validite_ffs = tonumber(string.sub(homologation_ffs, -2)) or 0;
			validite_ffs = 2000 + validite_ffs + ajouter;
			local homologation_fis = tPistes:GetCell('Homologation_fis', r);
			local validite_fis = tonumber(string.sub(homologation_fis, -2)) or 0;
			validite_fis = 2000 + validite_fis + ajouter;
			local piste_discipline = tPistes:GetCell('Discipline', r);
			local piste_categorie = tPistes:GetCell('Categorie', r);
			local piste_sexe = tPistes:GetCell('Sexe', r);
			local string_sexe = '';
			if piste_sexe == 'D' then
				piste_sexe = 'F';
			elseif piste_sexe == 'H' then
				piste_sexe = 'M';
			else
				piste_sexe = 'M F';
			end
			if piste_discipline ~= p.code_discipline then
				reponse = reponse.." n'est pas homologuée en "..p.code_discipline.. " !!";
				return false, reponse;
			end
			if piste_sexe ~= 'M F' then
				local chkSexe = true;
				for i = 0, tEpreuve:GetNbRows() -1 do
					if piste_sexe ~= tEpreuve:GetCell('Sexe',i) then 
						chkSexe = false;
						if piste_sexe == 'D' then
							string_sexe = 'Dames';
						else
							string_sexe = 'Hommes';
						end
						break;
					end
				end
				if chkSexe == false then
					reponse = reponse.." n'est pas homologuée pour les "..string_sexe.. " !!";
					return false, reponse;
				end
			end
			if p.code_entite == 'FFS' then
				if validite_ffs < saison_short then
					reponse = reponse.." n'est plus homologuée ("..(2000+saison_short)..')';
					ctrlPiste = false;
					p.OK = false;
				else
					reponse = reponse..' est homologuée et valide en '..piste_discipline;
				end
			else
				if validite_fis < saison_short then
					reponse = reponse.." n'est plus homologuée ("..(2000+saison_short)..')';
					p.OK = false;
					ctrlPiste = false;
				else
					reponse = reponse..' est homologuée et valide en '..piste_discipline;
				end
			end
			if piste_categorie:len() > 1 then
				reponse = reponse.." jusqu'aux "..piste_categorie;
			end
			if p.code_entite == 'FFS' then
				reponse = reponse.. ' ('..homologation_ffs..')';
			else
				reponse = reponse.. ' ('..homologation_fis..')';
			end
		end
	else
		reponse = "La piste utilisée n'existe pas dans la table des pistes";
		ctrlPiste = false;
		p.OK = false;
	end
	return ctrlPiste, reponse;
end

function GetESF(nom, prenom)
	local esf = '';
	local cmd = 'Select * From Moniteur Where Nom = "'..nom..'" And Prenom = "'..prenom..'" And Statut = "ACTIF"';
	local tMoniteur = base:GetTable('Moniteur');
	base:TableLoad(tMoniteur, cmd);
	if tMoniteur:GetNbRows() == 1 then
		esf = tMoniteur:GetCell('Ecole', 0);
	end
	return esf;
end

function Check_officiels(params)
	local p = params;
	local reponse = '';
	local bolOK = true;
	local tEvenement_Officiel = base:GetTable('_Evenement_Officiel');
	tEvenement_Officiel:OrderBy('Ordre');
	local index = 0;
	for i = 0, tEvenement_Officiel:GetNbRows() -1 do
		tEvenement_Officiel:SetCell('Diplome_ok', i, -2);
		local esf = GetESF(tEvenement_Officiel:GetCell('Nom', i), tEvenement_Officiel:GetCell('Prenom', i))
		local moniteur = '';
		local resultat = '';
		if esf:len() > 0 then
			moniteur = " ["..esf..']';
		end
		local code_coureur = tEvenement_Officiel:GetCell('Code_coureur', i);
		local identite = tEvenement_Officiel:GetCell('Prenom', i)..' '.. tEvenement_Officiel:GetCell('Nom', i);
		local libelle = '';
		local manche = tEvenement_Officiel:GetCell('Manche', i);
		local fonction = tEvenement_Officiel:GetCell('Fonction', i);
		local nation = tEvenement_Officiel:GetCell('Nation', i);
		local comite = tEvenement_Officiel:GetCell('Comite', i);
		local diplome_verifie = tEvenement_Officiel:GetCell('Diplome_verifie', i);
		local diplome_verifie_fr = tEvenement_Officiel:GetCell('Diplome_verifie_fr', i);
		local api_function = tEvenement_Officiel:GetCell('Api_function', i);
		local ordre = tEvenement_Officiel:GetCellInt('Ordre', i);
		local annee = tEvenement_Officiel:GetCellInt('Annee', i);;
		-- adv.Alert('fonction : '..fonction..', diplome_verifie : '..diplome_verifie..', annee = '..annee..', nation = '..nation..', comite = '..comite);
		if nation == 'FRA' then
			if p.comite_controle then
				if comite == p.comite_controle then
					if annee > 0 then
						if annee >= p.saison_num then
							tEvenement_Officiel:SetCell('Diplome_ok', i, 1);
							resultat = 'a son diplôme de '..tEvenement_Officiel:GetCell('Diplome_verifie_fr', i)..' valide ('..annee..')'..moniteur;
						else
							tEvenement_Officiel:SetCell('Diplome_ok', i, 0);
							resultat = 'a son diplôme de '..tEvenement_Officiel:GetCell('Diplome_verifie_fr', i)..' invalide ('..annee..')'..moniteur;
						end
					else
						if ordre >= 100 then
							resultat = "N'est pas traceur Fédéral"..moniteur;
						else
							resultat = "n'est pas un officiel connu du Comité";
							tEvenement_Officiel:SetCell('Diplome_ok', i, 0);
						end
						if p.code_discipline:In('SG', 'DH') then
							if fonction:In('TechnicalDelegate', 'Referee', 'AssistantReferee', 'ChiefRace', 'TraceurFederalExpert') then
								resultat = resultat;
								tEvenement_Officiel:SetCell('Diplome_ok', i, -1);
							end
						else
							if fonction:In('TechnicalDelegate', 'Referee', 'ChiefRace', 'TraceurFederal') then
								resultat = resultat;
								tEvenement_Officiel:SetCell('Diplome_ok', i, -1);
							end
						end
						if api_function:len() > 0 then
							local rc, jsonText = sqlBase.WS_FFS_Official(string.sub(code_coureur,4), 'AL', api_function);
							if rc > 0 then
								resultat = "Contrôlé et vérifié par l'API";
								tEvenement_Officiel:SetCell('Diplome_ok', i, 1);
							end
						end
					end
				else
					resultat = "n'est pas "..diplome_verifie_fr;
					tEvenement_Officiel:SetCell('Diplome_ok', i, 0);
					if p.code_discipline:In('SG', 'DH') then
						if fonction:In('TechnicalDelegate', 'Referee', 'AssistantReferee', 'ChiefRace', 'TraceurFederalExpert') then
							resultat = resultat;
							tEvenement_Officiel:SetCell('Diplome_ok', i, -1);
						end
					else
						if fonction:In('TechnicalDelegate', 'Referee', 'ChiefRace', 'TraceurFederal') then
							resultat = resultat;
							tEvenement_Officiel:SetCell('Diplome_ok', i, -1);
						end
					end
					if api_function:len() > 0 then
						local rc, jsonText = sqlBase.WS_FFS_Official(string.sub(code_coureur,4), 'AL', api_function);
						if rc > 0 then
							resultat = "Hors Comite - Contrôlé et vérifié par l'API";
							tEvenement_Officiel:SetCell('Diplome_ok', i, 1);
						end
					end
				end
			else	-- français et hors comité
				resultat = "n'est pas "..diplome_verifie_fr;
				tEvenement_Officiel:SetCell('Diplome_ok', i, 0);
				if api_function:len() > 0 then
					local rc, jsonText = sqlBase.WS_FFS_Official(string.sub(code_coureur,4), 'AL', api_function);
					if rc > 0 then
						resultat = "Contrôlé et vérifié par l'API";
						tEvenement_Officiel:SetCell('Diplome_ok', i, 1);
					end
				else
					resultat = "Diplôme non vérifié par l'API";
				end
			end
		else
			resultat = "officiel étranger, vérification impossible";
			tEvenement_Officiel:SetCell('Diplome_ok', i, -1);
		end
		if p.code_entite == 'FIS' then
			if ordre == 1 then
				tEvenement_Officiel:SetCell('Diplome_ok', i, 1);
				resultat = "Le diplome de Délégué Technique FIS n'est jamais vérifié.";
			end
		end
		tEvenement_Officiel:SetCell('Resultat_controle', i, resultat);
	end
	return p;
end

local function CheckListe(p)
	local tEpreuve = base:GetTable('_Epreuve');
	local type_classement = 'IAU';
	if p.code_entite == 'FFS' then
		type_classement = 'FAU';
	end
	local tListe = base:GetTable('_Liste');
	local cmd = 'SELECT * FROM Liste WHERE Code_liste = '..p.code_liste.." AND Type_classement = '"..type_classement.."'";
	base:TableLoad(tListe, cmd);
	local date_epreuve = tEpreuve:GetCell('Date_epreuve', 0, "%4Y%2M%2D");
	local valid_from = tListe:GetCell('Validfrom', 0, "%4Y%2M%2D");
	local valid_to = tListe:GetCell('Validto', 0, "%4Y%2M%2D");
	if tListe:GetNbRows() > 0 then
		if date_epreuve < valid_from or date_epreuve > valid_to then
			date_epreuve = tEpreuve:GetCell('Date_epreuve', 0);
			valid_from = tListe:GetCell('Validfrom', 0);
			valid_to = tListe:GetCell('Validto', 0);
			return false, string.format(
				"Erreur sur la liste utilisée ("..p.nom_liste..") pour la date de la course  : %s\nValide du %s au %s",
				date_epreuve, valid_from, valid_to)
		else
			date_epreuve = tEpreuve:GetCell('Date_epreuve', 0);
			valid_from = tListe:GetCell('Validfrom', 0);
			valid_to = tListe:GetCell('Validto', 0);
			return true, string.format(
				"La liste utilisée est la bonne pour la date de la course : %s\nValide du %s au %s",
				date_epreuve, valid_from, valid_to)
		end
	else
		return false, string.format(
			"La liste %s utilisée pour la date de la course n'est pas chargée dans la base",
			p.nom_liste)
	end
end

function Check_portes(p, run, row_epreuve, sexe, code_discipline, code_categorie, changement_de_directions)
	local ctrl_ok = 0;
	local tEpreuve = base:GetTable('_Epreuve');
	local tPortes_Denivele = base:GetTable('Portes_Denivele');
	local resultat_portes = '';
	local cmd = "SELECT * FROM Portes_Denivele"..
        " WHERE Code_saison  = '"..p.code_saison.."'"..
        " AND Code_activite = 'ALP'"..
        " AND Code_niveau = '"..p.code_niveau.."'"..
        " AND Code_discipline = '"..code_discipline.."'"..
        " AND Code_entite = '"..p.code_entite.."'"..
        " AND Code_categ = '"..code_categorie.."'"..
        " AND Sexe = '"..sexe.."'";
    base:TableLoad(tPortes_Denivele, cmd);
	-- adv.Alert(cmd);
    if tPortes_Denivele:GetNbRows() == 0 then
		resultat_portes = string.format(
			"Catégorie : %s, Sexe : %s, Dénivelé : %dm \nAucune règle trouvée pour la discipline %s",
			code_categorie, sexe, p.denivele, code_discipline)
		tEpreuve:SetCell('Resultat_portes'..run, row_epreuve, resultat_portes);
		tEpreuve:SetCell('Ctrl_ok'..run, row_epreuve, ctrl_ok);
		return;
	end
	local saut_de_ligne = '';

    local mini_pourcent = tPortes_Denivele:GetCellDouble('Mini', 0);
    local maxi_pourcent = tPortes_Denivele:GetCellDouble('Maxi', 0, -1);
	
	local mini = math.floor(p.denivele * mini_pourcent )
	local maxi = math.ceil(p.denivele * maxi_pourcent );
    local plus_moins = tPortes_Denivele:GetCellInt('Plus_moins', 0);
	local strplus_moins = ' ±'..plus_moins;
	if plus_moins == 0 then
		strplus_moins = '';
	end
	tEpreuve:SetCell('Denivele'..run, row_epreuve, p.denivele);
	tEpreuve:SetCell('VD_mini'..run, row_epreuve, tPortes_Denivele:GetCellInt('VD_mini', 0));
	tEpreuve:SetCell('VD_maxi'..run, row_epreuve, tPortes_Denivele:GetCellInt('VD_maxi', 0));
	tEpreuve:SetCell('Mini'..run, row_epreuve, mini);
	tEpreuve:SetCell('Maxi'..run, row_epreuve, maxi);
	tEpreuve:SetCell('Maxi'..run, row_epreuve, maxi);
	tEpreuve:SetCell('Changements_direction'..run, row_epreuve, maxi);
	tEpreuve:SetCell('Plage_denivele'..run, row_epreuve, '['..tPortes_Denivele:GetCellDouble('Mini', 0)..'-'..tPortes_Denivele:GetCellDouble('Maxi', 0)..']');
	tEpreuve:SetCell('Plage_portes'..run, row_epreuve, '['..mini..'-'..maxi..']');

	local plage_denivele = ' ['..tPortes_Denivele:GetCellInt('VD_mini', 0)..'-'..tPortes_Denivele:GetCellInt('VD_maxi', 0)..']';

    if changement_de_directions < mini - plus_moins then
		resultat_portes = string.format(
			"Catégorie : %s, Sexe : %s, Dénivelé : %dm %s \n ERREUR !!! -  %d changements de direction < Minimum (%d) "..strplus_moins..' pour la discipline %s',
			code_categorie, sexe, p.denivele, plage_denivele,
			changement_de_directions, mini-plus_moins, code_discipline
			);
		--adv.Alert('mini '..resultat_portes);
		tEpreuve:SetCell('Plage_portes'..run, row_epreuve, '['..mini..'-'..maxi..']');
		tEpreuve:SetCell('Resultat_portes'..run, row_epreuve, resultat_portes);
		tEpreuve:SetCell('Ctrl_ok'..run, row_epreuve, ctrl_ok);
		return;
	end

    if maxi > 0 and changement_de_directions > maxi + plus_moins then
		resultat_portes = string.format(
			"Catégorie : %s, Sexe : %s, Dénivelé : %dm %s\n ERREUR !!! -  %d changements de direction > Maximun (%d) "..strplus_moins..' pour la discipline %s',
			code_categorie, sexe, p.denivele, plage_denivele,
			changement_de_directions, maxi+plus_moins, code_discipline
			);

		tEpreuve:SetCell('Resultat_portes'..run, row_epreuve, resultat_portes);
		tEpreuve:SetCell('Ctrl_ok'..run, row_epreuve, ctrl_ok);
		return;
    end

	ctrl_ok = 1;
	if maxi > 0 then
		resultat_portes = string.format(
			"Catégorie : %s, Sexe : %s, Dénivelé : %dm %s\nIl a %d changements de direction dans la plage [%d-%d] "..strplus_moins..' pour la discipline %s',
			code_categorie, sexe, p.denivele, plage_denivele,
			changement_de_directions, mini, maxi, code_discipline
			);
		--adv.Alert(resultat_portes);
		tEpreuve:SetCell('Resultat_portes'..run, row_epreuve, resultat_portes);
		tEpreuve:SetCell('Ctrl_ok'..run, row_epreuve, 1);
		return;
	else
		resultat_portes = string.format(
			"Catégorie : %s, Sexe : %s, Dénivelé : %dm %s\nIl a %d changements de direction, [minimum : %d] "..strplus_moins..' pour la discipline %s',
			code_categorie, sexe, p.denivele, plage_denivele,
			changement_de_directions, mini, code_discipline
			);
		--adv.Alert(resultat_portes);
		tEpreuve:SetCell('Resultat_portes'..run, row_epreuve, resultat_portes);
		tEpreuve:SetCell('Ctrl_ok'..run, row_epreuve, 1);
		return;
	end
end

function ShowdlgMessage(p)
	local message = 'Les officiels du comité '..p.comite..' sont\nen cours de téléchargement';
	dlgMessage = wnd.CreateDialog(
		{
		width = 400,
		height = 200,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		x = (display:GetSize().width / 2) - 150,
		y = 400,
		label='Téléchargement des officiels en cours.', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgMessage:LoadTemplateXML({ 
		xml = "./process/verification_alpin.xml",
		node_name = 'root/panel', 			
		node_attr = 'name', 				
		node_value = 'message'	
	});
	dlgMessage:GetWindowName("lbl_message"):SetLabel(message);
	dlgMessage:Show();
end

function verifAlpin(params)
	local p = params;
	local tPortes_Denivele = base:GetTable('Portes_Denivele');
	if not tPortes_Denivele then
		CreateTablePortesDenivele();
		app.GetAuiFrame():MessageBox(
			"La base de donnée a nécessité la modification d'une table'.\nLe script va se fermer automatiquement.\nVous devrez quitter complètement skiFFS et relancer le programme.", 
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
		return "La table tPortes_Denivele a été crée";
	end
	p.diplome_api = "'TechnicalDelegate', 'Referee', 'AssistantReferee', 'ChiefRace', 'TraceurFederal', 'TraceurFederalExpert'";
	p.OK = true;
	local tComite = {};
	tComite.MB = {};
	tComite.MB.URL = "https://agilsport.fr/bta_alpin/Comite_MB/officiels_ALP.csv";
	script_version = 2026.04;
	indice_return = 16;
	local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'

	local tMoniteur = base:GetTable('Moniteur');
	local tEvenement = base:GetTable('Evenement');
	local tCoureur = base:GetTable('Coureur');
	local tEpreuve = base:GetTable('Epreuve');
	local tEpreuve_Alpine_Manche = base:GetTable('Epreuve_Alpine_Manche');
	local tEvenement_Officiel = base:GetTable('Evenement_Officiel');
	local tPistes = base:GetTable('Pistes');
	local tListe = base:GetTable('Liste');

	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..p.code_evenement);
	p.code_activite = tEvenement:GetCell('Code_activite', 0);
	p.nom = tEvenement:GetCell('Nom', 0)..' - Codex : '..tEvenement:GetCell('Codex', 0);
	p.code_entite = tEvenement:GetCell('Code_entite', 0);
	p.code_liste = tEvenement:GetCellInt('Code_liste', 0);
	p.nom_liste = p.code_entite..'-ALP'..p.code_liste..'.EXE';

	tListe:AddColumn({ name = 'Resultat_liste', type = sqlType.TEXT, width = 5, style = sqlStyle.NUL});
	ReplaceTableEnvironnement(tListe, '_Liste');
	
	tEvenement_Officiel:AddColumn({ name = 'Comite', type = sqlType.TEXT, width = 5, style = sqlStyle.NUL});
	tEvenement_Officiel:AddColumn({ name = 'Fonction_fr', type = sqlType.TEXT, width = 30, style = sqlStyle.NUL});
	tEvenement_Officiel:AddColumn({ name = 'Diplome_verifie', type = sqlType.TEXT, width = 30, style = sqlStyle.NUL});
	tEvenement_Officiel:AddColumn({ name = 'Diplome_verifie_fr', type = sqlType.TEXT, width = 30, style = sqlStyle.NUL});
	tEvenement_Officiel:AddColumn({ name = 'Api_function', type = sqlType.TEXT, width = 30, style = sqlStyle.NUL});
	tEvenement_Officiel:AddColumn({ name = 'Annee', type = sqlType.LONG, style = sqlStyle.NULL });
	tEvenement_Officiel:AddColumn({ name = 'Manche', type = sqlType.TEXT, width = 5, style = sqlStyle.NUL});
	tEvenement_Officiel:AddColumn({ name = 'Resultat_controle',  type = sqlType.TEXT, width = 255, style = sqlStyle.NUL});
	tEvenement_Officiel:AddColumn({ name = 'Diplome_ok', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tEvenement_Officiel, '_Evenement_Officiel');

	tEpreuve_Alpine_Manche:AddColumn({ name = 'Resultat_controle', type = sqlType.TEXT, width = 250, style = sqlStyle.NUL});
	tEpreuve_Alpine_Manche:AddColumn({ name = 'Ctrl_ok', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tEpreuve_Alpine_Manche, '_Epreuve_Alpine_Manche');

	base:TableLoad(tEpreuve_Alpine_Manche, 'Select * From Epreuve_Alpine_Manche Where Code_evenement = '..p.code_evenement.. ' Order By Code_manche');
	p.nombre_de_manche = tEpreuve_Alpine_Manche:GetNbRows();
	p.matricule_piste = tEpreuve_Alpine_Manche:GetCellInt('Code_piste', 0);

	for run = 1, p.nombre_de_manche do
		tEpreuve:AddColumn({ name = 'Denivele'..run, type = sqlType.LONG, style = sqlStyle.NULL });
		tEpreuve:AddColumn({ name = 'VD_mini'..run, type = sqlType.LONG, style = sqlStyle.NULL });
		tEpreuve:AddColumn({ name = 'VD_maxi'..run, type = sqlType.LONG, style = sqlStyle.NULL });
		tEpreuve:AddColumn({ name = 'Mini'..run, type = sqlType.LONG, style = sqlStyle.NULL });
		tEpreuve:AddColumn({ name = 'Maxi'..run, type = sqlType.LONG, style = sqlStyle.NULL });
		tEpreuve:AddColumn({ name = 'Changements_direction'..run, type = sqlType.LONG, style = sqlStyle.NULL });
		tEpreuve:AddColumn({ name = 'Plage_denivele'..run, type = sqlType.TEXT, width = 30, style = sqlStyle.NUL});
		tEpreuve:AddColumn({ name = 'Plage_portes'..run, type = sqlType.TEXT, width = 30, style = sqlStyle.NUL});
		tEpreuve:AddColumn({ name = 'Resultat_portes'..run, type = sqlType.TEXT, width = 250, style = sqlStyle.NUL});
		tEpreuve:AddColumn({ name = 'Ctrl_ok'..run, type = sqlType.LONG, style = sqlStyle.NULL });
	end
	ReplaceTableEnvironnement(tEpreuve, '_Epreuve');

	tPistes:AddColumn({ name = 'Resultat_piste', type = sqlType.TEXT, width = 250, style = sqlStyle.NUL});
	ReplaceTableEnvironnement(tPistes, '_Pistes');
	
	tEvenement_Officiel = base:TableLoad('Select * From Evenement_Officiel Where Code_evenement = '..p.code_evenement..' Order By Ordre');
	for i = 0, tEvenement_Officiel:GetNbRows() -1 do
		tEvenement_Officiel:SetCell('Diplome_ok', i, -1);
	end
	
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..p.code_evenement);
	p.code_niveau = tEpreuve:GetCell('Code_niveau', 0);
	p.code_discipline = tEpreuve:GetCell('Code_discipline', 0);
	p.code_saison = tEpreuve:GetCell('Code_saison', 0);
	p.saison_num = tonumber(p.code_saison) or 0;
	if p.code_saison:len() == 0 then
		p.code_saison = tostring(math.floor(script_version));
	end
	
	
	base:TableLoad(tPiste, 'Select * From Pistes');
	
	local cmd = "SELECT * FROM Portes_Denivele WHERE Code_saison  = '"..p.code_saison.."'";
	if p.saison_num >= 2026 then
		base:TableLoad(tPortes_Denivele, cmd);
		if tPortes_Denivele:GetNbRows() == 0 then
			local fichier_txt = app.GetPath().."/tmp/"..p.code_saison.."_Portes_denivele.txt";
			fichier_txt = string.gsub(fichier_txt, app.GetPathSeparator(), "/");
			if not app.FileExists(fichier_txt) then
				local txt_file_url = "https://agilsport.fr/bta_alpin/BTN/"..p.code_saison.."_Portes_Denivele.txt";
				if curl.DownloadFile(txt_file_url, fichier_txt) == true then
					adv.Success("Saison "..p.code_saison.." - Nombre de portes / dénivelé téléchargé");
					dofile(fichier_txt);
					for i = 1 , #tcmd do
						local cmd = tcmd[i];
						base:Query(cmd);
					end
				else
					app.GetAuiMessage():AddLine("Erreur dans le chargement du nombre de portes / dénivelé");
				end
			else
				local fichier_txt = app.GetPath().."/tmp/"..p.code_saison.."_Portes_denivele.txt";
				fichier_txt = string.gsub(fichier_txt, app.GetPathSeparator(), "/");
				dofile(fichier_txt);
				for i = 1 , #tcmd do
					local cmd = tcmd[i];
					base:Query(cmd);
				end
			end
		end
	else
		tPortes_Denivele:RemoveAllRows();
	end

	local bolOK = true;
	if p.code_entite == 'FIS' then
		p.categ = "*";
		if p.code_niveau:In('WC','OWKG','WC-COM') then
			p.code_niveau = 'WC';
		elseif p.code_niveau:In('EC','EQA') then
			p.code_niveau = 'EC';
		elseif p.code_niveau:In('CIT','FIS','NC') then
			p.code_niveau = 'FIS';
		elseif p.code_niveau:In('ENL') then
			p.code_niveau = 'ENL';
		else
			bolOK = false;
		end
	end
	p.comite = tEvenement:GetCell('Code_comite', 0);
	p.codex = tEpreuve:GetCell('Fichier_transfert', 0);
	p.date = tEpreuve:GetCell('Date_epreuve', 0);

	p.national = false;
	if p.codex:sub(1,3) == 'ANA' then
		p.national = true;
	end
	p = SetEquivalenceFonctions(p);
	tEvenement_Officiel = base:GetTable('Evenement_Officiel');
	local ordre = 100;
	-- rajoute les traceurs dans tEvenement_Officiel M1 : Ordre 100, M2 : Ordre 101
	for manche = 1, p.nombre_de_manche do
		local code_traceur = 'FFS'..tEpreuve_Alpine_Manche:GetCell('Matricule_traceur', manche-1);
		local prenom = tEpreuve_Alpine_Manche:GetCell('Prenom_traceur', manche-1);
		local nom = tEpreuve_Alpine_Manche:GetCell('Nom_traceur', manche-1);
		local nation = tEpreuve_Alpine_Manche:GetCell('Code_nation', manche-1);
		local row = tEvenement_Officiel:AddRow();
		tEvenement_Officiel:SetCell('Code_evenement', row, p.code_evenement);
		tEvenement_Officiel:SetCell('Code_epreuve', row, 1);
		tEvenement_Officiel:SetCell('Ordre', row, ordre);
		tEvenement_Officiel:SetCell('Code_coureur', row, code_traceur);
		tEvenement_Officiel:SetCell('Nom', row, nom);
		tEvenement_Officiel:SetCell('Prenom', row, prenom);
		tEvenement_Officiel:SetCell('Manche', row, ' M'..manche);
		if p.code_discipline:In('SG', 'DH') then
			tEvenement_Officiel:SetCell('Fonction', row, 'TraceurFederalExpert');
		else
			tEvenement_Officiel:SetCell('Fonction', row, 'TraceurFederal');
		end
		if nation:In('AP','AU','CA','CO','DA','IF','MB','MJ','MV','SA') then
			tEvenement_Officiel:SetCell('Nation', row, 'FRA');		
			tEvenement_Officiel:SetCell('Comite', row, nation);
		end
		ordre = ordre + 1
	end
	-- on met à jour les nations et comités si possible
	for i = 0, tEvenement_Officiel:GetNbRows() -1 do
		local code_coureur = tEvenement_Officiel:GetCell('Code_coureur', i);
		base:TableLoad(tCoureur, 'Select * from Coureur Where Code_coureur = "'..code_coureur..'"');
		if tCoureur:GetNbRows() == 1 then
			tEvenement_Officiel:SetCell('Nation', i, tCoureur:GetCell('Code_nation', 0));
			tEvenement_Officiel:SetCell('Comite', i, tCoureur:GetCell('Code_comite', 0));
		end
	end

	-- élimine les fonctions non gérées et met à jour Fonction_fr, Diplome_verifie, Diplome_verifie_fr
	for i = tEvenement_Officiel:GetNbRows() -1 , 0, -1 do
		local fonction = tEvenement_Officiel:GetCell('Fonction', i);
		if not tFonction[fonction] then
			tEvenement_Officiel:RemoveRowAt(i);
		else
			tEvenement_Officiel:SetCell('Fonction_fr', i, p.tFonction[fonction].Fonction);
			tEvenement_Officiel:SetCell('Diplome_verifie', i, p.tFonction[fonction].SqlMinimum);
			tEvenement_Officiel:SetCell('Diplome_verifie_fr', i, p.tFonction[fonction].Minimum);
			if p.tFonction[fonction].api_function then
				tEvenement_Officiel:SetCell('Api_function', i, p.tFonction[fonction].api_function);
			end
		end
	end
	p.comite_controle = false;

	p.tTableOfficiel = {};
	if tComite[p.comite] and tComite[p.comite].URL then
		local urlFile = tComite[p.comite].URL;
		local officiel_csv = app:GetPath()..'/tmp/officiels_ALP.csv';
		officiel_csv = string.gsub(officiel_csv, app.GetPathSeparator(), "/");
		ShowdlgMessage(p)
		if curl.DownloadFile(urlFile, officiel_csv) == true then
			p.comite_controle = p.comite;
			ChargeOfficiels(officiel_csv, p);
		else
			if dlgMessage then
				dlgMessage:Close();
				dlgMessage = nil;
			end
			app.GetAuiFrame():MessageBox(
				"Les Officiels du Comité "..p.comite.." ne peuvent pas être téléchargés !!", 
				"Téléchargement des officiels",
				msgBoxStyle.OK + msgBoxStyle.ICON_ERROR); 
		end
		if dlgMessage then
			dlgMessage:Close();
			dlgMessage = nil;
		end
	end
	p = Check_officiels(p);
	
	app.GetAuiMessage():AddLine(msg);
	
	p.altitude_depart = tonumber(tEpreuve_Alpine_Manche:GetCell('Altitude_Depart', 0)) or 0;
	p.altitude_arrivee = tonumber(tEpreuve_Alpine_Manche:GetCell('Altitude_Arrivee', 0)) or 0;
	if p.altitude_depart == 0 or p.altitude_arrivee == 0 then
		p.altitude_depart = 0;
		p.altitude_arrivee = 0;
		p.denivele = -1;
		p.groupe_check_porte = 2;
		p.OK = false;
	elseif p.altitude_depart > 0 and p.altitude_arrivee > 0 then
		p.groupe_check_porte = 2;
		p.denivele = p.altitude_depart - p.altitude_arrivee;
	else
		p.groupe_check_porte = 2;
		p.denivele = -1;
		p.OK = false;
	end
	if p.denivele > 0 then
		local tResultatPortes = {};
		for run = 1, p.nombre_de_manche do
			local str_run = '';
			tResultatPortes[run]= {};
			local bolok = nil;
			local changement_de_directions = tEpreuve_Alpine_Manche:GetCellInt('Changement_de_directions', run-1)
			local tCategGates = {};
			for row_epreuve = 0, tEpreuve:GetNbRows() -1 do
				local sexe = tEpreuve:GetCell('Sexe', row_epreuve);
				local code_discipline = tEpreuve:GetCell('Code_discipline', row_epreuve);
				local code_categorie = tEpreuve:GetCell('Code_categorie', row_epreuve);
				if code_categorie:len() == 0 then
					code_categorie = "*";
				end
				if p.code_entite == 'FFS' then
					p.code_niveau = 'FFS';
					sexe = 'T';
				end
				
				if not tCategGates[code_categorie] then
					tCategGates[code_categorie] = {};
					Check_portes(p, run, row_epreuve, sexe, code_discipline, code_categorie, changement_de_directions);
					--adv.Alert('run '..run..', epreuve '..(row_epreuve + 1)..' : '..tEpreuve:GetCell('Resultat_portes'..run, row_epreuve));
					str_run = str_run..tEpreuve:GetCell('Resultat_portes'..run, row_epreuve);
				end
			end
			if run == 1 then
				local count = 0
				for _ in string.gmatch(str_run, 'Catégorie') do
					count = count + 1
				end
				p.groupe_check_porte = count;
			end
		end
	else
		if p.saison_num >= 2026 then
			tEpreuve:SetCell('Resultat_portes1', 0, "Vérifiez les altitudes de départ et d'arrivée !!")
			if p.nombre_de_manche > 1 then
				tEpreuve:SetCell('Resultat_portes2', 0, "Vérifiez les altitudes de départ et d'arrivée !!")
			end
		else
			tEpreuve:SetCell('Resultat_portes1', 0, "Contrôle des portes à partir de la saison 2026")
			tEpreuve:SetCell('Resultat_portes2', 0, "Contrôle des portes à partir de la saison 2026")
		end
	end
	--adv.Alert('p.groupe_check_porte = '..p.groupe_check_porte);
	local tEpreuve = base:GetTable('_Epreuve');

	p.liste_ok, p.resultat_liste = CheckListe(p);
	p.ctrl_piste, p.resultat_piste = Check_piste(p);
	
	p.width = display:GetSize().width;
	p.height = display:GetSize().height - 100;
	p.x = 0;
	p.y = 0;
	
	local portes_groupe_hauteur = tostring(31 * p.groupe_check_porte * 2)..'px';
	if p.denivele < 0 then
		portes_groupe_hauteur = "35px";
	end
	
	dlgControle = wnd.CreateDialog(
		{
		width = p.width,
		height = p.height,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		x = p.x,
		y = p.y,
		label='Controle de la course (version '..script_version..') : Nom de la course '..p.nom..' - Comité '..p.comite, 
		icon='./res/32x32_ffs.png'
		});
	
	dlgControle:LoadTemplateXML({ 
		xml = "./process/verification_alpin.xml",
		node_name = 'root/panel', 			
		node_attr = 'name', 				
		nblignes = tEvenement_Officiel:GetNbRows() + 1,
		NomEvenement = p.nom,
		NbRun = p.nombre_de_manche,
		PortesHauteur = portes_groupe_hauteur,
		node_value = 'resultat_controle', 	
		imageclear = app.GetPath()..'/res/32x32_clear.png'
	});

	local tb = dlgControle:GetWindowName('tbctrl');

	tb:AddStretchableSpace();
	local btnClose = tb:AddTool("Quitter", "./res/32x32_exit.png");
	tb:AddStretchableSpace();
	tb:Realize();

	tb:Bind(eventType.MENU, 
		function(evt) 
			dlgControle:EndModal(idButton.CANCEL);
		end, btnClose);
	local tCategorie = base:GetTable('Categorie');
	local cmd = 'SELECT * FROM Categorie where Code_activite = "ALP" '..
			' AND Code_entite = "'..p.code_entite..'"'..
			' AND Code_saison = "'..p.code_saison..'"'..
			' AND Code_grille = "'..tEvenement:GetCell('Code_grille_categorie',0)..'"';
	base:TableLoad(tCategorie, cmd);
	local tCoureur = base:GetTable('Coureur');
	local tRanking = base.CreateTableRanking({ code_evenement = p.code_evenement});		
	local ranking_scan = "Contrôles supplémentaires : ";
	local tscan_concurrent = {};
	local resultat_ctrl = true;
	for i = 0, tRanking:GetNbRows() -1 do
		local code_coureur = tRanking:GetCell('Code_coureur', i);
		local an = tRanking:GetCellInt('An', i);
		local ordre_categorie = tRanking:GetCellInt('Ordre_categorie', i);
		local categ = tRanking:GetCell('Categ', i);
		local nation = tRanking:GetCell('Nation', i);
		local sexe = tRanking:GetCell('Sexe', i);
		local nom = tRanking:GetCell('Nom', i);
		local prenom = tRanking:GetCell('Prenom', i);
		table.insert(tscan_concurrent,{CodeCoureur = code_coureur, Nom = nom, Cause = ''});
		local code_epreuve = tRanking:GetCellInt('Code_epreuve', i);
		if code_epreuve < 0 then
			tscan_concurrent[#tscan_concurrent].Cause = '?'
			resultat_ctrl = false;
		end
		if string.sub(code_coureur,1,3):In('FFS','FIS') then
			cmd = 'SELECT * FROM Coureur WHERE Code_coureur = "'..code_coureur..'"';
			base:TableLoad(tCoureur, cmd);
			if tCoureur:GetNbRows() == 1 then
				if tCoureur:GetCell('Nom', 0) ~= nom or tCoureur:GetCell('Prenom', 0) ~= prenom then
					tscan_concurrent[#tscan_concurrent].Cause = 'Nom';
					resultat_ctrl = false;
				end
				if tCoureur:GetCell('Sexe', 0) ~= sexe then
					tscan_concurrent[#tscan_concurrent].Cause = 'Sexe';
					resultat_ctrl = false;
				end
				if tonumber(tCoureur:GetCell('Naissance', 0, '%4Y')) ~= an then
					tscan_concurrent[#tscan_concurrent].Cause = 'An';
					resultat_ctrl = false;
				end
				if tCoureur:GetCellInt('Dir_lic', 0) > 1 then
					tscan_concurrent[#tscan_concurrent].Cause = 'Dirigeant';
					resultat_ctrl = false;
				end
			else
				tscan_concurrent[#tscan_concurrent].Cause = 'ABS/liste '..p.code_liste;
				resultat_ctrl = false;
			end
		end
	end
	for i = #tscan_concurrent, 1, -1 do
		if tscan_concurrent[i].Cause:len() == 0 then
			table.remove(tscan_concurrent, i);
		end
	end
	if resultat_ctrl == true then
		ranking_scan = "Pas d'erreur sur les concurrents";
	else
		ranking_scan = 'Pb sur le(s) concurrent(s) : ';
		for i = 1, #tscan_concurrent do
			ranking_scan = ranking_scan..tscan_concurrent[i].Nom..'-'..tscan_concurrent[i].Cause..', ';
		end
		ranking_scan = string.sub(ranking_scan, 1, -3);
	end
		
	local traceur_manche = 0;
	
	for i = 0, tEvenement_Officiel:GetNbRows() -1 do
		local ligne = i + 1;
		local resultat =  tEvenement_Officiel:GetCell('Resultat_controle',i);
		local nation = tEvenement_Officiel:GetCell('Nation',i);
		local comite = tEvenement_Officiel:GetCell('Comite',i);
		local identite = tEvenement_Officiel:GetCell('Nom',i)..' '..tEvenement_Officiel:GetCell('Prenom',i);
		local diplome_ok = tEvenement_Officiel:GetCellInt('Diplome_ok', i);
		if nation == 'FRA' then
			if comite:len() > 0 then
				identite = identite..' ('..comite..')';
			else
				identite = identite..' ('..nation..')';
			end
		else
			identite = identite..' ('..nation..')';
		end
		local fonction = tEvenement_Officiel:GetCell('Fonction',i);
		local ordre  = tEvenement_Officiel:GetCellInt('Ordre',i);
		if ordre >= 100 then
			traceur_manche = traceur_manche + 1;
			ligne = ligne + 1;
		end
		if ordre < 100 then
			dlgControle:GetWindowName('indice'..ligne):SetLabel(ligne);
		else
			dlgControle:GetWindowName('indice'..ligne):SetLabel(ligne -1);
		end
		dlgControle:GetWindowName('officiel_fonction_fr'..ligne):SetLabel(tEvenement_Officiel:GetCell('Fonction_fr',i));
		if identite:len() > 5 then
			if traceur_manche == 0 then
				dlgControle:GetWindowName('officiel_fonction_fr'..ligne):SetLabel(tEvenement_Officiel:GetCell('Fonction_fr',i));
			else
				dlgControle:GetWindowName('officiel_fonction_fr'..ligne):SetLabel(tEvenement_Officiel:GetCell('Fonction_fr',i)..' M'..traceur_manche);
			end
			dlgControle:GetWindowName('officiel_identite'..ligne):SetLabel(identite);
			dlgControle:GetWindowName('officiel_diplome_teste'..ligne):SetLabel(tEvenement_Officiel:GetCell('Diplome_verifie_fr',i));
			dlgControle:GetWindowName('officiel_validite'..ligne):SetLabel(resultat);
			if diplome_ok == 1 then
				dlgControle:GetWindowName('image_ctrl'..ligne):GetObject(0):SetText('./res/32x32_dialog_ok.png', true);
			elseif diplome_ok == 0 then
				dlgControle:GetWindowName('image_ctrl'..ligne):GetObject(0):SetText('./res/32x32_dialog_ko.png', true);
			elseif diplome_ok == -1 then
				dlgControle:GetWindowName('image_ctrl'..ligne):GetObject(0):SetText('./res/chrono32x32_dns.png', true);
			end
		else
			dlgControle:GetWindowName('officiel_fonction_fr'..ligne):SetLabel(tEvenement_Officiel:GetCell('Fonction_fr',i));
			dlgControle:GetWindowName('officiel_identite'..ligne):SetLabel('Poste non pourvu');
		end

	end
	if p.resultat_piste and p.resultat_piste:len() > 0 then
		dlgControle:GetWindowName('piste'):SetValue(p.resultat_piste:Trim());
		if p.ctrl_piste == false then
			dlgControle:GetWindowName('piste_ctrl'):GetObject(0):SetText('./res/32x32_dialog_ko.png', true);
		else
			dlgControle:GetWindowName('piste_ctrl'):GetObject(0):SetText('./res/32x32_dialog_ok.png', true);
		end
	end
	if p.resultat_liste and p.resultat_liste:len() > 0 then
		dlgControle:GetWindowName('liste'):SetValue(p.resultat_liste);
		if p.liste_ok == false then
			dlgControle:GetWindowName('liste_ctrl'):GetObject(0):SetText('./res/32x32_dialog_ko.png', true);
		else
			dlgControle:GetWindowName('liste_ctrl'):GetObject(0):SetText('./res/32x32_dialog_ok.png', true);
		end
	end
	
	local tEpreuve = base:GetTable('_Epreuve');
	for run = 1, p.nombre_de_manche do
		local str_run = '';
		local ctrl_ok = 0;
		local retour_ligne = '';
		for row_epreuve = 0, tEpreuve:GetNbRows() -1 do
			if tEpreuve:GetCell('Resultat_portes'..run, row_epreuve):len() > 0 then
				str_run = str_run..retour_ligne..tEpreuve:GetCell('Resultat_portes'..run, row_epreuve)..retour_ligne;
				retour_ligne = '\n';
			end
			if tEpreuve:GetCellInt('Ctrl_ok'..run, row_epreuve) == 1 then
				ctrl_ok = 1;
			end
		end
		if ctrl_ok == 0 then
			dlgControle:GetWindowName('portes_ctrl'..run):GetObject(0):SetText('./res/32x32_dialog_ko.png', true);
			p.OK = false;
		else
			dlgControle:GetWindowName('portes_ctrl'..run):GetObject(0):SetText('./res/32x32_dialog_ok.png', true);
		end
		dlgControle:GetWindowName('portes_run'..run):SetValue(str_run);
	end
	dlgControle:GetWindowName('ranking_scan'):SetLabel(ranking_scan);
	if resultat_ctrl == false then
		dlgControle:GetWindowName('resultat_ctrl'):GetObject(0):SetText('./res/32x32_dialog_ko.png', true);
		p.OK = false;
	else
		dlgControle:GetWindowName('resultat_ctrl'):GetObject(0):SetText('./res/32x32_dialog_ok.png', true);
	end
	dlgControle:Fit()
	dlgControle:ShowModal();
	return p.OK
end