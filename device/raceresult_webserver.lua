-- RaceresultWebServeur gere systeme Actif et Passif 
-- connection internet obligatoire pour se connecter au serveur race result
-- systeme Actif gestion de 8 N° de Loop  et 8 N° de canal sur un memes decodeur 
-- Gestion du comptage de nombre de tour de pena si on active le couttourpena sur une boucle
-- aller dans gestion des options
-- Gestion de table de corespondance Généric a tt les évènements ou gestion de table propre à l'évènement traiter
-- dans les deux cas la mm table sert a plusieurs décodeur sur le memes EVT
-- version asychrone ******************* pas de blocage de skiffs si mauvaise connection

-- dofile('./interface/interface.lua');
-- dofile('./interface/adv.lua');
dofile('./interface/device.lua');
-- LIVE Timing Asynsynchrone 
dofile('./interface/include.lua');
dofile('./process/dbSki.lua');

--dofile('./device/raceresult_fonctions.lua');
-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 7.3,
			 code = 'raceresult_webserver', 
			 name = 'Raceresult Web-Serveur', 
			class = 'chrono'
			--interface = { { type='tcp', hostname = 'D-5314', port = 3601 } } 
			};
end	

--Creation de la table
RaceresultWebServeur = {}

function Alert(txt)
	RaceresultWebServeur.gridMessage:AddLine(txt);
end

function Success(txt)
	RaceresultWebServeur.gridMessage:AddLineSuccess(txt);
end

function Warning(txt)
	RaceresultWebServeur.gridMessage:AddLineWarning(txt);
end

function Error(txt)
	RaceresultWebServeur.gridMessage:AddLineError(txt);
end

-- delay Timer connect
RaceresultWebServeur.timerDelayConnect = 20000;

-- delay timer apres stert ou teop opération
RaceresultWebServeur.timerDelayStartOperation = 10000;

-- delay timer lecture
RaceresultWebServeur.timerDelay = 5000;

-- variable pour le count du timer
RaceresultWebServeur.alive = 0;

-- Actif ou pas
RaceresultWebServeur.ActiveStart = "Non Actif";

-- nb de lignes 
nbLignes = 0;

-- Nb de tour
NbTourRealiser = 0;

--delai double detection
DelayDoubleDetect = 1000;

function device.OnInit(params, node)

--	adv.Alert("On OnInit..");

	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	theParams = params;
	node = node;
	
	-- Création des variables pour la gestion en récupérant les valeurs dans config
	-- device.url = 'https://data.raceresult.com/interface/passings/v6';
	device.url = node:GetAttribute('config_AdrServeurRaceResult');
-- N° de prot si liaison ethernet
	RaceResultdevice = node:GetAttribute('config_IdDecodeur'); --steph D-5314  NEW LINES D-50582
	RaceResultPort = node:GetAttribute('config_PortDecodeur');
	RaceResultuser = node:GetAttribute('config_User');
	RaceResultpw = node:GetAttribute('config_PWD');
	RaceResultfile = node:GetAttribute('config_NumFichier');  --171 comtien des detections
	passage = node:GetAttribute('config_Passage');  -- N° de passage 0 depart, -1 arrivée, 1..2..3 N° inter
	
	--RaceResultservertime=[servertime]  falcultatif
	RaceResulttype = 'rrfile';--rrfile ou rronline il n'y a pas l'ID du decodeur
	-- declaration de variable complementaire pour la creation de l'URL getSystemStatus
	RaceResultformat = 'text';
	RaceResultshowlaststatus = 'false';
	-- device.url = 'https://data.raceresult.com/interface/passings/v6/getSystemPassings.php?user=19974&pw=mast15lath73@&device=D-50582&file=40&minid=1&type=rrfile&limit=0
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
	RaceresultWebServeur.dbSki = sqlBase.Clone();
	TabletagID_Passings = RaceresultWebServeur.dbSki:GetTable('tagID_Passings');
	TabletagID_Correspondance = RaceresultWebServeur.dbSki:GetTable('tagID_Correspondance');
	TableTagID_Finish = RaceresultWebServeur.dbSki:GetTable('tagID_Finish');
	TabletagID_Tour = RaceresultWebServeur.dbSki:GetTable('tagID_Tour');
	TabletagID_TourPena = RaceresultWebServeur.dbSki:GetTable('tagID_TourPena');
	
	RaceresultWebServeur.panel = panel; 
		
-- Initialisation des Controles 
	RaceresultWebServeur.gridMessage = panel:GetWindowName('message');
	
-- ToolBar
	RaceresultWebServeur.tb = panel:GetWindowName('tb');
	RaceresultWebServeur.tb_start = RaceresultWebServeur.tb:AddTool("Start", "./res/32x32_chrono_v3.png");
	RaceresultWebServeur.tb:AddSeparator();
	RaceresultWebServeur.tb_OnChargeTableCorres = RaceresultWebServeur.tb:AddTool("Import table corespondance", "./res/32x32_divide_column.png");
	RaceresultWebServeur.tb:AddSeparator();
	RaceresultWebServeur.tb_Param = RaceresultWebServeur.tb:AddTool("Paramétrage", "./res/32x32_config.png", "Paramétrage plage dossards relais",  itemKind.DROPDOWN);
	RaceresultWebServeur.tb:AddSeparator();
	
-- Sous menu parametre	
	local menuSend =  menu.Create();
	menuSend:AppendSeparator();	
	RaceresultWebServeur.tb_Param_Options = menuSend:Append({label="Configuration des options (Nb Tour / Passage) ", image ="./res/32x32_options.png"});
	menuSend:AppendSeparator();	
	RaceresultWebServeur.tb_Param_TagIdFinish = menuSend:Append({label="Vider la Table tagID_Finish ", image ="./res/32x32_background.png"});
	menuSend:AppendSeparator();
	RaceresultWebServeur.tb_Param_Passing = menuSend:Append({label="Mise a zéro du compteur passing", image ="./res/32x32_update.png"});
	menuSend:AppendSeparator();
	RaceresultWebServeur.tb_Chargement_Passing = menuSend:Append({label="Chargement d'un fichier Décodeur OFFLINE", image ="./res/32x32_update.png"});
	menuSend:AppendSeparator();
	RaceresultWebServeur.tb_Param_Socket = menuSend:Append({label="Réinitialisation de la connection au décodeur", image ="./res/32x32_postition_horizontal.png"});
	menuSend:AppendSeparator();
	RaceresultWebServeur.tb_Param_Mode = menuSend:Append({label="Recherche du mode Mode Chrono du décodeur", image ="./res/32x32_postition_horizontal.png"});
	menuSend:AppendSeparator();
	RaceresultWebServeur.tb_Param_StartAnt = menuSend:Append({label="Activé les antennes de détection", image ="./res/32x32_antenna.png"});
	menuSend:AppendSeparator();
	RaceresultWebServeur.tb_Param_stopAnt = menuSend:Append({label="désactiver les antennes de détection", image ="./res/32x32_stop.png"});
	menuSend:AppendSeparator();
	RaceresultWebServeur.tb_Param_Web = menuSend:Append({label="Modification du numero de fichier", image ="./res/32x32_configure.png"});
	RaceresultWebServeur.tb:SetDropdownMenu(RaceresultWebServeur.tb_Param:GetId(), menuSend);
		
-- Static Connect
	RaceresultWebServeur.Connect = wnd.CreateStaticText({parent = RaceresultWebServeur.tb, label = "Test Connect", style = wndStyle.ALIGN_LEFT});
	RaceresultWebServeur.Connect:SetLabel("Non Connect");
	RaceresultWebServeur.tb:AddControl(RaceresultWebServeur.Connect);
	RaceresultWebServeur.tb:AddSeparator();	
	
-- Static Info
	RaceresultWebServeur.info = wnd.CreateStaticText({parent = RaceresultWebServeur.tb, label = "Timer : ------  Passings : ----F/----D", style = wndStyle.ALIGN_LEFT});
	RaceresultWebServeur.tb:AddControl(RaceresultWebServeur.info);
	RaceresultWebServeur.tb:AddSeparator();	

-- Niveau de Batterie
	RaceresultWebServeur.battery = wnd.CreateStaticText({parent = RaceresultWebServeur.tb, label = "Charge Bat =---%", style = wndStyle.ALIGN_LEFT});
	RaceresultWebServeur.tb:AddControl(RaceresultWebServeur.battery);
	RaceresultWebServeur.tb:Realize();

-- Prise des Evenements (Bind)onglet principal
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnStartRaceresultWebServeur, RaceresultWebServeur.tb_start);
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnOpenTableCorespondance, RaceresultWebServeur.tb_OnChargeTableCorres);
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnParamko, RaceresultWebServeur.tb_Param);

