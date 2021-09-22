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
	port = tonumber(params.port) or 7000;
	address = tostring(params.hostname) or app.GetCurrentIPAddress();
	timer_milliseconds = tonumber(params.timer_milliseconds) or 5000;
	
	OnTimerOpen();
	
	local mainFrame = app.GetAuiFrame();
	timerOpen = timer.Create(mainFrame);
	timerOpen:Start(timer_milliseconds);
	mainFrame:Bind(eventType.TIMER, OnTimerOpen, timerOpen);

	stackNotification = {};
	
	timerQueue = timer.Create(mainFrame);
	timerQueue:Start(500);
	mainFrame:Bind(eventType.TIMER, OnTimerQueue, timerQueue);
	
	-- Queue ... 
	queueNotificationID = wnd.NewControlId();
	mainFrame:Bind(eventType.MENU, OnQueueNotification, queueNotificationID);

	-- A l'écoute de toutes les notifications ...
	app.BindNotify("<*>", OnNotify);
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
		device.LoadExclude('client_notification.lua');
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

function ReadPacket(cb)
	local iFind = cb:Find(asciiCode.NUL);	-- Recherche Fin de Trame (Code ASCII 0)
	if iFind == -1 then return false end 	-- On peut stopper la recherche
	
	-- Prise du packet 
	local packet = cb:ReadByte(iFind);
	
	local lg = #packet;
	assert(packet[lg] == asciiCode.NUL);
	
	local params = jsonParams.decode(adv.PacketString(packet,1,lg-1));
	if params ~= nil and type(params) == 'table' then
		table.insert(stackNotification , params);
	end
	
	return true;
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