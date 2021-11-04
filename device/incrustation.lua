dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 3.2, 
		name = 'Incrustation', 
		class = 'display', 
		interface = {} 
	};
end	

bibState = {
	NONE		= '',
	RUNNING		= 'running',
	INTER		= 'inter',
	FINISHED	= 'finished'
};

-- Configuration du Device
function device.OnConfiguration(node)

	local dlg = wnd.CreateDialog({
		icon = "./res/16x16_tools.png",
		label = "Configuration des Incrustations",
		width = 500,
		height = 800
	});
	
	dlg:LoadTemplateXML({ 
		xml = './device/incrustation.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'config'
	});
	
	-- Initialisation des Variables 
	local comboDisplay = dlg:GetWindowName('display');
	for i=0, display.GetCount()-1 do
		local dsp = display.Get(i);
		local txt = tostring(i+1)..' : '..dsp:GetName()..' ('..tostring(dsp:GetSize().width)..'/'..tostring(dsp:GetSize().height)..')';
		comboDisplay:Append(txt);
		dsp:Delete();
	end
	local iDisplay = tonumber(node:GetAttribute('display', '0')) or 0;
	if iDisplay >= 0 and iDisplay < display.GetCount() then
		comboDisplay:SetSelection(iDisplay);
	else
		comboDisplay:SetSelection(0);
	end

	dlg:GetWindowName('fill_color'):SetValue(node:GetAttribute('fill_color', '0,0,0'));
	
	-- Positionnement
	dlg:GetWindowName('width'):SetRange(0, 5000);
	dlg:GetWindowName('width'):SetValue(node:GetAttribute('width', 800));

	dlg:GetWindowName('height'):SetRange(0, 5000);
	dlg:GetWindowName('height'):SetValue(node:GetAttribute('height', 600));
	
	dlg:GetWindowName('x'):SetRange(0, 5000);
	dlg:GetWindowName('x'):SetValue(node:GetAttribute('x', 0));
		
	dlg:GetWindowName('y'):SetRange(0, 5000);
	dlg:GetWindowName('y'):SetValue(node:GetAttribute('y', 0));
	
	-- Scrolling
	dlg:GetWindowName('scroll_count'):SetRange(0, 200);
	dlg:GetWindowName('scroll_count'):SetValue(node:GetAttribute('scroll_count', 8));

	dlg:GetWindowName('scroll_delay'):SetRange(0, 200);
	dlg:GetWindowName('scroll_delay'):SetValue(node:GetAttribute('scroll_delay', 10));

	-- Coureur en Course
	dlg:GetWindowName('running_delay'):SetRange(1, 10);
	dlg:GetWindowName('running_delay'):SetValue(node:GetAttribute('running_delay', 1));

	dlg:GetWindowName('finished_delay'):SetRange(1, 100);
	dlg:GetWindowName('finished_delay'):SetValue(node:GetAttribute('finished_delay', 5));

	dlg:GetWindowName('inter_delay'):SetRange(1, 100);
	dlg:GetWindowName('inter_delay'):SetValue(node:GetAttribute('inter_delay', 4));

	-- Toolbar Principale ...
	local tb = dlg:GetWindowName('tb');
	local btnSave = tb:AddTool("Valider", "./res/32x32_ok.png");
	tb:AddStretchableSpace();
	local btnClose = tb:AddTool("Fermer", "./res/vpe32x32_close.png");
	tb:Realize();

	-- Enregistrement Configuration 
	function OnSaveConfig(evt)
		local txtDisplay = comboDisplay:GetValue();
		local iDisplay = tonumber(string.sub(txtDisplay,1,2))-1 or 0;
		node:ChangeAttribute('display', iDisplay);
	
		node:ChangeAttribute('fill_color', dlg:GetWindowName('fill_color'):GetValue());

		node:ChangeAttribute('width', dlg:GetWindowName('width'):GetValue());
		node:ChangeAttribute('height', dlg:GetWindowName('height'):GetValue());
		node:ChangeAttribute('x', dlg:GetWindowName('x'):GetValue());
		node:ChangeAttribute('y', dlg:GetWindowName('y'):GetValue());

		node:ChangeAttribute('scroll_count', dlg:GetWindowName('scroll_count'):GetValue());
		node:ChangeAttribute('scroll_delay', dlg:GetWindowName('scroll_delay'):GetValue());

		node:ChangeAttribute('running_delay', dlg:GetWindowName('running_delay'):GetValue());
		node:ChangeAttribute('finished_delay', dlg:GetWindowName('finished_delay'):GetValue());
		node:ChangeAttribute('inter_delay', dlg:GetWindowName('inter_delay'):GetValue());

		-- node:ChangeAttribute('region', dlg:GetWindowName('check_region'):GetValue());
		-- node:ChangeAttribute('scale', dlg:GetWindowName('check_scale'):GetValue());

		app.GetXML():SaveFile();
		dlg:EndModal(idButton.OK);
	end

	dlg:Bind(eventType.MENU, OnSaveConfig, btnSave); 
	dlg:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL) end, btnClose);

	-- Lancement de la dialog
	dlg:Fit();
	dlg:ShowModal();

	-- Liberation Memoire
	dlg:Delete();
