-- AGIL IMHP V3
dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Creation et initialisation table imhp
imhp = {};

imhp.valueRSSI = -1;

-- Type de Synchro
imhp.Synchro = 
{
	NONE	= '?',
	TOP		= 'T',
	RF		= 'R',
	GPS		= 'G',
	DCF77	= 'D',
	OUT		= 'O'
};

-- Packet Header
imhp.Header = 
{
	BATTERY			= 'B',
	PULSE			= 'P',
	SYNCHRO			= 'S',
	WRITE_CONFIG	= 'W',
	READ_CONFIG		= 'R',
	DEBUG			= '?',
	RELOAD			= 'L'
};

imhp.HeaderID = 
{
	BATTERY			= 'b',
	PULSE			= 'p',
	SYNCHRO			= 's',
	WRITE_CONFIG	= 'w',
	READ_CONFIG		= 'r',
	RELOAD			= 'l'
};

imhp.Config = 
{
	ID					= 'I',
	DEBUG				= 'D',
	POWER				= 'P',
	CHANNEL				= 'C',
	DATA_INTERFACE		= 'A',
	BUZZER				= 'Z',
	INDEX_PULSE			= 'N',
	DATE				= 'd',
	DATETIME			= 't',
	TIME				= 'T',
	DELAY				= 'Y',
	CALIBRATION_N		= 'u',
	CALIBRATION_D		= 'e',
	OFFSET_RF			= 'o',
	PRINTER_BAUDRATE	= 'B',
	VERSION				= 'v',
	RSSI_MODE			= 'r',
	PRODUCT_ID			= 'H'
};

imhp.Printer = 
{
	BAUDRATE_1200	= 	'1',
	BAUDRATE_2400	= 	'2',
	BAUDRATE_4800	= 	'3',
	BAUDRATE_9600	= 	'4'
};

-- Calcul du ChekcSum 
imhp.ComputeCheckSum = function(packet, iStart, iEnd)
	if iStart == nil then iStart = 1 end
	if iStart < 1 then iStart = 1 end
	
	if iEnd == nil then iEnd = #packet end
	if iEnd > #packet then iEnd = #packet end

	local checkSum = 0;
	if type(packet) == 'table' then
		for i=iStart, iEnd do
			checkSum = byte.Sum(checkSum, packet[i]);
		end
	elseif type(packet) == 'string' then
		for i=iStart, iEnd do
			checkSum = byte.Sum(checkSum, string.byte(packet,i));
		end
	end
	return byte.Not(checkSum);
end

-- Envoi [LG][DATA][CHECKSUM][CR]
imhp.Send = function(packet)
	if mt_device.obj ~= nil then
		mt_device.obj:WriteByte(#packet+3);		-- Lg sur 1 Byte 
		if type(packet) == 'string' then
			mt_device.obj:WriteString(packet);	-- Data
		elseif type(packet) == 'table' then
			mt_device.obj:WriteByte(packet);	-- Data
		end
		mt_device.obj:WriteString(hexa.ToString(imhp.ComputeCheckSum(packet), 2));	-- Checksum sur 2 Bytes
		mt_device.obj:WriteByte(asciiCode.CR);	-- Cariage Return : Caractère Fin de Trame
	end
end

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = "3.5",
		name = 'AGIL IMHP Version 3', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '19200' }	} 
	};
end	

-- Ouverture
function device.OnInit(params, node)

	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	imhp.params = params;
	imhp.node = node;
	
	device.Load();
end

-- Chargement
function device.Load()	
	
	-- Lecture de la configuration 
	ReadConfig();
	
	-- Creation Panel
	local panel = wnd.CreatePanel({ parent = app.GetAuiFrame() });
	panel:LoadTemplateXML({ 
		xml = './device/agil_imhp_v3.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'dashboard'
	});
	
	imhp.panel = panel;
	imhp.grid = panel:GetWindowName('grid');
	imhp.gridMessage = panel:GetWindowName('message');

	-- Initialisation des Controles 
	
	-- ToolBar
	local tb = panel:GetWindowName('tb');
	local btnConfigGlobal = tb:AddTool("Configuration Globale", "./res/32x32_time-admin.png");
	local btnConfigChrono = tb:AddTool("Paramètrage du Chrono-Modem connecté", "./res/32x32_config.png");
	local btnPulseReload = tb:AddTool("Rechargement des Impulsions", "./res/32x32_restart.png");
	tb:AddSeparator();
	local btnSynchro = tb:AddTool("Synchronisation", "./res/32x32_synchro.png");
	tb:Realize();

	-- Grid
	local grid = panel:GetWindowName('grid');
	local tGrid = sqlTable.Create("imhp");
	tGrid:AddColumn({ name = 'Label', type = sqlType.TEXT, label = '' });
	for i=1, #imhp.chrono do
		tGrid:AddColumn({ name = 'C'..i, type = sqlType.TEXT, label = GetChronoLabel(imhp.chrono[i].id) });
	end
	tGrid:AddRow();	-- row RSSI
	tGrid:AddRow(); -- row Battery

	grid:Set({
		table_base = tGrid,
		selection_mode = gridSelectionModes.CELLS,
		sortable = false,
		enable_editing = false,
	});
		
	-- Creation du Timer 
	TimerInit();
	
	-- Prise des Messages 
	panel:Bind(eventType.MENU, OnSynchro, btnSynchro);
	panel:Bind(eventType.MENU, OnConfigGlobal, btnConfigGlobal);
	panel:Bind(eventType.MENU, OnConfigChrono, btnConfigChrono);
	panel:Bind(eventType.MENU, OnPulseReload, btnPulseReload);

	grid:Bind(eventType.SIZE, OnGridSize);

	grid:Bind(eventType.GRID_COL_LABEL_CONTEXT, OnColLabelContext);
	grid:Bind(eventType.GRID_CELL_CONTEXT, OnCellContext);

	panel:Bind(eventType.TIMER, OnTimer, imhp.timer);

	-- Affichage ...
	panel:Show(true);
	
	local mgr = app.GetAuiManager();
	mgr:AddPane(panel, {
		icon = './res/16x16_agil.png',
		caption = "Tableau de Bord Agil IMHP-V3",
		caption_visible = true,
		close_button = false,
		pin_button = true,
		show = true,

		float = true, 
		floating_position = {app.GetAuiFrame():GetDisplayArea().x+800, 40},
		floating_size = {250, 250},
		dockable = false
		
	});
	mgr:Update();
end

function TimerInit()
	if imhp.node ~= nil and imhp.node:GetAttribute('timer','1') == '0' then
		-- Mode Esclave
		imhp.alert('Mode Esclave : Aucun Timer ...');
		imhp.timer = nil;
	else
		-- Mode Normal ... Scrutation par Timer ...
		imhp.timer = timer.Create(imhp.panel);
		TimerStart();
	end
end

function TimerStart()
	if imhp.timer ~= nil then
		local delay = 500 + 250 * #imhp.chrono;
		imhp.timer:Start(delay);
		return true;
	else
		return false;
	end
end

function TimerStop()
	if imhp.timer ~= nil then
		imhp.timer:Stop();
		return true;
	else
		return false;
	end
