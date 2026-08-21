-- Matrices / Challenges et Combinés pour skiFFS
dofile('./edition/functionPG.lua');

function CreateTableLicence()
	tLicence_Comite = sqlTable.Create();
	tLicence_Comite:AddColumn({ name = 'Numero_licence', label = 'Numero_licence', type = sqlType.CHAR, size = 20});
	tLicence_Comite:AddColumn({ name = 'Nom', label = 'Nom', type = sqlType.CHAR, size = 30, style = sqlStyle.NULL });
	tLicence_Comite:AddColumn({ name = 'Prenom', label = 'Prenom', type = sqlType.CHAR, size = 30, style = sqlStyle.NULL });
	tLicence_Comite:AddColumn({ name = 'Date_naissance', label = 'Date_naissance', type = sqlType.CHAR, size = 20, style = sqlStyle.NULL });
	tLicence_Comite:AddColumn({ name = 'Email', label = 'Email', type = sqlType.CHAR, size = 30, style = sqlStyle.NULL });
	tLicence_Comite:AddColumn({ name = 'Telephone', label = 'Telephone', type = sqlType.CHAR, size = 30, style = sqlStyle.NULL });
	tLicence_Comite:AddColumn({ name = 'Portable', label = 'Portable', type = sqlType.CHAR, size = 30, style = sqlStyle.NULL });
	tLicence_Comite:AddColumn({ name = 'Numero_club', label = 'Numero_club', type = sqlType.LONG });
	tLicence_Comite:AddColumn({ name = 'Club_nom', label = 'Club_nom', type = sqlType.CHAR, size = 30, style = sqlStyle.NULL });
	tLicence_Comite:AddColumn({ name = 'Cotis', label = 'Cotis', type = sqlType.CHAR, size = 10, style = sqlStyle.NULL });
	tLicence_Comite:AddColumn({ name = 'Saison', label = 'Saison', type = sqlType.LONG });
	tLicence_Comite:SetPrimary('Numero_licence, Numero_club, Saison');
	tLicence_Comite:SetName('Licence_Comite');
	local strCreate = tLicence_Comite:GetStringCreate(base);
	if strCreate then
		adv.Alert(strCreate);
		base:Query(strCreate);
	end
	ReplaceTableEnvironnement(tLicence_Comite, 'Licence_Comite');
end

