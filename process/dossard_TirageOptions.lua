-- Calcul d'un temps manuel (avec 10 avant ou avec d�calage)
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function GetMenuName()
	return "Tirage des dossards ou des rangs de d�part avec options de tirage";
end

function GetActivite()
	return "ALP,TM";
end

function GetBibo(bibo)
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
		params = {Niveau = params.code_niveau}
	});

	-- Toolbar Principale ...
	local tbbibo = dlgBibo:GetWindowName('tbbibo');
	tbbibo:AddStretchableSpace();
	local btnSave = tbbibo:AddTool("Valider", "./res/vpe32x32_save.png");
	tbbibo:AddStretchableSpace();
	tbbibo:Realize();
	
	dlgBibo:GetWindowName('bibo'):SetValue(bibo);
	dlgBibo:GetWindowName('dossard'):SetValue(1);
	
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

function ValideOption1(clef1, option1, option2)
	if string.find(option1, '1%.') or string.find(option1, '4%.') or string.find(option1, '5%.') or string.find(option1, '6%.') then
		dlgConfig:GetWindowName('clef1'):SetSelection(3);
		clef1 = dlgConfig:GetWindowName('clef1'):GetValue();
		if string.find(option1, '4%.') then
			dlgConfig:GetWindowName('course2'):SetValue('');
			dlgConfig:GetWindowName('course2_nom'):SetValue('');
			if not string.find(option2, '4%.') and not string.find(option2, '5%.')then
				dlgConfig:GetWindowName('option2'):SetSelection(3);
				option2 = dlgConfig:GetWindowName('option2'):GetValue();
			end
		end
	end
	if string.find(option1, '1%.') or string.find(option1, '3%.') then
		dlgConfig:GetWindowName('clef1'):SetSelection(3);
		dlgConfig:GetWindowName('clef1'):SetSelection(3);
		dlgConfig:GetWindowName('option2'):SetSelection(2);
		option2 = dlgConfig:GetWindowName('option2'):GetValue();
	end
end

	-- dlgConfig:GetWindowName('clef1'):Append('1. Par Sexe');
	-- dlgConfig:GetWindowName('clef1'):Append('2. Par Sexe et par Cat�gorie');
	-- dlgConfig:GetWindowName('clef1'):Append('3. Par Sexe et par Ann�e');
	-- dlgConfig:GetWindowName('clef1'):Append('4. Sans objet');
		
	-- dlgConfig:GetWindowName('option1'):Append('1. Tirage pour la manche 1 avec BIBO particulier');
	-- dlgConfig:GetWindowName('option1'):Append('2. Tirage pour les manches 1 et 2');
	-- dlgConfig:GetWindowName('option1'):Append('3. Tirage pour la manche 2 (ABD DSQ ordre inverse)');
	-- dlgConfig:GetWindowName('option1'):Append('4. Tirage des 3 manches par tiers tournants');
	-- dlgConfig:GetWindowName('option1'):Append("5. Coupes d'Argent et Nationales jeunes : Tirage pour des courses de 4 manches");
	-- dlgConfig:GetWindowName('option1'):Append("6. Coupes d'Argent et Nationales jeunes : Tirage pour des courses de 2 manches");

	-- dlgConfig:GetWindowName('option2'):Append("1. Pas d'inversion des dossards dans les groupes de tirage");
	-- dlgConfig:GetWindowName('option2'):Append('2. Inversion des dossards dans les groupes de tirage');
	-- dlgConfig:GetWindowName('option2'):Append('3. Gestion du BIBO');
	-- dlgConfig:GetWindowName('option2'):Append('4. Tirage au sort dans les tiers tournants');
	-- dlgConfig:GetWindowName('option2'):Append('5. Sans objet');
function ValideOption2(clef1, option1, option2)
	if string.find(option1, '4%.') then
		if string.find(option2, '4%.') or string.find(option2, '5%.') then 
			return;
		end
	end
	if string.find(clef1, '1%.') or string.find(clef1, '2%.') or string.find(clef1, '3%.') then
		if string.find(option2, '4%.') then 
			dlgConfig:GetWindowName('option2'):SetSelection(1);
			option2 = dlgConfig:GetWindowName('option2'):GetValue();
		end
	end
end

function OnTirageManche1()
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tResultat:OrderBy('Rang, Dossard');
	local dossard1 = tResultat:GetCellInt('Dossard', 0);
	if dossard1 > 0 then
		local msg = "Les dossards de la manche 1 ont d�j� �t� tir�s.\nVoulez-vous les remplacer ?";
		if app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!"
			, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
			return;
		end
	end
	local cmd = 'Update Resultat Set Dossard = Null, Rang = Null, Reserve = Null Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tResultat:OrderBy('Point');
	if string.find(option2, '3%.') then
		params.bibo, params.dossard = GetBibo(15);
	end
	params.bibo = params.bibo or -1;
	params.pts_bibo = -1;
	params.dossard = params.dossard or 1;
	local tSexe = {'T'};
	if string.find(clef1, '1%.') then		-- par sexe
		tSexe = {'F', 'M'};
	end
	for idx = 1, #tSexe do
		local sexe_encours = tSexe[idx];
		local Resultat_Copy = tResultat:Copy();
		local filtre = "$(Sexe):In('F', 'M', 'T')";
		if sexe_encours == 'F' then
			filtre = "$(Sexe):In('F')";
		elseif sexe_encours == 'M' then
			filtre = "$(Sexe):In('M')";
		else
			filtre = "$(Sexe):In('F', 'M')";
		end
		Resultat_Copy:Filter(filtre, true);
		if params.bibo > 0 then
			params.pts_bibo = Resultat_Copy:GetCellDouble('Point', params.bibo -1);
		end
		for i = 0, Resultat_Copy:GetNbRows() -1 do
			local reserve = 3;
			local point = Resultat_Copy:GetCellDouble('Point', i, -1);
			if point >= 0 then
				if params.pts_bibo > 0 then
					if point <= params.pts_bibo then
						reserve = 1;
					elseif point > 0 then
						reserve = 2;
					end
				end
			end
			Resultat_Copy:SetCell('Reserve', i, reserve);
		end
		base:TableBulkUpdate(Resultat_Copy,'Reserve', 'Resultat');
		for reserve = 1, 3 do
			tResultat_Filtre = Resultat_Copy:Copy();
			local filtre = '$(Reserve):In('..reserve..')';
			tResultat_Filtre:Filter(filtre, true);
			if reserve == 1 or reserve == 3 then
				tResultat_Filtre:OrderRandom();
			elseif reserve == 2 then
				tResultat_Filtre:OrderBy('Point');
			end
			for i = 0, tResultat_Filtre:GetNbRows() -1 do
				tResultat_Filtre:SetCell('Dossard', i, params.dossard);
				params.dossard = params.dossard + 1;
			end
			base:TableBulkUpdate(tResultat_Filtre, 'Dossard', 'Resultat');
		end
	end
	
