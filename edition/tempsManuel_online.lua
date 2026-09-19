-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');

local EEP_VERSION = "1.2"
local EET_VERSION = "1.25"

function OnSendJson()
	local impulse = 'START';
	if string.sub(TM.impulsion, 1, 1) == 'A' then
		impulse = 'FINISH';
	end
	TM.json = nil;
	local tRanking = base.CreateTableRanking({ code_evenement = params.code_evenement});	
	TM.r_dossard = tRanking:GetIndexRow('Dossard', TM.dossard);
	local calcul_id = dlgPage1:GetWindowName('calcul_id'):GetValue();
	local tRace = {season = tEvenement:GetCell('Code_saison', 0), codex = params.codex, run = TM.code_manche, missing_impulse = impulse, eet_bib = TM.dossard, location = tEvenement:GetCell('Station', 0), date =  tEpreuve:GetCell('Date_epreuve', 0, "%4Y-%2M-%2D"), discipline = tEpreuve:GetCell('Code_discipline', 0) };
	local tCompetitors = {};
	local eet_tod = '';
	if TM.et then
		eet_tod = TM.et;
	end
	for i = 0, tResultat_Chrono:GetNbRows() -1 do
		local dossard = tResultat_Chrono:GetCell('Dossard', i);
		if TM.et then -- system B toutes les impulsions sont là
			if dossard ~= TM.dossard then
				table.insert(tCompetitors, {bib = dossard, et_tod = tResultat_Chrono:GetCell('Heure', i, params.fmt)});
			else
				table.insert(tCompetitors, {bib = dossard, et_tod = tResultat_Chrono:GetCell('Heure', i, params.fmt), lastname = tRanking:GetCell('Nom', TM.r_dossard), firstname = tRanking:GetCell('Prenom', TM.r_dossard), nation = tRanking:GetCell('Nation', TM.r_dossard), club = tRanking:GetCell('Club', TM.r_dossard)});
			end
		else	-- system A impulsion manquante pour TM.dossard
			if TM.dossard_precedent == '' or tonumber(TM.dossard_precedent) == 0 then
				if i == 0 then
					table.insert(tCompetitors, {bib = TM.dossard, et_tod = "", lastname = tRanking:GetCell('Nom', TM.r_dossard), firstname = tRanking:GetCell('Prenom', TM.r_dossard), nation = tRanking:GetCell('Nation', TM.r_dossard), club = tRanking:GetCell('Club', TM.r_dossard)});
				end
				table.insert(tCompetitors, {bib = dossard, et_tod = tResultat_Chrono:GetCell('Heure', i, params.fmt)});
			else	-- on regarde TM.dossard_precedent et on met le EET juste après
				table.insert(tCompetitors, {bib = dossard, et_tod = tResultat_Chrono:GetCell('Heure', i, params.fmt)});
				if dossard == TM.dossard_precedent then
					table.insert(tCompetitors, {bib = TM.dossard, et_tod = eet_tod, lastname = tRanking:GetCell('Nom', TM.r_dossard), firstname = tRanking:GetCell('Prenom', TM.r_dossard), nation = tRanking:GetCell('Nation', TM.r_dossard), club = tRanking:GetCell('Club', TM.r_dossard)})
				end
			end
		end
	end
	local mode = "";
	if TM.mode == 'Test' then
		mode = "TEST";
	end
	
	tData = {calculation_id = calcul_id, mode = mode, race = tRace, competitors = tCompetitors};

	TM.json = table.ToStringJSON(tData, false)
	TM.document = tData;

	local file_temp = params.directory_tmp..'temp_EET.json';
	Write_json_to_send(TM.json);

	if not app.FileExists(file_temp) then
		return false;
	end

	if params.mode_localhost == true then
		rc, txtData = curl.POST_BINARY_JSON('http://localhost:5000/api/eep', params.json_out);
	else
		rc, txtData = curl.POST_BINARY_JSON('https://pg-chrono.fr/api/eep', params.json_out);
	end
	if rc then
		ReadRetour(txtData);
	end

end

