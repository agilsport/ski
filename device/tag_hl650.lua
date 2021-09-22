-- TAG HL-650
dofile('./interface/include.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 1.1, 
		code = 'tag_hl650', 
		name = 'TAG Heuer HL-650', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '9600' } } 
	};
end	

-- Ouverture
function device.OnInit(params, node)
	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	dllChrono = app.LoadDllChrono('taghl650.dll');
end

-- Fermeture
function device.OnClose()
	if dllChrono ~= nil then
		app.UnloadDllChrono(dllChrono);
	end
	
	-- Appel OnClose Metatable
	mt_device.OnClose();
end

-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	if cb ~= nil and dllChrono ~= nil then
		local txt = cb:ReadString();
		app.ReadBufferDllChrono(dllChrono, txt);
		app.GetAuiMessage():AddLine(txt);
	end
end

function SendData(data)
	if mt_device.obj ~= nil and data ~= nil then
		mt_device.obj:WriteString(data);
	end
end

