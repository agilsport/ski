-- RaceResult_WebRestApi gere systeme Actif et Passif 
-- connection internet obligatoire pour se connecter au serveur race result
-- systeme Actif gestion de 8 N° de Loop  et 8 N° de canal sur un memes decodeur 
-- Gestion du comptage de nombre de tour de pena si on active le couttourpena sur une boucle
-- aller dans gestion des options
-- Gestion de table de corespondance Généric a tt les évènements ou gestion de table propre à l'évènement traiter
-- dans les deux cas la mm table sert a plusieurs décodeur sur le memes EVT
-- version asychrone ******************* pas de blocage de skiffs si mauvaise connection
-- a partir de la version 1.0 du RaceResult_WebRestApi
	-- Prise en charge de la nouvelle interface Race-result avec bearer
	-- gestion des entier avec la version du lua 5.4  
	-- demande de renseigner les identifiants password et N° de fichier pour se cennecter au serveur raceresult
-- 18/06/2021  Version   1.0 
	-- Evolution vers la nouvelle norme Raceresult ( REST API ) pour récuprer les données sur le serveur race result
-- 22/06/2021  Version   2.1 
	-- gestion des decoder et trackbox.
	-- lecture des detection à distance par le websockets au fur et a mesure des detections
	-- lecture d'un fichier en off line.
	-- passingCurrent ok
	-- mise a jour des infos barre outil ok
	-- mise au bon format des heures de detections des trackbox
-- 22/06/2021  Version   3.0
	-- automatisation heure UTC
	-- mise en place de l'url pour lire le Nb de detections dans un fichiers qui est mis a jour automatic sur le serveur de Race-result
	-- sav des modif table corespondance
	-- mise en fonction des options (corection d'un bug
	-- refonte du ReadJsonRes qui gere les Nb de tour et autres 
-- 31/07/2021 Version   3.1
	-- Amelioration de la table corespondance avec insert et delate ligne
	-- enregistrement des données si modifications manuelle
-- 31/07/2021 Version   3.2
	-- nettoyage du fichier
-- 07/08/2021 Version   3.3
	-- activation du mode chrono...
	-- mise en fonction du bouton recher du mode chrono
	-- mise en fonction du bouton verif de la connection du decodeur au serveur Race-result
-- 09/08/2021 Version   3.4
	-- Realisation des requettes en post avec le bearer
	-- activation du chrono ou mise en stanby pour les decodeurs
-- 09/08/2021 Version   3.5
	-- Activation GPS a distance
-- 09/08/2021 Version   3.6
	-- Verif des dofile('./interface/interface.lua');
-- 12/09/2021 Version   3.7
	-- factorisation RechercheTagId_Rech_Der_Passge_TagID
	-- bug marqueur
-- 21/09/2021 Version   3.8
	-- mise de la valeur passage par rapport a la valeur ds le skiffs.xml
	-- bug diff GMT => UTC
-- 21/09/2021 Version   3.8
	-- mise en place d'un if recordcount ~= nil else return false (Ligne 1130) pour eviter si si records count == le restapi se blocque
dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 4.0,
			 code = 'RaceResult_WebRestApi', 
			 name = 'RaceResult Web RestApi', 
			class = 'chrono'
			--interface = { { type='tcp', hostname = 'D-5314', port = 3601 } } 
			};
end	

--Creation de la table RaceResult_WebRestApi
RaceResult_WebRestApi = {};

-- Création des fonction pour envoi des messages
function Alert(txt)
	RaceResult_WebRestApi.gridMessage:AddLine(txt);
end

function Success(txt)
	RaceResult_WebRestApi.gridMessage:AddLineSuccess(txt);
end

function Warning(txt)
	RaceResult_WebRestApi.gridMessage:AddLineWarning(txt);
end

function Error(txt)
	RaceResult_WebRestApi.gridMessage:AddLineError(txt);
end

-- Configuration du Device
function device.OnConfiguration(node)
	config = {};
	-- width = longueur; height = largeur;
	local dlg_ConfigRaceResult_WebRestApi = wnd.CreateDialog(
		{
			parent = RaceResult_WebRestApi.panel,
			icon = "./res/32x32_ffs.png",
			label = "Configuration du raceresult WebServeur",
			width = 900,
			height = 950
		})
		dlg_ConfigRaceResult_WebRestApi:LoadTemplateXML({ 
		xml = './device/raceresult.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'config_RaceResult_WebServeur'
	});

	dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_AdrServeurRaceResult'):SetValue(node:GetAttribute('config_AdrServeurRaceResult', 'https://rest.devices.raceresult.com/token'));
	dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_IdDecodeur'):SetValue(node:GetAttribute('config_IdDecodeur', ''));
	dlg_ConfigRaceResult_WebRestApi:GetWindowName('RaceResultTypeBox'):SetValue(node:GetAttribute('RaceResultTypeBox', ''));
	dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_PortDecodeur'):SetValue(node:GetAttribute('config_PortDecodeur', '3601'));
	dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_User'):SetValue(node:GetAttribute('config_User', ''));
	dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_PWD'):SetValue(node:GetAttribute('config_PWD', ''));
	dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_ApiKey'):SetValue(node:GetAttribute('config_ApiKey', ''));
	dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_NumFichier'):SetValue(node:GetAttribute('config_NumFichier', ''));	
	dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_Passage'):SetValue(node:GetAttribute('config_Passage', '-1'));
	if node:GetAttribute('SystemeActif') == "1" then
		dlg_ConfigRaceResult_WebRestApi:GetWindowName('checkbox_config_Systeme'):SetValue(true);
	else
		dlg_ConfigRaceResult_WebRestApi:GetWindowName('checkbox_config_Systeme'):SetValue(false);
	end
	
	if node:GetAttribute('bib') == "1" then
		dlg_ConfigRaceResult_WebRestApi:GetWindowName('checkbox_config_Lect_Dos'):SetValue(true);
	else
		dlg_ConfigRaceResult_WebRestApi:GetWindowName('checkbox_config_Lect_Dos'):SetValue(false);
	end

-- combo RaceResultTypeBox
		dlg_ConfigRaceResult_WebRestApi:GetWindowName('RaceResultTypeBox'):Clear();
		dlg_ConfigRaceResult_WebRestApi:GetWindowName('RaceResultTypeBox'):Append('Decoder');
		dlg_ConfigRaceResult_WebRestApi:GetWindowName('RaceResultTypeBox'):Append('Trackbox');
		dlg_ConfigRaceResult_WebRestApi:GetWindowName('RaceResultTypeBox'):SetValue(node:GetAttribute('RaceResultTypeBox', ''));


-- Toolbar Principale ...
	config.tb = dlg_ConfigRaceResult_WebRestApi:GetWindowName('tb');
	btnSave = config.tb:AddTool("Valider", "./res/32x32_save.png");
	config.tb:AddStretchableSpace();
	btnClose = config.tb:AddTool("Fermer", "./res/32x32_close.png");
	config.tb:Realize();

