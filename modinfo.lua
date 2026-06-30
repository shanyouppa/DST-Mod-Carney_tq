local Ch = locale == "zh" or locale == "zhr"

name =
Ch and
[[ 卡尼猫(改)_tq]] or
[[ Carney_tq]]

author = "我赚够三千万就收手_tq"
version = "1.3.51"
forumthread = ""
api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = true

description =
Ch and
"V"..version.."\n"..[[
旅行中的卡尼猫
吃鱼类和打怪升级
可以制作方便实用的帽子、短剑和背包等道具
可以发现天使水晶、幸运鱼
]] or
"V"..version.."\n"..[[
Carney is on her trip
eating fish and killing monsters make her upgrade
can craft useful hat,dagger and backpack
can discover angelcrystal and luckyfish
]]

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {
	"character",
    "卡尼猫",
    "carney",
}

--[[local alpha = 
{
    {description = "B", key = 98},
    {description = "C", key = 99},
    {description = "G", key = 103},
    {description = "J", key = 106},
    {description = "R", key = 114},
    {description = "T", key = 116},
    {description = "V", key = 118},
    {description = "X", key = 120},
    {description = "Z", key = 122},
    {description = "LAlt", key = 308},
    {description = "LCtrl", key = 306},
    {description = "LShift", key = 304},
    {description = "Space", key = 32},
}]]

local keys = 
{
{description = "TAB", key = 9},
{description = "KP_0", key = 256},
{description = "KP_1", key = 257},
{description = "KP_2", key = 258},
{description = "KP_3", key = 259},
{description = "KP_4", key = 260},
{description = "KP_5", key = 261},
{description = "KP_6", key = 262},
{description = "KP_7", key = 263},
{description = "KP_8", key = 264},
{description = "KP_9", key = 265},
{description = "KP_PERIOD", key = 266},
{description = "KP_DIVIDE", key = 267},
{description = "KP_MULTIPLY", key = 268},
{description = "KP_MINUS", key = 269},
{description = "KP_PLUS", key = 270},
{description = "KP_ENTER", key = 271},
{description = "KP_EQUALS", key = 272},
{description = "MINUS", key = 45},
{description = "EQUALS", key = 61},
{description = "SPACE", key = 32},
{description = "ENTER", key = 13},
{description = "ESCAPE", key = 27},
{description = "HOME", key = 278},
{description = "INSERT", key = 277},
{description = "DELETE", key = 127},
{description = "END   ", key = 279},
{description = "PAUSE", key = 19},
{description = "PRINT", key = 316},
{description = "CAPSLOCK", key = 301},
{description = "SCROLLOCK", key = 302},
{description = "RSHIFT", key = 303},
{description = "LSHIFT", key = 304},
{description = "RCTRL", key = 305},
{description = "LCTRL", key = 306},
{description = "RALT", key = 307},
{description = "LALT", key = 308},
{description = "LSUPER", key = 311},
{description = "RSUPER", key = 312},
--{description = "ALT", key = 400},
--{description = "CTRL", key = 401},
--{description = "SHIFT", key = 402},
{description = "BACKSPACE", key = 8},
{description = "PERIOD", key = 46},
{description = "SLASH", key = 47},
{description = "SEMICOLON", key = 59},
{description = "LEFTBRACKET", key = 91},
{description = "BACKSLASH", key = 92},
{description = "RIGHTBRACKET", key = 93},
{description = "TILDE", key = 96},
{description = "A", key = 97},
{description = "B", key = 98},
{description = "C", key = 99},
{description = "D", key = 100},
{description = "E", key = 101},
{description = "F", key = 102},
{description = "G", key = 103},
{description = "H", key = 104},
{description = "I", key = 105},
{description = "J", key = 106},
{description = "K", key = 107},
{description = "L", key = 108},
{description = "M", key = 109},
{description = "N", key = 110},
{description = "O", key = 111},
{description = "P", key = 112},
{description = "Q", key = 113},
{description = "R", key = 114},
{description = "S", key = 115},
{description = "T", key = 116},
{description = "U", key = 117},
{description = "V", key = 118},
{description = "W", key = 119},
{description = "X", key = 120},
{description = "Y", key = 121},
{description = "Z", key = 122},
{description = "F1", key = 282},
{description = "F2", key = 283},
{description = "F3", key = 284},
{description = "F4", key = 285},
{description = "F5", key = 286},
{description = "F6", key = 287},
{description = "F7", key = 288},
{description = "F8", key = 289},
{description = "F9", key = 290},
{description = "F10", key = 291},
{description = "F11", key = 292},
{description = "F12", key = 293},
{description = "UP", key = 273},
{description = "DOWN", key = 274},
{description = "RIGHT", key = 275},
{description = "LEFT", key = 276},
{description = "PAGEUP", key = 280},
{description = "PAGEDOWN", key = 281},
{description = "0", key = 48},
{description = "1", key = 49},
{description = "2", key = 50},
{description = "3", key = 51},
{description = "4", key = 52},
{description = "5", key = 53},
{description = "6", key = 54},
{description = "7", key = 55},
{description = "8", key = 56},
{description = "9", key = 57},
{description = "MOUSE_X1", key = 1005},
{description = "MOUSE_X2", key = 1006},
}

