dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
dofile('./edition/functionPG.lua');
function main(params_c)
	if params_c == nil then
		return false;
	end
	params = params_c;
	params.version = '1.8';
	params.pluscode = 0;
	params.closeDlg = false;
	params.impression = tonumber(params.impression) or 1;
	params.gestion = tonumber(params.gestion) or 0;
	base = sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	params.titre = tEvenement:GetCell('Nom', 0);
	params.station = tEvenement:GetCell('Station', 0);
	tEvenement2 = tEvenement:Copy();
	ReplaceTableEnvironnement(tEvenement2, '_tEvenement2');
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	local saison = tEpreuve:GetCell('Code_saison', 0);
	tRegroupement = base:GetTable('Regroupement');
	local cmd = "SELECT * FROM Regroupement WHERE Code_activite='ALP' AND Code_entite = 'FIS' AND Code_saison = '"..saison.."' AND Code = 'POOL'"
	base:TableLoad(tRegroupement, cmd);
	if tRegroupement:GetNbRows() == 0 then
		local cmd = "REPLACE INTO Regroupement VALUES ('ALP', 'FIS', "..saison..", '-', 'POOL', 100, NULL, 'Course POOL', 'Course POOL', 'N')";
		base:Query(cmd);
	end
	params.datex = tEpreuve:GetCell('Date_epreuve', 0);
	tEvenement_Officiel = base:GetTable('Evenement_Officiel');
	base:TableLoad(tEvenement_Officiel, 'Select * From Evenement_Officiel Where Code_evenement = '..params.code_evenement..' Order By Ordre DESC');
	params.lastordre = tEvenement_Officiel:GetCellInt('Ordre', 0);
	params.dlgPosit = {};
	params.dlgPosit.width = display:GetSize().width;
	params.dlgPosit.height = display:GetSize().height;
	params.dlgPosit.x = 1;
	params.dlgPosit.y = 1;
	if params.lastordre < 8 then
		params.lastordre = 7;
	end
	if params.impression == 1 then
		if tEpreuve:GetNbRows() > 1 then
			OnDates();
		end
		OnEdition()
	elseif params.gestion == 1 then
		OnGestion();
		AffichedlgCourses()
	end
end

function OnChangePlus(ctrl)
	params.pluscode = 0;
	local num = tonumber(ctrl:GetValue()) or 0;
	if num > 0 then
		base:TableLoad(tEvenement2, 'Select * From Evenement Where Code = '..num);
		if tEvenement2:GetNbRows() > 0 then
			params.pluscode = tEvenement2:GetCellInt('Code', 0);
			local chaine = tEvenement2:GetCell('Station', 0)..' le '..tEvenement2:GetCell('Date_debut', 0)..' - '..tEvenement2:GetCell('Nom', 0);
			dlgCourses:GetWindowName('pluscourse'):SetValue(chaine);
		end
	end
end

