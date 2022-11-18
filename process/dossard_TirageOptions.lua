-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function GetMenuName()
	return "Tirage des dossards ou des rangs de départ avec options de tirage";
end
function GetActivite()
	return "ALP,TM";
end

function SetupDefault(evt)
	local selection = dlgConfig:GetWindowName('option1'):GetSelection();
	local nbmanches = 2;
	if selection == 3 then
		nbmanches = 3;
	elseif selection == 4 then
		nbmanches = 4;
	end
	params.doc_config:Delete();
	xml_config = app.GetPath()..'/process/dossard_TirageOptions_config.xml'
	app.RemoveFile(xml_config);
	CreateXMLConfig();
	params.doc_config = xmlDocument.Create(xml_config);
	params.nodeSetupx4 = params.doc_config:FindFirst('root/manchesx4');
	params.nodeSetup2x2 = params.doc_config:FindFirst('root/manches2x2');
	params.nodeSetupx3 = params.doc_config:FindFirst('root/manchesx3');
	if selection == 3 then
		params.activeNode = params.nodeSetupx3;
	elseif selection == 4 then
		params.activeNode = params.nodeSetupx4;
	else
		params.activeNode = params.nodeSetup2x2;
	end
	dlgSetup:EndModal();
	OnSetup(selection, true)
end


function CreateXMLConfig()
	xml_config = "./process/dossard_TirageOptions_config_defaut.xml";
	params.doc_config = xmlDocument.Create(xml_config);
      params.doc_config:SaveFile(app.GetPath()..'/process/dossard_TirageOptions_config.xml');
	params.doc_config:Delete()
	xml_config = "./process/dossard_TirageOptions_config.xml";
	params.doc_config = xmlDocument.Create(xml_config);
end

function DecodeActiveNode()
	local nbmanches = tonumber(params.activeNode:GetAttribute('nb_manches')) or 0;
	params.tirageCourse = {};
	local node = params.activeNode:GetChildren();
	while node ~= nil do
		local nodeCourse = {};
		nodeCourse.Name = node:GetName();
		local course = node:GetName();
		local idxcourse = tonumber(nodeCourse.Name:sub(-1));
		nodeCourse.idxCourse = idxcourse;
		local paramsmanches = {};
		for i = 1, nbmanches do
			local groupes = node:GetAttribute('m'..i);
			local idx = tonumber(node:GetAttribute('m'..i..'_sens')) or 0;
			table.insert(paramsmanches, {Groupes = groupes, Sens = idx});
		end
		table.insert(params.tirageCourse, {Data = paramsmanches});	
		node = node:GetNext();
	end
	
	return params.tirageCourse;
end

function OnSetup(selection, quit)
	local nbmanches = 2;
	if selection == 3 then
		nbmanches = 3;
	elseif selection == 4 then
		nbmanches = 4;
	end
	function SaveSetup()
		params.activeNode:ChangeAttribute('bib_skip', dlgSetup:GetWindowName('bib_skip'):GetSelection());
		local node = params.activeNode:GetChildren();
		while node ~= nil do
			local course = node:GetName();
			local idxcourse = tonumber(course:sub(-1));
			for run = 1, nbmanches do
				local m = dlgSetup:GetWindowName('course'..idxcourse..'_manche'..run):GetValue();
				local sens = dlgSetup:GetWindowName('course'..idxcourse..'_sens'..run):GetSelection();
				node:ChangeAttribute('m'..run, m);
				node:ChangeAttribute('m'..run..'_sens', sens);
			end
			node = node:GetNext();
		end
		params.doc_config:SaveFile();
		dlgSetup:EndModal(idButton.OK);
	end
	dlgSetup = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Back Office', 
		icon='./res/32x32_param.png'
		});
	
	dlgSetup:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		node_value = 'setup',
		nbmanches = nbmanches
	});

	-- Toolbar Principale ...
	local tbsetup = dlgSetup:GetWindowName('tbsetup');
	tbsetup:AddStretchableSpace();
	local btnSave = tbsetup:AddTool("Valider", "./res/vpe32x32_save.png");
	tbsetup:AddSeparator();
	local btnDefault = tbsetup:AddTool("Valeurs par défaut", "./res/32x32_param.png");
	tbsetup:AddSeparator();
	local btnClose = tbsetup:AddTool("Quitter", "./res/32x32_end.png");
	tbsetup:AddStretchableSpace();
	tbsetup:Realize();
	dlgSetup:GetWindowName('bib_skip'):Clear();
	dlgSetup:GetWindowName('bib_skip'):Append('Non');
	dlgSetup:GetWindowName('bib_skip'):Append('Oui');
	for i = 1, nbmanches do
		dlgSetup:GetWindowName('course1_sens'..i):Clear();
		dlgSetup:GetWindowName('course1_sens'..i):Append('à la mêlée');
		dlgSetup:GetWindowName('course1_sens'..i):Append('par ordre croissant');
		dlgSetup:GetWindowName('course1_sens'..i):Append('par ordre décroissant');
		dlgSetup:GetWindowName('course2_sens'..i):Clear();
		dlgSetup:GetWindowName('course2_sens'..i):Append('à la mêlée');
		dlgSetup:GetWindowName('course2_sens'..i):Append('par ordre croissant');
		dlgSetup:GetWindowName('course2_sens'..i):Append('par ordre décroissant');
	end
	
	dlgSetup:GetWindowName('bib_skip'):SetSelection(tonumber(params.activeNode:GetAttribute('bib_skip')));
	params.tirageCourse = DecodeActiveNode();
	for idxcourse = 1, #params.tirageCourse do
		local paramsManche = params.tirageCourse[idxcourse].Data;
		for run = 1, #paramsManche do
			local name = 'course'..idxcourse..'_manche'..run;
			local name_sens = 'course'..idxcourse..'_sens'..run;
			dlgSetup:GetWindowName(name):SetValue(paramsManche[run].Groupes);
			dlgSetup:GetWindowName(name_sens):SetSelection(paramsManche[run].Sens);
		end
	end
	if quit == true then
		SaveSetup();
	end
	dlgSetup:Bind(eventType.MENU, 
		function(evt) 
			SaveSetup();
		end, btnSave); 
	dlgSetup:Bind(eventType.MENU, SetupDefault, btnDefault); 
	dlgSetup:Bind(eventType.MENU, 
		function(evt) 
			dlgSetup:EndModal(idButton.KO);
		end, btnClose); 
	dlgSetup:Fit();
	dlgSetup:ShowModal();
end

function CheckExaequoReserve2(bib_first);
	params.row_exaequo =  {};
	params.tExaequo =  {};
	local rang_tirage = bib_first - 1;
	local nb_exeaquo = 0;
	local point_encours = -1;
	for i = 0, params.tDraw_Copy:GetNbRows() -1 do
		local code_coureur = params.tDraw_Copy:GetCell('Code_coureur', i);
		local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
		local point = params.tDraw_Copy:GetCellDouble('Point', i);
		if point == point_encours then
			table.insert(params.row_exaequo, rang_tirage)
			nb_exeaquo = nb_exeaquo + 1;
		else
			rang_tirage = rang_tirage + nb_exeaquo + 1;
			nb_exeaquo = 0;
			point_encours = point;
		end
		params.tDraw_Copy:SetCell('Rang', i, rang_tirage);
		tResultat:SetCell('Rang', r, rang_tirage);
	end
end

function CheckExaequo(tablex, idx);
	params.row_exaequo =  {};
	params.tExaequo =  {};
	local rang_tirage = 0;
	if idx > 1 then
		rang_tirage = tBibo[idx-1].NbRows;
	end
	local nb_points = rang_tirage;
	local exaequo_ajoute = 0;
	local nb_exeaquo = 0;
	local point_encours = -1;
