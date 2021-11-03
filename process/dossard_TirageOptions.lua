-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function GetMenuName()
	return "Tirage des dossards à la mêlée avec options";
end

function OnTirage(clef1, option1, option2)
	local cmd = 'Update Resultat Set Dossard = Null, Reserve = Null Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	cmd = 'Delete From Resultat_Manche Where Code_evenement = '..params.code_evenement..' And Code_manche > 1';
	base:Query(cmd);
	local col = nil;
	if string.find(clef1, '1') then
		tRaceGroupe = tRaceSexe;
		col = 'Sexe';
	elseif string.find(clef1, '2') then
		tRaceGroupe = tRaceSexeCateg;
		col = 'Categ';
	elseif string.find(clef1, '3') then
		tRaceGroupe = tRaceSexeAn;
		col = 'An';
	end
	tGroupe_tirage = {};
	local groupe = 0;
	tGroupes = {};
	for i = 0, tRaceGroupe:GetNbRows() -1 do
		groupe = groupe + 1;
		table.insert(tGroupes, groupe);
		local clef = 'F-'..tRaceGroupe:GetCell(col, i);
		tGroupe_tirage[clef] = groupe;
		groupe = groupe + 1;
		table.insert(tGroupes, groupe);
		clef = 'M-'..tRaceGroupe:GetCell(col, i);
		tGroupe_tirage[clef] = groupe;
	end
	-- dlgConfig:GetWindowName('clef1'):Append('1. Par Sexe');
	-- dlgConfig:GetWindowName('clef1'):Append('2. Par Sexe et par Catégorie');
	-- dlgConfig:GetWindowName('clef1'):Append('3. Par Sexe et par Année');
	
	-- dlgConfig:GetWindowName('option1'):Append('1. Tirage pour la manche 1 seulement');
	-- dlgConfig:GetWindowName('option1'):Append('2. Tirage pour les manches 1 et 2');

	-- dlgConfig:GetWindowName('option2'):Append('1. Sans objet');
	-- dlgConfig:GetWindowName('option2'):Append('2. Inversion des dossards dans les groupes de tirage');

	local strClef = nil;
	for i = 0, tResultat:GetNbRows() -1 do
		local sexe = tResultat:GetCell('Sexe', i);
		local an = tResultat:GetCell('An', i);
		local categ = tResultat:GetCell('Categ', i);
		if string.find(clef1, '1') then
			strClef = sexe..'-'..sexe;
		elseif string.find(clef1, '2') then
			strClef = sexe..'-'..categ;
		elseif string.find(clef1, '3') then
			strClef = sexe..'-'..an;
		end
		if tGroupe_tirage[strClef] then
			tResultat:SetCell('Reserve', i, tGroupe_tirage[strClef])
		end		
	end
	base:TableBulkUpdate(tResultat,'Reserve', 'Resultat');
	tResultat:OrderBy('Reserve');
	local dossard = 0;
	for i = 1, #tGroupes do
		local filtre = '$(Reserve):In('..i..')';
		tResultat_Copy = tResultat:Copy();
		tResultat_Copy:Filter(filtre, true);
		tResultat_Copy:OrderRandom('Reserve');
		for row = 0, tResultat_Copy:GetNbRows() -1 do
			dossard = dossard + 1;
			tResultat_Copy:SetCell('Dossard', row, dossard); 
		end
		base:TableBulkUpdate(tResultat_Copy, 'Dossard', 'Resultat');
	end
	if string.find(option1, '2.') then
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement..' Order By Dossard');
		tReserve = base:TableLoad('Select Distinct Reserve From Resultat Where Code_evenement = '..params.code_evenement..' Order By Reserve');
		for j = 0, tReserve:GetNbRows() -1 do
			local reserve = tReserve:GetCellInt('Reserve', j)
			local filtre = '$(Reserve):In('..reserve..')';
			tResultat_Copy = tResultat:Copy();
			tResultat_Copy:Filter(filtre, true);
			local rang = tResultat_Copy:GetCellInt('Dossard', tResultat_Copy:GetNbRows()-1);
			if string.find(option2, '1.') then
				rang = tResultat_Copy:GetCellInt('Dossard', 0);
			end
			for i = 0, tResultat_Copy:GetNbRows() -1 do
				local code_coureur = tResultat_Copy:GetCell('Code_coureur', i);
				base:TableLoad(tResultat_Manche, 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement.." And Code_manche = 2 And Code_coureur = '"..code_coureur.."'");
				local row = nil;
				local addrow = false;
				if tResultat_Manche:GetNbRows() == 0 then
					row = tResultat_Manche:AddRow();
					addrow = true;
				else
					row = 0;
				end
				tResultat_Manche:SetCell('Code_evenement', row, params.code_evenement);
				tResultat_Manche:SetCell('Code_manche', row, 2);
				tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
				tResultat_Manche:SetCell('Rang', row, rang);
				if addrow == true then
					base:TableInsert(tResultat_Manche, row);
				else
					base:TableUpdate(tResultat_Manche, row, 'Rang');
				end
				if string.find(option2, '2.') then
					rang = rang - 1;
				else
					rang = rang + 1;
				end
			end
		end
	end
