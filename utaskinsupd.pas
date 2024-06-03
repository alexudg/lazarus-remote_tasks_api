unit utaskInsUpd;

{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  PopupNotifier, Task;

type

  { TfrmTaskInsUpd }

  TfrmTaskInsUpd = class(TForm)
    btnOk: TButton;
    btnCancel: TButton;
    chkIsDone: TCheckBox;
    Label1: TLabel;
    memoDescription: TMemo;
    popup: TPopupNotifier;
    tmrMain: TTimer;
    txtTitle: TLabeledEdit;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrMainTimer(Sender: TObject);
  private
    procedure _showPopup(txt: String);
  public
    task: TTask;
  end;

var
  frmTaskInsUpd: TfrmTaskInsUpd;

implementation

{$R *.lfm}

{ TfrmTaskInsUpd }

procedure TfrmTaskInsUpd.btnCancelClick(Sender: TObject);
begin
  self.Close;
end;

procedure TfrmTaskInsUpd.btnOkClick(Sender: TObject);
begin
  // validate
  txtTitle.Text:=Trim(txtTitle.Text);
  if (txtTitle.Text = '') then
  begin
    txtTitle.SetFocus;
    _showPopup('Titulo vacío');
    Exit;
  end;

  memoDescription.Text:=Trim(memoDescription.Text);
  if (memoDescription.Text = '') then
  begin
    memoDescription.SetFocus;
    _showPopup('Descripción vacía');
    Exit;
  end;

  task.title:=txtTitle.Text;
  task.description:=memoDescription.Text;
  task.isDone:=chkIsDone.Checked;
  self.ModalResult:=mrOk;
end;

procedure TfrmTaskInsUpd.FormShow(Sender: TObject);
begin
  if (task.id = -1) then
    self.Caption:='Agregando nueva tarea'
  else
    self.Caption:='Modificando tarea';
  txtTitle.Text:=task.title;
  memoDescription.Text:=task.description;
  chkIsDone.Checked:=task.isDone;
  chkIsDone.Enabled:=task.id > -1;
end;

procedure TfrmTaskInsUpd.tmrMainTimer(Sender: TObject);
begin
  tmrMain.Enabled:=false;
  popup.Hide;
end;

procedure TfrmTaskInsUpd._showPopup(txt: String);
begin
  tmrMain.OnTimer(tmrMain);
  popup.Text:=txt;
  popup.ShowAtPos(self.Left, self.Top);
  tmrMain.Enabled:=true;
end;

end.

