-- version 1.1
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function main(params)
	
	body = sqlBase.CreateTableRanking({ 
		code_evenement = params.code_evenement, 
		code_epreuve = params.code_epreuve, 
		code_manche = params.code_manche
	});
	
	-- Filtrage Ticket ...
	for i=body:GetNbRows()-1, 0, -1 do
		CodeCoureur = body:GetCell('Code_coureur', i):sub(1,3);
		if CodeCoureur ~= 'TIC' and CodeCoureur ~= 'EXT' and CodeCoureur ~= 'TMP' then
			body:RemoveRowAt(i);
		end
	end
	
	filename = './tmp/Ticket_Course_'..params.code_evenement..'.txt';
	fileTicket = io.open(filename, "w+");

	tResultatAdresse = base:GetTable('Resultat_Adresse');
	tEpreuve = base:GetTable('Epreuve');

	separator = ';';
	fileTicket:write('Compt.');
	fileTicket:write(separator);
	fileTicket:write('N° de TIC');
	fileTicket:write(separator);
	fileTicket:write('Dos.');
	fileTicket:write(separator);
	fileTicket:write('Identité');
	fileTicket:write(separator);
	fileTicket:write('Sexe');
	fileTicket:write(separator);
	fileTicket:write('Année');
	fileTicket:write(separator);
	fileTicket:write('Nation');
	fileTicket:write(separator);
	fileTicket:write('Status');
	fileTicket:write(separator);
	fileTicket:write('CP');
	fileTicket:write(separator);
	fileTicket:write('Ville');
	fileTicket:write(separator);
	fileTicket:write('Adresse');
	fileTicket:write(separator);
	fileTicket:write('Distance');
	fileTicket:write(separator);
	fileTicket:write(string.char(13));
	
	for i=0, body:GetNbRows()-1 do
	
		cmd = 
			"Select * From Resultat_Adresse Where Code_evenement = "..params.code_evenement..
			" And Code_coureur = '"..body:GetCell('Code_coureur', i).."' "
		;
		base:TableLoad(tResultatAdresse, cmd)
		
		fileTicket:write(tostring(i+1));
		fileTicket:write(separator);
		fileTicket:write(body:GetCell('Code_coureur', i));
		fileTicket:write(separator);
		fileTicket:write(body:GetCell('Dossard', i));
		fileTicket:write(separator);
		fileTicket:write(body:GetCell('Identite', i));
		fileTicket:write(separator);
		fileTicket:write(body:GetCell('Sexe', i));
		fileTicket:write(separator);
		fileTicket:write(body:GetCell('An', i));
		fileTicket:write(separator);
		fileTicket:write(body:GetCell('Nation', i));
		fileTicket:write(separator);
		fileTicket:write(chrono.Status(body:GetCellInt('Tps', i)));
		fileTicket:write(separator);
		fileTicket:write(tResultatAdresse:GetCell('Code_postal', 0));
		fileTicket:write(separator);
		fileTicket:write(tResultatAdresse:GetCell('Ville', 0));
		fileTicket:write(separator);
		fileTicket:write(tResultatAdresse:GetCell('Adresse1', 0));
		fileTicket:write(separator);
		fileTicket:write(body:GetCell('Distance', i));
		fileTicket:write(separator);
		fileTicket:write(tEpreuve:GetCell('Fichier_transfert', 0));
		fileTicket:write(separator);
		fileTicket:write(tEpreuve:GetCell('Date_epreuve', 0));
		fileTicket:write(separator);
		fileTicket:write(string.char(13));
	end
	fileTicket:close();
	
	body:Delete();
	wnd.MessageBox(app.GetParentFrame(), "Création du fichier "..filename..' ...', 'Information');

end
