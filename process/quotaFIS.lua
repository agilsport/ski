-- LIVE Draw par Philippe Guérindon

dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function OnClose()
	params.exit = true;
end

function SortTable(sens, array, keys)	-- tri de la table tTableComite
	if #keys == 1 then
		table.sort(array, function (u,v)
			if sens == '>' then
				return
					 u[keys[1]] > v[keys[1]];
			else
				return 
					 u[keys[1]] < v[keys[1]];
			end
		end)
	elseif #keys == 2 then
		table.sort(array, function (u,v)
			if sens == '>' then
				return
					 u[keys[1]] < v[keys[1]] or
					(u[keys[1]] == v[keys[1]] and u[keys[2]] > v[keys[2]]);
			else
				return
					 u[keys[1]] < v[keys[1]] or
					(u[keys[1]] == v[keys[1]] and u[keys[2]] < v[keys[2]]);
			end
		end)
	end
end


function SplitFilter(chaine)
	if chaine:len() == 0 then
		return '';
	end
	local filter_display = '';
	chaine = string.gsub(chaine,'$%(', '');
	chaine = string.gsub(chaine,'%)', '');
	chaine = string.gsub(chaine,'%(', '');
	chaine = string.gsub(chaine,':In', '|');
	local separator = '';
	local tCritere = chaine:Split(' and ');
	for i = 1, #tCritere do
		if i > 1 then
			separator = ' et ';
		end
		local tFiltre = tCritere[i]:Split('|');
		local filter = separator..tFiltre[1];
		local value = tFiltre[2];
		value = string.gsub(value,',',' ou ');
		filter_display = filter_display..filter..' = '..value;
	end
	return filter_display;
end

function OnSaveBackOffice()
	params.code_regroupement = dlgBackOffice:GetWindowName('combo_regroupement'):GetValue();
	params.place_comite_organisateur = tonumber(dlgBackOffice:GetWindowName('place_comite_organisateur_new'):GetValue()) or 0;
	params.place_club_organisateur = tonumber(dlgBackOffice:GetWindowName('place_club_organisateur_new'):GetValue()) or 0;
	params.wild_card = tonumber(dlgBackOffice:GetWindowName('wild_card_new'):GetValue()) or 0;
	params.comite_origine = dlgBackOffice:GetWindowName('comboComiteOrigine'):GetSelection();
	params.place_variable = dlgBackOffice:GetWindowName('comboVariable'):GetSelection();
	local total = 0;
	for i = 1, #tTableComite do
		local new_value = dlgBackOffice:GetWindowName('new_quota_base'..i):GetValue():sub(1,-1);
		new_value = tonumber(new_value) or 0;
		total = total + new_value;
	end
	if params.place_variable == 1 then
		total = total + params.place_comite_organisateur + params.place_club_organisateur + params.wild_card;
	end
	dlgBackOffice:GetWindowName('total_base2'):SetValue(total..'%');
	
	local bolOK = Eval(10000, Round(total * 100, 0));

	if bolOK == true then
		params.somme_quota_base = 100;
		for i = 1,#tTableComite do
			local comite = dlgBackOffice:GetWindowName('comite'..i):GetValue()
			if comite == 'GIRSA' then
				comite = 'GI';
			elseif comite == 'PE/PO' then
				comite = 'PY';
			end
			local new_value = string.gsub(dlgBackOffice:GetWindowName('new_quota_base'..i):GetValue(), ',', '.');
			node_quota:ChangeAttribute(comite, new_value);
			node_quota:ChangeAttribute(comite, new_value)
			tTableComite[i].Quota_base = new_value;
			tquotaComite[comite] = new_value;
			tTableComite[i].Quota_base2 = 0;
			tTableComite[i].Place_gagnee = 0;
			tTableComite[i].Place_Rendue = 0;
			tTableComite[i].Place_theorique2 = 0;
			tTableComite[i].Maxi_theorique = 0;
			tTableComite[i].Maxi_theorique2 = 0;
			tTableComite[i].Quota_calcule = 0;
			tTableComite[i].Status = 1;
			node_quota:ChangeAttribute(comite, new_value);
			tTableComite[i].Participation = tRanking:GetCounterValue('Comite', comite);

		end
		-- adv.Alert('passage sav 1');
		-- node_quota:ChangeAttribute(comite, new_value);
		-- node_quota:ChangeAttribute(comite, new_value)
		node_quota:ChangeAttribute('COMITE', params.place_comite_organisateur);
		node_quota:ChangeAttribute('CLUB', params.place_club_organisateur);
		node_quota:ChangeAttribute('WILDCARD', params.wild_card);
		node_quota:ChangeAttribute('VARIABLE', params.place_variable);
		node_quota:ChangeAttribute('ORIGINE', params.comite_origine);
		doc_config:SaveFile();
		app.GetAuiFrame():MessageBox(
			"Les nouveaux quotas ont été sauvegardés", 
			"Sauvegarde des quotas",
			msgBoxStyle.OK
			);
	else
		app.GetAuiFrame():MessageBox(
			"L'addition des quotas de base doit être égale à 100 !!\nLe total ce ces valeur est actuellement de "..total, 
			"Information !!!",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
			);
	end
end

function TotaliseNewValue()
	local total = 0;
	local valeur = 0;
	for i = 1, #tTableComite do
		valeur = tonumber(dlgBackOffice:GetWindowName('new_quota_base'..i):GetValue()) or 0;
		total = total + valeur;
	end
	if params.place_variable > 0 then
		valeur = string.gsub(dlgBackOffice:GetWindowName('place_comite_organisateur_new'):GetValue(), ' %%', '');
		valeur = tonumber(valeur) or 0;
		total = total + valeur;
		valeur = string.gsub(dlgBackOffice:GetWindowName('place_club_organisateur_new'):GetValue(), ' %%', '');
		valeur = tonumber(valeur) or 0;
		total = total + valeur;
		valeur = string.gsub(dlgBackOffice:GetWindowName('wild_card_new'):GetValue(), ' %%', '');
		valeur = tonumber(valeur) or 0;
		total = total + valeur;
	end
	return total;
end

function CalculeQuotaMaxiCalculette(a_repartir)
	local difference = 0;

	params.somme_quota_calcules = 0;
	for index = 1, #tTableComite do
		tTableComite[index].Status = -1;
	end
	local difference = 0;

	params.somme_quota_calcules = 0;
	local somme_base = 0;
	local somme_maxi_theorique = 0;
	-- DisplayDataCalculette();
	local somme_pour_redistribution = 0;
	params.somme_quota_base2 = 0;
	for index = 1, #tTableComite do
		if dlgGetQuotaComites:GetWindowName('chk'..index):GetValue() == true then
			somme_base = somme_base + tTableComite[index].Quota_base
		end
	end
	for index = 1, #tTableComite do
		local comite = tTableComite[index].Comite;
		if dlgGetQuotaComites:GetWindowName('chk'..index):GetValue() == true then
			local coef = tTableComite[index].Quota_base * 100 / somme_base;
			tTableComite[index].Quota_maxi = a_repartir * coef / 100;
			dlgGetQuotaComites:GetWindowName('quota_maximum'..index):SetValue(Round(tTableComite[index].Quota_maxi, 2))
			somme_maxi_theorique = somme_maxi_theorique + tTableComite[index].Quota_maxi;
		end
	end
	difference = somme_maxi_theorique - a_repartir;
	return difference;
end

function RazDisplayBackOffice()
	for i = 0, 20 do
		if dlgBackOffice:GetWindowName('comite'..i) then
			dlgBackOffice:GetWindowName('comite'..i):SetValue(false);
			dlgBackOffice:GetWindowName('old_quota_base'..i):SetValue('');
			dlgBackOffice:GetWindowName('old_quota_base'..i):SetValue('');
			dlgBackOffice:GetWindowName('new_quota_base'..i):SetValue('');
		end
	end
end

function DisplayDataBackOffice(node)
	local total_base = 0;
	local total_base_new = 0;
	local base_old = 0;
	local base_new = 0;
	local pourcent = ' %';
	params.place_variable = tonumber(node:GetAttribute("VARIABLE")) or 0;

	if params.place_variable == 0 then
		pourcent = '';
	end
	for i = 1, #tTableComite do
		local display_ligne = true;
		local comite = tTableComite[i].Comite;
		local comite_display = comite;
		if comite == 'GI' then
			comite_display = 'GIRSA';
		elseif comite == 'PY' then
			comite_display = 'PE/PO';
		end
		if tQuotaNode then
			if tQuotaNode['PY'] then
				if comite == 'PO' then
					display_ligne = false;
				elseif comite == 'PE' then
					comite_display = 'PE/PO';
					comite = 'PY';
				end
			end
		end
		if comite == 'CIT' and params.code_regroupement ~= 'NJR' then
			display_ligne = false;
		end
		if display_ligne == true then
			dlgBackOffice:GetWindowName('comite'..i):SetValue(comite_display);
			dlgBackOffice:GetWindowName('old_quota_base'..i):SetValue(tTableComite[i].Quota_base..' %');
			dlgBackOffice:GetWindowName('new_quota_base'..i):SetValue(tTableComite[i].Quota_base);
			base_old = tTableComite[i].Quota_base;
			base_new = base_old;
			total_base = total_base + base_old;
			total_base_new = total_base_new + base_new;
		else
			dlgBackOffice:GetWindowName('comite'..i):SetValue('');
			dlgBackOffice:GetWindowName('old_quota_base'..i):SetValue('');
			dlgBackOffice:GetWindowName('new_quota_base'..i):SetValue('');
		end
	end
	local node_comite_organisateur = tonumber(node:GetAttribute("COMITE")) or 0;
	local node_club_organisateur = tonumber(node:GetAttribute("CLUB")) or 0;
	local node_wildcard = tonumber(node:GetAttribute("WILDCARD")) or 0;
	if params.place_variable > 0 then
		total_base  = total_base  + node_comite_organisateur +  node_club_organisateur + node_wildcard;
		total_base_new = total_base_new  + node_comite_organisateur +  node_club_organisateur + node_wildcard;
	else

	end
	dlgBackOffice:GetWindowName('place_comite_organisateur'):SetValue(tonumber(node:GetAttribute("COMITE"))..pourcent);
	dlgBackOffice:GetWindowName('place_club_organisateur'):SetValue(tonumber(node:GetAttribute("CLUB"))..pourcent);
	dlgBackOffice:GetWindowName('wild_card'):SetValue(tonumber(node:GetAttribute("WILDCARD"))..pourcent);
	
	dlgBackOffice:GetWindowName('place_comite_organisateur_new'):SetValue(tonumber(node:GetAttribute("COMITE")));
	dlgBackOffice:GetWindowName('place_club_organisateur_new'):SetValue(tonumber(node:GetAttribute("CLUB")));
	dlgBackOffice:GetWindowName('wild_card_new'):SetValue(tonumber(node:GetAttribute("WILDCARD")));

	dlgBackOffice:GetWindowName('total_base'):SetValue(total_base..' %');
	dlgBackOffice:GetWindowName('total_base2'):SetValue(total_base_new);
	dlgBackOffice:GetWindowName('comboComiteOrigine'):Clear();
	dlgBackOffice:GetWindowName('comboComiteOrigine'):Append('Non');
	dlgBackOffice:GetWindowName('comboComiteOrigine'):Append('Oui');
	
	dlgBackOffice:GetWindowName('comboVariable'):Clear();
	dlgBackOffice:GetWindowName('comboVariable'):Append('Non');
	dlgBackOffice:GetWindowName('comboVariable'):Append('Oui');
	
	dlgBackOffice:GetWindowName('comboComiteOrigine'):SetSelection(params.equipe_Comite_origine);
	dlgBackOffice:GetWindowName('comboVariable'):SetSelection(params.place_variable);
