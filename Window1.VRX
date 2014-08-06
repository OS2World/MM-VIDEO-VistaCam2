/*:VRX         Main
*/
/*  Main
*/
Main:
/*  Process the arguments.
    Get the parent window.
*/
    parse source . calledAs .
    parent = ""
    argCount = arg()
    argOff = 0
    if( calledAs \= "COMMAND" )then do
        if argCount >= 1 then do
            parent = arg(1)
            argCount = argCount - 1
            argOff = 1
        end
    end; else do
        call VROptions 'ImplicitNames'
    end
    InitArgs.0 = argCount
    if( argCount > 0 )then do i = 1 to argCount
        InitArgs.i = arg( i + argOff )
    end
    drop calledAs argCount argOff

/*  Load the windows
*/
    call VRInit
    parse source . . spec
    _VREPrimaryWindowPath = ,
        VRParseFileName( spec, "dpn" ) || ".VRW"
    _VREPrimaryWindow = ,
        VRLoad( parent, _VREPrimaryWindowPath )
    drop parent spec
    if( _VREPrimaryWindow == "" )then do
        call VRMessage "", "Cannot load window:" VRError(), ,
            "Error!"
        _VREReturnValue = 32000
        signal _VRELeaveMain
    end

/*  Process events
*/
    call Init
    signal on halt
    do while( \ VRGet( _VREPrimaryWindow, "Shutdown" ) )
        _VREEvent = VREvent()
        interpret _VREEvent
    end
_VREHalt:
    _VREReturnValue = Fini()
    call VRDestroy _VREPrimaryWindow
_VRELeaveMain:
    call VRFini
exit _VREReturnValue

VRLoadSecondary:
    __vrlsWait = abbrev( 'WAIT', translate(arg(2)), 1 )
    if __vrlsWait then do
        call VRFlush
    end
    __vrlsHWnd = VRLoad( VRWindow(), VRWindowPath(), arg(1) )
    if __vrlsHWnd = '' then signal __vrlsDone
    if __vrlsWait \= 1 then signal __vrlsDone
    call VRSet __vrlsHWnd, 'WindowMode', 'Modal' 
    __vrlsTmp = __vrlsWindows.0
    if( DataType(__vrlsTmp) \= 'NUM' ) then do
        __vrlsTmp = 1
    end
    else do
        __vrlsTmp = __vrlsTmp + 1
    end
    __vrlsWindows.__vrlsTmp = VRWindow( __vrlsHWnd )
    __vrlsWindows.0 = __vrlsTmp
    do while( VRIsValidObject( VRWindow() ) = 1 )
        __vrlsEvent = VREvent()
        interpret __vrlsEvent
    end
    __vrlsTmp = __vrlsWindows.0
    __vrlsWindows.0 = __vrlsTmp - 1
    call VRWindow __vrlsWindows.__vrlsTmp 
    __vrlsHWnd = ''
__vrlsDone:
return __vrlsHWnd

/*:VRX         BuildCmd
*/
BuildCmd: Procedure Expose Site_URL CamLocs.INI;
/* -------------------------						*/
/* Bilde Cmd for Camera-Call:					*/
/* -------------------------						*/

QUERY = space( arg(1),0 );	/* eliminate Spaces			*/

/* Den String: 'username:passwort' kann man erzeugen bei		*/
/* http://www.zworks.de/Cre_AuthHeader.php				*/

/* Bilde Login:     */

LocName = VRGet("Combo_LocSelect","Value");

Login_Name = SysINI( CamLocs.INI, LocName, "Lginnm");   /* Abfrage auf "ERROR:" ?       */
Login_Pass = SysINI( CamLocs.INI, LocName, "Lginpw");   /* bei Allnet nicht erforderlich ... geht trotzdem ... aber nicht MOVE!  */

if Login_Name = "ERROR:" then
   Call XSay "No login-name / password specified - camera-access may probably fail";

LogIn = b64Encode(Login_Name":"Login_Pass);

/* ++
LogIn = "YWRtaW46YnJheiw2OQ=="; /* admin:braz,69		       */
LogIn = "Z3Vlc3Q6Z3Vlc3Q=";     /* guest:guest			*/
++ */

return ,
 "GET /" || QUERY ||" HTTP/1.1"   || "0D0A"x||    ,
 "HOST:" || Site_URL              || "0D0A"x||    ,
 "Authorization: Basic " || LogIn || "0D0A"x||    ,
 "0D0A"x;


/*:VRX         CB_PanTilt_Click
*/
CB_PanTilt_Click: 

ok = VRSet("GB_Cam_PanTilt","Visible", VRGet("CB_PanTilt","Set") );

return 0;

/*:VRX         Check_CamAccess
*/
Check_CamAccess: Procedure

Cam_Model = VRGet("Combo_Camselect", "Value");

if \(Cam_Model > "<") then do
   ok = VRMessage( VRWindow(), "Please select a camera" );
   RETURN 0;
end;

if \(VRGet("EF_IPAddr", "Value") > "0") then do
   ok = VRMessage( VRWindow(), "Please specify address of camera" );
   RETURN 0;
end;

return Cam_Model;   /* ok   */

/*:VRX         Combo_Camdefs_Click
*/
Combo_Camdefs_Click: 

/* VXError - Index immer 0 !!   */
return 0;

Index = VRInfo("Index");

say "Index="Index"!";

return 0;

/*:VRX         Combo_Camdefs_LostFocus
*/
Combo_Camdefs_LostFocus: 

Cam_Model = VRGet("Combo_Camdefs", "Value" );

ok = VRSet("CB_PanTilt", "Set", (SysINI( Cam_Model".ACD", "Feature", "PanTilt") = "1") );

Val = SysINI( Cam_Model".ACD", "Command", "FetchImg");             if Val = "ERROR:" then Val = "";
ok = VRSet("EF_CmdFetchImg",   "Value", Val );

Val = SysINI( Cam_Model".ACD", "Command", "FetchVideo");           if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_CmdFetchVideo","Value", Val );

Val = SysINI( Cam_Model".ACD", "Command", "VPlayer");              if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_VPlayer","Value", Val );

Val = SysINI( Cam_Model".ACD", "Command", "MovePreset");           if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_CmdMovePreset","Value", Val );

Val = SysINI( Cam_Model".ACD", "Command", "MoveLeft");             if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_CmdMoveLeft",  "Value", Val );

Val = SysINI( Cam_Model".ACD", "Command", "MoveRight");            if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_CmdMoveRight", "Value", Val);

Val = SysINI( Cam_Model".ACD", "Command", "MoveDown");             if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_CmdMoveDown",  "Value", Val );

Val = SysINI( Cam_Model".ACD", "Command", "MoveUp");               if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_CmdMoveUp",    "Value", Val );