function OnSaveConfig(evt)
		node:ChangeAttribute('config_AdrServeurRaceResult', dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_AdrServeurRaceResult'):GetValue());
		node:ChangeAttribute('config_ApiKey', dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_ApiKey'):GetValue());
		node:ChangeAttribute('config_IdDecodeur', dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_IdDecodeur'):GetValue());
		node:ChangeAttribute('RaceResultTypeBox', dlg_ConfigRaceResult_WebRestApi:GetWindowName('RaceResultTypeBox'):GetValue());
		node:ChangeAttribute('config_PortDecodeur', dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_PortDecodeur'):GetValue());
		node:ChangeAttribute('config_User', dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_User'):GetValue());
		node:ChangeAttribute('config_PWD', dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_PWD'):GetValue());
		node:ChangeAttribute('config_NumFichier',  dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_NumFichier'):GetValue());
		node:ChangeAttribute('config_Passage', dlg_ConfigRaceResult_WebRestApi:GetWindowName('config_Passage'):GetValue());
		if dlg_ConfigRaceResult_WebRestApi:GetWindowName('checkbox_config_Systeme'):GetValue() == true then
			node:ChangeAttribute('SystemeActif',  "1");
		else
			node:ChangeAttribute('SystemeActif',  "0");
		end
		if dlg_ConfigRaceResult_WebRestApi:GetWindowName('checkbox_config_Lect_Dos'):GetValue() == true then
			node:ChangeAttribute('bib',  "1");
		else
			node:ChangeAttribute('bib',  "0");
		end


		local doc = app.GetXML();
		doc:SaveFile();
		dlg_ConfigRaceResult_WebRestApi:EndModal(idButton.OK);
	end

		dlg_ConfigRaceResult_WebRestApi:Bind(eventType.MENU, OnSaveConfig, btnSave); 
		dlg_ConfigRaceResult_WebRestApi:Bind(eventType.MENU, function(evt) dlg_ConfigRaceResult_WebRestApi:EndModal(idButton.CANCEL) end, btnClose);

	-- Lancement de la dialog
	dlg_ConfigRaceResult_WebRestApi:Fit();
	dlg_ConfigRaceResult_WebRestApi:ShowModal();

	-- Liberation Memoire
	dlg_ConfigRaceResult_WebRestApi:Delete();
	
	function OnExit(evt)
	dlg_ConfigRaceResult_WebRestApi:EndModal();
	end
	
end

-- delay Timer connect
RaceResult_WebRestApi.timerDelayConnect = 20000;

-- delay timer apres start ou stop opération
RaceResult_WebRestApi.timerDelayCmd = 10000;


-- delay timer lecture
RaceResult_WebRestApi.timerDelay = 2000;

-- delay timer Jeton
RaceResult_WebRestApi.JetonDelay = 7199000; --1h59'59'

-- variable pour le count du timer
RaceResult_WebRestApi.alive = 0;

-- Actif ou pas
RaceResult_WebRestApi.ActiveStart = "Non Actif";

-- création du jeton
RaceResult_WebRestApi.access_token = false;

--
RaceResult_WebRestApi.ModeChrono = false;

-- nb de lignes 
nbLignes = 0;

-- Nb de tour
NbTourRealiser = 0;

--delai double detection
DelayDoubleDetect = 1000;


-- Fonction de démarrage du device et création de la boite de gestion du raceresult
function device.OnInit(params, node)
--	adv.Alert("On OnInit..");

	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	theParams = params;
	node = node;
	
	-- Création des variables pour la gestion en récupérant les valeurs dans config
	device.url = node:GetAttribute('config_AdrServeurRaceResult');
	device.url_rest = 'https://rest.devices.raceresult.com/';
	RaceResult_ApiKey = node:GetAttribute('config_ApiKey');
	RaceResultTypeBox = node:GetAttribute('RaceResultTypeBox');
	RaceResultdevice = node:GetAttribute('config_IdDecodeur');
	RaceResultuser = node:GetAttribute('config_User');
	RaceResultpw = node:GetAttribute('config_PWD');
	RaceResultPort = node:GetAttribute('config_PortDecodeur');
	RaceResultfile = node:GetAttribute('config_NumFichier');
	passage = node:GetAttribute('config_Passage');  -- N° de passage 0 depart, -1 arrivée, 1..2..3 N° inter
	
	-- variables permettant de créer les URL suivant si on appel un fichier de decodeur ou de trackbox
	if RaceResultTypeBox == 'Decoder' then
	RaceResultTypedetect = 'passings';
	RaceResulFromFiles = 'Passings';
	RaceResulFirstDetect = 'Passing';
	RaceResulStatus = "DecoderStatus";
	elseif RaceResultTypeBox == 'Trackbox' then
	RaceResultTypedetect = 'trackpings';
	RaceResulFromFiles = 'Trackpings';
	RaceResulFirstDetect = 'Trackping';
	RaceResulStatus = "TrackboxStatus";
	end
	
-- variable peu etre a suprimer
	--RaceResultservertime=[servertime]  falcultatif
	RaceResulttype = 'rrfile';--rrfile ou rronline il n'y a pas l'ID du decodeur
	-- declaration de variable complementaire pour la creation de l'URL getSystemStatus
	RaceResultformat = 'text';
	RaceResultshowlaststatus = 'false';
	-- variable variable permetant la reutilisation des requette du raceresult TCP
	ActiveID = RaceResultdevice;
	ActivePort = tonumber(RaceResultPort);
	
-- Creation Panel
	panel = wnd.CreatePanel({ parent = app.GetAuiFrame() });
	panel:LoadTemplateXML({ 
		xml = './device/raceresult.xml',
		node_name = 'root/panel',
		node_attr = 'name',
		node_value = 'Race_Result_WebServeur'
	});
		
-- initialisation de la table raceresult
		RaceResult_WebRestApi.dbSki = sqlBase.Clone();
		TabletagID_Passings = RaceResult_WebRestApi.dbSki:GetTable('tagID_Passings');
		TabletagID_Correspondance = RaceResult_WebRestApi.dbSki:GetTable('tagID_Correspondance');
		TableTagID_Finish = RaceResult_WebRestApi.dbSki:GetTable('tagID_Finish');
		TabletagID_Tour = RaceResult_WebRestApi.dbSki:GetTable('tagID_Tour');
		TabletagID_TourPena = RaceResult_WebRestApi.dbSki:GetTable('tagID_TourPena');
		
		RaceResult_WebRestApi.panel = panel; 
			
-- Initialisation des Controles 
	RaceResult_WebRestApi.gridMessage = panel:GetWindowName('message');
		
	if ActiveID == '' or RaceResultuser == '' or RaceResult_ApiKey == '' or RaceResultfile == '' then
		-- ouverture de la boite de dialogue pour confirmation ouverture de on configuration
		if RaceResult_WebRestApi.panel:MessageBox("Confirmation de la prise des parametres du serveur ?\n\nVoulez vous remplir les parametres de connection au serveur Raceresult", "Confirmation de prise en charge des parametres de connection au serveur", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
			adv.Warning("Parametres User My.raceresult.com non correct");
			adv.Alert("Aller dans la configuration du device pour enregistrer les parametres User My.raceresult.com");
			return;
		end		
		device.OnConfiguration(node);
		device.OnInit(params, node);
		-- Alert("ActiveID ou N° decodeur:"..ActiveID);
		adv.Alert(" la configuration des parametres User My.raceresult.com est ok");
	else
		
		
	-- ToolBar
		RaceResult_WebRestApi.tb = panel:GetWindowName('tb');
		RaceResult_WebRestApi.tb_start = RaceResult_WebRestApi.tb:AddTool("Start", "./res/32x32_chrono_v3.png");
		RaceResult_WebRestApi.tb:AddSeparator();
		RaceResult_WebRestApi.tb_OnChargeTableCorres = RaceResult_WebRestApi.tb:AddTool("Import table corespondance", "./res/32x32_divide_column.png");
		RaceResult_WebRestApi.tb:AddSeparator();
		RaceResult_WebRestApi.tb_Param = RaceResult_WebRestApi.tb:AddTool("Paramétrage", "./res/32x32_config.png", "Paramétrage plage dossards relais",  itemKind.DROPDOWN);
		RaceResult_WebRestApi.tb:AddSeparator();
		
	-- Sous menu parametre	
		local menuSend =  menu.Create();
		menuSend:AppendSeparator();	
		RaceResult_WebRestApi.tb_Param_Options = menuSend:Append({label="Configuration des options (Nb Tour / Passage) ", image ="./res/32x32_options.png"});
		menuSend:AppendSeparator();	
		RaceResult_WebRestApi.tb_Param_TagIdFinish = menuSend:Append({label="Vider la Table tagID_Finish ", image ="./res/32x32_background.png"});
		menuSend:AppendSeparator();
		RaceResult_WebRestApi.tb_Param_Passing = menuSend:Append({label="Mise a zéro du compteur passing", image ="./res/32x32_update.png"});
		menuSend:AppendSeparator();
		RaceResult_WebRestApi.tb_Chargement_Passing = menuSend:Append({label="Chargement d'un fichier Décodeur OFFLINE", image ="./res/32x32_update.png"});
		menuSend:AppendSeparator();
		RaceResult_WebRestApi.tb_Connect = menuSend:Append({label="Verifier la connection "..RaceResultTypeBox, image ="./res/32x32_antenna.png"});
		menuSend:AppendSeparator();
		RaceResult_WebRestApi.tb_Param_Mode = menuSend:Append({label="Recherche du mode Mode Chrono du décodeur", image ="./res/32x32_postition_horizontal.png"});
		if RaceResultTypeBox == 'Decoder' then
		menuSend:AppendSeparator();
		RaceResult_WebRestApi.tb_Param_StartAnt = menuSend:Append({label="Activé les antennes de détection", image ="./res/32x32_antenna.png"});
		menuSend:AppendSeparator();
		RaceResult_WebRestApi.tb_Param_stopAnt = menuSend:Append({label="désactiver les antennes de détection", image ="./res/32x32_stop.png"});
		menuSend:AppendSeparator();
		RaceResult_WebRestApi.tb_Param_StartGPS = menuSend:Append({label="Activé le GPS Time", image ="./res/32x32_antenna.png"});
		end
		menuSend:AppendSeparator();
		RaceResult_WebRestApi.tb_Param_Web = menuSend:Append({label="Modification du numero de fichier", image ="./res/32x32_configure.png"});
		menuSend:AppendSeparator();
		RaceResult_WebRestApi.nb_Detect = menuSend:Append({label="Nombre de détection en mémoire dans le fichier", image ="./res/32x32_configure.png"});
		RaceResult_WebRestApi.tb:SetDropdownMenu(RaceResult_WebRestApi.tb_Param:GetId(), menuSend);
			
	-- Static Connect
		RaceResult_WebRestApi.Connect = wnd.CreateStaticText({parent = RaceResult_WebRestApi.tb, label = "Test Connect", style = wndStyle.ALIGN_LEFT});
		RaceResult_WebRestApi.Connect:SetLabel("Non Connect");
		RaceResult_WebRestApi.tb:AddControl(RaceResult_WebRestApi.Connect);
		RaceResult_WebRestApi.tb:AddSeparator();	
		
	-- Static Info
		RaceResult_WebRestApi.info = wnd.CreateStaticText({parent = RaceResult_WebRestApi.tb, label = "Timer : ------  Passings : ----F/----D", style = wndStyle.ALIGN_LEFT});
		RaceResult_WebRestApi.tb:AddControl(RaceResult_WebRestApi.info);
		RaceResult_WebRestApi.tb:AddSeparator();	

	-- Niveau de Batterie
		RaceResult_WebRestApi.battery = wnd.CreateStaticText({parent = RaceResult_WebRestApi.tb, label = "Charge Bat =---%", style = wndStyle.ALIGN_LEFT});
		RaceResult_WebRestApi.tb:AddControl(RaceResult_WebRestApi.battery);
		RaceResult_WebRestApi.tb:Realize();

	-- Prise des Evenements (Bind)onglet principal
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnStartRaceresultWebServeur, RaceResult_WebRestApi.tb_start);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnOpenTableCorespondance, RaceResult_WebRestApi.tb_OnChargeTableCorres);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnParamko, RaceResult_WebRestApi.tb_Param);

	-- onglet du sous menu outil 
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnOpenOptions, RaceResult_WebRestApi.tb_Param_Options);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnDeleteTagIdFinish, RaceResult_WebRestApi.tb_Param_TagIdFinish);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnClearPassing, RaceResult_WebRestApi.tb_Param_Passing);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnRechargeFichierOffLine, RaceResult_WebRestApi.tb_Chargement_Passing);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnReadConnection, RaceResult_WebRestApi.tb_Connect);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnReadModeChrono, RaceResult_WebRestApi.tb_Param_Mode);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnStartOperation, RaceResult_WebRestApi.tb_Param_StartAnt);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnStopOperation, RaceResult_WebRestApi.tb_Param_stopAnt);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnStartGPS, RaceResult_WebRestApi.tb_Param_StartGPS);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnModifNumFile, RaceResult_WebRestApi.tb_Param_Web);
		RaceResult_WebRestApi.panel:Bind(eventType.MENU, OnGetNbDetections, RaceResult_WebRestApi.nb_Detect);
			
	-- Chargement des Informations de la Course ...
		RaceResult_WebRestApi.code_competition = -1;
		local rc, raceInfo = app.SendNotify('<race_load>');
		if rc == true then
			local tEvenement = raceInfo.tables.Evenement;
			RaceResult_WebRestApi.code_competition = tEvenement:GetCellInt('Code', 0);
			RaceResult_WebRestApi.code_manche = raceInfo.Code_manche or 1 ;
			Success("Compétition "..tostring(RaceResult_WebRestApi.code_competition)..' ok ..');
		end
	
	-- recherche du décalage horaire local par rapport à l'heure UTC
		if RaceResultTypeBox == 'Trackbox' then
		DiffGMT = app.GetTimeZone()
		RaceResult_WebRestApi.DiffGMT = tonumber(string.sub(DiffGMT, 2, 5));
		else
		RaceResult_WebRestApi.DiffGMT = 0;
		end
		-- RaceResult_WebRestApi.DiffGMT = 0
		Alert("DiffGMT = "..RaceResult_WebRestApi.DiffGMT);
	
	-- Recherche si un evenement existe dans la table tagID_Passings OK
		cmd = "Select * From tagID_Passings Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'";
		TableTagID_Passings = RaceResult_WebRestApi.dbSki:GetTable('tagID_Passings');
		RaceResult_WebRestApi.dbSki:TableLoad(TableTagID_Passings, cmd);	
		

		if TableTagID_Passings:GetNbRows() == 0 then
			-- Alert("pas d'évènement Dans la table tagID_Passings on la créer");
		-- creation de la variable Passing Current (nb de transpondeur detecter dans la ligne chrono)		
			RaceResult_WebRestApi.passingCurrent = 0;
			
		-- creation de variables TypeTable et CodeTypeTable(permetant de travailler une table générique a tt les evt ou une table spécifique à l'EVT)
			-- if passage == '' then passage = -1	end
			-- Alert("RaceResultdevice : "..RaceResultdevice);
			passage = node:GetAttribute('config_Passage') or -1;
			LoopID = 'Loop0';
			LoopCanal = 'LoopCanal0';	
			ID_1er_Inter = 1;
			SystemeActif = node:GetAttribute('checkbox_config_Systeme');
			CountTourActif = 0;
			CodeTypeTable = RaceResult_WebRestApi.code_competition;
			TypeTable = "ND";
		--delai double detection
			DelayDoubleDetect = 600000;  -- = à 10 minutes   ///  60000 = à 1 min
			
		-- ecriture des parametres dans la tagID_Passings et du type table
			AddTabletagID_Passings(RaceResult_WebRestApi.code_competition,ActiveID,ActivePort,LoopID,LoopCanal,passage,ID_1er_Inter,RaceResult_WebRestApi.passingCurrent,TypeTable,DelayDoubleDetect,CountTourActif,SystemeActif);		
				Warning("pas de table de corespondace pour cet évènement ...");
				Warning("Penser à aller dans l'onglet gestion pour importer une table avant de chronometrer...");
		else
	-- si il y a une ligne dans tagID_Passings On prend les valeurs de la table pour renseigner les variables 
			RaceResult_WebRestApi.passingCurrent = TableTagID_Passings:GetCellInt('Passings', 0);
			--Alert("RaceResult_WebRestApi.passingCurrent ="..RaceResult_WebRestApi.passingCurrent);
			TypeTable = TableTagID_Passings:GetCell('TypeTable', 0);
			passage = TableTagID_Passings:GetCell('passage', 0);
			SystemeActif = TableTagID_Passings:GetCell('SystemeActif', 0);
			ID_1er_Inter = TableTagID_Passings:GetCellInt('ID_1er_Inter', 0);
			DelayDoubleDetect = TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
			--Alert("RaceResult_WebRestApi.passingCurrent ="..RaceResult_WebRestApi.passingCurrent.."/ TypeTable :"..TypeTable);
				if TypeTable == 'GEN' then
					CodeTypeTable = 0;
				else
					CodeTypeTable = RaceResult_WebRestApi.code_competition ;
				end
		end
	
		-- On recherche si il y a une ou plusieurs lignes de créer ds la table TabletagID_Tour pour l'evt
		-- Si pas de ligne on inscrit dans latable	
		cmd = "Select * From tagID_Tour Where Code = '"..RaceResult_WebRestApi.code_competition.."' and AdresseIP = '"..ActiveID.."' Order by bibMini";
		if RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows() == 0 then
			local bibMini = 1;
			local bibMax = 9999;
			local LoopID = 'Loop0';
			local LoopCanal = 'LoopCanal0';
			local Tour = 0;
			AddTabletagID_Tour(RaceResult_WebRestApi.code_competition,ActiveID,bibMini,bibMax,LoopID,LoopCanal,Tour);
		end
	-- Recherche si une table de corespondance existe dans la table tagID_Correspondance
		cmd = "Select * From tagID_Correspondance Where Code = "..CodeTypeTable.." Order by Dossard";
		if RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Correspondance, cmd):GetNbRows() == 0 then
			Alert("pas de Table de correspondance pour cet évènement : "..RaceResult_WebRestApi.code_competition);
		else
		-- Alert("TypeTable ="..TypeTable);
			if TypeTable == 'GEN' then
				Alert("Utilisation de la table Générique pour l'EVT  : "..RaceResult_WebRestApi.code_competition.." avec "..TabletagID_Correspondance:GetNbRows().." lignes créées");
			elseif TypeTable == 'EVT' then
				Alert("Utilisation de la table spécifique à l'évènement N°: "..RaceResult_WebRestApi.code_competition.." avec "..TabletagID_Correspondance:GetNbRows().." lignes créées");
			else
				Alert("pas de table de corespondance pour l'EVT  : "..RaceResult_WebRestApi.code_competition);
			end	
		end
				
	-- creation de la variables RecordsCount (nb de transpondeur detecter par la ligne chrono)
		RaceResult_WebRestApi.RecordsCount = 0;

	-- Affichage ...
		panel:Show(true);
		
		local mgr = app.GetAuiManager();
		
		local caption = '/ '..ActiveID;
		
		mgr:AddPane(panel, {
			icon = './res/Mini-logo-raceresult.png',
			caption = "RaceResult Web-REST-API / "..ActiveID..", Passage = "..passage.." And N° Files = "..RaceResultfile,
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
		
		-- Mise en place de la gestion "Asynchrone"
		curlCommand = { 
			getSystemStatus = 1,
			GetNbDetections= 2,
			getPassings = 3,
			getModeChrono = 4,
			getSystemPassings = 5,
			getTestConnect = 6,
			OnActiveChrono = 7,
			OnReadConnect = 8,
			GetGPS_Time = 9;
		};
		
		panel:Bind(eventType.CURL, OnGetSTATUS, curlCommand.getSystemStatus); -- demande du statut
		panel:Bind(eventType.CURL, ReadCountDetection, curlCommand.GetNbDetections);-- demande du nb de passing par le timer
		panel:Bind(eventType.CURL, OnReadPassings, curlCommand.getPassings); -- 
		panel:Bind(eventType.CURL, ReadModeChrono, curlCommand.getModeChrono);
		panel:Bind(eventType.CURL, OnGetPASSINGS, curlCommand.getSystemPassings); 
		panel:Bind(eventType.CURL, ReadTestConnect, curlCommand.getTestConnect);
		panel:Bind(eventType.CURL, ReadModeChrono, curlCommand.OnActiveChrono);
		panel:Bind(eventType.CURL, ReadConnection, curlCommand.OnReadConnect);
		panel:Bind(eventType.CURL, ReadGPS_Time, curlCommand.GetGPS_Time);

	-- fin du controle des parametres de connection au serveur raceresult
	end
end

-- Fonction des tables de correspondance
--Outils:
--Pour Vider une table de corespondance	
function OnClearTableCorres(evt)
	if RaceResult_WebRestApi.panel:MessageBox("Confirmation du Vidage de la table de corespondance ?\n\nCette opération effecera le contenue de la table corespondance de cet évènement", "Confirmation du Vidage de la table de corespondance", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	-- Alert ("CodeTypeTable = "..CodeTypeTable.."et  TypeTable = ".. TypeTable);
	if CodeTypeTable ~= "" or  TypeTable ~= "" then
	cmd = "Delete From tagID_Correspondance Where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	RaceResult_WebRestApi.dbSki:Query(cmd);
	else
	cmd = "Delete From tagID_Correspondance Where Code = "..RaceResult_WebRestApi.code_competition;
	RaceResult_WebRestApi.dbSki:Query(cmd);
	end
	
--	TabletagID_Correspondance:RemoveAllRows();
	cmd = "Select * From tagID_Correspondance where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
 if TabletagID_Correspondance:GetNbRows() >= 1 then
	Alert("la table ne sais pas vider = "..TabletagID_Correspondance:GetNbRows());
end	
	TypeTable = 'ND'
	--Alert('je modifi dans la table TagID_Passings'..TypeTable)
	cmd = "Update tagID_Passings SET TypeTable = '"..TypeTable.."' Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'"
	RaceResult_WebRestApi.dbSki:Query(cmd);
	Warning("Vidage table tagID_Correspondance ok...");

	-- Rafraichissement de la grille ...
	local grid = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
	grid:SynchronizeRows();
end

-- Chargement de la table de corespondance
function OnChargeTableCorres(CodeTypeTable, TypeTable)
 if Table.state == true then
	-- recherche si il y a deja une table de corespondance de charger dans la base
	cmd = "Select * From tagID_Correspondance where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
	 if TabletagID_Correspondance:GetNbRows() >= 1 then
		if RaceResult_WebRestApi.panel:MessageBox("Confirmation du chargement de la table de corespondance ?\n\nCette opération effacera la table actuellement dans la base de donnée \n avant d'effectuer le rechargement de la table.", "Confirmation du chargement des Tag_ID et Dossards", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
			return;
		end
		
		OnClearTableCorres(CodeTypeTable, TypeTable)
		
	 end
 
 
	if RaceResult_WebRestApi.panel:MessageBox("Confirmation du chargement de la table de corespondance ?\n\nCette opération vas effectuer le chargement de la table.", "Confirmation du chargement des Tag_ID et Dossards", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
--  rechercher le fichier .xls des séquences à relire et le charger
	local fileDialog = wnd.CreateFileDialog(RaceResult_WebRestApi.panel,
		"Sélection du fichier de corespondance",
		RaceResult_WebRestApi.directory, 
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
						TabletagID_Correspondance:SetCell("Code", r, RaceResult_WebRestApi.code_competition);
						end
				TabletagID_Correspondance:SetCell("TagID", r, TagID);		
				TabletagID_Correspondance:SetCell("Dossard", r, Dossard);
				TabletagID_Correspondance:SetCell("TypeTable", r, TypeTable);
				RaceResult_WebRestApi.dbSki:TableInsert(TabletagID_Correspondance, r);
				end
			end
		end
		csvFile:close();
	-- Alert('je modifi dans la table TagID_Passings'..TypeTable)
	cmd = "Update tagID_Passings SET TypeTable = '"..TypeTable.."' Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'"
	RaceResult_WebRestApi.dbSki:Query(cmd);
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

--Pour charger une table générique
function OnValidTypeTableGen(evt)
	cmd = "Select * From tagID_Correspondance where Code = '0' and TypeTable = 'GEN' Order by Dossard";
	RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
	 if TabletagID_Correspondance:GetNbRows() >= 1 then
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable	= 'GEN' Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'";
		RaceResult_WebRestApi.dbSki:Query(cmd);
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

-- Pour charger une table qui ne fonctionne que pour l'evenement
function OnValidTypeTableEvt(evt)
	cmd = "Select * From tagID_Correspondance where Code = "..RaceResult_WebRestApi.code_competition.." and TypeTable = 'EVT'";
	RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Correspondance, cmd)
	
	if TabletagID_Correspondance:GetNbRows() >= 1 then
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable	= 'EVT' Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'";
		RaceResult_WebRestApi.dbSki:Query(cmd);
		TypeTable = 'EVT';	
		Table.state = true ;
		CodeTypeTable = tonumber(RaceResult_WebRestApi.code_competition);
		--Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
		-- Rafraichissement de la grille ...
		local grid = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
		grid:SynchronizeRows();
		Success('Validation de l\'utisation d\'une table unique à l\'évènement pour cet évènement ! ');
	else
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable = 'EVT'  Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'";
		RaceResult_WebRestApi.dbSki:Query(cmd);
		TypeTable = 'EVT';	
		Table.state = true ;
		CodeTypeTable = tonumber(RaceResult_WebRestApi.code_competition);
		Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
		OnChargeTableCorres(CodeTypeTable, TypeTable);
	end
	Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
end

-- fonction qui enregistre le modif de la table de corespondance manuel
function OnSaveTableCorres()
	cmd = "Delete From tagID_Correspondance Where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	RaceResult_WebRestApi.dbSki:Query(cmd);
	
	local Grid_Ligne = dlgCorespondance:GetWindowName('grid_TableCorrespondance'):GetTable();
	--Alert("RaceresultWebServeur_option:GetNbRows() = "..Grid_Ligne:GetNbRows());
	for i=0, Grid_Ligne:GetNbRows()-1 do
		TabletagID_Correspondance:SetCell("Code", i, Grid_Ligne:GetCellInt('Code', i));
		TabletagID_Correspondance:SetCell("TagID", i, Grid_Ligne:GetCell('TagID', i));
		TabletagID_Correspondance:SetCell("Dossard", i, Grid_Ligne:GetCellInt('Dossard', i));
		TabletagID_Correspondance:SetCell("TypeTable", i, TypeTable);
		RaceResult_WebRestApi.dbSki:TableFlush(TabletagID_Correspondance, i);
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

-- Création de la boite de dialogue pour la gestion de la table de corespondance
function OnOpenTableCorespondance(evt)
	dlgCorespondance = wnd.CreateDialog({
		parent = RaceResult_WebRestApi.panel,
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
	Race_result = {};
	function OnClosedlgCorespondance(evt)
		dlgCorespondance:EndModal();
	end
	
	-- Grid corespondance
	cmd = "Select * From tagID_Correspondance Where Code = '"..CodeTypeTable.."' Order by Dossard";
	RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Correspondance, cmd)
	
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
	Race_result.tb = dlgCorespondance:GetWindowName('tb');
	RaceresultWebServeurTb_Table = Race_result.tb:AddTool("Outil race Time", "./res/32x32_config.png", "outils",  itemKind.DROPDOWN);
	RaceresultWebServeurTb_Clear = Race_result.tb:AddTool('Remise à Zéro des Données', './res/32x32_clear.png');
	Race_result.tb:AddStretchableSpace();
	RaceresultWebServeurTb_InsertLigne = Race_result.tb:AddTool("Ajouter une Ligne", "./res/32x32_list_add.png");
	Race_result.tb:AddSeparator();
	RaceresultWebServeurTb_DeleteLigne = Race_result.tb:AddTool("Supprimer une Ligne", "./res/32x32_list_remove.png");
	Race_result.tb:AddSeparator();
	RaceresultWebServeurTb_Save = Race_result.tb:AddTool("Enregistrer", "./res/32x32_save.png");
	Race_result.tb:AddSeparator();
	RaceresultWebServeurTb_Exit = Race_result.tb:AddTool("Quitter", "./res/32x32_exit.png");

	local menuSend =  menu.Create();
	menuSend:AppendSeparator();
	RaceresultWebServeurTb_Table_TableGe = menuSend:Append({label="Utilisation de la Table Generique à tout les évènements", image ="./res/32x32_time-admin.png"});
	menuSend:AppendSeparator();	
	-- RaceresultWebServeurTb_OnChargeTableCorres = menuSend:Append({label="Upload d'une Table Generique à tout les évènements", image ="./res/32x32_time-admin.png"});
	-- menuSend:AppendSeparator();
	RaceresultWebServeurTb_Table_TableEvt = menuSend:Append({label="Upload et utilisation d'une Table unique à un évènement", image ="./res/vpe32x32_search.png"});
	Race_result.tb:SetDropdownMenu(RaceresultWebServeurTb_Table:GetId(), menuSend);
	Race_result.tb:Realize();
	
	-- Prise des Evenements (Bind)
	dlgCorespondance:Bind(eventType.MENU, OnRaceresultWebServeurOutil);
	-- dlgCorespondance:Bind(eventType.MENU, OnChargeTableCorres, RaceresultWebServeurTb_OnChargeTableCorres);
	dlgCorespondance:Bind(eventType.MENU, OnClearTableCorres, RaceresultWebServeurTb_Clear);
	dlgCorespondance:Bind(eventType.MENU, OnSaveTableCorres, RaceresultWebServeurTb_Save);
	dlgCorespondance:Bind(eventType.MENU, OnClosedlgCorespondance, RaceresultWebServeurTb_Exit);
	dlgCorespondance:Bind(eventType.MENU, OnInsertLigneCor, RaceresultWebServeurTb_InsertLigne);
	dlgCorespondance:Bind(eventType.MENU, OnDeleteLigneCor, RaceresultWebServeurTb_DeleteLigne);
	dlgCorespondance:Bind(eventType.MENU, OnValidTypeTableGen, RaceresultWebServeurTb_Table_TableGe);
	dlgCorespondance:Bind(eventType.MENU, OnValidTypeTableEvt, RaceresultWebServeurTb_Table_TableEvt);

	-- permet de verifier et fixer les choses avt le showmodal (à faire obligatoirement)
	dlgCorespondance:Fit();

	-- Affichage Modal
	dlgCorespondance:ShowModal();
	
end	

-- Fonction d' activation du chrono et de connection au serveur Race-result
function OnStartRaceresultWebServeur(evt)
	-- Vérification si on a bien déclarer une table de corespondance
	if TypeTable == 'ND' then 
		Warning("Pas de table de corespondance ");
		Warning("Veuillez sélectionner un type de table et uploader une table via un fichier .csv ");
	else
		if RaceResult_WebRestApi.ActiveStart == "Non Actif" then
			Success("Correspondance : "..TabletagID_Correspondance:GetNbRows().." ligne ds la table");
			Alert("Type de Table utiliser pour cet évènement Race_result :"..TypeTable);
			-- Création du Jeton si il n'en existe pas
			if RaceResult_WebRestApi.access_token == false then
				OnCreateJeton()
			end
			-- Création de l'adresse Url pour recuperer les passings sur le serveur race result.
			if RaceResult_WebRestApi.access_token ~= false then
				CreateURL_status(curlCommand.getSystemStatus);
				
			else
				Alert('Pas d\'access_token au serveur Race-result');
			end
		
		else 
			Error("Déja activé !");
		end		

	end		
end

-- fonction qui créer le Bearer d'acces 
function OnCreateJeton()
-- 1) Récupération du Jeton par rapport a L'API-KEY du compte utilisateur Race-result
	local url = device.url;
	local param = "apikey="..RaceResult_ApiKey;
	-- adv.Alert('url='..url);
	-- adv.Alert('RaceResult_ApiKey='..param);
	local jsonText = curl.POST(url, param);
	-- adv.Alert('jsonText='..jsonText);
	-- Exemple de retour : '{"access_token":"eyJhbGciOiJlZDI1NTE5IiwidHlwIjoiSldUIn0.eyJhdWQiOiJyZXN0cHJveHkiLCJleHAiOjE2MjM5NDU5NTUsInN1YiI6IjE5OTc0In0.6mv14RZXQVzKvcv4nY4znmPKKoedTwoKK0jeD-BAqwBFebMZfla2pKreObxZzl_6dpj-kYC0LKWU1KS95xcFDA","expires_in":7200,"token_type":"Bearer"}';
	if jsonText:len() > 0 then
		--adv.Success('JSON Return='..jsonText);
		local jsonConnect = table.FromStringJSON(jsonText);
		if jsonConnect.error == 'access denied' then
			Error("Acces serveur raceresult refusé!");
			return false;
		else
			if type(jsonConnect) == 'table' then
				RaceResult_WebRestApi.access_token = jsonConnect.access_token ;
				-- adv.Alert('access_token='..jsonConnect.access_token);
				-- adv.Alert('expires_in='..jsonConnect.expires_in);
				-- adv.Alert('token_type='..jsonConnect.token_type);
				-- RaceResult_WebRestApi.ActiveStart = "Actif";
				-- Création d'un timer pour recuperer un jeton au bout de 7200sec.
				RaceResult_WebRestApi.timerJeton = timer.Create(RaceResult_WebRestApi.panel);
				if RaceResult_WebRestApi.timerJeton ~= nil then
					--RaceResult_WebRestApi.timerJeton:Delete();
					RaceResult_WebRestApi.timerJeton:Start(RaceResult_WebRestApi.JetonDelay);
				end
				RaceResult_WebRestApi.panel:Bind(eventType.TIMER, OnCreateJeton, RaceResult_WebRestApi.timerJeton);
				Success('Acces Au serveur RaceResult Ok / token_type='..jsonConnect.token_type..' / expires dans ='..jsonConnect.expires_in..'Sec');
			end
		end
	end
	
end

-- Fonction qui créer l'url pour demander le status au serveur raceresult
function CreateURL_status(curlCommand)
	if RaceResult_WebRestApi.access_token == false then
		OnCreateJeton()
	end
 -- Alert("CreateURL_status ="..RaceResult_WebRestApi.access_token);
 -- https://rest.devices.raceresult.com/customers/19974/devices/T-21941
	local url = device.url_rest..
					'customers/'..RaceResultuser..
					'/devices?deviceIDs='..ActiveID..
					'&connected=true'
					;
					
	if url ~= nil then
		curl.AsyncGET(panel, url, curlCommand, RaceResult_WebRestApi.access_token);
		-- Alert("url CreateURL_status ="..url);
	end
end 

-- fonction pour lire le status d'un decodeur ou d'une trackbox 
function OnGetSTATUS(evt)
 -- Lecture du JSON get status
	local jsonText = evt:GetString();
	-- Alert("jsonText status ="..jsonText);

-- Si le len() du result du Json est superieur a 3 le decodeur est connecter
	if jsonText:len() > 3 then
		-- adv.Success('JSON Return='..jsonText);
		local jsonRes = table.FromStringJSON(jsonText);
		local Devices = #jsonRes.Devices ;
		-- adv.Success('Devices = '..jsonRes);
		-- boucle pour lire les resultas les afficher ou créer les variables
		for i=1,Devices do
			-- adv.Alert('Devices'..tostring(i));
			-- adv.Alert('  => Customer :'..jsonRes.Devices[i].Customer);
			-- adv.Alert('  => DeviceID :'..jsonRes.Devices[i].DeviceID);
			-- adv.Alert('  => DeviceName :'..jsonRes.Devices[i].DeviceName);
			-- adv.Alert('  => FileNo :'..jsonRes.Devices[i].FileNo);
			-- adv.Alert('  => BatteryCharge :'..jsonRes.Devices[i].BatteryCharge);
			-- adv.Alert('  => RecordsCount :'..jsonRes.Devices[i].RecordsCount);
			-- adv.Alert('  => Connected :'..tostring(jsonRes.Devices[i].Connected));
			-- adv.Alert('  => DeviceType :'..jsonRes.Devices[i].DeviceType);
			-- adv.Alert('  => DecoderStatus : Protocol='..jsonRes.Devices[i].DecoderStatus.Protocol..
				-- ', IsInTimingMode='..tostring(jsonRes.Devices[i].DecoderStatus.IsInTimingMode)..
				-- ', Antennas='..tostring(jsonRes.Devices[i].DecoderStatus.Antennas)..
				-- ', IsInTimingMode='..tostring(jsonRes.Devices[i].DecoderStatus.IsInTimingMode)..
				-- ', TimeIsRunning='..tostring(jsonRes.Devices[i].DecoderStatus.TimeIsRunning)
			-- );
			-- Création de variables  RaceResultTypeBox
			local FileNo = jsonRes.Devices[i].FileNo;
			RaceResult_WebRestApi.RecordsCount = tonumber(jsonRes.Devices[i].RecordsCount);
			local batteryCharge = tonumber(jsonRes.Devices[i].BatteryCharge) or 0;
			local PowerStatus = jsonRes.Devices[i][RaceResulStatus].PowerStatus or '-'
			--DecoderStatus TrackboxStatus
			ProtocolDecodeur = tostring(jsonRes.Devices[i][RaceResulStatus].Protocol);
			ModeChrono = jsonRes.Devices[i][RaceResulStatus].IsInTimingMode;
			IsInTimingMode = tostring(jsonRes.Devices[i][RaceResulStatus].IsInTimingMode);
			RaceResult_WebRestApi.ModeChrono = tostring(jsonRes.Devices[i][RaceResulStatus].IsInTimingMode);
		
			-- Alert("Decodeur OnLine="..tostring(jsonRes.Devices[i].Connected));		
			RaceResult_WebRestApi.Connect:SetLabel("Connect");
			
			-- On peu lancer continuer en verifiant le N° de fichier
			-- si le N° de fichier est identique dans skiffs et sur le serveur on peu lancer le timer chrono	averif			
			if tonumber(FileNo) == tonumber(RaceResultfile) then
				-- Timer Init ...******
				-- Creation du Timer 
				RaceResult_WebRestApi.timerChrono = timer.Create(RaceResult_WebRestApi.panel);
				if RaceResult_WebRestApi.timerChrono ~= nil then
					RaceResult_WebRestApi.timerChrono:Start(RaceResult_WebRestApi.timerDelay);
				end
				RaceResult_WebRestApi.panel:Bind(eventType.TIMER, OnTimerChrono, RaceResult_WebRestApi.timerChrono);
				adv.Success('Connection OK / decodeur: '..ActiveID..'N° de fichier: '..FileNo);
				Alert("Mode chrono Activé ")
				if IsInTimingMode == false then
					Warning("Décodeur en mode STANBY ....")
				end
			else
				Alert ('le N° de fichier ne correspond pas entre skiffs et le serveur!!!!!')
				Alert ('le N° de fichier Actif du decodeur :'..ActiveID..'est :'..FileNo..'et le fichier declarer dans SKIFFS est : '..RaceResultfile)
			end	
			
	-- niveau de charge de la batterie
			if batteryCharge < 10 then
				Warning("Charge de la batterie trop faible: "..batteryCharge.."%");
				if PowerStatus ~= 'POWER' then
					RaceResult_WebRestApi.battery:SetLabel("Bat is ="..PowerStatus);
				else
					RaceResult_WebRestApi.battery:SetLabel("Charge Bat ="..batteryCharge..'%');
				end
			else
			RaceResult_WebRestApi.battery:SetLabel("Charge Bat ="..batteryCharge..'%');
			end	
	-- Mise a jour des donnée decodeur ds la barre d'outil
			OngetInfo();
		
		end --fin de la boucle for i=1,Devices do
	else
		RaceResult_WebRestApi.timerConnect = timer.Create(RaceResult_WebRestApi.panel);
		if RaceResult_WebRestApi.timerConnect ~= nil then
			RaceResult_WebRestApi.timerConnect:Start(RaceResult_WebRestApi.timerDelayConnect);
		end
		RaceResult_WebRestApi.panel:Bind(eventType.TIMER, OnTestConnectresultWebServeur, RaceResult_WebRestApi.timerConnect);	
		Alert("Décodeur :"..ActiveID.." OffLine ");	
	end	
	
end	

-- recherche si le decodeur est connecter
function OnTestConnectresultWebServeur(evt)
	if RaceResult_WebRestApi.access_token == false then
	OnCreateJeton()
	end

	local url = device.url_rest..
					'customers/'..RaceResultuser..
					'/devices?deviceIDs='..ActiveID..
					'&connected=true';
	if url ~= nil then
		curl.AsyncGET(panel, url, curlCommand.getTestConnect, RaceResult_WebRestApi.access_token);
		--Alert("OnTestConnectresultWebServeur ");
	end
end	

-- fonction de lecture de OnTestConnectresultWebServeur
function ReadTestConnect(evt)	
-- Lecture du JSON get status
	local jsonText = evt:GetString();
-- Si le len() du result du Json est superieur a 3 le decodeur est connecter
	if jsonText:len() > 3 then
		Status = evt:GetString();
		-- Alert("Status venat du timer OnTestConnectresultWebServeur : "..Status);
		if RaceResult_WebRestApi.watchDogConnect ~= nil then
		RaceResult_WebRestApi.watchDogConnect:Delete();
		RaceResult_WebRestApi.watchDogConnect = nil;
		end
		-- on suprime le timer de test de connection
		if RaceResult_WebRestApi.timerConnect ~= nil then
			RaceResult_WebRestApi.timerConnect:Delete();
		end
		
		-- On envoi la table dans OnGetSTATUS pour lecture des données
		OnGetSTATUS(evt);
	else
		-- Mise en place du WatchDog
		RaceResult_WebRestApi.watchDogConnect = timer.Create(RaceResult_WebRestApi.panel);
		if RaceResult_WebRestApi.watchDogConnect ~= nil then
			RaceResult_WebRestApi.watchDogConnect:StartOnce(1000); -- Il faut moins de 1 sec au raceresult pour répondre 
		end
			
		RaceResult_WebRestApi.panel:Bind(eventType.TIMER, OnWatchDogConnect, RaceResult_WebRestApi.watchDogConnect);
		--Alert("Status KO ="..Status);
		Alert("le decodeur :"..ActiveID.." n'est toujours pas connecter");
	end

end

-- fonction pour demander si le decodeur est connecter au serveur Race-result
function OnReadConnection()
	CreateURL_status(curlCommand.OnReadConnect)
end

-- fonction de lecture de OnReadConnection
function ReadConnection(evt)
	-- Lecture du JSON get status
	local jsonText = evt:GetString();
	-- Alert("ReadConnection ="..jsonText);

-- Si le len() du result du Json est superieur a 3 le decodeur est connecter
	if jsonText:len() > 3 then
		-- adv.Success('JSON Return='..jsonText);
		local jsonRes = table.FromStringJSON(jsonText);
		local Devices = #jsonRes.Devices ;
		-- adv.Success('Devices = '..jsonRes);
		-- boucle pour lire les resultas les afficher ou créer les variables
		for i=1,Devices do
			-- adv.Alert('Devices'..tostring(i));
			batteryCharge = tonumber(jsonRes.Devices[i].BatteryCharge) or 0;
			ModeChrono = jsonRes.Devices[i][RaceResulStatus].IsInTimingMode;
			IsInTimingMode = tostring(jsonRes.Devices[i][RaceResulStatus].IsInTimingMode);
		end
		-- Alert("Decodeur OnLine="..tostring(jsonRes.Devices[i].Connected));		
		RaceResult_WebRestApi.Connect:SetLabel("Chr. Actif");
		if IsInTimingMode == false then
			Warning("Décodeur en mode STANBY ....")
		end
			
			
	-- niveau de charge de la batterie
		if batteryCharge < 10 then
			Warning("Charge de la batterie trop faible: "..batteryCharge.."%");
			if PowerStatus ~= 'POWER' then
				RaceResult_WebRestApi.battery:SetLabel("Bat is ="..PowerStatus);
			else
				RaceResult_WebRestApi.battery:SetLabel("Charge Bat ="..batteryCharge..'%');
			end
		else
		RaceResult_WebRestApi.battery:SetLabel("Charge Bat ="..batteryCharge..'%');
		end	
	-- Mise a jour des donnée decodeur ds la barre d'outil
		OngetInfo();
	else	
	Warning("Upload Décodeur non Actif.???")
	end
	
end

-- connection du watchDog ....
function OnWatchDogConnect(evt)
	-- Aucune réponse du Raceresult ... on n'est pas ou plus connecté
	RaceResult_WebRestApi.Connect:SetLabel("Non Connect");
	RaceResult_WebRestApi.battery:SetLabel('Bat=---%');
	
	if RaceResult_WebRestApi.watchDogConnect ~= nil then
		RaceResult_WebRestApi.watchDogConnect:Delete();
		RaceResult_WebRestApi.watchDogConnect = nil;
	end
end

-- Création d'un timer pour savoir le Nb de passing dans le fichier
function OnTimerChrono(evt)
-- agrementation de la variable alive (compteur timer)
	RaceResult_WebRestApi.alive = RaceResult_WebRestApi.alive + 1;
-- Activation de la fonction OnGetNbDetections() qui permet de savoir le nb de detections dans un fichier donner
	OnGetNbDetections();
-- Mise a jour des donnée dans l'afficheur Race-result dans skiffs
	OngetInfo();
-- Alert("OnTimerChrono");
end

-- Fonction qui créer l'url pour demander le Nb de détection dans le fichier en court de lecture pour l'acitiveID actif
function OnGetNbDetections()
	if RaceResult_WebRestApi.access_token == false then
		OnCreateJeton()
	end
 -- https://rest.devices.raceresult.com/customers/19974/devices/D-50582/files/99
	local url = device.url_rest..
					'customers/'..RaceResultuser..
					'/devices/'..ActiveID..
					'/files/'..RaceResultfile
					;
					
	if url ~= nil then
		curl.AsyncGET(panel, url, curlCommand.GetNbDetections, RaceResult_WebRestApi.access_token);
		-- Alert("test url OnGetNbTrapkings ="..url);
	end
end 

-- fonction pour lire le Nb de détections 
function ReadCountDetection(evt)
	-- Alert("ReadCountDetection");
	local jsonText = nil ;
	local jsonText = evt:GetString();
	-- Si le len() du result du Json est superieur a 3 le decodeur est connecter
	if jsonText:len() > 3 then
		-- adv.Success('JSON Return='..jsonText);
		local jsonRes = table.FromStringJSON(jsonText);
		-- Alert('  => Nb de Detection :'..jsonRes.Count..' dans le fichier N°: '..RaceResultfile);
		-- adv.Alert('  => Created :'..jsonRes.Created);
		-- adv.Alert('  => Customer :'..jsonRes.Customer);
		-- adv.Alert('  => DeviceID :'..jsonRes.DeviceID);
		-- adv.Alert('  => FileNo :'..jsonRes.FileNo);

		local RecordsCount = tonumber(jsonRes.Count);
		if RecordsCount ~= nil then
			RaceResult_WebRestApi.RecordsCount = tonumber(jsonRes.Count);
			-- Alert("RaceResult_WebRestApi.passingCurrent = "..RaceResult_WebRestApi.passingCurrent.." RecordsCount = "..RecordsCount);
			if tonumber(RaceResult_WebRestApi.passingCurrent) == RecordsCount then
				-- Alert("RaceResult_WebRestApi.passingCurrent = RecordsCount");
			elseif tonumber(RaceResult_WebRestApi.passingCurrent) > RecordsCount then
				-- Alert("RaceResult_WebRestApi.passingCurrent > RecordsCount");
			elseif tonumber(RaceResult_WebRestApi.passingCurrent) < RecordsCount then
				-- Si RaceResult_WebRestApi.passingCurrent (detec en meoire) est < RecordsCount( Nb de detect dans le fichier) on lance la fonction OnGetPassings(RecordsCount)
				-- Alert("RaceResult_WebRestApi.passingCurrent < RecordsCount");
				OnGetPassings(RecordsCount);
			else
				Alert("probleme de RaceResult_WebRestApi.RecordsCount ou RecordsCount");
			end
		else
			Alert("RecordsCount = nil");
			return false
		end
	end	

end

-- fonction pour recharger un fichier complet de Passings ou Trackpings
function OnRechargeFichierOffLine()
if RaceResult_WebRestApi.access_token == false then
	OnCreateJeton()
end
RaceResult_WebRestApi.ActiveStart = "Non Actif";
OnGetPassings(99999);
end

-- Créations des URL pour récuperer le fichiers complets ou juste les passings Non lus
function OnGetPassings(RecordsCount)
	-- notice RaceResulFirstDetect => Trackping
	--        RaceResultTypedetect => passings
	-- Alert('RecordsCount = '..RecordsCount);
	-- Alert('RaceResult_WebRestApi.passingCurrent = '..RaceResult_WebRestApi.passingCurrent);
	if tonumber(RaceResult_WebRestApi.passingCurrent) == 0 then
		--url pour recevoir les passings du fichier en court d'utilisation
		url = device.url_rest..
						'customers/'..RaceResultuser..
						'/devices/'..ActiveID..
						'/'..RaceResultTypedetect..'?fromFile='..RaceResultfile
						;
	elseif tonumber(RecordsCount) == 99999 then
		--url pour recevoir les passings d'un fichier ancien 
		url = device.url_rest..
						'customers/'..RaceResultuser..
						'/devices/'..ActiveID..
						'/Files/'..RaceResultfile..
						'/'..RaceResultTypedetect..'?'
						;
	else
		--url pour recevoir les passings avec limit (D-50582/files/91/passings?fromPassing=1&amount=100"  url avec limit)
		RaceResultamount = RecordsCount - tonumber(RaceResult_WebRestApi.passingCurrent);
		FirstPassing = RaceResult_WebRestApi.passingCurrent + 1;
		url = device.url_rest..
						'customers/'..RaceResultuser..
						'/devices/'..ActiveID..
						'/files/'..RaceResultfile..
						'/'..RaceResultTypedetect..'?from'..RaceResulFirstDetect..'='..FirstPassing..
						'&amount='..RaceResultamount
						;
	end
	
	if url ~= nil then
		-- Alert("On demande la lecture du fichier passings");
		curl.AsyncGET(panel, url, curlCommand.getPassings, RaceResult_WebRestApi.access_token);
		-- Alert("url OnGetPassings = "..url);
	end
end

-- fonction pour mettre le Nb de detection recu à jour dans la table LUA RaceResult_WebRestApi.passingCurrent et la base sql
function SavePassingCurrent()	
	-- Alert('SavePassingCurrent = '..tostring(RaceResult_WebRestApi.passingCurrent))
	RaceResult_WebRestApi.passingCurrent = tonumber(RaceResult_WebRestApi.passingCurrent) + 1;
	-- Enregistrement en MySQL 
	cmd = 
		"update tagID_Passings set Passings = "..
		tostring(RaceResult_WebRestApi.passingCurrent)..
		" Where Code = "..RaceResult_WebRestApi.code_competition..
		" And AdresseIP = '"..ActiveID..
		"'"
		;
	RaceResult_WebRestApi.dbSki:Query(cmd);
	cmd = "Select * From tagID_Passings Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'";
		TableTagID_Passings = RaceResult_WebRestApi.dbSki:GetTable('tagID_Passings');
		RaceResult_WebRestApi.dbSki:TableLoad(TableTagID_Passings, cmd);	
		
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
	--+tonumber(DiffGMT)
	return 3600000*tonumber(hour)+1000*tonumber(RaceResult_WebRestApi.DiffGMT)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
end

-- fonction qui inscrit un temps dans la table chrono
function AddTimePassage(chrono, passage, bib, tagID)	
	bib = bib or '';
	tagID = tagID or '';
	passage = passage or '';
	chrono = chrono or '';
	--Alert("test variable bib="..bib.."tagID ="..tagID.."passage ="..passage.."/")
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'Copy_RaceResult-RestAPI'..ActiveID, tag = tagID }
	);
	
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
	cmd = "select * from TagID_Finish where Code = "..RaceResult_WebRestApi.code_competition..
			" and AdresseIP = '"..ActiveID..
			"' and LoopID = '"..LoopID..
			"' and LoopCanal = '"..LoopCanal..
			"' and TagID = '"..tagID..
			"'"
	return RaceResult_WebRestApi.dbSki:TableLoad(TableTagID_Finish, cmd):GetCellInt("Tour", 0);
end

-- fonction qui renvoi le DelayDoubleDetect 
function GetDelayDoubleDetect()		
	-- Chargement de la table TableTagID_Passings pour avoir le DelayDoubleDetect
	cmd = "Select * From tagID_Passings Where Code = "..RaceResult_WebRestApi.code_competition..
		  " and AdresseIP = '"..ActiveID..
		  "' and LoopID = '"..LoopID..
		  "' and LoopCanal = '"..LoopCanal..
		  "'"
		  ;
	-- RaceResult_WebRestApi.dbSki:TableLoad(TableTagID_Passings, cmd);
	if tonumber(RaceResult_WebRestApi.dbSki:TableLoad(TableTagID_Passings, cmd):GetNbRows()) == 0 then
		Warning(" Vérifier les numero des Loop et Canal Loop il doive etre: ");
		Alert("Les données du fichier lu sont -> LoopID = "..LoopID.." / Canal = "..LoopCanal.." / SystemeActif = "..SystemeActif )
		Warning(" Apres les avoir Vérifier recharger a nouveau le fichier ou réactiver la lescture du decodeur");
		Alert(" bien remetre le Nb de passing detecter à 0 sinon le fichier ne seras pas lu");
		return false
	end
	
	return TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
end

		-- fonction recherche si un tagID existe dans la table TableTagID_Finish et di ID du dernier passage
function RechercheTagId_Rech_Der_Passge_TagID(ActiveID, LoopID, LoopCanal, tagID)
	cmd = "Select * From tagID_Finish Where Code = '"..RaceResult_WebRestApi.code_competition..
		  "' And AdresseIP = '"..ActiveID..
		  "' And LoopID = '"..LoopID..
		  "' And LoopCanal = '"..LoopCanal..
		  "' And TagID = '"..tagID..
		  "'"
		  ;
	
	Rech_TagID = RaceResult_WebRestApi.dbSki:TableLoad(TableTagID_Finish, cmd):GetCell("TagID", 0);
	Rech_Der_Passge_TagID = RaceResult_WebRestApi.dbSki:TableLoad(TableTagID_Finish, cmd):GetCellInt("Passage", 0);

end

		-- recherche si un tagID existe dans la table TagID_TourPena
function rechercheDos_TabletagID_TourPena(ActiveID, LoopID, LoopCanal, bib)
	cmd = "Select * From TagID_TourPena Where Code = '"..RaceResult_WebRestApi.code_competition..
		  "' And AdresseIP = '"..ActiveID..
		  "' And LoopID = '"..LoopID..
		  "' And LoopCanal = '"..LoopCanal..
		  "' And Dossard = "..bib							 
		  ;
	return RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCell("Dossard", 0);
end

-- fonction qui permet de lire la trame recu d'une trackbox ou d'un décodeur Race-result
function OnReadPassings(evt)
	-- notice RaceResulFromFiles => Trackpings
	jsonText = evt:GetString();
	-- Si le len() du result du Json est superieur a 3 le decodeur est connecter
	if jsonText:len() > 3 then
		-- adv.Success('JSON Return='..jsonText);

		local jsonRes = table.FromStringJSON(jsonText);
		local nbPassings = #jsonRes[RaceResulFromFiles];
		-- Alert('PASSINGS COUNT = '..nbPassings);

		for i=1,nbPassings do
			-- adv.Alert('PASSING No'..tostring(i));
			-- adv.Alert('  => Code :'..jsonRes[RaceResulFromFiles][i].Code);
			-- adv.Alert('  => Customer :'..jsonRes[RaceResulFromFiles][i].Customer);
			-- adv.Alert('  => RealTime :'..jsonRes[RaceResulFromFiles][i].RealTime);
			-- adv.Alert('  => DeviceID :'..jsonRes[RaceResulFromFiles][i].DeviceID);
			-- adv.Alert('  => FileNo :'..jsonRes[RaceResulFromFiles][i].FileNo);
			-- adv.Alert('  => Hits :'..jsonRes[RaceResulFromFiles][i].Hits);
			-- adv.Alert('  => IsActive :'..tostring(jsonRes[RaceResulFromFiles][i].IsActive)); 
			-- adv.Alert('  => LoopID :'..tostring(jsonRes[RaceResulFromFiles][i].LoopID));
			-- adv.Alert('  => Channel :'..tostring(jsonRes[RaceResulFromFiles][i].Channel));
			-- adv.Alert('  => LoopOnly :'..tostring(jsonRes[RaceResulFromFiles][i].LoopOnly));
			-- adv.Alert('  => PassingNo :'..jsonRes[RaceResulFromFiles][i].PassingNo);
			-- adv.Alert('  => TrackpingsNo :'..jsonRes[RaceResulFromFiles][i].TrackpingNo);
			if tostring(jsonRes[RaceResulFromFiles][i].IsActive) == true then 
				LoopID = 'Loop'..NumLoopID;
				LoopCanal = 'LoopCanal'..NumLoopCanal;
				SystemeActif = 1;
			else 
				LoopID = 'Loop0';
				LoopCanal = 'LoopCanal0';
				SystemeActif = 0;
			end 
			if RaceResultTypeBox == 'Decoder' then
				ReadJsonRes(jsonRes[RaceResulFromFiles][i].PassingNo, jsonRes[RaceResulFromFiles][i].Code, jsonRes[RaceResulFromFiles][i].RealTime, LoopID, LoopCanal, SystemeActif);
			elseif RaceResultTypeBox == 'Trackbox' then
				ReadJsonRes(jsonRes[RaceResulFromFiles][i].TrackpingNo, jsonRes[RaceResulFromFiles][i].Code, jsonRes[RaceResulFromFiles][i].Time, LoopID, LoopCanal, SystemeActif);
			end	
		end
	end
end 

-- lecture de la ligne provenant de la table jsonRes
function ReadJsonRes(passingCurrent, tagID, RealTime, LoopID, NumLoopCanal, SystemeActif)
	--Alert("	passingCurrent1 :"..passingCurrent);
	-- Mise au bon format millieme de seconde de la realtime
	hourPassage = GethourPassage(RealTime);
	-- Alert("	hourPassage :"..hourPassage.." et tagID = "..tagID);
	-- mise en milliseconde de l'heure de passage
-- ###### debut coupure pour tranfert //////////// code commun entre raceresult et RaceresultWebRestApi (entre les deux coupure) suivant si on est en IP ou en webserveur////******
	chrono = GetChrono(hourPassage);
	-- Alert("	CodeTypeTable :"..CodeTypeTable)
					
	-- on recherche si le CountTourActif est actif pour la Loop
	RechercheCountTourActif(CodeTypeTable,tagID, LoopID, LoopCanal);
	-- Alert("CountTourActif = "..CountTourActif)
	-- si c'est un systeme actif et que le N° de LoopID ou de LoopCanal sont == 0
	-- l'impulse viens du marqquer du decodeur 
	-- if tonumber(SystemeActif) == 0 and LoopID == 'Loop0' and LoopCanal == 'LoopCanal0' then
		-- Alert("L impulse viens du marqueur du décodeur "..ActiveID)
		-- Alert(chrono..' '..passage..' '..tagID);
		-- AddTimePassage(chrono, passage, '-'..tagID, tagID);	
	if tonumber(SystemeActif) == 1 and LoopID == 'Loop0' and LoopCanal == 'LoopCanal0' then
		Alert("L impulse viens du marqueur du décodeur "..ActiveID)
		--Alert(chrono..' '..passage..' '..tagID);
		AddTimePassage(chrono, passage, '-'..tagID, tagID);	
	else -- du tonumber(SystemeActif) == 1 ou du tonumber(SystemeActif) == 0
		-- si le CountTourActif == 0 donc non actifje gere normalement la detection comme un heure da passage
		if tonumber(CountTourActif) == 0 then			
			-- on recherche le dos et le nb de tour a faire par le dos 				
			RecherchetourDos(CodeTypeTable,tagID, LoopID, LoopCanal);
			Alert("bib = "..bib.." / Nb Tours A Faire = "..NbToursAFaire);		
			--si bib est différent de nil ou de '' on gere l'impultion						
			if bib ~= "" then				
				-- recherche si un tagID existe dans la table TableTagID_Finish et de Rech_Der_Passge_TagID
				RechercheTagId_Rech_Der_Passge_TagID(ActiveID, LoopID, LoopCanal, tagID)
				-- Alert("Rech_Der_Passge_TagID = "..Rech_Der_Passge_TagID)
				-- Alert("Rech_TagID = "..Rech_TagID)			
								--si Rech_TagID est diff de '' je gere l' impultion
					if Rech_TagID ~= '' then
						-- recherche du nombre de tour fait par le coureur ds la Table TableTagID_Finish 
						local NbTourRealiser = GetNbTourRealiser(tagID);
						-- Alert("NbTourRealiser: "..NbTourRealiser);
							
						-- Recherche du delay de double detection
						DelayDoubleDetect = GetDelayDoubleDetect();
						-- Alert("DelayDoubleDetect: "..DelayDoubleDetect);
						-- local TimeDelayDoubleDetect = tonumber(DelayDoubleDetect / 1000);
						-- local TimeDelayDoubleDetect = tonumber(TimeDelayDoubleDetect / 60);
						-- Alert("Attention Double detection delai entre les 2 detections < "..TimeDelayDoubleDetect.."Min");	
						
						-- incrementation de la variable passage suivant le Nb à faire te le Nb de tour réaliser
						local passage = GetPassage(NbToursAFaire,NbTourRealiser); 
						-- Alert("passage = "..passage);
						
						-- rechercher si une heure de passage est deja inscrite dans la table chrono
						local TimePassage = GetHeurePassage(bib, Rech_Der_Passge_TagID);
							--Alert(" chrono = "..chrono.." TimePassage = "..TimePassage);
							
						-- Je Calcul de l'heure de passage + delay double detection
						local TimePassagePlus = tostring(TimePassage)+tostring(DelayDoubleDetect); 
							--Alert(" TimePassagePlus ="..TimePassagePlus);
							
						-- si le l'heure dedetection 'chrono' est inferieur a tps + DelayDoubleDetect c'est une double détection
						if 	tonumber(chrono) <= tonumber(TimePassagePlus)then
							local bib = -6666;
							local tagID = tagID.."(d)";
							-- j'envoi l'heure de passage dans la table resultatchrono en signalent que c'est une double detection 
							AddTimePassage(chrono, Rech_Der_Passge_TagID, bib, tagID);

						else -- du tonumber(chrono) <= tonumber(TimePassagePlus)
						-- si le delay de double detection est passer je gere l'impultion normalement	
							-- Si le nb de tour realiser est < au nb de tour a faire je met l' heure ds la table
							if NbTourRealiser < NbToursAFaire then 
								--Alert("LoopID 1 = "..LoopID);
								AddNbTours(NbTourRealiser+1, tagID, ActiveID, LoopID, LoopCanal);
								AddTimePassage(chrono, NbTourRealiser+1, bib, tagID);
								refreshTagIDFinish(tagID, passage, LoopID, LoopCanal);
							elseif	NbTourRealiser == NbToursAFaire then
								-- Si le nb de tour realiser est == au nb de tour a faire je met l' heure ds la table
								AddNbTours(NbTourRealiser+1, tagID, ActiveID, LoopID, LoopCanal);
								AddTimePassage(chrono, passage, bib, tagID);
								refreshTagIDFinish(tagID, passage, LoopID, LoopCanal);
							elseif NbTourRealiser > NbToursAFaire then
								-- Si le nb de tour realiser est > au nb de tour a faire je met l' heure ds la table et je met -bib dans la table resultat chrono pour indiquer que le bib a deja été détecter
								AddNbTours(NbTourRealiser+1, tagID, ActiveID, LoopID, LoopCanal);
								AddTimePassage(chrono, passage, -bib, tagID);
							end
						end 
					--si recherche TagID == '' c'est la premiere detection du tagID j'envoi le temps ds la base					
					else -- du Rech_TagID ~= ''
						--Alert('premiere detection: Nb Tour Realiser = '..NbTourRealiser..' Nb Tours A Faire = '..NbToursAFaire)						
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
								-- Alert('Le concurent a fait le Bon nombre de Tour')
								AddTimePassage(chrono, passage, bib, tagID);
								AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib);
							end
						end
					end -- du Rech_TagID ~= ''
					
			else	-- du if bib ~= nil
				-- si bib = '' le tagID est inconnu ds la table de corespondance je met un dos -9999 pour le signaler au chrono et ne pas perdre l'impulse
				Warning("Tag ID inconnu dans la TableCorrespondance:  ")
				bib = -9999;
				AddTimePassage(chrono, passage, bib, tagID);
			end		-- du if bib ~= nil	
			
		else -- du if tonumber(CountTourActif) == 0
			-- Le CountTourActif est actif...
			-- la Loop sert a compter le Nb tour de Pena..... 
			-- a voir pour passer au Num tir superieur
			Warning("La détection viens de la Loop de comptage de tour de péna");
						RecherchetourDos(CodeTypeTable,tagID, LoopID, LoopCanal);
						--Alert("bib = "..bib)
	-- à verifier avec pierre si le bib ~= nil fonctionne bien ou si il faut mettre bib ~= ""car ds RecherchetourDos ~= nil ne fonctionne pas	
						if bib ~= nil then
							cmd = "Select * From tagID_Passings Where Code = "..RaceResult_WebRestApi.code_competition..
								  " and AdresseIP = '"..ActiveID..
								  "' and LoopID = '"..LoopID..
								  "' and LoopCanal = '"..LoopCanal..
								  "'"
								  ;
							RaceResult_WebRestApi.dbSki:TableLoad(TableTagID_Passings, cmd);
								-- Recherche du delay de double detection
							local DelayDoubleDetect = TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
							local passage = TableTagID_Passings:GetCell('passage', 0);
								--Alert("DelayDoubleDetect = "..DelayDoubleDetect);
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
									--Alert("chrono = "..chrono.." TimePassagePlus ="..TimePassagePlus)
										if 	tonumber(chrono) <= tonumber(TimePassagePlus)then
										-- si le l'heure dedetection 'chrono' est inferieur a tps + DelayDoubleDetect c'est une boucle de pena du tir actif
											local Num_Tir = RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Num_Tir", 0);
											--Alert("Num_Tir1 = "..Num_Tir);
											local NbTour_Fait = RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Tir"..Num_Tir, 0)+1;
											--Alert("NbTour_Fait = "..NbTour_Fait);
											AddNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait);
										else
										-- si le l'heure dedetection 'chrono' est superieur a tps + DelayDoubleDetect c'est une boucle de pena du tir superieur
											local Num_Tir = RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Num_Tir", 0)+1;
											--Alert("Num_Tir + 1 = "..Num_Tir);
											local NbTour_Fait = RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Tir"..Num_Tir, 0)+1;
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
		end -- du if tonumber(CountTourActif) == 0 then
		--AddTimePassage(chrono, passage, bib, tagID); --juste pour le test
		
	end -- du if tonumber(SystemeActif)
--#######  fin de la boucle pour transfert Web ou reseau
-- Je sauvegarde le Nb de passings ou trapkings lue
	SavePassingCurrent();
				
	-- ok pour la mise a jour apres le chargement d'un fichier complet
	-- Alert("	passingCurrent1 :"..RaceResult_WebRestApi.passingCurrent);
	OngetInfo();	
	return true;	
end

-- fonction pour mettre a jour le bandeau de donnée  detection lue / fichier // timer //  baterie
function OngetInfo(detectionlue)
	-- RaceResult_WebRestApi.passingCurrent = nb de detection lue
	-- RaceResult_WebRestApi.RecordsCount = nb de detection ds le fichier		
	RaceResult_WebRestApi.info:SetLabel("Timer :"..tostring(RaceResult_WebRestApi.alive)..
													" Passings : "..tostring(RaceResult_WebRestApi.passingCurrent)..
													"/"..tostring(RaceResult_WebRestApi.RecordsCount)..
													"-WebSer.")
												;			
end

-- Mise a jour du N° de fichier a lire 
function OnModifNumFile(node)
-- Création Dialog 
config = {};
node = node
	dlgNumFichier = wnd.CreateDialog({
		parent = RaceResult_WebRestApi.panel,
		icon = "./res/32x32_ffs.png",
		label = 'Numero de fichier',
		width = 500,
		height = 600
	});
	
	dlgNumFichier:LoadTemplateXML({ 
	xml = './device/raceresult.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'Numero_Fichier'
	});

	dlgNumFichier:GetWindowName('NumFichier'):SetValue(RaceResultfile);

	config.tb = dlgNumFichier:GetWindowName('tb');
	
	btn_save = config.tb:AddTool('Enregistrer', './res/16x16_xml.png');
	config.tb:AddStretchableSpace();
	btn_close = config.tb:AddTool('Quitter', './res/16x16_close.png');
	config.tb:Realize();

	function OnSaveConfig(evt)
		RaceResultfile = dlgNumFichier:GetWindowName('NumFichier'):GetValue();
		-- Alert('test : '..dlgNumFichier:GetWindowName('NumFichier'):GetValue());
		CreateURL_status(curlCommand.getSystemStatus);
-- il faudrais que je puisse enreistrer la modif dans le fichier skiffs.xml********************************* a demander a pierre

		-- node:ChangeAttribute('config_NumFichier', dlgNumFichier:GetWindowName('NumFichier'):GetValue());
		-- Alert('test2'..dlgNumFichier:GetWindowName('NumFichier'):GetValue());
		-- local doc = app.GetXML();
		-- doc:SaveFile();
		dlgNumFichier:EndModal(idButton.OK);
	end


	config.tb:Bind(eventType.MENU, OnSaveConfig, btn_save);
	config.tb:Bind(eventType.BUTTON, OnPath, dlgNumFichier:GetWindowName('path'));
	config.tb:Bind(eventType.MENU, function(evt) dlgNumFichier:EndModal(idButton.CANCEL); end, btn_close);

-- Lancement de la dialog
	dlgNumFichier:Fit();
	dlgNumFichier:ShowModal();

	-- Liberation Memoire
	dlgNumFichier:Delete();
	
	-- function OnClosedlgNumFichier(evt)
		-- dlgNumFichier:EndModal();
	-- end

end

-- Outil des Mise à jour des Tables Sql
-- Fonction permetant de vider la table tagid finish de l'evenement
function OnDeleteTagIdFinish()
	if RaceResult_WebRestApi.panel:MessageBox("Confirmation du supression des Tag_ID déjà détecter? \n\n Seul les TagID détecter par le décodeur ACTIF seront éffacer \n Attention lors de la prochaine detection \n les transpondeurs ne seront plus mis en double detection \n et les dossards deja arrivés passerons dans la colonne ancien dossard", " Supression des Tag_ID déjà détecter", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end

--recherche du nombre de ligne ds la table tag ID et afichage
	cmd = "Select * From tagID_Finish Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'";
	TabletagID_Finish = RaceResult_WebRestApi.dbSki:GetTable('tagID_Finish');
	RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Finish,cmd);
	local nbTagID_Finish = TabletagID_Finish:GetNbRows();
	--Alert("Nb de tagID Déja inscrit dans la table : "..nbTagID_Finish.." de l'Evt N°"..RaceResult_WebRestApi.code_competition.." du decodeur:"..ActiveID)

--Vidage de la table
	cmd = "Delete From tagID_Finish Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'";
	RaceResult_WebRestApi.dbSki:Query(cmd);
	
	Warning("Vidage table tagID_Finish ok...");
--recherche du nombre de ligne ds la table tag ID et afichage pour verication	
	cmd = "Select * From tagID_Finish Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'";	
	-- TabletagID_Finish = RaceResult_WebRestApi.dbSki:GetTable('tagID_Finish');
	RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Finish,cmd);
	local nbTagID_Finish = TabletagID_Finish:GetNbRows();
	Alert("Nb de tagID restant inscrit dans la table : "..nbTagID_Finish.." de l'Evt N°"..RaceResult_WebRestApi.code_competition.." du decodeur:"..ActiveID)

end

-- fonction permettant de vider la table tagID_Passings
function OnClearPassing()
--Alert("ActiveID :"..ActiveID);
	if RaceResult_WebRestApi.panel:MessageBox("Confirmation du supression des Nb de passings déjà détecter? \n\n Attention cette pération vas remetre le compteur de détection à zéro\n SKIFFS vas aller récuperer toutes les detections du décodeur ", " Remise à zéro du Nb de détection", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	Alert("Nb de detection Mis a jour : 0");
	RaceResult_WebRestApi.passingCurrent = -1;
	SavePassingCurrent();
	OngetInfo();
	
end

-- fonction de recherche du dos et du nombre de tour a faire par rapport au tagID
function RecherchetourDos(CodeTypeTable,tagID,LoopID,LoopCanal)
-- recherche du dossard par rapport au TagID ds la table tagID_Correspondance
	cmd = "Select * From tagID_Correspondance where Code = "..CodeTypeTable.." and TagID = '"..tagID.."'";
	bib = RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Correspondance, cmd):GetCellInt("Dossard", 0);
	--  Alert('RecherchetourDos bib = '..bib);
	if bib ~= "" then 
		-- Alert("bib = "..bib);
		-- Alert("RaceResult_WebRestApi.code_competition = "..RaceResult_WebRestApi.code_competition);
		-- Alert("ActiveID = "..ActiveID);
		-- Alert("LoopID = "..LoopID);
		-- Alert("LoopCanal = "..LoopCanal);
		-- on vas chercher le nombre de tour que le dos doit faire 
		cmd = "Select * From tagID_Tour Where Code = "..RaceResult_WebRestApi.code_competition..
													 " and AdresseIP = '"..ActiveID..
													 "' and LoopID = '"..LoopID..
													 "' and LoopCanal = '"..LoopCanal..
													 "'";
		-- Alert("cmd = "..cmd);											 
		TabletagID_Tour = RaceResult_WebRestApi.dbSki:GetTable('tagID_Tour');
		RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Tour, cmd);
		Testnbtour = RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows();
		-- Alert("Testnbtour = "..Testnbtour);
		for i=0, RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows()-1 do 
		bibMini = TabletagID_Tour:GetCellInt('bibMini', i);
		bibMax = TabletagID_Tour:GetCellInt('bibMax', i);
		-- Alert("bib = "..bib);
		-- Alert("bibMini = "..bibMini);
		-- Alert("bibMini = "..bibMax);
		-- Alert("i = "..i);
			if bib >= bibMini and bib <= bibMax then
				NbToursAFaire = TabletagID_Tour:GetCellInt('Tour', i);
				-- Alert("je suis dans la bonne ligne"..NbToursAFaire);
			--return ;
			end	
		end
		
		if NbToursAFaire ~= nil then else NbToursAFaire = 0 end
		-- Alert("NbToursAFaire 1 == "..NbToursAFaire.." au dos N° :"..bib)
	else 
	NbToursAFaire = 0;
	end 
