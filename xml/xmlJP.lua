-- FIS Ski Jumping Data Exchange XML Protocol version 2.7

case_sensitive = case_sensitive or false; -- Flag distinction majuscule-minuscule pour le nom des attributs et des balises  
tags_ffs = tags_ffs or false; -- Flag pour la génération des Balises FFS
msg = msg or app.GetAuiMessage(); -- Pile des Messages 

function SetAttributes(t, name, value)
	t.attributes = t.attributes or {};
	t.attributes[name] = value;
end

function beforeFisresults(t)
	base:SetGlobalVariable({'table', 'record'}); -- tName => table Name, rName => record Name
	
	if mode == 'import' then
		tEvenement:AddRow();
		tEpreuve:AddRow();
		tEpreuve_Alpine:AddRow();
		
		tResultat_Copy = tResultat:Copy(false, true);	--  paramètre 1 : false = copie de la structure, true = copie de la structure et des rows. Paramètre 2 : true va dans le garbage collector
		tResultat_Manche_Copy = tResultat_Manche:Copy(false, true);
		tResultat_Inter_Copy = tResultat_Inter:Copy(false, true);
	else
		SetAttributes(t, 'Version', '2.7'); -- Version du XML
	end
end

function afterFisresults(t)
	xmlError = xmlError or {};
	xmlWarning = xmlWarning or {};
	if mode == 'import' then
		if #xmlError == 0 then
			-- Verification table Evenement - Mise de valeurs par défaut ...
			if tEvenement:IsCellNull('Code_activite', 0) then tEvenement:SetCell('Code_activite', 0, 'ALP') end
			if tEvenement:IsCellNull('Code_entite', 0) then tEvenement:SetCell('Code_entite', 0, 'FIS') end
			local codex = tEvenement:GetCell('Code_nation', 0)..tEvenement:GetCell('Codex', 0)..'.007';
			tEvenement:SetCell('Codex', 0, codex);
			
			-- Verification table Epreuve - Mise de valeurs par défaut ...
			if tEpreuve:IsCellNull('Code_grille_categorie', 0) then tEpreuve:SetCell('Code_grille_categorie', 0, 'FIS-ALP') end
			if tEpreuve:IsCellNull('Code_categorie', 0) then tEpreuve:SetCell('Code_categorie', 0, '*') end

			-- Transfert Final tables Resultats ...
			tResultat:RemoveAllRows(); tResultat:AddRow(tResultat_Copy);
			tResultat_Manche:RemoveAllRows(); tResultat_Manche:AddRow(tResultat_Manche_Copy);
			tResultat_Inter:RemoveAllRows(); tResultat_Inter:AddRow(tResultat_Inter_Copy);
			base:InsertBaseEvenement();
		end
		if #xmlError == 0 then
			msg:AddLineSuccess('Import : Error(s) = '..#xmlError..', Warning(s) = '..#xmlWarning);
		else
			msg:AddLineError('Import : Error(s) = '..#xmlError..', Warning(s) = '..#xmlWarning);
		end
	else
		if #xmlError == 0 then
			msg:AddLineSuccess('Export : Error(s) = '..#xmlError..', Warning(s) = '..#xmlWarning);
		else
			msg:AddLineError('Export : Error(s) = '..#xmlError..', Warning(s) = '..#xmlWarning);
		end
	end
end

function afterRaceheader(t)
	if mode == 'import' then	-- Gender <=> Sexe 
		if t.attributes.Gender == 'W' then tEpreuve:SetCell('Sexe', 0, 'F');
		elseif t.attributes.Gender == 'A' then tEpreuve:SetCell('Sexe', 0, 'T');
		else tEpreuve:SetCell('Sexe', 0, 'M');
		end
	else
		SetAttributes(t, 'Sector', 'AL');
		if tEpreuve:GetCell('Sexe', 0) == 'F' then t.attributes.Gender = 'W';
		elseif tEpreuve:GetCell('Sexe', 0) == 'T' then t.attributes.Gender = 'A';
		else t.attributes.Gender = 'M';
		end
	end
end

function afterRacedate(t)
	if mode == 'import' then
		tEpreuve:LoadCell('Date_epreuve', 0, t.children.Year[1].content..'/'..t.children.Month[1].content..'/'..t.children.Day[1].content);
	else
		t.children.Year[1].content = tEpreuve:GetCell('Date_epreuve', 0, '%4Y');
		t.children.Month[1].content = tEpreuve:GetCell('Date_epreuve', 0, '%2M');
		t.children.Day[1].content = tEpreuve:GetCell('Date_epreuve', 0, '%2D');
	end
end

function beforeJP_ranked(t)
	if mode == 'import' then
		tResultat:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps > 0');
	end
end

function afterJP_ranked(t)
	if mode == 'import' then
		Code_coureur = tResultat:GetCell('Code_coureur', 0);
		for i=0, tResultat_Manche:GetNbRows()-1 do tResultat_Manche:SetCell('Code_coureur',i, Code_coureur) end
		for i=0, tResultat_Inter:GetNbRows()-1 do tResultat_Inter:SetCell('Code_coureur',i, Code_coureur) end
		tResultat_Copy:AddRow(tResultat); tResultat:RemoveAllRows();
		tResultat_Manche_Copy:AddRow(tResultat_Manche); tResultat_Manche:RemoveAllRows();
		tResultat_Inter_Copy:AddRow(tResultat_Inter); tResultat_Inter:RemoveAllRows();
	else
		SetAttributes(t, 'Status', 'QLF');
	end
end

function beforeJP_notranked(t)
	if mode == 'import' then
		tResultat:AddRow();
	else
		return base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..Code_evenement..' And Tps < 0');
	end
end

function afterJP_notranked(t)
	if mode == 'import' then
		Code_coureur = tResultat:GetCell('Code_coureur', 0);
		for i=0, tResultat_Manche:GetNbRows()-1 do tResultat_Manche:SetCell('Code_coureur',i, Code_coureur) end
		for i=0, tResultat_Inter:GetNbRows()-1 do tResultat_Inter:SetCell('Code_coureur',i, Code_coureur) end
		tResultat_Copy:AddRow(tResultat); tResultat:RemoveAllRows();
		tResultat_Manche_Copy:AddRow(tResultat_Manche); tResultat_Manche:RemoveAllRows();
		tResultat_Inter_Copy:AddRow(tResultat_Inter); tResultat_Inter:RemoveAllRows();
	else
		SetAttributes(t, 'Status', ranking.CodeInter(rResultat:GetInt('Tps')));
	end
end

function synchroResultatManche(t, manche)
	if mode == 'import' then
		tResultat_Manche:GetRecord():SetNull(); 
		tResultat_Manche:GetRecord():Set({ Code_manche = manche, Code_coureur = tResultat:GetCell('Code_coureur',0) }); 
		tResultat_Manche:AddRow();
	else
		return base:TableLoad(tResultat_Manche, 
			"Select * From Resultat_Manche"..
			" Where Code_evenement = "..Code_evenement..
			" And Code_manche = "..manche..
			" And Code_coureur = '"..rResultat:GetString('Code_coureur').."'" ..
			" And Tps_chrono > 0 ");
	end
end

function beforeRuninfo(t) 
	if mode == 'import' then 
		Code_manche = tonumber(t.attributes.No);
		rEpreuve_Alpine_Manche:Set('Code_manche', Code_manche);
		tEpreuve_Alpine_Manche:AddRow();
		
		if tEpreuve:GetCellInt('Nombre_de_manche', 0, -1) <= Code_manche then
			tEpreuve:SetCell('Nombre_de_manche', 0, Code_manche);
		end
	else
		return base:TableLoad(tEpreuve_Alpine_Manche, 
			"Select * From Epreuve_Alpine_Manche"..
			" Where Code_evenement = "..Code_evenement..
			" And Code_manche >= 1 "..
			" Order By Code_manche ");
	end 
end

function afterRuninfo(t) 
	if mode == 'export' then
		SetAttributes(t, 'No', rEpreuve_Alpine_Manche:GetString('Code_manche'));
	end
end

function beforeRun(t) 
	if mode == 'import' then 
		if t.attributes.No == 'tot' then Code_manche = -1 else Code_manche = t.attributes.No end
	else
		return base:TableLoad(tEpreuve_Alpine_Manche, 
			"Select * From Epreuve_Alpine_Manche"..
			" Where Code_evenement = "..Code_evenement..
			" Order By Code_manche ");
	end 
end

function beforeJury(t)
	if mode == 'import' then
		ordreJury = ordreJury or 0;
		ordreJury = ordreJury + 1;

		tEvenement_Officiel:GetRecord():SetNull(); 
		tEvenement_Officiel:GetRecord():Set({ Ordre = ordreJury, Label_Fonction = t.attributes.Function }); 
		tEvenement_Officiel:AddRow();
	else
		return base:TableLoad(tEvenement_Officiel, 
			"Select * From Evenement_Officiel"..
			" Where Code_evenement = "..Code_evenement..
			" Order By Ordre" );
	end
end

function afterJury(t)
	if mode == 'export' then 
		SetAttributes(t, 'Function', rEvenement_Officiel:GetString("Label_Fonction"));
	end
end

function contentFiscode(value) 
	if mode == 'import' then 
		return 'FIS'..value; 
	else 
		return value:sub(4);
	end 
end

function beforeSex(t)
	if mode == "import" then
		if t.attributes.Sex == 'M' then
			t.content = 'M';
		else
			t.content = 'F'; -- W, L ou F
		end
	end
end

function afterType(t)
	if mode == "export" then
		t.content = 'Official';
	end
end

--------------------------- XML Description tables ---------------------------
Raceheader = { 
	attributes = { {name = 'Sector', value = 'JP'}, {name = 'Gender', value = 'M|W|A', optional=true}, {name = 'Sex', value='M|W|A', optional=true}},
	children = {
		{ name = 'Season', field = 'Evenement.Code_saison' },
		{ name = 'Codex', field = 'Evenement.Codex' },
		{ name = 'Nation', field = 'Evenement.Code_nation' },
		{ name = 'Discipline', content = { 'NH','LH','FH','TN','TL','TF' }, field = 'Epreuve.Code_discipline' },
		{ name = 'Category', field = 'Epreuve.Code_regroupement' },
		{ name = 'Type', content = { 'Startlist', 'Partial' ,'Unofficial', 'Official' }, after = afterType },
		{ name = 'Phase',  required = '0-1', content = 'string' },
		{ name = 'Eventname', field = 'Evenement.Nom', required = '0-1' },
		{ name = 'Place', field = 'Evenement.Station', required = '0-1' },
		{ name = 'RaceDate', children = { 
			{ name = 'Day', content = "integer" } ,
			{ name = 'Month', content = "integer" },
			{ name = 'Year', content = "integer" },
			}, after = afterRacedate
		},
		{ name = 'TempUnit', required = '0-1', after = function(t) t.content = 'C' end },
		{ name = 'LongUnit', required = '0-1', after = function(t) t.content = 'm' end },
		{ name = 'SpeedUnit', required = '0-1', after = function(t) t.content = 'Km/h' end },
		{ name = 'WindUnit', required = '0-1', after = function(t) t.content = 'Km/h' end },
		
		{ name = 'FFS_Entite', field = 'Evenement.Code_entite', required = '0-1', export = tags_ffs },
		{ name = 'FFS_GrilleCategorie', field = 'Epreuve.Code_grille_categorie', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Categorie', field = 'Epreuve.Code_categorie', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Niveau', field = 'Epreuve.Code_niveau', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Regroupement', field = 'Epreuve.Code_regroupement', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Liste_Support', field = 'Evenement.Code_liste', required = '0-1', export = tags_ffs },
		{ name = 'FFS_Homologation_Date', field = 'Epreuve.Date_calendrier', required = '0-1', export = tags_ffs },
	},
	after = afterRaceheader
};

Competitor = {
	children = {
		{ name = 'FisCode', content = contentFiscode, field = 'Resultat.Code_coureur' },
		{ name = 'Lastname', field = 'Resultat.Nom' },
		{ name = 'Firstname', field = 'Resultat.Prenom' },
		{ name = 'Gender', content = {'M', 'F'} , field = 'Resultat.Sexe', required = '0-1' },	-- >= 2.10
		{ name = 'Sex', before = beforeSex, field = 'Resultat.Sexe', required = '0-1', export = false },-- 2.1 Compatibility
		{ name = 'Nation', field = 'Resultat.Nation' },
		{ name = 'YearOfBirth', field = 'Resultat.An' },
		{ name = 'ClubName', field = 'Resultat.Club', required = '0-1' },
		
		{ name = 'FFS_Code_coureur', field = 'Resultat.Code_coureur', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Comite', field = 'Resultat.Comite', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Groupe', field = 'Resultat.Groupe', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Equipe', field = 'Resultat.Equipe', required = '0-1' , export = tags_ffs },
		{ name = 'FFS_Critere', field = 'Resultat.Critere', required = '0-1', export = tags_ffs }
	}
};

JP_result_classified = {
	children = {
		{ name = 'Pointsdescend', content = 'string' },
		{ name = 'Level', content = 'string', required = '0-1'},
	}
};

JP_result_notclassified = {
	required = '0-1', children = {
		{ name = 'RacePoints', content = 'decimal', required = '0-1' },
		{ name = 'Level', content = 'string', required = '0-1' }
	}
};

JP_resultdetail = {
	required = '0-1', children = { 
		{	name = 'Jump', required = '0-9', attributes = {{name = 'No', value = '1|2|3|4'}, {name = 'Status', value='IRF|DNS|DSQ|DNQ2', optional=true}}, 
			children = {
				{ name = 'Distance', content = 'string' },
				{ name = 'Distancepoints', content = 'string' },
				{ name = 'Speed', content = 'string' },
				{ name = 'Judgesmarks', children = {
						{ name = 'Totalpoints', content = 'decimal' },
						{ name = 'A', content = 'decimal' , attributes = {{ name = 'counted', value = 'yes|no'}} },
						{ name = 'B', content = 'decimal' , attributes = {{ name = 'counted', value = 'yes|no'}} },
						{ name = 'C', content = 'decimal' , attributes = {{ name = 'counted', value = 'yes|no'}} },
						{ name = 'D', content = 'decimal' , attributes = {{ name = 'counted', value = 'yes|no'}} },
						{ name = 'E', content = 'decimal' , attributes = {{ name = 'counted', value = 'yes|no'}} }
					}
				},
				{ name = 'Gate', content = 'string' },
				{ name = 'Gatepoints', content = 'string' },
				{ name = 'Wind', content = 'string' },
				{ name = 'Windpoints', content = 'string' },
				{ name = 'Pointsdescend', content = 'string' },
				{ name = 'Rank', content = 'string' }
			}
		}
	}
};

Course = {
	children = {
		{ name = 'Name', required = '0-1' },
		{ name = 'Homologation', content = 'string' },
		{ name = 'Length', required = '0-1', field = 'Epreuve_Alpine_Manche.Longueur' },
		{ name = 'Gates', field = 'Epreuve_Alpine_Manche.Nombre_de_portes' },
		{ name = 'TurningGates', field = 'Epreuve_Alpine_Manche.Changement_de_directions' },
		{ name = 'StartElev', required = '0-1', field = 'Epreuve_Alpine_Manche.Altitude_Depart' },
		{ name = 'FinishElev', required = '0-1', field = 'Epreuve_Alpine_Manche.Altitude_Arrivee' },
		
		{ name = 'CourseSetter', required = '0-1', 
			children = {
				{ name = 'Lastname', field = 'Epreuve_Alpine_Manche.Nom_traceur' },
				{ name = 'Firstname', field = 'Epreuve_Alpine_Manche.Prenom_traceur' },
				{ name = 'Nation', content = 'Epreuve_Alpine_Manche.Code_nation_traceur' }
			}
		}
	}
};

Weather = {
	required = '0-99', children = {
		{ name = 'Time', field = 'Epreuve_Alpine_Manche.Heure_depart', required = '0-1' },
		{ name = 'Place', content = {'Start', 'Finish'}, required = '0-1' },
		{ name = 'Weather', required = '0-1' },
		{ name = 'Snow', required = '0-1' },
		{ name = 'TemperatureAir', required = '0-1' },
		{ name = 'TemperatureSnow', required = '0-1' },
		{ name = 'Humidity', required = '0-1' },
		{ name = 'WindSpeed', required = '0-1' },
		{ name = 'WindDirection', required = '0-1' }
	}
};
	
JP_race = {
	children = { 
		{ name = 'JP_raceinfo', children = {
				{ name = 'Hill', content = 'string' },
				{ name = 'Plastic', content = 'string' },
				{ name = 'Hillsize', content = 'string' },
				{ name = 'Kpoint', content = 'string' },
				{ name = 'Mvalue', content = 'string' },
				{ name = 'Gatefactor', content = 'string' },
				{ name = 'Windfactorhead', content = 'string' },
				{ name = 'Windfactortail', content = 'string' },
				{ name = 'Nullline', content = 'string', required = '0-1'},
				{ name = 'Jury', content = 'string' , required = '0-9999', attributes = {{ name='Function', type_value='string'}} },
				{ name = 'Member', content = 'string', required = '0-9999' },
				{ name = 'Judges', content = 'string', required = '0-1' },
				{ name = 'Runinfo', content = 'string', required = '0-1' },
						
				{ name = 'Timingby', content = 'string', required = '0-1' },
				{ name = 'DataProcessingBy', content = 'string', required = '0-1' },
				{ name = 'SoftwareCompany', content = 'string', required = '0-1' },
				{ name = 'SoftwareName', content = 'string', required = '0-1' },
				{ name = 'SoftwareVersion', content = 'string', required ="0-1" },
			}
		},
		{ name = 'JP_classified', children = {
				{ name = 'JP_ranked', required = '0-99999', before = beforeJP_ranked,  attributes = {{name ='Status', value = 'QLF'}}, children = {
						{ name = 'Rank', field = 'Resultat.Clt', required = '0-1' },	-- 2.10
						{ name = 'Order', field = 'Resultat.Rang', required = '0-1' },	-- 2.10
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },	-- 2.10
						{ name = 'Competitor', props = Competitor },
						{ name = 'JP_result', props = JP_result_classified },
						{ name = 'JP_resultdetail', props = JP_resultdetail }
					}, after = afterJP_ranked 
				}
			}
		},
		{ name = 'JP_notclassified', children = {
				{ name = 'JP_notranked', required = '0-99999', before = beforeJP_notranked,
					attributes = {{name = 'Status', value = 'DNS|DNS1|DNS2|DSQ|DSQ1|DSQ2|DNF|DNF1|DNF2|DNQ|DNQ1|DPO|NPS|DQB|DQO'}},
					children =
					{
						{ name = 'Run', content = "integer", required = '0-1' },
						{ name = 'Bib', field = 'Resultat.Dossard', required = '0-1' },
						{ name = 'Competitor', props = Competitor },
						{ name = 'Gate', content = "integer", required = '0-1' },
						{ name = 'JP_result', props = JP_result_notclassified },
						{ name = 'JP_resultdetail', props = JP_resultdetail },
						{ name = 'Reason', required = '0-1', content = 'string' },
					},
					after = afterJP_notranked
				}
			}
		}
	}
};

-- Point d'entrée principale de la Grammaire XML 
xmlDescription = {
	name = 'Fisresults', 
	before = beforeFisresults,
	attributes = { { name = 'Version', type_value = "string", optional = true }},
	children = {
		{ name = 'RaceHeader', props = Raceheader },
		{ name = 'JP_Race', props = JP_race }
	},
	after = afterFisresults
};