end

function imhp.alert(txt)
	imhp.gridMessage:AddLine(txt);
end

function imhp.success(txt)
	imhp.gridMessage:AddLineSuccess(txt);
end

function imhp.warning(txt)
	imhp.gridMessage:AddLineWarning(txt);
end

function imhp.error(txt)
	imhp.gridMessage:AddLineError(txt);
end

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

-- Fermeture
function device.OnClose()
	imhp.stop = true;
	if mt_device.obj ~= nil then
		local parentFrame = wnd.GetParentFrame();
		parentFrame:Unbind(eventType.SERIAL, mt_device.obj);
	end
	
	if imhp.timer ~= nil then
		imhp.timer:Delete();
	end

	if imhp.panel ~= nil then
		local grid = imhp.panel:GetWindowName('grid');
		if grid ~= nil and grid:GetTable() ~= nil then
			grid:GetTable():Delete();
		end

		local mgr = app.GetAuiManager();
		mgr:DeletePane(imhp.panel);
	end
	
	-- Appel OnClose Metatable
	mt_device.OnClose();
end

-- Lecture du fichier de configuation 
function ReadConfig()

	imhp.chrono = {};

	local node = imhp.node;
	if node ~= nil then
		local child = node:GetChildren();
		while child ~= nil do
			-- Balise <chrono> 
			if child:GetName() == "chrono" then
				table.insert(imhp.chrono, { id = child:GetAttribute("id"), input1 = child:GetAttribute("input1"), input2 = child:GetAttribute("input2"), ack = -1, tickcount = 0 });
			end
			child = child:GetNext();
		end
	end

	if #imhp.chrono == 0 then
		-- Master obligatoire
		table.insert(imhp.chrono, { id = 'Master', input1 = 1, input2 = -1, ack = -1, tickcount = 0});
	end
end

function GetChronoLabel(id)
	if id == 'M' then
		return 'Master';
	else
		return 'Radio '..id;
	end
end

function OnGridSize(evt)
	local grid = imhp.panel:GetWindowName('grid');
	
	local rect = grid:GetRect();
	local nbRows = grid:GetNumberRows();
	local nbColumns = grid:GetNumberCols();
	local w = math.floor((rect.width-32)/(nbColumns-1));
	local h = math.floor(rect.height/(nbRows+1));

	if w > 0 then
		for j=1, nbColumns-1 do
			grid:SetColSize(j, w);
		end
		grid:SetColSize(0, rect.width-w*(nbColumns-1));
	end

	if h > 0 then
		for i=0, nbRows-1 do
			grid:SetRowSize(i, h);
		end
		grid:SetColLabelSize(rect.height-h*nbRows);
	end
	
	if evt ~= nil then
		evt:Skip(true);
	end
end

-- Evénement Timer 
function OnTimer(evt)
	imhp.stop = imhp.stop or false;
	if imhp.stop then return end;
	
	local countChrono = #imhp.chrono;

	-- Header 
	local packet = imhp.Header.PULSE;
	
	-- Ack Master (2 Byte en base64)
	packet = packet..base64.ToString(imhp.chrono[countChrono].ack, 2);
	
	-- Ack Radio1, Radio2, Radio3, Radio 4 ... (2 Byte en base64) ...
	if countChrono > 1 then
		for j=1,4 do
			local k = -1;
			for i=1,countChrono-1 do
				if tonumber(imhp.chrono[i].id) == j then
					k = i;
					break;
				end
			end
			if k >= 1 then
				packet = packet..base64.ToString(imhp.chrono[k].ack, 2);
			else
				packet = packet..base64.ToString(-1, 2);
			end
		end
	end
	
	-- Envoi MBUS
	imhp.Send(packet);
	
	-- Gestion TickCount
	local now = app.GetTickCount();
	local delayMs = 500 + 250 * #imhp.chrono;
	for i=1,countChrono do
		if now-imhp.chrono[i].tickcount > 8*delayMs then
			if imhp.chrono[i].tickcount > 0 then
				imhp.chrono[i].tickcount = 0;
				imhp.grid:RefreshCell(0, i);
				imhp.grid:RefreshCell(1, i);
			end
		end
	end
end

-- Synchronisation
function OnSynchro(evt)
	local dlg = wnd.CreateDialog({
		parent = imhp.panel,
		icon = "./res/32x32_agil.png",
		label = "Synchronisation IMHP V3",
		width = 400,
		height = 160
	});
	
	dlg:LoadTemplateXML({ 
		xml = './device/agil_imhp_v3.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'synchro'
	});
	
	-- Creation des controles 
	local timePickerSynchroTop = dlg:GetWindowName('time');
	local btnSynchroTop = dlg:GetWindowName('top');
	local btnSynchroOut = dlg:GetWindowName('out');
	local btnSynchroRF = dlg:GetWindowName('rf');
	local btnExit = dlg:GetWindowName('exit');

	function OnClose(evt)
		dlg:EndModal();
	end

	function OnSynchroTop(evt)
		
		local timeSynchro = timePickerSynchroTop:GetValue();
		imhp.alert("-> Demande Synchro TOP : "..string.format('%02dh%02d.%02d',timeSynchro.hour, timeSynchro.minute, timeSynchro.second));
		app.SendNotify('<offset_time_reset>');
		CommandSynchroTop(timeSynchro.hour, timeSynchro.minute, timeSynchro.second);
		dlg:EndModal();
		dlg:Delete();
	end

	function OnSynchroOut(evt)
		
		local timeSynchro = timePickerSynchroTop:GetValue();
		imhp.alert("-> Demande Synchro OUT : "..string.format('%02dh%02d.%02d',timeSynchro.hour, timeSynchro.minute, timeSynchro.second));
		CommandSynchroOut(timeSynchro.hour, timeSynchro.minute, timeSynchro.second);
		dlg:EndModal();
		dlg:Delete();
	end

	function OnSynchroRF(evt)
		imhp.alert("-> Demande Synchro.RF");
		CommandSynchroRF();
		dlg:EndModal();
		dlg:Delete();
	end
	
	-- Bind
	dlg:Bind(eventType.BUTTON, OnClose, btnExit);
	dlg:Bind(eventType.BUTTON, OnSynchroTop, btnSynchroTop);
	dlg:Bind(eventType.BUTTON, OnSynchroOut, btnSynchroOut);
	dlg:Bind(eventType.BUTTON, OnSynchroRF, btnSynchroRF);
	
	-- Affichage Modal
	TimerStop(); -- Fermeture du Timer tant que la boite de Dialogue est active
	dlg:Fit();
	dlg:ShowModal();
	TimerStart(); -- Reprise du Timer ...
end

