-- LIVE Timing 
dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

site_distant = false;
if app.FileExists('./process/site_distant.lua') then
	dofile('./process/site_distant.lua');
	site_distant = true;
end

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 6.93;
		name = 'Live Timing Async.', 
		class = 'network'
	};
end	

-- Tableau Associatif Principal
 
function Error(txt)
	if live.panel ~= nil then
		gridmessage = live.panel:GetWindowName('gridmessage'):AddLineError(txt);
	else
		adv.Error(txt);
	end
end

function Info(txt)
	if live.panel ~= nil then
		gridmessage = live.panel:GetWindowName('gridmessage'):AddLine(txt);
	else
		adv.Alert(txt);
	end
end

function Success(txt)
	if live.panel ~= nil then
		gridmessage = live.panel:GetWindowName('gridmessage'):AddLineSuccess(txt);
	else
		adv.Success(txt);
	end
end

function Warning(txt)
	if live.panel ~= nil then
		gridmessage = live.panel:GetWindowName('gridmessage'):AddLineWarning(txt);
	else
		adv.Warning(txt);
	end
end

function OnTimerRunning();
	if live.Code_entite == 'FIS' then
		local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
		local nodeKeepalive = xmlNode.Create(nodeRoot, xmlNodeType.ELEMENT_NODE, "keepalive");
		CreateXML(nodeRoot);
		Info("Keepalive envoyé");
	end
end

function LoadTableMessages()
	if live.doc == nil then return nil end
	
	local nodeMessages = live.doc:FindFirst("root/messages");
	if nodeMessages == nil then return nil end

	local tMessages = sqlTable.Create('Messages');
	tMessages:AddColumn({ name = 'en', label = 'Name', type = sqlType.TEXT });
	tMessages:AddColumn({ name = 'fr', label = 'Nom', type = sqlType.TEXT });
	
	local child = xmlNode.GetChildren(nodeMessages);
	while child ~= nil do
		tMessages:GetRecord():Set('en', child:GetAttribute("en"));
		tMessages:GetRecord():Set('fr', child:GetAttribute("fr"));
		tMessages:AddRow();
			
		child = child:GetNext();
	end
	
	return tMessages;
end

function SetTablesMeteo()
	function RempliTable(node, tTable)
		local child = xmlNode.GetChildren(node);
		while child ~= nil do
			tTable:GetRecord():Set('Code', child:GetAttribute("code"));
			tTable:GetRecord():Set('Legend', child:GetAttribute("legend"));
			tTable:AddRow();
			child = child:GetNext();
		end
	end
	
	if live.doc ~= nil then
		if live.doc:FindFirst("root/weathers") ~= nil then
			tWeather = sqlTable.Create("Weather");
			tWeather:AddColumn({ name = 'Code', label = 'Code', type = sqlType.TEXT });
			tWeather:AddColumn({ name = 'Legend', label = 'Légende', type = sqlType.TEXT, width=60  });
			RempliTable(live.doc:FindFirst("root/weathers"), tWeather);
		end
		if live.doc:FindFirst("root/winds") ~= nil then
			tWind = sqlTable.Create("Wind");
			tWind:AddColumn({ name = 'Code', label = 'Code', type = sqlType.TEXT });
			tWind:AddColumn({ name = 'Legend', label = 'Légende', type = sqlType.TEXT, width=60 });
			RempliTable(live.doc:FindFirst("root/winds"), tWind);
		end
		if live.doc:FindFirst("root/snowconditions") ~= nil then
			tSnowCondition = sqlTable.Create("Snowcondition");
			tSnowCondition:AddColumn({ name = 'Code', label = 'Code', type = sqlType.TEXT });
			tSnowCondition:AddColumn({ name = 'Legend', label = 'Légende', type = sqlType.TEXT, width=60  });
			RempliTable(live.doc:FindFirst("root/snowconditions"), tSnowCondition);
		end
	end
end

-- Configuration du Device
function device.OnConfiguration(node)
	live = {};
	
	local dlg = wnd.CreateDialog({
		parent = live.panel,
		icon = "./res/16x16_live.png",
		label = "Configuration du Live Timing",
		width = 500,
		height = 800
	});
	
	dlg:LoadTemplateXML({ 
		xml = './device/live_timing.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'config'
	});
	
	-- Initialisation des Variables ...
	local comboLanguage = dlg:GetWindowName('language');
	comboLanguage:SetValue(node:GetAttribute('language', 'fr - Français'));
	comboLanguage:Append("fr - Français");
	comboLanguage:Append("en - English");
	
	dlg:GetWindowName('fis_hostname'):SetValue(node:GetAttribute('fis_hostname', 'live.fisski.com'));
	dlg:GetWindowName('fis_port'):SetValue(node:GetAttribute('fis_port'));
	dlg:GetWindowName('fis_pwd'):SetValue(node:GetAttribute('fis_pwd'));

	dlg:GetWindowName('ffs_hostname'):SetValue("https://live.ffs.fr/live_timing");
	if node:GetAttribute('ffs_test') == "1" then
		dlg:GetWindowName('ffs_test'):SetValue(true);
	else
		dlg:GetWindowName('ffs_test'):SetValue(false);
	end
	dlg:GetWindowName('clubesf_hostname'):SetValue(node:GetAttribute('clubesf_hostname', 'https://technique.clubesf.com/live_timing'));
	dlg:GetWindowName('perso_hostname'):SetValue(node:GetAttribute('perso_hostname', 'http://localhost/live_timing'));

	local comboTarget = dlg:GetWindowName('comboTarget');
	comboTarget:Append("Automatique");
	comboTarget:Append("FFS");
	comboTarget:Append("FIS");
	comboTarget:Append("ESF");
	comboTarget:Append("Perso");
	comboTarget:SetValue(node:GetAttribute('target', 'Automatique'));

	local comboPort = dlg:GetWindowName('fis_port');
	comboPort:Append("1550");
	comboPort:Append("1551");
	comboPort:Append("Automatique");
	comboPort:SetValue(node:GetAttribute('fis_port', 'Automatique'));

	-- Toolbar Principale ...
	local tb = dlg:GetWindowName('tb');
	local btnSave = tb:AddTool("Valider", "./res/32x32_ok.png");
	tb:AddStretchableSpace();
	local btnClose = tb:AddTool("Fermer", "./res/vpe32x32_close.png");
	tb:Realize();
	
	function OnSaveConfig(evt)
		node:ChangeAttribute('language', dlg:GetWindowName('language'):GetValue());

		node:ChangeAttribute('fis_hostname', dlg:GetWindowName('fis_hostname'):GetValue());
		node:ChangeAttribute('fis_port', dlg:GetWindowName('fis_port'):GetValue());
		node:ChangeAttribute('fis_pwd', dlg:GetWindowName('fis_pwd'):GetValue());

		node:ChangeAttribute('ffs_hostname', dlg:GetWindowName('ffs_hostname'):GetValue());
		if dlg:GetWindowName('ffs_test'):GetValue() == true then
			node:ChangeAttribute('ffs_test',  "1");
		else
			node:ChangeAttribute('ffs_test',  "0");
		end
		node:ChangeAttribute('clubesf_hostname', dlg:GetWindowName('clubesf_hostname'):GetValue());
		node:ChangeAttribute('perso_hostname', dlg:GetWindowName('perso_hostname'):GetValue());
		node:ChangeAttribute('target', dlg:GetWindowName('comboTarget'):GetValue());

		local doc = app.GetXML();
		doc:SaveFile();
		dlg:EndModal(idButton.OK);
	end
	
	dlg:Bind(eventType.MENU, OnSaveConfig, btnSave); 
--	dlg:Bind(eventType.BUTTON, OnPath, dlg:GetWindowName('path'));
	dlg:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL) end, btnClose);
	
	-- Lancement de la dialog
	dlg:Fit();
	dlg:ShowModal();

	-- Liberation Memoire
	dlg:Delete();
end