end

function CreateTranking()
	tRanking = base.CreateTableRanking({ code_evenement = -1});
	for i = 1, 9 do
		tRanking:AddColumn({ name = 'Epreuve_selection'..tostring(i), label = 'Epreuve_selection'..tostring(i), type = sqlType.CHAR, size = 1 });
	end


end

function OnAfficheBackOffice()
-- Création Dialog 
	if not tRanking then
		CreateTranking()
	end
	backoffice_node = doc_config:FindFirst('root/hommes/'..params.code_regroupement);
	params.label_dialog = 'Back office du script';
	dlgBackOffice = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		label=params.label_dialog, 
		icon='./res/32x32_fis.png'
		});
	
	dlgBackOffice:LoadTemplateXML({ 
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 	
		node_value = 'backoffice',
		regroupement = params.code_regroupement,
		tableau = tTableComite,
		lignes = 14,
		place_comite = tonumber(backoffice_node:GetAttribute("COMITE")) or 0,
		place_club = tonumber(backoffice_node:GetAttribute("CLUB")) or 0,
		proportionnelle = tonumber(backoffice_node:GetAttribute("VARIABLE")) or 0,
		wild_card = tonumber(backoffice_node:GetAttribute("WILDCARD")) or 0
	});
	
	dlgBackOffice:GetWindowName('combo_regroupement'):Clear();
	dlgBackOffice:GetWindowName('combo_regroupement'):Append('FIS');
	dlgBackOffice:GetWindowName('combo_regroupement'):Append('NJR');
	dlgBackOffice:GetWindowName('combo_regroupement'):Append('CIT');
	dlgBackOffice:GetWindowName('combo_regroupement'):Append('UNI');
	dlgBackOffice:GetWindowName('combo_regroupement'):SetValue(params.code_regroupement);
	
	local tb = dlgBackOffice:GetWindowName('tbbackoffice');
	tb:AddStretchableSpace();
	local btnSave = tb:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tb:AddSeparator();
	local btnClose = tb:AddTool("Quitter", "./res/32x32_exit.png");

	tb:AddStretchableSpace();
	tb:Realize();
	
	RazDisplayBackOffice();
	DisplayDataBackOffice(backoffice_node);

	dlgBackOffice:Bind(eventType.COMBOBOX, 
		function(evt)
			RazDisplayBackOffice();
			params.code_regroupement = dlgBackOffice:GetWindowName('combo_regroupement'):GetValue();
			backoffice_node = doc_config:FindFirst('root/hommes/'..params.code_regroupement);
			GetQuotaComites(backoffice_node);
			DisplayDataBackOffice(backoffice_node);
		 end,
		 dlgBackOffice:GetWindowName('combo_regroupement'));
		 	
	for i = 1, #tTableComite do
		dlgBackOffice:Bind(eventType.TEXT, 
			function(evt)
				local total = TotaliseNewValue();
				dlgBackOffice:GetWindowName('total_base2'):SetValue(total..'%');
			 end,  dlgBackOffice:GetWindowName('new_quota_base'..i));
	end

	dlgBackOffice:Bind(eventType.MENU, 
		function(evt)
			node_quota = doc_config:FindFirst('root/hommes/'..params.code_regroupement);
			OnSaveBackOffice();
		end,  btnSave);
	dlgBackOffice:Bind(eventType.MENU, 
		function(evt)
			local msg = "Oui = Appliquer ces quotas pour le calcul en cours.\nNon = Conserve les quotas d'origine.";
			local key = app.GetAuiFrame():MessageBox(msg, "Choix des quotas à appliquer", msgBoxStyle.YES + msgBoxStyle.NO + msgBoxStyle.YES_DEFAULT + msgBoxStyle.ICON_WARNING);
			if key == msgBoxStyle.NO then
				params.code_regroupement = string.sub(tEpreuve:GetCell('Code_regroupement', 0), 1, 3);
			end
			node_quota = doc_config:FindFirst('root/hommes/'..params.code_regroupement);
			for i = 0, tRanking:GetNbRows() -1 do
				local code_coureur = tRanking:GetCell('Code_coureur', i);
				local comite = tRanking:GetCell('Comite', i);
				if params.equipe_Comite_origine > 0 then
					if comite == 'EQ' or comite == 'CNE' then
						tRanking:SetCell('Comite', i, GetComiteOrigine(code_coureur));
					end
				else
					local row = tResultat:GetIndexRow('Code_coureur', code_coureur);
					comite = tResultat:GetCell('Comite', row);
					if comite == 'CNE' then
						comite = 'EQ';
					end
					tRanking:SetCell('Comite', i, comite);
				end
				if node_quota:HasAttribute('PY') then
					if comite:In('PE','PO') then
						tRanking:SetCell('Comite', i, 'PY');
					end
				end
				if node_quota:HasAttribute('GI') then
					if comite:In('BO','FZ','CE','LY','OU') and node_quota:HasAttribute('GI') then
						tRanking:SetCell('Comite', i, 'GI');
					end
				end
			end
			tRanking:SetCounter('Comite');
			dlgBackOffice:EndModal(idButton.CANCEL);
		 end,  btnClose);
		 
	dlgBackOffice:Fit();
	dlgBackOffice:ShowModal();
	
	GetQuotaComites(node_quota);
	for index = 1, #tTableComite do
		local comite = tTableComite[index].Comite;
		tTableComite[index].Quota_base = tquotaComite[comite];
		tTableComite[index].Participation = tRanking:GetCounterValue('Comite', comite);
	end
	if params.equipe_Comite_origine > 1 then
		params.nb_equipe = 0;
	else
		params.nb_equipe = tRanking:GetCounterValue('Comite', 'EQ');
	end

	dlgBackOffice = nil;
end

function DisplayQuotaBase()
	params.total_base = 0;
	for i = 1, 14 do
		if dlgGetQuotaComites:GetWindowName('chk'..i) then
			dlgGetQuotaComites:GetWindowName('chk'..i):SetLabel('');
			dlgGetQuotaComites:GetWindowName('quota_base'..i):SetValue('');
			dlgGetQuotaComites:GetWindowName('quota_maximum'..i):SetValue('');
			dlgGetQuotaComites:GetWindowName('places_demandees'..i):SetValue('');
			dlgGetQuotaComites:GetWindowName('places_obtenues'..i):SetValue('');
			dlgGetQuotaComites:GetWindowName('chk'..i):Enable(false);
			dlgGetQuotaComites:GetWindowName('places_demandees'..i):Enable(false);
			dlgGetQuotaComites:GetWindowName('places_obtenues'..i):Enable(false);
		end
	end
	for i = 1, 20 do
		local display_ligne = true;
		if i <= #tTableComite then
			local comite = tTableComite[i].Comite;
			-- tDisplayComite[comite] = tDisplayComite[comite] or {};
			-- tTableComite[i].Quota_base = tonumber(tquotaComite[comite]) or 0;
			-- tDisplayComite[comite].Quota_base = tTableComite[i].Quota_base;
			
			if comite == 'GI' then
				comite = 'GIRSA';
			elseif comite == 'PY' then
				comite = 'PE/PO';
			elseif comite == 'IF' then
				comite = 'IFNO';
			end
			if comite == 'CIT' and params.code_regroupement ~= 'NJR' then
				display_ligne = false;
			end
			if not tTableComite[i].Comite then
				display_ligne = false;
			end
			if display_ligne == true then
				dlgGetQuotaComites:GetWindowName('chk'..i):SetLabel(comite);
				dlgGetQuotaComites:GetWindowName('quota_base'..i):SetValue(tTableComite[i].Quota_base..' %');
				dlgGetQuotaComites:GetWindowName('chk'..i):Enable(true);
				dlgGetQuotaComites:GetWindowName('places_demandees'..i):Enable(true);
				dlgGetQuotaComites:GetWindowName('places_obtenues'..i):Enable(true);
				params.total_base  = params.total_base  + tTableComite[i].Quota_base;
			end
		end
	end	

	dlgGetQuotaComites:GetWindowName('combo_regroupement'):SetValue(params.code_regroupement);
	dlgGetQuotaComites:GetWindowName('total_base'):SetValue(params.total_base ..' %');
end

function AfficheNodeData()
	-- adv.Alert('AfficheNodeData');
	params.total_base = 0;
	for i = 1, 20 do
		if dlgGetQuotaComites:GetWindowName('chk'..i) then
			dlgGetQuotaComites:GetWindowName('chk'..i):SetLabel('');
			dlgGetQuotaComites:GetWindowName('quota_base'..i):SetValue('');
			dlgGetQuotaComites:GetWindowName('quota_maximum'..i):SetValue('');
			dlgGetQuotaComites:GetWindowName('places_demandees'..i):SetValue('');
			dlgGetQuotaComites:GetWindowName('places_obtenues'..i):SetValue('');
			dlgGetQuotaComites:GetWindowName('chk'..i):Enable(false);
			dlgGetQuotaComites:GetWindowName('places_demandees'..i):Enable(false);
			dlgGetQuotaComites:GetWindowName('places_obtenues'..i):Enable(false);
		end
	end
	for i = 1, 20 do
		local display_ligne = true;
		if i <= #tTableComite then
			local comite = tTableComite[i].Comite;
			tDisplayComite[comite] = tDisplayComite[comite] or {};
			tTableComite[i].Quota_base = tonumber(tquotaComite[comite]) or 0;
			tDisplayComite[comite].Quota_base = tTableComite[i].Quota_base;
			
			if comite == 'GI' then
				comite = 'GIRSA';
			elseif comite == 'PY' then
				comite = 'PE/PO';
			elseif comite == 'IF' then
				comite = 'IFNO';
			end
			if comite == 'CIT' and params.code_regroupement ~= 'NJR' then
				display_ligne = false;
			end
			if display_ligne == true then
				dlgGetQuotaComites:GetWindowName('chk'..i):SetLabel(comite);
				dlgGetQuotaComites:GetWindowName('quota_base'..i):SetValue(tTableComite[i].Quota_base..' %');
				dlgGetQuotaComites:GetWindowName('chk'..i):Enable(true);
				dlgGetQuotaComites:GetWindowName('places_demandees'..i):Enable(true);
				dlgGetQuotaComites:GetWindowName('places_obtenues'..i):Enable(true);
				params.total_base  = params.total_base  + tTableComite[i].Quota_base;
			end
		end
	end	
	tDisplayComite['CR'] = params.place_comite_organisateur;
	tDisplayComite['CL'] = params.place_club_organisateur;
	tDisplayComite['WC'] = params.wild_card;
	-- adv.Alert('params.place_variable = '..params.place_variable..', type(params.place_variable) = '..type(params.place_variable));
	-- adv.Alert("tDisplayComite['CR'] = "..tostring(tDisplayComite['CR']));
	-- dlgGetQuotaComites:GetWindowName('CR'):SetLabel('Places C.R.')
	-- dlgGetQuotaComites:GetWindowName('CLUB'):SetLabel('Places Club')
	-- dlgGetQuotaComites:GetWindowName('WC'):SetLabel('Wild Card')
	local place_cr2 = nil;
	local place_club2 = nil;
	local place_wc2 = params.wild_card_node;
	local places_ffs = nil;
	local pourcent = ' %';
	if params.place_variable == 1 then
		place_cr2 = Round(params.place_comite_organisateur_node * params.a_repartir / 100, 0);
		place_club2 = Round(params.place_club_organisateur_node *  params.a_repartir / 100,0);
		-- params.total_base  = params.total_base  + params.place_comite_organisateur_node + params.place_club_organisateur_node;
	else
		pourcent = '';
		place_cr2 = params.place_comite_organisateur_node;
		place_club2 = params.place_club_organisateur_node;
	end
	places_ffs =place_cr2 + place_club2 + place_wc2;
	dlgGetQuotaComites:GetWindowName('place_CR'):SetValue(params.place_comite_organisateur_node..pourcent);
	dlgGetQuotaComites:GetWindowName('place_CR2'):SetValue(place_cr2);
	dlgGetQuotaComites:GetWindowName('place_CLUB'):SetValue(params.place_club_organisateur_node..pourcent);
	dlgGetQuotaComites:GetWindowName('place_CLUB2'):SetValue(place_club2);
	dlgGetQuotaComites:GetWindowName('wild_card'):SetValue('');
	dlgGetQuotaComites:GetWindowName('wild_card2'):SetValue(place_wc2);
	dlgGetQuotaComites:GetWindowName('places_ffs'):SetValue(places_ffs);

	dlgGetQuotaComites:GetWindowName('combo_regroupement'):SetValue(params.code_regroupement);
	dlgGetQuotaComites:GetWindowName('total_base'):SetValue(params.total_base ..' %');
