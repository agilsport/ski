-- LIVE Draw par Philippe Guérindon

dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function OnClose()
	params.exit = true;
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
	params.place_comite_organisateur = tonumber(dlgBackOffice:GetWindowName('place_comite_organisateur'):GetValue()) or 0;
	params.place_club_organisateur = tonumber(dlgBackOffice:GetWindowName('place_club_organisateur'):GetValue()) or 0;
	params.wild_card = tonumber(dlgBackOffice:GetWindowName('wild_card'):GetValue()) or 0;
	params.comite_origine = dlgBackOffice:GetWindowName('comboComiteOrigine'):GetSelection();
	params.place_variable = dlgBackOffice:GetWindowName('comboVariable'):GetSelection();
	local place_comite_sav = params.place_comite_organisateur;
	local place_club_sav = params.place_club_organisateur;
	local wild_card_sav = params.wild_card;
	local place_variable_sav = params.place_variable;
	local comite_origine = params.equipe_Comite_origine;
	local total = 0;
	for i = 1, #tTableComite do
		local new_value = dlgBackOffice:GetWindowName('new_quota_base'..i):GetValue():sub(1,-1);
		new_value = tonumber(new_value) or 0;
		total = total + new_value;
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
			local new_value = tonumber(dlgBackOffice:GetWindowName('new_quota_base'..i):GetValue():sub(1,-1)) or 0;
			if tquotaComitex then
				node_hommesx:ChangeAttribute(comite, new_value);
				node_hommesx:ChangeAttribute(comite, new_value)
			else
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
				node_hommes:ChangeAttribute(comite, new_value);
			end

		end
		local place_comite_organisateur = tonumber(dlgBackOffice:GetWindowName('place_comite_organisateur'):GetValue()) or 0;
		local place_club_organisateur = tonumber(dlgBackOffice:GetWindowName('place_club_organisateur'):GetValue()) or 0;
		local wild_card = tonumber(dlgBackOffice:GetWindowName('wild_card'):GetValue()) or 0;
		local comite_origine = dlgBackOffice:GetWindowName('comboComiteOrigine'):GetSelection();
		local place_variable = dlgBackOffice:GetWindowName('comboVariable'):GetSelection();
		if tquotaComitex then
			-- adv.Alert('passage sav 1');
			-- node_hommesx:ChangeAttribute(comite, new_value);
			-- node_hommesx:ChangeAttribute(comite, new_value)
			node_hommesx:ChangeAttribute('COMITE', place_comite_organisateur);
			node_hommesx:ChangeAttribute('CLUB', place_club_organisateur);
			node_hommesx:ChangeAttribute('WILDCARD', wild_card);
			node_hommesx:ChangeAttribute('VARIABLE', place_variable);
			params.place_comite_organisateur = place_comite_sav;
			params.place_club_organisateur =place_club_sav;
			params.wild_card = wild_card_sav;
			params.equipe_Comite_origine = comite_origine;
			params.place_variable = place_variable;
			doc_config:SaveFile();
		else
			-- adv.Alert('passage sav 2');
			node.place_comite_organisateur = place_comite_organisateur;
			node_hommes:ChangeAttribute('COMITE', place_comite_organisateur);
			node.place_club_organisateur = place_club_organisateur;
			node_hommes:ChangeAttribute('CLUB', place_club_organisateur);
			node.wild_card = wild_card;
			params.place_variable = place_variable;
			node_hommes:ChangeAttribute('VARIABLE', params.place_variable);
			node_hommes:ChangeAttribute('WILDCARD', params.wild_card);
			params.equipe_Comite_origine = comite_origine;
			node_hommes:ChangeAttribute('ORIGINE', params.equipe_Comite_origine);
			local touche = app.GetAuiFrame():MessageBox(
				"Oui  = enregistrer ces valeurs de manière permnente ?\nNon = refaire le calcul sans enregistrer ces valeurs\nAnnuler = revenir aux anciennes valeurs.", 
				"Information !!!",
				msgBoxStyle.YES + msgBoxStyle.NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
				);
			if touche == msgBoxStyle.YES then
					doc_config:SaveFile();
			end
		end
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
	for i = 1, #tTableComite do
		local valeur = tonumber(dlgBackOffice:GetWindowName('new_quota_base'..i):GetValue()) or 0;
		total = total + valeur;
	end
	return total;
end



function CalculeQuotaCalculette(a_repartir)
	local difference = 0;

	params.place_comite_organisateur = 0;
	params.wild_card  = 0;
	params.somme_quota_base = 0;
	params.somme_quota_calcules = 0;
	params.somme_comite_coche = 0;
	for index = 1, #tTableComite do
		local comite = tTableComite[index].Comite;
		tTableComite[index].Quota_base = tquotaComite[comite];
		if not tquotaComite[comite] then
			tquotaComite[comite] = 0;
			tTableComite[index].Status = -1;
		end
		params.somme_quota_base = params.somme_quota_base + tTableComite[index].Quota_base;
		if dlgGetQuotaComites:GetWindowName('chk'..index):GetValue() == true then
			params.somme_comite_coche = params.somme_comite_coche + tTableComite[index].Quota_base;;
		else
			tTableComite[index].Quota_calcule = 0;
		end
	end
	local somme_maxi_theorique = 0;
	params.somme_quota_calcules = 0;
	local somme_pour_redistribution = 0;
	params.somme_quota_base2 = 0;
	for index = 1, #tTableComite do
		local comite = tTableComite[index].Comite;
		if dlgGetQuotaComites:GetWindowName('chk'..index):GetValue() == true then
			local coef = tTableComite[index].Quota_base * 100 / params.somme_comite_coche;
			tTableComite[index].Quota_calcule = Round(a_repartir * coef / 100, 2);
		else
			tTableComite[index].Quota_calcule = 0;
		end
	end
	local calcul = 0;
	calcul = 0;
	for index = 1, #tTableComite do
		local comite = tTableComite[index].Comite;
		tTableComite[index].Maxi_theorique = tTableComite[index].Quota_calcule;
		calcul = calcul + tTableComite[index].Maxi_theorique;
		tTableComite[index].Quota_calcule = 0;
		-- adv.Alert('passage 4 '..tTableComite[index].Comite..', Quota_calcule = '..tTableComite[index].Quota_calcule..', somme Quota_calcule = '..calcul);
	end
	for index = 1, #tTableComite do
		tTableComite[index].Quota_base2 = tTableComite[index].Maxi_theorique * 100 / params.a_repartir;
		-- adv.Alert('passage 5 '..tTableComite[index].Comite..', Quota_calcule = '..tTableComite[index].Quota_calcule..', somme Quota_calcule = '..calcul);
	end
	-- adv.Alert('\n fin de CalculeQuota, sonme des quotas calculés = '..calcul..', a_repartir = '..params.a_repartir);
	difference = calcul - a_repartir;
	-- adv.Alert('difference = '..difference..'\n-');
	return difference;
end


