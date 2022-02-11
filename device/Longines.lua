-- Longines-TL5005
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 1.6, 
		code = 'Longines-TL5005', 
		name = 'Longines-TL5005', 
		class = 'chrono', 
		interface = {{type='serial', bytesize = '7,8' , baudrate = '9600' }}
	};
end
	
function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end	
	
-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	-- Test si le Buffer est vide 
	if cb:GetCount() == 0 then	return end

	-- Lecture des Packets 
	while (ReadPacket(cb)) do end
end

function ReadPacket(cb)

	local iFind = cb:Find(asciiCode.LF);				-- Recherche LF = caractere fin de Trame
	if iFind == -1 then return false end 	-- On peut stopper la recherche

	-- Prise du packet 
	local packet = cb:ReadByte(iFind);

	if IsPacketOk(packet) == true then
		adv.DebugPacket(packet,"*");
	-- else
		-- adv.DebugPacket(packet,"Error Packet : ");
	end
	
	return true;	
end

-- Trame longines-TL5005

-- F finish
		 -- DDDHHMMSSMMMMSEQ
-- 10: [02]F 45151316242031  h ar
--		   1234567890123456
-- G  TPS NET
		-- DDD  MMSS000
-- [02]G    45   34610003N1
--	   1234567890123456
-- [02]G    45   34610053T1

-- 03:30: [02]F 46151636868011  H DEP
--			  1234567890123456
-- 031  PASSAGE-1
-- 011  PASSAGE 0

-- 00: 14: [02]F  2152526199021   INTER 1
--			   1234567890123456

function IsPacketOk(packet)
	local lg = #packet;
	alert("lg ="..lg);
--lg = 20 si temps net
	if lg < 5 then
		alert("Invalid Packet Length");
		return false;
	end
	
	--if lg 23
	
	
	local Tramecomplete = adv.PacketString(packet, lg-23, lg);
	alert("packet= "..Tramecomplete);

	local TypeTrame = Tramecomplete:sub(1, 1);
	local channel = Tramecomplete:sub(15, 15);
	local manche = Tramecomplete:sub(16, 16);
	alert("TypeTrame = "..TypeTrame)
	if TypeTrame == "F" then
		local chrono = GetTime(Tramecomplete);
		local bib = GetBib(Tramecomplete);
		-- Renvoi du passage suivant le N° de Channel
		if channel == "3" then
			-- Canal de Départ : si C0M => on devrait faire un peu plus ...
			passage = -1;
			AddTimePassage(chrono, passage, bib, channel, id);
		elseif channel == "1" then
			-- Canal Arrivée : si C1M => on devrait faire un peu plus ...
			passage = 0;
			AddTimePassage(chrono, passage, bib, channel, id);
		elseif channel == "2" then
		-- Canal 3 => Inter 1
			passage = 1;
			AddTimePassage(chrono, passage, bib, channel, id);
		else
			alert("Error channel="..channel);
		end
	elseif TypeTrame == "G" then
		-- Temps net
		local chrono = GetTimeNet(Tramecomplete);
		local bib = GetBibNet(Tramecomplete);
		passage = -1;
		--alert('dos:'..bib..' tps:'..chrono);
		AddTimeNet(chrono, passage, bib);
	elseif TypeTrame == "N" then
		-- Temps net
		local chrono = GetTimeNet(Tramecomplete);
		local bib = GetBibNet(Tramecomplete);
		passage = -1;
		AddTimeNet(chrono, passage, bib);
	elseif TypeTrame == "A" then
		-- Abandon
		local chrono = -500;
		local bib = GetBib(Tramecomplete);
		--alert('Abd dos:'..bib);
		passage = -1;
		AddTimeNet(chrono, passage, bib);
	end
	return false
end

function GetTime(Tramecomplete)
	local hour = Tramecomplete:sub(5, 6);
	local minute = Tramecomplete:sub(7, 8);
	local sec = Tramecomplete:sub(9, 10);
	local milli = Tramecomplete:sub(11, 13);

	local hour = string.gsub(hour, ' ', '0');
	local minute = string.gsub(minute, ' ', '0');
	local sec = string.gsub(sec, ' ', '0');
	local milli = string.gsub(milli, ' ', '0');
	
	hour = tonumber(hour) or 0;
	minute = tonumber(minute) or 0;
	sec = tonumber(sec) or 0;
	milli = tonumber(milli) or 0;
	
	return 3600000*hour+60000*minute+1000*sec+milli;
end

function GetTimeNet(Tramecomplete)
	-- local hour = Tramecomplete:sub(1, 2);
	-- local minute = Tramecomplete:sub(3, 4);
	-- local sec = Tramecomplete:sub(5, 6);
	-- local milli = Tramecomplete:sub(7, 9);
	local hour = Tramecomplete:sub(8, 9);
	local minute = Tramecomplete:sub(10, 11);
	local sec = Tramecomplete:sub(12, 13);
	local milli = Tramecomplete:sub(14, 16);

	local hour = string.gsub(hour, ' ', '0');
	local minute = string.gsub(minute, ' ', '0');
	local sec = string.gsub(sec, ' ', '0');
	local milli = string.gsub(milli, ' ', '0');
	
	hour = tonumber(hour) or 0;
	minute = tonumber(minute) or 0;
	sec = tonumber(sec) or 0;
	milli = tonumber(milli) or 0;
	
	return 3600000*hour+60000*minute+1000*sec+milli;
end

function GetBib(Tramecomplete)
	local bib = Tramecomplete:sub(2, 4);
	bib = string.gsub(bib, ' ', '0'); 
	return tonumber(bib);
end
function GetBibNet(Tramecomplete)
	local bib = Tramecomplete:sub(5, 7);
	bib = string.gsub(bib, ' ', '0'); 
	return tonumber(bib);
end

function AddTimePassage(chrono, passage, bib, channel, id)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'Longines_TL5005', log = id }
	);
end

function AddTimeNet(chrono, passage, bib)
	app.SendNotify("<net_time_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'Longines_TL5005' }
	);

end
