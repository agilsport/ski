-- LIVE Draw par Philippe Gu�rindon

dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function main()
	if app.GetVersion() >= '4.95' then 
		if app.GetAuiFrame():MessageBox(
			"Vous avez demand� la mise � jour forc�e des ressources pour le ski alpin.\nElle comprend la totalit� des d�veloppements sp�cifiques.\nVoulez-vous installer les mises � jour ?", 
			"Mise � jour des scripts de Ph.Gu�rindon",
			msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
			) == msgBoxStyle.YES then
			local reponse = app.AutoUpdateResource('https://agilsport.fr/bta_alpin/UpdateScript.zip');
			-- local url = ' https://agilsport.fr/bta_alpin/UpdateScript.zip';
			-- Telechargement(url, 'UpdateScript.zip');
		end
	end
	do return end;
end
main();
