-- Radiocoms Datasport
dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

datasprint = { sat = 0, bat = 0, offset = nil };

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 1.5, 
		code = 'rad_datasport', 
		name = 'Radiocoms Datasport', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '2400' }	} 
	};
end	

-- Ouverture
function device.OnInit(params)

	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	-- Passage en mode PC
	SendPacket({ asciiCode.ESC, string.byte('P'), asciiCode.CR });

	-- Demande du nombre de satellites
	SendPacket({ asciiCode.ESC, string.byte('T'), asciiCode.CR });
	
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
		caption = "Tableau de Bord Datasport",
		caption_visible = true,
		close_button = false,
		pin_button = true,
		show = true,

		float = true, 
		floating_position = {800, 40},
		floating_size = {400, 80},
		dockable = false
		
	});
	
	panel:Bind(eventType.CONTEXT_MENU, OnContextMenu);

	mgr:Update();
end

-- Fermeture
function device.OnClose()
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
	-- Passage en mode PC
	SendPacket({ asciiCode.ESC, string.byte('P'), asciiCode.CR });

	-- Demande du nombre de satellites
	SendPacket({ asciiCode.ESC, string.byte('T'), asciiCode.CR });

	dlgSynchro:EndModal();
end

function OnSynchroStart(evt)
	-- Passage du datasprint en mode 'S' ...
	local tb = dlgSynchro:GetWindowName('tb');
	if tb ~= nil then
		tb:EnableTool(tbSynchro:GetId(), false);
	end
	
	local time_synchro = dlgSynchro:GetWindowName('time_synchro');
	if time_synchro ~= nil then
		local t = time_synchro:GetValue();
		
		SendPacket({ 
			asciiCode.ESC, 
			string.byte('S'), 
			string.byte(string.format('%2d', t.hour, 1, 1)),
			string.byte(string.format('%2d', t.hour, 2, 2)),
			string.byte(':'), 
			string.byte(string.format('%2d', t.minute, 1, 1)),
			string.byte(string.format('%2d', t.minute, 2, 2)),
			string.byte(':'), 
			string.byte(string.format('%2d', t.second, 1, 1)),
			string.byte(string.format('%2d', t.second, 2, 2)),
			asciiCode.CR 
		});
		
		adv.Alert('Passage Mode Synchro : '..string.format('%2d', t.hour)..':'..string.format('%2d', t.minute)..':'..string.format('%2d', t.second));
	end
end

function OnSynchroDialog(evt)
	dlgSynchro = wnd.CreateDialog({
		parent = datasprint.panel,
		icon = "./res/32x32_chrono.png",
		label = "Synchronisation DATASPORT",
		width = 300,
		height = 160
	});
	
	dlgSynchro:LoadTemplateXML({ 
		xml = './device/radiocoms_datasprint.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'synchro'
	});

	local tb = dlgSynchro:GetWindowName('tb');
	tbSynchro = tb:AddTool("Synchro", "./res/32x32_save.png");
	tb:AddStretchableSpace();
	tbClose = tb:AddTool("Fermer", "./res/32x32_close.png");
	tb:Realize();

	dlgSynchro:Bind(eventType.MENU, OnSynchroClose, tbClose);
	dlgSynchro:Bind(eventType.MENU, OnSynchroStart, tbSynchro);
	
	dlgSynchro:Fit();
	dlgSynchro:ShowModal();
end

-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	-- Test si le Buffer est vide 
	if cb:GetCount() == 0 then	return end

	-- Lecture des Packets 
	while (ReadPacket(cb)) do end
end

-- Trame du Data ...
function ReadPacket(cb)

	local iFind = cb:Find(asciiCode.CR);	-- Recherche CR = caractère fin de Trame
	if iFind == -1 then return false end 	-- On peut stopper la recherche

	-- Prise du packet 
	local packet = cb:ReadByte(iFind);
	
	if IsPacketOk(packet) == false then
		adv.DebugPacket(packet,"Error Packet : ");
	end

	return true;	
end

function IsPacketOk(packet)
	local lg = #packet;
	
	if lg < 2 then return false end;

--	local typePacket = adv.PacketString(packet, 2, 2);
	local typePacket = string.char(packet[2]);
-- local checkSum = GetCheckSum(); -> 22 sur 2 - a finir
	
	if typePacket == 'T' then -- Nombre de Satellites 
		if lg >= 22 then
			datasprint.sat = tonumber(string.char(packet[22]));
			DrawSat();
--			alert("Nombre de Sat = "..datasprint.sat);
--			alert("Battery = "..datasprint.bat);
			datasprint.bat = tonumber(string.char(packet[23]));
			SendPacket({asciiCode.ACK}); -- ACK
			return true;
		else
			return false;
		end
	elseif typePacket == 'C' then -- Heure de Passage
		local channel = GetChannel(packet);
		local chrono = GetTime(packet);
		
		-- Prise Offset 
		datasprint.offset = -3600000;		-- 1 heure de décalage ...
		-- if datasprint.offset == nil then
			-- local now = app.Now();
			-- adv.Alert('now = '..now);
			-- local offset = now - chrono + 1800000;
			-- adv.Alert('offset = '..offset);

			-- if offset > 0 then
				-- offset = math.floor(offset/3600000);
			-- else
				-- offset = math.floor(offset/3600000)-1;
			-- end
			-- datasprint.offset = offset*3600000;
			-- adv.Alert('datasprint.offset = '..datasprint.offset);
		-- end
		chrono = chrono + datasprint.offset;
		
		if channel == '01' then -- Départ
			AddTimePassage(chrono, 0);
		elseif channel == '02' then -- Arrivée
			AddTimePassage(chrono, -1);
		elseif channel == '03' then -- Inter 1
			AddTimePassage(chrono, 1);
		elseif channel == '04' then -- Vitesse
			AddTimePassage(chrono, 2);	-- a améliorer ...
		end
		
		-- Ecriture ACK 
		SendPacket({asciiCode.ACK});
		-- Si CheckSum pas OK => NAK
		
		adv.DebugPacket(packet,"*");
		return true;
	elseif typePacket == 'H' then -- Heure de Synchro
		if dlgSynchro ~= nil then
			dlgSynchro:EndModal();
			dlgSynchro = nil;
		end
		return true;
	end
	
	adv.DebugPacket(packet,"Unknown Packet:");
	SendPacket({asciiCode.ACK}); -- ACK
	return false;
end

function GetChannel(packet)
	local channel = adv.PacketString(packet, 7, 8);
	return channel;
end

function GetBattery(packet)
	local battery = adv.PacketString(packet, 23, 1);
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
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, device = 'radiocoms_datasport' }
	);
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
	bannerSat:SetText('./res/16x16_circle_green.png');
	bannerSat:Refresh();
end

function DrawLedKo(bannerSat)
	bannerSat:SetText('./res/16x16_circle_red.png');
	bannerSat:Refresh();
end
