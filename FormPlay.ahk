Main()
return
Main()
{
	this := new MainWindow2()
	this.Show()
	
	hMain := this.Handle
	WinWaitClose, ahk_id %hMain%
	
	ExitApp
}

class MainWindow2 extends MainWindow
{
	SetHotkeys(enable:=true)
	{
		if enable
		{
			ToggleConsole := this.Commands.toggle_console
			FocusHTMLPane := this.Commands.focus_htmlpane
			FocusCSSPane  := this.Commands.focus_csspane
			FocusJSPane   := this.Commands.focus_jspane
			LoadDocument  := this.Commands.load_document
			Help          := this.Commands.help

			Menu, ViewMenu, Add, Show/Hide Console`tCtrl+``, %ToggleConsole%
			Menu, ViewMenu, Add, Focus HTML Pane`tCtrl+1, %FocusHTMLPane%
			Menu, ViewMenu, Add, Focus CSS Pane`tCtrl+2, %FocusCSSPane%
			Menu, ViewMenu, Add, Focus JS Pane`tCtrl+3, %FocusJSPane%
			
			Menu, ToolsMenu, Add, Run/Refresh`tF5, %LoadDocument%

			Menu, HelpMenu, Add, Help`tF1, %Help%

			Menu, MenuBar, Add, &View, :ViewMenu
			Menu, MenuBar, Add, &Tools, :ToolsMenu
			Menu, MenuBar, Add, &Help, :HelpMenu
			this.Menu := "MenuBar"
		}
		else
		{
			this.Menu := ""
			Menu, ViewMenu, Delete
			Menu, ToolsMenu, Delete
			Menu, HelpMenu, Delete
			Menu, MenuBar, Delete
		}
	}
}

class MainWindow extends GuiWnd
{
	__New()
	{
		base.__New("FormPlay", "+Resize")
		
			this.SetFont("s10", "Lucida Console")
			this.SetFont(, "Consolas")
			this.Margin["XY"] := 5

		hMain := this.Handle

		width := A_ScreenWidth*0.80, height := A_ScreenHeight*0.80

		w := (width-15)*0.35, h := (height-20)//3
		this.HTMLPane := new GEditCtl(hMain, "-Wrap +WantTab +HScroll t16 xm ym w" . w . " h" . h, "<!-- HTML Pane -->`n")
		this.CSSPane  := new GEditCtl(hMain, "-Wrap +WantTab +HScroll t16 xp y+5 wp hp", "/* CSS Pane */`n")
		this.JSPane   := new GEditCtl(hMain, "-Wrap +WantTab +HScroll t16 xp y+5 wp hp", "// JavaScript Pane`n")

		w := (width-15)*0.65
		this.View := new this.WebView(this, "x+5 y0 w" . w . " h" . height)

		this.Console := new this.JsConsole(
		(LTrim Join, Q
			this
			new GEditCtl(hMain, "xp y+0 wp r7 -Wrap t16 +ReadOnly Hidden")
			new GEditCtl(hMain, "xp y+5 wp r1 -Wrap t16 Hidden")
		))
			this.DefaultBtn := new GButtonCtl(hMain, "x0 y0 w0 h0 Hidden Default")
			this.DefaultBtn.Listener := ObjBindMethod(this.Console, "Submit")

		; for menus/hotkeys/glabels etc. esp. for sublcasses
		this.Commands := { toggle_console: ObjBindMethod(this.Console, "ToggleShowHide")
		                 , focus_htmlpane: ObjBindMethod(this.HTMLPane, "SetFocus")
		                 , focus_csspane:  ObjBindMethod(this.CSSPane, "SetFocus")
		                 , focus_jspane:   ObjBindMethod(this.JSPane, "SetFocus")
		                 , load_document:  ObjBindMethod(this.View, "LoadDocument")
		                 , help:           ObjBindMethod(this, "Help") }
		
		
		this.AutoReload := new this.Timer(-10000, this.Commands.load_document)
		OnEditChange := ObjBindMethod(this.AutoReload, "Run")
			this.HTMLPane.Listener := OnEditChange
			this.CSSPane.Listener  := OnEditChange
			this.JSPane.Listener   := OnEditChange

		this.SetHotkeys()
		this.View.LoadDocument()
		this.Show("Hide Center w" . width . " h" . height)
		this.HTMLPane.SetFocus()
	}