function AffichedlgCourses()	-- affichage des courses 
	dlgCourses = wnd.CreateDialog(
		{
		width = params.dlgPosit.width / 2,
		height = params.dlgPosit.height - 51,
		x = 400,
		y = 1,
		label='Voir les courses contenant les officiels', 
		icon='./res/32x32_fis.png'
		});
	
	dlgCourses:LoadTemplateXML({ 
		xml = './edition/entryFIS_ALP.xml', 	-- Obligatoire
		node_name = 'edition/gestion/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'listeevenement', 		-- Facultatif si le node_name est unique ...
		nbrows = tEvenement:GetNbRows();
	});

	-- Toolbar 
	local tbevenement = dlgCourses:GetWindowName('tbevenement');
	tbevenement:AddStretchableSpace();
	tbevenement:AddSeparator();
	local btnRetour = tbevenement:AddTool("Retour", "./res/32x32_exit.png");
	tbevenement:AddSeparator();
	local btnValider = tbevenement:AddTool("Voir les officiels", "./res/vpe32x32_save.png");
	tbevenement:AddSeparator();
	local btnTout = tbevenement:AddTool("Selectioner toutes les courses POOL", "./res/32x32_dialog_ok.png");
	tbevenement:AddSeparator();
	tbevenement:AddStretchableSpace();
	tbevenement:Realize();
	
	for i = 1, tEvenement:GetNbRows() do
		dlgCourses:GetWindowName('chk'..i):SetValue(false);
		dlgCourses:GetWindowName('nom'..i):SetValue(tEvenement:GetCell('Nom', i-1));
	end

	tbevenement:Bind(eventType.MENU, 
		function(evt)
			for i = 1, tEvenement:GetNbRows() do
				dlgCourses:GetWindowName('chk'..i):SetValue(true);
			end
			dlgCourses:Refresh();
		end
		, btnTout);
	tbevenement:Bind(eventType.MENU, 
		function(evt)
			local strin = '0';
			for i = 1, tEvenement:GetNbRows() do
				if dlgCourses:GetWindowName('chk'..i):GetValue() == true then
					strin = strin..','..tEvenement:GetCellInt('Code', i-1);
					if params.closeDlg == true then
						dlgCourses:EndModal(idButton.OK)
					end
				end
				strin = strin..','..params.pluscode;
			end
			local cmd = 'Select * From Evenement_Officiel Where Code_evenement In('..strin..") And Fonction In('ResponsibleEntry','NationalAssociation','TeamCaptain','Trainer','Doctor','Physiotherapist','Technician','ServicePersonnal') And LENGTH('Nom') > 0 Order By Fonction, Nom, Prenom";
			base:TableLoad(tEvenement_Officiel, cmd);
			for i = tEvenement_Officiel:GetNbRows() -1, 0, -1 do	-- �liminer les doublons
				local fonction = tEvenement_Officiel:GetCell('Fonction', i);
				local nom = tEvenement_Officiel:GetCell('Nom', i);
				local prenom = tEvenement_Officiel:GetCell('Prenom', i);
				if i > 0 then
					local fonction_prec = tEvenement_Officiel:GetCell('Fonction', i-1);
					local nom_prec = tEvenement_Officiel:GetCell('Nom', i-1);
					local prenom_prec = tEvenement_Officiel:GetCell('Prenom', i-1);
					if fonction == fonction_prec and nom == nom_prec and prenom == prenom_prec then
						tEvenement_Officiel:RemoveRowAt(i);
					end
				end
			end
			AffichedlgOfficiels();
			if params.closeDlg == true then
				dlgCourses:EndModal(idButton.OK);
			end
		end
		, btnValider);

	dlgCourses:Bind(eventType.TEXT, 
		function(evt) 
			OnChangePlus(dlgCourses:GetWindowName('plus'));
		end, 
		dlgCourses:GetWindowName('plus'))
		
	tbevenement:Bind(eventType.MENU, function(evt) dlgCourses:EndModal(idButton.CANCEL) end, btnRetour);
	dlgCourses:Fit();
	dlgCourses:ShowModal();
end

