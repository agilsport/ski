asciiCode = {
	NUL = 	0x00;	-- null
	SOH = 	0x01;	-- start of header
	STX	=	0x02;	-- start of text
	ETX	=	0x03;	-- end of text
	EOT	=	0x04;	-- end of transmission
	ENQ	=	0x05;	-- enquiry
	ACK = 	0x06;	-- acknowledge
	BEL = 	0x07;	-- bell
	BS 	= 	0x08;	-- backspace
	HT 	= 	0x09;	-- horizontal tab
	LF	=	0x0A;	-- line feed
	VT	=	0x0B;	-- vertical tab
	FF	=	0x0C;	-- form feed
	CR	=	0x0D;	-- enter / carriage return
	SO	=	0x0E;	-- shift out
	SI	=	0x0F;	-- shift in
	DLE	=	0x10;	-- data link escape
	DC1	=	0x11;	-- device control 1
	DC2	=	0x12;	-- device control 2
	DC3	=	0x13;	-- device control 3
	DC4	=	0x14;	-- device control 4
	NAK	=	0x15;	-- negative acknowledge
	SYN	=	0x16;	-- synchronize
	ETB	=	0x17;	-- end of trans. block
	CAN	=	0x18;	-- cancel
	EM	=	0x19;	-- end of medium
	SUB	=	0x1A;	-- substitute
	ESC	=	0x1B;	-- escape
};

-- chrono
chronoStatus =
{
	OUT		= -900,		-- Out 
	DSQ		= -800,		-- Disqualifié
	DNS		= -600, 	-- Did Not Start
	DNF		= -500, 	-- Did Not Finish
	NQ		= -400, 	-- Not Qualified
	KO		= -1,		-- KO = Non Classés
	ZERO	= 0,		-- ZERO = Non Traité
	OK		= 1			-- OK = Classés
};

-- string 
function string:Split(delimiter)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(self, delimiter, from)
	while delim_from do
		table.insert( result, string.sub(self, from , delim_from-1))
		from = delim_to + 1
		delim_from, delim_to = string.find(self, delimiter, from)
	end
	table.insert( result, string.sub(self, from) )
	return result
end

function string:Trim()
  return (self:gsub("^%s*(.-)%s*$", "%1"))
end

