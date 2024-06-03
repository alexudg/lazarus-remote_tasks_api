unit uLogin;

{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  PopupNotifier, User;

type

  { TfrmLogin }

  TfrmLogin = class(TForm)
    btnOk: TButton;
    btnClose: TButton;
    popup: TPopupNotifier;
    tmrMain: TTimer;
    txtName: TEdit;
    txtPass: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure btnCloseClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrMainTimer(Sender: TObject);
  private
    procedure _showPopup(txt: String);
  public

  end;

var
  frmLogin: TfrmLogin;

implementation

{$R *.lfm}

{ TfrmLogin }

procedure TfrmLogin.btnCloseClick(Sender: TObject);
begin
  self.Close;
end;

procedure TfrmLogin.btnOkClick(Sender: TObject);
var
  id: integer;
begin
  // validate
  txtName.Text:=Trim(txtName.Text);
  if (txtName.Text = '') then
  begin
    txtName.SetFocus;
    _showPopup('Usuario vacío');
    Exit;
  end;
  if (txtPass.Text = '') then
  begin
    txtPass.SetFocus;
    _showPopup('Contraseña vacía');
    Exit;
  end;

  id := TUser.getId(txtName.Text, txtPass.Text);
  if (id = -1) then
  begin
    txtPass.Clear;
    txtName.SetFocus;
    _showPopup('Usuario o contraseña incorrecta');
    Exit;
  end;

  TUser.currentUser := TUser.get(id);
  self.ModalResult:=mrOk;
end;

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  txtName.Text:='admin';
  txtPass.Text:='1';
end;

procedure TfrmLogin.FormShow(Sender: TObject);
begin
  txtName.SetFocus;
end;

procedure TfrmLogin.tmrMainTimer(Sender: TObject);
begin
  tmrMain.Enabled:=false;
  popup.Hide;
end;

procedure TfrmLogin._showPopup(txt: String);
begin
  popup.Text:=txt;
  tmrMain.OnTimer(tmrMain);
  popup.ShowAtPos(self.Left, self.Top);
  tmrMain.Enabled:=true;
end;

end.

