-- Calcul d'un temps manuel (avec 10 avant ou avec d�calage)
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
dofile('./edition/functionPG.lua');


function ReplaceTableEnvironnement(t, name)		-- replace la table cr��e dans l'environnement de la base de donn�e pour �viter les memory leaks
	if type(t) ~= 'userdata' then
		return;
	end
	t:SetName(name);
	if base:GetTable(name) ~= nil then
		base:RemoveTable(name);
	end
	base:AddTable(t);
end


function TriSurRang(a, b)
    if (a.Rang < b.Rang) then 
         return true;
     else
         return false;
     end
end

function OnPrint()
	-- Creation du Report
	if PG_TempsManuel:GetCell("Impulsion", 0) == 'D' then
		params.difference = 'H.D�part : '..params.HeureCalculee..'  -  H.Arriv�e : '..app.TimeToString(PG_TempsManuel:GetCellInt("Heure_arrivee", TM.row_coureur), params.fmt).. '  => Temps de course = '..params.tps;
	else
		params.difference = 'H.D�part : '..app.TimeToString(PG_TempsManuel:GetCellInt('Heure_depart', TM.row_coureur), params.fmt)..'  -  H.Arriv�e : '..params.HeureCalculee.. '  => Temps de course = '..params.tps;
	end
	params.date_calcul = PG_TempsManuel:GetCell('Date_calcul', 0);
	params.recherche = "\n\nCalcul de l'impulsion de "..TM.impulsion..
		" (EET) en manche "..params.code_manche..
		"\npour le dossard "..TM.dossard..
		" : "..params.Identite..
		"\nEdition du "..params.date_calcul;
	params.base_de_temps = TM.BaseDeTemps;
	report = wnd.LoadTemplateReportXML({
		xml = './edition/tempsManuel.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'print' ,
		title = 'Edition d\'un temps arithm�tique',
		
		base = base,
		body = PG_TempsManuel,
		
		margin_first_top = 200,
		margin_first_left = 100,
		margin_first_right = 100,
		margin_first_bottom = 200,
		margin_top = 100,
		margin_left = 100,
		margin_right = 100,
		margin_bottom = 200,
		paper_orientation = 'landscape',
		params = params
	});
	-- report:SetZoom(10)
end

function OnChangeDelta()
	params.millisecondes = 0;
	for idx = 1, 11 do
		if dlgSaisie:GetWindowName('heure'..idx):GetValue():len() > 0 then
			TM.ligne[idx].delta = tonumber(dlgSaisie:GetWindowName('delta'..idx):GetValue()) or 0;
			params.millisecondes = params.millisecondes + TM.ligne[idx].delta;
			if TM.ligne[idx].int_doublage > 0 then
				if math.abs(TM.ligne[idx].delta) > 1000 then
					msg = "N.B. il y a plus d'une seconde de diff�rence !!  \n\n V�rifiez le doublage de la ligne "..idx;
					app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
				end
			end
		end
	end
	dlgSaisie:GetWindowName("millisecondes"):SetValue(params.millisecondes);
end

function OnChangeDossard()
	TM.calculfait = false;
	TM.ok = true;
	params.Identite = "???";
	TM.dossard = tonumber(dlgConfig:GetWindowName('dossard'):GetValue()) or 0;
	if TM.dossard > 0 then
		local r = Resultat:GetIndexRow('Dossard', TM.dossard);
		if r and r >= 0 then
			params.Nom = Resultat:GetCell("Nom", r);
			params.Prenom = Resultat:GetCell("Prenom", r);
			params.Comite = Resultat:GetCell("Comite", r);
			params.Nation = Resultat:GetCell("Nation", r);
			if params.Nation == "FRA" then
				params.Identite = params.Nom.." "..params.Prenom.." - "..params.Comite;
			else
				params.Identite = params.Nom.." "..params.Prenom.." - "..params.Nation;
			end
		end
	end
	dlgConfig:GetWindowName('identite'):SetValue(params.Identite);
end

function OnChangeDossardPrecedent(dossardPrecedent)
	local dossard = tonumber(dossardPrecedent) or 0;
	if dossard == 0 then
		TM.dossard_precedent = 0;
		return
	end
	TM.calculfait = false;
	TM.lire = false
	TM.dossard_precedent = dossardPrecedent;
	params.IdentitePrecedente = '???';
	local r = Resultat:GetIndexRow('Dossard', dossardPrecedent);
	if r and r >= 0 then
		if Resultat:GetCell("Nation", r) == "FRA" then
			params.IdentitePrecedente = Resultat:GetCell("Nom", r).." "..Resultat:GetCell("Prenom", r).." - "..Resultat:GetCell("Comite", r);
		else
			params.IdentitePrecedente = Resultat:GetCell("Nom", r).." "..Resultat:GetCell("Prenom", r).." - "..Resultat:GetCell("Nation", r);
		end
	end
	dlgConfig:GetWindowName('identite_precedente'):SetValue(params.IdentitePrecedente);
end

