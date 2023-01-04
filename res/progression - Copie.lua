-- Synthaxe Progression :
-- Version 4.3 (12/03/2022)
-- Rectif placement en final
-- rajout de dim_min en tab nordique
-- Création d'un niveau KO_Spec pour pouvoir faire des ko30 ou autre spécifique en cas de reclamation ou de repeche ou l'on faire un duel a 7 a la place de 6 par exemple 
-- rajout du KO_12 en 'FOND,ROL'
-- rajout du KO_42 et MontDesc 10 en 'FOND,ROL'
-- Creation du Progression Cut pour tt les tableaux Montée_Descente
-- start~= nil pour eviter un bug ds le proression cut
-- corection d'une possition ds le couloir en Mont_Desc_10

-- clt/duel/tour/ordre/tri : clt (obligatoire ...), duel, tour, ordre (non obligatoires ...)
-- exemple 1 : 12 => 12ième du tour précédent (et de tous les duels)
-- exemple 2 : 2/3 => 2ème du duel 3 du tour précédent
-- exemple 3 : 2/3/1 => 2ème du duel 3 du tour 1
-- exemple 4 : 3/1-5/2/1 => Meilleur Troisième des duels 1 à 5 du tour 2 (1er Lucky Looser)
-- exemple 5 : 3/1-5/2/2 => Deuxième Troisième des duels 1 à 5 du tour 2 (2ème Lucky Looser)
-- exemple 6 : 3/1-5/2/2/qualif => Deuxième Troisième des duels 1 à 5 du tour 2 (2ème Lucky Looser) avec tri sur les temps de Qualification
-- exemple 7 : 3/1-5/2/2/duel => Deuxième Troisième des duels 1 à 5 du tour 2 (2ème Lucky Looser) avec tri sur le temps du duel
-- la valeur par default pour le tri est qualif

function GetLabel3Tours(progression, tour)
	if tour == 1 then return 'Quart de Finale';
	elseif tour == 2 then return 'Demi finale';
	else return 'Finale';
	end
end

function GetLabelTour_Mont_Desc(progression, tour)
	if tour == 1 then return '1er Tour Montée Descente ';
	elseif tour == 2 then return '2ème Tour Montée Descente';
	else return 'Finale tableau Montée Descente';
	end
end

function GetLabelDuel_Mont_Desc(progression, tour, duel)
	return 'Poule \n N°'..tostring(duel);
end

function GetLabelDuelTabA_B(progression, tour, duel)
	if tour == 1 then
		if duel < 6 then 
			return 'Tab A \n Poule: '..tostring(duel);
		else
			return 'Tab B \n Poule: '..tostring(duel)-5;
		end
	elseif tour == 2 then
		if duel < 3 then 
			return 'Tab A \n Poule:'..tostring(duel);
		else
			return 'Tab B \n Poule:'..tostring(duel)-2;
		end
	elseif tour == 3 then
		if duel == 1 then 
			return 'Finale \n Tab A';
		else
			return 'Finale \n Tab B';
		end
	else
		return 'S'..tostring(duel);
	end
end

-- GetLabelTour 'FS' N° duel / 8 ou /4 ou /2 et Big final and Small Final
function GetLabelDuelFS_2Tours(progression, tour, duel)
	if tour == 1 then
		return tostring(duel)..'/2';
	elseif tour == 2 then
		if duel == 1 then 
			return 'Big \n Final';
		else
			return 'Small \n Final';
		end
	end
end

function GetLabelDuelFS_3Tours(progression, tour, duel)
	if tour == 1 then
		return tostring(duel)..'/4';
	elseif tour == 2 then
		return tostring(duel)..'/2';
	elseif tour == 3 then
		if duel == 1 then 
			return 'Big \n Final';
		else
			return 'Small \n Final';
		end
	end
end

function GetLabelDuelFS_4Tours(progression, tour, duel)
	if tour == 1 then
		return tostring(duel)..'/8';
	elseif tour == 2 then
		return tostring(duel)..'/4';
	elseif tour == 3 then
		return tostring(duel)..'/2';
	elseif tour == 4 then
		if duel == 1 then 
			return 'Big \n Final';
		else
			return 'Small \n Final';
		end
	end
end

-- progression cut qui permet de couper le nombre du duel dans les tableaux montée descente 
-- et de mettre la bonne progression aux derniers couloirs des duels
function Getprogression_cut(dim, active_progression)
	local progression = active_progression.progression;
	
	if active_progression ~= nil then
