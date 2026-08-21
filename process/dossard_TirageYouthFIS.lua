-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function GetMenuName()
	return "FIS : Courses CHI (avec Groupe 1 et Groupe 2)";
end
function GetActivite()
	return "ALP,TM";
end

function BuildTableTirage(tablex, bib_first);
	params.tableDossards1 = {};
	tablex.OrderRandom();
	local bib = bib_first;
	for row = 0, tablex:GetNbRows() - 1 do
		table.insert(params.tableDossards1, bib);
		bib = bib + 1;
	end
	params.tableDossards1 = Shuffle(params.tableDossards1, false);
	tTableTirage1:RemoveAllRows();
	for row = 1, #params.tableDossards1 do
		local new_row1 = tTableTirage1:AddRow();
		tTableTirage1:SetCell('Row', new_row1, row);	-- setCell du rang fictif en lien avec  params.tableDossards1
	end
	tTableTirage1:OrderRandom();
	
	for row = 0, tTableTirage1:GetNbRows() -1 do
		local rang_fictif = tTableTirage1:GetCellInt('Row', row);
		local code_coureur = tablex:GetCell('Code_coureur', row);
		-- tCoureur[code_coureur] = tCoureur[code_coureur] or {};
		local row_coureur = tResultat:GetIndexRow('Code_coureur', code_coureur);
		local dossard = params.tableDossards1[rang_fictif];
		-- tCoureur[code_coureur].Dossard = dossard;
		tResultat:SetCell('Dossard', row_coureur, dossard);
	end
end

function PrintDoubleTirage()
	if report then
		report = nil;
	end
	if tU14_Filles:GetNbRows() > 0 then
		for i = 1, #tU14_Filles_Groupes do
			local groupe = tonumber(tU14_Filles_Groupes[i].Groupe) or 0;
			if groupe == 1 or groupe == 2 then
				OnPrintDoubleTirage(params.code_evenement, groupe, 'U14', 'F');
			end
		end
	end
	if tU14_Garcons:GetNbRows() > 0 then
		for i = 1, #tU14_Garcons_Groupes do
			local groupe = tonumber(tU14_Garcons_Groupes[i].Groupe) or 0;
			if groupe == 1 or groupe == 2 then
				OnPrintDoubleTirage(params.code_evenement * -1, groupe, 'U14', 'M');
			end
		end
	end
	if tU16_Filles:GetNbRows() > 0 then
		for i = 1, #tU16_Filles_Groupes do
			local groupe = tonumber(tU16_Filles_Groupes[i].Groupe) or 0;
			if groupe == 1 or groupe == 2 then
				OnPrintDoubleTirage(params.code_evenement + 1000, groupe, 'U16', 'F');
			end
		end
	end
	if tU16_Garcons:GetNbRows() > 0 then
		for i = 1, #tU16_Garcons_Groupes do
			local groupe = tonumber(tU16_Garcons_Groupes[i].Groupe) or 0;
			if groupe == 1 or groupe == 2 then
				OnPrintDoubleTirage((params.code_evenement + 1000) * -1, groupe, 'U16', 'M');
			end
		end
	end
end

