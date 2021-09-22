-- Stade Permanent
dofile('./interface/uty.lua');
dofile('./interface/interface.lua');
dofile('./interface/device.lua');

-- http://alpina-contest.ch/set_passage.php?code_barre=E007000029E9A090&temps=44.23

format = "%-1h%-1m%2s.%2f";

stade = {};

-- Temps Chrono entre 18 et 60 secondes ...
stade.chrono_min = 18000;
stade.chrono_max = 60000;

-- Temps pour Prendre le départ entre 2 et 30 secondes
stade.start_min = 2;
stade.start_max = 30;

-- Prise des URL
stade.url_alpina = 'http://alpina-contest.ch/';
stade.url_trinum = 'http://192.168.2.229:8080/';

stade.url_display_start = 'http://';
stade.url_display_finish = 'http://';

function Error(txt)
	stade.message:AddLineError(txt);
end

function Info(txt)
	stade.message:AddLine(txt);
end

function Success(txt)
	stade.message:AddLineSuccess(txt);
end

function Warning(txt)
	stade.message:AddLineWarning(txt);
end

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 1.3, 
		code = 'stade', 
		name = 'Stade Permanent', 
		class = 'display',
		interface = {}
	};
end	

-- Ouverture de device : initialisation
function device.OnInit(params)

	-- notification à prendre en compte 
	app.BindNotify("<passage_insert>", OnPassageInserted);
	
	-- Creation Frame 
	stade.frame = wnd.CreateFrame({
		icon = "./res/32x32_chrono.png",
		label = "Stade Permanent",
		width = 450,
		height = 150
	});

	-- GridMessage
	stade.message = wnd.CreateGridMessage({ parent = stade.frame });

	-- Creation Sizer et Positionnement des controles
	local bs = sizer.CreateBoxSizer(wndDirection.VERTICAL);
	bs:Add(stade.message, { proportion = 1, m_expand=true });
	stade.frame:SetSizer(bs);

	-- Connexion à la base
	stade.db = sqlBase.Clone();
end


-- OnPassageInserted
function OnPassageInserted(key, params)

	if tonumber(params.passage) == 0 then
		-- Départ
		SetStart(tonumber(params.time));
	end

	if tonumber(params.passage) == -1 then
		-- Arrivée
		SetFinish(tonumber(params.time));
	end

	-- Info("OnPassageInserted : Key="..key..",params="..type(params));
	-- if type(params) == "table" then
		-- for k, v in pairs(params) do
			-- if type(v) == "userdata" then
				-- Info("Key "..k.."=userdata");
				-- for i=0,v:GetNbRows() do
					-- local txt = '';
					-- for j=0, v:GetNbColumns() do
						-- txt = txt..v:GetCell(j,i)..'*';
					-- end	
					-- Info(txt);
				-- end
				-- v:Delete();
			-- else
				-- Info("Key "..k.."="..v);
			-- end
		-- end
	-- end
end

function SetStart(chronoStart)

	if chronoStart <= 0 then
		return false;
	end
	
	local now = os.time();
	local dateMax = os.date('%Y-%m-%d %H:%M:%S', now - stade.start_min);
	local dateMin = os.date('%Y-%m-%d %H:%M:%S', now - stade.start_max);

	local cmd = "Select * from stade_chrono Where Chrono_start <= 0 And Chrono_finish <= 0 "..
				"And Creation >= '"..dateMin.."' "..
				"And Creation <= '"..dateMax.."' "..
				"Order By Id Asc ";

	local tStadeChrono = stade.db:GetTable('stade_chrono');
	stade.db:TableLoad(tStadeChrono, cmd);
	if tStadeChrono:GetNbRows() > 0 then
		local TAGIT = tStadeChrono:GetCell("TAGIT",0);
		Success("DEPART : RFID "..TAGIT.." => "..app.TimeToString(chronoStart, "%-1h%-1m%2s.%3f"));
		cmd = "Update stade_chrono Set Chrono_start = "..tostring(chronoStart).." Where Id = "..tStadeChrono:GetCell("Id",0);
		stade.db:Query(cmd);
		
		local url = stade.url_trinum..'getchrono?NUM=1&POS=D&TAGIT='..TAGIT;
		curl.GET(url);
		Success("URL TRINUM DEPART : "..url);
		
		-- AFFICHEUR AGIL DEPART : On Efface 
		cmd = "Update stade_start_info Set Info = '    ' ";
		stade.db:Query(cmd);
		return true;
	end

	Warning("DEPART : Aucun RFID pour l'heure de départ à "..app.TimeToString(chronoStart, "%-1h%-1m%2s.%3f"));
	return false;
end

function SetFinish(chronoFinish)
	if chronoFinish <= 0 then
		return false;
	end

	local cmd = "Select * from stade_chrono Where Chrono_start > 0 And Chrono_finish <= 0 "..
				"Order By Id Asc ";

	local tStadeChrono = stade.db:GetTable('stade_chrono');
	stade.db:TableLoad(tStadeChrono, cmd);
	
	for i=0,tStadeChrono:GetNbRows()-1 do
		local chronoStart = tStadeChrono:GetCellInt("Chrono_start",i);
		if chronoFinish > chronoStart then
			local chrono = chronoFinish - chronoStart;
			if chrono > stade.chrono_min and chrono < stade.chrono_max then
			
				local cmd = "Update stade_chrono Set Chrono_finish = "..tostring(chronoFinish)..
							", Chrono = "..tostring(chrono).." "..
							"Where Id = "..tStadeChrono:GetCell("Id",i);
				stade.db:Query(cmd);
				
				local TAGIT = tStadeChrono:GetCell("TAGIT",i);
				local TPS = app.TimeToString(chrono,"%-1h%-1m%2s.%2f");
				Success("ARRIVEE : RFID "..TAGIT.." => "..app.TimeToString(chronoFinish, "%-1h%-1m%2s.%3f")..", TPS="..TPS);
				
				-- TRINUM ARRIVEE
				local url = stade.url_trinum..'getchrono?NUM=1&POS=A&TAGIT='..TAGIT..'&TPS='..tostring(chrono);
				curl.GET(url);
				Success("URL TRINUM ARRIVEE : "..url);
				
				-- AFFICHEUR AGIL ARRIVEE : Enregistrement du Temps
				cmd = "Update stade_finish_time Set Time = '"..TPS.."' ";
				stade.db:Query(cmd);
				
				-- ALPINA 
				url = stade.url_alpina..'set_passage.php?code_barre='..TAGIT..'&temps='..TPS;
				Success("URL ALPINA : "..url);
				return true;
			end
		end
	end

	Warning("ARRIVEE : Aucun RFID pour l'heure d'arrivée "..app.TimeToString(chronoFinish, "%-1h%-1m%2s.%3f"));
	return false;
end

function GetYYYYMMDDHHMMSS()
	return os.date('%Y-%m-%d %H:%M:%S', os.time());
end

	
	
