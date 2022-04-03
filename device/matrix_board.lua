-- Matrix Board
dofile('./interface/interface.lua');
dofile('./interface/device.lua');
dofile('./interface/adv.lua');

-- Information : Numéro de Version, Nom, Interface
	-- 6.6 sur les microgate u tab supression du temps tournant si ouvreur en course on affiche Ouvreur A ou B...
	-- 	Rectification pour le Alge gaz 4
	-- relecture apres la version 6.5de pierre
function device.GetInformation()
	return { 
		version = 6.6, 
		code = 'matrix_board', 
		name = 'Tableau Matrice', 
		class = 'display', 
		interface = { 
				{ type='serial', baudrate = '1200,2400,4800,9600,19200,38400,57600' },
				{ type='tcp', port = 7000, hostname = '192.168.1.50' },
				{ type='udp', port = 7000, hostname = '192.168.1.50' },
				{ type='none' } 
		}
	};
end	

boardTarget = 
{ 
	'agil_pi_display',
	'agil_pi_led',
	'alge_dtrn',
	'alge_gaz4m',
	'eridan',
	'microgate_tab',
	'microgate_graph',
	'vola_ca8_15',
	''
}

boardMode = 
{ 
	{ code = 'last_finish', label = 'Coureur en Course + dernières Arrivées' },
	{ code = 'ranking', label = 'Coureur en Course + Classement' },
	{ code = 'last_finish_full', label = 'Dernières Arrivées' },
	{ code = 'ranking_full', label = 'Classement' },
	{ code = 'startlist_full', label = 'Liste de Départ' },
	{ code = 'message', label = 'Message Hors Course' },
}

boardOptionFinish = 
{ 
	{ code = 'run', label = 'Temps Manche' },
	{ code = 'total', label = 'Temps Total' },
	{ code = 'run_total', label = 'Temps Manche puis Temps Total' },
	{ code = 'total_run', label = 'Temps Total puis Temps Manche' },
	{ code = 'run_medal', label = 'Temps Manche puis Médaille' }
}

stateBib = {
	RUNNING			= 1,
	INTER			= 2,
	FINISH	 		= 3
};

function boardIsFullList(mode)
	if mode == 'last_finish' or mode == 'ranking' then
		return false;
	else
		return true;
	end
end

-- Configuration
function device.OnConfiguration(node)
	wnd.ConfigDisplayBoard(node);
end

-- Ouverture
function device.OnInit(params, node)

	-- TCP agil_pi_display => Mode Async 
	params.target = params.target or '';
	if params.type == "tcp" then
		if string.find(params.target, 'agil_pi_display') == 1 or string.find(params.target, 'agil_pi_led') == 1 then
			params.type = 'tcp_async';
		end
	end

	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	-- Prise Offset
	local rc, data = app.SendNotify('<offset_time_load>');
	assert(rc and data.offset ~= nil);
	offsetTime = data.offset;
	
	adv.Alert('Matrix Board : Offset Time '..offsetTime);
	
	-- Récupération des infos de la course
	local rc, raceInfo = app.SendNotify('<race_load>');
	assert(rc);
	device.raceInfo = raceInfo;

	-- Prise Manche (Ski) ou Course et Phase (Canoe) 
	device.Code_course = tonumber(raceInfo.Code_course) or -1;
	device.Code_phase = tonumber(raceInfo.Code_phase) or -1;
	device.Code_manche = tonumber(raceInfo.Code_manche) or 1;
	device.mode_single = true;

	if device.Code_course >= 1 and device.Code_phase >= 1 then
		-- Canoe
		device.key_current = tostring(device.Code_course)..'_'..tostring(device.Code_phase);
		device.startlist_current = device.key_current;
	else 
		-- Ski
		device.startlist_current = tostring(device.Code_manche);

		if device.Code_manche == 1 then
			device.key_current = '1';
		else
			device.key_current = '';
			device.mode_single = false;
		end
	end

	-- Discipline et Entite ...
	device.discipline = '';
	device.entite = '';
	local tEpreuve = device.raceInfo.tables.Epreuve;
	if tEpreuve ~= nil then
		device.discipline = tEpreuve:GetCell('Code_discipline',0);
		device.entite = tEpreuve:GetCell('Code_entite',0);
	end

	-- Creation Simulateur DisplayBoard 
	displayBoard = wnd.CreateDisplayBoard({ node = node });

	local caption = "Tableau "..displayBoard:MatrixGetTarget()..' ('..
		tostring(displayBoard:MatrixGetRowCount())..' lig x '..
		tostring(displayBoard:MatrixGetColumnCount().." col")..' - '..
		displayBoard:MatrixGetMode()..')'
	;
	
	local mgr = app.GetAuiManager();
	mgr:AddPane(displayBoard, {
		icon = './res/16x16_live.png',
		caption = caption,
		caption_visible = true,
		close_button = false,
		pin_button = true,
		show = true,

		float = true, 
		floating_position = {500, 100},
		floating_size = {400, 100},
		dockable = false
	});
	mgr:Update();

	-- Timer
	local parentFrame = app.GetAuiFrame();
	if displayBoard:MatrixGetRunningTime() > 0 then
		timerRacer = timer.Create(parentFrame);
		timerRacer:Start(displayBoard:MatrixGetRunningTime());
		parentFrame:Bind(eventType.TIMER, OnTimer, timerRacer);
	end
	
	if displayBoard:MatrixGetDelayList() > 0 then
		timerList = timer.Create(parentFrame);
		parentFrame:Bind(eventType.TIMER, OnTimerList, timerList);
	end
	
	-- Notify 
	app.BindNotify("<bib_delete>", OnNotifyBibChange);
	app.BindNotify("<bib_insert>", OnNotifyBibChange);

	app.BindNotify("<bib_time>", OnNotifyBibTime);
	app.BindNotify("<forerunner_time>", OnNotifyForerunnerTimeBibTime);
	
	app.BindNotify("<offset_time>", OnNotifyOffsetTime);
	app.BindNotify("<run_erase>", OnNotifyRunErase);
	
	state = stateBib.RUNNING;
	OnNotifyBibChange();
	
	-- Initialisation Hard éventuelle ...
	SynchroInitialisation();
	
	-- Initialisation "template" Fields
	InitTemplateFields();
	
	InitTemplateFieldsStartlist();
	InitTemplateFieldsRanking();
	InitTemplateFieldsLastFinish();
	InitTemplateFieldsMessage(node);
	
	-- Affichage dernieres Arrivées ou Classement 
	Board_List();
end

function GetIdentity(tRanking, row)
	local col = tRanking:GetIndexColumn('Identite');
	if col < 0 then
		col = tRanking:GetIndexColumn('Bateau');
	end
	
	if col >= 0 then
		return tRanking:GetCell(col, row);
	else
		return ''
	end
end

function GetLenAgilPiFontStd(txt)
	local lg = 0;
	for i=1,txt:len() do
		local c = txt:sub(i,i);
		if c == '+' or c == '-' then
			lg = lg+3;
		elseif c == ':' or c == '.' then
			lg = lg+1;
		elseif c == '[' or c == ']' then
			lg = lg+2;
		else
			lg = lg+8;
		end
	end
	return lg;
end 

function InitTemplateFields()
	templateFields = {};
	
	local columnCount = displayBoard:MatrixGetColumnCount();
	if columnCount < 12 then
		InitTemplateFieldsMini();
	elseif device.entite == 'ESF' then
		InitTemplateFieldsESF_Fleche();
	else
		InitTemplateFieldsStd();
	end
end

