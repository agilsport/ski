-- RaceresultWebServeur gere systeme Actif et Passif 
-- connection ethernet entre le decodeur et l'ordi en IP Fixe obligatoire
-- systeme Actif gestion de 8 N° de Loop  et 8 N° de canal sur un memes decodeur 
-- Gestion du comptage de nombre de tour de pena si on active le couttourpena sur une boucle
-- aller dans gestion des options
-- Gestion de table de corespondance Généric a tt les évènements ou gestion de table propre à l'évènement traiter
-- dans les deux cas la mm table sert a plusieurs décodeur sur le memes EVT

dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface, adresse IP, N° de port donné par race result
function device.GetInformation()
	return { 
		version = 7.3, 
		code = 'raceresult', 
		name = 'Raceresult', 
		class = 'chrono', 
		interface = { { type='tcp', hostname = '192.168.1.214', port = 3601 } } 
	};
end	

-- Creation et initialisation table raceresult
raceresult = {};

-- Timer 
raceresult.timerDelay = 500;

-- Timer 
raceresult.timerDelayConnect = 10000;

-- Racings
raceresult.alive = 0;

-- Code Competition 
raceresult.code_competition = -1;

-- Actif ou pas
raceresult.ActiveStart = "Non Actif";

-- status
raceresult.GetStatus = "Ko";

-- nb de lignes 
nbLignes = 0;

-- Nb de tour
NbTourRealiser = 0;

--activation de la fonction debugage
debugage = false;

-- numero de passage ou le decodeur doit envoyer le chrono par default
passage = '';

function Alert(txt)
	raceresult.gridMessage:AddLine(txt);
end

function Success(txt)
	raceresult.gridMessage:AddLineSuccess(txt);
end

function Warning(txt)
	raceresult.gridMessage:AddLineWarning(txt);
end

function Error(txt)
	raceresult.gridMessage:AddLineError(txt);
end

-- Ouverture
function device.OnInit(params, node)

	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	theParams = params;
	node = node;
	
	RaceResultfile = node:GetAttribute('config_NumFichier');  --171 comtien des detections
	passage = node:GetAttribute('config_Passage');  -- N° de passage 0 depart, -1 arrivée, 1..2..3 N° inter
	
	-- Creation Panel
	local panel = wnd.CreatePanel({ parent = app.GetAuiFrame() });
	panel:LoadTemplateXML({ 
		xml = './device/raceresult.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'dashboard'
	});

	-- initialisation de la table raceresult
	raceresult.dbSki = sqlBase.Clone();
	TabletagID_Passings = raceresult.dbSki:GetTable('tagID_Passings');
	TabletagID_Correspondance = raceresult.dbSki:GetTable('tagID_Correspondance');
	TableTagID_Finish = raceresult.dbSki:GetTable('tagID_Finish');
	TabletagID_Tour = raceresult.dbSki:GetTable('tagID_Tour');
	TabletagID_TourPena = raceresult.dbSki:GetTable('tagID_TourPena');
	
	raceresult.panel = panel;
	
	-- Initialisation des Controles 
	raceresult.gridMessage = panel:GetWindowName('message');
	
	-- ToolBar
	raceresult.tb = panel:GetWindowName('tb');
	raceresult.tb_start = raceresult.tb:AddTool("Start", "./res/32x32_chrono_v3.png");
	raceresult.tb_outil = raceresult.tb:AddTool("Outil RaceResult", "./res/32x32_configure.png", "outils",  itemKind.DROPDOWN);
	raceresult.tb_OnGestionTableCorres = raceresult.tb:AddTool("Import table corespondance", "./res/32x32_divide_column.png");
	raceresult.tb_Param = raceresult.tb:AddTool("Prametrage", "./res/32x32_config.png", "Parametrage plage dossards relais",  itemKind.DROPDOWN);
	raceresult.tb:AddSeparator();
	
---- Sous menu table outils
	local menuSend =  menu.Create();
	menuSend:AppendSeparator();	
	raceresult.tb_outil_ping = menuSend:Append({label="Test Connection décodeur ?", image ="./res/32x32_time-admin.png"});
	menuSend:AppendSeparator();
	raceresult.tb_outil_mode = menuSend:Append({label="Ligne de Détection Active ou pas ?", image ="./res/vpe32x32_search.png"});
	menuSend:AppendSeparator();
	raceresult.tb_outil_protocol = menuSend:Append({label="Protocol du decodeur utilisé ?", image ="./res/32x32_tasks.png"});
	menuSend:AppendSeparator();	
	raceresult.tb_outil_status = menuSend:Append({label="Status du décodeur 'on/off", image ="./res/chrono32x32_traffic_light.png"});
	menuSend:AppendSeparator();	
	raceresult.tb_outil_passings = menuSend:Append({label="Nb de Passings enregistrer ds le décodeur ?", image ="./res/32x32_time-admin.png"});
	menuSend:AppendSeparator();	
	raceresult.tb_outil_gettime = menuSend:Append({label="heure du décodeur ?", image ="./res/chrono32x32_clock_inter.png"});
	menuSend:AppendSeparator();	
	raceresult.tb_outil_OnChargeBat = menuSend:Append({label="Niveau de Charge Batterie", image ="./res/32x32_battery_half.png"});
	menuSend:AppendSeparator();
	raceresult.tb_outil_OnDebug = menuSend:Append({label="Fonction de Debugage", image ="./res/32x32_lua.png"});
	menuSend:AppendSeparator();
	raceresult.tb_outil_OnRechargeTagId = menuSend:Append({label="Rechargement Séquence", image ="./res/32x32_update.png"});
	menuSend:AppendSeparator();
	raceresult.tb_outil_OnStartOperation = menuSend:Append({label="Activation Antenne de détection", image ="./res/32x32_antenna.png"});
	menuSend:AppendSeparator();
	raceresult.tb_outil_OnStopOperation = menuSend:Append({label="Désactivation Antenne de détection", image ="./res/32x32_stop.png"});
	raceresult.tb:SetDropdownMenu(raceresult.tb_outil:GetId(), menuSend);
	
---- Sous menu parametre	
	local menuSend =  menu.Create();
	menuSend:AppendSeparator();	
	raceresult.tb_Param_Options = menuSend:Append({label="Configuration des options (Nb Tour / Passage) ", image ="./res/32x32_options.png"});
	menuSend:AppendSeparator();	
	raceresult.tb_Param_TagIdFinish = menuSend:Append({label="Vider la Table des tagID déjà arrivés ", image ="./res/32x32_background.png"});
	menuSend:AppendSeparator();
	raceresult.tb_Param_tagID_TourPena = menuSend:Append({label="Vider la Table de memo des nb de tours de Péna fait ", image ="./res/32x32_background.png"});
	menuSend:AppendSeparator();
	raceresult.tb_Param_Passing = menuSend:Append({label="Mise a zéro du compteur passing", image ="./res/32x32_update.png"});
	menuSend:AppendSeparator();
	raceresult.tb_Param_Socket = menuSend:Append({label="Réinitialisation de la connection au décodeur", image ="./res/32x32_postition_horizontal.png"});
	raceresult.tb:SetDropdownMenu(raceresult.tb_Param:GetId(), menuSend);
	
	-- Static Connect
	raceresult.Connect = wnd.CreateStaticText({parent = raceresult.tb, label = "Test Connect", style = wndStyle.ALIGN_LEFT});
	raceresult.Connect:SetLabel("Non Connect");
	raceresult.tb:AddControl(raceresult.Connect);
	raceresult.tb:AddSeparator();	
	
	-- Static Info
	raceresult.info = wnd.CreateStaticText({parent = raceresult.tb, label = "Timer : ------  Passings : ----/----", style = wndStyle.ALIGN_LEFT});
	raceresult.tb:AddControl(raceresult.info);
	raceresult.tb:AddSeparator();	

	-- Niveau de Batterie
	raceresult.battery = wnd.CreateStaticText({parent = raceresult.tb, label = "Charge Bat =---%", style = wndStyle.ALIGN_LEFT});
	raceresult.tb:AddControl(raceresult.battery);
	raceresult.tb:Realize();

	-- Prise des Evenements (Bind)onglet principal
	raceresult.panel:Bind(eventType.MENU, OnStartRaceResult, raceresult.tb_start);
	raceresult.panel:Bind(eventType.MENU, OnraceResultOutils, raceresult.tb_outil);
	raceresult.panel:Bind(eventType.MENU, OnOpenTableCorespondance, raceresult.tb_OnGestionTableCorres);
	raceresult.panel:Bind(eventType.MENU, OnParamko, raceresult.tb_Param);
	-- onglet du sous menu outil 
	raceresult.panel:Bind(eventType.MENU, OnPing, raceresult.tb_outil_ping);
	raceresult.panel:Bind(eventType.MENU, OnMode, raceresult.tb_outil_mode);
	raceresult.panel:Bind(eventType.MENU, OnProtocol, raceresult.tb_outil_protocol);
	raceresult.panel:Bind(eventType.MENU, OnStatus, raceresult.tb_outil_status);
	raceresult.panel:Bind(eventType.MENU, OnPassings, raceresult.tb_outil_passings);
	raceresult.panel:Bind(eventType.MENU, OnGetTime, raceresult.tb_outil_gettime);
	raceresult.panel:Bind(eventType.MENU, OnChargeBat, raceresult.tb_outil_OnChargeBat);
	raceresult.panel:Bind(eventType.MENU, OnDebug, raceresult.tb_outil_OnDebug);
	raceresult.panel:Bind(eventType.MENU, OnRechargeTagId, raceresult.tb_outil_OnRechargeTagId);
	raceresult.panel:Bind(eventType.MENU, OnStartOperation, raceresult.tb_outil_OnStartOperation);
	raceresult.panel:Bind(eventType.MENU, OnStopOperation, raceresult.tb_outil_OnStopOperation);
	
-- onglet du sous menu outil 
	raceresult.panel:Bind(eventType.MENU, OnOpenOptions, raceresult.tb_Param_Options);
	raceresult.panel:Bind(eventType.MENU, OnDeleteTagIdFinish, raceresult.tb_Param_TagIdFinish);
	raceresult.panel:Bind(eventType.MENU, OnDeleteTagIdTourPena,raceresult.tb_Param_tagID_TourPena);
	raceresult.panel:Bind(eventType.MENU, OnClearPassing, raceresult.tb_Param_Passing);
	raceresult.panel:Bind(eventType.MENU, OnReOpenSocket, raceresult.tb_Param_Socket);
		
-- Chargement des Informations de la Course ...
	raceresult.code_competition = -1;
	local rc, raceInfo = app.SendNotify('<race_load>');
	if rc == true then
		local tEvenement = raceInfo.tables.Evenement;
		raceresult.code_competition = tEvenement:GetCellInt('Code', 0);
		raceresult.code_manche = raceInfo.Code_manche or 1 ;
		Success('Compétition '..tostring(raceresult.code_competition)..' ok ..');
	end
	
-- Recherche et creation d'une variable pour l'Adresse IP et le port utilser pour le decodeur actif OK
	local sockClient = mt_device.obj;
	local tPeer = sockClient :GetPeer();
	ActiveID = tPeer.ip;
	ActivePort = tPeer.port;
	--Alert("ActiveID :"..ActiveID..ActivePort);	
	
