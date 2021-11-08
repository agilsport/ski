-- Interface C++ - LUA

-- MessageBox Style
msgBoxStyle = {
	YES					= 0x00000002,
	OK					= 0x00000004,
	NO					= 0x00000008,
	CANCEL				= 0x00000010,
	APPLY				= 0x00000020,
	CLOSE				= 0x00000040,
	YES_NO				= 0x0000000a,

	OK_DEFAULT			= 0x00000000,
	YES_DEFAULT			= 0x00000000,
	NO_DEFAULT			= 0x00000080,  -- only valid with YES_NO 
	CANCEL_DEFAULT		= 0x80000000,  -- only valid with CANCEL 

	ICON_WARNING		= 0x00000100,
	ICON_ERROR			= 0x00000200,
	ICON_QUESTION		= 0x00000400,
	ICON_INFORMATION	= 0x00000800
};

-- Windows Style 
wndStyle = {
	NONE				= 0x00000000,
	
	FRAME_SHAPED		= 0x00000010,
 	RESIZE_BORDER		= 0x00000040,
	MAXIMIZE_BOX		= 0x00000200,
	MINIMIZE_BOX		= 0x00000400,
	SYSTEM_MENU			= 0x00000800,
	CLOSE_BOX			= 0x00001000,
	STAY_ON_TOP			= 0x00008000,

	WANTS_CHARS			= 0x00040000,
	TAB_TRAVERSAL		= 0x00080000,
	
	TRANSPARENT_WINDOW	= 0x00100000,

	BORDER_NONE			= 0x00200000,
	CLIP_CHILDREN		= 0x00400000,
	
	CAPTION				= 0x20000000,
	HSCROLL				= 0x40000000,
	CAPTION				= 0x20000000,
	
	-- CheckBox
	CHK_2STATE			= 0x4000,
	CHK_3STATE			= 0x1000,

	-- RadioButton
	RB_GROUP			= 0x0004,
	RB_SINGLE			= 0x0008,

	-- ToolBar
	TB_FLAT				= 0x0020,
	TB_HORIZONTAL 		= 0x0004,
	TB_VERTICAL			= 0x0008,
	TB_TEXT				= 0x0100,

	-- PropertyGrid
	PG_BOLD_MODIFIED			= 0x00000040,
	PG_SPLITTER_AUTO_CENTER		= 0x00000080,
	PG_TOOLTIPS					= 0x00000100,
	PG_TOOLBAR					= 0x00001000,
	PG_DESCRIPTION				= 0x00002000,

	-- Combobox
	CB_SIMPLE					= 0x0004,
	CB_SORT           			= 0x0008,
	CB_READONLY       			= 0x0010,
	CB_DROPDOWN       			= 0x0020,

	-- TextCtrl
	TE_READONLY       			= 0x0010,
	TE_MULTILINE				= 0x0020,
	TE_PROCESS_TAB				= 0x0040,
	TE_RICH						= 0x0080,
	TE_PROCESS_ENTER			= 0x0400,
	TE_PASSWORD					= 0x0800,
	
	TE_LEFT						= 0x0000,
	TE_CENTER					= 0x0100,
	TE_RIGHT					= 0x0200,

	-- Align
	ALIGN_LEFT					= 0x0000,
	ALIGN_RIGHT					= 0x0200,
	ALIGN_TOP					= 0x0000,
	ALIGN_BOTTOM				= 0x0400,
	ALIGN_CENTER_HORIZONTAL 	= 0x0100,
	ALIGN_CENTER_VERTICAL		= 0x0800,
	ALIGN_CENTER				= 0x0900
};

wndStyle.DEFAULT_FRAME = 
	wndStyle.SYSTEM_MENU+
	wndStyle.RESIZE_BORDER+
	wndStyle.MAXIMIZE_BOX+
	wndStyle.MINIMIZE_BOX+
	wndStyle.CLOSE_BOX+
	wndStyle.CAPTION+
	wndStyle.CLIP_CHILDREN;
	
wndStyle.DEFAULT_DIALOG = 
	wndStyle.SYSTEM_MENU+
	wndStyle.CAPTION+
	wndStyle.RESIZE_BORDER;
	
