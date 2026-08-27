-- LIVE Draw par Philippe Guérindon
-- LIVE Draw par Philippe Guérindon
-- avec chaine = "3rd FIS points list 2026/27"
-- local num, year = string.match(chaine, "^(%d+)%a+%s+FIS points list%s+%d+/(%d+)")
-- donne : num = 3, year = 27

dofile('./edition/functionPG.lua');
dofile('./edition/traductionPG.lua');

--[[

grid:Filter() = on réapplique le filtre avec la table sourse Src
table:FindColumnIndex(colname) -> retourne l'indice de la colonne visible pour la grille
table:FindColumnIndex(indice) -> indice numérique retourne l'indice de la colonne visible pour la grille
table_cible = table_source:Copy(false, true);	--  parametre 1 : false = copie de la structure, true = copie de la structure et des rows. parametre 2 : true va dans le garbage collector

]]

function GetMenuName()
	return "FIS : Live Draw : Tirage en ligne des dossards";
end

function GetActivite()
	return "ALP,TM";
end

function Error(txt)
	adv.Error(txt);
end

function Info(txt)	
	adv.Alert(txt);
end

function Success(txt)
	adv.Success(txt);
end

function Warning(txt)
	adv.Warning(txt);
end

function CreateXmlTriDefault(xml_tri_default)
	-- tDrawG1 dans les 15 de la ECSL en Tech ou dans les 30 en Vitesse (groupe 1 et groupe2)
	-- tDrawG2 les 450+ 
	-- tDrawG3 dans les 30 de la WC après le tri du tableau ou tous les WC en finale avant le tri
	-- tDrawG4 Tous les ECSL
	-- tDrawG5 tous les COC Winners 
	-- tDrawG6 tous les pts FIS 
	local doc_config = xmlDocument.Create();
	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "root");
	if doc_config:SetRoot(nodeRoot) == false then
		return;
	end
	nodeRoot:AddAttribute("Titre", 'Ordre de tri des différents groupes.');
	local nodeCE = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "CoupeEurope");
	nodeCE:AddAttribute('Posit_450', '16');
	nodeCE:AddAttribute('Posit_COC', '31');
	nodeCE:AddAttribute('Prendre_ECSL', '45');
	nodeCE:AddAttribute('Clt_WCSL', '30');
	nodeCE:AddAttribute('Qlf_Finale', '45');
	nodeCE:AddAttribute('Topx_FIS', '75');

	local nodeGroupe1 = xmlNode.Create(nodeCE, xmlNodeType.ELEMENT_NODE, "groupe1", 'ECSL_points DESC,FIS_pts');							-- de 1 à 15
	nodeGroupe1:AddAttribute('Order', '1'); 
	local nodeGroupe2 = xmlNode.Create(nodeCE, xmlNodeType.ELEMENT_NODE, "groupe2", 'ECSL_points DESC,ECSL_overall_points DESC,FIS_pts');	-- les 450+
	nodeGroupe2:AddAttribute('Order', '2');
	local nodeGroupe3 = xmlNode.Create(nodeCE, xmlNodeType.ELEMENT_NODE, "groupe3", 'ECSL_points DESC,WCSL_points DESC,FIS_pts'); 			-- les WCSL
	nodeGroupe3:AddAttribute('Order', '3');
	local nodeGroupe4 = xmlNode.Create(nodeCE, xmlNodeType.ELEMENT_NODE, "groupe4", 'ECSL_points DESC,FIS_pts');							-- les ECSL
	nodeGroupe4:AddAttribute('Order', '4');
	local nodeGroupe5 = xmlNode.Create(nodeCE, xmlNodeType.ELEMENT_NODE, "groupe5", 'ECSL_points DESC,FIS_pts');							-- les COC winners
	nodeGroupe5:AddAttribute('Order', '5');
	nodeRoot:AddChild(nodeCE);
	doc_config:SaveFile(xml_tri_default);
	doc_config:Delete();
end

function OnTimerRunning(evt);
	local nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeKeepalive = xmlNode.Create(nodeRoot, xmlType.ELEMENT_NODE, "keepalive");
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language, 'Demande de maintien de la connexion'));
end

function OnExport(tTable)
	tTable:OrderBy('Dossard, Rang_tirage');
	local chaine = 'Code;CodeFIS;Bib;Name;Surname;Identity;Nation;Sex;YoB;Cat.;Club;FIS Points';
	if config.script_level == 4 and draw.prepare_qualifie then
		chaine = 'Code;CodeFIS;Name;Surname;Identity;Nation;Sex;YoB;Cat.;Club;FIS Points;ECSL_points;Rank;QLF';
		tTable:OrderBy('ECSL_points DESC, FIS_pts');
		for i = tTable:GetNbRows() -1, 0, -1 do
			if tTable:GetCellInt('ECSL_points', i) == 0 then
				tTable:RemoveRowAt(i);
			end
		end
	end
	chaine = chaine..'\n';
	local filename = app.GetPath()..app.GetPathSeparator()..'tmp'..app.GetPathSeparator()..draw.codex..'_racers.csv';
	local f = io.open(filename, 'w')
	if f == nil then 
		local msg = traduction(draw.language,'Merci de fermer le fichier ouvert dans Excel.');
		app.GetAuiFrame():MessageBox(msg, traduction(draw.language,"Exportation des coureurs"), msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION);
		return;
	end
	f:write(chaine);
	local order_qlf = 0;
	for i = 0, tTable:GetNbRows() -1 do
		local pts = string.gsub(tTable:GetCell('FIS_pts', i),"%.",",");
		chaine = string.sub(tTable:GetCell('Code_coureur', i), 4);
		chaine = chaine..';'..tTable:GetCell('Code_coureur', i);
		if not draw.prepare_qualifie then
			chaine = chaine..';'..tTable:GetCell('Dossard', i);
		end
		chaine = chaine..';'..tTable:GetCell('Nom', i);
		chaine = chaine..';'..tTable:GetCell('Prenom', i);
		chaine = chaine..';'..tTable:GetCell('Nom', i)..' '..tTable:GetCell('Prenom', i);
		chaine = chaine..';'..tTable:GetCell('Nation', i);
		chaine = chaine..';'..tTable:GetCell('Sexe', i);
		chaine = chaine..';'..tTable:GetCell('An', i);
		chaine = chaine..';'..tTable:GetCell('Categ', i);
		chaine = chaine..';'..tTable:GetCell('Club', i);
		chaine = chaine..';'..pts;
		if draw.prepare_qualifie then
			chaine = chaine..';'..tTable:GetCellInt('ECSL_points', i);
			chaine = chaine..';'..tTable:GetCellInt('ECSL_rank', i);
			if tTable:GetCell('TG', i) == 'QLF' then
				order_qlf = order_qlf + 1;
				chaine = chaine..';'..tTable:GetCell('TG', i)..'-'..string.format( "%02d", tostring(order_qlf));
			else
				chaine = chaine..';'..tTable:GetCell('TG', i);
			end
		end
		chaine = chaine..'\n';
		-- chaine = chaine;
			
		f:write(chaine);
	end
	f:close();
	local msg = traduction(draw.language, 'Les coureurs ont été exportés dans le fichier')..'\n'..filename..traduction(draw.language, ' qui se trouve dans\nle répertoire tmp de skiFFS.');
	app.GetAuiFrame():MessageBox(msg, traduction(draw.language, "Exportation des coureurs"), msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION);
end

function OnClose()
	local cmd = "Update Resultat Set Reserve = Null Where Code_evenement = "..draw.code_evenement;
	base:Query(cmd);
	if draw.socket ~= nil then
		draw.socket:Close();
		Error("CONNEXION SERVEUR FIS KO ...");
	end
	
	if config.doc ~= nil then
		config.doc:SaveFile();
	end
	
	if draw.timer ~= nil then
		draw.timer:Delete();
	end
end

function SortTable(array, colnom, sens)	-- tri des tables 
	if sens == '<' then
		table.sort(array, function (u,v)
			return u[colnom] < v[colnom];
		end)
	else
		table.sort(array, function (u,v)
			return u[colnom] > v[colnom];
		end)
	end
end

function GetEpreuve()
	dlgGetEpreuve = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		label='Calcul des quotas : '..script_version.. ' - par Philippe Guérindon' , 
		icon='./res/32x32_fis.png'
		});
	
	dlgGetEpreuve:LoadTemplateXML({ 
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 
		node_value = 'get_epreuve',
		});


	-- Toolbar Principale ...
	local tbconfig = dlgGetEpreuve:GetWindowName('tbgetepreuve');
	tbconfig:AddStretchableSpace();
	local btnSave = tbconfig:AddTool("Valider", "./res/32x32_printer.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	
	dlgGetEpreuve:GetWindowName('num_epreuve'):Clear();
	for i = 0, tEpreuve:GetNbRows() -1 do
		dlgGetEpreuve:GetWindowName('num_epreuve'):Append((i+1)..' - '..tEpreuve:GetCell('Date_epreuve', i)..' / '..tEpreuve:GetCell('Sexe', i)..' / '..tEpreuve:GetCell('Code_discipline', i)..' / '..tEpreuve:GetCell('Fichier_transfert', i));
	end
	dlgGetEpreuve:GetWindowName('num_epreuve'):SetSelection(0);
	dlgGetEpreuve:Bind(eventType.MENU, 
		function(evt)
			draw.row_epreuve = dlgGetEpreuve:GetWindowName('num_epreuve'):GetSelection();
			dlgGetEpreuve:EndModal();
		end, btnSave);
		
	dlgGetEpreuve:Fit();
	dlgGetEpreuve:ShowModal();

end

function OnSaveBackOffice(evt)
	local bolOK = true;
	-- config.posit_450 = tonumber(dlgBackOffice:GetWindowName('pos_450+'):GetValue()) or 16;
	config.posit_450 = 16;
	config.posit_COC = tonumber(dlgBackOffice:GetWindowName('pos_COC'):GetValue()) or 31;
	config.prendre_ECSL = tonumber(dlgBackOffice:GetWindowName('nb_ECSL'):GetValue()) or 45;
	config.clt_WCSL = tonumber(dlgBackOffice:GetWindowName('clt_WCSL'):GetValue()) or 30;
	config.qlf_Finale = tonumber(dlgBackOffice:GetWindowName('qlf_Finale'):GetValue()) or 45;
	config.topx_FIS = tonumber(dlgBackOffice:GetWindowName('topx_FIS'):GetValue()) or 75;
	local xml_tri_default = app.GetPath()..'/liveDraw_tri.xml';
	local doc = xmlDocument.Create(xml_tri_default);
	local nodeName = 'root/CoupeEurope';
	local node = doc:FindFirst(nodeName);
	nodelivedraw:ChangeAttribute('ECSL_'..draw.code_evenement, filename);
	node:ChangeAttribute('Posit_450', config.posit_450);
	node:ChangeAttribute('Posit_COC', config.posit_COC);
	node:ChangeAttribute('Prendre_ECSL', config.prendre_ECSL);
	node:ChangeAttribute('Clt_WCSL', config.clt_WCSL);
	node:ChangeAttribute('Qlf_Finale', config.qlf_Finale);
	node:ChangeAttribute('Topx_FIS', config.topx_FIS);
	for i = 1, 5 do
		nodeName = 'root/CoupeEurope/groupe'..i;
		node = doc:FindFirst(nodeName);
		if dlgBackOffice:GetWindowName('clef_g'..i):GetValue():len() > 0 then
			node:SetNodeContent(dlgBackOffice:GetWindowName('clef_g'..i):GetValue());
			draw.tClefTri[i].OrderBy = dlgBackOffice:GetWindowName('clef_g'..i):GetValue();
		else
			bolOK = false;
		end
	end
	if bolOK == true then
		doc:SaveFile();
	end
end

function OnAfficheBackOffice()
-- Création Dialog 
	draw.label_dialog = 'Back office du script';
	
	dlgBackOffice = wnd.CreateDialog(
		{
		width = config.width,
		height = config.height,
		x = config.x,
		y = config.y,
		label=draw.label_dialog, 
		icon='./res/32x32_fis.png'
		});
	
	dlgBackOffice:LoadTemplateXML({ 
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 
		language = draw.language,	
		node_value = 'backoffice'
	});
	-- dlgBackOffice:GetWindowName('pos_450+'):SetValue(config.posit_450);
	dlgBackOffice:GetWindowName('pos_COC'):SetValue(config.posit_COC);
	dlgBackOffice:GetWindowName('nb_ECSL'):SetValue(config.prendre_ECSL);
	dlgBackOffice:GetWindowName('clt_WCSL'):SetValue(config.clt_WCSL);
	dlgBackOffice:GetWindowName('qlf_Finale'):SetValue(config.qlf_Finale);
	dlgBackOffice:GetWindowName('topx_FIS'):SetValue(config.topx_FIS);

	for i = 1, 5 do
		dlgBackOffice:GetWindowName('clef_g'..i):SetValue(draw.tClefTri[i].OrderBy);
		-- table.insert(draw.tClefTri, {Groupe = groupe, OrderBy = orderby, Order = ordre});
		dlgBackOffice:GetWindowName('groupe'..i):Clear();
		dlgBackOffice:GetWindowName('groupe'..i):Append('');
		dlgBackOffice:GetWindowName('groupe'..i):Append('ECSL_points DESC');
		dlgBackOffice:GetWindowName('groupe'..i):Append('WCSL_points DESC');
		dlgBackOffice:GetWindowName('groupe'..i):Append('FIS_pts');
		dlgBackOffice:Bind(eventType.COMBOBOX, 
			function(evt)
				local idx = dlgBackOffice:GetWindowName('groupe'..i):GetSelection();
				if idx > 0 then
					local chaine = dlgBackOffice:GetWindowName('clef_g'..i):GetValue();
					if chaine:len() == 0 then
						chaine = dlgBackOffice:GetWindowName('groupe'..i):GetValue();
					else
						chaine = chaine..','..dlgBackOffice:GetWindowName('groupe'..i):GetValue();
					end
					dlgBackOffice:GetWindowName('clef_g'..i):SetValue(chaine);
				else
					dlgBackOffice:GetWindowName('clef_g'..i):SetValue('');
				end
			end, 
			dlgBackOffice:GetWindowName('groupe'..i))
	end			

	local tb = dlgBackOffice:GetWindowName('tbbackoffice');
	tb:AddStretchableSpace();
	local btnSave = tb:AddTool(traduction(draw.language, "Enregistrer"), "./res/vpe32x32_save.png");
	tb:AddSeparator();
	local btnClose = tb:AddTool("Quitter", "./res/32x32_exit.png");

	tb:AddStretchableSpace();
	tb:Realize();
	
	dlgBackOffice:Bind(eventType.MENU, OnSaveBackOffice, btnSave);
	dlgBackOffice:Bind(eventType.MENU, 
		function(evt) 
			dlgBackOffice:EndModal(idButton.CANCEL);
		 end,  btnClose);
	dlgBackOffice:Fit();
	dlgBackOffice:ShowModal();

end

function GetRowsGroupe2()
	local first_row = -1;
	local last_row = -1;
	for i = 0, tDraw:GetNbRows() -1 do
		if tDraw:GetCellInt('Groupe_tirage', i) == 1 and tDraw:GetCell('Dossard', i):len() == 0 then
			return -1, -1;
		end
		if tDraw:GetCellInt('Groupe_tirage', i) == 2 then
			tDraw:SetCellNull('Dossard', i);
			last_row = i;
			if first_row < 0 then
				first_row = i;
			end
		end
	end
	return first_row, last_row;
end

function DoRazColOverAll(saison)
	local col_pts = '';
	local col_rank= '';
	if saison == 0 then
		col_pts = 'ECSL_overall_points_0';
		col_rank = 'ECSL_overall_pos_0';
	else
		col_pts = 'ECSL_overall_points_n';
		col_rank = 'ECSL_overall_pos_n';
	end
	for i =0 , tDraw:GetNbRows() -1 do
		tDraw:SetCellNull(col_pts, i);
		tDraw:SetCellNull(col_rank, i);
	end
end

function InitTableauCoureur(fiscode)
	tTableauCoureur[fiscode] = {};
	tTableauCoureur[fiscode].FIS_pts = 0;
	tTableauCoureur[fiscode].FIS_clt = 0;
	tTableauCoureur[fiscode].FIS_VIT_pts = 0;
	tTableauCoureur[fiscode].FIS_VIT_clt = 0;
	tTableauCoureur[fiscode].ECSL_points = 0;
	tTableauCoureur[fiscode].ECSL_rank = 0;
	tTableauCoureur[fiscode].ECSL_overall_points = 0;
	tTableauCoureur[fiscode].ECSL_overall_rank = 0;
	tTableauCoureur[fiscode].ECSL_overall_points_0 = 0;
	tTableauCoureur[fiscode].ECSL_overall_rank_0 = 0;
	tTableauCoureur[fiscode].ECSL_overall_points_n = 0;
	tTableauCoureur[fiscode].ECSL_overall_rank_n = 0;
	tTableauCoureur[fiscode].WCSL_points = 0;
	tTableauCoureur[fiscode].WCSL_rank = 0;
end

function ChargeECSL(filename)
	local header = true;
	local utf8 = true;
	local tcols = {};
	local tEcsl = sqlTable.ImportCSV(filename, ',', header, utf8);
	if tEcsl ~= nil then
		for i = 0, tEcsl:GetNbColumns() -1 do
			local colname = tEcsl:GetColumnName(i);
			if colname:Trim() == 'Fiscode' then
				tcols.Fiscode = i;
			end
			if colname:Trim() == draw.discipline..'points' then
				tcols.Pts = i;
			end
			if colname:Trim() == draw.discipline..'pos' then
				tcols.Rank = i;
			end
		end
		for i = 0, tEcsl:GetNbRows() -1 do
			local fiscode = 'FIS'..tEcsl:GetCell(tcols.Fiscode, i);
			if not tTableauCoureur[fiscode] then
				InitTableauCoureur(fiscode);
			end
			local pts = tonumber(tEcsl:GetCell(tcols.Pts, i)) or 0;
			local rank = tonumber(tEcsl:GetCell(tcols.Rank, i)) or 0;
			tTableauCoureur[fiscode].ECSL_points = pts;
			tTableauCoureur[fiscode].ECSL_rank = rank;
		end
		
		for i = 0, tDraw:GetNbRows() -1 do
			local fiscode = tDraw:GetCell('Code_coureur', i);
			if not tTableauCoureur[fiscode] then
				InitTableauCoureur(fiscode);
			end
			tDraw:SetCellNull('ECSL_points', i);
			tDraw:SetCellNull('ECSL_rank', i);
			if draw.finale_ce == 'Oui' or draw.finale_ce == 'Yes' then
				tDraw:SetCellNull('ECSL_overall_points', i);
				tDraw:SetCellNull('ECSL_overall_rank', i);
			end
			if tTableauCoureur[fiscode].ECSL_points > 0 then
				tDraw:SetCell('ECSL_points', i, tTableauCoureur[fiscode].ECSL_points);
				tDraw:SetCell('ECSL_rank', i, tTableauCoureur[fiscode].ECSL_rank);
			end
		end
	end
	draw.ECSL_done = true;
	RefreshGrid();
end

function ReadECSL()
	local filename = '';
	local fileDialog = wnd.CreateFileDialog(dlgScriptLua,
		"Recherche du fichier ECSL ",
		app.GetPath(), 
		"",
		"*.csv|*.csv",
		fileDialogStyle.OPEN+fileDialogStyle.FD_FILE_MUST_EXIST
	);
	if fileDialog:ShowModal() == idButton.OK then
		filename = string.gsub(fileDialog:GetPath(), app.GetPathSeparator(), "/");
		if nodelivedraw:HasAttribute('ECSL_'..draw.code_evenement) then
			nodelivedraw:ChangeAttribute('ECSL_'..draw.code_evenement, filename);
		else
			nodelivedraw:AddAttribute('ECSL_'..draw.code_evenement, filename);
		end
		config.doc:SaveFile()
	end
	if filename:len() > 0 then
		ChargeECSL(filename);
	end
end

function ChargeECPrevious(filename)
	if draw.finale_ce == 'Oui' or draw.finale_ce == 'Yes' then
		return;
	end
	local header = true;
	local utf8 = true;
	local tcols = {};
	local tAllPrevious = sqlTable.ImportCSV(filename, ',', header, utf8);
	if tAllPrevious ~= nil then
		for i = 0, tAllPrevious:GetNbColumns() -1 do
			local colname = tAllPrevious:GetColumnName(i);
			if colname:Trim() == 'Fiscode' then
				tcols.Fiscode = i;
			end
			if colname:Trim() == 'ALLpoints' then
				tcols.Allpoints = i;
			end
			if colname:Trim()== 'ALLpos' then
				tcols.Allpos = i;
			end
		end
		for i = 0, tAllPrevious:GetNbRows() -1 do
			local fiscode = 'FIS'..	tAllPrevious:GetCell(tcols.Fiscode,i);
			if not tTableauCoureur[fiscode] then
				InitTableauCoureur(fiscode);
			end
			local pts = tonumber(tAllPrevious:GetCell(tcols.Allpoints,i)) or 0;
			local rank = tonumber(tAllPrevious:GetCell(tcols.Allpos)) or 0;
			tTableauCoureur[fiscode].ECSL_overall_points_0 = pts;
		end
		for i = 0, tDraw:GetNbRows() -1 do
			local fiscode = tDraw:GetCell('Code_coureur', i);
			local pts_n = tDraw:GetCellInt('ECSL_overall_points', i);
			local pts_0 = tTableauCoureur[fiscode].ECSL_overall_points_0;
			tDraw:SetCell('ECSL_overall_points_0', i, pts_0);
			local maxPts = math.max(pts_n, pts_0);
			if maxPts >= 450 then
				tDraw:SetCell('ECSL_overall_points', i, maxPts);
			end
		end
		tAllPrevious:Delete();
	end
	RefreshGrid();
end

function ReadECPrevious()
	-- adv.Alert('draw.finale_ce = '..draw.finale_ce);
	if draw.finale_ce == 'Oui' or draw.finale_ce == 'Yes' then
		return;
	end
	local filename = '';
	local fileDialog = wnd.CreateFileDialog(dlgScriptLua,
		"Recherche du fichier EC Standing N-1",
		app.GetPath(), 
		"",
		"*.csv|*.csv",
		fileDialogStyle.OPEN+fileDialogStyle.FD_FILE_MUST_EXIST
	);
	if fileDialog:ShowModal() == idButton.OK then
		filename = string.gsub(fileDialog:GetPath(), app.GetPathSeparator(), "/");
		if nodelivedraw:HasAttribute('EC_PREVIOUS_'..draw.sexe) then
			nodelivedraw:ChangeAttribute('EC_PREVIOUS_'..draw.sexe, filename);
		else
			nodelivedraw:AddAttribute('EC_PREVIOUS_'..draw.sexe, filename);
		end
		config.doc:SaveFile()
	end
	if filename:len() > 0 then
		ChargeECPrevious(filename);
	end
end

function ChargeWCSL(filename)
	local header = true;
	local utf8 = true;
	local tColsWCSL = {};
	local tWcsl = sqlTable.ImportCSV(filename, ',', header, utf8);
	if tWcsl ~= nil then
		for i = 0, tWcsl:GetNbColumns() -1 do
			local colname = tWcsl:GetColumnName(i);
			if colname:Trim() == 'Fiscode' then
				tColsWCSL.Fiscode = i;
			end
			if colname:Trim() == draw.discipline..'points_value' then
				tColsWCSL.Pts = i;
			end
			if colname:Trim() == draw.discipline..'pos' then
				tColsWCSL.Rank = i;
			end
		end
		for i = 0, tWcsl:GetNbRows() -1 do
			local fiscode = 'FIS'..tWcsl:GetCell(tColsWCSL.Fiscode, i);
			if not tTableauCoureur[fiscode] then
				InitTableauCoureur(fiscode);
			end
				
			local pts = tonumber(tWcsl:GetCell(tColsWCSL.Pts, i)) or 0;
			local rank = tonumber(tWcsl:GetCell(tColsWCSL.Rank, i)) or 0;
			tTableauCoureur[fiscode].WCSL_points = pts;
			tTableauCoureur[fiscode].WCSL_rank = rank;
		end
		
		for i = 0, tDraw:GetNbRows() -1 do
			local fiscode = tDraw:GetCell('Code_coureur', i);
			tDraw:SetCellNull('WCSL_points', i);
			tDraw:SetCellNull('WCSL_rank', i);
			if tTableauCoureur[fiscode].WCSL_rank > 0 and tTableauCoureur[fiscode].WCSL_rank <= 30 then
				tDraw:SetCell('WCSL_points', i, tTableauCoureur[fiscode].WCSL_points);
				tDraw:SetCell('WCSL_rank', i, tTableauCoureur[fiscode].WCSL_rank);
			end
		end
	end
	draw.WCSL_done = true;
	RefreshGrid();
end

function ReadWCSL()
	local filename = '';
	local fileDialog = wnd.CreateFileDialog(dlgScriptLua,
		"Recherche du fichier WCSL ",
		app.GetPath(), 
		"",
		"*.csv|*.csv",
		fileDialogStyle.OPEN+fileDialogStyle.FD_FILE_MUST_EXIST
	);
	if fileDialog:ShowModal() == idButton.OK then
		filename = string.gsub(fileDialog:GetPath(), app.GetPathSeparator(), "/");
		if nodelivedraw:HasAttribute('WCSL_'..draw.code_evenement) then
			nodelivedraw:ChangeAttribute('WCSL_'..draw.code_evenement, filename);
		else
			nodelivedraw:AddAttribute('WCSL_'..draw.code_evenement, filename);
		end
		config.doc:SaveFile()
	end
	if filename:len() > 0 then
		ChargeWCSL(filename);
	end
end

function ChargeListeFIS(filename, code_liste)

	dlgFisList = wnd.CreateDialog({
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.STAY_ON_TOP+wndStyle.CLOSE_BOX,
		icon = "./res/16x16_agil.png",
		label = 'FIS list',
		x = (config.width / 2) - 250,
		y = 200,
		width = 500,
		height = 200
	});
	
	dlgFisList:LoadTemplateXML({ 
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'fislist'
		});

	dlgFisList:Show();

	base:Query('DELETE FROM Classement_Coureur WHERE Code_liste = '..code_liste..' And Type_classement In("IADH","IASG","IAGS","IASL","IAAC")');
	base:Query('DELETE FROM Liste WHERE Code_liste = '..code_liste.." And Type_classement = 'IAU'");
	-- Listid	Listname	listPublished	Published	Sectorcode	Status	Competitorid	Fiscode	Lastname	Firstname	Nationcode	Gender	Birthdate	Skiclub	Nationalcode	Competitorname	Birthyear	Calculationdate	DHpoints	DHpos	DHSta	SLpoints	SLpos	SLSta	GSpoints	GSpos	GSSta	SGpoints	SGpos	SGSta	ACpoints	ACpos	ACSta
	local tTypeclassement = {'DH', 'SG', 'GS', 'SL', 'AC'};
	local header = true;
	local utf8 = true;
	tClassement_Coureur = base:GetTable('Classement_Coureur');
	local tFislist = sqlTable.ImportCSV(filename, ',', header, utf8);
	if tFislist ~= nil then
		for i = 0, tFislist:GetNbRows() -1 do
			if i % 100 == 0 then
				dlgFisList:GetWindowName('count'):SetLabel('Line '..i..' / '.. tFislist:GetNbRows());
				dlgFisList:Refresh();
			end
			if i == 0 then
				local list_name = tFislist:GetCell('Listname', i);
				local tTemp = list_name:Split('/');     --16th FIS points list 2025/26
				local annee = tonumber(tTemp[2]) or 0;
				local saison_liste = 2000 + annee;
				local row = tListe:AddRow();
				tListe:SetCell('Code_liste', row, code_liste);
				tListe:SetCell('Type_classement', row, 'IAU');
				tListe:SetCell('Commentaire', row, 'Liste F.I.S N '..code_liste..' (Alpin)');
				tListe:SetCell('Seasoncode', row, saison_liste);
				base:TableInsert(tListe, row);
			end
			local code_coureur = 'FIS'..tFislist:GetCell('Fiscode', i);
			for j = 1, #tTypeclassement do
				local type_classement = tTypeclassement[j];
				local iax_pts = tFislist:GetCell(type_classement..'points', i);
				local iax_clt = tFislist:GetCell(type_classement..'pos', i);
				if iax_pts:len() > 0 then
					local row = tClassement_Coureur:AddRow();
					tClassement_Coureur:SetCell('Code_coureur',row,code_coureur);
					tClassement_Coureur:SetCell('Type_classement',row,'IA'..type_classement);
					tClassement_Coureur:SetCell('Code_liste',row, code_liste);
					tClassement_Coureur:SetCell('Pts', row, tonumber(iax_pts));
					tClassement_Coureur:SetCell('Clt', row, tonumber(iax_clt));
				end
			end
		end
		dlgFisList:GetWindowName('count'):SetLabel('Line '..tFislist:GetNbRows()..' / '.. tFislist:GetNbRows());
		dlgFisList:Refresh();
		base:TableBulkInsert(tClassement_Coureur, 'Code_coureur,Type_classement,Code_liste,Pts,Clt','Classement_Coureur');
		tFislist:Delete();
	end
	dlgFisList:Close();
	dlgFisList = nil;
	local msg = traduction(draw.language, "Voulez-vous mettre à jour les points avec la nouvelle liste ?");
	if dlgTableau:MessageBox(
		msg, 
		traduction(draw.language,"Mise à jour des points"), 
		msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION
	) == msgBoxStyle.YES then
		base:Query('Update Evenement Set Code_liste = '..code_liste..' Where Code = '..draw.code_evenement);
		draw.code_liste = code_liste;
		for i = 0, tDraw:GetNbRows() -1 do
			local code_coureur = tDraw:GetCell('Code_coureur', i);
			local pts, rank, pts_VIT, rank_VIT = GetRank(code_coureur);
			if pts and pts >= 0 then
				tDraw:SetCell('FIS_pts', i, pts);
				tDraw:SetCell('FIS_clt', i, rank);
			else
				tDraw:SetCellNull('FIS_pts', i);
				tDraw:SetCellNull('FIS_clt', i);
			end
			if pts_VIT and pts_VIT >= 0 then
				tDraw:SetCell('FIS_VIT_pts', i, pts_VIT);
				tDraw:SetCell('FIS_VIT_clt', i, rank_VIT);
			else
				tDraw:SetCellNull('FIS_VIT_pts', i);
				tDraw:SetCellNull('FIS_VIT_clt', i);
			end
			local r = tResultat:GetIndexRow('Code_coureur',code_coureur);
			if r >= 0 then
				tResultat:SetCell('Point', r, pts);
			end
		end
		base:TableBulkUpdate(tResultat);
		msg = traduction(draw.language,"Vous devez retrier le tableau !");
		dlgTableau:MessageBox(
			msg, 
			traduction(draw.language,"Mise à jour des points"), 
			msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION
		) 
	end
	RefreshGrid();
end

function ReadFISlist()
	local filename = '';
	local fileDialog = wnd.CreateFileDialog(dlgScriptLua,
		"Recherche du fichier Fiste FIS",
		app.GetPath(), 
		"",
		"*.csv|*.csv",
		fileDialogStyle.OPEN+fileDialogStyle.FD_FILE_MUST_EXIST
	);
	if fileDialog:ShowModal() == idButton.OK then
		filename = string.gsub(fileDialog:GetPath(), app.GetPathSeparator(), "/");
	end
	if filename:len() > 0 then
		dlgListe =  wnd.CreateDialog(
			{
			width = 400,
			height = 200,
			x = 500,
			y = 400,
			label='FIS List', 
			icon='./res/32x32_fis.png'
			});
		
		dlgListe:LoadTemplateXML({ 
			xml = './process/dossard_LiveDraw.xml',
			node_name = 'root/panel', 
			node_attr = 'name', 	
			node_value = 'importlist',
			language = draw.language
			});
		tbListe = dlgListe:GetWindowName('tb');
		tbListe:AddStretchableSpace();
		list_btnSave = tbListe:AddTool(traduction(draw.language,"Télécharger"), "./res/vpe32x32_save.png", strLabelButton);
		tbListe:AddSeparator();
		list_btnClose = tbListe:AddTool(traduction(draw.language, "Quitter"), "./res/32x32_exit.png");
		tbListe:AddStretchableSpace();
		tbListe:Realize();

		dlgListe:Bind(eventType.MENU, 
			function(evt) 
				dlgListe:EndModal(idButton.CANCEL) 
			 end,  list_btnClose);
		dlgListe:Bind(eventType.MENU, 
			function(evt) 
				code_liste = tonumber(dlgListe:GetWindowName('code'):GetValue()) or -1;
				if code_liste > 0 then
					dlgListe:EndModal(idButton.OK);
				end
			 end,  list_btnSave);

		if dlgListe:ShowModal() == idButton.OK then
			ChargeListeFIS(filename, code_liste);
		end
	end
end

-- fonctions des événements concernant les séquences
function IncrementationSequenceSend()
	assert(draw.sequence_send ~= nil);
	draw.sequence_send = draw.sequence_send + 1;
	nodelivedraw:ChangeAttribute('send', draw.sequence_send);
	RefreshCounterSequence();
end

function SaveSequenceAck()
	nodelivedraw:ChangeAttribute('ack', draw.sequence_ack);
	RefreshCounterSequence();
end

-- Acquitement XML
function ReadAckXML(stringXml)
	if string.len(stringXml) == 0 then return false end

	local doc = xmlDocument.Create();
	if doc:LoadString(stringXml) == true then
		local root = doc:GetRoot();
		if root ~= nil then
			if root:HasAttribute('sequence') then
				sequence = root:GetAttribute('sequence');
				draw.sequence_ack = tonumber(sequence);
				SaveSequenceAck();
				SendNextPacket();
				doc:Delete();
				return true;
			elseif root:HasAttribute('error') then
				local txtError = root:GetAttribute('error');
				Error('ReadAckXML : '..txtError);
				doc:Delete();
				return false;
			end
		end
	end
	draw.message = draw.sequence_ack..' / '..draw.sequence_send;
	dlgTableau:GetWindowName('sequence'):SetValue(draw.message);
	dlgTableau:Refresh();
	
	Error('ReadAckXML : XML invalid '..stringXml);
	return false;
end

function RefreshCounterSequence()
	draw.sequence_ack = draw.sequence_ack or 0;
	draw.sequence_send = draw.sequence_send or 0;
	dlgTableau:GetWindowName('sequence'):SetValue(traduction(draw.language,'Trame ')..draw.sequence_ack..' / '..draw.sequence_send);
	dlgTableau:Refresh();
end

-- Envoi Packet 
function SendNextPacket()
	if draw.sequence_ack == draw.sequence_send then
		return; -- Tout est Acquitté ...
	end
	if draw.sequence_last_send ~= nil and draw.sequence_ack < draw.sequence_last_send then
		return -- la dernière séquence envoyée n'a pas encore été acquittée.
	end
	
	if draw.sequence_last_send ~= nil and draw.sequence_ack < draw.sequence_last_send then
		Info(traduction(draw.language, "la dernière séquence envoyée n'a pas encore été acquittée"));
		return -- la dernière séquence envoyée n'a pas encore été acquittée.
	end
	
	local sequence_next = draw.sequence_ack + 1;
	
	-- Lecture du Xml ...
	local xmlFile = draw.directory..'/live'..draw.codex..'_'..tostring(sequence_next)..'.xml';
	local doc = xmlDocument.Create(xmlFile);
	local xmlText = doc:SaveString();
	doc:Delete();
	
	-- Envoi du XML
	local UTF8 = true;
	if draw.method == 'socket' then
		draw.socket:WriteString(xmlText, UTF8);	
	end
	draw.sequence_last_send = sequence_next;
end

function OnResetSocket(evt)
	local msg = traduction(draw.language, "Confirmation de la réinitialisation de la connexion").."\n\n"..
		traduction(draw.language, "La connexion avec la FIS sera interronpue puis réinitialisée.").."\n"..
		traduction(draw.language, "Vous devrez éventuellement renvoyer les informations manquantes à la FIS.");
	if dlgTableau:MessageBox(
		msg, 
		traduction(draw.language,"Reset de la connexion avec la FIS"), 
		msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION
	) ~= msgBoxStyle.YES then
		return;
	end

	Info(traduction(draw.language,'Demande de réinitialisation'));
	DoResetSocket();
end

function DoResetSocket()
	-- on ferme le socket
	if draw.socket ~= nil then
		draw.socket:Close();
	end

	draw.socket_state = false;
	draw.sequence_last_send = nil;
	parentFrame = wnd.GetParentFrame();
	draw.socket = socketClient.Open(parentFrame, draw.hostname, config.port);

	if draw.socket ~= nil then
		parentFrame:Bind(eventType.SOCKET, OnSocketLive, draw.socket);
	end
end


-- Event Socket
function OnSocketLive(evt)
	if evt:GetSocketEvent() == socketNotify.INPUT then
		-- INPUT
		draw.socket:ReadToCircularBuffer();
		local cb = draw.socket:GetCircularBuffer();
		local count = cb:GetCount();
		local stringXml = cb:ReadString();
		ReadAckXML(stringXml);
	elseif evt:GetSocketEvent() == socketNotify.CONNECTION then
		-- CONNECTION
		local tPeer = draw.socket:GetPeer();
		Success("CONNEXION SERVEUR FIS OK ...");
		draw.socket_state = true;
		SendNextPacket();
	elseif evt.GetSocketEvent() == socketNotify.LOST then
		-- LOST
		Warning("CONNEXION FIS PERDUE ...");
		draw.socket_state = false;
	end
end

function OnAide()
	app.LaunchDefaultEditor('./process/LivedrawHelp_'..draw.language..'.rtf');
end

function OnDecaler(row, bolVersLeBas, bolGroupe)
	local plus = 1;
	if bolVersLeBas == false then
		plus = -1;
	end
	-- adv.Alert('OnDecaler('..row..', '..tostring(bolVersLeBas)..', '..tostring(bolGroupe)..')');
	for i = row, tDraw:GetNbRows() -1 do
		if not bolGroupe then
			local rang_tirage = tDraw:GetCellInt('Rang_tirage', i) + plus;
			tDraw:SetCell('Rang_tirage', i, rang_tirage);
		else
			local groupe_tirage = tDraw:GetCellInt('Groupe_tirage', i) + plus;
			tDraw:SetCell('Groupe_tirage', i, groupe_tirage);
		end
	end
	RefreshGrid();
end

function BuildTableTirage(bib_first, nb_groupe)
	params.tableDossards1 = {};
	for index = 0, nb_groupe -1  do
		table.insert(params.tableDossards1, bib_first + index);
	end
	params.tableDossards1 = Shuffle(params.tableDossards1);
	for _ = 1, 5 do
		math.random();
	end	
	tTableTirage1:RemoveAllRows();
	for index = 0, nb_groupe -1 do
		row = index + 1;
		local new_row1 = tTableTirage1:AddRow();
		tTableTirage1:SetCell('Row', new_row1, row);
		local aleatoire = randomFloat(1, 2);
		tTableTirage1:SetCell('Aleatoire', new_row1, aleatoire);
	end
	
	tTableTirage1:OrderBy('Aleatoire');
	for i = 0, tTableTirage1:GetNbRows() -1 do
		local ligne = tTableTirage1:GetCellInt('Row', i);
		local dossard = params.tableDossards1[ligne];
		tDrawG6:SetCell('Dossard', i, dossard);
		local identite = tDrawG6:GetCell('Nom', i)..' '..tDrawG6:GetCell('Prenom', i);
		local code_coureur = tDrawG6:GetCell('Code_coureur', i);
		local r = tDraw:GetIndexRow('Code_coureur', code_coureur)
		if r >= 0 then
			tDraw:SetCell('Dossard', r, dossard);
		end
	end
	RefreshGrid();
end

function randomFloat(a, b)
    return a + (b - a) * math.random()
end

function BuildTableTirageVitesse()
	-- Génération d'une graine basée sur time et clock

	params.tableDossards1 = {};
	local ligne = 0;
	-- adv.Alert('#draw.tDossardsAvailable = '..#draw.tDossardsAvailable);
	for i = 1, #draw.tDossardsAvailable do
		if draw.tDossardsAvailable[i].Pris == 0 then
			ligne = ligne + 1
			table.insert(params.tableDossards1, draw.tDossardsAvailable[i].Dossard);
		end
	end
	for _ = 1, 5 do
		math.random();
	end

	params.tableDossards1 = Shuffle(params.tableDossards1);
	tTableTirage1:RemoveAllRows();
	for row = 0, ligne -1 do
		local new_row1 = tTableTirage1:AddRow();
		local aleatoire = randomFloat(0, 1);
		tTableTirage1:SetCell('Row', new_row1, row + 1);
		tTableTirage1:SetCell('Aleatoire', new_row1, aleatoire);
	end
	tTableTirage1:OrderBy('Aleatoire');
	for i = 0, #params.tableDossards1 -1 do
		local ligne = tTableTirage1:GetCellInt('Row', i);
		local dossard = params.tableDossards1[ligne];
		tDrawG6:SetCell('Dossard', i, dossard);
		local identite = tDrawG6:GetCell('Nom', i)..' '..tDrawG6:GetCell('Prenom', i);
		local code_coureur = tDrawG6:GetCell('Code_coureur', i);
		local r = tDraw:GetIndexRow('Code_coureur', code_coureur)
		if r >= 0 then
			tDraw:SetCell('Dossard', r, dossard);
		end
	end
	RefreshGrid();
end

function OnDecodeJson(groupe)
	params.Draw = groupe;
	local cmd = 'Select * From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement..' And Groupe = '..groupe;
	base:TableLoad(tResultat_Info_Bibo, cmd);
	tResultat_Info_Bibo:OrderBy('Groupe, Ligne');
	tDrawG6 = tDraw:Copy(false,true);
	--tDrawG6:RemoveAllRows();
	params.tableDossards1 = {};
	tTableTirage1:RemoveAllRows();
	if groupe == 1 then
		draw.nb_groupe_1 = tResultat_Info_Bibo:GetNbRows();
	end
	for i = 0, tResultat_Info_Bibo:GetNbRows() -1 do
		local jsontxt1 = tResultat_Info_Bibo:GetCell('Table1', i);
		local xTable1 = table.FromStringJSON(jsontxt1);
		table.insert(params.tableDossards1, xTable1.Table1[1].Col2);
		
		local jsontxt2 = tResultat_Info_Bibo:GetCell('Table2', i);
		local xTable2 = table.FromStringJSON(jsontxt2);
		local row1 = tTableTirage1:AddRow();
		local identite = xTable2.Table2[1].Col1;
		local pts = tonumber(xTable2.Table2[1].Col2) or 0;
		local rang_fictif = xTable2.Table2[1].Col3 ;
		local dossard = xTable2.Table2[1].Col4;
		tTableTirage1:SetCell('Row', row1, rang_fictif);
		local row2 = tDrawG6:AddRow();
		tDrawG6:SetCell('Nom', row2, identite);
		tDrawG6:SetCellNull('Prenom', row2);
		tDrawG6:SetCell('FIS_pts', row2, pts)
	end
end

function OnPrintDoubleTirageEgalite(groupe)
	local tPrint = tResultat_Info_Bibo:Copy(true,true);
	local filter = '$(Groupe):In('..groupe..')';
	tPrint:Filter(filter, true);
	params.tableDossards1, params.tableDossards2 = OnDecodeJsonBibo(draw.code_evenement, groupe);
	
	if report == nil then
		report = wnd.LoadTemplateReportXML({
			xml = './process/dossard_DoubleTirage.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = traduction(draw.language, 'Impression du double tirage des exaequos'),
			base = base,
			margin_first_top = 150,
			margin_first_left = 100,
			margin_first_right = 100,
			margin_first_bottom = 100,
			margin_top = 150,
			margin_left = 100, 
			margin_right = 100,
			margin_bottom = 100,
			paper_orientation = 'portrait',
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 0, Version = script_version, NbGroupe1 = 0, Entite = draw.code_entite, Langue = draw.language; Title = tEvenement:GetCell('Nom',0).."-"..tEpreuve:GetCell('Code_epreuve',0), Station = tEvenement:GetCell('Station',0), Date = tEvenement:GetCell('Date_debut',0) }
		});
	else
		editor = report:GetEditor();
		if not editor then
			do return end
		end
		editor:PageBreak(); -- Saut de Page entre les 2 éditions ...
		wnd.LoadTemplateReportXML({
			xml = './process/dossard_DoubleTirage.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = traduction(draw.language, 'Impression du double tirage des exaequos'),
			report = report,
			-- layers = {file = './edition/layer.xml', id = 'FIS-GM'}, 
			base = base,
			margin_first_top = 150,
			margin_first_left = 100,
			margin_first_right = 100,
			margin_first_bottom = 100,
			margin_top = 150,
			margin_left = 100, 
			margin_right = 100,
			margin_bottom = 100,
			paper_orientation = 'portrait',
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 0, Version = script_version, NbGroupe1 = params.nb_groupe1, Entite = draw.code_entite, Langue = draw.language}
		});
	end
