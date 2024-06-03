unit api;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils,
  Windows,
  Generics.Collections,
  fpHttpApp,
  httpRoute,
  httpDefs,
  User,
  Task,
  fpJson,
  fpJsonRtti{,
  base64};

type
  TPrintTask = procedure(task: TTask) of object; // for callback from frmMain

  { TServerThread }
  TServerThread = class(TThread)
    protected
      procedure Execute; override;
    public
      constructor Create(port: Word);
  end;

  { TApi }

  // static
  TApi = class
    private
      class var
        server: TServerThread;
      class procedure _onShowRequestException(AResponse: TResponse; AnException: Exception; var handled: boolean);

      class procedure _print(txt: String); static;

      class procedure _getRoot(req: TRequest; res: TResponse); static;

      class procedure _getUsers(req: TRequest; res: TResponse); static;
      class procedure _getUser(req: TRequest; res: TResponse); static;
      class procedure _getUserFromId(req: TRequest; res: TResponse); static;

      class procedure _getTasks(req: TRequest; res: TResponse); static;
      class procedure _getTask(req: TRequest; res: TResponse); static;
      class procedure _insertTask(req: TRequest; res: TResponse); static;
      class procedure _updateTask(req: TRequest; res: TResponse); static;
      class procedure _deleteTask(req: TRequest; res: TResponse); static;
      class procedure _printTask(req: TRequest; res: TResponse); static;

      class procedure _pageNotFound(req: TRequest; res: TResponse); static;
    public
      class var
        isActive: Boolean;
        task: TTask;

        // callBack function
        printTask: TPrintTask;

      class procedure start(port: Word); static;
      class procedure stop; static;

  end;

implementation

{ TServerThread }

procedure TServerThread.Execute;
begin
  fpHttpApp.Application.Run; // here stop, next line to stop service
  TApi._print('after server Run');
end;

constructor TServerThread.Create(port: Word);
begin
  fpHttpApp.Application.Port:=port;
  inherited Create(false);
  FreeOnTerminate:=true;
  TApi.isActive:=true;
end;

{ TApi }

class procedure TApi._onShowRequestException(AResponse: TResponse;
  AnException: Exception; var handled: boolean);
begin
  TApi._print(AnException.Message);
  handled := True;
end;

class procedure TApi._print(txt: String);
begin
  Windows.OutputDebugString(PChar(txt));
end;

class procedure TApi._getRoot(req: TRequest; res: TResponse);
var
  json: TJsonObject;
begin
  res.ContentType:='application/json';
  //res.Code:=200;
  json := TJsonObject.Create;
  json.Add('status', 'welcome to api');
  res.Content:=json.AsJSON;
  res.SendContent;

  FreeAndNil(json);
end;

class procedure TApi.start(port: Word);
begin
  TApi._print('server.create()');
  TApi.server := TServerThread.Create(port);
end;

class procedure TApi.stop;
begin
  TApi._print('Terminate: ' + BoolToStr(fpHttpApp.Application.Terminated));
  fpHttpApp.Application.Terminate;
  TApi._print('Terminate: ' + BoolToStr(fpHttpApp.Application.Terminated));
  Sleep(3000);
  TApi.isActive:=false;
  TApi._print('Terminate: ' + BoolToStr(fpHttpApp.Application.Terminated));
end;

// GET /users
class procedure TApi._getUsers(req: TRequest; res: TResponse);
var
  users: TList<TUser>;
  user: TUser;
  js: fpJsonRtti.TJsonStreamer;
  jArray: TJsonArray;
begin
  jArray := TJsonArray.Create; // []
  js := TJsonStreamer.Create(nil);
  try
    users := TUser.getAll('');
    for user in users do
    begin
      jArray.Add(js.ObjectToJSON(user));
    end;
  finally
    res.ContentType:='application/json';
    res.Content:=jArray.AsJSON;
    res.SendContent;

    FreeAndNil(js);
    FreeAndNil(jArray);
    FreeAndNil(users);
    FreeAndNil(user);
  end;
end;

// GET /users/:id
class procedure TApi._getUser(req: TRequest; res: TResponse);
var
  id: integer;
  user: TUser;
  js: fpJsonRtti.TJsonStreamer;