function CtrlFonction()
	local arFonction = {};
	arFonction.ResponsibleEntry = {}; arFonction.ResponsibleEntry.Nombre = 0;
	arFonction.NationalAssociation = {}; arFonction.NationalAssociation.Nombre = 0;
	arFonction.TeamCaptain = {}; arFonction.TeamCaptain.Nombre = 0;
	arFonction.Trainer = {}; arFonction.Trainer.Nombre = 0;
	arFonction.Doctor = {}; arFonction.Doctor.Nombre = 0;
	arFonction.Technician = {}; arFonction.Technician.Nombre = 0;
	arFonction.Physiotherapist = {}; arFonction.Physiotherapist.Nombre = 0;
	arFonction.ServicePersonnal = {}; arFonction.ServicePersonnal.Nombre = 0;
	for i = 1, tEvenement_Officiel_Copy:GetNbRows()  do
		if dlgOfficiels:GetWindowName('chkofficiel'..i):GetValue() == true then
			local fonction = tEvenement_Officiel_Copy:GetCell('Fonction', i-1);
			arFonction[fonction].Nombre = arFonction[fonction].Nombre + 1;
		end
	end
	local erreur = 'Attention aux erreurs ! Vous avez s�lectionn� ';
	if arFonction.ResponsibleEntry.Nombre > 1 then
		params.ok = false;
		erreur = erreur..'\n'..arFonction.ResponsibleEntry.Nombre..' responsables des inscriptions (1 maximum autoris�)';
	end
	if arFonction.NationalAssociation.Nombre > 1 then
		params.ok = false;
		erreur = erreur..'\n'..arFonction.NationalAssociation.Nombre..' structures responsables des inscriptions (1 maximum autoris�)';
	end
	if arFonction.TeamCaptain.Nombre > 1 then
		params.ok = false;
		erreur = erreur..'\n'..arFonction.TeamCaptain.Nombre..' chefs d\'�quipe (1 maximum autoris�)';
	end
	if arFonction.Trainer.Nombre > 6 then
		params.ok = false;
		erreur = erreur..'\n'..arFonction.Trainer.Nombre..' entra�neurs (6 maximum autoris�s)';
	end
	if arFonction.Doctor.Nombre > 2 then
		params.ok = false;
		erreur = erreur..'\n'..arFonction.Doctor.Nombre..' m�decins (2 maximum autoris�s)';
	end
	if arFonction.Physiotherapist.Nombre > 2 then
		params.ok = false;
		erreur = erreur..'\n'..arFonction.Physiotherapist.Nombre..' Kin�sith�rapeutes (2 maximum autoris�s)';
	end
	if arFonction.Technician.Nombre > 1 then
		params.ok = false;
		erreur = erreur..'\n'..arFonction.Technician.Nombre..' techniciens (1 maximum autoris�)';
	end
	if arFonction.ServicePersonnal.Nombre > 8 then
		params.ok = false;
		erreur = erreur..'\n'..arFonction.ServicePersonnal.Nombre..' accompagnateurs (8 maximum autoris�s)';
	end
	if params.ok == false then
		app.GetAuiFrame():MessageBox(erreur, "Attention au nombre des officiels !!", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING); 
	end
end

