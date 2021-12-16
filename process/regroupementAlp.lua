-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function BuildGrille_Point_Place()		-- Création de la table Grille_Point_Place selon l'activité
	local cmd = "Select * From Place_valeur Where Code_activite = 'CHA-CMB' And Code_grille = 'FIS-CM' And Code_saison = '"..params.saison.."' Order By Place";
	base:TableLoad(tPlace_Valeur, cmd);
end


function OnFiltrageCourse(code_evenement)
	local filtre = '';
	local cmd = 'Select * From Resultat Where Code_evenement = '..code_evenement;
	base:TableLoad(tResultat, cmd);
	if tResultat:GetNbRows() > 0 then
		local filterCmd = wnd.FilterConcurrentDialog({ 
			sqlTable = tResultat,
			key = 'cmd'});
		if type(filterCmd) == 'string' and filterCmd:len() > 3 then
			filtre = filterCmd;
		end
	end
	return filtre;
end

function OnPrint()
	local utf8 = true;
	report = wnd.LoadTemplateReportXML({
		xml = './process/regroupementALP.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'print',
		title = 'Edition du Challenge',
		base = base,
		body = tEquipe,
		margin_first_top = 100,
		margin_first_left = 100,
		margin_first_right = 100,
		margin_first_bottom = 100,
		margin_top = 100,
		margin_left = 100, 
		margin_right = 100,
		margin_bottom = 100,
		paper_orientation = 'portrait',
		params = {Version = params.version, Titre = params.titre, CoursesIn = params.courses_in, NbCourses = tRegroupement_Courses:GetNbRows(), NbCoursesFilles = params.nb_courses_filles, NbFilles = params.nb_filles, NbCoursesGarcons = params.nb_courses_garcons, NbGarcons = params.nb_garcons, PtsTps = params.comboPtsTps}
	});
	-- report:SetZoom(10)
end

function GetPointsCourse(idxcourse, tps, best, facteur_f)		-- application de la formule de calcul
	local pts = 10000;
	if tps > 0 then
		pts = ((tps / best) - 1) * facteur_f;
		pts = Round(pts, 2);
	end
	return pts;
end

function GetPointPlace(clt)
	local pts = 0;
	clt = tonumber(clt) or 0;
	if clt > 0 and clt <= 30 then
		pts = tPlace_Valeur:GetCellDouble('Point', clt-1);
	end
	return pts;
end