Val = SysINI( Cam_Model".ACD", "Rules", "PSetAssgn"); if Val = "ERROR:" then Val = "1";    /* Default  */
ok = VRSet("RB_PSetAssgn" || Val,  "Set", 1 );


/* --------------           */
/* Video-Section:           */
/* --------------           */

Val = SysINI( Cam_Model".ACD", "Command", "SetBright");          if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_SetBright", "Value", Val);
Val = SysINI( Cam_Model".ACD", "Command", "BrightLo");           if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_ValBrightLo", "Value", Val);
Val = SysINI( Cam_Model".ACD", "Command", "BrightHi");           if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_ValBrightHi", "Value", Val);

Val = SysINI( Cam_Model".ACD", "Command", "SetContr");           if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_SetContr", "Value", Val);
Val = SysINI( Cam_Model".ACD", "Command", "ContrLo");            if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_ValContrLo", "Value", Val);
Val = SysINI( Cam_Model".ACD", "Command", "ContrHi");            if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_ValContrHi", "Value", Val);

Val = SysINI( Cam_Model".ACD", "Command", "50Hz");               if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_Set50Hz", "Value", Val);
Val = SysINI( Cam_Model".ACD", "Command", "60Hz");               if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_Set60Hz", "Value", Val);
Val = SysINI( Cam_Model".ACD", "Command", "Outdoor");            if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_SetOutdoor", "Value", Val);


Call CB_PanTilt_Click;

return 0;

/*:VRX         Combo_Camselect_Change
*/
Combo_Camselect_Change: 

Cam_Model = VRGet("Combo_Camselect", "Value" );

if left(Cam_Model,1) <= "<" then RETURN 0;

LocName = VRGet("Combo_LocSelect", "Value");
Val = SysINI(LOC_File, LocName, "CamName");

if Val <> Cam_Model then do
   ok = VRMessage( VRWindow(), "The Camera '"Cam_Model"' is not defined for Location '"LocName"'",Val,"E");
   RETURN -1;
end;

ok = VRSet("DT_PanTilt", "Visible", (SysINI( Cam_Model".ACD", "Feature", "PanTilt") <> "1") );
ok = VRSet("GB_PanTilt", "Visible", (SysINI( Cam_Model".ACD", "Feature", "PanTilt")  = "1") );

/* ----------------------------------   */
/* Brightness gem. Camera darstellen:   */
/* ----------------------------------   */
SetBright = SysINI( Cam_Model".ACD", "Command", "SetBright");
if SetBright = "ERROR:" then do
   Call XSay "Brightness-Settings disabled because '"Cam_Model"' has no corresponding command defined";
   ok = VRSet("PB_SetBright", "Enabled", 0 );
   ok = VRSet("SL_Bright",    "Enabled", 0 );
end;
else;do
   Call XSay "Brightness-Settings enabled for camera" Cam_Model;
   ok = VRSet("PB_SetBright", "Enabled", 1 );
   ok = VRSet("SL_Bright",    "Enabled", 1 );
end;

/* ----------------------------------   */
/* Contrast gem. Camera darstellen:     */
/* ----------------------------------   */
SetContr = SysINI( Cam_Model".ACD", "Command", "SetContr");
if SetContr = "ERROR:" then do
   Call XSay "Contrast-Settings disabled because '"Cam_Model"' has no corresponding command defined";
   ok = VRSet("PB_SetContr", "Enabled", 0 );
   ok = VRSet("SL_Contr",    "Enabled", 0 );
end;
else;do
   Call XSay "Contrast-Settings enabled for camera" Cam_Model;
   ok = VRSet("PB_SetContr", "Enabled", 1 );
   ok = VRSet("SL_Contr",    "Enabled", 1 );
end;

/* ------------------------------------ */
/* Video-Button gem. Camera darstellen: */
/* ------------------------------------ */
VPlayer = SysINI( Cam_Model".ACD", "Command", "VPlayer");
if VPlayer = "ERROR:" then do
   Call XSay "Video disabled because '"Cam_Model"' has no video-player defined";
   ok = VRSet("PB_GetVideo", "Enabled", 0 );
end;
else;do
   Call XSay "Video enabled for camera" Cam_Model;
   ok = VRSet("PB_GetVideo", "Enabled", 1 );
end;

return 0;

/*:VRX         Combo_LocCams_Click
*/
Combo_LocCams_Click: 

/* VXError - Index immer 0 !!   */
return 0;

Index = VRInfo("Index");

say "Index="Index"!";

return 0;

/*:VRX         Combo_Locdefs_Change
*/
Combo_Locdefs_Change: 

Val = VRGet("Combo_Locdefs","Userdata");

if \Datatype(Val,"W") then Val = 0;

Val = Val +1;

ok = VRSet("Combo_Locdefs","Userdata", Val);

if Val > 3 then 
   ok = VRSet("PB_DefLoc_Set", "Caption", "set" );

return 0;

/*:VRX         Combo_Locdefs_LostFocus
*/
Combo_Locdefs_LostFocus: 

ok = VRGet("Combo_Locdefs","Userdata", 0);      /* Reset Counter    */

/* Einlesen Werte der ausgewÑhlten Location (aus LOC_File):         */

LocName = VRGet("Combo_Locdefs", "Value" );

if left(LocName,1) = "<"    ,
 | LocName         = "" then do
   ok = VRMessage(VRWindow(), "You must specify a location (Select one from List or type in a new name)" );
   RETURN -1;
end;

Val = SysINI( LOC_File, LocName, "CamName");          
if Val = "ERROR:" then Val = "";
else;ok = VRSet("Combo_LocCams",   "Value", Val );    /* beware '<select>'-Text   */

Val = SysINI( LOC_File, LocName, "Domain");
if Val = "ERROR:" then Val = "";
else;ok  = VRSet("EF_LocDomain","Value", Val );       /* beware '<e.g.>'-Text     */

Val = SysINI( LOC_File, LocName, "Portno");           if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_LocPortno","Value", Val );

Val = SysINI( LOC_File, LocName, "Lginnm");           if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_LoginName","Value", Val );
Val = SysINI( LOC_File, LocName, "Lginpw");           if Val = "ERROR:" then Val = "";
ok  = VRSet("EF_LoginPass","Value", Val );