end

function OnDisplayTotalDemande()
	params.somme_places_demandees = 0;
	for index = 1, #tTableComite do
		if dlgGetQuotaComites:GetWindowName('chk'..index) then
			local place_demandee = tonumber(dlgGetQuotaComites:GetWindowName('places_demandees'..index):GetValue()) or 0
			params.somme_places_demandees = params.somme_places_demandees + place_demandee;
		end
	end
	dlgGetQuotaComites:GetWindowName('total_places_demandees'):SetValue(params.somme_places_demandees);
end

function OnDisplayTotalObtenu()
	local somme_places_obtenues = 0;
	local a_repartir = tonumber(dlgGetQuotaComites:GetWindowName('a_repartir'):GetValue()) or 0;
	local place_comite = tonumber(dlgGetQuotaComites:GetWindowName('place_CR2'):GetValue()) or 0;
	local place_club = tonumber(dlgGetQuotaComites:GetWindowName('place_CLUB2'):GetValue()) or 0;
	local wild_card = tonumber(dlgGetQuotaComites:GetWindowName('wild_card2'):GetValue()) or 0;
	local places_france = tonumber(dlgGetQuotaComites:GetWindowName('places_france'):GetValue()) or 0;
	local difference = 0;
	for index = 1, #tTableComite do
		if dlgGetQuotaComites:GetWindowName('chk'..index) then
			local place_obtenue = tonumber(dlgGetQuotaComites:GetWindowName('places_obtenues'..index):GetValue()) or 0;
			somme_places_obtenues = somme_places_obtenues + place_obtenue;
		end
	end
	dlgGetQuotaComites:GetWindowName('total_places_obtenues'):SetValue(somme_places_obtenues);
	local total_reparti = somme_places_obtenues + place_club + place_comite + wild_card + places_france;
	local difference = total_reparti - a_repartir;
	dlgGetQuotaComites:GetWindowName('difference'):SetValue(difference);
end

function RAZdata()
	-- RazDisplayGetParticipationComites();
	for index = 1, #tTableComite do
		local comite = tTableComite[index].Comite;
		tTableComite[index].Quota_calcule = 0;
		tTableComite[index].Quota_base2 = 0;
		tTableComite[index].Place_gagnee = 0;
		tTableComite[index].Representation = 0;
		tTableComite[index].Place_theorique2 = 0;
		tTableComite[index].Maxi_theorique2 = 0;
		tTableComite[index].Place_Rendue = 0;
		tTableComite[index].Pourcent = 0;
		tTableComite[index].Status = 1;
		-- dlgGetQuotaComites:GetWindowName('quota_base'..index):SetValue('');
		dlgGetQuotaComites:GetWindowName('quota_maximum'..index):SetValue('');
		dlgGetQuotaComites:GetWindowName('places_demandees'..index):SetValue('');
		dlgGetQuotaComites:GetWindowName('places_obtenues'..index):SetValue('');
		dlgGetQuotaComites:GetWindowName('chk'..index):SetLabel('');
		dlgGetQuotaComites:GetWindowName('chk'..index):SetValue(false);
	end
	dlgGetQuotaComites:GetWindowName('total_base2'):SetValue('');
	dlgGetQuotaComites:GetWindowName('total_places_demandees'):SetValue('');
	dlgGetQuotaComites:GetWindowName('total_places_obtenues'):SetValue('');
	-- AfficheNodeData();
end

function DisplayDataCalculette()
	params.somme_maxi_theorique = 0;
	params.somme_places_obtenues = 0;
	params.somme_demandees = 0;
	local somme_maxi_theorique = 0;
	local somme_places_obtenues = 0;
	local somme_places_demandees = 0;
	local somme_quota_maxi = 0;
	for i = 1, 14 do
		local quota_base = tonumber(dlgGetQuotaComites:GetWindowName('quota_base'..i):GetValue()) or 0;
		if tTableComite[i] and dlgGetQuotaComites:GetWindowName('chk'..i):GetValue() == true then
			dlgGetQuotaComites:GetWindowName('quota_maximum'..i):SetValue(Round(tTableComite[i].Quota_maxi,2))
			local quota_maxi = tonumber(dlgGetQuotaComites:GetWindowName('quota_maximum'..i):GetValue()) or 0;
			local place_demandee = tonumber(dlgGetQuotaComites:GetWindowName('places_demandees'..i):GetValue()) or 0;
			if tTableComite[i].Quota_calcule > 0 then
				dlgGetQuotaComites:GetWindowName('places_obtenues'..i):SetValue(tTableComite[i].Quota_calcule);
			end
			somme_quota_maxi = somme_quota_maxi + quota_maxi;
			somme_places_demandees = somme_places_demandees + place_demandee;
			somme_places_obtenues = somme_places_obtenues + tTableComite[i].Quota_calcule;
		else
			dlgGetQuotaComites:GetWindowName('quota_maximum'..i):SetValue('');
			dlgGetQuotaComites:GetWindowName('places_obtenues'..i):SetValue('');
			dlgGetQuotaComites:GetWindowName('places_demandees'..i):SetValue('');
		end
	end	

	local pourcent = ' %';
	if params.place_variable == 1 then
		place_cr2 = Round(params.place_comite_organisateur * params.a_repartir / 100, 0);
		place_club2 = Round(params.place_club_organisateur *  params.a_repartir / 100,0);
	else
		pourcent = '';
		place_cr2 = params.place_comite_organisateur;
		place_club2 = params.place_club_organisateur;
	end
	places_france = params.places_france;
	places_wc2 = params.wild_card;
	places_ffs = place_cr2 + place_club2 + places_wc2;
	
	dlgGetQuotaComites:GetWindowName('place_CR2'):SetValue(place_cr2);
	dlgGetQuotaComites:GetWindowName('place_CLUB2'):SetValue(place_club2);
	dlgGetQuotaComites:GetWindowName('wild_card2'):SetValue(place_wc2);
	dlgGetQuotaComites:GetWindowName('places_ffs'):SetValue(places_ffs);

	dlgGetQuotaComites:GetWindowName('total_base'):SetValue(params.total_base..' %');
	dlgGetQuotaComites:GetWindowName('total_base2'):SetValue(Round(somme_quota_maxi, 2));
	dlgGetQuotaComites:GetWindowName('total_places_obtenues'):SetValue(somme_places_obtenues);
	dlgGetQuotaComites:GetWindowName('total_places_demandees'):SetValue(somme_places_demandees);
	if params.a_repartir > 0 and somme_places_obtenues > 0 then
		local difference = (params.a_repartir - (somme_places_obtenues + places_ffs + places_france)) * -1;
		dlgGetQuotaComites:GetWindowName('difference'):SetValue(difference);
	end
end

function RecalculeQotaBase()
	if params.ne_pas_recalculer then
		do return end
	end
	local total = 0;
	if not tTableComite then
		SettTableComite(node_quota);
	end
	if params.coef_recalcul ~= 1 then
		for i = 1, #tTableComite do
			local quota_base = tTableComite[i].Quota_base;
			tTableComite[i].Quota_base = Round(tTableComite[i].Quota_base * params.coef_recalcul,2);
			total = total + tTableComite[i].Quota_base;
			-- adv.Alert("quota de base d'origine pour "..tTableComite[i].Comite..', quota recalculé  = '..tTableComite[i].Quota_base);
		end
	end
end

