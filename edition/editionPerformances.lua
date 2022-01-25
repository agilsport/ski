-- version 1.3
dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function ChoixManche()	-- boîte de dialogue pour la sélection de la params.code_manche.
	dlgManche = wnd.CreateDialog(
		{
		width = 300,
		height = 150,
		x = (display:GetSize().width - 200) / 2, 
		y = (display:GetSize().height - 150) / 2, 
		label='Selection de la params.code_manche', 
		icon='./res/32x32_ffs.png'
		});
	
	dlgManche:LoadTemplateXML({ 
		xml = './edition/editionPerformances.xml', 	-- Obligatoire
		node_name = 'edition/panel', 			
		node_attr = 'name', 				
		node_value = 'choix_manche', 		
		base = base,
		params = {}
	});

	for run = 1, params.nombre_de_manche do
		dlgManche:GetWindowName('manche'):Append(run);
	end
	dlgManche:GetWindowName('manche'):SetValue(1);
	-- Toolbar 
	local tb = dlgManche:GetWindowName('tb');
	tb:AddSeparator();
	local btnOK = tb:AddTool("OK", "./res/32x32_save.png");
	tb:AddSeparator();
	local btnKO = tb:AddTool("Annuler", "./res/32x32_quit.png");
	tb:AddSeparator();
	tb:Bind(eventType.MENU, function(evt) dlgManche:EndModal(idButton.OK) end, btnOK);
	tb:Bind(eventType.MENU, function(evt) dlgManche:EndModal(idButton.CANCEL) end, btnKO);
	tb:Realize();
	dlgManche:Fit();
	if dlgManche:ShowModal() == idButton.OK then
		choix_manche = tonumber(dlgManche:GetWindowName('manche'):GetValue());
	else
		choix_manche= 1;
	end
	return choix_manche;
end

function main(paramsc)
	params = paramsc;
	params.nombre_de_manche = base:GetTable('Epreuve'):GetCellInt('Nombre_de_manche', 0, 1);
	params.nb_temps_inter = base:GetTable('Epreuve_Alpine_Manche'):GetCellInt('Nb_temps_inter', 0);
	if params.nb_temps_inter > 0 then
		params.need = 1 + (0.4 * (params.nb_temps_inter-1));
		params.nb_row_ligne = 2 + (params.nb_temps_inter-1);
	else
		params.need = 1;
		params.nb_row_ligne = 2;
	end
	params.need = tostring(params.need):gsub(',','.')..'cm';
	params.orientation = 'portrait';
	params.code_manche = 1;
	-- Prise du numéro de manche 
	if params.nombre_de_manche > 1 then
		params.code_manche = ChoixManche();
	end

	tRanking = base.CreateTableRanking({ code_evenement = params.code_evenement, code_manche = params.code_manche});
	for i = 1, params.nb_temps_inter +1 do
		tRanking:AddColumn({ name = 'Secteur'..i..'_tps', label = 'Secteur'..i..'_tps', type = 7});
		tRanking:AddColumn({ name = 'Secteur'..i..'_diff', label = 'Secteur'..i..'_diff', type = 7});
		tRanking:AddColumn({ name = 'Secteur'..i..'_clt', label = 'Secteur'..i..'_clt', type = 5});
	end

	tRanking:OrderBy('Tps'..params.code_manche);
	-- avec 2 temps inter, on a 3 secteurs 
	-- secteur 1 = inter1 - 0 
	-- secteur 2 = inter2 - inter1 
	-- secteur 3 = arrivée - inter 2 
	tRanking:OrderBy('Clt');
		
	local tps1 = 0; local tps2 = 0;
	tInter = {};
	tSecteur = {};
	for i = 1, params.nb_temps_inter do 
		table.insert(tInter, {Best = 0});
	end
	for i = 1, params.nb_temps_inter +1 do 
		table.insert(tSecteur, {Best = 0});
	end
	for r=0,tRanking:GetNbRows()-1 do
		tps = tRanking:GetCellInt('Tps'..params.code_manche, r);
		for i = 1, params.nb_temps_inter +1 do 
			if i <= params.nb_temps_inter then
				local clt = tRanking:GetCellInt('Clt'..params.code_manche..'_inter'..i, r); 
				if clt == 1 then
					tInter[i].Best = tRanking:GetCellInt('Tps'..params.code_manche..'_inter'..i, r); 
				end
			end
			if i == 1 then 
				tps1 = 0; 
				tps2 = tRanking:GetCellInt('Tps'..params.code_manche..'_inter'..i, r, -1); 
			elseif i <= params.nb_temps_inter then 
				tps1 = tRanking:GetCellInt('Tps'..params.code_manche..'_inter'..i-1, r, -1) 
				tps2 = tRanking:GetCellInt('Tps'..params.code_manche..'_inter'..i, r, -1); 
			else 
				tps1 = tRanking:GetCellInt('Tps'..params.code_manche..'_inter'..i-1, r,-1); 
				tps2 = tRanking:GetCellInt('Tps'..params.code_manche, r,-1); 
			end 
	
			if tps1 >= 0 and tps2 >= 0 then 
				tRanking:SetCell('Secteur'..i..'_tps', r, tps2 - tps1); 
			end 
		end 
	end
	-- avec 2 temps inter, on a 3 secteurs 
	-- secteur 1 = inter1 - 0 
	-- secteur 2 = inter2 - inter1 
	-- secteur 3 = arrivée - inter 2 
	for i = 1, params.nb_temps_inter +1 do 
		tRanking:SetRanking('Secteur'..i..'_clt', 'Secteur'..i..'_tps'); 
		tRanking:OrderBy('Secteur'..i..'_clt');
		tSecteur[i].Best = tRanking:GetCellInt('Secteur'..i..'_tps', 0); 
	end 
	tRanking:OrderBy('Clt');

		-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/editionPerformances.xml',
		node_name = 'edition/report',
		node_attr = 'id',
		node_value = 'res_performance' ,
		base = base,
		margin_first_top = 100,
		margin_first_left = 100,
		margin_first_right = 100,
		margin_first_bottom = 100,
		margin_top = 100,
		margin_left = 100, 
		margin_right = 100,
		margin_bottom = 135,
		paper_orientation = params.orientation,
		body = tRanking,
		params = {manche = params.code_manche, nb_inter = params.nb_temps_inter, tInter = tInter, tSecteur = tSecteur, need = params.need, nb_row_ligne = params.nb_row_ligne}
	});

end
