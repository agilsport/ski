-- LIVE Draw par Philippe Guérindon

dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function OnClose()
	if params.doc ~= nil then
		params.doc:SaveFile();
	end
end

function OnSaveBackOffice()
	local tTableComiteSav = tTableComite;
	local place_comite_sav = params.place_comite_organisateur140;
	local place_club_sav = params.place_club_organisateur140;
	local wild_card_sav = params.wild_card140;
	local comite_origine = params.equipe_Comite_origine;
	local total = 0;
	for i = 1, #tTableComite do
		local comite = tTableComite[i].Comite;
		local new_value = dlgBackOffice:GetWindowName('new_quota_base'..i):GetValue();
		new_value = tonumber(new_value) or 0;
		total = total + new_value;
	end
	dlgBackOffice:GetWindowName('total_base2'):SetValue(total..'%');
	
	local bolOK = Eval(10000, Round(total * 100, 0));

	if bolOK == true then
		params.somme_quota_base = 100;
		for i = 1,#tTableComite do
			local comite = tTableComite[i].Comite;
			local new_value = tonumber(dlgBackOffice:GetWindowName('new_quota_base'..i):GetValue()) or 0;
			if new_value > 0 then
				tTableComite[i].Quota_base = new_value;
				tquotaComite[comite] = new_value;
				tTableComite[i].Quota_base = new_value;
				tTableComite[i].Quota_base2 = 0;
				tTableComite[i].Place_gagnee = 0;
				tTableComite[i].Place_Rendue = 0;
				tTableComite[i].Place_theorique2 = 0;
				tTableComite[i].Maxi_theorique = 0;
				tTableComite[i].Maxi_theorique2 = 0;
				tTableComite[i].Quota_calcule = 0;
				tTableComite[i].Status = 1;
				node_hommes:ChangeAttribute(comite, new_value);
			end
		end
		params.place_comite_organisateur = tonumber(dlgBackOffice:GetWindowName('place_comite_organisateur'):GetValue()) or 0;
		node_hommes:ChangeAttribute('COMITE', params.place_comite_organisateur140);
		params.place_club_organisateur = tonumber(dlgBackOffice:GetWindowName('place_club_organisateur'):GetValue()) or 0;
		node_hommes:ChangeAttribute('CLUB', params.place_club_organisateur140);
		params.wild_card = tonumber(dlgBackOffice:GetWindowName('wild_card'):GetValue()) or 0;
		node_hommes:ChangeAttribute('WILDCARD', params.wild_card140);
		params.equipe_Comite_origine = dlgBackOffice:GetWindowName('comboComiteOrigine'):GetSelection();
		node_hommes:ChangeAttribute('ORIGINE', params.equipe_Comite_origine);
		local touche = app.GetAuiFrame():MessageBox(
			"Oui  = enregistrer ces valeurs de manière permnente ?\nNon = refaire le calcul sans enregistrer ces valeurs\nAnnuler = revenir aux anciennes valeurs.", 
			"Information !!!",
			msgBoxStyle.YES + msgBoxStyle.NO + msgBoxStyle.CANCEL + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
			);
		if touche == msgBoxStyle.YES then
				doc_config:SaveFile();
		elseif touche == msgBoxStyle.CANCEL then
			tTableComite = tTableComiteSav;
			params.place_comite_organisateur = place_comite_sav;
			params.place_club_organisateur = place_club_sav;
			params.wild_card = wild_card_sav;
			params.equipe_Comite_origine = comite_origine;
		end
		return true;
	else
		app.GetAuiFrame():MessageBox(
			"L'addition des quotas de base doit être égale à 100 !!\nLe total ce ces valeur est actuellement de "..total, 
			"Information !!!",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING
			);
		return false;
	end
	
end

function TotaliseNewValue()
	local total = 0;
	for i = 1, #tTableComite do
		local valeur = tonumber(dlgBackOffice:GetWindowName('new_quota_base'..i):GetValue()) or 0;
		total = total + valeur;
	end
	return total;
end

