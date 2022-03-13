-- Dossard FS v.1.0a
	-- atribution des dossard suivant les critere 1 et 2 FIS
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- création de la fenetre et appel du xml pour la mise en page
function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function GetMenuName()
	return "Snénario pour atribution Dossard en FS";
end

--Creation de la table
Dossards_FS = {}

function Alert(txt)
	Dossards_FS.gridMessage:AddLine(txt);
end

function Success(txt)
	Dossards_FS.gridMessage:AddLineSuccess(txt);
end

function Warning(txt)
	Dossards_FS.gridMessage:AddLineWarning(txt);
end

function Error(txt)
	Dossards_FS.gridMessage:AddLineError(txt);
end

function main(params)
	theParams = params;

	local widthMax = display:GetSize().width;
	local widthControl = math.floor((widthMax*3)/4);
	local x = math.floor((widthMax-widthControl)/2);

	local heightMax = display:GetSize().height;
	local heightControl = math.floor((heightMax *3) / 4);
	local y = math.floor((heightMax-heightControl)/2);

	dlg = wnd.CreateDialog({
		x = x,
		y = y,
		width=500, -- widthControl, 
		height=900, -- heightControl, 
		label='Attribution des Dossards en FS', 
		icon='./res/32x32_agil.png'
	});
	
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlg:LoadTemplateXML({ 
		xml = './process/Scenario_Dossards_FS.xml', 		-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'Script_Dossards_FS',			-- Facultatif si le node_name est unique ...	
	});
	
	-- creation du panel
	Dossards_FS.panel = dlg;
	-- creation de la base 
	Dossards_FS.dbSki = sqlBase.Clone();
	
	-- chargement des tables
	tResultat_manche = Dossards_FS.dbSki:GetTable('Resultat_Manche');
	tResultat = Dossards_FS.dbSki:GetTable('Resultat');
	tSeeding_FS = Dossards_FS.dbSki:GetTable('Seeding_FS');
	if tSeeding_FS == nil then
		-- Creation des Tables 
		if Dossards_FS.dbSki:ScriptSQL('./process/Table_Seefing_FS.sql') == true then
			adv.Success("Creation Table Seefing_FS OK");
		else
			adv.Error("Erreur lors création de la Table Seefing_FS OK!!");
			return;
		end
	end
	
	-- création des variables de base
	code_evenement = theParams.code_evenement;
	code_epreuve = theParams.code_epreuve;
	code_manche = theParams.code_manche;
	Organisateur = theParams.Organisateur;
	Club = theParams.Club;
	Comite = theParams.Code_comite;
	codeActivite = theParams.Code_activite;
	
	-- variables de description
	ScriptNom='Dos_FS'
	ScriptVersion='1.0'
	ScriptDate='13/02/2022'
	ScriptAuteur='Stephane'
	ScriptEmail='stephane@ski-auvergne.com'
	ScriptUrl=''
	ScriptDescription="Attribution des Dossards en FS"

	-- Parametres du script !
	
local tb = dlg:GetWindowName('tb');

-- Initialisation des Controles 
	Dossards_FS.gridMessage = dlg:GetWindowName('message');

	FirstBibD = dlg:GetWindowName('FirstBibD'):SetValue(51);
	FirstBibH = dlg:GetWindowName('FirstBibH'):SetValue(1);
	Code_SEEDING = 'SEEDING_2';

	if tb then
		local btn_edition = tb:AddTool('Execution script', './res/16x16_xml.png');
		tb:AddStretchableSpace();
		local btn_maj = tb:AddTool('Mise à jour SEEDING ', './res/16x16_database.png');
		tb:AddStretchableSpace();
		local btn_close = tb:AddTool('Fermer', './res/16x16_close.png');
		tb:Realize();

		tb:Bind(eventType.MENU, Script, btn_edition);
		tb:Bind(eventType.MENU, OnOpenTableSeeding_FS, btn_maj);
		tb:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL); end, btn_close);
	end

