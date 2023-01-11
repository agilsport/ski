dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- version 2.7

-- création des heures de départ de la M2 
			

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
		label='Heure Départ Equipier 2 des Team-Sprint', 
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
	body:OrderBy('Code_epreuve,Heure_depart1 Asc,Rang1 Asc,Dossard Asc' );
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
			if dlg:MessageBox("Confirmation Génération des Heures de Départ des 2ème équipiers ?\n\nCette opération effacera les heures de départ M2 \n avant de les générer de nouveau.", "Confirmation Génération des Heures de Départ", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
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
		-- local tEpreuve = base:GetTable('Epreuve');
		tEpreuve:AddColumn({ name = 'Heure_depart2', label = 'Heure_depart2', type = sqlType.CHRONO, style = sqlStyle.INT });
		tEpreuve:AddColumn({ name = 'Ecart2', label = 'Ecart2', type = sqlType.CHRONO, style = sqlStyle.NULL });
		
		tEpreuve:SetColumn('Code_discipline', { label = 'Disc.', width = 12 });
		tEpreuve:SetColumn('Code_niveau', { label = 'Niveau.', width = 12 });
		tEpreuve:SetColumn('Code_categorie', { label = 'Catégorie.', width = 12 });
		tEpreuve:SetColumn('Sexe', { label = 'Sexe.', width = 6 });
		tEpreuve:SetColumn('Heure_depart2', { label = 'Heure départ M2', width = 15 });
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
			-- local btn_edition = tb:AddTool('Edition', './res/16x16_xml.png');
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
			-- On accepte l'édition
			return;
		elseif colName == "Ecart2" then	
			return;
		end
	end
	-- Dans tous les autres cas on n'autorise pas l'édition ...
	evt:Veto();
end

function LectureDonnees(evt)
	-- recuperation des données de la combox 
	-- TriChoix = dlg:GetWindowName('ChoixFiltrage'):GetValue();
	code_evenement = theParams.code_evenement;
	PcodeManche = 2;
	theParams.title = 'Génération des Heures de Départ des 2ème équipiers';

	for i=0, tEpreuve:GetNbRows()-1 do	
		-- Heure_depart2 = 0;
		-- Ecart2 = 0;
		local code_epreuve = tEpreuve:GetCell('Code_epreuve', i);
		Alert("Prise en compte paramètre épreuve: "..code_epreuve);
		-- Alert("code_epreuve: "..code_epreuve);
		Heure_depart2 = tEpreuve:GetCellInt('Heure_depart2', i)
		local stringHeure_depart2 = tEpreuve:GetCell('Heure_depart2', i, '%2hh%2m:%2s')
		Alert("Heure_depart de l\'épreuve: "..stringHeure_depart2);
		Ecart2 = tEpreuve:GetCellInt('Ecart2', i)
		Alert("Avec un Ecart de: "..tEpreuve:GetCell('Ecart2', i).." sec.");
		if nbrow_tResultat_Manche2 >=1 then
			for i=0, body:GetNbRows()-1 do	
				-- Alert("Update Heure_depart2: "..Heure_depart2);
				if body:GetCell('Code_epreuve', i) == code_epreuve then
					cmd =      "Update Resultat_Manche Set Heure_depart = "..Heure_depart2;
					cmd = cmd..", Rang = "..i+1;
					cmd = cmd.." Where Code_evenement = "..tostring(code_evenement);
					cmd = cmd.." And Code_coureur = '"..body:GetCell('Code_coureur', i);
					cmd = cmd.."' And Code_manche = "..tostring(PcodeManche);
					base:Query(cmd);
					body:SetCell('Heure_depart2',i, Heure_depart2);
					Heure_depart2 = Heure_depart2 + Ecart2
				end
			end
		else
			for i=0, body:GetNbRows()-1 do	
				-- Alert("Insert Into Heure_depart2: "..Heure_depart2);
				if body:GetCell('Code_epreuve', i) == code_epreuve then
					cmd = "Insert Into Resultat_Manche (Code_evenement, Code_coureur, Code_manche, Rang, Heure_depart) values (";
					cmd = cmd..tostring(code_evenement);
					cmd = cmd..",'"..body:GetCell('Code_coureur', i);
					cmd = cmd.."',"..tostring(PcodeManche);
					cmd = cmd..","..tostring(i+1);
					cmd = cmd..","..tostring(Heure_depart2);
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