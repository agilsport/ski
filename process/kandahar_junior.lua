-- Calcul d'un temps manuel (avec 10 avant ou avec décalage)
dofile('./edition/functionPG.lua');
dofile('./interface/adv.lua');

function BuildGrille_Point_Place()		-- Création de la table Grille_Point_Place selon l'activité
	local cmd = "Select * From Place_valeur Where Code_activite = 'CHA-CMB' And Code_grille = 'FIS-CM' And Code_saison = '"..params.saison.."' Order By Place";
	base:TableLoad(tPlace_Valeur, cmd);
end


function OnFiltrageCourse(code_evenement, sexe)
	local filtre = "$(Sexe):In('"..sexe.."')";
	local cmd = 'Select * From Resultat Where Code_evenement = '..code_evenement;
	base:TableLoad(tResultat, cmd);
	if tResultat:GetNbRows() > 0 then
		local filterCmd = wnd.FilterConcurrentDialog({ 
			sqlTable = tResultat,
			key = 'cmd'});
		if type(filterCmd) == 'string' and filterCmd:len() > 3 then
			filtre = filtre..' And '..filterCmd;
		end
	end
	return filtre;
end

function OnPrint()
	local utf8 = true;
	local strPrendre = '(par '..dlgConfig:GetWindowName('comboPrendre'):GetValue()..')';
	report = wnd.LoadTemplateReportXML({
		xml = './process/kandahar_junior.xml',
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
		params = {Version = script_version, Titre = params.titre, Prendre = strPrendre, CoursesIn = params.courses_in, NbCourses = tMatrice_Courses:GetNbRows(), NbCoursesFilles = params.nb_courses_filles, NbFilles = params.nb_filles, NbCoursesGarcons = params.nb_courses_garcons, NbGarcons = params.nb_garcons, PtsTps = params.comboPtsTps}
	});
	-- report:SetZoom(10)
end

function GetPointsCourse(idxcourse, tps, best, facteur_f)		-- application de la formule de calcul
	if params.debug == true then
		if idxcourse == 2 then
			adv.Alert(',tps = '..tostring(tps)..', Tps best = '..tostring(best));
		end
	end
	pts = ((tps / best) - 1) * facteur_f;
	pts = Round(pts, 2);
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

function GetSetData(sexe, code, ligne, ordre, row)
	local tps_last = nil;
	local tps_first = -1;
	local facteur_f = nil;
	local index_filtre = '';
	local ordre_xml = ligne;
	local cmd = "Select * From Discipline Where Code_activite = '"..tMatrice_Courses:GetCell('Code_activite', row).."' And Code_entite = '"..tMatrice_Courses:GetCell('Code_entite', row).."' And Code_saison = '"..tMatrice_Courses:GetCell('Code_saison', row).."' And Code = '"..tMatrice_Courses:GetCell('Code_discipline', row).."'";
	base:TableLoad(tDiscipline, cmd);
	facteur_f = tDiscipline:GetCellInt('Facteur_f', 0);
	tMatrice_Courses:SetCell('Facteur_f', row, facteur_f);
	tMatrice_Courses:SetCell('Sexe', row, sexe);
	tMatrice_Courses:SetCell('Ordre_xml', row, ordre_xml);
	tMatrice_Courses:SetCell('Ordre', row, ordre);
	if sexe == 'F' then
		index_filtre = 'coursef'..ligne..'_filtre';
	else
		index_filtre = 'courseg'..ligne..'_filtre';
	end
	if params[index_filtre] then 
		tMatrice_Courses:SetCell('Filtre', row, params[index_filtre]);
	end

	local cmd = 'Select * From Resultat Where Code_evenement = '..code..' Order By Tps DESC';
	base:TableLoad(tResultat, cmd);

	local filter = tMatrice_Courses:GetCell('Filtre', row);
	if filter:len() > 0 then
		tResultat:Filter(filter, true);
	end

	tps_last = tResultat:GetCellInt('Tps', 0);
	clt_last = tResultat:GetCellInt('Clt', 0);
	for idx = tResultat:GetNbRows() -1, 0, -1 do
		if tResultat:GetCellInt('Tps', idx) > 0 then
			tps_first = tResultat:GetCellInt('Tps', idx);
			break;
		end
	end
	tMatrice_Courses:SetCell('Tps_last', row, tps_last);
	tMatrice_Courses:SetCell('Clt_last', row, clt_last);
	tMatrice_Courses:SetCell('Tps_first', row, tps_first);
	local nombre_de_manche = tMatrice_Courses:GetCellInt('Nombre_de_manche',row);
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
		tMatrice_Courses:SetCell('Tps_last_m'..j, row, tps_last_run);
		tMatrice_Courses:SetCell('Tps_first_m'..j, row, tps_first_run);
		table.insert(runs, {Run = j, TpsFirst = tps_first_run, TpsLast = tps_last_run, CltLast = clt_last_run});
	end
	filter = filter or '';
	tMatrice_Courses:SetCell('Coef_manche', row, params.coefManche);
	tCourses[ordre]= {};
	tCourses[ordre].Code_evenement = code;
	tCourses[ordre].Ordre_xml = ordre_xml;
	tCourses[ordre].Filtre = filter;
	tCourses[ordre].TpsFirst = tps_first;
	tCourses[ordre].TpsLast = tps_last;
	tCourses[ordre].CltLast = clt_last;
	tCourses[ordre].Facteur_f = facteur_f;
	tCourses[ordre].NbManches = nombre_de_manche;
	tCourses[ordre].Runs = runs;