function OnAfficheBackOffice()
-- Création Dialog 
	params.label_dialog = 'Back office du script';
	
	dlgBackOffice = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label=params.label_dialog, 
		icon='./res/32x32_fis.png'
		});
	
	dlgBackOffice:LoadTemplateXML({ 
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 	
		tableau = tTableComite;
		lignes = #tTableComite,
		place_comite = params.place_comite_organisateur,
		regroupement = params.code_regroupement,
		place_club = params.place_club_organisateur,
		wild_card = params.wild_card,
		node_value = 'backoffice'
	});
	local total_base = 0;
	for i = 1, #tTableComite do
		local comite = tTableComite[i].Comite;
		if comite == 'GI' then
			comite = 'GIRSA';
		elseif comite == 'PY' then
			comite = 'PE/PO';
		end
		dlgBackOffice:GetWindowName('comite'..i):SetValue(comite);
		dlgBackOffice:GetWindowName('old_quota_base'..i):SetValue(tTableComite[i].Quota_base);
		dlgBackOffice:GetWindowName('new_quota_base'..i):SetValue(tTableComite[i].Quota_base);
		total_base = total_base + tTableComite[i].Quota_base;
	end	
	dlgBackOffice:GetWindowName('total_base'):SetValue(total_base..'%');
	dlgBackOffice:GetWindowName('total_base2'):SetValue(total_base..'%');
	dlgBackOffice:GetWindowName('comboComiteOrigine'):Clear();
	dlgBackOffice:GetWindowName('comboComiteOrigine'):Append('Non');
	dlgBackOffice:GetWindowName('comboComiteOrigine'):Append('Oui');
	dlgBackOffice:GetWindowName('place_comite_organisateur'):SetValue(params.place_comite_organisateur);
	dlgBackOffice:GetWindowName('place_club_organisateur'):SetValue(params.place_club_organisateur);
	dlgBackOffice:GetWindowName('wild_card'):SetValue(params.wild_card);
	dlgBackOffice:GetWindowName('comboComiteOrigine'):SetSelection(params.equipe_Comite_origine);
	local tb = dlgBackOffice:GetWindowName('tbbackoffice');
	tb:AddStretchableSpace();
	local btnSave = tb:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tb:AddSeparator();
	local btnClose = tb:AddTool("Quitter", "./res/32x32_exit.png");

	tb:AddStretchableSpace();
	tb:Realize();
	
	for i = 1, #tTableComite do
		dlgBackOffice:Bind(eventType.TEXT, 
			function(evt)
				local total = TotaliseNewValue();
				dlgBackOffice:GetWindowName('total_base2'):SetValue(total..'%');
			 end,  dlgBackOffice:GetWindowName('new_quota_base'..i));
	end
	dlgBackOffice:Bind(eventType.MENU, 
		function(evt)
			params.recalcul = false;
			local ok = OnSaveBackOffice()
			if ok == true then
				params.recalcul = true;
				dlgBackOffice:EndModal(idButton.CANCEL);
			end
		 end,  btnSave);
	dlgBackOffice:Bind(eventType.MENU, 
		function(evt) 
			dlgBackOffice:EndModal(idButton.CANCEL);
		 end,  btnClose);
	dlgBackOffice:Fit();
	dlgBackOffice:ShowModal();
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
	for i = 1, #tTableComite do
		local row = tQuota_comite:AddRow();
		local comite = tTableComite[i].Comite;
		if comite == 'GI' and node_hommes:HasAttribute('GI') then
			comite = 'GIRSA';
		elseif comite == 'PY' and node_hommes:HasAttribute('PY') then
			comite = 'PE/PO';
		end
		tQuota_comite:SetCell('Comite', row, comite);
		tQuota_comite:SetCell('Quota_base', row, tTableComite[i].Quota_base);
		tQuota_comite:SetCell('Quota_base2', row, tTableComite[i].Quota_base2);
		tQuota_comite:SetCell('Participation', row, tTableComite[i].Participation);
		tQuota_comite:SetCell('Quota_calcule', row, tTableComite[i].Quota_calcule);
		tQuota_comite:SetCell('Pourcent', row, tTableComite[i].Pourcent);
		tQuota_comite:SetCell('Status', row, tTableComite[i].Status);
	end
	ligne_titre = tEvenement:GetCell('Nom', 0)..'\nCourse '..params.code_regroupement..' - Calculs des Quotas\nle '..tEpreuve:GetCell('Date_epreuve', 0)..' à '..tEvenement:GetCell('Station', 0);
	report = wnd.LoadTemplateReportXML({
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'print',
		paper_orientation = 'portrait',
		body = tQuota_comite,
		params = {Titre = ligne_titre, Inscrits = tRanking:GetNbRows(), Etrangers = params.nb_etrangers, Francais = params.nb_francais, 
		Francais_maxi = params.nb_francais_maxi, Place_CR140 = params.place_comite_organisateur140, Place_CR = params.place_comite_organisateur,
		Place_Club140 = params.place_club_organisateur140, Place_Club = params.place_club_organisateur,
		Place_WC140 = params.wild_card140, Place_WC = params.wild_card,
		Somme_base = params.somme_quota_base, Somme_base2 = params.somme_quota_base2,
		Total_Calcule = params.somme_quota_calcule, Nb_Equipe = params.nb_equipe,
		Total_General = params.total_general,
		RGB = params.RGB,
		Date = tEpreuve:GetCell('Date_epreuve', 0),
		Station = tEvenement:GetCell('Station', 0)}
		});
