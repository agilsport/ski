-- LIVE Draw 
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
--[[
groupe 1 ECSL de la discipline : de 1 à 15 (ou plus)
groupe 2 Si plus de 450 pts en EC la saison dernière de 16 à x
groupe 2 on met en plus dans ce groupe les coureurs de la WC dans les 30 de la WCSL de la discipline. On départage selon les pts ECSL sinon les pts WCSL
groupe 4 On continue avec les Pts de la ECSL jusqu'à en avoir 30 pris au titre de la ECSL
groupe 5 Cette série est interrompue si on a un vainqueur d'une autre Coupe continentale qui par systématiquement en 31 ème position.
groupe 6 La série interrompue reprend jusqu'à en avoir 30.
Groupe 7 On poursuit selon les points FIS.

grid:Filter() = on réapplique le filtre avec la table sourse Src
table:FindColumnIndex(colname) -> retourne l'indice de la colonne visible pour la grille
table:FindColumnIndex(indice) -> indice numérique retourne l'indice de la colonne visible pour la grille

]]

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
	tbTableau:EnableTool(btnSendMessage:GetId(), draw.socket_state);
	tbTableau:EnableTool(btnClear:GetId(), draw.socket_state);
	tbTableau:EnableTool(btnMenuSend:GetId(), draw.socket_state);
end

function OnAide()
-- groupe 1 ECSL de la discipline : de 1 à 15 (ou plus)
-- groupe 2 Si plus de 450 pts en EC la saison dernière de 16 à x
-- groupe 2 on met en plus dans ce groupe les coureurs de la WC dans les 30 de la WCSL de la discipline. On départage selon les pts ECSL sinon les pts WCSL
-- groupe 3 On continue avec les Pts de la ECSL jusqu'à en avoir 30 pris au titre de la ECSL
-- groupe 4 Cette série est interrompue si on a un vainqueur d'une autre Coupe continentale qui par systématiquement en 31 ème position.
-- groupe 5 La série interrompue reprend jusqu'à en avoir 30.
-- Groupe 6 On poursuit selon les points FIS.
	local msg = "le ranking en Coupe d'Europe se fait de la façon suivante :\n"..
				"Groupe 1-2 : les 15 premiers de la dernière European Cup Starting List produite par la FIS dans la discipline courue. "..
				"Ce groupe 1 sera divisé en deux sous groupe (1 à 7 et 8 à 15). Ces sous groupes sont augmentés en cas d'exaequo.\n"..
				"Groupe 3 : Ceux qui auront marqué au moins 450 points dans la ECSL toutes disciplines confondues dans la saison précédente ou celle en cours.\n"..
				"          + les coureurs de Coupe du Monde dans les 30 premiers de la spécialité (au jour de la course).\n"..
				"           en cas d'exaequos, ils seront départagés par les Pts ECSL ou les points FIS.\n"..
				"Groupe 4 : On continue dans l'ordre de la Starting List jusqu'à avoir 30 coureurs listés.\n"..
				"           Cette série peut être interrompue au rang 31 par un ou plusieurs vainqueurs des autres Coupes Continentales. Vous mettrez un caractère quelquonque dans 'Winner CC'.\n"..
				"           La série interrompue reprend ensuite pour en avoir 30 sur la ECSL\n"..
				"           Les coureurs pris au titre des points 'Overall' comptent parmi ces 30.\n"..
				"           là encore, en cas d'exaequos, ils seront départagés par les Pts ECSL ou les points FIS.\n"..
				"S'il y en a moins de 30, on prendra dans ce groupe les viennent ensuite par ordre de leurs points FIS.\n"..
				"Groupe 5 : Le ranking se poursuit selon les points FIS.\n"..
				"Les exaequos dans les coureurs 'points FIS' sont départagés par double tirage.\n"..
				"Vous pouvez télécharger les fichiers Excel des classements sur le site de la FIS dans votre 'Member section'\n"..
				"ATTENTION à bien vérifier que la dernière course a été prise en compte soit dès qu'elle est validée par le DT.";
	dlgTableau:MessageBox(msg, "Aide sur le ranking en CE.",
		msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION);
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
	ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
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
		OnDecodeJson(groupe)
	end
	if groupe == 1 then
		if not draw.print_alone then
			local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement..' And Groupe = '..groupe;
			base:Query(cmd);
			for i = 0, tTableTirage1:GetNbRows() -1 do
				local ligne = tTableTirage1:GetCellInt('Row', i);
				local dossard = params.tableDossards1[ligne];
				local identite = tDrawG6:GetCell('Nom', i)..' '..tDrawG6:GetCell('Prenom', i);
				local pts = tDrawG6:GetCellDouble('FIS_pts', i)
				local col1 = identite;
				local col2 = pts;
				local col3 = ligne;
				local col4 = dossard;
				local tTable1 = {};
				local tTable2 = {};
				table.insert(tTable1, {Col1 = 'Dossard du rang fictif '..(i+1), Col2 = params.tableDossards1[i+1]});
				local xTable1 = {Table1 = tTable1};
				local jsontxt1 = table.ToStringJSON(xTable1, false);
				table.insert(tTable2, {Col1 = col1, Col2 = col2, Col3 = col3, Col4 = col4});
				local xTable2 = {Table2 = tTable2};
				local jsontxt2 = table.ToStringJSON(xTable2, false);
				local row = tResultat_Info_Bibo:AddRow();
				tResultat_Info_Bibo:SetCell('Code_evenement', row, draw.code_evenement);
				tResultat_Info_Bibo:SetCell('Groupe', row, groupe);
				tResultat_Info_Bibo:SetCell('Ligne', row, i+1);
				tResultat_Info_Bibo:SetCell('Table1', row, jsontxt1);
				tResultat_Info_Bibo:SetCell('Table2', row, jsontxt2);
				base:TableInsert(tResultat_Info_Bibo, row)
			end
		end
		report = wnd.LoadTemplateReportXML({
			xml = './process/dossardDoubleTirage.xml',
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
			layers = {file = './edition/layer.xml', id = 'ffs-fis', page = '*'}, 
			paper_orientation = 'portrait',
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, Draw = 1, Version = draw.version, NbGroupe1 = 0}
		});
	elseif groupe == 2 then
		if not draw.print_alone then
			local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..draw.code_evenement..' And Groupe = '..groupe;
			base:Query(cmd);
			for i = 0, tTableTirage1:GetNbRows() -1 do
				local ligne = tTableTirage1:GetCellInt('Row', i);
				local dossard = params.tableDossards1[ligne];
				local identite = tDrawG6:GetCell('Nom', i)..' '..tDrawG6:GetCell('Prenom', i);
				local pts = tDrawG6:GetCellDouble('FIS_pts', i)
				local col1 = identite;
				local col2 = pts;
				local col3 = ligne;
				local col4 = dossard;
				local tTable1 = {};
				local tTable2 = {};
				table.insert(tTable1, {Col1 = 'Dossard du rang fictif '..(i+1), Col2 = params.tableDossards1[i+1]});
				local xTable1 = {Table1 = tTable1};
				local jsontxt1 = table.ToStringJSON(xTable1, false);
				table.insert(tTable2, {Col1 = col1, Col2 = col2, Col3 = col3, Col4 = col4});
				local xTable2 = {Table2 = tTable2};
				local jsontxt2 = table.ToStringJSON(xTable2, false);
				local row = tResultat_Info_Bibo:AddRow();
				tResultat_Info_Bibo:SetCell('Code_evenement', row, draw.code_evenement);
				tResultat_Info_Bibo:SetCell('Groupe', row, groupe);
				tResultat_Info_Bibo:SetCell('Ligne', row, i+1);
				tResultat_Info_Bibo:SetCell('Table1', row, jsontxt1);
				tResultat_Info_Bibo:SetCell('Table2', row, jsontxt2);
				base:TableInsert(tResultat_Info_Bibo, row)
			end
		end
		local editor = report:GetEditor();
		editor:PageBreak(); -- Saut de Page entre les 2 éditions ...

		wnd.LoadTemplateReportXML({
			xml = './process/dossardDoubleTirage.xml',
			node_name = 'root/panel',
			node_attr = 'id',
			node_value = 'print',
			title = 'Edition du tirage au sort du BIBO (2 pages)',
			report = report,
			base = base,
			margin_first_top = 150,
			margin_first_left = 100,
			margin_first_right = 100,
			margin_first_bottom = 100,
			margin_top = 150,
			margin_left = 100, 
			margin_right = 100,
			margin_bottom = 100,
			layers = {file = './edition/layer.xml', id = 'ffs-fis', page = '*'}, 
			paper_orientation = 'portrait',
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, Draw = 2, Version = draw.version, NbGroupe1 = draw.nb_groupe_1}
		});
	end
end

function OnPrintEtiquettes(orderby)
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
		xml = './process/live_draw.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'parti_etiquette_factorise',
		base = base,
		body = tDraw,
		params = {Orderby = orderby, EstCE = estce, EstVitesse = vitesse}
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
				if tDraw_Copy:GetCellInt('Groupe_tirage', i) > 1 then
					if tDraw_Copy:GetCellInt('ECSL_overall_points', i) == 0 then
						tDraw_Copy:RemoveRowAt(i);
					end
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
		xml = './process/live_draw.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'print',
		title = "Racers' Board - Bib Drawing",
		base = base,
		body = tDraw_Copy,
		layers = {file = './edition/layer.xml', id = 'ffs-fis'}, 
		margin_first_top = 80,
		margin_first_left = 80,
		margin_first_right = 80,
		margin_first_bottom = 80,
		margin_top = 80,
		margin_left = 80, 
		margin_right = 80,
		margin_bottom = 80,
		paper_orientation = 'portrait',
		params = {Evenement_nom = tEvenement:GetCell('Nom', 0), Version = draw.version, NbGroupe1 = draw.nb_groupe_1, EstCE = estCE}
	});
end

