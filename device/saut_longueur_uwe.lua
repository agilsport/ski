--[[ Saut Longueur Uwe Brechenmacher (uwe.brechenmacher@arcor.de)
- Connection parameters are 9600 Bit/s 8N1 with no hardware handshake. 
- You have to use a null-modem cable to connect both computers.

1. The calc computer send the bib
Send string: #STNbbbbCR
 
# : synchronise communication
STN : Command for Bib
bbbb : bib number
CR : Carriage Return (ASCII 13)

2. Measuring distance
After measuring distance and click on "Übernehmen" button the cad-m computer send the string to calc computer:
#DSTwwwwCR
 
# : synchronise communication
DST : command for distance
wwww : distance (without comma or point)
CR : carriage return
--]]

dofile('./interface/interface.lua');
dofile('./interface/device.lua');
dofile('./interface/adv.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 1.3, code = 'SAUTUWE', name = 'Saut Longueur Video Mesure (UWE)', class = 'chrono', 
				interface = { 
					{ type='serial', baudrate = '9600' }
				} 
			};
end	

-- Ouverture
function device.OnInit(params)

	-- Appel OnInit Metatable
	mt_device.OnInit(params);

	-- notification à prendre en compte 
	app.BindNotify("<bib_next>", OnBibNext);
	device.bib = -1;
	
	Alert("Initialisation Ok ...");
end

-- Fermeture
function device.OnClose()
	-- Appel OnClose Metatable
	mt_device.OnClose();
end

-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	-- Lecture des Packets 
	while (device.ReadPacket(cb)) do end
end

function device.ReadPacket(cb)
	local iFind = cb:Find(asciiCode.CR);
	if iFind < 0 then return false end

	local tBytes = cb:ReadByte(iFind);
	local dataString = adv.BytesToString(tBytes,0, iFind);
	Alert("<= Reception "..dataString);
	if string.sub(dataString,1,5) == '##DST' then
		local dist = tonumber(string.sub(dataString,6));
		app.SendNotify("<bib_distance>", { bib = device.bib,  distance = dist });
		Success("DISTANCE = "..tostring(dist));
	end
	
	return true;
end

function OnBibNext(key, params)

	-- #   :  synchronise communication
	-- STN : Command for Bib
	
	device.bib = tonumber(params.bib)

	local txt = "#STN"..string.format("%-d", device.bib);
	if mt_device.obj ~= nil then
		mt_device.obj:WriteString(txt);
		mt_device.obj:WriteByte(asciiCode.CR);
	end

	Alert('=> Event '..key..' bib = '..params.bib..', Send = '..txt);
	return true;
end

function Alert(msg)
	app.GetAuiMessage():AddLine(msg);
end

function Success(msg)
	app.GetAuiMessage():AddLineSuccess(msg);
end

function Warning(msg)
	app.GetAuiMessage():AddLineWarning(msg);
end

function Error(msg)
	app.GetAuiMessage():AddLineError(msg);
end