function OnChangeManche(code_manche);
	local filter = "$(Code_manche):In("..code_manche..")";
	LoadResultatChrono(params.code_evenement);
	tDeparts:Filter(filter, true);
	tArrivees:Filter(filter, true);
	TM.calculfait = false;
end

function OnChangeImpulsion(impulsion)
	TM.impulsion = impulsion;
	if TM.impulsion == "D�part" then
		TM.Table = tDeparts:Copy();
	else
		TM.Table = tArrivees:Copy();
	end
	TM.calculfait = false;
end

function OnValidation()
	-- on efface toutes les lignes de la table physique
	cmd = "Delete From PG_TempsManuel Where Code_evenement = "..params.code_evenement..
		" And Code_manche = "..params.code_manche..
		" And Dossard_calcul = '"..TM.dossard.."';";
	base:Query(cmd);
	-- on enregistre les lignes de PG_TempsManuel dans la base
	for idx = 1, 11 do
		row = idx -1;
		PG_TempsManuel:SetCell("Doublage", row, TM.ligne[idx].int_doublage);
		TM.ligne[idx].delta =  TM.ligne[idx].int_heure - TM.ligne[idx].int_doublage;
		if PG_TempsManuel:GetCellInt("Coureur", row) == 1 then
			TM.ligne[idx].delta = 0;
		end
		PG_TempsManuel:SetCell("Delta", row , TM.ligne[idx].delta);
		PG_TempsManuel:SetCell('Date_calcul', row, TM.date);
	end
	base:TableBulkInsert(PG_TempsManuel);
	OK = SetHeureCalculee();
	assert(OK == true);
	if OK == true then
		TM.calculfait = true;
	end
end

function ControleData()
	local errormessage = "";
	if params.Identite == nil or params.Identite == "???" then
		errormessage = errormessage.."Le n� de dossard est incorrect !!\n";
	end
	if errormessage:len() > 0 then 
		local msg = "Veuillez indiquer le num�ro de dossard :\n\n"..errormessage;
		app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		return false;
	end
	return true;
end

function OnChangeDoublage(idx)
	TM.ligne[idx] = TM.ligne[idx] or {};
	dlgSaisie:GetWindowName('delta'..idx):SetValue('');
	local value = dlgSaisie:GetWindowName("doublage"..idx):GetValue();
	if value:len() == 0 then
		TM.ligne[idx].delta = 0;
		dlgSaisie:GetWindowName("delta"..idx):SetValue('');
		return false
	end
	if TM.BaseDeTemps then
		dlgSaisie:GetWindowName("heure"..TM.row_coureur+1):SetValue('')
	end
	TM.calculfait = false;
	local strnumber = string.gsub(value, "%D", "");
	if strnumber:len() > 9 then
		strnumber = string.sub(strnumber, 1, 9);
	end
	if strnumber:len() == 9 then
		strnumber = string.sub(strnumber, 1, 2)..":"..string.sub(strnumber, 3, 4)..":"..string.sub(strnumber, 5, 6).."."..string.sub(strnumber, 7);
		dlgSaisie:GetWindowName("doublage"..idx):SetValue(strnumber);
	end
	if dlgSaisie:GetWindowName("doublage"..idx):GetValue():len() == 12 then
		TM.ligne[idx].doublage = dlgSaisie:GetWindowName("doublage"..idx):GetValue();
		TM.ligne[idx].int_doublage = adv.HHMMSSms_To_MS(TM.ligne[idx].doublage);
		if dlgSaisie:GetWindowName("heure"..idx):GetValue():len() > 0 then
			TM.ligne[idx].int_heure = adv.HHMMSSms_To_MS(dlgSaisie:GetWindowName("heure"..idx):GetValue());
			TM.ligne[idx].delta =  TM.ligne[idx].int_heure - TM.ligne[idx].int_doublage;
			dlgSaisie:GetWindowName("delta"..idx):SetValue(TM.ligne[idx].delta);
			if math.abs(TM.ligne[idx].delta) > 0 then
				OnChangeDelta();
			end
		else
			params.HeureDoublage = dlgSaisie:GetWindowName("doublage"..idx):GetValue();
		end
	end		
end

function OnChangeHeure(idx)
	local value = dlgSaisie:GetWindowName("heure"..idx):GetValue();
	local strnumber = string.gsub(value, "%D", "");
	if strnumber:len() > 9 then
		strnumber = string.sub(strnumber, 1, 9);
	end
	if strnumber:len() == 9 then
		strnumber = string.sub(strnumber, 1, 2)..":"..string.sub(strnumber, 3, 4)..":"..string.sub(strnumber, 5, 6).."."..string.sub(strnumber, 7);
		dlgSaisie:GetWindowName("heure"..idx):SetValue(strnumber);
	end
end