	OnEscape()
	{
		this.OnClose()
	}

	OnClose()
	{
		this.SetHotkeys(0)
		this.Commands := ""
		this.DefaultBtn.Listener := ""
		this.HTMLPane.Listener := ""
		this.CSSPane.Listener := ""
		this.JSPane.Listener := ""
		this.Destroy()
	}

	OnSize(EventInfo, w, h)
	{
		DllCall("SetWindowPos"
		      , "Ptr",  this.View.Handle
		      , "Ptr",  0
		      , "Int",  x := ((w-15)*0.35)+10
		      , "Int",  0
		      , "Int",  (w-10)*0.65
		      , "Int",  h-(this.Console.IsVisible ? this.Console.Height : 0)
		      , "UInt", 0)

		static ConsoleOutputHeight := 0
		if !ConsoleOutputHeight
			ConsoleOutputHeight := this.Console.Output.Pos["H"]

		Move := this.Console.IsVisible ? "MoveDraw" : "Move"
		y := h-this.Console.Height+5, wd := (w-15)*0.65
		(this.Console.Output)[Move](x, y, wd)
		y += ConsoleOutputHeight + 5
		(this.Console.Input)[Move](x, y, wd)

		w := (w-15)*0.35, h := (h-20)//3
		this.HTMLPane.Move(,, w, h)
		y := h + 10
		this.CSSPane.Move(, y, w, h)
		y += h + 5
		this.JSPane.Move(, y, w, h)
	}

	SetHotkeys(enable:=true)
	{
		hMain := this.Handle
		Hotkey, IfWinActive, ahk_id %hMain%

			if enable
			{
				ToggleConsole := this.Commands.toggle_console
				FocusHTMLPane := this.Commands.focus_htmlpane
				FocusCSSPane  := this.Commands.focus_csspane
				FocusJSPane   := this.Commands.focus_jspane
				LoadDocument  := this.Commands.load_document
				Help          := this.Commands.help

				Hotkey, F1,  %Help%
				Hotkey, F5,  %LoadDocument%
				Hotkey, ^1,  %FocusHTMLPane%
				Hotkey, ^2,  %FocusCSSPane%
				Hotkey, ^3,  %FocusJSPane%
				Hotkey, ^``, %ToggleConsole%
			}
			else 
			{
				Hotkey, F1,,  Off
				Hotkey, F5,,  Off
				Hotkey, ^1,,  Off
				Hotkey, ^2,,  Off
				Hotkey, ^3,,  Off
				Hotkey, ^``,, Off
			}
		
		Hotkey, IfWinActive
	}

	class WebView extends WebBrowserCtl
	{
		__New(self, args*)
		{
			base.__New(self.Handle, args*)
			this.__Wnd := &self
		}

		Window {
			get {
				if ( NumGet(this.__Wnd) == NumGet(&(obj := {})) )
					return Object(this.__Wnd)
			}
		}

