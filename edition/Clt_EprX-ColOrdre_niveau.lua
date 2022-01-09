dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- version 1.5

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
		label='transfert Clt dans Pts_Best', 
		icon='./res/32x32_agil.png'
	});
	
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlg:LoadTemplateXML({ 
		xml = './edition/Clt_EprX-ColOrdre_niveau.xml', 		-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'Clt_EprX-ColOrdre_niveau',			-- Facultatif si le node_name est unique ...	
	});

	base = sqlBase.Clone();
	code_evenement = tonumber(theParams.code_evenement);
	Colum_Ref = theParams.Colum_Ref;
	
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
	alert("Evt_source = "..Evt_source);
	tResultat = base:GetTable('Resultat');
	tResultat:AddColumn('CltG');
	tResultat:AddColumn('OrdreG');
	cmd = "Select  b.*, a.Clt CltG, a.Ordre_niveau OrdreG"..
			" From Resultat a, Resultat b "..
			" Where a.Code_evenement = "..Evt_source..
			" And b.Code_evenement = "..tonumber(code_evenement)..
			" And a.Code_coureur = b.Code_coureur";
	base:TableLoad(tResultat, cmd);
	
	
	-- alert("base:TableLoad(Resultat, cmd) = "..cmd)
	local Nbparticipant = tResultat:GetNbRows();
	for i=0, Nbparticipant-1 do
	-- Place = tResultat:GetCell('CltG', i);
	-- Place = tResultat:GetCell('OrdreG', i);
	Place = tResultat:GetCell(Colum_Ref, i);
	--alert("Place: "..Place);
	Critere = 'Evt_'..Evt_source;
	-- alert('Place = '..Place);
		if tonumber(Place) == 0 or Place == '' then 
			-- alert("Critere: "..Critere);
			Place = 9999; 
			Critere = 'NQ_'..Critere;
			-- alert("Critere2: "..Critere);
		end
		cmd = "Update Resultat SET Ordre_niveau = '"..Place.."', Niveau = '"..Critere.."' Where Code_evenement = "..tonumber(code_evenement).." and Code_coureur = '"..tResultat:GetCell('Code_coureur', i).."'";
		base:Query(cmd);
		-- alert("cmd = "..cmd)
	end
	
	cmd = "Select DISTINCT * From Resultat"..
			" Where Code_evenement = "..tonumber(code_evenement)..
			" And Ordre_niveau IS NULL or Ordre_niveau = ''"
	base:TableLoad(tResultat, cmd);
	-- alert("tResultat:GetNbRows(); "..tResultat:GetNbRows());
	
	local Nbparticipant = tResultat:GetNbRows();
	for i=0, Nbparticipant-1 do
		Place = 9999; 
		local Critere2 = 'Abs'..Evt_source;
		cmd = "Update Resultat SET Ordre_niveau = '"..Place.."', Niveau = '"..Critere2.."' Where Code_evenement = "..tonumber(code_evenement).." and Code_coureur = '"..tResultat:GetCell('Code_coureur', i).."'";
		base:Query(cmd);
		-- alert("cmd = "..cmd)
	end
	
	cmd = "Select * From Resultat"..
		" Where Code_evenement = "..tonumber(code_evenement)
	base:TableLoad(tResultat, cmd);
	alert("Nbparticipant_Tot; "..tResultat:GetNbRows());
	
	bodyliste = tResultat:Copy(false);
	local Nbparticipant = tResultat:GetNbRows();
	for i=0, Nbparticipant-1 do
		bodyliste:AddRow();
		sqlTable.CopyRow(bodyliste, bodyliste:GetNbRows()-1, tResultat, i);
	end
	
	editionliste(evt, params, base, bodyliste);
	
	-- Fermeture
	bodyliste:Delete();
	dlg:EndModal(idButton.OK);

end

function editionliste(evt, params, base, bodyliste)
	
		
	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/Clt_EprX-ColOrdre_niveau.xml',
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
