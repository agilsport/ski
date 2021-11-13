dofile('./interface/interface.lua');

-- Metatable device
mt_device = {
	-- Standard Device Init
	OnInit = function (params)
		local parentFrame = wnd.GetParentFrame();
		if type(params.type) == "string" then
			mt_device.type = params.type;
			if params.type == "serial" then
				-- Ouverture Port COM
				mt_device.obj = serial.Open(parentFrame, params.port, params.baudrate, params.bytesize, params.parity, params.stopbits, params.handshake);
				parentFrame:Bind(eventType.SERIAL, device.OnSerial, mt_device.obj);
			elseif params.type == "tcp" then
				if type(params.server) ~= "nil" and params.server == "1" then
					-- Ouverture Socket Server
					mt_device.obj = socketServer.Open(parentFrame, params.hostname, params.port);
					parentFrame:Bind(eventType.SOCKET, device.OnSocketServer, mt_device.obj);
					app.GetAuiMessage():AddLine("Socket Server ok ...");
				else
					-- Ouverture Socket Client
					mt_device.obj = socketClient.Open(parentFrame, params.hostname, params.port);
					parentFrame:Bind(eventType.SOCKET, mt_device.OnSocketClient, mt_device.obj);
					app.GetAuiMessage():AddLine('Socket Client '..params.hostname..':'..params.port..' Initialisation ...');
				end
			elseif params.type == "tcp_async" then
					-- Socket Tcp async
					mt_device.obj = {};
					mt_device.obj.type = 'tcp_async';
					mt_device.obj.port = params.port;
					mt_device.obj.hostname = params.hostname;
					app.GetAuiMessage():AddLine('Socket Client Async '..params.hostname..':'..params.port..' ...');
			elseif params.type == "udp" then
					-- Ouverture datagram Socket 
					mt_device.obj = datagramSocket.Open(params.hostname, params.port);
					app.GetAuiMessage():AddLine('UDP Client '..params.hostname..':'..params.port..' Initialisation ...');
			elseif params.type == "usb" then
				-- Ouverture USB
				mt_device.obj = circularBuffer.Open(); 
			end
		end
	end,

	-- Standard Device Close
	OnClose = function ()
		if type(mt_device.type) == "string" and type(mt_device.obj) == "userdata" then 
			-- Fermeture Port COM - Socket ...
			local parentFrame = wnd.GetParentFrame();
			local obj = mt_device.obj;
			if app.GetNameSpace(obj) == 'socketClient' then
				parentFrame:Unbind(eventType.SOCKET, obj:GetId());
			elseif app.GetNameSpace(obj) == 'serial' then
				parentFrame:Unbind(eventType.SERIAL, obj:GetId());
			end
			obj:Close();
			mt_device.obj = nil;
		end
	end,
	
	-- Standard Serial Event
	OnSerial = function (evt)
		if evt:GetInt() == serialNotify.RXCHAR then
			if mt_device ~= nil and mt_device.obj ~= nil then
				mt_device.obj:ReadToCircularBuffer();
				device.OnRead(mt_device.obj:GetCircularBuffer());
				mt_device.obj:ReStartEvent();
			end
		elseif evt:GetInt() == serialNotify.CONNECTION then
			app.GetAuiMessage():AddLineSuccess(evt:GetString());
		else
			app.GetAuiMessage():AddLineError(evt:GetString());
		end
	end,

	-- Standard Socket Client Event
	OnSocketClient = function (evt)
		local sockEvent = evt:GetSocketEvent();
		if mt_device ~= nil and mt_device.obj ~= nil then
			if sockEvent == socketNotify.CONNECTION then
				-- CONNECTION
				adv.Success('Connexion '..mt_device.obj:GetHostName()..':'.. mt_device.obj:GetPort()..' Ok ...');
			elseif sockEvent == socketNotify.LOST then
				-- LOST
				adv.Warning('Connexion Perdue '..mt_device.obj:GetHostName()..':'.. mt_device.obj:GetPort()..' !');
			else
				-- INPUT
				mt_device.obj:ReadToCircularBuffer();
				local cb = mt_device.obj:GetCircularBuffer();
				device.OnRead(cb);
			end
		end
	end,

	-- Standard Socket Server Event
	OnSocketServer = function (evt)
		mt_device.obj:ReadAndBroadcast();
	end,
	
	-- Standard Circular Buffer Read Event
	OnRead = function (cb)
		if type(cb) == "userdata" then
			local count = cb:GetCount();
			local tBytes = cb:ReadByte();
			app.GetAuiMessage():AddLine("OnRead lg="..tostring(count).."/"..tostring(#tBytes)..'=>'..adv.BytesToString(tBytes));
		end
	end,
	
	-- Standard Notify Event
	OnNotify = function(key, tKeyValue)
		if type(tKeyValue) == "table" then
			for key, value in pairs(msg) do
				app.GetAuiMessage():AddLine(key..'='..value);
			end
		end
	end,
	
	-- Metamethod indexing access table[key]
	__index = function(t, k)
		if k == "OnInit" then return mt_device.OnInit
		elseif k == "OnClose" then return mt_device.OnClose
		elseif k == "OnRead" then return mt_device.OnRead
		elseif k == "OnSerial" then return mt_device.OnSerial
		elseif k == "OnSocketServer" then return mt_device.OnSocketServer
		else return nil;
		end
	end
};
	
-- Table Device 
setmetatable(device, mt_device);
