-- AGIL PDA : Interface Vidage du PDA vers le logiciel de Course 
dofile('./interface/include.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 1.7, 
		code = 'agil_pda', 
		name = 'Agil PDA-Chrono', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '19200' } } 
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

function ReadPacket(cb)
	local iFind = cb:Find(asciiCode.CR);	-- Recherche CR = caractère fin de Trame
	if iFind == -1 then return false end 	-- On peut stopper la recherche

	-- Prise du packet 
	local packet = cb:ReadByte(iFind);

	if IsPacketOk(packet) == false then
		adv.DebugPacket(packet,"Error Packet:");
	else
		adv.DebugPacket(packet,"*");
	end
	
	return true;	
end

function IsPacketOk(packet)
	local lg = #packet;
	
	local strPacket = '';
	for i=1,#packet do
		local ascii = packet[i] or 0;
		if ascii > 0 and ascii < 128 then
			strPacket = strPacket..string.char(ascii);
		end
	end
	
	local arrayPacket = strPacket:Split('|');
	if #arrayPacket == 1 then
		return true;
	elseif #arrayPacket == 3 then
		local bib = arrayPacket[2] or '';
		local millisec = tonumber(arrayPacket[3]) or 0;
		
		if arrayPacket[1] == 'TN' then
			AddTimeNet(millisec, -1, bib);
			return true;
		elseif arrayPacket[1] == '0' then
			AddTimePassage(millisec, 0, bib);
			return true;
		elseif  arrayPacket[1] == '-1' then
			AddTimePassage(millisec, -1, bib);
			return true;
		end
	end
	return false;
end

function AddTimePassage(millisec, passage, bib)
	app.SendNotify("<passage_add>", 
		{ time = millisec,  passage = passage, bib = bib, device = 'agil_pda' }
	);
end

function AddTimeNet(millisec, passage, bib)
	if millisec == 4294966696 then
		-- DNS, ABS
		millisec = chrono.DNS;
		AddTimePassage(chrono.DNS, 0, bib);
	elseif millisec == 4294966796 then
		-- DNF, ABD
		millisec = chrono.DNF;
		AddTimePassage(chrono.DNF, -1, bib);
	end

	app.SendNotify("<net_time_add>", 
		{ time = millisec,  passage = passage, bib = bib, device = 'agil_pda' }
	);
end
