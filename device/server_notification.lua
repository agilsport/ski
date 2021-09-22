-- Serveur de Notification
dofile('./interface/include.lua');
dofile('./interface/device.lua');

json = loadfile("./interface/json.lua")();
dofile('./interface/jsonParams.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return {
				version = 1.2, 
				name = 'Serveur de Notification', 
				class = 'network', 
				root = 0,  
				interface = { { type='tcp', port=10000 } } 
	};
end	

-- Ouverture
function device.OnInit(params)

	-- Ouverture du Server de Socket ...
	local mainFrame = app.GetAuiFrame();
	local port = tonumber(params.port) or 7000;
	local address = tostring(params.hostname) or app.GetCurrentIPAddress();
	serverNotify = socketServer.Open(mainFrame, address, port);
	
	mainFrame:Bind(eventType.SOCKET, OnSocket, serverNotify:GetId());
	adv.Warning("Serveur de Notification Initialisation "..address..':'..port);
	
	-- A l'écoute de toutes les notifications ...
	app.BindNotify("<*>", OnNotify);
end

-- Fermeture
function device.OnClose()
	if serverNotify ~= nil then
		serverNotify:Close();
	end
end

function OnSocket(evt)
	local sockEvent = evt:GetSocketEvent();
	
	if sockEvent == socketNotify.CONNECTION then
		-- CONNECTION
		local sockNew = serverNotify:Accept();
		if sockNew ~= nil then
			if serverNotify:AddClient(sockNew) then
				local tPeer = sockNew:GetPeer();
				adv.Success("Serveur de Notification : Client "..tPeer.ip..':'..tPeer.port);
				return
			end
		end
	elseif sockEvent == socketNotify.LOST then
		-- LOST
		adv.Warning('Serveur de Notification : LOST');
	elseif sockEvent == socketNotify.INPUT then
		-- INPUT
		serverNotify:ReadToCircularBuffer(evt:GetSocket());
		local cb = serverNotify:GetCircularBuffer(evt:GetSocket());
		-- Lecture des Packets 
		while (ReadPacket(cb, evt:GetSocket())) do end
	elseif sockEvent == socketNotify.OUTPUT then
		adv.Warning("Serveur de Notification: Event OUTPUT");
	else
		-- ???
		adv.Error("Serveur de Notification: Unknown Event : "..tostring(sockEvent));
	end
end

function ReadPacket(cb, sockClient)
	local iFind = cb:Find(asciiCode.NUL);	-- Recherche Fin de Trame (Code ASCII 0)
	if iFind == -1 then return false end 	-- On peut stopper la recherche
	
	-- Prise du packet 
	local packet = cb:ReadByte(iFind);
	
	local lg = #packet;
	assert(packet[lg] == asciiCode.NUL);
	local params = jsonParams.decode(adv.PacketString(packet,1,lg-1));
	
	-- for k,v in pairs(params) do
		-- adv.Alert(k..'='..tostring(v));
	-- end
	
	params.internal = true;
    sockClient:SetNotify(socketEventFlags.LOST);

	sockClient:SetFlags(socketFlags.WAITALL);
	local rc, out = app.SendNotify(params.key, params);
	if rc == true then
		local jsonString = jsonParams.encode(out, out.key);

		local jsonSize = string.format('%06d', jsonString:len());
		adv.Alert('Writing ..'..jsonSize);
		sockClient:WriteString(jsonSize);
		
		local count = sockClient:WriteString(jsonString);
		sockClient:WriteByte(0);
		adv.Success("Write Count="..tostring(count));
	else
		adv.Error("SendNotify key"..params.key..' return false');
	end

	sockClient:SetFlags(socketFlags.NOWAIT);
	sockClient:SetNotify(socketEventFlags.LOST+socketEventFlags.INPUT);
	return true;
end

function OnNotify(key, params)
	params.internal = params.internal or false;
	
	if serverNotify ~= nil and serverNotify:IsOk() and params.internal == false then 
		adv.Warning('OnNotify '..key);
		serverNotify:WriteString(jsonParams.encode(params, key));
		serverNotify:WriteByte(asciiCode.NUL);
	end
end
