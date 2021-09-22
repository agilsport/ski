-- TAG CP-520
dofile('./interface/include.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.0, 
		code = 'tag_cp520', 
		name = 'TAG Heuer CP-520', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '9600' }} 
	};
end	

-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	-- Test si le Buffer est vide 
	if cb:GetCount() == 0 then	return end

	-- Lecture des Packets 
	while (ReadPacket(cb)) do end
end

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

--[[ Trame du CP520...
X = Type de Trame T=Temps de Passage , R = Run (Temps Manche)
       dddd = dossard
               HH:MM:SS.MMM = Heure de Passage ou Temps Net
             C = Canal : 1 = Départ, 2 = Arrivée			   
T      0046 M2 11:24:37.333000      : Exemple de Trame 'T'
R  43  0046       37:50.620000      ; Exemple de Trame 'R'
--]]

function ReadPacket(cb)
	local iFind = cb:Find(asciiCode.CR);	-- Recherche CR = caractere fin de Trame
	if iFind == -1 then return false end 	-- On peut stopper la recherche

	-- Prise du packet 
	local packet = cb:ReadByte(iFind);

	if IsPacketOk(packet) == false then
		alert('Packet Error : '..adv.BytesToString2(packet));
	end
	return true;
end

function IsPacketOk(packet)
	local lg = #packet;
	if lg < 27 then
		alert("Invalid Packet Length");
		return false;
	end

	local chrono = GetTime(packet);
	local bib = GetBib(packet);
	local channel = GetChannel(packet);

	if packet[1] == string.byte('T') then
		-- T = 'T'emps de passage
		if packet[14] == string.byte('1') then
			-- Canal 1 => Départ
			AddTimePassage(chrono, 0, bib, channel);
			return true;
		end

		if packet[14] == string.byte('2') then
			-- Canal 2 => Arrivée
			AddTimePassage(chrono, -1, bib, channel);
			return true
		end
	end
	
	if packet[1] == string.byte('R') then
		-- R = 'R'un : Temps de Manche
		AddTimeNet(chrono, bib);
		return true;
	end

	return false;
end

function GetTime(packet)
	local hour = adv.PacketString(packet, 16, 17);
	local minute = adv.PacketString(packet, 19, 20);
	local sec = adv.PacketString(packet, 22, 23);
	local milli = adv.PacketString(packet, 25, 27);

	hour = string.gsub(hour, ' ', '0') or 0;
	minute = string.gsub(minute, ' ', '0') or 0;
	sec = string.gsub(sec, ' ', '0') or 0;
	milli = string.gsub(milli, ' ', '0') or 0;
	
	return 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
end

function GetBib(packet)
	local bib = adv.PacketString(packet,8,11);
	bib = string.gsub(bib, ' ', '0'); 
	return tonumber(bib);
end

function GetChannel(packet)
	local channel = adv.PacketString(packet,13,14);
	channel = channel:Trim();
	return channel;
end

function AddTimePassage(chrono, passage, bib, channel)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'tag_cp520_'..channel }
	);
end

function AddTimeNet(chrono, bib)
end

