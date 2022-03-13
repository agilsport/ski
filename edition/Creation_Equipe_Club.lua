dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- version 1.2
function Success(txt)
	app.GetAuiMessage():AddLineSuccess(txt);
end

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

--Creation de la table
Dlg = {};

function Alert(txt)
	Dlg.gridMessage:AddLine(txt);
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
		width=500, -- widthControl, 
		height=250, -- heightControl, 
		label='Creation de la zone Equipe par rapport au code club et du la zone critere', 
		icon='./res/32x32_agil.png'
	});
	
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlg:LoadTemplateXML({ 
		xml = './edition/Creation_Equipe_Club.xml', 		-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'Creation_Equipe_Club',			-- Facultatif si le node_name est unique ...	
	});

	base = sqlBase.Clone();
	code_evenement = tonumber(theParams.code_evenement);
	
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
	tResultat = base:GetTable('Resultat');
	tClub = base:GetTable('Club');
	cmd = "Select * From Resultat Where Code_evenement = "..tonumber(code_evenement)
	base:TableLoad(tResultat, cmd);
	Nbparticipant = tResultat:GetNbRows();
	for i=0, Nbparticipant-1 do
	Club = tResultat:GetCell('Club', i);
	Code_Club = Club:EscapeQuote();
	--alert("Club: "..Code_Club);
	base:TableLoad(tClub, "Select * From Club Where Nom_reduit = '"..Code_Club.."'")
	NumClub = string.format("%05d", tClub:GetCellInt('Matric', 0));
	--alert("NumClub: "..NumClub);
	Equipe = tResultat:GetCell('Critere', i);
	Composition_equipe = NumClub..'_'..Equipe;
	--alert("Composition_equipe: "..Composition_equipe);
	cmd = "Update Resultat SET Equipe = '"..(Composition_equipe):upper().."' Where Code_evenement = "..tonumber(code_evenement).." and Code_coureur = '"..tResultat:GetCell('Code_coureur', i).."'";
	base:Query(cmd);
	--alert("cmd = "..cmd)
	end

	cmd = "Select * From Resultat Where Code_evenement = "..tonumber(code_evenement)
	base:TableLoad(tResultat, cmd);
	bodyliste = tResultat:Copy(false);
	for i=0, tResultat:GetNbRows()-1 do
		bodyliste:AddRow();
		sqlTable.CopyRow(bodyliste, bodyliste:GetNbRows()-1, tResultat, i);
	end
	
	editionliste(evt, params, base, bodyliste);
	
	-- Fermeture
	Success('Transfert Ok!!!');
	bodyliste:Delete();
	dlg:EndModal(idButton.OK);

end

function editionliste(evt, params, base, bodyliste)
	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/Creation_Equipe_Club.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'ListeEquipe' ,
		
		-- parent = dlg,
			
		base = base,
		body = bodyliste,
		
		params = theParams
	});
	dlg:EndModal();
end
