dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 2.3, name = 'TV Liste', class = 'display', interface = {} };
end	

-- Ouverture
function device.OnInit(params)

	-- Connexion Base MySQL "tv"
	device.dbTV = sqlBase.ConnectMySQL('localhost', 'tv', 'root', '', 3306);
	if device.dbTV == nil then
		adv.Error("Erreur Connexion Base TV");
	end
	device.dbTV:Load();
	
	-- Tableau de Bord
	tbNavigation = wnd.CreateAuiToolBar({ style = auiToolBarStyle.HORIZONTAL });

	local btn_clear = tbNavigation:AddTool("Ecran vide", "./res/32x32_clear.png");
	local btn_startlist = tbNavigation:AddTool("Liste de Départ", "./res/32x32_order.png");
	local btn_ranking = tbNavigation:AddTool("Classement", "./res/32x32_ranking.png");

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
	tbNavigation:Bind(eventType.MENU, OnModeRanking, btn_ranking);

	-- Prise valeur offset Horloge PC - Horloge Chrono Officielle
	local rc, offsetInfo = app.SendNotify('<offset_time_load>');
	assert(rc);
	device.offset = tonumber(offsetInfo.offset);

	-- Récupération des infos de la course
	local rc, raceInfo = app.SendNotify('<race_load>');
	assert(rc);
	device.raceInfo = raceInfo;
	app.GetAuiMessage():AddLine("Manche = "..device.raceInfo.Code_manche.." / Inter = "..device.raceInfo.Nb_inter);

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

	device.tick_finished = -1;

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
	local rc, bibNext = app.SendNotify("<bib_next_load>");
	if rc and type(bibNext) == 'table' then
		device.OnNotifyBibNext('<bib_next>', { bib = bibNext.bib, passage = 0});
	end

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

-- Notification : Next Bib 
function device.OnNotifyBibNext(key, params)
	assert(key == '<bib_next>');

	local passage = tonumber(params.passage) or -2;
	local bib = tonumber(params.bib) or 0;
	
	if passage == 0 and bib > 0 then
		local bibNext = device.BibLoad(bib);
		if bibNext ~= nil then
			local cmd = 
			"Update Next Set Tick = '"..app.GetTickCount().."' "..
			",State = 'O' "..
			",Bib = '"..bibNext:GetCell("Dossard", 0).."' "..
			",Identity = '"..string.gsub(bibNext:GetCell("Identite", 0), "'", "''").."' "..
			",Team = '"..string.gsub(bibNext:GetCell("Club", 0),"'","''").."' ";
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
			device.BibRunning(bib);
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
	if device.bib_running:GetNbRows() > 0 and device.tick_finished < 0 then
		local cmd = 
		"Update Running Set Tick = '"..app.GetTickCount().."' "..
		",Bib = '"..device.bib_running:GetCell("Dossard", 0).."' "..
		",Identity = '"..string.gsub(device.bib_running:GetCell("Identite", 0), "'", "''").."' "..
		",Team = '"..string.gsub(device.bib_running:GetCell("Club", 0),"'","''").."' ";
		device.dbTV:Query(cmd);
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

	if device.mode ~= 'startlist' then
		-- Prise des coureurs arrivés ou Abd ou Dsq
		local filter = '';
		if device.raceInfo.Code_manche == 1 then
			filter = "if Tps1 ~= nil and (Tps1 >0 or Tps1 == -500 or Tps1 == -800) then return true else return false end ";
		else
			filter = "if Tps ~= nil and (Tps >0 or Tps == -500 or Tps == -800) then return true else return false end ";
		end

		local rc, data = app.SendNotify('<ranking_load>', { filter = filter } );
		assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
		device.ranking = data.ranking;
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

	if time_net == nil or time_net == chrono.DNS then return end 

	local row = device.bib_running:GetIndexRow('Dossard', bib) or -1;
	local bib_finished = nil;
	if row >= 0 then
		bib_finished = adv.Filter(device.bib_running, function(t,row) return tonumber(t:GetCell('Dossard',row)) == bib end);
		assert(bib_finished:GetCell("Dossard",0) == tostring(bib));
		device.bib_running:RemoveRowAt(row);
	else
		bib_finished = device.BibLoad(bib);
	end
	
	if bib_finished ~= nil and bib_finished:GetNbRows() > 0 then
		device.tick_finished = app.GetTickCount();

		rank = rank or '';

		diff = diff or '';
		if type(diff) == 'number' then
			diff = app.TimeToString(diff, '[DIFF]%xs.%2f');
		end
		
		local cmd = 
			"Update Running Set State = 'F' "..
			",Tick = '"..app.GetTickCount().."' "..
			",Bib = '"..bib_finished:GetCell("Dossard", 0).."' "..
			",Identity = '"..string.gsub(bib_finished:GetCell("Identite", 0), "'", "''").."' "..
			",Team = '"..string.gsub(bib_finished:GetCell("Club", 0),"'","''").."' "..
			",Time = '"..app.TimeToString(time_net).."' "..
			",Rank = '"..tostring(rank).."' "..
			",Diff = '"..diff.."' ";
