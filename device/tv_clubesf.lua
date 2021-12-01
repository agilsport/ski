dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 4.5, name = 'TV Club ESF', class = 'display', interface = {} };
end	

-- Ouverture
function device.OnInit(params)

	-- Connexion Base MySQL "tv"
	device.dbTV = sqlBase.ConnectMySQL('localhost', 'tv', 'root', '', 3306);
	if device.dbTV == nil then
		-- Creation Base TV
		local base = sqlBase.Clone();
		base:Query("CREATE DATABASE tv");
		base:Delete();
		
		device.dbTV = sqlBase.ConnectMySQL('localhost', 'tv', 'root', '', 3306);
		if device.dbTV == nil then
			adv.Error("Erreur Connexion Base TV");
			return;
		end
		-- Creation des Tables 
		if device.dbTV:ScriptSQL('./process/base_tv.sql') == true then
			adv.Success("Creation Base TV OK");
		else
			adv.Error("Erreur Connexion Base TV");
			return;
		end
	end
	device.dbTV:Load();
	device.dbTV:Query("Replace Into Running (ID) Values (1)");
	
	-- Tableau de Bord
	tbNavigation = wnd.CreateAuiToolBar({ style = auiToolBarStyle.HORIZONTAL });

	local btn_clear = tbNavigation:AddTool("Ecran vide", "./res/32x32_clear.png");
	local btn_startlist = tbNavigation:AddTool("Liste de Départ", "./res/32x32_order.png");
	local btn_ranking = tbNavigation:AddTool("Classement", "./res/32x32_ranking.png");
	local btn_ranking_last = tbNavigation:AddTool("Par ordre d'arrivée", "./res/32x32_competition.png");

	tbNavigation:AddSeparator();
	modeLabel = wnd.CreateStaticText({parent = tbNavigation, label = "Mode StartList" });
	tbNavigation:AddControl(modeLabel);
	tbNavigation:Realize();

	local mgr = app.GetAuiManager();
	mgr:AddPane(tbNavigation, { toolbarpane=true, direction='top', caption = 'TV Liste', gripper=true });
	mgr:Update();

	-- Prise des Evenements (Bind)
	tbNavigation:Bind(eventType.MENU, OnModeClear, btn_clear);
	tbNavigation:Bind(eventType.MENU, OnModeStartlist, btn_startlist);
	tbNavigation:Bind(eventType.MENU, 
		function(evt)
			device.mode_last = false;
			device.mode_last = false;
			device.tm_running:Start(100);		
			OnModeRanking();
		end
		, btn_ranking);
	tbNavigation:Bind(eventType.MENU, 
		function(evt)
			device.mode_last = true;
			device.tm_running:Start(100);		
			OnModeRanking();
		end
		, btn_ranking_last);

	-- Prise valeur offset Horloge PC - Horloge Chrono Officielle
	local rc, offsetInfo = app.SendNotify('<offset_time_load>');
	assert(rc);
	device.offset = tonumber(offsetInfo.offset);

	-- Récupération des infos de la course
	local rc, raceInfo = app.SendNotify('<race_load>');
	assert(rc);
	device.raceInfo = raceInfo;
	app.GetAuiMessage():AddLine("Manche = "..device.raceInfo.Code_manche.." / Inter = "..device.raceInfo.Nb_inter);

	columnInfoRanking = 'Medaille1';
	columnInfoStartlist = 'Equipe';
	local tEpreuve = device.raceInfo.tables.Epreuve;
		
	-- Prise Information Coureur ayant le meilleur 
	local rc, best_time = app.SendNotify('<best_time_load>');
	device.OnNotifyBestTime('<best_time>', best_time);

	-- Prise des coureurs en course
	local filter = "if Heure_depart_reelle ~= nil and Heure_depart_reelle >= 0 and Heure_arrivee_reelle == nil then return true else return false end ";
	local rc, data = app.SendNotify('<ranking_load>', { filter = filter } );
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	device.bib_running = data.ranking;
	device.bib_running:OrderBy('Heure_depart_reelle Asc');

	-- Récupération Ranking
	local rc, data = app.SendNotify('<ranking_load>');
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	device.ranking = data.ranking;
	
	-- Création des Timer attaché à la frame ...
	local mainframe = app.GetAuiFrame();

	device.tm_running = timer.Create(mainframe);
	mainframe:Bind(eventType.TIMER, OnTimerRunning, device.tm_running);
	device.tm_running:Start(100);		

	device.tick_passage = -1;
	device.tick_passage_delay = 8000;

	app.BindNotify("<bib_next>", device.OnNotifyBibNext);
	app.BindNotify("<bib_insert>", device.OnNotifyBibInsert);
	app.BindNotify("<bib_delete>", device.OnNotifyBibDelete);
	app.BindNotify("<bib_time>", device.OnNotifyBibTime);
	app.BindNotify("<passage_add>", device.OnNotifyPassageAdd);

	-- Mode Classique ...
	app.BindNotify("<best_time>", device.OnNotifyBestTime);

	app.BindNotify("<offset_time>", device.OnNotifyOffsetTimeSet);
	app.BindNotify("<run_erase>", device.OnNotifyRunErased);
	app.BindNotify("<nb_inter>", device.OnNotifyNbInter);

	-- Mode Ranking par défaut ...
	OnModeRanking();

	-- Dossard au départ
	device.DoBibNext();