-- Ouverture de device : initialisation
function device.OnInit(params, node)

	-- Récupération des infos infos de la course selon le contexte
	local rc, raceInfo = app.SendNotify('<race_load>');
	if rc == false then
		Error("Erreur Chargement Informations Course ...");
		return;
	end
	
	live = raceInfo;  -- tableau associatif principal
	live.node = node;
	local tEvenement = raceInfo.tables.Evenement;
	local tEpreuve = raceInfo.tables.Epreuve;
	local tPistes = raceInfo.tables.Pistes;
	if tEvenement == nil or tEpreuve == nil or tPistes == nil then
		Error("L'environnement ne permet pas le Live !!");
		return;
	end
	
	live.fmt = GetFormatChrono();
	live.Code_entite = tEvenement:GetCell("Code_entite",0);
	live.Code_activite = tEvenement:GetCell("Code_activite",0);
	live.category = tEpreuve:GetCell('Code_regroupement');
	
	if live.Code_entite == 'ESF' then
		local rc, dataForerunner = app.SendNotify('<forerunner_load>');
		if rc then
			live.dataForerunner = dataForerunner;
		end
		
		local rc, dataMedals = app.SendNotify('<medals_load>');
		if rc then
			live.dataMedals = dataMedals.medals;
		end
	end
	live.target = node:GetAttribute('target');
	live.method = 'post';
	live.targetName = '';
	-- Prise Codex 
	if live.Code_entite == 'ESF' then
		-- En ESF Codex = Code ESF - Numéro de Course
		raceInfo.Code_esf = raceInfo.Code_esf or '';
		raceInfo.Signature_esf = raceInfo.Signature_esf or '';
		if IsSignatureEsfOk(raceInfo.Code_esf, raceInfo.Signature_esf) == false then
			Error("Signature ESF non correcte ! Live non autorisé ...");
			return;
		end
		live.codex = raceInfo.Code_esf..'-'..tEvenement:GetCell('Code',0);
	else
		if tEpreuve:GetCell('Fichier_transfert', 0):len() < 3 then
			Error("Live Impossible : Aucun Codex pour cette course !");
			return
		end
		if live.Code_entite == 'FIS' then
			-- Numero Codex FIS
			live.codex = string.sub(tEvenement:GetCell("Codex", 0),4);
			if live.target == 'FFS' or live.target == 'Perso' then
				live.pwd = '';
				live.codex = tEvenement:GetCell("Codex", 0);
			end
			live.codex = live.codex:Split("%.");
			live.codex = live.codex[1];
		elseif live.Code_entite == 'FFS' then
			if tEvenement:GetCell("Code_activite", 0) == 'ALP' then
				live.codex = tEpreuve:GetCell('Fichier_transfert', 0);
			else
				live.codex = tEvenement:GetCell("Codex", 0);
			end
			live.comite = tEvenement:GetCell("Station", 0);
			live.station = tEvenement:GetCell("Station", 0);
		end
		if live.target == 'FFS' then
			live.pwd = '';
			if sqlBase.IsWebFFS() == false then
				Error("Pas de Connexion au Web-FFS actuellement ! Live non autorisé ...");
				return;
			end
		end
	end
		
	-- attributs du Node XML 
	if live.target == 'FFS' then
		live.pwd = '';
		live.hostname = node:GetAttribute('ffs_hostname', 'https://live.ffs.fr/live_timing');
		live.targetName = 'Live FFS';
		live.directory = app.GetPath()..app.GetPathSeparator()..'live_timing'..app.GetPathSeparator()..'ffs';
		if live.Code_activite == 'FOND' or live.Code_activite == 'BIATH' or live.Code_activite == 'ROL' then
			live.web = 'https://live.ffs.fr/live_timing/live_cc.php?codex='..live.codex;
		else
			live.web = 'https://live.ffs.fr/live_timing/live.php?codex='..live.codex;
		end
		if live.node:GetAttribute('ffs_test') == '1' then
			live.web = live.web..'&test=1';
		end
	elseif live.target == 'FIS' then
			live.hostname = node:GetAttribute('fis_hostname', 'live.fisski.com');
			live.port = node:GetAttribute('fis_port');
			live.pwd = node:GetAttribute('fis_pwd');
			live.targetName = live.hostname..':'..live.port;
			live.method = 'socket';
			live.directory = app.GetPath()..app.GetPathSeparator()..'live_timing'..app.GetPathSeparator()..'fis';
			live.web = 'live.fis-ski.com/lv-'..string.lower(string.sub(live.Code_activite,1,2))..live.codex..'.htm';
	elseif live.target == 'ESF' then
			live.hostname = node:GetAttribute('clubesf_hostname', 'https://technique.clubesf.com/live_timing');
			live.targetName = 'Live ESF';
			live.directory = app.GetPath()..app.GetPathSeparator()..'live_timing'..app.GetPathSeparator()..'esf';
			live.web = live.hostname;
	elseif live.target == 'Perso' then
			live.hostname = node:GetAttribute('perso_hostname');
			live.targetName = 'Live '..live.hostname;
			live.directory = app.GetPath()..app.GetPathSeparator()..'live_timing'..app.GetPathSeparator()..'perso';
			if live.Code_activite == 'FOND' or live.Code_activite == 'BIATH' or live.Code_activite == 'ROL' then
				live.web = live.hostname..'/live_cc.php?codex='..live.codex;
			else
				live.web = live.hostname..'/live.php?codex='..live.codex;
			end
	else	-- 'Automatique'
		if live.Code_entite == 'ESF' then
			live.hostname = node:GetAttribute('clubesf_hostname', 'https://technique.clubesf.com/live_timing');
			live.targetName = 'Live ESF';
			live.directory = app.GetPath()..app.GetPathSeparator()..'live_timing/esf';
			live.web = live.hostname;
		elseif live.Code_entite == 'FFS' then
			live.pwd = '';
			if sqlBase.IsWebFFS() == false then
				Error("Pas de Connexion au Web-FFS actuellement ! Live non autorisé ...");
				return;
			end
			live.hostname = node:GetAttribute('ffs_hostname', 'https://live.ffs.fr/live_timing');
			live.targetName = 'Live FFS';
			live.directory = app.GetPath()..app.GetPathSeparator()..'live_timing/ffs';
			if live.Code_activite == 'FOND' or live.Code_activite == 'BIATH' or live.Code_activite == 'ROL' then
				live.web = 'https://live.ffs.fr/live_timing/live_cc.php?codex='..live.codex;
			else
				live.web = 'https://live.ffs.fr/live_timing/live.php?codex='..live.codex;
			end
			if live.node:GetAttribute('ffs_test') == '1' then
				live.web = live.web..'&test=1';
			end
		elseif live.Code_entite == 'FIS' then
			live.hostname = node:GetAttribute('fis_hostname', 'live.fisski.com');
			live.port = node:GetAttribute('fis_port');
			live.pwd = node:GetAttribute('fis_pwd');
			live.method = 'socket';
			live.targetName = live.hostname..':'..live.port;
			live.directory = app.GetPath()..app.GetPathSeparator()..'live_timing/fis';
			live.web = 'live.fis-ski.com/lv-'..string.lower(string.sub(live.Code_activite,1,2))..live.codex..'.htm';
		end
	end
	
	if live.method == 'socket' then
		if live.category == 'CE' then
			live.category = 'EC';
		end
		if live.category == 'F' then
			live.category = 'NC';
		end
		if tEpreuve:GetCell("Sexe", 0) == "M" and live.port == "Automatique" then
			live.port = '1550';
		end
		if tEpreuve:GetCell("Sexe", 0) == "F" and live.port == "Automatique" then
			live.port = '1551';
		end
		live.targetName = live.hostname..':'..live.port;
	end
	livetest = 0;
	
	-- Ouverture Document XML 
	live.doc = xmlDocument.Create();
	if live.doc:LoadFile('./device/live_timing.xml') == false then
		live.doc:Delete();
		live.doc = nil;
	end
	
	SetTablesMeteo();

	-- Creation Panel 
	local panel = wnd.CreatePanel({ parent = app.GetAuiFrame() });
	panel:LoadTemplateXML({ 
		xml = './device/live_timing.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'live'
	});
	live.panel = panel;

	-- Initialisation ...
	local tb = panel:GetWindowName('tb');

	live.btn_state = tb:AddTool('Activation ou Désactivation du Live...', './res/chrono32x32_ko.png');
	live.state = false;
	tb:AddSeparator();
	
	local btn_reset = tb:AddTool('Remise à Zéro des Données', './res/32x32_clear.png');
	tb:AddSeparator();
	
	local btn_startlist = tb:AddTool("Envoi de la liste de départ", "./res/32x32_bib.png");
	local btn_send = tb:AddTool("Envois Supplémentaires", "./res/32x32_send.png", "Envois Supplémentaires", itemKind.DROPDOWN);
	tb:AddSeparator();
	
	local btn_message = tb:AddTool("Envoyer un message", "./res/32x32_journal.png");
	tb:AddSeparator();
	btn_web = tb:AddTool("Acces Page Web du Live Timing", "./res/32x32_web.png");
	tb:AddSeparator();

	local menuSend =  menu.Create();
	btn_send_run = menuSend:Append({label="Envoi des temps de la manche en cours", image ="./res/32x32_chrono.png"});
	btn_send_all = menuSend:Append({label="Envoi de la totalité des informations et des temps", image ="./res/32x32_competition.png"});
	menuSend:AppendSeparator();
	btn_raceinfo = menuSend:Append({label="Envoi des Informations Course", image ="./res/32x32_tools.png"});
	menuSend:AppendSeparator();
	btn_scheduled = menuSend:Append({label="Envoi des Heures de Départ", image ="./res/32x32_clock.png"});
	menuSend:AppendSeparator();
	btn_saisie_meteo = menuSend:Append({label = "Saisie des infos météo", image = "./res/32x32_cloud_blue.png"});
	btn_envoi_meteo = menuSend:Append({label = "Envoi des infos météo", image = "./res/32x32_cloud_blue.png"});
	tb:SetDropdownMenu(btn_send:GetId(), menuSend);
	local btn_reset_socket = tb:AddTool('Reset de la connexion FIS', './res/32x32_satellite.png');
	tb:AddSeparator();
	if live.method ~= 'socket' then
		tb:EnableTool(btn_reset_socket:GetId(), false);
	end

	-- tb:AddStretchableSpace();
	live.counterSequence = wnd.CreateStaticText({parent = tb, label = "Trame 0/0", style = wndStyle.ALIGN_LEFT});
	tb:AddControl(live.counterSequence);
	tb:Realize();

	live.sequence_ack = nil;		-- Dernier Message Acquité par le serveur 
	live.sequence_send = nil;		-- Dernier Fichier XML crée
	
	-- Notification ...
	app.BindNotify("<bib_insert>", OnNotifyBibInsert);
	app.BindNotify("<bib_delete>", OnNotifyBibDelete);
	app.BindNotify("<bib_time>", OnNotifyBibTime);
	app.BindNotify("<run_erase>", OnNotifyRunErase);
	app.BindNotify("<bib_next>", OnNotifyBibNext);
	
	app.BindNotify("<passage_add>", OnNotifyBibPassageAdd);
	app.BindNotify("<passage_update>", OnNotifyBibPassageUpdate);
	
	app.BindNotify("<forerunner_best_base_time>", OnNotifyForerunnerBestBaseTime);

	-- Event ...
	panel:Bind(eventType.MENU, OnLiveState, live.btn_state);
	panel:Bind(eventType.MENU, OnReset, btn_reset);
	panel:Bind(eventType.MENU, OnSendStartList, btn_startlist);

	panel:Bind(eventType.MENU, OnSendRaceInfo, btn_raceinfo);
	panel:Bind(eventType.MENU, OnSendScheduled, btn_scheduled);
	
	panel:Bind(eventType.MENU, OnSendMeteo, btn_envoi_meteo);
	panel:Bind(eventType.MENU, OnSaisieMeteo, btn_saisie_meteo);
	
	panel:Bind(eventType.MENU, OnResetSocket, btn_reset_socket);

	panel:Bind(eventType.MENU, OnSendMessage, btn_message);
	panel:Bind(eventType.MENU, OnSendRunChrono, btn_send_run);
	panel:Bind(eventType.MENU, OnSendAll, btn_send_all);
	panel:Bind(eventType.MENU, OnWebLive, btn_web);
	-- création du timer pour la commande keepalive

	live.timer = timer.Create(panel);
	panel:Bind(eventType.TIMER, OnTimerRunning, live.timer);
	live.timer:Start(480000);	-- toutes les 8 minutes (8x60x1000ms) on envoie une commande keepalive
	
	if live.method == 'socket' then
		-- Method : SOCKET IP 
		parentFrame = wnd.GetParentFrame();
		live.socket = socketClient.Open(parentFrame, live.hostname, live.port);
		live.socket_state = false;
		parentFrame:Bind(eventType.SOCKET, OnSocketLive, live.socket);
		-- parentFrame:Bind(eventType.SOCKET, OnSocketLive);
		
	elseif live.method == 'post' then
		-- Method : POST Asynchrone
		parentFrame = wnd.GetParentFrame();
		parentFrame:Bind(eventType.CURL, OnCurlLive);
		InitLive();
	end
	
	-- Affichage ...
	panel:Show(true);
	
	local caption = live.targetName..' / Codex '..live.codex;
	
	local mgr = app.GetAuiManager();
	mgr:AddPane(panel, {
		icon = './res/16x16_live.png',
		caption = caption,
		caption_visible = true,
		close_button = false,
		pin_button = true,
		show = true,

		float = true, 
		floating_position = {600, 120},
		floating_size = {500, 250},
		dockable = false
	});
	mgr:Update();