end

function LitMatriceCourses();	-- lecture des courses figurant dans la valeur params.courses_in
	local cmd = 'Select * from Epreuve Where Code_evenement In('..params.courses_in..') Order By Nombre_de_manche DESC';
	tEpreuve = base:TableLoad(cmd);
	local nb_manche_max = tEpreuve:GetCellInt('Nombre_de_manche', 0);
	params.saison = tEpreuve:GetCell('Code_saison', 0);
	local cmd = "Select Ev.Code, Ev.Nom, Ev.Code_entite, Ev.Code_activite, Repeat(' ',200) Filtre, Ep.Code_discipline, Ep.Date_epreuve, 0 Facteur_f, Ep.Sexe, Ep.Code_saison, Ep.Nombre_de_manche, 0 Prise, 0 Ordre_xml, 0 Ordre, 0 Tps_last, 0 Tps_first, 0 Clt_last, 0 Nb_col, 0 Coef_manche";
	for i = 1, nb_manche_max do
		cmd = cmd.." ,0 Tps_last_m"..i;
		cmd = cmd.." ,0 Tps_first_m"..i;
	end
	cmd = cmd .." From Evenement Ev, Epreuve Ep "..
				" Where Ev.Code = Ep.Code_evenement "..
				" And Ev.Code In("..params.courses_in..") And Ep.Code_epreuve = 1 "..
				" Order By Ep.Date_epreuve, Sexe, Code";
	tMatrice_Courses = base:TableLoad(cmd);
	tMatrice_Courses:SetPrimary('Code');
	ReplaceTableEnvironnement(tMatrice_Courses, '_Matrice_Courses');
	tCourses = {};

	local ordre = 0;
	local idxcourse = 0;
	local r = -1;
	for ligne = 1, 3 do
		if params['coursef'..ligne] then
			local r = tMatrice_Courses:GetIndexRow('Code', params['coursef'..ligne]);
			ordre = ordre + 1;
			GetSetData('F',params['coursef'..ligne], ligne, ordre, r);
		end
	end
	ordre = 3;
	for ligne = 1, 3 do
		if params['courseg'..ligne] then
			local r = tMatrice_Courses:GetIndexRow('Code', params['courseg'..ligne]);
			ordre = ordre + 1;
			GetSetData('M',params['courseg'..ligne], ligne, ordre, r);
		end
	end
	tMatrice_Courses:OrderBy('Ordre');
	tMatrice_Courses:Snapshot('tMatrice_Courses.db3');
end