end

-- Notification <passage_add> : Chrono Classique 
function device.OnNotifyPassageAdd(key, params)
	-- Mode Classique ...
	assert(key == '<passage_add>');

	local bib = tonumber(params.bib) or 0;
	if bib > 0 then
		local idPassage = tonumber(params.passage) or -2;
		local timePassage = tonumber(params.time) or -1;

		if idPassage == 0 and timePassage > 0 then -- Depart
			device.BibRunning(bib, timePassage);
		elseif idPassage == -1 then	-- Arrivée
			if timePassage == chrono.DNF or timePassage == chrono.DSQ then
				device.BibFinished(bib,timePassage, '', '');
			end
		end
	end
end

function device.DoBibNext()
	local rc, bibNext = app.SendNotify("<bib_next_load>");
	if rc and type(bibNext) == 'table' then
		device.OnNotifyBibNext('<bib_next>', { bib = bibNext.bib, passage = 0});
	end
end 

-- Notification : Next Bib 
function device.OnNotifyBibNext(key, params)
	assert(key == '<bib_next>');

	-- si il existe un coureur en course avec un temps < 10s c'est lui le bib next !
	for row=0, 	device.bib_running:GetNbRows()-1 do
		local timeStart = device.bib_running:GetCellInt("Heure_depart_reelle", row);
		local timeCurrent = app.Now() + device.offset;
		if timeCurrent >= timeStart and timeStart >= 0 then
			local timeRunning = timeCurrent-timeStart;
			if device.raceInfo.Code_manche > 1 then
				timeRunning = timeRunning + device.bib_running:GetCellInt("Tps1", 0, 0);
			end
			if timeRunning <= 10000 then
				local cmd = 
				"Update Next Set Tick = '"..app.GetTickCount().."' "..
				",State = 'O' "..
				",Bib = '"..device.bib_running:GetCell("Dossard", row).."' "..
				",Identity = '"..string.gsub(device.bib_running:GetCell("Identite", row), "'", "''").."' "..
				",Team = '"..string.gsub(device.bib_running:GetCell(columnInfoStartlist, row),"'","''").."' ";
				device.dbTV:Query(cmd);
				return;
			end
		end
	end
	
	local passage = tonumber(params.passage) or -2;
	local bib = tonumber(params.bib) or 0;
	local columnInfoStartlist = columnInfoStartlist or 'Club'
	
	if passage == 0 and bib > 0 then
		local bibNext = device.BibLoad(bib);
		if bibNext ~= nil then
		
			local time1Ms = '-1';
			if device.raceInfo.Code_manche > 1 then
				-- Pour l'écart au Départ par rapport au Leader Actuel ...on a besoin du Temps réalisé en M1 ...
				time1Ms = bibNext:GetCellInt("Tps1", 0, -1);
			end

			local cmd = 
			"Update Next Set Tick = '"..app.GetTickCount().."' "..
			",State = 'O' "..
			",Bib = '"..bibNext:GetCell("Dossard", 0).."' "..
			",Identity = '"..string.gsub(bibNext:GetCell("Identite", 0), "'", "''").."' "..
			",Team = '"..string.gsub(bibNext:GetCell(columnInfoStartlist, 0),"'","''").."' "..
			",Time1Ms = "..tostring(time1Ms).." ";
		
			device.dbTV:Query(cmd);
		end
	end
