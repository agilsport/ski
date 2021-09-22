dofile('./interface/include.lua');

-- Information : Numéro de de Version, Nom, Interface
function device.GetInformation()
	return { version = 1.14, code = 'saut_tablette', name = 'Saut Tablette Notation', class = 'chrono', interface = {} };
end	

-- Ouverture
function device.OnInit(params)

	-- Récupération des infos de la course
	local rc, data = app.SendNotify('<race_load>');
	
	device.Code_evenement = -1;
	device.Code_manche = 1;
	if rc == true then
		device.Code_evenement = data.Code_evenement;
		device.Code_manche = data.Code_manche;
	end

	-- dbSki ...
	device.dbSki = sqlBase.Clone();
	assert(device.dbSki ~= nil);
	
--	adv.Alert('Code_evenement = '..device.Code_evenement..' Code_manche = '..device.Code_manche);

	-- Enregistrement de l'Evenement en cours ...
	local tParametre_Evenement = device.dbSki:GetTable('Parametre_Evenement');
	tParametre_Evenement:GetRecord():Set('Code_param', 'SAUT_EVENEMENT');
	tParametre_Evenement:GetRecord():Set('Libelle_param', tostring(device.Code_evenement));
	device.dbSki:TableFlush(tParametre_Evenement, -1);
				
	-- Notify 
	app.BindNotify("<bib_next>", device.OnNotifyBibNext);
	app.BindNotify("<run_erase>", device.OnNotifyRunErased);

	-- Timer
	local parentFrame = app.GetAuiFrame();
	local tm = timer.Create(parentFrame);
	tm:Start(params.timer_milliseconds or 1500);	-- Temps de scrutation de 1,5 secondes
	parentFrame:Bind(eventType.TIMER, device.OnTimer, tm);
	device.timer = tm;
end

-- Fermeture
function device.OnClose()
	if device.timer ~= nil then
		device.timer:Delete();
	end
end

-- Event Timer
function device.OnTimer(evt)
	local ski = device.dbSki;
	assert(ski ~= nil);
	if ski == nil then return end
	local bib = device.bib;
	if bib == nil then return end
	
	local tResultat_Saut = ski:GetTable('Resultat_Saut');
	
	local cmd = 
		'Select a.* From Resultat_Saut a, Resultat b'..
		' Where a.Code_evenement = '..device.Code_evenement..
		' And a.Code_manche = '..device.Code_manche..
		' And b.Dossard = '..bib..
		' And a.Code_evenement = b.Code_evenement'..
		' And a.Code_coureur = b.Code_coureur';
	ski:TableLoad(tResultat_Saut, cmd);
	
	if tResultat_Saut:GetNbRows() == 1 then
		if device.note == nil then
			device.note = { A = '', B = '', C = '', D = '', E = '' };
		end

		device.SetNote(tResultat_Saut, 'A');
		device.SetNote(tResultat_Saut, 'B');
		device.SetNote(tResultat_Saut, 'C');
		device.SetNote(tResultat_Saut, 'D');
		device.SetNote(tResultat_Saut, 'E');
	end
end	

function device.SetNote(tResultat_Saut, juge)
	if device.note[juge] == tResultat_Saut:GetCell('Note'..juge, 0) then return end

	device.note[juge] = tResultat_Saut:GetCell('Note'..juge, 0);
	app.SendNotify('<bib_note>', { bib = device.bib, note = device.note[juge], judge = juge });
--	adv.Error('OnTimer Juge '..juge..' : Note='..device.note[juge]);
end

-- Notification : <bib_next>
function device.OnNotifyBibNext(key, params)
	assert(key == '<bib_next>');
	
	device.bib = tonumber(params.bib) or 0;
	device.note = nil;

	local ski = device.dbSki;
	assert(ski ~= nil);
	
	-- Enregistrement du Dossard et de la Manche en cours pour les tablettes de Jugement 
	local cmd = 
		"Update Evenement "..
		"Set Id_internet = "..device.bib..","..
		"Etat_inscription = "..device.Code_manche.." "..
		"Where Code = "..device.Code_evenement;
	ski:Query(cmd);
	
	if device.bib <= 0 then return end 

	-- prise device.bib_ranking ...
	local rc, bibLoad = app.SendNotify("<bib_load>", { bib = device.bib });
	if rc and type(bibLoad) == 'table' then
		device.bib_ranking = bibLoad.ranking;
		if device.bib_ranking:GetNbRows() < 1 then return end
		
		-- Création de l'enregistrement Resultat_Saut si il n'existe pas ...
		local Code_coureur = device.bib_ranking:GetCell('Code_coureur',0);

		cmd = 
		"Select * From Resultat_Saut Where Code_evenement = "..device.Code_evenement.." "..
		"And Code_manche = "..device.Code_manche.." "..
		"And Code_coureur = '"..Code_coureur.."' ";
		
		local tResultat_Saut = ski:GetTable('Resultat_Saut');
		ski:TableLoad(tResultat_Saut, cmd);
		if tResultat_Saut:GetNbRows() == 0 then
			cmd = 
			"Insert Into Resultat_Saut (Code_evenement, Code_manche, Code_coureur) Value "..
			"("..device.Code_evenement..","..device.Code_manche..",'"..Code_coureur.."') ";
			ski:Query(cmd);
		end
	end
end

-- Notification : Effacement de la Manche
function device.OnNotifyRunErased(key, params)
	device.bib = nil;
	device.note = nil;
end

function OnRefreshNotation()
	device.note = { A = '', B = '', C = '', D = '', E = '' };
end