-- <= 12 Caractères
function InitTemplateFieldsMini()
	local columnCount = displayBoard:MatrixGetColumnCount();
	lgBib = 3;
	if displayBoard:MatrixGetColumnCount() <= 8 then lgBib = 2 end
	
	-- Dossard
	templateFields.bib_running = {
		condition = function(txt)
			if type(txt) == 'number' then txt = tostring(txt) end
			local lgBib = 3;
			if displayBoard:MatrixGetColumnCount() <= 8 then lgBib = 2 end
			if txt:len() <= lgBib then return true else return false end 
		end,

		color = color.Create(255, 255, 0), 
		row = 0,
		col = 0,
		lg = lgBib,
		align = 'right'
	};
		
	-- Temps Tournant
	templateFields.time_running = { 
		color = color.Create(0, 255, 0), 
		text = function(txt) return txt:TrimAll(); end,
		row = 0,
		col = lgBib,
		lg = columnCount-lgBib,
		align = 'right',
		
		agil_pi_display_fmt = function(field) 
			field.txt = field.txt:TrimAll(); 
			local unitAgil = displayBoard:MatrixGetBlocUnitCount() or 64;
			if field.txt:len() <= 5 then
				field.agil_pi_display_col = unitAgil - GetLenAgilPiFontStd(field.txt)-6; 
			else
				field.agil_pi_display_col = unitAgil - GetLenAgilPiFontStd(field.txt)-14; 
			end
		end
	};
	
	-- Dossard
	templateFields.bib_finish = {
		condition = function(txt)
			if type(txt) == 'number' then txt = tostring(txt) end
			local lgBib = 3;
			if displayBoard:MatrixGetColumnCount() <= 8 then lgBib = 2 end
			if txt:len() <= lgBib then return true else return false end 
		end,

		color = color.Create(255, 255, 255), 
		row = 0,
		col = 0,
		lg = lgBib,
		align = 'right'
	};

	-- Temps 
	templateFields.time_finish = { 
		color = color.Create(255, 0, 0), 
		text = function(txt) return txt:TrimAll(); end,
		row = 0,
		col = lgBib,
		lg = columnCount-lgBib,
		align = 'right',
		
		agil_pi_display_fmt = function(field) 
			field.txt = field.txt:TrimAll(); 
			local unitAgil = displayBoard:MatrixGetBlocUnitCount() or 64;
			field.agil_pi_display_col = unitAgil - GetLenAgilPiFontStd(field.txt); 
		end
	};
	
	--
	-- A l'inter ...
	--

	-- Dossard
	templateFields.bib_inter = {
		condition = function(txt)
			if type(txt) == 'number' then txt = tostring(txt) end
			local lgBib = 3;
			if displayBoard:MatrixGetColumnCount() <= 8 then lgBib = 2 end
			if txt:len() <= lgBib then return true else return false end 
		end,

		color = color.Create(255, 255, 255), 
		row = 0,
		col = 0,
		lg = lgBib,
		align = 'right'
	};

	-- Temps 
	templateFields.time_inter = { 
		color = color.Create(255, 0, 0), 
		text = function(txt) return txt:TrimAll(); end,
		row = 0,
		col = lgBib,
		lg = columnCount-lgBib,
		align = 'right',
		
		agil_pi_display_fmt = function(field) 
			field.txt = field.txt:TrimAll(); 
			local unitAgil = displayBoard:MatrixGetBlocUnitCount() or 64;
			field.agil_pi_display_col = unitAgil - GetLenAgilPiFontStd(field.txt); 
		end
	};
end	

-- ESF - Fleche - Chamois
function InitTemplateFieldsESF_Fleche()
	local columnCount = displayBoard:MatrixGetColumnCount();
	
	--
	-- En course ...
	--
	
	-- Dossard
	templateFields.bib_running = {
		color = color.Create(255, 255, 0), 
		row = 0,
		col = 0,
		lg = 3,
		align = 'right'
	};
		
	-- Identité
	templateFields.identity_running = { 
		color = color.Create(0, 255, 0), 
		row = 0,
		col = 4,
		lg = columnCount-4,
		align = 'left',
		agil_pi_display_col = 24,
		agil_pi_display_font = '-t6x7'
	};
	
	-- Temps Tournant
	templateFields.time_running = { 
		color = color.Create(0, 255, 0), 
		row = 1,
		col = 0,
		lg = columnCount,
		align = 'right',
		
		agil_pi_display_fmt = function(field) 
			field.txt = field.txt:TrimAll(); 
			local unitAgil = displayBoard:MatrixGetBlocUnitCount() or 64;
			if field.txt:len() <= 5 then
				field.agil_pi_display_col = unitAgil - GetLenAgilPiFontStd(field.txt)-6; 
			else
				field.agil_pi_display_col = unitAgil - GetLenAgilPiFontStd(field.txt)-14; 
			end
		end
	};
	
	--
	-- A l'arrivée ...
	--
	
	-- Dossard
	templateFields.bib_finish = {
		color = color.Create(255, 255, 255), 
		row = 0,
		col = 0,
		lg = 3,
		align = 'right'
	};
	
	-- Identité
	templateFields.identity_finish = { 
		color = color.Create(0, 255, 255), 
		row = 0,
		col = 4,
		lg = columnCount-4,
		align = 'left',
		
		agil_pi_display_col = 24;
		agil_pi_display_font = '-t6x7'
	};

	-- Temps 
	templateFields.time_finish = { 
		color = color.Create(255, 255, 255), 
		row = 1,
		col = 0,
		lg = 7,
		align = 'right',
		
		agil_pi_display_fmt = function(field) 
			field.txt = field.txt:TrimAll(); 
		end
	};

	-- Medaille 
	templateFields.medal_finish = { 
		condition = function(txt)
			if txt:len() > 0 then return true else return false end 
		end,
		color = color.Create(0, 255, 0), 
		row = 1,
		col = 8,
		lg = columnCount-8,
		align = 'left',
		
		agil_pi_display_col = 42
	};

	-- Clt 
	templateFields.rank_finish = { 
		condition = function(txt) 
			if type(txt) == 'number' then txt = tostring(txt) end
			if txt:len() <= 3 then return true else return false end 
		end,
		color = color.Create(255, 0, 0), 
		row = 1,
		col = columnCount-3,
		lg = 3,
		align = 'right',
		
		agil_pi_display_fmt = function(field) 
			field.txt = field.txt:TrimAll(); 
			local unitAgil = displayBoard:MatrixGetBlocUnitCount() or 64;
			field.agil_pi_display_col = unitAgil - GetLenAgilPiFontStd(field.txt); 
		end
	};
end

