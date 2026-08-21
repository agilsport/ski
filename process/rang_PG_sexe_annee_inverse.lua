-- Liste de Départ : Ordre Inversée par Catégorie
dofile('./edition/functionPG.lua');

function GetMenuName()
	return "FFS : Liste de départ: Ordre inversé par sexe et Année de naissance";
end

function main(params)
	code_evenement = params.code_evenement;
	code_manche = params.code_manche;
	adv.Alert('Code_manche = '..code_manche);

	local tRanking = base:GetTable("_ranking_");
	tRanking:OrderBy('Sexe, Annee, Dossard Desc');
	
	local rang = 1;
	local tResultat_Manche = base:GetTable("Resultat_Manche");
	local rResultat_Manche = tResultat_Manche:GetRecord();

	for i=0, tRanking:GetNbRows()-1 do
	
		rResultat_Manche:Set('Code_evenement', tRanking:GetCell('Code_evenement',i));
		rResultat_Manche:Set('Code_coureur', tRanking:GetCell('Code_coureur',i));
		rResultat_Manche:Set('Code_manche', code_manche);
		rResultat_Manche:Set('Rang', rang);
		base:TableFlush(tResultat_Manche, -1, 'Rang');
		
		rang = rang + 1;
	end
	
	app.GetAuiMessage():AddLineSuccess('Liste de départ: Ordre inversé dans les épreuves ok ...');
end