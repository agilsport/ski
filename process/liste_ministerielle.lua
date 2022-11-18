-- Matrices / Challenges et Combinés pour skiFFS
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function ReplaceTableEnvironnement(t, name)		-- replace la table créée dans l'environnement de la base de donnée pour éviter les memory leaks
	if type(t) ~= 'userdata' then
		return;
	end
	t:SetName(name);
	if base:GetTable(name) ~= nil then
		base:RemoveTable(name);
	end
	base:AddTable(t);
end

function GetNode()	-- lecture d'une valeur du XML 
	local node = nil;
	if listeMinisterielle.comboNiveau == 'Relève' then
		listeMinisterielle.comboNiveau = 'Releve';
	end
	if string.find(listeMinisterielle.comboNiveau, 'CNE') then
		listeMinisterielle.comboNiveau = 'CNE';
	end
	if string.find(listeMinisterielle.comboNiveau, 'CIE') then
		listeMinisterielle.comboNiveau = 'CIE';
	end
	local anneexml = 'annee'..listeMinisterielle.indexAnneeDebut+1;
	local strnode = 'root/'..listeMinisterielle.comboNiveau..'/'..listeMinisterielle.comboSexe..'/'..anneexml;
	if doc:FindFirst(strnode) then
		node = doc:FindFirst(strnode);
	end
	return node;
end

function GetNodex(niveau, sexe, idxannee)	-- lecture d'une valeur du XML 
	if niveau == 'Relève' then
		niveau = 'Releve';
	end
	if string.find(niveau, 'CNE') then
		niveau = 'CNE';
	end
	if string.find(niveau, 'CIE') then
		niveau = 'CIE';
	end
	local node = nil;
	local anneexml = 'annee'..listeMinisterielle.indexAnneeDebut+1;
	local strnode = 'root/'..niveau..'/'..sexe..'/annee'..idxannee;
	if doc:FindFirst(strnode) then
		node = doc:FindFirst(strnode);
	end
	return node;
end

function SetNodex(niveau, sexe, idxannee)
end

function ChargeDisciplines()	-- charge les disciplines de l'activité pour la saison choisie.
	local suffixe = '';
	suffixe = " And Not Code LIKE 'P%' And Not Code LIKE 'TE%' And Not Code LIKE 'KO%' ";
	local cmd = "Select * From Discipline Where Code_activite = 'ALP' And Code_entite = 'FIS' And Code_saison = '"..listeMinisterielle.Saison.."'"..suffixe.." ORDER BY Ordre";;
	base:TableLoad(Discipline, cmd);
	if Discipline:GetNbRows() > 0 then
		local row = Discipline:AddRow();
		Discipline:SetCell('Code_activite', row, Discipline:GetCell('Code_activite', 0));
		Discipline:SetCell('Code_entite', row, Discipline:GetCell('Code_entite', 0));
		Discipline:SetCell('Code_saison', row, Discipline:GetCell('Code_saison', 0));
		Discipline:SetCell('Code_origine', row, Discipline:GetCell('Code_origine', 0));
		Discipline:SetCell('Code', row, 'TEC');
		Discipline:SetCell('Ordre', row, 20);
		Discipline:SetCell('Officiel', row, 'N');
		Discipline:SetCell('Code_international', row, 'TEC');
		Discipline:SetCell('Libelle', row, 'Discipline fictive Technique');
		row = Discipline:AddRow();
		Discipline:SetCell('Code_activite', row, Discipline:GetCell('Code_activite', 0));
		Discipline:SetCell('Code_entite', row, Discipline:GetCell('Code_entite', 0));
		Discipline:SetCell('Code_saison', row, Discipline:GetCell('Code_saison', 0));
		Discipline:SetCell('Code_origine', row, Discipline:GetCell('Code_origine', 0));
		Discipline:SetCell('Code', row, 'VIT');
		Discipline:SetCell('Ordre', row, 21);
		Discipline:SetCell('Officiel', row, 'N');
		Discipline:SetCell('Code_international', row, 'VIT');
		Discipline:SetCell('Libelle', row, 'Discipline fictive Vitesse');
	end
end