function OnChangeBib(i)
	local row = i -1;
	local bib = dlgSaisie:GetWindowName("bib"..i):GetValue();
	heure_depart, heure_arrivee = GetHeuresCoureur(bib);
	PG_TempsManuel:SetCell('Heure_depart', row, heure_depart);
	PG_TempsManuel:SetCell('Heure_arrivee', row, heure_arrivee);
	local r = Resultat:GetIndexRow('Dossard', bib);
	if r and r >= 0 then
		dlgSaisie:GetWindowName("identite"..i):SetValue(Resultat:GetCell('Nom', r)..' '..Resultat:GetCell('Prenom', r));
		TM.ligne[i].bib = Resultat:GetCell('Dossard', r);
	else
		dlgSaisie:GetWindowName("identite"..i):SetValue('');
		return;
	end
	if TM.impulsion == 'D�part' then
		int_heure = heure_depart;
		heure = app.TimeToString(heure_depart, params.fmt);
		if int_heure == 0 then
			dlgSaisie:GetWindowName("heure"..i):SetValue('Abs');
		end
	else
		int_heure = heure_arrivee;
		heure = app.TimeToString(heure_arrivee, params.fmt);
	end
	if int_heure == 0 then
		return;
	end
	PG_TempsManuel:SetCell('Code_evenement', row, params.code_evenement);
	PG_TempsManuel:SetCell('Code_manche', row, params.code_manche);
	PG_TempsManuel:SetCell('Code_coureur', row, Resultat:GetCell('Code_coureur', r));
	PG_TempsManuel:SetCell('Dossard', row, bib);
	PG_TempsManuel:SetCell('Dossard_calcul', row, TM.dossard);
	PG_TempsManuel:SetCell('Rang', row, i);
	PG_TempsManuel:SetCell('Nom', row, Resultat:GetCell('Nom', r));
	PG_TempsManuel:SetCell('Prenom', row, Resultat:GetCell('Prenom', r));
	PG_TempsManuel:SetCell('Comite', row, Resultat:GetCell('Comite', r));
	PG_TempsManuel:SetCell('Nation', row, Resultat:GetCell('Nation', r));
	PG_TempsManuel:SetCell('Coureur', row, 0);
	PG_TempsManuel:SetCell('OK', row, 1);
	heure_depart, heure_arrivee = GetHeuresCoureur(bib);
	PG_TempsManuel:SetCell('Heure_depart', row, heure_depart);
	PG_TempsManuel:SetCell('Heure_arrivee', row, heure_arrivee);
	if TM.impulsion == 'D�part' then
		PG_TempsManuel:SetCell('Impulsion', row, 'D');
		int_heure = heure_depart;
		heure = app.TimeToString(heure_depart, params.fmt);
	else
		PG_TempsManuel:SetCell('Impulsion', row, 'A');
		int_heure = heure_arrivee;
		heure = app.TimeToString(heure_arrivee, params.fmt);
	end
	dlgSaisie:GetWindowName('heure'..i):SetValue(heure);
	PG_TempsManuel:SetCellNull('Doublage', row);
	PG_TempsManuel:SetCellNull('Delta', row);
	TM.ligne[i].identite = PG_TempsManuel:GetCell('Nom', row).." "..PG_TempsManuel:GetCell('Prenom', row);
	TM.ligne[i].int_heure = int_heure;
	TM.ligne[i].heure = heure;
	-- TM.ligne[i].int_doublage = PG_TempsManuel:GetCellInt('Doublage', row);
	-- TM.ligne[i].doublage = app.TimeToString(TM.ligne[i].int_doublage, params.fmt);
	-- TM.ligne[i].delta = PG_TempsManuel:GetCellInt('Delta', row);
	TM.ligne[i].int_doublage = 0;
	TM.ligne[i].doublage = '';
	TM.ligne[i].delta = 0;
	base:TableUpdate(PG_TempsManuel, row);
	PG_TempsManuel:OrderBy('Rang');
end