end 

-- fonction qui renvoi si le count tour est actif ou pas 
function RechercheCountTourActif(CodeTypeTable,tagID, LoopID, LoopCanal);
	-- recherche du dossard par rapport au TagID ds la table tagID_Correspondance
	cmd = "Select * From tagID_Passings Where Code = "..RaceResult_WebRestApi.code_competition..
												 " and AdresseIP = '"..ActiveID..
												 "' and LoopID = '"..LoopID..
												 "' and LoopCanal = '"..LoopCanal..
												 "'";
	CountTourActif = RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Passings, cmd):GetCell("CountTourActif", 0);
	SystemeActif = RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Passings, cmd):GetCell("SystemeActif", 0);
	--Alert("CountTourActif = "..CountTourActif);
end

-- fonction qui permet de mettre a jour lr Nb tour dans la table tagID_finish
function AddNbTours(NbTours, tagID, ActiveID, LoopID, LoopCanal)
	--  Alert("AddNbtours LoopID = "..ActiveID);
	local cmd = 
		"Update tagID_Finish SET Tour = "..NbTours..
		" Where Code = "..RaceResult_WebRestApi.code_competition..
		" and AdresseIP = '"..ActiveID..
		"' and LoopID = '"..LoopID..
		"' and LoopCanal = '"..LoopCanal..
		"' and TagID = '"..tagID..
		"'"
	RaceResult_WebRestApi.dbSki:Query(cmd);
	Success("mise a jour du nb tour au tagID ="..tagID.. " dans la TabletagID_TourPena Donc :"..NbTours);
