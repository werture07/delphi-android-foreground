unit ServiceU;

interface

uses
  System.Classes,
  FMX.Types
  {$IFDEF ANDROID}
  ,Androidapi.JNIBridge
  ,Androidapi.JNI.App
  ,Androidapi.JNI.GraphicsContentViewText
  ,ActivityReceiverU
  ,Androidapi.JNI.Toast
  ,FMX.Platform

  {$ENDIF}
  ;
type
  TServiceThread = class;

  TForegroundServis = class(TComponent)
  private
    FServiceIsRunning  : Boolean;
    FReceiverRegistered: Boolean;
    {$IFDEF ANDROID}
    AppEvents: IFMXApplicationEventService;
    FxReceiver: JActivityReceiver;
    function  GetJArray(const AIntArr: array of Int64): TJavaArray<Int64>;
    function ApplicationEventHandler(AAppEvent: TApplicationEvent;AContext: TObject): Boolean;
    Function GetVersion: String;
    {$ENDIF}

    procedure RegisterReceiver;
    procedure UnregisterReceiver;

  public

    {$IFDEF ANDROID}
    FReceiver: JBroadcastReceiver;
    FThread: TServiceThread;
    FForegroundServis: JService;
    {$ENDIF}
    Running: Boolean;
    StartValue: Integer;

    constructor Create(AOwner: TComponent); override;
    {$IFDEF ANDROID}function GetJService: JService;{$ENDIF}
    procedure SetForeground;
    procedure OnDestroy;
    {$IFDEF ANDROID}
    function OnStartCommand(StartIntent: JIntent;
      Flags, StartID: Integer): Integer;{$ENDIF}
    procedure StartService;
    procedure StopService;
    procedure EventControl;
  const
    SERVICE_ACTION = 'SERVICE_ACTION';
    ID_INT_CURRENT_VALUE = '0';
    ID_INT_COMMAND = 'COMMAND';
    ID_STATE = 'S00';
    ID_DL_FLAG = '0';
    CMD_STOP_SERVICE: Integer = 1;
    ID_DEG_MSG = 'DEBUG_MSG';
  end;

  TServiceThread = class(TThread)
  private
    function UIActiveISAlive: Boolean;
  public
    procedure Execute; override;
  end;

type
  TGeneratorUniqueID = class
  const
    SETTINGS_NOTIFICATION_UNIQUE_ID = 'SETTINGS_NOTIFICATION_UNIQUE_ID2';
  strict private
    class var FNextUniqueID: Int64;
  public
    class constructor Create;
    class function GenerateID: Integer;
  end;

const
  FMX_NOTIFICATION_CENTER = 'FMX_NOTIFICATION_CENTER2';
  ACTIVITY_ACTION = 'ACTIVITY_ACTION';



procedure Register;

implementation

{$IFDEF ANDROID}
uses
  System.SysUtils,
  FMX.Helpers.Android,
  FMX.Platform.Android,
  Androidapi.NativeActivity,
  Androidapi.JNI,
  Androidapi.JNI.JavaTypes,
  ServiceReceiverU, Androidapi.Helpers,
  System.IOUtils,
  Androidapi.JNI.ActivityManager,
  Androidapi.JNI.Net,
  Androidapi.JNI.Support,
  Androidapi.JNI.Embarcadero;

  var
  ForegroundServisObjectID: JNIObject;
  ARNStartIntent: JIntent;
  ARNFlags: Integer;
  ARNStartID: Integer;
  ARNResult: Integer;
  ForegroundServis: TForegroundServis;
{$ENDIF}

procedure Register;
begin
  RegisterComponents('Native Service', [TForegroundServis]);
end;
{$IFDEF ANDROID}
function TForeGroundServis.GetJArray(const AIntArr: array of Int64): TJavaArray<Int64>;
var
  LIndex: Integer;
begin
  Result := TJavaArray<Int64>.Create(Length(AIntArr));
  for LIndex := Low(AIntArr) to High(AIntArr) do
    Result.Items[LIndex] := AIntArr[LIndex];
end;

function TForeGroundServis.ApplicationEventHandler(AAppEvent: TApplicationEvent;AContext: TObject): Boolean;
begin
  case AAppEvent of
    TApplicationEvent.BecameActive:
      RegisterReceiver;
    TApplicationEvent.EnteredBackground:
      MainActivity.moveTaskToBack(True);
    TApplicationEvent.WillTerminate:
      UnregisterReceiver;
  end;
  Result := True;
end;

function TForeGroundServis.GetVersion: String;
var
  PackageManager: JPackageManager;
  PackageInfo : JPackageInfo;
