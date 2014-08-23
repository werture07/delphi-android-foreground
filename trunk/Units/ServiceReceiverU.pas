unit ServiceReceiverU;

interface
{$IFDEF ANDROID}
uses
  FMX.Types,
  Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText,
  ServiceU;

type
  JServiceReceiverClass = interface(JBroadcastReceiverClass)
    ['{177320F8-F933-4E10-8106-7A5119603383}']
    { Methods }
    // function init: JServiceReceiver; cdecl;
  end;

  [JavaSignature('com/barisatalay/foreground/ServiceReceiver')]
  JServiceReceiver = interface(JBroadcastReceiver)
    ['{06647B08-6920-4DEE-819B-8578F5BDFCCF}']
    { Methods }
  end;

  TJServiceReceiver = class(TJavaGenericImport<JServiceReceiverClass,
    JServiceReceiver>)
  private
    [weak]
    FOwningService: TForegroundServis;
  protected
    constructor _Create(Service: TForegroundServis);
  public
    class function Create(Service: TForegroundServis): JServiceReceiver;
    procedure OnReceive(Context: JContext; ReceivedIntent: JIntent);
  end;
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
  Androidapi.Helpers,
  Androidapi.JNI.Net,
  Androidapi.JNI.ActivityManager;

var
  ServiceReceiver: TJServiceReceiver;
  ARNContext: JContext;
  ARNReceivedIntent: JIntent;
  ServiceObjectID: JNIObject;

procedure ServiceReceiverOnReceiveThreadSwitcher;
begin
  ServiceReceiver.OnReceive(ARNContext, ARNReceivedIntent);
end;

procedure ServiceReceiverOnReceiveNative(PEnv: PJNIEnv; This: JNIObject;
  JNIContext, JNIReceivedIntent: JNIObject); cdecl;
begin
  ARNContext := TJContext.Wrap(JNIContext);
  ARNReceivedIntent := TJIntent.Wrap(JNIReceivedIntent);
  TThread.Synchronize(nil, ServiceReceiverOnReceiveThreadSwitcher);
  ServiceObjectID := This;
end;

procedure RegisterDelphiNativeMethods;
var
  PEnv: PJNIEnv;
  ReceiverClass: JNIClass;
  NativeMethod: JNINativeMethod;
begin
  PEnv := TJNIResolver.GetJNIEnv;
  NativeMethod.Name := 'serviceReceiverOnReceiveNative';
  NativeMethod.Signature :=
    '(Landroid/content/Context;Landroid/content/Intent;)V';
  NativeMethod.FnPtr := @ServiceReceiverOnReceiveNative;
  ReceiverClass := TJNIResolver.GetJavaClassID
    ('com.barisatalay.foreground.ServiceReceiver');
  if ReceiverClass <> nil then
  begin
    PEnv^.RegisterNatives(PEnv, ReceiverClass, @NativeMethod, 1);
    PEnv^.DeleteLocalRef(PEnv, ReceiverClass);
  end;
end;

{ TServiceReceiver }
constructor TJServiceReceiver._Create(Service: TForegroundServis);
begin
  inherited;
  FOwningService := Service;
end;

class function TJServiceReceiver.Create(Service: TForegroundServis)
  : JServiceReceiver;
begin
  Result := inherited Create;
  ServiceReceiver := TJServiceReceiver._Create(Service);
end;

procedure TJServiceReceiver.OnReceive(Context: JContext;
  ReceivedIntent: JIntent);
var
  Cmd: Integer;
begin
  Cmd := ReceivedIntent.getIntExtra
    (StringToJString(TForegroundServis.ID_INT_COMMAND), 0);
  if Cmd = TForegroundServis.CMD_STOP_SERVICE then
  begin
    FOwningService.Running := false;
    FOwningService.GetJService.stopForeground(true);
    FOwningService.GetJService.stopSelf;
  end;
end;

initialization

RegisterDelphiNativeMethods;
{$ENDIF}
end.