--		app.GetAuiMessage(true):AddLine('OUT DEBUG');
		return;
	end
	
	-- Gestion du Tour 1
	local progression_tour1 = progression[1];

	for j=1, #progression_tour1 do
		local bib = tonumber(progression_tour1[j][1]);

		if bib > dim then
			while #progression_tour1 >= j do
				table.remove(progression_tour1);
			end
			break;
		end
	end
	
	-- Gestions des Tours suivants 
	local nb_tour = #progression;
	-- app.GetAuiMessage(true):AddLine('nb_tour ds progression : '..tostring(nb_tour));
	local nb_duel = #progression_tour1;
	app.GetAuiMessage(true):AddLine('nb_duel tour 1 after Cut : '..tostring(nb_duel));
	for t=2, nb_tour do
		local progression_tour = progression[t];
		-- app.GetAuiMessage(true):AddLine('Cut progression_tour N°: '..tostring(t)..' lg = '..tostring(#progression_tour));
		while #progression_tour > nb_duel do
			table.remove(progression_tour);
			-- app.GetAuiMessage(true):AddLine('progression_tour effacer: '..tostring(#progression_tour));
		end
		-- app.GetAuiMessage(true):AddLine('Cut progression_tour After N°: '..tostring(t)..' lg = '..tostring(#progression_tour));

		for duel=1, #progression_tour do
			local tDuel = progression_tour[duel];
			
			for couloir=1, #tDuel do
				local valProgression = tDuel[couloir];
				local sep = string.find(valProgression, '/');
				-- app.GetAuiMessage(true):AddLine('sep: '..tostring(sep));
				if sep ~= nil then
					local srcDuel = tonumber(string.sub(valProgression, sep+1)) or 0;
					local PosClt = tonumber(string.sub(valProgression, 1, 1)) or 0;
					--app.GetAuiMessage(true):AddLine('PosClt N°: '..PosClt);
					if srcDuel > nb_duel and duel == nb_duel then
						if PosClt == 1 then start = couloir end
						-- app.GetAuiMessage(true):AddLine('srcDuel N°: '..tostring(srcDuel));
						if start ~= nil then
							valProgression = tostring(start)..'/'..tostring(nb_duel);
							tDuel[couloir] = valProgression;
							start = tonumber(start) + 1;
						end
					end
				end
			end
		end
	end
	-- app.GetAuiMessage(true):AddLine('Progression Cut : Dimension ='..tostring(dim));
end

-- Table définissant l'ensemble des progressions ...
duel_progression = {

	-- Spécial Dragon Boat
	drb5 = {
		activite = 'DRB',
		dimension = 5,
		progression = {
			-- tour 1
			{ 
				{'5', '1', '4' }, 
				{ '2', '3' } 
			}, 
			-- tour 2
			{ 
				{'2/2', '1/1', '1/2', '2/1' } 
			}
		}
	},

	drb6 = {
		activite = 'DRB',
		dimension = 6,
		progression = {
			-- tour 1
			{ 
				{'6', '1', '4', '' }, 
				{'5', '2', '3', '' } 
			},
			-- tour 2
			{ 
				{'2/2', '1/1', '1/2', '2/1' }, 
				{ '', '3/1', '3/2', ''  } 
			}
		}
	},

	drb7 = {
		activite = 'DRB',
		dimension = 7,
		progression = {
			-- tour 1
			{ 
				{'7', '1', '4', '5' }, 
				{'6', '2', '3' } 
			},
			-- tour 2
			{ 
				{'2/2', '1/1', '1/2', '2/1'}, 
				{'4/1', '3/1', '3/2'  } 
			}
		}
	},
	
	drb8 = {
		activite = 'DRB',
		dimension = 8,
		progression = {
			-- tour 1
			{ 
				-- tour 1
				{ '8', '1', '4', '5' }, 
				{ '6', '2', '3', '7' } 
			},
			-- tour 2
			{
				{ '2/2', '1/1', '1/2', '2/1'}, 
				{ '4/2', '3/1', '3/2', '4/1' } 
			}
		}
	},

-- Les Tableaux Standards ... ======================================================================>

	std4 = 
	{
		dimension = 4,
		progression = {
			{ 
				-- tour unique: 1 duel de 4 couloirs
				{ '1', '2', '3', '4'}
			},
		}
	},
	
	std6 =
	{
		dimension = 6,
		progression = {
			{ 
				-- tour unique: 1 duel de 6 couloirs
				{ '1', '2', '3', '4', '5', '6' }
			},
		}
	},

	std8 =
	{
		dimension = 8,
		label = { 'Demi Finale', 'Finale' },
		progression = {
			{ 
				-- tour 1 : 2 duels de 4 couloirs
				{ '1', '4', '5', '8' }, 
				{ '2', '3', '6', '7' }
			},
			{
				-- tour 2 : Finale A et Finale B
				{ '1/1', '1/2', '2/1', '2/2' }, 
				{ '3/1', '3/2', '4/1', '4/2' }
			}
		}
	},

	std12 =
	{
		dimension = 12,
		label = { 'Demi Finale', 'Finale' },
		progression = {
			{ 
				-- tour 1 : 2 duels de 6 couloirs
				{ '1', '4', '5', '8',  '9', '12' }, 
				{ '2', '3', '6', '7', '10', '11' }
			},
			{
				-- tour 2 : Finale A et Finale B
				{ '1/1', '1/2', '2/1', '2/2', '3/1', '3/2' }, 
				{ '4/1', '4/2', '5/1', '5/2', '6/1', '6/2' }
			}
		}
	},

	std16 =
	{
		dimension = 16,
		progression = {
			{ 
				-- tour 1 : 4 duels de 4 couloirs
				{ '1', '8',  '9', '16' }, 
				{ '4', '5', '12', '13' },
				{ '3', '6', '11', '14' },
				{ '2', '7', '10', '15' },
			},
			{ 
				-- tour 2 : 2 duels de 4
				{ '1/1', '1/2', '2/2', '2/1'}, 
				{ '1/4', '1/3', '2/3', '2/4' },
			},
			{ 
				-- tour 3 : Finale A et Finale B
				{ '1/1', '1/2', '1/3', '1/4'}, 
				{ '2/1', '2/2', '2/3', '2/4' },
			}
		}
	},

	std24 =
	{
		dimension = 24,
		GetLabelTour = GetLabel3Tours,
		progression = {
			{ 
				-- tour 1 : 4 duels de 6 couloirs
				{ '1', '8',  '9', '16', '17', '24' }, 
				{ '4', '5', '12', '13', '20', '21' },
				{ '3', '6', '11', '14', '19', '22' },
				{ '2', '7', '10', '15', '18', '23' }
			},
			{ 
				-- tour 2 : 2 duels de 6 couloirs
				{ '1/1', '1/2', '2/2', '2/1', '3/1', '3/2' }, 
				{ '1/4', '1/3', '2/3', '2/4', '3/4', '3/3' }
			},
			{ 
				-- tour 3 : Finale A et Finale B
				{ '1/1', '1/2', '2/1', '2/2', '3/1', '3/2' }, 
				{ '4/1', '4/2', '5/1', '5/2', '6/1', '6/2' }
			}
		}
	},

	ko30 =
	{
		dimension = 30,
		progression = {
			{ 
				-- tour 1 : 5 duels de 6 couloirs
				{ '1','10', '11', '20', '21', '30' }, 
				{ '4', '7', '14', '17', '24', '27' },
				{ '5', '6', '15', '16', '25', '26' },
				{ '2', '9', '12', '19', '22', '29' },
				{ '3', '8', '13', '18', '23', '28' },
			},
			{ 
				-- tour 2 : 2 duels de 6 couloirs
				{ '1/1', '1/2', '1/3', '2/2', '2/1', '3/1-5/2/1' }, 
				{ '1/4', '1/5', '2/3', '2/4', '2/4', '3/1-5/2/2' }
			},
			{ 
				-- tour 3 : Finale A et Finale B
				{ '1/1', '1/2', '2/1', '2/2', '3/1', '3/2' }, 
				{ '4/1', '4/2', '5/1', '5/2', '6/1', '6/2' }
			}
		}
	},

	std32 =
	{
		dimension = 32,
		label = { '8ième de finale', 'Quart de Finale', 'Demi Finale', 'Finale' },
		progression = {
			{ 
				-- tour 1 : 8 duels de 4 couloirs
				{ '1', '16', '17', '32' }, 
				{ '8',  '9', '24', '25' },
				{ '5', '12', '21', '28' },
				{ '4', '13', '20', '29' },
				{ '3', '14', '19', '30' },
				{ '6', '11', '22', '27' },
				{ '7', '10', '23', '26' },
				{ '2', '15', '18', '31' }
			},
			{ 
				-- tour 2 : 4 duels de 4 couloirs
				{ '1/1', '1/2',  '2/2', '2/1' }, 
				{ '1/4', '1/3', '2/3', '2/4' },
				{ '1/5', '1/6', '2/6', '2/5' },
				{ '1/8', '1/7', '2/7', '2/8' },
			},
			{ 
				-- tour 3 : 2 duels de 4 couloirs
				{ '1/1', '1/2', '2/2', '2/1'}, 
				{ '1/4', '1/3', '2/3', '2/4' },
			},
			{
				-- tour 4 : Finale A et finale B
				{ '1/1', '1/2', '1/3', '1/4'}, 
				{ '2/1', '2/2', '2/3', '2/4' }
			}
		}
	},

	std48 =
	{
		dimension = 48,
		progression = {
			{ 
				-- tour 1 : 8 duels de 6 couloirs
				{ '1', '16', '24', '32', '40', '48' }, 
				{ '8', '9', '17', '25', '33', '41' },
				{ '6', '11', '19', '27', '35', '43' },
				{ '4', '13', '21', '29', '37', '45' },
				{ '3', '14', '22', '30', '38', '46' },
				{ '5', '12', '20', '28', '36', '44' },
				{ '7', '10', '18', '26', '34', '42' },
				{ '2', '15', '23', '31', '39', '47' }
			},
			{ 
				-- tour 2 : 4 duels de 6 couloirs
				{ '1/1', '1/2', '2/2', '2/1', '3/2', '3/1' }, 
				{ '1/4', '1/3', '2/3', '2/4', '3/4', '3/3' },
				{ '1/5', '1/6', '2/6', '2/5', '3/6', '3/5' },
				{ '1/8', '1/7', '2/7', '2/8', '3/8', '3/7' },
			},
			{ 
				-- tour 3 : 2 duels de 6 couloirs
				{ '1/1', '1/2', '2/2', '2/1', '3/1', '3/2' }, 
				{ '1/4', '1/3', '2/3', '2/4', '3/4', '3/3' }
			},
			{ 
				-- tour 4 : Finale A et Finale B
				{ '1/1', '1/2', '2/1', '2/2', '3/1', '3/2' }, 
				{ '4/1', '4/2', '5/1', '5/2', '6/1', '6/2' }
			}
		}
	},
	
-- Tableau type FreeStyle   ------------------------------------------------->>

	FS_4 = 
	{
		dimension = 4,
		dimension_min = 2,
		activite = 'SB,FS',
		label = { 'Finale' },
		progression = {
			{ 
				-- tour unique: 1 duel de 4 couloirs
				{ '1', '2', '3', '4'}
			},
		}
	},

	FS_8 =
	{
		dimension = 8,
		dimension_min = 7,
		activite = 'SB,FS',
		label = { 'Demi Finale', 'Finale' },
		GetLabelDuel = GetLabelDuelFS_2Tours,
		progression = {
			{ 
				-- tour 1 : 2 duels de 4 couloirs
				{ '1', '4', '5', '8' }, 
				{ '2', '3', '6', '7' }
			},
			{
				-- tour 2 : Finale A et Finale B
				{ '1-2/1-2/1/1', '1-2/1-2/1/2', '1-2/1-2/1/3', '1-2/1-2/1/4'}, 
				{ '3-4/1-2/1/1', '3-4/1-2/1/2', '3-4/1-2/1/3', '3-4/1-2/1/4'}
			}
		}
	},

	FS_12 =
	{
		dimension = 12,
		dimension_min = 10,
		activite = 'SB,FS',
		niveau = 'Duel_6',
		label = { 'Demi Finale', 'Finale' },
		GetLabelDuel = GetLabelDuelFS_2Tours,
		progression = {
			{ 
				-- tour 1 : 2 duels de 6 couloirs
				{ '1', '4', '5', '8',  '9', '12' }, 
				{ '2', '3', '6', '7', '10', '11' }
			},
			{
				-- tour 2 : Finale A et Finale B
				{ '1-3/1-2/1/1', '1-3/1-2/1/2', '1-3/1-2/1/3', '1-3/1-2/1/4', '1-3/1-2/1/5', '1-3/1-2/1/6'}, 
				{ '4-6/1-2/1/1', '4-6/1-2/1/2', '4-6/1-2/1/3', '4-6/1-2/1/4', '4-6/1-2/1/5', '4-6/1-2/1/6'}
			}
		}
	},
	
	FS_16 =
	{
		dimension = 16,
		dimension_min = 9,
		activite = 'SB,FS',
		GetLabelTour = GetLabel3Tours,
		GetLabelDuel = GetLabelDuelFS_3Tours,
		progression = {
			{ 
				-- tour 1 : 4 duels de 4 couloirs
				{ '1', '8',  '9', '16' }, 
				{ '4', '5', '12', '13' },
				{ '3', '6', '11', '14' },
				{ '2', '7', '10', '15' },
			},
			{ 
				-- tour 2 : 2 duels de 4
				{ '1-2/1-2/1/1', '1-2/1-2/1/2', '1-2/1-2/1/3', '1-2/1-2/1/4' }, 
				{ '1-2/3-4/1/1', '1-2/3-4/1/2', '1-2/3-4/1/3', '1-2/3-4/1/4' }
			},
			{ 
				-- tour 3 : Finale A et Finale B
				{ '1-2/1-2/2/1', '1-2/1-2/2/2', '1-2/1-2/2/3', '1-2/1-2/2/4'}, 
				{ '3-4/1-2/2/1', '3-4/1-2/2/2', '3-4/1-2/2/3', '3-4/1-2/2/4'}
			}
		}
	},

	FS_24 =
	{
		dimension = 24,
		dimension_min = 20,
		activite = 'SB,FS',
		niveau = 'Duel_6',
		GetLabelTour = GetLabel3Tours,
		GetLabelDuel = GetLabelDuelFS_3Tours,
		progression = {
			{ 
				-- tour 1 : 4 duels de 6 couloirs
				{ '1', '8',  '9', '16', '17', '24' }, 
				{ '4', '5', '12', '13', '20', '21' },
				{ '3', '6', '11', '14', '19', '22' },
				{ '2', '7', '10', '15', '18', '23' }
			},
			{ 
				-- tour 2 : 2 duels de 6 couloirs
				{ '1-3/1-2/1/1', '1-3/1-2/1/2', '1-3/1-2/1/3', '1-3/1-2/1/4', '1-3/1-2/1/5', '1-3/1-2/1/6'}, 
				{ '1-3/3-4/1/1', '1-3/3-4/1/2', '1-3/3-4/1/3', '1-3/3-4/1/4', '1-3/3-4/1/5', '1-3/3-4/1/6'}
			},
			{ 
				-- tour 3 : Finale A et Finale B
				{ '1-3/1-2/2/1', '1-3/1-2/2/2', '1-3/1-2/2/3', '1-3/1-2/2/4', '1-3/1-2/2/5', '1-3/1-2/2/6'}, 
				{ '4-6/1-2/2/1', '4-6/1-2/2/2', '4-6/1-2/2/3', '4-6/1-2/2/4', '4-6/1-2/2/5', '4-6/1-2/2/6'}
			}
		}
	},

	FS_32 =
	{
		dimension = 32,
		dimension_min = 17,
		activite = 'SB,FS',
		label = { '8ième de finale', 'Quart de Finale', 'Demi Finale', 'Finale' },
		GetLabelDuel = GetLabelDuelFS_4Tours,
		progression = {
			{ 
				-- tour 1 : 8 duels de 4 couloirs
				{ '1', '16', '17', '32' }, 
				{ '8',  '9', '24', '25' },
				{ '5', '12', '21', '28' },
				{ '4', '13', '20', '29' },
				{ '3', '14', '19', '30' },
				{ '6', '11', '22', '27' },
				{ '7', '10', '23', '26' },
				{ '2', '15', '18', '31' }
			},
			{ 
				-- tour 2 : 4 duels de 4 couloirs
				{ '1-2/1-2/1/1', '1-2/1-2/1/2',  '1-2/1-2/1/3', '1-2/1-2/1/4' }, 
				{ '1-2/3-4/1/1', '1-2/3-4/1/2',  '1-2/3-4/1/3', '1-2/3-4/1/4' }, 
				{ '1-2/5-6/1/1', '1-2/5-6/1/2',  '1-2/5-6/1/3', '1-2/5-6/1/4' }, 
				{ '1-2/7-8/1/1', '1-2/7-8/1/2',  '1-2/7-8/1/3', '1-2/7-8/1/4' }
			},
			{ 
				-- tour 3 : 2 duels de 4 couloirs
				{ '1-2/1-2/2/1', '1-2/1-2/2/2', '1-2/1-2/2/3', '1-2/1-2/2/4' }, 
				{ '1-2/3-4/2/1', '1-2/3-4/2/2', '1-2/3-4/2/3', '1-2/3-4/2/4' }
			},
			{
				-- tour 4 : Finale A et finale B
				{ '1-2/1-2/3/1', '1-2/1-2/3/2', '1-2/1-2/3/3', '1-2/1-2/3/4' }, 
				{ '3-4/1-2/3/1', '3-4/1-2/3/2', '3-4/1-2/3/3', '3-4/1-2/3/4' }
			}
		}
	},
	
	FS_CONS_16 =
	{
		dimension = 16,
		activite = 'SB,FS',
		niveau = 'Cons_16',
		GetLabelTour = GetLabel2Tours,
		GetLabelDuel = GetLabelDuelFS_2Tours,
		progression = {
			{ 
				-- tour 1 : 8 duels de 4 couloirs
				{ '1', '8',  '9', '16' }, 
				{ '4', '5', '12', '13' },
				{ '3', '6', '11', '14' },
				{ '2', '7', '10', '15' },
			},
			{ 
				-- tour 3 : Finale A et finale B
				{ '1/1-4/1/1', '1/1-4/1/2', '1/1-4/1/3', '1/1-4/1/4' }, 
				{ '2/1-4/1/1', '2/1-4/1/2', '2/1-4/1/3', '2/1-4/1/4' }
			}
		}
	},	
	
	FS_CONS_32 =
	{
		dimension = 32,
		activite = 'SB,FS',
		niveau = 'Cons_32',
		GetLabelTour = GetLabel3Tours,
		GetLabelDuel = GetLabelDuelFS_3Tours,
		progression = {
			{ 
				-- tour 1 : 8 duels de 4 couloirs
				{ '1', '16', '17', '32' }, 
				{ '8',  '9', '24', '25' },
				{ '5', '12', '21', '28' },
				{ '4', '13', '20', '29' },
				{ '3', '14', '19', '30' },
				{ '6', '11', '22', '27' },
				{ '7', '10', '23', '26' },
				{ '2', '15', '18', '31' }
			},
			{ 
				-- tour 2 : 4 duels de 4 couloirs
				{ '1/1-4/1/1', '1/1-4/1/2',  '1/1-4/1/3', '1/1-4/1/4' }, 
				{ '1/5-8/1/1', '1/5-8/1/2',  '1/5-8/1/3', '1/5-8/1/4' }
			},
			{ 
				-- tour 3 : Finale A et finale B
				{ '1-2/1-2/2/1', '1-2/1-2/2/2', '1-2/1-2/2/3', '1-2/1-2/2/4' }, 
				{ '3-4/1-2/2/1', '3-4/1-2/2/2', '3-4/1-2/2/3', '3-4/1-2/2/4' }
			}
		}
	},	
	
	FS_48 =
	{
		dimension = 48,
		dimension_min = 41,
		activite = 'SB,FS',
		niveau = 'Duel_6',
		label = { '8ième de finale', 'Quart de Finale', 'Demi Finale', 'Finale' },
		GetLabelDuel = GetLabelDuelFS_4Tours,
		progression = {
			{ 
				-- tour 1 : 8 duels de 6 couloirs
				{ '1', '16', '24', '32', '40', '48' }, 
				{ '8', '9', '17', '25', '33', '41' },
				{ '6', '11', '19', '27', '35', '43' },
				{ '4', '13', '21', '29', '37', '45' },
				{ '3', '14', '22', '30', '38', '46' },
				{ '5', '12', '20', '28', '36', '44' },
				{ '7', '10', '18', '26', '34', '42' },
				{ '2', '15', '23', '31', '39', '47' }
			},
			{ 
				-- tour 2 : 4 duels de 6 couloirs
				{ '1-3/1-2/1/1', '1-3/1-2/1/2', '1-3/1-2/1/3', '1-3/1-2/1/4', '1-3/1-2/1/5', '1-3/1-2/1/6'}, 
				{ '1-3/3-4/1/1', '1-3/3-4/1/2', '1-3/3-4/1/3', '1-3/3-4/1/4', '1-3/3-4/1/5', '1-3/3-4/1/6'},
				{ '1-3/5-6/1/1', '1-3/5-6/1/2', '1-3/5-6/1/3', '1-3/5-6/1/4', '1-3/5-6/1/5', '1-3/5-6/1/6'}, 
				{ '1-3/7-8/1/1', '1-3/7-8/1/2', '1-3/7-8/1/3', '1-3/7-8/1/4', '1-3/7-8/1/5', '1-3/7-8/1/6'}
			},
			{ 
				-- tour 3 : 2 duels de 6 couloirs
				{ '1-3/1-2/1/1', '1-3/1-2/1/2', '1-3/1-2/1/3', '1-3/1-2/1/4', '1-3/1-2/1/5', '1-3/1-2/1/6'}, 
				{ '1-3/3-4/1/1', '1-3/3-4/1/2', '1-3/3-4/1/3', '1-3/3-4/1/4', '1-3/3-4/1/5', '1-3/3-4/1/6'}
			},
			{ 
				-- tour 4 : Finale A et Finale B
				{ '1-3/1-2/2/1', '1-3/1-2/2/2', '1-3/1-2/2/3', '1-3/1-2/2/4', '1-3/1-2/2/5', '1-3/1-2/2/6'}, 
				{ '4-6/1-2/2/1', '4-6/1-2/2/2', '4-6/1-2/2/3', '4-6/1-2/2/4', '4-6/1-2/2/5', '4-6/1-2/2/6'}
			}
		}
	},
	
	FS_64 =
	{
		dimension = 64,
		dimension_min = 50,
		activite = 'SB,FS',
		label = { '8ième de finale', 'Quart de Finale', 'Demi Finale', 'Finale' },
		GetLabelDuel = GetLabelDuelFS_4Tours,
		progression = {
			{ 
				-- tour 1 : 8 duels de 4 couloirs
				{ '1', '16', '17', '32' }, 
				{ '8',  '9', '24', '25' },
				{ '5', '12', '21', '28' },
				{ '4', '13', '20', '29' },
				{ '3', '14', '19', '30' },
				{ '6', '11', '22', '27' },
				{ '7', '10', '23', '26' },
				{ '2', '15', '18', '31' }
			},
			{ 
				-- tour 2 : 4 duels de 4 couloirs
				{ '1-2/1-2/1/1', '1-2/1-2/1/2',  '1-2/1-2/1/3', '1-2/1-2/1/4' }, 
				{ '1-2/3-4/1/1', '1-2/3-4/1/2',  '1-2/3-4/1/3', '1-2/3-4/1/4' }, 
				{ '1-2/5-6/1/1', '1-2/5-6/1/2',  '1-2/5-6/1/3', '1-2/5-6/1/4' }, 
				{ '1-2/7-8/1/1', '1-2/7-8/1/2',  '1-2/7-8/1/3', '1-2/7-8/1/4' }
			},
			{ 
				-- tour 3 : 2 duels de 4 couloirs
				{ '1-2/1-2/2/1', '1-2/1-2/2/2', '1-2/1-2/2/3', '1-2/1-2/2/4' }, 
				{ '1-2/3-4/2/1', '1-2/3-4/2/2', '1-2/3-4/2/3', '1-2/3-4/2/4' }
			},
			{
				-- tour 4 : Finale A et finale B
				{ '1-2/1-2/3/1', '1-2/1-2/3/2', '1-2/1-2/3/3', '1-2/1-2/3/4' }, 
				{ '3-4/1-2/3/1', '3-4/1-2/3/2', '3-4/1-2/3/3', '3-4/1-2/3/4' }
			}
		}
	},
	
	FS_96 =
	{
		dimension = 96,
		dimension_min = 66,
		activite = 'SB,FS',
		niveau = 'Duel_6',
		label = { '8ième de finale', 'Quart de Finale', 'Demi Finale', 'Finale' },
		GetLabelDuel = GetLabelDuelFS_4Tours,
		progression = {
			{ 
				-- tour 1 : 8 duels de 6 couloirs
				{ '1', '32', '33', '64', '65', '96' }, 
				{ '16', '17', '48', '49', '80', '81' },
				{ '9', '24', '41', '56', '73', '88' },
				{ '8', '25', '40', '57', '72', '89' },
				{ '5', '28', '37', '60', '69', '92' },
				{ '12', '21', '44', '53', '76', '85' },
				{ '13', '20', '45', '52', '77', '84' },
				{ '4', '29', '36', '61', '68', '93' },
				{ '3', '30', '35', '62', '67', '94' }, 
				{ '14', '19', '46', '51', '78', '83' },
				{ '11', '22', '43', '54', '75', '86' },
				{ '6', '27', '38', '59', '70', '91' },
				{ '7', '26', '39', '58', '71', '90' },
				{ '10', '18', '42', '55', '74', '87' },
				{ '15', '31', '47', '50', '79', '82' },
				{ '15', '31', '34', '63', '39', '95' }
			},
			{ 
				-- tour 4 : 4 duels de 6 couloirs
				{ '1-3/1-2/1/1', '1-3/1-2/1/2', '1-3/1-2/1/3', '1-3/1-2/1/4', '1-3/1-2/1/5', '1-3/1-2/1/6'}, 
				{ '1-3/3-4/1/1', '1-3/3-4/1/2', '1-3/3-4/1/3', '1-3/3-4/1/4', '1-3/3-4/1/5', '1-3/3-4/1/6'},
				{ '1-3/5-6/1/1', '1-3/5-6/1/2', '1-3/5-6/1/3', '1-3/5-6/1/4', '1-3/5-6/1/5', '1-3/5-6/1/6'}, 
				{ '1-3/7-8/1/1', '1-3/7-8/1/2', '1-3/7-8/1/3', '1-3/7-8/1/4', '1-3/7-8/1/5', '1-3/7-8/1/6'},
				{ '1-3/9-10/1/1', '1-3/9-10/1/2', '1-3/9-10/1/3', '1-3/9-10/1/4', '1-3/9-10/1/5', '1-3/9-10/1/6'}, 
				{ '1-3/11-12/1/1', '1-3/11-12/1/2', '1-3/11-12/1/3', '1-3/11-12/1/4', '1-3/11-12/1/5', '1-3/11-12/1/6'},
				{ '1-3/13-14/1/1', '1-3/13-14/1/2', '1-3/31-14/1/3', '1-3/13-14/1/4', '1-3/13-14/1/5', '1-3/13-14/1/6'}, 
				{ '1-3/15-16/1/1', '1-3/15-16/1/2', '1-3/15-16/1/3', '1-3/15-16/1/4', '1-3/15-16/1/5', '1-3/15-16/1/6'}
			},
			{ 
				-- tour 4 : 4 duels de 6 couloirs
				{ '1-3/1-2/1/1', '1-3/1-2/1/2', '1-3/1-2/1/3', '1-3/1-2/1/4', '1-3/1-2/1/5', '1-3/1-2/1/6'}, 
				{ '1-3/3-4/1/1', '1-3/3-4/1/2', '1-3/3-4/1/3', '1-3/3-4/1/4', '1-3/3-4/1/5', '1-3/3-4/1/6'},
				{ '1-3/5-6/1/1', '1-3/5-6/1/2', '1-3/5-6/1/3', '1-3/5-6/1/4', '1-3/5-6/1/5', '1-3/5-6/1/6'}, 
				{ '1-3/7-8/1/1', '1-3/7-8/1/2', '1-3/7-8/1/3', '1-3/7-8/1/4', '1-3/7-8/1/5', '1-3/7-8/1/6'}
			},
			{ 
				-- tour 5 : 2 duels de 6 couloirs
				{ '1-3/1-2/1/1', '1-3/1-2/1/2', '1-3/1-2/1/3', '1-3/1-2/1/4', '1-3/1-2/1/5', '1-3/1-2/1/6'}, 
				{ '1-3/3-4/1/1', '1-3/3-4/1/2', '1-3/3-4/1/3', '1-3/3-4/1/4', '1-3/3-4/1/5', '1-3/3-4/1/6'}
			},
			{ 
				-- tour 6 : Finale A et Finale B
				{ '1-3/1-2/2/1', '1-3/1-2/2/2', '1-3/1-2/2/3', '1-3/1-2/2/4', '1-3/1-2/2/5', '1-3/1-2/2/6'}, 
				{ '4-6/1-2/2/1', '4-6/1-2/2/2', '4-6/1-2/2/3', '4-6/1-2/2/4', '4-6/1-2/2/5', '4-6/1-2/2/6'}
			}
		}
	},
	
------ Tableau type nordique ------------------------------------------------->>

	KO_6 =
	{
		dimension = 6,
		dimension_min = 4,
		activite = 'FOND,ROL',
		progression = {
			{ 
				-- tour unique: 1 duel de 6 couloirs
				{ '1', '2', '3', '4', '5', '6' }
			},
		}
	},

	KO_8 =
	{
		dimension = 8,
		dimension_min = 7,
		activite = 'FOND,ROL',
		label = { 'Demi Finale', 'Finale' },
		progression = {
			{ 
				-- tour 1 : 2 duels de 4 couloirs
				{ '1', '4', '5', '8' }, 
				{ '2', '3', '6', '7' }
			},
			{
				-- tour 2 : Finale A et Finale B
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2' }, 
				{ '4/1-2/2/1', '4/1-2/2/2', '5/1-2/2/1', '5/1-2/2/2' }
			}
		}
	},

	KO_12_3T =
	{
		dimension = 12,
		dimension_min = 9,
		niveau = 'KO_12_3T',
		--label = { 'Quart de Finale', 'Demi Finale', 'Finale' },
		GetLabelTour = GetLabel3Tours,

		progression = {
			{ 
				-- tour 1 :  Quart de final => 5 duels de 4 couloirs
				{ '1', '4', '5', '7', '10', '12' }, 
				{ '2', '3', '6', '8', '9', '11' }
			},
			{ 
				-- tour 2 : demie finale => 2 duels de 6 couloirs
				{ '1/1', '2/1', '3/1', '4/1' }, 
				{ '1/2', '2/2', '3/2', '4/2' }
			},
			{ 
				-- tour  : Finale A et Finale B => 2 duel de 6 couloirs 3/1-5/2/1 => Meilleur Troisième des duels 1 à 5 du tour 2 
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2', '3/1-2/2/1', '3/1-2/2/2'}
				--{ '4/1-2/2/1', '4/1-2/2/2', '5/1-2/2/1', '5/1-2/2/2', '6/1-2/2/1', '6/1-2/2/2'}
			}
		}
	},

	KO_12 =
	{
		dimension = 12,
		dimension_min = 9,
		activite = 'FOND,ROL',
		niveau = '!KO_12_3T',	-- tous les niveaux sauf KO_12_3T ...
	
		label = { 'Demi Finale', 'Finale' },
		progression = {
			{ 
				-- tour 1 : 2 duels de 6 couloirs
				{ '1', '4', '5', '8',  '9', '12' }, 
				{ '2', '3', '6', '7', '10', '11' }
			},
			{
				-- tour 2 : Finale A et Finale B => 2 duel de 6 couloirs
				{ '1/1-2/1/1', '1/1-2/1/2', '2/1-2/1/1', '2/1-2/1/2', '3/1-2/1/1', '3/1-2/1/2'}, 
				{ '4/1-2/1/1', '4/1-2/1/2', '5/1-2/1/1', '5/1-2/1/2', '6/1-2/1/1', '6/1-2/1/2'}
			}
		}
	},

	KO_20_D4 =
	{
		dimension = 20,
		dimension_min = 13,
		niveau = 'KO_20_D4',
		--label = { 'Quart de Finale', 'Demi Finale', 'Finale' },
		GetLabelTour = GetLabel3Tours,

		progression = {
			{ 
				-- tour 1 :  Quart de final => 5 duels de 4 couloirs
				{ '1', '10', '11', '20' }, 
				{ '4',  '7', '14', '17' },
				{ '5',  '6', '15', '16' },
				{ '2',  '9', '12', '19' },
				{ '3',  '8', '13', '18' },
			},
			{ 
				-- tour 2 : demie finale => 2 duels de 6 couloirs
				{ '1/1-3/1/1', '1/1-3/1/2', '1/1-3/1/3', '2/1-2/1/1', '2/1-2/1/2', '3/1-5/1/2' }, 
				{ '1/4-5/1/1', '1/4-5/1/2', '2/3-5/1/1', '2/3-5/1/2', '2/3-5/1/3', '3/1-5/1/1' }
			},
			{ 
				-- tour  : Finale A et Finale B => 2 duel de 6 couloirs
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2', '3/1-2/2/1', '3/1-2/2/2'}, 
				{ '4/1-2/2/1', '4/1-2/2/2', '5/1-2/2/1', '5/1-2/2/2', '6/1-2/2/1', '6/1-2/2/2'}
			}
		}
	},

	KO_20_D5 =
	{
		dimension = 20,
		dimension_min = 13,
		niveau = 'KO_20_D5',
		GetLabelTour = GetLabel3Tours,
		progression = {
			{ 
				-- tour 1 :  Quart de final => 4 duels de 5 couloirs
				{ '1', '8', '9', '16', '17' },
				{ '4', '5', '12', '13', '20' },
				{ '2', '7', '10', '15', '18' },
				{ '3', '6', '11', '14', '19' },
			},
			{ 		
				-- tour 2 : demie finale => 2 duels de 6 couloirs
				{ '1/1-2/1/1', '1/1-2/1/2', '2/1-2/1/1', '2/1-2/1/2', '3/1-2/1/1', '3/1-2/1/2' },
				{ '1/3-4/1/1', '1/3-4/1/2', '2/3-4/1/1', '2/3-4/1/2', '3/3-4/1/1', '3/3-4/1/2' },
			},
			{ 
				-- tour  : Finale A et Finale B => 2 duel de 6 couloirs
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2', '3/1-2/2/1', '3/1-2/2/2'}, 
				{ '4/1-2/2/1', '4/1-2/2/2', '5/1-2/2/1', '5/1-2/2/2', '6/1-2/2/1', '6/1-2/2/2'}
			}
		}
	},
	
	Tab20FIS =
	{
		entite = 'FIS',
		dimension = 20,
		dimension_min = 13,
		niveau = '!KO_20_D4, !KO_20_D5',
		GetLabelTour = GetLabel3Tours,
		progression = {
			{ 
				-- tour 1 :  Quart de final => 4 duels de 5 couloirs
				{ '1', '8', '9', '16', '17' },
				{ '4', '5', '12', '13', '20' },
				{ '2', '7', '10', '15', '18' },
				{ '3', '6', '11', '14', '19' },
			},
			{ 		
				-- tour 2 : demie finale => 2 duels de 4 couloirs
				{ '1/1-2/1/1', '1/1-2/1/2', '2/1-2/1/1', '2/1-2/1/2' },
				{ '1/2-4/1/1', '1/2-4/1/2', '2/2-4/1/1', '2/2-4/1/2' }
			},
			{ 
				-- tour  : Finale A et Finale B => 2 duel de 4 couloirs
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2'}, 
				{ '3/1-2/2/1', '3/1-2/2/2', '4/1-2/2/1', '4/1-2/2/2'}
			}
		}
	},

	-- Tableau à 30 avec lucky lozer par Clt
	KO_30_Q7 =
	{
		dimension = 30,
		dimension_min = 21,
		niveau = 'KO_Spec',
		GetLabelTour = GetLabel3Tours,
		--label = { 'Quart de Finale', 'Demi Finale', 'Finale' },
		progression = {
			{ 
				-- tour 1 :  Quart de final => 5 duels de 4 couloirs
				{ '1', '10', '11', '20', '21', '30' }, 
				{ '4', '7', '14', '17', '24', '27' },
				{ '5', '6', '15', '16', '25', '26' },
				{ '2', '9', '12', '19', '22', '29' },
				{ '3', '8', '13', '18', '23', '28' }
			},
			{ 
				-- tour 2 : demie finale => 2 duels de 6 couloirs
				{ '1/1-3/1/1', '1/1-3/1/2', '1/1-3/1/3', '2/1-2/1/1', '2/1-2/1/2', '3/1-5/1/2' }, 
				{ '1/4-5/1/1', '1/4-5/1/2', '2/3-5/1/1', '2/3-5/1/2', '2/3-5/1/3', '3/1-5/1/1','3/3' }
			},
			{ 
				-- tour  : Finale A et Finale B => 2 duel de 6 couloirs
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2', '3/1-2/2/1', '3/1-2/2/2'}, 
				{ '4/1-2/2/1', '4/1-2/2/2', '5/1-2/2/1', '5/1-2/2/2', '6/1-2/2/1', '6/1-2/2/2'}
			}
		}
	},
	
		-- Tableau à 30 avec lucky lozer par Clt
	KO_30_LO =
	{
		dimension = 30,
		dimension_min = 21,
		niveau = 'KO_30_LO',
		GetLabelTour = GetLabel3Tours,
		--label = { 'Quart de Finale', 'Demi Finale', 'Finale' },
		progression = {
			{ 
				-- tour 1 :  Quart de final => 5 duels de 4 couloirs
				{ '1', '10', '11', '20', '21', '30' }, 
				{ '4', '7', '14', '17', '24', '27' },
				{ '5', '6', '15', '16', '25', '26' },
				{ '2', '9', '12', '19', '22', '29' },
				{ '3', '8', '13', '18', '23', '28' }
			},
			{ 
				-- tour 2 : demie finale => 2 duels de 6 couloirs
				{ '1/1-3/1/1', '1/1-3/1/2', '1/1-3/1/3', '2/1-2/1/1', '2/1-2/1/2', '3/1-5/1/2' }, 
				{ '1/4-5/1/1', '1/4-5/1/2', '2/3-5/1/1', '2/3-5/1/2', '2/3-5/1/3', '3/1-5/1/1' }
			},
			{ 
				-- tour 3 : Finale A et Finale B => 2 duel de 6 couloirs
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2', '3/1-2/2/1', '3/1-2/2/2'}, 
				{ '4/1-2/2/1', '4/1-2/2/2', '5/1-2/2/1', '5/1-2/2/2', '6/1-2/2/1', '6/1-2/2/2'}
			}
		}
	},

	-- Tableau à 30 avec lucky lozer avec Duel chrono	
	KO_30_CH =
	{
		dimension = 30,
		dimension_min = 21,
		niveau = 'KO_30_CH',
		GetLabelTour = GetLabel3Tours,

		progression = {
			{ 
				-- tour 1 :  Quart de final => 5 duels de 4 couloirs
				{ '1', '10', '11', '20', '21', '30' }, 
				{ '4', '7', '14', '17', '24', '27' },
				{ '5', '6', '15', '16', '25', '26' },
				{ '2', '9', '12', '19', '22', '29' },
				{ '3', '8', '13', '18', '23', '28' }
			},
			{ 
				-- tour 2 : demie finale => 2 duels de 6 couloirs
				{ '1/1-3/1/1', '1/1-3/1/2', '1/1-3/1/3', '2/1-2/1/1', '2/1-2/1/2', '3-4/1-5/1/2/duel' }, 
				{ '1/4-5/1/1', '1/4-5/1/2', '2/3-5/1/1', '2/3-5/1/2', '2/3-5/1/3', '3/1-5/1/1/duel' }
			},
			{ 
				-- tour 3 : Finale A et Finale B => 2 duel de 6 couloirs
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2', '3/1-2/2/1/duel', '3/1-2/2/2/duel'}, 
				{ '4/1-2/2/1', '4/1-2/2/2', '5/1-2/2/1', '5/1-2/2/2', '6/1-2/2/1/duel', '6/1-2/2/2/duel'}
			}
		}
	},

	-- Tableau A puis Tableau B 
	Tb_A_B42 =
	{
		dimension = 42,
		dimension_min = 31,
		niveau = 'Tb_A_B42',
		GetLabelDuel = GetLabelDuelTabA_B,
		GetLabelTour = GetLabel3Tours,
		GetLabelDuelWidth = function() return 9; end,
		
		progression = {
			{ 
				-- tour 1 :  Quart de final => tableau A
				{ '1', '10', '11', '20', '21', '30' }, -- D1
				{ '4', '7', '14', '17', '24', '27' },  -- D2
				{ '5', '6', '15', '16', '25', '26' },  -- D3
				{ '2', '9', '12', '19', '22', '29' },  -- D4
				{ '3', '8', '13', '18', '23', '28' }  -- D5
			},
			{ 
				-- tour 2 : demie finale => 2 duels de 6 couloirs => tableau A
				{ '1/1-3/1/1', '1/1-3/1/2', '1/1-3/1/3', '2/1-2/1/1', '2/1-2/1/2', '3/1-5/1/2' }, -- D1
				{ '1/4-5/1/1', '1/4-5/1/2', '2/3-5/1/1', '2/3-5/1/2', '2/3-5/1/3', '3/1-5/1/1' }, -- D2
				-- tour 2 : demie finale => 2 duels de 6 couloirs => tableau B
				{ '31', '34', '35', '38', '39', '42' }, -- D3
				{ '32', '33', '36', '37', '40', '41' }	 -- D4
			},
			{ 
				-- tour 3 : Finale A et Finale B => 2 duel de 6 couloirs => tableau A
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2', '3/1-2/2/1', '3/1-2/2/2'}, 
				--{ '4/1-2/2/1', '4/1-2/2/2', '5/1-2/2/1', '5/1-2/2/2', '6/1-2/2/1', '6/1-2/2/2'}
				-- tour 3 : Finale A et Finale B => 2 duel de 6 couloirs => tableau B
				{ '1/3-4/2/1', '1/3-4/2/2', '2/3-4/2/1', '2/3-4/2/2', '3/3-4/2/1', '3/3-4/2/2'}, 
				--{ '4/3-4/2/1', '4/3-4/2/2', '5/3-4/2/1', '5/3-4/2/2', '6/3-4/2/1', '6/3-4/2/2'}
			}
		}
	},
		
	Tb_A_B50 =
	{
		dimension = 50,
		dimension_min = 43,
		niveau = 'Tb_A_B50',
		GetLabelDuel = GetLabelDuelTabA_B,
		GetLabelTour = GetLabel3Tours,
		GetLabelDuelWidth = function() return 9; end,
		
		progression = {
			{ 
				-- tour 1 :  Quart de final => tableau A
				{ '1', '10', '11', '20', '21', '30' }, -- D1
				{ '4', '7', '14', '17', '24', '27' },  -- D2
				{ '5', '6', '15', '16', '25', '26' },  -- D3
				{ '2', '9', '12', '19', '22', '29' },  -- D4
				{ '3', '8', '13', '18', '23', '28' },  -- D5
				-- tour 1 :  Quart de final => tableau B
				{ '31', '38', '39', '46', '47' }, 	   -- D6
				{ '34', '35', '42', '43', '50' }, 	   -- D7
				{ '32', '37', '40', '45', '48' }, 	   -- D8
				{ '33', '36', '41', '44', '49' }, 	   -- D9
			},
			{ 
				-- tour 2 : demie finale => 2 duels de 6 couloirs => tableau A
				{ '1/1-3/1/1', '1/1-3/1/2', '1/1-3/1/3', '2/1-2/1/1', '2/1-2/1/2', '3/1-5/1/2' }, -- D1
				{ '1/4-5/1/1', '1/4-5/1/2', '2/3-5/1/1', '2/3-5/1/2', '2/3-5/1/3', '3/1-5/1/1' }, -- D2
				-- tour 2 : demie finale => 2 duels de 6 couloirs => tableau B
				{ '1/6-7/1/1', '1/6-7/1/2', '2/6-7/1/1', '2/6-7/1/2', '3/6-7/1/1', '3/6-7/1/2' }, -- D3
				{ '1/8-9/1/1', '1/8-9/1/2', '2/8-9/1/1', '2/8-9/1/2', '3/8-9/1/1', '3/8-9/1/2' }, -- D4
			},
			{ 
				-- tour 3  : Finale A et Finale B => 2 duel de 6 couloirs => tableau A
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2', '3/1-2/2/1', '3/1-2/2/2'}, 
				--{ '4/1-2/2/1', '4/1-2/2/2', '5/1-2/2/1', '5/1-2/2/2', '6/1-2/2/1', '6/1-2/2/2'}
				-- tour 3 : Finale A et Finale B => 2 duel de 6 couloirs => tableau B
				{ '1/3-4/2/1', '1/3-4/2/2', '2/3-4/2/1', '2/3-4/2/2', '3/3-4/2/1', '3/3-4/2/2'}, 
				--{ '4/3-4/2/1', '4/3-4/2/2', '5/3-4/2/1', '5/3-4/2/2', '6/3-4/2/1', '6/3-4/2/2'}
			}
		}
	},
	
	Tb_A_B60 =
	{
		dimension = 60,
		dimension_min = 51,
		niveau = 'Tb_A_B60',
		label = { 'Quart de Finale', 'Demi Finale', 'Finale' },
		GetLabelDuel = GetLabelDuelTabA_B,
		GetLabelTour = GetLabel3Tours,
		GetLabelDuelWidth = function() return 9; end,
		
		progression = {
			{ 
				-- tour 1 :  Quart de final => tableau A
				{ '1', '10', '11', '20', '21', '30' }, -- D1
				{ '4', '7', '14', '17', '24', '27' },  -- D2
				{ '5', '6', '15', '16', '25', '26' },  -- D3
				{ '2', '9', '12', '19', '22', '29' },  -- D4
				{ '3', '8', '13', '18', '23', '28' },  -- D5
				-- tour 1 :  Quart de final => tableau B
				{ '31', '40', '41', '50', '51', '60' }, -- D6 
				{ '34', '37', '44', '47', '54', '57' }, -- D7
				{ '35', '36', '45', '46', '55', '56' }, -- D8
				{ '32', '39', '42', '49', '52', '59' }, -- D9
				{ '33', '38', '43', '48', '53', '58' }  -- D10
			},
			{ 
				-- tour 2 : demie finale => 2 duels de 6 couloirs => tableau A
				{ '1/1-3/1/1', '1/1-3/1/2', '1/1-3/1/3', '2/1-2/1/1', '2/1-2/1/2', '3/1-5/1/2' },	   -- D1
				{ '1/4-5/1/1', '1/4-5/1/2', '2/3-5/1/1', '2/3-5/1/2', '2/3-5/1/3', '3/1-5/1/1' }, 	   -- D2
														 
				-- tour 2 : demie finale => 2 duels de 6 couloirs => tableau B
				{ '1/6-8/1/1', '1/6-8/1/2', '1/6-8/1/3', '2/6-7/1/1', '2/6-7/1/2', '3/6-10/1/2' },     -- D3
				{ '1/9-10/1/1', '1/9-10/1/2', '2/8-10/1/1', '2/8-10/1/2', '2/8-10/1/3', '3/6-10/1/1' } -- D4
			},
			{ 
				-- tour 3  : Finale A et Finale B => 2 duel de 6 couloirs => tableau A
				{ '1/1-2/2/1', '1/1-2/2/2', '2/1-2/2/1', '2/1-2/2/2', '3/1-2/2/1', '3/1-2/2/2'}, 
				--{ '4/1-2/2/1', '4/1-2/2/2', '5/1-2/2/1', '5/1-2/2/2', '6/1-2/2/1', '6/1-2/2/2'}
				-- tour 3 : Finale A et Finale B => 2 duel de 6 couloirs => tableau B
				{ '1/3-4/2/1', '1/3-4/2/2', '2/3-4/2/1', '2/3-4/2/2', '3/3-4/2/1', '3/3-4/2/2'}, 
				--{ '4/3-4/2/1', '4/3-4/2/2', '5/3-4/2/1', '5/3-4/2/2', '6/3-4/2/1', '6/3-4/2/2'}
			}
		}
	},

	-- tableau type montée descente sur 3 tour
	Mont_Desc_5 =
	{
		dimension = 100,
		dimension_min = 15,
	
		GetLabelTour = GetLabelTour_Mont_Desc,
		GetLabelDuel = GetLabelDuel_Mont_Desc,
		GetLabelDuelWidth = function() return 8; end,
		
		niveau = 'KO_MT_D5',
		
		progression_cut = Getprogression_cut,
		
		progression = {
			{ 
				-- tour 1 : 17 duels de 5 couloirs
				{ '1', '2', '3', '4', '5' }, 		-- D1
				{ '6', '7', '8', '9', '10' },		-- D2
				{ '11', '12', '13', '14', '15' },	-- D3
				{ '16', '17', '18', '19', '20' },	-- D4
				{ '21', '22', '23', '24', '25' },	-- D5
				{ '26', '27', '28', '29', '30' },	-- D6
				{ '31', '32', '33', '34', '35' },	-- D7
				{ '36', '37', '38', '39', '40' },	-- D8
				{ '41', '42', '43', '44', '45' }, 	-- D9
				{ '46', '47', '48', '49', '50' },	-- D10
				{ '51', '52', '53', '54', '55' },	-- D11
				{ '56', '57', '58', '59', '60' },	-- D12
				{ '61', '62', '63', '64', '65' }, 	-- D13
				{ '66', '67', '68', '69', '70' },	-- D14
				{ '71', '72', '73', '74', '75' },	-- D15
				{ '76', '77', '78', '79', '80' },	-- D16
				{ '81', '82', '83', '84', '85' },	-- D17
				{ '86', '87', '88', '89', '90' },	-- D18
				{ '91', '92', '93', '94', '95' },	-- D19
				{ '96', '97', '98', '99', '100'}	-- D20
			},
			{ 
				-- tour 2 : 17 duels de 6 couloirs
				{ '1/1', '2/1', '3/1', '1/2', '2/2' }, 		-- D1
				{ '4/1', '5/1', '3/2', '1/3', '2/3' }, 		-- D2
				{ '4/2', '5/2', '3/3', '1/4', '2/4' },		-- D3
				{ '4/3', '5/3', '3/4', '1/5', '2/5' },	 	-- D4
				{ '4/4', '5/4', '3/5', '1/6', '2/6' }, 		-- D5
				{ '4/5', '5/5', '3/6', '1/7', '2/7' }, 		-- D6
				{ '4/6', '5/6', '3/7', '1/8', '2/8' }, 		-- D7
				{ '4/7', '5/7', '3/8', '1/9', '2/9' },		-- D8
				{ '4/8', '5/8', '3/9', '1/10', '2/10' }, 	-- D9 
				{ '4/9', '5/9', '3/10', '1/11', '2/11' },	-- D10
				{ '4/10', '5/10', '3/11', '1/12', '2/12' }, -- D11
				{ '4/11', '5/11', '3/12', '1/13', '2/13' }, -- D12
				{ '4/12', '5/12', '3/13', '1/14', '2/14' }, -- D13
				{ '4/13', '5/13', '3/14', '1/15', '2/15' }, -- D14
				{ '4/14', '5/14', '3/15', '1/16', '2/16' }, -- D15
				{ '4/15', '5/15', '3/16', '1/17', '2/17' }, -- D16
				{ '4/16', '5/16', '3/17', '1/18', '2/18' }, -- D17
				{ '4/17', '5/17', '3/18', '1/19', '2/19' }, -- D18
				{ '4/18', '5/18', '3/19', '1/20', '2/20' }, -- D19
				{ '4/19', '5/19', '3/20', '4/20', '5/20' }  -- D20
			},
			{ 
				-- tour 3 : 17 duels de 6 couloirs
				{ '1/1', '2/1', '3/1', '1/2', '2/2' }, 		-- D1
				{ '4/1', '5/1', '3/2', '1/3', '2/3' }, 		-- D2
				{ '4/2', '5/2', '3/3', '1/4', '2/4' },		-- D3
				{ '4/3', '5/3', '3/4', '1/5', '2/5' }, 		-- D4
				{ '4/4', '5/4', '3/5', '1/6', '2/6' }, 		-- D5
				{ '4/5', '5/5', '3/6', '1/7', '2/7' }, 		-- D6
				{ '4/6', '5/6', '3/7', '1/8', '2/8' }, 		-- D7
				{ '4/7', '5/7', '3/8', '1/9', '2/9' },		-- D8
				{ '4/8', '5/8', '3/9', '1/10', '2/10' }, 	-- D9 
				{ '4/9', '5/9', '3/10', '1/11', '2/11' },	-- D10
				{ '4/10', '5/10', '3/11', '1/12', '2/12' }, -- D11
				{ '4/11', '5/11', '3/12', '1/13', '2/13' }, -- D12
				{ '4/12', '5/12', '3/13', '1/14', '2/14' }, -- D13
				{ '4/13', '5/13', '3/14', '1/15', '2/15' }, -- D14
				{ '4/14', '5/14', '3/15', '1/16', '2/16' }, -- D15
				{ '4/15', '5/15', '3/16', '1/17', '2/17' }, -- D16
				{ '4/16', '5/16', '3/17', '1/13', '2/13' }, -- D17
				{ '4/17', '5/17', '3/18', '1/19', '2/19' }, -- D18
				{ '4/18', '5/18', '3/19', '1/20', '2/20' }, -- D19
				{ '4/19', '5/19', '3/20', '4/20', '5/20' }  -- D20
			}
		}
	},
	
	Mont_Desc_6 =
	{
		dimension = 102,
		dimension_min = 18,
		
		niveau = 'KO_MT_D6',
		GetLabelTour = GetLabelTour_Mont_Desc,
		GetLabelDuel = GetLabelDuel_Mont_Desc,
		GetLabelDuelWidth = function() return 8; end,
		-- GetLabelDuelWidth = function(progression, tour, duel) if tour == 1 then return 10 else return 20 end end,
		progression_cut = Getprogression_cut,
		
		progression = {
			{ 
				-- tour 1 : 17 duels de 6 couloirs
				{ '1', '2', '3', '4', '5', '6' }, 			-- D1	
				{ '7', '8', '9', '10', '11', '12'},			-- D2
				{ '13', '14', '15', '16', '17', '18' },		-- D3
				{ '19', '20', '21', '22', '23', '24' },		-- D4
				{ '25', '26', '27', '28', '29', '30' },		-- D5
				{ '31', '32', '33', '34', '35', '36' },		-- D6
				{ '37', '38', '39', '40', '41', '42' },		-- D7
				{ '43', '44', '45', '46', '47', '48' }, 	-- D8
				{ '49', '50', '51', '52', '53', '54' },		-- D9
				{ '55', '56', '57', '58', '59', '60' },		-- D10
				{ '61', '62', '63', '64', '65', '66' }, 	-- D11
				{ '67', '68', '69', '70', '71', '72' },		-- D12
				{ '73', '74', '75', '76', '77', '78' },		-- D13
				{ '79', '80', '81', '82', '83', '84' },		-- D14
				{ '85', '86', '87', '88', '89', '90' },		-- D15
				{ '91', '92', '93', '94', '95', '96' },		-- D16
				{ '97', '98', '99', '100', '101', '102' }	-- D17
			},
			{ 
				-- tour 2 : 17 duels de 6 couloirs
				{ '1/1', '2/1', '3/1', '4/1', '1/2', '2/2' }, -- D1
				{ '5/1', '6/1', '3/2', '4/2', '1/3', '2/3' }, -- D2
				{ '5/2', '6/2', '3/3', '4/3', '1/4', '2/4' }, -- D3 
				{ '5/3', '6/3', '3/4', '4/4', '1/5', '2/5' }, -- D4
				{ '5/4', '6/4', '3/5', '4/5', '1/6', '2/6' }, -- D5
				{ '5/5', '6/5', '3/6', '4/6', '1/7', '2/7' }, -- D6
				{ '5/6', '6/6', '3/7', '4/7', '1/8', '2/8' }, -- D7
				{ '5/7', '6/7', '3/8', '4/8', '1/9', '2/9' }, -- D8			
				{ '5/8', '6/8', '3/9', '4/9', '1/10', '2/10' }, -- D9 
				{ '5/9', '6/9', '3/10', '4/10', '1/11', '2/11' }, -- D10
				{ '5/10', '6/10', '3/11', '4/11', '1/12', '2/12' }, -- D11
				{ '5/11', '6/11', '3/12', '4/12', '1/13', '2/13' }, -- D12
				{ '5/12', '6/12', '3/13', '4/13', '1/14', '2/14' }, -- D13
				{ '5/13', '6/13', '3/14', '4/14', '1/15', '2/15' }, -- D14
				{ '5/14', '6/14', '3/15', '4/15', '1/16', '2/16' }, -- D15
				{ '5/15', '6/15', '3/16', '4/16', '1/17', '2/17' }, -- D16
				{ '5/16', '6/16', '3/17', '4/17', '5/17', '6/17' } -- D17
			},
			{ 
				-- tour 3 : 17 duels de 6 couloirs
				{ '1/1', '2/1', '3/1', '4/1', '1/2', '2/2' }, -- D1
				{ '5/1', '6/1', '3/2', '4/2', '1/3', '2/3' }, -- D2
				{ '5/2', '6/2', '3/3', '4/3', '1/4', '2/4' }, -- D3 
				{ '5/3', '6/3', '3/4', '4/4', '1/5', '2/5' }, -- D4
				{ '5/4', '6/4', '3/5', '4/5', '1/6', '2/6' }, -- D5
				{ '5/5', '6/5', '3/6', '4/6', '1/7', '2/7' }, -- D6
				{ '5/6', '6/6', '3/7', '4/7', '1/8', '2/8' }, -- D7
				{ '5/7', '6/7', '3/8', '4/8', '1/9', '2/9' }, -- D8			
				{ '5/8', '6/8', '3/9', '4/9', '1/10', '2/10' }, -- D9 
				{ '5/9', '6/9', '3/10', '4/10', '1/11', '2/11' }, -- D10
				{ '5/10', '6/10', '3/11', '4/11', '1/12', '2/12' }, -- D11
				{ '5/11', '6/11', '3/12', '4/12', '1/13', '2/13' }, -- D12
				{ '5/12', '6/12', '3/13', '4/13', '1/14', '2/14' }, -- D13
				{ '5/13', '6/13', '3/14', '4/14', '1/15', '2/15' }, -- D14
				{ '5/14', '6/14', '3/15', '4/15', '1/16', '2/16' }, -- D15
				{ '5/15', '6/15', '3/16', '4/16', '1/17', '2/17' }, -- D16
				{ '5/16', '6/16', '3/17', '4/17', '5/17', '6/17' } -- D17
			}
		}
	},
	
	Mont_Desc_10 =
	{
		dimension = 100,
		dimension_min = 10,
	
		GetLabelTour = GetLabelTour_Mont_Desc,
		GetLabelDuel = GetLabelDuel_Mont_Desc,
		GetLabelDuelWidth = function() return 8; end,
		
		niveau = 'KO_MT_10',
		progression_cut = Getprogression_cut,
		
		progression = {
			{ 
				-- tour 1 : 17 duels de 5 couloirs	
				{ '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' }, 				-- D1
				{ '11', '12', '13', '14', '15', '16', '17', '18', '19', '20' },		-- D2
				{ '21', '22', '23', '24', '25', '26', '27', '28', '29', '30' },		-- D3
				{ '31', '32', '33', '34', '35', '36', '37', '38', '39', '40' },		-- D4
				{ '41', '42', '43', '44', '45', '46', '47', '48', '49', '50' },		-- D5
				{ '51', '52', '53', '54', '55', '56', '57', '58', '59', '60' },		-- D6
				{ '61', '62', '63', '64', '65', '66', '67', '68', '69', '70' },		-- D7
				{ '71', '72', '73', '74', '75', '76', '77', '78', '79', '80' },		-- D8
				{ '81', '82', '83', '84', '85', '86', '87', '88', '89', '90' }, 	-- D9
				{ '91', '92', '93', '94', '95', '96', '97', '98', '99', '100' },	-- D10
			},
			{ 
				-- tour 2 : 10 duels de 10 couloirs
				{ '1/1', '2/1', '3/1',  '4/1', '5/1', '6/1', '7/1', '1/2', '2/2', '3/2' }, 		-- D1
				{ '8/1', '9/1', '10/1',  '4/2', '5/2', '6/2', '7/2', '1/3','2/3', '3/3' }, 		-- D2
				{ '8/2', '9/2', '10/2',  '4/3', '5/3', '6/3', '7/3', '1/4','2/4', '3/4' }, 		-- D3
				{ '8/3', '9/3', '10/3',  '4/4', '5/4', '6/4', '7/4', '1/5','2/5', '3/5' }, 		-- D4
				{ '8/4', '9/4', '10/4',  '4/5', '5/5', '6/5', '7/5', '1/6','2/6', '3/6' }, 		-- D5
				{ '8/5', '9/5', '10/5',  '4/6', '5/6', '6/6', '7/6', '1/7','2/7', '3/7' }, 		-- D6
				{ '8/6', '9/6', '10/6',  '4/7', '5/7', '6/7', '7/7', '1/8','2/8', '3/8' }, 		-- D7
				{ '8/7', '9/7', '10/7',  '4/8', '5/8', '6/8', '7/8', '1/9','2/9', '3/9' }, 		-- D8
				{ '8/8', '9/8', '10/8',  '4/9', '5/9', '6/9', '7/9', '1/10','2/10', '3/10' },	-- D9 
				{ '8/9', '9/9', '10/9',  '4/9', '5/9', '6/9', '7/9', '8/10','9/10', '10/10' },	-- D10
			},
			{ 
				-- tour 3 : 10 duels de 10 couloirs
				{ '1/1', '2/1', '3/1',  '4/1', '5/1', '6/1', '7/1', '1/2', '2/2', '3/2' }, 		-- D1
				{ '8/1', '9/1', '10/1',  '4/2', '5/2', '6/2', '7/2', '1/3','2/3', '3/3' }, 		-- D2
				{ '8/2', '9/2', '10/2',  '4/3', '5/3', '6/3', '7/3', '1/4','2/4', '3/4' }, 		-- D3
				{ '8/3', '9/3', '10/3',  '4/4', '5/4', '6/4', '7/4', '1/5','2/5', '3/5' }, 		-- D4
				{ '8/4', '9/4', '10/4',  '4/5', '5/5', '6/5', '7/5', '1/6','2/6', '3/6' }, 		-- D5
				{ '8/5', '9/5', '10/5',  '4/6', '5/6', '6/6', '7/6', '1/7','2/7', '3/7' }, 		-- D6
				{ '8/6', '9/6', '10/6',  '4/7', '5/7', '6/7', '7/7', '1/8','2/8', '3/8' }, 		-- D7
				{ '8/7', '9/7', '10/7',  '4/8', '5/8', '6/8', '7/8', '1/9','2/9', '3/9' }, 		-- D8
				{ '8/8', '9/8', '10/8',  '4/9', '5/9', '6/9', '7/9', '1/10','2/10', '3/10' },	-- D9 
				{ '8/9', '9/9', '10/9',  '4/9', '5/9', '6/9', '7/9', '8/10','9/10', '10/10' },	-- D10
			}
		}
	},
};

