-- LIVE Draw par Philippe Gu�rindon

dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function main()
	scrip_version = "1.0"; -- 4.92 pour 2022-2023
	app.GetAuiFrame():MessageBox(
		"Vous avez demand� la mise � jour forc�e des ressources pour le ski alpin.\nValidez le t�l�chargement de la mise � jour dans le message suivant.\nElle comprend la totalit� des d�veloppements sp�cifiques.", 
		"Mise � jour des scripts de Ph.Gu�rindon",
		msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
	if app.GetVersion() >= '5.0' then 
		-- v�rification de l'existence d'une version plus r�cente du script.
		-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2
		indice_return = 1;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt';
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	end
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
	do return end;
end
main();