-- Std : FIS - FFS
function InitTemplateFieldsStd()
	
	local columnCount = displayBoard:MatrixGetColumnCount();

	--
	-- En course ...
	--
	
	-- Dossard
	templateFields.bib_running = {
		color = color.Create(255, 255, 0), 
		row = 0,
		col = 0,
		lg = 3,
		align = 'right'
	};
		
	-- Identité
	templateFields.identity_running = { 
		color = color.Create(0, 255, 0), 
		row = 0,
		col = 4,
		lg = columnCount-4,
		align = 'left',
		agil_pi_display_col = 24,
		agil_pi_display_font = '-t6x7'
	};
	
	-- Temps Tournant
	templateFields.time_running = { 
		color = color.Create(0, 255, 0), 
		row = 1,
		col = 0,
		lg = columnCount,
		align = 'right',
		
		agil_pi_display_fmt = function(field) 
			field.txt = field.txt:TrimAll(); 
			local unitAgil = displayBoard:MatrixGetBlocUnitCount() or 64;
			if field.txt:len() <= 5 then
				field.agil_pi_display_col = unitAgil - GetLenAgilPiFontStd(field.txt)-6; 
			else
				field.agil_pi_display_col = unitAgil - GetLenAgilPiFontStd(field.txt)-14; 
			end
		end
	};

	--
	-- A l'arrivée ...
	--
	
	-- Dossard
	templateFields.bib_finish = {
		color = color.Create(255, 255, 255), 
		row = 0,
		col = 0,
		lg = 3,
		align = 'right'
	};
	
	-- Identité
	templateFields.identity_finish = { 
		color = color.Create(0, 255, 0), 
		row = 0,
		col = 4,
		lg = columnCount-4,
		align = 'left',
		
		agil_pi_display_col = 24;
		agil_pi_display_font = '-t6x7'
	};

	-- Temps 
	templateFields.time_finish = { 
		color = color.Create(255, 255, 255), 
		row = 1,
		col = 0,
		lg = 7,
		align = 'right',
		
		agil_pi_display_fmt = function(field) 
			field.txt = field.txt:TrimAll();
		end
	};

	-- Ecart 
	templateFields.diff_finish = { 
		condition = function(txt)
			if txt:len() <= 5 then return true else return false end 
		end,
		
		text = function(txt) 
			if displayBoard:MatrixGetColumnCount() > 16 then return '['..txt..']' else return txt; end
		end,

		color = function(txt) 
			if txt:find('+') ~= nil then 
				return color.Create(255, 0, 0) 
			elseif txt:find('-') ~= nil then
				return color.Create(0, 255, 0) 
			else
				return color.Create(0, 0, 255) 
			end 
		end,
		
		row = 1,
		col = 7,
		lg = function(txt) return txt:len() end,
		align = 'left',
		
		agil_pi_display_fmt = function(field, client_data) 
			local rk = client_data or 0;
			if rk <= 0 or rk >= 99 then
				field.txt = '';
			end
		end,
			
		agil_pi_display_col = 44,
	};

	-- Clt 
	templateFields.rank_finish = { 
		condition = function(txt) 
			if type(txt) == 'number' then txt = tostring(txt) end
			if txt:len() <= 3 then return true else return false end 
		end,
		color = color.Create(255, 255, 0), 
		row = 1,
		col = columnCount-3,
		lg = 3,
		align = 'right',
		
		agil_pi_display_fmt = function(field) 
			local unitAgil = displayBoard:MatrixGetBlocUnitCount() or 64;
			field.txt = field.txt:TrimAll(); 
			field.agil_pi_display_col = unitAgil - GetLenAgilPiFontStd(field.txt); 
		end
	};
	
	--
	-- A l'inter ...
	--

	-- Dossard
	templateFields.bib_inter = {
		color = color.Create(255, 255, 255), 
		row = 0,
		col = 0,
		lg = 3,
		align = 'right'
	};
	
	-- Identité
	templateFields.identity_inter = { 
		color = color.Create(0, 255, 0), 
		row = 0,
		col = 4,
		lg = columnCount-4,
		align = 'left',
		
		agil_pi_display_col = 24;
		agil_pi_display_font = '-t6x7'
	};

	-- Temps 
	templateFields.time_inter = { 
		color = color.Create(0, 255, 255), 
		row = 1,
		col = 0,
		lg = 7,
		align = 'right',
		
		agil_pi_display_fmt = function(field) 
			field.txt = field.txt:TrimAll(); 
		end
	};

	-- Ecart 
	templateFields.diff_inter = { 
		condition = function(txt)
			if txt:len() <= 5 then return true else return false end 
		end,
		
		text = function(txt) 
			if displayBoard:MatrixGetColumnCount() > 16 then return '['..txt..']' else return txt; end
		end,

		color = function(txt) 
			if txt:find('+') ~= nil then 
				return color.Create(255, 0, 0) 
			elseif txt:find('-') ~= nil then
				return color.Create(0, 255, 0) 
			else
				return color.Create(0, 0, 255) 
			end 
		end,
		
		row = 1,
		col = 7,
		lg = function(txt) return txt:len() end,
		align = 'left',
		
		agil_pi_display_fmt = function(field) 
			inter_time = inter_time or 0;
			if inter_time <= 0 or inter_time > 59999 then
				field.txt = '';
			end
		end,
		
		agil_pi_display_col = 42
	};
	
end

function InitTemplateFieldsStartlist()
	templateFieldsStartlist = {};
	
	local columnCount = displayBoard:MatrixGetColumnCount();
	
	-- Dossard 
	templateFieldsStartlist.bib = { 
		condition = function(txt) 
			if type(txt) == 'number' then txt = tostring(txt) end
			if txt:len() <= 3 then return true else return false end 
		end,
		color = color.Create(255, 255, 0), 
		col = 0,
		lg = 3,
		align = 'right',
	};
	
	-- Identite
	templateFieldsStartlist.identity = { 
		color = color.Create(255, 255, 255), 
		col = 4,
		lg = columnCount-4,
		align = 'left',
	};
end

function InitTemplateFieldsRanking()
	templateFieldsRanking = {};
	
	local columnCount = displayBoard:MatrixGetColumnCount();
	
	-- Classement 
	templateFieldsRanking.rank = { 
		condition = function(txt) 
			if type(txt) == 'number' then txt = tostring(txt) end
			if txt:len() <= 3 then return true else return false end 
		end,
		text = function(txt) return txt..'-'; end,
		color = color.Create(255, 255, 0), 
		col = 0,
		lg = 4,
		align = 'right',
	};
	
	-- Identite 
	templateFieldsRanking.identity = { 
		color = color.Create(255, 255, 255), 
		col = 4,
		lg = columnCount-4,
		align = 'left',
	};

	-- Temps 
	templateFieldsRanking.time = { 
		color = color.Create(255, 0, 0), 
		col = columnCount-8,
		lg = 8,
		align = 'right',
	};
end

function InitTemplateFieldsLastFinish()
	templateFieldsLastFinish = {};
	
	local columnCount = displayBoard:MatrixGetColumnCount();
	
	-- Dossard 
	templateFieldsLastFinish.bib = { 
		condition = function(txt) 
			if type(txt) == 'number' then txt = tostring(txt) end
			if txt:len() <= 4 then return true else return false end 
		end,
		text = function(txt) return txt..'.'; end,
		color = color.Create(255, 255, 0), 
		col = 0,
		lg = 4,
		align = 'right',
		row = 0
	};
	
	-- Identite 
	templateFieldsLastFinish.identity = { 
		color = color.Create(255, 255, 255), 
		col = 4,
		lg = columnCount-4,
		align = 'left',
		row = 0
	};
	
	if columnCount < 25 then
		-- Temps 
		templateFieldsLastFinish.time = { 
			color = color.Create(255, 0, 0), 
			col = 0,
			lg = 8,
			align = 'right',
			row = 1
		};
		
		-- Medaille
		templateFieldsLastFinish.medal = { 
			text = function(txt) if string.len(txt) > 2 then txt = string.sub(txt,1,2) end return ' '..txt end,
			color = color.Create(255, 128, 0), 
			col = columnCount-8,
			lg = 3,
			align = 'left',
			row = 1
		};
		
		-- Classement
		templateFieldsLastFinish.rank = { 
			text = function(txt) if type(txt) == 'number' and txt > 0 then return '('..tostring(txt)..')' else return '' end end,
			color = color.Create(0, 255, 0), 
			col = columnCount-5,
			lg = 5,
			align = 'right',
			row = 1
		};
	else
			-- Temps 
		templateFieldsLastFinish.time = { 
			color = color.Create(255, 0, 0), 
			col = columnCount-16,
			lg = 8,
			align = 'right',
			row = 0
		};

		-- Medaille
		templateFieldsLastFinish.medal = { 
			text = function(txt) if string.len(txt) > 2 then txt = string.sub(txt,1,2) end return ' '..txt end,
			color = color.Create(255, 128, 0), 
			col = columnCount-8,
			lg = 3,
			align = 'left',
			row = 0
		};
		
		-- Classement
		templateFieldsLastFinish.rank = { 
			text = function(txt) if type(txt) == 'number' and txt > 0 then return '('..tostring(txt)..')' else return '' end end,
			color = color.Create(0, 255, 0), 
			col = columnCount-5,
			lg = 5,
			align = 'right',
			row = 0
		};
	end
end  