		LoadDocument()
		{
			static html := "
			(LTrim
			<!DOCTYPE html>
			<html>
			<head>
			<meta http-equiv='X-UA-Compatible' content='IE=Edge'/>
			<script type='text/javascript'>
			var console = {
				log: function (input) {
					var result = JSON.stringify( input );
					this.write.call('>>> ' + input + '\r\n' + result);
					return result;
				},
				write: ''
			};
			</script>
			<style type='text/css'>
			{1}
			</style>
			</head>
			<body>
			{2}
			<script type='text/javascript'>
			{3}
			</script>
			</body>
			</html>
			)"
			
			main := this.Window

			; kill timer if this method was invoked by a menu item, hotkey, or gui event
			if (A_ThisMenu || A_ThisHotkey || A_Gui)
				main.AutoReload.Kill()
			
			body   := main.HTMLPane.Value
			style  := main.CSSPane.Value
			script := main.JSPane.Value

			FocusedCtl := main.FocusedCtl

			document := this.Document
			document.open()
			document.write(Format(html, style, body, script))
			document.parentWindow.console.write := ObjBindMethod(main.Console, "Write")
			document.close()

			; loading the document steals keyboard focus, return focus to previously focused control
			hMain := main.Handle
			GuiControl, %hMain%:Focus, %FocusedCtl%
		}
	}

	class JsConsole
	{
		__New(self, output, input)
		{
			this.Output := output
			this.Input := input
			this.Height := 15 + output.Pos["H"] + input.Pos["H"]

			this.__IsVisible := false
			this.__Wnd := &self
		}

		Window {
			get {
				if ( NumGet(this.__Wnd) == NumGet(&(obj := {})) )
					return Object(this.__Wnd)
			}
		}

		Submit(args*)
		{
			if (this.Window.FocusedCtl == this.Input.Handle)
			{
				input := this.Input.Value
				window := this.Window.View.Document.parentWindow
				try result := window.eval("(function () { return " . input . "; })()")
				if IsObject(result)
					window.console.log(result)
				else
					this.Write( Format(">>> {1}`n{2}", input, result) )

				this.Input.Value := "" ; clear input
			}
		}

		Write(text)
		{
			text := RegExReplace(text, "\R", "`r`n")
			hOutput := this.Output.Handle
			SendMessage 0x000E, 0, 0,, ahk_id %hOutput% ; WM_GETTEXTLENGTH
			if (ErrorLevel)
				text := "`r`n" . text
			SendMessage 0x00B1, %ErrorLevel%, %ErrorLevel%,, ahk_id %hOutput% ; EM_SETSEL
			pText := &text
			SendMessage 0x00C2, 0, %pText%,, ahk_id %hOutput% ; EM_REPLACESEL
		}

		IsVisible {
			get {
				return this.__IsVisible
			}
			set {
				if (value && !this.IsVisible) || (!value && this.IsVisible)
				{
					pos := this.Window.ClientPos
						x := ((pos.W-15)*0.35)+10
						w := (pos.W-10)*0.65
						h := pos.H

					if value {
						this.Output.Move(x, h-this.Height+5, w)
						this.Input.Move(x, h-5-this.Input.Pos["H"], w)
						h -= this.Height
					}
					this.Output.Hide(!value)
					this.Input.Hide(!value)

					DllCall("SetWindowPos", "Ptr", this.Window.View.Handle, "Ptr", 0, "Int", x, "Int", 0, "Int", w, "Int", h, "UInt", 0)
				}
				return this.__IsVisible := value
			}
		}
		
		ToggleShowHide()
		{
			; console is visible but doesn't have keyboard focus
			; do not toggle show/hide but instead set focus to its input field
			if this.IsVisible
			&& (this.Window.FocusedCtl != this.Input.Handle)
			&& (this.Window.FocusedCtl != this.Output.Handle)
				return this.Input.SetFocus()

			this.IsVisible := !this.IsVisible

			static PrevFocusedCtl := 0
			if this.IsVisible
			{
				for i, ctl in [this.Window.HTMLPane, this.Window.CSSPane, this.Window.JSPane]
					if ( PrevFocusedCtl := this.Window.FocusedCtl==ctl.Handle ? &ctl : 0 )
						break
				this.Input.SetFocus()
			}
			else if PrevFocusedCtl && ( NumGet(PrevFocusedCtl+0) == NumGet(&(obj := {})) )
				Object(PrevFocusedCtl).SetFocus(), PrevFocusedCtl := 0
		}
	}