function ChangeDate(strDate)
	-- Extraction de l'année, du mois et du jour
	local year, month, day = strDate:match("(%d%d%d%d)-(%d%d)-(%d%d)")

	-- Réorganisation au format JJ-MM-AAAA
	local output_date = string.format("%s-%s-%s", day, month, year)

	print(output_date) -- Résultat : "25-12-2026"

	return output_date
end

function base_name(path, match)
	return path:match("^.+[/\\](.+)$")
end

function file_root(name)
    -- retire l'extension ".xxx"
    return name:match("(.+)%.[^%.]+$")
end

function GetFiles(directory, mask)

    local tFiles =app.GetAllFiles(directory, mask);
    return tFiles
end

function Affiche_calculs(start)
	local idx_calcul = start;
	for i = 1, 20 do
		if idx_calcul <= #TM.liste_json then
			local document = TM.liste_json[idx_calcul].document
			local impulse = document.race.missing_impulse;
			local race_date = ChangeDate(document.race.date);
			if impulse == 'START' then
				impulse = 'Départ';
			else
				impulse = 'Arrivée';
			end
			dlgJson:GetWindowName('json_id'..i):SetValue(document.calculation_id);
			dlgJson:GetWindowName('saison'..i):SetValue(document.race.season);
			dlgJson:GetWindowName('date'..i):SetValue(race_date);
			dlgJson:GetWindowName('codex'..i):SetValue(document.race.codex);
			dlgJson:GetWindowName('manche'..i):SetValue(document.race.run);
			dlgJson:GetWindowName('dossard'..i):SetValue(document.race.eet_bib);
			dlgJson:GetWindowName('impulsion'..i):SetValue(impulse);
		else
			dlgJson:GetWindowName('json_id'..i):SetValue('');
			dlgJson:GetWindowName('saison'..i):SetValue('');
			dlgJson:GetWindowName('date'..i):SetValue('');
			dlgJson:GetWindowName('codex'..i):SetValue('');
			dlgJson:GetWindowName('manche'..i):SetValue('');
			dlgJson:GetWindowName('dossard'..i):SetValue('');
			dlgJson:GetWindowName('impulsion'..i):SetValue('');
		end
		idx_calcul = idx_calcul + 1;
	end	

end
function ChargerDocuments()
    TM.liste_json = {};
	local start_calcul = 1;
    local fichiers = GetFiles(
        "./EET_calculs",
        "*.json"
    )
    for _, filename in ipairs(fichiers) do
        local f = io.open(
            filename,
            "r"
        )
        if f then
            local contenu = f:read("*a")
            io.close(f)
            local tJson = table.FromStringJSON(
                contenu
            )
            if tJson then
                table.insert(
                    TM.liste_json,
                    {
                        filename = filename,
                        document = tJson,
                    }
                )
			else 
				adv.Alert('tJson = nil')
            end
        end
    end

	table.sort(TM.liste_json, CompareDocuments);

	local widthMax = display:GetSize().width;
	local widthControl = math.floor((widthMax*3)/4);
	local x = math.floor((widthMax-widthControl)/2);

	local heightMax = display:GetSize().height;
	local heightControl = math.floor((heightMax *3) / 4);
	local y = math.floor((heightMax-heightControl)/2);

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgJson = wnd.CreateDialog({
		x = x,
		y = y,
		width=widthControl, 
		height=heightControl, 
		parent = dlgPage1,
		label='Calculs existants', 
		icon='./res/32x32_chrono.png'
	});
	dlgJson:LoadTemplateXML({ 
		xml = './edition/tempsManuel_online.xml', 	
		node_name = 'root/panel', 			
		node_attr = 'name', 				
		node_value = 'json'
		})
	-- affichage des data
	
	Affiche_calculs(start_calcul);
	
	for i = 1, 20 do
		dlgJson:Bind(eventType.CHECKBOX, 
			function(evt) 
				if dlgJson:GetWindowName('chk'..i):GetValue() == true then
					dlgJson:GetWindowName('chk'..i):SetValue(false);
					if dlgJson:GetWindowName('json_id'..i):GetValue():len() > 0 then
						if params.mode_localhost == true then
							url = 'http://localhost:5000/api/calculation/'..dlgJson:GetWindowName('json_id'..i):GetValue();
						else
							url = 'https://pg-chrono.fr/api/calculation/'..dlgJson:GetWindowName('json_id'..i):GetValue();
						end
						app.LaunchDefaultBrowser(url);
					end
				end

			end,
		dlgJson:GetWindowName('chk'..i))
	end

	local tbjson = dlgJson:GetWindowName('tbjson');
	tbjson:AddStretchableSpace();
	local btnSuite = tbjson:AddTool("Suite", "./res/vpe32x32_page_next.png");
	tbjson:AddSeparator();
	local btnClose = tbjson:AddTool("Fermer", "./res/32x32_quit.png");
	tbjson:AddStretchableSpace();
	tbjson:Realize();
	
	if #TM.liste_json < 20 then
		tbjson:EnableTool(btnSuite:GetId(), false);
	else
		tbjson:EnableTool(btnSuite:GetId(), true);
	end

	tbjson:Bind(eventType.MENU, 
		function(evt) 
			dlgJson:EndModal(idButton.CANCEL);
		end, 
		btnClose)
		
	tbjson:Bind(eventType.MENU, 
		function(evt)
			start_calcul = start_calcul + 20;
			if start_calcul >= #TM.liste_json then
				start_calcul = 1;
			end
			Affiche_calculs(start_calcul);
		end, 
		btnSuite)

	
	-- -- Ouverture de la boite de Dialogue 
	dlgJson:Fit();
	dlgJson:ShowModal();