-- Pulse Reload
function OnPulseReload(evt)
	local dlg = wnd.CreateDialog({
		parent = imhp.panel,
		icon = "./res/32x32_agil.png",
		label = "Rechargement des Impulsions",
		width = 400,
		height = 160
	});
	
	dlg:LoadTemplateXML({ 
		xml = './device/agil_imhp_v3.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'reload'
	});
	
	-- Initialisation des controles 
	local comboChrono = dlg:GetWindowName('combo_chrono');
	comboChrono:Append("M = Master");
	comboChrono:Append("1 = Radio 1");
	comboChrono:Append("2 = Radio 2");
	comboChrono:Append("3 = Radio 3");
	comboChrono:Append("4 = Radio 4");
	comboChrono:SetSelection(0);
	
	local spinStart = dlg:GetWindowName('pulse_start');
	spinStart:SetRange(0, 15000);
	spinStart:SetValue(0);
	
	local spinStop = dlg:GetWindowName('pulse_stop');
	spinStop:SetRange(0, 15000);
	spinStop:SetValue(0);
	
	local tb = dlg:GetWindowName('tb');
	local btnReload = tb:AddTool("Re-Chargement", "./res/32x32_send.png");
	tb:AddStretchableSpace();
	local btnExit = tb:AddTool("Quitter", "./res/vpe32x32_close.png");
	tb:Realize();

	function OnClose(evt)
		dlg:EndModal();
	end
	
	function OnReload(evt)
		local start = tonumber(spinStart:GetValue());
		local stop = tonumber(spinStop:GetValue());
		
		TimerStart();
		for i=start, stop do
			imhp.alert('Demande Ré-Emission '..comboChrono:GetValue()..' ID '..tostring(i));

			local packet = imhp.Header.RELOAD..comboChrono:GetValue():sub(1,1)..base64.ToString(i, 2);
			imhp.Send(packet);
			
			app.Sleep(1);
		end
		TimerStop();
	end

	-- Bind
	dlg:Bind(eventType.MENU, OnClose, btnExit);
	dlg:Bind(eventType.MENU, OnReload, btnReload);

	
	-- Affichage Modal
	TimerStop(); -- Fermeture du Timer tant que la boite de Dialogue est active
	dlg:Fit();
	dlg:ShowModal();
	TimerStart(); -- Reprise du Timer ...
end

-- Configuration Globale 
function OnConfigGlobal(evt)
	local dlg = wnd.CreateDialog({
		parent = imhp.panel,
		icon = "./res/32x32_agil.png",
		label = "Configuration Globale IMHP V3",
		width = 540,
		height = 260
	});

	dlg:LoadTemplateXML({ 
		xml = './device/agil_imhp_v3.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'global'
	});

	-- Initialisation des controles ...
	local checkChrono1 = dlg:GetWindowName('check_chrono1');
	local comboChrono1Input1 = dlg:GetWindowName('combo_chrono1_input1');
	local comboChrono1Input2 = dlg:GetWindowName('combo_chrono1_input2');

	local checkChrono2 = dlg:GetWindowName('check_chrono2');
	local comboChrono2Input1 = dlg:GetWindowName('combo_chrono2_input1');
	local comboChrono2Input2 = dlg:GetWindowName('combo_chrono2_input2');

	local checkChrono3 = dlg:GetWindowName('check_chrono3');
	local comboChrono3Input1 = dlg:GetWindowName('combo_chrono3_input1');
	local comboChrono3Input2 = dlg:GetWindowName('combo_chrono3_input2');

	local checkChrono4 = dlg:GetWindowName('check_chrono4');
	local comboChrono4Input1 = dlg:GetWindowName('combo_chrono4_input1');
	local comboChrono4Input2 = dlg:GetWindowName('combo_chrono4_input2');
	
	local comboChronoMasterInput1 = dlg:GetWindowName('combo_master_input1');
	local comboChronoMasterInput2 = dlg:GetWindowName('combo_master_input2');
	
	local tb = dlg:GetWindowName('tb');
	local btnSave = tb:AddTool("Enregistrer", "./res/32x32_ok.png");
	tb:AddStretchableSpace();
	local btnExit = tb:AddTool("Quitter", "./res/vpe32x32_close.png");
	tb:Realize();

	function OnCheckChrono1(evt)
		local enable = checkChrono1:GetValue();
		comboChrono1Input1:Enable(enable); 
		comboChrono1Input2:Enable(enable); 
	end

	function OnCheckChrono2(evt)
		local enable = checkChrono2:GetValue();
		comboChrono2Input1:Enable(enable); 
		comboChrono2Input2:Enable(enable); 
	end

	function OnCheckChrono3(evt)
		local enable = checkChrono3:GetValue();
		comboChrono3Input1:Enable(enable); 
		comboChrono3Input2:Enable(enable); 
	end

	function OnCheckChrono4(evt)
		local enable = checkChrono4:GetValue();
		comboChrono4Input1:Enable(enable); 
		comboChrono4Input2:Enable(enable); 
	end

	function OnSave(evt)
		local node = imhp.node;
		if node == nil then return end

		-- Suppression ancienne config ...
		local child = node:GetChildren();
		local nodeDelete = {};
		while child ~= nil do
			if child:GetName() == "chrono" then
				table.insert(nodeDelete,child); 
			end
			child = child:GetNext();
		end
		for i=1,#nodeDelete do
			node:DeleteChild(nodeDelete[i]);
			nodeDelete[i]:Delete();
		end

		-- Enregistrement nouvelle config ...
		if checkChrono1:GetValue() == true then
			local child = xmlNode.Create(node, xmlNodeType.ELEMENT_NODE, "chrono");
			child:AddAttribute('id', '1');
			child:AddAttribute('input1', GetComboInputValue(comboChrono1Input1));
			child:AddAttribute('input2', GetComboInputValue(comboChrono1Input2));
		end
				
		if checkChrono2:GetValue() == true then
			local child = xmlNode.Create(node, xmlNodeType.ELEMENT_NODE, "chrono");
			child:AddAttribute('id', '2');
			child:AddAttribute('input1', GetComboInputValue(comboChrono2Input1));
			child:AddAttribute('input2', GetComboInputValue(comboChrono2Input2));
		end

		if checkChrono3:GetValue() == true then
			local child = xmlNode.Create(node, xmlNodeType.ELEMENT_NODE, "chrono");
			child:AddAttribute('id', '3');
			child:AddAttribute('input1', GetComboInputValue(comboChrono3Input1));
			child:AddAttribute('input2', GetComboInputValue(comboChrono3Input2));
		end
		
		if checkChrono4:GetValue() == true then
			local child = xmlNode.Create(node, xmlNodeType.ELEMENT_NODE, "chrono");
			child:AddAttribute('id', '4');
			child:AddAttribute('input1', GetComboInputValue(comboChrono4Input1));
			child:AddAttribute('input2', GetComboInputValue(comboChrono4Input2));
		end
				
		local child = xmlNode.Create(node, xmlNodeType.ELEMENT_NODE, "chrono");
		child:AddAttribute('id', 'M');
		child:AddAttribute('input1', GetComboInputValue(comboChronoMasterInput1));
		child:AddAttribute('input2', GetComboInputValue(comboChronoMasterInput2));

		if app.GetXML():SaveFile() == true then
			-- Rechargement Config => table imhp.chrono ok ...
			ReadConfig();
			
			-- Maj Colonnes de la grille ...
			local grid = imhp.grid;
			local tGrid = grid:GetTable();
			tGrid:RemoveAllColumns();
			tGrid:AddColumn({ name = 'Label', type = sqlType.TEXT, label = '' });
			for i=1, #imhp.chrono do
				tGrid:AddColumn({ name = 'C'..i, type = sqlType.TEXT, label = GetChronoLabel(imhp.chrono[i].id) });
			end
			tGrid:ClearVisibleColumns();
			grid:SynchronizeColumns();
			
			OnGridSize();
		end
	end

	function OnClose(evt)
		dlg:EndModal();
	end

	-- Bind
	dlg:Bind(eventType.CHECKBOX, OnCheckChrono1, checkChrono1);
	dlg:Bind(eventType.CHECKBOX, OnCheckChrono2, checkChrono2);
	dlg:Bind(eventType.CHECKBOX, OnCheckChrono3, checkChrono3);
	dlg:Bind(eventType.CHECKBOX, OnCheckChrono4, checkChrono4);

	dlg:Bind(eventType.MENU, OnSave, btnSave);
	dlg:Bind(eventType.MENU, OnClose, btnExit);
	
	function SetComboInput(combo)
		combo:Append("Départ");
		combo:Append("Inter-1");
		combo:Append("Inter-2");
		combo:Append("Inter-3");
		combo:Append("Inter-4");
		combo:Append("Inter-5");
		combo:Append("Arrivée");
		combo:Append("(aucune)");
	end
	
	function SetComboInputValue(combo, value)
		if value == '0' then
			combo:SetValue("Départ");
		elseif value == '1' then
			combo:SetValue("Inter-1");
		elseif value == '2' then
			combo:SetValue("Inter-2");
		elseif value == '3' then
			combo:SetValue("Inter-3");
		elseif value == '4' then
			combo:SetValue("Inter-4");
		elseif value == '5' then
			combo:SetValue("Inter-5");
		elseif value == '-1' then
			combo:SetValue("Arrivée");
		else
			combo:SetValue("(aucune)");
		end
	end
	
	function GetComboInputValue(combo)
		local value = combo:GetValue();
		if value == 'Départ' then
			return '0';
		elseif value == 'Inter-1' then
			return '1';
		elseif value == 'Inter-2' then
			return '2';
		elseif value == 'Inter-3' then
			return '3';
		elseif value == 'Inter-4' then
			return '4';
		elseif value == 'Inter-5' then
			return '5';
		elseif value == 'Arrivée' then
			return '-1';
		else
			return '';
		end
	end

	SetComboInput(comboChrono1Input1);
	SetComboInput(comboChrono1Input2);
	SetComboInput(comboChrono2Input1);
	SetComboInput(comboChrono2Input2);
	SetComboInput(comboChrono3Input1);
	SetComboInput(comboChrono3Input2);
	SetComboInput(comboChrono4Input1);
	SetComboInput(comboChrono4Input2);
	SetComboInput(comboChronoMasterInput1);
	SetComboInput(comboChronoMasterInput2);
	
	for i=1, #imhp.chrono do
		if imhp.chrono[i].id == "1" then
			checkChrono1:SetValue(true);
			SetComboInputValue(comboChrono1Input1, imhp.chrono[i].input1);
			SetComboInputValue(comboChrono1Input2, imhp.chrono[i].input2);
		elseif imhp.chrono[i].id == "2" then
			checkChrono2:SetValue(true);
			SetComboInputValue(comboChrono2Input1, imhp.chrono[i].input1);
			SetComboInputValue(comboChrono2Input2, imhp.chrono[i].input2);
		elseif imhp.chrono[i].id == "3" then
			checkChrono3:SetValue(true);
			SetComboInputValue(comboChrono3Input1, imhp.chrono[i].input1);
			SetComboInputValue(comboChrono3Input2, imhp.chrono[i].input2);
		elseif imhp.chrono[i].id == "4" then
			checkChrono4:SetValue(true);
			SetComboInputValue(comboChrono4Input1, imhp.chrono[i].input1);
			SetComboInputValue(comboChrono4Input2, imhp.chrono[i].input2);
		elseif imhp.chrono[i].id == "M" then
			SetComboInputValue(comboChronoMasterInput1, imhp.chrono[i].input1);
			SetComboInputValue(comboChronoMasterInput2, imhp.chrono[i].input2);
		end
	end	
	
	OnCheckChrono1();
	OnCheckChrono2();
	OnCheckChrono3();
	OnCheckChrono4();
	
	-- Affichage Modal
	TimerStop(); -- Fermeture du Timer tant que la boite de Dialogue est active
	dlg:Fit();
	dlg:ShowModal();
	dlg:Delete();
	TimerStart(); -- Reprise du Timer ...
	
	evt:Skip(false);
