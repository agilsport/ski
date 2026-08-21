-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');

function GetMenuName()
	return "FIS : Double Tirage au sort des dossards (RIS)";
end

function GetActivite()
	return "ALP,TM";
end

function OnPrintDoubleTirage(groupe)
	if params.print_alone then
		params.tableDossards1, params.tableDossards2 = OnDecodeJsonBibo(params.code_evenement, groupe);
	else
		OnEncodeJsonBibo(params.code_evenement, groupe);
		params.tableDossards1, params.tableDossards2 = OnDecodeJsonBibo(params.code_evenement, groupe);
	end
	if params.bibo then
		return false;
	end
	if tResultat_Info_Bibo:GetNbRows() == 0 then
		if groupe == 1 then
			app.GetAuiFrame():MessageBox("Il n'y a rien à imprimer dans ce contexte",
							"Impression", 
							msgBoxStyle.OK+msgBoxStyle.ICON_WARNING
							);
			return;
		else
			return;
		end
	end
	if groupe == 1 then
		params.nb_groupe_1 = #params.tableDossards1;
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
			layers = {file = './edition/layer.xml', id = 'ffs-fis', page = '*'}, 
			paper_orientation = 'portrait',
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 1, Version = script_version, NbGroupe1 = 0, NC = 1}
		});
	elseif groupe == 2 then
		local editor = report:GetEditor();
		editor:PageBreak(); -- Saut de Page entre les 2 éditions ...

		wnd.LoadTemplateReportXML({
			xml = './process/dossard_DoubleTirage.xml',
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
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 2, Version = script_version, NbGroupe1 = params.nb_groupe_1, NC = 1}
		});
	end
end

function GetBibo()
	params.pts_7 = tResultat:GetCellDouble('Point', 6);
	params.pts_15 = tResultat:GetCellDouble('Point', 14);
	params.last_row_bibo = nil; 
	params.row_pts7 = nil;

	params.nb_bibo = 0;
	params.nb_classes = 0;
	params.nb_non_classes = 0;
	params.first_row_non_classe = nil;
	for row = 0, tResultat:GetNbRows() -1 do
		local point = tResultat:GetCellDouble('Point', row, -1);
		if point >= 0 then
			if point == params.pts_7 then
				params.row_pts7 = row;
			end
			if point <= params.pts_15 then
				params.last_row_bibo = row;
				params.nb_bibo = params.nb_bibo + 1;
			end
			params.nb_classes = params.nb_classes + 1;
		else
			if not params.first_row_non_classe then
				params.first_row_non_classe = row;
			end
			params.nb_non_classes = params.nb_non_classes + 1;
		end
	end	
end

function CheckExaequo()
	-- EC tech 1,2 = bibo, 3 = 450+, WC
	local groupe_en_cours = nil;
	params.exaequo_groupe = 101;
	local groupe_mini_exaequo = 2;
	
	for i = 0, tResultat:GetNbRows() -1 do
		tResultat:SetCell('Exaequo_groupe', i, 0);
		tResultat:SetCell('Rang_tirage', i, i+1)
		if params.pts_7 then
			groupe_mini_exaequo = 3;
			if tResultat:GetCellDouble('Point', i) <=  params.pts_7 then
				tResultat:SetCell('Groupe_tirage', i, 1);
			elseif tResultat:GetCellDouble('Point', i) <=  params.pts_15 then
				tResultat:SetCell('Groupe_tirage', i, 2);
			end
		else
			local pts =  tResultat:GetCellDouble('Point', i, 9999)
			if pts >= 0 and pts < 9999 then
				tResultat:SetCell('Groupe_tirage', i, 2);
			else
				tResultat:SetCell('Groupe_tirage', i, 3);
			end
		end
	end
	for i = 0, tResultat:GetNbRows() -1 do
		if tResultat:GetCellInt('Groupe_tirage', i) >= groupe_mini_exaequo then
			local exaequo = false;
			if i <= tResultat:GetNbRows() -1 then
				local pts_fis_next = tResultat:GetCellDouble('Point', i+1);
				if pts_fis_next == pts_fis then
					if groupe_en_cours == nil then
						params.exaequo_groupe = params.exaequo_groupe + 1;
						groupe_en_cours = params.exaequo_groupe;
					end
					tResultat:SetCell('Exaequo_groupe', i, params.exaequo_groupe);
					tResultat:SetCell('Exaequo_groupe', i+1, params.exaequo_groupe);
					-- adv.Alert(tDraw:GetCell('Identite', i)..', égalité au rang de tirage  '..tDraw:GetCellInt('Rang_tirage', i)..' et '..tDraw:GetCellInt('Rang_tirage', i+1)..', draw.exaequo_groupe = '..draw.exaequo_groupe);
				else
					groupe_en_cours = nil;
				end
			end
		end
	end
	tResultat:SetCounter('Exaequo_groupe');
	-- if draw.exaequo_groupe > 0 then
		-- for i = 0, tDraw:GetCounter('Exaequo_groupe'):GetNbRows() -1 do
			-- local id_groupe = tonumber(tDraw:GetCounter('Exaequo_groupe'):GetCell(0,i)) or 0;
			-- if id_groupe > 0 then
				-- adv.Alert(' groupe : '..id_groupe..', nombre : '..tDraw:GetCounter('Exaequo_groupe'):GetCell(1,i));
			-- end
		-- end			
	-- end
	tResultat:OrderBy('Rang_tirage');
