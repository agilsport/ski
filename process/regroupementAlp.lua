-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function BuildGrille_Point_Place()		-- Création de la table Grille_Point_Place selon l'activité
	local cmd = "Select * From Place_valeur Where Code_activite = 'CHA-CMB' And Code_grille = 'FIS-CM' And Code_saison = '"..params.saison.."' Order By Place";
	base:TableLoad(tPlace_Valeur, cmd);
end


function AfficheDialogScratch()
	params.type_regroupement = 'Scratch';
	params.nodeConfig = params.doc:FindFirst('root/config');
	assert(params.nodeConfig ~= nil);
	for i =1, 4 do
		params['coursef'..i] = tonumber(params.nodeConfig:GetAttribute('coursef'..i)) or 0;
		params['coursef'..i..'_filtre'] = params.nodeConfig:GetAttribute('coursef'..i..'_filtre');
		params['courseg'..i] = 0;
		params['courseg'..i..'_filtre'] = 0;
	end
	
	if params.nodeConfig:HasAttribute('titre') then
		params.titre = params.nodeConfig:GetAttribute('titre');
	else
		params.titre = 'Regroupement de coureurs';
	end
	
	if params.nodeConfig:HasAttribute('comboColEquipe') then
		params.comboColEquipe = tonumber(params.nodeConfig:GetAttribute('comboColEquipe')) or 0;
	else
		params.comboColEquipe = 0;
	end
	
	if params.nodeConfig:HasAttribute('comboPrendre') then
		params.comboPrendre = tonumber(params.nodeConfig:GetAttribute('comboPrendre')) or 0;
	else
		params.comboPrendre = 0;
	end
	
	if params.nodeConfig:HasAttribute('comboPtsTps') then
		params.comboPtsTps = tonumber(params.nodeConfig:GetAttribute('comboPtsTps')) or 0;
	else
		params.comboPtsTps = 0;
	end
	if params.nodeConfig:HasAttribute('comboEquipeBis') then
		params.comboEquipeBis = tonumber(params.nodeConfig:GetAttribute('comboEquipeBis')) or 0;
	else
		params.comboEquipeBis = 0;
	end

	if params.nodeConfig:HasAttribute('coefManche') then
		params.coefManche = tonumber(params.nodeConfig:GetAttribute('coefManche')) or 50;
	else
		params.coefManche = 50;
	end
	if params.nodeConfig:HasAttribute('nb_filles') then
		params.nb_fille = tonumber(params.nodeConfig:GetAttribute('nb_filles')) or 2;
	else
		params.nb_fille = 2;
	end
	if params.nodeConfig:HasAttribute('comboAbdDsq') then
		params.comboAbdDsq = params.nodeConfig:GetAttribute('comboAbdDsq');
	else
		params.comboAbdDsq = 0;
	end
	if params.nodeConfig:HasAttribute('comboGarderEquipe') then
		params.comboGarderEquipe = params.nodeConfig:GetAttribute('comboGarderEquipe');
	else
		params.comboGarderEquipe = 0;
	end
	dlgConfigScratch = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Configuration du Regroupement Mixte - version '..script_version, 
		icon='./res/32x32_ffs.png'
		});
	dlgConfigScratch:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		discipline = params.discipline,
		node_value = 'configscratch',
		niveau = params.code_niveau
	});
	if params.comboPtsTps > 0 then
		params.comboGarderEquipe = 0;
	end

	-- Toolbar Principale ...
	local tbconfig = dlgConfigScratch:GetWindowName('tbconfig');
	tbconfig:AddStretchableSpace();
	local btnSave = tbconfig:AddTool("Lancer le calcul", "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	local btnScratch = tbconfig:AddTool("Sexes séparés", "./res/32x32_param.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	local message = app.GetAuiMessage();
	
	for i = 1, 4 do
		if params['coursef'..i] > 0 then
			tEvenement = base:TableLoad('Select * From Evenement Where Code = '..params['coursef'..i]);
			dlgConfigScratch:GetWindowName('coursef'..i):SetValue(params['coursef'..i]);
			dlgConfigScratch:GetWindowName('coursef'..i..'_nom'):SetValue(tEvenement:GetCell('Nom', 0));
		end
	end
	
	dlgConfigScratch:GetWindowName('comboColEquipe'):Clear();
	dlgConfigScratch:GetWindowName('comboColEquipe'):Append('Equipe');
	dlgConfigScratch:GetWindowName('comboColEquipe'):Append('Groupe');
	dlgConfigScratch:GetWindowName('comboColEquipe'):Append('Critere');
	dlgConfigScratch:GetWindowName('comboColEquipe'):Append('Club');
	dlgConfigScratch:GetWindowName('comboColEquipe'):Append('Comite');
	dlgConfigScratch:GetWindowName('comboColEquipe'):Append('Nation');
	dlgConfigScratch:GetWindowName('comboColEquipe'):SetSelection(params.comboColEquipe);

	dlgConfigScratch:GetWindowName('comboAbdDsq'):Clear();
	dlgConfigScratch:GetWindowName('comboAbdDsq'):Append('Non');
	dlgConfigScratch:GetWindowName('comboAbdDsq'):Append('Oui');
	dlgConfigScratch:GetWindowName('comboAbdDsq'):SetSelection(params.comboAbdDsq);
	
	dlgConfigScratch:GetWindowName('comboGarderEquipe'):Clear();
	dlgConfigScratch:GetWindowName('comboGarderEquipe'):Append('Non');
	dlgConfigScratch:GetWindowName('comboGarderEquipe'):Append('Oui');
	dlgConfigScratch:GetWindowName('comboGarderEquipe'):SetSelection(params.comboGarderEquipe);
	if params.comboPtsTps > 0 then
		dlgConfigScratch:GetWindowName('comboGarderEquipe'):Enable(false);
	end

	dlgConfigScratch:GetWindowName('comboPrendre'):Clear();
	dlgConfigScratch:GetWindowName('comboPrendre'):Append('Classement général');
	-- dlgConfigScratch:GetWindowName('comboPrendre'):Append('Classement général PLUS meilleure manche');
	-- dlgConfigScratch:GetWindowName('comboPrendre'):Append('Classement général OU meilleure manche');
	dlgConfigScratch:GetWindowName('comboPrendre'):SetSelection(params.comboPrendre);
	
	params.comboprendre = {};
	table.insert(params.comboprendre, 'Classement général');
	-- table.insert(params.comboprendre, 'Classement général PLUS meilleure manche');
	-- table.insert(params.comboprendre, 'Classement général OU meilleure manche');
	
	dlgConfigScratch:GetWindowName('comboPtsTps'):Clear();
	dlgConfigScratch:GetWindowName('comboPtsTps'):Append('Points Coupe du Monde');
	dlgConfigScratch:GetWindowName('comboPtsTps'):Append('Points Course');
	dlgConfigScratch:GetWindowName('comboPtsTps'):Append('Temps');
	dlgConfigScratch:GetWindowName('comboPtsTps'):SetSelection(params.comboPtsTps);


	dlgConfigScratch:GetWindowName('comboEquipeBis'):Clear();
	dlgConfigScratch:GetWindowName('comboEquipeBis'):Append('Non');
	dlgConfigScratch:GetWindowName('comboEquipeBis'):Append('Oui');
	dlgConfigScratch:GetWindowName('comboEquipeBis'):SetSelection(params.comboEquipeBis);

	if params.comboPtsTps > 0 then
		dlgConfigScratch:GetWindowName('coefManche'):Enable(false);
	end
	
	dlgConfigScratch:GetWindowName('titre'):SetValue(params.titre);
	dlgConfigScratch:GetWindowName('coefManche'):SetValue(params.coefManche);
	dlgConfigScratch:GetWindowName('nb_filles'):SetValue(params.nb_filles);
	
	
	dlgConfigScratch:Bind(eventType.COMBOBOX, 
		function(evt) 
			params.comboPtsTps = dlgConfigScratch:GetWindowName('comboPtsTps'):GetSelection();
			if params.comboPtsTps > 0 then
				dlgConfigScratch:GetWindowName('comboAbdDsq'):SetSelection(1);
				dlgConfigScratch:GetWindowName('coefManche'):SetValue(100);
				dlgConfigScratch:GetWindowName('coefManche'):Enable(false);
				dlgConfigScratch:GetWindowName('comboGarderEquipe'):SetSelection(0);
				dlgConfigScratch:GetWindowName('comboGarderEquipe'):Enable(false);
			else
				dlgConfigScratch:GetWindowName('coefManche'):Enable(true);
				dlgConfigScratch:GetWindowName('comboAbdDsq'):Enable(true);
				dlgConfigScratch:GetWindowName('comboGarderEquipe'):SetSelection(1);
				dlgConfigScratch:GetWindowName('comboGarderEquipe'):Enable(true);
			end
		end, dlgConfigScratch:GetWindowName('comboPtsTps')); 

	for i = 1, 4 do
		dlgConfigScratch:Bind(eventType.TEXT, 
			function(evt) 
				params['coursef'..i] = tonumber(dlgConfigScratch:GetWindowName('coursef'..i):GetValue()) or -1;
				tEvenement = base:TableLoad('Select Nom From Evenement Where Code = '..params['coursef'..i]);
				if tEvenement:GetNbRows() > 0 then
					dlgConfigScratch:GetWindowName('coursef'..i..'_nom'):SetValue(tEvenement:GetCell('Nom', 0));
					dlgConfigScratch:GetWindowName('filtragef'..i):Enable(true);
				else
					dlgConfigScratch:GetWindowName('coursef'..i..'_nom'):SetValue('?');
					dlgConfigScratch:GetWindowName('filtragef'..i):Enable(false);
				end
			end, dlgConfigScratch:GetWindowName('coursef'..i)); 
		dlgConfigScratch:Bind(eventType.BUTTON, 
			function(evt) 
				filtre = OnFiltrageCourse(params['coursef'..i]) ;
				if filtre:len() > 0  then
					params.nodeConfig:ChangeAttribute('coursef'..i..'_filtre', filtre);
					params['coursef'..i..'_filtre'] = filtre;
				else
					params.nodeConfig:DeleteAttribute('coursef'..i..'_filtre');
					params['coursef'..i..'_filtre'] = '';
				end
				params.doc:SaveFile();
			end, dlgConfigScratch:GetWindowName('filtragef'..i));
		dlgConfigScratch:Bind(eventType.BUTTON, 
			function(evt) 
				filtre = OnFiltrageCourse(params['coursef'..i]) ;
				if filtre:len() > 0 then
					params.nodeConfig:ChangeAttribute('coursef'..i..'_filtre', filtre);
					params['coursef'..i..'_filtre'] = filtre;
				else
					params.nodeConfig:DeleteAttribute('coursef'..i..'_filtre');
					params['coursef'..i..'_filtre'] = '';
				end
				params.doc:SaveFile();
			end, dlgConfigScratch:GetWindowName('filtrage'..i));
	end
		
	dlgConfigScratch:Bind(eventType.MENU, 
		function(evt) 
			params.nb_garcons = 0;
			params.nb_courses_garcons = 0;
			params.nb_courses_filles = 0;
			params.courses_in  = "-1";
			params.titre = dlgConfigScratch:GetWindowName('titre'):GetValue();
			for i = 1, 4 do
				params['coursef'..i] = 0;
				local nom_course = dlgConfigScratch:GetWindowName('coursef'..i..'_nom'):GetValue()
				if nom_course:len() > 0 then
					params['coursef'..i] = tonumber(dlgConfigScratch:GetWindowName('coursef'..i):GetValue()) or 0;
					params.nb_courses_filles = params.nb_courses_filles + 1;
					params.courses_in = params.courses_in..','..params['coursef'..i];
				end
				params.nodeConfig:ChangeAttribute('coursef'..i, params['coursef'..i]);
				
				params['courseg'..i] = 0;
				nom_course = dlgConfigScratch:GetWindowName('courseg'..i..'_nom'):GetValue()
				if nom_course:len() > 0 then
					params['courseg'..i] = tonumber(dlgConfigScratch:GetWindowName('courseg'..i):GetValue()) or 0;
					params.nb_courses_garcons = params.nb_courses_garcons + 1;
					params.courses_in = params.courses_in..','..params['courseg'..i];
				end
				params.nodeConfig:ChangeAttribute('courseg'..i, params['courseg'..i]);
			end
			params.comboColEquipe = dlgConfigScratch:GetWindowName('comboColEquipe'):GetSelection();
			params.comboAbdDsq = dlgConfigScratch:GetWindowName('comboAbdDsq'):GetSelection();
			params.comboPrendre = dlgConfigScratch:GetWindowName('comboPrendre'):GetSelection();
			params.comboPtsTps = dlgConfigScratch:GetWindowName('comboPtsTps'):GetSelection();
			params.comboGarderEquipe = dlgConfigScratch:GetWindowName('comboGarderEquipe'):GetSelection();
			params.comboEquipeBis = dlgConfigScratch:GetWindowName('comboEquipeBis'):GetSelection();
			if params.comboPtsTps == 0 then
				params.default_pts = 0;
			else
				params.default_pts = 10000;
			end
			params.coefManche = tonumber(dlgConfigScratch:GetWindowName('coefManche'):GetValue()) or 50;
			params.nb_filles = tonumber(dlgConfigScratch:GetWindowName('nb_filles'):GetValue()) or 0;
			params.nb_filles_bis = params.nb_filles;
			params.nodeConfig:ChangeAttribute('titre', params.titre);
			params.nodeConfig:ChangeAttribute('comboColEquipe', params.comboColEquipe);
			params.nodeConfig:ChangeAttribute('comboPrendre', params.comboPrendre);
			params.nodeConfig:ChangeAttribute('comboPtsTps', params.comboPtsTps);
			params.nodeConfig:ChangeAttribute('comboAbdDsq', params.comboAbdDsq);
			params.nodeConfig:ChangeAttribute('coefManche', params.coefManche);
			params.nodeConfig:ChangeAttribute('nb_filles', params.nb_filles);
			params.nodeConfig:ChangeAttribute('comboGarderEquipe', params.comboGarderEquipe);
			params.nodeConfig:ChangeAttribute('comboEquipeBis', params.comboEquipeBis);
			params.doc:SaveFile();
			BuildRanking();
			BuildEquipes(); 		-- tEquipe ne contient que celles qui participent au classement (nombre suffisant de coureurs)
			bouton = idButton.OK;
			dlgConfigScratch:EndModal();
		end, btnSave); 
		
	dlgConfigScratch:Bind(eventType.MENU, 
		function(evt) 
			bouton = idButton.CANCEL;
			dlgConfigScratch:EndModal();
		 end,  btnClose);

	dlgConfigScratch:Bind(eventType.MENU, 
		function(evt) 
			bouton = 5102;
			dlgConfigScratch:EndModal();
		 end,  btnScratch);
	dlgConfigScratch:Fit();
	dlgConfigScratch:ShowModal();
	if bouton == idButton.CANCEL then
		return false;
	elseif bouton == idButton.OK then
		OnPrint();
	else
		AfficheDialogSexe();
	end
	return true;
end
function AfficheDialogSexe()
	params.type_regroupement = 'Sexe';
	params.nodeConfig = params.doc:FindFirst('root/config');
	assert(params.nodeConfig ~= nil);
	for i =1, 4 do
		params['coursef'..i] = tonumber(params.nodeConfig:GetAttribute('coursef'..i)) or 0;
		params['courseg'..i] = tonumber(params.nodeConfig:GetAttribute('courseg'..i)) or 0;
		params['coursef'..i..'_filtre'] = params.nodeConfig:GetAttribute('coursef'..i..'_filtre');
		params['courseg'..i..'_filtre'] = params.nodeConfig:GetAttribute('courseg'..i..'_filtre');
	end
	
	if params.nodeConfig:HasAttribute('titre') then
		params.titre = params.nodeConfig:GetAttribute('titre');
	else
		params.titre = tEvenement:GetCell('Nom', 0);
	end
	
	if params.nodeConfig:HasAttribute('comboColEquipe') then
		params.comboColEquipe = tonumber(params.nodeConfig:GetAttribute('comboColEquipe')) or 0;
	else
		params.comboColEquipe = 0;
	end
	
	if params.nodeConfig:HasAttribute('comboPrendre') then
		params.comboPrendre = tonumber(params.nodeConfig:GetAttribute('comboPrendre')) or 0;
	else
		params.comboPrendre = 0;
	end
	
	if params.nodeConfig:HasAttribute('comboPtsTps') then
		params.comboPtsTps = tonumber(params.nodeConfig:GetAttribute('comboPtsTps')) or 0;
	else
		params.comboPtsTps = 0;
	end

	if params.nodeConfig:HasAttribute('comboEquipeBis') then
		params.comboEquipeBis = tonumber(params.nodeConfig:GetAttribute('comboEquipeBis')) or 0;
	else
		params.comboEquipeBis = 0;
	end

	if params.nodeConfig:HasAttribute('coefManche') then
		params.coefManche = tonumber(params.nodeConfig:GetAttribute('coefManche')) or 50;
	else
		params.coefManche = 50;
	end
	if params.nodeConfig:HasAttribute('nb_filles') then
		params.nb_filles = tonumber(params.nodeConfig:GetAttribute('nb_filles')) or 2;
	else
		params.nb_filles = 2;
	end
	if params.nodeConfig:HasAttribute('nb_garcons') then
		params.nb_garcons = tonumber(params.nodeConfig:GetAttribute('nb_garcons')) or 2;
	else
		params.nb_garcons = 2;
	end
	if params.nodeConfig:HasAttribute('comboAbdDsq') then
		params.comboAbdDsq = params.nodeConfig:GetAttribute('comboAbdDsq');
	else
		params.comboAbdDsq = 0;
	end
	if params.nodeConfig:HasAttribute('comboGarderEquipe') then
		params.comboGarderEquipe = params.nodeConfig:GetAttribute('comboGarderEquipe');
	else
		params.comboGarderEquipe = 0;
	end

	dlgConfig = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Configuration du Regroupement par sexe - version '..script_version, 
		icon='./res/32x32_ffs.png'
		});
	dlgConfig:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		discipline = params.discipline,
		node_value = 'config',
		niveau = params.code_niveau
	});
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);

	-- Toolbar Principale ...
	local tbconfig = dlgConfig:GetWindowName('tbconfig');
	tbconfig:AddStretchableSpace();
	local btnSave = tbconfig:AddTool("Lancer le calcul", "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	local btnScratch = tbconfig:AddTool("Regroupement Mixte", "./res/32x32_param.png");
	tbconfig:AddSeparator();
	local btnRAZ = tbconfig:AddTool("RAZ des paramètres", "./res/32x32_clear.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	local message = app.GetAuiMessage();
	
	for i = 1, 4 do
		if params['coursef'..i] > 0 then
			tEvenement = base:TableLoad('Select * From Evenement Where Code = '..params['coursef'..i]);
			dlgConfig:GetWindowName('coursef'..i):SetValue(params['coursef'..i]);
			dlgConfig:GetWindowName('coursef'..i..'_nom'):SetValue(tEvenement:GetCell('Nom', 0));
		end
		if params['courseg'..i] > 0 then
			tEvenement = base:TableLoad('Select * From Evenement Where Code = '..params['courseg'..i]);
			dlgConfig:GetWindowName('courseg'..i):SetValue(params['courseg'..i]);
			dlgConfig:GetWindowName('courseg'..i..'_nom'):SetValue(tEvenement:GetCell('Nom', 0));
		end
	end
	
	dlgConfig:GetWindowName('comboColEquipe'):Clear();
	dlgConfig:GetWindowName('comboColEquipe'):Append('Equipe');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Groupe');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Critere');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Club');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Comite');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Nation');
	dlgConfig:GetWindowName('comboColEquipe'):SetSelection(params.comboColEquipe);

	dlgConfig:GetWindowName('comboAbdDsq'):Clear();
	dlgConfig:GetWindowName('comboAbdDsq'):Append('Non');
	dlgConfig:GetWindowName('comboAbdDsq'):Append('Oui');
	dlgConfig:GetWindowName('comboAbdDsq'):SetSelection(params.comboAbdDsq);
	
	dlgConfig:GetWindowName('comboGarderEquipe'):Clear();
	dlgConfig:GetWindowName('comboGarderEquipe'):Append('Non');
	dlgConfig:GetWindowName('comboGarderEquipe'):Append('Oui');
	dlgConfig:GetWindowName('comboGarderEquipe'):SetSelection(params.comboGarderEquipe);

	dlgConfig:GetWindowName('comboPrendre'):Clear();
	dlgConfig:GetWindowName('comboPrendre'):Append('Classement général');
	dlgConfig:GetWindowName('comboPrendre'):Append('Classement général PLUS meilleure manche');
	dlgConfig:GetWindowName('comboPrendre'):Append('Classement général OU meilleure manche');
	dlgConfig:GetWindowName('comboPrendre'):SetSelection(params.comboPrendre);

	params.comboprendre = {};
	table.insert(params.comboprendre, 'Classement général');
	table.insert(params.comboprendre, 'Classement général PLUS meilleure manche');
	table.insert(params.comboprendre, 'Classement général OU meilleure manche');
	
	dlgConfig:GetWindowName('comboPtsTps'):Clear();
	dlgConfig:GetWindowName('comboPtsTps'):Append('Points Coupe du Monde');
	dlgConfig:GetWindowName('comboPtsTps'):Append('Points Course');
	dlgConfig:GetWindowName('comboPtsTps'):Append('Temps');
	dlgConfig:GetWindowName('comboPtsTps'):SetSelection(params.comboPtsTps);
	if params.comboPtsTps > 0 then
		dlgConfig:GetWindowName('coefManche'):Enable(false);
	end
	
	dlgConfig:GetWindowName('comboEquipeBis'):Clear();
	dlgConfig:GetWindowName('comboEquipeBis'):Append('Non');
	dlgConfig:GetWindowName('comboEquipeBis'):Append('Oui');
	dlgConfig:GetWindowName('comboEquipeBis'):SetSelection(params.comboEquipeBis);

	dlgConfig:GetWindowName('titre'):SetValue(params.titre);
	dlgConfig:GetWindowName('coefManche'):SetValue(params.coefManche);
	dlgConfig:GetWindowName('nb_filles'):SetValue(params.nb_filles);
	dlgConfig:GetWindowName('nb_garcons'):SetValue(params.nb_garcons);
	
	
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt) 
			params.comboPtsTps = dlgConfig:GetWindowName('comboPtsTps'):GetSelection();
			if params.comboPtsTps > 0 then
				dlgConfig:GetWindowName('coefManche'):Enable(true);
				dlgConfig:GetWindowName('comboGarderEquipe'):SetSelection(0);
				dlgConfig:GetWindowName('comboGarderEquipe'):Enable(false);
				if dlgConfig:GetWindowName('comboPtsTps'):GetSelection() == 2 then
					dlgConfig:GetWindowName('comboPrendre'):SetSelection(0);
				end
			else
				dlgConfig:GetWindowName('coefManche'):Enable(false);
				dlgConfig:GetWindowName('comboAbdDsq'):Enable(true);
				dlgConfig:GetWindowName('comboGarderEquipe'):Enable(true);
			end
		end, dlgConfig:GetWindowName('comboPtsTps')); 

	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt) 
			params.comboPrendre = dlgConfig:GetWindowName('comboPtsTps'):GetSelection();
			if dlgConfig:GetWindowName('comboPtsTps'):GetSelection() == 2 then
				dlgConfig:GetWindowName('comboPrendre'):SetSelection(0);
			end
			if dlgConfig:GetWindowName('comboPrendre'):GetSelection() > 0 then
				dlgConfig:GetWindowName('coefManche'):Enable(true);
			else 
				dlgConfig:GetWindowName('coefManche'):Enable(false);
			end
		end, dlgConfig:GetWindowName('comboPrendre')); 

	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
	for i = 1, 4 do
		dlgConfig:Bind(eventType.TEXT, 
			function(evt) 
				params['coursef'..i] = tonumber(dlgConfig:GetWindowName('coursef'..i):GetValue()) or -1;
				tEvenement = base:TableLoad('Select Nom From Evenement Where Code = '..params['coursef'..i]);
				if tEvenement:GetNbRows() > 0 then
					dlgConfig:GetWindowName('coursef'..i..'_nom'):SetValue(tEvenement:GetCell('Nom', 0));
					dlgConfig:GetWindowName('filtragef'..i):Enable(true);
				else
					dlgConfig:GetWindowName('coursef'..i..'_nom'):SetValue('?');
					dlgConfig:GetWindowName('filtragef'..i):Enable(false);
				end
			end, dlgConfig:GetWindowName('coursef'..i)); 
		dlgConfig:Bind(eventType.BUTTON, 
			function(evt) 
				filtre = OnFiltrageCourse(params['coursef'..i]) ;
				if filtre:len() > 0  then
					params.nodeConfig:ChangeAttribute('coursef'..i..'_filtre', filtre);
					params['coursef'..i..'_filtre'] = filtre;
				else
					params.nodeConfig:DeleteAttribute('coursef'..i..'_filtre');
					params['coursef'..i..'_filtre'] = '';
				end
				params.doc:SaveFile();
			end, dlgConfig:GetWindowName('filtragef'..i));
		dlgConfig:Bind(eventType.TEXT, 
			function(evt) 
				params['courseg'..i] = tonumber(dlgConfig:GetWindowName('courseg'..i):GetValue()) or -1;
				tEvenement = base:TableLoad('Select Nom From Evenement Where Code = '..params['courseg'..i]);
				if tEvenement:GetNbRows() > 0 then
					dlgConfig:GetWindowName('courseg'..i..'_nom'):SetValue(tEvenement:GetCell('Nom', 0));
					dlgConfig:GetWindowName('filtrageg'..i):Enable(true);
				else
					dlgConfig:GetWindowName('courseg'..i..'_nom'):SetValue('');
					dlgConfig:GetWindowName('filtrageg'..i):Enable(false);
				end
			end, dlgConfig:GetWindowName('courseg'..i)); 
		dlgConfig:Bind(eventType.BUTTON, 
			function(evt) 
				filtre = OnFiltrageCourse(params['courseg'..i]) ;
				if filtre:len() > 0 then
					params.nodeConfig:ChangeAttribute('courseg'..i..'_filtre', filtre);
					params['courseg'..i..'_filtre'] = filtre;
				else
					params.nodeConfig:DeleteAttribute('courseg'..i..'_filtre');
					params['courseg'..i..'_filtre'] = '';
				end
				params.doc:SaveFile();
			end, dlgConfig:GetWindowName('filtrageg'..i));
	end
		
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			params.nb_courses_filles = 0;
			params.nb_courses_garcons = 0;
			params.courses_in  = "-1";
			params.prendre = params.comboprendre[params.comboPrendre + 1];
			params.titre = dlgConfig:GetWindowName('titre'):GetValue();
			for i = 1, 4 do
				params['coursef'..i] = 0;
				params['courseg'..i] = 0;
				local nom_course = dlgConfig:GetWindowName('coursef'..i..'_nom'):GetValue();
				if nom_course:len() > 0 then
					params['coursef'..i] = tonumber(dlgConfig:GetWindowName('coursef'..i):GetValue()) or 0;
					params.nb_courses_filles = params.nb_courses_filles + 1;
					params.courses_in = params.courses_in..','..params['coursef'..i];
				end
				params.nodeConfig:ChangeAttribute('coursef'..i, params['coursef'..i]);
				
				nom_course = dlgConfig:GetWindowName('courseg'..i..'_nom'):GetValue()
				if nom_course:len() > 0 then
					params['courseg'..i] = tonumber(dlgConfig:GetWindowName('courseg'..i):GetValue()) or 0;
					params.nb_courses_garcons = params.nb_courses_garcons + 1;
					params.courses_in = params.courses_in..','..params['courseg'..i];
				end
				params.nodeConfig:ChangeAttribute('courseg'..i, params['courseg'..i]);
			end
			if params.nb_courses_filles == 0 then 
				dlgConfig:GetWindowName('nb_filles'):SetValue('');
			end
			if params.nb_courses_garcons == 0 then 
				dlgConfig:GetWindowName('nb_garcons'):SetValue('');
			end
			params.comboColEquipe = dlgConfig:GetWindowName('comboColEquipe'):GetSelection();
			params.comboAbdDsq = dlgConfig:GetWindowName('comboAbdDsq'):GetSelection();
			params.comboPrendre = dlgConfig:GetWindowName('comboPrendre'):GetSelection();
			params.comboPtsTps = dlgConfig:GetWindowName('comboPtsTps'):GetSelection();
			params.comboGarderEquipe = dlgConfig:GetWindowName('comboGarderEquipe'):GetSelection();
			params.comboEquipeBis = dlgConfig:GetWindowName('comboEquipeBis'):GetSelection();
			if params.comboPtsTps == 0 then
				params.default_pts = 0;
			else
				params.default_pts = 10000;
			end
			params.coefManche = tonumber(dlgConfig:GetWindowName('coefManche'):GetValue()) or 50;
			params.nb_filles = tonumber(dlgConfig:GetWindowName('nb_filles'):GetValue()) or 0;
			params.nb_filles_bis = params.nb_filles;
			params.nb_garcons = tonumber(dlgConfig:GetWindowName('nb_garcons'):GetValue()) or 0;
			params.nb_garcons_bis = params.nb_garcons;
			params.nodeConfig:ChangeAttribute('titre', params.titre);
			params.nodeConfig:ChangeAttribute('comboColEquipe', params.comboColEquipe);
			params.nodeConfig:ChangeAttribute('comboPrendre', params.comboPrendre);
			params.nodeConfig:ChangeAttribute('comboPtsTps', params.comboPtsTps);
			params.nodeConfig:ChangeAttribute('comboAbdDsq', params.comboAbdDsq);
			params.nodeConfig:ChangeAttribute('coefManche', params.coefManche);
			params.nodeConfig:ChangeAttribute('nb_filles', params.nb_filles);
			params.nodeConfig:ChangeAttribute('nb_garcons', params.nb_garcons);
			params.nodeConfig:ChangeAttribute('comboGarderEquipe', params.comboGarderEquipe);
			params.nodeConfig:ChangeAttribute('comboEquipeBis', params.comboEquipeBis);
			params.doc:SaveFile();
			BuildRanking();
			BuildEquipes(); 		-- tEquipe ne contient que celles qui participent au classement (nombre suffisant de coureurs)
			bouton = idButton.OK
			dlgConfig:EndModal();
		end, btnSave); 
		
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			params.comboColEquipe = 0;
			params.comboPtsTps = 2;
			params.comboPrendre = 0;
			params.comboAbdDsq = 0;
			params.coefManche = 50;
			params.nb_filles = 1;
			params.nb_garcons = 1;
			params.comboGarderEquipe = 0;
			params.comboEquipeBis = 0;
			
			for i = 1, 4 do
				params['coursef'..i] = 0;
				params['courseg'..i] = 0;
				params['coursef'..i..'_filtre'] = '';
				params['courseg'..i..'_filtre'] = '';
				dlgConfig:GetWindowName('coursef'..i):SetValue('');
				dlgConfig:GetWindowName('coursef'..i..'_nom'):SetValue('');
				dlgConfig:GetWindowName('courseg'..i):SetValue('');
				dlgConfig:GetWindowName('courseg'..i..'_nom'):SetValue('');
				params.nodeConfig:ChangeAttribute('coursef'..i, 0);
				params.nodeConfig:ChangeAttribute('courseg'..i, 0);
				params.nodeConfig:ChangeAttribute('coursef'..i..'_filtre', '');
				params.nodeConfig:ChangeAttribute('courseg'..i..'_filtre', '');
			end

			-- params.nodeConfig:ChangeAttribute('titre', '');
			params.nodeConfig:ChangeAttribute('comboColEquipe', params.comboColEquipe);
			params.nodeConfig:ChangeAttribute('comboPtsTps', params.comboPtsTps);
			params.nodeConfig:ChangeAttribute('comboPtsTps', params.comboPtsTps);
			params.nodeConfig:ChangeAttribute('comboAbdDsq', params.comboAbdDsq);
			params.nodeConfig:ChangeAttribute('coefManche', params.coefManche);
			params.nodeConfig:ChangeAttribute('nb_filles', params.nb_filles);
			params.nodeConfig:ChangeAttribute('nb_garcons', params.nb_garcons);
			params.nodeConfig:ChangeAttribute('comboGarderEquipe', params.comboGarderEquipe);
			params.nodeConfig:ChangeAttribute('comboEquipeBis', params.comboEquipeBis);
			params.doc:SaveFile();

			dlgConfig:GetWindowName('comboColEquipe'):SetSelection(params.comboColEquipe);
			dlgConfig:GetWindowName('comboPtsTps'):SetSelection(params.comboPtsTps);
			dlgConfig:GetWindowName('comboPtsTps'):SetSelection(params.comboPtsTps);
			dlgConfig:GetWindowName('comboAbdDsq'):SetValue(params.comboAbdDsq);
			dlgConfig:GetWindowName('coefManche'):SetValue(params.coefManche);
			dlgConfig:GetWindowName('nb_filles'):SetValue(params.nb_filles);
			dlgConfig:GetWindowName('nb_garcons'):SetValue(params.nb_garcons);
			dlgConfig:GetWindowName('comboGarderEquipe'):SetSelection(params.comboGarderEquipe);
			dlgConfig:GetWindowName('comboEquipeBis'):SetSelection(params.comboEquipeBis);

		 end,  btnRAZ);

	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			bouton = idButton.CANCEL;
			dlgConfig:EndModal();
		 end,  btnClose);

	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			bouton = 5105;
			dlgConfig:EndModal();
		 end,  btnScratch);
	dlgConfig:Fit();
	dlgConfig:ShowModal();
	if bouton == idButton.CANCEL then
		return false;
	elseif bouton == idButton.OK then
		OnPrint();
	else
		AfficheDialogScratch();
	end
	return true;
