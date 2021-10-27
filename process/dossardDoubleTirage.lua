-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');

function OnPrintDoubleTirage(groupe)
	if params.print_alone then
		params.tableDossards1, params.tableDossards2 = OnDecodeJsonBibo(params.code_evenement, groupe);
	else
		OnEncodeJsonBibo(params.code_evenement, groupe);
		params.tableDossards1, params.tableDossards2 = OnDecodeJsonBibo(params.code_evenement, groupe);
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
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 1, Version = params.version, NbGroupe1 = 0, NC = 1}
		});
	elseif groupe == 2 then
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
			params = {Nom = params.evenementNom, tableDossards1 = params.tableDossards1, tableDossards2 = params.tableDossards2, Draw = 2, Version = params.version, NbGroupe1 = params.nb_groupe_1, NC = 1}
		});
	end
end

function GetBibo()
	params.pts_7 = tResultat:GetCellDouble('Point', 6);
	params.pts_15 = tResultat:GetCellDouble('Point', 14);
	params.last_row_bibo = nil; params.row_pts7 = nil;

	params.nb_bibo = 0;
	params.nb_classes = 0;
	params.nb_non_classes = 0;
	params.first_row_non_classe = nil;
	for row = 0, tResultat:GetNbRows() -1 do
		local point = tResultat:GetCellDouble('Point', row, -1);
		if point == params.pts_15 then
			if not params.last_row_bibo then
				params.last_row_bibo = row;
			end
		end
		if point == params.pts_7 then
			if not params.row_pts7 then
				params.row_pts7 = row;
			end
		end
		if point >= 0 then
			if point <= params.pts_15 then
				params.nb_bibo = params.nb_bibo + 1;
			else
				params.nb_classes = params.nb_classes + 1;
			end
		else
			if not params.first_row_non_classe then
				params.first_row_non_classe = row;
			end
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
	tNePasTirer = {};
	params.tExaequo = {};
	for i = 0, tResultat:GetNbRows() -1 do
		local point = tResultat:GetCellDouble('Point', i, -1);
		if point >= 0 then
			if nb_exeaquo == 0 then
				rang_tirage = rang_tirage + 1 + exaequo_ajoute;
				tResultat:SetCell('Rang', i, rang_tirage);
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
	base:TableBulkUpdate(tResultat, 'Rang', 'Resultat');
	if params.debug == true then
		for i = 1, #params.tExaequo do
			adv.Alert('params.tExaequo['..i..'] = '..params.tExaequo[i]);
		end
	end
end