--	table.insert(tBibo, {Sexe = 'M', NbRows = tResultat:GetCounterValue('Sexe', 'M'), RowFirst = row_first, RowEnd = row_end, PtsBibo = 0, LastRowBibo = -1,  LastRowPts = -1, FirstRowPtsNull = -1, Reserves = {}});
	for i = 0, tablex:GetNbRows() -1 do
		local code_coureur = tablex:GetCell('Code_coureur', i);
		local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
		local point = tablex:GetCellDouble('Point', i, 10000);
		local reserve = tablex:GetCellInt('Reserve', i);
		if reserve == 1 then
			tablex:SetCell('Rang', i, 1);
		elseif reserve == 2 then
			point_encours = point;
		else
			tablex:SetCell('Rang', i, tBibo[idx].FirstRowPtsNull);
		end
		if point == 10000 and not tBibo[idx].FirstRowPtsNull then
			tBibo[idx].FirstRowPtsNull = i;
			if idx > 1 then
				tBibo[idx].FirstRowPtsNull = tBibo[idx].FirstRowPtsNull + tBibo[idx-1].NbRows;
			end
			tablex:SetCell('Rang', i, tBibo[idx].FirstRowPtsNull + 1);
			tResultat:SetCell('Rang', r, tBibo[idx].FirstRowPtsNull + 1);
			if not params.row_exaequo[nb_points +1] then
				params.row_exaequo[nb_points +1] = {};
				table.insert(params.tExaequo, nb_points +1);
			end
		else
			nb_points = nb_points + 1
			if point <= tBibo[idx].PtsBibo then
				rang_tirage = i + 1;
				if idx > 1 then
					rang_tirage = rang_tirage + tBibo[idx-1].NbRows;
				end
				tablex:SetCell('Rang', i, rang_tirage);
				tResultat:SetCell('Rang', r, rang_tirage);
			else
				if point == point_encours then
					if not params.row_exaequo[nb_points +1] then
						rang_tirage = i + 1;
						params.row_exaequo[nb_points +1] = {};
						table.insert(params.tExaequo, nb_points +1);
					end
					tablex:SetCell('Rang', i, rang_tirage);
					tResultat:SetCell('Rang', r, rang_tirage);
				else
					rang_tirage = i + 1;
					if idx > 1 then
						rang_tirage = rang_tirage + tBibo[idx-1].NbRows;
					end
					tablex:SetCell('Rang', i, rang_tirage);
					tResultat:SetCell('Rang', r, rang_tirage);
				end
			end
		end
		-- adv.Alert('tBibo['..idx..'].PtsBibo = '..tBibo[idx].PtsBibo..', point = '..point..', rang_tirage = '..rang_tirage);
	end
	-- adv.Alert('sortie de CheckExaequo, taille de params.tExaequo = '..#params.tExaequo)
	adv.Alert('Sexe en cours : '..tBibo[idx].Sexe)
	for j = 1, #params.tExaequo do
		adv.Alert('exeaquo sur : '..params.tExaequo[j]);
	end
end

function GetBibo(bibo, bib_first, sexe)
	local sexe = sexe or 'F';
	params.enable_bib_first = params.enable_bib_first or 1;
	dlgBibo = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Configuration du tirage', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgBibo:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		discipline = params.discipline,
		node_value = 'bibo',
		Niveau = params.code_niveau,
		Sexe = sexe
		});

	-- Toolbar Principale ...
	local tbbibo = dlgBibo:GetWindowName('tbbibo');
	tbbibo:AddStretchableSpace();
	local btnSave = tbbibo:AddTool("Valider", "./res/vpe32x32_save.png");
	tbbibo:AddStretchableSpace();
	tbbibo:Realize();
	
	dlgBibo:GetWindowName('bibo'):SetValue(bibo);
	if bib_first then
		dlgBibo:GetWindowName('dossard'):SetValue(bib_first);
	else
		dlgBibo:GetWindowName('dossard'):SetValue(1);
	end
	if params.enable_bib_first == 0 then
		dlgBibo:GetWindowName('dossard'):Enable(false);
	end
	dlgBibo:Bind(eventType.MENU, 
		function(evt) 
			bibo = tonumber(dlgBibo:GetWindowName('bibo'):GetValue()) or bibo;
			dossard = tonumber(dlgBibo:GetWindowName('dossard'):GetValue()) or 1;
			dlgBibo:EndModal(idButton.OK);
		end, btnSave); 
	dlgBibo:Fit();
	dlgBibo:ShowModal();
	return bibo, dossard;
end

	-- dlgConfig:GetWindowName('option1'):Append('1. Tirage pour la manche 1 seulement');
	-- dlgConfig:GetWindowName('option1'):Append('2. Tirage pour les manches 1 et 2');
	-- dlgConfig:GetWindowName('option1'):Append('3. Tirage pour la manche 2 (ABD DSQ ordre inverse)');
	-- dlgConfig:GetWindowName('option1'):Append('4. Tirage des 3 manches par tiers tournants');
	-- dlgConfig:GetWindowName('option1'):Append("5. Coupes d'Argent et Nationales jeunes : Tirage pour des courses de 4 manches");
	-- dlgConfig:GetWindowName('option1'):Append("6. Coupes d'Argent et Nationales jeunes : Tirage pour des courses de 2 manches");
	-- dlgConfig:GetWindowName('option1'):Append("7. BIBO en manche 3 / resultat des 2 premières");

	-- dlgConfig:GetWindowName('option2'):Append("1. Pas d'inversion des dossards dans les groupes de tirage");
	-- dlgConfig:GetWindowName('option2'):Append('2. Inversion des dossards dans les groupes de tirage');
	-- dlgConfig:GetWindowName('option2'):Append('3. Gestion du BIBO');
	-- dlgConfig:GetWindowName('option2'):Append('4. Selon le paramétrage du Back Office');
	-- dlgConfig:GetWindowName('option2'):Append('5. Sans objet');
	
	-- dlgConfig:GetWindowName('clef1'):Append('1. Par Sexe');
	-- dlgConfig:GetWindowName('clef1'):Append('2. Par Sexe et par Catégorie');
	-- dlgConfig:GetWindowName('clef1'):Append('3. Par Sexe et par Année');
	-- dlgConfig:GetWindowName('clef1'):Append('4. Sans objet');
		