end
function OnFiltrageCourse(code_evenement)
	local filtre = '';
	local cmd = 'Select * From Resultat Where Code_evenement = '..code_evenement;
	base:TableLoad(tResultat, cmd);
	if tResultat:GetNbRows() > 0 then
		local filterCmd = wnd.FilterConcurrentDialog({ 
			sqlTable = tResultat,
			key = 'cmd'});
		if type(filterCmd) == 'string' and filterCmd:len() > 3 then
			filtre = filterCmd;
		end
	end
	return filtre;
end

function OnPrint()
	local utf8 = true;
	report = wnd.LoadTemplateReportXML({
		xml = './process/regroupementALP.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'print',
		title = 'Edition du Challenge',
		base = base,
		body = tEquipe,
		margin_first_top = 100,
		margin_first_left = 100,
		margin_first_right = 100,
		margin_first_bottom = 100,
		margin_top = 100,
		margin_left = 100, 
		margin_right = 100,
		margin_bottom = 100,
		paper_orientation = 'portrait',
		params = {Version = script_version, TypeRegroupement = params.type_regroupement, Titre = params.titre, CoursesIn = params.courses_in, NbCourses = tRegroupement_Courses:GetNbRows(), NbCoursesFilles = params.nb_courses_filles, NbFilles = params.nb_filles, NbCoursesGarcons = params.nb_courses_garcons, NbGarcons = params.nb_garcons, PtsTps = params.comboPtsTps, Prendre = params.comboprendre[params.comboPrendre + 1]} 
	});
	-- report:SetZoom(10)
