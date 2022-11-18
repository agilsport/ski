-- Matrices / Challenges et Combin�s pour skiFFS
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
dofile('./edition/functionPG.lua')

function AfficheVersion()
	local filename = app.GetPath()..app.GetPathSeparator()..'challenge'..app.GetPathSeparator()..'Matrice_versions.rtf';
	app.LaunchDefaultEditor(filename);
end

function AfficheAide()
	local filename = app.GetPath()..app.GetPathSeparator()..'challenge'..app.GetPathSeparator()..'Matrice_Aide.rtf';
	app.LaunchDefaultEditor(filename);
end

function CreateXMLLayerPerso(xml_layers)
	local utf8 = true;
	local doc_layer = xmlDocument.Create();
	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "layers");
	if doc_layer:SetRoot(nodeRoot) == false then
		return;
	end
	if not nodeRoot then
		return;
	end
	doc_layer:SaveFile(xml_layers);
	doc_layer:Delete();

end


-- Event Timer
function OnTimer()
	if matrice.action == 'close' then
		matrice.dialog:EndModal();
	end
	matrice.timer:Stop();
	if dlgOK then
		dlgOK:Close();
	end
end	

function TimerDialogInit()
	dlgOK = wnd.CreateDialog(
		{
		width = 400,
		height = 200,
		x = (matrice.dlgPosit.width/ 2) - 250,
		y = 150,
		label='Enregistrement', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgOK:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'sauveok' 		-- Facultatif si le node_name est unique ...
	});
	dlgOK:Fit()
	dlgOK:Show();
end

function BuildClassementListe(liste,indexclassement)	
	-- construction des tables de classement. 
	-- idx = 0 pour le filtre par points, on �liminera les points < ou > aux param�tres
	-- idx = 1 pour l'impression des points de la liste 1 et idx = 2 pour l'impression des points de la liste 2	
	-- idx = 3 pour l'analyse des performances 
	-- les points seront lus dans la fonction GetPtsListe() par recherche du Code_coureur dans la table
	local cmd = '';
	if matrice.comboEntite == 'FIS' then
		if matrice.comboActivite == 'ALP' then
			cmd = "Select cou.Code_coureur, 0 Est_critere, cou.Code_nation Nation, cou.Code_comite Comite, CONCAT(cou.Nom, ' ',cou.Prenom) Identite,  DATE_FORMAT(cou.Naissance,'%Y') An, "..
						"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = '-1' AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IASL') Pts_last_discipline, "..
						"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = '-1' AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IASL') Clt_last_discipline, "..
						"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IASL') Pts_SL, "..
						"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IASL') Clt_SL, "..
						"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IAGS') Pts_GS, "..
						"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IAGS') Clt_GS, "..
						"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = '-1' AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IASL') Pts_Technique, "..
						"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = '-1' AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IASL') Clt_technique, "..
						"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IASG') Pts_SG, "..
						"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IASG') Clt_SG, "..
						"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IADH') Pts_DH, "..
						"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IADH') Clt_DH, "..
						"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = '-1' AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IASL') Pts_vitesse, "..
						"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = '-1' AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='IASL') Clt_vitesse "..
					"FROM Coureur cou "..
					"Where cou.Code_coureur In(Select Code_coureur From Resultat Where Code_evenement In("..matrice.Evenement_selection.."))" 	
		end
	else
		if matrice.comboActivite == 'ALP' then
			cmd = "Select cou.Code_coureur, 0 Est_critere, cou.Code_nation Nation, cou.Code_comite Comite, CONCAT(cou.Nom, ' ',cou.Prenom) Identite,  DATE_FORMAT(cou.Naissance,'%Y') An, "..
						"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='FAU') Pts_liste , "..
						"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..liste.." AND cla1.Type_classement='FAU') Clt_liste "..
						"FROM Coureur cou "..
						"Where cou.Code_coureur In(Select Code_coureur From Resultat Where Code_evenement In("..matrice.Evenement_selection.."))" 	
		end
	end
	tClassement_Liste = base:TableLoad(cmd);
	if tClassement_Liste:GetNbRows() == 0 then
		app.GetAuiFrame():MessageBox(
			"Voulez n'avez pas encore charg� la liste "..liste.." !! ", 
			"Information !!!",
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
			);
		return;
	else
		if indexclassement == 0 then
			tClassement_Liste0 = tClassement_Liste:Copy();
			ReplaceTableEnvironnement(tClassement_Liste0, '_Classement_Liste0');
		elseif indexclassement == 1 then
			tClassement_Liste1 = tClassement_Liste:Copy();
			ReplaceTableEnvironnement(tClassement_Liste1, '_Classement_Liste1');
		elseif indexclassement == 2 then
			tClassement_Liste2 = tClassement_Liste:Copy();
			ReplaceTableEnvironnement(tClassement_Liste2, '_Classement_Liste2');
		elseif indexclassement == 3 then
			tClassement_Liste3 = tClassement_Liste:Copy();
			ReplaceTableEnvironnement(tClassement_Liste3, '_Classement_Liste3');
		end
	end
end

function BuildFilterSupport()	-- filtre additionnel des coureurs avec inclusion ou exclusion du classement en cas d'appartenance � la course 1 ou 2 de Evenement_support
	if matrice.support_inclusion > 0 then
		local cmd = 'Select * From Resultat Where Code_evenement = '..matrice.support_inclusion;
		local inclusion = "$(Code_coureur):In('-1'";
		base:TableLoad(tResultat, cmd);
		for i = 0, tResultat:GetNbRows() -1 do
			inclusion = inclusion..",'"..tResultat:GetCell('Code_coureur', i).."'";
		end
		inclusion = inclusion..')';
		tMatrice_Ranking:Filter(inclusion, true);
	end
	if matrice.support_exclusion > 0 then
		local tCode_exclusion = {};
		local cmd = 'Select * From Resultat Where Code_evenement = '..matrice.support_exclusion.." And Sexe = '"..matrice.comboSexe.."'";
		base:TableLoad(tResultat, cmd);
		-- tResultat:Snapshot('Resultat.db3');
		for i = tResultat:GetNbRows() -1, 0, -1 do
			local code_coureur = tResultat:GetCell('Code_coureur', i);
			tCode_exclusion[code_coureur] = {};
		end
		for i = tMatrice_Ranking:GetNbRows() -1, 0, -1 do
			local code_coureur = tMatrice_Ranking:GetCell('Code_coureur', i);
			if type(tCode_exclusion[code_coureur]) == 'table' then
				tMatrice_Ranking:RemoveRowAt(i);
			end			
		end
	end
end

function BuildGrilles_Point_Place()		-- Cr�ation de la table Grille_Point_Place selon l'activit�
	local cmd = "Select * From Grille_Point_Place Where Code_activite = 'CHA-CMB'";
	if matrice.comboActivite == 'BIATH' then
		cmd = cmd.." And Code Like 'BIAT%'";
	elseif matrice.comboActivite == 'FOND' then
		cmd = cmd.." And (Code Like 'NOR%' or Code Like 'MARSKIT')";
	else
		cmd = cmd.." And Code Like 'FIS%'";
	end
	cmd = cmd.." And Code_Saison = '"..matrice.Saison.."'";
	base:TableLoad(tGrille_Point_Place, cmd);
	matrice.comboGrille = matrice.comboGrille or tGrille_Point_Place:GetCell('Libelle', 0);
	assert(tGrille_Point_Place ~= nil);
end

function ChargeDisciplines()	-- charge les disciplines de l'activit� pour la saison de la matrice.
	local cmd = "Select * From Discipline Where Code_activite = '"..matrice.comboActivite.."' And Code_entite = '"..matrice.comboEntite.."' And Code_saison = '"..matrice.Saison.."' And Code IN('CS','SL','CR','GS','GS1','SG','DH','SC') ORDER BY Facteur_f";;
	base:TableLoad(tDiscipline, cmd);
	if matrice.debug == true then
		adv.Alert("ChargeDisciplines, Discipline:Snapshot('Discipline.db3')");
		tDiscipline:Snapshot('Discipline.db3');
	end
end

function GetValue(cle, defaultValue)	-- Lecture d'une valeur dans la table Evenement_Matrice avec lecture d'une valeur par d�faut dans le XML et retour de la valeur lue ou de la valeur par d�faut
	local valretour = defaultValue;
	if matrice.code_evenement > 0 then
		local r = tEvenement_Matrice:GetIndexRow('Cle', cle);
		if r >= 0 then
			valretour = tEvenement_Matrice:GetCell('Valeur', r)
		else
			local nodecle = doc:FindFirst('root/defaults/'..cle);
			if nodecle then
				valretour = nodecle:GetNodeContent();
			end
		end
	end
	return valretour;
end

function GetValueNumber(cle, defaultValue)
	local valeur = tonumber(GetValue(cle, defaultValue)) or 0;
	if valeur == math.floor(valeur) then	-- on retourne une valeur enti�re si on a z�ro apr�s la virgule
		valeur = math.floor(valeur);
	end
	return valeur;
end

function GetValueCombiSaut(cle)
	local nodecle = doc:FindFirst('root/combisaut/'..cle);	-- on va chercher les valeurs par d�faut des variables du Combi Saut
	return nodecle:GetNodeContent();
end

function OnChangecomboBloc(rowcourse)	-- lors du changement de bloc pour une course
	local bloc = tonumber(dlgVisuCoursex:GetWindowName('numBloc'):GetValue());
	matrice.course[(rowcourse+1)].bloc = bloc;
	matrice.course[(rowcourse+1)].coef_course = matrice['coefDefautCourseBloc'..bloc];
	matrice.course[(rowcourse+1)].coef_manche = matrice['coefDefautMancheBloc'..bloc];
	-- tMatrice_Courses:SetCell('Bloc', rowcourse, bloc);
	AfficheCoefCoursex(rowcourse);
	SetEnableControldlgConfiguration();
end

function OnChangecomboClassement();		-- en cas de changement du contenu du combo comboListe1Classement si on imprime les points de la liste n�1
	do return end
	dlgFiltrePoint:GetWindowName('comboListe1Classement'):Clear();
	dlgFiltrePoint:GetWindowName('comboListe'):Clear();
	local typeclassement = 'FAU';
	if matrice.comboActivite == 'ALP' then
		if entite == "FIS" then
			typeclassement = 'IAU';
		end
	end
	local filter = 'Seasoncode = '..matrice.Saison.." And Type_classement = '"..typeclassement.."'";
	tListe = base:TableLoad('Liste', filter);
	tListe:OrderBy('Code_liste');
	for i = 0, tListe:GetNbRows()-1 do
		dlgFiltrePoint:GetWindowName('comboListe'):Append(tListe:GetCell('Commentaire', i));
	end
	dlgFiltrePoint:GetWindowName('comboListe'):SetValue(tListe:GetCell('Commentaire', 0));
end

function OnChangecomboEntite()
	matrice.comboEntite = dlgConfig:GetWindowName('comboEntite'):GetValue();
	BuildRegroupement();
	SetEnableControldlgConfiguration();
end

function OnChangeSaison()
	matrice.Saison = dlgConfig:GetWindowName('Saison'):GetValue();
	BuildRegroupement();
end


function OnChangecomboPrendreBlocx(bloc)	-- en cas de changement dans les points � prendre pour les courses du bloc x
	bloc = bloc or 1;
	matrice['comboPrendreBloc'..bloc] = dlgConfig:GetWindowName('comboPrendreBloc'..bloc):GetValue();
	dlgConfig:GetWindowName('coefPourcentageMaxiBloc'..bloc):SetValue(matrice['coefPourcentageMaxiBloc'..bloc]);
	
	if string.find(matrice.comboTypePoint, 'place') then
		matrice.comboGrille = matrice.comboGrille or 'Point Place Coupe du Monde FIS';
		matrice['coefDefautCourseBloc'..bloc] = tonumber(matrice['coefDefautCourseBloc'..bloc]) or 100;
		matrice['coefDefautMancheBloc'..bloc] = tonumber(matrice['coefDefautMancheBloc'..bloc]) or 100;
		matrice['coefPourcentageMaxiBloc'..bloc] = tonumber(matrice['coefPourcentageMaxiBloc'..bloc]) or 0;
		dlgConfig:GetWindowName('comboGrille'):SetValue(matrice.comboGrille);
		dlgConfig:GetWindowName('coefPourcentageMaxiBloc'..bloc):SetValue(matrice['coefPourcentageMaxiBloc'..bloc]);
		if string.find(matrice['comboPrendreBloc'..bloc], '�') or string.find(matrice['comboPrendreBloc'..bloc], 'Idem') then
			dlgConfig:GetWindowName('coefDefautCourseBloc'..bloc):SetValue('100')
			dlgConfig:GetWindowName('coefDefautMancheBloc'..bloc):SetValue('100')
		else
			dlgConfig:GetWindowName('coefDefautCourseBloc'..bloc):SetValue(matrice['coefDefautCourseBloc'..bloc]);
			if string.find(dlgConfig:GetWindowName('comboPrendreBloc'..bloc):GetValue(), 'g�n�ral') then
				dlgConfig:GetWindowName('coefDefautMancheBloc'..bloc):SetValue('');
			else
				dlgConfig:GetWindowName('coefDefautMancheBloc'..bloc):SetValue(matrice['coefDefautMancheBloc'..bloc]);
			end
		end
	else
		dlgConfig:GetWindowName('coefDefautCourseBloc'..bloc):SetValue('');
		dlgConfig:GetWindowName('coefDefautMancheBloc'..bloc):SetValue('');
	end
	SetEnableControldlgConfiguration();
end

function OnChangecomboSexe()
	matrice.comboSexe = dlgConfig:GetWindowName('comboSexe'):GetValue();
	BuildRegroupement();
end

function OnChangecomboTpsDuDernier()
	matrice.comboTpsDuDernier = dlgConfig:GetWindowName('comboTpsDuDernier'):GetValue();
	if matrice.comboTpsDuDernier == 'Non' then
		matrice.numMalusAbdDsq = 0;
		matrice.numMalusAbs = 0;
		dlgConfig:GetWindowName('numMalusAbdDsq'):SetValue('');
		dlgConfig:GetWindowName('numMalusAbs'):SetValue('');
	end
	SetEnableControldlgConfiguration();
end

function OnChangecomboTypePoint(valeur)		-- selon le contenu du contr�le comboTypePoint
	dlgConfig:GetWindowName('comboPrendreBloc1'):Clear();
	dlgConfig:GetWindowName('comboPrendreBloc1'):Append("1.Classement g�n�ral");
	dlgConfig:GetWindowName('comboPrendreBloc1'):Append("2.Classement � la manche");
	dlgConfig:GetWindowName('comboPrendreBloc1'):Append("3.Idem plus le classement g�n�ral");
	dlgConfig:GetWindowName('comboPrendreBloc1'):SetSelection(0);
	dlgConfig:GetWindowName('comboPrendreBloc2'):Clear();
	dlgConfig:GetWindowName('comboPrendreBloc2'):Append("1.Classement g�n�ral");
	dlgConfig:GetWindowName('comboPrendreBloc2'):Append("2.Classement � la manche");
	dlgConfig:GetWindowName('comboPrendreBloc2'):Append("3.Idem plus le classement g�n�ral");
	dlgConfig:GetWindowName('comboPrendreBloc2'):SetSelection(0);
	dlgConfig:GetWindowName('coefPourcentageMaxiBloc1'):SetValue(matrice.coefPourcentageMaxiBloc1);
	if string.find(matrice.comboTypePoint, 'place') then
		if not matrice.comboGrille then
			BuildGrilles_Point_Place();
			dlgConfig:GetWindowName('comboGrille'):Clear();
			for i = 0, tGrille_Point_Place:GetNbRows() -1 do
				dlgConfig:GetWindowName('comboGrille'):Append(tGrille_Point_Place:GetCell("Libelle", i));
			end
			dlgConfig:GetWindowName('comboGrille'):SetSelection(0)
		end
		matrice.coefDefautCourseBloc1 = tonumber(matrice.coefDefautCourseBloc1) or 100;
		matrice.coefDefautMancheBloc1 = tonumber(matrice.coefDefautMancheBloc1) or 50;
		dlgConfig:GetWindowName('comboPrendreBloc1'):Append("4.G�n�ral PLUS meilleure manche");
		dlgConfig:GetWindowName('comboPrendreBloc1'):Append("5.G�n�ral OU meilleure manche");
		dlgConfig:GetWindowName('comboPrendreBloc2'):Append("4.G�n�ral PLUS meilleure manche");
		dlgConfig:GetWindowName('comboPrendreBloc2'):Append("5.G�n�ral OU meilleure manche");
		dlgConfig:GetWindowName('comboPrendreBloc1'):SetValue(matrice.comboPrendreBloc1);
		dlgConfig:GetWindowName('coefDefautCourseBloc1'):SetValue(matrice.coefDefautCourseBloc1);
		dlgConfig:GetWindowName('coefDefautMancheBloc1'):SetValue(matrice.coefDefautMancheBloc1);
		dlgConfig:GetWindowName('numPtsMini'):SetValue(matrice.numPtsMini);
		if matrice.numPtsMaxi < 9999 then
			dlgConfig:GetWindowName('numPtsMaxi'):SetValue('');
		end
		if matrice.bloc2 == true then
			matrice.coefDefautCourseBloc2 = tonumber(matrice.coefDefautCourseBloc2) or 100;
			matrice.coefDefautMancheBloc2 = tonumber(matrice.coefDefautMancheBloc2) or 0;
			dlgConfig:GetWindowName('coefPourcentageMaxiBloc2'):SetValue(matrice.coefPourcentageMaxiBloc2);
			dlgConfig:GetWindowName('comboPrendreBloc2'):SetValue(matrice.comboPrendreBloc2);
			dlgConfig:GetWindowName('coefDefautCourseBloc2'):SetValue(matrice.coefDefautCourseBloc2);
			dlgConfig:GetWindowName('coefDefautMancheBloc2'):SetValue(matrice.coefDefautMancheBloc2);
		end
	else
		dlgConfig:GetWindowName('coefDefautCourseBloc1'):SetValue('100');
		dlgConfig:GetWindowName('coefDefautMancheBloc1'):SetValue('100');
		if matrice.numPtsMaxi < 9999 then
			dlgConfig:GetWindowName('numPtsMaxi'):SetValue(matrice.numPtsMaxi);
		end
		dlgConfig:GetWindowName('numPtsMini'):SetValue('');
	end 
	SetDatadlgConfiguration();
	SetEnableControldlgConfiguration();
end

function OnChangenumMinimumArrivee()
	local lng = dlgConfig:GetWindowName('numMinimumArrivee'):GetValue():len();
	if lng == 0 then
		dlgConfig:GetWindowName('coefReduction'):SetValue('');
		dlgConfig:GetWindowName('coefReduction'):Enable(false);
	else
		dlgConfig:GetWindowName('coefReduction'):Enable(true);
	end
end

function SetRankingBody()
	for idxcourse = 1, tMatrice_Courses:GetNbRows() do
		if tMatrice_Courses:GetCell('Code_discipline', idxcourse-1) ~= 'CS' then
			local nombre_de_manche = tMatrice_Courses:GetCellInt('Nombre_de_manche', idxcourse-1);
			local colclt = 'Clt'..idxcourse;
			local coltps = 'Tps'..idxcourse;
			tMatrice_Ranking:OrderBy(coltps);
			if matrice.debug == true then
				adv.Alert('SetRankingBody tMatrice_Ranking:SetRanking('..colclt..', '..coltps..')');
			end
			tMatrice_Ranking:SetRanking(colclt, coltps);
			if matrice.prendre_manche then
				for idxrun = 1, nombre_de_manche do
					colclt = 'Clt'..idxcourse..'_run'..idxrun;
					coltps = 'Tps'..idxcourse..'_run'..idxrun;
					tMatrice_Ranking:OrderBy(coltps);
					if matrice.debug == true then
						adv.Alert('SetRankingBody tMatrice_Ranking:SetRanking('..colclt..', '..coltps..')');
					end
					tMatrice_Ranking:SetRanking(colclt, coltps);
				end
			end
		end
	end
	if matrice.debug == true then
		adv.Alert("SetRankingBody - tMatrice_Ranking:Snapshot('tMatrice_Ranking_apres_setrankingbody.db3')");
		tMatrice_Ranking:Snapshot('tMatrice_Ranking_apres_setrankingbody.db3');
	end
end

function CreateMatriceRanking(indice_filtrage)	-- cr�ation de la table tMatrice_Ranking sans tenir compte des filtres avec tous les coureurs inscrits aux courses de la matrice
	BuildTableRanking(indice_filtrage);
	tMatrice_Ranking:OrderBy('Code_coureur');
	
	-- application du filtre de FilterConcurrentDialog
	-- ex de matrice.Cle_filtrage = $(Groupe):In('ER')
	
	-- v�rifier les courses support. On retourne tMatrice_Ranking filtr�e le cas �ch�ant
	BuildFilterSupport()
	
	-- tMatrice_Ranking ne contient que les bons coureurs
	-- tMatrice_Ranking:Snapshot('tMatrice_Ranking.db3');
end			

function GetPtsCourse(idxcourse, tps, best, facteur_f)		-- application de la formule de calcul
	local pts = ((tps / best) - 1) * facteur_f;
	pts = Round(pts, 2);
	return pts;
end

function GetPointPlace(clt, grille)
	assert(grille ~= nil);
	-- for k,v in pairs(grille) do
		-- adv.Alert('Key '..k..'='..tostring(v));
		-- if type(v) == 'table' then
			-- for i,j in pairs(v) do
				-- adv.Alert('Key '..i..'='..tostring(j));
				-- if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == 'FIS6191024' then
					-- adv.Alert('type de '..i..' = '..type(j));
				-- end
			-- end
		-- end
		-- adv.Alert('\n');
	-- end
	clt = tonumber(clt) or 0;
	if clt <= 0 then
		return 0;
	end
	for i = 1, #grille do
		if clt == grille[i].Place then
			return grille[i].Point;
		end
	end
	if grille[#grille] == 9999 then
		return grille[#grille].Point;
	else
		return 0;
	end
end

function GetPtsListe(Code_coureur, index, row)
	local r = -1;
	tClassement_Listex = base:GetTable('_Classement_Liste'..index);
	r = tClassement_Listex:GetIndexRow('Code_coureur', Code_coureur);
	local clt = {};
	local pts = {};
	if r and r >= 0 then		-- on trouve le coureur
		r = tClassement_Listex:GetIndexRow('Code_coureur', Code_coureur);
		if matrice.comboEntite == 'FIS' then
			pts.last_discipline = tClassement_Listex:GetCellDouble('Pts_'..matrice.last_discipline, r, 999.99);
			clt.last_discipline = tClassement_Listex:GetCellInt('Clt_'..matrice.last_discipline, r, 999999);
			pts.SL = tClassement_Listex:GetCellDouble('Pts_SL', r, 999.99);
			pts.GS = tClassement_Listex:GetCellDouble('Pts_GS', r, 999.99);
			pts.SG = tClassement_Listex:GetCellDouble('Pts_SG', r, 999.99);
			pts.DH = tClassement_Listex:GetCellDouble('Pts_DH', r, 999.99);
			clt.SL = tClassement_Listex:GetCellInt('Clt_SL', r, 999999);
			clt.GS = tClassement_Listex:GetCellInt('Clt_GS', r, 999999);
			clt.SG = tClassement_Listex:GetCellInt('Clt_SG', r, 999999);
			clt.DH = tClassement_Listex:GetCellInt('Clt_DH', r, 999999);
			if clt.SL < 999999 then
				tMatrice_Ranking:SetCell('Pts_SL', row, pts.SL);
				tMatrice_Ranking:SetCell('Clt_SL', row, clt.SL);
			end
			if clt.GS < 999999 then
				tMatrice_Ranking:SetCell('Pts_GS', row, pts.GS);
				tMatrice_Ranking:SetCell('Clt_GS', row, clt.GS);
			end
			if clt.SG < 999999 then
				tMatrice_Ranking:SetCell('Pts_SG', row, pts.SG);
				tMatrice_Ranking:SetCell('Clt_SG', row, clt.SG);
			end
			if clt.DH < 999999 then
				tMatrice_Ranking:SetCell('Pts_DH', row, pts.DH);
				tMatrice_Ranking:SetCell('Clt_DH', row, clt.DH);
			end
			if clt.SL < clt.GS then
				clt.technique = clt.SL;
				pts.technique = pts.SL;
			else
				clt.technique = clt.GS;
				pts.technique = pts.GS;
			end			
			if clt.SG < clt.DH then
				clt.vitesse = clt.SG;
				pts.vitesse = pts.SG;
			else
				clt.vitesse = clt.DH;
				pts.vitesse = pts.DH;
			end			
			if index < 3 then
				if matrice.comboListePrimaute == 'aux points' then
					if pts.SL < pts.GS then
						clt.technique = clt.SL;
						pts.technique = pts.SL;
					else
						clt.technique = clt.GS;
						pts.technique = pts.GS;
					end			
					if pts.SG < pts.DH then
						clt.vitesse = clt.SG;
						pts.vitesse = pts.SG;
					else
						clt.vitesse = clt.DH;
						pts.vitesse = pts.DH;
					end			
				end
			end
			if clt.technique < 999999 then
				tMatrice_Ranking:SetCell('Pts_technique', row, pts.technique);
				tMatrice_Ranking:SetCell('Clt_technique', row, clt.technique);
			end
			if clt.vitesse < 999999 then
				tMatrice_Ranking:SetCell('Pts_vitesse', row, pts.vitesse);
				tMatrice_Ranking:SetCell('Clt_vitesse', row, clt.vitesse);
			end
			if matrice['comboListe'..index] and matrice['comboListe'..index..'Classement'] then
				if matrice['comboListe'..index..'Classement']:len() > 4 then
					if string.find(matrice['comboListe'..index..'Classement'], 'Technique') then
						clt['liste'..index] = clt.technique;
						pts['liste'..index] = pts.technique;
					else
						clt['liste'..index] = clt.vitesse;
						pts['liste'..index] = pts.vitesse;
					end
				else
					local suffixe = matrice['comboListe'..index..'Classement']:sub(-2);		-- IADH -> DH
					clt['liste'..index] = clt[suffixe];
					pts['liste'..index] = pts[suffixe];
				end
			end
			if index == 1 or index == 2 then
				if clt['liste'..index] < 999999 then
					tMatrice_Ranking:SetCell('Clt_liste'..index, row, clt['liste'..index]);
					tMatrice_Ranking:SetCell('Pts_liste'..index, row, pts['liste'..index]);
				end
			else
				if index == 3 then
					pts.last_discipline = pts[matrice.analyseGaucheDiscipline]
					clt.last_discipline = clt[matrice.analyseGaucheDiscipline]
				end
				tMatrice_Ranking:SetCell('Pts_inscription', row, pts.last_discipline); 
				tMatrice_Ranking:SetCell('Clt_inscription', row, clt.last_discipline); 
			end
			if clt.last_discipline < 999999 then
				tMatrice_Ranking:SetCell('Pts_last_discipline', row, pts.last_discipline);
				tMatrice_Ranking:SetCell('Clt_last_discipline', row, clt.last_discipline);
			end
		else
			pts = tClassement_Listex:GetCellDouble('Pts_liste', r, 255);
			clt = tClassement_Listex:GetCellInt('Clt_liste', r, nil);
			tMatrice_Ranking:SetCell('Pts_last_discipline', row, pts);
			tMatrice_Ranking:SetCell('Clt_last_discipline', row, clt);
			tMatrice_Ranking:SetCell('Pts_liste'..index, row, pts);
			tMatrice_Ranking:SetCell('Clt_liste'..index, row, clt);
			tMatrice_Ranking:SetCell('Pts_inscription', row, pts); 
			tMatrice_Ranking:SetCell('Clt_inscription', row, clt); 
		end
	end
end

function SetPtsTotalCourse(idxcourse, idxcoureur);	-- calcule et enregistre les points totaux d'une course en fonction du type de points � prendre en compte (g�n�ral, g�n�ral ou meilleure manche etc.)
	if matrice.course[idxcourse].Discipline == 'CS' then
		return raceData.PtsTotal;
	end

	local bestrun = raceData.Bestrun;
	local bestrunmaxi = 1;
	local bestclt = raceData.Bestclt;
	local bestpts = raceData.Bestpts;
	-- if matrice.course[idxcourse].Nombre_de_manche == 1 then
		-- raceData.Bestpts = 0;
	-- end
	ptscourse = 0;
	if matrice.course[idxcourse].Bloc < 2 then 
		ptscourse = ptscourse + matrice.numPtsPresence;
	end
	local bloc = matrice.course[idxcourse].Bloc;
	-- 1.Classement g�n�ral"
	-- 2.Classement � la manche"
	-- 3.Idem plus le classement g�n�ral"
	-- 4.G�n�ral PLUS meilleure manche"
	-- 5.G�n�ral OU meilleure manche"
	if string.find(matrice.course[idxcourse].Prendre, '1') then
		if idxcoureur < 0 then  
			ptscourse = matrice.course[idxcourse].MaxCourse;
		else
			if raceData.Clt > 0 then
				ptscourse = raceData.Pts;
			else
				if raceData.Tps == -500 or raceData.Tps == -800 or raceData.Tps == -600 then
					ptscourse = matrice.defaut_point;
				end
			end
			if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
				adv.Alert('dans SetPtsTotalCourse, course '..idxcourse..', ptscourse = '..tostring(ptscourse));
			end
		end
	elseif string.find(matrice.course[idxcourse].Prendre, '2') then
		if raceData.Clt > 0 then
			ptscourse = raceData.Pts;
		else
			if raceData.Tps == -500 or raceData.Tps == -800 or raceData.Tps == -600 then
				ptscourse = matrice.defaut_point;
			end
		end
		if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
			adv.Alert('dans SetPtsTotalCourse, course '..idxcourse..', ptscourse = '..tostring(ptscourse));
		end

	elseif string.find(matrice.course[idxcourse].Prendre, '3') then
		if idxcoureur < 0 then  
			ptscourse = matrice.course[idxcourse].MaxCourse;
		else
			if raceData.Clt > 0 then
				ptscourse = raceData.Pts;
			end
			for i = 1, matrice.course[idxcourse].Nombre_de_manche do
				local clt = tMatrice_Ranking:GetCellInt('Clt'..idxcourse..'_run'..i);
				if clt > 0 then
					local pts = tMatrice_Ranking:GetCellDouble('Pts'..idxcourse..'_run'..i, idxcoureur, -1);
					ptscourse = ptscourse + pts;
				end
			end
		end
	elseif string.find(matrice.course[idxcourse].Prendre, '4') then
		if idxcoureur < 0 then
			ptscourse = matrice.course[idxcourse].MaxCourse + matrice.course[idxcourse].MaxManche;
		else
			if raceData.Clt > 0 then
				ptscourse = raceData.Pts;
			end
			if raceData.Bestclt > 0 and matrice.course[idxcourse].Nombre_de_manche > 1 then
				ptscourse = ptscourse + raceData.Bestpts;
			end
		end
	elseif string.find(matrice.course[idxcourse].Prendre, '5') then
		if idxcoureur < 0 then
			ptscourse = math.max(matrice.course[idxcourse].MaxCourse, matrice.course[idxcourse].MaxManche);
		else
			if matrice.course[idxcourse].Nombre_de_manche == 1 then
				ptscourse = raceData.Pts;
			else
				if raceData.Bestpts > raceData.Pts then
					ptscourse = raceData.Bestpts;
				else
					ptscourse = raceData.Pts;
				end
				if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
					adv.Alert("dans SetPtsTotalCourse et string.find(prendre, 'OU'), raceData.Pts = "..tostring(raceData.Pts)..', raceData.Bestpts = '..tostring(raceData.Bestpts)..', selection = '..tostring(selection));
				end
			end
		end
	end
	if raceData.Tps > 0 or raceData.Tps == -500 or raceData.Tps == -800 then
		if not string.find(matrice.course[idxcourse].Prendre, '2') then
			ptscourse = ptscourse + matrice.numPtsPresence;
		end
	end

	return ptscourse;
end

function SortTable(sens, array, keys, code_coureur_en_cours)	-- tri des tables CourseData
	if code_coureur_en_cours and code_coureur_en_cours == code_coureur_pour_debug then
		adv.Alert('SortTable - sens = '..sens);
		for k,v in pairs(array) do
			adv.Alert('Key '..k..'='..tostring(v));
			if type(v) == 'table' then
				for i,j in pairs(v) do
					adv.Alert('Key '..i..'='..tostring(j));
					adv.Alert('type de '..i..' = '..type(j));
				end
			end
			adv.Alert('\n');
		end
	end
	if #keys == 1 then
		table.sort(array, function (u,v)
			if sens == '>' then
				return
					 u[keys[1]] > v[keys[1]];
			else
				return 
					 u[keys[1]] < v[keys[1]];
			end
		end)
	elseif #keys == 2 then
		table.sort(array, function (u,v)
			if sens == '>' then
				return
					 u[keys[1]] < v[keys[1]] or
					(u[keys[1]] == v[keys[1]] and u[keys[2]] > v[keys[2]]);
			else
				return
					 u[keys[1]] < v[keys[1]] or
					(u[keys[1]] == v[keys[1]] and u[keys[2]] < v[keys[2]]);
			end
		end)
	elseif #keys == 3 then
		table.sort(array, function (u,v)
			if sens == '>' then
				return
					 u[keys[1]] < v[keys[1]] or
					(u[keys[1]] == v[keys[1]] and u[keys[2]] < v[keys[2]]) or
					(u[keys[1]] == v[keys[1]] and u[keys[2]] == v[keys[2]] and u[keys[3]] > v[keys[3]]);
			else
				return
					 u[keys[1]] < v[keys[1]] or
					(u[keys[1]] == v[keys[1]] and u[keys[2]] < v[keys[2]]) or
					(u[keys[1]] == v[keys[1]] and u[keys[2]] == v[keys[2]] and u[keys[3]] < v[keys[3]]);
			end
		end)
	elseif #keys == 4 then
		table.sort(array, function (u,v)
			if sens == '>' then
				return
					 u[keys[1]]<v[keys[1]] or
					(u[keys[1]]==v[keys[1]] and u[keys[2]]<v[keys[2]]) or
					(u[keys[1]]==v[keys[1]] and u[keys[2]]==v[keys[2]] and u[keys[3]]<v[keys[3]]) or 
					(u[keys[1]]==v[keys[1]] and u[keys[2]]==v[keys[2]] and u[keys[3]]==v[keys[3]] and u[keys[4]] > v[keys[4]]);
			else
				return
					 u[keys[1]]<v[keys[1]] or
					(u[keys[1]]==v[keys[1]] and u[keys[2]]<v[keys[2]]) or
					(u[keys[1]]==v[keys[1]] and u[keys[2]]==v[keys[2]] and u[keys[3]]<v[keys[3]]) or 
					(u[keys[1]]==v[keys[1]] and u[keys[2]]==v[keys[2]] and u[keys[3]]==v[keys[3]] and u[keys[4]] < v[keys[4]]);
			end
		end)
	end
end

function SetPtsMaxiBloc1();	-- calcul des points maximum possible pour les courses du bloc 1. Les crit�res de calculs sont appliqu�s.
	matrice.MaxiPtsBloc1 = 0;
	-- un crit�re "au maximum" est toujours vrai
	-- matrice.numTypeCritere :
	-- 0 = pas de crit�re de calcul
	-- 1 = critere sans bloc : les nombres sont dans les Combien x des Matrices. Toutes les courses sont de bloc 1. 
	-- 2 = critere avec bloc : Idem matrice.numTypeCritere1 avec gestion des blocs en plus
	-- 3 = critere avec bloc : Idem matrice.numTypeCritere2 avec gestion des blocs et possibilit� d'aller chercher dans le m�me bloc x meilleures manches de la discipline ind�pendament des courses en plus.
	-- 4 = critere avec bloc : Idem 3 mais on va chercher les manches ind�pendemment des blocs.
	matrice.MaxiPtsBloc1 = 0;
	
	local prise = 0;
	local pts_premier = 0;
	local ptscourse = 0;
	local ptsmanche = 0;
	
	if matrice.numTypeCritere == 0 then					-- aucun tri est n�cessaire toutes les courses sont du bloc 1
		for i = 0, tMatrice_Courses:GetNbRows() -1 do
			if tMatrice_Courses:GetCellInt('Bloc', i) == 2 then
				break;
			end
			local coefcourse = tMatrice_Courses:GetCellInt('Coef_course', i);
			local coefmanche = tMatrice_Courses:GetCellInt('Coef_manche', i);
			local prendre = tMatrice_Courses:GetCell('Prendre', i);
			if string.find(prendre, '1') then
				ptscourse = GetPointPlace(1, matrice.course[(i+1)].Grille) * coefcourse / 100;
				pts_premier = pts_premier + ptscourse; 
			elseif string.find(prendre, '2') then
				for idxrun = 1, tMatrice_Courses:GetCellInt('Nombre_de_mancheCoef_course', i) do
					ptsmanche = GetPointPlace(1, matrice.course[(i+1)].Grille) * coefmanche / 100;
					pts_premier = pts_premier + ptsmanche;
				end
			elseif string.find(prendre, '3') then
				ptscourse = GetPointPlace(1, matrice.course[(i+1)].Grille) * coefcourse / 100;
				pts_premier = pts_premier + ptscourse; 
				for idxrun = 1, tMatrice_Courses:GetCellInt('Nombre_de_mancheCoef_course', i) do
					ptsmanche = GetPointPlace(1, matrice.course[(i+1)].Grille) * coefmanche / 100;
					pts_premier = pts_premier + ptsmanche;
				end
			elseif string.find(prendre, '4') then
				ptscourse = GetPointPlace(1, matrice.course[(i+1)].Grille) * coefcourse / 100;
				ptsmanche = GetPointPlace(1, matrice.course[(i+1)].Grille) * coefmanche / 100;
				pts_premier = pts_premier + ptscourse + ptsmanche;
			elseif string.find(prendre, '5') then
				ptscourse = GetPointPlace(1, matrice.course[(i+1)].Grille) * coefcourse / 100;
				ptsmanche = GetPointPlace(1, matrice.course[(i+1)].Grille) * coefmanche / 100;
				pts_premier = pts_premier + math.max(ptscourse, ptsmanche);
			end
		end
		matrice.MaxiPtsBloc1 = pts_premier;
	elseif matrice.numTypeCritere == 1 then				-- on trie par discipline. On avait forc� les blocs � 1.
		-- matrice.table_critere, {Critere = critere, TypeCritere = matrice.numTypeCritere, Item = item, Bloc = bloc, Discipline = discipline, Prendre = prendre, Combien = combien, NbCombien = nbcombien, Sur = sur}
		for idxcritere = 1, #matrice.table_critere do
			local critere = matrice.table_critere[idxcritere];
			local nb_courses_prises = 0;
		-- matrice.table_critere, {Critere = critere, TypeCritere = matrice.numTypeCritere, Item = item, Bloc = bloc, Discipline = discipline, Prendre = prendre, Combien = combien, NbCombien = nbcombien, Sur = sur}
			for i = 0, tMatrice_Courses:GetNbRows()-1 do
				if tMatrice_Courses:GetCellInt('Bloc', i) > 1 then
					break;
				end
				local pts_premier = GetPointPlace(1, matrice.course[(i+1)].Grille)
				local discipline = tMatrice_Courses:GetCell('Code_discipline', i);
				local prendre = tMatrice_Courses:GetCell('Prendre', i);
				local coefcourse = tMatrice_Courses:GetCellInt('Coef_course', i);
				local coefmanche = tMatrice_Courses:GetCellInt('Coef_manche', i);
				local nombredemanche = tMatrice_Courses:GetCellInt('Nombre_de_manche', i);
				if string.find(discipline, matrice.table_critere[idxcritere].Discipline) then	-- la course est dans la discipline du crit�re
					if tMatrice_Courses:GetCellInt('Prise', i) == 0 then	-- course pas encore prise
						if nb_courses_prises < matrice.table_critere[idxcritere].NbCombien then
							tMatrice_Courses:SetCell('Prise', i, 1);
							nb_courses_prises = nb_courses_prises + 1;
							if prendre == 'Classement g�n�ral' then
								matrice.MaxiPtsBloc1 = matrice.MaxiPtsBloc1 + (pts_premier * coefcourse / 100); 
							elseif string.find(prendre, '�') then
								matrice.MaxiPtsBloc1 = matrice.MaxiPtsBloc1 + (pts_premier * coefmanche * nombredemanche / 100); 
							elseif string.find(prendre, 'Idem') then
								matrice.MaxiPtsBloc1 = matrice.MaxiPtsBloc1 + (pts_premier * coefmanche * nombredemanche / 100) + (pts_premier * coefcourse / 100); 
							elseif string.find(prendre, 'PLUS') then
								matrice.MaxiPtsBloc1 = matrice.MaxiPtsBloc1 + (pts_premier * coefmanche / 100) + (pts_premier * coefcourse / 100); 
							elseif string.find(prendre, 'OU') then
								matrice.MaxiPtsBloc1 = matrice.MaxiPtsBloc1 + (pts_premier * coefcourse / 100); 
							end
							if nb_courses_prises == matrice.table_critere[idxcritere].NbCombien then
								if string.find(matrice.table_critere[idxcritere].Prendre, 'maximum') or string.find(matrice.table_critere[idxcritere].Prendre, 'exactement') then
									break;
								end
							end
						end
					end
				end
			end
		end
	end
	if matrice.MaxiPtsBloc1 == math.floor(matrice.MaxiPtsBloc1) then 
		matrice.MaxiPtsBloc1 = math.floor(matrice.MaxiPtsBloc1); 
	end;
end

function SetPtsTotalMatrice(idxcoureur, courseData);	-- calcul des points totaux de la matrice
	local code_coureur_en_cours = tMatrice_Ranking:GetCell('Code_coureur', idxcoureur);
	local identite = '';
	local selection = '';
	if code_coureur_en_cours == code_coureur_pour_debug then
		identite = tMatrice_Ranking:GetCell('Identite', idxcoureur)
		adv.Alert('\ndans SetPtsTotalMatrice, coureur '..idxcoureur..' : '..tMatrice_Ranking:GetCell('Identite', idxcoureur)..', numTypeCritere = '..matrice.numTypeCritere..', #matrice.table_critere = '..#matrice.table_critere);
	end
	-- un crit�re "au maximum" est toujours vrai
	-- matrice.numTypeCritere :
	-- 0 = pas de crit�re de calcul
	-- 1 = critere sans bloc : les nombres sont dans les Combien x des Matrices. Toutes les courses sont de bloc 1. 
	-- 2 = critere avec bloc : Idem matrice.numTypeCritere1 avec gestion des blocs en plus
	-- 3 = critere avec bloc : Idem matrice.numTypeCritere2 avec gestion des blocs et possibilit� d'aller chercher dans le m�me bloc x meilleures manches de la discipline ind�pendament des courses en plus.
	-- 4 = critere avec bloc : Idem 3 mais on va chercher les manches ind�pendemment des blocs.
	local prise = 0;
	local ptsMatrice = 0;
	local ajouter = 0;
	local ptsBloc1 = 0;
	local tbolCritere = {};
		
	-- 1.Classement g�n�ral"
	-- 2.Classement � la manche"
	-- 3.Idem plus le classement g�n�ral"
	-- 4.G�n�ral PLUS meilleure manche"
	-- 5.G�n�ral OU meilleure manche"
	if matrice.numTypeCritere == 0 then		-- aucun tri est n�cessaire, on prend tout
		for idxcourseData = 1, #courseData do
			local idxcourse = courseData[idxcourseData].Ordre;
			local bestrun = courseData[idxcourseData].BestRun;
			local bolCourse = Eval(courseData[idxcourseData].Type, 'course');
			if matrice.course[idxcourse].Discipline == 'CS' then
				matrice.course[idxcourse].Prendre = '1';
			end
			if string.find(matrice.course[idxcourse].Prendre, '1') then
				if bolCourse and courseData[idxcourseData].Pts >= 0 then
					selection = 'Pts'..idxcourseData..'G,Pts'..idxcourseData..'_total';
				end
			elseif string.find(matrice.course[idxcourse].Prendre, '2') then
				if not bolCourse and courseData[idxcourseData].Pts >= 0 then
					selection = 'Pts'..courseData[idxcourseData].Run;
				end
			elseif string.find(matrice.course[idxcourse].Prendre, '3') then
				if not bolCourse and courseData[idxcourseData].Pts >= 0 then
					selection = 'Pts'..courseData[idxcourseData].Run;
				end
			elseif string.find(matrice.course[idxcourse].Prendre, '4') then
				if courseData[idxcourseData].Pts >= 0 then
					selection = 'Pts'..idxcourseData..'G';
				end
				if courseData[idxcourseData].BestRun > 0 then
					selection = selection..',Pts'..idxcourseData..'_run'..bestrun;
				end
				if selection:len() > 0 then
					selection = selection..',Pts'..idxcourseData..'_total';
				end
			elseif string.find(matrice.course[idxcourse].Prendre, '5') then
				if matrice.comboTypePoint == 'Points place' then
					if courseData[idxcourseData].Pts >= courseData[idxcourseData].BestPts then
						selection = selection..',Pts'..idxcourse..'G';
					else
						selection = selection..',Pts'..idxcourse..'_run'..bestrun;
					end
				else
					if courseData[idxcourseData].Pts <= courseData[idxcourseData].BestPts then
						selection = selection..',Pts'..idxcourse;
					else
						selection = selection..',Pts'..idxcourse..'_run'..bestrun;
					end
				end
				if selection:len() > 0 then
					selection = selection..',Pts'..idxcourseData..'_total';
				end
			end
			if courseData[idxcourseData].Clt == 100000 then
				selection = selection..',Z';
			end
			if selection:len() > 0 then
				tMatrice_Ranking:SetCell('Selection'..idxcourse, idxcoureur, selection);
			end
			local bloc = courseData[idxcourseData].Bloc;
			if courseData[idxcourseData].BestPts >= 0 then
				ajouter = 0;
			end
			ptsMatrice = ptsMatrice + courseData[idxcourseData].PtsTotal;
			if bloc == 1 then 
				ptsBloc1 = ptsMatrice;
			end	
		end
		if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
			adv.Alert('ptsMatrice = '..ptsMatrice);
		end
		ptsBloc1 = ptsBloc1 + ajouter;
		ptsMatrice = ptsMatrice + ajouter;
		return ptsBloc1, ptsMatrice;
	elseif matrice.numTypeCritere == 1 then				-- on trie par discipline. On avait forc� les blocs � 1.
		matrice.bloc2 = false;
		for i = 1, #courseData do
			courseData[i].Bloc = 1;
		end
		SortTable(matrice.lastcompare, courseData, {'Obligatoire', 'PtsTotal'});
		-- SortTable(matrice.lastcompare, courseData, {'Bloc','Obligatoire','PtsTotal'});
		-- matrice.table_critere, {Critere = critere, TypeCritere = matrice.numTypeCritere, Item = item, Bloc = bloc, Discipline = discipline, Prendre = prendre, Combien = combien, NbCombien = nbcombien, Sur = sur}
		for idxcritere = 1, #matrice.table_critere do
			local critere = matrice.table_critere[idxcritere];
			local nb_courses_prises = 0;
			if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
				adv.Alert('\nmatrice.numTypeCritere == 1, en entr�e - Prendre '..matrice.table_critere[idxcritere].Prendre..' '..matrice.table_critere[idxcritere].Combien..' '..matrice.table_critere[idxcritere].Discipline);
			end
			local bolcritere = true;
			table.insert(tbolCritere, bolcritere);
			
			if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug or idxcoureur == -1 then
				adv.Alert('\napr�s SortTable, on a :')
				for k,v in pairs(courseData) do
					adv.Alert('Key '..k..'='..tostring(v));
					if type(v) == 'table' then
						for i,j in pairs(v) do
							adv.Alert('Key '..i..'='..tostring(j));
						end
					end
					adv.Alert('\n');
				end
			end
		-- matrice.table_critere, {Critere = critere, TypeCritere = matrice.numTypeCritere, Item = item, Bloc = bloc, Discipline = discipline, Prendre = prendre, Combien = combien, NbCombien = nbcombien, Sur = sur}
		-- � la manche,il a a autant de idxcourseData que de manche, Idem on rajoute un �l�ment dans courseDatales avec donn�es de la course 
			for idxcourseData = 1, #courseData do
				local idxcourse = courseData[idxcourseData].Ordre;
				local disciplineok = false;
				local selection = tMatrice_Ranking:GetCell('Selection'..idxcourse, idxcoureur);
				local nombre_de_manche = matrice.course[idxcourse].Nombre_de_manche;
				local idxrun = courseData[idxcourseData].Run;
				if matrice.table_critere[idxcritere].Discipline == '*' then
					courseData[idxcourseData].Discipline = '*';
				end
				if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
					adv.Alert('--------------------------------------------');
					adv.Alert('Le coureur correspond : passage 1');
				end
				local tdiscipline = matrice.table_critere[idxcritere].Discipline:Split(',');
				local disciplineOK = false;
				for index = 1, #tdiscipline do
					if tdiscipline[index] == courseData[idxcourseData].Discipline then
						disciplineOK = true;
					end
				end
				if disciplineOK then	-- la course est dans la discipline du crit�re
					if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
						adv.Alert('--------------------------------------------');
						adv.Alert('la course '..idxcourseData..' en '..courseData[idxcourseData].Discipline..' est dans la discipline du crit�re : '..matrice.table_critere[idxcritere].Discipline);
					end
					if courseData[idxcourseData].Prise == 0 then	-- course pas encore prise
						if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
							adv.Alert('--------------------------------------------');
							adv.Alert('Type crit�re = 1, la course '..idxcourseData.." n'est pas encore prise");
						end
						if nb_courses_prises < matrice.table_critere[idxcritere].NbCombien then
							courseData[idxcourseData].Prise = 1;
							nb_courses_prises = nb_courses_prises + 1;
							if courseData[idxcourseData].Type == 'course' then
								selection = selection..'Pts'.. idxcourse..'G,Pts'.. idxcourse..'_total,'; 
								if matrice.course[idxcourse].Nombre_de_manche == 1 then
									selection = selection..'Pts'..idxcourse..'_run1,';
								end
							else
								selection = selection..'Pts'.. idxcourse..'_run'..courseData[idxcourseData].Run..','
							end
							ptsMatrice = ptsMatrice + courseData[idxcourseData].PtsTotal;
							if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
								adv.Alert('--------------------------------------------');
								adv.Alert('Type crit�re = 1, on prend la course '..idxcourseData.." du tableau d'idxcourse "..idxcourse..' = '..courseData[idxcourseData].Discipline..', nb_courses_prises = '..nb_courses_prises..' / '..tostring(nbcombienx)..' avec '..courseData[idxcourseData].Pts..' Pts, on enregistre la selection = '..selection);
							end
							if courseData[idxcourseData].BestClt == 100000 then
								selection = selection..',Z';
							end
							if string.find(matrice.course[courseData[idxcourseData].Ordre].Prendre, '4') then
								if courseData[idxcourseData].BestRun > 0 then
									selection = selection..',Pts'..courseData[idxcourseData].Ordre..'_run'..courseData[idxcourseData].BestRun ;
								end
							end
							if string.find(matrice.course[courseData[idxcourseData].Ordre].Prendre, '5') then
								if courseData[idxcourseData].BestRun > 0 then
									if string.find(matrice.comboTypePoint, 'place') then
										if courseData[idxcourseData].BestPts > courseData[idxcourseData].Pts then
											selection = 'Pts'..courseData[idxcourseData].Ordre..'_run'..courseData[idxcourseData].BestRun ;
										end
									else
										if courseData[idxcourseData].BestPts < courseData[idxcourseData].Pts then
											selection = 'Pts'..courseData[idxcourseData].Ordre..'_run'..courseData[idxcourseData].BestRun ;
										end
									end
								end
							end
							tMatrice_Ranking:SetCell('Selection'..idxcourse, idxcoureur, selection);
							if nb_courses_prises == matrice.table_critere[idxcritere].NbCombien then
								if string.find(matrice.table_critere[idxcritere].Prendre, 'maximum') or string.find(matrice.table_critere[idxcritere].Prendre, 'exactement') then
									if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
										adv.Alert('le crit�re '..idxcritere..' est rempli, on fait break !!');
									end
									break;
								end
							end
						end
					end
				end
			end
			if string.find(matrice.table_critere[idxcritere].Prendre, 'minimum') and nb_courses_prises < nbcombienx then
				bolcritere = false;
			end
			if string.find(matrice.table_critere[idxcritere].Prendre, 'exactement') then
				if nb_courses_prises ~= matrice.table_critere[idxcritere].NbCombien then
					bolcritere = false;
				end
			end
			if string.find(matrice.table_critere[idxcritere].Prendre, 'maximum') then
				bolcritere = bolcritere or true;
			end
			if bolcritere == false then
				tbolCritere[#tbolCritere] = false;
			end
		end
		for i = 1, #tbolCritere do
			if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
				adv.Alert('le critere n� '..i..' est '..tostring(tbolCritere[i]));
			end
			if tbolCritere[i] == false then
				return -1, -1;
			end
		end
		if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
			adv.Alert(code_coureur_pour_debug..', ptsMatrice = '..tostring(ptsMatrice)..', ptsBloc1 = '..ptsBloc1);
		end
		ptsBloc1 = ptsBloc1 + ajouter;
		ptsMatrice = ptsMatrice + ajouter;
		return ptsBloc1, ptsMatrice;
		
	elseif matrice.numTypeCritere == 2 then				-- on trie par bloc et discipline. 
		local selection = '';
		if code_coureur_en_cours == code_coureur_pour_debug then
			adv.Alert('Dans SetPtsTotalMatrice lecture des criteres pour '..identite..' :')
			for k,v in pairs(matrice.table_critere) do
				adv.Alert('Key '..k..'='..tostring(v));
				if type(v) == 'table' then
					for i,j in pairs(v) do
						adv.Alert('Key '..i..'='..tostring(j));
					end
				end
				adv.Alert('\n');
			end
		end
		-- table.insert(matrice.table_critere, {Critere = critere, TypeCritere = matrice.numTypeCritere, Item = item, Bloc = bloc, Discipline = discipline, Prendre = prendre, Combien = combien, NbCombien = nbcombien, Sur = sur});
		for idxcritere = 1, #matrice.table_critere do
			local typecriterex = matrice.table_critere[idxcritere].TypeCritere;
			local itemx = matrice.table_critere[idxcritere].Item;
			local blocx = matrice.table_critere[idxcritere].Bloc;
			local disciplinex = matrice.table_critere[idxcritere].Discipline;
			local prendrex = matrice.table_critere[idxcritere].Prendre;
			local combienx = matrice.table_critere[idxcritere].Combien;
			local nbcombienx = matrice.table_critere[idxcritere].NbCombien;
			local surx = matrice.table_critere[idxcritere].Sur;
			-- local criterex, typecriterex, itemx, blocx, disciplinex, prendrex, combienx, nbcombienx, surx = ParseCriterex(matrice.table_critere[idxcritere]);
			local disciplines_critere = disciplinex:Split(',');
			if code_coureur_en_cours == code_coureur_pour_debug then
				adv.Alert('Dans SetPtsTotalMatrice, Crit�res de type '..matrice.numTypeCritere..' - Item = '..matrice.table_critere[idxcritere].Item..', Discipline = '..matrice.table_critere[idxcritere].Discipline..', Bloc = '..matrice.table_critere[idxcritere].Bloc..', en prendre '..matrice.table_critere[idxcritere].NbCombien..' '..matrice.table_critere[idxcritere].Prendre..' sur '..matrice.table_critere[idxcritere].Sur);
			end
			table.insert(tbolCritere, false);
			local prise = 0;
			local bolcritere = false;
			if string.find(prendrex, 'maximum') then
				bolcritere = true;
			end
			if matrice.table_critere[idxcritere].Item == 'Course' then
				item = 'Course';
				colpts = 'PtsTotal';
				if code_coureur_en_cours == code_coureur_pour_debug then
					for idxcourse = 1, #courseData do
						adv.Alert('avant tri, course '..idxcourse..', '..colpts..' = '..courseData[idxcourse].PtsTotal)
						-- adv.Alert(prendrex..' - course lue n� '..idxcourse..' � prendre, Ordre = '..ordrecourse..', Clt = '..courseData[idxcourse].Clt..', PtsTotal = '..courseData[idxcourse].PtsTotal..', Discipline = '..courseData[idxcourse].Discipline..', Bloc = '..courseData[idxcourse].Bloc..', courseData['..idxcourse..']['..item..'] = '..courseData[idxcourse][item]..', classement : '..prendre..', avant la prise, prise = '..prise..', nbcombienx = '..nbcombienx);
					end
				end
				SortTable(matrice.lastcompare, courseData, {'Bloc', 'Obligatoire', colpts},code_coureur_en_cours);
				if code_coureur_en_cours == code_coureur_pour_debug then
					for idxcourse = 1, #courseData do
						adv.Alert('apr�s tri, course '..idxcourse..', '..colpts..' = '..courseData[idxcourse].PtsTotal)
						-- adv.Alert(prendrex..' - course lue n� '..idxcourse..' � prendre, Ordre = '..ordrecourse..', Clt = '..courseData[idxcourse].Clt..', PtsTotal = '..courseData[idxcourse].PtsTotal..', Discipline = '..courseData[idxcourse].Discipline..', Bloc = '..courseData[idxcourse].Bloc..', courseData['..idxcourse..']['..item..'] = '..courseData[idxcourse][item]..', classement : '..prendre..', avant la prise, prise = '..prise..', nbcombienx = '..nbcombienx);
					end
				end
			else
				item = 'Manche';
				colpts = 'BestPts';
				SortTable(matrice.lastcompare, courseData, {'Bloc', 'Obligatoire', colpts},code_coureur_en_cours);
				if code_coureur_en_cours == code_coureur_pour_debug then
					for idxcourse = 1, #courseData do
						adv.Alert('apr�s tri des manches, course '..idxcourse..', '..colpts..' = '..courseData[idxcourse].BestPts)
						-- adv.Alert(prendrex..' - course lue n� '..idxcourse..' � prendre, Ordre = '..ordrecourse..', Clt = '..courseData[idxcourse].Clt..', PtsTotal = '..courseData[idxcourse].PtsTotal..', Discipline = '..courseData[idxcourse].Discipline..', Bloc = '..courseData[idxcourse].Bloc..', courseData['..idxcourse..']['..item..'] = '..courseData[idxcourse][item]..', classement : '..prendre..', avant la prise, prise = '..prise..', nbcombienx = '..nbcombienx);
					end
				end
			end
			-- table.insert(coursesData, {Code = matrice.course[idxcourse].Code, Ordre = matrice.course[idxcourse].Ordre, Obligatoire = matrice.course[idxcourse].Obligatoire, 
				-- Type = 'course', Bloc = matrice.course[idxcourse].Bloc, Discipline = matrice.course[idxcourse].Discipline, Tps = raceData.Tps, Prise = 0;
				-- Clt = raceData.Clt, Pts = raceData.Pts, MaxiPtsTotal = matrice.course[idxcourse].MaxiPts, BestRun = raceData.Bestrun, Run = 0,
				-- BestClt = raceData.Bestclt, BestPts = raceData.Bestpts, PtsTotal = raceData.PtsTotal, NbManches = matrice.course[idxcourse].Nombre_de_manche});
			for idxcourse = 1, #courseData do
				local disciplineok = false;
				local ordrecourse = courseData[idxcourse].Ordre;
				-- if idxcoureur == 0 then
					-- for k,v in pairs(courseData) do
						-- adv.Alert('Key '..k..'='..tostring(v));
						-- if type(v) == 'table' then
							-- for i,j in pairs(v) do
								-- adv.Alert('Key '..i..'='..tostring(j));
								-- adv.Alert('type de '..i..' = '..type(j));
							-- end
						-- end
						-- adv.Alert('\n');
					-- end
				-- end
				if courseData[idxcourse].Bloc == matrice.table_critere[idxcritere].Bloc then	-- la course appartient au bloc du crit�re
					for index = 1, #disciplines_critere do
						if disciplines_critere[index] == '*' or courseData[idxcourse].Discipline == disciplines_critere[index] then	-- la course est dans la discipline du crit�re
							disciplineok = true;
							break;
						end
					end
					if item == 'Manche' and courseData[idxcourse].NbManches == 1 then
						disciplineok = false
					end
					if disciplineok == true then
						courseData[idxcourse][item] = 0;
						local prendre =  matrice.course[ordrecourse].Prendre;
						if code_coureur_en_cours == code_coureur_pour_debug then
							adv.Alert('disciplineok == true '..prendrex..' - course lue n� '..idxcourse..' � prendre, Ordre = '..ordrecourse..', Clt = '..courseData[idxcourse].Clt..', PtsTotal = '..courseData[idxcourse].PtsTotal..', Discipline = '..courseData[idxcourse].Discipline..', Bloc = '..courseData[idxcourse].Bloc..', courseData['..idxcourse..']['..item..'] = '..courseData[idxcourse][item]..', Prendre : '..prendre..', avant la prise, Prise = '..prise..', nbcombienx = '..nbcombienx);
						end
						if courseData[idxcourse].BestPts >= 0 then
							ajouter = 0;
						end
						-- if courseData[idxcourse]Prise == 0 then 			
						-- 1.Classement g�n�ral"
						-- 2.Classement � la manche"
						-- 3.Idem plus le classement g�n�ral"
						-- 4.G�n�ral PLUS meilleure manche"
						-- 5.G�n�ral OU meilleure manche"
						if courseData[idxcourse][item] == 0 then 	-- la course n'a pas encore �t� prise pour l'item en question
							if prise < nbcombienx then
								prise = prise + 1;
								courseData[idxcourse][item] = 1;
								if code_coureur_en_cours == code_coureur_pour_debug then
									adv.Alert('course '..idxcourse..' prise, courseData['..idxcourse..']['..item..'] = '..courseData[idxcourse][item]);
								end
								if item == 'Course' then
									if string.find(prendre, '2') or string.find(prendre,'3') then
										if courseData[idxcourse].Pts >= 0 then
											selection = 'Pts'..ordrecourse..'_run'..courseData[idxcourse].Run;
											ptsMatrice = ptsMatrice + courseData[idxcourse].Pts;
											if string.find(prendre, 'Idem') then
												selection = selection..',Pts'..ordrecourse..',';
											end
										end
									elseif string.find(prendre, '1') then
										if courseData[idxcourse].Pts >= 0 then
											selection = 'Pts'..ordrecourse..'G,Pts'..ordrecourse..'_total';
											ptsMatrice = ptsMatrice + courseData[idxcourse].Pts;
											if code_coureur_en_cours == code_coureur_pour_debug then
												adv.Alert('on prend les pts du g�n�ral, courseData[idxcourse].Pts = '..courseData[idxcourse].Pts..', ptsMatrice '..ptsMatrice);
											end
										end
									elseif string.find(prendre, '4') then
										if courseData[idxcourse].PtsTotal >= 0 then
											selection = 'Pts'..ordrecourse..'G,Pts'..ordrecourse..'_total';
											ptsMatrice = ptsMatrice + courseData[idxcourse].PtsTotal;
											if courseData[idxcourse].BestRun > 0 then
												selection = selection..',Pts'..ordrecourse..'_run'..courseData[idxcourse].BestRun;
											end
										end
									elseif string.find(prendre, '5') then
										if courseData[idxcourse].PtsTotal >= 0 then
											selection = 'Pts'..ordrecourse..'_total';
											ptsMatrice = ptsMatrice + courseData[idxcourse].PtsTotal;
											if courseData[idxcourse].Pts > courseData[idxcourse].BestPts then
												selection = selection..',Pts'..ordrecourse..'G';
											else
												selection = selection..',Pts'..ordrecourse..'_run'..courseData[idxcourse].BestRun;
											end
										end
									end
									if courseData[idxcourse].BestClt == 100000 then
										selection = selection..',Z';
									end
									tMatrice_Ranking:SetCell('Selection'..courseData[idxcourse].Ordre, idxcoureur, selection);
									if code_coureur_en_cours == code_coureur_pour_debug then
										adv.Alert('crit�re de type > 1, on enregistre Selection'..courseData[idxcourse].Ordre..' = '..selection);
									end
									if code_coureur_en_cours == code_coureur_pour_debug then
										adv.Alert('On prend la course n� '..idxcourse..' d\'ordre '..ordrecourse..' : '..courseData[idxcourse].Discipline..' avec '..courseData[idxcourse].PtsTotal..' Pts');
									end
								end
								if item == 'Manche' then
									ptsMatrice = ptsMatrice + courseData[idxcourse][colpts];
									selection = selection..',Pts'..ordrecourse..'_run'..courseData[idxcourse].BestRun;
									tMatrice_Ranking:SetCell('Selection'..courseData[idxcourse].Ordre, idxcoureur, selection);
													if code_coureur_en_cours == code_coureur_pour_debug then
										adv.Alert('On prend dans la course n� '..idxcourse..' d\'ordre '..ordrecourse..' : '..courseData[idxcourse].Discipline..' avec '..courseData[idxcourse][colpts]..' Pts de la manche '..courseData[idxcourse].BestRun..', \net selection = '..selection);
									end
								end
								if courseData[idxcourse].Bloc == 1 then
									ptsBloc1 = ptsBloc1 + courseData[idxcourse].PtsTotal;
								end
								if string.find(prendrex, 'minimum') and prise >= matrice.table_critere[i].NbCombien then
									bolcritere = true;
								end
								if string.find(prendrex, 'exactement') then
									if prise == nbcombienx then
										bolcritere = true;
									end
								end
							end

						end
					end
				end
				if bolcritere == true then
					tbolCritere[#tbolCritere] = true;
				end
			end
		end
		for i = 1, #tbolCritere do
			if tbolCritere[i] == false then
				return matrice.defaut_point, matrice.defaut_point;
			end
		end
		ptsBloc1 = ptsBloc1 + ajouter;
		ptsMatrice = ptsMatrice + ajouter;
		if code_coureur_en_cours == code_coureur_pour_debug then
			adv.Alert('en fin de fonction SetPtsTotalMatrice, ptsBloc1 = '..ptsBloc1..', ptsMatrice = '..ptsMatrice);
		end
		return ptsBloc1, ptsMatrice;
	else  	-- crit�re de type 2 = courses du bloc 1 et 2
			-- crit�re de type 3 = courses du bloc 1 et 2 + manches du bloc 1 et 2
			-- crit�re de type 4 = courses du bloc 1 et 2 + manches de n'importe que bloc
		local selection = '';
		if code_coureur_en_cours == code_coureur_pour_debug then
			adv.Alert('Dans SetPtsTotalMatrice lecture des criteres pour '..identite..' :')
			for k,v in pairs(matrice.table_critere) do
				adv.Alert('Key '..k..'='..tostring(v));
				if type(v) == 'table' then
					for i,j in pairs(v) do
						adv.Alert('Key '..i..'='..tostring(j));
					end
				end
				adv.Alert('\n');
			end
		end
		for idxcritere = 1, #matrice.table_critere do
			local criterex, typecriterex, itemx, blocx, disciplinex, prendrex, combienx, nbcombienx, surx = ParseCriterex(matrice.table_critere[idxcritere]);
			local disciplines_critere = disciplinex:Split(',');
			if code_coureur_en_cours == code_coureur_pour_debug then
				adv.Alert('Dans SetPtsTotalMatrice, Crit�res de type '..matrice.numTypeCritere..' - Item = '..matrice.table_critere[idxcritere].Item..', Discipline = '..matrice.table_critere[idxcritere].Discipline..', Bloc = '..matrice.table_critere[idxcritere].Bloc..', en prendre '..matrice.table_critere[idxcritere].NbCombien..' '..matrice.table_critere[idxcritere].Prendre..' sur '..matrice.table_critere[idxcritere].Sur);
			end
			table.insert(tbolCritere, false);
			local prise = 0;
			local bolcritere = false;
			if string.find(prendrex, 'maximum') then
				bolcritere = true;
			end
			if matrice.table_critere[idxcritere].Item == 'Course' then
				item = 'Course';
				colpts = 'PtsTotal';
				if matrice.table_critere[idxcritere].Discipline == '*' then
					SortTable(matrice.lastcompare, courseData, {'Bloc', 'Obligatoire',colpts}, code_coureur_en_cours);
				else
					SortTable(matrice.lastcompare, courseData, {'Bloc', 'Obligatoire', 'Discipline', colpts},code_coureur_en_cours);
				end
			else
				item = 'Manche';
				colpts = 'BestPts';
				if matrice.numTypeCritere < 4 then
					if matrice.table_critere[idxcritere].Discipline == '*' then
						SortTable(matrice.lastcompare, courseData, {'Bloc', 'Obligatoire', colpts},code_coureur_en_cours);
					else
						SortTable(matrice.lastcompare, courseData, {'Bloc', 'Obligatoire', 'Discipline', colpts},code_coureur_en_cours);
					end
				else
					if matrice.table_critere[idxcritere].Discipline == '*' then
						SortTable(matrice.lastcompare, courseData, {'Obligatoire',colpts},code_coureur_en_cours);
					else
						SortTable(matrice.lastcompare, courseData, {'Obligatoire', 'Discipline', colpts},code_coureur_en_cours);
					end
				end
			end
			for idxcourse = 1, #courseData do
				local ordre = courseData[idxcourse].Ordre;
				if courseData[idxcourse].BestPts >= 0 then
					ajouter = 0;
				end
				courseData[idxcourse][item] = 0;
				local prendre =  matrice.course[ordre].Prendre;
				local prendrecourse = false;
				local ordrecourse = courseData[idxcourse].Ordre;
				local disciplineok = false;
				for index = 1, #disciplines_critere do
					if disciplines_critere[index] == '*' or courseData[idxcourse].Discipline == disciplines_critere[index] then
						disciplineok = true;
						break;
					end
				end
				if disciplineok == true then														-- la course est dans la discipline du crit�re
					if courseData[idxcourse].Bloc == matrice.table_critere[idxcritere].Bloc then	-- la course appartient au bloc du crit�re
						if courseData[idxcourse][item] == 0 then 								-- la course n'a pas encore �t� prise pour l'item en question
							if courseData[idxcourse].PtsTotal >= 0 then
								if code_coureur_en_cours == code_coureur_pour_debug then
									adv.Alert(prendrex..' - course lue n� '..idxcourse..' � prendre, Ordre = '..ordrecourse..', Clt = '..courseData[idxcourse].Clt..', PtsTotal = '..courseData[idxcourse].PtsTotal..', Discipline = '..courseData[idxcourse].Discipline..', Bloc = '..courseData[idxcourse].Bloc..', courseData['..idxcourse..']['..item..'] = '..courseData[idxcourse][item]..', classement : '..prendre..', avant la prise, prise = '..prise..', nbcombienx = '..nbcombienx);
								end
								if prise < nbcombienx and courseData[idxcourse][item] == 0 then
									prise = prise + 1;
									courseData[idxcourse][item] = 1;
									if code_coureur_en_cours == code_coureur_pour_debug then
										adv.Alert('course '..idxcourse..' prise, courseData['..idxcourse..']['..item..'] = '..courseData[idxcourse][item]);
									end
									if item == 'Course' then
										if string.find(prendre, '2') or string.find(prendre,'3') then
											if courseData[idxcourse].Pts >= 0 then
												selection = 'Pts'..ordrecourse..'_run'..courseData[idxcourse].Run;
												ptsMatrice = ptsMatrice + courseData[idxcourse].Pts;
												if string.find(prendre, 'Idem') then
													selection = selection..',Pts'..ordrecourse..',';
												end
											end
										elseif string.find(prendre, '1') then
											if courseData[idxcourse].Pts >= 0 then
												selection = 'Pts'..ordrecourse..',Pts'..ordrecourse..'_total';
												ptsMatrice = ptsMatrice + courseData[idxcourse].Pts;
												if code_coureur_en_cours == code_coureur_pour_debug then
													adv.Alert('on prend les pts du g�n�ral, courseData[idxcourse].Pts = '..courseData[idxcourse].Pts..', ptsMatrice '..ptsMatrice);
												end
											end
										elseif string.find(prendre, '4') then
											if courseData[idxcourse].PtsTotal >= 0 then
												selection = 'Pts'..ordrecourse..',Pts'..ordrecourse..'_total';
												ptsMatrice = ptsMatrice + courseData[idxcourse].PtsTotal;
												if courseData[idxcourse].BestRun > 0 then
													selection = selection..',Pts'..ordrecourse..'_run'..courseData[idxcourse].BestRun;
												end
											end
										elseif string.find(prendre, '5') then
											if courseData[idxcourse].PtsTotal >= 0 then
												selection = 'Pts'..ordrecourse..'_total';
												ptsMatrice = ptsMatrice + courseData[idxcourse].PtsTotal;
												if courseData[idxcourse].Pts > courseData[idxcourse].BestPts then
													selection = selection..',Pts'..ordrecourse;
												else
													selection = selection..',Pts'..ordrecourse..'_run'..courseData[idxcourse].BestRun;
												end
											end
										end
										if courseData[idxcourseData].BestClt == 100000 then
											selection = selection..',Z';
										end
										tMatrice_Ranking:SetCell('Selection'..courseData[idxcourse].Ordre, idxcoureur, selection);
										if code_coureur_en_cours == code_coureur_pour_debug then
											adv.Alert('crit�re de type > 1, on enregistre Selection'..courseData[idxcourse].Ordre..' = '..selection);
										end
									end
									if item == 'Manche' then
										ptsMatrice = ptsMatrice + courseData[idxcourse][colpts];
									end
									if courseData[idxcourse].Bloc == 1 then
										ptsBloc1 = ptsBloc1 + courseData[idxcourse][colpts];
									end
									if code_coureur_en_cours == code_coureur_pour_debug then
										adv.Alert('On prend la course n� '..idxcourse..' d\'ordre '..ordrecourse..' : '..courseData[idxcourse].Discipline..' avec '..courseData[idxcourse].PtsTotal..' Pts');
									end
									if string.find(prendrex, 'minimum') and prise >= matrice.table_critere[i].NbCombien then
										bolcritere = true;
									end
									if string.find(prendrex, 'exactement') then
										if prise == nbcombienx then
											bolcritere = true;
										end
									end
								end
							end
						end
					end
				end
				if bolcritere == true then
					tbolCritere[#tbolCritere] = true;
				end
			end
		end
		for i = 1, #tbolCritere do
			if tbolCritere[i] == false then
				return matrice.defaut_point, matrice.defaut_point;
			end
		end
		ptsBloc1 = ptsBloc1 + ajouter;
		ptsMatrice = ptsMatrice + ajouter;
		if code_coureur_en_cours == code_coureur_pour_debug then
			adv.Alert('en fin de fonction SetPtsTotalMatrice, ptsBloc1 = '..ptsBloc1..', ptsMatrice = '..ptsMatrice);
		end
		return ptsBloc1, ptsMatrice;
	end
end

function CorrectionPtsPlace(idxcourse, coef, pts)	-- selon qu'un minimum de participation pour avoir la totalit� des points est d�fini ou pas
	pts = pts or 0;
	if coef == 0 then
		return pts;
	end
	if coef > 0 then								-- Si oui, le coefficient de r�duction est appliqu�
		if matrice.course[idxcourse].participation < matrice.numMinimumArrivee then
			pts = pts * (matrice.coefReduction / 100);
		end
	end
	return pts;
end

function SetRangDepart()						-- fonction appel�e en cas de cr�ation d'une nouvelle course � la fin des calculs
	for i = 0, tResultat:GetNbRows() -1 do		-- elle d�finit le rang de d�part des coureurs en fonction des crit�res choisis
		local code_coureur = tResultat:GetCell('Code_coureur', i);
		if tCoureurs[code_coureur].Rang == 0 then
			tCoureurs[code_coureur].Rang = i + 1;
		end
		tResultat:SetCell('Rang', i, tCoureurs[code_coureur].Rang);
		if tResultat:GetCellInt('Dossard', i, -1) < 0 and tCoureurs[code_coureur].Rang > 0 then
			tResultat:SetCell('Dossard', i, tCoureurs[code_coureur].Rang);
			tResultat:SetCellNull('Rang', i);
		end
		base:TableUpdate(tResultat, i);
	end
	if matrice.debug == true then
		adv.Alert("SetRangDepart - tResultat:Snapshot('Resultat.db3')");
		tResultat:Snapshot('Resultat.db3');
	end
end

function OnCreateCourse()	--	Cr�ation d'une nouvelle course � la fin des calculs
	rEvenement = tEvenement:GetRecord();
	rEvenement:SetNull(); 
	rEvenement:Set('Nom', "R�sultat - "..matrice.Titre);
	rEvenement:Set('Code_activite', matrice.comboActivite);
	rEvenement:Set('Code_entite', matrice.comboEntite);
	rEvenement:Set('Code_saison', matrice.Saison);
	rEvenement:Set('Code_gestion', 0);
	base:TableInsert(tEvenement, -1, 'Code_activite, Nom, Code_entite, Code_saison, Code_gestion');  -- -1 pour sauvegarder le record
	local code = base:GetLastAutoIncrement();
	matrice.code_inscription = code;
	rEvenement:Set('Code', code);
	tEpreuve = base:GetTable('Epreuve');
	local row = tEpreuve:AddRow();
	tEpreuve:SetCell('Code_evenement', row, matrice.code_inscription);
	tEpreuve:SetCell('Code_epreuve', row, 1);
	tEpreuve:SetCell('Code_activite', row, matrice.comboActivite);
	tEpreuve:SetCell('Code_entite', row, matrice.comboEntite);
	tEpreuve:SetCell('Code_saison', row, matrice.Saison);
	tEpreuve:SetCell('Code_origine', row, 'FFS');
	tEpreuve:SetCell('Code_calendrier', row, '');
	tEpreuve:SetCell('Code_gestion', row, 0);
	tEpreuve:SetCell('Code_regroupement', row, '?');
	tEpreuve:SetCell('Code_discipline', row, '?');
	tEpreuve:SetCell('Code_grille_categorie', row, '?');
	tEpreuve:SetCell('Code_categorie', row, '?');
	tEpreuve:SetCell('Sexe', row, matrice.comboSexe);
	tEpreuve:SetCell('Date_epreuve', row, '0000-00-00');
	base:TableInsert(tEpreuve, row);
	tCoureurs = {};
	local code_coureur = nil;
	for idxcoureur = 0, tMatrice_Ranking:GetNbRows() -1 do
		code_coureur = tMatrice_Ranking:GetCell('Code_coureur', idxcoureur);
		tCoureurs[code_coureur] = {};
		tCoureurs[code_coureur].Rang = 0;
		tCoureurs[code_coureur].Ranked = true;
		tCoureurs[code_coureur].Pts = tMatrice_Ranking:GetCellDouble('Pts', idxcoureur);
		tCoureurs[code_coureur].Point = tMatrice_Ranking:GetCellDouble('Point', idxcoureur);
		if matrice.bibo and matrice.bibo > 0 then
			if string.find(matrice.typeTirage, '5.') then
				if tCoureurs[code_coureur].Point == 0 then
					tCoureurs[code_coureur].Ranked = false;
				end
			else
				if string.find(matrice.comboTypePoint, 'place') then
					if tCoureurs[code_coureur].Pts == 0 then
						tCoureurs[code_coureur].Ranked = false;
					end
				elseif tCoureurs[code_coureur].Pts > matrice.defaut_point then
					tCoureurs[code_coureur].Ranked = false;
				end
			end

		end
		local row = tResultat:AddRow();
		tResultat:SetCell('Code_evenement', row, matrice.code_inscription);
		tResultat:SetCell('Code_coureur', row, code_coureur);
		if matrice.inscriptionPresent ~= nil and matrice.garderDossards == true then
			tResultat:SetCell('Dossard', row, tMatrice_Ranking:GetCell('Dossard', idxcoureur))
		else
			tResultat:SetCellNull('Dossard');
		end
		tResultat:SetCell('Clt', row, tMatrice_Ranking:GetCellInt('Clt', idxcoureur));
		tResultat:SetCell('Point', row, tMatrice_Ranking:GetCellDouble('Point', idxcoureur));
		tResultat:SetCell('Nom', row, tMatrice_Ranking:GetCell('Nom', idxcoureur));
		tResultat:SetCell('Prenom', row, tMatrice_Ranking:GetCell('Prenom', idxcoureur));
		tResultat:SetCell('Sexe', row, tMatrice_Ranking:GetCell('Sexe', idxcoureur));
		tResultat:SetCell('Nation', row, tMatrice_Ranking:GetCell('Nation', idxcoureur));
		tResultat:SetCell('Comite', row, tMatrice_Ranking:GetCell('Comite', idxcoureur));
		tResultat:SetCell('Club', row, tMatrice_Ranking:GetCell('Club', idxcoureur));
		tResultat:SetCell('An', row, tMatrice_Ranking:GetCellInt('An', idxcoureur));
		tResultat:SetCell('Categ', row, tMatrice_Ranking:GetCell('Categ', idxcoureur));
		tResultat:SetCell('Groupe', row, tMatrice_Ranking:GetCell('Groupe', idxcoureur));
		tResultat:SetCell('Equipe', row, tMatrice_Ranking:GetCell('Equipe', idxcoureur));
		tResultat:SetCell('Critere', row, tMatrice_Ranking:GetCell('Critere', idxcoureur));
		base:TableInsert(Resultat, row);
	end
	base:TableLoad(Resultat, 'Code_evenement = '..matrice.code_inscription);
	-- on g�n�re les rangs de d�part
	-- 1.Global � la m�l�e
	-- 2.Selon le classement du Challenge
	-- 3.Selon le classement du Challenge ET inversion des x meilleurs
	-- 4.Selon le classement du Challenge ET tirage au sort des x meilleurs
	-- 5.Selon les points inscription ET tirage au sort des x meilleurs
	-- 6.Conserver l'ordre des dossards (de la derni�re course)
	-- 7.Inverser l'ordre des dossards (de la derni�re course)
	local colbibo = nil;
	if string.find(matrice.typeTirage, '1.') then
		tResultat:OrderRandom('Clt');
		SetRangDepart();
		return;
	elseif string.find(matrice.typeTirage, '2.') then
		tResultat:OrderBy('Clt');
		SetRangDepart();
		return;
	elseif string.find(matrice.typeTirage, '3.') then
		tResultat:OrderBy('Clt');
		colbibo = 'Clt';
	elseif string.find(matrice.typeTirage, '4.') then
		tResultat:OrderBy('Clt');
		colbibo = 'Clt';
	elseif string.find(matrice.typeTirage, '5.') then
		tResultat:OrderBy('Point');
		colbibo = 'Point';
	elseif string.find(matrice.typeTirage, '6.') then
		return;
	elseif string.find(matrice.typeTirage, '7.') then
		tResultat:OrderBy('Dossard DESC');
		SetRangDepart();
		return;
	end
	local lastbibovalue = tonumber(tResultat:GetCell(colbibo, 14)) or 0;
	local value = 0;
	for idxcoureur = tResultat:GetNbRows()-1 , 0, -1 do
		code_coureur = tResultat:GetCell('Code_coureur', idxcoureur);
		if colbibo == 'Clt' then
			value = tResultat:GetCellInt(colbibo, idxcoureur);
		else
			value = tResultat:GetCellDouble(colbibo, idxcoureur);
		end
		if  value > lastbibovalue then
			tCoureurs[code_coureur].Bibo = false;
		else
			tCoureurs[code_coureur].Bibo = true;
		end
	end

	-- cas d'un tirage particulier pour les x meilleurs et les non class�s;
	TableBibo = tResultat:Copy();
	TableBibo:SetName('TableBibo');
	TableNotRanked = tResultat:Copy();
	TableNotRanked:SetName('TableNotRanked')
	if matrice.bibo and matrice.bibo > 0 then
		for idxcoureur = TableNotRanked:GetNbRows() -1, 0, -1 do
			code_coureur = TableNotRanked:GetCell('Code_coureur', idxcoureur);
			if tCoureurs[code_coureur].Ranked == true then
				TableNotRanked:RemoveRowAt(idxcoureur);
			end
		end
		TableNotRanked:OrderRandom(colbibo);
		local rangNotRanked = tResultat:GetNbRows() - TableNotRanked:GetNbRows();
		for idxcoureur = 0, TableNotRanked:GetNbRows() -1 do
			code_coureur = TableNotRanked:GetCell('Code_coureur', idxcoureur);
			rangNotRanked = rangNotRanked + 1;
			tCoureurs[code_coureur].Rang = rangNotRanked;
			TableNotRanked:SetCell('Rang', idxcoureur, tCoureurs[code_coureur].Rang);
		end
		if matrice.debug == true then
			adv.Alert("OnCreateCourse - TableNotRanked:Snapshot('TableNotRanked.db3')");
			TableNotRanked:Snapshot('TableNotRanked.db3');
		end
		for idxcoureur = TableBibo:GetNbRows() -1, 0, -1 do
			code_coureur = TableBibo:GetCell('Code_coureur', idxcoureur);
			if tCoureurs[code_coureur].Bibo == false then
				TableBibo:RemoveRowAt(idxcoureur);
			end
		end
	-- 3.Selon le classement du Challenge ET inversion des x meilleurs
	-- 4.Selon le classement du Challenge ET tirage au sort des x meilleurs
	-- 5.Selon les points inscription ET tirage au sort des x meilleurs
		if string.find(matrice.typeTirage, '3.') then
			TableBibo:OrderBy('Clt DESC');
		else
			TableBibo:OrderRandom(colbibo);
		end
		for idxcoureur = 0, TableBibo:GetNbRows() -1 do
			code_coureur = TableBibo:GetCell('Code_coureur', idxcoureur);
			tCoureurs[code_coureur].Rang = idxcoureur +1;
			TableBibo:SetCell('Rang', idxcoureur, tCoureurs[code_coureur].Rang);
		end
		if matrice.debug == true then
			adv.Alert("OnCreateCourse - TableBibo:Snapshot('TableBibo.db3')");
			TableBibo:Snapshot('TableBibo.db3');
		end
		local rang = TableBibo:GetNbRows();
		for idxcoureur = 0, tResultat:GetNbRows() -1 do
			code_coureur = tResultat:GetCell('Code_coureur', idxcoureur);
			if tCoureurs[code_coureur].Rang == 0 then
				rang = rang+1;
				tCoureurs[code_coureur].Rang = rang;
			end
		end
	end
	SetRangDepart();
	TableBibo:Delete();
	TableNotRanked:Delete();
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..matrice.code_evenement)
end

function InitCombiSaut(idxcourse)
	if matrice.debug == true then
		adv.Alert('traitement de la course '..idxcourse..' en Combi-Saut');
	end
	-- tMatrice_Ranking:Snapshot('tMatrice_Ranking_avan_init_course'..idxcourse..'.db3')
	tCS = tCS or {};
	tCS[idxcourse] = {};
	tCS[idxcourse].facteur_f_discipline_alpine = tMatrice_Courses:GetCellInt('Facteur_f', idxcourse-1, 1010);
	matrice.course[idxcourse].Diff_maxi = 0;
	-- Recalculer tous les points course et les classements pour la course idxcourse. Manche 1 = saut, manche 2 = alpin
	-- longueur du meilleur en manche 1 = matrice.course[idxcourse][1].lasttime
	-- temps du meilleur en manche alpine = matrice.course[idxcourse][2].besttime
	-- on placera le total des points course dans Tpsidxcourse
	local colclt = 'Clt'..idxcourse;
	local coltps = 'Tps'..idxcourse;
	local coltps_saut = 'Tps'..idxcourse..'_run1';
	local collng_saut = 'Lng'..idxcourse..'_saut';
	local colpts_saut = 'Pts'..idxcourse..'_run1';
	local colclt_saut = 'Clt'..idxcourse..'_run1';
	local coltps_alpin = 'Tps'..idxcourse..'_run2';
	local colpts_alpin = 'Pts'..idxcourse..'_run2';
	local colclt_alpin = 'Clt'..idxcourse..'_run2';
	local saut_best = 0;
	tMatrice_Ranking:OrderBy(coltps_saut..' DESC');
	for row = 0, tMatrice_Ranking:GetNbRows() -1 do
		local lng = tMatrice_Ranking:GetCellInt(coltps_saut, row);
		if lng > 0 then
			saut_best = lng / 1000;
			break;
		end
	end
	tCS[idxcourse].tps_best = -1;
	tMatrice_Ranking:OrderBy(coltps_alpin);
	for row = 0, tMatrice_Ranking:GetNbRows() -1 do
		local tps = tMatrice_Ranking:GetCellInt(coltps_alpin, row);
		if tps > 0 then
			tCS[idxcourse].tps_best = tps;
			break;
		end
	end
	tCS[idxcourse].facteur_f = tonumber(GetValueCombiSaut('facteur_f')) or 350;
	tCS[idxcourse].valeur_c = tonumber(GetValueCombiSaut('valeur_c')) or 60;
	tCS[idxcourse].point_k =  tonumber(GetValueCombiSaut('point_k')) or 25;
	tCS[idxcourse].points_metre = tonumber(GetValueCombiSaut('points_metre')) or 2.5;
	matrice.penalisationsaut = 'P�nalisation de '..matrice.numPenalisationSaut..' points course � la manche de saut';
	-- point_k=25		un saut jusqu'au point k donne les pts de valeur_c
	-- points_metre=2.5	on ajoute ou on retire la valeur de points_metre par m�tre en plus ou en moins du saut par rapport au point_k
	-- formule des points saut : valeur_c + ((lng du saut - point_k) * points_metre)
	-- pour un saut de 30m --> 60 + ((30-25) * 2.5) = 60 + 12.5 = 72.5 pts sauts
	-- pour un saut de 15m --> 60 + ((15-25) * 2.5) = 60 - 25 = 35 pts sauts
	-- pour un saut de 1m --> 60 + ((1-25) * 2.5) = 60 - 60 = 0 pts sauts
	tCS[idxcourse].pts_saut_best = tCS[idxcourse].valeur_c + ((saut_best - tCS[idxcourse].point_k) * tCS[idxcourse].points_metre);
	for idxcoureur = 0, tMatrice_Ranking:GetNbRows() -1 do
		local lng_saut = tMatrice_Ranking:GetCellInt(coltps_saut, idxcoureur) / 1000;
		local tps_alpin = tMatrice_Ranking:GetCellInt(coltps_alpin, idxcoureur);
		local tps_saut = -1;
		local pts_course_saut = -1;
		local pts_alpin = -1;
		tMatrice_Ranking:SetCell(coltps, idxcoureur, -1); 
		if code_coureur_pour_debug == tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) then
			adv.Alert('Pour '..tMatrice_Ranking:GetCell('Nom', idxcoureur)..', tps_alpin = '..tps_alpin..', lng_saut = '..lng_saut) ;
		end
		if lng_saut > 0 then
			tMatrice_Ranking:SetCell(collng_saut, idxcoureur, lng_saut..'m');
			tMatrice_Ranking:SetCell(coltps_saut, idxcoureur, 100000 - (lng_saut * 1000));
			pts_saut = tCS[idxcourse].valeur_c + ((lng_saut - tCS[idxcourse].point_k) * tCS[idxcourse].points_metre); -- points saut
			-- on calcule les points course 
			pts_course_saut = ((tCS[idxcourse].pts_saut_best - pts_saut) * tCS[idxcourse].facteur_f) / tCS[idxcourse].pts_saut_best; -- points course
			pts_course_saut = pts_course_saut + matrice.numPenalisationSaut;
			pts_course_saut = Round(pts_course_saut, 2);
			tMatrice_Ranking:SetCell(colpts_saut, idxcoureur, pts_course_saut);
			if code_coureur_pour_debug == tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) then
				adv.Alert('pts_course_saut = '..pts_course_saut) ;
			end
		else
			pts_saut = -1; pts_course_saut = -1;
			tMatrice_Ranking:SetCellNull(collng_saut, idxcoureur);
			tMatrice_Ranking:SetCell(coltps_saut, idxcoureur, -1);
		end
		pts_course_saut = Round(pts_course_saut, 2);
		tMatrice_Ranking:SetCell(colpts_saut, idxcoureur, pts_course_saut);
		if tps_alpin == 0 then tps_alpin = 1; end
		if tps_alpin > 0 then
			pts_alpin = GetPtsCourse(idxcourse, tps_alpin, tCS[idxcourse].tps_best, tCS[idxcourse].facteur_f_discipline_alpine)
			pts_alpin = Round(pts_alpin, 2);
			if code_coureur_pour_debug == tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) then
				adv.Alert('tps_alpin = '..tps_alpin..', tCS[idxcourse].tps_best = '..tCS[idxcourse].tps_best..', tCS[idxcourse].facteur_f_discipline_alpine = '..tCS[idxcourse].facteur_f_discipline_alpine..', pts_alpin = '..pts_alpin) ;
			end
		else
			pts_alpin = -1;
		end
		tMatrice_Ranking:SetCell(colpts_alpin, idxcoureur, pts_alpin);
		-- Ex pts_alpin = 25.55, pts_saut = 34.55 -> total 59.10, on multiplie par 100 avant de mettre le total dans la colonne de temps 
		if pts_alpin >= 0 and pts_course_saut >= 0 then
			total = (pts_alpin + pts_course_saut) * 100;
			total = Round(total, 0)
			if code_coureur_pour_debug == tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) then
				adv.Alert('total = '..total) ;
			end
		else
			total = -1;
		end
		if total == 0 then
			total = 1;
		end
		tMatrice_Ranking:SetCell(coltps, idxcoureur, total);
	end
	tMatrice_Ranking:SetRanking(colclt_alpin, coltps_alpin, '');
	tMatrice_Ranking:SetRanking(colclt_saut, coltps_saut, '');
	tMatrice_Ranking:SetRanking(colclt, coltps, '');
	if matrice.debug == true then
		adv.Alert("tMatrice_Ranking:Snapshot('tMatrice_Ranking_apres_init_combi_saut.db3')");
		tMatrice_Ranking:Snapshot('tMatrice_Ranking_apres_init_combi_saut.db3');
	end
end

function Calculer(panel_name, indice_filtrage)		-- fonction de calcul du r�sultat du Challenge/Combin�/Matrice
	if not matrice.Evenement_selection or matrice.Evenement_selection:len() == 0 then
		app.GetAuiFrame():MessageBox(
			"Vous devez ajouter des courses pour aller plus loin !!", 
			"Attention",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
		return false;
	end
	local ok = ControleData();
	if ok == false then
		app.GetAuiFrame():MessageBox(
			"Vous devez enregistrer les param�tres pour aller plus loin !!", 
			"Attention",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
		return false;
	end
	if matrice.scriptLUA and matrice.scriptLUA:len() > 0 then				-- lancement d'un script sp�cifique de marquage des coureurs par exemple
		dofile(matrice.scriptLUA);		-- le filtrage � venir en tiendra donc compte.
	end
	GetCritere();
	dlgWait = wnd.CreateDialog(
		{
		width = 400,
		height = 200,
		x = (matrice.dlgPosit.width/ 2) - 250,
		y = 150,
		label='Information', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgWait:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'wait' 		-- Facultatif si le node_name est unique ...
	});
	dlgWait:Show();
	CreateMatriceRanking(indice_filtrage);
	-- tMatrice_Ranking:Snapshot('tMatrice_Ranking_apres_CreateMatriceRanking.db3');
	local filterCmd = '';
	if panel_name == 'printanalyse' then
		if not matrice.analyseGaucheDiscipline or not matrice.analyseGaucheListe then
			dlgWait:Close();
			dlgWait:Delete();
			dlgConfig:MessageBox(
			"V�rifiez la liste support et la discipline dans les\nparam�tres de l\'analyse !!!", 
			"Attention !!!",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
			);
			return false;
		end
	end
	if panel_name == 'printanalyse' or matrice.texteFiltreSupplementaire == 'Oui' then
		if tMatrice_Ranking:GetNbRows() > 0 then
			BuildClassementListe(matrice.analyseGaucheListe, 3);
			if dlgConfig:MessageBox(
				"Voulez vous appliquer un filtre suppl�mentaire pour cette analyse ?\n\nIl se rajoutera au filtre pr�c�demment d�fini pour la s�lection \nglobale des coureurs de la matrice.\n\nN.B. Ce filtre n'est pas stock� pour une utilisation ult�rieure.", 
				"Attention !!!",
				msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_WARNING
				) == msgBoxStyle.YES then
				filterCmd = wnd.FilterConcurrentDialog({ 
					sqlTable = tMatrice_Ranking,
					key = 'cmd'});
				if type(filterCmd) == 'string' and filterCmd:len() > 0 then
					tMatrice_Ranking:Filter(filterCmd, true);
					filterCmd = '';
					if tMatrice_Ranking:GetNbRows() == 0 then
						dlgConfig:MessageBox(
						"Aucun enregistrement correspond � ce filtrage !!!", 
						"Attention !!!",
						msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
						);
						return;
					end
				end
				if dlgConfig:MessageBox(
					"Voulez vous reclasser les coureurs apr�s application du filtre ?\nEn r�pondant oui, les points seront recalcul�s.", 
					"Attention !!!",
					msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_WARNING
					) == msgBoxStyle.YES then
					SetRankingBody()
				end
			end
		end				
	end

	-- idx = -1 pour l'analyse des performances 
	-- idx = 0 pour le filtre par points, on �liminera les points < ou > aux param�tres
	-- idx = 1 pour l'impression des points de la liste 1 et idx = 2 pour l'impression des points de la liste 2	
	-- les points seront lus dans la fonction GetPtsListe() par recherche du Code_coureur dans la table
	if matrice.comboListe1 and tonumber(matrice.comboListe1) > 0 then
		BuildClassementListe(matrice.comboListe1, 1);
	end
	if matrice.comboListe2 and tonumber(matrice.comboListe2) > 0 then
		BuildClassementListe(matrice.comboListe2, 2);
	end
	if matrice.numPtsMaxi < 9999 then
		BuildClassementListe(matrice.last_liste, 0);
		-- �limination des coureurs hors de la plage numPtsMini / numPtsMaxi si cette plage existe avec r�cup�ration des points FIS ou FFS 
		local delete = nil; 
		for idxcoureur = tMatrice_Ranking:GetNbRows() -1, 0, -1 do
			local code_coureur = tMatrice_Ranking:GetCell('Code_coureur', idxcoureur);
			GetPtsListe(code_coureur, 0, idxcoureur);
			local pts = tMatrice_Ranking:GetCellDouble('Pts_last_discipline', idxcoureur, -1);
			delete = false;
			if pts < matrice.numPtsMaxi then
				delete = true;
			end
			if delete == true then
				tMatrice_Ranking:RemoveRowAt(idxcoureur);
			end
		end
	end

	-- parcours de la table pour eliminer les < numDepartMini si applicable
	for idxcoureur = tMatrice_Ranking:GetNbRows() -1, 0, -1 do
		local effacer = false;
		local code_coureur = tMatrice_Ranking:GetCell('Code_coureur', idxcoureur);
		local nbdepart = 0;
		-- for idxcourse = 1, #matrice.course do
		for idxcourse = 1, tMatrice_Courses:GetNbRows() do
			tMatrice_Ranking:SetCell('Pts'..idxcourse, idxcoureur, -1);
			tMatrice_Ranking:SetCell('Pts'..idxcourse..'_total', idxcoureur, -1);
			tMatrice_Ranking:SetCell('Pts_bloc1', idxcoureur, -1);
			local tps = tMatrice_Ranking:GetCellInt('Tps'..idxcourse, idxcoureur, -1);
			if tps > 0 or tps == -500 or tps == -800 then
				nbdepart = nbdepart + 1;
			end
			tMatrice_Ranking:SetCell('Nb_depart', idxcoureur, nbdepart);
		end
		if matrice.numDepartMini > 0 then
			if nbdepart < matrice.numDepartMini then
				effacer = true;
			end
		end
		if nbdepart == 0 then
			effacer = true;
		end
		if effacer == true then
			tMatrice_Ranking:RemoveRowAt(idxcoureur);
		end
	end
	
	SetRankingBody();

	-- fixation des classements des courses ET des manches + r�cup�ration du meilleur temps des courses ET des manches. Idem pour le dernier
	-- pour le calcul des points course ou s'il faut imprimer les �carts de temps dans les colonnes xxx_diff les �carts de temps sont syst�matiquement calcul�s
	local idxcourse = 0;
	local idxrun = 0;

	-- cas particulier du combi-saut, on recalcule tous les points course pour la manche alpine et la manche de saut
	-- on reclasse les manches, on additionne les points des 2 manches, = Tps de la course et on reclasse la course
		
	for i = 0, tMatrice_Courses:GetNbRows() -1 do
		local idxcourse = i + 1;
		local bloc = tMatrice_Courses:GetCellInt('Bloc', i);
		local best_time = 0;
		local diff_maxi = 0;
		local tps_maxi = 0;
		local last_time = 0;
		local last_clt = 0;
		local nb_abd_dsq = 0;
		local participation = 0;
		local bloc1maxi = 0;
		if string.find(matrice.comboTypePoint, 'place') then
			if tMatrice_Courses:GetCellInt('Bloc', i) == 1 then
				if not string.find(matrice.comboPrendreBloc1, '2') then
					bloc1maxi = GetPointPlace(1, matrice.course[idxcourse].Grille) * matrice.coefDefautCourseBloc1 / 100;
					if string.find(matrice.comboPrendreBloc1, '3') then
						for run = 1, tMatrice_Courses:GetCellInt('Nombre_de_manche', i) do
							bloc1maxi = bloc1maxi + (GetPointPlace(1, matrice.course[idxcourse].Grille) * matrice.coefDefautMancheBloc1 / 100);
						end
					end
				elseif matrice.prendre_manche == true then
					for run = 1, tMatrice_Courses:GetCellInt('Nombre_de_manche', i) do
						bloc1maxi = bloc1maxi + (GetPointPlace(1, matrice.course[idxcourse].Grille) * matrice.coefDefautMancheBloc1 / 100);
					end
				end
			end
			tMatrice_Courses:SetCell('Bloc1_maxi', i, bloc1maxi);
		end
		if tMatrice_Courses:GetCell('Code_discipline', i) == 'CS' then
			InitCombiSaut(idxcourse);
		else
			tMatrice_Ranking:OrderBy('Clt'..idxcourse);
			best_time = tMatrice_Ranking:GetCellInt('Tps'..idxcourse, 0);
			if matrice['coefPourcentageMaxiBloc'..bloc] and  matrice['coefPourcentageMaxiBloc'..bloc] > 0 then
				diff_maxi = math.ceil(best_time * matrice['coefPourcentageMaxiBloc'..bloc] * 0.01);
				tps_maxi = best_time + diff_maxi;
			end
			for row = tMatrice_Ranking:GetNbRows() -1, 0, -1 do
				if tMatrice_Ranking:GetCellInt('Tps'..idxcourse, row) == -800 or tMatrice_Ranking:GetCellInt('Tps'..idxcourse, row) == -500 then
					nb_abd_dsq = nb_abd_dsq + 1;
				end
				last_clt = tMatrice_Ranking:GetCellInt('Clt'..idxcourse, row);
				if last_clt > 0 then
					last_time = tMatrice_Ranking:GetCellInt('Tps'..idxcourse, row);
					break;
				end
			end
			participation = last_clt + nb_abd_dsq;
			matrice.course[idxcourse].Best_time = best_time;
			matrice.course[idxcourse].Diff_maxi = diff_maxi;
			matrice.course[idxcourse].Tps_maxi = tps_maxi;
			matrice.course[idxcourse].Last_clt = last_clt;
			matrice.course[idxcourse].Last_time = last_time;
			matrice.course[idxcourse].participation = participation
			
			tMatrice_Courses:SetCell('Participation', i, participation);
			tMatrice_Courses:SetCell('Best_time', i, best_time);
			tMatrice_Courses:SetCell('Diff_maxi', i, diff_maxi);
			tMatrice_Courses:SetCell('Tps_maxi', i, tps_maxi);
			tMatrice_Courses:SetCell('Last_time', i, last_time);
			tMatrice_Courses:SetCell('Last_clt', i, last_clt);

			local arRun = {};
			for idxrun = 1, matrice.course[idxcourse].Nombre_de_manche do
				diff_maxi = 0;
				tps_maxi = 0;
				last_time = 0;
				last_clt = 0;
				arRun[idxrun] = {};
				tMatrice_Ranking:OrderBy('Clt'..idxcourse..'_run'..idxrun);
				best_time = tMatrice_Ranking:GetCellInt('Tps'..idxcourse..'_run'..idxrun, 0);
				if matrice['coefPourcentageMaxiBloc'..bloc] and  matrice['coefPourcentageMaxiBloc'..bloc] > 0 then
					diff_maxi = math.ceil(best_time * matrice['coefPourcentageMaxiBloc'..bloc] * 0.01);
					tps_maxi = best_time + diff_maxi;
				end
				for row = tMatrice_Ranking:GetNbRows() -1, 0, -1 do
					last_clt = tMatrice_Ranking:GetCellInt('Clt'..idxcourse..'_run'..idxrun, row);
					if last_clt > 0 then
						last_time = tMatrice_Ranking:GetCellInt('Tps'..idxcourse..'_run'..idxrun, row);
						break;
					end
				end
				arRun[idxrun].BestTime = best_time;
				arRun[idxrun].DiffMaxi = diff_maxi;
				arRun[idxrun].LastTime = last_time;
				arRun[idxrun].LastClt = last_clt;
				
				tMatrice_Courses:SetCell('Best_time_m'..idxrun, i , best_time);
				tMatrice_Courses:SetCell('Tps_maxi_m'..idxrun, i, tps_maxi);
				tMatrice_Courses:SetCell('Diff_maxi_m'..idxrun, i, diff_maxi);
				tMatrice_Courses:SetCell('Last_time_m'..idxrun, i, last_time);
				tMatrice_Courses:SetCell('Last_clt_m'..idxrun, i, last_clt);
			end
			matrice.course[idxcourse].Runs = arRun;
		end
	end
	if matrice.debug == true then
		adv.Alert("tMatrice_Courses:Snapshot('Matrice_Courses_avecdiff.db3')");
		tMatrice_Courses:Snapshot('Matrice_Courses_avecdiff.db3')
	end


	-- parcours de la table pour fixation des points
	for idxcoureur = 0, tMatrice_Ranking:GetNbRows() -1 do
		code_coureur = tMatrice_Ranking:GetCell('Code_coureur', idxcoureur);
		if code_coureur == code_coureur_pour_debug then
			adv.Alert('---- // Calculer, on est dans le coureur pour debug : '..tMatrice_Ranking:GetCell('Identite', idxcoureur));
		end
		if matrice.texteComiteOrigine == 'Oui' and tMatrice_Ranking:GetCell('Comite', idxcoureur) == 'EQ' then
			local comite = GetComiteOrigine(code_coureur);
			tMatrice_Ranking:SetCell('Comite', idxcoureur, comite); 
		end
		tMatrice_Ranking:SetCell('Pts_inscription', idxcoureur, -1); 
		tMatrice_Ranking:SetCell('Clt_inscription', idxcoureur, -1); 
		tMatrice_Ranking:SetCell('Analyse_groupe', idxcoureur, 999);
		for i = 1, 5 do
			tMatrice_Ranking:SetCell('Analyse'..i, idxcoureur, -1);
		end
		local pts1 = -1; local pts2 = -1;
		if panel_name == 'printanalyse' then
			GetPtsListe(code_coureur, 3, idxcoureur);
		end
		if matrice.comboListe1 and matrice.comboListe1Classement then
			GetPtsListe(code_coureur, 1, idxcoureur);
		end
		if matrice.comboListe2 and matrice.comboListe2Classement then
			GetPtsListe(code_coureur, 2, idxcoureur);
		end
		if tMatrice_Ranking:GetCellDouble('Pts_liste2', idxcoureur) >= 0 then
			tMatrice_Ranking:SetCell('Delta', idxcoureur, tMatrice_Ranking:GetCellDouble('Pts_liste2', idxcoureur) - tMatrice_Ranking:GetCellDouble('Pts_liste1', idxcoureur));
		end
		raceData = {};			-- tableau associatif des donn�es de la course en cours pour un coureur.
		coursesData = {};		-- table LUA des donn�es des courses du coureur. Pour chaque course on fait un table.insert. � la manche, il y a autant de ligne que de manches en tout.
		-- for idxcourse = 1, tMatrice_Courses:GetNbRows() do
		for idxcourse = 1, #matrice.course do 
			local discipline = matrice.course[idxcourse].Discipline;	-- discipline r�elle de la course : CS pour un combi saut
			raceData.Bloc = matrice.course[idxcourse].Bloc;
			raceData.Discipline_alpine = matrice.course[idxcourse].Discipline_alpine;	-- NB contient la discipline alpine d'un combi saut
			raceData.Tps = tMatrice_Ranking:GetCellInt('Tps'..idxcourse, idxcoureur, -600); -- absent par d�faut
			if raceData.Tps == -1 then raceData.Tps = -600; end
			raceData.Clt = tMatrice_Ranking:GetCellInt('Clt'..idxcourse, idxcoureur, -1);	-- = -1 par defaut
			raceData.Pts = matrice.defaut_point;
			raceData.Bestrun = -1;
			raceData.Bestclt = -1;
			raceData.Bestpts = -1;
			tMatrice_Ranking:SetCell('Run'..idxcourse..'_best', idxcoureur, -1);
			tMatrice_Ranking:SetCell('Clt'..idxcourse..'_best', idxcoureur, -1);
			tMatrice_Ranking:SetCell('Pts'..idxcourse..'_best', idxcoureur, -1);
			tMatrice_Ranking:SetCell('Tps'..idxcourse..'_diff', idxcoureur, -1);
			--Tps pour absent = -600, Abd = -500, Dsq = -800 ou NT = -1
			-- on v�rifie qu'un coureur n'ait pas �t� ajout� sur la course (sans dossard). Cas d'un absent pour lequel on veut lui accorder des points place.
			if type(ajouter[idxcourse][code_coureur]) == 'table' and string.find(matrice.comboTypePoint, 'place') then
				raceData.Tps = 1;
				raceData.Clt = 100000;
				raceData.Bestclt = 100000;
				raceData.Bestrun = 1;
				raceData.Bestpts = ajouter[idxcourse][code_coureur].Pts;
				raceData.Pts = ajouter[idxcourse][code_coureur].Pts;
				raceData.PtsTotal = ajouter[idxcourse][code_coureur].Pts;
				tMatrice_Ranking:SetCell('Tps'..idxcourse, idxcoureur, raceData.Tps);					
				tMatrice_Ranking:SetCell('Clt'..idxcourse, idxcoureur, raceData.Clt);					
				tMatrice_Ranking:SetCell('Pts'..idxcourse, idxcoureur, raceData.Pts);					
				tMatrice_Ranking:SetCell('Pts'..idxcourse..'_total', idxcoureur, raceData.Pts);					
				tMatrice_Ranking:SetCell('Run'..idxcourse..'_best', idxcoureur, raceData.Bestrun);					
				tMatrice_Ranking:SetCell('Clt'..idxcourse..'_best', idxcoureur, raceData.Bestclt);					
				tMatrice_Ranking:SetCell('Pts'..idxcourse..'_best', idxcoureur, raceData.Bestpts);
			end
			if discipline ~= 'CS' then
				if code_coureur == code_coureur_pour_debug then
					adv.Alert(" ---------discipline ~= 'CS'");
					adv.Alert('course '..idxcourse..', raceData.Tps = '..raceData.Tps..', GetCell du temps = '..tMatrice_Ranking:GetCell('Tps'..idxcourse, idxcoureur));
				end
				if raceData.Tps < 0 then
					if matrice.comboTpsDuDernier == 'Oui' then
						raceData.Tps = matrice.course[idxcourse].Last_time;
						raceData.Clt = matrice.course[idxcourse].Last_clt + 1;
						tMatrice_Ranking:SetCell('Clt'..idxcourse, idxcoureur, raceData.Clt);
						if code_coureur == code_coureur_pour_debug then
							adv.Alert(' ////////////////////////////////////');
							adv.Alert('/////  course '..idxcourse..', raceData.Tps = '..raceData.Tps..', matrice.numMalusAbdDsq = '..matrice.numMalusAbdDsq..', matrice.numMalusAbs = '..matrice.numMalusAbs);
						end
						if raceData.Tps == -500 or raceData.Tps == -800 then
							if matrice.numMalusAbdDsq < 10 then -- on rajoute des secondes
								raceData.Tps = raceData.Tps + (matrice.numMalusAbdDsq * 1000);
							end
						end
						if raceData.Tps == -600 then
							if matrice.numMalusAbs < 10 then -- on rajoute des secondes
								raceData.Tps = raceData.Tps + (matrice.numMalusAbdDsq * 1000);
							end
						end
						if matrice.comboTypePoint == 'Points course' then
							raceData.Pts = GetPtsCourse(idxcourse, raceData.Tps, matrice.course[idxcourse].Best_time, matrice.course[idxcourse].Facteur_f);
							if raceData.Tps == -500 or raceData.Tps == -800 then
								if matrice.numMalusAbdDsq >= 10 then	-- on rajoute des points course
									raceData.Pts = raceData.Pts + matrice.numMalusAbdDsq;
								end
							elseif raceData.Tps == -600 then
								if matrice.numMalusAbs >= 10 then	-- on rajoute des points course
									raceData.Pts = raceData.Pts + matrice.numMalusAbs;
								end
							end
							if code_coureur == code_coureur_pour_debug then
								adv.Alert(' 1 - course '..idxcourse..', raceData.Tps = '..raceData.Tps);
							end
						end
						tMatrice_Ranking:SetCell('Tps'..idxcourse, idxcoureur, raceData.Tps);
					end
				end
	-- 1.Classement g�n�ral"
	-- 2.Classement � la manche"
	-- 3.Idem plus le classement g�n�ral"
	-- 4.G�n�ral PLUS meilleure manche"
	-- 5.G�n�ral OU meilleure manche"
				if raceData.Tps > 0 then
					if type(ajouter[idxcourse][code_coureur]) == 'nil' then	-- on peut calculer les points
						local diff = raceData.Tps - matrice.course[idxcourse].Best_time;
						tMatrice_Ranking:SetCell('Tps'..idxcourse..'_diff', idxcoureur, diff);
						if code_coureur == code_coureur_pour_debug then
							adv.Alert(' //////// raceData.Tps > 0  //////////');
							adv.Alert('course '..idxcourse..', raceData.Tps = '..raceData.Tps..', raceData.Clt = '..raceData.Clt..', best_time = '..matrice.course[idxcourse].Best_time..', diff = '..diff);
						end
						if string.find(matrice.comboTypePoint, 'place') then  
							raceData.Pts = GetPointPlace(raceData.Clt, matrice.course[idxcourse].Grille);
							
							raceData.Pts = raceData.Pts * matrice.course[idxcourse].Coef_course / 100;
							raceData.Pts  = CorrectionPtsPlace(idxcourse, matrice.coefReduction, raceData.Pts) 
						else
							raceData.Pts = GetPtsCourse(idxcourse, raceData.Tps, matrice.course[idxcourse].Best_time, matrice.course[idxcourse].Facteur_f);
						end
						if matrice['coefPourcentageMaxiBloc'..matrice.course[idxcourse].Bloc] and  matrice['coefPourcentageMaxiBloc'..matrice.course[idxcourse].Bloc] > 0 then
							if raceData.Tps > matrice.course[idxcourse].Tps_maxi then
								raceData.Pts  = matrice.defaut_point ;
							end
						end
						tMatrice_Ranking:SetCell('Pts'..idxcourse, idxcoureur, raceData.Pts);
						if matrice.course[idxcourse].Nombre_de_manche == 1 then
							tMatrice_Ranking:SetCell('Pts'..idxcourse..'_total', idxcoureur, raceData.Pts);
							tMatrice_Ranking:SetCell('Pts'..idxcourse, idxcoureur, raceData.Pts);
							if tMatrice_Courses:GetNbRows() < 20 then
								tMatrice_Ranking:SetCell('Pts'..idxcourse..'_run1', idxcoureur, raceData.Pts);
							end
						end
					else
						local diff = 0;
						tMatrice_Ranking:SetCell('Tps'..idxcourse..'_diff', idxcoureur, diff);
						if code_coureur == code_coureur_pour_debug then
							adv.Alert(' ***********     ////////////     **********');
							adv.Alert('course '..idxcourse..', raceData.Tps = '..raceData.Tps..', raceData.Clt = '..raceData.Clt..', best_time = '..matrice.course[idxcourse].Best_time..', diff = '..diff);
						end
						tMatrice_Ranking:SetCell('Pts'..idxcourse, idxcoureur, raceData.Pts);
						tMatrice_Ranking:SetCell('Pts'..idxcourse..'_total', idxcoureur, raceData.Pts);
					end
				end
			else	-- on est dans un combi saut
				if raceData.Tps > 0 then	-- on peut calculer les points
					if string.find(matrice.comboTypePoint, 'place') then  
						raceData.Pts = GetPointPlace(raceData.Clt, matrice.course[idxcourse].Grille);
						if matrice.numPtsPresence then
							raceData.Pts = raceData.Pts + matrice.numPtsPresence;
						end
						raceData.PtsTotal = raceData.Pts;
						tMatrice_Ranking:SetCell('Pts'..idxcourse, idxcoureur, raceData.Pts);
						tMatrice_Ranking:SetCell('Pts'..idxcourse..'_total', idxcoureur, raceData.Pts);
					end
				end
			end
			runData = {};
			raceData.Bestclt = 100;
			raceData.Bestpts = matrice.defaut_point;
			if raceData.Tps > 0 and matrice.prendre_manche == false then
				raceData.Bestrun = 1;
				raceData.Bestclt = raceData.Clt;
				raceData.Bestpts = raceData.Pts;
			end
			if discipline ~= 'CS' then
				if matrice.prendre_manche == true then
					local arRuns = matrice.course[idxcourse].Runs;
					local diffrun = '';
					tMatrice_Ranking:SetCell('Run'..idxcourse..'_best', idxcoureur, -1);					
					tMatrice_Ranking:SetCell('Clt'..idxcourse..'_best', idxcoureur, -1);					
					tMatrice_Ranking:SetCell('Pts'..idxcourse..'_best', idxcoureur, -1);
					for idxrun = 1, matrice.course[idxcourse].Nombre_de_manche do
						tMatrice_Ranking:SetCell('Pts'..idxcourse..'_run'..idxrun, idxcoureur, -1);
						runData[idxrun] = {};
						runData[idxrun].Tps = tMatrice_Ranking:GetCellInt('Tps'..idxcourse..'_run'..idxrun, idxcoureur, -1);
						if code_coureur == code_coureur_pour_debug or idxcoureur == -1 then
							adv.Alert('\nfor idxrun = 1...  course '..idxcourse..', runData['..idxrun..'].Tps = '..runData[idxrun].Tps); 
						end
						if runData[idxrun].Tps < 0 then
							if runData[idxrun].Tps ~= -500 and runData[idxrun].Tps ~= -800 then
								runData[idxrun].Tps = -600;
								tMatrice_Ranking:SetCell('Tps'..idxcourse..'_run'..idxrun, idxcoureur, -600);
							end
						end
						runData[idxrun].Clt = tMatrice_Ranking:GetCellInt('Clt'..idxcourse..'_run'..idxrun, idxcoureur);
						runData[idxrun].Pts = -1;
						local best_time = arRuns[idxrun].BestTime;
						local diff_maxi = arRuns[idxrun].DiffMaxi;
						local last_time = arRuns[idxrun].LastTime;
						local last_clt = arRuns[idxrun].LastClt;
						matrice.course[idxcourse][idxrun] = {};
						if idxcoureur == 0 and idxrun == 1 and string.find(matrice.comboTypePoint, 'place') then  
							matrice.course[idxcourse][1].MaxiPts = GetPointPlace(1, matrice.course[idxcourse].Grille);
							matrice.course[idxcourse][1].MaxiPts = matrice.course[idxcourse][1].MaxiPts * matrice.course[idxcourse].Coef_manche / 100;
						end		
						if runData[idxrun].Tps > 0 then	-- on peut calculer les points des manches
							diffrun = runData[idxrun].Tps - best_time;
							tMatrice_Ranking:SetCell('Tps'..idxcourse..'_run'..idxrun..'_diff', idxcoureur, diffrun);
							if string.find(matrice.comboTypePoint, 'place') then   -- points place
								runData[idxrun].Pts = GetPointPlace(runData[idxrun].Clt, matrice.course[idxcourse].Grille);
								if code_coureur == code_coureur_pour_debug or idxcoureur == -1 then
									adv.Alert('\npassage 1 runData['..idxrun..'].Pts = '..runData[idxrun].Pts); 
								end
								runData[idxrun].Pts = runData[idxrun].Pts * matrice.course[idxcourse].Coef_manche / 100;
								if code_coureur == code_coureur_pour_debug or idxcoureur == -1 then
									adv.Alert('passage 2 runData['..idxrun..'].Pts = '..runData[idxrun].Pts); 
								end
								runData[idxrun].Pts  = CorrectionPtsPlace(idxcourse, matrice.coefReduction, runData[idxrun].Pts) 
								if code_coureur == code_coureur_pour_debug or idxcoureur == -1 then
									adv.Alert('passage 3 runData['..idxrun..'].Pts = '..runData[idxrun].Pts); 
								end
								if matrice['coefPourcentageMaxiBloc'..matrice.course[idxcourse].Bloc] and matrice['coefPourcentageMaxiBloc'..matrice.course[idxcourse].Bloc] > 0 and diffrun > 0 then
									if diffrun > diff_maxi then
										runData[idxrun].Pts = 0;
									end
								end
								if runData[idxrun].Clt < raceData.Bestclt then
									raceData.Bestrun = idxrun;
									raceData.Bestclt = runData[idxrun].Clt;
									raceData.Bestpts = runData[idxrun].Pts;
								end
							else
								runData[idxrun].Pts = GetPtsCourse(idxcourse, runData[idxrun].Tps, best_time, matrice.course[idxcourse].Facteur_f);
								if runData[idxrun].Pts < raceData.Bestpts then
									raceData.Bestrun = idxrun;
									raceData.Bestclt = runData[idxrun].Clt;
									raceData.Bestpts = runData[idxrun].Pts;
								end
							end
							if code_coureur == code_coureur_pour_debug or idxcoureur == -1 then
								adv.Alert(' \ntpsrun > 0, course '..idxcourse..', runData['..idxrun..'].Tps = '..runData[idxrun].Tps..', tps dans Matrice_Ranking = '..tMatrice_Ranking:GetCellInt('Tps'..idxcourse..'_run'..idxrun, idxcoureur)..', runData['..idxrun..'].Pts = '..runData[idxrun].Pts); 
							end
							tMatrice_Ranking:SetCell('Run'..idxcourse..'_best', idxcoureur, raceData.Bestrun);
							tMatrice_Ranking:SetCell('Clt'..idxcourse..'_best', idxcoureur, raceData.Bestclt);
							tMatrice_Ranking:SetCell('Pts'..idxcourse..'_best', idxcoureur, raceData.Bestpts);
							tMatrice_Ranking:SetCell('Pts'..idxcourse..'_run'..idxrun, idxcoureur, runData[idxrun].Pts);
							-- tMatrice_Ranking:SetCell('Txt_tps'..idxcourse..'_run'..idxrun, idxcoureur, tMatrice_Ranking:GetCell('Tps'..idxcourse..'_run'..idxrun, idxcoureur));
						elseif runData[idxrun].Tps == -500 or runData[idxrun].Tps == -800 or runData[idxrun].Tps == -600 then
							runData[idxrun].Pts = matrice.defaut_point;
							if matrice.comboTpsDuDernier == 'Oui' then
								runData[idxrun].Clt = last_clt + 1;
								tMatrice_Ranking:SetCell('Clt'..idxcourse..'_run'..idxrun, idxcoureur, runData[idxrun].Clt);
								if runData[idxrun].Tps == -500 or runData[idxrun].Tps == -800 then
									runData[idxrun].Tps = last_time;
									if matrice.numMalusAbdDsq < 10 then -- malus en secondes
										runData[idxrun].Tps = runData[idxrun].Tps + (matrice.numMalusAbdDsq * 1000);
									end
									runData[idxrun].Pts = GetPtsCourse(idxcourse, runData[idxrun].Tps, best_time, matrice.course[idxcourse].Facteur_f);
									if matrice.numMalusAbdDsq >= 10 then -- malus en points
										runData[idxrun].Pts = runData[idxrun].Pts + matrice.numMalusAbdDsq;
									end
								else	-- Abs
									runData[idxrun].Tps = last_time;
									if matrice.numMalusAbs < 10 then	-- malus en secondes
										runData[idxrun].Tps = runData[idxrun].Tps + (matrice.numMalusAbs * 1000);
									end
									runData[idxrun].Pts = GetPtsCourse(idxcourse, runData[idxrun].Tps, best_time, matrice.course[idxcourse].Facteur_f);
									if matrice.numMalusAbs >= 10 then
										runData[idxrun].Pts = runData[idxrun].Pts + matrice.numMalusAbs;
									end
								end
								diffrun = runData[idxrun].Tps - best_time;
								tMatrice_Ranking:SetCell('Tps'..idxcourse..'_run'..idxrun..'_diff', idxcoureur, runData[idxrun].Tps - best_time);
								tMatrice_Ranking:SetCell('Pts'..idxcourse..'_run'..idxrun, idxcoureur, runData[idxrun].Pts);
								if code_coureur == code_coureur_pour_debug or idxcoureur == -1 then
									adv.Alert('tpsrun < 0, course '..idxcourse..', runData['..idxrun..'].Tps = '..tostring(runData[idxrun].Tps)..', tps dans Matrice_Ranking = '..tMatrice_Ranking:GetCellInt('Tps'..idxcourse..'_run'..idxrun, idxcoureur)..', runData['..idxrun..'].Pts = '..tostring(runData[idxrun].Pts)); 
								end
							end
						end
						runData[idxrun].Tps = tMatrice_Ranking:GetCellInt('Tps'..idxcourse..'_run'..idxrun, idxcoureur, -600);
						runData[idxrun].Clt = tMatrice_Ranking:GetCellInt('Clt'..idxcourse..'_run'..idxrun, idxcoureur, -1);		
						-- if runData[idxrun].Tps > 0 then
							-- tMatrice_Ranking:SetCell('Txt_tps'..idxcourse..'_run'..idxrun, idxcoureur, tMatrice_Ranking:GetCell('Tps'..idxcourse..'_run'..idxrun, idxcoureur));
						-- end

						if string.find(matrice.course[idxcourse].Prendre, '2') or string.find(matrice.course[idxcourse].Prendre, '3') then
							if code_coureur == code_coureur_pour_debug or idxcoureur == -1 then
								adv.Alert('	-- table.insert(coursesData � la manche : Ordre = '..matrice.course[idxcourse].Ordre..', Run = '..idxrun..', Pts = '..runData[idxrun].Pts)
							end
							table.insert(coursesData, {Code = matrice.course[idxcourse].code, Ordre = matrice.course[idxcourse].Ordre, Obligatoire = matrice.course[idxcourse].Obligatoire, 
								Type = 'manche', Bloc = matrice.course[idxcourse].Bloc, Discipline = matrice.course[idxcourse].Discipline, Tps = runData[idxrun].Tps, Prise = 0,
								Clt = runData[idxrun].Clt, Pts = runData[idxrun].Pts , MaxiPtsRun = runData[idxrun].MaxiPtsRun, Run = idxrun, BestRun = raceData.Bestrun, 
								BestClt = runData[idxrun].Clt, BestPts = runData[idxrun].Pts, PtsTotal = runData[idxrun].Pts, NbManches = matrice.course[idxcourse].Nombre_de_manche});
						end
					end
				end
				if raceData.Bestrun > 0 then
					tMatrice_Ranking:SetCell('Run'..idxcourse..'_best', idxcoureur, raceData.Bestrun);					
					tMatrice_Ranking:SetCell('Clt'..idxcourse..'_best', idxcoureur, raceData.Bestclt);					
					tMatrice_Ranking:SetCell('Pts'..idxcourse..'_best', idxcoureur, raceData.Bestpts);					
				else
					tMatrice_Ranking:SetCell('Run'..idxcourse..'_best', idxcoureur, -1);					
					tMatrice_Ranking:SetCell('Clt'..idxcourse..'_best', idxcoureur, -1);					
					tMatrice_Ranking:SetCell('Pts'..idxcourse..'_best', idxcoureur, -1);
				end
				if type(ajouter[idxcourse][code_coureur]) ~= 'table' then
					raceData.PtsTotal = raceData.Pts;
					tMatrice_Ranking:SetCell('Pts'..idxcourse..'_total', idxcoureur, raceData.PtsTotal);
					if matrice.course[idxcourse].Nombre_de_manche == 1 then
						tMatrice_Ranking:SetCell('Pts'..idxcourse, idxcoureur, raceData.PtsTotal);
					end
				end
				-- if string.find(matrice.course[idxcourse].Prendre, '2') or string.find(matrice.course[idxcourse].Prendre, '3') then
				if string.find(matrice.course[idxcourse].Prendre, '3') and matrice.course[idxcourse].Nombre_de_manche > 1 then
					if code_coureur == code_coureur_pour_debug or idxcoureur == -1 then
						adv.Alert('	-- table.insert(coursesData de la course : Ordre = '..matrice.course[idxcourse].Ordre..', Pts = '..raceData.Pts);
					end
					table.insert(coursesData, {Code = matrice.course[idxcourse].Code, Ordre = matrice.course[idxcourse].Ordre, Obligatoire = matrice.course[idxcourse].Obligatoire, 
						Type = 'course', Bloc = matrice.course[idxcourse].Bloc, Discipline = matrice.course[idxcourse].Discipline, Tps = raceData.Tps, Prise = 0;
						Clt = raceData.Clt, Pts = raceData.Pts, MaxiPtsTotal = matrice.course[idxcourse].MaxiPts, BestRun = raceData.Bestrun, Run = 0,
						BestClt = raceData.Bestclt, BestPts = raceData.Bestpts, PtsTotal = raceData.PtsTotal, NbManches = matrice.course[idxcourse].Nombre_de_manche});
				end

				if not string.find(matrice.course[idxcourse].Prendre, '�') and not string.find(matrice.course[idxcourse].Prendre, 'Idem') then
					if raceData.Bestrun > 0 then
						tMatrice_Ranking:SetCell('Run'..idxcourse..'_best', idxcoureur, raceData.Bestrun);					
						tMatrice_Ranking:SetCell('Clt'..idxcourse..'_best', idxcoureur, raceData.Bestclt);					
						tMatrice_Ranking:SetCell('Pts'..idxcourse..'_best', idxcoureur, raceData.Bestpts);					
					else
						tMatrice_Ranking:SetCell('Run'..idxcourse..'_best', idxcoureur, -1);					
						tMatrice_Ranking:SetCell('Clt'..idxcourse..'_best', idxcoureur, -1);					
						tMatrice_Ranking:SetCell('Pts'..idxcourse..'_best', idxcoureur, -1);
					end
					raceData.PtsTotal = SetPtsTotalCourse(idxcourse, idxcoureur);
					tMatrice_Ranking:SetCell('Pts'..idxcourse..'_total', idxcoureur, raceData.PtsTotal);
					table.insert(coursesData, {Code = matrice.course[idxcourse].Code, Ordre = matrice.course[idxcourse].Ordre, Obligatoire = matrice.course[idxcourse].Obligatoire, 
						Type = 'course', Bloc = matrice.course[idxcourse].Bloc, Discipline = matrice.course[idxcourse].Discipline, Tps = raceData.Tps, Prise = 0;
						Clt = raceData.Clt, Pts = raceData.Pts, MaxiPtsTotal = matrice.course[idxcourse].MaxiPts, BestRun = raceData.Bestrun, Run = 0,
						BestClt = raceData.Bestclt, BestPts = raceData.Bestpts, PtsTotal = raceData.PtsTotal, NbManches = matrice.course[idxcourse].Nombre_de_manche});
				else
					raceData.PtsTotal = SetPtsTotalCourse(idxcourse, idxcoureur);
					tMatrice_Ranking:SetCell('Pts'..idxcourse..'_total', idxcoureur, raceData.PtsTotal);
				end

			else	-- combi saut - manche 1 = saut, manche 2 = manche 
				raceData.Pts = GetPointPlace(raceData.Clt, matrice.course[idxcourse].Grille);
				raceData.PtsTotal = raceData.Pts;
				raceData.Bestrun = 1;
				raceData.Bestclt = 1;
				raceData.Bestpts = 1;
				tMatrice_Ranking:SetCell('Pts'..idxcourse..'_total', idxcoureur, raceData.PtsTotal);
				tMatrice_Ranking:SetCell('Run'..idxcourse..'_best', idxcoureur, 1);					
				tMatrice_Ranking:SetCell('Clt'..idxcourse..'_best', idxcoureur, 1);					
				tMatrice_Ranking:SetCell('Pts'..idxcourse..'_best', idxcoureur, 1);
				table.insert(coursesData, {Code = matrice.course[idxcourse].Code, Ordre = matrice.course[idxcourse].Ordre, Obligatoire = matrice.course[idxcourse].Obligatoire, 
					Type = 'course', Bloc = matrice.course[idxcourse].Bloc, Discipline = 'CS', Tps = raceData.Tps, Prise = 0,
					Clt = raceData.Clt, Pts = raceData.PtsTotal, MaxiPts = raceData.MaxiPts, BestRun = raceData.Bestrun, 
					BestClt = raceData.Bestclt, BestPts = raceData.Bestpts, PtsTotal = raceData.PtsTotal, NbManches = matrice.course[idxcourse].Nombre_de_manche});
			end
		end
		-- fin du parcours des courses
		if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
			adv.Alert('avant SetPtsTotalMatrice, Snapshot Matrice_Ranking_'..code_coureur_pour_debug..'.db3');
			tMatrice_Ranking:Snapshot('Matrice_Ranking_'..code_coureur_pour_debug..'.db3');
		end
		ptsbloc1, ptsmatrice = SetPtsTotalMatrice(idxcoureur, coursesData);
		if tMatrice_Ranking:GetCell('Code_coureur', idxcoureur) == code_coureur_pour_debug then
			adv.Alert('apr�s SetPtsTotalMatrice, ptsbloc1 = '..ptsbloc1..', ptsmatrice = '..ptsmatrice);
		end
		tMatrice_Ranking:SetCell('Pts_bloc1', idxcoureur, ptsbloc1);
		tMatrice_Ranking:SetCell('Pts', idxcoureur, ptsmatrice);
	end
	-- on v�rifie que les coureurs correspondent aux crit�res sinon on les enl�ve
	if matrice.comboGarderInfQuota == 'Non' or matrice.numPtsMaxi < 9999 or matrice.numPtsMini > 0 then
		for idxcoureur = tMatrice_Ranking:GetNbRows() -1 , 0, -1 do
			local delete = false;
			if tMatrice_Ranking:GetCellDouble('Pts', idxcoureur) <= 0 then
				delete = true;
			end
			if delete == false then
				local pts = tMatrice_Ranking:GetCellDouble('Pts', idxcoureur);
				if string.find(matrice.comboTypePoint, 'place') then -- points place
					if matrice.comboGarderInfQuota == 'Non' then
						if pts == matrice.defaut_point then
							delete = true;
						end
					end
					if matrice.numPtsMini > 0 and pts < matrice.numPtsMini then
						delete = true;
					end
				else
					if pts > matrice.defaut_point then
						delete = true;
					end
					if matrice.numPtsMaxi > 0 and pts > matrice.numPtsMaxi then
						delete = true;
					end
				end
			end
			if delete == true then
				tMatrice_Ranking:RemoveRowAt(idxcoureur);
			end
		end
	end

	if string.find(matrice.comboTypePoint, 'place') then
		if matrice.bloc2 == true then
			tMatrice_Ranking:SetRanking('Clt_bloc1', 'Pts_bloc1 DESC', '');
		end
		tMatrice_Ranking:SetRanking('Clt', 'Pts DESC', '');
	else
		if matrice.bloc2 == true then
			tMatrice_Ranking:SetRanking('Clt_bloc1', 'Pts_bloc1', '');
		end
		tMatrice_Ranking:SetRanking('Clt', 'Pts', '');
	end
	if matrice.typeTirage then
		OnCreateCourse();
		app.GetAuiFrame():MessageBox(
			"Cr�ation de la course n� "..matrice.code_inscription.." OK !!!",
			"Cr�ation de la course", 
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
			) 
	end
	SetPtsMaxiBloc1();
	matrice.findescalculs = true;
	dlgWait:Close();
	dlgWait:Delete();
end

function OnPrintAnalyse()
	-- Creation du Report
	if matrice.debug == true then
		adv.Alert("OnPrintAnalyse - Snapshot('Matrice_Ranking_avant_print.db3')");
		tMatrice_Ranking:Snapshot('Matrice_Ranking_avant_print.db3');
	end
	ligne_titre = 'Analyse des performances du circuit sur les classements obtenus.\nLes points de la liste '..matrice.analyseGaucheListe..' obtenus en discipline "'..matrice.analyseGaucheDiscipline..'"\n'..
				'ainsi que le classement mondial sont affich�s � titre d\'information.';
	report = wnd.LoadTemplateReportXML({
		xml = './challenge/matrice.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'printanalyse',
		title = 'Edition du Challenge',
		base = base,
		body = tMatrice_Ranking,
		layers = {file = './edition/layer.xml', id = 'FFS_FIS', page = '*'}, 
		margin_first_top = 100,
		margin_first_left = 100,
		margin_first_right = 100,
		margin_first_bottom = 100,
		margin_top = 100,
		margin_left = 100,
		margin_right = 100,
		margin_bottom = 100,
		paper_orientation = 'landscape',
		params = {Titre = matrice.Titre, Version = scrip_version, Code_evenement = matrice.code_evenement, Liste = matrice.analyseGaucheListe, Discipline = matrice.last_discipline, LigneTitre = ligne_titre}
	});
	-- report:SetZoom(10)
end

function OnPrint()
	if matrice.debug == false then
		for i = tMatrice_Ranking:GetNbColumns() -1, 0, -1 do
			local colname = tMatrice_Ranking:GetColumnName(i);
			if string.find(colname, 'prise') or string.find(colname, 'Analyse') then
				tMatrice_Ranking:RemoveColumnAt(i);
			end
			if not matrice.bloc2 then 
				if string.find(colname, 'bloc') then
					tMatrice_Ranking:RemoveColumnAt(i);
				end
			end
			if not matrice.comboListe1 or tonumber(matrice.comboListe1) == nil then
				if string.find(colname, 'liste1') then
					tMatrice_Ranking:RemoveColumnAt(i);
				end
			end
			if not matrice.comboListe2 then
				if string.find(colname, 'liste2') then
					tMatrice_Ranking:RemoveColumnAt(i);
				end
				if string.find(colname, 'Delta') then
					tMatrice_Ranking:RemoveColumnAt(i);
				end
			end
			if not matrice.typeTirage then
				if string.find(colname, '_inscription') then
					tMatrice_Ranking:RemoveColumnAt(i);
				end
			end
		end
	end
	if matrice.comboTriSortie == 'Classement' then
		tMatrice_Ranking:OrderBy('Clt, Nb_depart DESC');
	elseif matrice.comboTriSortie == 'Ann�e et classement' then
		tMatrice_Ranking:OrderBy('An DESC, Clt, Nb_depart DESC');
	elseif matrice.comboTriSortie == 'Cat�gorie et classement' then
		tMatrice_Ranking:OrderBy('Categ, Clt, Nb_depart DESC');
	elseif matrice.comboTriSortie == 'Comit� et classement' then
		tMatrice_Ranking:OrderBy('Comite, Clt, Nb_depart DESC');
	elseif matrice.comboTriSortie == 'Club et classement' then
		tMatrice_Ranking:OrderBy('Club, Clt, Nb_depart DESC');
	elseif matrice.comboTriSortie == 'Nation et classement' then
		tMatrice_Ranking:OrderBy('Nation, Clt, Nb_depart DESC');
		tMatrice_Ranking:OrderBy('An, Clt, Nb_depart DESC');
	elseif matrice.comboTriSortie == 'Groupe et classement' then
		tMatrice_Ranking:OrderBy('Groupe, Clt, Nb_depart DESC');
	elseif matrice.comboTriSortie == 'Equipe et classement' then
		tMatrice_Ranking:OrderBy('Equipe, Clt, Nb_depart DESC');
	elseif matrice.comboTriSortie == 'Crit�re et classement' then
		tMatrice_Ranking:OrderBy('Critere, Clt, Nb_depart DESC');
	end
	-- Creation du Report
	if not matrice.comboOrientation or matrice.comboOrientation == 'Paysage' then
		matrice.comboOrientation = 'landscape';
	end
	if matrice.debug == true then
		adv.Alert("OnPrint - Snapshot('Matrice_Ranking_avant_print.db3')");
		tMatrice_Ranking:Snapshot('Matrice_Ranking_avant_print.db3');
		adv.Alert("\n\n les affichages suivant viennent du report !!");
	end


	--tMatrice_Ranking:Snapshot('Matrice_Ranking_avant_print.db3');



	local utf8 = true;
	matrice.comboOrientation = string.lower(matrice.comboOrientation);
	local txtcoefmaxi = 'Coef Maxi en plus du temps du premier pour marquer des points : ';
	if matrice.coefPourcentageMaxiBloc1 > 0 then
		txtcoefmaxi = txtcoefmaxi..matrice.coefPourcentageMaxiBloc1..' % / bloc 1';
	end
	matrice.criteres_bloc1 = matrice.criteres_bloc1 or '';
	matrice.criteres_bloc2 = matrice.criteres_bloc2 or '';
	if matrice.numTypeCritere then
		if matrice.numTypeCritere == 1 then
			if matrice.criteres_bloc1:len() < 10 then
				matrice.criteres_bloc1 = '';
			end
			if matrice.criteres_bloc2:len() < 10 then
				matrice.criteres_bloc2 = '';
			end
		else	
			if matrice.criteres_bloc1:len() < 20 then
				matrice.criteres_bloc1 = '';
			end
			if matrice.criteres_bloc2:len() < 20 then
				matrice.criteres_bloc2 = '';
			end
		end
	end
	if matrice.bloc2 and matrice.coefPourcentageMaxiBloc2 > 0 then
		if txtcoefmaxi:len() > 35 then
			txtcoefmaxi = txtcoefmaxi..'  -  '..matrice.coefPourcentageMaxiBloc2..' % / bloc 2';
		else
			txtcoefmaxi = txtcoefmaxi..matrice.coefPourcentageMaxiBloc2..' % / bloc 2';
		end
	end
	matrice.criteres_bloc2 = matrice.criteres_bloc2 or '';
	if matrice.criteres_bloc2:len() < 10 then
		matrice.criteres_bloc2 = '';
	end
	local pagelayer = '*';
	if matrice.texteImprimerLayer:len() > 0 then
		if string.find(matrice.texteImprimerLayerPage, '1') then
			pagelayer = '1';
		elseif string.find(matrice.texteImprimerLayerPage, '2') then
			pagelayer = '2';
		end
	end
	local separateur = '';
	matrice.penalisationsaut = matrice.penalisationsaut or '';
	local nbdepartmini = matrice.numDepartMini or -1;
	if matrice.TitreAdd then
		matrice.TitrePrn = matrice.TitrePrn..matrice.TitreAdd;
	else
		matrice.TitrePrn = matrice.Titre;
	end
	if matrice.next == false then
		report = wnd.LoadTemplateReportXML({
			xml = './challenge/matrice.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = 'Edition du Challenge',
			base = base,
			body = tMatrice_Ranking,
			layers = {file = './edition/layer.perso.xml', id = matrice.texteImprimerLayer, page = pagelayer}, 
			margin_first_top = math.floor(matrice.texteMargeHaute1 * 100),
			margin_first_left = 100,
			margin_first_right = 100,
			margin_first_bottom = 100,
			margin_top = math.floor(matrice.texteMargeHaute2 * 100),
			margin_left = 100, 
			margin_right = 100,
			margin_bottom = 100,
			paper_orientation = matrice.comboOrientation,
			params = {Titre = matrice.TitrePrn, Table_critere = matrice.table_critere, PenalisationSaut = matrice.penalisationsaut, FontSize = matrice.texteFontSize, Code_evenement = matrice.code_evenement, Version = scrip_version, Bloc2 = matrice.bloc2, ImprimerColonnes = matrice.imprimerColonnes, PrendreBloc1 = matrice.comboPrendreBloc1, ImprimerBloc1 = matrice.imprimerBloc1, ImprimerCombiSaut = matrice.imprimerCombiSaut, PrendreBloc2 = matrice.comboPrendreBloc2, ImprimerBloc2 = matrice.imprimerBloc2, CoursesIn = matrice.Evenement_selection, LastBloc1 = matrice.lastBloc1, Saison = matrice.Saison, Activite = matrice.comboActivite, Entite = matrice.comboEntite, AbdDsq = matrice.comboAbdDsq, TpsDernier = matrice.comboTpsDuDernier, Presentation = matrice.comboPresentationCourses, ImprimerHeader = matrice.texteImprimerHeader, TypePoint = matrice.comboTypePoint, Criteres1 = matrice.criteres_bloc1, Criteres2 = matrice.criteres_bloc2, PtsMaxiBloc1 = matrice.MaxiPtsBloc1, DepartMini = nbdepartmini, ParticipationMini = matrice.numMinimumArrivee, CoefMaxiBlocs = txtcoefmaxi}
		});
	else
		if not report then
			report = wnd.LoadTemplateReportXML({
				xml = './challenge/matrice.xml',
				node_name = 'root/panel',
				node_attr = 'id',
				node_value = 'print',
				title = 'Edition du Challenge',
				base = base,
				body = tMatrice_Ranking,
				layers = {file = './edition/layer.perso.xml', id = matrice.texteImprimerLayer, page = pagelayer}, 
				margin_first_top = math.floor(matrice.texteMargeHaute1 * 100),
				margin_first_left = 100,
				margin_first_right = 100,
				margin_first_bottom = 100,
				margin_top = math.floor(matrice.texteMargeHaute2 * 100),
				margin_left = 100, 
				margin_right = 100,
				margin_bottom = 100,
				paper_orientation = matrice.comboOrientation,
				params = {Titre = matrice.TitrePrn, Table_critere = matrice.table_critere, PenalisationSaut = matrice.penalisationsaut, FontSize = matrice.texteFontSize, Code_evenement = matrice.code_evenement, Version = scrip_version, Bloc2 = matrice.bloc2, ImprimerColonnes = matrice.imprimerColonnes, PrendreBloc1 = matrice.comboPrendreBloc1, ImprimerBloc1 = matrice.imprimerBloc1, ImprimerCombiSaut = matrice.imprimerCombiSaut, PrendreBloc2 = matrice.comboPrendreBloc2, ImprimerBloc2 = matrice.imprimerBloc2, CoursesIn = matrice.Evenement_selection, LastBloc1 = matrice.lastBloc1, Saison = matrice.Saison, Activite = matrice.comboActivite, Entite = matrice.comboEntite, AbdDsq = matrice.comboAbdDsq, TpsDernier = matrice.comboTpsDuDernier, Presentation = matrice.comboPresentationCourses, ImprimerHeader = matrice.texteImprimerHeader, TypePoint = matrice.comboTypePoint, Criteres1 = matrice.criteres_bloc1, Criteres2 = matrice.criteres_bloc2, PtsMaxiBloc1 = matrice.MaxiPtsBloc1, DepartMini = nbdepartmini, ParticipationMini = matrice.numMinimumArrivee, CoefMaxiBlocs = txtcoefmaxi}
			});
		end
		editor = report:GetEditor();
		editor:PageBreak(); -- Saut de Page entre les 2 �ditions ...
		wnd.LoadTemplateReportXML({
			xml = './challenge/matrice.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = 'Edition du Challenge',
			report = report,
			base = base,
			body = tMatrice_Ranking,
			layers = {file = './edition/layer.perso.xml', id = matrice.texteImprimerLayer, page = pagelayer}, 
			margin_first_top = math.floor(matrice.texteMargeHaute1 * 100),
			margin_first_left = 100,
			margin_first_right = 100,
			margin_first_bottom = 100,
			margin_top = math.floor(matrice.texteMargeHaute2 * 100),
			margin_left = 100, 
			margin_right = 100,
			margin_bottom = 100,
			paper_orientation = matrice.comboOrientation,
			params = {Titre = matrice.TitrePrn, Table_critere = matrice.table_critere, PenalisationSaut = matrice.penalisationsaut, FontSize = matrice.texteFontSize, Code_evenement = matrice.code_evenement, Version = scrip_version, Bloc2 = matrice.bloc2, ImprimerColonnes = matrice.imprimerColonnes, PrendreBloc1 = matrice.comboPrendreBloc1, ImprimerBloc1 = matrice.imprimerBloc1, ImprimerCombiSaut = matrice.imprimerCombiSaut, PrendreBloc2 = matrice.comboPrendreBloc2, ImprimerBloc2 = matrice.imprimerBloc2, CoursesIn = matrice.Evenement_selection, LastBloc1 = matrice.lastBloc1, Saison = matrice.Saison, Activite = matrice.comboActivite, Entite = matrice.comboEntite, AbdDsq = matrice.comboAbdDsq, TpsDernier = matrice.comboTpsDuDernier, Presentation = matrice.comboPresentationCourses, ImprimerHeader = matrice.texteImprimerHeader, TypePoint = matrice.comboTypePoint, Criteres1 = matrice.criteres_bloc1, Criteres2 = matrice.criteres_bloc2, PtsMaxiBloc1 = matrice.MaxiPtsBloc1, DepartMini = nbdepartmini, ParticipationMini = matrice.numMinimumArrivee, CoefMaxiBlocs = txtcoefmaxi}
		});
	end
	-- report:SetZoom(10)
end

function LitMatriceCourses(bolcalculer);	-- lecture des courses figurant dans la valeur Evenement_selection de la table Evenement_Matrice
	matrice.prendre_manche = false;
	if not matrice.Evenement_selection or matrice.Evenement_selection:len() == 0 then
		return false;
	end
	RempliTableauMatrice();
	local cmd = 'Select * from Epreuve Where Code_evenement In('..matrice.Evenement_selection..') Order By Nombre_de_manche DESC';
	tEpreuve = base:TableLoad(cmd);
	local nb_manche_max = tEpreuve:GetCellInt('Nombre_de_manche', 0);
	local cmd = "Select Ev.Code, 0 Ordre, Repeat(' ',2) Flag_param, Ev.Nom, Ev.Code_saison, Ep.Date_epreuve, Ep.Code_epreuve, Ep.Code_discipline, Repeat(' ',10) Discipline_alpine, 0 Participation, 0 Facteur_f, Ep.Nombre_de_manche, Ev.Station, Ev.Codex, Ev.Code_liste, 0 Bloc, 0 Obligatoire, 0 Prise, 0 Skip, 0 Coef_course, 0 Coef_manche, 0 Best_time, 0 Tps_maxi, 0 Diff_maxi, 0 Last_time, 0 Last_clt, 0 Nb_col, 0 Col_start";
	for i = 1, nb_manche_max do
		cmd = cmd.." ,0 Best_time_m"..i..", 0 Tps_maxi_m"..i..", 0 Diff_maxi_m"..i..", 0 Last_time_m"..i..", 0 Last_clt_m"..i;
	end
	cmd = cmd .." , Repeat(' ',50) Grille, Repeat(' ',60) Prendre, 0 Bloc1_maxi "..
	" From Evenement Ev, Epreuve Ep "..
	" Where Ev.Code = Ep.Code_evenement "..
	" And Ev.Code In("..matrice.Evenement_selection..") And Ep.Code_epreuve = 1 "..
	" Order By Ep.Date_epreuve, Code";
	tMatrice_Courses = base:TableLoad(cmd);
	tMatrice_Courses:SetPrimary('Code');
	tMatrice_Courses:ChangeColumn('Bloc1_maxi', 'double');
	ReplaceTableEnvironnement(tMatrice_Courses, '_Matrice_Courses');
	matrice.typeBuild = matrice.typeBuild or 1;
	if bolcalculer == true then
		if matrice.numArretCalculApres and matrice.numArretCalculApres > 0 then 	-- supprimer les courses en trop
			for i = tMatrice_Courses:GetNbRows() -1 , 0, -1 do	
				if i >= matrice.numArretCalculApres then
					tMatrice_Courses:RemoveRowAt(i);			
				end											
			end		
		end
		for i = tMatrice_Courses:GetNbRows() -1 , 0, -1 do	
			local code = tMatrice_Courses:GetCellInt('Code', i);
			local racine = '['..code..']_';	-- Ex : [1549]_		recherche des param�trages particuliers des courses
			if matrice[racine..'comboSkip'] then
				if i >= matrice.numArretCalculApres then
					tMatrice_Courses:RemoveRowAt(i);			
				end											
			end
		end		
	end
	matrice.bloc2 = false;
	matrice.combisaut = false;
	matrice.lastBloc1 = 0;
	matrice.nb_bloc1 = 0;
	matrice.nb_bloc2 = 0;
	matrice.nb_ajoutes = 0;
	matrice.course = {};
	matrice.disciplines = {};
	matrice.discipline = {};
	ajouter = {};
	for i = 0, tMatrice_Courses:GetNbRows() -1 do
		local idxcourse = i + 1;
		tMatrice_Courses:SetCell('Ordre', i, idxcourse);
		local bloc = 1;
		local flag_param = false;
		local code = tMatrice_Courses:GetCellInt('Code', i);
		local nombre_de_manche = tMatrice_Courses:GetCellInt('Nombre_de_manche',i);
		local discipline = tMatrice_Courses:GetCell('Code_discipline',i);
		local discipline_alpine = discipline;
		if tMatrice_Courses:GetCell('Code_discipline', i) == 'CS' then
			matrice.combisaut = true;
			if matrice.debug == true then
				adv.Alert('Select * From Epreuve_Alpine Where Code_evenement = '..tMatrice_Courses:GetCellInt('Code', i)..' And Code_epreuve = 1');
			end
			base:TableLoad(tEpreuve_Alpine, 'Select * From Epreuve_Alpine Where Code_evenement = '..tMatrice_Courses:GetCellInt('Code', i)..' And Code_epreuve = 1');
			discipline_alpine = tEpreuve_Alpine:GetCell('Info', 0);
			if discipline_alpine:len() == 0 then
				discipline_alpine = 'GS';
			end
		end
		tMatrice_Courses:SetCell('Discipline_alpine', i, discipline_alpine);
		if matrice.debug == true then
			adv.Alert('discipline alpine de la course '..idxcourse..' = '..discipline_alpine)
		end
		
		for j = 0, tDiscipline:GetNbRows() -1 do
			if matrice.debug == true then
				adv.Alert("course n� "..(i+1)..", tDiscipline:GetCell('Code', j) = "..tDiscipline:GetCell('Code', j)..", discipline_alpine = "..discipline_alpine..", tDiscipline:GetCellInt('Facteur_f', j) = "..tDiscipline:GetCellInt('Facteur_f', j));
			end
			if tDiscipline:GetCell('Code', j) == discipline_alpine then
				tMatrice_Courses:SetCell('Facteur_f', i, tDiscipline:GetCellInt('Facteur_f', j))
			end
		end		-- Facteur_f est celui de la course ou bien de la manche alpine du combi saut
		
		local racine = '['..code..']_';	-- Ex : [1549]_		recherche des param�trages particuliers des courses
		if matrice[racine..'numBloc'] then
			bloc = 2;
			flag_param = true;
			matrice.bloc2 = true;
		end
		if bloc == 1 then matrice.lastBloc1 = idxcourse; end
		tMatrice_Courses:SetCell('Bloc', i, bloc);
		if matrice[racine..'coefCourse'] then
			tMatrice_Courses:SetCell('Coef_course', i, matrice[racine..'coefCourse']);
			flag_param = true;
		else
			tMatrice_Courses:SetCell('Coef_course', i, matrice['coefDefautCourseBloc'..bloc]);
		end
		if matrice[racine..'coefManche'] then
			tMatrice_Courses:SetCell('Coef_manche', i, matrice[racine..'coefManche']);
			flag_param = true;
		else
			tMatrice_Courses:SetCell('Coef_manche', i, matrice['coefDefautMancheBloc'..bloc]);
		end
		if matrice[racine..'comboPrendre'] then
			tMatrice_Courses:SetCell('Prendre', i, matrice[racine..'comboPrendre']);
			flag_param = true;
		else
			tMatrice_Courses:SetCell('Prendre', i, matrice['comboPrendreBloc'..bloc]);
		end
		if matrice[racine..'comboObligatoire'] then
			tMatrice_Courses:SetCell('Obligatoire', i, -1);
			flag_param = true;
		end
		if matrice[racine..'comboSkip'] then
			tMatrice_Courses:SetCell('Skip', i, 1);
			flag_param = true;
		end
		if matrice[racine..'comboGrille'] then
			tMatrice_Courses:SetCell('Grille', i, matrice[racine..'comboGrille']);
			flag_param = true;
		else
			tMatrice_Courses:SetCell('Grille', i, matrice.comboGrille);
		end
		if flag_param == true then 
			tMatrice_Courses:SetCell('Flag_param', i, '* ');
		end

		if not matrice.disciplines[discipline] then
			matrice.disciplines[discipline] = {};
			matrice.disciplines[discipline][1] = {};
			matrice.disciplines[discipline][2] = {}
			matrice.disciplines[discipline][1].nombre = 0;
			matrice.disciplines[discipline][2].nombre = 0;
			table.insert(matrice.discipline, {Code = discipline, Facteur_f = tMatrice_Courses:GetCellInt('Facteur_f', i)});
		end
		if not matrice.disciplines['*'] then 
			matrice.disciplines['*'] = {};
			matrice.disciplines['*'][1] = {};
			matrice.disciplines['*'][2] = {};
			matrice.disciplines['*'][1].nombre = 0;
			matrice.disciplines['*'][2].nombre = 0;
		end
		matrice.disciplines[discipline][bloc].nombre = matrice.disciplines[discipline][bloc].nombre + 1;
		matrice.disciplines['*'][bloc].nombre = matrice.disciplines['*'][bloc].nombre + 1;
	
		local placevaleur = {};
		if string.find(matrice.comboTypePoint, 'place') then   
			local grille = tMatrice_Courses:GetCell('Grille', i);
			local r = tGrille_Point_Place:GetIndexRow('Libelle', grille);
			if r and r >= 0 then
				local cmd = "Select * From Place_valeur Where Code_activite = '"..matrice.code_activite.."' And Code_grille = '"..tGrille_Point_Place:GetCell('Code', r).."' And Code_saison = '"..matrice.Saison.."' Order By Place";
				base:TableLoad(tPlace_Valeur, cmd);
				for i = 0, tPlace_Valeur:GetNbRows()-1 do
					table.insert(placevaleur, { Place = tPlace_Valeur:GetCellInt('Place', i), Point = tPlace_Valeur:GetCellDouble('Point', i) });
				end
			end
			if string.find(tMatrice_Courses:GetCell('Prendre', i), '�') or string.find(tMatrice_Courses:GetCell('Prendre', i), 'Idem') then		
				tMatrice_Courses:SetCell('Coef_course', i, 100);
				tMatrice_Courses:SetCell('Coef_manche', i, 100);
			end
		else  
			tMatrice_Courses:SetCell('Coef_course', i, 100);
			tMatrice_Courses:SetCell('Coef_manche', i, 100);
		end
		if nombre_de_manche == 1 then
			tMatrice_Courses:SetCell('Coef_manche', i, tMatrice_Courses:GetCellInt('Coef_course', i));
		end
		ajouter[idxcourse] = {};
		local cle_ajouter = '%['..code..'%]_ajouter';
		for i = 0, tEvenement_Matrice:GetNbRows()-1 do
			local cle = tEvenement_Matrice:GetCell('Cle', i);
			if string.find(cle, cle_ajouter) then
				local pts =tonumber(tEvenement_Matrice:GetCell('Valeur', i)) or 0;
				local identite = '';
				local tData = cle:Split('|');
				local code_coureur = tData[2];
				matrice.nb_ajoutes = matrice.nb_ajoutes + 1;
				ajouter[idxcourse][code_coureur] = {};
				ajouter[idxcourse][code_coureur].Pts = pts;
			end
		end
		matrice.last_discipline = discipline;
		matrice.last_liste = tMatrice_Courses:GetCell('Code_liste', i);
		table.insert(matrice.course, 
			{Code = tMatrice_Courses:GetCell('Code', i), 
			Bloc = tMatrice_Courses:GetCellInt('Bloc', i), 
			Codex = tMatrice_Courses:GetCell('Codex', i), 
			Code_liste = tMatrice_Courses:GetCellInt('Code_liste', i), 
			Code_saison = tMatrice_Courses:GetCell('Code_saison', i), 
			Coef_course = tMatrice_Courses:GetCellInt('Coef_course', i), 
			Coef_manche = tMatrice_Courses:GetCellInt('Coef_manche', i), 
			Date_epreuve = tMatrice_Courses:GetCell('Date_epreuve', i), 
			Discipline = tMatrice_Courses:GetCell('Code_discipline', i),  
			Discipline_alpine = discipline_alpine, 
			Facteur_f = tMatrice_Courses:GetCellInt('Facteur_f', i), 
			Grille = placevaleur, 
			Nom = tMatrice_Courses:GetCell('Nom', i), 
			Nombre_de_manche = tMatrice_Courses:GetCellInt('Nombre_de_manche', i), 
			Obligatoire = tMatrice_Courses:GetCellInt('Obligatoire', i), 
			Ordre = idxcourse, 
			Prendre = tMatrice_Courses:GetCell('Prendre', i),
			Skip = tMatrice_Courses:GetCellInt('Skip', i),
			Station = tMatrice_Courses:GetCell('Station', i), 
			Best_time = 0, 
			Diff_maxi = 0,
			Last_clt = 0, 
			Last_time = 0, 
			Participation = 0,
			Tps_maxi = 0, 
			Runs = {}
			});
	end
	for i = 0,  tMatrice_Courses:GetNbRows() -1 do
		if matrice.numTypeCritere < 3 then 
			if discipline ~= 'CS' then
				if not string.find(matrice.comboPrendreBloc1, '1%.') then
					matrice.prendre_manche = true;
				end
				if matrice.bloc2 == true then
					if not string.find(matrice.comboPrendreBloc2, '1%.') then
						matrice.prendre_manche = true;
					end
				end
				local prendre = tMatrice_Courses:GetCell('Prendre', i);
				if not string.find(prendre, '1%.') then
					matrice.prendre_manche = true;
				end
				if matrice.prendre_manche == false then 
					tMatrice_Courses:SetCell('Nombre_de_manche', i, 0);
					matrice.course[(i+1)].Nombre_de_manche = 0;
				end
			end
		end
	end

	SortTable('<', matrice.discipline, {'Facteur_f'});
	if matrice.debug == true then
		adv.Alert("LitMatriceCourses - Snapshot('Matrice_Courses.db3')");
		tMatrice_Courses:Snapshot('Matrice_Courses.db3');
	end
end

function RempliTableauMatrice()		-- lescture de toutes les variables de la table Evenement_Matrice et affectation �ventuelle des variables dans les contr�les de la bo�te de dialogue
	local cmd = 'Select * From Evenement_Matrice Where Code_evenement = '..matrice.code_evenement..' Order By Cle';
	base:TableLoad(tEvenement_Matrice, cmd);
	for i = 0, tEvenement_Matrice:GetNbRows() -1 do
		local control = tEvenement_Matrice:GetCell("Cle", i); -- donne le nom du contr�le
		local valeur = nil;		
		-- les variables contenant 'num ou 'coef' sont des variables num�riques
		if (string.find(control, 'num')) or (string.find(control, 'coef')) then
			valeur = GetValueNumber(control, 0);  	-- retourne 0 si on ne trouve pas de valeur
			matrice[control] = valeur;
		else
			valeur = GetValue(control, '');			-- retourne '' si on ne trouve pas de valeur
			matrice[control] = valeur;
		end
		if string.find(control, 'critere') then
			matrice.numTypeCritere = tonumber(control:sub(1,1)) or 0;
		end
	end
	dlgConfig:Refresh();
end

function CreateTablesCombo()

	tOuiNon = sqlTable.Create('_OuiNon');
	tOuiNon:AddColumn({ name = 'Choix', label = 'Choix', type = sqlType.CHAR , width = 3});
	local row = tOuiNon:AddRow()
	tOuiNon:SetCell('Choix', row , 'Oui');
	local row = tOuiNon:AddRow()
	tOuiNon:SetCell('Choix', row , 'Non');
	ReplaceTableEnvironnement(tOuiNon, '_OuiNon');
	
	tColResultatPar = {};
	tResultatPar = sqlTable.Create('_ResultatPar');
	tResultatPar:AddColumn({ name = 'Choix', label = 'Choix', type = sqlType.CHAR , width =10});
	local row = tResultatPar:AddRow()
	tResultatPar:SetCell('Choix', row , 'Sans objet');
	local row = tResultatPar:AddRow()
	tResultatPar:SetCell('Choix', row , 'Cat�gorie');
	table.insert(tColResultatPar, 'Categ');
	local row = tResultatPar:AddRow()
	tResultatPar:SetCell('Choix', row , 'Groupe');
	table.insert(tColResultatPar, 'Groupe');
	local row = tResultatPar:AddRow()
	tResultatPar:SetCell('Choix', row , 'Equipe');
	table.insert(tColResultatPar, 'Equipe');
	local row = tResultatPar:AddRow()
	tResultatPar:SetCell('Choix', row , 'Crit�re');
	table.insert(tColResultatPar, 'Crit�re');
	ReplaceTableEnvironnement(tResultatPar, '_ResultatPar');
	
end

function CreateTableListe()
	local cmd = 'Select ';
	if matrice.comboActivite == 'ALP' then
		if matrice.comboEntite == 'FFS' then
			cmd  = cmd..' * From Liste Where Seasoncode = '..matrice.Saison.." And Type_classement = 'FAU' Order By Validfrom";
		else
			cmd  = cmd..' * From Liste Where Seasoncode = '..matrice.Saison.." And Type_classement = 'IAU' Order By Validfrom";
		end
	else
	end
	base:TableLoad(tListe, cmd);
end

function CreateTypeClassement()
	if matrice.comboActivite == "ALP" then
		if matrice.comboEntite == 'FIS' then
			cmd = "Select Code, Libelle, Ordre From Type_classement Where Code IN('IASL', 'IAGS', 'IASG', 'IASC') Order By Ordre";
 		else
			cmd = "Select Code, Libelle, Ordre From Type_classement Where Code IN('FAU') Order By Ordre";
		end
		base:TableLoad(tType_Classement, cmd);
		if matrice.comboEntite == 'FIS' then
			local row = tType_Classement:AddRow();
			tType_Classement:SetCell('Code', row, 'Technique');
			tType_Classement:SetCell('Libelle', row, 'Meilleurs Pts en SL / GS');
			tType_Classement:SetCell('Ordre', row, 100);
			local row = tType_Classement:AddRow();
			tType_Classement:SetCell('Code', row, 'Vitesse');
			tType_Classement:SetCell('Libelle', row, 'Meilleurs Pts en SG / DH');
			tType_Classement:SetCell('Ordre', row, 200);
		end
	else
	end
	if matrice.debug == true then
		adv.Alert("tType_Classement:Snapshot('Type_Classement.db3')");
		tType_Classement:Snapshot('Type_Classement.db3');
	end
end

function LitMatrice()	-- lecture des variables et affectation des valeurs dans les contr�les
	matrice.configFiltre = 1;
	matrice.numTypeCritere = 0;
	-- on charge toutes les lignes de la table Evenement_Matrice pour le matrice.code_evenement donn�
	-- le tableau associatif matrice est v�rifi� et compl�t� si besoin.
	RempliTableauMatrice();
	-- matrice.analyseGaucheClassement = matrice.analyseGaucheClassement or 'Listes';
	
	matrice.analyseGaucheListe = matrice.analyseGaucheListe or '';
	matrice.analyseGaucheDiscipline = matrice.analyseGaucheDiscipline or '';
	matrice.coefDefautCourseBloc1 = matrice.coefDefautCourseBloc1 or GetValueNumber("coefDefautCourseBloc1", 100);
	matrice.coefDefautCourseBloc2 = matrice.coefDefautCourseBloc2 or GetValueNumber("coefDefautCourseBloc2", 100);
	matrice.coefDefautMancheBloc1 = matrice.coefDefautMancheBloc1 or GetValueNumber("coefDefautMancheBloc1", 100);
	matrice.coefDefautMancheBloc2 = matrice.coefDefautMancheBloc2 or GetValueNumber("coefDefautMancheBloc2", 100);
	matrice.coefPourcentageMaxiBloc1 = matrice.coefPourcentageMaxiBloc1 or GetValueNumber("coefPourcentageMaxiBloc1", 0);
	matrice.coefPourcentageMaxiBloc2 = matrice.coefPourcentageMaxiBloc2 or GetValueNumber("coefPourcentageMaxiBloc2", 0);
	matrice.coefReduction = matrice.coefReduction or GetValueNumber("coefReduction", 0);
	matrice.comboAbdDsq = matrice.comboAbdDsq or GetValue("comboAbdDsq", "Non");
	matrice.comboActivite = matrice.comboActivite or GetValue("comboActivite", "ALP");
	matrice.comboEntite = matrice.comboEntite or GetValue("comboEntite", "FFS");
	matrice.comboGarderInfQuota = matrice.comboGarderInfQuota or GetValue("comboGarderInfQuota", "Non");
	matrice.comboListe1 = matrice.comboListe1 or GetValue('comboListe1', nil);
	matrice.comboListe2 = matrice.comboListe2 or GetValue('comboListe2', nil);
	matrice.comboListe1Classement = matrice.comboListe1Classement or GetValue('comboListe1Classement', nil);
	matrice.comboListe2Classement = matrice.comboListe2Classement or GetValue('comboListe2Classement', nil);
	matrice.comboListePrimaute = matrice.comboListePrimaute or GetValue('comboListePrimaute', 'au classement');
	matrice.comboOrientation = matrice.comboOrientation or GetValue("comboOrientation", 'Portrait');
	matrice.comboPrendreBloc1 = matrice.comboPrendreBloc1 or GetValue("comboPrendreBloc1", "Classement g�n�ral");
	matrice.comboPrendreBloc2 = matrice.comboPrendreBloc2 or GetValue("comboPrendreBloc2", "Classement g�n�ral");
	matrice.comboPresentationCourses = matrice.comboPresentationCourses or GetValue("comboPresentationCourses", "Pr�sentation horizontale type Ski Chrono Tour (par d�faut)");
	matrice.comboSexe = matrice.comboSexe or GetValue("comboSexe", '');
	matrice.comboResultatPar = matrice.comboResultatPar or GetValue("comboResultatPar", 'Sans objet');
	local chaine = "$(Sexe):In('"..matrice.comboSexe.."')";
	matrice.Cle_filtrage = matrice.Cle_filtrage or GetValue("Cle_filtrage", chaine);
	matrice.tGroupesCalcul = {};
	matrice.tResultatsGroupes = {};
	
	-- local chaine_er = "and %$%(Groupe%):In%('TOUS'%)";
	-- local chaine_categ = "and %$%(Categ%):In%('TOUS'%)";
	local cmd = "Select Distinct Categ From Resultat Where Code_evenement in ("..matrice.Evenement_selection..") And Sexe = '"..matrice.comboSexe.."'";
	tCategPresentes = base:TableLoad(cmd);
	tCategPresentes:SetCounter('Categ');
	ReplaceTableEnvironnement(tCategPresentes, '_tCategPresentes');
	local selectionresultatpar = 0;
	if matrice.comboResultatPar ~= 'Sans objet' then
		if matrice.comboResultatPar == 'Cat�gorie' then
			selectionresultatpar = 1;
		elseif matrice.comboResultatPar == 'Groupe' then
			selectionresultatpar = 2;
		elseif matrice.comboResultatPar == 'Equipe' then
			selectionresultatpar = 3;
		elseif matrice.comboResultatPar == 'Crit�re' then
			selectionresultatpar = 4;
		end
	end
	if selectionresultatpar > 0 then
		menuPrint:Enable(btnAnalyse:GetId(), false) ;
		matrice.col_resultat_par = tColResultatPar[selectionresultatpar];
		local parcol = tColResultatPar[selectionresultatpar];
		 cmd = "Select Code_coureur, "..parcol.." From Resultat Where Code_evenement in ("..matrice.Evenement_selection..") And Sexe = '"..matrice.comboSexe.."' Group By Code_coureur, "..parcol;
		local tGroupes = base:TableLoad(cmd)
		tGroupes:SetCounter(parcol);
		for i = 0, tGroupes:GetCounter(parcol):GetNbRows() -1 do 
			table.insert(matrice.tGroupesCalcul, {ColGroupe = parcol, Groupe = tGroupes:GetCounter(parcol):GetCell(0,i), Nombre = tGroupes:GetCounter(parcol):GetCellInt(1,i), Filtre = matrice.Cle_filtrage.." and $("..parcol.."):In('"..tGroupes:GetCounter(parcol):GetCell(0,i).."')"});
		end
		 cmd = "Select Code_coureur, "..parcol.." From Resultat Where Code_evenement in ("..matrice.Evenement_selection..") And Sexe = '"..matrice.comboSexe.."' Group By Code_coureur, "..parcol;
		local tGroupes = base:TableLoad(cmd)
		tGroupes:SetCounter(parcol);
		for i = 0, tGroupes:GetCounter(parcol):GetNbRows() -1 do
			local filtre = matrice.Cle_filtrage.." and $("..parcol.."):In('"..tGroupes:GetCounter(parcol):GetCell(0,i).."')"
			table.insert(matrice.tResultatsGroupes, 
				{ColRegroupement = parcol, 
				Nombre = tGroupes:GetCounter(parcol):GetCellInt(1,i), 
				Filtre = filtre
				}
			);
		end
	end

	matrice.comboTpsDuDernier = matrice.comboTpsDuDernier or GetValue("comboTpsDuDernier", "Non");
	matrice.comboTriSortie = matrice.comboTriSortie or GetValue("comboTriSortie", "Classement");
	matrice.comboTypePoint = matrice.comboTypePoint or GetValue("comboTypePoint", "Points place");
	matrice.imprimerBloc1 = matrice.imprimerBloc1 or 'Clt,0,Clt|Tps,0,Tps|Diff,0,Diff|Pts,1,Pts|Cltrun,0,Clt|Tpsrun,0,Tps|Diffrun,0,Diff|Ptsrun,0,M.|Ptstotal,0,Total|EtapeClt,0,Clt|EtapePts,0,Pts';
	matrice.imprimerBloc2 = matrice.imprimerBloc2 or 'Clt,0|Tps,0|Diff,0|Pts,1|Cltrun,0|Tpsrun,0|Diffrun,0|Ptsrun,0|Ptstotal,0';
	matrice.imprimerCombiSaut = matrice.imprimerCombiSaut or 'Cltcs,1|Lng_saut,1|Clt_saut,1|Pts_saut,1|Tps_alpin,1|Clt_alpin,1|Pts_alpin,1|Ptstotalcs,1';
	matrice.imprimerColonnes = matrice.imprimerColonnes or 'Code_coureur,Code,center,1|Identite,Identit�,left,1|Sexe,S.,center,1|An,An,center,1|Categ,Cat.,center,0|Nation,Nat.,center,0|Comite,CR,center,0|Club,Club,left,0|Groupe,Groupe,left,0|Equipe,Equipe,left,0|Critere,Crit�re,left,0|Liste1,Liste,center,0|Liste2,Liste,center,0|Delta,Delta,center,0';
	matrice.numArretCalculApres = matrice.numArretCalculApres or GetValueNumber("numArretCalculApres", 0);
	matrice.numDepartMini = matrice.numDepartMini or GetValueNumber("numDepartMini", 0);
	matrice.numMalusAbdDsq = matrice.numMalusAbdDsq or GetValueNumber("numMalusAbdDsq", 0);
	matrice.numMalusAbs = matrice.numMalusAbs or GetValueNumber("numMalusAbs", 0);
	matrice.numMinimumArrivee = matrice.numMinimumArrivee or GetValueNumber("numMinimumArrivee", 0);
	matrice.numPenalisationSaut = matrice.numPenalisationSaut or GetValueNumber("numPenalisationSaut", 0);
	matrice.numPtsMaxi = matrice.numPtsMaxi or GetValueNumber("numPtsMaxi", 9999);
	matrice.numPtsMini = matrice.numPtsMini or GetValueNumber("numPtsMini", 0);
	matrice.numPtsPresence = matrice.numPtsPresence or GetValueNumber("numPtsPresence", 0);
	matrice.Saison = matrice.Saison or GetValue("Saison", tSaison:GetCell('Code', 0));
	matrice.selectionRegroupement =  matrice.selectionRegroupement or GetValue("selectionRegroupement", '');
	matrice.texteCodeComplet = matrice.texteCodeComplet or GetValue ("texteCodeComplet", 'Non')
	matrice.texteFontSize = matrice.texteFontSize or 8;
	matrice.texteImprimerClubLong = matrice.texteImprimerClubLong or 'Oui';
	matrice.texteFiltreSupplementaire = matrice.texteFiltreSupplementaire or GetValue("texteFiltreSupplementaire", 'Non');
	matrice.texteImprimerDeparts = matrice.texteImprimerDeparts or GetValue ("texteImprimerDeparts", 'Oui');
	matrice.texteImprimerHeader = matrice.texteImprimerHeader or GetValue ("texteImprimerHeader", 'Oui');
	matrice.texteImprimerLayer = matrice.texteImprimerLayer or '';
	matrice.texteImprimerLayerPage = matrice.texteImprimerLayerPage or 'Toutes les pages';
	matrice.texteLargeurEtroite = matrice.texteLargeurEtroite or GetValue ("texteLargeurEtroite", '1');
	matrice.texteLargeurLarge = matrice.texteLargeurLarge or GetValue ("texteLargeurLarge", '1,5');
	matrice.texteLigne2Texte = matrice.texteLigne2Texte or GetValue ("texteLigne2Texte", 'Nombre de courses :')
	matrice.texteMargeHaute1 = matrice.texteMargeHaute1 or 1;
	matrice.texteMargeHaute2 = matrice.texteMargeHaute2 or 1;
	matrice.texteNbColPresCourses = matrice.texteNbColPresCourses or GetValue ("texteNbColPresCourses", '3');
	matrice.texteImageStatCourses = matrice.texteImageStatCourses or GetValue ("texteImageStatCourses", '')
	matrice.texteComiteOrigine = matrice.texteComiteOrigine or GetValue("texteComiteOrigine", 'Non')
	BuildRegroupement();

	matrice.scriptLUA = matrice.scriptLUA or GetValue("scriptLUA", "")
	matrice.Evenement_support = matrice.Evenement_support or GetValue("Evenement_support", '0,0');
	local coursesupport = matrice.Evenement_support:Split(',');
	matrice.support_inclusion = tonumber(coursesupport[1]) or 0;
	matrice.support_exclusion = tonumber(coursesupport[2] or 0);
	
	-- on fixe les points par d�faut si on est en points place ou en points course
	if string.find(matrice.comboTypePoint, 'place') then -- points place
		BuildGrilles_Point_Place();
		matrice.defaut_point = 0;
		matrice.lastcompare = '>';
	else
		matrice.defaut_point = 100000;
		matrice.lastcompare = '<';
	end
	if matrice.debug == true then
		adv.Alert("LitMatrice - Snapshot('Grille_Point_Place.db3')");
		tGrille_Point_Place:Snapshot('Grille_Point_Place.db3');
	end
	local r = tGrille_Point_Place:GetIndexRow('Libelle', matrice.comboGrille);
	if r and r >= 0 then
		local cmd = "Select * From Place_Valeur Where Code_activite = '"..matrice.code_activite.."' And Code_grille = '"..tGrille_Point_Place:GetCell('Code', r).."' And Code_saison = '"..matrice.Saison.."' Order By Place";
		base:TableLoad(tPlace_Valeur, cmd);
		local placevaleur = {};
		for i = 0, tPlace_Valeur:GetNbRows()-1 do
			table.insert(placevaleur, { Place = tPlace_Valeur:GetCellInt('Place', i), Point = tPlace_Valeur:GetCellDouble('Point', i) });
		end
		matrice.grille = placevaleur;
	end
	if matrice.comboResultatPar ~= 'Sans objet' then
		menuPrint:Enable(btnAnalyse:GetId(), false) ;
	end

	CreateTableListe();
	CreateTypeClassement();
	ChargeDisciplines();  	-- on charge toutes les disciplines de la matrice


end

function GetCritere()	-- lecture de toutes les variables des crit�res de calculs s'ils existent
	if not matrice.Evenement_selection or matrice.Evenement_selection:len() == 0 then
		dlgConfig:MessageBox(
			"Vous devez ajouter au moins une course pour d�finir un crit�re.",
			"Merci de saisir une course", 
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
			) ;
		return
	end
	if matrice.numTypeCritere == 1 then
		matrice.criteres_bloc1 = 'Prendre ';
		matrice.criteres_bloc2 = 'Prendre ';
	else
		matrice.criteres_bloc1 = 'Bloc 1 - Prendre ';
		matrice.criteres_bloc2 = 'Bloc 2 - Prendre ';
	end
	matrice.table_critere = {};
	matrice.numTypeCritere = 0;
	for i = 0, tEvenement_Matrice:GetNbRows()-1 do
		local cle = tEvenement_Matrice:GetCell('Cle', i);
		if string.find(cle, 'critere') then
			matrice.numTypeCritere = tonumber(string.sub(cle,1,1)) or 0;
			local val = tEvenement_Matrice:GetCell('Valeur', i);
			SplitCritere(val, i+1)
		end
	end
	-- matrice.table_critere, {Critere = critere, TypeCritere = numTypeCritere, Item = item, Bloc = bloc, Discipline = discipline, Prendre = prendre, Combien = combien, NbCombien = nbcombien, Sur = sur}
	local virgule_bloc = {}; 
	local nb_critere = {};
	for i = 1, #matrice.table_critere do
		local bloc = matrice.table_critere[i].Bloc;
		local discipline = matrice.table_critere[i].Discipline;
		virgule_bloc[bloc] = virgule_bloc[bloc] or '';
		nb_critere[bloc] = nb_critere[bloc] or 0;
		nb_critere[bloc] = nb_critere[bloc] + 1;
		if nb_critere[bloc] > 1 then virgule_bloc[bloc] = ', '; end
		matrice.table_critere[i].NbCombien = tonumber(matrice.table_critere[i].NbCombien) or 0;
		matrice.table_critere[i].Sur = tonumber(matrice.table_critere[i].Sur) or 1;
		-- matrice.disciplines[discipline][bloc].nombre;
		-- matrice.disciplines['*'][bloc].nombre;
		if discipline ~= '*' then
			if matrice.table_critere[i].NbCombien >= matrice.table_critere[i].Sur then
				matrice['criteres_bloc'..bloc] = matrice['criteres_bloc'..bloc]..virgule_bloc[bloc]..matrice.table_critere[i].Prendre..' '..matrice.table_critere[i].NbCombien..' '..matrice.table_critere[i].Discipline;
			else
				local sur = matrice.table_critere[i].Sur;
				matrice['criteres_bloc'..bloc] = matrice['criteres_bloc'..bloc]..virgule_bloc[bloc]..matrice.table_critere[i].Prendre..' '..matrice.table_critere[i].NbCombien..' '..matrice.table_critere[i].Discipline.. ' sur '..sur;
			end
		else
			local sur = matrice.disciplines['*'][bloc].nombre;
			local quoi = ' courses';
			if matrice.table_critere[i].NbCombien == 1 then
				quoi = ' course';
			end
			matrice['criteres_bloc'..bloc] = matrice['criteres_bloc'..bloc]..virgule_bloc[bloc]..matrice.table_critere[i].Prendre..' '..matrice.table_critere[i].NbCombien..quoi..' sur '..sur..virgule_bloc[bloc];
		end
	end
	for i = 0, tMatrice_Courses:GetNbRows() -1 do
		if tMatrice_Courses:GetCellInt('Obligatoire', i) == -1 then
			local bloc = tMatrice_Courses:GetCellInt('Bloc', i);
			matrice['criteres_bloc'..bloc] = matrice['criteres_bloc'..bloc]..' - course '..tMatrice_Courses:GetCellInt('Ordre', i)..' obligatoire. ';
		end
	end
end

function TransformeCombien(discipline, bloc, combien)
	local arcombien = {};
	local numerateur = 1;
	local denominateur = 1;
	local retour = 0;
	local arDiscipline = discipline:Split(',');
	local nb_disciplines = 0;

	if arDiscipline[1] == '*' then
		for idx = 1, #matrice.course do
			if matrice.course[idx].Bloc == bloc then
				if string.find(matrice['comboPrendreBloc'..bloc], '2%.') then
					nb_disciplines = nb_disciplines + matrice.course[idx].Nombre_de_manche;
				elseif string.find(matrice.comboPrendreBloc1, '3%.') then	
					if matrice.course[idx].Nombre_de_manche == 1 then
						nb_disciplines = nb_disciplines + 1;
					else
						nb_disciplines = nb_disciplines + matrice.course[idx].Nombre_de_manche + 1;
					end
				else
					nb_disciplines = nb_disciplines + 1;
				end
			end
		end
	else
		for i = 1, #arDiscipline do
			local discipline = arDiscipline[i];
			if matrice.disciplines[discipline] and matrice.disciplines[discipline][1] then
				nb_disciplines = nb_disciplines + matrice.disciplines[discipline][1].nombre;
			end
		end
	end
	combien = combien or '';
	if string.find(combien, 'sur') then				-- on a 5 sur 9
		local arcombien = combien:Split('sur');
		retour = arcombien[1];
		nb_disciplines = arcombien[2];
	end
	if string.find(combien,'/') then	-- on a une fraction ex : 2/3
		arcombien = combien:Split('/');
		numerateur = tonumber(arcombien[1]) or 0;
		denominateur = tonumber(arcombien[2]) or 1;
		retour = math.floor(nb_disciplines * numerateur / denominateur);
	elseif string.find(combien, '%%') then				-- on a un pourcentage 75% -> 75/100
		retour = string.gsub(combien, "%D", "");
		retour = tonumber(retour) or 0;
		retour = math.floor(nb_disciplines * retour / 100);
	else
		retour = tonumber(combien) or 0;
	end
	if retour < 1 then retour = 1; end
	return retour, nb_disciplines;
end

function SplitCritere(critere, idxcritere)
	-- Course|1|SG|au maximum|1/2	
	if matrice.debug == true then
		adv.Alert('\nfunction SplitCritere('..critere..', '..idxcritere..')');
	end
	local arcritere = critere:Split('|');
	local item = arcritere[1];
	local bloc = tonumber(arcritere[2]) or 1;
	local discipline = arcritere[3];
	local prendre = arcritere[4];
	local combien = arcritere[5];
	
	local arDiscipline = discipline:Split(',');
	local nb_disciplines = 0;
	local ok = false;
	for i = 1, #arDiscipline do
		local discipline = arDiscipline[i];
		if not matrice.disciplines[discipline] then
			app.GetAuiFrame():MessageBox(
					"Attention : le crit�re n� "..idxcritere.." est incompatible\navec les courses � prendre en compte !!!\nUne ou plusieurs diciplines contenues dans\ncelui-ci n'existent pas dans les courses.",
					"Erreur sur le crit�re n� "..idxcritere, 
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
					) 
			break;
		end
		if matrice.disciplines[discipline] and matrice.disciplines[discipline][bloc] then
			ok = true;
			nb_disciplines = nb_disciplines + matrice.disciplines[discipline][bloc].nombre;
		else
			matrice.disciplines[discipline] = {};
			matrice.disciplines[discipline][bloc] = {};
			matrice.disciplines[discipline][bloc].nombre = 0;
		end
	end
	-- local sur = nb_disciplines;
	local nbcombien, sur = TransformeCombien(discipline, bloc, combien);
	if ok == true then
		if matrice.debug == true then
			adv.Alert('\nOn ins�re le crit�re dans la table matrice.table_critere');
			adv.Alert('		Critere = '..critere..', TypeCritere = '..matrice.numTypeCritere..', Item = '..item..', Bloc = '..bloc..', Discipline = '..discipline..', Combien = '..tostring(combien)..', NbCombien = '..nbcombien..', Sur = '..tostring(sur))
		end
		table.insert(matrice.table_critere, {Critere = critere, TypeCritere = matrice.numTypeCritere, Item = item, Bloc = bloc, Discipline = discipline, Prendre = prendre, Combien = combien, NbCombien = nbcombien, Sur = sur});
	end
end

function OnSavedlgRegroupement()
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle = 'Evenement_filtre' Or Cle = 'selectionRegroupement'";
	base:Query(cmd);
	matrice.selectionRegroupement = "'-1'";
	for i = 1, tRegroupement:GetNbRows() do
		if dlgRegroupement:GetWindowName('chk'..i):GetValue() == true then
			matrice.selectionRegroupement = matrice.selectionRegroupement..",'"..tRegroupement:GetCell('Code', i-1).."'";
		end		
	end
	AddRowEvenement_Matrice('selectionRegroupement', matrice.selectionRegroupement);
	local evenement_filtre = "Ev.Code >= 0 And Ev.Code_saison = "..matrice.Saison.." And Ev.Code_Activite = '"..matrice.comboActivite.."' And Ev.Code_entite = '"..matrice.comboEntite.."' And Ep.Sexe = '"..matrice.comboSexe.."' And Ep.Code_regroupement In("..matrice.selectionRegroupement..")";
	AddRowEvenement_Matrice('Evenement_filtre', evenement_filtre);
end

function AffichedlgRegroupement()
	dlgRegroupement = wnd.CreateDialog(
		{
		width = 1000,
		height = 400,
		x = 200,
		y = 50,
		label='Selection des Codes Regroupement pour la s�lection des courses', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgRegroupement:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'selectionRegroupement', 	-- Facultatif si le node_name est unique ...
		base = base,
		Rows = tRegroupement:GetNbRows() 
	});
	
	
	-- Toolbar 
	local tb = dlgRegroupement:GetWindowName('tb');
	tb:AddStretchableSpace();
	local btnValider = tb:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tb:AddSeparator();
	local btnRetour = tb:AddTool("Retour", "./res/32x32_exit.png");
	tb:AddStretchableSpace();
	tb:Realize();
	local arSelection = matrice.selectionRegroupement:Split(',');
	for i = 1, tRegroupement:GetNbRows() do
		dlgRegroupement:GetWindowName('chk'..i):SetValue(false);
		local code_regroupement = tRegroupement:GetCell('Code', i-1);
		local libelle_regroupement = tRegroupement:GetCell('Libelle', i-1);
		if libelle_regroupement:len() > 0 then
			dlgRegroupement:GetWindowName('reg'..i):SetValue(code_regroupement..' : '..libelle_regroupement);
			for j = 1, #arSelection do
				if arSelection[j] == "'"..code_regroupement.."'" then
					dlgRegroupement:GetWindowName('chk'..i):SetValue(true);
					break;
				end
			end
		end
	end

	dlgRegroupement:Bind(eventType.MENU, 
		function(evt)
			matrice.dialog = dlgRegroupement;
			matrice.timer:Start(600);	-- Temps de scrutation de 0.6 secondes
			matrice.action = 'nada';
			dlgRegroupement:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgRegroupement();
			matrice.action = 'close';
		end,
			btnValider);

	dlgRegroupement:Bind(eventType.MENU, 
			function(evt) 
				dlgRegroupement:EndModal(idButton.CANCEL)	
			end, btnRetour);
	dlgRegroupement:Fit()
	dlgRegroupement:ShowModal();
end

function OnSavedlgCritere1();	-- lecture et �criture des variables pour un crit�re de type 1
	-- Course|1|SG|au maximum|1/2
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And (Cle Like 'numTypeCritere%' or Cle Like '%critere%')";
	base:Query(cmd);
	matrice.numTypeCritere = 1;
	matrice.table_critere = {};
	local item = 'Course';
	local bloc = 1;
	for i = 0, 14 do
		local prendre = dlgCritere1:GetWindowName('prendre'..i):GetValue();
		local discipline = dlgCritere1:GetWindowName('disciplineschoisies'..i):GetValue();
		local combien = dlgCritere1:GetWindowName('combien'..i):GetValue();
		if combien:len() > 3 then
			if not string.find(combien, '%%') and not string.find(combien, '/') and not string.find(combien, 'sur') then
				dlgCritere1:MessageBox(
					"Vous avez mal configur� le crit�re � la ligne "..(i+1).." !!!",
					"Param�trage du crit�re", 
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
					) ;	
			end
		end
		combien = string.gsub(combien, "%s+", "")
		local chaine = item..'|'..bloc..'|'..discipline..'|'..prendre..'|'..combien;
		if prendre:len() > 0 and discipline:len() > 0 and combien:len() > 0 then
			-- verifier que les disciplines d�finies dans le crit�re existent bien si on arr�te les calculs apr�s une certaine course
			AddRowEvenement_Matrice('1critere'..(i+1), chaine);
		end
	end
	RempliTableauMatrice();
	LitMatriceCourses(false);
	GetCritere();
	dlgCritere1:EndModal(idButton.CANCEL)
end

function AffichedlgCritere1()	-- bo�te de dialogue pour un crit�re de type 1
	if not matrice.Evenement_selection or matrice.Evenement_selection:len() == 0 then
		dlgConfig:MessageBox(
			"Vous devez rajouter au moins une course\navant de d�finir un crit�re de calcul",
			"Merci de saisir une course", 
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
			) ;
		return
	end
	dlgCritere1 = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Crit�res simples de calcul par disciplines', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgCritere1:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'criteretype1', 		-- Facultatif si le node_name est unique ...
		imageclear = app.GetPath()..'/res/32x32_clear.png'
	});

	-- Toolbar 
	local tbcriteretype1 = dlgCritere1:GetWindowName('tbcriteretype1');
	tbcriteretype1:AddStretchableSpace();
	local btnValider = tbcriteretype1:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbcriteretype1:AddSeparator();
	local btnRAZ = tbcriteretype1:AddTool("RAZ crit�re", "./res/32x32_clear.png");
	tbcriteretype1:AddSeparator();
	local btnRetour = tbcriteretype1:AddTool("Retour", "./res/32x32_exit.png");
	tbcriteretype1:AddStretchableSpace();
	tbcriteretype1:Realize();
	
	GetCritere();
	--{Item = Course ou Manche, Bloc = 0 ou 1 ou 2, Discipline, Prendre(au mini, exactement...), Combien }
	for i = 0, 14 do
		dlgCritere1:GetWindowName('prendre'..i):Append("exactement");
		dlgCritere1:GetWindowName('prendre'..i):Append("au maximum");
		dlgCritere1:GetWindowName('prendre'..i):Append("au minimum");
		dlgCritere1:GetWindowName('disciplinesproposees'..i):Clear();
		dlgCritere1:GetWindowName('disciplinesproposees'..i):Append('*');
		for j = 1, #matrice.discipline do
			dlgCritere1:GetWindowName('disciplinesproposees'..i):Append(matrice.discipline[j].Code);
		end
	end

	for i = 0, 14 do
		if #matrice.table_critere > 0 and i < #matrice.table_critere then
			if string.find(matrice.table_critere[(i+1)].Combien, 'sur') then
				local ar = matrice.table_critere[(i+1)].Combien:Split('sur');
				if #ar == 2 then
					matrice.table_critere[(i+1)].Combien = ar[1]..' sur '..ar[2];
				end
			end
			dlgCritere1:GetWindowName('disciplineschoisies'..i):SetValue(matrice.table_critere[(i+1)].Discipline);
			dlgCritere1:GetWindowName('prendre'..i):SetValue(matrice.table_critere[(i+1)].Prendre);
			dlgCritere1:GetWindowName('combien'..i):SetValue(matrice.table_critere[(i+1)].Combien);
		end
		if string.len(dlgCritere1:GetWindowName('disciplineschoisies'..i):GetValue()) > 0 then
			dlgCritere1:GetWindowName('prendre'..i):Enable(true);
			dlgCritere1:GetWindowName('combien'..i):Enable(true);
		else
			dlgCritere1:GetWindowName('prendre'..i):Enable(false);
			dlgCritere1:GetWindowName('combien'..i):Enable(false);
		end
	end

	-- Bind
	tbcriteretype1:Bind(eventType.MENU, 
		function(evt)
			matrice.dialog = dlgCritere1;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgCritere1:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgCritere1();
			matrice.action = 'close';
		end
		, btnValider);
		
	tbcriteretype1:Bind(eventType.MENU, 
		function(evt)
			if dlgCritere1:MessageBox(
				"Voulez vous effacer ce crit�re de calcul ?\nVous devrez red�finir un crit�re le cas �ch�ant.", 
				"Confirmation !!!",
				msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
			end
			local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle Like 'numTypeCritere%' Or Cle Like '%critere%'";
			base:Query(cmd);
			matrice.numTypeCritere = 0;
			RempliTableauMatrice();
			dlgCritere1:MessageBox(
					"RAZ du crit�re de calcul OK !!!",
					"RAZ du crit�re de calcul", 
					msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
					) 
			dlgCritere1:EndModal(idButton.OK)
		end
		, btnRAZ);
	tbcriteretype1:Bind(eventType.MENU, function(evt) dlgCritere1:EndModal(idButton.CANCEL)	end, btnRetour);
	for i = 0, 14 do

		dlgCritere1:Bind(eventType.CHECKBOX, 
			function(evt) 
				if dlgCritere1:GetWindowName('chk'..i):GetValue() == true then
					dlgCritere1:GetWindowName('chk'..i):SetValue(false);
					dlgCritere1:GetWindowName('disciplineschoisies'..i):SetValue('');
					dlgCritere1:GetWindowName('disciplinesproposees'..i):SetValue('');
					dlgCritere1:GetWindowName('prendre'..i):SetSelection(1);
					dlgCritere1:GetWindowName('combien'..i):SetValue('');
					dlgCritere1:Refresh();
				end
			end,
		dlgCritere1:GetWindowName('chk'..i))


		dlgCritere1:Bind(eventType.COMBOBOX, 
			function(evt) 
				if string.len(dlgCritere1:GetWindowName('disciplinesproposees'..i):GetValue()) > 0 then
					local idx = dlgCritere1:GetWindowName('disciplinesproposees'..i):GetSelection();
					local chaine = dlgCritere1:GetWindowName('disciplineschoisies'..i):GetValue();
					if chaine == '' then
						chaine = dlgCritere1:GetWindowName('disciplinesproposees'..i):GetValue();
					else
						chaine = chaine..','..dlgCritere1:GetWindowName('disciplinesproposees'..i):GetValue();
					end
					dlgCritere1:GetWindowName('disciplineschoisies'..i):SetValue(chaine);
					dlgCritere1:GetWindowName('prendre'..i):SetSelection(1);
				else
					dlgCritere1:GetWindowName('disciplineschoisies'..i):SetValue('');
					dlgCritere1:GetWindowName('combien'..i):SetValue('');
				end
			end, 
			dlgCritere1:GetWindowName('disciplinesproposees'..i))
		dlgCritere1:Bind(eventType.TEXT, 
			function(evt) 
				if string.len(dlgCritere1:GetWindowName('disciplineschoisies'..i):GetValue()) > 0 then
					dlgCritere1:GetWindowName('prendre'..i):Enable(true);
					dlgCritere1:GetWindowName('combien'..i):Enable(true);
				else
					dlgCritere1:GetWindowName('prendre'..i):Enable(false);
					dlgCritere1:GetWindowName('combien'..i):Enable(false);
				end
			end, 
			dlgCritere1:GetWindowName('disciplineschoisies'..i))
	end			
	dlgCritere1:ShowModal();
end

function OnSavedlgCritere2();	-- lecture et �criture des variables pour un crit�re de type 2
	-- pour le crit�re 1
	-- for i = 0, 14 do
		-- local prendre = dlgCritere1:GetWindowName('prendre'..i):GetValue();
		-- local discipline = dlgCritere1:GetWindowName('disciplineschoisies'..i):GetValue();
		-- local combien = dlgCritere1:GetWindowName('combien'..i):GetValue();
		-- local chaine = item..'|'..bloc..'|'..discipline..'|'..prendre..'|'..combien;
		-- if prendre:len() > 0 and discipline:len() > 0 and combien:len() > 0 then
			-- AddRowEvenement_Matrice('1critere'..(i+1), chaine);
		-- end
	-- end
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And (Cle Like 'numTypeCritere%' or Cle Like '%critere%')";
	base:Query(cmd);
	matrice.numTypeCritere = 2;
	matrice.table_critere = {}
	local idxcritere = 0;
	for i = 0, 5 do
		local discipline = dlgCritere2:GetWindowName('disciplineschoisiesa'..i):GetValue();
		local prendre = dlgCritere2:GetWindowName('prendrea'..i):GetValue();
		local combien = dlgCritere2:GetWindowName('combiena'..i):GetValue();
		combien = string.gsub(combien, "%s+", "")
		local chaine = '';
		if prendre:len() > 0 and discipline:len() > 0 and combien:len() > 0 then
			matrice.numTypeCritere = 2;
			-- table.insert(matrice.table_critere, {Item = 'Course', Bloc = 1, Discipline = discipline, Prendre = prendre, Combien = combien})
			chaine = 'Course|1|'..discipline..'|'..prendre..'|'..combien;
			idxcritere = idxcritere + 1;
			AddRowEvenement_Matrice('2critere'..idxcritere, chaine);
		end
		discipline = dlgCritere2:GetWindowName('disciplineschoisiesb'..i):GetValue();
		prendre = dlgCritere2:GetWindowName('prendreb'..i):GetValue();
		combien = dlgCritere2:GetWindowName('combienb'..i):GetValue();
		combien = string.gsub(combien, "%s+", "")
		if prendre:len() > 0 and discipline:len() > 0 and combien:len() > 0 then
			matrice.numTypeCritere = 2;
			-- table.insert(matrice.table_critere, {Item = 'Course', Bloc = 2, Discipline = discipline, Prendre = prendre, Combien = combien})
			chaine = 'Course|2|'..discipline..'|'..prendre..'|'..combien;
			idxcritere = idxcritere + 1;
			AddRowEvenement_Matrice('2critere'..idxcritere, chaine);
		end
		discipline = dlgCritere2:GetWindowName('disciplineschoisiesc'..i):GetValue();
		prendre = dlgCritere2:GetWindowName('prendrec'..i):GetValue();
		combien = dlgCritere2:GetWindowName('combienc'..i):GetValue();
		combien = string.gsub(combien, "%s+", "")
		if prendre:len() > 0 and discipline:len() > 0 and combien:len() > 0 then
			matrice.numTypeCritere = 3;
			-- table.insert(matrice.table_critere, {Item = 'Manche', Bloc = 1, Discipline = discipline, Prendre = prendre, Combien = combien})
			chaine = 'Manche|1|'..discipline..'|'..prendre..'|'..combien;
			idxcritere = idxcritere + 1;
			AddRowEvenement_Matrice('3critere'..idxcritere, chaine);
		end
		discipline = dlgCritere2:GetWindowName('disciplineschoisiesd'..i):GetValue();
		prendre = dlgCritere2:GetWindowName('prendred'..i):GetValue();
		combien = dlgCritere2:GetWindowName('combiend'..i):GetValue();
		combien = string.gsub(combien, "%s+", "")
		if prendre:len() > 0 and discipline:len() > 0 and combien:len() > 0 then
			matrice.numTypeCritere = 3;
			-- table.insert(matrice.table_critere, {Item = 'Manche', Bloc = 2, Discipline = discipline, Prendre = prendre, Combien = combien})
			chaine = 'Manche|2|'..discipline..'|'..prendre..'|'..combien;
			idxcritere = idxcritere + 1;
			AddRowEvenement_Matrice('3critere'..idxcritere, chaine);
		end
	end
	RempliTableauMatrice();
	LitMatriceCourses(false);
	GetCritere();
end

function AffichedlgCritere2()	-- bo�te de dialogue pour un crit�re de type 2
	if not matrice.Evenement_selection or matrice.Evenement_selection:len() == 0 then
		dlgConfig:MessageBox(
			"Vous devez rajouter au moins une course\navant de d�finir un crit�re de calcul",
			"Merci de saisir une course", 
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
			) ;
		return
	end
	matrice.numTypeCritere = 2;
	local arparams = {};
	dlgCritere2 = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Crit�res simples de calcul par disciplines', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgCritere2:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'criteretype2', 		-- Facultatif si le node_name est unique ...
		numTypeCritere = 2
	});
	-- Toolbar 
	assert(dlgCritere2:GetWindowName('tbcriteretype2') ~= nil);
	local tbcriteretype2 = dlgCritere2:GetWindowName('tbcriteretype2');
	tbcriteretype2:AddStretchableSpace();
	local btnValider = tbcriteretype2:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbcriteretype2:AddSeparator();
	local btnRAZ = tbcriteretype2:AddTool("RAZ crit�re", "./res/32x32_clear.png");
	tbcriteretype2:AddSeparator();
	local btnRetour = tbcriteretype2:AddTool("Retour", "./res/32x32_exit.png");
	tbcriteretype2:AddStretchableSpace();
	tbcriteretype2:Realize();
	
	LitMatriceCourses(false);
	local coursebloc1 = {};
	local coursebloc2 = {};
	local manchebloc1 = {};
	local manchebloc2 = {};
	local disciplinesproposeesa = {};
	local disciplinesproposeesb = {};
	for i = 1, #matrice.discipline do
		table.insert(disciplinesproposeesa, matrice.discipline[i].Code);
		table.insert(disciplinesproposeesb, matrice.discipline[i].Code);
	end
	for idx = #disciplinesproposeesa, 1, -1 do
		effacer = true;
		for i = 0, tMatrice_Courses:GetNbRows() -1 do
			if tMatrice_Courses:GetCellInt('Bloc', i) == 1 then
				if tMatrice_Courses:GetCell('Code_discipline', i) == disciplinesproposeesa[idx] then
					effacer = false;
				end
			end
		end
		if effacer == true then
			table.remove(disciplinesproposeesa, idx);
		end
	end
	for idx = #disciplinesproposeesb, 1, -1 do
		effacer = true;
		for i = 0, tMatrice_Courses:GetNbRows() -1 do
			if tMatrice_Courses:GetCellInt('Bloc', i) == 2 then
				if tMatrice_Courses:GetCell('Code_discipline', i) == disciplinesproposeesb[idx] then
					effacer = false;
				end
			end
		end
		if effacer == true then
			table.remove(disciplinesproposeesb, idx);
		end
	end
	if #disciplinesproposeesa > 0 then
		table.insert(disciplinesproposeesa, 1 , '*');
	end
	if #disciplinesproposeesb > 0 then
		table.insert(disciplinesproposeesb, 1 , '*');
	end

	GetCritere();
	for i = 0, 5 do
		for j = 1, #disciplinesproposeesa do
			dlgCritere2:GetWindowName('disciplinesproposeesa'..i):Append(disciplinesproposeesa[j]);
			dlgCritere2:GetWindowName('disciplinesproposeesc'..i):Append(disciplinesproposeesa[j]);
		end
		for j = 1, #disciplinesproposeesb do
			dlgCritere2:GetWindowName('disciplinesproposeesb'..i):Append(disciplinesproposeesb[j]);
			dlgCritere2:GetWindowName('disciplinesproposeesd'..i):Append(disciplinesproposeesb[j]);
		end
		dlgCritere2:GetWindowName('prendrea'..i):Append("exactement");
		dlgCritere2:GetWindowName('prendrea'..i):Append("au maximum");
		dlgCritere2:GetWindowName('prendrea'..i):Append("au minimum");
		dlgCritere2:GetWindowName('prendreb'..i):Append("exactement");
		dlgCritere2:GetWindowName('prendreb'..i):Append("au maximum");
		dlgCritere2:GetWindowName('prendreb'..i):Append("au minimum");
		dlgCritere2:GetWindowName('prendrec'..i):Append("exactement");
		dlgCritere2:GetWindowName('prendrec'..i):Append("au maximum");
		dlgCritere2:GetWindowName('prendrec'..i):Append("au minimum");
		dlgCritere2:GetWindowName('prendred'..i):Append("exactement");
		dlgCritere2:GetWindowName('prendred'..i):Append("au maximum");
		dlgCritere2:GetWindowName('prendred'..i):Append("au minimum");
		dlgCritere2:GetWindowName('disciplinesproposeesb'..i):Enable(matrice.bloc2);
		dlgCritere2:GetWindowName('disciplinesproposeesd'..i):Enable(matrice.bloc2);
		dlgCritere2:GetWindowName('disciplineschoisiesb'..i):Enable(matrice.bloc2);
		dlgCritere2:GetWindowName('disciplineschoisiesd'..i):Enable(matrice.bloc2);
		dlgCritere2:GetWindowName('prendreb'..i):Enable(matrice.bloc2);
		dlgCritere2:GetWindowName('prendred'..i):Enable(matrice.bloc2);
		dlgCritere2:GetWindowName('combienb'..i):Enable(matrice.bloc2);
		dlgCritere2:GetWindowName('combiend'..i):Enable(matrice.bloc2);
	end
	-- matrice.table_critere, {Critere = critere, TypeCritere = matrice.numTypeCritere, Item = item, Bloc = bloc, Discipline = discipline, Prendre = prendre, Combien = combien, NbCombien = nbcombien, Sur = sur}
	
	for j = 1, #matrice.table_critere do
		if matrice.table_critere[j].Item == 'Course' then
			if matrice.table_critere[j].Bloc == 1 then
				table.insert(coursebloc1, matrice.table_critere[j]);
			else
				table.insert(coursebloc2, matrice.table_critere[j]);
			end
		else
			if matrice.table_critere[j].Bloc == 1 then
				table.insert(manchebloc1, matrice.table_critere[j]);
			else
				table.insert(manchebloc2, matrice.table_critere[j]);
			end
		end
	end
	for i = 1, #coursebloc1 do
		dlgCritere2:GetWindowName('disciplineschoisiesa'..i-1):SetValue(coursebloc1[i].Discipline);
		dlgCritere2:GetWindowName('prendrea'..i-1):SetValue(coursebloc1[i].Prendre);
		dlgCritere2:GetWindowName('combiena'..i-1):SetValue(coursebloc1[i].Combien);

	end
	for i = 1, #coursebloc2 do
		dlgCritere2:GetWindowName('disciplineschoisiesb'..i-1):SetValue(coursebloc2[i].Discipline);
		dlgCritere2:GetWindowName('prendreb'..i-1):SetValue(coursebloc2[i].Prendre);
		dlgCritere2:GetWindowName('combienb'..i-1):SetValue(coursebloc2[i].Combien);
	end
	for i = 1, #manchebloc1 do
		dlgCritere2:GetWindowName('disciplineschoisiesc'..i-1):SetValue(manchebloc1[i].Discipline);
		dlgCritere2:GetWindowName('prendrec'..i-1):SetValue(manchebloc1[i].Prendre);
		dlgCritere2:GetWindowName('combienc'..i-1):SetValue(1);
	end
	for i = 1, #manchebloc2 do
		dlgCritere2:GetWindowName('disciplineschoisiesd'..i-1):SetValue(manchebloc2[i].Discipline);
		dlgCritere2:GetWindowName('prendred'..i-1):SetValue(manchebloc2[i].Prendre);
		dlgCritere2:GetWindowName('combiend'..i-1):SetValue(1);
	end
	for i = 0, 5 do
		dlgCritere2:GetWindowName('prendrea'..i):Enable(string.len(dlgCritere2:GetWindowName('disciplineschoisiesa'..i):GetValue()) > 0);
		dlgCritere2:GetWindowName('prendreb'..i):Enable(string.len(dlgCritere2:GetWindowName('disciplineschoisiesb'..i):GetValue()) > 0);
		dlgCritere2:GetWindowName('prendrec'..i):Enable(string.len(dlgCritere2:GetWindowName('disciplineschoisiesc'..i):GetValue()) > 0);
		dlgCritere2:GetWindowName('prendred'..i):Enable(string.len(dlgCritere2:GetWindowName('disciplineschoisiesd'..i):GetValue()) > 0);
		dlgCritere2:GetWindowName('combiena'..i):Enable(string.len(dlgCritere2:GetWindowName('disciplineschoisiesa'..i):GetValue()) > 0);
		dlgCritere2:GetWindowName('combienb'..i):Enable(string.len(dlgCritere2:GetWindowName('disciplineschoisiesc'..i):GetValue()) > 0);
	end

	tbcriteretype2:Bind(eventType.MENU, function(evt) dlgCritere2:EndModal(idButton.CANCEL)	end, btnRetour);
	tbcriteretype2:Bind(eventType.MENU, 
		function(evt)
			matrice.dialog = dlgCritere2;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgCritere2:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgCritere2();
			matrice.action = 'close';
		end
		, btnValider);
		
	tbcriteretype2:Bind(eventType.MENU, 
		function(evt)
			if dlgCritere2:MessageBox(
				"Voulez vous effacer ce crit�re de calcul ?\nVous devrez red�finir un crit�re le cas �ch�ant.", 
				"Confirmation !!!",
				msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
			end
			local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle Like 'numTypeCritere%' Or Cle Like '%critere%'";
			base:Query(cmd);
			matrice.numTypeCritere = 0;
			RempliTableauMatrice();
			dlgCritere2:MessageBox(
					"RAZ du crit�re de calcul OK !!!",
					"Effacer le crit�re de calcul", 
					msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
					) 
			dlgCritere2:EndModal(idButton.OK)
		end
		, btnRAZ);
	for i = 0, 5 do
		dlgCritere2:Bind(eventType.COMBOBOX, 
			function(evt) 
				if string.len(dlgCritere2:GetWindowName('disciplinesproposeesa'..i):GetValue()) > 0 then
					local idx = dlgCritere2:GetWindowName('disciplinesproposeesa'..i):GetSelection();
					local chaine = dlgCritere2:GetWindowName('disciplineschoisiesa'..i):GetValue();
					if chaine == '' then
						dlgCritere2:GetWindowName('prendrea'..i):SetSelection(1);
						chaine = dlgCritere2:GetWindowName('disciplinesproposeesa'..i):GetValue();
					else
						chaine = chaine..','..dlgCritere2:GetWindowName('disciplinesproposeesa'..i):GetValue();
					end
					dlgCritere2:GetWindowName('disciplineschoisiesa'..i):SetValue(chaine);
				else
					dlgCritere2:GetWindowName('disciplineschoisiesa'..i):SetValue('');
					dlgCritere2:GetWindowName('combiena'..i):SetValue('');
				end
			end, 
			dlgCritere2:GetWindowName('disciplinesproposeesa'..i))
		dlgCritere2:Bind(eventType.COMBOBOX, 
			function(evt) 
				if string.len(dlgCritere2:GetWindowName('disciplinesproposeesb'..i):GetValue()) > 0 then
					local idx = dlgCritere2:GetWindowName('disciplinesproposeesb'..i):GetSelection();
					local chaine = dlgCritere2:GetWindowName('disciplineschoisiesb'..i):GetValue();
					if chaine == '' then
						dlgCritere2:GetWindowName('prendreb'..i):SetSelection(1);
						chaine = dlgCritere2:GetWindowName('disciplinesproposeesb'..i):GetValue();
					else
						chaine = chaine..','..dlgCritere2:GetWindowName('disciplinesproposeesb'..i):GetValue();
					end
					dlgCritere2:GetWindowName('disciplineschoisiesb'..i):SetValue(chaine);
				else
					dlgCritere2:GetWindowName('disciplineschoisiesb'..i):SetValue('');
					dlgCritere2:GetWindowName('combienb'..i):SetValue('');
				end
			end, 
			dlgCritere2:GetWindowName('disciplinesproposeesb'..i))

		dlgCritere2:Bind(eventType.COMBOBOX, 
			function(evt) 
				if string.len(dlgCritere2:GetWindowName('disciplinesproposeesc'..i):GetValue()) > 0 then
					dlgCritere2:GetWindowName('combienc'..i):SetValue(1);
					local idx = dlgCritere2:GetWindowName('disciplinesproposeesc'..i):GetSelection();
					local chaine = dlgCritere2:GetWindowName('disciplineschoisiesc'..i):GetValue();
					if chaine == '' then
						dlgCritere2:GetWindowName('prendrec'..i):SetSelection(1);
						chaine = dlgCritere2:GetWindowName('disciplinesproposeesc'..i):GetValue();
					else
						chaine = chaine..','..dlgCritere2:GetWindowName('disciplinesproposeesc'..i):GetValue();
					end
					dlgCritere2:GetWindowName('disciplineschoisiesc'..i):SetValue(chaine);
				else
					dlgCritere2:GetWindowName('disciplineschoisiesc'..i):SetValue('');
					dlgCritere2:GetWindowName('combienc'..i):SetValue('');
				end
			end, 
			dlgCritere2:GetWindowName('disciplinesproposeesc'..i))

		dlgCritere2:Bind(eventType.COMBOBOX, 
			function(evt) 
				if string.len(dlgCritere2:GetWindowName('disciplinesproposeesd'..i):GetValue()) > 0 then
					dlgCritere2:GetWindowName('combiend'..i):SetValue(1);
					local idx = dlgCritere2:GetWindowName('disciplinesproposeesd'..i):GetSelection();
					local chaine = dlgCritere2:GetWindowName('disciplineschoisiesd'..i):GetValue();
					if chaine == '' then
						dlgCritere2:GetWindowName('prendred'..i):SetSelection(1);
						chaine = dlgCritere2:GetWindowName('disciplinesproposeesd'..i):GetValue();
					else
						chaine = chaine..','..dlgCritere2:GetWindowName('disciplinesproposeesd'..i):GetValue();
					end
					dlgCritere2:GetWindowName('disciplineschoisiesd'..i):SetValue(chaine);
				else
					dlgCritere2:GetWindowName('disciplineschoisiesd'..i):SetValue('');
					dlgCritere2:GetWindowName('combiend'..i):SetValue('');
				end
			end, 
			dlgCritere2:GetWindowName('disciplinesproposeesd'..i))


		dlgCritere2:Bind(eventType.TEXT, 
			function(evt) 
				if string.len(dlgCritere2:GetWindowName('disciplineschoisiesa'..i):GetValue()) > 0 then
					dlgCritere2:GetWindowName('prendrea'..i):Enable(true);
					dlgCritere2:GetWindowName('combiena'..i):Enable(true);
				else
					dlgCritere2:GetWindowName('prendrea'..i):Enable(false);
					dlgCritere2:GetWindowName('combiena'..i):Enable(false);
				end
			end, 
			dlgCritere2:GetWindowName('disciplineschoisiesa'..i))

		dlgCritere2:Bind(eventType.TEXT, 
			function(evt) 
				if string.len(dlgCritere2:GetWindowName('disciplineschoisiesb'..i):GetValue()) > 0 then
					dlgCritere2:GetWindowName('prendreb'..i):Enable(true);
					dlgCritere2:GetWindowName('combienb'..i):Enable(true);
				else
					dlgCritere2:GetWindowName('prendreb'..i):Enable(false);
					dlgCritere2:GetWindowName('combienb'..i):Enable(false);
				end
			end, 
			dlgCritere2:GetWindowName('disciplineschoisiesb'..i))

		dlgCritere2:Bind(eventType.TEXT, 
			function(evt) 
				if string.len(dlgCritere2:GetWindowName('disciplineschoisiesc'..i):GetValue()) > 0 then
					dlgCritere2:GetWindowName('combienc'..i):SetValue('1');
					dlgCritere2:GetWindowName('prendrec'..i):Enable(true);
				else
					dlgCritere2:GetWindowName('prendrec'..i):Enable(false);
					dlgCritere2:GetWindowName('combienc'..i):SetValue('');
				end
			end, 
			dlgCritere2:GetWindowName('disciplineschoisiesc'..i))

		dlgCritere2:Bind(eventType.TEXT, 
			function(evt) 
				if string.len(dlgCritere2:GetWindowName('disciplineschoisiesd'..i):GetValue()) > 0 then
					dlgCritere2:GetWindowName('combiend'..i):SetValue('1');
					dlgCritere2:GetWindowName('prendred'..i):Enable(true);
				else
					dlgCritere2:GetWindowName('prendred'..i):Enable(false);
					dlgCritere2:GetWindowName('combiend'..i):SetValue('');
				end
			end, 
			dlgCritere2:GetWindowName('disciplineschoisiesd'..i))
	end			
	dlgCritere2:ShowModal();
end

function OnSavedlgCritere4();	-- lecture et �criture des variables pour un crit�re de type 3 ou 4
	-- c'est le dernier type de crit�re valid� qui donne la variable matrice.numTypeCritere
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And (Cle Like 'numTypeCritere%' or Cle Like '%critere%')";
	base:Query(cmd);
	matrice.numTypeCritere = 4;
	for i = 0, 5 do
		local choisia = dlgCritere4:GetWindowName('disciplineschoisiesa'..i):GetValue();
		local prendrea = dlgCritere4:GetWindowName('prendrea'..i):GetValue();
		local combiena = dlgCritere4:GetWindowName('combiena'..i):GetValue();
		if string.len(prendrea) > 0 and string.len(choisia) > 0 and string.len(combiena) > 0 then
			local chaine = prendrea..'|'..choisia..'|'..combiena;
			chaine = chaine:gsub(' ', '');
			AddRowEvenement_Matrice('critereType4aLigne'..i, chaine);
		end
		local choisib = dlgCritere4:GetWindowName('disciplineschoisiesb'..i):GetValue();
		local prendreb = dlgCritere4:GetWindowName('prendreb'..i):GetValue();
		local combienb = dlgCritere4:GetWindowName('combienb'..i):GetValue();
		if string.len(prendreb) > 0 and string.len(choisib) > 0 and string.len(combienb) > 0 then
			local chaine = prendreb..'|'..choisib..'|'..combienb;
			chaine = chaine:gsub(' ', '');
			AddRowEvenement_Matrice('critereType4bLigne'..i, chaine);
		end
		local choisix = dlgCritere4:GetWindowName('disciplineschoisiesx'..i):GetValue();
		local prendrex = dlgCritere4:GetWindowName('prendrex'..i):GetValue();
		local combienx = dlgCritere4:GetWindowName('combienx'..i):GetValue();
		if string.len(prendrex) > 0 and string.len(choisix) > 0 and string.len(combienx) > 0 then
			matrice.numTypeCritere = 4;
			local chaine = prendrex..'|'..choisix..'|'..combienx;
			chaine = chaine:gsub(' ', '');
			AddRowEvenement_Matrice('critereType4xLigne'..i, chaine);
		end
	end
	RempliTableauMatrice();
	dlgCritere4:MessageBox(
			"Enregistrement OK !!!",
			"Param�trage du crit�re", 
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
			) 
	dlgCritere4:EndModal(idButton.CANCEL)
end

function AffichedlgCritere4()	-- bo�te de dialogue pour un crit�re de type 3 ou 4 selon qu'il y a des manches 'flotantes' ou pas
	if not matrice.Evenement_selection or matrice.Evenement_selection:len() == 0 then
		dlgConfig:MessageBox(
			"Vous devez rajouter au moins une course\navant de d�finir un crit�re de calcul",
			"Merci de saisir une course", 
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
			) ;
		return
	end
	matrice.numTypeCritere = 4;
	if matrice.bloc2 == false then
		matrice.numTypeCritere = 2;
	end
	dlgCritere4 = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Crit�res de calculs avec gestion des blocs et des manches ind�pendantes des blocs', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgCritere4:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'criteretype2', 		-- Facultatif si le node_name est unique ...
		numTypeCritere = matrice.numTypeCritere
	});

	-- Toolbar 
	local tbdlgCritere4 = dlgCritere4:GetWindowName('tbcriteretype2');
	tbdlgCritere4:AddStretchableSpace();
	local btnValider = tbdlgCritere4:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbdlgCritere4:AddSeparator();
	local btnRAZ = tbdlgCritere4:AddTool("RAZ crit�re", "./res/32x32_clear.png");
	tbdlgCritere4:AddSeparator();
	local btnRetour = tbdlgCritere4:AddTool("Retour", "./res/32x32_exit.png");
	tbdlgCritere4:AddStretchableSpace();
	tbdlgCritere4:Realize();
	
	LitMatriceCourses(false);
	
	local disciplinesproposeesx = {};
	local disciplinesx = {};
	local disciplinesproposeesa = {};
	local disciplinesproposeesb = {};
	
	for i = 0, tMatrice_Courses:GetNbRows() -1 do
		local discipline = tMatrice_Courses:GetCell('Code_discipline', i);
		if not disciplinesx[discipline] then
			table.insert(disciplinesproposeesx, discipline);
			table.insert(disciplinesproposeesa, discipline);
			table.insert(disciplinesproposeesb, discipline);
			disciplinesx[discipline] = {};
		end
	end
	table.insert(disciplinesproposeesx, 1, '*');
	table.insert(disciplinesproposeesa, 1, '*');
	table.insert(disciplinesproposeesb, 1, '*');
	if not matrice.bloc2 then
		disciplinesproposeesb = {};
	end
	for idx = #disciplinesproposeesa, 2, -1 do
		effacer = true;
		for i = 0, tMatrice_Courses:GetNbRows() -1 do
			if tMatrice_Courses:GetCellInt('Bloc', i) == 1 then
				if tMatrice_Courses:GetCell('Code_discipline', i) == disciplinesproposeesa[idx] then
					effacer = false;
					break;
				end
			end
		end
		if effacer == true then
			table.remove(disciplinesproposeesa, idx);
		end
	end
	for idx = #disciplinesproposeesb, 2, -1 do
		effacer = true;
		for i = 0, tMatrice_Courses:GetNbRows() -1 do
			if tMatrice_Courses:GetCellInt('Bloc', i) == 2 then
				if tMatrice_Courses:GetCell('Code_discipline', i) == disciplinesproposeesb[idx] then
					effacer = false;
					break;
				end
			end
		end
		if effacer == true then
			table.remove(disciplinesproposeesb, idx);
		end
	end
	
	for i = 0, 5 do
		if dlgCritere4:GetWindowName('disciplinesproposeesa'..i) then
			dlgCritere4:GetWindowName('disciplinesproposeesa'..i):Clear();
			for j = 1, #disciplinesproposeesa do
				dlgCritere4:GetWindowName('disciplinesproposeesa'..i):Append(disciplinesproposeesa[j]);
			end
		end
		if dlgCritere4:GetWindowName('disciplinesproposeesc'..i) then
			dlgCritere4:GetWindowName('disciplinesproposeesc'..i):Clear();
			for j = 1, #disciplinesproposeesa do
				dlgCritere4:GetWindowName('disciplinesproposeesc'..i):Append(disciplinesproposeesa[j]);
			end
		end
		if dlgCritere4:GetWindowName('disciplinesproposeesb'..i) then
			dlgCritere4:GetWindowName('disciplinesproposeesb'..i):Clear();
			for j = 1, #disciplinesproposeesb do
				dlgCritere4:GetWindowName('disciplinesproposeesb'..i):Append(disciplinesproposeesb[j]);
			end
		end
		if dlgCritere4:GetWindowName('disciplinesproposeesd'..i) then
			dlgCritere4:GetWindowName('disciplinesproposeesd'..i):Clear();
			for j = 1, #disciplinesproposeesb do
				dlgCritere4:GetWindowName('disciplinesproposeesd'..i):Append(disciplinesproposeesb[j]);
			end
		end
		if dlgCritere4:GetWindowName('disciplinesproposeesx'..i) then
			for j = 1, #disciplinesproposeesx do
				dlgCritere4:GetWindowName('disciplinesproposeesx'..i):Append(disciplinesproposeesx[j]);
			end
		end
		if dlgCritere4:GetWindowName('prendrea'..i) then
			dlgCritere4:GetWindowName('prendrea'..i):Append("exactement");
			dlgCritere4:GetWindowName('prendrea'..i):Append("au maximum");
			dlgCritere4:GetWindowName('prendrea'..i):Append("au minimum");
		end
		if dlgCritere4:GetWindowName('prendreb'..i) then
			dlgCritere4:GetWindowName('prendreb'..i):Append("exactement");
			dlgCritere4:GetWindowName('prendreb'..i):Append("au maximum");
			dlgCritere4:GetWindowName('prendreb'..i):Append("au minimum");
		end
		if dlgCritere4:GetWindowName('prendrexx'..i) then
			dlgCritere4:GetWindowName('prendrex'..i):Append("exactement");
			dlgCritere4:GetWindowName('prendrex'..i):Append("au maximum");
			dlgCritere4:GetWindowName('prendrex'..i):Append("au minimum");
		end
	end
	
	-- r�cup�rer les valeurs pour chaque ligne. On part de la ligne 0
	local arrayg1 = {};
	local arrayd1 = {};
	local arrayx = {};
	for i = 0, 5 do
		local idx = 'critereType4aLigne'..i;
		arrayg1[idx] = GetValue('critereType4aLigne'..i, '');
		if string.len(arrayg1[idx]) > 1 then
			local tLigne = arrayg1['critereType4aLigne'..i]:Split('|');
			for idx = 1, #tLigne do
				dlgCritere4:GetWindowName('disciplineschoisiesa'..i):SetValue(tLigne[2]);
				dlgCritere4:GetWindowName('prendrea'..i):SetValue(tLigne[1]);
				dlgCritere4:GetWindowName('combiena'..i):SetValue(tLigne[3]);
			end
		end
		if string.len(dlgCritere4:GetWindowName('disciplineschoisiesa'..i):GetValue()) > 0 then
			dlgCritere4:GetWindowName('prendrea'..i):Enable(true);
			dlgCritere4:GetWindowName('combiena'..i):Enable(true);
		else
			dlgCritere4:GetWindowName('prendrea'..i):Enable(false);
			dlgCritere4:GetWindowName('combiena'..i):Enable(false);
		end
		-- droite
		local idx = 'critereType4bLigne'..i;
		arrayd1[idx] = GetValue('critereType4bLigne'..i, '');
		if string.len(arrayd1[idx]) > 1 then
			local tLigne = matrice['critereType4bLigne'..i]:Split('|');
			for idx = 1, #tLigne do
				dlgCritere4:GetWindowName('disciplineschoisiesb'..i):SetValue(tLigne[2]);
				dlgCritere4:GetWindowName('prendreb'..i):SetValue(tLigne[1]);
				dlgCritere4:GetWindowName('combienb'..i):SetValue(tLigne[3]);
			end
		end
		if string.len(dlgCritere4:GetWindowName('disciplineschoisiesb'..i):GetValue()) > 0 then
			dlgCritere4:GetWindowName('prendreb'..i):Enable(true);
			dlgCritere4:GetWindowName('combienb'..i):Enable(true);
		else
			dlgCritere4:GetWindowName('prendreb'..i):Enable(false);
			dlgCritere4:GetWindowName('combienb'..i):Enable(false);
		end
		if string.len(dlgCritere4:GetWindowName('disciplineschoisiesd'..i):GetValue()) > 0 then
			dlgCritere4:GetWindowName('prendred'..i):Enable(true);
		else
			dlgCritere4:GetWindowName('prendred'..i):Enable(false);
		end
		if dlgCritere4:GetWindowName('disciplineschoisiesx'..i) then 
			if string.len(dlgCritere4:GetWindowName('disciplineschoisiesx'..i):GetValue()) > 0 then
				dlgCritere4:GetWindowName('prendred'..i):Enable(true);
			else
				dlgCritere4:GetWindowName('prendred'..i):Enable(false);
			end
		end
		-- les manches
		arrayx[idx] = GetValue('critereType4xLigne'..i, '');
		if string.len(arrayx[idx]) > 1 then
			local tLigne = matrice['critereType4xLigne'..i]:Split('|');
			for idx = 1, #tLigne do
				if dlgCritere4:GetWindowName('disciplineschoisiesx'..i) then
					dlgCritere4:GetWindowName('disciplineschoisiesx'..i):SetValue(tLigne[2]);
					dlgCritere4:GetWindowName('prendrex'..i):SetValue(tLigne[1]);
					dlgCritere4:GetWindowName('combienx'..i):SetValue(tLigne[3]);
				end
			end
		end
	end
	for i = 0, 5 do
		dlgCritere4:GetWindowName('disciplinesproposeesb'..i):Enable(matrice.bloc2);
		dlgCritere4:GetWindowName('disciplineschoisiesb'..i):Enable(matrice.bloc2);
		dlgCritere4:GetWindowName('disciplinesproposeesd'..i):Enable(matrice.bloc2);
		dlgCritere4:GetWindowName('disciplineschoisiesd'..i):Enable(matrice.bloc2);
		dlgCritere4:GetWindowName('prendreb'..i):Enable(matrice.bloc2);
		dlgCritere4:GetWindowName('prendred'..i):Enable(matrice.bloc2);
		if dlgCritere4:GetWindowName('disciplinesproposeesx'..i) then
			dlgCritere4:GetWindowName('disciplinesproposeesx'..i):Enable(matrice.bloc2);
			dlgCritere4:GetWindowName('disciplineschoisiesx'..i):Enable(matrice.bloc2);
			dlgCritere4:GetWindowName('prendrex'..i):Enable(matrice.bloc2);
		end
	end
	dlgCritere4:Refresh();

	-- Bind
	tbdlgCritere4:Bind(eventType.MENU, 
		function(evt)
			matrice.dialog = dlgCritere4;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgCritere4:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgCritere4();
			matrice.action = 'close';
		end
		, btnValider);
		
	tbdlgCritere4:Bind(eventType.MENU, 
		function(evt)
			if dlgCritere4:MessageBox(
				"Voulez vous effacer ce crit�re de calcul ?\nVous devrez red�finir un crit�re le cas �ch�ant.", 
				"Confirmation !!!",
				msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
			end
			local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle Like 'numTypeCritere%' Or Cle Like '%critere%'";
			ski.TableLoad(cmd);
			matrice.numTypeCritere = 0;
			RempliTableauMatrice();
			dlgCritere4:MessageBox(
					"RAZ du crit�re de calcul OK !!!",
					"Effacer le crit�re de calcul", 
					msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
					) 
			dlgCritere4:EndModal(idButton.OK)
		end
		, btnRAZ);
	tbdlgCritere4:Bind(eventType.MENU, function(evt) dlgCritere4:EndModal(idButton.CANCEL) end, btnRetour);
	for i = 0, 5 do
		dlgCritere4:Bind(eventType.COMBOBOX, 
			function(evt) 
				if string.len(dlgCritere4:GetWindowName('disciplinesproposeesa'..i):GetValue()) > 0 then
					local idx = dlgCritere4:GetWindowName('disciplinesproposeesa'..i):GetSelection();
					local chaine = dlgCritere4:GetWindowName('disciplineschoisiesa'..i):GetValue();
					if chaine == '' then
						chaine = dlgCritere4:GetWindowName('disciplinesproposeesa'..i):GetValue();
					else
						chaine = chaine..','..dlgCritere4:GetWindowName('disciplinesproposeesa'..i):GetValue();
					end
					dlgCritere4:GetWindowName('disciplineschoisiesa'..i):SetValue(chaine);
				else
					dlgCritere4:GetWindowName('disciplineschoisiesa'..i):SetValue('');
					dlgCritere4:GetWindowName('combiena'..i):SetValue('');
				end
			end, 
			dlgCritere4:GetWindowName('disciplinesproposeesa'..i))
		dlgCritere4:Bind(eventType.COMBOBOX, 
			function(evt) 
				if string.len(dlgCritere4:GetWindowName('disciplinesproposeesb'..i):GetValue()) > 0 then
					local idx = dlgCritere4:GetWindowName('disciplinesproposeesb'..i):GetSelection();
					local chaine = dlgCritere4:GetWindowName('disciplineschoisiesb'..i):GetValue();
					if chaine == '' then
						chaine = dlgCritere4:GetWindowName('disciplinesproposeesb'..i):GetValue();
					else
						chaine = chaine..','..dlgCritere4:GetWindowName('disciplinesproposeesb'..i):GetValue();
					end
					dlgCritere4:GetWindowName('disciplineschoisiesb'..i):SetValue(chaine);
				else
					dlgCritere4:GetWindowName('disciplineschoisiesb'..i):SetValue('');
					dlgCritere4:GetWindowName('combienb'..i):SetValue('');
				end
			end, 
			dlgCritere4:GetWindowName('disciplinesproposeesb'..i))

		dlgCritere4:Bind(eventType.COMBOBOX, 
			function(evt) 
				if string.len(dlgCritere4:GetWindowName('disciplinesproposeesx'..i):GetValue()) > 0 then
					local idx = dlgCritere4:GetWindowName('disciplinesproposeesx'..i):GetSelection();
					local chaine = dlgCritere4:GetWindowName('disciplineschoisiesx'..i):GetValue();
					if chaine == '' then
						chaine = dlgCritere4:GetWindowName('disciplinesproposeesx'..i):GetValue();
					else
						chaine = chaine..','..dlgCritere4:GetWindowName('disciplinesproposeesx'..i):GetValue();
					end
					dlgCritere4:GetWindowName('disciplineschoisiesx'..i):SetValue(chaine);
				else
					dlgCritere4:GetWindowName('disciplineschoisiesx'..i):SetValue('');
					dlgCritere4:GetWindowName('combienx'..i):SetValue('');
				end
			end, 
			dlgCritere4:GetWindowName('disciplinesproposeesx'..i))

		dlgCritere4:Bind(eventType.TEXT, 
			function(evt) 
				if string.len(dlgCritere4:GetWindowName('disciplineschoisiesa'..i):GetValue()) > 0 then
					dlgCritere4:GetWindowName('prendrea'..i):Enable(true);
					dlgCritere4:GetWindowName('combiena'..i):Enable(true);
				else
					dlgCritere4:GetWindowName('prendrea'..i):Enable(false);
					dlgCritere4:GetWindowName('combiena'..i):Enable(false);
				end
			end, 
			dlgCritere4:GetWindowName('disciplineschoisiesa'..i))

		dlgCritere4:Bind(eventType.TEXT, 
			function(evt) 
				if string.len(dlgCritere4:GetWindowName('disciplineschoisiesb'..i):GetValue()) > 0 then
					dlgCritere4:GetWindowName('prendreb'..i):Enable(true);
					dlgCritere4:GetWindowName('combienb'..i):Enable(true);
				else
					dlgCritere4:GetWindowName('prendreb'..i):Enable(false);
					dlgCritere4:GetWindowName('combienb'..i):Enable(false);
				end
			end, 
			dlgCritere4:GetWindowName('disciplineschoisiesb'..i))

		dlgCritere4:Bind(eventType.TEXT, 
			function(evt) 
				if string.len(dlgCritere4:GetWindowName('disciplineschoisiesx'..i):GetValue()) > 0 then
					dlgCritere4:GetWindowName('prendrex'..i):Enable(true);
					dlgCritere4:GetWindowName('combienx'..i):Enable(true);
				else
					dlgCritere4:GetWindowName('prendrex'..i):Enable(false);
					dlgCritere4:GetWindowName('combienx'..i):Enable(false);
				end
			end, 
			dlgCritere4:GetWindowName('disciplineschoisiesx'..i))
	end			
	dlgCritere4:ShowModal();
end

function OnSavedlgConfigurationSupport();	-- lecture et �criture des param�tres des courses 'inclusion' / 'exclusion' des coureurs
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle = 'Evenement_support'";
	base:Query(cmd);
	matrice.support_inclusion = tonumber(dlgConfigurationSupport:GetWindowName('gauchecode'):GetValue()) or 0;
	matrice.support_exclusion = tonumber(dlgConfigurationSupport:GetWindowName('droitecode'):GetValue()) or 0;
	if matrice.support_inclusion > 0 then
		if dlgConfigurationSupport:GetWindowName('gauchechksupport'):GetValue() == false then
			matrice.support_inclusion = matrice.support_inclusion * -1;
		end
	end
	if matrice.support_exclusion > 0 then
		if dlgConfigurationSupport:GetWindowName('droitechksupport'):GetValue() == false then
			matrice.support_exclusion = matrice.support_exclusion * -1;
		end
	end
	AddRowEvenement_Matrice('Evenement_support', matrice.support_inclusion..','..matrice.support_exclusion);
end

function OnChangeCourseSupport(ou)
	if string.len(dlgConfigurationSupport:GetWindowName(ou..'code'):GetValue()) == 0 then
		dlgConfigurationSupport:GetWindowName(ou..'titre'):SetValue('');
		return;
	else
		base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..tonumber(dlgConfigurationSupport:GetWindowName(ou..'code'):GetValue()));
		if tEvenement:GetNbRows() > 0 then
			dlgConfigurationSupport:GetWindowName(ou..'titre'):SetValue(tEvenement:GetCell('Nom', 0));
		else
			dlgConfigurationSupport:GetWindowName(ou..'titre'):SetValue('????');
		end
	end
end

function AffichedlgConfigurationSupport()	-- bo�te de dialogue des param�tres des courses 'inclusion' / 'exclusion' des coureurs
	dlgConfigurationSupport = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Courses support (inclusion - exclusion des coureurs du Challenge)', 
		icon='./res/32x32_ffs.png'
		});

	dlgConfigurationSupport:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'coursesupport'
		})
	
	-- Toolbar 
	local tbcoursesupport = dlgConfigurationSupport:GetWindowName('tbcoursesupport');
	tbcoursesupport:AddStretchableSpace();
	local btnValider = tbcoursesupport:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbcoursesupport:AddSeparator();
	local btnRetour = tbcoursesupport:AddTool("Retour", "./res/32x32_exit.png");
	tbcoursesupport:AddStretchableSpace();
	tbcoursesupport:Realize();

	for i = 1, 3 do
		dlgConfigurationSupport:GetWindowName('gauchesource'..i):Append('');	
		dlgConfigurationSupport:GetWindowName('gauchesource'..i):Append('Groupe');	
		dlgConfigurationSupport:GetWindowName('gauchesource'..i):Append('Equipe');	
		dlgConfigurationSupport:GetWindowName('gauchesource'..i):Append('Critere');	
		dlgConfigurationSupport:GetWindowName('gauchedestination'..i):Append('');	
		dlgConfigurationSupport:GetWindowName('gauchedestination'..i):Append('Groupe');	
		dlgConfigurationSupport:GetWindowName('gauchedestination'..i):Append('Equipe');	
		dlgConfigurationSupport:GetWindowName('gauchedestination'..i):Append('Critere');	
		dlgConfigurationSupport:GetWindowName('droitesource'..i):Append('');	
		dlgConfigurationSupport:GetWindowName('droitesource'..i):Append('Groupe');	
		dlgConfigurationSupport:GetWindowName('droitesource'..i):Append('Equipe');	
		dlgConfigurationSupport:GetWindowName('droitesource'..i):Append('Critere');	
		dlgConfigurationSupport:GetWindowName('droitedestination'..i):Append('');	
		dlgConfigurationSupport:GetWindowName('droitedestination'..i):Append('Groupe');	
		dlgConfigurationSupport:GetWindowName('droitedestination'..i):Append('Equipe');	
		dlgConfigurationSupport:GetWindowName('droitedestination'..i):Append('Critere');	
	end
	
	-- variables
	if matrice.support_inclusion > 0 then
		dlgConfigurationSupport:GetWindowName('gauchechksupport'):SetValue(true);
	end
	if math.abs(matrice.support_inclusion) > 0 then
		dlgConfigurationSupport:GetWindowName('gauchecode'):SetValue(math.abs(matrice.support_inclusion));
		base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..math.abs(matrice.support_inclusion));
		dlgConfigurationSupport:GetWindowName('gauchetitre'):SetValue(tEvenement:GetCell('Nom', 0));
	end
	if matrice.support_exclusion > 0 then
		dlgConfigurationSupport:GetWindowName('droitechksupport'):SetValue(true);
	end
	if math.abs(matrice.support_exclusion) > 0 then
		dlgConfigurationSupport:GetWindowName('droitecode'):SetValue(math.abs(matrice.support_exclusion));;
		base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..math.abs(matrice.support_exclusion));
		dlgConfigurationSupport:GetWindowName('droitetitre'):SetValue(tEvenement:GetCell('Nom', 0));
	end
	
	-- Bind
	dlgConfigurationSupport:Bind(eventType.MENU, 
		function(evt)
			matrice.dialog = dlgConfigurationSupport;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgConfigurationSupport:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgConfigurationSupport();
			matrice.action = 'close';
		end
		, btnValider);		
	dlgConfigurationSupport:Bind(eventType.TEXT, 
		function(evt)
			OnChangeCourseSupport('gauche');
		end
		, dlgConfigurationSupport:GetWindowName('gauchecode'));
	dlgConfigurationSupport:Bind(eventType.TEXT, 
		function(evt)
			OnChangeCourseSupport('droite');
		end
		, dlgConfigurationSupport:GetWindowName('droitecode'));

	dlgConfigurationSupport:Bind(eventType.MENU, 
		function(evt) 
			dlgConfigurationSupport:EndModal(idButton.CANCEL) 
		end, btnRetour);
	
	dlgConfigurationSupport:ShowModal();
end

function OnSavedlgCopycolonnes();	-- lecture et modification des colonnes pour chaque coureur pour toutes les courses de la matrice  
	local coldestination = dlgCopycolonnes:GetWindowName('copycoldestination'):GetValue()
	if matrice.copySource then	-- on recopie le contenu de la colonne source de la course dans la colonne destination dans toutes les courses de la matrice
		base:TableLoad(Resultat, 'Select * From Resultat Where Code_evenement = '..matrice.copySource);
		local colsource = dlgCopycolonnes:GetWindowName('copycolsource'):GetValue();
		for i = 1, tResultat:GetNbRows() -1 do
			local code_coureur = tResultat:GetCell('Code_coureur', i);
			local valeur = tResultat:GetCell(colsource, i);
			cmd = 'Update Resultat Set '..coldestination.." = '"..valeur.."' \n"..
				' Where Code_evenement In('..matrice.Evenement_selection..') \n'..
				" And Code_coureur = '"..code_coureur.."' \n";
			if matrice.debug == true then
				adv.Alert(cmd);
			end
			base:Query(cmd);
		end
	end
	local valeur = dlgCopycolonnes:GetWindowName('copydata'):GetValue();
	if string.len(valeur) > 0 then
		cmd = 'Update Resultat Set '..coldestination.." = '"..valeur.."' "..
			' Where Code_evenement In('..matrice.Evenement_selection..') ';
		if matrice.debug == true then
			adv.Alert(cmd);
		end
		base:Query(cmd);
	else
		if app.GetAuiFrame():MessageBox(
			"Voulez-vous remettre � blanc le contenu de la colonne "..coldestination..'\npour toutes les courses incluses dans la matrice ?', 
			"Attention !!!",
			msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_WARNING
			) == msgBoxStyle.YES then
			local cmd = 'Update Resultat Set '..coldestination.." = NULL "..
				' Where Code_evenement In('..matrice.Evenement_selection..') ';
			base:Query(cmd);
		end
	end
	valeur = dlgCopycolonnes:GetWindowName('mettre'):GetValue();
	if string.len(valeur) > 0 then
		local destination = dlgCopycolonnes:GetWindowName('destination'):GetValue();
		local mettre = dlgCopycolonnes:GetWindowName('mettre'):GetValue();
		local virgule = '';
		local chaine = '';
		for i = 1, tCategPresentes:GetNbRows() do
			if dlgCopycolonnes:GetWindowName('chk'..i):GetValue() == true then
				chaine = chaine..virgule..tCategPresentes:GetCell('Categ', i-1);
				virgule = "','";
			end
		end
		if chaine:len() > 0 then
			cmd = 'Update Resultat Set '..destination.." = '"..mettre.."' "..
				' Where Code_evenement In('..matrice.Evenement_selection..") and categ In('"..chaine.."')";
			base:Query(cmd);
		end
	end
end

function OnChangeDataCopycolonnes()
	if string.len(dlgCopycolonnes:GetWindowName('copydata'):GetValue()) > 0 then
		dlgCopycolonnes:GetWindowName('copycolsource'):SetValue('');
		dlgCopycolonnes:GetWindowName('copycolsource'):Enable(false);
	else
		dlgCopycolonnes:GetWindowName('copycolsource'):SetValue('Groupe');
		dlgCopycolonnes:GetWindowName('copycolsource'):Enable(true);
	end
end

function OnChangeCourseCopycolonnes()
	matrice.copySource = nil;
	if string.len(dlgCopycolonnes:GetWindowName('copycoursecode'):GetValue()) == 0 then
		dlgCopycolonnes:GetWindowName('copycoursetitre'):SetValue('')
		dlgCopycolonnes:GetWindowName('copydata'):SetValue('')
		dlgCopycolonnes:GetWindowName('copydata'):Enable(false);
		return;
	end
	dlgCopycolonnes:GetWindowName('copydata'):Enable(false);
	base:TableLoad(tEvenement, "Select * From Evenement Where Code = "..tonumber(dlgCopycolonnes:GetWindowName('copycoursecode'):GetValue())..' And Not Code_activite = "CHA-CMB"');
	if tEvenement:GetNbRows() > 0 then
		dlgCopycolonnes:GetWindowName('copycoursetitre'):SetValue(Evenement:GetCell('Nom', 0));
		matrice.copySource = Evenement:GetCell('Code', 0);
		dlgCopycolonnes:GetWindowName('copycolsource'):Enable(true);
		dlgCopycolonnes:GetWindowName('copydata'):Enable(true);
	else
		dlgCopycolonnes:GetWindowName('copycoursetitre'):SetValue('????');
		dlgCopycolonnes:GetWindowName('copycolsource'):Enable(false);
		dlgCopycolonnes:GetWindowName('copydata'):Enable(false);
	end
end


function AffichedlgCopycolonnes()	-- affiche la bo�te de dialogue pour la copie et l'�criture du contenu des colonnes pour toutes les courses de la matrice
	matrice.copySource = nil;
	dlgCopycolonnes = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Copier le contenu des colonnes dans les courses de la matrice', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgCopycolonnes:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'copycolonne', 		-- Facultatif si le node_name est unique ...
		Rows = tCategPresentes:GetNbRows();
	});

	-- Toolbar 
	local tbcopycolonne = dlgCopycolonnes:GetWindowName('tbcopycolonne');
	tbcopycolonne:AddStretchableSpace();
	local btnValider = tbcopycolonne:AddTool("Valider", "./res/vpe32x32_save.png");
	tbcopycolonne:AddSeparator();
	local btnRetour = tbcopycolonne:AddTool("Retour", "./res/32x32_exit.png");
	tbcopycolonne:AddStretchableSpace();
	tbcopycolonne:Realize();

	dlgCopycolonnes:GetWindowName('copycolsource'):Append('');	
	dlgCopycolonnes:GetWindowName('copycolsource'):Append('Groupe');	
	dlgCopycolonnes:GetWindowName('copycolsource'):Append('Equipe');	
	dlgCopycolonnes:GetWindowName('copycolsource'):Append('Critere');	
	dlgCopycolonnes:GetWindowName('copycolsource'):SetValue('Groupe');	
	dlgCopycolonnes:GetWindowName('copycoldestination'):Append('Groupe');	
	dlgCopycolonnes:GetWindowName('copycoldestination'):Append('Equipe');	
	dlgCopycolonnes:GetWindowName('copycoldestination'):Append('Critere');	
	dlgCopycolonnes:GetWindowName('copycoldestination'):SetValue('Groupe');
	dlgCopycolonnes:GetWindowName('destination'):Clear();
	dlgCopycolonnes:GetWindowName('destination'):Append('Groupe');	
	dlgCopycolonnes:GetWindowName('destination'):Append('Equipe');	
	dlgCopycolonnes:GetWindowName('destination'):Append('Critere');	
	dlgCopycolonnes:GetWindowName('destination'):SetValue('Groupe');
	if matrice.copySource then
		dlgCopycolonnes:GetWindowName('copycolsource'):Enable(true);	
		dlgCopycolonnes:GetWindowName('copydata'):Enable(false);
	else
		dlgCopycolonnes:GetWindowName('copycolsource'):Enable(false);	
		dlgCopycolonnes:GetWindowName('copydata'):Enable(true);
	end
	for i = 1, tCategPresentes:GetNbRows() do
		dlgCopycolonnes:GetWindowName('categ'..i):SetValue(tCategPresentes:GetCell(0, i -1));
	end
	
	-- Bind
	for i = 1, tCategPresentes:GetNbRows() do
		dlgCopycolonnes:Bind(eventType.CHECKBOX, 
			function(evt)
				local mettre = '';
				dlgCopycolonnes:GetWindowName('mettre'):SetValue(mettre);
				for j = 1, tCategPresentes:GetNbRows() do
					if dlgCopycolonnes:GetWindowName('chk'..j):GetValue() == true then
						if mettre:len() == 0 then
							mettre = dlgCopycolonnes:GetWindowName('categ'..j):GetValue();
						else
							mettre = mettre..','..dlgCopycolonnes:GetWindowName('categ'..j):GetValue();
						end
					end
				end
				dlgCopycolonnes:GetWindowName('mettre'):SetValue(mettre);
			end
		,dlgCopycolonnes:GetWindowName('chk'..i));
	end
	dlgCopycolonnes:Bind(eventType.MENU, 
		function(evt)
			matrice.dialog = dlgCopycolonnes;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgCopycolonnes:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgCopycolonnes();
			matrice.action = 'close';
		end
		, btnValider);
		
	dlgCopycolonnes:Bind(eventType.TEXT, 
		function(evt)
			OnChangeCourseCopycolonnes();
		end
		, dlgCopycolonnes:GetWindowName('copycoursecode'));
	dlgCopycolonnes:Bind(eventType.TEXT, 
		function(evt)
			OnChangeDataCopycolonnes();
		end
		, dlgCopycolonnes:GetWindowName('copydata'));
	dlgCopycolonnes:Bind(eventType.MENU, 
		function(evt) 
			dlgCopycolonnes:EndModal(idButton.CANCEL) 
		end, btnRetour);
	dlgCopycolonnes:ShowModal();
end

function OnSavedlgScriptLua()		-- �criture de la variable scriptLUA � lancer avant les calculs (si l'option est coch�e);
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle = 'scriptLUA'";
	base:Query(cmd);
	local path1 = dlgScriptLua:GetWindowName('script1'):GetValue();
	local path2 = dlgScriptLua:GetWindowName('script2'):GetValue();
	if string.len(path2) > 0 then
		AddRowEvenement_Matrice('scriptLUA', path2);
		dlgScriptLua:MessageBox(
				"Enregistrement OK !!!",
				"Script � lancer avant de faire les calculs", 
				msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
				) 
	end
	if string.len(path1) > 0 then
		if dlgScriptLua:MessageBox(
			"Voulez-vous lancer le script "..path1.." ?", 
			"Confirmation !!!",
			msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
		end
		dofile(path1);
	end
end

function OnPathScriptLua(id)	-- recherche d'un script LUA
	local name = '� lancer imm�diatement';
	local path = {};
	if id == 2 then
		name = '� lancer avant de faire les calculs';
	end
	local fileDialog = wnd.CreateFileDialog(dlgScriptLua,
		"S�lection du script LUA "..name,
		app.GetPath(), 
		"",
		"*.lua|*.lua",
		fileDialogStyle.OPEN+fileDialogStyle.FD_FILE_MUST_EXIST
	);
	if fileDialog:ShowModal() == idButton.OK then
		path[id] = string.gsub(fileDialog:GetPath(), app.GetPathSeparator(), "/");
		dlgScriptLua:GetWindowName('script'..id):SetValue(path[id]);
		if id == 2 then
			matrice.scriptLUA = path[id];
		end
	else
		dlgScriptLua:GetWindowName('script'..id):SetValue('');		
		if id == 2 then
			matrice.scriptLUA = nil;
		end
	end
end

function AffichedlgScriptLua()	-- affiche la bo�te de dialogue de recherche d'un script LUA
	matrice.copySource = nil;
	dlgScriptLua = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Rechercher un script LUA', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgScriptLua:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'scriptlua' 		-- Facultatif si le node_name est unique ...
	});
	
	-- Toolbar 
	local tbscriptlua = dlgScriptLua:GetWindowName('tbscriptlua');
	tbscriptlua:AddStretchableSpace();
	local btnValider = tbscriptlua:AddTool("Valider", "./res/vpe32x32_save.png");
	tbscriptlua:AddSeparator();
	local btnRAZ = tbscriptlua:AddTool("Effacer", "./res/32x32_clear.png");
	tbscriptlua:AddSeparator();
	local btnRetour = tbscriptlua:AddTool("Retour", "./res/32x32_exit.png");
	tbscriptlua:AddStretchableSpace();
	tbscriptlua:Realize();
	
	if matrice.scriptLUA then
		dlgScriptLua:GetWindowName('script2'):SetValue(matrice.scriptLUA);
	end
	-- Bind
	dlgScriptLua:Bind(eventType.MENU, 
		function(evt)
			TimerStart(dlgScriptLua)
			OnSavedlgScriptLua();
		end
		, btnValider);
	dlgScriptLua:Bind(eventType.MENU, 
		function(evt)
			dlgScriptLua:GetWindowName('script2'):SetValue('');
			local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle = 'scriptLUA'";
			base:Query(cmd);
			matrice.scriptLUA = nil;
			dlgScriptLua:MessageBox(
					"Le script LUA a �t� effac� !!",
					"Script � lancer avant de faire les calculs", 
					msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
					) 
			dlgScriptLua:EndModal(idButton.OK)
		end
		, btnRAZ);
	for i = 1, 2 do
		dlgScriptLua:Bind(eventType.BUTTON, function(evt) OnPathScriptLua(i) end, dlgScriptLua:GetWindowName('bscript'..i));
	end
		
	dlgScriptLua:Bind(eventType.MENU, function(evt) dlgScriptLua:EndModal(idButton.CANCEL) end, btnRetour);
	dlgScriptLua:ShowModal();
end

function OnSavedlgInscription()		-- lecture et �criture des variables pour la cr�ation d'une nouvelle course.
	matrice.inscriptionPresent = dlgInscription:GetWindowName('presents'):GetValue();
	matrice.garderDossards = dlgInscription:GetWindowName('garderdossards'):GetValue();
	matrice.typeTirage = dlgInscription:GetWindowName('typetirage'):GetValue();
	matrice.bibo = tonumber(dlgInscription:GetWindowName('bibo'):GetValue()) or 0;
	if string.find(matrice.typeTirage, 'bibo') and matrice.bibo == 0 then
		dlgInscription:MessageBox(
				"Vous devez indiquer la valeur du bibo\npour g�n�rer le fichier inscription.",
				"Saisie du bibo", 
				msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
				) 
		return;
	end
	dlgInscription:EndModal(idButton.CANCEL)
	matrice.panel_name = 'nada';
	Calculer(nil);
end

function AffichedlgInscription()	-- bo�te de dialogue pour la cr�ation d'une nouvelle course.
	dlgInscription = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='G�n�rer un fichier Inscription', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgInscription:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'inscription' 		-- Facultatif si le node_name est unique ...
	});

	-- Toolbar 
	local tbinscription = dlgInscription:GetWindowName('tbinscription');
	tbinscription:AddStretchableSpace();
	local btnValider = tbinscription:AddTool("Valider", "./res/vpe32x32_save.png");
	tbinscription:AddSeparator();
	local btnRetour = tbinscription:AddTool("Retour", "./res/32x32_exit.png");
	tbinscription:AddStretchableSpace();
	tbinscription:Realize();
	
	-- variables
	dlgInscription:GetWindowName('typetirage'):Clear();
	dlgInscription:GetWindowName('typetirage'):Append('1.Global � la m�l�e');
	dlgInscription:GetWindowName('typetirage'):Append("2.Selon le classement du Challenge");
	dlgInscription:GetWindowName('typetirage'):Append("3.Selon le classement du Challenge ET inversion des x meilleurs");
	dlgInscription:GetWindowName('typetirage'):Append("4.Selon le classement du Challenge ET tirage au sort des x meilleurs");
	dlgInscription:GetWindowName('typetirage'):Append("5.Selon les points inscription ET tirage au sort des x meilleurs");
	dlgInscription:GetWindowName('typetirage'):SetSelection(0);
	dlgInscription:GetWindowName('inscriptionapres'):Clear();
	dlgInscription:GetWindowName('inscriptionapres'):Append('');
	dlgInscription:GetWindowName('inscriptionapres'):SetSelection(0);
	dlgInscription:GetWindowName('garderdossards'):Enable(false)
	dlgInscription:GetWindowName('inscriptionapres'):Enable(false)
	dlgInscription:GetWindowName('bibo'):Enable(false)
	
	-- Bind
	dlgInscription:Bind(eventType.CHECKBOX, 
		function(evt) 
			dlgInscription:GetWindowName('garderdossards'):Enable(dlgInscription:GetWindowName('presents'):GetValue())
			dlgInscription:GetWindowName('inscriptionapres'):Enable(dlgInscription:GetWindowName('presents'):GetValue())
			if dlgInscription:GetWindowName('presents'):GetValue() == true then
				dlgInscription:GetWindowName('typetirage'):Clear();
				dlgInscription:GetWindowName('typetirage'):Append('1.Global � la m�l�e');
				dlgInscription:GetWindowName('typetirage'):Append("2.Selon le classement du Challenge");
				dlgInscription:GetWindowName('typetirage'):Append("3.Selon le classement du Challenge ET inversion des x meilleurs");
				dlgInscription:GetWindowName('typetirage'):Append("4.Selon le classement du Challenge ET tirage au sort des x meilleurs");
				dlgInscription:GetWindowName('typetirage'):Append("5.Selon les points inscription ET tirage au sort des x meilleurs");
				dlgInscription:GetWindowName('typetirage'):Append("6.Conserver l'ordre des dossards");
				dlgInscription:GetWindowName('typetirage'):Append("7.Inverser l'ordre des dossards");
				dlgInscription:GetWindowName('typetirage'):SetSelection(0);
				dlgInscription:GetWindowName('inscriptionapres'):Clear();
				dlgInscription:GetWindowName('inscriptionapres'):Append('');
				LitMatriceCourses(false);
				local last = tMatrice_Courses:GetNbRows() -1;
				local txt = 'n� '..tMatrice_Courses:GetCell('Code', last)..' - '..tMatrice_Courses:GetCell('Date_epreuve', last)..' - '..tMatrice_Courses:GetCell('Station', last)..' : '..tMatrice_Courses:GetCell('Code_discipline', last);
				dlgInscription:GetWindowName('inscriptionapres'):SetValue(txt);
			else
				dlgInscription:GetWindowName('typetirage'):Clear();
				dlgInscription:GetWindowName('typetirage'):Append('1.Global � la m�l�e');
				dlgInscription:GetWindowName('typetirage'):Append("2.Selon le classement du Challenge");
				dlgInscription:GetWindowName('typetirage'):Append("3.Selon le classement du Challenge ET inversion des x meilleurs");
				dlgInscription:GetWindowName('typetirage'):Append("4.Selon le classement du Challenge ET tirage au sort des x meilleurs");
				dlgInscription:GetWindowName('typetirage'):Append("5.Selon les points inscription ET tirage au sort des x meilleurs");
				dlgInscription:GetWindowName('typetirage'):SetSelection(0);
				dlgInscription:GetWindowName('inscriptionapres'):SetValue('');
			end
		end,
		dlgInscription:GetWindowName('presents'));
	dlgInscription:Bind(eventType.COMBOBOX, 
		function(evt) 
			if string.find(dlgInscription:GetWindowName('typetirage'):GetValue(), 'tirage') then
				dlgInscription:GetWindowName('bibo'):Enable(true);
			else
				dlgInscription:GetWindowName('bibo'):SetValue('');
				dlgInscription:GetWindowName('bibo'):Enable(false);
			end
		end,
		dlgInscription:GetWindowName('typetirage'));

	dlgInscription:Bind(eventType.MENU, 
		function(evt) 
			matrice.dialog = dlgAnalyse;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgAnalyse:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgInscription() 
			matrice.action = 'close';
		end, btnValider);
	dlgInscription:Bind(eventType.MENU, 
		function(evt) 
			dlgInscription:EndModal(idButton.CANCEL) 
		end, btnRetour);
	dlgInscription:ShowModal();
end

function BuildRegroupement()
	local cmd = "Select * From Regroupement Where Code_saison = '"..matrice.Saison.."'";
	if matrice.comboActivite then
		cmd = cmd.." And Code_activite = '"..matrice.comboActivite.."'";
	end
	if matrice.comboEntite then
		cmd = cmd.." And Code_entite = '"..matrice.comboEntite.."'";
	end
	cmd = cmd.." Order By Ordre";
	base:TableLoad(tRegroupement, cmd);
end

function OnSavedlgFiltrePoint(raz)
	matrice.combListe0Entite = nil; matrice.comboListe0Classement = nil; matrice.comboListe0 = nil;
	matrice.numPtsBas = nil; matrice.numPtsHaut = nil;
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle In('comboListe0Entite', 'comboListe0Classement', 'comboListe0', 'numPtsBas', 'numPtsHaut')";
	base:Query(cmd);
	if raz == false then
		local idxtypeclassement = dlgFiltrePoint:GetWindowName('comboListe0Classement'):GetSelection();
		local classement = tType_Classement:GetCell('Code',idxtypeclassement);
		local idxliste = dlgFiltrePoint:GetWindowName('comboListe0'):GetSelection();
		local liste = Liste:GetCellInt('Code_liste', idxliste);
		AddRowEvenement_Matrice('comboListe0Classement', classement);
		AddRowEvenement_Matrice('comboListe0', liste);
		AddRowEvenement_Matrice('numPtsBas', dlgFiltrePoint:GetWindowName('numPtsBas'):GetValue());
		AddRowEvenement_Matrice('numPtsHaut', dlgFiltrePoint:GetWindowName('numPtsHaut'):GetValue());
	end
	RempliTableauMatrice();
end

function AffichedlgVisuFiltrexPoints()		-- bo�te de dialogue de filtrage des coureurs par les points. S'il existe ,
	dlgFiltrePoint = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Plage de points - S�lection des coureurs', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgFiltrePoint:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'configplagepoints' 		-- Facultatif si le node_name est unique ...
	});


	-- Toolbar 
	local tbconfigplagepoints = dlgFiltrePoint:GetWindowName('tbconfigplagepoints');
	tbconfigplagepoints:AddStretchableSpace();
	local btnSaveEdit = tbconfigplagepoints:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbconfigplagepoints:AddSeparator();
	local btnRAZ = tbconfigplagepoints:AddTool("RAZ du filtre", "./res/32x32_clear.png");
	tbconfigplagepoints:AddSeparator();
	local btnClose = tbconfigplagepoints:AddTool("Retour", "./res/32x32_exit.png");
	tbconfigplagepoints:AddStretchableSpace();

	tbconfigplagepoints:Realize();

	-- Initialisation des controles et affectation des variables
	matrice.combListe0Entite = GetValue('combListe0Entite', matrice.comboEntite);
	matrice.comboListe0Classement = GetValue('comboListe0Classement', '');
	matrice.comboListe0 = GetValue('comboListe0', '');
	matrice.numPtsBas = GetValueNumber('numPtsBas', 0)
	matrice.numPtsHaut = GetValueNumber('numPtsHaut', 0)
	dlgFiltrePoint:GetWindowName('comboListe0Entite'):Append('FFS');
	dlgFiltrePoint:GetWindowName('comboListe0Entite'):Append('FIS');
	if matrice.combListe0Entite then
		dlgFiltrePoint:GetWindowName('comboListe0Entite'):SetValue(matrice.combListe0Entite);
		PopulateComboClassementEtListe('dlgFiltrePoint', 0);
	end
	if matrice.comboListe0Classement then
		dlgFiltrePoint:GetWindowName('comboListe0Classement'):SetValue(matrice.comboListe0Classement);
	end
	if matrice.comboListe0 then
		dlgFiltrePoint:GetWindowName('comboListe0'):SetValue(matrice.comboListe0);
	end
	dlgFiltrePoint:GetWindowName('numPtsBas'):SetValue(matrice.numPtsBas);
	dlgFiltrePoint:GetWindowName('numPtsHaut'):SetValue(matrice.numPtsHaut);
	-- dlgFiltrePoint:Refresh();

	-- Bind
	dlgFiltrePoint:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangecomboClassement();
		end,  
		dlgFiltrePoint:GetWindowName('comboListe0Classement'));
	dlgFiltrePoint:Bind(eventType.COMBOBOX, 
		function(evt) 
			PopulateComboClassementEtListe('dlgFiltrePoint', 0);
		end,  
		dlgFiltrePoint:GetWindowName('comboListe0Entite'));
	tbconfigplagepoints:Bind(eventType.MENU, 
		function(evt) 
			matrice.dialog = dlgFiltrePoint;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgFiltrePoint:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgFiltrePoint(false);
			matrice.action = 'close';
		end, btnSaveEdit);
	tbconfigplagepoints:Bind(eventType.MENU, 
			function(evt) 
				OnSavedlgFiltrePoint(true);
				dlgFiltrePoint:EndModal(idButton.OK)
			end, btnRAZ);
	tbconfigplagepoints:Bind(eventType.MENU, 
			function(evt) 
				dlgFiltrePoint:EndModal(idButton.CANCEL)
			end, btnClose);
	dlgFiltrePoint:ShowModal();
end

function PopulateComboClassementEtListe(dlg, idx)	-- fonction commune pour AffichedlgColonne et AffichedlgVisuFiltrexPoints
	do return end
	local dialog = nil;
	local comboliste = nil;
	local matricecomboclassement = nil;
	local matricecomboentite = nil;
	
	matrice['comboListe'..idx..'Entite'] = matrice['comboListe'..idx..'Entite'] or matrice.comboEntite;
	local comboclassement = 'comboListe'..idx..'Classement';
	comboliste = 'comboListe'..idx;
	if dlg == 'dlgColonne' then
		dialog = dlgColonne;
		if idx == 1 then
			if not matrice.comboListe1Entite then
				matrice.comboListe1Entite = matrice.comboEntite;
			end
			matricecomboentite = matrice.comboListe1Entite;
			if matrice.comboListe1Classement then
				matricecomboclassement = matrice.comboListe1Classement;
			end
			if matrice.comboListe1 then
				matricecomboliste = matrice.comboListe1;
			end
			dlgColonne:GetWindowName('comboListe1Entite'):Enable(dialog:GetWindowName('chk12'):GetValue() == true);
			dlgColonne:GetWindowName('comboListe1Classement'):Enable(dialog:GetWindowName('chk12'):GetValue() == true);
			dlgColonne:GetWindowName('comboListe1'):Enable(dialog:GetWindowName('chk12'):GetValue() == true);
		else
			if not matrice.comboListe2Entite then
				matrice.comboListe2Entite = matrice.comboEntite;
			end
			matricecomboentite = matrice.comboListe2Entite;
			if matrice.comboListe2Classement then
				matricecomboclassement = matrice.comboListe2Classement;
			end
			if matrice.comboListe2 then
				matricecomboliste = matrice.comboListe2;
			end
			dlgColonne:GetWindowName('comboListe2Entite'):Enable(false);
			dlgColonne:GetWindowName(comboclassement):Enable(dialog:GetWindowName('chk13'):GetValue() == true);
			dlgColonne:GetWindowName(comboliste):Enable(dialog:GetWindowName('chk13'):GetValue() == true);
		end
	elseif dlg == 'dlgFiltrePoint' then
		dialog = dlgFiltrePoint;
		matrice.combListe0Entite = matrice.combListe0Entite or matrice.comboEntite;
		matricecomboentite = dialog:GetWindowName('comboListe0Entite'):GetValue();
		matrice.combListe0Entite = matricecomboentite;
	end
	local cmd = '';
	if matrice.comboActivite == "ALP" then
		if matricecomboentite == "FFS" then
			cmd = "Select * From Type_Classement Where Code_activite = '"..matrice.comboActivite.."' And Code In ('FAU') And Affichage = 'O' Order By Libelle DESC";
		else
			cmd = "Select * From Type_Classement Where Code_activite = '"..matrice.comboActivite.."' And Code In ('IASL', 'IAGS', 'IASG', 'IADH') And Affichage = 'O' Order By Libelle DESC";
		end
	else
	end
	base:TableLoad(tType_Classement, cmd);
	if matrice.debug == true then
		adv.Alert("PopulateComboClassementEtListe - Snapshot('Type_Classement.db3')");
		tType_Classement:Snapshot('Type_Classement.db3');
	end
	dialog:GetWindowName(comboclassement):Clear();
	for i = 0, tType_Classement:GetNbRows()-1 do
		dialog:GetWindowName(comboclassement):Append(tType_Classement:GetCell('Libelle', i));
	end
	if matricecomboclassement then
		local r = tType_Classement:GetIndexRow('Code', matricecomboclassement);
		if r >= 0 then
			dialog:GetWindowName(comboclassement):SetValue(tType_Classement:GetCell('Libelle', r));
		end
	else
		dialog:GetWindowName(comboclassement):SetSelection(0);
		matricecomboclassement = dialog:GetWindowName(comboclassement):GetValue();
	end
	-- pour les comboListex
	dialog:GetWindowName(comboliste):Clear();
	local typeclassement = '';
	if matrice.comboActivite == 'ALP' then
		if matricecomboentite == "FIS" then
			typeclassement = 'IAU';
		else
			typeclassement = 'FAU';
		end
	else
	end
end

function OnSavedlgTexte()
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And (Cle Like 'texte%')";
	base:Query(cmd);
	matrice.texteImprimerHeader = dlgTexte:GetWindowName('texteImprimerHeader'):GetValue();
	AddRowEvenement_Matrice('texteImprimerHeader', matrice.texteImprimerHeader);
	AddRowEvenement_Matrice('texteMargeHaute1', dlgTexte:GetWindowName('texteMargeHaute1'):GetValue());
	AddRowEvenement_Matrice('texteMargeHaute2', dlgTexte:GetWindowName('texteMargeHaute2'):GetValue());
	matrice.texteImprimerClubLong = dlgTexte:GetWindowName('texteImprimerClubLong'):GetValue();
	AddRowEvenement_Matrice('texteImprimerClubLong', matrice.texteImprimerClubLong);
	AddRowEvenement_Matrice('texteFontSize', dlgTexte:GetWindowName('texteFontSize'):GetValue());
	matrice.texteImprimerLayer = dlgTexte:GetWindowName('texteImprimerLayer'):GetValue();
	AddRowEvenement_Matrice('texteImprimerLayer', matrice.texteImprimerLayer);
	matrice.texteImprimerLayerPage = dlgTexte:GetWindowName('texteImprimerLayerPage'):GetValue();
	AddRowEvenement_Matrice('texteImprimerLayerPage', matrice.texteImprimerLayerPage);
	matrice.texteLargeurLarge = dlgTexte:GetWindowName('texteLargeurLarge'):GetValue();
	AddRowEvenement_Matrice('texteLargeurLarge', matrice.texteLargeurLarge);
	matrice.texteLargeurEtroite = dlgTexte:GetWindowName('texteLargeurEtroite'):GetValue();
	AddRowEvenement_Matrice('texteLargeurEtroite', matrice.texteLargeurEtroite);
	matrice.texteImprimerDeparts = dlgTexte:GetWindowName('texteImprimerDeparts'):GetValue();
	AddRowEvenement_Matrice('texteImprimerDeparts', matrice.texteImprimerDeparts);
	matrice.texteImprimerStatCourses = dlgTexte:GetWindowName('texteImprimerStatCourses'):GetValue();
	AddRowEvenement_Matrice('texteImprimerStatCourses', matrice.texteImprimerStatCourses);
	matrice.texteNbColPresCourses = dlgTexte:GetWindowName('texteNbColPresCourses'):GetValue();
	AddRowEvenement_Matrice('texteNbColPresCourses', matrice.texteNbColPresCourses);
	matrice.texteComiteOrigine = dlgTexte:GetWindowName('texteComiteOrigine'):GetValue();
	AddRowEvenement_Matrice('texteComiteOrigine', matrice.texteComiteOrigine);
	matrice.texteLigne2Texte = dlgTexte:GetWindowName('texteLigne2Texte'):GetValue();
	AddRowEvenement_Matrice('texteLigne2Texte', matrice.texteLigne2Texte);
	matrice.texteImageStatCourses = dlgTexte:GetWindowName('texteImageStatCourses'):GetValue();
	AddRowEvenement_Matrice('texteImageStatCourses', matrice.texteImageStatCourses);

	matrice.texteCodeComplet = dlgTexte:GetWindowName('texteCodeComplet'):GetValue();
	AddRowEvenement_Matrice('texteCodeComplet', matrice.texteCodeComplet);
	matrice.texteFiltreSupplementaire = dlgTexte:GetWindowName('texteFiltreSupplementaire'):GetValue();
	AddRowEvenement_Matrice('texteFiltreSupplementaire', matrice.texteFiltreSupplementaire);
	RempliTableauMatrice();
	-- app.GetAuiFrame():MessageBox(
			-- "Enregistrement OK !!!",
			-- "Param�trage des Elements � imprimer", 
			-- msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
			--) 
end

function LectureLayers(node)
	if node == nil then
		return
	end
	child = xmlNode.GetChildren(node);
	while child ~= nil do
		if node:HasAttribute("id") then 		-- on est sur un node = layer
			table.insert(matrice.layers, node:GetAttribute("id"));
		end
		LectureLayers(child);
	end
	LectureLayers(node:GetNext())
end

function AffichedlgTexte()		-- bo�te de dialogue pour le choix des textes � imprimer 
	dlgTexte = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Param�trage compl�mentaire de la matrice', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgTexte:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'texte' 				-- Facultatif si le node_name est unique ...
	});
	
	matrice.layers = {};
	local xml_layers = './edition/layer.perso.xml';
	if app.FileExists(xml_layers) then
		local doc = xmlDocument.Create(xml_layers);
		local root = doc:GetRoot();
		if root ~= nil then
			LectureLayers(root);
		end
		doc:Delete();
	else
		local utf8 = true;
		local doc = xmlDocument.Create();
		local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "layers");
		if doc:SetRoot(nodeRoot) == false then
			adv.Alert('doc:SetRoot(nodeRoot) == false');
			return;
		else
			adv.Alert('doc:SetRoot(nodeRoot) == true');
		end
		doc:SaveFile(app.GetPath()..'/edition/layer.perso.xml');
		doc:Delete();
	end
	-- Toolbar 
	local tbtexte = dlgTexte:GetWindowName('tbtexte');
	tbtexte:AddStretchableSpace();
	local btnSaveEdit = tbtexte:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbtexte:AddSeparator();
	local btnClose = tbtexte:AddTool("Retour", "./res/32x32_exit.png");
	tbtexte:AddStretchableSpace();

	tbtexte:Realize();

	-- Initialisation des controles et affectation des variables
	
	dlgTexte:GetWindowName('texteImprimerHeader'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgTexte:GetWindowName('texteImprimerHeader'):SetValue(matrice.texteImprimerHeader);
	dlgTexte:GetWindowName('texteMargeHaute1'):SetValue(matrice.texteMargeHaute1);
	dlgTexte:GetWindowName('texteMargeHaute2'):SetValue(matrice.texteMargeHaute2);
	dlgTexte:GetWindowName('texteImprimerClubLong'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgTexte:GetWindowName('texteImprimerClubLong'):SetValue(matrice.texteImprimerClubLong);
	dlgTexte:GetWindowName('texteFiltreSupplementaire'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgTexte:GetWindowName('texteFiltreSupplementaire'):SetValue(matrice.texteFiltreSupplementaire);
	
	dlgTexte:GetWindowName('texteNbColPresCourses'):Clear();
	dlgTexte:GetWindowName('texteNbColPresCourses'):Append('3');
	dlgTexte:GetWindowName('texteNbColPresCourses'):Append('4');
	dlgTexte:GetWindowName('texteNbColPresCourses'):Append('5');
	dlgTexte:GetWindowName('texteNbColPresCourses'):SetValue(matrice.texteNbColPresCourses);
	dlgTexte:GetWindowName('texteComiteOrigine'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgTexte:GetWindowName('texteComiteOrigine'):SetValue(matrice.texteComiteOrigine);

	dlgTexte:GetWindowName('texteFontSize'):SetValue(matrice.texteFontSize);
	dlgTexte:GetWindowName('texteImprimerLayer'):Clear();
	dlgTexte:GetWindowName('texteImprimerLayer'):Append('');
	dlgTexte:GetWindowName('texteImprimerLayerPage'):Clear();
	dlgTexte:GetWindowName('texteImprimerLayerPage'):Append('Toutes les pages');
	dlgTexte:GetWindowName('texteImprimerLayerPage'):Append('Sur la page 1');
	dlgTexte:GetWindowName('texteImprimerLayerPage'):Append('Sur la page 2 et suivante');
	dlgTexte:GetWindowName('texteImprimerStatCourses'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgTexte:GetWindowName('texteImprimerStatCourses'):SetValue(matrice.texteImprimerStatCourses);
	dlgTexte:GetWindowName('texteLigne2Texte'):SetValue(matrice.texteLigne2Texte);
	dlgTexte:GetWindowName('texteImageStatCourses'):SetValue(matrice.texteImageStatCourses);
	
	for i = 1, #matrice.layers do
		dlgTexte:GetWindowName('texteImprimerLayer'):Append(matrice.layers[i]);
	end
	dlgTexte:GetWindowName('texteImprimerLayer'):SetValue(matrice.texteImprimerLayer);
	dlgTexte:GetWindowName('texteImprimerLayerPage'):SetValue(matrice.texteImprimerLayerPage);
	local array = {'0,5','0,6','0,7','0,8', '0,9', '1', '1,1', '1,2', '1,3', '1,4', '1,5'};
	dlgTexte:GetWindowName('texteLargeurEtroite'):Clear();
	dlgTexte:GetWindowName('texteLargeurLarge'):Clear();
	for i = 1, #array do
		dlgTexte:GetWindowName('texteLargeurLarge'):Append(tostring(array[i]));
		dlgTexte:GetWindowName('texteLargeurEtroite'):Append(tostring(array[i]));
	end
	dlgTexte:GetWindowName('texteLargeurEtroite'):SetValue(matrice.texteLargeurEtroite);
	dlgTexte:GetWindowName('texteLargeurLarge'):SetValue(matrice.texteLargeurLarge);
	
	dlgTexte:GetWindowName('texteImprimerDeparts'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgTexte:GetWindowName('texteImprimerDeparts'):SetValue(matrice.texteImprimerDeparts);

	dlgTexte:GetWindowName('texteCodeComplet'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgTexte:GetWindowName('texteCodeComplet'):SetValue(matrice.texteCodeComplet);

	-- Bind
	tbtexte:Bind(eventType.MENU, 
		function(evt) 
			if matrice.bloc2 == true and dlgTexte:GetWindowName('texteImprimerStatCourses'):GetValue() == 'Oui' then
				dlgConfig:MessageBox(
					"L'impression des du tableau des crit�res de calcul est incompatible\navec l'existence d'un bloc 2.",
					"Merci de saisir une course", 
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
					) ;
				dlgTexte:GetWindowName('texteImprimerStatCourses'):SetValue('Non');
			end
			matrice.dialog = dlgTexte;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			-- dlgTexte:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgTexte();
			matrice.action = 'close';
		end, 
		btnSaveEdit);
		
	dlgTexte:Bind(eventType.BUTTON, 
		function(evt) 
			local returnPath = "";
			local fileDialog = wnd.CreateFileDialog(dlgTexte,
				"S�lection du fichier image des crit�res de calcul",
				app.GetPath()..app.GetPathSeparator()..'logo', 
				filename,
				"*.jpg, *.gif, *.png|*.jpg;*.gif;*.png", fileDialogStyle.OPEN);
			if fileDialog:ShowModal() == idButton.OK then
				matrice.texteImageStatCourses = string.gsub(fileDialog:GetPath(), '\\', '/');
			else
				matrice.texteImageStatCourses = '';
			end
				dlgTexte:GetWindowName('texteImageStatCourses'):SetValue(matrice.texteImageStatCourses);
		end, 
		dlgTexte:GetWindowName('pathimagestat'));
	dlgTexte:Bind(eventType.COMBOBOX, 
		function(evt) 
			dlgTexte:GetWindowName('texteLigne2Texte'):Enable(dlgTexte:GetWindowName('texteImprimerStatCourses'):GetValue() == 'Oui');
		end, 
		dlgTexte:GetWindowName('texteImprimerStatCourses'));
	tbtexte:Bind(eventType.MENU, function(evt) dlgTexte:EndModal(idButton.CANCEL) end, btnClose);
	dlgTexte:ShowModal();
end

function OnSavedlgAnalyse()
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle Like 'analyseGauche%'";
	base:Query(cmd);
	local etou = nil;
	local valeur = '';
	local ecrire = false;
	local arlignes = {};
	local idxcritere = 0;
	for i = 1, 10 do
		local gfaire = tonumber(dlgAnalyse:GetWindowName('gfaire'..i):GetValue()) or 0;
		local gxpremiers = tonumber(dlgAnalyse:GetWindowName('gxpremiers'..i):GetValue()) or 0;
		local discipline = dlgAnalyse:GetWindowName('discipline'..i):GetValue();
		if i == 1 then
			valeur = gfaire..','..gxpremiers..','..discipline;
		else
			etou = dlgAnalyse:GetWindowName('etou'..i):GetValue();
			if etou:len() == 0 or i == 10 then
				if valeur:len() > 0 then
					idxcritere = idxcritere + 1;
					AddRowEvenement_Matrice('analyseGauche'..idxcritere, valeur);
					matrice['analyseGauche'..idxcritere] = valeur;
					valeur = '';
				end
			elseif etou:In('ET','OU') then
				valeur = valeur..etou..gfaire..','..gxpremiers..','..discipline;
			elseif etou == '+' then
				idxcritere = idxcritere + 1;
				AddRowEvenement_Matrice('analyseGauche'..idxcritere, valeur);
				matrice['analyseGauche'..idxcritere] = valeur;
				valeur = gfaire..','..gxpremiers..','..discipline;
			end
		end
	end
	matrice.analyseGaucheListe = dlgAnalyse:GetWindowName('analyseGaucheListe'):GetValue();
	AddRowEvenement_Matrice('analyseGaucheListe', matrice.analyseGaucheListe);
	matrice.analyseGaucheDiscipline = dlgAnalyse:GetWindowName('analyseGaucheDiscipline'):GetValue();
	AddRowEvenement_Matrice('analyseGaucheDiscipline', matrice.analyseGaucheDiscipline);
	matrice.lignegauche = 0;
	-- AddRowEvenement_Matrice('analyseGaucheClassement', matrice.analyseGaucheClassement);
end

function SetAnalyseGauche(param, etou)
	-- un sous-crit�re peut �tre de la forme :
	-- avant SetAnalyseGauche , matrice['analyseGauche'..1] = 3,5,*, etou = nil	
	-- avant SetAnalyseGauche , matrice['analyseGauche'..2] = 2,10,SLOU2,10,GS, etou = OU	
	-- avant SetAnalyseGauche , matrice['analyseGauche'..3] = 1,20,SLET1,20,GSET1,20,SG, etou = ET	
	if etou then
		local arChaine = param:Split(etou);		-- 2,10,SLOU2,10,GS
		for i = 1, #arChaine do
			adv.Alert('arChaine[i] = '..arChaine[i]);
			matrice.lignegauche = matrice.lignegauche + 1;
			local t = arChaine[i]:Split(',');
			for j = 1, #t do
				dlgAnalyse:GetWindowName('gfaire'..matrice.lignegauche):SetValue(t[1]);
				dlgAnalyse:GetWindowName('gxpremiers'..matrice.lignegauche):SetValue(t[2]);
				dlgAnalyse:GetWindowName('discipline'..matrice.lignegauche):SetValue(t[3]);
			end
			if i > 1 then
				dlgAnalyse:GetWindowName('etou'..matrice.lignegauche):SetValue(etou);
			end
		end
	else
		matrice.lignegauche = matrice.lignegauche + 1;
		local t = param:Split(',');
		dlgAnalyse:GetWindowName('gfaire'..matrice.lignegauche):SetValue(t[1]);
		dlgAnalyse:GetWindowName('gxpremiers'..matrice.lignegauche):SetValue(t[2]);
		dlgAnalyse:GetWindowName('discipline'..matrice.lignegauche):SetValue(t[3]);
		if dlgAnalyse:GetWindowName('etou'..matrice.lignegauche) then
			dlgAnalyse:GetWindowName('etou'..matrice.lignegauche):SetValue('+');
		end
	end
end

function AffichedlgAnalyse()	
	local txt = 'Les points de la liste choisie seront imprim�s pour information. \nEn technique ou vitesse, le choix se fait sur le meilleur classement mondial.';
	dlgAnalyse = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Analyse des performances', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgAnalyse:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'analyse', 			-- Facultatif si le node_name est unique ...
		txt_label = txt,
		params = {Activite = matrice.comboActivite, Saison = matrice.Saison}
	});

	-- Toolbar 
	local tbanalyse = dlgAnalyse:GetWindowName('tbanalyse');
	tbanalyse:AddStretchableSpace();
	local btnSaveEdit = tbanalyse:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbanalyse:AddSeparator();
	local btnRAZ = tbanalyse:AddTool("Tout effacer", "./res/vpe32x32_save.png");
	tbanalyse:AddSeparator();
	local btnClose = tbanalyse:AddTool("Retour", "./res/32x32_exit.png");
	tbanalyse:Bind(eventType.MENU, function(evt) dlgAnalyse:EndModal(idButton.CANCEL) end, btnClose);
	tbanalyse:AddStretchableSpace();

	tbanalyse:Realize();

	dlgAnalyse:GetWindowName('analyseGaucheListe'):SetTable(tListe, 'Code_liste', 'Code_liste');
	dlgAnalyse:GetWindowName('analyseGaucheDiscipline'):Clear();
	if matrice.comboEntite == 'FIS' then
		for row = 0, tDiscipline:GetNbRows() -1 do
			dlgAnalyse:GetWindowName('analyseGaucheDiscipline'):Append(tDiscipline:GetCell('Code', row));
		end
		dlgAnalyse:GetWindowName('analyseGaucheDiscipline'):Append('vitesse');
		dlgAnalyse:GetWindowName('analyseGaucheDiscipline'):Append('technique');
	else
		dlgAnalyse:GetWindowName('analyseGaucheDiscipline'):Append('Toutes disciplines');
	end	

	-- Initialisation des controles et affectation des variables
	dlgAnalyse:GetWindowName('analyseGaucheListe'):SetValue(matrice.analyseGaucheListe);
	dlgAnalyse:GetWindowName('analyseGaucheDiscipline'):SetValue(matrice.analyseGaucheDiscipline);
	-- 1,10,SLET1,10,GS : il faut avoir fait 1 fois dans les 10 en SL et 1 fois dans les 10 en GS, les 2 sous crit�res doivent �tre satisfaits
	-- Ex f = 3,5,* 			-> on remplit la ligne 1
	--    analyseGauche2 = 1,10,SLOU1,10,GS	-> on remplit les lignes 2 et 3	

	for i = 1, 10 do
		if i > 1 then
			dlgAnalyse:GetWindowName('etou'..i):Clear();
			dlgAnalyse:GetWindowName('etou'..i):Append('');
			dlgAnalyse:GetWindowName('etou'..i):Append('+');
			dlgAnalyse:GetWindowName('etou'..i):Append('ET');
			dlgAnalyse:GetWindowName('etou'..i):Append('OU');
		end
		dlgAnalyse:GetWindowName('discipline'..i):Clear();
		for row = 0, tDiscipline:GetNbRows() -1 do
			dlgAnalyse:GetWindowName('discipline'..i):Append(tDiscipline:GetCell('Code', row));
		end
		if matrice.comboEntite == 'FIS' then
			dlgAnalyse:GetWindowName('discipline'..i):Append('Vitesse');
			dlgAnalyse:GetWindowName('discipline'..i):Append('Technique');
		else
			dlgAnalyse:GetWindowName('discipline'..i):Append('*');
		end
	end
	local idxcritere = 1;
	matrice.lignegauche = 0;
	for i = 1, 10 do
		if matrice['analyseGauche'..i] then
			local etou = nil;
			if string.find( matrice['analyseGauche'..i], 'ET') then
				etou = 'ET';
			elseif string.find( matrice['analyseGauche'..i], 'OU') then
				etou = 'OU';
			end
			SetAnalyseGauche(matrice['analyseGauche'..i], etou);
		end
	end
	-- Bind
	tbanalyse:Bind(eventType.MENU, 
			function(evt) 
				matrice.dialog = dlgAnalyse;
				matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
				matrice.action = 'nada';
				dlgAnalyse:Bind(eventType.TIMER, OnTimer, matrice.timer);
				TimerDialogInit();
				OnSavedlgAnalyse();
				matrice.action = 'close';
			end, btnSaveEdit);
	tbanalyse:Bind(eventType.MENU, 
			function(evt) 
				matrice.dialog = dlgAnalyse;
				matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
				matrice.action = 'nada';
				dlgAnalyse:Bind(eventType.TIMER, OnTimer, matrice.timer);
				TimerDialogInit();
				local cmd = 'Delete From Evenement_Matrice Where Code_evenement = '..matrice.code_evenement.." And Cle Like 'analyseGauche%'";
				base:Query(cmd);
				matrice.analyseGaucheDiscipline = nil;
				matrice.analyseGaucheListe = nil;
				for i = 1, 10 do
					matrice['analyseGauche'..i] = nil;
				end
				matrice.action = 'close';
			end, btnRAZ);
	tbanalyse:Bind(eventType.MENU, 
			function(evt) 
				dlgAnalyse:EndModal(idButton.CANCEL)
			end, btnClose);
	dlgAnalyse:ShowModal()
end

function AffichedlgFiltre()	-- bo�te de dialogue pour le filtrage des concurrents.
	dlgFiltre = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Param�trage des impressions', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgFiltre:LoadTemplateXML({ 
		xml = './res/res.xml', 	
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'filter_concurrent',
		params = {Data = matrice.filter_concurrent}
	});

	-- Toolbar 
	local tb = dlgFiltre:GetWindowName('tb');
	tb:AddStretchableSpace();
	local btnSaveEdit = tb:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tb:AddSeparator();
	local btnClose = tb:AddTool("Retour", "./res/32x32_exit.png");
	tb:Bind(eventType.MENU, function(evt) dlgFiltre:EndModal(idButton.CANCEL) end, btnClose);
	tb:AddStretchableSpace();

	tb:Realize();

	-- Initialisation des controles et affectation des variables
	for i = 1, 14 do
		dlgFiltre:GetWindowName('align'..i):Append('left');
		dlgFiltre:GetWindowName('align'..i):Append('center');
		dlgFiltre:GetWindowName('align'..i):Append('right');
	end
				
	tColonnes = matrice.imprimerColonnes:Split('|');
	colonnes = {}
	for i = 1, #tColonnes do
		arConfigColonnes = tColonnes[i]:Split(',');
		colonnes[i] = {Colonne = arConfigColonnes[1], Label = arConfigColonnes[2], Align = arConfigColonnes[3], Imprimer = tonumber(arConfigColonnes[4]) or 0, Afficher = arConfigColonnes[4]}
		if colonnes[i].Imprimer == 0 then
			dlgFiltre:GetWindowName('chk'..i):SetValue(false);
		else
			dlgFiltre:GetWindowName('chk'..i):SetValue(true);
		end
		dlgFiltre:GetWindowName('label'..i):SetValue(colonnes[i].Label);
		dlgFiltre:GetWindowName('align'..i):SetValue(colonnes[i].Align);
		
	end

	-- Bind
	tbconfigcolonnes:Bind(eventType.MENU, 
		function(evt) 
			matrice.dialog = dlgFiltre;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgFiltre:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgFiltre();
			matrice.action = 'close';
		end, btnSaveEdit);

	tbconfigcolonnes:Bind(eventType.MENU, 
		function(evt) 
			dlgFiltre:EndModal(idButton.CANCEL)
		end, btnClose);
	dlgFiltre:ShowModal()
end

function AffichedlgColonne()	-- bo�te de dialogue pour la s�lection des colonnes � imprimer.
	dlgColonne = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Param�trage des impressions', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgColonne:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'configcolonnes', 		-- Facultatif si le node_name est unique ...
		params = {Activite = matrice.comboActivite, Saison = matrice.Saison}
	});

	-- Toolbar 
	local tbconfigcolonnes = dlgColonne:GetWindowName('tbconfigcolonnes');
	tbconfigcolonnes:AddStretchableSpace();
	local btnSaveEdit = tbconfigcolonnes:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbconfigcolonnes:AddSeparator();
	local btnClose = tbconfigcolonnes:AddTool("Retour", "./res/32x32_exit.png");
	tbconfigcolonnes:Bind(eventType.MENU, function(evt) dlgColonne:EndModal(idButton.CANCEL) end, btnClose);
	tbconfigcolonnes:AddStretchableSpace();

	tbconfigcolonnes:Realize();

	-- Initialisation des controles et affectation des variables
	for i = 1, 14 do
		dlgColonne:GetWindowName('align'..i):Append('left   ');
		dlgColonne:GetWindowName('align'..i):Append('   center');
		dlgColonne:GetWindowName('align'..i):Append('      right');
	end
	dlgColonne:GetWindowName('chk12'):Enable(matrice.comboListe1);
	dlgColonne:GetWindowName('comboListe1'):Enable(matrice.comboListe1);
	dlgColonne:GetWindowName('comboListe1Classement'):Enable(matrice.comboListe1);
	dlgColonne:GetWindowName('chk13'):Enable(matrice.comboListe2);
	dlgColonne:GetWindowName('comboListe2'):Enable(matrice.comboListe2);
	dlgColonne:GetWindowName('comboListe2Classement'):Enable(matrice.comboListe2);
	
	dlgColonne:GetWindowName('comboListe1'):SetTable(tListe, 'Code_liste', 'Code_liste, Commentaire');
	dlgColonne:GetWindowName('comboListe2'):SetTable(tListe, 'Code_liste', 'Code_liste, Commentaire');
	dlgColonne:GetWindowName('comboListe1Classement'):SetTable(tType_Classement, 'Code', 'Code');
	dlgColonne:GetWindowName('comboListe2Classement'):SetTable(tType_Classement, 'Code', 'Code');

	dlgColonne:GetWindowName('comboListePrimaute'):Append('au classement');
	dlgColonne:GetWindowName('comboListePrimaute'):Append('aux points');
	dlgColonne:GetWindowName('comboListePrimaute'):SetValue(matrice.comboListePrimaute);
	
	
	tColonnes = matrice.imprimerColonnes:Split('|');
	colonnes = {}
	for i = 1, #tColonnes do
		arConfigColonnes = tColonnes[i]:Split(',');
		colonnes[i] = {Colonne = arConfigColonnes[1], Label = arConfigColonnes[2], Align = arConfigColonnes[3], Imprimer = tonumber(arConfigColonnes[4]) or 0, Afficher = arConfigColonnes[4]}
		if colonnes[i].Imprimer == 0 then
			dlgColonne:GetWindowName('chk'..i):SetValue(false);
		else
			dlgColonne:GetWindowName('chk'..i):SetValue(true);
		end
		dlgColonne:GetWindowName('label'..i):SetValue(colonnes[i].Label);
		dlgColonne:GetWindowName('align'..i):SetValue(colonnes[i].Align);
		
		if i == 2 then
			dlgColonne:GetWindowName('chk2'):SetValue(true);
		end
	end


	-- Bind
	dlgColonne:GetWindowName('comboListePrimaute'):Enable(false);
	tbconfigcolonnes:Bind(eventType.MENU, 
		function(evt) 
			matrice.dialog = dlgColonne;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgColonne:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgColonne();
			matrice.action = 'close';
		end, btnSaveEdit);
	for i =12, 13 do
		if matrice['comboListe'..(i-11)] and matrice['comboListe'..(i-11)..'Classement'] then
			dlgColonne:GetWindowName('comboListe'..(i-11)):SetValue(matrice['comboListe'..(i-11)]);
			dlgColonne:GetWindowName('comboListe'..(i-11)..'Classement'):SetValue(matrice['comboListe'..(i-11)..'Classement']);
			dlgColonne:GetWindowName('chk'..(i-11)):SetValue(true);
			if dlgColonne:GetWindowName('chk12'):GetValue() == true or dlgColonne:GetWindowName('chk13'):GetValue() == true then
				dlgColonne:GetWindowName('comboListePrimaute'):Enable(true);
			end
		end
		
		dlgColonne:Bind(eventType.CHECKBOX, 
			function(evt) 
				if dlgColonne:GetWindowName('chk12'):GetValue() == false and dlgColonne:GetWindowName('chk13'):GetValue() == false then
					dlgColonne:GetWindowName('comboListePrimaute'):Enable(false);
				else
					dlgColonne:GetWindowName('comboListePrimaute'):Enable(true);
				end
			end,
			dlgColonne:GetWindowName('chk'..i));
	end


	tbconfigcolonnes:Bind(eventType.MENU, 
			function(evt) 
				dlgColonne:EndModal(idButton.CANCEL)
			end, btnClose);
	dlgColonne:ShowModal();
end

function AffichedlgColonne2()		-- bo�te de dialogue pour le choix des colonnes � imprimer pour les courses (Tps, Clt etc.)
	dlgColonne2 = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Param�trage des impressions', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgColonne2:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'configcolonnes2' 		-- Facultatif si le node_name est unique ...
	});

	-- Toolbar 
	

	local tbconfigcolonnes2 = dlgColonne2:GetWindowName('tbconfigcolonnes2');
	tbconfigcolonnes2:AddStretchableSpace();
	local btnSaveEdit = tbconfigcolonnes2:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbconfigcolonnes2:AddSeparator();
	local btnLabelRAZ = tbconfigcolonnes2:AddTool("Revenir aux labels par d�faut", "./res/32x32_clear.png");
	tbconfigcolonnes2:AddSeparator();
	local btnClose = tbconfigcolonnes2:AddTool("Retour", "./res/32x32_exit.png");
	tbconfigcolonnes2:AddStretchableSpace();
	tbconfigcolonnes2:Realize();

	matrice.imprimerBloc2 = matrice.imprimerBloc2 or 'Clt,0|Tps,0|Diff,0|Pts,1|Cltrun,0|Tpsrun,0|Diffrun,0|Ptsrun,0|Ptstotal,0';
	if string.find(matrice.imprimerBloc2, 'EtapeClt') then
		matrice.imprimerBloc2 = string.sub(matrice.imprimerBloc2,1, -23)
	end
	colonnes1Course = matrice.imprimerBloc1:Split('|');
	arColonnes1Course = {}
	for i = 1, #colonnes1Course do
		arConfigColonnes1 = colonnes1Course[i]:Split(',');
		if #arConfigColonnes1 < 3 then 
			local label = arConfigColonnes1[1];
			if string.find(label, 'run') then label = 'M'; end
			label = string.gsub(label, 'Ptstotal', 'Total');
			label = string.gsub(label, 'Etape', '');
			table.insert(arConfigColonnes1, label); 
		end
		arColonnes1Course[i] = {Colonne = arConfigColonnes1[1], Align = 'center', Imprimer = tonumber(arConfigColonnes1[2]) or 0, Label = arConfigColonnes1[3]}
		if arColonnes1Course[i].Imprimer == 0 then
			dlgColonne2:GetWindowName('1chk'..i):SetValue(false);
		else
			dlgColonne2:GetWindowName('1chk'..i):SetValue(true);
		end
		dlgColonne2:GetWindowName('1label'..i):SetValue(arConfigColonnes1[3]);
	end
	colonnes2Course = matrice.imprimerBloc2:Split('|');
	arColonnes2Course = {}
	for i = 1, #colonnes2Course do
		arConfigColonnes2 = colonnes2Course[i]:Split(',');
		arColonnes2Course[i] = {Colonne = arConfigColonnes2[1], Align = 'center', Imprimer = tonumber(arConfigColonnes2[2]) or 0}
		if arColonnes2Course[i].Imprimer == 0 then
			dlgColonne2:GetWindowName('2chk'..i):SetValue(false);
		else
			dlgColonne2:GetWindowName('2chk'..i):SetValue(true);
		end
		dlgColonne2:GetWindowName('2chk'..i):Enable(matrice.bloc2 == true);
	end
	tColonnes3 = matrice.imprimerCombiSaut:Split('|');
	colonnes3 = {}
	for i = 1, #tColonnes3 do
		tConfigColonnes3 = tColonnes3[i]:Split(',');
		colonnes3[i] = {Colonne = tConfigColonnes3[1], Align = 'center', Imprimer = tonumber(tConfigColonnes3[2]) or 0}
		if colonnes3[i].Imprimer == 0 then
			dlgColonne2:GetWindowName('3chk'..i):SetValue(false);
		else
			dlgColonne2:GetWindowName('3chk'..i):SetValue(true);
		end
		dlgColonne2:GetWindowName('3chk'..i):Enable(matrice.combisaut == true);
	end
	dlgColonne2:GetWindowName('numPenalisationSaut'):SetValue(matrice.numPenalisationSaut);
	dlgColonne2:GetWindowName('numPenalisationSaut'):Enable(matrice.combisaut)

	-- Bind
	tbconfigcolonnes2:Bind(eventType.MENU, 
		function(evt) 
			matrice.dialog = dlgColonne2;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgColonne2:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgColonne2();
			matrice.action = 'close';
		end, 
		btnSaveEdit);
	tbconfigcolonnes2:Bind(eventType.MENU, 
		function(evt) 
			local arlabel1 = {'Clt','Tps','Diff','Pts','Clt','Tps','Diff','M.','Total','Clt','Pts'};
			for i = 1, #arlabel1 do
				dlgColonne2:GetWindowName('1label'..i):SetValue(arlabel1[i]);
			end
		end, 
		btnLabelRAZ);
	tbconfigcolonnes2:Bind(eventType.MENU, 
		function(evt) dlgColonne2:EndModal(idButton.CANCEL) 
	end, btnClose);
	dlgColonne2:ShowModal();
end

function OnChangeColonne(colonne)
	if colonne:len() == 0 then
		for i = 1, 20 do
			dlgColonne3:GetWindowName('val'..i):SetValue('');
			dlgColonne3:GetWindowName('align'..i):SetValue('');
			dlgColonne3:GetWindowName('align'..i):Enable(false);
		end
		return;
	end
	local cmd = 'Select '..colonne..' From Resultat Where Code_evenement in ('..matrice.Evenement_selection..') And Not '..colonne..' = "" Group By '..colonne..' Limit 20 ';
	tColonne = base:TableLoad(cmd);
	ReplaceTableEnvironnement(tColonne, '_Colonne');
	local label = colonne..'_align';	-- Ex : An_align : 2003,left|2004,right 
	local talign = {};
	if matrice[label] then								-- Ex matrice[label] = 2003,left|2004,right
		local tvaleurs = matrice[label]:Split('|');		-- tvaleurs[1] = 2003,left, tvaleurs[2] = 2004,right
		for i = 1, #tvaleurs do
			local tval = tvaleurs[i]:Split(',');
			talign[tval[1]] = tval[2]
		end
	end
	local indexcol = tColonne:GetIndexColumn(colonne);
	local colname = tColonne:GetColumnName(indexcol);
	for i = 1, 20 do
		valeur = tColonne:GetCell(colname, i-1);
		if valeur:len() > 0 then
			dlgColonne3:GetWindowName('val'..i):SetValue(valeur);
			dlgColonne3:GetWindowName('align'..i):Enable(true);
			if tColonne:GetCell(colonne, i-1):len() > 0 then
				if talign[valeur] then
					if talign[valeur] == 'left' then
						dlgColonne3:GetWindowName('align'..i):SetSelection(0);
					elseif talign[valeur] == 'right' then
						dlgColonne3:GetWindowName('align'..i):SetSelection(2);
					else
						dlgColonne3:GetWindowName('align'..i):SetSelection(1);
					end
				else
					dlgColonne3:GetWindowName('align'..i):SetSelection(1);
				end
				dlgColonne3:GetWindowName('align'..i):Enable(true);
			else
				dlgColonne3:GetWindowName('align'..i):SetValue('');
				dlgColonne3:GetWindowName('align'..i):Enable(false);
			end
		else
			dlgColonne3:GetWindowName('val'..i):SetValue('');
			dlgColonne3:GetWindowName('align'..i):SetValue('');
			dlgColonne3:GetWindowName('align'..i):Enable(false);
		end
	end
end

function AffichedlgColonne3()		-- bo�te de dialogue pour les alignements sp�cifiques
	dlgColonne3 = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Param�trage des alignements sp�cifiques', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgColonne3:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'configcolonnes3' 		-- Facultatif si le node_name est unique ...
	});

	-- Toolbar 
	local tbconfigcolonnes3 = dlgColonne3:GetWindowName('tbconfigcolonnes3');
	tbconfigcolonnes3:AddStretchableSpace();
	local btnSaveEdit = tbconfigcolonnes3:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbconfigcolonnes3:AddSeparator();
	local btnRAZ = tbconfigcolonnes3:AddTool("Effacer", "./res/32x32_clear.png");
	tbconfigcolonnes3:AddSeparator();
	local btnClose = tbconfigcolonnes3:AddTool("Retour", "./res/32x32_exit.png");
	tbconfigcolonnes3:AddStretchableSpace();

	tbconfigcolonnes3:Realize();

	-- Initialisation des controles et affectation des variables
	dlgColonne3:GetWindowName('colonne'):Clear();
	dlgColonne3:GetWindowName('colonne'):Append('');
	dlgColonne3:GetWindowName('colonne'):Append('Sexe');
	dlgColonne3:GetWindowName('colonne'):Append('Nation');
	dlgColonne3:GetWindowName('colonne'):Append('Comite');
	dlgColonne3:GetWindowName('colonne'):Append('An');
	dlgColonne3:GetWindowName('colonne'):Append('Categ');
	for i = 1, 20 do
		dlgColonne3:GetWindowName('align'..i):Append('� gauche');
		dlgColonne3:GetWindowName('align'..i):Append('	au centre');
		dlgColonne3:GetWindowName('align'..i):Append('		� droite');
		dlgColonne3:GetWindowName('align'..i):Enable(false);
	end
	

	-- Bind
	dlgColonne3:Bind(eventType.COMBOBOX, 
			function(evt)
				OnChangeColonne(dlgColonne3:GetWindowName('colonne'):GetValue());
			end, dlgColonne3:GetWindowName('colonne'));
	tbconfigcolonnes3:Bind(eventType.MENU, 
		function(evt) 
			matrice.dialog = dlgColonne3;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgColonne3:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgColonne3(dlgColonne3:GetWindowName('colonne'):GetValue(), false);
			matrice.action = 'close';
		end, 
		btnSaveEdit);
	tbconfigcolonnes3:Bind(eventType.MENU, 
		function(evt) 
			matrice.dialog = dlgColonne3;
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgColonne3:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgColonne3(dlgColonne3:GetWindowName('colonne'):GetValue(), true);
			matrice.action = 'close';
		end, 
		btnRAZ);
	tbconfigcolonnes3:Bind(eventType.MENU, 
		function(evt) dlgColonne3:EndModal(idButton.CANCEL) 
	end, btnClose);
	dlgColonne3:ShowModal();
end

function BuildTableRanking(indice_filtrage)
	matrice.TitrePrn = matrice.Titre;
	matrice.TitreAdd = nil;
	indice_filtrage = indice_filtrage or 0;
	if not matrice.cle_filtrage then
		matrice.cle_filtrage = "$(Sexe):In('"..matrice.comboSexe.."')";
	end
	matrice.typeBuild = 1;
	matrice.prendre_manche = matrice.prendre_manche or false;
	for bloc = 1, 2 do
		if bloc == 2 and not matrice.Bloc2 then
			break;
		end
		local arImprimerBloc = matrice['imprimerBloc'..bloc]:Split('|');
		if matrice.prendre_manche == true then
			break;
		end
		for i = 1, #arImprimerBloc do
			local arcol = arImprimerBloc[i]:Split(',')
			for j = 1, #arcol do
				local col = arcol[1];
				local imprimer = tonumber(arcol[2]) or 0;
				if string.find(col, 'run') and imprimer == 1 then
					matrice.prendre_manche = true;
					break;
				end
			end
		end
	end
	local cmd = '';
	if matrice.comboResultatPar == 'Sans objet' then
		cmd = 'Select Code_coureur, Sexe From Resultat Where Code_evenement in('..matrice.Evenement_selection..') Group By Code_coureur, Sexe';
	else
		cmd = 'Select Code_coureur, Sexe, Categ, Groupe From Resultat Where Code_evenement in('..matrice.Evenement_selection..') Group By Code_coureur, Sexe, Categ, Groupe';
	end
	tMatrice_Ranking = base:TableLoad(cmd);
	tMatrice_Ranking:OrderBy('Code_coureur');
	local filter = "$(Sexe):In('"..matrice.comboSexe.."')";
	tMatrice_Ranking:Filter(filter, true);
	local sexe = ' Hommes';
	if matrice.Sexe == 'F' then
		sexe = ' Dames';
	end
	if indice_filtrage > 0 then
		local col_resultat_par = matrice.tGroupesCalcul[indice_filtrage].ColGroupe; 
		local filter = "$("..col_resultat_par.."):In('"..matrice.tGroupesCalcul[indice_filtrage].Groupe.."')";
		tMatrice_Ranking:Filter(filter, true);
		matrice.TitreAdd = '\nClassement '..matrice.tGroupesCalcul[indice_filtrage].Groupe..sexe;
	end
	ReplaceTableEnvironnement(tMatrice_Ranking, '_tMatrice_Ranking');
	if matrice.comboEntite == 'FIS' then
		tMatrice_Ranking:AddColumn({ name = 'Code_FFS', label = 'Code_FFS', type = sqlType.CHAR, width = '15', style = sqlStyle.NULL});
	end
 	tMatrice_Ranking:AddColumn({ name = 'Clt', label = 'Clt', type = sqlType.LONG, style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Dossard', label = 'Dossard', type = sqlType.LONG, style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Rang', label = 'Rang', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Nom', label = 'Nom', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Prenom', label = 'Prenom', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Identite', label = 'Identite', type = sqlType.CHAR, width = '61', style = sqlStyle.NULL});
	local colindex = tMatrice_Ranking:GetIndexColumn('Sexe');
	if colindex < 0 then
		tMatrice_Ranking:AddColumn({ name = 'Sexe', label = 'Sexe', type = sqlType.CHAR, width = '1', style = sqlStyle.NULL});
      end
	tMatrice_Ranking:AddColumn({ name = 'An', label = 'An', type = sqlType.LONG, style = sqlStyle.NULL});
	colindex = tMatrice_Ranking:GetIndexColumn('Categ');
	if colindex < 0 then
		tMatrice_Ranking:AddColumn({ name = 'Categ', label = 'Categ', type = sqlType.CHAR, width = '8', style = sqlStyle.NULL});
      end
	tMatrice_Ranking:AddColumn({ name = 'Nation', label = 'Nation', type = sqlType.CHAR, width = '3', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Comite', label = 'Comite', type = sqlType.CHAR, width = '3', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Club', label = 'Club', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Club_long', label = 'Club', type = sqlType.CHAR, width = '75', style = sqlStyle.NULL});
	colindex = tMatrice_Ranking:GetIndexColumn('Groupe');
	if colindex < 0 then
		tMatrice_Ranking:AddColumn({ name = 'Groupe', label = 'Groupe', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
      end
	tMatrice_Ranking:AddColumn({ name = 'Equipe', label = 'Equipe', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Critere', label = 'Critere', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Point', label = 'Point', type = sqlType.DOUBLE, style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Pts', label = 'Pts', type = sqlType.DOUBLE, style = sqlStyle.NULL});

	tMatrice_Ranking:AddColumn({ name = 'Clt_FFS', label = 'Clt_FFS', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_FFS', label = 'Pts_FFS', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_SL', label = 'Clt_SL', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_SL', label = 'Pts_SL', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_GS', label = 'Clt_GS', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_GS', label = 'Pts_GS', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_SG', label = 'Clt_SG', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_SG', label = 'Pts_SG', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_DH', label = 'Clt_DH', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_DH', label = 'Pts_DH', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_vitesse', label = 'Clt_vitesse', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_vitesse', label = 'Pts_vitesse', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_technique', label = 'Clt_technique', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_technique', label = 'Pts_technique', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_liste1', label = 'Clt_liste1', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_liste1', label = 'Pts_liste1', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_liste2', label = 'Clt_liste2', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_liste2', label = 'Pts_liste2', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Delta', label = 'Delta', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_inscription', label = 'Clt_inscription', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_inscription', label = 'Pts_inscription', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_last_discipline', label = 'Clt_last_discipline', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_last_discipline', label = 'Pts_last_discipline', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Clt_bloc1', label = 'Clt_bloc1', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Pts_bloc1', label = 'Pts_bloc1', type = sqlType.DOUBLE, style = sqlStyle.NULL});

	for row = 0, tMatrice_Courses:GetNbRows() -1 do
		local idxcourse = row + 1;
		local discipline = tMatrice_Courses:GetCell('Code_discipline', row);
		tMatrice_Ranking:AddColumn({ name = 'Code_evenement'..idxcourse, label = 'Code_evenement'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Course_prise'..idxcourse, label = 'Course_prise'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Manche_prise'..idxcourse, label = 'Manche_prise'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Selection'..idxcourse, label = 'Selection'..idxcourse, type = sqlType.CHAR, width = '100', style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Clt'..idxcourse, label = 'Clt'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse, label = 'Tps'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse..'_diff', label = 'Tps'..idxcourse..'_diff', type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse, label = 'Pts'..idxcourse, type = sqlType.DOUBLE, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Run'..idxcourse..'_best', label = 'Run'..idxcourse..'_best', type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Clt'..idxcourse..'_best', label = 'Clt'..idxcourse..'_best', type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse..'_best', label = 'Pts'..idxcourse..'_best', type = sqlType.DOUBLE, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse..'_total', label = 'Pts'..idxcourse..'_total', type = sqlType.DOUBLE, style = sqlStyle.NULL});
		for idxrun = 1, tMatrice_Courses:GetCellInt('Nombre_de_manche', row) do
			if discipline == 'CS' and idxrun == 1 then		-- manche de saut
				tMatrice_Ranking:AddColumn({ name = 'Lng'..idxcourse..'_saut', label = 'Lng'..idxcourse..'_saut', type = sqlType.CHAR, width = '10', style = sqlStyle.NULL});
				tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse..'_saut'..idxrun, label = 'Pts'..idxcourse..'_saut', type = sqlType.DOUBLE, style = sqlStyle.NULL});
			end
			tMatrice_Ranking:AddColumn({ name = 'Clt'..idxcourse..'_run'..idxrun, label = 'Clt'..idxcourse..'_run'..idxrun, type = sqlType.LONG, style = sqlStyle.NULL});
			tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse..'_run'..idxrun, label = 'Tps'..idxcourse..'_run'..idxrun, type = sqlType.LONG, style = sqlStyle.NULL});
			tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse..'_run'..idxrun..'_diff', label = 'Tps'..idxcourse..'_run'..idxrun..'_diff', type = sqlType.LONG, style = sqlStyle.NULL});
			tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse..'_run'..idxrun, label = 'Pts'..idxcourse..'_run'..idxrun, type = sqlType.DOUBLE, style = sqlStyle.NULL});
		end
	end
	tMatrice_Ranking:AddColumn({ name = 'Analyse1', label = 'Analyse1', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Analyse2', label = 'Analyse2', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Analyse3', label = 'Analyse3', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Analyse4', label = 'Analyse4', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Analyse5', label = 'Analyse5', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Analyse_groupe', label = 'Analyse_groupe', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Nb_depart', label = 'Nb_depart', type = sqlType.LONG, style = sqlStyle.NULL});

	for i = 0, tMatrice_Ranking:GetNbColumns() -1 do
		if string.find(tMatrice_Ranking:GetColumnName(i), 'Clt') then
			tMatrice_Ranking:ChangeColumn(tMatrice_Ranking:GetColumnName(i), 'ranking');
		end
		if string.find(tMatrice_Ranking:GetColumnName(i), 'Tps') then
			tMatrice_Ranking:ChangeColumn(tMatrice_Ranking:GetColumnName(i), 'chrono');
		end
	end
	if matrice.texteImprimerClubLong == 'Oui' then
		local cmd = 'Select * From Club';
		base:TableLoad(tClub, cmd);
	end
	matrice.ajouter = {};
	for row_course = 0, tMatrice_Courses:GetNbRows() -1 do
		arResultat_Manchex = {};
		local nombre_de_manche = tMatrice_Courses:GetCellInt('Nombre_de_manche', row_course);
		local idxcourse = row_course + 1;
		local discipline = tMatrice_Courses:GetCell('Code_discipline', row_course)
		local code_evenement = tMatrice_Courses:GetCellInt('Code', row_course);
		local cmd = 'Select * From Resultat Where Code_evenement = '..code_evenement..' Order By Code_coureur';
		base:TableLoad(tResultat, cmd);
		if indice_filtrage == 0 and matrice.Cle_filtrage then
			tResultat:Filter(matrice.Cle_filtrage, true);
		end
		for row = 0, tMatrice_Ranking:GetNbRows() -1 do
			tMatrice_Ranking:SetCell('Code_evenement'..idxcourse, row, code_evenement)
			local coltps = 'Tps'..idxcourse;
			local code_coureur = tMatrice_Ranking:GetCell('Code_coureur', row);
			if matrice.comboEntite == 'FIS' and row_course == 0 then
				base:TableLoad(tCorrespondance, "Select * From Correspondance Where Code1 = '"..code_coureur.."'");
				if tCorrespondance:GetNbRows() > 0 then
					tMatrice_Ranking:SetCell('Code_FFS', row, tCorrespondance:GetCell('Code2', 0));
				end
			end
			local tps = -1;
			local identite = nil;
			local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
			if r and r >= 0 then
				tps = tResultat:GetCellInt('Tps', r, -1);
				tMatrice_Ranking:SetCell(coltps, row, tps);
				local nom = tMatrice_Ranking:GetCell('Nom', row);
				if nom:len() == 0 then
					tMatrice_Ranking:SetCell('Nom', row, tResultat:GetCell('Nom', r));
					tMatrice_Ranking:SetCell('Prenom', row, tResultat:GetCell('Prenom', r));
					tMatrice_Ranking:SetCell('Identite', row, tResultat:GetCell('Nom', r)..' '..tResultat:GetCell('Prenom', r));
					tMatrice_Ranking:SetCell('Sexe', row, tResultat:GetCell('Sexe', r));
					tMatrice_Ranking:SetCell('An', row, tResultat:GetCellInt('An', r));
					tMatrice_Ranking:SetCell('Categ', row, tResultat:GetCell('Categ', r));
					tMatrice_Ranking:SetCell('Nation', row, tResultat:GetCell('Nation', r));
					tMatrice_Ranking:SetCell('Comite', row, tResultat:GetCell('Comite', r));
					tMatrice_Ranking:SetCell('Club', row, tResultat:GetCell('Club', r));
				end
				local club = tMatrice_Ranking:GetCell('Club', row);
				if matrice.texteImprimerClubLong == 'Oui' and club:len() > 0 then
					local s = tClub:GetIndexRow('Nom_reduit', club);
					if s and s >= 0 then
						tMatrice_Ranking:SetCell('Club_long', row, tClub:GetCell('Nom_complet', s));
					else
						tMatrice_Ranking:SetCell('Club_long', row, club);
					end
				end
				if row_course == tMatrice_Courses:GetNbRows() -1 then
					tMatrice_Ranking:SetCell('Groupe', row, tResultat:GetCell('Groupe', r));
					tMatrice_Ranking:SetCell('Equipe', row, tResultat:GetCell('Equipe', r));
					tMatrice_Ranking:SetCell('Critere', row, tResultat:GetCell('Critere', r));
					tMatrice_Ranking:SetCell('Dossard', row, tResultat:GetCellInt('Dossard', r));
					tMatrice_Ranking:SetCell('Point', row, tResultat:GetCellDouble('Point', r));
				end
			end
		end
		for idxrun = 1, nombre_de_manche do
			local coltpsrun = 'Tps'..idxcourse..'_run'..idxrun;
			local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..code_evenement..' And Code_manche = '..idxrun; 
			base:TableLoad(tResultat_Manche, cmd)
			local rm = -1;
			for row = 0, tMatrice_Ranking:GetNbRows() -1 do
				local code_coureur = tMatrice_Ranking:GetCell('Code_coureur', row);
				local tpsm = -1;
				rm = tResultat_Manche:GetIndexRow('Code_coureur', code_coureur);
				if rm and rm >= 0 then
					tpsm = tResultat_Manche:GetCellInt('Tps_chrono', rm);
				end
				tMatrice_Ranking:SetCell(coltpsrun, row, tpsm);
				if idxrun == 1 and discipline == 'CS' then
					local collng = 'Lng'..idxcourse..'saut';
					local lng = tpsm / 1000;
					if tpsm > 0 then
						tMatrice_Ranking:SetCell(collng, row, tpsm / 1000);
						tMatrice_Ranking:SetCell(collng, row, tpsm / 1000);
					else
						tMatrice_Ranking:SetCell(collng, row, 0);
					end
				end
			end
		end
	end
	if matrice.debug == true then
		adv.Alert("Apr�s BuildTableRanking Snapshot('tMatrice_Ranking_apres_build.db3')");
		tMatrice_Ranking:Snapshot('tMatrice_Ranking_apres_build.db3');
	end
end

function BtnPrint()
	matrice.next = false;
	matrice.findescalculs = false;
	matrice.panel_name = 'print';
	LitMatrice();
	LitMatriceCourses(true);
	matrice.findescalculs = false;
	matrice.panel_name = 'print';
	if matrice.comboResultatPar == 'Sans objet' then
		Calculer('print', 0);
		if not matrice.findescalculs == true then
			dlgConfig:MessageBox(
				"Une erreur est intervenue durant les calculs !!!",
				"Calcul de la matrice "..matrice.Titre, 
				msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
				);
			return;
		end
		OnPrint();
	else
		for i = 1, #matrice.tResultatsGroupes do
			if i > 1 then
				matrice.next = true;
			end
			Calculer('print', i);
			if not matrice.findescalculs == true then
				dlgConfig:MessageBox(
					"Une erreur est intervenue durant les calculs !!!",
					"Calcul de la matrice "..matrice.Titre, 
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
					);
				return;
			end
			OnPrint();
		end
	end
end

function AffichedlgConfiguration()
	-- Creation de la bo�te de dialogue principale
	dlgConfig = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Configuration des param�tres'..matrice.label_matrice, 
		icon='./res/32x32_ffs.png'
		});

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgConfig:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'matriceconfig' 		-- Facultatif si le node_name est unique ...
	});
	matrice.timer = timer.Create(dlgConfig);
	dlgConfig:Bind(eventType.TIMER, OnTimer, matrice.timer);
	-- remplissage des Combo
	dlgConfig:GetWindowName('comboEntite'):SetTable(tEntite, 'Code', 'Code,Libelle');
	dlgConfig:GetWindowName('comboActivite'):SetTable(tActivite, 'Code', 'Code, Libelle');
	dlgConfig:GetWindowName('Saison'):SetTable(tSaison, 'Code', 'Code, Libelle');
	
	dlgConfig:GetWindowName('comboGarderInfQuota'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgConfig:GetWindowName('comboSexe'):Append("F");
	dlgConfig:GetWindowName('comboSexe'):Append("M");
	dlgConfig:GetWindowName('comboTypePoint'):Append("Points place");
	dlgConfig:GetWindowName('comboTypePoint'):Append("Points course");
	dlgConfig:GetWindowName('comboAbdDsq'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgConfig:GetWindowName('comboTpsDuDernier'):SetTable(tOuiNon, 'Choix', 'Choix');
	
	-- dlgConfig:GetWindowName('comboResultatPar'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgConfig:GetWindowName('comboResultatPar'):SetTable(tResultatPar, 'Choix', 'Choix');
	dlgConfig:GetWindowName('comboTriSortie'):Append("Classement");
	dlgConfig:GetWindowName('comboTriSortie'):Append("Ann�e et classement");
	dlgConfig:GetWindowName('comboTriSortie'):Append("Cat�gorie et classement");
	dlgConfig:GetWindowName('comboTriSortie'):Append("Comit� et classement");
	dlgConfig:GetWindowName('comboTriSortie'):Append("Club et classement");
	dlgConfig:GetWindowName('comboTriSortie'):Append("Nation et classement");
	dlgConfig:GetWindowName('comboTriSortie'):Append("Groupe et classement");
	dlgConfig:GetWindowName('comboTriSortie'):Append("Equipe et classement");
	dlgConfig:GetWindowName('comboTriSortie'):Append("Crit�re et classement");
	dlgConfig:GetWindowName('comboPresentationCourses'):Append("Pr�sentation verticale sur fond opaque");
	dlgConfig:GetWindowName('comboPresentationCourses'):Append("Pr�sentation horizontale type Ski Chrono Tour (par d�faut)");
	dlgConfig:GetWindowName('comboPresentationCourses'):Append("Pr�sentation verticale sur fond transparent");
	dlgConfig:GetWindowName('comboOrientation'):Append("Portrait");
	dlgConfig:GetWindowName('comboOrientation'):Append("Paysage");
	dlgConfig:GetWindowName('comboPrendreBloc1'):Append("1.Classement g�n�ral");
	dlgConfig:GetWindowName('comboPrendreBloc1'):Append("2.Classement � la manche");
	dlgConfig:GetWindowName('comboPrendreBloc1'):Append("3.Idem plus le classement g�n�ral");
	dlgConfig:GetWindowName('comboPrendreBloc2'):Append("1.Classement g�n�ral");
	dlgConfig:GetWindowName('comboPrendreBloc2'):Append("2.Classement � la manche");
	dlgConfig:GetWindowName('comboPrendreBloc2'):Append("3.Idem plus le classement g�n�ral");
	

	-- Toolbar 
	local tbedit1 = dlgConfig:GetWindowName('tbedit1');
	tbedit1:AddStretchableSpace();
	local btnSaveEdit = tbedit1:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbedit1:AddSeparator();
	local btnTxtLogo = tbedit1:AddTool("Compl�ments", "./res/32x32_layer.png");
	tbedit1:AddSeparator();
	local btnParam = tbedit1:AddTool("Param�tres", "./res/32x32_tools.png", "Param�trages", itemKind.DROPDOWN);
	local menuParams = menu.Create();
	local btnCouleurs = menuParams:Append({label="Couleurs des disciplines", image ="./res/32x32_color.png"});
	menuParams:AppendSeparator();
	local btnCouleurPodium = menuParams:Append({label="Couleurs du Podium", image ="./res/32x32_color.png"});
	menuParams:AppendSeparator();
	local btnParamAnalyse = menuParams:Append({label="de l'analyse des performances.", image ="./res/32x32_ranking.png"});
	tbedit1:SetDropdownMenu(btnParam:GetId(), menuParams);
	tbedit1:AddSeparator();
	local btnColonnes = tbedit1:AddTool("Param. des colonnes", "./res/32x32_divide_row.png", 'Choix des colonnes', itemKind.DROPDOWN);
	local menuColonnes = menu.Create();
	menuColonnes:AppendSeparator();
	local btnColonnes1 = menuColonnes:Append({label="Colonnes principale � imprimer", image ="./res/32x32_param.png"});
	menuColonnes:AppendSeparator();
	local btnColonnes2 = menuColonnes:Append({label="Choix des colonnes des courses", image ="./res/32x32_param.png"});
	menuColonnes:AppendSeparator();
	local btnColonnes3 = menuColonnes:Append({label="Alignements sp�ciaux", image ="./res/32x32_param.png"});
	tbedit1:SetDropdownMenu(btnColonnes:GetId(), menuColonnes);
	tbedit1:AddSeparator();
	local btnOutils = tbedit1:AddTool("Outils", "./res/32x32_tools.png", "Coureurs pouvant figurer dans la matrice", itemKind.DROPDOWN);
	local menuOutils = menu.Create();
	local btnOutils1 = menuOutils:Append({label="Inclusion / Exclusion des coureurs", image ="./res/32x32_config.png"});
	menuOutils:AppendSeparator();
	local btnOutils2 = menuOutils:Append({label="Effacer / remplir des colonnes", image ="./res/32x32_config.png"});
	menuOutils:AppendSeparator();
	local btnOutils3 = menuOutils:Append({label="Rechercher un script LUA", image ="./res/32x32_param.png"});
	menuOutils:AppendSeparator();
	local btnOutils4 = menuOutils:Append({label='Cr�er une nouvelle course', image ="./res/32x32_journal.png"});
	tbedit1:SetDropdownMenu(btnOutils:GetId(), menuOutils);
	tbedit1:AddSeparator();
	local btnFiltrage = tbedit1:AddTool("Filtres", "./res/32x32_tools.png", "Filtres � appliquer", itemKind.DROPDOWN);
	local menuFiltres = menu.Create();
	local btnFiltres = menuFiltres:Append({label="Filtrage des coureurs", image ="./res/32x32_config.png"});
	menuFiltres:AppendSeparator();
	local btnFiltreParPoint = menuFiltres:Append({label="Filtrage des coureurs par points", image ="./res/32x32_config.png"});
	menuFiltres:AppendSeparator();
	local btnFiltreRegroupement = menuFiltres:Append({label="Regroupement des courses", image ="./res/32x32_config.png"});
	tbedit1:SetDropdownMenu(btnFiltrage:GetId(), menuFiltres);
	tbedit1:AddSeparator();
	local btnVisuCourses = tbedit1:AddTool("Visu Courses", "./res/32x32_pencil.png");
	tbedit1:AddSeparator();
	local btn_parametrage = tbedit1:AddTool("Param. des calculs", "./res/32x32_config.png", "Param�trage des calculs", itemKind.DROPDOWN);
	local menuCritere =  menu.Create();
	local btnCritere1 = menuCritere:Append({label="Crit�res simples de calcul par disciplines", image ="./res/32x32_config.png"});
	menuCritere:AppendSeparator();
	local btnCritere2 = menuCritere:Append({label="Crit�res de calcul par disciplines et par blocs", image ="./res/32x32_param.png"});
	menuCritere:AppendSeparator();
	local btnCritere4 = menuCritere:Append({label="Crit�res de calcul par disciplines, par courses et par manches ind�pendantes des blocs", image ="./res/32x32_configuration.png"});
	menuCritere:AppendSeparator();
	local btnRAZCritere = menuCritere:Append({label="Effacer tous les crit�res de calcul", image ="./res/32x32_configuration.png"});
	tbedit1:SetDropdownMenu(btn_parametrage:GetId(), menuCritere);
	local btnPrint = tbedit1:AddTool("Calculer", "./res/32x32_ranking.png", "Calculer", itemKind.DROPDOWN);
	menuPrint =  menu.Create();
	local btnCalculer = menuPrint:Append({label="Calculer", image="./res/32x32_ranking.png"});
	menuPrint:AppendSeparator();
	btnAnalyse = menuPrint:Append({label="Analyse des performances", image ="./res/32x32_ranking.png"});
	tbedit1:SetDropdownMenu(btnPrint:GetId(), menuPrint);
	tbedit1:AddSeparator();
	local btnRetour = tbedit1:AddTool("Sortie", "./res/32x32_exit.png");
	tbedit1:AddSeparator();
	local btnVersion = tbedit1:AddTool("Versions", "./res/vpe32x32_help.png", "Versions", itemKind.DROPDOWN);
	local menuHelp =  menu.Create();
	local btnHelp = menuHelp:Append({label="Aide", image ="./res/32x32_sos.png"});
	tbedit1:SetDropdownMenu(btnVersion:GetId(), menuHelp);
	tbedit1:AddStretchableSpace();
	tbedit1:Realize();
	
	-- local tbedit1 = dlgConfig:GetWindowName('tbedit1');
	-- menuFiltres:Enable(btnFiltreParPoint:GetId(), false) ;


	-- Bind
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
	tbedit1:Bind(eventType.MENU, 
		function(evt) 
			if base ~= nil then
				base:Delete();
				base = nil;
			end
			matrice.findescalculs = false;
			dlgConfig:EndModal(idButton.CANCEL) 
		end, btnRetour);
	tbedit1:Bind(eventType.MENU, 
		function(evt)
			matrice.dialog = 'dlgConfig';
			matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
			matrice.action = 'nada';
			dlgConfig:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSavedlgConfiguration();
		end, btnSaveEdit);
	tbedit1:Bind(eventType.MENU, AffichedlgAnalyse, btnParam);
	tbedit1:Bind(eventType.MENU, AffichedlgAnalyse, btnParamAnalyse);
	tbedit1:Bind(eventType.MENU, AffichedlgTexte, btnTxtLogo);
	tbedit1:Bind(eventType.MENU, AffichedlgConfigurationSupport, btnOutils);
	tbedit1:Bind(eventType.MENU, AffichedlgConfigurationSupport, btnOutils1);
	tbedit1:Bind(eventType.MENU, AffichedlgCopycolonnes, btnOutils2);
	tbedit1:Bind(eventType.MENU, AffichedlgScriptLua, btnOutils3);
	tbedit1:Bind(eventType.MENU, AffichedlgInscription, btnOutils4);
	
	tbedit1:Bind(eventType.MENU, AffichedlgRegroupement, btnFiltreRegroupement);
	tbedit1:Bind(eventType.MENU, AffichedlgVisuFiltrexPoints, btnFiltreParPoint);
	tbedit1:Bind(eventType.MENU, AffichedlgColonne, btnColonnes);
	tbedit1:Bind(eventType.MENU, AffichedlgColonne, btnColonnes1);
	tbedit1:Bind(eventType.MENU, AffichedlgColonne2, btnColonnes2);
	tbedit1:Bind(eventType.MENU, AffichedlgColonne3, btnColonnes3);
	tbedit1:Bind(eventType.MENU, AffichedlgParamColor, btnCouleurs);
	tbedit1:Bind(eventType.MENU, AffichedlgParamColorPodium, btnCouleurPodium);
	tbedit1:Bind(eventType.MENU, AffichedlgCritere1, btnCritere1);
	tbedit1:Bind(eventType.MENU, AffichedlgCritere2, btnCritere2);
	tbedit1:Bind(eventType.MENU, AffichedlgCritere4, btnCritere4);
	tbedit1:Bind(eventType.MENU, 
		function(evt) 
			matrice.numTypeCritere = matrice.numTypeCritere or 0;
			if matrice.numTypeCritere < 2 then
				AffichedlgCritere1();
			elseif matrice.numTypeCritere < 4 then
				AffichedlgCritere2();
			else
				AffichedlgCritere4();
			end
		end
		, btn_parametrage);
	tbedit1:Bind(eventType.MENU, 
		function(evt)
			local cmd = 'Delete From Evenement_Matrice Where Code_evenement = '..matrice.code_evenement.." And Cle Like '%critere%'";
			base:Query(cmd);
		end
		, btnRAZCritere);
	tbedit1:Bind(eventType.MENU, 
		function(evt)
			if not matrice.Evenement_selection or matrice.Evenement_selection:len() == 0 then
				dlgConfig:MessageBox(
					"Il n'y a rien � filtrer, la matrice ne contient aucune course.",
					"Merci de saisir une course", 
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
					) ;
				return
			end
			local cmd = 'Select * From Resultat Where Code_evenement In(-1,'..matrice.Evenement_selection..") And Sexe = '"..matrice.comboSexe.."'";
			base:TableLoad(tResultat, cmd);
			if tResultat:GetNbRows() > 0 then
				local filterCmd = wnd.FilterConcurrentDialog({ 
					sqlTable = tResultat,
					key = 'cmd'});
				if type(filterCmd) == 'string' and filterCmd:len() > 1 then
					matrice.Cle_filtrage = filterCmd;
					if not string.find(matrice.Cle_filtrage, 'Sexe') then
						matrice.Cle_filtrage = "$(Sexe):In('"..matrice.comboSexe.."')" ..' and '..matrice.Cle_filtrage;
					end
					local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle = 'Cle_filtrage'";
					base:Query(cmd);
					AddRowEvenement_Matrice('Cle_filtrage', matrice.Cle_filtrage);
				else
					if dlgConfig:MessageBox(
						"Voulez vous effacer les crit�res de filtrage\ndes concurrents pour le Challenge ?", 
						"Attention !!!",
						msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_WARNING
						) == msgBoxStyle.YES then
						local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle = 'Cle_filtrage'";
						base:Query(cmd);
						matrice.Cle_filtrage = nil;
					end
				
				end
			end
		end
		, btnFiltres);
	tbedit1:Bind(eventType.MENU, 
		function(evt)
			idxcoursestart = 0;
			AffichedlgCourses();
		end
		, btnVisuCourses);
	tbedit1:Bind(eventType.MENU,
		function(evt)
			BtnPrint()
			dlgConfig:EndModal(idButton.OK);
		end
		, btnPrint);
	tbedit1:Bind(eventType.MENU,
		function(evt)
			BtnPrint()
			dlgConfig:EndModal(idButton.OK);
		end
		, btnCalculer);
	tbedit1:Bind(eventType.MENU,
		function(evt)
			matrice.findescalculs = false;
			matrice.panel_name = 'printanalyse';
			if not matrice.analyseGauche1 then
				dlgConfig:MessageBox(
					"Veuillez d�finir les crit�res de l'analyse !!!",
					"Analyse des performances", 
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
					) 
				return;
			end
			if matrice.comboResultatPar == 'Non' then
				if #matrice.tGroupesCalcul == 0 then
					Calculer('printanalyse', 0);
					if not matrice.findescalculs == true then
						dlgConfig:MessageBox(
							"Une erreur est intervenue durant les calculs !!!",
							"Calcul de la matrice "..matrice.Titre, 
							msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
							);
						return;
					end
					OnPrintAnalyse();
				else
					for i = 1, #matrice.tGroupesCalcul do
						if i > 1 then
							matrice.next = true;
						end
						Calculer('printanalyse', i);
						if not matrice.findescalculs == true then
							dlgConfig:MessageBox(
								"Une erreur est intervenue durant les calculs !!!",
								"Calcul de la matrice "..matrice.Titre, 
								msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
								);
							return;
						end
						OnPrintAnalyse();
					end
				end
			end
			dlgConfig:EndModal(idButton.OK);
		end
		, btnAnalyse);
			
	dlgConfig:Bind(eventType.TEXT, OnChangenumMinimumArrivee, dlgConfig:GetWindowName('numMinimumArrivee'));
	dlgConfig:Bind(eventType.COMBOBOX, OnChangecomboEntite, dlgConfig:GetWindowName('comboEntite'));
	dlgConfig:Bind(eventType.COMBOBOX, OnChangeSaison, dlgConfig:GetWindowName('Saison'));
	dlgConfig:Bind(eventType.COMBOBOX, OnChangecomboTpsDuDernier, dlgConfig:GetWindowName('comboTpsDuDernier'));
	dlgConfig:Bind(eventType.COMBOBOX,
		function(evt)
			OnChangecomboPrendreBlocx(1); 
		end,
		dlgConfig:GetWindowName('comboPrendreBloc1'));
		
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt)
			OnChangecomboPrendreBlocx(2); 
		end,
		dlgConfig:GetWindowName('comboPrendreBloc2'));
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt) 
			matrice.comboTypePoint = dlgConfig:GetWindowName('comboTypePoint'):GetValue();
			OnChangecomboTypePoint(matrice.comboTypePoint);
		end,  
		dlgConfig:GetWindowName('comboTypePoint'));
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt)
			matrice.comboActivite = matrice.comboActivite;
			BuildGrilles_Point_Place();
			dlgConfig:GetWindowName('comboGrille'):Clear();
			for i = 0, tGrille_Point_Place:GetNbRows() -1 do
				dlgConfig:GetWindowName('comboGrille'):Append(tGrille_Point_Place:GetCell("Libelle", i));
			end
			dlgConfig:GetWindowName('comboGrille'):SetSelection(0)
			ChargeDisciplines();
		end,  
		dlgConfig:GetWindowName('comboActivite'));
		
	tbedit1:Bind(eventType.MENU, AfficheVersion, btnVersion);
	tbedit1:Bind(eventType.MENU, AfficheAide, btnHelp);
	
	-- lecture et affichage des donn�es. Les bind feront leur effet
	
	LitMatrice();
	LitMatriceCourses(false);

	if string.find(matrice.comboTypePoint, 'place') then
		dlgConfig:GetWindowName('comboGrille'):Clear();
		for i = 0, tGrille_Point_Place:GetNbRows() -1 do
			dlgConfig:GetWindowName('comboGrille'):Append(tGrille_Point_Place:GetCell('Libelle', i));
		end
		dlgConfig:GetWindowName('comboPrendreBloc1'):Append("4.G�n�ral PLUS meilleure manche");
		dlgConfig:GetWindowName('comboPrendreBloc1'):Append("5.G�n�ral OU meilleure manche");
		dlgConfig:GetWindowName('comboPrendreBloc2'):Append("4.G�n�ral PLUS meilleure manche");
		dlgConfig:GetWindowName('comboPrendreBloc2'):Append("5.G�n�ral OU meilleure manche");
		dlgConfig:GetWindowName('numPtsPresence'):Append("0");
		dlgConfig:GetWindowName('numPtsPresence'):Append("1");
	end
	dlgConfig:GetWindowName('numArretCalculApres'):Clear();
	dlgConfig:GetWindowName('numArretCalculApres'):Append('');
	if tMatrice_Courses then
		for i = 0, tMatrice_Courses:GetNbRows()-1 do
			dlgConfig:GetWindowName('numArretCalculApres'):Append((i+1)..' - '..tMatrice_Courses:GetCell('Date_epreuve', i)..' - '..tMatrice_Courses:GetCell('Station', i)..' : '..tMatrice_Courses:GetCell('Code_discipline', i));
		end
	end
	-- affectation des variables et set enable des contr�les
	
	SetDatadlgConfiguration();
	SetEnableControldlgConfiguration();
	if dlgConfig:ShowModal() == idButton.OK then
		do return end
	end
	-- dlgConfig:ShowModal();
	-- if matrice.timer then matrice.timer:Delete(); end
	-- if matrice.findescalculs == true then
		-- if matrice.panel_name == 'print' then
			-- OnPrint();
		-- elseif matrice.panel_name == 'printanalyse' then
			-- OnPrintAnalyse();
		-- end
	-- end
	-- do return end
end

function OnGetColorDiscipline(ligne)
	local rgb_color = '';;
	colorDialog = wnd.CreateColorDialog({parent = dlgParamColor}, color.Create('255,255,255') );
	if colorDialog:ShowModal() == idButton.OK then
		colorselect = colorDialog:GetColor();
		rgb_color = colorselect:Red()..' '..colorselect:Green()..' '..colorselect:Blue();
	end
	colorDialog:Delete();
	colorDiscipline[ligne].Color = rgb_color;
	return rgb_color;
end

function OnGetColorPodium()
	local rgb_color = '';;
	colorDialog = wnd.CreateColorDialog({parent = dlgParamColor}, color.Create('255,255,255') );
	if colorDialog:ShowModal() == idButton.OK then
		colorselect = colorDialog:GetColor();
		rgb_color = colorselect:Red()..' '..colorselect:Green()..' '..colorselect:Blue();
	end
	colorDialog:Delete();
	return rgb_color;
end

function AffichedlgParamColor()
	colorDiscipline = {};
	local doc = xmlDocument.Create(app.GetPath().."/challenge/matrice_config.xml");
	local node = doc:FindFirst('root/colors');	-- on va chercher les valeurs par d�faut des variables des couleurs des disciplines
	node = node:GetChildren();
	while node ~= nil do
		local code_discipline = node:GetName();
		local color = node:GetNodeContent();
		table.insert(colorDiscipline, {Discipline = code_discipline, Color = node:GetNodeContent()});
		node = node:GetNext();
	end
	
	dlgParamColor = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Configuration des couleurs des disciplines', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgParamColor:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'configparamcolor',	-- Facultatif si le node_name est unique ...
		colordisciplines = colorDiscipline
	});

-- local dlgColor = wnd.CreateColorDialog({});

-- dlgColor:ShowModal();
-- local colorselect = dlgColor:GetColor();
-- colorselect:GetRGB();

	-- { "Create", _colorCreate },
	-- { "Red", _colorRed },
	-- { "Green", _colorGreen },
	-- { "Blue", _colorBlue },
	-- { "Alpha", _colorAlpha },

	-- { "GetRGB", _colorGetRGB },

	-- { "__eq", _color__eq },

	local tbconfigparam = dlgParamColor:GetWindowName('tbconfigparam');
	tbconfigparam:AddStretchableSpace();
	local btnDefaut = tbconfigparam:AddTool("Config par d�faut", "./res/32x32_clear.png");
	tbconfigparam:AddSeparator();
	local btnClose = tbconfigparam:AddTool("Retour", "./res/32x32_exit.png");

	tbconfigparam:Bind(eventType.MENU, 
		function(evt) 
			colorDiscipline[1].Color = '0 255 255';		--SL
			colorDiscipline[2].Color = '255 0 255';		--GS
			colorDiscipline[3].Color = '255 0 255';		--GS1
			colorDiscipline[4].Color = '0 255 0';		--SG
			colorDiscipline[5].Color = '255 255 0';		--DH
			colorDiscipline[6].Color = '255 170 0';		--SC
			colorDiscipline[7].Color = '192 192 192';	--CS
			for i = 1, #colorDiscipline do
				local code_discipline = colorDiscipline[i].Discipline;
				local node = doc:FindFirst('root/colors/'..code_discipline);
				local rgb_color = colorDiscipline[i].Color;
				node:SetNodeContent(rgb_color);
				local wndTextColor = dlgParamColor:GetWindowName('bgc'..i);
				if wndTextColor ~= nil then
					local objText = wndTextColor:GetObject(0);
					if objText ~= nil then
						local txtColor = string.gsub(rgb_color, ' ', ',');
						objText:SetBkColorStart(color.Create(txtColor));
						objText:Refresh();
					end
				end
			end
			doc:SaveFile();
			tbconfigparam:EndModal(idButton.CANCEL);
		end, btnDefaut);
		
	tbconfigparam:Bind(eventType.MENU, 
		function(evt) 
			tbconfigparam:EndModal(idButton.CANCEL);
		end, btnClose);
	tbconfigparam:AddStretchableSpace();
	tbconfigparam:Realize();

	-- Initialisation des controles et affectation des variables directement dans le XML
	for i = 1, #colorDiscipline do
		dlgParamColor:GetWindowName('discipline'..i):SetValue(colorDiscipline[i].Discipline);
	end
	
	-- Bind
	for i = 1, #colorDiscipline do
		dlgParamColor:Bind(eventType.CHECKBOX, 
			function(evt) 
				if dlgParamColor:GetWindowName('chk'..i):GetValue() == true then
					dlgParamColor:GetWindowName('chk'..i):SetValue(false);
					local code_discipline = colorDiscipline[i].Discipline;
					local node = doc:FindFirst('root/colors/'..code_discipline);
					local rgb_color = OnGetColorDiscipline(i);
					if node and rgb_color:len() > 0 then
						node:SetNodeContent(rgb_color);
						doc:SaveFile();
						local wndTextColor = dlgParamColor:GetWindowName('bgc'..i);
						if wndTextColor ~= nil then
							local objText = wndTextColor:GetObject(0);
							if objText ~= nil then
								local txtColor = string.gsub(rgb_color, ' ', ',');
								objText:SetBkColorStart(color.Create(txtColor));
								objText:Refresh();
							end
						end
			
					end
				end
			end,
			dlgParamColor:GetWindowName('chk'..i));
	end

	tbconfigparam:Bind(eventType.MENU, 
			function(evt) 
				dlgParamColor:EndModal(idButton.CANCEL)
			end, btnClose);
	if dlgParamColor:ShowModal() == idButton.OK then
		dlgParamColor:MessageBox(
				"Enregistrement OK !!!",
				"Param�trage des couleurs des disciplines", 
				msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
				) 
	end
	if doc then
		doc:Delete();
	end
end

function AffichedlgParamColorPodium()
	local doc_podium = xmlDocument.Create(app.GetPath().."/challenge/matrice_config.xml");
	local node = doc_podium:FindFirst('root/podium');	-- on va chercher les valeurs par d�faut des variables des couleurs des disciplines
	local colorpodium = node:GetNodeContent();
	dlgParamColorPodium = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Configuration des couleurs du podium', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgParamColorPodium:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		colorpodium = colorpodium,
		node_value = 'configparamcolorpodium'	-- Facultatif si le node_name est unique ...
	});
	local tbconfigparam = dlgParamColorPodium:GetWindowName('tbconfigparam');
	tbconfigparam:AddStretchableSpace();
	local btnDefaut = tbconfigparam:AddTool("Config par d�faut", "./res/32x32_clear.png");
	tbconfigparam:AddSeparator();
	local btnClose = tbconfigparam:AddTool("Retour", "./res/32x32_exit.png");

	tbconfigparam:Bind(eventType.MENU, 
		function(evt) 
			cololorpodium = '0 0 255';		--par d�faut
			local doc_podium = xmlDocument.Create(app.GetPath().."/challenge/matrice_config.xml");
			local root = doc_podium:GetRoot()
			local node = doc_podium:FindFirst('root/podium');
			node:SetNodeContent(cololorpodium);
			local wndTextColor = dlgParamColorPodium:GetWindowName('podium');
			if wndTextColor ~= nil then
				local objText = wndTextColor:GetObject(0);
				if objText ~= nil then
					local txtColor = string.gsub(cololorpodium, ' ', ',');
					objText:SetBkColorStart(color.Create(txtColor));
					objText:Refresh();
				end
			end
			doc_podium:SaveFile();
			tbconfigparam:EndModal(idButton.CANCEL);
		end, btnDefaut);
		
	tbconfigparam:Bind(eventType.MENU, 
		function(evt) 
			tbconfigparam:EndModal(idButton.CANCEL);
		end, btnClose);
	tbconfigparam:AddStretchableSpace();
	tbconfigparam:Realize();


	dlgParamColorPodium:Bind(eventType.CHECKBOX, 
		function(evt) 
			if dlgParamColorPodium:GetWindowName('chkpodium'):GetValue() == true then
				dlgParamColorPodium:GetWindowName('chkpodium'):SetValue(false);
				local doc_podium = xmlDocument.Create(app.GetPath().."/challenge/matrice_config.xml");
				local root = doc_podium:GetRoot()
				local node = doc_podium:FindFirst('root/podium');
				local rgb_color = OnGetColorPodium();
				if node and rgb_color:len() > 0 then
					node:SetNodeContent(rgb_color);
					doc_podium:SaveFile();
					local wndTextColor = dlgParamColorPodium:GetWindowName('podium');
					if wndTextColor ~= nil then
						local objText = wndTextColor:GetObject(0);
						if objText ~= nil then
							local txtColor = string.gsub(rgb_color, ' ', ',');
							objText:SetBkColorStart(color.Create(txtColor));
							objText:Refresh();
						end
					end
				end
			end
		end,
		dlgParamColorPodium:GetWindowName('chkpodium'));
	tbconfigparam:Bind(eventType.MENU, 
			function(evt) 
				dlgParamColorPodium:EndModal(idButton.CANCEL)
			end, btnClose);
	if doc_podium then
		doc_podium:Delete();
	end
	dlgParamColorPodium:ShowModal();
end

function AddRowEvenement_Matrice(cle, valeur)		-- ajout d'une ligne cl� / valeur dans la table Evenement_Matrice
	local row = tEvenement_Matrice:AddRow();
	tEvenement_Matrice:SetCell('Code_evenement', row, matrice.code_evenement);
	tEvenement_Matrice:SetCell('Cle', row, cle);
	tEvenement_Matrice:SetCell('Valeur', row, valeur);
	base:TableInsert(tEvenement_Matrice, row);
end

function OnSavedlgFiltre(colonne)	-- lescture et �criture des variables des filtres d'inclusion / exclusion
	local cmd = "Delete From tEvenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle Like '"..colonne.."_%'";
	base:Query(cmd);
	local filtrein = '';
	local filtreout = '';
	for i = 0, 14 do
		local valeur = dlgVisuFiltrex:GetWindowName('filtrex'..i):GetValue()
		if string.len(valeur) > 1 then
			local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle Like '{"..colonne.."}_align:%'";
			base:Query(cmd);
			local racine = colonne..'_align:';		
			local align = dlgVisuFiltrex:GetWindowName('align'..i):GetValue();
			if align ~= 'centre' then
				AddRowEvenement_Matrice(racine..valeur, align);
				matrice.sortirBoucleFiltre = true;
			end
		end
		if dlgVisuFiltrex:GetWindowName('chkinclure'..i):GetValue() == true then
			if filtrein == '' then
				filtrein = dlgVisuFiltrex:GetWindowName('filtrex'..i):GetValue();
			else
				filtrein = filtrein..','..dlgVisuFiltrex:GetWindowName('filtrex'..i):GetValue();
			end
		end
		if dlgVisuFiltrex:GetWindowName('chkexclure'..i):GetValue() == true then
			if filtreout == '' then
				filtreout = dlgVisuFiltrex:GetWindowName('filtrex'..i):GetValue();
			else
				filtreout = filtreout..','..dlgVisuFiltrex:GetWindowName('filtrex'..i):GetValue();
			end
		end
	end
	if filtrein ~= '' then
		AddRowEvenement_Matrice(colonne..'_in', filtrein);
	end
	if filtreout ~= '' then
		AddRowEvenement_Matrice(colonne..'_out', filtreout);
	end
	RempliTableauMatrice();
end

function OnSavedlgColonne()		-- lecture et �critue des variables pour les colonnes � imprimer (An, Comit� etc.)
	--                           Colonne, Label, Align, Imprimer
	-- matrice.imprimerColonnes : 'Code_coureur,Code,center,1|Identite,Identit�,left,1|Sexe,S.,center,1|An,An,center,4|Categ,Cat.,center,0|Nation,Nat.,center,0|Comite,CR,center,0|Club,Club,left,0|Groupe,Groupe,left,0,|Equipe,Equipe,left,0|Critere,Crit�re,left,0|Liste1,Liste,center,0|Liste2,Liste,center,0|Delta,Delta,center,0';
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And (Cle = 'imprimerColonnes' Or Cle Like 'comboListe%')";
	base:Query(cmd);
	matrice.imprimerColonnes = '';
	matrice.last_code_liste = nil; matrice.comboListe1 = nil;
	for i = 1, 14 do
		local separator = '|';
		if i == 1 then
			separator = '';
		end
		if dlgColonne:GetWindowName('chk12'):GetValue() == false or dlgColonne:GetWindowName('chk13'):GetValue() == false then
			dlgColonne:GetWindowName('chk14'):SetValue(false);
		end
		local chk = 0;
		if dlgColonne:GetWindowName('chk'..i):GetValue() == true then
			chk = 1;
		end
		local align = dlgColonne:GetWindowName('align'..i):GetValue();
		if align == '' then 
			align = 'center';
		end
		local chaine = colonnes[i].Colonne..','..dlgColonne:GetWindowName('label'..i):GetValue()..','..align..','..chk;
		matrice.imprimerColonnes = matrice.imprimerColonnes..separator..chaine;
	end
	AddRowEvenement_Matrice('imprimerColonnes', matrice.imprimerColonnes);
	local idxtypeclassement = nil;
	if dlgColonne:GetWindowName('chk12'):GetValue() == true then 
		AddRowEvenement_Matrice('comboListe1', dlgColonne:GetWindowName('comboListe1'):GetValue());
		AddRowEvenement_Matrice('comboListe1Classement', dlgColonne:GetWindowName('comboListe1Classement'):GetValue());
	end
	if dlgColonne:GetWindowName('chk13'):GetValue() == true then
		AddRowEvenement_Matrice('comboListe2', dlgColonne:GetWindowName('comboListe2'):GetValue());
		AddRowEvenement_Matrice('comboListe2Classement', dlgColonne:GetWindowName('comboListe2Classement'):GetValue());
	end
	if dlgColonne:GetWindowName('chk12'):GetValue() == true or dlgColonne:GetWindowName('chk13'):GetValue() == true then
		matrice.comboListePrimaute = dlgColonne:GetWindowName('comboListePrimaute'):GetValue();
		AddRowEvenement_Matrice('comboListePrimaute', dlgColonne:GetWindowName('comboListePrimaute'):GetValue());
	end
	RempliTableauMatrice();
end

function OnSavedlgColonne2()	-- lecture et ecriture des variables des colonnes � imprimer pour chaque course (Tps, Clt etc.)
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And (Cle Like 'imprimerBloc%' Or Cle Like 'imprimerCombiSaut%' or Cle Like 'numPenalisation%')";
	base:Query(cmd);
	local separator = '';
	matrice.imprimerBloc1 = '';
	matrice.imprimerBloc2 = '';
	matrice.imprimerCombiSaut = '';
	for i = 1, #colonnes1Course do
		if tMatrice_Courses:GetNbRows() >= 20 and i > 4 then
			dlgColonne2:GetWindowName('1chk'..i):SetValue(false)
		end
		local chaine1 = '';
		local chk1 = 0; 
		if dlgColonne2:GetWindowName('1chk'..i):GetValue() == true then
			chk1 = 1;
		end
		chaine1 = arColonnes1Course[i].Colonne..','..chk1..','..dlgColonne2:GetWindowName('1label'..i):GetValue();
		matrice.imprimerBloc1 = matrice.imprimerBloc1..separator..chaine1;
		separator = '|';
	end
	local separator = '';
	for i = 1, #colonnes2Course do
		local chaine2 = '';
		local chk2 = 0; 
		if tMatrice_Courses:GetNbRows() >= 20 and i > 4 then
			dlgColonne2:GetWindowName('2chk'..i):SetValue(false)
		end
		if dlgColonne2:GetWindowName('2chk'..i):GetValue() == true then
			chk2= 1;
		end
		chaine2 = arColonnes2Course[i].Colonne..','..chk2;
		matrice.imprimerBloc2 = matrice.imprimerBloc2..separator..chaine2;
		separator = '|';
	end
	local separator = '';
	for i = 1, #tColonnes3 do
		local chaine3 = '';
		local chk3 = 0;
		if dlgColonne2:GetWindowName('3chk'..i):GetValue() == true then
			chk3= 1;
		end
		chaine3 = colonnes3[i].Colonne..','..chk3;
		matrice.imprimerCombiSaut = matrice.imprimerCombiSaut..separator..chaine3;
		separator = '|';
	end
	matrice.numPenalisationSaut = tonumber(dlgColonne2:GetWindowName('numPenalisationSaut'):GetValue()) or 0;
	AddRowEvenement_Matrice('imprimerBloc1', matrice.imprimerBloc1);
	AddRowEvenement_Matrice('imprimerBloc2', matrice.imprimerBloc2);
	AddRowEvenement_Matrice('imprimerCombiSaut', matrice.imprimerCombiSaut);
	AddRowEvenement_Matrice('numPenalisationSaut', matrice.numPenalisationSaut);
	RempliTableauMatrice();
end

function OnSavedlgColonne3(colonne, bolraz)	-- lecture et ecriture des variables des colonnes � imprimer 
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle = '"..colonne.."_align'";
	base:Query(cmd);
	local cle = colonne..'_align';
	if bolraz == true then
		for i = 1, 20 do
			dlgColonne3:GetWindowName('colonne'):SetValue('');
			dlgColonne3:GetWindowName('val'..i):SetValue('');
			dlgColonne3:GetWindowName('val'..i):Enable(false);
			dlgColonne3:GetWindowName('align'..i):SetValue('');
			dlgColonne3:GetWindowName('align'..i):Enable(false);
			matrice[cle] = nil;
		end
		return;
	end
	local align = ''; local chaine = nil;
	-- cle = 'AN_align'; chaine = 2003,right|2004,left
	for i = 1, 20 do
		local valeur = dlgColonne3:GetWindowName('val'..i):GetValue();	-- Ex : 2003
		local selalign = dlgColonne3:GetWindowName('align'..i):GetSelection();
		if valeur:len() > 0 then
			if selalign == 0 then
				align = 'left';
			elseif selalign == 1 then
				align = 'center';
			else
				align = 'right';
			end
			if selalign ~= 1 then
				if not chaine then
					chaine = valeur..','..align;				-- Ex : 2003,right
				else
					chaine = chaine..'|'..valeur..','..align;	--Ex : 2003,right|2002,left
				end
			end
		end
	end
	if chaine then
		AddRowEvenement_Matrice(cle, chaine);
		matrice[cle] = chaine;
	end
end

function OnSavedlgCourseMatrice(rowcourse, bolRAZ, bolNext)			-- lecture et �criture des variables pour le param�trage sp�cifique d'une course.
	assert(rowcourse ~= nil);
	tMatrice_Courses:SetCell('Flag_param', rowcourse, '');
	local code_course = tMatrice_Courses:GetCellInt('Code', rowcourse);	
	local racine0 = "'["..code_course.."]%'";
	local racinecoureur0 = "'["..code_course.."]_ajouter%'";
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement..
		" And Cle Like "..racine0..
		" And Not Cle Like "..racinecoureur0;
	base:Query(cmd);
	local str = '['..code_course..'  -  '..tMatrice_Courses:GetCell('Code_discipline', rowcourse)..'  -  '..tMatrice_Courses:GetCellInt('Bloc', rowcourse)..']   '..tMatrice_Courses:GetCell('Nom', rowcourse);
	local racine0 = "["..code_course.."]_";
	if bolRAZ == true then
		matrice[racine0..'numBloc'] = nil;
		matrice[racine0..'comboPrendre'] = nil;
		matrice[racine0..'comboObligatoire'] = nil; 
		matrice[racine0..'comboSkip'] = nil; 
		matrice[racine0..'coefCourse'] = nil;
		matrice[racine0..'coefManche'] = nil;
		matrice[racine0..'comboGrille'] = nil;
		if bolNext == true then
			matrice.bloc2 = false;
			for i = rowcourse + 1 , tMatrice_Courses:GetNbRows() -1 do
				local racine = "'["..tMatrice_Courses:GetCellInt('Code', i).."]%'";
				local racinecoureur = "'["..tMatrice_Courses:GetCellInt('Code', i).."]_ajouter%'";
				local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle Like "..racine.." And Not Cle Like "..racinecoureur;
				base:Query(cmd);
				local racine = "["..tMatrice_Courses:GetCellInt('Code', i).."]_";
				matrice[racine..'numBloc'] = nil;
				matrice[racine..'comboPrendre'] = nil;
				matrice[racine..'comboObligatoire'] = nil; 
				matrice[racine..'comboSkip'] = nil; 
				matrice[racine..'coefCourse'] = nil;
				matrice[racine..'coefManche'] = nil;
				matrice[racine..'comboGrille'] = nil;;
			end
		end
		OnAfficheCourses();
		dlgConfig:GetWindowName('coefPourcentageMaxiBloc2'):SetValue('');
		SetDatadlgConfiguration();
		SetEnableControldlgConfiguration();
		LitMatriceCourses(false);
		OnAfficheCourses(idxcoursestart);
		return;
	end
	local bloc = tonumber(dlgVisuCoursex:GetWindowName('numBloc'):GetValue());
	tMatrice_Courses:SetCell('Bloc', rowcourse, bloc);
	if bloc == 2 then
		matrice.bloc2 = true;
	end
	if matrice.course[(rowcourse+1)].bloc == 2 then
		AddRowEvenement_Matrice(racine0..'numBloc', 2);
	end
	local obligatoire = dlgVisuCoursex:GetWindowName('comboObligatoire'):GetValue();
	if obligatoire == 'Oui' then
		AddRowEvenement_Matrice(racine0..'comboObligatoire', 'Oui');
	end
	local skip = dlgVisuCoursex:GetWindowName('comboSkip'):GetValue();
	if skip == 'Oui' then
		AddRowEvenement_Matrice(racine0..'comboSkip', 'Oui');
	end
	local coefcourse = tonumber(dlgVisuCoursex:GetWindowName('coefCourse'):GetValue()) or 0;
	if coefcourse > 0 and coefcourse ~= matrice['coefDefautCourseBloc'..bloc] then
		AddRowEvenement_Matrice(racine0..'coefCourse', coefcourse);
	end
	local coefmanche = tonumber(dlgVisuCoursex:GetWindowName('coefManche'):GetValue()) or 0;
	if coefmanche > 0 and coefmanche ~= matrice['coefDefautMancheBloc'..bloc] then
		AddRowEvenement_Matrice(racine0..'coefManche', coefmanche);
	end
	local combogrille = dlgVisuCoursex:GetWindowName('comboGrille'):GetValue();
	if not string.find(combogrille, 'Grille de la matrice') and combogrille ~= matrice.comboGrille then
		AddRowEvenement_Matrice(racine0..'comboGrille', combogrille);
	end
	local prendre = dlgVisuCoursex:GetWindowName('comboPrendre'):GetValue();
	if prendre ~= 'Idem matrice' and prendre ~= matrice['comboPrendreBloc'..bloc] then
		AddRowEvenement_Matrice(racine0..'comboPrendre', prendre);
	end
	if bolNext == true then	-- on applique les donn�es � toutes les courses suivantes;
		for i = rowcourse +1 , tMatrice_Courses:GetNbRows() -1 do
			local racine = "'["..tMatrice_Courses:GetCellInt('Code', i).."]%'";
			local racinecoureur = "'["..tMatrice_Courses:GetCellInt('Code', i).."]_ajouter%'";
			local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle Like "..racine.." And Not Cle Like "..racinecoureur;
			base:Query(cmd);
			racine = "["..tMatrice_Courses:GetCellInt('Code', i).."]_";
			matrice[racine..'numBloc'] = nil;
			matrice[racine..'comboPrendre'] = nil;
			matrice[racine..'comboObligatoire'] = nil; 
			matrice[racine..'comboSkip'] = nil; 
			matrice[racine..'coefCourse'] = nil;
			matrice[racine..'coefManche'] = nil;
			matrice[racine..'comboGrille'] = nil;
			if bloc > 1 then
				tMatrice_Courses:SetCell('Flag_param', i, '* ');
				AddRowEvenement_Matrice(racine..'numBloc', 2);
				-- matrice.course[(i+1)].existe_param = true;
			end
			if dlgVisuCoursex:GetWindowName('comboObligatoire'):GetValue() == 'Oui' then
				tMatrice_Courses:SetCell('Flag_param', i, '* ');
				AddRowEvenement_Matrice(racine..'comboObligatoire', 'Oui');
				-- matrice.course[(i+1)].existe_param = true;
			end
			if dlgVisuCoursex:GetWindowName('comboSkip'):GetValue() == 'Oui' then
				tMatrice_Courses:SetCell('Flag_param', i, '* ');
				tMatrice_Courses:SetCell('Skip', i, 1);
				AddRowEvenement_Matrice(racine..'comboSkip', 'Oui');
				-- matrice.course[(i+1)].existe_param = true;
			end
			if string.find(matrice.comboTypePoint, 'place') then
				if coefcourse > 0 and coefcourse ~= matrice['coefDefautCourseBloc'..bloc] then
					tMatrice_Courses:SetCell('Flag_param', i, '* ');
					AddRowEvenement_Matrice(racine..'coefCourse', coefcourse);
					-- matrice.course[(i+1)].existe_param = true;
				end
				if coefmanche > 0 and coefmanche ~= matrice['coefDefautMancheBloc'..bloc] then
					tMatrice_Courses:SetCell('Flag_param', i, '* ');
					AddRowEvenement_Matrice(racine..'coefManche', coefmanche);
					-- matrice.course[(i+1)].existe_param = true;
				end
				if not string.find(combogrille, 'Grille de la matrice') and combogrille ~= matrice.comboGrille then
					tMatrice_Courses:SetCell('Flag_param', i, '* ');
					AddRowEvenement_Matrice(racine..'comboGrille', combogrille);
					-- matrice.course[(i+1)].existe_param = true;
				end
			end
			if prendre ~= 'Idem matrice' and prendre ~= matrice['comboPrendreBloc'..bloc] then
				tMatrice_Courses:SetCell('Flag_param', i, '* ');
				AddRowEvenement_Matrice(racine..'comboPrendre', prendre);
				-- matrice.course[(i+1)].existe_param = true;
			end
		end
	end
	LitMatriceCourses(false);
	if matrice.debug == true then
		adv.Alert("OnSavedlgCourseMatrice - Snapshot('tMatrice_Courses.db3')");
		tMatrice_Courses:Snapshot('tMatrice_Courses.db3');
	end
	OnAfficheCourses(idxcoursestart);
	SetDatadlgConfiguration();
	SetEnableControldlgConfiguration();
end

function OnAfficheCourses(idxcoursestart)
	if not idxcoursestart then
		idxcoursestart = 0;
	end
	if not matrice.Evenement_selection or matrice.Evenement_selection:len() == 0 then
		app.GetAuiFrame():MessageBox(
			"Vous devez ajouter des courses pour aller plus loin !!", 
			"Attention",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
		return false;
	end
	local idxlu = idxcoursestart;
	for idx = 0, 19 do
		dlgCourses:GetWindowName('chk'..idx):SetValue(false);
		if idxlu > tMatrice_Courses:GetNbRows() -1 then
			dlgCourses:GetWindowName('date'..idx):SetValue('');
			dlgCourses:GetWindowName('codex'..idx):SetValue('');
			dlgCourses:GetWindowName('evenement'..idx):SetValue('');
			dlgCourses:GetWindowName('station'..idx):SetValue('');
			dlgCourses:GetWindowName('chk'..idx):Enable(false);
			dlgCourses:GetWindowName('chk'..idx):SetLabel('');
		else
			matrice.course[(idxlu+1)].code = tMatrice_Courses:GetCellInt('Code', idxlu)
			table.insert(matrice.courselue, idxlu);
			dlgCourses:GetWindowName('chk'..idx):Enable(true);
			dlgCourses:GetWindowName('chk'..idx):SetLabel((idxlu + 1)..'  ');
			dlgCourses:GetWindowName('date'..idx):SetValue(tMatrice_Courses:GetCell('Date_epreuve', idxlu));
			dlgCourses:GetWindowName('codex'..idx):SetValue(tMatrice_Courses:GetCell('Codex', idxlu));
			dlgCourses:GetWindowName('station'..idx):SetValue(tMatrice_Courses:GetCell('Station', idxlu));
			local str = tMatrice_Courses:GetCell('Flag_param', idx)..'['..tMatrice_Courses:GetCell('Code', idxlu)..'  -  '..tMatrice_Courses:GetCell('Code_discipline', idxlu)..'  -  '..tMatrice_Courses:GetCellInt('Bloc', idxlu)..']   '..tMatrice_Courses:GetCell('Nom', idxlu);
			dlgCourses:GetWindowName('evenement'..idx):SetValue(str);
		end
		idxlu = idxlu + 1;
	end
end

function AffichedlgCourses()	-- affichage des courses contenues dans matrice.Evenement_selection avec prise en compte d'un �ventuel param�trage sp�cifique des courses.
	dlgCourses = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Voir les courses du Challenge - Combin� -  il y a actuellement '..tMatrice_Courses:GetNbRows()..' course(s) dans la matrice', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgCourses:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'voirlescourses' 		-- Facultatif si le node_name est unique ...
	});

	-- Toolbar 
	local tbvoirlescourses = dlgCourses:GetWindowName('tbvoirlescourses');
	tbvoirlescourses:AddStretchableSpace();
	local btnRetour = tbvoirlescourses:AddTool("Retour", "./res/32x32_exit.png");
	tbvoirlescourses:AddSeparator();
	local btnSuite = tbvoirlescourses:AddTool("Suite", "./res/vpe32x32_page_next.png");
	if tMatrice_Courses and tMatrice_Courses:GetNbRows() > 15 then
		tbvoirlescourses:EnableTool(btnSuite:GetId(), true);
	else
		tbvoirlescourses:EnableTool(btnSuite:GetId(), false);
	end
	tbvoirlescourses:AddStretchableSpace();

	tbvoirlescourses:Realize();
	
	-- Lecture des courses de Evenement_selection = tMatrice_Courses et initialisation des checkbox
	matrice.courselue = {};
	if matrice.debug == true then
		adv.Alert("AffichedlgCourses - Snapshot('tMatrice_Courses.db3')");
		tMatrice_Courses:Snapshot('tMatrice_Courses.db3');
	end
	OnAfficheCourses(idxcoursestart);
	-- Bind
	tbvoirlescourses:Bind(eventType.MENU, function(evt) dlgCourses:EndModal(idButton.CANCEL) end, btnRetour);
	for i = 0, 19 do
		dlgCourses:Bind(eventType.CHECKBOX, 
			function(evt) 
				if dlgCourses:GetWindowName('chk'..i):GetValue() == true then
					dlgCourses:GetWindowName('chk'..i):SetValue(false);
					AffichedlgVisuCoursex(matrice.courselue[i+1]);
				end
			end,
			dlgCourses:GetWindowName('chk'..i));
	end
	tbvoirlescourses:Bind(eventType.MENU, 
			function(evt)
				idxcoursestart = idxcoursestart + 20;
				if idxcoursestart > tMatrice_Courses:GetNbRows() -1 then
					idxcoursestart = 0;
				end
				OnAfficheCourses(idxcoursestart);
			end
			, btnSuite);
	dlgCourses:Fit();
	dlgCourses:ShowModal();
end

function OnSaveAjouterCoureurs(code)	-- sauvegarde du param�trage quand on veut donner des points � coureur absent sur une course
	local code_course = code;
	local racine = "'["..code_course.."]_ajouter|%'";
	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement.." And Cle Like "..racine;
	base:Query(cmd);
	cle = '['..code_course..']_ajouter|';
	for i = 0, 14 do
		local code_coureur = dlgAjouterCoureur:GetWindowName('code'..i):GetValue();
		local points = tonumber(dlgAjouterCoureur:GetWindowName('xpoints'..i):GetValue()) or -1;
		if points >= 0 then
			AddRowEvenement_Matrice(cle..code_coureur, points);
		end
	end
end
	
function OnAjouterCoureur(rowcourse)							-- bo�te de dialogue pour donner des points � un coureur absent sur une course
	local code_course = matrice.course[(rowcourse+1)].code;		-- ce coureur doit �tre inscrit � post�riori sans dossard dans la course en question
	dlgAjouterCoureur = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Ajout de coureurs absents sur la course n� '..code_course,
		icon='./res/32x32_ffs.png'
		});
	
	dlgAjouterCoureur:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'ajoutercoureurs' 		-- Facultatif si le node_name est unique ...
	});

	-- Toolbar 
	
	local tbajoutercoureurs = dlgAjouterCoureur:GetWindowName('tbajoutercoureurs');
	tbajoutercoureurs:AddStretchableSpace();
	local btnValider = tbajoutercoureurs:AddTool("Valider", "./res/vpe32x32_save.png");
	tbajoutercoureurs:AddSeparator();
	local btnRetour = tbajoutercoureurs:AddTool("Retour", "./res/32x32_exit.png");
	tbajoutercoureurs:AddSeparator();
	local btnEffacer = tbajoutercoureurs:AddTool("Effacer", "./res/32x32_clear.png");
	tbajoutercoureurs:AddStretchableSpace();
	tbajoutercoureurs:Realize();
	-- Lecture des coureurs sans dossards de la table Resultat
	-- ex: matrice[[1506]_ajouter|FIS6191024]
	for i = 0, 14 do
		if i <= tResultat:GetNbRows() -1 then
			local code_coureur = tResultat:GetCell('Code_coureur', i)
			dlgAjouterCoureur:GetWindowName('code'..i):SetValue(code_coureur);
			dlgAjouterCoureur:GetWindowName('identite'..i):SetValue(tResultat:GetCell('Nom', i)..' '..tResultat:GetCell('Prenom', i));
			if ajouter[(rowcourse+1)][code_coureur] then
				dlgAjouterCoureur:GetWindowName('xpoints'..i):SetValue(ajouter[(rowcourse+1)][code_coureur].Pts);
			end
		end
	end
	-- Bind
	tbajoutercoureurs:Bind(eventType.MENU, function(evt) dlgAjouterCoureur:EndModal(idButton.CANCEL) end, btnRetour);
	dlgAjouterCoureur:Bind(eventType.TIMER, OnTimer, matrice.timer);
	tbajoutercoureurs:Bind(eventType.MENU, 
		function(evt)
			if dlgAjouterCoureur:MessageBox(
				"Voulez-vous effacer tous les coureurs ajout�s � cette course ?", 
				"Effacer les coureurs",
				msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
				) == msgBoxStyle.YES then
					local racine = "'["..code_course.."]_ajouter%'";
					local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement..' And Cle Like '..racine;
					base:Query(cmd);
				matrice.dialog = dlgAjouterCoureur;
				matrice.timer:Start(600);	-- Temps de scrutation de 0,5 secondes
				TimerDialogInit();
				matrice.action = 'close';
			end
		end
		, btnEffacer);
	tbajoutercoureurs:Bind(eventType.MENU, 
		function(evt)
			matrice.dialog = dlgAjouterCoureur;
			matrice.timer:Start(600);	-- Temps de scrutation de 0,5 secondes
			matrice.action = 'nada';
			dlgAjouterCoureur:Bind(eventType.TIMER, OnTimer, matrice.timer);
			TimerDialogInit();
			OnSaveAjouterCoureurs(code_course);
			matrice.action = 'close';
		end
		, btnValider);
			
	dlgAjouterCoureur:ShowModal();
end

function AfficheCoefCoursex(rowcourse)	-- affiche les valeurs dans les contr�les de la boite de dialogue dlgVisuCoursex 
	local bloc = tMatrice_Courses:GetCellInt('Bloc', rowcourse);
	local strcoefcourse = 'Idem d�faut';
	local strcoefmanche = 'Idem d�faut';
	matrice.course[(rowcourse+1)].coef_course = tMatrice_Courses:GetCellInt('Coef_course', rowcourse);
	matrice.course[(rowcourse+1)].coef_manche = tMatrice_Courses:GetCellInt('Coef_manche', rowcourse);
	if matrice.course[(rowcourse+1)].coef_course ~= matrice['coefDefautCourseBloc'..bloc] then
		strcoefcourse = matrice.course[(rowcourse+1)].coef_course;
	end
	if matrice.course[(rowcourse+1)].coef_manche ~= matrice['coefDefautMancheBloc'..bloc] then
		strcoefmanche = matrice.course[(rowcourse+1)].coef_manche;
	end
	dlgVisuCoursex:GetWindowName('coefCourse'):SetValue(strcoefcourse);
	dlgVisuCoursex:GetWindowName('coefManche'):SetValue(strcoefmanche);
end

function AffichedlgVisuCoursex(rowcourse)	-- affichage du param�trage de la course. Si aucun param�trage sp�cifique est d�fini, les param�tres standards de la matrice sont affich�s.
	dlgVisuCoursex = wnd.CreateDialog(
		{
		width = matrice.dlgPosit.width,
		height = matrice.dlgPosit.height,
		x = matrice.dlgPosit.x,
		y = matrice.dlgPosit.y,
		label='Configuration des param�tres de la course n�'..tMatrice_Courses:GetCellInt('Code', rowcourse), 
		});
		icon='./res/32x32_ffs.png'
	
	dlgVisuCoursex:LoadTemplateXML({ 
		xml = './challenge/matrice.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'coursex' 		-- Facultatif si le node_name est unique ...
	});

	-- local racine = "["..tMatrice_Courses:GetCell('Code', rowcourse).."]_";
	dlgVisuCoursex:GetWindowName('numBloc'):Append('1');		
	dlgVisuCoursex:GetWindowName('numBloc'):Append('2');		
	dlgVisuCoursex:GetWindowName('comboObligatoire'):SetTable(tOuiNon, 'Choix', 'Choix');
	dlgVisuCoursex:GetWindowName('comboSkip'):SetTable(tOuiNon, 'Choix', 'Choix');
	BuildGrilles_Point_Place();	
	dlgVisuCoursex:GetWindowName('comboGrille'):Append("Grille de la matrice");
	for i = 0, tGrille_Point_Place:GetNbRows() -1 do
		dlgVisuCoursex:GetWindowName('comboGrille'):Append(tGrille_Point_Place:GetCell("Libelle", i));
	end
	dlgVisuCoursex:GetWindowName('comboPrendre'):Clear();
	-- 1.Classement g�n�ral"
	-- 2.Classement � la manche"
	-- 3.Idem plus le classement g�n�ral"
	-- 4.G�n�ral PLUS meilleure manche"
	-- 5.G�n�ral OU meilleure manche"
	if string.find(matrice.comboTypePoint, 'place') then
		dlgVisuCoursex:GetWindowName('comboPrendre'):Append("Idem matrice");
		dlgVisuCoursex:GetWindowName('comboPrendre'):Append("1.Classement g�n�ral");
		dlgVisuCoursex:GetWindowName('comboPrendre'):Append("2.Classement � la manche");
		dlgVisuCoursex:GetWindowName('comboPrendre'):Append("3.Idem plus le classement g�n�ral");
		dlgVisuCoursex:GetWindowName('comboPrendre'):Append("4.G�n�ral PLUS meilleure manche");
		dlgVisuCoursex:GetWindowName('comboPrendre'):Append("5.G�n�ral OU meilleure manche");
	else
		dlgVisuCoursex:GetWindowName('comboPrendre'):Append("Idem matrice");
		dlgVisuCoursex:GetWindowName('comboPrendre'):Append("1.Classement g�n�ral");
		dlgVisuCoursex:GetWindowName('comboPrendre'):Append("2.Classement � la manche");
		dlgVisuCoursex:GetWindowName('comboPrendre'):Append("3.Idem plus le classement g�n�ral");
	end

	-- affectation des variables

	dlgVisuCoursex:GetWindowName('titre'):SetValue(tMatrice_Courses:GetCell('Nom', rowcourse));
	dlgVisuCoursex:GetWindowName('date'):SetValue(tMatrice_Courses:GetCell('Date_epreuve', rowcourse));
	dlgVisuCoursex:GetWindowName('station'):SetValue(tMatrice_Courses:GetCell('Station', rowcourse));
	dlgVisuCoursex:GetWindowName('discipline'):SetValue(tMatrice_Courses:GetCell('Code_discipline', rowcourse));
	if tMatrice_Courses:GetCellInt('Obligatoire', rowcourse) == 0 then
		dlgVisuCoursex:GetWindowName('comboObligatoire'):SetValue('Non');
	else
		dlgVisuCoursex:GetWindowName('comboObligatoire'):SetValue('Oui');
	end
	if tMatrice_Courses:GetCellInt('Skip', rowcourse) == 0 then
		dlgVisuCoursex:GetWindowName('comboSkip'):SetValue('Non');
	else
		dlgVisuCoursex:GetWindowName('comboSkip'):SetValue('Oui');
	end
	dlgVisuCoursex:GetWindowName('numBloc'):SetValue(tMatrice_Courses:GetCellInt('Bloc', rowcourse));
	if tMatrice_Courses:GetCell('Grille', rowcourse) == matrice.comboGrille then
		dlgVisuCoursex:GetWindowName('comboGrille'):SetSelection(0);
	else
		dlgVisuCoursex:GetWindowName('comboGrille'):SetValue(tMatrice_Courses:GetCell('Grille', rowcourse));
	end
	if tMatrice_Courses:GetCell('Prendre', rowcourse) == matrice['comboPrendreBloc'..tMatrice_Courses:GetCellInt('Bloc', rowcourse)] then
		dlgVisuCoursex:GetWindowName('comboPrendre'):SetSelection(0);
	else
		dlgVisuCoursex:GetWindowName('comboPrendre'):SetValue(tMatrice_Courses:GetCell('Prendre', rowcourse));
	end
	AfficheCoefCoursex(rowcourse);
	-- Toolbar 
	local tbcoursex = dlgVisuCoursex:GetWindowName('tbcoursex');
	tbcoursex:AddStretchableSpace();
	local btnSaveEdit = tbcoursex:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbcoursex:AddSeparator();
	local btnAjouterCoureurs = tbcoursex:AddTool("Rajouter des coureurs", "./res/32x32_list_add.png");
	tbcoursex:AddSeparator();
	local btnRAZ = tbcoursex:AddTool("RAZ des donn�es sp�cifiques", "./res/32x32_clear.png");
	tbcoursex:AddSeparator();
	local btnClose = tbcoursex:AddTool("Retour", "./res/32x32_exit.png");
	tbcoursex:AddStretchableSpace();
	tbcoursex:Realize();
	
	-- Bind
	dlgVisuCoursex:Bind(eventType.COMBOBOX, 
			function(evt)
				OnChangecomboBloc(rowcourse)
			end, dlgVisuCoursex:GetWindowName('numBloc'));
	tbcoursex:Bind(eventType.MENU, function(evt) dlgVisuCoursex:EndModal(idButton.CANCEL) end, btnClose);
	tbcoursex:Bind(eventType.MENU, 
			function(evt)
				dlgVisuCoursex:Bind(eventType.TIMER, OnTimer, matrice.timer);
				if dlgVisuCoursex:MessageBox(
					"Voulez-vous appliquer les changements � toutes les courses suivantes ?", 
					"Sauvegarde des donn�es !!!",
					msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
					) == msgBoxStyle.YES then
						matrice.dialog = dlgVisuCoursex;
						matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
						matrice.action = 'nada';
						TimerDialogInit();
						OnSavedlgCourseMatrice(rowcourse, false, true);
						matrice.action = 'close';
				else
					matrice.dialog = dlgVisuCoursex;
					matrice.timer:Start(600);	-- Temps de scrutation de 1,5 secondes
					matrice.action = 'nada';
					TimerDialogInit();
					OnSavedlgCourseMatrice(rowcourse, false, false);
					matrice.action = 'close';
				end
			end, btnSaveEdit);
	tbcoursex:Bind(eventType.MENU, 
		function(evt)
			cmd = 'Select * From Resultat Where Code_evenement = '..matrice.course[rowcourse+1].code.." And Dossard Is Null";
			tResultat = base:TableLoad(cmd);
			if tResultat:GetNbRows() > 0 then
				OnAjouterCoureur(rowcourse);
			else
				dlgVisuCoursex:MessageBox(
					"Aucun coureur ne peut �tre ajout� dans cette course !!!\nVous devez l'inscrire SANS DOSSARD dans les concurrents.", 
					"Attention !!!",
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
					);
				dlgVisuCoursex:EndModal(idButton.KO);
			end
		end
		, btnAjouterCoureurs);
	tbcoursex:Bind(eventType.MENU, 
		function(evt)
				if dlgVisuCoursex:MessageBox(
					"Voulez vous effacer toutes les donn�es sp�cifiques\nenregistr�es pour cette course ?", 
					"Confirmation !!!",
					msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
					) ~= msgBoxStyle.YES then
						return;
				end
				if dlgVisuCoursex:MessageBox(
					"Voulez-vous �galement supprimer les donn�es sp�cifiques de toutes les courses suivantes ?", 
					"Confirmation !!!",
					msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
					) == msgBoxStyle.YES then
						OnSavedlgCourseMatrice(rowcourse, true, true);
				else
					OnSavedlgCourseMatrice(rowcourse, true, false);
				end
				dlgVisuCoursex:EndModal(idButton.OK)
		end
		, btnRAZ);
	dlgVisuCoursex:Fit();
	dlgVisuCoursex:ShowModal();
end

function OnSavedlgConfiguration()	-- sauvegarde des param�tres de la matrice.
	-- suppression de tous les enregistrements pr�sents dans la table Evenement_Matrice sauf les [code et critere;
	-- r�cup�ration de la valeur de Evenement_selection, suppression de toutes les valeurs et cr�ation de la totalit� des valeurs
	-- relecture des variables de Evenement_Matrice pour recr�er les variables du tableau associatif matrice{}
	if matrice.comboEntite == 'FIS' and string.find(dlgConfig:GetWindowName('comboPresentationCourses'):GetValue(), 'Chrono') then
		if dlgConfig:MessageBox(
				"Voulez-vous revenir aux param�tres par d�faut\nde la pr�sentation horizontale ?",
				"Param�trage par d�faut", 
				msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT+ msgBoxStyle.ICON_INFORMATION
				) == msgBoxStyle.YES then
			if dlgConfig:MessageBox(
					"Confirmez-vous l'op�ration ?",
					"Param�trage par d�faut", 
					msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT+ msgBoxStyle.ICON_INFORMATION
					) == msgBoxStyle.YES then
				local apostrophe = "'"; local virgule = ',';
				for i = 0, tMatrice_Courses:GetNbRows() -1 do
					code_course = tMatrice_Courses:GetCell('Code',i);
					local racine = '['..code_course..']_';
					local strin = apostrophe..racine.."numBloc"..apostrophe..
								virgule..apostrophe..racine.."comboObligatoire"..apostrophe..
								virgule..apostrophe..racine.."comboSkip"..apostrophe..
								virgule..apostrophe..racine.."coefCourse"..apostrophe..
								virgule..apostrophe..racine.."coefManche"..apostrophe..
								virgule..apostrophe..racine.."comboGrille"..apostrophe
					local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement..' And Cle In('..strin..") Or Cle Like 'imprimer%'";
					base:Query(cmd);
				end
				dlgConfig:GetWindowName('comboGrille'):SetValue('Point Place Coupe du Monde FIS');
				dlgConfig:GetWindowName('comboResultatPar'):SetValue('Sans objet');
				dlgConfig:GetWindowName('comboAbdDsq'):SetValue('Non');
				dlgConfig:GetWindowName('comboOrientation'):SetValue('Paysage');
				dlgConfig:GetWindowName('comboPrendreBloc1'):SetValue('Classement g�n�ral');
				dlgConfig:GetWindowName('coefDefautCourseBloc1'):SetValue('100');
				dlgConfig:GetWindowName('coefDefautMancheBloc1'):SetValue('0');
				dlgConfig:GetWindowName('coefPourcentageMaxiBloc1'):SetValue('0');
				dlgConfig:GetWindowName('coefReduction'):SetValue('0');
				dlgConfig:GetWindowName('comboGarderInfQuota'):SetValue('Oui');
				matrice.imprimerBloc1 = 'Clt,0|Tps,0|Diff,0|Pts,1|Cltrun,0|Tpsrun,0|Diffrun,0|Ptsrun,0|Ptstotal,0|EtapeClt,0|EtapePts,0';
				matrice.imprimerBloc2 = 'Clt,0|Tps,0|Diff,0|Pts,1|Cltrun,0|Tpsrun,0|Diffrun,0|Ptsrun,0|Ptstotal,0';
				matrice.imprimerColonnes = 'Code_coureur,Code,center,1|Identite,Identit�,left,1|Sexe,S.,center,0|An,An,center,1|Categ,Cat.,center,1|Nation,Nat.,center,0|Comite,CR,center,1|Club,Club,left,1|Groupe,Groupe,left,0|Equipe,Equipe,left,0|Critere,Crit�re,left,0|Liste1,Liste,center,0|Liste2,Liste,center,0|Delta,Delta,center,0';
				matrice.Bloc2 = false;
				matrice.texteImprimerHeader = 'Non';
				matrice.texteMargeHaute1 = '4,5';
				matrice.texteMargeHaute2 = '4,5';
				matrice.texteImprimerClubLong = 'Oui';
				matrice.texteFiltreSupplementaire = 'Non';
				matrice.texteCodeComplet = 'Non';
				matrice.texteFontSize = '8';
				matrice.texteImprimerDeparts = 'Non';
				matrice.texteImprimerStatCourses ='Oui';
				matrice.texteImprimerLayerPage = 'Toutes les pages';
				matrice.texteLargeurEtroite = '0,8';
				matrice.texteNbColPresCourses = '4';
				matrice.texteLigne2Texte = 'Nombre de courses :';
				matrice.texteComiteOrigine = 'Non';
			end
		end
	end
	matrice.Titre = dlgConfig:GetWindowName('Titre'):GetValue();
	matrice.Saison = dlgConfig:GetWindowName('Saison'):GetValue();
	matrice.comboEntite = dlgConfig:GetWindowName('comboEntite'):GetValue();
	matrice.comboActivite = dlgConfig:GetWindowName('comboActivite'):GetValue();
	matrice.comboGrille = dlgConfig:GetWindowName('comboGrille'):GetValue();
	matrice.numArretCalculApres = dlgConfig:GetWindowName('numArretCalculApres'):GetSelection();
	matrice.comboOrientation = dlgConfig:GetWindowName('comboOrientation'):GetValue();
	matrice.comboSexe = dlgConfig:GetWindowName('comboSexe'):GetValue();
	matrice.comboAbdDsq = dlgConfig:GetWindowName('comboAbdDsq'):GetValue();
	matrice.comboGarderInfQuota = dlgConfig:GetWindowName('comboGarderInfQuota'):GetValue();
	matrice.comboTypePoint = dlgConfig:GetWindowName('comboTypePoint'):GetValue();
	matrice.comboPrendreBloc1 = dlgConfig:GetWindowName('comboPrendreBloc1'):GetValue();
	matrice.comboResultatPar = dlgConfig:GetWindowName('comboResultatPar'):GetValue();
	if matrice.bloc2 then
		matrice.comboPrendreBloc2 = dlgConfig:GetWindowName('comboPrendreBloc2'):GetValue();
	end
	tEvenement:SetCell('Code_entite', 0, matrice.comboEntite);
	tEvenement:SetCell('Code_saison', 0, matrice.Saison);
	base:TableUpdate(tEvenement, 0);

	local cmd = "Delete From Evenement_Matrice Where Code_evenement = "..matrice.code_evenement..
			" And Not Cle Like '[%'"..
			" And Not Cle Like '%_align%'"..
			" And Not Cle Like 'Cle_filtrage'"..
			" And Not Cle Like '%critere%'"..
			" And Not Cle Like 'numPenalisation%'"..
			" And Not Cle Like 'analyseGauche%'";
	base:Query(cmd);
	matrice.Evenement_selection = matrice.Evenement_selection or '';
	AddRowEvenement_Matrice('Evenement_selection', matrice.Evenement_selection);
	AddRowEvenement_Matrice('Evenement_support', matrice.Evenement_support);
	matrice.scriptLUA = matrice.scriptLUA or nil;
	if matrice.scriptLUA and matrice.scriptLUA:len() > 0 then
		AddRowEvenement_Matrice('scriptLUA', matrice.scriptLUA);
	end
	local strfiltre = "Ev.Code >= 0 And Ev.Code_saison = "..matrice.Saison;
	if matrice.comboActivite then
		strfiltre = strfiltre.." And Ev.Code_Activite = '"..matrice.comboActivite.."'";
	end
	if matrice.comboEntite then
		strfiltre = strfiltre.." And Ev.Code_entite = '"..matrice.comboEntite.."'";
	end
	if matrice.comboSexe then
		strfiltre = strfiltre.." And Ep.Sexe = '"..matrice.comboSexe.."'";
	end
	if matrice.selectionRegroupement:len() > 0 then
		strfiltre = strfiltre.." And Ep.Code_regroupement In("..matrice.selectionRegroupement..')';
	end
	
	AddRowEvenement_Matrice('Evenement_filtre', strfiltre);
	AddRowEvenement_Matrice('Evenement_ordre', 'Ep.Date_epreuve DESC, Ev.Code DESC');
	AddRowEvenement_Matrice('XML', 'matrice.xml');
	AddRowEvenement_Matrice('comboEntite', matrice.comboEntite);
	AddRowEvenement_Matrice('comboActivite', matrice.comboActivite);
	AddRowEvenement_Matrice('Saison', matrice.Saison);
	AddRowEvenement_Matrice('comboSexe', matrice.comboSexe);
	AddRowEvenement_Matrice('comboAbdDsq', matrice.comboAbdDsq);
	AddRowEvenement_Matrice('comboResultatPar', matrice.comboResultatPar);
	AddRowEvenement_Matrice('comboGarderInfQuota', matrice.comboGarderInfQuota);
	AddRowEvenement_Matrice('comboTypePoint', matrice.comboTypePoint);
	AddRowEvenement_Matrice('comboPrendreBloc1', matrice.comboPrendreBloc1);
	if matrice.selectionRegroupement then
		AddRowEvenement_Matrice('selectionRegroupement', matrice.selectionRegroupement);
		
	end
	if matrice.bloc2 then
		AddRowEvenement_Matrice('comboPrendreBloc2', matrice.comboPrendreBloc2);
	end
	if string.find(matrice.comboTypePoint, 'place') then
		matrice.comboGrille = dlgConfig:GetWindowName('comboGrille'):GetValue();
		AddRowEvenement_Matrice('comboGrille', matrice.comboGrille);
		local cmd = "Update Epreuve Set Code_discipline = 'CHA' Where Code_evenement = "..matrice.code_evenement.." And Code_epreuve = 1";
		base:Query(cmd);
		matrice.numPtsPresence = tonumber(dlgConfig:GetWindowName('numPtsPresence'):GetValue());
		AddRowEvenement_Matrice('numPtsPresence', matrice.numPtsPresence);
		matrice.coefDefautCourseBloc1 = tonumber(dlgConfig:GetWindowName('coefDefautCourseBloc1'):GetValue()) or 0;
		matrice.coefDefautMancheBloc1 = tonumber(dlgConfig:GetWindowName('coefDefautMancheBloc1'):GetValue()) or 0;
		matrice.coefPourcentageMaxiBloc1 = tonumber(dlgConfig:GetWindowName('coefPourcentageMaxiBloc1'):GetValue()) or 0;
		AddRowEvenement_Matrice('coefDefautCourseBloc1', matrice.coefDefautCourseBloc1);
		AddRowEvenement_Matrice('coefDefautMancheBloc1', matrice.coefDefautMancheBloc1);
		AddRowEvenement_Matrice('coefPourcentageMaxiBloc1', matrice.coefPourcentageMaxiBloc1);
		if matrice.bloc2 then
			matrice.coefDefautCourseBloc2 = tonumber(dlgConfig:GetWindowName('coefDefautCourseBloc2'):GetValue()) or 0;
			matrice.coefDefautMancheBloc2 = tonumber(dlgConfig:GetWindowName('coefDefautMancheBloc2'):GetValue()) or 0;
			matrice.coefPourcentageMaxiBloc2 = tonumber(dlgConfig:GetWindowName('coefPourcentageMaxiBloc2'):GetValue()) or 0;
			AddRowEvenement_Matrice('coefDefautCourseBloc2', matrice.coefDefautCourseBloc2);
			AddRowEvenement_Matrice('coefDefautMancheBloc2', matrice.coefDefautMancheBloc2);
			AddRowEvenement_Matrice('coefPourcentageMaxiBloc2', matrice.coefPourcentageMaxiBloc2);
		end
	else
		dlgConfig:GetWindowName('coefDefautCourseBloc1'):SetValue('');
		dlgConfig:GetWindowName('coefDefautCourseBloc2'):SetValue('');
		dlgConfig:GetWindowName('coefDefautMancheBloc1'):SetValue('');
		dlgConfig:GetWindowName('coefDefautMancheBloc2'):SetValue('');
		dlgConfig:GetWindowName('coefPourcentageMaxiBloc1'):SetValue('');
		dlgConfig:GetWindowName('coefPourcentageMaxiBloc2'):SetValue('');
		local cmd = "Update Epreuve Set Code_discipline = 'CMB' Where Code_evenement = "..matrice.code_evenement.." And Code_epreuve = 1";
		base:Query(cmd);
	end
	matrice.numPtsMini = tonumber(dlgConfig:GetWindowName('numPtsMini'):GetValue()) or 0;
	if matrice.numPtsMini > 0 then
		AddRowEvenement_Matrice('numPtsMini', matrice.numPtsMini);
	end
	matrice.numPtsMaxi = tonumber(dlgConfig:GetWindowName('numPtsMaxi'):GetValue()) or 9999;
	if matrice.numPtsMaxi > 0 and matrice.numPtsMaxi < 9999 then
		AddRowEvenement_Matrice('numPtsMaxi', matrice.numPtsMaxi);
	end
	matrice.numDepartMini = tonumber(dlgConfig:GetWindowName('numDepartMini'):GetValue()) or 0;
	if matrice.numDepartMini > 0 then
		if matrice.numDepartMini > tMatrice_Courses:GetNbRows() then
			matrice.numDepartMini = tMatrice_Courses:GetNbRows();
			dlgConfig:GetWindowName('numDepartMini'):SetValue(matrice.numDepartMini);
		end
		AddRowEvenement_Matrice('numDepartMini', matrice.numDepartMini);
	end
	AddRowEvenement_Matrice('numMinimumArrivee', tonumber(dlgConfig:GetWindowName('numMinimumArrivee'):GetValue()) or 0);
	AddRowEvenement_Matrice('coefReduction', tonumber(dlgConfig:GetWindowName('coefReduction'):GetValue()) or 0);
	AddRowEvenement_Matrice('comboTriSortie', dlgConfig:GetWindowName('comboTriSortie'):GetValue());
	AddRowEvenement_Matrice('comboTpsDuDernier', dlgConfig:GetWindowName('comboTpsDuDernier'):GetValue());
	AddRowEvenement_Matrice('imprimerColonnes', matrice.imprimerColonnes);
	AddRowEvenement_Matrice('imprimerBloc1', matrice.imprimerBloc1);
	AddRowEvenement_Matrice('imprimerBloc2', matrice.imprimerBloc2);
	AddRowEvenement_Matrice('imprimerCombiSaut', matrice.imprimerCombiSaut);
	AddRowEvenement_Matrice('comboOrientation', matrice.comboOrientation);
	AddRowEvenement_Matrice('comboPresentationCourses', dlgConfig:GetWindowName('comboPresentationCourses'):GetValue());
	AddRowEvenement_Matrice('numArretCalculApres', matrice.numArretCalculApres);
	AddRowEvenement_Matrice('numMalusAbdDsq', tonumber(dlgConfig:GetWindowName('numMalusAbdDsq'):GetValue()));
	AddRowEvenement_Matrice('numMalusAbs', tonumber(dlgConfig:GetWindowName('numMalusAbs'):GetValue()));
	
	AddRowEvenement_Matrice('texteImprimerHeader', matrice.texteImprimerHeader);
	AddRowEvenement_Matrice('texteMargeHaute1', matrice.texteMargeHaute1);
	AddRowEvenement_Matrice('texteMargeHaute2', matrice.texteMargeHaute2);
	AddRowEvenement_Matrice('texteImprimerClubLong', matrice.texteImprimerClubLong);
	AddRowEvenement_Matrice('texteFiltreSupplementaire', matrice.texteFiltreSupplementaire);
	AddRowEvenement_Matrice('texteCodeComplet', matrice.texteCodeComplet);
	AddRowEvenement_Matrice('texteFontSize', matrice.texteFontSize);
	AddRowEvenement_Matrice('texteImprimerLayer', matrice.texteImprimerLayer);
	AddRowEvenement_Matrice('texteImprimerLayerPage', matrice.texteImprimerLayerPage);
	AddRowEvenement_Matrice('texteLargeurLarge', matrice.texteLargeurLarge);
	AddRowEvenement_Matrice('texteLargeurEtroite', matrice.texteLargeurEtroite);
	AddRowEvenement_Matrice('texteImageStatCourses', matrice.texteImageStatCourses);

	AddRowEvenement_Matrice('texteImprimerDeparts', matrice.texteImprimerDeparts);
	AddRowEvenement_Matrice('texteImprimerStatCourses', matrice.texteImprimerStatCourses);
	AddRowEvenement_Matrice('texteNbColPresCourses', matrice.texteNbColPresCourses);
	AddRowEvenement_Matrice('texteComiteOrigine', matrice.texteComiteOrigine);
	AddRowEvenement_Matrice('texteLigne2Texte', matrice.texteLigne2Texte);

	matrice.ErreurMessage = 'Veuillez renseigner les donn�es manquantes : ';
	matrice.OK = ControleData();
	if matrice.OK ~= true then
		dlgConfig:MessageBox(
					matrice.ErreurMessage,
					"Erreurs � corriger : ", 
					msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION
					) 
	end
	LitMatrice();
	LitMatriceCourses(false);
	SetDatadlgConfiguration();
	SetEnableControldlgConfiguration();
end

function ControleData()
	local ok = true;
	if not matrice.ErreurMessage then
		matrice.ErreurMessage = '';
	end
	if dlgConfig:GetWindowName('Saison'):GetValue() == '' then 
		matrice.ErreurMessage = matrice.ErreurMessage..'\nSaison manquante';
		ok = false;
	end
	if dlgConfig:GetWindowName('comboEntite'):GetValue() == '' then 
		matrice.ErreurMessage = matrice.ErreurMessage..'\nCode entit� manquant';
		ok = false;
	end
	if dlgConfig:GetWindowName('comboActivite'):GetValue() == '' then 
		matrice.ErreurMessage = matrice.ErreurMessage..'\nCode activit� manquant';
		ok = false;
	end
	if dlgConfig:GetWindowName('comboSexe'):GetValue() == '' then 
		matrice.ErreurMessage = matrice.ErreurMessage..'\nSexe des coureurs non renseign� !!';
		ok = false;
	end
	if dlgConfig:GetWindowName('comboPrendreBloc1'):GetValue() == '' then 
		matrice.ErreurMessage = matrice.ErreurMessage..'\nQuoi prendre en compte pour le bloc 1 ??';
		ok = false;
	end
	if not matrice.bloc2 then
		if dlgConfig:GetWindowName('comboTypePoint'):GetValue() == 'Points place' then
			if dlgConfig:GetWindowName('coefDefautCourseBloc1'):GetValue() == '' then
				matrice.ErreurMessage = matrice.ErreurMessage..'\nCoef par d�faut des courses du bloc 1 ??';
				ok = false;
			end
		end
	elseif dlgConfig:GetWindowName('comboPrendreBloc2'):GetValue() == '' then 
		matrice.ErreurMessage = matrice.ErreurMessage..'\nQuoi prendre en compte pour le bloc 2 ??';
		ok = false;
		if dlgConfig:GetWindowName('comboTypePoint'):GetValue() == 'Points place' then
			if dlgConfig:GetWindowName('coefDefautCourseBloc2'):GetValue() == '' then
				matrice.ErreurMessage = matrice.ErreurMessage..'\nCoef par d�faut des courses du bloc 2 ??';
				ok = false;
			end
		end
	end
	if dlgConfig:GetWindowName('comboTpsDuDernier'):GetValue() == 'Oui' and dlgConfig:GetWindowName('comboTypePoint'):GetValue() == 'Points place' then
		local malus_abd = tonumber(dlgConfig:GetWindowName('numMalusAbdDsq'):GetValue()) or -1;
		if malus_abd > 10 then
			matrice.ErreurMessage = matrice.ErreurMessage..'\nLe malus des ABD/DSQ ne peut pas �tre en points place !!';
			ok = false;
		end
		local malus_abs = tonumber(dlgConfig:GetWindowName('numMalusAbs'):GetValue()) or -1;
		if malus_abs > 10 then
			matrice.ErreurMessage = matrice.ErreurMessage..'\nLe malus des ABS ne peut pas �tre en points place !!';
			ok = false;
		end
	end
	return ok;
end

function SetEnableControldlgConfiguration();
	dlgConfig:GetWindowName('numMalusAbdDsq'):Enable(Eval(matrice.comboTpsDuDernier,'Oui'));
	dlgConfig:GetWindowName('numMalusAbs'):Enable(Eval(matrice.comboTpsDuDernier,'Oui'));
	dlgConfig:GetWindowName('comboGrille'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
	dlgConfig:GetWindowName('numPtsPresence'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
	dlgConfig:GetWindowName('numMinimumArrivee'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
	dlgConfig:GetWindowName('coefReduction'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
	dlgConfig:GetWindowName('numPtsMini'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
	dlgConfig:GetWindowName('numPtsMaxi'):Enable(Eval(matrice.comboEntite,'FFS'));
	dlgConfig:GetWindowName('coefDefautCourseBloc1'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
	dlgConfig:GetWindowName('coefDefautMancheBloc1'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
	dlgConfig:GetWindowName('coefPourcentageMaxiBloc1'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
	if matrice.bloc2 == true then
		dlgConfig:GetWindowName('coefDefautCourseBloc2'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
		dlgConfig:GetWindowName('coefDefautMancheBloc2'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
		dlgConfig:GetWindowName('comboPrendreBloc2'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
		dlgConfig:GetWindowName('coefPourcentageMaxiBloc2'):Enable(Eval(matrice.comboTypePoint, 'Points place'));
	else
		dlgConfig:GetWindowName('coefDefautCourseBloc2'):Enable(false);
		dlgConfig:GetWindowName('coefDefautMancheBloc2'):Enable(false);
		dlgConfig:GetWindowName('comboPrendreBloc2'):Enable(false);
		dlgConfig:GetWindowName('coefPourcentageMaxiBloc2'):Enable(false);
		if Eval(matrice.comboTypePoint, 'Points place') then
			if string.find(matrice.comboPrendreBloc1, '1%.')then
				dlgConfig:GetWindowName('coefDefautMancheBloc1'):Enable(false);
			elseif string.find(matrice.comboPrendreBloc1, '2%.') then
				dlgConfig:GetWindowName('coefDefautCourseBloc1'):Enable(false);
				dlgConfig:GetWindowName('coefDefautMancheBloc1'):Enable(false);
			end
		end
	end
end

function SetDatadlgConfiguration()
	dlgConfig:GetWindowName('Titre'):SetValue(matrice.Titre);
	dlgConfig:GetWindowName('Saison'):SetValue(matrice.Saison);
	dlgConfig:GetWindowName('comboActivite'):SetValue(matrice.comboActivite);
	dlgConfig:GetWindowName('comboEntite'):SetValue(matrice.comboEntite);
	dlgConfig:GetWindowName('comboSexe'):SetValue(matrice.comboSexe);
	dlgConfig:GetWindowName('comboGarderInfQuota'):SetValue(matrice.comboGarderInfQuota);
	dlgConfig:GetWindowName('comboTypePoint'):SetValue(matrice.comboTypePoint);
	if matrice.numDepartMini > 0 then
		dlgConfig:GetWindowName('numDepartMini'):SetValue(matrice.numDepartMini);
	else
		dlgConfig:GetWindowName('numDepartMini'):SetValue('');
	end
	dlgConfig:GetWindowName('comboAbdDsq'):SetValue(matrice.comboAbdDsq);
	dlgConfig:GetWindowName('comboTpsDuDernier'):SetValue(matrice.comboTpsDuDernier);
	if matrice.comboTpsDuDernier == 'Oui' and matrice.numMalusAbdDsq > 0 then
		dlgConfig:GetWindowName('numMalusAbdDsq'):SetValue(matrice.numMalusAbdDsq);
	else
		dlgConfig:GetWindowName('numMalusAbdDsq'):SetValue('');
	end
	if matrice.comboTpsDuDernier == 'Oui' and matrice.numMalusAbs > 0 then
		dlgConfig:GetWindowName('numMalusAbs'):SetValue(matrice.numMalusAbs);
	else
		dlgConfig:GetWindowName('numMalusAbs'):SetValue('');
	end
	dlgConfig:GetWindowName('comboResultatPar'):SetValue(matrice.comboResultatPar);
	dlgConfig:GetWindowName('comboTriSortie'):SetValue(matrice.comboTriSortie);
	dlgConfig:GetWindowName('comboPresentationCourses'):SetValue(matrice.comboPresentationCourses);
	dlgConfig:GetWindowName('comboOrientation'):SetValue(matrice.comboOrientation);
	matrice.numArretCalculApres = matrice.numArretCalculApres or 0;
	if matrice.numArretCalculApres > 0 then
		dlgConfig:GetWindowName('numArretCalculApres'):SetSelection(matrice.numArretCalculApres);
	end

	
	dlgConfig:GetWindowName('numPtsPresence'):SetValue(matrice.numPtsPresence);
	for i = 1, 2 do
		dlgConfig:GetWindowName('comboPrendreBloc'..i):SetValue(matrice['comboPrendreBloc'..i]);
		dlgConfig:GetWindowName('coefPourcentageMaxiBloc'..i):SetValue(matrice['coefPourcentageMaxiBloc'..i]);
		dlgConfig:GetWindowName('coefDefautCourseBloc'..i):SetValue(matrice['coefDefautCourseBloc'..i]);
		dlgConfig:GetWindowName('coefDefautMancheBloc'..i):SetValue(matrice['coefDefautMancheBloc'..i]);
	end

	if string.find(matrice.comboTypePoint, 'place') then
		if matrice.numMinimumArrivee > 0 then
			dlgConfig:GetWindowName('numMinimumArrivee'):SetValue(matrice.numMinimumArrivee);
		end
		if matrice.coefReduction > 0 then
			dlgConfig:GetWindowName('coefReduction'):SetValue(matrice.coefReduction);
		end
		dlgConfig:GetWindowName('numPtsPresence'):SetValue(matrice.numPtsPresence);
		if matrice.numPtsMini > 0 then
			dlgConfig:GetWindowName('numPtsMini'):SetValue(matrice.numPtsMini);
		end
		if matrice.comboGrille:len() > 0 then
			dlgConfig:GetWindowName('comboGrille'):SetValue(matrice.comboGrille);
		else
			app.GetAuiFrame():MessageBox(
				"N'oubliez pas de renseigner la grille de points � prendre en compte !!", 
				"Grille de points",
				msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
		end
	end
	if matrice.numPtsMaxi < 9999 then
		dlgConfig:GetWindowName('numPtsMaxi'):SetValue(matrice.numPtsMaxi);
	end
	SetEnableControldlgConfiguration();
end

-- point d'entr�e du script par le C++
function OnConfiguration(cparams)
	matrice = {};
	if cparams then
		matrice.code_evenement = cparams.code_evenement;	-- matrice.code_evenement = variable globale
	else
		return false;
	end
	scrip_version = '5.93';
	-- v�rification de l'existence d'une version plus r�cente du script.
	-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2
	if app.GetVersion() >= '4.4c' then 		-- d�but d'implementation de la fonction UpdateRessource
		indice_return = 2;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	end
	local updatefile = './tmp/updatesPG.txt';
	if app.FileExists(updatefile) then
		local f = io.open(updatefile, 'r')
		for lines in f:lines() do
			alire = lines;
		end
		io.close(f);
		app.RemoveFile(updatefile);
		app.LaunchDefaultEditor('./'..alire);
	end


	local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
	local version = curl.AsyncGET(wnd.GetParentFrame(), url);
	indice_return = 2;
	matrice.dlgPosit = {};
	matrice.dlgPosit.width = display:GetSize().width;
	matrice.dlgPosit.height = display:GetSize().height -30;
	matrice.dlgPosit.x = 1;
	matrice.dlgPosit.y = 1;
	base = base or sqlBase.Clone();
	code_coureur_pour_debug = "FFS2662170";		-- provoque tous les affichages pour d�bug propres � ce Code_coureur
	matrice.debug = false;
	if matrice.debug == false then
		code_coureur_pour_debug = '';
	end
	tEvenement = base:GetTable('Evenement');
	tEpreuve_Alpine = base:GetTable('Epreuve_Alpine');
	tEvenement_Challenge = base:GetTable('Evenement_Challenge');
	tEvenement_Matrice = base:GetTable('Evenement_Matrice');
	tSaison = base:GetTable('Saison');
	tEntite = base:GetTable('Entite');
	tCorrespondance = base:GetTable('Correspondance');
	tDiscipline = base:GetTable('Discipline');
	tComite = base:GetTable('Comite');
	tClub = base:GetTable('Club');
	tType_Classement = base:GetTable('Type_Classement');
	tGrille_Point_Place = base:GetTable('Grille_Point_Place');
	tPlace_Valeur = base:GetTable('Place_Valeur');
	tRegroupement = base:GetTable('Regroupement');
	tResultat = base:GetTable('Resultat');
	tResultat_Manche = base:GetTable('Resultat_Manche');
	tListe = base:GetTable('Liste');
	tActivite = base:GetTable('Activite');
	
	local xml_config = app.GetPath()..'/challenge/matrice_config.xml';
	if not app.FileExists(xml_config) then
		CreateXMLConfig();
	end
	local xml_layers = app.GetPath()..'/edition/layer.perso.xml';
	if not app.FileExists(xml_layers) then
		CreateXMLLayerPerso(xml_layers);
	end
	VerifNodePodium();
	XML = app.GetPath().."/challenge/matrice.xml";
	doc = xmlDocument.Create(XML);
	local cmd = 'Select * From Evenement_Matrice Where Code_evenement = '..matrice.code_evenement..' Order By Cle';
	base:TableLoad(tEvenement_Matrice, cmd);
	matrice.Evenement_selection = GetValue('Evenement_selection', '');
	activite = {'ALP', 'BIATH', 'FOND'};
	sexe = {'F', 'M'};
	matrice.label_matrice = ' du Challenge / Combin� n� '..matrice.code_evenement..'   (version '..scrip_version..')';
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..matrice.code_evenement)
	matrice.code_activite = tEvenement:GetCell('Code_activite', 0);
	matrice.Titre = tEvenement:GetCell('Nom', 0);
	matrice.Saison = tEvenement:GetCell('Code_saison', 0);
	base:TableLoad(tSaison, 'Select * From Saison Where Code > 0 Order By Code DESC');
	base:TableLoad(tEntite, "Select * From Entite Where Code In('FFS', 'FIS') Order By Code DESC");
	base:TableLoad(tActivite, "Select * From Activite Where Code In('ALP')");
	CreateTablesCombo();
	AffichedlgConfiguration()
end
