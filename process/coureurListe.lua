-- Matrices / Challenges et Combinés pour skiFFS
dofile('./edition/functionPG.lua');

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

function BuildClassementCoureur()	-- construction de la table des classements
	local cmd = "SELECT cou.Code_coureur Code, cou.Nom, cou.Prenom, CONCAT(cou.Nom, ' ',cou.Prenom) Identite, cou.Sexe, DATE_FORMAT(cou.Naissance,'%Y') An, cou.Code_nation Nation, cou.Code_comite Comite, cou.Club, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..coureurListe.comboListe.." AND cla1.Type_classement='IASL') Pts_SL, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..coureurListe.comboListe.." AND cla1.Type_classement='IASL') Clt_SL, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..coureurListe.comboListe.." AND cla1.Type_classement='IAGS') Pts_GS, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..coureurListe.comboListe.." AND cla1.Type_classement='IAGS') Clt_GS, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..coureurListe.comboListe.." AND cla1.Type_classement='IASG') Pts_SG, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..coureurListe.comboListe.." AND cla1.Type_classement='IASG') Clt_SG, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..coureurListe.comboListe.." AND cla1.Type_classement='IADH') Pts_DH, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..coureurListe.comboListe.." AND cla1.Type_classement='IADH') Clt_DH "..
		" FROM Coureur cou "..
		" WHERE cou.Code_coureur LIKE 'FIS%'"..
		" Order By cou.Nom, cou.Prenom";
	-- adv.Alert(cmd);
	Classement_Coureur = base:TableLoad(cmd);
	Classement_Coureur:AddColumn({ name = 'Pts_technique', label = 'Pts_technique', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_technique', label = 'Clt_technique', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Pts_vitesse', label = 'Pts_vitesse', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_vitesse', label = 'Clt_vitesse', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_An_SL', label = 'Clt_An_SL', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_An_GS', label = 'Clt_An_GS', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_An_SG', label = 'Clt_An_SG', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_An_DH', label = 'Clt_An_DH', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_An_technique', label = 'Clt_An_technique', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_An_vitesse', label = 'Clt_An_citesse', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Best_technique', label = 'Best_technique', type = sqlType.CHAR, size = 2, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Best_vitesse', label = 'Best_vitesse', type = sqlType.CHAR, size = 2, style = sqlStyle.NULL });
	
	for i = 0, Classement_Coureur:GetNbColumns() -1 do
		local colname = Classement_Coureur:GetColumnName(i);
		if string.find(colname, 'Clt') then
			Classement_Coureur:ChangeColumn(colname, 'ranking');
		end
	end
	
	for row = 0, Classement_Coureur:GetNbRows()-1 do
		local cltSL = Classement_Coureur:GetCellInt('Clt_SL', row, 10000);
		local ptsSL = Classement_Coureur:GetCellDouble('Pts_SL', row, 10000);
		local cltGS = Classement_Coureur:GetCellInt('Clt_GS', row, 10000);
		local ptsGS = Classement_Coureur:GetCellDouble('Pts_GS', row, 10000);
		local cltSG = Classement_Coureur:GetCellInt('Clt_SG', row, 10000);
		local ptsSG = Classement_Coureur:GetCellDouble('Pts_SG', row, 10000);
		local cltDH = Classement_Coureur:GetCellInt('Clt_DH', row, 10000);
		local ptsDH = Classement_Coureur:GetCellDouble('Pts_DH', row, 10000);
		local cltTect = math.min(cltSL, cltGS);
		if cltTect < 10000 then
			if cltSL < cltGS then
				Classement_Coureur:SetCell('Best_technique', row, 'SL');
				Classement_Coureur:SetCell('Pts_technique', row, ptsSL);
				Classement_Coureur:SetCell('Clt_technique', row, cltSL);
			else
				Classement_Coureur:SetCell('Best_technique', row, 'GS');
				Classement_Coureur:SetCell('Pts_technique', row, ptsGS);
				Classement_Coureur:SetCell('Clt_technique', row, cltGS);
			end
		end
		local cltVit = math.min(cltSG, cltDH);
		if cltVit < 10000 then
			if cltSG < cltDH then
				Classement_Coureur:SetCell('Best_vitesse', row, 'SG');
				Classement_Coureur:SetCell('Pts_vitesse', row, ptsSG);
				Classement_Coureur:SetCell('Clt_vitesse', row, cltSG);
			else
				Classement_Coureur:SetCell('Best_vitesse', row, 'DH');
				Classement_Coureur:SetCell('Pts_vitesse', row, ptsDH);
				Classement_Coureur:SetCell('Clt_vitesse', row, cltDH);
			end
		end
	end
	for i = Classement_Coureur:GetNbRows() -1, 0, -1 do
		local delete = false;
		local naissance = tonumber(Classement_Coureur:GetCell('An', i)) or 0;
		if coureurListe.annee_mini > 0 and naissance < coureurListe.annee_mini then
			delete = true;
		end
		if coureurListe.annee_maxi > 0 and naissance > coureurListe.annee_maxi then
			delete = true;
		end
		if coureurListe.sexe ~= '*' then
			if  Classement_Coureur:GetCell('Sexe', i) ~= coureurListe.sexe then
				delete = true;
			end
		end
		if delete == true then
			Classement_Coureur:RemoveRowAt(i);
		end
	end	
	if coureurListe.comboClt == 1 then
		Classement_Coureur:OrderBy('Pts_SL');
		Classement_Coureur:SetRanking('Clt_An_SL', 'Pts_SL', '');
		Classement_Coureur:OrderBy('Pts_GS');
		Classement_Coureur:SetRanking('Clt_An_GL', 'Pts_GL', '');
		Classement_Coureur:OrderBy('Pts_SG');
		Classement_Coureur:SetRanking('Clt_An_SG', 'Pts_SG', '');
		Classement_Coureur:OrderBy('Pts_DH');
		Classement_Coureur:SetRanking('Clt_An_DH', 'Pts_DH', '');
		Classement_Coureur:OrderBy('Pts_technique');
		Classement_Coureur:SetRanking('Clt_An_technique', 'Pts_technique', '');
		Classement_Coureur:OrderBy('Pts_vitesse');
		Classement_Coureur:SetRanking('Clt_An_vitesse', 'Pts_vitesse', '');
	end

	Classement_Coureur:OrderBy('Pts_'..coureurListe.discipline);
	for i = Classement_Coureur:GetNbRows() -1, 0, -1 do
		local delete = false;
		if coureurListe.comboClt == 1 then
			local clt_an = Classement_Coureur:GetCellInt('Clt_An_'..coureurListe.discipline, i);
			Classement_Coureur:SetCell('Clt_'..coureurListe.discipline, i, clt_an);
		end
		local clt_discipline = Classement_Coureur:GetCellInt('Clt_'..coureurListe.discipline, i);
		if coureurListe.clt_mini > 0 then
			if clt_discipline < coureurListe.clt_mini then
				delete = true;
			end
		end
		if coureurListe.clt_maxi > 0 then
			if clt_discipline > coureurListe.clt_maxi then
				delete = true;
			end
		end
		if delete == true then
			Classement_Coureur:RemoveRowAt(i);
		end
	end	
	if coureurListe.xmeilleurs_francais > 0 then
		local nb_francais = 0;
		for row = 0, Classement_Coureur:GetNbRows()-1 do
			if Classement_Coureur:GetCell('Nation', row) == 'FRA' then
				nb_francais = nb_francais + 1;
				if nb_francais <= coureurListe.xmeilleurs_francais  then
					Classement_Coureur:SetCell('Critere', row, 1);
				end
			end
		end
	end
	-- Classement_Coureur:Snapshot('Classement_Coureur.db3');
	Classement_Coureur:SetCounter('Nation');
	Classement_Coureur:OrderBy('Clt_'..coureurListe.discipline);
	if Classement_Coureur:GetNbRows() > 0 then
		OnPrint();
	else
		local msg = "Aucon coureur ne correspont au(x) critère(s) !!";
		app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
	end
end

function OnPrint()
	-- Creation du Report
	local nombre_de_critere = 0;
	local critere = '';
	local sexe = 'mixte';
	if coureurListe.sexe == 'F' then
		sexe = 'Dames';
	elseif coureurListe.sexe == 'M' then
		sexe = 'Hommes';
	end
	if coureurListe.clt_mini > 0 and coureurListe.clt_maxi > 0 then
		nombre_de_critere = nombre_de_critere + 1;
		critere = critere..dlgConfig:GetWindowName('combo_clt'):GetValue()..' compris entre '..coureurListe.clt_mini..' et '..coureurListe.clt_maxi..' en '..coureurListe.discipline;
	end
	if coureurListe.annee_mini > 0 and coureurListe.annee_maxi > 0 then
		nombre_de_critere = nombre_de_critere + 1;
		critere = critere..'\nAnnée de naissance entre '..coureurListe.annee_mini..' et '..coureurListe.annee_maxi;
	end
	local nb_francais = Classement_Coureur:GetCounterValue('Nation', 'FRA');
	local nb_critere = Classement_Coureur:GetNbRows();
	if coureurListe.xmeilleurs_francais > nb_francais then
		coureurListe.xmeilleurs_francais = nb_francais;
	end
	local filter = "$(Nation):In('FRA')";
	Classement_Coureur:Filter(filter, true);
	if coureurListe.xmeilleurs_francais > 0 then
		for row = Classement_Coureur:GetNbRows() -1, 0, -1 do
			if row >= coureurListe.xmeilleurs_francais then
				Classement_Coureur:RemoveRowAt(row);
			end
		end
	end
	report = wnd.LoadTemplateReportXML({
		xml = './process/coureurListe.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'print',
		title = "Edition des coureurs de la liste FIS ",
		base = base,
		body = Classement_Coureur,
		paper_orientation = 'landscape',
		params = {Liste = coureurListe.comboListe, Criteres = nombre_de_critere, Critere = critere, Nb_Rows = coureurListe.xmeilleurs_francais, Discipline = coureurListe.discipline, Sexe = sexe, NbCritere = nb_critere, NbFrancais = nb_francais, Version = script_version}
	});
	
	-- report:SetZoom(10)
end

function AffichagedlgConfiguration()
	-- Interrogation();
	-- Creation de la boîte de dialogue

	dlgConfig = wnd.CreateDialog(
		{
		width = coureurListe.dlgPosit.width,
		height = coureurListe.dlgPosit.height,
		x = coureurListe.dlgPosit.x,
		y = coureurListe.dlgPosit.y,
		label='Configuration des paramètres', 
		icon='./res/32x32_ffs.png'
		});

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgConfig:LoadTemplateXML({ 
		xml = './process/coureurliste.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'configgenerale', 		-- Facultatif si le node_name est unique ...
		params = {Affichage = coureurListe.affichage}
	});

	-- remplissage des Combo
	dlgConfig:GetWindowName('combo_sexe'):Clear();
	dlgConfig:GetWindowName('combo_sexe'):Append("M");
	dlgConfig:GetWindowName('combo_sexe'):Append("F");
	dlgConfig:GetWindowName('combo_sexe'):Append("*");
	dlgConfig:GetWindowName('combo_sexe'):SetSelection(0);

	dlgConfig:GetWindowName('combo_discipline'):Clear();
	dlgConfig:GetWindowName('combo_discipline'):Append("SL");
	dlgConfig:GetWindowName('combo_discipline'):Append("GS");
	dlgConfig:GetWindowName('combo_discipline'):Append("SG");
	dlgConfig:GetWindowName('combo_discipline'):Append("DH");
	dlgConfig:GetWindowName('combo_discipline'):Append("technique");
	dlgConfig:GetWindowName('combo_discipline'):Append("vitesse");
	dlgConfig:GetWindowName('combo_discipline'):SetSelection(0);
	for row = 0, Liste:GetNbRows() -1 do
		dlgConfig:GetWindowName('comboListe'):Append(Liste:GetCell('Code_liste', row));
	end
	dlgConfig:GetWindowName('comboListe'):SetSelection(0);
	dlgConfig:GetWindowName('clt_mini'):SetValue(1);
	dlgConfig:GetWindowName('clt_maxi'):SetValue(9999);

	dlgConfig:GetWindowName('combo_clt'):Clear();
	dlgConfig:GetWindowName('combo_clt'):Append("Classement mondial");
	dlgConfig:GetWindowName('combo_clt'):Append("Classement par année d'âge");
	dlgConfig:GetWindowName('combo_clt'):SetSelection(0);

	-- Toolbar 
	local tbedit1 = dlgConfig:GetWindowName('tbedit1');
	tbedit1:AddStretchableSpace();
	local btnAnalyse = tbedit1:AddTool("Lancer l'édition", "./res/32x32_ranking.png");
	tbedit1:AddSeparator();
	local btnRetour = tbedit1:AddTool("Sortie", "./res/32x32_exit.png");
	tbedit1:AddStretchableSpace();
	tbedit1:Realize();
	
	-- Bind
	tbedit1:Bind(eventType.MENU, 
		function(evt) 
			coureurListe.comboListe = Liste:GetCellInt('Code_liste', dlgConfig:GetWindowName('comboListe'):GetSelection());
			coureurListe.saison = Liste:GetCellInt('Seasoncode', dlgConfig:GetWindowName('comboListe'):GetSelection());
			coureurListe.clt_mini = tonumber(dlgConfig:GetWindowName('clt_mini'):GetValue()) or 0;
			coureurListe.clt_maxi = tonumber(dlgConfig:GetWindowName('clt_maxi'):GetValue()) or 0;
			coureurListe.discipline = dlgConfig:GetWindowName('combo_discipline'):GetValue();
			coureurListe.sexe = dlgConfig:GetWindowName('combo_sexe'):GetValue();
			coureurListe.xmeilleurs_francais = tonumber(dlgConfig:GetWindowName('xmeilleurs_francais'):GetValue()) or 0;
			coureurListe.annee_mini = tonumber(dlgConfig:GetWindowName('annee_mini'):GetValue()) or 0;
			coureurListe.annee_maxi = tonumber(dlgConfig:GetWindowName('annee_maxi'):GetValue()) or 0;
			coureurListe.comboClt = dlgConfig:GetWindowName('combo_clt'):GetSelection();
			BuildClassementCoureur();
		end, btnAnalyse);
	tbedit1:Bind(eventType.MENU, 
		function(evt)
			dlgConfig:EndModal(idButton.CANCEL) 
		end, btnRetour);
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt)
			coureurListe.comboListe = Liste:GetCellInt('Code_liste', dlgConfig:GetWindowName('comboListe'):GetSelection());
			coureurListe.saison = Liste:GetCellInt('Seasoncode', dlgConfig:GetWindowName('comboListe'):GetSelection());
		end, 
		dlgConfig:GetWindowName('comboListe'))
		
	dlgConfig:Fit();
	dlgConfig:ShowModal();
	if doc then
		doc:Delete();
	end
