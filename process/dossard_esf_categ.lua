-- Attribution des dossards : Par Ordre de Catégories (ESF)
function GetMenuName()
	return "ESF : Attribution des Dossards par ordre de Catégories";
end

function main(params)
	code_evenement = params.code_evenement;

	local tResultat = base:GetTable("Resultat");

	base:AddColumnOrdreCategorie(tResultat);
	base:AddColumnOrdreAleatoire(tResultat);
	
	tResultat:OrderBy('Sexe, Ordre_Categorie Desc, Ordre_Aleatoire');
	
	local dossard = 1;
	for i=0, tResultat:GetNbRows()-1 do
	
		tResultat:SetCell('Dossard', i, dossard);
		base:TableFlush(tResultat, i, 'Dossard');

		dossard = dossard + 1;
	end
	
	app.GetAuiMessage():AddLineSuccess('Attribution des Dossards par ordre de Catégories Ok ...');
end