dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 1.3, code = 'phone_passage', name = 'Phone Passage', class = 'chrono' }
end	

function Error(txt)
	app.GetAuiMessage():AddLineError(txt);
end

function Alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function Success(txt)
	app.GetAuiMessage():AddLineSuccess(txt);
end

function device.OnInit(params, node)
	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	theParams = params;
	node = node;
	
	-- Création des variables pour la gestion en récupérant les valeurs dans config
	PhonePassageType = node:GetAttribute('PhonePassageType');
	-- Url Init ...
	Alert("PhonePassageType = "..PhonePassageType);
	if PhonePassageType == 'FFS' then
		device.url = 'http://www.agil.fr/phone_passage';
	elseif PhonePassageType == 'FFS' then
		device.url = 'http://localhost/phone_passage';
	elseif PhonePassageType == 'Perso' then
		device.url = node:GetAttribute('config_AdrServeurPhonePassage');
	end
	
	device.url = 'http://www.agil.fr/phone_passage';
	Alert("device.url"..device.url);
	-- Récupération des infos infos de la course selon le contexte
	signature = '';
	codex = '';
	local rc, raceInfo = app.SendNotify('<race_load>');
	if rc == true then
		local tEvenement = raceInfo.tables.Evenement;
		if tEvenement:GetCell('Code_entite',0) == 'ESF' then
			codex = raceInfo.Code_esf..'-'..tEvenement:GetCell('Code',0);
		else
			codex = tEvenement:GetCell('Codex', 0);
		end
		signature = tEvenement:GetCell('Commentaire',0)
	end

	session_id = 0;
	local doc = curl.GET_XML(device.url..'/session.php?codex='..codex..'&signature='..signature);
	if doc ~= nil then
		local root = doc:GetRoot();
		if root ~= nil then
			if root:HasAttribute('session_id') then
				session_id = tonumber(root:GetAttribute('session_id'));
			end
		end
		doc:Delete();
	end
	
	if session_id >= 0 then
		Success("Phone Passage Codex = "..codex);
		Success("Phone Signature = "..signature);
		Alert("Session ID = "..session_id);
	end

	-- Ack Init ...
	stackAck = {};
	lastAck = -1;
	
	local doc = curl.GET_XML(device.url..'/ack.php?id='..session_id);
	if doc ~= nil then
		device.ReadAckXML(doc);
		doc:Delete();
	end

	-- Timer Init ...
	local frame = app.GetAuiFrame();
	device.timer = timer.Create(frame);
	local timerID =  device.timer:GetId();
	device.timer:Start(1000);
	frame:Bind(eventType.TIMER, device.OnTimer, device.timer, device);
end

function device.OnTimer(evt, device)
	local doc = curl.GET_XML(device.url..'/passage.php?id='..session_id..'&ack='..lastAck);
--	Alert(device.url..'/passage.php?id='..session_id..'&ack='..lastAck);
	if doc ~= nil then
		device.ReadPassageXML(doc);
		doc:Delete();
	end
end

function device.ReadAckXML(doc)
	local root = doc:GetRoot();
	if root ~= nil then
		if root:HasAttribute('ack') then
			local ack = tonumber(root:GetAttribute('ack'));
			if ack >= 0 and stackAck[ack] == nil then
				lastAck = ack;
			end
		end
	end
end

function device.ReadPassageXML(doc)
	local root = doc:GetRoot();
	if root ~= nil then
		if root:HasAttribute('ack') then
			local ack = tonumber(root:GetAttribute('ack'));
			if ack >= 0 and stackAck[ack] == nil then
				stackAck[ack] = true;
				lastAck = ack;
		
				local chrono = root:GetAttribute('chrono', '');
				local passage = root:GetAttribute('passage', '0');
				local bib = root:GetAttribute('bib');
				if chrono ~= '' and tonumber(chrono) > 0 then
					AddTimePassage(chrono, passage, bib);
				end
			end
		end
	end
end

function device.OnClose()
	if device.timer ~= nil then
		device.timer:Delete();
		device.timer = nil;
	end
end

function AddTimePassage(chrono, passage, bib)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'phone_passage' }
	);
end

-- Configuration du Device
function device.OnConfiguration(node)
	PhonePassage = {};
	Config = {};
	-- width = longueur; height = largeur;
	local dlg_PhonePassage = wnd.CreateDialog(
		{
			parent = PhonePassage.panel,
			icon = "./res/32x32_ffs.png",
			label = "Configuration du Phone Passage",
			width = 900,
			height = 950
		})
		dlg_PhonePassage:LoadTemplateXML({ 
		xml = './device/PhonePassage.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'config_PhonePassage'
	});

	dlg_PhonePassage:GetWindowName('PhonePassageType'):SetValue(node:GetAttribute('PhonePassageType', ''));
	dlg_PhonePassage:GetWindowName('config_AdrServeurPhonePassage'):SetValue(node:GetAttribute('config_AdrServeurPhonePassage', 'http://localhost/phone_passage'));

	if node:GetAttribute('bib') == "1" then
		dlg_PhonePassage:GetWindowName('checkbox_config_Lect_Dos'):SetValue(true);
	else
		dlg_PhonePassage:GetWindowName('checkbox_config_Lect_Dos'):SetValue(false);
	end

-- combo RaceResultTypeBox
		dlg_PhonePassage:GetWindowName('PhonePassageType'):Clear();
		dlg_PhonePassage:GetWindowName('PhonePassageType'):Append('FFS');
		dlg_PhonePassage:GetWindowName('PhonePassageType'):Append('Localhost');
		dlg_PhonePassage:GetWindowName('PhonePassageType'):Append('Perso');
		dlg_PhonePassage:GetWindowName('PhonePassageType'):SetValue(node:GetAttribute('PhonePassageType', ''));


-- Toolbar Principale ...
	Config.tb = dlg_PhonePassage:GetWindowName('tb');
	btnSave = Config.tb:AddTool("Valider", "./res/32x32_save.png");
	Config.tb:AddStretchableSpace();
	btnClose = Config.tb:AddTool("Fermer", "./res/32x32_close.png");
	Config.tb:Realize();

	function OnSaveConfig(evt)
		node:ChangeAttribute('PhonePassageType', dlg_PhonePassage:GetWindowName('PhonePassageType'):GetValue());
		node:ChangeAttribute('config_AdrServeurPhonePassage', dlg_PhonePassage:GetWindowName('config_AdrServeurPhonePassage'):GetValue());
		if dlg_PhonePassage:GetWindowName('checkbox_config_Lect_Dos'):GetValue() == true then
			node:ChangeAttribute('bib',  "1");
		else
			node:ChangeAttribute('bib',  "0");
		end


		local doc = app.GetXML();
		doc:SaveFile();
		dlg_PhonePassage:EndModal(idButton.OK);
	end

		dlg_PhonePassage:Bind(eventType.MENU, OnSaveConfig, btnSave); 
		dlg_PhonePassage:Bind(eventType.MENU, function(evt) dlg_PhonePassage:EndModal(idButton.CANCEL) end, btnClose);

	-- Lancement de la dialog
	dlg_PhonePassage:Fit();
	dlg_PhonePassage:ShowModal();

	-- Liberation Memoire
	dlg_PhonePassage:Delete();
	
	function OnExit(evt)
	dlg_PhonePassage:EndModal();
	end
	
end