begin
  PackageManager := SharedActivity.getPackageManager;
  PackageInfo := PackageManager.getPackageInfo(SharedActivityContext.getPackageName(), TJPackageManager.JavaClass.GET_ACTIVITIES);
  Result := JStringToString(PackageInfo.versionName);
end;

{$ENDIF}

procedure TForeGroundServis.RegisterReceiver;
{$IFDEF ANDROID}
var
  Filter: JIntentFilter;
begin
  if not FReceiverRegistered and (FReceiver <> nil) then
  begin
    Filter := TJIntentFilter.Create;
    Filter.addAction(StringToJString(TForegroundServis.SERVICE_ACTION));
    SharedActivity.RegisterReceiver(FReceiver, Filter);
    FReceiverRegistered := True;
  end
{$ELSE}
begin
{$ENDIF}
end;

procedure TForeGroundServis.StartService;
{$IFDEF ANDROID}
var
  ServiceIntent: JIntent;
begin
  EventControl;
  if not FServiceIsRunning then
  begin
    FReceiver := TJActivityReceiver.Create;
    RegisterReceiver;
    ServiceIntent := TJIntent.JavaClass.init(SharedActivityContext,
      TJLang_Class.JavaClass.forName
      (StringToJString('com.barisatalay.foreground.ForegroundServis'), True,
      SharedActivity.getClassLoader));
    if SharedActivity.StartService(ServiceIntent) = nil then
      Toast('startService returned nil',TToastLength.ShortToast);
    FServiceIsRunning := True;
  end
{$ELSE}
begin
{$ENDIF}
end;

procedure TForeGroundServis.StopService;
{$IFDEF ANDROID}
var
  Intent: JIntent;
begin
  if FServiceIsRunning then
  begin
    UnregisterReceiver;
    FReceiver := nil;
    Intent := TJIntent.Create;
    Intent.setAction
      (StringToJString(ACTIVITY_ACTION));
    Intent.putExtra(StringToJString(TForegroundServis.ID_INT_COMMAND),
      TForegroundServis.CMD_STOP_SERVICE);
    SharedActivity.sendBroadcast(Intent);
    FServiceIsRunning := False;
  end;
{$ELSE}
begin
{$ENDIF}
end;

procedure TForegroundServis.EventControl;
{$IFDEF ANDROID}
begin
  if TPlatformServices.Current.SupportsPlatformService
    (IFMXApplicationEventService, IInterface(AppEvents)) then
    AppEvents.SetApplicationEventHandler(ApplicationEventHandler);
{$ELSE}
begin
{$ENDIF}
end;

procedure TForeGroundServis.UnregisterReceiver;
{$IFDEF ANDROID}
begin
  if FReceiverRegistered and (FReceiver <> nil) then
  begin
    SharedActivity.UnregisterReceiver(FReceiver);
    FReceiverRegistered := False;
  end;
{$ELSE}
begin
{$ENDIF}
end;


procedure SampleServiceOnStartCommandThreadSwitcher;
{$IFDEF ANDROID}
begin
  ARNResult := ForegroundServis.OnStartCommand(ARNStartIntent, ARNFlags,
    ARNStartID);
{$ELSE}
begin
{$ENDIF}
end;

{$IFDEF ANDROID}
function SampleServiceOnStartCommandNative(PEnv: PJNIEnv; This: JNIObject;
  JNIStartIntent: JNIObject; Flags, StartID: Integer): Integer; cdecl;
begin
  ForegroundServisObjectID := This;
  ARNStartIntent := TJIntent.Wrap(JNIStartIntent);
  ARNFlags := Flags;
  ARNStartID := StartID;
  TThread.Synchronize(nil, SampleServiceOnStartCommandThreadSwitcher);
  Result := ARNResult;
end;

procedure SampleServiceOnDestroyNative(PEnv: PJNIEnv; This: JNIObject); cdecl;
begin
  ForegroundServisObjectID := This;
  ForegroundServis.OnDestroy;
  ForegroundServisObjectID := nil;
end;
{$ENDIF}

procedure sendActive(const _infoMsg, _infoState, _infoValue: string);
{$IFDEF ANDROID}
var
  ActivityIntent: JIntent;
  Service: JService;