-- onglet du sous menu outil 
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnOpenOptions, RaceresultWebServeur.tb_Param_Options);
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnDeleteTagIdFinish, RaceresultWebServeur.tb_Param_TagIdFinish);
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnClearPassing, RaceresultWebServeur.tb_Param_Passing);
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnRechargeFichierOffLine, RaceresultWebServeur.tb_Chargement_Passing);
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnReOpenSocket, RaceresultWebServeur.tb_Param_Socket);
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnReadModeChrono, RaceresultWebServeur.tb_Param_Mode);
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnStartOperation, RaceresultWebServeur.tb_Param_StartAnt);
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnStopOperation, RaceresultWebServeur.tb_Param_stopAnt);
	RaceresultWebServeur.panel:Bind(eventType.MENU, OnModifNumFile, RaceresultWebServeur.tb_Param_Web);
	
	
		
-- Chargement des Informations de la Course ...
	RaceresultWebServeur.code_competition = -1;
	local rc, raceInfo = app.SendNotify('<race_load>');
	if rc == true then
		local tEvenement = raceInfo.tables.Evenement;
		RaceresultWebServeur.code_competition = tEvenement:GetCellInt('Code', 0);
		RaceresultWebServeur.code_manche = raceInfo.Code_manche or 1 ;
		Success("Compétition "..tostring(RaceresultWebServeur.code_competition)..' ok ..');
	end
	
-- Recherche si un evenement existe dans la table tagID_Passings OK
	cmd = "Select * From tagID_Passings Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'";
	TableTagID_Passings = RaceresultWebServeur.dbSki:GetTable('tagID_Passings');
	RaceresultWebServeur.dbSki:TableLoad(TableTagID_Passings, cmd);	
	
	TypeTable = "ND";
	if TableTagID_Passings:GetNbRows() == 0 then
		Alert("pas d'évènement Dans la table tagID_Passings on la créer");
-- creation de la variable Passing Current (nb de transpondeur detecter dans la ligne chrono)		
	RaceresultWebServeur.passingCurrent = 0;
	
