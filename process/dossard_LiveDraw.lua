-- LIVE Draw par Philippe Guérindon

dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
--[[
Coupes d'Europe :
groupe 1 ECSL de la discipline : de 1 à 15 (ou plus) triés par ECSL_points et FIS_pts
groupe 2 Si plus de 450 pts en EC la saison dernière de 16 à x triés par ECSL_overall_points, ECSL_points et FIS_pts
groupe 2 on met en plus dans ce groupe les coureurs de la WC dans les 30 de la WCSL de la discipline. On départage selon les pts ECSL sinon les pts FIS
groupe 4 On continue avec les Pts de la ECSL jusqu'à en avoir 30 pris au titre de la ECSL
groupe 5 Cette série est interrompue si on a un vainqueur d'une autre Coupe continentale qui par systématiquement en 31 ème position.
groupe 6 La série éventuellement interrompue des ECSL reprend jusqu'à en avoir 30.
	s'il n'y a pas assez de coureurs ayant des points ECSL, on complète le groupe avec les meilleurs points FIS JUSQU'AU rang 30
Groupe 7 On poursuit selon les points FIS.

grid:Filter() = on réapplique le filtre avec la table sourse Src
table:FindColumnIndex(colname) -> retourne l'indice de la colonne visible pour la grille
table:FindColumnIndex(indice) -> indice numérique retourne l'indice de la colonne visible pour la grille

]]

function GetMenuName()
	return "Tirage en ligne des dossards sur le site de la FIS";
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

function OnTimerRunning(evt);
	local nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeKeepalive = xmlNode.Create(nodeRoot, xmlType.ELEMENT_NODE, "keepalive");
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('sequence'):SetValue('Demande de maintien de la connexion');
end

function OnExport()
	tDraw:OrderBy('Dossard, Rang_tirage');
	local filename = app.GetPath()..app.GetPathSeparator()..'tmp'..app.GetPathSeparator()..string.sub(tEpreuve:GetCell('Fichier_transfert',0), 4)..'_racers.csv';
	local f = io.open(filename, 'w')
	if f == nil then 
		return
	end
	local chaine = 'Code;CodeFIS;Bib;Name;Surname;Identity;Nation;Club;FIS Points\n'
	f:write(chaine);
	for i = 0, tDraw:GetNbRows() -1 do
		local pts = string.gsub(tDraw:GetCell('FIS_pts', i),"%.",",");
		chaine = string.sub(tDraw:GetCell('Code_coureur', i), 4);
		chaine = chaine..';'..tDraw:GetCell('Code_coureur', i);
		chaine = chaine..';'..tDraw:GetCell('Dossard', i);
		chaine = chaine..';'..tDraw:GetCell('Nom', i);
		chaine = chaine..';'..tDraw:GetCell('Prenom', i);
		chaine = chaine..';'..tDraw:GetCell('Nom', i)..' '..tDraw:GetCell('Prenom', i);
		chaine = chaine..';'..tDraw:GetCell('Nation', i);
		chaine = chaine..';'..tDraw:GetCell('Club', i);
		chaine = chaine..';'..pts..'\n';
		f:write(chaine);
	end
	f:close();
	local msg = 'Les coureurs ont été exportés dans le fichier\n'..filename..' qui se trouve dans\nle répertoire tmp de skiFFS.';
	app.GetAuiFrame():MessageBox(msg, "Exportation des coureurs ", msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION);
end

function OnClose()

	if draw.socket ~= nil then
		draw.socket:Close();
		Error("CONNEXION SERVEUR FIS KO ...");
	end
	
	if draw.doc ~= nil then
		draw.doc:SaveFile();
	end
	
	if draw.timer ~= nil then
		draw.timer:Delete();
	end
	
	if grid_coureur then
		local mgr = app.GetAuiManager();
		mgr:DeletePane(panel_coureur);
		panel_coureur = nil;
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

function ChargeECSL(filename)
	draw.tECSL = {};
	lines = {};
	for line in io.lines(filename) do 
		lines[#lines + 1] = line
	end
	local cols = lines[1]:Split(',');
	for i = 1, #cols do
		if cols[i] == draw.discipline..'points' then
			idxcolPts = i;
		end
		if cols[i] == draw.discipline..'pos' then
			idxcolClt = i;
		end
	end
	for i = 0, tDraw:GetNbRows() -1 do
		tDraw:SetCellNull('ECSL_points', i);
		tDraw:SetCellNull('ECSL_rank', i);
	end
	for i = 2, #lines do
		local cols = lines[i]:Split(',');
		local fiscode = 'FIS'..cols[1];
		draw.tECSL[fiscode] = {};
		draw.tECSL[fiscode].Point = 0;
		draw.tECSL[fiscode].Clt = 0;
		if idxcolPts > 0 and idxcolClt > 0 then
			local pts = tonumber(cols[idxcolPts]) or 0;
			local clt = tonumber(cols[idxcolClt]) or 0;
			if pts > 0 and clt > 0 then
				draw.tECSL[fiscode].Point = pts;
				draw.tECSL[fiscode].Clt = clt;
			end
		end
		local r = tDraw:GetIndexRow('Code_coureur', fiscode);
		if r and r >= 0 then
			if draw.tECSL[fiscode].Point > 0 then
				tDraw:SetCell('ECSL_points', r, draw.tECSL[fiscode].Point);
				tDraw:SetCell('ECSL_rank', r, draw.tECSL[fiscode].Clt);
			end
		end
	end
	RefreshGrid();
end

function ReadECSL()
	local filename = '';
	local idxcolPts = nil;
	local idxcolClt = nil;
	local idxcolPtsAll = nil;
	local idxcolCltAll = nil;
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
		draw.doc:SaveFile()
	end
	if filename:len() > 0 then
		ChargeECSL(filename);
	end
end

function ChargeWCSL(filename)
	draw.tWCSL = {};
	lines = {};
	for line in io.lines(filename) do 
		lines[#lines + 1] = line
	end
	local cols = lines[1]:Split(',');
	for i = 1, #cols do
		if cols[i] == draw.discipline..'points' then
			idxcolPts = i;
		end
		if cols[i] == draw.discipline..'pos' then
			idxcolClt = i;
		end
	end
	if idxcolPts and idxcolClt then
		for i = 0, tDraw:GetNbRows() -1 do
			tDraw:SetCellNull('WCSL_points', i);
			tDraw:SetCellNull('WCSL_rank', i);					
		end
		for i = 2, #lines do
			local cols = lines[i]:Split(',');
			local fiscode = 'FIS'..cols[1];
			draw.tWCSL[fiscode] = {};
			draw.tWCSL[fiscode].Pts = tonumber(cols[idxcolPts]) or 0;
			draw.tWCSL[fiscode].Clt = tonumber(cols[idxcolClt]) or 0;
			local r = tDraw:GetIndexRow('Code_coureur', fiscode);
			if r and r >= 0 then
				if draw.tWCSL[fiscode].Pts > 0 and draw.tWCSL[fiscode].Clt <= 30 then
					tDraw:SetCell('WCSL_points', r, draw.tWCSL[fiscode].Pts);
					tDraw:SetCell('WCSL_rank', r, draw.tWCSL[fiscode].Clt);
				end
			end
		end
		RefreshGrid();
	end
end

function ReadWCSL()
	draw.tWCSL = {};
	local filename = '';
	local idxcolPts = nil;
	local idxcolClt = nil;
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
		draw.doc:SaveFile()
	end
	if filename:len() > 0 then
		ChargeWCSL(filename);
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

function OnLiveState(evt)
	local tb = dlgTableau:GetWindowName('tbtableau');

	if tb ~= nil then
		if draw.state == true then
			draw.state = false;
			tb:SetToolNormalBitmap(btnMenuCommande, './res/chrono32x32_ko.png');
		else
			draw.state = true;
			tb:SetToolNormalBitmap(btnMenuCommande, './res/chrono32x32_ok.png');
		end
		tb:EnableTool(btnMenuSend:GetId(), draw.state);
		tb:EnableTool(btnSendMessage:GetId(), draw.state);
		menuCommande:Enable(btnClear:GetId(), draw.state) ;
		menuCommande:Enable(btn_reset_socket:GetId(), draw.state) ;
	end
end

function RefreshCounterSequence()
	draw.sequence_ack = draw.sequence_ack or 0;
	draw.sequence_send = draw.sequence_send or 0;
	dlgTableau:GetWindowName('sequence'):SetValue('Trame '..draw.sequence_ack..' / '..draw.sequence_send);
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
		Info("la dernière séquence envoyée n'a pas encore été acquittée");
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
	local msg = "Confirmation de la réinitialisation de la connexion :\n\n"..
		"La connexion avec la FIS sera interronpue puis réinitialisée.\n"..
		"Vous devrez éventuellent renvoyer les informations manquantes à la FIS.";
	if dlgTableau:MessageBox(
		msg, 
		"Reset de la connexion avec la FIS", 
		msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION
	) ~= msgBoxStyle.YES then
		return;
	end

	Info('Demande de réinitialisation ....');
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
	draw.socket = socketClient.Open(parentFrame, draw.hostname, draw.port);

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
-- groupe 1 ECSL de la discipline : de 1 à 15 (ou plus)
-- groupe 2 Si plus de 450 pts en EC la saison dernière de 16 à x
-- groupe 3 on met ici les coureurs de la WC dans les 30 de la WCSL de la discipline. On départage selon les pts ECSL sinon les pts WCSL
-- groupe 4 On continue avec les Pts de la ECSL jusqu'à en avoir 30 pris au titre de la ECSL
-- groupe 4 Cette série est interrompue si on a un vainqueur d'une autre Coupe continentale qui par systématiquement en 31 ème position.
-- groupe 5 La série interrompue reprend jusqu'à en avoir 30.
-- Groupe 6 On poursuit selon les points FIS.
	local msg = "le ranking en Coupe d'Europe (technique) se fait de la façon suivante :\n"..
				"Groupe 1-2 : les 15 premiers de la dernière European Cup Starting List produite par la FIS dans la discipline courue. "..
				"Ce groupe 1 sera divisé en deux sous groupe (1 à 7 et 8 à 15). Ces sous groupes sont augmentés en cas d'exaequo.\n"..
				"Groupe 3 : Ceux qui auront marqué au moins 450 points en EC toutes disciplines confondues dans la saison précédente ou celle en cours.\n"..
				"Groupe 4 : les coureurs dans les 30 premiers World Cup dans la discipline (au jour j).\n"..
				"           en cas d'exaequos, ils seront départagés par les Pts ECSL puis les points FIS.\n"..
				"Groupe 5 : On continue dans l'ordre de la Starting List jusqu'à avoir 30 coureurs listés.\n"..
				"           Cette série peut être interrompue au rang 31 par un ou plusieurs vainqueurs des autres\n"..
				"           Coupes Continentales dans la discipline courue. Vous mettrez le chiffre 1 dans 'Winner CC'.\n"..
				"           La série interrompue reprend ensuite pour en avoir 30 sur la ECSL\n"..
				"           Les coureurs pris au titre des points 'Overall' comptent parmi ces 30.\n"..
				"           là encore, en cas d'exaequos, ils seront départagés par les Pts ECSL et les points FIS.\n"..
				"           S'il y en a moins de 30, on prendra dans ce groupe les viennent ensuite par ordre de leurs points FIS.\n"..
				"Groupe 6 : Le ranking se poursuit selon les points FIS.\n"..
				"			Les exaequos dans les coureurs 'points FIS' sont départagés par double tirage.\n\n"..
				"Vous pouvez charger depuis les outils les fichiers csv du classement ECSL et WCSL pris sur le site de la FIS '\n"..
				"dans votre Member Section.Les points ECSL et WCSL seront alors placés automatiquement dans le tableau.\n"..
				"Vous devrez télécharger également le fichiers : 'Special starting positions at COC events' se trouvant dans 'ALPINE Documents' (CC winners dans la discipline et Pts OverAll de la saison n-1).";
	dlgTableau:MessageBox(msg, "Aide sur le ranking en CE.", msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION);
end

function OnDecaler(row, bolVersLeBas, bolGroupe)
	local plus = 1;
	if bolVersLeBas == false then
		plus = -1;
	end
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

function BuildTableTirage(bib_first, last_row_groupe_bibo)
	params.tableDossards1 = {};
	for row = 0, last_row_groupe_bibo  do
		table.insert(params.tableDossards1, bib_first + row);
	end
	params.tableDossards1 = Shuffle(params.tableDossards1, false);
	tTableTirage1:RemoveAllRows();
	for row = 0, last_row_groupe_bibo do
		local new_row1 = tTableTirage1:AddRow();
		tTableTirage1:SetCell('Row', new_row1, row+1);
	end
	tTableTirage1:OrderBy('Row');
	tTableTirage1:OrderRandom('Row');
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

function OnDecodeJson(groupe)
	params.Draw = groupe;
	local cmd = 'Select * From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement..' And Groupe = '..groupe;
	base:TableLoad(tResultat_Info_Bibo, cmd);
	tResultat_Info_Bibo:OrderBy('Groupe, Ligne');
	tDrawG6 = tDraw:Copy();
	ReplaceTableEnvironnement(tDrawG6, '_DrawG6');
	tDrawG6:RemoveAllRows();
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

function OnPrintDoubleTirage(groupe)
	if draw.print_alone then
		params.tableDossards1, params.tableDossards2 = OnDecodeJsonBibo(draw.code_evenement, groupe);
	else
		OnEncodeJsonBibo(draw.code_evenement, groupe);
		params.tableDossards1, params.tableDossards2 = OnDecodeJsonBibo(draw.code_evenement, groupe);
	end
	if groupe == 1 then
		params.nb_groupe1 = #params.tableDossards1;
		report = wnd.LoadTemplateReportXML({
			xml = './process/dossard_DoubleTirage.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = 'Edition du tirage au sort du BIBO (2 pages)',
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
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 1, Version = scrip_version, NbGroupe1 = 0, Entite = draw.code_entite }
		});
	else
		if not report then
			report = wnd.LoadTemplateReportXML({
				xml = './process/dossard_DoubleTirage.xml',
				node_name = 'root/panel',
				node_attr = 'id',
				node_value = 'print',
				title = 'Edition du tirage au sort du BIBO (2 pages)',
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
				params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 1, Version = scrip_version, NbGroupe1 = 0, Entite = draw.code_entite}
			});
		end
		editor = report:GetEditor();
		editor:PageBreak(); -- Saut de Page entre les 2 éditions ...
		wnd.LoadTemplateReportXML({
			xml = './process/dossard_DoubleTirage.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = 'Edition du tirage au sort du BIBO (2 pages)',
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
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 2, Version = scrip_version, NbGroupe1 = params.nb_groupe1, Entite = draw.code_entite}
		});
	end
end

function OnPrintEtiquettes(orderby)
	tDraw:OrderBy(orderby);
	tEtiquette = tDraw:Copy();
	ReplaceTableEnvironnement(tEtiquette, '_Etiquette');
	-- Creation du Report
	local estce = 0;
	local row_separation = nil;
	if draw.bolEstCE then
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
	if draw.bolEstCE then
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
		node_value = 'print_tableau',
		base = base,
		body = tDraw,
		params = {Orderby = orderby, EstCE = estce, EstVitesse = vitesse}
	});
	
end

function OnPrintNation()
	-- Creation du Report
	local estce = 0;
	if draw.bolEstCE then
		estce = 1;
	end
	report = wnd.LoadTemplateReportXML({
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'parti_factorise',
		base = base,
		body = tDraw,
		params = {EstCE = estce, EstVitesse = vitesse, Rupture = 'Nation'}
		});
	
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
		body = tDraw,
		margin_first_top = 250,
		margin_first_left = 80,
		margin_first_right = 80,
		margin_first_bottom = 160,
		margin_top = 245,
		margin_left = 80, 
		margin_right = 80,
		margin_bottom = 160,
		paper_orientation = 'portrait',
		params = {EstCE = estce, EstVitesse = vitesse, Rupture = 'Nation'}
		});
	
end