wndStyle.DEFAULT_PANEL = wndStyle.TAB_TRAVERSAL;
	
wndStyle.DEFAULT_TOOLBAR = 
	wndStyle.TB_FLAT+
	wndStyle.TB_HORIZONTAL;

fontStyle = {
    NORMAL		= 	90,
	ITALIC		=	93,
	SLANT		=	94
};

fontWeight = {
    NORMAL		= 	90,
	LIGHT		=	91,
	BOLD		=	92
};

-- KeyBoard Values
keyCode = {
	NONE    =    0,

    CONTROL_A 	= 1,
    CONTROL_B 	= 2,
    CONTROL_C 	= 3,
    CONTROL_D 	= 4,
    CONTROL_E 	= 5,
    CONTROL_F 	= 6,
    CONTROL_G 	= 7,
    CONTROL_H 	= 8,
    CONTROL_I 	= 9,
    CONTROL_J 	= 10,
    CONTROL_K 	= 11,
    CONTROL_L	= 12,
    CONTROL_M 	= 13,
    CONTROL_N 	= 14,
    CONTROL_O 	= 15,
    CONTROL_P 	= 16,
    CONTROL_Q 	= 17,
    CONTROL_R 	= 18,
    CONTROL_S 	= 19,
    CONTROL_T 	= 20,
    CONTROL_U 	= 21,
    CONTROL_V 	= 22,
    CONTROL_W 	= 23,
    CONTROL_X 	= 24,
    CONTROL_Y 	= 25,
    CONTROL_Z 	= 26,

    BACK    	= 8, 	-- backspace
    TAB     	= 9,
    RETURN  	= 13,
    ESCAPE  	= 27,

    -- values from 33 to 126 are reserved for the standard ASCII characters 
    SPACE   	= 32,
    DELETE  	= 127,

	START   	= 300,
	LBUTTON		= 301,
	RBUTTON		= 302,
	CANCEL		= 303,
	MBUTTON		= 304,
	CLEAR		= 305,
	SHIFT		= 306,
	ALT			= 307,
	CONTROL		= 308,
	MENU		= 309,
	PAUSE		= 310,
	CAPITAL		= 311,
	END			= 312,
	HOME		= 313,
	LEFT		= 314,
	UP			= 315,
	RIGHT		= 316,
	DOWN		= 317,
	SELECT		= 318,
	PRINT		= 319,
	EXECUTE		= 320,
	SNAPSHOT	= 321,
	INSERT		= 322,
	HELP		= 323,
	NUMPAD0		= 324,
	NUMPAD1		= 325,
	NUMPAD2		= 326,
	NUMPAD3		= 327,
	NUMPAD4		= 328,
	NUMPAD5		= 329,
	NUMPAD6		= 330,
	NUMPAD7		= 331,
	NUMPAD8		= 332,
	NUMPAD9		= 333,
	MULTIPLY	= 334,
	ADD			= 335,
	SEPARATOR	= 336,
	SUBTRACT	= 337,
	DECIMAL		= 338,
	DIVIDE		= 339,
	
	F1			= 340,
	F2			= 341,
	F3			= 342,
	F4			= 343,
	F5			= 344,
	F6			= 345,
	F7			= 346,
	F8			= 347,
	F9			= 348,
	F10			= 349,
	F11			= 350,
	F12			= 351,
	F13			= 352,
	F14			= 353,
	F15			= 354,
	F16			= 355,
	F17			= 356,
	F18			= 357,
	F19			= 358,
	F20			= 359,
	F21			= 360,
	F22			= 361,
	F23			= 362,
	F24			= 363,
	NUMLOCK		= 364,
	SCROLL		= 365,
	PAGEUP		= 366,
	PAGEDOWN	= 367,
	
	NUMPAD_SPACE	= 368,
	NUMPAD_TAB		= 369,
	NUMPAD_ENTER	= 370,
	NUMPAD_F1		= 371,
	NUMPAD_F2		= 372,
	NUMPAD_F3		= 373,
	NUMPAD_F4		= 374,
	NUMPAD_HOME		= 375,
	NUMPAD_LEFT		= 376,
	NUMPAD_UP		= 377,
	NUMPAD_RIGHT	= 378,
	NUMPAD_DOWN		= 379,
	NUMPAD_PAGEUP	= 380,
	NUMPAD_PAGEDOWN	= 381,
	NUMPAD_END		= 382,
	NUMPAD_BEGIN	= 383,
	NUMPAD_INSERT	= 384,
	NUMPAD_DELETE	= 385,
	NUMPAD_EQUAL	= 386,
	NUMPAD_MULTIPLY	= 387,
	NUMPAD_ADD		= 388,
	NUMPAD_SEPARATOR= 389,
	NUMPAD_SUBTRACT	= 390,
	NUMPAD_DECIMAL	= 391,
	NUMPAD_DIVIDE	= 392
};

