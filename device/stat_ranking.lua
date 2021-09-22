-- Stat Ranking
dofile('./interface/include.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 2.1, 
		name = 'Stat. Classement', 
		class = 'tools' 
	};
end	

-- Ouverture de device : initialisation
function device.OnInit(params, node)

	local rc, data = app.SendNotify('<stat_ranking_load>');
	if rc and data then
		-- Creation Panel
		panel = wndPanel.New({
				parent = app.GetAuiFrame(),
				style = wndStyle.DEFAULT_PANEL, 
			},
			{ 
				file = './device/stat_ranking.xml', 
				node = 'root/panel', 
				name = 'dashboard'
			}
		);
		
		-- Initialisation 
		panel:GetWindowName('total'):SetValue(data.total);
		panel:GetWindowName('ok'):SetValue(data.ok);
		panel:GetWindowName('dns'):SetValue(data.dns);
		panel:GetWindowName('dnf'):SetValue(data.dnf);
		panel:GetWindowName('dsq'):SetValue(data.dsq);
		panel:GetWindowName('ko'):SetValue(data.ko);
		
		-- Affichage ...
		panel:Show(true);
		
		local mgr = app.GetAuiManager();
		mgr:AddPane(panel:GetWndContainer(), {
			icon = './res/32x32_chrono.png',
			caption = "Stat. Coureur",
			caption_visible = true,
			close_button = false,
			pin_button = true,
			show = true,

			float = true, 
			floating_position = {725, 25},
			floating_size = {250, 80},
			dockable = false
			
		});
		mgr:Update();
		
		app.BindNotify("<stat_ranking>", OnNotifyStatRanking);
	end
end

function OnNotifyStatRanking(key, params)
	if panel ~= nil then
		panel:GetWindowName('total'):SetValue(params.total);
		panel:GetWindowName('ok'):SetValue(params.ok);
		panel:GetWindowName('dns'):SetValue(params.dns);
		panel:GetWindowName('dnf'):SetValue(params.dnf);
		panel:GetWindowName('dsq'):SetValue(params.dsq);
		panel:GetWindowName('ko'):SetValue(params.ko);
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