function BuildEquipes()
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
	if params.debug == true then
		tEquipe:Snapshot('tEquipe_build.db3')
	end
 	tEquipe:OrderBy(col_equipe);
	tEquipe:SetPrimary(col_equipe);
	ReplaceTableEnvironnement(tEquipe, '_Equipe');
	if params.debug == true then
		tEquipe:Snapshot('tEquipe_build.db3');
	end
	tMatrice_Courses:OrderBy('Ordre');
	for i = 0, tEquipe:GetNbRows() -1 do
		local OK = 1;
		local equipe = tEquipe:GetCell(col_equipe, i);
		local pts_total = 0;
		local tps_total = 0;
		local strGarcons = '';
		local separateur_filles = '';
		local separateur_garcons = '';
		for row_course = 0, tMatrice_Courses:GetNbRows() -1 do
			local nb_filles_pris = 0;
			local nb_garcons_pris = 0;
			local idxcourse = tMatrice_Courses:GetCellInt('Ordre', row_course);
			local ordre_xml = tMatrice_Courses:GetCellInt('Ordre_xml', row_course);
			---local ordre = tMatrice_Courses:GetCellInt('Ordre', row_course);
			local sexe_course = tMatrice_Courses:GetCell('Sexe', row_course);
			local code_evenement = tMatrice_Courses:GetCellInt('Code', row_course);
			local nombre_de_manche = tMatrice_Courses:GetCellInt('Nombre_de_manche', row_course);
			tEquipe:SetCell('Course'..idxcourse, i, code_evenement);
			tMatrice_Ranking_Copy = tMatrice_Ranking:Copy();
			local filter = '$('..col_equipe.."):In('"..equipe.."') and $(Code_evenement"..idxcourse.."):In('"..code_evenement.."')";
			tMatrice_Ranking_Copy:Filter(filter, true);		-- il reste les coureurs de l'équipe dans cette course.
			if params.comboPtsTps == 0 then
				tMatrice_Ranking_Copy:OrderBy('Pts'..idxcourse..'_total Desc');
			else
				tMatrice_Ranking_Copy:OrderBy('Pts'..idxcourse..'_total');
			end
			if params.debug == true then 
				adv.Alert('course : '..idxcourse..', taille de tMatrice_Ranking_Copy = '..tMatrice_Ranking_Copy:GetNbRows()..'\npour un filtre : '..filter);
			end
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
							if params.debug == true then
								adv.Alert('on insere dans tDetailFilles : '..jsontxt);
							end
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
		nb_filles = #tdetailfille
		local tdetailgarcons = tEquipe:GetCell('Detail_garcons', i):Split('|');
		nb_garcons = #tdetailgarcons
		if tEquipe:GetCell('Detail_filles', i):len() == 0 or tEquipe:GetCell('Detail_garcons', i):len() == 0 then
			OK = 0;
		end
		if params.comboPtsTps > 0 then
			if nb_filles < (params.nb_filles * params.nb_courses_filles)  or nb_garcons < (params.nb_garcons * params.nb_courses_garcons) then
				OK = 0;
			end
		end
		tEquipe:SetCell('OK',i, OK);
		tEquipe:SetCell('Pts_total',i, pts_total);
		tEquipe:SetCell('Tps_total',i, tps_total);
	end
	local filter = '$(OK):In(1)';
	tEquipe:Filter(filter, true)
	if params.comboPtsTps == 0 then
		tEquipe:SetRanking('Clt', 'Pts_total DESC', '');
	elseif params.comboPtsTps == 1 then
		tEquipe:SetRanking('Clt', 'Pts_total ASC', '');
	elseif params.comboPtsTps == 2 then
		tEquipe:SetRanking('Clt', 'Tps_total ASC', '');
	end
	tEquipe:OrderBy('Clt');
	tEquipe:Snapshot('tEquipe.db3');
end