end

-- Notification : Insertion dossard à un point de passage
function device.OnNotifyBibInsert(key, params)
	assert(key == '<bib_insert>');

	local idPassage = tonumber(params.passage) or -2;
	local bib = tonumber(params.bib) or 0;
	local timePassage = tonumber(params.time) or -1;
	
	if bib > 0 then
		if idPassage == 0 and timePassage >= 0 then
			-- Dossard au Départ : Ok si pas d'heure arrivée 
			device.BibRunning(bib, timePassage);
		elseif idPassage == -1 then
			-- Dossard a l'arrivée Abs , Abd ...
			device.BibFinished(bib);
		end
	end
end

-- Notification: Suppression dossard à un point de passage
function device.OnNotifyBibDelete(key, params)
	assert(key == '<bib_delete>');

	local idPassage = tonumber(params.passage) or -2;
	local bib = tonumber(params.bib) or 0;
	
	if bib > 0 then
		if idPassage == 0 then
			-- Suppression d'un dossard au Départ
			device.BibDelete(bib);
		elseif idPassage == -1 then
			-- Suppression d'un dossard à l'arrivée
			device.BibRunning(bib);
		end
	end
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

-- Prise en compte d'un nouveau dossard en course
function device.BibRunning(bib, timeStart)
	local row = device.bib_running:GetIndexRow('Dossard', bib) or -1;
	if row < 0 then
		local bibRanking = device.BibLoad(bib);
		if bibRanking ~= nil then
			
			timeStart = timeStart or -1;
			if timeStart > 0 then
				bibRanking:SetCell('Heure_depart_reelle',0,timeStart);
			end

			device.bib_running:AddRow(bibRanking, true);
			device.bib_running:OrderBy('Heure_depart_reelle Asc');
			SetBibRunning();
		end
	end
end

function SetBibRunning()
	if device.bib_running:GetNbRows() > 0 and device.tick_passage < 0 then

		local columnInfoStartlist = columnInfoStartlist or 'Club';
		
		-- Calcul Temps de Course actuel  
		local timeMs = 0;
		local timeStart = device.bib_running:GetCellInt("Heure_depart_reelle", 0);
		local timeCurrent = app.Now() + device.offset;
		if timeCurrent >= timeStart and timeStart >= 0 then
			timeMs = timeCurrent-timeStart;
		end
		
		-- Prise dernier point de passage
		local passage = 0;
		local bib = device.bib_running:GetCell("Dossard", 0);
		local rc, bibLoad = app.SendNotify("<bib_load>", { bib = bib });
		if rc and type(bibLoad) == 'table' then
			if 	bibLoad.passage ~= nil then
				local tPassageBib = bibLoad.passage;
				if tPassageBib:GetNbRows() > 0 then
					tPassageBib:OrderBy('Id Asc');
					if tPassageBib:GetCellInt('Id', 0) == -1 then
						passage = -1; -- Arrivée ...
					else
						passage = tPassageBib:GetCellInt('Id', tPassageBib:GetNbRows()-1);
					end
				end
			end
		end

		local cmd = 
		"Update Running Set Tick = '"..app.GetTickCount().."'"..
		",State = 'R'"..
		",Bib = '"..bib.."' "..
		",Identity = '"..string.gsub(device.bib_running:GetCell("Identite", 0), "'", "''").."' "..
		",Team = '"..string.gsub(device.bib_running:GetCell(columnInfoStartlist, 0),"'","''").."' "..
		",TimeMs = "..timeMs..
		",Passage = "..passage;
		device.dbTV:Query(cmd);
