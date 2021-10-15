-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');

function OnDecodeJson()
	params.debug = true;
	tResultat:OrderBy('Point');
	if not tTableTirage1 then
		tTableTirage1 = sqlTable.Create('_TableTirage1');
		tTableTirage1:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
		ReplaceTableEnvironnement(tTableTirage1, '_TableTirage1');
	end
	local cmd = 'Select * From Resultat_Info_Bibo Where Code_evenement = '..params.code_evenement;
	base:TableLoad(tResultat_Info_Bibo, cmd);
	tResultat_Info_Bibo:OrderBy('Groupe, Ligne');
	params.tableDossards1 = {};
	for i = 0, tResultat_Info_Bibo:GetNbRows() -1 do
		local jsontxt1 = tResultat_Info_Bibo:GetCell('Table1', i);
		local xTable1 = table.FromStringJSON(jsontxt1);
		table.insert(params.tableDossards1, xTable1.Table1[1].Col2);
		
		local jsontxt2 = tResultat_Info_Bibo:GetCell('Table2', i);
		local xTable2 = table.FromStringJSON(jsontxt2);
		local row = tTableTirage1:AddRow();
		local rang_fictif = xTable2.Table2[1].Col3 ;
		local dossard = xTable2.Table2[1].Col4;
		tTableTirage1:SetCell('Row', row, rang_fictif);
		if params.debug then
			adv.Alert('OnDecodeJson - rang_fictif = '..rang_fictif..' pour '..tResultat:GetCell('Nom', i)..', dossard : '..dossard);
		end
	end
end

function OnEncodeJson()
	-- tResultat_Copy contient tous les coureurs du BIBO
	local groupe = 1;
	local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	for row = 0, tTableTirage1:GetNbRows() -1 do
		local idx = row + 1;
		local tTable1 = {};
		local tTable2 = {};
		table.insert(tTable1, {Col1 = 'Dossard du rang fictif '..idx, Col2 = params.tableDossards1[idx]});
		local xTable1 = {Table1 = tTable1};
		local jsontxt1 = table.ToStringJSON(xTable1, false);

		local rang_fictif = tTableTirage1:GetCellInt('Row', row) + 1;
		local code_coureur = tResultat:GetCell('Code_coureur', row);
		local identite = tResultat:GetCell('Nom', row)..' '..tResultat:GetCell('Prenom', row);
		local pts = tResultat:GetCellDouble('Point', row);
		local dossard = params.tableDossards1[rang_fictif];
		if params.debug then
			adv.Alert('OnEncodeJson - row : '..row..' pour '..identite..'\t'..' : rang fictif =  '..rang_fictif..', dossard correspondant = '..tostring(dossard)..' code : '..code_coureur..', pts = '..pts);
		end
		local col1 = identite;
		local col2 = pts;
		local col3 = rang_fictif;
		local col4 = dossard;
		table.insert(tTable2, {Col1 = col1, Col2 = col2, Col3 = col3, Col4 = col4});
		local xTable2 = {Table2 = tTable2};
		local jsontxt2 = table.ToStringJSON(xTable2, false);
		local rowsql = tResultat_Info_Bibo:AddRow();
		tResultat_Info_Bibo:SetCell('Code_evenement', rowsql, params.code_evenement);
		tResultat_Info_Bibo:SetCell('Groupe', rowsql, groupe);
		tResultat_Info_Bibo:SetCell('Ligne', rowsql, idx);
		tResultat_Info_Bibo:SetCell('Table1', rowsql, jsontxt1);
		tResultat_Info_Bibo:SetCell('Table2', rowsql, jsontxt2);
		base:TableInsert(tResultat_Info_Bibo, rowsql)
	end
end

function OnPrint()
	if params.print_alone then
		OnDecodeJson();
	else
		OnEncodeJson();
	end
	report = wnd.LoadTemplateReportXML({
		xml = './process/dossardDoubleTirage.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'print',
		title = 'Edition du tirage au sort du BIBO',
		base = base,
		body = tTableTirage1,
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
		params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, Version = params.version}
	});
end

function GetBibo()
	resultat = {};
	params.pts15 = tResultat:GetCellDouble('Point', 14);
	resultat.pts15 = tResultat:GetCellDouble('Point', 14);
	params.nb_bibo = 0;
	params.nb_classes = 0;
	params.nb_non_classes = 0;
	params.first_row_non_classe = nil;
	params.last_row_bibo = 0;
	for row = 0, tResultat:GetNbRows() -1 do
		local point = tResultat:GetCellDouble('Point', row, -1);
		if point >= 0 then
			if point <= params.pts15 then
				params.nb_bibo = params.nb_bibo + 1;
				params.last_row_bibo = row;
			else
				params.nb_classes = params.nb_classes + 1;
			end
		else
			params.first_row_non_classe = params.first_row_non_classe or row;
			params.nb_non_classes = params.nb_non_classes + 1;
		end
	end	
	if params.debug == true then
		adv.Alert('GetBibo - params.last_row_bibo = '..params.last_row_bibo..', params.first_row_non_classe = '..params.first_row_non_classe);
	end
