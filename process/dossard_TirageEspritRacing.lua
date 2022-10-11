-- Esprit Racing - Tirage des dossards et des rangs de départ en manche 2 par Philippe Guérindon
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function GetMenuName()
	return "Esprit Racing - Tirage des dossards ou des rangs de départ";
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
		local dossard = params.tDraw_Copy:GetCell('Dossard', i);
		local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
		local point = params.tDraw_Copy:GetCellDouble('Point', i);
		if point == point_encours then
			table.insert(params.row_exaequo, rang_tirage)
			nb_exeaquo = nb_exeaquo + 1;
			adv.Alert('exaequo dossard : '..dossard);
		else
			rang_tirage = rang_tirage + nb_exeaquo + 1;
			nb_exeaquo = 0;
			point_encours = point;
		end
		params.tDraw_Copy:SetCell('Rang', i, rang_tirage);
		tResultat:SetCell('Rang', r, rang_tirage);
	end
end
		
function OnTirageManche1()
	if params.dossard1 > 0 then
		local msg = "Les dossards ont déjà été tirés.\nVoulez-vous les remplacer ?\nTous les rangs de tirage antérieurs seront supprimés.";
		if app.GetAuiFrame():MessageBox(msg, "Attention !!!"
			, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
			return;
		end
	end
	params.dossard = 1;
	if params.nb_dames > 0 then
		for i = 1, 	#tCoureurs.F do
			tDraw = tResultat:Copy();
			local filter = "$(Reserve):In("..tCoureurs.F[i].Reserve..")";
			tDraw:Filter(filter, true);
			tCoureurs.F[i].Nombre = tDraw:GetNbRows();
			if tCoureurs.F[i].Nombre > 0 then
				for j = 0, tDraw:GetNbRows() -1 do
					if tDraw:GetCellDouble('Point', j, -1) >= 0 then 
						tCoureurs.F[i].NbPoint = tCoureurs.F[i].NbPoint + 1;
					end
				end
				OnTirageDossard(tDraw, tCoureurs.F[i].Nombre, tCoureurs.F[i].NbPoint);
			end
		end
	end
	if params.nb_hommes > 0 then
		for i = 1, 	#tCoureurs.M do
			tDraw = tResultat:Copy();
			local filter = "$(Reserve):In("..tCoureurs.M[i].Reserve..")";
			tDraw:Filter(filter, true);
			tCoureurs.M[i].Nombre = tDraw:GetNbRows();
			if tCoureurs.M[i].Nombre > 0 then
				for j = 0, tDraw:GetNbRows() -1 do
					if tDraw:GetCellDouble('Point', j, -1) >= 0 then 
						tCoureurs.M[i].NbPoint = tCoureurs.M[i].NbPoint + 1;
					end
				end
				OnTirageDossard(tDraw, tCoureurs.M[i].Nombre, tCoureurs.M[i].NbPoint);
			end
		end
	end
	if #params.tExaequo > 0 then
		local msg = "Il y a égalité de points pour :\n";
		for i = 1, #params.tExaequo do
			local rang = params.tExaequo[i];
			tResultat_Copy = tResultat:Copy();
			tResultat_Copy:OrderRandom();
			local filter = "$(Rang):In("..rang..")";
			tResultat_Copy:Filter(filter, true);
			tResultat_Copy:OrderRandom();
			for j = 0, tResultat_Copy:GetNbRows() -1 do
				local dossard = rang + j;
				msg = msg..tResultat_Copy:GetCell('Nom', j)..', dossard attribué = '..dossard..'\n';
				tResultat_Copy:SetCell('Dossard', j, dossard);
			end							
		end
		base:TableBulkUpdate(tResultat_Copy, 'Dossard', 'Resultat');
		app.GetAuiFrame():MessageBox(msg, "Tirage au sort des exaequos !!!"
			, msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
	end
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
			rang = OnTirageDossard(params['course'..course], run, reserve, sens, rang);
		end
		if tResultat:GetCounter('Sexe'):GetNbRows() > 1 then
			for i = 1, #tGroupes do
				local reserve = tGroupes[i] + #tGroupes;
				rang = OnTirageDossard(params['course'..course], run, reserve, sens, rang);
			end
		end
	end
end

function OnTirageDossard(tablex, nombre, nombre_point)
	tablex:OrderBy('Point');
	local reserve = tablex:GetCellInt('Reserve', 0);
	local nb_aexequo = 0;
	local table_bibo = tablex:Copy();
	local table_pts = tablex:Copy();
	local table_pts0 = tablex:Copy();
	for j = table_pts0:GetNbRows() -1, 0, -1 do
		if table_pts0:GetCellDouble('Point', j, -1) >= 0 then
			table_pts0:RemoveRowAt(j);
		end
	end
	for j = table_pts:GetNbRows() -1, 0, -1 do
		if table_pts:GetCellDouble('Point', j, -1) < 0 then
			table_pts:RemoveRowAt(j);
		end
	end
	local pts_bibo = -1;
	local nb_exeaquo = 0;
	if nombre >= params.bibo_m1 then
		if nombre_point >= params.bibo_m1 then
			pts_bibo = tablex:GetCellDouble('Point', params.bibo_m1 - 1);
		else
			pts_bibo = tablex:GetCellDouble('Point', nombre_point -1);
		end
	elseif nombre_point > 0 then
		pts_bibo = tablex:GetCellDouble('Point', nombre_point -1);
	end
	if pts_bibo < 0 then
		tablex:OrderRandom();
		for j = 0, tablex:GetNbRows() -1 do
			tablex:SetCell('Dossard', j , params.dossard);
			params.dossard = params.dossard + 1;
		end
		base:TableBulkUpdate(tablex, 'Dossard', 'Resultat');
	else
		for j = table_bibo:GetNbRows() -1, 0, -1 do
			local pts = table_bibo:GetCellDouble('Point', j, -1);
			if pts > pts_bibo or pts < 0 then
				table_bibo:RemoveRowAt(j);
			end
		end
		table_bibo:OrderRandom();
		for j = 0, table_bibo:GetNbRows() -1 do
			local code_coureur = table_bibo:GetCell('Code_coureur', j);
			table_bibo:SetCell('Dossard', j , params.dossard);
			local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then
				tResultat:SetCell('Dossard', r, params.dossard);
			end
			params.dossard = params.dossard + 1;
			local row = table_pts:GetIndexRow('Code_coureur', code_coureur);
			if row >= 0 then
				table_pts:RemoveRowAt(row);
			end
		end
		if table_pts:GetNbRows() > 0 then
			local nb_aexequo = 0;
			local code_next = "-1";
			local r_next = -1;
			local rang_egal = -1;
			for j = 0, table_pts:GetNbRows() -1 do
				local code_coureur = table_pts:GetCell('Code_coureur', j);
				local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
				local pts = table_pts:GetCellDouble('Point', j);
				local pts_next = -1;
				table_pts:SetCell('Dossard', j , params.dossard);
				if j < tablex:GetNbRows() -1 then
					pts_next = table_pts:GetCellDouble('Point', j+1);
					code_next = table_pts:GetCell('Code_coureur', j+1);
					local r_next = tResultat:GetIndexRow('Code_coureur', code_next);
					if pts == pts_next then
						nb_aexequo = nb_aexequo + 1;
					else
						nb_aexequo = 0;
					end	
					if nb_aexequo > 0 then
						if nb_aexequo == 1 then
							rang_egal = params.dossard;
							adv.Alert('traitement de table_pts, exaequo au rang '..rang_egal);
							if params.tExaequo[#params.tExaequo] ~= rang_egal then
								table.insert(params.tExaequo, rang_egal);
							end
							tResultat:SetCell('Rang', r, rang_egal);
							tResultat:SetCell('Rang', r_next, rang_egal);
						else
							tResultat:SetCell('Rang', r_next, rang_egal);
						end
					end
				end
				if r >= 0 then
					tResultat:SetCell('Dossard', r, params.dossard);
					if nb_aexequo > 0 then
					end
				end
				params.dossard = params.dossard + 1;
			end
		end
		table_pts0:OrderRandom();
		if table_pts0:GetNbRows() > 0 then
			for j = 0, table_pts0:GetNbRows() -1 do
				local code_coureur = table_pts0:GetCell('Code_coureur', j);
				table_pts0:SetCell('Dossard', j , params.dossard);
				local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
				if r >= 0 then
					tResultat:SetCell('Dossard', r, params.dossard);
				end
				params.dossard = params.dossard + 1;
			end
		end
	end
	base:TableBulkUpdate(tResultat);
end

function main(params_c)
	params = {};
	params.code_evenement = params_c.code_evenement;
	if params.code_evenement < 0 then
		return;
	end
	params.width = (display:GetSize().width * 2) / 3;
	params.height = display:GetSize().height / 2;
	params.x = (display:GetSize().width - params.width) / 2;
	params.y = 200;
	params.version = "1.0";
	base = base or sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	tResultat = base:GetTable('Resultat');
	tResultat_Copy = tResultat:Copy();
	ReplaceTableEnvironnement(tResultat_Copy, '_Resultat_Copy');
	tDraw = tResultat:Copy();
	ReplaceTableEnvironnement(tDraw, '_tDraw');
	tDraw_Copy = tResultat:Copy();
	ReplaceTableEnvironnement(tDraw, '_tDraw_Copy');
	
	local cmd = "Update Resultat Set Dossard = Null, Rang = Null, Reserve = Null Where Code_evenement = "..params.code_evenement;
	base:Query(cmd);
	tCoureur = {};
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tResultat:OrderBy('Point');
	tResultat:SetCounter('Sexe');
	params.nb_dames = tResultat:GetCounterValue('Sexe', 'F');
	params.nb_hommes = tResultat:GetCounterValue('Sexe', 'M');
	params.dossard1 = tResultat:GetCellInt('Dossard', 0);
	tResultat_Manche = base:GetTable('Resultat_Manche');
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	tCategorie = base:GetTable('Categorie');
	params.nbmanches = tEpreuve:GetCellInt('Nombre_de_manche', 0);
	
	tTableTirage1 = sqlTable.Create('_TableTirage1');
	tTableTirage1:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage1, '_TableTirage1');
	tTableTirage2 = sqlTable.Create('_TableTirage2');
	tTableTirage2:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage2, '_TableTirage2');

	params.code_entite = tEvenement:GetCell("Code_entite",0);
	params.code_activite = tEvenement:GetCell("Code_activite",0);
	params.code_saison = tEvenement:GetCell("Code_saison", 0);
	if params.code_entite ~= 'FFS' then
		local msg = "Ce scénario n'est valable que pour les courses FFS !!";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
		return;
	end
	
	-- if tResultat:GetCounterValue('Sexe', 'M') > 0 then
	XML = "./process/dossard_TirageEspritRacing.xml";
	params.doc = xmlDocument.Create(XML);
	params.nodeDefault = params.doc:FindFirst('root/default');
	params.nodeConfig = params.doc:FindFirst('root/config');
	params.nodeDames = params.doc:FindFirst('root/config/dames');
	params.nodeHommes = params.doc:FindFirst('root/config/hommes');
	params.bibo_m1 = tonumber(params.nodeConfig:GetAttribute('bibo_m1')) or 10;
	params.bibo_m2 = tonumber(params.nodeConfig:GetAttribute('bibo_m1')) or 10;
	tCoureurs = {};
	tCoureurs.F = {};
	tCoureurs.M = {};
	
	local attribute = params.nodeDames:GetAttributes();
	while attribute ~= nil do
		local name = attribute:GetName();
		local reserve = tonumber(name:sub(-1)) or 1;
		local value = attribute:GetValue();
		table.insert(tCoureurs.F, {Categ = value, Reserve = reserve, Nombre = 0, NbPoint = 0});
		local cmd = "Update Resultat Set Reserve = "..reserve.." Where Code_evenement = "..params.code_evenement.." And Sexe = 'F' and Categ In("..tCoureurs.F[#tCoureurs.F].Categ..")";
		base:Query(cmd);
		attribute = attribute:GetNext();
	end
	

	local attribute = params.nodeHommes:GetAttributes();
	while attribute ~= nil do
		local name = attribute:GetName();
		local reserve = tonumber(name:sub(-1)) or 1;
		local value = attribute:GetValue();
		table.insert(tCoureurs.M, {Categ = value, Reserve = reserve, Nombre = 0, NbPoint = 0});
		local cmd = "Update Resultat Set Reserve = "..reserve.." Where Code_evenement = "..params.code_evenement.." And Sexe = 'M' and Categ In("..tCoureurs.M[#tCoureurs.M].Categ..")";
		base:Query(cmd);
		attribute = attribute:GetNext();
	end
	local cmd = "Update Resultat Set Reserve = 20 Where Code_evenement = "..params.code_evenement.." And Sexe = 'F' And Reserve Is Null";
	base:Query(cmd);
	local cmd = "Update Resultat Set Reserve = 21 Where Code_evenement = "..params.code_evenement.." And Sexe = 'M' And Reserve Is Null";
	base:Query(cmd);
	local cmd = "Select * From Resultat Where Code_evenement = "..params.code_evenement.." Order By Reserve, Point";
	base:TableLoad(tResultat, cmd);
	tDraw = tResultat:Copy();
	tDraw:SetCounter('Reserve');
	for i = 1, #tCoureurs.F do
		tCoureurs.F[i].Nombre = tDraw:GetCounterValue('Reserve', tCoureurs.F[i].Reserve);
		
	end
	for i = 1, #tCoureurs.M do
		tCoureurs.M[i].Nombre = tDraw:GetCounterValue('Reserve', tCoureurs.M[i].Reserve);
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
		node_value = 'config'
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

	dlgConfig:GetWindowName('manche'):Clear();
	dlgConfig:GetWindowName('manche'):Append('Manche 1');
	dlgConfig:GetWindowName('manche'):Append('Manche 2');
	dlgConfig:GetWindowName('manche'):SetSelection(0);
	
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			params.code_manche = dlgConfig:GetWindowName('manche'):GetSelection() + 1;
			if params.code_manche == 1 then
				params.tExaequo = {};
				OnTirageManche1();				
				dlgConfig:EndModal(idButton.OK);
			else
				--OnTirageManche2();
			end
		end, btnSave); 
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:EndModal(idButton.KO);
		end, btnClose); 
	
	
	dlgConfig:Fit();
	dlgConfig:ShowModal();
	

	local cmd = 'Update Resultat Set Rang = NULL Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	if params.doc then params.doc:Delete(); end
	
	return true;
end