function InitTemplateFieldsMessage(node)
	templateFieldsMsg = {};
	local color1 = color.Create(node:GetAttribute('color1', 'red'));
	local color2 = color.Create(node:GetAttribute('color2', 'red'))
	local color3 = color.Create(node:GetAttribute('color3', 'red'))
	
	local timer1 = tonumber(node:GetAttribute('timer1', '0')) or 0;
	local timer2 = tonumber(node:GetAttribute('timer2', '0')) or 0;
	local timer3 = tonumber(node:GetAttribute('timer3', '0')) or 0;
	
	local rowCount = displayBoard:MatrixGetRowCount();
	local columnCount = displayBoard:MatrixGetColumnCount();
	
	local target = displayBoard:MatrixGetTarget();
	if target == 'agil_pi_led' then
		columnCount = 255;
	end
	
	-- permet d'envoyer un message a bandeau défilant sur le microtab 1 ligne 9 colonnes
	local mode = displayBoard:MatrixGetMode(); 
	if target == "microgate_tab" and (mode:find('message') or -1) == 1 then
		local msg = node:GetAttribute('message');
		-- adv.Alert('msg : '..msg);
		if tonumber(msg:len()) > tonumber(columnCount) then
			microgate_tabMsg = node:GetAttribute('message');
			microgate_Msg = true;
			-- adv.Alert('microgate_tabMsg : '..microgate_tabMsg);
		else
			microgate_Msg = false;
		end
	end
	-- fin création message pour bandeau défilant
	
	for r=0,rowCount-1 do
		templateFieldsMsg['row'..tostring(r)] = {
			row = r,
			col = 0,
			lg = columnCount,
			align = 'left'
		}
		
		if r == 0 then templateFieldsMsg['row0'].color = color1;
		elseif r == 1 then templateFieldsMsg['row1'].color = color2;
		else templateFieldsMsg['row'..tostring(r)].color = color3;
		end

		if r == 0 then templateFieldsMsg['row0'].timer = timer1;
		elseif r == 1 then templateFieldsMsg['row1'].timer = timer2;
		else templateFieldsMsg['row'..tostring(r)].timer = timer3;
		end
		
	end

	local msg = node:GetAttribute('message');
	local arrayMsg = string.Split(msg, '|');
	for r=1, #arrayMsg do
		AddField(templateFieldsMsg, 'row'..tostring(r-1), arrayMsg[r]);
	end

end

function ResetArrayField(fields)
	fields.array = {};
end

function AddField(fields, code, txt, row, data)
	fields.array = fields.array or {};
	table.insert(fields.array, { code = code, txt = txt, row = row, client_data = data });
end

function AddFieldClientData(fields, code, txt, data)
	fields.array = fields.array or {};
	table.insert(fields.array, { code = code, txt = txt, row = nil, client_data = data });
end

function GetTextAlign(txt, lg, align)
	if type(txt) == 'number' then txt = tostring(txt) end
	if txt:len() > lg then
		return txt:sub(1, lg);
	elseif txt:len() < lg then
		if align == 'right' then
			return string.rep(' ', lg-txt:len())..txt;
		elseif align == 'center' then
			return string.rep(' ', (lg-txt:len())/2)..txt..string.rep(' ', lg-txt:len()-(lg-txt:len())/2);
		else
			return txt..string.rep(' ', lg-txt:len());
		end
	else
		return txt;
	end
end

function GetFieldText(field, txt)
	txt = txt or '';
	if type(field.text) == 'function' then
		txt = field.text(txt);
	end
	if type(field.lg) == 'function' then
		return GetTextAlign(txt, field.lg(txt), field.align)
	else
		return GetTextAlign(txt, field.lg, field.align)
	end
end

function GetFieldColor(field)
	if type(field.color) == 'function' then
		return field.color(field.txt);
	else
		return field.color;
	end
end

function RefreshFields(fields)
	assert(type(fields) == 'table');
	assert(type(fields.array) == 'table');
	
	local rowMin = 9999;
	local rowMax = 0;
	
	local clearRows = {};
	
	local target = displayBoard:MatrixGetTarget();
	if target == "alge_gaz4m" then
		-- Cas Spécifique Alge GAZ 4
		SynchroAlgeGaz4meca(fields);
	end
	
	-- Cas Standard ...
	for i=1,#fields.array do
		local item = fields.array[i];
		local field = fields[item.code];
		
		if type(field) == 'table' then
			local condition = true;
			if type(field.condition) == 'function' then
				condition = field.condition(item.txt);
			end
			
			if condition == true then
				field.txt = GetFieldText(field, item.txt);
				local row = item.row;
				if row == nil then 
					row = field.row
				elseif type(field.row) == 'number' then
					row = row + field.row;
				end
					
				-- Effacement éventuel de la ligne 
				if clearRows[row] == nil then
					displayBoard:MatrixClearRow(row);
					clearRows[row] = true;
				end
				
				displayBoard:MatrixSetText(field.txt, row, field.col, GetFieldColor(field));
				
				if row < rowMin then rowMin = row end
				if row > rowMax then rowMax = row end
			end
		end
	
	end
	
	if rowMin >= 0 and rowMax < displayBoard:MatrixGetRowCount() and rowMin <= rowMax then
		SynchroRow(rowMin, rowMax, fields);
	end
end

function Board_Message()
	RefreshFields(templateFieldsMsg);
end

function SynchroFieldsAgilPi(fields)
	if fields == nil then
		if type(mt_device.obj) == 'table' then
			socket.SendTcpAsync(displayBoard, mt_device.obj.hostname, mt_device.obj.port, '-c ');
		end
		return;
	end

	local cmd = '';
	for i=1,#fields.array do
		local item = fields.array[i];
		local field = fields[item.code];
		if type(field) == 'table' then
			local condition = true;
			if type(field.condition) == 'function' then
				condition = field.condition(item.txt);
			end
			if condition == true then
				field.txt = GetFieldText(field, item.txt);
				if type(field.agil_pi_display_fmt) == 'function' then
					field.agil_pi_display_fmt(field, item.client_data);
				end
				if field.txt ~= '' then
					txt = field.txt:Replace(' ','|');
					
					local row = item.row;
					if row == nil then row = field.row end
					row = row*8;
					local col = field.col*8;
					if type(field.agil_pi_display_col) == 'number' then
						col = field.agil_pi_display_col;
					end
					local font = '-t';
					if type(field.agil_pi_display_font) == 'string' then
						font = field.agil_pi_display_font;
					end
					cmd = cmd..font..' '..txt..' '..tostring(GetFieldColor(field):GetRGB())..' '..tostring(col)..' '..tostring(row)..' ';
				end
			end
		end
	end
	
	if type(mt_device.obj) == 'table' and cmd:len() > 0 then
		cmd = '-c '..cmd..'-s ';
		socket.SendTcpAsync(displayBoard, mt_device.obj.hostname, mt_device.obj.port, cmd);
--		adv.Alert('cmd='..cmd);
	end
end

function SynchroFieldsAgilPiLed(fields)
	if fields == nil then
		if type(mt_device.obj) == 'table' then
			socket.SendTcpAsync(displayBoard, mt_device.obj.hostname, mt_device.obj.port, '-c'..string.char(0));
		end
		return;
	end

	local cmd = '';
	for i=1,#fields.array do
		local item = fields.array[i];
		local field = fields[item.code];
		if type(field) == 'table' then
			local condition = true;
			if type(field.condition) == 'function' then
				condition = field.condition(item.txt);
			end
			if condition == true then
				if string.sub(item.txt,1,2) == '[[' then
					cmd = string.sub(item.txt,3);
					cmd = cmd:Replace('$', string.char(3));
					cmd = cmd..string.char(0);
					socket.SendTcpAsync(displayBoard, mt_device.obj.hostname, mt_device.obj.port, cmd);
					return;
				end

				field.txt = GetFieldText(field, item.txt);
				if type(field.agil_pi_display_fmt) == 'function' then
					field.agil_pi_display_fmt(field, item.client_data);
				end
				if field.txt ~= '' then
					local row = item.row;
					if row == nil then row = field.row end
					row = row*8;
					local col = field.col*8;
					if type(field.agil_pi_display_col) == 'number' then
						col = field.agil_pi_display_col;
					end
					local font = '-t8x8';
					if field.timer ~= nil and tonumber(field.timer) > 0 then
						font = '-scroll8x8';
					end
					
					if type(field.agil_pi_display_font) == 'string' then
						font = field.agil_pi_display_font;
					end

					field.txt = field.txt:TrimAll(); 
					if font == '-scroll8x8' then
						cmd = cmd..string.char(3)..'-scroll8x8 "'..field.txt..'" '..tostring(GetFieldColor(field):GetRGB())..' 0 '..tostring(row)..' 96 '..tostring(8)..' '..tostring(field.timer);
					else
						if row == 8 then row = 9 end
						cmd = cmd..string.char(3)..font..' '..'"'..field.txt..'" '..tostring(GetFieldColor(field):GetRGB())..' '..tostring(col)..' '..tostring(row);
					end
				end
			end
		end
	end
	
	if type(mt_device.obj) == 'table' and cmd:len() > 0 then
		cmd = '-c'..string.char(3)..'-cscroll'..string.char(3)..cmd..string.char(3)..'-s'..string.char(0);
		socket.SendTcpAsync(displayBoard, mt_device.obj.hostname, mt_device.obj.port, cmd);