end

-- fonction qui insert un tour de pena dans la table tagid pena
function InsertNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait)
	 --Alert("Num_Tir = "..Num_Tir);	
 local r = TabletagID_TourPena:AddRow();				
				TabletagID_TourPena:SetCell("Code", r, tonumber(RaceResult_WebRestApi.code_competition));
				TabletagID_TourPena:SetCell("AdresseIP", r, ActiveID);
				TabletagID_TourPena:SetCell("LoopID", r, LoopID);
				TabletagID_TourPena:SetCell("LoopCanal", r, LoopCanal);
				TabletagID_TourPena:SetCell("Dossard", r, bib);
				TabletagID_TourPena:SetCell("Tir1", r, tonumber(NbTour_Fait));	
				TabletagID_TourPena:SetCell("Tir2", r, 0);
				TabletagID_TourPena:SetCell("Tir3", r, 0);
				TabletagID_TourPena:SetCell("Tir4", r, 0);
				TabletagID_TourPena:SetCell("Num_Tir", r, tonumber(Num_Tir));
				RaceResult_WebRestApi.dbSki:TableInsert(TabletagID_TourPena, r);
		Success("Ajout dos ="..bib.. " dans la TabletagID_TourPena");	
end

-- fonction qui ajoute un tour de pena dans la table tagidpena
function AddNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait)
	--Alert("AddNbtours_pena Num_Tir = "..Num_Tir);
	--Alert("AddNbtours LoopID = "..NbTour_Fait);
	
	local cmd = 
		"Update tagID_TourPena SET Tir"..Num_Tir.." = "..NbTour_Fait..
		", Num_Tir = "..Num_Tir..
		" Where Code = "..RaceResult_WebRestApi.code_competition..
		" and AdresseIP = '"..ActiveID..
		"' and LoopID = '"..LoopID..
		"' and LoopCanal = '"..LoopCanal..
		"' and Dossard = '"..bib..
		"' "
		;
	RaceResult_WebRestApi.dbSki:Query(cmd);
	Success("Ajout d\' 1 tour de Pénalité au dos ="..bib.. " dans la TabletagID_TourPena Donc :"..NbTour_Fait);		
