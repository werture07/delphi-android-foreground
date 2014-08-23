unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  ServiceU, FMX.Layouts, FMX.Objects, FMX.Edit

  {$IFDEF ANDROID}
  , FMX.Helpers.Android
  {$ENDIF}
  ;

type
  TMainScreen = class(TForm)
    ForegroundServis1: TForegroundServis;
    GridPanelLayout2: TGridPanelLayout;
    ServisStartBut: TButton;
    ServisStopBut: TButton;
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure ServisStopButClick(Sender: TObject);
    procedure ServisStartButClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainScreen: TMainScreen;

implementation

{$R *.fmx}

procedure TMainScreen.FormKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkHardwareBack then
  begin
    Key := 0;
    {$IFDEF ANDROID}SharedActivity.moveTaskToBack(True);{$ENDIF}
  end;
end;

procedure TMainScreen.ServisStartButClick(Sender: TObject);
begin
  ForegroundServis1.StartService;
end;

procedure TMainScreen.ServisStopButClick(Sender: TObject);
begin
  ForegroundServis1.StopService;
end;

end.
