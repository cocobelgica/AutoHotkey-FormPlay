#Include <CFunction>
#Include <GuiWnd>
#Include <GButtonCtl>
#Include <GEditCtl>
#Include <WebBrowserCtl>

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