--		adv.Alert('SetBibRunning:'..cmd);
	elseif device.bib_running:GetNbRows() == 0 then
		-- Plus aucun concurrent en course ...
		device.dbTV:Query("Update Running Set State = 'C'");
	end
end

function device.OnNotifyBibTime(key, params)

	-- for k,v in pairs(params) do
		-- adv.Alert('Key '..k..'='..tostring(v));
	-- end
	
	local idPassage = tonumber(params.passage) or -2;
	local bib = tonumber(params.bib) or 0;
	local time_net = tonumber(params.total_time) or -1;
	local rank = params.total_rank;
	local diff = params.total_diff;
	
	if idPassage == -1 then 
		-- Finish ...
		device.BibFinished(bib, time_net, rank, diff);
	elseif idPassage >= 1 then
		-- Inter 1, 2 ...
		if time_net ~= chrono.DNS then
			device.BibInter(bib, idPassage, time_net, rank, diff);
		end
	end

	-- MAJ Dossard Suivant
	device.DoBibNext();
	
	if device.mode ~= 'startlist' then
		-- Prise des coureurs arrivés ou Abd ou Dsq
		local filter = '';
		if device.raceInfo.Code_manche == 1 then
			if device.mode_last == false then
				filter = "if Tps1 ~= nil and (Tps1 > 0 or Tps1 == -500 or Tps1 == -800) then return true else return false end ";
			else
				filter = "if Tps1 ~= nil and Tps1 > 0 then return true else return false end ";
			end
		else
			if device.mode_last == false then
				filter = "if Tps ~= nil and (Tps > 0 or Tps == -500 or Tps == -800) then return true else return false end ";
			else
				filter = "if Tps ~= nil and Tps > 0 then return true else return false end ";
			end
		end

		local rc, data = app.SendNotify('<ranking_load>', { filter = filter } );
		assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
		device.ranking = data.ranking;
		if device.mode_last == true then
			device.ranking:OrderBy('Heure_arrivee_reelle DESC');
			for row = device.ranking:GetNbRows() -1, 12, -1 do
				device.ranking:RemoveRowAt(row);
			end
		end
	end

	RefreshMode();
end

-- Suppression d'un dossard en course
function device.BibDelete(bib)
	local row = device.bib_running:GetIndexRow('Dossard', bib) or -1;
	if row >= 0 then
		device.bib_running:RemoveRowAt(row);
		SetBibRunning();
	end
end

