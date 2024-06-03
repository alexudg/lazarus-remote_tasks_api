unit uconfig;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, ComCtrls, config;

type

  { TfrmConfig }

  TfrmConfig = class(TForm)
    btnCancel: TBitBtn;
    btnUpdate: TBitBtn;
    btnSave: TBitBtn;
    chkIsApiEnable: TCheckBox;
    bar: TStatusBar;
    txtApiPort: TEdit;
    Label1: TLabel;
    Panel1: TPanel;
    procedure btnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    _config: TConfig;
    procedure _loadFields;
  public
    isChanged: boolean; // default=false
  end;

var
  frmConfig: TfrmConfig;

implementation

{$R *.lfm}

{ TfrmConfig }

procedure TfrmConfig.btnClick(Sender: TObject);
var
  idBtn: byte;
  port: integer;
begin
  idBtn := (Sender as TComponent).Tag;

  // save: validation
  if (idBtn = 1) then
  begin
    if (not TryStrToInt(txtApiPort.Text, port) or (port < 80) or (port > 65535)) then
    begin
      txtApiPort.SetFocus;
      MessageDlg('ERROR', 'Puerto no válido', TMsgDlgType.mtError, [], 0);
      Exit;
    end;
  end;

  // cancel | save
  if (idBtn <= 1) then
  begin
    // cancel
    if (idBtn = 0) then
      _loadFields()
    // save
    else
    begin
      _config := TConfig.create(
        -1, // id, not used
        chkIsApiEnable.Checked,
        port
      );
      TConfig.update(_config);
      isChanged := true;
    end;
    bar.Panels[0].Text:='Observando configuración';
  end;

  // enable|disable controls
  btnUpdate.Visible:=idBtn <= 1;
  btnCancel.Visible:=idBtn = 2;
  btnSave.Visible:= idBtn = 2;
  chkIsApiEnable.Enabled:=idBtn = 2;
  txtApiPort.Enabled:=idBtn = 2;

  // edit
  if (idBtn = 2) then
  begin
    bar.Panels[0].Text:='Editando configuración';
  end;
end;

procedure TfrmConfig.FormCreate(Sender: TObject);
begin
  _config := TConfig.get();
  btnCancel.Click;
end;

procedure TfrmConfig._loadFields;
begin
  chkIsApiEnable.Checked:=_config.isApiEnable;
  txtApiPort.Text:=_config.apiPort.ToString();
end;

end.

