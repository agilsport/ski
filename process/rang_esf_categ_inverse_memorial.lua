dofile('./interface/interface.lua');
-- Liste de Départ : Ordre Inversée par Catégorie
function GetMenuName()
	return "ESF : Liste de départ en M2 pour Mémorial";
end

function main(params)
	code_evenement = params.code_evenement;
	code_manche = params.code_manche;

	tEvenement = base:GetTable("Evenement");
	tResultat = base:GetTable("Resultat");
	tResultat:OrderBy('Niveau, Dossard DESC');
	for i=0, tResultat:GetNbRows()-1 do
		if tResultat:GetCell('Niveau', i):len() == 0 then
			local msg = "Vous avez ajouté au moins un concurrent après le tirage des dossards sans définir le 'Niveau'\n"..
					"correspondant à sa catégorie. Retournez dans la grille des concurrents pour le faire\n"..
					"Ex: Dossard "..tResultat:GetCell('Dossard', i)..' : '..tResultat:GetCell('Nom', i)..' '..tResultat:GetCell('Prenom', i);
			app.GetAuiFrame():MessageBox(msg,
				"Attention !!", 
				msgBoxStyle.OK+msgBoxStyle.ICON_WARNING
				);
			return false;
		end
	end
	local tResultat_Manche = base:GetTable("Resultat_Manche");
	local rResultat_Manche = tResultat_Manche:GetRecord();

	local rang = 0;
	for i=0, tResultat:GetNbRows()-1 do
		rang = rang + 1;
		rResultat_Manche:Set('Code_evenement', tResultat:GetCell('Code_evenement',i));
		rResultat_Manche:Set('Code_coureur', tResultat:GetCell('Code_coureur',i));
		rResultat_Manche:Set('Code_manche', 2);
		rResultat_Manche:Set('Rang', rang);
		base:TableFlush(tResultat_Manche, -1, 'Rang');
	end
	
	app.GetAuiMessage():AddLineSuccess('Liste de départ en M2 pour Mémorial OK ...');
end