function device.BibFinished(bib, time_net, rank, diff)

	if time_net == nil or time_net == chrono.DNS or time_net == chrono.KO or time_net == chrono.ZERO then return end 

	local row = device.bib_running:GetIndexRow('Dossard', bib) or -1;
	local bibInfo = nil;
	if row >= 0 then
		bibInfo = adv.Filter(device.bib_running, function(t,row) return tonumber(t:GetCell('Dossard',row)) == bib end);
		assert(bibInfo:GetCell("Dossard",0) == tostring(bib));
		device.bib_running:RemoveRowAt(row);
	else
		bibInfo = device.BibLoad(bib);
	end

	if bibInfo ~= nil and bibInfo:GetNbRows() > 0 then
		device.tick_passage = app.GetTickCount();
		device.tick_passage_delay = 8000;

		rank = rank or '';

		diff = diff or '';
		if type(diff) == 'number' then
			diff = app.TimeToString(diff, '[DIFF]%xs.%2f');
		end

		columnInfoRanking = columnInfoRanking or 'Equipe';
		
		local cmd = 
			"Update Running Set State = 'F' "..
			",Tick = '"..app.GetTickCount().."' "..
			",Bib = '"..bibInfo:GetCell("Dossard", 0).."' "..
			",Identity = '"..string.gsub(bibInfo:GetCell("Identite", 0), "'", "''").."' "..
			",Team = '"..string.gsub(bibInfo:GetCell(columnInfoRanking, 0),"'","''").."' "..
			",Time = '"..app.TimeToString(time_net).."' "..
			",TimeMs = "..time_net.." "..
			",Passage = -1 "..
			",Rank = '"..tostring(rank).."' "..
			",Diff = '"..diff.."' ";
--		adv.Alert(cmd);
		device.dbTV:Query(cmd);
	end
end

function device.BibInter(bib, idPassage, time_net, rank, diff)
	if time_net == nil or time_net == chrono.DNS or time_net == chrono.KO or time_net == chrono.ZERO then return end 

	local row = device.bib_running:GetIndexRow('Dossard', bib) or -1;
	local bibInfo = nil;
	if row ~= 0 then
		return;
	end

	-- Uniquement le premier Coureur en course
	bibInfo = adv.Filter(device.bib_running, function(t,row) return tonumber(t:GetCell('Dossard',row)) == bib end);
	assert(bibInfo:GetCell("Dossard",0) == tostring(bib));

	if bibInfo ~= nil and bibInfo:GetNbRows() > 0 then
		device.tick_passage = app.GetTickCount();
		device.tick_passage_delay = 3000;

		rank = rank or '';

		diff = diff or '';
		if type(diff) == 'number' then
			diff = app.TimeToString(diff, '[DIFF]%xs.%2f');
		end

		columnInfoRanking = columnInfoRanking or 'Equipe';

		local cmd = 
			"Update Running Set State = '"..tostring(idPassage).."' "..
			",Tick = '"..app.GetTickCount().."' "..
			",Bib = '"..bibInfo:GetCell("Dossard", 0).."' "..
			",Identity = '"..string.gsub(bibInfo:GetCell("Identite", 0), "'", "''").."' "..
			",Team = '"..string.gsub(bibInfo:GetCell(columnInfoRanking, 0),"'","''").."' "..
			",Time = '"..app.TimeToString(time_net).."' "..
			",TimeMs = "..time_net.." "..
			",Passage = "..idPassage.." "..
			",Rank = '"..tostring(rank).."' "..
			",Diff = '"..diff.."' ";
		device.dbTV:Query(cmd);
--		adv.Alert('Bib Inter:'..cmd);
	end
end

