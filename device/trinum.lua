-- Interface ski - Caméra TRINUM
dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 3.5, name = 'Trinum', class = 'display' };
end	

trinum = {};

-- URL, Plateforme et paramètres généraux
trinum.http = "http://127.0.0.1:8080";
trinum.plateforme_depart = 'BAS';

trinum.code_competition = -1;
trinum.nom_competition = '';
trinum.meilleur_temps = -1;

-- Configuration du Device
function device.OnConfiguration(node)
	local dlg = wnd.CreateDialog({
		icon = "./res/32x32_trinum.png",
		label = "Configuration Interface TRINUM",
		width = 350,
		height = 200
	});
	
	dlg:LoadTemplateXML({ 
		xml = './device/trinum.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'config'
	});

	trinum.node = node;

	-- Initialisation des controles 
	local url = dlg:GetWindowName('url_trinum');
	url:SetValue(node:GetAttribute('url_trinum'));
	
	local comboPlateformeDepart = dlg:GetWindowName('combo_plateforme');
	
	local plateformes = node:GetAttribute('plateformes');
	if plateformes:len() == 0 then
		comboPlateformeDepart:Append('HAUT');
		comboPlateformeDepart:Append('MILIEU');
		comboPlateformeDepart:Append('BAS');
	else
		local arrayPlateformes = plateformes:Split(',');
		for i=1,#arrayPlateformes do
			comboPlateformeDepart:Append(arrayPlateformes[i]:Trim());
		end
	end
	comboPlateformeDepart:SetValue(node:GetAttribute('plateforme_depart', 'BAS'));
	
	local tb = dlg:GetWindowName('tb');
	local btnSave = tb:AddTool("Enregistrer", "./res/32x32_ok.png");
	tb:AddStretchableSpace();
	local btnExit = tb:AddTool("Quitter", "./res/vpe32x32_close.png");
	tb:Realize();

	function OnExit(evt)
		dlg:EndModal();
	end

	function OnSave(evt)
		node:DeleteAttribute('url_trinum');
		node:AddAttribute('url_trinum', url:GetValue());
		node:DeleteAttribute('plateforme_depart');
		node:AddAttribute('plateforme_depart', comboPlateformeDepart:GetValue());
		app.GetXML():SaveFile();
		dlg:EndModal();
	end

	-- Bind
	dlg:Bind(eventType.MENU, OnExit, btnExit);
	dlg:Bind(eventType.MENU, OnSave, btnSave);

	-- Affichage Modal
	dlg:Fit();
	dlg:ShowModal();
	dlg:Delete();
end

-- Ouverture de device : initialisation
function device.OnInit(params, node)

	if node ~= nil then
		trinum.http = node:GetAttribute('url_trinum', 'http://127.0.0.1:8080');
		trinum.plateforme_depart = node:GetAttribute('plateforme_depart', 'BAS');
	end

	-- notification à prendre en compte 
	app.BindNotify("<bib_time>", OnNotifyBibTime);
	app.BindNotify("<forerunner_time>", OnNotifyForerunnerTime);
	app.BindNotify("<passage_insert>", OnNotifyPassageInserted);
	app.BindNotify("<passage_add>", OnNotifyBibPassageAdd);

	-- Prise valeur offset Horloge PC - Horloge Chrono Officielle
	local rc, offsetInfo = app.SendNotify('<offset_time_load>');
	assert(rc);
	trinum.offset = tonumber(offsetInfo.offset);

	-- Récupération des infos de la course
	local rc, raceInfo = app.SendNotify('<race_load>');
	assert(rc);
	trinum.raceInfo = raceInfo;

	trinum.code_competition = raceInfo.tables['Evenement']:GetCell('Code', 0);
	trinum.nom_competition = raceInfo.tables['Evenement']:GetCell('Nom', 0);
	trinum.code_discipline = raceInfo.tables['Epreuve']:GetCell('Code_discipline', 0);

	-- Creation Panel
	local panel = wnd.CreatePanel({ parent = app.GetAuiFrame() });
	panel:LoadTemplateXML({ 
		xml = './device/trinum.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'dashboard'
	});

	trinum.panel = panel;
	trinum.gridMessage = panel:GetWindowName('message');

	-- Affichage ...
	panel:Show(true);
	
	local mgr = app.GetAuiManager();
	mgr:AddPane(panel, {
		icon = './res/32x32_trinum.png',
		caption = "Tableau de Bord Trinum",
		caption_visible = true,
		close_button = false,
		pin_button = true,
		show = true,

		float = true, 
		floating_position = {800, 40},
		floating_size = {400, 180},
		dockable = false
		
	});
	mgr:Update();

	panel:Bind(eventType.CURL, OnCurl);
	
	Success('Platefome Départ Caméra = '..trinum.plateforme_depart);
	Success('Course '..trinum.code_competition..', Manche '..raceInfo.Code_manche..' (Nb Inter='..raceInfo.Nb_inter..')');
end

-- Fermeture
function device.OnClose()
	if trinum.panel ~= nil then
		local mgr = app.GetAuiManager();
		mgr:DeletePane(trinum.panel);
	end