function GetParticipationComites()
-- Création Dialog 
	if not tTableComite then
		GetQuotaComites(node_quota);
		SettTableComite(node_quota);
		RecalculeQotaBase();
	end
	params.nb_maxi_lignes = #tTableComite;
	params.places_france = 0;
	
	params.label_dialog = 'Calculette de quota FIS (Philippe Guérindon) - version '..script_version;
	dlgGetQuotaComites = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		label=params.label_dialog, 
		icon='./res/32x32_fis.png'
		});
	
	dlgGetQuotaComites:LoadTemplateXML({ 
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 	
		tableau = tTableComite;
		lignes = params.nb_maxi_lignes,
		place_comite = params.place_comite_organisateur,
		place_club = params.place_club_organisateur,
		wild_card = params.wild_card,
		place_variable = params.place_variable,
		regroupement = params.code_regroupement,
		node_value = 'calculatrice'
	});
	
	dlgGetQuotaComites:GetWindowName('places_ffs'):SetValue(0);
	dlgGetQuotaComites:GetWindowName('label_quota'):SetValue('Quota maximum');
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):Clear();
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):Append('FIS');
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):Append('NJR');
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):Append('CIT');
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):Append('UNI');
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):SetSelection(0);
	tDisplayComite = {};
	DisplayQuotaBase();
	local tb = dlgGetQuotaComites:GetWindowName('tbbackoffice');
	tb:AddStretchableSpace();
	local btnSave = tb:AddTool("Calculer", "./res/32x32_save.png");
	tb:AddSeparator();
	local btnPrint = tb:AddTool("Imprimer", "./res/32x32_printer.png");
	tb:AddSeparator();
	local btnRAZ = tb:AddTool("Effacer", "./res/32x32_clear.png");
	tb:AddSeparator();
	local btnBackOffice = tb:AddTool("Back Office", "./res/32x32_param.png");
	tb:AddSeparator();
	local btnClose = tb:AddTool("Quitter", "./res/32x32_exit.png");

	tb:AddStretchableSpace();
	tb:Realize();
	
	params.nb_equipe = 0;

	dlgGetQuotaComites:Bind(eventType.COMBOBOX, 
		function(evt)
			params.code_regroupement = string.sub(dlgGetQuotaComites:GetWindowName('combo_regroupement'):GetValue(), 1, 3);
			node_quota = doc_config:FindFirst('root/hommes/'..params.code_regroupement);
			if not node_quota then
				return false;
			end
			GetQuotaComites(node_quota);
			SettTableComite(node_quota);
			RecalculeQotaBase();
			for i = 1, 20 do
				if dlgGetQuotaComites:GetWindowName('chk'..i) then
					dlgGetQuotaComites:GetWindowName('chk'..i):SetValue(false);
				end
			end
			DisplayQuotaBase();
		 end,
		 dlgGetQuotaComites:GetWindowName('combo_regroupement'));
	
	dlgGetQuotaComites:Bind(eventType.TEXT, 
		function(evt) 
			-- RAZdata();
			params.a_repartir = tonumber(dlgGetQuotaComites:GetWindowName('a_repartir'):GetValue()) or 0;
			DisplayQuotaBase();
		end,
		dlgGetQuotaComites:GetWindowName('a_repartir'));

	dlgGetQuotaComites:Bind(eventType.TEXT, 
		function(evt) 
			params.place_club_organisateur = tonumber(dlgGetQuotaComites:GetWindowName('place_CLUB2'):GetValue()) or 0;
			local total = params.place_club_organisateur + params.place_comite_organisateur + params.wild_card;
			dlgGetQuotaComites:GetWindowName('places_ffs'):SetValue(total);
		end,
		dlgGetQuotaComites:GetWindowName('place_CLUB2'));

	dlgGetQuotaComites:Bind(eventType.TEXT, 
		function(evt) 
			params.place_comite_organisateur = tonumber(dlgGetQuotaComites:GetWindowName('place_CR2'):GetValue()) or 0;
			local total = params.place_club_organisateur + params.place_comite_organisateur + params.wild_card;
			dlgGetQuotaComites:GetWindowName('places_ffs'):SetValue(total);
		end,
		dlgGetQuotaComites:GetWindowName('place_CR2'));

	dlgGetQuotaComites:Bind(eventType.TEXT, 
		function(evt) 
			params.wild_card = tonumber(dlgGetQuotaComites:GetWindowName('wild_card2'):GetValue()) or 0;
			local total = params.place_club_organisateur + params.place_comite_organisateur + params.wild_card;
			dlgGetQuotaComites:GetWindowName('places_ffs'):SetValue(total);
		end,
		dlgGetQuotaComites:GetWindowName('wild_card2'));

	dlgGetQuotaComites:Bind(eventType.TEXT, 
		function(evt) 
			params.places_france = tonumber(dlgGetQuotaComites:GetWindowName('places_france'):GetValue()) or 0;
		end,
		dlgGetQuotaComites:GetWindowName('places_france'));
		
	for i = 1, 14 do
	-- for i = 1, #tTableComite do
		dlgGetQuotaComites:Bind(eventType.CHECKBOX, 
			function(evt) 
				if dlgGetQuotaComites:GetWindowName('a_repartir'):GetValue():len() == 0 then
					dlgGetQuotaComites:GetWindowName('chk'..i):SetValue(false);
					local msg = "Vous devez d'abord définir les places à répartir";
					app.GetAuiFrame():MessageBox(msg, "Saisir les valeurs initiales du calcul", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
					return;
				end
				if dlgGetQuotaComites:GetWindowName('chk'..i):GetValue() == false then
					if tTableComite[i] then
						tTableComite[i].Quota_base2 = 0;
						tTableComite[i].Quota_calcule = 0;
						tTableComite[i].Quota_maxi = 0;
					end
				end
				if tTableComite[i] then
					local comite = tTableComite[i].Comite;
					local total_a_repartir = tonumber(dlgGetQuotaComites:GetWindowName('a_repartir'):GetValue()) or 0;
					params.nb_equipe = tonumber(dlgGetQuotaComites:GetWindowName('places_ffs'):GetValue()) or 0;
					params.nb_places_a_repartir = total_a_repartir - params.nb_equipe;
					local difference = 0;
					local a_repartir = params.nb_places_a_repartir;
					local pas = 0.1;
					local mult = -1;
					local nb_iteration = 0;
					while true do
						nb_iteration = nb_iteration + 1;
						difference = CalculeQuotaMaxiCalculette(a_repartir);
						if math.abs(difference) < 0.2 or nb_iteration == 20 then
							break;
						end
						local ajouter = a_repartir + (pas * mult);
						mult = mult * -1;
						a_repartir = a_repartir + ajouter;
					end
					difference = difference * -1;
				end
				DisplayDataCalculette();
			end,
			dlgGetQuotaComites:GetWindowName('chk'..i));
	end

	for i = 1, #tTableComite do
		if tTableComite[i].Comite then
			dlgGetQuotaComites:Bind(eventType.TEXT, 
				function(evt) 
					OnDisplayTotalDemande();
				end,
				dlgGetQuotaComites:GetWindowName('places_demandees'..i));
		end
	end

	for i = 1, #tTableComite do
		if tTableComite[i].Comite then
			dlgGetQuotaComites:Bind(eventType.TEXT, 
				function(evt) 
					OnDisplayTotalObtenu()
				end,
				dlgGetQuotaComites:GetWindowName('places_obtenues'..i));
		end
	end

	dlgGetQuotaComites:Bind(eventType.MENU, 
		function(evt)
			local nb_iteration = 1;
			local difference = 0;
			local a_repartir = 0;
			local total = params.place_club_organisateur + params.place_comite_organisateur + params.wild_card + params.places_france;
			a_repartir = params.a_repartir - total;
			for i = 1, #tTableComite do
				if dlgGetQuotaComites:GetWindowName('chk'..i):GetValue() == true then
					local participation = tonumber(dlgGetQuotaComites:GetWindowName('places_demandees'..i):GetValue()) or 0;
					if participation > 0 then
						tTableComite[i].Participation = participation;
					end
				end
			end
			-- adv.Alert('avant boucle de calcul, a_repartir = '..a_repartir);
			while true do
				difference = CalculeQuota(a_repartir, 1);
				if math.abs(difference) > 2 then
					break;
				end
				if nb_iteration == 30 then
					break;
				end
				if difference == 0 then
					break;
				end
				nb_iteration = nb_iteration + 1;
				if difference > 0 then
					a_repartir = a_repartir - 0.1;
				else
					a_repartir = a_repartir + 0.1;
				end
			end
			DisplayDataCalculette()
		 end,  btnSave);
		 
	dlgGetQuotaComites:Bind(eventType.MENU, 
		function(evt)
			RAZdata();
			for index = 1, #tTableComite do
				local comite = tTableComite[index].Comite;
				dlgGetQuotaComites:GetWindowName('quota_maximum'..index):SetValue('');
				dlgGetQuotaComites:GetWindowName('places_demandees'..index):SetValue('');
				dlgGetQuotaComites:GetWindowName('places_obtenues'..index):SetValue('');
				dlgGetQuotaComites:GetWindowName('chk'..index):SetValue(false);
			end
			dlgGetQuotaComites:GetWindowName('total_base'):SetValue('');
			dlgGetQuotaComites:GetWindowName('total_base2'):SetValue('');
			dlgGetQuotaComites:GetWindowName('total_places_obtenues'):SetValue('');
			dlgGetQuotaComites:GetWindowName('total_places_demandees'):SetValue('');
		 end,  btnRAZ);
	dlgGetQuotaComites:Bind(eventType.MENU, 
		function(evt) 
			OnAfficheBackOffice();
		 end,  btnBackOffice);
	dlgGetQuotaComites:Bind(eventType.MENU, 
		function(evt)
			OnPrintCalculette();
			dlgGetQuotaComites:EndModal(idButton.CANCEL);
		 end,  btnPrint);
	dlgGetQuotaComites:Bind(eventType.MENU, 
		function(evt) 
			dlgGetQuotaComites:EndModal(idButton.CANCEL);
		 end,  btnClose);
	dlgGetQuotaComites:Fit();
	dlgGetQuotaComites:ShowModal();
end

function GetNbPlacesARepartir()
-- Création Dialog 
	
	dlgValue = wnd.CreateDialog(
		{
		width = 300;
		height = 200;
		x = (params.width - 300) / 2;
		y = (params.height - 200) / 2;
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		label="Nombre de places à répartir", 
		icon='./res/32x32_fis.png'
		});
		dlgValue:LoadTemplateXML({ 
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 	
		node_value = 'get_valeur'
	});

	local tb = dlgValue:GetWindowName('tbgetvalue');
	tb:AddStretchableSpace();
	local btnSave = tb:AddTool("Enregistrer", "./res/vpe32x32_save.png");

	tb:AddStretchableSpace();
	tb:Realize();
	
	dlgValue:Bind(eventType.MENU, 
		function(evt)
			local valeur = tonumber(dlgValue:GetWindowName('val_140'):GetValue()) or 0;
			local a_repartir = params.nb_francais - params.nb_equipe;
			if params.codex:sub(1,3) == 'FRA' and valeur > a_repartir then
				app.GetAuiFrame():MessageBox(
					"Le nombre de places à répartir ne peut pas être\nsupérieur à '..a_repartir !!", 
					"Attention",
					msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
				return false;
			end
			params.nb_places_a_repartir = valeur;
			dlgValue:EndModal(idButton.CANCEL);
		 end,  btnSave);
	dlgValue:Fit();
	dlgValue:ShowModal();
end

function OnPrintCalculette()
	local imprimerPD = 1;
	local msg = 'Voulez-vous imprimer la colonne "Places demandées" ?';
	local key = app.GetAuiFrame():MessageBox(msg, "Impression", msgBoxStyle.YES + msgBoxStyle.NO + msgBoxStyle.YES_DEFAULT + msgBoxStyle.ICON_WARNING);
	if key == msgBoxStyle.NO then
		imprimerPD = 0;
	end
	local tQuota_comite = sqlTable.Create("tQuota_comite");
	tQuota_comite:AddColumn({ name = 'Comite', label = 'Comite', type = sqlType.CHAR, size = 10 });
	tQuota_comite:AddColumn({ name = 'Quota_base', label = 'Quota_base', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Quota_base2', label = 'Quota_base2', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Participation', label = 'Participation', type = sqlType.LONG, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Quota_calcule', label = 'Quota_calcule', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tQuota_comite:SetPrimary('Comite');
	tQuota_comite:SetName('_Quota_comite');
	ReplaceTableEnvironnement(tQuota_comite, '_Quota_comite');
	local somme_base2 = 0;
	local somme_inscrits = 0;
	local somme_quota_calcule = 0
	for i = 1, #tTableComite do
		local quota_calcule = tonumber(dlgGetQuotaComites:GetWindowName('places_obtenues'..i):GetValue()) or 0;
		tTableComite[i].Quota_calcule = quota_calcule;
		local row = tQuota_comite:AddRow();
		local comite = tTableComite[i].Comite;
		if comite == 'GI' and node_quota:HasAttribute('GI') then
			comite = 'GIRSA';
		elseif comite == 'PY' and node_quota:HasAttribute('PY') then
			comite = 'PE/PO';
		elseif comite == 'IF' then
			comite = 'IFNO';
		end
		tQuota_comite:SetCell('Comite', row, comite);
		tQuota_comite:SetCell('Quota_base', row, tTableComite[i].Quota_base);
		local base2 = Round(tTableComite[i].Quota_calcule * 100 / (params.a_repartir - params.nb_equipe),2);
		tQuota_comite:SetCell('Quota_base2', row, base2);
		somme_base2 = somme_base2 + base2;
		tQuota_comite:SetCell('Participation', row, tTableComite[i].Participation);
		somme_inscrits = somme_inscrits + tTableComite[i].Participation;
		tQuota_comite:SetCell('Quota_calcule', row, tTableComite[i].Quota_calcule);
		somme_quota_calcule = somme_quota_calcule + tTableComite[i].Quota_calcule;
	end
	local places_ffs = tonumber(dlgGetQuotaComites:GetWindowName('places_ffs'):GetValue()) or 0;
	local places_france = tonumber(dlgGetQuotaComites:GetWindowName('places_france'):GetValue()) or 0;
	local total_reparti = somme_quota_calcule + places_ffs + places_france;
	local ligne1 = 'Calcul des quotas pour la course '..tEpreuve:GetCell('Code_regroupement',0)..
				'\n'..tEvenement:GetCell('Nom',0)..
				'\n'..tEvenement:GetCell('Station',0)..' du '..tEpreuve:GetCell('Date_epreuve',0)..'\n';
	if imprimerPD == 0 then
		ligne1 = '';
	end
	local ligne_titre = ligne1..
				'Les quotas '..params.code_regroupement..' ont été utilisés pour le calcul.'..
				"\nQuota total alloué sur la course : "..total_reparti;
	report = wnd.LoadTemplateReportXML({
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'printcalculette',
		paper_orientation = 'portrait',
		body = tQuota_comite,
		params = {Titre = ligne_titre, 
				Inscrits = somme_inscrits,
				Total_participation = somme_inscrits,
				Total_base = params.total_base,
				Total_base2 = somme_base2,
				Places_ffs = places_ffs,
				Places_france = places_france,
				Total_reparti = total_reparti,
				Place_CR = params.place_comite_organisateur,
				Place_CR2 = Place_CR,
				Place_CR2 = tonumber(dlgGetQuotaComites:GetWindowName('place_CR2'):GetValue()) or 0,
				Place_CLUB = params.place_club_organisateur,
				Place_CLUB2 = tonumber(dlgGetQuotaComites:GetWindowName('place_CLUB2'):GetValue()) or 0,
				Place_WC = params.wild_card,
				Place_WC2 = tonumber(dlgGetQuotaComites:GetWindowName('wild_card2'):GetValue()) or 0,
				ImprimerPD = imprimerPD,
				Variable = params.place_variable,
				RGB = params.RGB,
				Total_calcule = somme_quota_calcule}
		});
end


function OnPrintCalculs()
	local tQuota_comite = sqlTable.Create("tQuota_comite");
	tQuota_comite:AddColumn({ name = 'Comite', label = 'Comite', type = sqlType.CHAR, size = 10 });
	tQuota_comite:AddColumn({ name = 'Quota_base', label = 'Quota_base', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Quota_base2', label = 'Quota_base2', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Participation', label = 'Participation', type = sqlType.LONG, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Quota_calcule', label = 'Quota_calcule', type = sqlType.LONG, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Pourcent', label = 'Pourcent', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Status', label = 'Status', type = sqlType.LONG, style = sqlStyle.NULL });
	tQuota_comite:SetPrimary('Comite');
	tQuota_comite:SetName('_Quota_comite');
	ReplaceTableEnvironnement(tQuota_comite, '_Quota_comite');
	local somme_base = 0;
	local somme_base2 = 0;
	local somme_inscrits = 0;
	local display_ligne = true;
	for i = 1, #tTableComite do
		display_ligne = true;
		local comite = tTableComite[i].Comite;
		if comite == 'GI' and node_quota:HasAttribute('GI') then
			comite = 'GIRSA';
		elseif comite == 'PY' and node_quota:HasAttribute('PY') then
			comite = 'PE/PO';
		elseif comite == 'IF' then
			comite = 'IFNO';
		end
		if params.code_regroupement == 'CIT' and comite == 'CIT' then
			display_ligne = false;
		end
		if display_ligne == true then
			local row = tQuota_comite:AddRow();
			if tTableComite[i].Quota_calcule < tTableComite[i].Participation then
				tTableComite[i].Status = 1;
			end
			tQuota_comite:SetCell('Comite', row, comite);
			tQuota_comite:SetCell('Quota_base', row, tTableComite[i].Quota_base);
			somme_base = somme_base + tTableComite[i].Quota_base;
			tQuota_comite:SetCell('Quota_base2', row, tTableComite[i].Quota_base2);
			somme_base2 = somme_base2 + tTableComite[i].Quota_base2;
			tQuota_comite:SetCell('Participation', row, tTableComite[i].Participation);
			somme_inscrits = somme_inscrits + tTableComite[i].Participation;
			tQuota_comite:SetCell('Quota_calcule', row, tTableComite[i].Quota_calcule);
			tQuota_comite:SetCell('Pourcent', row, tTableComite[i].Pourcent);
			tQuota_comite:SetCell('Status', row, tTableComite[i].Status);
		end
	end
	if params.place_variable == 1 then
		somme_base = 100;
	else
		params.somme_quota_calcule = params.somme_quota_calcule - (params.place_comite_organisateur + params.place_club_organisateur + params.wild_card);
	end
	ligne_titre = 'CALCUL DES QUOTAS'..
			'\n'..tEvenement:GetCell('Nom', 0)..
			'\n'..tEvenement:GetCell('Station', 0)..' le '..tEpreuve:GetCell('Date_epreuve', 0)..
			'\nCourse '..tEpreuve:GetCell('Code_regroupement', 0)..' - CODEX : '..params.codex..
			'\nLes quotas '..params.code_regroupement..' sont utilisés pour le calcul';
	report = wnd.LoadTemplateReportXML({
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'print',
		paper_orientation = 'portrait',
		body = tQuota_comite,
		params = {Titre = ligne_titre, 
		Inscrits = somme_inscrits, 
		Etrangers = params.nb_etrangers, 
		Francais = params.nb_francais, 
		Francais_maxi = params.nb_francais_maxi, 
		Place_CR = params.place_comite_organisateur,
		Place_CR = tquotaComite['COMITE'],
		Place_Club140 = params.place_club_organisateur140, 
		Place_Club = params.place_club_organisateur,
		Place_WC140 = params.wild_card140, 
		Place_WC = params.wild_card,
		Somme_base = somme_base, 
		Somme_base2 =somme_base2,
		Somme_inscrits = somme_inscrits;
		Total_Calcule = params.somme_quota_calcule, 
		Nb_Equipe = params.nb_equipe,
		Total_General = params.total_general,
		Variable = params.place_variable,
		CR_node = tquotaComite['COMITE'],
		CLUB_node = tquotaComite['CLUB'],
		WC_node = params.wild_card_node,
		CR = params.place_comite_organisateur,
		CLUB = params.place_club_organisateur,
		WC = params.wild_card,
		RGB = params.RGB,
		Date = tEpreuve:GetCell('Date_epreuve', 0),
		Station = tEvenement:GetCell('Station', 0)}
		});
end

function OnDisplayTotalReparti()
	params.somme_quota_calcule = 0;
	for index = 1, #tTableComite do
		if dlgAfficheCalculs:GetWindowName('quota_calcule'..index) then
			params.somme_quota_calcule = params.somme_quota_calcule + tonumber(dlgAfficheCalculs:GetWindowName('quota_calcule'..index):GetValue()) or 0;
		end
	end
	
	-- params.somme_quota_calcule = tonumber(dlgAfficheCalculs:GetWindowName('somme_quota_calcule'):GetValue()) or 0;
	params.place_comite_organisateur = tonumber(dlgAfficheCalculs:GetWindowName('cr_orga'):GetValue()) or 0;
	params.place_club_organisateur = tonumber(dlgAfficheCalculs:GetWindowName('club_orga'):GetValue()) or 0;
	params.wild_card = tonumber(dlgAfficheCalculs:GetWindowName('wild_cards'):GetValue()) or 0;
	params.nb_equipe = tonumber(dlgAfficheCalculs:GetWindowName('equipe'):GetValue()) or 0;
	params.total_general = params.somme_quota_calcule + params.nb_etrangers + params.place_comite_organisateur + params.place_club_organisateur + params.wild_card + params.nb_equipe ;
	dlgAfficheCalculs:GetWindowName('total'):SetValue(params.total_general);
	local difference = params.valeur_140 - params.total_general;
	dlgAfficheCalculs:GetWindowName('difference'):SetValue(difference);
end

function OnDisplayQuotaCalcule()
	params.somme_quota_calcule = 0;
	for index = 1, #tTableComite do
		params.somme_quota_calcule = params.somme_quota_calcule + tTableComite[index].Quota_calcule;
		if tTableComite[index].Participation > 0 then
			tTableComite[index].Status = 0;
			if tTableComite[index].Quota_calcule  ~= tTableComite[index].Participation then
				tTableComite[index].Status = 1;
			end
			local pourcent_utilisation = 0;
			pourcent_utilisation = (tTableComite[index].Quota_calcule / tTableComite[index].Quota_base) * 100;
			dlgAfficheCalculs:GetWindowName('quota_base2'..index):SetValue(Round(pourcent_utilisation, 2));
		end

	end
	params.somme_quota_calcule = params.somme_quota_calcule + params.place_comite_organisateur + params.place_club_organisateur + params.wild_card;
	dlgAfficheCalculs:GetWindowName('somme_quota_calcule'):SetValue(params.somme_quota_calcule);
	params.total_general = params.somme_quota_calcule + params.nb_etrangers + params.nb_equipe;
	dlgAfficheCalculs:GetWindowName('total'):SetValue(params.total_general);
	local signe = '';
	local difference = 0;
	if params.nb_places_a_repartir then
		difference = params.total_general - params.nb_places_a_repartir;
	else
		difference = params.total_general - params.valeur_140;
	end
	if difference > 0 then
		signe = '+';
	end 
	dlgAfficheCalculs:GetWindowName('difference'):SetValue(signe..difference);
end

function DisplayCalcul()
	local pourcent = ' %'
	if params.place_variable == 0 then
		pourcent = '';
	end
	dlgAfficheCalculs:GetWindowName('cr_orga2'):SetValue(tquotaComite['COMITE']..pourcent);
	dlgAfficheCalculs:GetWindowName('club_orga2'):SetValue(tquotaComite['CLUB']..pourcent);
	dlgAfficheCalculs:GetWindowName('wild_cards2'):SetValue(tquotaComite['WILDCARD']..pourcent);

	-- if params.place_variable == 1 then
		-- dlgAfficheCalculs:GetWindowName('cr_orga3'):SetValue(params.place_comite_organisateur);
		-- dlgAfficheCalculs:GetWindowName('club_orga3'):SetValue(params.place_club_organisateur);
		-- dlgAfficheCalculs:GetWindowName('wild_cards3'):SetValue(params.wild_card);
	-- end
	local somme_maxi_theorique = 0;
	params.somme_quota_calcule = 0;
	params.somme_participation = 0;
	local somme_quota_base = 0;
	local somme_quota_base2 = 0;
	local display_ligne = true;
	for i = 1, #tTableComite do
		display_ligne = true;
		local comite = tTableComite[i].Comite;
		if comite == 'GI' then
			comite = 'GIRSA';
		elseif comite == 'PY' then
			comite = 'PE/PO';
		end
		if params.code_regroupement == 'CIT' and comite == 'CIT' then
			display_ligne = false;
		end
		if display_ligne == true then
			params.somme_quota_calcule = params.somme_quota_calcule + tTableComite[i].Quota_calcule;
			params.somme_participation = params.somme_participation + tTableComite[i].Participation;
			dlgAfficheCalculs:GetWindowName('comite'..i):SetValue(comite);
			dlgAfficheCalculs:GetWindowName('quota_base'..i):SetValue(tTableComite[i].Quota_base..'%');
			somme_quota_base = somme_quota_base + tTableComite[i].Quota_base;
			local pourcent_utilisation = 0;
			if tTableComite[i].Participation > 0 then
				pourcent_utilisation = (tTableComite[i].Quota_calcule / tTableComite[i].Quota_base) * 100;
			end
			dlgAfficheCalculs:GetWindowName('quota_base2'..i):SetValue(Round(pourcent_utilisation, 2)..'%');
			tTableComite[i].Quota_base2 = tTableComite[i].Quota_calcule * 100 / params.a_repartir;
			-- dlgAfficheCalculs:GetWindowName('quota_base2'..i):SetValue(Round(tTableComite[i].Quota_base2, 2)..'%');
			somme_quota_base2 = somme_quota_base2 + tTableComite[i].Quota_base2;
			dlgAfficheCalculs:GetWindowName('participation'..i):SetValue(tTableComite[i].Participation);
			dlgAfficheCalculs:GetWindowName('quota_calcule'..i):SetValue(tTableComite[i].Quota_calcule);
			if tTableComite[i].Participation > 0 then
				tTableComite[i].Pourcent = Round(tTableComite[i].Quota_calcule * 100 / tTableComite[i].Quota_base, 2);
			end
		end
	end
	if params.place_variable == 1 then
		somme_quota_base = somme_quota_base + tquotaComite['COMITE'] + tquotaComite['CLUB'] + tquotaComite['WILDCARD'];
	end
	params.somme_quota_calcule = params.somme_quota_calcule + params.place_comite_organisateur + params.place_club_organisateur + params.wild_card;
	dlgAfficheCalculs:GetWindowName('somme_quota_base'):SetValue(somme_quota_base..' %');
	-- dlgAfficheCalculs:GetWindowName('somme_quota_base2'):SetValue(somme_quota_base2..'%');

	dlgAfficheCalculs:GetWindowName('somme_participation'):SetValue(params.somme_participation);
	dlgAfficheCalculs:GetWindowName('somme_quota_calcule'):SetValue(params.somme_quota_calcule);
	dlgAfficheCalculs:GetWindowName('equipe'):SetValue(params.nb_equipe);
	params.total_general = params.somme_quota_calcule + params.nb_etrangers + params.nb_equipe ;
	dlgAfficheCalculs:GetWindowName('total'):SetValue(params.total_general);
	
	local signe = '';
	local difference = 0;
	if params.nb_places_a_repartir then
		difference = params.total_general - params.nb_places_a_repartir;
	else
		difference = params.total_general - params.valeur_140;
	end

	if params.place_variable == 1 then
	end
	if difference > 0 then
		signe = '+';
	end
	dlgAfficheCalculs:GetWindowName('difference'):SetValue(signe..difference);

end

function GetEpreuve()
	dlgGetEpreuve = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		label='Calcul des quotas : '..script_version.. ' - par Philippe Guérindon' , 
		icon='./res/32x32_fis.png'
		});
	
	dlgGetEpreuve:LoadTemplateXML({ 
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 
		node_value = 'get_epreuve',
		});


	-- Toolbar Principale ...
	local tbconfig = dlgGetEpreuve:GetWindowName('tbgetepreuve');
	tbconfig:AddStretchableSpace();
	local btnSave = tbconfig:AddTool("Valider", "./res/32x32_printer.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	
	dlgGetEpreuve:GetWindowName('num_epreuve'):Clear();
	for i = 0, tEpreuve:GetNbRows() -1 do
		dlgGetEpreuve:GetWindowName('num_epreuve'):Append((i+1)..' - '..tEpreuve:GetCell('Date_epreuve', i)..' / '..tEpreuve:GetCell('Sexe', i)..' / '..tEpreuve:GetCell('Code_discipline', i)..' / '..tEpreuve:GetCell('Codex', i));
	end
	dlgGetEpreuve:GetWindowName('num_epreuve'):SetSelection(0);
	dlgGetEpreuve:Bind(eventType.MENU, 
		function(evt)
			params.row_epreuve = dlgGetEpreuve:GetWindowName('num_epreuve'):GetSelection();
			dlgGetEpreuve:EndModal();
		end, btnSave);
		
	dlgGetEpreuve:Fit();
	dlgGetEpreuve:ShowModal();

end

function AfficheCalculs()
	local bouton = idButton.KO;
	for i = 1, #tTableComite do
		-- tTableComite[i].Maxi_theorique = math.ceil(tTableComite[i].Maxi_theorique);
		if tTableComite[i].Participation == 0 then
			tTableComite[i].Quota_calcule = 0;
			tTableComite[i].Status = 0;
		elseif tTableComite[i].Participation == tTableComite[i].Quota_calcule then
			tTableComite[i].Status = 0;
		end
	end
	local date_epreuve = '';
	local station = '';
	if not tRanking then
		date_epreuve = 'Ce jour';
		station = 'Calculette';
		race_name = 'Calculette de quota\npour une course '..params.code_regroupement;
	else
		date_epreuve = tEpreuve:GetCell('Date_epreuve', 0);
		station = tEvenement:GetCell('Station', 0);
		race_name = tEvenement:GetCell('Nom', 0)..'\nCourse '..tEpreuve:GetCell('Code_regroupement', 0)..' - quotas utilisés : '..params.code_regroupement;
	end
	filter_display = 'Epreuve '..(params.row_epreuve + 1);
	dlgAfficheCalculs = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		label='Calcul des quotas : '..script_version.. ' - par Philippe Guérindon' , 
		icon='./res/32x32_fis.png'
		});
	
	dlgAfficheCalculs:LoadTemplateXML({ 
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 
		discipline = params.discipline,
		node_value = 'config',
		tableau = tTableComite;
		lignes = #tTableComite,
		difference = difference,
		-- filter = params.filter,
		filter = filter_display,
		Date = date_epreuve,
		Station = station,
		Codex = params.codex,
		Variable = params.place_variable,
		nb_etrangers = params.nb_etrangers,
		place_comite = params.place_comite_organisateur,
		place_club = params.place_club_organisateur,
		place_wild_card = params.wild_card,
		RGB = params.RGB
		});

	-- adv.Alert('(params.place_comite_organisateur = '..params.place_comite_organisateur);
	dlgAfficheCalculs:GetWindowName('race_name'):SetValue(race_name);
	dlgAfficheCalculs:GetWindowName('inscrits'):SetValue(params.nb_inscrits);
	dlgAfficheCalculs:GetWindowName('equipe'):SetValue(params.nb_equipe);
	dlgAfficheCalculs:GetWindowName('etrangers'):SetValue(params.nb_etrangers);
	dlgAfficheCalculs:GetWindowName('etrangers2'):SetValue(params.nb_etrangers);
	dlgAfficheCalculs:GetWindowName('francais'):SetValue(params.nb_francais);
	dlgAfficheCalculs:GetWindowName('nb_francais_maxi'):SetValue(params.nb_francais_maxi);
	if params.place_variable == 0 then
		dlgAfficheCalculs:GetWindowName('cr_orga2'):SetValue(params.place_comite_organisateur);
		dlgAfficheCalculs:GetWindowName('club_orga2'):SetValue(params.place_club_organisateur);
		dlgAfficheCalculs:GetWindowName('wild_cards2'):SetValue(params.wild_card);
		dlgAfficheCalculs:GetWindowName('cr_orga'):SetValue(params.place_comite_organisateur);
	else
		dlgAfficheCalculs:GetWindowName('cr_orga2'):SetValue(params.place_comite_organisateur..' %');
		-- dlgAfficheCalculs:GetWindowName('cr_orga3'):SetValue(params.place_comite_organisateur);
		dlgAfficheCalculs:GetWindowName('club_orga2'):SetValue(params.place_club_organisateur..' %');
		-- dlgAfficheCalculs:GetWindowName('club_orga3'):SetValue(params.place_club_organisateur);
		dlgAfficheCalculs:GetWindowName('wild_cards2'):SetValue(params.wild_card..' %');
		-- dlgAfficheCalculs:GetWindowName('wild_cards3'):SetValue(params.wild_card);
	end
	dlgAfficheCalculs:GetWindowName('cr_orga'):SetValue(params.place_comite_organisateur);
	dlgAfficheCalculs:GetWindowName('club_orga'):SetValue(params.place_club_organisateur);
	dlgAfficheCalculs:GetWindowName('wild_cards'):SetValue(params.wild_card);
	DisplayCalcul();

	-- Toolbar Principale ...
	local tbconfig = dlgAfficheCalculs:GetWindowName('tbconfig');
	tbconfig:AddStretchableSpace();
	local btnPrint = tbconfig:AddTool("Imprimer", "./res/32x32_printer.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddSeparator();
	btnBackOffice = tbconfig:AddTool("Gestion des Quotas", "./res/32x32_configuration.png");
	tbconfig:AddStretchableSpace();

	tbconfig:Realize();
	for i = 1, #tTableComite do
		dlgAfficheCalculs:Bind(eventType.TEXT, 
			function(evt)
				tTableComite[i].Comite = tTableComite[i].Comite or nil;
				tTableComite[i].Quota_calcule = tonumber(dlgAfficheCalculs:GetWindowName('quota_calcule'..i):GetValue())or 0;
				OnDisplayQuotaCalcule();
			end,
			dlgAfficheCalculs:GetWindowName('quota_calcule'..i));
	end
	
	dlgAfficheCalculs:Bind(eventType.TEXT, 
		function(evt)
			params.nb_etrangers = tonumber(dlgAfficheCalculs:GetWindowName('etrangers2'):GetValue()) or 0;
			OnDisplayQuotaCalcule();
		end,
		dlgAfficheCalculs:GetWindowName('etrangers2'));

	dlgAfficheCalculs:Bind(eventType.TEXT, 
		function(evt)
			params.place_comite_organisateur = tonumber(dlgAfficheCalculs:GetWindowName('cr_orga'):GetValue()) or 0;
			OnDisplayQuotaCalcule();
		end,
		dlgAfficheCalculs:GetWindowName('cr_orga'));

	dlgAfficheCalculs:Bind(eventType.TEXT, 
		function(evt)
			params.place_club_organisateur = tonumber(dlgAfficheCalculs:GetWindowName('club_orga'):GetValue()) or 0;
			OnDisplayQuotaCalcule();
		end,
		dlgAfficheCalculs:GetWindowName('club_orga'));

	dlgAfficheCalculs:Bind(eventType.TEXT, 
		function(evt)
			params.wild_card = tonumber(dlgAfficheCalculs:GetWindowName('wild_cards'):GetValue()) or 0;
			OnDisplayQuotaCalcule();
		end,
		dlgAfficheCalculs:GetWindowName('wild_cards'));

	dlgAfficheCalculs:Bind(eventType.MENU, 
		function(evt) 
			OnPrintCalculs();
			params.exit = true;
			dlgAfficheCalculs:EndModal();
		end, btnPrint); 
				
	dlgAfficheCalculs:Bind(eventType.MENU, 
		function(evt) 
			dlgAfficheCalculs:EndModal(idButton.OK);
		 end,  btnBackOffice);

	dlgAfficheCalculs:Bind(eventType.MENU, 
		function(evt) 
			OnClose();
			dlgAfficheCalculs:EndModal(idButton.CANCEL) 
		 end,  btnClose);
	dlgAfficheCalculs:Fit();
	bouton = dlgAfficheCalculs:ShowModal()
	
	if bouton == idButton.OK then
		OnAfficheBackOffice();
	elseif bouton == idButton.KO then
		-- AfficheCalculs();
	end

end

function GetQuotaComites(node)
	-- lecture du node
	local somme_quota_base = 0;
	tquotaComite = {};
	local attribute = node:GetAttributes();
	while attribute ~= nil do
		local name = attribute:GetName();
		local value = attribute:GetValue();
		if tonumber(value) ~= nil then
			value = tonumber(value);
		end
		if name == 'COMITE' then
			tquotaComite[name] = value;
			params.place_comite_organisateur = value;
		elseif name == 'CLUB' then
			tquotaComite[name] = value;
			params.place_club_organisateur = value;
		elseif name == 'WILDCARD' then
			tquotaComite[name] = value;
			params.wild_card = value;
		elseif name == 'ORIGINE' then
			params.equipe_Comite_origine = value
		elseif name == 'filter' then
			if not params.kill_filter then
				params.filter = ''
				-- params.filter = value
			end
		elseif name == 'VARIABLE' then
			params.place_variable = value;
		else	-- on est dans un comité
			if estNumerique(value) then
				tquotaComite[name] = value;
				somme_quota_base = somme_quota_base + value;
			end
		end
		attribute = attribute:GetNext();
		-- adv.Alert(name..' : '..value);
	end
	if params.calculette == 1 then
		if not params.ne_pas_recalculer then
			params.place_comite_organisateur = 0;
			params.place_club_organisateur = 0;
			params.wild_card = 0;
			params.coef_recalcul = 100 / somme_quota_base;
			if not dlgBackOffice then
				RecalculeQotaBase();
			end
		end
	end
	if params.codex:sub(1,3) ~= 'FRA' then
		params.place_comite_organisateur = 0;
		params.place_club_organisateur = 0;
		params.wild_card = 0;
	end
	SettTableComite(node);
end

function CalculeQuota(a_repartir, nb_iteration)
	if not a_repartir then
		do return end
	end
	local difference = 0;
	-- adv.Alert('\nCalculeQuota, nb_iteration = '..nb_iteration..', a_repartir = '..a_repartir);
	-- params.a_repartir = nombre de places allouées à la répartition dans les comités déduction faite des places réservées
	-- on ne tient compte que des comités ayant des inscrits
	-- pour un comité, on a un quota de base en %tage ex : 18.41 

	-- adv.Alert('GetSetData - type(tRecalcul) = '..type(tRecalcul));
	params.somme_quota_base = 0;
	params.somme_places_rendues = 0;
	params.somme_quota_base2 = 0;
	params.somme_quota_calcules = 0;
	local somme_repartie = 0;
	local somme_equipe = 0;
	local somme_restant_a_repartir = 0;

	local somme_maxi_theorique = 0;
	local somme_pour_redistribution = 0;
	for index = 1, #tTableComite do
		if tTableComite[index].Participation > 0 then
			params.somme_quota_base = params.somme_quota_base + tTableComite[index].Quota_base;
		end
	end
	if params.place_variable == 1 then
		params.somme_quota_base = params.somme_quota_base + tquotaComite['COMITE'] + tquotaComite['CLUB'] + tquotaComite['WILDCARD'];
	end
	-- if nb_iteration == 1 then
		-- adv.Alert('CalculeQuota passage 1, somme des comités présents - params.somme_quota_base = '..params.somme_quota_base);
		-- adv.Alert('Quota_base2 = Quota_base * 100 / somme_quota_base, Maxi_theorique = a_repartir * Quota_base2 / 100');
	-- end
	for index = 1, #tTableComite do
		if tTableComite[index].Participation > 0 then
			local quota_calcule = 0;
			local comite = tTableComite[index].Comite;
			tTableComite[index].Quota_base2 = tTableComite[index].Quota_base * 100 / params.somme_quota_base;
			tTableComite[index].Maxi_theorique = a_repartir * tTableComite[index].Quota_base2 / 100;
			-- if nb_iteration == 1 then
				-- adv.Alert(comite..', participation '..tTableComite[index].Participation..', Quota_base = '..tTableComite[index].Quota_base..', Quota_base2 = '..tTableComite[index].Quota_base2..', Maxi_theorique = '..tTableComite[index].Maxi_theorique);
			-- end
			if tTableComite[index].Participation > tTableComite[index].Maxi_theorique then
				tTableComite[index].Status = 1;
				-- if nb_iteration == 1 then
					-- adv.Alert(comite..', participation > tTableComite[index].Maxi_theorique, Quota_calcule = '..tTableComite[index].Quota_calcule..', Status = '..tTableComite[index].Status);
				-- end
			else
				tTableComite[index].Status = 9;
				tTableComite[index].Quota_calcule = tTableComite[index].Participation;
				tTableComite[index].Place_gagnee = 9;

				-- if nb_iteration == 1 then
					-- adv.Alert(comite..', participation <= tTableComite[index].Maxi_theorique, Quota_calcule = '..tTableComite[index].Quota_calcule..', Status = '..tTableComite[index].Status);
				-- end
			end
		end
	end
	-- if nb_iteration == 1 then
		-- adv.Alert('CalculeQuota passage 2 - somme_quota_calcules = '..params.somme_quota_calcules..', somme_places_rendues = '..params.somme_places_rendues..', total des 2 = '..(params.somme_quota_calcules + params.somme_places_rendues));
	-- end
	-- les comités pourvus incomplètement ont un status à 1
	local somme_quotax = 0;
	params.somme_quota_calcules	= 0
	for index = 1, #tTableComite do
		local comite = tTableComite[index].Comite;
		params.somme_quota_calcules = params.somme_quota_calcules + tTableComite[index].Quota_calcule;
		-- adv.Alert(comite..', participation = '..tTableComite[index].Participation..', quota_base = '..tTableComite[index].Quota_base..', Quota_calcule = '..tTableComite[index].Quota_calcule);
		if tTableComite[index].Status == 1 then
			somme_quotax = somme_quotax + tTableComite[index].Quota_base2;
		end
	end
	-- on recalcule Representation des comités devant recevoir les places rendues
	for index = 1, #tTableComite do
		if tTableComite[index].Status == 1 then
			local comite = tTableComite[index].Comite;
			tTableComite[index].Representation = (tTableComite[index].Quota_base2 / somme_quotax) * 100;
		end
	end
	-- adv.Alert('CalculeQuota passage 2');
	-- somme_restant_a_repartir = a_repartir - params.somme_quota_calcules + params.somme_places_rendues;
	somme_restant_a_repartir = a_repartir - params.somme_quota_calcules;
	-- adv.Alert('\na_repartir = '..a_repartir..', Quotas déjà attribués = '..params.somme_quota_calcules..', somme_restant_a_repartir = '..somme_restant_a_repartir);
	-- tTableComite[index].Quota_base2  = pourcentage de représentativité d'un comité parmi ceux qui ont des participants. C'est un pourcantage sur 100
	-- tTableComite[index].Maxi_theorique  = nombre de place (décimale) qu'un comité peut recevoir. Leur addition donne le nombre e place à répartir
	-- on aura attribué les Quota_calcule selon : 
	--		un comité ayant une participation >= Quota_base2  --> Maxi_theorique. Place_gagnee = 0;
	--		un comité ayant une participation <  Quota_base2  -->Participation
	--				dans ce cas, Place_Rendue = Maxi_theorique - Participation. Place rendue = valeur décimale
	--				dans ce cas, Place_gagnee = -1
	-- les comités ayant Place_gagnee = 0 doivent recevoir une fraction des places rendues selon leur pourcentage de représentativité.
--	table.insert(tTableComite, {Comite = 'AP', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	params.somme_quota_base2 = 0;
	for index = 1, #tTableComite do
		if tTableComite[index].Status ~= 9 then
			delta_a_rajouter = 0;
			if tTableComite[index].Status == 1 then
				local comite = tTableComite[index].Comite;
				local gagne = (somme_restant_a_repartir * tTableComite[index].Representation) / 100;
				-- adv.Alert('\npour le comite '..comite..', gagné = '..gagne..', tTableComite[index].Quota_calcule + gagne = '..tTableComite[index].Quota_calcule + gagne);
				
				if tTableComite[index].Quota_calcule + gagne > tTableComite[index].Participation then
					delta_a_rajouter = tTableComite[index].Quota_calcule + gagne - tTableComite[index].Participation;
					tTableComite[index].Quota_calcule = tTableComite[index].Participation;
					-- adv.Alert('\nOn remonte '..comite..', à sa participation');
					tTableComite[index].Quota_calcule =  tTableComite[index].Participation;
				else 
					tTableComite[index].Place_gagnee = 2;
					-- adv.Alert('le comite '..comite..' va recevoir des places au tour 2, on recalculera sa nouvelle representation');
				end
			end
		end
	end
	-- adv.Alert('CalculeQuota passage 3');
	for index = 1, #tTableComite do
		if tTableComite[index].Place_gagnee == 2 then
			params.somme_quota_base2 = params.somme_quota_base2 + tTableComite[index].Quota_base2;
		end
	end
	params.somme_quota_calcules = 0;
	for index = 1, #tTableComite do
		params.somme_quota_calcules = params.somme_quota_calcules + tTableComite[index].Quota_calcule;
		if tTableComite[index].Place_gagnee == 2 then
			local comite = tTableComite[index].Comite;
			tTableComite[index].Representation = (tTableComite[index].Quota_base2 / params.somme_quota_base2) * 100;
			-- adv.Alert('le comite '..comite..' va recevoir des places, sa nouvelle représentation est de '..tTableComite[index].Representation..'%');
		end
	end
	local calcul = 0;
	somme_restant_a_repartir = a_repartir - params.somme_quota_calcules;
	-- adv.Alert('on redistribue le reliquat des places rendues, somme_restant_a_repartir = '..somme_restant_a_repartir);
	for index = 1, #tTableComite do
		if tTableComite[index].Place_gagnee == 2 then
			local comite = tTableComite[index].Comite;
			local gagne = (somme_restant_a_repartir * tTableComite[index].Representation) / 100;
			-- adv.Alert('\n'..comite..' - Place_gagnee == 2 , Quota_calcule initial = '..tTableComite[index].Quota_calcule..', gagne = '..gagne);
			tTableComite[index].Quota_calcule = tTableComite[index].Quota_calcule + gagne
		end
	end
	-- adv.Alert('CalculeQuota passage 4');

	calcul = 0;
	for index = 1, #tTableComite do
		if tTableComite[index].Participation > 0 then
			local comite = tTableComite[index].Comite;
			if params.calculette == 0 then
				tTableComite[index].Quota_calcule = Round(tTableComite[index].Quota_calcule, 0);
			else
				tTableComite[index].Quota_calcule = Round(tTableComite[index].Quota_calcule, 0);
			end
			if tTableComite[index].Quota_calcule > tTableComite[index].Participation then
				tTableComite[index].Quota_calcule = tTableComite[index].Participation;
			end
			calcul = calcul + tTableComite[index].Quota_calcule;
			tTableComite[index].Quota_base2 = tTableComite[index].Quota_calcule * 100 / a_repartir;
		end
		-- if type(tRecalcul) == 'table' then
			-- adv.Alert('passage 2 '..tTableComite[index].Comite..', Quota_calcule = '..tTableComite[index].Quota_calcule..', somme Quota_calcule = '..calcul);
		-- end
		-- adv.Alert('passage 2 '..tTableComite[index].Comite..', Quota_calcule = '..tTableComite[index].Quota_calcule..', somme Quota_calcule = '..calcul);
	end
	difference = calcul - a_repartir;
	-- adv.Alert('\n fin de CalculeQuota, sonme des quotas calculés = '..calcul..', a_repartir = '..params.a_repartir..', difference = '..difference..'\n-');
	-- if params.place_variable == 1 then
		-- params.place_comite_organisateur = params.place_comite_organisateur - difference;
		-- difference = 0;
	-- end
	return difference;
end

function GetSetData()
	params.somme_quota_base = 0;

	for index = 1, #tTableComite do
		if tTableComite[index].Quota_base then
			params.somme_quota_base = params.somme_quota_base + tTableComite[index].Quota_base;
		else
			tTableComite[index].Quota_base  = 0;
		end
	end
	if params.nb_places_a_repartir then
		params.nb_francais_maxi = params.nb_places_a_repartir;
		params.a_repartir = params.nb_places_a_repartir;
	elseif tRanking then
		if tRanking:GetNbRows() >= 140 then
			params.nb_francais_maxi = 140 - params.nb_etrangers;
		else
			params.nb_francais_maxi = tRanking:GetNbRows() - params.nb_etrangers;
		end
	end
	if params.calculette == 1 and params.codex:sub(1,3) ~= 'FRA' then
		params.place_comite_organisateur = 0;
		params.place_club_organisateur = 0;
		params.wild_card = 0;
	end
	if params.calculette == 0 then
		if params.place_variable == 0 then
			params.a_repartir = params.nb_francais_maxi - (params.place_comite_organisateur + params.place_club_organisateur + params.wild_card  + params.nb_equipe);
		else
			local a_retirer = 0;
			params.place_comite_organisateur = Round(params.place_comite_organisateur * params.nb_francais_maxi / 100, 0) ;
			params.place_club_organisateur = Round(params.place_club_organisateur * params.nb_francais_maxi / 100, 0) ;
			params.wild_card = Round(params.wild_card * params.nb_francais_maxi / 100, 0) ;
			params.a_repartir = params.nb_francais_maxi - (params.place_comite_organisateur + params.place_club_organisateur + params.wild_card);
		end
	end
	-- adv.Alert('GetSetData');
	-- adv.Alert('params.nb_francais_maxi = '..params.nb_francais_maxi);
	-- adv.Alert('params.somme_quota_base = '..params.somme_quota_base);
	-- adv.Alert('params.a_repartir = '..params.a_repartir);
	-- adv.Alert('params.place_comite_organisateur = '..params.place_comite_organisateur);
	-- adv.Alert('params.place_club_organisateur = '..params.place_club_organisateur);
	-- adv.Alert('params.wild_card = '..params.wild_card);
	-- adv.Alert('params.nb_equipe = '..params.nb_equipe);
	-- adv.Alert('params.place_variable = '..params.place_variable);
	nb_iteration = 1;
	local difference = 0;
	local a_repartir = params.a_repartir;
	local multiplicateur = 1;
	local pas = 0.05;
	while true do
		difference = CalculeQuota(a_repartir, nb_iteration);
		difference = 0;
		if math.abs(difference) < 0.1 or math.abs(difference) > 2 then
			-- adv.Alert('sortie de boucle sur itération '..nb_iteration..' avec math.abs(difference) = '..math.abs(difference));
			break;
		end
		nb_iteration = 20;
		if nb_iteration == 20 then
			adv.Alert('\nsortie de la boucle while, après CalculeQuota nb_iteration = '..nb_iteration..', différence = '..difference..', à repartir tour suivant = '..a_repartir);
			return false;
		end
		
		for index = 1, #tTableComite do
			tTableComite[index].Quota_base2 = 0;
			tTableComite[index].Place_gagnee = 0;
			tTableComite[index].Place_theorique2 = 0;
			tTableComite[index].Quota_calcule = 0;
			tTableComite[index].Place_Rendue = 0;
			tTableComite[index].Pourcent = 0;
			tTableComite[index].Status = 1;
		end
		nb_iteration = nb_iteration + 1;
		multiplicateur = multiplicateur * -1;
		a_repartir = params.a_repartir + (pas * multiplicateur * (nb_iteration -1));
		adv.Alert('\nfin de la boucle while, après CalculeQuota nb_iteration = '..nb_iteration..', différence = '..difference..', à repartir tour suivant = '..a_repartir);
	end
end

function SettTableComite(node);
	tTableComite = {};
	table.insert(tTableComite, {Comite = 'AP', Ordre = 1, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	table.insert(tTableComite, {Comite = 'AU', Ordre = 2, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	table.insert(tTableComite, {Comite = 'CA', Ordre = 3, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	table.insert(tTableComite, {Comite = 'CO', Ordre = 4, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	table.insert(tTableComite, {Comite = 'DA', Ordre = 5, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	table.insert(tTableComite, {Comite = 'IF', Ordre = 6, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	table.insert(tTableComite, {Comite = 'MB', Ordre = 7, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	table.insert(tTableComite, {Comite = 'MJ', Ordre = 8, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	table.insert(tTableComite, {Comite = 'MV', Ordre = 9, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	table.insert(tTableComite, {Comite = 'SA', Ordre = 15, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	if node:HasAttribute('PY') then
		table.insert(tTableComite, {Comite = 'PY', Ordre = 10, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	else
		table.insert(tTableComite, {Comite = 'PE', Ordre = 10, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
		table.insert(tTableComite, {Comite = 'PO', Ordre = 11, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	end
	if node:HasAttribute('GI') then
		table.insert(tTableComite, {Comite = 'GI', Ordre = 18, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	else
		table.insert(tTableComite, {Comite = 'BO', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
		table.insert(tTableComite, {Comite = 'FZ', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
		table.insert(tTableComite, {Comite = 'CE', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
		table.insert(tTableComite, {Comite = 'LY', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
		table.insert(tTableComite, {Comite = 'OU', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_manquante = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	end
	if node:HasAttribute('CIT') then
		table.insert(tTableComite, {Comite = 'CIT', Ordre = 20, Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = -1});
	end
	SortTable('<', tTableComite, {'Ordre'});
	for index = 1, #tTableComite do
		local comite = tTableComite[index].Comite;
		tTableComite[index].Quota_base = tquotaComite[comite];
	end
	-- adv.Alert('Sortie de SettTableComite');
	-- tTableComite = tTableComite;
end

-- Fonction pour vérifier si une variable est numérique
function estNumerique(variable)
    return tonumber(variable) ~= nil
end

function InitData()
	params.nb_equipe = 0;
	params.nb_francais = 0;
	params.nb_etrangers = 0;
	params.place_comite_organisateur = 0;
	params.place_club_organisateur = 0;
	params.wild_card = 0;
	params.comite_origine = 0;
	params.place_variable = 0;
	params.filter = '';
	params.equipe_Comite_origine = 0;
end

function main(params_c)
	script_version = 3.02;
	indice_return = 11;
	params = params_c;
	params.RGB = {};
	params.RGB[1] = 'rgb 200 255 200';
	params.RGB[2] = {};
	params.RGB[2][1] = 'rgb 255 192 0';
	params.RGB[2][2] = 'rgb 255 0 0';
	params.calculette = tonumber(params.calculette or 1) or 0;
	params.row_epreuve = 0;
	tEvenement = base:GetTable('Evenement');
	tEpreuve = base:GetTable('Epreuve');
	tResultat_Paiement = base:GetTable('Resultat_Paiement');
	if tResultat_Paiement == nil then
		CreateResultatPaiement();
		app.GetAuiFrame():MessageBox(
			"La base de donnée a nécessité l'ajout d'une table'.\nLe script va se fermer automatiquement.\nVous devrez quitter complètement skiFFS et relancer le programme.", 
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
			return true;
	end

	if params.code_evenement >= 0 then
		base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
		base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
		params.code_regroupement = string.sub(tEpreuve:GetCell('Code_regroupement', 0), 1, 3);
		if params.calculette == 0 and tEpreuve:GetNbRows() > 1 then
			GetEpreuve();
		end
	else
		if params.calculette == 0 and not params.code_evenement then
			return;
		end
	end
	InitData();
	if params.calculette == 0 then
		if tEvenement:GetCell('Code_entite', 0) ~= 'FIS' then
			return;
		end
	end
	if params.code_regroupement:len() == 0 then
		params.code_regroupement = 'FIS';
	end
	params.comite_organisateur = tEvenement:GetCell('Code_comite', 0);
	params.codex = tEpreuve:GetCell('Fichier_transfert', params.row_epreuve);
	params.width = display:GetSize().width;
	params.height = display:GetSize().height - 50;
	params.x = 0;
	params.y = 0;
	local msg = '';
	if app.GetVersion() >= '5.0' then 
		-- vérification de l'existence d'une version plus récente du script.
		-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2
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
	-- params.codex = 'FRA';
	base = base or sqlBase.Clone();
	-- Ouverture Document XML 
	xml_config_quota = app.GetPath()..'/quotaFIS_config.xml';
	if not app.FileExists(xml_config_quota) then
		msg = "Vous n'êtes pas habilité à gérer les quotas FIS";
		app.GetAuiFrame():MessageBox(msg, "Droits insuffisants", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		app.RemoveFile('./process/quotaFIS.lua');
		return;
	end
	doc_config = xmlDocument.Create(xml_config_quota);
	root = doc_config:GetRoot();
	node_quota = doc_config:FindFirst('root/hommes/'..string.sub(params.code_regroupement, 1, 3));
	if not node_quota then
		msg = msg.."La gestion de quotas n'est pas prévue\npour le code regroupement "..params.code_regroupement;
		app.GetAuiFrame():MessageBox(msg, "Quotas non gérés", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		return;
	else
		GetQuotaComites(node_quota);
		SettTableComite(node_quota);

		if params.calculette == 0  then
			tResultat = base:GetTable('Resultat');
			base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
			-- if node_quota:HasAttribute('filter') then
				-- params.filter = node_quota:GetAttribute('filter');
			-- end
			if node_quota:HasAttribute('filter') then
				node_quota:DeleteAttribute('filter');
			end
			tRanking = base.CreateTableRanking({ code_evenement = params.code_evenement});
			for i = 1, 9 do
				tRanking:AddColumn({ name = 'Epreuve_selection'..tostring(i), label = 'Epreuve_selection'..tostring(i), type = sqlType.CHAR, size = 1 });
			end
			local col = 'Epreuve_selection'..tostring(params.row_epreuve + 1);		
			base:TableLoad(tResultat_Paiement, 'Select * From Resultat_Paiement Where Code_evenement = '..params.code_evenement);
			for i = 0, tResultat_Paiement:GetNbRows() -1 do
				if tResultat_Paiement:GetCell(col, i) ==  '-' or tResultat_Paiement:GetCell(col, i) == '' then
					local code_coureur = tResultat_Paiement:GetCell('Code_coureur', i);
					local row = tRanking:GetIndexRow('Code_coureur', code_coureur);
					if row >= 0 then
						tRanking:RemoveRowAt(row);
					end
				end
			end
			for i = 0, tRanking:GetNbRows() -1 do
				local comite = tRanking:GetCell('Comite', i);
				if comite == 'CNE' then
					comite = 'EQ';
					tRanking:SetCell('Comite', i, comite);
				end
				if comite == 'EQ' then
					if params.equipe_Comite_origine > 0 then
						comite = GetComiteOrigine(tRanking:GetCell('Code_coureur', i));
						tRanking:SetCell('Comite', i, comite);
					end
				end
				if comite:In('BO','FZ','CE','LY','OU') and node_quota:HasAttribute('GI') then
					comite = 'GI';
					tRanking:SetCell('Comite', i, comite);
				end
				if comite:In('PE','PO') and node_quota:HasAttribute('PY') then
					comite = 'PY';
					tRanking:SetCell('Comite', i, comite);
				end
			end
			-- tRanking:Snapshot('tRanking.db3');
			tRanking:SetCounter('Comite');
			tRanking:SetCounter('Nation');
			for index = 1, #tTableComite do
				local comite = tTableComite[index].Comite
				tTableComite[index].Participation = tRanking:GetCounterValue('Comite', comite);
			end

			params.nb_equipe = tRanking:GetCounterValue('Comite', 'EQ') + tRanking:GetCounterValue('Comite', 'CNE');
			params.nb_francais = tRanking:GetCounterValue('Nation', 'FRA');
			params.nb_etrangers = tRanking:GetNbRows() - params.nb_francais;
			if tRanking:GetNbRows() < 140 or params.codex:sub(1,3) ~= 'FRA' then
				params.valeur_140 = tRanking:GetNbRows();
				-- adv.Alert('prise de la valeur des places à répartir');
				GetNbPlacesARepartir();
			else
				params.valeur_140 = 140;
			end
			params.nb_inscrits = tRanking:GetNbRows();
			while true do
				if params.exit then
					break;
				end
				GetSetData();
				AfficheCalculs();
				if dlgAfficheCalculs then
					dlgAfficheCalculs = nil;
				end
			end
		else
			GetParticipationComites();
		end
	end
	if doc_config then
		doc_config:Delete();
	end
end