function OnRead(dossard, code_manche)
	local cmd = "Select * From PG_TempsManuel Where"..
			" Code_evenement = "..params.code_evenement..
			" And Code_manche = "..params.code_manche..
			" And Dossard_calcul = '"..TM.dossard.."' "..
			" Order By Rang";
	base:TableLoad(PG_TempsManuel, cmd)
	-- LoadResultatChrono(params.code_evenement, params.code_manche);
	params.impulsion = PG_TempsManuel:GetCell("Impulsion", 0)
	TM.row_coureur = -1;
	params.millisecondes = 0;
	for row = 0, PG_TempsManuel:GetNbRows()-1  do
		idx = row + 1;
		TM.ligne[idx] = {};
		local heure = ''; local int_heure = 0;
		if PG_TempsManuel:GetCellInt('Coureur', row) == 0 then
			if TM.impulsion == 'D�part' then
				int_heure = PG_TempsManuel:GetCellInt('Heure_depart', row);
				heure = app.TimeToString(int_heure, params.fmt)
			else
				int_heure = PG_TempsManuel:GetCellInt('Heure_arrivee', row);
				heure = app.TimeToString(int_heure, params.fmt)
			end
		else
			TM.row_coureur = row;
			TM.idx_coureur = idx;
			dlgSaisie:GetWindowName('heure'..row+1):Enable(false);
		end
		TM.ligne[idx].bib = PG_TempsManuel:GetCell('Dossard', row);
		TM.ligne[idx].identite = PG_TempsManuel:GetCell('Nom', row).." "..PG_TempsManuel:GetCell('Prenom', row);
		TM.ligne[idx].int_heure = int_heure;
		TM.ligne[idx].heure = heure;
		TM.ligne[idx].int_doublage = PG_TempsManuel:GetCellInt('Doublage', row);
		TM.ligne[idx].doublage = app.TimeToString(TM.ligne[idx].int_doublage, params.fmt);
		TM.ligne[idx].delta = PG_TempsManuel:GetCellInt('Delta', row);
		
		dlgSaisie:GetWindowName("bib"..idx):SetValue(TM.ligne[idx].bib);
		dlgSaisie:GetWindowName("identite"..idx):SetValue(TM.ligne[idx].identite);
		dlgSaisie:GetWindowName("heure"..idx):SetValue(TM.ligne[idx].heure);
		dlgSaisie:GetWindowName("doublage"..idx):SetValue(TM.ligne[idx].doublage);
		if math.abs(TM.ligne[idx].delta) > 0 then
			dlgSaisie:GetWindowName("delta"..idx):SetValue(TM.ligne[idx].delta);
		end
	end
	SetCtrlEnable(false);
	OnChangeDelta();
end

function SetHeureCalculee()
	params.millisecondes = params.millisecondes or 0;
	params.SommeMilliPar10 = params.millisecondes / 10
	if params.SommeMilliPar10 > 0 then
		params.SommeMilliPar10 = params.SommeMilliPar10 + 0.5;
		params.SommeMilliPar10 = math.floor(params.SommeMilliPar10);
	elseif params.SommeMilliPar10 < 0 then
		params.SommeMilliPar10 = params.SommeMilliPar10 - 0.5;
		params.SommeMilliPar10 = math.ceil(params.SommeMilliPar10);
	end
	params.HeureDoublage = TM.ligne[TM.idx_coureur].doublage
	params.HeureCalculee = app.TimeToString(TM.ligne[TM.idx_coureur].int_doublage + params.SommeMilliPar10, params.fmt);
	-- dlgSaisie:GetWindowName("millisecondes"):SetValue(params.millisecondes);
	-- dlgSaisie:GetWindowName("heure"..TM.idx_coureur):SetValue(params.HeureCalculee);
	local heure_depart = 0; local heure_arrivee = 0; params.tps = 0;
	if TM.impulsion == 'D�part' then
		if PG_TempsManuel:GetCellInt('Heure_arrivee', TM.row_coureur) > 0 then
			params.tps = PG_TempsManuel:GetCellInt('Heure_arrivee', TM.row_coureur) - (TM.ligne[TM.idx_coureur].int_doublage + params.SommeMilliPar10);
		end
	else
		if PG_TempsManuel:GetCellInt('Heure_depart', TM.row_coureur) > 0 then
			params.tps = (TM.ligne[TM.idx_coureur].int_doublage + params.SommeMilliPar10) - PG_TempsManuel:GetCellInt('Heure_depart', TM.row_coureur);
		end
	end
	if params.tps > 0 then
		params.tps = app.TimeToString(params.tps, params.fmt2);
	else
		params.tps = 'non calculable';
	end
	return true;
end

