-- Microgate REI2
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.5, 
		code = 'microgate_rei2', 
		name = 'MICROGATE Rei2 / RTPRO', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '9600,1200,2400,4800,19200,28800,38400,57600' } } 
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
	else
		adv.DebugPacket(packet,"Error Packet : ");
	end
	
	return true;	
end

-- Trame du rei2 ...
			 --trame hd hors base temps
--  DR  SO000127123450000011000000203724321602102016
--			--trame hA hors base temps
--  DR  SO000128123450000011152550203740540902102016
		
--				trame temps net  hors base temps
--*** GestionTrame *** Seq : 40662531 : InfoTrame(dossard, manche, typeTps, Tps)= 12345 , 1, A, 16200 
--*** SetTrameExe *** Seq : 40662531 Trame = R  SO0001291234500000111525510000162000+0000000  
--Traitee = 0 

--  decoupe trame pc on line c'est soit DR ou R en debut de trame
--	ROO000119000000000011000000203333853902102016 			trame de lecture HD ou HA
	--   OO 000119 00000 00000 11 00 0000 2033338539 02102016	trame decouper HD ou HA
--  1234 56 789012 34567 89012 34 56 7890 1234567890 12345678    compteur
	--	 SO 000024 00001 00000 11 15 2552 0000056000 +0000000    trame temps net
	--	 SO 000082 00006 00000 11 01 0011 0000079000 +0000000    trame temps net inter 1 	 
	-- 	 SO 000092 00007 00000 11 16 0021 0000292000 +0000000    trame temps net inter 2
	--	 SO 000093 00007 00000 11 16 0022 0000292000 +0000000   envoie de la trame en double pour tout les inters
	--	 Tt|ID seq| dos |     |OT|Ch|    |hhmmssmmmm|jjmmaaaa
	--
	--		origine trame:	11 impuls manu 			channel : 	01  L1
	--						10 impuls ligne						02	L2
	--						15 impuls radio						16	L2
	--															00 start
	--															15 stop
	--      Type trame: OO online
	--					SO temps net

function IsPacketOk(packet)
	local lg = #packet;

	if lg < 46 then
		alert("Invalid Packet Length");
		return false;
	end
	local OriginTrame = adv.PacketString(packet, 23, 24);
	local Date = adv.PacketString(packet, 41, 48);
	local typeTrame = adv.PacketString(packet, 5, 6);
	local channel = adv.PacketString(packet, 25, 26);
	local id = tonumber(adv.PacketString(packet, 7, 12));
	local chrono = GetTime(packet);
	local bib = GetBib(packet);
	
	--Renvoi l'origine de la trame radio manue ou ligne
		if OriginTrame == "11" then
			-- origine trame bouton mauelle du chrono ...
			OrigineTrame = 'impuls-Man.';
		elseif OriginTrame == "10" then
			-- origine trame entrée ligne du chrono ...
			OrigineTrame = 'impuls-Ligne.';
		elseif OriginTrame == "15" then
			-- origine trame de encradio ...
			OrigineTrame = 'impuls-Rad.';
		else 
			-- origine trame Non determiner ...
			OrigineTrame = '';
		end
	
	
	
	-- Renvoi du passage suivant le N° de Channel
		if channel == "00" then
			-- Canal de Départ : si C0M => on devrait faire un peu plus ...
			passage = 0;
		elseif channel == "15" then
			-- Canal Arrivée : si C1M => on devrait faire un peu plus ...
			passage = -1;
		elseif channel == "01" then
		-- Canal 3 => Inter 1
			passage = 1;
		elseif channel == "16" then
			-- Canal 3 => Inter 1
			passage = 2;
		elseif channel == "02" then
			-- Canal 4 => Inter 2
			passage = 2;
		elseif channel == "03" then
			-- Canal 5 => Inter 3
			passage = 3;
		elseif channel == "04" then
			-- Canal 6 => Inter 4
			passage = 4;
		elseif channel == "05" then
			-- Canal 7 => Inter 5
			passage = 5;
		elseif channel == "06" then
			-- Canal 8 => Inter 6
			passage = 6;
		elseif channel == "07" then
			-- Canal 4 => Inter 2
			passage = 7;
		elseif channel == "08" then
			-- Canal 5 => Inter 3
			passage = 8;
		elseif channel == "09" then
			-- Canal 6 => Inter 4
			passage = 9;
		elseif channel == "10" then
			-- Canal 7 => Inter 5
			passage = 10;
		elseif channel == "11" then
			-- Canal 8 => Inter 6
			passage = 11;	
		elseif channel == "12" then
			-- Canal 5 => Inter 3
			passage = 12;
		elseif channel == "13" then
			-- Canal 6 => Inter 4
			passage = 13;
		elseif channel == "14" then
			-- Canal 7 => Inter 5
			passage = 14;	
		else
			alert("Error channel="..channel);
		end

	if typeTrame == 'OO' then -- Base de Temps
		alert("chrono= "..chrono)
		AddTimePassage(chrono, passage, bib, channel, id);
		return true;	
	elseif typeTrame == 'SO' and Date == '+0000000' then -- Temps Net
		AddTimeNet(chrono, passage, bib);
		return true;
	elseif typeTrame == 'SO' and Date ~= '+0000000' then -- heure de depart arrivée	
		return true;
	else
		alert("Type Trame non prise en compte = "..typeTrame..'//');
		return true;
	end 
	return false
end

function GetTime(packet)
	local hour = adv.PacketString(packet, 31, 32);
	local minute = adv.PacketString(packet, 33, 34);
	local sec = adv.PacketString(packet, 35, 36);
	local milli = adv.PacketString(packet, 37, 39);

	hour = string.gsub(hour, ' ', '0');
	minute = string.gsub(minute, ' ', '0');
	sec = string.gsub(sec, ' ', '0');
	milli = string.gsub(milli, ' ', '0');
		
	return 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
end

function GetBib(packet)
	local bib = adv.PacketString(packet,13, 17);
	bib = string.gsub(bib, ' ', '0'); 
	return tonumber(bib);
end

function AddTimePassage(chrono, passage, bib, channel, id)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'microgate_rei2_'..OrigineTrame, log = id }
	);
end

function AddTimeNet(chrono, passage, bib)
app.SendNotify("<net_time_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'Microgate REi2'..OrigineTrame }
	);

end
--[[
--*********************
function device.OnClose()

-- fonction permetant le fonctionnement de l'activation ou de la desactivation des devices ds la fenetre chrono
	local mgr = app.GetAuiManager();
	mgr:DeletePane(RaceresultWebServeur.panel.container);

-- Appel OnClose Metatable
	mt_device.OnClose();

end ]]--