function SetCriteres()
	-- Classement_Coureur est construit
	-- étude du critère 1 : discipline technique
	local c1 = dlgConfig:GetWindowName('gxpremiers1'):GetValue();
	c1 = tonumber(c1) or 0;
	local c2 = dlgConfig:GetWindowName('gxpremiers2'):GetValue();
	c2 = tonumber(c2) or 0;
		
	-- étude du critère 2 : discipline vitesse
	local c3 = dlgConfig:GetWindowName('gxpremiers3'):GetValue();
	c3 = tonumber(c3) or 0;
	
	-- étude du critère 3 : 1 discipline technique + 1 discipline vitesse
	local c4 = dlgConfig:GetWindowName('gxpremiers4'):GetValue();
	c4 = tonumber(c4) or 0;
	local c5 = dlgConfig:GetWindowName('gxpremiers5'):GetValue();
	c5 = tonumber(c5) or 0;
	
	-- Col1 = les Pts Techniques sont sélectionnés
	-- Col2 = les Pts Vitesses sont sélectionnés
	-- Col3 = les Pts Techniques par année sont sélectionnés
	-- Col4 = les Pts Vitesses par année sont sélectionnés
	-- Col5 = on prend 1 vitesse + 1 technique
	for row = 0, Classement_Coureur:GetNbRows() -1 do
		Classement_Coureur:SetCell('Col1', row, 0);
		Classement_Coureur:SetCell('Col2', row, 0);
		Classement_Coureur:SetCell('Col3', row, 0);
		Classement_Coureur:SetCell('Col4', row, 0);
		Classement_Coureur:SetCell('Col5', row, 0);
		local clt_tech = Classement_Coureur:GetCellInt('Clt_technique', row, 10000);
		local clt_vitesse = Classement_Coureur:GetCellInt('Clt_vitesse', row, 10000);
		local clt_tech_annee = Classement_Coureur:GetCellInt('Clt_technique_annee', row, 10000);
		local clt_vitesse_annee = Classement_Coureur:GetCellInt('Clt_vitesse_annee', row, 10000);
		local critere = 0;
		-- technique
		if c1 > 0 then
			if dlgConfig:GetWindowName('chk1'):GetValue() == true then	-- la première ligne est par année 
				if clt_tech_annee > 0 and clt_tech_annee  <= c1 then
					critere = critere + 1;
					Classement_Coureur:SetCell('Col3', row, 1);
				end
			else
				if clt_tech > 0 and clt_tech <= c1 then
					critere = critere + 1;
					Classement_Coureur:SetCell('Col1', row, 1);
				end
			end
		end
		if c2 > 0 then
			if dlgConfig:GetWindowName('chk2'):GetValue() == true then	-- la deuxième ligne est par année on mettra 
				if clt_tech_annee > 0 and clt_tech_annee <= c2 then
					critere = critere + 1;
					Classement_Coureur:SetCell('Col3', row, 1);
				end
			else
				if clt_tech > 0 and clt_tech <= c2 then
					critere = critere + 1;
					Classement_Coureur:SetCell('Col1', row, 1);
				end
			end
		end

		if c3 > 0 then
			if clt_vitesse > 0 and clt_vitesse <= c3 then
				critere = critere + 1;
				Classement_Coureur:SetCell('Col2', row, 1);
			end
		end
		
		if c4 > 0 and c5 > 0 then	-- 1 discipline vitesse ET 1 discipline technique
			local est_critere = 1;
			if dlgConfig:GetWindowName('chk4'):GetValue() == true and dlgConfig:GetWindowName('chk5'):GetValue() == true then
				if clt_vitesse_annee > c4 then
					est_critere = 0;
				end
				if clt_tech_annee > c5 then
					est_critere = 0;
				end
				if est_critere == 1 then
					critere = critere + 1;
					Classement_Coureur:SetCell('Col3', row, 1);
					Classement_Coureur:SetCell('Col4', row, 1);
					Classement_Coureur:SetCell('Col5', row, 1);
				end
			else
				if clt_vitesse > c4 then
					est_critere = 0;
				end
				if clt_tech > c5 then
					est_critere = 0;
				end
				if est_critere == 1 then
					critere = critere + 1;
					Classement_Coureur:SetCell('Col1', row, 1);
					Classement_Coureur:SetCell('Col2', row, 1);
					Classement_Coureur:SetCell('Col5', row, 1);
				end
			end
		end
		Classement_Coureur:SetCell('Est_critere', row, critere);
	end
end

function SetClassement_Coureur_Annee()
	Classement_Coureur:OrderBy('Pts_SL');
	Classement_Coureur:SetRanking('Clt_SL_Annee', 'Pts_SL', '')
	Classement_Coureur:OrderBy('Pts_GS');
	Classement_Coureur:SetRanking('Clt_GS_Annee', 'Pts_GS', '')
	Classement_Coureur:OrderBy('Pts_DH');
	Classement_Coureur:SetRanking('Clt_DH_Annee', 'Pts_DH', '')
	Classement_Coureur:OrderBy('Pts_SG');
	Classement_Coureur:SetRanking('Clt_SG_Annee', 'Pts_SG', '')
	
end

