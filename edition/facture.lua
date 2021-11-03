dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- version 2.5

-- point a voir avec pierre
			-- Edition des factures par club comité ou nation 
			-- manque la gestion des abs a traiter
			-- une page blache se créer a la fin de l'edition par nation comite club le row ~= 0 n'est pas valable comme on est ds le end

function alert(txt)
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
		label='Facture', 
		icon='./res/32x32_agil.png'
	});
	
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlg:LoadTemplateXML({ 
		xml = './edition/facture.xml', 		-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'Facturation',			-- Facultatif si le node_name est unique ...	
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
	
	-- body:SetName('body');
	-- base:AddTable(body);
	-- code_evenement = base:GetTable('Evenement'):GetCellInt('Nom');
	-- alert('test'..code_evenement);
	

	-- Initialisation des controles ...
	local comboChoixtri = dlg:GetWindowName('ChoixFiltrage');
	comboChoixtri:Append('Nation');
	comboChoixtri:Append('Comite');
	comboChoixtri:Append('Club');
	comboChoixtri:SetValue('Club');
	
	local comboGestionAbs = dlg:GetWindowName('GestionAbs');
	comboGestionAbs:Append('enlever les Absents');
	comboGestionAbs:Append('facturer tout les inscrits');
	comboGestionAbs:SetValue('facturer tout les inscrits');

	local tEpreuve = base:GetTable('Epreuve');
	tEpreuve:AddColumn('Tarif_Inscriptions');
	
	tEpreuve:SetColumn('Code_discipline', { label = 'Disc.', width = 12 });
	tEpreuve:SetColumn('Code_niveau', { label = 'Niveau.', width = 12 });
	tEpreuve:SetColumn('Code_categorie', { label = 'Catégorie.', width = 12 });
	tEpreuve:SetColumn('Sexe', { label = 'Sexe.', width = 6 });
	tEpreuve:SetColumn('Tarif_Inscriptions', { label = 'Tarif Inscriptions', width = 15 });
	
	grid = dlg:GetWindowName('grid_epreuve');
	grid:Set({
		table_base = tEpreuve,
		columns = 'Code_discipline, Code_niveau, Code_categorie, Sexe, Tarif_Inscriptions',
		selection_mode = gridSelectionModes.CELLS,
		sortable = false,
		enable_editing = true
	});
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
		if colName == "Tarif_Inscriptions" then
			-- On accepte l'édition
			
			return;
		end
	end

	-- Dans tous les autres cas on n'autorise pas l'édition ...
	evt:Veto();
end

function LectureDonnees(evt)
	-- recuperation des données de la combox 
	TriChoix = dlg:GetWindowName('ChoixFiltrage'):GetValue();
	
	if TriChoix == 'Comite' then
		theParams.ChoixRequette = 'Comite';
	elseif
		TriChoix == 'Club' then
		theParams.ChoixRequette = 'Club';
	elseif
		TriChoix == 'Nation' then
		theParams.ChoixRequette = 'Nation';
	end
	
	
	GestionAbsent = dlg:GetWindowName('GestionAbs'):GetValue();
	-- alert('GestionAbsent = '..GestionAbsent);
	if GestionAbsent == 'facturer tout les inscrits' then
		bodyFact = body;
	elseif GestionAbsent == 'enlever les Absents' then
		bodyFact = body:Copy(false);
		for i=0, body:GetNbRows()-1 do
			Tps = body:GetCell('Tps', i)
			alert('Tps = '..Tps);
			if Tps ~= 'Abs' then
				bodyFact:AddRow();
				sqlTable.CopyRow(bodyFact, bodyFact:GetNbRows()-1, body, i);
			end
		end
	end
	
	theParams.title = 'Facturation des droits d\' inscriptions';
	
	local tEpreuve = base:GetTable('Epreuve');

	for i=0, tEpreuve:GetNbRows()-1 do
		theParams['tarif_'..tostring(i+1)] = tEpreuve:GetCell('Tarif_Inscriptions', i);
	end
	
-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/facture.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'uti_facture' ,
		
		-- parent = dlg,
			
		base = base,
		body = bodyFact,
		
		params = theParams
	});
	
	editionChoix(evt, GestionAbsent, params, base, bodyFact)
	-- Fermeture
	dlg:EndModal(idButton.OK);

end

function editionChoix(evt, GestionAbsent, params, base, bodyFact)
	local tEpreuve = base:GetTable('Epreuve');

	for i=0, tEpreuve:GetNbRows()-1 do
		theParams['tarif_'..tostring(i+1)] = tEpreuve:GetCell('Tarif_Inscriptions', i);
	end
	
	theParams.title = 'Facturation des droits d\' inscriptions';

-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/facture.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'uti_facture_tri' ,
		
		base = base,
		body = bodyFact,
		
		params = theParams
	});

end