end

function OnColLabelContext(evt)
	local col = evt:GetCol();
	if col == 0 then
		evt:SetCellContext({ 
			bk_color_start = color.WHITE, 
			bk_color_end = color.LTGRAY, 
			pen = pen.Create({ size=1, color = color.LTGRAY }),
			bitmaps = { { image = './res/16x16_chrono_v3.png'} }
	});
	end
end

function OnCellContext(evt)

	local row = evt:GetRow();
	local col = evt:GetCol();

	if col == 0 then
		-- Label
		if row == 0 then
			-- RSSI
			evt:SetCellContext({ 
				bk_color_start = color.WHITE, 
				bk_color_end = color.LTGRAY,
				pen = pen.Create({ size=1, color = color.LTGRAY }),
				bitmaps = { { image = './res/16x16_antenna.png'} }
			});
		elseif row == 1 then
			-- Battery
			evt:SetCellContext({ 
				bk_color_start = color.WHITE, 
				bk_color_end = color.LTGRAY,
				pen = pen.Create({ size=1, color = color.LTGRAY }),
				bitmaps = { { image = './res/16x16_battery_half.png'} }
			});
		end
	else
		if row == 0 then
			-- RSSI
			if imhp.chrono[col].tickcount == 0 then
				evt:SetCellContext({ 
					align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL,
					bk_color_start = color.LTRED, 
					bk_color_end = color.DKRED,
					bk_direction = wndDirection.TOP,
					text_color = color.BLACK
				});
			else
				evt:SetCellContext({ 
					align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL,
					bk_color_start = color.LTGREEN, 
					bk_color_end = color.DKGREEN,
					text_color = color.WHITE
				});
			end
		elseif row == 1 then
			-- Battery
			local txt = evt:GetCellContext({ 'text' });
			txt = tonumber(txt) or 0;

			if imhp.chrono[col].tickcount == 0 then
				evt:SetCellContext({ 
					bk_color_start = color.LTRED, 
					bk_color_end = color.DKRED,
					bk_direction = wndDirection.TOP,
					align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL,
					text = txt..'%';
				});
			else
				if txt < 25 then
					evt:SetCellContext({ 
						bk_color_start = color.LTORANGE, 
						bk_color_end = color.DKRORANGE,
						bk_direction = wndDirection.TOP,
						align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL,
						text_color = color.BLACK,
						text = txt..'%';
					});
				else
					evt:SetCellContext({ 
						bk_color_start = color.LTGREEN, 
						bk_color_end = color.DKGREEN,
						bk_direction = wndDirection.TOP,
						align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL,
						text_color = color.WHITE,
						text = txt..'%';
					});
				end
			end
		end
	end
