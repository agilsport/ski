dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');
-- version 2.3
	-- Verification edition/PtsFFS_ColPtsBest
	-- correction mise a jour du body pour edition liste par ordre de points selectionner
--Creation de la table
Dlg = {};

function Alert(txt)
	Dlg.gridMessage:AddLine(txt);
end

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function main(params)
	params = params or {};
	
	-- local verif = params.Colum_Label or 'BOF';
	-- alert('Verif='..verif);

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

	code_evenement = params.code_evenement;
	tEvenement = base:GetTable('Evenement');
	tEpreuve = base:GetTable('Epreuve');
	tResultat = base:GetTable('Resultat');
	colum_Pts = params.colum_Pts;	 	--="Pts_best" 
	LabelNc = params.LabelNc;            -- "NC_FFS"
	Colum_Label = params.Colum_Label;
	LabelPts = params.LabelPts;
	Dlg.LabelPts = params.LabelPts;
	cmd = "Select * From Evenement Where Code = "..tonumber(code_evenement);
	base:TableLoad(tEvenement, cmd)
	code_activite = tEvenement:GetCell('Code_activite', 0);
	cmd = "Select * From Epreuve Where Code_evenement = "..code_evenement..
	" Order by Code_epreuve";
	base:TableLoad(tEpreuve, cmd)
	code_discipline = tEpreuve:GetCell('Code_discipline', 0);
	--alert("code_activite "..code_activite);
	
-- Initialisation des controles ...
	Dlg.gridMessage = dlg:GetWindowName('message');
	
	local tb = dlg:GetWindowName('tb');
	if tb then
		local btn_edition = tb:AddTool('Lancement du Scrit', './res/16x16_xml.png');
		tb:AddStretchableSpace();
		local btn_close = tb:AddTool('Annuler', './res/16x16_close.png');
		tb:Realize();

		tb:Bind(eventType.MENU, LectureDonnees, btn_edition);
		tb:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL); end, btn_close);
	end
	msg = "Transfert de la Colonne point "
	msg = msg.."de l\'activite: "..code_activite.." et de la Discipline: "..code_discipline.." \n"
	msg = msg.."Vers: la Colonne "..colum_Pts.." \n"
	msg = msg.."et mettra 9999 aux non classer pour pouvoir les filtrer \n"
	Alert(msg.." Ok!!!");	
	dlg:Fit();
	dlg:ShowModal();
	dlg:Delete();
end

function LectureDonnees(evt)
	-- alert("code_evenement = "..code_evenement);
	-- alert("colum_Pts = "..colum_Pts);
	-- alert("LabelNc = "..LabelNc);
	-- alert("Colum_Label = "..Colum_Label);
	Lab_NC = LabelNc;

	cmd = "Select * From Resultat WHERE Code_evenement = "..code_evenement.." Order by Code_coureur"
	base:TableLoad(tResultat, cmd);
	-- alert("base:TableLoad(Resultat, cmd) = "..tResultat:GetNbRows()..' / '..cmd);
	bodyliste = tResultat:Copy(false);
	Nbparticipant = tResultat:GetNbRows();
	for i=0, Nbparticipant-1 do
		--resultatPts = tResultat:GetCell('Point', i)
		--alert("resultatPts "..resultatPts);
		if tResultat:GetCellDouble('Point', i) == 0.0 then 
			resultatPts = 9999;
			LabelNc = Lab_NC;
		else
			resultatPts = tResultat:GetCell('Point', i);
			LabelNc = '';
		end
		cmd = "Update Resultat SET "..colum_Pts.." = "..resultatPts..", "..Colum_Label.." = '"..LabelNc.."' Where Code_evenement = "..tonumber(code_evenement).." and Code_coureur = '"..tResultat:GetCell('Code_coureur', i).."'";
		base:Query(cmd);
		-- alert("cmd = "..cmd)
	end
	
	cmd = "Select * From Resultat WHERE Code_evenement = "..code_evenement.." Order by "..colum_Pts
	base:TableLoad(tResultat, cmd);	
	for i=0, tResultat:GetNbRows()-1 do
		bodyliste:AddRow();
		sqlTable.CopyRow(bodyliste, bodyliste:GetNbRows()-1, tResultat, i);
	end
	editionliste(evt, base, bodyliste);
	alert("Transfert des points:"..LabelPts.." Ok!!!")
	
	-- Fermeture
	bodyliste:Delete();
	dlg:EndModal(idButton.OK);

end

function editionliste(evt, base, bodyliste)
	theParams = {}
	alert("Colum_Label: "..Colum_Label);
	theParams.Colum_Label = Colum_Label;
	theParams.LabelNc = LabelNc;
	theParams.colum_Pts = colum_Pts;
	theParams.LabelPts = LabelPts;
	bodyliste:OrderBy('Point Asc' );
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