function BuildClubs()
	tClubs = sqlTable.Create();
	tClubs:AddColumn({ name = 'Nombre_licence', label = 'Nombre_licence', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Numero_club', label = 'Numero_club', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Nom_club', label = 'Nom_club', type = sqlType.CHAR, size = 30 });
	tClubs:AddColumn({ name = 'Nombre', label = 'Nombre', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Nombre-1', label = 'Nombre-1', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Diff', label = 'Diff', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Delta', label = 'Delta', type = sqlType.DOUBLE });
	tClubs:AddColumn({ name = 'Nombre_esf', label = 'Nombre_esf', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Nombre_esf-1', label = 'Nombre_esf-1', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Nombre_competiteur', label = 'Nombre_competiteur', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Nombre_competiteur-1', label = 'Nombre_competiteur-1', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Nombre_dirigeant', label = 'Nombre_dirigeant', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Nombre_dirigeant-1', label = 'Nombre_dirigeant-1', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Nombre_loisir', label = 'Nombre_loisir', type = sqlType.LONG });
	tClubs:AddColumn({ name = 'Nombre_loisir-1', label = 'Nombre_loisir-1', type = sqlType.LONG });
	ReplaceTableEnvironnement(tClubs, '_Clubs');
	local cmd = 'SELECT Count(Club_nom) Nombre_licence, Numero_club, Club_nom Nom_club From Licence_Comite GROUP BY Club_nom, Numero_club ORDER BY Numero_club';
	-- local cmd = 'SELECT * From Licence_Comite GROUP BY Numero_club ORDER BY Numero_club';
	base:TableLoad(tClubs, cmd);
	for i = 0, tClubs:GetNbRows() -1 do
		tClubs:SetCell('Nombre', i, 0);
		tClubs:SetCell('Nombre-1', i, 0);
		tClubs:SetCell('Nombre_esf', i, 0);
		tClubs:SetCell('Nombre_esf-1', i, 0);
		tClubs:SetCell('Nombre_competiteur', i, 0);
		tClubs:SetCell('Nombre_competiteur-1', i, 0);
		tClubs:SetCell('Nombre_dirigeant', i, 0);
		tClubs:SetCell('Nombre_dirigeant-1', i, 0);
		tClubs:SetCell('Nombre_loisir', i, 0);
		tClubs:SetCell('Nombre_loisir-1', i, 0);
	end

	local club_lu = 0;
	total_nombre = 0;
	total_nombre0 = 0;
	total_esf = 0;
	total_esf0 = 0;
	total_competiteur = 0;
	total_competiteur0 = 0;
	total_dirigeant = 0;
	total_dirigeant0 = 0;
	total_loisir = 0;
	total_loisir0 = 0;
	local cotis = '';
	local row_club = 0;
	local club_encours = tLicence_Comite:GetCellInt('Numero_club', 0);
	for i = 0, tLicence_Comite:GetNbRows() -1 do
		local bolBoth = false;
		local bolN = false;

		club_lu = tLicence_Comite:GetCellInt('Numero_club', i);
		row_club = tClubs:GetIndexRow('Numero_club', club_lu);
		cotis = tLicence_Comite:GetCell('Cotis', i);
		local saison = tLicence_Comite:GetCellInt('Saison', i);
		if cotis:In('E3','CE3','CEL','CEP', 'CA2','CAP','CAL','CA3','CJ2','CJP','CJL','CJ3','D2','DP','DL','D3','RCA','PA','LA','3A','RCJ','PJ','LJ','3J','FA2','FAP','FAM','FA3','FDA','FDJ') then 
			if saison == params.saison1 then
				total_nombre = total_nombre + 1;
				tClubs:SetCell('Nombre', row_club, tClubs:GetCellInt('Nombre', row_club) + 1);
				if cotis:In('E3','CE3','CEL','CEP') then -- Nombre_esf
					total_esf = total_esf + 1;
					tClubs:SetCell('Nombre_esf', row_club, tClubs:GetCellInt('Nombre_esf', row_club) + 1);
				elseif cotis:In('CA2','CAP','CAL','CA3','CJ2','CJP','CJL','CJ3') then --Nombre_competiteur
					total_competiteur = total_competiteur + 1;
					tClubs:SetCell('Nombre_competiteur', row_club, tClubs:GetCellInt('Nombre_competiteur', row_club) + 1);
				elseif cotis:In('D2','DP','DL','D3') then --Nombre_dirigeant
					total_dirigeant = total_dirigeant + 1;
					tClubs:SetCell('Nombre_dirigeant', row_club, tClubs:GetCellInt('Nombre_dirigeant', row_club) + 1);
				elseif cotis:In('RCA','PA','LA','3A','RCJ','PJ','LJ','3J','FA2','FAP','FAM','FA3','FDA','FDJ') then --Nombre_loisir
					total_loisir = total_loisir + 1;
					tClubs:SetCell('Nombre_loisir', row_club, tClubs:GetCellInt('Nombre_loisir', row_club) + 1);
				end
			else
				total_nombre0 = total_nombre0 + 1;
				tClubs:SetCell('Nombre-1', row_club, tClubs:GetCellInt('Nombre-1', row_club) + 1);
				if cotis:In('E3','CE3','CEL','CEP') then -- Nombre_esf
					total_esf0 = total_esf0 + 1;
					tClubs:SetCell('Nombre_esf-1', row_club, tClubs:GetCellInt('Nombre_esf-1', row_club) + 1);
				elseif cotis:In('CA2','CAP','CAL','CA3','CJ2','CJP','CJL','CJ3') then --Nombre_competiteur
					total_competiteur0 = total_competiteur0 + 1;
					tClubs:SetCell('Nombre_competiteur-1', row_club, tClubs:GetCellInt('Nombre_competiteur-1', row_club) + 1);
				elseif cotis:In('D2','DP','DL','D3') then --Nombre_dirigeant
					total_dirigeant0 = total_dirigeant0 + 1;
					tClubs:SetCell('Nombre_dirigeant-1', row_club, tClubs:GetCellInt('Nombre_dirigeant-1', row_club) + 1);
				elseif cotis:In('RCA','PA','LA','3A','RCJ','PJ','LJ','3J','FA2','FAP','FAM','FA3','FDA','FDJ') then --Nombre_loisir
					total_loisir0 = total_loisir0 + 1;
					tClubs:SetCell('Nombre_loisir-1', row_club, tClubs:GetCellInt('Nombre_loisir-1', row_club) + 1);
				end
			end
		else
			adv.Alert('club '..club_lu..', licence inconnu : '..cotis);
		end

	end
end

function ChargeLicences(filename, annee)
	if annee == 1 and params.saison1 > 0 then
		base:Query('Delete From Licence_Comite Where Saison = '..params.saison1);
	end
	if annee == 0 and params.saison0 > 0 then
		base:Query('Delete From Licence_Comite Where Saison = '..params.saison0);
	end
	base:TableLoad(tLicence_Comite, 'Select * From Licence_Comite');
	local valeur = '';
	tColcsv = {};
	
	local f = io.open(filename, 'r')
	local ligne = 0;
	for lines in f:lines() do
		ligne = ligne + 1;
		alire = lines;
		tData = alire:Split(';');
		if ligne == 1 then
			if alire ~= 'numero_licence;nom;prenom;date_naissance;email;telephone;portable;numero_club;club_nom;cotis;saison' then
				app.GetAuiFrame():MessageBox(
					"Le ficher téléchargé n'a pas la structure attendue :\n"..
					'numero_licence\nnom\nprenom\ndate_naissance\nemail\ntelephone\nportable\nnumero_club\nclub_nom\ncotis\nsaison', 
					msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
					return true;
			end
		else
			if ligne == 2 then
				if annee == 1 then
					nodelicence:ChangeAttribute('saison1', tData[#tData]);
					params.saison1 = tonumber(tData[#tData]) or 0;
					doc:SaveFile();
				else
					nodelicence:ChangeAttribute('saison0', tData[#tData]);
					params.saison0 = tonumber(tData[#tData]) or 0;
					doc:SaveFile();
				end
			end

			row = tLicence_Comite:AddRow()
			for col = 1, #tData do
				if tonumber(tData[col]) == nil then
					tData[col] = string.gsub(tData[col], '"', '');
				end
				tLicence_Comite:SetCell(col-1, row, tData[col]);
			end	
		end
	end
	base:TableBulkFlush(tLicence_Comite);
	io.close(f);
end

function chargeFichierLicences(annee)
	local annee_encours = annee;
	local filename = '';
	local fileDialog = wnd.CreateFileDialog(dlgScriptLua,
		"Recherche du fichier des licenciés",
		app.GetPath(), 
		"",
		"*.csv|*.csv",
		fileDialogStyle.OPEN+fileDialogStyle.FD_FILE_MUST_EXIST
	);
	if fileDialog:ShowModal() == idButton.OK then
		filename = string.gsub(fileDialog:GetPath(), app.GetPathSeparator(), "/");
	end
	if filename:len() > 0 then
		ChargeLicences(filename, annee_encours);
	end
end

function OnPrint()
	-- Creation du Report
	params.delta = (total_nombre - total_nombre0 ) / total_nombre0;
	params.delta = Round(params.delta * 100, 2);
	params.diff = total_nombre - total_nombre0;
	for i = 0, tClubs:GetNbRows() -1 do
		local diff = tClubs:GetCellInt('Nombre', i) - tClubs:GetCellInt('Nombre-1', i);
		tClubs:SetCell('Diff', i, diff);
		if tClubs:GetCellInt('Nombre-1', i) > 0 then
			local delta = (tClubs:GetCellInt('Nombre', i) - tClubs:GetCellInt('Nombre-1', i)) / tClubs:GetCellInt('Nombre-1', i);
			local delta2 = Round(delta * 100, 2);
			tClubs:SetCell('Delta', i, delta2);
			tClubs:SetCell('Delta', i, delta2);
		end
	end
	tClubs:OrderBy('Numero_club');
	report = wnd.LoadTemplateReportXML({
		xml = './process/licencieComite.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'print',
		title = "Edition des licenciés du Comite",
		base = base,
		body = tClubs,
		paper_orientation = 'portrait',
		params = {Version = script_version, TotalDiff = params.diff, TotalDelta = params.delta, Saison = params.saison1, Saison0 = params.saison0, TotalNombre = total_nombre, TotalNombre0 = total_nombre0, TotalEsf = total_esf, TotalEsf0 = total_esf0, TotalCompetiteur = total_competiteur, TotalCompetiteur0 = total_competiteur0, TotalDirigeant = total_dirigeant, TotalDirigeant0 = total_dirigeant0, TotalLoisir = total_loisir, TotalLoisir0 = total_loisir0}
	});
	
	-- report:SetZoom(10)
end

function AffichagedlgConfiguration()
	dlgConfig = wnd.CreateDialog(
		{
		width = params.dlgPosit.width,
		height = params.dlgPosit.height,
		x = params.dlgPosit.x,
		y = params.dlgPosit.y,
		label='Configuration des paramètres', 
		icon='./res/32x32_ffs.png'
		});

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgConfig:LoadTemplateXML({ 
		xml = './process/licencieComite.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'configgenerale', 		-- Facultatif si le node_name est unique ...
		params = {Affichage = params.affichage}
	});

	-- Toolbar 
	local tbedit1 = dlgConfig:GetWindowName('tbedit1');
	tbedit1:AddStretchableSpace();
	local btnClear = tbedit1:AddTool("RAZ de tous les enregistrements", "./res/32x32_clear.png");
	tbedit1:AddSeparator();
	local btnChargerLicences1 = tbedit1:AddTool("Charger Toutes les licences année N", "./res/32x32_download.png");
	tbedit1:AddSeparator();
	local btnChargerLicences0 = tbedit1:AddTool("Charger Toutes les licences année N-x", "./res/32x32_download.png");
	tbedit1:AddSeparator();
	local btnPrint = tbedit1:AddTool("Traitement", "./res/32x32_printer.png");
	tbedit1:AddSeparator();
	local btnRetour = tbedit1:AddTool("Sortie", "./res/32x32_exit.png");
	tbedit1:AddStretchableSpace();
	tbedit1:Realize();
	
	-- Bind


	dlgConfig:Bind(eventType.MENU, 
		function(evt)
			if app.GetAuiFrame():MessageBox(
				"Confirmez-vous l'effacement de toutes les données ?", 
				"RAZ des données",
				msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
				) == msgBoxStyle.YES then
				base:Query('Delete From Licence_Comite');
				nodelicence:ChangeAttribute('saison1', 0);
				nodelicence:ChangeAttribute('saison0', 0);
				doc:SaveFile();
			end
		end, btnClear);

	dlgConfig:Bind(eventType.MENU, 
		function(evt)
			chargeFichierLicences(1);
		end, btnChargerLicences1);

	dlgConfig:Bind(eventType.MENU, 
		function(evt)
			chargeFichierLicences(0);
		end, btnChargerLicences0);
		
	dlgConfig:Bind(eventType.MENU, 
		function(evt)
			BuildClubs();
			OnPrint();
		end, btnPrint);

	tbedit1:Bind(eventType.MENU, function(evt) dlgConfig:EndModal(idButton.CANCEL) end, btnRetour);
		
	dlgConfig:Fit();
	dlgConfig:ShowModal();
	if doc then
		doc:Delete();
	end
end

function main()

	XML = app.GetPath().."/process/licencieComite.xml";
	doc = xmlDocument.Create(XML);
	local root = doc:GetRoot();
	nodelicence = doc:FindFirst('root/licence_comite');
	params = {};
	if not nodelicence then
		nodelicence = xmlNode.Create(root, xmlType.ELEMENT_NODE, "licence_comite");
		nodelicence:AddAttribute('saison1', 0);
		nodelicence:AddAttribute('saison0', 0);
		params.saison1 = 0;
		params.saison0 = 0;
		doc:SaveFile();
	else
		params.saison1 = tonumber(nodelicence:GetAttribute('saison1')) or 0;;
		params.saison0 = tonumber(nodelicence:GetAttribute('saison0')) or 0;
	end
	params.dlgPosit = {};
	params.dlgPosit.width = display:GetSize().width * .7;
	params.dlgPosit.height = 300;
	params.dlgPosit.x = (display:GetSize().width - params.dlgPosit.width) / 2;
	params.dlgPosit.y = (display:GetSize().height - params.dlgPosit.height) / 3;
	params.debug = false;
	base = base or sqlBase.Clone();
	script_version = '1.0';
	params.base_reload = nil;
	tLicence_Comite = base:GetTable('Licence_Comite');
	if tLicence_Comite == nil then
		CreateTableLicence();
		params.base_reload = true;
	end
	if params.base_reload then
		app.GetAuiFrame():MessageBox(
			"La base de donnée a nécessité la modification d'une table'.\nLe script va se fermer automatiquement.\nVous devrez quitter complètement skiFFS et relancer le programme.", 
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
			return true;
	else
		base:TableLoad(tLicence_Comite, 'Select * From Licence_Comite Order By Numero_club, Saison');
		-- adv.Alert('nombre de licences = '..tLicence_Comite:GetNbRows()..', nombre de clubs : '..tLicence_Comite:GetCounter('Club_nom'):GetNbRows());
	end

	AffichagedlgConfiguration();
end

if not params then
	main()
end