end

function BuildTableTirageSplit(bib_first, last_row_groupe_bibo)
	params.tableDossards1 = {};
	for row = 0, last_row_groupe_bibo  do
		table.insert(params.tableDossards1, bib_first + row);
	end
	params.tableDossards1 = Shuffle(params.tableDossards1);
	tTableTirage1:RemoveAllRows();
	for row = 0, last_row_groupe_bibo do
		local new_row1 = tTableTirage1:AddRow();
		local aleatoire = randomFloat(1, 2);
		tTableTirage1:SetCell('Row', new_row1, row+1);
		tTableTirage1:SetCell('Aleatoire', new_row1, aleatoire);
	end
	tTableTirage1:OrderRandom('Aleatoire');
	for i = 0, tTableTirage1:GetNbRows() -1 do
		local ligne = tTableTirage1:GetCellInt('Row', i);
		local dossard = params.tableDossards1[ligne];
		tDrawG6:SetCell('Dossard', i, dossard);
	end
end

function randomFloat(a, b)
    return a + (b - a) * math.random()
end

function BuildTableTirage(row_first, row_last, rang_tirage, bib_first, shuffle);
	-- adv.Alert('BuildTableTirage row_first = '..tostring(row_first)..', row_last = '..tostring(row_last)..', rang_tirage = '..tostring(rang_tirage)..', bib_first = '..tostring(bib_first)..', shuffle = '..tostring(shuffle));
	tResultat_Copy = tResultat:Copy();
	ReplaceTableEnvironnement(tResultat_Copy, '_Resultat_Copy');
	shuffle = shuffle or false;
	if rang_tirage then
		bib_first = rang_tirage;
		row_first = rang_tirage -1;
	end
	
	row_first = row_first or 0;
	row_last = row_last or tResultat:GetNbRows() -1;
	if row_last < 0 then
		row_last = tResultat:GetNbRows() -1;
	end
	bib_first = bib_first or 1;
	if rang_tirage then
		for row = tResultat_Copy:GetNbRows() -1, 0, -1 do
			local rang = tResultat_Copy:GetCellInt('Rang', row);
			if rang ~= rang_tirage then
				tResultat_Copy:RemoveRowAt(row);
			end
		end
		row_last = row_first + tResultat_Copy:GetNbRows() -1;
	end
	-- row_first = 49, row_last = 78, rang_tirage = false, bib_first = 50	
	params.tableDossards1 = {};
	local bib = bib_first;
	for row = row_first, row_last do
		table.insert(params.tableDossards1, bib);
		bib = bib + 1;
	end
	if shuffle then
		params.tableDossards1 = Shuffle(params.tableDossards1);
	end
	tTableTirage1:RemoveAllRows();
	local rang_fictif = 0;
	for row = 1, #params.tableDossards1 do
		local aleatoire = randomFloat(1, 2);
		local new_row1 = tTableTirage1:AddRow();
		tTableTirage1:SetCell('Row', new_row1, row);	-- setCell du rang fictif en lien avec  params.tableDossards1
		tTableTirage1:SetCell('Aleatoire', new_row1, aleatoire);
	end
	
	tTableTirage1:OrderRandom('Aleatoire');
	for row = 0, tTableTirage1:GetNbRows() -1 do
		local row_coureur = row + row_first;
		local rang_fictif = tTableTirage1:GetCellInt('Row', row);
		local code_coureur = tResultat:GetCell('Code_coureur', row_coureur);
		local identite = tResultat:GetCell('Nom', row_coureur)..' '..tResultat:GetCell('Prenom', row_coureur);
		local dossard = params.tableDossards1[rang_fictif];
		if tResultat_Copy:GetCellInt('Dossard', row) == 0 then
			tResultat_Copy:SetCell('Dossard', row, dossard);
			tResultat:SetCell('Dossard', row_coureur, dossard);
			-- local cmd = 'Update Resultat Set Dossard = '..dossard;
			if rang_tirage then
				tResultat_Copy:SetCell('Rang', row, rang_tirage);
				tResultat:SetCell('Rang', row_coureur, rang_tirage);
				-- cmd = cmd..', Rang = '..rang_tirage;
			end
		end
	end