	class Timer extends CFunction
	{
		__New(period, FuncObj)
		{
			this.Period := period
			this.Target := FuncObj
		}

		__Delete()
		{
			this.Target := ""
			this.Kill()
		}

		Call(args*)
		{
			this.Target.Call()
			this.Kill()
		}

		Run()
		{
			period := this.Period
			SetTimer, %this%, %period%
		}

		Kill()
		{
			SetTimer, %this%, Delete
		}
	}

	Help()
	{
		MsgBox,, %A_ScriptName% - Help, % "
		(LTrim Join`n
		Hotkeys:

		F1`tHelp
		F5`tRun\Refresh
		Ctrl + ```tToggle console
		Ctrl + 1`tFocus HTML Pane
		Ctrl + 2`tFocus CSS Pane
		Ctrl + 3`tFocus JavaScript Pane
		)"
	}
}

; Base class for custom "Function" objects
class CFunction
{
	__Call(method, args*)
	{
		if IsObject(method) || (method == "")
			return method ? this.Call(method, args*) : this.Call(args*)
	}
}

class WebBrowserCtl extends GActiveXCtl
{
	__New(gui, options:="", init:="about:<!DOCTYPE html><html><head><meta http-equiv='X-UA-Compatible' content='IE=Edge'/></head></html>")
	{
		base.__New(gui, options, init)
		while (this.Ptr.ReadyState != 4)
			Sleep, 10
	}

	Document {
		get {
			return this.Ptr.Document
		}
	}

	Window {
		get {
			return this.Document.parentWindow
		}
	}
}

class RebarCtl extends GCustomCtl
{
	static Class := "ReBarWindow32"
}


class GCustomCtl extends GuiCtl
{
	static Type := "Custom"
	static Class := ""

	__New(gui, args*)
	{
		class := this.Class ? this.Class : ObjRemoveAt(args, 1)
		options := Format("{1} Class{2}", args[1], class)
		base.__New(gui, options, args*)
	}
}

class GActiveXCtl extends GuiCtl
{
	static Type := "ActiveX"

	Ptr {
		get {
			if !this.__Ptr
				this.__Ptr := this.Value ; store in internal property
			return this.__Ptr
		}
		set {
			throw Exception("This property is read-only", -1, "Ptr")
		}
	}
}

class GEditCtl extends GuiCtl
{
	static Type := "Edit"
}

class GButtonCtl extends GuiCtl
{
	static Type := "Button"
}

class GStatusBarCtl extends GuiCtl
{
	static Type := "StatusBar"

	SetText(text, PartNumber:=1, style:=0)
	{
		gui := this.Gui
		Gui, %gui%:Default
		return SB_SetText(text, PartNumber, style)
	}

	SetParts(width*)
	{
		gui := this.Gui
		Gui, %gui%:Default
		return SB_SetParts(width*)
	}
}

class GuiCtl
{
	static Type := ""
	
	__New(gui, args*)
	{
		Gui, %gui%:+LastFoundExist
		if !WinExist()
			throw Exception("GUI does not exist.", -1, gui)

		CtlType := this.Type ? this.Type : ObjRemoveAt(args, 1)
		options := args[1], text := args[2]
		Gui, %gui%:Add, %CtlType%, %options% HwndhCtl, %text%
		this.__Handle := hCtl + 0
		this.__Gui := gui
	}

	Handle {
		get {
			return this.__Handle + 0
		}
		set {
			throw Exception("This property is read-only", -1, "Handle")
		}
	}

	Gui {
		get {
			return this.__Gui
		}
		set {
			throw Exception("This property is read-only", -1, "Gui")
		}
	}

	Value {
		set {
			gui := this.Gui, hCtl := this.Handle
			GuiControl, %gui%:, %hCtl%, %value%
			return value
		}
		get {
			gui := this.Gui, hCtl := this.Handle
			GuiControlGet, value, %gui%:, %hCtl%
			return value
		}
	}

	Pos[arg:=""] {
		get {
			gui := this.Gui, hCtl := this.Handle
			GuiControlGet, pos, %gui%:Pos, %hCtl%
			return arg ? pos%arg% : { X:posX, Y:posY, W:posW, H:posH }
		}
	}

	Listener {
		set {
			gui := this.Gui, hCtl := this.Handle
			if value
			{
				if IsObject(value)
					GuiControl, %gui%:+g, %hCtl%, %value%
				else
					GuiControl, %gui%:+g%value%, %hCtl%
			}
			else
				GuiControl, %gui%:-g, %hCtl%

			return value
		}
	}

	SetFocus()
	{
		gui := this.Gui, hCtl := this.Handle
		GuiControl, %gui%:Focus, %hCtl%
	}

	Move(X:="", Y:="", W:="", H:="", redraw:=false)
	{
		gui := this.Gui
		hCtl := this.Handle

		pos := ""
		Loop, Parse, % "xywh"
			if (%A_LoopField% != "")
				pos .= " " . A_LoopField . %A_LoopField%

		Move := redraw ? "MoveDraw" : "Move"
		GuiControl, %gui%:%Move%, %hCtl%, %pos%
	}

	MoveDraw(X:="", Y:="", W:="", H:="")
	{
		this.Move(X, Y, W, H, true)
	}

	Hide(hide:=true)
	{
		gui := this.Gui, hCtl := this.Handle
		GuiControl, %gui%:Hide%hide%, %hCtl%
	}
}

class GuiChildWnd extends GuiWnd
{
	__New(parent, title:="", options:="")
	{
		Gui, %parent%:+LastFoundExist
		if !WinExist()
			throw Exception("Parent GUI does not exist.", -1, parent)

		options .= " +Parent" . parent
		base.__New(title, options)
		this.__Parent := parent
	}

	Parent {
		get {
			return this.__Parent
		}
	}
}

class GuiWnd
{
	static Windows := {}
	
	__New(title:="", options:="", FuncPrefixOrObj:="")
	{
		Gui, New, +LastFound %options% +LabelGWnd_On, %title%
		this.__Handle := WinExist()+0
		this.__FuncPrefixOrObj := FuncPrefixOrObj

		GuiWnd.Windows[this.Handle] := &this
	}

	__Delete()
	{
		if (this.Handle && DlLCall("IsWindow", "Ptr", this.Handle))
			this.Destroy()
	}

	__Call(method, args*)
	{
		if ( InStr(method, "Add")==1 && StrLen(method)>3 )
			return this.Add(SubStr(method, 4), args*)
	}

	Handle {
		get {
			return this.__Handle + 0
		}
		set {
			throw Exception("This property is read-only", -1, "Handle")
		}
	}

	Options {
		set {
			h := this.Handle
			Gui, %h%:%value%
			return value
		}
	}

	Add(CtlType, options:="", text:="")
	{
		global ; for control's associated variable(s)
		local h, hCtl
		h := this.Handle
		Gui, %h%:Add, %CtlType%, %options% +HwndhCtl, %text%
		return hCtl
	}

	Show(options:="", title:="")
	{
		h := this.Handle
		Gui, %h%:Show, %options%, %title%
	}

	Destroy()
	{
		h := this.Handle
		Gui, %h%:Destroy
		ObjDelete(GuiWnd.Windows, h)
		this.__Handle := ""
	}

	SetOptions(options:="")
	{
		h := this.Handle
		Gui, %h%:%options%
	}

	SetFont(FontOptions:="", FontName:="")
	{
		h := this.Handle
		Gui, %h%:Font, %FontOptions%, %FontName%
	}

	BgColor {
		set {
			h := this.Handle
			Gui, %h%:Color, %value%
			return value
		}
	}

	CtlColor {
		set {
			h := this.Handle
			Gui, %h%:Color,, %value%
			return value
		}
	}

	Margin[arg:="XY"] {
		set {
			h := this.Handle
			X := Trim(arg, " `tY")="X" ? value : ""
			Y := Trim(arg, " `tX")="Y" ? value : ""
			Gui, %h%:Margin, %X%, %Y%
			return value
		}
	}