end

function GetPointsCourse(tps, best, facteur_f)		-- application de la formule de calcul
	local pts = 10000;
	if tps > 0 then
		pts = ((tps / best) - 1) * facteur_f;
		pts = Round(pts, 2);
	end
	return pts;
end

function GetPointPlace(clt)
	local pts = 0;
	clt = tonumber(clt) or 0;
	if clt > 0 and clt <= 30 then
		pts = tPlace_Valeur:GetCellDouble('Point', clt-1);
	end
	return pts;
end

function LitRegroupementCourses();	-- lecture des courses figurant dans la valeur params.courses_in
	local cmd = 'Select * from Epreuve Where Code_evenement In('..params.courses_in..') Order By Nombre_de_manche DESC';
	tEpreuve = base:TableLoad(cmd);
	local nb_manche_max = tEpreuve:GetCellInt('Nombre_de_manche', 0);
	params.saison = tEpreuve:GetCell('Code_saison', 0);
	
	tRegroupement_Courses = sqlTable:Create('Regroupement_Courses');
	tRegroupement_Courses:AddColumn({ name = 'Code', label = 'Code', type = sqlType.LONG });
	tRegroupement_Courses:AddColumn({ name = 'Ordre', label = 'Ordre', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Id_course', label = 'Id_course', type = sqlType.CHAR, size = 10 , style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Ordre_xml', label = 'Ordre_xml', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Sexe', label = 'Sexe', type = sqlType.CHAR, size = 1 });
	tRegroupement_Courses:AddColumn({ name = 'Date', label = 'Date', type = sqlType.CHAR, size = 10 , style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Nom', label = 'Nom', type = sqlType.CHAR, size = 150, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Code_entite', label = 'Code_entite', type = sqlType.CHAR, size = 6, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Code_activite', label = 'Code_activite', type = sqlType.CHAR, size = 8, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Code_saison', label = 'Code_saison', type = sqlType.CHAR, size = 6, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Filtre', label = 'Filtre', type = sqlType.CHAR, size = 200, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Code_discipline', label = 'Code_discipline', type = sqlType.CHAR, size = 8, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Facteur_f', label = 'Facteur_f', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Nombre_de_manche', label = 'Nombre_de_manche', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Coef_manche', label = 'Coef_manche', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Tps_last', label = 'Tps_last', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Tps_first', label = 'Tps_first', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Clt_last', label = 'Clt_last', type = sqlType.LONG, style = sqlStyle.NULL });
	for i = 0, tRegroupement_Courses:GetNbColumns() -1 do
		if string.find(tRegroupement_Courses:GetColumnName(i), 'Clt') then
			tRegroupement_Courses:ChangeColumn(tRegroupement_Courses:GetColumnName(i), 'ranking');
		end
		if string.find(tRegroupement_Courses:GetColumnName(i), 'Tps') then
			tRegroupement_Courses:ChangeColumn(tRegroupement_Courses:GetColumnName(i), 'chrono');
		end
	end
	tRegroupement_Courses:SetPrimary('Code, Ordre');
	tRegroupement_Courses:RemoveAllRows();
	ReplaceTableEnvironnement(tRegroupement_Courses, '_Regroupement_Courses');
	local ordre = 0;
	tEvenement = base:GetTable('Evenement');
	for i = 1, 4 do
		if params['coursef'..i] > 0 then
			ordre =  ordre + 1;
			ordre_xml = i;
			code_evenement = params['coursef'..i];
			filtre = params['coursef'..i..'_filtre'] or '';
			cmd = 'Select * From Evenement Where Code = '..code_evenement;
			base:TableLoad(tEvenement, cmd);
			local nom = tEvenement:GetCell('Nom', 0);
			local code_entite = tEvenement:GetCell('Code_entite', 0);
			local code_activite = tEvenement:GetCell('Code_activite', 0);
			local code_saison = tEvenement:GetCell('Code_saison', 0);
			cmd = 'Select * From Epreuve Where Code_evenement = '..code_evenement.." And Code_epreuve = 1";
			base:TableLoad(tEpreuve, cmd);
			local discipline = tEpreuve:GetCell('Code_discipline', 0);
			local cmd = "Select * From Discipline Where Code_entite = '"..code_entite.."' And Code_activite = '"..code_activite.."' And Code_saison = '"..code_saison.."' And Code = '"..discipline.."'";
			base:TableLoad(tDiscipline, cmd);
			local facteur_f = tDiscipline:GetCellInt('Facteur_f', 0);

			rRegroupement_Courses = tRegroupement_Courses:GetRecord();
			rRegroupement_Courses:SetNull(); 
			
			rRegroupement_Courses:Set('Code', code_evenement);
			rRegroupement_Courses:Set('Ordre', ordre);
			rRegroupement_Courses:Set('Id_course', 'coursef'..i);
			rRegroupement_Courses:Set('Sexe', 'F');
			rRegroupement_Courses:Set('Ordre_xml', ordre_xml);
			rRegroupement_Courses:Set('Nom', nom);
			rRegroupement_Courses:Set('Code_entite', code_entite);
			rRegroupement_Courses:Set('Code_activite', code_activite);
			rRegroupement_Courses:Set('Code_saison', code_saison);

			if filtre:len() > 0 then
				filtre = "$(Sexe):In('F') and "..filtre;
				rRegroupement_Courses:Set('Filtre', filtre);
			else
				rRegroupement_Courses:Set('Filtre', "$(Sexe):In('F')");
			end

			rRegroupement_Courses:Set('Date', tEpreuve:GetCell('Date_epreuve', 0, '%2D-%2M-%4Y'));
			rRegroupement_Courses:Set('Code_discipline', tEpreuve:GetCell('Code_discipline', 0));
			rRegroupement_Courses:Set('Facteur_f', facteur_f);
			rRegroupement_Courses:Set('Nombre_de_manche', tEpreuve:GetCellInt('Nombre_de_manche', 0));
			rRegroupement_Courses:Set('Coef_manche', tEpreuve:GetCellInt('Coef_manche', 0));
			tRegroupement_Courses:AddRow();
		end
		if tonumber(params['courseg'..i]) > 0 then
			ordre =  ordre + 1;
			ordre_xml = i;
			code_evenement = params['courseg'..i];
			filtre = params['courseg'..i..'_filtre'] or '';
			cmd = 'Select * From Evenement Where Code = '..code_evenement;
			base:TableLoad(tEvenement, cmd);
			local nom = tEvenement:GetCell('Nom', 0);
			local code_entite = tEvenement:GetCell('Code_entite', 0);
			local code_activite = tEvenement:GetCell('Code_activite', 0);
			local code_saison = tEvenement:GetCell('Code_saison', 0);
			cmd = 'Select * From Epreuve Where Code_evenement = '..code_evenement.." And Code_epreuve = 1";
			base:TableLoad(tEpreuve, cmd);
			local discipline = tEpreuve:GetCell('Code_discipline', 0);
			local cmd = "Select * From Discipline Where Code_entite = '"..code_entite.."' And Code_activite = '"..code_activite.."' And Code_saison = '"..code_saison.."' And Code = '"..discipline.."'";
			base:TableLoad(tDiscipline, cmd);
			local facteur_f = tDiscipline:GetCellInt('Facteur_f', 0);
			rRegroupement_Courses = tRegroupement_Courses:GetRecord();
			rRegroupement_Courses:SetNull(); 
			
			rRegroupement_Courses:Set('Code', code_evenement);
			rRegroupement_Courses:Set('Ordre', ordre);
			rRegroupement_Courses:Set('Id_course', 'courseg'..i);
			rRegroupement_Courses:Set('Sexe', 'M');
			rRegroupement_Courses:Set('Ordre_xml', ordre_xml);
			rRegroupement_Courses:Set('Nom', tEvenement:GetCell('Nom', 0));
			rRegroupement_Courses:Set('Code_entite', tEvenement:GetCell('Code_entite', 0));
			rRegroupement_Courses:Set('Code_activite', tEvenement:GetCell('Code_activite', 0));
			rRegroupement_Courses:Set('Code_saison', tEvenement:GetCell('Code_saison', 0));
			if filtre:len() > 0 then
				filtre = "$(Sexe):In('M') and "..filtre;
				rRegroupement_Courses:Set('Filtre', filtre);
			else
				rRegroupement_Courses:Set('Filtre', "$(Sexe):In('M')");
			end
			rRegroupement_Courses:Set('Date', tEpreuve:GetCell('Date_epreuve', 0, '%2D-%2M-%4Y'));
			rRegroupement_Courses:Set('Code_discipline', tEpreuve:GetCell('Code_discipline', 0));
			rRegroupement_Courses:Set('Facteur_f', facteur_f);
			rRegroupement_Courses:Set('Nombre_de_manche', tEpreuve:GetCellInt('Nombre_de_manche', 0));
			rRegroupement_Courses:Set('Coef_manche', tEpreuve:GetCellInt('Coef_manche', 0));
			tRegroupement_Courses:AddRow();
		end
	end
	-- tRegroupement_Courses:Snapshot('tRegroupement_Courses.db3');
	tCourses = {};

	local ordre = 0;
	for i = 0, tRegroupement_Courses:GetNbRows() -1 do
		local idxcourse = i + 1;
		local ordre = tRegroupement_Courses:GetCellInt('Ordre', i);
		local ordre_xml = tRegroupement_Courses:GetCellInt('Ordre_xml', i);
		local filter = tRegroupement_Courses:GetCell('Filtre', i);
		local code = tRegroupement_Courses:GetCellInt('Code', i);
		local sexe = tRegroupement_Courses:GetCell('Sexe', i);
		local cmd = 'Select * From Resultat Where Code_evenement = '..code.." and Sexe = '"..sexe.."' Order By Tps DESC";
		base:TableLoad(tResultat, cmd);

		if filter:len() > 0 then
			tResultat:Filter(filter, true);
		end
		local tCoureurs = {};
		for row = 0, tResultat:GetNbRows() -1 do
			local code_coureur = tResultat:GetCell('Code_coureur', row);
			tCoureurs[code_coureur] = {};
		end
		local tps_last = tResultat:GetCellInt('Tps', 0);
		local clt_last = tResultat:GetCellInt('Clt', 0);
		local tps_first = -1;
		for idx = tResultat:GetNbRows() -1, 0, -1 do
			if tResultat:GetCellInt('Tps', idx) > 0 then
				tps_first = tResultat:GetCellInt('Tps', idx);
				break;
			end
		end
		tRegroupement_Courses:SetCell('Coef_manche', i, params.coefManche);
		tRegroupement_Courses:SetCell('Tps_last', i, tps_last);
		tRegroupement_Courses:SetCell('Clt_last', i, clt_last);
		tRegroupement_Courses:SetCell('Tps_first', i, tps_first);
		local nombre_de_manche = tRegroupement_Courses:GetCellInt('Nombre_de_manche',i);
		local facteur_f = tRegroupement_Courses:GetCellInt('Facteur_f',i);
		local tps_last_run = -1;
		local tps_first_run = -1;
		local runs={};
		for j = 1, nombre_de_manche do
			cmd = 'Select * From Resultat_Manche Where Code_evenement = '..code..' And Code_manche = '..j..' Order By Tps_chrono DESC';
			base:TableLoad(tResultat_Manche, cmd);
			tps_last_run = tResultat_Manche:GetCellInt('Tps_chrono', 0);
			clt_last_run = tResultat_Manche:GetCellInt('Clt_chrono', 0);
			for idx = tResultat_Manche:GetNbRows() -1, 0, -1 do
				local code_coureur = tResultat_Manche:GetCell('Code_coureur', idx);
				if type(tCoureurs[code_coureur]) == 'table' then
					tps_first_run = tResultat_Manche:GetCellInt('Tps_chrono', idx);
					if tps_first_run > 0 then
						break;
					end
				end
			end
			tRegroupement_Courses:SetCell('Tps_last_m'..j, i, tps_last_run);
			tRegroupement_Courses:SetCell('Tps_first_m'..j, i, tps_first_run);
			table.insert(runs, {Run = j, TpsFirst = tps_first_run, TpsLast = tps_last_run, CltLast = clt_last_run});
		end
		filter = filter or '';
		table.insert(tCourses, {Code_evenement = code, Ordre = ordre, Ordre_xml = ordre_xml, Filtre = filter, Sexe = sexe, TpsFirst = tps_first, TpsLast = tps_last, CltLast = clt_last, Facteur_f = facteur_f, NbManches = nombre_de_manche, Runs = runs})
	end
	tRegroupement_Courses:OrderBy('Ordre');
	if params.debug then
		tRegroupement_Courses:Snapshot('tRegroupement_Courses.db3');
	end
end

function BuildEquipes()
	local col_equipe = dlgConfig:GetWindowName('comboColEquipe'):GetValue();
	local cmd = 'Select '..col_equipe..' From Resultat Where Code_evenement In('..params.courses_in..')';
	cmd = cmd..' Group By '..col_equipe;
	tEquipe = base:TableLoad(cmd);
	tEquipe:AddColumn({ name = 'Clt', label = 'Clt', type = sqlType.LONG, style = sqlStyle.NULL});
	tEquipe:AddColumn({ name = 'OK', label = 'OK', type = sqlType.LONG, style = sqlStyle.NULL});
	tEquipe:AddColumn({ name = 'Detail_filles', label = 'Detail_filles', type = sqlType.VARCHAR, style = sqlStyle.NULL});
	tEquipe:AddColumn({ name = 'Detail_garcons', label = 'Detail_garcons', type = sqlType.VARCHAR, style = sqlStyle.NULL});
	tEquipe:AddColumn({ name = 'Pts_total', label = 'Pts_total', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tEquipe:AddColumn({ name = 'Tps_total', label = 'Tps_total', type = sqlType.LONG, style = sqlStyle.NULL});
	for i = 0, tEquipe:GetNbColumns() -1 do
		if string.find(tEquipe:GetColumnName(i), 'Clt') then
			tEquipe:ChangeColumn(tEquipe:GetColumnName(i), 'ranking');
		end
		if string.find(tEquipe:GetColumnName(i), 'Tps') then
			tEquipe:ChangeColumn(tEquipe:GetColumnName(i), 'chrono');
		end
	end

 	tEquipe:OrderBy(col_equipe);
	tEquipe:SetPrimary(col_equipe);
	ReplaceTableEnvironnement(tEquipe, '_Equipe');
	tEquipe_Bis = tEquipe:Copy();
	ReplaceTableEnvironnement(tEquipe_Bis, '_Equipe_Bis');
	
	-- on prendra le nombre de coureur indiqué dans chaque course présente
	for i = 0, tEquipe:GetNbRows() -1 do
		local OK = 1;
		local OK_BIS = 1;
		local equipe = tEquipe:GetCell(0, i):gsub("'", '_');
		local pts_total = 0;
		local tps_total = 0;
		local pts_total_bis = 0;
		local tps_total_bis = 0;
		local strGarcons = '';
		local separateur_filles = '';
		local separateur_garcons = '';
		local separateur_filles_bis = '';
		local separateur_garcons_bis = '';
		for idxcourse = 1, #tCourses do
			local nb_filles_pris = 0;
			local nb_garcons_pris = 0;
			local nb_filles_pris_bis = 0;
			local nb_garcons_pris_bis = 0;
			local ordre_xml = tCourses[idxcourse].Ordre_xml;
			local sexe_course = tCourses[idxcourse].Sexe;
			local code_evenement = tCourses[idxcourse].Code_evenement;
			local nombre_de_manche = tCourses[idxcourse].NbManches;
			local course_prise = 0;
			if params.comboPrendre == 0 then	-- général
				tMatrice_Ranking:OrderBy('Tps'..idxcourse);
			else
				if params.comboPtsTps < 3 then			-- pas en addition des temps
					tMatrice_Ranking:OrderBy('Pts'..idxcourse..'_total DESC');
				end
			end
			tMatrice_Ranking_Copy = tMatrice_Ranking:Copy();
			local filter = "$("..col_equipe.."):In('"..equipe.."') and "..tCourses[idxcourse].Filtre;
			tMatrice_Ranking_Copy:Filter(filter, true);
			-- les filles ou les mixtes
			for row = 0, tMatrice_Ranking_Copy:GetNbRows() -1 do
				if params.type_regroupement == 'Scratch' or (tMatrice_Ranking_Copy:GetCell('Sexe', row) == 'F' and tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse, row) ~= -600) then
					local pts_total_course = nil;
					local pts_total_course_bis = nil;
					if params.comboPtsTps == 0 then			-- pts place
						pts_total_course = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_total', row, 10000);
					else
						pts_total_course = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_total', row, 0);
					end
					if pts_total_course < 10000 then
						local tps_total_course = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse..'_total', row, -1);						
						local dossard = tMatrice_Ranking_Copy:GetCellInt('Dossard'..idxcourse, row);
						if dossard > 0 and tMatrice_Ranking_Copy:GetCellInt('Course'..idxcourse..'_prise', row) == 0 then
							local code_coureur = tMatrice_Ranking_Copy:GetCell('Code_coureur', row);
							local nom = tMatrice_Ranking_Copy:GetCell('Identite', row);
							local categ = tMatrice_Ranking_Copy:GetCell('Categ', row);
							local pts_course = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_total', row);
							local clt = tMatrice_Ranking_Copy:GetCellInt('Clt'..idxcourse, row);
							local tps = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse, row);
							local clt_best = tMatrice_Ranking_Copy:GetCellInt('Clt'..idxcourse..'_best', row);
							local run_best = tMatrice_Ranking_Copy:GetCellInt('Run'..idxcourse..'_best', row);
							local tps_best = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse..'_Run'..run_best, row);
							local pts_best = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_best', row);
							local tDetailFilles = {};
							local tDetailFillesBis = {};
							local ajouter_fille = false;
							local ajouter_fille_bis = false;
							if nb_filles_pris < params.nb_filles then
								nb_filles_pris = nb_filles_pris + 1;
								tMatrice_Ranking_Copy:SetCell('Course'..idxcourse..'_prise', row, 1);
								local r = tMatrice_Ranking:GetIndexRow('Code_coureur', code_coureur);
								if r >= 0 then
									tMatrice_Ranking:SetCell('Course'..idxcourse..'_prise', r, 1);
									
								end
								table.insert(tDetailFilles, 
									{Course = ordre_xml, 
									CodeEvenement = code_evenement, 
									CodeCoureur = code_coureur, 
									Dossard = dossard, 
									Nom = nom, 
									Categ = categ,
									Sexe = 'F', 
									Clt = clt, 
									PtsCourse = pts_course, 
									TpsCourse = tps_course, 
									BestClt = clt_best, 
									BestRun = run_best, 
									BestPts = pts_best, 
									BestTps = tps_best,
									PtsTotal = pts_total_course,
									TpsTotal = tps_total_course});
								local xDetailFilles = {Detail = tDetailFilles};
								local jsontxt = table.ToStringJSON(xDetailFilles, false);
								pts_total = pts_total + pts_total_course;
								tps_total = tps_total + tps_total_course;
								jsontxt = separateur_filles..jsontxt;
								tEquipe:SetCell('Detail_filles', i, tEquipe:GetCell('Detail_filles', i)..jsontxt);
								separateur_filles = '|';
							elseif params.comboEquipeBis == 1 then
								if nb_filles_pris_bis < params.nb_filles and tMatrice_Ranking_Copy:GetCellInt('Course'..idxcourse..'_prise', row) == 0 then
									nb_filles_pris_bis = nb_filles_pris_bis + 1;
									table.insert(tDetailFillesBis, 
										{Course = ordre_xml, 
										CodeEvenement = code_evenement, 
										CodeCoureur = code_coureur, 
										Dossard = dossard, 
										Nom = nom, 
										Categ = categ, 
										Sexe = 'F', 
										Clt = clt, 
										PtsCourse = pts_course, 
										TpsCourse = tps_course, 
										BestClt = clt_best, 
										BestRun = run_best, 
										BestPts = pts_best, 
										BestTps = tps_best,
										PtsTotal = pts_total_course,
										TpsTotal = tps_total_course});
									local xDetailFilles = {Detail = tDetailFillesBis};
									local jsontxt = table.ToStringJSON(xDetailFilles, false);
									pts_total_bis = pts_total_bis + pts_total_course;
									tps_total_bis = tps_total_bis + tps_total_course;
									jsontxt = separateur_filles_bis..jsontxt;
									tEquipe_Bis:SetCell('Detail_filles', i, tEquipe_Bis:GetCell('Detail_filles', i)..jsontxt);
									separateur_filles_bis = '|';
								else
									course_prise = 1;
								end
							end
						end
					end
				end
			end
			-- les garçons
			if params.type_regroupement == 'Sexe' and  tCourses[idxcourse].Sexe == 'M'  then
				for row = 0, tMatrice_Ranking_Copy:GetNbRows() -1 do
					if tMatrice_Ranking_Copy:GetCell('Sexe', row) == 'M' and tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse, row) ~= -600 then
						local pts_total_course = nil;
						local pts_total_course_bis = nil;
						if params.comboPtsTps == 0 then			-- pts place
							pts_total_course = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_total', row, 10000);
						else
							pts_total_course = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_total', row, 0);
						end
						if pts_total_course < 10000 then
							local tps_total_course = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse..'_total', row, -1);
							local dossard = tMatrice_Ranking_Copy:GetCellInt('Dossard'..idxcourse, row);
							if dossard > 0 and tMatrice_Ranking_Copy:GetCellInt('Course'..idxcourse..'_prise', row) == 0 then
								local code_coureur = tMatrice_Ranking_Copy:GetCell('Code_coureur', row);
								local nom = tMatrice_Ranking_Copy:GetCell('Identite', row);
								local categ = tMatrice_Ranking_Copy:GetCell('Categ', row);
								local pts_course = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_total', row);
								local clt = tMatrice_Ranking_Copy:GetCellInt('Clt'..idxcourse, row);
								local tps = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse, row);
								local clt_best = tMatrice_Ranking_Copy:GetCellInt('Clt'..idxcourse..'_best', row);
								local run_best = tMatrice_Ranking_Copy:GetCellInt('Run'..idxcourse..'_best', row);
								local tps_best = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse..'_Run'..run_best, row);
								local pts_best = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_best', row);
								local tDetailGarcons = {};
								local tDetailGarconssBis = {};
								local ajouter_garcon = false;
								local ajouter_garcon_bis = false;
								if nb_garcons_pris < params.nb_garcons then
									nb_garcons_pris = nb_garcons_pris + 1;
									tMatrice_Ranking_Copy:SetCell('Course'..idxcourse..'_prise', row, 1);
									local r = tMatrice_Ranking:GetIndexRow('Code_coureur', code_coureur);
									if r >= 0 then
										tMatrice_Ranking:SetCell('Course'..idxcourse..'_prise', r, 1);
										
									end
									table.insert(tDetailGarcons, 
										{Course = ordre_xml, 
										CodeEvenement = code_evenement, 
										CodeCoureur = code_coureur, 
										Dossard = dossard, 
										Nom = nom, 
										Categ = categ,
										Sexe = 'M', 
										Clt = clt, 
										PtsCourse = pts_course, 
										TpsCourse = tps_course, 
										BestClt = clt_best, 
										BestRun = run_best, 
										BestPts = pts_best, 
										BestTps = tps_best,
										PtsTotal = pts_total_course,
										TpsTotal = tps_total_course});
									local xDetailGarcons = {Detail = tDetailGarcons};
									local jsontxt = table.ToStringJSON(xDetailGarcons, false);
									pts_total = pts_total + pts_total_course;
									tps_total = tps_total + tps_total_course;
									jsontxt = separateur_garcons..jsontxt;
									tEquipe:SetCell('Detail_garcons', i, tEquipe:GetCell('Detail_garcons', i)..jsontxt);
									separateur_garcons = '|';
								elseif params.comboEquipeBis == 1 then
									if nb_garcons_pris_bis < params.nb_garcons and tMatrice_Ranking_Copy:GetCellInt('Course'..idxcourse..'_prise', row) == 0 then
										nb_garcons_pris_bis = nb_garcons_pris_bis + 1;
										table.insert(tDetailGarconssBis, 
											{Course = ordre_xml, 
											CodeEvenement = code_evenement, 
											CodeCoureur = code_coureur, 
											Dossard = dossard, 
											Nom = nom, 
											Categ = categ, 
											Sexe = 'M', 
											Clt = clt, 
											PtsCourse = pts_course, 
											TpsCourse = tps_course, 
											BestClt = clt_best, 
											BestRun = run_best, 
											BestPts = pts_best, 
											BestTps = tps_best,
											PtsTotal = pts_total_course,
											TpsTotal = tps_total_course});
										local xDetailGarcons = {Detail = tDetailGarconssBis};
										local jsontxt = table.ToStringJSON(xDetailGarcons, false);
										pts_total_bis = pts_total_bis + pts_total_course;
										tps_total_bis = tps_total_bis + tps_total_course;
										jsontxt = separateur_garcons_bis..jsontxt;
										tEquipe_Bis:SetCell('Detail_garcons', i, tEquipe_Bis:GetCell('Detail_garcons', i)..jsontxt);
										separateur_garcons_bis = '|';
									else
										course_prise = 1;
									end
								end
							end
						end
					end
				end
			end
		end
		nb_filles = 0;
		nb_garcons = 0;
		local tdetailfille = tEquipe:GetCell('Detail_filles', i):Split('|');
		if tEquipe:GetCell('Detail_filles', i):len() > 0 then
			nb_filles = #tdetailfille;
		end
		local critere_filles = params.nb_filles * params.nb_courses_filles;
		local critere_garcons = params.nb_garcons * params.nb_courses_garcons;
		local tdetailgarcons = tEquipe:GetCell('Detail_garcons', i):Split('|');
		if tEquipe:GetCell('Detail_garcons', i):len() > 0 then
			nb_garcons = #tdetailgarcons;
		end
		if params.nb_filles > 0 and nb_filles < critere_filles then
			OK = 0;
		end
		if params.nb_garcons > 0 and nb_garcons < critere_garcons then
			OK = 0;
		end
		tEquipe:SetCell('OK',i, OK);
		tEquipe:SetCell('Pts_total',i, pts_total);
		tEquipe:SetCell('Tps_total',i, tps_total);
		
		tdetailfille = tEquipe_Bis:GetCell('Detail_filles', i):Split('|');
		nb_filles = #tdetailfille;
		tdetailgarcons = tEquipe_Bis:GetCell('Detail_garcons', i):Split('|');
		nb_garcons = #tdetailgarcons;
		if params.nb_filles > 0 and nb_filles < (params.nb_filles * params.nb_courses_filles) then
			OK_BIS = 0;
		end
		if params.nb_garcons > 0 and nb_garcons < (params.nb_garcons * params.nb_courses_garcons) then
			OK_BIS = 0;
		end
		tEquipe_Bis:SetCell('OK',i, OK_BIS);
		tEquipe_Bis:SetCell('Pts_total',i, pts_total_bis);
		tEquipe_Bis:SetCell('Tps_total',i, tps_total_bis);
	end
	tMatrice_Ranking:Snapshot('tMatrice_Ranking.db3');
	if params.comboEquipeBis == 1 then
		for i = 0, tEquipe_Bis:GetNbRows() -1 do
			if tEquipe_Bis:GetCell('Detail_filles', i):len() > 0 or tEquipe_Bis:GetCell('Detail_garcons', i):len() > 0 then		-- il faut créer un nouveau record avec l'équipe bis
				local rEquipe = tEquipe:GetRecord();
				rEquipe:SetNull(); 
				rEquipe:Set(col_equipe, tEquipe_Bis:GetCell(col_equipe, i)..' BIS');
				rEquipe:Set('OK', tEquipe_Bis:GetCell('OK', i));
				rEquipe:Set('Detail_filles', tEquipe_Bis:GetCell('Detail_filles', i));
				rEquipe:Set('Detail_garcons', tEquipe_Bis:GetCell('Detail_garcons', i));
				rEquipe:Set('Pts_total', tEquipe_Bis:GetCell('Pts_total', i));
				rEquipe:Set('Tps_total', tEquipe_Bis:GetCell('Tps_total', i));
				tEquipe:AddRow();
			end
		end
	end
	-- le cas échéant, les équipes BIS ont été ajoutées dans la table tEquipe
	local filter = '$(OK):In(1)';
	if params.debug then
		tEquipe:Snapshot('tEquipe.db3');
	end
	if params.comboGarderEquipe == 0 then
		tEquipe:Filter(filter, true);
	end
	if params.comboPtsTps == 0 then
		tEquipe:SetRanking('Clt', 'Pts_total DESC', '');
	elseif params.comboPtsTps == 1 then
		tEquipe:SetRanking('Clt', 'Pts_total ASC', '');
	elseif params.comboPtsTps == 2 then
		tEquipe:SetRanking('Clt', 'Tps_total ASC', '');
	end
	tEquipe:OrderBy('Clt');