function LitRegroupementCourses();	-- lecture des courses figurant dans la valeur params.courses_in
	local cmd = 'Select * from Epreuve Where Code_evenement In('..params.courses_in..') Order By Nombre_de_manche DESC';
	tEpreuve = base:TableLoad(cmd);
	local nb_manche_max = tEpreuve:GetCellInt('Nombre_de_manche', 0);
	params.saison = tEpreuve:GetCell('Code_saison', 0);
	if params.debug then
		adv.Alert("entrée de LitRegroupementCourses, base:GetTable('_Regroupement_Courses') = "..tostring(base:GetTable('_Regroupement_Courses'))..', type(tRegroupement_Courses) = '..type(tRegroupement_Courses)..', app.GetNameSpace(tRegroupement_Courses) = '..tostring(app.GetNameSpace(tRegroupement_Courses)));
	end
	if base:GetTable('_Regroupement_Courses') ~= nil then
		base:RemoveTable('_Regroupement_Courses');
		tRegroupement_Courses:Delete();
		tRegroupement_Courses = nil;
	end

	if params.debug then
		adv.Alert('passage dans la création de la table tRegroupement_Courses');
	end
	tRegroupement_Courses = sqlTable:Create('Regroupement_Courses');
	tRegroupement_Courses:AddColumn({ name = 'Code', label = 'Code', type = sqlType.LONG });
	tRegroupement_Courses:AddColumn({ name = 'Sexe', label = 'Sexe', type = sqlType.CHAR, size = 1 });
	tRegroupement_Courses:AddColumn({ name = 'Ordre_xml', label = 'Ordre_xml', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Date', label = 'Date', type = sqlType.CHAR, size = 10 });
	tRegroupement_Courses:AddColumn({ name = 'Ordre', label = 'Ordre', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Nom', label = 'Nom', type = sqlType.CHAR, size = 150, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Code_entite', label = 'Code_entite', type = sqlType.CHAR, size = 6, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Code_activite', label = 'Code_activite', type = sqlType.CHAR, size = 8, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Code_saison', label = 'Code_saison', type = sqlType.CHAR, size = 6, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Filtre', label = 'Filtre', type = sqlType.CHAR, size = 200, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Code_discipline', label = 'Code_discipline', type = sqlType.CHAR, size = 8, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Facteur_f', label = 'Facteur_f', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Nombre_de_manche', label = 'Nombre_de_manche', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Coef_manche', label = 'Coef_manche', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Tps_last', label = 'Tps_last', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Tps_first', label = 'Tps_first', type = sqlType.LONG, style = sqlStyle.NULL });
	tRegroupement_Courses:AddColumn({ name = 'Clt_last', label = 'Clt_last', type = sqlType.LONG, style = sqlStyle.NULL });
	for i = 0, tRegroupement_Courses:GetNbColumns() -1 do
		if string.find(tRegroupement_Courses:GetColumnName(i), 'Clt') then
			tRegroupement_Courses:ChangeColumn(tRegroupement_Courses:GetColumnName(i), 'ranking');
		end
		if string.find(tRegroupement_Courses:GetColumnName(i), 'Tps') then
			tRegroupement_Courses:ChangeColumn(tRegroupement_Courses:GetColumnName(i), 'chrono');
		end
	end
	tRegroupement_Courses:SetPrimary('Code, Ordre');
	ReplaceTableEnvironnement(tRegroupement_Courses, '_Regroupement_Courses');
	if params.debug then
		adv.Alert('après création éventuelle de LitRegroupementCourses, type(tRegroupement_Courses) = '..type(tRegroupement_Courses)..', app.GetNameSpace(tRegroupement_Courses) = '..tostring(app.GetNameSpace(tRegroupement_Courses)));
	end
	local ordre = 0;
	for i = 1, 3 do
		if params['coursef'..i] > 0 then
			ordre =  ordre + 1;
			ordre_xml = i;
			code_evenement = params['coursef'..i];
			filtre = params['coursef'..i..'_filtre'] or '';
			if params.debug then
				adv.Alert('avant add row chez les filles');
			end
			cmd = 'Select * From Evenement Where Code = '..code_evenement;
			base:TableLoad(tEvenement, cmd);
			cmd = 'Select * From Epreuve Where Code_evenement = '..code_evenement.." And Code_epreuve = 1";
			base:TableLoad(tEpreuve, cmd);

			rRegroupement_Courses = tRegroupement_Courses:GetRecord();
			rRegroupement_Courses:SetNull(); 
			
			rRegroupement_Courses:Set('Code', code_evenement);
			rRegroupement_Courses:Set('Ordre', ordre);
			rRegroupement_Courses:Set('Sexe', 'F');
			rRegroupement_Courses:Set('Ordre_xml', ordre_xml);
			rRegroupement_Courses:Set('Nom', tEvenement:GetCell('Nom', 0));
			rRegroupement_Courses:Set('Code_entite', tEvenement:GetCell('Code_entite', 0));
			rRegroupement_Courses:Set('Code_activite', tEvenement:GetCell('Code_activite', 0));
			rRegroupement_Courses:Set('Code_saison', tEvenement:GetCell('Code_saison', 0));
			rRegroupement_Courses:Set('Code_entite', tEvenement:GetCell('Code_entite', 0));
			if filtre:len() > 0 then
				rRegroupement_Courses:Set('Filtre', filtre);
			end
			rRegroupement_Courses:Set('Date', tEpreuve:GetCell('Date_epreuve', 0, '%2D-%2M-%4Y'));
			rRegroupement_Courses:Set('Code_discipline', tEpreuve:GetCell('Code_discipline', 0));
			rRegroupement_Courses:Set('Facteur_f', tEpreuve:GetCell('Facteur_f', 0));
			rRegroupement_Courses:Set('Nombre_de_manche', tEpreuve:GetCellInt('Nombre_de_manche', 0));
			rRegroupement_Courses:Set('Coef_manche', tEpreuve:GetCellInt('Coef_manche', 0));
			tRegroupement_Courses:AddRow();
			if params.debug then
				adv.Alert('LitRegroupementCourses : ajout de la course fille n° '..i);
			end
		end
		if params['courseg'..i] > 0 then
			ordre =  ordre + 1;
			ordre_xml = i;
			code_evenement = params['courseg'..i];
			filtre = params['courseg'..i..'_filtre'] or '';
			if params.debug then
				adv.Alert('avant add row chez les garçons');
			end
			cmd = 'Select * From Evenement Where Code = '..code_evenement;
			base:TableLoad(tEvenement, cmd);
			cmd = 'Select * From Epreuve Where Code_evenement = '..code_evenement.." And Code_epreuve = 1";
			base:TableLoad(tEpreuve, cmd);

			rRegroupement_Courses = tRegroupement_Courses:GetRecord();
			rRegroupement_Courses:SetNull(); 
			
			rRegroupement_Courses:Set('Code', code_evenement);
			rRegroupement_Courses:Set('Ordre', ordre);
			rRegroupement_Courses:Set('Sexe', 'M');
			rRegroupement_Courses:Set('Ordre_xml', ordre_xml);
			rRegroupement_Courses:Set('Nom', tEvenement:GetCell('Nom', 0));
			rRegroupement_Courses:Set('Code_entite', tEvenement:GetCell('Code_entite', 0));
			rRegroupement_Courses:Set('Code_activite', tEvenement:GetCell('Code_activite', 0));
			rRegroupement_Courses:Set('Code_saison', tEvenement:GetCell('Code_saison', 0));
			rRegroupement_Courses:Set('Code_entite', tEvenement:GetCell('Code_entite', 0));
			if filtre:len() > 0 then
				rRegroupement_Courses:Set('Filtre', filtre);
			end
			rRegroupement_Courses:Set('Date', tEpreuve:GetCell('Date_epreuve', 0, '%2D-%2M-%4Y'));
			rRegroupement_Courses:Set('Code_discipline', tEpreuve:GetCell('Code_discipline', 0));
			rRegroupement_Courses:Set('Facteur_f', tEpreuve:GetCellInt('Facteur_f', 0));
			rRegroupement_Courses:Set('Nombre_de_manche', tEpreuve:GetCellInt('Nombre_de_manche', 0));
			rRegroupement_Courses:Set('Coef_manche', tEpreuve:GetCellInt('Coef_manche', 0));
			tRegroupement_Courses:AddRow();
			if params.debug then
				adv.Alert('LitRegroupementCourses : ajout de la course garçons n° '..i);
			end
		end
	end
	tCourses = {};

	local ordre = 0;
	for i = 0, tRegroupement_Courses:GetNbRows() -1 do
		local idxcourse = i + 1;
		local ordre_xml = tRegroupement_Courses:GetCellInt('Ordre_xml', i);
		local tps_last = -1;
		local tps_first = nil;
		local code = tRegroupement_Courses:GetCellInt('Code', i);
		local sexe = tRegroupement_Courses:GetCell('Sexe', i);
		local cmd = 'Select * From Resultat Where Code_evenement = '..code..' Order By Tps DESC';
		base:TableLoad(tResultat, cmd);

		local filter = tRegroupement_Courses:GetCell('Filtre', i);
		if filter:len() > 0 then
			tResultat:Filter(filter, true);
		end

		tps_last = tResultat:GetCellInt('Tps', 0);
		clt_last = tResultat:GetCellInt('Clt', 0);
		tps_first = -1;
		for idx = tResultat:GetNbRows() -1, 0, -1 do
			if tResultat:GetCellInt('Tps', idx) > 0 then
				tps_first = tResultat:GetCellInt('Tps', idx);
				break;
			end
		end
		tRegroupement_Courses:SetCell('Tps_last', i, tps_last);
		tRegroupement_Courses:SetCell('Clt_last', i, clt_last);
		tRegroupement_Courses:SetCell('Tps_first', i, tps_first);
		local nombre_de_manche = tRegroupement_Courses:GetCellInt('Nombre_de_manche',i);
		local tps_last_run = -1;
		local tps_first_run = -1;
		local runs={};
		for j = 1, nombre_de_manche do
			cmd = 'Select * From Resultat_Manche Where Code_evenement = '..code..' And Code_manche = '..j..' Order By Tps_chrono DESC';
			base:TableLoad(tResultat_Manche, cmd);
			tps_last_run = tResultat_Manche:GetCellInt('Tps_chrono', 0);
			clt_last_run = tResultat_Manche:GetCellInt('Clt_chrono', 0);
			for idx = tResultat_Manche:GetNbRows() -1, 0, -1 do
				tps_first_run = tResultat_Manche:GetCellInt('Tps_chrono', idx);
				if tps_first_run > 0 then
					break;
				end
			end
			tRegroupement_Courses:SetCell('Tps_last_m'..j, i, tps_last_run);
			tRegroupement_Courses:SetCell('Tps_first_m'..j, i, tps_first_run);
			table.insert(runs, {Run = j, TpsFirst = tps_first_run, TpsLast = tps_last_run, CltLast = clt_last_run});
		end
		filter = filter or '';
		tRegroupement_Courses:SetCell('Coef_manche', i, params.coefManche);
		table.insert(tCourses, {Code_evenement = code, Ordre_xml = ordre_xml, Filtre = filter, Sexe = sexe, TpsFirst = tps_first, TpsLast = tps_last, CltLast = clt_last, Facteur_f = facteur_f, NbManches = nombre_de_manche, Runs = runs})
	end
	tRegroupement_Courses:OrderBy('Ordre');
	if params.debug then
		tRegroupement_Courses:Snapshot('tRegroupement_Courses.db3');
	end
end

function BuildEquipes()
	if params.debug then
		adv.Alert('entrée dans BuildEquipes');
	end
	local col_equipe = dlgConfig:GetWindowName('comboColEquipe'):GetValue();
	local cmd = 'Select '..col_equipe..' From Resultat Where Code_evenement In('..params.courses_in..')';
	cmd = cmd..' Group By '..col_equipe;
	tEquipe = base:TableLoad(cmd);
	tEquipe:AddColumn({ name = 'Clt', label = 'Clt', type = sqlType.LONG, style = sqlStyle.NULL});
	tEquipe:AddColumn({ name = 'OK', label = 'OK', type = sqlType.LONG, style = sqlStyle.NULL});
	tEquipe:AddColumn({ name = 'Detail_filles', label = 'Detail_filles', type = sqlType.VARCHAR, style = sqlStyle.NULL});
	tEquipe:AddColumn({ name = 'Detail_garcons', label = 'Detail_garcons', type = sqlType.VARCHAR, style = sqlStyle.NULL});
	tEquipe:AddColumn({ name = 'Pts_total', label = 'Pts_total', type = sqlType.DOUBLE, style = sqlStyle.NULL});
	tEquipe:AddColumn({ name = 'Tps_total', label = 'Tps_total', type = sqlType.LONG, style = sqlStyle.NULL});
	for i = 0, tEquipe:GetNbColumns() -1 do
		if string.find(tEquipe:GetColumnName(i), 'Clt') then
			tEquipe:ChangeColumn(tEquipe:GetColumnName(i), 'ranking');
		end
		if string.find(tEquipe:GetColumnName(i), 'Tps') then
			tEquipe:ChangeColumn(tEquipe:GetColumnName(i), 'chrono');
		end
	end
 	tEquipe:OrderBy(col_equipe);
	tEquipe:SetPrimary(col_equipe);
	ReplaceTableEnvironnement(tEquipe, '_Equipe');
	
	for i = 0, tEquipe:GetNbRows() -1 do
		local OK = 1;
		local equipe = tEquipe:GetCell(0, i);
		local pts_total = 0;
		local tps_total = 0;
		local strGarcons = '';
		local separateur_filles = '';
		local separateur_garcons = '';
		for idxcourse = 1, #tCourses do
			local nb_filles_pris = 0;
			local nb_garcons_pris = 0;
			local ordre_xml = tCourses[idxcourse].Ordre_xml;
			local sexe_course = tCourses[idxcourse].Sexe;
			local code_evenement = tCourses[idxcourse].Code_evenement;
			local nombre_de_manche = tCourses[idxcourse].NbManches;
			local filter = tCourses[idxcourse].Filtre;
			tMatrice_Ranking_Copy = tMatrice_Ranking:Copy();
			if filter:len() > 0 then
				filter = filter.." and $("..col_equipe.."):In('"..equipe.."') and $(Code_evenement"..idxcourse.."):In('"..code_evenement.."')"
			else
				filter = '$('..col_equipe.."):In('"..equipe.."') and $(Code_evenement"..idxcourse.."):In('"..code_evenement.."')";
			end
			tMatrice_Ranking_Copy:Filter(filter, true);		-- il reste les coureurs de l'équipe dans cette course.
			tMatrice_Ranking_Copy:OrderBy('Pts'..idxcourse..'_total Desc');
			-- les filles
			for row = 0, tMatrice_Ranking_Copy:GetNbRows() -1 do
				local pts_total_course = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_total', row);
				if pts_total_course < 10000 then
					local tps_total_course = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse..'_total', row, -1);
					if tMatrice_Ranking_Copy:GetCell('Sexe', row) == 'F' then
						if nb_filles_pris < params.nb_filles then
							local tDetailFilles = {};
							nb_filles_pris = nb_filles_pris + 1;
							local code_coureur = tMatrice_Ranking_Copy:GetCell('Code_coureur', row);
							local dossard = tMatrice_Ranking_Copy:GetCellInt('Dossard'..idxcourse, row);
							local nom = tMatrice_Ranking_Copy:GetCell('Identite', row);
							local pts_course = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_total', row);
							local clt = tMatrice_Ranking_Copy:GetCellInt('Clt'..idxcourse, row);
							local tps = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse, row);
							local clt_best = tMatrice_Ranking_Copy:GetCellInt('Clt'..idxcourse..'_best', row);
							local run_best = tMatrice_Ranking_Copy:GetCellInt('Run'..idxcourse..'_best', row);
							local tps_best = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse..'_Run'..run_best, row);
							local pts_best = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_best', row);
							pts_total = pts_total + pts_total_course;
							tps_total = tps_total + tps_total_course;
							table.insert(tDetailFilles, 
								{Course = ordre_xml, 
								CodeEvenement = code_evenement, 
								CodeCoureur = code_coureur, 
								Dossard = dossard, 
								Nom = nom, 
								Sexe = 'F', 
								Clt = clt, 
								PtsCourse = pts_course, 
								TpsCourse = tps_course, 
								BestClt = clt_best, 
								BestRun = run_best, 
								BestTps = tps_best, 
								BestPts = pts_best, 
								BestTps = tps_best,
								PtsTotal = pts_total_course,
								TpsTotal = tps_total_course});
							local xDetailFilles = {Detail = tDetailFilles};
							local jsontxt = table.ToStringJSON(xDetailFilles, false);
							jsontxt = separateur_filles..jsontxt;
							tEquipe:SetCell('Detail_filles', i, tEquipe:GetCell('Detail_filles', i)..jsontxt);
							separateur_filles = '|';
						end
					end
				end
			end
			-- les garçons
			for row = 0, tMatrice_Ranking_Copy:GetNbRows() -1 do
				local pts_total_course = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_total', row);
				if pts_total_course < 10000 then
					local tps_total_course = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse..'_total', row, -1);
					if tMatrice_Ranking_Copy:GetCell('Sexe', row) == 'M' then
						if nb_garcons_pris < params.nb_garcons then
							local tDetailGarcons = {};
							nb_garcons_pris = nb_garcons_pris + 1;
							local code_coureur = tMatrice_Ranking_Copy:GetCell('Code_coureur', row);
							local dossard = tMatrice_Ranking_Copy:GetCellInt('Dossard'..idxcourse, row);
							local nom = tMatrice_Ranking_Copy:GetCell('Identite', row);
							local pts_course = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_total', row);
							local clt = tMatrice_Ranking_Copy:GetCellInt('Clt'..idxcourse, row);
							local tps = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse, row);
							local clt_best = tMatrice_Ranking_Copy:GetCellInt('Clt'..idxcourse..'_best', row)
							local run_best = tMatrice_Ranking_Copy:GetCellInt('Run'..idxcourse..'_best', row)
							local tps_best = tMatrice_Ranking_Copy:GetCellInt('Tps'..idxcourse..'_Run'..run_best, row)
							local pts_best = tMatrice_Ranking_Copy:GetCellDouble('Pts'..idxcourse..'_best', row)
							pts_total = pts_total + pts_total_course;
							tps_total = tps_total + tps_total_course;
							table.insert(tDetailGarcons, 
								{Course = ordre_xml, 
								CodeEvenement = code_evenement, 
								CodeCoureur = code_coureur, 
								Dossard = dossard, 
								Nom = nom, 
								Sexe = 'M', 
								Clt = clt, 
								PtsCourse = pts_course, 
								TpsCourse = tps_course, 
								BestClt = clt_best, 
								BestRun = run_best, 
								BestTps = tps_best, 
								BestPts = pts_best, 
								BestTps = tps_best,
								PtsTotal = pts_total_course,
								TpsTotal = tps_total_course});
							local xDetailGarcons = {Detail = tDetailGarcons};
							local jsontxt = table.ToStringJSON(xDetailGarcons, false);
							jsontxt = separateur_garcons..jsontxt;
							tEquipe:SetCell('Detail_garcons', i, tEquipe:GetCell('Detail_garcons', i)..jsontxt);
							separateur_garcons = '|';
						end
					end
				end
			end
		end

		local tdetailfille = tEquipe:GetCell('Detail_filles', i):Split('|');
		nb_filles = #tdetailfille;
		local tdetailgarcons = tEquipe:GetCell('Detail_garcons', i):Split('|');
		nb_garcons = #tdetailgarcons;
		if params.nb_filles > 0 and nb_filles < (params.nb_filles * params.nb_courses_filles) then
			OK = 0;
		end
		if params.nb_garcons > 0 and nb_garcons < (params.nb_garcons * params.nb_courses_garcons) then
			OK = 0;
		end
		tEquipe:SetCell('OK',i, OK);
		tEquipe:SetCell('Pts_total',i, pts_total);
		tEquipe:SetCell('Tps_total',i, tps_total);
	end
	local filter = '$(OK):In(1)';
	if params.comboGarderEquipe == 0 then
		tEquipe:Filter(filter, true);
	end
	if params.comboPtsTps == 0 then
		tEquipe:SetRanking('Clt', 'Pts_total DESC', '');
	elseif params.comboPtsTps == 1 then
		tEquipe:SetRanking('Clt', 'Pts_total ASC', '');
	elseif params.comboPtsTps == 2 then
		tEquipe:SetRanking('Clt', 'Tps_total ASC', '');
	end
	tEquipe:OrderBy('Clt');
	if params.debug then
		tEquipe:Snapshot('tEquipe.db3');
		adv.Alert('sortie de BuildEquipes');
	end