function OnSaisieDlg1()
	local widthMax = display:GetSize().width;
	local widthControl = math.floor((widthMax*3)/4);
	local x = math.floor((widthMax-widthControl)/2);

	local heightMax = display:GetSize().height;
	local heightControl = math.floor((heightMax *3) / 4);
	local y = math.floor((heightMax-heightControl)/2);

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgConfig = wnd.CreateDialog({
		x = x,
		y = y,
		width=widthControl, 
		height=heightControl, 
		label='Calcul d\'un temps manuel - version '..script_version, 
		icon='./res/32x32_chrono.png'
	});
	dlgConfig:LoadTemplateXML({ 
		xml = './edition/tempsManuel.xml', 	
		node_name = 'root/panel', 			
		node_attr = 'name', 				
		node_value = 'page1' 				
	});
	-- affichage des data

	local race = params.evenement_nom:Split('%\n');
	race = race[1];
	dlgConfig:GetWindowName('race'):SetValue(race);
	dlgConfig:GetWindowName('dossard'):SetValue('');
	dlgConfig:GetWindowName('identite'):SetValue('');
		
	dlgConfig:GetWindowName("impulsion"):Append('D�part');
	dlgConfig:GetWindowName("impulsion"):Append('Arriv�e');
	dlgConfig:GetWindowName("impulsion"):SetSelection(0);
	for i = 1, params.nb_manche do
		dlgConfig:GetWindowName("manche"):Append(i);
	end
	dlgConfig:GetWindowName("manche"):SetSelection(0);
	-- -- Toolbar Principale ...
	local tbh = dlgConfig:GetWindowName('tbh');
	tbh:AddStretchableSpace();
	local btnNext = tbh:AddTool("Suite", "./res/vpe32x32_page_next.png");
	tbh:AddSeparator();
	local btnRead = tbh:AddTool("Charger le calcul", "./res/32x32_refresh.png");
	tbh:AddSeparator();
	local btnClose = tbh:AddTool("Fermer", "./res/32x32_quit.png");
	tbh:AddStretchableSpace();
	tbh:Realize();
	
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
			OnChangeDossard()
		end,  
		dlgConfig:GetWindowName('dossard'));
										  
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
			OnChangeDossardPrecedent(dlgConfig:GetWindowName('dossard_precedent'):GetValue());
		end,  
		dlgConfig:GetWindowName('dossard_precedent'));
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeImpulsion(dlgConfig:GetWindowName('impulsion'):GetValue(), tonumber(dlgConfig:GetWindowName('manche'):GetValue()))
		end,  
		dlgConfig:GetWindowName('impulsion'));

	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeManche(tonumber(dlgConfig:GetWindowName('manche'):GetValue()))
		end,  
		dlgConfig:GetWindowName('manche'));

	tbh:Bind(eventType.MENU, 
		function(evt)
			params.code_manche = tonumber(dlgConfig:GetWindowName('manche'):GetValue());
			TM.impulsion = dlgConfig:GetWindowName('impulsion'):GetValue();
			TM.dossard = dlgConfig:GetWindowName('dossard'):GetValue();
			params.dossard_precedent = dlgConfig:GetWindowName('dossard_precedent'):GetValue();
			OK = ControleData()
			if OK == true then
				local msg = "Toutes les donn�es de doublage existante seront effac�es.\nVoulez-vous poursuivre ?";
				if app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.YES_NO+msgBoxStyle.ICON_WARNING) == msgBoxStyle.YES then 
					OnSaisieDlg2()
				end
			end
			dlgConfig:EndModal(idButton.OK);
		end, 
		btnNext)

	tbh:Bind(eventType.MENU, 
		function(evt) 
			TM.lire = true;
			params.code_manche = tonumber(dlgConfig:GetWindowName('manche'):GetValue());
			TM.impulsion = dlgConfig:GetWindowName('impulsion'):GetValue();
			TM.dossard = dlgConfig:GetWindowName('dossard'):GetValue();
			if tonumber(TM.dossard) then
				OnSaisieDlg2();
			else
				msg = "Veuillez indiquer le dossard et le n� de manche !!";
				app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
			end		
		end,
		btnRead)
		
		tbh:Bind(eventType.MENU, 
		function(evt) 
			params.sortir = true;
			dlgConfig:EndModal(idButton.CANCEL);
		end, 
		btnClose)
	
	-- -- Ouverture de la boite de Dialogue 
	dlgConfig:ShowModal();
	
	if TM.Table ~= nil then
		TM.Table:Delete();
	end
end

function OnSaisieDlg2()
	local widthMax = display:GetSize().width;
	local widthControl = math.floor((widthMax*3)/4);
	local x = math.floor((widthMax-widthControl)/2);

	local heightMax = display:GetSize().height;
	local heightControl = math.floor((heightMax *3) / 4);
	local y = math.floor((heightMax-heightControl)/2);
	dlgSaisie = wnd.CreateDialog({
		x = x,
		y = y,
		width=widthControl, 
		height=heightControl, 
		label='Calcul d\'un temps manuel', 
		icon='./res/32x32_chrono.png'
	});
	dlgSaisie:LoadTemplateXML({ 
		xml = './edition/tempsManuel.xml', 	
		node_name = 'root/panel', 			
		node_attr = 'name', 				
		node_value = 'saisie' 				
	});
	if TM.lire == true then
		OnRead(dlgConfig:GetWindowName('dossard'):GetValue(), tonumber(dlgConfig:GetWindowName('manche'):GetValue()))
		if PG_TempsManuel:GetNbRows() ~= 11 then
			msg = "Il n'y a aucun calcul correspondant � ces donn�es !!";
			app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
			return;
		end
	end

	local txt = "Calcul de l'heure de "..TM.impulsion.." en manche "..params.code_manche.." \npour le dossard "..TM.dossard.. " : "..params.Identite;
	dlgSaisie:GetWindowName("what"):SetValue(txt);
		
	if TM.lire == false then
		-- si on ne lit pas un calcul pr�c�dent il faut construire toutes les tables utiles dans SetData()
		SetData(nil, nil);
	end
	TM.date = os.date("%d/%m/%Y %X");
	-- Toolbar Principale ...
	local tbh2 = dlgSaisie:GetWindowName('tbh2');
	tbh2:AddStretchableSpace();
	local btnPrint = tbh2:AddTool("Calculer", "./res/32x32_chrono_v1.png");
	tbh2:AddStretchableSpace();
	local btnClose = tbh2:AddTool("Fermer", "./res/32x32_quit.png");
	tbh2:AddStretchableSpace();
	-- if TM.lire == true then
		-- tbh2:EnableTool(btnPrevious:GetId(), false);
	-- end

	tbh2:Realize();
	
	-- tbh2:Bind(eventType.MENU, 
		-- function(evt) 
			-- dlgSaisie:EndModal(idButton.CANCEL);
		-- end, 
		-- btnPrevious); 

	tbh2:Bind(eventType.MENU, 
		function(evt)
			OnValidation();
			OnPrint()
			dlgSaisie:EndModal(idButton.OK);
		end, 
		btnPrint)

	tbh2:Bind(eventType.MENU, 
		function(evt) 
			dlgSaisie:EndModal(idButton.CANCEL);
		end, 
		btnClose)

	for i = 1, 11 do
		dlgSaisie:Bind(eventType.TEXT, 
			function(evt) 
				OnChangeBib(i);
			end,  dlgSaisie:GetWindowName('bib'..i));
		dlgSaisie:Bind(eventType.TEXT, 
			function(evt) 
				OnChangeHeure(i);
			end,  dlgSaisie:GetWindowName('heure'..i));
		dlgSaisie:Bind(eventType.TEXT, 
			function(evt) 
				OnChangeDoublage(i);
			end,  dlgSaisie:GetWindowName('doublage'..i));
	end
	-- Ouverture de la boite de Dialogue 
	dlgSaisie:Fit();
	if dlgSaisie:ShowModal() == idButton.OK then
		dlgConfig:EndModal();
	end	
	if TM.Table ~= nil then
		TM.Table:Delete();
	end
