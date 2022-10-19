-- Esprit Racing - Tirage des dossards et des rangs de départ en manche 2 par Philippe Guérindon
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function GetMenuName()
	return "Esprit Racing - Tirage des dossards ou des rangs de départ";
end

function GetActivite()
	return "ALP,TM";
end

function SetupDefault(evt)
	-- dlgSetup:GetWindowName('bibo_m1'):SetValue(params.bibo_m1);
	-- dlgSetup:GetWindowName('bibo_m2'):SetValue(params.bibo_m2);
	-- for i = 1, #params.tGroupesDames do
		-- local groupe = string.gsub(params.tGroupesDames[i], "'", "");
		-- dlgSetup:GetWindowName('groupe_dames'..i):SetValue(groupe);
	-- end
	dlgSetup:GetWindowName('bibo_m1'):SetValue(params.nodeDefault:GetAttribute('bibo_m1'));
	dlgSetup:GetWindowName('bibo_m2'):SetValue(params.nodeDefault:GetAttribute('bibo_m2'));
	for i = 1, 10 do
		dlgSetup:GetWindowName('groupe_dames'..i):SetValue('');
		dlgSetup:GetWindowName('groupe_hommes'..i):SetValue('');
	end
	if params.nodeDefault:GetAttribute('abd_dsq_repartent') == 'Oui' then
		if params.nodeDefault:GetAttribute('bib_abddsq_ordre') == 'ASC' then
			dlgSetup:GetWindowName('bib_abddsq_ordre'):SetSelection(0);
		else
			dlgSetup:GetWindowName('bib_abddsq_ordre'):SetSelection(1);
		end
		if params.nodeDefault:GetAttribute('abd_dsq_apres_classes') == 'Oui' then
			dlgSetup:GetWindowName('abd_dsq_apres_classes'):SetSelection(0);
		else
			dlgSetup:GetWindowName('abd_dsq_apres_classes'):SetSelection(1);
		end
	else
		dlgSetup:GetWindowName('bib_abddsq_ordre'):SetSelection(2);
		dlgSetup:GetWindowName('abd_dsq_apres_classes'):SetSelection(2);
	end
	local indice_dames = 0;
	for i = 1, 20 do
		if params.nodeDefaultDames:HasAttribute('groupe'..i) then
			indice_dames = indice_dames + 1;
			local valeur = params.nodeDefaultDames:GetAttribute('groupe'..i);
			valeur = string.gsub(valeur,"'","");
			dlgSetup:GetWindowName('groupe_dames'..indice_dames):SetValue(valeur);
		end
	end
	local indice_hommes = 0;
	for i = 1, 20 do
		if params.nodeDefaultHommes:HasAttribute('groupe'..i) then
			indice_hommes = indice_hommes + 1;
			local valeur = params.nodeDefaultHommes:GetAttribute('groupe'..i);
			valeur = string.gsub(valeur,"'","");
			dlgSetup:GetWindowName('groupe_hommes'..indice_hommes):SetValue(valeur);
		end
	end
end

function SortTable(array)	-- tri des tables 
	table.sort(array, function (u,v)
		return u['Reserve'] < v['Reserve'];
	end)
end


function DecodeActiveNode()
	local nbmanches = tonumber(params.activeNode:GetAttribute('nb_manches')) or 0;
	params.tirageCourse = {};
	local node = params.activeNode:GetChildren();
	while node ~= nil do
		local nodeCourse = {};
		nodeCourse.Name = node:GetName();
		local course = node:GetName();
		local idxcourse = tonumber(nodeCourse.Name:sub(-1));
		nodeCourse.idxCourse = idxcourse;
		local paramsmanches = {};
		for i = 1, nbmanches do
			local groupes = node:GetAttribute('m'..i);
			local idx = tonumber(node:GetAttribute('m'..i..'_sens')) or 0;
			table.insert(paramsmanches, {Groupes = groupes, Sens = idx});
		end
		table.insert(params.tirageCourse, {Data = paramsmanches});	
		node = node:GetNext();
	end
	
	return params.tirageCourse;
end