function OnPrintBibo(groupe)
	ChecktDraw();
	tDraw:OrderBy('Rang_tirage');
	local last_group = tDraw:GetCellInt('Groupe_tirage', tDraw:GetNbRows() -1);
	tDraw_Copy = tDraw:Copy();
	ReplaceTableEnvironnement(tDraw_Copy, 'Draw_copy');
	if draw.bolEstCE == true then
		tDraw_Copy = tDraw:Copy();
		tDraw_Copy:OrderBy('Rang_tirage');
		for i = tDraw_Copy:GetNbRows() -1, 0, -1 do
			if not draw.bolVitesse then
				if tDraw_Copy:GetCellInt('Groupe_tirage', i) > 2 then
					tDraw_Copy:RemoveRowAt(i);
				end
			else
				local groupe_tirage_30 = tDraw_Copy:GetCellInt('Groupe_tirage', 29)
				if tDraw_Copy:GetCellInt('Groupe_tirage', i) > groupe_tirage_30 then
					tDraw_Copy:RemoveRowAt(i);
				end
			end
		end
	else
		tDraw_Copy = tDraw:Copy();
		tDraw_Copy:OrderBy('FIS_pts');
		for i = tDraw_Copy:GetNbRows() -1, 0, -1 do
			if not draw.bolVitesse then
				if draw.code_niveau ~= 'NC' then
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
	local estCE = draw.bolEstCE and 1 or 0;
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
		params = {Evenement_nom = tEvenement:GetCell('Nom', 0), Version = scrip_version, NbGroupe1 = draw.nb_groupe_1, EstCE = estCE}
	});
end

function OnPrintTop75()
	local tDraw_Copy = tDraw:Copy();
	tDraw_Copy:OrderBy('Nation, FIS_pts');
	local fis_pts = -1;
	local fis_clt = 10000;
	for i = tDraw_Copy:GetNbRows() -1, 0, -1 do
		local fis_pts = tDraw_Copy:GetCellDouble('FIS_pts', i, -1);
		if fis_pts >= 0 then
			fis_clt = tDraw_Copy:GetCellInt('FIS_clt', i, -1);
			if fis_clt > 75 then
				tDraw_Copy:RemoveRowAt(i);
			end
		else
			tDraw_Copy:RemoveRowAt(i);
		end
	end
	local title = "TOP 75 / "..draw.discipline.." FIS Points ordered by ";
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
		params = {Title = title ,Evenement_nom = tEvenement:GetCell('Nom', 0), EstCE = estce, EstVitesse = vitesse, Rupture = 'Nation', Version = scrip_version}
	});
	
end

function OnOrder()
	if draw.bolInit then
		draw.build_table = true;
		draw.skip_question = true;
	end
	if not draw.skip_question then
		draw.build_table = false;
		local msg = "Voulez-vous reconstruire les groupes et les rangs de départ ?\n\n"..
					"Cliquer sur Oui pour tout reconstruire\n"..
					"ou cliquer sur Non pour garder les données stockées.";
		if dlgTableau:MessageBox(
			msg, "Tri du tableau des coureurs", 
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
			if not draw.bolEstCE then 
				SetuptDraw();
			end
		else
			SetuptDraw();
		end
	end
	tDraw:OrderBy('Rang_tirage, ECSL_points DESC, ECSL_overall_points DESC, WCSL_points DESC ,Winner_CC, FIS_pts');

	-- draw.build_table = false;
	-- grid_tableau:SetSortingColumn('Rang_tirage');
	draw.bolInit = false;
	SetRangEgal();
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
	local msg = "Confirmation RAZ ?\n\n"..
				"Toutes les données envoyées précédemment seront effacées du serveur !!";
	if dlgTableau:MessageBox(
		msg, 
		"Information Remise à zéro", 
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
		label = "Envoi Message",
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
	local btnSend = tb:AddTool("Envoyer", "./res/32x32_send_green.png");
	tb:AddStretchableSpace();
	local btnClose = tb:AddTool("Fermer", "./res/32x32_close.png");
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
	local nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeRaceEvent = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceevent");
	tDraw:OrderBy('Rang_tirage');
	for i = 0, tDraw:GetNbRows() -1 do
		local dossard = tDraw:GetCellInt('Dossard', i);
		if bolRAZ == true or dossard == 0 then
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
	dlgTableau:GetWindowName('info'):SetValue('Dossards renvoyés.');
end

function CommandValiderCoureurs(statut)
	local msg = "Voulez-vous valider en bloc tous les coureurs ?";
	if statut == 'UF' then
		msg = "Voulez-vous invalider en bloc tous les coureurs ?";
	end
	if dlgTableau:MessageBox(
		msg, "Validation des coureurs", 
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
	dlgTableau:GetWindowName('info'):SetValue(tDraw:GetNbRows()..' coureurs modifiés.');
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
		dlgTableau:GetWindowName('info'):SetValue(tDraw:GetCell('Nom', row)..' '..tDraw:GetCell('Prenom', row)..' confirmé.');
	else
		CommandRenvoyerDossards(false);
		dlgTableau:GetWindowName('info'):SetValue(tDraw:GetCell('Nom', row)..' '..tDraw:GetCell('Prenom', row)..' non confirmé.');
	end
end

function CheckDossardAfter()
	local ligne = -1;
	for i = draw.row_selected, tDraw:GetNbRows() -1 do
		if tDraw:GetCellInt('Dossard', i) > 0 then
			ligne = i + 1;
			break;
		end
	end
	return ligne;
end

function SetDossardsAvailable()
	for i = 0, tDraw:GetNbRows() -1 do
		if tDraw:GetCellInt('Groupe_tirage', i) > 1 then
			break;
		end
		if tDraw:GetCell('Dossard', i):len() == 0 then
			return false;
		end
	end
	draw.tDossardsAvailable = {};
	for i = 1, 40 do
		table.insert(draw.tDossardsAvailable, {Dossard = i, Pris = 0});
	end
	for i = 0, 40 do
		local dossard = tDraw:GetCell('Dossard', i);
		if dossard:len() > 0 then
			local indice = tonumber(dossard) ;
			if draw.tDossardsAvailable[indice] then
				draw.tDossardsAvailable[indice].Pris = 1;
			end
		end
	end
	return true;
end

function ChecktDraw()
	draw.bolExisteDossard = false;
	draw.bolExisteSansPoint = false;
	draw.statut = 'CF';
	tDraw:OrderBy('Rang_tirage');
	for i = 0, tDraw:GetNbRows() -1 do
		tDraw:SetCell('Dossard_bibo', i, 0);
		local dossard = tDraw:GetCellInt('Dossard', i);
		if tDraw:GetCellInt('Groupe_tirage', i) == 1 then
			tDraw:SetCell('Dossard_bibo', i, 1);
		end
		if tDraw:GetCell('Winner_CC', i):len() > 0 then
			tDraw:SetCell('Winner_CC', i, '1')
		end
		local pts, rank, pts_SG, rank_SG = GetRank(tDraw:GetCell('Code_coureur', i));
		if pts and pts >= 0 then
			tDraw:SetCell('FIS_pts', i, pts);
			tDraw:SetCell('FIS_clt', i, rank);
			if pts_SG and pts_SG >= 0 then
				tDraw:SetCell('FIS_SG_pts', i, pts_SG);
				tDraw:SetCell('FIS_SG_clt', i, rank_SG);
			end
		end
		if tDraw:GetCellDouble('FIS_pts', i, -1) < 0 then
			draw.bolExisteSansPoint = true
		end
		local rang_tirage = tDraw:GetCellInt('Rang_tirage', i);
		if tDraw:GetCell('Statut', i) ~= 'CF' then
			draw.statut = 'UF';
		end
		if draw.bolEstCE or draw.code_niveau == 'NC' then
			if not draw.bolVitesse then
				if tDraw:GetCellInt('Groupe_tirage', i) == 2 then
					tDraw:SetCell('Dossard_bibo', i, 1);
				end
			end
		end
		if dossard > 0 then
			draw.bolExisteDossard = true;
			if tDraw:GetCellInt('Dossard_bibo', i) == 1 then
				draw.bolTirageBiboFait = true;
			end
			if tDraw:GetCell('TG', i) == 'tDrawG6' then
				draw.bolTirageAvecPointFait = true;
			end
			if tDraw:GetCell('TG', i) == 'PtsFISNull' then
				draw.bolTirageSansPointFait = true;
			end
		end
	end
	if draw.bolExisteSansPoint == false then
		bolTirageSansPointFait = true;
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
		local nodeGroup = xmlNode.Create(nodeDrawGroup, xmlType.ELEMENT_NODE, "group", math.abs(tDraw:GetCellInt('Groupe_tirage', i)));
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
	dlgTableau:GetWindowName('info'):SetValue("Ordre des coureurs dans le tableau envoyé");
end

function SetRangEgal()
	tDraw:OrderBy('TG, Rang_tirage');
	draw.RangEgal = {};
	draw.ECSL_point = {};
	draw.PtsFis = {};
	draw.bolWinner = false;
	draw.bol99 = false;
	-- tDrawG1 = tDraw:Copy();	-- dans les 15 de la ECSL
	-- tDrawG2 = tDraw:Copy();	-- les 450 - 200 pts
	-- tDrawG3 = tDraw:Copy();	-- dans les 30 de la WC
	-- tDrawG4 = tDraw:Copy();	-- les winner des CC
	-- tDrawG5 = tDraw:Copy();	-- tous les ECSL 
	-- tDrawG6 = tDraw:Copy();	-- tous les pts FIS 
	for i = 0, tDraw:GetNbRows()-1 do
		tDraw:SetCellNull('Racer_info', i);
		tDraw:SetCellNull('Pts_info', i);
	end
	local clef_encours = nil;
	local rang1_ptsnull = nil;
	local rangs_nul = '';
	for i = 0, tDraw:GetNbRows()-1 do
		if tDraw:GetCell('Winner_CC', i):len() > 0 then
			draw.bolWinner = true;
		end
		local ecsl_points = tDraw:GetCell('ECSL_points', i);
		local rang = tDraw:GetCellInt('Rang_tirage', i);
		local fis_pts = tDraw:GetCellDouble('FIS_pts', i, -1);
		local tg = tDraw:GetCell('TG', i);
		local clef_lue = tg;
		if clef_lue ~= 'tDrawG1'and clef_lue ~= 'Groupe1' then
			if clef_lue == 'tDrawG4' or clef_lue == 'tDrawG5' then
				clef_lue = clef_lue..'_'..ecsl_points..'_'..fis_pts;
			else 
				clef_lue = clef_lue..'_'..fis_pts;
			end
			-- adv.Alert('clef_encours = '..tostring(clef_encours)..', clef_lue = '..tostring(clef_lue));
			if clef_encours and clef_encours == clef_lue then
				-- adv.Alert('--- clef_encours = clef_lue');
				tDraw:SetCell('Racer_info', i, '==');
				tDraw:SetCell('Racer_info', i-1, '==');
				tDraw:SetCell('Pts_info', i, '=');
				tDraw:SetCell('Pts_info', i-1, '=');
			end
			clef_encours = clef_lue;
		end
	end
	base:TableBulkUpdate(tDraw, 'Racer_info, Pts_info', 'Resultat_Info_Tirage');
	tDraw:OrderBy('Rang_tirage');
end

function SetRangsPtsNull()
	tDraw:OrderBy('Rang_tirage');
	draw.tRangsPtsNull = {};
	draw.PtsFis = {};
	local rang1_ptsnull = nil;
	local rangs_nul = '';
	for i = 0, tDraw:GetNbRows()-1 do
		local rang = tDraw:GetCellInt('Rang_tirage', i);
		local fis_pts = tDraw:GetCellDouble('FIS_pts', i, -1);
		if fis_pts < 0 then
			if not rang1_ptsnull then
				rang1_ptsnull = rang;
				rangs_nul = rang;
			else
				rangs_nul = rangs_nul..','..rang;
			end
			table.insert(draw.tRangsPtsNull, {Rangs = rangs_nul});
		end
	end
end

-- envoi de l'heure de départ
function CommandSendScheduled(run)
	if tEpreuve:GetCell('Code_activite', 0) == 'ALP' then
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
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "year", tEpreuve:GetCell("Date_epreuve", 0, '%4Y'));	
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "month", tEpreuve:GetCell("Date_epreuve", 0, '%2M'));	
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "day", tEpreuve:GetCell("Date_epreuve", 0, '%2D'));	
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "cettime", stringtime);
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "loctime", stringtime);
			-- Regroupement <scheduled> et <command>
			local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
			nodeRoot:AddChild(nodeCommand);
			CreateXML(nodeRoot);
			dlgTableau:GetWindowName('info'):SetValue("Tag scheduled envoyé pour la manche 1 = "..stringtime);
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
				"Tous les dossards n'ont pas été attribués",
				"Erreur sur les dossards", 
				msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
			break;
		end
	end

	if bolOK == false then
		return;
	end
	CommandClear();
	CommandRaceInfo(false);
	-- Génération des balises 
	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeStartList = nil;
	nodeStartList = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "startlist");
	nodeStartList:AddAttribute("runno",activerun);			
	
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
	local nodeActiveRun = xmlNode.Create(nodeCommand, xmlNodeType.ELEMENT_NODE, "activerun");
	nodeActiveRun:AddAttribute("no",activerun);
	
	-- Regroupement <startlist> et <command>
	
	-- si live.target == 'FIS', le nodeRoot a déjà été créé fans le raceinfo;
	nodeRoot:AddChild(nodeStartList);
	nodeRoot:AddChild(nodeCommand);
	CreateXML(nodeRoot);
	
	dlgTableau:GetWindowName('info'):SetValue("Liste de départ manche 1 envoyée");
	
	-- dossard de rang 1 au départ
	local nodeRaceEvent = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "raceevent");
	local nodeNextStart = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "nextstart");			
	nodeNextStart:AddAttribute("bib", 1);
	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeRaceEvent);
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue("dossard 1 au départ envoyé");
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
	local rangs_egalite = {};
	local egalite = false;
	for i = 0, tDraw:GetNbRows()-1 do
		rangs_egalite = rangs_egalite or {};
		local racer_info = tDraw:GetCell('Racer_info', i);
		local pts_info = tDraw:GetCell('Pts_info', i);
		local nom = tDraw:GetCell('Nom', i);
		local prenom = tDraw:GetCell('Prenom', i);
		local nation = tDraw:GetCell('Nation', i);
		if not draw.bolEstCE then
			if not bolSendDrawOrder then	-- envoi des participants
				if nation == 'FRA' then
					nom = tDraw:GetCell('Comite', i)..' - '..nom;
				end
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
		local winner_points = tDraw:GetCell('Winner_CC', i);
		local winner_rank = '';
		if winner_points:len() > 0 then
			winner_points = "1";
			winner_rank = 1;
		end
		local fis_pts = tDraw:GetCell('FIS_pts', i);
		local fis_clt = tDraw:GetCell('FIS_clt', i);
		if fis_pts:len() == 0 then 
			fis_pts = ''; 
			fis_clt = '';
		-- elseif if fis_pts == '0.0' then 
			-- fis_pts = '0'; 
		end

		local tStandings = {};
		local tData = {};
		if draw.bolEstCE then
			table.insert(tData, {rank = ecsl_rank, points = ecsl_points, event = draw.discipline, category = 'ECSL', pointsinfo = pts_info});
			table.insert(tData, {rank = ecsl_overall_rank, points = ecsl_overall_points, event = '', category = 'EC OA 450+', pointsinfo = pts_info});
			table.insert(tData, {rank = wcsl_rank, points = wcsl_points, event = draw.discipline, category = 'WCSL Top 30', pointsinfo = pts_info});
			table.insert(tData, {rank = winner_rank, points = winner_points, event = draw.discipline, category = 'COC WINNER', pointsinfo = pts_info});
			table.insert(tData, {rank = fis_clt, points = fis_pts, event = draw.discipline, category = 'FIS pts', pointsinfo = pts_info});
		else
			table.insert(tData, {rank = fis_clt, points = fis_pts, event = draw.discipline, category = 'FIS pts'});
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
	dlgTableau:GetWindowName('info'):SetValue("Tableau des coureurs envoyé");
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
	dlgTableau:GetWindowName('info'):SetValue("Demande d'effacement envoyé");
end