local keyslist = {}
for i=1,#keys do
    keyslist[i] = {description = keys[i].description, data = keys[i].key}
end

configuration_options =
Ch and
{
    {
        name = "Language",
        label = "语言",
        options =   {
                        {description = "English", data = "en"},
                        {description = "简体中文", data = "zh"},
                    },
        default = Ch and "zh" or "en",
    },
    {
        name = "CheckKey",
        label = "自我检查按键",
        options = keyslist,
        default = 106,
    },
    {
        name = "BugJumpKey",
        label = "虫跃技能按键",
        options = keyslist,
        default = 107,  -- 默认 K 键
    },
    {
        name = "DaggerLimit",
        label = "短剑限制",
        options =   {
                        {description = "92攻击力", data = true},
                        {description = "无上限", data = false},
                    },
        default = false,
    },
    {
        name = "LevelLimit",
        label = "等级限制",
        options =   {
                        {description = "50级", data = 50},
                        {description = "无上限", data = false},
                    },
        default = false,
    },
    {
        name = "GestaltAttackKey",
        label = "虚影攻击开关按键",
        options = keyslist,
        default = 108,  -- L键
    },
    {
        name = "RemoveThuleciteTradable",
        label = "铥矿取消可交易属性",
        options =   {
            {description = "开启", data = true},
            {description = "关闭", data = false},
        },
        default = true,
    },
    --[[{
        name = "CrossEdge",
        label = "闪避穿越边缘",
        options =   {
                        {description = "是", data = true},
                        {description = "否", data = false},
                    },
        default = false,
    },]]
} or
{
    {
        name = "Language",
        label = "Language",
        options =   {
                        {description = "English", data = "en"},
                        {description = "Chinese", data = "zh"},
                    },
        default = Ch and "zh" or "en",
    },
    {
        name = "CheckKey",
        label = "CheckKey",
        options = keyslist,
        default = 106,
    },
    {
        name = "BugJumpKey",
        label = "Bug Jump Key",
        options = keyslist,
        default = 107,
    },
    {
        name = "DaggerLimit",
        label = "DaggerLimit",
        options =   {
                        {description = "Damage 92", data = true},
                        {description = "false", data = false},
                    },
        default = false,
    },
    {
        name = "LevelLimit",
        label = "LevelLimit",
        options =   {
                        {description = "Lv 50", data = 50},
                        {description = "UnLimit", data = false},
                    },
        default = false,
    },
    {
        name = "GestaltAttackKey",
        label = "Gestalt Attack Toggle Key",
        options = keyslist,
        default = 108,  -- L键
    },
    {
        name = "RemoveThuleciteTradable",
        label = "Remove Thulecite Tradable",
        options =   {
            {description = "On", data = true},
            {description = "Off", data = false},
        },
        default = true,
    },
}