--		adv.Alert(cmd);
		device.dbTV:Query(cmd);
	end
end

-- Notification : Nouveau Meilleur Temps
function device.OnNotifyBestTime(key, params)
	assert(key == '<best_time>');

	if params ~= nil and params.ranking ~= nil and params.ranking:GetNbRows() == 1 then
		local identity = params.ranking:GetCell("Prenom", 0):sub(1,1)..'.'..params.ranking:GetCell("Nom", 0);
		identity = string.gsub(identity, "'", "''");

		local cmd = 
			"Update Context Set Best_identity = '"..identity.."' "..
			",Best_time = '"..app.TimeToString(params.total_time).."' "..
			"Where ID = 1";
		device.dbTV:Query(cmd);
	else
		device.dbTV:Query("Update Context Set Best_identity = '', Best_time = '' Where ID = 1");
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
	device.tick_finished = -1;

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
		device.dbTV:Delete();
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

	if device.mode == 'ranking' and device.bib_running:GetNbRows() > 0 and device.tick_finished <= 0 then
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
			device.dbTV:Query("Update Running Set State = 'R', Time = '"..stringTime.."' Where ID = 1");
		end
	elseif device.tick_finished > 0 then
		local tick = app.GetTickCount();
		if tick > device.tick_finished + 5000 then
			device.tick_finished = -1;
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
		local tEpreuve = device.raceInfo.tables.Epreuve;
		if tEvenement ~= nil and tEpreuve ~= nil then
			local title = tEvenement:GetCell('Organisateur', 0)..'|'..tEpreuve:GetCell('Code_discipline', 0);
			return string.gsub(title,"'", "''");
		end
	end
	return '';
end

function OnModeRanking()

	device.mode = 'ranking';

	if device.raceInfo.Code_manche == 1 then
		modeLabel:SetLabel('ranking-1');
		device.dbTV:Query("Update Context Set Mode = 'ranking', Title = '"..GetTitle().."' Where ID = 1");
	else
		modeLabel:SetLabel('ranking-2');
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
			device.ranking:OrderBy('Clt1, Dossard');
		else
			device.ranking:OrderBy('Clt, Dossard');
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

	tvStartlist:RemoveAllRows();
	for i=0,tRanking:GetNbRows()-1 do

		tvStartlist:GetRecord():Set('ID', i+1);
		tvStartlist:GetRecord():Set('Bib', tRanking:GetCell('Dossard', i));
		tvStartlist:GetRecord():Set('Identity', string.gsub(tRanking:GetCell('Identite', i), "'", "''"));
		tvStartlist:GetRecord():Set('Team', string.gsub(tRanking:GetCell('Club', i),"'", "''"));

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

	tvRanking:RemoveAllRows();
	for i=0,tRanking:GetNbRows()-1 do

		tvRanking:GetRecord():Set('ID', i+1);
		tvRanking:GetRecord():Set('Bib', tRanking:GetCell('Dossard', i));
		tvRanking:GetRecord():Set('Identity', string.gsub(tRanking:GetCell('Identite', i), "'", "''"));
		tvRanking:GetRecord():Set('Team', string.gsub(tRanking:GetCell('Club', i),"'", "''"));

		tvRanking:GetRecord():Set('Rank1', tRanking:GetCell('Clte1', i));
		tvRanking:GetRecord():Set('Time1', tRanking:GetCell('Tps1', i));

		tvRanking:GetRecord():Set('Rank2', tRanking:GetCell('Clte2', i));
		tvRanking:GetRecord():Set('Time2', tRanking:GetCell('Tps2', i));

		tvRanking:GetRecord():Set('Rank', tRanking:GetCell('Clte', i));
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