--		adv.Alert('cmd='..cmd);
	end
end

function OnNotifyOffsetTime(key, params)
	offsetTime = params.offset;
	adv.Alert('Matrix Board : Offset Time '..offsetTime);
end

function OnNotifyRunErase(key, params)
	-- Effacement ...
	tRunning = nil;
	displayBoard:MatrixClearRow(0, displayBoard:MatrixGetRowCount()-1);
	SynchroRow(0,displayBoard:MatrixGetRowCount()-1);
end

function OnNotifyBibChange(key, params)
	local rc, data = app.SendNotify('<bib_running>');
	assert(rc and data.running ~= nil);
	tRunning = data.running;
end

function OnNotifyBibTime(key, params)
	local idPassage = tonumber(params.passage) or -99;
	
	if idPassage == -1 then
		-- Arrivée ...
		tickcount_finish = app.GetTickCount(); 
		state = stateBib.FINISH;

		local optionFinish = displayBoard:MatrixGetOptionFinish();
		
		if device.mode_single == true then
			-- Manche 1
			Board_FinishTime(params.bib, params.time, params.rank, params.diff);
			
			if optionFinish == 'run_medal' then 
				infoFinish = {};
				table.insert(infoFinish, { bib = params.bib, medal = params.medal });
			end
		else
			-- Manche 2 ou supérieure ....
			infoFinish = {};
			
			if optionFinish == 'total_run' then
				table.insert(infoFinish, { bib = params.bib, chrono = params.time, rank = params.rank, diff = params.diff });
			elseif optionFinish == 'run_total' then 
				table.insert(infoFinish, { bib = params.bib, chrono = params.total_time, rank = params.total_rank, diff = params.total_diff });
			elseif optionFinish == 'run_medal' then 
				table.insert(infoFinish, { bib = params.bib, medal = params.medal });
			end
			
			if string.sub(optionFinish,1,3) == 'run' then
				Board_FinishTime(params.bib, params.time, params.rank, params.diff)
			else
				Board_FinishTime(params.bib, params.total_time, params.total_rank, params.total_diff);
			end
		end
	elseif idPassage >= 1 then
		-- Inter1, Inter 2 ...
		if tRunning ~= nil and tRunning:GetNbRows() > 0 and state ~= stateBib.FINISH then
			local row = tRunning:GetNbRows()-1;
			if tostring(params.bib) == tRunning:GetCell('Dossard', row) then
				-- Uniquement pour le coureur en course le plus proche de l'arrivée 
				tickcount_inter = app.GetTickCount(); 
				state = stateBib.INTER;
				Board_InterTime(params.bib, idPassage, params.total_time, params.total_rank, params.total_diff);
			end
		end
	end
end

function OnNotifyForerunnerTimeBibTime(key, params)
	local idPassage = tonumber(params.passage) or -99;
	finish_time = params.time or 0;

	if idPassage == -1 and device.entite == 'ESF' and finish_time > 0 then
	
		-- Arrivée Ouvreur ...
		tickcount_finish = app.GetTickCount(); 
		state = stateBib.FINISH;
		
		ResetArrayField(templateFields);
		
		local bib = params.bib or '';
		local nom = params.nom or '';
		local prenom = params.prenom or '';
			
		AddField(templateFields, 'bib_finish', params.bib or '');
		AddField(templateFields, 'identity_finish', nom..' '..prenom);
		
		if finish_time > 0 and finish_time < 10000 then
			AddFieldClientData(templateFields, 'time_finish', app.TimeToString(finish_time, "%xs.%2f"), finish_time);
		else
			AddFieldClientData(templateFields, 'time_finish', app.TimeToString(finish_time, "%-1h%-1m%2s.%2f"), finish_time);
		end
		AddField(templateFields, 'rank_finish', 'OUV');
		
		RefreshFields(templateFields);
	end
end

-- Fermeture
function device.OnClose()
	-- Fermeture Timer
	if timerRacer ~= nil then timerRacer:Delete() end
	if timerList ~= nil then timerList:Delete() end

	if displayBoard ~= nil then
		local mgr = app.GetAuiManager();
		mgr:DeletePane(displayBoard);
	end
	
	-- Appel OnClose Metatable
	mt_device.OnClose();
end

function OnTimer(evt)
	if boardIsFullList(displayBoard:MatrixGetMode()) then return end 

	if state == stateBib.RUNNING then
		if tRunning ~= nil and tRunning:GetNbRows() > 0 then
			local row = tRunning:GetNbRows()-1;
			
			local timeNow = app.Now() + offsetTime;
			local timeStart = tRunning:GetCellInt('Heure_depart_reelle', row, -1);
			if timeStart >= 0 and timeNow > timeStart then
				Board_RunningTime(timeNow-timeStart);
			end
		end
	elseif state == stateBib.INTER then
		local tickCount = app.GetTickCount();
		if tickCount - tickcount_inter >= displayBoard:MatrixGetDelayInter() then
			tickcount_inter = 0;
			state = stateBib.RUNNING;
		end
	elseif state == stateBib.FINISH then
		local tickCount = app.GetTickCount();
		if tickCount - tickcount_finish >= displayBoard:MatrixGetDelayFinish() then
			infoFinish = infoFinish or {};
			if #infoFinish > 0 then
				tickcount_finish = app.GetTickCount(); 
				if infoFinish[1].medal ~= nil then
					Board_FinishMedal(infoFinish[1].bib, infoFinish[1].medal);
				else
					Board_FinishTime(infoFinish[1].bib, infoFinish[1].chrono, infoFinish[1].rank, infoFinish[1].diff);
				end
				table.remove(infoFinish,1);
			else
				state = stateBib.RUNNING;
				tickcount_finish = 0;
			end
		end
	end
end

function OnTimerList(evt)
	Board_List();
end

-- Chargement des informations liées au dossard
function device.BibLoad(bib)
	local rc, bibLoad = app.SendNotify("<bib_load>", { bib = bib });
	if rc and type(bibLoad) == 'table' then
		return bibLoad.ranking;
	else
		return nil;
	end
end

function Board_InterTime(bib, inter_passage, inter_time, rk, diff)
	if boardIsFullList(displayBoard:MatrixGetMode()) then return end 

	bib = tonumber(bib) or 0;
	if bib <= 0 then return end

	inter_time = inter_time or 0;
	if inter_time <= 0 then
		return 
	end

	inter_passage = inter_passage or 0;
	if inter_passage <= 0 then return end
	
	local row = tRunning:GetNbRows()-1;
	if row < 0 then return end
	
	ResetArrayField(templateFields);
	AddField(templateFields, 'bib_inter', bib);
	AddField(templateFields, 'identity_inter', GetIdentity(tRunning, row));

	if inter_time > 0 and inter_time < 10000 then
		AddFieldClientData(templateFields, 'time_inter', app.TimeToString(inter_time, "%2s.%2f"), inter_time);
	else
		AddFieldClientData(templateFields, 'time_inter', app.TimeToString(inter_time, "%-1h%-1m%2s.%2f"), inter_time);
	end
	
	if type(diff) == 'number' then
		AddField(templateFields, 'diff_inter', app.TimeToString(tonumber(diff), '[DIFF]%xs.%2f'));
	end
	
	RefreshFields(templateFields);