end

function OnSaisieMeteo()

	local dlg = wnd.CreateDialog({
		parent = live.panel,
		icon = "./res/32x32_tools.png",
		label = "Informations Météo",
		width = 500,
		height = 300
	});
	
	dlg:LoadTemplateXML({ 
		xml = './device/live_timing.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'meteo'
	});

	-- Creation de la toobar 
	local tb = dlg:GetWindowName('tb');
	local btnSend = tb:AddTool("Valider", "./res/32x32_ok.png");
	tb:AddStretchableSpace();
	local btnClose = tb:AddTool("Fermer", "./res/vpe32x32_close.png");
	tb:Realize();

	function OnExit(evt)
		dlg:EndModal();
	end
	
	function OnSave(evt)
		live.weather = dlg:GetWindowName('weather'):GetValue();
		live.temperature = dlg:GetWindowName('temperature'):GetValue();
		live.snowtemperature = dlg:GetWindowName('snowtemperature'):GetValue();
		live.humidity = string.gsub(dlg:GetWindowName('humidity'):GetValue(), "%%", "");	-- enregistrement de l'humidité sous forme entière
		live.wind = dlg:GetWindowName('wind'):GetValue();
		live.snowcondition = dlg:GetWindowName('snowcondition'):GetValue();
	
		local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livemeteo");
		local nodeMeteo = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "meteo");
		nodeMeteo:ChangeAttribute('weather', dlg:GetWindowName('weather'):GetValue());
		nodeMeteo:ChangeAttribute('temperature', dlg:GetWindowName('temperature'):GetValue());
		nodeMeteo:ChangeAttribute('snowtemperature', dlg:GetWindowName('snowtemperature'):GetValue());
		nodeMeteo:ChangeAttribute('humidity', dlg:GetWindowName('humidity'):GetValue());
		nodeMeteo:ChangeAttribute('wind', live.wind);
		nodeMeteo:ChangeAttribute('snowcondition', live.snowcondition);
		
		local doc = xmlDocument.Create();
		if doc:SetRoot(nodeRoot) == true then
			nodeRoot:AddAttribute("codex", live.codex);
			nodeRoot:AddAttribute("timestamp", os.date('%H:%M:%S', os.time()));
			nodeRoot:AddChild(nodeMeteo);
		end
		doc:SaveFile(live.directory..'/meteo'..live.codex..'.xml');	-- ecriture d'un seul fichier météo par CODEX
		doc:Delete();
		dlg:EndModal();
	end

	dlg:GetWindowName('weather'):SetTable(tWeather, 'Legend', 'Legend');
	dlg:GetWindowName('wind'):SetTable(tWind, 'Legend', 'Legend');
	dlg:GetWindowName('snowcondition'):SetTable(tSnowCondition, 'Legend', 'Legend');

	ReadMeteo();
	dlg:GetWindowName("weather"):SetValue(live.weather);	
	dlg:GetWindowName("temperature"):SetValue(live.temperature);	
	dlg:GetWindowName("snowtemperature"):SetValue(live.snowtemperature);	
	dlg:GetWindowName("humidity"):SetValue(live.humidity);	
	dlg:GetWindowName("wind"):SetValue(live.wind);	
	dlg:GetWindowName("snowcondition"):SetValue(live.snowcondition);	

	-- Bind
	dlg:Bind(eventType.MENU, OnExit, btnExit);
	dlg:Bind(eventType.MENU, OnSave, btnSave);
	
	dlg:Fit();
	dlg:ShowModal();

end

-- Fermeture
function device.OnClose()

	if live.socket ~= nil then
		live.socket:Close();
	end
	
	if live.doc ~= nil then
		live.doc:Delete();
	end
	
	if live.panel ~= nil then
		local mgr = app.GetAuiManager();
		mgr:DeletePane(live.panel);
	end

	if live.timer ~= nil then
		live.timer:Delete();
	end
	
	if tWeather ~= nil then tWeather:Delete(); end
	if tWind ~= nil then tWind:Delete(); end
	if tSnowCondition ~= nil then tSnowCondition:Delete(); end
end

-- fonctions des événements concernant les séquences
function IncrementationSequenceSend()
	live.sequence_send = live.sequence_send + 1;
	live.node:ChangeAttribute('send_'..live.codex, live.sequence_send);
	app.GetXML():SaveFile();

	RefreshCounterSequence();
end

function SaveSequenceAck()
	live.node:ChangeAttribute('ack_'..live.codex, live.sequence_ack);
	app.GetXML():SaveFile();

	RefreshCounterSequence();
end

-- Acquitement XML
function ReadAckXML(stringXml)
	if string.len(stringXml) == 0 then return false end

	local doc = xmlDocument.Create();
	if doc:LoadString(stringXml) == true then
		local root = doc:GetRoot();
		if root ~= nil then
			if root:HasAttribute('sequence') then
				sequence = root:GetAttribute('sequence');
				live.sequence_ack = tonumber(sequence);
				SaveSequenceAck();
				SendNextPacket();
				doc:Delete();
				return true;
			elseif root:HasAttribute('error') then
				local txtError = root:GetAttribute('error');
				Error('ReadAckXML : '..txtError);
				doc:Delete();
				live.state = false;
				local tb = live.panel:GetWindowName('tb');
				tb:SetToolNormalBitmap(live.btn_state, './res/chrono32x32_ko.png');
				return false;
			end
		end
	end

	Error('ReadAckXML : XML invalid '..stringXml);
	return false;
end

function RefreshCounterSequence()
	live.counterSequence:SetLabel('Trame '..tostring(live.sequence_ack)..'/'..tostring(live.sequence_send));
end

-- Envoi Packet 
function SendNextPacket()
	if live.sequence_ack == live.sequence_send then
		return; -- Tout est Acquitté ...
	end
	
	if live.method == 'socket' then
		-- Verification de l'état du Socket ..
		if live.socket_state == false then
			Info('Demande de réinitialisation ...');
			DoResetSocket();
			return;
		end
	end

	if live.sequence_last_send ~= nil and live.sequence_ack < live.sequence_last_send then
		return -- la dernière séquence envoyée n'a pas encore été acquittée.
	end
	
	local sequence_next = live.sequence_ack + 1;
	
	-- Lecture du Xml ...
	local xmlFile = live.directory..'/live'..live.codex..'_'..tostring(sequence_next)..'.xml';
	local doc = xmlDocument.Create(xmlFile);
	local xmlText = doc:SaveString();
	doc:Delete();
	
	-- Envoi du XML
	local UTF8 = true;
	if live.method == 'socket' then
		live.socket:WriteString(xmlText, UTF8);	
	elseif live.method == 'post' then
		curl.AsyncPOST(wnd.GetParentFrame(), live.hostname..'/send.php', xmlText);
	end
		
	live.sequence_last_send = sequence_next;