function OnAfficheBackOffice()
	function RazDisplay()
		for i = 0, 20 do
			if dlgBackOffice:GetWindowName('chk'..i) then
				dlgGetQuotaComites:GetWindowName('chk'..i):SetValue(false);
				dlgGetQuotaComites:GetWindowName('chk'..i):SetLabel('');
				dlgGetQuotaComites:GetWindowName('quota_base'..i):SetValue('');
				dlgGetQuotaComites:GetWindowName('quota_effectif'..i):SetValue('');
			end
		end
	end
	function  DisplayData()
		local total_base = 0;
		for i = 1, #tTableComite do
			local display_ligne = true;
			local comite = tTableComite[i].Comite;
			local comite_display = comite;
			if comite == 'GI' then
				comite_display = 'GIRSA';
			elseif comite == 'PY' then
				comite_display = 'PE/PO';
			end
			if tquotaComitex then
				if tquotaComitex['PY'] then
					if comite == 'PO' then
						display_ligne = false;
					elseif comite == 'PE' then
						comite_display = 'PE/PO';
						comite = 'PY';
					end
				end
			end
			if display_ligne == true then
				dlgBackOffice:GetWindowName('comite'..i):SetValue(comite_display);
				if params.code_regroupement == params.code_regroupementx then
					dlgBackOffice:GetWindowName('old_quota_base'..i):SetValue(tTableComite[i].Quota_base);
					dlgBackOffice:GetWindowName('new_quota_base'..i):SetValue(tTableComite[i].Quota_base);
					total_base = total_base + tTableComite[i].Quota_base;
				else
					dlgBackOffice:GetWindowName('old_quota_base'..i):SetValue(tquotaComitex[comite]);
					dlgBackOffice:GetWindowName('new_quota_base'..i):SetValue(tquotaComitex[comite]);
					total_base = total_base + tquotaComitex[comite];
				end
			else
				dlgBackOffice:GetWindowName('comite'..i):SetValue('');
				dlgBackOffice:GetWindowName('old_quota_base'..i):SetValue('');
				dlgBackOffice:GetWindowName('new_quota_base'..i):SetValue('');
			end
		end	
		dlgBackOffice:GetWindowName('total_base'):SetValue(total_base..'%');
		dlgBackOffice:GetWindowName('total_base2'):SetValue(total_base..'%');
		dlgBackOffice:GetWindowName('comboComiteOrigine'):Clear();
		dlgBackOffice:GetWindowName('comboComiteOrigine'):Append('Non');
		dlgBackOffice:GetWindowName('comboComiteOrigine'):Append('Oui');
		
		dlgBackOffice:GetWindowName('comboVariable'):Clear();
		dlgBackOffice:GetWindowName('comboVariable'):Append('Non');
		dlgBackOffice:GetWindowName('comboVariable'):Append('Oui');
		
		if params.code_regroupement == params.code_regroupementx then
			dlgBackOffice:GetWindowName('place_comite_organisateur'):SetValue(node.place_comite_organisateur);
			dlgBackOffice:GetWindowName('place_club_organisateur'):SetValue(node.place_club_organisateur);
			dlgBackOffice:GetWindowName('wild_card'):SetValue(node.wild_card);
			dlgBackOffice:GetWindowName('comboComiteOrigine'):SetSelection(params.equipe_Comite_origine);
			dlgBackOffice:GetWindowName('comboVariable'):SetSelection(params.place_variable);
		elseif tquotaComitex then
			dlgBackOffice:GetWindowName('place_comite_organisateur'):SetValue(params.place_comite_organisateurx);
			dlgBackOffice:GetWindowName('place_club_organisateur'):SetValue(params.place_club_organisateurx);
			dlgBackOffice:GetWindowName('wild_card'):SetValue(params.wild_cardx);
			dlgBackOffice:GetWindowName('comboComiteOrigine'):SetSelection(params.equipe_Comite_originex);
			dlgBackOffice:GetWindowName('comboVariable'):SetSelection(params.place_variablex);
		end
	end
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
		-- proportionnelle = params.place_variable,
		wild_card = params.wild_card,
		node_value = 'backoffice'
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
	if params.code_regroupementx then
		dlgBackOffice:GetWindowName('combo_regroupement'):SetValue(params.code_regroupementx);
	end
	--if params.code_regroupementx == params.code_regroupement then
		DisplayData();
	--end
	
	dlgBackOffice:Bind(eventType.COMBOBOX, 
		function(evt)
			params.code_regroupementx = dlgBackOffice:GetWindowName('combo_regroupement'):GetValue();
			-- if params.code_regroupementx ~= params.code_regroupement then
				-- node_hommesx = doc_config:FindFirst('root/hommes/'..params.code_regroupementx);
				-- LectureNodeHommes(node_hommesx);
			-- else
				-- tquotaComitex = nil;
			-- end
			tquotaComitex = nil;
			node_hommesx = doc_config:FindFirst('root/hommes/'..params.code_regroupementx);
			LectureNodeHommes(node_hommesx);
			DisplayData();
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
			OnSaveBackOffice()
			dlgBackOffice:EndModal(idButton.CANCEL);
		 end,  btnSave);
	dlgBackOffice:Bind(eventType.MENU, 
		function(evt) 
			dlgBackOffice:EndModal(idButton.CANCEL);
		 end,  btnClose);
	dlgBackOffice:Fit();
	dlgBackOffice:ShowModal();
end

function AfficheNodeData()
	local total_base = 0;
	for i = 1, #tTableComite do
		local comite = tTableComite[i].Comite;
		tDisplayComite[comite] = tDisplayComite[comite] or {};
		tTableComite[i].Quota_base = tonumber(tquotaComite[comite]) or 0;
		tDisplayComite[comite].Quota_base = tTableComite[i].Quota_base;
		
		if comite == 'GI' then
			comite = 'GIRSA';
		elseif comite == 'PY' then
			comite = 'PE/PO';
		end
		dlgGetQuotaComites:GetWindowName('chk'..i):SetLabel(comite);
		dlgGetQuotaComites:GetWindowName('quota_base'..i):SetValue(tTableComite[i].Quota_base);
		total_base = total_base + tTableComite[i].Quota_base;
	end	
	dlgGetQuotaComites:GetWindowName('total_base'):SetValue(total_base..'%');
end
function OnDisplayTotalDemande()
	params.somme_places_demandees = 0;
	for index = 1, #tTableComite do
		local place_demandee = tonumber(dlgGetQuotaComites:GetWindowName('places_demandees'..index):GetValue()) or 0
		params.somme_places_demandees = params.somme_places_demandees + place_demandee;
	end
	dlgGetQuotaComites:GetWindowName('total_places_demandees'):SetValue(params.somme_places_demandees);
end

function OnDisplayTotalObtenu()
	params.somme_places_obtenues = 0;
	local difference = 0;
	for index = 1, #tTableComite do
		local place_obtenue = tonumber(dlgGetQuotaComites:GetWindowName('places_obtenues'..index):GetValue()) or 0;
		params.somme_places_obtenues = params.somme_places_obtenues + place_obtenue;
	end
	if estNumerique(params.a_repartir) and estNumerique(params.somme_places_obtenues) then
		if params.a_repartir > 0 and params.somme_places_obtenues > 0 then
			difference = params.a_repartir - params.somme_places_obtenues;
			dlgGetQuotaComites:GetWindowName('difference'):SetValue(difference);
		end
	end
	dlgGetQuotaComites:GetWindowName('total_places_obtenues'):SetValue(params.somme_places_obtenues);
end

function RAZdata()
	-- RazDisplayGetParticipationComites();
	for index = 1, 20 do
		if tTableComite[index] then
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
		else
			break;
		end
		if dlgGetQuotaComites:GetWindowName('quota_base'..index) then
			dlgGetQuotaComites:GetWindowName('quota_base'..index):SetValue('');
			dlgGetQuotaComites:GetWindowName('quota_maximum'..index):SetValue('');
			dlgGetQuotaComites:GetWindowName('places_demandees'..index):SetValue('');
			dlgGetQuotaComites:GetWindowName('places_obtenues'..index):SetValue('');
			dlgGetQuotaComites:GetWindowName('chk'..index):SetLabel('');
			dlgGetQuotaComites:GetWindowName('chk'..index):SetValue(false);
		else
			break;
		end
	end
	dlgGetQuotaComites:GetWindowName('total_base2'):SetValue('');
	dlgGetQuotaComites:GetWindowName('total_places_demandees'):SetValue('');
	dlgGetQuotaComites:GetWindowName('total_places_obtenues'):SetValue('');
	AfficheNodeData();
	params.place_comite_organisateur = 0;
	params.place_club_organisateur = 0
	params.wild_card = 0;
	params.a_repartir = tonumber(dlgGetQuotaComites:GetWindowName('a_repartir'):GetValue()) or 0;
	params.nb_equipe = tonumber(dlgGetQuotaComites:GetWindowName('places_ffs'):GetValue()) or 0;
