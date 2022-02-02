dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- version 2.3
	-- calcul du diff Heure_depart2
	-- mise de 00.0 au premier Dos au lieu d'avoir la case vide pour l'ecart
	-- affichage du N° de couloir en prenant le 1er chiffre du 1er Dos du body 
	
-- point a voir avec pierre
			-- voir si la façon de mettre la police ds le body est ok si qq veut la modifier si format A3 par exemple 


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
		width=400, -- widthControl, 
		height=300, -- heightControl, 
		label='Couloir', 
		icon='./res/32x32_agil.png'
	});
	
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlg:LoadTemplateXML({ 
		xml = './edition/Couloir.xml', 		-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'Couloir',			-- Facultatif si le node_name est unique ...	
	});

	-- La table body est la table filtrée ou pas ... mais c'est la bonne 
	body = base:GetTable('body');
	
	-- Tri du body
	body:OrderBy('Heure_depart2 Asc' );
	-- body:OrderBy('Dossard' );
	-- Ajout et Mise à Jour de la colonne Diff_Heure_depart2
	body:AddColumn({ name = 'Diff_heure_depart2', label = 'Diff_heure_depart2', type = sqlType.CHRONO });	
	if body:GetNbRows() > 0 then
		local best_heure_depart2 = body:GetCellInt('Heure_depart2',0);
		for i=0, body:GetNbRows()-1 do
			if body:GetCellInt('Heure_depart2', i, -1) >= best_heure_depart2 then 
				body:SetCell('Diff_heure_depart2', i, body:GetCellInt('Heure_depart2',i) - best_heure_depart2);
			end
			if tonumber(i) == 0 then
				body:SetCell('Diff_heure_depart2', i, 1);
			end
		end
	end
	
	-- Initialisation des controles ...
	local comboNbCouloir = dlg:GetWindowName('NbCouloir');
		
	local checkbox_Affich_HeureDepart = dlg:GetWindowName('Affich_HeureDepart'):SetValue(true);
	
	local checkbox_Affich_Ecart = dlg:GetWindowName('Affich_Ecart'):SetValue(false);
	
	local tb = dlg:GetWindowName('tb');
	if tb then
		local btn_edition = tb:AddTool('OK', './res/16x16_xml.png');
		tb:AddStretchableSpace();
		local btn_close = tb:AddTool('Annuler', './res/16x16_close.png');
		tb:Realize();

		tb:Bind(eventType.MENU, LectureDonnees, btn_edition);
		tb:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL); end, btn_close);
	end
		
	dlg:Fit();
	dlg:ShowModal();
	dlg:Delete();
end

function LectureDonnees(evt)

	-- recuperation des données de la combox du nb de couloir
	theParams.NbCouloir = dlg:GetWindowName('NbCouloir'):GetValue();
	
	-- récupération de la valeur de checkbox pour l'affichage de l'heure de départ  pour la mettre dans les params
	if dlg:GetWindowName('Affich_HeureDepart'):GetValue() == true then
		theParams.Affich_heureDepart = 1;
	else 
		theParams.Affich_heureDepart = 2;
	end 
	
	-- récupération de la valeur de checkbox pour l'affichage de l'écarts de départ pour la mettre dans les params
	if dlg:GetWindowName('Affich_Ecart'):GetValue() == true then
		theParams.Affich_Ecart = 1;
	else
		theParams.Affich_Ecart = 2;
	end 
	
	NbCouloir = tonumber(dlg:GetWindowName('NbCouloir'):GetValue());
	
	for i=0, NbCouloir-1 do
		editionCouloir_n(evt, params, base, body, i, NbCouloir);
	end

	-- Fermeture
	dlg:EndModal(idButton.OK);

end

function editionCouloir_n(evt, params, base, body, ind, NbCouloir)
	-- AfficheNumCouloir = NumCouloir+1
	bodyCouloir = body:Copy(false);
	
	for i=0, body:GetNbRows()-1 do
		Dossard = tonumber(body:GetCell('Dossard', i)) or 0;
		
		if Dossard % NbCouloir == ind then
			--alert("ind= "..ind)
			bodyCouloir:AddRow();
			sqlTable.CopyRow(bodyCouloir, bodyCouloir:GetNbRows()-1, body, i);
		end
	end
		
	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/Couloir.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'Couloir' ,
		
		-- parent = dlg,
			
		base = base,
		body = bodyCouloir,
		
		params = theParams
	});
end