end

-- Ouverture
function device.OnInit(params)
	
	-- Tableau de Bord
	tbNavigation = wnd.CreateAuiToolBar({ style = auiToolBarStyle.HORIZONTAL });

	local btn_clear = tbNavigation:AddTool("Ecran vide", "./res/32x32_clear.png");
	local btn_startlist = tbNavigation:AddTool("Liste de Départ", "./res/32x32_order.png");
	local btn_ranking = tbNavigation:AddTool("Classement", "./res/32x32_ranking.png");
--	local btn_orderfinish = tbNavigation:AddTool("Ordre d'arrivée", "./res/32x32_competition.png");
	tbNavigation:Realize();

	local mgr = app.GetAuiManager();
	mgr:AddPane(tbNavigation, { toolbarpane=true, direction='top', caption = 'Navigation Incrustation', gripper=true });
	mgr:Update();

	-- Prise des Evenements (Bind)
	tbNavigation:Bind(eventType.MENU, OnModeClear, btn_clear);
	tbNavigation:Bind(eventType.MENU, OnModeStartlist, btn_startlist);
	tbNavigation:Bind(eventType.MENU, OnModeRanking, btn_ranking);
	tbNavigation:Bind(eventType.MENU, OnModeFinish, btn_orderfinish);
	
	-- Prise valeur offset Horloge PC - Horloge Chrono Officiel
	device.offset = 0;
	local rc, offsetInfo = app.SendNotify('<offset_time_load>');
	OnNotifyOffsetTimeSet('<offset_time>', offsetInfo);

	-- Récupération des infos de la course
	local rc, raceInfo = app.SendNotify('<race_load>');
	assert(rc);
	device.raceInfo = raceInfo;
	app.GetAuiMessage():AddLine("Manche ="..device.raceInfo.Code_manche.." / "..device.raceInfo.Nb_inter);

	-- Récupération Ranking
	local rc, data = app.SendNotify('<ranking_load>');
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	device.ranking = data.ranking;
	
	-- Prise Information Coureur ayant le meilleur 
	local rc, best_time = app.SendNotify('<best_time_load>');
	if rc and best_time.bib ~= nil then
		device.best_time = best_time;
	end

	-- Prise des coureurs en course
	local filter = "if Heure_depart_reelle ~= nil and Heure_depart_reelle >= 0 and Heure_arrivee_reelle == nil then return true else return false end ";
	local rc, data = app.SendNotify('<ranking_load>', { filter = filter } );
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	device.bib_running = data.ranking;
	device.bib_running:OrderBy('Heure_depart_reelle Asc');
	
	-- Notify 
	app.BindNotify("<bib_insert>", OnNotifyBibInsert);
	app.BindNotify("<passage_add>", OnNotifyPassageAdd);
	
	app.BindNotify("<bib_delete>", OnNotifyBibDelete);
	app.BindNotify("<bib_time>", OnNotifyBibTime);
	app.BindNotify("<bib_next>", OnNotifyBibNext);
	
	app.BindNotify("<best_time>", OnNotifyBestTime);
	
	app.BindNotify("<offset_time>", OnNotifyOffsetTimeSet);
	app.BindNotify("<run_erase>", OnNotifyRunErased);
	app.BindNotify("<nb_inter>", OnNotifyNbInter);

	-- Params
	local x = tonumber(params.x) or 0;
	local y = tonumber(params.y) or 0;
	local width = tonumber(params.width) or 640;
	local height = tonumber(params.height) or 480;
	local display = tonumber(params.display) or 0;
	
	local bitmap_width = tonumber(params.bitmap_width) or 1920;
	local bitmap_height = tonumber(params.bitmap_height) or 1080;

	-- Creation frame ...
	frame = wnd.CreateFrameEditor({ 
		unit = "pixel", 

		graphics_mode = graphicsMode.MEMORY_DC,
		bitmap_width = bitmap_width,
		bitmap_height = bitmap_height,

		style = wndStyle.FRAME_SHAPED+wndStyle.BORDER_NONE,
		style_report = styleFrameReport.NONE,

		display = display,
		width = width, 
		height = height, 
		x = x, 
		y = y, 
	});

	-- Nom de la Fenêtre pour OBS (open broadcaster software) ou autre ...
	frame:SetName('incrustation');
	frame:SetLabel('incrustation');

	wnd.LoadTemplateReportXML({ 
		xml = './device/incrustation.xml',
		node_name = 'root/report',
		report = frame,
--		layers = { file ='c:/adv/ski/edition/layer.xml', id = 'entry_form' },
	});
	
	editor = frame:GetEditor();
	
	local trans_color = color.BLACK;
	if params.fill_color ~= nil and params.fill_color ~= '' then
		trans_color = color.Create(params.fill_color);
	end
	editor:SetTransparentColor(trans_color);
	
	-- local region = true;
	-- if params.region ~= nil and params.region == '0' then
		-- region = false;
	-- end
	
	-- local scale = true;
	-- if params.scale ~= nil and params.scale == '0' then
		-- scale = false;
	-- end

	tpl = frame:GetTemplate();

	tpl:SetEnvString('mode', 'clear');
	tpl:SetEnvLong('manche', device.raceInfo.Code_manche);
	tpl:SetEnvString('entite', device.raceInfo.tables['Evenement']:GetCell('Code_entite',0));
	
	tpl:SetEnvString('header_row1', device.raceInfo.tables['Evenement']:GetCell('Nom',0));
	tpl:SetEnvString('header_row2', 
		device.raceInfo.tables['Epreuve']:GetCell('Code_activite',0)..' - '..
		device.raceInfo.tables['Epreuve']:GetCell('Code_discipline',0)
	);
	tpl:SetEnvString('header_row3','');

	-- Création Timer ...
	tm = timer.Create(frame);
	running_delay = tonumber(params.running_delay) or 1;
	running_delay = running_delay*100;
	tm:Start(running_delay);
	frame:Bind(eventType.TIMER, OnTimer, tm);
	
	-- Initialisation Etat
	device.state = bibState.NONE;
	
	-- Paramètres Timer ...
	scroll_delay = tonumber(params.scroll_delay) or 10;	-- 10s avant de changer de page
	scroll_count = tonumber(params.scroll_count) or 8;
	scroll_start = 0;
	
	finished_delay = tonumber(params.finished_delay) or 5;	-- Affichage Arrivée pendant 5 Secondes
	finished_delay = finished_delay * 1000;

	inter_delay = tonumber(params.inter_delay) or 4;	-- Affichage Inter pendant 4 Secondes	
	inter_delay = inter_delay * 1000;

	RefreshMode();