end
function  DisplayDataCalculette()
	params.somme_quota_base = 0;
	params.somme_maxi_theorique = 0;
	params.somme_places_obtenues = 0;
	params.somme_demandees = 0;
	for i = 1, #tTableComite do
		local display_ligne = true;
		local comite = tTableComite[i].Comite;
		local comite_display = comite;
		if comite == 'GI' then
			comite_display = 'GIRSA';
		elseif comite == 'PY' then
			comite_display = 'PE/PO';
		end
		if tquotaComite then
			if tquotaComite['PY'] then
				if comite == 'PO' then
					display_ligne = false;
				elseif comite == 'PE' then
					comite_display = 'PE/PO';
					comite = 'PY';
				end
			end
		end
		if tquotaComite[comite] then
			tTableComite[i].Quota_base = tquotaComite[comite];
		end
		dlgGetQuotaComites:GetWindowName('chk'..i):SetLabel(tostring(comite_display));
		dlgGetQuotaComites:GetWindowName('quota_base'..i):SetValue(tTableComite[i].Quota_base);
		if dlgGetQuotaComites:GetWindowName('chk'..i):GetValue() == true then
			dlgGetQuotaComites:GetWindowName('quota_maximum'..i):SetValue(Round(tTableComite[i].Maxi_theorique,2));
			dlgGetQuotaComites:GetWindowName('places_obtenues'..i):SetValue(tTableComite[i].Quota_calcule);
		end
	end	
	local somme_maxi_theorique = 0;
	local somme_places_obtenues = 0;
	local somme_places_demandees = 0;
	local somme_quota_base = 0;
	local somme_quota_maxi = 0;
	for i = 1, #tTableComite do
		local quota_base = tonumber(dlgGetQuotaComites:GetWindowName('quota_base'..i):GetValue()) or 0;
		somme_quota_base = somme_quota_base + quota_base;
		if dlgGetQuotaComites:GetWindowName('chk'..i):GetValue() == true then
			local quota_maxi = tonumber(dlgGetQuotaComites:GetWindowName('quota_maximum'..i):GetValue()) or 0
			local place_demandee = tonumber(dlgGetQuotaComites:GetWindowName('places_demandees'..i):GetValue()) or 0
			local place_obtenue = tonumber(dlgGetQuotaComites:GetWindowName('places_obtenues'..i):GetValue()) or 0
			somme_quota_maxi = somme_quota_maxi + quota_maxi;
			somme_places_demandees = somme_places_demandees + place_demandee;
			somme_places_obtenues = somme_places_obtenues + place_obtenue;
		end
	end	
	-- params.a_repartir = tonumber(dlgGetQuotaComites:GetWindowName('a_repartir'):GetValue()) or 0;
	-- params.nb_equipe = tonumber(dlgGetQuotaComites:GetWindowName('places_ffs'):GetValue()) or 0;
	dlgGetQuotaComites:GetWindowName('total_base'):SetValue(somme_quota_base);
	dlgGetQuotaComites:GetWindowName('total_base2'):SetValue(Round(somme_quota_maxi, 2));
	dlgGetQuotaComites:GetWindowName('total_places_obtenues'):SetValue(somme_places_obtenues);
	dlgGetQuotaComites:GetWindowName('total_places_demandees'):SetValue(somme_places_demandees);
	if params.a_repartir > 0 and somme_places_obtenues > 0 then
		local difference = params.a_repartir - somme_places_obtenues;
		dlgGetQuotaComites:GetWindowName('difference'):SetValue(difference);
	end
end