function CommandPhaseD()
	local nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeCommand = xmlNode.Create(nodeRoot, xmlType.ELEMENT_NODE, "command");
	local nodeActive = xmlNode.Create(nodeCommand, xmlType.ELEMENT_NODE, "active");
	nodeActive:AddAttribute("phase", "D");
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue("Phase D envoyé");
end

function CommandRaceInfo(bolPhased)
	local phased = false;
	if bolPhased == true then
		phased = true;
	end
	local run = 1;
	-- Génération des balises 
	local nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	local nodeRaceinfo = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceinfo");
	local category = tEpreuve:GetCell("Code_regroupement", 0);
	if category == 'CE' then
		category = 'EC';
	end
	if category == 'F' then
		category = 'NC';
	end
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "event", tEvenement:GetCell('Nom',0));	
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "name", tEpreuve:GetCell("Code_discipline", 0)..' '..tEpreuve:GetCell("Sexe", 0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "slope", tPistes:GetCell('Nom_piste',0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "discipline", tEpreuve:GetCell("Code_discipline", 0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "gender", tEpreuve:GetCell("Sexe", 0));			
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
	local x, y = string.find(heure_depart, "%D");  -- tout ce qui n'est pas un chiffre
	if x ~= nil then  -- position du séparateur
		heure = string.sub(heure_depart, 1, x-1);
		heure = string.format("%02d", tonumber(heure) or 0);
		minute = string.sub(heure_depart, x+1);
		minute = string.format("%02d", tonumber(minute) or 0);
	end
	if phased == true then
		nodePhase = xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "phase");			
		nodePhase:AddAttribute("no", 'D');			
		
		-- nodePhase Childs ...
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "discipline", tEpreuve:GetCell('Code_discipline', 0));	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "start", start);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "finish", finish);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "height", start - finish);	
		if length > 0 then
			xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "length", length);	
		end
		local gates = tEpreuve_Alpine_Manche:GetCellInt("Nombre_de_portes",0);
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "gates", gates);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "turninggates", turninggates);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "year", tEpreuve:GetCell("Date_epreuve", 0, '%4Y'));	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "month", tEpreuve:GetCell("Date_epreuve", 0, '%2M'));	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "day", tEpreuve:GetCell("Date_epreuve", 0, '%2D'));	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "hour", heure);	
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "minute", minute);	
		
		local nodeRacedef = xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "racedef");	
		xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "draworder", '');	
		xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "drawgroup", '');	
		xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "drawstatus", '');	
		xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "drawbib", '');	
		local tInfo = {legend = {abbreviation = {{description = 'ECSL points in '..draw.discipline, title = 'ECSL'}, {description = 'At least 450 Cup points overall', title = 'EC OA 450+'}, {description = 'Winner of COC in '..draw.discipline, title = 'COC WINNER'}, {description = 'Within the top 30 of the WCSL in '..draw.discipline, title = 'WCSL TOP 30'}, {description = 'Ranked by '..draw.discipline..' FIS points', title = 'FIS Points'}}}};
		if draw.bolEstCE == false then
			tInfo = {legend = {abbreviation = {{description = 'Ranked by FIS points', title = 'FIS Points'}}}};
		end
		local jsontxt = table.ToStringJSON(tInfo, false);
		
		local nodedrawinfoJSON = xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, 'drawinfoJSON');	
		xmlNode.Create(nodedrawinfoJSON, xmlType.CDATA_SECTION_NODE,'', jsontxt);	
	else
		for run = 1, 1 do
			-- run x 
			nodeRun = xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "run");			
			nodeRun:AddAttribute("no", run);			
			
			-- nodeRun Childs ...
			if tEpreuve:GetCell('Code_activite', 0) == 'ALP' then
				if tEpreuve_Alpine_Manche:GetNbRows() >= run then
					xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "discipline", tEpreuve:GetCell('Code_discipline', 0));	
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
					xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "year", tEpreuve:GetCell("Date_epreuve", 0, '%4Y'));	
					xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "month", tEpreuve:GetCell("Date_epreuve", 0, '%2M'));	
					xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "day", tEpreuve:GetCell("Date_epreuve", 0, '%2D'));	
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
	end

	nodeRoot:AddChild(nodeRaceinfo);
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue("Informations de course envoyées");
end

function CreateXML(nodeRoot)
	if draw.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return false;
	end
	if not draw.socket_state then
		dlgTableau:GetWindowName('info'):SetValue('Pas de connexion à la FIS !!!');
		Error('Pas de connexion à la FIS !!!');
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
		draw.message = draw.sequence_ack..' / '..draw.sequence_send;
		
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
	local msg = "Confirmation de l'envoi du tableau à la FIS.";
	local txtdialog = "Envoi du tableau à la FIS";
	if not bolSendDrawOrder then
		msg = "Confirmation de l'envoi de la liste des participants à la FIS.";
		txtdialog = "Envoi des participants à la FIS";
	end
	if dlgTableau:MessageBox(
		msg, txtdialog, 
		msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION
	) ~= msgBoxStyle.YES then
		return;
	end
	SetRangEgal();
	-- CommandClear();
	CommandRaceInfo(true);
	CommandPhaseD();
	CommandSendList(bolSendDrawOrder);
	CommandSendOrder(bolSendDrawOrder);
	if bolSendDrawOrder and draw.state == true then
		local msg = "Voulez-vous en plus envoyer les dossards à la FIS ?";
		if dlgTableau:MessageBox(
			msg, 
			"Envoi des dossards à la FIS", 
			msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
		) == msgBoxStyle.NO then
			return;
		end
		CommandRenvoyerDossards(false);
	end
end

function OnRAZData(colonne)
	local txt = '';
	if colonne == 'Groupe_tirage' then
		txt = 'groupes de tirage'
	elseif colonne == 'Rang_tirage' then
		txt = 'rangs de tirage'
	elseif colonne == 'Dossard' then
		txt = 'dossards'
		draw.bolTirageBiboFait = false;
		draw.bolTirageAvecPointFait = false;
		draw.bolTirageSansPointFait = false;
	elseif colonne == 'Dossard_bibo' then
		draw.bolTirageBiboFait = false;
		txt = 'dossards du BIBO'
	elseif colonne == 'All' then
		txt = 'rangs et les groupes de tirage'
	elseif colonne == 'Tout' then
		draw.bolTirageBiboFait = false;
		draw.bolTirageAvecPointFait = false;
		draw.bolTirageSansPointFait = false;
		txt = 'rangs et les groupes de tirage ainsi que les dossards'
	end
	local reponse = nil;
	if not draw.skip_question then
		local msg = "Confirmation RAZ ?\n\n"..
					"Les "..txt.." seront effacées.";
		reponse = dlgTableau:MessageBox(
			msg, 
			"Information Remise à zéro", 
			msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING)
		if reponse == msgBoxStyle.NO then
			return;
		end
	end
	for i = 0, tDraw:GetNbRows() -1 do
		tDraw:SetCell('Pris', i, 0);
		if colonne == 'Rang_tirage' then
			tDraw:SetCellNull('Rang_tirage', i);
			tDraw:SetCellNull('Critere', i);
		elseif colonne == 'Groupe_tirage' then 
			tDraw:SetCell('Groupe_tirage', i, 5);
		elseif colonne == 'All' then 
			tDraw:SetCellNull('Rang_tirage', i);
			tDraw:SetCell('Groupe_tirage', i, 5);
		elseif colonne == 'Dossard' then
			local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement;
			base:Query(cmd);
			tDraw:SetCellNull('Dossard', i);
		elseif colonne == 'Tout' then
			tDraw:SetCellNull('Rang_tirage', i);
			tDraw:SetCell('Groupe_tirage', i, 5);
			tDraw:SetCellNull('Critere', i);
			tDraw:SetCellNull('Dossard', i);
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
	if not draw.trouve_coureur then
		local msg = 'Le coureur ne figure pas sur la liste '..draw.code_liste..'\n'..
					"Voulez-vous l'ajouter tout de même ?";
		if dlgTableau:MessageBox(
			msg, 
			"Ajout d'un coureur", 
			msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING
		) ~= msgBoxStyle.YES then
			return;
		end
	end
	local code_fis = dlgTableau:GetWindowName('code'):GetValue();
	local code_coureur = 'FIS'..code_fis;
	local groupe = tonumber(dlgTableau:GetWindowName('groupe'):GetValue()) or 9;
	local nom = dlgTableau:GetWindowName('nom'):GetValue();
	local prenom = dlgTableau:GetWindowName('prenom'):GetValue();
	local sexe = draw.sexe;
	local an = tonumber(dlgTableau:GetWindowName('an'):GetValue()) or 0;
	local categ = nil;
	local nation = dlgTableau:GetWindowName('nation'):GetValue();
	local comite = '';
	local ecsl_rank = nil;
	local ecsl_points = nil;
	local ecsl_all_rank = nil;
	local ecsl_all_points = nil;	
	local point = tonumber(dlgTableau:GetWindowName('points'):GetValue()) or 0;
	local clt = tonumber(dlgTableau:GetWindowName('classement'):GetValue()) or 0;
	if draw.bolEstCE then
		if type(draw.tECSL[code_coureur]) == 'table' then
			ecsl_points = draw.tECSL[code_coureur].Point or 0;
			ecsl_rank = draw.tECSL[code_coureur].Clt or 0;
			ecsl_all_points = draw.tECSL[code_coureur].AllPoint or 0;
			ecsl_all_rank = draw.tECSL[code_coureur].AllClt or 0;
		end
	end
	if dlgTableau:GetWindowName('comite') then
		comite = dlgTableau:GetWindowName('comite'):GetValue();
		club = dlgTableau:GetWindowName('club'):GetValue();
	end
	local modif_manuel = nil;
	if tCoureur:GetNbRows() == 1 then
		code_coureur = tCoureur:GetCell('Code_coureur', 0);
		nom = tCoureur:GetCell('Nom', 0);
		prenom = tCoureur:GetCell('Prenom', 0);
		sexe = tCoureur:GetCell('Sexe', 0);
		an = tCoureur:GetCell('Naissance', 0, '%4Y');
		nation = tCoureur:GetCell('Code_nation', 0);
	end
	categ = GetCateg(an);
	
	local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
	if r < 0 then		-- on ajoute le coureur dans la table source
		draw.build_table = true;
		draw.skip_question = true;
		draw.ajouter_code = code_coureur;
		tDraw:GetRecord():Set('Code_evenement', draw.code_evenement);
		tDraw:GetRecord():Set('Code_coureur', code_coureur);
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
		if draw.bolEstCE then
			if ecsl_points and ecsl_points > 0 then
				tDraw:GetRecord():Set('ECSL_rank', ecsl_rank);
				tDraw:GetRecord():Set('ECSL_points', ecsl_points);
			end
			if ecsl_all_points and ecsl_all_points > 0 then
				tDraw:GetRecord():Set('ECSL_overall_rank', ecsl_all_rank);
				tDraw:GetRecord():Set('ECSL_overall_points', ecsl_all_points);
			end
		end
		if point > 0 and clt > 0 then
			tDraw:GetRecord():Set('FIS_pts', point);
			tDraw:GetRecord():Set('FIS_clt', clt);
		end
		tDraw:AddRow();
		table.insert(draw.tModifs_tableau, {Code_coureur = code_coureur:sub(4), Nom = nom, Prenom = prenom, Nation = nation, Status = 'AD'});
		-- OnOrder()
	end
	draw.build_table = true;
	OnOrder();
	CommandSendList(bolSendDrawOrder);
	CommandSendOrder(bolSendDrawOrder);
	CommandSendMessage();
	local row = tResultat:AddRow();
	tResultat:SetCell('Code_evenement', row, draw.code_evenement);
	tResultat:SetCell('Code_coureur', row, code_coureur);
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
	tResultat:SetCell('Modif_manuel', row, modif_manuel);
	base:TableInsert(tResultat, row);
	
	row = tResultat_Info_Tirage:AddRow();
	tResultat_Info_Tirage:SetCell('Code_evenement', row, draw.code_evenement);
	tResultat_Info_Tirage:SetCell('Code_coureur', row, code_coureur);
	tResultat_Info_Tirage:SetCellNull('Rang_tirage', row);
	tResultat_Info_Tirage:SetCell('Groupe_tirage', row, groupe);
	tResultat_Info_Tirage:SetCell('ECSL_points', row, ecsl_points);
	tResultat_Info_Tirage:SetCell('ECSL_rank', row, ecsl_rank);
	tResultat_Info_Tirage:SetCell('FIS_pts', row, point);
	tResultat_Info_Tirage:SetCell('FIS_clt', row, clt);
	tResultat_Info_Tirage:SetCell('Statut', row, 'CF');
	base:TableInsert(tResultat_Info_Tirage, row);
	
	-- draw.build_table = false;
	local tView = grid_tableau:GetTableView();
	local tSource = grid_tableau:GetTableSrc();
	if tSource and tView then
		if tView:GetNbRows() ~= tSource:GetNbRows() then
			r = tView:GetIndexRow('Code_coureur', code_coureur);
			grid_tableau:SynchronizeRowsView();
		else
			r = tSource:GetIndexRow('Code_coureur', code_coureur);
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
	dlgTableau:GetWindowName('nation'):SetValue('');
	dlgTableau:GetWindowName('points'):SetValue('');
	dlgTableau:GetWindowName('classement'):SetValue('');
	if draw.bolEstCE then
		dlgTableau:GetWindowName('code'):SetValue('');
		-- dlgTableau:GetWindowName('ecsl_rank'):SetValue('');
		-- dlgTableau:GetWindowName('ecsl_points'):SetValue('');
	else
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
	dlgTableau:GetWindowName('info'):SetValue('Dossard '..dossard..' attribué pour '..tDraw:GetCell('Nom', row)..' '..tDraw:GetCell('Prenom', row));
end

function OnChangeStatut(row)
	local statut = tDraw:GetCell('Statut', row);
	if statut ~= 'UF' and statut ~= 'CF' then
		statut = 'UF';
	end
	local nodeRaceEvent = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceevent");
	local code_coureur = tDraw:GetCell('Code_coureur', row):sub(4);;
	local nodeDrawStatus = xmlNode.Create(nodeRaceEvent, xmlType.ELEMENT_NODE, "drawstatus");
	nodeDrawStatus:AddAttribute('fiscode', code_coureur);
	local nodeStatus = xmlNode.Create(nodeDrawStatus, xmlType.ELEMENT_NODE, "status", statut);
	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeRaceEvent);
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue('Statut de '..tDraw:GetCell('Nom', row)..' '..tDraw:GetCell('Prenom', row)..' modifié');
	-- SendMessage(tDraw:GetCell('Nom', row)..' '..tDraw:GetCell('Prenom', row)..' updated. You might have to refresh the page.');
end

function OnChercheCoureurCode(code);
	draw.trouve_coureur = false;
	local codeFIS = 'FIS'..code;
	local cmd ="Select * From Coureur Where Code_coureur = '"..codeFIS.."'";
	base:TableLoad(tCoureur, cmd);
	if tCoureur:GetNbRows() == 1 then
		draw.trouve_coureur = true;
		local nom = tCoureur:GetCell('Nom', 0);
		local prenom = tCoureur:GetCell('Prenom', 0);
		local sexe = tCoureur:GetCell('Sexe', 0);
		local an = tCoureur:GetCell('Naissance', 0, '%4Y');
		local nation = tCoureur:GetCell('Code_nation', 0);
		local comite = tCoureur:GetCell('Code_comite', 0);
		local club = tCoureur:GetCell('Club', 0);
		local pts, rank, pts_VIT, rank_VIT = GetRank(codeFIS);
		if draw.bolEstCE then 
			if draw.tECSL[codeFIS] == 'table' then
				dlgTableau:GetWindowName('ecsl_points'):SetValue(draw.tECSL[codeFIS].Point);
				dlgTableau:GetWindowName('ecsl_rank'):SetValue(draw.tECSL[codeFIS].Clt);
			end
		end
		return nom, prenom, sexe, an, nation, comite, club, pts, rank, pts_VIT, rank_VIT;
	end
end

