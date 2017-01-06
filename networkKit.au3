#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <Array.au3>
#RequireAdmin

AutoItSetOption("MustDeclareVars", 1);
OnAutoItExitRegister("cleanUp");

Dim $probeOnOff = False;
Dim $probeWaitTimer = TimerInit();
Dim $probeHosts[3];
Dim Const $thousand = 1000;
Dim $thisIp = InetRead("http://www.myexternalip.com/raw");
Dim $ruleEnabled = True;

TCPStartup()
GUICreate("Nexination Networkkit", 350, 350);
GUICtrlCreateTab(0, 0, 352, 351);

GUICtrlCreateLabel("Status:", 20, 322);
Dim $status = GuiCtrlCreateInput("", 57, 320, 80, 20, $ES_READONLY);

GUICtrlCreateTabItem("Latency");
GUICtrlCreateLabel("Host:", 20, 27);
Dim $probeHost = GuiCtrlCreateInput("google.com", 50, 25, 100, 20);
Dim $probeHostAdd = GUICtrlCreateButton("Add", 155, 25, 40, 20);
Dim $probeAlertTime = GuiCtrlCreateInput("50", 300, 25, 20, 20);
Dim $probeHostDisplay = GuiCtrlCreateInput("Host list...", 20, 50, 240, 20, $ES_READONLY);
GUICtrlCreateLabel("Max Timeout:", 233, 27);
Dim $probeStartStop = GUICtrlCreateButton("Start", 130, 80, 80, 20);
Dim $probeView = GUICtrlCreateEdit("", 20, 100, 300, 200, $ES_AUTOVSCROLL + $WS_VSCROLL + $ES_READONLY);

GUICtrlCreateTabItem("Firewall");
GUICtrlCreateLabel("Blocking rule builder", 20, 27);
GUICtrlCreateLabel("Name:", 20, 52);
Dim $firewallRuleName = GuiCtrlCreateInput("aaFW", 70, 50, 100, 20);
GUICtrlCreateLabel("Port list:", 20, 77);
Dim $firewallRulePorts = GuiCtrlCreateInput("6672,61455-61458", 70, 75, 100, 20);
GUICtrlCreateLabel("IP's allow:", 20, 102);
Dim $firewallRuleIps = GUICtrlCreateInput("192.168.1.1,172.16.1.1", 70, 100, 100, 20);
GUICtrlCreateLabel("Protocol:", 20, 127);
Dim $firewallRuleProtocol = GUICtrlCreateCombo("", 70, 125, 100, 20);
GUICtrlSetData($firewallRuleProtocol, "UDP|TCP|ANY", "UDP");
;GUICtrlCreateLabel("Mode:", 20, 152);
;Dim $firewallRuleMode = GUICtrlCreateCombo("", 70, 150, 100, 20);
Dim $firewallOutput = GUICtrlCreateEdit("", 70, 175, 200, 100, $ES_AUTOVSCROLL + $WS_VSCROLL + $ES_READONLY);
;GUICtrlSetData($firewallRuleMode, "allow|block|bypass", "block");
Dim $firewallRuleAdd = GUICtrlCreateButton("Create rules", 180, 50, 100, 20);
;Dim $firewallRuleUpdate = GUICtrlCreateButton("Update rule", 180, 75, 100, 20);
Dim $firewallRuleRemove = GUICtrlCreateButton("Remove rules", 180, 75, 100, 20);
Dim $firewallRuleView = GUICtrlCreateButton("View rules", 180, 100, 100, 20);
Dim $firewallRuleEnableDisable = GUICtrlCreateButton("Enable/Disable", 180, 150, 100, 20);

GUICtrlCreateTabItem("Info");
GUICtrlCreateLabel("Your IP:", 5, 27);
GuiCtrlCreateInput(BinaryToString($thisIp), 50, 25, 100, 20, $ES_READONLY);

GUICtrlCreateTabItem("");

GUISetState(@SW_SHOW);

Func cleanUp()
  TCPShutdown();
  GUIDelete();
EndFunc

Func probeScan()
  Dim $logLine = @HOUR & ":" & @MIN & ":" & @SEC & " - ";
  Dim $probeOverTime = false;
  
  For $hostName In $probeHosts
    If $hostName <> "" Then
      Dim $probeTimer = TimerInit();
      Dim $probe = TCPConnect(TCPNameToIP($hostName), 80);
      If @error Then GUICtrlSetData($status, "Service or host not available.");
      TCPCloseSocket($probe);
      Dim $probeTimeTaken = Round(TimerDiff($probeTimer), 1);
      
      If $probeTimeTaken > GUICtrlRead($probeAlertTime) Then $probeOverTime = true;
      
      $logLine &= StringRight($hostName, 5) & ":" & $probeTimeTaken & " ";
    EndIf
  Next
  
  If $probeOverTime Then
      $logLine &= "<--" & @CRLF;
  Else
      $logLine &= @CRLF;
  EndIf
  
  Dim $log = $logLine & GUICtrlRead($probeView);
  GUICtrlSetData($probeView, $log);
EndFunc

Func printFile($fileName, $content)
  $file = FileOpen($fileName, $FO_OVERWRITE);
  If $file = -1 Then GUICtrlSetData($status, "Unable to open file.")
  
  FileWrite($file, $content);
  FileClose($file);
EndFunc