end
function OnTirageManche2Special()
	-- on supprime les records qui pourraient tra�ner chez ceux qui ont test� les premi�res versions du script
	cmd = 'Delete From Resultat_Manche Where Code_evenement = '..params.code_evenement..' And Code_manche = 2 And Tps_chrono = -600';
	base:Query(cmd);
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tCoureur = {};
	for i = 0, tResultat:GetNbRows() -1 do
		local code_coureur = tResultat:GetCell('Code_coureur', i);
		tCoureur[code_coureur] = {};
		tCoureur[code_coureur].Dossard = tResultat:GetCellInt('Dossard', i);
	end
	base:TableLoad(tResultat_Manche, 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement..' And Code_manche = 2');
	tResultat_Manche:OrderBy('Rang DESC');
	local rangx = tResultat_Manche:GetCellInt('Rang', 0);
	if rangx > 0 then
		local msg = "Les rangs de d�part de la manche 2 ont d�j� �t� tir�s.\nVoulez-vous les remplacer ?";
		if app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!"
			, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
			return;
		end
	end
	-- faire les groupes pour la manche 1
	if string.find(option2, '3%.') then
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

	-- la colonne Reserve de la manche 1 est fix�e
	cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement..' And Code_manche = 2';
	base:TableLoad(tResultat_Manche, cmd);
	local rang = 0;
	for reserve = 1, 3 do
		tTable_Boucle = tResultat_Manche1:Copy();
		local filtre = '$(Reserve):In('..reserve..')';
		tTable_Boucle:Filter(filtre, true);
		if reserve == 1 then
			tTable_Boucle:OrderBy('Tps_chrono DESC');
		elseif reserve == 2 then
			tTable_Boucle:OrderBy('Tps_chrono');
		else
			tTable_Boucle:OrderBy('Dossard DESC');
		end
		for i = 0, tTable_Boucle:GetNbRows() -1 do
			local code_coureur = tTable_Boucle:GetCell('Code_coureur', i);
			rang = rang + 1;
			local row = 0;
			local trouve = false;
			local r = tResultat_Manche:GetIndexRow('Code_coureur', code_coureur);
			if r and r >= 0 then
				row = r;
				trouve = true;
			else
				row = tResultat_Manche:AddRow();
			end
			tResultat_Manche:SetCell('Code_evenement', row, params.code_evenement);
			tResultat_Manche:SetCell('Code_manche', row, 2);
			tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
			tResultat_Manche:SetCell('Reserve', row, reserve);
			tResultat_Manche:SetCell('Rang', row, rang);
			if trouve then
				base:TableUpdate(tResultat_Manche, row);
			else
				base:TableInsert(tResultat_Manche, row);
			end
		end
	end
	cmd = 'Update Resultat_Manche Set Reserve = Null  Where Code_evenement = '..params.code_evenement..' And Code_manche = 1';
	base:Query(cmd);
end


