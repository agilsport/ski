dofile('./xml/xmlTools.lua');

-- Liste des Protocoles pris en compte ...
xmlProtocol = {
	-- Protocol Data Exchange pour l'Import des Listes ou les mises à jour de la base 
	{ description = 'xmlBaseImport.lua', name = 'Importation Liste', import = { name = 'FFS_LISTE' } },

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

	-- Protocol Data Exchange CC (FIS)
	{ description = 'xmlCCv1.lua', name = 'Fond' , 
		import = {
			name = 'Fisresults', 
			children = { {name = 'RaceHeader', attributes = {{name = 'Sector', value = 'CC'}} }}
		},
		export =  function()
			if base:GetRecord('Evenement'):GetString('Code_activite') == 'FOND' then return true else return false end
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