	Menu {
		set {
			h := this.Handle
			Gui, %h%:Menu, %value%
			return value
		}
	}

	Hide()
	{
		h := this.Handle
		Gui, %h%:Hide
	}

	Minimize()
	{
		h := this.Handle
		Gui, %h%:Minimize
	}

	Maximize()
	{
		h := this.Handle
		Gui, %h%:Maximize
	}

	Restore()
	{
		h := this.Handle
		Gui, %h%:Restore
	}

	Flash(flash:=true)
	{
		h := this.Handle
		OnOrOff := (flash && flash!="Off") ? "On" : "Off"
		Gui, %h%:Flash, %OnOrOff%
	}

	SetAsDefault()
	{
		h := this.Handle
		Gui, %h%:Default
	}

	FocusedCtl {
		get {
			h := this.Handle
			GuiControlGet, FocusedCtl, %h%:Focus
			GuiControlGet, hFocusedCtl, %h%:Hwnd, %FocusedCtl%
			return hFocusedCtl+0
		}
	}

	OnClose()
	{
		this.Destroy()
		
		prev_DHW := A_DetectHiddenWindows
		DetectHiddenWindows, On
			
			static PID := DllCall("GetCurrentProcessId")
			if !WinExist("ahk_class AutoHotkeyGUI ahk_pid " . PID)
				SetTimer, gwnd_exit, -1
		
		DetectHiddenWindows, %prev_DHW%
		return
	gwnd_exit:
		ExitApp
	}