end

-- Affichage de la Médaille à la place du Temps (Tableau LG < 12)
function Board_FinishMedal(bib, medal)
	bib = tonumber(bib) or 0;
	if bib <= 0 then return end

	medal = medal or ' - ';

	ResetArrayField(templateFields);
	AddField(templateFields, 'bib_finish', bib);
	AddField(templateFields, 'time_finish', medal);
	RefreshFields(templateFields);
end

function Board_FinishTime(bib, finish_time, rk, diff)
	if boardIsFullList(displayBoard:MatrixGetMode()) then return end 
	
	finish_time = finish_time or 0;
	if finish_time <= 0 and finish_time ~= chrono.DNF and finish_time ~= chrono.DSQ then
		return 
	end

	rk = tonumber(rk) or 0;
	bib = tonumber(bib) or 0;
	
	if bib <= 0 then 
			return
	end	
	
	local bibRanking = device.BibLoad(bib);
	if bibRanking == nil then return end
	
	ResetArrayField(templateFields);
	AddField(templateFields, 'bib_finish', bib);
	AddField(templateFields, 'identity_finish', GetIdentity(bibRanking, 0));
	
	if finish_time > 0 and finish_time < 10000 then
		AddFieldClientData(templateFields, 'time_finish', app.TimeToString(finish_time, "%xs.%2f"), finish_time);
	else
		AddFieldClientData(templateFields, 'time_finish', app.TimeToString(finish_time, "%-1h%-1m%2s.%2f"), finish_time);
	end
	if device.entite == 'ESF' then
		AddField(templateFields, 'medal_finish', bibRanking:GetCell('Medaille'..device.key_current, 0));
	end
	
	if type(diff) == 'number' then
		AddFieldClientData(templateFields, 'diff_finish', app.TimeToString(tonumber(diff), '[DIFF]%xs.%2f'), rk);
	end

	if rk >= 1 then
		AddField(templateFields, 'rank_finish', rk);
	end

	RefreshFields(templateFields);

	-- Maj Liste
	index_list = index_list_prev or 0;
	
	local mode = displayBoard:MatrixGetMode();
	if (mode:find('ranking') or -1) == 1 then
		Board_List();
	end
end

function Board_RunningTime(running_time)
	if displayBoard ~= nil and tRunning ~= nil and tRunning:GetNbRows() > 0 then
		if displayBoard:MatrixGetRunningTime() <= 0 then return end
		
		local row = tRunning:GetNbRows()-1;

		if device.mode_single == false then
			if tRunning:GetCellInt('Tps1', 0, 0) > 0 and string.sub(displayBoard:MatrixGetOptionFinish(), 1, 3) == 'tot' then
				running_time = running_time + tRunning:GetCellInt('Tps1', 0, 0);
			end
		end
		
		ResetArrayField(templateFields);
		AddField(templateFields, 'bib_running', tRunning:GetCell('Dossard', row):upper());
		AddField(templateFields, 'identity_running', GetIdentity(tRunning, row));
		
		if displayBoard:MatrixGetRunningTime() == 100 then
			if running_time < 10000 then
				AddFieldClientData(templateFields, 'time_running', app.TimeToString(running_time, '%xs.%1f'), running_time);
			else
				AddFieldClientData(templateFields, 'time_running', app.TimeToString(running_time, '%-1h%-1m%2s.%1f'), running_time);
			end
		else
			if running_time < 10000 then
				AddFieldClientData(templateFields, 'time_running', app.TimeToString(running_time, '%xs.0'), running_time);
			else
				AddFieldClientData(templateFields, 'time_running', app.TimeToString(running_time, '%-1h%-1m%2s.0'), running_time);
			end
		end
		RefreshFields(templateFields);
	end	
end

function Board_List(bibSelection)
	local mode = displayBoard:MatrixGetMode();
	
	if (mode:find('ranking') or -1) == 1 then
		Board_Ranking(bibSelection);
	elseif (mode:find('last_finish') or -1) == 1 then
		Board_LastFinish();
	elseif (mode:find('startlist') or -1) == 1 then
		Board_Startlist();
	elseif (mode:find('message') or -1) == 1 then
		Board_Message();
	end
	
	if timerList ~= nil and displayBoard:MatrixGetDelayList() > 0 and displayBoard:MatrixGetRowCount() > 2 then
		timerList:StartOnce(displayBoard:MatrixGetDelayList());
	end
end 

function Board_LastFinish()
	local filter = "if Heure_arrivee_reelle ~= nil and Heure_arrivee_reelle > 0 then return true else return false end ";
	local rc, data = app.SendNotify('<ranking_load>', { filter = filter } );
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	
	local tRanking = data.ranking;

	-- Effacement des lignes ...
	displayBoard:MatrixClearRow(2, displayBoard:MatrixGetRowCount()-1);

	-- Tri sur les dernieres arrivées ...
	tRanking:OrderBy('Heure_arrivee_reelle Desc');

	local rowStart = 2;
	local mode = displayBoard:MatrixGetMode();
	if boardIsFullList(mode) then rowStart = 0 end

	ResetArrayField(templateFieldsLastFinish);

	local columnCount = displayBoard:MatrixGetColumnCount();
	local row = rowStart;
	local i = row-rowStart;
	while row <= displayBoard:MatrixGetRowCount()-1 do
		if 	i < tRanking:GetNbRows() then

			local tpsChrono = tRanking:GetCellInt('Tps_chrono'..device.key_current, i, chrono.KO);
			if tpsChrono == chrono.DNF or tpsChrono == chrono.DSQ or tpsChrono > 0 then
				AddField(templateFieldsLastFinish, 'bib', tRanking:GetCell('Dossard',i), row);
				AddField(templateFieldsLastFinish, 'identity', GetIdentity(tRanking, i), row);
				AddField(templateFieldsLastFinish, 'time', tRanking:GetCell('Tps_chrono'..device.key_current, i), row);
				
				if columnCount >= 15 and device.entite == 'ESF' then
					AddField(templateFieldsLastFinish, 'medal', tRanking:GetCell('Medaille'..device.key_current, i), row);
				end
				
				local clt = tRanking:GetCellInt('Clt'..device.key_current, i, -1);
				if clt > 0 then 
					AddField(templateFieldsLastFinish, 'rank', clt, row);
				else
					AddField(templateFieldsLastFinish, 'rank', '');
				end
			end
			i = i + 1;
		else
			AddField(templateFieldsLastFinish, 'rank', clt, row);
			AddField(templateFieldsLastFinish, 'time', '', row);
			AddField(templateFieldsLastFinish, 'bib', '', row);
			AddField(templateFieldsLastFinish, 'identity', '', row);
			if columnCount >= 15 and device.entite == 'ESF' then
				AddField(templateFieldsLastFinish, 'medal', '', row);
			end
		end
		
		if columnCount < 25 then
			row = row + 2;
		else
			row = row +1;
		end
	end
	RefreshFields(templateFieldsLastFinish);
end

function Board_Startlist()
	local rc, data = app.SendNotify('<ranking_load>');
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	
	local tRanking = data.ranking;
	tRanking:OrderBy('Rang'..device.startlist_current..', Dossard');
	
	ResetArrayField(templateFieldsStartlist);
	
	local rowStart = 2;
	local mode = displayBoard:MatrixGetMode();
	if boardIsFullList(mode) then rowStart = 0 end
	
	index_list = index_list or 0;
	if index_list >= tRanking:GetNbRows() then
		index_list = 0;
	end
	
	for row=rowStart,displayBoard:MatrixGetRowCount()-1 do
		if index_list < tRanking:GetNbRows() then
			AddField(templateFieldsStartlist, 'bib',  tRanking:GetCell('Dossard',index_list), row);
			AddField(templateFieldsStartlist, 'identity', GetIdentity(tRanking, index_list), row);
		else
			AddField(templateFieldsStartlist, 'bib', '', row);
			AddField(templateFieldsStartlist, 'identity', '', row);
		end
		index_list = index_list + 1;
	end
	RefreshFields(templateFieldsStartlist);