end

function OnTirageEgalite(groupe)
	tResultatTirageAuto = tResultat:Copy();
	local filter = "$(Exaequo_groupe):In("..groupe..")";
	tResultatTirageAuto:Filter(filter, true);
	local bib_first = tResultatTirageAuto:GetCellInt('Rang_tirage', 0);

	params.tableDossards1 = {};
	for row = 0, tResultatTirageAuto:GetNbRows() -1  do
		table.insert(params.tableDossards1, bib_first + row);
	end
	params.tableDossards1 = Shuffle(params.tableDossards1);
	tTableTirage1:RemoveAllRows();
	for row = 0, tResultatTirageAuto:GetNbRows() -1 do
		local new_row1 = tTableTirage1:AddRow();
		tTableTirage1:SetCell('Row', new_row1, row+1);
	end
	tTableTirage1:OrderBy('Row');
	tTableTirage1:OrderRandom();
	for i = 0, tTableTirage1:GetNbRows() -1 do
		local ligne = tTableTirage1:GetCellInt('Row', i);
		local dossard = params.tableDossards1[ligne];
		tResultatTirageAuto:SetCell('Dossard', i, dossard);
		local identite = tResultatTirageAuto:GetCell('Nom', i)..' '..tResultatTirageAuto:GetCell('Prenom', i);
		local code_coureur = tResultatTirageAuto:GetCell('Code_coureur', i);
		local r = tResultat:GetIndexRow('Code_coureur', code_coureur)
		if r >= 0 then
			tResultat:SetCell('Dossard', r, dossard);
		end
	end
	base:TableFlush(tResultat)
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
		code_coureur = tResultatTirageAuto:GetCell('Code_coureur', row);
		identite = tResultatTirageAuto:GetCell('Nom', row)..' '..tResultatTirageAuto:GetCell('Prenom', row);
		pts = tResultatTirageAuto:GetCellDouble('Point', row);
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

