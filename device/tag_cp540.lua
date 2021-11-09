-- TAG CP-540
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 3.6, 
		code = 'tag_cp540', 
		name = 'TAG Heuer CP-540/545', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '9600,2400,19200,38400,57600' },
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
		adv.DebugPacket(packet,"*");
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
	-- TN : New time
	if packet[1] == string.byte('T') and packet[2] == string.byte('N') then
		return PacketTN(packet);
	-- T* : heure manuelle en mode split
	elseif packet[1] == string.byte('T') and packet[2] == string.byte('*') then
		return PacketTN(packet);
	-- T+ : heure manuelle en mode start stop
	elseif packet[1] == string.byte('T') and packet[2] == string.byte('+') then
		return PacketTN(packet);
	-- RR : Result (Finish – Start or Lap) tps net
	elseif packet[1] == string.byte('R') and packet[2] == string.byte('R') then
		return PacketRR(packet);
	-- IR : Intermediate Result tps net
	elseif packet[1] == string.byte('I') and packet[2] == string.byte('R') then
		return PacketIR(packet);
	-- ID : Serial number
	elseif packet[1] == string.byte('I') and packet[2] == string.byte('D') then
	    alert("Start download ...")
		return true;
	-- DS : Start of download
	elseif packet[1] == string.byte('D') and packet[2] == string.byte('S') then
		alert("Mode Chrono ...");
		return true;
	-- AN  trame d'heure start lap stop en mode chrono et non base temps
	elseif packet[1] == string.byte('A') and packet[2] == string.byte('N') then
		return PacketTN(packet); --fonction a activer pour avoir le deversement des trames en base de temps
	-- DE : End of download
	elseif packet[1] == string.byte('D') and packet[2] == string.byte('E') then
		alert("End download ...");
		return true;
	-- DE : End of download
	elseif packet[1] == string.byte('C') and packet[2] == string.byte('L') then
		alert("Fermeture Manche ...");
		return true;
	-- DE : ouverture chrono
	elseif packet[1] == string.byte('O') and packet[2] == string.byte('M') then
		alert("End download ...");	
		return true; 
	-- DE : ouverture chrono
	elseif packet[1] == string.byte('O') and packet[2] == string.byte('P') then
		alert("Mode Chrono ...");	
		return true; 	
	-- -- Temps Tournant
	elseif packet[1] == asciiCode.CR then
		return true;
	else
		return false;
	end
end

function FindHT(packet)
	for i=1,#packet do
		if packet[i] == asciiCode.HT then
			return i;
		end
	end
	return -1;
end

--                         1         2         3 
--                123456789012345678901234567890
-- TN = New Time :TN_NNNN_idid_CC_HH:MM:SS.FFFFF_DDDDD<E>
--                T+    1    1  1 11:11:11.11100  6994[ 9]0649[13][10]
--				  TN    2    2 M1 19:30:58.41200  6994[ 9]06B3[13][10]
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

	local bib = string.sub(data, 4, 7) or 0 ;
	local id = string.sub(data, 9, 12)or 0;
	local channel = string.sub(data, 14,15)or 0;
	local OrigineTrame = string.sub(data, 14,14)or 0;
	local chrono = GetTime(packet, data);
	
	channel = channel:Trim();  -- a completer
	if OrigineTrame == 'M' then OrigineTrame = 'Manuel' 
		else OrigineTrame = 'ligne:'..channel
	end
	
	if chrono == 0 then
		local bib = string.sub(data, 4, 7);
		local statusTime = tonumber(string.sub(data, 32,38)) or 0;
		if statusTime == chronoStatus.DNF or statusTime == chronoStatus.DNS or statusTime == chronoStatus.DSQ then
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
	elseif channel == 'M4' or channel == '4' or channel == '04' then
		passage = -1;	-- Arrivée
	elseif channel == 'M5' or channel == '5' or channel == '05' then
		passage = 3;	-- Inter 3	
	elseif channel == 'M6' or channel == '6' or channel == '06' then
		passage = 4;	-- Inter 4	
	elseif channel == 'M7' or channel == '7' or channel == '07' then
		passage = 5;	-- Inter 5		
	elseif channel == 'M8' or channel == '8' or channel == '08' then
		passage = 6;	-- Inter 6	
	end

	AddTimePassage(chrono, passage, bib, id, OrigineTrame);
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
--IR 1       2          11.53500	04CB  inter1  dos 2
--IR 2       2        4:56.08800	0506  inter2  dos 2
--RR    2    2        5:54.11400	0504  Arrivee dos 2
--AN    3    3 M1 18:10:43.41100  6994
--IRni   ddddd Ti     M.SS.MMMMM	04D6     			explication decoupe trame
--12_4_6789012_45_78901234567890__345678   				compteur trame  _ espace (donnée vide)
--DE 01	010A