begin
  if (ForegroundServis <> nil) and (ForegroundServis.Running) then
  begin
    ActivityIntent := TJIntent.Create;
    ActivityIntent.setAction
      (StringToJString(TForegroundServis.SERVICE_ACTION)); //Deðiþtirdim
    ActivityIntent.putExtra(StringToJString(TForegroundServis.ID_DEG_MSG),
      StringToJString(_infoMsg));
    ActivityIntent.putExtra(StringToJString(TForegroundServis.ID_STATE),
      StringToJString(_infoState));
    if _infoValue <> string.Empty then
    begin
      ActivityIntent.putExtra
        (StringToJString(TForegroundServis.ID_INT_CURRENT_VALUE),
        StringToJString(_infoValue));
    end;
    Service := TJService.Wrap(ForegroundServisObjectID);
    Service.sendBroadcast(ActivityIntent);
  end;
{$ELSE}
begin
{$ENDIF}
end;

procedure RegisterDelphiNativeMethods;
{$IFDEF ANDROID}
var
  PEnv: PJNIEnv;
  ServiceClass: JNIClass;
  NativeMethods: array [0 .. 1] of JNINativeMethod;
begin
  PEnv := TJNIResolver.GetJNIEnv;
  NativeMethods[0].Name := 'sampleServiceOnStartCommandNative';
  NativeMethods[0].Signature := '(Landroid/content/Intent;II)I';
  NativeMethods[0].FnPtr := @SampleServiceOnStartCommandNative;
  NativeMethods[1].Name := 'sampleServiceOnDestroyNative';
  NativeMethods[1].Signature := '()V';
  NativeMethods[1].FnPtr := @SampleServiceOnDestroyNative;
  ServiceClass := TJNIResolver.GetJavaClassID('com.barisatalay.foreground.ForegroundServis');
  if ServiceClass <> nil then
  begin
    PEnv^.RegisterNatives(PEnv, ServiceClass, @NativeMethods[0],
      Length(NativeMethods));
    PEnv^.DeleteLocalRef(PEnv, ServiceClass);
  end;
{$ELSE}
begin
{$ENDIF}
end;
{ TJSampleService }

{$IFDEF ANDROID}
function TForegroundServis.GetJService: JService;
begin
  if FForegroundServis = nil then
    FForegroundServis := TJService.Wrap(ForegroundServisObjectID);
  Result := FForegroundServis;
end;

procedure StartUIActive;
var
  _Intent: JIntent;
  Service: JService;
begin
  _Intent := TJIntent.JavaClass.init(SharedActivityContext,
    TJLang_Class.JavaClass.forName(StringToJString('com.barisatalay.foreground'),
    True, SharedActivity.getClassLoader));
  _Intent.setAction(StringToJString('com.barisatalay.foreground'));
  _Intent.addCategory(TJIntent.JavaClass.CATEGORY_HOME);
  _Intent.setFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
  Service := TJService.Wrap(ForegroundServisObjectID);
  Service.sendBroadcast(_Intent);
end;
{$ENDIF}

function TServiceThread.UIActiveISAlive: Boolean;
{$IFDEF ANDROID}
var
  LJL: JList;
  LIterator: JIterator;
  LJAR: JActivityManager_RunningAppProcessInfo;
begin
  Result := False;
  LJL := GetActivityManager.getRunningAppProcesses;
  if Assigned(LJL) then
  begin
    LIterator := LJL.iterator;
    while LIterator.hasNext do
    begin
      LJAR := TJActivityManager_RunningAppProcessInfo.Wrap
        ((LIterator.next as ILocalObject).GetObjectID);
      if JStringToString(LJAR.processName) = 'com.barisatalay.foreground' then    ////////////
      begin
        Result := True;
        Break;
      end;
    end;
  end;
  LJL.Clear;
  LJL := nil;
{$ELSE}
begin
{$ENDIF}
end;

constructor TForegroundServis.Create(AOwner: TComponent);
begin
  inherited;
 {$IFDEF ANDROID}FReceiver := TJServiceReceiver.Create(self);{$ENDIF}
end;

{ TServiceThread }

procedure TForegroundServis.SetForeground;
{$IFDEF ANDROID}
var
  notification: JNotification;
  NotificationBuilder: JNotificationCompat_Builder;
  Intent: JIntent;
  Titret: TJavaArray<Int64>; //Androidapi.JNIBridge;
begin
  NotificationBuilder := TJNotificationCompat_Builder.JavaClass.init
    (SharedActivityContext);

  {$REGION  'Icon'}
  NotificationBuilder := NotificationBuilder.setSmallIcon
    (SharedActivityContext.getApplicationInfo.icon);
  {$ENDREGION}

