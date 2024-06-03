unit umain;

{
  * author: Alejandro Ramirez Macias
  * email: alexudg@gmail.com
  * date: may 2024
  * ide: lazarus 3.2
  * dependences:
    - printer4lazarus
}

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, Buttons, Grids, Windows, Api, Config, uConfig,
  WinSock, uUsers, uLogin, User, Task, Generics.Collections, uTaskInsUpd,
  Printers; // printer4lazarus

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnDelete: TBitBtn;
    btnCloseSession: TBitBtn;
    btnPrint: TBitBtn;
    btnInsert: TBitBtn;
    btnUpdate: TBitBtn;
    grid: TStringGrid;
    menuGeneral: TMenuItem;
    menuConfig: TMenuItem;
    MenuItem2: TMenuItem;
    menuMain: TMainMenu;
    bar: TStatusBar;
    pnlTop: TPanel;
    procedure btnCloseSessionClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnInsUpdClick(Sender: TObject);
    procedure btnPrintClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    function getIpLocal: string;
    procedure menuGeneralClick(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure menuPrinterClick(Sender: TObject);
  private
    _config: TConfig;
    _tasks: TList<TTask>;
    procedure _loadMobileService;
    procedure _loadTasks(idSelect: integer = -1);
  public
    function printTask(task: TTask): integer;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.btnCloseSessionClick(Sender: TObject);
var
  i: integer;
  mr: TModalResult;
begin
  // hide menu
  for i:=0 to menuMain.Items.Count - 1 do
  begin
    menuMain.Items[i].Visible:=False;
  end;
  pnlTop.Hide;
  grid.Hide;
  bar.Hide;

  // show input
  frmLogin := TfrmLogin.Create(nil);
  mr := frmLogin.ShowModal;
  FreeAndNil(frmLogin);

  if (mr = mrOk) then
  begin
    for i:=0 to menuMain.Items.Count - 1 do
    begin
      // config
      if (i > 0) or (TUser.currentUser.isAdmin) then
        menuMain.Items[i].Visible:=true;
    end;
    pnlTop.Show;
    grid.Show;
    with (bar.Panels[0]) do
    begin
      Text:='Usuario: ' + TUser.currentUser.name;
      Width := Canvas.TextWidth(Text) + 8;
    end;
    bar.Show;
    _loadTasks();
  end
  else
    Application.Terminate;
end;

procedure TfrmMain.btnDeleteClick(Sender: TObject);
var
  i, id: integer;
begin
  if (MessageDlg('CONFIRMAR', '¿Estás segur@ de eliminar la tarea seleccionada?', TMsgDlgType.mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
  begin
    i := grid.Row - 1;
    id := _tasks[i].id;
    TTask.delete(id);
    if (_tasks.Count - 1 > 0) then
    begin
      if (_tasks.Count - 1 >= i + 1) then
        id := _tasks[i + 1].id
      else
        id := _tasks[i - 1].id;
    end
    else
      id := -1;
    _loadTasks(id);
  end;
end;

procedure TfrmMain.btnInsUpdClick(Sender: TObject);
var
  isInsert: boolean;
  task: TTask;
  mr: TModalResult;
begin
  isInsert := (Sender as TComponent).Tag = 3;
  frmTaskInsUpd := TfrmTaskInsUpd.Create(nil);
  if (isInsert) then
  begin
    task := TTask.Create(
      -1,
      TUser.currentUser.id,
      '', // title
      '', // description
      false
    );
  end
  else
    task := _tasks[grid.Row - 1];
  frmTaskInsUpd.task := task;
  mr := frmTaskInsUpd.ShowModal;
  FreeAndNil(frmTaskInsUpd);


  if (mr = mrOk) then
  begin
    if (isInsert) then
      task.id:=TTask.insert(task)
    else
      TTask.update(task);
    _loadTasks(task.id);
  end;
end;

procedure TfrmMain.btnPrintClick(Sender: TObject);
begin
  if (printTask(_tasks[grid.Row - 1]) = -1) then
    MessageDlg('ERROR', 'Impresora no encontrada', mtError, [], 0);
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  _loadMobileService();
  btnCloseSession.Click;
end;

function TfrmMain.getIpLocal: string;
{
type
  TaPInAddr = array [0..10] of WinSock.PInAddr; // ^TInAddr
  PaPInAddr = ^TaPInAddr;
}
var
  {
  phe: WinSock.PHostEnt; // ^THostEnt
  pptr: PaPInAddr;
  buffer: array [0..63] of Ansichar;
  i: Integer;
  wsaData: WinSock.TWSAData;
  }
  addr: WinSock.TSockAddrIn;
  phe: WinSock.PHostEnt;
  hostName: array [0..windows.MAX_COMPUTERNAME_LENGTH] of Char;
  socketData: WinSock.TWSAData;
begin
  {
  Result := '';
  WinSock.WSAStartup($101, wsaData);
  WinSock.GetHostName(buffer, SizeOf(buffer));
  phe := WinSock.GetHostByName(buffer);
  if (phe = nil) then
    Exit;
  pptr := PaPInAddr(phe^.h_addr_list);
  i := 0;
  while (pptr^[i] <> nil) do
  begin
    Result := StrPas(WinSock.inet_ntoa(pptr^[i]^));
    Inc(i);
  end;
  WinSock.WSACleanup;
  }
  Result := '127.0.0.1';
  if (WinSock.WSAStartup($101, socketData) = 0) then
  begin
    if (WinSock.gethostname(hostName, Windows.MAX_COMPUTERNAME_LENGTH) = WinSock.SOCKET_ERROR{-1}) then
      Exit;

    phe := WinSock.gethostbyname(hostName);
    if (phe = nil) then
      Exit;

    addr.sin_addr.S_addr := LongInt(pLongint(phe^.h_addr_list^)^);

    Result := WinSock.inet_ntoa(addr.sin_addr);
  end;
end;

procedure TfrmMain.menuGeneralClick(Sender: TObject);
var
  isChanged: boolean;
begin
  frmConfig := TfrmConfig.Create(nil);
  frmConfig.ShowModal;
  isChanged := frmConfig.isChanged;
  FreeAndNil(frmConfig);

  if (isChanged) then
  begin
    _loadMobileService();
  end;
end;

procedure TfrmMain.MenuItem2Click(Sender: TObject);
var
  isChanged: boolean;
begin
  frmUsers := TfrmUsers.Create(nil);
  frmUsers.ShowModal;
  isChanged := frmUsers.isChanged;
  FreeAndNil(frmUsers);

  if (isChanged) then
  begin
    //_loadCurrentUser();
  end;
end;

procedure TfrmMain.menuPrinterClick(Sender: TObject);
begin
  //
end;

procedure TfrmMain._loadMobileService;
begin
  _config := TConfig.get();
  if (TApi.isActive) then
  begin
    TApi.stop;
  end;

  if (_config.isApiEnable) then
  begin
    TApi.start(_config.apiPort);
    bar.Panels[2].Text:='Servicio para moviles: ' + getIpLocal() + ':' + _config.apiPort.ToString();
  end
  else
  begin
    bar.Panels[2].Text:='Servicio para moviles: DESACTIVADO';
  end;
end;

procedure TfrmMain._loadTasks(idSelect: integer = -1);
var
  i: integer;
begin
  _tasks := TTask.getAll(TUser.currentUser.id, '');

  // show|hide buttons
  btnUpdate.Visible:=_tasks.Count > 0;
  btnDelete.Visible:=_tasks.Count > 0;
  btnPrint.Visible:=_tasks.Count > 0;

  with (grid) do
  begin
    RowCount := _tasks.Count + 1;
    for i:=0 to _tasks.Count - 1 do
    begin
      Cells[0, i + 1] := _tasks[i].title;
      Cells[1, i + 1] := _tasks[i].description;
      Cells[2, i + 1] := BoolToStr(_tasks[i].isDone, True);
      if (_tasks[i].id = idSelect) then
        Row := i + 1;
    end;
    AutoSizeColumns;
  end;


  // show count
  with (bar.Panels[1]) do
  begin
    Text := _tasks.Count.ToString() + ' tarea';
    if (_tasks.Count <> 1) then
      Text := Text + 's';
    Width := bar.Canvas.TextWidth(Text) + 8;
  end;
end;

function TfrmMain.printTask(task: TTask): integer;
var
  config: TConfig;
  x, y, middle, h: integer;
  txt: String;
begin
  Windows.OutputDebugString(PChar('printTask: ' + task.ToString));

  config := TConfig.get();
  if (config.printerName = '') then
  begin
    Result := -1; // printer not found
    Exit;
  end;

  // (Printers)
  with (Printer) do
  begin
    Refresh;
    SetPrinter(config.printerName);
    BeginDoc;
    Canvas.Font.Name := 'Arial';
    Canvas.Font.Size := 10;
    Canvas.Font.Color := $0;
    x:=0;
    y:=0;
    middle := PageWidth div 2;
    h := Abs(Printer.Canvas.Font.Height); // negative
    {
    Canvas.TextOut(x, y, '|');
    x := middle - (Canvas.TextWidth('|') div 2);
    Canvas.TextOut(x, y, '|');
    x := Printer.PageWidth - Canvas.TextWidth('|');
    Canvas.TextOut(x, y, '|');
    }
    txt:='RECORDATORIO DE TAREA';
    x := middle - Canvas.TextWidth(txt) div 2;
    Canvas.TextOut(x, y, txt);

    x := 0;
    y := h * 2;
    txt := 'Titulo: ' + task.title;
    Canvas.TextOut(x, y, txt);
    y := y + h;
    txt := 'Descripción: ' + task.title;
    Canvas.TextOut(x, y, txt);
    y := y + h;
    txt := 'Hecha: ' + BoolToStr(task.isDone, 'SI', 'NO');
    Canvas.TextOut(x, y, txt);
    y := y + h;
    txt := '.';
    Canvas.TextOut(x, y, txt);
    EndDoc;
  end;
  Result := 0; // success
end;

initialization
   Windows.OutputDebugString(PChar('frmMain initialization'));
   TApi.printTask:=TfrmMain.printTask;
end.

