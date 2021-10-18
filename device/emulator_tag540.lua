-- SERVER EMULATION TAG-540
dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

myServer = nil; -- Server de Socket
device = {};

function Alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function Warning(txt)
	app.GetAuiMessage():AddLineWarning(txt);
end

function Error(txt)
	app.GetAuiMessage():AddLineError(txt);
end

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.9, 
		code = 'emulator_tag_cp540', 
		name = 'Emulation TAG Heuer CP-540', 
		class = 'network' 
	};
end	

function device.OnConfiguration(node)
	device.address = node:GetAttribute('address');
	if device.address:len() < 2 then
		device.address = app.GetCurrentIPAddress();
	end
	device.port = node:GetAttribute('port');
	if device.port:len() < 2 then
		device.port = 7000;
	end
	
	local dlg = wnd.CreateDialog({
		icon = './res/32x32_chrono.png',
		label = "Configuration de l'émulateur TAG 540",
		width = 300,
		height = 200
	});
	
	dlg:LoadTemplateXML({ 
		xml = './device/emulator_tag540.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'config'
	});
	
	dlg:GetWindowName('address'):SetValue(device.address);
	dlg:GetWindowName('port'):SetValue(device.port);

	-- Toolbar Principale ...
	local tb = dlg:GetWindowName('tb');
	local btnSave = tb:AddTool("Valider", "./res/32x32_ok.png");
	tb:AddStretchableSpace();
	local btnClose = tb:AddTool("Fermer", "./res/vpe32x32_close.png");
	tb:Realize();

	function OnSaveConfig(evt)
		local doc = app.GetXML();
		device.address = dlg:GetWindowName('address'):GetValue();
		device.port = dlg:GetWindowName('port'):GetValue();
		node:ChangeAttribute('address', device.address);
		node:ChangeAttribute('port', device.port);
		doc:SaveFile(app.GetPath()..'/'..app.GetName()..'.xml');
		dlg:EndModal();
	end
	
	dlg:Bind(eventType.MENU, OnSaveConfig, btnSave); 
	
	dlg:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL) end, btnClose);

	dlg:GetWindowName('address'):SetValue(device.address);
	dlg:GetWindowName('port'):SetValue(device.port);

	dlg:Fit();
	dlg:ShowModal();
end

-- Ouverture
function device.OnInit(params, node)

	-- Appel OnInit Metatable
	mt_device.OnInit(params);

	device.address = node:GetAttribute('address');
	if device.address:len() < 2 then
		device.address = app.GetCurrentIPAddress();
	end
	device.port = node:GetAttribute('port');
	if device.port:len() < 2 then
		device.port = 7000;
	end
	
	-- Creation du Server de Socket "TAG-540"
	local mainFrame = app.GetAuiFrame();
	
	myServer = socketServer.Open(mainFrame, device.address, device.port);
	mainFrame:Bind(eventType.SOCKET, OnSockServer, myServer:GetId());
	Warning("Ouverture Socket "..device.address..':'..device.port);
		
	-- notification à prendre en compte
	app.BindNotify("<passage_insert>", OnNotifyPassageInserted);
	app.BindNotify("<bib_time>", OnNotifyBibTime);
end

-- Fermeture
function device.OnClose()
	if myServer ~= nil then
		myServer:Close();
	end

	-- Appel OnClose Metatable
	mt_device.OnClose();
end

function OnSockServer(evt)
	local sockEvent = evt:GetSocketEvent();
	
	if sockEvent == socketNotify.CONNECTION then
		-- CONNECTION
		local sockNew = myServer:Accept();
		if sockNew ~= nil then
			if myServer:AddClient(sockNew) then
				local tPeer = sockNew:GetPeer();
				Warning("<SERVER TAG-540 CONNECT "..tPeer.ip..':'..tPeer.port..'>');
				return
			end
		end
	elseif sockEvent == socketNotify.LOST then
		-- LOST
		Warning('<SERVER TAG-540 LOST>');
	elseif sockEvent == socketNotify.INPUT then
		-- INPUT
		myServer:ReadToCircularBuffer(evt:GetSocket());
		Warning('<SERVER TAG-540 INPUT !!!>');
	else
		-- ???
		Warning("<EVENT UNKNOWN "..tostring(sockEvent).." ?>");
	end
end