Val = SysINI( LOC_File, LocName, "PSetName1"); if Val = "ERROR:" then Val = ""; ok = VRSet("EF_LocPSetName1",  "Value", Val );
Val = SysINI( LOC_File, LocName, "PSetName2"); if Val = "ERROR:" then Val = ""; ok = VRSet("EF_LocPSetName2",  "Value", Val );
Val = SysINI( LOC_File, LocName, "PSetName3"); if Val = "ERROR:" then Val = ""; ok = VRSet("EF_LocPSetName3",  "Value", Val );
Val = SysINI( LOC_File, LocName, "PSetName4"); if Val = "ERROR:" then Val = ""; ok = VRSet("EF_LocPSetName4",  "Value", Val );
Val = SysINI( LOC_File, LocName, "PSetName5"); if Val = "ERROR:" then Val = ""; ok = VRSet("EF_LocPSetName5",  "Value", Val );
Val = SysINI( LOC_File, LocName, "PSetName6"); if Val = "ERROR:" then Val = ""; ok = VRSet("EF_LocPSetName6",  "Value", Val );
Val = SysINI( LOC_File, LocName, "PSetName7"); if Val = "ERROR:" then Val = ""; ok = VRSet("EF_LocPSetName7",  "Value", Val );
Val = SysINI( LOC_File, LocName, "PSetName8"); if Val = "ERROR:" then Val = ""; ok = VRSet("EF_LocPSetName8",  "Value", Val );
Val = SysINI( LOC_File, LocName, "PSetName9"); if Val = "ERROR:" then Val = ""; ok = VRSet("EF_LocPSetName9",  "Value", Val );

ok = VRSet("GB_LocProps","Visible", 1);

return 0;

/*:VRX         Combo_LocSelect_Change
*/
Combo_LocSelect_Change: 

LocName = VRGet("Combo_LocSelect", "Value");

CamName = SysINI( LOC_File, LocName, "CamName");
if CamName = "ERROR:" then do
   ok = VRMessage( VRWindow(), "No Camera defined for this Location",,"E");
   RETURN -1;
end;

ok = VRSet("Combo_CamSelect", "Value", CamName);


ok = VRSet("EF_IPAddr", "Value",    ,
            SysINI( LOC_File, LocName, "Domain") || ":" ||  ,
            SysINI( LOC_File, LocName, "Portno")            ,
          );

return 0;

/*:VRX         Fini
*/
Fini:
    window = VRWindow()
    call VRSet window, "Visible", 0
    drop window
return 0

/*:VRX         Halt
*/
Halt:
    signal _VREHalt
return

/*:VRX         Init
*/
Init:

YGlob.YProg = "VistaCam";
INIFile     = YGlob.YProg || ".INI";

ACD_File    = "<cammodel>.ACD";
LOC_File    = "CAMLOCS.INI";

ok = SysINI( LOC_File, "ALL:", "Locs." );
YFirstTime = ( Locs.0 = 0 );

CrLf = "0D0A"x;

nok = RxFuncAdd("SysLoadFuncs",  "RexxUtil", "SysLoadFuncs") ;rc = SysLoadFuncs();
nok = RxFuncAdd("RxExtra",       "RxExtras", "RxExtra")      ;rc = RxExtra("LOAD");
nok = RxFuncAdd('B64encode','md5rx','B64encode');	/* in md5rx.dll		*/
nok = RxFuncAdd('B64decode','md5rx','B64decode');	/* in md5rx.dll		*/

rc = RxFuncAdd("SockLoadFuncs","RxSock","SockLoadFuncs")
rc = SockLoadFuncs(bypass_copyright);

if(1) then ok = VRRedirectStdIO("OFF"); /* Makes console invisible  */

Heute = date("S");
Call XSay  left(Heute,4) || "-" || substr(Heute,5,2) || "-"  || right(Heute,2) "is today's date";

ok = SysFileTree(YGlob.YProg".exe","ExeDate.","F");
Call XSay "Welcome to "YGlob.YProg", compiled on "word(ExeDate.1,1)" at "word(ExeDate.1,2)".";drop ExeDate.;

/* ----------------             */
/* INI wiederholen:             */
/* ----------------             */
Val = SysINI( INIFile, "Current", "Location" ); if Val = "ERROR:" then Val = "";
ok = VRSet("Combo_LocSelect", "Value", Val);

Val = SysINI( INIFile, "Current", "Camera" ); if Val = "ERROR:" then Val = "";
ok = VRSet("Combo_CamSelect", "Value", Val);

if YFirstTime then do
   ok = VRFlush("Change","Combo_LocSelect");
   ok = VRFlush("Change","Combo_CamSelect");
end;

ok = ZFill_CamModels("Combo_Camselect");

/* Window preloaden:        */
ok = VRLoadSecondary("WIN_Wait");

ok = VRSet("DT_PanTilt", "Visible", 0 );    /* 'No PanTilt'             */

ok = VRSet("DT_Preset",  "Visible", 0 );    /* anfÑnglich unsichtbar    */

/* ----------------------------  */
/* Init fÅr Resize Window-Frame: */
/* ----------------------------  */
ok = VRSet("GB_Image", "Userdata", VRGet("GB_Image", "Width") VRGet("GB_Image", "Height") );

/* ----------------             */
/* Resize Images:               */
/* ----------------             */
ok = VRSet("PICT_Img",  "Width",  220 * VRMethod("Screen","PixelsToTwips",1) );
ok = VRSet("PICT_Img",  "Height", 192 * VRMethod("Screen","PixelsToTwips",1) );

ok = ZCre_PSet();

ok = ZFill_CamLocs("Combo_LocSelect");

if YFirstTime then do
   ok = VRMessage( VRWindow(), "At first you must define the remote location of the camera" ); 
   ok = VRLoadSecondary("WIN_DefLoc", "WAIT");
   ok = VRSet("EF_IPAddr", "Value", SysINI( LOC_File, LocName, "Domain") );
end;

    window = VRWindow()
    call VRMethod window, "CenterWindow"
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window
return

/* ------------------------------       */
/* XSay: Neu: 'REPL'-Param              */
/*       fÅr im Stand lfd. Zeilen       */
/* ------------------------------       */
XSay: procedure
What = arg(1);
Aux  = arg(2);  /* erklÑrender Text, nur wenn What <> Leer   */
Mode = arg(3);  /* "REPL" | ""          */
LB   = arg(4);  /* alternative ListBox  */

if strip(What) = "" | What="TOF" | What="BOF" then return;

if Aux <> "" then
   What = Aux||What;

What = time()"."left(time("LONG"),2)"> "What;

if LB = "" | (1) then
   LBObj = "LB_XSay";
else;
   LBObj = LB;

if Mode= "REPL" then do
   ok = VRSet( LBObj, "Painting", 0);
   Indx = VRGet( LBObj, "Count");
   ok = VRMethod( LBObj, "Delete", Indx);
end;

/* ++ debug: ++ */
if (0) then say What;

ok = VRMethod( LBObj, "Addstring", What);
ok = VRSet( LBObj, "Selected", VRGet( LBObj, "Count"));
ok = VRSet( LBObj, "Painting", 1);
return 0;
/*:VRX         LB_XSay_DoubleClick
*/
LB_XSay_DoubleClick: Procedure;

Buttons.1 = "OK";
Buttons.2 = "Help";
Buttons.0 =  2;

