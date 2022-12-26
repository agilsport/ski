dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- version 2.0
	-- permet l'edition de l'analyse de performance entre inter d'une plage définie


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
		label='Edition d\'une plage de Temps Inter', 
		icon='./res/32x32_agil.png'
	});
	
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlg:LoadTemplateXML({ 
		xml = './edition/Edition_plage_Inter.xml', 		-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'Plage',			-- Facultatif si le node_name est unique ...	
	});

	-- Initialisation des controles ...
	local spinctrlFirstInter = dlg:GetWindowName('FirstInter');
	
	local spinctrlLastInter = dlg:GetWindowName('LastInter');
	
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

	manche = dlg:GetWindowName('manche'):GetValue();
	theParams.manche = dlg:GetWindowName('manche'):GetValue();
	
	-- recuperation des données de la combox du nb de couloir
	FirstInter = dlg:GetWindowName('FirstInter'):GetValue();
	
	LastInter = dlg:GetWindowName('LastInter'):GetValue();
	
	theParams.Nb_tps_inter = tonumber(LastInter)- tonumber(FirstInter) + 1;
	theParams.FirstInter = tonumber(FirstInter);
	theParams.LastInter = tonumber(LastInter);
	
	-- Nb_tps_inter = base:GetTable('Epreuve_Nordique'):GetCellInt('Nb_temps_inter', 0, 1)
	-- La table body est la table filtrée ou pas ... mais c'est la bonne 
	body = base:GetTable('body');
	-- Tri du body
	body:OrderBy('Clt Asc' );
	
	-- Ajout et Mise à Jour de la colonne Diff_Heure_depart2
	for i=tonumber(FirstInter),tonumber(LastInter) do
	body:AddColumn({ name = 'Diff_Tps'..manche..'_I'..i, label = 'Diff_Tps'..manche..'_I'..i, type = sqlType.CHRONO });
	body:AddColumn({ name = 'Rank_Diff_Tps'..manche..'_I'..i, label = 'Rank_Diff_Tps'..manche..'_I'..i, type = sqlType.RANKING });
	-- alert('Rank_Diff_Tps'..manche..'_I'..i)
	end
	
	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/Edition_plage_Inter.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'res_DiffInter_Plage' ,
		
		-- parent = dlg,
			
		base = base,
		body = body,
		
		params = theParams
	});

	-- Fermeture
	dlg:EndModal(idButton.OK);

end