function OnReOrder(old_rank,new_rank, code_coureur)
	for i = new_rank-1, old_rank -1 do
		if tDraw:GetCell('Code_coureur', i) ~= code_coureur then
			tDraw:SetCell('Rang_tirage', i, tDraw:GetCellInt('Rang_tirage', i) +1);
		end
	end
	tDraw:SetCell('Rang_tirage', i, tDraw:GetCellInt('Rang_tirage', i) +1);
	tDraw:OrderBy('Rang_tirage');
	RefreshGrid();
	grid_tableau:SelectRow(new_rank -1)
	local msg = "Voulez-vous renvoyer les modifications à la FIS ?\n\n"..
				"Vous devrez peut-être changer le groupe de tirage avant.\n\n"..
				"Dans le cas contraire, vous devrez renvoyer tout le tableau ultérieurement.";
	if dlgTableau:MessageBox(
		msg, "Renvoi du tableau à la FIS", 
		msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
	) == msgBoxStyle.YES then
		CommandSendOrder();
	end
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
	else
		tDraw:OrderBy('Rang_tirage');
	end
	-- draw.build_table = false;
	-- grid_tableau:SetSortingColumn('Rang_tirage');
	draw.bolInit = false;
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
		width = 500,
		height = 150
	});
	
	dlg:LoadTemplateXML({ 
		xml = './process/live_draw.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'message'
	});
	function OnSend()
		SendMessage(dlg:GetWindowName('message'):GetValue());
		dlg:EndModal(idButton.OK);
	end
	
	-- Initialisation des variables 
	
	dlg:GetWindowName('message'):Clear();
	dlg:GetWindowName('message'):Append('Draw available');
	dlg:GetWindowName('message'):Append('Validation of racers in progress');
	dlg:GetWindowName('message'):Append('Board of racers refreshed');
	dlg:GetWindowName('message'):Append('Board confirmed, bib drawing in progress');
	dlg:GetWindowName('message'):SetSelection(0);
	
	
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

function ChecktDraw()
	tDraw:OrderBy('Rang_tirage');
	-- params.last_row_groupe_bibo = nil;
	-- if draw.bolEstCE then
		-- draw.pts7 = tDraw:GetCellInt('ECSL_points', 6);
		-- draw.pts15 = tDraw:GetCellInt('ECSL_points', 14);
		-- if not draw.bolVitesse then
			-- for i = tDraw:GetNbRows() -1, 0, -1 do
				-- if 
			-- end
		-- else
			-- for i = tDraw:GetNbRows() -1, 0, -1 do
				-- if tDraw:GetCellInt('Groupe_tirage', i) == 1 then
					-- params.last_row_groupe_bibo = i;
				-- end
			-- end
		-- end
	-- end

	draw.tRang_tirageauto = {};
	draw.statut = 'CF';
	draw.tDossardsAvailable = {};
	if draw.bolVitesse == true then
		for i = 1, 30 do
			table.insert(draw.tDossardsAvailable, i);
		end
	end
	for i = 0, tDraw:GetNbRows() -1 do
		if draw.bolVitesse then
			if i < 30 then
				local dossard = tDraw:GetCellInt('Dossard', i);
				if dossard > 0 then
					draw.tDossardsAvailable[dossard] = draw.tDossardsAvailable[dossard] + 100;
				end
			end
		end
		local pts, rank, pts_VIT, rank_VIT = GetRank(tDraw:GetCell('Code_coureur', i));
		if pts and pts >= 0 then
			tDraw:SetCell('FIS_pts', i, pts);
			tDraw:SetCell('FIS_clt', i, rank);
		end
		local rang_tirage = tDraw:GetCellInt('Rang_tirage', i);
		if tDraw:GetCell('Statut', i) ~= 'CF' then
			draw.statut = 'UF';
		end
		if pts and pts >= 0 then
			if i < tDraw:GetNbRows() -1 then
				if draw.bolVitesse then
				else
				end
				if rang_tirage == tDraw:GetCellInt('Rang_tirage', i+1) then
					draw.tRows_nepastirer[rang_tirage] = {};
					if not draw.tRang_tirageauto[rang_tirage] then
						table.insert(draw.tRang_tirageauto, rang_tirage);
					end
				end
			end
		end
	end
	if draw.bolVitesse then
		for i = #draw.tDossardsAvailable, 1, -1 do
			if draw.tDossardsAvailable[i] > 100 then
				table.remove(draw.tDossardsAvailable, i);
			end
		end
	end
end

function CommandSendOrder()
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
		local nodeGroup = xmlNode.Create(nodeDrawGroup, xmlType.ELEMENT_NODE, "group", tDraw:GetCellInt('Groupe_tirage', i));

		local nodeDrawOrder = xmlNode.Create(nodeRaceEvent, xmlType.ELEMENT_NODE, "draworder");
		nodeDrawOrder:AddAttribute('fiscode', code_coureur);
		local nodeOrder = xmlNode.Create(nodeDrawOrder, xmlType.ELEMENT_NODE, "order", tDraw:GetCellInt('Rang_tirage', i));
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
	if draw.statut == 'UF' then
		SendMessage('Board of racers refreshed (you might have to refresh the page)');
	else
		SendMessage('Board confirmed, bib drawing in progress (you might have to refresh the page)');
	end
end

-- Envoi Course
function CommandSendList()
	-- Génération des balises 
	local nodeStartlist = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "startlist");
	nodeStartlist:AddAttribute("phase", 'D');
	draw.statut_CF = true;
	for i = 0, tDraw:GetNbRows()-1 do
		local nom = tDraw:GetCell('Nom', i);
		local prenom = tDraw:GetCell('Prenom', i);
		local nation = tDraw:GetCell('Nation', i);
		if tDraw:GetCell('Statut', i) == 'UF' then
			draw.statut_CF = false;
		end
		local code = tDraw:GetCell('Code_coureur', i):sub(4);
		local wcsl_points = tDraw:GetCellInt('WCSL_points', i, -1);
		local wcsl_rank = tDraw:GetCellInt('WCSL_rank', i);
		local ecsl_points = tDraw:GetCellInt('ECSL_points', i, -1);
		local ecsl_rank = tDraw:GetCellInt('ECSL_rank', i);
		local cupsl_points = tDraw:GetCellInt('CupSL_points', i, -1);
		local cupsl_rank = tDraw:GetCellInt('CupSL_rank', i);
		local fis_pts = tDraw:GetCellDouble('FIS_pts', i, -1);
		local fis_clt = tDraw:GetCellInt('FIS_clt', i);
		local tStandings = {};
		if wcsl_points >= 0 then
			   table.insert(tStandings, {category = 'WCSL', event = 'ALL', points = wcsl_points, rank = wcsl_rank});
		end
		if ecsl_points >= 0 then
			table.insert(tStandings, {category = 'ECSL', event = 'ALL', points = ecsl_points, rank = ecsl_rank});
		end
		if cupsl_points >= 0 then
			table.insert(tStandings, {category = 'CUPS', event = 'ALL', points = cupsl_points, rank = cupsl_rank});
		end
		if fis_pts >= 0 then
			table.insert(tStandings, {category = 'FIS', event = draw.discipline, points = fis_pts, rank = fis_clt});
		else
			table.insert(tStandings, {category = 'FIS', event = draw.discipline, points = '', rank = ''});
		end
		local tCoureur = {standings = tStandings};
		local jsontxt = table.ToStringJSON(tCoureur, false);
		
		local nodeRacer = xmlNode.Create(nodeStartlist, xmlNodeType.ELEMENT_NODE, "racer");
		local nodeLastname = xmlNode.Create(nodeRacer, xmlType.ELEMENT_NODE, "lastname", nom);
		local nodeFirstname = xmlNode.Create(nodeRacer, xmlType.ELEMENT_NODE, "firstname", prenom);
		local nodeNation = xmlNode.Create(nodeRacer, xmlType.ELEMENT_NODE, "nat", nation);
		local nodeFiscode = xmlNode.Create(nodeRacer, xmlType.ELEMENT_NODE, "fiscode", code);
		-- local noderacerinfoJSON = xmlNode.Create(nodeRacer, xmlType.ELEMENT_NODE, "racerinfoJSON", jsontxt);	
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

function CommandRaceInfo()
	local run = 1;
	-- Génération des balises 
	local nodeRaceinfo = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "raceinfo");
	
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "event", tEvenement:GetCell('Nom',0));	
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "name", tEpreuve:GetCell("Code_discipline", 0)..' '..tEpreuve:GetCell("Sexe", 0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "slope", tPistes:GetCell('Nom_piste',0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "discipline", tEpreuve:GetCell("Code_discipline", 0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "gender", tEpreuve:GetCell("Sexe", 0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "category", tEpreuve:GetCell("Code_niveau", 0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "place", tEvenement:GetCell('Station',0));			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "tempunit", 'C');			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "longunit", 'm');			
	xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "speedunit", 'Kmh');	
				
	nodePhase = xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, "phase");			
	nodePhase:AddAttribute("no", 'D');			
	
	-- nodePhase Childs ...
		
	-- discipline
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "discipline", tEpreuve:GetCell('Code_discipline', 0));	
	
	-- start
	local start = tonumber(tEpreuve_Alpine_Manche:GetCell("Altitude_Depart",run-1)) or 0;
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "start", start);	

	-- finish
	local finish = tonumber(tEpreuve_Alpine_Manche:GetCell("Altitude_Arrivee",run-1)) or 0;
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "finish", finish);	
	
	-- height
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "height", start - finish);	

	-- length 
	local length = tonumber(tEpreuve_Alpine_Manche:GetCell("Longueur",run-1)) or 0;
	if length > 0 then
		xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "length", length);	
	end
	-- gates
	local gates = tEpreuve_Alpine_Manche:GetCellInt("Nombre_de_portes",run-1);
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "gates", gates);	
	
	-- turninggates
	local turninggates = tEpreuve_Alpine_Manche:GetCellInt("Changement_de_directions",run-1,0);
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "turninggates", turninggates);	

	-- year
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "year", tEpreuve:GetCell("Date_epreuve", 0, '%4Y'));	
	
	-- month
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "month", tEpreuve:GetCell("Date_epreuve", 0, '%2M'));	

	-- day
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "day", tEpreuve:GetCell("Date_epreuve", 0, '%2D'));	
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
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "hour", heure);	

	-- minute
	xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "minute", minute);	
	
	--racedef  
	local nodeRacedef = xmlNode.Create(nodePhase, xmlType.ELEMENT_NODE, "racedef");	
		
	-- nodeRacedef Childs ...
	xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "draworder", '');	
	xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "drawgroup", '');	
	xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "drawstatus", '');	
	xmlNode.Create(nodeRacedef, xmlType.ELEMENT_NODE, "drawbib", '');	
	local tInfo = {legend = {abbreviation = {{description = 'ECSL', title = 'ECSL'}, {description = '400-200 Cup Points', title = '400-200'}, {description = 'WCSL top 30', title = 'Top 30'}, {description = 'Ranked by FIS points', title = 'FIS Points'}}}};
	if draw.bolEstCE == false then
		tInfo = {legend = {abbreviation = {{description = 'Ranked by FIS points', title = 'FIS Points'}}}};
	end
	local jsontxt = table.ToStringJSON(tInfo, false);
	
	local nodedrawinfoJSON = xmlNode.Create(nodeRaceinfo, xmlType.ELEMENT_NODE, 'drawinfoJSON');	
	xmlNode.Create(nodedrawinfoJSON, xmlType.CDATA_SECTION_NODE,'', jsontxt);	

	nodeRoot = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeRaceinfo);
	CreateXML(nodeRoot);
	dlgTableau:GetWindowName('info'):SetValue("Informations de course envoyées");