ok = VRMethod("LB_XSay", "GetSelectedList", "indexes.");

ok = VRMessage( VRWindow(), VRMethod("LB_XSay", "GetString", indexes.1),    ,
                "Message in the Log Window", "I", "Buttons.", 2, 1          ,
              );

if ok = 2 then do
   ok = VRMethod( "LB_XSay", "InvokeHelp" );
end;

return

/*:VRX         MMExit_Click
*/
MMExit_Click: 
Call Quit;
return 0;

/*:VRX         MMSett_Cam_Click
*/
MMSett_Cam_Click: 
Call PB_DefCam_Click;
return 0;

/*:VRX         MMSett_Loc_Click
*/
MMSett_Loc_Click: 
Call PB_DefLoc_Click;
return 0;

/*:VRX         PB_Camdef_Canc_Click
*/
PB_Camdef_Canc_Click: 
Call WIN_Defcam_Close;
return 0;

/*:VRX         PB_Camdef_OK_Click
*/
PB_Camdef_OK_Click: 

Cam_Model = VRGet("Combo_Camdefs", "Value" );
if Cam_Model = "" then do
   ok = VRMessage( VRWindow(), "A Camera Model must be specified" );
   RETURN -1;
end;

ok = SysINI( Cam_Model".ACD", "Feature", "PanTilt",     VRGet("CB_PanTilt", "Set" ) );

if VRGet("RB_PSetAssgn1","Set") then PSetAssgn=1;
if VRGet("RB_PSetAssgn2","Set") then PSetAssgn=2;
if VRGet("RB_PSetAssgn3","Set") then PSetAssgn=3;
if VRGet("RB_PSetAssgn9","Set") then PSetAssgn=9;

ok = SysINI( Cam_Model".ACD", "Rules", "PSetAssgn", PSetAssgn );   /* No. of Assignment-Rule       */

