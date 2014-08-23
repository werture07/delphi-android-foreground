unit ActivityReceiverU;

interface
{$IFDEF ANDROID}
uses
  FMX.Types,
  Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText;

type
  JActivityReceiverClass = interface(JBroadcastReceiverClass)
    ['{9D967671-9CD8-483A-98C8-161071CE7B64}']
    { Methods }
    // function init: JActivityReceiver; cdecl;
  end;

  [JavaSignature('com/barisatalay/foreground/ActivityReceiver')]
  JActivityReceiver = interface(JBroadcastReceiver)
  ['{4CA80170-FDA8-4D9B-BB66-0A0D86A9F5C0}']
  { Methods }
  end;

  TJActivityReceiver = class(TJavaGenericImport<JActivityReceiverClass,
    JActivityReceiver>)
  protected
    constructor _Create;
  public
    class function Create: JActivityReceiver;
    procedure OnReceive(Context: JContext; ReceivedIntent: JIntent);
  end;

  TStateEnum = (S00, S0B, S0S, SCN, SDN, SCM);
{$ENDIF}
implementation
{$IFDEF ANDROID}
uses
  System.Classes,
  System.SysUtils,
  FMX.Helpers.Android,
  Androidapi.NativeActivity,
  Androidapi.JNI,
  Androidapi.JNI.JavaTypes,
  ServiceU, Androidapi.Helpers,
  Androidapi.JNI.Net,
  System.TypInfo,
  FMX.Platform
  ;

var
  ActivityReceiver: TJActivityReceiver;
  ARNContext: JContext;
  ARNReceivedIntent: JIntent;

procedure ActivityReceiverOnReceiveThreadSwitcher;
begin
  ActivityReceiver.OnReceive(ARNContext, ARNReceivedIntent);
end;

procedure ActivityReceiverOnReceiveNative(PEnv: PJNIEnv; This: JNIObject;
  JNIContext, JNIReceivedIntent: JNIObject); cdecl;
begin
  ARNContext := TJContext.Wrap(JNIContext);
  ARNReceivedIntent := TJIntent.Wrap(JNIReceivedIntent);
  TThread.Synchronize(nil, ActivityReceiverOnReceiveThreadSwitcher);
end;

procedure RegisterDelphiNativeMethods;
var
  PEnv: PJNIEnv;
  ReceiverClass: JNIClass;
  NativeMethod: JNINativeMethod;
begin
  PEnv := TJNIResolver.GetJNIEnv;
  NativeMethod.Name := 'activityReceiverOnReceiveNative';
  NativeMethod.Signature :=
    '(Landroid/content/Context;Landroid/content/Intent;)V';
  NativeMethod.FnPtr := @ActivityReceiverOnReceiveNative;
  ReceiverClass := TJNIResolver.GetJavaClassID
    ('com.barisatalay.foreground.ActivityReceiver');
  if ReceiverClass <> nil then
  begin
    PEnv^.RegisterNatives(PEnv, ReceiverClass, @NativeMethod, 1);
    PEnv^.DeleteLocalRef(PEnv, ReceiverClass);
  end;
end;
{ TActivityReceiver }

constructor TJActivityReceiver._Create;
begin
  inherited;
end;

class function TJActivityReceiver.Create: JActivityReceiver;
begin
  Result := inherited Create;
  ActivityReceiver := TJActivityReceiver._Create;
end;

//procedure SendNotification(title: string; info: string);
//var
//  Notification: TNotification;
//  NotificationService: IFMXNotificationCenter;
//begin
//  if TPlatformServices.Current.SupportsPlatformService(IFMXNotificationCenter)
//  then
//    NotificationService := TPlatformServices.Current.GetPlatformService
//      (IFMXNotificationCenter) as IFMXNotificationCenter;
//
//  if Assigned(NotificationService) then
//  begin
//    Notification := TNotification.Create;
//    try
//      Notification.Name := title;
//      Notification.AlertBody := info;
//      Notification.FireDate := Now + EncodeTime(0, 0, 5, 0);
//      NotificationService.CancelAllNotifications;
//      NotificationService.ScheduleNotification(Notification);
//    finally
//      Notification.DisposeOf;
//    end;
//  end
//end;

procedure TJActivityReceiver.OnReceive(Context: JContext;
  ReceivedIntent: JIntent);//Yayýn Yakalama olayý sanýrým burada oluyor.
var
  _infoMsg: string;
  _state: TStateEnum;
  _currentValue: string;
  _stateValue: string;
begin
  _stateValue := JStringToString
    (ReceivedIntent.getStringExtra(StringToJString(TForegroundServis.ID_STATE)));
  _state := TStateEnum(GetEnumvalue(TypeInfo(TStateEnum), _stateValue));
  case _state of
    S00, S0S, SCN, SDN:
      begin
        _infoMsg := JStringToString
          (ReceivedIntent.getStringExtra
          (StringToJString(TForegroundServis.ID_DEG_MSG)));
      end;
    S0B:
      begin
        _infoMsg := JStringToString
          (ReceivedIntent.getStringExtra
          (StringToJString(TForegroundServis.ID_DEG_MSG)));
        _currentValue := JStringToString
          (ReceivedIntent.getStringExtra
          (StringToJString(TForegroundServis.ID_INT_CURRENT_VALUE)));
      end;
    SCM:
      begin
        _infoMsg := JStringToString
          (ReceivedIntent.getStringExtra
          (StringToJString(TForegroundServis.ID_DEG_MSG)));
      end;
  end;
end;

initialization

RegisterDelphiNativeMethods;
{$ENDIF}
end.