end

function Board_Ranking(bibSelection)
	local rc, data = app.SendNotify('<ranking_load>');
	assert(rc and data.ranking ~= nil and app.GetNameSpace(data.ranking) == 'sqlTableGC');
	
	local tRanking = data.ranking;
	tRanking:OrderBy('Clt'..device.key_current..', Dossard');
	
	local rowStart = 2;
	local mode = displayBoard:MatrixGetMode();
	if boardIsFullList(mode) then rowStart = 0 end
	
	if bibSelection ~= nil then
		local i = tRanking:GetIndexRow('Dossard', bib) or -1;
		if i >= 0 and i < tRanking:GetNbRows() then
			index_list = i - math.floor(displayBoard:MatrixGetRowCount()-rowStart/2);
		end
	end

	index_list = index_list or 0;
	if index_list < 0 or index_list >= tRanking:GetNbRows() then
		index_list = 0;
	else
		local tpsChrono = tRanking:GetCellInt('Tps_chrono'..device.key_current, index_list, 0);
		if tpsChrono ~= chrono.DNF and tpsChrono ~= chrono.DSQ and tpsChrono <= 0 then
			index_list = 0;
		end
	end
	
	ResetArrayField(templateFieldsRanking);
	index_list_prev = index_list;
	
	for row=rowStart,displayBoard:MatrixGetRowCount()-1 do
		if index_list < tRanking:GetNbRows() then
			local tpsChrono = tRanking:GetCellInt('Tps_chrono'..device.key_current, index_list, chrono.KO);
			if tpsChrono == chrono.DNF or tpsChrono == chrono.DSQ or tpsChrono > 0 then
				local clt = tRanking:GetCellInt('Clt'..device.key_current, index_list, -1);
				if clt > 0 then 
					AddField(templateFieldsRanking, 'rank', tostring(clt), row);
				else
					AddField(templateFieldsRanking, 'rank', '');
				end
				AddField(templateFieldsRanking, 'identity', GetIdentity(tRanking, index_list), row);
				AddField(templateFieldsRanking, 'time', tRanking:GetCell('Tps_chrono'..device.key_current, index_list), row);
			else
				AddField(templateFieldsRanking, 'rank', '', row);
				AddField(templateFieldsRanking, 'identity', '', row);
				AddField(templateFieldsRanking, 'time', '', row);
			end
		end
		index_list = index_list + 1;
	end
	RefreshFields(templateFieldsRanking);
end

function SynchroInitialisation()
	local target = displayBoard:MatrixGetTarget();
	if target == nil or target:len() == 0 then return end

	if target == 'microgate_tab' then
		SynchroInitialisationMicrogateTab(mt_device.obj);
	end
end

function SynchroRow(rowMin, rowMax, fields)

	local rowCount = displayBoard:MatrixGetRowCount();
	local colCount = displayBoard:MatrixGetColumnCount();
	
	rowMin = tonumber(rowMin) or 0;
	rowMax = tonumber(rowMax) or rowCount-1;
	
	if rowMin < 0 then rowMin = 0 end
	if rowMax >= rowCount then rowMax = rowCount-1 end

	displayBoard:MatrixRefreshRow(rowMin, rowMax);

	local target = displayBoard:MatrixGetTarget();
	if target == nil or target:len() == 0 then return end

	if target == 'agil_pi_display' then
		-- Agil PI-DISPLAY
		SynchroFieldsAgilPi(fields);
	elseif target == 'agil_pi_led' then
		-- Agil PI-LED
		SynchroFieldsAgilPiLed(fields);

	elseif target == 'alge_dtrn' then
		-- Alge DTRN
		local txt = '';
		for row=0, rowMin-1 do
			if row ~= 0 then
				txt = txt..string.char(asciiCode.CR);
			end
			txt = txt..displayBoard:MatrixGetText(row, 0, row, colCount-1);
		end
		for row=rowMin, rowMax do
			if row ~= 0 then
				txt = txt..string.char(asciiCode.CR);
			end
			txt = txt..displayBoard:MatrixGetText(row, 0, row, colCount-1);
		end
		SynchroAlgeDTRN(mt_device.obj, txt); 
	elseif target == 'eridan' then
		-- Eridan
		local txt = displayBoard:MatrixGetText(0, 0, rowCount-1, colCount-1);
		SynchroRowEridan(mt_device.obj, 0, txt);
	elseif target == 'microgate_tab' then
		-- Microgate Tab 
		for row=rowMin, rowMax do
				-- Microgate Tab 
			txt = displayBoard:MatrixGetText(row, 0, row, colCount-1);
			local Dossard = displayBoard:MatrixGetText(row, 0, row, colCount-1); 
			local Dossard = Dossard:sub(lgBib,lgBib)		
			-- adv.Alert("Dossard :"..Dossard);
			local DosOuvreur = {"A", "B", "C", "D", "E", "F", "G", "H"};
			for i, k in ipairs(DosOuvreur) do
				if k == Dossard:upper() then
					-- adv.Alert("k:upper() :"..Dossard:upper());
					txt = 'Ouvreur '..Dossard:upper();
				end
			end
			-- adv.Alert("txt :"..txt);
			SynchroMicrogateTab(mt_device.obj, row, txt); 
		end
	elseif target == 'microgate_graph' then
		-- microgate Graph 
		for row=rowMin, rowMax do
			local txt = displayBoard:MatrixGetText(row, 0, row, colCount-1);
			SynchroMicrogateGraph(mt_device.obj, row, txt); 
		end
	elseif target == 'vola_ca8_15' then
		-- Vola CA8-15
		for row=rowMin, rowMax do
			local txt = displayBoard:MatrixGetText(row, 0, row, colCount-1);
			SynchroVolaCA8_15(mt_device.obj, row, txt); 
		end
	elseif target == 'alge_gaz4m' then
		-- Rien à faire à ce niveau pour le Gaz4_Meca, cd fonction SynchroAlgeGaz4meca
	else
		adv.Error('Target Error : '..target);
	end
end

function SynchroEridan(device, txt)
	if device ~= nil then
		device:WriteByte(asciiCode.SI); 	-- SI = 0x0F
		device:WriteByte(32); 				-- espace
		device:WriteByte(asciiCode.SO); 	-- SO = 0x0E
		device:WriteByte(asciiCode.STX);	-- STX = 0x02
		device:WriteByte(32); 				-- espace
		device:WriteString(txt);			-- string 
		device:WriteByte(asciiCode.ETX);	-- ETX = 0x03
		device:WriteByte(asciiCode.HT);		-- HT = 0x09
		return true;
	end
	return false;
end

function SynchroRowEridan(device, row, txt)
	if device ~= nil then
		device:WriteByte(asciiCode.SI); 	-- SI = 0x0F
		device:WriteByte(32+row);
		device:WriteByte(asciiCode.SO); 	-- SO = 0x0E
		device:WriteByte(asciiCode.STX);	-- STX = 0x02
		device:WriteByte(32);	 			-- espace
		device:WriteString(txt);			-- string 
		device:WriteByte(asciiCode.ETX);	-- ETX = 0x03
		device:WriteByte(asciiCode.HT);		-- HT = 0x09
		return true;
	end
	return false
end

