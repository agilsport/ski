dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- function utilisable dans une édition
-- en faisant un dofile('./edition/functionNordique.lua');
-- et en appelan la fonction souhaiter

function GetQualifie_TeamSprint()
	dlg = wnd.CreateDialog({
		x = x,
		y = y,
		width=600, -- widthControl, 
		height=300, -- heightControl,
		style=wndStyle.RESIZE_BORDER+wndStyle.CAPTION+wndStyle.CLOSE_BOX,
		label='Heure Départ Equipier 2 des Team-Sprint', 
		icon='./res/32x32_agil.png'
	});
	PcodeEvenement = base:GetRecord('Evenement'):GetInt('Code');
	app.GetAuiMessage():AddLine("PcodeEvenement="..PcodeEvenement);
	
	EpreuveActive = base:GetRecord('Epreuve'):GetInt('Code_epreuve');
	app.GetAuiMessage():AddLine("EpreuveActive="..EpreuveActive);
	
	PcodeManche = 3;
	
	local NbMancheActive = base:GetRecord('Epreuve'):GetInt('Nombre_de_manche');
	app.GetAuiMessage():AddLine("NbMancheActive="..NbMancheActive);
	if tonumber(NbMancheActive) ~= 2 then
		if dlg:MessageBox("Confirmation de la sortie des éditions des qualifiés team-sprint ?\n\nvous devez aller mettre 2 dans le nomde phase dans les parametres de course.", "Edition equipes des qualifiées en Team Sprint",msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.OK then
			for i=0, body:GetNbRows()-1 do
				body:SetCell('Status_equipe', i, "Pas Qualifié");
				body:SetCell('Tps', i, 0);
				body:SetCell('Clt', i, 0);
			end
		end
	else
		TpsTotal = body:GetCellInt('Tps', 0);
		-- app.GetAuiMessage():AddLine("TpsTotal="..TpsTotal);
		if TpsTotal == '' then
			if dlg:MessageBox("Confirmation de la sortie des éditions des qualifiés team-sprint ?\n\nle Tps est vide le ou les chrono de manche .", "Edition equipes des qualifiées en Team Sprint",msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.OK then
				for i=0, body:GetNbRows()-1 do
					body:SetCell('Status_equipe', i, "Pas Qualifié");
					body:SetCell('Tps', i, 0);
				end
			end
			return;
		else
			if qualif_critere == 0 then
				app.GetAuiMessage():AddLine("je fait juste une édition sans mise a jour de la base");
			else
				app.GetAuiMessage():AddLine("je fait un delete de la table resultat_manche de la manche: "..PcodeManche);
				app.GetAuiMessage():AddLine("de l' epreuve: "..EpreuveActive);
				cmd    =   " Select * From Resultat_Manche";
				cmd = cmd.." Where Code_evenement = "..PcodeEvenement;
				cmd = cmd.." And Medaille = '"..string.format('%02d',EpreuveActive).."'";
				cmd = cmd.." And Code_manche = "..PcodeManche;
				local tReq = base:TableLoad(cmd);
				
				if tReq:GetNbRows() >= 1 then
					app.GetAuiMessage():AddLine("je Vide la table Resultat_Manche");
					cmd =      "Delete from Resultat_Manche";
					cmd = cmd.." Where Code_evenement = "..PcodeEvenement;
					cmd = cmd.." And Code_manche = "..PcodeManche;
					cmd = cmd.." And Medaille = '"..string.format('%02d',EpreuveActive).."'";
					base:Query(cmd);
				else
					app.GetAuiMessage():AddLine("je ne Vide pas la table Resultat_Manche");
				end
			end
			
			for i=0, body:GetNbRows()-1 do
				body:SetCell('Type_qualif', i, body:GetCell('Critere', i):sub(1,1));
				-- app.GetAuiMessage():AddLine("Type_qualif="..body:GetCell('Critere', i):sub(1,1));
			end
			for i=0,body:GetNbRows()-1 do
				if body:GetCell('Critere', i):sub(1,1) == "T" then 
					body:SetCell('Status_equipe', i, "Qualifié");
					epr = body:GetCellInt('Code_epreuve', i)
					ordre_niveau = 0;
					centre = "A";
					--app.GetAuiMessage():AddLine("qualif_critere"..qualif_critere);
					if qualif_critere >= 1 then
						PcodeCoureur = body:GetCell('Code_coureur',i)
						Prang = tonumber(string.format('%02d',epr)..string.format('%03d',i+1));
						-- app.GetAuiMessage():AddLine("Prang="..Prang);
						cmd =      "Insert Into Resultat_Manche (Code_evenement, Code_coureur, Code_manche, Rang, Medaille) values (";
						cmd = cmd..PcodeEvenement;
						cmd = cmd..",'";
						cmd = cmd..PcodeCoureur;
						cmd = cmd.."',"..PcodeManche..",";
						cmd = cmd..Prang..", '";
						cmd = cmd..string.format('%02d',epr).."'";
						cmd = cmd..")";
						base:Query(cmd);
					end
				else
					if body:GetCellInt('Clt',i) ~= 0 then
						ordre_niveau = body:GetCellInt('Clt',i);
						centre = "B";
					else
						centre = "C";
					end
				end
				if qualif_critere >= 1 then
					-- app.GetAuiMessage():AddLine("ordre_niveau = "..body:GetCellInt('Clt',i));
					reserve = tonumber(body:GetCellInt('Tps1',i)) + tonumber(body:GetCellInt('Tps2',i))
					local cmd = "Update Resultat Set Centre = '"..centre.."', Ordre_niveau = "..ordre_niveau..", reserve = "..reserve.." ";
					cmd =  cmd.."Where Code_evenement = "..body:GetCell('Code_evenement',i).." ";
					cmd =  cmd.."And Code_coureur = '"..body:GetCell('Code_coureur',i).."' ";
					base:Query(cmd);
				end
			end
			app.GetAuiMessage():AddLine("Nb de lignes traitée ds le body"..body:GetNbRows());
		end
	end
end

function GetPenalite_Equipier(Pelalite1, m)
	if m == 0 then
		Penalite_Equipier = string.sub(Pelalite1 ,1 ,3);
	elseif m == 1 then
		Penalite_Equipier = string.sub(Pelalite1 ,5 ,7);
	elseif m == 2 then
		Penalite_Equipier = string.sub(Pelalite1 ,9 ,11);
	elseif m == 3 then
		Penalite_Equipier = string.sub(Pelalite1 ,13 ,15);
	elseif m == 4 then
		Penalite_Equipier = string.sub(Pelalite1 ,17 ,19);	
	else
		Penalite_Equipier = string.sub(Pelalite1 ,21 ,33);
	end
	return Penalite_Equipier;
end