function BuildRanking();
	LitMatriceCourses();
	BuildGrille_Point_Place();
	cmd = 'Select Code_coureur From Resultat Where Code_evenement in('..params.courses_in..') ';
	cmd = cmd..' Group By Code_coureur';
	tMatrice_Ranking = base:TableLoad(cmd);
	ReplaceTableEnvironnement(tMatrice_Ranking, '_tMatrice_Ranking');
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

	for row = 0, tMatrice_Courses:GetNbRows() -1 do
		local idxcourse = tMatrice_Courses:GetCellInt('Ordre', row);
		local discipline = tMatrice_Courses:GetCell('Code_discipline', row);
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
		for idxrun = 1, tMatrice_Courses:GetCellInt('Nombre_de_manche', row) do
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
	for row_course = 0, tMatrice_Courses:GetNbRows() -1 do
		local nombre_de_manche = tMatrice_Courses:GetCellInt('Nombre_de_manche', row_course);
		local idxcourse = tMatrice_Courses:GetCellInt('Ordre', row_course);
		local ordre_xml = tMatrice_Courses:GetCellInt('Ordre_xml', row_course);
		local discipline = tMatrice_Courses:GetCell('Code_discipline', row_course)
		local code_evenement = tMatrice_Courses:GetCellInt('Code', row_course);
		local cmd = 'Select * From Resultat Where Code_evenement = '..code_evenement..' Order By Code_coureur';
		local coltps = 'Tps'..idxcourse;
		base:TableLoad(tResultat, cmd);
		local filter = tMatrice_Courses:GetCell('Filtre', row_course);
		if filter:len() > 0 then
			tResultat:Filter(filter, true);
		end
		if params.debug == true then
			adv.Alert('taille de tResultat pour Code_evenement = '..code_evenement..' = '..tResultat:GetNbRows());
		end
		-- table.insert(tCourses, {Code_evenement = code, TpsFirst = tps_first, TpsLast = tps_last, Facteur_f = facteur_f, NbManches = nombre_de_manche, Runs = runs})
		for row = 0, tMatrice_Ranking:GetNbRows() -1 do
			local code_coureur = tMatrice_Ranking:GetCell('Code_coureur', row);
			local tps = -1;
			local r = tResultat:GetIndexRow('Code_coureur', code_coureur);
			if r >= 0 then
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
				if tMatrice_Ranking:GetCell('Groupe', row):len() == 0 then
					tMatrice_Ranking:SetCell('Groupe', row, tResultat:GetCell('Groupe', r));
				end
				if tMatrice_Ranking:GetCell('Equipe', row):len() == 0 then
					tMatrice_Ranking:SetCell('Equipe', row, tResultat:GetCell('Equipe', r));
				end
				if tMatrice_Ranking:GetCell('Critere', row):len() == 0 then
					tMatrice_Ranking:SetCell('Critere', row, tResultat:GetCell('Critere', r));
				end
				tMatrice_Ranking:SetCell('Code_evenement'..idxcourse, row, code_evenement)
				tMatrice_Ranking:SetCell('Ordre_xml'..idxcourse, row, ordre_xml);
				tMatrice_Ranking:SetCell('Ordre'..idxcourse, row, idxcourse);
				local tps = -1;
				tps = tResultat:GetCellInt('Tps', r, -1);
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
		tMatrice_Ranking:SetRanking('Clt'..idxcourse, 'Tps'..idxcourse, '');
		for idxrun = 1, nombre_de_manche do
			local coltpsrun = 'Tps'..idxcourse..'_run'..idxrun;
			local colcltrun = 'Clt'..idxcourse..'_run'..idxrun;
			tMatrice_Ranking:SetRanking(colcltrun, coltpsrun, '');
		end
	end
	for row = 0, tMatrice_Ranking:GetNbRows() -1 do
		for row_course = 0, tMatrice_Courses:GetNbRows() -1 do
			local idxcourse = tMatrice_Courses:GetCellInt('Ordre', row_course);
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
			local ordre = tMatrice_Courses:GetCellInt('Ordre', row_course);
			if params.comboPtsTps == 0 then
				pts = GetPointPlace(tMatrice_Ranking:GetCellInt(colclt, row));
			elseif params.comboPtsTps == 1 then
				if tps > 0 then
					if params.debug == true then
						adv.Alert('course '..idxcourse..', calcul des points course pour '..tMatrice_Ranking:GetCell('Identite', row)..', coltps = '..coltps)
					end
					pts = GetPointsCourse(idxcourse, tps, tCourses[idxcourse].TpsFirst, tCourses[idxcourse].Facteur_f)		-- application de la formule de calcul
				else
					pts = params.default_pts;
				end
			end
			tMatrice_Ranking:SetCell('Pts'..idxcourse, row, pts)
			local nb_run = tMatrice_Courses:GetCellInt('Nombre_de_manche', row_course);
			local best_pts = params.default_pts;
			local pts_run = params.default_pts;
			local best_clt = 10000;
			local best_run = nil;
			local best_tps = nil;
			for idxrun = 1, nb_run do
				local colcltrun = 'Clt'..idxcourse..'_run'..idxrun;
				local coltpsrun = 'Tps'..idxcourse..'_run'..idxrun;
				local colptsrun = 'Pts'..idxcourse..'_run'..idxrun;
				local clt_run = tMatrice_Ranking:GetCellInt(colcltrun, row, 10000);
				local tps_run = tMatrice_Ranking:GetCellInt(coltpsrun, row, -1);
				if params.comboPtsTps == 0 then
					pts_run = GetPointPlace(clt_run);
					pts_run = pts_run * params.coefManche / 100;
				elseif params.comboPtsTps == 1 and params.comboPrendre > 0 then
					if tps_run > 0 then
						if params.debug == true then
							adv.Alert('course '..idxcourse..', calcul des points du run '..idxrun..' pour '..tMatrice_Ranking:GetCell('Identite', row)..', coltpsrun = '..coltpsrun);
						end
						pts_run = GetPointsCourse(idxcourse, tpsrun, tCourses[idxcourse].Runs[idxrun].TpsFirst, tCourses[idxcourse].Facteur_f)		-- application de la formule de calcul
					else
						pts_run = params.default_pts;
					end
						
				end
				tMatrice_Ranking:SetCell(colptsrun, row, pts_run);
				if clt_run > 0 and clt_run < best_clt then
					best_clt = clt_run;
					best_run = idxrun;
					best_pts = pts_run;
					best_tps = tps_run;
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
				if params.comboPtsTps == 0 then				-- pts Coupe du Monde
					pts_total = pts + best_pts;
				elseif params.comboPtsTps == 1 then			-- pts course
					pts_total = pts + math.min(pts, best_pts);
				elseif params.comboPtsTps == 2 then			-- addition des temps
					tps_total = tps + best_tps;
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
	-- tMatrice_Courses:Snapshot('tMatrice_Courses.db3');
	if params.debug == true then
		tMatrice_Ranking:Snapshot('tMatrice_Ranking.db3');
	end
