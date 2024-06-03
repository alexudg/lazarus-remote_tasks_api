unit uUsers;

{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  Grids, Generics.Collections, Buttons, StdCtrls, PopupNotifier, Windows,
  user;

type

  { TfrmUsers }

  TfrmUsers = class(TForm)
    barFields: TStatusBar;
    btnDelete: TBitBtn;
    btnCancel: TBitBtn;
    btnInsert: TBitBtn;
    btnSave: TBitBtn;
    btnUpdate: TBitBtn;
    chkIsAdmin: TCheckBox;
    boxPass: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    popup: TPopupNotifier;
    tmrMain: TTimer;
    txtPass: TEdit;
    txtConfirm: TEdit;
    txtName: TLabeledEdit;
    pnlList: TPanel;
    pnlFields: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    Splitter1: TSplitter;
    barList: TStatusBar;
    grid: TStringGrid;
    procedure btnClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure gridSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure tmrMainTimer(Sender: TObject);
  private
    _users: TList<TUser>;
    _id: integer;
    procedure _loadUsers(idSelect: integer = -1);
    procedure _cleanFields;
    procedure _loadFields(row: integer = -1);
    procedure _showPopup(txt: String);
  public
    isChanged: Boolean; // default = false;
  end;

var
  frmUsers: TfrmUsers;

implementation

{$R *.lfm}

{ TfrmUsers }

procedure TfrmUsers.btnClick(Sender: TObject);
var
  idBtn: byte;
  user: TUser;
begin
  idBtn := (Sender as TComponent).Tag;

  // validation if save
  if (idBtn = 1) then
  begin
    txtName.Text:=Trim(txtName.Text);
    if (txtName.Text = '') then
    begin
      txtName.SetFocus;
      _showPopup('Nombre vacío');
      Exit;
    end;

    // name already exists?
    if (TUser.isNameRepeated(txtName.Text, _id)) then
    begin
      txtName.SetFocus;
      _showPopup('El nombre ya existe');
      Exit;
    end;

    // if insert, pass required
    if (_id = -1) then
    begin
      if (txtPass.Text = '') then
      begin
        txtPass.SetFocus;
        _showPopup('Contraseña vacía');
        Exit;
      end;
    end;

    if (txtPass.Text <> txtConfirm.Text) then
    begin
      txtConfirm.Clear;
      txtPass.SetFocus;
      _showPopup('Contraseña y confirmación diferentes');
      Exit;
    end;
  end;


  // cancel|save
  if (idBtn <= 1) then
  begin
    // cancel
    if (idBtn = 0) then
      _loadFields()
    // save
    else
    begin
      user := TUser.Create(
        _id,
        txtName.Text,
        txtPass.Text,
        chkIsAdmin.Checked,
        '' // token no required
      );

      // insert
      if (_id = -1) then
        _id := TUser.insert(user)
      // update
      else
        TUser.update(user);
      _loadUsers(_id);
    end;
    txtPass.Clear;
    txtConfirm.Clear;
    barFields.Panels[0].Text:='Observando usuario seleccionado';
  end;

  // enable|disable controls
  pnlList.Visible:=idBtn <= 1;
  grid.Enabled:=idBtn <= 1;
  pnlFields.Visible:=idBtn >= 2;
  txtName.Enabled:=idBtn >= 2;
  chkIsAdmin.Enabled:=idBtn >= 2;
  boxPass.Visible:=idBtn >= 2;

  // update|insert
  if (idBtn >= 2) then
  begin
    // update
    if (idBtn = 2) then
    begin
      _id := _users[grid.Row - 1].id;
      barFields.Panels[0].Text:='Modificando usuario seleccionado';
    end
    // insert
    else
    begin
      _id := -1;
      _cleanFields();
      barFields.Panels[0].Text:='Agregando nuevo usuario';
    end;
  end;
end;

procedure TfrmUsers.btnDeleteClick(Sender: TObject);
var
  i, id: integer;
begin
  i := grid.Row - 1;
  id := _users[i].id;

  // is same user
  if (id = TUser.currentUser.id) then
  begin
    _showPopup('No esta permitido auto-eliminar tu usuario');
    Exit;
  end;

  // is super-admin?
  if (id = 0) then
  begin
    _showPopup('No esta permitido eliminar al super-admin');
    Exit;
  end;

  if (MessageDlg('CONFIRMAR', '¿Estás segur@ de eliminar el usuario seleccionado?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
  begin
    TUser.delete(id);
    if (_users.Count -1 >= i + 1) then
      id := _users[i + 1].id
    else
      id := _users[i - 1].id;
    _loadUsers(id);
  end;
end;

procedure TfrmUsers.FormShow(Sender: TObject);
begin
  _loadUsers();
  btnCancel.Click;
end;

procedure TfrmUsers.gridSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
begin
  if (_users <> nil) then
    _loadFields(aRow);
end;

procedure TfrmUsers.tmrMainTimer(Sender: TObject);
begin
  tmrMain.Enabled:=false;
  popup.Hide;
end;

procedure TfrmUsers._loadUsers(idSelect: integer);
var
  i: integer;
begin
  _users := TUser.getAll('');

  // show|hide buttons
  btnUpdate.Visible:=_users.Count > 0;
  btnDelete.Visible:=_users.Count > 0;

  // fill grid
  with (grid) do
  begin
    RowCount := _users.Count + 1;

    for i:=0 to _users.Count - 1 do
    begin
      Cells[0, i + 1] := _users[i].name;
      Cells[1, i + 1] := BoolToStr(_users[i].isAdmin, True); // 'True'|'False'

      if (idSelect > -1) and (_users[i].id = idSelect) then
        Row := i + 1;
    end;
  end;

  // show count
  with (barList.Panels[0]) do
  begin
    Text := _users.Count.ToString() + ' usuario';
    if (_users.Count <> 1) then
      Text := Text + 's';
  end;

  // create current user temp
  TUser.currentUser := _users[0];
end;

procedure TfrmUsers._cleanFields;
begin
  txtName.Clear;
  chkIsAdmin.Checked:=False;
end;

procedure TfrmUsers._loadFields(row: integer = -1);
var
  user: TUser;
begin
  if (row = -1) then
    row := grid.Row;
  user := _users[row - 1];
  txtName.Text:=user.name;
  chkIsAdmin.Checked:=user.isAdmin;
end;

procedure TfrmUsers._showPopup(txt: String);
begin
  tmrMain.OnTimer(tmrMain);
  popup.Text:=txt;
  popup.ShowAtPos(self.Left, self.Top);
  tmrMain.Enabled:=true;
end;

end.