function OnSetup()
	function SaveSetup()
		for i = 1, 20 do
			if params.nodeDames:HasAttribute('groupe'..i) then
				params.nodeDames:DeleteAttribute('groupe'..i);
			end
			if params.nodeHommes:HasAttribute('groupe'..i) then
				params.nodeHommes:DeleteAttribute('groupe'..i);
			end
		end
		params.bibo_m1 = tonumber(dlgSetup:GetWindowName('bibo_m1'):GetValue()) or 10;
		params.nodeConfig:ChangeAttribute('bibo_m1', params.bibo_m1);
		params.bibo_m2 = tonumber(dlgSetup:GetWindowName('bibo_m2'):GetValue()) or 10;
		params.nodeConfig:ChangeAttribute('bibo_m2', params.bibo_m2);
		if dlgSetup:GetWindowName('bib_abddsq_ordre'):GetSelection() == 0 then
			params.bib_abddsq_ordre = 'ASC';
			params.abd_dsq_repartent = 'Oui';
		elseif dlgSetup:GetWindowName('bib_abddsq_ordre'):GetSelection() == 1 then
			params.bib_abddsq_ordre = 'DESC';
			params.abd_dsq_repartent = 'Oui';
		else
			params.abd_dsq_repartent = 'Non';
		end
		params.nodeConfig:ChangeAttribute('abd_dsq_repartent', params.abd_dsq_repartent);
		params.nodeConfig:ChangeAttribute('bib_abddsq_ordre', params.bib_abddsq_ordre);
		if dlgSetup:GetWindowName('abd_dsq_apres_classes'):GetSelection() == 0 then
			params.abd_dsq_apres_classes = 'Oui';
		else
			params.abd_dsq_apres_classes = 'Non';
		end
		params.nodeConfig:ChangeAttribute('abd_dsq_apres_classes', params.abd_dsq_apres_classes);
		local indice_groupe = 0;
		for i = 1, 10 do
			local chaine = dlgSetup:GetWindowName('groupe_dames'..i):GetValue();
			if chaine:len() > 0 then
				indice_groupe = indice_groupe + 1;
				local separateur = '';
				local strgroupe = '';
				local tCat = chaine:Split(',');
				for j = 1, #tCat do
					tCat[j] = "'"..tCat[j].."'";
					strgroupe = strgroupe ..separateur..tCat[j];
					separateur = ',';
				end
				params.nodeDames:ChangeAttribute('groupe'..indice_groupe, strgroupe);
			else
			end
		end
		for i = 1, 10 do
			local chaine = dlgSetup:GetWindowName('groupe_hommes'..i):GetValue();
			if chaine:len() > 0 then
				indice_groupe = indice_groupe + 1;
				local separateur = '';
				local strgroupe = '';
				local tCat = chaine:Split(',');
				for j = 1, #tCat do
					tCat[j] = "'"..tCat[j].."'";
					strgroupe = strgroupe ..separateur..tCat[j];
					separateur = ',';
				end
				params.nodeHommes:ChangeAttribute('groupe'..indice_groupe, strgroupe);
			end
		end
		params.doc:SaveFile();
		params.doc:Delete();
		GetNodeXMLData();
		dlgSetup:EndModal(idButton.OK);
	end
	dlgSetup = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Back Office', 
		icon='./res/32x32_param.png'
		});
	
	dlgSetup:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		node_value = 'setup'
	});
	dlgSetup:GetWindowName('bib_abddsq_ordre'):Clear();
	dlgSetup:GetWindowName('bib_abddsq_ordre'):Append("Dans l'ordre des dossards");
	dlgSetup:GetWindowName('bib_abddsq_ordre'):Append("Dans l'ordre inverse des dossards");
	dlgSetup:GetWindowName('bib_abddsq_ordre'):Append("Ne repartent pas en M2");

	dlgSetup:GetWindowName('abd_dsq_apres_classes'):Clear();
	dlgSetup:GetWindowName('abd_dsq_apres_classes'):Append("A la fin de tous les classés");
	dlgSetup:GetWindowName('abd_dsq_apres_classes'):Append("A la fin de leur groupe");
	dlgSetup:GetWindowName('abd_dsq_apres_classes'):Append("Sans objet");

	if params.abd_dsq_repartent == 'Non' then
		dlgSetup:GetWindowName('bib_abddsq_ordre'):SetSelection(2);
		dlgSetup:GetWindowName('abd_dsq_apres_classes'):SetSelection(2)
	else
		if params.abd_dsq_apres_classes == 'Oui' then
			dlgSetup:GetWindowName('abd_dsq_apres_classes'):SetSelection(0);
		else
			dlgSetup:GetWindowName('abd_dsq_apres_classes'):SetSelection(1);
		end
		if params.bib_abddsq_ordre == 'ASC' then
			dlgSetup:GetWindowName('bib_abddsq_ordre'):SetSelection(0);
		else
			dlgSetup:GetWindowName('bib_abddsq_ordre'):SetSelection(1);
		end
	end
	
	dlgSetup:GetWindowName('bibo_m1'):SetValue(params.bibo_m1);
	dlgSetup:GetWindowName('bibo_m2'):SetValue(params.bibo_m2);
	local cmd = "Select * From Categorie WHERE Code_entite = 'FFS' And Code_activite = 'ALP' AND Code_grille Like 'FFS-M%' AND Code_saison = '"..params.code_saison.."' And (Code = 'U21' Or Code = 'U30' Or Libelle LIKE '%Masters Dames%')  ORDER BY Ordre";
	base:TableLoad(tCategorie, cmd);
	tCategorieDames = tCategorie:Copy();
	local cmd = "Select * From Categorie WHERE Code_entite = 'FFS' And Code_activite = 'ALP' AND Code_grille Like 'FFS-M%' AND Code_saison = '"..params.code_saison.."' And (Code = 'U21' Or Code = 'U30' Or Libelle LIKE '%Masters Hommes%')  ORDER BY Ordre";
	base:TableLoad(tCategorie, cmd);
	tCategorieHommes = tCategorie:Copy();
	dlgSetup:GetWindowName('categ_dames'):SetValue('');
	for i = 1, #params.tGroupesDames do
		local groupe = string.gsub(params.tGroupesDames[i], "'", "");
		dlgSetup:GetWindowName('groupe_dames'..i):SetValue(groupe);
	end
	local categories = '';
	for i = 0, tCategorieDames:GetNbRows() -1 do
		categories = categories..tCategorieDames:GetCell('Code', i)..' - de '..tCategorieDames:GetCell('An_min', i)..' à '..tCategorieDames:GetCell('An_max', i)..'\n';
	end
	dlgSetup:GetWindowName('categ_dames'):SetValue(categories);
	
	dlgSetup:GetWindowName('categ_hommes'):SetValue('');
	for i = 1, #params.tGroupesHommes do
		local groupe = string.gsub(params.tGroupesHommes[i], "'", "");
		dlgSetup:GetWindowName('groupe_hommes'..i):SetValue(groupe);
	end
	local categories = '';
	for i = 0, tCategorieHommes:GetNbRows() -1 do
		categories = categories..tCategorieHommes:GetCell('Code', i)..' - de '..tCategorieHommes:GetCell('An_min', i)..' à '..tCategorieHommes:GetCell('An_max', i)..'\n';
	end
	dlgSetup:GetWindowName('categ_hommes'):SetValue(categories);
	
	-- Toolbar Principale ...
	local tbsetup = dlgSetup:GetWindowName('tbsetup');
	tbsetup:AddStretchableSpace();
	local btnSave = tbsetup:AddTool("Valider", "./res/vpe32x32_save.png");
	tbsetup:AddSeparator();
	local btnDefault = tbsetup:AddTool("Valeurs par défaut", "./res/32x32_param.png");
	tbsetup:AddSeparator();
	local btnClose = tbsetup:AddTool("Quitter", "./res/32x32_end.png");
	tbsetup:AddStretchableSpace();
	tbsetup:Realize();
	
	dlgSetup:Bind(eventType.COMBOBOX, 
			function(evt) 
				if dlgSetup:GetWindowName('bib_abddsq_ordre'):GetSelection() < 2 then
					dlgSetup:GetWindowName('abd_dsq_apres_classes'):SetSelection(0); 
				else
					dlgSetup:GetWindowName('abd_dsq_apres_classes'):SetSelection(2); 
				end
			end, 
			dlgSetup:GetWindowName('bib_abddsq_ordre'))
	dlgSetup:Bind(eventType.COMBOBOX, 
			function(evt) 
				if dlgSetup:GetWindowName('abd_dsq_apres_classes'):GetSelection() == 2 then
					dlgSetup:GetWindowName('bib_abddsq_ordre'):SetSelection(2); 
				end
			end, 
			dlgSetup:GetWindowName('abd_dsq_apres_classes'))

	dlgSetup:Bind(eventType.MENU, 
		function(evt) 
			SaveSetup();
		end, btnSave); 
	dlgSetup:Bind(eventType.MENU, SetupDefault, btnDefault); 
	dlgSetup:Bind(eventType.MENU, 
		function(evt) 
			dlgSetup:EndModal(idButton.KO);
		end, btnClose); 
	dlgSetup:Fit();
	dlgSetup:ShowModal();
