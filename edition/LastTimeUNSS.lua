dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- version 1.0

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function main(params)
	theParams = params;

	local widthMax = display:GetSize().width;
	local widthControl = math.floor((widthMax*3)/4);
	local x = math.floor((widthMax-widthControl)/2);

	local heightMax = display:GetSize().height;
	local heightControl = math.floor((heightMax *3) / 4);
	local y = math.floor((heightMax-heightControl)/2);

	base = sqlBase.Clone();
	tResultat = base:GetTable('Resultat');
	tResultat:AddColumn({ name = 'Tps_Equi', label = 'Tps_Equi', type = sqlType.CHRONO });
	code_evenement = tonumber(theParams.code_evenement);
	alert('code_evenement'..code_evenement);

	LectureDonnees()

	
	
	--editionliste(evt, params, base, bodyliste);
	
	-- Fermeture
	--bodyliste:Delete();

end

function OptionNumeric(evt)
	ListEquipe = base:TableLoad(cmd);
	label_Equipe = tonumber(string.sub(ListEquipe:GetCell('Equipe', 0),1));
	lg = ListEquipe:GetCell('Equipe', 0):len();
	if label_Equipe ~= nil and lg <= 2 then
		if label_Equipe >= 0 or  label_Equipe <= 9 then
			-- alert("Type label_Equipe: "..label_Equipe)
			-- alert("equipe numerique");
			tResultat = base:GetTable('Resultat')
			cmd = "Select * From Resultat Where Code_evenement = "..code_evenement..
				" Order by Equipe";
			base:TableLoad(tResultat, cmd);
			Nbparticipant = tonumber(tResultat:GetNbRows());
			for j=0, Nbparticipant-1 do
				local StringFormatEquipe = string.format("%03d", tResultat:GetCell('Equipe', j));
				-- alert("StringFormatEquipe = ."..StringFormatEquipe)
				cmd = "Update Resultat SET Equipe = '"..StringFormatEquipe..
					"' Where Code_evenement = "..tonumber(code_evenement)..
					" And Code_coureur = '"..tResultat:GetCell('Code_coureur', j).."' ";
				base:Query(cmd);
				-- alert("cmd = "..cmd)
				-- StringFormatEquipe = '';
			end
		end 
	end
	cmd = "Select DISTINCT Equipe From Resultat Where Code_evenement = "..code_evenement.." Order by Equipe" 
end

function LectureDonnees(evt)	
	cmd = "Select DISTINCT Equipe From Resultat Where Code_evenement = "..code_evenement.." Order by Equipe" 
	OptionNumeric();
	ListEquipe = base:TableLoad(cmd);
	NbEquipe = tonumber(ListEquipe:GetNbRows());
	alert('NbEquipes: '..ListEquipe:GetNbRows());
	for i=0, NbEquipe-1 do
		NumEquipe = ListEquipe:GetCell('Equipe', i)
		tResultatTempEquip = base:GetTable('Resultat')
		cmd = "Select * From Resultat Where Code_evenement = "..code_evenement..
			" And Equipe = '"..NumEquipe..
			-- "' Order by Dossard "
			"' Order by Tps Desc "
		base:TableLoad(tResultatTempEquip, cmd);
		NbEquiper = tResultatTempEquip:GetNbRows();
		alert('NbEquiper: '..NbEquiper);
		TpsEquipe = tResultatTempEquip:GetCellInt('Tps', 0);

		alert('Equipe: '..tResultatTempEquip:GetCell('Equipe', i)..' / TpsEquipe: '..TpsEquipe);
		tResultatTempEquip:SetCell('Tps_Equi', 0, TpsEquipe);
		cmd = "Update Resultat SET Tps_best = "..TpsEquipe.." Where Code_evenement = "..tonumber(code_evenement)..
			" and Equipe = '"..NumEquipe.."'";
		base:Query(cmd);
		-- alert("cmd = "..cmd)
	end
	
	-- Prise du Classement dans la colonne Resultat.Clt
	cmd =      'SELECT MIN(Dossard) Dossard_min, Equipe, Tps_best, 9999 Clt ';
	cmd = cmd..'FROM Resultat ';
	cmd = cmd..'WHERE Code_evenement = '..code_evenement.. ' And Tps_best > 0 ';
	cmd = cmd..'GROUP BY Equipe, Tps_best';
	tResultatEquipe = base:TableLoad(cmd);
	if tResultatEquipe ~= nil then
--		alert("Count Equipe="..tResultatEquipe:GetNbRows());
		tResultatEquipe:SetRanking('Clt', 'Tps_best');
		
		for i=0,tResultatEquipe:GetNbRows()-1 do
			cmd = "Update Resultat Set Clt = "..tResultatEquipe:GetCell('Clt',i)..
			" Where Code_evenement = "..code_evenement..
			" And Equipe = '"..tResultatEquipe:GetCell('Equipe', i).."' ";
			base:Query(cmd);
		end
		
		tResultatEquipe:Delete();
	end
	
	-- Rechargement final ...
	tResultat = base:GetTable('Resultat')
	cmd = "Select * From Resultat Where Code_evenement = "..code_evenement..
		" Order by Tps_best, Equipe, Tps";
	base:TableLoad(tResultat, cmd);
	Nbparticipant = tonumber(tResultat:GetNbRows());
	bodyliste = tResultat:Copy(false);
	for i=0, Nbparticipant-1 do
	bodyliste:AddRow();
	sqlTable.CopyRow(bodyliste, bodyliste:GetNbRows()-1, tResultat, i);
	end
	
	editionliste(evt, params, base, bodyliste)
end

function editionliste(evt, params, base, bodyliste)
	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/editionFOND.Perso.UNSS.xml',
		node_name = 'edition/report',
		node_attr = 'id',
		node_value = 'res_Tps_Patrouille',
		
		-- parent = dlg,
			
		base = base,
		body = bodyliste,
		
		params = theParams
	});
end