end

-- Event Curl Asynchrone
function OnCurlLive(evt)
	if evt:GetInt() == 1 then
		ReadAckXML(evt:GetString());
	else
		adv.Alert('Erreur CURL :'..evt:GetString():sub(1,80));
	end
end

-- Event Socket
function OnSocketLive(evt)
	if evt:GetSocketEvent() == socketNotify.INPUT then
		-- INPUT
		live.socket:ReadToCircularBuffer();
		local cb = live.socket:GetCircularBuffer();
		local count = cb:GetCount();
		local stringXml = cb:ReadString();
		ReadAckXML(stringXml);
	elseif evt:GetSocketEvent() == socketNotify.CONNECTION then
		-- CONNECTION
		local tPeer = live.socket:GetPeer();
--		Success("CONNEXION FIS "..tPeer.ip..':'..tPeer.port);
		Success("CONNEXION SERVEUR FIS OK ...");
		live.socket_state = true;
		InitLive();
	elseif evt:GetSocketEvent() == socketNotify.LOST then
		-- LOST
		Warning("CONNEXION INTERNET / FIS PERDUE ...");
		Warning("REINITIALISEZ LES CONNEXIONS !!!");
		live.socket_state = false;
	else 
		Warning("REINITIALISEZ TOUTES LES CONNEXIONS !!!");
		live.socket_state = false;
	end
end

function InitLive()
	
	local tEpreuve = live.tables.Epreuve;
	live.sequence_ack = tonumber(live.node:GetAttribute('ack_'..live.codex)) or 0;
	live.sequence_send = tonumber(live.node:GetAttribute('send_'..live.codex)) or 0;
	RefreshCounterSequence();
	
	-- Est ce que tout a été acquitté ?
	if live.state == true then
		SendNextPacket();
	end
	
	-- if live.sexe == "F" then sexe = "L" end
	
	return true;
end

function GetFormatChrono()
	local tEvenement = live.tables.Evenement;
	if tEvenement ~= nil then
		if live.Code_activite == 'FOND' or live.Code_entite == 'BIATH' or live.Code_entite == 'ROL' then
			return "%-1h%-1m%2s.%1f";
		else
			return "%-1h%-1m%2s.%2f";
		end
	end
	
	Warning('Aucun Format de Temps ...');
	return "%-1h%-1m%2s.%2f";
end

-- Suppression des Données
function OnReset(evt)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end
	
	local msg = "Confirmation RAZ ?\n\n"..
		"Toutes les données envoyées précédemment seront effacées du serveur.\n"..
		"Le renvoi d'une liste de départ supprime les temps de la manche en cours uniquement.";
	if live.panel:MessageBox(
		msg, 
		"Information Remise à zéro", 
		msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION
	) ~= msgBoxStyle.YES then
		return;
	end

	local gridmessage = live.panel:GetWindowName('gridmessage');
	gridmessage:Clear();
	
	CommandClear();
end

function OnResetSocket(evt)
	local msg = "Confirmation de la réinitialisation de la connexion :\n\n"..
		"La connexion avec la FIS sera interronpue puis réinitialisée.\n"..
		"Vous devrez éventuellent renvoyer les informations manquantes à la FIS.";
	if live.panel:MessageBox(
		msg, 
		"Reset de la connexion avec la FIS", 
		msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION
	) ~= msgBoxStyle.YES then
		return;
	end

	Info('Demande de réinitialisation ....');
	DoResetSocket();
end

function DoResetSocket()
	-- on ferme le socket
	if live.socket ~= nil then
		live.socket:Close();
	end

	live.socket_state = false;
	live.sequence_last_send = nil;
	parentFrame = wnd.GetParentFrame();
	live.socket = socketClient.Open(parentFrame, live.hostname, live.port);

	if live.socket ~= nil then
		parentFrame:Bind(eventType.SOCKET, OnSocketLive, live.socket);
	end
end

function OnWebLive(evt)
	app.LaunchDefaultBrowser(live.web);
end

-- Envoi de la totalité des informations et des temps
function OnSendAll(evt)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end
	
	-- if live.Code_manche < live.Nb_manche then
		-- local msg = "Vous ne pouvez pas envoyer les temps de la manche suivante !!\nVous devez changer de manche pour pouvoir le faire.";
		-- live.panel:MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
	-- end
	
	for manche = 1, live.Code_manche do
		live.sendchrono = DoSendStartList(manche)
		if live.sendchrono == true then
			OnSendMeteo();
			DoSendRunChrono(manche);
			if live.endrun == true then
				CommandEndRun();
			end
		end
	end
end

-- Envoi des Informations de la Course
function OnSendRaceInfo(evt)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end
	CommandRaceInfo(live.Code_manche, false)
end

-- Envoi des Heures de départ
function OnSendScheduled(evt)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end
	CommandScheduled(live.Code_manche)
end


-- Envoi des Temps de Manche 
function OnSendRunChrono(evt)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end
	live.endrun = true;
	DoSendRunChrono(live.Code_manche);
end

function DoSendRunChrono(activerun)
	
	local rc, data = app.SendNotify('<ranking_load>');
	if rc == false then
		Error("Erreur Chargement Temps de la Manche ...");
		return;
	end

	local tRanking = data.ranking;
	tRanking:OrderBy('Rang'..activerun..', Dossard');
	-- tRanking:Snapshot("tRanking.db3");
	live.rangnext = nil;
	local coltps = ""; coldiff = ""; colrank = "";

	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	for row = 0, tRanking:GetNbRows() - 1 do
		local bib = tRanking:GetCell("Dossard", row);
		local nodeRaceEvent = nil;
		if tRanking:GetCellInt("Tps"..activerun, row) == -1 then
			live.endrun = false;
			live.rangnext = live.rangnext or tRanking:GetCell("Dossard", row);
		end
		if live.method == "post" then
			for inter = 1, live.Nb_inter do
				coltps = "Tps"..activerun.."_inter"..inter;
				colrank = "Clt"..activerun.."_inter"..inter;
				coldiff = "Diff"..activerun.."_inter"..inter;
				local nodeRaceEvent = NodeRaceEventBibTime(
					tRanking:GetCell("Dossard", row),
					inter,
					tRanking:GetCellInt(coltps, row),
					tRanking:GetCellInt(coldiff, row),
					tRanking:GetCellInt(colrank, row),
					"")

				if nodeRaceEvent ~= nil then
					nodeRoot:AddChild(nodeRaceEvent);
				end
			end
			coltps = "Tps"..activerun;
			colrank = "Clt"..activerun;
			coldiff = "Diff"..activerun;
		else
			for inter = 1, live.Nb_inter do
				if activerun == 1 then
					coltps = "Tps"..activerun.."_inter"..inter;
					colrank = "Clt"..activerun.."_inter"..inter;
					coldiff = "Diff"..activerun.."_inter"..inter;
				else
					coltps = "Tps_cumul"..activerun.."_inter"..inter;
					colrank = "Clt_cumul"..activerun.."_inter"..inter;
					coldiff = "Diff_cumul"..activerun.."_inter"..inter;
				end
				local nodeRaceEvent = NodeRaceEventBibTime(
					tRanking:GetCell("Dossard", row),
					inter,
					tRanking:GetCellInt(coltps, row),
					tRanking:GetCellInt(coldiff, row),
					tRanking:GetCellInt(colrank, row),
					"")

				if nodeRaceEvent ~= nil then
					nodeRoot:AddChild(nodeRaceEvent);
				end
			end
			if activerun == 1 then
				coltps = "Tps"..activerun;
				colrank = "Clt"..activerun;
				coldiff = "Diff"..activerun;
			else
				if activerun < live.Nb_manche then
					coltps = "Tps";
					colrank = "Clt"..activerun;
					coldiff = "Diff"..activerun;
				else
					coltps = "Tps";
					colrank = "Clt";
					coldiff = "Diff";
				end
			end
		end
		nodeRaceEvent = NodeRaceEventBibTime(
			tRanking:GetCell("Dossard", row),
			-1,
			tRanking:GetCellInt(coltps, row),
			tRanking:GetCellInt(coldiff, row),
			tRanking:GetCellInt(colrank, row),
			tRanking:GetCell("Medaille"..activerun, row)
		);
		if nodeRaceEvent ~= nil then
			nodeRoot:AddChild(nodeRaceEvent);
		end
	end
	
	CreateXML(nodeRoot);
	Info('Temps de la Manche '..activerun..' envoyés ...');
	-- dossard de rang x au départ
	if  live.rangnext ~= nil then
		local nodeRaceEvent = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "raceevent");
		local nodeNextStart = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "nextstart");			
		nodeNextStart:AddAttribute("bib", live.rangnext);
		local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
		nodeRoot:AddChild(nodeRaceEvent);
		CreateXML(nodeRoot);
	end
	
	if live.endrun == true then
		CommandEndRun();
	end

end


function OnSendMeteo()
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end
	
	CommandRaceMeteo();
end