end

function CheckExaequo();
	params.row_exaequo = {};
	resultat = {};
	resultat.row_nepastirer = {};
	local rang_tirage = 0;
	local exaequo_ajoute = 0;
	local nb_exeaquo = 0;
	tExaequo = {};
	tNePasTirer = {};
	params.tExaequo = {};
	for i = 0, tResultat:GetNbRows() -1 do
		local point = tResultat:GetCellDouble('Point', i, -1);
		if point >= 0 then
			if nb_exeaquo == 0 then
				rang_tirage = rang_tirage + 1 + exaequo_ajoute;
				exaequo_ajoute = 0;
			else
				exaequo_ajoute = exaequo_ajoute + 1;
				nb_exeaquo = nb_exeaquo - 1;
			end
			if tResultat:GetCellDouble('Point', i+1) == point and rang_tirage > params.last_row_bibo then
				tNePasTirer[rang_tirage] = {};
				params.row_exaequo[rang_tirage] = {};
				nb_exeaquo = nb_exeaquo + 1;
				if params.tExaequo[#params.tExaequo] ~= rang_tirage then
					table.insert(params.tExaequo, rang_tirage);
				end
			end
			if tNePasTirer[rang_tirage] then
				tResultat:SetCell('Rang', i, rang_tirage);
			end
		end
	end
	if params.debug == true then
		for i = 1, #params.tExaequo do
			adv.Alert('params.tExaequo['..i..'] = '..params.tExaequo[i]);
		end
	end
end

function BuildTableTirage(row_first, row_last, rang_tirage, bib_first, shuffle);
	tResultat_Copy = tResultat:Copy();
	shuffle = shuffle or false;
	if rang_tirage then
		bib_first = rang_tirage;
		row_first = rang_tirage -1;
	end
	
	row_first = row_first or 0;
	row_last = row_last or tResultat:GetNbRows() -1;
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
	if params.debug then
		adv.Alert('row_first = '..row_first..', row_last = '..row_last..', rang_tirage = '..tostring(rang_tirage)..', bib_first = '..bib_first..', shuffle = '..tostring(shuffle));
	end
	-- row_first = 49, row_last = 78, rang_tirage = false, bib_first = 50	
	params.tableDossards1 = {};
	local bib = bib_first;
	for row = row_first, row_last do
		table.insert(params.tableDossards1, bib);
		bib = bib + 1;
	end
	if shuffle then
		params.tableDossards1 = Shuffle(params.tableDossards1, false);
	end
	for i = 1, #params.tableDossards1 do
		if params.debug then
			adv.Alert('lecture de params.tableDossards1 après shuffle : '..params.tableDossards1[i]);
		end
	end
	tTableTirage1:RemoveAllRows();
	local rang_fictif = 0;
	for row = 1, #params.tableDossards1 do
		local new_row1 = tTableTirage1:AddRow();
		tTableTirage1:SetCell('Row', new_row1, row-1);	-- setCell du rang fictif en lien avec  params.tableDossards1
	end
	if shuffle then
		tTableTirage1:OrderRandom('Prenom');
	end
	if params.debug then
		for row = 0, tTableTirage1:GetNbRows() -1 do
			adv.Alert('Lecture de tTableTirage1 après Random : '..', Row = '..tTableTirage1:GetCellInt('Row', row));
		end
	end
	
	for row = 0, tTableTirage1:GetNbRows() -1 do
		local row_coureur = row + row_first;
		local rang_fictif = tTableTirage1:GetCellInt('Row', row) + 1;
		local code_coureur = tResultat:GetCell('Code_coureur', row_coureur);
		local identite = tResultat:GetCell('Nom', row_coureur)..' '..tResultat:GetCell('Prenom', row_coureur);
		local dossard = params.tableDossards1[rang_fictif];
		if params.debug then
			adv.Alert('row_coureur : '..row_coureur..' pour '..identite..'\t'..' : rang fictif =  '..rang_fictif..', dossard correspondant = '..tostring(dossard)..' code : '..code_coureur..', dossard lu = '..tResultat_Copy:GetCellInt('Dossard', row));
		end
		if tResultat_Copy:GetCellInt('Dossard', row) == 0 then
			tResultat_Copy:SetCell('Dossard', row, dossard);
			tResultat:SetCell('Dossard', row_coureur, dossard);
			-- local cmd = 'Update Resultat Set Dossard = '..dossard;
			if rang_tirage then
				tResultat_Copy:SetCell('Rang', row, rang_tirage);
				tResultat:SetCell('Rang', row_coureur, rang_tirage);
				-- cmd = cmd..', Rang = '..rang_tirage;
			end
			-- cmd = cmd..' Where Code_evenement = '..params.code_evenement.." and Code_coureur = '"..code_coureur.."'";
			-- base:Query(cmd);
			-- if params.debug then
				-- adv.Alert('on fait : '..cmd);
			-- end
		end
	end
end

function main(params_c)
	if params_c == nil then
		return false;
	end
	params = params_c;
	params.debug = false;
	params.version = '2.1';
	params.code_evenement = params.code_evenement or -1;
	if params.code_evenement < 0 then
		return;
	end
	base = sqlBase.Clone();
	tResultat = base:GetTable('Resultat');
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	params.evenementNom = tEvenement:GetCell('Nom', 0);
	tEpreuve = base:GetTable('Epreuve');
	tResultat_Info_Bibo = base:GetTable('Resultat_Info_Bibo');
	if tResultat_Info_Bibo == nil then
		CreateTableResultat_Info_Bibo();
	end
	local cmd = 'Select * From Resultat_Info_Bibo Where Code_evenement = '..params.code_evenement;
	base:TableLoad(tResultat_Info_Bibo, cmd);
	tResultat_Info_Bibo:OrderBy('Groupe, Ligne');
	params.print_alone = nil;
	if tResultat_Info_Bibo:GetNbRows() > 0 then
		local msg = "Le double tirage au sort du BIBO  déjà été réalisé.\n"..
					"Voulez vous rééditer la feuille du tirage fait précédemment?\n"..
					"ATTENTION, si vous cliquez sur Non, tous les dossards seront alors effacés et remplacé par ceux du nouveau tirage.";
		local reponse =  app.GetAuiFrame():MessageBox(msg,
						"Lancer le tirage", 
						msgBoxStyle.YES+msgBoxStyle.NO+msgBoxStyle.CANCEL+msgBoxStyle.CANCEL_DEFAULT+msgBoxStyle.ICON_WARNING
						);
		if reponse == msgBoxStyle.CANCEL then
			return ;
		elseif reponse == msgBoxStyle.YES then
			params.print_alone = true;
		end
	end
	if not params.print_alone then
		tResultat:OrderBy('Point');
		GetBibo();
		local cmd = 'Update Resultat Set Dossard = Null, Rang = NULL Where Code_evenement = '..params.code_evenement;
		base:Query(cmd);
		local cmd = 'Update Resultat Set Rang = '..(params.first_row_non_classe + 1)..' Where Code_evenement = '..params.code_evenement..' And Point Is Null';
		base:Query(cmd);
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
		tResultat:OrderBy('Point');
		math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
		math.random(); math.random(); math.random();

		tTableTirage1 = sqlTable.Create('_TableTirage1');
		tTableTirage1:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
		ReplaceTableEnvironnement(tTableTirage1, '_TableTirage1');
		tResultat_Copy = tResultat:Copy();
		ReplaceTableEnvironnement(tResultat_Copy, '_Resultat_Copy');
		CheckExaequo();
		-- valeurs définies apres GetBibo
		-- params.pts15 
		-- resultat.pts15 
		-- params.nb_bibo
		-- params.nb_classes
		-- params.nb_non_classes 
		-- params.first_row_non_classe;
		-- function BuildTableTirage(row_first, row_last, rang_tirage, bib_first, shuffle);
		for i = 1, #params.tExaequo do
			if i == 1 and params.debug then
				adv.Alert('\n!! tirage des exaequos !!');
			end
			if params.tExaequo[i] < tResultat:GetNbRows() then
				BuildTableTirage(params.tExaequo[i]+1, nil, params.tExaequo[i] ,nil, false) -- tirage des exaequo ayants des points
			end
		end
		base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
		tResultat:OrderBy('Point');
		for row = params.nb_bibo, params.first_row_non_classe -1 do
			if tResultat:GetCellInt('Dossard', row) == 0 then
				local code_coureur = tResultat:GetCell('Code_coureur', row);
				local dossard = row + 1;
				tResultat:SetCell('Dossard', row, dossard) ;
			end
		end
		base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
		tResultat:OrderBy('Point');
		if params.debug then
			adv.Alert('\n!! tirage des non classes');
		end
		if params.first_row_non_classe < tResultat:GetNbRows() -2 then
	--      BuildTableTirage(row_first, row_last, rang_tirage, bib_first, shuffle);
			BuildTableTirage(params.first_row_non_classe, params.nb_non_classes -1, params.first_row_non_classe + 1, params.first_row_non_classe + 1, true) -- tirage des sans points
		end
		base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
		tResultat:OrderBy('Point');
		if params.debug then
			adv.Alert('\n!! tirage du bibo');
		end
--      BuildTableTirage(row_first, row_last, rang_tirage, bib_first, shuffle);
		BuildTableTirage(0, params.nb_bibo -1, nil, 1, true) -- tirage du bibo
	end
	base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
	local cmd = 'Update Resultat Set Rang = NULL Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	-- base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	-- tResultat:OrderBy('Point');
	OnPrint();
end