end

function CompareDocuments(a, b)

    local ra = a.document.race
    local rb = b.document.race

    -- Saison décroissante
    if ra.season ~= rb.season then
        return ra.season > rb.season
    end

    -- Date décroissante
    if ra.date ~= rb.date then
        return ra.date > rb.date
    end

    -- Codex croissant
    if ra.codex ~= rb.codex then
        return ra.codex < rb.codex
    end

    -- Manche croissante
    local runA = tonumber(ra.run) or 0
    local runB = tonumber(rb.run) or 0
    if runA ~= runB then
        return runA < runB
    end

    -- Dossard croissant
    local bibA = tonumber(ra.eet_bib) or 0
    local bibB = tonumber(rb.eet_bib) or 0
    if bibA ~= bibB then
        return bibA < bibB
    end

    -- Impulsion manquante
    return ra.missing_impulse < rb.missing_impulse

end

function Write_json(calculation_id)
    if not TM.document then
        return false, "TM.document is nil"
    end

	local filename = params.directory_calculs ..calculation_id..'.json';

    local f, err = io.open(filename, "w")
    if not f then
        return false, err
    end
    local ok, err = f:write(table.ToStringJSON(TM.document));
    f:close()

    if not ok then
        return false, err
    end

    return true
end

function Write_json_tmp(txt_json, file_name)
    local f, err = io.open(file_name, "w")
    if not f then
        return false, err
    end
    local ok, err = f:write(txt_json)
    f:close()
    if not ok then
        return false, err
    end
    return true
end

function Write_json_to_send()
    if not TM.json then
        return false, "TM.json is nil"
    end
	local filename = params.directory_tmp .."temp_EET.json";
    local f, err = io.open(filename, "w")
    if not f then
        return false, err
    end
    local ok, err = f:write(table.ToStringJSON(TM.document, false))
    f:close()
    if not ok then
        return false, err
    end
    return true
end

function VersionToTable(version)
    local t = {}
    for n in string.gmatch(
        version,
        "%d+"
    ) do
        table.insert(
            t,
            tonumber(n)
        )
    end
    return t
end

function CompareVersions(v1, v2)

    local t1 = VersionToTable(v1)
    local t2 = VersionToTable(v2)
    local n = math.max(
        #t1,
        #t2
    )
    for i = 1, n do
        local a = t1[i] or 0
        local b = t2[i] or 0
        if a < b then
            return -1
        elseif a > b then
            return 1
        end
    end
    return 0
end