end

function GetHeuresCoureur(bib);
	local h_depart = 0; h_arrivee = 0;
	local r1 = tDeparts:GetIndexRow('Dossard', bib);
	if r1 and r1 >= 0 then
		h_depart = tDeparts:GetCellInt('Heure', r1)
	end
	local r2 = tArrivees:GetIndexRow('Dossard', bib);
	if r2 and r2 >= 0 then
		h_arrivee = tArrivees:GetCellInt('Heure', r2);
	end
	return h_depart, h_arrivee;
end

function SetCtrlEnable(enable)
	for idx = 1, 11 do
		local row = idx - 1;
		local bib = dlgSaisie:GetWindowName('bib'..idx):GetValue();
		-- dlgSaisie:GetWindowName('bib'..idx):Enable(enable);
		dlgSaisie:GetWindowName('identite'..idx):Enable(enable);
		dlgSaisie:GetWindowName('heure'..idx):Enable(enable);
		if enable == true then
			-- dlgSaisie:GetWindowName('bib'..idx):SetValue('');
			dlgSaisie:GetWindowName('identite'..idx):SetValue('');
			dlgSaisie:GetWindowName('heure'..idx):SetValue('');
			dlgSaisie:GetWindowName('doublage'..idx):SetValue('');
			dlgSaisie:GetWindowName('delta'..idx):SetValue('');
		end
		if dlgSaisie:GetWindowName('bib'..idx):GetValue() == TM.dossard_precedent then
			TM.RangPrecedent = idx -1;
		end
		if dlgSaisie:GetWindowName('bib'..idx):GetValue() == TM.dossard then
			dlgSaisie:GetWindowName('heure'..idx):Enable(false);
		end
	end
end

function PopulatePG_Tempsmanuel()
	for idx = 1, 11 do
		local row = PG_TempsManuel:AddRow();
		PG_TempsManuel:SetCell('Code_evenement', row, params.code_evenement);
		PG_TempsManuel:SetCell('Code_manche', row, params.code_manche);
		PG_TempsManuel:SetCell('Dossard_calcul', row, TM.dossard);
		PG_TempsManuel:SetCell('OK', row, 1);
		PG_TempsManuel:SetCell('Impulsion', row, string.sub(TM.impulsion,1,1));
		PG_TempsManuel:SetCell('Date_calcul', row, TM.date);
	end
end

function ReplaceBib(indice)
	if dlgSaisie:GetWindowName('identite'..indice):GetValue():len() > 5 then
		if TM.impulsion == "D�part" then
			dlgSaisie:GetWindowName('heure'..indice):SetValue(PG_TempsManuel:GetCell('Heure_depart', indice-1));
		else
			dlgSaisie:GetWindowName('heure'..indice):SetValue(PG_TempsManuel:GetCell('Heure_arrivee', indice-1));
		end
	end
end

