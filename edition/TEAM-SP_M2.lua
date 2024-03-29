dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- version 2.6

-- point a voir avec pierre
			-- Edition des factures par club comit� ou nation 
			-- manque la gestion des abs a traiter
			-- une page blache se cr�er a la fin de l'edition par nation comite club le row ~= 0 n'est pas valable comme on est ds le end

function Alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function main(params)
	theParams = params;

	local widthMax = display:GetSize().width;
	local widthControl = math.floor((widthMax*3)/4);
	local x = math.floor((widthMax-widthControl)/2);

	local heightMax = display:GetSize().height;
	local heightControl = math.floor((heightMax *3) / 4);
	local y = math.floor((heightMax-heightControl)/2);

	dlg = wnd.CreateDialog({
		x = x,
		y = y,
		width=600, -- widthControl, 
		height=300, -- heightControl,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		label='Heure D�part Equipier 2 des Team-Sprint', 
		icon='./res/32x32_agil.png'
	});
	
	base = sqlBase.Clone();
	body = base.CreateTableRanking({ 
		code_evenement = theParams.code_evenement, 
		code_epreuve = theParams.code_epreuve, 
		code_manche = theParams.code_manche,
		Organisateur = theParams.Organisateur,
		Club = theParams.Club,
	Comite = theParams.Code_comite,
	codeActivite = theParams.Code_activite
	});
	--body = base:GetTable('body');
	-- Tri du body
	body:OrderBy('Code_epreuve , Heure_depart1 Desc' );
	code_evenement = theParams.code_evenement;

	tEpreuve = base:GetTable('Epreuve');

	-- on recherche si il y a deja des inscrits ds la tables resultats_manche
	tResultat_Manche = base:GetTable('Resultat_Manche');
	cmd =      "Select * from Resultat_Manche ";
	cmd = cmd.." Where Code_evenement = "..tonumber(code_evenement);
	cmd = cmd.." And Code_manche = 1";
	tResultat_Manche1 = base:TableLoad(tResultat_Manche, cmd)

	if tResultat_Manche1:GetNbRows() >= 1 then
		-- je verifie si j'ai bien la colonne Heure_depart2 ds le body
		base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
		local Nb_Epreuve = tEpreuve:GetCellInt('Nombre_de_manche', 0);
		-- Alert("Nb_Epreuve: "..Nb_Epreuve);
		if Nb_Epreuve == 1 then
			body:AddColumn({ name = 'Heure_depart2', label = 'Heure_depart2', type = sqlType.CHRONO, style = sqlStyle.INT });
			Alert("Nb_Epreuve: "..Nb_Epreuve);
		end
		-- je regarde si la colonne Heure_depart2 est ~= de nil 
		cmd =      "Select * from Resultat_Manche ";
		cmd = cmd.." Where Code_evenement = "..tonumber(code_evenement);
		cmd = cmd.." And Code_manche = 2";
		tResultat_Manche2 = base:TableLoad(tResultat_Manche, cmd);
		nbrow_tResultat_Manche2 = tResultat_Manche2:GetNbRows();
		tResultat_Manche2:GetCell('Heure_depart2', 0)
		-- Alert("nbrow_tResultat_Manche2: "..nbrow_tResultat_Manche2);
		-- local tEpreuve = base:GetTable('Epreuve');
		if 	tResultat_Manche2:GetCell('Heure_depart2', 0) ~= nil then
			if dlg:MessageBox("Confirmation G�n�ration des Heures de D�part des 2�me �quipiers ?\n\nCette op�ration effacera les heures de d�part M2 \n avant de les g�n�rer de nouveau.", "Confirmation G�n�ration des Heures de D�part", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
				CreationReport(evt, base, body, theParams);
				dlg:Delete();
				return;
			end
		end 
		-- Creation des Controles et Placement des controles par le Template XML ...
		dlg:LoadTemplateXML({ 
			xml = './edition/TEAM-SP_M2.xml', 		-- Obligatoire
			node_name = 'root/panel', 			-- Obligatoire
			node_attr = 'name', 				-- Facultatif si le node_name est unique ...
			node_value = 'Heure_equipier2',			-- Facultatif si le node_name est unique ...	
		});
		
		local comboOrderBy = dlg:GetWindowName('OrderBy_M2');
		comboOrderBy:Append('Ordre Inverse des �quipiers 1');
		comboOrderBy:Append('M�mes ordre que les �quipiers 1');
		comboOrderBy:SetValue('Ordre Inverse des �quipiers 1');
		
		-- local tEpreuve = base:GetTable('Epreuve');
		tEpreuve:AddColumn({ name = 'Heure_depart2', label = 'Heure_depart2', type = sqlType.CHRONO, style = sqlStyle.INT });
		tEpreuve:AddColumn({ name = 'Ecart2', label = 'Ecart2', type = sqlType.CHRONO, style = sqlStyle.NULL });
		
		tEpreuve:SetColumn('Code_discipline', { label = 'Disc.', width = 12 });
		tEpreuve:SetColumn('Code_niveau', { label = 'Niveau.', width = 12 });
		tEpreuve:SetColumn('Code_categorie', { label = 'Cat�gorie.', width = 12 });
		tEpreuve:SetColumn('Sexe', { label = 'Sexe.', width = 6 });
		tEpreuve:SetColumn('Heure_depart2', { label = 'Heure d�part M2', width = 15 });
		tEpreuve:SetColumn('Ecart2', { label = 'Ecart M2', width = 15 });
		
		grid = dlg:GetWindowName('grid_epreuve');
		grid:Set({
			table_base = tEpreuve,
			columns = 'Code_epreuve, Code_categorie, Sexe, Heure_depart2, Ecart2',
			selection_mode = gridSelectionModes.CELLS,
			sortable = false,
			enable_editing = true
		});
		grid:SetColAttr('Heure_depart2', { kind='time' });
		grid:SetColAttr('Ecart2', { kind='time' });
		grid:Bind(eventType.GRID_EDITOR_SHOWN, OnEditorShown);
		grid:Bind(eventType.GRID_CELL_CHANGED, OnCellChanged);

		-- Toolbar
		local tb = dlg:GetWindowName('tb');
		if tb then
			local btn_edition = tb:AddTool('Edition', './res/16x16_xml.png');
			tb:AddStretchableSpace();
			local btn_close = tb:AddTool('Fermer', './res/16x16_close.png');
			tb:Realize();

			tb:Bind(eventType.MENU, LectureDonnees, btn_edition);
			tb:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL); end, btn_close);
		end
	else
		-- Creation des Controles et Placement des controles par le Template XML ...
		dlg:LoadTemplateXML({ 
			xml = './edition/TEAM-SP_M2.xml', 		-- Obligatoire
			node_name = 'root/panel', 			-- Obligatoire
			node_attr = 'name', 				-- Facultatif si le node_name est unique ...
			node_value = 'Heure_depart1',			-- Facultatif si le node_name est unique ...	
		});
	
		-- Toolbar
		local tb = dlg:GetWindowName('tb');
		if tb then
			local btn_edition = tb:AddTool('Edition', './res/16x16_xml.png');
			tb:AddStretchableSpace();
			local btn_close = tb:AddTool('Fermer', './res/16x16_close.png');
			tb:Realize();

			tb:Bind(eventType.MENU, LectureDonnees, btn_edition);
			tb:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL); end, btn_close);
		end
	
	end
		
	dlg:Fit();
	dlg:ShowModal();
	dlg:Delete();