function OnTirageParTiersMixte();
	-- on fixe les dossards
	-- Ordre des groupes = manche 1 : 1, 2, 3,  manche 2 : 2, 3, 1,  manche 3 : 3, 1, 2 par sexe le cas �ch�ant.
	if tEpreuve:GetCellInt('Nombre_de_manche', 0) ~= 3 then
		local msg = "Cette course n'est pas param�tr�e pour 3 manches";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
		return;
	end
	SetDossardMixte();
	local tables_sexe = {};
	if tResultat_Filles:GetNbRows() > 0 then
		tResultat_Filles:OrderBy('Dossard')
		table.insert(tables_sexe, {Sexe = 'F', Table = tResultat_Filles});
	end
	if tResultat_Garcons:GetNbRows() > 0 then
		tResultat_Garcons:OrderBy('Dossard')
		table.insert(tables_sexe, {Sexe = 'M', Table = tResultat_Garcons});
	end
	local max_row_g1_filles = math.ceil(tResultat_Filles:GetNbRows() / 3);
	local max_row_g2_filles = tResultat_Filles:GetNbRows() - max_row_g1_filles;
	local max_row_g1_garcons = math.ceil(tResultat_Garcons:GetNbRows() / 3);
	local max_row_g2_garcons = tResultat_Garcons:GetNbRows() - max_row_g1_garcons;
	for i = tResultat_Filles:GetNbRows() - 1, 0, -1 do
		if i >= max_row_g2_filles then
			tResultat_Filles:SetCell('Reserve', i, 3);
		elseif i >= max_row_g1_filles then
			tResultat_Filles:SetCell('Reserve', i, 2);
		else
			tResultat_Filles:SetCell('Reserve', i, 1);
		end
	end
	base:TableBulkUpdate(tResultat_Filles,'Reserve', 'Resultat');
	for i = tResultat_Garcons:GetNbRows() - 1, 0, -1 do
		if i >= max_row_g2_garcons then
			tResultat_Garcons:SetCell('Reserve', i, 3);
		elseif i >= max_row_g1_garcons then
			tResultat_Garcons:SetCell('Reserve', i, 2);
		else
			tResultat_Garcons:SetCell('Reserve', i, 1);
		end
	end
	base:TableBulkUpdate(tResultat_Garcons,'Reserve', 'Resultat');
	
	for idx = 1, #tables_sexe do
		local table_resultat = tables_sexe[idx].Table;
		local sexe = tables_sexe[idx].Sexe;
		local Counter_Reserve = table_resultat:SetCounter('Reserve');
		local tCounter_Reserve = table_resultat:GetCounter('Reserve');
		NbG1 = tCounter_Reserve:GetCellInt('_count_', 0);
		NbG2 = tCounter_Reserve:GetCellInt('_count_', 1);
		NbG3 = tCounter_Reserve:GetCellInt('_count_', 2);
		local tReserve = {};
		table.insert(tReserve, {Manche = 1, Ordre = {1,2,3}});
		table.insert(tReserve, {Manche = 2, Ordre = {3,1,2}});
		table.insert(tReserve, {Manche = 3, Ordre = {2,3,1}});
		
		for manche = 2, 3 do
			local tOrdre = tReserve[manche].Ordre;	-- si manche = 2, tOrdre = {3,1,2}, tOrdre[2] = 1
			rang = 0;
			if sexe == 'M' then
				rang = tResultat_Filles:GetNbRows();
			end
			for ordre = 1, 3 do
				local reserve = tOrdre[ordre];
				local filtre = '$(Reserve):In('..reserve..')';
				table_resultat_copy = table_resultat:Copy();
				table_resultat_copy:Filter(filtre, true);
				if string.find(option2, '4%.') then
					table_resultat_copy:OrderRandom();
				else
					table_resultat_copy:OrderBy('Dossard');
				end	
				local row = nil;
				local addrow = false;
				for i = 0, table_resultat_copy:GetNbRows() -1 do
					rang = rang + 1;
					local code_coureur = table_resultat_copy:GetCell('Code_coureur', i);
					local reserve = table_resultat_copy:GetCellInt('Reserve', i);
					local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement.." And Code_manche = "..manche.." And Code_coureur = '"..code_coureur.."'";
					base:TableLoad(tResultat_Manche, cmd);
					if tResultat_Manche:GetNbRows() == 0 then
						addrow = true;
						row = tResultat_Manche:AddRow();
					else
						row = 0;
					end
					tResultat_Manche:SetCell('Code_evenement', row, params.code_evenement);
					tResultat_Manche:SetCell('Code_manche', row, manche);
					tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
					tResultat_Manche:SetCell('Rang', row, rang);
					tResultat_Manche:SetCell('Reserve', row, reserve);
					if addrow == true then
						base:TableInsert(tResultat_Manche, row);
					else
						base:TableUpdate(tResultat_Manche, row);
					end
				end
			end
		end
	end
end

function OnTirageParTiers();
	-- on fixe les dossards
	-- Ordre des groupes = manche 1 : 1, 2, 3,  manche 2 : 2, 3, 1,  manche 3 : 3, 1, 2 par sexe le cas �ch�ant.
	if tEpreuve:GetCellInt('Nombre_de_manche', 0) ~= 3 then
		local msg = "Cette course n'est pas param�tr�e pour 3 manches";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
		return;
	end
	_, params.dossard = GetBibo(0);

	tResultat:OrderBy('Dossard');
	local max_row_g1 = math.ceil(tResultat:GetNbRows() / 3);
	local max_row_g2 = tResultat:GetNbRows() - max_row_g1;
	tResultat:OrderRandom();
	for i = tResultat:GetNbRows() - 1, 0, -1 do
		tResultat:SetCell('Dossard', i, params.dossard + i);
		if i >= max_row_g2 then
			tResultat:SetCell('Reserve', i, 3);
		elseif i >= max_row_g1 then
			tResultat:SetCell('Reserve', i, 2);
		else
			tResultat:SetCell('Reserve', i, 1);
		end
	end
	base:TableBulkUpdate(tResultat);

	local Counter_Reserve = tResultat:SetCounter('Reserve');
	local tCounter_Reserve = tResultat:GetCounter('Reserve');
	NbG1 = tCounter_Reserve:GetCellInt('_count_', 0);
	NbG2 = tCounter_Reserve:GetCellInt('_count_', 1);
	NbG3 = tCounter_Reserve:GetCellInt('_count_', 2);
	local tReserve = {};
	table.insert(tReserve, {Manche = 1, Ordre = {1,2,3}});
	table.insert(tReserve, {Manche = 2, Ordre = {3,1,2}});
	table.insert(tReserve, {Manche = 3, Ordre = {2,3,1}});
	for manche = 2, 3 do
		local tOrdre = tReserve[manche].Ordre;	-- si manche = 2, tOrdre = {3,1,2}, tOrdre[2] = 1
		local rang = 1;
		for ordre = 1, 3 do
			local reserve = tOrdre[ordre];
			local filtre = '$(Reserve):In('..reserve..')';
			tResultat_Copy = tResultat:Copy();
			tResultat_Copy:Filter(filtre, true);
			if string.find(option2, '4%.') then
				tResultat_Copy:OrderRandom();
			else
				tResultat_Copy:OrderBy('Dossard');
			end				
			local row = nil;
			local addrow = false;
			for i = 0, tResultat_Copy:GetNbRows() -1 do
				local code_coureur = tResultat_Copy:GetCell('Code_coureur', i);
				local reserve = tResultat_Copy:GetCellInt('Reserve', i);
				local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement.." And Code_manche = "..manche.." And Code_coureur = '"..code_coureur.."'";
				base:TableLoad(tResultat_Manche, cmd);
				if tResultat_Manche:GetNbRows() == 0 then
					addrow = true;
					row = tResultat_Manche:AddRow();
				else
					row = 0;
				end
				tResultat_Manche:SetCell('Code_evenement', row, params.code_evenement);
				tResultat_Manche:SetCell('Code_manche', row, manche);
				tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
				tResultat_Manche:SetCell('Rang', row, rang);
				tResultat_Manche:SetCell('Reserve', row, reserve);
				if addrow == true then
					base:TableInsert(tResultat_Manche, row);
				else
					base:TableUpdate(tResultat_Manche, row);
				end
				rang = rang + 1;
			end
		end
	end