end

function AfficheCalculs()
	local signe = '';
	for i = 1, #tTableComite do
		-- tTableComite[i].Maxi_theorique = math.ceil(tTableComite[i].Maxi_theorique);
		if tTableComite[i].Participation == 0 then
			tTableComite[i].Quota_calcule = 0;
			tTableComite[i].Status = 0;
		elseif tTableComite[i].Participation == tTableComite[i].Quota_calcule then
			tTableComite[i].Status = 0;
		end
	end
	if not params.recalcul then
		dlgConfig = wnd.CreateDialog(
			{
			width = params.width,
			height = params.height,
			x = params.x,
			y = params.y,
			label='Calcul des quotas : '..script_version.. ' - par Philippe Guérindon' , 
			icon='./res/32x32_fis.png'
			});
		
		dlgConfig:LoadTemplateXML({ 
			xml = './process/quotaFIS.xml',
			node_name = 'root/panel', 
			node_attr = 'name', 
			discipline = params.discipline,
			node_value = 'config',
			tableau = tTableComite;
			lignes = #tTableComite,
			difference = difference,
			filter = params.filter,
			Date = tEpreuve:GetCell('Date_epreuve', 0),
			Station = tEvenement:GetCell('Station', 0),
			nb_etrangers = params.nb_etrangers,
			place_comite = params.place_comite_organisateur,
			place_club = params.place_club_organisateur,
			place_wild_card = params.wild_card,
			RGB = params.RGB
			});
	end

	-- adv.Alert('(params.place_comite_organisateur = '..params.place_comite_organisateur);
	dlgConfig:GetWindowName('race_name'):SetValue(tEvenement:GetCell('Nom', 0)..'\nCourse '..tEpreuve:GetCell('Code_regroupement', 0));
	dlgConfig:GetWindowName('inscrits'):SetValue(tRanking:GetNbRows());
	dlgConfig:GetWindowName('etrangers'):SetValue(params.nb_etrangers);
	dlgConfig:GetWindowName('etrangers2'):SetValue(params.nb_etrangers);
	dlgConfig:GetWindowName('francais'):SetValue(params.nb_francais);
	dlgConfig:GetWindowName('nb_francais_maxi'):SetValue(params.nb_francais_maxi);
	dlgConfig:GetWindowName('cr_orga'):SetValue(params.place_comite_organisateur);
	dlgConfig:GetWindowName('club_orga'):SetValue(params.place_club_organisateur);
	dlgConfig:GetWindowName('wild_cards'):SetValue(params.wild_card);
	
	local somme_maxi_theorique = 0;
	params.somme_quota_calcule = 0;
	params.somme_participation = 0;
	local somme_quota_base = 0;
	local somme_quota_base2 = 0;
	for i = 1, #tTableComite do
		if tTableComite[i].Quota_base > 0 then
			local comite = tTableComite[i].Comite;
			if comite == 'GI' then
				comite = 'GIRSA';
			elseif comite == 'PY' then
				comite = 'PE/PO';
			end
			params.somme_quota_calcule = params.somme_quota_calcule + tTableComite[i].Quota_calcule;
			params.somme_participation = params.somme_participation + tTableComite[i].Participation;
			
			dlgConfig:GetWindowName('comite'..i):SetValue(comite);
			dlgConfig:GetWindowName('quota_base'..i):SetValue(tTableComite[i].Quota_base..'%');
			somme_quota_base = somme_quota_base + tTableComite[i].Quota_base;

			dlgConfig:GetWindowName('quota_base2'..i):SetValue(Round(tTableComite[i].Quota_base2, 2)..'%');
			somme_quota_base2 = somme_quota_base2 + tTableComite[i].Quota_base2;
			-- dlgConfig:GetWindowName('quota_base2'..i):SetValue(tTableComite[i].Place_theorique2);
			dlgConfig:GetWindowName('participation'..i):SetValue(tTableComite[i].Participation);
			dlgConfig:GetWindowName('quota_calcule'..i):SetValue(tTableComite[i].Quota_calcule);
			dlgConfig:GetWindowName('pourcent'..i):SetValue(tTableComite[i].Pourcent..'%');
		end
	end
	-- adv.Alert('AfficheCalculs , somme_participation = '..params.somme_participation..', somme_maxi_theorique = '..somme_maxi_theorique..' sommme_quota_calcule = '..sommme_quota_calcule);
	dlgConfig:GetWindowName('somme_quota_base'):SetValue(somme_quota_base..'%');
	dlgConfig:GetWindowName('somme_quota_base2'):SetValue(somme_quota_base2..'%');

	dlgConfig:GetWindowName('somme_participation'):SetValue(params.somme_participation);
	dlgConfig:GetWindowName('somme_quota_calcule'):SetValue(params.somme_quota_calcule);
	dlgConfig:GetWindowName('equipe'):SetValue(params.nb_equipe);
	params.total_general = params.somme_quota_calcule + params.nb_etrangers + params.place_comite_organisateur + params.place_club_organisateur + params.wild_card + params.nb_equipe ;
	dlgConfig:GetWindowName('total'):SetValue(params.total_general);
	
	local difference = 0;
		difference = params.total_general - 140;
	if difference > 0 then
		signe = '+';
	end 
	dlgConfig:GetWindowName('difference'):SetValue(signe..difference);

	-- Toolbar Principale ...
	if not params.recalcul then
		local tbconfig = dlgConfig:GetWindowName('tbconfig');
		tbconfig:AddStretchableSpace();
		local btnPrint = tbconfig:AddTool("Imprimer le résultat", "./res/32x32_printer.png");
		tbconfig:AddSeparator();
		local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
		tbconfig:AddSeparator();
		
		btnBackOffice = tbconfig:AddTool("Back Office", "./res/32x32_configuration.png");
		tbconfig:AddStretchableSpace();

		tbconfig:Realize();

		dlgConfig:Bind(eventType.MENU, 
			function(evt) 
				OnPrintCalculs();
				dlgConfig:EndModal(idButton.OK);
			end, btnPrint); 
		wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
		dlgConfig:Bind(eventType.MENU, 
			function(evt) 
				OnAfficheBackOffice();
				if params.recalcul then
					GetSetData();
					AfficheCalculs();
				end
			 end,  btnBackOffice);

		dlgConfig:Bind(eventType.MENU, 
			function(evt) 
				OnClose();
				dlgConfig:EndModal(idButton.CANCEL) 
			 end,  btnClose);
		dlgConfig:Fit();
		dlgConfig:ShowModal()
	end
