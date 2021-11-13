-- Matrices / Challenges et Combinés pour skiFFS
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function ReplaceTableEnvironnement(t, name)		-- replace la table créée dans l'environnement de la base de donnée pour éviter les memory leaks
	if type(t) ~= 'userdata' then
		return;
	end
	t:SetName(name);
	if base:GetTable(name) ~= nil then
		base:RemoveTable(name);
	end
	base:AddTable(t);
end

function ConstructionCriteres()
	Criteres = {};
	prendreentout = 0;
	for i = 1, 6 do
		local ok = false;
		local prendre = tonumber(dlgConfiguration:GetWindowName('prendre'..i):GetValue()) or 0;
		local sexe = '';
		local filtre = '';
		ok = true;
		if prendre > 0 then
			prendreentout = prendreentout + prendre;
			local libelle = '';
			local sexe = dlgConfiguration:GetWindowName('comboPrendre'..i):GetValue();
			local categ = dlgConfiguration:GetWindowName('comboCateg'..i):GetValue();
			local anneedebut = tonumber(dlgConfiguration:GetWindowName('anneeDebut'..i):GetValue()) or 0;
			local anneefin = tonumber(dlgConfiguration:GetWindowName('anneeFin'..i):GetValue()) or 0;
			if string.find(sexe, 'ou') then
				sexe = 'T';
			elseif string.find(sexe, 'dame') then
				sexe = 'F';
			elseif string.find(sexe, 'homme') then
				sexe = 'M';
			else
				sexe = '?';
				ok = false;
			end	
			if categ:len() > 0 then
				anneedebut = 0;
				anneefin = 0;
			end
			if categ:len() == 0 and anneedebut == 0 and anneefin == 0 then
				ok = false;
			else
				if categ:len() > 0 then
					filtre = 'Categ';
					valeur1 = categ;
					valeur2 = -1;
				elseif anneedebut > 0 and anneefin > 0 then
					filtre = 'An';
					valeur1 = anneedebut;
					valeur2 = anneefin;
				end				
			end
			if ok == true then
				if sexe == 'T' then
					libelle = prendre..' hommes ou dames';
					carsexe = ' né(e)s';
				elseif sexe == 'F' then
					libelle = prendre..' dames';
					carsexe = ' nées';
				else
					libelle = prendre..' hommes';
					carsexe = ' nés';
				end
				if filtre == 'Categ' then
					libelle = libelle..' '..valeur1;
				else
					libelle = libelle..carsexe..' entre '..valeur1..' et '..valeur2;
				end
				table.insert(Criteres, {Prendre = prendre, Sexe = sexe, Filtre = filtre, Valeur1 = valeur1, Valeur2 = valeur2, ComboQuoi = comboQuoi, IndexQuoi = indexQuoi, Libelle = libelle});
			end
		end
	end
end

