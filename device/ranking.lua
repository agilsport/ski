dofile('./interface/uty.lua');
dofile('./interface/interface.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 1.1, code = 'ranking', name = 'Fenêtre de Classement', class = 'display', interface = {} };
end	

-- Ouverture
function device.OnInit(params)

-- local filter = "return (Categ == 'U12')";

	local caption = "Classement";
	if params.caption ~= nil then
		caption = params.caption;
	end

	local panel = wnd.CreatePanelRanking(wndFlags.New().Label(caption).Key('display_ranking'), params.filter, params.order);
	
	frame = wnd.CreateFramePanel(wndFlags.New()
		.Size(800,600)
		.Icon("./res/32x32_chrono_v5.png")
		.Style(wndStyle.DEFAULT_FRAME-wndStyle.STAY_ON_TOP)
		.Label(caption)
	, panel);
end

-- Fermeture
function device.OnClose()
	if frame ~= nil then
		frame:Delete();
	end
end