end

function OnPrintDoubleTirage(groupe)
	local txt_tirage = " BIBO (2 pages)";
	params.tableDossards1, params.tableDossards2 = OnDecodeJsonBibo(draw.code_evenement, groupe);
	if groupe == 1 then
		report = wnd.LoadTemplateReportXML({
			xml = './process/dossard_DoubleTirage.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = 'Edition du tirage au sort du'..txt_tirage,
			base = base,
			margin_first_top = 150,
			margin_first_left = 100,
			margin_first_right = 100,
			margin_first_bottom = 100,
			margin_top = 150,
			margin_left = 100, 
			margin_right = 100,
			margin_bottom = 100,
			paper_orientation = 'portrait',
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 1, Version = script_version, NbGroupe1 = 0, Entite = draw.code_entite, Langue = draw.language; Title = tEvenement:GetCell('Nom',0).."-"..tEpreuve:GetCell('Code_epreuve',0), Station = tEvenement:GetCell('Station',0), Date = tEvenement:GetCell('Date_debut',0) }
		});
	elseif groupe == 2 then
		if not report then
			report = wnd.LoadTemplateReportXML({
				xml = './process/dossard_DoubleTirage.xml',
				node_name = 'root/panel',
				node_attr = 'id',
				node_value = 'print',
				title = 'Edition du tirage au sort du'..txt_tirage,
				-- layers = {file = './edition/layer.xml', id = 'FIS-PM'}, 
				base = base,
				margin_first_top = 150,
				margin_first_left = 100,
				margin_first_right = 100,
				margin_first_bottom = 100,
				margin_top = 150,
				margin_left = 100, 
				margin_right = 100,
				margin_bottom = 100,
				paper_orientation = 'portrait',
				params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 2, Version = script_version, NbGroupe1 = params.nb_groupe1, Entite = draw.code_entite, Langue = draw.language, Station = tEvenement:GetCell('Station',0), Date = tEvenement:GetCell('Date_debut',0)}
			});
		end
		editor = report:GetEditor();
		if not editor then
			do return end
		end
		editor:PageBreak(); -- Saut de Page entre les 2 éditions ...
		wnd.LoadTemplateReportXML({
			xml = './process/dossard_DoubleTirage.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = 'Edition du tirage au sort du'..txt_tirage,
			report = report,
			-- layers = {file = './edition/layer.xml', id = 'FIS-GM'}, 
			base = base,
			margin_first_top = 150,
			margin_first_left = 100,
			margin_first_right = 100,
			margin_first_bottom = 100,
			margin_top = 150,
			margin_left = 100, 
			margin_right = 100,
			margin_bottom = 100,
			paper_orientation = 'portrait',
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 2, Version = script_version, NbGroupe1 = params.nb_groupe1, Entite = draw.code_entite, Langue = draw.language}
		});
	end
end

function OnPrintEtiquettes(orderby)
	tDraw:OrderBy(orderby);
	tEtiquette = tDraw:Copy(true,true);
	-- Creation du Report
	local estce = 0;
	local row_separation = nil;
	if config.script_level == 4 then
		for i = tEtiquette:GetNbRows() -1, 0, -1 do
			if tEtiquette:GetCellInt('ECSL_30', i) > 0 and not row_separation then
				row_separation = i;
			end
		end
		estce = 1;
	end
	local vitesse = 0;
	if draw.bolVitesse then
		vitesse = 1;
	end
	report = wnd.LoadTemplateReportXML({
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'parti_etiquette_factorise',
		base = base,
		body = tEtiquette,
		params = {Orderby = orderby, EstCE = estce, EstVitesse = vitesse, RowSeparation = row_separation}
	});
	
end

function OnPrintTableau(orderby)
	tDraw:OrderBy(orderby);
	-- Creation du Report
	local estce = 0;
	local finale = 0;
	local wjc = 0;
	if config.script_level == 4 then
		estce = 1;
		if draw.finale_ce == 'Oui' or draw.finale_ce == 'Yes' then
			finale = 1;
		end
	end
	if config.script_level == 2 then
		wjc = 1;
	end
	local vitesse = 0;
	if draw.bolVitesse then
		vitesse = 1;
	end
	report = wnd.LoadTemplateReportXML({
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'print_tableau',
		base = base,
		body = tDraw,
		params = {Orderby = orderby, EstCE = estce, EstVitesse = vitesse, EstFinale = finale, EstWJC = wjc, Station = tEvenement:GetCell('Station',0), Date = tEvenement:GetCell('Date_debut',0)}
	});
	
end

function OnPrintNation()
	-- Creation du Report
	local estce = 0;
	local estwjc = 0;
	if config.script_level == 4 then
		estce = 1;
	end
	if config.scrip == 2 then
		estwjc = 1;
	end
	report = wnd.LoadTemplateReportXML({
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'parti_factorise',
		base = base,
		body = tDraw,
		params = {EstCE = estce, EstWJC = estwjc, EstVitesse = vitesse, Rupture = 'Nation', Station = tEvenement:GetCell('Station',0), Date = tEvenement:GetCell('Date_debut',0)}
		});
	
end

function OnPrintZKNation()
	local tDisciplines = draw.wjc_discipline:Split(',');
	tDrawCopy = tDraw:Copy(true,true);
	tDrawCopy:AddColumn({ name = 'Clt_SL', label = 'Clt SL', type = sqlType.LONG, style = sqlStyle.NULL });
	tDrawCopy:AddColumn({ name = 'Clt_GS', label = 'Clt GS', type = sqlType.LONG, style = sqlStyle.NULL });
	tDrawCopy:AddColumn({ name = 'Clt_DH', label = 'Clt DH', type = sqlType.LONG, style = sqlStyle.NULL });
	for i = 0, tDrawCopy:GetNbRows() -1 do
		tDrawCopy:SetCellNull('Racer_info', i);
		local nb_clt = 0;
		local code_coureur = tDrawCopy:GetCell('Code_coureur', i);
		for j = 1, #tDisciplines do
			local discipline = tDisciplines[j];
			local type_classement = 'IA'..discipline;
			local cmd = "Select * From Classement_Coureur Where Code_liste = "..draw.code_liste.." And Code_coureur = '"..code_coureur.."' And Type_classement = '"..type_classement.."'";
			tClassement_Coureur = base:TableLoad(cmd);
			if tClassement_Coureur:GetNbRows() > 0 then
				local clt = tClassement_Coureur:GetCellInt('Clt', 0);
				if clt > 0 then
					tDrawCopy:SetCell('Clt_'..discipline, i, clt);
					if clt <= draw.wjc_clt_maxi then
						nb_clt = nb_clt + 1;
					end
				end
			end
		end
		if nb_clt > 1 then
			tDrawCopy:SetCell('Racer_info', i, 'ZK ???');
		end
	end
	local estce = 0;
	local estwjc = 0;
	if config.script_level == 4  then
		estce = 1;
	end
	if config.script_level == 2 then
		estwjc = 1;
	end
	report = wnd.LoadTemplateReportXML({
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'zk',
		base = base,
		body = tDrawCopy,
		params = {EstCE = estce, EstWJC = estwjc, EstVitesse = vitesse, Rupture = 'Nation', Station = tEvenement:GetCell('Station',0), Date = tEvenement:GetCell('Date_debut',0)}
		});
end

function OnPrintStartlist()
	tDraw:OrderBy('Dossard');
	report = wnd.LoadTemplateReportXML({
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'lst_officiel',
		base = base,
		body = tDraw
		});
end

function OnPrepareQualifies()
	draw.prepare_qualifie = true;
	tDraw_QLF = tDraw:Copy(true,true);
	tDraw_QLF:OrderBy('ECSL_points DESC, FIS_pts');
	local filter = "$(ECSL_points):len() > 0";
	tDraw_QLF:Filter(filter, true);
	local pris = 0;
	local rank= -1;
	for i = 0, tDraw_QLF:GetNbRows() -1 do
		local rank = tDraw_QLF:GetCellInt('ECSL_rank', i, -1);
		if tDraw_QLF:GetCellInt('WCSL_points', i) > 0 and tDraw_QLF:GetCellInt('WCSL_rank', i) <= config.clt_WCSL then
			tDraw_QLF:SetCell('TG', i, 'WCSL Top30');
		elseif tDraw_QLF:GetCellInt('ECSL_points', i) > 0 then
			if pris <= config.qlf_Finale then
				pris = pris + 1;
			end
			if pris == config.qlf_Finale and i < tDraw_QLF:GetNbRows() -1 then
				if tDraw_QLF:GetCellInt('ECSL_points', i) == tDraw_QLF:GetCellInt('ECSL_points', i + 1 ) then
					pris = pris - 1;
				end
			end
			if pris > config.qlf_Finale then
				tDraw_QLF:SetCell('TG', i, 'DNQLF');
			else
				tDraw_QLF:SetCell('TG', i, 'QLF');
			end
		end
	end

end

function OnPrintFinale()
	-- Creation du Report
	local estce = 0;
	report = wnd.LoadTemplateReportXML({
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'parti_finale',
		base = base,
		body = tDraw_QLF,
		margin_first_top = 250,
		margin_first_left = 80,
		margin_first_right = 80,
		margin_first_bottom = 160,
		margin_top = 245,
		margin_left = 80, 
		margin_right = 80,
		margin_bottom = 160,
		paper_orientation = 'portrait',
		params = {EstCE = estce, EstVitesse = vitesse, Rupture = 'Nation', Station = tEvenement:GetCell('Station',0), Date = tEvenement:GetCell('Date_debut',0)}
		});
	
end

function OnPrintFeuilleTirage()
	tDraw:OrderBy('Rang_tirage');
	tDraw_Copy = tDraw:Copy(true,true);
	if config.script_level == 4 and draw.bolVitesse then
		for i = 0, tDraw_Copy:GetNbRows() -1 do
			if tDraw_Copy:GetCell('TG', i) == 'tDrawG2' then
				tDraw_Copy:SetCell('Groupe_tirage', i, 2);
			end
		end
	end
	if config.script_level == 4  then
		tDraw_Copy:OrderBy('Rang_tirage');
		for i = tDraw_Copy:GetNbRows() -1, 0, -1 do
			if tDraw_Copy:GetCellInt('Groupe_tirage', i) > 2 then
				tDraw_Copy:RemoveRowAt(i);
			end
		end
	else
		tDraw_Copy:OrderBy('FIS_pts');
		for i = tDraw_Copy:GetNbRows() -1, 0, -1 do
			if not draw.bolVitesse then
				if config.script_level ~= 3 then
					if tDraw_Copy:GetCellInt('Groupe_tirage', i) > 1 then
						tDraw_Copy:RemoveRowAt(i);
					end
				else
					if tDraw_Copy:GetCellInt('Groupe_tirage', i) > 2 then
						tDraw_Copy:RemoveRowAt(i);
					end
				end
			else
				if tDraw_Copy:GetCellInt('Groupe_tirage', i) > 1 then
					tDraw_Copy:RemoveRowAt(i);
				end
			end
		end
	end
	local estCE = 0;
	if config.script_level == 4 then
		estCE = 1;
	end
	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'print',
		title = "Racers' Board - Bib Drawing",
		base = base,
		body = tDraw_Copy,
		margin_first_top = 80,
		margin_first_left = 80,
		margin_first_right = 80,
		margin_first_bottom = 80,
		margin_top = 80,
		margin_left = 80, 
		margin_right = 80,
		margin_bottom = 80,
		paper_orientation = 'portrait',
		params = {Evenement_nom = tEvenement:GetCell('Nom', 0), Version = script_version, NbGroupe1 = draw.nb_groupe_1, EstCE = estCE, Station = tEvenement:GetCell('Station',0), Date = tEvenement:GetCell('Date_debut',0)}
	});
end

function OnPrintTop75()
	local tDraw_Copy = tDraw:Copy(true, true);
	tDraw_Copy:OrderBy('Nation, FIS_pts');
;	local fis_pts = -1;
	local fis_clt = 10000;
	for i = tDraw_Copy:GetNbRows() -1, 0, -1 do
		local fis_pts = tDraw_Copy:GetCellDouble('FIS_pts', i, -1);
		if fis_pts >= 0 then
			fis_clt = tDraw_Copy:GetCellInt('FIS_clt', i, -1);
			if fis_clt > config.topx_FIS  then
				tDraw_Copy:RemoveRowAt(i);
			end
		else
			tDraw_Copy:RemoveRowAt(i);
		end
	end
	local title = "TOP "..config.topx_FIS .." / "..draw.discipline.." FIS Points ordered by ";
	report = wnd.LoadTemplateReportXML({
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'parti_factorise',
		base = base,
		body = tDraw_Copy,
		margin_first_top = 80,
		margin_first_left = 80,
		margin_first_right = 80,
		margin_first_bottom = 80,
		margin_top = 80,
		margin_left = 80, 
		margin_right = 80,
		margin_bottom = 80,
		paper_orientation = 'portrait',
		params = {Title = title ,Evenement_nom = tEvenement:GetCell('Nom', 0), Sexe = draw.sexe, EstCE = estce, EstVitesse = vitesse, Rupture = 'Nation', Version = script_version, Station = tEvenement:GetCell('Station',0), Date = tEvenement:GetCell('Date_debut',0)}
	});
	
end

function OnOrder()
	if draw.bolInit then
		draw.build_table = true;
		draw.skip_question = true;
	end
	if not draw.skip_question then
		draw.build_table = false;
		local msg = traduction(draw.language,"Voulez-vous reconstruire les groupes et les rangs de départ ?\n\nCliquer sur Oui pour tout reconstruire\nou cliquer sur Non pour garder les données stockées.");
		if dlgTableau:MessageBox(
			msg, traduction(draw.language,"Tri du tableau des coureurs"), 
			msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
		) == msgBoxStyle.YES then
			draw.build_table = true;
		end
	end
	if draw.build_table == true then
		draw.skip_question = true;
		OnRAZData('Tout');
		draw.build_table = true;
		if draw.bolInit then
			if config.script_level ~= 4 then 
				SetuptDraw();
			end
		else
			SetuptDraw();
		end
	end
	tDraw:OrderBy('Rang_tirage');

	-- draw.build_table = false;
	-- grid_tableau:SetSortingColumn('Rang_tirage');
	draw.bolInit = false;
	CheckExaequo();
	RefreshGrid();
end

function InitDraw()
	RefreshCounterSequence();
	-- Est ce que tout a été acquitté ?
	SendNextPacket();

	return true;
end


-- Suppression des Données
function OnReset(evt)
	local msg = traduction(draw.language,"Confirmation RAZ ?\n\nToutes les données envoyées précédemment seront effacées du serveur !!");
	if dlgTableau:MessageBox(
		msg, 
		traduction(draw.language,"RAZ à la FIS"), 
		msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
	) ~= msgBoxStyle.YES then
		return;
	end
	draw.raz_sequence = true;
	CommandClear();
end

function OnWebDraw()
	app.LaunchDefaultBrowser(draw.web);
end

function OnSendMessage()
	local dlg = wnd.CreateDialog({
		parent = app.GetAuiFrame(),
		icon = "./res/32x32_message.png",
		label = traduction(draw.language,"Envoi du Message"),
		width = 700,
		height = 200
	});
	
	dlg:LoadTemplateXML({ 
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'message'
	});
	
	function OnSend()
		SendMessage(dlg:GetWindowName('message'):GetValue());
		nodelivedraw:ChangeAttribute('last_message', dlg:GetWindowName('message'):GetValue());
		dlg:EndModal(idButton.OK);
	end
	
	-- Initialisation des variables 
	
	dlg:GetWindowName('message'):Clear();
	dlg:GetWindowName('message'):Append('Draw available');
	dlg:GetWindowName('message'):Append('Draw in progress');
	dlg:GetWindowName('message'):Append('Validation of racers in progress');
	dlg:GetWindowName('message'):Append('Draw list refreshed');
	dlg:GetWindowName('message'):Append('Draw list confirmed');
	dlg:GetWindowName('message'):Append('Draw list confirmed, bib drawing in progress');
	dlg:GetWindowName('message'):Append('Bib drawing completed, the race is expected to start at ');
	dlg:GetWindowName('message'):SetSelection(0);
	
	if nodelivedraw:GetAttribute('last_message'):len() > 0 then
		dlg:GetWindowName('message'):SetValue(nodelivedraw:GetAttribute('last_message'));
	end
	
	nodelivedraw:GetAttribute('send', 0)
	nodelivedraw:GetAttribute('send', 0)
	-- Toolbar Principale ...
	local tb = dlg:GetWindowName('tb');
	local btnSend = tb:AddTool(traduction(draw.language,"Envoyer"), "./res/32x32_send_green.png");
	tb:AddStretchableSpace();
	local btnClose = tb:AddTool(traduction(draw.language,"Fermer"), "./res/32x32_close.png");
	tb:Realize();

	-- Bind
	dlg:Bind(eventType.MENU, OnSend, btnSend); 
	dlg:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL) end, btnClose)

	-- Affichage Modal
	dlg:Fit();
	dlg:ShowModal();
	
	-- Liberation Mémoire
	dlg:Delete();
end

-- Envoi Message
function SendMessage(msg)
	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	local nodeMessage = xmlNode.Create(nodeRoot, xmlNodeType.ELEMENT_NODE, "message");
	xmlNode.Create(nodeMessage, xmlNodeType.ELEMENT_NODE, "text", msg);	
	CreateXML(nodeRoot);
end