end

function BuildRanking();
	if params.debug then
		adv.Alert('\n____________________________________________________\navant LitRegroupementCourses');
	end
	LitRegroupementCourses();
	if params.debug then
		adv.Alert('après LitRegroupementCourses');
	end
	BuildGrille_Point_Place();
	cmd = 'Select Code_coureur From Resultat Where Code_evenement in('..params.courses_in..') ';
	cmd = cmd..' Group By Code_coureur';
	tMatrice_Ranking = base:TableLoad(cmd);
	ReplaceTableEnvironnement(tMatrice_Ranking, '_tMatrice_Ranking');
    tMatrice_Ranking:AddColumn({ name = 'Filtrer', label = 'Filtrer', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Nom', label = 'Nom', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Prenom', label = 'Prenom', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Identite', label = 'Identite', type = sqlType.CHAR, width = '61', style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Sexe', label = 'Sexe', type = sqlType.CHAR, width = '1', style = sqlStyle.NULL});
    tMatrice_Ranking:AddColumn({ name = 'An', label = 'An', type = sqlType.LONG, style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Categ', label = 'Categ', type = sqlType.CHAR, width = '8', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Nation', label = 'Nation', type = sqlType.CHAR, width = '3', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Comite', label = 'Comite', type = sqlType.CHAR, width = '3', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Club', label = 'Club', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Groupe', label = 'Groupe', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Equipe', label = 'Equipe', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
	tMatrice_Ranking:AddColumn({ name = 'Critere', label = 'Critere', type = sqlType.CHAR, width = '30', style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Point', label = 'Point', type = sqlType.DOUBLE, style = sqlStyle.NULL});
 	tMatrice_Ranking:AddColumn({ name = 'Pts', label = 'Pts', type = sqlType.DOUBLE, style = sqlStyle.NULL});

	for idxcourse = 1, #tCourses do
		local discipline = tCourses[idxcourse].Discipline;
		tMatrice_Ranking:AddColumn({ name = 'Code_evenement'..idxcourse, label = 'Code_evenement'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Ordre'..idxcourse, label = 'Ordre'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Ordre_xml'..idxcourse, label = 'Ordre_xml'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Dossard'..idxcourse, label = 'Dossard'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Clt'..idxcourse, label = 'Clt'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse, label = 'Tps'..idxcourse, type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse, label = 'Pts'..idxcourse, type = sqlType.DOUBLE, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Run'..idxcourse..'_best', label = 'Run'..idxcourse..'_best', type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Clt'..idxcourse..'_best', label = 'Clt'..idxcourse..'_best', type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse..'_best', label = 'Pts'..idxcourse..'_best', type = sqlType.DOUBLE, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse..'_total', label = 'Pts'..idxcourse..'_total', type = sqlType.DOUBLE, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse..'_total', label = 'Tps'..idxcourse..'_total', type = sqlType.LONG, style = sqlStyle.NULL});
		tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse..'_best', label = 'Tps'..idxcourse..'_best', type = sqlType.LONG, style = sqlStyle.NULL});
		for idxrun = 1, tCourses[idxcourse].NbManches do
			tMatrice_Ranking:AddColumn({ name = 'Clt'..idxcourse..'_run'..idxrun, label = 'Clt'..idxcourse..'_run'..idxrun, type = sqlType.LONG, style = sqlStyle.NULL});
			tMatrice_Ranking:AddColumn({ name = 'Tps'..idxcourse..'_run'..idxrun, label = 'Tps'..idxcourse..'_run'..idxrun, type = sqlType.LONG, style = sqlStyle.NULL});
			tMatrice_Ranking:AddColumn({ name = 'Pts'..idxcourse..'_run'..idxrun, label = 'Pts'..idxcourse..'_run'..idxrun, type = sqlType.DOUBLE, style = sqlStyle.NULL});
		end
	end

	for i = 0, tMatrice_Ranking:GetNbColumns() -1 do
		if string.find(tMatrice_Ranking:GetColumnName(i), 'Clt') then
			tMatrice_Ranking:ChangeColumn(tMatrice_Ranking:GetColumnName(i), 'ranking');
		end
		if string.find(tMatrice_Ranking:GetColumnName(i), 'Tps') then
			tMatrice_Ranking:ChangeColumn(tMatrice_Ranking:GetColumnName(i), 'chrono');
		end
	end
	for idxcourse = 1, #tCourses do
		local nombre_de_manche = tCourses[idxcourse].NbManches;
		local code_evenement = tCourses[idxcourse].Code_evenement;
		local cmd = 'Select * From Resultat Where Code_evenement = '..code_evenement..' Order By Tps ASC';
		local coltps = 'Tps'..idxcourse;
		local colclt = 'Clt'..idxcourse;
		base:TableLoad(tResultat, cmd);
		if tCourses[idxcourse].Filtre:len() > 0 then
			tResultat:Filter(tCourses[idxcourse].Filtre, true);
		end
		for row = 0, tMatrice_Ranking:GetNbRows() -1 do
			local code_coureur = tMatrice_Ranking:GetCell('Code_coureur', row);
			local r = -1;
			r = tResultat:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then
				tMatrice_Ranking:SetCell('Filtrer', row, 1);
				tMatrice_Ranking:SetCell('Dossard'..idxcourse, row, tResultat:GetCellInt('Dossard', r));
				tMatrice_Ranking:SetCell('Nom', row, tResultat:GetCell('Nom', r));
				tMatrice_Ranking:SetCell('Prenom', row, tResultat:GetCell('Prenom', r));
				tMatrice_Ranking:SetCell('Identite', row, tResultat:GetCell('Nom', r)..' '..tResultat:GetCell('Prenom', r));
				tMatrice_Ranking:SetCell('Sexe', row, tResultat:GetCell('Sexe', r));
				tMatrice_Ranking:SetCell('An', row, tResultat:GetCellInt('An', r));
				tMatrice_Ranking:SetCell('Categ', row, tResultat:GetCell('Categ', r));
				tMatrice_Ranking:SetCell('Nation', row, tResultat:GetCell('Nation', r));
				tMatrice_Ranking:SetCell('Comite', row, tResultat:GetCell('Comite', r));
				tMatrice_Ranking:SetCell('Club', row, tResultat:GetCell('Club', r));
				tMatrice_Ranking:SetCell('Groupe', row, tResultat:GetCell('Groupe', r));
				tMatrice_Ranking:SetCell('Equipe', row, tResultat:GetCell('Equipe', r));
				tMatrice_Ranking:SetCell('Critere', row, tResultat:GetCell('Critere', r));
				tMatrice_Ranking:SetCell('Code_evenement'..idxcourse, row, code_evenement)
				local tps = tResultat:GetCellInt('Tps', r, -1);
				if tps < 0 then
					if params.comboAbdDsq == 1 then
						tps = tCourses[idxcourse].TpsLast;
					end
				end
				tMatrice_Ranking:SetCell(coltps, row, tps);
				for idxrun = 1, nombre_de_manche do
					local coltpsrun = 'Tps'..idxcourse..'_run'..idxrun;
					local tpsm = -1;
					local cmd = 'Select * From Resultat_Manche Where Code_evenement = '..code_evenement..' And Code_manche = '..idxrun.." And Code_coureur = '"..code_coureur.."'"; 
					base:TableLoad(tResultat_Manche, cmd);
					tpsm = tResultat_Manche:GetCellInt('Tps_chrono', 0, -1);
					if tpsm < 0 then
						if params.comboAbdDsq == 1 then
							tpsm = tCourses[idxcourse].Runs[idxrun].TpsLast;
						end
					end
					tMatrice_Ranking:SetCell(coltpsrun, row, tpsm);
				end
			end
		end
		tMatrice_Ranking:SetRanking(colclt, coltps, 'OK > 0');
		if params.debug then
			tMatrice_Ranking:Snapshot('tMatrice_Ranking_'..idxcourse..'_apres_tps.db3');
		end
		for idxrun = 1, nombre_de_manche do
			local colcltrun = 'Clt'..idxcourse..'_run'..idxrun;
			local coltpsrun = 'Tps'..idxcourse..'_run'..idxrun;
			tMatrice_Ranking:SetRanking(colcltrun, coltpsrun, 'OK > 0');
		end
	end
	local filter = '$(Filtrer):In(1)';
	tMatrice_Ranking:Filter(filter, true);
	if params.debug then
		tMatrice_Ranking:Snapshot('tMatrice_Ranking_apres_tps.db3');
	end
	for row = 0, tMatrice_Ranking:GetNbRows() -1 do
		for idxcourse = 1, tRegroupement_Courses:GetNbRows() do
			local colclt = 'Clt'..idxcourse;
			local coltps = 'Tps'..idxcourse;
			local colpts = 'Pts'..idxcourse;
			local colbestrun = 'Run'..idxcourse..'_best';
			local colbestclt = 'Clt'..idxcourse..'_best';
			local colbestpts = 'Pts'..idxcourse..'_best';
			local colbesttps = 'Tps'..idxcourse..'_best';
			local colptstotal = 'Pts'..idxcourse..'_total';
			local coltpstotal = 'Tps'..idxcourse..'_total';
			local pts = params.default_pts;
			local tps = tMatrice_Ranking:GetCellInt(coltps, row, -1);
			local ordre = tRegroupement_Courses:GetCellInt('Ordre', idxcourse-1);
			tMatrice_Ranking:SetRanking('Clt'..idxcourse, 'Tps'..idxcourse, '');
			tMatrice_Ranking:SetCell('Ordre'..idxcourse, row, ordre);
			if params.comboPtsTps == 0 then
				pts = GetPointPlace(tMatrice_Ranking:GetCellInt(colclt, row));
			elseif params.comboPtsTps == 1 then
				pts = GetPointsCourse(idxcourse, tps, tCourses[idxcourse].TpsFirst, tCourses[idxcourse].Facteur_f)		-- application de la formule de calcul
			end
			tMatrice_Ranking:SetCell('Pts'..idxcourse, row, pts)
			local nb_run = tRegroupement_Courses:GetCellInt('Nombre_de_manche', idxcourse -1);
			local best_pts = params.default_pts;
			pts_run = params.default_pts;
			local best_clt = 10000;
			local best_run = nil;
			local best_tps = nil;
			for idxrun = 1, nb_run do
				local coltpsrun = 'Tps'..idxcourse..'_run'..idxrun;
				local colcltrun = 'Clt'..idxcourse..'_run'..idxrun;
				tMatrice_Ranking:SetRanking(colcltrun, coltpsrun, '');
			end
			for idxrun = 1, nb_run do
				local colcltrun = 'Clt'..idxcourse..'_run'..idxrun;
				local coltpsrun = 'Tps'..idxcourse..'_run'..idxrun;
				local colptsrun = 'Pts'..idxcourse..'_run'..idxrun;
				local clt_run = tMatrice_Ranking:GetCellInt(colcltrun, row, 10000);
				local tps_run = tMatrice_Ranking:GetCellInt(coltpsrun, row, -1);
				if params.comboPtsTps == 0 then
					pts_run = GetPointPlace(clt_run);
					pts_run = pts_run * params.coefManche / 100;
				elseif params.comboPtsTps == 1 then
					pts_run = GetPointsCourse(idxcourse, tpsrun, tCourses[idxcourse].Runs[idxrun].TpsFirst, tCourses[idxcourse].Facteur_f)		-- application de la formule de calcul
				end
				tMatrice_Ranking:SetCell(colptsrun, row, pts_run);
				if params.comboPtsTps == 0 then
					if clt_run < best_clt then
						best_clt = clt_run;
						best_run = idxrun;
						best_pts = pts_run;
						best_tps = tps_run;
					end
				elseif params.comboPtsTps == 1 then
					if pts_run < best_pts then
						best_clt = clt_run;
						best_run = idxrun;
						best_pts = pts_run;
						best_tps = tps_run;
					end
				elseif params.comboPtsTps == 2 then
					if clt_run < best_clt then
						best_clt = clt_run;
						best_run = idxrun;
						best_pts = pts_run;
						best_tps = tps_run;
					end
				end
			end
			if best_run then
				tMatrice_Ranking:SetCell(colbestrun, row, best_run);
				tMatrice_Ranking:SetCell(colbestclt, row, best_clt);
				tMatrice_Ranking:SetCell(colbestpts, row, best_pts);
				tMatrice_Ranking:SetCell(colbesttps, row, best_tps);
			end
			local pts_total = nil;
			local tps_total = nil;
			if params.comboPrendre == 0 then				-- géréral
				pts_total = pts;
				tps_total = tps;
			elseif params.comboPrendre == 1 then			-- général PLUS meilleure manche
				pts_total = pts;
				tps_total = tps;
				if tCourses[idxcourse].NbManches > 1 then
					pts_total = pts_total + best_pts;
					tps_total = tpstotal + best_tps;
				end					
			elseif params.comboPrendre == 2 then			-- général OU meilleure manche
				if params.comboPtsTps == 0 then
					pts_total = math.max(pts, best_pts);
				elseif params.comboPtsTps == 1 then
					pts_total = math.min(pts, best_pts);
				elseif params.comboPtsTps == 2 then
					tps_total = math.min(tps, best_tps);
				end
			end
			tMatrice_Ranking:SetCell(colptstotal, row, pts_total);
			tMatrice_Ranking:SetCell(coltpstotal, row, tps_total);
		end
	end
	tMatrice_Ranking:OrderBy('Sexe, Identite');
	if params.debug then
		tMatrice_Ranking:Snapshot('tMatrice_Ranking.db3');
	end
end

function main(params_c)
	params = {};
	params.code_evenement = params_c.code_evenement;
	if params.code_evenement < 0 then
		return;
	end
	params.width = (display:GetSize().width * 2) / 3;
	params.height = display:GetSize().height / 2;
	params.x = (display:GetSize().width - params.width) / 2;
	params.y = 50;
	params.debug = false;
	params.version = "1.2";
	base = base or sqlBase.Clone();
	tPlace_Valeur = base:GetTable('Place_Valeur');
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	tResultat = base:GetTable('Resultat');
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tResultat_Manche = base:GetTable('Resultat_Manche');
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	tDiscipline = base:GetTable('Discipline');
	-- Ouverture Document XML 
	XML = "./process/regroupementALP.xml";
	params.doc = xmlDocument.Create(XML);
	assert(params.doc~= nil);
	params.nodeConfig = params.doc:FindFirst('root/config');
	assert(params.nodeConfig ~= nil);
	for i =1, 3 do
		params['coursef'..i] = tonumber(params.nodeConfig:GetAttribute('coursef'..i)) or 0;
		params['courseg'..i] = tonumber(params.nodeConfig:GetAttribute('courseg'..i)) or 0;
		params['coursef'..i..'_filtre'] = params.nodeConfig:GetAttribute('coursef'..i..'_filtre');
		params['courseg'..i..'_filtre'] = params.nodeConfig:GetAttribute('courseg'..i..'_filtre');
	end
	
	if params.nodeConfig:HasAttribute('titre') then
		params.titre = params.nodeConfig:GetAttribute('titre');
	else
		params.titre = tEvenement:GetCell('Nom', 0);
	end
	
	if params.nodeConfig:HasAttribute('comboColEquipe') then
		params.comboColEquipe = tonumber(params.nodeConfig:GetAttribute('comboColEquipe')) or 0;
	else
		params.comboColEquipe = 0;
	end
	
	if params.nodeConfig:HasAttribute('comboPrendre') then
		params.comboPrendre = tonumber(params.nodeConfig:GetAttribute('comboPrendre')) or 0;
	else
		params.comboPrendre = 0;
	end
	
	if params.nodeConfig:HasAttribute('comboPtsTps') then
		params.comboPtsTps = tonumber(params.nodeConfig:GetAttribute('comboPtsTps')) or 0;
	else
		params.comboPtsTps = 0;
	end

	if params.nodeConfig:HasAttribute('coefManche') then
		params.coefManche = tonumber(params.nodeConfig:GetAttribute('coefManche')) or 50;
	else
		params.coefManche = 50;
	end
	if params.nodeConfig:HasAttribute('nb_filles') then
		params.nb_filles = tonumber(params.nodeConfig:GetAttribute('nb_filles')) or 2;
	else
		params.nb_filles = 2;
	end
	if params.nodeConfig:HasAttribute('nb_garcons') then
		params.nb_garcons = tonumber(params.nodeConfig:GetAttribute('nb_garcons')) or 2;
	else
		params.nb_garcons = 2;
	end
	if params.nodeConfig:HasAttribute('comboAbdDsq') then
		params.comboAbdDsq = params.nodeConfig:GetAttribute('comboAbdDsq');
	else
		params.comboAbdDsq = 0;
	end
	if params.nodeConfig:HasAttribute('comboGarderEquipe') then
		params.comboGarderEquipe = params.nodeConfig:GetAttribute('comboGarderEquipe');
	else
		params.comboGarderEquipe = 0;
	end

	dlgConfig = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Configuration du Regroupement', 
		icon='./res/32x32_ffs.png'
		});
	dlgConfig:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		discipline = params.discipline,
		node_value = 'config',
		niveau = params.code_niveau
	});

	-- Toolbar Principale ...
	local tbconfig = dlgConfig:GetWindowName('tbconfig');
	tbconfig:AddStretchableSpace();
	local btnSave = tbconfig:AddTool("Lancer le calcul", "./res/vpe32x32_save.png");
	tbconfig:AddSeparator();
	local btnClose = tbconfig:AddTool("Quitter", "./res/32x32_exit.png");
	tbconfig:AddStretchableSpace();
	tbconfig:Realize();
	local message = app.GetAuiMessage();
	
	for i = 1, 3 do
		if params['coursef'..i] > 0 then
			tEvenement = base:TableLoad('Select * From Evenement Where Code = '..params['coursef'..i]);
			dlgConfig:GetWindowName('coursef'..i):SetValue(params['coursef'..i]);
			dlgConfig:GetWindowName('coursef'..i..'_nom'):SetValue(tEvenement:GetCell('Nom', 0));
		end
		if params['courseg'..i] > 0 then
			tEvenement = base:TableLoad('Select * From Evenement Where Code = '..params['courseg'..i]);
			dlgConfig:GetWindowName('courseg'..i):SetValue(params['courseg'..i]);
			dlgConfig:GetWindowName('courseg'..i..'_nom'):SetValue(tEvenement:GetCell('Nom', 0));
		end
	end
	
	dlgConfig:GetWindowName('comboColEquipe'):Clear();
	dlgConfig:GetWindowName('comboColEquipe'):Append('Equipe');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Groupe');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Critere');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Club');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Comite');
	dlgConfig:GetWindowName('comboColEquipe'):Append('Nation');
	dlgConfig:GetWindowName('comboColEquipe'):SetSelection(params.comboColEquipe);

	dlgConfig:GetWindowName('comboAbdDsq'):Clear();
	dlgConfig:GetWindowName('comboAbdDsq'):Append('Non');
	dlgConfig:GetWindowName('comboAbdDsq'):Append('Oui');
	dlgConfig:GetWindowName('comboAbdDsq'):SetSelection(params.comboAbdDsq);
	
	dlgConfig:GetWindowName('comboGarderEquipe'):Clear();
	dlgConfig:GetWindowName('comboGarderEquipe'):Append('Non');
	dlgConfig:GetWindowName('comboGarderEquipe'):Append('Oui');
	dlgConfig:GetWindowName('comboGarderEquipe'):SetSelection(params.comboGarderEquipe);

	dlgConfig:GetWindowName('comboPrendre'):Clear();
	dlgConfig:GetWindowName('comboPrendre'):Append('Classement général');
	dlgConfig:GetWindowName('comboPrendre'):Append('Classement général PLUS meilleure manche');
	dlgConfig:GetWindowName('comboPrendre'):Append('Classement général OU meilleure manche');
	dlgConfig:GetWindowName('comboPrendre'):SetSelection(params.comboPrendre);
	
	dlgConfig:GetWindowName('comboPtsTps'):Clear();
	dlgConfig:GetWindowName('comboPtsTps'):Append('Points Coupe du Monde');
	dlgConfig:GetWindowName('comboPtsTps'):Append('Points Course');
	dlgConfig:GetWindowName('comboPtsTps'):Append('Temps');
	dlgConfig:GetWindowName('comboPtsTps'):SetSelection(params.comboPtsTps);
	if params.comboPtsTps > 0 then
		dlgConfig:GetWindowName('coefManche'):Enable(false);
	end
	
	dlgConfig:GetWindowName('titre'):SetValue(params.titre);
	dlgConfig:GetWindowName('coefManche'):SetValue(params.coefManche);
	dlgConfig:GetWindowName('nb_filles'):SetValue(params.nb_filles);
	dlgConfig:GetWindowName('nb_garcons'):SetValue(params.nb_garcons);
	
	
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt) 
			params.comboPtsTps = dlgConfig:GetWindowName('comboPtsTps'):GetSelection();
			if params.comboPtsTps > 0 then
				dlgConfig:GetWindowName('comboAbdDsq'):SetSelection(1);
				dlgConfig:GetWindowName('coefManche'):SetValue(100);
				dlgConfig:GetWindowName('coefManche'):Enable(false);
				if params.comboPtsTps == 2 then
					dlgConfig:GetWindowName('comboAbdDsq'):Enable(false);
				end
			else
				dlgConfig:GetWindowName('coefManche'):Enable(true);
				dlgConfig:GetWindowName('comboAbdDsq'):Enable(true);
			end
		end, dlgConfig:GetWindowName('comboPtsTps')); 

	for i = 1, 3 do
		dlgConfig:Bind(eventType.TEXT, 
			function(evt) 
				params['coursef'..i] = tonumber(dlgConfig:GetWindowName('coursef'..i):GetValue()) or -1;
				tEvenement = base:TableLoad('Select Nom From Evenement Where Code = '..params['coursef'..i]);
				if tEvenement:GetNbRows() > 0 then
					dlgConfig:GetWindowName('coursef'..i..'_nom'):SetValue(tEvenement:GetCell('Nom', 0));
					dlgConfig:GetWindowName('filtragef'..i):Enable(true);
				else
					dlgConfig:GetWindowName('coursef'..i..'_nom'):SetValue('?');
					dlgConfig:GetWindowName('filtragef'..i):Enable(false);
				end
			end, dlgConfig:GetWindowName('coursef'..i)); 
		dlgConfig:Bind(eventType.BUTTON, 
			function(evt) 
				filtre = OnFiltrageCourse(params['coursef'..i]) ;
				if filtre:len() > 0  then
					params.nodeConfig:ChangeAttribute('coursef'..i..'_filtre', filtre);
					params['coursef'..i..'_filtre'] = filtre;
				else
					params.nodeConfig:DeleteAttribute('coursef'..i..'_filtre');
					params['coursef'..i..'_filtre'] = '';
				end
				params.doc:SaveFile();
			end, dlgConfig:GetWindowName('filtragef'..i));
		dlgConfig:Bind(eventType.TEXT, 
			function(evt) 
				params['courseg'..i] = tonumber(dlgConfig:GetWindowName('courseg'..i):GetValue()) or -1;
				tEvenement = base:TableLoad('Select Nom From Evenement Where Code = '..params['courseg'..i]);
				if tEvenement:GetNbRows() > 0 then
					dlgConfig:GetWindowName('courseg'..i..'_nom'):SetValue(tEvenement:GetCell('Nom', 0));
					dlgConfig:GetWindowName('filtrageg'..i):Enable(true);
				else
					dlgConfig:GetWindowName('courseg'..i..'_nom'):SetValue('');
					dlgConfig:GetWindowName('filtrageg'..i):Enable(false);
				end
			end, dlgConfig:GetWindowName('courseg'..i)); 
		dlgConfig:Bind(eventType.BUTTON, 
			function(evt) 
				filtre = OnFiltrageCourse(params['courseg'..i]) ;
				if filtre:len() > 0 then
					params.nodeConfig:ChangeAttribute('courseg'..i..'_filtre', filtre);
					params['courseg'..i..'_filtre'] = filtre;
				else
					params.nodeConfig:DeleteAttribute('courseg'..i..'_filtre');
					params['courseg'..i..'_filtre'] = '';
				end
				params.doc:SaveFile();
			end, dlgConfig:GetWindowName('filtrageg'..i));
	end
		
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			params.nb_courses_filles = 0;
			params.nb_courses_garcons = 0;
			params.courses_in  = "-1";
			params.titre = dlgConfig:GetWindowName('titre'):GetValue();
			for i = 1, 3 do
				params['coursef'..i] = tonumber(dlgConfig:GetWindowName('coursef'..i):GetValue()) or 0;
				if params['coursef'..i] > 0 then
					params.nb_courses_filles = params.nb_courses_filles + 1;
					params.nodeConfig:ChangeAttribute('coursef'..i, params['coursef'..i]);
					params.courses_in = params.courses_in..','..params['coursef'..i];
				else
					params.nodeConfig:DeleteAttribute('coursef'..i);
					params.nodeConfig:DeleteAttribute('coursef'..i..'_filtre');
					dlgConfig:GetWindowName('coursef'..i..'_nom'):SetValue('');
				end
				params['courseg'..i] = tonumber(dlgConfig:GetWindowName('courseg'..i):GetValue()) or 0;
				if params['courseg'..i] > 0 then
					params.nb_courses_garcons = params.nb_courses_garcons + 1;
					params.nodeConfig:ChangeAttribute('courseg'..i, params['courseg'..i]);
					params.courses_in = params.courses_in..','..params['courseg'..i];
				else
					params.nodeConfig:DeleteAttribute('courseg'..i);
					params.nodeConfig:DeleteAttribute('courseg'..i..'_filtre');
					dlgConfig:GetWindowName('coursef'..i..'_nom'):SetValue('');
				end
			end
			params.comboColEquipe = dlgConfig:GetWindowName('comboColEquipe'):GetSelection();
			params.comboAbdDsq = dlgConfig:GetWindowName('comboAbdDsq'):GetSelection();
			params.comboPrendre = dlgConfig:GetWindowName('comboPrendre'):GetSelection();
			params.comboPtsTps = dlgConfig:GetWindowName('comboPtsTps'):GetSelection();
			params.comboGarderEquipe = dlgConfig:GetWindowName('comboGarderEquipe'):GetSelection();
			if params.comboPtsTps == 0 then
				params.default_pts = 0;
			elseif params.comboPtsTps == 1 then
				params.default_pts = 10000;
			end
			params.coefManche = tonumber(dlgConfig:GetWindowName('coefManche'):GetValue()) or 50;
			params.nb_filles = tonumber(dlgConfig:GetWindowName('nb_filles'):GetValue()) or 0;
			params.nb_garcons = tonumber(dlgConfig:GetWindowName('nb_garcons'):GetValue()) or 0;

			params.nodeConfig:ChangeAttribute('titre', params.titre);
			params.nodeConfig:ChangeAttribute('comboColEquipe', params.comboColEquipe);
			params.nodeConfig:ChangeAttribute('comboPrendre', params.comboPrendre);
			params.nodeConfig:ChangeAttribute('comboPtsTps', params.comboPtsTps);
			params.nodeConfig:ChangeAttribute('comboAbdDsq', params.comboAbdDsq);
			params.nodeConfig:ChangeAttribute('coefManche', params.coefManche);
			params.nodeConfig:ChangeAttribute('nb_filles', params.nb_filles);
			params.nodeConfig:ChangeAttribute('nb_garcons', params.nb_garcons);
			params.nodeConfig:ChangeAttribute('comboGarderEquipe', params.comboGarderEquipe);
			params.doc:SaveFile();
			BuildRanking();
			BuildEquipes(); 		-- tEquipe ne contient que celles qui participent au classement (nombre suffisant de coureurs)
			dlgConfig:EndModal(idButton.OK);
		end, btnSave); 
		
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:EndModal(idButton.CANCEL);
		 end,  btnClose);

	dlgConfig:Fit();
	if dlgConfig:ShowModal() == idButton.OK then
		OnPrint();
	end
	return true;
end