-- fileDialogStyle
fileDialogStyle =
{
	OPEN	 			=	0x0001,
	SAVE 				=	0x0002,
	OVERWRITE_PROMPT	=	0x0004,
    FD_NO_FOLLOW		=	0x0008,
    FD_FILE_MUST_EXIST	=	0x0010,
    FD_CHANGE_DIR		=	0x0080,
	FD_PREVIEW			=	0x0100,
	FD_MULTIPLE			=	0x0200
};

pgStyle =
{
	AUTO_SORT				= 0x00000010,
	HIDE_CATEGORIES			= 0x00000020,
	ALPHABETIC_MODE			= 0x00000030,
	BOLD_MODIFIED			= 0x00000040,
	SPLITTER_AUTO_CENTER	= 0x00000080,
	TOOLTIPS				= 0x00000100,
	HIDE_MARGIN				= 0x00000200,
	STATIC_SPLITTER			= 0x00000400,
	STATIC_LAYOUT			= 0x00000600,
	LIMITED_EDITING			= 0x00000800,
	TOOLBAR					= 0x00001000,
	DESCRIPTION				= 0x00002000,
	NO_INTERNAL_BORDER		= 0x00004000
};

gridSelectionModes =
{
	CELLS			= 0,
	ROWS			= 1,
	COLUMNS			= 2,
	ROWS_OR_COLUMNS	= 3
};

-- Windows Style 
auiToolBarStyle = {
	TEXT				= 1,
	NO_TOOLTIPS			= 1 << 1,
	NO_AUTORESIZE		= 1 << 2,
	GRIPPER				= 1 << 3,
	OVERFLOW			= 1 << 4,
	VERTICAL			= 1 << 5,
	HORZ_LAYOUT			= 1 << 6,
	HORIZONTAL			= 1 << 7,
	PLAIN_BACKGROUND	= 1 << 8,
};
auiToolBarStyle.HORZ_TEXT = auiToolBarStyle.HORZ_LAYOUT+auiToolBarStyle.TEXT;

-- Frame Report Style
styleFrameReport = {
	NONE					= 0x00,
	RULER_HORIZONTAL		= 0x01,
	RULER_VERTICAL			= 0x02,
	GRID_HORIZONTAL			= 0x04,
	GRID_VERTICAL			= 0x08,
	STATUSBAR				= 0x10,
	TOOLBAR_NAVIGATION		= 0x20,
	TOOLBAR_ADMIN			= 0x40,
	ALL						= 0xff
}
styleFrameReport.DEFAULT = styleFrameReport.RULER_HORIZONTAL + styleFrameReport.RULER_VERTICAL + styleFrameReport.STATUSBAR + styleFrameReport.TOOLBAR_NAVIGATION;

editorMode = {
	READONLY			= 0,
	EDITION				= 1,
	INPUT				= 2,
	TEMPLATE			= 3,
	LAYER				= 4
};

-- Obsolète : graphicsMode
editorGraphicsMode = {
	STD						= 0x00,
	DOUBLE_BUFFERING		= 0x01,
	INCRUSTATION			= 0x02,
	REGION					= 0x04,
};