function OnSendMessage()
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end

	local dlg = wnd.CreateDialog({
		parent = live.panel,
		icon = "./res/32x32_message.png",
		label = "Envoi Message Live",
		width = 500,
		height = 150
	});
	
	dlg:LoadTemplateXML({ 
		xml = './device/live_timing.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'message'
	});

	function OnSend()
		SendMessage(dlg:GetWindowName('message'):GetValue());
		dlg:EndModal(idButton.OK);
	end
	
	-- Initialisation des variables 
	local tMessages = LoadTableMessages();
	if tMessages ~= nil then
		dlg:GetWindowName('message'):SetTable(tMessages, 'fr', 'fr');
	end
	
	-- Toolbar Principale ...
	local tb = dlg:GetWindowName('tb');
	local btnSend = tb:AddTool("Envoyer", "./res/32x32_send_green.png");
	tb:AddStretchableSpace();
	local btnClose = tb:AddTool("Fermer", "./res/32x32_close.png");
	tb:Realize();

	-- Bind
	dlg:Bind(eventType.MENU, OnSend, btnSend); 
	dlg:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL) end, btnClose)

	-- Affichage Modal
	dlg:Fit();
	dlg:ShowModal();
	
	-- Liberation Mémoire
	dlg:Delete();
	if tMessages ~= nil then tMessages:Delete(); end	
end

-- Envoi Message
function SendMessage(msg)
	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	local nodeMessage = xmlNode.Create(nodeRoot, xmlNodeType.ELEMENT_NODE, "message");
	xmlNode.Create(nodeMessage, xmlNodeType.ELEMENT_NODE, "text", msg);	
	CreateXML(nodeRoot);
end

-- Envoi Course
function OnSendStartList(evt)
	DoSendStartList(live.Code_manche);
end

function DoSendStartList(run)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return false;
	end
	local msg = "L'envoi de la liste de départ pour la manche "..run.." supprimera tous les temps de la manche.\nConfirmer-vous l'envoi ?";
	if live.panel:MessageBox(msg, "Confirmation Envoi", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return false;
	end
	-- CommandClear obligatoire car une commande endrun a peut-être déjà été envoyée qui bloquerait tout
	if run == 1 then CommandClear(); end  
	local rc, data = app.SendNotify('<ranking_load>');
	if rc == false then
		Error("Erreur Chargement Temps de la Manche ...");
		return false;
	end
	tRanking = data.ranking;
	tRanking:OrderBy('Rang'..run..', Dossard');
	if live.target ~= 'FIS' then
		CommandRaceInfo(run, false);
	else
		CommandRaceInfo(run, true);
	end
	CommandStartList(run);
	return true;
end

function OnLiveState(evt)
	if live.target == 'FFS' then
	end
	local tb = live.panel:GetWindowName('tb');

	if tb ~= nil and live.method ~= nil then
		if live.state == true then
			live.state = false;
			tb:SetToolNormalBitmap(live.btn_state, './res/chrono32x32_ko.png');
		else
			live.state = true;
			tb:SetToolNormalBitmap(live.btn_state, './res/chrono32x32_ok.png');
		end
	end
end

function CommandBibDeleted(params)
	local action = params.change;
	local nodeRaceEvent = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "raceevent");
	local passage = tonumber(params.passage);
	bib = tonumber(params.bib) or 0;
	if passage == nil then bib = 0; end
	if bib == 0 then return end
	if (action ~= "bib_deleted")  then
		if (passage == 0) then  	-- annulation du départ
			local nodeStatut = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "dns");			
			nodeStatut:AddAttribute("bib", bib);
		elseif passage > 0 then		-- annulation d'un temps inter
			nodeInter = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "inter");			
			nodeInter:AddAttribute("i", passage);
			nodeInter:AddAttribute("bib", bib);
			nodeInter:AddAttribute("correction", "y");
			nodeTime = xmlNode.Create(nodeInter, xmlNodeType.ELEMENT_NODE, "time");			
			xmlNode.Create(nodeTime, xmlNodeType.TEXT_NODE, "time", "0.00");	
		elseif passage > -1 then		-- annulation d'une arrivée
			nodeFinish = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "finish");			
			nodeFinish:AddAttribute("bib", bib);
			nodeFinish:AddAttribute("correction", "y");
			nodeTime = xmlNode.Create(nodeFinish, xmlNodeType.ELEMENT_NODE, "time");			
			xmlNode.Create(nodeTime, xmlNodeType.TEXT_NODE, "time", "0.00");	
		end
		local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
		nodeRoot:AddChild(nodeRaceEvent);
		CreateXML(nodeRoot);
	end
	app.SendNotify("<bib_load>", {bib = bib});

end

function CommandBibInsert(bib, passage)
	local passage = tonumber(passage) or -2;
	local bib = tonumber(bib) or 0;

	if passage == 0 and bib > 0 then   
		-- Start
		local nodeRaceEvent = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "raceevent");			
		local nodeBibStart = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "start");			
		nodeBibStart:AddAttribute("bib",bib);	

		local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
		nodeRoot:AddChild(nodeRaceEvent);
		CreateXML(nodeRoot);
	end
end

function CommandBibNext(bib, passage)
	local passage = tonumber(passage) or -2;
	local bib = tonumber(bib) or 0;
	
	if passage == 0 and bib > 0 then
		local nodeRaceEvent = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "raceevent");
		local nodeNextStart = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "nextstart");			
		nodeNextStart:AddAttribute("bib", bib);
		
		local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
		nodeRoot:AddChild(nodeRaceEvent);
		CreateXML(nodeRoot);
	end
end

function CommandBibPassageUpdate(params)
	-- généré par le changement manuel d'une heure de passage ou du temps net
	-- on renvoie un temps 0.00 en correction pour supprimer le temps puis un evenement <bib_time>
	-- en cas de modification sur les dossards
	-- premier passage avec action = bib_deleted 	bib devien NULL et bib va dans Dossard_anc
	-- deuxià¨me passage avec action = bib_inserted	Dossard_anc devient NULL et bib va dans Dossard
	
	local passage = tonumber(params.passage);
	local bib = tonumber(params.bib);
	local bib = params.bib; local action = params.change;
	local time = tonumber(params.time);
	if time == nil then time = 0; end
	local rank = "";
	local diff = "";
	if action == "bib_deleted" then
		time = 0;
	end
	
	local nodeRaceEvent = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "raceevent");
	if passage > 0 then 
		-- temps inter
		local nodeInter = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "inter");			
		nodeInter:AddAttribute("i", passage);
		nodeInter:AddAttribute("bib", bib);
		nodeInter:AddAttribute("correction", "y");
		local nodeTime = xmlNode.Create(nodeInter, xmlNodeType.ELEMENT_NODE, "time");			
		xmlNode.Create(nodeTime, xmlNodeType.TEXT_NODE, "time", time);	

		local nodeDiff = xmlNode.Create(nodeInter, xmlNodeType.ELEMENT_NODE, "diff");			
		xmlNode.Create(nodeDiff, xmlNodeType.TEXT_NODE, "diff", "");	

		local nodeRank = xmlNode.Create(nodeInter, xmlNodeType.ELEMENT_NODE, "rank");			
		xmlNode.Create(nodeRank, xmlNodeType.TEXT_NODE, "rank", rank);
	else
		-- arrivée
		local nodeFinish = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "finish");			
		nodeFinish:AddAttribute("bib", bib);
		nodeFinish:AddAttribute("correction", "y");
		
		local nodeTime = xmlNode.Create(nodeFinish, xmlNodeType.ELEMENT_NODE, "time");			
		xmlNode.Create(nodeTime, xmlNodeType.TEXT_NODE, "time", time);	

		local nodeDiff = xmlNode.Create(nodeFinish, xmlNodeType.ELEMENT_NODE, "diff");			
		xmlNode.Create(nodeDiff, xmlNodeType.TEXT_NODE, "diff", "");	

		local nodeRank = xmlNode.Create(nodeFinish, xmlNodeType.ELEMENT_NODE, "rank");			
		xmlNode.Create(nodeRank, xmlNodeType.TEXT_NODE, "rank", rank);
	end
	--Tps pour absent = -600, Abd = -500  ou Dsq = -800
		
	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeRaceEvent);
	CreateXML(nodeRoot);
end