-- creation des combo
	-- combo temps
	dlg:GetWindowName('Code_SEEDING'):Clear();
	dlg:GetWindowName('Code_SEEDING'):Append('SEEDING_2');
	dlg:GetWindowName('Code_SEEDING'):Append('SEEDING_3');
	dlg:GetWindowName('Code_SEEDING'):Append('SEEDING_4');
	dlg:GetWindowName('Code_SEEDING'):SetValue(Code_SEEDING);

-- fixation et creation de la boite
	dlg:Fit();
	dlg:ShowModal();
	dlg:Delete();
end

function Dossard_Existant()
	cmd = " Select * From Resultat Where Code_evenement = "..code_evenement.." And Dossard IS NOT NULL Order by Dossard"
	Dossards_FS.dbSki:TableLoad(tResultat, cmd);	
	
	local Nbrow = tonumber(tResultat:GetNbRows());
	-- Alert("tResultat:GetNbRows()."..Nbrow);
	if Nbrow >= 1 then
		return false
	else 
		return true
	end
end

function dos_melee(sexe, Critere, FirstDos, msg);
	Bib = tonumber(FirstDos) or 1;
	cmd = "Select * From Resultat Where Code_evenement = "..code_evenement.." And Sexe = '"..sexe.."' And Critere = '"..Critere.."'";
	Dossards_FS.dbSki:TableLoad(tResultat, cmd);	
	tResultat_Copy = tResultat:Copy();
	tResultat_Copy:OrderRandom();
	msg = msg..'Tirage à la melée pour '..tResultat_Copy:GetNbRows()..' du dossard '..Bib;
	for i = 0, tResultat_Copy:GetNbRows() -1 do
		local code_coureur = tResultat_Copy:GetCell('Code_coureur', i);
		tResultat_Copy:SetCell('Dossard', i, Bib);
		Bib = Bib + 2;
	end
	msg = msg..' au dossard '..Bib-2;
	Alert(msg);
	base:TableBulkUpdate(tResultat_Copy, 'Dossard', 'Resultat');