-- Object Type
objType = {
	NONE			= 0,
	TEXT 			= 100,
	IMAGE 			= 101,
	AREA			= 102,
	WINDOW			= 103,
	TABLE			= 104,
	TEMPLATE		= 105
};

-- Object Style
objStyle = {
	NONE			= 0,
	VISIBLE 		= 0x01,
	CLICKABLE		= 0x02,
	EDITABLE		= 0x04,
	PRINTABLE		= 0x08,
	DOCKABLE		= 0x10
};

-- Object BackGround Mode
objBackGroundMode = {
	TRANSPARENT				= 84, -- 'T',
	SOLID					= 83, -- 'S',
	SOLID_TEXT				= 115, -- 's',
	GRADIENT_LINE_HORZ		= 72, -- 'H',
	GRADIENT_LINE_VERT		= 86, -- 'V',
	GRADIENT_LINE			= 76, -- 'L',
	GRADIENT_ELLIPSE		= 69, -- 'E'
};

-- Object Image Ajustement
objImageAdjust = {
	NONE					=	0x00,
	WIDTH					=	0x01,
	HEIGHT					=	0x02,
	BEST					=	0x03,
	SCALE					=	0x04
};

-- Object Text Ajustement
objTextAdjust = {
	NONE			=	0x00,
	WIDTH			=	0x01,
	HEIGHT			=	0x02,
	ELLIPSIZE		=	0x04,
	
	BOTH			=	0x03,
	MAX				=	0x07
};

-- Object Border Frame
objBorderFrame = {
	NONE					=	0x00,
	LEFT					=	0x01,
	RIGHT					=	0x02,
	TOP						=	0x04,
	BOTTOM					=	0x08,
	ALL						=	0xff
};

-- Object Border Style
objBorderStyle = {
    SOLID 		= 100,
    DOT 		= 101,
	LONG_DASH	= 102,
	SHORT_DASH	= 103,
	DOT_DASH	= 104
};

-- Object Align
objAlign = {
	NONE						=	0x0000,
	CENTER_HORIZONTAL			=	0x0100,
	LEFT						=	0x0000,
 	TOP							=	0x0000,
 	RIGHT						=	0x0200,
 	BOTTOM						=	0x0400,
	CENTER_VERTICAL				=	0x0800,
	CENTER						=	0x0900
};

-- Object Unit
objUnit = {
	NONE 	= 0,
	PIXEL 	= 1,
	U10MM	= 2
};

-- Object Size
objSize = {};

objSize.New = function()
	local self = {};

	self.Proportion = function(value)
		self.proportion = value;
		return self;
	end

	self.Constant = function(value)
		self.constant = value;
		return self;
	end
	
	return self;
end

