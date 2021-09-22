-- Microgate RACE-TIME
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.7, 
		code = 'Race-Time', 
		name = 'MICROGATE Race-time', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '1200,2400,4800,9600' }} 
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

--si on fait un tranfert de donnée la dernière trame fait 32 au lieu de 30 les autres

--CR = 13;	-- Cariage Return

-- Trame du race Time ...
-- dos 20 arrivé 19h33'09"929  dep = 000  lap1 001  arr = 255
-- Tp type temps  0M heure de depart  1M ou 2M
		--est ZM sequence de controle(double bip), 0M h base temps , 1M temps net manche active ds le chrono, 2M temps net total
			--si M impulse viens du chrono si R impulse viens du systeme a onde
-- sequ doss man dep dep CH_ hhmmssmmm
-- 0004 0020 001 255 255 0M_ 193309929(CR)
-- 1234 5678 901 234 567 890 123456789 compteur
-- 000400200012552550M 193309929(CR)
-- [03]O002600520010000000M 192629883    1ere trame apres transfert
-- 1234567890123456789012345678901234

-- si dep dep == 000 000 heure de depart
-- si dep dep == 255 255 heure de arrivee
-- si dep dep == 001 001 heure de lap1

-- [02]R2       F  ->trame envoyer si on ne met pas de numero de manche il fo alors ne pas prendre le transfert en compte le chrono envoi tt les manche

-- [03]n[02]R2       F  -> trame trier par manche ok pour le transfert

--trame de transfert heure de depart
--[02]R2       F[13]
--000000010010000000M 220102741
--000000020012552550M 220107134
--[03]B ou T ou 00 mais pas de CR

function ReadPacket(cb)
	local iFind = cb:Find(asciiCode.CR);-- Recherche CR = caractère fin de Trame
	
	if iFind == -1 then 
		iFind = cb:Find(asciiCode.ETX);
		if iFind == -1 then 
		return false
		end
	end 	-- On peut stopper la recherche

	-- Prise du packet 
	local packet = cb:ReadByte(iFind);
	if IsPacketOk(packet) == true then
		adv.DebugPacket(packet,"*");
	else
		adv.DebugPacket(packet,"Error Packet : ");
	end
	return true;
end

function IsPacketOk(packet)
	assert(packet ~= nil);
	
	local lg = #packet;
	--alert("lg"..lg)
	local Tramecomplete = adv.PacketString(packet, lg-29, lg);
	if lg == 12 then
		alert("1ere trame transfert off line");
		return true;
	elseif lg == 14 then
		alert("1ere trame transfert off line");
		return true;
	elseif lg == 32 then
		alert("1ere trame transfert on line apres un tranfert");
		return true;
	elseif lg == 16 then 
		--alert("Trame Tps tournant"..Tramecomplete);
		return true;
	elseif lg == 15 then 
		alert("Tps net Sans bib ne peut pas etre mise ds la base");
		return true;
	elseif lg == 1 then 
		alert("Trame fin de transfert off line");
		return true;		
	elseif lg < 30 then
		alert("lg="..lg);
		return false;
	end
	
	--Channel est ZM sequence de controle(double bip), 0M heure base temps ou temps net Manche1, 1M temps net manche2, 2M temps net total
	--Channel si M viens du chrono si R viens du systeme a onde
	
	local manche = Tramecomplete:sub(9,11)
	local channel = Tramecomplete:sub(18, 19);
	local origin = GetOrigin(channel);
	local chrono = GetTime(Tramecomplete);
	local bib = GetBib(Tramecomplete);
	local c2 = Tramecomplete:sub(15, 17);
	local passage = -1;
	
-- Atribution du numero de passage suivant le channel ds la trame pour les heures de passage ou le deversement des temps net
	if c2 == "000" then
		-- Canal de Départ : si C0M => on devrait faire un peu plus ...
		passage = 0;
	elseif c2 == "255" then
		-- Canal Arrivée : si C1M => on devrait faire un peu plus ...
		passage = -1;
	elseif c2 == "001" then
		-- Canal 2 => Inter 1
		passage = 1;
	elseif c2 == "002" then
	-- Canal 4 => Inter 2
		passage = 2;
	elseif c2 == "003" then
		-- Canal 5 => Inter 3
		passage = 3;
	elseif c2 == "004" then
		-- Canal 6 => Inter 4
		passage = 4 ;
	elseif c2 == "005" then
		-- Canal 7 => Inter 5
		passage = 5 ;
	elseif c2 == "006" then
		passage = 6 ;
	elseif c2 == "007" then
		passage = 7 ;	
	elseif c2 == "008" then
		passage = 8 ;	
	elseif c2 == "009" then
		passage = 9 ;	
	elseif c2 == "010" then
		passage = 10 ;	
	elseif c2 == "011" then
		passage = 11 ;	
	elseif c2 == "012" then
		passage = 12 ;	
	elseif c2 == "013" then
		passage = 13 ;	
	elseif c2 == "014" then
		passage = 14 ;
	else
		alert("Error channel="..channel);
		return false;
	end 
	
	--Info("C2 ="..c2..'Lg='..lg..'ch'..Ttps);
	if channel == '0M' or channel == '0R' then
		--alert("Trame ok");
		AddTimePassage(chrono, passage, bib, channel, origin)
		return true;
	elseif channel == 'ZM' or channel == 'ZR' then 
		alert("impulsion de controle synchro="..channel);
		return true;
	elseif channel == '1M' then
		alert("Trame Manche ok "..passage.."/");
		AddTimeNet(chrono, bib, passage);
		return true;	
	elseif channel == '2M' then
			--alert("Trame Manche non corcordante avec la manche en court");
			alert("Trame de temps Total");
	elseif channel == '3M' then
			alert("Diff entre I1 et Tps total"..chrono);	
	else
		alert("Type Trame non prise en compte = "..channel);
		return false;		
	end
	
	return true;
end

function GetTime(trame)
	local hour = trame:sub(21, 22);
	local minute = trame:sub(23, 24);
	local sec = trame:sub(25, 26);
	local milli = trame:sub(27, 29);

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

function GetBib(trame)
	local bib = trame:sub(5,8);
	bib = string.gsub(bib, ' ', '0'); 
	return tonumber(bib);
end

function GetOrigin(channel)
		if channel == "0M" then
			return "LN";
		elseif channel == "0R" then
			return "RD";
		end
	return "??";
end

function AddTimePassage(chrono, passage, bib, channel, origin)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'Microgate Race Time_'..origin }
	);
end

function AddTimeNet(chrono, bib, passage)
	app.SendNotify("<net_time_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'Microgate Race-Time' }
	);
end