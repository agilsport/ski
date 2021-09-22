-- Description du protocol XML permettant la mise à jour de la base SKI
dofile('./xml/xmlTools.lua');

function importCSV(t)
	tableName = t.attributes.Nom;
	
	if t.attributes.Entete == 'O' then rowHeader = true else rowHeader = false end

	local separator = t.attributes.Separateur or '|';
	separator = string.lower(separator);
	
	if separator == 'pointvirgule' then separator = ';'
	elseif separator == 'barreverticale' then separator = '|';
	elseif separator == 'tabulation' then separator = 0x09;
	end
	
	local liste = t.attributes.Liste or '';
	if string.len(liste)  == 4 then
		-- xxYY : 
		liste = string.sub(liste,3)..string.sub(liste,1,2);
	elseif string.len(liste) == 3 then
		-- xYY : 
		liste = string.sub(liste,2)..string.sub(liste,1,1);
	else
		liste = '';
	end
	
	if isRunning() then
		base:ImportTableCSV(tableName, directory..string.lower(t.content), separator, rowHeader, t.attributes.Delete, liste);
	end
end

function afterFFS_Titre(t)
	MessageWarning('Importation '..t.content..' en cours ...');
end

function afterSQL(t)
--	MessageWarning('SQL '..t.content);
	base:Query(t.content);
end

-- Point d'entrée principale de la Grammaire XML 
xmlDescription = {
	name = 'FFS_Liste', children = {
		{ name = 'FFS_Titre', required = '0-1', after = afterFFS_Titre },
		{ name = 'SQL', required = '0-999', after = afterSQL },
		{ name = 'FFS_Table', required = '0-999', attributes = {
				{ name = 'Nom', type_value = 'string' },
				{ name = 'Entete', value = { 'O', 'N' }, optional = true },
				{ name = 'Separateur', value = { 'PointVirgule', 'BarreVerticale', 'Tabulation' }, optional = true },
				{ name = 'Liste', type_value = 'string', optional = true },
				{ name = 'Delete', type_value = 'string', optional = true }
			}, after = importCSV
		}
	}
};

