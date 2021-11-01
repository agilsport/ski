-- Tirage SKIOPEN 
function GetMenuName()
	return "Tirage SKIOPEN";
end

function main(params)
	codeEvenement = params.code_evenement;
	
	codeDiscipline = base:GetTable("Epreuve"):GetCell("Code_discipline", 0);
	
	if codeDiscipline == 'C' then	
		facteur_f = 0.8;
	elseif  codeDiscipline == 'FUS' then
		facteur_f = 1.15;
	else
		facteur_f = 1;
	end

	-- Chargement des Médailles
	tMedaille = base:GetTable("Medaille");
	cmd = "Select * From Medaille Where Code_discipline = '"..codeDiscipline.."' Order By Borne_sup Asc ";
	base:TableLoad(tMedaille, cmd);

	-- Chargement des Concurrents
	tResultat = base:GetTable("Resultat");
	cmd = "Select * From Resultat Where Code_evenement = "..codeEvenement;
	base:TableLoad(tResultat, cmd);
	
	math.randomseed( os.time() );
	for i=0, tResultat:GetNbRows()-1 do
		
		niveau = '';
		ordre_niveau = 999;
		alea = math.random(1, 1000);
		
		point = tResultat:GetCell("Point", i);
		if string.len(point) > 0 then
			point = tonumber(point);
			point = point / facteur_f;

			for j=0, tMedaille:GetNbRows()-1 do
				if point <= tMedaille:GetCellDouble("Borne_sup", j) then
					niveau = tMedaille:GetCell("Libelle", j);
					ordre_niveau = j+1;
					break;
				end
			end 
		end
			
		codeCoureur = tResultat:GetCell("Code_coureur", i);
		cmd = "Update Resultat Set Niveau = '"..niveau.."', Ordre_niveau = "..ordre_niveau..", Reserve = "..alea
			.." Where Code_evenement = "..codeEvenement.." And Code_coureur = '"..codeCoureur.."'" ;
		base:Query(cmd);
	end

	cmd = "Select max(Dossard) Dossard From Resultat Where Code_evenement = "..codeEvenement.." And Dossard Is Not Null";
	dossard = base:SelectInt(cmd, 0) + 1;

	cmd = "Select * From Resultat Where Code_evenement = "..codeEvenement.." And Dossard Is Null Order By Ordre_niveau, Reserve ";
	base:TableLoad(tResultat, cmd);

	for i=0, tResultat:GetNbRows()-1 do
		codeCoureur = tResultat:GetCell("Code_coureur", i);
		cmd = "Update Resultat Set Dossard = "..dossard.." Where Code_evenement = "..codeEvenement.." And Code_coureur = '"..codeCoureur.."'" ;
		base:Query(cmd);
		dossard = dossard + 1;
	end
end