	_OnEvent(event, args*)
	{
		FuncPrefixOrObj := this.__FuncPrefixOrObj

		; Similar to ComObjConnect
		if IsObject(FuncPrefixOrObj)
			return FuncPrefixOrObj[event](this, args*)

		; +Label<LabelorFuncPrefix>
		else if fn := Func(FuncPrefixOrObj . event)
			return fn.Call(this, args*)

		; Subclassing
		else
			return this[event](args*)
	}

	Pos[arg:="", client:=false] {
		get {
			static RECT
			if !VarSetCapacity(RECT)
				VarSetCapacity(RECT, 16, 0)
			DllCall(client ? "GetClientRect" : "GetWindowRect", "Ptr", this.Handle, "Ptr", &RECT)
				w := NumGet(RECT,  8, "Int") - x := NumGet(RECT,  0, "Int")
				h := NumGet(RECT, 12, "Int") - y := NumGet(RECT,  4, "Int")

			return ((StrLen(arg:=Trim(arg, " `t`r`n"))==1) && InStr("XYWH", arg)) ? %arg% : { X:x, Y:y, W:w, H:h }
		}
	}

	ClientPos[arg:=""] {
		get {
			return this.Pos[arg, true]
		}
	}
}

GWnd_Get(h)
{
	if ( pThis := GuiWnd.Windows[h + 0] )
	&& ( NumGet(pThis+0) == NumGet(&(o := {})) ) ; make sure it's an object pointer
		return Object(pThis)
}

GWnd_OnClose(h)
{
	return GuiWnd._OnEvent.Call(GWnd_Get(h), "OnClose")
}

GWnd_OnEscape(h)
{
	return GuiWnd._OnEvent.Call(GWnd_Get(h), "OnEscape")
}

GWnd_OnSize(h, args*)
{
	return GuiWnd._OnEvent.Call(GWnd_Get(h), "OnSize", args*)
}

GWnd_OnContextMenu(h, args*)
{
	return GuiWnd._OnEvent.Call(GWnd_Get(h), "OnContextMenu", args*)
}

GWnd_OnDropFiles(h, args*)
{
	return GuiWnd._OnEvent.Call(GWnd_Get(h), "OnDropFiles", args*)
}