function ExtraireVersion(message)
    return string.match(
        message,
        "(%d+[%d%.]*)"
    )

end

function ReadRetour(chaine)
    local tRetour = table.FromStringJSON(chaine)
    if not tRetour then
        return
    end
    local strmessage = ""

    -- Lecture des messages

    if type(tRetour.messages) == "table" then
        for _, message in ipairs(tRetour.messages) do
            if string.find(
                message,
                "EEP protocol"
            ) then
                local version = ExtraireVersion(
                    message
                )
                if CompareVersions(
                    version,
                    EEP_VERSION
                ) > 0 then
					if strmessage ~= "" then
						strmessage = strmessage .. "\n"
					end
					strmessage = strmessage ..
                        "Le serveur implémente une version plus récente du protocole EEP ("..
                        version..")."                  
                end
            elseif string.find(
                message,
                "EET Calculator"
            ) then
                local version = ExtraireVersion(
                    message
                )
				if CompareVersions(
					version,
					EET_VERSION
				) > 0 then
					if strmessage ~= "" then
						strmessage = strmessage .. "\n"
					end
					strmessage = strmessage ..
						"Le serveur utilise une version plus récente de l'EET Calculator (" ..
						version .. ")."
				end
            else
                if strmessage ~= "" then
                    strmessage = strmessage..", "
                end
                strmessage = strmessage..message
            end
        end
    end

    -- Traitement du statut

	if tRetour.status == "ok" then
		TM.calcul_id = tostring(
			tRetour.calculation_id
		)
		dlgPage1:GetWindowName(
			"calcul_id"
		):SetValue(
			TM.calcul_id
		)
		-- Met à jour le document avant
		-- de l'enregistrer localement
		TM.document.calculation_id = TM.calcul_id;
		if strmessage == "" then
			strmessage = "Calcul accepté."
		else
			strmessage = "Calcul accepté.\n"..strmessage;
		end
		local ok, err = Write_json(
			TM.calcul_id
		)		
        if not ok then
            adv.Alert(
                "Le calcul a été accepté.\n\n" ..
                "Calculation ID : " ..
                TM.calcul_id ..
                "\n\nLa sauvegarde locale a échoué.\n" ..
                tostring(err)
            )
        end
    elseif tRetour.status == "warning" then
        if strmessage == "" then
            strmessage = "Le calcul contient des avertissements."
        end
    elseif tRetour.status == "error" then
        if strmessage == "" then
            strmessage = "Erreur inconnue."
        end
    else
        adv.Alert(
            "Statut de réponse inconnu."
        )
    end
    if strmessage ~= "" then
        dlgPage1:GetWindowName(
            "message"
        ):SetValue(
            strmessage
        )
    end
end

function OnSynchroCalculs()
	local tFiles = GetFiles(params.directory_calculs, '*.json');
	if #tFiles == 0 then
		return;
	end
	for i = 1, #tFiles do
		tFiles[i] = base_name(tFiles[i]);
		tFiles[i] = file_root(tFiles[i]);
	end
	local tData = {calculation_ids = tFiles};
	local txt_json = table.ToStringJSON(tData, false);
	local file_name = params.directory_tmp..'temp_check.json';
	local bolOK = Write_json_tmp(txt_json, file_name);

	if not bolOK then
		adv.Alert(' Erreur dans la création du fichier temporaire '..file_name);
		return false;
	end
	if params.mode_localhost == true then
		rc, txtData = curl.POST_BINARY_JSON('http://localhost:5000/api/calculations/check', params.json_check);
	else
		rc, txtData = curl.POST_BINARY_JSON('https://pg-chrono.fr/api/calculations/check', params.json_check);
	end
	if rc then
		local retour = table.FromStringJSON(txtData)
		for calculation_id, info in pairs(retour.calculations) do
			if not info.exists then
				app.RemoveFile(
					params.directory_calculs ..
					calculation_id ..
					".json"
				)
			end
		end
	end
end