end

-- Configuration 
function OnConfigChrono(evt)
	local dlg = wnd.CreateDialog({
		parent = imhp.panel,
		icon = "./res/32x32_agil.png",
		label = "Configuration Chrono-Modem IMHP V3",
		width = 600,
		height = 560
	});

	dlg:LoadTemplateXML({ 
		xml = './device/agil_imhp_v3.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'chrono_modem'
	});

	-- Initialisation des controles 
	
	-- ID
	local comboID = dlg:GetWindowName('combo_id');
	comboID:Append('M : Master');
	comboID:Append('1 : Radio 1');
	comboID:Append('2 : Radio 2');
	comboID:Append('3 : Radio 3');
	comboID:Append('4 : Radio 4');
	comboID:Append('5 : Radio 5');
	comboID:Append('R : Relais');

	-- Channel
	local comboChannel = dlg:GetWindowName('combo_channel');
	for i=1,24 do
		comboChannel:Append(tostring(i));
	end

	-- Power
	local comboPower = dlg:GetWindowName('combo_power');
	for i=1,5 do
		comboPower:Append(tostring(i));
	end

	-- Printer
	local comboPrinterSpeed = dlg:GetWindowName('combo_printer_speed');
	comboPrinterSpeed:Append('1200');
	comboPrinterSpeed:Append('2400');
	comboPrinterSpeed:Append('4800');
	comboPrinterSpeed:Append('9600');
	comboPrinterSpeed:Append('19200');
	
	-- RSSI
	local comboRSSI = dlg:GetWindowName('combo_rssi');
	comboRSSI:Append('On');
	comboRSSI:Append('Off');
	comboRSSI:SetValue('On');

	-- Debug
	local comboDebug = dlg:GetWindowName('combo_debug');
	comboDebug:Append('On');
	comboDebug:Append('Off');
	comboDebug:SetValue('Off');

	-- Neutralisation Calibration et Offset RF 
	if imhp.params.admin == nil or imhp.params.admin == '0' then
		dlg:GetWindowName('calib_d'):Enable(false);
		dlg:GetWindowName('calib_n'):Enable(false);
		dlg:GetWindowName('offset_rf'):Enable(false);
	
		dlg:GetWindowName('btn_calib_d'):Enable(false);
		dlg:GetWindowName('btn_calib_n'):Enable(false);
		dlg:GetWindowName('btn_offset_rf'):Enable(false);
	end
	
	-- Toolbar
	local tb = dlg:GetWindowName('tb');
	local btnInspectionChrono = tb:AddTool("Inspection Chrono", "./res/32x32_find.png");
	local btnInspectionModem = tb:AddTool("Inspection Modem", "./res/32x32_find.png");
	local btnInspectionClock = tb:AddTool("Inspection Horloge", "./res/32x32_find.png");
	tb:AddStretchableSpace();
	local btnInitChrono = tb:AddTool("Init. Chrono", "./res/32x32_save.png");
	local btnInitModem = tb:AddTool("Init. Modem", "./res/32x32_save.png");
	tb:AddStretchableSpace();
	local btnExit = tb:AddTool("Quitter", "./res/vpe32x32_close.png");
	tb:Realize();
		
	function OnChangeID(evt)
		local ID = comboID:GetValue();
		if string.len(ID) == 0 then
			imhp.warning("Erreur : Aucun ID sélectionné ...");
		else
			imhp.alert("-> Demande changement ID "..ID);
			CommandChangeID(ID);
		end
	end

	function OnChangeChannel(evt)
		local channel = comboChannel:GetValue();
		if string.len(channel) == 0 then
			imhp.warning("Erreur : Aucun Canal sélectionné ...");
		else
			imhp.alert("-> Demande changement canal "..channel);
			CommandChangeChannel(channel);
		end
	end

	function OnChangePower(evt)
		local power = comboPower:GetValue();
		if string.len(power) == 0 then
			imhp.warning("Erreur : Aucune Puissance sélectionnée ...");
		else
			imhp.alert("-> Demande changement puissance "..power);
			CommandChangePower(power);
		end
	end
	
	function OnChangeDelay(evt)
		local delay = dlg:GetWindowName('spin_delay_input'):GetValue();
		imhp.alert("-> Demande changement délai rebond (1/10 sec) "..delay);
		CommandChangeDelay(delay);
	end
	
	function OnChangeBuzzer(evt)
		local buzzer = dlg:GetWindowName('spin_delay_buzzer'):GetValue();
		imhp.alert("-> Demande changement délai buzzer (1/10 sec) "..buzzer);
		CommandChangeBuzzer(buzzer);
	end
	
	function OnChangePrinter(evt)
		local printer = comboPrinterSpeed:GetValue();
		imhp.alert("-> Demande changement Printer Vitesse "..printer);
		CommandChangePrinter(printer);
	end
	
	function OnChangeDate(evt)
		local dateValue = dlg:GetWindowName('date_chrono'):GetValue();
		imhp.alert("-> Demande changement Date "..string.format("%#02d",dateValue.day)..'/'..string.format("%#02d",dateValue.month)..'/'..dateValue.year);
		CommandChangeDate(dateValue);
	end

	function OnChangeTime(evt)
		local timeValue = dlg:GetWindowName('hour_chrono'):GetValue();
		imhp.alert("-> Demande changement Heure "..string.format("%#02d",timeValue.hour)..'h'..string.format("%#02d",timeValue.minute)..'.'..string.format("%#02d",timeValue.second));
		CommandChangeTime(timeValue);
	end
	
	function OnCalibrationN(evt)
		local valueN = tonumber(dlg:GetWindowName('calib_n'):GetValue());
		imhp.alert("-> Demande changement Calibration N "..valueN);
		CommandChangeCalibrationN(valueN);
	end
	
	function OnCalibrationD(evt)
		local valueD = tonumber(dlg:GetWindowName('calib_d'):GetValue());
		imhp.alert("-> Demande changement Calibration D "..valueD);
		CommandChangeCalibrationD(valueD);
	end
	
	function OnOffsetRF(evt)
		local valueOffsetRF = tonumber(dlg:GetWindowName('offset_rf'):GetValue());
		imhp.alert("-> Demande changement Offset RF "..valueOffsetRF);
		CommandChangeOffsetRF(valueOffsetRF);
	end
	
	function OnRSSI(evt)
		local valueRSSI = comboRSSI:GetValue();
		imhp.alert("-> Demande changement RSSI "..valueRSSI);
		CommandChangeRSSI(valueRSSI);
	end

	function OnDebug(evt)
		local valueDebug = comboDebug:GetValue();
		imhp.alert("-> Demande changement Debug "..valueDebug);
		CommandChangeDebug(valueDebug);
	end
	
	function OnInspectionChrono(evt)
		imhp.alert("-> Demande Inspection Chrono");
		CommandInspectionChrono();
	end

	function OnInspectionModem(evt)
		imhp.alert("-> Demande Inspection Modem");
		CommandInspectionModem();
	end

	function OnInspectionClock(evt)
		imhp.alert("-> Demande Inspection Horloge");
		CommandInspectionClock();
	end
	
	function OnInitChrono(evt)
		imhp.alert("-> Demande Initialisation Chrono");
		CommandInitChrono();
	end

	function OnInitModem(evt)
		imhp.alert("-> Demande Initialisation Modem");
		CommandInitModem();
	end
	
	function OnClose(evt)
		dlg:EndModal();
	end

	-- Bind
	dlg:Bind(eventType.BUTTON, OnChangeID, dlg:GetWindowName('btn_id'));
	dlg:Bind(eventType.BUTTON, OnChangeChannel, dlg:GetWindowName('btn_channel'));
	dlg:Bind(eventType.BUTTON, OnChangePower, dlg:GetWindowName('btn_power'));
	dlg:Bind(eventType.BUTTON, OnChangeDelay, dlg:GetWindowName('btn_delay_input'));
	dlg:Bind(eventType.BUTTON, OnChangeBuzzer, dlg:GetWindowName('btn_delay_buzzer'));
	dlg:Bind(eventType.BUTTON, OnChangePrinter, dlg:GetWindowName('btn_printer_speed'));
	dlg:Bind(eventType.BUTTON, OnChangeDate, dlg:GetWindowName('btn_date_chrono'));
	dlg:Bind(eventType.BUTTON, OnChangeTime, dlg:GetWindowName('btn_hour_chrono'));
	dlg:Bind(eventType.BUTTON, OnCalibrationN, dlg:GetWindowName('btn_calib_n'));
	dlg:Bind(eventType.BUTTON, OnCalibrationD, dlg:GetWindowName('btn_calib_d'));
	dlg:Bind(eventType.BUTTON, OnOffsetRF, dlg:GetWindowName('btn_offset_rf'));
	dlg:Bind(eventType.BUTTON, OnRSSI, dlg:GetWindowName('btn_rssi'));
	dlg:Bind(eventType.BUTTON, OnDebug, dlg:GetWindowName('btn_debug'));
	
	dlg:Bind(eventType.MENU, OnInspectionChrono, btnInspectionChrono);
	dlg:Bind(eventType.MENU, OnInspectionModem, btnInspectionModem);
	dlg:Bind(eventType.MENU, OnInspectionClock, btnInspectionClock);
	dlg:Bind(eventType.MENU, OnInitChrono, btnInitChrono);
	dlg:Bind(eventType.MENU, OnInitModem, btnInitModem);
	dlg:Bind(eventType.MENU, OnClose, btnExit);
	
	-- Show  Modal
	TimerStop(); -- Fermeture du Timer tant que la boite de Dialogue est active
	dlg:Fit();
	dlg:ShowModal();
	dlg:Delete();
	TimerStart(); -- Reprise du Timer ...
	
	evt:Skip(false);