begin
  js := TJsonStreamer.Create(nil);
  user := TUser.Create; // default values (id = -1)
  user.id:=-1;
  try
    if (req.RouteParams['id'] > '') then
    begin
      id := StrToInt(req.RouteParams['id']);
      user := TUser.get(id);
    end;
  finally
    res.ContentType:='application/json';
    res.Content := js.ObjectToJSONString(user);
    res.SendContent;

    FreeAndNil(js);
    FreeAndNil(user);
  end;
end;


// POST api/users/id
{
  id: -1,
  name: "<name>",
  pass: "<pass>",
  isAdmin: false,
  token: ""
}
class procedure TApi._getUserFromId(req: TRequest; res: TResponse);
var
  js: fpJsonRtti.TJsonDeStreamer;
  json: TJsonObject;
  userStr: String;
  user: TUser;
  id: integer;
begin
  js := fpJsonRtti.TJSONDeStreamer.Create(nil);
  json := TJsonObject.Create;
  user := TUser.Create;
  try
    try
      // read body
      userStr := req.Content;

      // str to json
      json := fpJson.GetJSON(userStr) as TJsonObject;

      // json to object
      js.JSONToObject(json, user);

      // get id from name-pass
      id := TUser.getId(user.name, user.pass);
    except
      // -1 = error
      id := -1;
    end;
  finally
    // now redirect to _getUser() GET api/users/:id
    req.RouteParams['id'] := id.ToString();
    TApi._getUser(req, res);

    // clear
    userStr := '';
    FreeAndNil(json);
    FreeAndNil(js);
    FreeAndNil(user);
  end;
end;

// GET api/tasks?idUser=x
class procedure TApi._getTasks(req: TRequest; res: TResponse);
var
  sArray: TStringArray;
  idUser: integer;
  tasks: TList<TTask>;
  task: TTask;
  js: fpJsonRtti.TJsonStreamer;
  jArray: TJsonArray;
begin
  jArray := TJsonArray.Create;
  js := TJsonStreamer.Create(nil);

  try
    // get idUser   /api
    if (req.QueryFields.Count > 0) then
    begin
      // idUser=x
      sArray := req.QueryFields[0].Split('=');
      idUser := StrToInt(sArray[1]);
      tasks := TTask.getAll(idUser, '');
      for task in tasks do
      begin
        jArray.Add(js.ObjectToJSON(task));
      end;
    end;
  finally
    res.ContentType:='application/json';
    res.Content := jArray.AsJSON;
    res.SendContent;

    FreeAndNil(js);
    FreeAndNil(jArray);
    FreeAndNil(tasks);
    FreeAndNil(task);
  end;
end;

// GET /tasks/:id
class procedure TApi._getTask(req: TRequest; res: TResponse);
var
  id: integer;
  task: TTask;
  js: fpJsonRtti.TJsonStreamer;
begin
  js := TJsonStreamer.Create(nil);

  try
    if (req.RouteParams['id'] > '') then
    begin
      id := StrToInt(req.RouteParams['id']);
      task := TTask.get(id);
    end
    else
      task := TTask.Create; // default values (id = -1)
  finally
    res.ContentType:='application/json';
    res.Content := js.ObjectToJSONString(task);
    res.SendContent;

    FreeAndNil(js);
    FreeAndNil(task);
  end;
end;

// POST /tasks
{
  id: -1,
  idUser: n,
  title: "<title>",
  description: "<description>",
  isDone: false
}
class procedure TApi._insertTask(req: TRequest; res: TResponse);
var
  js: fpJsonRtti.TJSONDeStreamer;
  taskStr: String;
  json: TJsonObject;
  task: TTask;
  status: String;
begin
  js := fpJsonRtti.TJSONDeStreamer.Create(nil);
  json := TJsonObject.Create;
  task := TTask.Create;
  try
    try
      // read body
      taskStr := req.Content;

      // str to json
      json := fpJson.GetJSON(taskStr) as TJsonObject;

      // json to object
      js.JSONToObject(json, task);

      // insert & get new id
      status := TTask.insert(task).ToString();
    except
      // -1 = error
      status := 'error';
    end;
  finally
    res.ContentType:='application/json';

    // re-use jsonObject to response
    json := TJsonObject.Create;
    json.Add('status', status);
    res.Content:=json.AsJSON;
    res.SendContent;

    taskStr := '';
    FreeAndNil(json);
    FreeAndNil(js);
    FreeAndNil(task);
  end;
end;

// PUT /tasks
{
  id: n,
  idUser: n,
  title: "<title>",
  description: "<description>",
  isDone: true|false
}
class procedure TApi._updateTask(req: TRequest; res: TResponse);
var
  js: fpJsonRtti.TJSONDeStreamer;
  taskStr: String;
  json: TJsonObject;
  task: TTask;
  status: String;