function OnSaisieDlg1()
	OnSynchroCalculs();
	local widthMax = display:GetSize().width;
	local widthControl = math.floor((widthMax*3)/4);
	local x = math.floor((widthMax-widthControl)/2);

	local heightMax = display:GetSize().height;
	local heightControl = math.floor((heightMax *3) / 4);
	local y = math.floor((heightMax-heightControl)/2);

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgPage1 = wnd.CreateDialog({
		x = x,
		y = y,
		width=widthControl, 
		height=heightControl, 
		label='Calcul d\'un temps manuel', 
		icon='./res/32x32_chrono.png'
	});
	dlgPage1:LoadTemplateXML({ 
		xml = './edition/tempsManuel_online.xml', 	
		node_name = 'root/panel', 			
		node_attr = 'name', 				
		node_value = 'page1' 				
	});
	-- affichage des data

	local race = params.evenement_nom:Split('%\n');
	race = race[1];
	dlgPage1:GetWindowName('race'):SetValue(race);
	dlgPage1:GetWindowName('dossard'):SetValue('');
	dlgPage1:GetWindowName('identite'):SetValue('');
		
	dlgPage1:GetWindowName("impulsion"):Append('Départ');
	dlgPage1:GetWindowName("impulsion"):Append('Arrivée');
	dlgPage1:GetWindowName("impulsion"):SetSelection(0);
	
	dlgPage1:GetWindowName("mode"):Append('Réel');
	dlgPage1:GetWindowName("mode"):Append('Test');
	dlgPage1:GetWindowName("mode"):SetSelection(0);

	for i = 1, params.nb_manche do
		dlgPage1:GetWindowName("manche"):Append(i);
	end
	dlgPage1:GetWindowName("manche"):SetSelection(0);
	-- -- Toolbar Principale ...
	local tbh = dlgPage1:GetWindowName('tbh');
	tbh:AddStretchableSpace();
	local btnSend = tbh:AddTool("Envoyer les données", "./res/32x32_calc.png");
	tbh:AddSeparator();
	local btnRecherche = tbh:AddTool("Recherche de vos calculs", "./res/32x32_search.png");
	tbh:AddSeparator();
	local btnVisu = tbh:AddTool("Voir le calcul en ligne", "./res/32x32_calc.png");
	tbh:AddSeparator();
	local btnTuto = tbh:AddTool("Voir le tutoriel en ligne", "./res/vpe32x32_help.png");
	tbh:AddSeparator();
	local btnClose = tbh:AddTool("Fermer", "./res/32x32_quit.png");
	tbh:AddStretchableSpace();
	tbh:Realize();
	
	tbh:EnableTool(btnVisu:GetId(), false);
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);

	dlgPage1:Bind(eventType.TEXT, 
		function(evt) 
			TM.dossard = dlgPage1:GetWindowName('dossard'):GetValue();
			TM.dossard_precedent = dlgPage1:GetWindowName('dossard_precedent'):GetValue();
			TM.code_manche = dlgPage1:GetWindowName('manche'):GetSelection() + 1;
			TM.impulsion = dlgPage1:GetWindowName('impulsion'):GetValue();
			TM.mode = dlgPage1:GetWindowName('mode'):GetValue();
			local identite = EstPresent(TM.dossard, TM.code_manche, 'eet')
			dlgPage1:GetWindowName('identite'):SetValue(identite);
		end,  
		dlgPage1:GetWindowName('dossard'));
										  
	dlgPage1:Bind(eventType.TEXT, 
		function(evt) 
			TM.dossard = dlgPage1:GetWindowName('dossard'):GetValue();
			TM.dossard_precedent = dlgPage1:GetWindowName('dossard_precedent'):GetValue();
			TM.code_manche = dlgPage1:GetWindowName('manche'):GetSelection() + 1;
			TM.impulsion = dlgPage1:GetWindowName('impulsion'):GetValue();
			TM.mode = dlgPage1:GetWindowName('mode'):GetValue();
			local identite = EstPresent(TM.dossard_precedent, TM.code_manche, 'precedent')
			dlgPage1:GetWindowName('identite_precedente'):SetValue(identite);
		end,  
		dlgPage1:GetWindowName('dossard_precedent'));
	dlgPage1:Bind(eventType.TEXT, 
		function(evt) 
			local calculation_id = dlgPage1:GetWindowName('calcul_id'):GetValue();
			if calculation_id:len() == 6 then
				tbh:EnableTool(btnVisu:GetId(), true);
			else
				tbh:EnableTool(btnVisu:GetId(), false);
			end
		end,  
		dlgPage1:GetWindowName('calcul_id'));

	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt)
			TM.dossard = dlgPage1:GetWindowName('dossard'):GetValue();
			TM.dossard_precedent = dlgPage1:GetWindowName('dossard_precedent'):GetValue();
			TM.code_manche = dlgPage1:GetWindowName('manche'):GetSelection() + 1;
			TM.impulsion = dlgPage1:GetWindowName('impulsion'):GetValue();
			TM.mode = dlgPage1:GetWindowName('mode'):GetValue();
		end,  
		dlgPage1:GetWindowName('impulsion'));

	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			TM.code_manche = tonumber(dlgPage1:GetWindowName('manche'):GetValue());
		end,  
		dlgPage1:GetWindowName('manche'));

	tbh:Bind(eventType.MENU, 
		function(evt)
			TM.dossard = dlgPage1:GetWindowName('dossard'):GetValue();
			TM.dossard_precedent = dlgPage1:GetWindowName('dossard_precedent'):GetValue();
			TM.code_manche = dlgPage1:GetWindowName('manche'):GetValue();
			TM.impulsion = dlgPage1:GetWindowName('impulsion'):GetValue();
			TM.calcul_id = dlgPage1:GetWindowName('calcul_id'):GetValue();
			TM.mode = dlgPage1:GetWindowName('mode'):GetValue();
			if TM.dossard:len() == 0 then
				dlgPage1:GetWindowName('message'):SetValue('Dossard / EET vide !!');
				return;
			end
			local bolOK = SetData();
			if bolOK == false then
				return;
			end
			local msg = "";
			if TM.calcul_id:len() > 0 then
				msg = "Confirmer l'envoi des données du système B \n"..
						"Vous allez compléter les données du calcul en envoyant\n"..
						"les impulsions comme Temps Manuels";
			else
				msg = "Confirmer l'envoi des données du système A \n"..
					"Vous allez initier un nouveau calcul en envoyant\n"..
					"les impulsions comme Temps Electroniques";
			end
			if dlgPage1:MessageBox(msg, 
				"Attention !!!",
				msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_WARNING
				) == msgBoxStyle.NO then
				return;
			end
			-- if TM.calcul_id:len() == 0 then
			-- end
			OnSendJson();
		end, 
		btnSend)
		
	tbh:Bind(eventType.MENU, 
		function(evt) 
			ChargerDocuments()
		end, 
		btnRecherche)

	tbh:Bind(eventType.MENU, 
		function(evt) 
			local calculation_id = dlgPage1:GetWindowName('calcul_id'):GetValue();
			if params.mode_localhost == true then
				url = 'http://localhost:5000/api/calculation/'..calculation_id;
			else
				url = 'https://pg-chrono.fr/api/calculation/'..calculation_id;
			end
			app.LaunchDefaultBrowser(url);
		end, 
		btnVisu)

	tbh:Bind(eventType.MENU, 
		function(evt) 
			url = 'https://agilsport.fr/bta_alpin/tuto/Calcul_EET_en_ligne.pdf';
			app.LaunchDefaultBrowser(url);
		end, 
		btnTuto)

	tbh:Bind(eventType.MENU, 
		function(evt) 
			dlgPage1:EndModal(idButton.CANCEL);
		end, 
		btnClose)
	
	-- -- Ouverture de la boite de Dialogue 
	dlgPage1:Fit();
	dlgPage1:ShowModal();