-- <passage_insert>
function OnNotifyPassageInserted(key, params)

	-- for k,v in pairs(params) do
		-- Alert("clé = "..k..", v = "..v);
	-- end
	local seq = tonumber(params.seq) or 0;
	local hour = tonumber(params.time) or 0;
	local bib = tonumber(params.bib) or 0;
	local passage = tonumber(params.passage) or 3;
	--                123456789012345678901234567890123456
	-- TN = New time :TN_NNNN_SSSS_CC_HH:MM:SS.FFFFF_DDDDD<E>
	local packetTN = 'TN ';

	-- Dossard
	if bib > 0 then
		packetTN = packetTN..string.format("%04d ", bib);
	else
		packetTN = packetTN..'0000 ';
	end 
	
	-- Id
	device.seqID = device.seqID or {};
	device.seqID[passage] = device.seqID[passage] or 0;
	local numID = device.seqID[passage] + 1;
	packetTN = packetTN..string.format("%04d ", numID);
	device.seqID[passage] = numID;
	
	-- Canal
	if passage >= 0 then
		packetTN = packetTN..string.format('%02d ', passage+1); -- Depart , Inter1, Inter2, Inter3 ...
	else 
		packetTN = packetTN..string.format('04 '); -- Arrivée
	end

	if hour >= 0 then
		-- HH:SS:SS.MMM00
		packetTN = packetTN..app.TimeToString(hour, "%2h:%2m:%2s.%3f"..'00 ');
		
		-- DDDDD : Days (0 - 32767) counting from 01.01.2000 
		packetTN = packetTN..'06570';
	else
		-- Gestion Abd Dsq... 
		packetTN = packetTN..'00:00:00.00000 '..string.format('%#05d',hour);
	end
	
	-- CR, LF
	packetTN = packetTN..string.char(13, 10);
	
	-- Envoi à tous les clients du Packet TN
	if myServer ~= nil then
		myServer:WriteString(packetTN);
	end
	
	Warning(packetTN);
end

-- <bib_time>
function OnNotifyBibTime(key, params)
	-- if params ~= nil then
		-- for k,v in pairs(params) do
			-- Alert("clé = "..k..", v = "..v);
		-- end
	-- end

	local idPassage = tonumber(params.passage) or -2;
	local bib = params.bib or '';
	local time_net = tonumber(params.time) or -1;
	local rank = params.total_rank;
	local diff = params.total_diff;

	local packet = '';
	if idPassage == -1 then
		-- Temps Net Finish           
		-- RR = Result : RR_ZZZZ_NNNN____HH:MM:SS.FFFFF<E>
		-- Z = Rank
		-- N = Bib

		packet = 'RR ';

		-- Rank
		packet = packet..string.format("%04d ", rank);
			
		-- Bib
		if tonumber(bib) > 0 then
			packet = packet..string.format("%04d    ", bib);
		else
			packet = packet..'0000    ';
		end 
	
		if time_net >= 0 then
			-- HH:SS:SS.MMM00
			packet = packet..app.TimeToString(time_net, "%2h:%2m:%2s.%3f"..'00 ');
		
			-- DDDDD : Days (0 - 32767) counting from 01.01.2000 
			packet = packet..'06570';
		else
			-- Gestion Abd , Abs ... 
			packet = packet..'00:00:00.00000 '..string.format('%#05d',time_net);
		end
	elseif idPassage > 0 then
		-- Temps Net Inter1
		-- IR = Intermediate Result : IR_I____NNNN____HH:MM:SS.FFFFF<E>
		
		packet = 'IR ';

		-- idPassage
		packet = packet..string.format("%1d    ", idPassage);

		-- Bib
		if tonumber(bib) > 0 then
			packet = packet..string.format("%04d    ", bib);
		else
			packet = packet..'0000    ';
		end 

		if time_net >= 0 then
			-- HH:SS:SS.MMM00
			packet = packet..app.TimeToString(time_net, "%2h:%2m:%2s.%3f"..'00 ');
		
			-- DDDDD : Days (0 - 32767) counting from 01.01.2000 
			packet = packet..'06570';
		else
			-- Gestion Abd , Abs ... 
			packet = packet..'00:00:00.00000 '..string.format('%#05d',time_net);
		end
	end
	
	-- CR, LF
	packet = packet..string.char(13, 10);
	
	-- Envoi à tous les clients du Packet RR
	if myServer ~= nil then
		myServer:WriteString(packet);
	end
	
	Warning(packet);
end