-- Recherche si un evenement existe dans la table tagID_Passings OK
	cmd = "Select * From tagID_Passings Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'";
	TableTagID_Passings = raceresult.dbSki:GetTable('tagID_Passings');
	raceresult.dbSki:TableLoad(TableTagID_Passings, cmd);	
	
	if TableTagID_Passings:GetNbRows() == 0 then
		Alert("pas d'évènement Dans la table tagID_Passings on la créer");
		
-- creation de la variable Passing Current (nb de transpondeur detecter dans la ligne chrono)		
	raceresult.passingCurrent = 0;
	
-- creation de variables TypeTable et CodeTypeTable(permetant de travailler une table générique a tt les evt ou une table spécifique à l'EVT)
	if passage == '' then passage = -1	end
	LoopID = 'Loop0';
	LoopCanal = 'LoopCanal0';
	TypeTable = 'ND';
	CountTourActif = 0;
	SystemeActif = 0;
	CodeTypeTable = raceresult.code_competition;
	ID_1er_Inter = 1;
--delai double detection
	DelayDoubleDetect = 600000;  -- = à 10 minutes   ///  60000 = à 1 min
	
-- ecriture des parametres dans la tagID_Passings et du type table
	AddTabletagID_Passings(raceresult.code_competition,ActiveID,ActivePort,LoopID,LoopCanal,passage,ID_1er_Inter,raceresult.passingCurrent,TypeTable,DelayDoubleDetect,CountTourActif);		
		Warning("pas de table de corespondace pour cet évènement ...");
		Warning("Penser à aller dans l'onglet gestion pour importer une table avant de chronometrer...");
	else
-- si il y a une ligne dans tagID_Passings On prend les valeurs de la table pour renseigner les variables 
		raceresult.passingCurrent = TableTagID_Passings:GetCellInt('Passings', 0);
		--Alert("raceresult.passingCurrent ="..raceresult.passingCurrent);
		TypeTable = TableTagID_Passings:GetCell('TypeTable', 0);
		passage = TableTagID_Passings:GetCell('passage', 0);
		ID_1er_Inter = TableTagID_Passings:GetCell('ID_1er_Inter', 0);
		-- DelayDoubleDetect = TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
		--Alert("raceresult.passingCurrent ="..raceresult.passingCurrent.."/ TypeTable :"..TypeTable);
			if TypeTable == 'GEN' then
				CodeTypeTable = 0;
			else
				CodeTypeTable = raceresult.code_competition ;
			end
	end
	
	-- On recherche si il y a une ou plusieurs lignes de créer ds la table TabletagID_Tour pour l'evt
	-- Si pas de ligne on inscrit dans latable	
	cmd = "Select * From tagID_Tour Where Code = '"..raceresult.code_competition.."' and AdresseIP = '"..ActiveID.."' Order by bibMini";
	if raceresult.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows() == 0 then
		local bibMini = 1;
		local bibMax = 9999;
		local LoopID = 'Loop0';
		local LoopCanal = 'LoopCanal0';
		local Tour = 0;
		AddTabletagID_Tour(raceresult.code_competition,ActiveID,bibMini,bibMax,LoopID,LoopCanal,Tour);
	end
-- Recherche si une table de corespondance existe dans la table tagID_Correspondance
	cmd = "Select * From tagID_Correspondance Where Code = "..CodeTypeTable.." Order by Dossard";
	if raceresult.dbSki:TableLoad(TabletagID_Correspondance, cmd):GetNbRows() == 0 then
		Alert("pas de Table de correspondance pour cet évènement : "..raceresult.code_competition);
	else
	-- Alert("TypeTable ="..TypeTable);
		if TypeTable == 'GEN' then
			Alert("Utilisation de la table Générique pour l'EVT  : "..raceresult.code_competition.." avec "..TabletagID_Correspondance:GetNbRows().." lignes créées");
		elseif TypeTable == 'EVT' then
			Alert("Utilisation de la table spécifique à l'évènement N°: "..raceresult.code_competition.." avec "..TabletagID_Correspondance:GetNbRows().." lignes créées");
		else
			Alert("pas de table de corespondance pour l'EVT  : "..raceresult.code_competition);
		end	
	end
			
-- creation de la variables PassingCount (nb de transpondeur detecter par la ligne chrono)
		raceresult.passingCount = 0;
		--Alert("passingCurrent :"..raceresult.passingCurrent.."/ "..raceresult.passingCount);

rechercheHeureDepartDos = rechercheHeureDepartDos(1)

Alert("rechercheHeureDepartDos : "..rechercheHeureDepartDos);
-- Affichage ...
	panel:Show(true);
	
	local mgr = app.GetAuiManager();
	mgr:AddPane(panel, {
		icon = './res/Mini-logo-raceresult.png',
		caption = "Tableau de Bord Race Result / "..ActiveID,
		caption_visible = true,
		close_button = false,
		pin_button = true,
		show = true,

		float = true, 
		-- position de la fenetre a l'ouverture {horizontal , verticale}
		floating_position = {1000, 40},
		-- taille de la {fenetre L , H}
		floating_size = {700, 300},
		dockable = false
		
	});

	mgr:Update();
	
	-- Creation du Timer connect pour la baterie
	raceresult.timerConnect = timer.Create(raceresult.panel);
	if raceresult.timerConnect ~= nil then
		raceresult.timerConnect:Start(raceresult.timerDelayConnect);
	end
	raceresult.panel:Bind(eventType.TIMER, OnTimerBatConnect, raceresult.timerConnect);
	
	
	--local toto = GetHeurePassage(32, 0);

end


-- Fermeture
function device.OnClose()
	raceresult.Stop = true;
	
	if raceresult.panel ~= nil then
		-- On Ignore les "event" qui peuvent encore être dans la pile ...
		raceresult.panel:UnbindAll();
	end

	if raceresult.timer ~= nil then
		raceresult.timer:Delete();
	end
	
	if raceresult.timerConnect ~= nil then
		raceresult.timerConnect:Delete();
	end
	
	if raceresult.watchDogConnect ~= nil then
		raceresult.watchDogConnect:Delete();
	end
	
	if Table ~= nil then
		Table:Delete();
	end
	
	if Steph ~= nil then
		Steph:Delete();
	end
	
	if raceresult_option ~= nil then
		raceresult_option:Delete();
	end
	
	if raceresult_param ~= nil then
		raceresult_param:Delete();
	end
	if raceresult_Exit ~= nil then
		raceresult_Exit:Delete();
	end
	
	if raceresult.panel ~= nil then
		local mgr = app.GetAuiManager();
		mgr:DeletePane(raceresult.panel);
	end

-- Appel OnClose Metatable
	mt_device.OnClose();
end

-- insert d'une ligne dans la table TabletagID_Tour
function AddTabletagID_Tour(Code,AdresseIP,bibMini,bibMax,LoopID,LoopCanal,Tour)
			local r = TabletagID_Tour:AddRow();
				TabletagID_Tour:SetCell("Code", r, tonumber(Code));
				TabletagID_Tour:SetCell("AdresseIP", r, AdresseIP);
				TabletagID_Tour:SetCell("bibMini", r, tonumber(bibMini));		
				TabletagID_Tour:SetCell("bibMax", r, tonumber(bibMax));
				TabletagID_Tour:SetCell("LoopID", r, LoopID);
				TabletagID_Tour:SetCell("LoopCanal", r, LoopCanal);
				TabletagID_Tour:SetCell("Tour", r, tonumber(Tour));
				raceresult.dbSki:TableInsert(TabletagID_Tour, r);
end 

-- insert d'une ligne dans la table TabletagID_Passings
function AddTabletagID_Passings(Code,AdresseIP,ActivePort,LoopID,LoopCanal,passage,ID_1er_Inter,Passings,TypeTable,DelayDoubleDetect,CountTourActif);			
				local r = TabletagID_Passings:AddRow();				
				TabletagID_Passings:SetCell("Code", r, tonumber(Code));
				TabletagID_Passings:SetCell("AdresseIP", r, ActiveID);
				TabletagID_Passings:SetCell("Port", r, tonumber(ActivePort));
				TabletagID_Passings:SetCell("LoopID", r, LoopID);
				TabletagID_Passings:SetCell("LoopCanal", r, LoopCanal);
				TabletagID_Passings:SetCell("passage", r, tonumber(passage));
				TabletagID_Passings:SetCell("ID_1er_Inter", r, tonumber(ID_1er_Inter));
				TabletagID_Passings:SetCell("Passings", r, tonumber(Passings));
				TabletagID_Passings:SetCell("TypeTable", r, TypeTable);
				TabletagID_Passings:SetCell("DelayDoubleDetect", r, DelayDoubleDetect);
				TabletagID_Passings:SetCell("CountTourActif", r, tonumber(CountTourActif));
				raceresult.dbSki:TableInsert(TabletagID_Passings, r);
end
-- Evénement Timer 
function OnTimer(evt)
	--Alert("on passe dans le timer");
	--Alert("passingCurrent :"..tostring(raceresult.passingCurrent).."/ "..tostring(raceresult.passingCount));
	raceresult.alive = raceresult.alive + 1;
	
	raceresult.info:SetLabel("Timer :"..tostring(raceresult.alive).." Passings : "..tostring(raceresult.passingCurrent)..'/'..tostring(raceresult.passingCount));
	--Alert("passing count = "..tonumber(raceresult.passingCount).."passingCurent = ".. tonumber(raceresult.passingCurrent));
	local sockClient = mt_device.obj;
	-- si le Nb de passing ds skiffs est > au nb de passing du decodeur on envoi juste la commande passings au decodeur pour qu'il nous renvoi le count
	if tonumber(raceresult.passingCurrent) >= tonumber(raceresult.passingCount) then
		-- Command PASSINGS 
		sockClient:WriteString("PASSINGS");
		sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
		-- Alert("raceresult.passingCount nb de detect lu par race result"..raceresult.passingCurrent.." >= "..raceresult.passingCount.."le nb de detection ds la ligne chrono");
	else
	-- si le count est > au pasing currant 
		-- Command PASSAGE INDIVIDUEL
		--Alert("raceresult.passingCount :"..raceresult.passingCount);--nb de detection ds la ligne chrono
		--Alert("raceresult.passingCurrent :"..raceresult.passingCurrent);--nb de passings dans skiffs
		local NbpassingsDecodeur = tonumber(raceresult.passingCount) - tonumber(raceresult.passingCurrent);
		--Alert("test NbpassingsDecodeur :"..NbpassingsDecodeur);
		if tonumber(NbpassingsDecodeur) == 1 then
		--Alert("NbpassingsDecodeur :"..NbpassingsDecodeur);
		sockClient:WriteString(tonumber(raceresult.passingCurrent+1));
		sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
		elseif tonumber(NbpassingsDecodeur) <= 0 then
-- Alert("NbpassingsDecodeur multiple :"..NbpassingsDecodeur);
		else
		-- Obtenez plusieurs passes
		-- Afin de recevoir plusieurs passages, l'hôte envoie
		-- <S>: <C> <CrLf>
		-- où <S> est le numéro de passage du premier passage à envoyer 
		-- et <C> le nombre de passages à envoyer.

		-- demande au décodeur de renvoyer tout les passings entre le count le le passingsCurent de skiffs
		-- evite d'avoir un bug lors de l'utilisation de la fonction OnClearPassing
		--Alert("NbpassingsDecodeur multiple :"..NbpassingsDecodeur);
		if tonumber(raceresult.passingCurrent) == 0 then 
		sockClient:WriteString(tonumber(raceresult.passingCurrent+1)..":"..tonumber(NbpassingsDecodeur));
		sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
		else 
		sockClient:WriteString(tonumber(raceresult.passingCurrent)..":"..tonumber(NbpassingsDecodeur));
		sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
		end 
		end
	end
	
end

-- Evénement Timer 
function OnTimerBatConnect(evt)
	local sockClient = mt_device.obj;
	
	-- Mise en place du WatchDog
	raceresult.watchDogConnect = timer.Create(raceresult.panel);
	if raceresult.watchDogConnect ~= nil then
		raceresult.watchDogConnect:StartOnce(1000); -- Il faut moins de 1 sec au raceresult pour répondre 
	end
	raceresult.panel:Bind(eventType.TIMER, OnWatchDogConnect, raceresult.watchDogConnect);

	-- Appel Status 
	sockClient:WriteString("GETSTATUS");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
end

function OnReOpenSocket(evt)
	parentFrame = app.GetAuiFrame();
	mt_device.obj = socketClient.Open(parentFrame, theParams.hostname, theParams.port);
	parentFrame:Bind(eventType.SOCKET, mt_device.OnSocketClient, mt_device.obj);
	app.GetAuiMessage():AddLine('Socket Client '..theParams.hostname..':'..theParams.port..' Initialisation ...');
end

function OnWatchDogConnect(evt)
	-- Aucune réponse du Raceresult ... on n'est pas ou plus connecté
	raceresult.Connect:SetLabel("Non Connect");
	raceresult.battery:SetLabel('Bat=---%');
	
	if raceresult.watchDogConnect ~= nil then
		raceresult.watchDogConnect:Delete();
		raceresult.watchDogConnect = nil;
	end
end

-- fonction permettant de remetre à zéro le nb de passing sur l'evenement
function OnClearPassing()
--Alert("ActiveID :"..ActiveID);
	local NbPassing = '';
	if raceresult.panel:MessageBox("Confirmation du supression des Nb de passings déjà détecter? \n\n Attention cette pération vas remetre le compteur de détection à zéro\n SKIFFS vas aller récuperer toutes les detections du décodeur ", " Remise à zéro du Nb de détection", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	
	SavePassingCurrent(0);
end

--fonction permetant de vider la table tagid finish de l'evenement
function OnDeleteTagIdFinish()
	if raceresult.panel:MessageBox("Confirmation du supression des Tag_ID déjà détecter? \n\n Seul les TagID détecter par le décodeur ACTIF seront éffacer \n Attention lors de la prochaine detection \n les transpondeurs ne seront plus mis en double detection \n et les dossards deja arrivés passerons dans la colonne ancien dossard", " Supression des Tag_ID déjà détecter", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end

--recherche du nombre de ligne ds la table tag ID et afichage
	cmd = "Select * From tagID_Finish Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'";
	TabletagID_Finish = raceresult.dbSki:GetTable('tagID_Finish');
	raceresult.dbSki:TableLoad(TabletagID_Finish,cmd);
	local nbTagID_Finish = TabletagID_Finish:GetNbRows();
	Alert("Nb de tagID Déja inscrit dans la table : "..nbTagID_Finish.." de l'Evt N°"..raceresult.code_competition.." du decodeur:"..ActiveID)

--Vidage de la table
	cmd = "Delete From tagID_Finish Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'";
	raceresult.dbSki:Query(cmd);
	
	Warning("Vidage table tagID_Finish ok...");
--recherche du nombre de ligne ds la table tag ID et afichage pour verication	
	cmd = "Select * From tagID_Finish Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'";	
	-- TabletagID_Finish = raceresult.dbSki:GetTable('tagID_Finish');
	raceresult.dbSki:TableLoad(TabletagID_Finish,cmd);
	local nbTagID_Finish = TabletagID_Finish:GetNbRows();
	Alert("Nb de tagID restant inscrit dans la table : "..nbTagID_Finish.." de l'Evt N°"..raceresult.code_competition.." du decodeur:"..ActiveID)

end


--fonction permetant de vider la table tagid Tour de l'evenement
function OnDeleteTagIdTourPena()
	if raceresult.panel:MessageBox("Confirmation du supression des Nb de Tours ? \n\n Attention cette Opération effaceras le Nb de tour  \n la Table de données comportants  \n le Nb de tour dé Pénalite éffectuée", " Supression du Nb de tours éffectuer", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end

--recherche du nombre de ligne ds la table tag ID et afichage
	cmd = "Select * From tagID_TourPena Where Code = "..raceresult.code_competition;
	--TabletagID_TourPena = raceresult.dbSki:GetTable('tagID_TourPena');
	raceresult.dbSki:TableLoad(tagID_TourPena,cmd);
	local nbtagID_TourPena = TabletagID_TourPena:GetNbRows();
	-- Alert("nbtagID_TourPena"..nbtagID_TourPena)
	if nbtagID_TourPena ~= 0 then
	Alert("Nb de Tour Déja inscrit dans la table : "..nbtagID_TourPena.." de l'Evt N°"..raceresult.code_competition)

--Vidage de la table
	cmd = "Delete From tagID_TourPena Where Code = "..raceresult.code_competition;
	raceresult.dbSki:Query(cmd);
	
	Warning("Vidage table tagID_TourPena ok...");
	
--recherche du nombre de ligne ds la table tag ID et afichage pour verication	
	cmd = "Select * From tagID_TourPena Where Code = "..raceresult.code_competition;	
	TabletagID_TourPena = raceresult.dbSki:GetTable('tagID_TourPena');
	--raceresult.dbSki:TableLoad(TabletagID_TourPena,cmd);
	local nbTagID_Finish = TabletagID_TourPena:GetNbRows();
	Alert("Nb de tagID restant inscrit dans la table : "..nbTagID_Finish.." de l'Evt N°"..raceresult.code_competition.."")
	else
	Alert("Pas de Dossard inscrit dans la table tagID_TourPena pour l\'évènement N°"..raceresult.code_competition.."")
	end 
	
end

-- boite de dialogue pour la gestion de la table de corespondance
function OnOpenTableCorespondance(evt)
-- Création Dialog 

	dlgCorespondance = wnd.CreateDialog({
		parent = raceresult.panel,
		icon = "./res/32x32_ffs.png",
		label = 'Table de Corespondance',
		width = 500,
		height = 600
	});
	
	dlgCorespondance:LoadTemplateXML({ 
	xml = './device/raceresult.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'cores_Table'
	});

	
	Table = {};
	Steph = {};
	function OnClosedlgCorespondance(evt)
		dlgCorespondance:EndModal();
	end
	
	-- Grid corespondance
	cmd = "Select * From tagID_Correspondance Where Code = '"..CodeTypeTable.."' Order by Dossard";
	raceresult.dbSki:TableLoad(TabletagID_Correspondance, cmd)
	
	TabletagID_Correspondance:SetColumn('Code', { label = 'Code-Evt.', width = 12 });
	TabletagID_Correspondance:SetColumn('Dossard', { label = 'Dossard.', width = 12 });
	TabletagID_Correspondance:SetColumn('TagID', { label = 'TagID.', width = 12 });
	
	
	local grid = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
	grid:Set({
		table_base = TabletagID_Correspondance,
		columns = 'Code, TagID, Dossard',
		selection_mode = gridSelectionModes.CELLS,
		sortable = false,
		enable_editing = true
	});

	-- Initialisation des Controles
	Table.state = false;
	
	-- ToolBar
	Steph.tb = dlgCorespondance:GetWindowName('tb');
	raceresultTb_Table = Steph.tb:AddTool("Outil race Time", "./res/32x32_config.png", "outils",  itemKind.DROPDOWN);
	raceresultTb_Clear = Steph.tb:AddTool('Remise à Zéro des Données', './res/32x32_clear.png');
	Steph.tb:AddStretchableSpace();
	raceresultTb_Save = Steph.tb:AddTool("Enregistrer", "./res/32x32_save.png");
	Steph.tb:AddSeparator();
	raceresultTb_Exit = Steph.tb:AddTool("Quitter", "./res/32x32_exit.png");

	local menuSend =  menu.Create();
	menuSend:AppendSeparator();
	raceresultTb_Table_TableGe = menuSend:Append({label="Utilisation de la Table Generique à tout les évènements", image ="./res/32x32_time-admin.png"});
	menuSend:AppendSeparator();	
	-- raceresultTb_OnChargeTableCorres = menuSend:Append({label="Upload d'une Table Generique à tout les évènements", image ="./res/32x32_time-admin.png"});
	-- menuSend:AppendSeparator();
	raceresultTb_Table_TableEvt = menuSend:Append({label="Upload et utilisation d'une Table unique à un évènement", image ="./res/vpe32x32_search.png"});
	Steph.tb:SetDropdownMenu(raceresultTb_Table:GetId(), menuSend);
	Steph.tb:Realize();
	
	-- Prise des Evenements (Bind)
	dlgCorespondance:Bind(eventType.MENU, OnraceResultOutil);
	-- dlgCorespondance:Bind(eventType.MENU, OnChargeTableCorres, raceresultTb_OnChargeTableCorres);
	dlgCorespondance:Bind(eventType.MENU, OnClearTableCorres, raceresultTb_Clear);
	dlgCorespondance:Bind(eventType.MENU, OnSave, raceresultTb_Save);
	dlgCorespondance:Bind(eventType.MENU, OnClosedlgCorespondance, raceresultTb_Exit);
	dlgCorespondance:Bind(eventType.MENU, OnValidTypeTableGen, raceresultTb_Table_TableGe);
	dlgCorespondance:Bind(eventType.MENU, OnValidTypeTableEvt, raceresultTb_Table_TableEvt);

	-- permet de verifier et fixer les choses avt le showmodal (à faire obligatoirement)
	dlgCorespondance:Fit();

	-- Affichage Modal
	dlgCorespondance:ShowModal();
	
end	
	
	-- Insertion d'une Epreuve
function OnInsertTrDos(evt)
	local grid_Ligne = dlgOptionTable:GetWindowName('grid_Option');
	grid_Ligne:InsertRows(grid_Ligne:GetNumberRows());
	grid_Ligne:SetGridCursor(grid_Ligne:GetNumberRows()-1, 0);
end

	-- Suppression d'une Epreuve
function OnRemoveTrDos(evt)
	local grid_Option = dlgOptionTable:GetWindowName('grid_Option');
	local row = grid_Option:GetGridCursorRow();
	if row >= 0 then
		grid_Option:DeleteRows(row);
	end	
end

	-- Insertion d'une Loop
function OnInsertLoop(evt)
	local grid_Param = dlgOptionTable:GetWindowName('grid_Param');
	grid_Param:InsertRows(grid_Param:GetNumberRows());
	grid_Param:SetGridCursor(grid_Param:GetNumberRows()-1, 0);
end

	-- Suppression d'une Epreuve
function OnRemoveLoop(evt)
	local grid_Param = dlgOptionTable:GetWindowName('grid_Param');
	local row = grid_Param:GetGridCursorRow();
	if row >= 0 then
		grid_Param:DeleteRows(row);
	end	
end
	
function OnSaveOption(evt)

	cmd = "Delete From tagID_Tour Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'";
	raceresult.dbSki:Query(cmd);
	local grid_Ligne = dlgOptionTable:GetWindowName('grid_Option');
	
	local Grid_Ligne = grid_Ligne:GetTable();
	--Alert("raceresult_option:GetNbRows() = "..Grid_Ligne:GetNbRows());
	for i=0, Grid_Ligne:GetNbRows()-1 do
			--enregistrement de la grid option dans la table TabletagID_Tour			
			local Code = Grid_Ligne:GetCellInt('Code', i);
			local AdresseIP = Grid_Ligne:GetCell('AdresseIP', i);
			local bibMini = tonumber(Grid_Ligne:GetCell('bibMini', i));		
			local bibMax = tonumber(Grid_Ligne:GetCell('bibMax', i));
			local LoopID = Grid_Ligne:GetCell('LoopID', i);
			local LoopCanal = Grid_Ligne:GetCell('LoopCanal', i);
			local Tour = Grid_Ligne:GetCellInt('Tour', i);
		-- Alert("raceresult_option:GetNbRows() = "..Grid_Ligne:GetCell('LoopID', i));
		AddTabletagID_Tour(Code,AdresseIP,bibMini,bibMax,LoopID,LoopCanal,Tour);
		
	end
		Alert("Sauvegarde des lignes ds tagID_Tour éffectuer correctement");
	
	cmd = "Delete From tagID_Passings Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'";
	raceresult.dbSki:Query(cmd);
	local grid_Param = dlgOptionTable:GetWindowName('grid_Param');
	local Grid_Param = grid_Param:GetTable();
	Alert("raceresult_option:GetNbRows() = "..Grid_Param:GetNbRows());
	for i=0, Grid_Param:GetNbRows()-1 do
			--enregistrement de la grid option dans la table TabletagID_Passings						
		local Code = Grid_Param:GetCellInt('Code', i);
		local AdresseIP = Grid_Param:GetCell('AdresseIP', i);
		local Port = Grid_Param:GetCell('Port', i);		
		local LoopID = Grid_Param:GetCell('LoopID', i);
		local LoopCanal = Grid_Param:GetCell('LoopCanal', i);
		local passage = Grid_Param:GetCell('passage', i);
		local ID_1er_Inter = Grid_Param:GetCell('ID_1er_Inter', i);
		local Passings = Grid_Param:GetCell('Passings', i);
		local TypeTable = Grid_Param:GetCell('TypeTable', i);
		local DelayDoubleDetect = Grid_Param:GetCellInt('DelayDoubleDetect', i);
		local CountTourActif = Grid_Param:GetCellInt('CountTourActif', i);
		AddTabletagID_Passings(Code,AdresseIP,Port,LoopID,LoopCanal,passage,ID_1er_Inter,Passings,TypeTable,DelayDoubleDetect,CountTourActif);

		--Alert("Grid_Param:GetNbRows() = "..Grid_Param:GetNbRows()); --  Grid_Param:GetCell('LoopID', i));
	end
		Alert("Sauvegarde des lignes ds TabletagID_Passings éffectuer correctement");
end

	function OnEditorShown(evt)
	local row = evt:GetRow();
	local col = evt:GetCol();
	if row >= 0 and col >= 0 then
		local t = grid:GetTable();
		local colName = t:GetColumnName(t:GetVisibleColumnsIndex(col));
		if colName == "Tarif_Inscriptions" then
			-- On accepte l'édition
			return;
		end
	end
	-- Dans tous les autres cas on n'autorise pas l'édition ...
	evt:Veto();
end
	
function OnOpenOptions(evt)
-- Création Dialog 

	dlgOptionTable = wnd.CreateDialog({
		parent = raceresult.panel,
		icon = "./res/32x32_ffs.png",
		label = 'Gestion des Options Nb Tours et / Passage',
		width = 1050,
		height = 500
	});
	
	dlgOptionTable:LoadTemplateXML({ 
	xml = './device/raceresult.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'Option_Table'
	});
	
	raceresult_option = {};
	raceresult_param = {};
	raceresult_Exit = {};
	
	function OnClosedlgOptionTable(evt)
	dlgOptionTable:EndModal();
	end
	
	
-- Grid Options
	cmd = "Select * From tagID_Tour Where Code = '"..raceresult.code_competition.."' and AdresseIP = '"..ActiveID.."' Order by Code, bibMini";
	raceresult.dbSki:TableLoad(TabletagID_Tour, cmd)
	
	TabletagID_Tour:SetColumn('Code', { label = 'Code-Evt.', width = 9 });
	TabletagID_Tour:SetColumn('AdresseIP', { label = 'AdresseIP.', width = 12 });
	TabletagID_Tour:SetColumn('bibMini', { label = 'bibMini.', width = 9 });
	TabletagID_Tour:SetColumn('bibMax', { label = 'bibMax.', width = 9 });
	TabletagID_Tour:SetColumn('LoopID', { label = 'Loop.', width = 9 });
	TabletagID_Tour:SetColumn('LoopCanal', { label = 'LoopCanal.', width = 9 });
	TabletagID_Tour:SetColumn('Tour', { label = 'Tour.', width = 6 });
	
	local grid = dlgOptionTable:GetWindowName('grid_Option');
	grid:Set({
		table_base = TabletagID_Tour,
		columns = 'Code, AdresseIP, bibMini, bibMax, LoopID, LoopCanal, Tour',
		selection_mode = gridSelectionModes.CELLS,
		sortable = false,
		enable_editing = true
	});

-- Initialisation des Controles
	
		-- ToolBar OPTION
	raceresult_option.tb = dlgOptionTable:GetWindowName('tb_option');
	raceresultTb_InsertTrDos = raceresult_option.tb:AddTool("Ajouter une Ligne", "./res/32x32_list_add.png");
	raceresult_option.tb:AddStretchableSpace();
	raceresultTb_RemoveTrDos = raceresult_option.tb:AddTool("Supprimer une Ligne", "./res/32x32_list_remove.png");
	raceresult_option.tb:Realize();
-- Grid Parametre

	cmd = "Select * From tagID_Passings Where Code = '"..raceresult.code_competition.."' and AdresseIP = '"..ActiveID.."' Order by Code, LoopID, LoopCanal";
	raceresult.dbSki:TableLoad(TabletagID_Passings, cmd)
	
	TabletagID_Passings:SetColumn('Code', { label = 'Code-Evt.', width = 9 });
	TabletagID_Passings:SetColumn('AdresseIP', { label = 'AdresseIP.', width = 12 });
	TabletagID_Passings:SetColumn('Port', { label = 'Port.', width = 9 });
	TabletagID_Passings:SetColumn('LoopID', { label = 'LoopID.', width = 6 });
	TabletagID_Passings:SetColumn('LoopCanal', { label = 'LoopCanal.', width = 6 });
	TabletagID_Passings:SetColumn('passage', { label = 'passage.', width = 9 });
	TabletagID_Passings:SetColumn('ID_1er_Inter', { label = 'ID 1er Inter.', width = 9 });
	TabletagID_Passings:SetColumn('Passings', { label = 'Nb Passings.', width = 12 });
	TabletagID_Passings:SetColumn('TypeTable', { label = 'TypeTable.', width = 6 });
	TabletagID_Passings:SetColumn('DelayDoubleDetect', { label = 'Delai Double Detect.', width = 18 });
	TabletagID_Passings:SetColumn('CountTourActif', { label = 'Compteur Tour Pena Actif.', width = 22 });
	TabletagID_Passings:SetColumn('SystemeActif', { label = 'SystemeActif.', width = 22 });
	local grid = dlgOptionTable:GetWindowName('grid_Param');
	grid:Set({
		table_base = TabletagID_Passings,
		columns = 'Code, AdresseIP, Port, LoopID, LoopCanal, passage, ID_1er_Inter, Passings, TypeTable, DelayDoubleDetect, CountTourActif, SystemeActif',
		selection_mode = gridSelectionModes.CELLS,
		sortable = false,
		enable_editing = true
	});
	
	grid:SetColAttr('CountTourActif', { kind = 'bool', value_true = '1' });
	grid:SetColAttr('SystemeActif', { kind = 'bool', value_true = '1' });

-- Initialisation des Controles
		
	-- ToolBar PARAM
	raceresult_param.tb = dlgOptionTable:GetWindowName('tb_param');
	raceresultTb_InsertLoop = raceresult_param.tb:AddTool("Dupliquer une Ligne", "./res/32x32_list_add.png");
	raceresult_param.tb:AddStretchableSpace();
	raceresultTb_RemoveLoop = raceresult_param.tb:AddTool("Suprimer une Ligne", "./res/32x32_list_remove.png");
	raceresult_param.tb:Realize();
	
	-- ToolBar exit
	raceresult_Exit.tb = dlgOptionTable:GetWindowName('tb');
	raceresultTb_Save = raceresult_Exit.tb:AddTool("Enregistrer", "./res/32x32_save.png");
	raceresult_Exit.tb:AddStretchableSpace();
	raceresultTb_Exit = raceresult_Exit.tb:AddTool("Quitter", "./res/32x32_exit.png");
	raceresult_Exit.tb:Realize();
	
	-- Prise des Evenements (Bind)
	dlgOptionTable:Bind(eventType.MENU, OnInsertTrDos, raceresultTb_InsertTrDos);
	dlgOptionTable:Bind(eventType.MENU, OnRemoveTrDos, raceresultTb_RemoveTrDos);
	dlgOptionTable:Bind(eventType.MENU, OnInsertLoop, raceresultTb_InsertLoop);
	dlgOptionTable:Bind(eventType.MENU, OnRemoveLoop, raceresultTb_RemoveLoop);
	dlgOptionTable:Bind(eventType.MENU, OnSaveOption, raceresultTb_Save);
	dlgOptionTable:Bind(eventType.MENU, OnClosedlgOptionTable, raceresultTb_Exit);
	
	-- permet de verifier et fixer les choses avt le showmodal (à faire obligatoirement)
	dlgOptionTable:Fit();

	-- Affichage Modal
	dlgOptionTable:ShowModal();
		
end

--fonction pour charger une table générique
function OnValidTypeTableGen(evt)
	cmd = "Select * From tagID_Correspondance where Code = '0' and TypeTable = 'GEN'";
	raceresult.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
	 if TabletagID_Correspondance:GetNbRows() >= 1 then
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable	= 'GEN' Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'";
		raceresult.dbSki:Query(cmd);
		TypeTable = 'GEN';	
		Table.state = true ;
		CodeTypeTable = 0;
		--Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
		-- Rafraichissement de la grille ...
		local grid = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
		grid:SynchronizeRows();
		Success('Validation de l\'utisation d\'une table Générique pour cet évènement ! ');
	else
		Alert('Pas de Table Généric dans la base ski veuiller uploader une table de corespondance');
		Alert('Pour pouvoir vous en servir');
		Table.state = true ;
		-- CodeTypeTable = 0;
		-- TypeTable = 'GEN';
		OnChargeTableCorres(0, 'GEN');
	end	
	
end

--fonction pour charger une table qui ne fonctionne que pour l'evenement
function OnValidTypeTableEvt(evt)
	cmd = "Select * From tagID_Correspondance where Code = "..raceresult.code_competition.." and TypeTable = 'EVT'";
	raceresult.dbSki:TableLoad(TabletagID_Correspondance, cmd)
	
	if TabletagID_Correspondance:GetNbRows() >= 1 then
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable	= 'EVT' Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'";
		raceresult.dbSki:Query(cmd);
		TypeTable = 'EVT';	
		Table.state = true ;
		CodeTypeTable = tonumber(raceresult.code_competition);
		--Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
		-- Rafraichissement de la grille ...
		local grid = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
		grid:SynchronizeRows();
		Success('Validation de l\'utisation d\'une table unique à l\'évènement pour cet évènement ! ');
	else
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable = 'EVT'  Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'";
		raceresult.dbSki:Query(cmd);
		TypeTable = 'EVT';	
		Table.state = true ;
		CodeTypeTable = tonumber(raceresult.code_competition);
		Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
		OnChargeTableCorres(CodeTypeTable, TypeTable);
	end
	Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
end
	
--fonction pour Vider une table de corespondance	
function OnClearTableCorres(evt)
	if raceresult.panel:MessageBox("Confirmation du Vidage de la table de corespondance ?\n\nCette opération effecera le contenue de la table corespondance de cet évènement", "Confirmation du Vidage de la table de corespondance", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	Alert ("CodeTypeTable = "..CodeTypeTable.."et  TypeTable = ".. TypeTable);
	if CodeTypeTable ~= "" or  TypeTable ~= "" then
	cmd = "Delete From tagID_Correspondance Where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	raceresult.dbSki:Query(cmd);
	else
	cmd = "Delete From tagID_Correspondance Where Code = "..raceresult.code_competition;
	raceresult.dbSki:Query(cmd);
	end
	
--	TableCorrespondance:RemoveAllRows();
	cmd = "Select * From tagID_Correspondance where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	raceresult.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
 if TabletagID_Correspondance:GetNbRows() >= 1 then
	Alert("la table ne sais pas vider = "..TabletagID_Correspondance:GetNbRows());
end	
	TypeTable = 'ND'
	--Alert('je modifi dans la table TagID_Passings'..TypeTable)
	cmd = "Update tagID_Passings SET TypeTable = '"..TypeTable.."' Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'"
	raceresult.dbSki:Query(cmd);
	Warning("Vidage table tagID_Correspondance ok...");

	-- Rafraichissement de la grille ...
	local grid = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
	grid:SynchronizeRows();
end

-- chargement de la table de corespondance
function OnChargeTableCorres(CodeTypeTable, TypeTable)
 if Table.state == true then
	-- recherche si il y a deja une table de corespondance de charger dans la base
	cmd = "Select * From tagID_Correspondance where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	raceresult.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
	 if TabletagID_Correspondance:GetNbRows() >= 1 then
		if raceresult.panel:MessageBox("Confirmation du chargement de la table de corespondance ?\n\nCette opération effacera la table actuellement dans la base de donnée \n avant d'effectuer le rechargement de la table.", "Confirmation du chargement des Tag_ID et Dossards", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
			return;
		end
		
		OnClearTableCorres(CodeTypeTable, TypeTable)
		
	 end
 
 
	if raceresult.panel:MessageBox("Confirmation du chargement de la table de corespondance ?\n\nCette opération vas effectuer le chargement de la table.", "Confirmation du chargement des Tag_ID et Dossards", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
--  rechercher le fichier .db3 des séquences à relire et le charger en read.db3
	local fileDialog = wnd.CreateFileDialog(raceresult.panel,
		"Sélection du fichier de corespondance",
		raceresult.directory, 
		"",
		"*.csv|*.csv",
		fileDialogStyle.OPEN+fileDialogStyle.FD_FILE_MUST_EXIST
	);
-- prise du chemin du fichier csv
	if fileDialog:ShowModal() == idButton.OK then
			read_csv = string.gsub(fileDialog:GetPath(), app.GetPathSeparator(), "/");
	else return false;
	end
		csvFile = io.open(read_csv);
			Alert ('Chargement de la nouvelle table de corespondance');
		
		for line in csvFile:lines() do
			local arrayResults = string.Split(line,';');
			if #arrayResults >= 2 then 
				if tonumber(arrayResults[1]) ~= nil and tonumber(arrayResults[1]) > 0 then
				local r = TabletagID_Correspondance:AddRow();
					local TagID = arrayResults[2];
					local Dossard = tonumber(arrayResults[1]);
						if TypeTable == 'GEN' then 
						TabletagID_Correspondance:SetCell("Code", r, 0);
						elseif TypeTable == 'EVT' then
						TabletagID_Correspondance:SetCell("Code", r, raceresult.code_competition);
						end
				TabletagID_Correspondance:SetCell("TagID", r, TagID);		
				TabletagID_Correspondance:SetCell("Dossard", r, Dossard);
				TabletagID_Correspondance:SetCell("TypeTable", r, TypeTable);
				raceresult.dbSki:TableInsert(TabletagID_Correspondance, r);
				end
			end
		end
		csvFile:close();
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
	cmd = "Update tagID_Passings SET TypeTable = '"..TypeTable.."' Where Code = "..raceresult.code_competition.." and AdresseIP = '"..ActiveID.."'"
	raceresult.dbSki:Query(cmd);
	--Alert('je modifi dans la table TagID_Passings le type de table utiliser :'..TypeTable)
		local nbLignes = TabletagID_Correspondance:GetNbRows();
			Warning("Correspondance : "..nbLignes.." ligne ds la table");
		local nbLignes = 0;
		
else
	Warning("pas de type de table designer");
end 
	
	-- Rafraichissement de la grille ...
	local grid = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
	grid:SynchronizeRows();

end

function OnRunErased(key, params)
	Alert("Suppression de tous les passages !!!!!! : on doit faire des trucs ...");
	return true;
end

function OnBibLoaded(key, params)
	if type(params.table) == 'userdata' then
		Alert(params.table:GetCell("Dossard",0).." "..params.table:GetCell("Nom",0).." "..params.table:GetCell("Prenom",0));
	end
	return true;
end

--fonction qui permet de verifier que le protocol est mis en place et que le decodeur repond par pong si tt est ok
function OnPing(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("PING");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	Warning('PING Envoyé ...');
end

-- renvoi le mode de fonctionnement du decodeur test ou chrono
function OnMode(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("GETMODE");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
end

-- renvoi le N° de protocol qu'utilise le decodeur
function OnProtocol(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("GETPROTOCOL");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
end

--renvoi le status du decodeur
function OnStatus(evt)

	local sockClient = mt_device.obj;
	sockClient:WriteString("GETSTATUS");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	raceresult.GetStatus = "Ok" ;
	Alert ('Envoi GetStatus'..raceresult.GetStatus);
	return raceresult.GetStatus
end

--renvoi le Nb de passings enregistrer dans le fichier du decodeur
function OnPassings(evt, Get)
	local sockClient = mt_device.obj;
	sockClient:WriteString("PASSINGS");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	Alert("Nb de Passing ds le fichier du decodeur = "..raceresult.passingCount);	
end

--renvoi le temps tournant du decodeur
function OnGetTime(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("GETTIME");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
end

-- renvoi le niveau de charge du decodeur
function OnChargeBat(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("GETSTATUS");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
end

function OnStartOperation(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("STARTOPERATION");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	Warning('Demande d\'Activation des antennes envoyé ...');
end

function OnStopOperation(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("STOPOPERATION");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	Warning('Demande de désactivation des antennes envoyé ...');
end

function OnRechargeTagId(evt)
	Alert ('en cours de rédaction utiliser la fonction remise a zero di Nb passing');
end

function OnStartRaceResult(evt)
if TypeTable == 'ND' then 
Warning("Pas de table de corespondance ");
Warning("Veuillez sélectionner un type de table et uploader une table via un fichier .csv ");
else
	if raceresult.ActiveStart == "Non Actif" then
		-- Mise du Protocol ...
		local sockClient = mt_device.obj;
		sockClient:WriteString("SETPROTOCOL;1.8");
		sockClient:WriteByte(asciiCode.CR, asciiCode.LF);

		-- Prise de la table de Correspondance ...
		raceresult.tagID = TabletagID_Correspondance;
		Warning("Correspondance : "..TabletagID_Correspondance:GetNbRows().." ligne ds la table");
		Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
		
		-- Verification que le directory ./device/Race-result existe ... a suprimer??????????????????????
		if app.DirExists('./device/Race-result') == false then
			app.Mkdir('./device/Race-result'); -- Creation du répertoire
		end

		-- Creation du Timer 
		raceresult.timer = timer.Create(raceresult.panel);
		if raceresult.timer ~= nil then
			raceresult.timer:Start(raceresult.timerDelay);
		end
		raceresult.panel:Bind(eventType.TIMER, OnTimer, raceresult.timer);

		raceresult.ActiveStart = "Actif"
	else 
		Error("Déja activé !");
	end
end
end


-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	
	-- Test si le Buffer est vide 
	if cb:GetCount() == 0 then return end

	-- Lecture des Packets 
	while (ReadPacket(cb)) do end
		
end

--fonction permetant d'envoyer un tagID pour voir le bon fonctionnement de la lecture ds les tables sans le decodeur race result
function OnDebug()
--local tagID = '1532658';
tagID = 'ABDF-1';
--local chrono = 3600000; -- 3600000 == 1h
--local chrono = 10000; -- 10000 == 10 SECONDE
local hourPassage = "12:40:10.370";
local arrayResults = 4;
local countResults = 5;
local firstResult = 4;
local LoopID = 'Loop1';
local LoopCanal = 'LoopCanal0';
debugage = true;
-- cb = hourPassage,tagID,countResults,firstResult,arrayResults,LoopID;
ReadPacket(hourPassage,tagID,countResults,firstResult,arrayResults,LoopID,LoopCanal);
	
end

-- function ReadPacket(hourPassage,tagID,countResults,firstResult,arrayResults,LoopID);
function ReadPacket(cb)
--ligne a commenter pour la fonction debug <--
			-- Alert("LoopID = "..LoopID);	
	local count =  cb:GetCount();
	
	local findEnd = cb:Find(asciiCode.CR, asciiCode.LF);	-- Recherche fin de Trame
	if findEnd == -1 then return false end 					-- On peut stopper la recherche

	local packet = cb:ReadByte(findEnd+1);
	
	local packetString = adv.PacketString(packet, 1, findEnd);
-- Alert ("packetString = "..packetString);
	local arrayResults = string.Split(packetString,';');
	
	local countResults = #arrayResults;
--> fin des lignes a comenter

	if countResults >= 1 then
		local firstResult = arrayResults[1]; --ligne a commenter pour la fonction debug
	--Alert("firstResult = "..firstResult);

		if tonumber(firstResult) ~= nil and tonumber(firstResult) > 0 then
-- ###### coupure pour tranfert web ou reseau  //////////// quand on met bien mettre raceresult ou RaceresultWebServeur (entre les deux coupure) suivant si on est en IP ou en webserveur////******
			-- Impulsion de Passage
			if #arrayResults >= 4 then    -- à activer si hors debug
			--if arrayResults >= 4 then        -- à activer si debug
--**** recherche du dos	
				local tagID = arrayResults[2];  -- à activer si hors debug
				tagID = tagID:gsub('\n', '');	-- Suppression du LF éventuel
				tagID = tagID:gsub('\r', '');	-- Suppression du CR éventuel
				
				local NumLoopID = arrayResults[11];-- à activer si hors debug
				local NumLoopCanal = arrayResults[10];-- à activer si hors debug
				local SystemeActif = arrayResults[9];  --  == 1 la trame viens d'un systeme actif
				
				if NumLoopID ~= '' then 
					LoopID = 'Loop'..NumLoopID;
					LoopCanal = 'LoopCanal'..NumLoopCanal;
					SystemeActif = arrayResults[9]
				else 
					LoopID = 'Loop0';
					LoopCanal = 'LoopCanal0';
					SystemeActif = 0;
				end 
				Alert("LoopID = "..LoopID.." / Canal = "..LoopCanal.." / SystemeActif = "..SystemeActif )

				local hourPassage = arrayResults[4];                -- à activer si hors debug derniere a bouger
				-- Alert("	hourPassage :"..hourPassage.." et tagID = "..tagID);
				local chrono = GetChrono(hourPassage);
				-- Alert("	CodeTypeTable :"..CodeTypeTable)
								
				-- on recherche si le CountTourActif est actif pour la Loop
				RechercheCountTourActif(CodeTypeTable,tagID, LoopID, LoopCanal);
				-- Alert("CountTourActif = "..CountTourActif)
				
				-- si c'est un systeme actif et que le N° de LoopID ou de LoopCanal sont == 0
				-- l'impulse viens du marqquer du decodeur 
				if tonumber(SystemeActif) == 1 and LoopID == 'Loop0' and LoopCanal == 'LoopCanal0' then
					Alert("L impulse viens du marqueur du décodeur "..ActiveID)
					AddTimePassage(chrono, passage, -tonumber(tagID), tagID);	
				else	
					if tonumber(CountTourActif) == 0 then
					-- Alert("je gere la detection normalement comme un chrono")			
						-- on recherche le dos et le nb de tour a faire par le dos 				
						RecherchetourDos(CodeTypeTable,tagID, LoopID, LoopCanal);
						-- Alert("bib = "..bib);
						-- Alert("NbToursAFaire 2 = "..NbToursAFaire);	--ok			
						--si bib est différent de nil ou de '' on gere l'impultion
						if bib ~= "" then
							-- recherche de l'heure de départ de l'épreuve
								-- rechercheHeureDepartDos(bib);
							
							
							-- recherche si un tagID existe dans la table TableTagID_Finish
							cmd = "Select * From TagID_Finish Where Code = '"..raceresult.code_competition..
								  "' and AdresseIP = '"..ActiveID..
								  "' and LoopID = '"..LoopID..
								  "' and LoopCanal = '"..LoopCanal..
								  "' and TagID = '"..tagID..
								  "'"
								  ;
							local Rech_TagID = raceresult.dbSki:TableLoad(TableTagID_Finish, cmd):GetCell("TagID", 0);
							local Rech_Der_Passge_TagID = raceresult.dbSki:TableLoad(TableTagID_Finish, cmd):GetCell("Passage", 0);
							Alert("Rech_Der_Passge_TagID = "..Rech_Der_Passge_TagID)
							-- Alert("Rech_TagID = "..Rech_TagID)
							-- Gestion Impulsions			
								--si Rech_TagID est diff de '' je gere l' impultion
							if Rech_TagID ~= '' then
								-- recherche du nombre de tour fait par le coureur ds la Table TableTagID_Finish 
								cmd = "select * from TagID_Finish where Code = "..raceresult.code_competition..
										" and AdresseIP = '"..ActiveID..
										"' and LoopID = '"..LoopID..
										"' and LoopCanal = '"..LoopCanal..
										"' and TagID = '"..tagID..
										"'"
								local NbTourRealiser = raceresult.dbSki:TableLoad(TableTagID_Finish, cmd):GetCellInt("Tour", 0);
								-- Alert("Nb Tour fait: "..NbTourRealiser.."/ "..NbToursAFaire.." Tours à Faire")
									-- Recherche du numero de passage défini dans la table tagID_Passings OK
								cmd = "Select * From tagID_Passings Where Code = "..raceresult.code_competition..
									  " and AdresseIP = '"..ActiveID..
									  "' and LoopID = '"..LoopID..
									  "' and LoopCanal = '"..LoopCanal..
									  "'"
									  ;
								raceresult.dbSki:TableLoad(TableTagID_Passings, cmd);
					--peu etre mettre une condition si la requette retourne nil	?	*****************************************************************	
								-- Recherche du delay de double detection
									local DelayDoubleDetect = TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
									Alert("DelayDoubleDetect: test steph"..DelayDoubleDetect);
									
									-- suivant le nombre de tour fait par le concurent et le nombre de tour qu'il a a faire j'acremente la variable passage
									--si le concurent n'a pas fait plus le nombre de tour alors passage seras egal NbTourRealiser
									if NbToursAFaire == 0 then
										passage = TableTagID_Passings:GetCell('passage', 0);
										Alert("if tonumber(NbToursAFaire) == 0 : "..passage);
									else
										if NbTourRealiser < tonumber(NbToursAFaire) then 
											passage = NbTourRealiser + ID_1er_Inter;
											Alert("if tonumber(NbTourRealiser) < tonumber(NbToursAFaire) : "..passage);
										--si le concurent a fait le nombre de tour alors passage seras egal a passage	
										elseif	NbTourRealiser == NbToursAFaire then 
											passage = TableTagID_Passings:GetCell('passage', 0);
											Alert("if tonumber(NbTourRealiser) == tonumber(NbToursAFaire) : "..passage);
										--si le concurent a fait plus que le nombre de tour alors passage seras egal a passage 
										elseif tonumber(NbTourRealiser) > tonumber(NbToursAFaire) then
											Alert("tonumber(NbTourRealiser) > tonumber(NbToursAFaire) : "..passage);
											passage = TableTagID_Passings:GetCell('passage', 0);
										end
									end
								
										--Alert("Détection double "..tagID..'-/- '..NbTourRealiser..'->'..Tour);
							
									-- je recherche	si le dos existe ds la table tresultachrono	suivant le point de passage qu'il a été deteter la derniere fois			
									-- rechercher si une heure de passage est deja inscrite dans la table chrono
									-- Alert("passage = "..passage);

									TimePassage = GetHeurePassage(bib, Rech_Der_Passge_TagID);
									
										Alert(" chrono = "..chrono.." TimePassage = "..TimePassage);
										-- Calcul de l'heure de passage + delay double detection
									local TimePassagePlus = tostring(TimePassage)+tostring(DelayDoubleDetect); 
										--Alert(" TimePassagePlus ="..TimePassagePlus)
										-- si le l'heure dedetection 'chrono' est inferieur a tps + DelayDoubleDetect c'est une double détection
									if 	tonumber(chrono) <= tonumber(TimePassagePlus)then 
										Alert("Attention Double detection delai entre les 2 detections < "..DelayDoubleDetect);
										local bib = -6666;
										local tagID = tagID.."(d)";
										Alert("Nb Tour fait: "..NbTourRealiser.."/ "..NbToursAFaire.." Tours à Faire")
											AddTimePassage(chrono, Rech_Der_Passge_TagID, bib, tagID);
		--****						-- Sinon c'est une impultion normal on peu continuer la gestion	
									else
										-- **** si le delay de double detection est passer je gere l'impultion normalement
										--Alert(" heure de passage > au DelayDoubleDetect on peu gerer l'impultion normalement");		
											-- Si le nb de tour realiser est == au nb de tour a faire je met l' heure ds la table
											if tonumber(NbTourRealiser) < tonumber(NbToursAFaire) then 
												--Alert("LoopID 1 = "..LoopID);
												AddNbTours(NbTourRealiser+1, tagID, ActiveID, LoopID, LoopCanal);
												AddTimePassage(chrono, NbTourRealiser+1, bib, tagID);
												refreshTagIDFinish(tagID, passage, LoopID, LoopCanal);
											elseif	tonumber(NbTourRealiser) == tonumber(NbToursAFaire) then 
												--Alert("LoopID 2 = "..LoopID);
												AddNbTours(NbTourRealiser+1, tagID, ActiveID, LoopID, LoopCanal);
												AddTimePassage(chrono, passage, bib, tagID);
												refreshTagIDFinish(tagID, passage, LoopID, LoopCanal);
											elseif tonumber(NbTourRealiser) > tonumber(NbToursAFaire) then
												--Alert("LoopID 3 = "..LoopID);
												AddNbTours(NbTourRealiser+1, tagID, ActiveID, LoopID, LoopCanal);
												AddTimePassage(chrono, passage, -bib, tagID);
											end
									end 
							--si recherche TagID == '' c'est la premiere detection du tagID j'envoi le temps ds la base					
							else 
								Alert('premiere detection NbTourRealiser = '..NbTourRealiser..'NbToursAFaire = '..NbToursAFaire)						
								Alert('passage = '..passage)
								if tonumber(NbToursAFaire) == 0 then
									-- numero de passage a verifier il devrais etre le passage defini
									local Tour = 1;
									Alert('Le concurent n\'a pas de tour à faire j\'ecrit dans la table TableTagID_Finish')
									AddTimePassage(chrono, passage, bib, tagID);
									AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib)
								else
									if tonumber(NbTourRealiser) < tonumber(NbToursAFaire) then
										-- numero de passage a verifier il devrais etre le passage defini
										local passage = tonumber(ID_1er_Inter);
										local Tour = 1;
										Alert('Le concurent n\'a pas fait de Nb tour à faire j\'ecrit dans la table TableTagID_Finish')
										AddTimePassage(chrono, passage, bib, tagID);
										Alert('je lui met un Tour dans la table TabletagID_Finish')
										AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib)
									elseif tonumber(NbTourRealiser) == tonumber(NbToursAFaire) then
										local Tour = 1;
										Alert('Le concurent a fait le Bon nombre de Tour')
										AddTimePassage(chrono, passage, bib, tagID);
										AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib);
									end
								end

							end
			
						-- si bib = '' le tagID est inconnu ds la table de corespondance je met un dos -9999 pour le signaler au chrono et ne pas perdre l'impulse
						else			
							Alert("Tag ID inconnu dans la TableCorrespondance:  ")
							bib = -9999;
							AddTimePassage(chrono, passage, bib, tagID);
						end		
					else 
					-- CountTourActif == 1
					-- la Loop sert a compter le Nb tour de Pena..... 
					-- a voir pour passer au Num tir superieur
						Alert("La détection viens de la Loop de comptage de tour de péna");
						RecherchetourDos(CodeTypeTable,tagID, LoopID, LoopCanal);
						--Alert("bib = "..bib)
	-- à verifier avec pierre si le bib ~= nil fonctionne bien ou si il faut mettre bib ~= ""car ds RecherchetourDos ~= nil ne fonctionne pas	
						if bib ~= nil then
							cmd = "Select * From tagID_Passings Where Code = "..raceresult.code_competition..
								  " and AdresseIP = '"..ActiveID..
								  "' and LoopID = '"..LoopID..
								  "' and LoopCanal = '"..LoopCanal..
								  "'"
								  ;
							raceresult.dbSki:TableLoad(TableTagID_Passings, cmd);
								-- Recherche du delay de double detection
							local DelayDoubleDetect = TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
							local passage = TableTagID_Passings:GetCell('passage', 0);
								Alert("DelayDoubleDetect = "..DelayDoubleDetect);
								Alert("passage = "..passage);
							-- recherche si un tagID existe dans la table TagID_TourPena
							cmd = "Select * From TagID_TourPena Where Code = '"..raceresult.code_competition..
								  "' and AdresseIP = '"..ActiveID..
								  "' and LoopID = '"..LoopID..
								  "' and LoopCanal = '"..LoopCanal..
								  "' and Dossard = "..bib							 
								  ;
							local Rech_Dossard = raceresult.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCell("Dossard", 0);
							Alert("Rech_Dossard = "..Rech_Dossard);
								if Rech_Dossard == '' then
									--Alert("Rech_Dossard test2 = "..Rech_Dossard)
									-- Je creer un ligne pour le comptage de tour de pena ds la table tagID_TourPena
									local Num_Tir = 1;
									local NbTour_Fait = 1;
									InsertNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait);
								else
									--Alert("bib = "..bib)
									--Alert("passage: "..passage);
									Alert("DelayDoubleDetect: "..DelayDoubleDetect);
									local TimePassage = GetHeurePassage(Rech_Dossard, passage);
									Alert("TimePassage: "..TimePassage);
									local Num_Tir = 1;
									local TimePassagePlus = tonumber(TimePassage)+tonumber(DelayDoubleDetect); 
									Alert("chrono = "..chrono.." TimePassagePlus ="..TimePassagePlus)
										if 	tonumber(chrono) <= tonumber(TimePassagePlus)then
										-- si le l'heure dedetection 'chrono' est inferieur a tps + DelayDoubleDetect c'est une boucle de pena du tir actif
											local Num_Tir = raceresult.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Num_Tir", 0);
											Alert("Num_Tir1 = "..Num_Tir);
											local NbTour_Fait = raceresult.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Tir"..Num_Tir, 0)+1;
											Alert("NbTour_Fait = "..NbTour_Fait);
											AddNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait);
										else
										-- si le l'heure dedetection 'chrono' est superieur a tps + DelayDoubleDetect c'est une boucle de pena du tir superieur
											local Num_Tir = raceresult.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Num_Tir", 0)+1;
											Alert("Num_Tir + 1 = "..Num_Tir);
											local NbTour_Fait = raceresult.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Tir"..Num_Tir, 0)+1;
											Alert("NbTour_Fait = "..NbTour_Fait);
											-- j' ajoute 1 tour ds la table tagID_TourPena
											AddNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait);
										end
								end
								AddTimePassage(chrono, passage, bib, tagID);
						else
						AddTimePassage(chrono, passage, -7777, tagID);
						end
					end
				end
				SavePassingCurrent(tonumber(firstResult));
--#######  fin de la boucle pour transfert Web ou reseau						
			end

		-- PASSINGS
		elseif firstResult == 'PASSINGS' then
			if #arrayResults >= 2 then
				raceresult.passingCount = tonumber(arrayResults[2]);
			end
			
		-- GETSTATUS
		elseif firstResult == 'GETSTATUS' then
			-- Suppression du WatchDog
			if raceresult.watchDogConnect ~= nil then
				raceresult.watchDogConnect:Delete();
				raceresult.watchDogConnect = nil;
			end
		
		raceresult.Connect:SetLabel("Connect");
			
			if raceresult.GetStatus == 'Ok'then
				Success(packetString);
				raceresult.GetStatus = 'Ko'
				return raceresult.GetStatus
			else 
			--Alert ('envoiGetStatus KO')
			end	 
			
			local batteryCharge = tonumber(arrayResults[11]);
			raceresult.battery:SetLabel("Charge Bat ="..batteryCharge..'%');
			if batteryCharge < 10 then
				Warning("Charge de la batterie trop faible: "..batteryCharge.."%");
			end
		
		-- PING;PONG
		elseif firstResult == 'PING' and #arrayResults >= 2 and arrayResults[2] == 'PONG' then
			Success('PONG reçu ! Décodeur connecter');
		-- ----
		elseif firstResult == 'GETTIME' then
			Success(packetString);
		-- GETPROTOCOL
		elseif firstResult == 'GETPROTOCOL' then
			--NProtocol = arrayResults[2]..'/'..arrayResults[3]..'/'..arrayResults[4]..'/'..arrayResults[4]..'.'
			Success('protocol pris en compte par le decodeur: '..packetString);
			
		elseif firstResult == 'GETMODE' then
			ModeChrono = arrayResults[2];
				if ModeChrono == 'OPERATION' then
				Success("decodeur en mode Chrono: "..ModeChrono);
				elseif ModeChrono == 'TEST' then
				Warning("decodeur en mode Test "..ModeChrono);
				else
				alert("Mode chrono non traiter pour l'instand")
				end
				
		elseif firstResult == 'SETPROTOCOL' then		
				SetProtocol = arrayResults[2];	
				Alert("Protocol utilisé par le decodeur : "..SetProtocol)
				
		elseif firstResult == 'STARTOPERATION' and #arrayResults >= 2 and arrayResults[2] == 'Ok' then
			Success('Ligne Active');	
		
		elseif firstResult == 'STOPOPERATION' and #arrayResults >= 2 and arrayResults[2] == 'Ok' then
			Warning('Ligne Désactivée plus de détection de Transpondeur');	
			Alert("decodeur en mode Chrono: Test");
			
		--elseif firstResult == 'ONLY '..tostring(raceresult.passingCount) then
			--NumPassings = arrayResults[2];
			--Alert('Commande ONLY envoie du passing :'..NumPassings);
		
		elseif firstResult ~= '' then
			-- Réponse autre commandes alert lors de la detection des puces... Only11
			Alert('Commande '..firstResult..' non prise en compte :'..packetString);
		end
	end

	return true;	-- il faut poursuivre la recherche	
end

-- function permetant aller chercher le dos par rapport au tagid
function RecherchetourDos(CodeTypeTable,tagID,LoopID,LoopCanal)
-- recherche du dossard par rapport au TagID ds la table tagID_Correspondance
	cmd = "Select * From tagID_Correspondance where Code = "..CodeTypeTable.." and TagID = '"..tagID.."'";
	bib = raceresult.dbSki:TableLoad(TabletagID_Correspondance, cmd):GetCell("Dossard", 0);
	 Alert("bib = "..bib);
	if bib ~= "" then 
		-- Alert("bib = "..bib);
		-- Alert("raceresult.code_competition = "..raceresult.code_competition);
		-- Alert("ActiveID = "..ActiveID);
		-- Alert("LoopID = "..LoopID);
		-- Alert("LoopCanal = "..LoopCanal);
		-- on vas chercher le nombre de tour que le dos doit faire 
		cmd = "Select * From tagID_Tour Where Code = "..raceresult.code_competition..
													 " and AdresseIP = '"..ActiveID..
													 "' and LoopID = '"..LoopID..
													 "' and LoopCanal = '"..LoopCanal..
													 "'";
		-- Alert("cmd = "..cmd);											 
		TabletagID_Tour = raceresult.dbSki:GetTable('tagID_Tour');
		raceresult.dbSki:TableLoad(TabletagID_Tour, cmd);
		Testnbtour = raceresult.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows();
		Alert("Testnbtour = "..Testnbtour);
		for i=0, raceresult.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows()-1 do 
		bibMini = TabletagID_Tour:GetCell('bibMini', i);
		bibMax = TabletagID_Tour:GetCell('bibMax', i);
		-- Alert("bib = "..bib);
		--Alert("bibMini = "..bibMini);
		-- Alert("bibMini = "..bibMax);
		-- Alert("i = "..i);
			if tonumber(bib) >= tonumber(bibMini) and tonumber(bib) <= tonumber(bibMax) then
				NbToursAFaire = TabletagID_Tour:GetCellInt('Tour', i);
				-- Alert("je suis dans la bonne ligne"..NbToursAFaire);
			end	
		end
		
		-- Pour éviter d'avoir la variable NbToursAFaire soit nul
		if NbToursAFaire ~= nil then else NbToursAFaire = 0 end
		Alert("le Dossard :"..bib.."doit faire :"..NbToursAFaire.." aTour")
	else 
	NbToursAFaire = 0;
	end 
end 

function rechercheHeureDepartDos(Dossard)
	-- recherche et création de variable des heure de départ des épreuve
	cmd = "Select * From Resultat Where Code = "..raceresult.code_competition.." and Dossard = '"..Dossard.."'";
			
		-- test = raceresult.dbSki:TableLoad(Resultat, cmd):GetCell('Code_epreuve', 0);
		--raceresult.dbSki:GetTable('Ranking'):GetCell('Code_epreuve', 1);
		-- for m=1,tonumber(NbEpreuve) do
			-- local steph = 'HeureDepartEpreuve'..m
		 --steph = raceresult.dbSki:GetTable('Epreuve'):GetCell('Heure_depart', m);
		 --"HeureDepartEpreuve"..m = raceresult.dbSki:GetTable('Epreuve'):GetCell('Heure_depart', m);
		-- Alert("NbEpreuve : "..HeureDepartEpreuve1);
		-- end
		--Alert("NbEpreuve : "..test);
		return 0 --raceresult.dbSki:GetTable('Ranking'):GetCellInt('Code_epreuve', 0);
end

function RechercheCountTourActif(CodeTypeTable,tagID, LoopID,LoopCanal);
	-- recherche du dossard par rapport au TagID ds la table tagID_Correspondance
	cmd = "Select * From tagID_Passings Where Code = "..raceresult.code_competition..
												 " and AdresseIP = '"..ActiveID..
												 "' and LoopID = '"..LoopID..
												 "' and LoopCanal = '"..LoopCanal..
												 "'";
	CountTourActif = raceresult.dbSki:TableLoad(TabletagID_Passings, cmd):GetCell("CountTourActif", 0);
	if CountTourActif == '' then 
		CountTourActif = 0 
	end
	Alert("CountTourActif = "..CountTourActif);
end

-- fonction qui permet de mettre a jour lr Nb tour dans la table tagID_finish
function AddNbTours(NbTours, tagID, ActiveID, LoopID, LoopCanal)
	Alert("AddNbtours LoopID = "..ActiveID);
	local cmd = 
		"Update tagID_Finish SET Tour = "..NbTours..
		" Where Code = "..raceresult.code_competition..
		" and AdresseIP = '"..ActiveID..
		"' and LoopID = '"..LoopID..
		"' and LoopCanal = '"..LoopCanal..
		"' and TagID = '"..tagID..
		"'"
	raceresult.dbSki:Query(cmd);
 
end

function InsertNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait)
	 --Alert("Num_Tir = "..Num_Tir);	
 local r = TabletagID_TourPena:AddRow();				
				TabletagID_TourPena:SetCell("Code", r, tonumber(raceresult.code_competition));
				TabletagID_TourPena:SetCell("AdresseIP", r, ActiveID);
				TabletagID_TourPena:SetCell("LoopID", r, LoopID);
				TabletagID_TourPena:SetCell("LoopCanal", r, LoopCanal);
				TabletagID_TourPena:SetCell("Dossard", r, bib);
				TabletagID_TourPena:SetCell("Tir1", r, tonumber(NbTour_Fait));	
				TabletagID_TourPena:SetCell("Tir2", r, 0);
				TabletagID_TourPena:SetCell("Tir3", r, 0);
				TabletagID_TourPena:SetCell("Tir4", r, 0);
				TabletagID_TourPena:SetCell("Num_Tir", r, tonumber(Num_Tir));
				raceresult.dbSki:TableInsert(TabletagID_TourPena, r);
				Success("Ajout dos ="..bib.. " dans la TabletagID_TourPena");	
end

function AddNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait)
	Alert("AddNbtours_pena Num_Tir = "..Num_Tir);
	Alert("AddNbtours LoopID = "..NbTour_Fait);
	
	local cmd = 
		"Update tagID_TourPena SET Tir"..Num_Tir.." = "..NbTour_Fait..
		", Num_Tir = "..Num_Tir..
		" Where Code = "..raceresult.code_competition..
		" and AdresseIP = '"..ActiveID..
		"' and LoopID = '"..LoopID..
		"' and LoopCanal = '"..LoopCanal..
		"' and Dossard = '"..bib..
		"' "
		;
	raceresult.dbSki:Query(cmd);
	Success("Ajout d\' 1 tour au dos ="..bib.. " dans la TabletagID_TourPena Donc :"..NbTour_Fait);		
end

function AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib)
-- ecriture du TagID dans la table tagID_Finish
				local r = TableTagID_Finish:AddRow();				
				TableTagID_Finish:SetCell("Code", r, raceresult.code_competition);
				TableTagID_Finish:SetCell("AdresseIP", r, ActiveID);
				TableTagID_Finish:SetCell("LoopID", r, LoopID);
				TableTagID_Finish:SetCell("LoopCanal", r, LoopCanal);
				TableTagID_Finish:SetCell("TagID", r, tagID);		
				TableTagID_Finish:SetCell("Passage", r, passage);
				TableTagID_Finish:SetCell("Tour", r, Tour);
				raceresult.dbSki:TableInsert(TableTagID_Finish, r);
					Success("Ajout dos ="..bib.. " dans la TableTagID_Finish");	

end


function refreshTagIDFinish(tagID, passage, LoopID, LoopCanal)
	local cmd = 
			"update tagID_Finish SET Passage = '"..passage..
		" 'Where Code = "..raceresult.code_competition..
		" And AdresseIP = '"..ActiveID..
		"' And LoopID = '"..LoopID..   
		"' And LoopCanal = '"..LoopCanal.. 
		"' And tagID = '"..tagID..
		"' "
		;
	raceresult.dbSki:Query(cmd);
	Success("Mise a jour du N° de passage :"..passage.." du TagID ="..tagID.. " dans la TableTagID_Finish");
	
end

					
function GetHeurePassage(dossard, passage)
	local cmd =
		" select * From Resultat_Chrono where Code_evenement = "..raceresult.code_competition..
		" And Code_manche = "..raceresult.code_manche..
		" And Id = "..passage..
		" And Dossard = "..dossard
	;
	tResultatChrono = raceresult.dbSki:GetTable('Resultat_Chrono');
	raceresult.dbSki:TableLoad(tResultatChrono, cmd);
	--Alert('raceresult.code_competition = '..raceresult.code_competition);
	--Alert('raceresult.code_manche = '..raceresult.code_manche);
	--Alert('idPassage = '..passage);
	--Alert('dossard = '..dossard);
	
	if tResultatChrono == nil then return -1 end
	if tResultatChrono:GetNbRows() == 0 then return -1 end
	
	-- Heure de passage existe ...	
	return tResultatChrono:GetCellInt('Heure',0);
end

function GetTempsNet(dossard)

	local heureDep = GetHeurePassage(dossard, 0);
	local heureArr = GetHeurePassage(dossard, -1);
	
	if heureArr > heureDep and heureDep >= 0 then
		return heureArr-heureDep;
	else
		return -1;
	end
end


function GetTempsNetInter(dossard, inter)

	local heureDep = GetHeurePassage(dossard, 0);
	local heureInter = GetHeurePassage(dossard, inter);
	
	if heureInter > heureDep and heureDep >= 0 then
		return heureInter-heureDep;
	else
		return -1;
	end
end

-- fonction permetant d'aller chercher le nb de pena
function GetPenaBiathlon(dossard, passage)
	local dossard = 1;
	local Num_Tir = 3;
	local Code_coureur = GetCodecoureur(dossard);
	Alert('GetPenaBiathlon Code_coureur = '..Code_coureur);
	local cmd =
		" select * From Resultat_Manche where Code_evenement = "..raceresult.code_competition..
		" And Code_coureur = '"..Code_coureur..
		"'"
	;
	tResultat_Manche = raceresult.dbSki:GetTable('Resultat_Manche');
	raceresult.dbSki:TableLoad(tResultat_Manche, cmd);
	--Alert('raceresult.code_competition = '..raceresult.code_competition);
	--Alert('raceresult.code_manche = '..raceresult.code_manche);
	--Alert('idPassage = '..passage);
	--Alert('dossard = '..dossard);
	
	if tResultat_Manche == nil then return -1 end
	if tResultat_Manche:GetNbRows() == 0 then return -1 end
	
	-- Heure de passage existe ...	
	--return tResultat:GetCellInt('Penalite',0);
	if Num_Tir == 1 then
	i = 1;
	elseif Num_Tir == 2 then
	i = 3;
	elseif Num_Tir == 3 then
	i = 5;
	elseif Num_Tir == 4 then
	i = 7;
	elseif Num_Tir == 5 then
	i = 9;
	elseif Num_Tir == 6 then
	i = 11;
	end
	Alert('pena tir biathlon = '..string.sub(tResultat_Manche:GetCell('Penalite',0),i,i));
end

-- fonction permetant de trouver le Code coureur / au dos
function GetCodecoureur(dossard)
	local cmd =
		" select * From Resultat where Code_evenement = "..raceresult.code_competition..
		" And Dossard = "..dossard
	;
	tResultat = raceresult.dbSki:GetTable('Resultat');
	raceresult.dbSki:TableLoad(tResultat, cmd);
	--Alert('raceresult.code_competition = '..raceresult.code_competition);
	--Alert('raceresult.code_manche = '..raceresult.code_manche);
	--Alert('idPassage = '..passage);
	--Alert('dossard = '..dossard);
	
	if tResultat == nil then return -1 end
	if tResultat:GetNbRows() == 0 then return -1 end
	Alert('GetCodecoureur = '..tResultat:GetCell('Code_coureur',0));
	-- Heure de passage existe ...	
	return tResultat:GetCell('Code_coureur',0);
end

-- format hh:mm:ss.kkk
function GetChrono(hourPassage)
	local hour = string.sub(hourPassage,1,2);
	local minute = string.sub(hourPassage,4,5);
	local sec = string.sub(hourPassage,7,8);
	local milli = string.sub(hourPassage,10,12);
	return 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
end

function AddTimePassage(chrono, passage, bib, tagID)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'raceresult: '..ActiveID, tag = tagID }
	);
	
	bib = bib or '';
	tagID = tagID or '';
	passage = passage or '';
	chrono = chrono or '';
	Success('<passage_add tagId='..tagID..' bib='..bib..' passage='..passage..' chrono='..chrono..'>');

end

function SavePassingCurrent(value)
	-- Prise de la Valeur en Mémoire 
	raceresult.passingCurrent = value;
	
	-- Enregistrement en MySQL 
	cmd = 
		"update tagID_Passings set Passings = "..
		tostring(raceresult.passingCurrent)..
		" Where Code = "..raceresult.code_competition..
		" And AdresseIP = '"..ActiveID..
		"'"
		;
	raceresult.dbSki:Query(cmd);

end

-- Configuration du Device

function device.OnConfiguration(node)
	config = {};
	-- width = longueur;
	-- height = largeur;
	
	local dlg_RaceResultConfig = wnd.CreateDialog(
		{
			parent = RaceresultWebServeur.panel,
			icon = "./res/32x32_ffs.png",
			label = "Configuration du raceresult WebServeur",
			width = 600,
			height = 650
		})
		dlg_RaceResultConfig:LoadTemplateXML({ 
		xml = './device/raceresult.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'config_RaceResult_WebServeur'
	});

	dlg_RaceResultConfig:GetWindowName('config_IdDecodeur'):SetValue(node:GetAttribute('config_IdDecodeur', 'D-5314'));
	dlg_RaceResultConfig:GetWindowName('config_PortDecodeur'):SetValue(node:GetAttribute('config_PortDecodeur', '3601'));
	dlg_RaceResultConfig:GetWindowName('config_NumFichier'):SetValue(node:GetAttribute('config_NumFichier', '191'));	
	dlg_RaceResultConfig:GetWindowName('config_Passage'):SetValue(node:GetAttribute('config_Passage', '-1'));
	if node:GetAttribute('SystemeActif') == "1" then
		dlg_RaceResultConfig:GetWindowName('checkbox_config_Systeme'):SetValue(true);
	else
		dlg_RaceResultConfig:GetWindowName('checkbox_config_Systeme'):SetValue(false);
	end
	
	if node:GetAttribute('bib') == "1" then
		dlg_RaceResultConfig:GetWindowName('checkbox_config_Lect_Dos'):SetValue(true);
	else
		dlg_RaceResultConfig:GetWindowName('checkbox_config_Lect_Dos'):SetValue(false);
	end

-- Toolbar Principale ...
	config.tb = dlg_RaceResultConfig:GetWindowName('tb');
	btnSave = config.tb:AddTool("Valider", "./res/32x32_save.png");
	config.tb:AddStretchableSpace();
	btnClose = config.tb:AddTool("Fermer", "./res/32x32_close.png");
	config.tb:Realize();

	function OnSaveConfig(evt)
		node:ChangeAttribute('config_IdDecodeur', dlg_RaceResultConfig:GetWindowName('config_IdDecodeur'):GetValue());
		node:ChangeAttribute('config_PortDecodeur', dlg_RaceResultConfig:GetWindowName('config_PortDecodeur'):GetValue());
		node:ChangeAttribute('config_NumFichier',  dlg_RaceResultConfig:GetWindowName('config_NumFichier'):GetValue());
		node:ChangeAttribute('config_Passage', dlg_RaceResultConfig:GetWindowName('config_Passage'):GetValue());
		if dlg_RaceResultConfig:GetWindowName('checkbox_config_Systeme'):GetValue() == true then
			node:ChangeAttribute('SystemeActif',  "1");
		else
			node:ChangeAttribute('SystemeActif',  "0");
		end
		if dlg_RaceResultConfig:GetWindowName('checkbox_config_Lect_Dos'):GetValue() == true then
			node:ChangeAttribute('bib',  "1");
		else
			node:ChangeAttribute('bib',  "0");
		end


		local doc = app.GetXML();
		doc:SaveFile();
		dlg_RaceResultConfig:EndModal(idButton.OK);
	end

		dlg_RaceResultConfig:Bind(eventType.MENU, OnSaveConfig, btnSave); 
		dlg_RaceResultConfig:Bind(eventType.BUTTON, OnPath, dlg_RaceResultConfig:GetWindowName('path'));
		dlg_RaceResultConfig:Bind(eventType.MENU, function(evt) dlg_RaceResultConfig:EndModal(idButton.CANCEL) end, btnClose);
		

	-- Lancement de la dialog
	dlg_RaceResultConfig:Fit();
	dlg_RaceResultConfig:ShowModal();

	-- Liberation Memoire
	dlg_RaceResultConfig:Delete();
	
	function OnExit(evt)
	dlg_RaceResultConfig:EndModal();
	end
	
end