function GetParticipationComites()
-- Création Dialog 
	params.label_dialog = 'Calculette de quota FIS (Philippe Guérindon)';
	dlgGetQuotaComites = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label=params.label_dialog, 
		icon='./res/32x32_fis.png'
		});
	
	dlgGetQuotaComites:LoadTemplateXML({ 
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 	
		tableau = tTableComite;
		lignes = #tTableComite,
		place_comite = params.place_comite_organisateur,
		regroupement = params.code_regroupement,
		-- place_club = params.place_club_organisateur,
		-- wild_card = params.wild_card,
		node_value = 'calculatrice'
	});
	
	dlgGetQuotaComites:GetWindowName('label_quota'):SetValue('Quota maximum');
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):Clear();
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):Append('FIS');
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):Append('NJR');
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):Append('CIT');
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):Append('UNI');
	dlgGetQuotaComites:GetWindowName('combo_regroupement'):SetSelection(0);
	tDisplayComite = {};
	AfficheNodeData();
	
	local tb = dlgGetQuotaComites:GetWindowName('tbbackoffice');
	tb:AddStretchableSpace();
	local btnSave = tb:AddTool("Calculer", "./res/32x32_save.png");
	tb:AddSeparator();
	local btnPrint = tb:AddTool("Imprimer", "./res/32x32_printer.png");
	tb:AddSeparator();
	local btnRAZ = tb:AddTool("Effacer", "./res/32x32_clear.png");
	tb:AddSeparator();
	local btnClose = tb:AddTool("Quitter", "./res/32x32_exit.png");

	tb:AddStretchableSpace();
	tb:Realize();
	
	params.nb_equipe = 0;
	params.place_comite_organisateur = 0;
	params.wild_card = 0;
	params.place_club_organisateur = 0;

	dlgGetQuotaComites:Bind(eventType.COMBOBOX, 
		function(evt)
			params.code_regroupement = dlgGetQuotaComites:GetWindowName('combo_regroupement'):GetValue();
			RAZdata();
			node_hommes = doc_config:FindFirst('root/hommes/'..dlgGetQuotaComites:GetWindowName('combo_regroupement'):GetValue());
			SettTableComite();
			LectureNodeHommes(node_hommes);
			GetQuotaComites(node_hommes);
			for index = 1, #tTableComite do
				local comite = tTableComite[index].Comite;
				tTableComite[index].Quota_base = tquotaComitex[comite];
				dlgGetQuotaComites:GetWindowName('quota_base'..index):SetValue(tquotaComitex[comite]);
				dlgGetQuotaComites:GetWindowName('quota_maximum'..index):SetValue('');
				dlgGetQuotaComites:GetWindowName('places_demandees'..index):SetValue('');
				dlgGetQuotaComites:GetWindowName('places_obtenues'..index):SetValue('');
				dlgGetQuotaComites:GetWindowName('chk'..index):SetValue(false);
			end
			AfficheNodeData();
			dlgGetQuotaComites:GetWindowName('total_base'):SetValue('');
			dlgGetQuotaComites:GetWindowName('total_base2'):SetValue('');
			dlgGetQuotaComites:GetWindowName('total_places_obtenues'):SetValue('');
			dlgGetQuotaComites:GetWindowName('total_places_demandees'):SetValue('');
		 end,
		 dlgGetQuotaComites:GetWindowName('combo_regroupement'));
	
	dlgGetQuotaComites:Bind(eventType.TEXT, 
		function(evt) 
			RAZdata();
			AfficheNodeData();
			params.a_repartir = tonumber(dlgGetQuotaComites:GetWindowName('a_repartir'):GetValue()) or 0;
		end,
		dlgGetQuotaComites:GetWindowName('a_repartir'));

	dlgGetQuotaComites:Bind(eventType.TEXT, 
		function(evt) 
			params.place_comite_organisateur = 0;
			params.wild_card = 0;
			params.place_club_organisateur = tonumber(dlgGetQuotaComites:GetWindowName('place_club'):GetValue()) or 0;
		end,
		dlgGetQuotaComites:GetWindowName('place_club'));

	dlgGetQuotaComites:Bind(eventType.TEXT, 
		function(evt) 
			params.place_comite_organisateur = 0;
			params.wild_card = 0;
			params.nb_equipe = tonumber(dlgGetQuotaComites:GetWindowName('places_ffs'):GetValue()) or 0;
		end,
		dlgGetQuotaComites:GetWindowName('place_ffs'));
	for i = 1, #tTableComite do
		dlgGetQuotaComites:Bind(eventType.CHECKBOX, 
			function(evt) 
				if dlgGetQuotaComites:GetWindowName('places_ffs'):GetValue():len() == 0 or dlgGetQuotaComites:GetWindowName('a_repartir'):GetValue():len() == 0 then
					dlgGetQuotaComites:GetWindowName('chk'..i):SetValue(false);
					local msg = "Vous devez d'abord définir les valeurs initiales\n(places à répartir et places réservées FFS)";
					app.GetAuiFrame():MessageBox(msg, "Saisir les valeurs initiales du calcul", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
					return;
				end
				if dlgGetQuotaComites:GetWindowName('chk'..i):GetValue() == false then
					dlgGetQuotaComites:GetWindowName('quota_maximum'..i):SetValue('');
					dlgGetQuotaComites:GetWindowName('places_demandees'..i):SetValue('');
					dlgGetQuotaComites:GetWindowName('places_obtenues'..i):SetValue('');
				end
				local comite = tTableComite[i].Comite;
				local total_a_repartir = tonumber(dlgGetQuotaComites:GetWindowName('a_repartir'):GetValue()) or 0;
				params.nb_equipe = tonumber(dlgGetQuotaComites:GetWindowName('places_ffs'):GetValue()) or 0;
				params.nb_places_a_repartir = total_a_repartir - params.nb_equipe;
				local nb_iteration = 1;
				local difference = 0;
				local a_repartir = params.nb_places_a_repartir;
				local nb_iteration = 1;
				local difference = 0;
				while true do
					difference = CalculeQuotaCalculette(a_repartir);
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
				DisplayDataCalculette();
			end,
			dlgGetQuotaComites:GetWindowName('chk'..i));
	end


	for i = 1, #tTableComite do
		dlgGetQuotaComites:Bind(eventType.TEXT, 
			function(evt) 
				OnDisplayTotalDemande()
			end,
			dlgGetQuotaComites:GetWindowName('places_demandees'..i));
	end

	for i = 1, #tTableComite do
		dlgGetQuotaComites:Bind(eventType.TEXT, 
			function(evt) 
				OnDisplayTotalObtenu()
			end,
			dlgGetQuotaComites:GetWindowName('places_obtenues'..i));
	end

	dlgGetQuotaComites:Bind(eventType.MENU, 
		function(evt)
			local total_a_repartir = tonumber(dlgGetQuotaComites:GetWindowName('a_repartir'):GetValue()) or 0;
			params.nb_equipe = tonumber(dlgGetQuotaComites:GetWindowName('places_ffs'):GetValue()) or 0;
			params.nb_places_a_repartir = total_a_repartir - params.nb_equipe;
			local nb_iteration = 1;
			local difference = 0;
			local a_repartir = params.nb_places_a_repartir;
			while true do
				difference = CalculeQuotaCalculette(a_repartir);
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
			for index = 1, #tTableComite do
				if dlgGetQuotaComites:GetWindowName('places_demandees'..index) then
					local quota_calculette = tonumber(dlgGetQuotaComites:GetWindowName('quota_maximum'..index):GetValue()) or 0;
					quota_calculette = Round(quota_calculette, 0);
					local place_demandee = tonumber(dlgGetQuotaComites:GetWindowName('places_demandees'..index):GetValue()) or 0;
					tTableComite[index].Participation = place_demandee;
				end
			end
			params.somme_places_demandees = tonumber(dlgGetQuotaComites:GetWindowName('total_places_demandees'):GetValue()) or 0;
			params.somme_maxi_theorique = tonumber(dlgGetQuotaComites:GetWindowName('total_base2'):GetValue()) or 0;
			-- adv.Alert('num somme_demandees = '..params.somme_places_demandees..', somme_maxi_theorique = '..params.somme_maxi_theorique);
			-- params.nb_inscrits = params.a_repartir;
			if params.somme_places_demandees > params.somme_maxi_theorique then
				GetSetData()
				params.recalcul = false;
				-- for i = 1, #tTableComite do
					-- local comite = tTableComite[i].Comite
					-- tComiteSav[comite].Maxi_theorique = tTableComite[i].Quota_calcule * 100 / params.a_repartir;
				-- end
				DisplayDataCalculette()
				dlgGetQuotaComites:Refresh();
			else
				local somme_places_obtenues = 0;
				for i = 1, #tTableComite do
					local place_obtenue = tonumber(dlgGetQuotaComites:GetWindowName('places_demandees'..i):GetValue()) or 0;
					dlgGetQuotaComites:GetWindowName('places_obtenues'..i):SetValue(dlgGetQuotaComites:GetWindowName('places_demandees'..i):GetValue());
					somme_places_obtenues = somme_places_obtenues + place_obtenue;	
				end
				dlgGetQuotaComites:GetWindowName('total_places_obtenues'):SetValue(somme_places_obtenues);
			end
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
			params.recalcul = false;
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
			params.nb_places_a_repartir = tonumber(dlgValue:GetWindowName('val_140'):GetValue()) or 0;
			dlgValue:EndModal(idButton.CANCEL);
		 end,  btnSave);
	dlgValue:Fit();
	dlgValue:ShowModal();
end

function OnPrintCalculette()
	local tQuota_comite = sqlTable.Create("tQuota_comite");
	tQuota_comite:AddColumn({ name = 'Comite', label = 'Comite', type = sqlType.CHAR, size = 10 });
	tQuota_comite:AddColumn({ name = 'Quota_base', label = 'Quota_base', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Quota_base2', label = 'Quota_base2', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Participation', label = 'Participation', type = sqlType.LONG, style = sqlStyle.NULL });
	tQuota_comite:AddColumn({ name = 'Quota_calcule', label = 'Quota_calcule', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tQuota_comite:SetPrimary('Comite');
	tQuota_comite:SetName('_Quota_comite');
	ReplaceTableEnvironnement(tQuota_comite, '_Quota_comite');
	local somme_base = 0;
	local somme_base2 = 0;
	local somme_inscrits = 0;
	local somme_quota_calcule = 0
	for i = 1, #tTableComite do
		local quota_calcule = tonumber(dlgGetQuotaComites:GetWindowName('places_obtenues'..i):GetValue()) or 0;
		tTableComite[i].Quota_calcule = quota_calcule;
		local row = tQuota_comite:AddRow();
		local comite = tTableComite[i].Comite;
		if comite == 'GI' and node_hommes:HasAttribute('GI') then
			comite = 'GIRSA';
		elseif comite == 'PY' and node_hommes:HasAttribute('PY') then
			comite = 'PE/PO';
		end
		tQuota_comite:SetCell('Comite', row, comite);
		tQuota_comite:SetCell('Quota_base', row, tTableComite[i].Quota_base);
		somme_base = somme_base + tTableComite[i].Quota_base;
		tQuota_comite:SetCell('Quota_base2', row, Round(tTableComite[i].Quota_calcule * 100 / params.a_repartir,2));
		somme_base2 = somme_base2 + Round(tTableComite[i].Quota_calcule * 100 / params.a_repartir,2);
		tQuota_comite:SetCell('Participation', row, tTableComite[i].Participation);
		somme_inscrits = somme_inscrits + tTableComite[i].Participation;
		tQuota_comite:SetCell('Quota_calcule', row, tTableComite[i].Quota_calcule);
		somme_quota_calcule = somme_quota_calcule + tTableComite[i].Quota_calcule;
	end
	local places_ffs = tonumber(dlgGetQuotaComites:GetWindowName('places_ffs'):GetValue()) or 0;
	local total_reparti = somme_quota_calcule + places_ffs;
	local ligne_titre = 'Calcul de Quota pour une course '..params.code_regroupement..
				'\n'..tEvenement:GetCell('Nom',0)..
				'\n'..tEvenement:GetCell('Station',0)..' le '..tEpreuve:GetCell('Date_epreuve',0)..
				'\nPlaces demandées : '..somme_inscrits..
				' - Quota à répartir : '..params.a_repartir..
				"\nQuota total alloué sur la course : "..total_reparti;

	report = wnd.LoadTemplateReportXML({
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'printcalculette',
		paper_orientation = 'portrait',
		body = tQuota_comite,
		params = {Titre = ligne_titre, Inscrits = somme_inscrits,
				Total_participation = somme_inscrits,
				Total_base = params.somme_comite_coche,
				Total_base2 = somme_base2,
				Places_ffs = places_ffs,
				Total_reparti = total_reparti,
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
		somme_base = somme_base + tTableComite[i].Quota_base;
		tQuota_comite:SetCell('Quota_base2', row, tTableComite[i].Quota_base2);
		somme_base2 = somme_base2 + tTableComite[i].Quota_base2;
		tQuota_comite:SetCell('Participation', row, tTableComite[i].Participation);
		somme_inscrits = somme_inscrits + tTableComite[i].Participation;
		tQuota_comite:SetCell('Quota_calcule', row, tTableComite[i].Quota_calcule);
		tQuota_comite:SetCell('Pourcent', row, tTableComite[i].Pourcent);
		tQuota_comite:SetCell('Status', row, tTableComite[i].Status);
	end
	ligne_titre = tEvenement:GetCell('Nom', 0)..'\nCourse '..params.code_regroupement..' - Calcul des Quotas\nle '..tEpreuve:GetCell('Date_epreuve', 0)..' à '..tEvenement:GetCell('Station', 0)..' - CODEX : '..params.codex;
	report = wnd.LoadTemplateReportXML({
		xml = './process/quotaFIS.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'print',
		paper_orientation = 'portrait',
		body = tQuota_comite,
		params = {Titre = ligne_titre, Inscrits = somme_inscrits, Etrangers = params.nb_etrangers, Francais = params.nb_francais, 
		Francais_maxi = params.nb_francais_maxi, Place_CR = params.place_comite_organisateur, Place_CR = params.place_comite_organisateur,
		Place_Club140 = params.place_club_organisateur140, Place_Club = params.place_club_organisateur,
		Place_WC140 = params.wild_card140, Place_WC = params.wild_card,
		Somme_base = somme_base, 
		Somme_base2 =somme_base2,
		Somme_inscrits = somme_inscrits;
		Total_Calcule = params.somme_quota_calcule, Nb_Equipe = params.nb_equipe,
		Total_General = params.total_general,
		RGB = params.RGB,
		Date = tEpreuve:GetCell('Date_epreuve', 0),
		Station = tEvenement:GetCell('Station', 0)}
		});
end

function OnDisplayTotalReparti()
	params.somme_quota_calcule = tonumber(dlgAfficheCalculs:GetWindowName('somme_quota_calcule'):GetValue()) or 0;
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
		local quota_calcule = tonumber(dlgAfficheCalculs:GetWindowName('quota_calcule'..index):GetValue()) or 0;
		tTableComite[index].Quota_calcule = quota_calcule;
		params.somme_quota_calcule = params.somme_quota_calcule + quota_calcule;
		if tTableComite[index].Quota_calcule  == tTableComite[index].Participation then
			tTableComite[index].Status = 0;
		end
	end
	dlgAfficheCalculs:GetWindowName('somme_quota_calcule'):SetValue(params.somme_quota_calcule);
	params.total_general = params.somme_quota_calcule + params.nb_etrangers + params.place_comite_organisateur + params.place_club_organisateur + params.wild_card + params.nb_equipe ;
	dlgAfficheCalculs:GetWindowName('total'):SetValue(params.total_general);
	local somme_quota_base2 = 0;
	for index = 1, #tTableComite do
		local quota_base2 = tTableComite[index].Quota_calcule * 100 / params.somme_quota_calcule;
		somme_quota_base2 = somme_quota_base2 + quota_base2;
		dlgAfficheCalculs:GetWindowName('quota_base2'..index):SetValue(Round(quota_base2, 2));
		tTableComite[index].Quota_base2 = quota_base2;
	end
	dlgAfficheCalculs:GetWindowName('somme_quota_base2'):SetValue(somme_quota_base2..'%');
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

function AfficheCalculs()
	
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
		race_name = tEvenement:GetCell('Nom', 0)..'\nCourse '..tEpreuve:GetCell('Code_regroupement', 0);
	end
	filter_display = SplitFilter(params.filter);
	if not dlgAfficheCalculs then
		dlgAfficheCalculs = wnd.CreateDialog(
			{
			width = params.width,
			height = params.height,
			x = params.x,
			y = params.y,
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
			Codex = params.codex;
			nb_etrangers = params.nb_etrangers,
			place_comite = params.place_comite_organisateur,
			place_club = params.place_club_organisateur,
			place_wild_card = params.wild_card,
			RGB = params.RGB
			});
	end

	-- adv.Alert('(params.place_comite_organisateur = '..params.place_comite_organisateur);
	dlgAfficheCalculs:GetWindowName('race_name'):SetValue(race_name);
	dlgAfficheCalculs:GetWindowName('inscrits'):SetValue(params.nb_inscrits);
	dlgAfficheCalculs:GetWindowName('etrangers'):SetValue(params.nb_etrangers);
	dlgAfficheCalculs:GetWindowName('etrangers2'):SetValue(params.nb_etrangers);
	dlgAfficheCalculs:GetWindowName('francais'):SetValue(params.nb_francais);
	dlgAfficheCalculs:GetWindowName('nb_francais_maxi'):SetValue(params.nb_francais_maxi);
	dlgAfficheCalculs:GetWindowName('cr_orga'):SetValue(params.place_comite_organisateur);
	dlgAfficheCalculs:GetWindowName('club_orga'):SetValue(params.place_club_organisateur);
	dlgAfficheCalculs:GetWindowName('wild_cards'):SetValue(params.wild_card);
	
	local somme_maxi_theorique = 0;
	params.somme_quota_calcule = 0;
	params.somme_participation = 0;
	local somme_quota_base = 0;
	local somme_quota_base2 = 0;
	for i = 1, #tTableComite do
		local comite = tTableComite[i].Comite;
		tTableComite[i].Quota_calcule = tComite[comite].Quota_calcule or 0;
		if comite == 'GI' then
			comite = 'GIRSA';
		elseif comite == 'PY' then
			comite = 'PE/PO';
		end
		params.somme_quota_calcule = params.somme_quota_calcule + tTableComite[i].Quota_calcule;
		params.somme_participation = params.somme_participation + tTableComite[i].Participation;
		dlgAfficheCalculs:GetWindowName('comite'..i):SetValue(comite);
		dlgAfficheCalculs:GetWindowName('quota_base'..i):SetValue(tTableComite[i].Quota_base..'%');
		somme_quota_base = somme_quota_base + tTableComite[i].Quota_base;
		tTableComite[i].Quota_base2 = tTableComite[i].Quota_calcule * 100 / params.a_repartir;
		dlgAfficheCalculs:GetWindowName('quota_base2'..i):SetValue(Round(tTableComite[i].Quota_base2, 2)..'%');
		somme_quota_base2 = somme_quota_base2 + tTableComite[i].Quota_base2;
		-- dlgAfficheCalculs:GetWindowName('quota_base2'..i):SetValue(tTableComite[i].Place_theorique2);
		dlgAfficheCalculs:GetWindowName('participation'..i):SetValue(tTableComite[i].Participation);
		dlgAfficheCalculs:GetWindowName('quota_calcule'..i):SetValue(tTableComite[i].Quota_calcule);
		if tTableComite[i].Participation > 0 then
		-- 85 places à répartir, un quota de base de 13% donne 11 places. avec un quota calculé de 16 places, on a une utilisation du quota de base de 
			tTableComite[i].Pourcent = Round(tTableComite[i].Quota_calcule * 100 / tTableComite[i].Quota_base, 2);
		end
	end
	-- adv.Alert('AfficheCalculs , somme_participation = '..params.somme_participation..', somme_maxi_theorique = '..somme_maxi_theorique..' sommme_quota_calcule = '..sommme_quota_calcule);
	dlgAfficheCalculs:GetWindowName('somme_quota_base'):SetValue(somme_quota_base..'%');
	dlgAfficheCalculs:GetWindowName('somme_quota_base2'):SetValue(somme_quota_base2..'%');

	dlgAfficheCalculs:GetWindowName('somme_participation'):SetValue(params.somme_participation);
	dlgAfficheCalculs:GetWindowName('somme_quota_calcule'):SetValue(params.somme_quota_calcule);
	dlgAfficheCalculs:GetWindowName('equipe'):SetValue(params.nb_equipe);
	params.total_general = params.somme_quota_calcule + params.nb_etrangers + params.place_comite_organisateur + params.place_club_organisateur + params.wild_card + params.nb_equipe ;
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

	-- Toolbar Principale ...
	if not params.recalcul then
		local tbconfig = dlgAfficheCalculs:GetWindowName('tbconfig');
		tbconfig:AddStretchableSpace();
		local btnPrint = tbconfig:AddTool("Imprimer", "./res/32x32_printer.png");
		tbconfig:AddStretchableSpace();
		local btnRecalculer = tbconfig:AddTool("Recalculer", "./res/32x32_calc.png");
		tbconfig:AddStretchableSpace();
		local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
		tbconfig:AddStretchableSpace();
		btnBackOffice = tbconfig:AddTool("Back Office", "./res/32x32_configuration.png");
		tbconfig:AddStretchableSpace();

		tbconfig:Realize();

		for i = 1, #tTableComite do
			dlgAfficheCalculs:Bind(eventType.TEXT, 
				function(evt)
					if tTableComite[i].Participation > 0 then
						local quota_calcule = tonumber(dlgAfficheCalculs:GetWindowName('quota_calcule'..i):GetValue()) or 0;
						if quota_calcule > tTableComite[i].Participation then
							quota_calcule = tTableComite[i].Participation;
							tTableComite[i].Quota_calcule = quota_calcule;
							dlgAfficheCalculs:GetWindowName('quota_calcule'..i):SetValue(tTableComite[i].Quota_calcule);
						end
						OnDisplayQuotaCalcule()
					end
				end,
				dlgAfficheCalculs:GetWindowName('quota_calcule'..i));
		end

		dlgAfficheCalculs:Bind(eventType.TEXT, 
			function(evt)
				OnDisplayTotalReparti();
			end,
			dlgAfficheCalculs:GetWindowName('cr_orga'));

		dlgAfficheCalculs:Bind(eventType.TEXT, 
			function(evt)
				OnDisplayTotalReparti();
			end,
			dlgAfficheCalculs:GetWindowName('club_orga'));

		dlgAfficheCalculs:Bind(eventType.TEXT, 
			function(evt)
				OnDisplayTotalReparti();
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
				local nb_francais = 0;
				-- table.insert(tTableComite, {Comite = 'AP', Quota_base = 0, 
				-- Quota_base2 = 0, 
				-- Representation = 0, 
				-- Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, 
				-- Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, 
				-- Place_Rendue = 0, Pourcent = 0, Status = 1});
				for i = 1, #tTableComite do
					local comite = tTableComite[i].Comite;
					local participation = tonumber(dlgAfficheCalculs:GetWindowName('participation'..i):GetValue()) or 0;
					nb_francais = nb_francais + participation;
					tTableComite[i].Participation = participation;
					tTableComite[i].Quota_base = tquotaComite[comite];
					tTableComite[i].Quota_base2 = 0;
					tTableComite[i].Representation = 0;
					tTableComite[i].Place_gagnee = -1;
					tTableComite[i].Place_theorique2 = 0;
					tTableComite[i].Quota_calcule = 0;
					tTableComite[i].Status = 1;;
					tTableComite[i].Maxi_theorique = 0;
					tTableComite[i].Maxi_theorique2 = 0;
					tTableComite[i].Place_rendue = -1;
					tTableComite[i].Maximum = 0;
					tTableComite[i].Pourcent = 0;
					tTableComite[i].Maxi_theorique2 = 0;
				end
				params.place_comite_organisateur = tonumber(dlgAfficheCalculs:GetWindowName('cr_orga'):GetValue()) or 0;
				params.place_club_organisateur = tonumber(dlgAfficheCalculs:GetWindowName('club_orga'):GetValue()) or 0;
				params.wild_card = tonumber(dlgAfficheCalculs:GetWindowName('wild_cards'):GetValue()) or 0;
				if params.place_comite_organisateur == 0 and params.place_club_organisateur == 0 and params.wild_card == 0 then
					params.place_variable = 0;
				end
				node_hommes:ChangeAttribute('COMITE', params.place_comite_organisateur);
				node_hommes:ChangeAttribute('CLUB', params.place_club_organisateur);
				node_hommes:ChangeAttribute('WILDCARD', params.wild_card);
				node_hommes:ChangeAttribute('VARIABLE', params.place_variable);
				LectureNodeHommes(node_hommes);
				node.place_comite_organisateur = params.place_comite_organisateur;
				node.place_club_organisateur = params.place_club_organisateur;
				node.wild_card = params.wild_card;
				-- if node.place_comite_organisateur == 0 and node.place_club_organisateur == 0 and node.wild_card == 0 then
					-- params.place_variable = 0;
				-- end
				dlgAfficheCalculs:EndModal();
				-- params.nb_francais = nb_francais;
				-- tTableComitex = tTableComite;
				params.recalcul = true
				SettTableComite();
				-- GetSetData();
				-- AfficheCalculs();
				-- somme_quota_base2 = 0;
				-- for index = 1, #tTableComite do
					-- dlgAfficheCalculs:GetWindowName('quota_base2'..index):SetValue(Round(tTableComite[index].Quota_base2, 2)..'%');
					-- somme_quota_base2 = somme_quota_base2 + tTableComite[index].Quota_base2;
				-- end
				dlgAfficheCalculs:GetWindowName('somme_quota_base2'):SetValue(somme_quota_base2..'%');
			end, btnRecalculer2); 

		dlgAfficheCalculs:Bind(eventType.MENU, 
			function(evt) 
				params.place_comite_organisateur = tonumber(dlgAfficheCalculs:GetWindowName('cr_orga'):GetValue()) or 0;
				params.place_club_organisateur = tonumber(dlgAfficheCalculs:GetWindowName('club_orga'):GetValue()) or 0;
				params.wild_card = tonumber(dlgAfficheCalculs:GetWindowName('wild_cards'):GetValue()) or 0;
				node_hommes:ChangeAttribute('COMITE', params.place_comite_organisateur);
				node_hommes:ChangeAttribute('CLUB', params.place_club_organisateur);
				node_hommes:ChangeAttribute('WILDCARD', params.wild_card);
				node.place_comite_organisateur = params.place_comite_organisateur;
				node.place_club_organisateur = params.place_club_organisateur;
				node.wild_card = params.wild_card;
				dlgAfficheCalculs:EndModal();
			end, btnRecalculer); 
			
		wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
		
		dlgAfficheCalculs:Bind(eventType.MENU, 
			function(evt) 
				OnAfficheBackOffice();
				dlgBackOffice = nil;
				dlgAfficheCalculs:EndModal();
			 end,  btnBackOffice);

		dlgAfficheCalculs:Bind(eventType.MENU, 
			function(evt) 
				OnClose();
				dlgAfficheCalculs:EndModal(idButton.CANCEL) 
			 end,  btnClose);
		dlgAfficheCalculs:Fit();
		dlgAfficheCalculs:ShowModal()
	end
end

function LectureNodeHommes(node)
	tquotaComitex = {}
	local attribute = node:GetAttributes();
	while attribute ~= nil do
		local name = attribute:GetName();
		local value = attribute:GetValue();
		if name ~= 'filter' then
			value = tonumber(value) or 0;
		end
		if name == 'COMITE' then
			params.place_comite_organisateurx = value;
		elseif name == 'CLUB' then
			params.place_club_organisateurx = value;
		elseif name == 'WILDCARD' then
			params.wild_cardx = value;
		elseif name == 'ORIGINE' then
			params.equipe_Comite_originex = value;
		elseif name ~= 'filter' then
			tquotaComite[name] = value;
		end
		tquotaComitex[name] = value;
		attribute = attribute:GetNext();
	end
	-- les valeurs ci-dessous sont indiquées pour 140 français sans étrangers.
	params.place_comite_organisateurx = params.place_comite_organisateurx or 0;
	params.place_club_organisateurx = params.place_club_organisateurx or 0;
	params.wild_cardx = params.wild_cardx or 0;
	params.equipe_Comite_originex = params.equipe_Comite_originex or 0;
end

function GetQuotaComites(node_hommes)
	node = {};
	local attribute = node_hommes:GetAttributes();
	while attribute ~= nil do
		local name = attribute:GetName();
		local value = attribute:GetValue();
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
		elseif name == 'VARIABLE' then
			params.place_variable = value;
		else
			if estNumerique(value) then
				tquotaComite[name] = value;
			end
		end
		attribute = attribute:GetNext();
		-- adv.Alert(name..' - '..value);
	end
	params.filter = params.filter or '';
	-- les valeurs ci-dessous sont indiquées pour 140 français sans étrangers.
	params.place_club_organisateur = params.place_club_organisateur or 0;
	params.wild_card = params.wild_card or 0;
	params.place_variable = params.place_variable or 0;
	params.equipe_Comite_origine = params.equipe_Comite_origine or 0;

	node.place_comite_organisateur = params.place_comite_organisateur;
	node.place_club_organisateur = params.place_club_organisateur;
	node.wild_card = params.wild_card;
	node.place_variable = params.place_variable;
	node.equipe_Comite_origine = params.equipe_Comite_origine;
end

function CalculeQuota(a_repartir, nb_iteration)
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
	local somme_quota_base2 = 0;
	local somme_pour_redistribution = 0;
	-- adv.Alert('\nCalculeQuota - nb_iteration = '..nb_iteration);
		for index = 1, #tTableComitex do
			if tTableComitex[index].Participation > 0 then
				local comite = tTableComitex[index].Comite;
				params.somme_quota_base = params.somme_quota_base + tTableComitex[index].Quota_base;
				tTableComitex[index].Quota_base2 = tTableComitex[index].Quota_base * 100 / params.somme_quota_base;
			end
		end
		for index = 1, #tTableComitex do
			if tTableComitex[index].Participation > 0 then
				local quota_calcule = 0;
				local comite = tTableComitex[index].Comite;
				tTableComitex[index].Quota_base2 = tTableComitex[index].Quota_base * 100 / params.somme_quota_base;
				-- adv.Alert(comite..', Quota_base2 = '..tTableComitex[index].Quota_base2..', params.somme_quota_base2 = '..params.somme_quota_base2);
				tTableComitex[index].Maxi_theorique = a_repartir * tTableComitex[index].Quota_base2 / 100;
				somme_maxi_theorique = somme_maxi_theorique + tTableComitex[index].Maxi_theorique ;
				if tTableComitex[index].Participation >= tTableComitex[index].Maxi_theorique then
					tTableComitex[index].Place_gagnee = 1;
					somme_quota_base2 = somme_quota_base2 + tTableComitex[index].Quota_base2;
					tTableComitex[index].Quota_calcule = tTableComitex[index].Maxi_theorique;
					params.somme_quota_calcules = params.somme_quota_calcules + tTableComitex[index].Quota_calcule;
					-- adv.Alert(comite..', participation '..tTableComitex[index].Participation..' >= Maxi_theorique = '..tTableComitex[index].Maxi_theorique..', Quota_calcule = '..tTableComitex[index].Quota_calcule..', Status = '..tTableComitex[index].Status);
					somme_pour_redistribution = somme_pour_redistribution + tTableComitex[index].Maxi_theorique;
				else
					tTableComitex[index].Status = 0;
					tTableComitex[index].Place_gagnee = 0;
					tComite[comite].Status = 0;
					quota_calcule = tTableComitex[index].Participation;
					tTableComitex[index].Quota_calcule = quota_calcule;
					tComite[comite].Quota_calcule = quota_calcule;
					local place_rendue = tTableComitex[index].Maxi_theorique - tTableComitex[index].Participation;
					params.somme_quota_calcules = params.somme_quota_calcules + quota_calcule;
					tTableComitex[index].Place_Rendue = place_rendue;
					tComite[comite].Place_Rendue = place_rendue;
					params.somme_places_rendues = params.somme_places_rendues + tTableComitex[index].Place_Rendue;
					-- adv.Alert(comite..', participation '..tTableComitex[index].Participation..' < Maxi_theorique = '..tTableComitex[index].Maxi_theorique..', Quota_calcule = '..tTableComitex[index].Quota_calcule..', Status = '..tTableComitex[index].Status..', rend '..tTableComitex[index].Place_Rendue..' places');
				end
			end
		end
	-- les comités pourvus incomplètement ont un status à 1
	params.somme_quota_base2 = 0;
	for index = 1, #tTableComitex do
		if tTableComitex[index].Place_gagnee > 0 then
			local comite = tTableComitex[index].Comite;
			params.somme_quota_base2 = params.somme_quota_base2 + tTableComitex[index].Quota_base2;
		end
	end
	-- on recalcule Representation des comités devant recevoir les places rendues
	for index = 1, #tTableComitex do
		if tTableComitex[index].Place_gagnee > 0 then
			local comite = tTableComitex[index].Comite;
			if not tComite[comite].Quota_calcule and tTableComitex[index].Place_gagnee > 0 then
				tTableComitex[index].Representation = (tTableComitex[index].Quota_base2 / params.somme_quota_base2) * 100;
				-- adv.Alert('le comite '..comite..' va recevoir des places, sa représentation est de '..tTableComitex[index].Representation..'% Place_gagnee = '..tTableComitex[index].Place_gagnee);
			end
		end
	end

	 -- somme_restant_a_repartir = a_repartir - params.somme_quota_calcules + params.somme_places_rendues;
		somme_restant_a_repartir = params.somme_places_rendues;
	-- adv.Alert('\na_repartir = '..a_repartir..', Quotas déjà attribués = '..params.somme_quota_calcules..', params.somme_places_rendues = '..params.somme_places_rendues..', somme_restant_a_repartir = '..somme_restant_a_repartir);
	-- tTableComitex[index].Quota_base2  = pourcentage de représentativité d'un comité parmi ceux qui ont des participants. C'est un pourcantage sur 100
	-- tTableComitex[index].Maxi_theorique  = nombre de place (décimale) qu'un comité peut recevoir. Leur addition donne le nombre e place à répartir
	-- on aura attribué les Quota_calcule selon : 
	--		un comité ayant une participation >= Quota_base2  --> Maxi_theorique. Place_gagnee = 0;
	--		un comité ayant une participation <  Quota_base2  -->Participation
	--				dans ce cas, Place_Rendue = Maxi_theorique - Participation. Place rendue = valeur décimale
	--				dans ce cas, Place_gagnee = -1
	-- les comités ayant Place_gagnee = 0 doivent recevoir une fraction des places rendues selon leur pourcentage de représentativité.
--	table.insert(tTableComitex, {Comite = 'AP', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	params.somme_quota_base2 = 0;
	for index = 1, #tTableComitex do
		delta_a_rajouter = 0;
		if tTableComitex[index].Place_gagnee > 0 then
			local comite = tTableComitex[index].Comite;
			local gagne = (somme_restant_a_repartir * tTableComitex[index].Representation) / 100;
			
			if tTableComitex[index].Quota_calcule + gagne > tTableComitex[index].Participation then
				delta_a_rajouter = tTableComitex[index].Quota_calcule + gagne - tTableComitex[index].Participation;
				tTableComitex[index].Quota_calcule = tTableComitex[index].Participation;
				-- adv.Alert('\nOn remonte '..comite..', à sa participation');
				tTableComitex[index].Quota_calcule =  tTableComitex[index].Participation;
			else 
				tTableComitex[index].Place_gagnee = 2;
				-- adv.Alert('le comite '..comite..' va recevoir des places au tour 2, on recalculera sa nouvelle representation');
			end
		end
	end
	for index = 1, #tTableComitex do
		if tTableComitex[index].Place_gagnee == 2 then
			params.somme_quota_base2 = params.somme_quota_base2 + tTableComitex[index].Quota_base2;
		end
	end
	params.somme_quota_calcules = 0;
	for index = 1, #tTableComitex do
		params.somme_quota_calcules = params.somme_quota_calcules + tTableComitex[index].Quota_calcule;
		if tTableComitex[index].Place_gagnee == 2 then
			local comite = tTableComitex[index].Comite;
			tTableComitex[index].Representation = (tTableComitex[index].Quota_base2 / params.somme_quota_base2) * 100;
			-- adv.Alert('le comite '..comite..' va recevoir des places, sa nouvelle représentation est de '..tTableComitex[index].Representation..'%');
		end
	end
	local calcul = 0;
	somme_restant_a_repartir = a_repartir - params.somme_quota_calcules;
	-- adv.Alert('on redistribue le reliquat des places rendues, somme_restant_a_repartir = '..somme_restant_a_repartir);
	for index = 1, #tTableComitex do
		if tTableComitex[index].Place_gagnee == 2 then
			local comite = tTableComitex[index].Comite;
			local gagne = (somme_restant_a_repartir * tTableComitex[index].Representation) / 100;
			-- adv.Alert('\n'..comite..' - Place_gagnee == 2 , Quota_calcule initial = '..tTableComitex[index].Quota_calcule..', gagne = '..gagne);
			tTableComitex[index].Quota_calcule = tTableComitex[index].Quota_calcule + gagne
		end
	end

	calcul = 0;
	for index = 1, #tTableComitex do
		if tTableComitex[index].Participation > 0 then
			local comite = tTableComitex[index].Comite;
			tTableComitex[index].Quota_calcule = Round(tTableComitex[index].Quota_calcule, 0);
			calcul = calcul + tTableComitex[index].Quota_calcule;
			tComite[comite].Quota_calcule = tTableComitex[index].Quota_calcule;
			tTableComitex[index].Quota_base2 = tTableComitex[index].Quota_calcule * 100 / a_repartir;
		end
		-- adv.Alert('passage 2 '..tTableComitex[index].Comite..', Quota_calcule = '..tTableComitex[index].Quota_calcule..', somme Quota_calcule = '..calcul);
	end
	difference = calcul - a_repartir;
	-- adv.Alert('\n fin de CalculeQuota, sonme des quotas calculés = '..calcul..', a_repartir = '..params.a_repartir..', difference = '..difference..'\n-');
	return difference;
end

function NettoietTableComite(index)
-- table.insert(tTableComite, {Comite = 'MJ', Quota_base = 0, Quota_base2 = 0, 
-- Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, 
-- Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, 
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
	params.somme_quota_base = 0;
	for index = #tTableComitex, 1, -1 do
		params.somme_quota_base = params.somme_quota_base + tTableComitex[index].Quota_base;
	end
	if params.nb_places_a_repartir then
		params.nb_francais_maxi = params.nb_places_a_repartir;
		params.nb_etrangers = 0;
		params.place_comite_organisateur = 0;
		params.place_club_organisateur = 0;
		params.wild_card = 0;
		params.a_repartir = params.nb_places_a_repartir;
	else
		params.place_comite_organisateur = node.place_comite_organisateur;
		params.place_club_organisateur = node.place_club_organisateur;
		params.wild_card = node.wild_card;
		if tRanking:GetNbRows() >= 140 then
			params.nb_francais_maxi = 140 - params.nb_etrangers;
		else
			params.nb_francais_maxi = tRanking:GetNbRows() - params.nb_etrangers;
		end
	end
	if params.codex:sub(1,3) ~= 'FRA' then
		params.place_comite_organisateur = 0;
		params.place_club_organisateur = 0;
		params.wild_card = 0;
	end
	-- adv.Alert('params.nb_francais_maxi = '..params.nb_francais_maxi);
	-- adv.Alert('params.place_comite_organisateur = '..params.place_comite_organisateur);
	-- adv.Alert('params.place_club_organisateur = '..params.place_club_organisateur);
	-- adv.Alert('params.wild_card = '..params.wild_card);
	-- adv.Alert('params.nb_equipe = '..params.nb_equipe);
	-- adv.Alert('params.place_variable = '..params.place_variable);
	if params.calculette == 0 then
		if params.place_variable == 0 then
			params.a_repartir = params.nb_francais_maxi - (params.place_comite_organisateur + params.place_club_organisateur + params.wild_card  + params.nb_equipe);
		else
			params.place_comite_organisateur = math.ceil(params.place_comite_organisateur * params.nb_francais_maxi / 140);
			params.place_club_organisateur = math.ceil(params.place_club_organisateur * params.nb_francais_maxi / 140);
			params.wild_card = math.ceil(params.wild_card * params.nb_francais_maxi / 140);
			params.a_repartir = params.nb_francais_maxi - (params.place_comite_organisateur + params.place_club_organisateur + params.wild_card  + params.nb_equipe);
		end
	end
	-- adv.Alert('GetSetData à répartir = '..params.a_repartir);
	nb_iteration = 1;
	local difference = 0;
	local a_repartir = params.a_repartir;
	local multiplicateur = 1;
	while true do
		-- adv.Alert('\n - début de boucle, nb_iteration = '..nb_iteration..', a_repartir = '..a_repartir);
		difference = CalculeQuota(a_repartir, nb_iteration);
		if math.abs(difference) < 0.1 or math.abs(difference) > 3 then
			-- adv.Alert('sortie de boucle sur itération '..nb_iteration..' avec math.abs(difference) = '..math.abs(difference));
			break;
		end
		if nb_iteration == 20 then
			return false;
		end
		for index = 1, #tTableComitex do
			tTableComitex[index].Quota_base2 = 0;
			tTableComitex[index].Place_gagnee = 0;
			tTableComitex[index].Place_theorique2 = 0;
			tTableComitex[index].Quota_calcule = 0;
			tTableComitex[index].Place_Rendue = 0;
			tTableComitex[index].Pourcent = 0;
			tTableComitex[index].Status = 1;
		end
		nb_iteration = nb_iteration + 1;
		if not difference_sav then
			difference_sav = difference
			a_repartir = a_repartir + 0.5;
		else
			a_repartir = a_repartir - 0.1;
		end
		-- adv.Alert('\nfin de la boucle while, après CalculeQuota nb_iteration = '..nb_iteration..', différence = '..difference..', à repartir tour suivant = '..a_repartir);
	end
end

function SettTableComite();
	tTableComite = {};
	table.insert(tTableComite, {Comite = 'AP', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'AU', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'CA', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'CO', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'DA', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'IF', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'MB', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'MJ', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'MV', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	table.insert(tTableComite, {Comite = 'SA', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	if node_hommes:HasAttribute('PY') then
		table.insert(tTableComite, {Comite = 'PY', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	else
		table.insert(tTableComite, {Comite = 'PO', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
		table.insert(tTableComite, {Comite = 'PE', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	end
	if node_hommes:HasAttribute('GI') then
		table.insert(tTableComite, {Comite = 'GI', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	else
		table.insert(tTableComite, {Comite = 'BO', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
		table.insert(tTableComite, {Comite = 'FZ', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
		table.insert(tTableComite, {Comite = 'CE', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
		table.insert(tTableComite, {Comite = 'LY', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
		table.insert(tTableComite, {Comite = 'OU', Quota_base = 0, Quota_base2 = 0, Representation = 0, Place_gagnee = -1, Place_theorique2 = 0,Participation = 0, Maxi_theorique = 0, Maximum = 0, Maxi_theorique2 = 0, Quota_calcule = 0, Quota_calculette = 0, Place_Rendue = 0, Pourcent = 0, Status = 1});
	end
	params.nb_equipe = 0;
	-- adv.Alert('SettTableComite - type(params.equipe_Comite_origine) = '..type(params.equipe_Comite_origine)..', params.equipe_Comite_origine = '..params.equipe_Comite_origine);
	if params.calculette == 0 then
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
		-- tRanking:Snapshot('tRanking.db3');
	end
	tComite = {};
	for index = 1, #tTableComite do
		local comite = tTableComite[index].Comite;
		tComite[comite] = {};
		tComite[comite].Index = index;
		tTableComite[index].Quota_base = tquotaComite[comite];
		if params.calculette == 0 then
			if tRanking:GetCounterValue('Comite', comite) then
				tTableComite[index].Participation = tRanking:GetCounterValue('Comite', tTableComite[index].Comite);
			else
				tTableComite[index].Participation = -1;
			end
		end
	end
	tTableComitex = tTableComite;
end

-- Fonction pour vérifier si une variable est numérique
function estNumerique(variable)
    return tonumber(variable) ~= nil
end

function main(params_c)
	params = params_c;
		-- for k,v in pairs(params) do
			-- adv.Alert('Key '..k..'='..tostring(v));
			-- if type(v) == 'table' then
				-- for i,j in pairs(v) do
					-- adv.Alert('Key '..i..'='..tostring(j));
					-- adv.Alert('type de '..i..' = '..type(j));
				-- end
			-- end
			-- adv.Alert('\n');
		-- end
		-- do return end
	params.RGB = {};
	params.RGB[1] = 'rgb 200 255 200';
	params.RGB[2] = {};
	params.RGB[2][1] = 'rgb 255 192 0';
	params.RGB[2][2] = 'rgb 255 0 0';
	params.calculette = tonumber(params.calculette) or 0;
	if params.calculette == 0 then
		if not params.code_evenement then	
			return;
		end
	end
	params.width = display:GetSize().width;
	params.height = display:GetSize().height - 50;
	params.x = 0;
	params.y = 0;
	params.recalcul = false;
	script_version = 2.0;
	; -- 4.92 pour 2022-2023
	indice_return = 11;
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
	-- Ouverture Document XML 
	xml_config_quota = app.GetPath()..'/quotaFIS_config.xml';
	if not app.FileExists(xml_config_quota) then
		msg = "Vous n'êtes pas habilité à gérer les quotas FIS";
		app.GetAuiFrame():MessageBox(msg, "Droits insuffisants", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		return;
	end
	params.codex = 'FRA';
	base = base or sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	if params.calculette == 0 then
		if tEvenement:GetCell('Code_entite', 0) ~= 'FIS' then
			return;
		end
		params.comite_organisateur = tEvenement:GetCell('Code_comite', 0);
		params.code_regroupement = tEpreuve:GetCell('Code_regroupement', 0);
		params.codex = tEpreuve:GetCell('Codex', 0);
		if params.code_regroupement == 'CITWC' then
			params.code_regroupement = 'CIT';
		end
		params.code_regroupementx = params.code_regroupement;
		tRanking = base.CreateTableRanking({ code_evenement = params.code_evenement});
		-- tRanking:Snapshot('tRanking.db3');
	end
	params.code_regroupement = params.code_regroupement or 'FIS';
	params.code_regroupementx = params.code_regroupement;
	tquotaComite = {};
	params.filter = '';
	doc_config = xmlDocument.Create(xml_config_quota);
	root = doc_config:GetRoot();
	node_hommes = doc_config:FindFirst('root/hommes/'..string.sub(params.code_regroupement, 1, 3));
	if not node_hommes then
		msg = msg.."La gestion de quotas n'est pas prévue\npour le code regroupement "..params.code_regroupement;
		app.GetAuiFrame():MessageBox(msg, "Quotas non gérés", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		return;
	else
		GetQuotaComites(node_hommes);
	end
	if params.calculette == 0 then
		local msg = "Oui = Conserver le filtre actuellement enregistré.\nNon = Enregistrement d'un nouveau filtre.\nAnnuler = Ne pas tenir compte d'un filtrage enregistré.";
		local key = app.GetAuiFrame():MessageBox(msg, "Filtrage des concurrents", msgBoxStyle.YES + msgBoxStyle.NO + msgBoxStyle.CANCEL + msgBoxStyle.YES_DEFAULT + msgBoxStyle.ICON_WARNING);
		if key == msgBoxStyle.NO then
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
			end
		elseif key == msgBoxStyle.CANCEL then
			params.filter = '';
		end
		if params.filter:len() > 0 then
			tRanking:Filter(params.filter, true);
		end
		if tRanking:GetNbRows() < 140 or params.codex:sub(1,3) ~= 'FRA' then
			params.valeur_140 = tRanking:GetNbRows();
			GetNbPlacesARepartir();
			-- prise de la valeur des places à répartir.
		else
			params.valeur_140 = 140;
		end
		params.nb_inscrits = tRanking:GetNbRows();
		while true do
			if params.exit then
				break;
			end
			SettTableComite();
			GetSetData();
			AfficheCalculs();
			if dlgAfficheCalculs then
				dlgAfficheCalculs = nil;
			end
				
		end
	elseif not dlgGetQuotaComites then
		SettTableComite();
		GetParticipationComites();
	end
	
	
	if params.doc_config then
		params.doc_config:Close();
		params.doc_config:Delete();
	end

end