function Calculer()
	tRanking = tRanking_Sav:Copy();
	local id_equipier = 0;
	dlgConfiguration:Bind(eventType.COMBOBOX, OnChangecomboGroupe, dlgConfiguration:GetWindowName('comboGroupe'));
	dlgConfiguration:Bind(eventType.COMBOBOX, OnChangecomboTpsPts, dlgConfiguration:GetWindowName('comboTpsPts'));
	dlgConfiguration:Bind(eventType.COMBOBOX, OnChangecomboQuoi, dlgConfiguration:GetWindowName('comboQuoi'));
	comboGroupe = dlgConfiguration:GetWindowName('comboGroupe'):GetValue();
	comboTpsPts = dlgConfiguration:GetWindowName('comboTpsPts'):GetValue();
	comboQuoi = dlgConfiguration:GetWindowName('comboQuoi'):GetValue();
	indexQuoi = indexQuoi or 0;
	
	if comboGroupe:len() == 0 or comboTpsPts:len() == 0 or comboQuoi:len() == 0 then
		app.GetAuiFrame():MessageBox(
			"Merci de renseigner tous les choix du regroupement !!!", 
			"Erreurs",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
		return;
	end
	if indexQuoi > 0 then	-- on veut les n-1 meilleures manches.
		trunsTps = {};
		trunsPts = {};
		for idxrun = 1, nombre_de_manche do
			table.insert(trunsTps, 'Tps'..idxrun);
			table.insert(trunsPts, 'Pts'..idxrun);
		end
		tRanking:ComputeBestTimeX('Tps_total', trunsTps, indexQuoi);
		tRanking:ComputeBestPointX('Pts_total', trunsPts, indexQuoi, true);
	end
	local bolRechercherComite = dlgConfiguration:GetWindowName('chkCoureurEquipe'):GetValue();
	bolNonClasses = dlgConfiguration:GetWindowName('chkNonClasses'):GetValue();
	for row = tRanking:GetNbRows() -1, 0, -1 do
		local boldelete = false;
		if bolRechercherComite == true and tRanking:GetCell('Comite', row) == 'EQ' then
			code_coureur = tRanking:GetCell('Code_coureur', row);
			Coureur = base:TableLoad("Select * From Coureur Where Code_coureur = '"..code_coureur.."'")
			if Coureur:GetNbRows() > 0 then
				tRanking:SetCell('Comite', row, Coureur:GetCell('Code_comite', 0));
			end
		end
		if tRanking:GetCell(comboGroupe, row):len() == 0 then
			boldelete = true;
		else
			if indexQuoi == 0 then		-- au général
				local tps = tRanking:GetCellInt('Tps', row, -1);
				if tps > 0 then
					tRanking:SetCell('Tps_total', row, tps);
					tRanking:SetCell('Pts_total', row, tRanking:GetCellDouble('Pts', row));
				else
					boldelete = true;
				end
			end
		end
		if bolTemps == true then
			if tRanking:GetCellInt('Tps_total', row) < 0 then	-- valeur initialisée à -1 dans main()
				boldelete = true;
			end
		elseif tRanking:GetCellDouble('Pts_total', row) < 0 then
			boldelete = true;
		end
		if boldelete == true then
			tRanking:RemoveRowAt(row);
		end
	end
	if bolTemps == true then
		tRanking:SetRanking('Clt_total', 'Tps_total,');
	else
		tRanking:SetRanking('Clt_total', 'Pts_total,');
	end
	tRanking:OrderBy(comboGroupe..',Clt_total');
	Groupe = {};
	groupes = {};
	for row = 0, tRanking:GetNbRows() -1 do 
		groupelu = tRanking:GetCell(comboGroupe, row);
		if groupelu:len() == 0 then
			groupelu = '??';
		end
		Groupe[groupelu] = Groupe[groupelu] or {};
		Groupe[groupelu].Row_depart = Groupe[groupelu].Row_depart or row;
		if row == 0 then
			groupeencours = groupelu;
		end
		if groupelu == groupeencours then
			Groupe[groupeencours].Row_fin = row;
		else
			groupeencours = groupelu;
			Groupe[groupeencours].Row_fin = row;
		end
	end
	if comboGroupe == 'Comite' and bolCoureurEquipe == true then
		cmd = 'Select Comite Groupe From Resultat Where Code_evenement = '..code_evenement.." And Comite <> 'EQ' Group By "..comboGroupe;
	else
		-- cmd = 'Select '..comboGroupe..' Groupe From Resultat Where Code_evenement = '..code_evenement..' And Not '..comboGroupe..' Is Null Group By '..comboGroupe;
		cmd = 'Select '..comboGroupe..' Groupe From Resultat Where Code_evenement = '..code_evenement..' And LENGTH('..comboGroupe..') > 0 Group By '..comboGroupe;
	end
	Resultat = base:TableLoad(cmd);
	Body = Resultat:Copy();
	Body:SetName('Body');
	
	ReplaceTableEnvironnement(Body, 'Body');
	Body:AddColumn({ name = 'Rang', label = 'Rang', type = sqlType.LONG, style = sqlStyle.NULL });
	Body:AddColumn({ name = 'Clt_equipe', label = 'Clt_equipe', type = sqlType.RANKING, style = sqlStyle.NULL });
	Body:AddColumn({ name = 'Nb_equipiers', label = 'Nb_equipiers', type = sqlType.LONG, style = sqlStyle.NULL });
	if bolTemps == true then
		Body:AddColumn({ name = 'Tps_equipe', label = 'Tps_equipe', type = sqlType.CHRONO, style = sqlStyle.NULL });
	else
		Body:AddColumn({ name = 'Pts_equipe', label = 'Pts_equipe', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	end
	Body:AddColumn({ name = 'Txt_data_equipe', label = 'Tps_equipe', type = sqlType.CHAR, width = 20, style = sqlStyle.NULL });
	tableGroupe = {};
	for rowbody = 0, Body:GetNbRows() -1 do
		table.insert(tableGroupe, Body:GetCell('Groupe', rowbody));
		Body:SetCell('Rang', rowbody, 1);
	end
	if bolMulti == true then
		for index = 1, #tableGroupe do
			local groupe = tableGroupe[index];
			for i = 2, 9 do
				local row = Body:AddRow();
				Body:SetCell('Groupe', row, groupe);
				Body:SetCell('Rang', row, i);
			end
		end
	end
	Body:OrderBy('Groupe, Rang');
	ConstructionCriteres()
	
	if #Criteres < 1 then
		app.GetAuiFrame():MessageBox(
			"Merci de renseigner tous les critères du regroupement !!!", 
			"Erreurs",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
		return;
	end
	id_equipier = 0;
	for i = 1, #Criteres do
		for j = 1, Criteres[i].Prendre do
			id_equipier = id_equipier + 1;
			Body:AddColumn({ name = 'Clt'..id_equipier, label = 'Clt'..id_equipier, type = sqlType.LONG, style = sqlStyle.NULL });
			Body:AddColumn({ name = 'Code'..id_equipier, label = 'Code'..id_equipier, type = sqlType.CHAR, width = 12, style = sqlStyle.NULL });
			Body:AddColumn({ name = 'Data'..id_equipier, label = 'Data'..id_equipier, type = sqlType.CHAR, width = 12, style = sqlStyle.NULL });
			Body:AddColumn({ name = 'Comite'..id_equipier, label = 'Comite'..id_equipier, type = sqlType.CHAR, width = 3, style = sqlStyle.NULL });
		end
		Body:AddColumn({ name = 'Critere'..i..'_ok', label = 'Critere'..i..'_ok', type = sqlType.LONG, style = sqlStyle.NULL });
	end
	Body:AddColumn({ name = 'Nb_critere', label = 'Nb_critere', type = sqlType.LONG, style = sqlStyle.NULL });
	for rowbody = 0, Body:GetNbRows() -1 do
		Body:SetCell('Nb_equipiers', rowbody, 0);
		groupe = Body:GetCell('Groupe', rowbody);
		if Groupe[groupe] ~= nil then
			Body:SetCell('Tps_equipe', rowbody, 0);
			Body:SetCell('Pts_equipe', rowbody, 0);
			id_equipier = 0;
			for idxcritere = 1, #Criteres do
				Body:SetCell('Critere'..idxcritere..'_ok', rowbody, 0);
				local pris_critere = 0;
				local val_critere = 0;
				local prendre_critere = Criteres[idxcritere].Prendre;
				local sexe_critere = Criteres[idxcritere].Sexe;
				local filtre_critere = Criteres[idxcritere].Filtre;
				local valeur1_critere = Criteres[idxcritere].Valeur1;
				local valeur2_critere = Criteres[idxcritere].Valeur2;
				for row = Groupe[groupe].Row_depart, Groupe[groupe].Row_fin do
					bolconvient = true;
					local code_coureur = tRanking:GetCell('Code_coureur', row);
					local sexe = tRanking:GetCell('Sexe', row);
					local code_comite = tRanking:GetCell('Comite', row);
					if sexe_critere == 'T' then
						sexe = 'T';
					end
					local categ = tRanking:GetCell('Categ', row);
					local an = tRanking:GetCellInt('An', row);
					if sexe ~= Criteres[idxcritere].Sexe then
						bolconvient = false;
					end
					if filtre_critere == 'Categ' then
						if categ ~= valeur1_critere then
							bolconvient = false;
						end
					else
						if an < valeur1_critere or an > valeur2_critere then
							bolconvient = false;
						end
					end
					if tRanking:GetCell('Status', row) == 'O' then	-- s'il est déjà pris dans un critère, on ne doit pas le reprendre
						bolconvient = false;
					end
					if bolTemps == true then
						if indexQuoi > 0 then
							valeur_lue = tRanking:GetCellInt('Tps_total', row, -1);
						else
							valeur_lue = tRanking:GetCellInt('Tps', row, -1);
						end
					else
						if indexQuoi > 0 then
							valeur_lue = tRanking:GetCellDouble('Pts_total', row, -1);
						else
							valeur_lue = tRanking:GetCellDouble('Pts', row, -1);
						end
					end
					if valeur_lue < 0 then
						bolconvient = false
					end
					if bolconvient == true then
						if pris_critere < prendre_critere then
							pris_critere = pris_critere + 1;
							id_equipier = id_equipier + 1;
							Body:SetCell('Nb_equipiers', rowbody, Body:GetCellInt('Nb_equipiers', rowbody) + 1);
							Body:SetCell('Code'..id_equipier, rowbody, code_coureur);
							Body:SetCell('Comite'..id_equipier, rowbody, code_comite);
							tRanking:SetCell('Status', row, 'O');
							if bolTemps == true then
								if indexQuoi > 0 then
									valeur_lue = tRanking:GetCellInt('Tps_total', row);
								else
									valeur_lue = tRanking:GetCellInt('Tps', row);
								end
								Body:SetCell('Tps_equipe', rowbody, Body:GetCellInt('Tps_equipe', rowbody) + valeur_lue);
								Body:SetCell('Txt_tps_equipe', rowbody, Body:GetCell('Tps_equipe', rowbody));
								Body:SetCell('Data'..id_equipier, rowbody, tRanking:GetCell('Tps_total', row));
							else
								if indexQuoi > 0 then
									valeur_lue = tRanking:GetCellDouble('Pts_total', row);
								else
									valeur_lue = tRanking:GetCellDouble('Pts', row);
								end
								Body:SetCell('Pts_equipe', rowbody, Body:GetCellDouble('Pts_equipe', rowbody) + valeur_lue);
								if valeur_lue == 0 then
									Body:SetCell('Data'..id_equipier, rowbody, '0');
								else
									Body:SetCell('Data'..id_equipier, rowbody, tRanking:GetCell('Pts_total', row));
								end
							end
							Body:SetCell('Clt'..id_equipier, rowbody, tRanking:GetCellInt('Clt_total', row));
							if pris_critere == prendre_critere then
								if bolTemps == true then
									Body:SetCell('Txt_data_equipe', rowbody, Body:GetCell('Tps_equipe', rowbody));
								else
									Body:SetCell('Txt_data_equipe', rowbody, Body:GetCell('Pts_equipe', rowbody));
								end
								Body:SetCell('Critere'..idxcritere..'_ok', rowbody, 1);
								Body:SetCell('Nb_critere', rowbody, Body:GetCellInt('Nb_critere', rowbody)+1);			
								break;
							end
						end
					end
				end
				if Body:GetCellInt('Critere'..idxcritere..'_ok', rowbody) == 0 then
					if bolTemps == true then
						Body:SetCellNull('Tps_equipe', rowbody);
					else
						Body:SetCell('Pts_equipe', rowbody, 1000000);
					end
				end
			end
		end
		if Body:GetCellInt('Nb_critere', rowbody) < #Criteres then
			if bolTemps == true then
				Body:SetCellNull('Tps_equipe', rowbody);
			else
				Body:SetCell('Pts_equipe', rowbody, 1000000);
			end
		end
	end
	if bolTemps == true then
		Body:SetRanking('Clt_equipe', 'Tps_equipe', '');
	else
		Body:SetRanking('Clt_equipe', 'Pts_equipe', '');
	end
	for row = Body:GetNbRows() -1, 0, -1 do
		boldelete = false;
		if Body:GetCellInt('Nb_equipiers', row) == 0 then
			boldelete = true;
		else
			if bolNonClasses == true then
				if Body:GetCellInt('Nb_equipiers', row) < prendreentout then
					boldelete = true;
				end
			else
				if Body:GetCellInt('Nb_equipiers', row) < prendreentout then
					Body:SetCell('Clt_equipe', row, 0);
					Body:SetCellNull('Txt_data_equipe', row);
				end
			end
		end
		if boldelete == true then
			Body:RemoveRowAt(row);
		end
	end
	tRanking:Snapshot('tRanking.db3');
	Body:Snapshot('Body.db3');
	OnPrint();
end

function OnPrint()
	local strcritere = '';
	local sep = '';
	local virgule = '';
	for idxcritere = 1, #Criteres do
		if idxcritere > 1 then
			virgule = ', ';
		end
		if idxcritere == 4 then
			sep = '\n';
		else
			sep = '';
		end
		strcritere = sep..strcritere..virgule..Criteres[idxcritere].Libelle;
	end
	tpspts = 'T';
	if not bolTemps then
		tpspts = 'P';
	end
	strtitre = Evenement:GetCell('Nom', 0)..'\nRegroupement de coureurs';
	if bolMulti == true then
		multi = 1;
	else
		multi = 0;
	end
	report = wnd.LoadTemplateReportXML({
		xml = './edition/editionRegroupement.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'print',
		title = strtitre,
		base = base,
		body = Body,
		margin_first_top = 150,
		margin_first_left = 100,
		margin_first_right = 150,
		margin_first_bottom = 100,
		margin_top = 150,
		margin_left = 100,
		margin_right = 150,
		margin_bottom = 100,
		paper_orientation = 'portrait',
		params = {Titre = 'Edition du Regroupement de coureurs', TpsPts = tpspts, Version = version_script, Code_evenement = code_evenement, Criteres = strcritere, NbEquipiers = prendreentout, IndexQuoi = indexQuoi, NbManches = nombre_de_manche, Multi = multi}
	});
	-- report:SetZoom(10)
end

function AffichedlgConfiguration()
	-- Creation de la boîte de dialogue principale
	dlgConfiguration = wnd.CreateDialog(
		{
		width = dlgPosit.width,
		height = dlgPosit.height,
		x = dlgPosit.x,
		y = dlgPosit.y,
		label='Paramètres du regroupement', 
		icon='./res/32x32_ffs.png'
		});

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgConfiguration:LoadTemplateXML({ 
		xml = './edition/editionRegroupement.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'config_generale' 		-- Facultatif si le node_name est unique ...
	});

	-- remplissage des Combo
	
	-- Toolbar 
	local tbedit = dlgConfiguration:GetWindowName('tbedit');
	tbedit:AddStretchableSpace();
	local btnCalculer = tbedit:AddTool("Valider", "./res/32x32_calc.png");
	tbedit:AddSeparator();
	local btnRetour = tbedit:AddTool("Sortie", "./res/32x32_exit.png");
	tbedit:AddStretchableSpace();
	tbedit:Realize();
	
	-- Bind
	tbedit:Bind(eventType.MENU, Calculer, btnCalculer);
	tbedit:Bind(eventType.MENU, function(evt) dlgConfiguration:EndModal(idButton.CANCEL) end, btnRetour);
	dlgConfiguration:Bind(eventType.COMBOBOX, OnChangecomboGroupe, dlgConfiguration:GetWindowName('comboGroupe'));
	dlgConfiguration:Bind(eventType.COMBOBOX, OnChangecomboTpsPts, dlgConfiguration:GetWindowName('comboTpsPts'));
	dlgConfiguration:Bind(eventType.COMBOBOX, OnChangecomboQuoi, dlgConfiguration:GetWindowName('comboQuoi'));
	dlgConfiguration:Bind(eventType.CHECKBOX, OnChangeMulti, dlgConfiguration:GetWindowName('chkMulti'));
	for i = 1, 6 do
		dlgConfiguration:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangecomboPrendre(i)
		end, 
		dlgConfiguration:GetWindowName('comboPrendre'..i));
		
		dlgConfiguration:Bind(eventType.TEXT, 
		function(evt) 
			OnChangePrendre(i)
		end, 
		dlgConfiguration:GetWindowName('prendre'..i));
		
		dlgConfiguration:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangecomboCateg(i)
		end, 
		dlgConfiguration:GetWindowName('comboCateg'..i));
		
		dlgConfiguration:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangecomboAnneeDebut(i)
		end, 
		dlgConfiguration:GetWindowName('anneeDebut'..i));
	end

	dlgConfiguration:GetWindowName('chkCoureurEquipe'):Enable(bolCoureurEquipe);
	dlgConfiguration:GetWindowName('chkNonClasses'):SetValue(true);

	dlgConfiguration:GetWindowName('comboGroupe'):Clear();
	dlgConfiguration:GetWindowName('comboGroupe'):Append('Nation');
	dlgConfiguration:GetWindowName('comboGroupe'):Append('Comite');
	dlgConfiguration:GetWindowName('comboGroupe'):Append('Club');
	dlgConfiguration:GetWindowName('comboGroupe'):Append('Categ');
	dlgConfiguration:GetWindowName('comboGroupe'):Append('An');
	dlgConfiguration:GetWindowName('comboGroupe'):Append('Sexe');
	dlgConfiguration:GetWindowName('comboGroupe'):Append('Groupe');
	dlgConfiguration:GetWindowName('comboGroupe'):Append('Equipe');
	dlgConfiguration:GetWindowName('comboGroupe'):Append('Critere');
	dlgConfiguration:GetWindowName('comboGroupe'):Append('Distance');
	dlgConfiguration:GetWindowName('comboTpsPts'):Clear();
	dlgConfiguration:GetWindowName('comboTpsPts'):Append('les temps');
	dlgConfiguration:GetWindowName('comboTpsPts'):Append('les points course');
	for i = 1, 6 do
		dlgConfiguration:GetWindowName('prendre'..i):Clear();
		dlgConfiguration:GetWindowName('comboPrendre'..i):Clear();
		if #tAnneeM > 0 and #tAnneeF > 0 then
			dlgConfiguration:GetWindowName('comboPrendre'..i):Append('homme(s) ou dame(s)');
		end
		if #tAnneeF > 0 then
			dlgConfiguration:GetWindowName('comboPrendre'..i):Append('dame(s)');
		end
		if #tAnneeM > 0 then
			dlgConfiguration:GetWindowName('comboPrendre'..i):Append('homme(s)');
		end
		for j = 1, 10 do
			dlgConfiguration:GetWindowName('prendre'..i):Append(j);
		end
		dlgConfiguration:GetWindowName('comboPrendre'..i):Append('');
	end
	dlgConfiguration:GetWindowName('comboGroupe'):SetValue('Club');
	dlgConfiguration:GetWindowName('comboTpsPts'):SetSelection(0);
	OnChangecomboTpsPts();
	dlgConfiguration:Fit();
	dlgConfiguration:ShowModal();
end

function OnChangecomboQuoi()		
	comboQuoi = dlgConfiguration:GetWindowName('comboQuoi'):GetValue();
	indexQuoi = dlgConfiguration:GetWindowName('comboQuoi'):GetSelection();
end

function OnChangeMulti()
	bolMulti = dlgConfiguration:GetWindowName('chkMulti'):GetValue();
	if bolMulti == true then
		dlgConfiguration:GetWindowName('chkNonClasses'):SetValue(true);
		dlgConfiguration:GetWindowName('chkNonClasses'):Enable(false);
	else
		dlgConfiguration:GetWindowName('chkNonClasses'):Enable(true);
	end
end

function OnChangePrendre(id)
	if dlgConfiguration:GetWindowName('prendre'..id):GetValue():len() == 0 or tonumber(dlgConfiguration:GetWindowName('prendre'..id):GetValue()) == nil then
		dlgConfiguration:GetWindowName('comboPrendre'..id):SetValue('');
		dlgConfiguration:GetWindowName('comboCateg'..id):SetValue('');
		dlgConfiguration:GetWindowName('anneeDebut'..id):SetValue('');
		dlgConfiguration:GetWindowName('anneeFin'..id):SetValue('');
	else
		OnChangecomboPrendre(id);
	end
	
end

function OnChangecomboPrendre(id)
	comboPrendre[id] = dlgConfiguration:GetWindowName('comboPrendre'..id):GetValue();
	if comboPrendre[id]:len() == 0 then
		comboPrendre[id] = dlgConfiguration:GetWindowName('comboPrendre'..id):SetSelection(0);
		comboPrendre[id] = dlgConfiguration:GetWindowName('comboPrendre'..id):GetValue();
	end
	dlgConfiguration:GetWindowName('anneeDebut'..id):Clear();
	dlgConfiguration:GetWindowName('anneeFin'..id):Clear();
	dlgConfiguration:GetWindowName('comboCateg'..id):Clear();
	if string.find(comboPrendre[id], 'ou') then
		tCategX = tCategT;
		tAnneeX = tAnneeT;
	elseif string.find(comboPrendre[id], 'homme') then
		tCategX = tCategM;
		tAnneeX = tAnneeM;
	elseif string.find(comboPrendre[id], 'dame') then
		tCategX = tCategF;
		tAnneeX = tAnneeF;
	end
	for i = 1, #tAnneeX do
		dlgConfiguration:GetWindowName('anneeDebut'..id):Append(tAnneeX[i]);
		dlgConfiguration:GetWindowName('anneeFin'..id):Append(tAnneeX[i]);
	end
	for i = 1, #tCategX do
		dlgConfiguration:GetWindowName('comboCateg'..id):Append(tCategX[i]);
	end
	dlgConfiguration:GetWindowName('anneeDebut'..id):Append('');
	dlgConfiguration:GetWindowName('anneeFin'..id):Append('');
	dlgConfiguration:GetWindowName('comboCateg'..id):Append('');
	dlgConfiguration:GetWindowName('comboCateg'..id):SetSelection(0);
end

function OnChangecomboCateg(id)
	comboCateg[id] = dlgConfiguration:GetWindowName('comboCateg'..id):GetValue();
	if comboCateg[id]:len() > 0 then
		dlgConfiguration:GetWindowName('anneeDebut'..id):SetValue('');
		dlgConfiguration:GetWindowName('anneeFin'..id):SetValue('');
	end
		
end

function OnChangecomboAnneeDebut(id)
	local anneedebut = dlgConfiguration:GetWindowName('anneeDebut'..id):GetValue();
	if anneedebut:len() > 0 then
		dlgConfiguration:GetWindowName('comboCateg'..id):SetValue('');
	end
		
end

function OnChangecomboGroupe()
	comboGroupe = dlgConfiguration:GetWindowName('comboGroupe'):GetValue();
end

function OnChangecomboTpsPts()
	comboTpsPts = dlgConfiguration:GetWindowName('comboTpsPts'):GetValue();
	dlgConfiguration:GetWindowName('comboQuoi'):Clear();
	if string.find(comboTpsPts, 'temps') then	-- addition des temps
		bolTemps = true;
		dlgConfiguration:GetWindowName('comboQuoi'):Append("le temps total");
		if nombre_de_manche > 1 then
			dlgConfiguration:GetWindowName('comboQuoi'):Append("le temps de la meilleure manche");
			if nombre_de_manche > 2 then
				for i = 2, nombre_de_manche -1 do
					dlgConfiguration:GetWindowName('comboQuoi'):Append('le temps des '..i..' meilleures manches');
				end
			end
		end
	else
		bolTemps = false;
		dlgConfiguration:GetWindowName('comboQuoi'):Append("les points du classement général");
		if nombre_de_manche > 1 then
			dlgConfiguration:GetWindowName('comboQuoi'):Append("les points de la meilleure manche");
			if nombre_de_manche > 2 then
				for i = 2, nombre_de_manche -1 do
					dlgConfiguration:GetWindowName('comboQuoi'):Append('les points des '..i..' meilleures manches');
				end
			end
		end
	end 
	dlgConfiguration:GetWindowName('comboQuoi'):SetSelection(0);
end

-- Point Entree Principal
function main(cparams)
	version_script = '1.0';
	bolTemps = true;
	bolCoureurEquipe = false;
	if cparams then
		code_evenement = cparams.code_evenement;
	else
		return false;
	end

	dlgPosit = {};
	dlgPosit.width = display:GetSize().width * 3 / 4;
	dlgPosit.height = display:GetSize().height * 3 / 4;
	dlgPosit.x = (display:GetSize().width - dlgPosit.width) / 2;
	dlgPosit.y = 50;
	-- dlgPosit.y = (display:GetSize().height - dlgPosit.height) / 2;
	base = sqlBase.Clone();
	XML = app.GetPath().."/edition/editionRegroupement.xml";
	doc = xmlDocument.Create(XML);
	
	Evenement = base:GetTable('Evenement');
	Resultat = base:GetTable('Resultat');
	Coureur = base:GetTable('Coureur');
	Epreuve = base:GetTable('Epreuve');
	Discipline = base:GetTable('Discipline');
	
	tRanking = base.CreateTableRanking({ code_evenement = code_evenement});
	tRanking:AddColumn({ name = 'Best_run', label = 'Best_run', type = sqlType.LONG, style = sqlStyle.NULL });
	tRanking:AddColumn({ name = 'Clt_total', label = 'Tps_total', type = sqlType.LONG, style = sqlStyle.NULL });
	tRanking:AddColumn({ name = 'Tps_total', label = 'Tps_total', type = sqlType.CHRONO, style = sqlStyle.NULL });
	tRanking:AddColumn({ name = 'Pts_total', label = 'Pts_total', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tAnneeM = {};
	tAnneeF = {};
	tAnneeT = {};
	tAnneeX = {};
	tCategM = {};
	tCategF = {};
	tCategT = {};
	tCategX = {};
	prendre = {};
	comboPrendre = {};
	comboCateg = {};
	comboGroupe = '';
	comboTpsPts = '';
	comboQuoi = '';
	indexQuoi = 0;
	local cmd = 'Select An, Categ, Sexe From Resultat Where Code_evenement = '..code_evenement..' Group By An, Categ, Sexe';
	Resultat = base:TableLoad(cmd);
	Resultat:OrderBy('An DESC');
	local bolAlerteSexe = false;
	local bolAlerteCateg = false;
	local bolAlerteAn = false;
	
	for row = 0, Resultat:GetNbRows() -1 do
		local categ = Resultat:GetCell('Categ', row);
		local sexe = Resultat:GetCell('Sexe', row);
		local an = Resultat:GetCellInt('An', row);
		if categ:len() == 0 then
			bolAlerteCateg = true;
		end
		if sexe:len() == 0 then
			bolAlerteSexe = true;
		end
		if an == 0 then
			bolAlerteAn = true;
		end
		if #tAnneeT == 0 or tAnneeT[#tAnneeT] ~= an then
			table.insert(tAnneeT, an);
		end
		if #tCategT == 0 or tCategT[#tCategT] ~= categ then
			table.insert(tCategT, categ);
		end
		if sexe == 'F' then
			if #tAnneeF == 0 or tAnneeF[#tAnneeF] ~= an then
				table.insert(tAnneeF, an);
			end
			if #tCategF == 0 or tCategF[#tCategF] ~= categ then
				table.insert(tCategF, categ);
			end
		elseif sexe == 'M' then
			if #tAnneeM == 0 or tAnneeM[#tAnneeM] ~= an then
				table.insert(tAnneeM, an);
			end
			if #tCategM == 0 or tCategM[#tCategM] ~= categ then
				table.insert(tCategM, categ);
			end
		end
	end
	local strErreur = '';
	if bolAlerteSexe == true or bolAlerteCateg == true or bolAlerteAn == true then
		if bolAlerteCateg == true then
			strErreur = strErreur..'\nLa catégorie';
		end
		if bolAlerteSexe == true then
			strErreur = strErreur..'\nLe sexe';
		end
		if bolAlerteAn == true then
			strErreur = strErreur.."\nL'année de naissance";
		end
		app.GetAuiFrame():MessageBox(
			"ATTENTION, Certaines données sont manquantes !!!!!!!!!!!"..strErreur,
			"Erreurs",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
		return;
	end
	table.sort(tAnneeF);
	table.sort(tAnneeM);
	table.sort(tAnneeT);
	Evenement = base:TableLoad('Select * From Evenement Where Code = '..code_evenement);
	Epreuve = base:TableLoad('Select * From Epreuve Where Code_evenement = '..code_evenement);
	cmd = "Select * From Discipline Where Code_activite = '"..Evenement:GetCell('Code_activite', 0).."' And Code_saison = '"..Evenement:GetCell('Code_saison', 0).."' And Code = '"..Epreuve:GetCell('Code_discipline', 0).."'"
	Discipline = base:TableLoad(cmd);
	facteur_f = Discipline:GetCellInt('Facteur_f', 0);
	nombre_de_manche = Epreuve:GetCellInt('Nombre_de_manche', 0);
	for i = 1, nombre_de_manche do
		tRanking:OrderBy('Tps'..i);
		local best_timex = 0;
		local ptsx = 10000;
		local tpsx = 0;
		for row = 0, tRanking:GetNbRows() -1 do
			if i == 1 then	-- initialisation des valeurs pour le coureur
				local code_comite = tRanking:GetCell('Comite', row);
				tRanking:SetCell('Status', row, 'N');
				tRanking:SetCell('Tps_total', row, -1);
				tRanking:SetCell('Pts_total', row, -1);
				if code_comite == 'EQ' then
					bolCoureurEquipe = true;
				end
			end
		end
	end
	ReplaceTableEnvironnement(tRanking,'tRanking');
	tRanking_Sav = tRanking:Copy();
	ReplaceTableEnvironnement(tRanking_Sav,'tRanking_Sav');
	AffichedlgConfiguration()
	if doc then
		doc:Delete();
	end
end