function NodeRaceEventBibTime(bib, passage, total_time, total_diff, total_rank, medal)
	bib = tonumber(bib) or 0;
	passage = tonumber(passage);
	total_time = tonumber(total_time) or 0;
	total_diff = tonumber(total_diff) or 0;
	total_rank = tonumber(total_rank) or 0;
	medal = medal or '';
	
	if passage == nil or bib <= 0 then 
		return nil;
	end

	-- Creation node "raceevent"
	local nodeRaceEvent = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "raceevent");
	
	if total_time > 0 then
		local timestring = app.TimeToString(total_time, live.fmt);
		local diffstring = app.TimeToString(total_diff, '[DIFF]'..live.fmt);
		if passage > 0 then 
			-- Temps inter
			local nodeInter = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "inter");			
			nodeInter:AddAttribute("i", passage);
			nodeInter:AddAttribute("bib", bib);
			
			xmlNode.Create(nodeInter, xmlNodeType.ELEMENT_NODE, "time", timestring);			
			xmlNode.Create(nodeInter, xmlNodeType.ELEMENT_NODE, "diff", diffstring);			
			xmlNode.Create(nodeInter, xmlNodeType.ELEMENT_NODE, "rank", total_rank);			
		else 	
			-- Arrivée
			local nodeFinish = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "finish");			
			nodeFinish:AddAttribute("bib", bib);
			
			xmlNode.Create(nodeFinish, xmlNodeType.ELEMENT_NODE, "time", timestring);			
			xmlNode.Create(nodeFinish, xmlNodeType.ELEMENT_NODE, "diff", diffstring);			
			xmlNode.Create(nodeFinish, xmlNodeType.ELEMENT_NODE, "rank", total_rank);			

			if medal:len() > 0 then
				xmlNode.Create(nodeFinish, xmlNodeType.ELEMENT_NODE, "medal", medal);	
			end
		end
	elseif total_time == chrono.DSQ then
		-- DSQ
		local nodeStatut = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "dq");			
		nodeStatut:AddAttribute("bib", bib);
	elseif total_time == chrono.DNS then
		-- DNS
		local nodeStatut = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "dns");			
		nodeStatut:AddAttribute("bib", bib);
	elseif total_time == chrono.DNF then
		-- DNF
		local nodeStatut = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "dnf");			
		nodeStatut:AddAttribute("bib", bib);
	elseif total_time == -1 then
		if live.method == "post" then
			-- annulation du passage, renvoi d'un temps à 0 en correction
			if passage < 0 then 
				-- annulation de l'arrivée
				local nodeFinish = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "finish");			
				nodeFinish:AddAttribute("bib", bib);
				nodeFinish:AddAttribute("correction", "y");
				xmlNode.Create(nodeFinish, xmlNodeType.ELEMENT_NODE, "time", "0");			
			elseif passage == 0 then 	
				-- annulation du départ
			else
				-- annulation d'un temps inter
				local nodeInter = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "inter");			
				nodeInter:AddAttribute("i", passage);
				nodeInter:AddAttribute("bib", bib);
				xmlNode.Create(nodeInter, xmlNodeType.ELEMENT_NODE, "time", "0");			
			end
		end
	end

	return nodeRaceEvent;
end

function CommandClear()
	-- Remise à  Zéro des compteurs 
	live.sequence_send = 0;
	live.sequence_ack = 0;
	live.node:ChangeAttribute('send_'..live.codex, live.sequence_send);
	live.node:ChangeAttribute('ack_'..live.codex, live.sequence_ack);
	live.sequence_last_send = nil;

	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	local nodeCommand = xmlNode.Create(nodeRoot, xmlNodeType.ELEMENT_NODE, "command");
	local nodeClear = xmlNode.Create(nodeCommand, xmlNodeType.ELEMENT_NODE, "clear");
	CreateXML(nodeRoot);
	Info("CommandClear envoyée");
	if site_distant then
		local params_distant = {};
		params_distant.Nom = live.tables.Evenement:GetCell('Nom', 0);
		params_distant.Code_saison = live.tables.Evenement:GetCell('Code_saison', 0);
		params_distant.Date_epreuve = live.tables.Epreuve:GetCell("Date_epreuve", 0);
		params_distant.Comite = live.tables.Evenement:GetCell('Code_comite', 0)
		params_distant.Codex = live.codex;
		params_distant.Code_manche = live.Code_manche;
		params_distant.Action = 'Clear';
		params_distant.Web = live.web;
		params_distant.Code_entite = live.Code_entite;
		params_distant.Target = live.target;
		ToDoSiteDistant(params_distant); 
	end
end

function CommandEndRun()
	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	local nodeCommand = xmlNode.Create(nodeRoot, xmlNodeType.ELEMENT_NODE, "command");
	xmlNode.Create(nodeCommand, xmlNodeType.ELEMENT_NODE, "endrun");
	CreateXML(nodeRoot);
	Info("Tag 'endrun' envoyée");
end

function CommandRaceMeteo()
	function FindCode(pTable, legend)
		local code = "";
		local r = pTable:GetIndexRow('Legend', legend);
		if r then
			code = pTable:GetCell('Code', r);
		end
		return code
	end
	ReadMeteo();
	local nodeMeteo = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "meteo");
	-- weather
	local nodeWeather = xmlNode.Create(nodeMeteo, xmlNodeType.ELEMENT_NODE, "weather");			
	xmlNode.Create(nodeWeather, xmlNodeType.TEXT_NODE, "weather", FindCode(tWeather,live.weather));	

	-- temperature
	local nodeTemperature = xmlNode.Create(nodeMeteo, xmlNodeType.ELEMENT_NODE, "temperature");			
	xmlNode.Create(nodeTemperature, xmlNodeType.TEXT_NODE, "temperature", live.temperature);	
	
	-- wind
	local nodeWind = xmlNode.Create(nodeMeteo, xmlNodeType.ELEMENT_NODE, "wind");			
	xmlNode.Create(nodeWind, xmlNodeType.TEXT_NODE, "wind", FindCode(tWind,live.wind));	
	
	-- snowtemperature
	local nodeSnowTemperature = xmlNode.Create(nodeMeteo, xmlNodeType.ELEMENT_NODE, "snowtemperature");			
	xmlNode.Create(nodeSnowTemperature, xmlNodeType.TEXT_NODE, "snowtemperature", live.snowtemperature);	
	
	-- snowcondition
	local nodeSnowCondition = xmlNode.Create(nodeMeteo, xmlNodeType.ELEMENT_NODE, "snowcondition");			
	xmlNode.Create(nodeSnowCondition, xmlNodeType.TEXT_NODE, "snowcondition", FindCode(tSnowCondition, live.snowcondition));	
	
	-- humidity
	local nodeHumidity = xmlNode.Create(nodeMeteo, xmlNodeType.ELEMENT_NODE, "humidity");			
	xmlNode.Create(nodeHumidity, xmlNodeType.TEXT_NODE, "humidity", live.humidity);
	
	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeMeteo);
	
	CreateXML(nodeRoot);
	Info("Tag meteo envoyé");
end