function BuildTableTirageSplit(bib_first, last_row_groupe_bibo)
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
		adv.Alert('BuildTableTirage !! - row_first = '..row_first..', row_last = '..row_last..', rang_tirage = '..tostring(rang_tirage)..', bib_first = '..bib_first..', shuffle = '..tostring(shuffle));
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
			adv.Alert('BuildTableTirage !! - lecture de params.tableDossards1 après shuffle : '..params.tableDossards1[i]);
		end
	end
	tTableTirage1:RemoveAllRows();
	local rang_fictif = 0;
	for row = 1, #params.tableDossards1 do
		local new_row1 = tTableTirage1:AddRow();
		tTableTirage1:SetCell('Row', new_row1, row);	-- setCell du rang fictif en lien avec  params.tableDossards1
	end
	if shuffle then
		tTableTirage1:OrderRandom('Prenom');
	end
	if params.debug then
		for row = 0, tTableTirage1:GetNbRows() -1 do
			adv.Alert('BuildTableTirage !! - Lecture de tTableTirage1 après Random : '..', Row = '..tTableTirage1:GetCellInt('Row', row));
		end
	end
	
	for row = 0, tTableTirage1:GetNbRows() -1 do
		local row_coureur = row + row_first;
		local rang_fictif = tTableTirage1:GetCellInt('Row', row);
		local code_coureur = tResultat:GetCell('Code_coureur', row_coureur);
		local identite = tResultat:GetCell('Nom', row_coureur)..' '..tResultat:GetCell('Prenom', row_coureur);
		local dossard = params.tableDossards1[rang_fictif];
		if params.debug then
			adv.Alert('BuildTableTirage !! - row_coureur : '..row_coureur..' pour '..identite..'\t'..' : rang fictif =  '..rang_fictif..', dossard correspondant = '..tostring(dossard)..' code : '..code_coureur..', dossard lu = '..tResultat_Copy:GetCellInt('Dossard', row));
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
	params.version = '2.3';
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
	base.TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	tResultat_Info_Bibo = base:GetTable('Resultat_Info_Bibo');
	if tResultat_Info_Bibo == nil then
		CreateTableResultat_Info_Bibo();
	end
	tTableTirage1 = sqlTable.Create('_TableTirage1');
	tTableTirage1:AddColumn({ name = 'Row', type = sqlType.LONG, style = sqlStyle.NULL });
	ReplaceTableEnvironnement(tTableTirage1, '_TableTirage1');
	local cmd = 'Select * From Resultat_Info_Bibo Where Code_evenement = '..params.code_evenement;
	base:TableLoad(tResultat_Info_Bibo, cmd);
	tResultat_Info_Bibo:OrderBy('Groupe, Ligne');
	params.print_alone = nil;
	params.skip_question = false;
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
			local msg = "Le double tirage au sort des dossards a déjà été réalisé.\n"..
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
	end
	bolSplitBibo = false;
	tResultat:OrderBy('Point');
	params.pts_7 = tResultat:GetCellDouble('Point', 6);
	params.pts_15 = tResultat:GetCellDouble('Point', 14);
	params.last_row_bibo = nil; params.row_pts7 = nil;
	GetBibo();
	if not params.print_alone then
		local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..params.code_evenement;
		base:Query(cmd);
		cmd = 'Update Resultat Set Dossard = Null, Rang = NULL, Critere = Null Where Code_evenement = '..params.code_evenement;
		base:Query(cmd);
		if params.first_row_non_classe then
			local cmd = 'Update Resultat Set Rang = '..(params.first_row_non_classe + 1)..' Where Code_evenement = '..params.code_evenement..' And Point Is Null';
			base:Query(cmd);
		end
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
		tResultat:OrderBy('Point');

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
		-- base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
		-- base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
		
		if params.first_row_non_classe then
			for row = params.nb_bibo, params.first_row_non_classe -1 do
				if tResultat:GetCellInt('Dossard', row) == 0 then
					local code_coureur = tResultat:GetCell('Code_coureur', row);
					local dossard = row + 1;
					tResultat:SetCell('Dossard', row, dossard) ;
				end
			end
			base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
		end
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
		tResultat:OrderBy('Point');
		if params.debug then
			adv.Alert('\n!! tirage des non classes, first_row_non_classe = '..params.first_row_non_classe);
		end
		if params.first_row_non_classe then
			if params.first_row_non_classe < tResultat:GetNbRows() -1 then
		--      BuildTableTirage(row_first, row_last, rang_tirage, bib_first, shuffle);
				BuildTableTirage(params.first_row_non_classe, nil, params.first_row_non_classe + 1, params.first_row_non_classe + 1, true) -- tirage des sans points
			else
				tResultat:SetCell('Dossard', tResultat:GetNbRows()-1, tResultat:GetNbRows())
			end
			base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
		end
		if params.debug then
			adv.Alert('\n!! tirage du bibo, params.nb_bibo = '..params.nb_bibo);
		end
--      BuildTableTirage(row_first, row_last, rang_tirage, bib_first, shuffle);
		if not bolSplitBibo then
			BuildTableTirage(0, params.nb_bibo -1, nil, 1, true) -- tirage du bibo
		end
	end
	base:TableBulkUpdate(tResultat, 'Dossard, Rang', 'Resultat');
	local cmd = 'Update Resultat Set Rang = NULL Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	if tEpreuve:GetCell('Code_entite', 0) == 'FIS' and tEpreuve:GetCell('Code_niveau', 0):In('EC', 'NC') and tEpreuve:GetCell('Code_discipline', 0):In('SL','GS') then
		bolSplitBibo = true;
	end
	if not bolSplitBibo then
		if not params.print_alone then
			tResultat:OrderBy('Point');
			tDrawG6 = tResultat:Copy();
			ReplaceTableEnvironnement(tDrawG6, 'DrawG6');
			for i = tDrawG6:GetNbRows() -1, 0, -1 do
				local pts = tDrawG6:GetCellDouble('Point', i, -1);
				if pts < 0 or pts > params.pts_15 then
					tDrawG6:RemoveRowAt(i);
				end
			end
		end
		OnPrintDoubleTirage(1);
	else
		if not params.print_alone then
			if params.debug then
				adv.Alert('\n!! tirage du bibo : slpil, params.row_pts7 = '..params.row_pts7..', params.last_row_bibo = '..params.last_row_bibo);
			end
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