end

function SetEquipe()
	dlgEquipe = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Configuration des équipes du Kandahar Junior', 
		icon='./res/32x32_ffs.png'
		});
	dlgEquipe:LoadTemplateXML({ 
		xml = XML,
		node_name = 'root/panel', 
		node_attr = 'name', 
		discipline = params.discipline,
		node_value = 'equipe',
		niveau = params.code_niveau
	});

	dlgEquipe:GetWindowName('f_origine'):Clear();
	dlgEquipe:GetWindowName('f_origine'):Append('');
	dlgEquipe:GetWindowName('f_origine'):Append('Equipe');
	dlgEquipe:GetWindowName('f_origine'):Append('Groupe');
	dlgEquipe:GetWindowName('f_origine'):Append('Critere');
	dlgEquipe:GetWindowName('f_origine'):Append('Club');
	dlgEquipe:GetWindowName('f_origine'):Append('Comite');
	dlgEquipe:GetWindowName('f_origine'):Append('Nation');
	dlgEquipe:GetWindowName('f_origine'):SetSelection(4);

	dlgEquipe:GetWindowName('f_destination'):Clear();
	dlgEquipe:GetWindowName('f_destination'):Append('');
	dlgEquipe:GetWindowName('f_destination'):Append('Equipe');
	dlgEquipe:GetWindowName('f_destination'):Append('Groupe');
	dlgEquipe:GetWindowName('f_destination'):Append('Critere');
	dlgEquipe:GetWindowName('f_destination'):SetSelection(1);

	dlgEquipe:GetWindowName('e_origine'):Clear();
	dlgEquipe:GetWindowName('e_origine'):Append('');
	dlgEquipe:GetWindowName('e_origine'):Append('Equipe');
	dlgEquipe:GetWindowName('e_origine'):Append('Groupe');
	dlgEquipe:GetWindowName('e_origine'):Append('Critere');
	dlgEquipe:GetWindowName('e_origine'):Append('Club');
	dlgEquipe:GetWindowName('e_origine'):Append('Nation');
	dlgEquipe:GetWindowName('e_origine'):SetSelection(1);

	dlgEquipe:GetWindowName('e_destination'):Clear();
	dlgEquipe:GetWindowName('e_destination'):Append('');
	dlgEquipe:GetWindowName('e_destination'):Append('Equipe');
	dlgEquipe:GetWindowName('e_destination'):Append('Groupe');
	dlgEquipe:GetWindowName('e_destination'):Append('Critere');
	dlgEquipe:GetWindowName('e_destination'):SetSelection(1);

	-- Toolbar Principale ...
	local tb = dlgEquipe:GetWindowName('tb');
	tb:AddStretchableSpace();
	local btnBuildEquipe = tb:AddTool("Constituer les équipes", "./res/32x32_tools.png");
	tb:AddSeparator();
	local btnClose = tb:AddTool("Quitter", "./res/32x32_exit.png");
	tb:AddStretchableSpace();
	tb:Realize();
	
	dlgEquipe:Bind(eventType.MENU, 
		function(evt)
			local f_origine = dlgEquipe:GetWindowName('f_origine'):GetValue();
			local f_destination = dlgEquipe:GetWindowName('f_destination'):GetValue();
			local e_origine = dlgEquipe:GetWindowName('e_origine'):GetValue();
			local e_destination = dlgEquipe:GetWindowName('e_destination'):GetValue();
			local mess = 'Voulez-vous lancer la constitution automatique des équipes ?'..
				'\nPour les français, le contenu de la colonne '..f_destination..
				'\nsera remplacé par celui de la colonne '..f_origine..'.'..
				'\n\nPour les étrangers, le contenu de la colonne '..e_destination..
				'\nsera remplacé par celui de la colonne '..e_origine..'.';
			if app.GetAuiFrame():MessageBox(mess, 
				"Constitution automatique des équipes",
				msgBoxStyle.YES_NO + msgBoxStyle.NO_DEFAULT + msgBoxStyle.ICON_INFORMATION
				) == msgBoxStyle.YES then
				for i = 1, 3 do
					if string.len(dlgConfig:GetWindowName('coursef'..i..'_nom'):GetValue()) > 0 then
						if f_origine:len() > 0 and f_destination:len() > 0 then 
							local cmd = 'Update Resultat Set '..f_destination..' = '..f_origine.." Where Code_evenement = "..params['coursef'..i]..' And Nation = "FRA"';
							base:Query(cmd);
						end
						if e_origine:len() > 0 and e_destination:len() > 0 then 
							local cmd = 'Update Resultat Set '..e_destination..' = '..e_origine.." Where Code_evenement = "..params['coursef'..i]..' And Nation != "FRA"';
							base:Query(cmd);
							if e_origine == 'Nation' then
								base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params['coursef'..i]);
								for row = 0, tResultat:GetNbRows() -1 do
									local nation = tResultat:GetCell('Nation', row);
									if nation ~= 'FRA' then
										local r = tNation:GetIndexRow('Code',nation);
										if r >= 0 then
											nation = tNation:GetCell('Libelle', r);
											tResultat:SetCell(e_destination, row, nation);
										end
									end
								end
								base:TableBulkUpdate(tResultat);
							end
						end
					end
					if string.len(dlgConfig:GetWindowName('courseg'..i..'_nom'):GetValue()) > 0 then
						if f_origine:len() > 0 and f_destination:len() > 0 then 
							local cmd = 'Update Resultat Set '..f_destination..' = '..f_origine.." Where Code_evenement = "..params['courseg'..i]..' And Nation = "FRA"';
							base:Query(cmd);
						end
						if e_origine:len() > 0 and e_destination:len() > 0 then 
							local cmd = 'Update Resultat Set '..e_destination..' = '..e_origine.." Where Code_evenement = "..params['courseg'..i]..' And Nation != "FRA"';
							base:Query(cmd);
							if e_origine == 'Nation' then
								base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params['courseg'..i]);
								for row = 0, tResultat:GetNbRows() -1 do
									local nation = tResultat:GetCell('Nation', row);
									if nation ~= 'FRA' then
										local r = tNation:GetIndexRow('Code',nation);
										if r >= 0 then
											nation = tNation:GetCell('Libelle', r);
											tResultat:SetCell(e_destination, row, nation);
										end
									end
								end
								base:TableBulkUpdate(tResultat);
							end
						end
					end
				end
			end
			dlgEquipe:EndModal(idButton.CANCEL);
		 end,  btnBuildEquipe);
		 
	dlgEquipe:Bind(eventType.MENU, 
		function(evt) 
			dlgEquipe:EndModal(idButton.CANCEL);
		 end,  btnClose);
	dlgEquipe:Fit();
	dlgEquipe:ShowModal();