//  {$REGION 'Titreþim Olayý'}
////  Titret := ServisLib.GetJArray([500, 1000, 2000, 3000]);
////  NotificationBuilder := NotificationBuilder.setVibrate(Titret);
//  {$ENDREGION}
//
//  {$REGION 'TARÝH EKLEME'}
////  NotificationBuilder := NotificationBuilder.setWhen(5000);
//  {$ENDREGION}
//
//  {$REGION 'Eklenirken gözüken notification'}
//  NotificationBuilder := NotificationBuilder.setTicker(StrToJCharSequence(GetApplicationTitle));
//  {$ENDREGION}
//
//  {$REGION 'Large Icon'}
////  NotificationBuilder := NotificationBuilder.setLargeIcon();
//  {$ENDREGION}
//

  notification := NotificationBuilder.build;

  Intent := TJIntent.Create;
  Intent.setClass(SharedActivityContext, SharedActivityContext.getClass);
  Intent.setFlags(TJIntent.JavaClass.FLAG_ACTIVITY_SINGLE_TOP or
    TJIntent.JavaClass.FLAG_ACTIVITY_CLEAR_TOP);
  Intent.setAction(TJFMXNotificationAlarm.JavaClass.ACTION_FMX_NOTIFICATION);

  notification.setLatestEventInfo(MainActivity.getApplicationContext,
    StrToJCharSequence( GetApplicationTitle), StrToJCharSequence('Versiyon: ' + GetVersion ),
    TJPendingIntent.JavaClass.getActivity(SharedActivityContext,
    TGeneratorUniqueID.GenerateID, Intent, 0));
  GetJService.startForeground(1, notification);
{$ELSE}
begin
{$ENDIF}
end;

{$IFDEF ANDROID}
function TForegroundServis.OnStartCommand(StartIntent: JIntent;
  Flags, StartID: Integer): Integer;
var
  Filter: JIntentFilter;
begin
  if not Running then
  begin
    Filter := TJIntentFilter.Create;
    Filter.addAction(StringToJString(ACTIVITY_ACTION));
    Filter.setPriority(1000);
    SharedActivity.registerReceiver(FReceiver, Filter);
    Running := True;
    FThread := TServiceThread.Create(False);
    FThread.FreeOnTerminate := True;
    SetForeground;
  end;
  Result := TJService.JavaClass.START_STICKY_COMPATIBILITY;
end;
{$ENDIF}


procedure TServiceThread.Execute;
{$IFDEF ANDROID}
var
  debmsg: string;
begin
  try
    while (ForegroundServis <> nil) and (ForegroundServis.Running) do
    begin
      Sleep(10000);
      try
        if ForegroundServis <> nil then
          sendActive(debmsg, 'SCM', debmsg);
      except
        on e: Exception do
          sendActive(e.Message, 'SCM', e.Message);
      end;
    end;
    sendActive('Burasý ne bilmiyorum', 'S00', string.Empty);
    if ForegroundServis <> nil then
      ForegroundServis.GetJService.stopSelf;
  finally
    if (GetAndroidApp <> nil) and (GetAndroidApp.activity <> nil) then
      GetAndroidApp.activity.vm^.DetachCurrentThread(GetAndroidApp.activity.vm);
  end;
{$ELSE}
begin
{$ENDIF}
end;

class constructor TGeneratorUniqueID.Create;
{$IFDEF ANDROID}
var
  Preference: JSharedPreferences;
begin
  Preference := SharedActivity.getSharedPreferences
    (StringToJString(FMX_NOTIFICATION_CENTER),
    TJContext.JavaClass.MODE_PRIVATE);
  FNextUniqueID := Preference.getInt
    (StringToJString(SETTINGS_NOTIFICATION_UNIQUE_ID), 0);
{$ELSE}
begin
{$ENDIF}
end;

class function TGeneratorUniqueID.GenerateID: Integer;
{$IFDEF ANDROID}
var
  PreferenceEditor: JSharedPreferences_Editor;
  Preference: JSharedPreferences;
begin
  Preference := SharedActivity.getPreferences(TJContext.JavaClass.MODE_PRIVATE);
  PreferenceEditor := Preference.edit;
  try
    PreferenceEditor.putInt(StringToJString(SETTINGS_NOTIFICATION_UNIQUE_ID),
      FNextUniqueID);
  finally
    PreferenceEditor.commit;
  end;
  Result := FNextUniqueID;
  Inc(FNextUniqueID);
{$ELSE}
begin
{$ENDIF}
end;

procedure TForegroundServis.OnDestroy;
{$IFDEF ANDROID}
begin
  SharedActivity.unregisterReceiver(FReceiver);
{$ELSE}
begin
{$ENDIF}
end;

initialization

{$IFDEF ANDROID}ForegroundServis := TForegroundServis.Create(nil); {$ENDIF}
RegisterDelphiNativeMethods;
end.