function AffichedlgOfficiels()	-- affichage des courses 
	dlgOfficiels = wnd.CreateDialog(
		{
		width = params.dlgPosit.width / 2,
		height = params.dlgPosit.height - 51,
		x = 400,
		y = 1,
		label='Officiels de la course : ' , 
		icon='./res/32x32_fis.png'
		});
	
	dlgOfficiels:LoadTemplateXML({ 
		xml = './edition/entryFIS_ALP.xml', 	-- Obligatoire
		node_name = 'edition/gestion/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'listeofficiel', 		-- Facultatif si le node_name est unique ...
		titre = params.titre,
		station = params.station,
		datex = params.datex,
		nbrows = tEvenement_Officiel:GetNbRows()

	});

	-- Toolbar 
	local tbofficiel = dlgOfficiels:GetWindowName('tbofficiel');
	tbofficiel:AddStretchableSpace();
	tbofficiel:AddSeparator();
	local btnRetour = tbofficiel:AddTool("Retour", "./res/32x32_exit.png");
	tbofficiel:AddSeparator();
	local btnRAZ = tbofficiel:AddTool("Supprimer tous les officiels", "./res/32x32_clear.png");
	tbofficiel:AddSeparator();
	local btnValider = tbofficiel:AddTool("Enregistrer les officiels", "./res/vpe32x32_save.png");
	tbofficiel:AddSeparator();
	local btnTout = tbofficiel:AddTool("Selectioner tous les officiels", "./res/32x32_dialog_ok.png");
	tbofficiel:AddSeparator();
	tbofficiel:AddStretchableSpace();
	tbofficiel:Realize();
	
	for i = 1, tEvenement_Officiel:GetNbRows() do
		local fonction = tEvenement_Officiel:GetCell('Fonction', i-1);
		dlgOfficiels:GetWindowName('chkofficiel'..i):SetValue(false);
		dlgOfficiels:GetWindowName('fonction'..i):SetValue(params.officiels[fonction].Fonction);
		dlgOfficiels:GetWindowName('nom'..i):SetValue(tEvenement_Officiel:GetCell('Nom', i-1)..' '..tEvenement_Officiel:GetCell('Prenom', i-1));
	end

	

	tbofficiel:Bind(eventType.MENU, 
		function(evt)
			local cmd = 'Delete From Evenement_Officiel Where Code_evenement = '..params.code_evenement.." And Fonction In('ResponsibleEntry','NationalAssociation','TeamCaptain','Trainer','Doctor','Physiotherapist','Technician','ServicePersonnal')";
			base:Query(cmd);
			for i = 1, tEvenement_Officiel:GetNbRows() do
				dlgOfficiels:GetWindowName('chkofficiel'..i):SetValue(false)
			end
		end
		, btnRAZ);

	tbofficiel:Bind(eventType.MENU, 
		function(evt)
			tEvenement_Officiel_Copy = tEvenement_Officiel:Copy();
			params.ok = true;
			CtrlFonction()
			if params.ok == false then
				return;
			end
			local cmd = 'Delete From Evenement_Officiel Where Code_evenement = '..params.code_evenement.." And Fonction In('ResponsibleEntry','NationalAssociation','TeamCaptain','Trainer','Doctor','Physiotherapist','Technician','ServicePersonnal')";
			base:Query(cmd);
			local indice = params.lastordre;
			for i = 1, tEvenement_Officiel_Copy:GetNbRows() do
				if dlgOfficiels:GetWindowName('chkofficiel'..i):GetValue() == true then
					params.closeDlg = true;
					indice = indice + 1;
					local row = tEvenement_Officiel:AddRow();
					tEvenement_Officiel:SetCell('Code_evenement', row, params.code_evenement);
					tEvenement_Officiel:SetCell('Code_epreuve', row, 1);
					tEvenement_Officiel:SetCell('Ordre', row, indice);
					tEvenement_Officiel:SetCell('Code_coureur', row, tEvenement_Officiel_Copy:GetCell('Code_coureur', i-1));
					tEvenement_Officiel:SetCell('Nom', row, tEvenement_Officiel_Copy:GetCell('Nom', i-1));
					tEvenement_Officiel:SetCell('Prenom', row, tEvenement_Officiel_Copy:GetCell('Prenom', i-1));
					tEvenement_Officiel:SetCell('Fonction', row, tEvenement_Officiel_Copy:GetCell('Fonction', i-1));
					tEvenement_Officiel:SetCell('Nation', row, tEvenement_Officiel_Copy:GetCell('Nation', i-1));
					tEvenement_Officiel:SetCell('Email', row, tEvenement_Officiel_Copy:GetCell('Email', i-1));
					tEvenement_Officiel:SetCell('Adresse1', row, tEvenement_Officiel_Copy:GetCell('Adresse1', i-1));
					tEvenement_Officiel:SetCell('Adresse2', row, tEvenement_Officiel_Copy:GetCell('Adresse2', i-1));
					tEvenement_Officiel:SetCell('Code_postal', row, tEvenement_Officiel_Copy:GetCell('Code_postal', i-1));
					tEvenement_Officiel:SetCell('Ville', row, tEvenement_Officiel_Copy:GetCell('Ville', i-1));
					tEvenement_Officiel:SetCell('Pays', row, tEvenement_Officiel_Copy:GetCell('Pays', i-1));
					tEvenement_Officiel:SetCell('Tel_fixe', row, tEvenement_Officiel_Copy:GetCell('Tel_fixe', i-1));
					tEvenement_Officiel:SetCell('Tel_mobile', row, tEvenement_Officiel_Copy:GetCell('Tel_mobile', i-1));
					tEvenement_Officiel:SetCell('Image_signature', row, tEvenement_Officiel_Copy:GetCell('Image_signature', i-1));
					tEvenement_Officiel:SetCell('Info_supplement', row, tEvenement_Officiel_Copy:GetCell('Info_supplement', i-1));
					base:TableInsert(tEvenement_Officiel, row);
				end
			end
			tEvenement_Officiel_Copy:Delete();
			dlgOfficiels:EndModal(idButton.OK);
		end
		, btnValider);
	tbofficiel:Bind(eventType.MENU, 
		function(evt)
			for i = 1, tEvenement_Officiel:GetNbRows() do
				dlgOfficiels:GetWindowName('chkofficiel'..i):SetValue(true);
			end
			dlgOfficiels:Refresh();
		end
		, btnTout);

	tbofficiel:Bind(eventType.MENU, function(evt) dlgOfficiels:EndModal(idButton.CANCEL) end, btnRetour);
	dlgOfficiels:Fit();
	dlgOfficiels:ShowModal();