-- Object Flags 
objFlags = {};
objFlags.New = function()
	local self = {};

	-- Text
	self.Text = function(text, color)
		self.text = text;
		self.type = objType.TEXT;
		if color ~= nil then
			self.text_color = color;
		end
		return self;
	end
	
	self.TextString = function(text)
		self.text = text;
		return self;
	end

	self.TextColor = function(color)
		self.text_color = color;
		return self;
	end

	-- Image
	self.Image = function(imageName, imageType, imageAdjust)
		self.text = imageName;
		self.type = objType.IMAGE;

		if imageType ~= nil then
			self.image_type = imageType;
		end
		if imageAdjust ~= nil then
			self.image_adjust = imageAdjust;
		end
		return self;
	end

	self.ImageType = function(imageType)
		self.image_type = imageType;
		return self;
	end

	self.ImageAdjust = function(imageAdjust)
		self.image_adjust = imageAdjust;
		return self;
	end
	
	-- Table
	self.Table = function()
		self.type = objType.TABLE;
		return self;
	end
	
	-- Type
	self.Type = function(value)
		self.type = value;
		return self;
	end
	
	-- Area
	self.Area = function()
		self.type = objType.AREA;
		return self;
	end
	
	-- Window
	self.Window = function()
		self.type = objType.WINDOW;
		return self;
	end
	
	-- Margin
	self.Margin = function(left, right, top, bottom)
		self.margin_left = left;
		self.margin_right = right;
		self.margin_top = top;
		self.margin_bottom = bottom;
		return self;
	end

	self.MarginLeft = function(margin)
		self.margin_left = margin;
		return self;
	end

	self.MarginRight = function(margin)
		self.margin_right = margin;
		return self;
	end
	
	self.MarginTop = function(margin)
		self.margin_top = margin;
		return self;
	end
	
	self.MarginBottom = function(margin)
		self.margin_bottom = margin;
		return self;
	end

	-- Spacing
	self.Spacing = function(left, right, top, bottom)
		self.spacing_left = left;
		self.spacing_right = right or left;
		self.spacing_top = top or left;
		self.spacing_bottom = bottom or left;
		return self;
	end

	self.SpacingLeft = function(spacing)
		self.spacing_left = spacing;
		return self;
	end

	self.SpacingRight = function(spacing)
		self.spacing_right = spacing;
		return self;
	end
	
	self.SpacingTop = function(spacing)
		self.spacing_top = spacing;
		return self;
	end
	
	self.SpacingBottom = function(spacing)
		self.spacing_bottom = spacing;
		return self;
	end
	
	-- Alignment
	self.Align = function(alignHorz, alignVert)
		self.align_horz = alignHorz;
		self.align_vert = alignVert;
		return self;
	end
	
	self.AlignHorz = function(align)
		self.align_horz = align;
		return self;
	end

	self.AlignVert = function(align)
		self.align_vert = align;
		return self;
	end
	
	-- Border
	self.Border = function(border)
		self.border = border;
		return self;
	end
	
	-- Font
	self.Font = function(name, size)
		self.font_name = name;
		if size ~= nil then
			self.font_size = size;
		end
		return self;
	end
	
	self.FontName = function(name)
		self.font_name = name;
		return self;
	end

	self.FontSize = function(size)
		self.font_size = size;
		return self;
	end

	self.FontWeight = function(weight)
		self.font_weight = weight;
		return self;
	end
	
	self.FontStyle = function(style)
		self.font_style = style;
		return self;
	end
	
	self.FontUnderlined = function(underlined)
		self.font_underlined = underlined;
		return self;
	end

	self.FontOrientation = function(orientation)
		self.font_orientation = orientation;
		return self;
	end

	self.FontAdjust = function(adjust)
		self.font_adjust = adjust;
		return self;
	end

	self.BackgroundColor = function(color1, color2)
		if color2 == nil then
			self.background_color = color1;
		else
			self.background_color_start = color1;
			self.background_color_end = color2;
		end
		return self;
	end

	self.BackgroundMode = function(mode)
		self.background_mode = mode;
		return self;
	end
	
	self.BackgroundColorStart = function(color)
		self.background_color_start = color;
		return self;
	end

	self.BackgroundColorEnd = function(color)
		self.background_color_end = color;
		return self;
	end

	self.TransparentColor = function(color)
		self.transparent_color = color;
		return self;
	end

	self.PenSize = function(size)
		self.pen_size = size;
		return self;
	end

	self.PenStyle = function(style)
		self.pen_style = style;
		return self;
	end

	self.PenColor = function(color)
		self.pen_color = color;
		return self;
	end

	self.Pen = function(size, style, color)
		self.pen_size = size;
		if style ~= nil then
			self.pen_style = style;
		end	
		if color ~= nil then
			self.pen_color = color;
		end	
		return self;
	end
	
	self.Hatch = function(style, color)
		self.hatch_style = style;
		if color ~= nil then
			self.hatch_color = color;
		end	
		return self;
	end

	self.HatchStyle = function(style)
		self.hatch_style = style;
		return self;
	end

	self.HatchColor = function(color)
		self.hatch_color = color;
		return self;
	end

	self.Width = function(width)
		self.width = width;
		return self;
	end

	self.Height = function(height)
		self.height = height;
		return self;
	end

	self.X = function(x)
		self.x = x;
		return self;
	end

	self.Y = function(y)
		self.y = y;
		return self;
	end
	
	self.Style = function(style)
		self.style = style;
		return self;
	end
	
	self.Node = function(node)
		self.node = node;
		return self;
	end
		
	self.ParentId = function(parentID)
		self.parent_id = parentID;
		return self;
	end

	return self;