end

function EstPresent(dossard, manche, type_dossard)  -- le dossard précédent doit avoir un temps et le dossard ne doit pas en avoir
	local identite = '????';
	local r = tResultat:GetIndexRow('Dossard', tonumber(dossard));
	if r and r >= 0 then
		identite = tResultat:GetCell('Nom', r)..' '..tResultat:GetCell('Prenom', r);
		if type_dossard == 'eet' then
			TM.r_dossard = r;
		else
			TM.r_dossard_precedent = r;
		end
	end
	-- on charge les données de chronométrage
	local cmd = "SELECT * From Resultat_Chrono Where Code_evenement = "..params.code_evenement..' AND Code_manche = '..manche..
		" AND Origine = '"..string.sub(TM.impulsion,1,1).."' AND Dossard = '"..dossard.."' AND Heure > 0";
	base:TableLoad(tResultat_Chrono, cmd);
	if type_dossard == 'eet' then	-- cas du dossard 
		if tResultat_Chrono:GetNbRows() > 0 then
			identite = identite..' a une impulsion en manche '..TM.code_manche.. ' !!!';
		end
	else		-- cas du dossard précédent
		if tResultat_Chrono:GetNbRows() == 0 then
			identite = identite..' est DNS en manche '..TM.code_manche.. ' !!!';
		end
		if TM.dossardPrecedent == '' then
			identite = '';
		end
	end
	return identite;