end

function LectureOfficiels(node)
	child = xmlNode.GetChildren(node);
	while child ~= nil do
		local titre = child:GetAttribute('code');
		params.officiels[titre] = {};
		params.officiels[titre].Fonction = child:GetAttribute('label');
		child = child:GetNext();
	end
end

function OnGestion(evt)
	params.officiels = {};
	local doc = xmlDocument.Create(app.GetPath().."/res/res.xml");
	local root = doc:GetRoot();
	child = xmlNode.GetChildren(root);
	while child ~= nil do
		if child:HasAttribute("activite") and child:GetAttribute('ALPIN') and child:HasAttribute("regroupement") and child:GetAttribute('POOL') then 
			LectureOfficiels(child)
			break;
		end
		child = child:GetNext();
	end
	doc:Delete();

	local cmd = 'Select * From Epreuve Where Code_evenement = '..params.code_evenement..' Order By Date_epreuve';
	base:TableLoad(tEpreuve, cmd);
	local code_activite = tEpreuve:GetCell('Code_activite', 0);
	local code_saison = tEpreuve:GetCell('Code_saison', 0);
	-- local cmd = "Select * From Epreuve Where Code_activite = '"..code_activite.."' And Code_saison = '"..code_saison.."' And Code_epreuve = 1 And Code_regroupement = '-' Order By Date_epreuve DESC";
	local cmd = "Select * From Epreuve Where Code_activite = '"..code_activite.."' And Code_epreuve = 1 And Code_regroupement = 'POOL' Order By Date_epreuve DESC";
	base:TableLoad(tEpreuve, cmd);
	local evenement_in = '0';
	for i = 0, tEpreuve:GetNbRows() -1 do
		local code_evenement = tEpreuve:GetCellInt('Code_evenement', i);
		evenement_in = evenement_in..','..code_evenement
	end
	local cmd = 'Select * From Evenement Where Code In ('..evenement_in..')';
	base:TableLoad(tEvenement, cmd);
end

function OnDates()	
	dlgDates = wnd.CreateDialog(
		{
		width = params.dlgPosit.width / 2,
		height = params.dlgPosit.height - 51,
		x = 400,
		y = 1,
		label='Gestion des dates de l\'�venement : ' , 
		icon='./res/32x32_fis.png'
		});
	
	dlgDates:LoadTemplateXML({ 
		xml = './edition/entryFIS_ALP.xml', 	-- Obligatoire
		node_name = 'edition/gestion/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'gestiondates', 		-- Facultatif si le node_name est unique ...
		titre = params.titre,
		station = params.station,
		datex = params.datex,
		nbrows = tEvenement_Officiel:GetNbRows()

	});

	-- Toolbar 
	local tbdate = dlgDates:GetWindowName('tbdate');
	tbdate:AddStretchableSpace();
	tbdate:AddSeparator();
	local btnRetour = tbdate:AddTool("Retour", "./res/32x32_exit.png");
	tbdate:AddSeparator();
	local btnValider = tbdate:AddTool("Enregistrer les dates", "./res/vpe32x32_save.png");
	tbdate:AddSeparator();
	tbdate:AddStretchableSpace();
	tbdate:Realize();
	
	dlgDates:GetWindowName('debut'):SetValue(tEpreuve:GetCell('Date_epreuve', 0, '%4Y/%2M/%2D'));
	dlgDates:GetWindowName('fin'):SetValue(tEpreuve:GetCell('Date_epreuve', tEpreuve:GetNbRows() -1, '%4Y/%2M/%2D'));

	tbdate:Bind(eventType.MENU, function(evt) dlgDates:EndModal(idButton.CANCEL) end, btnRetour);
	tbdate:Bind(eventType.MENU, 
		function(evt)
			local arfin = dlgDates:GetWindowName('fin'):GetValue();
			local annee = string.format('%04i', arfin.year);
			local mois = string.format('%02i', arfin.month);
			local jour = string.format('%02i', arfin.day);
			local str = annee..'-'..mois..'-'..jour;
			tEpreuve:SetCell('Date_epreuve', tEpreuve:GetNbRows() -1, str);
			base:TableUpdate(tEpreuve, tEpreuve:GetNbRows() -1);
			dlgDates:EndModal(idButton.OK)
		end
		, btnValider);
	dlgDates:ShowModal();	