end

function SetDossard(course)
	if course == 1 then
		tCoureur = {};
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.course1..' And Dossard > 0');
		if tResultat:GetNbRows() > 0 then
			local msg = "Les dossards ont d�j� �t� tir�s.\nVoulez-vous les remplacer ?";
			if app.GetAuiFrame():MessageBox(msg, "V�rification !!!"
				, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
				return false;
			end
		end
		if string.find(option2, '3%.') then
			params.bibo, params.dossard = GetBibo(0);
		end
		params.bibo = params.bibo or 30;
		local cmd = 'Update Resultat Set Dossard = Null, Rang = null Where Code_evenement IN('..params.course1..','..params.course2..')';
		base:Query(cmd);
		cmd = 'Delete From Resultat_Manche Where Code_evenement IN('..params.course1..','..params.course2..')'.."And (Tps_chrono =  Null or Tps_Chrono = -1)" ;
		base:Query(cmd);
		cmd = 'Update Resultat_Manche Set Rang = Null Where Code_evenement IN('..params.course1..','..params.course2..')';
		base:Query(cmd);
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.course1);
		params.nb_groupe1 = math.ceil(tResultat:GetNbRows() / 2);
		-- manche 1 de la course 1 : toujours un tirage � la m�l�e.
		tResultat:OrderRandom();
		for i = 0, tResultat:GetNbRows() -1 do
			local code_coureur = tResultat:GetCell('Code_coureur', i);
			local reserve = nil;
			tResultat:SetCell('Dossard', i, i+1);
			tResultat:SetCell('Rang', i, i+1);
			if string.find(option1, '5%.') then		-- 4 manches 
				if i < params.nb_groupe1 then
					reserve = 1;
					tResultat:SetCell('Reserve', i, reserve);
				else
					reserve = 2;
					tResultat:SetCell('Reserve', i, reserve);
				end
			else
				tResultat:SetCellNull('Reserve', i);
			end
			tCoureur[code_coureur] = {};
			tCoureur[code_coureur].Dossard = i+1;
		end
		base:TableBulkUpdate(tResultat);
		tResultat1 = tResultat:Copy();
		tResultat1:OrderBy('Dossard');
	else
		base:TableLoad(tResultat_Manche, 'Select * From Resultat_Manche Where Code_evenement = '..params.course2..' And Code_manche = 1');
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.course2);
		tResultat2 = tResultat:Copy();
		tResultat2:OrderRandom();
		-- on r�cup�re Dossard de la course 1 pour tous les coureurs avec GetIndexRow()
		local rang = 0;
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.course1);
		for i = 0, tResultat2:GetNbRows() -1 do
			rang = rang + 1;
			local code_coureur = tResultat2:GetCell('Code_coureur', i);
			local dossard = nil;
			if tCoureur[code_coureur] then
				dossard = tCoureur[code_coureur].Dossard;
			end
			tResultat2:SetCell('Rang', i, rang);
			tResultat2:SetCell('Dossard', i, dossard);
			tResultat2:SetCell('Rang', i, rang);
			if string.find(option1, '5%.') then		-- 4 manches 
				if i < params.nb_groupe1 then
					reserve = 1;
					tResultat2:SetCell('Reserve', i, reserve);
				else
					reserve = 2;
					tResultat2:SetCell('Reserve', i, reserve);
				end
			else
				tResultat2:SetCellNull('Reserve', i);
			end
		end
		base:TableBulkUpdate(tResultat2, 'Rang, Dossard, Reserve', 'Resultat');
	end
	return true;
end



