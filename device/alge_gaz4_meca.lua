-- ALGE Timy
dofile('./interface/include.lua');
dofile('./interface/device.lua');
dofile('./interface/wndDisplayBoard.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.6, 
		code = 'alge_gaz4m', 
		name = 'Alge Gaz4 Mécanique', 
		class = 'display', 
		interface = { { type='serial', baudrate = '2400'} }
	};
end	

stateBib = {
	RUNNING		= 1,
	FINISHED	= 2
};

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

-- Ouverture
function device.OnInit(params)
	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	-- Prise Offset
	local rc, data = app.SendNotify('<offset_time_load>');
	assert(rc and data.offset ~= nil);
	offsetTime = data.offset;
	adv.Alert('Alge GAZ4 : Offset Time '..offsetTime);

	-- Récupération des infos de la course
	local rc, raceInfo = app.SendNotify('<race_load>');
	assert(rc);
	device.raceInfo = raceInfo;
	adv.Alert("Alge GAZ4 : Manche = "..device.raceInfo.Code_manche.." / Inter = "..device.raceInfo.Nb_inter);

	-- Timer
	local parentFrame = app.GetAuiFrame();
	tm = timer.Create(parentFrame);
	tm:Start(1000);					-- Temps tournant à la seconde par défaut
	parentFrame:Bind(eventType.TIMER, OnTimer, tm);
	
	-- Notify 
	app.BindNotify("<bib_delete>", OnNotifyBibChange);
	app.BindNotify("<bib_insert>", OnNotifyBibChange);

	app.BindNotify("<bib_time>", OnNotifyBibTime);

	app.BindNotify("<offset_time>", OnNotifyOffsetTime);
	app.BindNotify("<run_erase>", OnNotifyRunErase);
	
	state = stateBib.RUNNING;
	OnNotifyBibChange();
	
	simulator = params.simulator or false;
	if simulator then
		displayBoard = wndDisplayBoard.New({ rows=1, cols=20 });
	end
	
end

function OnNotifyOffsetTime(key, params)
	offsetTime = params.offset;
	adv.Alert('Alge GAZ4 : Offset Time '..offsetTime);
end

function OnNotifyRunErase(key, params)
	if tRunning ~= nil then
		tRunning:RemoveAllRows();
	end
end

function OnNotifyBibChange(key, params)
	local rc, data = app.SendNotify('<bib_running>');
	assert(rc and data.running ~= nil);
	tRunning = data.running;
end

function OnNotifyBibTime(key, params)

	local idPassage = tonumber(params.passage) or -99;
	if idPassage == -1 then
		-- Uniquement les Arrivées
		state = stateBib.FINISHED;
		tickcount_finish = app.GetTickCount(); 
		SendGaz4_Time(params.bib, params.total_time, params.total_rank);
	end
end

-- Fermeture
function device.OnClose()
	-- Fermeture du Timer
	if tm ~= nil then
		tm:Delete();
	end

	-- Appel OnClose Metatable
	mt_device.OnClose();
end

function OnTimer(evt)
	if state == stateBib.RUNNING then
		if tRunning ~= nil and tRunning:GetNbRows() > 0 then
			local row = tRunning:GetNbRows()-1;
				
			local timeNow = app.Now() + offsetTime;
			local timeStart = tRunning:GetCellInt('Heure_depart_reelle', row, -1);
			if timeStart >= 0 and timeNow > timeStart then
				if device.raceInfo.Code_manche > 1 then
					timeNow = timeNow + tRunning:GetCellInt("Tps1", row, 0);
				end
				SendGaz4_RunningTime(tRunning:GetCell('Dossard', row), timeNow-timeStart);
			end
		end
	elseif state == stateBib.FINISHED then
		local tickCount = app.GetTickCount();
		if tickCount - tickcount_finish >= 7000 then
			tickcount_finish = 0;
			state = stateBib.RUNNING;
		end
	end
end

function SendGaz4_Time(bib, chrono, rk)

	chrono = chrono or 0;
	if chrono <= 0 then return end

	rk = rk or 0;
	if rk <= 0 or rk > 99 then return end
	
	local rs232 = mt_device.obj;
	assert(rs232);
	
	local packet = 
		string.format('%3d', tonumber(bib))..			-- Bib 
		'D   '..										-- 4 espaces
		app.TimeToString(chrono, "%2h:%2m:%2s.%3f")..	-- HH:MM:SS.MMM
		string.format('%2d', tonumber(rk));				-- Rk 
	
	rs232:WriteString(packet);
	rs232:WriteByte(asciiCode.CR);
	rs232:WriteByte(asciiCode.LF);

	if displayBoard ~= nil then
		displayBoard:MatrixText(string.format('%3d', tonumber(bib)),1,1);
		displayBoard:MatrixText(app.TimeToString(chrono, "%2h:%2m:%2s.%3f"),1,5);
		displayBoard:MatrixText(string.format('%2d', tonumber(rk)), 1, 18);
	end
	
	adv.Alert('GAZ4:'..packet);
end

function SendGaz4_RunningTime(bib, chrono)

	chrono = chrono or 0;
	if chrono <= 0 then return end

	local rs232 = mt_device.obj;
	assert(rs232);
	
	local packet = 
		string.format('%3d', tonumber(bib))..			-- Bib 
		'C   '..										-- 4 espaces
		app.TimeToString(chrono, "%2h:%2m:%2s.000")..	-- HH:MM:SS.MMM
		'  ';
	
	rs232:WriteString(packet);
	rs232:WriteByte(asciiCode.CR);
	rs232:WriteByte(asciiCode.LF);
	
	if displayBoard ~= nil then
		displayBoard:MatrixText(string.format('%3d', tonumber(bib)),1,1);
		displayBoard:MatrixText(app.TimeToString(chrono, "%2h:%2m:%2s.%3f"),1,5);
		displayBoard:MatrixText('  ', 1, 18);
	end	
	
	adv.Alert('GAZ4:'..packet);
end


