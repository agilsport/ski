-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function CreateEquipe();
	tEquipe = sqlTable.Create("Equipe");
	tEquipe:AddColumn({ name = "Id", label = "Id", type = sqlType.LONG });
	tEquipe:AddColumn({ name = "Type_equipe", label = "Type_equipe", type = sqlType.CHAR, size = 5 });
	tEquipe:AddColumn({ name = "Libelle", label = "Libelle", type = sqlType.CHAR, size = 45, style = sqlStyle.NULL });
	tEquipe:AddColumn({ name = "Nom", label = "Nom", type = sqlType.CHAR, size = 45, style = sqlStyle.NULL });
	tEquipe:SetPrimary('Id, Type_equipe');
	tEquipe:SetName('Equipe');
	local strCreate = tEquipe:GetStringCreate(base);
	if strCreate then
		base:Query(strCreate);
	end
	ReplaceTableEnvironnement(tEquipe, 'Equipe');
	tEquipe = base:GetTable('Equipe');
end

function CreatetEquipe_Club();
	tEquipe_club = sqlTable.Create("Equipe_Club");
	tEquipe_club:AddColumn({ name = "Matric", label = "Matric", type = sqlType.LONG });
	tEquipe_club:AddColumn({ name = "Type_equipe", label = "Type_equipe", type = sqlType.CHAR, size = 5 });
	tEquipe_club:AddColumn({ name = "Code_equipe", label = "Code_equipe", type = sqlType.LONG, style = sqlStyle.NULL });
	tEquipe_club:SetPrimary('Matric, Type_equipe');
	tEquipe_club:SetName('Equipe_Club');
	local strCreate = tEquipe_club:GetStringCreate(base);
	if strCreate then
		base:Query(strCreate);
	end
	ReplaceTableEnvironnement(tEquipe_club, 'Equipe_Club');
	tEquipe_club = base:GetTable('Equipe_Club');
end

function OnMarquage();
	local col_equipe = dlgConfig:GetWindowName('comboColEquipe'):GetValue();
	local courses = dlgConfig:GetWindowName('courses'):GetValue();
	local type_equipe = dlgConfig:GetWindowName('comboTypeEquipe'):GetValue();

	local cmd = "SELECT ec.Code_equipe, e.*, c.*"..
				" FROM Equipe_club ec"..
				" LEFT JOIN Equipe e ON ec.Type_equipe = e.Type_equipe AND ec.Code_equipe = e.Id"..
				" LEFT JOIN Club c ON c.Matric = ec.Matric"..
				" Where ec.Type_equipe = '"..type_equipe.."'"..
				" Order BY ec.Matric";
	tEquipe_Marquage = base:TableLoad(cmd);
	for i = 0, tEquipe_Marquage:GetNbRows() -1 do
		local club = tEquipe_Marquage:GetCell('Nom_reduit', i);
		local nom_equipe = tEquipe_Marquage:GetCell('Nom', i);
		local cmd = "Update Resultat Set "..col_equipe..' = "'..nom_equipe..'" Where Club = "'..club..'" And Code_evenement In('..courses..')';
		base:Query(cmd);
	end
end

function SetcomboCoursesPrises()
	local tCodes = dlgConfig:GetWindowName('courses'):GetValue():Split(',');
	dlgConfig:GetWindowName('courses'):GetValue():Split(',');
	dlgConfig:GetWindowName('comboCoursesPrises'):Clear();
	for i = 1, #tCodes do
		local code = tCodes[i];
		local cmd = 'Select * From Evenement Where Code = '..code;
		base:TableLoad(tEvenement, cmd);
		dlgConfig:GetWindowName('comboCoursesPrises'):Append(tEvenement:GetCell('Code', 0)..' - '..tEvenement:GetCell('Nom', 0));
		dlgConfig:GetWindowName('comboCoursesPrises'):SetSelection(i-1);
	end
	dlgConfig:GetWindowName('coursex'):SetValue('');
	dlgConfig:GetWindowName('evenementx'):SetValue('');
end
function OnGetCourse(evt)
	local courses = dlgConfig:GetWindowName('courses'):GetValue();
	local virgule = '';
	if courses:len() > 0 then
		virgule = ',';
	end
	local code = tonumber(dlgConfig:GetWindowName('coursex'):GetValue()) or 0;
	if code > 0 then
		local cmd = 'Select * From Evenement Where Code = '..code;
		base:TableLoad(tEvenement, cmd);
		if tEvenement:GetNbRows() > 0 then
			dlgConfig:GetWindowName('evenementx'):SetValue(tEvenement:GetCell('Nom', 0));
		else
			dlgConfig:GetWindowName('evenementx'):SetValue('');
		end
	end
end