function SetData(force_rang, force_bib)
	-- on charge tous les d�parts et toutes les arriv�es
	if TM.impulsion == "D�part" then
		TM.Table = tDeparts:Copy();
	else
		TM.Table = tArrivees:Copy();
	end
	if TM.Table:GetNbRows() == 0 then
		local msg = "Le chronom�trage n'a pas �t� r�alis� en base de temps.\nVous devez saisir la totalit� des donn�es.";
		app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		SetCtrlEnable(true);
		PopulatePG_Tempsmanuel();
		return;
	end
	SetCtrlEnable(false);
	-- on supprime le dossard de la table si jamais il �tait pr�sent.
	for row = TM.Table:GetNbRows() -1, 0, -1 do
		if TM.Table:GetCell("Dossard", row) == TM.dossard then
			TM.Table:RemoveRowAt(row);
			break;
		end
	end
	local row_precedent = -1;
	if TM.dossard_precedent and TM.dossard_precedent:len() > 0 then
		row_precedent = TM.Table:GetIndexRow('Dossard', TM.dossard_precedent);  -- on cherche le row du dossard pr�c�dent. 
	-- si row_precedent > 9 , on en a 10 avant. On part de la fin, on efface jusqu'au dossard pr�c�dent, on en saute 10 et on efface le d�but.
	end
	if row_precedent > 9 then
		for row = TM.Table:GetNbRows() -1, 0, -1 do
			if row > row_precedent then
				TM.Table:RemoveRowAt(row);
			elseif row < row_precedent - 9 then
				TM.Table:RemoveRowAt(row);
			end
		end
	else	-- il y en a moins de 10 avant on part de la fin et on en garde 10 (row de 0 � 9)
		for row = TM.Table:GetNbRows() -1, 10, -1 do
			TM.Table:RemoveRowAt(row);
		end
	end
	-- on efface les lignes de PG_TempsManuel
	local cmd = "Delete From PG_TempsManuel Where"..
			" Code_evenement = "..params.code_evenement..
			" And Code_manche = "..params.code_manche..
			" And Dossard_calcul = '"..TM.dossard.."' ";
	base:Query(cmd);
	-- on ajoute les lignes dans PG_TempsManuel
	local rang = 0;
	if row_precedent == -1 then
		rang = rang + 1;
		TM.rang_dossard = 1;
		TM.row_coureur = 0;
	end
	for row = 0, TM.Table:GetNbRows()-1 do
		local row2 = PG_TempsManuel:AddRow();
		rang = rang + 1;
		local dossardlu = '';
		if force_rang ~= nil and force_bib ~= nil then
			if force_rang == rang then
				dossardlu = force_bib;
			end
		else	
			dossardlu = TM.Table:GetCell("Dossard", row);
		end
		local r = Resultat:GetIndexRow('Dossard', dossardlu);
		local h_depart, h_arrivee = GetHeuresCoureur(dossardlu);
		PG_TempsManuel:SetCell('Code_evenement', row2, params.code_evenement);
		PG_TempsManuel:SetCell('Code_manche', row2, params.code_manche);
		PG_TempsManuel:SetCell('Code_coureur', row2, Resultat:GetCell("Code_coureur", r));
		PG_TempsManuel:SetCell('Dossard_calcul', row2, TM.dossard);
		PG_TempsManuel:SetCell('Heure_depart', row2, h_depart);
		PG_TempsManuel:SetCell('Heure_arrivee', row2, h_arrivee);
		PG_TempsManuel:SetCell('Prenom', row2, Resultat:GetCell("Prenom", r));
		PG_TempsManuel:SetCell('Comite', row2, Resultat:GetCell("Comite", r));
		PG_TempsManuel:SetCell('Nation', row2, Resultat:GetCell("Nation", r));
		PG_TempsManuel:SetCell('Nom', row2, Resultat:GetCell("Nom", r));
		PG_TempsManuel:SetCell('Coureur', row2, 0);
		PG_TempsManuel:SetCell('Dossard', row2, dossardlu);
		PG_TempsManuel:SetCell('Rang', row2, rang);
		PG_TempsManuel:SetCell('OK', row2, 1);
		PG_TempsManuel:SetCell('Doublage', row2, 0);
		PG_TempsManuel:SetCell('Delta', row2, 0);
		PG_TempsManuel:SetCell('Impulsion', row2, string.sub(TM.impulsion,1,1));
		PG_TempsManuel:SetCell('Date_calcul', row2, TM.date);
		if dossardlu == TM.dossard_precedent then
			rang = rang + 1;
			TM.rang_dossard = rang;
		end
	end
	-- on ajoute le row du coureur cherch�
	local row2 = PG_TempsManuel:AddRow();
	local r = Resultat:GetIndexRow('Dossard', TM.dossard);
	local h_depart, h_arrivee = GetHeuresCoureur(TM.dossard);
	PG_TempsManuel:SetCell('Code_evenement', row2, params.code_evenement);
	PG_TempsManuel:SetCell('Code_manche', row2, params.code_manche);
	PG_TempsManuel:SetCell('Code_coureur', row2, Resultat:GetCell("Code_coureur", r));
	PG_TempsManuel:SetCell('Dossard_calcul', row2, TM.dossard);
	PG_TempsManuel:SetCell('Heure_depart', row2, h_depart);
	PG_TempsManuel:SetCell('Heure_arrivee', row2, h_arrivee);
	PG_TempsManuel:SetCell('Prenom', row2, Resultat:GetCell("Prenom", r));
	PG_TempsManuel:SetCell('Comite', row2, Resultat:GetCell("Comite", r));
	PG_TempsManuel:SetCell('Nation', row2, Resultat:GetCell("Nation", r));
	PG_TempsManuel:SetCell('Nom', row2, Resultat:GetCell("Nom", r));
	PG_TempsManuel:SetCell('Coureur', row2, 1);
	PG_TempsManuel:SetCell('Dossard', row2, TM.dossard);
	if row_precedent == -1 then
		TM.rang_dossard = 1;
	end
	PG_TempsManuel:SetCell('Rang', row2, TM.rang_dossard);
	PG_TempsManuel:SetCell('OK', row2, 1);
	PG_TempsManuel:SetCell('Doublage', row2, 0);
	PG_TempsManuel:SetCell('Delta', row2, 0);
	PG_TempsManuel:SetCell('Impulsion', row2, string.sub(TM.impulsion,1,1));
	PG_TempsManuel:SetCell('Date_calcul', row2, TM.date);
	
	-- tri de la table solon le Rang et affichage des data dans les contr�les
	PG_TempsManuel:OrderBy('Rang');
	for idx = 1, 11 do
		row = idx - 1;
		local bib = PG_TempsManuel:GetCell('Dossard', row);
		local identite = PG_TempsManuel:GetCell('Nom', row).." "..PG_TempsManuel:GetCell('Prenom', row);
		local heure = ''; local int_heure = 0
		assert(bib ~= nil);
		dlgSaisie:GetWindowName("bib"..idx):SetValue(bib);
		dlgSaisie:GetWindowName("identite"..idx):SetValue(identite);
		if PG_TempsManuel:GetCellInt('Coureur', row) == 0 then
			if TM.impulsion == 'D�part' then
				int_heure = PG_TempsManuel:GetCellInt('Heure_depart', row);
				heure = app.TimeToString(int_heure, params.fmt)
			else
				int_heure = PG_TempsManuel:GetCellInt('Heure_arrivee', row);
				heure = app.TimeToString(int_heure, params.fmt)
			end
		else
			TM.row_coureur = row;
			TM.idx_coureur = idx;
		end
		TM.ligne[idx].bib = bib;
		dlgSaisie:GetWindowName("doublage"..idx):SetValue('');
		dlgSaisie:GetWindowName("delta"..idx):SetValue('');
		if bib ~= TM.dossard then
			TM.ligne[idx].int_heure = int_heure;
			TM.ligne[idx].heure = heure;
			dlgSaisie:GetWindowName("heure"..idx):SetValue(TM.ligne[idx].heure);
		end
	end
	TM.BaseDeTemps = true;