end

function GetReserveDossard(manche2)
	for i = 0, tResultat:GetNbRows() -1 do
		local code_coureur = tResultat:GetCell('Code_coureur', i);
		tCodes[code_coureur] = {};
		tCodes[code_coureur].Reserve = tResultat:GetCellInt('Reserve', i);
		tCodes[code_coureur].Point = tResultat:GetCellDouble('Point', i, -1);
		tCodes[code_coureur].Tps = -600;
		if manche2 then
			tCodes[code_coureur].Tps = tResultat:GetCellInt('Tps_chrono', i);
			tCodes[code_coureur].Dossard = tResultat:GetCellInt('Dossard', i);
		end
	end
end
		
function OnTirageManche1()
	if params.dossard1 > 0 then
		local msg = "Les dossards ont déjà été tirés.\nVoulez-vous les remplacer ?\nTous les rangs de tirage antérieurs seront supprimés.";
		if app.GetAuiFrame():MessageBox(msg, "Attention !!!"
			, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
			return;
		end
	end
	params.dossard = 1;

	for i = 1, 	#tCoureurs do
		tDraw = tResultat:Copy();
		local filter = "$(Reserve):In("..tCoureurs[i].Reserve..")";
		tDraw:Filter(filter, true);
		tCoureurs[i].Nombre = tDraw:GetNbRows();
		if tCoureurs[i].Nombre > 0 then
			for j = 0, tDraw:GetNbRows() -1 do
				if tDraw:GetCellDouble('Point', j, -1) >= 0 then 
					tCoureurs[i].NbPoint = tCoureurs[i].NbPoint + 1;
				end
			end
			OnTirageDossard(tDraw, tCoureurs[i].Nombre, tCoureurs[i].NbPoint);
		end
	end

	if #params.tExaequo > 0 then
		local msg = "Il y a égalité de points pour :\n";
		for i = 1, #params.tExaequo do
			local rang = params.tExaequo[i];
			tResultat_Copy = tResultat:Copy();
			tResultat_Copy:OrderRandom();
			local filter = "$(Rang):In("..rang..")";
			tResultat_Copy:Filter(filter, true);
			tResultat_Copy:OrderRandom();
			for j = 0, tResultat_Copy:GetNbRows() -1 do
				local dossard = rang + j;
				msg = msg..tResultat_Copy:GetCell('Nom', j).." ("..tResultat_Copy:GetCellDouble('Point', j)..'), dossard attribué = '..dossard..'\n';
				tResultat_Copy:SetCell('Dossard', j, dossard);
			end							
		end
		base:TableBulkUpdate(tResultat_Copy, 'Dossard', 'Resultat');
		app.GetAuiFrame():MessageBox(msg, "Tirage au sort des exaequos !!!"
			, msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
	end
	if params.non_tires_message:len() > 0 then
		local msg = "Certains dossards n'ont pas été attribués. Liste des coureurs concernés ; \n"..params.non_tires_message;
		app.GetAuiFrame():MessageBox(msg, "Dossards non tirés"
			, msgBoxStyle.OK+msgBoxStyle.ICON_WARNING);
	end
end

function OnTirageManche2()
	params.traite = 0;
	--Tps pour absent = -600, Abd = -500  ou Dsq = -800
	local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement..' and Code_manche = 1 And Not Tps = -600 ';
	base:TableLoad(tResultat_Manche, cmd)
	-- adv.Alert('à traiter en M2 = '..tResultat_Manche:GetNbRows())
	for i = 0, tResultat_Manche:GetNbRows() -1 do
		local code_coureur = tResultat_Manche:GetCell('Code_coureur', i);
		local reserve = tCodes[code_coureur].Reserve;
		tResultat_Manche:SetCell('Tps_bonus', i, tCodes[code_coureur].Dossard);
		local tps = tResultat_Manche:GetCellInt('Tps_chrono', i);
		tResultat_Manche:SetCell('Reserve', i, reserve);
		local reservex = reserve;
		if reserve == 21 then
			reservex = #tCoureurs;
		elseif reserve == 20 then
			reservex = #tCoureurs -1;
		end
		if tCoureurs[reservex] then
			if tCodes[code_coureur].Point >= 0 then
				tCoureurs[reservex].NbPoint = tCoureurs[reservex].NbPoint + 1;
			end
			if tps > 0 then
				tCoureurs[reservex].NbClasses = tCoureurs[reservex].NbClasses + 1;
			else
				if tps == -800 then
					tCoureurs[reservex].NbDSQ = tCoureurs[reservex].NbDSQ + 1
				else
					tCoureurs[reservex].NbABD = tCoureurs[reservex].NbABD + 1;
				end
			end
		end
	end
	base:TableBulkUpdate(tResultat_Manche);
	params.rang = 0;
	for i = 1, #tCoureurs do
		local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement..' and Not Tps = -600 And Code_manche = 1 And Reserve = '..tCoureurs[i].Reserve;
		base:TableLoad(tResultat_Manche, cmd);
		tResultat_Manche:OrderBy('Tps_chrono');
		local tablex = tResultat_Manche:Copy();
		OnTirageRang(tablex, i);
	end
	if params.abd_dsq_repartent == 'Oui' and params.abd_dsq_apres_classes == 'Oui' then
		local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement..' and (Tps = -500 or Tps = -800) And Code_manche = 1';
		base:TableLoad(tResultat_Manche, cmd);
		for i = 0, tResultat_Manche:GetNbRows() -1 do
			local code_coureur = tResultat_Manche:GetCell('Code_coureur', i);
			local reserve = tCodes[code_coureur].Reserve;
			tResultat_Manche:SetCell('Tps_bonus', i, tCodes[code_coureur].Dossard);
			tResultat_Manche:SetCell('Reserve', i, reserve);
		end
		local table_abddsq = tResultat_Manche:Copy();
		local orderby = 'Tps_bonus '..params.bib_abddsq_ordre;
		table_abddsq:OrderBy(orderby);
		local traite_abddsq = 0;
		for i = 0, table_abddsq:GetNbRows() -1 do
			params.rang = params.rang + 1;
			local code_coureur = table_abddsq:GetCell('Code_coureur', i);
			local reserve = table_abddsq:GetCellInt('Reserve', i);
			local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement.." And Code_manche = 2 And Code_coureur = '"..code_coureur.."'";
			base:TableLoad(tResultat_Manche, cmd);
			traite_abddsq = traite_abddsq + 1;
			if tResultat_Manche:GetNbRows() > 0 then
				tResultat_Manche:SetCell('Rang', 0, params.rang);
				tResultat_Manche:SetCell('Reserve', 0, reserve);
				base:TableUpdate(tResultat_Manche, 0);
			else
				local row = tResultat_Manche:AddRow();
				tResultat_Manche:SetCell('Code_evenement', row, params.code_evenement);
				tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
				tResultat_Manche:SetCell('Code_manche', row, 2);
				tResultat_Manche:SetCell('Rang', row, params.rang);
				tResultat_Manche:SetCell('Reserve', row, reserve);
				base:TableInsert(tResultat_Manche, row);
			end
		end
	end
end

function SetDossardBackOffice(course, nbGroupes)
	tBibo = {};
	if tResultat:GetCounterValue('Sexe', 'F') > 0 then
		table.insert(tBibo, {Sexe = 'F', NbRows = tResultat:GetCounterValue('Sexe', 'F'), RowFirst = 0, RowEnd = tResultat:GetCounterValue('Sexe', 'F') -1, PtsBibo = 0, LastRowBibo = -1, LastRowPts = -1, FirstRowPtsNull = -1, Reserves = {}});
	end
	if tResultat:GetCounterValue('Sexe', 'M') > 0 then
		table.insert(tBibo, {Sexe = 'M', NbRows = tResultat:GetCounterValue('Sexe', 'M'), RowFirst = 0, RowEnd = tResultat:GetCounterValue('Sexe', 'M') -1, PtsBibo = 0, LastRowBibo = -1,  LastRowPts = -1, FirstRowPtsNull = -1, Reserves = {}});
	end
	
	-- on fera toujours un double tirage des dossards en manche 1 de la course 1
	-- params.tableDossards1 est brassée par la fonction Shuffle du fichier functionPG.lua
	-- tTableTirage1 est brassée par la méthode OrderRandom de skiFFS
	-- des groupes seront constitués selon le back office
	-- la colonne Reserve sera mise à jour selon les différents groupes
	if course == 1 or params.bib_skip == 0 then
		for i = 1, #tBibo do
			tBibo[i].Reserves = {};
			SetGroupes(nbGroupes, i);
			local tReserve = tBibo[i].Reserves
			for ireserve = 1, #tReserve do
				-- adv.Alert('BuildTableTirage( rang = '..tReserve[ireserve]..', bib_first = '..params.bib_first..', setrang = '..tostring(true)..')'..', tResultat_Copy:GetNbRows() = '..tResultat_Copy:GetNbRows());
				local tablex = tResultat:Copy();
				BuildTableTirage(tablex, tReserve[ireserve], params.bib_first, false) ;
			end
		end
	end
	return true;
end
	
function OnTirageBackOffice(course, paramsManche, manche_start)
	-- selection = 3 : 4. Tirage pour des courses de 3 manches
	-- selection = 4 : 5. Tirage pour des courses de 4 manches
	-- selection = 5 : 6. Tirage pour des courses de 2 manches
	-- tirage selon le back office
	local nbmanches = #paramsManche;
	tResultat:OrderBy('Dossard');
	tResultat:SetCounter('Reserve');
	tResultat:SetCounter('Sexe');
	for run = manche_start, nbmanches do
		local rang = 0;
		local groupes = paramsManche[run].Groupes;
		local tGroupes = groupes:Split(',');
		-- for i = 1, #tGroupes do
			-- adv.Alert('run = '..run..', Ordre des groupes : '..tGroupes[i]);
		-- end
		local sens = paramsManche[run].Sens;
		for i = 1, #tGroupes do
			local reserve = tGroupes[i];
			rang = OnTirageDossard(params['course'..course], run, reserve, sens, rang);
		end
		if tResultat:GetCounter('Sexe'):GetNbRows() > 1 then
			for i = 1, #tGroupes do
				local reserve = tGroupes[i] + #tGroupes;
				rang = OnTirageDossard(params['course'..course], run, reserve, sens, rang);
			end
		end
	end
end

-- moins de bibo coureurs --> ordre inverse des temps de la manche 1
-- au moins bibo coureurs --> bibo puis ordre des temps
-- ABD DSQ à la fin par groupe dans ordre inverse des dossards
-- table.insert(tCoureurs.F, {Categ = value, Reserve = reserve, Nombre = 0, NbPoint = 0, NbClasses = 0, NbABD = 0, NbDSQ = 0});

function OnTirageRang(tablex, indice)
	--Tps pour Abd = -500  ou Dsq = -800
	-- table.insert(tCoureurs, {Sexe = 'M', Categ = value, Reserve = reserve, Nombre = 0, NbPoint = 0, NbClasses = 0, NbABD = 0, NbDSQ = 0});
	-- adv.Alert('tCoureurs['..indice..'].Nombre = '..tCoureurs[indice].Nombre..', tCoureurs['..indice..'].NbClasses = '..tCoureurs[indice].NbClasses..', tCoureurs['..indice..'].NbABD = '..tCoureurs[indice].NbABD..', tCoureurs['..indice..'].NbDSQ = '..tCoureurs[indice].NbDSQ..', Reserve = '..tCoureurs[indice].Reserve);
	local traite = 0;
	local traite_bibo = 0;
	local traite_tps = 0;
	local traite_abddsq = 0;
	local table_tps = tablex:Copy();
	local table_abddsq = tablex:Copy();
	local tps_bibo = -1;
	local bolBibo = true;
	if tCoureurs[indice].NbClasses < params.bibo_m2 then
		bolBibo = false;
	end
	for j = table_tps:GetNbRows() -1, 0, -1 do
		if table_tps:GetCellInt('Tps_chrono', j) < 0 then
			table_tps:RemoveRowAt(j);
		end
	end
	for j = table_abddsq:GetNbRows() -1, 0, -1 do
		if table_abddsq:GetCellInt('Tps_chrono', j) > 0 then
			table_abddsq:RemoveRowAt(j);
		end
	end
	local table_bibo = table_tps:Copy();
	table_bibo:OrderBy('Tps_chrono');
	if bolBibo == false then
		tps_bibo = table_bibo:GetCellInt('Tps_chrono', table_bibo:GetNbRows() -1);
		table_tps:RemoveAllRows()
	else
		tps_bibo = table_bibo:GetCellInt('Tps_chrono', params.bibo_m2 -1);
	end
	for j = table_bibo:GetNbRows() -1 , 0, -1 do
		if table_bibo:GetCellInt('Tps_chrono', j) > tps_bibo then
			table_bibo:RemoveRowAt(j);
		end
	end
	table_bibo:OrderBy('Tps_chrono DESC, Tps_bonus');
	for i = 0, table_bibo:GetNbRows() -1 do
		params.rang = params.rang + 1;
		local code_coureur = table_bibo:GetCell('Code_coureur', i);
		local r = table_tps:GetIndexRow('Code_coureur', code_coureur);
		if r >= 0 then
			table_tps:RemoveRowAt(r);
		end
		traite = traite + 1;
		traite_bibo = traite_bibo + 1;
		local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement.." And Code_manche = 2 And Code_coureur = '"..code_coureur.."'";
		base:TableLoad(tResultat_Manche, cmd);
		if tResultat_Manche:GetNbRows() > 0 then
			tResultat_Manche:SetCell('Rang', 0, params.rang);
			tResultat_Manche:SetCell('Reserve', 0, tCoureurs[indice].Reserve);
			base:TableUpdate(tResultat_Manche, 0);
		else
			local row = tResultat_Manche:AddRow();
			tResultat_Manche:SetCell('Code_evenement', row, params.code_evenement);
			tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
			tResultat_Manche:SetCell('Code_manche', row, 2);
			tResultat_Manche:SetCell('Rang', row, params.rang);
			tResultat_Manche:SetCell('Reserve', row, tCoureurs[indice].Reserve);
			base:TableInsert(tResultat_Manche, row);
		end
	end
	if table_tps:GetNbRows() > 0 then
		table_tps:OrderBy('Tps_chrono, Tps_bonus DESC');
		for i = 0, table_tps:GetNbRows() -1 do
			params.rang = params.rang + 1;
			local code_coureur = table_tps:GetCell('Code_coureur', i);
			local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement.." And Code_manche = 2 And Code_coureur = '"..code_coureur.."'";
			base:TableLoad(tResultat_Manche, cmd);
			traite = traite + 1;
			traite_tps = traite_tps + 1;
			if tResultat_Manche:GetNbRows() > 0 then
				tResultat_Manche:SetCell('Rang', 0, params.rang);
				tResultat_Manche:SetCell('Reserve', 0, tCoureurs[indice].Reserve);
				base:TableUpdate(tResultat_Manche, 0);
			else
				local row = tResultat_Manche:AddRow();
				tResultat_Manche:SetCell('Code_evenement', row, params.code_evenement);
				tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
				tResultat_Manche:SetCell('Code_manche', row, 2);
				tResultat_Manche:SetCell('Rang', row, params.rang);
				tResultat_Manche:SetCell('Reserve', row, tCoureurs[indice].Reserve);
				base:TableInsert(tResultat_Manche, row);
			end
		end
	end
	if params.abd_dsq_repartent == 'Oui' and params.abd_dsq_apres_classes == 'Non' then
		if table_abddsq:GetNbRows() > 0 then
			local orderby = 'Tps_bonus '..params.bib_abddsq_ordre;
			table_abddsq:OrderBy(orderby);
			for i = 0, table_abddsq:GetNbRows() -1 do
				params.rang = params.rang + 1;
				local code_coureur = table_abddsq:GetCell('Code_coureur', i);
				local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..params.code_evenement.." And Code_manche = 2 And Code_coureur = '"..code_coureur.."'";
				base:TableLoad(tResultat_Manche, cmd);
				traite = traite + 1;
				traite_abddsq = traite_abddsq + 1;
				if tResultat_Manche:GetNbRows() > 0 then
					tResultat_Manche:SetCell('Rang', 0, params.rang);
					tResultat_Manche:SetCell('Reserve', 0, tCoureurs[indice].Reserve);
					base:TableUpdate(tResultat_Manche, 0);
				else
					local row = tResultat_Manche:AddRow();
					tResultat_Manche:SetCell('Code_evenement', row, params.code_evenement);
					tResultat_Manche:SetCell('Code_coureur', row, code_coureur);
					tResultat_Manche:SetCell('Code_manche', row, 2);
					tResultat_Manche:SetCell('Rang', row, params.rang);
					tResultat_Manche:SetCell('Reserve', row, tCoureurs[indice].Reserve);
					base:TableInsert(tResultat_Manche, row);
				end
			end
		end
	end
	-- adv.Alert('reserve = '..tCoureurs[indice].Reserve..', traite = '..traite..', traite_bibo = '..traite_bibo..', traite_tps = '..traite_tps..', traite_abddsq = '..traite_abddsq);
end

function OnTirageDossard(tablex, nombre, nombre_point)
	tablex:OrderBy('Point');
	local reserve = tablex:GetCellInt('Reserve', 0);
	local nb_aexequo = 0;
	local table_bibo = tablex:Copy();
	local table_pts = tablex:Copy();
	local table_pts0 = tablex:Copy();
	for j = table_pts0:GetNbRows() -1, 0, -1 do
		if table_pts0:GetCellDouble('Point', j, -1) >= 0 then
			table_pts0:RemoveRowAt(j);
		end
	end
	for j = table_pts:GetNbRows() -1, 0, -1 do
		if table_pts:GetCellDouble('Point', j, -1) < 0 then
			table_pts:RemoveRowAt(j);
		end
	end
	local pts_bibo = -1;
	local nb_exeaquo = 0;
	if nombre >= params.bibo_m1 then
		if nombre_point >= params.bibo_m1 then
			pts_bibo = tablex:GetCellDouble('Point', params.bibo_m1 - 1);
		else
			pts_bibo = tablex:GetCellDouble('Point', nombre_point -1);
		end
	elseif nombre_point > 0 then
		pts_bibo = tablex:GetCellDouble('Point', nombre_point -1);
	end
	if pts_bibo < 0 then
		tablex:OrderRandom();
		for j = 0, tablex:GetNbRows() -1 do
			if tablex:GetCellInt('Reserve', j) <=20 then
				tablex:SetCell('Dossard', j , params.dossard);
				params.dossard = params.dossard + 1;
			end
		end
		base:TableBulkUpdate(tablex, 'Dossard', 'Resultat');
	else
		for j = table_bibo:GetNbRows() -1, 0, -1 do
			local pts = table_bibo:GetCellDouble('Point', j, -1);
			if pts > pts_bibo or pts < 0 then
				table_bibo:RemoveRowAt(j);
			end
		end
		table_bibo:OrderRandom();
		for j = 0, table_bibo:GetNbRows() -1 do
			if table_bibo:GetCellInt('Reserve', j) <=20 then
				local code_coureur = table_bibo:GetCell('Code_coureur', j);
				table_bibo:SetCell('Dossard', j , params.dossard);
				local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
				if r >= 0 then
					tResultat:SetCell('Dossard', r, params.dossard);
				end
				params.dossard = params.dossard + 1;
				local row = table_pts:GetIndexRow('Code_coureur', code_coureur);
				if row >= 0 then
					table_pts:RemoveRowAt(row);
				end
			end
		end
		if table_pts:GetNbRows() > 0 then
			if table_pts:GetCellInt('Reserve', j) <=20 then
				local nb_aexequo = 0;
				local code_next = "-1";
				local r_next = -1;
				local rang_egal = -1;
				for j = 0, table_pts:GetNbRows() -1 do
					local code_coureur = table_pts:GetCell('Code_coureur', j);
					local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
					local pts = table_pts:GetCellDouble('Point', j);
					local pts_next = -1;
					table_pts:SetCell('Dossard', j , params.dossard);
					if j < tablex:GetNbRows() -1 then
						pts_next = table_pts:GetCellDouble('Point', j+1);
						code_next = table_pts:GetCell('Code_coureur', j+1);
						local r_next = tResultat:GetIndexRow('Code_coureur', code_next);
						if pts == pts_next then
							nb_aexequo = nb_aexequo + 1;
						else
							nb_aexequo = 0;
						end	
						if nb_aexequo > 0 then
							if nb_aexequo == 1 then
								rang_egal = params.dossard;
								if params.tExaequo[#params.tExaequo] ~= rang_egal then
									table.insert(params.tExaequo, rang_egal);
								end
								tResultat:SetCell('Rang', r, rang_egal);
								tResultat:SetCell('Rang', r_next, rang_egal);
							else
								tResultat:SetCell('Rang', r_next, rang_egal);
							end
						end
					end
					if r >= 0 then
						tResultat:SetCell('Dossard', r, params.dossard);
						if nb_aexequo > 0 then
						end
					end
					params.dossard = params.dossard + 1;
				end
			end
		end
		table_pts0:OrderRandom();
		if table_pts0:GetNbRows() > 0 then
			for j = 0, table_pts0:GetNbRows() -1 do
				if table_pts0:GetCellInt('Reserve', j) <=20 then
					local code_coureur = table_pts0:GetCell('Code_coureur', j);
					table_pts0:SetCell('Dossard', j , params.dossard);
					local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
					if r >= 0 then
						tResultat:SetCell('Dossard', r, params.dossard);
					end
					params.dossard = params.dossard + 1;
				end
			end
		end
	end
	base:TableBulkUpdate(tResultat);
end

function GetNodeXMLData()
	XML = "./process/dossard_TirageEspritRacing.xml";
	params.doc = xmlDocument.Create(XML);
	params.nodeDefault = params.doc:FindFirst('root/default');
	params.nodeDefaultDames = params.doc:FindFirst('root/default/dames');
	params.nodeDefaultHommes = params.doc:FindFirst('root/default/hommes');
	params.nodeConfig = params.doc:FindFirst('root/config');
	params.nodeDames = params.doc:FindFirst('root/config/dames');
	params.nodeHommes = params.doc:FindFirst('root/config/hommes');
	params.bibo_m1 = tonumber(params.nodeConfig:GetAttribute('bibo_m1')) or 10;
	params.bibo_m2 = tonumber(params.nodeConfig:GetAttribute('bibo_m2')) or 10;
	params.bib_abddsq_ordre = params.nodeConfig:GetAttribute('bib_abddsq_ordre');
	if params.bib_abddsq_ordre ~= 'ASC' and params.bib_abddsq_ordre ~= 'DESC'  then
		params.bib_abddsq_ordre = 'ASC';
	end
	params.abd_dsq_repartent = params.nodeConfig:GetAttribute('abd_dsq_repartent');
	if params.abd_dsq_repartent ~= 'Oui' and params.abd_dsq_repartent ~= 'Non' then
		params.abd_dsq_repartent = 'Oui'
	end
	params.abd_dsq_apres_classes = params.nodeConfig:GetAttribute('abd_dsq_apres_classes');
	if params.abd_dsq_apres_classes ~= 'Oui' and params.abd_dsq_apres_classes ~= 'Non'  then
		params.abd_dsq_apres_classes = 'Oui';
	end
	tCoureurs = {};
	tCodes = {};
	tDossardsNonTires = {};
	params.reserve_maxi_dames = 0;
	bolOK = false;
	params.tGroupesDames = {};
	params.tGroupesHommes = {};
	local attribute = params.nodeDames:GetAttributes();
	while attribute ~= nil do
		local name = attribute:GetName();
		local strnumber = string.gsub(name, "%D", "");
		local reserve = tonumber(strnumber) or 1;
		params.reserve_maxi_dames = math.max(params.reserve_maxi_dames, reserve);
		local value = attribute:GetValue();
		table.insert(tCoureurs, {Sexe = 'F', Categ = value, Reserve = reserve, Nombre = 0, NbPoint = 0, NbClasses = 0, NbABD = 0, NbDSQ = 0});
		table.insert(params.tGroupesDames, value);
		local cmd = "Update Resultat Set Reserve = "..reserve.." Where Code_evenement = "..params.code_evenement.." And Sexe = 'F' and Categ In("..tCoureurs[#tCoureurs].Categ..")";
		base:Query(cmd);
		attribute = attribute:GetNext();
	end
	
	local attribute = params.nodeHommes:GetAttributes();
	while attribute ~= nil do
		local name = attribute:GetName();
		local reserve = tonumber(name:sub(-1)) or 1;
		local value = attribute:GetValue();
		table.insert(tCoureurs, {Sexe = 'M', Categ = value, Reserve = reserve, Nombre = 0, NbPoint = 0, NbClasses = 0, NbABD = 0, NbDSQ = 0});
		table.insert(params.tGroupesHommes, value);
		local cmd = "Update Resultat Set Reserve = "..reserve.." Where Code_evenement = "..params.code_evenement.." And Sexe = 'M' and Categ In("..tCoureurs[#tCoureurs].Categ..")";
		base:Query(cmd);
		attribute = attribute:GetNext();
	end
	
	SortTable(tCoureurs);
	local cmd = "Update Resultat Set Reserve = "..tCoureurs[#params.tGroupesDames].Reserve.." Where Code_evenement = "..params.code_evenement.." And Sexe = 'F' And Categ = 'U18'";
	base:Query(cmd);
	local cmd = "Update Resultat Set Reserve = "..tCoureurs[#tCoureurs].Reserve.." Where Code_evenement = "..params.code_evenement.." And Sexe = 'M' And Categ = 'U18'";
	base:Query(cmd);

	local cmd = "Update Resultat Set Reserve = 21 Where Code_evenement = "..params.code_evenement.." And Sexe = 'F' And Reserve Is Null";
	base:Query(cmd);
	table.insert(tCoureurs, {Sexe = 'F', Categ = value, Reserve = 20, Nombre = 0, NbPoint = 0, NbClasses = 0, NbABD = 0, NbDSQ = 0});
	local cmd = "Update Resultat Set Reserve = 22 Where Code_evenement = "..params.code_evenement.." And Sexe = 'M' And Reserve Is Null";
	base:Query(cmd);
	table.insert(tCoureurs, {Sexe = 'M', Categ = value, Reserve = 21, Nombre = 0, NbPoint = 0, NbClasses = 0, NbABD = 0, NbDSQ = 0});
	local cmd = "Select * From Resultat Where Code_evenement = "..params.code_evenement.." Order By Reserve, Point";
	base:TableLoad(tResultat, cmd);
	params.non_tires_message = '';
	for i = 0, tResultat:GetNbRows() -1 do
		if tResultat:GetCellInt('Reserve', i) == 21 or tResultat:GetCellInt('Reserve', i) == 22 then
			local texte = tResultat:GetCell('Code_coureur', i)..' - '..tResultat:GetCell('Nom', i)..'  '..tResultat:GetCell('Prenom', i)..'  ('..tResultat:GetCell('Sexe', i)..')';
			table.insert(tDossardsNonTires, texte);
			params.non_tires_message = params.non_tires_message..texte..'\n';
		end
	end
	GetReserveDossard(false);
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
	params.y = 50;
	params.version = "1.3";
	base = base or sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	params.code_saison = tEvenement:GetCell('Code_saison', 0);
	params.code_entite = tEvenement:GetCell("Code_entite",0);
	params.code_activite = tEvenement:GetCell("Code_activite",0);
	tResultat = base:GetTable('Resultat');
	tResultat_Copy = tResultat:Copy();
	ReplaceTableEnvironnement(tResultat_Copy, '_Resultat_Copy');
	tDraw = tResultat:Copy();
	ReplaceTableEnvironnement(tDraw, '_tDraw');
	tDraw_Copy = tResultat:Copy();
	ReplaceTableEnvironnement(tDraw, '_tDraw_Copy');
	
	local cmd = "Update Resultat Set Rang = Null, Reserve = Null Where Code_evenement = "..params.code_evenement;
	base:Query(cmd);
	tCoureur = {};
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tResultat:OrderBy('Point');
	tResultat:SetCounter('Sexe');
	tResultat:SetCounter('Categ');
	GetNodeXMLData();
	params.nb_dames = tResultat:GetCounterValue('Sexe', 'F');
	params.nb_hommes = tResultat:GetCounterValue('Sexe', 'M');
	params.dossard1 = tResultat:GetCellInt('Dossard', 0);
	tResultat_Manche = base:GetTable('Resultat_Manche');
	tResultat_Manche_Copy = tResultat_Manche:Copy();
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	tCategorie = base:GetTable('Categorie');
	
	if params.code_entite ~= 'FFS' then
		local msg = "Ce scénario n'est valable que pour les courses FFS !!";
		app.GetAuiFrame():MessageBox(msg, "Attention aux erreurs !!!", msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
		return;
	end
	tDraw = tResultat:Copy();
	tDraw:SetCounter('Reserve');
	for i = 1, #tCoureurs do
		tCoureurs[i].Nombre = tDraw:GetCounterValue('Reserve', tCoureurs[i].Reserve);
	end
	
	dlgConfig = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Configuration du tirage', 
		icon='./res/32x32_ffs.png'
		});
	dlgConfig:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		node_value = 'config'
	});

	-- Toolbar Principale ...
	local tbconfig = dlgConfig:GetWindowName('tbconfig');
	assert(tbconfig ~= nil);
	tbconfig:AddStretchableSpace();
	local btnSetup = tbconfig:AddTool("Back Office", "./res/32x32_param.png");
	tbconfig:AddSeparator();
	local btnSave = tbconfig:AddTool("Lancer le tirage", "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();

	dlgConfig:GetWindowName('manche'):Clear();
	dlgConfig:GetWindowName('manche'):Append('Manche 1');
	dlgConfig:GetWindowName('manche'):Append('Manche 2');
	dlgConfig:GetWindowName('manche'):SetSelection(0);
	
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			params.code_manche = dlgConfig:GetWindowName('manche'):GetSelection() + 1;
			if params.code_manche == 1 then
				params.tExaequo = {};
				OnTirageManche1();				
				dlgConfig:EndModal(idButton.OK);
			else
				local msg = "Ce tirage effacera les temps avant disqualification !!!\nVoulez-vous poursuivre ?";
				if app.GetAuiFrame():MessageBox(msg, "Attention !!!"
					, msgBoxStyle.YES_NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then
					return;
				end
				GetReserveDossard(true)
				OnTirageManche2();				
				dlgConfig:EndModal(idButton.OK);
			end
		end, btnSave); 
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			OnSetup();
		 end,  btnSetup);
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:EndModal(idButton.KO);
		end, btnClose); 
	
	
	dlgConfig:Fit();
	dlgConfig:ShowModal();
	

	local cmd = 'Update Resultat Set Rang = NULL Where Code_evenement = '..params.code_evenement;
	base:Query(cmd);
	if params.doc then params.doc:Delete(); end
	
	return true;
end
