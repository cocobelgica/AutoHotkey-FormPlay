Main()
return
Main()
{
	this := new MainWindow2()
	this.Form.LoadDocument()
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
			ToggleConsole := ObjBindMethod(this, "ToggleConsole")
			FocusHTMLPane := ObjBindMethod(this.HTMLPane, "SetFocus")
			FocusCSSPane  := ObjBindMethod(this.CSSPane, "SetFocus")
			FocusJSPane   := ObjBindMethod(this.JSPane, "SetFocus")
			LoadDocument  := ObjBindMethod(this.Form, "LoadDocument")
			ToggleDock    := ObjBindMethod(this, "ToggleDock")
			Help          := ObjBindMethod(this, "Help")

			Menu, ViewMenu, Add, Show/Hide Console`tCtrl+``, %ToggleConsole%
			Menu, ViewMenu, Add, Focus HTML Pane`tCtrl+1, %FocusHTMLPane%
			Menu, ViewMenu, Add, Focus CSS Pane`tCtrl+2, %FocusCSSPane%
			Menu, ViewMenu, Add, Focus JS Pane`tCtrl+3, %FocusJSPane%
			Menu, ViewMenu, Add, Dock Form, %ToggleDock%
			
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

	ToggleDock()
	{
		VarSetCapacity(RECT, 16, 0)
		DllCall("GetClientRect", "Ptr", this.Handle, "Ptr", &RECT)
			w := NumGet(RECT, 0, "Int") + NumGet(RECT, 8, "Int")
			h := NumGet(RECT, 4, "Int") + NumGet(RECT, 12, "Int")
		
		this.Canvas.Hide()
		if (this.Form.WebView != this.Canvas)
		{
			WB := this.Form.WebView0 ? this.Form.WebView0 : new WebBrowserCtl(this.Handle, "x0 y0 w10 h100 Hidden")
			this.Canvas0 := this.Canvas
			this.Form.WebView0 := this.Form.WebView
			this.Form.WebView := this.Canvas := WB

			this.Canvas.Hide(0)
			Menu, ViewMenu, Rename, Dock Form, Undock Form
		}
		else
		{
			WB := this.Form.WebView0
			this.Canvas := ObjDelete(this, "Canvas0")
			this.Form.WebView0 := this.Form.WebView
			this.Form.WebView := WB

			this.Canvas.Show()
			Menu, ViewMenu, Rename, Undock Form, Dock Form
		}

		this.OnSize(0, w, h)
		this.Show()

		document := WB.Document
		document.open()
		document.write(this.Form.WebView0.Document.documentElement.outerHtml)
		document.parentWindow.console.write := ObjBindMethod(this, "ConsoleWrite")
		document.close()
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

		this.DefaultBtn := new GButtonCtl(hMain, "x0 y0 w0 h0 Hidden Default")
			this.DefaultBtn.Listener := ObjBindMethod(this, "ConsoleSubmit")
		this.StatusBar := new GStatusBarCtl(hMain)
			sbpos_H := this.StatusBar.Pos["H"]

		
		width := A_ScreenWidth*0.80, height := A_ScreenHeight*0.80

		w := (width-15)*0.35, h := (height-sbpos_H-20)//3
		this.StatusBar.SetParts(w)
		this.HTMLPane := new GEditCtl(hMain, "-Wrap +WantTab +HScroll t16 xm ym w" . w . " h" . h, "<!-- HTML Pane -->")
		this.CSSPane  := new GEditCtl(hMain, "-Wrap +WantTab +HScroll t16 xp y+5 wp hp", "/* CSS Pane */")
		this.JSPane   := new GEditCtl(hMain, "-Wrap +WantTab +HScroll t16 xp y+5 wp hp", "// JavScript Pane")

		
		x := w+10
		w := (width-15)*0.65
		
		this.JsConsole := {}
			this.JsConsole.IsVisible := false
			this.JsConsole.Output := new GEditCtl(hMain, Format("x{1} yp w{2} r7 -Wrap t16 +ReadOnly Hidden", x, w))
			this.JsConsole.Input  := new GEditCtl(hMain, "-Wrap t16 Hidden r1 xp y+5 wp")

			this.JsConsole.Height := 15 ; margin*3
			y := (h*3) + 15
			pos_H := this.JsConsole.Input.Pos["H"]
			y -= pos_H, this.JsConsole.Height += pos_H
			this.JsConsole.Input.Move(, y)
			pos_H := this.JsConsole.Output.Pos["H"]
			y -= pos_H+5, this.JsConsole.Height += pos_H
			this.JsConsole.Output.Move(, y)

		
		this.Canvas := new GuiChildWnd(hMain,, "-Caption +ToolWindow")
			this.Canvas.BgColor := "858585"

			width := (width-15)*0.65, height -= sbpos_H
			this.Canvas.Show(Format("x{1} y0 w{2} h{3} Hide", x, width, height))

		
		w := width*0.85, h := height*0.85
		this.Form := new this.HtmlForm(this, "FormPlay - WebView", w, h) ; use 'this' to allow overwriting when subclassing
			this.Form.Show("Hide")

		; Workaround - 'Center' option is not positioning the child window in the center of its parent
		; Center it manually.
		VarSetCapacity(RECT, 16, 0)
		DllCall("GetWindowRect", "Ptr", this.Form.Handle, "Ptr", &RECT)
		x := (width//2) - ((wd := NumGet(RECT, 8, "Int") - NumGet(RECT, 0, "Int"))//2)
		y := (height//2) - ((ht := NumGet(RECT, 12, "Int") - NumGet(RECT, 4,"Int"))//2)
		this.Form.Show("Hide x" . x . " y" . y)

		this.SetHotkeys()

		base.Show("Hide")
		this.HTMLPane.SetFocus()
		this.StatusBar.SetText(" F1=Help, F5=Run, Ctrl+``=Toggle console")
		this.StatusBar.SetText(Format(" Mode: IE{1:i}`tWidth: {2}, Height: {3}", this.Form.WebView.Document.documentMode, wd, ht), 2)
	}

	Show(options:="", title:="")
	{
		this.Form.Show()
		this.Canvas.Show()
		base.Show(options, title)
	}

	OnEscape()
	{
		this.OnClose()
	}

	OnClose()
	{
		this.SetHotkeys(0)
		this.DefaultBtn.Listener := ""
		this.Form := ""
		this.Canvas := ""
		this.Destroy()
	}

	OnSize(EventInfo, w, h)
	{
		static sbpos_H := 0
		if !sbpos_H
			sbpos_H := this.StatusBar.Pos["H"]

		DllCall("SetWindowPos"
		      , "Ptr",  this.Canvas.Handle ; hCanvas
		      , "Ptr",  0
		      , "Int",  x := ((w-15)*0.35)+10
		      , "Int",  0
		      , "Int",  (w-10)*0.65
		      , "Int",  h-sbpos_H-(this.JsConsole.IsVisible ? this.JsConsole.Height : 0)
		      , "UInt", 0)

		static ConsoleOutputHeight := 0
		if !ConsoleOutputHeight
			ConsoleOutputHeight := this.JsConsole.Output.Pos["H"]

		Move := this.JsConsole.IsVisible ? "MoveDraw" : "Move"
		y := h-(sbpos_H + this.JsConsole.Height)+5, wd := (w-15)*0.65
		(this.JsConsole.Output)[Move](x, y, wd)
		y += ConsoleOutputHeight + 5
		(this.JsConsole.Input)[Move](x, y, wd)

		w := (w-15)*0.35, h := (h-sbpos_H-20)//3
		this.HTMLPane.Move(,, w, h)
		y := h + 10
		this.CSSPane.Move(, y, w, h)
		y += h + 5
		this.JSPane.Move(, y, w, h)

		this.StatusBar.SetParts(w + 10) ; update StatusBar part(s) width
	}

	SetHotkeys(enable:=true)
	{
		hMain := this.Handle
		Hotkey, IfWinActive, ahk_id %hMain%

			if enable
			{
				Help          := ObjBindMethod(this, "Help")
				LoadDocument  := ObjBindMethod(this.Form, "LoadDocument")
				FocusHTMLPane := ObjBindMethod(this.HTMLPane, "SetFocus")
				FocusCSSPane  := ObjBindMethod(this.CSSPane, "SetFocus")
				FocusJSPane   := ObjBindMethod(this.JSPane, "SetFocus")
				ToggleConsole := ObjBindMethod(this, "ToggleConsole")

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

	ToggleConsole()
	{
		console := this.JsConsole
		show := console.IsVisible := !console.IsVisible

		; console is visible but doesn't have keyboard focus
		; do not toggle show/hide but instead set focus to its input field
		if !show
		&& (this.FocusedCtl != console.Input.Handle)
		&& (this.FocusedCtl != console.Output.Handle)
			return (console.IsVisible := true) && console.Input.SetFocus()

		console.Output.Hide(!show)
		console.Input.Hide(!show)

		hCanvas := this.Canvas.Handle
		WinGetPos,,, w, h, ahk_id %hCanvas%
		h += show ? -console.Height : console.Height
		DllCall("SetWindowPos"
		      , "Ptr",  hCanvas
		      , "Ptr",  0
		      , "Int",  0
		      , "Int",  0
		      , "Int",  w
		      , "Int",  h
		      , "UInt", 0x0002)

		static PrevFocusedCtl := 0
		if show
		{
			for i, ctl in [this.HTMLPane, this.CSSPane, this.JSPane]
				if ( PrevFocusedCtl := this.FocusedCtl==ctl.Handle ? &ctl : 0 )
					break
			console.Input.SetFocus()
		}
		else if PrevFocusedCtl && ( NumGet(PrevFocusedCtl+0) == NumGet(&(obj := {})) )
			Object(PrevFocusedCtl).SetFocus(), PrevFocusedCtl := 0
	}

	ConsoleSubmit(args*)
	{
		if (this.FocusedCtl == this.JsConsole.Input.Handle)
		{
			input := this.JsConsole.Input.Value
			window := this.Form.WebView.Window
			try result := window.eval(input)
			if IsObject(result)
				window.console.log(result)
			else
				this.ConsoleWrite( Format(">>> {1}`n{2}", input, result) )

			this.JsConsole.Input.Value := "" ; clear input
		}
	}

	ConsoleWrite(text)
	{
		text := RegExReplace(text, "\R", "`r`n")
		hOutput := this.JsConsole.Output.Handle
		SendMessage 0x000E, 0, 0,, ahk_id %hOutput% ; WM_GETTEXTLENGTH
		if (ErrorLevel)
			text := "`r`n" . text
		SendMessage 0x00B1, %ErrorLevel%, %ErrorLevel%,, ahk_id %hOutput% ; EM_SETSEL
		pText := &text
		SendMessage 0x00C2, 0, %pText%,, ahk_id %hOutput% ; EM_REPLACESEL
	}

	class HtmlForm extends GuiChildWnd
	{
		__New(self, title:="", w:=600, h:=400)
		{
			base.__New(self.Canvas.Handle, title, "+Resize")
				this.SetFont("s10", "Lucida Console")
				this.SetFont(, "Consolas")
				this.Margin["XY"] := 0
			
			pos := Format("x0 y0 w{1} h{2}", w, h)
			this.WebView := new WebBrowserCtl(this.Handle, pos)

			this.__MainWnd := &self
		}

		MainWnd {
			get {
				if ( NumGet(this.__MainWnd) == NumGet(&(o := {})) )
					return Object(this.__MainWnd)
			}
		}

		OnClose()
		{
			MainWnd := this.MainWnd
				MainWnd.HTMLPane.Value := "<!-- HTML Pane -->"
				MainWnd.CSSPane.Value := "/* CSS Pane */"
				MainWnd.JSPane.Value := "// JavaScript Pane"
			this.LoadDocument() ; reset
			return true ; prevent window from closing
		}

		OnSize(EventInfo, w, h)
		{
			DllCall("SetWindowPos"
			      , "Ptr",  this.WebView.Handle
			      , "Ptr",  0
			      , "Int",  0
			      , "Int",  0
			      , "Int",  w
			      , "Int",  h
			      , "UInt", 0x0002) ; SWP_NOMOVE

			if (MainWnd := this.MainWnd)
				MainWnd.StatusBar.SetText(Format(" Mode: IE{1:i}`tWidth: {2}, Height: {3}", this.WebView.Document.documentMode, w, h), 2)
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
			
			main := this.MainWnd
			
			body   := main.HTMLPane.Value
			style  := main.CSSPane.Value
			script := main.JSPane.Value

			document := this.WebView.Document
			document.open()
			document.write(Format(html, style, body, script))
			document.parentWindow.console.write := ObjBindMethod(main, "ConsoleWrite")
			document.close()
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
		this.__Handle := hCtl
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

	Pos[which:=""] {
		get {
			gui := this.Gui, hCtl := this.Handle
			GuiControlGet, pos, %gui%:Pos, %hCtl%
			return which ? pos%which% : { X:posX, Y:posY, W:posW, H:posH }
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

	Margin[which:="XY"] {
		set {
			h := this.Handle
			X := Trim(which, " `tY")="X" ? value : ""
			Y := Trim(which, " `tX")="Y" ? value : ""
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
			
			static PID := DllCall("GetCurrentProcessID")
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