function SetDossardMixte()
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.course1..' And Dossard > 0');
	if tResultat:GetNbRows() > 0 then
		local msg = "Les dossards ont d�j� �t� tir�s.\nVoulez-vous les remplacer ?";
		if app.GetAuiFrame():MessageBox(msg, "V�rification !!!"
			, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
			return false;
		end
	end
	_, params.dossard = GetBibo(0);

	local cmd = 'Update Resultat Set Dossard = Null, Rang = Null, Reserve = Null Where Code_evenement IN('..params.course1..')';
	base:Query(cmd);
	cmd = 'Delete From Resultat_Manche Where Code_evenement IN('..params.course1..')'.."And (Tps_chrono =  Null or Tps_Chrono = -1)" ;
	base:Query(cmd);
	cmd = 'Update Resultat_Manche Set Rang = Null Where Code_evenement IN('..params.course1..')';
	base:Query(cmd);

	local cmd = 'Select * From Resultat Where Code_evenement = '..params.course1;
	base:TableLoad(tResultat, cmd);
	tResultat_Filles = tResultat:Copy();
	tResultat_Garcons = tResultat:Copy();
	local filtre = "$(Sexe):In('F')";
	tResultat_Filles:Filter(filtre, true);
	tResultat_Filles:OrderRandom();
	tResultat_Filles:OrderRandom();
	local filtre = "$(Sexe):In('M')";
	tResultat_Garcons:Filter(filtre, true);
	tResultat_Garcons:OrderRandom();
	tResultat_Garcons:OrderRandom();
		
	tCoureur = tCoureur or {};

	params.nb_groupe1_filles = math.ceil(tResultat_Filles:GetNbRows() / 2); 	-- 55 filles, params.nb_groupe1_filles = 28 -> row 27
	params.nb_groupe1_garcons = math.ceil(tResultat_Garcons:GetNbRows() / 2);
	
	-- manche 1 de la course 1 : toujours un tirage � la m�l�e.
	local dossard = params.dossard;
	for i = 0, tResultat_Filles:GetNbRows() -1 do
		local code_coureur = tResultat_Filles:GetCell('Code_coureur', i);
		tResultat_Filles:SetCell('Dossard', i, dossard);
		tCoureur[code_coureur] = {};
		tCoureur[code_coureur].Dossard = dossard;
		dossard = dossard + 1;
	end

	base:TableBulkUpdate(tResultat_Filles, 'Dossard', 'Resultat');

	for i = 0, tResultat_Garcons:GetNbRows() -1 do
		local code_coureur = tResultat_Garcons:GetCell('Code_coureur', i);
		tResultat_Garcons:SetCell('Dossard', i, dossard);
		tCoureur[code_coureur] = {};
		tCoureur[code_coureur].Dossard = dossard;
		dossard = dossard + 1;
	end

	base:TableBulkUpdate(tResultat_Garcons, 'Dossard', 'Resultat');
end

function OnTirage2x2Mixte(course, code_evenement)
	-- 6. Tirage pour 2 courses de 2 manches
	
	-- cas de 2 courses de 2 manches
	-- course 1
	-- manche 1 : � la m�l�e
	-- manche 2 : ordre inverse
	-- course 2
	-- manche 1 milieu -> fin puis d�but -> milieu ex de 51 � 100 puis de 1 � 50
	-- manche 2 milieu -> d�but puis fin -> milieu ex de 50 � 1 puis de 100 � 51

	local debut = 0;
	local fin = 0;
	step = 0;
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..code_evenement);
	tResultat:OrderBy('Dossard');
	if course == 1 then
		params.rang_depart = 1;
		row_debut = params.decaler_garcons - 1;
		row_fin = 0;
		step = -1;
		OnTirageManchex(code_evenement, 2, row_debut, row_fin, step);
		row_debut = tResultat:GetNbRows()-1;
		row_fin = params.decaler_garcons;
		step = -1;
		OnTirageManchex(code_evenement, 2, row_debut, row_fin, step);
	else
		for manche = 1, 2 do
			params.rang_depart = 1;
			if manche == 1 then
				-- manche 1 ex de 51 � 100   row de 50 � 99
				-- les filles
				row_debut = params.nb_groupe1_filles;
				row_fin = params.decaler_garcons -1;
				step = 1;
				-- adv.Alert('Filles course 2 manche 1 milieu - fin');
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				-- manche 1 ex de 1 � 50  row de 0 � 49
				row_debut = 0;
				row_fin = params.nb_groupe1_filles -1;
				step = 1;
				-- adv.Alert('Filles course 2 manche 1 d�but - milieu ');
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				
				-- les garcons
				row_debut = params.decaler_garcons + params.nb_groupe1_garcons +1;
				row_fin = tResultat:GetNbRows() -1;
				step = 1;
				-- adv.Alert('Garcons course 2 manche 1 milieu - fin');
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				-- manche 1 ex de 1 � 50  row de 0 � 49
				row_debut = params.decaler_garcons ;
				row_fin = params.decaler_garcons + params.nb_groupe1_garcons;
				step = 1;
				-- adv.Alert('Garcons course 2 manche 1 d�but - milieu');
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				
			else	-- milieu -> d�but puis fin -> milieu
				-- les filles
				row_debut = params.nb_groupe1_filles -1;
				row_fin = 0 ;
				step = -1;
				-- adv.Alert('Filles course 2 manche 2 milieu - d�but');
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				row_debut = params.decaler_garcons - 1;
				row_fin = params.nb_groupe1_filles;
				step = -1;
				-- adv.Alert('Filles course 2 manche 2 fin - milieu');
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);

				-- les garcons
				row_debut = params.decaler_garcons + params.nb_groupe1_garcons;
				row_fin = params.decaler_garcons;
				step = -1;
				-- adv.Alert('garcons course 2 manche 2 milieu - d�but');
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				row_debut = tResultat:GetNbRows() -1;
				row_fin = params.decaler_garcons + params.nb_groupe1_garcons +1 ;
				step = -1;
				-- adv.Alert('garcons course 2 manche 2 fin - milieu');
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
			end
		end
	end
end

