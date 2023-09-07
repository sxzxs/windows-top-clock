#include <Direct2DRender>

monitor_info := get_all_monitor_info()
g_all_clock := []
loop(monitor_info.Length)
{
    g_all_clock.Push(Clock(monitor_info[A_Index]))
}

g_font_size := 30
g_opacity := 0xBB

#HotIf is_hover()
wheeldown::
{
    global g_opacity
    g_opacity := (g_opacity-10 < 1 ? 1 : g_opacity-10)
    return
}

wheelup::
{
    global g_opacity
    g_opacity := (g_opacity+10 > 255 ? 255 : g_opacity+10)
    return
}

^wheeldown::
{
    global g_font_size
    g_font_size := (g_font_size-1 < 1 ? 1 : g_font_size-1)
}

^wheelup::
{
    global g_font_size
    g_font_size := (g_font_size+1 > 100 ? 100 : g_font_size+1)
}
#HotIf

class Clock
{
    __New(monitor_info) 
    {
        this.overlay := Direct2DRender(0, 0, 50, 50)
        this.monitor_info := monitor_info
        this.x := monitor_info.Left
        this.y := monitor_info.Top
        this.w := monitor_info.Right - monitor_info.Left
        this.h := monitor_info.Bottom - monitor_info.Top
        ;设置定时器
        SetTimer(ObjBindMethod(this, 'draw'), 40)
    }
    is_hover() => this.overlay.GetMousePos(&mx, &my)
    draw()
    {
        uijm :=A_Hour '∶' A_Min '∶' A_Sec
        wh := this.overlay.GetTextWidthHeight(uijm, g_font_size, 'Courier')
        w := wh.width, h := wh.height
        this.overlay.SetPosition(this.x, 0, w, h)
        if (this.overlay.BeginDraw()) 
        {
            this.overlay.FillRoundedRectangle(0, 0, w, h, 5, 5, g_opacity << 24)
            this.overlay.DrawText(uijm, 0, 0, g_font_size, 0xccFF0000, "Courier")
            this.overlay.EndDraw()
        }
    }
}

is_hover()
{
    for k,v in g_all_clock
    {
        if(v.is_hover())
            return true
    }
    return false
}

get_all_monitor_info()
{
    screen_number := GetMonitorCount()
    arr_screen := []
    loop(screen_number)
    {
        info := GetMonitorInfo(A_Index)
        arr_screen.Push(info)
    }
    return arr_screen
}

GetMonitorCount()
{
	Monitors := MDMF_Enum()
	return Monitors['TotalCount']
}

GetMonitorInfo(MonitorNum)
{
	Monitors := MDMF_Enum()
	for k,v in Monitors 
	{
		if(IsObject(v) && v.HasOwnProp('num'))
		{
			if (v.Num = MonitorNum) 
			{
				return v
			}
		}
	}
}

GetPrimaryMonitor()
{
	Monitors := MDMF_Enum()
	for k,v in Monitors {
		if (v.Primary) {
			return v.Num
		}
	}
}
MDMF_Enum(HMON := "") {
	static EnumProc := CallbackCreate(MDMF_EnumProc)
	static Monitors := Map()

	if (HMON = "") { 	; new enumeration
		Monitors := Map("TotalCount", 0)
		if !DllCall("User32.dll\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", EnumProc, "Ptr", ObjPtr(Monitors), "Int")
			return False
	}

	return (HMON = "") ? Monitors : Monitors.HasKey(HMON) ? Monitors[HMON] : False
}
MDMF_EnumProc(HMON, HDC, PRECT, ObjectAddr) {
	Monitors := ObjFromPtrAddRef(ObjectAddr)

	Monitors[HMON] := MDMF_GetInfo(HMON)
	Monitors["TotalCount"]++
	if (Monitors[HMON].Primary) {
		Monitors["Primary"] := HMON
	}

	return true
}

MDMF_GetInfo(HMON) {
	MIEX := Buffer(40 + (32 << !!1))
	NumPut("UInt", MIEX.Size, MIEX, 0)
	if DllCall("User32.dll\GetMonitorInfo", "Ptr", HMON, "Ptr", MIEX.Ptr, "Int") {
		return {Name:      (Name := StrGet(MIEX.Ptr + 40, 32))  ; CCHDEVICENAME = 32
		      , Num:       RegExReplace(Name, ".*(\d+)$", "$1")
		      , Left:      NumGet(MIEX, 4, "Int")    ; display rectangle
		      , Top:       NumGet(MIEX, 8, "Int")    ; "
		      , Right:     NumGet(MIEX, 12, "Int")   ; "
		      , Bottom:    NumGet(MIEX, 16, "Int")   ; "
		      , WALeft:    NumGet(MIEX, 20, "Int")   ; work area
		      , WATop:     NumGet(MIEX, 24, "Int")   ; "
		      , WARight:   NumGet(MIEX, 28, "Int")   ; "
		      , WABottom:  NumGet(MIEX, 32, "Int")   ; "
		      , Primary:   NumGet(MIEX, 36, "UInt")} ; contains a non-zero value for the primary monitor.
	}
	return False
}