end

-- Notification : Changement du nombre de temps inter
function OnNotifyNbInter(key, params)
	assert(key == '<nb_inter>');
	device.raceInfo.Nb_inter = params.nb;
end

-- Notification: Insertion dossard à un point de passage
function OnNotifyBibInsert(key, params)

	assert(key == '<bib_insert>');
	local idPassage = tonumber(params.passage) or -2;
	local bib = tonumber(params.bib) or 0;
	local timePassage = tonumber(params.time) or -1;
	
	if bib > 0 then
		if idPassage == 0 and timePassage >= 0 then
			-- Dossard au Départ : Ok si pas d'heure arrivée 
			BibRunning(bib, timePassage);
		elseif idPassage == -1 then
			-- Dossard a l'arrivée Abs, Abd ...
			if timePassage ~= chrono.DNS then
				BibFinished(bib);
			end
		end
	end
end

-- Notification: Insertion dossard à un point de passage (Mode Temps Net)
function OnNotifyPassageAdd(key, params)
	if app.GetAuiFrame():GetModeChrono() == 'net_time' then

		assert(key == '<passage_add>');

		local idPassage = tonumber(params.passage) or -2;
		local bib = tonumber(params.bib) or 0;
		local timePassage = tonumber(params.time) or -1;

		if bib > 0 then
			if idPassage == 0 and timePassage >= 0 then
				-- Dossard au Départ : Ok si pas d'heure arrivée 
				BibRunning(bib, timePassage);
			elseif idPassage == -1 then
				-- Dossard a l'arrivée Abs, Abd ...
				if timePassage ~= chrono.DNS then
					BibFinished(bib);
				end
			end
		end
	end