end

function BuildRanking();
	LitRegroupementCourses();
	BuildGrille_Point_Place();
	cmd = 'Select Code_coureur From Resultat Where Code_evenement in('..params.courses_in..') ';
	cmd = cmd..' Group By Code_coureur';
	tMatrice_Ranking = base:TableLoad(cmd);
	ReplaceTableEnvironnement(tMatrice_Ranking, '_tMatrice_Ranking');
    tMatrice_Ranking:AddColumn({ name = 'Filtrer', label = 'Filtrer', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Nom', label = 'Nom', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Prenom', label = 'Prenom', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Identite', label = 'Identite', type = sqlType.CHAR, width = '61', style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Sexe', label = 'Sexe', type = sqlType.CHAR, width = '1', style = sqlStyle.NULL});
    tMatrice_Ranking:AddColumn({ name = 'An', label = 'An', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Categ', label = 'Categ', type = sqlType.CHAR, width = '8', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Nation', label = 'Nation', type = sqlType.CHAR, width = '3', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Comite', label = 'Comite', type = sqlType.CHAR, width = '3', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Club', label = 'Club', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Groupe', label = 'Groupe', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Equipe', label = 'Equipe', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Critere', label = 'Critere', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Point', label = 'Point', type = sqlType.DOUBLE, style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Pts', label = 'Pts', type = sqlType.DOUBLE, style = sqlStyle.NULL});

	for idxcourse = 1, #tCourses do
		local discipline = tCourses[idxcourse].Discipline;
		tMatrice_Ranking:AddColumn({ name = 'Code_evenement'..idxcourse, label = 'Code_evenement'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Ordre_xml'..idxcourse, label = 'Ordre_xml'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Course'..idxcourse..'_prise', label = 'Course'..idxcourse..'_prise', type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Dossard'..idxcourse, label = 'Dossard'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Clt'..idxcourse, label = 'Clt'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse, label = 'Tps'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse, label = 'Pts'..idxcourse, type = sqlType.DOUBLE, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Run'..idxcourse..'_best', label = 'Run'..idxcourse..'_best', type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Clt'..idxcourse..'_best', label = 'Clt'..idxcourse..'_best', type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse..'_best', label = 'Pts'..idxcourse..'_best', type = sqlType.DOUBLE, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse..'_total', label = 'Pts'..idxcourse..'_total', type = sqlType.DOUBLE, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse..'_total', label = 'Tps'..idxcourse..'_total', type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse..'_best', label = 'Tps'..idxcourse..'_best', type = sqlType.LONG, style = sqlStyle.NULL});
		for idxrun = 1, tCourses[idxcourse].NbManches do
			tMatrice_Ranking:AddColumn({ name = 'Clt'..idxcourse..'_run'..idxrun, label = 'Clt'..idxcourse..'_run'..idxrun, type = sqlType.LONG, style = sqlStyle.NULL});
			tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse..'_run'..idxrun, label = 'Tps'..idxcourse..'_run'..idxrun, type = sqlType.LONG, style = sqlStyle.NULL});
			tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse..'_run'..idxrun, label = 'Pts'..idxcourse..'_run'..idxrun, type = sqlType.DOUBLE, style = sqlStyle.NULL});
		end
	end

	for i = 0, tMatrice_Ranking:GetNbColumns() -1 do
		if string.find(tMatrice_Ranking:GetColumnName(i), 'Clt') then
			tMatrice_Ranking:ChangeColumn(tMatrice_Ranking:GetColumnName(i), 'ranking');
		end
		if string.find(tMatrice_Ranking:GetColumnName(i), 'Tps') then
			tMatrice_Ranking:ChangeColumn(tMatrice_Ranking:GetColumnName(i), 'chrono');
		end
	end
	for idxcourse = 1, #tCourses do
		local nombre_de_manche = tCourses[idxcourse].NbManches;
		local code_evenement = tCourses[idxcourse].Code_evenement;
		local ordre_xml = tCourses[idxcourse].Ordre_xml;
		local cmd = 'Select * From Resultat Where Code_evenement = '..code_evenement..' Order By Tps ASC';
		local coltps = 'Tps'..idxcourse;
		local colclt = 'Clt'..idxcourse;
		base:TableLoad(tResultat, cmd);
		tResultat:Filter(tCourses[idxcourse].Filtre, true);
		tResultat:SetRanking('Cltc', 'Tps');
		tResultat:OrderBy('Clt');
		for row = 0, tResultat:GetNbRows() -1 do
			local code_coureur = tResultat:GetCell('Code_coureur', row);
			local r = tMatrice_Ranking:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then
				tMatrice_Ranking:SetCell('Filtrer', row, 1);
				tMatrice_Ranking:SetCell('Nom', r, tResultat:GetCell('Nom', row));
				tMatrice_Ranking:SetCell('Prenom', r, tResultat:GetCell('Prenom', row));
				tMatrice_Ranking:SetCell('Identite', r, tResultat:GetCell('Nom', row)..' '..tResultat:GetCell('Prenom', row));
				tMatrice_Ranking:SetCell('Sexe', r, tResultat:GetCell('Sexe', row));
				tMatrice_Ranking:SetCell('An', r, tResultat:GetCellInt('An', row));
				tMatrice_Ranking:SetCell('Categ', r, tResultat:GetCell('Categ', row));
				tMatrice_Ranking:SetCell('Nation', r, tResultat:GetCell('Nation', row));
				tMatrice_Ranking:SetCell('Comite', r, tResultat:GetCell('Comite', row));
				tMatrice_Ranking:SetCell('Club', r, tResultat:GetCell('Club', row):gsub("'","_"));
				tMatrice_Ranking:SetCell('Groupe', r, tResultat:GetCell('Groupe', row):gsub("'","_"));
				tMatrice_Ranking:SetCell('Equipe', r, tResultat:GetCell('Equipe', row):gsub("'","_"));
				tMatrice_Ranking:SetCell('Critere', r, tResultat:GetCell('Critere', row):gsub("'","_"));
				tMatrice_Ranking:SetCell('Dossard'..idxcourse, r, tResultat:GetCell('Dossard', row));
				tMatrice_Ranking:SetCell('Code_evenement'..idxcourse, r, code_evenement);
				tMatrice_Ranking:SetCell('Ordre_xml'..idxcourse, r, ordre_xml);
				tMatrice_Ranking:SetCell('Clt'..idxcourse, r, tResultat:GetCellInt('Cltc', row));
				local tps = tResultat:GetCellInt('Tps', row, -1);
				if tps < 0 then
					if params.comboAbdDsq == 1 then
						tps = tCourses[idxcourse].TpsLast;
					end
				end
				tMatrice_Ranking:SetCell(coltps, r, tps);
				for idxrun = 1, nombre_de_manche do
					local coltpsrun = 'Tps'..idxcourse..'_run'..idxrun;
					local tpsm = -1;
					local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..code_evenement..' And Code_manche = '..idxrun.." And Code_coureur = '"..code_coureur.."'"; 
					base:TableLoad(tResultat_Manche, cmd);
					tpsm = tResultat_Manche:GetCellInt('Tps_chrono', 0, -1);
					if tpsm < 0 then
						if params.comboAbdDsq == 1 then
							tpsm = tCourses[idxcourse].Runs[idxrun].TpsLast;
						end
					end
					tMatrice_Ranking:SetCell(coltpsrun, r, tpsm);
				end
			end
			
		end
		-- tMatrice_Ranking:SetRanking(colclt, coltps, 'OK > 0');
		for idxrun = 1, nombre_de_manche do
			local colcltrun = 'Clt'..idxcourse..'_run'..idxrun;
			local coltpsrun = 'Tps'..idxcourse..'_run'..idxrun;
			tMatrice_Ranking:SetRanking(colcltrun, coltpsrun, 'OK > 0');
		end
	end
	local filter = '$(Filtrer):In(1)';
	tMatrice_Ranking:Filter(filter, true);
	for row = 0, tMatrice_Ranking:GetNbRows() -1 do
		local pts_total = params.default_pts;
		local pts_total_course = params.default_pts;
		local tps_total_course = 3600000;
		for idxcourse = 1, #tCourses do
			local colclt = 'Clt'..idxcourse;
			local coltps = 'Tps'..idxcourse;
			local colpts = 'Pts'..idxcourse;
			local colbestrun = 'Run'..idxcourse..'_best';
			local colbestclt = 'Clt'..idxcourse..'_best';
			local colbestpts = 'Pts'..idxcourse..'_best';
			local colbesttps = 'Tps'..idxcourse..'_best';
			local colptstotal = 'Pts'..idxcourse..'_total';
			local coltpstotal = 'Tps'..idxcourse..'_total';
			local pts = params.default_pts;
			local clt = tMatrice_Ranking:GetCellInt(colclt, row, -1);
			local tps = tMatrice_Ranking:GetCellInt(coltps, row, -1);
			if tMatrice_Ranking:GetCellInt('Code_evenement'..idxcourse, row) > 0 then
				if params.comboPtsTps == 0 then
					if clt > 0 then
						pts = GetPointPlace(clt);
						tMatrice_Ranking:SetCell(colpts, row, pts)
					end
				else
					if tps > 0 then
						pts = GetPointsCourse(tps, tCourses[idxcourse].TpsFirst, tCourses[idxcourse].Facteur_f)		-- application de la formule de calcul
						tMatrice_Ranking:SetCell(colpts, row, pts);
					end
				end
				local nb_run = tCourses[idxcourse].NbManches;
				local best_pts = nil;
				local best_clt = 10000;
				local best_run = -1;
				local best_tps = nil;
				for idxrun = 1, nb_run do
					local pts_run = nil;
					local colcltrun = 'Clt'..idxcourse..'_run'..idxrun;
					local coltpsrun = 'Tps'..idxcourse..'_run'..idxrun;
					local colptsrun = 'Pts'..idxcourse..'_run'..idxrun;
					local clt_run = tMatrice_Ranking:GetCellInt(colcltrun, row, -1);
					local tps_run = tMatrice_Ranking:GetCellInt(coltpsrun, row, -1);
					if clt_run > 0 then
						if params.comboPtsTps == 0 then
							pts_run = GetPointPlace(clt_run) * params.coefManche / 100;
						elseif params.comboPtsTps == 1 then
							pts_run = GetPointsCourse(tps_run, tCourses[idxcourse].Runs[idxrun].TpsFirst, tCourses[idxcourse].Facteur_f)		-- application de la formule de calcul
						end
						tMatrice_Ranking:SetCell(colptsrun, row, pts_run);				
					end
					if not best_pts then
						if pts_run then
							best_run = idxrun;
							best_pts = pts_run;
							best_clt = clt_run;
							best_tps = tps_run
						end
					else
						pts_run = pts_run or params.default_pts;
						if params.comboPtsTps == 0 then		-- points place
							if pts_run > best_pts then
								best_run = idxrun;
								best_pts = pts_run;
								best_clt = clt_run;
								best_tps = tps_run
							end
						else
							if pts_run < best_pts then
								best_run = idxrun;
								best_pts = pts_run;
								best_clt = clt_run;
								best_tps = tps_run
							end
						end
					end
				end
				tMatrice_Ranking:SetCell(colbestrun, row, best_run);
				if best_run > 0 then
					tMatrice_Ranking:SetCell(colbestclt, row, best_clt);
					tMatrice_Ranking:SetCell(colbestpts, row, best_pts);
					tMatrice_Ranking:SetCell(colbesttps, row, best_tps);
				end
				if tps > 0 then 
					tps_total_course = tps;
				end
				if params.comboPrendre == 0 then				-- géréral
					if tps > 0 then
						pts_total_course = pts;
					end
				elseif params.comboPrendre == 1 then			-- général PLUS meilleure manche
					pts_total_course = pts;
					if best_run > 0 then
						if nb_run > 1 then
							pts_total_course = pts_total_course + best_pts;
						end	
					end
				elseif params.comboPrendre == 2 then			-- général OU meilleure manche
					if best_run  > 0  then
						if params.comboPtsTps == 0 then				-- Pts CDM
							pts_total_course = math.max(pts, best_pts);
						else
							pts_total_course = math.min(pts, best_pts);
						end	
					end
				end
				tMatrice_Ranking:SetCell(colptstotal, row, pts_total_course);
				if tps > 0 then
					tMatrice_Ranking:SetCell(coltpstotal, row, tps_total_course);
				end
				pts_total = pts_total + pts_total_course;
			end				
		end
		tMatrice_Ranking:SetCell('Pts', row, pts_total);
	end
	tMatrice_Ranking:OrderBy('Sexe, Identite');
	if params.debug then
		tMatrice_Ranking:Snapshot('tMatrice_Ranking.db3');
	end