end

-- insert un dos dans la table tagIDfinish
function AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib)
-- ecriture du TagID dans la table tagID_Finish
				local r = TableTagID_Finish:AddRow();				
				TableTagID_Finish:SetCell("Code", r, RaceResult_WebRestApi.code_competition);
				TableTagID_Finish:SetCell("AdresseIP", r, ActiveID);
				TableTagID_Finish:SetCell("LoopID", r, LoopID);
				TableTagID_Finish:SetCell("LoopCanal", r, LoopCanal);
				TableTagID_Finish:SetCell("TagID", r, tagID);		
				TableTagID_Finish:SetCell("Passage", r, passage);
				TableTagID_Finish:SetCell("Tour", r, Tour);
				RaceResult_WebRestApi.dbSki:TableInsert(TableTagID_Finish, r);
	Success("Ajout dos ="..bib.. " dans la TableTagID_Finish");	

end
					
function GetHeurePassage(dossard, passage)
	local cmd =
		" select * From Resultat_Chrono where Code_evenement = "..RaceResult_WebRestApi.code_competition..
		" And Code_manche = "..RaceResult_WebRestApi.code_manche..
		" And Id = "..passage..
		" And Dossard = "..dossard
	;
	tResultatChrono = RaceResult_WebRestApi.dbSki:GetTable('Resultat_Chrono');
	RaceResult_WebRestApi.dbSki:TableLoad(tResultatChrono, cmd);
	--Alert('RaceResult_WebRestApi.code_competition = '..RaceResult_WebRestApi.code_competition);
	--Alert('RaceResult_WebRestApi.code_manche = '..RaceResult_WebRestApi.code_manche);
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
		" select * From Resultat_Manche where Code_evenement = "..RaceResult_WebRestApi.code_competition..
		" And Code_coureur = '"..Code_coureur..
		"'"
	;
	tResultat_Manche = RaceResult_WebRestApi.dbSki:GetTable('Resultat_Manche');
	RaceResult_WebRestApi.dbSki:TableLoad(tResultat_Manche, cmd);
	--Alert('RaceResult_WebRestApi.code_competition = '..RaceResult_WebRestApi.code_competition);
	--Alert('RaceResult_WebRestApi.code_manche = '..RaceResult_WebRestApi.code_manche);
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
		" select * From Resultat where Code_evenement = "..RaceResult_WebRestApi.code_competition..
		" And Dossard = "..dossard
	;
	tResultat = RaceResult_WebRestApi.dbSki:GetTable('Resultat');
	RaceResult_WebRestApi.dbSki:TableLoad(tResultat, cmd);
	--Alert('RaceResult_WebRestApi.code_competition = '..RaceResult_WebRestApi.code_competition);
	--Alert('RaceResult_WebRestApi.code_manche = '..RaceResult_WebRestApi.code_manche);
	--Alert('idPassage = '..passage);
	--Alert('dossard = '..dossard);
	
	if tResultat == nil then return -1 end
	if tResultat:GetNbRows() == 0 then return -1 end
	Alert('GetCodecoureur = '..tResultat:GetCell('Code_coureur',0));
	-- Heure de passage existe ...	
	return tResultat:GetCell('Code_coureur',0);
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
		RaceResult_WebRestApi.dbSki:TableFlush(TabletagID_Tour, r);
		--RaceResult_WebRestApi.dbSki:TableFlush(TabletagID_Tour, r); permet un TableInsert et si la ligne existe elle met a jour
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
	TabletagID_Passings:SetCell("SystemeActif", r, tonumber(SystemeActif));
	RaceResult_WebRestApi.dbSki:TableFlush(TabletagID_Passings, r);