-- Notification : Nouveau Meilleur Temps
function device.OnNotifyBestTime(key, params)
	assert(key == '<best_time>');

	local txtManche = tostring(device.raceInfo.Code_manche);

	if params ~= nil and params.ranking ~= nil and params.ranking:GetNbRows() == 1 then
		local identity = params.ranking:GetCell("Prenom", 0):sub(1,1)..'.'..params.ranking:GetCell("Nom", 0);
		identity = string.gsub(identity, "'", "''");
		
		local time_inter1 = params.ranking:GetCellInt("Tps_cumul"..txtManche.."_inter1", 0, -1);
		local time_inter2 = params.ranking:GetCellInt("Tps_cumul"..txtManche.."_inter2", 0, -1);
		local time_inter3 = params.ranking:GetCellInt("Tps_cumul"..txtManche.."_inter3", 0, -1);
		local time_inter4 = params.ranking:GetCellInt("Tps_cumul"..txtManche.."_inter4", 0, -1);

		local cmd = 
			"Update Context Set Best_identity = '"..identity.."' "..
			",Best_time = '"..app.TimeToString(params.total_time).."' "..
			",Best_time1 = '"..app.TimeToString(time_inter1).."' "..
			",Best_time2 = '"..app.TimeToString(time_inter2).."' "..
			",Best_time3 = '"..app.TimeToString(time_inter3).."' "..
			",Best_time4 = '"..app.TimeToString(time_inter4).."' "..
	
			",Best_timeMs = "..params.total_time..
			",Best_time1Ms = "..time_inter1..
			",Best_time2Ms = "..time_inter2..
			",Best_time3Ms = "..time_inter3..
			",Best_time4Ms = "..time_inter4..

			",Nb_inter = "..device.raceInfo.Nb_inter.." "..
			",Manche = "..txtManche.." "..
			",Time1Ms = "..params.ranking:GetCellInt("Tps1", 0, -1).." "..
			
			"Where ID = 1";
		device.dbTV:Query(cmd);
	else
		local cmd = 
			"Update Context Set Best_identity = '' "..
			",Best_time = '' "..
			",Best_time1 = '' "..
			",Best_time2 = '' "..
			",Best_time3 = '' "..
			",Best_time4 = '' "..
	
			",Best_timeMs = -1"..
			",Best_time1Ms = -1"..
			",Best_time2Ms = -1"..
			",Best_time3Ms = -1"..
			",Best_time4Ms = -1"..
			
			",Nb_inter = "..device.raceInfo.Nb_inter.." "..
			",Manche = "..txtManche.." "..
			",Time1Ms = -1 "..
			
			"Where ID = 1";

		device.dbTV:Query(cmd);
	end
end
	
function device.OnNotifyOffsetTimeSet(key, params)
	device.offset = tonumber(params.offset);
	adv.Warning('New Offset TV = '..device.offset);
	return true;
end

-- Notification : Effacement de la Manche
function device.OnNotifyRunErased(key, params)
	if device.bib_running ~= nil then
		device.bib_running:RemoveAllRows();
	end

	device.best_time = {};
	device.tick_passage = -1;

	device.dbTV:Query("Update Context Set Best_identity = '',Best_time = ''  Where ID = 1");
	device.dbTV:Query("Update Running Set State = 'C' Where ID = 1");
	device.dbTV:Query("Delete From Ranking");
end

-- Notification : Changement du nombre de temps inter
function device.OnNotifyNbInter(key, params)
	assert(key == '<nb_inter>');
	device.raceInfo.Nb_inter = params.nb;
end

-- Fermeture
function device.OnClose()

	-- Fermeture Timer
	if device.tm_running ~= nil then
		device.tm_running:Delete();
	end

	-- Fermeture Base
	if device.dbTV ~= nil then
		device.dbTV = nil;
	end
	
	-- Fermeture Toolbar 
	if tbNavigation ~= nil then
		local mgr = app.GetAuiManager();
		mgr:DeletePane(tbNavigation);
	end
end

-- Evenement Timer 
function OnTimerRunning(evt)

	if device.mode == 'ranking' and device.bib_running:GetNbRows() > 0 and device.tick_passage <= 0 then
		local timeStart = device.bib_running:GetCellInt("Heure_depart_reelle", 0);
		local timeCurrent = app.Now() + device.offset;
			
		if timeCurrent >= timeStart and timeStart >= 0 then
			local timeRunning = timeCurrent-timeStart;
			if device.raceInfo.Code_manche > 1 then
				timeRunning = timeRunning + device.bib_running:GetCellInt("Tps1", 0, 0);
			end

			local stringTime = app.TimeToString(math.floor((timeRunning)/100)*100);
			stringTime = stringTime:sub(1,stringTime:len()-1); 