--TI type impulsion M1 M2... manuel 1 2   si 1... 2... 3  impultion ligne1 ... ligne2....
--ni numero de tps inter si la trame commence par IR			   
				   
function PacketRR(packet, data)

	local data = '';
	local checksum16 = '';

	local iFind = FindHT(packet);
	if iFind > 0 then
		data = adv.BytesToString(packet,1, iFind);
		checksum16 = adv.BytesToString(packet,iFind+1, #packet-2);
	else
		data = adv.BytesToString(packet,1, #packet-2);
	end

	--alert("I1ere trame transfert off line  :"..data);
	if string.len(data) < 28 then
		return false;
	end

	local bib = string.sub(data, 9, 12);
	local hour = string.sub(data, 17,18);
	local minute = string.sub(data, 20,21);
	local sec = string.sub(data, 23,24);
	local milli = string.sub(data, 26,28);
	
	local hour = string.gsub(hour, ' ', '0');
	local minute = string.gsub(minute, ' ', '0');
	local sec = string.gsub(sec, ' ', '0');
	local milli = string.gsub(milli, ' ', '0');
	
	hour = tonumber(hour) or 0;
	minute = tonumber(minute) or 0;
	sec = tonumber(sec) or 0;
	milli = tonumber(milli) or 0;
	
	local chrono = 3600000*hour+60000*minute+1000*sec+milli;

	if chrono == 0 then
		local statusTime = tonumber(string.sub(data, 32,38)) or 0;
		if statusTime == chronoStatus.DNF or statusTime == chronoStatus.DNS or statusTime == chronoStatus.DSQ then
			chrono = statusTime;
		end
	end

	local passage = -1;
	
	AddTimeNet(chrono, passage, bib);
	return true;
end

function PacketIR(packet)

	local data = '';
	local checksum16 = '';

	local iFind = FindHT(packet);
	if iFind > 0 then
		data = adv.BytesToString(packet,1, iFind);
		checksum16 = adv.BytesToString(packet,iFind+1, #packet-2);
	else
		data = adv.BytesToString(packet,1, #packet-2);
	end

	--alert("I1ere trame transfert off line  :"..data);
	if string.len(data) < 28 then
		return false;
	end
	
	local passage = string.sub(data, 4,4);
	passage = tonumber(passage) or 1;
	local bib = string.sub(data, 9, 12);
	local hour = string.sub(data, 17,18);
	local minute = string.sub(data, 20,21);
	local sec = string.sub(data, 23,24);
	local milli = string.sub(data, 26,28);
	
	local hour = string.gsub(hour, ' ', '0');
	local minute = string.gsub(minute, ' ', '0');
	local sec = string.gsub(sec, ' ', '0');
	local milli = string.gsub(milli, ' ', '0');
	
	hour = tonumber(hour) or 0;
	minute = tonumber(minute) or 0;
	sec = tonumber(sec) or 0;
	milli = tonumber(milli) or 0;
	
	local chrono = 3600000*hour+60000*minute+1000*sec+milli;

	AddTimeNet(chrono, passage, bib);
	return true;
end

function GetTime(packet, data)
	local hour = string.sub(data, 17,18);
	local minute = string.sub(data, 20,21);
	local sec = string.sub(data, 23,24);
	local milli = string.sub(data, 26,28);

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


function AddTimePassage(chrono, passage, bib, idLog, OrigineTrame)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib:TrimAll(), device = 'tag_cp540/545_'..OrigineTrame, log = idLog }
	);
end

function AddTimeNet(chrono, passage, bib)
	app.SendNotify("<net_time_add>", 
		{ time = chrono,  passage = passage, bib = bib:TrimAll(), device = 'tag_cp540/545' }
	);
end
