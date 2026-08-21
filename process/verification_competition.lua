-- Verification Compétition
dofile('./interface/interface.lua');
function main(cparams)
	cparams.code_evenement = cparams.code_evenement or -1;
	if cparams.code_evenement < 0 then
		return;
	end
	app.GetAuiMessage():AddLine("Verification LUA Compétition "..cparams.code_evenement);
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'SELECT * FROM Evenement WHERE Code = '..cparams.code_evenement)
	if tEvenement:GetCell('Code_activite', 0) == 'ALP' then
		if not app.FileExists(app.GetPath().."/process/verification_alpin.lua") then
			local msg = 'Vous devez télécharger un fichier supplémentaire.\nEtes-vous connecté à Internet ?';
			local reponse = app.GetAuiFrame():MessageBox(msg,
					"Téléchargement en attente", 
					msgBoxStyle.YES+msgBoxStyle.NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING
					);
			if reponse == msgBoxStyle.YES then
				app.AutoUpdateResource('https://agilsport.fr/bta_alpin/UpdateScript.zip');
			end
			return;
		end
		dofile(app.GetPath()..'/process/verification_alpin.lua');
		local reponse = verifAlpin(cparams)
		app.GetAuiMessage():AddLine(" ");
		if reponse == true then
			app.GetAuiMessage():AddLineSuccess("La vérification est OK.");
		else
			app.GetAuiMessage():AddLineError("La vérification a montré des erreurs !!!");
		end
	end
end
