-- TAG CP-520
dofile('./interface/adv.lua');
dofile('./interface/device.lua');
-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.6, 
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

--trame envoi temps net off line par run
				--	 S 001          LAP TIME[013]	
	--Packet Error : L         1 M2        5.380000[013]
--compteur			 123456789012345678901234567893
--					 T      0046 M2 11:24:37.333000

function ReadPacket(cb)
	local iFind = cb:Find(asciiCode.CR);	-- Recherche CR = caractere fin de Trame
	if iFind == -1 then return false end 	-- On peut stopper la recherche

	-- Prise du packet 
	local packet = cb:ReadByte(iFind);

	
	if IsPacketOk(packet) == true then
			adv.DebugPacket(packet,"*");
			
	elseif IsPacketOk(packet) == 'TypeTrame' then
			alert("Envoi trame Tps net RUN"..packet[1]);
	else
		adv.DebugPacket(packet,'Packet Error : ');
	end
	return false;
end

function IsPacketOk(packet)
	local lg = #packet;
	if lg < 21 then
		alert("Invalid Packet Length");
		return false;
	end


	if packet[1] == string.byte('T') then
	-- T = 'T'emps de passage
		if packet[14] == string.byte('1') then
			-- Canal 1 => Départ
			passage = 0;
		elseif packet[14] == string.byte('2') then
			-- Canal 2 => Arrivée
			passage = -1;
		end
	PacketTT(packet)
	return true
	elseif packet[1] == string.byte('R') then
		-- R = 'R'un : Temps de Manche
		PacketTN(packet)
	return true
	elseif packet[1] == string.byte('L') then
		-- L = 'L'un : Temps de Manche
		PacketTN(packet)
		
	elseif packet[1] == string.byte('S') then
	alert ('type trame')
			TypeTrame = 'TypeTrame';
		return TypeTrame;		
	else
		return false;
	end
end


--lecture trame temps net
function PacketTN(packet)
	local chrono = GetTime(packet);
	local bib = GetBib(packet);
	local channel = GetChannel(packet);
	
	AddTimeNet(chrono, bib);
	adv.DebugPacket(packet,"*");
end 

--lecture trame temps passage
function PacketTT(packet)
	local chrono = GetTime(packet);
	local bib = GetBib(packet);
	local channel = GetChannel(packet);
		AddTimePassage(chrono, passage, bib, channel)
		--adv.DebugPacket(packet,"*");

end 

--lecture trame temps passage
function PacketS(packet)
	

end 


function GetTime(packet)
	local hour = adv.PacketString(packet, 16, 17);
	local minute = adv.PacketString(packet, 19, 20);
	local sec = adv.PacketString(packet, 22, 23);
	local milli = adv.PacketString(packet, 25, 27);
	hour = string.gsub(hour, ' ', '0');
	minute = string.gsub(minute, ' ', '0');
	sec = string.gsub(sec, ' ', '0');
	milli = string.gsub(milli, ' ', '0');
	
	return 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
	
end

function GetBib(packet)
	local bib = adv.PacketString(packet,8,11);
	bib = string.gsub(bib, ' ', '0'); 
	return tonumber(bib);
end

function GetChannel(packet)
local channel1 = adv.PacketString(packet,13, 13);
	if channel1 == 'M' then 
		local channel = adv.PacketString(packet,14,14);
		channel = 'manuel-'..channel:Trim();
		return channel;
	else	
		local channel = adv.PacketString(packet,14,14);
		channel = 'ligne-'..channel:Trim();
		return channel;
	end

end

function AddTimePassage(chrono, passage, bib, channel)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'tag_cp520 /'..channel }
	);
end

function AddTimeNet(chrono, bib)
	app.SendNotify("<net_time_add>", 
		{ time = chrono,  passage = -1, bib = bib, device = 'tag_cp520' }
	);

end