function SynchroInitialisationMicrogateTab(device)
	if device ~= nil then
		checkSum = 0;

		device:WriteByte(asciiCode.ESC); 	-- ESC = 0x1b
		checkSum = checkSum + asciiCode.ESC;
		
		device:WriteByte(string.byte('A'));	
		checkSum = checkSum + string.byte('A')
		
		device:WriteByte(string.byte('r'));				-- 'r' => Reset Tableau
		checkSum = checkSum + string.byte('r');
		
		device:WriteByte(asciiCode.ETX);	-- ETX = 0x03
		checkSum = checkSum + asciiCode.ETX;

		-- Checksum sur 7 Bits 
		checkSum = checkSum % 128;
		device:WriteByte(checkSum);			-- CheckSum
		return true;
	end
	
	return false
end

function SynchroMicrogateTab(device, row, txt)
	if device ~= nil then
		local mode = displayBoard:MatrixGetMode();
		if (mode:find('message') or -1) == 1 and microgate_Msg == true then
			txt = microgate_tabMsg..'   ';
			microgate_Msg = false;
		end
		
		checkSum = 0;

		device:WriteByte(asciiCode.ESC); 	-- ESC = 0x1b
		checkSum = checkSum + asciiCode.ESC;
		
		device:WriteByte(65+row);			-- 65 = A => 1er Ligne, B => 2ième Ligne 
		checkSum = checkSum + 65+row;
	-- commande pour faire fonctionner le bandeau deroulant suivant txt:len()) <= 9	
		if tonumber(txt:len()) <= 9 then
			device:WriteByte(string.byte('S'));			-- 'S' => Bandeau Fix
			checkSum = checkSum + string.byte('S');
		else
			device:WriteByte(string.byte('O'));			-- 'O' => Bandeau Défilant
			checkSum = checkSum + string.byte('O');
			bandeaudefilant = true;
		end

		device:WriteByte(string.byte('0'));				-- '00' => Premier caractere gauche
		device:WriteByte(string.byte('0'));
		checkSum = checkSum + string.byte('0') + string.byte('0');
		
		if bandeaudefilant == true then
			local Nbcol = tostring(displayBoard:MatrixGetColumnCount());
			device:WriteByte(string.byte('0')); -- '8' => Nb de colonne interesser
			device:WriteByte(string.byte('9'));
			checkSum = checkSum + string.byte('0') + string.byte('9');
			device:WriteByte(string.byte('1'));			-- '8' => temps de decalage
			device:WriteByte(string.byte('0'));	
			device:WriteByte(string.byte('1'));	
			checkSum = checkSum + string.byte('1') + string.byte('0') + string.byte('1');
		end
	-- commande pour faire fonctionner le bandeau deroulant suivant txt:len()) <= 9	
	
		device:WriteString(txt);			-- Caractères à Ecrire ... 
		for i=1,txt:len() do
			checkSum = checkSum + string.byte(txt,i)
		end
		device:WriteByte(asciiCode.ETX);	-- ETX = 0x03
		checkSum = checkSum + asciiCode.ETX;

		-- Checksum sur 7 Bits 
		checkSum = checkSum % 128;
		device:WriteByte(checkSum);			-- CheckSum
		return true;
	end
	
	return false
end

function SynchroMicrogateGraph(device, row, txt)
	if device ~= nil then
		checkSum = 0;

		device:WriteByte(asciiCode.ESC); 	-- ESC = 0x1b
		checkSum = checkSum + asciiCode.ESC;
		
		device:WriteByte(0x40);				-- Identifiant du tableau 
		checkSum = checkSum + 0x40;
		
		device:WriteByte(string.byte('S'));				-- 'S' => Bandeau Fixe
		checkSum = checkSum + string.byte('S');
	
		-- X : 0
		device:WriteByte(0x00)		
		checkSum = checkSum + 0x00;
		
		device:WriteByte(0x00)		
		checkSum = checkSum + 0x00;

		-- Y : 16pixels 		
		device:WriteByte(row*16)		
		checkSum = checkSum + row*16;
		
		device:WriteByte(0x00)		
		checkSum = checkSum + 0x00;

		device:WriteByte(0x00)		-- Opération Binaire
		checkSum = checkSum + 0x00;
		
		device:WriteByte(0x01)		-- Police Mini
		checkSum = checkSum + 0x01;

		device:WriteString(txt);			-- Caractères à Ecrire ... 
		for i=1,txt:len() do
			checkSum = checkSum + string.byte(txt,i)
		end
		
		device:WriteByte(asciiCode.ETX);	-- ETX = 0x03
		checkSum = checkSum + asciiCode.ETX;

		-- Checksum sur 7 Bits 
		checkSum = checkSum % 128;
		device:WriteByte(checkSum);			-- CheckSum
		return true;
	end
	
	return false
end

function SynchroVolaCA8_15(device, row, txt)

	if device ~= nil then
		local colCount = displayBoard:MatrixGetColumnCount();
		local unitBloc = displayBoard:MatrixGetBlocUnitCount() or 16;
		
		local countBlocRow = 1;
		local dim = unitBloc;
		while colCount > dim do
			countBlocRow = countBlocRow*2;
			dim = dim*2;
		end
		
		local luminosite = '3';

		for blocRow=1, countBlocRow do
			local r = row*countBlocRow + blocRow;
			local start = (blocRow-1)*unitBloc+1;
			if txt:len() >= start then
				local txtBloc = txt:sub(start, start+unitBloc-1);
				device:WriteByte(asciiCode.STX);	-- Debut Trame
				device:WriteString(r);				-- Ligne
				device:WriteString(luminosite);		-- Luminosite
				device:WriteString(txtBloc);		-- Bloc de unitBloc caractères 
				device:WriteByte(asciiCode.LF);		-- Fin de Trame
			end
		end
		return true;
	end
	return false;
end

function SynchroAlgeDTRN(device, txt)
	if device ~= nil then
		local arrayBytes = { 0x4A,0x57,0x00,0x00 };

		for i=1,txt:len() do
			table.insert(arrayBytes, string.byte(string.sub(txt,i,i)));
		end
		device:WriteByte(arrayBytes);
		return true;
	end
	
	return false;
end

function SynchroAlgeGaz4meca(fields)

	local bibGaz4 = '';	
	local timeGaz4 = '';
	local rkGaz4 = '  '; -- bien laisser les 2 espaces pour le tps tournant
	
	for i=1,#fields.array do
		local item = fields.array[i];
		local field = fields[item.code];
	
		local txtValue = item.txt;
		local condition = true;
		if type(field) == 'table' then
			if type(field.condition) == 'function' then
				condition = field.condition(item.txt);
			end
			txtValue = GetFieldText(field, item.txt);
		end

		if condition == true then
			if item.code == "bib_running" or item.code == "bib_finish" or item.code == "bib_inter" then
				-- Dossard positif sur 3 caractères ...
				local bib = tonumber(txtValue) or 0;
				if bib > 0 then
					bibGaz4 = string.format('%3d', bib);
					if item.code == "bib_running" then
						bibGaz4 = bibGaz4..'C   ';
					else
						bibGaz4 = bibGaz4..'D   ';
					end
				end
			elseif item.code == "time_finish" or item.code == "time_inter" then
				local timems = tonumber(item.client_data) or 0;
				timeGaz4 = app.TimeToString(timems, "%2h:%2m:%2s.%3f");
			elseif item.code == "time_running" then
				local timems = tonumber(item.client_data) or 0;
				timeGaz4 = app.TimeToString(timems, "%2h:%2m:%2s.000");
			elseif item.code == "rank_finish" or item.code == "rank__inter" then
				rkGaz4 = txtValue;
				rkGaz4 = string.format('%2d', tonumber(rkGaz4) or 99)
				--adv.Alert("txtValue :"..txtValue);
			end
		end
	end

	local device = mt_device.obj;
	if device ~= nil and bibGaz4:len() > 0 and timeGaz4:len() > 0 then
		adv.Alert("GAZ4 :"..bibGaz4..timeGaz4..rkGaz4);
		device:WriteString(bibGaz4..timeGaz4..rkGaz4);
		device:WriteByte(asciiCode.CR);
		device:WriteByte(asciiCode.LF);
		return true;
	else
		return false;
	end
end