function CommandRenvoyerDossards(bolRAZ);
	draw.completed = true;
	local nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeRaceEvent = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceevent");
	tDraw:OrderBy('Rang_tirage');
	for i = 0, tDraw:GetNbRows() -1 do
		local dossard = tDraw:GetCellInt('Dossard', i);
		if dossard == 0 then
			draw.completed = false;
		end
		if bolRAZ == true or dossard == 0 or bolSendDossard == false then
			dossard = '';
		end
		local code_coureur = tDraw:GetCell('Code_coureur', i):sub(4);;
		local nodeDrawBib = xmlNode.Create(nodeRaceEvent, xmlType.ELEMENT_NODE, "drawbib");
		local nodeBib = xmlNode.Create(nodeDrawBib, xmlType.ELEMENT_NODE, "bib", dossard);
		nodeDrawBib:AddAttribute('fiscode', code_coureur);
	end
	local nodeCommand = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "command");
	nodeRoot:AddChild(nodeRaceEvent);
	nodeCommand = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "command");
	local nodeDrawInProgress = xmlNode.Create(nodeCommand, xmlType.ELEMENT_NODE, "drawinprogress");
	nodeRoot:AddChild(nodeCommand);
	CreateXML(nodeRoot);
	if draw.completed == false then
		SendMessage('Draw in progress');
	else
		SendMessage('Draw completed');
	end
	dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language,'Dossards renvoyés'));
end

function CommandValiderCoureurs(statut)
	local msg = traduction(draw.language,"Voulez-vous valider en bloc tous les coureurs ?");
	if statut == 'UF' then
		msg = traduction(draw.language,"Voulez-vous invalider en bloc tous les coureurs ?");
	end
	if dlgTableau:MessageBox(
		msg, traduction(draw.language, "Validation des coureurs"), 
		msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION
		) == msgBoxStyle.NO then
		return;
	end
	local nodeRaceEvent = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceevent");
	for i = 0, tDraw:GetNbRows() -1 do
		tDraw:SetCell('Statut', i, statut);
		local code_coureur = tDraw:GetCell('Code_coureur', i):sub(4);;
		local nodeDrawStatus = xmlNode.Create(nodeRaceEvent, xmlType.ELEMENT_NODE, "drawstatus");
		nodeDrawStatus:AddAttribute('fiscode', code_coureur);
		local nodeStatus = xmlNode.Create(nodeDrawStatus, xmlType.ELEMENT_NODE, "status", statut);
	end
	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeRaceEvent);
	CreateXML(nodeRoot);
	RefreshGrid();
	dlgTableau:GetWindowName('info'):SetValue(tDraw:GetNbRows()..traduction(draw.language,' coureurs modifiés.'));
end

function CommandValiderUnCoureur(row)
	local nodeRaceEvent = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceevent");
	local code_coureur = tDraw:GetCell('Code_coureur', row):sub(4);
	local statut = tDraw:GetCell('Statut', row)
	local nodeDrawStatus = xmlNode.Create(nodeRaceEvent, xmlType.ELEMENT_NODE, "drawstatus");
	nodeDrawStatus:AddAttribute('fiscode', code_coureur);
	local nodeStatus = xmlNode.Create(nodeDrawStatus, xmlType.ELEMENT_NODE, "status", statut);

	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeRaceEvent);
	CreateXML(nodeRoot);
	if statut == 'CF' then
		dlgTableau:GetWindowName('info'):SetValue(tDraw:GetCell('Nom', row)..' '..tDraw:GetCell('Prenom', row)..traduction(draw.language,' confirmé.'));
	else
		CommandRenvoyerDossards(false);
		dlgTableau:GetWindowName('info'):SetValue(tDraw:GetCell('Nom', row)..' '..tDraw:GetCell('Prenom', row)..traduction(draw.language, ' non confirmé.'));
	end
end

function CheckDossardAfter()
	local ligne = -1;
	if not draw.row_selected then
		draw.row_selected = tDraw:GetNbRows() -1;
	end
	for i = draw.row_selected, tDraw:GetNbRows() -1 do
		if tDraw:GetCellInt('Dossard', i) > 0 then
			ligne = i + 1;
			break;
		end
	end
	return ligne;
end

function SetDossardsAvailable(last_row_1530)
	draw.tDossardsAvailable = {};
	for i = 0, last_row_1530 do
		table.insert(draw.tDossardsAvailable, {Dossard = i + 1, Pris = 0});
	end
	for i = 0, last_row_1530 do
		local dossard = tonumber(tDraw:GetCell('Dossard', i)) or -1;
		if dossard > 0 then
			draw.tDossardsAvailable[dossard].Pris = 1;
		end
	end

end

function CommandSendOrder(bolSendDrawOrder)
	ChecktDraw();
	-- Génération des balises 
	local nodeRaceEvent = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceevent");
	tDraw:OrderBy('Rang_tirage');
	for i = 0, tDraw:GetNbRows()-1 do
		local code_coureur = tDraw:GetCell('Code_coureur', i):sub(4);;
		local nodeDrawStatus = xmlNode.Create(nodeRaceEvent, xmlType.ELEMENT_NODE, "drawstatus");
		nodeDrawStatus:AddAttribute('fiscode', code_coureur);
		local nodeStatus = xmlNode.Create(nodeDrawStatus, xmlType.ELEMENT_NODE, "status", tDraw:GetCell('Statut', i));
 		local nodeDrawGroup = xmlNode.Create(nodeRaceEvent, xmlType.ELEMENT_NODE, "drawgroup");
		nodeDrawGroup:AddAttribute('fiscode', code_coureur);
		local groupe_tirage = tDraw:GetCellInt('Groupe_tirage', i);
		if config.script_level == 4 then
			if draw.bolVitesse and tDraw:GetCell('Racer_info', i) == '450+' then
				groupe_tirage = 2;
			end
		end
		local nodeGroup = xmlNode.Create(nodeDrawGroup, xmlType.ELEMENT_NODE, "group", groupe_tirage);
		if bolSendDrawOrder then
			local nodeDrawOrder = xmlNode.Create(nodeRaceEvent, xmlType.ELEMENT_NODE, "draworder");
			nodeDrawOrder:AddAttribute('fiscode', code_coureur);
			local nodeOrder = xmlNode.Create(nodeDrawOrder, xmlType.ELEMENT_NODE, "order", tDraw:GetCellInt('Rang_tirage', i));
		end
	end
	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeCommand = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "command");
	nodeRoot:AddChild(nodeRaceEvent);
	local nodeCommandStatus = nil;
	if draw.statut == 'UF' then
		nodeCommandStatus = xmlNode.Create(nodeCommand, xmlType.ELEMENT_NODE, "drawavailable");
	else
		nodeCommandStatus = xmlNode.Create(nodeCommand, xmlType.ELEMENT_NODE, "drawconfirmed");
	end
	nodeRoot:AddChild(nodeCommand);
	CreateXML(nodeRoot);
	if bolSendDrawOrder then
		dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language, "Ordre des coureurs dans le tableau envoyé"));
	else
		dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language, "Liste des participants envoyée"));
	end
end

function SetRangsPtsNull()
	tDraw:OrderBy('Rang_tirage');
	local rang_first = -1;
	local rang_last = -1;	
	for i = tDraw:GetNbRows()-1, 0, -1 do
		local rang = i + 1;
		local fis_pts = tDraw:GetCellDouble('FIS_pts', i, -1);
		if fis_pts < 0 then
			if rang_last < 0 then
				rang_last = rang;
			end
			rang_first = rang;
		else
			break;
		end
	end
	return rang_first, rang_last;
end

-- envoi de l'heure de départ
function CommandSendScheduled(run)
	if tEpreuve:GetCell('Code_activite', draw.row_epreuve) == 'ALP' then
		local heure = ""; local minute = ""; local stringtime = "";
		if tEpreuveAlpineManche ~= nil then
			local heure_depart = tEpreuveAlpineManche:GetCell("Heure_depart", run-1);
			if heure_depart == "" then
				heure_depart = '00:00';
			end
			local x, y = string.find(heure_depart, "%D");  -- tout ce qui n'est pas un chiffre
			if x == nil then  -- position du séparateur
				return;
			else
				heure = string.sub(heure_depart, 1, x-1);
				heure = string.format("%02d", tonumber(heure) or 0);
				minute = string.sub(heure_depart, x+1);
				minute = string.format("%02d", tonumber(minute) or 0);
				stringtime = heure..":"..minute;
			end
			local nodeCommand = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "command");
			local nodeScheduled = xmlNode.Create(nodeCommand, xmlNodeType.ELEMENT_NODE, "scheduled");
			nodeScheduled:AddAttribute("runno", run);
			-- nodeScheduled Childs ...
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "year", tEpreuve:GetCell("Date_epreuve", draw.row_epreuve, '%4Y'));	
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "month", tEpreuve:GetCell("Date_epreuve", draw.row_epreuve, '%2M'));	
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "day", tEpreuve:GetCell("Date_epreuve", draw.row_epreuve, '%2D'));	
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "cettime", stringtime);
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "loctime", stringtime);
			-- Regroupement <scheduled> et <command>
			local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
			nodeRoot:AddChild(nodeCommand);
			CreateXML(nodeRoot);
			dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language,"Tag scheduled envoyé pour la manche 1 = ")..stringtime);
		end
	end
end



-- envoi de la startlist 
function CommandSendStartList()
	tDraw:OrderBy('Dossard');
	local activerun = 1;
	local bolOK = true;
	for i = 0, tDraw:GetNbRows() -1 do
		if tDraw:GetCell('Dossard', i):len() == 0 then
			bolOK = false;
			dlgTableau:MessageBox(
				traduction(draw.language,"Tous les dossards n'ont pas été attribués"),
				traduction(draw.language,"Erreur sur les dossards"), 
				msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
			break;
		end
	end

	if bolOK == false then
		return;
	end
	-- CommandClear();
	CommandRaceInfo(false);
	-- Génération des balises
	-- nodeRoot est déjà créé dans SendRaceinfo	
	nodeStartList = xmlNode.Create(nodeRoot, xmlNodeType.ELEMENT_NODE, "startlist");
	nodeStartList:AddAttribute("runno",1);			
	
	local countRacer = 0;
	for row = 0, tDraw:GetNbRows() - 1 do
		if activerun == 1 then 
			local bib = tDraw:GetCell("Dossard", row);

			-- Balise "racer"
			local nodeRacer = xmlNode.Create(nodeStartList, xmlNodeType.ELEMENT_NODE, "racer");			
			countRacer = countRacer + 1;
			nodeRacer:AddAttribute("order", countRacer);		
				
			-- Balises FIS 
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "bib", tDraw:GetCell("Dossard", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "lastname", tDraw:GetCell("Nom", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "firstname", tDraw:GetCell("Prenom", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "nat", tDraw:GetCell("Nation", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "fiscode", string.sub(tDraw:GetCell("Code_coureur", row),4));			
				
		end
	end
	
	-- command activerun
	local nodeCommand = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "command");
	local nodeActiveRun = xmlNode.Create(nodeCommand, xmlNodeType.ELEMENT_NODE, 'activerun');
	nodeActiveRun:AddAttribute("no",1);
	
	-- Regroupement <startlist> et <command>
	nodeRoot:AddChild(nodeStartList);
	nodeRoot:AddChild(nodeCommand);
	CreateXML(nodeRoot);
	
	dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language,"Liste de départ manche 1 envoyée"));

	-- dossard de rang 1 au départ
	local nodeRaceEvent = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "raceevent");
	local nodeNextStart = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "nextstart");			
	nodeNextStart:AddAttribute("bib", 1);
	nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeRaceEvent);
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language, "dossard 1 au départ envoyé"));
	CommandSendScheduled(1);
	local msg = 'Start List';
	if tEpreuve_Alpine_Manche:GetCell("Heure_depart", 0):len() > 0 then
		local heure = ""; local minute = "";
		local heure_depart = tEpreuve_Alpine_Manche:GetCell("Heure_depart", 0);
		local x, y = string.find(heure_depart, "%D");  -- tout ce qui n'est pas un chiffre
		if x ~= nil then  -- position du séparateur
			heure = string.sub(heure_depart, 1, x-1);
			heure = string.format("%02d", tonumber(heure) or 0);
			minute = string.sub(heure_depart, x+1);
			minute = string.format("%02d", tonumber(minute) or 0);
		end
		msg = 'The race is expected to start at '..heure..':'..minute;
	end
	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeMessage = xmlNode.Create(nodeRoot, xmlNodeType.ELEMENT_NODE, "message");
	xmlNode.Create(nodeMessage, xmlNodeType.ELEMENT_NODE, "text", msg);	
	CreateXML(nodeRoot);
end


-- Envoi Course
function CommandSendList(bolSendDrawOrder)
	tDraw:OrderBy('Rang_tirage');
	-- Génération des balises 
	local nodeStartlist = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "startlist");
	nodeStartlist:AddAttribute("phase", 'D');
	draw.statut_CF = true;
	for i = 0, tDraw:GetNbRows()-1 do
		if config.script_level == 2 then
			if tDraw:GetCell('Winner_CC', i):len() > 0 then
				if tDraw:GetCell('Racer_info', i) == '==' then
					tDraw:SetCell('Racer_info', i, '==ZK');
				else
					tDraw:SetCell('Racer_info', i, 'ZK');
				end
			end
		end
		local racer_info = tDraw:GetCell('Racer_info', i);
		local pts_info = tDraw:GetCell('Pts_info', i);
		local nom = tDraw:GetCell('Nom', i);
		local prenom = tDraw:GetCell('Prenom', i);
		local nation = tDraw:GetCell('Nation', i);
		if config.script_level == 1 and not bolSendDrawOrder then
			if nation == 'FRA' then
				nation = '-'..tDraw:GetCell('Comite', i);
			end
		end
		local code = tDraw:GetCell('Code_coureur', i):sub(4);
		local rang_tirage = tDraw:GetCellInt('Rang_tirage', i);
		local wcsl_points = tDraw:GetCell('WCSL_points', i);
		local wcsl_rank = tDraw:GetCell('WCSL_rank', i);
		local ecsl_points = tDraw:GetCell('ECSL_points', i);
		local ecsl_rank = tDraw:GetCell('ECSL_rank', i);
		local ecsl_overall_points = tDraw:GetCell('ECSL_overall_points', i);
		local ecsl_overall_rank = tDraw:GetCell('ECSL_overall_rank', i);
		local ecsl_overall_rank = '';
		local winner_points = tDraw:GetCell('Winner_CC', i);
		local winner_rank = '';
		local fis_pts = tDraw:GetCellDouble('FIS_pts', i, -1);
		local fis_clt = tDraw:GetCellInt('FIS_clt', i);
		if fis_pts < 0 then 
			fis_pts = ''; 
			fis_clt = '';
		end
		if draw.finale_ce == 'Non' or draw.finale_ce == 'No' then
			if tDraw:GetCellInt('WCSL_rank', i) > config.clt_WCSL then
				wcsl_points = '';
				wcsl_rank = '';
			end
		end		
		local tStandings = {};
		local tData = {};
		if config.script_level == 4 then
			-- table.insert(tData, {rank = ecsl_rank, points = ecsl_points, event = draw.discipline, category = 'ECSL', pointsinfo = pts_info});
			table.insert(tData, {rank = ecsl_rank, points = ecsl_points, event = draw.discipline, category = 'ECSL', pointsinfo = pts_info});
			table.insert(tData, {rank = ecsl_overall_rank, points = ecsl_overall_points, event = '', category = '450+', pointsinfo = pts_info});
			if draw.finale_ce == 'Non' or draw.finale_ce == 'No' then
				table.insert(tData, {rank = wcsl_rank, points = wcsl_points, event = draw.discipline, category = 'WCSL', pointsinfo = pts_info});
				if bolSendDrawOrder == false then
					table.insert(tData, {rank = '', points = winner_points, event = draw.discipline, category = 'COC', pointsinfo = pts_info});
				end
			else
				table.insert(tData, {rank = wcsl_rank, points = wcsl_points, event = draw.discipline, category = 'WCSL', pointsinfo = pts_info});
			end
			table.insert(tData, {rank = fis_clt, points = fis_pts, event = draw.discipline, category = 'FIS PTS', pointsinfo = pts_info});
		else
			if config.script_level == 2 then
				table.insert(tData, {rank = winner_rank, points = winner_points, event = draw.discipline, category = 'ZK', pointsinfo = pts_info});
				table.insert(tData, {rank = fis_clt, points = fis_pts, event = draw.discipline, category = 'FIS PTS', pointsinfo = pts_info});
			else
				table.insert(tData, {rank = fis_clt, points = fis_pts, event = draw.discipline, category = 'FIS PTS', pointsinfo = pts_info});
			end
		end
		local tCoureur = {standings = tData, racerinfo = tostring(racer_info)};
		local jsontxt = table.ToStringJSON(tCoureur, false);
		local nodeRacer = xmlNode.Create(nodeStartlist, xmlNodeType.ELEMENT_NODE, "racer");
		local nodeLastname = xmlNode.Create(nodeRacer, xmlType.ELEMENT_NODE, "lastname", nom);
		local nodeFirstname = xmlNode.Create(nodeRacer, xmlType.ELEMENT_NODE, "firstname", prenom);
		local nodeNation = xmlNode.Create(nodeRacer, xmlType.ELEMENT_NODE, "nat", nation);
		local nodeFiscode = xmlNode.Create(nodeRacer, xmlType.ELEMENT_NODE, "fiscode", code);
		local noderacerinfoJSON = xmlNode.Create(nodeRacer, xmlType.ELEMENT_NODE, "racerinfoJSON");
		xmlNode.Create(noderacerinfoJSON, xmlType.CDATA_SECTION_NODE,'', jsontxt);
	end
	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	nodeCommand = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "command");
	local nodeDrawAvailable = xmlNode.Create(nodeCommand, xmlType.ELEMENT_NODE, "drawavailable");
	nodeRoot:AddChild(nodeStartlist);
	nodeRoot:AddChild(nodeCommand);
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language,"Tableau des coureurs envoyé"));
end

function CommandSendMessage();
	local debut = #draw.tModifs_tableau;
	for i = debut, #draw.tModifs_tableau do
		local nodeMessage = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "message");
		local code_coureur = draw.tModifs_tableau [i].Code_coureur;
		local nom = draw.tModifs_tableau [i].Nom;
		local prenom = draw.tModifs_tableau [i].Prenom;
		local nation = draw.tModifs_tableau [i].Nation;
		local status = draw.tModifs_tableau [i].Status;
		local message = 'Added';
		if status == 'RM' then
			message = 'Removed';
		end
		local tMessage = {Updates = {racer = {{lastname = nom, firstname = prenom, nat = nation, fiscode = code_coureur, status = status, message = message, logid = i}}}};
		local jsontxt = table.ToStringJSON(tMessage, false);

		local nodeJSON = xmlNode.Create(nodeMessage, xmlType.ELEMENT_NODE, "drawupdatesJSON");
		xmlNode.Create(nodeJSON, xmlType.CDATA_SECTION_NODE,'', jsontxt);
		local nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
		nodeRoot:AddChild(nodeMessage);
		CreateXML(nodeRoot);
	end

end

function CommandClear()
	-- Remise à  Zéro des compteurs 
	if draw.raz_sequence then
		draw.sequence_send = 0;
		draw.sequence_ack = 0;
		nodelivedraw:ChangeAttribute('send', draw.sequence_send);
		nodelivedraw:ChangeAttribute('ack', draw.sequence_ack);
		draw.sequence_last_send = nil;
	end
	draw.raz_sequence = false;
	local nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeCommand = xmlNode.Create(nodeRoot, xmlType.ELEMENT_NODE, "command");
	local nodeClear = xmlNode.Create(nodeCommand, xmlType.ELEMENT_NODE, "clear");
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language, "Demande d'effacement envoyée"));
end

function CommandPhaseD()
	local nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeCommand = xmlNode.Create(nodeRoot, xmlType.ELEMENT_NODE, "command");
	local nodeActive = xmlNode.Create(nodeCommand, xmlType.ELEMENT_NODE, "active");
	nodeActive:AddAttribute("phase", "D");
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language,"Phase D envoyé"));
end

function CommandRaceInfo(bolPhased)
	-- bolPlusStartList n'est utilisé que pour le live FIS.
	-- bolPlusStartList = true si on concatène la start list. Dans ce cas, on ne termine pas le XML
	-- bolPlusStartList = false si on envoi la commande raceinco seule. Dans ce cas, on termine le XML
	local phased = false;
	if bolPhased == true then
		phased = true;
	end
	local run = 1;
	-- Génération des balises 
	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeRaceinfo = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceinfo");
	local category = tEpreuve:GetCell("Code_regroupement", draw.row_epreuve);
	if category == 'CE' then
		category = 'EC';
	end
	if category == 'F' then
		category = 'NC';
	end
	if category == 'NCM/J' then
		category = 'WJC';
	end

	local sexe = tEpreuve:GetCell("Sexe", draw.row_epreuve);
	if sexe ~= 'M' then
		sexe = 'L';
	end
	local discipline = tEpreuve:GetCell("Code_discipline", draw.row_epreuve);
	if draw.code_regroupement == 'TRA' or draw.niveau == 'TRA' then
		discipline = 'TRA';
	end
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "event", tEvenement:GetCell('Nom',0));	
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "name", discipline);			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "slope", tPistes:GetCell('Nom_piste',0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "discipline", discipline);			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "gender", sexe);			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "category", category);			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "place", tEvenement:GetCell('Station',0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "tempunit", 'C');			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "longunit", 'm');			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "speedunit", 'Kmh');	
		
	local start = tonumber(tEpreuve_Alpine_Manche:GetCell("Altitude_Depart",0)) or 0;
	local finish = tonumber(tEpreuve_Alpine_Manche:GetCell("Altitude_Arrivee",0)) or 0;
	local length = tonumber(tEpreuve_Alpine_Manche:GetCell("Longueur",0)) or 0;
	local turninggates = tEpreuve_Alpine_Manche:GetCellInt("Changement_de_directions",0,0);
	local heure = ""; local minute = "";
	local heure_depart = tEpreuve_Alpine_Manche:GetCell("Heure_depart", run-1);
	if phased == true and draw.time then
		heure_depart = draw.time;
	end
	local x, y = string.find(heure_depart, "%D");  -- tout ce qui n'est pas un chiffre
	if x ~= nil then  -- position du séparateur
		heure = string.sub(heure_depart, 1, x-1);
		heure = string.format("%02d", tonumber(heure) or 0);
		minute = string.sub(heure_depart, x+1);
		minute = string.format("%02d", tonumber(minute) or 0);
	end
	local year = tEpreuve:GetCell("Date_epreuve", draw.row_epreuve, '%4Y');
	local month = tEpreuve:GetCell("Date_epreuve", draw.row_epreuve, '%2M');
	local day = tEpreuve:GetCell("Date_epreuve", draw.row_epreuve, '%2D');
	if phased == true then
		if draw.date then
			local arDate = draw.date:Split('/');
			year = arDate[1];
			month = string.format('%02d', arDate[2]);
			day = string.format('%02d', arDate[3]);
		end
		nodePhase = xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "phase");			
		nodePhase:AddAttribute("no", 'D');			
		
		-- nodePhase Childs ...
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "discipline", tEpreuve:GetCell('Code_discipline', draw.row_epreuve));	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "start", start);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "finish", finish);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "height", start - finish);	
		if length > 0 then
			xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "length", length);	
		end
		local gates = tEpreuve_Alpine_Manche:GetCellInt("Nombre_de_portes",0);
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "gates", gates);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "turninggates", turninggates);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "year", year);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "month", month);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "day", day);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "hour", heure);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "minute", minute);	
		
		local nodeRacedef = xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "racedef");	
		xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "draworder", '');	
		xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "drawgroup", '');	
		xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "drawstatus", '');	
		xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "drawbib", '');	
		local tInfo = {};
		if config.script_level == 4 then
			if draw.finale_ce == 'Non' or draw.finale_ce == 'No' then
				tInfo = {legend = {abbreviation = {{description = 'ECSL points in '..draw.discipline, title = 'ECSL '..draw.discipline}, {description = 'At least 450 Cup points overall', title = '450+'}, {description = 'Winner of COC in '..draw.discipline, title = 'COC'}, {description = 'Within the top 30 of the WCSL in '..draw.discipline, title = 'WCSL '..draw.discipline}, {description = 'Ranked by '..draw.discipline..' FIS points', title = 'FIS PTS'}}}};
			else
				tInfo = {legend = {abbreviation = {{description = 'ECSL points in '..draw.discipline, title = 'ECSL'..draw.discipline}, {description = 'At least 450 Cup points overall', title = '450+'}, {description = 'WCSL Pts in '..draw.discipline, title = 'WCSL '..draw.discipline}, {description = 'Ranked by '..draw.discipline..' FIS points', title = 'FIS PTS'}}}};
			end
		else
			tInfo = {legend = {abbreviation = {{description = 'Ranked by FIS points', title = 'FIS Points'}}}};
		end
		local jsontxt = table.ToStringJSON(tInfo, false);
		
		local nodedrawinfoJSON = xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, 'drawinfoJSON');	
		xmlNode.Create(nodedrawinfoJSON, xmlType.CDATA_SECTION_NODE,'', jsontxt);	
	else
		run = 1
		-- run x 
		nodeRun = xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "run");			
		nodeRun:AddAttribute("no", run);			
		
		-- nodeRun Childs ...
		if tEpreuve:GetCell('Code_activite', draw.row_epreuve) == 'ALP' then
			if tEpreuve_Alpine_Manche:GetNbRows() >= run then
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "discipline", tEpreuve:GetCell('Code_discipline', draw.row_epreuve));	
				local start = tonumber(tEpreuve_Alpine_Manche:GetCell("Altitude_Depart",run-1)) or 0;
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "start", start);	
				local finish = tonumber(tEpreuve_Alpine_Manche:GetCell("Altitude_Arrivee",run-1)) or 0;
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "finish", finish);	
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "height", start-finish);	
				local length = tonumber(tEpreuve_Alpine_Manche:GetCell("Longueur",run-1)) or 0;
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "length", length);	
				local gates = tEpreuve_Alpine_Manche:GetCellInt("Nombre_de_portes",run-1,0);
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "gates", gates);	
				local turninggates = tEpreuve_Alpine_Manche:GetCellInt("Changement_de_directions",run-1,0);
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "turninggates", turninggates);	
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "year", year);	
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "month", month);	
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "day", day);	
				local heure = ""; local minute = "";
				local heure_depart = tEpreuve_Alpine_Manche:GetCell("Heure_depart", run-1);
				local x, y = string.find(heure_depart, "%D");  -- tout ce qui n'est pas un chiffre
				if x ~= nil then  -- position du séparateur
					heure = string.sub(heure_depart, 1, x-1);
					heure = string.format("%02d", tonumber(heure) or 0);
					minute = string.sub(heure_depart, x+1);
					minute = string.format("%02d", tonumber(minute) or 0);
				end
				
				-- hour
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "hour", heure);	

				-- minute
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "minute", minute);	
				
				--racedef  
				local nodeRacedef = xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "racedef");	
					
				-- nodeRacedef Childs ...
				local nbInter = tEpreuve_Alpine_Manche:GetCellInt("Nb_temps_inter",run-1, 0);
				for inter = 1, nbInter do

					local nodeInter = xmlNode.Create(nodeRacedef, xmlNodeType.ELEMENT_NODE, "inter");
					nodeInter:AddAttribute("i", inter);
							
				end
			end
		end
	end
	nodeRoot:AddChild(nodeRaceinfo);
	if phased then
		CreateXML(nodeRoot);
	end
	
	dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language,"Informations de course envoyées"));
end

function CreateXML(nodeRoot)
	if draw.state == false then
		Error(traduction(draw.language,"Feu au Rouge : Aucune Action possible !"));
		return false;
	end
	if not draw.socket_state then
		dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language, 'Pas de connexion à la FIS !'));
		Error(traduction(draw.language, 'Pas de connexion à la FIS !'));
		return;
	end
	assert(app.GetNameSpace(nodeRoot) == 'xmlNode');
	
	local doc = xmlDocument.Create();
	if doc:SetRoot(nodeRoot) == true then

		nodeRoot:AddAttribute("codex", draw.codex);
		nodeRoot:AddAttribute("passwd", draw.pwd);
	
		-- Incrementation sequence
		IncrementationSequenceSend();
		nodeRoot:AddAttribute("sequence", draw.sequence_send);
		
		-- timestamp
		nodeRoot:AddAttribute("timestamp", os.date('%H:%M:%S', os.time()));
	end

	doc:SaveFile(draw.directory..'live'..draw.codex..'_'..tostring(draw.sequence_send)..'.xml');
	doc:Delete();

	SendNextPacket();
end

function GetCateg(an)
	local cmd = "Select * From Categorie Where Code_activite = 'ALP' And Code_entite = 'FIS' And Code_grille = '"..draw.code_grille_categorie.."' And Code_saison = '"..draw.code_saison.."' And An_min <= "..an.." And An_max >= "..an.." Order By Ordre";
	base:TableLoad(tCategorie, cmd);
	return tCategorie:GetCell('Code', 0);
end

function OnSendTableau(bolSendDrawOrder)
	local msg = traduction(draw.language, "Confirmation de l'envoi du tableau à la FIS.");
	local txtdialog = traduction(draw.language, "Envoi du tableau à la FIS");
	CheckExaequo();
	CommandRaceInfo(true);
	CommandPhaseD();
	CommandSendList(bolSendDrawOrder);
	CommandSendOrder(bolSendDrawOrder);
	if bolSendDrawOrder == true then
		if draw.bolExisteDossard == true and draw.state == true then
			CommandRenvoyerDossards(false);
		end
	end
end

function OnRAZData(colonne)
	local txt = '';
	local msg = '';
	if colonne == 'Groupe_tirage' then
		txt = traduction(draw.language, 'groupes de tirage');
	elseif colonne == 'Rang_tirage' then
		txt = traduction(draw.language, 'rangs de tirage');
	elseif colonne == 'Dossard' then
		txt = traduction(draw.language, 'dossards');
		draw.bolTirageBiboFait = false;
		draw.bolTirageAvecPointFait = false;
		draw.bolTirageSansPointFait = false;
	elseif colonne == 'Dossard_bibo' then
		draw.bolTirageBiboFait = false;
		txt = traduction(draw.language, 'dossards du BIBO');
	elseif colonne == 'All' then
		txt = traduction(draw.language, 'rangs et groupes de tirage');
	elseif colonne == 'Tout' then
		draw.bolTirageBiboFait = false;
		draw.bolTirageAvecPointFait = false;
		draw.bolTirageSansPointFait = false;
		txt = traduction(draw.language, 'rangs et groupes de tirage ainsi que les dossards');
	end
	local reponse = nil;
	msg = traduction(draw.language, "Confirmation RAZ").." ?\n\n"..
		  traduction(draw.language, "Les ")..txt..traduction(draw.language, " seront effacés.");
	if not draw.skip_question then
		reponse = dlgTableau:MessageBox(
			msg, 
			traduction(draw.language, "Confirmation RAZ"), 
			msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING)
		if reponse == msgBoxStyle.NO then
			return;
		end
	end
	for i = 0, tDraw:GetNbRows() -1 do
		tDraw:SetCell('Pris', i, 0);
		if colonne == 'Rang_tirage' then
			tDraw:SetCellNull('Rang_tirage', i);
			tDraw:SetCellNull('Reserve', i);
		elseif colonne == 'Groupe_tirage' then 
			tDraw:SetCell('Groupe_tirage', i, 5);
		elseif colonne == 'All' then 
			tDraw:SetCellNull('Rang_tirage', i);
			tDraw:SetCell('Groupe_tirage', i, 5);
			-- local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement In('..draw.code_evenement..',-'..draw.code_evenement..')';
			-- base:Query(cmd);
			tResultat_Info_Bibo:RemoveAllRows();
			tDraw:SetCellNull('Dossard', i);
		elseif colonne == 'Dossard' then
			-- local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement In('..draw.code_evenement..',-'..draw.code_evenement..')';
			-- base:Query(cmd);
			tResultat_Info_Bibo:RemoveAllRows();
			tDraw:SetCellNull('Dossard', i);
		elseif colonne == 'Tout' then
			tDraw:SetCellNull('Rang_tirage', i);
			tDraw:SetCell('Groupe_tirage', i, 5);
			tDraw:SetCellNull('Reserve', i);
			tDraw:SetCellNull('Dossard', i);
			draw.bolTirageGroupe1Fait = false;
			draw.bolTirageGroupe2Fait = false;
			-- local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement In('..draw.code_evenement..',-'..draw.code_evenement..')';
			-- base:Query(cmd);
			tResultat_Info_Bibo:RemoveAllRows();
		end
	end
	if colonne == 'Dossard' then
		CommandRenvoyerDossards();
	end
	RefreshGrid();
	ChecktDraw();