end

function GetDqp(origine)
	local tDossardDQP = {};
	local cmd = "SELECT A.*, B.Dossard" ..
		" FROM Resultat_manche AS A"..
		" JOIN Resultat AS B "..
		" ON A.Code_coureur = B.Code_coureur AND A.Code_evenement = B.Code_evenement"..
        " WHERE A.Code_evenement = "..params.code_evenement..
		" AND A.Tps_Chrono = -809";
	tResultat_Chrono_DQP = base:TableLoad(cmd);	-- tous les DQP
	for i = 0, tResultat_Chrono_DQP:GetNbRows() -1 do
		local dossard = tResultat_Chrono_DQP:GetCell('Dossard', i);
		local r = tResultat_Chrono:GetIndexRow('Dossard_anc', dossard);
		table.insert(tDossardDQP, {Dossard = dossard});
	end
	tResultat_Chrono_DQP:Delete();
	return tDossardDQP;
end

function SetData()
	local bolOK = true;
	local origine = string.sub(TM.impulsion,1,1);
	-- on charge les données
	local cmd = "SELECT * From Resultat_Chrono Where Code_evenement = "..params.code_evenement..' AND Code_manche = '..TM.code_manche..
		" AND Origine = '"..origine.."' AND ABS(Dossard) > 0";
	base:TableLoad(tResultat_Chrono, cmd);
	if tResultat_Chrono:GetNbRows() == 0 then
		local msg = "Le chronométrage n'a pas été réalisé en base de temps.\nLe calcul en ligne est impossible.";
		app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		return false;
	end
	if TM.calcul_id:len() == 0 then -- système A, on enlève l'impulsion au cas où elle serait présente
		local r = tResultat_Chrono:GetIndexRow('Dossard', TM.dossard);
		if r and r >= 0 then
			tResultat_Chrono:RemoveRowAt(r);
		end
	end

	if origine == 'A' then
		local tDossardDQP = GetDqp(origine);
		if #tDossardDQP > 0 then
			for i = 1, #tDossardDQP do
				local dossard = tDossardDQP[i].Dossard;
				local cmd = "SELECT * From Resultat_Chrono Where Code_evenement = "..params.code_evenement..' AND Code_manche = '..TM.code_manche..
					" AND Origine = '"..origine.."' AND Dossard_anc = '"..dossard.."'";
				tResultat_Chrono_DQP = base:TableLoad(cmd);	-- le DQP
				if tResultat_Chrono_DQP:GetNbRows() >0 then
					local row = tResultat_Chrono:AddRow();
					tResultat_Chrono:SetCell('Code_evenement', row, params.code_evenement);
					tResultat_Chrono:SetCell('Code_manche', row, TM.code_manche);
					tResultat_Chrono:SetCell('Origine', row, origine);
					tResultat_Chrono:SetCell('Heure', row, tResultat_Chrono_DQP:GetCellInt('Heure', 0));
					tResultat_Chrono_DQP:Delete();
				end
			end
		end
	end
	tResultat_Chrono:OrderBy('Heure');
	TM.row_et = tResultat_Chrono:GetIndexRow('Dossard', TM.dossard);
	if TM.row_et and TM.row_et >= 0 then
		TM.et = tResultat_Chrono:GetCell('Heure', TM.row_et, params.fmt);
	end
	TM.row_precedent = 0 ;
	if TM.dossard_precedent:len() > 0 then
		TM.row_precedent = tResultat_Chrono:GetIndexRow('Dossard', TM.dossard_precedent)
	end
	local nb_references = 0;
	local limite = 10;
	if TM.et then	-- system B toutes les impulsions sont là
		limite = 11
		for i = TM.row_et, 0, -1 do
			tResultat_Chrono:SetCell('Reserve', i, 1);
			nb_references = nb_references + 1;
			if nb_references >= limite then
				break;
			end
		end
		if nb_references < limite then
			for i = TM.row_et + 1 , tResultat_Chrono:GetNbRows() -1 do
				tResultat_Chrono:SetCell('Reserve', i, 1);
				local dossard = tResultat_Chrono:GetCell('Dossard', i);
				if dossard ~= TM.dossard then
					nb_references = nb_references + 1;
				end
				if nb_references >= limite then
					break;
				end
			end
		end
	else	-- system A il manque l'impulsion pour TM.dossard
		for i = TM.row_precedent, 0, -1 do
			tResultat_Chrono:SetCell('Reserve', i, 1);
			nb_references = nb_references + 1;
			if nb_references >= limite then
				break;
			end
		end
		if nb_references < limite then
			for i = TM.row_precedent + 1 , tResultat_Chrono:GetNbRows() -1 do
				tResultat_Chrono:SetCell('Reserve', i, 1);
				nb_references = nb_references + 1;
				if nb_references >= limite then
					break;
				end
			end
		end
	end
	local filter = '$(Reserve):In(1)';
	tResultat_Chrono:Filter(filter, true);

	-- for i = 0, tResultat_Chrono:GetNbRows() -1 do
		-- adv.Alert('il reste le dossard : '..tResultat_Chrono:GetCell('Dossard', i)..', Heure = '..tResultat_Chrono:GetCell('Heure', i, params.fmt));
	-- end

	return bolOK;
