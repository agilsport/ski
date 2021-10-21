-- RaceResult gere systeme Actif et Passif 
-- connection ethernet entre le decodeur et l'ordi en IP Fixe obligatoire
-- systeme Actif gestion de 8 N° de Loop  et 8 N° de canal sur un memes decodeur 
-- Gestion du comptage de nombre de tour de pena si on active le couttourpena sur une boucle
-- aller dans gestion des options
-- Gestion de table de corespondance Généric a tt les évènements ou gestion de table propre à l'évènement traiter
-- dans les deux cas la mm table sert a plusieurs décodeur sur le memes EVT
-- a partir de la version 7.4 
--      *gestion des entier avec la version du lua 5.4  
--      *demande de renseigner les identifiants password et N° de fichier pour se cennecter au serveur RaceResult
-- 18/05/2021  Version   7.93 
	-- lecture d'un fichier txt de SAV Ok
	-- Affichage du delay de double detection en minute 
-- 31/07/2021 Version   7.94
	-- Amelioration de la table corespondance avec insert et delate ligne
	-- enregistrement des données si modifications manuelle
	-- mise en place de TableFlush ds les insert options pour ne pas avoir de doublons
-- 09/09/2021	Version  8.1
	-- bug onclose
	-- nettoyage code
	-- debugage option
	-- test lecture dos OK
-- 12/09/2021 Version   8.2
	-- factorisation RechercheTagId_Rech_Der_Passge_TagID
	-- "-9999"  Tag_ID inconnu ds la table de correspondance
	-- "-7777" dossard inconnu
-- 12/09/2021 Version   8.3
	-- Mise en norma RaceResult comme ds RaceresultWebRestApi
	-- mise en place de l'activation de l'upload a distance
	-- corection bug maquage marqueur 
-- 12/09/2021 Version   8.4
	-- mise de la valeur passage par rapport a la valeur ds le skiffs.xml	
-- 12/09/2021 Version   8.5
	-- mise en sommeil des Alert de developpement
-- 21/10/2021 Version 9.0
	-- version officielles skiffs 2021/2022	
	
dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface, adresse IP, N° de port donné par race result
function device.GetInformation()
	return { 
		version = 9.0, 
		code = 'RaceResult_IP', 
		name = 'RaceResult IP', 
		class = 'chrono', 
		interface = { { type='tcp', hostname = '192.168.2.214', port = 3601 } } 
	};
end	

-- Creation et initialisation table RaceResult
RaceResult = {};

-- Timer 
RaceResult.timerDelay = 500;

-- Timer 
RaceResult.timerDelayConnect = 10000;

-- Racings
RaceResult.alive = 0;

-- Code Competition 
RaceResult.code_competition = -1;

-- Actif ou pas
RaceResult.ActiveStart = "Non Actif";

-- status
RaceResult.GetStatus = "Ko";

-- nb de lignes 
nbLignes = 0;

-- Nb de tour
NbTourRealiser = 0;

--activation de la fonction debugage
RaceResult.debugage = false;

-- numero de passage ou le decodeur doit envoyer le chrono par default
passage = '';

-- recherche du décalage horaire local par rapport à l'heure UTC Pour la lecture d'un fichier de trackbox
DiffGMT = app.GetTimeZone()
RaceResult.DiffGMT = tonumber(string.sub(DiffGMT, 2, 5));

function Alert(txt)
	RaceResult.gridMessage:AddLine(txt);
end

function Success(txt)
	RaceResult.gridMessage:AddLineSuccess(txt);
end

function Warning(txt)
	RaceResult.gridMessage:AddLineWarning(txt);
end

function Error(txt)
	RaceResult.gridMessage:AddLineError(txt);
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
		icon = './logo/Mini-logo-RaceResult.png',
		xml = './device/RaceResult.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'dashboard'
	});

	-- initialisation de la table RaceResult
	RaceResult.dbSki = sqlBase.Clone();
	TabletagID_Passings = RaceResult.dbSki:GetTable('tagID_Passings');
	TabletagID_Correspondance = RaceResult.dbSki:GetTable('tagID_Correspondance');
	TableTagID_Finish = RaceResult.dbSki:GetTable('tagID_Finish');
	TabletagID_Tour = RaceResult.dbSki:GetTable('tagID_Tour');
	TabletagID_TourPena = RaceResult.dbSki:GetTable('tagID_TourPena');
	
	RaceResult.panel = panel;
	
	-- Initialisation des Controles 
	RaceResult.gridMessage = panel:GetWindowName('message');
	
	-- ToolBar
	RaceResult.tb = panel:GetWindowName('tb');
	RaceResult.tb_start = RaceResult.tb:AddTool("Start", "./res/32x32_chrono_v3.png");
	RaceResult.tb_outil = RaceResult.tb:AddTool("Outil RaceResult", "./res/32x32_configure.png", "outils",  itemKind.DROPDOWN);
	RaceResult.tb_OnGestionTableCorres = RaceResult.tb:AddTool("Import table corespondance", "./res/32x32_divide_column.png");
	RaceResult.tb_Param = RaceResult.tb:AddTool("Prametrage", "./res/32x32_config.png", "Parametrage plage dossards relais",  itemKind.DROPDOWN);
	RaceResult.tb:AddSeparator();
	
