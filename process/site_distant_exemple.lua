-- pour inclure la fonction dans le live timing
function ToDoSiteDistant(params)
	-- si le fichier existe dans le répertoire process de skiFFS sur l'ordinateur du chronométreur, on passera dans cette fonction lors de l'envoi de la liste de départ ou de l'effacement de la course (le balai).
	-- N.B. en manche 1, la commance 'Clear' est systématiquement envoyée immédiatement avant la commande 'Raceinfo'.
	-- à chaque fois, la fonction ToDoSiteDistant est appelée en lui passant les paramètres.
	-- Les paramètres passés sont : 
	-- params.Nom, params.Code_saison, params.Date_epreuve, params.Comite, params.Codex
	-- params.Code_manche, params.Action, params.Web, params.Code_entite, params.Target  params.Target contient 'ESF' ou 'FFS' ou 'FIS' ou 'Perso' et params.Web contient le lien vers la page du live de la course.
	-- exemple de ce que vous pourriez mettre dans cette fonction :
	
	-- adv.Alert('params.Target = '..params.Target);	-- vous décommenterez cette ligne pour afficher par exemple le contenu de params.Target en bas à droite de la fenêtre de chronométrage.
	
	local code_comite = "code de votre comite Ex: 'MV'"		-- local code_comite = 'MV';
	if params.Target ~= 'FFS' or params.Code_entite == 'FIS' or params.Comite ~= code_comite then	-- avec un tel filtre, vous ne traitez que les courses FFS de votre comité envoyées sur le live FFS
		return;
	end
	-- Exemple de chaine à transmettre que vous adapterez selon vos besoins
	local chaine = 'Action='..params.Action;	-- params.Action contient soit 'Clear' soit 'Raceinfo'
	chaine = chaine..'&Saison='..params.Saison..'&Date_epreuve='..params.Date_epreuve..'&Code_entite='..params.Code_entite..'&Codex='..params.Codex..'&Web='..params.Web..'&Code_manche='..params.Code_manche..'&Nom='..curl.UrlEncode(params.Nom);	-- curl.UrlEncode vous renvoi une chaine nettoyée OK
	-- pour un script cible getcurl.php à la racine de votre site : 
	local cible = 'https://www.votrecomite.fr/getcurl.php?'..chaine;
	-- vous pouvez recevoir le resultat du post dans la variable locale resultat.
	local resultat = curl.POST(cible, chaine);
	-- il n'est pas indispensable de traiter la variable de retour resultat. En cas d'erreur, skiFFS ne sera pas affecté.
	-- il n'y a pas besoin d'en mettre plus dans cette fonction, vous ferez le traitement de la chaine transmise de votre côté. 
end