end

function main(params_c)
	params = {};
	params.code_evenement = params_c.code_evenement;
	if params.code_evenement < 0 then
		return;
	end
	params.origine = params.origine or 'scenario';	
	params.width = display:GetSize().width / 2;
	params.height = display:GetSize().height / 2;
	params.x = (display:GetSize().width - params.width) / 2;
	params.y = 200;
	params.version = "1.0";
	base = base or sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	tResultat = base:GetTable('Resultat');
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tResultat_Manche = base:GetTable('Resultat_Manche');
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	tCategorie = base:GetTable('Categorie');
	tEpreuve_Alpine_Manche = base:GetTable('Epreuve_Alpine_Manche');
	base:TableLoad(tEpreuve_Alpine_Manche, 'Select * From Epreuve_Alpine_Manche Where Code_evenement = '..params.code_evenement);
	
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
	
	local cmd = "Select Distinct Sexe From Resultat Where Code_evenement = "..params.code_evenement..' Order By Sexe';
	tRaceSexe = base:TableLoad(cmd);
	local cmd = "Select Distinct r.An, c.Code, c.Ordre From Resultat r, Categorie c Where r.Code_evenement = "..params.code_evenement.." AND r.Categ = c.Code And c.Code_activite = '"..params.code_activite.."' AND c.Code_entite = '"..params.code_entite.."' AND c.Code_saison = '"..params.code_saison.."' AND c.Code_grille = '"..params.code_grille_categorie.."' Order By An DESC";
	tRaceSexeAn = base:TableLoad(cmd);
	local cmd = "Select Distinct r.Categ, c.Code, c.Ordre From Resultat r, Categorie c Where r.Code_evenement = "..params.code_evenement.." AND r.Categ = c.Code And c.Code_activite = '"..params.code_activite.."' AND c.Code_entite = '"..params.code_entite.."' AND c.Code_saison = '"..params.code_saison.."' AND c.Code_grille = '"..params.code_grille_categorie.."' Order By Ordre";
	tRaceSexeCateg = base:TableLoad(cmd);
	
	params.codex = tEvenement:GetCell("Codex", 0);
	-- Ouverture Document XML 
	local XML = "./process/dossard_TirageOptions.xml";
	params.doc = xmlDocument.Create(XML);
	params.nodeConfig = params.doc:FindFirst('root/config');
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
		discipline = params.discipline;
		node_value = 'config' 
	});

	-- Toolbar Principale ...
	local tbconfig = dlgConfig:GetWindowName('tbconfig');
	tbconfig:AddStretchableSpace();
	local btnSave = tbconfig:AddTool("Lancer le tirage", "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	local message = app.GetAuiMessage();
	
	dlgConfig:GetWindowName('clef1'):Clear();
	dlgConfig:GetWindowName('clef1'):Append('1. Par Sexe');
	dlgConfig:GetWindowName('clef1'):Append('2. Par Sexe et par Catégorie');
	dlgConfig:GetWindowName('clef1'):Append('3. Par Sexe et par Année');
	dlgConfig:GetWindowName('clef1'):SetSelection(0);
		
	dlgConfig:GetWindowName('option1'):Clear();
	dlgConfig:GetWindowName('option1'):Append('1. Tirage pour la manche 1 seulement');
	dlgConfig:GetWindowName('option1'):Append('2. Tirage pour les manches 1 et 2');
	dlgConfig:GetWindowName('option1'):SetSelection(0);

	dlgConfig:GetWindowName('option2'):Clear();
	dlgConfig:GetWindowName('option2'):Append("1. Pas d'inversion des dossards dans les groupes de tirage");
	dlgConfig:GetWindowName('option2'):Append('2. Inversion des dossards dans les groupes de tirage');
	dlgConfig:GetWindowName('option2'):SetSelection(0);

	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			clef1 = dlgConfig:GetWindowName('clef1'):GetValue();
			option1 = dlgConfig:GetWindowName('option1'):GetValue();
			option2 = dlgConfig:GetWindowName('option2'):GetValue();
			params.nodeConfig:ChangeAttribute('clef1', clef1);
			params.nodeConfig:ChangeAttribute('option1', option1);
			params.nodeConfig:ChangeAttribute('option2', option2);
			params.doc:SaveFile();
			dlgConfig:EndModal(idButton.OK);
		end, btnSave); 
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:EndModal(idButton.CANCEL);
		 end,  btnClose);

	dlgConfig:Fit();
	if dlgConfig:ShowModal() == idButton.OK then
		OnTirage(clef1, option1, option2);
	end
	return true;
end