function AfficheConfig()
	
	dlgConfig = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Marquage des Equipes', 
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

	-- Toolbar Principale ...
	local tbconfig = dlgConfig:GetWindowName('tbconfig');
	tbconfig:AddStretchableSpace();
	local btnSave = tbconfig:AddTool("Lancer le marquage", "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	local btnClear = tbconfig:AddTool("Effacer la sélection", "./res/32x32_clear.png");
	tbconfig:AddSeparator();
	local btnRAZ = tbconfig:AddTool("RAZ Equipe", "./res/32x32_clear.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	local message = app.GetAuiMessage();
	
	local cmd = 'Select count(*) Type, Type_equipe From Equipe Group By Type_equipe';
	base:TableLoad(tEquipe, cmd);
	
	dlgConfig:GetWindowName('comboTypeEquipe'):Clear();
	for i = 0, tEquipe:GetNbRows() -1 do
		dlgConfig:GetWindowName('comboTypeEquipe'):Append(tEquipe:GetCell('Type_equipe', i));
	end
	dlgConfig:GetWindowName('comboTypeEquipe'):SetSelection(0);

	dlgConfig:GetWindowName('comboColEquipe'):Clear();
	dlgConfig:GetWindowName('comboColEquipe'):Append('Equipe');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Groupe');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Critere');
	dlgConfig:GetWindowName('comboColEquipe'):SetSelection(0);
	dlgConfig:GetWindowName('comboColEquipe'):SetSelection(0);
	
	local texte = 'Si votre base de données a été préparée, vous pourrez'..
					'\nmarquer les colonnes Groupe, Equipe et Critere des concurrents'..
					"\nde façon à constituer des équipes avec un contenu préparé à l'avance."..
					"\nPour le Comité Mont-Blanc, Il est possible de constituer les équipes"..
					"\navec le nom des districts ou ceux des Conseillers Généraux"..
					"\ncorrespontants aux Clubs."
	dlgConfig:GetWindowName('texte'):SetLabel(texte);
	dlgConfig:Bind(eventType.TEXT, OnGetCourse, dlgConfig:GetWindowName('coursex'));
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			OnMarquage();
			dlgConfig:EndModal();
		end, btnSave); 
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:GetWindowName('comboCoursesPrises'):Clear();
			dlgConfig:GetWindowName('comboCoursesPrises'):SetValue('');
			dlgConfig:GetWindowName('coursex'):SetValue('');
			dlgConfig:GetWindowName('courses'):SetValue('');
			dlgConfig:GetWindowName('evenementx'):SetValue('');
		end, btnClear); 
		
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			bouton = idButton.CANCEL;
			dlgConfig:EndModal();
		 end,  btnClose);

	dlgConfig:Bind(eventType.MENU, 
		function(evt)
			local colonne = dlgConfig:GetWindowName('comboColEquipe'):GetValue();
			if dlgConfig:GetWindowName('courses'):GetValue():len() > 0 then
				local cmd = "Update Resultat Set "..colonne..' = NULL Where Code_evenement in('..dlgConfig:GetWindowName('courses'):GetValue()..')';
				base:Query(cmd);
				app.GetAuiFrame():MessageBox('Colonne '..colonne..' Mise à blanc', "RAZ "..colonne, msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION); 
			else
				app.GetAuiFrame():MessageBox('Veuillez selectionner une ou plusieurs courses avant... ', "RAZ "..colonne, msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION); 
			end
		 end,  btnRAZ);

	dlgConfig:Bind(eventType.BUTTON, 
		function(evt)	
			local virgule = '';
			local courses = dlgConfig:GetWindowName('courses'):GetValue();
			local coursex = dlgConfig:GetWindowName('coursex'):GetValue();
			local evenementx = dlgConfig:GetWindowName('evenementx'):GetValue();
			if courses:len() > 0 then
				virgule = ',';
			end
			if evenementx:len() > 0 then
				courses = courses..virgule..coursex;
			end
			dlgConfig:GetWindowName('courses'):SetValue(courses);
			SetcomboCoursesPrises();
		 end,  btnAjouter);
	dlgConfig:Fit();
	dlgConfig:ShowModal();
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

function main(params_c)
	params = {};
	params.code_evenement = params_c.code_evenement;
	params.width = (display:GetSize().width * 2) / 3;
	params.height = display:GetSize().height / 2;
	params.x = (display:GetSize().width - params.width) / 2;
	params.y = 0;
	params.debug = false;
	params.version = "1.0";
	base = base or sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	tResultat = base:GetTable('Resultat');
	tEquipe = base:GetTable('Equipe');
	if not tEquipe then
		CreateEquipe();
	end
	tEquipe_Club = base:GetTable('Equipe_Club');
	if not tEquipe_Club then
		CreatetEquipe_Club();
	end
	-- Ouverture Document XML 
	XML = "./process/marquageEquipe.xml";
	params.doc = xmlDocument.Create(XML);
	AfficheConfig();
end