end
-----Debut du Script
function Script()
	FirstBibD = dlg:GetWindowName('FirstBibD'):GetValue();
	FirstBibH = dlg:GetWindowName('FirstBibH'):GetValue();
	Code_SEEDING = dlg:GetWindowName('Code_SEEDING'):GetValue();
	-- Alert("Code_SEEDING: "..Code_SEEDING);
	if Dossard_Existant() == false then
		Alert("Les dossards sont deja Attribuer ! Lancement impossible.");
		if Dossards_FS.panel:MessageBox("Confirmation de la supression des dossards  ?\n\n Cette opération effecera les dossards et les Critéres dejà affecter et lanceras le script", "Confirmation de la supression", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
			return;
		else
			DeleteDos(Code_SEEDING);
		end
	else 
		Traitement(Code_SEEDING);
	end
	
--Traitement
	Alert('Traitement fini!!!');
	
	Success('Script (v '.. ScriptVersion ..' '.. ScriptDate ..') à été effectuer avec succes');
	if Dossards_FS.dbSki ~= nil then
		Dossards_FS.dbSki:Delete();
	end
end

--Fonctions techniques
function DeleteDos(Code_SEEDING)
	Alert('Effacement des dossards et Critere en court...');
	local Nbrow = tonumber(tResultat:GetNbRows());
	-- Alert("tResultat:GetNbRows()."..Nbrow);
	for i=0,Nbrow-1 do
		cmd = "Update Resultat SET Dossard = Null, Critere = NULL"..
			" Where Code_evenement = "..code_evenement
		Dossards_FS.dbSki:Query(cmd);
	end
	Alert('Effacement des dossards Critere éffectuer!!!');
	Traitement(Code_SEEDING);
end 

function Traitement(Code_SEEDING)
	local Code_SEEDING = Code_SEEDING;
	-- Alert("Code_SEEDING 2: "..Code_SEEDING);
	TraitementCritere(Code_SEEDING);
	TraitementScenario(Code_SEEDING);
end

function TraitementCritere(Code_SEEDING)
	-- Alert("Code_SEEDING: "..Code_SEEDING);
	cmd = "Select * From Resultat Where Code_evenement = "..code_evenement.." And Sexe = 'F' Order By Point Desc, Code_coureur ";
	Dossards_FS.dbSki:TableLoad(tResultat, cmd);	
	NbConcurrent_DossardF = tonumber(tResultat:GetNbRows())
	Alert('Nombre de Femmes = '..NbConcurrent_DossardF);
	for i=0,NbConcurrent_DossardF-1 do
		cmd = "Select * From Seeding_FS Where Code_SEEDING = '"..Code_SEEDING.."' And Place_Points = "..i+1; 
		Dossards_FS.dbSki:TableLoad(tSeeding_FS, cmd);
		NumCritere = tSeeding_FS:GetCell('Critere', 0);
		-- Alert('NumCritere: '..NumCritere);
		cmd = "Update Resultat SET Critere = '"..NumCritere..
			"' Where Code_evenement = "..code_evenement..
			" And Code_coureur = '"..tResultat:GetCell('Code_coureur', i)..
			"'"
		Dossards_FS.dbSki:Query(cmd);
	end
	Alert('Critere Dames ok!!!');
	
	cmd = "Select * From Resultat Where Code_evenement = "..code_evenement.." And Sexe = 'M' Order By Point Desc, Code_coureur ";
	Dossards_FS.dbSki:TableLoad(tResultat, cmd);	
	NbConcurrent_DossardM = tonumber(tResultat:GetNbRows())
	Alert('Nombre d\' Hommes = '..NbConcurrent_DossardM);
	for i=0,NbConcurrent_DossardM-1 do
		cmd = "Select * From Seeding_FS Where Code_SEEDING = '"..Code_SEEDING.."' And Place_Points = "..i+1; 
		Dossards_FS.dbSki:TableLoad(tSeeding_FS, cmd);
		NumCritere = tSeeding_FS:GetCell('Critere', 0);
		-- Alert('NumCritere: '..NumCritere);
		cmd = "Update Resultat SET Critere = '"..NumCritere..
			"' Where Code_evenement = "..code_evenement..
			" And Code_coureur = '"..tResultat:GetCell('Code_coureur', i)..
			"'"
		Dossards_FS.dbSki:Query(cmd);
	end
	Alert('Critere Hommes ok!!!');
end

function TraitementScenario()
	cmd = "Select DISTINCT Critere From Resultat Where Code_evenement = "..code_evenement.." Order by Critere" 
	ListCritere = base:TableLoad(cmd);
	NbCritere = tonumber(ListCritere:GetNbRows());
	Alert('NbCritere: '..ListCritere:GetNbRows());
	
	for i=0,NbCritere-1 do 
-- tirages des dames du critere 1
		local sexe = 'F';
		local Critere = ListCritere:GetCell('Critere', i);
		if i == 0 then
			FirstDos = FirstBibD;
		elseif i == 1 then
			FirstDos = FirstBibD+1;
		elseif i == 1 then
			FirstDos = FirstBibD+2;
		else
			FirstDos = FirstBibD+3;
		end 
		local 	msg = 'Tirage Dames Critere: '..Critere..'\n'
		dos_melee(sexe, Critere, FirstDos, msg);
	end

-- tirages des Hommes du critere 1
	for i=0,NbCritere-1 do 
		local sexe = 'M';
		local Critere = ListCritere:GetCell('Critere', i);
		if i == 0 then
			FirstDos = FirstBibH;
		elseif i == 1 then
			FirstDos = FirstBibH+1;
		elseif i == 1 then
			FirstDos = FirstBibH+2;
		else
			FirstDos = FirstBibH+3;
		end 
		local 	msg = 'Tirage Hommes Critere: '..Critere..'\n'
		dos_melee(sexe, Critere, FirstDos, msg);
	end 
end

-- Création de la boite de dialogue pour la gestion de la table de Seeding
function OnOpenTableSeeding_FS(evt)
	dlgSeeding_FS = wnd.CreateDialog({
		parent = Dossards_FS.panel,
		icon = "./res/32x32_ffs.png",
		label = 'Table de Seeding',
		width = 500,
		height = 600
	});
	
	dlgSeeding_FS:LoadTemplateXML({ 
	xml = './process/Scenario_Dossards_FS.xml',
		node_name = 'root/panel',
		node_attr = 'name', 
		node_value = 'Seeding_Table'
	});

	Table = {};
	function OnClosedlgSeeding_FS(evt)
		dlgSeeding_FS:EndModal();
	end
	
	-- Grid corespondance
	cmd = "Select * From Seeding_FS Order by Code_SEEDING, Place_Points";
	Dossards_FS.dbSki:TableLoad(tSeeding_FS, cmd)

	tSeeding_FS:SetColumn('Code_SEEDING', { label = 'Code-SEEDING.', width = 15 });
	tSeeding_FS:SetColumn('Place_Points', { label = 'Place -> Points.', width = 12 });
	tSeeding_FS:SetColumn('Critere', { label = 'Critere.', width = 12 });
	
	
	local grid = dlgSeeding_FS:GetWindowName('grid_Code_SEEDING');
	grid:Set({
		table_base = tSeeding_FS,
		columns = 'Code_SEEDING, Place_Points, Critere',
		selection_mode = gridSelectionModes.CELLS,
		sortable = false,
		enable_editing = true
	});

	-- Initialisation des Controles
	
	-- ToolBar
	Dossards_FS.tb = dlgSeeding_FS:GetWindowName('tb');
	RaceresultWebServeurTb_Table = Dossards_FS.tb:AddTool("Outils", "./res/32x32_config.png");
		Dossards_FS.tb:AddStretchableSpace();
	RaceresultWebServeurTb_Clear = Dossards_FS.tb:AddTool('Remise à Zéro des Données', './res/32x32_clear.png');
	Dossards_FS.tb:AddStretchableSpace();
	RaceresultWebServeurTb_InsertLigne = Dossards_FS.tb:AddTool("Ajouter une Ligne", "./res/32x32_list_add.png");
	Dossards_FS.tb:AddSeparator();
	RaceresultWebServeurTb_DeleteLigne = Dossards_FS.tb:AddTool("Supprimer une Ligne", "./res/32x32_list_remove.png");
	Dossards_FS.tb:AddSeparator();
	RaceresultWebServeurTb_Save = Dossards_FS.tb:AddTool("Enregistrer", "./res/32x32_save.png");
	Dossards_FS.tb:AddSeparator();
	RaceresultWebServeurTb_Exit = Dossards_FS.tb:AddTool("Quitter", "./res/32x32_exit.png");

	Dossards_FS.tb:Realize();
	
	-- Prise des Evenements (Bind)
	dlgSeeding_FS:Bind(eventType.MENU, OnRaceresultWebServeurOutil);
	dlgSeeding_FS:Bind(eventType.MENU, OnChargeTableSeeding_FS, RaceresultWebServeurTb_Table);
	dlgSeeding_FS:Bind(eventType.MENU, OnClearTableSeeding_FS, RaceresultWebServeurTb_Clear);
	dlgSeeding_FS:Bind(eventType.MENU, OnClosedlgSeeding_FS, RaceresultWebServeurTb_Exit);
	dlgSeeding_FS:Bind(eventType.MENU, OnInsertLigneCor, RaceresultWebServeurTb_InsertLigne);
	dlgSeeding_FS:Bind(eventType.MENU, OnDeleteLigneCor, RaceresultWebServeurTb_DeleteLigne);
	dlgSeeding_FS:Bind(eventType.MENU, OnSaveTableCorres, RaceresultWebServeurTb_Save);

	-- permet de verifier et fixer les choses avt le showmodal (à faire obligatoirement)
	dlgSeeding_FS:Fit();

	-- Affichage Modal
	dlgSeeding_FS:ShowModal();
	
end	

-- Chargement de la table de corespondance
function OnChargeTableSeeding_FS()
	-- recherche si il y a deja une table de corespondance de charger dans la base
	cmd = "Select * From Seeding_FS where Code_SEEDING = '"..Code_SEEDING.."'";
	Dossards_FS.dbSki:TableLoad(tSeeding_FS, cmd)
 
	 if tSeeding_FS:GetNbRows() >= 1 then
		if Dossards_FS.panel:MessageBox("Confirmation de l'effacement de la table de Code_SEEDING ?\n\nCette opération effacera la table actuellement dans la base de donnée \n avant d'effectuer le rechargement de la table.", "Confirmation de l\'effacement de la table Code_SEEDING", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
			return;
		end
		OnClearTableSeeding_FS()
	 end
 
	if Dossards_FS.panel:MessageBox("Confirmation du chargement de la table de corespondance ?\n\nCette opération vas effectuer le chargement de la table.", "Confirmation du chargement des Tag_ID et Dossards", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
--  rechercher le fichier .xls des séquences à relire et le charger
	local fileDialog = wnd.CreateFileDialog(Dossards_FS.panel,
		"Sélection du fichier de Seeding_FS",
		Dossards_FS.directory, 
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
			Alert ('Chargement de la nouvelle table Seeding_FS');
		
		for line in csvFile:lines() do
			local arrayResults = string.Split(line,';');
			-- Alert("arrayResults"..#arrayResults);
			if #arrayResults >= 2 then 
				if arrayResults[1] ~= nil then
				local r = tSeeding_FS:AddRow();
				local C_SEEDING = arrayResults[1]
				local Place_Points = tonumber(arrayResults[2]);
				if arrayResults[1] == 'SEEDING_2' then
					Critere = string.format("%03d", arrayResults[3]);
				else
					Critere = arrayResults[3];
				end
				-- Alert("Critere "..string.format("%03d", arrayResults[3]));
				tSeeding_FS:SetCell("Code_SEEDING", r, C_SEEDING);		
				tSeeding_FS:SetCell("Place_Points", r, Place_Points);
				tSeeding_FS:SetCell("Critere", r, Critere);
				Dossards_FS.dbSki:TableInsert(tSeeding_FS, r);
				end
			end
		end
		csvFile:close();
		
	-- cmd = "Update Seeding_FS SET Code_SEEDING = '"..Code_SEEDING.."' Where Code_SEEDING = "..Code_SEEDING.."'"
	-- Dossards_FS.dbSki:Query(cmd);
	-- local nbLignes = tSeeding_FS:GetNbRows();
		-- Warning("Code_SEEDING : "..nbLignes.." ligne ds la table");
	-- local nbLignes = 0;

	
	-- Rafraichissement de la grille ...
	local grid = dlgSeeding_FS:GetWindowName('grid_Code_SEEDING');
	grid:SynchronizeRows();

end

--Outils:
--Pour Vider une table de corespondance	
function OnClearTableSeeding_FS(evt)
	if Dossards_FS.panel:MessageBox("Confirmation du Vidage de la table de Seeding_FS ?\n\nCette opération effecera le contenue de la table Seeding_FS", "Confirmation du Vidage de la table de Seeding_FS", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	
	cmd = "Delete From Seeding_FS Where Code_SEEDING = '"..Code_SEEDING.."'";
	Dossards_FS.dbSki:Query(cmd);

	-- Rafraichissement de la grille ...
	local grid = dlgSeeding_FS:GetWindowName('grid_Code_SEEDING');
	grid:SynchronizeRows();
end