unit uconfig;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, ComCtrls,
  Printers, // printer4lazarus
  config;

type

  { TfrmConfig }

  TfrmConfig = class(TForm)
    btnCancel: TBitBtn;
    btnUpdate: TBitBtn;
    btnSave: TBitBtn;
    chkIsApiEnable: TCheckBox;
    bar: TStatusBar;
    boxApi: TGroupBox;
    comboPrinters: TComboBox;
    boxPrinters: TGroupBox;
    Label1: TLabel;
    Panel1: TPanel;
    txtApiPort: TEdit;
    procedure btnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    _config: TConfig;
    procedure _loadFields;
    procedure _loadPrinters;
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
      // same _config at create form
      if (comboPrinters.ItemIndex = 0) then
        _config.printerName:=''
      else
        _config.printerName:=comboPrinters.Text;
      _config.isApiEnable:=chkIsApiEnable.Checked;
      _config.apiPort:=port;

      TConfig.update(_config);
      isChanged := true;
    end;
    bar.Panels[0].Text:='Observando configuración';
  end;

  // enable|disable controls
  btnUpdate.Visible:=idBtn <= 1;
  btnCancel.Visible:=idBtn = 2;
  btnSave.Visible:= idBtn = 2;
  comboPrinters.Enabled:=idBtn = 2;
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
  _loadPrinters();
  _config := TConfig.get();
  btnCancel.Click;
end;

procedure TfrmConfig._loadFields;
var
  i: byte;
begin
  // select saved printer
  if _config.printerName = '' then
    comboPrinters.ItemIndex:=0
  else
  begin
    for i:=0 to comboPrinters.Items.Count do
    begin
      if comboPrinters.Items[i] = _config.printerName then
      begin
        comboPrinters.ItemIndex:=i;
        Break;
      end;
    end;
  end;

  chkIsApiEnable.Checked:=_config.isApiEnable;
  txtApiPort.Text:=_config.apiPort.ToString();
end;

procedure TfrmConfig._loadPrinters;
var
  printerName: String;
begin
  comboPrinters.Items.Add('<ninguna>');
  Printer.Refresh;
  for printerName in Printer.Printers do
  begin
    comboPrinters.Items.Add(printerName);
  end;
end;

end.

