dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
-- version 2.1


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
		width=730, -- widthControl, 
		height=300, -- heightControl, 
		label='transfert Points dans Pts_Best', 
		icon='./res/32x32_agil.png'
	});
	
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlg:LoadTemplateXML({ 
		xml = './edition/PtsFFS_ColPtsBest.xml', 		-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'PtsFFS_ColPts_best',			-- Facultatif si le node_name est unique ...	
	});

	base = sqlBase.Clone();
	code_evenement = theParams.code_evenement;
	
	-- Initialisation des controles ...
	
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
	alert("code_evenement = "..code_evenement);

	tResultat = base:GetTable('Resultat');
	cmd = "select * from Resultat where Code_evenement = "..code_evenement.." Order by Dossard"
	base:TableLoad(Resultat, cmd);
	bodyliste = tResultat:Copy(false);
	
	alert("base:TableLoad(Resultat, cmd) = "..tResultat:GetNbRows())
	Nbparticipant = tResultat:GetNbRows();
	for i=0, Nbparticipant-1 do
		resultatPts = tResultat:GetCell('Point', i)
		if resultatPts ~= '' then
			cmd = "Update Resultat SET Pts_best = '"..resultatPts.."' Where Code_evenement = "..tonumber(code_evenement).." and Code_coureur = '"..tResultat:GetCell('Code_coureur', i).."'";
			base:Query(cmd);
			alert("cmd = "..cmd)
			bodyliste:AddRow();
			sqlTable.CopyRow(bodyliste, bodyliste:GetNbRows()-1, tResultat, i);
		end
	end
	--$(Point)
	
	editionliste(evt, params, base, bodyliste);
	
	-- Fermeture
	bodyliste:Delete();
	dlg:EndModal(idButton.OK);

end

function editionliste(evt, params, base, bodyliste)
	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/PtsFFS_ColPtsBest.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'ListePoints' ,
		
		-- parent = dlg,
			
		base = base,
		body = bodyliste,
		
		params = theParams
	});
	dlg:EndModal();
end