end

-- Predefined Colors
color.BLACK = color.Create(0, 0, 0);
color.DKGRAY = color.Create(128, 128, 128);
color.GRAY = color.Create(192, 192, 192);
color.LTGRAY = color.Create(230, 230, 230);
color.WHITE = color.Create(255, 255, 255);

color.DKRED = color.Create(128, 0, 0);
color.RED = color.Create(192, 0, 0);
color.LTRED = color.Create(255, 0, 0);

color.DKORANGE = color.Create(255,  64, 0);
color.ORANGE = color.Create(255, 128, 0);
color.LTORANGE = color.Create(255, 192, 0);

color.DKYELLOW = color.Create(224, 224, 0);
color.YELLOW = color.Create(242, 242, 0);
color.LTYELLOW = color.Create(255, 255, 0);

color.DKGREEN = color.Create(0, 128, 0);
color.GREEN = color.Create(0, 192, 0);
color.LTGREEN = color.Create(0, 255, 0);
color.HIGREEN = color.Create(0, 255, 128);
color.BLUEGREEN = color.Create(0, 128, 128);

color.OLIVE = color.Create(128, 128, 0);
color.BROWN = color.Create(128,  80, 0);
color.PINK = color.Create(255, 0, 128);

color.DKBLUE = color.Create(0, 0, 128);
color.BLUE = color.Create(0, 0, 255);
color.LTBLUE = color.Create(0, 128, 255);
color.LTLTBLUE = color.Create(0, 160, 255);
color.HIBLUE = color.Create(0, 192, 255);
color.CYAN = color.Create(0, 255, 255);

color.DKPURPLE = color.Create(128, 0, 128);
color.PURPLE = color.Create(192, 0, 192);
color.MAGENTA = color.Create(255, 0, 255);

-- Color
wnd.RGB = function(r,g,b) 
	return r+g*0x100+b*0x10000 
end

wndColor = {
	BLACK = wnd.RGB(0, 0, 0),
	DKGRAY = wnd.RGB(128, 128, 128),
	GRAY = wnd.RGB(192, 192, 192),
	LTGRAY = wnd.RGB(230, 230, 230),
	WHITE = wnd.RGB(255, 255, 255),

	DKRED = wnd.RGB(128, 0, 0),
	RED = wnd.RGB(192, 0, 0),
	LTRED = wnd.RGB(255, 0, 0),

	DKORANGE = wnd.RGB(255,  64, 0),
	ORANGE = wnd.RGB(255, 128, 0),
	LTORANGE = wnd.RGB(255, 192, 0),

	DKYELLOW = wnd.RGB(224, 224, 0),
	YELLOW = wnd.RGB(242, 242, 0),
	LTYELLOW = wnd.RGB(255, 255, 0),

	DKGREEN = wnd.RGB(0, 128, 0),
	GREEN = wnd.RGB(0, 192, 0),
	LTGREEN = wnd.RGB(0, 255, 0),
	HIGREEN = wnd.RGB(0, 255, 128),
	BLUEGREEN = wnd.RGB(0, 128, 128),
	
	OLIVE = wnd.RGB(128, 128, 0),
	BROWN = wnd.RGB(128,  80, 0),

	DKBLUE = wnd.RGB(0, 0, 128),
	BLUE = wnd.RGB(0, 0, 255),
	LTBLUE = wnd.RGB(0, 128, 255),
	LTLTBLUE = wnd.RGB(0, 160, 255),
	HIBLUE = wnd.RGB(0, 192, 255),
	CYAN = wnd.RGB(0, 255, 255),

	DKPURPLE = wnd.RGB(128, 0, 128),
	PURPLE = wnd.RGB(192, 0, 192),
	MAGENTA = wnd.RGB(255, 0, 255),
};

-- Direction
wndDirection  = { 
	HORIZONTAL 		=	0x0004, 
	VERTICAL		= 	0x0008, 
	LEFT 			=	0x0010,
	RIGHT 			=	0x0020,
	TOP				=	0x0040,
	BOTTOM			=	0x0080
};
wndDirection.ALL = wndDirection.TOP+wndDirection.BOTTOM+wndDirection.RIGHT+wndDirection.LEFT;