---- Sous menu table outils
	local menuSend =  menu.Create();
	menuSend:AppendSeparator();	
	RaceResult.tb_outil_ping = menuSend:Append({label="Test Connection décodeur ?", image ="./res/32x32_time-admin.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_outil_mode = menuSend:Append({label="Ligne de Détection Active ou pas ?", image ="./res/vpe32x32_search.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_outil_protocol = menuSend:Append({label="Protocol du decodeur utilisé ?", image ="./res/32x32_tasks.png"});
	menuSend:AppendSeparator();	
	RaceResult.tb_outil_status = menuSend:Append({label="Status du décodeur 'on/off", image ="./res/chrono32x32_traffic_light.png"});
	menuSend:AppendSeparator();	
	RaceResult.tb_outil_passings = menuSend:Append({label="Nb de Passings enregistrer ds le décodeur ?", image ="./res/32x32_time-admin.png"});
	menuSend:AppendSeparator();	
	RaceResult.tb_outil_gettime = menuSend:Append({label="heure du décodeur ?", image ="./res/chrono32x32_clock_inter.png"});
	menuSend:AppendSeparator();	
	RaceResult.tb_outil_OnChargeBat = menuSend:Append({label="Niveau de Charge Batterie", image ="./res/32x32_battery_half.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_outil_OnRechargeFichier = menuSend:Append({label="Recharge d'un fichier SAV du décodeur", image ="./res/32x32_lua.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_outil_OnRechargeTagId = menuSend:Append({label="Rechargement Séquence", image ="./res/32x32_update.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_outil_OnStartGPS_Time = menuSend:Append({label="Synchro du GPS Time", image ="./res/32x32_antenna.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_outil_OnStartOperation = menuSend:Append({label="Activation Du chrono", image ="./res/32x32_antenna.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_outil_OnStopOperation = menuSend:Append({label="Mise en stanby du Chrono", image ="./res/32x32_stop.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_outil_OnStartUpload = menuSend:Append({label="Activation De l'Upload", image ="./res/32x32_antenna.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_outil_OnStopUpload = menuSend:Append({label="Désctivation De l'Upload", image ="./res/32x32_stop.png"});
	RaceResult.tb:SetDropdownMenu(RaceResult.tb_outil:GetId(), menuSend);
	
---- Sous menu parametre	
	local menuSend =  menu.Create();
	menuSend:AppendSeparator();	
	RaceResult.tb_Param_Options = menuSend:Append({label="Configuration des options (Nb Tour / Passage) ", image ="./res/32x32_options.png"});
	menuSend:AppendSeparator();	
	RaceResult.tb_Param_TagIdFinish = menuSend:Append({label="Vider la Table des tagID déjà arrivés ", image ="./res/32x32_background.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_Param_tagID_TourPena = menuSend:Append({label="Vider la Table de memo des nb de tours de Péna fait ", image ="./res/32x32_background.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_Param_Passing = menuSend:Append({label="Mise a zéro du compteur passing", image ="./res/32x32_update.png"});
	menuSend:AppendSeparator();
	RaceResult.tb_Param_Socket = menuSend:Append({label="Réinitialisation de la connection au décodeur", image ="./res/32x32_postition_horizontal.png"});
	RaceResult.tb:SetDropdownMenu(RaceResult.tb_Param:GetId(), menuSend);
	
	-- Static Connect
	RaceResult.Connect = wnd.CreateStaticText({parent = RaceResult.tb, label = "Test Connect", style = wndStyle.ALIGN_LEFT});
	RaceResult.Connect:SetLabel("Non Connect");
	RaceResult.tb:AddControl(RaceResult.Connect);
	RaceResult.tb:AddSeparator();	
	
	-- Static Info
	RaceResult.info = wnd.CreateStaticText({parent = RaceResult.tb, label = "Timer : ------  Passings : ----/----", style = wndStyle.ALIGN_LEFT});
	RaceResult.tb:AddControl(RaceResult.info);
	RaceResult.tb:AddSeparator();	

	-- Niveau de Batterie
	RaceResult.battery = wnd.CreateStaticText({parent = RaceResult.tb, label = "Charge Bat =---%", style = wndStyle.ALIGN_LEFT});
	RaceResult.tb:AddControl(RaceResult.battery);
	RaceResult.tb:Realize();

	-- Prise des Evenements (Bind)onglet principal
	RaceResult.panel:Bind(eventType.MENU, OnStartRaceResult, RaceResult.tb_start);
	RaceResult.panel:Bind(eventType.MENU, OnraceResultOutils, RaceResult.tb_outil);
	RaceResult.panel:Bind(eventType.MENU, OnOpenTableCorespondance, RaceResult.tb_OnGestionTableCorres);
	RaceResult.panel:Bind(eventType.MENU, OnParamko, RaceResult.tb_Param);
	-- onglet du sous menu outil 
	RaceResult.panel:Bind(eventType.MENU, OnPing, RaceResult.tb_outil_ping);
	RaceResult.panel:Bind(eventType.MENU, OnMode, RaceResult.tb_outil_mode);
	RaceResult.panel:Bind(eventType.MENU, OnProtocol, RaceResult.tb_outil_protocol);
	RaceResult.panel:Bind(eventType.MENU, OnStatus, RaceResult.tb_outil_status);
	RaceResult.panel:Bind(eventType.MENU, OnPassings, RaceResult.tb_outil_passings);
	RaceResult.panel:Bind(eventType.MENU, OnGetTime, RaceResult.tb_outil_gettime);
	RaceResult.panel:Bind(eventType.MENU, OnChargeBat, RaceResult.tb_outil_OnChargeBat);
	RaceResult.panel:Bind(eventType.MENU, OnRechargeFichier, RaceResult.tb_outil_OnRechargeFichier);
	RaceResult.panel:Bind(eventType.MENU, OnRechargeTagId, RaceResult.tb_outil_OnRechargeTagId);
	RaceResult.panel:Bind(eventType.MENU, OnStartGPS_Time, RaceResult.tb_outil_OnStartGPS_Time);
	RaceResult.panel:Bind(eventType.MENU, OnStartOperation, RaceResult.tb_outil_OnStartOperation);
	RaceResult.panel:Bind(eventType.MENU, OnStopOperation, RaceResult.tb_outil_OnStopOperation);
	RaceResult.panel:Bind(eventType.MENU, OnStartUpload, RaceResult.tb_outil_OnStartUpload);
	RaceResult.panel:Bind(eventType.MENU, OnStopUpload, RaceResult.tb_outil_OnStopUpload);

-- onglet du sous menu outil 
	RaceResult.panel:Bind(eventType.MENU, OnOpenOptions, RaceResult.tb_Param_Options);
	RaceResult.panel:Bind(eventType.MENU, OnDeleteTagIdFinish, RaceResult.tb_Param_TagIdFinish);
	RaceResult.panel:Bind(eventType.MENU, OnDeleteTagIdTourPena,RaceResult.tb_Param_tagID_TourPena);
	RaceResult.panel:Bind(eventType.MENU, OnClearPassing, RaceResult.tb_Param_Passing);
	RaceResult.panel:Bind(eventType.MENU, OnReOpenSocket, RaceResult.tb_Param_Socket);
		
-- Chargement des Informations de la Course ...
	RaceResult.code_competition = -1;
	local rc, raceInfo = app.SendNotify('<race_load>');
	if rc == true then
		local tEvenement = raceInfo.tables.Evenement;
		RaceResult.code_competition = tEvenement:GetCellInt('Code', 0);
		RaceResult.code_manche = raceInfo.Code_manche or 1 ;
		Success('Compétition '..tostring(RaceResult.code_competition)..' ok ..');
	end
	
-- Recherche et creation d'une variable pour l'Adresse IP et le port utilser pour le decodeur actif OK
	local sockClient = mt_device.obj;
	local tPeer = sockClient :GetPeer();
	ActiveID = tPeer.ip;
	ActivePort = tPeer.port;
	--Alert("ActiveID :"..ActiveID..ActivePort);	
	
-- Recherche si un evenement existe dans la table tagID_Passings OK
	cmd = "Select * From tagID_Passings Where Code = "..RaceResult.code_competition.." and AdresseIP = '"..ActiveID.."'";
	TableTagID_Passings = RaceResult.dbSki:GetTable('tagID_Passings');
	RaceResult.dbSki:TableLoad(TableTagID_Passings, cmd);	
	
	if TableTagID_Passings:GetNbRows() == 0 then
		Alert("pas d'évènement Dans la table tagID_Passings on la créer");
		
-- creation de la variable Passing Current (nb de transpondeur detecter dans la ligne chrono)		
	RaceResult.passingCurrent = 0;
	
-- creation de variables TypeTable et CodeTypeTable(permetant de travailler une table générique a tt les evt ou une table spécifique à l'EVT)
	-- if passage == '' then passage = -1	end
	passage = node:GetAttribute('config_Passage') or -1;
	LoopID = 'Loop0';
	LoopCanal = 'LoopCanal0';
	TypeTable = 'ND';
	CountTourActif = 0;
	SystemeActif = 0;
	CodeTypeTable = RaceResult.code_competition;
	ID_1er_Inter = 1;
--delai double detection
	DelayDoubleDetect = 600000;  -- = à 10 minutes   ///  60000 = à 1 min
	
-- ecriture des parametres dans la tagID_Passings et du type table
	AddTabletagID_Passings(RaceResult.code_competition,ActiveID,ActivePort,LoopID,LoopCanal,passage,ID_1er_Inter,RaceResult.passingCurrent,TypeTable,DelayDoubleDetect,CountTourActif);		
		Warning("pas de table de corespondace pour cet évènement ...");
		Warning("Penser à aller dans l'onglet gestion pour importer une table avant de chronometrer...");
	else
-- si il y a une ligne dans tagID_Passings On prend les valeurs de la table pour renseigner les variables 
		RaceResult.passingCurrent = TableTagID_Passings:GetCellInt('Passings', 0);
		--Alert("RaceResult.passingCurrent ="..RaceResult.passingCurrent);
		TypeTable = TableTagID_Passings:GetCell('TypeTable', 0);
		passage = TableTagID_Passings:GetCell('passage', 0);
		ID_1er_Inter = TableTagID_Passings:GetCellInt('ID_1er_Inter', 0);
		-- DelayDoubleDetect = TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
		--Alert("RaceResult.passingCurrent ="..RaceResult.passingCurrent.."/ TypeTable :"..TypeTable);
			if TypeTable == 'GEN' then
				CodeTypeTable = 0;
			else
				CodeTypeTable = RaceResult.code_competition ;
			end
	end
	
	-- On recherche si il y a une ou plusieurs lignes de créer ds la table TabletagID_Tour pour l'evt
	-- Si pas de ligne on inscrit dans latable	
	cmd = "Select * From tagID_Tour Where Code = '"..RaceResult.code_competition.."' And AdresseIP = '"..ActiveID.."' Order by bibMini";
	if RaceResult.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows() == 0 then
		local bibMini = 1;
		local bibMax = 9999;
		local LoopID = 'Loop0';
		local LoopCanal = 'LoopCanal0';
		local Tour = 0;
		AddTabletagID_Tour(RaceResult.code_competition,ActiveID,bibMini,bibMax,LoopID,LoopCanal,Tour);
	end
-- Recherche si une table de corespondance existe dans la table tagID_Correspondance
	cmd = "Select * From tagID_Correspondance Where Code = "..CodeTypeTable.." Order by Dossard";
	if RaceResult.dbSki:TableLoad(TabletagID_Correspondance, cmd):GetNbRows() == 0 then
		Alert("pas de Table de correspondance pour cet évènement : "..RaceResult.code_competition);
	else
	-- Alert("TypeTable ="..TypeTable);
		if TypeTable == 'GEN' then
			Alert("Utilisation de la table Générique pour l'EVT  : "..RaceResult.code_competition.." avec "..TabletagID_Correspondance:GetNbRows().." lignes créées");
		elseif TypeTable == 'EVT' then
			Alert("Utilisation de la table spécifique à l'évènement N°: "..RaceResult.code_competition.." avec "..TabletagID_Correspondance:GetNbRows().." lignes créées");
		else
			Alert("pas de table de corespondance pour l'EVT  : "..RaceResult.code_competition);
		end	
	end
			
-- creation de la variables PassingCount (nb de transpondeur detecter par la ligne chrono)
		RaceResult.RecordsCount = 0;
		--Alert("passingCurrent :"..RaceResult.passingCurrent.."/ "..RaceResult.RecordsCount);

--rechercheHeureDepartDos = rechercheHeureDepartDos(1)

--Alert("rechercheHeureDepartDos : "..rechercheHeureDepartDos);
-- Affichage ...
	panel:Show(true);
	
	local mgr = app.GetAuiManager();
	mgr:AddPane(panel, {
		caption = "Tableau de Bord Race Result / "..ActiveID..' => Passage N° '..passage,
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
	RaceResult.timerConnect = timer.Create(RaceResult.panel);
	if RaceResult.timerConnect ~= nil then
		RaceResult.timerConnect:Start(RaceResult.timerDelayConnect);
	end
	RaceResult.panel:Bind(eventType.TIMER, OnTimerBatConnect, RaceResult.timerConnect);
	
	
	--local toto = GetHeurePassage(32, 0);

end

-- Fermeture
function device.OnClose()
	RaceResult.Stop = true;
	
	if RaceResult.panel ~= nil then
		-- On Ignore les "event" qui peuvent encore être dans la pile ...
		RaceResult.panel:UnbindAll();
	end

	if RaceResult.timer ~= nil then
		RaceResult.timer:Delete();
	end
	
	if RaceResult.timerConnect ~= nil then
		RaceResult.timerConnect:Delete();
	end
	
	if RaceResult.watchDogConnect ~= nil then
		RaceResult.watchDogConnect:Delete();
	end
	
	if RaceResult.panel ~= nil then
		local mgr = app.GetAuiManager();
		mgr:DeletePane(RaceResult.panel);
	end

-- Appel OnClose Metatable
	mt_device.OnClose();
end

--Outils:
	-- Fonction des tables de correspondance
		--fonction pour Vider une table de corespondance	
function OnClearTableCorres(evt)
	if RaceResult.panel:MessageBox("Confirmation du Vidage de la table de corespondance ?\n\nCette opération effecera le contenue de la table corespondance de cet évènement", "Confirmation du Vidage de la table de corespondance", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	-- Alert ("CodeTypeTable = "..CodeTypeTable.."et  TypeTable = ".. TypeTable);
	if CodeTypeTable ~= "" or  TypeTable ~= "" then
	cmd = "Delete From tagID_Correspondance Where Code = "..CodeTypeTable.." And TypeTable = '"..TypeTable.."'";
	RaceResult.dbSki:Query(cmd);
	else
	cmd = "Delete From tagID_Correspondance Where Code = "..RaceResult.code_competition;
	RaceResult.dbSki:Query(cmd);
	end
	
--	TableCorrespondance:RemoveAllRows();
	cmd = "Select * From tagID_Correspondance where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	RaceResult.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
	if TabletagID_Correspondance:GetNbRows() >= 1 then
		Alert("la table ne sais pas vider = "..TabletagID_Correspondance:GetNbRows());
	end	
	TypeTable = 'ND'
	--Alert('je modifi dans la table TagID_Passings'..TypeTable)
	cmd = "Update tagID_Passings SET TypeTable = '"..TypeTable.."' Where Code = "..RaceResult.code_competition.." And AdresseIP = '"..ActiveID.."'"
	RaceResult.dbSki:Query(cmd);
	Warning("Vidage table tagID_Correspondance ok...");

	-- Rafraichissement de la grille ...
	local grid = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
	grid:SynchronizeRows();
end

		-- chargement de la table de corespondance
function OnChargeTableCorres(CodeTypeTable, TypeTable)
 if Table.state == true then
	-- recherche si il y a deja une table de corespondance de charger dans la base
	cmd = "Select * From tagID_Correspondance Where Code = "..CodeTypeTable.." And TypeTable = '"..TypeTable.."'";
	RaceResult.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
	 if TabletagID_Correspondance:GetNbRows() >= 1 then
		if RaceResult.panel:MessageBox("Confirmation du chargement de la table de corespondance ?\n\nCette opération effacera la table actuellement dans la base de donnée \n avant d'effectuer le rechargement de la table.", "Confirmation du chargement des Tag_ID et Dossards", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
			return;
		end
		
		OnClearTableCorres(CodeTypeTable, TypeTable)
		
	 end
 
 
	if RaceResult.panel:MessageBox("Confirmation du chargement de la table de corespondance ?\n\nCette opération vas effectuer le chargement de la table.", "Confirmation du chargement des Tag_ID et Dossards", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
--  rechercher le fichier .db3 des séquences à relire et le charger en read.db3
	local fileDialog = wnd.CreateFileDialog(RaceResult.panel,
		"Sélection du fichier de corespondance",
		RaceResult.directory, 
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
						TabletagID_Correspondance:SetCell("Code", r, RaceResult.code_competition);
						end
				TabletagID_Correspondance:SetCell("TagID", r, TagID);		
				TabletagID_Correspondance:SetCell("Dossard", r, Dossard);
				TabletagID_Correspondance:SetCell("TypeTable", r, TypeTable);
				RaceResult.dbSki:TableInsert(TabletagID_Correspondance, r);
				end
			end
		end
		csvFile:close();
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
	cmd = "Update tagID_Passings SET TypeTable = '"..TypeTable.."' Where Code = "..RaceResult.code_competition.." And AdresseIP = '"..ActiveID.."'"
	RaceResult.dbSki:Query(cmd);
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

		--fonction pour charger une table générique
function OnValidTypeTableGen(evt)
	cmd = "Select * From tagID_Correspondance Where Code = '0' And TypeTable = 'GEN' Order by Dossard";
	RaceResult.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
	 if TabletagID_Correspondance:GetNbRows() >= 1 then
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable	= 'GEN' Where Code = "..RaceResult.code_competition.." And AdresseIP = '"..ActiveID.."'";
		RaceResult.dbSki:Query(cmd);
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
	cmd = "Select * From tagID_Correspondance Where Code = "..RaceResult.code_competition.." And TypeTable = 'EVT'";
	RaceResult.dbSki:TableLoad(TabletagID_Correspondance, cmd)
	
	if TabletagID_Correspondance:GetNbRows() >= 1 then
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable	= 'EVT' Where Code = "..RaceResult.code_competition.." And AdresseIP = '"..ActiveID.."'";
		RaceResult.dbSki:Query(cmd);
		TypeTable = 'EVT';	
		Table.state = true ;
		CodeTypeTable = tonumber(RaceResult.code_competition);
		--Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
		-- Rafraichissement de la grille ...
		local grid = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
		grid:SynchronizeRows();
		Success('Validation de l\'utisation d\'une table unique à l\'évènement pour cet évènement ! ');
	else
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable = 'EVT'  Where Code = "..RaceResult.code_competition.." And AdresseIP = '"..ActiveID.."'";
		RaceResult.dbSki:Query(cmd);
		TypeTable = 'EVT';	
		Table.state = true ;
		CodeTypeTable = tonumber(RaceResult.code_competition);
		Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
		OnChargeTableCorres(CodeTypeTable, TypeTable);
	end
	Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
end
	
		-- fonction qui enregistre le modif de la table de corespondance manuel
function OnSaveTableCorres()
	cmd = "Delete From tagID_Correspondance Where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	RaceResult.dbSki:Query(cmd);
	
	local Grid_Ligne = dlgCorespondance:GetWindowName('grid_TableCorrespondance'):GetTable();
	--Alert("RaceresultWebServeur_option:GetNbRows() = "..Grid_Ligne:GetNbRows());
	for i=0, Grid_Ligne:GetNbRows()-1 do
		TabletagID_Correspondance:SetCell("Code", i, Grid_Ligne:GetCellInt('Code', i));
		TabletagID_Correspondance:SetCell("TagID", i, Grid_Ligne:GetCell('TagID', i));
		TabletagID_Correspondance:SetCell("Dossard", i, Grid_Ligne:GetCellInt('Dossard', i));
		TabletagID_Correspondance:SetCell("TypeTable", i, TypeTable);
		RaceResult.dbSki:TableFlush(TabletagID_Correspondance, i);
	end
		Alert("Sauvegarde des lignes de la Table Correspondance éffectuer correctement"); 
end

		-- Insertion d'une ligne de corespondance
function OnInsertLigneCor(evt)
	local grid_Cores = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
	grid_Cores:InsertRows(grid_Cores:GetNumberRows());
	grid_Cores:SetGridCursor(grid_Cores:GetNumberRows()-1, 0);
end

		-- Suppression d'une ligne de corespondance
function OnDeleteLigneCor(evt)
	local grid_Cores = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
	local row = grid_Cores:GetGridCursorRow();
	if row >= 0 then
		grid_Cores:DeleteRows(row);
	end	
end

		-- boite de dialogue pour la gestion de la table de corespondance
function OnOpenTableCorespondance(evt)
-- Création Dialog 
	dlgCorespondance = wnd.CreateDialog({
		parent = RaceResult.panel,
		icon = "./res/32x32_ffs.png",
		label = 'Gestion des Tables de Corespondance',
		width = 500,
		height = 600
	});
	
	dlgCorespondance:LoadTemplateXML({ 
	xml = './device/RaceResult.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'cores_Table'
	});

	
	Table = {};
	Race_table = {};
	function OnClosedlgCorespondance(evt)
		dlgCorespondance:EndModal();
	end
	
	-- Grid corespondance
	cmd = "Select * From tagID_Correspondance Where Code = '"..CodeTypeTable.."' Order by Dossard";
	RaceResult.dbSki:TableLoad(TabletagID_Correspondance, cmd)
	
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
	Race_table.tb = dlgCorespondance:GetWindowName('tb');
	raceresultTb_Table = Race_table.tb:AddTool("Outil race Time", "./res/32x32_config.png", "outils",  itemKind.DROPDOWN);
	raceresultTb_Clear = Race_table.tb:AddTool('Remise à Zéro des Données', './res/32x32_clear.png');
	Race_table.tb:AddStretchableSpace();
	raceresultTb_InsertLigne = Race_table.tb:AddTool("Ajouter une Ligne", "./res/32x32_list_add.png");
	Race_table.tb:AddSeparator();
	raceresultTb_DeleteLigne = Race_table.tb:AddTool("Supprimer une Ligne", "./res/32x32_list_remove.png");
	Race_table.tb:AddSeparator();
	raceresultTb_Save = Race_table.tb:AddTool("Enregistrer", "./res/32x32_save.png");
	Race_table.tb:AddSeparator();
	raceresultTb_Exit = Race_table.tb:AddTool("Quitter", "./res/32x32_exit.png");

	local menuSend =  menu.Create();
	menuSend:AppendSeparator();
	raceresultTb_Table_TableGe = menuSend:Append({label="Utilisation de la Table Generique à tout les évènements", image ="./res/32x32_time-admin.png"});
	menuSend:AppendSeparator();	
	-- raceresultTb_OnChargeTableCorres = menuSend:Append({label="Upload d'une Table Generique à tout les évènements", image ="./res/32x32_time-admin.png"});
	-- menuSend:AppendSeparator();
	raceresultTb_Table_TableEvt = menuSend:Append({label="Upload et utilisation d'une Table unique à un évènement", image ="./res/vpe32x32_search.png"});
	Race_table.tb:SetDropdownMenu(raceresultTb_Table:GetId(), menuSend);
	Race_table.tb:Realize();
	
	-- Prise des Evenements (Bind)
	dlgCorespondance:Bind(eventType.MENU, OnraceResultOutil);
	-- dlgCorespondance:Bind(eventType.MENU, OnChargeTableCorres, raceresultTb_OnChargeTableCorres);
	dlgCorespondance:Bind(eventType.MENU, OnClearTableCorres, raceresultTb_Clear);
	dlgCorespondance:Bind(eventType.MENU, OnInsertLigneCor, raceresultTb_InsertLigne);
	dlgCorespondance:Bind(eventType.MENU, OnDeleteLigneCor, raceresultTb_DeleteLigne);
	dlgCorespondance:Bind(eventType.MENU, OnValidTypeTableGen, raceresultTb_Table_TableGe);
	dlgCorespondance:Bind(eventType.MENU, OnValidTypeTableEvt, raceresultTb_Table_TableEvt);
	dlgCorespondance:Bind(eventType.MENU, OnSaveTableCorres, raceresultTb_Save);
	dlgCorespondance:Bind(eventType.MENU, OnClosedlgCorespondance, raceresultTb_Exit);

	-- permet de verifier et fixer les choses avt le showmodal (à faire obligatoirement)
	dlgCorespondance:Fit();

	-- Affichage Modal
	dlgCorespondance:ShowModal();
	
end	

	-- Gestion des options pour le nombre dtour par tranche de dos et la gestion du N° de passage / au N° de tour
	-- Gestion des systeme Actifs
		-- Insertion d'une option par plage de dos
function OnInsertTrDos(evt)
	local grid_Ligne = dlgOptionTable:GetWindowName('grid_Option');
	grid_Ligne:InsertRows(grid_Ligne:GetNumberRows());
	grid_Ligne:SetGridCursor(grid_Ligne:GetNumberRows()-1, 0);
end

		-- Suppression d'une Option
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

		-- sauvegarde des grid option
function OnSaveOption(evt)

	cmd = "Delete From tagID_Tour Where Code = "..RaceResult.code_competition.." And AdresseIP = '"..ActiveID.."'";
	RaceResult.dbSki:Query(cmd);
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
	
	cmd = "Delete From tagID_Passings Where Code = "..RaceResult.code_competition.." And AdresseIP = '"..ActiveID.."'";
	RaceResult.dbSki:Query(cmd);
	local grid_Param = dlgOptionTable:GetWindowName('grid_Param');
	local Grid_Param = grid_Param:GetTable();
	-- Alert("raceresult_option:GetNbRows() = "..Grid_Param:GetNbRows());
	for i=0, Grid_Param:GetNbRows()-1 do
			--enregistrement de la grid option dans la table TabletagID_Passings						
		local Code = Grid_Param:GetCellInt('Code', i);
		local AdresseIP = Grid_Param:GetCell('AdresseIP', i);
		local Port = Grid_Param:GetCell('Port', i);		
		local LoopID = Grid_Param:GetCell('LoopID', i);
		local LoopCanal = Grid_Param:GetCell('LoopCanal', i);
		local passage = Grid_Param:GetCell('passage', i);
		local ID_1er_Inter = Grid_Param:GetCellInt('ID_1er_Inter', i);
		local Passings = Grid_Param:GetCell('Passings', i);
		local TypeTable = Grid_Param:GetCell('TypeTable', i);
		local DelayDoubleDetect = Grid_Param:GetCellInt('DelayDoubleDetect', i);
		local CountTourActif = Grid_Param:GetCellInt('CountTourActif', i);
		AddTabletagID_Passings(Code,AdresseIP,Port,LoopID,LoopCanal,passage,ID_1er_Inter,Passings,TypeTable,DelayDoubleDetect,CountTourActif);
	end
		Alert("Sauvegarde des lignes ds TabletagID_Passings éffectuer correctement");
end

		-- fonction qui permet de rendre une cellule d'une grid editable
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

		-- boite de dialogue pour la gestions des options et des nb tours et N° de passage	
function OnOpenOptions(evt)
-- Création Dialog 

	dlgOptionTable = wnd.CreateDialog({
		parent = RaceResult.panel,
		icon = "./res/32x32_ffs.png",
		label = 'Gestion des Options Nb Tours et / Passage',
		width = 1050,
		height = 500
	});
	
	dlgOptionTable:LoadTemplateXML({ 
	xml = './device/RaceResult.xml',
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
	cmd = "Select * From tagID_Tour Where Code = '"..RaceResult.code_competition.."' and AdresseIP = '"..ActiveID.."' Order by Code, bibMini";
	RaceResult.dbSki:TableLoad(TabletagID_Tour, cmd)
	
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

	cmd = "Select * From tagID_Passings Where Code = '"..RaceResult.code_competition.."' And AdresseIP = '"..ActiveID.."' Order by Code, LoopID, LoopCanal";
	RaceResult.dbSki:TableLoad(TabletagID_Passings, cmd)
	
	TabletagID_Passings:SetColumn('Code', { label = 'Code-Evt.', width = 9 });
	TabletagID_Passings:SetColumn('AdresseIP', { label = 'AdresseIP.', width = 12 });
	TabletagID_Passings:SetColumn('Port', { label = 'Port.', width = 9 });
	TabletagID_Passings:SetColumn('LoopID', { label = 'LoopID.', width = 6 });
	TabletagID_Passings:SetColumn('LoopCanal', { label = 'LoopCanal.', width = 6 });
	TabletagID_Passings:SetColumn('passage', { label = 'passage.', width = 9 });
	TabletagID_Passings:SetColumn('ID_1er_Inter', { label = 'ID 1er Inter.', width = 9 });
	TabletagID_Passings:SetColumn('Passings', { label = 'Nb Passings.', width = 12 });
	TabletagID_Passings:SetColumn('TypeTable', { label = 'TypeTable.', width = 9 });
	TabletagID_Passings:SetColumn('DelayDoubleDetect', { label = 'Delai Double Detect.', width = 18 });
	TabletagID_Passings:SetColumn('CountTourActif', { label = 'Compteur Tour Pena Actif.', width = 22 });
	TabletagID_Passings:SetColumn('SystemeActif', { label = 'SystemeActif.', width = 22 });
	local grid = dlgOptionTable:GetWindowName('grid_Param');
	grid:Set({
		table_base = TabletagID_Passings,
		columns = 'Code, AdresseIP, Port, LoopID, LoopCanal, ID_1er_Inter, passage, Passings, TypeTable, DelayDoubleDetect, CountTourActif, SystemeActif',
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
	
	-- Gestion des tables Tag ID.....
		--fonction permetant de vider la table tagid finish de l'evenement
function OnDeleteTagIdFinish()
	if RaceResult.panel:MessageBox("Confirmation du supression des Tag_ID déjà détecter? \n\n Seul les TagID détecter par le décodeur ACTIF seront éffacer \n Attention lors de la prochaine detection \n les transpondeurs ne seront plus mis en double detection \n et les dossards deja arrivés passerons dans la colonne ancien dossard", " Supression des Tag_ID déjà détecter", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end

--recherche du nombre de ligne ds la table tag ID et afichage
	cmd = "Select * From tagID_Finish Where Code = "..RaceResult.code_competition.." And AdresseIP = '"..ActiveID.."'";
	TabletagID_Finish = RaceResult.dbSki:GetTable('tagID_Finish');
	RaceResult.dbSki:TableLoad(TabletagID_Finish,cmd);
	local nbTagID_Finish = TabletagID_Finish:GetNbRows();
	Alert("Nb de tagID Déja inscrit dans la table : "..nbTagID_Finish.." de l'Evt N°"..RaceResult.code_competition.." du decodeur:"..ActiveID)

--Vidage de la table
	cmd = "Delete From tagID_Finish Where Code = "..RaceResult.code_competition.." And AdresseIP = '"..ActiveID.."'";
	RaceResult.dbSki:Query(cmd);
	
	Warning("Vidage table tagID_Finish ok...");
--recherche du nombre de ligne ds la table tag ID et afichage pour verication	
	cmd = "Select * From tagID_Finish Where Code = "..RaceResult.code_competition.." And AdresseIP = '"..ActiveID.."'";	
	-- TabletagID_Finish = RaceResult.dbSki:GetTable('tagID_Finish');
	RaceResult.dbSki:TableLoad(TabletagID_Finish,cmd);
	local nbTagID_Finish = TabletagID_Finish:GetNbRows();
	Alert("Nb de tagID restant inscrit dans la table : "..nbTagID_Finish.." de l'Evt N°"..RaceResult.code_competition.." du decodeur:"..ActiveID)

end

		--fonction permetant de vider la table tagid Tour de l'evenement
function OnDeleteTagIdTourPena()
	if RaceResult.panel:MessageBox("Confirmation du supression des Nb de Tours ? \n\n Attention cette Opération effaceras le Nb de tour  \n la Table de données comportants  \n le Nb de tour dé Pénalite éffectuée", " Supression du Nb de tours éffectuer", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end

--recherche du nombre de ligne ds la table tag ID et afichage
	cmd = "Select * From tagID_TourPena Where Code = "..RaceResult.code_competition;
	--TabletagID_TourPena = RaceResult.dbSki:GetTable('tagID_TourPena');
	RaceResult.dbSki:TableLoad(tagID_TourPena,cmd);
	local nbtagID_TourPena = TabletagID_TourPena:GetNbRows();
	-- Alert("nbtagID_TourPena"..nbtagID_TourPena)
	if nbtagID_TourPena ~= 0 then
	Alert("Nb de Tour Déja inscrit dans la table : "..nbtagID_TourPena.." de l'Evt N°"..RaceResult.code_competition)

--Vidage de la table
	cmd = "Delete From tagID_TourPena Where Code = "..RaceResult.code_competition;
	RaceResult.dbSki:Query(cmd);
	
	Warning("Vidage table tagID_TourPena ok...");
	
--recherche du nombre de ligne ds la table tag ID et afichage pour verication	
	cmd = "Select * From tagID_TourPena Where Code = "..RaceResult.code_competition;	
	TabletagID_TourPena = RaceResult.dbSki:GetTable('tagID_TourPena');
	RaceResult.dbSki:TableLoad(TabletagID_TourPena,cmd);
	local nbTagID_Finish = TabletagID_TourPena:GetNbRows();
	Alert("Nb de tagID restant inscrit dans la table : "..nbTagID_Finish.." de l'Evt N°"..RaceResult.code_competition.."")
	else
	Alert("Pas de Dossard inscrit dans la table tagID_TourPena pour l\'évènement N°"..RaceResult.code_competition.."")
	end 
	
end	
	
		-- insertion d'une ligne dans la table TabletagID_Tour
function AddTabletagID_Tour(Code,AdresseIP,bibMini,bibMax,LoopID,LoopCanal,Tour)
			local r = TabletagID_Tour:AddRow();
				TabletagID_Tour:SetCell("Code", r, tonumber(Code));
				TabletagID_Tour:SetCell("AdresseIP", r, AdresseIP);
				TabletagID_Tour:SetCell("bibMini", r, tonumber(bibMini));		
				TabletagID_Tour:SetCell("bibMax", r, tonumber(bibMax));
				TabletagID_Tour:SetCell("LoopID", r, LoopID);
				TabletagID_Tour:SetCell("LoopCanal", r, LoopCanal);
				TabletagID_Tour:SetCell("Tour", r, tonumber(Tour));
				RaceResult.dbSki:TableFlush(TabletagID_Tour, r);
end 

		-- insertion d'une ligne dans la table TabletagID_Passings
function AddTabletagID_Passings(Code,AdresseIP,ActivePort,LoopID,LoopCanal,passage,ID_1er_Inter,Passings,TypeTable,DelayDoubleDetect,CountTourActif);			
				local r = TabletagID_Passings:AddRow();				
				TabletagID_Passings:SetCell("Code", r, tonumber(Code));
				TabletagID_Passings:SetCell("AdresseIP", r, ActiveID);
				TabletagID_Passings:SetCell("Port", r, tonumber(ActivePort));
				TabletagID_Passings:SetCell("LoopID", r, LoopID);
				TabletagID_Passings:SetCell("LoopCanal", r, LoopCanal);
				TabletagID_Passings:SetCell("passage", r, tonumber(passage));
				TabletagID_Passings:SetCell("ID_1er_Inter", r, ID_1er_Inter);
				TabletagID_Passings:SetCell("Passings", r, tonumber(Passings));
				TabletagID_Passings:SetCell("TypeTable", r, TypeTable);
				TabletagID_Passings:SetCell("DelayDoubleDetect", r, DelayDoubleDetect);
				TabletagID_Passings:SetCell("CountTourActif", r, tonumber(CountTourActif));
				RaceResult.dbSki:TableFlush(TabletagID_Passings, r);
end

		-- fonction permettant de remetre à zéro le nb de passing sur l'evenement
function OnClearPassing()
--Alert("ActiveID :"..ActiveID);
	local NbPassing = '';
	if RaceResult.panel:MessageBox("Confirmation du supression des Nb de passings déjà détecter? \n\n Attention cette pération vas remetre le compteur de détection à zéro\n SKIFFS vas aller récuperer toutes les detections du décodeur ", " Remise à zéro du Nb de détection", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	
	SavePassingCurrent(0);
end

-- à finir
function OnRunErased(key, params)
	Alert("Suppression de tous les passages !!!!!! : on doit faire des trucs ...");
	return true;
end

-- fontion permetant d'avoir les info du bibload
function OnBibLoaded(key, params)
	if type(params.table) == 'userdata' then
		Alert(params.table:GetCell("Dossard",0).." "..params.table:GetCell("Nom",0).." "..params.table:GetCell("Prenom",0));
	end
	return true;
end

-- Menu outil
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
	RaceResult.GetStatus = "Ok" ;
	Alert ('Envoi GetStatus'..RaceResult.GetStatus);
	return RaceResult.GetStatus
end

	--renvoi le Nb de passings enregistrer dans le fichier du decodeur
function OnPassings(evt, Get)
	local sockClient = mt_device.obj;
	sockClient:WriteString("PASSINGS");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	Alert("Nb de Passing ds le fichier du decodeur = "..RaceResult.RecordsCount);	
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

	-- Synchronisation du l'heure GPS SETGPSTIME
function OnStartGPS_Time(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("SETGPSTIME");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	Warning('Synchronisation de l\'heure GPS envoyé ...');
end	
	
	-- active la fonction chrono du decodeur a distance
function OnStartOperation(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("STARTOPERATION");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	Warning('Demande d\'Activation des antennes envoyé ...');
end

	-- met le chrono en stanby
function OnStopOperation(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("STOPOPERATION");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	Warning('Demande de désactivation des antennes envoyé ...');
end

	-- Met l'upload en marche
function OnStartUpload(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("STARTUPLOAD");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	Warning('Demande d\'Activation des antennes envoyé ...');
end

	-- arrete l'upload
function OnStopUpload(evt)
	local sockClient = mt_device.obj;
	sockClient:WriteString("STOPUPLOAD");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
	Warning('Demande d\'Activation des antennes envoyé ...');
end

function OnRechargeTagId(evt)
	Alert ('en cours de rédaction utiliser la fonction remise a zero di Nb passing');
end

-- Evénement Timer
	-- timer pour la charge de la baterie 
function OnTimerBatConnect(evt)
	local sockClient = mt_device.obj;
	
	-- Mise en place du WatchDog
	RaceResult.watchDogConnect = timer.Create(RaceResult.panel);
	if RaceResult.watchDogConnect ~= nil then
		RaceResult.watchDogConnect:StartOnce(1000); -- Il faut moins de 1 sec au RaceResult pour répondre 
	end
	RaceResult.panel:Bind(eventType.TIMER, OnWatchDogConnect, RaceResult.watchDogConnect);

	-- Appel Status 
	sockClient:WriteString("GETSTATUS");
	sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
end

	-- reinitialisation du reseau
function OnReOpenSocket(evt)
	parentFrame = app.GetAuiFrame();
	mt_device.obj = socketClient.Open(parentFrame, theParams.hostname, theParams.port);
	parentFrame:Bind(eventType.SOCKET, mt_device.OnSocketClient, mt_device.obj);
	app.GetAuiMessage():AddLine('Socket Client '..theParams.hostname..':'..theParams.port..' Initialisation ...');
end

	-- watchDog qd on perd la cennection pour pouvoir la relancer?
function OnWatchDogConnect(evt)
	-- Aucune réponse du RaceResult ... on n'est pas ou plus connecté
	RaceResult.Connect:SetLabel("Non Connect");
	RaceResult.battery:SetLabel('Bat=---%');
	
	if RaceResult.watchDogConnect ~= nil then
		RaceResult.watchDogConnect:Delete();
		RaceResult.watchDogConnect = nil;
	end
end

-- Action faite au Timer apres le lancement de la connection au decodeur
function OnTimer(evt)
	--Alert("on passe dans le timer");
	--Alert("passingCurrent :"..tostring(RaceResult.passingCurrent).."/ "..tostring(RaceResult.RecordsCount));
	RaceResult.alive = RaceResult.alive + 1;
	--*** a verif***********************************************
	OngetInfo();
	--Alert("passing count = "..tonumber(RaceResult.RecordsCount).."passingCurent = ".. tonumber(RaceResult.passingCurrent));
	
	local sockClient = mt_device.obj;
	-- si le Nb de passing ds skiffs est > au nb de passing du decodeur on envoi juste la commande passings au decodeur pour qu'il nous renvoi le count
	if tonumber(RaceResult.passingCurrent) >= tonumber(RaceResult.RecordsCount) then
		-- Command PASSINGS 
		sockClient:WriteString("PASSINGS");
		sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
		-- Alert("RaceResult.RecordsCount nb de detect lu par race result"..RaceResult.passingCurrent.." >= "..RaceResult.RecordsCount.."le nb de detection ds la ligne chrono");
	else
	-- si le count est > au pasing currant 
		-- Command PASSAGE INDIVIDUEL
		--Alert("RaceResult.RecordsCount :"..RaceResult.RecordsCount);--nb de detection ds la ligne chrono
		--Alert("RaceResult.passingCurrent :"..RaceResult.passingCurrent);--nb de passings dans skiffs
		local NbpassingsDecodeur = tonumber(RaceResult.RecordsCount) - tonumber(RaceResult.passingCurrent);
		--Alert("test NbpassingsDecodeur :"..NbpassingsDecodeur);
		if tonumber(NbpassingsDecodeur) == 1 then
		--Alert("NbpassingsDecodeur :"..NbpassingsDecodeur);
		sockClient:WriteString(tonumber(RaceResult.passingCurrent+1));
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
		if tonumber(RaceResult.passingCurrent) == 0 then 
		sockClient:WriteString(tonumber(RaceResult.passingCurrent+1)..":"..tonumber(NbpassingsDecodeur));
		sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
		else 
		sockClient:WriteString(tonumber(RaceResult.passingCurrent)..":"..tonumber(NbpassingsDecodeur));
		sockClient:WriteByte(asciiCode.CR, asciiCode.LF);
		end 
		end
	end
	
end

-- fonction qui lance la connection au decodeur
function OnStartRaceResult(evt)
	if TypeTable == 'ND' then 
	Warning("Pas de table de corespondance ");
	Warning("Veuillez sélectionner un type de table et uploader une table via un fichier .csv ");
	else
		if RaceResult.ActiveStart == "Non Actif" then
			-- Mise du Protocol ...
			local sockClient = mt_device.obj;
			sockClient:WriteString("SETPROTOCOL;1.8");
			sockClient:WriteByte(asciiCode.CR, asciiCode.LF);

			-- Prise de la table de Correspondance ...
			RaceResult.tagID = TabletagID_Correspondance;
			Success("Correspondance : "..TabletagID_Correspondance:GetNbRows().." ligne ds la table");
			Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
			
			-- Verification que le directory ./device/Race-result existe ... a suprimer??????????????????????
			-- if app.DirExists('./device/Race-result') == false then
				-- app.Mkdir('./device/Race-result'); -- Creation du répertoire
			-- end

			-- Creation du Timer 
			RaceResult.timer = timer.Create(RaceResult.panel);
			if RaceResult.timer ~= nil then
				RaceResult.timer:Start(RaceResult.timerDelay);
			end
			RaceResult.panel:Bind(eventType.TIMER, OnTimer, RaceResult.timer);

			RaceResult.ActiveStart = "Actif"
		else 
			Error("Déja activé !");
		end
	end
end

-- fonction qui permet d'aller ouvrir un fichier txt de sav de decodeur RaceResult ou un fichier telecharger sur le site RR et de le lire 
function OnRechargeFichier()
-- recherche du fichier se sauvegarde RaceResult
	local fileDialog = wnd.CreateFileDialog(RaceResult.panel,
	"Sélection du fichier de sauvegarde RaceResult",
	RaceResult.directory, 
	"",
	"*.txt|*.txt",
	fileDialogStyle.OPEN+fileDialogStyle.FD_FILE_MUST_EXIST
	);
-- si valeur bouton == OK
	if fileDialog:ShowModal() == idButton.OK then
		-- J'ouvre le fichier en mode reaad
		local file = io.open(fileDialog:GetPath(), "r");
			-- je lis ligne par ligne et active la fonction ReadPacket en lui envoyant la valeur de ligne
			if file ~= nil then -- Le Fichier Existe ...
				Alert('Chargement du fichier: '..fileDialog:GetPath());
					for line in file:lines() do
						--Alert('ligne...'..line);
						RaceResult.debugage  = true;
						ReadPacket(line)
					end
			file:close();
			end
		
		fileDialog:Delete();
	else
		Alert('le fichier n\'existe pas...')
		fileDialog:Delete();
		return false;
	end
end

--fonction de read packet
	-- outils
		-- fonction d'enregistrement du nombre de passings lu
function SavePassingCurrent(value)
	-- Prise de la Valeur en Mémoire 
	RaceResult.passingCurrent = value;
	-- Enregistrement en MySQL 
	cmd = 
		"Update tagID_Passings set Passings = "..
		tostring(RaceResult.passingCurrent)..
		" Where Code = "..RaceResult.code_competition..
		" And AdresseIP = '"..ActiveID..
		"'"
		;
	RaceResult.dbSki:Query(cmd);
	cmd = "Select * From tagID_Passings Where Code = "..RaceResult.code_competition.." and AdresseIP = '"..ActiveID.."'";
		TableTagID_Passings = RaceResult.dbSki:GetTable('tagID_Passings');
		RaceResult.dbSki:TableLoad(TableTagID_Passings, cmd);	

	Alert("Nb de detection enregistrée = "..TableTagID_Passings:GetCellInt('Passings', 0))
end

		-- fonction pour donner l'heure de detection au bon format .000
function GethourPassage(RealTime)
	-- Alert("	RealTime :"..RealTime);
	local a = string.find(RealTime, 'T') or 0;
	local b = string.find(RealTime, 'Z') or 0;
	local c = string.find(RealTime, '+') or 0;
	if c ~= 0 then 
	e = c 
	else 
	e = b 
	end
	-- Alert("	Debut trame :"..a.."fin de trame trackbox = "..b.." fin de trame decoder = "..c);
	local hourPassage = string.sub(RealTime, a+1, e-1);
	-- Alert("	hourPassage :"..hourPassage..' hourPassage:len() '..hourPassage:len());
	if hourPassage:len() == 8 then
		hourPassage = hourPassage..'.000'
	elseif hourPassage:len() == 9 then
		hourPassage = hourPassage..'000'
	elseif hourPassage:len() == 10 then
		hourPassage = hourPassage..'00'
	elseif hourPassage:len() == 11 then
		hourPassage = hourPassage..'0'
	end
	return hourPassage;
end

		-- format hh:mm:ss.kkk
function GetChrono(hourPassage)
	local hour = string.sub(hourPassage,1,2);
	local minute = string.sub(hourPassage,4,5);
	local sec = string.sub(hourPassage,7,8);
	local milli = string.sub(hourPassage,10,12);
	return 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
	-- return 3600000*tonumber(hour)+1000*tonumber(RaceResult.DiffGMT)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
end

		-- Fonction pour envoyer ds le chrono et base linfos souhaitées 
function AddTimePassage(chrono, passage, bib, tagID)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'RaceResult: '..ActiveID, tag = tagID }
	);
	
	bib = bib or '';
	tagID = tagID or '';
	passage = passage or '';
	chrono = chrono or '';
	Success('<passage_add tagId='..tagID..' bib='..bib..' passage='..passage..' chrono='..chrono..'>');

end

		-- fonction qui renvoi Le N° de passage du concurents suivant le nb de tour a faire et le nb de tour deja réaliser
function GetPassage(NbToursAFaire,NbTourRealiser); 
	-- suivant le nombre de tour fait par le concurent et le nombre de tour qu'il a a faire j'acremente la variable passage
	-- si le concurent n'a pas fait plus le nombre de tour alors passage seras egal NbTourRealiser
	if NbToursAFaire == 0 then
		passage = TableTagID_Passings:GetCell('passage', 0);
		-- Alert("if tonumber(NbToursAFaire) == 0 : "..passage);
	else
		if NbTourRealiser < NbToursAFaire then 
			return NbTourRealiser + ID_1er_Inter;
			--Alert("if tonumber(NbTourRealiser) < tonumber(NbToursAFaire) : "..passage);
		--si le concurent a fait le nombre de tour alors passage seras egal a passage	
		elseif	NbTourRealiser == NbToursAFaire then 
			return TableTagID_Passings:GetCellInt('passage', 0);
			--Alert("if tonumber(NbTourRealiser) == tonumber(NbToursAFaire) : "..passage);
		--si le concurent a fait plus que le nombre de tour alors passage seras egal a passage 
		elseif NbTourRealiser > tonumber(NbToursAFaire) then
			--Alert("tonumber(NbTourRealiser) > tonumber(NbToursAFaire) : "..passage);
			return TableTagID_Passings:GetCell('passage', 0);
		end
	end
end

		-- fonction qui renvoi le Nb de tour réaliser par le concurent
function GetNbTourRealiser(tagID)
	-- recherche du nombre de tour fait par le coureur ds la Table TableTagID_Finish 
	cmd = "select * from TagID_Finish where Code = "..RaceResult.code_competition..
			" and AdresseIP = '"..ActiveID..
			"' and LoopID = '"..LoopID..
			"' and LoopCanal = '"..LoopCanal..
			"' and TagID = '"..tagID..
			"'"
	return RaceResult.dbSki:TableLoad(TableTagID_Finish, cmd):GetCellInt("Tour", 0);
end 

		-- fonction qui renvoi le Nb de tour à faire par le concurent 
function GetDelayDoubleDetect()		
	-- Chargement de la table TableTagID_Passings pour avoir le DelayDoubleDetect
	cmd = "Select * From tagID_Passings Where Code = "..RaceResult.code_competition..
		  " and AdresseIP = '"..ActiveID..
		  "' and LoopID = '"..LoopID..
		  "' and LoopCanal = '"..LoopCanal..
		  "'"
		  ;
	-- Race_result.dbSki:TableLoad(TableTagID_Passings, cmd);
	if tonumber(RaceResult.dbSki:TableLoad(TableTagID_Passings, cmd):GetNbRows()) == 0 then
		Warning(" Vérifier les numero des Loop et Canal Loop il doive etre: ");
		Alert("Les données du fichier lu sont -> LoopID = "..LoopID.." / Canal = "..LoopCanal.." / SystemeActif = "..SystemeActif )
		Warning(" Apres les avoir Vérifier recharger a nouveau le fichier ou réactiver la lescture du decodeur");
		Alert(" bien remetre le Nb de passing detecter à 0 sinon le fichier ne seras pas lu");
		return false
	end
	
	return TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
end

		-- fonction pour mettre a jour le bandeau de donnée  detection lue / fichier // timer //  baterie
function OngetInfo(detectionlue)
	RaceResult.info:SetLabel("Timer :"..tostring(RaceResult.alive)..
													" Passings : "..tostring(RaceResult.passingCurrent)..
													"/"..tostring(RaceResult.RecordsCount)..
													"-Decodeur.")
												;															
end

		-- fonction de recherche du dos et du nombre de tour du tag-id
function RecherchetourDos(CodeTypeTable,tagID,LoopID,LoopCanal)
-- recherche du dossard par rapport au TagID ds la table tagID_Correspondance tagID_Correspondance
	-- Code = tonumber(CodeTypeTable);
	cmd = "Select * From tagID_Correspondance Where Code = "..CodeTypeTable.." And TagID = '"..tagID.."'"; 
	bib = RaceResult.dbSki:TableLoad(TabletagID_Correspondance, cmd):GetCellInt('Dossard',0);
	-- Alert("bib = "..bib);
	if bib ~= "" then 
		
		-- Alert("RaceResult.code_competition = "..RaceResult.code_competition);
		-- Alert("ActiveID = "..ActiveID);
		-- Alert("LoopID = "..LoopID);
		-- Alert("LoopCanal = "..LoopCanal);
		-- on vas chercher le nombre de tour que le dos doit faire 
		cmd = "Select * From tagID_Tour Where Code = "..RaceResult.code_competition..
													 " And AdresseIP = '"..ActiveID..
													 "' And LoopID = '"..LoopID..
													 "' And LoopCanal = '"..LoopCanal..
													 "'";
		-- Alert("cmd = "..cmd);											 
		TabletagID_Tour = RaceResult.dbSki:GetTable('tagID_Tour');
		RaceResult.dbSki:TableLoad(TabletagID_Tour, cmd);
		Testnbtour = RaceResult.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows();
		-- Alert("Testnbtour = "..Testnbtour);
		for i=0, RaceResult.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows()-1 do 
		bibMini = TabletagID_Tour:GetCellInt('bibMini', i);
		bibMax = TabletagID_Tour:GetCellInt('bibMax', i);
		-- Alert("bib = "..bib);
		--Alert("bibMini = "..bibMini);
		-- Alert("bibMini = "..bibMax);
		-- Alert("i = "..i);
			if bib >= bibMini and bib <= bibMax then
				NbToursAFaire = TabletagID_Tour:GetCellInt('Tour', i);
				-- Alert("je suis dans la bonne ligne"..NbToursAFaire);
			end	
		end
		
		-- Pour éviter d'avoir la variable NbToursAFaire soit nul
		if NbToursAFaire ~= nil then else NbToursAFaire = 0 end
		--Alert("le Dossard :"..bib.."doit faire :"..NbToursAFaire.." aTour")
	else 
	NbToursAFaire = 0;
	end 
end 

		-- fonction qui renvoi si le count tour est actif ou pas 
function RechercheCountTourActif(CodeTypeTable,tagID, LoopID,LoopCanal);
	-- recherche du dossard par rapport au TagID ds la table tagID_Correspondance
	cmd = "Select * From tagID_Passings Where Code = "..RaceResult.code_competition..
												 " And AdresseIP = '"..ActiveID..
												 "' And LoopID = '"..LoopID..
												 "' And LoopCanal = '"..LoopCanal..
												 "'";
	CountTourActif = RaceResult.dbSki:TableLoad(TabletagID_Passings, cmd):GetCell("CountTourActif", 0);
	if CountTourActif == '' then 
		CountTourActif = 0 
	end
	--Alert("CountTourActif = "..CountTourActif);
end

		-- fonction qui permet de mettre a jour lr Nb tour dans la table tagID_finish
function AddNbTours(NbTours, tagID, ActiveID, LoopID, LoopCanal)
	--Alert("AddNbtours LoopID = "..ActiveID);
	local cmd = 
		"Update tagID_Finish SET Tour = "..NbTours..
		" Where Code = "..RaceResult.code_competition..
		" And AdresseIP = '"..ActiveID..
		"' And LoopID = '"..LoopID..
		"' And LoopCanal = '"..LoopCanal..
		"' And TagID = '"..tagID..
		"'"
	RaceResult.dbSki:Query(cmd);
	Success("mise a jour du nb tour au tagID ="..tagID.. " dans la TabletagID_TourPena Donc :"..NbTours);
end

		-- fonction qui insert un tour de pena dans la table tagid pena
function InsertNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait)
	 --Alert("Num_Tir = "..Num_Tir);	
 local r = TabletagID_TourPena:AddRow();				
				TabletagID_TourPena:SetCell("Code", r, tonumber(RaceResult.code_competition));
				TabletagID_TourPena:SetCell("AdresseIP", r, ActiveID);
				TabletagID_TourPena:SetCell("LoopID", r, LoopID);
				TabletagID_TourPena:SetCell("LoopCanal", r, LoopCanal);
				TabletagID_TourPena:SetCell("Dossard", r, bib);
				TabletagID_TourPena:SetCell("Tir1", r, tonumber(NbTour_Fait));	
				TabletagID_TourPena:SetCell("Tir2", r, 0);
				TabletagID_TourPena:SetCell("Tir3", r, 0);
				TabletagID_TourPena:SetCell("Tir4", r, 0);
				TabletagID_TourPena:SetCell("Num_Tir", r, tonumber(Num_Tir));
				RaceResult.dbSki:TableInsert(TabletagID_TourPena, r);
				Success("Ajout dos ="..bib.. " dans la TabletagID_TourPena");	
end

		-- fonction qui ajoute un tour de pena dans la table tagidpena
function AddNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait)
	--Alert("AddNbtours_pena Num_Tir = "..Num_Tir);
	--Alert("AddNbtours LoopID = "..NbTour_Fait);
	
	local cmd = 
		"Update tagID_TourPena SET Tir"..Num_Tir.." = "..NbTour_Fait..
		", Num_Tir = "..Num_Tir..
		" Where Code = "..RaceResult.code_competition..
		" And AdresseIP = '"..ActiveID..
		"' And LoopID = '"..LoopID..
		"' And LoopCanal = '"..LoopCanal..
		"' And Dossard = '"..bib..
		"' "
		;
	RaceResult.dbSki:Query(cmd);
	Success("Ajout d\' 1 tour au dos ="..bib.. " dans la TabletagID_TourPena Donc :"..NbTour_Fait);		
end
	
		-- fonction qui insert un dos dans la table tagIDfinish
function AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib)
	-- ecriture du TagID dans la table tagID_Finish
	local r = TableTagID_Finish:AddRow();				
	TableTagID_Finish:SetCell("Code", r, RaceResult.code_competition);
	TableTagID_Finish:SetCell("AdresseIP", r, ActiveID);
	TableTagID_Finish:SetCell("LoopID", r, LoopID);
	TableTagID_Finish:SetCell("LoopCanal", r, LoopCanal);
	TableTagID_Finish:SetCell("TagID", r, tagID);		
	TableTagID_Finish:SetCell("Passage", r, passage);
	TableTagID_Finish:SetCell("Tour", r, Tour);
	RaceResult.dbSki:TableInsert(TableTagID_Finish, r);
		Success("Ajout dos ="..bib.. " dans la TableTagID_Finish");	

end

		-- fonction qui ajoute un tour de pena dans la table tagidpena
function refreshTagIDFinish(tagID, passage, LoopID, LoopCanal)
	local cmd = 
			"Update tagID_Finish SET Passage = '"..passage..
		" 'Where Code = "..RaceResult.code_competition..
		" And AdresseIP = '"..ActiveID..
		"' And LoopID = '"..LoopID..   
		"' And LoopCanal = '"..LoopCanal.. 
		"' And tagID = '"..tagID..
		"' "
		;
	RaceResult.dbSki:Query(cmd);
	Success("Mise a jour du N° de passage :"..passage.." du TagID ="..tagID.. " dans la TableTagID_Finish");
end

		-- Fonction pour qui renvoi l'heure de passage					
function GetHeurePassage(dossard, passage)
	local cmd =
		" Select * From Resultat_Chrono Where Code_evenement = "..RaceResult.code_competition..
		" And Code_manche = "..RaceResult.code_manche..
		" And Id = "..passage..
		" And Dossard = "..dossard
	;
	tResultatChrono = RaceResult.dbSki:GetTable('Resultat_Chrono');
	RaceResult.dbSki:TableLoad(tResultatChrono, cmd);
	--Alert('RaceResult.code_competition = '..RaceResult.code_competition);
	--Alert('RaceResult.code_manche = '..RaceResult.code_manche);
	--Alert('idPassage = '..passage);
	--Alert('dossard = '..dossard);
	
	if tResultatChrono == nil then return -1 end
	if tResultatChrono:GetNbRows() == 0 then return -1 end
	
	-- Heure de passage existe ...	
	return tResultatChrono:GetCellInt('Heure',0);
end

		-- Fonction qui renvoi un tps net
function GetTempsNet(dossard)
	local heureDep = GetHeurePassage(dossard, 0);
	local heureArr = GetHeurePassage(dossard, -1);
	
	if heureArr > heureDep and heureDep >= 0 then
		return heureArr-heureDep;
	else
		return -1;
	end
end

		-- fonction qui renvoi untps net inter
function GetTempsNetInter(dossard, inter)

	local heureDep = GetHeurePassage(dossard, 0);
	local heureInter = GetHeurePassage(dossard, inter);
	
	if heureInter > heureDep and heureDep >= 0 then
		return heureInter-heureDep;
	else
		return -1;
	end
end

		-- fonction permetant d'aller chercher le nb de pena d'un dossard
function GetPenaBiathlon(dossard, passage)
	local dossard = 1;
	local Num_Tir = 3;
	local Code_coureur = GetCodecoureur(dossard);
	Alert('GetPenaBiathlon Code_coureur = '..Code_coureur);
	local cmd =
		" Select * From Resultat_Manche Where Code_evenement = "..RaceResult.code_competition..
		" And Code_coureur = '"..Code_coureur..
		"'"
	;
	tResultat_Manche = RaceResult.dbSki:GetTable('Resultat_Manche');
	RaceResult.dbSki:TableLoad(tResultat_Manche, cmd);
	--Alert('RaceResult.code_competition = '..RaceResult.code_competition);
	--Alert('RaceResult.code_manche = '..RaceResult.code_manche);
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
		" select * From Resultat Where Code_evenement = "..RaceResult.code_competition..
		" And Dossard = "..dossard
	;
	tResultat = RaceResult.dbSki:GetTable('Resultat');
	RaceResult.dbSki:TableLoad(tResultat, cmd);
	--Alert('RaceResult.code_competition = '..RaceResult.code_competition);
	--Alert('RaceResult.code_manche = '..RaceResult.code_manche);
	--Alert('idPassage = '..passage);
	--Alert('dossard = '..dossard);
	
	if tResultat == nil then return -1 end
	if tResultat:GetNbRows() == 0 then return -1 end
	Alert('GetCodecoureur = '..tResultat:GetCell('Code_coureur',0));
	-- Heure de passage existe ...	
	return tResultat:GetCell('Code_coureur',0);
end

		-- fonction recherche si un tagID existe dans la table TableTagID_Finish et di ID du dernier passage
function RechercheTagId_Rech_Der_Passge_TagID(ActiveID, LoopID, LoopCanal, tagID)
	cmd = "Select * From tagID_Finish Where Code = '"..RaceResult.code_competition..
		  "' And AdresseIP = '"..ActiveID..
		  "' And LoopID = '"..LoopID..
		  "' And LoopCanal = '"..LoopCanal..
		  "' And TagID = '"..tagID..
		  "'"
		  ;
	
	Rech_TagID = RaceResult.dbSki:TableLoad(TableTagID_Finish, cmd):GetCell("TagID", 0);
	Rech_Der_Passge_TagID = RaceResult.dbSki:TableLoad(TableTagID_Finish, cmd):GetCellInt("Passage", 0);

end

		-- recherche si un tagID existe dans la table TagID_TourPena
function rechercheDos_TabletagID_TourPena(ActiveID, LoopID, LoopCanal, bib)
	cmd = "Select * From TagID_TourPena Where Code = '"..RaceResult.code_competition..
		  "' And AdresseIP = '"..ActiveID..
		  "' And LoopID = '"..LoopID..
		  "' And LoopCanal = '"..LoopCanal..
		  "' And Dossard = "..bib							 
		  ;
	return RaceResult.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCell("Dossard", 0);
end

--  lecture des trames
-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	-- Test si le Buffer est vide 
	if cb:GetCount() == 0 then return end

	-- Lecture des Packets 
	while (ReadPacket(cb)) do end
		
end

-- fonction de lecture du packet envoyer du chrono ou du fichier Txt
function ReadPacket(cb)
-- ligne qui permette de lire un fichier RR télécharger
	--******************************************************************** a faire voire a pierre
	if RaceResult.debugage  == true then 
		packetString = cb;
		RaceResult.debugage = false
	else
		local count =  cb:GetCount();
		
		local findEnd = cb:Find(asciiCode.CR, asciiCode.LF);	-- Recherche fin de Trame
		-- Alert('findEnd = '..findEnd..' / count = '..count);
		if findEnd == -1 then return false end  					-- On peut stopper la recherche
		local packet = cb:ReadByte(findEnd+1);
		packetString = adv.PacketString(packet, 1, findEnd);
	end
--********************************************************************	
	local arrayResults = string.Split(packetString,';');
	
	local countResults = #arrayResults;

	if countResults >= 1 then
		local firstResult = arrayResults[1]; 
	-- Alert("firstResult = "..firstResult);
	-- Alert("arrayResults[2] = "..arrayResults[2]);
		if tonumber(firstResult) ~= nil and tonumber(firstResult) > 0 then

			-- Impulsion de Passage
			if #arrayResults >= 4 then   

--**** recherche du dos	
				local tagID = arrayResults[2];  
				tagID = tagID:gsub('\n', '');	-- Suppression du LF éventuel
				tagID = tagID:gsub('\r', '');	-- Suppression du CR éventuel
				
				local NumLoopID = arrayResults[11];
				local NumLoopCanal = arrayResults[10];
				local SystemeActif = arrayResults[9];
				
				if NumLoopID ~= '' then 
					LoopID = 'Loop'..NumLoopID;
					LoopCanal = 'LoopCanal'..NumLoopCanal;
					SystemeActif = arrayResults[9]
				else 
					LoopID = 'Loop0';
					LoopCanal = 'LoopCanal0';
					SystemeActif = 0;
				end 
				-- Alert("LoopID = "..LoopID.." / Canal = "..LoopCanal.." / SystemeActif = "..SystemeActif )

				local hourPassage = arrayResults[4];
				-- Alert("	hourPassage :"..hourPassage.." et tagID = "..tagID);
-- ###### debut coupure pour tranfert //////////// code commun entre RaceResult et RaceresultWebRestApi (entre les deux coupure) suivant si on est en IP ou en webserveur////******
				local chrono = GetChrono(hourPassage);
				-- Alert("	CodeTypeTable :"..CodeTypeTable)
								
				-- on recherche si le CountTourActif est actif pour la Loop
				RechercheCountTourActif(CodeTypeTable,tagID, LoopID, LoopCanal);
				-- Alert("CountTourActif = "..CountTourActif)
				-- si c'est un systeme actif et que le N° de LoopID ou de LoopCanal sont == 0
				-- l'impulse viens du marqquer du decodeur 
				-- if tonumber(SystemeActif) == 0 and LoopID == 'Loop0' and LoopCanal == 'LoopCanal0' then
					-- Alert("L impulse viens du marqueur du décodeur "..ActiveID)
					-- AddTimePassage(chrono, passage, '-'..tagID, "N°marqueur"..tagID);	
				if tonumber(SystemeActif) == 1 and LoopID == 'Loop0' and LoopCanal == 'LoopCanal0' then
					Alert("L impulse viens du marqueur du décodeur "..ActiveID)
					--Alert(chrono..' '..passage..' '..tagID);
					AddTimePassage(chrono, passage, '-'..tagID, tagID);	
				else -- du tonumber(SystemeActif) == 1 ou du tonumber(SystemeActif) == 0
					-- si le CountTourActif == 0 donc non actifje gere normalement la detection comme un heure da passage
					if tonumber(CountTourActif) == 0 then
					-- Alert("je gere la detection normalement comme un chrono")			
						-- on recherche le dos et le nb de tour a faire par le dos 				
						RecherchetourDos(CodeTypeTable,tagID, LoopID, LoopCanal);
						--Alert("bib = "..bib.." / Nb Tours A Faire = "..NbToursAFaire);		
						--si bib est différent de nil ou de '' on gere l'impultion		
						if bib ~= "" then
							-- recherche de l'heure de départ de l'épreuve  evolution a finir
								-- rechercheHeureDepartDos(bib);
							
							-- recherche si un tagID existe dans la table TableTagID_Finish et de Rech_Der_Passge_TagID
							RechercheTagId_Rech_Der_Passge_TagID(ActiveID, LoopID, LoopCanal, tagID)

							--Alert("Rech_Der_Passge_TagID = "..Rech_Der_Passge_TagID)
							-- Alert("Rech_TagID = "..Rech_TagID)
							-- Gestion Impulsions			
								--si Rech_TagID est diff de '' je gere l' impultion
						
							if Rech_TagID ~= '' then
								-- recherche du nombre de tour fait par le coureur ds la Table TableTagID_Finish 
								local NbTourRealiser = GetNbTourRealiser(tagID);
									-- Alert("NbTourRealiser: "..NbTourRealiser);
									
								-- Recherche du delay de double detection
								local DelayDoubleDetect = GetDelayDoubleDetect();
									-- Alert("DelayDoubleDetect: "..DelayDoubleDetect);
									
								-- incrementation de la variable passage suivant le Nb à faire te le Nb de tour réaliser
								local passage = GetPassage(NbToursAFaire,NbTourRealiser); 
									-- Alert("passage = "..passage);
								
								-- rechercher si une heure de passage est deja inscrite dans la table chrono
								local TimePassage = GetHeurePassage(bib, Rech_Der_Passge_TagID);
									--Alert(" chrono = "..chrono.." TimePassage = "..TimePassage);
									
								-- Calcul de l'heure de passage + delay double detection
								local TimePassagePlus = tonumber(TimePassage) + tonumber(DelayDoubleDetect); 
									--Alert(" TimePassagePlus ="..TimePassagePlus)
									-- si le l'heure dedetection 'chrono' est inferieur a tps + DelayDoubleDetect c'est une double détection
									
								if 	tonumber(chrono) <= tonumber(TimePassagePlus)then 
									TimeDelayDoubleDetect = tonumber(DelayDoubleDetect / 1000);
									TimeDelayDoubleDetect = tonumber(TimeDelayDoubleDetect / 60);
									Alert("Attention Double detection delai entre les 2 detections < "..TimeDelayDoubleDetect.."Min");
									--Alert("Nb Tour fait: "..NbTourRealiser.."/ "..NbToursAFaire.." Tours à Faire")
									AddTimePassage(chrono, Rech_Der_Passge_TagID, -6666, tagID.."(d)");
								
								-- Sinon c'est une impultion normal on peu continuer la gestion	
								else -- du tonumber(chrono) <= tonumber(TimePassagePlus)
									-- **** si le delay de double detection est passer je gere l'impultion normalement
									--Alert(" heure de passage > au DelayDoubleDetect on peu gerer l'impultion normalement");		
									-- Si le nb de tour realiser est == au nb de tour a faire je met l' heure ds la table
									if NbTourRealiser < NbToursAFaire then 
										--Alert("LoopID 1 = "..LoopID);
										AddNbTours(NbTourRealiser+1, tagID, ActiveID, LoopID, LoopCanal);
										AddTimePassage(chrono, NbTourRealiser+1, bib, tagID);
										refreshTagIDFinish(tagID, passage, LoopID, LoopCanal);
									elseif	NbTourRealiser == NbToursAFaire then 
										--Alert("LoopID 2 = "..LoopID);
										AddNbTours(NbTourRealiser+1, tagID, ActiveID, LoopID, LoopCanal);
										AddTimePassage(chrono, passage, bib, tagID);
										refreshTagIDFinish(tagID, passage, LoopID, LoopCanal);
									elseif NbTourRealiser > NbToursAFaire then
										--Alert("LoopID 3 = "..LoopID);
										AddNbTours(NbTourRealiser+1, tagID, ActiveID, LoopID, LoopCanal);
										AddTimePassage(chrono, passage, -bib, tagID);
									end
								end 
					
							else	-- if Rech_TagID ~= '' c'est la premiere detection du tagID j'envoi le temps ds la base
								--Alert('premiere detection NbTourRealiser = '..NbTourRealiser..'NbToursAFaire = '..NbToursAFaire)						
								--Alert('passage = '..passage)
								if NbToursAFaire == 0 then
									-- numero de passage a verifier il devrais etre le passage defini
									local Tour = 1;
									--Alert('Le concurent n\'a pas de tour à faire j\'ecrit dans la table TableTagID_Finish')
									AddTimePassage(chrono, passage, bib, tagID);
									AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib)
								else
									if NbTourRealiser < NbToursAFaire then
										-- numero de passage a verifier il devrais etre le passage defini
										local passage = ID_1er_Inter;
										local Tour = 1;
										--Alert('Le concurent n\'a pas fait de Nb tour à faire j\'ecrit dans la table TableTagID_Finish')
										AddTimePassage(chrono, passage, bib, tagID);
										--Alert('je lui met un Tour dans la table TabletagID_Finish')
										AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib)
									elseif NbTourRealiser == NbToursAFaire then
										local Tour = 1;
										--Alert('Le concurent a fait le Bon nombre de Tour')
										AddTimePassage(chrono, passage, bib, tagID);
										AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib);
									elseif NbTourRealiser > NbToursAFaire then
										-- Si le nb de tour realiser est > au nb de tour a faire je met l' heure ds la table et je met -bib dans la table resultat chrono pour indiquer que le bib a deja été détecter
										AddNbTours(NbTourRealiser+1, tagID, ActiveID, LoopID, LoopCanal);
										AddTimePassage(chrono, passage, -bib, tagID);
									end
								end
							end
			
						-- si bib = '' le tagID est inconnu ds la table de corespondance je met un dos -9999 pour le signaler au chrono et ne pas perdre l'impulse
						else	-- de if bib ~= ""			
							Alert("Tag ID inconnu dans la TableCorrespondance:  ")
							bib = -9999;
							AddTimePassage(chrono, passage, bib, tagID);
						end		
						
					else -- de if tonumber(CountTourActif) == 0
					-- la Loop sert a compter le Nb tour de Pena..... 
					-- a voir pour passer au Num tir superieur
						Alert("La détection viens de la Loop de comptage de tour de péna");
						RecherchetourDos(CodeTypeTable,tagID, LoopID, LoopCanal);
						--Alert("bib = "..bib)
	-- à verifier avec pierre si le bib ~= nil fonctionne bien ou si il faut mettre bib ~= ""car ds RecherchetourDos ~= nil ne fonctionne pas ????????????	
						if bib ~= nil then
							cmd = "Select * From tagID_Passings Where Code = "..RaceResult.code_competition..
								  " and AdresseIP = '"..ActiveID..
								  "' and LoopID = '"..LoopID..
								  "' and LoopCanal = '"..LoopCanal..
								  "'"
								  ;
							RaceResult.dbSki:TableLoad(TableTagID_Passings, cmd);
								-- Recherche du delay de double detection
							local DelayDoubleDetect = TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
							local passage = TableTagID_Passings:GetCell('passage', 0);
								--Alert("DelayDoubleDetect = "..tonumber(DelayDoubleDetect/10000)..'sec.'); 
								--Alert("passage = "..passage);
								
							-- recherche si un tagID existe dans la table TagID_TourPena
							local Rech_Dossard = rechercheDos_TabletagID_TourPena(ActiveID, LoopID, LoopCanal, bib)
							--Alert("Rech_Dossard = "..Rech_Dossard);
							
								if Rech_Dossard == '' then
									--Alert("Rech_Dossard test2 = "..Rech_Dossard)
									-- Je creer un ligne pour le comptage de tour de pena ds la table tagID_TourPena
									local Num_Tir = 1;
									local NbTour_Fait = 1;
									InsertNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait);
								else
									--Alert("bib = "..bib)
									--Alert("passage: "..passage);
									--Alert("DelayDoubleDetect: "..DelayDoubleDetect);
									local TimePassage = GetHeurePassage(Rech_Dossard, passage);
									--Alert("TimePassage: "..TimePassage);
									local Num_Tir = 1;
									local TimePassagePlus = tonumber(TimePassage)+tonumber(DelayDoubleDetect);
									--Alert("chrono = "..chrono)
									--Alert("TimePassage = "..TimePassage.." TimePassagePlus ="..TimePassagePlus)
										if 	tonumber(chrono) <= tonumber(TimePassagePlus)then
										-- si le l'heure dedetection 'chrono' est inferieur a tps + DelayDoubleDetect c'est une boucle de pena du tir actif
											local Num_Tir = RaceResult.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Num_Tir", 0);
											--Alert("Num_Tir1 = "..Num_Tir);
											local NbTour_Fait = RaceResult.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Tir"..Num_Tir, 0)+1;
											--Alert("NbTour_Fait = "..NbTour_Fait);
											AddNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait);
										else
										-- si le l'heure dedetection 'chrono' est superieur a tps + DelayDoubleDetect c'est une boucle de pena du tir superieur
											local Num_Tir = RaceResult.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Num_Tir", 0)+1;
											--Alert("Num_Tir + 1 = "..Num_Tir);
											local NbTour_Fait = RaceResult.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Tir"..Num_Tir, 0)+1;
											--Alert("NbTour_Fait = "..NbTour_Fait);
											-- j' ajoute 1 tour ds la table tagID_TourPena
											AddNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait);
										end
								end
								AddTimePassage(chrono, passage, bib, tagID);
						else
						-- si le dossrd est inconnu je met -7777 en bib
						AddTimePassage(chrono, passage, -7777, tagID);
						end
					end -- de if tonumber(CountTourActif) == 0
				end -- de if tonumber(SystemeActif)
				-- on sauvegarde le Nb de detection lu
				SavePassingCurrent(tonumber(firstResult));
-- ###### fin coupure pour tranfert //////////// code commun entre RaceResult et RaceresultWebRestApi (entre les deux coupure) suivant si on est en IP ou en webserveur////******						
			end

		-- PASSINGS
		elseif firstResult == 'PASSINGS' then
			if #arrayResults >= 2 then
				RaceResult.RecordsCount = tonumber(arrayResults[2]);
			end
			
		-- GETSTATUS
		elseif firstResult == 'GETSTATUS' then
			-- Suppression du WatchDog
			if RaceResult.watchDogConnect ~= nil then
				RaceResult.watchDogConnect:Delete();
				RaceResult.watchDogConnect = nil;
			end
		
		RaceResult.Connect:SetLabel("Connect");
			
			if RaceResult.GetStatus == 'Ok'then
				Success(packetString);
				RaceResult.GetStatus = 'Ko'
				return RaceResult.GetStatus
			else 
			--Alert ('envoiGetStatus KO')
			end	 
			
			local batteryCharge = tonumber(arrayResults[11]);
			RaceResult.battery:SetLabel("Charge Bat ="..batteryCharge..'%');
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
				
		elseif firstResult == 'STARTOPERATION' and #arrayResults >= 2 and arrayResults[2] == 'OK' then
			Success('Ligne Active');	
		elseif firstResult == 'STARTOPERATION' and #arrayResults >= 2 and arrayResults[2] == 'OPERATIONMODE' then
			Alert("Chrono déjà actif");
		elseif firstResult == 'STOPOPERATION' and #arrayResults >= 2 and arrayResults[2] == 'OK' then
			Warning('Ligne Désactivée plus de détection de Transpondeur decodeur en mode Chrono: Test');
		elseif firstResult == 'STARTUPLOAD' and #arrayResults >= 2 and arrayResults[2] == 'OK' then
			Alert('Activation de l\'Upload');
		elseif firstResult == 'STOPUPLOAD' and #arrayResults >= 2 and arrayResults[2] == 'OK' then
			Alert('Arret de l\'Upload');
		elseif firstResult == 'SETGPSTIME' and #arrayResults >= 2 and arrayResults[2] == 'NOSATELITES' then	
			Alert("Pas de satelite pour la synchronisation");
		elseif firstResult == 'SETGPSTIME' and #arrayResults >= 2 and arrayResults[2] == 'ERROR' then	
			Warning("Erreur  d'envoi");
		elseif firstResult == 'SETGPSTIME' and #arrayResults >= 2 and arrayResults[2] == 'OPERATIONMODE' then	
			Alert("Synchronisation en court");
		elseif firstResult == 'SETGPSTIME' and #arrayResults >= 2 and arrayResults[2] == 'OPERATIONMODE' then	
			Alert("Synchronisation en court");
		elseif firstResult == 'SETGPSTIME' and #arrayResults >= 2 and string.sub(arrayResults[2], 1, 2) == '20' then	
			Alert("Synchro GPS OK..."..arrayResults[2]);
		--elseif firstResult == 'ONLY '..tostring(RaceResult.RecordsCount) then
			--NumPassings = arrayResults[2];
			--Alert('Commande ONLY envoie du passing :'..NumPassings);
		
		elseif firstResult ~= '' then
			-- Réponse autre commandes alert lors de la detection des puces... Only11
			Alert('Commande '..firstResult..' non prise en compte :'..packetString);
		end
	end

	return true;	-- il faut poursuivre la recherche	
end


-- FONCTION A FINIR *********************************************************************************************************
function rechercheHeureDepartDos(Dossard)
	-- recherche et création de variable des heure de départ des épreuve
	cmd = "Select * From Resultat Where Code = "..RaceResult.code_competition.." And Dossard = '"..Dossard.."'";
			
		-- test = RaceResult.dbSki:TableLoad(Resultat, cmd):GetCell('Code_epreuve', 0);
		--RaceResult.dbSki:GetTable('Ranking'):GetCell('Code_epreuve', 1);
		-- for m=1,tonumber(NbEpreuve) do
			-- local steph = 'HeureDepartEpreuve'..m
		 --steph = RaceResult.dbSki:GetTable('Epreuve'):GetCell('Heure_depart', m);
		 --"HeureDepartEpreuve"..m = RaceResult.dbSki:GetTable('Epreuve'):GetCell('Heure_depart', m);
		-- Alert("NbEpreuve : "..HeureDepartEpreuve1);
		-- end
		--Alert("NbEpreuve : "..test);
		return 0 --RaceResult.dbSki:GetTable('Ranking'):GetCellInt('Code_epreuve', 0);
end