-- creation de variables TypeTable et CodeTypeTable(permetant de travailler une table générique a tt les evt ou une table spécifique à l'EVT)
	-- if passage == '' then passage = -1	end
	-- Alert("RaceResultdevice : "..RaceResultdevice);
	LoopID = 'Loop0';
	LoopCanal = 'LoopCanal0';	
	ID_1er_Inter = 1;
	SystemeActif = node:GetAttribute('checkbox_config_Systeme');
	CountTourActif = 0;
	CodeTypeTable = RaceresultWebServeur.code_competition;
--delai double detection
	DelayDoubleDetect = 600000;  -- = à 10 minutes   ///  60000 = à 1 min
	
-- ecriture des parametres dans la tagID_Passings et du type table
	AddTabletagID_Passings(RaceresultWebServeur.code_competition,ActiveID,ActivePort,LoopID,LoopCanal,passage,ID_1er_Inter,RaceresultWebServeur.passingCurrent,TypeTable,DelayDoubleDetect,CountTourActif,SystemeActif);		
		Warning("pas de table de corespondace pour cet évènement ...");
		Warning("Penser à aller dans l'onglet gestion pour importer une table avant de chronometrer...");
	else
-- si il y a une ligne dans tagID_Passings On prend les valeurs de la table pour renseigner les variables 
		RaceresultWebServeur.passingCurrent = TableTagID_Passings:GetCellInt('Passings', 0);
		--Alert("RaceresultWebServeur.passingCurrent ="..RaceresultWebServeur.passingCurrent);
		TypeTable = TableTagID_Passings:GetCell('TypeTable', 0);
		passage = TableTagID_Passings:GetCell('passage', 0);
		SystemeActif = TableTagID_Passings:GetCell('SystemeActif', 0);
		ID_1er_Inter = TableTagID_Passings:GetCell('ID_1er_Inter', 0);
		-- DelayDoubleDetect = TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
		--Alert("RaceresultWebServeur.passingCurrent ="..RaceresultWebServeur.passingCurrent.."/ TypeTable :"..TypeTable);
			if TypeTable == 'GEN' then
				CodeTypeTable = 0;
			else
				CodeTypeTable = RaceresultWebServeur.code_competition ;
			end
	end
	
	
	-- On recherche si il y a une ou plusieurs lignes de créer ds la table TabletagID_Tour pour l'evt
	-- Si pas de ligne on inscrit dans latable	
	cmd = "Select * From tagID_Tour Where Code = '"..RaceresultWebServeur.code_competition.."' and AdresseIP = '"..ActiveID.."' Order by bibMini";
	if RaceresultWebServeur.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows() == 0 then
		local bibMini = 1;
		local bibMax = 9999;
		local LoopID = 'Loop0';
		local LoopCanal = 'LoopCanal0';
		--local passage = node:GetAttribute('config_Passage');
		local Tour = 0;
		AddTabletagID_Tour(RaceresultWebServeur.code_competition,ActiveID,bibMini,bibMax,LoopID,LoopCanal,Tour);
	end
-- Recherche si une table de corespondance existe dans la table tagID_Correspondance
	cmd = "Select * From tagID_Correspondance Where Code = "..CodeTypeTable.." Order by Dossard";
	if RaceresultWebServeur.dbSki:TableLoad(TabletagID_Correspondance, cmd):GetNbRows() == 0 then
		Alert("pas de Table de correspondance pour cet évènement : "..RaceresultWebServeur.code_competition);
	else
	-- Alert("TypeTable ="..TypeTable);
		if TypeTable == 'GEN' then
			Alert("Utilisation de la table Générique pour l'EVT  : "..RaceresultWebServeur.code_competition.." avec "..TabletagID_Correspondance:GetNbRows().." lignes créées");
		elseif TypeTable == 'EVT' then
			Alert("Utilisation de la table spécifique à l'évènement N°: "..RaceresultWebServeur.code_competition.." avec "..TabletagID_Correspondance:GetNbRows().." lignes créées");
		else
			Alert("pas de table de corespondance pour l'EVT  : "..RaceresultWebServeur.code_competition);
		end	
	end
			
-- creation de la variables PassingCount (nb de transpondeur detecter par la ligne chrono)
		RaceresultWebServeur.passingCount = 0;
		--Alert("passingCurrent :"..RaceresultWebServeur.passingCurrent.."/ "..RaceresultWebServeur.passingCount);

-- Affichage ...
	panel:Show(true);
	
	local mgr = app.GetAuiManager();
	
	local caption = '/ '..ActiveID;
	
	mgr:AddPane(panel, {
		icon = './res/Mini-logo-raceresult.png',
		caption = "Race_Result_WebServeur / "..ActiveID,
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
		getSystemPassings = 2,
		getModeChrono = 3,
		getNbPassings = 4,
		getTestConnect = 5;
	};
	
	panel:Bind(eventType.CURL, OnGetSTATUS, curlCommand.getSystemStatus);
	panel:Bind(eventType.CURL, OnGetPASSINGS, curlCommand.getSystemPassings);
	panel:Bind(eventType.CURL, ReadModeChrono, curlCommand.getModeChrono);
	panel:Bind(eventType.CURL, ReadNbPassings, curlCommand.getNbPassings);
	panel:Bind(eventType.CURL, ReadTestConnect, curlCommand.getTestConnect);

	-- Alert("ActiveID ou N° decodeur:"..ActiveID);
end

function OnModifNumFile(node)
-- Création Dialog 
config = {};
node = node
	dlgNumFichier = wnd.CreateDialog({
		parent = RaceresultWebServeur.panel,
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
		Alert('test : '..dlgNumFichier:GetWindowName('NumFichier'):GetValue());
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

function OnReOpenSocket(evt)
	Alert("En cour de redaction");
end
--*** new interface
-- fonction pour la gestion de la tables de corespondance

--fonction pour Vider une table de corespondance	
function OnClearTableCorres(evt)
	if RaceresultWebServeur.panel:MessageBox("Confirmation du Vidage de la table de corespondance ?\n\nCette opération effecera le contenue de la table corespondance de cet évènement", "Confirmation du Vidage de la table de corespondance", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	-- Alert ("CodeTypeTable = "..CodeTypeTable.."et  TypeTable = ".. TypeTable);
	if CodeTypeTable ~= "" or  TypeTable ~= "" then
	cmd = "Delete From tagID_Correspondance Where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	RaceresultWebServeur.dbSki:Query(cmd);
	else
	cmd = "Delete From tagID_Correspondance Where Code = "..RaceresultWebServeur.code_competition;
	RaceresultWebServeur.dbSki:Query(cmd);
	end
	
--	TabletagID_Correspondance:RemoveAllRows();
	cmd = "Select * From tagID_Correspondance where Code = "..CodeTypeTable.." and TypeTable = '"..TypeTable.."'";
	RaceresultWebServeur.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
 if TabletagID_Correspondance:GetNbRows() >= 1 then
	Alert("la table ne sais pas vider = "..TabletagID_Correspondance:GetNbRows());
end	
	TypeTable = 'ND'
	--Alert('je modifi dans la table TagID_Passings'..TypeTable)
	cmd = "Update tagID_Passings SET TypeTable = '"..TypeTable.."' Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'"
	RaceresultWebServeur.dbSki:Query(cmd);
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
	RaceresultWebServeur.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
	 if TabletagID_Correspondance:GetNbRows() >= 1 then
		if RaceresultWebServeur.panel:MessageBox("Confirmation du chargement de la table de corespondance ?\n\nCette opération effacera la table actuellement dans la base de donnée \n avant d'effectuer le rechargement de la table.", "Confirmation du chargement des Tag_ID et Dossards", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
			return;
		end
		
		OnClearTableCorres(CodeTypeTable, TypeTable)
		
	 end
 
 
	if RaceresultWebServeur.panel:MessageBox("Confirmation du chargement de la table de corespondance ?\n\nCette opération vas effectuer le chargement de la table.", "Confirmation du chargement des Tag_ID et Dossards", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
--  rechercher le fichier .db3 des séquences à relire et le charger en read.db3
	local fileDialog = wnd.CreateFileDialog(RaceresultWebServeur.panel,
		"Sélection du fichier de corespondance",
		RaceresultWebServeur.directory, 
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
						TabletagID_Correspondance:SetCell("Code", r, RaceresultWebServeur.code_competition);
						end
				TabletagID_Correspondance:SetCell("TagID", r, TagID);		
				TabletagID_Correspondance:SetCell("Dossard", r, Dossard);
				TabletagID_Correspondance:SetCell("TypeTable", r, TypeTable);
				RaceresultWebServeur.dbSki:TableInsert(TabletagID_Correspondance, r);
				end
			end
		end
		csvFile:close();
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
	cmd = "Update tagID_Passings SET TypeTable = '"..TypeTable.."' Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'"
	RaceresultWebServeur.dbSki:Query(cmd);
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
	cmd = "Select * From tagID_Correspondance where Code = '0' and TypeTable = 'GEN'";
	RaceresultWebServeur.dbSki:TableLoad(TabletagID_Correspondance, cmd)
 
	 if TabletagID_Correspondance:GetNbRows() >= 1 then
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable	= 'GEN' Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'";
		RaceresultWebServeur.dbSki:Query(cmd);
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
	cmd = "Select * From tagID_Correspondance where Code = "..RaceresultWebServeur.code_competition.." and TypeTable = 'EVT'";
	RaceresultWebServeur.dbSki:TableLoad(TabletagID_Correspondance, cmd)
	
	if TabletagID_Correspondance:GetNbRows() >= 1 then
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable	= 'EVT' Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'";
		RaceresultWebServeur.dbSki:Query(cmd);
		TypeTable = 'EVT';	
		Table.state = true ;
		CodeTypeTable = tonumber(RaceresultWebServeur.code_competition);
		--Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
		-- Rafraichissement de la grille ...
		local grid = dlgCorespondance:GetWindowName('grid_TableCorrespondance');
		grid:SynchronizeRows();
		Success('Validation de l\'utisation d\'une table unique à l\'évènement pour cet évènement ! ');
	else
		--Alert('je modifi dans la table TagID_Passings'..TypeTable)
		cmd = "Update tagID_Passings SET TypeTable = 'EVT'  Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'";
		RaceresultWebServeur.dbSki:Query(cmd);
		TypeTable = 'EVT';	
		Table.state = true ;
		CodeTypeTable = tonumber(RaceresultWebServeur.code_competition);
		Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
		OnChargeTableCorres(CodeTypeTable, TypeTable);
	end
	Alert("Type de Table utiliser pour cet évènement :"..TypeTable);
end

-- boite de dialogue pour la gestion de la table de corespondance
function OnOpenTableCorespondance(evt)
-- Création Dialog 

	dlgCorespondance = wnd.CreateDialog({
		parent = RaceresultWebServeur.panel,
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
	RaceresultWebServeur.dbSki:TableLoad(TabletagID_Correspondance, cmd)
	
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
	RaceresultWebServeurTb_Table = Steph.tb:AddTool("Outil race Time", "./res/32x32_config.png", "outils",  itemKind.DROPDOWN);
	RaceresultWebServeurTb_Clear = Steph.tb:AddTool('Remise à Zéro des Données', './res/32x32_clear.png');
	Steph.tb:AddStretchableSpace();
	RaceresultWebServeurTb_Save = Steph.tb:AddTool("Enregistrer", "./res/32x32_save.png");
	Steph.tb:AddSeparator();
	RaceresultWebServeurTb_Exit = Steph.tb:AddTool("Quitter", "./res/32x32_exit.png");

	local menuSend =  menu.Create();
	menuSend:AppendSeparator();
	RaceresultWebServeurTb_Table_TableGe = menuSend:Append({label="Utilisation de la Table Generique à tout les évènements", image ="./res/32x32_time-admin.png"});
	menuSend:AppendSeparator();	
	-- RaceresultWebServeurTb_OnChargeTableCorres = menuSend:Append({label="Upload d'une Table Generique à tout les évènements", image ="./res/32x32_time-admin.png"});
	-- menuSend:AppendSeparator();
	RaceresultWebServeurTb_Table_TableEvt = menuSend:Append({label="Upload et utilisation d'une Table unique à un évènement", image ="./res/vpe32x32_search.png"});
	Steph.tb:SetDropdownMenu(RaceresultWebServeurTb_Table:GetId(), menuSend);
	Steph.tb:Realize();
	
	-- Prise des Evenements (Bind)
	dlgCorespondance:Bind(eventType.MENU, OnRaceresultWebServeurOutil);
	-- dlgCorespondance:Bind(eventType.MENU, OnChargeTableCorres, RaceresultWebServeurTb_OnChargeTableCorres);
	dlgCorespondance:Bind(eventType.MENU, OnClearTableCorres, RaceresultWebServeurTb_Clear);
	dlgCorespondance:Bind(eventType.MENU, OnSave, RaceresultWebServeurTb_Save);
	dlgCorespondance:Bind(eventType.MENU, OnClosedlgCorespondance, RaceresultWebServeurTb_Exit);
	dlgCorespondance:Bind(eventType.MENU, OnValidTypeTableGen, RaceresultWebServeurTb_Table_TableGe);
	dlgCorespondance:Bind(eventType.MENU, OnValidTypeTableEvt, RaceresultWebServeurTb_Table_TableEvt);

	-- permet de verifier et fixer les choses avt le showmodal (à faire obligatoirement)
	dlgCorespondance:Fit();

	-- Affichage Modal
	dlgCorespondance:ShowModal();
	
end	

--***** NEW GESTION TABLE TAG ID FINISH

--fonction permetant de vider la table tagid finish de l'evenement
function OnDeleteTagIdFinish()
	if RaceresultWebServeur.panel:MessageBox("Confirmation du supression des Tag_ID déjà détecter? \n\n Seul les TagID détecter par le décodeur ACTIF seront éffacer \n Attention lors de la prochaine detection \n les transpondeurs ne seront plus mis en double detection \n et les dossards deja arrivés passerons dans la colonne ancien dossard", " Supression des Tag_ID déjà détecter", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end

--recherche du nombre de ligne ds la table tag ID et afichage
	cmd = "Select * From tagID_Finish Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'";
	TabletagID_Finish = RaceresultWebServeur.dbSki:GetTable('tagID_Finish');
	RaceresultWebServeur.dbSki:TableLoad(TabletagID_Finish,cmd);
	local nbTagID_Finish = TabletagID_Finish:GetNbRows();
	Alert("Nb de tagID Déja inscrit dans la table : "..nbTagID_Finish.." de l'Evt N°"..RaceresultWebServeur.code_competition.." du decodeur:"..ActiveID)

--Vidage de la table
	cmd = "Delete From tagID_Finish Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'";
	RaceresultWebServeur.dbSki:Query(cmd);
	
	Warning("Vidage table tagID_Finish ok...");
--recherche du nombre de ligne ds la table tag ID et afichage pour verication	
	cmd = "Select * From tagID_Finish Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'";	
	-- TabletagID_Finish = RaceresultWebServeur.dbSki:GetTable('tagID_Finish');
	RaceresultWebServeur.dbSki:TableLoad(TabletagID_Finish,cmd);
	local nbTagID_Finish = TabletagID_Finish:GetNbRows();
	Alert("Nb de tagID restant inscrit dans la table : "..nbTagID_Finish.." de l'Evt N°"..RaceresultWebServeur.code_competition.." du decodeur:"..ActiveID)

end

-- fonction permettant de vider la table tagID_Passings
function OnClearPassing()
--Alert("ActiveID :"..ActiveID);
	local NbPassing = '';
	if RaceresultWebServeur.panel:MessageBox("Confirmation du supression des Nb de passings déjà détecter? \n\n Attention cette pération vas remetre le compteur de détection à zéro\n SKIFFS vas aller récuperer toutes les detections du décodeur ", " Remise à zéro du Nb de détection", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	
	SavePassingCurrent(0,LoopID,LoopCanal);
	Alert("Nb de detection Mis a jour : 0");
	
end


-- fonction permetant de connaitre le GETSTATUS du decodeur definis ds les parametres et de commencer le chronometrage
function OnStartRaceresultWebServeur(evt)
	if TypeTable == 'ND' then 
		Warning("Pas de table de corespondance ");
		Warning("Veuillez sélectionner un type de table et uploader une table via un fichier .csv ");
	else
		if RaceresultWebServeur.ActiveStart == "Non Actif" then
			-- Prise de la table de Correspondance ...
			--raceresult.tagID = TabletagID_Correspondance; //////////////////////////////////////a suprimer???????????
			Warning("Correspondance : "..TabletagID_Correspondance:GetNbRows().." ligne ds la table");
			Alert("Type de Table utiliser pour cet évènement steph :"..TypeTable);
			--creation de l'adresse Url pour recuperer les passings sur le serveur race result
			CreateURL_status(curlCommand.getSystemStatus)
--			
		else 
			Error("Déja activé !");
		end		

	end		
end

-- Fonction qui créer l'url pour demander le status au serveur raceresult
function CreateURL_status(curlCommand)
	local url = device.url..
				'/getSystemStatus.php'..
				'?user='..RaceResultuser..
				'&pw='..RaceResultpw..
				'&device='..RaceResultdevice..
				'&format='..RaceResultformat
				;
	if url ~= nil then
		curl.AsyncGET(panel, url, curlCommand);
		--Alert("test url ="..url);
	end
end 

function OnGetSTATUS(evt)
	  local GetStatus = evt:GetString();
		Alert("test GetStatus ="..GetStatus);
			if GetStatus ~= nil then
				local arrayResults = string.Split(GetStatus,';');
				
				local Status = arrayResults[1];
				 Alert("test status ="..Status);
					if Status == "" then
						Alert("pas de connection internet sur l'ordi ");
					elseif Status == 'NO STATUS' then
					-- si le status est 'NO STATUS' je créer un timer pour rechercher quand le decodeur seras connecter
					RaceresultWebServeur.timerConnect = timer.Create(RaceresultWebServeur.panel);
						if RaceresultWebServeur.timerConnect ~= nil then
							RaceresultWebServeur.timerConnect:Start(RaceresultWebServeur.timerDelayConnect);
						end
						RaceresultWebServeur.panel:Bind(eventType.TIMER, OnTestConnectresultWebServeur, RaceresultWebServeur.timerConnect);	
						Alert("Décodeur :"..ActiveID.." OffLine ");
							
					else
						-- je renseigne ma variable pour dire que mon chrono est deja actif
						RaceresultWebServeur.ActiveStart = "Actif"

						RaceresultWebServeur.Connect:SetLabel("Connect");
						--Alert("Decodeur OnLine="..Status);
			-- decodeur connecter au serveur on peu lancer continuer en verifiant le N° de fichier
						local ProtocolDecodeur = arrayResults[3];
						local ModeChrono = arrayResults[4];
						Alert("Mode chrono = "..ModeChrono)
						if tostring(ModeChrono) == 0 then
							Alert("Décodeur en mode STANBY ....")
						elseif tostring(ModeChrono) == '1' then
							Alert("Décodeur en mode CHRONO / Protocol Utilisé : "..ProtocolDecodeur)
						else
							Alert("Chrono en mode ?????")
						end
						
						local Files = arrayResults[6];
							--Alert ("N° files = "..Files);
							--Alert ("N° files = "..RaceResultfile);
			-- si le N° de fichier est identique dans skiffs et sur le serveur on peu lancer le timer chrono	averif			
						if tostring(Files) == tostring(RaceResultfile) then
							-- Timer Init ...******
							-- Creation du Timer 
							RaceresultWebServeur.timerChrono = timer.Create(RaceresultWebServeur.panel);
							if RaceresultWebServeur.timerChrono ~= nil then
								RaceresultWebServeur.timerChrono:Start(RaceresultWebServeur.timerDelay);
							end
							RaceresultWebServeur.panel:Bind(eventType.TIMER, OnTimerChrono, RaceresultWebServeur.timerChrono);	
						else
							Alert ('le N° de fichier ne correspond pas entre skiffs et le serveur!!!!!')
							Alert ('le N° de fichier Actif du decodeur :'..ActiveID..'est :'..Files..'et le fichier declarer dans SKIFFS est : '..RaceResultfile)
						end	
		-- niveau de charge de la batterie

					local batteryCharge = tonumber(arrayResults[9]);
					RaceresultWebServeur.battery:SetLabel("Charge Bat ="..batteryCharge..'%');
					if batteryCharge < 10 then
						Warning("Charge de la batterie trop faible: "..batteryCharge.."%");
					end	
		--Nb de passinds ds le fichiers		
				RaceresultWebServeur.passingCount = tostring(arrayResults[7]);	
				RaceresultWebServeur.info:SetLabel("Timer :"..tostring(RaceresultWebServeur.alive)..
													" Passings : "..tostring(RaceresultWebServeur.passingCurrent)..
													"-R/"..tostring(RaceresultWebServeur.passingCount)..
													"-D0/")
													;			
				end
				
			else 
			-- recherche de la connection par un timer on charge baterie
			
			end 
end		


--fonction permetant de lire si le decodeur est actif ou pas...
function OnReadModeChrono(ModeChrono)
	-- création et envoi de la requette curl en mode asychrone avec la commande curlCommand.getModeChrono qui permetra la gestion de la requette de retour du serveur
	CreateURL_status(curlCommand.getModeChrono)
	
end

-- fonction lisant le status du decodeur
function ReadModeChrono(evt)			
	local GetStatus = evt:GetString();
		--Alert("test getModeChrono ="..GetStatus);
	if GetStatus ~= nil then
		local arrayResults = string.Split(GetStatus,';');
		
		local Status = arrayResults[1];
		--Alert("test status ="..Status);
			if Status == 'NO STATUS' then
			-- Creation du Timer connect
				RaceresultWebServeur.timerConnect = timer.Create(RaceresultWebServeur.panel);
				if RaceresultWebServeur.timerConnect ~= nil then
					RaceresultWebServeur.timerConnect:Start(RaceresultWebServeur.timerDelayConnect);
				end
				RaceresultWebServeur.panel:Bind(eventType.TIMER, OnTestConnectresultWebServeur, RaceresultWebServeur.timerConnect);	
				Alert("Décodeur OffLine ="..Status);
					
			else	
				--Alert("Decodeur OnLine="..Status);
	-- decodeur connecter au serveur on peu lancer continuer en verifiant le N° de fichier
				local ProtocolDecodeur = arrayResults[3];
				local ModeChrono = arrayResults[4];
				Alert("Mode chrono = "..ModeChrono.."/ Protocol Utilisé : "..ProtocolDecodeur)
				if tostring(ModeChrono) == '0' then
					Alert("Décodeur en mode STANBY ....")
					-- delate TimerStartOperation
					if RaceresultWebServeur.timerStartOperation ~= nil then
						RaceresultWebServeur.timerStartOperation:Delete();
						RaceresultWebServeur.timerStartOperation = nil;
					end
					
					
				elseif tostring(ModeChrono) == '1' then
					Alert("Décodeur en mode CHRONO / Protocol Utilisé : "..ProtocolDecodeur)
						if RaceresultWebServeur.timerStartOperation ~= nil then
						RaceresultWebServeur.timerStartOperation:Delete();
						RaceresultWebServeur.timerStartOperation = nil;
						end
				else
					Alert("Chrono en mode ?????")
				end
			end	
	else 
		Alert('GetStatus = nil')
	end
end

--Fonction permetant de d'activé les antennes
function OnStartOperation()
local url = device.url..
				'/sendCommand.php'..
				'?user='..RaceResultuser..
				'&pw='..RaceResultpw..
				'&device='..RaceResultdevice..
				'&cmd=STARTOPERATION'
				;
	local txtReturn = curl.GET(url);
	Alert("demande d'activation des antennes de détection")
		--Alert("test Get status ="..GetStatus);
RaceresultWebServeur.timerStartOperation = timer.Create(RaceresultWebServeur.panel);
				if RaceresultWebServeur.timerStartOperation ~= nil then
					RaceresultWebServeur.timerStartOperation:Start(RaceresultWebServeur.timerDelayConnect);
				end
				--fonction OnReadModeChrono fait en asynchrone
				RaceresultWebServeur.panel:Bind(eventType.TIMER, OnReadModeChrono, RaceresultWebServeur.timerStartOperation);	
				--Alert("Décodeur OffLine ="..Status);
end


--Fonction permetant de désactiver les antennes
function OnStopOperation()
local url = device.url..
				'/sendCommand.php'..
				'?user='..RaceResultuser..
				'&pw='..RaceResultpw..
				'&device='..RaceResultdevice..
				'&cmd=STOPOPERATION'
				;
	-- Pas besoin de faire en asynchrone car pas de réponse demander c'est juste une commande d'envoyer la confirmation est demander par la fonction OnReadModeChrono lancer par le timer
	local OnStopOperation = curl.GET(url);
		Alert("demande de mise en veille des antennes de détection");
		--Alert("test Get status ="..GetStatus);
RaceresultWebServeur.timerStartOperation = timer.Create(RaceresultWebServeur.panel);
				if RaceresultWebServeur.timerStartOperation ~= nil then
					RaceresultWebServeur.timerStartOperation:Start(RaceresultWebServeur.timerDelayConnect);
				end
				--fonction OnReadModeChrono fait en asynchrone
				RaceresultWebServeur.panel:Bind(eventType.TIMER, OnReadModeChrono, RaceresultWebServeur.timerStartOperation);	
				--Alert("Décodeur OffLine ="..Status);
end

function OnRechargeFichierOffLine(evt)
	local RaceResultminid = 1;
	local RaceResultlimit = 0;
	local url = device.url..
		'/getSystemPassings.php'..
		'?user='..RaceResultuser..
		'&pw='..RaceResultpw..
		'&device='..RaceResultdevice..
		'&file='..tonumber(RaceResultfile)..
		'&minid='..tonumber(RaceResultminid)..
		'&type='..RaceResulttype..
		'&limit='..tonumber(RaceResultlimit)
		;
	-- Commande Asynchrone pour lire le fichier Passings du serveur race result
		curl.AsyncGET(panel, url, curlCommand.getSystemPassings);	
		-- Alert('envoi de la requette asynchrone pour recharger le fichier complet faite'..url);
	
end

--*****fonction de lecture des données envoyer par le serveur raceresult
function OnTimerChrono(evt)
RaceresultWebServeur.alive = RaceresultWebServeur.alive + 1;
--creation de l'adresse Url pour recuperer les passings sur le serveur race result avec la fonction GetNbPassings
CreateURL_status(curlCommand.getNbPassings);

end

function ReadNbPassings(evt)
	local GetStatus = evt:GetString();
		--Alert("test Get status ="..GetStatus);

	if GetStatus ~= nil then
		local arrayResults = string.Split(GetStatus,';');
		NbPassingsFiles = tostring(arrayResults[7]);
	end
	-- Alert("NbPassingsFiles = "..NbPassingsFiles);
	-- Alert("RaceresultWebServeur.passingCurrent = "..RaceresultWebServeur.passingCurrent);
	if tonumber(NbPassingsFiles) == tonumber(RaceresultWebServeur.passingCurrent) then

	elseif tonumber(NbPassingsFiles) > tonumber(RaceresultWebServeur.passingCurrent) then

		RaceResultminid = tonumber(NbPassingsFiles) - tonumber(RaceresultWebServeur.passingCurrent);
		-- Alert("RaceResultminid = "..RaceResultminid);
		
				if RaceResultminid == 1 then
				--RaceResultlimit = 0;  -- valeur du nb de ligne que l'on souhaite recevoir 0 on recois le fichier complet  si on met 1 on ne recois pas les trames
				RaceResultlimit = 1;
					url = device.url..
					'/getSystemPassings.php'..
					'?user='..RaceResultuser..
					'&pw='..RaceResultpw..
					'&device='..RaceResultdevice..
					'&file='..RaceResultfile..
					'&minid='..tonumber(RaceresultWebServeur.passingCurrent+1)..
					'&type='..RaceResulttype..
					'&limit='..RaceResultlimit
					;
				-- Alert('URL1 = '..url);
				
				--*******
				else
				--RaceResultlimit = 0;  -- valeur du nb de ligne que l'on souhaite recevoir 0 on recois le fichier complet  si on met 1 on ne recois pas les trames
				RaceResultlimit = 0;
					url = device.url..
					'/getSystemPassings.php'..
					'?user='..RaceResultuser..
					'&pw='..RaceResultpw..
					'&device='..RaceResultdevice..
					'&file='..tonumber(RaceResultfile)..
					'&minid='..tonumber(RaceresultWebServeur.passingCurrent+1)..
					'&type='..RaceResulttype..
					'&limit='..tonumber(RaceResultlimit)
					;
				-- Alert('URL2 = '..url);
				end
		-- Commande Asynchrone pour lire le fichier Passings du serveur race result
		curl.AsyncGET(panel, url, curlCommand.getSystemPassings);
	end
-- a mettre peu etre dans la fonction on read passings ca a l'aire de fonctionner on pourras enlever ces lignes ************************
-- RaceresultWebServeur.info:SetLabel("Timer :"..tostring(RaceresultWebServeur.alive)..
									-- " Nb Passings : "..tostring(RaceresultWebServeur.passingCurrent)..
									-- '-R/'..tostring(NbPassingsFiles)..
									-- '-Serveur/')
									-- ;			
end


function OnGetPASSINGS(evt)
	local data = evt:GetString();
	-- Alert('reception de la requette asynchrone envoyer au serveur pour envoi dans le readpacket');
	-- Alert('data = '..data);
	
	if data == 'NO PASSINGS' then
		Alert('pas de passing dans le fichier: '..RaceResultfile);
	else
		local cb = circularBuffer.Open();
		cb:WriteString(data);
		-- adv.Alert('CircularBuffer Size = '..cb:GetCount());
		assert(cb:GetCount() == data:len());
		--Alert('data = '..data);
		-- Traitement De Lecture
		if cb:GetCount() == 0 then return end
		-- Lecture des Packets 
		while (ReadPacket(cb)) do end
		--ReadPacket(cb);
		
		cb:Close();
	end
end

-- lecture du packet recu du serveur race result
function ReadPacket(cb)
-- Alert ("test passage ds readPacket(cb)");
	
	local count =  cb:GetCount();
	
	local findEnd = cb:Find(asciiCode.LF);	-- Recherche fin de Trame(asciiCode.CR, asciiCode.LF);
-- Alert ("findEnd = "..findEnd);	
	if findEnd == -1 then return false end 					-- On peut stopper la recherche
	

		local packet = cb:ReadByte(findEnd);
		local packetString = adv.PacketString(packet, 1, findEnd);
-- Alert ("packetString = "..packetString);
		local arrayResults = string.Split(packetString,';');
		
		local countResults = #arrayResults;
		-- Alert ("test passage ds readPacket(cb)"..countResults);	
		if countResults >= 1 then
			local firstResult = arrayResults[1]; --ligne a commenter pour la fonction debug

			-- Alert("firstResult = "..firstResult);
			if tonumber(firstResult) ~= nil and tonumber(firstResult) > 0 then
-- ###### coupure pour tranfert web ou reseau //////////// quand on met bien mettre raceresult ou RaceresultWebServeur (entre les deux coupure) suivant si on est en IP ou en webserveur////******
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
						Alert("NbToursAFaire 2 = "..NbToursAFaire);	--ok			
						--si bib est différent de nil ou de '' on gere l'impultion
						if bib ~= "" then				
							-- recherche si un tagID existe dans la table TableTagID_Finish
							cmd = "Select * From TagID_Finish Where Code = '"..RaceresultWebServeur.code_competition..
								  "' and AdresseIP = '"..ActiveID..
								  "' and LoopID = '"..LoopID..
								  "' and LoopCanal = '"..LoopCanal..
								  "' and TagID = '"..tagID..
								  "'"
								  ;
							local Rech_TagID = RaceresultWebServeur.dbSki:TableLoad(TableTagID_Finish, cmd):GetCell("TagID", 0);
							local Rech_Der_Passge_TagID = RaceresultWebServeur.dbSki:TableLoad(TableTagID_Finish, cmd):GetCell("Passage", 0);
							Alert("Rech_Der_Passge_TagID = "..Rech_Der_Passge_TagID)
							-- Alert("Rech_TagID = "..Rech_TagID)
							-- Gestion Impulsions			
								--si Rech_TagID est diff de '' je gere l' impultion
							if Rech_TagID ~= '' then
								-- recherche du nombre de tour fait par le coureur ds la Table TableTagID_Finish 
								cmd = "select * from TagID_Finish where Code = "..RaceresultWebServeur.code_competition..
										" and AdresseIP = '"..ActiveID..
										"' and LoopID = '"..LoopID..
										"' and LoopCanal = '"..LoopCanal..
										"' and TagID = '"..tagID..
										"'"
								local NbTourRealiser = RaceresultWebServeur.dbSki:TableLoad(TableTagID_Finish, cmd):GetCellInt("Tour", 0);
								-- Alert("Nb Tour fait: "..NbTourRealiser.."/ "..NbToursAFaire.." Tours à Faire")
									-- Recherche du numero de passage défini dans la table tagID_Passings OK
								cmd = "Select * From tagID_Passings Where Code = "..RaceresultWebServeur.code_competition..
									  " and AdresseIP = '"..ActiveID..
									  "' and LoopID = '"..LoopID..
									  "' and LoopCanal = '"..LoopCanal..
									  "'"
									  ;
								RaceresultWebServeur.dbSki:TableLoad(TableTagID_Passings, cmd);
					--peu etre mettre une condition si la requette retourne nil	?	*****************************************************************	
								-- Recherche du delay de double detection
									local DelayDoubleDetect = TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
									Alert("DelayDoubleDetect: test steph"..DelayDoubleDetect);
									
									-- suivant le nombre de tour fait par le concurent et le nombre de tour qu'il a a faire j'acremente la variable passage
									--si le concurent n'a pas fait plus le nombre de tour alors passage seras egal NbTourRealiser
									if tonumber(NbToursAFaire) == 0 then
										passage = TableTagID_Passings:GetCell('passage', 0);
										Alert("if tonumber(NbToursAFaire) == 0 : "..passage);
									else
										if tonumber(NbTourRealiser) < tonumber(NbToursAFaire) then 
											passage = tonumber(NbTourRealiser) + tonumber(ID_1er_Inter);
											Alert("if tonumber(NbTourRealiser) < tonumber(NbToursAFaire) : "..passage);
										--si le concurent a fait le nombre de tour alors passage seras egal a passage	
										elseif	tonumber(NbTourRealiser) == tonumber(NbToursAFaire) then 
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
							cmd = "Select * From tagID_Passings Where Code = "..RaceresultWebServeur.code_competition..
								  " and AdresseIP = '"..ActiveID..
								  "' and LoopID = '"..LoopID..
								  "' and LoopCanal = '"..LoopCanal..
								  "'"
								  ;
							RaceresultWebServeur.dbSki:TableLoad(TableTagID_Passings, cmd);
								-- Recherche du delay de double detection
							local DelayDoubleDetect = TableTagID_Passings:GetCell('DelayDoubleDetect', 0);
							local passage = TableTagID_Passings:GetCell('passage', 0);
								Alert("DelayDoubleDetect = "..DelayDoubleDetect);
								Alert("passage = "..passage);
							-- recherche si un tagID existe dans la table TagID_TourPena
							cmd = "Select * From TagID_TourPena Where Code = '"..RaceresultWebServeur.code_competition..
								  "' and AdresseIP = '"..ActiveID..
								  "' and LoopID = '"..LoopID..
								  "' and LoopCanal = '"..LoopCanal..
								  "' and Dossard = "..bib							 
								  ;
							local Rech_Dossard = RaceresultWebServeur.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCell("Dossard", 0);
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
											local Num_Tir = RaceresultWebServeur.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Num_Tir", 0);
											Alert("Num_Tir1 = "..Num_Tir);
											local NbTour_Fait = RaceresultWebServeur.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Tir"..Num_Tir, 0)+1;
											Alert("NbTour_Fait = "..NbTour_Fait);
											AddNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait);
										else
										-- si le l'heure dedetection 'chrono' est superieur a tps + DelayDoubleDetect c'est une boucle de pena du tir superieur
											local Num_Tir = RaceresultWebServeur.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Num_Tir", 0)+1;
											Alert("Num_Tir + 1 = "..Num_Tir);
											local NbTour_Fait = RaceresultWebServeur.dbSki:TableLoad(TabletagID_TourPena, cmd):GetCellInt("Tir"..Num_Tir, 0)+1;
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
					
		end --if firstResult
	
	end--if countResults
		-- ok pour la mise a jour apres le chargement d'un fichier complet
RaceresultWebServeur.info:SetLabel("Timer :"..tostring(RaceresultWebServeur.alive)..
									" Nb Passings : "..tostring(RaceresultWebServeur.passingCurrent)..
									'-R/'..tostring(NbPassingsFiles)..
									'-Serveur/')
									;			
	
	return true;	
	-- il faut poursuivre la recherche	
end 
--*****fin de fonction de lecture des données envoyer par le serveur raceresult 

--**** new fonction pour la recherche rdu Nb de tour

-- function permetant aller chercher le dos par rapport au tagid
function RecherchetourDos(CodeTypeTable,tagID,LoopID,LoopCanal)
-- recherche du dossard par rapport au TagID ds la table tagID_Correspondance
	cmd = "Select * From tagID_Correspondance where Code = "..CodeTypeTable.." and TagID = '"..tagID.."'";
	bib = RaceresultWebServeur.dbSki:TableLoad(TabletagID_Correspondance, cmd):GetCell("Dossard", 0);
	if bib ~= "" then 
		-- Alert("bib = "..bib);
		-- Alert("RaceresultWebServeur.code_competition = "..RaceresultWebServeur.code_competition);
		-- Alert("ActiveID = "..ActiveID);
		-- Alert("LoopID = "..LoopID);
		-- Alert("LoopCanal = "..LoopCanal);
		-- on vas chercher le nombre de tour que le dos doit faire 
		cmd = "Select * From tagID_Tour Where Code = "..RaceresultWebServeur.code_competition..
													 " and AdresseIP = '"..ActiveID..
													 "' and LoopID = '"..LoopID..
													 "' and LoopCanal = '"..LoopCanal..
													 "'";
		-- Alert("cmd = "..cmd);											 
		TabletagID_Tour = RaceresultWebServeur.dbSki:GetTable('tagID_Tour');
		RaceresultWebServeur.dbSki:TableLoad(TabletagID_Tour, cmd);
		Testnbtour = RaceresultWebServeur.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows();
		-- Alert("Testnbtour = "..Testnbtour);
		for i=0, RaceresultWebServeur.dbSki:TableLoad(TabletagID_Tour, cmd):GetNbRows()-1 do 
		bibMini = TabletagID_Tour:GetCell('bibMini', i);
		bibMax = TabletagID_Tour:GetCell('bibMax', i);
		-- Alert("bib = "..bib);
		-- Alert("bibMini = "..bibMini);
		-- Alert("bibMini = "..bibMax);
		-- Alert("i = "..i);
			if tonumber(bib) >= tonumber(bibMini) and tonumber(bib) <= tonumber(bibMax) then
				NbToursAFaire = TabletagID_Tour:GetCell('Tour', i);
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


function RechercheCountTourActif(CodeTypeTable,tagID, LoopID, LoopCanal);
	-- recherche du dossard par rapport au TagID ds la table tagID_Correspondance
	cmd = "Select * From tagID_Passings Where Code = "..RaceresultWebServeur.code_competition..
												 " and AdresseIP = '"..ActiveID..
												 "' and LoopID = '"..LoopID..
												 "' and LoopCanal = '"..LoopCanal..
												 "'";
	CountTourActif = RaceresultWebServeur.dbSki:TableLoad(TabletagID_Passings, cmd):GetCell("CountTourActif", 0);
	SystemeActif = RaceresultWebServeur.dbSki:TableLoad(TabletagID_Passings, cmd):GetCell("SystemeActif", 0);
	--Alert("CountTourActif = "..CountTourActif);
end

-- fonction qui permet de mettre a jour lr Nb tour dans la table tagID_finish
function AddNbTours(NbTours, tagID, ActiveID, LoopID, LoopCanal)
	Alert("AddNbtours LoopID = "..ActiveID);
	local cmd = 
		"Update tagID_Finish SET Tour = "..NbTours..
		" Where Code = "..RaceresultWebServeur.code_competition..
		" and AdresseIP = '"..ActiveID..
		"' and LoopID = '"..LoopID..
		"' and LoopCanal = '"..LoopCanal..
		"' and TagID = '"..tagID..
		"'"
	RaceresultWebServeur.dbSki:Query(cmd);
 
end

function InsertNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait)
	 --Alert("Num_Tir = "..Num_Tir);	
 local r = TabletagID_TourPena:AddRow();				
				TabletagID_TourPena:SetCell("Code", r, tonumber(RaceresultWebServeur.code_competition));
				TabletagID_TourPena:SetCell("AdresseIP", r, ActiveID);
				TabletagID_TourPena:SetCell("LoopID", r, LoopID);
				TabletagID_TourPena:SetCell("LoopCanal", r, LoopCanal);
				TabletagID_TourPena:SetCell("Dossard", r, bib);
				TabletagID_TourPena:SetCell("Tir1", r, tonumber(NbTour_Fait));	
				TabletagID_TourPena:SetCell("Tir2", r, 0);
				TabletagID_TourPena:SetCell("Tir3", r, 0);
				TabletagID_TourPena:SetCell("Tir4", r, 0);
				TabletagID_TourPena:SetCell("Num_Tir", r, tonumber(Num_Tir));
				RaceresultWebServeur.dbSki:TableInsert(TabletagID_TourPena, r);
				Success("Ajout dos ="..bib.. " dans la TabletagID_TourPena");	
end

function AddNbTour_Pena( ActiveID, LoopID, LoopCanal, bib, Num_Tir, NbTour_Fait)
	--Alert("AddNbtours_pena Num_Tir = "..Num_Tir);
	--Alert("AddNbtours LoopID = "..NbTour_Fait);
	
	local cmd = 
		"Update tagID_TourPena SET Tir"..Num_Tir.." = "..NbTour_Fait..
		", Num_Tir = "..Num_Tir..
		" Where Code = "..RaceresultWebServeur.code_competition..
		" and AdresseIP = '"..ActiveID..
		"' and LoopID = '"..LoopID..
		"' and LoopCanal = '"..LoopCanal..
		"' and Dossard = '"..bib..
		"' "
		;
	RaceresultWebServeur.dbSki:Query(cmd);
	Success("Ajout d\' 1 tour au dos ="..bib.. " dans la TabletagID_TourPena Donc :"..NbTour_Fait);		
end

function AddTimesTagIDFinish(tagID, passage, LoopID, LoopCanal, Tour, bib)
-- ecriture du TagID dans la table tagID_Finish
				local r = TableTagID_Finish:AddRow();				
				TableTagID_Finish:SetCell("Code", r, RaceresultWebServeur.code_competition);
				TableTagID_Finish:SetCell("AdresseIP", r, ActiveID);
				TableTagID_Finish:SetCell("LoopID", r, LoopID);
				TableTagID_Finish:SetCell("LoopCanal", r, LoopCanal);
				TableTagID_Finish:SetCell("TagID", r, tagID);		
				TableTagID_Finish:SetCell("Passage", r, passage);
				TableTagID_Finish:SetCell("Tour", r, Tour);
				RaceresultWebServeur.dbSki:TableInsert(TableTagID_Finish, r);
					Success("Ajout dos ="..bib.. " dans la TableTagID_Finish");	

end
					
function GetHeurePassage(dossard, passage)
	local cmd =
		" select * From Resultat_Chrono where Code_evenement = "..RaceresultWebServeur.code_competition..
		" And Code_manche = "..RaceresultWebServeur.code_manche..
		" And Id = "..passage..
		" And Dossard = "..dossard
	;
	tResultatChrono = RaceresultWebServeur.dbSki:GetTable('Resultat_Chrono');
	RaceresultWebServeur.dbSki:TableLoad(tResultatChrono, cmd);
	--Alert('RaceresultWebServeur.code_competition = '..RaceresultWebServeur.code_competition);
	--Alert('RaceresultWebServeur.code_manche = '..RaceresultWebServeur.code_manche);
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
		" select * From Resultat_Manche where Code_evenement = "..RaceresultWebServeur.code_competition..
		" And Code_coureur = '"..Code_coureur..
		"'"
	;
	tResultat_Manche = RaceresultWebServeur.dbSki:GetTable('Resultat_Manche');
	RaceresultWebServeur.dbSki:TableLoad(tResultat_Manche, cmd);
	--Alert('RaceresultWebServeur.code_competition = '..RaceresultWebServeur.code_competition);
	--Alert('RaceresultWebServeur.code_manche = '..RaceresultWebServeur.code_manche);
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
		" select * From Resultat where Code_evenement = "..RaceresultWebServeur.code_competition..
		" And Dossard = "..dossard
	;
	tResultat = RaceresultWebServeur.dbSki:GetTable('Resultat');
	RaceresultWebServeur.dbSki:TableLoad(tResultat, cmd);
	--Alert('RaceresultWebServeur.code_competition = '..RaceresultWebServeur.code_competition);
	--Alert('RaceresultWebServeur.code_manche = '..RaceresultWebServeur.code_manche);
	--Alert('idPassage = '..passage);
	--Alert('dossard = '..dossard);
	
	if tResultat == nil then return -1 end
	if tResultat:GetNbRows() == 0 then return -1 end
	Alert('GetCodecoureur = '..tResultat:GetCell('Code_coureur',0));
	-- Heure de passage existe ...	
	return tResultat:GetCell('Code_coureur',0);
end

-- **** fin des news fonction

function OnTestConnectresultWebServeur (evt)
--creation de l'adresse Url pour recuperer les passings sur le serveur race result
local url = device.url..
		'/getSystemStatus.php'..
		'?user='..RaceResultuser..
		'&pw='..RaceResultpw..
		'&device='..RaceResultdevice..
		'&format='..RaceResultformat..
		'&showlaststatus='..RaceResultshowlaststatus
		;
	curl.AsyncGET(panel, url, curlCommand.getTestConnect);	
end	

function ReadTestConnect(evt)	

	 Status = evt:GetString();
	 Alert("Status venat du timer OnTestConnectresultWebServeur : "..Status);
	if Status ~= nil then

		local arrayResults = string.Split(Status,';');

		if Status == 'NO STATUS' then
			-- Mise en place du WatchDog
			RaceresultWebServeur.watchDogConnect = timer.Create(RaceresultWebServeur.panel);
			if RaceresultWebServeur.watchDogConnect ~= nil then
				RaceresultWebServeur.watchDogConnect:StartOnce(1000); -- Il faut moins de 1 sec au raceresult pour répondre 
			end
			
	RaceresultWebServeur.panel:Bind(eventType.TIMER, OnWatchDogConnect, RaceresultWebServeur.watchDogConnect);
			--Alert("Status KO ="..Status);
			Alert("le decodeur :"..ActiveID.." n'est toujours pas connecter");
		else		
			--Alert("Status OK ="..Status);
			Alert("le decodeur :"..ActiveID.." est bien connecter");
-- niveau de charge de la batterie
			local batteryCharge = tonumber(arrayResults[9]);
			RaceresultWebServeur.battery:SetLabel("Charge Bat ="..batteryCharge..'%');
			if batteryCharge < 10 then
				Warning("Charge de la batterie trop faible: "..batteryCharge.."%");
			end
			RaceresultWebServeur.Connect:SetLabel("Connect");	
-- delate timerConnect
			if RaceresultWebServeur.timerConnect ~= nil then
				RaceresultWebServeur.timerConnect:Delete();
				RaceresultWebServeur.timerConnect = nil;	
			end
			OnStartRaceresultWebServeur();
		end
	else 
	-- recherche de la connection par un timer on charge baterie
	
	end 

end
--**********************
function OnWatchDogConnect(evt)
	-- Aucune réponse du Raceresult ... on n'est pas ou plus connecté
	RaceresultWebServeur.Connect:SetLabel("Non Connect");
	RaceresultWebServeur.battery:SetLabel('Bat=---%');
	
	if RaceresultWebServeur.watchDogConnect ~= nil then
		RaceresultWebServeur.watchDogConnect:Delete();
		RaceresultWebServeur.watchDogConnect = nil;
	end
end

--*********************
function device.OnClose()

	RaceresultWebServeur.Stop = true;

	if RaceresultWebServeur.panel ~= nil then
		-- On Ignore les "event" qui peuvent encore être dans la pile ...
		RaceresultWebServeur.panel:UnbindAll();
	end
-- delate timerConnect
	if RaceresultWebServeur.timerConnect ~= nil then
		RaceresultWebServeur.timerConnect:Delete();
		RaceresultWebServeur.timerConnect = nil;
	end
-- delate timerChrono
	if RaceresultWebServeur.timerChrono ~= nil then
		RaceresultWebServeur.timerChrono:Delete();
		RaceresultWebServeur.timerChrono = nil;
	end
-- delate TimerStartOperation
	if RaceresultWebServeur.timerStartOperation ~= nil then
		RaceresultWebServeur.timerStartOperation:Delete();
		RaceresultWebServeur.timerStartOperation = nil;
	end
-- delate watchDogConnect	
	if RaceresultWebServeur.watchDogConnect ~= nil then
		RaceresultWebServeur.watchDogConnect:Delete();
	end

-- fonction permetant le fonctionnement de l'activation ou de la desactivation des devices ds la fenetre chrono
	local mgr = app.GetAuiManager();
	mgr:DeletePane(RaceresultWebServeur.panel);

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
				RaceresultWebServeur.dbSki:TableInsert(TabletagID_Tour, r);
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
				RaceresultWebServeur.dbSki:TableInsert(TabletagID_Passings, r);
end

-- fonction pour mettre le Nb de detection recu à jour test
function SavePassingCurrent(value)
	-- Prise de la Valeur en Mémoire 
	RaceresultWebServeur.passingCurrent = value;
	
	-- Enregistrement en MySQL 
	cmd = 
		"update tagID_Passings set Passings = "..
		tostring(RaceresultWebServeur.passingCurrent)..
		" Where Code = "..RaceresultWebServeur.code_competition..
		" And AdresseIP = '"..ActiveID..
		"'"
		;
	RaceresultWebServeur.dbSki:Query(cmd);
	
end

-- mise a jour du N° de passage lors d'une détection
function refreshTagIDFinish(tagID, passage, LoopID, LoopCanal)
	local cmd = 
			"update tagID_Finish SET Passage = '"..passage..
		" 'Where Code = "..RaceresultWebServeur.code_competition..
		" And AdresseIP = '"..ActiveID..
		"' And LoopID = '"..LoopID..   
		"' And LoopCanal = '"..LoopCanal.. 
		"' And tagID = '"..tagID..
		"' "
		;
	RaceresultWebServeur.dbSki:Query(cmd);
	Success("Mise a jour du N° de passage :"..passage.." du TagID ="..tagID.. " dans la TableTagID_Finish");
	
end

--*******
-- format hh:mm:ss.kkk
function GetChrono(hourPassage)
	local hour = string.sub(hourPassage,1,2);
	local minute = string.sub(hourPassage,4,5);
	local sec = string.sub(hourPassage,7,8);
	local milli = string.sub(hourPassage,10,12);
	
	return 3600000*tonumber(hour)+60000*tonumber(minute)+1000*tonumber(sec)+tonumber(milli);
end

function AddTimePassage(chrono, passage, bib, tagID)	
	bib = bib or '';
	tagID = tagID or '';
	passage = passage or '';
	chrono = chrono or '';
	--Alert("test variable bib="..bib.."tagID ="..tagID.."passage ="..passage.."/")
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'RaceResult-WebServeur'..ActiveID, tag = tagID }
	);
	
	Success('<passage_add tagId='..tagID..' bib='..bib..' passage='..passage..' chrono='..chrono..'>');

end
		

-- Configuration du Device

function device.OnConfiguration(node)
	config = {};
	-- width = longueur;
	-- height = largeur;
	
	local dlg_ConfigRaceResultWebServeur = wnd.CreateDialog(
		{
			parent = RaceresultWebServeur.panel,
			icon = "./res/32x32_ffs.png",
			label = "Configuration du raceresult WebServeur",
			width = 600,
			height = 650
		})
		dlg_ConfigRaceResultWebServeur:LoadTemplateXML({ 
		xml = './device/raceresult.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'config_RaceResult_WebServeur'
	});

	dlg_ConfigRaceResultWebServeur:GetWindowName('config_AdrServeurRaceResult'):SetValue(node:GetAttribute('config_AdrServeurRaceResult', 'https://data.raceresult.com/interface/passings/v6'));
	dlg_ConfigRaceResultWebServeur:GetWindowName('config_IdDecodeur'):SetValue(node:GetAttribute('config_IdDecodeur', ''));
	dlg_ConfigRaceResultWebServeur:GetWindowName('config_PortDecodeur'):SetValue(node:GetAttribute('config_PortDecodeur', '3601'));
	dlg_ConfigRaceResultWebServeur:GetWindowName('config_User'):SetValue(node:GetAttribute('config_User', ''));
	dlg_ConfigRaceResultWebServeur:GetWindowName('config_PWD'):SetValue(node:GetAttribute('config_PWD', ''));
	dlg_ConfigRaceResultWebServeur:GetWindowName('config_NumFichier'):SetValue(node:GetAttribute('config_NumFichier', ''));	
	dlg_ConfigRaceResultWebServeur:GetWindowName('config_Passage'):SetValue(node:GetAttribute('config_Passage', '-1'));
	if node:GetAttribute('SystemeActif') == "1" then
		dlg_ConfigRaceResultWebServeur:GetWindowName('checkbox_config_Systeme'):SetValue(true);
	else
		dlg_ConfigRaceResultWebServeur:GetWindowName('checkbox_config_Systeme'):SetValue(false);
	end
	
	if node:GetAttribute('bib') == "1" then
		dlg_ConfigRaceResultWebServeur:GetWindowName('checkbox_config_Lect_Dos'):SetValue(true);
	else
		dlg_ConfigRaceResultWebServeur:GetWindowName('checkbox_config_Lect_Dos'):SetValue(false);
	end

-- Toolbar Principale ...
	config.tb = dlg_ConfigRaceResultWebServeur:GetWindowName('tb');
	btnSave = config.tb:AddTool("Valider", "./res/32x32_save.png");
	config.tb:AddStretchableSpace();
	btnClose = config.tb:AddTool("Fermer", "./res/32x32_close.png");
	config.tb:Realize();

function OnSaveConfig(evt)
		node:ChangeAttribute('config_AdrServeurRaceResult', dlg_ConfigRaceResultWebServeur:GetWindowName('config_AdrServeurRaceResult'):GetValue());
		node:ChangeAttribute('config_IdDecodeur', dlg_ConfigRaceResultWebServeur:GetWindowName('config_IdDecodeur'):GetValue());
		node:ChangeAttribute('config_PortDecodeur', dlg_ConfigRaceResultWebServeur:GetWindowName('config_PortDecodeur'):GetValue());
		node:ChangeAttribute('config_User', dlg_ConfigRaceResultWebServeur:GetWindowName('config_User'):GetValue());
		node:ChangeAttribute('config_PWD', dlg_ConfigRaceResultWebServeur:GetWindowName('config_PWD'):GetValue());
		node:ChangeAttribute('config_NumFichier',  dlg_ConfigRaceResultWebServeur:GetWindowName('config_NumFichier'):GetValue());
		node:ChangeAttribute('config_Passage', dlg_ConfigRaceResultWebServeur:GetWindowName('config_Passage'):GetValue());
		if dlg_ConfigRaceResultWebServeur:GetWindowName('checkbox_config_Systeme'):GetValue() == true then
			node:ChangeAttribute('SystemeActif',  "1");
		else
			node:ChangeAttribute('SystemeActif',  "0");
		end
		if dlg_ConfigRaceResultWebServeur:GetWindowName('checkbox_config_Lect_Dos'):GetValue() == true then
			node:ChangeAttribute('bib',  "1");
		else
			node:ChangeAttribute('bib',  "0");
		end


		local doc = app.GetXML();
		doc:SaveFile();
		dlg_ConfigRaceResultWebServeur:EndModal(idButton.OK);
	end

		dlg_ConfigRaceResultWebServeur:Bind(eventType.MENU, OnSaveConfig, btnSave); 
		dlg_ConfigRaceResultWebServeur:Bind(eventType.MENU, function(evt) dlg_ConfigRaceResultWebServeur:EndModal(idButton.CANCEL) end, btnClose);

	-- Lancement de la dialog
	dlg_ConfigRaceResultWebServeur:Fit();
	dlg_ConfigRaceResultWebServeur:ShowModal();

	-- Liberation Memoire
	dlg_ConfigRaceResultWebServeur:Delete();
	
	function OnExit(evt)
	dlg_ConfigRaceResultWebServeur:EndModal();
	end
	
end




function OnSaveOption(evt)

	cmd = "Delete From tagID_Tour Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'";
	RaceresultWebServeur.dbSki:Query(cmd);
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
			local passage = Grid_Ligne:GetCellInt('passage', i);
			local Tour = Grid_Ligne:GetCellInt('Tour', i);
		-- Alert("RaceresultWebServeur_option:GetNbRows() = "..Grid_Ligne:GetCell('LoopID', i));
		AddTabletagID_Tour(Code,AdresseIP,bibMini,bibMax,LoopID,LoopCanal,Tour);
		
	end
		Alert("Sauvegarde des lignes ds tagID_Tour éffectuer correctement");
	
	cmd = "Delete From tagID_Passings Where Code = "..RaceresultWebServeur.code_competition.." and AdresseIP = '"..ActiveID.."'";
	RaceresultWebServeur.dbSki:Query(cmd);
	local grid_Param = dlgOptionTable:GetWindowName('grid_Param');
	local Grid_Param = grid_Param:GetTable();
	Alert("RaceresultWebServeur_option:GetNbRows() = "..Grid_Param:GetNbRows());
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

function OnOpenOptions(evt)
-- Création Dialog 

	dlgOptionTable = wnd.CreateDialog({
		parent = RaceresultWebServeur.panel,
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
	cmd = "Select * From tagID_Tour Where Code = '"..RaceresultWebServeur.code_competition.."' and AdresseIP = '"..ActiveID.."' Order by bibMini";
	RaceresultWebServeur.dbSki:TableLoad(TabletagID_Tour, cmd)
	
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

	cmd = "Select * From tagID_Passings Where Code = '"..RaceresultWebServeur.code_competition.."' and AdresseIP = '"..ActiveID.."' Order by Code, LoopID, LoopCanal";
	RaceresultWebServeur.dbSki:TableLoad(TabletagID_Passings, cmd)
	
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