-- itemKind
itemKind = {
	SEPARATOR = -1,
	NORMAL = 0,
	CHECK = 1,
	RADIO = 2,
	DROPDOWN = 3,
	MAX = 4
};

-- gridRowLabel
gridRowLabel = 
{
	STD 		= 1,
	STATE		= 2,
	SELECT		= 3,
	CHECK		= 4,
	OWNERDRAW	= 5
};

-- XML Node Type
xmlNodeType = 
{
	ELEMENT_NODE 		= 1, 
	ATTRIBUTE_NODE		= 2, 
	TEXT_NODE			= 3, 
	CDATA_SECTION_NODE	= 4, 
	ENTITY_REF_NODE		= 5, 
	ENTITY_NODE			= 6, 
	PI_NODE 			= 7, 
	COMMENT_NODE 		= 8, 
	DOCUMENT_NODE 		= 9, 
	DOCUMENT_TYPE_NODE	= 10, 
	DOCUMENT_FRAG_NODE	= 11, 
	NOTATION_NODE 		= 12, 
	HTML_DOCUMENT_NODE	= 13 
};

-- SQL 
sqlType = 
{
	NONE 			= 0,

	CHAR	 		= 1,
	VARCHAR 		= 2,
	TEXT			= 3,
	
	SHORT			= 4,
	LONG			= 5,
	DOUBLE			= 6,
	CHRONO			= 7,
	RANKING			= 8,
	
	DATE			= 9,
	SMALLDATETIME	= 10,
	DATETIME		= 11,
	PERIOD			= 12,

	ANY				= 13,
	OBJECT			= 14,

	BLOB			= 15,
	USERDATA		= 16
};

sqlStyle =
{
	NONE 				=	0x0000,
	VISIBLE 			=	0x0001,		-- Flag Champ Visible 
	AUTOINCREMENT 		=	0x0002,		-- Flag Champ Autoincrement
	CURRENT_TIMESTAMP 	=	0x0004,		-- Flag Champ Current Timestamp
	CURRENT_DATE 		=	0x0008,		-- Flag Champ Current Date
	PRIMARY 			=	0x0010,		-- Flag Champ constitue la cle primaire
	FOREIGN 			=	0x0020,		-- Flag Champ constitue une cle secondaire 
	NULL 				= 	0x0040,		-- Flag Champ accepte les champs null
	READONLY 			=	0x0080,		-- Flag Champ Lecture Seule 
	CHECK 				= 	0x0100,		-- Flag Champ check 	
	FIXED 				=	0x0200		-- Flag Champ Fixe (advGRID_CONTEXT_MENU_ARRANGE_COLUMNS)
}

idButton = {
	OK 		= 5100,
	CANCEL	= 5101
}

socketFlags =
{
	NONE           = 0x0000,
	NOWAIT_READ    = 0x0001,
	NOWAIT_WRITE   = 0x0002,
	WAITALL_READ   = 0x0004,
	WAITALL_WRITE  = 0x0008,
	BLOCK          = 0x0010,
	REUSEADDR      = 0x0020,
	BROADCAST      = 0x0040,
	NOBIND         = 0x0080
}
socketFlags.NOWAIT = socketFlags.NOWAIT_READ + socketFlags.NOWAIT_WRITE;
socketFlags.WAITALL = socketFlags.WAITALL_READ + socketFlags.WAITALL_WRITE;

socketNotify = 
{
    INPUT		= 0,
	OUTPUT		= 1,
    CONNECTION	= 2,
	LOST		= 3
}

socketEventFlags =
{
	INPUT = 1 << socketNotify.INPUT,
	OUTPUT = 1 << socketNotify.OUTPUT,
	CONNECTION = 1 << socketNotify.CONNECTION,
	LOST = 1 << socketNotify.LOST
}

serialNotify = 
{
	RXCHAR			= 0,
	CONNECTION		= 1,
	LOST			= 2
}
