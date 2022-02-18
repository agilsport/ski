dofile('./xml/xmlTools.lua');
-- Version 1.6 le 26-01-2022
-- Envoi 'KO' à la FIS  Ok
-- Envoi FOND FS à la FIS Ok
-- Import ESF
-- Import TELEMARK
-- Import SB

-- Liste des Protocoles pris en compte ...
xmlProtocol = {
	-- Protocol Data Exchange pour l'Import des Listes ou les mises à jour de la base 
	{ description = 'xmlBaseImport.lua', name = 'Importation Liste', import = { name = 'FFS_LISTE' } },

	-- Protocol Data Exchange (ESF)
	{ description = 'xmlESF.lua', name = 'ESF Ski-Open' , import = { name = 'esf_competition'} },

	-- Protocol Data Exchange AL Version 1 (FFS) : Uniquement Import : Ancienne Norme
	{ description = 'xmlALv1.lua', name = 'Alpin V1' , 
		import = {
			name = 'Fisresults',
			children = { {name = 'RaceHeader', attributes = {{name = 'Sector', value = 'AL'}, {name = 'Sex', type_value = 'string'}} } }
		}
	},

	-- Protocol Data Exchange AL FIS - Import - Export 
	{ description = 'xmlAL.lua', name = 'Alpin' , activite = 'ALP', 
		import = {
			name = 'Fisresults',
			children = { {name = 'RaceHeader', attributes = {{name = 'Sector', value = 'AL'}, {name = 'Gender', type_value = 'string'}} }}
		},
		export =  function()
			if base:GetRecord('Evenement'):GetString('Code_activite') == 'ALP' then return true else return false end
		end
	},
	
	-- Rajout MF le 24-01-22 Protocol Data Exchange TM Version 1 (FFS) : Uniquement Import : Ancienne Norme
	{ description = 'xmlTMv1.lua', name = 'Telemark V1' , 
		import = {
			name = 'Fisresults',
			children = { {name = 'RaceHeader', attributes = {{name = 'Sector', value = 'TM'}, {name = 'Sex', type_value = 'string'}} } }
		},
		export =  function()
			if base:GetRecord('Evenement'):GetString('Code_activite') == 'TM' then return true else return false end
		end
	},	
	
	-- Protocol Data Exchange MA FIS - Import - Export 
	{ description = 'xmlAL.lua', name = 'Alpin' , activite = 'ALP', 
		import = {
			name = 'Fisresults',
			children = { {name = 'RaceHeader', attributes = {{name = 'Sector', value = 'MA'}, {name = 'Gender', type_value = 'string'}} }}
		},
		export =  function()
			if base:GetRecord('Evenement'):GetString('Code_activite') == 'ALP' then return true else return false end
		end
	},
	
	-- Protocol Data Exchange BH (FFS - VOLA)
	{ description = 'xmlBH.lua', name = 'Biathlon' , 
		import = {
			name = 'Fisresults', 
			children = { {name = 'RaceHeader', attributes = {{name = 'Sector', value = 'BH'}} }}
		},
		export =  function()
			if base:GetRecord('Evenement'):GetString('Code_activite') == 'BIATH' then return true else return false end
		end
	},

	-- Protocol Data Exchange CC (VOLA - Ancienne norme balise Sex)
	{ description = 'xmlCCv1.lua', name = 'Import Fond Vola' , 
		import = {
			name = 'Fisresults', 
			children = { {name = 'RaceHeader', attributes = {{name = 'Sector', value = 'CC'}, {name = 'Sex', type_value = 'string'}} }},
			-- Message('Import vola CC');
		}
		-- export =  function()
			-- if base:GetRecord('Evenement'):GetString('Code_activite') == 'FOND' then 
				-- Message('Export vola');
			-- return true else return false end
		-- end
	},

		-- Protocol Data Exchange CC pour KO(FIS)
	{ description = 'xmlCC_kov2.lua', name = 'Fond FIS' , 
		import = {
			name = 'Fisresults', 
			children = {{name = 'RaceHeader', attributes = {{name = 'Sector', value = 'CC'}},
							children = {{name = 'Discipline', value = 'KO'}}
			}},
			-- Message('Import skiFFS');
		},
		export =  function()
			if base:GetRecord('Evenement'):GetString('Code_activite') == 'FOND' and base:GetRecord('Epreuve'):GetString('Code_discipline') == 'KO' then return true else return false end
		end
	},

	-- Protocol Data Exchange CC Standard (FIS)
	{ description = 'xmlCCv2.lua', name = 'Fond FIS' , 
		import = {
			name = 'Fisresults', 
			children = { {name = 'RaceHeader', attributes = {{name = 'Sector', value = 'CC'}} }}
		},
		export =  function()
			if base:GetRecord('Evenement'):GetString('Code_activite') == 'FOND' then 
				-- Message('Code_discipline:'..base:GetRecord('Epreuve'):GetString('Code_discipline'));
				return true else return false end
			end
	},
	
	-- Protocol Data Exchange SB Standard (FIS)
	{ description = 'xmlSB.lua', name = 'Snowboard FIS' , 
		import = {
			name = 'Fisresults', 
			children = { {name = 'RaceHeader', attributes = {{name = 'Sector', value = 'SB'}} }}
		},
		export =  function()
			if base:GetRecord('Evenement'):GetString('Code_activite') == 'SB' then 
				return true else return false end
			end
	},

	-- Protocol Data Exchange JP (FIS)
	{ description = 'xmlJP.lua', name = 'Saut' , 
		import = {
			name = 'Fisresults', 
			children = { {name = 'RaceHeader', attributes = {{name = 'Sector', value = 'JP'}} }}
		},
		export = function()
			if base:GetRecord('Evenement'):GetString('Code_activite') == 'SAUT' then return true else return false end
		end
	}
};
