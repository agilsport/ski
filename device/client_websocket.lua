-- Client de Notification
dofile('./interface/include.lua');
dofile('./interface/device.lua');

json = loadfile("./interface/json.lua")();
dofile('./interface/jsonParams.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return {	version = 1.3, 
				name = 'Client de Notification', 
				class = 'network', 
				interface = { { type='tcp', port=10000 } } 
	};
end	

-- Ouverture
function device.OnInit(params)
	port = tonumber(params.port) or 9000;
	address = tostring(params.hostname) or 'localhost';
	timer_milliseconds = tonumber(params.timer_milliseconds) or 5000;
	
	local mainFrame = app.GetAuiFrame();
	timerOpen = timer.Create(mainFrame);
	timerOpen:Start(timer_milliseconds);
	mainFrame:Bind(eventType.TIMER, OnTimerOpen, timerOpen);

	stackNotification = {};
	
	-- Queue ... 
	queueNotificationID = wnd.NewControlId();
	mainFrame:Bind(eventType.MENU, OnQueueNotification, queueNotificationID);
end

-- Fermeture
function device.OnClose()

	if timerOpen ~= nil then
		-- local mainFrame = app.GetAuiFrame();
		-- mainFrame:Unbind(eventType.TIMER);
		timerOpen:Delete();
	end
	
	if timerQueue ~= nil then
		timerQueue:Delete();
	end
	
	if clientNotify ~= nil then
		clientNotify:Close();
	end
end

function OnTimerOpen()
	if clientNotify == nil or clientNotify:IsOk() == false then
		
		if clientNotify ~= nil then
			clientNotify:Close();
		end

		local mainFrame = app.GetAuiFrame();
		clientNotify = socketClient.Open(mainFrame, address, port);
		mainFrame:Bind(eventType.SOCKET, OnSocket, clientNotify:GetId());
		adv.Warning("Client de Notification Initialisation "..address..':'..port);
	else
		-- if #stackNotification > 0 then
			-- local mainFrame = app.GetAuiFrame();
			-- mainFrame:QueueEvent(eventType.MENU, queueNotificationID);
		-- end
	end
end

function OnSocket(evt)

	local sockEvent = evt:GetSocketEvent();
	if sockEvent == socketNotify.CONNECTION then
		-- CONNECTION
		adv.Success('CONNECTION OK');
		SendWebSocketInit();
		
	elseif sockEvent == socketNotify.LOST then
		-- LOST
		adv.Warning('CONNECTION LOST ...');
		device.Unload();
		clientNotify:Close();
		clientNotify = nil;
	else
		-- INPUT
		clientNotify:ReadToCircularBuffer();
		local cb = clientNotify:GetCircularBuffer();

		-- Test si le Buffer est vide 
		if cb:GetCount() == 0 then return end

		-- Lecture des Packets 
		while (ReadPacket(cb)) do end
		
		-- if #stackNotification > 0 then
			-- local mainFrame = app.GetAuiFrame();
			-- mainFrame:QueueEvent(eventType.MENU, queueNotificationID);
		-- end

	end
end

function SendWebSocketInit()
	local data = 
	'GET /echobot HTTP/1.1'..string.char(13, 10)..
	'Host: 127.0.0.1:9000'..string.char(13, 10)..
	'Connection: Upgrade'..string.char(13, 10)..
	'Pragma: no-cache'..string.char(13, 10)..
	'Cache-Control: no-cache'..string.char(13, 10)..
	'Upgrade: websocket'..string.char(13, 10)..
	'Origin: http://localhost'..string.char(13, 10)..
	'Sec-WebSocket-Version: 13'..string.char(13, 10)..
	'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36'..string.char(13, 10)..
	'Accept-Encoding: gzip, deflate, br'..string.char(13, 10)..
	'Accept-Language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7'..string.char(13, 10)..
	'Sec-WebSocket-Key: G9r+trq9jcWOVTslR0AYJQ=='..string.char(13, 10)..
	'Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits'..string.char(13, 10)
	..string.char(13, 10);
	
	adv.Alert("Data:"..data);
	clientNotify:WriteString(data);
end
		

function ReadPacket(cb)
	local packet = cb:ReadByte();
	adv.DebugPacket(packet,"Packet:");
	return false;
end

function OnNotify(key, input)
	input.internal = input.internal or false;
	local output = nil;
	
	if clientNotify ~= nil and clientNotify:IsOk() and input.internal == false then

--		adv.Alert('OnNotify :'..key..' internal = '..tostring(input.internal));
	
		-- Envoi de la Notification au Server 
		if clientNotify:WaitForWrite(2) == true then
			clientNotify:WriteString(jsonParams.encode(input, key));
			clientNotify:WriteByte(asciiCode.NUL);
		else
			adv.Error('WaitForWrite timeout ...');
			clientNotify:SetFlags(socketFlags.NOWAIT);
			return;
		end
	
		-- Passage en mode WAITALL
-- 	    clientNotify:SetNotify(socketEventFlags.LOST);
		local jsonString = clientNotify:ReadString();
		if jsonString ~= nil then
			output = jsonParams.decode(jsonString); 
--			adv.Warning('OnNotify Ok : key='..key..' : output='..tostring(jsonString));
			adv.Warning('OnNotify Ok : key='..key);
		else
			adv.Error("OnNotify KO");
		end

		-- if clientNotify:WaitForRead(2) == true then
			-- if clientNotify:IsData() and clientNotify:Error() == false then
				-- local jsonString = clientNotify:ReadString();
				
				-- if jsonString ~= nil then
					-- output = jsonParams.decode(jsonString); 
					-- adv.Warning('OnNotify Ok : key='..key..' : output='..tostring(jsonString));
				-- else
					-- adv.Error("OnNotify KO");
				-- end
			-- end
		-- else
			-- adv.Error('WaitForRead timeout ...');
		-- end

--		clientNotify:SetNotify(socketEventFlags.LOST+socketEventFlags.INPUT);
--		clientNotify:SetFlags(socketFlags.NOWAIT);
	end
	return output;
end

function OnQueueNotification(evt)
	clientNotify:SetNotify(socketEventFlags.LOST);
	while #stackNotification > 0 do
		local params = stackNotification[1];
		adv.Alert('OnQueueNotification '..params.key);
		params.internal = true;
		app.SendNotify(params.key, params);
		table.remove(stackNotification, 1);
	end
	clientNotify:SetNotify(socketEventFlags.LOST+socketEventFlags.INPUT);
end

function OnTimerQueue(evt)
	if clientNotify ~= nil then
		clientNotify:SetNotify(socketEventFlags.LOST);
	end
	
	while #stackNotification > 0 do
		local params = stackNotification[1];
		adv.Alert('OnTimerQueue '..params.key);
		params.internal = true;
		app.SendNotify(params.key, params);
		table.remove(stackNotification, 1);
	end

	if clientNotify ~= nil then
		clientNotify:SetNotify(socketEventFlags.LOST+socketEventFlags.INPUT);
	end
end