end

function LectureNodeHommes(node)
	
	-- if node == nil then
		-- return
	-- end
	-- child = xmlNode.GetChildren(node);
	-- while child ~= nil do
		-- if node:HasAttribute("FIS") then 		-- on est sur un node = comite
			-- local comite = node:GetName();
			-- params.comite[comite] = params.comite[comite] or {};
			-- local attribute = node:GetAttributes();
			-- while attribute ~= nil do
				-- local name = attribute:GetName();
				-- local value = attribute:GetValue();
				-- params.comite[comite]
				-- attribute = attribute:GetNext();
			-- end

			-- table.insert(matrice.layers, node:GetAttribute("id"));
		-- end
		-- LectureNodeHommes(child);
	-- end
	-- LectureNodeHommes(node:GetNext())
end

function GetQuotaComites(node_hommes)
	local attribute = node_hommes:GetAttributes();
	while attribute ~= nil do
		local name = attribute:GetName();
		local value = attribute:GetValue();
		if name ~= 'filter' then
			value = tonumber(value) or 0;
		end
		if name == 'COMITE' then
			params.place_comite_organisateur = value;
		elseif name == 'CLUB' then
			params.place_club_organisateur = value;
		elseif name == 'WILDCARD' then
			params.wild_card = value;
		elseif name == 'ORIGINE' then
			params.equipe_Comite_origine = value
		elseif name == 'filter' then
			params.filter = value
		end
		tquotaComite[name] = value;
		attribute = attribute:GetNext();
		-- adv.Alert(name..' - '..value);
	end
	params.filter = params.filter or '';
	-- les valeurs ci-dessous sont indiquées pour 140 français sans étrangers.
	params.place_club_organisateur = params.place_club_organisateur or 0;
	params.wild_card = params.wild_card or 0;
	params.equipe_Comite_origine = params.equipe_Comite_origine or 0;