end

-- Standard Serial Event
function device.OnSerial(evt)
	if evt:GetInt() == serialNotify.RXCHAR then
		if mt_device ~= nil and mt_device.obj ~= nil then
			mt_device.obj:ReadToCircularBuffer();
			device.OnRead(mt_device.obj:GetCircularBuffer());
			mt_device.obj:ReStartEvent();
		end
	elseif evt:GetInt() == serialNotify.CONNECTION then
		imhp.success(evt:GetString());
	else
		imhp.error(evt:GetString());
	end
end

-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	-- Test si le Buffer est vide 
	if cb:GetCount() == 0 then	return end

	-- Lecture des Packets 
	while (ReadPacket(cb)) do end
end

-- Structure des Trames IMHP : <lg> .... <checksum><cr> ou <lg> .... <checksum><rssi><cr>
-- lg 		: Longueur : 1 Byte 
-- checksum	: 2 Bytes (Hexa)
-- rssi		: / + 2 Bytes (Hexa)
function ReadPacket(cb)
	local iFind = cb:Find(asciiCode.CR);	-- Recherche CR = caractere fin de Trame 		
	if iFind == -1 then return false end 	-- On peut stopper la recherche
	
	if iFind == 0 then 
		-- Il faut traiter la cas ou CR=13 indique la longueur de la trame ...
		iFind = cb:FindChar(asciiCode.CR, 1);	-- On cherche alors la deuxième occurence
		if iFind == -1 then return false end 
	end

	-- Prise du packet 
	local packet = cb:ReadByte(iFind);

	if IsPacketOk(packet) then
		local header = string.char(packet[1]);
		if header == imhp.HeaderID.BATTERY then
			ReadPacketBattery(packet);
			MessagePacket(packet, ' (*)');
		elseif header == imhp.HeaderID.PULSE then 
			ReadPacketPulse(packet);
			MessagePacket(packet, ' (*)');
		elseif header == imhp.HeaderID.READ_CONFIG then 
			ReadPacketConfig(packet);
			MessagePacket(packet, ' (*)');
		elseif header == imhp.HeaderID.SYNCHRO then 
			ReadPacketSynchro(packet);
			MessagePacket(packet, ' (*)');
		elseif header == imhp.HeaderID.RELOAD then 
			ReadPacketPulse(packet);
			MessagePacket(packet, ' (*)');
		else
			imhp.warning("Header unknown : "..header);
			MessagePacket(packet);
		end
	else
		MessagePacket(packet);
	end

	return true;
end

-- <HEADER_ID.BATTERY><ID><PERCENT><TYPE_SYNCHRO>
function ReadPacketBattery(packet)
	if #packet < 5 then return end;

	local idChrono = string.char(packet[2]);
	local percent = adv.PacketString(packet, 3, 4);
	local synchro = string.char(packet[5]);

	local infoRSSI = '';
	if synchro == 'R' then
		infoRSSI = 'RF ';
	elseif synchro == 'T' then
		infoRSSI = 'TOP ';
	end
	
	if imhp.valueRSSI ~= -1 then
		infoRSSI = infoRSSI..'rssi='..imhp.valueRSSI;
	end

	local tGrid = imhp.grid:GetTable();
	
	local countChrono = #imhp.chrono;
	for i=1,countChrono do
		if imhp.chrono[i].id == idChrono then
			imhp.chrono[i].tickcount = app.GetTickCount();
			tGrid:SetCell(i, 0, infoRSSI);
			tGrid:SetCell(i, 1, percent);
			
			imhp.grid:RefreshCell(0, i);
			imhp.grid:RefreshCell(1, i);
			break;
		end
	end 
end

-- <HEADER_ID.PULSE><ID><INDEX (2 BYTE en BASE64)><TIME (6 BYTE en BASE64)>
-- <HEADER_ID.RELOAD><ID><INDEX (2 BYTE en BASE64)><TIME (6 BYTE en BASE64)>
function ReadPacketPulse(packet)

	local idChrono = string.char(packet[2]);
	local index64 = adv.PacketString(packet,3,4)
	local index = base64.ToInteger(index64, 2)
	local time64 = adv.PacketString(packet,5,10)
	local mstime = base64.ToInteger(time64)
	
	local origin = '9';
	if #packet >= 11 then
		origin = string.char(packet[11]);
	end
	
	local countChrono = #imhp.chrono;
	for i=1,countChrono do
		if imhp.chrono[i].id == idChrono then
			imhp.chrono[i].ack = index;
			imhp.chrono[i].tickcount = app.GetTickCount();

			if origin >= '2' then
				AddTimePassage(mstime, imhp.chrono[i].input2, index);
			else
				AddTimePassage(mstime, imhp.chrono[i].input1, index);
			end
			return;
		end
	end 
	
	-- idChrono non pris en compte ?
	AddTimePassage(mstime, 99, index);