Func firewallCreateRule($name, $ips, $ports, $protocol);, $action)
  Dim $ipList = StringSplit($ips, ",", $STR_NOCOUNT);
  Dim $ipListString = '0.0.0.0-';
  
  _ArraySort($ipList);
  For $ip IN $ipList
    Dim $inter = _ipToInt($ip);
    $ipListString &= _intToIp($inter-1) & ',';
    $ipListString &= _intToIp($inter+1) & '-';
  Next
  
  $ipListString &= '255.255.255.255';
  
  Dim $commandIn = 'netsh advfirewall firewall add rule name="' & $name & '" protocol=' & $protocol & ' dir=in remoteport=' & $ports  & ' remoteip=' & $ipListString & ' action=block'; & $action
  Dim $commandOut = 'netsh advfirewall firewall add rule name="' & $name & '" protocol=' & $protocol & ' dir=out remoteport=' & $ports & ' remoteip=' & $ipListString & ' action=block'; & $action
  
  Dim $pidIn = Run(@ComSpec & " /c " & $commandIn, "", @SW_HIDE);
  Dim $pidOut = Run(@ComSpec & " /c " & $commandOut, "", @SW_HIDE);
  
  GUICtrlSetData($firewallOutput, 'Rules created!' & $ipListString);
EndFunc

;Func firewallUpdateRule($name, $ips, $ports, $protocol, $action)
  ;netsh advfirewall firewall set rule name="aaFW" new remoteip=0.0.0.0-192.168.1.0,192.168.1.2-172.16.1.0,172.16.1.2-255.255.255.255
;EndFunc
Func firewallDeleteRule($name)
  Dim $command = 'netsh advfirewall firewall delete rule name="' & $name & '"';
  Dim $pid = Run(@ComSpec & " /c " & $command, "", @SW_HIDE, $STDOUT_CHILD);
  
  firewallOutputDump($pid);
EndFunc

Func firewallGetRule($name)
  Dim $command = 'netsh advfirewall firewall show rule name="' & $name & '"';
  Dim $pid = Run(@ComSpec & " /c " & $command, "", @SW_HIDE, $STDOUT_CHILD);
  
  firewallOutputDump($pid);
EndFunc

Func firewallOutputDump($pid)
  ProcessWaitClose($pid);
  Dim $output = StdoutRead($pid);

  GUICtrlSetData($firewallOutput, $output);
EndFunc

Func firewallEnableDisableRule($name)
  Dim $enabled = 'no';
  If $ruleEnabled Then
    $enabled = 'yes';
  EndIf
  $ruleEnabled = NOT($ruleEnabled);
  
  Dim $command = 'netsh advfirewall firewall set rule name="' & $name & '" new enable=' & $enabled
  Dim $iPID = Run(@ComSpec & " /c " & $command, "", @SW_HIDE);
  
  GUICtrlSetData($status, ($ruleEnabled ? 'Disabled rule' : 'Enabled rule'));
EndFunc

Func buildIpArray($ips)
  Dim $ipList = StringSplit($ips, ',');
EndFunc

Func _intToIp($ip)
    Return Number(BinaryMid($ip, 4, 1)) & "." & Number(BinaryMid($ip, 3, 1)) & "." & Number(BinaryMid($ip, 2, 1)) & "." & Number(BinaryMid($ip, 1, 1));
EndFunc

Func _ipToInt($ip)
    Dim $ipSplit = StringSplit($ip, ".");
    ReDim $ipSplit[5];
    Return Dec(Hex($ipSplit[1], 2) & Hex($ipSplit[2], 2) & Hex($ipSplit[3], 2) & Hex($ipSplit[4], 2))
EndFunc

While 1
  Dim $guiEvent = GUIGetMsg()
  If $guiEvent = $GUI_EVENT_CLOSE Then ExitLoop
  If $guiEvent = $probeStartStop Then
    $probeOnOff = Not($probeOnOff);
    GUICtrlSetData($probeStartStop, ($probeOnOff ? "Stop" : "Start"));
  ElseIf $guiEvent = $probeHostAdd Then
    _ArrayPush($probeHosts, GUICtrlRead($probeHost))
    GUICtrlSetData($probeHostDisplay, _ArrayToString($probeHosts));
  ElseIf $guiEvent = $firewallRuleEnableDisable Then
    firewallEnableDisableRule(GUICtrlRead($firewallRuleName));
  ;ElseIf $guiEvent = $firewallRuleUpdate Then
    ;firewallUpdateRule(GUICtrlRead($firewallRuleName), GUICtrlRead($firewallRuleIps), GUICtrlRead($firewallRulePorts), GUICtrlRead($firewallRuleProtocol), GUICtrlRead($firewallRuleMode));
  ElseIf $guiEvent = $firewallRuleAdd Then
    firewallCreateRule(GUICtrlRead($firewallRuleName), GUICtrlRead($firewallRuleIps), GUICtrlRead($firewallRulePorts), GUICtrlRead($firewallRuleProtocol));, GUICtrlRead($firewallRuleMode));
  ElseIf $guiEvent = $firewallRuleRemove Then
    firewallDeleteRule(GUICtrlRead($firewallRuleName));
  ElseIf $guiEvent = $firewallRuleView Then
    firewallGetRule(GUICtrlRead($firewallRuleName));
  EndIf
  If $probeOnOff AND TimerDiff($probeWaitTimer) > (5*$thousand) Then
    probeScan();
    $probeWaitTimer = TimerInit();
  EndIf
WEnd