end

function main(params_c)
	params = {};
	params.code_evenement = params_c.code_evenement;
	if params.code_evenement < 0 then
		return;
	end
	params.width = (display:GetSize().width * 2) / 3;
	params.height = display:GetSize().height / 2;
	params.x = (display:GetSize().width - params.width) / 2;
	params.y = 0;
	params.debug = false;
	script_version = "2.2";
	if app.GetVersion() >= '5.0' then 
		-- vérification de l'existence d'une version plus récente du script.
		-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2
		indice_return = 10;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	else
		app.GetAuiFrame():MessageBox(
			"Vous devez mettre à jour le logiciel avec\nla dernière version stable (téléchargement -> Logiciel).", 
			"Mise à jour du logiciel",
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
		return true;
	end

	local updatefile = './tmp/updatesPG.txt';
	if app.FileExists(updatefile) then
		local f = io.open(updatefile, 'r')
		for lines in f:lines() do
			alire = lines;
		end
		io.close(f);
		app.RemoveFile(updatefile);
		app.LaunchDefaultEditor('./'..alire);
	end
	base = base or sqlBase.Clone();
	tPlace_Valeur = base:GetTable('Place_Valeur');
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	tResultat = base:GetTable('Resultat');
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tResultat_Manche = base:GetTable('Resultat_Manche');
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	tDiscipline = base:GetTable('Discipline');
	-- Ouverture Document XML 
	XML = "./process/regroupementALP.xml";
	params.doc = xmlDocument.Create(XML);
	assert(params.doc~= nil);
	AfficheDialogSexe();
end