end

function main(cparams)

	XML = app.GetPath().."/process/coureurListe.xml";
	doc = xmlDocument.Create(XML);
	coureurListe = {};
	script_version = "1.6"; 
	-- vérification de l'existence d'une version plus récente du script.
	-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2,DoubleTirage=3.2,TirageOptions=3.3,TirageER=1.7,ListeMinisterielle=2.3,KandaHarJunior=2.0
	if app.GetVersion() >= '4.4c' then 
		indice_return = 12;
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

	coureurListe.dlgPosit = {};
	coureurListe.dlgPosit.width = display:GetSize().width * .7;
	coureurListe.dlgPosit.height = display:GetSize().height * .9;
	coureurListe.dlgPosit.x = (display:GetSize().width - coureurListe.dlgPosit.width) / 2;
	coureurListe.dlgPosit.y = (display:GetSize().height - coureurListe.dlgPosit.height) / 3;
	coureurListe.debug = false;
	base = sqlBase.Clone();
	Liste = base:GetTable('Liste');
	local cmd = "SELECT * FROM Liste WHERE Type_classement = 'IAU' ORDER BY Seasoncode DESC, Code_liste DESC";
	base:TableLoad(Liste, cmd);
	tSexe = {"'F'", "'M'", "'F','M'"};
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
	coureurListe.standalone = false;
	AffichagedlgConfiguration();
	return true;
	
end

main();