end

function CalculeQuota(a_repartir)
	local difference = 0;
	-- adv.Alert('CalculeQuota, a_repartir = '..a_repartir)
	-- params.a_repartir = nombre de places allouées à la répartition dans les comités déduction faite des places réservées
	-- on ne tient compte que des comités ayant des inscrits
	-- pour un comité, on a un quota de base en %tage ex : 18.41 

	params.somme_places_rendues = 0;
	params.somme_quota_calcules = 0;
	local somme_repartie = 0;
	local somme_equipe = 0;
	local somme_restant_a_repartir = 0;

	params.somme_quota_base = 0;
	local somme_maxi_theorique = 0;
	for index = 1, #tTableComite do
		local comite = tTableComite[index].Comite;
		tTableComite[index].Quota_base = tquotaComite[comite];
		if not tquotaComite[comite] then
			tquotaComite[comite] = 0;
			tTableComite[index].Status = -1;
		end
		if tRanking:GetCounterValue('Comite', comite) then
			tTableComite[index].Participation = tRanking:GetCounterValue('Comite', tTableComite[index].Comite);
		else
			tTableComite[index].Participation = -1;
		end
	end
	tComites = {};
	local index2 = 0;
	params.somme_quota_base = 0
	for index = 1, #tTableComite do
		if  tTableComite[index].Participation > 0 then
			index2 = index2 + 1;
			tComites[index2] = tTableComite[index];
			-- adv.Alert('passage 2'..tComites[index2].Comite..', Quota_base = '..tComites[index2].Quota_base..', Participation = '..tComites[index2].Participation);
			params.somme_quota_base = params.somme_quota_base + tComites[index2].Quota_base;
		end
	end
	somme_maxi_theorique = 0;
	params.somme_quota_calcules = 0;
	local somme_maxi_theorique = 0;
	local somme_pour_redistribution = 0;
	params.somme_quota_base2 = 0;
	for index = 1, #tComites do
		local comite = tComites[index].Comite;
		tComites[index].Quota_base2 = tComites[index].Quota_base * 100 / params.somme_quota_base;
		params.somme_quota_base2 = params.somme_quota_base2 + tComites[index].Quota_base2;
		-- adv.Alert(comite..', Quota_base2 = '..tComites[index].Quota_base2..', params.somme_quota_base2 = '..params.somme_quota_base2);
		tComites[index].Maxi_theorique = a_repartir * tComites[index].Quota_base2 / 100;
		somme_maxi_theorique = somme_maxi_theorique + tComites[index].Maxi_theorique ;
		-- adv.Alert(comite..', Maxi_theorique = '..tComites[index].Maxi_theorique..', somme_maxi_theorique = '..somme_maxi_theorique);
		if tComites[index].Participation >= tComites[index].Maxi_theorique then
			tComites[index].Quota_calcule = tComites[index].Maxi_theorique;
			params.somme_quota_calcules = params.somme_quota_calcules + tComites[index].Quota_calcule;
			-- adv.Alert(comite..', Maxi_theorique = '..tComites[index].Maxi_theorique..', Quota_calcule = '..tComites[index].Quota_calcule..', params.somme_quota_calcules = '..params.somme_quota_calcules);
			somme_pour_redistribution = somme_pour_redistribution + tComites[index].Maxi_theorique;
		else
			tComites[index].Quota_calcule = tComites[index].Participation;
			params.somme_quota_calcules = params.somme_quota_calcules + tComites[index].Quota_calcule;
			tComites[index].Place_gagnee = -1;
			tComites[index].Place_Rendue = tComites[index].Maxi_theorique - tComites[index].Participation;
			-- adv.Alert(comite..', -  Maxi_theorique = '..tComites[index].Maxi_theorique..', Quota_calcule = '..tComites[index].Quota_calcule..', params.somme_quota_calcules = '..params.somme_quota_calcules);
			-- adv.Alert("l'"..comite..' rend '..tComites[index].Place_Rendue..' places');
			params.somme_places_rendues = params.somme_places_rendues + tComites[index].Place_Rendue;
			tComites[index].Status = 0;
		end	

		-- adv.Alert(comite..' - Participation = '..tComites[index].Participation..', Maxi_theorique = '..tComites[index].Maxi_theorique..', Quota_calcule = '..tComites[index].Quota_calcule);
	end
	-- adv.Alert('\nsomme_pour_redistribution = '..somme_pour_redistribution);
	-- on recalcule la représentation des comités devant decevoir les places rendues et on met le résultat dans Representation
	for index = 1, #tComites do
		local comite = tComites[index].Comite;
		if tComites[index].Place_gagnee == 0 then
			tComites[index].Representation = (tComites[index].Maxi_theorique / somme_pour_redistribution) * 100;
		end
	end
	somme_restant_a_repartir = a_repartir - params.somme_places_rendues;
	-- adv.Alert('\nQuotas déjà attribués = '..params.somme_quota_calcules..', somme_restant_a_repartir = '..somme_restant_a_repartir..', params.somme_places_rendues = '..params.somme_places_rendues.. ', total = '..(somme_restant_a_repartir + params.somme_places_rendues));
	-- tComites[index].Quota_base2  = pourcentage de représentativité d'un comité parmi ceux qui ont des participants. C'est un pourcantage sur 100
	-- tComites[index].Maxi_theorique  = nombre de place (décimale) qu'un comité peut recevoir. Leur addition donne le nombre e place à répartir
	-- on aura attribué les Quota_calcule selon : 
	--		un comité ayant une participation >= Quota_base2  --> Maxi_theorique. Place_gagnee = 0;
	--		un comité ayant une participation <  Quota_base2  -->Participation
	--				dans ce cas, Place_Rendue = Maxi_theorique - Participation. Place rendue = valeur décimale
	--				dans ce cas, Place_gagnee = -1
	-- les comités ayant Place_gagnee = 0 doivent recevoir une fraction des places rendues selon leur pourcentage de représentativité.