end

-- mise a jour du N° de passage lors d'une détection
function refreshTagIDFinish(tagID, passage, LoopID, LoopCanal)
	local cmd = 
			"update tagID_Finish SET Passage = '"..passage..
		" 'Where Code = "..RaceResult_WebRestApi.code_competition..
		" And AdresseIP = '"..ActiveID..
		"' And LoopID = '"..LoopID..   
		"' And LoopCanal = '"..LoopCanal.. 
		"' And tagID = '"..tagID..
		"' "
		;
	RaceResult_WebRestApi.dbSki:Query(cmd);
	Success("Mise a jour du N° de passage :"..passage.." du TagID ="..tagID.. " dans la TableTagID_Finish");
	
end

-- ***  gestion de la fenetre option
-- fonction de sauvegarde de la grille option		
function OnSaveOption(evt)

	cmd = "Delete From tagID_Tour Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'";
	RaceResult_WebRestApi.dbSki:Query(cmd);
	local grid_Ligne = dlgOptionTable:GetWindowName('grid_Option');
	
	local Grid_Ligne = grid_Ligne:GetTable();
	--Alert("RaceresultWebServeur_option:GetNbRows() = "..Grid_Ligne:GetNbRows());
	for i=0, Grid_Ligne:GetNbRows()-1 do
			--enregistrement de la grid option dans la table TabletagID_Tour			
			local Code = Grid_Ligne:GetCellInt('Code', i);
			local AdresseIP = Grid_Ligne:GetCell('AdresseIP', i);
			local bibMini = tonumber(Grid_Ligne:GetCell('bibMini', i));		
			local bibMax = tonumber(Grid_Ligne:GetCell('bibMax', i));
			local LoopID = Grid_Ligne:GetCell('LoopID', i);
			local LoopCanal = Grid_Ligne:GetCell('LoopCanal', i);
			--local passage = Grid_Ligne:GetCellInt('passage', i);
			local Tour = Grid_Ligne:GetCellInt('Tour', i);
		-- Alert("RaceresultWebServeur_option:GetNbRows() = "..Grid_Ligne:GetCell('LoopID', i));
		AddTabletagID_Tour(Code,AdresseIP,bibMini,bibMax,LoopID,LoopCanal,Tour);
		
	end
		Alert("Sauvegarde des lignes ds tagID_Tour éffectuer correctement");
	
	cmd = "Delete From tagID_Passings Where Code = "..RaceResult_WebRestApi.code_competition.." and AdresseIP = '"..ActiveID.."'";
	RaceResult_WebRestApi.dbSki:Query(cmd);
	local grid_Param = dlgOptionTable:GetWindowName('grid_Param');
	local Grid_Param = grid_Param:GetTable();
	-- Alert("RaceresultWebServeur_option:GetNbRows() = "..Grid_Param:GetNbRows());
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