end

-- Notification: Suppression dossard à un point de passage
function OnNotifyBibDelete(key, params)
	assert(key == '<bib_delete>');

	local idPassage = tonumber(params.passage) or -2;
	local bib = tonumber(params.bib) or 0;
	
	if bib > 0 then
		if idPassage == 0 then
			-- Suppression d'un dossard au Départ
			BibDelete(bib);
		elseif idPassage == -1 then
			-- Suppression d'un dossard à l'arrivée
			BibRunning(bib);
		end
	end
end

-- Notification : Temps Net à l'arrivée ou aux Intermédiaires ... 
function OnNotifyBibTime(key, params)
	assert(key == '<bib_time>');
	local idPassage = tonumber(params.passage) or -2;
	local bib = tonumber(params.bib) or 0;
	local time_net = tonumber(params.total_time) or -1;
	local rank = params.total_rank;
	local diff = params.total_diff;
	
	if idPassage == -1 then 
		-- Finish ...
		if time_net ~= chrono.DNS then
			-- Uniquement des Temps OK ou ABD ...
			BibFinished(bib, time_net, rank, diff);
			RefreshState(bibState.FINISHED);
			
			ReloadRanking();
			RefreshMode();
		end
	elseif idPassage >= 1 then
		-- Inter 1, 2 ...
		BibInter(bib, idPassage, time_net, rank, diff);
	end
end

-- Notification : Nouveau Meilleur Temps
function OnNotifyBestTime(key, params)
	assert(key == '<best_time>');
	device.best_time = params;
end

-- Notification : Prochain dossard au départ 
function OnNotifyBibNext(key, params)
	assert(key == '<bib_next>');
	local bib_next = tonumber(params.bib) or 0;
	if bib_next > 0 then
		device.bib_next = device.BibLoad(bib_next);
	end
end

-- Notification : Effacement de la Manche
function OnNotifyRunErased(key, params)
	device.bib_running:RemoveAllRows();
	device.best_time = {};
	
	RefreshState(bibState.NONE);

	ReloadRanking();
	RefreshMode();
end

-- Notification : OnNotifyOffsetTimeSet
function OnNotifyOffsetTimeSet(key, params)
	assert(key == '<offset_time>');

	if type(params) == 'table' and type(params.offset) == 'number' then
		device.offset = tonumber(params.offset);
		adv.Alert('<offset_time> : '..device.offset);
	end
end

