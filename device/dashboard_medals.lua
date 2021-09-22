-- Tableau des Médailles
dofile('./interface/include.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 2.2, name = 'Médailles', class = 'tools' };
end	

-- Ouverture de device : initialisation
function device.OnInit(params, node)

	local rc, dataMedals = app.SendNotify('<medals_load>');
	local rc, dataForerunner = app.SendNotify('<forerunner_load>');
		
	if dataMedals and dataForerunner then
		-- Creation Panel
		panel = wndPanel.New({
				parent = app.GetAuiFrame(),
				style = wndStyle.DEFAULT_PANEL, 
			},
			{ 
				file = './device/dashboard_medals.xml', 
				node = 'root/panel', 
				name = 'dashboard'
			}
		);
		
		-- Initialisation 
		local tForerunner = dataForerunner.forerunner;
		if tForerunner:GetNbRows() > 0 then
			panel:GetWindowName('ouvreur_identite'):SetValue(tForerunner:GetCell('Nom',0)..' '..tForerunner:GetCell('Prenom',0));
			panel:GetWindowName('ouvreur_handicap'):SetValue(tForerunner:GetCell('Handicap',0));
			panel:GetWindowName('ouvreur_tps'):SetValue(tForerunner:GetCell('Tps',0));
			panel:GetWindowName('ouvreur_base'):SetValue(tForerunner:GetCell('Base',0));
		end
		
		grid = panel:GetWindowName('grid');
		grid:Set({
			table_base = dataMedals.medals,
			selection_mode = gridSelectionModes.CELLS,
			sortable = false,
			enable_editing = false,
		});
		
		-- Prise des Messages 
		grid:Bind(eventType.SIZE, OnGridSize);
		grid:Bind(eventType.GRID_CELL_CONTEXT, OnCellContext);

		-- Affichage ...
		panel:Show(true);
		
		local mgr = app.GetAuiManager();
		mgr:AddPane(panel:GetWndContainer(), {
			icon = './res/32x32_esf.png',
			caption = "Ouvreur et Médailles",
			caption_visible = true,
			close_button = false,
			pin_button = true,
			show = true,

			float = true, 
			floating_position = {600, 120},
			floating_size = {480, 120},
			dockable = false
			
		});
		mgr:Update();
		
		app.BindNotify("<forerunner_best_base_time>", OnNotifyForerunnerBestBaseTime);
	end
end

function OnGridSize(evt)

--	grid:Freeze();

	local rect = grid:GetRect();
	local nbRows = grid:GetNumberRows();
	local nbColumns = grid:GetNumberCols();
	
	local w = math.floor(rect.width/nbColumns);
	local h = math.floor(rect.height/(nbRows+1));

	if w > 0 then
		for j=1, nbColumns-1 do
			grid:SetColSize(j, w);
		end
		grid:SetColSize(0, rect.width-w*(nbColumns-1));
	end

	if h > 0 then
		for i=0, nbRows-1 do
			grid:SetRowSize(i, h);
		end
		grid:SetColLabelSize(rect.height-h*nbRows);
	end
		
--	grid:Thaw();
end

function OnCellContext(evt)
	local row = evt:GetRow();
	local col = evt:GetCol();

	local options = { align_horz = wndStyle.ALIGN_CENTER_HORIZONTAL };

	if col == 0 then
		options.bk_color_start = color.WHITE;
		options.bk_color_end = color.LTGRAY;
	else
		local fnt = evt:GetCellContext({'font'});
		fnt:SetWeight(fontWeight.BOLD);
		options.font = fnt;
	end
	evt:SetCellContext(options);
end

function OnNotifyForerunnerBestBaseTime(key, params)
	local rc, dataMedals = app.SendNotify('<medals_load>');
	local rc, dataForerunner = app.SendNotify('<forerunner_load>');
		
	if dataMedals and dataForerunner then
		local tForerunner = dataForerunner.forerunner;
		panel:GetWindowName('ouvreur_identite'):SetValue(tForerunner:GetCell('Nom',0)..' '..tForerunner:GetCell('Prenom',0));
		panel:GetWindowName('ouvreur_handicap'):SetValue(tForerunner:GetCell('Handicap',0));
		panel:GetWindowName('ouvreur_tps'):SetValue(tForerunner:GetCell('Tps',0));
		panel:GetWindowName('ouvreur_base'):SetValue(tForerunner:GetCell('Base',0));
	
		grid:SetTable(dataMedals.medals);
		grid:SynchronizeRows();
		
		panel:Refresh();
	end

end

-- Fermeture
function device.OnClose()
	if panel ~= nil then
		panel:DeleteDoc();
		
		local mgr = app.GetAuiManager();
		mgr:DeletePane(panel.container);
	end
end