function BuildClassementCoureur()	-- construction de la table des classements
	local sexe = 'M';
	if listeMinisterielle.comboSexe == 'Dames' then
		sexe = 'F';
	end
	local cmd = "SELECT cou.Code_coureur, 0 Est_critere, cou.Code_nation Nation, cou.Code_comite Comite, CONCAT(cou.Nom, ' ',cou.Prenom) Identite,  DATE_FORMAT(cou.Naissance,'%Y') An, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IASL') Pts_SL, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IASL') Clt_SL, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IAGS') Pts_GS, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IAGS') Clt_GS, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IASG') Pts_SG, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IASG') Clt_SG, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IADH') Pts_DH, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IADH') Clt_DH "..
		"FROM Coureur cou "..
		"WHERE cou.Code_coureur LIKE 'FIS%' And cou.Sexe ='"..sexe.."'";
	Classement_Coureur = base:TableLoad(cmd);
	Classement_Coureur:OrderBy('Clt_technique');
	ReplaceTableEnvironnement(Classement_Coureur, 'Classement_Coureur');
	Classement_Coureur:AddColumn({ name = 'Pts_technique', label = 'Pts_technique', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_technique', label = 'Clt_technique', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Pts_vitesse', label = 'Pts_vitesse', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_vitesse', label = 'Clt_vitesse', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_SL_Annee', label = 'Clt_SL_Annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_GS_Annee', label = 'Clt_GS_Annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_DH_Annee', label = 'Clt_DH_Annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_SG_Annee', label = 'Clt_SG_Annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Pts_technique_annee', label = 'Pts_technique_annee', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_technique_annee', label = 'Clt_technique_annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Pts_vitesse_annee', label = 'Pts_vitesse_annee', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_vitesse_annee', label = 'Clt_vitesse_annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Col1', label = 'Col1', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Col2', label = 'Col2', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Col3', label = 'Col3', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Col4', label = 'Col4', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Col5', label = 'Col5', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:OrderBy('Clt_technique DESC');
	last_clt_technique = Classement_Coureur:GetCellInt('Clt_technique', 0, -1);
	Classement_Coureur:OrderBy('Clt_vitesse DESC');
	last_clt_vitesse = Classement_Coureur:GetCellInt('Clt_vitesse', 0, -1);
	for row = Classement_Coureur:GetNbRows() -1, 0, -1 do
		local cltSL = Classement_Coureur:GetCellInt('Clt_SL', row, -1);
		local cltGS = Classement_Coureur:GetCellInt('Clt_GS', row, -1);
		local cltSG = Classement_Coureur:GetCellInt('Clt_SG', row, -1);
		local cltDH = Classement_Coureur:GetCellInt('Clt_DH', row, -1);
		if cltSL < 0 and cltGS < 0 and cltSG < 0 and cltDH < 0 then
			Classement_Coureur:RemoveRowAt(row);
		end
	end

	listeMinisterielle.filter_annees = "'-1'";
	num_annee_debut = tonumber(dlgConfig:GetWindowName('comboAnneeDebut'):GetValue()) or 0;
	num_annee_fin = tonumber(dlgConfig:GetWindowName('comboAnneeFin'):GetValue()) or 0;
	for i = num_annee_debut, num_annee_fin do
		listeMinisterielle.filter_annees = listeMinisterielle.filter_annees..",'"..tostring(i).."'";
	end
	listeMinisterielle.filter_annees = "$(An):In("..listeMinisterielle.filter_annees..")";
	Classement_Coureur:Filter()

	for row = 0, Classement_Coureur:GetNbRows()-1 do
		local cltSL = Classement_Coureur:GetCellInt('Clt_SL', row, 10000);
		local ptsSL = Classement_Coureur:GetCellDouble('Pts_SL', row, 10000);
		local cltGS = Classement_Coureur:GetCellInt('Clt_GS', row, 10000);
		local ptsGS = Classement_Coureur:GetCellDouble('Pts_GS', row, 10000);
		local cltSG = Classement_Coureur:GetCellInt('Clt_SG', row, 10000);
		local cltSGannee = Classement_Coureur:GetCellInt('Clt_SG_Annee', row, 10000);
		local ptsSG = Classement_Coureur:GetCellDouble('Pts_SG', row, 10000);
		local cltDH = Classement_Coureur:GetCellInt('Clt_DH', row, 10000);
		local cltDHannee = Classement_Coureur:GetCellInt('Clt_DH_Annee', row, 10000);
		local ptsDH = Classement_Coureur:GetCellDouble('Pts_DH', row, 10000);
		local cltTect = math.min(cltSL, cltGS);
		if cltTect < 10000 then
			if cltSL < cltGS then
				Classement_Coureur:SetCell('Pts_technique', row, ptsSL);
				Classement_Coureur:SetCell('Pts_technique_annee', row, ptsSL);
				Classement_Coureur:SetCell('Clt_technique', row, cltSL);
			else
				Classement_Coureur:SetCell('Pts_technique', row, ptsGS);
				Classement_Coureur:SetCell('Pts_technique_annee', row, ptsGS);
				Classement_Coureur:SetCell('Clt_technique', row, cltGS);
			end
		end
		local cltVit = math.min(cltSG, cltDH);
		if cltVit < 10000 then
			if cltSG < cltDH then
				Classement_Coureur:SetCell('Pts_vitesse', row, ptsSG);
				Classement_Coureur:SetCell('Pts_vitesse_annee', row, ptsSG);
				Classement_Coureur:SetCell('Clt_vitesse', row, cltSG);
			else
				Classement_Coureur:SetCell('Pts_vitesse', row, ptsDH);
				Classement_Coureur:SetCell('Pts_vitesse_annee', row, ptsDH);
				Classement_Coureur:SetCell('Clt_vitesse', row, cltDH);
			end
		end
	end
	Classement_Coureur:Filter(listeMinisterielle.filter_annees, true);
	if listeMinisterielle.par_annee == true then
		--Classement_Coureur:Filter(listeMinisterielle.filter_annees, true);
		SetClassement_Coureur_Annee();
		for row = 0, Classement_Coureur:GetNbRows()-1 do
			local cltSLannee = Classement_Coureur:GetCellInt('Clt_SL_Annee', row, 10000);
			local cltGSannee = Classement_Coureur:GetCellInt('Clt_GS_Annee', row, 10000);
			local cltSGannee = Classement_Coureur:GetCellInt('Clt_SG_Annee', row, 10000);
			local cltDHannee = Classement_Coureur:GetCellInt('Clt_DH_Annee', row, 10000);
			local cltTectannee = math.min(cltSLannee, cltGSannee);
			local cltVitannee = math.min(cltSGannee, cltDHannee);
			if cltTectannee < 10000 then
				if cltSLannee < cltGSannee then
					Classement_Coureur:SetCell('Clt_technique_annee', row, cltSLannee);
				else
					Classement_Coureur:SetCell('Clt_technique_annee', row, cltGSannee);
				end
			end
			if cltVitannee < 10000 then
				if cltSGannee < cltDHannee then
					Classement_Coureur:SetCell('Clt_vitesse_annee', row, cltSGannee);
				else
					Classement_Coureur:SetCell('Clt_vitesse_annee', row, cltDHannee);
				end
			end
		end
	end
	Classement_Coureur:Filter("$(Nation):In('FRA')", true);

	SetCriteres();
	OnPrintAnalyse();
end

function OnPrintAnalyse()
	-- Creation du Report
	listeMinisterielle.Critere1  = 'Néant';
	listeMinisterielle.Critere2  = 'Néant';
	listeMinisterielle.Critere3  = 'Néant';
	local x1 = dlgConfig:GetWindowName('gxpremiers1'):GetValue();
	local x2 = dlgConfig:GetWindowName('gxpremiers2'):GetValue();
	local x3 = dlgConfig:GetWindowName('gxpremiers3'):GetValue();
	local x4 = dlgConfig:GetWindowName('gxpremiers4'):GetValue();
	local x5 = dlgConfig:GetWindowName('gxpremiers5'):GetValue();
	if x1 ~= '' then
		listeMinisterielle.Critere1 = "être dans les "..x1..' mondiaux';
		if dlgConfig:GetWindowName('chk1'):GetValue() == true then
			listeMinisterielle.Critere1 = listeMinisterielle.Critere1.." de son année ";
		end
	end
	if x2 ~= '' then
		listeMinisterielle.Critere1 = listeMinisterielle.Critere1.. ' OU être dans les '..x2..' mondiaux';
	end
	if x3 ~= '' then
		listeMinisterielle.Critere2 = "être dans les "..x3..' mondiaux';
	end
	if x4 ~= '' then
		listeMinisterielle.Critere3 = "être dans les "..x4..' mondiaux';
		if dlgConfig:GetWindowName('chk4'):GetValue() == true then
			listeMinisterielle.Critere3 = listeMinisterielle.Critere3.." de son année en Vitesse";
		else
			listeMinisterielle.Critere3 = listeMinisterielle.Critere3.." en Vitesse";
		end
		listeMinisterielle.Critere3 = listeMinisterielle.Critere3.." ET être dans les ";
		listeMinisterielle.Critere3 = listeMinisterielle.Critere3..x5..' mondiaux';
		if dlgConfig:GetWindowName('chk5'):GetValue() == true then
			listeMinisterielle.Critere3 = listeMinisterielle.Critere3.." de son année en Technique";
		else
			listeMinisterielle.Critere3 = listeMinisterielle.Critere3.." en Technique";
		end
	end
	Classement_Coureur:OrderBy('Est_critere DESC, Pts_technique')
	-- Classement_Coureur:Snapshot('Classement_Coureur.db3');
	report = wnd.LoadTemplateReportXML({
		xml = './process/liste_ministerielle.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'printanalyse',
		title = "Edition des coureurs selon les critères",
		base = base,
		body = Classement_Coureur,
		margin_first_top = 120,
		margin_first_left = 100,
		margin_first_right = 100,
		margin_first_bottom = 100,
		margin_top = 120,
		margin_left = 100,
		margin_right = 100,
		margin_bottom = 100,
		paper_orientation = 'landscape',
		params = {Niveau = ' - Pour le niveau : '..listeMinisterielle.comboNiveau, Liste = listeMinisterielle.comboListe, Version = scrip_version, Critere1 = listeMinisterielle.Critere1, Critere2 = listeMinisterielle.Critere2, Critere3 = listeMinisterielle.Critere3, X1 = x1, X2 = x2, X3 = x3, X4 = x4, X5 = x5, AnneeDebut = num_annee_debut, AnneeFin = num_annee_fin}
	});
	-- report:SetZoom(10)
end

function OnSavedlgBackoffice()
	for i = 1, 10 do
		local c1 = '';
		local c2 = '';
		local c3 = '';
		node = GetNodex(listeMinisterielle.comboNiveau, listeMinisterielle.comboSexe, i);
		local col1 = dlgBackoffice:GetWindowName('unetechniquea'..i):GetValue();
		local col2 = dlgBackoffice:GetWindowName('unetechniqueb'..i):GetValue();
		local col3 = dlgBackoffice:GetWindowName('unevitesse'..i):GetValue();
		local col4 = dlgBackoffice:GetWindowName('deuxvitessea'..i):GetValue();
		local col5 = dlgBackoffice:GetWindowName('deuxvitesseb'..i):GetValue();
		local col6 = dlgBackoffice:GetWindowName('deuxtechniquea'..i):GetValue();
		local col7 = dlgBackoffice:GetWindowName('deuxtechniqueb'..i):GetValue();
		if col1 == '' and col2 == '' then
			c1 = '-1';
		else
			if col1 ~= '' then
				c1 = col1..'a';
			end
			if col2 ~= '' then
				if c1:len() > 0 then
					c1 = c1..',';
				end
				c1 = c1..col2;
			end
		end
		if col3 == '' then
			c2 = '-1';
		else
			c2 = col3;
		end
		if (col4 == '' and col5 == '') or (col6 == '' and col7 == '') then
			c3 = '-1';
		end
		if col4 ~= '' and col6 ~= '' then	-- col4 et col 6 = par année d'âge
			c3 = col4..'a,'..col6..'a';
		end
		if col5 ~= '' and col7 ~= '' then	-- col5 et col 7 = clt modial
			c3 = col5..','..col7;
		end
		if c1 == '' then
			c1 = '-1';
		end
		if c2 == '' then
			c2 = '-1';
		end
		if c3 == '' then
			c3 = '-1';
		end
		node:ChangeAttribute('c1', c1);
		node:ChangeAttribute('c2', c2);
		node:ChangeAttribute('c3', c3);
		doc:SaveFile();
		doc:Delete();
		XML = app.GetPath().."/process/liste_ministerielle.xml";
		doc = xmlDocument.Create(XML);
	end
	SetDataAnalyse();
end

function OnSavedlgBackofficeOLD()
	for i = 1, 10 do
		local c1 = '';
		local c2 = '';
		local c3 = '';
		node = GetNodex(listeMinisterielle.comboNiveau, listeMinisterielle.comboSexe, i);
		local col1 = dlgBackoffice:GetWindowName('unetechniquea'..i):GetValue();
		local col2 = dlgBackoffice:GetWindowName('unetechniqueb'..i):GetValue();
		local col3 = dlgBackoffice:GetWindowName('unevitesse'..i):GetValue();
		local col4 = dlgBackoffice:GetWindowName('deuxvitessea'..i):GetValue();
		local col5 = dlgBackoffice:GetWindowName('deuxvitesseb'..i):GetValue();
		local col6 = dlgBackoffice:GetWindowName('deuxtechniquea'..i):GetValue();
		local col7 = dlgBackoffice:GetWindowName('deuxtechniqueb'..i):GetValue();
		if col1 == '' and col2 == '' then
			c1 = '-1';
		else
			if col1 ~= '' then
				c1 = col1..'a';
			end
			if col2 ~= '' then
				if c1:len() > 0 then
					c1 = c1..',';
				end
				c1 = c1..col2;
			end
		end
		if col3 == '' then
			c2 = '-1';
		else
			c2 = col2;
		end
		if (col4 == '' and col5 == '') or (col6 == '' and col7 == '') then
			c3 = '-1';
		end
		if col4 ~= '' and col6 ~= '' then	-- col4 et col 6 = par année d'âge
			c3 = col4..'a,'..col6;
		end
		if col5 ~= '' and col7 ~= '' then	-- col5 et col 7 = clt modial
			c3 = col5..','..col7;
		end
		if c1 == '' then
			c1 = '-1';
		end
		if c2 == '' then
			c2 = '-1';
		end
		if c3 == '' then
			c3 = '-1';
		end
		node:ChangeAttribute('c1', c1);
		node:ChangeAttribute('c2', c2);
		node:ChangeAttribute('c3', c3);
		doc:SaveFile();
		doc:Delete();
		XML = app.GetPath().."/process/liste_ministerielle.xml";
		doc = xmlDocument.Create(XML);
	end
	SetDataAnalyse();
end

function SetAnalyseGauche(c1,c2,c3)	-- c1, c2 et c3 sont des valeurs de critères
	dlgConfig:GetWindowName('chk1'):SetValue(false);
	dlgConfig:GetWindowName('chk2'):SetValue(false);
	dlgConfig:GetWindowName('chk3'):SetValue(false);
	dlgConfig:GetWindowName('chk4'):SetValue(false);
	dlgConfig:GetWindowName('chk5'):SetValue(false);
	local tc1 = c1:Split(',');
	listeMinisterielle.par_annee = false;
	for i = 1, #tc1 do
		if string.find(tc1[i], 'a') then	-- on est par année d'âge
			listeMinisterielle.par_annee = true;
			tc1[i] = string.gsub(tc1[i], "%D", "");
			dlgConfig:GetWindowName('chk1'):SetValue(true);
		end
		if tc1[i] ~= '-1' then
			dlgConfig:GetWindowName('gxpremiers'..i):SetValue(tc1[i]);
		end
	end
	local tc2 = c2:Split(',');
	for i = 1, #tc2 do
		if tc2[i] ~= '-1' then
			dlgConfig:GetWindowName('gxpremiers'..i+2):SetValue(tc2[i]);
		end
	end
	local tc3 = c3:Split(',');
	if tc3[1] ~= '-1' then
		if string.find(tc3[1], 'a') then	-- on est par année d'âge
			listeMinisterielle.par_annee = true;
			dlgConfig:GetWindowName('chk4'):SetValue(true);
		end
		tc3[1] = string.gsub(tc3[1], "%D", "");
		if tc3[1] ~= '-1' then
			dlgConfig:GetWindowName('gxpremiers4'):SetValue(tc3[1]);
		end
	end
	if tc3[2] and tc3[2] ~= '-1' then
		if string.find(tc3[2], 'a') then	-- on est par année d'âge
			listeMinisterielle.par_annee = true;
			dlgConfig:GetWindowName('chk5'):SetValue(true);
		end
		tc3[2] = string.gsub(tc3[2], "%D", "");
		if tc3[2] ~= -1 then
			dlgConfig:GetWindowName('gxpremiers5'):SetValue(tc3[2]);
		end
	end
end

function SetDataAnalyse()
	dlgConfig:GetWindowName('chk1'):SetValue(false);
	dlgConfig:GetWindowName('chk4'):SetValue(false);
	dlgConfig:GetWindowName('gxpremiers1'):SetValue('');
	dlgConfig:GetWindowName('gxpremiers2'):SetValue('');
	dlgConfig:GetWindowName('gxpremiers3'):SetValue('');
	dlgConfig:GetWindowName('gxpremiers4'):SetValue('');
	dlgConfig:GetWindowName('gxpremiers5'):SetValue('');
	
	listeMinisterielle.node = GetNode();
	assert(listeMinisterielle.node ~= nil)
	local c1 = listeMinisterielle.node:GetAttribute("c1");
	local c2 = listeMinisterielle.node:GetAttribute("c2");
	local c3 = listeMinisterielle.node:GetAttribute("c3");
	SetAnalyseGauche(c1, c2, c3);
end

function OnChangeComboAnneeDebut()
	listeMinisterielle.comboAnneeDebut = dlgConfig:GetWindowName('comboAnneeDebut'):GetValue();
	listeMinisterielle.indexAnneeDebut = dlgConfig:GetWindowName('comboAnneeDebut'):GetSelection();
	SetDataAnalyse();
end

function AfficheNode(node, idx)
	dlgBackoffice:GetWindowName('unetechniquea'..idx):SetValue('');
	dlgBackoffice:GetWindowName('unetechniqueb'..idx):SetValue('');
	dlgBackoffice:GetWindowName('unevitesse'..idx):SetValue('');
	dlgBackoffice:GetWindowName('deuxvitessea'..idx):SetValue('');
	dlgBackoffice:GetWindowName('deuxvitesseb'..idx):SetValue('');
	dlgBackoffice:GetWindowName('deuxtechniquea'..idx):SetValue('');
	dlgBackoffice:GetWindowName('deuxtechniqueb'..idx):SetValue('');
	
	dlgBackoffice:GetWindowName('unetechniquea'..idx):Enable(true);
	dlgBackoffice:GetWindowName('unetechniqueb'..idx):Enable(true);
	dlgBackoffice:GetWindowName('unevitesse'..idx):Enable(true);
	dlgBackoffice:GetWindowName('deuxvitessea'..idx):Enable(true);
	dlgBackoffice:GetWindowName('deuxvitesseb'..idx):Enable(true);
	dlgBackoffice:GetWindowName('deuxtechniquea'..idx):Enable(true);
	dlgBackoffice:GetWindowName('deuxtechniqueb'..idx):Enable(true);
	
	local c1 = node:GetAttribute("c1");
	local c2 = node:GetAttribute("c2");
	local c3 = node:GetAttribute("c3");
	if c1 ~= '-1' then
		local tc1 = c1:Split(',');
		for i = 1, #tc1 do
			if string.find(tc1[i], 'a') then	-- on est par année d'âge
				tc1[i] = string.gsub(tc1[i], "%D", "");
				dlgBackoffice:GetWindowName('unetechniquea'..idx):SetValue(tc1[i]);
			else
				dlgBackoffice:GetWindowName('unetechniqueb'..idx):SetValue(tc1[i]);
			end
		end
	end
	local tc2 = c2:Split(',');
	for i = 1, #tc2 do
		if tc2[i] ~= '-1' then
			dlgBackoffice:GetWindowName('unevitesse'..idx):SetValue(tc2[i]);
		end
	end
	local tc3 = c3:Split(',');
	if #tc3 > 1 then
		if string.find(tc3[1], 'a') then	-- on est par année d'âge
			tc3[1] = string.gsub(tc3[1], "%D", "");
			dlgBackoffice:GetWindowName('deuxvitessea'..idx):SetValue(tc3[1]);
		else
			dlgBackoffice:GetWindowName('deuxvitesseb'..idx):SetValue(tc3[1]);
		end
		if string.find(tc3[2], 'a') then	-- on est par année d'âge
			tc3[2] = string.gsub(tc3[2], "%D", "");
			dlgBackoffice:GetWindowName('deuxtechniquea'..idx):SetValue(tc3[2]);
		else
			dlgBackoffice:GetWindowName('deuxtechniqueb'..idx):SetValue(tc3[2]);
		end
	end
	if dlgBackoffice:GetWindowName('unetechniquea'..idx):GetValue() == '' and  dlgBackoffice:GetWindowName('unetechniqueb'..idx):GetValue() == '' then
		dlgBackoffice:GetWindowName('unetechniquea'..idx):Enable(false);
		dlgBackoffice:GetWindowName('unetechniqueb'..idx):Enable(false);
		dlgBackoffice:GetWindowName('unevitesse'..idx):Enable(false);
		dlgBackoffice:GetWindowName('deuxvitessea'..idx):Enable(false);
		dlgBackoffice:GetWindowName('deuxvitesseb'..idx):Enable(false);
		dlgBackoffice:GetWindowName('deuxtechniquea'..idx):Enable(false);
		dlgBackoffice:GetWindowName('deuxtechniqueb'..idx):Enable(false);
	end

end

function AfficheBackOffice()
	dlgBackoffice = wnd.CreateDialog(
		{
		width = listeMinisterielle.dlgPosit.width,
		height = listeMinisterielle.dlgPosit.height,
		x = listeMinisterielle.dlgPosit.x,
		y = listeMinisterielle.dlgPosit.y,
		label='Gestion des critères', 
		icon='./res/32x32_ffs.png'
		});

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgBackoffice:LoadTemplateXML({ 
		xml = './process/liste_ministerielle.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'backoffice', 		-- Facultatif si le node_name est unique ...
		params = {Affichage = listeMinisterielle.affichage}
	});

	-- remplissage des Combo
	dlgBackoffice:GetWindowName('comboNiveau'):Append("Releve");
	dlgBackoffice:GetWindowName('comboNiveau'):Append("Espoirs");
	dlgBackoffice:GetWindowName('comboNiveau'):Append("Accès CNE");
	dlgBackoffice:GetWindowName('comboNiveau'):Append("Accès CIE");
	dlgBackoffice:GetWindowName('comboSexe'):Append("Dames");
	dlgBackoffice:GetWindowName('comboSexe'):Append("Hommes");
	dlgBackoffice:GetWindowName('comboNiveau'):SetValue(listeMinisterielle.comboNiveau);
	dlgBackoffice:GetWindowName('comboSexe'):SetValue(listeMinisterielle.comboSexe);
	local debut = tonumber(listeMinisterielle.Saison) - 27;
	-- lecture des nodes
	for i = 1, 10 do
		debut = debut + 1;
		dlgBackoffice:GetWindowName('annee'..i):SetValue(debut);
		node = GetNodex(listeMinisterielle.comboNiveau, listeMinisterielle.comboSexe, i)
		if node then
			AfficheNode(node, i);
		else
			app.GetAuiFrame():MessageBox(
			"Erreur de lecture du fichier XML !!", 
			"Erreur !!!",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING); 
		end
	end
	
	-- Toolbar 
	local tbedit1 = dlgBackoffice:GetWindowName('tbedit1');
	local btnSaveEdit = tbedit1:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbedit1:AddSeparator();
	local btnRetour = tbedit1:AddTool("Sortie", "./res/32x32_exit.png");
	tbedit1:AddSeparator();
	tbedit1:Realize();
	
	-- Bind
	tbedit1:Bind(eventType.MENU, OnSavedlgBackoffice, btnSaveEdit);
	tbedit1:Bind(eventType.MENU, function(evt) dlgBackoffice:EndModal(idButton.CANCEL) end, btnRetour);
	dlgBackoffice:Bind(eventType.COMBOBOX, 
		function(evt)
			listeMinisterielle.comboNiveau = dlgBackoffice:GetWindowName('comboNiveau'):GetValue();
			for i = 1, 10 do
				local node = GetNodex(listeMinisterielle.comboNiveau, listeMinisterielle.comboSexe, i);
				if node then
					AfficheNode(node, i);
				else
					app.GetAuiFrame():MessageBox(
					"Erreur de lecture du fichier XML !!", 
					"Erreur !!!",
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
				end
			end
		end, 
		dlgBackoffice:GetWindowName('comboNiveau'))
		
	dlgBackoffice:Bind(eventType.COMBOBOX, 
		function(evt) 
			listeMinisterielle.comboSexe = dlgBackoffice:GetWindowName('comboSexe'):GetValue();
			for i = 1, 10 do
				local node = GetNodex(listeMinisterielle.comboNiveau, listeMinisterielle.comboSexe, i)
				if node then
					AfficheNode(node, i);
				else
					app.GetAuiFrame():MessageBox(
					"Erreur de lecture du fichier XML !!", 
					"Erreur !!!",
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
				end
			end
		end, 
		dlgBackoffice:GetWindowName('comboSexe'))
	dlgBackoffice:Fit();
	dlgBackoffice:ShowModal();
end

function AffichagedlgConfiguration()
	-- Creation de la boîte de dialogue
	dlgConfig = wnd.CreateDialog(
		{
		width = listeMinisterielle.dlgPosit.width,
		height = listeMinisterielle.dlgPosit.height,
		x = listeMinisterielle.dlgPosit.x,
		y = listeMinisterielle.dlgPosit.y,
		label='Configuration des paramètres', 
		icon='./res/32x32_ffs.png'
		});

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgConfig:LoadTemplateXML({ 
		xml = './process/liste_ministerielle.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'configgenerale', 		-- Facultatif si le node_name est unique ...
		params = {Affichage = listeMinisterielle.affichage}
	});

	-- remplissage des Combo
	dlgConfig:GetWindowName('comboNiveau'):Append("Relève");
	dlgConfig:GetWindowName('comboNiveau'):Append("Espoirs");
	dlgConfig:GetWindowName('comboNiveau'):Append("Accès CNE");
	dlgConfig:GetWindowName('comboNiveau'):Append("Accès CIE");
	dlgConfig:GetWindowName('comboSexe'):Append("Dames");
	dlgConfig:GetWindowName('comboSexe'):Append("Hommes");
	dlgConfig:GetWindowName('comboListe'):Clear();
	local debut = tonumber(listeMinisterielle.Saison) - 27;
	for i = 1, 10 do
		debut = debut + 1;
		dlgConfig:GetWindowName('comboAnneeDebut'):Append(debut);
		dlgConfig:GetWindowName('comboAnneeFin'):Append(debut);
	end
	for row = 0, Liste:GetNbRows() -1 do
		dlgConfig:GetWindowName('comboListe'):Append(Liste:GetCell('Code_liste', row));
	end
	dlgConfig:GetWindowName('comboListe'):SetValue(listeMinisterielle.comboListe);
	dlgConfig:GetWindowName('comboNiveau'):SetValue(listeMinisterielle.comboNiveau);
	dlgConfig:GetWindowName('comboSexe'):SetValue(listeMinisterielle.comboSexe);
	dlgConfig:GetWindowName('comboAnneeDebut'):SetValue(listeMinisterielle.comboAnneeDebut);
	dlgConfig:GetWindowName('comboAnneeFin'):SetValue(listeMinisterielle.comboAnneeFin);
	-- lecture des nodes
	SetDataAnalyse();
	
	local cmd = '';
	-- Toolbar 
	local tbedit1 = dlgConfig:GetWindowName('tbedit1');
	tbedit1:AddSeparator();
	local btnAnalyse = tbedit1:AddTool("Lancer l'analyse", "./res/32x32_ranking.png");
	tbedit1:AddSeparator();
	local btnGestion = tbedit1:AddTool("Back Office", "./res/32x32_param.png");
	tbedit1:AddSeparator();
	local btnRetour = tbedit1:AddTool("Sortie", "./res/32x32_exit.png");
	tbedit1:AddSeparator();
	tbedit1:Realize();
	
	-- Bind
	tbedit1:Bind(eventType.MENU, 
		function(evt) 
			BuildClassementCoureur();
		end, btnAnalyse);
	tbedit1:Bind(eventType.MENU, 
		function(evt) 
			AfficheBackOffice();
		end, btnGestion);
	tbedit1:Bind(eventType.MENU, function(evt) dlgConfig:EndModal(idButton.CANCEL) end, btnRetour);
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt)
			listeMinisterielle.comboListe = tonumber(dlgConfig:GetWindowName('comboListe'):GetValue()) or 0;
			SetDataAnalyse();
		end, 
		dlgConfig:GetWindowName('comboListe'))
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt)
			listeMinisterielle.comboNiveau = dlgConfig:GetWindowName('comboNiveau'):GetValue();
			SetDataAnalyse();
		end, 
		dlgConfig:GetWindowName('comboNiveau'))
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt) 
			listeMinisterielle.comboSexe = dlgConfig:GetWindowName('comboSexe'):GetValue();
			SetDataAnalyse();
		end, 
		dlgConfig:GetWindowName('comboSexe'))
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt) 
			listeMinisterielle.comboAnneeDebut = dlgConfig:GetWindowName('comboAnneeDebut'):GetValue();
			listeMinisterielle.indexAnneeDebut = dlgConfig:GetWindowName('comboAnneeDebut'):GetSelection();
			SetDataAnalyse();
		end, 
		dlgConfig:GetWindowName('comboAnneeDebut'))
		
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
		end, 
		dlgConfig:GetWindowName('gxpremiers1'))
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
		end, 
		dlgConfig:GetWindowName('gxpremiers2'))
	dlgConfig:Fit();
	dlgConfig:ShowModal();
	if base then
		base:Delete()
	end
	if doc then
		doc:Delete();
	end