function OnTirageNationales(course, code_evenement)
	-- 5. Coupes d'Argent et Nationales jeunes : Tirage pour des courses de 4 manches
	-- 6. Coupes d'Argent et Nationales jeunes : Tirage pour des courses de 2 manches
	-- params.nb_manche est d�fini et les dossards sont tir�s pour toutes les courses
	-- Courses en 4 manches 100 coureurs groupe 1 = de 1 � 50 - groupe 2 de 51 � 100
	-- course 1 
	-- manche 1 tirage � la m�l�e
	-- manche 2 invers�
	-- manche 3 milieu -> fin puis d�but -> milieu ex de 51 � 100 puis de 1 � 50
	-- manche 4 milieu -> d�but puis fin -> milieu ex de 50 � 1 puis de 100 � 51
	
	-- le tirage des dossards est fait pour la course 2 
	-- on garde les dossards et on tire les rangs de d�part
	-- manche 1 tirage la m�l�e 
	-- manche 2, 3 et 4 idem course 1

	-- manche 1 tirage � la m�l�e
	-- manche 2 invers�
	-- manche 3 milieu -> fin puis d�but -> milieu ex de 51 � 100 puis de 1 � 50
	-- manche 4 milieu -> d�but puis fin -> milieu ex de 50 � 1 puis de 100 � 51
	
	-- cas de 2 courses de 2 manches
	-- course 1
	-- manche 1 : � la m�l�e
	-- manche 2 : ordre inverse
	-- course 2
	-- manche 1 milieu -> fin puis d�but -> milieu ex de 51 � 100 puis de 1 � 50
	-- manche 2 milieu -> d�but puis fin -> milieu ex de 50 � 1 puis de 100 � 51

	local debut = 0;
	local fin = 0;
	step = 0;
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..code_evenement);
	tResultat:OrderBy('Rang');
	if string.find(option1, '6%.') and course == 2 then		-- 2 manches 
		tResultat:OrderBy('Dossard');
	end
	if string.find(option1, '5%.') then		-- 4 manches
		for manche = 1, 4 do
			params.rang_depart = 1;
			if manche == 1 then
				--if course == 1 then
				-- if code_evenement ~= params.course1 then
					row_debut = 0;
					row_fin = tResultat:GetNbRows()-1;
					step = 1;
					OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				--end
			elseif manche == 2 then
				row_debut = tResultat:GetNbRows()-1;
				row_fin = 0;
				step = -1;
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
			elseif manche == 3 then 
				-- manche 3 ex de 51 � 100   row de 50 � 99
				row_debut = params.nb_groupe1  ;
				row_fin = tResultat:GetNbRows() -1;
				step = 1;
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				-- manche 3 ex de 1 � 50  row de 0 � 49
				row_debut = 0;
				row_fin = params.nb_groupe1 -1;
				step = 1;
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
			elseif manche == 4 then 
				-- manche 4 ex de 50 � 1  row de 49 � 0
				row_debut = params.nb_groupe1 -1;
				row_fin = 0;
				step = -1;
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				-- manche 4 ex de 100 � 51   row de 99 � 50
				row_debut = tResultat:GetNbRows() -1;
				row_fin = params.nb_groupe1;
				step = -1;
				OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
			end
		end
	elseif string.find(option1, '6%.') then	-- 2 manches
		for manche = 1, 2 do
			params.rang_depart = 1;
			if manche == 1 then
				if code_evenement == params.course2 then
					-- manche 1 ex de 51 � 100   row de 50 � 99
					row_debut = params.nb_groupe1;
					row_fin = tResultat:GetNbRows() -1;
					step = 1;
					OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
					-- manche 1 ex de 1 � 50  row de 0 � 49
					row_debut = 0;
					row_fin = params.nb_groupe1 -1;
					step = 1;
					OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				end
			else
				if course == 1 then
				-- if code_evenement == params.course1 then
					row_debut = tResultat:GetNbRows()-1;
					row_fin = 0;
					step = -1;
					OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				else
					-- manche 2 ex de 50 � 1  row de 49 � 0
					row_debut = params.nb_groupe1 -1;
					row_fin = 0;
					step = -1;
					OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
					-- manche 2 ex de 100 � 51   row de 99 � 50
					row_debut = tResultat:GetNbRows() -1;
					row_fin = params.nb_groupe1;
					step = -1;
					OnTirageManchex(code_evenement, manche, row_debut, row_fin, step);
				end
			end
		end
	end
end

function OnTirageManchex(code_evenement, manche, debut, fin, step)

	-- adv.Alert('OnTirageManchex('..code_evenement..', '..manche..', '..debut..', '..fin..', '..step..')');
	for i = debut, fin, step do
		local code_coureur = tResultat:GetCell('Code_coureur', i);
		base:TableLoad(tResultat_Manche, 'Select * From Resultat_Manche Where Code_evenement = '..code_evenement.." And Code_manche = "..manche.." And Code_coureur = '"..code_coureur.."'");
		local row = 0;
		local addrow = false;
		if tResultat_Manche:GetNbRows() == 0 then
			row = tResultat_Manche:AddRow();
			addrow = true;
		end
		tResultat_Manche:SetCell('Code_evenement', row, code_evenement);
		tResultat_Manche:SetCell('Code_manche', row, manche);
		tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
		tResultat_Manche:SetCell('Rang', row, params.rang_depart);
		if addrow == true then
			base:TableInsert(tResultat_Manche, row);
		else
			base:TableUpdate(tResultat_Manche, row);
		end	
		params.rang_depart = params.rang_depart + 1;
	end
end