-- retourne la chaine du meilleur temps à l'arrivée
function GetBestTime()
	if device.best_time ~= nil and device.best_time.ranking ~= nil and device.best_time.ranking:GetNbRows() == 1 then
		if device.raceInfo.Code_manche == 1 then
			return device.best_time.ranking:GetCell("Tps1", 0);
		else
			return device.best_time.ranking:GetCell("Tps", 0);
		end
	else
		return '???';
	end
end

-- retourne la chaine du temps Inter n°inter du meilleur
function GetBestTimeInter(inter)
	if inter >= 1 and device.best_time ~= nil and device.best_time.ranking ~= nil and device.best_time.ranking:GetNbRows() == 1 then
		return device.best_time.ranking:GetCell("Tps_cumul"..device.raceInfo.Code_manche..'_inter'..inter, 0);
	else
		return '???';
	end
end

-- retourne le dernier Temps de Passage ok ou -2
function GetLastCurrentPassage()
	if device.bib_running:GetNbRows() == 0 then
		-- Aucun coureur en course
		return -2;
	end

	-- Test Temps à l'arrivée
	if device.raceInfo.Code_manche == 1 then
		if device.bib_running:GetCellInt("Tps1", 0) > 0 then return -1 end
	else
		if device.bib_running:GetCellInt("Tps", 0) > 0 then return -1 end
	end
		
	-- Pas de Temps à l'Arrivée => On regarde les temps inter
	for i=device.raceInfo.Nb_inter, 1, -1 do
		if device.bib_running:GetCellInt('Tps_cumul'..device.raceInfo.Code_manche..'_inter'..i, 0) > 0 then
			return i;
		end
	end
	
	return -2;
	
end

-- Affichage 
function RefreshState(state)

	if tpl:GetEnvString('mode') ~= 'ranking' then return end

	-- Gestion des prioriés
	if device.state == bibState.FINISHED then return end;
	if device.state == bibState.INTER and state ~=  bibState.FINISHED then return end;

	if state == bibState.RUNNING and device.bib_running:GetNbRows() == 0 then
		device.state = bibState.NONE;
	else
		device.state = state;
	end
	
	local editor = frame:GetEditor();
	local tpl = editor:GetTemplate();
	
	tpl:SetEnvString('state', device.state);
	tpl:SetEnvString('bib', '');
	tpl:SetEnvString('identity', '');
	
	if device.state == bibState.FINISHED then
		tpl:SetEnvString('time', '');
		tpl:SetEnvString('rank', '');
		tpl:SetEnvString('diff', '');
		if device.bib_finished:GetNbRows() > 0 then
			tpl:SetEnvString('bib', device.bib_finished:GetCell("Dossard",0));
			tpl:SetEnvString('identity', device.bib_finished:GetCell("Identite",0));
			tpl:SetEnvString('time', device.bib_finished:GetCell('Tps', 0));
			tpl:SetEnvString('rank', device.bib_finished:GetCell('Clt', 0));
			tpl:SetEnvString('diff', device.bib_finished:GetCell('Diff', 0));
		end
	else
		tpl:SetEnvString('diff_inter', '');
		tpl:SetEnvString('time_inter', '');
		if device.bib_running:GetNbRows() > 0 then
			tpl:SetEnvString('bib', device.bib_running:GetCell("Dossard",0));
			tpl:SetEnvString('identity', device.bib_running:GetCell("Identite",0));
			tpl:SetEnvString('time_inter', device.bib_running:GetCell("Tps_inter",0));
			tpl:SetEnvString('diff_inter', device.bib_running:GetCell("Diff_inter",0));
		end
	end
	
	-- Prise en compte best_total_time ...
	tpl:SetEnvLong('best_total_time', 0);
	if device.best_time ~= nil and device.best_time.total_time ~= nil then
		tpl:SetEnvLong('best_total_time', device.best_time.total_time);
	end

	if device.best_time ~= nil and device.best_time.ranking ~= nil and device.best_time.ranking:GetNbRows() > 0 then
		tpl:SetEnvString('best_time_identity', device.best_time.ranking:GetCell('Identite', 0));
	end
	
	-- Prise en compte best_time_passage
	tpl:SetEnvString('best_time_passage', '');
	if device.best_time ~= nil and device.best_time.ranking ~= nil and device.best_time.ranking:GetNbRows() > 0 and device.bib_running:GetNbRows() > 0 then
		if device.raceInfo.Nb_inter > 0 then
			if device.state == bibState.RUNNING then
				local lastPassage = GetLastCurrentPassage();
				if lastPassage == device.raceInfo.Nb_inter or lastPassage == -1 then
					tpl:SetEnvString('best_time_passage', GetBestTime());
				elseif lastPassage >= 1 then 
					tpl:SetEnvString('best_time_passage', GetBestTimeInter(lastPassage+1));
				else
					tpl:SetEnvString('best_time_passage', GetBestTimeInter(1));
				end
			elseif device.state == bibState.INTER then
				local lastPassage = GetLastCurrentPassage();
				if lastPassage >= 1 then
					tpl:SetEnvString('best_time_passage', GetBestTimeInter(lastPassage));
				end
			elseif device.state == bibState.FINISHED then
				tpl:SetEnvString('best_time_passage', GetBestTime());
			end
		else
			-- Aucun Temps Inter => Meilleur à l'arrivée
			tpl:SetEnvString('best_time_passage', GetBestTime());
		end
	end
	
	RefreshAll();
