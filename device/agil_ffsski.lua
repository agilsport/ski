-- AGIL FFSSKI
dofile('./interface/include.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.5, 
		name = 'AGIL FFSSKI', 
		class = 'chrono', 
		interface = { { type='tcp', hostname = '192.168.1.10', port = 64 } } 
	};
end	

-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	-- Test si le Buffer est vide 
	if cb:GetCount() == 0 then	return end

	-- Lecture des Packets 
	while (ReadPacket(cb)) do end
end

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function ReadPacket(cb)
	local count = cb:GetCount();
	if count <= 4 then return false end 

	local pos = 0;
	local flagCloseSocket = cb:GetInt16(pos);	-- Flag indiquant si la socket est toujours ok
	pos = pos + 2;

	-- MFC : Longueur de la Chaine sur 1 Caractere
	local lgNomMachine = cb:GetInt8(pos);
	pos = pos + 1;
	pos = pos + lgNomMachine;	-- Nom de la machine
	
	local codeEvenement = cb:GetInt16(pos);
	pos = pos + 2;

	-- Dossard 
	local bib = cb:GetInt16(pos);
	if bib == 0 then bib = '' end
	pos = pos + 2;

	-- Numéro de Manche
	local run = cb:GetInt16(pos);
	pos = pos + 2;
	
	-- Type de Trame
	local typeTrame = cb:GetInt16(pos);
	pos = pos + 2;

	-- Temps en millisecones
	local tps = cb:GetInt32(pos);
	pos = pos + 4;

	-- Extra Data 
	local data = cb:GetInt32(pos);
	pos = pos + 4;
	local lgDossardExtra = cb:GetInt8(pos);
	pos = pos + 1;
	pos = pos + lgDossardExtra;
	
	if typeTrame == 100 then -- 'd' => Heure de Départ
		AddTimePassage(tps, 0, bib, data);
	elseif typeTrame == 97 then  -- 'a' => Heure d'Arrivée
		AddTimePassage(tps, -1, bib, data);
	elseif typeTrame == 105 then  -- 'i' => Heure Inter 1
		AddTimePassage(tps, 1, bib, data);
	elseif typeTrame == 106 then  -- 'j' => Heure Inter 2
		AddTimePassage(tps, 2, bib, data);
	elseif typeTrame == 42 and tps == -600 then -- '*' Abs
		AddTimePassage(tps, 0, bib, data);
	elseif typeTrame == 42 and tps == -500 then -- '*' Abd
		AddTimePassage(tps, -1, bib, data);
	elseif typeTrame == 65 and tps == -800 then -- 'A' Dsq (Gestion Manuelle)
		AddTimePassage(tps, -1, bib, data);
	elseif typeTrame == 65 and tps == -600 then -- 'A' Abs (Gestion Manuelle)
		AddTimePassage(tps, -1, bib, data);
	elseif typeTrame == 65 and tps == -500 then -- 'A' Abd (Gestion Manuelle)
		AddTimePassage(tps, -1, bib, data);
	elseif typeTrame == 45 then -- '-' Annulation Dossard
		BibRemove(bib, data);
	elseif typeTrame == 36 then -- '$' Annulation Dossard depart
		BibRemove(bib, 0);
	elseif typeTrame == 65 then -- 'A' => Temps Net Arrivée
		AddTimeNet(tps, -1, bib)
	elseif typeTrame == 72 then -- 'H' => Heure de Départ
		AddTimePassage(tps, 0, bib, data);
	elseif typeTrame == 70 then -- 'F' => Heure Arrivée
		AddTimePassage(tps, -1, bib, data);
	elseif typeTrame ~= 84 then -- 'T' => Temps Tournant
		alert("typeTrame inconnu "..typeTrame..',bib='..bib..',tps='..tps);
	end

	-- On a traité le buffer jusqu'à pos ...
	cb:Cut(pos);
	return true;	
end

function AddTimePassage(chrono, passage, bib, data)
	data = data or 0;
	data = tonumber(data);

	if data == 67 then -- 'C' == 67 
		app.SendNotify("<passage_add>", 
			{ time = chrono,  passage = passage, bib = bib, device = 'agil_ffsksi' }
		);
		BibInsert(bib, chrono, passage);
	else
		app.SendNotify("<passage_add>", 
			{ time = chrono,  passage = passage, bib = bib, device = 'agil_ffsksi' }
		);
	end
end

function AddTimeNet(chrono, passage, bib)
	app.SendNotify("<net_time_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'agil_ffsksi' }
	);
end

function BibRemove(bib, passage)
	app.SendNotify("<bib_delete>", 
		{ bib = bib,  passage = passage }
	);
end

function BibInsert(bib, chrono, passage)
	app.SendNotify("<bib_insert>", 
		{ bib = bib,  time = chrono, passage = passage }
	);
end