end

function OnEdition(evt)
	body = base.CreateTableRanking({ 
		code_evenement = params.code_evenement, 
		code_epreuve = params.code_epreuve, 
		code_manche = params.code_manche
	});
	local filterCmd = wnd.FilterConcurrentDialog({ 
	sqlTable = body,
	key = 'cmd'});
	if type(filterCmd) == 'string' and filterCmd:len() > 0 then
		body:Filter(filterCmd, true);
	end

	-- Ex de filtrage de body
	-- body:Filter("$(Nation) == 'FRA'", true);
	body:AddColumn('IADH', 'char');
	body:AddColumn('IASG', 'char');
	body:AddColumn('IAGS', 'char');
	body:AddColumn('IASL', 'char');
	body:AddColumn('IASC', 'char');
	body:AddColumn('NTE', 'char');
	body:SetColumnLabel('Code_coureur', 'FIS\nCode');
	body:SetColumnLabel('IADH', 'DH');
	body:SetColumnLabel('IASG', 'SG');
	body:SetColumnLabel('IAGS', 'GS');
	body:SetColumnLabel('IASL', 'SL');
	body:SetColumnLabel('IASC', 'SC/C');
	body:SetColumnLabel('NTE', 'NTE');

	local cmd = "Select * From Epreuve Where Code_evenement = "..params.code_evenement;
	base:TableLoad(tEpreuve,cmd);
	tEpreuve:OrderBy('Code_epreuve');
	local t = {}; arEpreuve = {};
	params.date_epreuve_debut = tEpreuve:GetCell('Date_epreuve', 0,'%2D.%2M.%4Y');
	params.date_epreuve_fin = tEpreuve:GetCell('Date_epreuve', tEpreuve:GetNbRows() -1,'%2D.%2M.%4Y');
	local arDate = tEpreuve:GetCell('Date_epreuve', 0):Split('/');
	local t1 = os.time( { year = arDate[3], month = arDate[2], day = arDate[1] } );
	local t2 = t1 - (3600*24);
	local date_arrivee_default = os.date("%d.%m.%Y", t2);
	local body_date_arrivee = os.date("%d.%m.%y", t2);
	local body_date_depart = tEpreuve:GetCell('Date_epreuve', tEpreuve:GetNbRows() -1, '%2D.%2M.%2Y');
	local date_arrivee_update = os.date("%Y-%m-%d", t2);
	local date_depart_update = tEpreuve:GetCell('Date_epreuve', tEpreuve:GetNbRows() -1,'%4Y-%2M-%2D');
	local cmd = 'Select * From Evenement_officiel Where Code_evenement = '..params.code_evenement;
	params.date_arrivee_default = date_arrivee_default;
	base:TableLoad(tEvenement_Officiel, cmd)
	for i = 0, tEvenement_Officiel:GetNbRows() -1 do
		tEvenement_Officiel:SetCell('Date_arrivee', i, date_arrivee_update);
		tEvenement_Officiel:SetCell('Date_depart', i, date_depart_update);
	end
	local arDiscipline = {};
	arDiscipline['DH'] = {};
	arDiscipline['DH'].Nombre = 0;
	arDiscipline['SG'] = {};
	arDiscipline['SG'].Nombre = 0;
	arDiscipline['GS'] = {};
	arDiscipline['GS'].Nombre = 0;
	arDiscipline['SL'] = {};
	arDiscipline['SL'].Nombre = 0;
	base:TableBulkUpdate(tEvenement_Officiel);
	for i = 0, tEpreuve:GetNbRows() -1 do
		local discipline = tEpreuve:GetCell('Code_discipline', i);
		table.insert(t, 'IA'..discipline);
		arDiscipline [discipline].Nombre = arDiscipline [discipline].Nombre + 1;
		local sexe = tEpreuve:GetCell('Sexe', i);
		arEpreuve[sexe] = sexe;
	end
	params.code_regroupement = "'-1'";
	for i = 0, tEpreuve:GetNbRows() -1 do
		params.code_regroupement = params.code_regroupement..",'"..tEpreuve:GetCell('Code_regroupement', i).."'";
	end
	if arEpreuve.M and arEpreuve.F then
		params.sexe = "T";
	elseif arEpreuve.M then
		params.sexe = "M";
	else
		params.sexe = "F";
	end
	params.no_entry = 0;

	
	-- base:GetClassementCoureur($(Code_coureur)):GetCell('Pts',0)
	-- base:GetClassementCoureur($(Code_coureur), 'FAU'):GetCell('Pts',0)
	-- base:GetClassementCoureur($(Code_coureur), 'FAU', 519):GetCell('Pts',0)
	
	-- local pts = base:GetClassementCoureur('FIS194965', 'IAGS', 1719):GetCell('Pts', 0)
	-- adv.Alert('pts = '..pts);
	for i=0, body:GetNbRows()-1 do
		tCritere = {};
		local code_coureur = body:GetCell('Code_coureur',i);
		if code_coureur:len() > 0 then
			local plus_moins = body:GetCell('Critere',i):sub(1,1);
			if plus_moins == '+' or plus_moins == '-' then
				tCritere.plus_moins = plus_moins;
				tCritere.discipline = body:GetCell('Critere',i):sub(2);
				tCritere.code_epreuve = tonumber(body:GetCell('Critere',i):sub(4,4)) or -1;
			end
			for j = 1, #t do  -- il y a autant de ligne que d'�preuve.
				local pts = '';
				local discipline = t[j]:sub(3);
				if not tCritere.discipline then
					pts = base:GetClassementCoureur(code_coureur, t[j]):GetCell('Pts', 0);
					if pts:len() == 0 then
						pts = 'X';
					end
				else
					if plus_moins == '+' then
						if discipline == string.sub(tCritere.discipline, 1, 2) then	
							pts = base:GetClassementCoureur(code_coureur, t[j]):GetCell('Pts', 0);
						else
							params.no_entry = params.no_entry + 1;
						end
					elseif plus_moins == '-' then
						-- �preuve 1 = SL
						-- �preuve 2 = GS
						-- �preuve 3 = GS, -GS2 = on fait le SL et le GS1, on met les points du SL ET les points du GS, 
						-- �preuve 1 = GS 
						-- �preuve 2 = GS, -SG2 = on fait le GS1 donc on met les points du GS
						if arDiscipline[discipline].Nombre > 1 then	-- je mets les points de la discipline
							pts = base:GetClassementCoureur(code_coureur, t[j]):GetCell('Pts', 0);
							params.no_entry = params.no_entry + arDiscipline[discipline].Nombre -1;
						else
							if discipline ~= tCritere.discipline then	-- -GS : plus_moins = -
								pts = base:GetClassementCoureur(code_coureur, t[j]):GetCell('Pts', 0);
							else
								params.no_entry = params.no_entry + 1;
							end
						end
					end
				end			
				if pts:len() > 0 then
					body:SetCell(t[j], i, pts)
				else
					body:SetCell(t[j], i, '');
				end
			end
			body:SetCell('Info', i, body_date_arrivee);
			if body:GetCell('Critere', i):len() == 0 then
				body:SetCell('Niveau', i, body_date_depart);
			else
				body:SetCell('Niveau', i, body:GetCell('Critere', i));
			end
		end
	end

	
	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/entryFIS_ALP.xml',
		node_name = 'edition/report',
		node_attr = 'id',
		node_value = 'Entry_form' ,
		parent = dlg,
		title = 'Formulaire d\'inscription FIS',
		base = base,
		body = body,
		params = params
	});
	
	-- On Enchaine avec la page 2 
	local editor = report:GetEditor();
	editor:PageBreak(); -- Saut de Page entre les 2 �ditions ...

	wnd.LoadTemplateReportXML({
		xml = './edition/entryFIS_ALP.xml',
		node_name = 'edition/report',
		node_attr = 'id',
		node_value = 'Entry_form2' ,
		report = report,
		base = base,
		body = body,
		params = params
	});

	-- Positionnement sur la Derni�re Page ...
	-- editor:SetPagePreview(editor:GetPageCount());
end