-- adv
adv = {
	-- Message Alert, Warning, Error, Success,  
	Alert = function(txt)
		app.GetAuiMessage():AddLine(txt);
	end,

	Success = function(txt)
		app.GetAuiMessage():AddLineSuccess(txt);
	end,

	Warning = function(txt)
		app.GetAuiMessage():AddLineWarning(txt);
	end,
	
	Error = function(txt)
		app.GetAuiMessage():AddLineError(txt);
	end,
	
	Filter = function(self,  fn)
		assert(type(fn) == 'function');
		
		-- Copy Table vide
		local filterTable = self:Copy(false);
		
		-- Parcours et tri
		for row=0, self:GetNbRows()-1 do
			if fn(self, row, params) then
				filterTable:AddRow();
				filterTable:CopyRow(filterTable:GetNbRows()-1, self, row);
			end
		end	
		return filterTable;
	end,
	
	Evaluate = function(expr)
		local fn, error_msg = load(expr, 'Evaluate', 't');
		if fn == nil then
			return error_msg;
		else
			local ok, rc = pcall(fn);
			if ok then 
				return rc;
			else
				return 'Evaluate Error '..expr;
			end
		end
	end,

	FindIndex = function(self, search)
		if self == nil then return -1 end
		for i=1,#self do
			if search == self[i] then return i end;
		end
		return -1;
	end,
	
	FindVariable = function(self, search, index)
		index = index or 1;
		if index > #search then return nil end
		
		local kSearch = search[index];
		for k,v in pairs(self) do
			if k == kSearch then
				if index == #search then 
					return v;
				elseif type(v) == 'table' then
					return adv.FindVariable(v, search, index+1);
				else
					return nil;
				end
			end
		end
		
		return nil;
	end,
	
	FlagNation = function(nation)
		if nation == nil or nation == '' then nation = 'FRA' end
		if app.FileExists('./logo/'..nation..'.gif') then
			return './logo/'..nation..'.gif';
		else
			return './logo/FIS.gif';
		end
	end,

	LogoMedal = function(medal)
		if medal == nil or medal == '' then medal = 'blank' end
		local logo = './res/esf/vg-'..medal..'.png';
		if app.FileExists(logo) then
			return logo;
		else
			return './res/esf/vg-blank.png';
		end
	end,
	
	CreateDatabase = function(self)
		assert(type(self) == 'table');
		local db = {};
		for k,v in pairs(self) do
			if type(v) == 'userdata' and app.GetNameSpace(v) == 'sqlTable' then
				db[k] = v:Copy();
			end
		end
		return db;
	end,

	DeleteDatabase = function(self)
		assert(type(self) == 'table');
		for __,v in pairs(self) do
			if type(v) == 'userdata' and app.GetNameSpace(v) == 'sqlTable' then
				v:Delete();
			end
		end
	end,
	
	sqlTableToTable = function(tSQL, multipleRows, minRow)
		assert(app.GetNameSpace(tSQL) == 'sqlTable' or app.GetNameSpace(tSQL) == 'sqlTableGC');
		singleRow = singleRow or true;
		minRow = minRow or 0; 
	
		local t = {};
		
		if multipleRows then
			for i=0, tSQL:GetNbRows()-1 do
				local r = {};
				for j=0,tSQL:GetNbColumns()-1 do
					r[tSQL:GetColumnName(j)] = tSQL:GetCell(j, i);
				end
				table.insert(t, r);
			end
			if minRow > tSQL:GetNbRows() then
				for i=tSQL:GetNbRows(), minRow do
					local r = {};
					for j=0,tSQL:GetNbColumns()-1 do
						r[tSQL:GetColumnName(j)] = '';
					end
					table.insert(t, r);
				end
			end
		else
			if tSQL:GetNbRows() > 0 then
				for j=0,tSQL:GetNbColumns()-1 do
					t[tSQL:GetColumnName(j)] = tSQL:GetCell(j, 0);
				end
			else
				for j=0,tSQL:GetNbColumns()-1 do
					t[tSQL:GetColumnName(j)] = tSQL:GetRecord():GetString(j);
				end
			end
		end
		
		return t;
	end,
	
	-- retourne la chaine de caractère formé des bytes de iStart à iEnd
	PacketString = function(packet, iStart, iEnd)
		iStart = iStart or 1;
		iEnd = iEnd or #packet;
		
		if type(packet) ~= 'table' then
			adv.Error("adv.PacketString : packet not table ...");
			return;
		end

		local lg = #packet;
		if iStart < 1 then iStart = 1 end
		if iEnd > lg then iEnd = lg end

		local arrayChar = {};
		local bug = 0;
		for i=iStart,iEnd do
			if packet[i] >= 32 and packet[i] <= 127 then
				table.insert(arrayChar, string.char(packet[i]));
			else
				bug = bug+1;
			end
		end
		
		-- if bug then
			-- adv.DebugPacket(packet,'BUG count='..bug);
		-- end
		
		return table.concat(arrayChar);
	end,

	-- Remplace le caractère chOld par chNew de l'indice iStart à iEnd 
	PacketCharReplace = function(packet, iStart, iEnd, chOld, chNew)
		local lg = #packet;
		if iStart < 1 then iStart = 1 end
		if iEnd > lg then iEnd = lg end
		
		local count = 0;
		for i=iStart,iEnd do
			if packet[i] == string.byte(chOld) then
				packet[i] = string.byte(chNew);
				count = count +1;
			end
		end
		return count;
	end,

	-- Envoi du packet dans la fenêtre d'information
	DebugPacket = function(packet, msg)
		local strPacket = '';
		for i=1,#packet do
			if packet[i] >= 32 then
				strPacket = strPacket..string.char(packet[i]);
			else
				strPacket = strPacket..string.format('[%2d]', packet[i]);
			end
		end
		if msg == nil then
			adv.Alert(strPacket);
		else
			adv.Alert(msg..strPacket);
		end
	end,

	-- Table Bytes to String 
	BytesToString2 = function(bytes, iStart, iEnd)
		iStart = iStart or 1
		iEnd = iEnd or -1
	
		if type(bytes) == "table" then 

			local lg = #bytes;
			if iStart < 1 then iStart = 1 end
			if iEnd <= 0 or iEnd > lg then iEnd = lg end

			local str = '';
			for i=iStart,iEnd do
				if bytes[i] >= 32 and bytes[i] <= 126 then
					str = str..string.char(bytes[i]);
				elseif bytes[i] < 0 then
					str = str..'['..string.format("%#03u", 256+bytes[i])..']';
				else
					str = str..'['..string.format("%#03u", bytes[i])..']';
				end
			end
			return str;
		else
			return '';
		end
	end,
	
	-- Table Bytes to String 
	BytesToString = function(bytes, iStart, iEnd)
		iStart = iStart or 1
		iEnd = iEnd or -1
	
		if type(bytes) == "table" then 

			local lg = #bytes;
			if iStart < 1 then iStart = 1 end
			if iEnd <= 0 or iEnd > lg then iEnd = lg end

			local str = '';
			for i=iStart,iEnd do
				if bytes[i] > 0 then
					str = str..string.char(bytes[i]);
				else
					str = str..string.char(256+bytes[i]);
				end
			end
			return str;
		else
			return '';
		end
	end,
	
	-- Remplace le byte byteOld par byteNew de l'indice iStart à iEnd 
	BytesReplace = function(bytes, byteOld, byteNew, iStart, iEnd)
		iStart = iStart or 1
		iEnd = iEnd or -1

		if type(bytes) == "table" then 
			local lg = #bytes;
			if iStart < 1 then iStart = 1 end
			if iEnd <= 0 or iEnd > lg then iEnd = lg end

			local count = 0;
			for i=iStart,iEnd do
				if bytes[i] == byteOld then
					bytes[i] = byteNew;
					count = count +1;
				end
			end
			return count;
		else
			return 0;
		end
	end,

	-- Transformation String HHMMSS en millisecondes 
	HHMMSS_To_MS = function(strHHMMSS)
		if string.len(strHHMMSS) < 6 then return 0 end
		local h = tonumber(string.sub(strHHMMSS, 1, 2));
		local m = tonumber(string.sub(strHHMMSS, 3, 4));
		local s = tonumber(string.sub(strHHMMSS, 5, 6));
		return h*3600000+m*60000+s*1000;
	end,
	
	-- Transformation String HHMMSS en millisecondes 
	HHMMSSms_To_MS = function(strHHMMSSms)  -- 14h15:20.125
		if string.len(strHHMMSSms) < 12 then return 0 end
		local h = tonumber(string.sub(strHHMMSSms, 1, 2));
		local m = tonumber(string.sub(strHHMMSSms, 4, 5));
		local s = tonumber(string.sub(strHHMMSSms, 7, 8));
		local ms = tonumber(string.sub(strHHMMSSms, 10));
		return h*3600000+m*60000+s*1000+ms;
	end,
	
	CmpNodeName = function(node1, node2)
		if node1 == nil or node2 == nil then return false end

		while node1 ~= nil and node2 ~= nil do
			if node1:GetName() ~= node2:GetName() then return false end
			node1 = node1:GetParent();
			node2 = node2:GetParent();
		end
		
		if node1 == nil and node2 == nil then
			return true;
		else
			return false;
		end
	end
	
}	