function OnTirage(clef1, option1, option2)
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tResultat:OrderBy('Rang, Dossard');
	local dossard1 = tResultat:GetCellInt('Dossard', 0);
	if dossard1 > 0 then
		local msg = "Les dossards ont d�j� �t� tir�s.\nVoulez-vous les remplacer ?";
		if app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!"
			, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
			return;
		end
	end
	local cmd = 'Update Resultat Set Dossard = Null, Rang = Null, Reserve = Null Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	local col = nil;
	if string.find(clef1, '1%.') then
		tRaceGroupe = tRaceSexe;
		col = 'Sexe';
	elseif string.find(clef1, '2%.') then
		tRaceGroupe = tRaceSexeCateg;
		col = 'Categ';
	elseif string.find(clef1, '3%.') then
		tRaceGroupe = tRaceSexeAn;
		col = 'An';
	elseif string.find(clef1, '4%.') then
		tRaceGroupe = tRaceSexe;
		col = 'Sexe';
	end
	tGroupe_tirage = {};
	local groupe = 0;
	tGroupes = {};
	tRaceGroupe = tRaceGroupe or tRaceSexe;
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
	local strClef = nil;
	for i = 0, tResultat:GetNbRows() -1 do
		local sexe = tResultat:GetCell('Sexe', i);
		local an = tResultat:GetCell('An', i);
		local categ = tResultat:GetCell('Categ', i);
		if string.find(clef1, '1%.') then
			strClef = sexe..'-'..sexe;
		elseif string.find(clef1, '2%.') then
			strClef = sexe..'-'..categ;
		elseif string.find(clef1, '3%.') then
			strClef = sexe..'-'..an;
		end
		if tGroupe_tirage[strClef] then
			tResultat:SetCell('Reserve', i, tGroupe_tirage[strClef])
		end		
	end
	base:TableBulkUpdate(tResultat,'Reserve', 'Resultat');
	tResultat:OrderBy('Reserve');
	local dossard = 0;
	local manche = 1;
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
	tReserve = base:TableLoad('Select Distinct Reserve From Resultat Where Code_evenement = '..params.code_evenement..' Order By Reserve');
	if string.find(option1, '2%.') then		-- tirage des rangs pour les 2 manches
		base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement..' Order By Dossard');
		for manche = 1, 2 do
			local rang = 1;
			if manche == 2 and string.find(option2, '2%.') then	-- inversion en manche 2
				tResultat:OrderBy('Dossard DESC');
			end
			for j = 0, tReserve:GetNbRows() -1 do
				local reserve = tReserve:GetCellInt('Reserve', j)
				local filtre = '$(Reserve):In('..reserve..')';
				tResultat_Copy = tResultat:Copy();
				tResultat_Copy:Filter(filtre, true);
				for i = 0, tResultat_Copy:GetNbRows() -1 do
					local code_coureur = tResultat_Copy:GetCell('Code_coureur', i);
					if code_coureur:len() > 0 then
						base:TableLoad(tResultat_Manche, 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement.." And Code_manche = 2 And Code_coureur = '"..code_coureur.."'");
						local row = 0;
						local addrow = false;
						if tResultat_Manche:GetNbRows() == 0 then
							row = tResultat_Manche:AddRow();
							addrow = true;
						end
						tResultat_Manche:SetCell('Code_evenement', row, params.code_evenement);
						tResultat_Manche:SetCell('Code_manche', row, 2);
						tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
						if manche == 2 then
							tResultat_Manche:SetCell('Rang', row, rang);
						else
							tResultat_Manche:SetCellNull('Rang', row);
						end
						if addrow == true then
							base:TableInsert(tResultat_Manche, row);
						else
							base:TableUpdate(tResultat_Manche, row);
						end
						rang = rang + 1;
					end
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
	params.width = (display:GetSize().width * 2) / 3;
	params.height = display:GetSize().height / 2;
	params.x = (display:GetSize().width - params.width) / 2;
	params.y = 200;
	params.version = "2.2";
	base = base or sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	tResultat = base:GetTable('Resultat');
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tResultat_Manche = base:GetTable('Resultat_Manche');
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	params.code_niveau = tEpreuve:GetCell('Code_niveau', 0);
	
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
		local msg = "Ce sc�nario n'est valable que pour les courses FFS !!";
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
	XML = "./process/dossard_TirageOptions.xml";
	params.doc = xmlDocument.Create(XML);
	params.nodeConfig = params.doc:FindFirst('root/config');
	local course1_config = tonumber(params.nodeConfig:GetAttribute('course1')) or -1;
	local clef1_config = tonumber(params.nodeConfig:GetAttribute('clef1')) or 0;
	local option1_config = tonumber(params.nodeConfig:GetAttribute('option1')) or 1;
	local option2_config = tonumber(params.nodeConfig:GetAttribute('option2')) or 0;

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
		discipline = params.discipline,
		node_value = 'config',
		niveau = params.code_niveau
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
	dlgConfig:GetWindowName('clef1'):Append('2. Par Sexe et par Cat�gorie');
	dlgConfig:GetWindowName('clef1'):Append('3. Par Sexe et par Ann�e');
	dlgConfig:GetWindowName('clef1'):Append('4. Sans objet');
		
	dlgConfig:GetWindowName('option1'):Clear();
	dlgConfig:GetWindowName('option1'):Append('1. Tirage pour la manche 1 seulement');
	dlgConfig:GetWindowName('option1'):Append('2. Tirage pour les manches 1 et 2');
	dlgConfig:GetWindowName('option1'):Append('3. Tirage pour la manche 2 (ABD DSQ ordre inverse)');
	dlgConfig:GetWindowName('option1'):Append('4. Tirage des 3 manches par tiers tournants');
	dlgConfig:GetWindowName('option1'):Append("5. Tirage pour des courses de 4 manches");
	dlgConfig:GetWindowName('option1'):Append("6. Tirage pour 2 courses de 2 manches");
	
	dlgConfig:GetWindowName('option2'):Clear();
	dlgConfig:GetWindowName('option2'):Append("1. Pas d'inversion des dossards dans les groupes de tirage");
	dlgConfig:GetWindowName('option2'):Append('2. Inversion des dossards dans les groupes de tirage');
	dlgConfig:GetWindowName('option2'):Append('3. Gestion du BIBO');
	dlgConfig:GetWindowName('option2'):Append('4. Tirage au sort dans les tiers tournants');
	dlgConfig:GetWindowName('option2'):Append('5. Sans objet');

	if course1_config == params.code_evenement then
		dlgConfig:GetWindowName('clef1'):SetSelection(clef1_config);
		dlgConfig:GetWindowName('option1'):SetSelection(option1_config);
		dlgConfig:GetWindowName('option2'):SetSelection(option2_config);
	else
		dlgConfig:GetWindowName('clef1'):SetSelection(0);
		dlgConfig:GetWindowName('option1'):SetSelection(1);
		dlgConfig:GetWindowName('option2'):SetSelection(1);
	end
	dlgConfig:GetWindowName('course1'):SetValue(params.code_evenement);
	dlgConfig:GetWindowName('course1_nom'):SetValue(tEvenement:GetCell('Nom', 0));
	
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
			local code_evenement1 = tonumber(dlgConfig:GetWindowName('course1'):GetValue()) or -1;
			tEvenement1 = base:TableLoad('Select Nom From Evenement Where Code = '..code_evenement1);
			if tEvenement1:GetNbRows() > 0 then
				dlgConfig:GetWindowName('course1_nom'):SetValue(tEvenement1:GetCell('Nom', 0));
			else
				dlgConfig:GetWindowName('course1_nom'):SetValue('');
			end
		end, dlgConfig:GetWindowName('course1')); 

	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
			local code_evenement2 = tonumber(dlgConfig:GetWindowName('course2'):GetValue()) or -1;
			tEvenement2 = base:TableLoad('Select Nom From Evenement Where Code = '..code_evenement2);
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
		end, dlgConfig:GetWindowName('option1')); 
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
			local clef1 = dlgConfig:GetWindowName('clef1'):GetValue();
			local option1 = dlgConfig:GetWindowName('option1'):GetValue();
			local option2 = dlgConfig:GetWindowName('option2'):GetValue();
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
			params.doc:SaveFile();
			dlgConfig:EndModal(idButton.OK);
		end, btnSave); 
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:EndModal(idButton.CANCEL);
		 end,  btnClose);

	dlgConfig:Fit();
	
	if dlgConfig:ShowModal() == idButton.OK then
		local intKO = 0;
		if string.find(option1, '5%.') then
			for i = 1, 2 do
				if params['course'..i] > 0 then
					base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params['course'..i]..' And Code_epreuve = 1');
					params.nb_manche = tEpreuve:GetCellInt('Nombre_de_manche', 0);
					if params.nb_manche ~= 4 then
						intKO = 4;
					end
				end
			end
		elseif string.find(option1, '6%.') then
			local intKO = true;
			for i = 1, 2 do
				if params['course'..i] > 0 then
					base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params['course'..i]..' And Code_epreuve = 1');
					params.nb_manche = tEpreuve:GetCellInt('Nombre_de_manche', 0);
					if params.nb_manche ~= 2 then
						intKO = 2;
					end
				end
			end
		end
		if string.find(option1, '5%.') or string.find(option1, '6%.')  then
			if intKO > 0 then
				local msg = "Le nombre de manche doit �tre �gal � "..intKO.." !!";
				app.GetAuiFrame():MessageBox(msg, "ATTENTION !!!"
					, msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
				return;
			end
		end
		if string.find(option1, '1%.') then
			OnTirageManche1();
		elseif string.find(option1, '2%.') then
			base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement..' And Code_epreuve = 1');
			params.nb_manche = tEpreuve:GetCellInt('Nombre_de_manche', 0);
			if params.nb_manche ~= 2 then
				local msg = "Le nombre de manche doit �tre �gal � 2 !!";
				app.GetAuiFrame():MessageBox(msg, "ATTENTION !!!"
					, msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
				return;
			end
			OnTirage(clef1, option1, option2);
		elseif string.find(option1, '3%.') then
			OnTirageManche2Special()
		elseif string.find(option1, '4%.') then
			if string.find(clef1, '1%.') then
				OnTirageParTiersMixte();
			else
				OnTirageParTiers();
			end
		elseif string.find(option1, '5%.') or string.find(option1, '6%.') then
			params.decaler_garcons = 0;
			if string.find(clef1, '1%.') then		--par sexe
				if string.find(option1, '6%.') then
					if params.course1 > 0 then
						local bolOK = SetDossardMixte();
						if bolOK == false then return false; end
						OnTirage2x2Mixte(1, params.course1);
					end
					if params.course2 > 0 then
						OnTirage2x2Mixte(2, params.course2);
					end
				end
			else
				if params.course1 > 0 then
					local bolOK = SetDossard(1);
					if bolOK then
						OnTirageNationales(1, params.course1);
					end
				end
				if params.course2 > 0 then
					local bolOK = SetDossard(2);
					if bolOK then
						OnTirageNationales(2, params.course2);
					end
				end
				if string.find(option1, '6%.') then
					local cmd = 'Delete From Resultat_Manche Where Code_evenement IN('..params.course1..','..params.course2..') And Code_manche > 2';
					base:Query(cmd);
				end
			end
		end			
		local cmd = 'Update Resultat Set Rang = NULL Where Code_evenement IN('..params.course1..','..params.course2..')';
		base:Query(cmd);
	end
	return true;
end