-- Insertion d'une Option
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

-- Suppression d'une Loop
function OnRemoveLoop(evt)
	local grid_Param = dlgOptionTable:GetWindowName('grid_Param');
	local row = grid_Param:GetGridCursorRow();
	if row >= 0 then
		grid_Param:DeleteRows(row);
	end	
end

-- creation de la fenetre options
function OnOpenOptions(evt)
-- Création Dialog 

	dlgOptionTable = wnd.CreateDialog({
		parent = RaceResult_WebRestApi.panel,
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
	
	RaceresultWebServeur_option = {};
	RaceresultWebServeur_param = {};
	RaceresultWebServeur_Exit = {};
	
	function OnClosedlgOptionTable(evt)
	dlgOptionTable:EndModal();
	end
	
	
-- Grid Options
	cmd = "Select * From tagID_Tour Where Code = '"..RaceResult_WebRestApi.code_competition.."' and AdresseIP = '"..ActiveID.."' Order by bibMini";
	RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Tour, cmd)
	
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
	RaceresultWebServeur_option.tb = dlgOptionTable:GetWindowName('tb_option');
	RaceresultWebServeurTb_InsertTrDos = RaceresultWebServeur_option.tb:AddTool("Ajouter une Ligne", "./res/32x32_list_add.png");
	RaceresultWebServeur_option.tb:AddStretchableSpace();
	RaceresultWebServeurTb_RemoveTrDos = RaceresultWebServeur_option.tb:AddTool("Supprimer une Ligne", "./res/32x32_list_remove.png");
	RaceresultWebServeur_option.tb:Realize();
-- Grid Parametre

	cmd = "Select * From tagID_Passings Where Code = '"..RaceResult_WebRestApi.code_competition.."' and AdresseIP = '"..ActiveID.."' Order by Code, LoopID, LoopCanal";
	RaceResult_WebRestApi.dbSki:TableLoad(TabletagID_Passings, cmd)
	
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
		columns = 'Code, AdresseIP, Port, LoopID, LoopCanal, passage, ID_1er_Inter, Passings, TypeTable, DelayDoubleDetect, CountTourActif, SystemeActif',
		selection_mode = gridSelectionModes.CELLS,
		sortable = false,
		enable_editing = true
	});
	
	grid:SetColAttr('CountTourActif', { kind = 'bool', value_true = '1' });
	grid:SetColAttr('SystemeActif', { kind = 'bool', value_true = '1' });