end

function OnEditorShown(evt)
	local row = evt:GetRow();
	local col = evt:GetCol();
	if row >= 0 and col >= 0 then
		local t = grid:GetTable();
		local colName = t:GetColumnName(t:GetVisibleColumnsIndex(col));
		if colName == "Heure_depart2" then
			-- On accepte l'�dition
			return;
		elseif colName == "Ecart2" then	
			return;
		end
	end

	-- Dans tous les autres cas on n'autorise pas l'�dition ...
	evt:Veto();
end

function LectureDonnees(evt)
	-- recuperation des donn�es de la combox 
	-- TriChoix = dlg:GetWindowName('ChoixFiltrage'):GetValue();
	code_evenement = theParams.code_evenement;
	PcodeManche = 2;
	theParams.title = 'G�n�ration des Heures de D�part des 2�me �quipiers';
	OrderBy_M2 = dlg:GetWindowName('OrderBy_M2'):GetValue();
	if OrderBy_M2 == 'Ordre Inverse des �quipiers 1' then
		body:OrderBy('Code_epreuve,Heure_depart1 Desc' );
	else
		body:OrderBy('Code_epreuve,Heure_depart1 Asc' );
	end

		-- si j'ai pas le memes nombre de ligne dans le body et la table manche 2 j'efface la table et je repart a 0
	nbrows_body = body:GetNbRows()
	if nbrow_tResultat_Manche2 < nbrows_body then
		cmd = 	   "Delete From Resultat_Manche" 
		cmd = cmd.." Where Code_evenement = "..tonumber(code_evenement);
		cmd = cmd.." And Code_manche = "..PcodeManche;
		base:Query(cmd);
		Alert("je fait un raz de la table"); 
	end

	for i=0, tEpreuve:GetNbRows()-1 do	
		-- Heure_depart2 = 0;
		-- Ecart2 = 0;
		local code_epreuve = tEpreuve:GetCell('Code_epreuve', i);
		Alert("Prise en compte param�tre �preuve: "..code_epreuve);
		-- Alert("code_epreuve: "..code_epreuve);
		Heure_depart2 = tEpreuve:GetCellInt('Heure_depart2', i)
		local stringHeure_depart2 = tEpreuve:GetCell('Heure_depart2', i, '%2hh%2m:%2s')
		Alert("Heure_depart de l\'�preuve: "..stringHeure_depart2);
		Ecart2 = tEpreuve:GetCellInt('Ecart2', i)
		Alert("Avec un Ecart de: "..tEpreuve:GetCell('Ecart2', i).." sec.");
		if nbrow_tResultat_Manche2 >=1 then
			for i=0, body:GetNbRows()-1 do
				rang2 = i+1;
				Alert("Update Heure_depart2: "..Heure_depart2);
				if body:GetCell('Code_epreuve', i) == code_epreuve then
					cmd =      "Update Resultat_Manche Set Heure_depart = "..Heure_depart2;
					cmd = cmd..", Rang = "..rang2;
					cmd = cmd.." Where Code_evenement = "..tonumber(code_evenement);
					cmd = cmd.." And Code_coureur = '"..body:GetCell('Code_coureur', i).."'";
					cmd = cmd.." And Code_manche = "..PcodeManche;
					base:Query(cmd);
					body:SetCell('Heure_depart2',i, Heure_depart2);
					Heure_depart2 = Heure_depart2 + Ecart2
				end
			end
		else
			for i=0, body:GetNbRows()-1 do	
				Alert("Insert Into Heure_depart2: "..Heure_depart2);
				rang2 = i+1;
				if body:GetCell('Code_epreuve', i) == code_epreuve then
					cmd = "Insert Into Resultat_Manche (Code_evenement, Code_coureur, Code_manche, Heure_depart, Rang) values (";
					cmd = cmd..tonumber(code_evenement);
					cmd = cmd..",'";
					cmd = cmd..body:GetCell('Code_coureur', i).."', ";
					cmd = cmd..PcodeManche..", ";
					cmd = cmd..Heure_depart2..", ";
					cmd = cmd..rang2;
					cmd = cmd..")";
					base:Query(cmd);
					body:SetCell('Heure_depart2',i, Heure_depart2);
					Heure_depart2 = Heure_depart2 + Ecart2
				end
			end		
		
		end
	end
	
	CreationReport(evt, base, body, theParams);

	-- Fermeture
	dlg:EndModal(idButton.OK);

end

function CreationReport(evt, base, body, theParams)
-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/TEAM-SP_M2.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'H_dept_M2' ,
		
		-- parent = dlg,
			
		base = base,
		body = body,
		
		params = theParams
	});
end