end

-- <HEADER_ID.READ_CONFIG><ID><key1><value1><key2><value2>... 
function ReadPacketConfig(packet)
	local lg = #packet;
	if lg < 2 then return end;

	local ID = adv.PacketString(packet,2,2);
	if ID == 'M' then
		imhp.warning("ID="..ID..' (Chrono Master)');
	else
		imhp.warning("ID="..ID..' (Chrono Radio '..ID..')');
	end

	local i = 3;
	while i < lg do
		local key = adv.PacketString(packet,i,i);
		if key == imhp.Config.ID then
			imhp.warning("ID="..adv.PacketString(packet,i+1,i+1));
			i = i+2;
		elseif key == imhp.Config.DEBUG then
			imhp.warning("DEBUG="..adv.PacketString(packet,i+1,i+1));
			i = i+2;
		elseif key == imhp.Config.DELAY then
			imhp.warning("DELAY="..adv.PacketString(packet,i+1,i+3));
			i = i+4;
		elseif key == imhp.Config.BUZZER then
			imhp.warning("BUZZER="..adv.PacketString(packet,i+1,i+3));
			i = i+4;
		elseif key == imhp.Config.INDEX_PULSE then
			imhp.warning("INDEX_PULSE="..adv.PacketString(packet,i+1,i+4));
			i = i+5;
		elseif key == imhp.Config.DATE then
			imhp.warning("DATE="..adv.PacketString(packet,i+1,i+8));
			i = i+9;	
		elseif key == imhp.Config.DATETIME then
			imhp.warning("DATETIME="..adv.PacketString(packet,i+1,i+14));
			i = i+15;	
		elseif key == imhp.Config.TIME then
			imhp.warning("TIME="..adv.PacketString(packet,i+1,i+6));
			i = i+7;	
		elseif key == imhp.Config.POWER then
			imhp.warning("POWER="..adv.PacketString(packet,i+1,i+1));
			i = i+2;	
		elseif key == imhp.Config.CHANNEL then
			imhp.warning("CHANNEL="..adv.PacketString(packet,i+1,i+2));
			i = i+3;	
		elseif key == imhp.Config.DATA_INTERFACE then
			imhp.warning("DATA_INTERFACE="..adv.PacketString(packet,i+1,i+1));
			i = i+2;	
		elseif key == imhp.Config.RSSI_MODE then
			imhp.warning("RSSI_MODE="..adv.PacketString(packet,i+1,i+1));
			i = i+2;	
		elseif key == imhp.Config.CALIBRATION_N then
			imhp.warning("CALIBRATION_N="..adv.PacketString(packet,i+1,i+10));
			i = i+11;	
		elseif key == imhp.Config.CALIBRATION_D then
			imhp.warning("CALIBRATION_D="..adv.PacketString(packet,i+1,i+10));
			i = i+11;	
		elseif key == imhp.Config.OFFSET_RF then
			imhp.warning("OFFSET_RF="..adv.PacketString(packet,i+1,i+3));
			i = i+4;	
		elseif key == imhp.Config.PRODUCT_ID then
			imhp.warning("PRODUCT_ID="..adv.PacketString(packet,i+1,i+10));
			i = i+11;	
		elseif key == imhp.Config.VERSION then
			imhp.warning("VERSION="..adv.PacketString(packet,i+1,i+4));
			i = i+5;	
		elseif key == imhp.Config.PRINTER_BAUDRATE then
			local baudrate = adv.PacketString(packet,i+1,i+1);
			i = i+2;	
			if baudrate == imhp.Printer.BAUDRATE_1200 then
				imhp.warning("PRINTER=1200");
			elseif baudrate == imhp.Printer.BAUDRATE_2400 then
				imhp.warning("PRINTER=2400");
			elseif baudrate == imhp.Printer.BAUDRATE_4800 then
				imhp.warning("PRINTER=4800");
			elseif baudrate == imhp.Printer.BAUDRATE_9600 then
				imhp.warning("PRINTER=9600");
			else
				imhp.warning("PRINTER=???");
			end
		else
			imhp.warning("KEY="..key.." UNKNOWN ???");
			i = lg;
			break;
		end
	end
end

-- <PACKET_HEADER_ID_SYNCHRO><id><SYNCHRO_TOP><HHMMSS><origin>
-- <PACKET_HEADER_ID_SYNCHRO><id><SYNCHRO_RF>
function ReadPacketSynchro(packet)

	local lg = #packet;
	if lg < 3 then return end;

	local idChrono = adv.PacketString(packet, 2, 2);
	local typeSynchro = adv.PacketString(packet, 3, 3);
	
	if typeSynchro == imhp.Synchro.TOP then
		
		local strHHMMSS = adv.PacketString(packet, 4, 9);
		imhp.warning("SYNCHRO TOP "..strHHMMSS);
		local mstime = adv.HHMMSS_To_MS(strHHMMSS);
		local origin = adv.PacketString(packet, 10, 10);
				
		local countChrono = #imhp.chrono;
		for i=1,countChrono do
			if imhp.chrono[i].id == idChrono then
				imhp.chrono[i].tickcount = app.GetTickCount();

				if origin == '2' then
					AddTimePassage(mstime, imhp.chrono[i].input2, -1);
				else
					AddTimePassage(mstime, imhp.chrono[i].input1, -1);
				end
				return;
			end
		end
	elseif typeSynchro == imhp.Synchro.RF then
		imhp.warning("SYNCHRO RF "..idChrono);
	end 
end