-- Initialisation des Controles
		
	-- ToolBar PARAM
	RaceresultWebServeur_param.tb = dlgOptionTable:GetWindowName('tb_param');
	RaceresultWebServeurTb_InsertLoop = RaceresultWebServeur_param.tb:AddTool("Dupliquer une Ligne", "./res/32x32_list_add.png");
	RaceresultWebServeur_param.tb:AddStretchableSpace();
	RaceresultWebServeurTb_RemoveLoop = RaceresultWebServeur_param.tb:AddTool("Suprimer une Ligne", "./res/32x32_list_remove.png");
	RaceresultWebServeur_param.tb:Realize();
	
	-- ToolBar exit
	RaceresultWebServeur_Exit.tb = dlgOptionTable:GetWindowName('tb');
	RaceresultWebServeurTb_Save = RaceresultWebServeur_Exit.tb:AddTool("Enregistrer", "./res/32x32_save.png");
	RaceresultWebServeur_Exit.tb:AddStretchableSpace();
	RaceresultWebServeurTb_Exit = RaceresultWebServeur_Exit.tb:AddTool("Quitter", "./res/32x32_exit.png");
	RaceresultWebServeur_Exit.tb:Realize();
	
	-- Prise des Evenements (Bind)
	dlgOptionTable:Bind(eventType.MENU, OnInsertTrDos, RaceresultWebServeurTb_InsertTrDos);
	dlgOptionTable:Bind(eventType.MENU, OnRemoveTrDos, RaceresultWebServeurTb_RemoveTrDos);
	dlgOptionTable:Bind(eventType.MENU, OnInsertLoop, RaceresultWebServeurTb_InsertLoop);
	dlgOptionTable:Bind(eventType.MENU, OnRemoveLoop, RaceresultWebServeurTb_RemoveLoop);
	dlgOptionTable:Bind(eventType.MENU, OnSaveOption, RaceresultWebServeurTb_Save);
	dlgOptionTable:Bind(eventType.MENU, OnClosedlgOptionTable, RaceresultWebServeurTb_Exit);
	
	-- permet de verifier et fixer les choses avt le showmodal (à faire obligatoirement)
	dlgOptionTable:Fit();

	-- Affichage Modal
	dlgOptionTable:ShowModal();
		
end

-- *** fonction utilitaire pour les decodeurs

-- fonction pour envoyer l' URL pour connaitre le mode chrono du decodeur actif
function OnReadModeChrono()
	CreateURL_status(curlCommand.getModeChrono)
end

-- fonction lisant le status du decodeur pour savoir le mode chrono
function ReadModeChrono(evt)
-- Lecture du JSON get status
	local jsonText = evt:GetString();
	-- Alert("jsonText ReadModeChrono ="..jsonText);
	if jsonText:len() > 3 then
		-- adv.Success('JSON Return='..jsonText);
		local jsonText = table.FromStringJSON(jsonText);
		local Devices = #jsonText.Devices;
		
		for i=1,Devices do
			RaceResult_WebRestApi.ModeChrono =	tostring(jsonText.Devices[i][RaceResulStatus].IsInTimingMode) -- tostring(jsonText.Devices[i][RaceResulStatus].IsInTimingMode)   ;
		end
		--Alert('ModeChrono = '..RaceResult_WebRestApi.ModeChrono);
		
		if RaceResult_WebRestApi.ModeChrono == 'true' then
			Success(' => Mode Chrono: Actif');
		else
			Alert(' => Mode Chrono: Standby');
		end
		
	else
		adv.Alert('Le décodeur n\'est pas Connecter');
	end
	
	if RaceResult_WebRestApi.timerStartOperation ~= nil then
		RaceResult_WebRestApi.timerStartOperation:Delete();
		RaceResult_WebRestApi.timerStartOperation = nil;
	end
	
	if RaceResult_WebRestApi.timerStopOperation ~= nil then
		RaceResult_WebRestApi.timerStopOperation:Delete();
		RaceResult_WebRestApi.timerStopOperation = nil;
	end
end

--Fonction permetant de d'activé les antennes
function OnStartOperation()
-- https://rest.devices.raceresult.com/customers/19974/devices/D-5310/cmd?command=startoperation
	if RaceResult_WebRestApi.access_token == false then
		OnCreateJeton()
	end
	
	if RaceResult_WebRestApi.ModeChrono ~= 'true' then
		local url = device.url_rest..
						'customers/'..RaceResultuser..
						'/devices/'..ActiveID..
						'/cmd?command=STARTOPERATION'
						;
		if url ~= nil then
			-- Pas besoin de faire en asynchrone car pas de réponse demander c'est juste une commande d'envoyer la confirmation est demander par la fonction OnReadModeChrono lancer par le timer
			curl.POST(url, url, RaceResult_WebRestApi.access_token);
			-- curl.AsyncPOST(panel, url, curlCommand.OnActiveChrono, RaceResult_WebRestApi.access_token);
			-- Alert("test url OnStartOperation ="..url);
		end
		Alert("demande d'activation des antennes de détection")
		-- creation du timer pour lire le status et savoir si le mode chrono c'est bien activé
		RaceResult_WebRestApi.timerStartOperation = timer.Create(RaceResult_WebRestApi.panel);
		if RaceResult_WebRestApi.timerStartOperation ~= nil then
			RaceResult_WebRestApi.timerStartOperation:Start(RaceResult_WebRestApi.timerDelayConnect);
		end
		-- Timer pour la fonction OnReadModeChrono
		RaceResult_WebRestApi.panel:Bind(eventType.TIMER, OnReadModeChrono, RaceResult_WebRestApi.timerStartOperation);	
		--Alert("Décodeur OffLine ="..Status);
	else
		Alert("Antenne du décodeur déja Active")
	end
end

--Fonction permetant de désactiver les antennes
function OnStopOperation()
	if RaceResult_WebRestApi.access_token == false then
		OnCreateJeton()
	end
	
	if RaceResult_WebRestApi.ModeChrono ~= 'false' then
		local url = device.url_rest..
						'customers/'..RaceResultuser..
						'/devices/'..ActiveID..
						'/cmd?command=STOPOPERATION'
						;
		if url ~= nil then
			-- Pas besoin de faire en asynchrone car pas de réponse demander c'est juste une commande d'envoyer la confirmation est demander par la fonction OnReadModeChrono lancer par le timer
			curl.POST(url, url, RaceResult_WebRestApi.access_token);
			-- curl.AsyncPOST(panel, url, curlCommand.OnActiveChrono, RaceResult_WebRestApi.access_token);
			-- Alert("test url STOPOPERATION ="..url);
		end
		Alert("demande de mise en veille des antennes de détection");

		RaceResult_WebRestApi.timerStopOperation = timer.Create(RaceResult_WebRestApi.panel);
		if RaceResult_WebRestApi.timerStopOperation ~= nil then
			RaceResult_WebRestApi.timerStopOperation:Start(RaceResult_WebRestApi.timerDelayConnect);
		end
		-- Timer pour la fonction OnReadModeChrono
		RaceResult_WebRestApi.panel:Bind(eventType.TIMER, OnReadModeChrono, RaceResult_WebRestApi.timerStopOperation);	
		--Alert("Décodeur OffLine ="..Status);
	else
	Alert("Antenne du déodeur déja Désactivée")
	end
end

function OnStartGPS()
-- https://rest.devices.raceresult.com/customers/19974/devices/D-5310/cmd?command=startoperation
	if RaceResult_WebRestApi.access_token == false then
		OnCreateJeton()
	end
	
	if RaceResult_WebRestApi.ModeChrono ~= 'true' then
		local url = device.url_rest..
						'customers/'..RaceResultuser..
						'/devices/'..ActiveID..
						'/cmd?command=SETGPSTIME'
						;
		if url ~= nil then
			-- Pas besoin de faire en asynchrone car pas de réponse demander c'est juste une commande d'envoyer la confirmation est demander par la fonction OnReadModeChrono lancer par le timer
			curl.POST(url, url, RaceResult_WebRestApi.access_token);
			-- curl.AsyncPOST(panel, url, curlCommand.OnActiveChrono, RaceResult_WebRestApi.access_token);
			-- Alert("test url OnStartGPS ="..url);
		end
		
		Alert("demande d'activation du GPS envoyé...")
		
	else
		Alert("Le chronometrage est Actif impossible de synchro avec le GPS...")
	end
	
			RaceResult_WebRestApi.TimerStartGPS = timer.Create(RaceResult_WebRestApi.panel);
		if RaceResult_WebRestApi.TimerStartGPS ~= nil then
			RaceResult_WebRestApi.TimerStartGPS:Start(RaceResult_WebRestApi.timerDelayConnect);
		end
		-- Timer pour la fonction OnReadSetGpsTime
		RaceResult_WebRestApi.panel:Bind(eventType.TIMER, OnReadSetGpsTime, TimerStartGPS);	
		--Alert("Décodeur OffLine ="..Status);
		
end

function OnReadSetGpsTime()
	CreateURL_status(curlCommand.GetGPS_Time)
end

-- fonction lisant le status du decodeur pour savoir le mode chrono
function ReadGPS_Time(evt)
-- Lecture du JSON get status
	local jsonText = evt:GetString();
	-- Alert("jsonText ReadModeChrono ="..jsonText);
	if jsonText:len() > 3 then
		-- adv.Success('JSON Return='..jsonText);
		local jsonText = table.FromStringJSON(jsonText);
		local Devices = #jsonText.Devices;
		
		for i=1,Devices do
			TimeSource = tostring(jsonText.Devices[i][RaceResulStatus].TimeSource);
		end
		-- Alert('TimeSource = '..TimeSource);
	else
		adv.Alert('Le décodeur n\'est pas Connecter');
	end
	
	if TimeSource == '0' then
		Alert(' => Time Chrono: Manuel');
	elseif TimeSource == '1' then
		Success(' => GPS: Actif');
	elseif TimeSource == '2' then
		Alert(' => GPS: Actif (Mais aproximatif car mauvaise réception satelite');
	else
		Alert(' => Time Chrono: Non définis');
	end
	
	if RaceResult_WebRestApi.TimerStartGPS ~= nil then
		RaceResult_WebRestApi.TimerStartGPS:Delete();
		RaceResult_WebRestApi.TimerStartGPS = nil;
	end
	
end

-- Opération à faire lors de la fermeture du device
function device.OnClose()

	RaceResult_WebRestApi.Stop = true;

	if RaceResult_WebRestApi.panel ~= nil then
		-- On Ignore les "event" qui peuvent encore être dans la pile ...
		RaceResult_WebRestApi.panel:UnbindAll();
	end
-- delate timerConnect
	if RaceResult_WebRestApi.timerConnect ~= nil then
		RaceResult_WebRestApi.timerConnect:Delete();
		RaceResult_WebRestApi.timerConnect = nil;
	end
-- delate timerChrono
	if RaceResult_WebRestApi.timerChrono ~= nil then
		RaceResult_WebRestApi.timerChrono:Delete();
		RaceResult_WebRestApi.timerChrono = nil;
	end
-- delate timerJeton
	if RaceResult_WebRestApi.timerJeton ~= nil then
		RaceResult_WebRestApi.timerJeton:Delete();
		RaceResult_WebRestApi.timerJeton = nil;
	end
-- delate TimerStartOperation
	if RaceResult_WebRestApi.timerStartOperation ~= nil then
		RaceResult_WebRestApi.timerStartOperation:Delete();
		RaceResult_WebRestApi.timerStartOperation = nil;
	end
	
-- delate timerStopOperation
	if RaceResult_WebRestApi.timerStopOperation ~= nil then
		RaceResult_WebRestApi.timerStopOperation:Delete();
		RaceResult_WebRestApi.timerStopOperation = nil;
	end	
-- delate watchDogConnect	
	if RaceResult_WebRestApi.watchDogConnect ~= nil then
		RaceResult_WebRestApi.watchDogConnect:Delete();
	end

-- fonction permetant le fonctionnement de l'activation ou de la desactivation des devices ds la fenetre chrono
	local mgr = app.GetAuiManager();
	mgr:DeletePane(RaceResult_WebRestApi.panel);

-- Appel OnClose Metatable
	mt_device.OnClose();

end

-- end