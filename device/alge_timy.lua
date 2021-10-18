-- ALGE Timy
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.3, 
		code = 'alge_timy', 
		name = 'ALGE Timy', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '9600,2400,4800,19200,38400'}, { type='usb', dll='alge_usb.dll' }	}
	};
end	

timyDLL = nil;

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

-- Ouverture
function device.OnInit(params)
	-- Appel OnInit Metatable
	mt_device.OnInit(params);

	if params.type == 'usb' then
		timyDLL = app.UsbTimyStart();
	end
end

-- Fermeture
function device.OnClose()
	if timyDLL ~= nil then
		timyDLL:UsbTimyEnd();
	end
	
	-- Appel OnClose Metatable
	mt_device.OnClose();
end

-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	-- Test si le Buffer est vide 
	if cb:GetCount() == 0 then	return end

	-- Lecture des Packets 
	while (ReadPacket(cb)) do end
end

-- Data USB 
function OnUsb(params)
	if mt_device.obj ~= nil and type(mt_device.obj) == "userdata" and params.data ~= nil then  
		local cb = mt_device.obj;
		cb:WriteString(params.data);
		ReadPacket(cb);
	end
end

-- Trame du Timy ...
-- yNNNNxCCCxHH:MM:SS.zhtq(CR) / yNNNNxCCCx01:00:00.zhtq
-- 12345678901234567890123
function ReadPacket(cb)
	local iFind = cb:Find(asciiCode.CR);	-- Recherche CR = caractère fin de Trame
	if iFind == -1 then return false end 	-- On peut stopper la recherche

	-- Prise du packet 
	local packet = cb:ReadByte(iFind);

	if IsPacketOk(packet) == false then
		adv.DebugPacket(packet,"Error Packet:");
	end
	
	return true;	
end

function IsPacketOk(packet)
	local lg = #packet;

	if lg == 13 then
		-- Temps Tournant HH:MM:SS.D
		adv.DebugPacket(packet);
		return true;	
	end

	if lg < 23 then
		-- On Ignore ...
		adv.DebugPacket(packet);
		return true;
	end

	local channel = GetChannel(packet)
	local chrono = GetTime(packet);
	local bib = GetBib(packet);
	
	local c2 = string.upper(string.sub(channel,1,2));
	if c2 == "C0" then
		-- Canal de Départ : si C0M => on devrait faire un peu plus ...
		AddTimePassage(chrono, 0, bib, channel);
	elseif c2 == "C1" then
		-- Canal Arrivée : si C1M => on devrait faire un peu plus ...
		AddTimePassage(chrono, -1, bib, channel);
	elseif c2 == "C2" then
		-- Canal 2 => Inter 1
		AddTimePassage(chrono, 1, bib, channel);
	elseif c2 == "C3" then
		-- Canal 3 => Inter 2
		AddTimePassage(chrono, 2, bib, channel);
	elseif c2 == "C4" then
		-- Canal 4 => Inter 2
		AddTimePassage(chrono, 3, bib, channel);
	elseif c2 == "C5" then
		-- Canal 5 => Inter 3
		AddTimePassage(chrono, 4, bib, channel);
	elseif c2 == "C6" then
		-- Canal 6 => Inter 4
		AddTimePassage(chrono, 5, bib, channel);
	elseif c2 == "C7" then
		-- Canal 7 => Inter 5
		AddTimePassage(chrono, 6, bib, channel);
	elseif c2 == "C8" then
		-- Canal 8 => Inter 6
		AddTimePassage(chrono, 7, bib, channel);
	elseif c2 == "RT" then
		-- Temps de Course
		AddTimeNet(chrono, -1, bib);
	elseif c2 == "TT" then
		-- Temps Total
		AddTimeNet(chrono, -1, bib);
	end
	
	adv.DebugPacket(packet, '*');
	return true;
end

function GetChannel(packet)
	local channel = adv.PacketString(packet, 7, 9);
	return channel;
end

function GetTime(packet)
	local hour = adv.PacketString(packet, 11, 12);
	local minute = adv.PacketString(packet, 14, 15);
	local sec = adv.PacketString(packet, 17, 18);
	local milli = adv.PacketString(packet, 20, 22);

	hour = string.gsub(hour, ' ', '0');
	minute = string.gsub(minute, ' ', '0');
	sec = string.gsub(sec, ' ', '0');
	milli = string.gsub(milli, ' ', '0');
	
	return 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
end

function GetBib(packet)
	local bib = adv.PacketString(packet,2,5);
	bib = string.gsub(bib, ' ', '0'); 
	return tonumber(bib);
end

function AddTimePassage(chrono, passage, bib, channel)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'alge_timy_'..channel }
	);
end

function AddTimeNet(chrono, passage, bib)
	app.SendNotify("<net_time_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'alge_timy' }
	);
end