end

function CreateXML(nodeRoot)
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
	if draw.debug then
		Info('CreateXML '..draw.directory..'live'..draw.codex..'_'..tostring(draw.sequence_send)..'.xml');
	end
	doc:Delete();

	SendNextPacket();
end

function GetCateg(an)
	local cmd = "Select * From Categorie Where Code_activite = 'ALP' And Code_entite = 'FIS' And Code_grille = '"..draw.code_grille_categorie.."' And Code_saison = '"..draw.code_saison.."' And An_min <= "..an.." And An_max >= "..an.." Order By Ordre";
	base:TableLoad(tCategorie, cmd);
	return tCategorie:GetCell('Code', 0);
end

function OnSendTableau(statut)
	local msg = "Confirmation de l'envoi du tableau à la FIS.";
	if dlgTableau:MessageBox(
		msg, 
		"Envoi du tableau à la FIS", 
		msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION
	) ~= msgBoxStyle.YES then
		return;
	end
	CommandClear();
	CommandRaceInfo();
	CommandPhaseD();
	CommandSendList();
	CommandSendOrder();
	CommandRenvoyerDossards(false);
end

function OnRAZData(colonne)
	local txt = '';
	if colonne == 'Groupe_tirage' then
		txt = 'groupes de tirage'
	elseif colonne == 'Rang_tirage' then
		txt = 'rangs de tirage'
	elseif colonne == 'Dossard' then
		txt = 'dossards'
	elseif colonne == 'All' then
		txt = 'rangs et les groupes de tirage'
	elseif colonne == 'Tout' then
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
	draw.bib_done = false;
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
end

