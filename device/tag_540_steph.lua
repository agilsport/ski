-- TAG CP-540
dofile('./interface/include.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.1, 
		code = 'tag_cp540', 
		name = 'TAG Heuer CP-540', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '9600,2400,38400,57600' },
					  { type='tcp', port = 7000, hostname = '192.168.1.50' } } 
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
	local iFind = cb:Find(asciiCode.CR, asciiCode.LF);	-- Recherche CR, LF = caracteres fin de Trame
	if iFind == -1 then return false end 	-- On peut stopper la recherche

	-- Prise du packet 
	local packet = cb:ReadByte(iFind+1);

	if IsPacketOk(packet) == true then
		--adv.DebugPacket(packet,"*1");
		alert("test packet");
	else
		adv.DebugPacket(packet,"Error Packet : ");
	end
	return true;
end

function IsPacketOk(packet)
	local lg = #packet;
	if lg < 2 then
		alert("Invalid Packet Length");
		return false;
	end
	
	-- TN 
	if packet[1] == string.byte('T') and packet[2] == string.byte('N') then
		return PacketTN(packet);
	-- RR
	elseif packet[1] == string.byte('R') and packet[2] == string.byte('R') then
		return PacketRR(packet);
	elseif packet[1] == string.byte('I') and packet[2] == string.byte('D') then
		alert("OUVERTURE CHRONO");
		--return true;	
	elseif packet[1] == string.byte('D') and packet[2] == string.byte('S') then
		alert("OUVERTURE TRANSFERT11111");
		--return true;
		
	else
		return false;
	end
end

function FindHT(packet)
	for i=1,#packet do
		if packet[i] == HT then
			return i;
		end
	end
	return -1;
end

--                         1         2         3 
--                123456789012345678901234567890
-- TN = New Time :TN_NNNN_SSSS_CC_HH:MM:SS.FFFFF_DDDDD<E>
function PacketTN(packet)
	local data = '';
	local checksum16 = '';

	local iFind = FindHT(packet);
	if iFind > 0 then
		data = adv.BytesToString(packet,1, iFind);
		checksum16 = adv.BytesToString(packet,iFind+1, #packet-2);
	else
		data = adv.BytesToString(packet,1, #packet-2);
	end
	
	if string.len(data) < 28 then
		return false;
	end

	local bib = string.sub(data, 4, 7);
	local id = string.sub(data, 9, 12);
	local channel = string.sub(data, 14,15);
	local OrigineTrame = string.sub(data, 14,14);
	
	local hour = string.sub(data, 17,18);
	local minute = string.sub(data, 20,21);
	local sec = string.sub(data, 23,24);
	local milli = string.sub(data, 26,28);
	local chrono = 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
	
	channel = channel:Trim();
	if OrigineTrame == 'M' then OrigineTrame = 'Manuel' 
		else OrigineTrame = channel
	end
	
	if chrono == 0 then
		local bib = string.sub(data, 4, 7);
		local statusTime = tonumber(string.sub(data, 32,38)) or 0;
		if statusTime == chrono.DNF or statusTime == chrono.DNS then
			chrono = statusTime;
		end
	end
	
	local passage = -1;	-- Arrivée
	if channel == 'M1' or channel == '1' or channel == '01' then
		passage = 0;	-- Depart
	elseif channel == 'M2' or channel == '2' or channel == '02' then
		passage = 1;	-- Inter 1
	elseif channel == 'M3' or channel == '3' or channel == '03' then
		passage = 2;	-- Inter 2
	elseif channel == 'M5' or channel == '3' or channel == '03' then
		passage = 3;	-- Inter 2	
	elseif channel == 'M6' or channel == '3' or channel == '03' then
		passage = 4;	-- Inter 2	
	elseif channel == 'M7' or channel == '3' or channel == '03' then
		passage = 5;	-- Inter 2	
	elseif channel == 'M8' or channel == '3' or channel == '03' then
		passage = 6;	-- Inter 2		
	end

	AddTimePassage(chrono, passage, bib, id, OrigineTrame);
	adv.DebugPacket(packet,"*");
	return true;
end	
	
--                            1         2         3 
--                   123456789012345678901234567890
-- RR = Result Time :RR_ZZZZ_NNNN____HH:MM:SS.FFFFF<E>
				   --RR    2   14           1.99300
				   --RR    0    2           0.70400	04BF
				   
				   -- trame envoyer en deversement tps net
	--ID 01904	01AB
--DS 01  00 START - FINISH     	0634
--AN    1    1 M1 20:37:44.13600  6899	069F
--AN    1    1 M4 20:37:46.61300  6899	06A4
--RR    0    1           2.47700	04C7
--AN    2    2 M1 20:37:50.45100  6899	069E
--AN    2    2 M4 20:37:51.15500  6899	06A3
--RR    0    2           0.70400	04BF
--DE 01	010A			   
				   
				   
function PacketRR(packet)

	local data = '';
	local checksum16 = '';

	local iFind = FindHT(packet);
	if iFind > 0 then
		data = adv.BytesToString(packet,1, iFind);
		checksum16 = adv.BytesToString(packet,iFind+1, #packet-2);
	else
		data = adv.BytesToString(packet,1, #packet-2);
	end

	alert("I1ere trame transfert off line  :"..data);
	if string.len(data) < 28 then
		return false;
	end

	local bib = string.sub(data, 9, 12);
	local hour = string.sub(data, 17,18);
	local minute = string.sub(data, 20,21);
	local sec = string.sub(data, 23,24);
	local milli = string.sub(data, 26,28);
	
	hour = string.gsub(hour, ' ', '0');
	minute = string.gsub(minute, ' ', '0');
	sec = string.gsub(sec, ' ', '0');
	milli = string.gsub(milli, ' ', '0');
	
	
	local chrono = 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);

	AddTimeNet(chrono, bib);
	adv.DebugPacket(packet,"*");
	
	return true;
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

function AddTimePassage(chrono, passage, bib, idLog, OrigineTrame)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'tag_cp540_'..OrigineTrame, log = idLog }
	);
end

function AddTimeNet(chrono, bib)
	app.SendNotify("<net_time_add>", 
		{ time = chrono,  passage = -1, bib = bib, device = 'tag_cp540' }
	);
end