function IsPacketOk(packet)
	
	local valueRSSI = imhp.valueRSSI;

	if IsPacketKeyboard(packet) then
		MessagePacket(packet, " (Keyboard)");
	end

	local lg = #packet;
	if lg < 4 then return false end
	if packet[lg] ~= asciiCode.CR then return false end

	local lg1 = packet[1];
	if packet[lg-3] == string.byte('/') then
		-- Information RSSI présente dans la trame ...
		if lg > 7 then
			local rssiHexa = string.char(packet[lg-2])..string.char(packet[lg-1]);
			valueRSSI = hexa.ToInteger(rssiHexa); 
			-- Suppression des 3 Bytes RSSI
			table.remove(packet, #packet-1);
			table.remove(packet, #packet-1);
			table.remove(packet, #packet-1);
			lg = #packet;
		end
	end
	
	-- Test cohérence sur la longueur 
	if lg ~= lg1 + 1 then return false end

	-- Test checkSum
	local checksum1 = imhp.ComputeCheckSum(packet, 2, lg - 3);
	local checksumString = string.char(packet[lg-2])..string.char(packet[lg-1]);
	local checksum2 = hexa.ToInteger(checksumString); 
	if checksum1 ~= checksum2 then return false; end
	
	-- Longueur Ok, CheckSum Ok => la trame est correcte ...
	table.remove(packet,1); -- Suppression Byte Longueur
	table.remove(packet, #packet);	-- Suppression CR
	table.remove(packet, #packet);	-- Suppression CheckSum deuxieme caractere
	table.remove(packet, #packet);	-- Suppression CheckSum premier caractere

	imhp.valueRSSI = valueRSSI;
	return true;
end

function IsPacketKeyboard(packet)
	if #packet < 4 then return false end
	if (packet[1] ~= string.byte('[') or packet[4] ~= string.byte(']')) then return false end

	-- Remplacement de la sequence [xx] par la vraie longueur sur 1 Byte 
	local lgHexa = string.char(packet[2])..string.char(packet[3]);
	local lg = hexa.ToInteger(lgHexa); 
	table.remove(packet, 1);
	table.remove(packet, 1);
	table.remove(packet, 1);
	packet[1] = lg+2;

	-- Ajout du CheckSum ...
	lg = #packet;
	local checkSum = imhp.ComputeCheckSum(packet, 2, lg-1);
	local strCheckSum = hexa.ToString(checkSum, 2);
	table.insert(packet, lg, string.byte(strCheckSum,1));
	table.insert(packet, lg+1, string.byte(strCheckSum,2));

	return true;
end

-- Envoi du packet dans la fenêtre d'information
function MessagePacket(packet, msg)
	local strPacket = '';
	for i=1,#packet do
		if packet[i] >= 32 then
			strPacket = strPacket..string.char(packet[i]);
		end
	end

	if msg == nil then
		imhp.alert(strPacket);
	else
		imhp.alert(strPacket..msg);
	end
end

function AddTimePassage(chrono, passage, index)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, device = 'agil_imhp', log=index }
	);
end

function CommandChangeID(ID)
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.ID..string.sub(ID,1,1);
	imhp.Send(packet);
end

function CommandChangeChannel(channel)
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.CHANNEL..string.format('%#02d', tonumber(channel));
	imhp.Send(packet);
end

function CommandChangePower(power)
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.POWER..power;
	imhp.Send(packet);
end

function CommandChangeDelay(delay)
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.DELAY..delay;
	imhp.Send(packet);
end

function CommandChangeBuzzer(buzzer)
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.BUZZER..buzzer;
	imhp.Send(packet);
end

function CommandChangePrinter(printer)
	local rate = imhp.Printer.BAUDRATE_1200;
	
	if printer == '2400' then rate = imhp.Printer.BAUDRATE_2400;
	elseif printer == '4800' then rate = imhp.Printer.BAUDRATE_4800;
	elseif printer == '9600' then rate = imhp.Printer.BAUDRATE_9600;
	end
	
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.PRINTER_BAUDRATE..rate;
	imhp.Send(packet);
end

function CommandChangeDate(dateValue)
	local dateYYYYMMDD = dateValue.year..string.format("%#02d",dateValue.month)..string.format("%#02d",dateValue.day);
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.DATE..dateYYYYMMDD;
	imhp.Send(packet);
end

function CommandChangeTime(timeValue)
	local timeHHMMSS = string.format("%#02d",timeValue.hour)..string.format("%#02d",timeValue.minute)..string.format("%#02d",timeValue.second);
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.TIME..timeHHMMSS;
	imhp.Send(packet);
end

function CommandChangeCalibrationN(valueN)
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.CALIBRATION_N..string.format("%#010d",valueN);
	imhp.Send(packet);
end

function CommandChangeCalibrationD(valueD)
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.CALIBRATION_D..string.format("%#010d",valueD);
	imhp.Send(packet);
end

function CommandChangeOffsetRF(valueOffsetRF)
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.OFFSET_RF..string.format("%#03d",valueOffsetRF);
	imhp.Send(packet);
end

function CommandChangeRSSI(valueRSSI)
	local bRSSI = '1';
	if valueRSSI == 'Off' then
		bRSSI = '0';
	end
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.RSSI_MODE..bRSSI;
	imhp.Send(packet);
end

function CommandChangeDebug(valueDebug)
	local bDebug = '0';
	if valueDebug == 'On' then
		bDebug = '1';
	end
	local packet = imhp.Header.WRITE_CONFIG..'?'..imhp.Config.DEBUG..bDebug;
	imhp.Send(packet);
end

function CommandInspectionModem()
	local packet = 
			imhp.Header.READ_CONFIG..
			'?'..
			imhp.Config.POWER..
			imhp.Config.CHANNEL..
			imhp.Config.DATA_INTERFACE..
			imhp.Config.RSSI_MODE;
	imhp.Send(packet);
end

function CommandInspectionChrono()
	local packet = 
			imhp.Header.READ_CONFIG..
			'?'..
			imhp.Config.ID..
			imhp.Config.DELAY..
			imhp.Config.BUZZER..
			imhp.Config.DEBUG..
			imhp.Config.INDEX_PULSE..
			imhp.Config.CALIBRATION_N..
			imhp.Config.CALIBRATION_D..
			imhp.Config.OFFSET_RF..
			imhp.Config.PRINTER_BAUDRATE..
			imhp.Config.PRODUCT_ID..
			imhp.Config.VERSION;
	imhp.Send(packet);
end

function CommandInspectionClock()
	local packet = 
			imhp.Header.READ_CONFIG..
			'?'..
			imhp.Config.ID..
			imhp.Config.DATE..
			imhp.Config.TIME;
	imhp.Send(packet);
end

function CommandSynchroRF()
	local packet = imhp.Header.SYNCHRO..imhp.Synchro.RF;
	imhp.Send(packet);
end

function CommandSynchroTop(hour, min, sec)
	local packet = imhp.Header.SYNCHRO..imhp.Synchro.TOP..string.format("%#02d%#02d%#02d", hour, min, sec);	
	imhp.Send(packet);
end

function CommandSynchroOut(hour, min, sec)
	local packet = imhp.Header.SYNCHRO..imhp.Synchro.OUT..string.format("%#02d%#02d%#02d", hour, min, sec);	
	imhp.Send(packet);
end

function CommandInitChrono()
	local packet = imhp.Header.WRITE_CONFIG..'?';
	packet = packet..imhp.Config.ID..'M';				-- ID Master
	packet = packet..imhp.Config.DELAY..'001';			-- Delay Rebond 1
	packet = packet..imhp.Config.BUZZER..'004';			-- Delay Buzzer 4
	packet = packet..imhp.Config.DEBUG..'0';			-- Debug 0
	packet = packet..imhp.Config.INDEX_PULSE..'0000';	-- Index Pulse 0000
	packet = packet..imhp.Config.OFFSET_RF..'142';		-- Offset RF 142
	
	imhp.Send(packet);
end

function CommandInitModem()
	local packet = imhp.Header.WRITE_CONFIG..'?';
	packet = packet..imhp.Config.POWER..'5';			-- POWER 5
	packet = packet..imhp.Config.CHANNEL..'03';			-- CHANNEL 3
	packet = packet..imhp.Config.DATA_INTERFACE..'1';	-- DATA_INTERFACE 1
	packet = packet..imhp.Config.RSSI_MODE..'1';		-- RSSI_MODE 1
	imhp.Send(packet);
end