end

function main(params_c)
	if params_c == nil then
		return false;
	end

	base = base or sqlBase.Clone();
	params = params_c;
	OK = true;
	params.mode_localhost = false;
	params.code_manche = 1;
	params.nb_manche = 1;
	params.fmt = "%2h:%2m:%2s.%3f";
	script_version = "2027.04"; 
	indice_return = 16;
	local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
	version = curl.AsyncGET(wnd.GetParentFrame(), url);


	TM = {};
	TM.ligne = {};
	TM.impulsion = "Départ";
	TM.dossard = nil;
	TM.dossardPrecedent = nil;
	TM.lire = false;
	TM.calculfait = false;
	tResultat = base:GetTable('Resultat');
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	params.evenement_nom = tEvenement:GetCell("Nom", 0);
	local codex = tEvenement:GetCell("Codex", 0);
	local tcodex = codex:Split('%.');
	params.codex = tcodex[1];
	params.directory_calculs = app.GetPath()..app.GetPathSeparator()..'EET_calculs'..app.GetPathSeparator();
	params.directory_tmp = app.GetPath()..app.GetPathSeparator()..'tmp'..app.GetPathSeparator();
	if not app.DirExists(params.directory_calculs) then
		app.Mkdir(params.directory_calculs);
	end
	params.json_out = app.GetPath()..app.GetPathSeparator()..'tmp'..app.GetPathSeparator()..'temp_EET.json';
	params.json_check = app.GetPath()..app.GetPathSeparator()..'tmp'..app.GetPathSeparator()..'temp_check.json';
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	params.nb_manche = tEpreuve:GetCellInt("Nombre_de_manche", 0, 1);
	tResultat_Chrono = base:GetTable('Resultat_Chrono');
	TM.ligne = {};
	TM.RangPrecedent = -1;
	OnSaisieDlg1();

end