end

function main(params_c)
	params = {};
	params.code_evenement = params_c.code_evenement;
	if params.code_evenement < 0 then
		return;
	end
	params.width = (display:GetSize().width ) - 300;
	params.height = display:GetSize().height -200;
	params.x = (display:GetSize().width - params.width) / 2;
	params.y = 50;
	params.debug = false;
	
	script_version = "2.8"; 
	-- vérification de l'existence d'une version plus récente du script.
	-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2,DoubleTirage=3.2,TirageOptions=3.3,TirageER=1.7,ListeMinisterielle=2.3,KandaHarJunior=2.0
	if app.GetVersion() >= '4.4c' then 
		indice_return = 8;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	end

	local updatefile = './tmp/updatesPG.txt';
	if app.FileExists(updatefile) then
		local f = io.open(updatefile, 'r')
		for lines in f:lines() do
			alire = lines;
		end
		io.close(f);
		app.RemoveFile(updatefile);
		app.LaunchDefaultEditor('./'..alire);
	end

	base = base or sqlBase.Clone();
	tPlace_Valeur = base:GetTable('Place_Valeur');
	tEvenement = base:GetTable('Evenement');
	tNation = base:GetTable('Nation');
	Interrogation();
	tResultat = base:GetTable('Resultat');
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tResultat_Manche = base:GetTable('Resultat_Manche');
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	tDiscipline = base:GetTable('Discipline');
	-- Ouverture Document XML 
	XML = "./process/kandahar_junior.xml";
	params.doc = xmlDocument.Create(XML);
	assert(params.doc~= nil);
	params.nodeConfig = params.doc:FindFirst('root/config');
	assert(params.nodeConfig ~= nil);
	
	for i =1, 3 do
		params['coursef'..i] = tonumber(params.nodeConfig:GetAttribute('coursef'..i)) or 0;
		params['courseg'..i] = tonumber(params.nodeConfig:GetAttribute('courseg'..i)) or 0;
		params['coursef'..i..'_filtre'] = params.nodeConfig:GetAttribute('coursef'..i..'_filtre');
		params['courseg'..i..'_filtre'] = params.nodeConfig:GetAttribute('courseg'..i..'_filtre');
		base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params['coursef'..i]);
		if tEvenement:GetNbRows() == 0 then
			params['coursef'..i] = 0;
			params['coursef'..i..'_filtre'] = '';
		end
		base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params['coursef'..i]);
		if tEvenement:GetNbRows() == 0 then
			params['courseg'..i] = 0;
			params['courseg'..i..'_filtre'] = '';
		end
	end
	
	if params['coursef1'] > 0 then
		base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params['coursef1'])
		params.titre = tEvenement:GetCell('Commentaire', 0);
		if params.titre:len() == 0 then
			params.titre = tEvenement:GetCell('Nom', 0);
		end
	end
	params.titre = params.titre or 'Résultats du Kandahar Junior';
	params.titre2 = '\n\n(Le titre de l\'édition reprend le commentaire de la course n°1 filles ou son nom si le commentaire est vide)';
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

	dlgConfig = wnd.CreateDialog(
		{
		width = params.width,
		height = params.height,
		x = params.x,
		y = params.y,
		label='Configuration des résultats du Kandahar Junior - version '..script_version, 
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
	local btnBuildEquipe = tbconfig:AddTool("Constituer les équipes (facultatif)", "./res/32x32_tools.png");
	tbconfig:AddSeparator();
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
	
	dlgConfig:GetWindowName('titre'):SetValue(params.titre..params.titre2);
	dlgConfig:GetWindowName('coefManche'):SetValue(params.coefManche);
	dlgConfig:GetWindowName('nb_filles'):SetValue(params.nb_filles);
	dlgConfig:GetWindowName('nb_garcons'):SetValue(params.nb_garcons);
	
	
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
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
					dlgConfig:GetWindowName('coursef'..i..'_nom'):SetValue('');
					dlgConfig:GetWindowName('filtragef'..i):Enable(false);
				end
			end, dlgConfig:GetWindowName('coursef'..i)); 
		dlgConfig:Bind(eventType.BUTTON, 
			function(evt) 
				filtre = OnFiltrageCourse(params['coursef'..i], 'F') ;
				params.nodeConfig:ChangeAttribute('coursef'..i..'_filtre', filtre);
				params['coursef'..i..'_filtre'] = filtre;
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
				filtre = OnFiltrageCourse(params['courseg'..i], 'M') ;
				params.nodeConfig:ChangeAttribute('courseg'..i..'_filtre', filtre);
				params['courseg'..i..'_filtre'] = filtre;
				params.doc:SaveFile();
			end, dlgConfig:GetWindowName('filtrageg'..i));
	end
		
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			SetEquipe();
		end, btnBuildEquipe); 
		
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			params.nb_courses_filles = 0;
			params.nb_courses_garcons = 0;
			for i = 1, 3 do
				params['coursef'..i] = tonumber(dlgConfig:GetWindowName('coursef'..i):GetValue()) or 0;
				if params['coursef'..i] > 0 then
					params.nb_courses_filles = params.nb_courses_filles + 1;
				end
				params['courseg'..i] = tonumber(dlgConfig:GetWindowName('courseg'..i):GetValue()) or 0;
				if params['courseg'..i] > 0 then
					params.nb_courses_garcons = params.nb_courses_garcons + 1;
				end
				params.nodeConfig:ChangeAttribute('coursef'..i, params['coursef'..i]);
				params.nodeConfig:ChangeAttribute('courseg'..i, params['courseg'..i]);
			end
			params.comboColEquipe = dlgConfig:GetWindowName('comboColEquipe'):GetSelection();
			params.comboAbdDsq = dlgConfig:GetWindowName('comboAbdDsq'):GetSelection();
			params.comboPrendre = dlgConfig:GetWindowName('comboPrendre'):GetSelection();
			params.comboPtsTps = dlgConfig:GetWindowName('comboPtsTps'):GetSelection();
			if params.comboPtsTps == 0 then
				params.default_pts = 0;
			elseif params.comboPtsTps == 1 then
				params.default_pts = 10000;
			end
			params.coefManche = tonumber(dlgConfig:GetWindowName('coefManche'):GetValue()) or 50;
			params.nb_filles = tonumber(dlgConfig:GetWindowName('nb_filles'):GetValue()) or 2;
			params.nb_garcons = tonumber(dlgConfig:GetWindowName('nb_garcons'):GetValue()) or 2;

			params.nodeConfig:ChangeAttribute('titre', params.titre);
			params.nodeConfig:ChangeAttribute('comboColEquipe', params.comboColEquipe);
			params.nodeConfig:ChangeAttribute('comboPrendre', params.comboPrendre);
			params.nodeConfig:ChangeAttribute('comboPtsTps', params.comboPtsTps);
			params.nodeConfig:ChangeAttribute('comboAbdDsq', params.comboAbdDsq);
			params.nodeConfig:ChangeAttribute('coefManche', params.coefManche);
			params.nodeConfig:ChangeAttribute('nb_filles', params.nb_filles);
			params.nodeConfig:ChangeAttribute('nb_garcons', params.nb_garcons);
			params.doc:SaveFile();
			if params.coursef1 * params.courseg1 == 0 then
				return false;
			else
				params.courses_in = params.coursef1..','..params.courseg1;
				if params.coursef2 * params.courseg2 > 0 then
					params.courses_in = params.courses_in..','..params.coursef2..','..params.courseg2;
				end
				if params.coursef3 * params.courseg3 > 0 then
					params.courses_in = params.courses_in..','..params.coursef3..','..params.courseg3;
				end
			end
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




