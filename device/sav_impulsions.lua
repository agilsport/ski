-- Sauvegarde des inpulsions en continu
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.9, 
		name = 'Sauvegarde des impulsions', 
		class = 'tools'
	};
end	

function device.OnConfiguration(node)
	sav = sav or {};
	sav.directory = node:GetAttribute('directory');
	if sav.directory:len() < 2 then
		sav.directory = string.gsub(app.GetPath()..app.GetPathSeparator().."tmp", app.GetPathSeparator(), "/");
	end
	
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgConfig = wnd.CreateDialog({
		width = 400,
		height = 150,
		x = 600,
		y = 200,
		label='Configuration du répertoire de sauvegarde', 
		icon='./res/32x32_param.png'
	});

	dlgConfig:LoadTemplateXML({ 
		xml = './device/sav_impulsions.xml', 	
		node_name = 'root/panel', 			
		node_attr = 'name', 				
		node_value = 'config' 				
	});

	function OnPath()
		local dirDialog = wnd.CreateDirDialog(
			{ parent = dlgConfig },
			"Emplacement du fichier de sauvegarde", 
			sav.directory
		);
		if dirDialog:ShowModal() == idButton.OK then
			sav.directory = string.gsub(dirDialog:GetPath(), app.GetPathSeparator(), "/");
			dlgConfig:GetWindowName('directory'):SetValue(sav.directory);
		end	
		dirDialog:Delete();
	end
	
	function OnSaveConfig()
		sav.directory = dlgConfig:GetWindowName('directory'):GetValue();
		node:ChangeAttribute('directory', sav.directory);
	end

	function OnClose()
		dlgConfig:EndModal(idButton.CANCEL);
	end

	-- Toolbar Principale ...
	local tb = dlgConfig:GetWindowName('tb');
	local btnSave = tb:AddTool("Valider", "./res/32x32_save.png");
	tb:AddStretchableSpace();
	local btnClose = tb:AddTool("Fermer", "./res/32x32_close.png");
	tb:Realize();
	
	dlgConfig:Bind(eventType.BUTTON, function(evt) OnPath() end, dlgConfig:GetWindowName('path'));
	dlgConfig:Bind(eventType.MENU, function(evt) OnSaveConfig() end, btnSave);
	tb:Bind(eventType.MENU, function(evt) OnClose() end, btnClose);
	
	dlgConfig:GetWindowName('directory'):SetValue(sav.directory);

	dlgConfig:ShowModal();
end

-- Ouverture
function device.OnInit(params, node)
	sav = {};
	
	sav.statut = true;
	sav.node = node;
	sav.directory = node:GetAttribute('directory');
	if sav.directory:len() < 2 then
		sav.directory = string.gsub(app.GetPath()..app.GetPathSeparator().."tmp", app.GetPathSeparator(), "/");
	end
	
	sav.statut_image = "./res/chrono32x32_ok.png";
	rc, raceInfo = app.SendNotify('<race_load>');
	if rc == false then
		adv.Error("Erreur Chargement Informations Course ...");
		sav.statut = false;
		return;
	end
	
	sav.code_evenement = raceInfo.tables.Evenement:GetCellInt("Code",0,0);
	sav.code_manche = raceInfo.Code_manche or 1;
	sav.nb_inter = raceInfo.Nb_inter or 0;
	sav.db3 = sav.directory.."/sav"..tostring(sav.code_evenement).."_m"..sav.code_manche..".db3";
	
	-- Ouverture du .db3
	sosDb = sqlBase.ConnectSQLite(sav.db3); 
	if sosDb == nil then
		adv.Error("Erreur : Ouverture du fichier "..sav.db3.." Impossible !");
		return;
	end

	-- Ouverture Ok : on peut continuer ...
	sosDb:Load();
	tResultatChrono = sosDb:GetTable("Resultat_Chrono");
	if tResultatChrono == nil then 
		-- création de la base sav.db3 et création de la table Resultat_Chrono
		sosDb:Delete();
		
		local base = sqlBase.Clone();
		local tResultatChronoSki = base:GetTable("Resultat_Chrono");
		local cmd = "Select * From Resultat_Chrono Where Code_evenement = "..sav.code_evenement.." And Code_manche = "..sav.code_manche;
		base:TableLoad(tResultatChronoSki, cmd);
		local ignoreConstraint = false; -- On veut les primary key ...
		tResultatChronoSki:Snapshot(sav.db3, ignoreConstraint);
	
		sosDb = sqlBase.ConnectSQLite(sav.db3);
		sosDb:Load();
		tResultatChrono = sosDb:GetTable("Resultat_Chrono");
		base:Delete();	
	end

	if tResultatChrono == nil or tResultatChrono:GetIndexColumn("Seq") < 0 then 
		return;
	end
	
	local seq = sosDb:SelectInt("Select Max(Seq) From Resultat_Chrono");

	-- Creation Panel
	panel = wnd.CreatePanel({
		parent = app.GetAuiFrame(),
		style = wndStyle.DEFAULT_PANEL, 
		label='Sauvegarde des impulsions', 
		icon='./res/32x32_param.png'
		})
	panel:LoadTemplateXML({ 
		xml = './device/sav_impulsions.xml', 
		node_name = 'root/panel', 
		node_attr = 'name',
		node_value = 'sav'
	});
	
	-- Affichage ...
	panel:Show(true);
	local mgr = app.GetAuiManager();
	mgr:AddPane(panel, {
		icon = './res/32x32_ffs.png',
		caption = "Sauvegarde des impulsions",
		caption_visible = true,
		close_button = false,
		pin_button = true,
		show = true,
		float = true, 
		floating_position = {981, 25},
		floating_size = {250, 90},
		dockable = false
	});
	mgr:Update();

	local tb = panel:GetWindowName('tb');
	btn_statut = tb:AddTool("Feu vert / Feu rouge", sav.statut_image);
	tb:AddSeparator();
	local btn_recharger = tb:AddTool("Recharger les séquences", "./res/32x32_download.png");
	tb:Realize();
	
	RefreshCompteur(seq)

	-- Prise des Evenements (Bind)
	app.BindNotify("<passage_insert>", OnNotifyPassageInsert);
	app.BindNotify("<passage_update>", OnNotifyPassageUpdate);
	app.BindNotify("<run_erase>", OnRunErase);
	
	panel:Bind(eventType.MENU, OnChangeStatut, btn_statut); 
	panel:Bind(eventType.MENU, OnRechargerSequence, btn_recharger);
	
	adv.Success("Ouverture du fichier "..sav.db3.." Ok ...");