function CommandStartList(activerun)
	local rc, data = app.SendNotify('<ranking_load>');
	if rc == false then
		Error("Erreur Chargement Liste de Départ ...");
		live.ok = false;
		return;
	end

	local tRanking = data.ranking;
	tRanking:OrderBy('Rang'..activerun..', Dossard');

	-- Génération des balises 
	local nodeStartList = nil;
	if live.target ~= 'FIS' then
		nodeStartList = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "startlist");
	else
		nodeStartList = xmlNode.Create(nodeRoot, xmlNodeType.ELEMENT_NODE, "startlist");
	end
	nodeStartList:AddAttribute("runno",activerun);			
	
	local countRacer = 0;
	live.rangnext = nil;
	for row = 0, tRanking:GetNbRows() - 1 do
		local rang = tRanking:GetCellInt("Rang"..activerun, row, 0);
		if row == 0 then 
			live.rangnext = tRanking:GetCell("Dossard", row);
		end
		if activerun == 1 or rang > 0 then 
			local bib = tRanking:GetCell("Dossard", row);

			-- Balise "racer"
			local nodeRacer = xmlNode.Create(nodeStartList, xmlNodeType.ELEMENT_NODE, "racer");			
			countRacer = countRacer + 1;
			nodeRacer:AddAttribute("order", countRacer);		
				
			-- Balises FIS 
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "bib", tRanking:GetCell("Dossard", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "lastname", tRanking:GetCell("Nom", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "firstname", tRanking:GetCell("Prenom", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "nat", tRanking:GetCell("Nation", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "fiscode", string.sub(tRanking:GetCell("Code_coureur", row),4));			
				
			-- Balises FFS
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "FFS_code_coureur", tRanking:GetCell("Code_coureur", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "FFS_sexe", tRanking:GetCell("Sexe", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "FFS_an", tRanking:GetCell("An", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "FFS_categ", tRanking:GetCell("Categ", row));			

			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "FFS_club", tRanking:GetCell("Club", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "FFS_comite", tRanking:GetCell("Comite", row));			
			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "FFS_equipe", tRanking:GetCell("Equipe", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "FFS_groupe", tRanking:GetCell("Groupe", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "FFS_critere", tRanking:GetCell("Critere", row));			
			xmlNode.Create(nodeRacer, xmlNodeType.ELEMENT_NODE, "FFS_distance", tRanking:GetCell("Distance", row));			
		end
	end
	
	-- command activerun
	local nodeCommand = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "command");
	local nodeActiveRun = xmlNode.Create(nodeCommand, xmlNodeType.ELEMENT_NODE, "activerun");
	nodeActiveRun:AddAttribute("no",activerun);
	
	-- Regroupement <startlist> et <command>
	
	-- si live.target == 'FIS', le nodeRoot a déjà été créé fans le raceinfo;
	if live.target ~= 'FIS' then
		nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	end
	nodeRoot:AddChild(nodeStartList);
	nodeRoot:AddChild(nodeCommand);
	CreateXML(nodeRoot);
	
	Info("Liste de départ manche "..activerun.." envoyée");
	
	-- dossard de rang 1 au départ
	if live.rangnext ~= nil then
		local nodeRaceEvent = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "raceevent");
		local nodeNextStart = xmlNode.Create(nodeRaceEvent, xmlNodeType.ELEMENT_NODE, "nextstart");			
		nodeNextStart:AddAttribute("bib", live.rangnext);
		local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
		nodeRoot:AddChild(nodeRaceEvent);
		CreateXML(nodeRoot);
		Info("dossard suivant "..live.rangnext.. " envoyé");
	end
	CommandScheduled(activerun);
end

function CommandRaceInfo(activerun, bolPlusStartList)
	-- bolPlusStartList n'est utilisé que pour le live FIS.
	-- bolPlusStartList = true si on concatène la start list. Dans ce cas, on ne termine pas le XML
	-- bolPlusStartList = false si on envoi la commande raceinco seule. Dans ce cas, on termine le XML
	local tEvenement = live.tables.Evenement;
	local tPistes = live.tables.Pistes;
	local tEpreuve = live.tables.Epreuve;
	local tEpreuveAlpine = live.tables.Epreuve_Alpine;
	local tEpreuveAlpineManche = live.tables.Epreuve_Alpine_Manche;
	if tPistes:GetNbRows() == 0 then
		tPistes:AddRow();
	end
		
	-- Génération des balises 
	local nodeRaceinfo = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "raceinfo");
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "event", tEvenement:GetCell('Nom',0));	
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "name", tEpreuve:GetCell("Code_discipline", 0)..' '..tEpreuve:GetCell("Sexe", 0));			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "slope", tPistes:GetCell('Nom_piste',0));			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "discipline", tEpreuve:GetCell("Code_discipline", 0));			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "gender", tEpreuve:GetCell("Sexe", 0));			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "category", live.category );
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "place", tEvenement:GetCell('Station',0));			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "tempunit", 'c');			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "longunit", 'm');			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "speedunit", 'Kmh');	
	
	-- Balises FFS
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_organisateur", tEvenement:GetCell('Organisateur',0));			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_code_club", tEvenement:GetCell('Code_club',0));			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_club", tEvenement:GetCell('Club',0));			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_comite", tEvenement:GetCell('Code_comite',0));			
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_activite", live.Code_activite);	
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_entite", live.Code_entite);

	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_software", app.GetName().." "..device.GetInformation().version);		
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_test", live.node:GetAttribute('ffs_test'));			
	
	live.Columns_live1 = "Code_coureur,Dossard,Nom,Prenom,Sexe,Categ,Club,Comite,Nation,Tps1,Clt1,Ecart1,Medaille1";
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_columns_live1", live.Columns_live1);	
	live.Columns_live2 = "Code_coureur,Dossard,Nom,Prenom,Sexe,Categ,Club,Comite,Nation,Tps1,Clt1,Ecart1,Tps2,Clt2,Ecart2,Tps,Clt,Ecart";
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_columns_live2", live.Columns_live2);	

	
	local commentaire = tEvenement:GetCell('Commentaire_live',0);
	if commentaire:len() == 0 then
		local discipline = tEpreuve:GetCell("Code_discipline", 0);
		if live.Code_entite == "ESF" then
			-- ESF
			if discipline == 'F' then commentaire = 'Flèche';
			elseif discipline == 'C' then commentaire = 'Chamois';
			elseif discipline == 'F' then commentaire = 'Fusée';
			else commentaire = discipline;
			end
			commentaire = commentaire..' du '..tEpreuve:GetCell("Date_epreuve", 0);
			if tEpreuve:GetCell("Tir", 0):len() > 0 then
				commentaire = commentaire..' à '..tEpreuve:GetCell("Tir", 0);
			end
		end
	end
	
	xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_commentaire", commentaire);	

	for i=0, tEpreuve:GetNbRows()-1 do
		local nodeEpreuve = xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "FFS_epreuve");
			
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_activite", live.Code_activite);	
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_entite", live.Code_entite);	
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_saison", tEpreuve:GetCell('Code_saison', i));	
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_origine", tEpreuve:GetCell('Code_origine', i));	
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_discipline", tEpreuve:GetCell('Code_discipline', i));	
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_niveau", tEpreuve:GetCell('Code_niveau', i));	
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_regroupement", tEpreuve:GetCell('Code_regroupement', i));
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_grille_categorie", tEpreuve:GetCell('Code_grille_categorie', i));	
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_sexe", tEpreuve:GetCell('Sexe', i));	
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_categorie", tEpreuve:GetCell('Code_categorie', i));	
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_distance", tEpreuve:GetCell('Distance', i));	
		xmlNode.Create(nodeEpreuve, xmlNodeType.ELEMENT_NODE, "FFS_date_epreuve", tEpreuve:GetCell('Date_epreuve', i, '%4Y-%2M-%2D'));	
	end
	
	if live.dataForerunner ~= nil then
		-- Ouvreur ESF
		local tForerunner = live.dataForerunner.forerunner;
		if tForerunner ~= nil and tForerunner:GetNbRows() > 0 then
			local nodeOuvreur = xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "ESF_ouvreur");
		
			xmlNode.Create(nodeOuvreur, xmlNodeType.ELEMENT_NODE, "ESF_ouvreur_dossard", tForerunner:GetCell('Info', 0));	
			xmlNode.Create(nodeOuvreur, xmlNodeType.ELEMENT_NODE, "ESF_ouvreur_matric", tForerunner:GetCell('Matric', 0));	
			xmlNode.Create(nodeOuvreur, xmlNodeType.ELEMENT_NODE, "ESF_ouvreur_nom", tForerunner:GetCell('Nom', 0));	
			xmlNode.Create(nodeOuvreur, xmlNodeType.ELEMENT_NODE, "ESF_ouvreur_prenom", tForerunner:GetCell('Prenom', 0));	
			xmlNode.Create(nodeOuvreur, xmlNodeType.ELEMENT_NODE, "ESF_ouvreur_tps", tForerunner:GetCell('Tps', 0));	
			xmlNode.Create(nodeOuvreur, xmlNodeType.ELEMENT_NODE, "ESF_ouvreur_handicap", tForerunner:GetCell('Handicap', 0));	
			xmlNode.Create(nodeOuvreur, xmlNodeType.ELEMENT_NODE, "ESF_ouvreur_base", tForerunner:GetCell('Base', 0));	
			xmlNode.Create(nodeOuvreur, xmlNodeType.ELEMENT_NODE, "ESF_ouvreur_tps_chrono", tForerunner:GetCellInt('Tps', 0));	
			xmlNode.Create(nodeOuvreur, xmlNodeType.ELEMENT_NODE, "ESF_ouvreur_base_chrono", tForerunner:GetCellInt('Base', 0));	
		end
	end
	
	if live.dataMedals ~= nil then
		-- Médailles ESF
		local tMedals = live.dataMedals;
		if tMedals ~= nil and tMedals:GetNbRows() > 0 then
			local nodeMedaille = xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "ESF_medaille");
		
			for m=1,tMedals:GetNbColumns()-1 do
				local node = xmlNode.Create(nodeMedaille, xmlNodeType.ELEMENT_NODE, "ESF_medaille"..tostring(m));
				node:AddAttribute('nom', tMedals:GetColumnLabel(m));
				node:AddAttribute('pourcentage', tMedals:GetCell(m,0));
				node:AddAttribute('temps', tMedals:GetCell(m,1));
			end
		end
	end
	local firstrun = activerun;
	local lastrun = activerun;
	-- if live.target == 'FIS' then	
		-- firstrun = 1;
		-- lastrun = live.Nb_manche;
	-- end
	for run = firstrun, lastrun do
		-- run x 
		nodeRun = xmlNode.Create(nodeRaceinfo, xmlNodeType.ELEMENT_NODE, "run");			
		nodeRun:AddAttribute("no", run);			
		
		-- nodeRun Childs ...
		if tEpreuve:GetCell('Code_activite', 0) == 'ALP' then
			if tEpreuveAlpineManche:GetNbRows() >= run then
			
				-- discipline
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "discipline", tEpreuve:GetCell('Code_discipline', 0));	
				
				-- start
				local start = tonumber(tEpreuveAlpineManche:GetCell("Altitude_Depart",run-1)) or 0;
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "start", start);	

				-- finish
				local finish = tonumber(tEpreuveAlpineManche:GetCell("Altitude_Arrivee",run-1)) or 0;
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "finish", finish);	
				
				-- height
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "height", start-finish);	
			
				-- length 
				local length = tonumber(tEpreuveAlpineManche:GetCell("Longueur",run-1)) or 0;
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "length", length);	
				
				-- gates
				local gates = tEpreuveAlpineManche:GetCellInt("Nombre_de_portes",run-1,0);
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "gates", gates);	
				
				-- turninggates
				local turninggates = tEpreuveAlpineManche:GetCellInt("Changement_de_directions",run-1,0);
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "turninggates", turninggates);	

				-- year
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "year", tEpreuve:GetCell("Date_epreuve", 0, '%4Y'));	
				
				-- month
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "month", tEpreuve:GetCell("Date_epreuve", 0, '%2M'));	

				-- day
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "day", tEpreuve:GetCell("Date_epreuve", 0, '%2D'));	
				local heure = ""; local minute = "";
				local heure_depart = tEpreuveAlpineManche:GetCell("Heure_depart", run-1);
				local x, y = string.find(heure_depart, "%D");  -- tout ce qui n'est pas un chiffre
				if x ~= nil then  -- position du séparateur
					heure = string.sub(heure_depart, 1, x-1);
					heure = string.format("%02d", tonumber(heure) or 0);
					minute = string.sub(heure_depart, x+1);
					minute = string.format("%02d", tonumber(minute) or 0);
				end
				
				-- hour
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "hour", heure);	

				-- minute
				xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "minute", minute);	
				
				--racedef  
				local nodeRacedef = xmlNode.Create(nodeRun, xmlNodeType.ELEMENT_NODE, "racedef");	
					
				-- nodeRacedef Childs ...
				local nbInter = tEpreuveAlpineManche:GetCellInt("Nb_temps_inter",run-1, 0);
				for inter = 1, nbInter do

					local nodeInter = xmlNode.Create(nodeRacedef, xmlNodeType.ELEMENT_NODE, "inter");
					nodeInter:AddAttribute("i", inter);
							
					if tEvenement:GetCell('Code_activite', 0)  ~= "ALP" then
						-- distance
						xmlNode.Create(nodeInter, xmlNodeType.ELEMENT_NODE, "distance");
								
						--finish
						xmlNode.Create(nodeInter, xmlNodeType.ELEMENT_NODE, "finish");	
					end
				end
			end
		end
	end

	-- command activerun
	local nodeCommand = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "command");
	local nodeActiveRun = xmlNode.Create(nodeCommand, xmlNodeType.ELEMENT_NODE, "activerun");
	nodeActiveRun:AddAttribute("no",activerun);
	
	-- Regroupement <race_info> et <command>
	nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
	nodeRoot:AddChild(nodeRaceinfo);
	if bolPlusStartList == false then
		-- on ne concatène pas le child nodeCommand en FIS, si on doit ajouter la liste de départ;
		if live.target ~= 'FIS' then
			nodeRoot:AddChild(nodeCommand);
		end
		CreateXML(nodeRoot);
		Info("Tag raceinfo envoyé");
	end

	if site_distant then
		local params_distant = {};
		params_distant.Nom = live.tables.Evenement:GetCell('Nom', 0);
		params_distant.Code_saison = live.tables.Evenement:GetCell('Code_saison', 0);
		params_distant.Date_epreuve = live.tables.Epreuve:GetCell("Date_epreuve", 0);
		params_distant.Comite = live.tables.Evenement:GetCell('Code_comite', 0)
		params_distant.Codex = live.codex;
		params_distant.Code_manche = live.Code_manche;
		params_distant.Action = 'Raceinfo';
		params_distant.Web = live.web;
		params_distant.Code_entite = live.Code_entite;
		params_distant.Target = live.target;
		ToDoSiteDistant(params_distant); 
	end
