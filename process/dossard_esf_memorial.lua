dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- transformation des codes FFS en MON
-- affectation des dossards

function GetMenuName()
	return "ESF : Attribution des Dossards en Mémorial";
end

function main(params)
	code_evenement = params.code_evenement;
	tEvenement = base:GetTable("Evenement");
	tCategorie = base:GetTable("Categorie");
	tResultat = base:GetTable("Resultat");
	tMoniteur = base:GetTable("Moniteur");
	base:TableLoad(tMoniteur, 'Select * From Moniteur');
	base:AddColumnOrdreAleatoire(tResultat);
	local cmd = "SELECT * FROM Categorie c WHERE c.Code_entite ='ESF' AND c.code_saison = '"..tEvenement:GetCell('Code_saison', 0).."' AND c.code_grille = 'CHA/ALP' AND c.Ordre < 99";
	base:TableLoad(tCategorie, cmd);
	local msg = "Voulez-vous faire partir toutes les Dames avant les Hommes ? \n"..
				"OUI = Les Dames avant les Hommes.\n"..
				"Non = On intercale les Dames et les Hommes selon les catégories.";
	local reponse =  app.GetAuiFrame():MessageBox(msg,
			"Lancer le tirage", 
			msgBoxStyle.YES+msgBoxStyle.NO+msgBoxStyle.CANCEL+msgBoxStyle.CANCEL_DEFAULT+msgBoxStyle.ICON_WARNING
			);
	if reponse == msgBoxStyle.YES then
		tCategorie:OrderBy('Sexe, An_min');
	elseif reponse == msgBoxStyle.NO then
		tCategorie:OrderBy('An_min, Sexe');
	else
		return false;
	end
	tResultat:OrderBy('An, Sexe');
	local tCode = {};
	local r = -1;
	local bolFFS = false;
	for i = 0, tResultat:GetNbRows() -1 do
		tResultat:SetCellNull('Dossard', i);
		local code_coureur = tResultat:GetCell('Code_coureur', i);
		local sexe = tResultat:GetCell('Sexe', i);
		if string.find(code_coureur, 'FFS') then
			bolFFS = true;
			break;
		end
		local categ = tResultat:GetCell('Categ', i);
		r = tCategorie:GetIndexRow('Code', categ);
		if r and r >= 0 then
			local code = tCategorie:GetCell('Code', r);
			if reponse == msgBoxStyle.NO then
				if code == 'SH' then
					r = r + 1;
				elseif code == 'SD' then
					r = r - 1;
				end
			end
			tResultat:SetCell('Niveau', i, string.format("%.2d", r+1));
		end
	end
	if bolFFS == true then
		msg = 'Vous devez au préalable convertir les codes FFS en code MON !';
		app.GetAuiFrame():MessageBox(msg, "Codes Moniteurs", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		return false;
	end
	tResultat:OrderBy('Niveau, Sexe, Ordre_Aleatoire');

	local dossard = 1;
	for i=0, tResultat:GetNbRows()-1 do
		tResultat:SetCell('Dossard', i, dossard);
		dossard = dossard + 1;
	end
	base:TableBulkUpdate(tResultat, 'Dossard, Niveau', 'Resultat');	
	app.GetAuiMessage():AddLineSuccess('Attribution des Dossards en Mémorial Ok ...');
end