end

function OnSupprimerCoureur(code_coureur, rang_tirage_selected)
	local cmd = "Delete From Resultat_Info_Tirage Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
	base:Query(cmd);
	cmd = "Delete From Resultat Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
	base:Query(cmd);
	if tResultat_Paiement and tResultat_Paiement:GetNbRows() > 0 then
		cmd = "Update From Resultat_Paiement Set Epreuve_selection"..(draw.row_epreuve + 1).." = NULL Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
	end
	for i = tDraw:GetNbRows() -1, 0, -1 do
		local rang_tirage = tDraw:GetCellInt('Rang_tirage', i);
		if rang_tirage > tDraw:GetNbRows() then
			tDraw:SetCell('Rang_tirage', i, tDraw:GetNbRows());
		elseif rang_tirage >= rang_tirage_selected then
			tDraw:SetCell('Rang_tirage', i, tDraw:GetCellInt('Rang_tirage', i) -1);
		else
			break;
		end
	end
	RefreshGrid(false);
	CommandSendList(bolSendDrawOrder);
	CommandSendOrder(bolSendDrawOrder);
	CommandSendMessage();
end

function OnAjouterCoureur()
	local fiscode = dlgTableau:GetWindowName('code'):GetValue();
	if not draw.trouve_coureur_liste then
		local msg = traduction(draw.language, 'Le coureur ne figure pas sur la liste ')..draw.code_liste..'\n'..
					traduction(draw.language, "Voulez-vous l'ajouter tout de même ?");
		if dlgTableau:MessageBox(
			msg, 
			traduction(draw.language, "Ajout d'un coureur"), 
			msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING
		) ~= msgBoxStyle.YES then
			return;
		end
	end
	local point, clt, pts_SG, rank_SG = GetRank(fiscode);
	
	local groupe = tonumber(dlgTableau:GetWindowName('groupe'):GetValue()) or 9;
	local nom = dlgTableau:GetWindowName('nom'):GetValue();
	local prenom = dlgTableau:GetWindowName('prenom'):GetValue();
	local sexe = draw.sexe;
	local an = tonumber(dlgTableau:GetWindowName('an'):GetValue()) or 0;
	local categ = GetCateg(an);
	local nation = '';
	local comite = '';
	local club = '';
	if dlgTableau:GetWindowName('nation') then
		nation = dlgTableau:GetWindowName('nation'):GetValue();
	end
	if dlgTableau:GetWindowName('comite') then
		comite = dlgTableau:GetWindowName('comite'):GetValue();
	end
	if dlgTableau:GetWindowName('club') then
		club = dlgTableau:GetWindowName('club'):GetValue();
	end
	local modif_manuel = nil;
	
	local r = tDraw:GetIndexRow('Code_coureur', fiscode);
	if r < 0 then		-- on ajoute le coureur dans la table source
		draw.build_table = true;
		draw.skip_question = true;
		draw.ajouter_code = fiscode;
		tDraw:GetRecord():Set('Code_evenement', draw.code_evenement);
		tDraw:GetRecord():Set('Code_coureur', fiscode);
		tDraw:GetRecord():Set('Nom', nom);
		tDraw:GetRecord():Set('Prenom', prenom);
		tDraw:GetRecord():Set('Sexe', sexe);
		tDraw:GetRecord():Set('An',an);
		tDraw:GetRecord():Set('Categ',categ);
		tDraw:GetRecord():Set('Nation', nation);
		tDraw:GetRecord():Set('Comite', comite);
		tDraw:GetRecord():Set('Club', club);
		tDraw:GetRecord():Set('Groupe_tirage', groupe);
		tDraw:GetRecord():Set('Statut', 'CF');
		tDraw:GetRecord():SetNull('ECSL_rank');
		tDraw:GetRecord():SetNull('ECSL_points');
		tDraw:GetRecord():SetNull('ECSL_overall_rank');
		tDraw:GetRecord():SetNull('ECSL_overall_points');
		tDraw:GetRecord():SetNull('WCSL_rank');
		tDraw:GetRecord():SetNull('WCSL_points');
		tDraw:GetRecord():SetNull('Winner_CC');
		tDraw:GetRecord():SetNull('ECSL_overall_rank_0');
		tDraw:GetRecord():SetNull('ECSL_overall_points_0');
		tDraw:GetRecord():SetNull('ECSL_overall_rank_n');
		tDraw:GetRecord():SetNull('ECSL_overall_points_n');

		if config.script_level == 4 then
			if tTableauCoureur[fiscode] then
				if tTableauCoureur[fiscode].ECSL_points > 0 then
					tDraw:GetRecord():Set('ECSL_rank', tTableauCoureur[fiscode].ECSL_rank);
					tDraw:GetRecord():Set('ECSL_points', tTableauCoureur[fiscode].ECSL_points);
				end
				if tTableauCoureur[fiscode].ECSL_overall_points_n > 0 then
					tDraw:GetRecord():Set('ECSL_overall_points_n', tTableauCoureur[fiscode].ECSL_overall_points_n);
					tDraw:GetRecord():Set('ECSL_overall_rank_n', tTableauCoureur[fiscode].ECSL_overall_rank_n);
				end
				if tTableauCoureur[fiscode].ECSL_overall_points > 0 then
					tDraw:GetRecord():Set('ECSL_overall_points', tTableauCoureur[fiscode].ECSL_overall_points);
					tDraw:GetRecord():Set('ECSL_overall_rank', tTableauCoureur[fiscode].ECSL_overall_rank);
				end
				if tTableauCoureur[fiscode].ECSL_overall_points_0 >= 450 then
					tDraw:GetRecord():Set('ECSL_overall_points_0', tTableauCoureur[fiscode].ECSL_overall_points_0);
					tDraw:GetRecord():Set('ECSL_overall_rank_0', tTableauCoureur[fiscode].ECSL_overall_rank_0);
					tDraw:GetRecord():Set('ECSL_overall_points', tTableauCoureur[fiscode].ECSL_overall_points_0);
					tDraw:GetRecord():Set('ECSL_overall_rank', tTableauCoureur[fiscode].ECSL_overall_rank_0);
				end
				if tTableauCoureur[fiscode].WCSL_rank > 0 then
					tDraw:GetRecord():Set('WCSL_points', tTableauCoureur[fiscode].WCSL_points);
					tDraw:GetRecord():Set('WCSL_rank', tTableauCoureur[fiscode].WCSL_rank);
				end
			end

		end
		if point and point >= 0 then
			tDraw:GetRecord():Set('FIS_pts', point);
			tDraw:GetRecord():Set('FIS_clt', clt);
		end
		if draw.discipline == 'DH' then
			if pts_SG and pts_SG >= 0 then
				tDraw:GetRecord():Set('FIS_VIT_pts', pts_SG);
				tDraw:GetRecord():Set('FIS_VIT_clt', rank_SG);
			end
		end
		tDraw:AddRow();
		table.insert(draw.tModifs_tableau, {Code_coureur = fiscode:sub(4), Nom = nom, Prenom = prenom, Nation = nation, Status = 'AD'});
		-- OnOrder()
	end
	draw.build_table = true;
	OnOrder();
	CommandSendList(bolSendDrawOrder);
	CommandSendOrder(bolSendDrawOrder);
	CommandSendMessage();
	local row = tResultat:AddRow();
	tResultat:SetCell('Code_evenement', row, draw.code_evenement);
	tResultat:SetCell('Code_coureur', row, fiscode);
	tResultat:SetCellNull('Dossard', row);
	tResultat:SetCellNull('Rang', row);
	tResultat:SetCell('Nom', row, nom);
	tResultat:SetCell('Prenom', row, prenom);
	tResultat:SetCell('Sexe', row, sexe);
	tResultat:SetCell('An', row, an);
	tResultat:SetCell('Point', row, point);
	tResultat:SetCell('Categ', row, categ);
	tResultat:SetCell('Nation', row, nation);
	tResultat:SetCell('Comite', row, comite);
	tResultat:SetCell('Club', row, club);
	tResultat:SetCell('Groupe', row, 'CF');

	tResultat:SetCell('Modif_manuel', row, modif_manuel);
	base:TableInsert(tResultat, row);
	
	row = tResultat_Info_Tirage:AddRow();
	tResultat_Info_Tirage:SetCell('Code_evenement', row, draw.code_evenement);
	tResultat_Info_Tirage:SetCell('Code_coureur', row, fiscode);
	tResultat_Info_Tirage:SetCell('Groupe_tirage', row, groupe);
	tResultat_Info_Tirage:SetCellNull('Rang_tirage', row);
	tResultat_Info_Tirage:SetCell('ECSL_points', row, ecsl_points);
	tResultat_Info_Tirage:SetCell('ECSL_rank', row, ecsl_rank);
	tResultat_Info_Tirage:SetCell('FIS_pts', row, point);
	tResultat_Info_Tirage:SetCell('FIS_clt', row, clt);
	tResultat_Info_Tirage:SetCell('Statut', row, 'CF');
	if tTableauCoureur[fiscode].ECSL_points then
		tResultat_Info_Tirage:SetCell('ECSL_points', row, tTableauCoureur[fiscode].ECSL_points);
		tResultat_Info_Tirage:SetCell('ECSL_rank', row, tTableauCoureur[fiscode].ECSL_rank);
	end
	if tTableauCoureur[fiscode].WCSL_points then
		tResultat_Info_Tirage:SetCell('WCSL_points', row, tTableauCoureur[fiscode].WCSL_points);
		tResultat_Info_Tirage:SetCell('WCSL_rank', row, tTableauCoureur[fiscode].WCSL_rank);
	end
	if tTableauCoureur[fiscode].ECSL_overall_points then
		tResultat_Info_Tirage:SetCell('ECSL_overall_points', row, tTableauCoureur[fiscode].ECSL_overall_points);
		tResultat_Info_Tirage:SetCell('ECSL_overall_rank', row, tTableauCoureur[fiscode].ECSL_overall_rank);
		tResultat_Info_Tirage:SetCell('ECSL_overall_points_n', row, ecsl_all_pointsn);
		tResultat_Info_Tirage:SetCell('ECSL_overall_rank_n', row, ecsl_all_rankn);
	end
	if tTableauCoureur[fiscode].ECSL_overall_points_0 then
		tResultat_Info_Tirage:SetCell('ECSL_overall_points_0', row, tTableauCoureur[fiscode].ECSL_overall_points_0);
		tResultat_Info_Tirage:SetCell('ECSL_overall_rank_0', row, tTableauCoureur[fiscode].ECSL_overall_rank_0);
	end

	base:TableInsert(tResultat_Info_Tirage, row);
	
	if tResultat_Paiement and tResultat_Paiement:GetNbRows() > 0 then
		row = tResultat_Paiement:AddRow();
		tResultat_Paiement:SetCell('Code_evenement', row, draw.code_evenement);
		tResultat_Paiement:SetCell('Code_coureur', row, fiscode);
		tResultat_Paiement:SetCell('Epreuve_selection'..(draw.row_epreuve + 1), row, 'X');
		base:TableInsert(tResultat_Paiement, row);
	end

		
	-- draw.build_table = false;
	local tView = grid_tableau:GetTableView();
	local tSource = grid_tableau:GetTableSrc();
	if tSource and tView then
		if tView:GetNbRows() ~= tSource:GetNbRows() then
			r = tView:GetIndexRow('Code_coureur', fiscode);
			grid_tableau:SynchronizeRowsView();
		else
			r = tSource:GetIndexRow('Code_coureur', fiscode);
			grid_tableau:SynchronizeRowsSrc();
		end
	end
	grid_tableau:Filter();
	grid_tableau:SelectRow(r);
	
	draw.build_table = false;
	draw.skip_question = false;
	dlgTableau:GetWindowName('code'):SetValue('');
	dlgTableau:GetWindowName('groupe'):SetValue('');
	dlgTableau:GetWindowName('nom'):SetValue('');
	dlgTableau:GetWindowName('prenom'):SetValue('');
	dlgTableau:GetWindowName('an'):SetValue('');
	dlgTableau:GetWindowName('sexe'):SetValue('');
	dlgTableau:GetWindowName('nation'):SetValue('');
	dlgTableau:GetWindowName('points'):SetValue('');
	dlgTableau:GetWindowName('classement'):SetValue('');
	if config.script_level ~= 4 then
		dlgTableau:GetWindowName('comite'):SetValue('');
		dlgTableau:GetWindowName('club'):SetValue('');
	end
end

function OnChangeDossard(row)
	local dossard = tDraw:GetCellInt('Dossard', row);
	if dossard == 0 then
		dossard = '';
	else
		draw.tDossards_pris = draw.tDossards_pris or {};
		draw.tDossards_pris[dossard] = dossard;
	end
	local nodeRaceEvent = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceevent");
	local code_coureur = tDraw:GetCell('Code_coureur', row):sub(4);;
	local nodeDrawBib = xmlNode.Create(nodeRaceEvent, xmlType.ELEMENT_NODE, "drawbib");
	local nodeBib = xmlNode.Create(nodeDrawBib, xmlType.ELEMENT_NODE, "bib", dossard);
	nodeDrawBib:AddAttribute('fiscode', code_coureur);
	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeRaceEvent);
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language, 'Dossard')..' '..dossard..traduction(draw.language, ' attribué pour ')..tDraw:GetCell('Nom', row)..' '..tDraw:GetCell('Prenom', row));
end

function OnChangeStatut(row)
	local statut = tDraw:GetCell('Statut', row);
	base:Query("Update Resultat Set Groupe = '"..statut.."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..tDraw:GetCell('Code_coureur', row).."'");
	local nodeRaceEvent = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceevent");
	local code_coureur = tDraw:GetCell('Code_coureur', row):sub(4);;
	local nodeDrawStatus = xmlNode.Create(nodeRaceEvent, xmlType.ELEMENT_NODE, "drawstatus");
	nodeDrawStatus:AddAttribute('fiscode', code_coureur);
	local nodeStatus = xmlNode.Create(nodeDrawStatus, xmlType.ELEMENT_NODE, "status", statut);
	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeRaceEvent);
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue(traduction(draw.language, 'Statut de ')..tDraw:GetCell('Nom', row)..' '..tDraw:GetCell('Prenom', row)..traduction(draw.language, ' modifié'));
	-- SendMessage(tDraw:GetCell('Nom', row)..' '..tDraw:GetCell('Prenom', row)..' updated. You might have to refresh the page.');
end

function OnGridReorder()
	if config.script_level == 4 then
		tDraw:OrderBy(draw.orderbyCE);
	else
		tDraw:OrderBy(draw.orderbyFIS);
	end
	RefreshGrid();
	grid_tableau:SelectRow(-1);
end