end

function CommandScheduled(run)
	local tEpreuve = live.tables.Epreuve;

	if tEpreuve:GetCell('Code_activite', 0) == 'ALP' then
		local tEpreuveAlpine = live.tables.Epreuve_Alpine;
		local tEpreuveAlpineManche = live.tables.Epreuve_Alpine_Manche;
		local heure = ""; local minute = ""; local stringtime = "";
		if tEpreuveAlpineManche ~= nil then
			local heure_depart = tEpreuveAlpineManche:GetCell("Heure_depart", run-1);
			if heure_depart == "" then
				heure_depart = '00:00';
			end
			local x, y = string.find(heure_depart, "%D");  -- tout ce qui n'est pas un chiffre
			if x == nil then  -- position du séparateur
				return;
			else
				heure = string.sub(heure_depart, 1, x-1);
				heure = string.format("%02d", tonumber(heure) or 0);
				minute = string.sub(heure_depart, x+1);
				minute = string.format("%02d", tonumber(minute) or 0);
				stringtime = heure..":"..minute;
			end
			local nodeCommand = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "command");
			local nodeScheduled = xmlNode.Create(nodeCommand, xmlNodeType.ELEMENT_NODE, "scheduled");
			nodeScheduled:AddAttribute("runno", run);
			-- nodeScheduled Childs ...
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "year", tEpreuve:GetCell("Date_epreuve", 0, '%4Y'));	
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "month", tEpreuve:GetCell("Date_epreuve", 0, '%2M'));	
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "day", tEpreuve:GetCell("Date_epreuve", 0, '%2D'));	
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "cettime", stringtime);
			xmlNode.Create(nodeScheduled, xmlNodeType.ELEMENT_NODE, "loctime", stringtime);
			-- Regroupement <scheduled> et <command>
			local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
			nodeRoot:AddChild(nodeCommand);
			CreateXML(nodeRoot);
			Info("Tag scheduled envoyé pour la manche "..run.." = "..stringtime);
		end
	end
end

function CreateXML(nodeRoot)
	if live.state == false then
		return false;
	end
	assert(app.GetNameSpace(nodeRoot) == 'xmlNode');
	
	local doc = xmlDocument.Create();
	if doc:SetRoot(nodeRoot) == true then

		nodeRoot:AddAttribute("codex", live.codex);
		nodeRoot:AddAttribute("passwd", live.pwd);
	
		-- Incrementation sequence
		IncrementationSequenceSend();
		nodeRoot:AddAttribute("sequence", live.sequence_send);
		
		-- timestamp
		nodeRoot:AddAttribute("timestamp", os.date('%H:%M:%S', os.time()));
	end

	doc:SaveFile(live.directory..'/live'..live.codex..'_'..tostring(live.sequence_send)..'.xml');
	Info('CreateXML '..live.directory..'/live'..live.codex..'_'..tostring(live.sequence_send)..'.xml');
	doc:Delete();

	SendNextPacket();
end

-- <bib_delete> Notification
function OnNotifyBibDelete(key, params)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end
	
	local bib = tonumber(params.bib) or 0;
	if bib > 0 then CommandBibDeleted(params); end
	return true;
end

-- <bib_insert> Notification
function OnNotifyBibInsert(key, params)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end
	
	CommandBibInsert(params.bib, params.passage); 
end

-- <bib_next> Notification
function OnNotifyBibNext(key, params)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end
	CommandBibNext(params.bib, params.passage); 
end

-- <passage_add> Notification
function OnNotifyBibPassageAdd(key, params)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end

	if app.GetAuiFrame():GetModeChrono() == 'net_time' then
		-- Uniquement en Mode Temps Net ...
		if params.time == chrono.DNF and params.passage == -1 then
			OnNotifyBibTime('<bib_time>', { bib = params.bib, passage = -1, total_time = chrono.DNF });
		elseif params.time == chrono.DNS and params.passage == 0 then
			OnNotifyBibTime('<bib_time>', { bib = params.bib, passage = 0, total_time = chrono.DNS });
		elseif params.time > 0 then
			CommandBibInsert(params.bib, params.passage); 
		end
	end
end

-- <passage_update> Notification
function OnNotifyBibPassageUpdate(key, params) -- correction en changeant le temps
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end
--	CommandBibPassageUpdate(params);
end

-- <bib_time> Notification
function OnNotifyBibTime(key, params)
	if live.state == false then
		Error("Feu au Rouge : Aucune Action possible ...");
		return;
	end

	if live.method == 'post' then
		-- en FFS ou ESF on envoi pas le temps total mais le temps de Manche
		params.total_time = params.time;
		params.total_diff = params.diff;
		params.total_rank = params.rank;
	end
	
	local nodeRaceEvent = NodeRaceEventBibTime(
		params.bib, 
		params.passage, 
		params.total_time, 
		params.total_diff, 
		params.total_rank,
		params.medal
	);
	
	if nodeRaceEvent ~= nil then
		local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "livetiming");
		nodeRoot:AddChild(nodeRaceEvent);
		CreateXML(nodeRoot);
	end
end

-- <forerunner_best_base_time> Notification
function OnNotifyForerunnerBestBaseTime(key, params)

	local rc, dataMedals = app.SendNotify('<medals_load>');
	local rc, dataForerunner = app.SendNotify('<forerunner_load>');
		
	if dataMedals and dataForerunner and live.Code_entite == 'ESF' then
		live.dataForerunner = dataForerunner;
		live.dataMedals = dataMedals.medals;
		CommandRaceInfo(1, false);
	end
end

function OnNotifyRunErase(key, params)
	-- adv.Alert("début de récupération de params  OnNotifyRunErase");
    -- for k,v in pairs(params) do
		-- adv.Alert("k = "..k..", v = "..tostring(v));
    -- end
	-- adv.Alert("fin de récupération de params");
	local code_manche = tonumber(params.code_manche) or 1;
	DoSendStartList(code_manche)
	return true;
end

function ReadMeteo()
	local stringXml = live.directory.."/meteo"..live.codex..".xml";
	f = io.open(stringXml)  			-- Trying to open some file. If the file exists, than
	if f == nil then                  	-- variable f will contain some table, else f will be nil.
		return
	else	
		io.close(f)
	end
	local doc = xmlDocument.Create(stringXml);
	if doc ~= nil then
		local root = doc:GetRoot();
		if root ~= nil then
			local child = xmlNode.GetChildren(root);
			live.weather = ""; live.temperature = ""; live.wind = ""; live.snowtemperature = ""; live.snowcondition = ""; live.humidity= "0";
			while child ~= nil do
				live.weather = child:GetAttribute("weather");
				live.temperature = child:GetAttribute("temperature");
				live.wind = child:GetAttribute("wind");
				live.snowtemperature = child:GetAttribute("snowtemperature");
				live.snowcondition = child:GetAttribute("snowcondition");
				live.humidity = child:GetAttribute("humidity");
				child = child:GetNext();
			end
		end
	end
	if doc ~= nil then
		doc:Delete();
	end
end

function IsSignatureEsfOk(code, signature)
	local url = "http://37.187.252.152/resultat/service/is_signature_ok.php?esf="..code.."&signature="..signature;
	local jsonText = curl.GET(url);
	if string.find(jsonText, '"success":true') ~= nil then
		return true;
	else
		return false;
	end
end