begin
  js := fpJsonRtti.TJSONDeStreamer.Create(nil);
  json := TJsonObject.Create;
  task := TTask.Create;
  try
    try
      // read body
      taskStr := req.Content;

      // str to json
      json := fpJson.GetJSON(taskStr) as TJsonObject;

      // json to object
      js.JSONToObject(json, task);

      _print(task.ToString());

      // update
      TTask.update(task);
      status := 'updated';
    except
      // false = error
      status := 'error';
    end;
  finally
    res.ContentType:='application/json';

    // re-use jsonObject to response
    json := TJsonObject.Create;
    json.Add('status', status);
    res.Content:=json.AsJSON;
    res.SendContent;

    taskStr := '';
    FreeAndNil(json);
    FreeAndNil(js);
    FreeAndNil(task);
  end;
end;


// DELETE /tasks/:id
class procedure TApi._deleteTask(req: TRequest; res: TResponse);
var
  id: integer;
  status: String;
  json: TJsonObject;
begin
  try
    try
      if (req.RouteParams['id'] > '') then
      begin
        id := StrToInt(req.RouteParams['id']);
        TTask.delete(id);
        status := 'deleted';
      end
      else
        status := 'error';
    except
      status := 'error';
    end;
  finally
    res.ContentType:='application/json';
    json := TJsonObject.Create;
    json.Add('status', status);
    res.Content:=json.AsJSON;
    res.SendContent;

    FreeAndNil(json);
  end;
end;

// GET api/printtask/:id
class procedure TApi._printTask(req: TRequest; res: TResponse);
var
  id: integer;
  task: TTask;
  status: String;
  json: TJsonObject;
begin
  try
    try
      if (req.RouteParams['id'] > '') then
      begin
        id := StrToInt(req.RouteParams['id']);
        task := TTask.get(id);
        printTask(task); // callback from frmMain on initialization
        status := 'printed';
      end
      else
        status := 'error';
    except
      status := 'error';
    end;
  finally
    res.ContentType:='application/json';
    json := TJsonObject.Create;
    json.Add('status', status);
    res.Content:=json.AsJSON;
    res.SendContent;

    FreeAndNil(task);
    FreeAndNil(json);
  end;
end;

// ANY *
class procedure TApi._pageNotFound(req: TRequest; res: TResponse);
var
  json: TJsonObject;
begin
  res.ContentType:='application/json';
  res.Code:=404;
  json := TJsonObject.Create;
  json.Add('status', 'page not found');
  res.Content:=json.AsJSON;
  res.SendContent;

  FreeAndNil(json);
end;

begin
  Windows.OutputDebugString(PChar('TApi initialization'));

  // API app
  httpRoute.HTTPRouter.RegisterRoute('/api', rmGet, TApi._getRoot);

  httpRoute.HTTPRouter.RegisterRoute('/api/users', rmGet, TApi._getUsers);
  httpRoute.HTTPRouter.RegisterRoute('/api/users/:id', rmGet, TApi._getUser);
  httpRoute.HTTPRouter.RegisterRoute('/api/users/id', rmPost, TApi._getUserFromId);

  httpRoute.HTTPRouter.RegisterRoute('/api/tasks', rmGet, TApi._getTasks);
  httpRoute.HTTPRouter.RegisterRoute('/api/tasks/:id', rmGet, TApi._getTask);
  httpRoute.HTTPRouter.RegisterRoute('/api/tasks', rmPost, TApi._insertTask);
  httpRoute.HTTPRouter.RegisterRoute('/api/tasks', rmPut, TApi._updateTask);
  httpRoute.HTTPRouter.RegisterRoute('/api/tasks/:id', rmDelete, TApi._deleteTask);

  httpRoute.HTTPRouter.RegisterRoute('api/printtask/:id', rmGet, TApi._printTask);

  httpRoute.HTTPRouter.RegisterRoute('*', TRouteMethod.rmAll, TApi._pageNotFound, true);

  fpHttpApp.Application.Title:='API Tasks';
  fpHttpApp.Application.LegacyRouting := false; // default=false
  fpHttpApp.Application.Threaded:=true;
  fpHttpApp.Application.Initialize;
  //fpHttpApp.Application.Run; // freeze if uncomment, solution: run into thread
end.