--			adv.Alert(timeRunning..' HD='..timeStart..' TC='..timeCurrent);
			device.dbTV:Query("Update Running Set State = 'R', Time = '"..stringTime.."', TimeMs = "..timeRunning.." Where ID = 1");
		end
	elseif device.tick_passage > 0 then
		local tick = app.GetTickCount();
		if tick > device.tick_passage + device.tick_passage_delay then
			device.tick_passage = -1;
			SetBibRunning();
		end
	end
end

function OnModeClear()
	device.mode = 'clear';
	modeLabel:SetLabel('clear');

	device.dbTV:Query("Update Context Set Mode = 'clear' Where ID = 1");
	RefreshMode();
end

function OnModeStartlist()
	
	device.mode = 'startlist';
	modeLabel:SetLabel('startlist');

	device.dbTV:Query("Update Context Set Mode = 'startlist', Title = '"..GetTitle().."' Where ID = 1");

	local rc, data = app.SendNotify('<ranking_load>');
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	device.ranking = data.ranking;
	RefreshMode();
end

function GetTitle()
	if device.raceInfo.tables ~= nil then
		local tEvenement = device.raceInfo.tables.Evenement;
		local tDiscipline = device.raceInfo.tables.Discipline;
		if tEvenement ~= nil and tDiscipline ~= nil then
			local title = tEvenement:GetCell('Commentaire', 0)..'|'..tDiscipline:GetCell("Libelle", 0);
			return string.gsub(title,"'", "''");
		end
	end
	return '';
end

function OnModeRanking()

	device.mode = 'ranking';

	if device.raceInfo.Code_manche == 1 then
		if device.mode_last == false then
			modeLabel:SetLabel('ranking-1');
		else
			modeLabel:SetLabel('arrivée-1');
		end
		device.dbTV:Query("Update Context Set Mode = 'ranking', Title = '"..GetTitle().."' Where ID = 1");
	else
		if device.mode_last == false then
			modeLabel:SetLabel('ranking-2');
		else
			modeLabel:SetLabel('arrivée-2');
		end
		device.dbTV:Query("Update Context Set Mode = 'ranking2', Title = '"..GetTitle().."' Where ID = 1");
	end

	device.dbTV:Query("Update Running Set State = 'C' Where ID = 1");

	local filter = '';
	if device.raceInfo.Code_manche == 1 then
		filter = "if Tps1 ~= nil and (Tps1 >0 or Tps1 == -500 or Tps1 == -800) then return true else return false end ";
	else
		filter = "if Tps ~= nil and (Tps >0 or Tps == -500 or Tps == -800) then return true else return false end ";
	end
	local rc, data = app.SendNotify('<ranking_load>', { filter = filter } );
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	device.ranking = data.ranking;

	RefreshMode();
end

function RefreshMode()
	-- Tri ...
	if device.mode == 'startlist' then
		-- Liste de Départ 
		if device.raceInfo.Code_manche == 1 then
			device.ranking:OrderBy('Dossard');
		else
			device.ranking:OrderBy('Rang2, Dossard');
		end
		TvSynchroStartlist();
	elseif device.mode == 'ranking' then
		-- Liste de Résultat
		if device.raceInfo.Code_manche == 1 then
			if device.mode_last == false then
				device.ranking:OrderBy('Clt1, Dossard');
			end
		else
			if device.mode_last == false then
				device.ranking:OrderBy('Clt, Dossard');
			end
		end
		TvSynchroRanking();
	end
end

