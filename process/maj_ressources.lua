-- LIVE Draw par Philippe Guérindon

dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function main()
	scrip_version = "1.0"; -- 4.92 pour 2022-2023
	app.GetAuiFrame():MessageBox(
		"Vous avez demandé la mise à jour forcée des ressources pour le ski alpin.\nValidez le téléchargement de la mise à jour dans le message suivant.\nElle comprend la totalité des développements spécifiques.", 
		"Mise à jour des scripts de Ph.Guérindon",
		msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
	if app.GetVersion() >= '5.0' then 
		-- vérification de l'existence d'une version plus récente du script.
		-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2
		indice_return = 1;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt';
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	end
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
	do return end;
end
main();
