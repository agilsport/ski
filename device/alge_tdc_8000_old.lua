-- ALGE TDC 8000
dofile('./interface/include.lua');
dofile('./interface/device.lua');
dofile('./interface/adv.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.0, 
		code = 'ALGE TDC 8000', 
		name = 'ALGE TDC 8000', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '9600, 2400, 4800, 19200', handshake = 'RTS/CTS' } }
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
			alert("Trame 8000="..packet);
	if IsPacketOk(packet) == false then
		adv.DebugPacket(packet,"Error Packet:");
	end
	return true;
end


--[[  TRAME RECU TDC 8000 TERMITE
CLASSEMENT:
                                
ALL
                                
RUN TIME
                                
n0002
 0002 RTM 00:00:04.83   00 0001
 0006 RTM 00:00:05.99   00 0002
 0003 RTM 00:00:10.55   00 0003
 0008 RTM 00:00:10.89   00 0004
 0007 RTM 00:00:12.23   00 0005
 0005 RTM 00:00:13.76   00 0006
 0004 RTM 00:00:14.19   00 0007
 0001 RTM 00:02:25.4900 00 0008
 123456789012345678901234567890  lg=30
 
 DOSS TTR HH:mm.ss.00   xx Cltg
 
 TTR  -> TYPE TRAME
 Cltg -> classement
 xx  -> manche  a verif
 
  ALGE TIMING
   TdC  8000
  FRA V 98.83
18-11-19  19:00
                                
                                
 0010 C0M 19:19:49.6800 00
n0003
n0004
n0005
n0006
n0007
n0008
n0009
 0009 C1M 19:20:27.1000 00
 0009 RTM 00:20:53.09   00
n0010
 0010 C1M 19:20:40.8400 00
 0010 RTM 00:00:51.16   00
 1234567890123456789012345  lg = 25
n0011
]]--


function IsPacketOk(packet)
	local lg = #packet;
	if lg < 25 then
		alert("Invalid Packet Length lg="..lg);
		return false;
	end
	
	if lg == 30 then 
		local Tramecomplete = adv.PacketString(packet, lg-30, lg);
		local TypeChrono = 'BaseTemps';
		assert(#Tramecomplete == 30);
		return TypeChrono;
	elseif lg == 25 then
		local Tramecomplete = adv.PacketString(packet, lg-25, lg);
		local TypeChrono = 'OffLine';
		assert(#Tramecomplete == 25);
		return TypeChrono;
	end
	
	local manche = Tramecomplete:sub(24,25)-- a voir????
	
	local TypeTrame = Tramecomplete:sub(6,8)--ok
	local origin = Tramecomplete:sub(9, 9)--ok
	local chrono = GetTime(Tramecomplete); -- ok
	local bib = GetBib(Tramecomplete);  --ok
	local passage = -1;
		
	if TypeTrame == 'CO' and TypeChrono == 'BaseTemps' then
			-- Canal Départ :
			passage = 0;
			AddTimePassage(chrono, passage, bib, TypeTrame, origin );
			
	elseif TypeTrame == 'C1' and TypeChrono == 'BaseTemps' then
			-- Canal Arrivée : si C1M => on devrait faire un peu plus ...
			passage = -1;
			AddTimePassage(chrono, passage, bib, TypeTrame, origin );
			
	elseif TypeTrame == 'TR' and TypeChrono == 'OffLine' then
			-- Ajout du temps net
			AddTimeNet(chrono, bib);
			
	else
			alert("Error TypeTrame="..TypeTrame);
			return false;
	end 

		adv.DebugPacket(packet, '*');
		return true;
		
		
		end


function GetTime(Tramecomplete)
	local hour = Tramecomplete:sub(10, 11);
	local minute = Tramecomplete:sub(13, 14);
	local sec = Tramecomplete:sub(16, 17);
	local milli1 = Tramecomplete:sub(19, 22);
	

	hour = string.gsub(hour, ' ', '0');
	minute = string.gsub(minute, ' ', '0');
	sec = string.gsub(sec, ' ', '0');
	milli1 = string.gsub(milli1, ' ', '0');
	local lgMilli = #milli1;
	
	if lgMilli == '1' then milli = milli1..'000'
	elseif lgMilli == '2' then milli = milli1..'00'
	elseif lgMilli == '3' then milli = milli1..'0'
	else milli = milli1
	end
	
	return 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
end

function GetBib(Tramecomplete)
	local bib = Tramecomplete:sub(packet,1,4);
	bib = string.gsub(bib, ' ', '0'); 
	return tonumber(bib);
end

function AddTimePassage(chrono, passage, bib, TypeTrame)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'alge_TDC-8000_'..origin }
	);
end


function AddTimeNet(chrono, bib)
	app.SendNotify("<net_time_add>", 
		{ time = chrono,  passage = -1, bib = bib, device = 'alge_TDC-8000_' }
	);
end
