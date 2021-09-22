-- Radiocoms Datasprint
dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

datasprint = { sat = 0, bat = 0, offsetGMT = nil };

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 3.1, 
		code = 'rad_datasprint', 
		name = 'Radiocoms Datasprint', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '2400' }	} 
	};
end	

-- Ouverture
function device.OnInit(params)

	-- Table Ack Passage
	lastPassageOk = {};
	
	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	-- Able System 
	-- Sleep Mode 900 seconds = 15 minutes = 132 + 256*3 
	-- ESC  X   11 132  3
	-- 1BH,58H,0BH,84H,03H sets a period of 15 minutes [(132+ 256*3) = 900 seconds
--	SendPacket({ ESC, string.byte('X'), 0x0b, 0x84, 0x03 }); -- 900 secondes 
--	SendPacket({ ESC, string.byte('X'), 0x0b, 0xff, 0xff });
	
	-- Creation Panel 
	local panel = wnd.CreatePanel({ parent = app.GetAuiFrame() });
	panel:LoadTemplateXML({ 
		xml = './device/radiocoms_datasprint.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'dashboard'
	});

	datasprint.panel = panel;
	
	bannerSat1 = panel:GetObjectName('sat1');
	bannerSat2 = panel:GetObjectName('sat2');
	bannerSat3 = panel:GetObjectName('sat3');
	bannerSat4 = panel:GetObjectName('sat4');
	bannerSat5 = panel:GetObjectName('sat5');
	bannerSat6 = panel:GetObjectName('sat6');
	bannerSat7 = panel:GetObjectName('sat7');
	bannerSat8 = panel:GetObjectName('sat8');

	bannerBatD = panel:GetObjectName('batd');
	bannerBatP = panel:GetObjectName('batp');
	bannerBatA = panel:GetObjectName('bata');

	DrawSat();

	local mgr = app.GetAuiManager();
	mgr:AddPane(panel, {
		caption = "Tableau de Bord Datasprint",
		caption_visible = true,
		close_button = false,
		pin_button = true,
		show = true,

		float = true, 
		floating_position = {800, 40},
		floating_size = {400, 80},
		dockable = false
		
	});
	
	panel:Bind(eventType.CONTEXT_MENU, OnContextMenu, -1);

	mgr:Update();
	
	-- Passage en mode PC
	SendPacket({ asciiCode.ESC, string.byte('P'), asciiCode.CR });
	
	-- Demande du nombre de satellites
	SendPacket({ asciiCode.ESC, string.byte('T'), asciiCode.CR });
end

-- Fermeture
function device.OnClose()
	-- Commande de Fermeture 
	SendPacket({ asciiCode.ESC, string.byte('Q'), asciiCode.CR });

	local mgr = app.GetAuiManager();
	mgr:DeletePane(datasprint.panel);

	-- Appel OnClose Metatable
	mt_device.OnClose();
end

-- OnContextMenu
function OnContextMenu(evt)
	local menuContext =  menu.Create();
	local btnSynchro = menuContext:Append({label="Synchro. Horloge", image ="./res/16x16_synchro.png"});
	datasprint.panel:Bind(eventType.MENU, OnSynchroDialog, btnSynchro);
	datasprint.panel:PopupMenu(menuContext);
	menuContext:Delete();
end

-- Fermeture Dialog Synchro 
function OnSynchroClose(evt)

	-- Annulation Mode Synchro => Passage en Mode Chrono 
	SendPacket({ asciiCode.ESC, string.byte('C'), asciiCode.CR });

	dlgSynchro:EndModal();
end

function OnSynchroStart(evt)
	local tb = dlgSynchro:GetWindowName('tb');
	if tb ~= nil then
		tb:EnableTool(tbSynchro:GetId(), false);
	end
	
	local time_synchro = dlgSynchro:GetWindowName('time_synchro');
	if time_synchro ~= nil then
		local t = time_synchro:GetValue();
		
		datasprint.offsetGMT = datasprint.offsetGMT or 0;
		local hour = t.hour - datasprint.offsetGMT;
		
		-- Prise de l'heure de Synchro
		SendPacket({ 
			asciiCode.ESC, 
			string.byte('S'), 
			string.byte(string.format('%2d', hour):sub(1,1)),
			string.byte(string.format('%2d', hour):sub(2,2)),
			string.byte(':'), 
			string.byte(string.format('%2d', t.minute):sub(1,1)),
			string.byte(string.format('%2d', t.minute):sub(2,2)),
			string.byte(':'), 
			string.byte(string.format('%2d', t.second):sub(1,1)),
			string.byte(string.format('%2d', t.second):sub(2,2)),
			asciiCode.CR 
		});
		
		time_synchro:Enable(false);
		
		theSynchroSec = t.hour*3600 + t.minute*60 + t.second;
		adv.Alert('Top Synchro : '..string.format('%2d', t.hour)..':'..string.format('%2d', t.minute)..':'..string.format('%2d', t.second));
	end
end

function OnSynchroDialog(evt)
	dlgSynchro = wnd.CreateDialog({
		parent = datasprint.panel,
		icon = "./res/32x32_chrono.png",
		label = "Synchronisation DATASPRINT",
		width = 300,
		height = 160
	});
	
	dlgSynchro:LoadTemplateXML({ 
		xml = './device/radiocoms_datasprint.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'synchro'
	});

	local clock_gps = dlgSynchro:GetWindowName('clock_gps');
	if clock_gps ~= nil then
		clock_gps:GetObject(0):SetText(app.TimeToString(0,'%zero%2h:%2m:%2s'));
		clock_gps:GetObject(0):Refresh();
	end
	
	local tb = dlgSynchro:GetWindowName('tb');
	tbSynchro = tb:AddTool("Synchro", "./res/32x32_save.png");
	tb:AddStretchableSpace();
	tbClose = tb:AddTool("Fermer", "./res/32x32_close.png");
	tb:Realize();
	
	dlgSynchro:Bind(eventType.MENU, OnSynchroClose, tbClose);
	dlgSynchro:Bind(eventType.MENU, OnSynchroStart, tbSynchro);

	-- Passage en Mode 'H'
	SendPacket({ asciiCode.ESC, string.byte('H'), asciiCode.CR });
	
	dlgSynchro:Fit();
	dlgSynchro:ShowModal();
end

function GetDatasprintOffsetGMT(chrono)
	if datasprint.offsetGMT == nil then
		local now = app.Now();
		local offset = now - chrono + 1800000;
		if offset > 0 then
			offset = math.floor(offset/3600000);
		else
			offset = math.floor(offset/3600000)-1;
		end
		datasprint.offsetGMT = offset;
	end
	return chrono + datasprint.offsetGMT*3600000;
end

-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	-- Test si le Buffer est vide 
	if cb:GetCount() == 0 then	return end

	-- Lecture des Packets 
	while (ReadPacket(cb)) do end
end

 function ReadPacket(cb)

	local iFind = cb:Find(asciiCode.CR);	-- Recherche CR = caractère fin de Trame
	if iFind == -1 then return false end 	-- On peut stopper la recherche

	-- Prise du packet 
	local packet = cb:ReadByte(iFind);
	
	DoPacket(packet);
	return true;	
end

-- Calcul du Checksum 
function GetCheckSum(packet)
	local checkSum = 0;
	if #packet >= 21 then
		for i=2,22 do
			checkSum = checkSum + packet[i];
		end
	end
	
	checkSum = checkSum % 256;
	return checkSum;
end

-- Trame du Data exemple : [ 2]C000102 11:00:07.60601D[13]	
function DoPacket(packet)
	local lg = #packet;
	
	if lg < 2 then return false end;
	if packet[2] <= 0 or packet[2] >= 128 then return false end
	
	local typePacket = string.char(packet[2]);
	local checkSumCompute = GetCheckSum(packet);
	local checkSumPacket = adv.PacketString(packet, 23, 24);
	
	if checkSumCompute ~= tonumber(checkSumPacket,16) then
		-- CheckSum KO !
		SendPacket({asciiCode.NAK}); -- NAK
		adv.DebugPacket(packet,"-error-");
		return false;
	end
	
	-- CheckSum OK 
	SendPacket({asciiCode.ACK}); -- ACK
	adv.DebugPacket(packet,"*");

	if typePacket == 'T' then -- Nombre de Satellites 
		if lg >= 21 then
			datasprint.sat = tonumber(string.char(packet[21]));
			DrawSat();
--			alert("Nombre de Sat = "..datasprint.sat);
--			alert("Battery = "..datasprint.bat);
			datasprint.bat = tonumber(string.char(packet[22]));
			return true;
		else
			return false;
		end
	elseif typePacket == 'C' then -- Heure de Passage
		local channel = GetChannel(packet);
		local chrono = GetTime(packet);

		-- Prise Décalage GMT
		chrono = GetDatasprintOffsetGMT(chrono);
		
		if channel == '01' then -- Départ
			AddTimePassage(chrono, 0);
		elseif channel == '02' then -- Arrivée
			AddTimePassage(chrono, -1);
		elseif channel == '03' then -- Inter 1
			AddTimePassage(chrono, 1);
		elseif channel == '04' then -- Vitesse
			AddTimePassage(chrono, 2);	-- a améliorer ...
		end
		return true;
	elseif typePacket == 'H' then -- Heure de Synchro
		-- Affichage de l'heure tournante pour la Synchro
		local chrono = GetTime(packet);
	
		-- Prise Décalage GMT 
		chrono = GetDatasprintOffsetGMT(chrono);
	
		if dlgSynchro ~= nil then
			local clock_gps = dlgSynchro:GetWindowName('clock_gps');
			if clock_gps ~= nil then
				clock_gps:GetObject(0):SetText(app.TimeToString(chrono,'%zero%2h:%2m:%2s'));
				clock_gps:GetObject(0):Refresh();
			end
		end
	elseif typePacket == 'S' then -- Top Synchro
		-- Fermeture eventuelle de la boite de dialogue de Synchro
		if dlgSynchro ~= nil then
			dlgSynchro:EndModal();
			dlgSynchro = nil;
		end
		
		-- Passage en Mode Chrono 
		SendPacket({ asciiCode.ESC, string.byte('C'), asciiCode.CR });
	end
	
	return false;
end

function GetChannel(packet)
	local channel = adv.PacketString(packet, 7, 8);
	return channel;
end

function GetBattery(packet)
	local battery = adv.PacketString(packet, 22, 1);
	return battery;
end

function GetTime(packet)
	local hour = adv.PacketString(packet, 10, 11);
	local minute = adv.PacketString(packet, 13, 14);
	local sec = adv.PacketString(packet, 16, 17);
	local milli = adv.PacketString(packet, 19, 21);

	hour = string.gsub(hour, ' ', '0');
	minute = string.gsub(minute, ' ', '0');
	sec = string.gsub(sec, ' ', '0');
	milli = string.gsub(milli, ' ', '0');
	
	return 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
end

function SendPacket(packet)
	if mt_device.obj ~= nil then
		if type(packet) == 'string' then
			mt_device.obj:WriteString(packet);	-- Data
		elseif type(packet) == 'table' then
			mt_device.obj:WriteByte(packet);	-- Data
		end
	end
end

function AddTimePassage(chrono, passage)
	if lastPassageOk[passage] ~= chrono then
		lastPassageOk[passage] = chrono;

		app.SendNotify("<passage_add>", 
			{ time = chrono,  passage = passage, device = 'radiocoms_datasprint' }
		);
	end
end

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function DrawSat()
	if bannerSat1 == nil then return end
	
	DrawLedKo(bannerSat1);
	DrawLedKo(bannerSat2);
	DrawLedKo(bannerSat3);
	DrawLedKo(bannerSat4);
	DrawLedKo(bannerSat5);
	DrawLedKo(bannerSat6);
	DrawLedKo(bannerSat7);
	DrawLedKo(bannerSat8);
	
	if datasprint.sat >= 1 then DrawLedOk(bannerSat1); end
	if datasprint.sat >= 2 then DrawLedOk(bannerSat2); end
	if datasprint.sat >= 3 then DrawLedOk(bannerSat3); end
	if datasprint.sat >= 4 then DrawLedOk(bannerSat4); end
	if datasprint.sat >= 5 then DrawLedOk(bannerSat5); end
	if datasprint.sat >= 6 then DrawLedOk(bannerSat6); end
	if datasprint.sat >= 7 then DrawLedOk(bannerSat7); end
	if datasprint.sat >= 8 then DrawLedOk(bannerSat8); end
	
	DrawLedKo(bannerBatD);
	DrawLedKo(bannerBatP);
	DrawLedKo(bannerBatA);
	
	if (datasprint.bat & 0x01) == 0x00 then
		DrawLedOk(bannerBatD);
	end

	if (datasprint.bat & 0x08) == 0x00 then
		DrawLedOk(bannerBatP);
	end
	
	if (datasprint.bat & 0x02) == 0x00 then
		DrawLedOk(bannerBatA);
	end
	
end

function DrawLedOk(bannerSat)
	-- adv.Alert(type(bannerSat)..' app='..app.GetNameSpace(bannerSat));
	bannerSat:SetText('./res/16x16_circle_green.png');
	bannerSat:Refresh();
end

function DrawLedKo(bannerSat)
	bannerSat:SetText('./res/16x16_circle_red.png');
	bannerSat:Refresh();
end