ok = SysINI( Cam_Model".ACD", "Command", "FetchImg" ,   VRGet("EF_CmdFetchImg",   "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "FetchVideo",  VRGet("EF_CmdFetchVideo", "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "VPlayer",     VRGet("EF_VPlayer",       "Value" ) );

/* ------------------       */
/* Pan-/Tilt-Section:       */
/* ------------------       */
ok = SysINI( Cam_Model".ACD", "Command", "MovePreset",  VRGet("EF_CmdMovePreset", "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "MoveLeft",    VRGet("EF_CmdMoveLeft",   "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "MoveRight",   VRGet("EF_CmdMoveRight",  "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "MoveDown",    VRGet("EF_CmdMoveDown",   "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "MoveUp",      VRGet("EF_CmdMoveUp",     "Value" ) );

/* --------------           */
/* Video-Section:           */
/* --------------           */

ok = SysINI( Cam_Model".ACD", "Command", "SetBright",  VRGet("EF_SetBright",   "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "BrightLo",   VRGet("EF_ValBrightLo", "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "BrightHi",   VRGet("EF_ValBrightHi", "Value" ) );

ok = SysINI( Cam_Model".ACD", "Command", "SetContr",   VRGet("EF_SetContr",    "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "ContrLo",    VRGet("EF_ValContrLo",  "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "ContrHi",    VRGet("EF_ValContrHi",  "Value" ) );

ok = SysINI( Cam_Model".ACD", "Command", "50Hz",       VRGet("EF_Set50Hz",    "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "60Hz",       VRGet("EF_Set60Hz",    "Value" ) );
ok = SysINI( Cam_Model".ACD", "Command", "Outdoor",    VRGet("EF_SetOutdoor", "Value" ) );

Call WIN_Defcam_Close;

return 0;
/*:VRX         PB_DefCam_Click
*/
PB_DefCam_Click: 
ok = VRLoadSecondary("WIN_DefCam", "WAIT");
return 0;

/*:VRX         PB_Defcam_Set_Click
*/
PB_Defcam_Set_Click: 
ok = VRSet("NB_1", "Visible", 1);

return

/*:VRX         PB_DefLoc_Click
*/
PB_DefLoc_Click: 
ok = VRLoadSecondary("WIN_DefLoc", "WAIT");
return 0;

/*:VRX         PB_Defloc_Set_Click
*/
PB_Defloc_Set_Click: 
nop; /* alles passiert in ...   */
return

/*:VRX         PB_Exit_Click
*/
PB_Exit_Click: 

if VRInfo("AltPressed") = 1 then do
   ok =  VRRedirectStdIO("ON");  /* Show console!     */
   say "Console made visible by explicit request!";
   return;
end;

if VRInfo("ShiftPressed") = 1 then do
   ok =  VRRedirectStdIO("OFF");  /* Make Show console invisibl!     */
   Call Xsay "Console made invisible by explicit request!";
   return;
end;

if VRInfo("CtrlPressed") = 1 then do
   !YSay = 1;  /* make debugging-info visible     */
   Call XSay "debugging-info made visible by explicit request!";
   return;
end;

Call Quit;

return 0;

/*:VRX         PB_GetImg_Click
*/
PB_GetImg_Click: 

QIs_Video = ( arg(1) = "VID" );     /* Video-Stream?    */

Cam_Model = Check_CamAccess();

if \(Cam_Model > "0") then RETURN;

ACD_File = Cam_Model".ACD";

ok = VRSet("PICT_Img", "PicturePath", "" );
ok = VRSet("PICT_Img", "Painting", 1 );

if ( QIs_Video ) then What = "video-stream"; else; What = "image";

ok = ZSet_Wait("On","Please wait for "What" being fetched");

if VRGet("SPIN_Preset", "Value") <> "none" then do
   Call ZMove_Cam ACD_File;
end;

if ( QIs_Video ) then do
   /* ---------------------------------------              */
   /* is Video: Åbergeben URL an Videoplayer:              */
   /* ---------------------------------------              */
   QUERY = SysINI( ACD_File, "Command", "FetchVideo" );
   QUERY = strip(QUERY,"L","/");   /* strip leading slash  */

   VPlayer = SysINI( ACD_File, "Command", "VPlayer" );

   LocName = VRGet("Combo_LocSelect","Value");

   Login_Name = SysINI( CamLocs.INI, LocName, "Lginnm");   /* Abfrage auf "ERROR:" ?       */
   Login_Pass = SysINI( CamLocs.INI, LocName, "Lginpw");   /* bei Allnet nicht erforderlich ... geht trotzdem ...   */

   URL = "http://" || Login_Name":"Login_Pass"@" || VRGet("EF_IPAddr", "Value") || "/" || QUERY;
   Call XSay "->"URL;

   PlayWindow = "Video from Camera";

   address cmd 'Start "'PlayWindow'" /C /F /WIN /I 'VPlayer' 'URL;

   ok = ZSet_Wait("Off");
   RETURN 0;
   /* --- Ende Video ----------------                      */
end;
else;do
   QUERY = SysINI( ACD_File, "Command", "FetchImg" );
   What = "image";
end;

if QUERY = "ERROR:" then do
   ok = VRMessage( VRWindow(), "No command defined for fetching the" What, "ACD_File="ACD_File, "E" );
   ok = ZSet_Wait("OFF");
   if Datatype(sock,"W") then
      nok = SockSoClose(sock);	/* closing the socket		    */
   RETURN -1;
end;

QUERY = strip(QUERY,"L","/");   /* strip leading slash              */

ret = TalkToCam( QUERY );
if ret < 0 then do
   Call XSay "No "What" retrieved due to connection-errors";
   ok = ZSet_Wait("Off");
   RETURN -1;
end;


/* +++
   say left("",69,"-");
   say "==> HTTP_Ans:"
   say HTTP_Ans;
   ok = SysFileDelete("$$HTTP_Ans");
   ok = CharOut("$$HTTP_Ans",HTTP_Ans);
   ok = stream("$$HTTP_Ans","c","close");
   nok = SockSoClose(sock);	/* closing the socket			*/
   RETURN 0;
+++ */


/* Image verarbeiten:		*/

HTTP_Ans = -1;
HTTP_Kum = "";
do i = 1 by 1 while HTTP_Ans <> ""
   nok = SockRecv(sock,"HTTP_Ans",512);		/* Teil von Mediafile holen	*/

   /* Respone-Header auswerten:     */
   if i = 1 then do
      say "HTTP-Response-Header="HTTP_Ans;
      HTTP_Retcode = word(HTTP_Ans,2);
      if HTTP_Retcode = "200" then NOP;
      else;do
         if HTTP_Retcode = "401" then
            Call XSay "Unauthorized - camera needs a valid login with username + password";

         ok = beep(333,666);
         ok = ZSet_Wait("Off");
         nok = SockSoClose(sock);	/* closing the socket		      */
         RETURN -1;
      end;
   end;
   HTTP_Kum = HTTP_Kum || HTTP_Ans;
end;

Call XSay "received image has length="length(HTTP_Kum)" (including headers)";

ok = SysFileDelete("$$HTTP_Kum");
ok = CharOut("$$HTTP_Kum",HTTP_Kum);
ok = stream("$$HTTP_Kum","c","close");

nok = SockSoClose(sock);	/* closing the socket			       */

/* Nun aus HTTP_Kum das Image-File holen (Header wegstrippen):		*/
JPG_File = "$$image.jpg";
ok = SysFileDelete(JPG_File);
Posi = pos("0D0A0D0A"x, HTTP_Kum );

if Posi > 0 then do
   ok = VRSet( VRWindow(),     "Painting", 0 );

   ok = CharOut(JPG_File, right(HTTP_Kum, length(HTTP_Kum)-(Posi+2+1)) );	/* +1 fÅr "0A"x ??	*/
   ok = stream(JPG_File,"c","close");

   posi = pos(".",JPG_File);
   dir = strip(directory(),"T","\") || "\";
   BMP_File =  dir || left(JPG_File,posi) || "bmp";

   cmd = "gbmsize "JPG_File BMP_File;
   cmd;

   xx = ZGet_ImgSize( BMP_File );
   X_Size = word(xx,1) +1;
   Y_Size = word(xx,2) +1;
   ok = VRSet("GB_Image", "Width",  (X_Size+6)*VRmethod("SCREEN", PixelsToTwips, 1));
   ok = VRSet("GB_Image", "Height", (Y_Size+16)*VRmethod("SCREEN", PixelsToTwips, 1));
   ok = VRSet("PICT_Img", "Width",  (X_Size)*VRmethod("SCREEN", PixelsToTwips, 1));
   ok = VRSet("PICT_Img", "Height", (Y_Size)*VRmethod("SCREEN", PixelsToTwips, 1));

   ok = VRSet("PICT_Img", "PicturePath", BMP_File );
   ok = VRSet("PICT_Img", "Painting", 1 );

   ok = VRSet("PICT_Img", "Top", 126 );
   ok = VRSet("PICT_Img", "Left", 26 );

   /* ------------------------------       */
   /* Fensterbreite, -Hîhe anpassen:       */
   /* ------------------------------       */

   Delta_Width  = VRGet("GB_Image", "Width" )  - word( VRGet("GB_Image", "Userdata"),1 );
   Delta_Height = VRGet("GB_Image", "Height" ) - word( VRGet("GB_Image", "Userdata"),2 );

   ok = VRSet( VRWindow(), "Width",  VRGet( VRWindow(), "Width")  + Delta_Width  );
   ok = VRSet( VRWindow(), "Height", VRGet( VRWindow(), "Height") + Delta_Height );
   ok = VRSet( "GB_XSay_Outer", "Top", VRGet("GB_XSay_Outer", "Top") + Delta_Height );
   ok = VRSet( "PB_Exit", "Top", VRGet("PB_Exit", "Top") + Delta_Height );

   /* Re-Init fÅr Resize Window-Frame: */
   ok = VRSet("GB_Image", "Userdata", VRGet("GB_Image", "Width") VRGet("GB_Image", "Height") );

   ok = VRSet( VRWindow(), "Painting", 1 );

end;
else;
   Call XSay "Invalid JPG-return: header not correctly delimited";

ok = ZSet_Wait("Off");

return 0;

/*:VRX         PB_GetVideo_Click
*/
PB_GetVideo_Click: 

Call PB_GetImg_Click "VID";

return 0;

/*:VRX         PB_Locdef_Canc_Click
*/
PB_Locdef_Canc_Click: 
Call WIN_DefLoc_Close;
return 0;

/*:VRX         PB_Locdef_OK_Click
*/
PB_Locdef_OK_Click: 

LocName = VRGet("Combo_Locdefs", "Value" );     /* beware 'LocName' for If FirstTime      */
if LocName = "" then do
   ok = VRMessage( VRWindow(), "A Location-Name must be specified" );
   RETURN -1;
end;

Domain = VRGet("EF_LocDomain", "Value" );
if Domain = "" then do
   ok = VRMessage( VRWindow(), "A Domain (IP-Address) must be specified" );
   RETURN -1;
end;

PortNo = VRGet("EF_LocPortNo", "Value" );
if PortNo = "" then do
   ok = VRMessage( VRWindow(), "A Port-Number to the Internet-Address must be specified" );
   RETURN -1;
end;

Camera = VRGet("Combo_LocCams", "Value" );
if Camera = "" then do
   ok = VRMessage( VRWindow(), "A Camera must be specified" );
   RETURN -1;
end;

ok = SysINI( LOC_File, LocName, "CamName",  VRGet("Combo_LocCams",   "Value" ) );   /* Design-Ungenauigkeit - ist in Wirklichkeit Cammodel    */

ok = SysINI( LOC_File, LocName, "Domain" ,   VRGet("EF_LocDomain",    "Value" ) );
ok = SysINI( LOC_File, LocName, "Portno",    strip(VRGet("EF_LocPortno", "Value" ),"L",":") );

ok = SysINI( LOC_File, LocName, "Lginnm", VRGet("EF_LoginName", "Value" ) );
ok = SysINI( LOC_File, LocName, "Lginpw", VRGet("EF_LoginPass", "Value" ) );

ok = SysINI( LOC_File, LocName, "PSetName1", VRGet("EF_LocPSetName1", "Value" ) );
ok = SysINI( LOC_File, LocName, "PSetName2", VRGet("EF_LocPSetName2", "Value" ) );
ok = SysINI( LOC_File, LocName, "PSetName3", VRGet("EF_LocPSetName3", "Value" ) );
ok = SysINI( LOC_File, LocName, "PSetName4", VRGet("EF_LocPSetName4", "Value" ) );
ok = SysINI( LOC_File, LocName, "PSetName5", VRGet("EF_LocPSetName5", "Value" ) );
ok = SysINI( LOC_File, LocName, "PSetName6", VRGet("EF_LocPSetName6", "Value" ) );
ok = SysINI( LOC_File, LocName, "PSetName7", VRGet("EF_LocPSetName7", "Value" ) );
ok = SysINI( LOC_File, LocName, "PSetName8", VRGet("EF_LocPSetName8", "Value" ) );
ok = SysINI( LOC_File, LocName, "PSetName9", VRGet("EF_LocPSetName9", "Value" ) );

Call WIN_Defloc_Close;

return 0;

/*:VRX         PB_Move_Click
*/
PB_Move_Click: 

if VRGet("SPIN_Preset", "Value") = "none" then do
   ok = VRMessage( VRWindow(), "No preset position selected",,"E");
   RETURN -1;
end;

Cam_Model = Check_CamAccess();

if \(Cam_Model > "0") then RETURN;

ACD_File = Cam_Model".ACD";

Call ZMove_Cam ACD_File;

/* -------------------------            */
/* HTTP-Returncode auslesen:            */
/* -------------------------            */
nok = SockRecv(sock,"HTTP_Ans",512);
HTTP_Retcode = word(HTTP_Ans,2);
Call XSay "Return from 'move to preset': " ZTransHTTPCode( HTTP_Retcode );

return 0;

/*:VRX         PB_SetBright_Click
*/
PB_SetBright_Click: 
Call PB_Setxxx_Click "Bright";
return 0;

/* ------------------------------------------------------   */
/* Setzen der Video-Eigenschaften  Brightness / Contrast:   */
/* ------------------------------------------------------   */
PB_Setxxx_Click:
What = arg(1);      /* ["Bright"|"Contr"]   */

Cam_Model = Check_CamAccess();

if \(Cam_Model > "0") then RETURN;

ACD_File = Cam_Model".ACD";

/* Bestimmen Wert fÅr Brightness / Contrast = f(Slider-Value): */

Lo = SysINI( ACD_File, "Command", What"Lo" );     /* 0 ...    */
Hi = SysINI( ACD_File, "Command", What"Hi" );     /* ... 255  */

if Lo = "ERROR:"    ,
 | Hi = "ERROR:"    then do
   ok = VRMessage( VRWindow(), "Camera has no specification for sharpness / contrast-setting", "Error in Camera-Definion", "E" );
   RETURN -1;
end;

Percentile = VRGet("SL_"What, "Percentile");

WhatVal = (( Percentile / 100 ) * Hi ) %1;

Cmd_Setxx = SysINI( ACD_File, "Command", "Set"What );
Cmd_Setxx = strip(Cmd_Setxx,"L","/");   /* strip leading slash     */

QUERY   = ZChange( Cmd_Setxx, "%1", WhatVal );

Call TalkToCam QUERY;

nok = SockRecv(sock,"HTTP_Ans",512);

HTTP_Retcode = word(HTTP_Ans,2);

Call XSay "Return from Set-"What"ness: " ZTransHTTPCode( HTTP_Retcode );

return 0;

/*:VRX         PB_SetContr_Click
*/
PB_SetContr_Click: 
Call PB_Setxxx_Click "Contr";
return 0;

/*:VRX         PB_VPlayerBrowse_Click
*/
PB_VPlayerBrowse_Click: 

VPlayer = VRFileDialog( VRWindow(), "Select a video-player", "Open", , , ,  );

if VPlayer = "" then RETURN;

ok = VRSet("EF_VPlayer", "Value", VPlayer );

return 0;

/*:VRX         Quit
*/
Quit:

/* INI sichern      */

ok = SysINI( INIFile, "Current", "Location", VRGet("Combo_LocSelect", "Value") );
ok = SysINI( INIFile, "Current", "Camera",   VRGet("Combo_CamSelect", "Value") );

ok = RXListboxToFile( VRGet("LB_XSay", "hWnd"), , YGlob.YProg || ".log" );

ok = VRRedirectStdIO("OFF"); /* Makes console invisible  */

    window = VRWindow()
    call VRSet window, "Shutdown", 1
    drop window
return

/*:VRX         SL_Bright_Change
*/
SL_Bright_Change: 

Percentile = VRGet("SL_Bright", "Percentile");

Brightness = (50 - Percentile) * -1;

ok = VRSet("EF_BrightVal", "Painting", 0 );

ok = VRSet("EF_BrightVal", "Value", Brightness );

Left = ( VRGet("SL_Bright", "Width") - 100 ) * ( (Percentile - (0.1 * Brightness)) / 100 ) %1;
Left = Left - ( VRGet("EF_BrightVal", "Width") /2 ) %1;

if Left < 0 then Left = 0;

if Brightness = 0 then Left = Left + 40;  /* abfedern Ungenauigkeit   */

ok = VRSet("EF_BrightVal", "Left", Left );

ok = VRSet("EF_BrightVal", "Painting", 1 );

return 0;

/*:VRX         SL_Contr_Change
*/
SL_Contr_Change: 

Percentile = VRGet("SL_Contr", "Percentile");

Contrast = (50 - Percentile) * -1;

ok = VRSet("EF_ContrVal", "Painting", 0 );

ok = VRSet("EF_ContrVal", "Value", Contrast );

Left = ( VRGet("SL_Contr", "Width") - 100 ) * ( (Percentile - (0.1 * Contrast)) / 100 ) %1;
Left = Left - ( VRGet("EF_ContrVal", "Width") /2 ) %1;

if Left < 0 then Left = 0;

if Contrast = 0 then Left = Left + 40;  /* abfedern Ungenauigkeit   */

ok = VRSet("EF_ContrVal", "Left", Left );

ok = VRSet("EF_ContrVal", "Painting", 1 );

return 0;

/*:VRX         SPIN_Preset_Change
*/
SPIN_Preset_Change: 

/* wird ausgelîst durch einen Click auf einen der PSet-Buttons:     */

PSetPos = VRGet("SPIN_Preset","Value");

LocName = VRGet("Combo_LocSelect", "Value");

Val = SysINI( LOC_File, LocName, "PSetName" || PSetPos);
if Val = "ERROR:" then do
   Val = "<undefined>";
   ok = VRSet("SPIN_Preset","Index", 0);
   ok = VRFlush("Change", "SPIN_Preset");
end;

ok = VRSet("DT_Preset", "Caption", Val );
ok = VRSet("DT_Preset",  "Visible", 1 );

return

/*:VRX         TalkToCam
*/
TalkToCam: Procedure Expose YGlob. INIFile  ,
                            sock;
QUERY = arg(1);

Site_URL = VRGet("EF_IPAddr", "Value"); /* enthÑlt Portno !!        */

parse value Site_URL with Site_URL ":" Portno;

HTTP_Cmd = BuildCmd( QUERY );

host.!family = 'AF_INET';
host.!port   = Portno;		/* port for HTTP-Server         */
host.!addr   = 'will be returned from SockGetHostByName';
host.!name   = 'will be returned from GetHostByAddr';

if left(Site_URL,4) <> "192." then do
   Call XSay "Connecting to "Site_URL"...";
   ok = SockGetHostByName(Site_URL, "host.!");

   Call XSay "ok(SockGetHostByName)="ok;
   if ok = 1 then
      Call XSay "IP-addres of "Site_URL"="host.!addr;
   URL = host.!addr;
   host.!addr = URL;
end;
else;
   host.!addr = Site_URL;

Call XSay "About to send camera-command="HTTP_Cmd".";

/* -------------------------						*/
/* Open the Session:							*/
/* -------------------------						*/
sock = SockSocket('AF_INET','SOCK_STREAM','IPPROTO_TCP');
nok = SockConnect(sock,host.!)
if nok = -1 then do
   Call XSay 'Error connecting to host='host.!addr;
   sock = -1;
end

if Sock < 0 then do;
   Call ZSock_Err "Error with OpenSession", Sock;
   return -1;
end;

SentBytes = SockSend(sock,HTTP_Cmd);	Call XSay "Sent bytes: "SentBytes" out of max. "length(HTTP_Cmd)".";

return SentBytes;

/*:VRX         WIN_Defcam_Close
*/
WIN_Defcam_Close: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return 0;

/*:VRX         WIN_Defcam_Create
*/
WIN_Defcam_Create: 


/* Alte Werte anzeigen:                                 */
/* Lies alle vorhandenen Access Control Definitions:    */

    ok = ZFill_CamModels("Combo_Camdefs");

    window = VRInfo( "Object" )
    call VRMethod window, "CenterWindow"
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window
return 0;

/*:VRX         WIN_DefLoc_Close
*/
WIN_DefLoc_Close: 

ok = ZFill_CamLocs("Combo_LocSelect");  /* erfrischen   */

    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return 0;

/*:VRX         WIN_DefLoc_Create
*/
WIN_DefLoc_Create: 

    ok = VRSet("PB_DefLoc_Set", "Caption", "refresh" );

    ok = ZFill_CamLocs(  "Combo_Locdefs");
    ok = ZFill_CamModels("Combo_LocCams");

    window = VRInfo( "Object" )
    call VRMethod window, "CenterWindow"
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window
return 0;

/*:VRX         WIN_Wait_Close
*/
WIN_Wait_Close: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return

/*:VRX         WIN_Wait_Create
*/
WIN_Wait_Create: 
    window = VRInfo( "Object" )
    call VRMethod window, "CenterWindow"
    call VRSet window, "Visible", 0
    call VRMethod window, "Activate"
    drop window
return

/*:VRX         Window1_Close
*/
Window1_Close:
    call Quit
return

/*:VRX         ZChange
*/
ZChange: Procedure      /* ++ identisch aus phpGUI - Window1.vrx ++  */
/*------------------------------------------------------------------
  Change Record (Replace-Funktion / strrepl() ):
  Ersetze alten String durch neuen, mit Optionen in weiteren <...>:
  -------------------------------------------------------------------*/
Record   = arg(1)
OldPGMID = arg(2)   /* OldVar   */
NewPGMID = arg(3)   /* NewVar   */

/* Optionen:                    */
Ucase = 0;          /* Ersatzstring wird NICHT auf Uppercases translatiert    */
Lcase = 0;          /* Ersatzstring wird NICHT auf Lowercases translatiert    */

CurPosi = 1

if length(Record) \> 1 then return Record  /* nix tun mit Leerzeilen    */

do while CurPosi < length(Record)
   posi = pos(OldPGMID,Record,CurPosi)
   if posi > 0 then do

      if Ucase = 1 then NewPGMID = translate(NewPGMID);
      if Lcase = 1 then NewPGMID = setlower(NewPGMID);

      Links = left(Record,posi-1)
      rechts= right(Record,length(Record)-(posi+length(OldPGMID)-1))
      NewRec = Links||NewPGMID||Rechts

      CurPosi = Posi+1  /* fÅr neuen Durchlauf prÑparieren */
   end
   else do
      NewRec  = Record            /* unverÑndert Åbernehmen             */
      CurPosi = length(Record)+1  /* fÅr neuen Durchlauf prÑparieren    */
   end

   Record  = NewRec    /* fÅr neuen Durchlauf prÑparieren */
end
return NewRec

/*:VRX         ZCre_PSet
*/
ZCre_PSet: Procedure;

Init_Left = 266;
Init_Top  = 690;

Width =25 * VRMethod("Screen", "PixelsToTwips",1);
Height=25 * VRMethod("Screen", "PixelsToTwips",1);

Left = Init_Left;
Top  = Init_Top;
do i = 1 to 9

   pset = VRCreate("GB_PanTilt", "PICTUREBOX",          ,
                   "Name", "PSet"i,                     ,
                   "Left", Left, "Top", Top,            ,
                   "Width", Width, "Height", Height,    ,
                   "PicturePath", "PSet.bmp",           ,
                   "Border", 0,                         ,
                   "Click",  "Call ZPSet_Click;"        ,
                  );

   DT   = VRCreate("GB_PanTilt", "DESCRIPTIVETEXT",    ,
                   "Left", Left+80, "Top", Top+60,     ,
                   "Caption", i,                       ,
                   "Height", 160, "Width",80,          ,
                   "Font",  "9.WarpSans Bold"           ,
                  );

   ok = VRSet( pset, "Userdata", DT );     /* Verketten DT an Picturebox   */

   Rest = (i//3);
   If Rest = 0 then do
      /* Neue Zeile:        */
      Left = Init_Left;
      Top  = Top  + Height + 110;
   end;
   else;do
      Left = Left + Width  + 200;
   end;

end;

return 0;

/*:VRX         ZFill_CamLocs
*/
ZFill_Camlocs: Procedure Expose YGlob. LOC_File;
ListObj = arg(1);

ok = VRMethod("Combo_LocSelect", "CLEAR");

ok = SysINI( LOC_File, "ALL:", "Locs." );

say "Locs.0="Locs.0"!";

do i = 1 to Locs.0
   LocName =  Locs.i;
   ok = VRMethod(ListObj, "AddString", LocName );
end;

return 0;


/*:VRX         ZFill_CamModels
*/
ZFill_CamModels: Procedure Expose YGlob.
ListObj = arg(1);

ok = VRMethod("Combo_CamSelect", "CLEAR");

ok = SysFileTree("*.ACD", "files.", "FO" );
do i = 1 to files.0
   FName =  filespec("name",files.i);

   Model = left(FName, length(FName)-length(".ACD") );
   ok = VRMethod(ListObj, "AddString", Model );
end;

return 0;

/*:VRX         ZGet_ImgSize
*/
ZGet_ImgSize: procedure

FileSpec = arg(1);  /* ++ nur fÅr BMPs !! */

if \VRFileExists(FileSpec) then RETURN 444 240; /* return standard image-dimension  */

X_x = Charin(FileSpec, 17, 4);
Y_x = Charin(FileSpec, 21, 4);
ok=stream(FileSpec,"c","close");

X_d = c2x(X_x);
Y_d = c2x(Y_x);

/* richtig rum drehen:  */

XSize = x2d( substr(X_d,7,2)||substr(X_d,5,2) );
YSize = x2d( substr(Y_d,7,2)||substr(Y_d,5,2) );

return XSize YSize;


/*:VRX         ZMove_Cam
*/
ZMove_Cam: Procedure Expose sock;
ACD_File = arg(1);

   /* Command holen und Positions-Nummer einsetzen:                 */
   Cmd_Pset = SysINI( ACD_File, "Command", "MovePreset" );
   Cmd_Pset = strip(Cmd_Pset,"L","/");   /* strip leading slash     */
   PSetPos = VRGet("SPIN_Preset", "Value");

   /* anwenden Assignment-Rule:          */
   LocName = VRGet("Combo_LocSelect", "Value");
   PSetPos = ZPSet_Assgn( SysINI( ACD_File, "Rules", "PSetAssgn" ), PSetPos );  /* Umsetzen Positionsnummer --> cgi-Param   */
   QUERY   = ZChange( Cmd_Pset, "%1", PSetPos );

   Call TalkToCam QUERY;

   ok = SysSleep(3);    /* solange braucht's etwa, um den Schwenkbefehl auszufÅhren */

return 0;

/*:VRX         ZNB_Subroutines
*/
ZNB_Subroutines:
nop;
return;


ZNB_Basic_Create: 
    call ZNB_zzz_Init;
return

ZNB_PTlt_Create: 
    call ZNB_zzz_Init
return

ZNB_Video_Create: 
    call ZNB_zzz_Init
return

/* --------------- end Create ----------------	*/

ZNB_Basic_Close: 
ZNB_PTlt_Close: 
ZNB_Video_Close: 
    call ZNB_zzz_Fini
return

/* --------------- end Close ----------------	*/

ZNB_zzz_Init: 
nop;
return 0;

ZNB_zzz_Fini: 
    window = VRInfo( "Window" )
    call VRDestroy window
    drop window
return 0;


/*:VRX         ZPSet_Assgn
*/
ZPSet_Assgn: Procedure;
AssgnRule = arg(1);     /* Regel        */
PSetVal   = arg(2);     /* PSet-Nummer  */

if AssgnRule = 1 then                   /* 1 -> 1   */
   Param = PSetVal;

if AssgnRule = 2 then                   /* 1 -> 0   */
   Param = PSetVal-1;

if AssgnRule = 3 then                   /* 1 -> a   */
   Param = d2c( c2d(PSetVal) + 16 );

if AssgnRule = 9 then                   /* Userexit _ZTrPSet.cmd  */
   Param = _ZTrPSet(PSetVal);

return Param;


/*:VRX         ZPset_Click
*/
ZPset_Click: 


Obj = VRGet( VRInfo("Object"), "Name" );

PSet_Pos = right(Obj,1);

ok = VRSet( "SPIN_Preset", "Index", PSet_Pos +1);

/* -------------------------    */
/* Markieren geklickten ROT:    */
/* -------------------------    */

do i = 1 to 9
   Obj = "PSet"i;
   DT = VRGet( Obj, "Userdata" );     /* Hole DT aus Picturebox           */
   if i = PSet_Pos then
      ok = VRSet( DT, "ForeColor", "Red" );
   else;
      ok = VRSet( DT, "ForeColor", "<default>" );  /* reset to default    */

end;


return 0;

/*:VRX         ZSet_Wait
*/
ZSet_Wait: Procedure Expose YGlob.;
OnOff = arg(1);     /* [ "On" | "Off" ]      */
Txt   = arg(2);

if translate( OnOff ) = "ON" then do
   ok = VRSet("DT_WaitTxt",   "Caption", Txt);
   Vis  = 1;
   Sibl = 1;
end;
else;do
   if \VRGet("WIN_Wait",  "Visible") then RETURN 0;
   Vis  = 0;
   Sibl = 9;
end;

ok = VRSet("WIN_Wait", "Visible", Vis );        /* "Bitte warten ... "              */
ok = VRSet("WIN_Wait", "SiblingOrder", Sibl );  /* "Bitte warten ... "              */

ok = VRSet("Window1",  "SiblingOrder", 2 );     /* Hauptfenster nach vorn bringen   */

return ok;

/*:VRX         ZSock_Err
*/
ZSock_Err: 
/* -------- */
/* SockErr: */
/* -------- */
Mess = arg(1);
sock = arg(2);

   TmpFile = SysTempFileName("$$???.log");
   ok = VRRedirectStdIO("ON",TmpFile);      /* weil SockPSock() schreibt nur auf Console    */
   ok = SockPSock_Errno( sock );
   ok = VRRedirectStdIO("OFF");
   SockMess = CharIn(TmpFile,1,Chars(TmpFile)-2);
   Call XSay Mess "on Socket" || sock ||":" SockMess;

   ok = stream(TmpFile,"c","close");
   ok = SysFileDelete(TmpFile);

   ok = SockClose( sock );

return -1;

/*:VRX         ZTransHTTPCode
*/
ZTransHTTPCode: 
HTTPCode = arg(1);

if HTTPCode = "200" then return "OK";
if HTTPCode = "401" then return "not authorized";
if HTTPCode = "404" then return "not found";

return "unknown http-returncode";