end

-- Event Curl Asynchrone
function OnCurl(evt)
	if evt:GetInt() == 1 then
		Alert('-> ok');
	else
		-- Erreur CURL ...
		Alert('<- Erreur CURL :'..evt:GetString():sub(1,80));
	end
end

-- <bib_insert> : 
-- passage = 0 -> départ
-- passage = 1 -> inter 1
-- passage = 2 -> inter2
-- passage = -1 -> arrivée

function OnNotifyBibTime(key, params)
	local passage = tonumber(params.passage);
	local bib = params.bib;
	local temps_coureur = tonumber(params.time);
	if passage == -1 and temps_coureur ~= -1 then
		Send(bib, passage, 0, temps_coureur);
	end
end

-- <forerunner_time>
function OnNotifyForerunnerTime(key, params)
	local passage = tonumber(params.passage);
	local bib = params.bib;
	local temps_coureur = tonumber(params.time);

	Send(bib, passage, 0, temps_coureur);
end

-- <passage_insert>
function OnNotifyPassageInserted(key, params)
	local passage = tonumber(params.passage);
	local bib = params.bib;
	local chrono = tonumber(params.time);
	
	Send(bib, passage, chrono, 0);
end

-- <passage_add> Notification
function OnNotifyBibPassageAdd(key, params)
	if app.GetAuiFrame():GetModeChrono() == 'net_time' then
		-- Uniquement en Mode Temps Net ...
		local passage = tonumber(params.passage);
		local bib = params.bib;
		local chrono = tonumber(params.time);
		if passage == 0 then
			Send(bib, passage, chrono, 0);
		end
	end
end

-- <best_load>
function OnNotifyBestLoaded(key, params)
	if params.time ~= nil and tonumber(params.time) > 0 then
		trinum.meilleur_temps = tonumber(params.time);
	end
	return true;
end

-- Send
function Send(bib, passage, chrono, temps_coureur)
	if bib == nil then return end
	if type(bib) == 'string' and bib:len() == 0 then return end

	-- Chargement des informations lié au dossard
	local rc, bibLoad = app.SendNotify("<bib_load>", { bib = bib });
	if rc == nil or rc == false then return end;
	
	local url = nil;
	if bibLoad.ranking ~= nil then
		-- Coureur 
		local bibInfo = bibLoad.ranking;
		
		url = trinum.http.."/getchrono"
		.."?dossard="..bib
		.."&id_passage="..passage
		.."&temps_coureur="..tostring(temps_coureur)
		.."&chrono="..tostring(chrono)
		
		.."&num_course="..trinum.code_competition
		.."&num_manche="..trinum.raceInfo.Code_manche
		.."&nom_course="..curl.UrlEncode(trinum.nom_competition)
		.."&depart="..trinum.plateforme_depart
		.."&meilleur_temps="..tostring(trinum.meilleur_temps)
		
		.."&code_coureur="..bibInfo:GetCell('Code_coureur', 0)
		.."&nom="..curl.UrlEncode(bibInfo:GetCell('Nom', 0))
		.."&prenom="..curl.UrlEncode(bibInfo:GetCell('Prenom', 0))
		.."&sexe="..bibInfo:GetCell('Sexe', 0)
		.."&an="..bibInfo:GetCell('An', 0)
		.."&medaille="..curl.UrlEncode(bibInfo:GetCell('Medaille'..trinum.raceInfo.Code_manche, 0))
		.."&discipline="..tostring(trinum.code_discipline)
		;	
	elseif bibLoad.nom ~= nil then
		-- Ouvreur
		local nom = bibLoad.nom or '';
		local prenom = bibLoad.prenom or '';
		local sexe = bibLoad.sexe or '';
		local an = bibLoad.an or '';
		local matric = bibLoad.matric or '';
	
		url = trinum.http.."/getchrono"
		.."?dossard="..bib
		.."&id_passage="..passage
		.."&temps_coureur="..tostring(temps_coureur)
		.."&chrono="..tostring(chrono)
		
		.."&num_course="..trinum.code_competition
		.."&num_manche="..trinum.raceInfo.Code_manche
		.."&nom_course="..curl.UrlEncode(trinum.nom_competition)
		.."&depart="..trinum.plateforme_depart
		.."&meilleur_temps="..tostring(trinum.meilleur_temps)
		
		.."&code_coureur=MON"..matric
		.."&nom="..curl.UrlEncode(nom)
		.."&prenom="..curl.UrlEncode(prenom)
		.."&sexe="..sexe
		.."&an="..an
		.."&medaille="
		.."&discipline="..tostring(trinum.code_discipline)
		;
	end

	if url ~= nil then
		curl.AsyncGET(trinum.panel, url, 1234);
		Alert('send:'..url);
	end
end

function Alert(txt)
	trinum.gridMessage:AddLine(txt);
end

function Success(txt)
	trinum.gridMessage:AddLineSuccess(txt);
end

function Warning(txt)
	trinum.gridMessage:AddLineWarning(txt);
end

function Error(txt)
	trinum.gridMessage:AddLineError(txt);
end