function main(params_c)
	if params_c == nil then
		return false;
	end
	local seed = os.time() + os.clock() * 1000000;
	math.randomseed(seed)	
	params = params_c;
		-- for k,v in pairs(params) do
			-- adv.Alert('Key '..k..'='..tostring(v));
			-- if type(v) == 'table' then
				-- for i,j in pairs(v) do
					-- adv.Alert('Key '..i..'='..tostring(j));
					-- adv.Alert('type de '..i..' = '..type(j));
				-- end
			-- end
			-- adv.Alert('\n');
		-- end
	
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	Interrogation();
	script_version = "4.01"; 
	-- vérification de l'existence d'une version plus récente du script.
	-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2,DoubleTirage=3.2,TirageOptions=3.3,TirageER=1.7,ListeMinisterielle=2.3,KandaHarJunior=2.0
	if app.GetVersion() >= '4.4c' then 
		indice_return = 4;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
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
	params.code_evenement = params.code_evenement or -1;
	if params.code_evenement < 0 then
		return;
	end
	params.width = display:GetSize().width / 3;
	params.height = display:GetSize().height / 3;
	params.x = (display:GetSize().width - params.width) / 2;
	params.y = 200;
	params.origine = params.origine or 'scenario';	
	base = base or sqlBase.Clone();
	tResultat = base:GetTable('Resultat');
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement..' Order By Dossard');
	tResultat:SetCounter('Sexe');
	if tResultat:GetCounterCount('Sexe') > 1 then
		msg = 'Scénario incompatible avec des courses mixtes.\n\n'..
			'Choisissez le scénario : Tirage des dossards ou des rangs de départ avec options de tirage';
		local reponse =  app.GetAuiFrame():MessageBox(msg,
						"Lancer le tirage", 
						msgBoxStyle.OK+msgBoxStyle.ICON_WARNING
						);
		return;
	end
	params.bolDossardExiste = false;
	if tResultat:GetCellInt('Dossard', 0) > 0 then
		params.bolDossardExiste = true;;
	end
	-- if not params.bolDossardExiste then
		-- local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..params.code_evenement;
		-- base:Query(cmd);
	-- end
	dlgConfig = wnd.CreateDialog({
		
		width = display:GetSize().width * 2 / 3,
		height = display:GetSize().height / 2,
		x = display:GetSize().width / 6,
		y = 100,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		label='Double tirage au sort des dossards : '..script_version , 
		icon='./res/32x32_ffs.png'
		});
	
	dlgConfig:LoadTemplateXML({ 
		xml = './process/verification_competition.xml',
		node_name = 'root/panel', 
		node_attr = 'name',
		node_value = 'config'
		});

	dlgConfig:GetWindowName('race_name'):SetValue('Compétition \n\n'..tEvenement:GetCell('Nom', 0));
	
	-- Toolbar Principale ...
	local tbconfig = dlgConfig:GetWindowName('tbconfig');
	tbconfig:AddStretchableSpace();
	local config_btnClose = tbconfig:AddTool("Continuer", "./res/32x32_save.png");
	tbconfig:AddStretchableSpace();
	local config_btnQuitter = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();

	tbconfig:Realize();
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);

	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:EndModal(idButton.OK) 
		 end,  config_btnClose);

	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:EndModal(idButton.CANCEL) 
		 end,  config_btnQuitter);
		 
	if dlgConfig:ShowModal() ~= idButton.OK then
		return;
	end

	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	params.evenementNom = tEvenement:GetCell('Nom', 0);
	tEpreuve = base:GetTable('Epreuve');
	base.TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	params.code_niveau = tEpreuve:GetCell('Code_niveau', 0);
	tResultat_Info_Bibo = base:GetTable('Resultat_Info_Bibo');
	if tResultat_Info_Bibo == nil then
		CreateTableResultat_Info_Bibo();
	end
	
	tTableTirage1 = sqlTable.Create('_TableTirage1');
	tTableTirage1:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	tTableTirage1:AddColumn({ name = 'Aleatoire', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage1, '_TableTirage1');
	
	local cmd = 'Select * From Resultat_Info_Bibo Where Code_evenement = '..params.code_evenement;
	base:TableLoad(tResultat_Info_Bibo, cmd);
	tResultat_Info_Bibo:OrderBy('Groupe, Ligne');
	params.skip_question = false;
	params.print_alone = false;
	if tEpreuve:GetCell('Code_entite', 0) == 'FIS' and tEpreuve:GetCell('Code_niveau', 0):In('EC', 'NC') and tEpreuve:GetCell('Code_discipline', 0):In('SG','DH') then
		params.print_alone = true;
		params.skip_question = true;
	end
	if tEpreuve:GetCell('Code_entite', 0) == 'FIS' and tEpreuve:GetCell('Code_niveau', 0):In('EC') then
		params.print_alone = true;
		params.skip_question = true;
	end
	if tResultat_Info_Bibo:GetNbRows() > 0 then
		if not params.skip_question then
			local msg = "Le double tirage au sort des dossards a déjà été réalisé. \n"..
						"Voulez-vous rééditer la feuille du tirage fait précédemment? \n"..
						"ATTENTION, si vous cliquez sur Non, tous les dossards seront alors effacés et remplacés par ceux du nouveau tirage.\n\n"..
						"OUI = réédition des dossards\n"..
						"Non = retirage des dossards\n";
			local reponse =  app.GetAuiFrame():MessageBox(msg,
							"Lancer le tirage", 
							msgBoxStyle.YES+msgBoxStyle.NO+msgBoxStyle.CANCEL+msgBoxStyle.CANCEL_DEFAULT+msgBoxStyle.ICON_WARNING
							);
			if reponse == msgBoxStyle.CANCEL then
				return ;
			elseif reponse == msgBoxStyle.YES then
				params.print_alone = true;
			else
				params.print_alone = false;;
			end
		end
	else
		params.print_alone = false;;
		tResultat:OrderBy('Dossard DESC');
		if tResultat:GetCell('Dossard', 0):len() > 0 then
			local msg = "ATTENTION : Les dossards ont déjà été tirés pour cette course !!!\n"..
						"Confirmez-vous le double tirage au sort des dossards?\n"..
						"Les dossards présents seront alors effacés et remplacés par ceux du nouveau tirage.";
			local reponse =  app.GetAuiFrame():MessageBox(msg,
						"Lancer le tirage", 
						msgBoxStyle.YES+msgBoxStyle.NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING
						);
			if reponse == msgBoxStyle.NO then
				return ;
			end
		end
	end

	bolSplitBibo = false;
	if tEpreuve:GetCell('Code_entite', 0) == 'FIS' then
		if tEpreuve:GetCell('Code_niveau', 0):In('EC', 'NC') then
			if tEpreuve:GetCell('Code_discipline', 0):In('SL','GS') then
				bolSplitBibo = true;
			else
				local msg = "ATTENTION, ce script n'est valable que pour les épreuves techniques.";
				app.GetAuiFrame():MessageBox(msg,
							"ATTENTION", 
						msgBoxStyle.OK+msgBoxStyle.ICON_WARNING
							);
				return ;
			end
		end
	end
	tResultat:OrderBy('Point');
	if bolSplitBibo == true then
		params.pts_7 = tResultat:GetCellDouble('Point', 6);
	end
	params.pts_15 = tResultat:GetCellDouble('Point', 14);
	if params.bibo then
		params.pts_bibo_jeunes = tResultat:GetCellDouble('Point', params.bibo -1);
	end
	params.last_row_bibo = nil; params.row_pts7 = nil;
	GetBibo();
	if params.print_alone == false then
		local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..params.code_evenement;
		base:Query(cmd);
		cmd = 'Update Resultat Set Dossard = Null, Rang = NULL, Critere = Null Where Code_evenement = '..params.code_evenement;
		base:Query(cmd);
		if params.first_row_non_classe then		-- tirage des non classés
			local cmd = 'Update Resultat Set Rang = '..(params.first_row_non_classe + 1)..' Where Code_evenement = '..params.code_evenement..' And Point Is Null';
			base:Query(cmd);
		end
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
		tResultat:AddColumn({ name = 'Rang_tirage', type = sqlType.LONG, style = sqlStyle.NULL });
		tResultat:AddColumn({ name = 'Groupe_tirage', type = sqlType.LONG, style = sqlStyle.NULL });
		tResultat:AddColumn({ name = 'Exaequo_groupe', type = sqlType.LONG, style = sqlStyle.NULL });
		
		tResultat:OrderBy('Point');

		CheckExaequo();
		-- valeurs définies apres GetBibo
		-- params.pts15 
		-- resultat.pts15 
		-- params.nb_bibo
		-- params.nb_classes
		-- params.nb_non_classes 
		-- params.first_row_non_classe;
		-- function BuildTableTirage(row_first, row_last, rang_tirage, bib_first, shuffle);
			for i = 0, tResultat:GetCounter('Exaequo_groupe'):GetNbRows() -1 do
				local id_groupe = tonumber(tResultat:GetCounter('Exaequo_groupe'):GetCell(0,i)) or 0;
				if id_groupe > 0 then	-- on fait le double tirage pour le groupe de tirage concerné
					local nombre = tonumber(tResultat:GetCounter('Exaequo_groupe'):GetCell(1,i));
					OnTirageEgalite(id_groupe);
				end
			end
		-- base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
		-- base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
		local limite = nil;
		if params.first_row_non_classe then
			limite = params.first_row_non_classe;
		else
			limite = tResultat:GetNbRows();
		end
		local depart = params.nb_bibo;
		if params.bibo then
			depart = params.bibo;
		end
		for row = depart, limite -1 do
			if tResultat:GetCellInt('Dossard', row) == 0 then
				local dossard = row + 1;
				tResultat:SetCell('Dossard', row, dossard) ;
			end
		end
		base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
		tResultat:OrderBy('Point');
		if params.first_row_non_classe then
			if params.first_row_non_classe < tResultat:GetNbRows() -1 then
		--      BuildTableTirage(row_first, row_last, rang_tirage, bib_first, shuffle);
				BuildTableTirage(params.first_row_non_classe, nil, params.first_row_non_classe + 1, params.first_row_non_classe + 1, true) -- tirage des sans points
			else
				tResultat:SetCell('Dossard', tResultat:GetNbRows()-1, tResultat:GetNbRows())
			end
			base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
		end
--      BuildTableTirage(row_first, row_last, rang_tirage, bib_first, shuffle);
		if not bolSplitBibo then
			if not params.bibo then
				BuildTableTirage(0, params.nb_bibo -1, nil, 1, true) -- tirage du bibo
			else
				BuildTableTirage(0, params.bibo -1, nil, 1, true) -- tirage du bibo
			end
		end
	end
	base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
	local cmd = 'Update Resultat Set Rang = NULL Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	local cmd = 'Update Resultat Set Groupe = NULL Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	local cmd = 'Update Resultat Set Reserve = NULL Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);

	if not bolSplitBibo then
		if not params.print_alone then
			tResultat:OrderBy('Point');
			tDrawG6 = tResultat:Copy();
			ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
			for i = tDrawG6:GetNbRows() -1, 0, -1 do
				local pts = tDrawG6:GetCellDouble('Point', i, -1);
				if pts < 0 then
					if params.bibo then
						tResultat:SetCell('Reserve', i, 3);
					end
					tDrawG6:RemoveRowAt(i);
				else
					if params.bibo then
						if pts > params.pts_bibo_jeunes then
							tResultat:SetCell('Reserve', i, 2);
							tDrawG6:RemoveRowAt(i);
						else
							tResultat:SetCell('Reserve', i, 1);
						end
					else
						if pts > params.pts_15 then
							tDrawG6:RemoveRowAt(i);
						end
					end
				end
			end
			if params.bibo then
				base:TableBulkUpdate(tResultat,'Reserve','Resultat');
			end
		end
		OnPrintDoubleTirage(1);
	else
		if not params.print_alone then
			tResultat:OrderBy('Point');
			tDrawG6 = tResultat:Copy();
			ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
			for i = tDrawG6:GetNbRows() -1, 0, -1 do
				local pts = tDrawG6:GetCellDouble('Point', i, -1);
				if pts < 0 or pts > params.pts_7 then
					tDrawG6:RemoveRowAt(i);
				end
				params.nb_groupe_1 = tDrawG6:GetNbRows();
			end
			-- BuildTableTirageSplit(bib_first, last_row_groupe_bibo)
			BuildTableTirageSplit(1, tDrawG6:GetNbRows() - 1) -- tirage du sous groupe 1
			base:TableBulkUpdate(tDrawG6, 'Dossard', 'Resultat');
			OnPrintDoubleTirage(1);
			tDrawG6 = tResultat:Copy();
			ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
			for i = tDrawG6:GetNbRows() -1, 0, -1 do
				local pts = tDrawG6:GetCellDouble('Point', i, -1);
				if pts < 0 or pts > params.pts_15 or pts <= params.pts_7 then
					tDrawG6:RemoveRowAt(i);
				end
			end
			BuildTableTirageSplit(params.nb_groupe_1 + 1, tDrawG6:GetNbRows() - 1) -- tirage du sous groupe 2
			base:TableBulkUpdate(tDrawG6, 'Dossard', 'Resultat');
			OnPrintDoubleTirage(2);
		else
			tDrawG6 = tResultat:Copy();
			ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
			for i = tDrawG6:GetNbRows() -1, 0, -1 do
				local pts = tDrawG6:GetCellDouble('Point', i, -1);
				if pts < 0 or pts > params.pts_7 then
					tDrawG6:RemoveRowAt(i);
				end
				params.nb_groupe_1 = tDrawG6:GetNbRows();
			end
			OnPrintDoubleTirage(1);
			tTableTirage1:RemoveAllRows();
			tDrawG6 = tResultat:Copy();
			ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
			for i = tDrawG6:GetNbRows() -1, 0, -1 do
				local pts = tDrawG6:GetCellDouble('Point', i, -1);
				if pts < 0 or pts > params.pts_15 or pts <= params.pts_7 then
					tDrawG6:RemoveRowAt(i);
				end
			end
			OnPrintDoubleTirage(2);
		end
	end
end