function OnCellChanged(evt)
	local row = evt:GetRow();
	local col = evt:GetCol();
	-- Info('ancienne valeur avant le changement = '..evt:GetString());
	local t = grid_tableau:GetTable();
	local colName = t:GetColumnName(t:GetVisibleColumnsIndex(col));
	if t:GetCell(colName, row) == '0' or t:GetCell(colName, row) == '0.00' then
		if colName:find('tirage') or colName:find('points') or colName:find('rank') or colName:find('Winner') or colName:find('pts') or colName:find('clt') then 
			t:SetCellNull(colName, row);
			grid_tableau:RefreshCell(row, col);
		end
	end
	if colName == 'Statut' then
		if t:GetCell('Statut', row) ~= 'UF' and t:GetCell('Statut', row) ~= 'CF' then
			t:SetCell('Statut', row, 'UF')
			grid_tableau:RefreshCell(row, col);
		end
		OnChangeStatut(row);
		base:TableBulkUpdate(tDraw, 'Statut', 'Resultat_Info_Tirage');
	elseif colName == 'Dossard' then
		if t:GetCell('Statut', row) ~= 'CF' then
			t:SetCellNull('Dossard', row);
			grid_tableau:RefreshCell(row, col);
			local msg = traduction(draw.language, "Le coureur n'est pas confirmé !");
			app.GetAuiFrame():MessageBox(msg, traduction(draw.language, "ATTENTION !!"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
		else
			local ok = true;
			draw.double_tirage_bibo = false;
			local dossard = t:GetCellInt('Dossard', row);
			if dossard == 0 then
				t:SetCellNull('Dossard', row);
				grid_tableau:RefreshCell(row, col);
				if evt:GetString():len() > 0 then
					OnChangeDossard(row);
				end
			else
				for i = 0, t:GetNbRows() -1 do
					if i ~= row then
						if t:GetCellInt('Dossard', i) == dossard then
							t:SetCellNull('Dossard', row);
							grid_tableau:RefreshCell(row, col);
							local msg = traduction(draw.language, 'Dossard')..' '..dossard..traduction(draw.language, ' déjà attribué !!');
							if dossard > 0 then
								app.GetAuiFrame():MessageBox(msg, traduction(draw.language, "ATTENTION !!"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
							end
							ok = false;
						end
					end
				end
				if ok == true then
					OnChangeDossard(row);
				end
			end
		end
		grid_tableau:SynchronizeRows();
		base:TableBulkUpdate(tDraw, 'Dossard', 'Resultat');
		grid_tableau:SetGridCursor(row, col);
	elseif colName == 'Rang_tirage' then
		grid_tableau:SynchronizeRows();
		base:TableBulkUpdate(tDraw, 'Rang_tirage', 'Resultat_Info_Tirage');
	end
end


function OnCellSelected(evt)
	local row = evt:GetRow();
	local col = evt:GetCol();
	draw.row_selected = row;
	local t = grid_tableau:GetTable();
	local colName = t:GetColumnName(t:GetVisibleColumnsIndex(col));
	local code_coureur = t:GetCell('Code_coureur', row);
	grid_tableau:SelectRow(row);
	if colName == 'Code_coureur' then
		local link = "https://www.fis-ski.com/DB/general/biographies.html?fiscode="..string.sub(code_coureur, 4) .."&status=&search=true";
		app.LaunchDefaultBrowser(link);
	end
	if col > 0 and col < grid_tableau:GetNumberCols() -2 then
		return;
	end
	local rang_tirage_selected = t:GetCellInt('Rang_tirage', row);
	local nom = t:GetCell('Nom', row);
	local prenom = t:GetCell('Prenom', row);
	local nation = t:GetCell('Nation', row);
	local identite = nom..'   '..prenom;
	if col == grid_tableau:GetNumberCols() -2 then
		local msg = traduction(draw.language, 'Confirmez-vous la suppression de ')..identite;
		if app.GetAuiFrame():MessageBox(msg, traduction(draw.language, "Confirmer la suppression"), msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
			return ;
		end
		-- suppression du coureur
		table.insert(draw.tModifs_tableau, {Code_coureur = code_coureur:sub(4), Nom = nom, Prenom = prenom, Nation = nation, Status = 'RM'});
		grid_tableau:DeleteRows(row);
		OnSupprimerCoureur(code_coureur, rang_tirage_selected);
	end
	if col == grid_tableau:GetNumberCols() -1 then
		local etat = t:GetCell('Statut', row);
		if etat == 'UF' then
			etat = 'CF';
		else
			if t:GetCellInt('Dossard', row) > 0 then
				local msg = traduction(draw.language, 'Attention - Ce concurrent a déjà un dossard.\nSi vous poursuivez, ce dossard sera effacé\nVoulez-vous poursuivre ?');
				if app.GetAuiFrame():MessageBox(msg, traduction(draw.language, "Attention !!"), msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) ~= msgBoxStyle.YES then
					return;
				end
			end
			etat = 'UF';
			t:SetCellNull('Dossard', row);
		end
		t:SetCell('Statut', row, etat)
		OnChangeStatut(row);
		RefreshGrid();
		CommandValiderUnCoureur(row);
	end
end

function OnCellContext(evt)
	local row = evt:GetRow();
	local col = evt:GetCol();
	if row >= 0 and col >= 0 then
		local cf_uf = 'CF';
		local t = grid_tableau:GetTable();
		local colName = t:GetColumnName(t:GetVisibleColumnsIndex(col));
		if not colName:find('Nom') and not colName:find('Prenom') and not colName:find('Code') and not colName:find('Club')then
			local fnt = font.Create();
			fnt:SetWeight(fontWeight.BOLD);
			evt:SetCellContext({
				font = fnt,
				align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL
			});
		end
		if colName == 'Statut' then
			if t:GetCell('Statut', row) == 'CF' then
				evt:SetCellContext({ 
					align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL,
					bk_color_start = color.LTGREEN, 
					bk_color_end = color.DKGREEN,
					text_color = color.WHITE
					});
			else
				evt:SetCellContext({ 
					align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL,
					bk_color_start = color.LTORANGE, 
					bk_color_end = color.DKORANGE,
					text_color = color.WHITE
					});
			end
			-- cf_uf = t:GetCell('Statut', row);
			-- grid_tableau:SetCellBackgroundColour(row, col, 'green');
		elseif colName == 'Nation' then
			local nation = tDraw:GetCell('Nation', row);
			evt:SetCellContext({ 
			align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL
			});
		elseif colName == 'Code_coureur' then
			local fnt = font.Create();
			fnt:SetWeight(fontWeight.BOLD);
			fnt:SetUnderlined(true);
			evt:SetCellContext({
				font = fnt,
				text_color = color.BLUE
			});
		elseif colName == 'Action' then
			evt:SetCellContext({ 
				bitmaps = { { image = './res/16x16_minus.png'}}
			});
		elseif colName == 'Validation' then
				evt:SetCellContext({ 
					bitmaps = {{ image = './res/40x16_dbl_coche.png'}}
				});
		end
	end
end

function OnGridShown(evt)
	local row = evt:GetRow();
	local col = evt:GetCol();
	if row >= 0 and col >= 0 then
		local t = grid_tableau:GetTable();
		local colName = t:GetColumnName(t:GetVisibleColumnsIndex(col));
		if colName:find('_tirage') or colName:find('Dossard') or colName:find('ECSL') or colName:find('WCSL') or colName:find('Winner') then
			evt:Skip(true);
			return;
		end
	end
	evt:Veto();
end

function OnTirageEgalite(groupe)
	tDrawTirageAuto = tDraw:Copy(true,true);
	local filter = "$(Exaequo_groupe):In("..groupe..")";
	tDrawTirageAuto:Filter(filter, true);
	local bib_first = tDrawTirageAuto:GetCellInt('Rang_tirage', 0);

	params.tableDossards1 = {};
	for row = 0, tDrawTirageAuto:GetNbRows() -1  do
		table.insert(params.tableDossards1, bib_first + row);
	end
	params.tableDossards1 = Shuffle(params.tableDossards1);
	tTableTirage1:RemoveAllRows();
	for row = 0, tDrawTirageAuto:GetNbRows() -1 do
		local new_row1 = tTableTirage1:AddRow();
		tTableTirage1:SetCell('Row', new_row1, row+1);
		local aleatoire = randomFloat(1, 2);
		tTableTirage1:SetCell('Aleatoire', new_row1, aleatoire);
	end
	tTableTirage1:OrderBy('Aleatoire');
	for i = 0, tTableTirage1:GetNbRows() -1 do
		local ligne = tTableTirage1:GetCellInt('Row', i);
		local dossard = params.tableDossards1[ligne];
		tDrawTirageAuto:SetCell('Dossard', i, dossard);
		local identite = tDrawTirageAuto:GetCell('Nom', i)..' '..tDrawTirageAuto:GetCell('Prenom', i);
		local code_coureur = tDrawTirageAuto:GetCell('Code_coureur', i);
		local r = tDraw:GetIndexRow('Code_coureur', code_coureur)
		if r >= 0 then
			tDraw:SetCell('Dossard', r, dossard);
			local cmd = "Update Resultat Set Dossard = "..dossard..", Reserve = '"..string.format('%03d', tDraw:GetCellInt('Rang_tirage', r)).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
			base:Query(cmd);
		end
	end
	RefreshGrid();
	assert(tTableTirage1:GetNbRows() > 0);
	for row = 0, tTableTirage1:GetNbRows() -1 do
		base:TableLoad(tResultat_Info_Bibo, 'Select * From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement);
		local idx = row + 1;
		local tTable1 = {};
		local tTable2 = {};
		table.insert(tTable1, {Col1 = 'Dossard du rang fictif '..idx, Col2 = params.tableDossards1[idx]});
		local xTable1 = {Table1 = tTable1};
		local jsontxt1 = table.ToStringJSON(xTable1, false);
		
		local rang_fictif = tTableTirage1:GetCellInt('Row', row);
		local code_coureur = '';
		local identite = '';
		local pts = '';
		local dossard = params.tableDossards1[rang_fictif] or '';
		code_coureur = tDrawTirageAuto:GetCell('Code_coureur', row);
		identite = tDrawTirageAuto:GetCell('Nom', row)..' '..tDrawTirageAuto:GetCell('Prenom', row);
		pts = tDrawTirageAuto:GetCellDouble('FIS_pts', row);
		local col1 = identite;
		local col2 = pts;
		local col3 = rang_fictif;
		local col4 = dossard;
		table.insert(tTable2, {Identite = col1, Pts = col2, RangFictif = col3, Dossard = col4});
		local xTable2 = {Table2 = tTable2};
		local jsontxt2 = table.ToStringJSON(xTable2, false);
		local rowsql = tResultat_Info_Bibo:AddRow();
		-- adv.Alert('OnTirageEgalite clef primaire = '..draw.code_evenement..', '..groupe..', '..idx);
		tResultat_Info_Bibo:SetCell('Code_evenement', rowsql, draw.code_evenement);
		tResultat_Info_Bibo:SetCell('Groupe', rowsql, groupe);
		-- adv.Alert('jsontxt1 = '..jsontxt1);
		-- adv.Alert('jsontxt2 = '..jsontxt2);
		tResultat_Info_Bibo:SetCell('Ligne', rowsql, idx);
		tResultat_Info_Bibo:SetCell('Table1', rowsql, jsontxt1);
		tResultat_Info_Bibo:SetCell('Table2', rowsql, jsontxt2);
		base:TableInsert(tResultat_Info_Bibo, rowsql);
	end
	base:TableFlush(tResultat_Info_Bibo);
end

function OnTirageRangsPtsNull(rang_first, rang_last)
	local tShuffle = {};
	local rangs = '-1';
	for i = rang_first, rang_last do
		table.insert(tShuffle, i);
		rangs = rangs..','..i;
	end
	tShuffle = Shuffle(tShuffle, true);
	tDrawTirageAuto = tDraw:Copy(true,true);
	local filter = "$(Rang_tirage):In("..rangs..")";
	tDrawTirageAuto:Filter(filter, true);		
	
	tDrawTirageAuto:OrderBy('Prenom');
	tDrawTirageAuto:OrderRandom();
	for j = 0, tDrawTirageAuto:GetNbRows() -1 do
		local valeur_shuffle = tShuffle[j+1];
		local code_coureur = tDrawTirageAuto:GetCell('Code_coureur', j)
		local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
		if r >= 0 then
			tDraw:SetCell('Dossard', r, valeur_shuffle);
			local cmd = "Update Resultat Set Dossard = "..(valeur_shuffle)..", Reserve = '"..string.format('%03d', tDraw:GetCellInt('Rang_tirage', r)).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..tDraw:GetCell('Code_coureur', r).."'";
			base:Query(cmd);
		end
	end
end

function GetRank(code_coureur)
	if not tTableauCoureur[code_coureur] then
		InitTableauCoureur(code_coureur)
	end
	local pts = nil;
	local rank = nil;
	local pts_SG = nil;
	local rank_SG = nil;
	local cmd = "Select * From Classement_Coureur Where Code_coureur = '"..code_coureur.."' And Type_classement = '"..draw.type_classement.."' And Code_liste = "..draw.code_liste;
	tClassement_Coureur = base:TableLoad(cmd);
	if tClassement_Coureur:GetNbRows() == 1 then
		pts = tClassement_Coureur:GetCellDouble('Pts', 0, -1);
		rank = tClassement_Coureur:GetCellInt('Clt', 0, -1);
		-- if code_coureur == 'FIS30488' then
				-- pts = 16.67;
		-- end
	end

	if draw.type_classement == 'IADH' then
		local cmd = "Select * From Classement_Coureur Where Code_coureur = '"..code_coureur.."' And Type_classement = 'IASG' And Code_liste = "..draw.code_liste;
		tClassement_Coureur = base:TableLoad(cmd);
		if tClassement_Coureur:GetNbRows() == 1 then
			pts_SG = tClassement_Coureur:GetCellDouble('Pts', 0, -1);
			rank_SG = tClassement_Coureur:GetCellInt('Clt', 0, -1);
		end
	end
	if pts and pts < 0 then
		pts = nil;
		rank = nil;
	end
	if pts_SG and pts_SG < 0 then
		pts_SG = nil;
		rank_SG = nil;
	end
	tTableauCoureur[code_coureur].FIS_pts = pts;
	tTableauCoureur[code_coureur].FIS_clt = clt;
	tTableauCoureur[code_coureur].FIS_VIT_pts = pts_SG;
	tTableauCoureur[code_coureur].FIS_VIT_clt = rank_SG;
	
	return pts, rank, pts_SG, rank_SG;
end

function RefreshGrid(bolTableSource)	-- bolTableSource = true ou false
	tDraw:OrderBy('Rang_tirage');
	local bolTableSource = bolTableSource or false;
	local tView = grid_tableau:GetTableView();
	local tSource = grid_tableau:GetTableSrc();
	if tSource and tView then
		if tView:GetNbRows() ~= tSource:GetNbRows() then
			dlgTableau:SetLabel(draw.label_dialog..'   ('..tView:GetNbRows()..' / '..tSource:GetNbRows()..' lignes)');
		else
			dlgTableau:SetLabel(draw.label_dialog..'   ('..tSource:GetNbRows()..' lignes)');
		end
	end
	if bolTableSource then
		grid_tableau:SynchronizeRowsSrc();
	else
		grid_tableau:SynchronizeRowsView();
	end
	base:TableBulkUpdate(tDraw,'Dossard', 'Resultat');
	base:TableBulkUpdate(tDraw,'Code_evenement, Groupe_tirage, TG, Rang_tirage, WCSL_points, WCSL_rank, ECSL_points, ECSL_rank, ECSL_30, ECSL_overall_points, ECSL_overall_rank, Winner_CC, FIS_pts, FIS_clt, FIS_SG_pts, FIS_SG_clt, Statut, Racer_info, Pts_info', 'Resultat_Info_Tirage');
end

function BuildTablesDraw()	-- on ajoute ou on supprime des enregistrements dans la table Resultat_Info_Tirage
	tResultat_Info_Tirage = base:GetTable('Resultat_Info_Tirage');
	local cmd = 'Delete From Resultat_Info_Tirage Where Code_evenement = '..draw.code_evenement..' And Code_coureur Not In (Select Code_coureur From Resultat Where Code_evenement = '..draw.code_evenement..')';
	base:Query(cmd);
	base:TableLoad(tResultat_Info_Tirage, 'Select * From Resultat_Info_Tirage Where Code_evenement = '..draw.code_evenement);
	if tResultat_Info_Tirage:GetNbRows() == 0 then
		draw.bolInit = true;
	end
	tResultat:OrderBy('Nom');
	local nb = 0;
	tRankSG = {};
	for i = 0, tResultat:GetNbRows() -1 do
		local code_coureur = tResultat:GetCell('Code_coureur', i);
		local pts, rank, pts_SG, rank_SG = GetRank(code_coureur);
		if pts and pts >= 0 then
			tResultat:SetCell('Point', i, pts);
		end
		if pts_SG and pts_SG >= 0 then
			tRankSG[code_coureur]= {};
			tRankSG[code_coureur].Pts = pts_SG; 
			tRankSG[code_coureur].Rank = rank_SG; 
		end
		local an =  tResultat:GetCellInt('An', i);
		local categ = GetCateg(an);
		tResultat:SetCell('Categ', i, categ);

		local r = tResultat_Info_Tirage:GetIndexRow('Code_coureur', code_coureur);
		if r < 0 then
			nb = nb + 1;
			-- on ajoute le coureur dans la table tResultat_Info_Tirage
			draw.build_table = true;
			row = tResultat_Info_Tirage:AddRow();
			tResultat_Info_Tirage:SetCell('Code_evenement', row, draw.code_evenement);
			tResultat_Info_Tirage:SetCell('Code_coureur', row, tResultat:GetCell('Code_coureur', i));
			tResultat_Info_Tirage:SetCell('Groupe_tirage', row, 5);
			tResultat_Info_Tirage:SetCell('Statut', row, 'UF');
			if not pts then
				pts = -1;
			end
			if pts >= 0 then
				tResultat_Info_Tirage:SetCell('FIS_pts', row, pts);
				tResultat_Info_Tirage:SetCell('FIS_clt', row, rank);
			else
				tResultat_Info_Tirage:SetCellNull('FIS_pts', row);
				tResultat_Info_Tirage:SetCellNull('FIS_clt', row);
			end
			if not pts_SG then
				pts_SG = -1;
			end
			if pts_SG and pts_SG >= 0 then
				tResultat_Info_Tirage:SetCell('FIS_VIT_pts', row, pts_SG);
				tResultat_Info_Tirage:SetCell('FIS_VIT_clt', row, rank_SG);
			else
				tResultat_Info_Tirage:SetCellNull('FIS_VIT_pts', row);
				tResultat_Info_Tirage:SetCellNull('FIS_VIT_clt', row);
			end
			base:TableInsert(tResultat_Info_Tirage, row);
		else
			if pts and pts >= 0 then
				tResultat_Info_Tirage:SetCell('FIS_pts', r, pts);
				tResultat_Info_Tirage:SetCell('FIS_clt', r, rank);
			else
				tResultat_Info_Tirage:SetCellNull('FIS_pts', r);
				tResultat_Info_Tirage:SetCellNull('FIS_clt', r);
			end
			if FIS_VIT_pts and FIS_VIT_pts >= 0 then
				tResultat_Info_Tirage:SetCell('FIS_VIT_pts', r, pts_SG);
				tResultat_Info_Tirage:SetCell('FIS_VIT_clt', r, rank_SG);
			else
				tResultat_Info_Tirage:SetCellNull('FIS_VIT_pts', r);
				tResultat_Info_Tirage:SetCellNull('FIS_VIT_clt', r);
			end
			base:TableUpdate(tResultat_Info_Tirage, r);
		end
	end
	base:TableBulkUpdate(tResultat);
	local msg = traduction(draw.language, 'Les points ont été mis à jour avec la liste FIS n° ')..draw.code_liste;				
	app.GetAuiFrame():MessageBox(msg, " FIS Points", msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION);
end

function TraitementtDrawG5()
	-- adv.Alert('\nEntrée de TraitementtDrawG5 avec '..tDrawG5:GetNbRows()..' enregistrements et un previous rang de tirage : '..draw.rang_tirage..', groupe en entrée = '..draw.groupe_before_coc);
	
	for j = 0, tDrawG5:GetNbRows() -1 do		-- les winners des CC 
		if tDrawG5:GetCellInt('Pris', j) == 0 then
			draw.rang_tirage = draw.rang_tirage + 1;
			local code_coureur = tDrawG5:GetCell('Code_coureur', j);
			local r2 = tDraw:GetIndexRow('Code_coureur', code_coureur);
			tDraw:SetCell('TG', r2, 'tDrawG5');
			tDraw:SetCell('Racer_info', r2, 'COC');
			tDraw:SetCell('Pts_info', r2, '');
			tDraw:SetCell('Pris', r2, 1);
			tDrawG5:SetCell('Pris', j, 1);
			tDraw:SetCell('Groupe_tirage', r2, draw.groupe_before_coc + 1);
			tDraw:SetCell('ECSL_30', r2, 10);
			tDraw:SetCell('Rang_tirage', r2, draw.rang_tirage);
			if tDraw:GetCell('Statut', r2) == 'CF' then
				tDraw:SetCell('Dossard', r2, draw.rang_tirage);
			end
			tDraw:SetCell('Reserve', r2, string.format('%03d', draw.rang_tirage));
			local r = tDrawG6:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG6:RemoveRowAt(r);
			end
			r = tDrawG4:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG4:SetCell('Pris', r, 1);
			end
			if draw.debug == 0 then
				local msg = 'Order '..draw.rang_tirage..' '..tDrawG5:GetCell('Identite', j)..', Group : '..(draw.current_group + 1)..', COC Winner : '..tDrawG5:GetCell('Winner_CC',j)..', taken ECSL: '..draw.nb_pris_ecsl;
				app.GetAuiFrame():MessageBox(msg, 'Debug - Group '..(draw.current_group + 1)..' / COC Winner', msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
			end
		end
	end
	-- adv.Alert('Sortie de TraitementtDrawG5\n');

end

function CheckExaequo()
	draw.statut = 'CF';
	tDraw:OrderBy('Rang_tirage');
	draw.bolExisteDossard = false;
	draw.bolWinner = false;
	local groupe_en_cours = 101;
	draw.exaequo_groupe = 101;
	for i = 0, tDraw:GetNbRows() -1 do
		tDraw:SetCellNull('Exaequo_groupe', i);
	end
	for i = 0, tDraw:GetNbRows() -1 do
		if tDraw:GetCell('Statut', i):len() == 0 then
			tDraw:SetCell('Statut', i, 'UF');
		end
		if tDraw:GetCell('Statut', i) == 'UF' then
			draw.statut = 'UF';
		end
		if tDraw:GetCell('Winner_CC', i):len() > 0 then
			draw.bolWinner = true;
		end
		local groupe_tirage = tDraw:GetCellInt('Groupe_tirage', i);
		if groupe_tirage >= draw.groupe_mini_exeaquo then			
			local groupe_tirage_next = tDraw:GetCellInt('Groupe_tirage', i+1);
			if groupe_tirage == groupe_tirage_next then
				local pts_fis = tDraw:GetCellDouble('FIS_pts', i, -1);
				local pts_fis_next = tDraw:GetCellDouble('FIS_pts', i+1, -1);
				local pts_ecsl = tDraw:GetCellInt('ECSL_points', i, -1);
				local pts_ecsl_next = tDraw:GetCellInt('ECSL_points', i+1, -1);
				local pts_ecsl_overall = tDraw:GetCellInt('ECSL_overall_points', i, -1);
				local pts_ecsl_overall_next = tDraw:GetCellInt('ECSL_overall_points', i+1, -1);
				local pts_wcsl = tDraw:GetCellInt('WCSL_points', i);
				local pts_wcsl_next = tDraw:GetCellInt('WCSL_points', i+1, -1);
				local winner_cc = tDraw:GetCell('Winner_CC', i);
				local winner_cc_next = tDraw:GetCell('Winner_CC', i+1);
				local exaequo = false;
				if pts_fis > 0 and pts_fis_next == pts_fis and pts_ecsl_next == pts_ecsl then
					if groupe_en_cours == nil then
						draw.exaequo_groupe = draw.exaequo_groupe + 1;
						groupe_en_cours = draw.exaequo_groupe;
					end
					local infoegal = '==';
					tDraw:SetCell('Exaequo_groupe', i, draw.exaequo_groupe);
					tDraw:SetCell('Exaequo_groupe', i+1, draw.exaequo_groupe);
					tDraw:SetCell('Pts_info', i, '=');
					tDraw:SetCell('Pts_info', i+1, '=');
					tDraw:SetCell('Racer_info', i, infoegal);
					tDraw:SetCell('Racer_info', i+1, infoegal);
				else
					groupe_en_cours = nil;
				end
			end
		end
	end
	tDraw:SetCounter('Exaequo_groupe');
	base:TableBulkUpdate(tDraw, 'Racer_info, Pts_info', 'Resultat_Info_Tirage');
end

function ChecktDraw()
	draw.bolExisteDossard = false;
	draw.bolTirageBiboFait = false;
	draw.bolTirageGroupe2Fait = false;
	draw.bolExisteSansPoint = false;
	draw.bolTirageSansPointFait = false;
	draw.statut = 'CF';
	tDraw:OrderBy('Rang_tirage');
	for i = 0, tDraw:GetNbRows() -1 do
		local code_coureur = tDraw:GetCell('Code_coureur', i);
		tDraw:SetCell('Dossard_bibo', i, 0);
		if config.script_level == 1 then			-- FIS
			if tDraw:GetCellInt('Groupe_tirage', i) == 1 then
				tDraw:SetCell('Dossard_bibo', i, 1);
			end
		else
			if not draw.bolVitesse then
				if tDraw:GetCellInt('Groupe_tirage', i) < 3 then
					tDraw:SetCell('Dossard_bibo', i, 1);
				end
			end
		end
		if tDraw:GetCell('Statut', i) ~= 'CF' then
			draw.statut = 'UF';
			tDraw:SetCell('Statut', i, 'UF');
		end
		if tDraw:GetCell('Winner_CC', i):len() > 0 then
			tDraw:SetCell('Winner_CC', i, '1')
		end
		if tDraw:GetCellDouble('FIS_pts', i, -1) < 0 then
			draw.bolExisteSansPoint = true
		end
		base:Query("Update Resultat Set Groupe = '"..tDraw:GetCell('Statut', i).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'");
		if tDraw:GetCellInt('Dossard', i) > 0 then
			draw.bolExisteDossard = true;
			if tDraw:GetCellInt('Dossard_bibo', i) == 1 then
				draw.bolTirageBiboFait = true;
			end
			if tDraw:GetCellInt('Groupe_tirage', i) == 2 then
				draw.bolTirageGroupe2Fait = true;
			end
			if tDraw:GetCell('TG', i) == 'tDrawG6' then
				draw.bolTirageAvecPointFait = true;
			end
			if tDraw:GetCell('TG', i) == 'PtsFISNull' then
				draw.bolTirageSansPointFait = true;
			end
		end
	end
end

function SetupBoardFIS()
	draw.get_payment = false;
	if tResultat_Paiement and tResultat_Paiement:GetNbRows() > 0 then
		local msg = 'Prise en compte des paiements uniquement (O/N)';
		if app.GetAuiFrame():MessageBox(
			msg, "Trier le tableau",
			msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) == msgBoxStyle.YES then
			draw.get_payment = true;
		end
	end
	draw.rang_tirage = 0;
	tDraw:OrderBy('FIS_pts');
	draw.ptsFIS7 = tDraw:GetCellDouble('FIS_pts',6)
	draw.ptsFIS15 = tDraw:GetCellDouble('FIS_pts',14)
	draw.ptsFIS30 = tDraw:GetCellDouble('FIS_pts',29);
	for i = 0, tDraw:GetNbRows() -1 do
		local code_coureur = tDraw:GetCell('Code_coureur', i);
		-- adv.Alert('tDraw - on traite '..tDraw:GetCell('Nom', i).. 'dans tDraw');
		local pts = tDraw:GetCellDouble('FIS_pts', i, 10000);
		if code_coureur == 'FIS6537726' then
			pts = 51.89;
		end
		if config.script_level == 3 or config.script_level == 2	then -- Championnats de France ou Championnats du Monde Junior
			if draw.bolVitesse then
				if pts <= draw.ptsFIS15 then
					draw.current_group = 1;
				elseif pts <= draw.ptsFIS30 then
					draw.current_group = 2;
				elseif pts < 9999 then
					draw.current_group = 3;
				else
					draw.current_group = 4;
				end
			else
				if pts <= draw.ptsFIS7 then
					draw.current_group = 1;
				elseif pts <= draw.ptsFIS15 then
					draw.current_group = 2;
				elseif pts < 9999 then
					draw.current_group = 3;
				else
					draw.current_group = 4;
				end
			end
		else -- FIS normale
			if pts <= draw.ptsFIS15 then
				draw.current_group = 1;
			elseif pts <= 9999 then
				draw.current_group = 2;
			else
				draw.current_group = 3;
			end
		end
		tDraw:SetCell('Groupe', i, draw.current_group);
		if draw.get_payment == true then
			draw.paiement = true;
			local r = tResultat_Paiement:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then
				if tResultat_Paiement:GetCellInt('Etat_paiement', r) < 8 then
					tDraw:SetCell('Statut', i, 'UF');
					draw.paiement = false;
				else
					tDraw:SetCell('Statut', i, 'CF');
				end
			end
		end
		draw.rang_tirage = draw.rang_tirage + 1;
		tDraw:SetCell('Pris', i, 1);
		tDraw:SetCell('Groupe_tirage', i, draw.current_group);
		tDraw:SetCell('TG', i, 'Groupe'..draw.current_group);
		tDraw:SetCell('Rang_tirage', i, draw.rang_tirage);
		tDraw:SetCell('Reserve', i, string.format('%03d', tDraw:GetCellInt('Rang_tirage', i)));
	end
	RefreshGrid(true);
	--ChecktDraw();
end

function RemoveRacerTable(table_origine, code)
	-- je suis dans la table_origine 2, j'efface de la table 3 à la table 6
	local row = -1;
	for i = table_origine, 5 do
		if i == 1 then
			row = tDrawG2:GetIndexRow('Code_coureur', code);
			if row >= 0 then
				tDrawG2:RemoveRowAt(row);
			end
		elseif i == 2 then
			row = tDrawG3:GetIndexRow('Code_coureur', code);
			if row >= 0 then
				tDrawG3:RemoveRowAt(row);
			end
		elseif i == 3 then
			row = tDrawG4:GetIndexRow('Code_coureur', code);
			if row >= 0 then
				tDrawG4:RemoveRowAt(row);
			end
		elseif i == 4 then
			row = tDrawG5:GetIndexRow('Code_coureur', code);
			if row >= 0 then
				tDrawG5:RemoveRowAt(row);
			end
		elseif i == 5 then
			row = tDrawG6:GetIndexRow('Code_coureur', code);
			if row >= 0 then
				tDrawG6:RemoveRowAt(row);
			end
		end
	end
end

function SetuptDraw()
	if not draw.build_table then
		tDraw:OrderBy('Rang_tirage');
		return;
	end
	draw.paiement = true;
	draw.pts_last_ecsl = nil;
	draw.bolExisteDossard = false;
	draw.bolTirageBiboFait = false;
	draw.bolTirageAvecPointFait = false;
	draw.bolTirageSansPointFait = false;
	base:Query('Delete From Resultat_Info_Bibo Where Abs(Code_evenement) = '..draw.code_evenement);
	local cmd = "Update Resultat Set Dossard = Null Where Code_evenement = "..draw.code_evenement;
	base:Query(cmd);
	tResultat_Info_Bibo:RemoveAllRows();
	params.tableDossards1 = {};
	tTableTirage1:RemoveAllRows();
	for i = 0, tDraw:GetNbRows() -1 do
		tDraw:SetCell('Pris', i, 0);
		tDraw:SetCellNull('Dossard_bibo', i);
		tDraw:SetCellNull('Reserve', i);
		tDraw:SetCell('Groupe', i, 5);
		tDraw:SetCellNull('TG', i);
		tDraw:SetCellNull('ECSL_30', i);
		tDraw:SetCellNull('Racer_info', i);
		tDraw:SetCellNull('Pts_info', i);
		tDraw:SetCellNull('Exaequo_groupe', i);
		tDraw:SetCellNull('Groupe_tirage', i);
		tDraw:SetCellNull('Rang_tirage', i);
		if tDraw:GetCellInt('ECSL_points', i, -1) < 0 then
			tDraw:SetCellNull('ECSL_rank', i);
			tDraw:SetCellNull('ECSL_points', i);
		end
		if tDraw:GetCellInt('WCSL_points', i, -1) < 0 then
			tDraw:SetCellNull('WCSL_rank', i);
			tDraw:SetCellNull('WCSL_points', i);
		end
		if tDraw:GetCellInt('ECSL_overall_points', i, -1) < 0 then
			tDraw:SetCellNull('ECSL_overall_rank', i);
			-- tDraw:SetCellNull('ECSL_overall_points', i);
		end
		if tDraw:GetCell('Winner_CC', i):len() == 0 then
			tDraw:SetCellNull('Winner_CC', i);
		end
	end
	tDraw:OrderBy('FIS_pts');
	if config.script_level == 4 then
		OnRAZData('Tout');
		tDrawG1 = tDraw:Copy(true,true);	-- dans les 15 de la ECSL
		tDrawG2 = tDraw:Copy(true,true);	-- les 450+
		tDrawG3 = tDraw:Copy(true,true);	-- dans les 30 de la WC
		tDrawG4 = tDraw:Copy(true,true);	-- tous les restants
		tDrawG5 = tDraw:Copy(true,true);	-- tous les COC winners 
		tDrawG6 = tDraw:Copy(true,true);	-- tous les pts FIS
		if draw.finale_ce == 'Yes' or draw.finale_ce == 'Oui' then
			tDrawG5:RemoveAllRows();
		end
	else
		OnRAZData('Tout');
		SetupBoardFIS();	-- on ne travaille que sur tDraw;
		return;
	end
--[[
on est en Coupe d'Europe pour ce qui suit
groupe 1 ECSL de la discipline : de 1 à 15 (ou plus). Compte dans les 45 ECSL
groupe 2 450+ (en finale uniquement les OA de la saison en cours sinon plus de 450 pts en EC la saison dernière de 16 à x. Compte dans les 45 ECSL
groupe 2 on met en plus dans ce groupe les coureurs de la WC dans les 30 de la WCSL de la discipline. On départage selon les pts ECSL sinon par les pts FIS
groupe 3 On continue avec les Pts de la ECSL et les Pts FIS si on n'a pas assez de Pts ECSL jusqu'à en avoir 45.
groupe 4 Si pas en finale, cette série est interrompue si on a un vainqueur d'une Coupe continentale qui par systématiquement en 31 ème position.
groupe 5 La série interrompue reprend jusqu'à en avoir 45.
Groupe 6 On poursuit selon les points FIS.
]]
	-- adv.Alert('draw.ECSL_pts15 = '..draw.ECSL_pts15);
	tDrawG1:OrderBy(draw.tClefTri[1].OrderBy);
	draw.ECSL_pts15 = tDrawG1:GetCellInt('ECSL_points', 14);
	for i = tDrawG1:GetNbRows() -1, 0, -1 do		-- dans les 15
		local pts = tDrawG1:GetCellInt('ECSL_points', i, -1);
		if pts < draw.ECSL_pts15 then
			tDrawG1:RemoveRowAt(i);
		end
	end
	tDrawG2:OrderBy(draw.tClefTri[2].OrderBy);		-- les 450+
	for i = tDrawG2:GetNbRows() -1, 0, -1 do
		local pts = tDrawG2:GetCellInt('ECSL_overall_points', i);
		if pts < 450 then
			tDrawG2:RemoveRowAt(i);
		end
	end

	tDrawG3:OrderBy(draw.tClefTri[3].OrderBy);		-- dans les 30 de la WCSL
	for i = tDrawG3:GetNbRows() -1, 0, -1 do
		local clt = tDrawG3:GetCellInt('WCSL_rank', i, 9999);
		if clt > config.clt_WCSL then
			tDrawG3:RemoveRowAt(i);
		end
	end

	-- on ne fait rien sur tDrawG4
		
	tDrawG5:OrderBy(draw.tClefTri[5].OrderBy);	-- les COC_winners
	for i = tDrawG5:GetNbRows() -1, 0, -1 do
		local winner = tDrawG5:GetCell('Winner_CC', i);
		if winner:len() == 0 then
			tDrawG5:RemoveRowAt(i);
		end
	end
	
	-- adv.Alert('avant le traitement - tDrawG1:GetNbRows() = '..tDrawG1:GetNbRows()..', tDrawG2:GetNbRows() = '..tDrawG2:GetNbRows()..', tDrawG3:GetNbRows() = '..tDrawG3:GetNbRows()..', tDrawG4:GetNbRows() = '..tDrawG4:GetNbRows()..', tDrawG5:GetNbRows() = '..tDrawG5:GetNbRows());
	tDrawG6:OrderBy('FIS_pts, ECSL_points DESC'); -- coureurs ayant des points FIS
	for i = tDrawG6:GetNbRows() -1, 0, -1 do
		local pts = tDrawG6:GetCellDouble('FIS_pts', i, -1);
		if pts < 0 then
			tDrawG6:RemoveRowAt(i);
		end
	end
	
	-- adv.Alert('3- tDrawG6:GetNbRows() = '..tDrawG6:GetNbRows())
	-- liste des variables de position
	-- config.posit_450 
	-- config.posit_COC 
	-- config.prendre_ECSL 
	-- config.clt_WCSL
	draw.current_group = 1;
	draw.nb_pris_ecsl = 0;
	params.nb_groupe1 = 0;
	params.nb_groupe2 = 0;
	draw.rang_tirage = 0;
	for order = 1, #draw.tClefTri do
		-- adv.Alert('order = '..order..', draw.tClefTri[order].Groupe = '..draw.tClefTri[order].Groupe)
		if order == 1 then  -- dans les 15 de la ECSL
			tDrawG1:OrderBy(draw.tClefTri[1].OrderBy);	-- départage des exaequos ECSL par les pts FIS
			draw.ECSL_pts7 =  tDrawG1:GetCellInt('ECSL_points', 6);
			draw.ECSL_pts15 = tDrawG1:GetCellInt('ECSL_points', 14);
			for i = 0, tDrawG1:GetNbRows() -1 do
				local ecsl_pts = tDrawG1:GetCellInt('ECSL_points', i);
				if not draw.bolVitesse then
					if ecsl_pts < draw.ECSL_pts7 then
						draw.current_group = 2;
					end
				end
				draw.rang_tirage = draw.rang_tirage + 1;
				local code_coureur = tDrawG1:GetCell('Code_coureur', i);
				local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
				tDraw:SetCell('ECSL_30', r, 1);
				tDraw:SetCell('Groupe_tirage', r, draw.current_group);
				tDraw:SetCell('TG', r, 'tDrawG1');
				tDraw:SetCell('Pris', r, 1);
				tDraw:SetCell('Rang_tirage', r, draw.rang_tirage);
				tDraw:SetCell('Reserve', r, string.format('%03d', draw.rang_tirage));
				if draw.debug == 0 then
					local msg = 'Order '..draw.rang_tirage..' '..tDrawG1:GetCell('Identite', i)..', Group:'..draw.current_group..', ECSL_points : '..tDrawG1:GetCellInt('ECSL_points',i);
					app.GetAuiFrame():MessageBox(msg, 'Debug - Group '..draw.current_group..' / ECSL', msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				end
				RemoveRacerTable(1, code_coureur);
			end
		elseif order == 2 then	-- les + de 450 pts ils restent dans le groupe 1 en vitesse pour choisir leur dossard en vitesse. On affichera 2 comme groupe sur le site de la FIS
			if not draw.bolVitesse then
				draw.current_group = draw.current_group + 1;
			end
			tDrawG2:OrderBy(draw.tClefTri[2].OrderBy);				
			-- adv.Alert('on traite tDrawG2, tDrawG2:GetNbRows() = '..tDrawG2:GetNbRows());
			for i = 0, tDrawG2:GetNbRows() -1 do 
				local code_coureur = tDrawG2:GetCell('Code_coureur', i);
				local pts_fis = tDrawG2:GetCellDouble('FIS_pts', i);
				draw.rang_tirage = draw.rang_tirage + 1;
				-- adv.Alert('tDrawG2, identité = '..tDrawG2:GetCell('Nom', i).." "..tDrawG2:GetCell('Prenom', i)..', draw.rang_tirage = '..draw.rang_tirage);
				local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
				tDraw:SetCell('TG', r, 'tDrawG2');
				tDraw:SetCell('Racer_info', r, '450+');
				tDraw:SetCell('Pts_info', r, '>');
				tDraw:SetCell('Pris', r, 1);
				tDraw:SetCell('Groupe_tirage', r, draw.current_group);
				tDraw:SetCell('Rang_tirage', r, draw.rang_tirage);
				tDraw:SetCell('ECSL_30', r, 2);
				if draw.bolVitesse == false and tDraw:GetCell('Statut', r) == 'CF' then
					tDraw:SetCell('Dossard', r, draw.rang_tirage);
				end
				tDraw:SetCell('Reserve', r, string.format('%03d', draw.rang_tirage));
				if draw.debug == 0 then
					local msg = 'Order '..draw.rang_tirage..' '..tDrawG2:GetCell('Identite', i)..', Group:'..draw.current_group..', 450+ points : '..tDrawG2:GetCellInt('ECSL_overall_points',i);
					app.GetAuiFrame():MessageBox(msg, 'Debug - Group '..draw.current_group..' / 450+', msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				end
				RemoveRacerTable(2, code_coureur);
			end
			-- adv.Alert('après traitement de tDrawG2 - tDrawG1:GetNbRows() = '..tDrawG1:GetNbRows()..', tDrawG2:GetNbRows() = '..tDrawG2:GetNbRows()..', tDrawG3:GetNbRows() = '..tDrawG3:GetNbRows()..', tDrawG4:GetNbRows() = '..tDrawG4:GetNbRows()..', tDrawG5:GetNbRows() = '..tDrawG5:GetNbRows());
		elseif order == 3 then	-- dans les 30 de la WCSL 
			if draw.bolVitesse then
				draw.current_group = draw.current_group + 1;
			end
			-- adv.Alert('on traite tDrnawG3, tDrawG3:GetNbRows() = '..tDrawG3:GetNbRows());
			tDrawG3:OrderBy(draw.tClefTri[3].OrderBy);				
			for i = 0, tDrawG3:GetNbRows() -1 do		
				local code_coureur = tDrawG3:GetCell('Code_coureur', i);
				local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
				draw.rang_tirage = draw.rang_tirage + 1;
				tDraw:SetCell('TG', r, 'tDrawG3');
				tDraw:SetCell('Racer_info', r, 'WC');
				tDraw:SetCell('Pts_info', r, '<');
				tDraw:SetCell('Pris', r, 1);
				tDraw:SetCell('Groupe_tirage', r, draw.current_group);
				tDraw:SetCell('Rang_tirage', r, draw.rang_tirage);
				tDraw:SetCell('ECSL_30', r, 3);
				if not draw.bolVitesse and tDraw:GetCell('Statut', r) == 'CF' then
					tDraw:SetCell('Dossard', r, draw.rang_tirage);
				end
				tDraw:SetCell('Reserve', r, string.format('%03d', draw.rang_tirage));
				if draw.debug == 0 then
					local msg = 'Order '..draw.rang_tirage..' '..tDrawG2:GetCell('Identite', i)..', Group:'..draw.current_group..', WCSL rank: '..tDrawG2:GetCellInt('WCSL_rank',i);
					app.GetAuiFrame():MessageBox(msg, 'Debug - Group '..draw.current_group..' / WCSL', msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				end
				RemoveRacerTable(3, code_coureur);
			end
			-- adv.Alert('après traitement de tDrawG3 - tDrawG1:GetNbRows() = '..tDrawG1:GetNbRows()..', tDrawG2:GetNbRows() = '..tDrawG2:GetNbRows()..', tDrawG3:GetNbRows() = '..tDrawG3:GetNbRows()..', tDrawG4:GetNbRows() = '..tDrawG4:GetNbRows()..', tDrawG5:GetNbRows() = '..tDrawG5:GetNbRows());
		elseif order == 4 then	-- les ECSL plus les points FIS
			-- adv.Alert('on traite le groupe 4, tri sur : '..draw.tClefTri[order].OrderBy);
			tDrawG4:OrderBy(draw.tClefTri[order].OrderBy);
			draw.nb_pris_ecsl = tDrawG1:GetNbRows() + tDrawG2:GetNbRows();
			-- adv.Alert('tri du groupe 4 = '..draw.tClefTri[order].OrderBy);
			if tDrawG4:GetNbRows() > 0 then
				draw.group_tirage_ecsl = draw.current_group;
				draw.vitesseFait = false;
				draw.ecslFait = false;
				if draw.finale_ce == 'Oui' or draw.finale_ce == 'Yes' then
					draw.last_row_ecsl_finale = config.prendre_ECSL + tDrawG3:GetNbRows();
					-- adv.Alert('draw.last_row_ecsl_finale  = '..draw.last_row_ecsl_finale);
					draw.pts_last_ecsl = 1;
				end
				draw.pts_limite = nil;
				draw.pts_limite_vitesse_groupe2 = nil;
				for i = 0, tDrawG4:GetNbRows() -1 do
					if tDrawG4:GetCellInt('Pris', i) == 0 then
						local code_coureur = tDrawG4:GetCell('Code_coureur', i);
						local ecsl_points =  tDrawG4:GetCellInt('ECSL_points', i);
						if ecsl_points == 0 then
							break;
						end
						draw.nb_pris_ecsl = draw.nb_pris_ecsl + 1;
						if draw.nb_pris_ecsl <= config.prendre_ECSL then
							if ecsl_points > 0 then
								draw.pts_limite = ecsl_points;
							end
						end
						if draw.bolVitesse then
							if draw.nb_pris_ecsl <= 30 then
								if ecsl_points > 0 then
									draw.pts_limite_vitesse_groupe2 = ecsl_points;
								end
							end
						end
						if draw.bolVitesse then
							if ecsl_points < draw.pts_limite_vitesse_groupe2 then
								if not draw.vitesseFait then
									draw.vitesseFait = true;
									draw.current_group = draw.current_group + 1;
								end
							end
						end
						if ecsl_points < draw.pts_limite then
							if not draw.ecslFait then
								draw.ecslFait = true;
								if draw.finale_ce == 'Non' or draw.finale_ce == 'No' then
									break;
								end
							end
						end
						tDrawG4:SetCell('Pris', i, 1);
						draw.rang_tirage = draw.rang_tirage + 1;
						local rtDraw = tDraw:GetIndexRow('Code_coureur', code_coureur);
						tDraw:SetCell('ECSL_30', rtDraw, 4);
						tDraw:SetCell('TG', rtDraw, 'tDrawG4');
						tDraw:SetCell('Rang_tirage', rtDraw, draw.rang_tirage);
						tDraw:SetCell('Pris', rtDraw, 1);
						tDraw:SetCell('Groupe_tirage', rtDraw, draw.current_group);
						if draw.debug == 0 then
							local msg = 'Order '..draw.rang_tirage..' '..tDrawG4:GetCell('Identite', i)..', Group:'..draw.current_group..', ECSL : '..tDrawG4:GetCellInt('ECSL_points',i)..', taken ECSL: '..draw.nb_pris_ecsl;
							app.GetAuiFrame():MessageBox(msg, 'Debug - Group '..draw.current_group..' / <= 45 ECSL', msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
						end
						if not draw.pts_last_ecsl and draw.nb_pris_ecsl == config.prendre_ECSL then
							draw.pts_last_ecsl = ecsl_points;
						end
						tDraw:SetCell('Rang_tirage', rtDraw, draw.rang_tirage);
						tDraw:SetCell('Reserve', rtDraw, string.format('%03d', draw.rang_tirage));
						if draw.rang_tirage < config.posit_COC -1 then
							RemoveRacerTable(4, code_coureur);
							RemoveRacerTable(5, code_coureur);
						else
							RemoveRacerTable(5, code_coureur);
						end
						if draw.rang_tirage == config.posit_COC -1 then
							if tDrawG5:GetNbRows() > 0 then					
								if not draw.groupe_before_coc then
									draw.groupe_before_coc = draw.current_group;
								end
								tDrawG5:OrderBy(draw.tClefTri[5].OrderBy);
								TraitementtDrawG5();
								draw.current_group = draw.groupe_before_coc;
								-- adv.Alert('Après Traitement tDrawG5, draw.rang_tirage = '..draw.rang_tirage..', groupe avant traitement G5 = '..draw.groupe_before_coc);
							end
						end
					end
				end
			end
			-- adv.Alert('après traitement de tDrawG4 : tDrawG1:GetNbRows() = '..tDrawG1:GetNbRows()..', tDrawG2:GetNbRows() = '..tDrawG2:GetNbRows()..', tDrawG3:GetNbRows() = '..tDrawG3:GetNbRows()..', tDrawG4:GetNbRows() = '..tDrawG4:GetNbRows()..', tDrawG5:GetNbRows() = '..tDrawG5:GetNbRows());
			-- adv.Alert('3 - rajouter_pts_fis = '..rajouter_pts_fis..', draw.current_group = '..draw.current_group);
		end 
	end
	draw.current_group = draw.current_group + 1;
	-- adv.Alert('draw.last_code_ecsl = '..tostring(draw.last_code_ecsl));
	tDraw:OrderBy('FIS_pts, ECSL_points DESC');
	for i = 0, tDraw:GetNbRows() -1 do
		if tDraw:GetCellInt('Pris', i) == 0 then
			if draw.debug == 0 then
				adv.Alert('pour la suite , on prend '..tDraw:GetCell('Nom', i)..', draw.current_group = '..draw.current_group);
			end
			tDraw:SetCell('Pris', i, 1);
			draw.rang_tirage = draw.rang_tirage + 1;
			tDraw:SetCell('Rang_tirage', i, draw.rang_tirage);
			tDraw:SetCell('Reserve', i, string.format('%03d', draw.rang_tirage));
			if tDraw:GetCellDouble('FIS_pts', i, -1) >= 0 then
				tDraw:SetCell('Groupe_tirage', i, draw.current_group);
				tDraw:SetCell('TG', i, 'tDrawG6');
			else
				tDraw:SetCell('Groupe_tirage', i, draw.current_group + 1);
				tDraw:SetCell('TG', i, 'PtsFISNull');
			end
			if draw.rang_tirage == config.posit_COC -1 then
				draw.groupe_before_coc = 2;
				if tDrawG5:GetNbRows() > 0 then					
					tDrawG5:OrderBy(draw.tClefTri[5].OrderBy);
					TraitementtDrawG5();
					draw.current_group = draw.groupe_before_coc + 2;
					-- adv.Alert('Après Traitement tDrawG5, draw.rang_tirage = '..draw.rang_tirage..', groupe avant traitement G5 = '..draw.groupe_before_coc);
				end
			end
		end
	end
	tDraw:OrderBy('Rang_tirage');
	for i = tDraw:GetNbRows() -1, 0, -1 do
		if tDraw:GetCellInt('ECSL_30', i) == 4 then
			tDraw:SetCell('ECSL_30', i, 99);
			break;
		end
	end

	RefreshGrid();
	ChecktDraw();
end

function OnLiveState(evt)
	local tb = dlgTableau:GetWindowName('tbtableau');
	if draw.state == true then
		draw.state = false;
		tb:SetToolNormalBitmap(btnMenuCommande, './res/chrono32x32_ko.png');
	else
		draw.state = true;
		tb:SetToolNormalBitmap(btnMenuCommande, './res/chrono32x32_ok.png');
	end
	tb:EnableTool(btnMenuSend:GetId(), draw.state);
	tb:EnableTool(btnSendMessage:GetId(), draw.state);
end

function AfficheMenuCommande()
	local menuContext =  menu.Create();
	local btnState = menuContext:Append({label=traduction(draw.language,"Activation ou Désactivation du Live"), image ="./res/32x32_fis.png"});
	local btnClear = menuContext:Append({label=traduction(draw.language,"RAZ à la FIS"), image ="./res/32x32_clear.png"});
	local btn_reset_socket = menuContext:Append({label=traduction(draw.language,"Reset de la connexion à la FIS"), image = "./res/32x32_satellite.png"});

	dlgTableau:Bind(eventType.MENU, OnLiveState, btnState);
	dlgTableau:Bind(eventType.MENU, OnReset, btnClear);
	dlgTableau:Bind(eventType.MENU, OnResetSocket, btn_reset_socket);
	
	dlgTableau:PopupMenu(menuContext);
	menuContext:Delete();
end

function AfficheMenuRAZ()
	local menuContext =  menu.Create();
	local btnRAZRang = menuContext:Append({label=traduction(draw.language,"RAZ des Rangs"), image ="./res/32x32_clear.png"});
	local btnRAZGroupe = menuContext:Append({label=traduction(draw.language,"RAZ des Groupes"), image ="./res/32x32_clear.png"});
	local btnRAZAll = menuContext:Append({label=traduction(draw.language,"RAZ des deux"), image ="./res/32x32_clear.png"});
	local btnRAZDossard =  menuContext:Append({label=traduction(draw.language,"RAZ des Dossards"), image ="./res/32x32_clear.png"});
	local btnRAZDossardSel = menuContext:Append({label=traduction(draw.language,"RAZ des Dossards pour les lignes sélectionnées"), image ="./res/32x32_clear.png"});
	
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.skip_question = false;
			OnRAZData('Rang_tirage')
		end
	, btnRAZRang);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.skip_question = false;
			OnRAZData('Groupe_tirage')
		end, btnRAZGroupe);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.skip_question = false;
			OnRAZData('All')
		end
	, btnRAZAll);
	
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.skip_question = false;
			params.tableDossards1 = {};
			tTableTirage1:RemoveAllRows();
			draw.bolTirageAvecPointFait = false;
			draw.bolTirageGroupe1Fait = false;
			draw.bolTirageGroupe2Fait = false;
			draw.bolTirageBiboFait = false;
			draw.bolTirageSansPointFait = false;
			OnRAZData('Dossard')
			SendMessage('Board refreshed');
		end, btnRAZDossard);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			params.tableDossards1 = {};
			tTableTirage1:RemoveAllRows();
			local groupe1 = false;
			local groupe2 = false;
			local rows = grid_tableau:GetSelectedRows();
			for i = 1, #rows do
				tDraw:SetCellNull('Dossard', rows[i]);
				groupe = tDraw:GetCellInt('Groupe_tirage', rows[i]);
				if groupe == 1 then
					groupe1 = true;
					draw.bolTirageGroupe1Fait = false;
				end
				if groupe == 2 then
					groupe2 = true;
					draw.bolTirageGroupe2Fait = false;
				end
			end
			if groupe1 == true then
				draw.bolTirageBiboFait = false;
				-- local cmd = 'Delete From Resultat_Info_Bibo Where Groupe = 1 And Code_evenement = '..draw.code_evenement;
				-- base:Query(cmd);
				tResultat_Info_Bibo:RemoveAllRows();
			end
			if groupe2 == true and draw.bolVitesse then
				-- local cmd = 'Delete From Resultat_Info_Bibo Where Groupe = 2 And Code_evenement = -'..draw.code_evenement;
				-- base:Query(cmd);
				tResultat_Info_Bibo:RemoveAllRows();
				local first_row_1530, last_row_1530 = GetRowsGroupe2();
				SetDossardsAvailable(last_row_1530);
			end
			RefreshGrid();
			if draw.state == true then
				local msg = traduction(draw.language, "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.");
				if dlgTableau:MessageBox(
					msg, traduction(draw.language, "Renvoi des dossards"),
					msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
				end
				CommandRenvoyerDossards(false);
			end
		end
	, btnRAZDossardSel);
	
	dlgTableau:PopupMenu(menuContext);
	menuContext:Delete();	
end

function AfficheMenuSend()
	local menuContext = menu.Create();
	local btnSendParticipants = menuContext:Append({label=traduction(draw.language,"Envoi des participants"), image ="./res/32x32_send.png"});
	local btnSendTableau = menuContext:Append({label=traduction(draw.language,"Envoi du tableau à la FIS"), image ="./res/32x32_send.png"});
	local btnSendTableauSansDossards = menuContext:Append({label=traduction(draw.language,"Envoi du tableau sans les dossards"), image ="./res/32x32_send.png"});
	local btnSendDossards = menuContext:Append({label=traduction(draw.language,"Envoi de tous les dossards"), image ="./res/32x32_send.png"});
	local btnSendStartList = menuContext:Append({label=traduction(draw.language,"Envoi de la liste de départ"), image ="./res/32x32_send.png"});

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			bolSendDrawOrder = false;
			OnSendTableau(bolSendDrawOrder)
			SendMessage('Participants list');
			nodelivedraw:ChangeAttribute('board_status_'..draw.code_evenement, 'participants');
			local last_message = 'Participant List';
			if draw.paiement == false then
				last_message = 'RED = Unpayed status on '..os.date('%d/%m%Y at %H:%M');
			end
			SendMessage(last_message);
			nodelivedraw:ChangeAttribute('last_message', last_message);
			config.doc:SaveFile();
		end
		, btnSendParticipants);
		
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			bolSendDrawOrder = true;
			bolSendDossard = true;
			OnSendTableau(bolSendDrawOrder)
			nodelivedraw:ChangeAttribute('board_status_'..draw.code_evenement, 'board');
			local last_message = 'Draw available';
			if draw.paiement == false then
				last_message = 'RED = Unpayed status on '..os.date('%d/%m%Y at %H:%M');
			end
			SendMessage(last_message);
			nodelivedraw:ChangeAttribute('last_message', last_message);
			config.doc:SaveFile();
		end
		, btnSendTableau);
		
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			bolSendDrawOrder = true;
			bolSendDossard = false;
			OnSendTableau(bolSendDrawOrder)
			nodelivedraw:ChangeAttribute('board_status_'..draw.code_evenement, 'board');
			local last_message = 'Draw available';
			if draw.paiement == true then
				local last_message = 'RED = Unpayed status on '..os.date('%d/%m%Y at %H:%M');
			end
			SendMessage(last_message);
			nodelivedraw:ChangeAttribute('last_message', last_message);
			config.doc:SaveFile();
		end
		, btnSendTableauSansDossards);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local msg = traduction(draw.language, "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.");
			if dlgTableau:MessageBox(
				msg, traduction(draw.language, "Renvoi des dossards"),
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
			end
			CommandRenvoyerDossards(false);
		end
		, btnSendDossards);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			bolSendDrawOrder = true;
			CommandSendStartList();
		end
		, btnSendStartList);


	dlgTableau:PopupMenu(menuContext);
	menuContext:Delete();	
end

function AfficheMenuValider()
	local menuContext = menu.Create();
	local btnValiderSelection = menuContext:Append({label=traduction(draw.language,"Validation des coureurs filtrés"), image ="./res/32x32_down.png"});
	local btnValiderCoureurs = menuContext:Append({label=traduction(draw.language,"Validation globale des coureurs"), image ="./res/32x32_dialog_ok.png"});
	local btnInValiderSelection = menuContext:Append({label=traduction(draw.language,"Invalider les coureurs filtrés"), image ="./res/32x32_close.png"});
	local btnInvaliderCoureurs = menuContext:Append({label=traduction(draw.language,"Revenir au statut Non Validé"), image ="./res/32x32_dialog_ko.png"});
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			CommandValiderCoureurs('CF');
			SendMessage('Board confirmed, bib drawing in progress');
		end
		, btnValiderCoureurs);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			CommandValiderCoureurs('UF');
			SendMessage('Board refreshed');
		end
		, btnInvaliderCoureurs);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local t = grid_tableau:GetTable();
			local indexcol = t:GetVisibleColumnsIndex('Statut');
			for row = 0, t:GetNbRows() -1 do
				t:SetCell('Statut', row, 'CF');
				grid_tableau:RefreshCell(row, indexcol);
			end
			grid_tableau:SynchronizeRowsView();
			base:TableBulkUpdate(tDraw, 'Statut', 'Resultat_Info_Tirage');
			OnSendTableau(bolSendDrawOrder);
			SendMessage('Board refreshed');
		end
		, btnValiderSelection);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local t = grid_tableau:GetTable();
			local indexcol = t:GetVisibleColumnsIndex('Statut');
			for row = 0, t:GetNbRows() -1 do
				t:SetCell('Statut', row, 'UF');
				grid_tableau:RefreshCell(row, indexcol);
			end
			grid_tableau:SynchronizeRowsView(); -- on est sur la vue
			base:TableBulkUpdate(tDraw, 'Statut', 'Resultat_Info_Tirage');
			OnSendTableau(bolSendDrawOrder);
			SendMessage('Board refreshed');
		end
		, btnInValiderSelection);

	dlgTableau:PopupMenu(menuContext);
	menuContext:Delete();	
end

function AfficheMenuPrint()
	local menuContext = menu.Create();
	local btnPrintDoubleTirageBibo = menuContext:Append({label=traduction(draw.language,"Impression du double tirage du BIBO"), image ="./res/32x32_printer.png"});
	local btnPrintDoubleTirageVitesse = menuContext:Append({label=traduction(draw.language,"Impression du double tirage du groupe 2 en Vitesse"), image ="./res/32x32_printer.png"});
	local btnPrintDoubleTirageEgalite = menuContext:Append({label=traduction(draw.language,"Impression du double tirage des exaequos"), image ="./res/32x32_printer.png"});
	local btnPrintEtiquettesAlpha = menuContext:Append({label=traduction(draw.language,"Impression des étiquettes par ordre alphabétique"), image ="./res/32x32_printer.png"});
	local btnPrintEtiquettesNation = menuContext:Append({label=traduction(draw.language,"Impression des étiquettes par Nation"), image ="./res/32x32_printer.png"});
	local btnPrintEtiquettesParpoints = menuContext:Append({label=traduction(draw.language,"Impression des étiquettes par Points"), image ="./res/32x32_printer.png"});
	local btnPrintTableau = menuContext:Append({label=traduction(draw.language,"Impression du tableau des coureurs"), image ="./res/32x32_printer.png"});
	local btnPrintNation = menuContext:Append({label=traduction(draw.language,"Impression des coureurs par Nation"), image ="./res/32x32_printer.png"});
	local btnPrintFinale = menuContext:Append({label=traduction(draw.language,"Qualifiés pour les finales"), image ="./res/32x32_printer.png"});
	local btnPrintFeuilleTirage = menuContext:Append({label=traduction(draw.language,"Impression de la feuille de tirage"), image ="./res/32x32_printer.png"});
	local btnPrintTop75 = menuContext:Append({label=traduction(draw.language,"Impression du TOP ")..config.topx_FIS ..traduction(draw.language," en points FIS"), image ="./res/32x32_printer.png"});
	local btnPrintGetZK = menuContext:Append({label=traduction(draw.language,"Impression des ZK potentiels par Nation"), image ="./res/32x32_printer.png"});
	local btnPrintStartlist = menuContext:Append({label=traduction(draw.language,"Liste de départ en anglais"), image ="./res/32x32_printer.png"});
	menuContext:Enable(btnPrintFinale:GetId(), false);
	menuContext:Enable(btnPrintTop75:GetId(), false);
	menuContext:Enable(btnPrintGetZK:GetId(), false);
	menuContext:Enable(btnPrintDoubleTirageVitesse:GetId(), false);
	if config.script_level == 2 then
		menuContext:Enable(btnPrintGetZK:GetId(), true);
	end
	if config.script_level == 4 then
		menuContext:Enable(btnPrintTop75:GetId(), true);
		menuContext:Enable(btnPrintFinale:GetId(), true);
		if draw.bolVitesse then
			menuContext:Enable(btnPrintDoubleTirageVitesse:GetId(), true);
		end
	elseif config.script_level == 3 and draw.bolVitesse then
		menuContext:Enable(btnPrintDoubleTirageVitesse:GetId(), true);
	end

	dlgTableau:Bind(eventType.MENU, OnPrintFeuilleTirage, btnPrintFeuilleTirage);
	dlgTableau:Bind(eventType.MENU, OnPrintTop75, btnPrintTop75);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			OnPrintDoubleTirage(1);
			if not draw.bolVitesse then
				if config.script_level > 1 then
					OnPrintDoubleTirage(2);
				end
			end
			report = nil;
		end, btnPrintDoubleTirageBibo);
		
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			tDraw:OrderBy('Rang_tirage');
			for i = 0, tDraw:GetNbRows() -1 do
				if tDraw:GetCellInt('Groupe_tirage', i) == 2 then
					params.nb_groupe1 = i;
					break;
				end
			end
			OnPrintDoubleTirage(2);
			report = nil;
		end, btnPrintDoubleTirageVitesse);
		
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local cmd = 'Select * From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement..' And Groupe > 100';
			base:TableLoad(tResultat_Info_Bibo, cmd);
			tResultat_Info_Bibo:SetCounter('Groupe');
			if tResultat_Info_Bibo:GetCounter('Groupe'):GetNbRows() > 0 then
				for i = 0, tResultat_Info_Bibo:GetCounter('Groupe'):GetNbRows() -1 do
					local id_groupe = tonumber(tResultat_Info_Bibo:GetCounter('Groupe'):GetCell(0,i)) or 0;
					if id_groupe > 0 then
						OnPrintDoubleTirageEgalite(id_groupe);
					end
				end			
			end
		end, btnPrintDoubleTirageEgalite);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			OnPrintEtiquettes('Nom, Prenom');
		end, btnPrintEtiquettesAlpha);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			OnPrintEtiquettes('Nation, Nom, Prenom');
		end, btnPrintEtiquettesNation);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			if config.script_level == 4 then
				OnPrintEtiquettes(draw.orderbyCE);
			else
				OnPrintEtiquettes(draw.orderbyFIS);
			end
		end, btnPrintEtiquettesParpoints);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			-- adv.Alert('draw.orderbyCE = '..tostring(draw.orderbyCE));
			if config.script_level == 4 then
				OnPrintTableau(draw.orderbyCE);
			else
				OnPrintTableau(draw.orderbyFIS);
			end
		end, btnPrintTableau);
		
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			OnPrintNation();
		end, btnPrintNation);

	if config.script_level == 2 then
		dlgTableau:Bind(eventType.MENU, 
			function(evt)
				OnPrintZKNation();
			end, btnPrintGetZK);
	end

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			OnPrintStartlist();
			end, btnPrintStartlist);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			OnPrepareQualifies();
			OnPrintFinale();
			tDraw:OrderBy('Rang_tirage');
		end, btnPrintFinale);

	dlgTableau:PopupMenu(menuContext);
	menuContext:Delete();	