function OnSupprimerCoureur(code_coureur, delete_rang_tirage)
	local cmd = "Delete From Resultat_Info_Tirage Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
	base:Query(cmd);
	cmd = "Delete From Resultat Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
	base:Query(cmd);
	for i = tDraw:GetNbRows() -1, 0, -1 do
		local rang_tirage = tDraw:GetCellInt('Rang_tirage', i);
		if rang_tirage > tDraw:GetNbRows() then
			tDraw:SetCell('Rang_tirage', i, tDraw:GetNbRows());
		elseif rang_tirage >= delete_rang_tirage then
			tDraw:SetCell('Rang_tirage', i, tDraw:GetCellInt('Rang_tirage', i) -1);
		else
			break;
		end
	end
	RefreshGrid(false);
	CommandSendList();
	CommandSendOrder();
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
	local code_coureur = 'FIS'..dlgTableau:GetWindowName('code'):GetValue();
	local groupe = tonumber(dlgTableau:GetWindowName('groupe'):GetValue()) or 9;
	local nom = dlgTableau:GetWindowName('nom'):GetValue();
	local prenom = dlgTableau:GetWindowName('prenom'):GetValue();
	local sexe = draw.sexe;
	local an = tonumber(dlgTableau:GetWindowName('an'):GetValue()) or 0;
	local code_saison = draw.code_saison;
	local categ = nil;
	local nation = dlgTableau:GetWindowName('nation'):GetValue();
	local comite = '';
	local ecsl_rank = nil;
	local ecsl_points = nil;
	local point = tonumber(dlgTableau:GetWindowName('points'):GetValue()) or 0;
	local clt = tonumber(dlgTableau:GetWindowName('classement'):GetValue()) or 0;
	if draw.bolEstCE then
		ecsl_rank = tonumber(dlgTableau:GetWindowName('ecsl_rank'):GetValue()) or 0; 
		ecsl_points = tonumber(dlgTableau:GetWindowName('ecsl_points'):GetValue()) or 0;;
	else
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
		code_saison = tCoureur:GetCellInt('Code_saison', 0);
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
		if nation == 'FRA' and code_saison ~= draw.code_saison then
			modif_manuel = 'D';
			tDraw:GetRecord():Set('Modif_manuel',modif_manuel);
			app.GetAuiFrame():MessageBox(msg, "Veuillez vérifier la licence FFS.", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
		end
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
			if ecsl_rank > 1 and ecsl_points > 0 then
				tDraw:GetRecord():Set('ECSL_rank', ecsl_rank);
				tDraw:GetRecord():Set('ECSL_points', ecsl_points);
			end
		end
		if point > 0 and clt > 0 then
			tDraw:GetRecord():Set('FIS_pts', point);
			tDraw:GetRecord():Set('FIS_clt', clt);
		end
		tDraw:AddRow();
		table.insert(draw.tModifs_tableau, {Code_coureur = code_coureur:sub(4), Nom = nom, Prenom = prenom, Nation = nation, Status = 'AD'});
		-- OnOrder()
	else
		local msg = 'Ce coureur est déjà présent dans la course !!!';
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
		return;
	end
	draw.build_table = true;
	OnOrder();
	CommandSendList();
	CommandSendOrder();
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
		dlgTableau:GetWindowName('ecsl_rank'):SetValue('');
		dlgTableau:GetWindowName('ecsl_points'):SetValue('');
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
	-- nodeCommand = xmlNode.Create(nil, xmlType.ELEMENT_NODE, "command");
	-- local nodeDrawInProgress = xmlNode.Create(nodeCommand, xmlType.ELEMENT_NODE, "drawinprogress");
	nodeRoot:AddChild(nodeRaceEvent);
	-- nodeRoot:AddChild(nodeCommand);
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
		draw.double_tirage_bibo = false;
		local dossard = t:GetCellInt('Dossard', row);
		if t:GetCell('Statut', row) ~= 'CF' then
			dossard = 0;
		end
		if dossard == 0 then
			t:SetCellNull('Dossard', row);
			grid_tableau:RefreshCell(row, col);
		end
		OnChangeDossard(row);
		grid_tableau:SynchronizeRows();
		base:TableBulkUpdate(tDraw, 'Dossard', 'Resultat');
	elseif colName == 'Rang_tirage' then
		OnReOrder(tonumber(evt:GetString(row)), tDraw:GetCellInt('Rang_tirage',row), tDraw:GetCell('Code_coureur', row));
		grid_tableau:SynchronizeRows();
		base:TableBulkUpdate(tDraw, 'Rang_tirage', 'Resultat_Info_Tirage');
	end
end


function OnCellSelected(evt)
	local row = evt:GetRow();
	local col = evt:GetCol();
	local t = grid_tableau:GetTable();
	local colName = t:GetColumnName(t:GetVisibleColumnsIndex(col));
	grid_tableau:SelectRow(row);
	if col > 0 and col < grid_tableau:GetNumberCols() -1 then
		return;
	end
	local delete_rang_tirage = t:GetCellInt('Rang_tirage', row);
	local code_coureur = t:GetCell('Code_coureur', row);
	local nom = t:GetCell('Nom', row);
	local prenom = t:GetCell('Prenom', row);
	local nation = t:GetCell('Nation', row);
	local identite = nom..' '..prenom;
	if col == grid_tableau:GetNumberCols() -1 then
		local msg = 'Confirmez-vous la suppression de '..identite;
		if app.GetAuiFrame():MessageBox(msg, "Confirmer la suppression", msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
			return ;
		end
		-- suppression du coureur
		table.insert(draw.tModifs_tableau, {Code_coureur = code_coureur:sub(4), Nom = nom, Prenom = prenom, Nation = nation, Status = 'RM'});
		grid_tableau:DeleteRows(row);
		OnSupprimerCoureur(code_coureur, delete_rang_tirage);
	end
end

function OnCellContext(evt)
	local row = evt:GetRow();
	local col = evt:GetCol();
	if row >= 0 and col >= 0 then
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
		if colName == 'Nation' then
			local nation = tDraw:GetCell('Nation', row);
			evt:SetCellContext({ 
			align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL
			});
		elseif colName == 'Action' then
			evt:SetCellContext({ 
				bitmaps = { { image = './res/16x16_minus.png'}}
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
		if colName:find('Rang') or colName:find('Dossard') or colName:find('points') or colName:find('_rank') or colName:find('Groupe') or colName:find('Winner') or colName:find('Statut') or colName:find('pts') or colName:find('clt') then
			evt:Skip(true);
			return;
		end
	end
	evt:Veto();
end

function OnTirageAuto()
	for i = 1, #draw.tRang_tirageauto  do
		tDrawG6 = tDraw:Copy();
		ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
		for row = tDrawG6:GetNbRows() -1, 0, -1 do
			if tDrawG6:GetCellInt('Rang_tirage', row) ~= draw.tRang_tirageauto[i] then
				tDrawG6:RemoveRowAt(row);
			end
		end
		tDrawG6:OrderRandom('Prenom');
		local tShuffle = {};
		for row = 0, tDrawG6:GetNbRows() -1 do
			table.insert(tShuffle, draw.tRang_tirageauto[i]+row);
		end
		tShuffle = Shuffle(tShuffle, true);
		for j = 0, tDrawG6:GetNbRows() -1 do
			local valeur_shuffle = tShuffle[j+1];
			local code_coureur = tDrawG6:GetCell('Code_coureur', j)
			local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then
				if draw.tirage_auto then
					tDraw:SetCell('Dossard', r, valeur_shuffle);
					local cmd = "Update Resultat Set Dossard = "..(valeur_shuffle)..", Critere = '"..string.format('%03d', tDraw:GetCellInt('Rang_tirage', r)).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..tDraw:GetCell('Code_coureur', r).."'";
					base:Query(cmd);
				else
					tDraw:SetCell('Dossard', r, 1000);
				end
			end
		end
	end
	RefreshGrid();
	--grid_tableau:SynchronizeRows();
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
	base:TableBulkUpdate(tDraw,'Groupe_tirage, Rang_tirage, WCSL_points, WCSL_rank, ECSL_points, ECSL_rank, ECSL_30, ECSL_overall_points, ECSL_overall_rank, Winner_CC, FIS_pts, FIS_clt, FIS_SG_pts, FIS_SG_clt, Statut', 'Resultat_Info_Tirage');
end

function BuildTablesDraw()	-- on ajoute ou on supprime des enregistrements dans la table Resultat_Info_Tirage
	tResultat_Info_Tirage = base:GetTable('Resultat_Info_Tirage');
	local cmd = 'Delete From Resultat_Info_Tirage Where Code_evenement = '..draw.code_evenement..' And Code_coureur Not In (Select Code_coureur From Resultat Where Code_evenement = '..draw.code_evenement..')';
	base:Query(cmd);
	base:TableLoad(tResultat_Info_Tirage, 'Select * From Resultat_Info_Tirage Where Code_evenement = '..draw.code_evenement);
	if tResultat_Info_Tirage:GetNbRows() == 0 then
		draw.bolInit = true;
	end
	for i = 0, tResultat:GetNbRows() -1 do
		local code_coureur = tResultat:GetCell('Code_coureur', i);
		local pts, rank, pts_SG, rank_SG = GetRank(code_coureur);
		tResultat:SetCell('Point', i, pts);
		local r = tResultat_Info_Tirage:GetIndexRow('Code_coureur', code_coureur);
		if r < 0 then
			-- on ajoute le coureur dans la table tResultat_Info_Tirage
			if draw.debug then
				Info('code '..code_coureur..' non trouvé dans tResultat_Info_Tirage');
			end
			draw.build_table = true;
			row = tResultat_Info_Tirage:AddRow();
			tResultat_Info_Tirage:SetCell('Code_evenement', row, draw.code_evenement);
			tResultat_Info_Tirage:SetCell('Code_coureur', row, tResultat:GetCell('Code_coureur', i));
			tResultat_Info_Tirage:SetCell('Groupe_tirage', row, 5);
			tResultat_Info_Tirage:SetCell('Statut', row, 'UF');
			if pts then
				tResultat_Info_Tirage:SetCell('FIS_pts', row, pts);
				tResultat_Info_Tirage:SetCell('FIS_clt', row, rank);
			else
				tResultat_Info_Tirage:SetCellNull('FIS_pts', row);
				tResultat_Info_Tirage:SetCellNull('FIS_clt', row);
			end
			tResultat_Info_Tirage:SetCell('FIS_SG_pts', row, pts_SG);
			tResultat_Info_Tirage:SetCell('FIS_SG_clt', row, rank_SG);
			base:TableInsert(tResultat_Info_Tirage, row);
		end
	end
end

function SetuptDraw()
	if not draw.build_table then
		tDraw:OrderBy('Rang_tirage');
		return;
	end
	for i = 0, tDraw:GetNbRows() -1 do
		tDraw:SetCellNull('Critere', i);
		tDraw:SetCellNull('Groupe', i);
		tDraw:SetCellNull('ECSL_30', i);
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
	tDraw:OrderBy('FIS_pts');
	draw.ptsFIS7 = tDraw:GetCellDouble('FIS_pts', 6);
	draw.ptsFIS15 = tDraw:GetCellDouble('FIS_pts', 14);
	tDraw:OrderBy('ECSL_points DESC, FIS_pts');
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
	ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
--[[
groupe 1 ECSL de la discipline : de 1 à 15 (ou plus)
groupe 2 Si plus de 450 pts en EC la saison dernière de 16 à x
groupe 2 on met en plus dans ce groupe les coureurs de la WC dans les 30 de la WCSL de la discipline. On départage selon les pts ECSL sinon les pts WCSL
groupe 3 On continue avec les Pts de la ECSL jusqu'à en avoir 30 pris au titre de la ECSL
groupe 4 Cette série est interrompue si on a un vainqueur d'une autre Coupe continentale qui par systématiquement en 31 ème position.
groupe 5 La série interrompue reprend jusqu'à en avoir 30.
Groupe 6 On poursuit selon les points FIS.
]]
	draw.pts7 = tDrawG1:GetCellInt('ECSL_points', 6);
	draw.pts15 = tDrawG1:GetCellInt('ECSL_points', 14);
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

	tDrawG3:OrderBy('ECSL_points, FIS_pts, WCSL_rank');				-- dans les 30 de la WCSL
	for i = tDrawG3:GetNbRows() -1, 0, -1 do
		local clt = tDrawG3:GetCellInt('WCSL_rank', i, 31);
		if clt > 30 then
			tDrawG3:RemoveRowAt(i);
		end
	end

	tDrawG4:OrderBy('FIS_pts');				-- les vainqueurs des autres CC
	for i = tDrawG4:GetNbRows() -1, 0, -1 do
		local winner = tDrawG4:GetCell('Winner_CC', i);
		if winner:len() == 0 then
			tDrawG4:RemoveRowAt(i);
		end
	end

	tDrawG5:OrderBy('ECSL_points DESC');				-- coureurs ayant des points ECSL
	for i = tDrawG5:GetNbRows() -1, 0, -1 do
		local pts = tDrawG5:GetCellInt('ECSL_points', i);
		if pts == 0 then
			tDrawG5:RemoveRowAt(i);
		end
	end

	tDrawG6:OrderBy('FIS_pts');				-- coureurs ayant des points FIS
	for i = tDrawG6:GetNbRows() -1, 0, -1 do
		local pts = tDrawG6:GetCellDouble('FIS_pts', i, -1);
		if pts < 0 then
			tDrawG6:RemoveRowAt(i);
		end
	end

	if draw.debug == true then
		Info('Avant le tri, il reste : ');
		Info(tDrawG1:GetNbRows()..' coureurs dans tDrawG1');
		Info(tDrawG2:GetNbRows()..' coureurs dans tDrawG2');
		Info(tDrawG3:GetNbRows()..' coureurs dans tDrawG3');
		Info(tDrawG4:GetNbRows()..' coureurs dans tDrawG4');
		Info(tDrawG5:GetNbRows()..' coureurs dans tDrawG5');
	end

	-- les groupes 1 et 2 en technique ou groupe 1 seulement en vitesse
	local rang_tirage = 0;
	local current_group = 0;
	draw.nb_pris_ecsl = 0;
	tDrawG1:OrderBy('ECSL_points DESC, FIS_pts');
	local nb_exaequo = 0;
	if draw.debug then
		Info('draw.pts7 = '..tostring(draw.pts7)..', draw.pts15 = '..tostring(draw.pts15));
	end
	params.nb_groupe1 = 0;
	params.nb_groupe2 = 0;
	for i = 0, tDrawG1:GetNbRows() -1 do		-- On est forcément en Coupe d'Europe
		draw.nb_pris_ecsl = draw.nb_pris_ecsl + 1;
		local pts = tDrawG1:GetCellInt('ECSL_points', i);
		local code_coureur = tDrawG1:GetCell('Code_coureur', i);
		local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
		local fis_pts = tDrawG1:GetCellDouble('FIS_pts', i);
		if draw.bolVitesse == true then
			groupe = 1;
		else
			if pts >= draw.pts7 then
				params.nb_groupe1 = params.nb_groupe1 + 1;
				groupe = 1;
			else
				params.nb_groupe2 = params.nb_groupe2 + 1;
				groupe = 2;
			end
		end
		tDraw:SetCell('Groupe_tirage', r, groupe);
		if i > 0 then
			if pts < tDrawG1:GetCellInt('ECSL_points', i-1) then	-- pas d'égalité sur les pts ECSL
				rang_tirage = rang_tirage + 1 + nb_exaequo;
				nb_exaequo = 0;
			elseif fis_pts == tDrawG1:GetCellDouble('FIS_pts', i-1) then	-- égalité sur les pts ECSL ET sir les pts FIS
				if draw.debug == true then
					Info('Egalite de pts ECSL ET sur les pts FIS pour '..tDrawG1:GetCell('Nom', i)..' et '..tDrawG1:GetCell('Nom', i-1))
				end
				nb_exaequo = nb_exaequo + 1;
			else	-- égalité sur les pts ECSL mais pas sur les Pts FIS
				if draw.debug == true then
					Info('Egalite de pts ECSL MAIS PAS sur les pts FIS pour '..tDrawG1:GetCell('Nom', i)..' et '..tDrawG1:GetCell('Nom', i-1))
				end
				if draw.bolVitesse then
					if rang_tirage ~= 15 then
						rang_tirage = rang_tirage + 1;
						nb_exaequo = 0;
					end
				else
					if groupe == 1 then
						if rang_tirage ~= 7 then
							rang_tirage = rang_tirage + 1;
							nb_exaequo = 0;
						else
							nb_exaequo = nb_exaequo + 1;
						end
					else
						if rang_tirage ~= 15 then
							rang_tirage = rang_tirage + 1;
							nb_exaequo = 0;
						else
							nb_exaequo = nb_exaequo + 1;
						end
					end
				end
			end
		end
		current_group = groupe;
		if rang_tirage == 0 then rang_tirage = 1; end
		tDraw:SetCell('TG', r, 'tDrawG1');
		tDraw:SetCell('Pris', r, 1);
		tDraw:SetCell('ECSL_30', r, 1);
		
		tDraw:SetCell('Rang_tirage', r, rang_tirage);
		if draw.debug == true then
			Info('pour '..tDrawG1:GetCell('Nom', i)..', rang_tirage = '..rang_tirage);
		end
		tDraw:SetCell('Critere', r, string.format('%03d', rang_tirage));
		r = tDrawG2:GetIndexRow('Code_coureur', code_coureur);
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
	if nb_exaequo > 0 then
		for i = 0, nb_exaequo do	-- traitement des exaequos de rang 15
			rang_tirage = rang_tirage + 1;
		end
	end
	if draw.debug == true then
		Info('Après le BIBO, et avant les plus de 450 - 200 pts il reste : ');
		Info(tDrawG2:GetNbRows()..' coureurs dans tDrawG2');
		Info(tDrawG3:GetNbRows()..' coureurs dans tDrawG3');
		Info(tDrawG4:GetNbRows()..' coureurs dans tDrawG4');
		Info(tDrawG5:GetNbRows()..' coureurs dans tDrawG5 : \n');
		Info('dernier rang attribué = '..rang_tirage..'\n')
	end

	nb_exaequo = 0;
	if tDrawG2:GetNbRows() > 0 then
		rang_tirage = rang_tirage + 1;
		current_group = current_group + 1;
		for i = 0, tDrawG2:GetNbRows() -1 do		-- les plus de 450 - 200 pts 
			local code_coureur = tDrawG2:GetCell('Code_coureur', i);
			local pts = tDrawG2:GetCellInt('ECSL_overall_points', i);
			if i > 0 then
				if pts < tDrawG2:GetCellInt('ECSL_overall_points', i-1) then
					rang_tirage = rang_tirage + 1 + nb_exaequo;
					nb_exaequo = 0;
				else
					nb_exaequo = nb_exaequo + 1;
				end
			end
			local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
			tDraw:SetCell('TG', r, 'tDrawG2');
			tDraw:SetCell('Pris', r, 1);
			tDraw:SetCell('Groupe_tirage', r, current_group);
			tDraw:SetCell('Rang_tirage', r, rang_tirage);
			tDraw:SetCell('ECSL_30', r, 2);
			tDraw:SetCell('Critere', r, string.format('%03d', rang_tirage));
			draw.nb_pris_ecsl = draw.nb_pris_ecsl + 1;
			if draw.nb_pris_ecsl <= 30 then
				-- tDraw:SetCell('ECSL_30', r, 1);
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
	end
	-- rang_tirage = tDrawG1:GetNbRows() + tDrawG2:GetNbRows() + 1;
	if draw.debug then
		Info('Après les + de 450 pts en CE et avant tDrawG3 - dans les 30 de la WCSL  - dernier rang attribué = '..rang_tirage)
		Info(tDrawG2:GetNbRows()..' coureurs dans tDrawG2');
		Info(tDrawG3:GetNbRows()..' coureurs dans tDrawG3');
		Info(tDrawG4:GetNbRows()..' coureurs dans tDrawG4');
		Info(tDrawG5:GetNbRows()..' coureurs dans tDrawG5');
		Info('dernier rang attribué = '..rang_tirage..'\n')
	end
	
	if tDrawG3:GetNbRows() > 0 then
		current_group = current_group + 1;
		for i = 0, tDrawG3:GetNbRows() -1 do		-- dans les 30 de la WCSL 
			local code_coureur = tDrawG3:GetCell('Code_coureur', i);
			local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
			rang_tirage = rang_tirage + 1;
			tDraw:SetCell('TG', r, 'tDrawG3');
			tDraw:SetCell('Pris', r, 1);
			tDraw:SetCell('Groupe_tirage', r, current_group);
			tDraw:SetCell('Rang_tirage', r, rang_tirage);
			tDraw:SetCell('Critere', r, string.format('%03d', rang_tirage));
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
	if draw.debug == true then
		Info('Après les 30 premiers en WC, il reste : ');
		Info(tDrawG2:GetNbRows()..' coureurs dans tDrawG2');
		Info(tDrawG3:GetNbRows()..' coureurs dans tDrawG3');
		Info(tDrawG4:GetNbRows()..' coureurs dans tDrawG4');
		Info(tDrawG5:GetNbRows()..' coureurs dans tDrawG5');
		Info('avant tDrawG5 - on continue avec la ECSL, dernier rang attribué = '..rang_tirage..'\n')
	end
	-- on continue avec les ECSL pts (tDrawG5) interrompu par les winners en 31 ème place
	-- rang_tirage = tDrawG1:GetNbRows() + tDrawG2:GetNbRows() + tDrawG3:GetNbRows() +1;
	tDrawG4:OrderBy('ECSL_points DESC, FIS_pts');				-- les winners de CC triés par leurs points ECSL et les points FIS
	tDrawG5:OrderBy('ECSL_points DESC, FIS_pts');				-- les 30 ECSL
	if draw.debug then
		Info('\navant tDrawG5 - on continue avec la ECSL  - dernier rang attribué = '..rang_tirage)
		Info('il reste '..tDrawG5:GetNbRows()..' coureurs dans tDrawG5 : ');
		for i = 0, tDrawG5:GetNbRows() -1 do
			Info(tDrawG5:GetCell('Nom', i)..', ECSL_points = '..tDrawG5:GetCellInt('ECSL_points', i));
		end
	end
	-- nb_exaequo = 0;
	if tDrawG5:GetNbRows() > 0 then
		current_group = current_group + 1;
		for i = 0, tDrawG5:GetNbRows() -1 do		-- on prendra jusqu'à draw.nb_pris_ecsl = 30 
			local code_coureur = tDrawG5:GetCell('Code_coureur', i);
			local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
			local pts = tDrawG5:GetCellInt('ECSL_points', i);
			rang_tirage = rang_tirage + 1;
			tDraw:SetCell('TG', r, 'tDrawG5');
			tDraw:SetCell('Pris', r, 1);
			tDraw:SetCell('Groupe_tirage', r, current_group);
			tDraw:SetCell('Rang_tirage', r, rang_tirage);
			tDraw:SetCell('Critere', r, string.format('%03d', rang_tirage));
			draw.nb_pris_ecsl = draw.nb_pris_ecsl + 1;
			if draw.nb_pris_ecsl <= 30 then
				tDraw:SetCell('ECSL_30', r, 1);
			end
			local r = tDrawG6:GetIndexRow('Code_coureur', code_coureur);
			if draw.debug == true then
				Info('On a traité le coureur tDrawG5 : '..tDrawG5:GetCell('Nom', i)..', son rang_tirage = '..rang_tirage);
				Info('nb coureurs déjà pris au titre de la ECSL = '..draw.nb_pris_ecsl);
			end
			if r >= 0 then		-- on trouve le coureur
				tDrawG6:RemoveRowAt(r);
			end
			if rang_tirage == 30 or i == tDrawG5:GetNbRows() -1 or draw.nb_pris_ecsl == 30 then
				if tDrawG4:GetNbRows() > 0 then
					if draw.debug == true then
						Info('\ntDrawG4:GetNbRows() >, dernier rang_tirage = '..rang_tirage);
						Info('draw.nb_pris_ecsl au titre de la ECSL = '..draw.nb_pris_ecsl);
					end
					for j = 0, tDrawG4:GetNbRows() -1 do		-- les winners des CC 
						local code_coureur = tDrawG4:GetCell('Code_coureur', j);
						rang_tirage = rang_tirage + 1;
						if draw.debug == true then
							Info('On traite le coureur tDrawG4 : '..tDrawG4:GetCell('Nom', j));
							Info('son rang_tirage est : '..rang_tirage);
						end
						local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
						tDraw:SetCell('TG', r, 'tDrawG4');
						tDraw:SetCell('Pris', r, 1);
						tDraw:SetCell('Groupe_tirage', r, current_group);
						tDraw:SetCell('Rang_tirage', r, rang_tirage);
						tDraw:SetCell('Critere', r, string.format('%03d', rang_tirage));
						r = tDrawG6:GetIndexRow('Code_coureur', code_coureur);
						if r >= 0 then		-- on trouve le coureur
							tDrawG6:RemoveRowAt(r);
						end
					end
					tDrawG4:RemoveAllRows();
				end
			end
			if draw.nb_pris_ecsl == 30 then
				break;
			end
		end
	end
	if draw.debug == true then
		Info('Après le traitement de tDrawG5 avec insertion des winners tDrawG4 : ');
		Info('draw.nb_pris_ecsl au titre de la ECSL = '..draw.nb_pris_ecsl);
		Info('dernier rang_tirage attribué = '..rang_tirage);
		Info(tDrawG2:GetNbRows()..' coureurs dans tDrawG2');
		Info(tDrawG3:GetNbRows()..' coureurs dans tDrawG3');
		Info(tDrawG4:GetNbRows()..' coureurs dans tDrawG4');
		Info(tDrawG5:GetNbRows()..' coureurs dans tDrawG5');
	end
	-- on continue avec les points FIS
	nb_exaequo = 0;
	-- rang_tirage = rang_tirage + tDrawG4:GetNbRows();
	if draw.debug then
		Info('avant le tirage par pts FIS, rang_tirage = '..rang_tirage);
	end
	if draw.debug == true then
		Info('Avant le final par pts FIS, il reste : ');
		Info(tDrawG6:GetNbRows()..' coureurs dans tDrawG6');
	end
	if draw.debug == true then
		Info('draw.ptsFIS15 = '..tostring(draw.ptsFIS15));
	end
	nb_exaequo = 0;
	tDrawG6:OrderBy('FIS_pts');			-- on continue avec les points FIS
	if tDrawG6:GetNbRows() > 0 then
		current_group = current_group + 1;
		rang_tirage = rang_tirage + 1;
		for i = 0, tDrawG6:GetNbRows() -1 do
			local pts = tDrawG6:GetCellDouble('FIS_pts', i);
			if not draw.bolVitesse then
				if draw.code_niveau == 'NC' then		-- Championnats de France
					if pts <= draw.ptsFIS7 then
						current_group = 1;
					elseif pts <= draw.ptsFIS15 then
						current_group = 2;
					else
						current_group = 3;
					end
				elseif not draw.bolEstCE then
					if pts <= draw.ptsFIS15 then
						current_group = 1;
					else
						current_group = 2;
					end
				end
			end
			if current_group == 1 then
				if pts > draw.ptsFIS15 then
					current_group = 2;
				end
			end
			local code_coureur = tDrawG6:GetCell('Code_coureur', i);
			if i > 0 then
				if pts > tDrawG6:GetCellDouble('FIS_pts', i-1) then
					rang_tirage = rang_tirage + 1 + nb_exaequo;
					nb_exaequo = 0;
				else
					nb_exaequo = nb_exaequo + 1;
				end
			end
			local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
			if code_coureur == draw.ajouter_code then
				tDraw:SetCell('Statut', r, 'CF');
			end
			tDraw:SetCell('Pris', r, 1);
			tDraw:SetCell('Groupe_tirage', r, current_group);
			tDraw:SetCell('Rang_tirage', r, rang_tirage);
			tDraw:SetCell('Groupe', r, current_group);
			tDraw:SetCell('Critere', r, string.format('%03d', tDraw:GetCellInt('Rang_tirage', r)));
			if draw.debug == true then
				Info(tDraw:GetCell('Nom', r)..', pts lus = '..pts..', Rang_tirage = '..tDraw:GetCellInt('Rang_tirage', r)..', current_group = '..current_group);
			end
		end
	end
	rang_tirage = rang_tirage + 1;
	current_group = current_group + 1;
	for i = 0, tDraw:GetNbRows() -1 do
		if draw.debug == true then
			Info(tDraw:GetCell('Nom', i)..', Pris = '..tDraw:GetCellInt('Pris', i));
		end
		if tDraw:GetCellInt('Pris', i) == 0 then
			if draw.debug == true then
				Info(tDraw:GetCell('Nom', i)..' pas encore pris ...');
			end
			tDraw:SetCell('Pris', i, 1);
			tDraw:SetCell('Rang_tirage', i, rang_tirage);
			tDraw:SetCell('Groupe_tirage', i, current_group);
			tDraw:SetCell('Critere', i, string.format('%03d', rang_tirage));
		end
	end
	
	ChecktDraw();
end

function OnAfficheTableau()
	if not draw.socket then
		parentFrame = wnd.GetParentFrame();
		draw.socket = socketClient.Open(parentFrame, draw.hostname, draw.port);
		draw.socket_state = false;
		parentFrame:Bind(eventType.SOCKET, OnSocketLive, draw.socket);
	end
-- Création Dialog 
	draw.label_dialog = 'Tableau des coureurs - discipline de la course : '..draw.discipline..'  - version '..draw.version..' du script';
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
			xml = './process/live_draw.xml',
			node_name = 'root/panel', 
			node_attr = 'name', 	
			node_value = 'gridCE' 
		});
	else
		dlgTableau:LoadTemplateXML({ 
			xml = './process/live_draw.xml',
			node_name = 'root/panel', 
			node_attr = 'name', 	
			node_value = 'gridFIS' 
		});
	end
	
	draw.timer = timer.Create(dlgTableau);

-- Grid 
	grid_tableau = dlgTableau:GetWindowName('tableau');
	BuildTablesDraw();

	local cmd ='Select r.*, rit.* , Repeat(" ",10) Action, Concat(Prenom, Nom) Identite, Repeat(" ",7) TG, 0 Pris ';
	cmd = cmd..'From Resultat r ';
	cmd = cmd..'Left Join Resultat_Info_Tirage rit On r.Code_evenement = rit.Code_evenement And r.Code_coureur = rit.Code_coureur ';
	cmd = cmd..'Where r.Code_evenement = '..draw.code_evenement;
	tDraw = base:TableLoad(cmd);
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
	tDraw:SetColumn('Statut', { label = 'UF/CF', width = 6 });
	tDraw:SetPrimary('Code_evenement, Code_coureur');
	ReplaceTableEnvironnement(tDraw, '_Draw');
	
	if draw.bolEstCE then
		if not draw.bolVitesse then
			grid_tableau:Set({
				table_base = tDraw,
				columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, ECSL_points, ECSL_rank, WCSL_points, WCSL_rank, ECSL_overall_points, ECSL_overall_rank, Winner_CC, FIS_pts, FIS_clt, Statut, Action',
				selection_mode = gridSelectionModes.CELLS,
				sortable = true,
				enable_editing = true
			});
		else
			grid_tableau:Set({
				table_base = tDraw,
				columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, ECSL_points, ECSL_rank, WCSL_points, WCSL_rank, ECSL_overall_points, ECSL_overall_rank, Winner_CC, FIS_pts, FIS_clt, FIS_SG_pts, FIS_SG_clt, Statut, Action',
				selection_mode = gridSelectionModes.CELLS,
				sortable = true,
				enable_editing = true
			});
		end
	else
		grid_tableau:Set({
			table_base = tDraw,
			columns = 'Dossard, Rang_tirage, Groupe_tirage, Code_coureur, Nom, Prenom, Nation, Comite, Club, FIS_pts, FIS_clt, Statut, Action',
			selection_mode = gridSelectionModes.CELLS,
			sortable = true,
			enable_editing = true
		});
	end

	grid_tableau:AddColumnLabel(3);
    grid_tableau:AddRowLabel(1, 48);
	OnOrder();

-- Initialisation des Controles
	
	tbTableau = dlgTableau:GetWindowName('tbtableau');
	tbTableau:AddStretchableSpace();
	btnSendMessage = tbTableau:AddTool("Envoyer un message", "./res/32x32_journal.png");
	tbTableau:AddSeparator();
	btnMenuRAZ = tbTableau:AddTool("RAZ des données", "./res/32x32_journal.png",'', itemKind.DROPDOWN);
	tbTableau:AddSeparator();
	btnOrder = tbTableau:AddTool("Trier le tableau", "./res/32x32_bib.png");
	tbTableau:AddSeparator();
	btnClear = tbTableau:AddTool("RAZ à la FIS", "./res/32x32_clear.png");
	
	menuRAZ = menu.Create();
	btnRAZRang = menuRAZ:Append({label="RAZ des rangs", image ="./res/32x32_clear.png"});
	menuRAZ:AppendSeparator();
	btnRAZGroupe = menuRAZ:Append({label="RAZ des groupes", image ="./res/32x32_clear.png"});
	menuRAZ:AppendSeparator();
	btnRAZAll = menuRAZ:Append({label="RAZ des deux", image ="./res/32x32_clear.png"});
	menuRAZ:AppendSeparator();
	btnRAZDossard = menuRAZ:Append({label="RAZ des dossards", image ="./res/32x32_clear.png"});
	tbTableau:SetDropdownMenu(btnMenuRAZ:GetId(), menuRAZ);
	
	tbTableau:AddSeparator();
	btnMenuSend = tbTableau:AddTool("Menu des envois", "./res/32x32_send.png",'', itemKind.DROPDOWN);

	menuSend = menu.Create();
	btnSendTableau = menuSend:Append({label="Envoi du tableau à la FIS", image ="./res/32x32_send.png"});
	menuSend:AppendSeparator();
	btnSendDossards = menuSend:Append({label="Renvoi de tous les dossards", image ="./res/32x32_send.png"});
	menuSend:AppendSeparator();
	tbTableau:SetDropdownMenu(btnMenuSend:GetId(), menuSend);

	tbTableau:AddSeparator();
	btnValider = tbTableau:AddTool("Menu des validations", "./res/32x32_send.png",'', itemKind.DROPDOWN);
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
	btnMenuPrint = tbTableau:AddTool("Menu des impressions", "./res/32x32_printer.png",'', itemKind.DROPDOWN);
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
	btnPrintFeuilleTirage = menuPrint:Append({label="Impression de la feuille de tirage", image ="./res/32x32_printer.png"});
	menuPrint:AppendSeparator();
	tbTableau:SetDropdownMenu(btnMenuPrint:GetId(), menuPrint);

	tbTableau:AddSeparator();
	btnOutils = tbTableau:AddTool("Menu des outils", "./res/32x32_tools.png",'', itemKind.DROPDOWN);
	menuOutils = menu.Create();
	menuOutils:AppendSeparator();
	btnTirageDossardsBIBO = menuOutils:Append({label="Double tirage à la mêlée du BIBO", image ="./res/32x32_bib.png"});
	menuOutils:AppendSeparator();
	btnTirageDossardsRestants = menuOutils:Append({label="Tirage des dossards restants (avec points)", image ="./res/32x32_bib.png"});
	menuOutils:AppendSeparator();
	btnTirageDossardsSansPoints = menuOutils:Append({label="Double tirage à la mêlée (sans points)", image ="./res/32x32_bib.png"});
	menuOutils:AppendSeparator();
	btnWeb = menuOutils:Append({label="Vers la page FIS de la course", image ="./res/32x32_fis.png"});
	menuOutils:AppendSeparator();
	btnDecalerBas = menuOutils:Append({label="Décaler les rangs de tirage vers le bas", image ="./res/32x32_list_add.png"});
	menuOutils:AppendSeparator();
	btnDecalerHaut = menuOutils:Append({label="Décaler les rangs de tirage vers le haut", image ="./res/32x32_list_remove.png"});
	menuOutils:AppendSeparator();
	btnDecalerGroupeBas = menuOutils:Append({label="Décaler les groupes de tirage vers le bas", image ="./res/32x32_down.png"});
	menuOutils:AppendSeparator();
	btnDecalerGroupeHaut = menuOutils:Append({label="Décaler les groupes de tirage vers le haut", image ="./res/32x32_up.png"});
	menuOutils:AppendSeparator();
	btnAideCE = menuOutils:Append({label="Aide / ranking en CE", image ="./res/32x32_ranking.png"});
	menuOutils:AppendSeparator();
	tbTableau:SetDropdownMenu(btnOutils:GetId(), menuOutils);

	tbTableau:AddSeparator();
	btnClose = tbTableau:AddTool("Quitter", "./res/32x32_exit.png");
	tbTableau:AddStretchableSpace();
	
 	tbTableau:Realize();
	-- tbTableau:EnableTool(btnSendMessage:GetId(), draw.socket_state);
	-- tbTableau:EnableTool(btnClear:GetId(), draw.socket_state);
	-- tbTableau:EnableTool(btnMenuSend:GetId(), draw.socket_state);

	-- tbTableau:EnableTool(btnPrintDoubleTirageBibo:GetId(), false);
	-- pour le moment, EnableTool ne marche que bour des boutons de premier niveau et pas dans un menu
	
	RefreshCounterSequence();
	-- Prise des Evenements (Bind)
	grid_tableau:Bind(eventType.GRID_EDITOR_SHOWN, OnGridShown);
	grid_tableau:Bind(eventType.GRID_CELL_CONTEXT, OnCellContext);
	grid_tableau:Bind(eventType.GRID_CELL_CHANGED, OnCellChanged);
	grid_tableau:Bind(eventType.GRID_SELECT_CELL, OnCellSelected);
	
	dlgTableau:Bind(eventType.TIMER, OnTimerRunning, draw.timer);
	draw.timer:Start(480000);	-- toutes les 8 minutes (8x60x1000ms) on envoie une commande keepalive

	dlgTableau:Bind(eventType.MENU, OnSendMessage, btnSendMessage);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.skip_question = false;
			OnRAZData('Dossard')
			SendMessage('Board refreshed');
		end, btnRAZDossard);
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
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			ChecktDraw();
			OnPrintDoubleTirage(1);
			if not draw.bolVitesse then
				if draw.bolEstCE or draw.code_niveau == 'NC' then
					OnPrintDoubleTirage(2);
				end
			end
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
			CommandSendList();
			CommandSendOrder();
			CommandRenvoyerDossards();
			base:TableBulkUpdate(tDraw, 'Statut', 'Resultat_Info_Tirage');
		end
		, btnValiderSelection);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local t = grid_tableau:GetTable();
			local indexcol = t:GetVisibleColumnsIndex('Statut');
			for row = 0, t:GetNbRows() -1 do
				t:SetCell('Statut', row, 'UF');
				grid_tableau:RefreshCell(row, indexcol);
				if draw.debug then
					Info('grid_tableau:RefreshCell('..tostring(row)..', '..tostring(indexcol));
				end
			end
			grid_tableau:SynchronizeRowsView(); -- on est sur la vue
			CommandSendList();
			CommandSendOrder();
			CommandRenvoyerDossards();
			base:TableBulkUpdate(tDraw, 'Statut', 'Resultat_Info_Tirage');
		end
		, btnInValiderSelection);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			OnSendTableau()
			SendMessage('Board refreshed');
		end
		, btnSendTableau);
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
			SendMessage('Board and bibs refreshed');
		end
		, btnSendDossards);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local msg = "Cliquer sur Oui pour lancer le double tirage du BIBO.\n"..
					"Les coureurs doivent être validés sur le tableau au préalable.\n\n"..
					"Vous pourrez retrouver cette impression plus tard\n"..
					"même si vous sortez du programme.\n"..
					"Il est conseillé d'en faire une impression au format PDF.";
			if dlgTableau:MessageBox(
				msg, "Attribution des dossards",
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
			end
			draw.print_alone = false;
			ChecktDraw();
			if draw.statut == 'UF' then
				local msg = "Tous les coureurs n'on pas été Validés !!!";
				dlgTableau:MessageBox(msg, "Erreur", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			draw.start_Bib = nil;
			-- draw.EnableToolPrintBibo = true;
			tDrawG6 = tDraw:Copy();
			ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
			for i = tDrawG6:GetNbRows() -1, 0, -1 do
				local groupe_tirage = tDrawG6:GetCellInt('Groupe_tirage', i, -1);
				if groupe_tirage < 0 or groupe_tirage > 1 then
					tDrawG6:RemoveRowAt(i);
				end
			end
			params.nb_groupe1 = tDrawG6:GetNbRows();
			BuildTableTirage(1, tDrawG6:GetNbRows() - 1);
			CommandRenvoyerDossards(false);
			OnPrintDoubleTirage(1);
			if not draw.bolVitesse then
				if draw.bolEstCE or draw.code_niveau == 'NC' then
					tDrawG6 = tDraw:Copy();
					ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
					tDrawG6:OrderBy('Rang_tirage');
					for i = tDrawG6:GetNbRows() -1, 0, -1 do
						local groupe_tirage = tDrawG6:GetCellInt('Groupe_tirage', i, -1);
						if groupe_tirage ~= 2 then
							tDrawG6:RemoveRowAt(i);
						end
					end
					BuildTableTirage(params.nb_groupe1 + 1, tDrawG6:GetNbRows() -1);
					CommandRenvoyerDossards(false);
					OnPrintDoubleTirage(2);
				end
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
			if draw.tRang_tirageauto and #draw.tRang_tirageauto > 0 then
				local msg = "Voulez-vous tirer les dossards des exaequos par double tirage ?\n"..
						"Les coureurs doivent être validés sur le tableau au préalable.";
				reponse = dlgTableau:MessageBox(
					msg, "Attribution des dossards",
					msgBoxStyle.YES+msgBoxStyle.NO+msgBoxStyle.CANCEL+msgBoxStyle.CANCEL_DEFAULT+msgBoxStyle.ICON_INFORMATION
				);
				if reponse == msgBoxStyle.YES then
					draw.tirage_auto = true;
				else
					draw.tirage_auto = false;
					if reponse == msgBoxStyle.CANCEL then
						return;
					end
				end
			end
			-- tirage du groupe 1 FIS, CE discipline technique groupe 1 ou CE de vitesse
			-- for i = tDrawG6:GetNbRows() -1, 0, -1 do
				-- local groupe_tirage = tDrawG6:GetCellInt('Groupe_tirage', i, -1);
				-- if groupe_tirage < 0 or groupe_tirage > 1 then
					-- tDrawG6:RemoveRowAt(i);
				-- end
			-- end
			-- params.nb_groupe1 = tDrawG6:GetNbRows();
			-- BuildTableTirage(1);
			-- OnPrintDoubleTirage(1);
			-- CommandRenvoyerDossards(false);
			if not draw.bolEstCE then
				-- on commence par tirer les exaequos
				draw.start_Bib = nil;
				for i = 0, tDraw:GetNbRows() -1 do
					if draw.code_niveau ~= 'NC' then
						if tDraw:GetCellInt('Groupe_tirage', i) == 1 then
							draw.start_Bib = i + 1;
						else
							break;
						end
					else
						if not draw.bolVitesse then
							if tDraw:GetCellInt('Groupe_tirage', i) < 3 then
								draw.start_Bib = i + 1;
							else
								break;
							end
						else
							if tDraw:GetCellInt('Groupe_tirage', i) == 1 then
								draw.start_Bib = i + 1;
							else
								break;
							end
						end
					end
				end
				draw.bib_done = true;
				if draw.start_Bib > 0 then
					grid_tableau:SelectRow(draw.start_Bib);
				else
					return;
				end
				if #draw.tRang_tirageauto > 0 then	-- il y a des rangs de depart à tirer
					OnTirageAuto();
				end
				for i = draw.start_Bib, tDraw:GetNbRows() -1 do
					if tDraw:GetCellDouble('FIS_pts', i, -1) < 0 then
						break;
					end
					local dossard = tDraw:GetCellInt('Dossard', i);
					local rang_tirage = tDraw:GetCellInt('Rang_tirage', i);
					local groupe_tirage = tDraw:GetCellInt('Groupe_tirage', i);
					local code_coureur = tDraw:GetCell('Code_coureur', i);
					if dossard == 0 then
						dossard = rang_tirage;
						tDraw:SetCell('Dossard', i, dossard);
						local cmd = "Update Resultat Set Dossard = "..dossard..", Critere = '"..string.format('%03d', rang_tirage).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
						base:Query(cmd);
					elseif dossard == 1000 then
						tDraw:SetCellNull('Dossard', i)
						local cmd = "Update Resultat Set Dossard = NULL, Critere = '"..string.format('%03d', rang_tirage).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..code_coureur.."'";
						base:Query(cmd);
					end
				end
			else
				tDraw:OrderBy('Rang_tirage')
				for i = 0, tDraw:GetNbRows() -1 do
					if tDraw:GetCellDouble('FIS_pts', i) == 0 then
						break;
					end
					local dossard = tDraw:GetCellInt('Dossard', i);
					local rang_tirage = tDraw:GetCellInt('Rang_tirage', i);
					local groupe_tirage = tDraw:GetCellInt('Groupe_tirage', i);
					if draw.bolVitesse then
						if dossard == 0 and i < 30 then
							if #draw.tDossardsAvailable > 0 then
								dossard = draw.tDossardsAvailable[1];
								table.remove(draw.tDossardsAvailable, 1);
								tDraw:SetCell('Dossard', i, dossard);
								local cmd = "Update Resultat Set Dossard = "..dossard..", Critere = '"..string.format('%03d', tDraw:GetCellInt('Rang_tirage', i)).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..tDraw:GetCell('Code_coureur', i).."'";
								base:Query(cmd);
							end
						end
					end
					if dossard == 0 then
						Info('dossard = 0, i = '..i..', draw.tRows_nepastirer['..rang_tirage..'] = '..tostring(draw.tRows_nepastirer[rang_tirage]));
						if not draw.tRows_nepastirer[rang_tirage] then
							local dossard = rang_tirage;
							tDraw:SetCell('Dossard', i, dossard);
							local cmd = "Update Resultat Set Dossard = "..dossard..", Critere = '"..string.format('%03d', tDraw:GetCellInt('Rang_tirage', i)).."' Where Code_evenement = "..draw.code_evenement.." And Code_coureur = '"..tDraw:GetCell('Code_coureur', i).."'";
							base:Query(cmd);
						else
							tDrawG6 = tDraw:Copy();
							ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
							for i = tDrawG6:GetNbRows() -1, 0, -1 do
								if tDrawG6:GetCellInt('Rang_tirage', i, -1) ~= rang_tirage then
									tDrawG6:RemoveRowAt(i);
								end
							end
							tDrawG6:OrderRandom('FIS_pts');
							local tShuffle = {};
							for i = 0, tDrawG6:GetNbRows() -1 do
								-- table.insert(tShuffle, i+1);
								table.insert(tShuffle, rang_tirage + i);
							end
							tShuffle = Shuffle(tShuffle, true);
							for i = 0, tDrawG6:GetNbRows() -1 do
								local valeur_shuffle = tShuffle[i+1];
								local dossard = valeur_shuffle ;
								local code_coureur = tDrawG6:GetCell('Code_coureur', i)
								local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
								if r >= 0 then
									if draw.tirage_auto then
										tDraw:SetCell('Dossard', r, dossard);
									end
								end
							end
						end
					end						
				end
			end
			RefreshGrid()
			CommandRenvoyerDossards(false);
		end
		, btnTirageDossardsRestants);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			draw.start_Bib = nil;
			local msg = "Cliquer sur Oui pour lancer l'attribution\n"..
					"des dossards pour les coureurs sans points FIS\n"..
					"Les coureurs doivent être validés sur le tableau au préalable.";
			if dlgTableau:MessageBox(
				msg, "Attribution des dossards",
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION
			) ~= msgBoxStyle.YES then
				return;
			end
			ChecktDraw();
			if draw.statut == 'UF' then
				local msg = "Tous les coureurs n'on pas été Validés !!!";
				dlgTableau:MessageBox(msg, "Erreur", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				return;
			end
			tDrawG6 = tDraw:Copy();
			ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
			for i = tDrawG6:GetNbRows() -1, 0, -1 do
				if tDrawG6:GetCellDouble('FIS_pts', i, -1) >= 0 then
					tDrawG6:RemoveRowAt(i);
				end
			end
			local bib_first = tDraw:GetNbRows() - tDrawG6:GetNbRows() + 1 ;
			
			local tShuffle = {};
			-- 130 en tout,  30 restants dans tDrawG6 ==> 130 - 30 = 100 avec des points ==> bib_first = 101 
			for i = 0, tDrawG6:GetNbRows() -1 do
				local bib = bib_first + i ;
				table.insert(tShuffle, bib);
			end
			tShuffle = Shuffle(tShuffle, true);
			tDrawG6:OrderBy('Identite');
			tDrawG6:OrderRandom();
			for i = 0, tDrawG6:GetNbRows() -1 do
				local valeur_shuffle = tShuffle[i+1];
				local code_coureur = tDrawG6:GetCell('Code_coureur', i)
				local r = tDraw:GetIndexRow('Code_coureur', code_coureur);
				if r >= 0 then
					tDraw:SetCell('Dossard', r, valeur_shuffle);
				end
			end
			RefreshGrid();
			CommandRenvoyerDossards(false);
		end
		, btnTirageDossardsSansPoints);		
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			OnWebDraw(draw.web)
		end, btnWeb);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local msg = "Voulez-vous décaler les rangs de tirage de UN vers le bas\n"..
						"à partir de la ligne sélectionnée ?";
			if dlgTableau:MessageBox(
				msg, "Décalage des rangs de tirage", 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				local rowsSelected = grid_tableau:GetSelectedRows();
				if #rowsSelected == 0 then 	-- Aucune ligne sélectionnée ...
					return;
				end
				local row = rowsSelected[1]; 
				OnDecaler(row, true, false);
			end
		end, btnDecalerBas);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local msg = "Voulez-vous décaler les rangs de tirage de UN vers le haut\n"..
						"à partir de la ligne sélectionnée ?";
			if dlgTableau:MessageBox(
				msg, "Décalage des rangs de tirage", 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				local rowsSelected = grid_tableau:GetSelectedRows();
				if #rowsSelected == 0 then 	-- Aucune ligne sélectionnée ...
					return;
				end
				local row = rowsSelected[1]; 
				OnDecaler(row, false, false);
			end
		end, btnDecalerHaut);

	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local msg = "Voulez-vous décaler les groupes de tirage de UN vers le bas\n"..
						"à partir de la ligne sélectionnée ?";
			if dlgTableau:MessageBox(
				msg, "Décalage des groupes de tirage", 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				local rowsSelected = grid_tableau:GetSelectedRows();
				if #rowsSelected == 0 then 	-- Aucune ligne sélectionnée ...
					return;
				end
				local row = rowsSelected[1]; 
				OnDecaler(row, true, true);
			end
		end, btnDecalerGroupeBas);
	dlgTableau:Bind(eventType.MENU, 
		function(evt)
			local msg = "Voulez-vous décaler les groupes de tirage de UN vers le haut\n"..
						"à partir de la ligne sélectionnée ?";
			if dlgTableau:MessageBox(
				msg, "Décalage des groupes de tirage", 
				msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.YES then
				local rowsSelected = grid_tableau:GetSelectedRows();
				if #rowsSelected == 0 then 	-- Aucune ligne sélectionnée ...
					return;
				end
				local row = rowsSelected[1]; 
				OnDecaler(row, false, true);
			end
		end, btnDecalerGroupeHaut);

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
			local code_coureur = dlgTableau:GetWindowName('code'):GetValue();
			local nom, prenom, sexe, an, nation, comite, club, points, classement = OnChercheCoureurCode(code_coureur);
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

	dlgTableau:Bind(eventType.BUTTON, 
		function(evt)
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
	draw.code_evenement = params_c.code_evenement;
	params.code_evenement = params_c.code_evenement;
	if draw.code_evenement < 0 then
		return;
	end
	draw.debug = false;
	draw.width = display:GetSize().width;
	draw.height = display:GetSize().height - 30;
	draw.x = 0;
	draw.y = 0;
	draw.version = "1.32";
	draw.orderbyCE = 'Rang_tirage, Groupe_tirage, ECSL_points DESC, WCSL_points DESC, ECSL_overall_points DESC, Winner_CC DESC, FIS_pts, Nom, Prenom';
	draw.orderbyFIS = 'Rang_tirage, Groupe_tirage, FIS_pts, Nom, Prenom';
	draw.hostname = 'live.fisski.com';
	draw.method = 'socket';
	draw.ajouter_code = '';
	draw.directory = app.GetPath()..'/live_draw/';
	base = base or sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	tResultat = base:GetTable('Resultat');
	tEpreuve = base:GetTable('Epreuve');
	tPistes = base:GetTable('Pistes');
	tNation = base:GetTable('Nation');
	tResultat_Info_Tirage = base:GetTable('Resultat_Info_Tirage');
	if tResultat_Info_Tirage == nil then
		CreateTableResultat_Info_Tirage();
	end
	tResultat_Info_Bibo = base:GetTable('Resultat_Info_Bibo');
	if tResultat_Info_Bibo == nil then
		CreateTableResultat_Info_Bibo();
	end
	tCoureur = base:GetTable('Coureur');
	tCategorie = base:GetTable('Categorie');
	tClassement_Coureur = base:GetTable('Classement_Coureur');
	tEpreuve_Alpine_Manche = base:GetTable('Epreuve_Alpine_Manche');
	
	tTableTirage1 = sqlTable.Create('_TableTirage1');
	tTableTirage1:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage1, '_TableTirage1');
	tTableTirage2 = sqlTable.Create('_TableTirage2');
	tTableTirage2:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage2, '_TableTirage2');

	draw.code_piste = tEpreuve_Alpine_Manche:GetCellInt('Code_piste', 0);
	base:TableLoad(tPistes, "Select * From Pistes Where Code_activite = 'ALP' And Matricule = "..draw.code_piste);
	draw.code_liste = tEvenement:GetCellInt("Code_liste", 0)
	draw.code_entite = tEvenement:GetCell("Code_entite",0);
	draw.code_activite = tEvenement:GetCell("Code_activite",0);
	draw.code_niveau = tEpreuve:GetCell('Code_niveau', 0);
	draw.sexe = tEpreuve:GetCell('Sexe', 0);
	if draw.code_niveau ~= 'EC' then
		draw.bolEstCE = false;
	else
		draw.bolEstCE = true;
	end
	draw.code_saison = tEvenement:GetCell("Code_saison", 0);
	draw.discipline = tEpreuve:GetCell('Code_discipline', 0);
	draw.bolVitesse = false;
	if draw.discipline == 'DH' or draw.discipline == 'SG' then
		draw.bolVitesse = true;
	end
	draw.code_grille_categorie = tEpreuve:GetCell("Code_grille_categorie", 0);
	if draw.code_activite ~= 'ALP' or draw.code_entite ~= 'FIS' then
		local msg = "L'environnement ne permet pas la mise \nen ligne du tableau des coureurs\nsur le site de la FIS !!";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
		return;
	end

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
		draw.pwd = nodelivedraw:GetAttribute('pwd', 'toto');
		draw.sequence_send = tonumber(nodelivedraw:GetAttribute('send', 0)) or 0;;
		draw.sequence_ack = tonumber(nodelivedraw:GetAttribute('ack', 0)) or 0;
		draw.sequence_last_send = draw.sequence_send;
	end
	draw.targetName = draw.hostname..':'..draw.port;
	draw.web = 'live.fis-ski.com/lv-'..string.lower(string.sub(draw.code_activite,1,2))..draw.codex..'.htm';
	draw.state = true;
	draw.double_tirage_bibo = false;
	draw.tRows_nepastirer = {};
	draw.tRang_tirageauto = {};
	draw.tModifs_tableau = {};
	draw.raz_sequence = false;
	draw.print_alone = true;

	dlgConfig = wnd.CreateDialog(
		{
		width = draw.width,
		height = draw.height,
		x = draw.x,
		y = draw.y,
		label='Informations de connexion', 
		icon='./res/32x32_fis.png'
		});
	
	dlgConfig:LoadTemplateXML({ 
		xml = './process/live_draw.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 
		discipline = draw.discipline;
		node_value = 'config' 
	});

	-- Toolbar Principale ...
	local tbconfig = dlgConfig:GetWindowName('tbconfig');
	tbconfig:AddStretchableSpace();
	local btnSave = tbconfig:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	local message = app.GetAuiMessage();

	dlgConfig:GetWindowName('fis_hostname'):SetValue('live.fisski.com');
	dlgConfig:GetWindowName('fis_port'):SetValue(draw.port);
	dlgConfig:GetWindowName('fis_pwd'):SetValue(draw.pwd);
	
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			draw.pwd = dlgConfig:GetWindowName('fis_pwd'):GetValue();
			nodelivedraw:ChangeAttribute('port', dlgConfig:GetWindowName('fis_port'):GetValue());
			nodelivedraw:ChangeAttribute('pwd', draw.pwd);
			nodelivedraw:ChangeAttribute('send', 0);
			nodelivedraw:ChangeAttribute('ack', 0);
			draw.doc:SaveFile();
			dlgConfig:EndModal(idButton.OK) 
		end, btnSave); 
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			if draw.doc then
				draw.doc:SaveFile();
			end
			dlgConfig:EndModal(idButton.CANCEL) 
		 end,  btnClose);

	if dlgConfig:ShowModal() == idButton.OK then
		local cmd = "Update Resultat Set Critere = NULL, Groupe = NULL Where Code_evenement = "..draw.code_evenement;
		base:Query(cmd);
		OnAfficheTableau();
	end
end