end

function RefreshAll()

	editor:ResetMemoryDC();
	tpl:Reset();

	tpl:Reload("nodeFooter");
	tpl:Reload("nodeHeader");
	tpl:Reload("nodeBody");
			
	editor:DrawMemoryDC();
	editor:ShowMemoryDC();

--	editor:RemoveObjectByGroup('footer');
--	tpl:RemoveObjName('running_time_img');
--	tpl:RemoveObjName('running_time_txt');
--	tpl:Reload("nodeFooter");

--	editor:DrawMemoryDC();
--	editor:ShowMemoryDC();
end

-- Chargement des informations lié au dossard
function device.BibLoad(bib)
	local rc, bibLoad = app.SendNotify("<bib_load>", { bib = bib });
	if rc and type(bibLoad) == 'table' then
		return bibLoad.ranking;
	else
		return nil;
	end
end

-- Retourne le dossard en course le plus proche de l'arrivée (=> Heure de départ réelle la plus petite ...)
function GetCurrentBib()
	if device.bib_running:GetNbRows() > 0 then
		return device.bib_running:GetCell("Dossard",0);
	else
		return nil;
	end
end

-- Prise en compte d'un nouveau dossard en course
function BibRunning(bib, timePassage)
	local row = device.bib_running:GetIndexRow('Dossard', bib) or -1;
	if row < 0 then
		local bibRanking = device.BibLoad(bib);
		if bibRanking ~= nil then
			local previousBib = GetCurrentBib();
			
			if timePassage ~= nil then
				bibRanking:SetCell('Heure_depart_reelle', 0, timePassage);
			end
			
			device.bib_running:AddRow(bibRanking, true);
			device.bib_running:OrderBy('Heure_depart_reelle Asc');
		
			local currentBib = GetCurrentBib();
			
			if previousBib ~= currentBib and currentBib ~= nil then
				RefreshState(bibState.RUNNING);
			end
		end
	end
end

-- Suppression d'un dossard en course
function BibDelete(bib)
	local row = device.bib_running:GetIndexRow('Dossard', bib) or -1;
	if row >= 0 then
		local previousBib = GetCurrentBib();
		device.bib_running:RemoveRowAt(row);
		local currentBib = GetCurrentBib();
	
		if previousBib ~= currentBib then
			RefreshState(bibState.RUNNING);
		end
	end
end

