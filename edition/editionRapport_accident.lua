-- edition du rapport d'accident pour skiFFS
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

-- Point Entree Principal
function main(params)
	version_script = '1.0';
	
	base = sqlBase.Clone();
	
	Evenement = base:GetTable('Evenement');
	Resultat = base:GetTable('Resultat');
	Epreuve = base:GetTable('Epreuve');
	Discipline = base:GetTable('Discipline');
	TRapport = base:GetTable('Rap_accident');
	codex = Evenement:GetCell('Codex', 0);
	saison = Evenement:GetCell('Code_saison', 0);
	
	local widthMax = display:GetSize().width;
	local widthControl = math.floor((widthMax*3)/4);
	local x = math.floor((widthMax-widthControl)/2);

	local heightMax = display:GetSize().height;
	local heightControl = math.floor((heightMax *3) / 4);
	local y = math.floor((heightMax-heightControl)/2);

	dlg = wnd.CreateDialog({
		x = x,
		y = y,
		width=350, -- widthControl, 
		height=170, -- heightControl,hauteur 
		label='Choix du numero de rapport', 
		icon='./res/32x32_agil.png'
	});
	
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlg:LoadTemplateXML({ 
		xml = './edition/editionRapport_accident.xml', 		-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'NumFichier',			-- Facultatif si le node_name est unique ...	
	});

	-- Initialisation des controles ...
	local comboNumFichier = dlg:GetWindowName('NumFichier');
	
	cmd = "Select * From Rap_accident Where Code_saison = '"..saison.."' And Evt_codex = '"..codex.."' Order by Num_rapport";	
	Rapport = base:TableLoad(cmd);
		
	if tonumber(Rapport:GetNbRows()) > 0 then
		LectNumfichier = tonumber(Rapport:GetNbRows());
	else
		if dlg:MessageBox("Avertissement ?\n\nIl n'y a pas de rapport d'accident dans la base \n\n si vous souhaitez en saisir un aller dans les utilitaires", "Rapport d'accident", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
			return;
		end
		alert("pas de rapport d'accident dans la table");
		return false
	end
	-- combo NumFichier
		-- dlg:GetWindowName('NumFichier'):Clear();
	for i=0, LectNumfichier-1 do
		NumFichierAlire = Rapport:GetCellInt('Num_rapport', i);
		-- alert("NumFichier a lire = "..NumFichierAlire);
		dlg:GetWindowName('NumFichier'):Append(NumFichierAlire);
	end

		dlg:GetWindowName('NumFichier'):SetValue(0);
	
	local tb = dlg:GetWindowName('tb');
	
	
	if tb then
		local btn_edition = tb:AddTool('OK', './res/16x16_xml.png');
		tb:AddStretchableSpace();
		local btn_close = tb:AddTool('Annuler', './res/16x16_close.png');
		tb:Realize();
		tb:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.OK); end, btn_edition);
		tb:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL); end, btn_close);
	end

	
	
	if dlg:ShowModal() == idButton.OK then
			editRapport(dlg:GetWindowName('NumFichier'):GetValue('NumFichier'),base,params);
			dlg:EndModal();
	else
		return 0 ;
	end
	-- dlg:Fit();
	-- dlg:ShowModal();
	dlg:EndModal();
	-- Liberation Memoire
	dlg:Delete();
end



function editRapport(NumFichier,base,params)
	base = base;
	theParams = params;
	
	Evenement = base:GetTable('Evenement');
	Resultat = base:GetTable('Resultat');
	Epreuve = base:GetTable('Epreuve');
	Discipline = base:GetTable('Discipline');
	TRapport = base:GetTable('Rap_accident');
	codex = Evenement:GetCell('Codex', 0);
	saison = Evenement:GetCell('Code_saison', 0);
	--alert("NumFichier a lire = "..NumFichier);
	tRap_accident = base:GetTable('Rap_accident');
	base:TableLoad(tRap_accident, "Select * From Rap_accident Where Code_saison = '"..saison.."' And Evt_codex = '"..codex.."' And Num_rapport = "..NumFichier);

	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/editionRapport_accident.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'rap_accident' ,
		
		-- parent = dlg,
			
		base = base,
		
		params = theParams
	});

end