end


function LoadResultatChrono(code_evenement)
	Resultat_Chrono = base:GetTable('Resultat_Chrono');
	cmd = "Select * From Resultat_Chrono Where Code_evenement = "..code_evenement..
		" And Id = 0 And ABS(Dossard) > 0 And Heure > 0 Order By Heure";
	base:TableLoad(Resultat_Chrono, cmd);
	tDeparts = Resultat_Chrono:Copy();
	ReplaceTableEnvironnement(tDeparts, 'tDeparts')

	cmd = "Select * From Resultat_Chrono Where Code_evenement = "..code_evenement..
		" And Id = -1 And ABS(Dossard) > 0 And Heure > 0 Order By Heure"
	base:TableLoad(Resultat_Chrono, cmd);
	tArrivees = Resultat_Chrono:Copy();
	ReplaceTableEnvironnement(tArrivees, 'tArrivees')
end

function main(params_c)
	if params_c == nil then
		return false;
	end

	base = base or sqlBase.Clone();
	params = params_c;
	script_version = 2.0;
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
	if app.GetVersion() >= '6.0' then 
		-- v�rification de l'existence d'une version plus r�cente du script.
		-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2
		indice_return = 15;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	end

	OK = true;
	params.code_manche = 1;
	params.nb_manche = 1;
	params.fmt = "%2h:%2m:%2s.%3f";
	params.fmt2 = "%-1h%-1m%2s.%2f";
	doublage = 0;

	TM = {};
	TM.ligne = {};
	TM.impulsion = "D�part";
	TM.dossard = nil;
	TM.dossardPrecedent = nil;
	TM.lire = false;
	TM.calculfait = false;
	PG_TempsManuel = base:GetTable('PG_TempsManuel');
	Resultat = base:GetTable('Resultat');
	base:TableLoad(Resultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	Evenement = base:GetTable('Evenement');
	base:TableLoad(Evenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	Interrogation();
	params.evenement_nom = Evenement:GetCell("Nom", 0);
	Epreuve = base:GetTable('Epreuve');
	base:TableLoad(Epreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	params.nb_manche = Epreuve:GetCellInt("Nombre_de_manche", 0, 1);
	TM.ligne = {};
	TM.RangPrecedent = -1;
	for idx = 1, 11 do
		TM.ligne[idx] = {};
		TM.ligne[idx].doublage = '';
		TM.ligne[idx].heure = '';
		TM.ligne[idx].int_doublage = 0;
		TM.ligne[idx].delta = 0;
		TM.ligne[idx].int_heure = 0;
	end
	OnChangeManche(1);
	OnSaisieDlg1();
end