--	table.insert(tTableComite, {Comite = 'AP', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	local calcul = 0;
	for index = 1, #tComites do
		local comite = tComites[index].Comite;
		if tComites[index].Place_gagnee == 0 then
			local gagne = (params.somme_places_rendues * tComites[index].Representation) / 100;
			-- adv.Alert('\ntQuota_calcule initial = '..tComites[index].Quota_calcule..', gagne = '..gagne);
			tComites[index].Quota_calcule = tComites[index].Quota_calcule + gagne;
			tComites[index].Quota_calcule = Round(tComites[index].Quota_calcule, 0);
			tComites[index].Pourcent = Round(tComites[index].Quota_calcule * 100 / tComites[index].Quota_base, 2);
			local calcul = calcul + tComites[index].Quota_calcule ;
		end
	end
	local idx_depart = 1;
	for i = 1, #tTableComite do
		for index = idx_depart, #tComites do
			if tTableComite[i].Comite == tComites[index].Comite then
				tTableComite[i] = tComites[index];
				idx_depart = idx_depart + 1;
				break;
			end
		end
	end
	calcul = 0;
	for index = 1, #tTableComite do
		tTableComite[index].Quota_calcule = Round(tTableComite[index].Quota_calcule, 0);
		calcul = calcul + tTableComite[index].Quota_calcule
		-- adv.Alert('passage 3 '..tTableComite[index].Comite..', Quota_calcule = '..tTableComite[index].Quota_calcule..', somme Quota_calcule = '..calcul);
	end
	for index = 1, #tTableComite do
		tTableComite[index].Quota_base2 = tTableComite[index].Quota_calcule * 100 / params.a_repartir;
		-- adv.Alert('passage 3 '..tTableComite[index].Comite..', Quota_calcule = '..tTableComite[index].Quota_calcule..', somme Quota_calcule = '..calcul);
	end
	-- adv.Alert('\n fin de CalculeQuota, sonme des quotas calculés = '..calcul..', a_repartir = '..params.a_repartir);
	difference = calcul - params.a_repartir;
	-- adv.Alert('difference = '..difference..'\n-');
	return difference;
end

function NettoietTableComite(index)
-- table.insert(tTableComite, {Comite = 'MJ', Quota_base = 0, Quota_base2 = 0, 
-- Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, 
-- Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, 
-- Pourcent = 0, Status = 1});
	tTableComite[index].Quota_base2 = 0;
	tTableComite[index].Representation = 0;
	tTableComite[index].Place_gagnee = 0;
	tTableComite[index].Place_theorique2 = 0;
	tTableComite[index].Quota_calcule = 0;
	tTableComite[index].Place_Rendue = 0;
	tTableComite[index].Pourcent = 0;
	tTableComite[index].Status = 1;
end

function GetSetData()
	-- params.somme_quota_base = 0;
	params.a_repartir =  params.nb_francais_maxi - (params.place_comite_organisateur + params.place_club_organisateur + params.wild_card  + params.nb_equipe);
	-- adv.Alert('GetSetData à répartir = '..params.a_repartir);
	local nb_iteration = 1;
	local difference = 0;
	local a_repartir = params.a_repartir;
	while true do
		difference = CalculeQuota(a_repartir);
		if math.abs(difference) > 2 then
			break;
		end
		-- adv.Alert('\ndans la boucle while, nb_iteration = '..nb_iteration..', différence = '..difference);
		if nb_iteration == 10 then
			return false;
		end
		if difference == 0 then
			return true;
		end
		for index = 1, #tTableComite do
			NettoietTableComite(index);
		end
		nb_iteration = nb_iteration + 1;
		if difference > 0 then
			a_repartir = a_repartir - 0.2;
		else
			a_repartir = a_repartir + 0.2;
		end
	end
end

function SettTableComite();
	params.nb_equipe = 0;
	-- adv.Alert('SettTableComite - type(params.equipe_Comite_origine) = '..type(params.equipe_Comite_origine)..', params.equipe_Comite_origine = '..params.equipe_Comite_origine);
	for i = 0, tRanking:GetNbRows() -1 do
		local comite = tRanking:GetCell('Comite', i);
		if comite == 'EQ' then
			if params.equipe_Comite_origine > 0 then
				comite = GetComiteOrigine(tRanking:GetCell('Code_coureur', i));
				tRanking:SetCell('Comite', i, comite);
			else
				params.nb_equipe = params.nb_equipe + 1;
			end
		end
		if comite:In('BO','FZ','CE','LY','OU') and node_hommes:HasAttribute('GI') then
			comite = 'GI';
			tRanking:SetCell('Comite', i, comite);
		end
		if comite:In('PE','PO','CE','LY','OU') and node_hommes:HasAttribute('PY') then
			comite = 'PY';
			tRanking:SetCell('Comite', i, comite);
		end
	end
	tRanking:SetCounter('Comite');
	tRanking:SetCounter('Nation');
	params.nb_francais = tRanking:GetCounterValue('Nation', 'FRA');
	params.nb_etrangers = tRanking:GetNbRows() - params.nb_francais;
	params.nb_francais_maxi = 140 - params.nb_etrangers;
	-- tRanking:Snapshot('tRanking.db3');
	tTableComite = {};
	table.insert(tTableComite, {Comite = 'AP', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'AU', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'CA', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'CO', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'DA', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'IF', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'MB', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'MJ', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'MV', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'SA', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	if node_hommes:HasAttribute('PY') then
		table.insert(tTableComite, {Comite = 'PY', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	else
		table.insert(tTableComite, {Comite = 'PO', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
		table.insert(tTableComite, {Comite = 'PE', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	end
	if node_hommes:HasAttribute('GI') then
		table.insert(tTableComite, {Comite = 'GI', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	else
		if comite:In('BO','FZ','CE','LY','OU') then
			table.insert(tTableComite, {Comite = 'BO', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
			table.insert(tTableComite, {Comite = 'FZ', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
			table.insert(tTableComite, {Comite = 'CE', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
			table.insert(tTableComite, {Comite = 'LY', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
			table.insert(tTableComite, {Comite = 'OU', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = 0, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	
		end
	end
	GetSetData();
	AfficheCalculs();
end

function main(params_c)
	params = params_c;
	params.RGB = {};
	params.RGB[1] = 'rgb 200 255 200';
	params.RGB[2] = {};
	params.RGB[2][1] = 'rgb 255 192 0';
	params.RGB[2][2] = 'rgb 255 0 0';
	if not params.code_evenement then	
		return;
	end
	params.width = display:GetSize().width;
	params.height = display:GetSize().height - 50;
	params.x = 0;
	params.y = 0;
	params.recalcul = false;
	script_version = "1.2"; -- 4.92 pour 2022-2023
	local msg = '';
	if app.GetVersion() >= '5.0' then 
		-- vérification de l'existence d'une version plus récente du script.
		-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2
		indice_return = 11;
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
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	if tEvenement:GetCell('Code_entite', 0) ~= 'FIS' then
		return;
	end
	params.comite_organisateur = tEvenement:GetCell('Code_comite', 0);
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	params.code_regroupement = tEpreuve:GetCell('Code_regroupement', 0);
	if params.code_regroupement == 'CITWC' then
		params.code_regroupement = 'CIT';
	end
	if tEvenement:GetCell('Codex', 0):len() > 0 then
		if string.sub(tEvenement:GetCell('Codex', 0), 1, 3) ~= 'FRA' then
			params.code_regroupement = '';
		end
	end
	-- Ouverture Document XML 
	xml_config_quota = app.GetPath()..'/quotaFIS_config.xml';
	if not app.FileExists(xml_config_quota) then
		msg = "Vous n'êtes pas habilité à gérer les quotas FIS";
		app.GetAuiFrame():MessageBox(msg, "Droits insuffisants", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		return;
	end
	doc_config = xmlDocument.Create(xml_config_quota);
	root = doc_config:GetRoot();
	node_hommes = doc_config:FindFirst('root/hommes/'..string.sub(params.code_regroupement, 1, 3));
	if not node_hommes then
		msg = msg.."La gestion de quotas n'est pas prévue\npour le code regroupement "..params.code_regroupement;
		app.GetAuiFrame():MessageBox(msg, "Quotas non gérés", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		return;
	end
	params.filter = '';
	tquotaComite = {};

	GetQuotaComites(node_hommes);
	tRanking = base.CreateTableRanking({ code_evenement = params.code_evenement});
	-- tRanking:Snapshot('tRanking.db3');
	local msg = "Voulez vous conserver le filtre enregistré précédemment = Oui ?\nVoulez-vous enregistrer un nouveau filtre = Non ?\nVoulez-vous supprimer l'ancien filtre : Annuler ?";
	local key = app.GetAuiFrame():MessageBox(msg, "Filtrage des concurrents", msgBoxStyle.YES + msgBoxStyle.NO + msgBoxStyle.CANCEL + msgBoxStyle.YES_DEFAULT + msgBoxStyle.ICON_WARNING);
	if key == msgBoxStyle.YES then
		if params.filter:len() > 0 then
			tRanking:Filter(params.filter, true);
		end
	elseif key == msgBoxStyle.NO then
		filterCmd = wnd.FilterConcurrentDialog({ 
			sqlTable = tRanking,
			key = 'cmd'});
		if type(filterCmd) == 'string' and filterCmd:len() > 0 then
			params.filter = filterCmd;
			if node_hommes:HasAttribute('filter') then
				node_hommes:ChangeAttribute('filter', filterCmd);
			else
				node_hommes:AddAttribute('filter', filterCmd);
			end
			doc_config:SaveFile();
			tRanking:Filter(filterCmd, true);
		end
	elseif key == msgBoxStyle.YES then
			tRanking:Filter(params.filter, true);
	else
		if node_hommes:HasAttribute('filter') then
			node_hommes:DeleteAttribute('filter');
		end
	end
	SettTableComite();
end