end

function device.OnClose()
	if sosDb ~= nil then
		sosDb:Delete();
	end

	-- Appel OnClose Metatable
	mt_device.OnClose();
end

function OnChangeRepertoire();
	device.OnConfiguration(sav.node)
end

function OnChangeStatut();
	if sav.statut == true then
		sav.statut = false;
		sav.statut_image = "./res/chrono32x32_ko.png";
	else
		sav.statut = true;
		sav.statut_image = "./res/chrono32x32_ok.png";
	end
	local tb = panel:GetWindowName('tb');
	tb:SetToolNormalBitmap(btn_statut, sav.statut_image);
end

function OnRechargerSequence();
	if sav.statut == false then 
		adv.Warning("Feu rouge !!"); 
		return
	end
	if panel:MessageBox("Confirmation du rechargement des séquences ?\nCette opération effacera tous les temps de la manche "..sav.code_manche.."\navant d'effectuer le rechargement des séquences.", "Confirmation du rechargement des séquenses", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	--  rechercher le fichier .db3 des séquences à relire et le charger
	local fileDialog = wnd.CreateFileDialog( 
		{ parent = panel },
		"Sélection du fichier de sauvegarde",
		sav.directory, 
		"",
		"*.db3|*.db3",
		fileDialogStyle.OPEN+fileDialogStyle.FD_FILE_MUST_EXIST
	);
	if fileDialog:ShowModal() ~= idButton.OK then
		fileDialog:Delete();
		return false;
	end
	
	if sosDb ~= nil then
		sosDb:Delete();
		sosDb = nil;
	end

	read_db3 = string.gsub(fileDialog:GetPath(), app.GetPathSeparator(), "/");
	fileDialog:Delete();
	sosDb = sqlBase.ConnectSQLite(read_db3);
	sosDb:Load();

	if sosDb:GetTable('Resultat_Chrono') == nil then
		panel:MessageBox("Le fichier sélectionné n'est pas un fichier valide !\n"..read_db3, "Erreur", msgBoxStyle.OK+msgBoxStyle.ICON_ERROR);
		sosDb:Delete();
		sosDb = nil;
		return false;
	end

	base = sqlBase.Clone();
	cmd = "Delete From Resultat_Chrono Where Code_evenement = "..sav.code_evenement.." And Code_manche = "..sav.code_manche;
	base:Query(cmd);
	
	-- Chargement Table DB3
	local tResultatChrono = sosDb:GetTable('Resultat_Chrono');
	sosDb:TableLoad(tResultatChrono, "Select * From Resultat_Chrono Order By Seq ASC");

	tResultatChronoSki = base:GetTable("Resultat_Chrono");
	rResultatChronoSki = tResultatChronoSki:GetRecord();
	
	for row = 0, tResultatChrono:GetNbRows()-1 do
		rResultatChronoSki:Set('Code_evenement', sav.code_evenement);
		rResultatChronoSki:Set('Code_manche', sav.code_manche);
		rResultatChronoSki:Set('Seq', tResultatChrono:GetCellInt("Seq",row));
		rResultatChronoSki:Set('Origine', tResultatChrono:GetCell("Origine",row));
		rResultatChronoSki:Set('Heure', tResultatChrono:GetCellInt("Heure",row));
		rResultatChronoSki:Set('Dossard', tResultatChrono:GetCell("Dossard",row));
		rResultatChronoSki:Set('Dossard_anc', tResultatChrono:GetCell("Dossard_anc",row));
		rResultatChronoSki:Set('Id', tResultatChrono:GetCellInt("Id",row));
		rResultatChronoSki:Set('Device', tResultatChrono:GetCell("Device",row));
		base:TableInsert(tResultatChronoSki, -1);
	end
	base:Delete();

	RefreshCompteur(sosDb:SelectInt("Select Max(Seq) From Resultat_Chrono"));

	-- ReChargement des Passages dans la fenêtre de chronométrage
	-- à faire un recalcul des temps nets  partir des séquences quelle est la notification à envoyer
	app.SendNotify('<run_reload>'); 
end

function OnRunErase(key, params);
	if sav.statut == false then return end
	if panel:MessageBox("Voulez-vous également effacer les impulsions \ndéjà sauvegardées pour la manche "..sav.code_manche.." ?", "Confirmation de l'effacement de la sauvegerde", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end

	if sosDb ~= nil then
		tResultat_Chrono = sosDb:GetTable('Resultat_Chrono');
		if tResultat_Chrono ~= nil then 
			cmd = "Delete From Resultat_Chrono Where Code_manche = "..sav.code_manche;
			sosDb:Query(cmd);
		end
		RefreshCompteur(0)
	end
end

function OnNotifyPassageInsert(key, params)
	if sav.statut == false then 
		adv.Warning("Feu rouge !!"); 
		return
	end
	seq = tonumber(params.seq);
	local origine = "";
	local heure = tonumber(params.time);
	local bib = params.bib;
	local id = tonumber(params.passage);
	local device = params.device;
	if id == -1 then	-- ça mange pas de pain (compatibilité FFSSSKI ...)
		origine = "A";
	elseif id == 0 then
		origine = "D";
	else	
		origine = tostring(id);
	end
	if params.bib ~= "" then
		cmd = "Insert Into Resultat_Chrono (Code_evenement, Code_manche, Seq, Origine, Heure, Dossard, Dossard_anc, Id, Device) Values("..sav.code_evenement..","..sav.code_manche..","..seq..',"'..origine..'",'..heure..',"'..bib..'", NULL, '..id..',"'..device..'")';
	else
		cmd = "Insert Into Resultat_Chrono (Code_evenement, Code_manche, Seq, Origine, Heure, Dossard, Dossard_anc, Id, Device) Values("..sav.code_evenement..","..sav.code_manche..","..seq..',"'..origine..'",'..heure..', NULL, NULL, '..id..',"'..device..'")';
	end
	
	if sosDb ~= nil then
		sosDb:Query(cmd);
		RefreshCompteur(seq)
	end
end

function OnNotifyPassageUpdate(key, params)
	-- premier passage avec action = bib_deleted 	bib devien NULL et bib va dans Dossard_anc
	-- deuxième passage avec action = bib_inserted	Dossard_anc devient NULL et bib va dans Dossard
	if sav.statut == false then return end
	local bib = params.bib; local seq = tonumber(params.seq); local action = params.change;
	if seq == nil then return end
	if action == "bib_deleted" then
		cmd = "Update Resultat_Chrono Set"..
			" Dossard = NULL"..
			" ,Dossard_anc = '"..bib.."'"..
			" Where Code_manche = "..sav.code_manche.." And Seq = "..seq;
	elseif action == "bib_inserted" then
		if string.len(bib) == 0 then
			cmd = "Update Resultat_Chrono Set"..
				" Dossard = NULL"..
				" Where Code_manche = "..sav.code_manche.." And Seq = "..seq;
		else
			cmd = "Update Resultat_Chrono Set"..
				" Dossard = '"..bib.."'"..
				" Where Code_manche = "..sav.code_manche.." And Seq = "..seq;
		end
	end
	
	-- update de l'impulsion dans la base
	if sosDb ~= nil then
		sosDb:Query(cmd);
	end
end

function RefreshCompteur(seq)
	if seq ~= nil and panel:GetWindowName('sequence') ~= nil then
		panel:GetWindowName('sequence'):SetLabel('Seq : '..tostring(seq));
	end
end
