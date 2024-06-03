program api_ui;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  printer4lazarus, // Printer
  umain, api, sqlite, config, uconfig, user, uUsers,
  uLogin, task, utaskInsUpd,
  Windows;

{$R *.res}

begin
  Forms.Application.Scaled:=True;
  Windows.OutputDebugString(PChar('project initialization'));

  // UI app
  Forms.RequireDerivedFormResource:=True;
  Forms.Application.Scaled:=True;
  Forms.Application.Initialize;
  Forms.Application.CreateForm(TfrmMain, frmMain);
  Forms.Application.Run;
end.