function OnGridReorder()
	if draw.bolEstCE then
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
			local msg = "Le coureur n'est pas confirmé !!";
			app.GetAuiFrame():MessageBox(msg, "ATTENTION !! ", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
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
							local msg = 'Dossard '..dossard..' déjà attribué !!';
							if dossard > 0 then
								app.GetAuiFrame():MessageBox(msg, "ATTENTION !! ", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
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
	if draw.bolEstCE == true or draw.bolEstNC == true then
		if draw.bolVitesse == false then
			if row > 14 then
				menuOutils:Enable(btnTirageDossardsRestants:GetId(), true);
			end
		else
			if row > 29 then
				menuOutils:Enable(btnTirageDossardsRestants:GetId(), true);
			end
		end
	else
		if row > 14 then
			menuOutils:Enable(btnTirageDossardsRestants:GetId(), true);
		end
	end
	menuOutils:Enable(btnDecalerBas:GetId(), true);
	menuOutils:Enable(btnDecalerHaut:GetId(), true);
	menuOutils:Enable(btnDecalerGroupeBas:GetId(), true);
	menuOutils:Enable(btnDecalerGroupeHaut:GetId(), true);
	local t = grid_tableau:GetTable();
	local colName = t:GetColumnName(t:GetVisibleColumnsIndex(col));
	grid_tableau:SelectRow(row);
	if col > 0 and col < grid_tableau:GetNumberCols() -2 then
		return;
	end
	local rang_tirage_selected = t:GetCellInt('Rang_tirage', row);
	local code_coureur = t:GetCell('Code_coureur', row);
	local nom = t:GetCell('Nom', row);
	local prenom = t:GetCell('Prenom', row);
	local nation = t:GetCell('Nation', row);
	local identite = nom..'   '..prenom;
	if col == grid_tableau:GetNumberCols() -2 then
		local msg = 'Confirmez-vous la suppression de '..identite;
		if app.GetAuiFrame():MessageBox(msg, "Confirmer la suppression", msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
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
				local msg = 'Attention - Ce concurrent a déjà un dossard.\nSi vous poursuivez, ce dossard sera effacé\nVoulez-vous poursuivre ?';
				if app.GetAuiFrame():MessageBox(msg, "Attention !!!", msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) ~= msgBoxStyle.YES then
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

function OnTirageRangsPtsNull(tableau)
	local rang1 = tableau.Rang1;
	local rangs = tableau.Rangs;
	local dossards = nil;
	local tRangs = rangs:Split(',');
	local tShuffle = {};
	for i = 1, #tRangs do
		table.insert(tShuffle, tRangs[i]);
	end
	tShuffle = Shuffle(tShuffle, true);
	tDrawTirageAuto = tDraw:Copy();
	local filter = "$(Rang_tirage):In("..rangs..")";
	tDrawTirageAuto:Filter(filter, true);		
	
	ReplaceTableEnvironnement(tDrawTirageAuto, '_DrawTirageAuto');
	tDrawTirageAuto:OrderRandom('Prenom');
	tDrawTirageAuto:OrderRandom();
	for j = 0, tDrawTirageAuto:GetNbRows() -1 do
		local valeur_shuffle = tShuffle[j+1];
		local code_coureur = tDrawTirageAuto:GetCell('Code_coureur', j)
		local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
		if r >= 0 then
			tDraw:SetCell('Dossard', r, valeur_shuffle);
			local cmd = "Update Resultat Set Dossard = "..(valeur_shuffle)..", Critere = '"..string.format('%03d', tDraw:GetCellInt('Rang_tirage', r)).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..tDraw:GetCell('Code_coureur', r).."'";
			base:Query(cmd);
		end
	end
end

function GetRank(code_coureur)
	local pts = nil;
	local rank = nil;
	local pts_SG = nil;
	local rank_SG = nil;
	local cmd = "Select * From Classement_Coureur Where Code_coureur = '"..code_coureur.."' And Type_classement = '"..draw.type_classement.."' And Code_liste = "..draw.code_liste;
	tClassement_Coureur = base:TableLoad(cmd);
	if tClassement_Coureur:GetNbRows() == 1 then
		pts = tClassement_Coureur:GetCellDouble('Pts', 0);
		rank = tClassement_Coureur:GetCellInt('Clt', 0);
	end

	if draw.type_classement == 'IADH' then
		local cmd = "Select * From Classement_Coureur Where Code_coureur = '"..code_coureur.."' And Type_classement = 'IASG' And Code_liste = "..draw.code_liste;
		tClassement_Coureur = base:TableLoad(cmd);
		if tClassement_Coureur:GetNbRows() == 1 then
			pts_SG = tClassement_Coureur:GetCellDouble('Pts', 0);
			rank_SG = tClassement_Coureur:GetCellInt('Clt', 0);
		end
	end
	return pts, rank, pts_SG, rank_SG;
end

function RefreshGrid(bolTableSource)	-- bolTableSource = true ou false
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
	base:TableBulkUpdate(tDraw,'Dossard, Critere', 'Resultat');
	base:TableBulkUpdate(tDraw,'Code_evenement, Groupe_tirage, TG, Rang_tirage, WCSL_points, WCSL_rank, ECSL_points, ECSL_rank, ECSL_30, ECSL_overall_points, ECSL_overall_rank, Winner_CC, FIS_pts, FIS_clt, FIS_SG_pts, FIS_SG_clt, Statut', 'Resultat_Info_Tirage');
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
	for i = 0, tResultat:GetNbRows() -1 do
		local code_coureur = tResultat:GetCell('Code_coureur', i);
		local pts, rank, pts_SG, rank_SG = GetRank(code_coureur);
		local r = tResultat_Info_Tirage:GetIndexRow('Code_coureur', code_coureur);
		if r < 0 then
			-- on ajoute le coureur dans la table tResultat_Info_Tirage
			draw.build_table = true;
			row = tResultat_Info_Tirage:AddRow();
			tResultat_Info_Tirage:SetCell('Code_evenement', row, draw.code_evenement);
			tResultat_Info_Tirage:SetCell('Code_coureur', row, tResultat:GetCell('Code_coureur', i));
			tResultat_Info_Tirage:SetCell('Groupe_tirage', row, 5);
			tResultat_Info_Tirage:SetCell('Statut', row, 'UF');
			if pts then
				tResultat:SetCell('Point', i, pts);
				tResultat_Info_Tirage:SetCell('FIS_pts', row, pts);
				tResultat_Info_Tirage:SetCell('FIS_clt', row, rank);
			else
				tResultat_Info_Tirage:SetCellNull('FIS_pts', row);
				tResultat_Info_Tirage:SetCellNull('FIS_clt', row);
			end
			tResultat_Info_Tirage:SetCell('FIS_SG_pts', row, pts_SG);
			tResultat_Info_Tirage:SetCell('FIS_SG_clt', row, rank_SG);
			base:TableInsert(tResultat_Info_Tirage, row);
		else
			if pts then
				tResultat_Info_Tirage:SetCell('FIS_pts', r, pts);
				tResultat_Info_Tirage:SetCell('FIS_clt', r, rank);
				tResultat_Info_Tirage:SetCell('FIS_SG_pts', r, pts_SG);
				tResultat_Info_Tirage:SetCell('FIS_SG_clt', r, rank_SG);
				base:TableUpdate(tResultat_Info_Tirage, r);
			end
		end
	end
	base:TableBulkUpdate(tResultat, 'Point', 'Resultat');
end

function TraitementtDrawG4()
	-- adv.Alert('\nEntrée de TraitementtDrawG4');
	for j = 0, tDrawG4:GetNbRows() -1 do		-- les winners des CC 
		-- adv.Alert('coureur de tDrawG4 traité : '..tDrawG4:GetCell('Nom', j)..',  draw.rang_tirage = '.. draw.rang_tirage);
		draw.rang_tirage = draw.rang_tirage + 1;
		local code_coureur = tDrawG4:GetCell('Code_coureur', j);
		local r2 = tDraw:GetIndexRow('Code_coureur', code_coureur);
		tDraw:SetCell('TG', r2, 'tDrawG4');
		tDraw:SetCell('Racer_info', r2, 'COC');
		tDraw:SetCell('Pts_info', r2, '');
		tDraw:SetCell('Pris', r2, 1);
		tDraw:SetCell('Groupe_tirage', r2, current_group + 1);
		tDraw:SetCell('ECSL_30', r2, 10);
		tDraw:SetCell('Rang_tirage', r2, draw.rang_tirage);
		tDraw:SetCell('Dossard', r2, draw.rang_tirage);
		tDraw:SetCell('Critere', r2, string.format('%03d', draw.rang_tirage));
		local rtDrawG5 = tDrawG5:GetIndexRow('Code_coureur', code_coureur);
		if rtDrawG5 >= 0 then		-- on trouve le coureur
			tDrawG5:RemoveRowAt(rtDrawG5);
		end
		local rtDrawG6 = tDrawG6:GetIndexRow('Code_coureur', code_coureur);
		-- adv.Alert('On cherche '..tDrawG4:GetCell('Nom', j)..' dans tDrawG6')
		if rtDrawG6 >= 0 then		-- on trouve le coureur
			-- adv.Alert('On efface '..tDrawG4:GetCell('Nom', j)..' dans tDrawG6')
			tDrawG6:RemoveRowAt(rtDrawG6);
		end
	end
	-- adv.Alert('Sortie de TraitementtDrawG4\n');
	tDrawG4:RemoveAllRows();
	if draw.nb_pris_ecsl == 30 then
		draw.ajouter_groupe = 1;
	else
		draw.ajouter_groupe = 0;
	end
		
end

function SetuptDraw()
	if not draw.build_table then
		tDraw:OrderBy('Rang_tirage');
		return;
	end
	draw.bolExisteDossard = false;
	draw.bolTirageBiboFait = false;
	draw.bolTirageAvecPointFait = false;
	draw.bolTirageSansPointFait = false;
	base:Query('Delete From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement);
	local cmd = "Update Resultat Set Dossard = Null Where Code_evenement = "..draw.code_evenement;
	base:Query(cmd);
	for i = 0, tDraw:GetNbRows() -1 do
		tDraw:SetCell('Pris', i, 0);
		tDraw:SetCellNull('Critere', i);
		tDraw:SetCellNull('Groupe', i);
		tDraw:SetCellNull('TG', i);
		tDraw:SetCellNull('ECSL_30', i);
		tDraw:SetCellNull('Racer_info', i);
		tDraw:SetCellNull('Pts_info', i);
		if tDraw:GetCell('Statut', i):len() == 0 then
			tDraw:SetCell('Statut', i, 'UF');
		end
		local pts, rank, pts_SG, rank_SG = GetRank(tDraw:GetCell('Code_coureur', i));
		if rank and rank > 0 then
			tDraw:SetCell('FIS_pts', i, pts);
			tDraw:SetCell('FIS_clt', i, rank);
		else
			tDraw:SetCellNull('FIS_pts', i);
			tDraw:SetCellNull('FIS_clt', i);
		end
		if rank_SG and rank_SG > 0 then
			tDraw:SetCell('FIS_SG_pts', i, pts_SG);
			tDraw:SetCell('FIS_SG_clt', i, rank_SG);
		else
			tDraw:SetCellNull('FIS_SG_pts', i);
			tDraw:SetCellNull('FIS_SG_clt', i);
		end
		if tDraw:GetCell('Code_coureur', i) == draw.ajouter_code then
			tDraw:SetCell('Statut', i, 'CF');
		end
	end
	-- prise en compte des points de la ligne 15 et écentuellement 7 en technique (EC et NC)
	tDraw:OrderBy('ECSL_points DESC, FIS_pts');
	draw.ptsFIS7 = tDraw:GetCellDouble('FIS_pts', 6);
	draw.ptsFIS15 = tDraw:GetCellDouble('FIS_pts', 14);
	draw.ptsFIS30 = tDraw:GetCellDouble('FIS_pts', 29);
	draw.pts7 = tDraw:GetCellInt('ECSL_points', 6);
	draw.pts15 = tDraw:GetCellInt('ECSL_points', 14);
	tDrawG1 = tDraw:Copy();	-- dans les 15 de la ECSL
	ReplaceTableEnvironnement(tDrawG1, 'DrawG1');
	tDrawG2 = tDraw:Copy();	-- les 450 - 200 pts
	ReplaceTableEnvironnement(tDrawG2, 'DrawG2');
	tDrawG3 = tDraw:Copy();	-- dans les 30 de la WC
	ReplaceTableEnvironnement(tDrawG3, 'DrawG3');
	tDrawG4 = tDraw:Copy();	-- les winner des CC
	ReplaceTableEnvironnement(tDrawG4, 'DrawG4');
	tDrawG5 = tDraw:Copy();	-- tous les ECSL 
	ReplaceTableEnvironnement(tDrawG5, 'DrawG5');
	tDrawG6 = tDraw:Copy();	-- tous les pts FIS 
	ReplaceTableEnvironnement(tDrawG6, '_DrawG6');
--[[
groupe 1 ECSL de la discipline : de 1 à 15 (ou plus). Compte dans les 30 ECSL
groupe 2 Si plus de 450 pts en EC la saison dernière de 16 à x. Compte dans les 30 ECSL
groupe 2 on met en plus dans ce groupe les coureurs de la WC dans les 30 de la WCSL de la discipline. On départage selon les pts ECSL sinon par les pts FIS
groupe 3 On continue avec les Pts de la ECSL et les Pts FIS si on n'a pas assez de Pts ECSL jusqu'à en avoir 30. On peut avoir 27 avec des Pts ECSL et 3 avec des Pts FIS.
groupe 4 Cette série est interrompue si on a un vainqueur d'une autre Coupe continentale qui par systématiquement en 31 ème position.
groupe 5 La série interrompue reprend jusqu'à en avoir 30.
Groupe 6 On poursuit selon les points FIS.
]]
	-- adv.Alert('draw.pts15 = '..draw.pts15);
	
	for i = tDrawG1:GetNbRows() -1, 0, -1 do		-- dans les 15
		local pts = tDrawG1:GetCellInt('ECSL_points', i, -1);
		if pts < draw.pts15 then
			tDrawG1:RemoveRowAt(i);
		end
	end
	tDrawG2:OrderBy('ECSL_overall_points DESC');	-- les 450 - 200 pts
	for i = tDrawG2:GetNbRows() -1, 0, -1 do
		local pts = tDrawG2:GetCellInt('ECSL_overall_points', i);
		if pts == 0 then
			tDrawG2:RemoveRowAt(i);
		end
	end

	tDrawG3:OrderBy('ECSL_points DESC, FIS_pts, WCSL_rank');	-- dans les 30 de la WCSL
	for i = tDrawG3:GetNbRows() -1, 0, -1 do
		local clt = tDrawG3:GetCellInt('WCSL_rank', i, 31);
		if clt > 30 then
			tDrawG3:RemoveRowAt(i);
		end
	end

	tDrawG5:OrderBy('ECSL_points DESC');				-- les ECSL
	for i = tDrawG5:GetNbRows() -1, 0, -1 do
		local pts =  tDrawG5:GetCellInt('ECSL_points', i, -1);
		if pts < 0 then
			tDrawG5:RemoveRowAt(i);
		else
			if draw.finale_ce == 'Oui' then
				break;
			end
		end
	end

	tDrawG4:OrderBy('FIS_pts');				-- les vainqueurs des autres CC
	for i = tDrawG4:GetNbRows() -1, 0, -1 do
		local winner = tDrawG4:GetCell('Winner_CC', i);
		if winner:len() == 0 then
			tDrawG4:RemoveRowAt(i);
		end
	end
	tDrawG6:OrderBy('FIS_pts');				-- coureurs ayant des points FIS
	for i = tDrawG6:GetNbRows() -1, 0, -1 do
		local pts = tDrawG6:GetCellDouble('FIS_pts', i, -1);
		if pts < 0 then
			tDrawG6:RemoveRowAt(i);
		end
	end
	
	if draw.finale_ce == 'Oui' then
		for i = 0, tDrawG5:GetNbRows() -1 do
			local code_coureur = tDrawG5:GetCell('Code_coureur', i)
			local r = tDrawG6:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG6:RemoveRowAt(r);
			end
		end
	else
	end
	
	-- adv.Alert('3- tDrawG6:GetNbRows() = '..tDrawG6:GetNbRows())
	
	tDrawG5:OrderBy('ECSL_points DESC, FIS_pts');	-- coureurs ayant des points ECSL
	tDrawG6:OrderBy('FIS_pts');
	-- analyse de tDrawG5
	local last_pts_fis = 0;
	if not draw.bolEstCE then
		tDrawG5:RemoveAllRows();
		last_pts_fis = tDrawG6:GetCellDouble('FIS_pts', tDrawG6:GetNbRows() -1);
	end
	-- les groupes 1 et 2 en technique ou groupe 1 seulement en vitesse
	current_group = 0;
	draw.nb_pris_ecsl = 0;
	params.nb_groupe1 = 0;
	params.nb_groupe2 = 0;
	local ecsl_pts = -1;
	local fis_pts = -1;
	draw.rang_tirage = 0;
	tDrawG1:OrderBy('ECSL_points DESC, FIS_pts');	-- départage des exaequos ECSL par les pts FIS
	if tDrawG1:GetNbRows() > 0 then
		for i = 0, tDrawG1:GetNbRows() -1 do		-- On est forcément en Coupe d'Europe sinon tDrawG1 est vide
			local ecsl_pts = tDrawG1:GetCellInt('ECSL_points', i);
			local fis_pts = tDrawG1:GetCellDouble('FIS_pts', i);
			local code_coureur = tDrawG1:GetCell('Code_coureur', i);
			local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
			if draw.bolVitesse == true then
				current_group = 1;
			else
				if ecsl_pts >= draw.pts7 then
					current_group = 1;
				else
					current_group = 2;
				end
			end
			tDraw:SetCell('ECSL_30', r, 1);
			tDraw:SetCell('Groupe_tirage', r, current_group);
			tDraw:SetCell('TG', r, 'tDrawG1');
			tDraw:SetCell('Pris', r, 1);
			tDraw:SetCell('ECSL_30', r, 1);
			
			draw.rang_tirage = draw.rang_tirage + 1;
			tDraw:SetCell('Rang_tirage', r, draw.rang_tirage);
			tDraw:SetCell('Critere', r, string.format('%03d', draw.rang_tirage));
			draw.nb_pris_ecsl = draw.nb_pris_ecsl + 1;
			local r = tDrawG2:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG2:RemoveRowAt(r);
			end
			r = tDrawG3:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG3:RemoveRowAt(r);
			end
			r = tDrawG4:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG4:RemoveRowAt(r);
			end
			r = tDrawG5:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG5:RemoveRowAt(r);
			end
			r = tDrawG6:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG6:RemoveRowAt(r);
			end
		end
		if draw.bolVitesse == false then
			current_group = current_group + 1;
		end
	end
	
	tDrawG2:OrderBy('ECSL_overall_points DESC, ECSL_points DESC, FIS_pts');				-- les + de 450 pts
	if tDrawG2:GetNbRows() > 0 then
		local pts_overall_next  = nil;
		local pts_fis_next  = nil;
		for i = 0, tDrawG2:GetNbRows() -1 do		-- les plus de 450 - 200 pts 
			local code_coureur = tDrawG2:GetCell('Code_coureur', i);
			local pts_overall = tDrawG2:GetCellInt('ECSL_overall_points', i);
			local pts_fis = tDrawG2:GetCellDouble('FIS_pts', i);
			-- adv.Alert('tDrawG2, identité = '..tDrawG2:GetCell('Nom', i).." "..tDrawG2:GetCell('Prenom', i))
			draw.rang_tirage = draw.rang_tirage + 1;
			local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
			tDraw:SetCell('TG', r, 'tDrawG2');
			tDraw:SetCell('Racer_info', r, '450+');
			tDraw:SetCell('Pts_info', r, '>');
			tDraw:SetCell('Pris', r, 1);
			tDraw:SetCell('Groupe_tirage', r, current_group);
			tDraw:SetCell('Rang_tirage', r, draw.rang_tirage);
			tDraw:SetCell('ECSL_30', r, 2);
			if draw.bolVitesse == false then
				tDraw:SetCell('Dossard', r, draw.rang_tirage);
			end
			tDraw:SetCell('Critere', r, string.format('%03d', draw.rang_tirage));
			draw.nb_pris_ecsl = draw.nb_pris_ecsl + 1;
			local r = tDrawG3:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG3:RemoveRowAt(r);
			end
			r = tDrawG4:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG4:RemoveRowAt(r);
			end
			r = tDrawG5:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG5:RemoveRowAt(r);
			end
			r = tDrawG6:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG6:RemoveRowAt(r);
			end
		end
	end
	if draw.bolVitesse == true then
		current_group = current_group + 1;
	end
	-- draw.rang_tirage = tDrawG1:GetNbRows() + tDrawG2:GetNbRows() + 1;
	tDrawG3:OrderBy('ECSL_points DESC, FIS_pts, WCSL_rank');				-- dans les 30 de la WCSL
	if tDrawG3:GetNbRows() > 0 then
		for i = 0, tDrawG3:GetNbRows() -1 do		-- dans les 30 de la WCSL 
			local code_coureur = tDrawG3:GetCell('Code_coureur', i);
			local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
			draw.rang_tirage = draw.rang_tirage + 1;
			tDraw:SetCell('TG', r, 'tDrawG3');
			tDraw:SetCell('Racer_info', r, '<= 30');
			tDraw:SetCell('Pts_info', r, '<');
			tDraw:SetCell('Pris', r, 1);
			tDraw:SetCell('Groupe_tirage', r, current_group);
			tDraw:SetCell('Rang_tirage', r, draw.rang_tirage);
			tDraw:SetCell('ECSL_30', r, 3);
			if draw.bolVitesse == false then
				tDraw:SetCell('Dossard', r, draw.rang_tirage);
			end
			tDraw:SetCell('Critere', r, string.format('%03d', draw.rang_tirage));
			local r = tDrawG4:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG4:RemoveRowAt(r);
			end
			r = tDrawG5:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG5:RemoveRowAt(r);
			end
			r = tDrawG6:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then		-- on trouve le coureur
				tDrawG6:RemoveRowAt(r);
			end
		end
	end
	-- on continue avec les ECSL pts (tDrawG5) interrompu par les winners en 31 ème place
	-- draw.rang_tirage = tDrawG1:GetNbRows() + tDrawG2:GetNbRows() + tDrawG3:GetNbRows() +1;
	tDrawG4:OrderBy('ECSL_points DESC, FIS_pts');				-- les winners de CC triés par leurs points ECSL et les points FIS
	tDrawG5:OrderBy('ECSL_points DESC, FIS_pts');				-- les 30 ECSL
	-- adv.Alert('on a pris '..draw.nb_pris_ecsl..' sur les 30 à prendre, tDrawG4:GetNbRows() = '..tDrawG4:GetNbRows());
	-- le premier winner sera toujours au rang 31 = row 30
	draw.bol99done = false;
	draw.ajouter_groupe = 0;	
	local groupe5 = 0;
	-- adv.Alert('avant traitement de tDrawG5, tDrawG4:GetNbRows() = '..tDrawG4:GetNbRows()..', tDrawG5:GetNbRows() = '..tDrawG5:GetNbRows());
	local exaequo = 0;
	if tDrawG5:GetNbRows() > 0 then
		local rtDraw = -1;
		for i = 0, tDrawG5:GetNbRows() -1 do		-- on prendra jusqu'à draw.nb_pris_ecsl = 30 étendu si exaequo à la 30 place
			local code_coureur = tDrawG5:GetCell('Code_coureur', i);
			if code_coureur:len() > 0 then
				rtDraw = tDraw:GetIndexRow('Code_coureur', code_coureur);
				tDraw:SetCell('ECSL_30', rtDraw, 5);
				tDraw:SetCell('TG', rtDraw, 'tDrawG5');
				tDraw:SetCell('Pris', rtDraw, 1);
				tDraw:SetCell('Groupe_tirage', rtDraw, current_group);
				groupe5 = current_group;
				draw.rang_tirage = draw.rang_tirage + 1;
				tDraw:SetCell('Rang_tirage', rtDraw, draw.rang_tirage);
				tDrawG5:SetCell('Rang_tirage', i, draw.rang_tirage);
				tDraw:SetCell('Critere', rtDraw, string.format('%03d', draw.rang_tirage));
				draw.nb_pris_ecsl = draw.nb_pris_ecsl + 1;
				local r = tDrawG4:GetIndexRow('Code_coureur', code_coureur);
				if r >= 0 then		-- on trouve le coureur
					tDrawG4:RemoveRowAt(r);
				end
				r = tDrawG6:GetIndexRow('Code_coureur', code_coureur);
				if r >= 0 then		-- on trouve le coureur
					tDrawG6:RemoveRowAt(r);
				end
				-- adv.Alert('On traite tDrawG5, on prend '..tDrawG5:GetCell('Nom', i)..', ECSL_points = '..tDraw:GetCellInt('ECSL_points', i)..', draw.nb_pris_ecsl = '..draw.nb_pris_ecsl..', draw.rang_tirage = '..draw.rang_tirage..', tDrawG4:GetNbRows() = '..tDrawG4:GetNbRows());
				if draw.rang_tirage == 30 and tDrawG4:GetNbRows() > 0 then
					-- adv.Alert('Avant Traitement tDrawG4, draw.rang_tirage = '..draw.rang_tirage)
					TraitementtDrawG4();
					-- adv.Alert('Après Traitement tDrawG4, draw.rang_tirage = '..draw.rang_tirage)
				end
				if draw.nb_pris_ecsl == 30 or rang_tirage == 30 then
					if i < tDrawG5:GetNbRows() -1 then
						if tDrawG5:GetCellInt('ECSL_points', i) == tDrawG5:GetCellInt('ECSL_points', i + 1) then
							draw.nb_pris_ecsl = 29;
							exaequo = exaequo + 1;
						end
					end
				end
				if draw.nb_pris_ecsl == 30 then
					draw.bol99done  = true
					tDrawG5:SetCell('ECSL_30', i, 99);
					tDraw:SetCell('ECSL_30', rtDraw, 99);
				end
				-- draw.nb_pris_ecsl = draw.nb_pris_ecsl + 1;
				-- adv.Alert('last tDrawG5 traité = '..tDrawG5:GetCell('Nom', i)..', draw.rang_tirage = '..draw.rang_tirage);
				draw.LastCurrentGroup = current_group;
				if draw.bol99done and draw.finale_ce == 'Non' then
					break;
				end
			end
		end
		-- adv.Alert('3 - rajouter_pts_fis = '..rajouter_pts_fis..', current_group = '..current_group);
	end
	tDrawG6:OrderBy('FIS_pts');
	current_group = current_group + draw.ajouter_groupe;
	if draw.bolEstCE and draw.nb_pris_ecsl < 30 then
		for i = 0, tDrawG6:GetNbRows() - 1 do
			if tDrawG6:GetCell('Winner_CC', i):len() == 0 then
				local code_coureur = tDrawG6:GetCell('Code_coureur', i);
				draw.rang_tirage = draw.rang_tirage + 1;
				draw.nb_pris_ecsl = draw.nb_pris_ecsl + 1;
				if draw.nb_pris_ecsl == 30 then
					tDrawG5:SetCell('ECSL_30', i, 99);
					tDraw:SetCell('ECSL_30', rtDraw, 99);
				end
				tDrawG6:SetCell('Pris', i, 1);
				tDrawG6:SetCell('Rang_tirage', i, draw.rang_tirage);
				local rtDraw = tDraw:GetIndexRow('Code_coureur', code_coureur);
				if rtDraw >= 0 then		-- on trouve le coureur
					tDraw:SetCell('Pris', rtDraw, 1);
					if tDraw:GetCell('TG', rtDraw):len() == 0 then
						tDraw:SetCell('TG', rtDraw, 'tDrawG5');
					end
					tDraw:SetCell('Groupe_tirage', rtDraw, current_group);
					tDraw:SetCell('Rang_tirage', rtDraw, draw.rang_tirage);
					tDraw:SetCell('Critere', rtDraw, string.format('%03d', draw.rang_tirage));
				end
				if draw.rang_tirage == 30 then
					break;
				end
			end
		end
	end
	if tDrawG4:GetNbRows() > 0 then
		if draw.bolVitesse then
			if current_group < 3 then
				current_group = 3;
			end
		end
		TraitementtDrawG4();
	end
	tDrawG6:OrderBy('FIS_pts');			-- on continue avec les points FIS
	if not draw.bolEstCE then
		current_group = 0;			-- les groupes de tirages son définis cidessous
	end
	if tDrawG6:GetNbRows() > 0 then
		current_group = current_group + 1;
		for i = 0, tDrawG6:GetNbRows() -1 do
			if tDrawG6:GetCellInt('Pris', i) == 0 then
				local code_coureur = tDrawG6:GetCell('Code_coureur', i);
				-- adv.Alert('tDrawG6 - on traite '..tDrawG6:GetCell('Nom', i).. 'dans tDrawG6');
				local pts = tDrawG6:GetCellDouble('FIS_pts', i);
				if not draw.bolEstCE then
					if not draw.bolVitesse then
						if draw.code_niveau == 'NC' then		-- Championnats de France
							if pts <= draw.ptsFIS7 then
								current_group = 1;
							elseif pts <= draw.ptsFIS15 then
								current_group = 2;
							elseif pts > 0 then
								current_group = 3;
							else
								current_group = 4;
							end
						else
							if pts <= draw.ptsFIS15 then
								current_group = 1;
							elseif pts > 0 then
								current_group = 2;
							else
								current_group = 3;
							end
						end
					else
						if pts > 0 then
							if pts <= draw.ptsFIS15 then
								current_group = 1;
							elseif pts <= draw.ptsFIS30 then
								current_group = 2;
							else
								current_group = 3;
							end
						else
							current_group = 4;
						end
					end
				end
				local code_coureur = tDrawG6:GetCell('Code_coureur', i);
				draw.rang_tirage = draw.rang_tirage + 1;
				local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
				if code_coureur == draw.ajouter_code then
					tDraw:SetCell('Statut', r, 'CF');
				end
				-- adv.Alert('coureur de tDrawG6 traité : '..tDrawG6:GetCell('Nom', i)..',  draw.rang_tirage = '.. draw.rang_tirage);

				tDraw:SetCell('Pris', r, 1);
				tDraw:SetCell('Groupe_tirage', r, current_group);
				if draw.bolEstCE then
					tDraw:SetCell('TG', r, 'tDrawG6');
				else
					tDraw:SetCell('TG', r, 'Groupe'..tDraw:GetCell('Groupe_tirage', r, current_group));
				end
				tDraw:SetCell('Rang_tirage', r, draw.rang_tirage);
				tDraw:SetCell('Groupe', r, current_group);
				tDraw:SetCell('Critere', r, string.format('%03d', tDraw:GetCellInt('Rang_tirage', r)));
			end
		end
	end
	current_group = current_group + 1;
	-- adv.Alert('draw.last_code_ecsl = '..tostring(draw.last_code_ecsl));
	for i = 0, tDraw:GetNbRows() -1 do
		if tDraw:GetCellInt('Pris', i) == 0 then
			-- adv.Alert('pour la suite , on prend '..tDraw:GetCell('Nom', i)..', current_group = '..current_group);
			tDraw:SetCell('Pris', i, 1);
			draw.rang_tirage = draw.rang_tirage + 1;
			tDraw:SetCell('Rang_tirage', i, draw.rang_tirage);
			tDraw:SetCell('Groupe_tirage', i, current_group);
			tDraw:SetCell('Critere', i, string.format('%03d', draw.rang_tirage));
		end
		if tDraw:GetCell('TG', i):len() == 0 or tDraw:GetCellDouble('FIS_pts', i, -1) < 0 then
			tDraw:SetCell('TG', i, 'PtsFISNull');
		end
	end
	RefreshGrid();
	ChecktDraw();
end

function OnRowSelected(evt)
	local row = evt:GetRow();
	local col = evt:GetCol();
	local t = grid_coureur:GetTable();
	local colName = t:GetColumnName(t:GetVisibleColumnsIndex(col));
	grid_coureur:SelectRow(row);
	if col > 0 then
		dlgTableau:GetWindowName('code'):SetValue(t:GetCell('Code_coureur', row):sub(4));
		local mgr = app.GetAuiManager();
		mgr:DeletePane(panel_coureur);
		panel_coureur = nil;
	end
end

function CreatePanelCoureur()
	local xlabel = 'Recherche des coureurs - discipline de la course : '..draw.discipline..' - version '..scrip_version..' du script  -  course n° '..draw.code_evenement..' - CODEX : '..tEvenement:GetCell('Codex', 0);
	panel_coureur = wnd.CreatePanel({ parent = app.GetAuiFrame() });
	panel_coureur:LoadTemplateXML({ 
		xml = './process/dossard_LiveDraw.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 	
		node_value = 'coureur' 
	});
	grid_coureur = panel_coureur:GetWindowName('coureur');
	grid_coureur:Set({
		table_base = tCoureur,
		columns = 'Code_coureur, Nom, Prenom, Naissance, Code_nation, Code_comite, Club',
		selection_mode = gridSelectionModes.ROWS,
		sortable = false,
		enable_editing = false
	});
	local mgr = app.GetAuiManager();
	mgr:AddPane(panel_coureur, {
		icon = './res/16x16_agil.png',
		caption = xlabel,
		caption_visible = true,
		close_button = false,
		pin_button = true,
		show = true,
		float = true, 
		floating_position = {app.GetAuiFrame():GetDisplayArea().x+100, 50},
		floating_size = {1000, 750},
		dockable = false
		
	});
	mgr:Update();
	grid_coureur:Bind(eventType.GRID_SELECT_CELL, OnRowSelected);
	panel_coureur:Bind(eventType.CLOSE_WINDOW, 
		function(evt)
			local mgr = app.GetAuiManager();
			mgr:DeletePane(panel_coureur);
			panel_coureur = nil;
			mgr:Update();
		end);
end

function OnAfficheTableau()
	if not draw.socket then
		parentFrame = wnd.GetParentFrame();
		draw.socket = socketClient.Open(parentFrame, draw.hostname, draw.port);
		draw.socket_state = false;
		parentFrame:Bind(eventType.SOCKET, OnSocketLive, draw.socket);
	end
-- Création Dialog 
	draw.label_dialog = 'Tableau des coureurs - discipline de la course : '..draw.discipline..' - version '..scrip_version..' du script  -  course n° '..draw.code_evenement..' - CODEX : '..tEvenement:GetCell('Codex', 0);
	dlgTableau = wnd.CreateDialog(
		{
		width = draw.width,
		height = draw.height,
		x = draw.x,
		y = draw.y,
		label=draw.label_dialog, 
		icon='./res/32x32_fis.png'
		});
	
	if draw.bolEstCE then
		dlgTableau:LoadTemplateXML({ 
			xml = './process/dossard_LiveDraw.xml',
			node_name = 'root/panel', 
			node_attr = 'name', 	
			node_value = 'gridCE' 
		});
	else
		dlgTableau:LoadTemplateXML({ 
			xml = './process/dossard_LiveDraw.xml',
			node_name = 'root/panel', 
			node_attr = 'name', 	
			node_value = 'gridFIS' 
		});
	end
	
	draw.timer = timer.Create(dlgTableau);

-- Grid 
	grid_tableau = dlgTableau:GetWindowName('tableau');
	BuildTablesDraw();

	local cmd ='Select r.*, rit.* , Repeat(" ",10) Action, Repeat(" ",10) Validation, Concat(Prenom, Nom) Identite, Repeat(" ",7) TG, 0 Pris, 0 Dossard_bibo ';
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
	tDraw:SetColumn('Rang_tirage', { label = 'Rang', width = 6 });
	tDraw:SetColumn('Groupe_tirage', { label = 'Groupe', width = 7 });
	tDraw:SetColumn('Code_coureur', { label = 'Code', width = 10 });
	tDraw:SetColumn('Nom', { label = 'Nom', width = 20 });
	tDraw:SetColumn('Prenom', { label = 'Prenom', width = 12 });
	tDraw:SetColumn('Nation', { label = 'Nat.', width = 5 });
	tDraw:SetColumn('ECSL_points', { label = 'EC SL', width = 6 });
	tDraw:SetColumn('ECSL_rank', { label = 'EC Clt', width = 6 });
	tDraw:SetColumn('WCSL_points', { label = 'WC SL', width = 6 });
	tDraw:SetColumn('WCSL_rank', { label = 'WC Clt', width = 6 });
	tDraw:SetColumn('ECSL_overall_points', { label = 'Overall Pts', width = 10 });
	tDraw:SetColumn('ECSL_overall_rank', { label = 'Overall Clt', width = 8 });
	tDraw:SetColumn('Winner_CC', { label = 'Winner CC', width = 8 });
	tDraw:SetColumn('FIS_pts', { label = 'Pts '..draw.discipline, width = 6 });
	tDraw:SetColumn('FIS_clt', { label = 'Clt '..draw.discipline, width = 6 });
	tDraw:SetColumn('FIS_SG_pts', { label = 'Pts SG', width = 6 });
	tDraw:SetColumn('FIS_SG_clt', { label = 'Clt SG', width = 6 });
	tDraw:SetColumn('Comite', { label = 'C.R.', width = 6 });
	tDraw:SetColumn('Club', { label = 'Club', width = 12 });
	tDraw:SetColumn('Action', { label = 'Supprimer', width = 8 });
	tDraw:SetColumn('Validation', { label = 'CF / UF', width = 8 });
	tDraw:SetColumn('Statut', { label = 'UF/CF', width = 6 });
	tDraw:SetPrimary('Code_evenement, Code_coureur');
	ReplaceTableEnvironnement(tDraw, '_Draw');
	tDraw:OrderBy('Rang_tirage');
	
	if draw.bolEstCE then
		if not draw.bolVitesse then
			grid_tableau:Set({
				table_base = tDraw,
				columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, ECSL_points, ECSL_rank, WCSL_points, WCSL_rank, ECSL_overall_points, ECSL_overall_rank, Winner_CC, FIS_pts, FIS_clt, Statut, Action, Validation',
				selection_mode = gridSelectionModes.ROWS,
				-- focus_cell_highlight = true,
				label_tracking = true,
				sortable = true,
				enable_editing = true
			});
		else
			grid_tableau:Set({
				table_base = tDraw,
				columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, ECSL_points, ECSL_rank, WCSL_points, WCSL_rank, ECSL_overall_points, ECSL_overall_rank, Winner_CC, FIS_pts, FIS_clt, FIS_SG_pts, FIS_SG_clt, Statut, Action, Validation',
				selection_mode = gridSelectionModes.ROWS,
				-- focus_cell_highlight = true,
				label_tracking = true,
				sortable = true,
				enable_editing = true
			});
		end
	else
		for i = 0, tDraw:GetNbRows() -1 do
			tDraw:SetCellNull('ECSL_points', i);
			tDraw:SetCellNull('ECSL_rank', i);					
			tDraw:SetCellNull('ECSL_overall_points', i);
			tDraw:SetCellNull('ECSL_overall_rank', i);
			tDraw:SetCellNull('WCSL_points', i);
			tDraw:SetCellNull('WCSL_rank', i);					
			tDraw:SetCellNull('CC_winner', i);					
		end
		grid_tableau:Set({
			table_base = tDraw,
			columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, Comite, Club, FIS_pts, FIS_clt, Statut, Action, Validation',
			selection_mode = gridSelectionModes.ROWS,
			-- focus_cell_highlight = true,
			label_tracking = true,
			sortable = true,
			enable_editing = true
		});
	end

	grid_tableau:AddColumnLabel(3);
      grid_tableau:AddRowLabel(1, 48);

-- Initialisation des Controles

	bolSendDrawOrder = true;
	
	tbTableau = dlgTableau:GetWindowName('tbtableau');
	tbTableau:AddStretchableSpace();
	btnSendMessage = tbTableau:AddTool("Messages", "./res/32x32_journal.png");
	tbTableau:AddSeparator();
		
	btnMenuCommande = tbTableau:AddTool("Commandes", "./res/chrono32x32_ko.png",'', itemKind.DROPDOWN);
	menuCommande = menu.Create();
	menuCommande:AppendSeparator();
	btnClear = menuCommande:Append({label="RAZ à la FIS", image ="./res/32x32_clear.png"});
	menuCommande:AppendSeparator();
	btnState = menuCommande:Append({label="Activation ou Désactivation du Live...", image ="./res/32x32_fis.png"});
	menuCommande:AppendSeparator();
	btn_reset_socket = menuCommande:Append({label="Reset de la connexion FIS.", image = "./res/32x32_satellite.png"});
	tbTableau:SetDropdownMenu(btnMenuCommande:GetId(), menuCommande);	
	tbTableau:AddSeparator();
	
	btnMenuRAZ = tbTableau:AddTool("Menu des RAZ", "./res/32x32_journal.png",'', itemKind.DROPDOWN);
	tbTableau:AddSeparator();
	btnOrder = tbTableau:AddTool("Trier le tableau", "./res/32x32_bib.png");
	tbTableau:AddSeparator();
	
	menuRAZ = menu.Create();
	btnRAZRang = menuRAZ:Append({label="RAZ des rangs", image ="./res/32x32_clear.png"});
	menuRAZ:AppendSeparator();
	btnRAZGroupe = menuRAZ:Append({label="RAZ des groupes", image ="./res/32x32_clear.png"});
	menuRAZ:AppendSeparator();
	btnRAZAll = menuRAZ:Append({label="RAZ des deux", image ="./res/32x32_clear.png"});
	menuRAZ:AppendSeparator();
	btnRAZDossard = menuRAZ:Append({label="RAZ des dossards", image ="./res/32x32_clear.png"});
	menuRAZ:AppendSeparator();
	btnRAZDossardSel = menuRAZ:Append({label="RAZ des dossards pour les lignes sélectionnées", image ="./res/32x32_clear.png"});
	tbTableau:SetDropdownMenu(btnMenuRAZ:GetId(), menuRAZ);
	tbTableau:AddSeparator();

	btnMenuSend = tbTableau:AddTool("Envois", "./res/32x32_send.png",'', itemKind.DROPDOWN);
	menuSend = menu.Create();
	btnSendParticipants = menuSend:Append({label="Envoi des participants", image ="./res/32x32_send.png"});
	menuSend:AppendSeparator();
	btnSendTableau = menuSend:Append({label="Envoi du tableau à la FIS", image ="./res/32x32_send.png"});
	menuSend:AppendSeparator();
	btnSendDossards = menuSend:Append({label="Envoi de tous les dossards", image ="./res/32x32_send.png"});
	menuSend:AppendSeparator();
	btnSendStartList = menuSend:Append({label="Envoi de la liste de départ", image ="./res/32x32_send.png"});
	menuSend:AppendSeparator();
	tbTableau:SetDropdownMenu(btnMenuSend:GetId(), menuSend);
	tbTableau:AddSeparator();

	btnValider = tbTableau:AddTool("Validations", "./res/32x32_send.png",'', itemKind.DROPDOWN);
	menuValider = menu.Create();
	btnValiderSelection = menuValider:Append({label="Validation des coureurs filtrés", image ="./res/32x32_down.png"});
	menuValider:AppendSeparator();
	btnValiderCoureurs = menuValider:Append({label="Validation globale des coureurs", image ="./res/32x32_dialog_ok.png"});
	menuValider:AppendSeparator();
	btnInValiderSelection = menuValider:Append({label="Invalider les coureurs filtrés", image ="./res/32x32_close.png"});
	menuValider:AppendSeparator();
	btnInvaliderCoureurs = menuValider:Append({label="Revenir au statut Non Validé", image ="./res/32x32_dialog_ko.png"});
	menuValider:AppendSeparator();
	tbTableau:SetDropdownMenu(btnValider:GetId(), menuValider);
	tbTableau:AddSeparator();

	btnMenuPrint = tbTableau:AddTool("Impressions", "./res/32x32_printer.png",'', itemKind.DROPDOWN);
	menuPrint = menu.Create();
	menuPrint:AppendSeparator();
	btnPrintDoubleTirageBibo = menuPrint:Append({label="Impression du double tirage du BIBO", image ="./res/32x32_printer.png"});
	menuPrint:AppendSeparator();
	btnPrintEtiquettesAlpha = menuPrint:Append({label="Impression des étiquettes par ordre alphabétique", image ="./res/32x32_printer.png"});
	menuPrint:AppendSeparator();
	btnPrintEtiquettesNation = menuPrint:Append({label="Impression des étiquettes par Nation", image ="./res/32x32_printer.png"});
	menuPrint:AppendSeparator();
	btnPrintEtiquettesParpoints = menuPrint:Append({label="Impression des étiquettes par Points", image ="./res/32x32_printer.png"});
	menuPrint:AppendSeparator();
	btnPrintTableau = menuPrint:Append({label="Impression du tableau des coureurs", image ="./res/32x32_printer.png"});
	menuPrint:AppendSeparator();
	btnPrintNation = menuPrint:Append({label="Impression des coureurs par Nation", image ="./res/32x32_printer.png"});
	menuPrint:AppendSeparator();
	btnPrintFinale = menuPrint:Append({label="Qualifiés pour les finales", image ="./res/32x32_printer.png"});
	menuPrint:AppendSeparator();
	btnPrintFeuilleTirage = menuPrint:Append({label="Impression de la feuille de tirage", image ="./res/32x32_printer.png"});
	menuPrint:AppendSeparator();
	btnPrintTop75 = menuPrint:Append({label="Impression du TOP 75 en points FIS", image ="./res/32x32_printer.png"});
	menuPrint:AppendSeparator();
	tbTableau:SetDropdownMenu(btnMenuPrint:GetId(), menuPrint);
	tbTableau:AddSeparator();

	btnOutils = tbTableau:AddTool("Outils", "./res/32x32_tools.png",'', itemKind.DROPDOWN);
	menuOutils = menu.Create();
	menuOutils:AppendSeparator();
	btnTirageDossardsBIBO = menuOutils:Append({label="Double tirage à la mêlée du BIBO", image ="./res/32x32_bib.png"});
	menuOutils:AppendSeparator();
	btnTirageDossardsRestants = menuOutils:Append({label="Tirage des dossards restants (avec points)", image ="./res/32x32_bib.png"});
	menuOutils:AppendSeparator();
	btnTirageDossardsSansPoints = menuOutils:Append({label="Double tirage à la mêlée (sans points)", image ="./res/32x32_bib.png"});
	menuOutils:AppendSeparator();
	btnTirageVitesse1530 = menuOutils:Append({label="Double tirage à la mêlée des coureurs du groupe 2 en Vitesse", image ="./res/32x32_bib.png"});
	menuOutils:AppendSeparator();
	btnWeb = menuOutils:Append({label="Vers la page FIS de la course", image ="./res/32x32_fis.png"});
	menuOutils:AppendSeparator();
	btnDocs = menuOutils:Append({label="Vers la page FIS des documents alpins", image ="./res/32x32_fis.png"});
	menuOutils:AppendSeparator();
	btnDecalerBas = menuOutils:Append({label="Décaler les rangs de tirage de +1", image ="./res/32x32_list_add.png"});
	menuOutils:AppendSeparator();
	btnDecalerHaut = menuOutils:Append({label="Décaler les rangs de tirage de -1", image ="./res/32x32_list_remove.png"});
	menuOutils:AppendSeparator();
	btnDecalerGroupeBas = menuOutils:Append({label="Décaler les groupes de tirage de +1", image ="./res/32x32_down.png"});
	menuOutils:AppendSeparator();
	btnDecalerGroupeHaut = menuOutils:Append({label="Décaler les groupes de tirage de -1", image ="./res/32x32_up.png"});
	menuOutils:AppendSeparator();
	btnExporter = menuOutils:Append({label="Exporter le tableau (fichier csv)", image ="./res/32x32_csv.png"});
	menuOutils:AppendSeparator();
	btnGetECSL = menuOutils:Append({label="Charger un fichier csv ECSL", image ="./res/32x32_startlist.png"});
	menuOutils:AppendSeparator();
	btnGetWCSL = menuOutils:Append({label="Charger un fichier csv WCSL", image ="./res/32x32_startlist.png"});
	menuOutils:AppendSeparator();
	btnAideCE = menuOutils:Append({label="Aide / ranking en CE", image ="./res/32x32_ranking.png"});
	menuOutils:AppendSeparator();
	tbTableau:SetDropdownMenu(btnOutils:GetId(), menuOutils);

	tbTableau:AddSeparator();
	btnClose = tbTableau:AddTool("Quitter", "./res/32x32_exit.png");

	tbTableau:AddStretchableSpace();
 	tbTableau:Realize();

	tbTableau:EnableTool(btnMenuSend:GetId(), draw.state);
	tbTableau:EnableTool(btnSendMessage:GetId(), draw.state);
	
	menuCommande:Enable(btnClear:GetId(), draw.state) ;
	menuCommande:Enable(btn_reset_socket:GetId(), draw.state) ;
	
	-- if not draw.row_selected or draw.row_selected == 0 then
		-- menuOutils:Enable(btnTirageDossardsRestants:GetId(), false);
		-- menuOutils:Enable(btnDecalerBas:GetId(), false);
		-- menuOutils:Enable(btnDecalerHaut:GetId(), false);
		-- menuOutils:Enable(btnDecalerGroupeBas:GetId(), false);
		-- menuOutils:Enable(btnDecalerGroupeHaut:GetId(), false);
	-- end
	menuOutils:Enable(btnTirageVitesse1530:GetId(), false);
	if draw.bolVitesse then
		if draw.bolEstCE or draw.bolEstNC == true then
			menuOutils:Enable(btnTirageVitesse1530:GetId(), true);
		end
	end
	ChecktDraw();
	if not draw.bolEstCE then
		menuPrint:Enable(btnPrintTop75:GetId(), false);
	else
		if nodelivedraw:HasAttribute('ECSL_'..draw.code_evenement) then
			local path = nodelivedraw:GetAttribute('ECSL_'..draw.code_evenement);
			if app.FileExists(path) then
				ChargeECSL(path);
			else
				nodelivedraw:DeleteAttribute('ECSL_'..draw.code_evenement);
				draw.doc:SaveFile();
			end
		end
		if nodelivedraw:HasAttribute('WCSL_'..draw.code_evenement) then
			local path = nodelivedraw:GetAttribute('WCSL_'..draw.code_evenement);
			if app.FileExists(path) then
				ChargeWCSL(path);
			else
				nodelivedraw:DeleteAttribute('WCSL_'..draw.code_evenement);
				draw.doc:SaveFile();
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

	dlgTableau:Bind(eventType.MENU, OnResetSocket, btn_reset_socket);
	dlgTableau:Bind(eventType.MENU, OnLiveState, btnState);
	dlgTableau:Bind(eventType.MENU, OnLiveState, btnMenuCommande);
	dlgTableau:Bind(eventType.MENU, OnSendMessage, btnSendMessage);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.skip_question = false;
			OnRAZData('Dossard')
			SendMessage('Board refreshed');
		end, btnRAZDossard);
		
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local rows = grid_tableau:GetSelectedRows();
			for i = 1, #rows do
				tDraw:SetCellNull('Dossard', rows[i]);
			end
			RefreshGrid();
			if draw.state == true then
				local msg = "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.";
				if dlgTableau:MessageBox(
					msg, "Renvoi des dossards",
					msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
				end
				CommandRenvoyerDossards(false);
			end
		end
	, btnRAZDossardSel);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.skip_question = false;
			OnRAZData('Rang_tirage')
		end, btnRAZRang);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.skip_question = false;
			OnRAZData('Groupe_tirage')
		end, btnRAZGroupe);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.skip_question = false;
			OnRAZData('All')
		end, btnRAZAll);
	dlgTableau:Bind(eventType.MENU, OnPrintBibo, btnPrintFeuilleTirage);
	dlgTableau:Bind(eventType.MENU, OnPrintTop75, btnPrintTop75);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			tDraw:OrderBy('Rang_tirage');
			draw.print_alone = true;
			OnPrintDoubleTirage(1);
			if not draw.bolVitesse then
				if draw.bolEstCE or draw.code_niveau == 'NC' then
					OnPrintDoubleTirage(2);
				end
			end
			report = nil;
		end, btnPrintDoubleTirageBibo);
		
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
			if draw.bolEstCE then
				OnPrintEtiquettes(draw.orderbyCE);
			else
				OnPrintEtiquettes(draw.orderbyFIS);
			end
		end, btnPrintEtiquettesParpoints);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			if draw.bolEstCE then
				OnPrintTableau(draw.orderbyCE);
			else
				OnPrintTableau(draw.orderbyFIS);
			end
		end, btnPrintTableau);
		
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			OnPrintNation();
		end, btnPrintNation);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			OnPrintFinale();
		end, btnPrintFinale);

	dlgTableau:Bind(eventType.MENU, OnAide, btnAideCE);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.skip_question = false;
			OnOrder();
		end, btnOrder);
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
			OnReset()
		end
		, btnClear);
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
			bolSendDrawOrder = true;
			OnSendTableau(bolSendDrawOrder);
			SendMessage('Board refreshed');
		end
		, btnValiderSelection);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			bolSendDrawOrder = true;
			CommandSendStartList();
		end
		, btnSendStartList);
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
			bolSendDrawOrder = true;
			OnSendTableau(bolSendDrawOrder);
			SendMessage('Board refreshed');
		end
		, btnInValiderSelection);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			bolSendDrawOrder = true;
			OnSendTableau(bolSendDrawOrder)
			SendMessage('Draw available');
		end
		, btnSendTableau);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			bolSendDrawOrder = false;
			OnSendTableau(bolSendDrawOrder)
			SendMessage('Participants list');
		end
		, btnSendParticipants);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local msg = "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.";
			if dlgTableau:MessageBox(
				msg, "Renvoi des dossards",
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
			end
			CommandRenvoyerDossards(false);
			SendMessage('Draw in progress');
		end
		, btnSendDossards);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			-- les coureurs sont du groupe de tirage 1
			ChecktDraw();
			if draw.bolTirageBiboFait == true then
				local msg = "Les dossards du BIBO ont déjà été tirés !!!";
				dlgTableau:MessageBox(msg, "Erreur", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			local msg = "Cliquer sur Oui pour lancer le double tirage du BIBO.\n"..
					"Les coureurs doivent être validés sur le tableau au préalable.\n\n"..
					"Vous pourrez retrouver cette édition dans les impressions\n\n"..
					"S'il existe deux sous-groupes (1-7 et 8-15), les deux tirages sont indépendants.";
			if dlgTableau:MessageBox(
				msg, "Attribution des dossards",
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
			end
			if draw.statut == 'UF' then
				local msg = "Tous les coureurs n'on pas été Validés !!!";
				dlgTableau:MessageBox(msg, "Erreur", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			base:Query('Delete From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement);
			draw.start_Bib = nil;
			tDrawG6 = tDraw:Copy();
			tDrawG6:OrderBy('Rang_tirage');
			ReplaceTableEnvironnement(tDrawG6, '_DrawG6');
			for i = tDrawG6:GetNbRows() -1, 0, -1 do -- traitement du groupe 1
				if tDrawG6:GetCellInt('Groupe_tirage', i) ~= 1 then
					tDrawG6:RemoveRowAt(i);
				end
			end
			params.nb_groupe1 = tDrawG6:GetNbRows();
			BuildTableTirage(1, tDrawG6:GetNbRows() - 1);
			OnPrintDoubleTirage(1);
			if not draw.bolVitesse then
				if draw.bolEstCE or draw.code_niveau == 'NC' then
					tDrawG6 = tDraw:Copy();
					ReplaceTableEnvironnement(tDrawG6, '_DrawG6');
					tDrawG6:OrderBy('Rang_tirage');
					for i = tDrawG6:GetNbRows() -1, 0, -1 do
						if tDrawG6:GetCellInt('Groupe_tirage', i) ~= 2 then
							tDrawG6:RemoveRowAt(i);
						end
					end
					BuildTableTirage(params.nb_groupe1 + 1, tDrawG6:GetNbRows() -1);
					OnPrintDoubleTirage(2);
				end
			end
			draw.print_alone = true;
			ChecktDraw()
			draw.bolTirageBiboFait = true;
			if draw.state == true then
				local msg = "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.";
				if dlgTableau:MessageBox(
					msg, "Renvoi des dossards",
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
			ChecktDraw();
			if draw.statut == 'UF' then
				local msg = "Tous les coureurs n'on pas été Validés !!!";
				dlgTableau:MessageBox(msg, "Erreur", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			if not draw.row_selected then
				local msg = "Veuillez selectionner la ligne à partir de laquelle\nvous allez tirer les dossards.";
				dlgTableau:MessageBox(msg, "Erreur", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			SetRangEgal();
			for i = draw.row_selected, tDraw:GetNbRows() -1 do
				if tDraw:GetCellDouble('FIS_pts', i, -1) < 0 then
					break;
				end
				if tDraw:GetCell('Pts_info', i) ~= '=' then				
					local dossard = tDraw:GetCellInt('Dossard', i);
					local rang_tirage = tDraw:GetCellInt('Rang_tirage', i);
					local groupe_tirage = tDraw:GetCellInt('Groupe_tirage', i);
					local code_coureur = tDraw:GetCell('Code_coureur', i);
					if dossard == 0 then
						dossard = rang_tirage;
						tDraw:SetCell('Dossard', i, dossard);
						local cmd = "Update Resultat Set Dossard = "..dossard..", Critere = '"..string.format('%03d', rang_tirage).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
						base:Query(cmd);
					end
				end
			end
			RefreshGrid()
			-- CommandRenvoyerDossards(false);
			ChecktDraw()
			draw.bolTirageAvecPointFait = true;
			if draw.state == true then
				local msg = "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.";
				if dlgTableau:MessageBox(
					msg, "Renvoi des dossards",
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
			local dossards_tires = SetDossardsAvailable();
			if dossards_tires == false then
				local msg = "Tous les dossards du Groupe 1 n'ont pas été attribués.";
				dlgTableau:MessageBox(
					msg, "Attribution des dossards",
					msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				return;
			end
			local msg = "Cliquer sur Oui pour lancer l'attribution\n"..
					"des dossards pour les coureurs du groupe 2 en vitesse.\n"..
					"Les coureurs doivent être validés sur le tableau au préalable.";
			if dlgTableau:MessageBox(
				msg, "Attribution des dossards",
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
			end
			if draw.statut == 'UF' then
				local msg = "Tous les coureurs n'ont pas été Validés !!!";
				dlgTableau:MessageBox(msg, "Erreur", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			tDrawG6 = tDraw:Copy();
			ReplaceTableEnvironnement(tDrawG6, '_DrawG6');
			local filter = "$(Groupe_tirage):In(2)";
			tDrawG6:Filter(filter, true);
			if tDrawG6:GetNbRows() > 0 then
				tDrawG6:OrderRandom('Groupe_tirage');
				tDrawG6:OrderRandom('Groupe_tirage');
				local tShuffle = {};
				for i = 0, tDrawG6:GetNbRows() -1 do
					local bib = 0;
					for idx = 1, #draw.tDossardsAvailable do
						if draw.tDossardsAvailable[idx].Pris == 0 then
							bib = draw.tDossardsAvailable[idx].Dossard;
							draw.tDossardsAvailable[idx].Pris = 1;
							break;
						end								
					end
					table.insert(tShuffle, bib);
				end
				tShuffle = Shuffle(tShuffle, true);
				for i = 0, tDrawG6:GetNbRows() -1 do
					local valeur_shuffle = tShuffle[i+1];
					local dossard = valeur_shuffle ;
					local code_coureur = tDrawG6:GetCell('Code_coureur', i)
					local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
					-- adv.Alert('avant set dossard');
					tDraw:SetCell('Dossard', r, dossard);
					table.remove(draw.tDossardsAvailable, 1);
					local cmd = "Update Resultat Set Dossard = "..dossard..", Critere = '"..string.format('%03d', tDrawG6:GetCellInt('Rang_tirage', i)).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
					base:Query(cmd);
				end
			end
			ChecktDraw()
			if draw.state == true then
				local msg = "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.";
				if dlgTableau:MessageBox(
					msg, "Renvoi des dossards",
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
			if draw.statut == 'UF' then
				local msg = "Tous les coureurs n'ont pas été Validés !!!";
				dlgTableau:MessageBox(msg, "Erreur", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			SetRangsPtsNull();
			if #draw.tRangsPtsNull > 0 then
				OnTirageRangsPtsNull(draw.tRangsPtsNull[#draw.tRangsPtsNull]);
				draw.bolTirageSansPointFait = true;
			end
			RefreshGrid();
			if draw.state == true then
				local msg = "Cliquer sur Oui pour Renvoyer tous les dossards à la FIS.";
				if dlgTableau:MessageBox(
					msg, "Renvoi des dossards",
					msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
				) ~= msgBoxStyle.YES then
					return;
				end
				CommandRenvoyerDossards();
			end
			-- ChecktDraw()
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
			ChecktDraw();
			local ligne = CheckDossardAfter();
			if ligne > 0 then
				local msg = "Opération impossible, un dossard a déjà été tiré\nà la ligne "..ligne;
				dlgTableau:MessageBox(
					msg, "Décalage des rangs de tirage", 
					msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				return;
			end
			local msg = "Voulez-vous décaler les rangs de tirage de +1\n"..
						"à partir de la ligne "..(draw.row_selected + 1).." ?";
			if dlgTableau:MessageBox(
				msg, "Décalage des rangs de tirage", 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				OnDecaler(draw.row_selected, true, false);
			end
		end, btnDecalerBas);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			local msg = "Voulez-vous décaler les rangs de tirage de -1\n"..
						"à partir de la ligne sélectionnée ?";
			if dlgTableau:MessageBox(
				msg, "Décalage des rangs de tirage", 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				local rowsSelected = grid_tableau:GetSelectedRows();
				local row = rowsSelected[1]; 
				OnDecaler(row, false, false);
			end
		end, btnDecalerHaut);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			local msg = "Voulez-vous décaler les groupes de tirage de +1\n"..
						"à partir de la ligne sélectionnée ?";
			if dlgTableau:MessageBox(
				msg, "Décalage des groupes de tirage", 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				local rowsSelected = grid_tableau:GetSelectedRows();
				local row = rowsSelected[1]; 
				OnDecaler(row, true, true);
			end
		end, btnDecalerGroupeBas);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			local msg = "Voulez-vous décaler les groupes de tirage de -1\n"..
						"à partir de la ligne sélectionnée ?";
			if dlgTableau:MessageBox(
				msg, "Décalage des groupes de tirage", 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				local rowsSelected = grid_tableau:GetSelectedRows();
				local row = rowsSelected[1]; 
				OnDecaler(row, false, true);
			end
		end, btnDecalerGroupeHaut);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			if tDraw:GetNbRows() > 0 then
				OnExport();
			end
		end, btnExporter);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ReadECSL();
		end, btnGetECSL);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ReadWCSL();
		end, btnGetWCSL);

	dlgTableau:Bind(eventType.GRID_FILTER_CHANGED, 
		function(evt)
			if grid_tableau:GetTableSrc():GetNbRows() == grid_tableau:GetTableView():GetNbRows() then
				RefreshGrid(true);	-- on est sur la source
			else
				RefreshGrid(false);	-- on est sur la vue
			end
		end
		, dlgTableau:GetWindowName('tableau'));
		
	dlgTableau:Bind(eventType.TEXT, 
		function(evt)
			if draw.bolEstCE and not draw.tECSL then
				local msg = "Veuillez charger le fichier ECSL (.csv) en premier.";
				app.GetAuiFrame():MessageBox(msg, "ATTENTION !! ", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				return;
			end
			local code_coureur = dlgTableau:GetWindowName('code'):GetValue();
--  		return nom, prenom, sexe, an, nation, comite, club, pts, rank, pts_VIT, rank_VIT;
			local nom, prenom, sexe, an, nation, comite, club, points, classement, _, _ = OnChercheCoureurCode(code_coureur);
			dlgTableau:GetWindowName('nom'):SetValue(nom);
			dlgTableau:GetWindowName('prenom'):SetValue(prenom);
			dlgTableau:GetWindowName('an'):SetValue(an);
			dlgTableau:GetWindowName('nation'):SetValue(nation);
			dlgTableau:GetWindowName('points'):SetValue(points);
			dlgTableau:GetWindowName('classement'):SetValue(classement);
			if dlgTableau:GetWindowName('sexe') then
				dlgTableau:GetWindowName('sexe'):SetValue(sexe);
			end
			if dlgTableau:GetWindowName('comite') ~= nil then
				dlgTableau:GetWindowName('comite'):SetValue(comite);
			end
			if dlgTableau:GetWindowName('club') ~= nil then
				dlgTableau:GetWindowName('club'):SetValue(club);
			end
		end
		, dlgTableau:GetWindowName('code'));

	dlgTableau:Bind(eventType.TEXT, 
		function(evt)
			if draw.bolEstCE and not draw.tECSL then
				local msg = "Veuillez charger le fichier ECSL (.csv) en premier.";
				app.GetAuiFrame():MessageBox(msg, "ATTENTION !! ", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				return;
			end
			draw.cherche_nom = dlgTableau:GetWindowName('nom'):GetValue();
			if draw.cherche_nom:len() == 0 then
				if panel_coureur then
					panel_coureur:Close();
				end
			end
			draw.cherche_prenom = draw.cherche_prenom or '';
			draw.cherche_coureur = "Select * From Coureur Where Code_coureur Like 'FIS%' And Nom Like '"..draw.cherche_nom.."%' And Prenom Like '"..draw.cherche_prenom.."%' and Sexe = '"..draw.sexe.."' Order By Nom, Prenom";
			base:TableLoad(tCoureur, draw.cherche_coureur);
			draw.code_coureur = nil;
			if not panel_coureur and draw.cherche_nom:len() > 0 then
				CreatePanelCoureur()
			end
			if tCoureur:GetNbRows() > 0 then
				grid_coureur:SynchronizeRows();
			end
		end
		, dlgTableau:GetWindowName('nom'));

	dlgTableau:Bind(eventType.TEXT, 
		function(evt)
			if draw.bolEstCE and not draw.tECSL then
				local msg = "Veuillez charger le fichier ECSL (.csv) en premier.";
				app.GetAuiFrame():MessageBox(msg, "ATTENTION !! ", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
				return;
			end
			draw.cherche_prenom = dlgTableau:GetWindowName('prenom'):GetValue();
			if draw.cherche_prenom:len() == 0 then
				if panel_coureur then
					panel_coureur:Close();
				end
			end
			draw.cherche_nom = draw.cherche_nom or '';
			draw.cherche_coureur = "Select * From Coureur Where Code_coureur Like 'FIS%' And Nom Like '"..draw.cherche_nom.."%' And Prenom Like '"..draw.cherche_prenom.."%' and Sexe = '"..draw.sexe.."' Order By Nom, Prenom";
			base:TableLoad(tCoureur, draw.cherche_coureur);
			draw.code_coureur = nil;
			if not panel_coureur and draw.cherche_prenom:len() > 0  then
				CreatePanelCoureur()
			end
			if tCoureur:GetNbRows() > 0 then
				grid_coureur:SynchronizeRows();
			end
		end
		, dlgTableau:GetWindowName('prenom'));

	dlgTableau:Bind(eventType.BUTTON, 
		function(evt)
			local fiscode = 'FIS'..dlgTableau:GetWindowName('code'):GetValue();
			local r = tDraw:GetIndexRow('Code_coureur', fiscode);
			if r > -1 then
				local msg = 'Ce coureur est déjà présent dans la course !!!';
				app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
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
				tDraw:SetCellNull('Critere', i);
			end
			RefreshGrid();
			ChecktDraw();
			if dlgTableau:GetWindowName('nom'):GetValue():len() > 0 then
				OnAjouterCoureur();
			end
		end
		, dlgTableau:GetWindowName('ajouter'));
		
	dlgTableau:Bind(eventType.MENU, 
		function(evt) 
			OnClose()
			dlgTableau:EndModal(idButton.CANCEL);
		 end,  btnClose);

	dlgTableau:ShowModal();
end

function main(params_c)
	draw = {};
	params = {};
	draw.code_evenement = params_c.code_evenement or -1;
	if draw.code_evenement < 0 then
		return;
	end
	draw.width = display:GetSize().width;
	draw.height = display:GetSize().height - 30;
	draw.x = 0;
	draw.y = 0;
	scrip_version = "5.6"; -- 4.92 pour 2022-2023
	local imgfile = './res/40x16_dbl_coche.png';
	if not app.FileExists(imgfile) then
		app.GetAuiFrame():MessageBox(
			"Vous devez télécharger une image supplémentaire.\nLe script va se fermer automatiquement.", 
			"Téléchargement d'une image supplémentaire",
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
			local reponse = app.AutoUpdateResource('https://agilsport.fr/bta_alpin/UpdateScript.zip');
			return true;
	end
	if app.GetVersion() >= '5.0' then 
		-- vérification de l'existence d'une version plus récente du script.
		-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2
		indice_return = 1;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	else
		app.GetAuiFrame():MessageBox(
			"Vous devez mettre à jour le logiciel avec\nla dernière version stable (téléchargement -> Logiciel).", 
			"Mise à jour du logiciel",
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
	draw.hostname = 'live.fisski.com';
	draw.method = 'socket';
	draw.ajouter_code = '';
	draw.directory = app.GetPath()..'/live_draw/';
	if not app.DirExists(draw.directory) then
		app.Mkdir(draw.directory);
	end
	base = base or sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	tResultat = base:GetTable('Resultat');
	tEpreuve = base:GetTable('Epreuve');
	tPistes = base:GetTable('Pistes');
	tNation = base:GetTable('Nation');
	tResultat_Info_Tirage = base:GetTable('Resultat_Info_Tirage');
	if tResultat_Info_Tirage == nil then
		CreateTableResultat_Info_Tirage();
	else
		if tResultat_Info_Tirage:GetIndexColumn("Pts_info") < 0 then
			local cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN TG CHAR(10) NULL";
			base:Query(cmd);
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN Racer_info CHAR(10) NULL";
			base:Query(cmd);
			cmd = "ALTER TABLE Resultat_Info_Tirage ADD COLUMN Pts_info CHAR(3) NULL";
			base:Query(cmd);
			app.GetAuiFrame():MessageBox(
				"La base de donnée a nécessité la modification d'une table'.\nLe script va se fermer automatiquement.\nVous devrez quitter complètement skiFFS et relancer le programme.", 
				"Téléchargement d'une image supplémentaire",
				msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
			return true;
		end
	end
	tResultat_Info_Bibo = base:GetTable('Resultat_Info_Bibo');
	tCoureur = base:GetTable('Coureur');
	tCategorie = base:GetTable('Categorie');
	tClassement_Coureur = base:GetTable('Classement_Coureur');
	tEpreuve_Alpine_Manche = base:GetTable('Epreuve_Alpine_Manche');
	tResultat_Info_Tirage = base:GetTable('Resultat_Info_Tirage');
	if tResultat_Info_Bibo == nil then
		CreateTableResultat_Info_Bibo();
	end
	tResultat_Info_Bibo = base:GetTable('Resultat_Info_Bibo');
	
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..draw.code_evenement);
	
	draw.code_entite = tEvenement:GetCell("Code_entite",0);
	draw.code_activite = tEvenement:GetCell("Code_activite",0);
	if draw.code_activite ~= 'ALP' or draw.code_entite ~= 'FIS' then
		local msg = "L'environnement ne permet pas la mise \nen ligne du tableau des coureurs\nsur le site de la FIS !!";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
		return;
	end
	
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..draw.code_evenement);
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..draw.code_evenement);
	base:TableLoad(tEpreuve_Alpine_Manche, 'Select * From Epreuve_Alpine_Manche Where Code_evenement = '..draw.code_evenement);
	draw.code_piste = tEpreuve_Alpine_Manche:GetCellInt('Code_piste', 0);
	base:TableLoad(tPistes, "Select * From Pistes Where Code_activite = 'ALP' And Matricule = "..draw.code_piste);
	-- création des tables pour le double tirage des dossards
	tTableTirage1 = sqlTable.Create('_TableTirage1');
	tTableTirage1:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage1, '_TableTirage1');
	tTableTirage2 = sqlTable.Create('_TableTirage2');
	tTableTirage2:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage2, '_TableTirage2');
	
	draw.code_liste = tEvenement:GetCellInt("Code_liste", 0)
	draw.code_niveau = tEpreuve:GetCell('Code_niveau', 0);
	draw.code_regroupement = tEpreuve:GetCell('Code_regroupement', 0);
	draw.sexe = tEpreuve:GetCell('Sexe', 0);
	draw.bolEstCE = false;
	draw.bolEstNC = false;
	
	tOuiNon = sqlTable.Create('_OuiNon');
	tOuiNon:AddColumn({ name = 'Choix', label = 'Choix', type = sqlType.CHAR , width = 3});
	local row = tOuiNon:AddRow()
	tOuiNon:SetCell('Choix', row , 'Oui');
	local row = tOuiNon:AddRow()
	tOuiNon:SetCell('Choix', row , 'Non');
	ReplaceTableEnvironnement(tOuiNon, '_OuiNon')

	if draw.code_niveau == 'EC' or draw.code_regroupement == 'CE' then
		draw.bolEstCE = true;
	end
	if tEpreuve:GetCell("Code_regroupement", 0) == 'F' then
		draw.bolEstNC = true;
	end
	draw.code_saison = tEvenement:GetCell("Code_saison", 0);
	draw.discipline = tEpreuve:GetCell('Code_discipline', 0);
	draw.bolVitesse = false;
	if draw.discipline:In('DH','TRA','SG') then
		draw.bolVitesse = true;
	end
	if not draw.bolVitesse then
		draw.orderbyCE = 'Rang_tirage, Groupe_tirage, ECSL_points DESC, WCSL_points DESC, ECSL_overall_points DESC, Winner_CC DESC, FIS_pts, Nom, Prenom';
	else
		draw.orderbyCE = 'Rang_tirage, Groupe_tirage, ECSL_points DESC, WCSL_points DESC, ECSL_overall_points DESC, Winner_CC DESC, FIS_pts, Nom, Prenom';
	end
	draw.orderbyFIS = 'Rang_tirage, Groupe_tirage, FIS_pts, Nom, Prenom';
	draw.code_grille_categorie = tEpreuve:GetCell("Code_grille_categorie", 0);

	draw.codex = string.sub(tEvenement:GetCell("Codex", 0),4);
	draw.codex = draw.codex:Split("%.");
	if #draw.codex == 1 then
		local msg = "Veuillez rectifier le CODEX FIS de la course.\n"..
					"Exemple d'un CODEX FIS : FRA1234.x ou x représente\n"..
					"le numéro d'identification de délégué technique FIS.";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
		return;
	end
	draw.codex = draw.codex[1];
	draw.web = 'http://live.fis-ski.com/lv-al'..draw.codex:sub(4)..'.htm';
	draw.code_manche = 1;
	draw.type_classement = 'IA'..tEpreuve:GetCell('Code_discipline', 0);
	
	if tEpreuve:GetCell("Sexe", 0) == "M" then
		draw.port = '1550';
	else
		draw.port = '1551';
	end
	-- Ouverture Document XML 
	draw.doc = app.GetXML();
	draw.docRoot = draw.doc:GetRoot();
	nodelivedraw = draw.doc:FindFirst('main/livedraw');
	if not nodelivedraw then
		nodelivedraw = xmlNode.Create(draw.docRoot, xmlType.ELEMENT_NODE, "livedraw");
		nodelivedraw:ChangeAttribute('port', draw.port);
		nodelivedraw:ChangeAttribute('pwd', '');
	else
		draw.sequence_send = tonumber(nodelivedraw:GetAttribute('send', 0)) or 0;;
		draw.sequence_ack = tonumber(nodelivedraw:GetAttribute('ack', 0)) or 0;
		draw.sequence_last_send = draw.sequence_send;
	end
	local pwdfile = './process/liveDrawPwd.txt';
	if app.FileExists(pwdfile) then
		local f = io.open(pwdfile, 'r')
		for lines in f:lines() do
			draw.pwd = lines;
		end
		io.close(f);
	end
	local date_jour = os.date("%Y-%m-%d");
	local date_epreuve = tEpreuve:GetCell('Date_epreuve', 0, "%4Y-%2M-%2D");
	local attribute = nodelivedraw:GetAttributes();
	while attribute ~= nil do
		local name = attribute:GetName();
		local pos1, pos2 = string.find(name, 'ECSL_');
		if pos1 and pos1 > 0 then
			local code_evenement = tonumber(string.sub(name, pos2 + 1)) or 0;
			if code_evenement > 0 then
				if date_jour > date_epreuve then
					nodelivedraw:DeleteAttribute(name);
				end
			end
		end
		pos1, pos2 = string.find(name, 'WCSL_');
		if pos1 and pos1 > 0 then
			local code_evenement = tonumber(string.sub(name, pos2 + 1)) or 0;
			if code_evenement > 0 then
				if date_jour > date_epreuve then
					nodelivedraw:DeleteAttribute(name);
				end
			end
		end
		attribute = attribute:GetNext();
	end
	draw.sequence_ack = draw.sequence_ack or 0;
	draw.sequence_send = draw.sequence_send or 0;
	draw.targetName = draw.hostname..':'..draw.port;
	draw.web = 'live.fis-ski.com/lv-'..string.lower(string.sub(draw.code_activite,1,2))..draw.codex..'.htm';
	draw.state = false;
	draw.double_tirage_bibo = false;
	draw.tModifs_tableau = {};
	draw.raz_sequence = false;
	
	draw.CE = 'N';
	if draw.bolEstCE then
		draw.CE = 'O';
	end
	dlgConfig = wnd.CreateDialog(
		{
		width = draw.width,
		height = draw.height,
		x = draw.x,
		y = draw.y,
		label='Informations de connexion - version du script : '..scrip_version , 
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
	local btnSave = tbconfig:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	local btnSOS = tbconfig:AddTool("Mode d'emploi du sript", "./res/32x32_sos.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	local message = app.GetAuiMessage();
	local titre = 'TIRAGE DES DOSSARDS EN LIGNE SUR LE SITE DE LA FIS\n\nCourse : '..tEvenement:GetCell('Nom', 0)
	dlgConfig:GetWindowName('race_name'):SetValue(titre);
	dlgConfig:GetWindowName('codex'):SetValue(tEvenement:GetCell('Codex', 0));
	dlgConfig:GetWindowName('fis_hostname'):SetValue('live.fisski.com');
	dlgConfig:GetWindowName('fis_port'):SetValue(draw.port);
	dlgConfig:GetWindowName('fis_pwd'):SetValue(draw.pwd);
	if draw.bolEstCE then
		dlgConfig:GetWindowName('finale_ce'):SetTable(tOuiNon, 'Choix', 'Choix');
		dlgConfig:GetWindowName('finale_ce'):SetValue('Non');
	end
	
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			draw.pwd = dlgConfig:GetWindowName('fis_pwd'):GetValue();
			local filename = './process/liveDrawPwd.txt';
			local f = io.open(filename, 'w')
			f:write(draw.pwd);
			f:close();
			nodelivedraw:ChangeAttribute('port', dlgConfig:GetWindowName('fis_port'):GetValue());
			nodelivedraw:ChangeAttribute('send', 0);
			nodelivedraw:ChangeAttribute('ack', 0);
			draw.doc:SaveFile();
			draw.finale_ce = 'Non';
			if dlgConfig:GetWindowName('finale_ce') then
				draw.finale_ce = dlgConfig:GetWindowName('finale_ce'):GetValue();
			end
			dlgConfig:EndModal(idButton.OK) 
		end, btnSave); 
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			if draw.doc then
				draw.doc:SaveFile();
			end
			OnClose();
			dlgConfig:EndModal(idButton.CANCEL) 
		 end,  btnClose);
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			app.LaunchDefaultEditor('./process/LiveDrawHelp.rtf');
		 end,  btnSOS);

	if dlgConfig:ShowModal() == idButton.OK then
		local cmd = "Update Resultat Set Critere = NULL, Groupe = NULL Where Code_evenement = "..draw.code_evenement;
		base:Query(cmd);
		OnAfficheTableau();
	end
end