function ValideClef1(clef1, option1, option2)
	local nbsexe = tResultat:GetCounter('Sexe'):GetNbRows();
	local nbcateg = tResultat:GetCounter('Categ'):GetNbRows();
	local nban = tResultat:GetCounter('An'):GetNbRows();

	if string.find(clef1, '1%.') then
		if nbsexe == 1 then 
			local msg = "Vérifiez les options choisies.";
			app.GetAuiFrame():MessageBox(msg, "Attention !!!"
				, msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
			dlgConfig:GetWindowName('clef1'):SetSelection(3);
			return;
		end
	end
	if string.find(clef1, '2%.') and nbcateg == 1 then 
		dlgConfig:GetWindowName('clef1'):SetSelection(3);
		return;
	end
	if string.find(clef1, '3%.') and nban == 1 then 
		dlgConfig:GetWindowName('clef1'):SetSelection(3);
		return;
	end
			
	if string.find(clef1, '2%.') or string.find(clef1, '3%.') then
		if dlgConfig:GetWindowName('option2'):GetSelection() > 2 then
			dlgConfig:GetWindowName('option2'):SetSelection(4);
		end
	end
	if string.find(option2, '3%.') then
		if string.find(clef1, '2%.') or string.find(clef1, '3%.') then
			dlgConfig:GetWindowName('option2'):SetSelection(4);
		end
		if #tBibo > 1 then
			dlgConfig:GetWindowName('clef1'):SetSelection(0);
		end
	end
end


function ValideOption1(clef1, option1, option2)
	dlgConfig:GetWindowName('course2'):Enable(true);
	dlgConfig:GetWindowName('course2_nom'):Enable(true);
	if string.find(option1, '1%.') or string.find(option1, '2%.') or string.find(option1, '3%.') then
		dlgConfig:GetWindowName('course1'):SetValue(params.code_evenement);
		dlgConfig:GetWindowName('course1_nom'):SetValue(tEvenement:GetCell('Nom',0));
		dlgConfig:GetWindowName('course1'):Enable(false);
		dlgConfig:GetWindowName('course1_nom'):Enable(false);
		dlgConfig:GetWindowName('course2'):SetValue('');
		dlgConfig:GetWindowName('course2_nom'):SetValue('');
		dlgConfig:GetWindowName('course2'):Enable(false);
		dlgConfig:GetWindowName('course2_nom'):Enable(false);
		if string.find(option1, '1%.') or string.find(option1, '3%.') then
			if not string.find(option2, '3%.') then
				dlgConfig:GetWindowName('option2'):SetSelection(4);
			end
		end
	end
	if string.find(option1, '7%.') then
		dlgConfig:GetWindowName('course1'):Enable(false);
		dlgConfig:GetWindowName('option2'):SetSelection(2);
		dlgConfig:GetWindowName('course2'):Enable(false);
		dlgConfig:GetWindowName('course2_nom'):Enable(false);
	end
end
	-- dlgConfig:GetWindowName('clef1'):Append('1. Par Sexe');
	-- dlgConfig:GetWindowName('clef1'):Append('2. Par Sexe et par Catégorie');
	-- dlgConfig:GetWindowName('clef1'):Append('3. Par Sexe et par Année');
	-- dlgConfig:GetWindowName('clef1'):Append('4. Sans objet');
		
	-- dlgConfig:GetWindowName('option1'):Append('1. Tirage pour la manche 1 seulement');
	-- dlgConfig:GetWindowName('option1'):Append('2. Tirage pour les manches 1 et 2');
	-- dlgConfig:GetWindowName('option1'):Append('3. Tirage pour la manche 2 (ABD DSQ ordre inverse)');
	-- dlgConfig:GetWindowName('option1'):Append('4. Tirage des 3 manches par tiers tournants');
	-- dlgConfig:GetWindowName('option1'):Append("5. Coupes d'Argent et Nationales jeunes : Tirage pour des courses de 4 manches");
	-- dlgConfig:GetWindowName('option1'):Append("6. Coupes d'Argent et Nationales jeunes : Tirage pour des courses de 2 manches");
	-- dlgConfig:GetWindowName('option1'):Append("7. Tirage de la manche 3 BIBO résultats M1/M2;

	-- dlgConfig:GetWindowName('option2'):Append("1. Pas d'inversion des dossards dans les groupes de tirage");
	-- dlgConfig:GetWindowName('option2'):Append('2. Inversion des dossards dans les groupes de tirage');
	-- dlgConfig:GetWindowName('option2'):Append('3. Gestion du BIBO');
	-- dlgConfig:GetWindowName('option2'):Append('4. Selon le paramétrage du Back Office');
	-- dlgConfig:GetWindowName('option2'):Append('5. Sans objet');
	
function OnTirageM3Seule(clef1, option1, option2)
	-- table.insert(tBibo, {Sexe = 'M', NbRows = tResultat:GetCounterValue('Sexe', 'M'), RowFirst = 0, RowEnd = tResultat:GetCounterValue('Sexe', 'M') -1, PtsBibo = 0, LastRowBibo = -1,  LastRowPts = -1, FirstRowPtsNull = -1, Reserves = {}});
	local reponse = msgBoxStyle.NO;
	if params.code_entite == 'FFS' then
		local msg = "Est-ce que les ABD et DSQ repartent en manche 3 ?";
		reponse = app.GetAuiFrame():MessageBox(msg, "Attention !!!"
			, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING);
	end
	params.enable_bib_first = 0;
	local bibo, _ = GetBibo(30, -1, '*');
	tRanking = base.CreateTableRanking({ code_evenement = params.code_evenement});
	tRanking:AddColumn({ name = 'Tps_M1M2', type = sqlType.LONG, style = sqlStyle.NULL });
	tRanking:ChangeColumn('Tps_M1M2', 'chrono');
	for i = 0, tRanking:GetNbRows() -1 do
		local tps1 = tRanking:GetCellInt('Tps1', i);
		local tps2 = tRanking:GetCellInt('Tps2', i);
		local tps_min = math.min(tps1, tps2);
		if tps_min < 0 then
			tRanking:SetCell('Tps_M1M2', i, tps_min);
		else
			tRanking:SetCell('Tps_M1M2', i, tps1 + tps2);
		end
	end
	if reponse == msgBoxStyle.YES then
		tRanking:Filter("$(Tps_M1M2) ~= 'Abs'", true);
	else
		tRanking:Filter("$(Tps_M1M2) ~= 'Abs' and $(Tps_M1M2) ~= 'Abd' and $(Tps_M1M2) ~= 'Dsq'", true);
		local cmd = 'Delete From Resultat_Manche Where Code_evenement = '..params.code_evenement.." And Code_manche = 3 And Medaille = '0'";
		base:Query(cmd);
	end
	tRanking:SetRanking('Cltc', 'Tps_M1M2', 'Sexe');
	tRanking:OrderBy('Sexe, Cltc, Dossard DESC');
	local tps_first = 0;
	local tRows = {};
	tRows['M'] = {}
	tRows['M'].FirstRow = nil;
	tRows['F'] = {}
	tRows['F'].FirstRow = nil;
	for i = 0, tRanking:GetNbRows() -1 do
		local code_coureur = tRanking:GetCell('Code_coureur', i);
		local sexe = tRanking:GetCell('Sexe', i);
		local cltc = tRanking:GetCellInt('Cltc', i);
		local diff = 0;
		if not tRows[sexe].FirstRow then
			tRows[sexe].FirstRow  = i;
			tRows[sexe].NbRows = 1;
		else
			tRows[sexe].LastRow  = i;
			tRows[sexe].NbRows = tRows[sexe].NbRows + 1;
		end
			
		if cltc > 0 then
			if cltc <= bibo then
				tRows[sexe].LastRowBibo = i;
				if cltc == 1 then
					tps_first = tRanking:GetCellInt('Tps_M1M2', i);
				end
			end
			tRows[sexe].LastRowClt = i;
		end
		if tRanking:GetCellInt('Tps_M1M2', i) > 0 then
			diff = tRanking:GetCellInt('Tps_M1M2', i) - tps_first;
		else
			diff = tRanking:GetCellInt('Tps_M1M2', i);
		end
		tRanking:SetCell('Diff', i, diff);
	end
	local rang = 0;
	if tRows['F'].FirstRow then
		for row = tRows['F'].LastRowBibo, tRows['F'].FirstRow, -1 do
			rang = rang + 1;
			tRanking:SetCell('Rang3', row, rang);
		end
		for row = tRows['F'].LastRowBibo + 1, tRows['F'].LastRowClt do
			rang = rang + 1;
			tRanking:SetCell('Rang3', row, rang);
		end
	end
	
	if tRows['M'].FirstRow then
		for row = tRows['M'].LastRowBibo, tRows['M'].FirstRow, -1 do
			rang = rang + 1;
			tRanking:SetCell('Rang3', row, rang);
		end
		for row = tRows['M'].LastRowBibo + 1, tRows['M'].LastRowClt do
			rang = rang + 1;
			tRanking:SetCell('Rang3', row, rang);
		end
	end
	-- les Abd Dsq
	for i = 0, tRanking:GetNbRows() -1 do
		if tRanking:GetCellInt('Cltc', i) == 0 then
			rang = rang + 1;
			tRanking:SetCell('Rang3', i, rang);
		end
	end
	tRanking:OrderBy('Rang3');
	for i = 0, tRanking:GetNbRows() -1 do
		local code_coureur = tRanking:GetCell('Code_coureur', i);
		local rang = tRanking:GetCellInt('Rang3', i);
		local cltc = tRanking:GetCellInt('Cltc', i);
		cltc = tostring(math.floor(cltc));
		local diff = tRanking:GetCellInt('Diff', i);
		local tpsm1m2 = tRanking:GetCellInt('Tps_M1M2', i);
		local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement.." And Code_manche = 3 And Code_coureur = '"..code_coureur.."'";
		base:TableLoad(tResultat_Manche, cmd);
		local rowx = 0;
		local ajouter = false;
		if tResultat_Manche:GetNbRows() == 0 then
			ajouter = true;
			rowx = tResultat_Manche:AddRow();
		end
		tResultat_Manche:SetCell('Code_evenement', rowx, params.code_evenement);
		tResultat_Manche:SetCell('Code_manche', rowx, 3);
		tResultat_Manche:SetCell('Code_coureur', rowx, code_coureur);
		tResultat_Manche:SetCell('Info', rowx, 'M1_M2');
		tResultat_Manche:SetCell('Tps_bonus', rowx, tpsm1m2);
		tResultat_Manche:SetCell('Tps_penalite', rowx, diff);
		tResultat_Manche:SetCell('Medaille', rowx, cltc);
		tResultat_Manche:SetCell('Rang', rowx, rang);
		if ajouter == true then
			base:TableInsert(tResultat_Manche, rowx);
		else
			base:TableUpdate(tResultat_Manche, rowx);
		end
	end
	local msg = "La liste de départ en manche 3 est prête pour l'édition.";
	app.GetAuiFrame():MessageBox(msg, "Création de la liste de départ en manche 3"
		, msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION);
end

function ValideOption2(clef1, option1, option2)
	local seloption1 = dlgConfig:GetWindowName('option1'):GetSelection();
	local seloption2 = dlgConfig:GetWindowName('option2'):GetSelection();
	if string.find(option1, '1%.') or string.find(option1, '3%.') then
		if seloption2 > 2 then 
			dlgConfig:GetWindowName('option2'):SetSelection(4);
			return;
		end
	end
	if seloption1 > 2 and seloption1 < 6 then
		dlgConfig:GetWindowName('option2'):SetSelection(3);
		return;
	end
	if dlgConfig:GetWindowName('option2'):GetSelection() > 1 and dlgConfig:GetWindowName('option1'):GetSelection() < 6 then
		if string.find(clef1, '2%.') or string.find(clef1, '3%.') then
			dlgConfig:GetWindowName('option2'):SetSelection(4);
		end
	end
	if string.find(option2, '3%.') and #tBibo > 1 then
		dlgConfig:GetWindowName('clef1'):SetSelection(0);
	end
end

function OnTirageManche1()
	if params.dossard1 > 0 then
		local msg = "Les dossards ont déjà été tirés.\nVoulez-vous les remplacer ?\nTous les rangs de tirage antérieurs seront supprimés \nainsi que tous les temps des manches éventuels.";
		if app.GetAuiFrame():MessageBox(msg, "Attention !!!"
			, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
			return;
		end
	end
	local cmd = 'Update Resultat Set Dossard = Null, Rang = Null, Reserve = Null Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	cmd = 'Delete From Resultat_Manche Where Code_evenement = '..params.code_evenement..' And Code_manche = 2';
	base:Query(cmd);
	local intercaler = 0;

	if dlgConfig:GetWindowName('clef1'):GetSelection() > 0 and dlgConfig:GetWindowName('clef1'):GetSelection() < 3 then
		local msg = "Voulez-vous tirer les dames avant les hommes ?\nEn répondant non, le tirage sera fait en intercalant\nles dames et les hommes selon le tri choisi.";
		if app.GetAuiFrame():MessageBox(msg, "Attention !!!"
			, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
			intercaler = 1;
		end
	end
	local groupe_en_cours = 'Je suis le groupe en cours';
	local groupe_lu = '';
	local row_start = 0;
	local row_end = 0;
	local tReserve = {};
	local reserve = 0;
	params.bibo = 15;
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement..' Order By Rang, Dossard');
	for i = 1, #tBibo do
		tResultat:OrderRandom();		-- ordre par défaut à la mêlée
		params.bib_first = 1;
		-- table.insert(tBibo, {Sexe = 'M', NbRows = tResultat:GetCounterValue('Sexe', 'M'), RowFirst = row_first, RowEnd = row_end, PtsBibo = 0, LastRowBibo = -1, LastRowPts = -1, Reserves = {}});
		local tReserves = {};
		if dlgConfig:GetWindowName('option2'):GetSelection() == 2 then	-- gestion du bibo -> les dames avant les hommes
			tResultat:OrderBy('Point');
			tDraw = tResultat:Copy();
			local filter = "$(Sexe):In('"..tBibo[i].Sexe.."')";
			tDraw:Filter(filter, true);
			if i == 2 then
				params.dossard = tBibo[1].NbRows + 1;
			end
			params.bibo, params.dossard = GetBibo(params.bibo, params.dossard, tBibo[i].Sexe); 
			tBibo[i].PtsBibo = tDraw:GetCellDouble('Point', params.bibo - 1);
			tBibo[i].BibFirst = params.dossard ;
			tBibo[i].NbReserve1 = 0;
			tBibo[i].NbReserve2 = 0;
			tBibo[i].NbReserve3 = 0;
			for row = 0, tDraw:GetNbRows() -1 do
				local code_coureur = tDraw:GetCell('Code_coureur', row);
				local point = tDraw:GetCellDouble('Point', row, 10000);
				local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
				if point <= tBibo[i].PtsBibo then
					reserve = 1;
					table.insert(tReserves, 1);
					tBibo[i].LastRowBibo = row;
					tBibo[i].NbReserve1 = tBibo[i].NbReserve1 + 1;
				elseif point < 10000 then
					reserve = 2;
					table.insert(tReserves, 2);
					tBibo[i].LastRowPts = row;
					tBibo[i].NbReserve2 = tBibo[i].NbReserve2 + 1;
				else
					if not tBibo[i].FirstRowPtsNull then
						tBibo[i].FirstRowPtsNull = i;
					end
					reserve = 3;
					tBibo[i].NbReserve3 = tBibo[i].NbReserve3 + 1;
					table.insert(tReserves, 3);
				end
				tDraw:SetCell('Reserve', row, reserve);
				tResultat:SetCell('Reserve', r, reserve);
			end
			for index = 1, 3 do
				params.tDraw_Copy = tDraw:Copy();
				local filter = "$(Reserve):In("..index..")";
				params.tDraw_Copy:Filter(filter, true);
				params.tDraw_Copy:OrderBy('Point')
				if index == 1 then
					if params.tDraw_Copy:GetNbRows() > 0 then
						BuildTableTirage2(params.tDraw_Copy, tBibo[i].BibFirst);
					end
				elseif index == 2 then
					if params.tDraw_Copy:GetNbRows() > 0 then
						local bib_first = tBibo[i].BibFirst + tBibo[i].NbReserve1;
						CheckExaequoReserve2(bib_first);
						for j =1, #params.row_exaequo do
							local rang_tirage = params.row_exaequo[j];
							local tablex = params.tDraw_Copy:Copy();
							local filter = "$(Rang):In("..rang_tirage..")";
							tablex:Filter(filter, true);
							BuildTableTirage2(tablex, rang_tirage);
						end
					end
				elseif index == 3 then
					if params.tDraw_Copy:GetNbRows() > 0 then
						local bib_first = tBibo[i].BibFirst + tBibo[i].NbReserve1 + tBibo[i].NbReserve2;
						BuildTableTirage2(params.tDraw_Copy, bib_first);
					end
				end
			end
		else	-- pas de gestion du bibo
			local reserve = 0;
			tReserve = {};
			local sexe_encours = tBibo[i].Sexe;
			if string.find(clef1, '1%.') then		-- par sexe
				tResultat_Copy:OrderBy('Sexe');
			elseif string.find(clef1, '2%.') then	-- par sexe et categ
				tResultat_Copy:AddColumn({ name = 'Categ_ordre', type = sqlType.LONG, style = sqlStyle.NULL });
				for row = 0, tResultat_Copy:GetNbRows() -1 do
					for icateg = 0, tCategorie:GetNbRows() -1 do
						local ordre = tCategorie:GetCellInt('Ordre', icateg) 
						if categ ==  tCategorie:GetCell('Code', icateg) then
							tResultat_Copy:SetCell('Categ_ordre', row, ordre);
							break;
						end
					end
					local categ = tResultat_Copy:GetCell('Categ', row);
					local r = tCategorie:GetIndexRow('Code', categ);
					if r and r >= 0 then
						tResultat_Copy:SetCell('Categ_ordre', row, tCategorie:GetCellInt('Ordre', r));
					end
				end
				
				if intercaler == 0 then			-- les dames avant les hommes
					tResultat_Copy:OrderBy('Sexe, Categ_ordre');
				else
					tResultat_Copy:OrderBy('Categ_ordre, Sexe');
				end
			elseif string.find(clef1, '3%.') then	-- par sexe et an
				if intercaler == 0 then			-- les dames avant les hommes
					tResultat_Copy:OrderBy('Sexe, An DESC');
				else
					tResultat_Copy:OrderBy('An DESC, Sexe');
				end
			end
			for row = 0, tResultat_Copy:GetNbRows() -1 do
				if string.find(clef1, '1%.') then		-- par sexe
					groupe_lu = tResultat_Copy:GetCell('Sexe', row);
				elseif string.find(clef1, '2%.') then	-- par sexe et catzg
					if intercaler == 0 then			-- les dames avant les hommes
						groupe_lu = tResultat_Copy:GetCell('Sexe', row)..'-'..tResultat_Copy:GetCell('Categ', row);
					else
						groupe_lu = tResultat_Copy:GetCell('Categ', row)..'-'..tResultat_Copy:GetCell('Sexe', row);
					end
				elseif string.find(clef1, '3%.') then	-- par sexe et an
					if intercaler == 0 then			-- les dames avant les hommes
						groupe_lu = tResultat_Copy:GetCell('Sexe', row)..'-'..tResultat_Copy:GetCell('An', row);
					else
						groupe_lu = tResultat_Copy:GetCell('An', row)..'-'..tResultat_Copy:GetCell('Sexe', row);
					end
				end
				if groupe_lu ~= groupe_en_cours then
					groupe_en_cours = groupe_lu;
					reserve = reserve + 1;
					table.insert(tReserve, reserve);
				end
				tResultat_Copy:SetCell('Reserve', row, reserve);
				tResultat_Copy:SetCell('Rang', row, reserve);
			end
			base:TableBulkUpdate(tResultat_Copy,'Rang, Reserve', 'Resultat');
			base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement..' Order By Rang');
			params.bib_first = 1;
			for reserve = 1, #tReserve do
				local tablex = tResultat:Copy();
				BuildTableTirage(tablex, reserve, params.bib_first, false);
			end
		end
	end
	-- base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement..' Order By Rang, Dossard');
	tResultat:OrderBy('Rang, Dossard');
	for i = 0, tResultat:GetNbRows() -1 do
		if tResultat:GetCell('Dossard', i):len() == 0 then
			tResultat:SetCell('Dossard', i, tResultat:GetCell('Rang', i));
		end
	end
	base:TableBulkUpdate(tResultat);
	
end

function OnTirageManche2Special()
	base:TableLoad(tResultat_Manche, 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement..' And Code_manche = 2');
	tResultat_Manche:OrderBy('Rang DESC');
	local rangx = tResultat_Manche:GetCellInt('Rang', 0);
	if rangx > 0 then
		local msg = "Les rangs de départ de la manche 2 ont déjà été tirés.\nVoulez-vous les remplacer ?";
		if app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!"
			, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
			return;
		end
	end
	cmd = 'Delete From Resultat_Manche Where Code_evenement = '..params.code_evenement..' And Code_manche = 2';
	base:Query(cmd);
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	for i = 0, tResultat:GetNbRows() -1 do
		local code_coureur = tResultat:GetCell('Code_coureur', i);
		tCoureur[code_coureur].Dossard = tResultat:GetCellInt('Dossard', i);
	end
	-- faire les groupes pour la manche 1
	if string.find(option2, '3%.') then
		params.enable_bib_first = 0;
		params.bibo, _ = GetBibo(30);
	end
	params.bibo = params.bibo or 30;
	base:TableLoad(tResultat_Manche, 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement..' And Code_manche = 1');
	tResultat_Manche:SetRanking('Clt_chrono', 'Tps_chrono', '');
	tResultat_Manche:OrderBy('Clt_chrono');
	for i = 0, tResultat_Manche:GetNbRows() -1 do
		local clt = tResultat_Manche:GetCellInt('Clt_chrono', i);
		local tps = tResultat_Manche:GetCellInt('Tps_chrono', i);
		local reserve = nil;
		if clt > 0 then
			if clt <= params.bibo then
				reserve = 1;
			else
				reserve = 2;
			end
		else
			if tps == -500 or tps == -800 then
				reserve = 3;
			else
				reserve = 4;
			end
		end
		tResultat_Manche:SetCell('Reserve', i, reserve);
	end
	base:TableBulkUpdate(tResultat_Manche);
	tResultat_Manche1 = tResultat_Manche:Copy();
	tResultat_Manche1:AddColumn({ name = 'Dossard', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tResultat_Manche1, '_Resultat_Manche1')
	for i = 0, tResultat_Manche1:GetNbRows() -1 do
		local code_coureur = tResultat_Manche1:GetCell('Code_coureur', i);
		local dossard = tCoureur[code_coureur].Dossard;
		tResultat_Manche1:SetCell('Dossard', i, dossard);
	end
	-- la colonne Reserve de la manche 1 est fixée
	cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement..' And Code_manche = 2';
	base:TableLoad(tResultat_Manche, cmd);
	local rang = 0;
	for reserve = 1, 3 do
		tTable_Boucle = tResultat_Manche1:Copy();
		local filtre = '$(Reserve):In('..reserve..')';
		tTable_Boucle:Filter(filtre, true);
		if reserve == 1 then
			tTable_Boucle:OrderBy('Tps_chrono DESC, Dossard');
		elseif reserve == 2 then
			tTable_Boucle:OrderBy('Tps_chrono');
		else
			tTable_Boucle:OrderBy('Dossard DESC');
		end
		for i = 0, tTable_Boucle:GetNbRows() -1 do
			local code_coureur = tTable_Boucle:GetCell('Code_coureur', i);
			rang = rang + 1;
			local row = tResultat_Manche:AddRow();
			tResultat_Manche:SetCell('Code_evenement', row, params.code_evenement);
			tResultat_Manche:SetCell('Code_manche', row, 2);
			tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
			tResultat_Manche:SetCell('Reserve', row, reserve);
			tResultat_Manche:SetCell('Rang', row, rang);
			base:TableInsert(tResultat_Manche, row);
		end
	end
	cmd = 'Update Resultat_Manche Set Reserve = Null  Where Code_evenement = '..params.code_evenement..' And Code_manche = 1';
	base:Query(cmd);
	if tTable_Boucle then
		tTable_Boucle:Delete();
	end
end

function BuildTableTirage2(tablex, bib_first)
	params.tableDossards1 = {};
	for row = 0, tablex:GetNbRows() -1 do
		table.insert(params.tableDossards1, bib_first + row);
	end
	params.tableDossards1 = Shuffle(params.tableDossards1, false);
	tTableTirage1:RemoveAllRows();
	for row = 0, tablex:GetNbRows() -1 do
		local new_row1 = tTableTirage1:AddRow();
		tTableTirage1:SetCell('Row', new_row1, row+1);
	end
	tTableTirage1:OrderBy('Row');
	tTableTirage1:OrderRandom('Row');
	for i = 0, tTableTirage1:GetNbRows() -1 do
		local ligne = tTableTirage1:GetCellInt('Row', i);
		local dossard = params.tableDossards1[ligne];
		tablex:SetCell('Dossard', i, dossard);
		local code_coureur = tablex:GetCell('Code_coureur', i);
		local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
		tResultat:SetCell('Dossard', r, dossard);
		tResultat:SetCell('Rang', r, dossard);
		-- adv.Alert('dossard mis à jour : '..dossard);
	end
end


function BuildTableTirage(tablex, rang_tirage, bib_first, set_rang);
	adv.Alert('dans BuildTableTirage avant filtrage, tablex:GetNbRows() = '..tablex:GetNbRows());
	if rang_tirage then
		local filter = "$(Rang):In("..rang_tirage..")";
		tablex:Filter(filter, true);
	end
	adv.Alert('dans BuildTableTirage rang = '..tostring(rang_tirage)..', bib_first = '..tostring(bib_first)..', setrang = '..tostring(set_rang)..')'..', tablex:GetNbRows() = '..tablex:GetNbRows());
	params.tableDossards1 = {};
	local shuffle = true;

	local bib = rang_tirage;
	if bib_first then
		bib = bib_first;
	end
	for row = 0, tablex:GetNbRows() - 1 do
		table.insert(params.tableDossards1, bib);
		bib = bib + 1;
		if bib_first then
			params.bib_first = bib;
		end
	end
	if shuffle then
		params.tableDossards1 = Shuffle(params.tableDossards1, false);
	end
	tTableTirage1:RemoveAllRows();
	local rang_fictif = 0;
	for row = 1, #params.tableDossards1 do
		local new_row1 = tTableTirage1:AddRow();
		tTableTirage1:SetCell('Row', new_row1, row);	-- setCell du rang fictif en lien avec  params.tableDossards1
		tTableTirage1:OrderRandom();
	end
	
	for row = 0, tTableTirage1:GetNbRows() -1 do
		local rang_fictif = tTableTirage1:GetCellInt('Row', row);
		local code_coureur = tablex:GetCell('Code_coureur', row);
		tCoureur[code_coureur] = tCoureur[code_coureur] or {};
		local row_coureur = tResultat:GetIndexRow('Code_coureur', code_coureur);
		local dossard = params.tableDossards1[rang_fictif];
		tCoureur[code_coureur].Dossard = dossard;
		tResultat:SetCell('Dossard', row_coureur, dossard);
		if set_rang then
			tResultat:SetCell('Rang', row_coureur, rang_tirage);
		end
	end
end

function SetGroupes(nbGroupes, ibibo)
	--table.insert(tBibo, {Sexe = 'M', NbRows = tResultat:GetCounterValue('Sexe', 'M'), RowFirst = 0, RowEnd = tResultat:GetCounterValue('Sexe', 'M') -1, PtsBibo = 0, LastRowBibo = -1,  LastRowPts = -1, FirstRowPtsNull = -1, Reserves = {}});
	local reserve = 0;
	if ibibo == 2 then
		local treserve = tBibo[ibibo-1].Reserves;
		reserve = treserve[#treserve];
	end
	local dans_le_groupe = 10000;
	local sexe_en_cours = tBibo[ibibo].Sexe
	local tResultat_Copy = tResultat:Copy();
	local filter = "$(Sexe):In('"..sexe_en_cours.."')";
	tResultat_Copy:Filter(filter, true);
	local nb_par_groupe = math.floor(tResultat_Copy:GetNbRows() / nbGroupes);
	tCoureur = tCoureur or {};	
	tResultat_Copy:OrderRandom();
	local tReserves = {};	
	for row = 0, tResultat_Copy:GetNbRows() - 1 do
		dans_le_groupe = dans_le_groupe + 1;
		local code_coureur = tResultat_Copy:GetCell('Code_coureur', row);
		if dans_le_groupe > nb_par_groupe and #tReserves < nbGroupes then
			dans_le_groupe = 1;
			reserve = reserve + 1;
			table.insert(tReserves, reserve)
		end
		local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
		tCoureur[code_coureur] = {};
		tCoureur[code_coureur].Reserve = reserve;
		tResultat:SetCell('Reserve', r, reserve);
		tResultat:SetCell('Rang', r, reserve);
	end
	tBibo[ibibo].Reserves = tReserves;
end

function SetDossardBackOffice(course, nbGroupes)
	tBibo = {};
	if tResultat:GetCounterValue('Sexe', 'F') > 0 then
		table.insert(tBibo, {Sexe = 'F', NbRows = tResultat:GetCounterValue('Sexe', 'F'), RowFirst = 0, RowEnd = tResultat:GetCounterValue('Sexe', 'F') -1, PtsBibo = 0, LastRowBibo = -1, LastRowPts = -1, FirstRowPtsNull = -1, Reserves = {}});
	end
	if tResultat:GetCounterValue('Sexe', 'M') > 0 then
		table.insert(tBibo, {Sexe = 'M', NbRows = tResultat:GetCounterValue('Sexe', 'M'), RowFirst = 0, RowEnd = tResultat:GetCounterValue('Sexe', 'M') -1, PtsBibo = 0, LastRowBibo = -1,  LastRowPts = -1, FirstRowPtsNull = -1, Reserves = {}});
	end
	
	-- on fera toujours un double tirage des dossards en manche 1 de la course 1
	-- params.tableDossards1 est brassée par la fonction Shuffle du fichier functionPG.lua
	-- tTableTirage1 est brassée par la méthode OrderRandom de skiFFS
	-- des groupes seront constitués selon le back office
	-- la colonne Reserve sera mise à jour selon les différents groupes
	if course == 1 or params.bib_skip == 0 then
		for i = 1, #tBibo do
			tBibo[i].Reserves = {};
			SetGroupes(nbGroupes, i);
			local tReserve = tBibo[i].Reserves
			for ireserve = 1, #tReserve do
				-- adv.Alert('BuildTableTirage( rang = '..tReserve[ireserve]..', bib_first = '..params.bib_first..', setrang = '..tostring(true)..')'..', tResultat_Copy:GetNbRows() = '..tResultat_Copy:GetNbRows());
				local tablex = tResultat:Copy();
				BuildTableTirage(tablex, tReserve[ireserve], params.bib_first, false) ;
			end
		end
	end
	return true;
end

function OnTirageM2(option2)
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.course1);
	tResultat:SetCounter('Reserve');
	tResultat_Manche = base:GetTable('Resultat_Manche');
	local rang = 1;
	for reserve = 1, tResultat:GetCounter('Reserve'):GetNbRows() do
		local tResultat_Copy = tResultat:Copy();
		local filtre = '$(Reserve):In('..reserve..')';
		tResultat_Copy:Filter(filtre, true);
		tResultat_Copy:OrderBy('Dossard');
		if string.find(option2, '2%.') then
			tResultat_Copy:OrderBy('Dossard DESC');
		end
		for row = 0, tResultat_Copy:GetNbRows() -1 do
			local addrow = tResultat_Manche:AddRow()
			local code_coureur = tResultat_Copy:GetCell('Code_coureur', row);
			tResultat_Manche:SetCell('Code_evenement', addrow, params.course1);
			tResultat_Manche:SetCell('Code_coureur', addrow, code_coureur);
			tResultat_Manche:SetCell('Code_manche', addrow, 2);
			tResultat_Manche:SetCell('Rang', addrow, rang);
			base:TableInsert(tResultat_Manche, addrow);
			rang = rang + 1;
		end
		-- base:TableBulkInsert(tResultat_Manche);
	end
end
	
function OnTirageBackOffice(course, paramsManche, manche_start)
	-- selection = 3 : 4. Tirage pour des courses de 3 manches
	-- selection = 4 : 5. Tirage pour des courses de 4 manches
	-- selection = 5 : 6. Tirage pour des courses de 2 manches
	-- tirage selon le back office
	local nbmanches = #paramsManche;
	tResultat:OrderBy('Dossard');
	tResultat:SetCounter('Reserve');
	tResultat:SetCounter('Sexe');
	for run = manche_start, nbmanches do
		local rang = 0;
		local groupes = paramsManche[run].Groupes;
		local tGroupes = groupes:Split(',');
		-- for i = 1, #tGroupes do
			-- adv.Alert('run = '..run..', Ordre des groupes : '..tGroupes[i]);
		-- end
		local sens = paramsManche[run].Sens;
		for i = 1, #tGroupes do
			local reserve = tGroupes[i];
			rang = OnTirageGroupe(params['course'..course], run, reserve, sens, rang);
		end
		if tResultat:GetCounter('Sexe'):GetNbRows() > 1 then
			for i = 1, #tGroupes do
				local reserve = tGroupes[i] + #tGroupes;
				rang = OnTirageGroupe(params['course'..course], run, reserve, sens, rang);
			end
		end
	end
end

function OnTirageGroupe(code_evenement, manche, reserve, sens, rang)
	-- sens = 0 -> à la mêlée
	-- sens = 1 -> par ordre croissant
	-- sens = 2 -> par ordre décroissant
	local rang_tirage = rang;
	local tResultat_Copy = tResultat:Copy();
	local filter = '$(Reserve):In('..reserve..')';
	tResultat_Copy:Filter(filter, true);
	-- adv.Alert('OnTirageGroupe('..code_evenement..', '..manche..', '..reserve..', '..sens..', '..rang..')'..', tResultat_Copy:GetNbRows()  = '..tResultat_Copy:GetNbRows())
	if sens == 0 then
		tResultat_Copy:OrderRandom();
		-- adv.Alert('tirage à la mêlée');
	elseif sens == 1 then
		tResultat_Copy:OrderBy('Dossard');
		-- adv.Alert('tirage par ordre croissant');
	elseif sens == 2 then
		tResultat_Copy:OrderBy('Dossard DESC');
		-- adv.Alert('tirage par ordre décroissant');
	else
		return;
	end
	for j = 0, tResultat_Copy:GetNbRows() -1 do
		local code_coureur = tResultat_Copy:GetCell('Code_coureur', j);
		rang_tirage = rang_tirage + 1;
		local row = tResultat_Manche:AddRow();
		tResultat_Manche:SetCell('Code_evenement', row, code_evenement);
		tResultat_Manche:SetCell('Code_manche', row, manche);
		tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
		tResultat_Manche:SetCell('Rang', row, rang_tirage);
		tResultat_Manche:SetCell('Reserve', row, reserve);
		base:TableInsert(tResultat_Manche, row);
	end
	return rang_tirage;
end

function main(params_c)
	params = {};
	params.code_evenement = params_c.code_evenement;
	if params.code_evenement < 0 then
		return;
	end
	params.faire = params_c.faire or '';
	params.width = (display:GetSize().width * 2) / 3;
	params.height = display:GetSize().height / 2;
	params.x = (display:GetSize().width - params.width) / 2;
	params.y = 200;
	
	scrip_version = "3.3"; 
	-- vérification de l'existence d'une version plus récente du script.
	-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2,DoubleTirage=3.2,TirageOptions=3.3,TirageER=1.7,ListeMinisterielle=2.3,KandaHarJunior=2.0
	if app.GetVersion() >= '4.4c' then 
		indice_return = 5;
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
	
	base = base or sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	tResultat = base:GetTable('Resultat');
	tResultat_Copy = tResultat:Copy();
	ReplaceTableEnvironnement(tResultat_Copy, '_Resultat_Copy');
	tCoureur = {};
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement..' Order By Rang, Dossard');
	tDraw = tResultat:Copy();
	ReplaceTableEnvironnement(tDraw, '_tDraw');
	for row = 0, tResultat:GetNbRows() -1 do
		local code_coureur = tResultat:GetCell('Code_coureur', row);
		tCoureur[code_coureur] = {};
		tCoureur[code_coureur].Reserve = -1;
		tCoureur[code_coureur].Dossard = -1;
		tCoureur[code_coureur].Rang = -1;
	end
	params.dossard1 = tResultat:GetCellInt('Dossard', 0);
	tResultat_Manche = base:GetTable('Resultat_Manche');
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	tCategorie = base:GetTable('Categorie');
	base:TableLoad(tCategorie, "Select * From Categorie Where Code_activite = 'ALP' And Code_entite = 'FFS' And Code_grille = 'FFS-ALP' And Code_saison = '"..tEvenement:GetCell('Code_saison', 0).."' Order By Ordre");
	params.code_niveau = tEpreuve:GetCell('Code_niveau', 0);
	params.nbmanches = tEpreuve:GetCellInt('Nombre_de_manche', 0);
	
	tTableTirage1 = sqlTable.Create('_TableTirage1');
	tTableTirage1:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage1, '_TableTirage1');
	tTableTirage2 = sqlTable.Create('_TableTirage2');
	tTableTirage2:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage2, '_TableTirage2');

	params.code_liste = tEvenement:GetCellInt("Code_liste", 0)
	params.code_entite = tEvenement:GetCell("Code_entite",0);
	params.code_activite = tEvenement:GetCell("Code_activite",0);
	params.code_saison = tEvenement:GetCell("Code_saison", 0);
	params.code_grille_categorie = tEpreuve:GetCell("Code_grille_categorie", 0);
	if params.code_entite ~= 'FFS' then
		local msg = "Ce scénario n'est valable que pour les courses FFS !!";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
		return;
	end
	
	tBibo = {};
	if tResultat:GetCounterValue('Sexe', 'F') > 0 then
		table.insert(tBibo, {Sexe = 'F', NbRows = tResultat:GetCounterValue('Sexe', 'F'), RowFirst = 0, RowEnd = tResultat:GetCounterValue('Sexe', 'F') -1, PtsBibo = 0, LastRowBibo = -1, LastRowPts = -1, FirstRowPtsNull = -1, Reserves = {}});
	end
	if tResultat:GetCounterValue('Sexe', 'M') > 0 then
		table.insert(tBibo, {Sexe = 'M', NbRows = tResultat:GetCounterValue('Sexe', 'M'), RowFirst = 0, RowEnd = tResultat:GetCounterValue('Sexe', 'M') -1, PtsBibo = 0, LastRowBibo = -1,  LastRowPts = -1, FirstRowPtsNull = -1, Reserves = {}});
	end
	tResultat:SetCounter('Categ');
	tResultat:SetCounter('An');
	
	params.codex = tEvenement:GetCell("Codex", 0);
	-- Ouverture Document XML 
	local xml_config = app.GetPath()..'/process/dossard_TirageOptions_config.xml';
	if not app.FileExists(xml_config) then
		CreateXMLConfig();
	end

	xml_config = "./process/dossard_TirageOptions_config.xml";
	params.doc_config = xmlDocument.Create(xml_config);
	params.nodeConfig = params.doc_config:FindFirst('root/config');
	params.course2 = tonumber(params.nodeConfig:GetAttribute('course2')) or -1
	params.nodeSetupx4 = params.doc_config:FindFirst('root/manchesx4');
	params.nodeSetup2x2 = params.doc_config:FindFirst('root/manches2x2');
	params.nodeSetupx3 = params.doc_config:FindFirst('root/manchesx3');
	
	XML = "./process/dossard_TirageOptions.xml";
	params.doc = xmlDocument.Create(XML);
	if params.faire == 'M1_M2' then
		clef1 = '1. Par Sexe';
		option1 = '7. BIBO en manche 3 / résultat des 2 premières';
		option2 = '3. Gestion du BIBO';
		OnTirageM3Seule();
		return true;
	end
	dlgConfig = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Configuration du tirage', 
		icon='./res/32x32_ffs.png'
		});
	dlgConfig:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		node_value = 'config',
		niveau = params.code_niveau
	});

	-- Toolbar Principale ...
	local tbconfig = dlgConfig:GetWindowName('tbconfig');
	assert(tbconfig ~= nil);
	tbconfig:AddStretchableSpace();
	local btnSetup = tbconfig:AddTool("Back Office", "./res/32x32_param.png");
	tbconfig:AddSeparator();
	local btnSave = tbconfig:AddTool("Lancer le tirage", "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	tbconfig:EnableTool(btnSetup:GetId(), false);

	local message = app.GetAuiMessage();
	dlgConfig:GetWindowName('clef1'):Clear();
	dlgConfig:GetWindowName('clef1'):Append('1. Par Sexe');
	dlgConfig:GetWindowName('clef1'):Append('2. Par Sexe et par Catégorie');
	dlgConfig:GetWindowName('clef1'):Append('3. Par Sexe et par Année');
	dlgConfig:GetWindowName('clef1'):Append('4. Sans objet');
		
	dlgConfig:GetWindowName('option1'):Clear();
	dlgConfig:GetWindowName('option1'):Append('1. Tirage pour la manche 1 seulement');
	dlgConfig:GetWindowName('option1'):Append('2. Tirage pour les manches 1 et 2');
	dlgConfig:GetWindowName('option1'):Append('3. Tirage pour la manche 2 (ABD DSQ ordre inverse)');
	dlgConfig:GetWindowName('option1'):Append('4. Tirage pour des courses de 3 manches');
	dlgConfig:GetWindowName('option1'):Append("5. Tirage pour des courses de 4 manches");
	dlgConfig:GetWindowName('option1'):Append("6. Tirage pour des courses de 2 manches");
	dlgConfig:GetWindowName('option1'):Append("7. BIBO en manche 3 / résultat des 2 premières");
	
	dlgConfig:GetWindowName('option2'):Clear();
	dlgConfig:GetWindowName('option2'):Append("1. Pas d'inversion des dossards dans les groupes de tirage");
	dlgConfig:GetWindowName('option2'):Append('2. Inversion des dossards dans les groupes de tirage');
	dlgConfig:GetWindowName('option2'):Append('3. Gestion du BIBO');
	dlgConfig:GetWindowName('option2'):Append('4. Selon le paramétrage du Back Office');
	dlgConfig:GetWindowName('option2'):Append('5. Sans objet');

	dlgConfig:GetWindowName('course1'):SetValue(params.code_evenement);
	if params.course2 > 0 then
		dlgConfig:GetWindowName('course2'):SetValue(params.course2);
		local tEvenement2 = base:TableLoad('Select Nom From Evenement Where Code = '..params.course2);
		if tEvenement2:GetNbRows() > 0 then
			dlgConfig:GetWindowName('course2_nom'):SetValue(tEvenement2:GetCell('Nom', 0));
		end
	end
	local clef1_config = tonumber(params.nodeConfig:GetAttribute('clef1')) or 0;
	local option1_config = tonumber(params.nodeConfig:GetAttribute('option1')) or 0;
	local option2_config = tonumber(params.nodeConfig:GetAttribute('option2')) or 0;
	dlgConfig:GetWindowName('clef1'):SetSelection(clef1_config);
	dlgConfig:GetWindowName('option1'):SetSelection(option1_config);
	dlgConfig:GetWindowName('option2'):SetSelection(option2_config);
	if dlgConfig:GetWindowName('option1'):GetSelection() > 2 then
		tbconfig:EnableTool(btnSetup:GetId(), true);
	end
	dlgConfig:GetWindowName('course1_nom'):SetValue(tEvenement:GetCell('Nom', 0));
	clef1 = dlgConfig:GetWindowName('clef1'):GetValue();
	option1 = dlgConfig:GetWindowName('option1'):GetValue();
	option2 = dlgConfig:GetWindowName('option2'):GetValue();
	ValideClef1(clef1, option1, option2);
	ValideOption1(clef1, option1, option2);
	ValideOption2(clef1, option1, option2);
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
			local code_evenement1 = tonumber(dlgConfig:GetWindowName('course1'):GetValue()) or -1;
			local tEvenement1 = base:TableLoad('Select Nom From Evenement Where Code = '..code_evenement1);
			if tEvenement1:GetNbRows() > 0 then
				dlgConfig:GetWindowName('course1_nom'):SetValue(tEvenement1:GetCell('Nom', 0));
			else
				dlgConfig:GetWindowName('course1_nom'):SetValue('');
			end
		end, dlgConfig:GetWindowName('course1')); 

	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
			local clef1 = dlgConfig:GetWindowName('clef1'):GetValue();
			local option1 = dlgConfig:GetWindowName('option1'):GetValue();
			local option2 = dlgConfig:GetWindowName('option2'):GetValue();
			ValideClef1(clef1, option1, option2);
		end, dlgConfig:GetWindowName('clef1')); 
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
			local code_evenement2 = tonumber(dlgConfig:GetWindowName('course2'):GetValue()) or -1;
			local tEvenement2 = base:TableLoad('Select Nom From Evenement Where Code = '..code_evenement2);
			if tEvenement2:GetNbRows() > 0 then
				dlgConfig:GetWindowName('course2_nom'):SetValue(tEvenement2:GetCell('Nom', 0));
			else
				dlgConfig:GetWindowName('course2_nom'):SetValue('');
			end
		end, dlgConfig:GetWindowName('course2')); 
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
			local clef1 = dlgConfig:GetWindowName('clef1'):GetValue();
			local option1 = dlgConfig:GetWindowName('option1'):GetValue();
			local option2 = dlgConfig:GetWindowName('option2'):GetValue();
			ValideOption1(clef1, option1, option2);
			if dlgConfig:GetWindowName('option1'):GetSelection() > 2 then
				tbconfig:EnableTool(btnSetup:GetId(), true);
			end

		end, dlgConfig:GetWindowName('option1')); 
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
			clef1 = dlgConfig:GetWindowName('clef1'):GetValue();
			option1 = dlgConfig:GetWindowName('option1'):GetValue();
			option2 = dlgConfig:GetWindowName('option2'):GetValue();
			ValideOption2(clef1, option1, option2);
		end, dlgConfig:GetWindowName('option2')); 

	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			clef1 = dlgConfig:GetWindowName('clef1'):GetValue();
			option1 = dlgConfig:GetWindowName('option1'):GetValue();
			option2 = dlgConfig:GetWindowName('option2'):GetValue();
			if dlgConfig:GetWindowName('course1') then
				params.course1 = tonumber(dlgConfig:GetWindowName('course1'):GetValue()) or -1;
			else
				params.course1 = params.code_evenement;
			end
			if dlgConfig:GetWindowName('course2') then
				params.course2 = tonumber(dlgConfig:GetWindowName('course2'):GetValue()) or -1;
			else
				params.course2 = -1;
			end
			params.nodeConfig:ChangeAttribute('course1', params.course1);
			params.nodeConfig:ChangeAttribute('course2', params.course2);
			params.nodeConfig:ChangeAttribute('clef1', dlgConfig:GetWindowName('clef1'):GetSelection());
			params.nodeConfig:ChangeAttribute('option1', dlgConfig:GetWindowName('option1'):GetSelection());
			params.nodeConfig:ChangeAttribute('option2', dlgConfig:GetWindowName('option2'):GetSelection());
			params.doc_config:SaveFile();
			dlgConfig:EndModal(idButton.OK);
		end, btnSave); 
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:EndModal(idButton.CANCEL);
		 end,  btnClose);
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			local selection = dlgConfig:GetWindowName('option1'):GetSelection();
			if selection == 3 then
				params.activeNode = params.nodeSetupx3;
			elseif selection == 4 then
				params.activeNode = params.nodeSetupx4;
			else
				params.activeNode = params.nodeSetup2x2;
			end
			OnSetup(selection, false);
		 end,  btnSetup);

	dlgConfig:Fit();
	
	if dlgConfig:ShowModal() == idButton.OK then
		local intKO = 0;
		local node_nbmanches = nil;
		local selection = dlgConfig:GetWindowName('option1'):GetSelection();
		if selection == 3 then
			params.activeNode = params.nodeSetupx3;
		elseif selection == 4 then
			params.activeNode = params.nodeSetupx4;
		elseif selection == 5 then
			params.activeNode = params.nodeSetup2x2;
		end
		if selection > 2 and selection < 6 then
			params.bib_skip = tonumber(params.activeNode:GetAttribute('bib_skip')) or 0;
			node_nbmanches = tonumber(params.activeNode:GetAttribute('nb_manches')) or -1;
			params.tirageCourse = DecodeActiveNode();
			if params.course1 > 0 then
				base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.course1);
				if tEpreuve:GetCellInt('Nombre_de_manche', 0) ~= node_nbmanches then
					intKO = node_nbmanches;
				end
			end
			if params.course2 > 0 then
				base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.course2);
				if tEpreuve:GetCellInt('Nombre_de_manche', 0) ~= node_nbmanches then
					intKO = node_nbmanches;
				end
			end
		end
		
		if string.find(option1, '1%.') then
			OnTirageManche1();
		elseif string.find(option1, '2%.') then
			base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement..' And Code_epreuve = 1');
			params.nb_manche = tEpreuve:GetCellInt('Nombre_de_manche', 0);
			if params.nb_manche ~= 2 then
				local msg = "Le nombre de manche doit être égal à 2 !!";
				app.GetAuiFrame():MessageBox(msg, "ATTENTION !!!"
					, msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
				return;
			end
			OnTirageManche1();
			OnTirageM2(option2);
		elseif string.find(option1, '3%.') then
			OnTirageManche2Special()
		elseif string.find(option1, '7%.') then
			OnTirageM3Seule();
			-- on lance le report avec un body spécial;
		else
			base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.course1..' And Dossard > 0');
			if tResultat:GetNbRows() > 0 then
				local msg = "Les dossards ont déjà été tirés.\nVoulez-vous les remplacer ?\nTous les rangs de tirage antérieurs seront supprimés \nainsi que tous les temps des manches éventuels.";
				if app.GetAuiFrame():MessageBox(msg, "Vérification !!!"
					, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
					return false;
				end
			end
			local cmd = 'Update Resultat Set Dossard = Null, Rang = null Where Code_evenement IN('..params.course1..','..params.course2..')';
			base:Query(cmd);
			cmd = 'Delete From Resultat_Manche Where Code_evenement IN('..params.course1..','..params.course2..')' ;
			base:Query(cmd);
			for course = 1, 2 do
				params.bib_first = 1;
				if params['course'..course] > 0 then
					base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params['course'..course]);
					local paramsManche = params.tirageCourse[course].Data;
					local nbGroupes = tonumber(string.sub(paramsManche[course].Groupes, -1)) or 1;
					params.affiche_bibfirst = 0;
					if course == 1 or params.bib_skip == 0 then
						local ok = SetDossardBackOffice(course, nbGroupes);
						if ok then
							OnTirageBackOffice(course, paramsManche, 2)
						end
					end
					if course == 2 and params.bib_skip == 1 then
					-- function OnTirageGroupe(code_evenement, manche, reserve, sens, rang)
						for row = 0, tResultat:GetNbRows()-1 do
							local code_coureur = tResultat:GetCell('Code_coureur', row);
							if tCoureur[code_coureur] then
								tResultat:SetCell('Dossard', row, tCoureur[code_coureur].Dossard);
								tResultat:SetCell('Reserve', row, tCoureur[code_coureur].Reserve);
							end
						end
						for run = 1, #paramsManche do
							local rang = 0;
							local groupes = paramsManche[run].Groupes;
							local tGroupes = groupes:Split(',');
							local sens = paramsManche[run].Sens;
							for i = 1, #tGroupes do
								local reserve = tGroupes[i];
								rang = OnTirageGroupe(params['course'..course], run, reserve, sens, rang);
							end
							if tResultat:GetCounter('Sexe'):GetNbRows() > 1 then
								for i = 1, #tGroupes do
									local reserve = tGroupes[i] + #tGroupes;
									rang = OnTirageGroupe(params['course'..course], run, reserve, sens, rang);
								end
							end
						end
					end
				end
				base:TableBulkUpdate(tResultat, 'Rang, Dossard, Reserve', 'Resultat');
			end
		end
		local cmd = 'Update Resultat Set Rang = NULL Where Code_evenement IN('..params.course1..','..params.course2..')';
		base:Query(cmd);
	end
	if params.doc then params.doc:Delete(); end
	if params.doc_config then params.doc_config:Delete(); end
	
	return true;
end