function TvSynchroStartlist()
	if device.ranking == nil or type(device.ranking) ~= 'userdata' then return end
	if device.dbTV == nil or type(device.dbTV) ~= 'userdata' then return end

	local tvStartlist = device.dbTV:GetTable('Startlist');
	if tvStartlist == nil then return end

	local tRanking = device.ranking;

	columnInfoStartlist = columnInfoStartlist or 'Club';

	tvStartlist:RemoveAllRows();
	for i=0,tRanking:GetNbRows()-1 do

		tvStartlist:GetRecord():Set('ID', i+1);
		tvStartlist:GetRecord():Set('Bib', tRanking:GetCell('Dossard', i));
		tvStartlist:GetRecord():Set('Identity', string.gsub(tRanking:GetCell('Identite', i), "'", "''"));
		tvStartlist:GetRecord():Set('Team', string.gsub(tRanking:GetCell(columnInfoStartlist, i),"'", "''"));

		tvStartlist:GetRecord():Set('Rank1', tRanking:GetCell('Clt1', i));
		tvStartlist:GetRecord():Set('Time1', tRanking:GetCell('Tps1', i));

		tvStartlist:GetRecord():Set('Rank2', tRanking:GetCell('Clt2', i));
		tvStartlist:GetRecord():Set('Time2', tRanking:GetCell('Tps2', i));

		tvStartlist:GetRecord():Set('Rank', tRanking:GetCell('Clt', i));
		tvStartlist:GetRecord():Set('Time', tRanking:GetCell('Tps', i));

		tvStartlist:GetRecord():Set('Epreuve', tRanking:GetCell('Code_epreuve', i));
		tvStartlist:GetRecord():Set('Categ', tRanking:GetCell('Categ', i));
		tvStartlist:GetRecord():Set('Sex', tRanking:GetCell('Sexe', i));
		tvStartlist:GetRecord():Set('Distance', tRanking:GetCell('Distance', i));

		tvStartlist:AddRow();
	end

	device.dbTV:Query('Delete From Startlist');
	device.dbTV:TableBulkInsert(tvStartlist);

	device.dbTV:Query("Update Startlist Set Tick = '"..app.GetTickCount().."' ");
end

function TvSynchroRanking()
	if device.ranking == nil or type(device.ranking) ~= 'userdata' then return end
	if device.dbTV == nil or type(device.dbTV) ~= 'userdata' then return end

	local tvRanking = device.dbTV:GetTable('Ranking');
	if tvRanking == nil then return end

	local tRanking = device.ranking;

	columnInfoRanking = columnInfoRanking or 'Equipe';

	tvRanking:RemoveAllRows();
	for i=0,tRanking:GetNbRows()-1 do

		tvRanking:GetRecord():Set('ID', i+1);
		tvRanking:GetRecord():Set('Bib', tRanking:GetCell('Dossard', i));
		tvRanking:GetRecord():Set('Identity', string.gsub(tRanking:GetCell('Identite', i), "'", "''"));
		tvRanking:GetRecord():Set('Team', string.gsub(tRanking:GetCell(columnInfoRanking, i),"'", "''"));

		tvRanking:GetRecord():Set('Rank1', tRanking:GetCell('Clt1', i));
		tvRanking:GetRecord():Set('Time1', tRanking:GetCell('Tps1', i));

		tvRanking:GetRecord():Set('Rank2', tRanking:GetCell('Clt2', i));
		tvRanking:GetRecord():Set('Time2', tRanking:GetCell('Tps2', i));

		tvRanking:GetRecord():Set('Rank', tRanking:GetCell('Clt', i));
		tvRanking:GetRecord():Set('Time', tRanking:GetCell('Tps', i));
		
		tvRanking:GetRecord():Set('Epreuve', tRanking:GetCell('Code_epreuve', i));
		tvRanking:GetRecord():Set('Categ', tRanking:GetCell('Categ', i));
		tvRanking:GetRecord():Set('Sex', tRanking:GetCell('Sexe', i));
		tvRanking:GetRecord():Set('Distance', tRanking:GetCell('Distance', i));

		tvRanking:GetRecord():Set('Finish', tRanking:GetCellInt('Heure_arrivee_reelle', i));

		tvRanking:AddRow();
	end

	device.dbTV:Query('Delete From Ranking');
	device.dbTV:TableBulkInsert(tvRanking);

	device.dbTV:Query("Update Ranking Set Tick = '"..app.GetTickCount().."' ");
end