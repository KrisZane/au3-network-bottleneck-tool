#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <Array.au3>

Local $resSysmsg;
Local $strList;
Local $strPing;
Local $arrPings[99999];
Local $blnOnoff = False;
Local $intTimeout = 5000;
Local $intPingTimer = TimerInit();

GUICreate("Split Pinger By Kristian B", 350, 350);

$btnStartStop = GUICtrlCreateButton("Start", 130, 320, 80, 20);

GUICtrlCreateLabel("WAN address:", 20, 5);
$resWanhost = GuiCtrlCreateInput("google.com", 20, 25, 140, 20);
GUICtrlCreateLabel("Max Ping For Alert(WAN):", 20, 50);
$resWanhostms = GuiCtrlCreateInput("50", 140, 50, 20, 20);

GUICtrlCreateLabel("LAN address:", 200, 5);
$resLanhost = GuiCtrlCreateInput("10.0.0.94", 200, 25, 140, 20);
GUICtrlCreateLabel("Max Ping For Alert(LAN):", 200, 50);
$resLanhostms = GuiCtrlCreateInput("50", 320, 50, 20, 20);

$resPinglist = GUICtrlCreateEdit("", 20, 80, 300, 200, $ES_AUTOVSCROLL + $WS_VSCROLL + $ES_READONLY)


GUISetState(@SW_SHOW);

$resLogfile = FileOpen("log.txt", 1);
If $resLogfile = -1 Then
    MsgBox(16, "Error", "Unable to open log file.");
    Exit;
EndIf

Func split_ping()
    $intPingTimer = TimerInit();
    If $blnOnoff Then
        $intPingwan = Ping(GUICtrlRead($resWanhost));
        $intPinglan = Ping(GUICtrlRead($resLanhost));
        If @error Then
            MsgBox(16, "Error", "Error number: " & @error & @CRLF & "Consult Manual");
            Exit;
        EndIf
        $strPing = @HOUR & ":" & @MIN & ":" & @SEC & " - Wan: " & $intPingwan & " Lan: " & $intPinglan;
        $intMaxping = 50;
        If $intPingwan > GUICtrlRead($resWanhostms) OR $intPinglan > GUICtrlRead($resLanhostms) OR $intPingwan <= 0 OR $intPinglan <= 0 Then
            $strPing &= "!!!!!!!!!!!" & @CRLF;
        Else
            $strPing &= @CRLF;
        EndIf
        _ArrayAdd($arrPings, $strPing);
        _ArrayReverse($arrPings);
        $strList = _ArrayToString($arrPings);
        _ArrayReverse($arrPings);
        FileWrite($resLogfile, $strPing);
        GUICtrlSetData($resPinglist, $strList);
    Else
        
    EndIf
EndFunc

Func whattorun()
    If TimerDiff($intPingTimer) > $intTimeout AND $blnOnoff Then
        split_ping();
    EndIf
EndFunc

While 1
    $resSysmsg = GUIGetMsg()
    If $resSysmsg = $GUI_EVENT_CLOSE Then ExitLoop
    If $resSysmsg = $btnStartStop Then
        $strStartStop = GUICtrlRead($btnStartStop);
        If $strStartStop == "Start" Then
            GUICtrlSetData($btnStartStop, "Stop");
            $blnOnoff = True;
            GUICtrlSetStyle($resWanhost, $ES_READONLY);
            GUICtrlSetStyle($resLanhost, $ES_READONLY);
            GUICtrlSetStyle($resWanhostms, $ES_READONLY);
            GUICtrlSetStyle($resLanhostms, $ES_READONLY);
        ElseIf $strStartStop == "Stop" Then
            GUICtrlSetData($btnStartStop, "Start");
            $blnOnoff = False;
            GUICtrlSetStyle($resWanhost, $WS_TABSTOP);
            GUICtrlSetStyle($resLanhost, $WS_TABSTOP);
            GUICtrlSetStyle($resWanhostms, $WS_TABSTOP);
            GUICtrlSetStyle($resLanhostms, $WS_TABSTOP);
        EndIf
    EndIf
    whattorun();
WEnd
FileClose($resLogfile);
GUIDelete();