-- LIVE Draw par Philippe Guérindon

dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function main()
	if app.GetVersion() >= '4.95' then 
		if app.GetAuiFrame():MessageBox(
			"Vous avez demandé la mise à jour forcée des ressources pour le ski alpin.\nElle comprend la totalité des développements spécifiques.\nVoulez-vous installer les mises à jour ?", 
			"Mise à jour des scripts de Ph.Guérindon",
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
