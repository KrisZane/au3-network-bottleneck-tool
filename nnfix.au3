#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
AutoItSetOption("MustDeclareVars", 1);
OnAutoItExitRegister("cleanUp");

Dim $probeOnOff = False;
Dim $probeWaitTimer = TimerInit();
Dim Const $thousand = 1000;

TCPStartup()

GUICreate("Nexination Net Fix", 350, 350);
GUICtrlCreateLabel("Host:", 20, 7);
Dim $probeHost = GuiCtrlCreateInput("google.com", 50, 5, 140, 20);
GUICtrlCreateLabel("Max Timeout:", 233, 7);4
Dim $probeAlertTime = GuiCtrlCreateInput("50", 300, 5, 20, 20);
Dim $probeStartStop = GUICtrlCreateButton("Start", 130, 60, 80, 20);
Dim $probeView = GUICtrlCreateEdit("", 20, 80, 300, 200, $ES_AUTOVSCROLL + $WS_VSCROLL + $ES_READONLY)
GUICtrlCreateLabel("Status:", 20, 322);
Dim $error = GuiCtrlCreateInput("", 57, 320, 80, 20, $ES_READONLY);
GUISetState(@SW_SHOW);

While 1
  Dim $guiEvent = GUIGetMsg()
  If $guiEvent = $GUI_EVENT_CLOSE Then ExitLoop
  If $guiEvent = $probeStartStop Then
    $probeOnOff = Not($probeOnOff);
    GUICtrlSetData($probeStartStop, ($probeOnOff ? "Stop" : "Start"));
  EndIf
  If $probeOnOff AND TimerDiff($probeWaitTimer) > (5*$thousand) Then
    probeActivate();
    $probeWaitTimer = TimerInit();
  EndIf
WEnd

Func cleanUp()
  TCPShutdown();
  GUIDelete();
EndFunc

Func probeActivate()
  If $probeOnOff Then
    Dim $probeTimer = TimerInit();
    Dim $probe = TCPConnect(TCPNameToIP(GUICtrlRead($probeHost)), 80);
    If @error Then GUICtrlSetData($error, "Service or host not available.")
    TCPCloseSocket($probe)
    Dim $probeTimeTaken = Round(TimerDiff($probeTimer), 1);
    
    Dim $logLine = @HOUR & ":" & @MIN & ":" & @SEC & " - Host: " & $probeTimeTaken;
    Dim $intMaxping = 50;
    If $probeTimeTaken > GUICtrlRead($probeAlertTime) Then
        $logLine &= "<--" & @CRLF;
    Else
        $logLine &= @CRLF;
    EndIf
    
    Dim $log = $error & $logLine & GUICtrlRead($probeView);
    GUICtrlSetData($probeView, $log);
  Else

  EndIf
EndFunc

Func printFile($fileName, $content)
  $file = FileOpen($fileName, $FO_OVERWRITE);
  If $file = -1 Then GUICtrlSetData($error, "Unable to open file.")
  
  FileWrite($file, $content);
  FileClose($file);
EndFunc