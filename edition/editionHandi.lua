dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
dofile('./edition/traductionPG.lua');

function SortTable(array)	-- tri des tables 
	table.sort(array, function (u,v)
		return 
			 u['Clt'] < v['Clt'];
	end)
end

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

function ConfigHandi()
	dlgConfig = wnd.CreateDialog(
		{
		width = 600,
		height = 350,
		x = (display:GetSize().width - 200) / 2, 
		y = (display:GetSize().height - 150) / 2, 
		label='Selection de la manche', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgConfig:LoadTemplateXML({ 
		xml = './edition/editionHandi.xml', 	-- Obligatoire
		node_name = 'edition/panel', 			
		node_attr = 'name', 				
		node_value = 'config', 		
		base = base
	});

	dlgConfig:GetWindowName('mode'):Clear();
	dlgConfig:GetWindowName('mode'):Append('FFS');
	dlgConfig:GetWindowName('mode'):Append('WPAS');
	dlgConfig:GetWindowName('mode'):SetValue(handi.mode);
	
	dlgConfig:GetWindowName('language'):Clear();
	dlgConfig:GetWindowName('language'):Append('Français');
	dlgConfig:GetWindowName('language'):Append('Anglais');
	if language == 'fr' then
		dlgConfig:GetWindowName('language'):SetValue('Français');
	else
		dlgConfig:GetWindowName('language'):SetValue('Anglais');
	end

	dlgConfig:Bind(eventType.TEXT, 
		function(evt)
			if dlgConfig:GetWindowName('language'):GetValue() == 'Français' and dlgConfig:GetWindowName('mode'):GetValue() == 'WPAS' then
				dlgConfig:GetWindowName('language'):SetValue('Anglais');
			end
		end,
		dlgConfig:GetWindowName('language'))

	dlgConfig:Bind(eventType.TEXT, 
		function(evt)
			if dlgConfig:GetWindowName('language'):GetValue() == 'Français' and dlgConfig:GetWindowName('mode'):GetValue() == 'WPAS' then
				dlgConfig:GetWindowName('language'):SetValue('Anglais');
			end
		end,
		dlgConfig:GetWindowName('mode'))

	-- Toolbar 
	local tb = dlgConfig:GetWindowName('tb');
	tb:AddSeparator();
	local btnOK = tb:AddTool("Sauvegarder", "./res/32x32_save.png");
	tb:AddSeparator();
	local btnKO = tb:AddTool("Annuler", "./res/32x32_quit.png");
	tb:AddSeparator();
	
	tb:Bind(eventType.MENU, function(evt) dlgConfig:EndModal(idButton.OK) end, btnOK);
	tb:Bind(eventType.MENU, function(evt) dlgConfig:EndModal(idButton.CANCEL) end, btnKO);
	tb:Realize();
	dlgConfig:Fit();
	if dlgConfig:ShowModal() == idButton.OK then
		if dlgConfig:GetWindowName('language'):GetValue() == 'Français' then
			language = 'fr';
		else
			language = 'en';
		end
		
		handi.mode = dlgConfig:GetWindowName('mode'):GetValue();
		nodehandi:ChangeAttribute('language', language);
		nodehandi:ChangeAttribute('mode', handi.mode);
		handi.doc:SaveFile();
	end
end

function PageBreak()	-- boîte de dialogue pour le saut de page à la rupture
	page_break = 0;
	if app.GetAuiFrame():MessageBox(
		"Voulez-vous un saut de page à chaque rupture ?", 
		"Saut de page Oui / Non",
		msgBoxStyle.YES_NO + msgBoxStyle.ICON_INFORMATION
		) == msgBoxStyle.YES then
		page_break = 1;
	end
	return page_break;
end

function ChoixManche()	-- boîte de dialogue pour la sélection de la manche.
	dlgManche = wnd.CreateDialog(
		{
		width = 300,
		height = 150,
		x = (display:GetSize().width - 200) / 2, 
		y = (display:GetSize().height - 150) / 2, 
		label='Selection de la manche', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgManche:LoadTemplateXML({ 
		xml = './edition/editionHandi.xml', 	-- Obligatoire
		node_name = 'edition/panel', 			
		node_attr = 'name', 				
		node_value = 'choix_manche', 		
		base = base
	});

	for run = 1, handi.nb_manche do
		dlgManche:GetWindowName('manche'):Append(run);
	end
	dlgManche:GetWindowName('manche'):SetValue(1);
	-- Toolbar 
	local tb = dlgManche:GetWindowName('tb');
	tb:AddSeparator();
	local btnOK = tb:AddTool("OK", "./res/32x32_save.png");
	tb:AddSeparator();
	local btnKO = tb:AddTool("Annuler", "./res/32x32_quit.png");
	tb:AddSeparator();
	tb:Bind(eventType.MENU, function(evt) dlgManche:EndModal(idButton.OK) end, btnOK);
	tb:Bind(eventType.MENU, function(evt) dlgManche:EndModal(idButton.CANCEL) end, btnKO);
	tb:Realize();
	dlgManche:Fit();
	if dlgManche:ShowModal() == idButton.OK then
		choix_manche = tonumber(dlgManche:GetWindowName('manche'):GetValue());
	else
		choix_manche= 0;
	end
	return choix_manche;
end

function main(cparams)
	handi = cparams;
	handi.choix_manche = tonumber(handi.choix_manche) or 0;
	handi.page_break = tonumber(handi.page_break) or 1;
	
	handi.orderby = handi.orderby or '';
	handi.doc = app.GetXML();
	handi.docRoot = handi.doc:GetRoot();
	nodehandi = handi.doc:FindFirst('main/handi');
	if not nodehandi then
		nodehandi = xmlNode.Create(handi.docRoot, xmlType.ELEMENT_NODE, "handi");
		nodehandi:AddAttribute('mode', 'FFS');
		nodehandi:AddAttribute('language', 'fr');
		language = 'fr';
		handi.mode = 'FFS';
	else
		language = nodehandi:GetAttribute('language', 'fr');
		handi.mode = nodehandi:GetAttribute('mode', 'FFS');
	end
	handi.doc:SaveFile();
	handi.config = tonumber(handi.config) or 0;
	if handi.config == 1 then
		ConfigHandi();
		return;
	end

	GetParamsXML();
	base = base or sqlBase.Clone();
	code_evenement = handi.code_evenement;
	tRanking = base:GetTable('body'):Copy();
	tRanking:AddColumn({ name = 'Tps_status', label = 'Tps_status', type = sqlType.CHAR, width = 5, style = sqlStyle.NULL });
	tRanking:AddColumn({ name = 'Tps_g1', label = 'Tps_g1', type = sqlType.CHAR, width = 5, style = sqlStyle.NULL });
	tRanking:AddColumn({ name = 'Tps_g2', label = 'Tps_g2', type = sqlType.CHAR, width = 5, style = sqlStyle.NULL });
	tRanking:AddColumn({ name = 'Tps_g3', label = 'Tps_g3', type = sqlType.CHAR, width = 5, style = sqlStyle.NULL });
	tRanking:AddColumn({ name = 'Tps_g4', label = 'Tps_g4', type = sqlType.CHAR, width = 5, style = sqlStyle.NULL });
	-- tRanking:AddColumn({ name = 'Id_group', label = 'Id_group', type = sqlType.LONG, style = sqlStyle.NULL });
	tRanking:AddColumn({ name = 'Label_group', label = 'Label_group', type = sqlType.CHAR, width = 50, style = sqlStyle.NULL });
	tRanking:AddColumn({ name = 'PtsCM', label = 'PtsCM', type = sqlType.LONG, style = sqlStyle.NULL });
	Evenement = base:GetTable('Evenement');
	Epreuve = base:GetTable('Epreuve');
	Discipline = base:GetTable('Discipline');
	Place_Valeur = base:GetTable('Place_Valeur');
	base:TableLoad(Evenement, 'Select * From Evenement Where Code = '..handi.code_evenement);
	local cmd = 'Select * From Epreuve Where Code_evenement = '..handi.code_evenement;
	if handi.code_epreuve > 0 then
		cmd = cmd..' And Code_epreuve = '..handi.code_epreuve;
	end
	cmd = cmd..' Order By Code_epreuve';
	base:TableLoad(Epreuve, cmd)
	handi.code_discipline = Epreuve:GetCell('Code_discipline', 0);
	handi.code_saison = Evenement:GetCell('Code_saison', 0);
	handi.entite = Evenement:GetCell('Code_entite', 0);
	handi.facteur_f = Discipline:GetCellInt('Facteur_f',0);
	handi.nb_manche = Epreuve:GetCellInt('Nombre_de_manche', 0, 1);
	handi.date_epreuve = Epreuve:GetCell('Date_epreuve', 0);
	local cmd = "SELECT * FROM Place_Valeur WHERE Code_activite = 'CHA-CMB' AND Code_grille = 'FIS-CM' AND Code_saison = '"..handi.code_saison.."'";
	base:TableLoad(Place_Valeur, cmd);

	for row = 0, tRanking:GetNbRows() -1 do
		if tRanking:GetCell('Comite', row) == '' then
			tRanking:SetCell('Comite', row, '-');
		end
		local tps = tRanking:GetCellInt('Tps', row);
		tps_status = chrono.Status(tps);
		
		if tps_status == 'zero'then
			app.GetAuiFrame():MessageBox(
				"Edition impossible, tous les coureurs\nn'ont pas été traités !!", 
				"ATTENTION",
				msgBoxStyle.OK + msgBoxStyle.ICON_WARNING)
			return false;
		end
		tRanking:SetCell('Tps_status', row, tps_status);
		groupe = tRanking:GetCell('Groupe', row);
		if groupe:In('B1','B2','B3') then
			local label = traduction(language, 'Déficient Visuel');
			-- tRanking:SetCell('Id_group', row, 1);
			tRanking:SetCell('Reserve', row, 1);
			tRanking:SetCell('Label_group', row, label);
			tRanking:SetCell('Tps_g1', row, tps_status);
		elseif groupe:In('LW1','LW2','LW3','LW4','LW5/7-1','LW5/7-2','LW5/7-3','LW6/8-1','LW6/8-2','LW9-1','LW9-2') then
			local label = traduction(language, 'Debout');
			-- tRanking:SetCell('Id_group', row, 2);
			tRanking:SetCell('Reserve', row, 2);
			tRanking:SetCell('Label_group', row, label);
			tRanking:SetCell('Tps_g2', row, tps_status);
		elseif groupe:In('LW0') then
			local label = traduction(language, 'Déficient Auditif');
			-- tRanking:SetCell('Id_group', row, 3);
			tRanking:SetCell('Reserve', row, 3);
			tRanking:SetCell('Label_group', row, label);
			tRanking:SetCell('Tps_g3', row, tps_status);
		elseif groupe:In('LW10-1','LW10-2','LW11','LW12-1','LW12-2') then
			local label = traduction(language, 'Assis');
			-- tRanking:SetCell('Id_group', row, 4);
			tRanking:SetCell('Reserve', row, 4);
			tRanking:SetCell('Label_group', row, label);
			tRanking:SetCell('Tps_g4', row, tps_status);
		else
			app.GetAuiFrame():MessageBox(
				"On ne devrait jamais passer ici :\nGroupe inconnu ligne 173 !! = "..groupe, 
				"ATTENTION",
				msgBoxStyle.OK + msgBoxStyle.ICON_WARNING)
			return false;
		end
	end
	tRanking:SetCounter('Tps_g1');
	tRanking:SetCounter('Tps_g2');
	tRanking:SetCounter('Tps_g3');
	tRanking:SetCounter('Tps_g4');
	tRanking:SetCounter('Nation');
	handi.nb_nation = tRanking:GetCounter('Nation'):GetNbRows();
	
	base:TableBulkUpdate(tRanking,'Reserve', 'Resultat');
	-- tRanking:Snapshot('tRanking.db3');
	tRanking:SetRanking('Cltc', 'Tps', 'Sexe,Reserve');
	for i = 1, handi.nb_manche do
		tRanking:SetRanking('Cltc'..i, 'Tps'..i, 'Sexe, Reserve');
	end
	if handi.choix_manche == 1 then
		choix_manche= ChoixManche();
		if choix_manche == 0 then
			return;
		end
	end
	if page_break == 1 then
		page_break = PageBreak();
	end
	margin_first_bottom = 200;
	if string.find(handi.cible, 'res_') then
		if string.find(handi.cible, 'manche') then
			titre = 'RESULTS RUN '..choix_manche;
			handi.cible = 'res_manche';
		else
			tRanking:OrderBy('Id_group, Tps_status Desc, Tps, Dossard Desc');
			titre = 'OFFICIAL RESULTS';
			officiel = tonumber(handi.officiel) or 0;
			if officiel < 1 then
				titre = 'UNOFFICIAL RESULTS';
			end
		end
	elseif string.find(handi.cible, 'lst_') then
		if string.find(handi.cible, 'officiel') then
			titre = 'START LIST RUN '..choix_manche;
			tRanking:OrderBy('Rang, Dossard');
		elseif string.find(handi.cible, 'club') then
			titre = 'START LIST RUN '..choix_manche..' BY CLUB';
		elseif string.find(handi.cible, 'comite') then
			titre = 'START LIST RUN '..choix_manche..' BY COMITE';
		elseif string.find(handi.cible, 'nation') then
			titre = 'START LIST RUN '..choix_manche..' BY NATION';
		end
	elseif string.find(handi.cible, 'parti') then
		if string.find(handi.cible, 'alpha') then
			titre = 'ENTRIES BY ALPHABETIC ORDER';
		-- elseif string.find(handi.cible, 'club') then
			-- titre = 'ENTRIES BY CLUB';
		-- elseif string.find(handi.cible, 'comite') then
			-- titre = 'ENTRIES BY COMITE';
		-- elseif string.find(handi.cible, 'nation') then
			-- titre = 'ENTRIES BY NATION';
		elseif string.find(handi.cible, 'handicap') then
			titre = 'ENTRIES BY SPORT CLASS';
		elseif string.find(handi.cible, 'etiquette') then
			orientation = 'landscape';
			margin_first_bottom = 100;
			titre = 'ENTRIES BY SPORT CLASS';
			if handi.orderby == 'Point' then
				orderby = 'Id_group,Point';
			else
				orderby = 'Id_group,Identite';
			end
		elseif handi.orderby:len() > 0 then
			titre = 'ENTRIES BY '..string.upper(handi.orderby);
			titre = string.gsub(titre, 'CLUB', 'SPORTS CLUB');
		end
	end
	doc:Delete();
	orientation = orientation or 'portrait';
	report = wnd.LoadTemplateReportXML({
		xml = './edition/editionHandi.xml',
		node_name = 'edition/report',
		node_attr = 'id',
		node_value = handi.cible,
		title = titre,
		base = base,
		body = tRanking,
		margin_first_top = 100,
		margin_first_left = 100,
		margin_first_right = 100,
		margin_first_bottom = margin_first_bottom,
		margin_top = 100,
		margin_left = 100,
		margin_right = 100,
		margin_bottom = 100,
		paper_orientation = orientation,
		params = {Titre = titre, Mode = handi.mode, Language = language, OrderBy = handi.orderby, tRanked = tRanked, PageBreak =handi.page_break, Saison = handi.code_saison, CoefDiffMaxi = coef_diffmaxi, Manche  = handi.choix_manche, Inscrits = tRanking:GetNbRows(), Nations = handi.nb_nation, Date= handi.date_epreuve, Discipline = handi.code_discipline, Officiel = handi.officiel, Nb_manche = handi.nb_manche, Code_evenement = handi.code_evenement, Entite = handi.entite, cible = handi.cible}
	});
end

function GetParamsXML()
	tRanked = {};
	XML = app.GetPath().."/edition/editionHandi.xml";
	doc = xmlDocument.Create(XML);
	local racine = '';
	local nodeParams = doc:FindFirst('edition/params');
	local child = xmlNode.GetChildren(nodeParams);
	while child ~= nil do
		if child:GetName() == "diffmaxi" then
			coef_diffmaxi = tonumber(child:GetAttribute('valeur')) or 0;
		elseif string.find(child:GetName(), 'ranked') then
			local idx = tonumber(string.match(child:GetName(), '%d+')) or -1;
			tRanked[idx] = {};
			for i = 1, idx do
				tRanked[idx][i] = {};
				local pts_rank = child:GetAttribute('rank'..i);
				pts_rank = tonumber(pts_rank) or 0;
				tRanked[idx][i].Pts = pts_rank;
				-- idx = nombre de classés, i = classement
			end
		end	
		child = child:GetNext();
	end
end