function OnPrintDoubleTirage(code_evenement, groupe, categ, sexe)
	local tableDossards1 = {};
	local tableDossards2 = {};
	local tDossards = {};
	local txtsexe = 'Filles';
	if sexe == 'M' then
		txtsexe = 'Garçons';
	end
	local txt_tirage = " Groupe "..groupe..' pour les '..categ..' '..txtsexe;
	tableDossards1, tableDossards2 = OnDecodeJsonCHI(code_evenement, groupe);
	if #tableDossards1 == 0 or #tableDossards2 == 0 then
		local msg = "Les doubles tirages n'ont pas été enregistrés !!";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
		do return end
	end
	tTableBody:RemoveAllRows();
	for i = 1, #tableDossards1 do
		local dossard = tableDossards1[i].Dossard;
		table.insert(tDossards, dossard);
		local rang_fictif = tableDossards2[i].RangFictif or 0;
		local matching_bib = tableDossards2[i].Dossard or 0;
		local identite = tableDossards2[i].Identite or '';
		local nation = tableDossards2[i].Nation;
		local row = tTableBody:AddRow();
		tTableBody:SetCell('Order_fictionnal_rank', row, i);
		tTableBody:SetCell('Order_racer', row, i);;
		tTableBody:SetCell('Bib_fictionnal_rank', row, dossard);
		tTableBody:SetCell('Racer_fictionnal_rank', row, rang_fictif);
		tTableBody:SetCell('Racer_matching_bib', row, matching_bib);
		tTableBody:SetCell('Racer_identity', row, identite);
		tTableBody:SetCell('Racer_nation', row, nation);
	end
	if not report then
		-- local msg = 'code_evenement = '..code_evenement..'\ngroupe = '..groupe..'\ncateg = '..categ..'\nsexe = '..sexe..'\ntaille de tableDossards1 = '..#tableDossards1..'\ntTableBody:GetNbRows() = '..tTableBody:GetNbRows()..'\ntype(report) = '..type(report);
		-- app.GetAuiFrame():MessageBox(msg, "Vérification des données", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
		report = wnd.LoadTemplateReportXML({
			xml = './process/dossard_TirageYouthFIS.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = 'Edition du tirage au sort du'..txt_tirage,
			margin_first_top = 150,
			margin_first_left = 100,
			margin_first_right = 100,
			margin_first_bottom = 100,
			margin_top = 150,
			margin_left = 100, 
			margin_right = 100,
			margin_bottom = 100,
			body = tTableBody,
			paper_orientation = 'portrait',
			params = {Nom = tEvenement:GetCell('Nom', 0), TableDossards = tDossards, Draw = groupe, Version = script_version, Langue = params.language , Categ = categ, Sexe = sexe}
		});
	else
		editor = report:GetEditor();
		if not editor then
			do return end
		end
		editor:PageBreak(); -- Saut de Page entre les 2 éditions ...
		-- local msg = 'code_evenement = '..code_evenement..'\ngroupe = '..groupe..'\ncateg = '..categ..'\nsexe = '..sexe..'\ntaille de tableDossards1 = '..#tableDossards1..'\ntTableBody:GetNbRows() = '..tTableBody:GetNbRows()..'\ntype(report) = '..type(report);
		-- app.GetAuiFrame():MessageBox(msg, "Vérification des données", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
		wnd.LoadTemplateReportXML({
			xml = './process/dossard_TirageYouthFIS.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = 'Edition du tirage au sort du'..txt_tirage,
			report = report,
			margin_first_top = 150,
			margin_first_left = 100,
			margin_first_right = 100,
			margin_first_bottom = 100,
			margin_top = 150,
			margin_left = 100, 
			margin_right = 100,
			margin_bottom = 100,
			body = tTableBody,
			paper_orientation = 'portrait',
			params = {Nom = tEvenement:GetCell('Nom', 0), TableDossards = tDossards, Draw = groupe, Version = script_version, Langue = params.language , Categ = categ, Sexe = sexe}
		});
	end
end

function OnDecodeJsonCHI(code_evenement, groupe)
	local tableDossards1 = {};
	local tableDossards2 = {};
	local cmd = 'Select * From Resultat_Info_Bibo Where Code_evenement = '..code_evenement..' And Groupe = '..groupe..' Order By Ligne';
	base:TableLoad(tResultat_Info_Bibo, cmd);
	if tResultat_Info_Bibo:GetNbRows() == 0 then
		return tableDossards1, tableDossards2;
	end
	-- tResultat_Info_Bibo:Snapshot('tResultat_Info_Bibo.db3');
	tResultat_Info_Bibo:OrderBy('Groupe, Ligne');
	tTableTirage1:RemoveAllRows();
	for i = 0, tResultat_Info_Bibo:GetNbRows() -1 do
		local jsontxt1 = tResultat_Info_Bibo:GetCell('Table1', i);
		local xTable1 = table.FromStringJSON(jsontxt1);
		table.insert(tableDossards1, {Dossard = xTable1.Table1[1].Col2, RangFictif = xTable1.Table1[1].Col1});
		local jsontxt2 = tResultat_Info_Bibo:GetCell('Table2', i);
		local xTable2 = table.FromStringJSON(jsontxt2);
		table.insert(tableDossards2, {Identite = xTable2.Table2[1].Identite, Dossard = xTable2.Table2[1].Dossard, Nation = xTable2.Table2[1].Nation, RangFictif = xTable2.Table2[1].RangFictif});
	end
	return tableDossards1, tableDossards2;
end

function OnEncodeJsonCHI(code_evenement, groupe)
	local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..code_evenement..' And Groupe = '..groupe;
	base:Query(cmd);
	rResultat_Info_Bibo = tResultat_Info_Bibo:GetRecord();
	local row_groupe = nil;
	assert(tTableTirage1:GetNbRows() > 0);
	for row = 0, tTableTirage1:GetNbRows() -1 do
		local idx = row + 1;
		local tTable1 = {};
		local tTable2 = {};
		table.insert(tTable1, {Col1 = 'Dossard du rang fictif '..idx, Col2 = params.tableDossards1[idx]});
		local xTable1 = {Table1 = tTable1};
		local jsontxt1 = table.ToStringJSON(xTable1, false);
		
		local rang_fictif = tTableTirage1:GetCellInt('Row', row);
		local identite = '';
		local nation = '';
		local pts = 0;
		local dossard = params.tableDossards1[rang_fictif] or '';
		local row_coureur = tResultat:GetIndexRow('Dossard', dossard);
		if row_coureur >= 0 then
			identite = tResultat:GetCell('Nom', row_coureur)..' '..tResultat:GetCell('Prenom', row_coureur);
			nation = tResultat:GetCell('Nation', row_coureur);
		end
		local col1 = identite;
		local col2 = pts;
		local col3 = rang_fictif;
		local col4 = dossard;
		local col5 = nation;
		table.insert(tTable2, {Identite = col1, Pts = col2, RangFictif = col3, Dossard = col4, Nation= col5});
		local xTable2 = {Table2 = tTable2};
		local jsontxt2 = table.ToStringJSON(xTable2, false);
		
		rResultat_Info_Bibo:Set('Code_evenement', code_evenement);
		rResultat_Info_Bibo:Set('Groupe', groupe);
		rResultat_Info_Bibo:Set('Ligne', idx);
		rResultat_Info_Bibo:Set('Table1', jsontxt1);
		rResultat_Info_Bibo:Set('Table2', jsontxt2);
		tResultat_Info_Bibo:AddRow();
		base:TableInsert(tResultat_Info_Bibo, -1);
	end
end

function OnTirageGroupe(tTable, code_evenement, bib_first, groupe)
	local filter = "$(Groupe):In('"..groupe.."')";
	tTable:Filter(filter, true);
	tTable:OrderRandom();
	BuildTableTirage(tTable, bib_first);
	if groupe == '1' or groupe == '2' then
		groupe = tonumber(groupe);
		local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..code_evenement..' And Groupe = '..groupe;
		base:Query(cmd);
		OnEncodeJsonCHI(code_evenement, groupe);
	end
end

function SetGroupes()
	local bolGroupesOK = true;
	tU14_Filles:SetCounter(params.column);
	tU16_Filles:SetCounter(params.column);
	tU14_Garcons:SetCounter(params.column);
	tU16_Garcons:SetCounter(params.column);
	if tU14_Filles:GetNbRows() > 0 then
		if tU14_Filles:GetCounter(params.column):GetNbRows() < 2 then
			bolGroupesOK = false;
		end
	end
	if tU16_Filles:GetNbRows() > 0 then
		if tU16_Filles:GetCounter(params.column):GetNbRows() < 2 then
			bolGroupesOK = false;
		end
	end
	if tU14_Garcons:GetNbRows() > 0 then
		if tU14_Garcons:GetCounter(params.column):GetNbRows() < 2 then
			bolGroupesOK = false;
		end
	end
	if tU16_Garcons:GetNbRows() > 0 then
		if tU16_Garcons:GetCounter(params.column):GetNbRows() < 2 then
			bolGroupesOK = false;
		end
	end
	if bolGroupesOK == false then
		local msg = "Tous les groupes n'ont pas été définis !!!\nLe scénario va s'arrêter pour vous permettre de mettre\nàjour les concurrents";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
		return false;
	end

	tU14_Filles_Groupes = {};
	for i = 0 , tU14_Filles:GetCounter(params.column):GetNbRows() -1 do
		local groupe = tU14_Filles:GetCounter(params.column):GetCell(0,i);
		local nombre = tU14_Filles:GetCounter(params.column):GetCell(1,i);
		table.insert(tU14_Filles_Groupes, {Groupe = groupe, Nombre = nombre});
	end
	tU16_Filles_Groupes = {};
	for i = 0 , tU16_Filles:GetCounter(params.column):GetNbRows() -1 do
		local groupe = tU16_Filles:GetCounter(params.column):GetCell(0,i);
		local nombre = tU16_Filles:GetCounter(params.column):GetCell(1,i);
		table.insert(tU16_Filles_Groupes, {Groupe = groupe, Nombre = nombre});
	end
	tU14_Garcons_Groupes = {};
	for i = 0 , tU14_Garcons:GetCounter(params.column):GetNbRows() -1 do
		local groupe = tU14_Garcons:GetCounter(params.column):GetCell(0,i);
		local nombre = tU14_Garcons:GetCounter(params.column):GetCell(1,i);
		table.insert(tU14_Garcons_Groupes, {Groupe = groupe, Nombre = nombre});
	end
	tU16_Garcons_Groupes = {};
	for i = 0 , tU16_Garcons:GetCounter(params.column):GetNbRows() -1 do
		local groupe = tU16_Garcons:GetCounter(params.column):GetCell(0,i);
		local nombre = tU16_Garcons:GetCounter(params.column):GetCell(1,i);
		table.insert(tU16_Garcons_Groupes, {Groupe = groupe, Nombre = nombre});
	end
	return bolGroupesOK;
end

function main(params_c)
	params = params_c;
	params.language = 'en';
	params.code_evenement = tonumber(params.code_evenement) or -1;
	params.column = 'Groupe';
	if params.code_evenement < 0 then
		return;
	end
	params.faire = params.faire or '';
	params.width = (display:GetSize().width * 2) / 3;
	params.height = display:GetSize().height / 2;
	params.x = (display:GetSize().width - params.width) / 2;
	params.y = 100;
	
	script_version = "1.2"; 
	-- vérification de l'existence d'une version plus récente du script.
	-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2,DoubleTirage=3.2,TirageOptions=3.3,TirageER=1.7,ListeMinisterielle=2.3,KandaHarJunior=2.0
	if app.GetVersion() >= '4.4c' then 		-- début d'implementation de la fonction UpdateRessource
		indice_return = 14;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	end
	bolEnableTirage = true;
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
	
	base = base or sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	tResultat = base:GetTable('Resultat');
	tResultat_Info_Bibo = base:GetTable('Resultat_Info_Bibo');
	tResultat:OrderBy('Dossard');
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
	if app.GetVersion() >= '4.4c' then 		-- début d'implementation de la fonction UpdateRessource
		indice_return = 14;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	end
	tResultat:OrderRandom();
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement..' Order By Rang, Dossard');
	params.code_entite = tEvenement:GetCell('Code_entite', 0);
	tU14_Filles = tResultat:Copy(true,true);
	tU14_Garcons = tResultat:Copy(true,true);
	tU16_Filles = tResultat:Copy(true,true);
	tU16_Garcons = tResultat:Copy(true,true);
	
	local filter = "$(Categ):In('U14') and $(Sexe):In('F')";
	tU14_Filles:Filter(filter, true);
	filter = "$(Categ):In('U14') and $(Sexe):In('M')";
	tU14_Garcons:Filter(filter, true);
	filter = "$(Categ):In('U16') and $(Sexe):In('F')";
	tU16_Filles:Filter(filter, true);
	filter = "$(Categ):In('U16') and $(Sexe):In('M')";
	tU16_Garcons:Filter(filter, true);
	local nbrows = tU14_Filles:GetNbRows() + tU16_Filles:GetNbRows() + tU14_Garcons:GetNbRows() + tU16_Garcons:GetNbRows();
	if nbrows ~= tResultat:GetNbRows() then
		local msg = "Veuillez passer les Outils afin de mettre à jour\nles catégories et les sexes.\nLe scénario va s'arrêter pour vous permettre de mettre\nà jour les concurrents";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
	end
	bolGroupesOK = true;
	-- tCoureur = {};
	tTableTirage1 = sqlTable.Create('_TableTirage1');
	tTableTirage1:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage1, '_TableTirage1');
	tTableTirage2 = sqlTable.Create('_TableTirage2');
	tTableTirage2:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage2, '_TableTirage2');
	
	tTableBody = sqlTable.Create('_TableBody');
	tTableBody:AddColumn({ name = 'Order_fictionnal_rank', type = sqlType.LONG, style = sqlStyle.NULL });
	tTableBody:AddColumn({ name = 'Bib_fictionnal_rank', type = sqlType.LONG, style = sqlStyle.NULL });
	tTableBody:AddColumn({ name = 'Order_racer', type = sqlType.LONG, style = sqlStyle.NULL });
	tTableBody:AddColumn({ name = 'Racer_fictionnal_rank', type = sqlType.LONG, style = sqlStyle.NULL });
	tTableBody:AddColumn({ name = 'Racer_matching_bib', type = sqlType.LONG, style = sqlStyle.NULL });
	tTableBody:AddColumn({ name = 'Racer_identity', type = sqlType.TEXT, style = sqlStyle.NULL });
	tTableBody:AddColumn({ name = 'Racer_nation', type = sqlType.TEXT, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableBody, '_TableBody');

	-- Ouverture Document XML 
	
	XML = "./process/dossard_TirageYouthFIS.xml";
	params.doc = xmlDocument.Create(XML);
	dlgColumn = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Configuration du tirage - script version '..script_version, 
		icon='./res/32x32_ffs.png'
		});
	dlgColumn:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		node_value = 'column',
		});
	-- Toolbar Principale ...
	local tbcolumn = dlgColumn:GetWindowName('tbcolumn');
	tbcolumn:AddStretchableSpace();
	local btnSave = tbcolumn:AddTool("Enregistrer les paramètres", "./res/vpe32x32_save.png");
	tbcolumn:AddStretchableSpace();
	tbcolumn:Realize();
	dlgColumn:GetWindowName('column'):Append('Groupe');
	dlgColumn:GetWindowName('column'):Append('Equipe');
	dlgColumn:GetWindowName('column'):Append('Critere');
	dlgColumn:GetWindowName('column'):SetSelection(0);

	dlgColumn:Bind(eventType.CHECKBOX, 
		function(evt) 
			if dlgColumn:GetWindowName('raz'):GetValue() == true then
				if tResultat:GetCellInt('Dossard', 0) > 0 then
					if app.GetAuiFrame():MessageBox(
						"Les dossards ont été déjà tirés, voulez-vous les effacer ?", 
						"Attention !!!",
						msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_WARNING
						) == msgBoxStyle.NO then
						dlgColumn:GetWindowName('raz'):SetValue(false);
						local cmd = 'Delete From Resultat_Info_Bibo where Code_evenement = '..params.code_evenement;
						base:Query(cmd);
						cmd = 'Update Resultat Set Dossard = NULL Where Code_evenement = '..params.code_evenement;
						base:Query(cmd);
						local cmd = 'Delete From Resultat_Manche Where Code_evenement = '..params.code_evenement;
						base:Query(cmd);
						local cmd = 'Delete From Resultat_Chrono Where Code_evenement = '..params.code_evenement;
						base:Query(cmd);
					else
						bolEnableTirage = false;
					end
				end
			end	
		end,
		dlgColumn:GetWindowName('raz'));
	dlgColumn:Bind(eventType.MENU, 
		function(evt) 
			params.language = 'en';
			if dlgColumn:GetWindowName('language'):GetValue() == true then
				params.language = 'fr';
			end	
			bolEnableTirage = dlgColumn:GetWindowName('raz'):GetValue();
			params.column = dlgColumn:GetWindowName('column'):GetValue();
			dlgColumn:EndModal(idButton.OK);
		 end,  btnSave);
	dlgColumn:Fit();
	dlgColumn:ShowModal();
	
	local bolOK = SetGroupes();
	if bolOK == false then
		return false;
	end
	
	dlgConfig = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Configuration du tirage - script version '..script_version, 
		icon='./res/32x32_ffs.png'
		});
	dlgConfig:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		node_value = 'config',
		nb_u14_filles = tU14_Filles:GetNbRows(),
		u14_filles = #tU14_Filles_Groupes,
		nb_u16_filles = tU16_Filles:GetNbRows(),
		u16_filles = #tU16_Filles_Groupes,
		nb_u14_garcons = tU14_Garcons:GetNbRows(),
		u14_garcons = #tU14_Garcons_Groupes,
		nb_u16_garcons = tU16_Garcons:GetNbRows(),
		u16_garcons = #tU16_Garcons_Groupes
		});

	-- Toolbar Principale ...
	local tbconfig = dlgConfig:GetWindowName('tbconfig');
	assert(tbconfig ~= nil);
	tbconfig:AddStretchableSpace();
	local btnPrint = tbconfig:AddTool("Impression des double tirages", "./res/32x32_printer.png");
	tbconfig:AddSeparator();
	local btnSave = tbconfig:AddTool("Lancer le tirage", "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	
	tbconfig:EnableTool(btnSave:GetId(), bolEnableTirage);

	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:EndModal(idButton.CANCEL);
		 end,  btnClose);
		 
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			PrintDoubleTirage();
			dlgConfig:EndModal();
		 end,  btnPrint);

	dlgConfig:Bind(eventType.TEXT, 
		function(evt)
			local dossard1 = dlgConfig:GetWindowName('u16_filles_dossard1'):GetValue();
			dossard1 = tonumber(dossard1) or 0;
			dossard1 = dossard1 + tU16_Filles:GetNbRows();
			dlgConfig:GetWindowName('u16_garcons_dossard1'):SetValue(dossard1);
		 end,  dlgConfig:GetWindowName('u16_filles_dossard1'));

	dlgConfig:Bind(eventType.MENU, 
		function(evt)
			for i = 0, tResultat:GetNbRows() -1 do
				tResultat:SetCellNull('Dossard', i);
			end
			if tU14_Filles:GetNbRows() > 0 then
				local bib_first = tonumber(dlgConfig:GetWindowName('u14_filles_dossard1'):GetValue()) or 1;
				for i = 1, #tU14_Filles_Groupes do
					local groupe = tU14_Filles_Groupes[i].Groupe;
					local nombre = tU14_Filles_Groupes[i].Nombre;
					local tGroupe = tU14_Filles:Copy(true,true);
					OnTirageGroupe(tGroupe, params.code_evenement, bib_first, groupe);
					bib_first = bib_first + nombre;
				end
			end
			if tU16_Filles:GetNbRows() > 0 then
				local bib_first = tonumber(dlgConfig:GetWindowName('u16_filles_dossard1'):GetValue()) or 1;
				for i = 1, #tU16_Filles_Groupes do
					local groupe = tU16_Filles_Groupes[i].Groupe;
					local nombre = tU16_Filles_Groupes[i].Nombre;
					local tGroupe = tU16_Filles:Copy(true,true);
					OnTirageGroupe(tGroupe, params.code_evenement + 1000, bib_first, groupe);
					bib_first = bib_first + nombre;
				end
			end
			if tU14_Garcons:GetNbRows() > 0 then
				local bib_first = tonumber(dlgConfig:GetWindowName('u14_garcons_dossard1'):GetValue()) or 1;
				for i = 1, #tU14_Garcons_Groupes do
					local groupe = tU14_Garcons_Groupes[i].Groupe;
					local nombre = tU14_Garcons_Groupes[i].Nombre;
					local tGroupe = tU14_Garcons:Copy(true,true);
					OnTirageGroupe(tGroupe, params.code_evenement * -1, bib_first, groupe);
					bib_first = bib_first + nombre;
				end
			end
			if tU16_Garcons:GetNbRows() > 0 then
				local bib_first = tonumber(dlgConfig:GetWindowName('u16_garcons_dossard1'):GetValue()) or 1;
				for i = 1, #tU16_Garcons_Groupes do
					local groupe = tU16_Garcons_Groupes[i].Groupe;
					local nombre = tU16_Garcons_Groupes[i].Nombre;
					local tGroupe = tU16_Garcons:Copy(true,true);
					OnTirageGroupe(tGroupe, (params.code_evenement + 1000) * -1, bib_first, groupe);
					bib_first = bib_first + nombre;
				end
			end
			base:TableBulkUpdate(tResultat_Info_Bibo);
			base:TableBulkUpdate(tResultat);
			PrintDoubleTirage();
			dlgConfig:EndModal(idButton.OK);
		 end,  btnSave);

	for i = 1, #tU14_Filles_Groupes do
		if i == 1 then
			dlgConfig:GetWindowName('u14_filles_dossard1'):SetValue(1);
		end
		dlgConfig:GetWindowName('u14_filles_groupe'..i):SetValue(tU14_Filles_Groupes[i].Groupe);
		dlgConfig:GetWindowName('u14_filles_nombre'..i):SetValue(tU14_Filles_Groupes[i].Nombre);
	end
	for i = 1, #tU14_Garcons_Groupes do
		if i == 1 then
			dlgConfig:GetWindowName('u14_garcons_dossard1'):SetValue(1 + tU14_Filles:GetNbRows());
		end
		dlgConfig:GetWindowName('u14_garcons_groupe'..i):SetValue(tU14_Garcons_Groupes[i].Groupe);
		dlgConfig:GetWindowName('u14_garcons_nombre'..i):SetValue(tU14_Garcons_Groupes[i].Nombre);
	end

	for i = 1, #tU16_Filles_Groupes do
		if i == 1 then
			dlgConfig:GetWindowName('u16_filles_dossard1'):SetValue(1);
		end
		dlgConfig:GetWindowName('u16_filles_groupe'..i):SetValue(tU16_Filles_Groupes[i].Groupe);
		dlgConfig:GetWindowName('u16_filles_nombre'..i):SetValue(tU16_Filles_Groupes[i].Nombre);
	end
	for i = 1, #tU16_Garcons_Groupes do
		if i == 1 then
			dlgConfig:GetWindowName('u16_garcons_dossard1'):SetValue(1 + tU16_Filles:GetNbRows());
		end
		dlgConfig:GetWindowName('u16_garcons_groupe'..i):SetValue(tU16_Garcons_Groupes[i].Groupe);
		dlgConfig:GetWindowName('u16_garcons_nombre'..i):SetValue(tU16_Garcons_Groupes[i].Nombre);
	end

	dlgConfig:Fit();
	
	dlgConfig:ShowModal();
	if params.doc then
		params.doc = nil;
	end
	if report then
		report = nil;
	end
end
