dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- version 2.0


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
		width=780, -- widthControl, 
		height=500, -- heightControl, 
		label='Transfert Pts_Clt dans PtsClt & Clt dans Clt_best', 
		icon='./res/32x32_agil.png'
	});
	
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlg:LoadTemplateXML({ 
		xml = './edition/ColPtsClt_ColPtsBest.xml', 		-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'ColPtsClt_ColPtsBest',			-- Facultatif si le node_name est unique ...	
	});	

	base = sqlBase.Clone();
	code_evenement = tonumber(theParams.code_evenement);
	Label_col = theParams.Label_col;
	
	-- Initialisation des controles ...
	local comboNbCouloir = dlg:GetWindowName('N_Course');
	
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
	-- alert("code_evenement = "..code_evenement);
	Evt_source = tonumber(dlg:GetWindowName('N_Course'):GetValue());
	-- alert("Evt_source = "..Evt_source);
	tResultat = base:GetTable('Resultat');
	tResultat:AddColumn('CltG');
	tResultat:AddColumn('PtsClt_G');
	cmd = "Select  b.*, a.Clt CltG, a.PtsClt PtsClt_G"..
			" From Resultat a, Resultat b "..
			" Where a.Code_evenement = "..Evt_source..
			" And b.Code_evenement = "..tonumber(code_evenement)..
			" And a.Code_coureur = b.Code_coureur";
	base:TableLoad(tResultat, cmd);
	bodyliste = tResultat:Copy(false);
	
	-- alert("base:TableLoad(Resultat, cmd) = "..cmd)
	Nbparticipant = tResultat:GetNbRows();
	for i=0, Nbparticipant-1 do
		Points_Ch = tResultat:GetCell('PtsClt_G', i) or 0;
		Place = tResultat:GetCell('CltG', i) or 0;
		Groupe = 'Cha'..Evt_source;
		Critere = '';
		-- alert('Place = '..Place);
		if tonumber(Place) == 0 or Place == '' then 
			Critere = 'NQ_Cha.';
			Points_Ch = 9999;
			Place = 9999;
		end
		if Label_col == 'Info' then
			cmd = "Update Resultat SET Info = '"..Points_Ch..
			"', Ordre_niveau = "..tonumber(Place)..
			", Niveau = '"..Critere..
			"', Moniteur = '"..Groupe..
			"' Where Code_evenement = "..tonumber(code_evenement)..
			" and Code_coureur = '"..tResultat:GetCell('Code_coureur', i)..
			"'";
		else
			cmd = "Update Resultat SET Pts_best = '"..Points_Ch..
				"', Ordre_niveau = "..tonumber(Place)..
				", Niveau = '"..Critere..
				"', Moniteur = '"..Groupe..
				"' Where Code_evenement = "..tonumber(code_evenement)..
				" and Code_coureur = '"..tResultat:GetCell('Code_coureur', i)..
				"'";
		end
		base:Query(cmd);
		-- alert("cmd = "..cmd)
	end
-- rechargement du body pour edition liste	
	for i=0, Nbparticipant-1 do
		bodyliste:AddRow();
		sqlTable.CopyRow(bodyliste, bodyliste:GetNbRows()-1, tResultat, i);
	end
	
	editionliste(evt, params, base, bodyliste);
	alert("Clt du Challenge: "..Groupe..'Importer dans la colonne '..Label_col)
	-- Fermeture
	bodyliste:Delete();
	dlg:EndModal(idButton.OK);

end

function editionliste(evt, params, base, bodyliste)
	-- Creation du Report
	theParams = {}
	theParams.Label_col = Label_col;
	
	report = wnd.LoadTemplateReportXML({
		xml = './edition/ColPtsClt_ColPtsBest.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'ListeClt' ,
		
		-- parent = dlg,
			
		base = base,
		body = bodyliste,
		
		params = theParams
	});
	dlg:EndModal();
end