function BibFinished(bib, time_net, rank, diff)
	local row = device.bib_running:GetIndexRow('Dossard', bib) or -1;
	if row >= 0 then
		device.bib_finished = adv.Filter(device.bib_running, function(t,row) return tonumber(t:GetCell('Dossard',row)) == bib end);
		assert(device.bib_finished:GetCell("Dossard",0) == tostring(bib));
		device.bib_running:RemoveRowAt(row);
	else
		device.bib_finished = device.BibLoad(bib);
	end
	
	if device.bib_finished ~= nil and device.bib_finished:GetNbRows() > 0 and time_net ~= nil then
		device.bib_finished:SetCell('Tps', 0, time_net);
		device.bib_finished:SetCell('Clt', 0, rank);
		device.bib_finished:SetCell('Diff', 0, diff);
	end
end

function BibInter(bib, idPassage, time_net, rank, diff)
	assert(idPassage >= 1);
	local row = device.bib_running:GetIndexRow('Dossard', bib) or -1;
	if row >= 0 then
		device.bib_running:SetCell('Tps_inter', row, time_net);
		device.bib_running:SetCell('Clt_inter', row, rank);
		device.bib_running:SetCell('Diff_inter', row, diff);

		device.bib_running:SetCell('Tps_cumul'..device.raceInfo.Code_manche..'_inter'..idPassage, row, time_net);
		device.bib_running:SetCell('Clt_cumul'..device.raceInfo.Code_manche..'_inter'..idPassage, row, rank);
		device.bib_running:SetCell('Diff_cumul'..device.raceInfo.Code_manche..'_inter'..idPassage, row, diff);
				
		if row == 0 then
			RefreshState(bibState.INTER);
		end
	end
end

-- Fermeture
function device.OnClose()
	if tm ~= nil then
		tm:Delete();
	end
	-- if tBody ~= nil then
		-- tBody:Delete();
	-- end
	if frame ~= nil then
		frame:Close();
	end
	if tbNavigation ~= nil then
		app.GetAuiManager():DeletePane(tbNavigation);
	end
end

-- Evenement Timer 
function OnTimer(evt)
	if tpl:GetEnvString('mode') == 'ranking' then
		if device.state == bibState.NONE or device.state == bibState.RUNNING then
			device.state = bibState.NONE;
			if device.bib_running ~= nil then
				if device.bib_running:GetNbRows() > 0 then
					device.state = bibState.RUNNING;

					local objRunningTimeTxt = tpl:GetObjName('running_time_txt');
					if objRunningTimeTxt == nil then
						RefreshMode();
					end
					
					if objRunningTimeTxt ~= nil then
						local timeStart = device.bib_running:GetCellInt("Heure_depart_reelle", 0);
						local timeCurrent = app.Now() + device.offset;
						
						if timeCurrent >= timeStart and timeStart >= 0 then
							local timeRunning = timeCurrent-timeStart;
							if device.raceInfo.Code_manche > 1 then
								timeRunning = timeRunning + device.bib_running:GetCellInt("Tps1", 0, 0);
							end
							local stringTime = app.TimeToString(math.floor((timeRunning)/100)*100, '[P10]%-1h%-1m%2s.%1f');

							local objRunningTimeImg = tpl:GetObjName('running_time_img');
							if objRunningTimeImg ~= nil then
								editor:DrawObjMemoryDC(objRunningTimeImg, false);
							end
							objRunningTimeTxt:SetText(stringTime);
							editor:DrawObjMemoryDC(objRunningTimeTxt, true);
						end
					end
				end
			end
		elseif device.state == bibState.FINISHED then
			device.bib_finished_start = device.bib_finished_start or app.Now();
			if app.Now() > device.bib_finished_start + finished_delay then
				device.bib_finished_start = nil;
				device.state = nil;
				RefreshState(bibState.RUNNING);
			end
		elseif device.state == bibState.INTER then
			device.bib_inter_start = device.bib_inter_start or app.Now();
			if app.Now() > device.bib_inter_start + inter_delay then
				device.bib_inter_start = nil;
				device.state = bibState.NONE;
				RefreshState(bibState.RUNNING);
			end
		end
	end
	
	internalCountDelayScroll = internalCountDelayScroll or 0;
	scroll_delay = scroll_delay or 10;
	
	if scroll_delay > 0 then
		if internalCountDelayScroll > scroll_delay*10 then
			OnPageDown();
			internalCountDelayScroll = 0;
		else
			internalCountDelayScroll = internalCountDelayScroll+1;
		end
	end
