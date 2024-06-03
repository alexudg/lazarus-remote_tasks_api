unit task;

{$mode Delphi}

interface

uses
  Classes, SysUtils, Generics.Collections,
  SQLite;

type

  { TTask }

  TTask = class(TObject)
    strict private
      fId: integer;
      fIdUser: integer;
      fTitle: String;
      fDescription: String;
      fIsDone: boolean;
    published
      property id: integer read fId write fId;
      property idUser: integer read fIdUser write fIdUser;
      property title: String read fTitle write fTitle;
      property description: String read fDescription write fDescription;
      property isDone: boolean read fIsDone write fIsDone;
    public
      constructor Create(
        id: integer;
        idUser: integer;
        title: String;
        description: String;
        isDone: boolean
      ); overload; // two constructors
      function ToString: String; override;

      class function insert(task: TTask): integer; static;
      class procedure update(task: TTask); static;
      class function getAll(idUser: integer; txt: String): TList<TTask>;
      class function get(id: integer): TTask; static;
      class procedure delete(id: integer); static;
  end;

implementation

{ TTask }

constructor TTask.Create(
  id: integer;
  idUser: integer;
  title: String;
  description: String;
  isDone: boolean);
begin
  self.id:=id;
  self.idUser:=idUser;
  self.title:=title;
  self.description:=description;
  self.isDone:=isDone;
end;

function TTask.ToString: String;
begin
  //Result:=inherited ToString;
  Result := Format('TTask: {id: %d, idUser: %d, title: %s, description: %s, isDone: %s}', [
    self.id,
    self.idUser,
    self.title,
    self.description,
    BoolToStr(self.isDone, True)
  ]);
end;

class function TTask.insert(task: TTask): integer;
var
  sql: String;
begin
  sql := 'INSERT INTO tasks(id_user, title, description, isDone) ' +
         'VALUES(:id_user, :title, :description, :isDone)';
  TSQLite.execSql(sql, [
    task.idUser,
    task.title,
    task.description,
    task.isDone
  ]);

  // get new id
  sql := 'SELECT MAX(id) FROM tasks';
  Result := TSQLite.queryScalar(sql);
end;

class procedure TTask.update(task: TTask);
const
  SQL = 'UPDATE tasks SET ' +
           'title = :title,' +
           'description = :description,' +
           'isDone = :isDone ' +
         'WHERE id = :id';
begin
  TSQLite.execSql(SQL, [
    task.title,
    task.description,
    task.isDone,
    task.id
  ]);
end;

class function TTask.getAll(idUser: integer; txt: String): TList<TTask>;
const
  SQL = 'SELECT id, id_user AS idUser, title, description, isDone FROM tasks WHERE idUser = :idUser AND title LIKE :txt';
var
  rows: TList<TDictionary<String, variant>>;
  row: TDictionary<String, variant>;
  task: TTask;
begin
  Result := TList<TTask>.Create;
  rows := TSQLite.query(SQL, [idUser, '%' + txt + '%']);
  for row in rows do
  begin
    task := TTask.Create(
      row['id'],
      row['idUser'],
      row['title'],
      row['description'],
      row['isDone']
    );
    Result.Add(task);
  end;
end;

class function TTask.get(id: integer): TTask;
const
  SQL = 'SELECT id, id_user AS idUser, title, description, isDone ' +
        'FROM tasks ' +
        'WHERE id = :id';
var
  row: TDictionary<String, variant>;
begin
  Result := TTask.Create;
  row := TSQLite.queryRow(SQL, [id]);
  if (row.Count > 0) then
    Result := TTask.Create(
      row['id'],
      row['idUser'],
      row['title'],
      row['description'],
      row['isDone']
    );
end;

class procedure TTask.delete(id: integer);
const
  SQL = 'DELETE FROM tasks WHERE id = :id';
begin
  TSQLite.execSql(SQL, [id]);
end;

end.