end

function main(cparams)
	XML = app.GetPath().."/process/liste_ministerielle.xml";
	doc = xmlDocument.Create(XML);
	listeMinisterielle = {};
	listeMinisterielle.affichage = false;	
	
	
	
	scrip_version = "2.3"; 
	-- vérification de l'existence d'une version plus récente du script.
	-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2,DoubleTirage=3.2,TirageOptions=3.3,TirageER=1.7,ListeMinisterielle=2.3,KandaHarJunior=2.0
	if app.GetVersion() >= '4.4c' then 
		indice_return = 7;
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

	listeMinisterielle.dlgPosit = {};
	listeMinisterielle.dlgPosit.width = display:GetSize().width * .7;
	listeMinisterielle.dlgPosit.height = display:GetSize().height * .9;
	listeMinisterielle.dlgPosit.x = (display:GetSize().width - listeMinisterielle.dlgPosit.width) / 2;
	listeMinisterielle.dlgPosit.y = (display:GetSize().height - listeMinisterielle.dlgPosit.height) / 3;
	listeMinisterielle.debug = false;
	base = sqlBase.Clone();
	Liste = base:GetTable('Liste');
	local cmd = "SELECT * FROM Liste WHERE Type_classement = 'IAU' ORDER BY Seasoncode DESC, Code_liste DESC";
	base:TableLoad(Liste, cmd);
	listeMinisterielle.Saison = Liste:GetCell('Seasoncode', 0);
	listeMinisterielle.comboAnneeDebut = tonumber(listeMinisterielle.Saison) -24;
	listeMinisterielle.indexAnneeDebut = 2;
	listeMinisterielle.comboAnneeFin = tonumber(listeMinisterielle.Saison) -22;
	listeMinisterielle.indexAnneeFin = listeMinisterielle.indexAnneeDebut + 2;
	listeMinisterielle.par_annee = false;
	listeMinisterielle.comboListe = Liste:GetCellInt('Code_liste',0);
	listeMinisterielle.comboSexe = "Dames";
	listeMinisterielle.comboNiveau = "Relève";
	Discipline = base:GetTable('Discipline');
	ChargeDisciplines();
	Evenement_Matrice = base:GetTable('Evenement_Matrice');
	Type_Classement = base:GetTable('Type_Classement');
	tSexe = {'F', 'M'};
	AffichagedlgConfiguration();
end

if not listeMinisterielle then
	Main()
end