end

function OnModeClear()
	tpl:SetEnvString('mode', 'clear');
	RefreshMode();
end

function OnModeStartlist()
	tpl:SetEnvString('mode', 'startlist');
	scroll_start = 0;
	
	-- Récupération Ranking
	local rc, data = app.SendNotify('<ranking_load>');
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	device.ranking = data.ranking;

	RefreshMode();
end

function OnModeRanking()
	tpl:SetEnvString('mode', 'ranking');

	ReloadRanking();
	scroll_start = 0;
	RefreshMode();
end

function ReloadRanking()
	local filter = '';
	if device.raceInfo.Code_manche == 1 then
		filter = "if Tps1 ~= nil and (Tps1 > 0 or Tps1 == -500 or Tps1 == -800) then return true else return false end ";
	else
		filter = "if Tps ~= nil and (Tps > 0 or Tps == -500 or Tps == -800) then return true else return false end ";
	end
	local rc, data = app.SendNotify('<ranking_load>', { filter = filter } );
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	device.ranking = data.ranking;
end

	
function OnModeFinish()
	tpl:SetEnvString('mode', 'finish');

	-- Récupération Ranking
	local filter = "if Heure_arrivee_reelle ~= nil and Heure_arrivee_reelle > 0 then return true else return false end ";
	local rc, data = app.SendNotify('<ranking_load>', { filter = filter } );
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	device.ranking = data.ranking;

	RefreshMode();
end

function OnPageDown()
	if device.ranking ~= nil then
		scroll_count = scroll_count or 8;
		scroll_start = scroll_start or 0;
	
		local nbRows = device.ranking:GetNbRows();
		if scroll_start + scroll_count < nbRows then
			scroll_start = scroll_start + scroll_count;
		else
			scroll_start = 0;
		end
		DrawScroll();
	end
end

function DrawScroll()
	scroll_count = scroll_count or 8;
	scroll_start = scroll_start or 0;
	
	if device.ranking ~= nil then
		-- tBody = tBody or nil;
		-- if tBody ~= nil then
			-- tBody:Delete();
		-- end

		tBody = device.ranking:FilterRows(scroll_start,scroll_start+scroll_count-1);
		tpl:SetEnvUserDataTable('body', tBody);
	end

	-- Ré-Affichage Total ...
	RefreshAll();
end

function RefreshMode()
	local mode = tpl:GetEnvString('mode');

	-- Tri ...
	if mode == 'startlist' then
		-- Liste de Départ 
		if device.raceInfo.Code_manche == 1 then
			device.ranking:OrderBy('Dossard');
			tpl:SetEnvString('header_row3', 'Liste de Départ Manche 1');
		else
			device.ranking:OrderBy('Rang2, Dossard');
			tpl:SetEnvString('header_row3', 'Liste de Départ Manche 2');
		end
	elseif mode == 'ranking' then
		-- Résultat
		if device.raceInfo.Code_manche == 1 then
			device.ranking:OrderBy('Clt1, Dossard');
			tpl:SetEnvString('header_row3', 'Résultat Manche 1');
		else
			device.ranking:OrderBy('Clt, Dossard');
			tpl:SetEnvString('header_row3', 'Résultat');
		end
		tpl:SetEnvString('state', device.state);
		RefreshState(device.state);
	elseif mode == 'finish' then
		-- Ordre Arrivée
		device.ranking:OrderBy("Heure_arrivee_reelle DESC")
		tpl:SetEnvString('header_row3', 'Ordre d\'arrivée');
	end

	local sizeTotal = editor:ResizeMemoryDC(scroll_count);
--	app.GetAuiMessage():AddLine('Size Memory DC='..tostring(sizeTotal.width)..' / '..tostring(sizeTotal.height));

	scroll_start = 0;
	DrawScroll();
end