end

function AfficheMenuOutils()
	local menuContext = menu.Create();
	local btnTirageDossardsBIBO = menuContext:Append({label=traduction(draw.language, "Double tirage à la mêlée du BIBO"), image ="./res/32x32_bib.png"});
	local btnTirageDossardsGroup1Tech = menuContext:Append({label=traduction(draw.language, "Double tirage à la mêlée du Groupe 1 Tech"), image ="./res/32x32_bib.png"});
	local btnTirageDossardsGroup2Tech = menuContext:Append({label=traduction(draw.language, "Double tirage à la mêlée du Groupe 2 Tech"), image ="./res/32x32_bib.png"});
	local btnTirageDossardsRestants = menuContext:Append({label=traduction(draw.language, "Tirage des dossards restants (avec points)"), image ="./res/32x32_bib.png"});
	local btnTirageDossardsEgalite = menuContext:Append({label=traduction(draw.language, "Double tirage des exaequos"), image ="./res/32x32_bib.png"});
	local btnTirageDossardsSansPoints = menuContext:Append({label=traduction(draw.language, "Double tirage à la mêlée (sans points)"), image ="./res/32x32_bib.png"});
	local btnTirageVitesse1530 = menuContext:Append({label=traduction(draw.language, "Double tirage à la mêlée des coureurs du groupe 2 en Vitesse"), image ="./res/32x32_bib.png"});
	local btnWeb = menuContext:Append({label=traduction(draw.language, "Vers la page FIS de la course"), image ="./res/32x32_fis.png"});
	local btnDecalerBas = menuContext:Append({label=traduction(draw.language, "Décaler les rangs de tirage de +1"), image ="./res/32x32_list_add.png"});
	local btnDecalerHaut = menuContext:Append({label=traduction(draw.language, "Décaler les rangs de tirage de -1"), image ="./res/32x32_list_remove.png"});
	local btnDecalerGroupeBas = menuContext:Append({label=traduction(draw.language, "Décaler les groupes de tirage de +1"), image ="./res/32x32_down.png"});
	local btnDecalerGroupeHaut = menuContext:Append({label=traduction(draw.language, "Décaler les groupes de tirage de -1"), image ="./res/32x32_up.png"});
	local btnExporter = menuContext:Append({label=traduction(draw.language, "Exporter le tableau (fichier csv)"), image ="./res/32x32_csv.png"});
	local btnGetECSL = menuContext:Append({label=traduction(draw.language, "Charger un fichier csv ECSL"), image ="./res/32x32_startlist.png"});
	local btnGetECPrevious = menuContext:Append({label=traduction(draw.language, "Charger un fichier csv Cup Standing Saison n-1"), image ="./res/32x32_startlist.png"});
	local btnGetWCSL = menuContext:Append({label=traduction(draw.language, "Charger un fichier csv WCSL"), image ="./res/32x32_startlist.png"});
	local btnGetFISlist = menuContext:Append({label=traduction(draw.language, "Charger une liste FIS (csv)"), image ="./res/32x32_startlist.png"});
	local btnDocs = menuContext:Append({label=traduction(draw.language, "Vers la page FIS des documents alpins"), image ="./res/32x32_fis.png"});
	local btnAideCE = menuContext:Append({label=traduction(draw.language, "Aide / ranking en CE"), image ="./res/32x32_ranking.png"});

	menuContext:Enable(btnTirageVitesse1530:GetId(), false);
	menuContext:Enable(btnGetECSL:GetId(), false);
	menuContext:Enable(btnGetECPrevious:GetId(), false);
	menuContext:Enable(btnTirageDossardsGroup1Tech:GetId(), false);
	menuContext:Enable(btnTirageDossardsGroup2Tech:GetId(), false);
	if not draw.bolVitesse then
		if config.script_level > 1 then
			menuContext:Enable(btnTirageDossardsBIBO:GetId(), false);
			menuContext:Enable(btnTirageDossardsGroup1Tech:GetId(), true);
			menuContext:Enable(btnTirageDossardsGroup2Tech:GetId(), true);
		end
	else
		menuContext:Enable(btnTirageDossardsBIBO:GetId(), false);
		if config.script_level > 1 then
			menuContext:Enable(btnTirageVitesse1530:GetId(), true);
		end
	end
	if config.script_level == 4 then
		menuContext:Enable(btnGetECSL:GetId(), true);
		menuContext:Enable(btnGetECPrevious:GetId(), true);
		menuContext:Enable(btnGetWCSL:GetId(), true);
		menuContext:Enable(btnAideCE:GetId(), true);
	end
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local groupe_limite = 1;
			params.nb_groupe1 = 0;
			params.nb_groupe2 = 0;
			if config.script_level > 1 then
				groupe_limite = 2;
			end
			tDraw:OrderBy('Rang_tirage');
			draw.bolTirageBiboFait = false;
			for i = 0, tDraw:GetNbRows() -1 do
				if tDraw:GetCellInt('Groupe_tirage', i) <= groupe_limite then
					if tDraw:GetCellInt('Groupe_tirage', i) == 1 then
						params.nb_groupe1 = params.nb_groupe1 + 1;
					else
						params.nb_groupe2 = params.nb_groupe2 + 1;
					end
					if tDraw:GetCellInt('Dossard', i) > 0 then
						draw.bolTirageBiboFait = true;
					end
				end
			end
			if draw.bolTirageBiboFait == true then
				local msg = traduction(draw.language, "Les dossards du BIBO ont déjà été tirés !!");
				dlgTableau:MessageBox(msg, traduction(draw.language, "Erreur"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			local msg = traduction(draw.language, "Cliquer sur Oui pour lancer le double tirage du BIBO.").."\n"..
					traduction(draw.language, "Les coureurs doivent être validés au préalable.").."\n\n"..
					traduction(draw.language, "Vous pourrez retrouver cette édition dans les impressions").."\n\n"..
					traduction(draw.language, "S'il existe deux sous-groupes (1-7 et 8-15), les deux tirages sont indépendants.");
			if dlgTableau:MessageBox(
				msg, traduction(draw.language, "Attribution des dossards"),
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
			end
			ChecktDraw();
			if draw.statut == 'UF' then
				local msg = traduction(draw.language, "Tous les coureurs n'ont pas été Validés !!");
				dlgTableau:MessageBox(msg, traduction(draw.language, "Erreur"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			draw.print_alone = false;
			base:Query('Delete From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement..' And Groupe < 100');
			tResultat_Info_Bibo:RemoveAllRows();
			-- les coureurs sont du groupe de tirage 1
			draw.start_Bib = nil;
			tDrawG6 = tDraw:Copy(true,true);
			tDrawG6:OrderBy('Rang_tirage');
			local filter = "$(Groupe_tirage):In(1)";
			tDrawG6:Filter(filter, true);
			BuildTableTirage(1, params.nb_groupe1);
			OnEncodeJsonBibo(draw.code_evenement, 1)
			if config.script_level > 1 then
				tDrawG6 = tDraw:Copy(true,true);
				tDrawG6:OrderBy('Rang_tirage');
				local filter = "$(Groupe_tirage):In(2)";
				tDrawG6:Filter(filter, true);
				BuildTableTirage(params.nb_groupe1 + 1, params.nb_groupe2);
				OnEncodeJsonBibo(draw.code_evenement, 2);
			end

			ChecktDraw()
			draw.bolTirageBiboFait = true;
			if draw.state == true then
				local msg = traduction(draw.language, "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.");
				if dlgTableau:MessageBox(
					msg, traduction(draw.language,traduction(draw.language, "Renvoi des dossards")),
					msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
				end
				CommandRenvoyerDossards();
			end
		end
		, btnTirageDossardsBIBO);
		
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			tDraw:OrderBy('Rang_tirage');
			draw.bolTirageGroupe1Fait = false;
			params.nb_groupe1 = 0;
			for i = 0, tDraw:GetNbRows() -1 do
				if tDraw:GetCellInt('Groupe_tirage', i) == 1 then
					params.nb_groupe1 = params.nb_groupe1 + 1;
					if tDraw:GetCellInt('Dossard', i) > 0 then
						draw.bolTirageGroupe1Fait = true;
					end
				end
			end
			if draw.bolTirageGroupe1Fait == true then
				local msg = traduction(draw.language, "Les dossards du Groupe 1 ont déjà été tirés !!");
				dlgTableau:MessageBox(msg, traduction(draw.language, "Erreur"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			local msg = traduction(draw.language, "Cliquer sur Oui pour lancer le double tirage du Groupe 1.").."\n"..
					traduction(draw.language, "Les coureurs doivent être validés au préalable.").."\n\n"..
					traduction(draw.language, "Vous pourrez retrouver cette édition dans les impressions").."\n\n"..
					traduction(draw.language, "S'il existe deux sous-groupes (1-7 et 8-15), les deux tirages sont indépendants.");
			if dlgTableau:MessageBox(
				msg, traduction(draw.language, "Attribution des dossards"),
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
			end
			ChecktDraw();
			if draw.statut == 'UF' then
				local msg = traduction(draw.language, "Tous les coureurs n'ont pas été Validés !!");
				dlgTableau:MessageBox(msg, traduction(draw.language, "Erreur"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			draw.print_alone = false;
			base:Query('Delete From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement..' And Groupe = 1');
			draw.start_Bib = nil;
			tDrawG6 = tDraw:Copy(true,true);
			tDrawG6:OrderBy('Rang_tirage');
			local filter = "$(Groupe_tirage):In(1)";
			tDrawG6:Filter(filter, true);
			BuildTableTirage(1, params.nb_groupe1);
			OnEncodeJsonBibo(draw.code_evenement, 1)
			-- OnPrintDoubleTirage(1);
			draw.print_alone = true;
			ChecktDraw()
			draw.bolTirageGroupe1Fait = true;
			if draw.state == true then
				local msg = traduction(draw.language, "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.");
				if dlgTableau:MessageBox(
					msg, traduction(draw.language,traduction(draw.language, "Renvoi des dossards")),
					msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
				end
				CommandRenvoyerDossards();
			end
		end
		, btnTirageDossardsGroup1Tech);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			tDraw:OrderBy('Rang_tirage');
			draw.bolTirageGroupe2Fait = false;
			params.nb_groupe2 = 0;
			for i = 0, tDraw:GetNbRows() -1 do
				if tDraw:GetCellInt('Groupe_tirage', i) == 2 then
					params.nb_groupe2 = params.nb_groupe2 + 1;
					if tDraw:GetCellInt('Dossard', i) > 0 then
						draw.bolTirageGroupe2Fait = true;
					end
				end
			end
			
			if draw.bolTirageGroupe2Fait == true then
				local msg = traduction(draw.language, "Les dossards du Groupe 2 ont déjà été tirés !!");
				dlgTableau:MessageBox(msg, traduction(draw.language, "Erreur"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			local msg = traduction(draw.language, "Cliquer sur Oui pour lancer le double tirage du Groupe 1.").."\n"..
					traduction(draw.language, "Les coureurs doivent être validés au préalable.").."\n\n"..
					traduction(draw.language, "Vous pourrez retrouver cette édition dans les impressions").."\n\n"..
					traduction(draw.language, "S'il existe deux sous-groupes (1-7 et 8-15), les deux tirages sont indépendants.");
			if dlgTableau:MessageBox(
				msg, traduction(draw.language, "Attribution des dossards"),
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
			end
			ChecktDraw();
			if draw.statut == 'UF' then
				local msg = traduction(draw.language, "Tous les coureurs n'ont pas été Validés !!");
				dlgTableau:MessageBox(msg, traduction(draw.language, "Erreur"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			draw.print_alone = false;
			base:Query('Delete From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement..' And Groupe = 2');
			-- les coureurs sont du groupe de tirage 2
			draw.start_Bib = nil;
			tDrawG6 = tDraw:Copy(true,true);
			tDrawG6:OrderBy('Rang_tirage');
			local filter = "$(Groupe_tirage):In(2)";
			tDrawG6:Filter(filter, true);
			local firstBib = tDrawG6:GetCellInt('Rang_tirage', 0);
			BuildTableTirage(firstBib, params.nb_groupe2);
			OnEncodeJsonBibo(draw.code_evenement, 2)
			-- OnPrintDoubleTirage(2);
			draw.print_alone = true;
			ChecktDraw()
			draw.bolTirageGroupe2Fait = true;
			if draw.state == true then
				local msg = traduction(draw.language, "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.");
				if dlgTableau:MessageBox(
					msg, traduction(draw.language,traduction(draw.language, "Renvoi des dossards")),
					msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
				end
				CommandRenvoyerDossards();
			end
		end
		, btnTirageDossardsGroup2Tech);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			if draw.statut == 'UF' then
				local msg = traduction(draw.language, "Tous les coureurs n'ont pas été Validés !!");
				dlgTableau:MessageBox(msg, traduction(draw.language, "Erreur"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			
			tDraw:OrderBy('Rang_tirage');
			CheckExaequo();
			for i = 0, tDraw:GetNbRows() -1 do
				if tDraw:GetCellDouble('FIS_pts', i, -1) < 0 then
					break;
				end
				local groupe_lu = tDraw:GetCellInt('Groupe_tirage', i);
				if groupe_lu >= draw.groupe_mini_exeaquo then
					local dossard = tDraw:GetCellInt('Dossard', i);
					if dossard == 0 then
						if tDraw:GetCell('Pts_info', i) ~= '=' then				
							local rang_tirage = tDraw:GetCellInt('Rang_tirage', i);
							local groupe_tirage = tDraw:GetCellInt('Groupe_tirage', i);
							local code_coureur = tDraw:GetCell('Code_coureur', i);
							dossard = rang_tirage;
							tDraw:SetCell('Dossard', i, dossard);
							local cmd = "Update Resultat Set Dossard = "..dossard.." Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
							base:Query(cmd);
						end
					end
				end
			end
			RefreshGrid()
			-- CommandRenvoyerDossards(false);
			draw.bolTirageAvecPointFait = true;
			if draw.state == true then
				local msg = traduction(draw.language, "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.");
				if dlgTableau:MessageBox(
					msg, traduction(draw.language, "Renvoi des dossards"),
					msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
				end
				CommandRenvoyerDossards();
			end
		end
		, btnTirageDossardsRestants);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			--ChecktDraw();
			CheckExaequo ();
			if draw.statut == 'UF' then
				local msg = traduction(draw.language, "Tous les coureurs n'ont pas été Validés !!");
				dlgTableau:MessageBox(msg, traduction(draw.language, "Erreur"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement..' And Groupe > 100';
			base:Query(cmd);

			for i = 0, tDraw:GetCounter('Exaequo_groupe'):GetNbRows() -1 do
				local id_groupe = tonumber(tDraw:GetCounter('Exaequo_groupe'):GetCell(0,i)) or 0;
				if id_groupe > 0 then	-- on fait le double tirage pour le groupe de tirage concerné
					local nombre = tonumber(tDraw:GetCounter('Exaequo_groupe'):GetCell(1,i));
					OnTirageEgalite(id_groupe);
				end
			end
			RefreshGrid()
			if draw.state == true then
				local msg = traduction(draw.language, "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.");
				if dlgTableau:MessageBox(
					msg, traduction(draw.language, "Renvoi des dossards"),
					msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
				end
				CommandRenvoyerDossards();
			end
		end
		, btnTirageDossardsEgalite);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			if draw.statut == 'UF' then
				local msg = traduction(draw.language, "Tous les coureurs n'ont pas été Validés !!");
				dlgTableau:MessageBox(msg, traduction(draw.language, "Erreur"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			if draw.bolTirageGroupe2Fait == true then
				local msg = traduction(draw.language, "Les dossards du Groupe 2 ont déjà été tirés !!");
				dlgTableau:MessageBox(msg, traduction(draw.language, "Erreur"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			local first_row_1530, last_row_1530 = GetRowsGroupe2();
			if first_row_1530 < 0 then
				local msg = traduction(draw.language, "Tous les dossards du Groupe 1 n'ont pas été attribués.");
				dlgTableau:MessageBox(
					msg, traduction(draw.language, "Attribution des dossards"),
					msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				return;
			end
			SetDossardsAvailable(last_row_1530);
			local msg = traduction(draw.language, "Cliquer sur Oui pour lancer l'attribution").."\n"..
					traduction(draw.language, "des dossards pour les coureurs du groupe 2 en vitesse.").."\n"..
					traduction(draw.language, "Les coureurs doivent être validés au préalable.");
			if dlgTableau:MessageBox(
				msg, traduction(draw.language, "Attribution des dossards"),
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
			end
			
			tDraw:OrderBy('Rang_tirage');
			tDrawG6 = tDraw:Copy(true,true);
			for i = 0, tDraw:GetNbRows() -1 do
				if tDraw:GetCellInt('Groupe_tirage', i) == 2 then
					params.nb_groupe1 = i;
				end
			end

			local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement..' And Groupe < 100';
			base:Query(cmd);
			ReplaceTableEnvironnement(tDrawG6, '_DrawG6');
			local filter = "$(Groupe_tirage):In(2)";
			tDrawG6:Filter(filter, true);
			BuildTableTirageVitesse();
			draw.print_alone = true;
			OnEncodeJsonBibo(draw.code_evenement, 2);
			RefreshGrid();
			if draw.state == true then
				local msg = traduction(draw.language, "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.");
				if dlgTableau:MessageBox(
					msg, traduction(draw.language, "Renvoi des dossards"),
					msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
				end
				CommandRenvoyerDossards();
			end
		end
		, btnTirageVitesse1530);		

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			if draw.statut == 'UF' then
				local msg = traduction(draw.language, "Tous les coureurs n'ont pas été Validés !!");
				dlgTableau:MessageBox(msg, "Erreur", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			local rang_first, rang_last = SetRangsPtsNull();
			if rang_last > 0 then
				OnTirageRangsPtsNull(rang_first, rang_last);
				draw.bolTirageSansPointFait = true;
			end
			RefreshGrid();
			if draw.state == true then
				local msg = traduction(draw.language, "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.");
				if dlgTableau:MessageBox(
					msg, traduction(draw.language, "Renvoi des dossards"),
					msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
				end
				CommandRenvoyerDossards();
			end
		end
		, btnTirageDossardsSansPoints);		
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			OnWebDraw(draw.web)
		end, btnWeb);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			app.LaunchDefaultBrowser('https://www.fis-ski.com/en/inside-fis/document-library/alpine-documents')
		end, btnDocs);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local ligne = CheckDossardAfter();
			if ligne > 0 then
				local msg = traduction(draw.language, "Opération impossible, un dossard a déjà été tiré").."\n"..traduction(draw.language, "à la ligne ")..ligne;
				dlgTableau:MessageBox(
					msg, traduction(draw.language, "Décalage des rangs de tirage"), 
					msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				return;
			end
			local msg = traduction(draw.language, "Voulez-vous décaler les rangs de tirage de +1").."\n"..
						traduction(draw.language, "à partir de la ligne ")..(draw.row_selected + 1).." ?";
			if dlgTableau:MessageBox(
				msg, traduction(draw.language, "Décalage des rangs de tirage"), 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				OnDecaler(draw.row_selected, true, false);
			end
		end, btnDecalerBas);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			local msg = traduction(draw.language, "Voulez-vous décaler les rangs de tirage de -1").."\n"..
						traduction(draw.language, "à partir de la ligne sélectionnée ?");
			if dlgTableau:MessageBox(
				msg, traduction(draw.language, "Décalage des rangs de tirage"), 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				local rowsSelected = grid_tableau:GetSelectedRows();
				local row = rowsSelected[1]; 
				OnDecaler(row, false, false);
			end
		end, btnDecalerHaut);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			local msg = traduction(draw.language, "Voulez-vous décaler les groupes de tirage de +1").."\n"..
						traduction(draw.language, "à partir de la ligne sélectionnée ?");
			if dlgTableau:MessageBox(
				msg, traduction(draw.language, "Décalage des groupes de tirage"), 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				local rowsSelected = grid_tableau:GetSelectedRows();
				local row = rowsSelected[1]; 
				OnDecaler(row, true, true);
			end
		end, btnDecalerGroupeBas);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			local msg = traduction(draw.language, "Voulez-vous décaler les groupes de tirage de -1").."\n"..
						traduction(draw.language, "à partir de la ligne sélectionnée ?");
			if dlgTableau:MessageBox(
				msg, traduction(draw.language, "Décalage des groupes de tirage"), 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				local rowsSelected = grid_tableau:GetSelectedRows();
				local row = rowsSelected[1]; 
				OnDecaler(row, false, true);
			end
		end, btnDecalerGroupeHaut);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			if tDraw:GetNbRows() > 0 then
				if draw.prepare_qualifie then
					OnExport(tDraw_QLF);
				else
					OnExport(tDraw);
				end
			end
		end, btnExporter);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ReadECSL();
		end, btnGetECSL);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			if draw.finale_ce == 'Non' or draw.finale_ce == 'No' then
				ReadECPrevious();
			end
		end, btnGetECPrevious);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ReadWCSL();
		end, btnGetWCSL);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ReadFISlist();
		end, btnGetFISlist);
	
	dlgTableau:PopupMenu(menuContext);
	menuContext:Delete();	
end

function ValidetDraw(row_epreuve)
	for i = tDraw:GetNbRows() -1, 0, -1 do
		local code_coureur = tDraw:GetCell('Code_coureur', i);
		local r = tResultat_Paiement:GetIndexRow('Code_coureur', code_coureur);
		if r < 0 then
			tDraw:RemoveRowAt(i);
		-- else
			-- if tResultat_Paiement:GetCellInt('Etat_paiement', r) < 9 then
				-- tDraw:SetCell('Statut', i, 'UF');
			-- else
				-- tDraw:SetCell('Statut', i, 'CF');
			-- end
		end
	end
end

function OnAutoCompleteSearch(evt)
	local str = evt:GetString();
	if config.script_level == 4  then
		local ok = true;
		if not draw.ECSL_done then
			ok = false;
			local msg = traduction(draw.language, "Veuillez charger le fichier ECSL (.csv) en premier.");
			app.GetAuiFrame():MessageBox(msg, traduction(draw.language, "ATTENTION !!"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
		end
		if draw.finale_ce:In('No','Non') and not draw.WCSL_done then
			ok = false;
			local msg = traduction(draw.language, "Veuillez charger le fichier WCSL (.csv) en premier.");
			app.GetAuiFrame():MessageBox(msg, traduction(draw.language, "ATTENTION !!"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
		end
		if ok == false then
			return;
		end
	end
	local str = evt:GetString();
	if string.len(str) == 0  then
		dlgTableau:GetWindowName('code'):SetValue('');
		dlgTableau:GetWindowName('prenom'):SetValue('');
		dlgTableau:GetWindowName('sexe'):SetValue('');
		dlgTableau:GetWindowName('an'):SetValue('');
		dlgTableau:GetWindowName('nation'):SetValue('');
		dlgTableau:GetWindowName('points'):SetValue('');
		dlgTableau:GetWindowName('classement'):SetValue('');
		autoCompleteFrame:Hide();
	else
		local cmd = "SELECT * From Coureur Where Sexe = '"..draw.sexe.."' " ;
		if tonumber(str) then
			-- par n° licence
			cmd = cmd .." AND Code_coureur LIKE 'FIS"..str.."%' ORDER BY Code_coureur ";
		else
			if str:find(',') then
				-- nom + prenom
				local tstr = str:Split(',')
				cmd = cmd .." AND Code_coureur LIKE 'FIS%' AND Nom LIKE '"..tstr[1].."%' AND Prenom LIKE '"..tstr[2].."%' ORDER BY Nom, Prenom ";
			else
				-- nom
				cmd = cmd .." AND Code_coureur LIKE 'FIS%' AND Nom LIKE '"..str.."%' ORDER BY Nom ";
			end
		end
		cmd = cmd.." LIMIT 30";
		base:TableLoad(tCoureur, cmd);
		tCoureur:SetVisibleColumns("Code_coureur, Nom, Prenom, Code_nation");
	
		autoCompleteFrame:SetSearching(true);
	
		autoCompleteFrame:SetTable(tCoureur, 'Nom');
		autoCompleteFrame:ShowBest();

		autoCompleteFrame:SetSearching(false);
	end
end

function OnAutoCompleteSelection(evt)
	local row = evt:GetInt();
	local code_coureur = tCoureur:GetCell('Code_coureur', row);
	dlgTableau:GetWindowName('code'):SetValue(code_coureur)
	dlgTableau:GetWindowName('prenom'):SetValue(tCoureur:GetCell('Prenom', row));
	dlgTableau:GetWindowName('sexe'):SetValue(tCoureur:GetCell('Sexe', row));
	dlgTableau:GetWindowName('an'):SetValue(tCoureur:GetCell('Naissance', row, '%4Y'));
	dlgTableau:GetWindowName('nation'):SetValue(tCoureur:GetCell('Code_nation', row));
	
	draw.trouve_coureur_liste = false;
	local pts, rank, pts_SG, rank_SG = GetRank(code_coureur);
	if pts then
		draw.trouve_coureur_liste = true;
		dlgTableau:GetWindowName('points'):SetValue(pts);
		dlgTableau:GetWindowName('classement'):SetValue(rank);
	end
	dlgTableau:SetFocus();
end

function OnAfficheTableau()
	if not draw.socket then
		parentFrame = wnd.GetParentFrame();
		draw.socket = socketClient.Open(parentFrame, draw.hostname, config.port);
		draw.socket_state = false;
		parentFrame:Bind(eventType.SOCKET, OnSocketLive, draw.socket);
	end
-- Création Dialog 
	draw.label_dialog = traduction(draw.language,'Tableau des coureurs')..' - '..traduction(draw.language,'discipline de la course')..' : '..draw.discipline..' - version '..script_version..' '..traduction(draw.language,'du script')..'  -  '..traduction(draw.language,'course')..' n° '..draw.code_evenement..' - CODEX : '..draw.codex;
	dlgTableau = wnd.CreateDialog(
		{
		width = config.width,
		height = config.height,
		x = config.x,
		y = config.y,
		label=draw.label_dialog, 
		icon='./res/32x32_fis.png'
		});
	
	if config.script_level == 4 then
		dlgTableau:LoadTemplateXML({ 
			xml = './process/dossard_LiveDraw.xml',
			node_name = 'root/panel', 
			node_attr = 'name', 	
			node_value = 'gridCE',
			language = draw.language
		});
	elseif config.script_level == 3 then
			dlgTableau:LoadTemplateXML({ 
				xml = './process/dossard_LiveDraw.xml',
				node_name = 'root/panel', 
				node_attr = 'name', 	
				node_value = 'gridFIS',
				language = draw.language
			});
	elseif config.script_level == 2 then
		dlgTableau:LoadTemplateXML({ 
			xml = './process/dossard_LiveDraw.xml',
			node_name = 'root/panel', 
			node_attr = 'name', 	
			node_value = 'gridtableau';
			language = draw.language
		});
	else
		dlgTableau:LoadTemplateXML({ 
			xml = './process/dossard_LiveDraw.xml',
			node_name = 'root/panel', 
			node_attr = 'name', 	
			node_value = 'gridFIS',
			language = draw.language
		});
	end
	
	draw.timer = timer.Create(dlgTableau);

-- Grid 
	grid_tableau = dlgTableau:GetWindowName('tableau');
	assert(grid_tableau ~= nil)
	BuildTablesDraw();
	local cmd ='Select r.*, rit.* , Repeat(" ",10) Action, Repeat(" ",10) Validation, Concat(Prenom, " ", Nom) Identite, 0 Pris, 0 Dossard_bibo, 0 Exaequo_groupe ';
	cmd = cmd..'From Resultat r ';
	cmd = cmd..'Left Join Resultat_Info_Tirage rit On r.Code_evenement = rit.Code_evenement And r.Code_coureur = rit.Code_coureur ';
	cmd = cmd..'Where r.Code_evenement = '..draw.code_evenement;
	tDraw = base:TableLoad(cmd);
	for i = tDraw:GetNbColumns() -1, 0, -1 do
		local colname = tDraw:GetColumnName(i);
		if colname == 'Code_coureur' then
			tDraw:RemoveColumnAt(i);
		end
		if colname == 'Code_evenement' then
			tDraw:RemoveColumnAt(i);
			break;
		end
	end
	tDraw:SetColumn('Dossard', { label = traduction(draw.language,'Dos.'), width = 4 });
	tDraw:SetColumn('Rang_tirage', { label = traduction(draw.language,'Rang'), width = 5 });
	tDraw:SetColumn('Groupe_tirage', { label = traduction(draw.language,'Groupe'), width = 5 });
	tDraw:SetColumn('Code_coureur', { label = traduction(draw.language,'Code'), width = 10 });
	tDraw:SetColumn('Nom', { label = traduction(draw.language,'Nom'), width = 15 });
	tDraw:SetColumn('Prenom', { label = traduction(draw.language,'Prénom'), width = 12 });
	tDraw:SetColumn('Nation', { label = 'Nat.', width = 5 });
	tDraw:SetColumn('ECSL_points', { label = 'ECSL', width = 6 });
	tDraw:SetColumn('ECSL_rank', { label = 'ECSL Rk', width = 6 });
	tDraw:SetColumn('WCSL_points', { label = 'WCSL', width = 6 });
	tDraw:SetColumn('WCSL_rank', { label = 'WCSL Rk', width = 7 });
	tDraw:SetColumn('ECSL_overall_points', { label = 'OA Pts', width = 6 });
	tDraw:SetColumn('ECSL_overall_rank', { label = 'OA Rk', width = 6 });
	if config.script_level == 2 then
		tDraw:SetColumn('Winner_CC', { label = 'ZK', width = 3 });
	elseif config.script_level == 4 then
		tDraw:SetColumn('Winner_CC', { label = 'COC W.', width = 5 });
	end
	tDraw:SetColumn('FIS_pts', { label = 'Pts '..draw.discipline, width = 6 });
	tDraw:SetColumn('FIS_clt', { label = 'Rk '..draw.discipline, width = 5 });
	tDraw:SetColumn('FIS_VIT_pts', { label = 'Pts SG', width = 6 });
	tDraw:SetColumn('FIS_VIT_clt', { label = 'Rk SG', width = 5 });
	tDraw:SetColumn('Comite', { label = 'C.R.', width = 6 });
	tDraw:SetColumn('Club', { label = 'Club', width = 12 });
	tDraw:SetColumn('Action', { label = traduction(draw.language,'Supp.'), width = 5});
	tDraw:SetColumn('Validation', { label = 'CF/UF', width = 5});
	tDraw:SetColumn('Statut', { label = 'UF/CF', width = 5 });
	tDraw:SetPrimary('Code_evenement, Code_coureur');
	ReplaceTableEnvironnement(tDraw, '_Draw');
	tDraw:OrderBy('Rang_tirage');

	if config.script_level == 4 then
		for i = 0, tDraw:GetNbRows() -1 do
			if tDraw:GetCellInt('ECSL_points', i, -1) < 0 then
				tDraw:SetCellNull('ECSL_rank', i);
				tDraw:SetCellNull('ECSL_points', i);
			end
			if tDraw:GetCellInt('WCSL_points', i, -1) < 0 then
				tDraw:SetCellNull('WCSL_rank', i);
				tDraw:SetCellNull('WCSL_points', i);
			end
			if draw.discipline == 'DH' then
				local code_coureur = tDraw:GetCell('Code_coureur', i);
				if tRankSG[code_coureur] then
					tDraw:SetCell('FIS_VIT_pts', i, tRankSG[code_coureur].Pts);
					tDraw:SetCell('FIS_VIT_clt', i, tRankSG[code_coureur].Rank);
				end
			end
		end
		if not draw.bolVitesse then
			grid_tableau:Set({
				table_base = tDraw,
				columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, ECSL_points, ECSL_rank, WCSL_points, WCSL_rank, ECSL_overall_points, Winner_CC, FIS_pts, FIS_clt, Statut, Action, Validation',
				selection_mode = gridSelectionModes.ROWS,
				-- focus_cell_highlight = true,
				label_tracking = true,
				sortable = true,
				filterable = true,
				enable_editing = true
			});
		else
			if draw.discipline == 'DH' then
				grid_tableau:Set({
					table_base = tDraw,
					columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, ECSL_points, ECSL_rank, WCSL_points, WCSL_rank, ECSL_overall_points, Winner_CC, FIS_pts, FIS_clt, FIS_VIT_pts, FIS_VIT_clt, Statut, Action, Validation',
					selection_mode = gridSelectionModes.ROWS,
					-- focus_cell_highlight = true,
					label_tracking = true,
					sortable = true,
					filterable = true,
					enable_editing = true
				});
			else
				grid_tableau:Set({
					table_base = tDraw,
					columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, ECSL_points, ECSL_rank, WCSL_points, WCSL_rank, ECSL_overall_points, Winner_CC, FIS_pts, FIS_clt, Statut, Action, Validation',
					selection_mode = gridSelectionModes.ROWS,
					-- focus_cell_highlight = true,
					label_tracking = true,
					sortable = true,
					filterable = true,
					enable_editing = true
				});
			end
		end
	else
		if tResultat_Paiement and tResultat_Paiement:GetNbRows() > 0 then
			ValidetDraw(draw.row_epreuve)
		end
		for i = 0, tDraw:GetNbRows() -1 do
			tDraw:SetCellNull('ECSL_points', i);
			tDraw:SetCellNull('ECSL_rank', i);					
			tDraw:SetCellNull('ECSL_overall_points', i);
			tDraw:SetCellNull('ECSL_overall_rank', i);
			tDraw:SetCellNull('WCSL_points', i);
			tDraw:SetCellNull('WCSL_rank', i);
			if config.script_level ~= 2 then
				tDraw:SetCellNull('CC_winner', i);
			else
				if tDraw:GetCell('CC_winner', i):len() == 0 then
					tDraw:SetCellNull('CC_winner', i);
				end
			end
		end
		if config.script_level ~= 2 then
			grid_tableau:Set({
				table_base = tDraw,
				columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, Comite, Club, FIS_pts, FIS_clt, Statut, Action, Validation',
				selection_mode = gridSelectionModes.ROWS,
				-- focus_cell_highlight = true,
				label_tracking = true,
				sortable = true,
				filterable = true,
				enable_editing = true
			});
		else
			grid_tableau:Set({
				table_base = tDraw,
				columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, Comite, Club, FIS_pts, FIS_clt, Winner_CC, Statut, Action, Validation',
				selection_mode = gridSelectionModes.ROWS,
				-- focus_cell_highlight = true,
				label_tracking = true,
				sortable = true,
				filterable = true,
				enable_editing = true
			});
		end
	end

	-- grid_tableau:AddColumnLabel(3);
    grid_tableau:AddRowLabel(1, 48);

-- Initialisation des Controles
	
	tbTableau = dlgTableau:GetWindowName('tbtableau');
	tbTableau:AddStretchableSpace();
	btnSendMessage = tbTableau:AddTool(traduction(draw.language,"Messages"), "./res/32x32_journal.png");
	tbTableau:AddSeparator();
		
	local strLabelButton = traduction(draw.language,"Activation ou Désactivation du Live")..
					"\n"..traduction(draw.language,"RAZ à la FIS")..
					"\n"..traduction(draw.language,"Reset de la connexion à la FIS");
	btnMenuCommande = tbTableau:AddTool(traduction(draw.language,"Commandes"), "./res/chrono32x32_ko.png", strLabelButton);
	tbTableau:AddSeparator();
	strLabelButton = traduction(draw.language,"RAZ des Rangs")..
					"\n"..traduction(draw.language,"RAZ des Groupes")..
					"\n"..traduction(draw.language,"RAZ des deux")..
					"\n"..traduction(draw.language,"RAZ des Dossards")..
					"\n"..traduction(draw.language,"RAZ des Dossards pour les lignes sélectionnées");
	btnMenuRAZ = tbTableau:AddTool(traduction(draw.language,"Menu des RAZ"), "./res/32x32_journal.png", strLabelButton);
	tbTableau:AddSeparator();
	btnOrder = tbTableau:AddTool(traduction(draw.language,"Trier le tableau"), "./res/32x32_bib.png");
	tbTableau:AddSeparator();
	strLabelButton = traduction(draw.language,"Envoi des participants")..
					"\n"..traduction(draw.language,"Envoi du tableau à la FIS")..
					"\n"..traduction(draw.language,"Envoi de tous les dossards")..
					"\n"..traduction(draw.language,"Envoi de la liste de départ");
	btnMenuSend = tbTableau:AddTool(traduction(draw.language,"Menu des Envois"), "./res/32x32_send.png", strLabelButton);
	tbTableau:AddSeparator();
	strLabelButton = traduction(draw.language,"Validation des coureurs filtrés")..
					"\n"..traduction(draw.language,"Validation globale des coureurs")..
					"\n"..traduction(draw.language,"Invalider les coureurs filtrés")..
					"\n"..traduction(draw.language,"Revenir au statut Non Validé");
	btnMenuValider = tbTableau:AddTool(traduction(draw.language,"Menu des Validations"), "./res/32x32_send.png", strLabelButton);
	tbTableau:AddSeparator();
	strLabelButton = traduction(draw.language,"Impression du double tirage du BIBO")..
					"\n"..traduction(draw.language,"Impression du double tirage du groupe 2 en Vitesse")..
					"\n"..traduction(draw.language,"Impression des étiquettes par ordre alphabétique")..
					"\n"..traduction(draw.language,"Impression des étiquettes par Nation")..
					"\n"..traduction(draw.language,"Impression des étiquettes par Points")..
					"\n"..traduction(draw.language,"Impression du tableau des coureurs")..
					"\n"..traduction(draw.language,"Impression des coureurs par Nation")..
					"\n"..traduction(draw.language,"Qualifiés pour les finales")..
					"\n"..traduction(draw.language,"Impression de la feuille de tirage")..
					"\n"..traduction(draw.language,"Impression du TOP ")..config.topx_FIS ..traduction(draw.language," en points FIS")..
					"\n"..traduction(draw.language,"Impression des ZK potentiels par Nation");
	btnMenuPrint = tbTableau:AddTool(traduction(draw.language,"Menu des Impressions"), "./res/32x32_send.png", strLabelButton);
	tbTableau:AddSeparator();
	strLabelButton = traduction(draw.language,"Double tirage à la mêlée du BIBO")..
					"\n"..traduction(draw.language,"Double tirage à la mêlée du Groupe 1 Tech")..
					"\n"..traduction(draw.language,"Double tirage à la mêlée du Groupe 2 Tech")..
					"\n"..traduction(draw.language,"Tirage des dossards restants (avec points)")..
					"\n"..traduction(draw.language,"Double tirage à la mêlée (sans points)")..
					"\n"..traduction(draw.language,"Double tirage des exaequos")..
					"\n"..traduction(draw.language,"Double tirage à la mêlée des coureurs du groupe 2 en Vitesse")..
					"\n"..traduction(draw.language,"Vers la page FIS de la course")..
					"\n"..traduction(draw.language,"Décaler les rangs de tirage de +1")..
					"\n"..traduction(draw.language,"Décaler les rangs de tirage de -1")..
					"\n"..traduction(draw.language,"Décaler les groupes de tirage de +1")..
					"\n"..traduction(draw.language,"Décaler les groupes de tirage de -1")..
					"\n"..traduction(draw.language,"Exporter le tableau (fichier csv)")..
					"\n"..traduction(draw.language,"Charger un fichier csv ECSL")..
					"\n"..traduction(draw.language,"Charger un fichier csv Cup Standing Saison n-1")..
					"\n"..traduction(draw.language,"Charger un fichier csv Cup Standing Saison N (450+)")..
					"\n"..traduction(draw.language,"Charger un fichier csv WCSL")..
					"\n"..traduction(draw.language,"Charger une liste FIS (csv)")..
					"\n"..traduction(draw.language,"Vers la page FIS des documents alpins")..
					"\n"..traduction(draw.language,"Aide / ranking en CE");
	btnMenuOutils = tbTableau:AddTool(traduction(draw.language,"Menu des Outils"), "./res/32x32_tools.png",strLabelButton);
	tbTableau:AddSeparator();
	btnClose = tbTableau:AddTool(traduction(draw.language,"Quitter"), "./res/32x32_exit.png");
	tbTableau:AddStretchableSpace();
 	tbTableau:Realize();

	tbTableau:EnableTool(btnMenuSend:GetId(), draw.state);
	tbTableau:EnableTool(btnSendMessage:GetId(), draw.state);
	
	ChecktDraw();
	if config.script_level == 4 then
		if nodelivedraw:HasAttribute('ECSL_'..draw.code_evenement) then
			local path = nodelivedraw:GetAttribute('ECSL_'..draw.code_evenement);
			if app.FileExists(path) then
				ChargeECSL(path);
			else
				nodelivedraw:DeleteAttribute('ECSL_'..draw.code_evenement);
				config.doc:SaveFile();
			end
		end
		if nodelivedraw:HasAttribute('WCSL_'..draw.code_evenement) then
			local path = nodelivedraw:GetAttribute('WCSL_'..draw.code_evenement);
			if app.FileExists(path) then
				ChargeWCSL(path);
			else
				nodelivedraw:DeleteAttribute('WCSL_'..draw.code_evenement);
				config.doc:SaveFile();
			end
		end
		DoRazColOverAll(0);
		-- DoRazColOverAll(1);
		if nodelivedraw:HasAttribute('EC_PREVIOUS_'..draw.sexe) then
			local path = nodelivedraw:GetAttribute('EC_PREVIOUS_'..draw.sexe);
			if app.FileExists(path) then
				ChargeECPrevious(path);
			else
				nodelivedraw:DeleteAttribute('EC_PREVIOUS_'..draw.sexe);
				config.doc:SaveFile();
			end
		end
	end
	
	RefreshCounterSequence();
	-- Prise des Evenements (Bind)
	grid_tableau:Bind(eventType.GRID_EDITOR_SHOWN, OnGridShown);
	grid_tableau:Bind(eventType.GRID_CELL_CONTEXT, OnCellContext);
	grid_tableau:Bind(eventType.GRID_CELL_CHANGED, OnCellChanged);
	grid_tableau:Bind(eventType.GRID_SELECT_CELL, OnCellSelected);
	
	dlgTableau:Bind(eventType.TIMER, OnTimerRunning, draw.timer);
	draw.timer:Start(480000);	-- toutes les 8 minutes (8x60x1000ms) on envoie une commande keepalive

	-- dlgTableau:Bind(eventType.MENU, OnResetSocket, btn_reset_socket);
	dlgTableau:Bind(eventType.MENU, AfficheMenuCommande, btnMenuCommande);
	dlgTableau:Bind(eventType.MENU, AfficheMenuRAZ, btnMenuRAZ);
	dlgTableau:Bind(eventType.MENU, AfficheMenuSend, btnMenuSend);
	dlgTableau:Bind(eventType.MENU, AfficheMenuValider, btnMenuValider);
	dlgTableau:Bind(eventType.MENU, AfficheMenuPrint, btnMenuPrint);
	dlgTableau:Bind(eventType.MENU, AfficheMenuOutils, btnMenuOutils);
	
	dlgTableau:Bind(eventType.MENU, OnSendMessage, btnSendMessage);

	dlgTableau:Bind(eventType.MENU, OnAide, btnAideCE);
	
	searchctrl = dlgTableau:GetWindowName('nom');
	if searchctrl ~= nil then
		searchctrl:SetDescriptiveText(traduction(draw.language, 'recherche par Nom, Prénom ou Code FIS'));
		autoCompleteFrame = wnd.CreateAutoCompleteFrame({
			parent = searchctrl, 
			label = "AutoCompleteFrame - Test", 
		});
		autoCompleteFrame:Bind(eventType.AUTOCOMPLETE_SEARCH, OnAutoCompleteSearch);
		searchctrl:Bind(eventType.AUTOCOMPLETE_SELECTION, OnAutoCompleteSelection);
	end

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local cmd = 'Delete From Resultat_Info_Bibo Where Abs(Code_evenement) = '..draw.code_evenement;
			base:Query(cmd);
			draw.skip_question = false;
			draw.btnOrder = true;
			OnOrder();
			draw.btnOrder = false;
		end, btnOrder);

	dlgTableau:Bind(eventType.GRID_FILTER_CHANGED, 
		function(evt)
			if grid_tableau:GetTableSrc():GetNbRows() == grid_tableau:GetTableView():GetNbRows() then
				RefreshGrid(true);	-- on est sur la source
			else
				RefreshGrid(false);	-- on est sur la vue
			end
		end
		, dlgTableau:GetWindowName('tableau'));
		
	dlgTableau:Bind(eventType.BUTTON, 
		function(evt)
			local fiscode = dlgTableau:GetWindowName('code'):GetValue();
			local r = tDraw:GetIndexRow('Code_coureur', fiscode);
			if r > -1 then
				local msg = traduction(draw.language, 'Ce coureur est déjà présent dans la course !!');
				app.GetAuiFrame():MessageBox(msg, traduction(draw.language, "ATTENTION !!"), msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				dlgTableau:GetWindowName('code'):SetValue('');
				dlgTableau:GetWindowName('groupe'):SetValue('');
				dlgTableau:GetWindowName('nom'):SetValue('');
				dlgTableau:GetWindowName('prenom'):SetValue('');
				dlgTableau:GetWindowName('an'):SetValue('');
				dlgTableau:GetWindowName('nation'):SetValue('');
				dlgTableau:GetWindowName('points'):SetValue('');
				dlgTableau:GetWindowName('classement'):SetValue('');
				return;
			end

			for i = 0, tDraw:GetNbRows() -1 do
				tDraw:SetCellNull('Rang_tirage', i);
				tDraw:SetCellNull('Groupe_tirage', i);
				tDraw:SetCellNull('Dossard', i);
				tDraw:SetCellNull('Reserve', i);
			end
			RefreshGrid();
			if dlgTableau:GetWindowName('code'):GetValue():len() > 3 then
				OnAjouterCoureur();
			end
		end
		, dlgTableau:GetWindowName('ajouter'));
		
	dlgTableau:Bind(eventType.MENU, 
		function(evt) 
			OnClose();
			dlgTableau:EndModal(idButton.CANCEL);
		 end,  btnClose);

	dlgTableau:Fit();
	dlgTableau:ShowModal();
end

function SetLabelConfig()
	if dlgConfig:GetWindowName('label_host_name') then
		dlgConfig:GetWindowName('label_host_name'):SetLabel(traduction(draw.language, "Cible")..' : ');
	end
	if dlgConfig:GetWindowName('label_fis_pwd') then
		dlgConfig:GetWindowName('label_fis_pwd'):SetLabel(traduction(draw.language, "Mot de passe")..' : ');
	end
	if dlgConfig:GetWindowName('label_finale') then
		dlgConfig:GetWindowName('label_finale'):SetLabel(traduction(draw.language, "Est-ce la Finale des Coupes d'Europe")..' ? ');
	end
	if dlgConfig:GetWindowName('label_date') then
		dlgConfig:GetWindowName('label_date'):SetLabel(traduction(draw.language, "Date du tirage des dossards")..' : ');
 	end
	if dlgConfig:GetWindowName('label_heure') then
		dlgConfig:GetWindowName('label_heure'):SetLabel(traduction(draw.language, "Heure du tirage des dossards")..' : ');
 	end
	if dlgConfig:GetWindowName('label_langage') then
		dlgConfig:GetWindowName('label_langage'):SetLabel(traduction(draw.language, "Langue")..' : ');
	end
	if draw.sexe == 'F' then
		draw.lngsexe = traduction(draw.language, 'Dames');
	else
		draw.lngsexe = traduction(draw.language, 'Hommes');
	end
	local titre = traduction(draw.language, 'Tirage des Dossards en ligne sur le site de la FIS')..'\n'..traduction(draw.language,'Course')..' : '..tEvenement:GetCell('Nom', 0)..' - Discipline : '..draw.discipline..' - '..draw.lngsexe..'\nDate : '..tEpreuve:GetCell('Date_epreuve', draw.row_epreuve)..' - CODEX : '..draw.codex;
	dlgConfig:GetWindowName('race_name'):SetValue(titre);
	if dlgConfig:GetWindowName('finale_ce') then
		dlgConfig:GetWindowName('finale_ce'):Clear();
		dlgConfig:GetWindowName('finale_ce'):Append(traduction(draw.language, "Oui"));
		dlgConfig:GetWindowName('finale_ce'):Append(traduction(draw.language, "Non"));
		dlgConfig:GetWindowName('finale_ce'):SetValue(draw.finale_ce);
	end
	if app.GetVersion() > '6.0h' then 
		local tb = dlgConfig:GetWindowName('tbconfig');
		tb:FindById(config_btnSave:GetId()):SetLabel(traduction(draw.language, "Sauvegarder"));
		tb:FindById(config_btnSave:GetId()):SetShortHelp(traduction(draw.language, "Sauvegarder"));
		tb:FindById(config_btnSOS:GetId()):SetLabel(traduction(draw.language, "Mode d'emploi du script"));
		tb:FindById(config_btnSOS:GetId()):SetShortHelp(traduction(draw.language, "Mode d'emploi du script"));
		tb:FindById(config_btnClose:GetId()):SetLabel(traduction(draw.language, "Quitter"));
		tb:FindById(config_btnClose:GetId()):SetShortHelp(traduction(draw.language, "Quitter"));
	end
	dlgConfig:FitInside();
end

function soustraireUnJour(dateStr)
    -- Découper la date en jour, mois, année
    local jour, mois, annee = dateStr:match("(%d+)/(%d+)/(%d+)")
    jour = tonumber(jour)
    mois = tonumber(mois)
    annee = tonumber(annee)

    -- Convertir en timestamp
    local timestamp = os.time({year = annee, month = mois, day = jour, hour = 0})

    -- Soustraire un jour (86400 secondes)
    timestamp = timestamp - 86400

    -- Convertir le timestamp en date lisible
    local nouvelleDate = os.date("%Y/%m/%d", timestamp)

    return nouvelleDate
end

function OnAffichedlgConfig()
	dlgConfig = wnd.CreateDialog({
		
		width = config.width,
		height = config.height,
		x = config.x,
		y = config.y,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		label='Informations de connexion - version du script : '..script_version , 
		icon='./res/32x32_fis.png'
		});
	
	dlgConfig:LoadTemplateXML({ 
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 
		discipline = draw.discipline,
		node_value = 'config',
		CE = draw.CE
		});

	-- Toolbar Principale ...
	local tbconfig = dlgConfig:GetWindowName('tbconfig');
	tbconfig:AddStretchableSpace();
	config_btnSave = tbconfig:AddTool(traduction(draw.language, "Enregistrer"), "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	config_btnSOS = tbconfig:AddTool(traduction(draw.language, "Mode d'emploi du sript"), "./res/32x32_sos.png");
	tbconfig:AddSeparator();
	config_btnClose = tbconfig:AddTool(traduction(draw.language, "Quitter"), "./res/32x32_exit.png");
	tbconfig:AddSeparator();
	
	config_btnBackOffice = tbconfig:AddTool("Back Office", "./res/32x32_configuration.png");
	tbconfig:AddStretchableSpace();

	tbconfig:Realize();
	SetLabelConfig();
	local message = app.GetAuiMessage();
	dlgConfig:GetWindowName('codex'):SetValue(draw.codex);
	dlgConfig:GetWindowName('fis_hostname'):SetValue('live.fisski.com');
	dlgConfig:GetWindowName('fis_port'):SetValue(config.port);
	dlgConfig:GetWindowName('fis_pwd'):SetValue(draw.pwd);
	dlgConfig:GetWindowName('language'):Clear();
	dlgConfig:GetWindowName('language'):Append('Français');
	dlgConfig:GetWindowName('language'):Append('English');
	
	if config.script_level == 4 then 
		dlgConfig:GetWindowName('debug'):Clear();
		dlgConfig:GetWindowName('debug'):Append(traduction(draw.language,'Oui'));
		dlgConfig:GetWindowName('debug'):Append(traduction(draw.language,'Non'));
		dlgConfig:GetWindowName('debug'):SetSelection(1);
	end

	if nodelivedraw:HasAttribute('Date_'..draw.code_evenement) then
		local node_date = nodelivedraw:GetAttribute('Date_'..draw.code_evenement);
		dlgConfig:GetWindowName('draw_date'):SetValue(node_date);
	else
		local date_tirage = soustraireUnJour(tEpreuve:GetCell('Date_epreuve', 0));
		dlgConfig:GetWindowName('draw_date'):SetValue(date_tirage);
	end
	for i = 1, #tLanguage do
		if tLanguage[i].Code == draw.language then
			dlgConfig:GetWindowName('language'):SetValue(tLanguage[i].Libelle);
		end
	end
	if draw.finale_ce:len() == 0 then
		draw.finale_ce = traduction(draw.language,'Non');
	end
	if nodelivedraw:HasAttribute('Time_'..draw.code_evenement) then
		local node_time = nodelivedraw:GetAttribute('Time_'..draw.code_evenement);
		dlgConfig:GetWindowName('draw_time'):SetValue(node_time);
		-- dlgConfig:GetWindowName('draw_time'):SetValue(valeur);
	else
		dlgConfig:GetWindowName('draw_time'):SetValue('--:--');
	end
	
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt)
			local idx = dlgConfig:GetWindowName('language'):GetSelection();
			if idx >= 0 then
				draw.language = tLanguage[idx + 1].Code;
				nodelivedraw:ChangeAttribute('language', draw.language);
				SetLabelConfig();
			end
		end, dlgConfig:GetWindowName('language'))

	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			draw.pwd = dlgConfig:GetWindowName('fis_pwd'):GetValue();
			draw.time = dlgConfig:GetWindowName('draw_time'):GetValue();
			config.port = dlgConfig:GetWindowName('fis_port'):GetValue();
			draw.language = 'fr';
			if dlgConfig:GetWindowName('language'):GetValue() == 'English' then
				draw.language = 'en';
			end 
			if dlgConfig:GetWindowName('finale_ce') then
				draw.finale_ce = dlgConfig:GetWindowName('finale_ce'):GetValue();
			else
				draw.finale_ce = 'Non';
			end
			local filename = './process/liveDrawPwd.txt';
			local f = io.open(filename, 'w')
			f:write(draw.pwd);
			f:close();
			nodelivedraw:ChangeAttribute('port', config.port);
			nodelivedraw:ChangeAttribute('send', 0);
			nodelivedraw:ChangeAttribute('ack', 0);
			if nodelivedraw:HasAttribute('language') then
				nodelivedraw:ChangeAttribute('language', draw.language);
			else
				nodelivedraw:AddAttribute('language', draw.language);
			end
			local arDate = dlgConfig:GetWindowName('draw_date'):GetValue();
			draw.date = arDate.year..'/'..string.format('%02d',arDate.month)..'/'..string.format('%02d', arDate.day);
			if nodelivedraw:HasAttribute('Date_'..draw.code_evenement) then
				nodelivedraw:ChangeAttribute('Date_'..draw.code_evenement, draw.date);
			else
				nodelivedraw:AddAttribute('Date_'..draw.code_evenement, draw.date);
			end
			if nodelivedraw:HasAttribute('Time_'..draw.code_evenement) then
				nodelivedraw:ChangeAttribute('Time_'..draw.code_evenement, draw.time);
			else
				nodelivedraw:AddAttribute('Time_'..draw.code_evenement, draw.time);
			end
			if nodelivedraw:HasAttribute('Finale_ce_'..draw.code_evenement) then
				nodelivedraw:ChangeAttribute('Finale_ce_'..draw.code_evenement, draw.finale_ce);
			else
				nodelivedraw:AddAttribute('Finale_ce_'..draw.code_evenement, draw.finale_ce);
			end
			if config.script_level == 4 then
				draw.debug = dlgConfig:GetWindowName('debug'):GetSelection();
			end
			config.doc:SaveFile();
			-- adv.Alert('draw.debug = '..draw.debug);
		
			dlgConfig:EndModal(idButton.OK) 
		end, config_btnSave); 
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			OnAfficheBackOffice();
		 end,  config_btnBackOffice);

	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			if config.doc then
				config.doc:SaveFile();
			end
			OnClose();
			dlgConfig:EndModal(idButton.CANCEL) 
		 end,  config_btnClose);
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			OnAide()
		 end,  config_btnSOS);

	if dlgConfig:ShowModal() == idButton.OK then
		local cmd = "Update Resultat Set Reserve = NULL, Groupe = NULL Where Code_evenement = "..draw.code_evenement;
		base:Query(cmd);
		OnAfficheTableau();
	end
end

function subtractDays(timestamp, days)
    local secondsInDay = 86400 -- 60 secondes * 60 minutes * 24 heures
    local adjustedTimestamp = timestamp - (days * secondsInDay)
    return adjustedTimestamp
end

function main(params_c)
	math.randomseed(os.time() + math.floor(os.clock() * 1000000))  -- initialisation pour math.random

	-- Brûler un nombre aléatoire d’itérations
	for i = 1, math.random(1, 5) do 
		math.random()
	end
	config = {};
	draw = {};
	tTableauCoureur = {};
	params = {};
	draw.code_evenement = params_c.code_evenement or -1;
	if draw.code_evenement < 0 then
		return;
	end
	if draw.code_evenement > 10500 then
		app.GetAuiFrame():MessageBox(
			"Vous ne pouvez pas lancer ce script sur une course du webFFS !!", 
			"Information !!!",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
			);
		return false;
	end
	config.width = display:GetSize().width;
	config.height = display:GetSize().height - 50;
	config.x = 0;
	config.y = 0;
	script_version = "2027.02"; 
	-- Ouverture Document XML 
	draw.finale_ce = 'Non';
	config.doc = app.GetXML();
	config.docRoot = config.doc:GetRoot();
	nodelivedraw = config.doc:FindFirst('main/livedraw');
	if not nodelivedraw then
		nodelivedraw = xmlNode.Create(config.docRoot, xmlType.ELEMENT_NODE, "livedraw");
		nodelivedraw:AddAttribute('port', config.port);
		nodelivedraw:AddAttribute('pwd', '');
		nodelivedraw:AddAttribute('language', 'fr');
		draw.language = 'fr';
		nodelivedraw:AddAttribute('Finale_ce_'..draw.code_evenement, 'Non');
		draw.finale_ce = 'Non';
	else
		draw.sequence_send = tonumber(nodelivedraw:GetAttribute('send', 0)) or 0;;
		draw.sequence_ack = tonumber(nodelivedraw:GetAttribute('ack', 0)) or 0;
		draw.sequence_last_send = draw.sequence_send;
		draw.language = nodelivedraw:GetAttribute('language', 'fr');
		draw.finale_ce = nodelivedraw:GetAttribute('Finale_ce_'..draw.code_evenement, 'Non');
		if draw.finale_ce:len() == 0 then
			draw.finale_ce = traduction(draw.language, 'Non');
		end
	end
	local imgfile = './res/40x16_dbl_coche.png';
	if not app.FileExists(imgfile) then
		app.GetAuiFrame():MessageBox(
			traduction(draw.language, "Vous devez télécharger une image supplémentaire.\nLe script va se fermer automatiquement."), 
			traduction(draw.language, "Téléchargement d'une image supplémentaire"),
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
			local reponse = app.AutoUpdateResource('https://agilsport.fr/bta_alpin/UpdateScript.zip');
			return true;
	end
	if app.GetVersion() >= '6.0' then 
		-- vérification de l'existence d'une version plus récente du script.
		-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2
		indice_return = 1;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	else
		app.GetAuiFrame():MessageBox(
			traduction(draw.language, "Vous devez mettre à jour le logiciel avec\nla dernière version stable (téléchargement -> Logiciel)."), 
			traduction(draw.language, "Mise à jour du logiciel"),
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
		return true;
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
	draw.paiement = true;
	draw.hostname = 'live.fisski.com';
	draw.method = 'socket';
	draw.ajouter_code = '';
	draw.debug = 0;
	draw.btnOrder = false;
	draw.orderbyCE = 'Rang_tirage';
	draw.orderbyFIS = 'Rang_tirage';
	draw.directory = app.GetPath()..'/live_draw/';
	if not app.DirExists(draw.directory) then
		app.Mkdir(draw.directory);
	end
	base = base or sqlBase.Clone();
	draw.base_reload=false;
	tResultat_Info_Tirage = base:GetTable('Resultat_Info_Tirage');
	if tResultat_Info_Tirage == nil then
		CreateTableResultat_Info_Tirage();
		draw.base_reload=true;
	else
		local cmd = '';
		if tResultat_Info_Tirage:GetIndexColumn("Dossard") >= 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage DROP COLUMN Dossard";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("Statut") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN Statut CHAR(2) NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("TG") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN TG CHAR(10) NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("Racer_info") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN Racer_info CHAR(10) NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("Pts_info") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN Pts_info CHAR(3) NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("FIS_VIT_pts") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN FIS_VIT_pts DOUBLE NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("FIS_VIT_clt") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN FIS_VIT_clt INT NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("ECSL_30") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN ECSL_30 INT NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("ECSL_overall_points_0") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN ECSL_overall_points_0 INT NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("ECSL_overall_rank_0") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN ECSL_overall_rank_0 INT NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("ECSL_overall_points_n") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN ECSL_overall_points_n INT NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
		if tResultat_Info_Tirage:GetIndexColumn("ECSL_overall_rank_n") < 0 then
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN ECSL_overall_rank_n INT NULL";
			base:Query(cmd);
			draw.base_reload=true;
		end
	end
	tResultat_Info_Bibo = base:GetTable('Resultat_Info_Bibo');
	if tResultat_Info_Bibo == nil then
		CreateTableResultat_Info_Bibo();
		draw.base_reload = true;
	end
	if draw.base_reload == true then
		app.GetAuiFrame():MessageBox(
			traduction(draw.language, "La base de donnée a nécessité la modification d'une table'.\nLe script va se fermer automatiquement.\nVous devrez quitter complètement skiFFS et relancer le programme."), 
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
			base:Reload();
			return true;
	end

	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..draw.code_evenement);
	draw.code_entite = tEvenement:GetCell("Code_entite",0);
	draw.code_activite = tEvenement:GetCell("Code_activite",0);
	if draw.code_activite ~= 'ALP' or draw.code_entite ~= 'FIS' then
		local msg = traduction(draw.language, "L'environnement ne permet pas le tirage en ligne des dossards !!");
		app.GetAuiFrame():MessageBox(msg, traduction(draw.language, "ATTENTION !!"), msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
		return;
	end
	
	tResultat = base:GetTable('Resultat');
	tResultat_Paiement = base:GetTable('Resultat_Paiement');
	tEpreuve = base:GetTable('Epreuve');
	tPistes = base:GetTable('Pistes');
	tNation = base:GetTable('Nation');
	tCoureur = base:GetTable('Coureur');
	tClassement_Coureur = base:GetTable('Classement_Coureur');
	tListe = base:GetTable('Liste');
	tCategorie = base:GetTable('Categorie');
	tEpreuve_Alpine_Manche = base:GetTable('Epreuve_Alpine_Manche');
	tResultat_Info_Tirage = base:GetTable('Resultat_Info_Tirage');
	tResultat_Info_Bibo = base:GetTable('Resultat_Info_Bibo');
	
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..draw.code_evenement);
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..draw.code_evenement);
	base:TableLoad(tEpreuve_Alpine_Manche, 'Select * From Epreuve_Alpine_Manche Where Code_evenement = '..draw.code_evenement);
	draw.code_piste = tEpreuve_Alpine_Manche:GetCellInt('Code_piste', 0);
	base:TableLoad(tPistes, "Select * From Pistes Where Code_activite = 'ALP' And Matricule = "..draw.code_piste);
	base:TableLoad(tNation, "Select * From Nation Where Code = 'AIN'");
	if tNation:GetNbRows() == 0 then
		base:Query("INSERT INTO Nation (Code, Libelle) VALUES ('AIN', 'INDIVIDUAL NEUTRAL ATHLETE')");
	end

	-- création des tables pour le double tirage des dossards
	tTableTirage1 = sqlTable.Create('_TableTirage1');
	tTableTirage1:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	tTableTirage1:AddColumn({ name = 'Aleatoire', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage1, '_TableTirage1');
	
	draw.code_liste = tEvenement:GetCellInt("Code_liste", 0)
	draw.code_regroupement = tEpreuve:GetCell('Code_regroupement', 0);
	draw.groupe_mini_exeaquo = 3;
	if draw.code_regroupement == 'CE' then
		config.script_level = 4;
	elseif draw.code_regroupement == 'F' then
		config.script_level = 3;
		if tResultat_Paiement == nil then
			CreateResultatPaiement();
			app.GetAuiFrame():MessageBox(
				"La base de donnée a nécessité l'ajout d'une table'.\nLe script va se fermer automatiquement.\nVous devrez quitter complètement skiFFS et relancer le programme.", 
				msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
				return true;
		end
	elseif draw.code_regroupement == 'NCM/J' then
		config.script_level = 2;
	else
		if tResultat_Paiement == nil then
			CreateResultatPaiement();
			app.GetAuiFrame():MessageBox(
				"La base de donnée a nécessité l'ajout d'une table'.\nLe script va se fermer automatiquement.\nVous devrez quitter complètement skiFFS et relancer le programme.", 
				msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
				return true;
		end
		config.script_level = 1;
		draw.groupe_mini_exeaquo = 2;
	end
		
	tLanguage = {};
	table.insert(tLanguage, {Code = 'fr', Libelle = 'Français'});
	table.insert(tLanguage, {Code = 'en', Libelle = 'English'});

	draw.code_saison = tEvenement:GetCell("Code_saison", 0);
	draw.row_epreuve = 0;
	if tResultat_Paiement then
		local cmd = 'Select * From Resultat_Paiement Where Code_evenement = '..draw.code_evenement..' And Code_coureur In(Select Code_coureur From Resultat Where Code_evenement = '..draw.code_evenement..')';
		base:TableLoad(tResultat_Paiement, cmd);
		if tResultat_Paiement:GetNbRows() > 0 then
			if tEpreuve:GetNbRows() > 1 then
				GetEpreuve();
				local filter = "$(Epreuve_selection"..(draw.row_epreuve + 1).."):In('X')";
				tResultat_Paiement:Filter(filter, true);
			end
		end
	end
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where code_evenement = '..draw.code_evenement);
	draw.discipline = tEpreuve:GetCell('Code_discipline', draw.row_epreuve);
	draw.niveau = tEpreuve:GetCell('Code_niveau', draw.row_epreuve);
	draw.bolVitesse = false;
	if draw.discipline:In('DH','TRA','SG') then
		draw.bolVitesse = true;
	end
	draw.sexe = tEpreuve:GetCell('Sexe', draw.row_epreuve);
	local filter = "$(Sexe):In('"..draw.sexe.."')";
	tResultat:Filter(filter, true);
	draw.date_epreuve = tEpreuve:GetCell('Date_epreuve', draw.row_epreuve, "%4Y/%2M/%2D");
	draw.date_jour = os.date("%Y/%m/%d");
	draw.bolChargerCsv = true;
	if draw.date_jour > draw.date_epreuve then
		draw.bolChargerCsv = false;
	end
	params.evenementNom = tEvenement:GetCell('Nom', 0)..' - '..tEpreuve:GetCell('Code_discipline', draw.row_epreuve)..' - '..draw.sexe;
	draw.code_grille_categorie = tEpreuve:GetCell("Code_grille_categorie", draw.row_epreuve);
	draw.codex = string.sub(tEpreuve:GetCell("Fichier_transfert", draw.row_epreuve),4);
	draw.codex = draw.codex:Split('%.');
	draw.codex = draw.codex[1];
	draw.web = 'http://live.fis-ski.com/lv-al'..draw.codex..'.htm';
	draw.code_manche = 1;
	draw.type_classement = 'IA'..tEpreuve:GetCell('Code_discipline', draw.row_epreuve);
	xml_tri_default = app.GetPath()..'/liveDraw_tri.xml';
	if not app.FileExists(xml_tri_default) then
		CreateXmlTriDefault(xml_tri_default);
	end
	local doc = xmlDocument.Create(xml_tri_default);
	nodeName = 'root/CoupeEurope';
	node = doc:FindFirst(nodeName);
	config.posit_450 = tonumber(node:GetAttribute('Posit_450')) or 16;
	config.posit_COC = tonumber(node:GetAttribute('Posit_COC')) or 31;
	config.prendre_ECSL = tonumber(node:GetAttribute('Prendre_ECSL')) or 45;
	config.clt_WCSL = tonumber(node:GetAttribute('Clt_WCSL')) or 30;
	config.qlf_Finale = tonumber(node:GetAttribute('Qlf_Finale')) or 45;
	config.topx_FIS = tonumber(node:GetAttribute('Topx_FIS')) or 75;
	if config.script_level == 4 then
		draw.tClefTri = {};
		node = node:GetChildren();
		local order = 0;
		while node ~= nil do
			order = order + 1;
			local groupe = node:GetName();
			local orderby = node:GetNodeContent();
			local ordre = tonumber(node:GetAttribute('Order')) or order;
			table.insert(draw.tClefTri, {Groupe = groupe, OrderBy = orderby, Order = ordre});
			node = node:GetNext();
		end
		--SortGroupes(draw.tClefTri, {'Order'});
		table.sort(draw.tClefTri, 
			function (u,v)
				return u['Order'] < v['Order'];
			end)
	elseif config.script_level == 2 then
		nodeName = 'root/WJC/ZK';
		node = doc:FindFirst(nodeName);
		if draw.sexe == 'F' then
			draw.wjc_clt_maxi = tonumber(node:GetAttribute('F')) or 400;
		else
			draw.wjc_clt_maxi = tonumber(node:GetAttribute('M')) or 500;
		end
		draw.wjc_discipline = node:GetNodeContent();
		if draw.wjc_discipline:len() == 0 then
			draw.wjc_discipline = "'SL','GS', 'DH'";
		end
	end
	if tEpreuve:GetCell("Sexe", draw.row_epreuve) == "M" then
		config.port = '1550';
	else
		config.port = '1551';
	end
	local pwdfile = './process/liveDrawPwd.txt';
	if app.FileExists(pwdfile) then
		local f = io.open(pwdfile, 'r')
		for lines in f:lines() do
			draw.pwd = lines;
		end
		io.close(f);
	end
	if nodelivedraw:HasAttribute('board_status_'..draw.code_evenement) then
		draw.board_status = nodelivedraw:GetAttribute('board_status_'..draw.code_evenement)
	else
		nodelivedraw:AddAttribute('board_status_'..draw.code_evenement, 'particiants');
		draw.board_status = participants;
	end
	if nodelivedraw:HasAttribute('language') then
		draw.language = nodelivedraw:GetAttribute('language');
		draw.init_language = draw.language;
	else
		nodelivedraw:AddAttribute('language', 'fr');
		draw.language = 'fr';
	end
	config.doc:SaveFile();
	bolSendDrawOrder = Eval(draw.board_status, 'board');
	
	-- on nettoie skiFFS.xml
	-- Get the current Unix timestamp
    
	local date_jour = os.date("%Y-%m-%d");
	local date_epreuve = tEpreuve:GetCell('Date_epreuve', draw.row_epreuve, "%4Y-%2M-%2D");
	local currentTimestamp = os.time();
	local beforeTimeStamp = subtractDays(currentTimestamp, 10);
	local attribute = nodelivedraw:GetAttributes();
	local tCodeSupprimer = {};
	local tNodeSupprimer = {};
	while attribute ~= nil do
		local name = attribute:GetName();
		if string.find(name,'Date_') then
			local tname = name:Split('_');
			local delete_code = tname[2] or '';
			local date_str = attribute:GetValue();
			local year, month, day = date_str:match("(%d+)%/(%d+)%/(%d+)");
			year = tonumber(year) or 0;
			month = tonumber(month) or 0;
			day = tonumber(day) or 0;
			local timestamp_lu = os.time({year = year, month = month, day = day})
			if timestamp_lu <= beforeTimeStamp then
				table.insert(tCodeSupprimer, '_'..delete_code);
			end
		end
		attribute = attribute:GetNext();
	end
	attribute = nodelivedraw:GetAttributes();
	while attribute ~= nil do
		local name = attribute:GetName();
		for i = 1, #tCodeSupprimer do
			if string.find(name, tCodeSupprimer[i]) then
				table.insert(tNodeSupprimer, name);
			end
		end
		attribute = attribute:GetNext();
	end
	for i = 1, #tNodeSupprimer do
		nodelivedraw:DeleteAttribute(tNodeSupprimer[i]);
	end
	config.doc:SaveFile();
	draw.sequence_ack = draw.sequence_ack or 0;
	draw.sequence_send = draw.sequence_send or 0;
	draw.targetName = draw.hostname..':'..config.port;
	draw.web = 'live.fis-ski.com/lv-'..string.lower(string.sub(draw.code_activite,1,2))..draw.codex..'.htm';
	draw.state = false;
	draw.double_tirage_bibo = false;
	draw.tModifs_tableau = {};
	draw.raz_sequence = false;
	
	draw.CE = 'N';
	if config.script_level == 4 then
		draw.CE = 'O';
	end
	OnAffichedlgConfig();
	if tDraw then
		tDraw = nil;
	end
	return;
end
