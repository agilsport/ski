-- TAG CP-505
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return 	{ 
		version = 2.0, 
		code = 'tag_cp505', 
		name = 'TAG Heuer CP-505', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '1200' } } 
	};
end	

-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	-- Test si le Buffer est vide 
	if cb:GetCount() == 0 or cb:GetCount() == 2	then return end
	-- Lecture des Packets 
	while (ReadPacket(cb)) do end
end

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

--[[ Trame du CP505...
	 DOSEHHMMSSMMM
[255]0041100611748[013]		trame depart  lg 15
[255]0022100228734[013]		trame arrivée lg 15
	 1234567890123
	 
	 HHMMSSMMM
[245]000010460[013]			temps net  lg11
     12345678901
R  43  0046       37:50.620000      ; Exemple de Trame 'R'
--]]

function ReadPacket(cb)
	--local iFind = cb:Find('[255][000]');	-- Recherche CR = caractere fin de Trame
	--local iFind = cb:Find(asciiCode.NULL);
	--local iFind = cb:Find(asciiCode.LF);
	--local iFind = cb:Find(asciiCode.CR, asciiCode.LF);
	local iFind = cb:Find(asciiCode.CR); -- caractere ok
	
	if iFind == -1 then return false end 	-- On peut stopper la recherche

	-- Prise du packet 
	local packet = cb:ReadByte(iFind);

	if IsPacketOk(packet) == true then
		adv.DebugPacket(packet,"*");
	else
		adv.DebugPacket(packet,"1er packet : ");
	end
	return true;
end

function IsPacketOk(packet)

	local TypeTrame = packet[1];
	if TypeTrame == 0 then TypeTrame = -1 
	elseif TypeTrame == 0 and packet[2] == -11 then TypeTrame = -11
	end

	local lg = #packet;
	if lg <= 8 then
		return false;
	end
	--Lecture de la trame complete a partir du caractere de fin (ifind) 
	local Tramecomplete = adv.PacketString(packet, lg-13, lg);
	--alert("Tramecomplete"..Tramecomplete..'lg = '..lg);
	
	local chrono = GetTime(Tramecomplete);
	local bib = GetBib(Tramecomplete);
	local channel = GetChannel(Tramecomplete);
	-- alert("channel"..channel);
	
	-- T = 'T'emps de passage
	if TypeTrame == -1 then
		if channel == '1' then 
			-- Canal 1 => Départ
			AddTimePassage(chrono, 0, bib, channel);
			return true;
		elseif channel == '2' then
			-- Canal 2 => Arrivée
			AddTimePassage(chrono, -1, bib, channel);
			return true;
		else
			alert("Error channel="..channel);
		end	
	elseif TypeTrame == -11 then
	-- R = 'R'un : Temps de Manche
		passage = -1;
		local Tramecomplete = adv.PacketString(packet, lg-9, lg);
		local chrono = GetTimeNet(Tramecomplete);
		local bib = GetBib(Tramecomplete);
		
		--AddTimeNet(chrono, passage);
		alert("TypeTrameOffLine"..TypeTrame..'Tramecomplete = '..Tramecomplete);
		return true;
	else 
		alert("Error TypeTrame"..TypeTrame..'lg = '..lg);
		return false;
	end
	return false;
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
	local hour = Tramecomplete:sub(1, 2);
	local minute = Tramecomplete:sub(3, 4);
	local sec = Tramecomplete:sub(5, 6);
	local milli = Tramecomplete:sub(7, 9);

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
	local bib = Tramecomplete:sub(1,3);
	bib = string.gsub(bib, ' ', '0'); 
	return tonumber(bib);
end

function GetChannel(Tramecomplete)
	--local channel = adv.PacketString(packet,5,5);
	local channel = Tramecomplete:sub(4, 4);
	--channel = channel:adv.Trim();
	return channel;
end

function AddTimePassage(chrono, passage, bib, channel)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'TAG-CP-505' }
	);
end

function AddTimeNet(chrono, passage)
	app.SendNotify("<net_time_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'TAG-CP-505' }
	);
end
