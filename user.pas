unit user;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils,
  SQLite,
  Generics.Collections;

type

  { TUser }

  TUser = class(TObject)
    strict private
      fId: integer;
      fName: String;
      fPass: String;
      fIsAdmin: boolean;
      fToken: String;

      class function _getFromRow(row: TDictionary<String, variant>): TUser; static;
      class procedure _createToken(id: integer); static;
    published // important!
      property id: integer read fId write fId;
      property name: String read fName write fName;
      property pass: String read fPass write fPass;
      property isAdmin: boolean read fIsAdmin write fIsAdmin;
      property token: String read fToken write fToken;
    public
      class var
        currentUser: TUser;

      constructor Create(
        id: integer;
        name: String;
        pass: String;
        isAdmin: boolean;
        token: String
      ); overload; // two constructors
      function ToString: string; override;

      class function insert(user: TUser): integer; static;
      class procedure update(user: TUser); static;
      class procedure updatePass(pass: String; id: integer); static;
      class function getId(name: String; pass: String): integer; static;
      class function get(id: integer): TUser; static;
      class function getAll(txt: String): TList<TUser>; static;
      class function isNameRepeated(name: String; id: integer): boolean; static;
      class procedure delete(id: integer); static;
  end;

implementation

{ TUser }

class function TUser._getFromRow(row: TDictionary<String, variant>): TUser;
begin
  Result := TUser.Create(
    row['id'],
    row['name'],
    row['pass'],
    row['isAdmin'],
    row['token']
  );
end;

class procedure TUser._createToken(id: integer);
const
  SQL = 'UPDATE users SET token = :token WHERE id = :id';
var
  guid: TGUID;
  token: String;
begin
  CreateGUID(guid);
  token := guid.ToString(true); // (without brackets {} = true)
  TSQLite.execSql(SQL, [token, id]);
end;

constructor TUser.Create(
  id: integer;
  name: String;
  pass: String;
  isAdmin: boolean;
  token: String
);
begin
  self.id:=id;
  self.name:=name;
  self.pass:=pass;
  self.isAdmin:=isAdmin;
  self.token:=token;
end;

function TUser.ToString: string;
begin
  //Result:=inherited ToString;
  Result := Format('TUser: {id: %d, name: %s, pass: %s, isAdmin: %s, token: %s}', [
    self.id,
    self.name,
    self.pass,
    BoolToStr(self.isAdmin, True),
    self.token
  ]);
end;

class function TUser.insert(user: TUser): integer;
var
  sql: String;
begin
  sql := 'INSERT INTO users(name, pass, isAdmin) ' +
         'VALUES(:name, :pass, :isAdmin)';
  TSQLite.execSql(sql, [
    user.name,
    user.pass,
    user.isAdmin
  ]);
  sql := 'SELECT MAX(id) FROM users';
  Result := TSQLite.queryScalar(sql);
end;

class procedure TUser.update(user: TUser);
const
  SQL = 'UPDATE users SET ' +
          'name = :name,' +
          'isAdmin = :isAdmin ' +
        'WHERE id = :id';
begin
  TSQLite.execSql(SQL, [
    user.name,
    user.isAdmin,
    user.id
  ]);
  if (user.pass > '') then
    updatePass(user.pass, user.id);
end;

class procedure TUser.updatePass(pass: String; id: integer);
const
  SQL = 'UPDATE users SET ' +
          'pass = :pass ' +
        'WHERE id = :id';
begin
  TSQLite.execSql(SQL, [
    pass,
    id
  ]);
end;

class function TUser.getId(name: String; pass: String): integer;
const
  SQL = 'SELECT id FROM users WHERE name = :name AND pass = :pass';
var
  val: variant;
begin
  val := TSQLite.queryScalar(SQL, [
    name,
    pass
  ]);
  if (val = Null) then
    Result := -1
  else
  begin
    // create new token
    _createToken(val);

    Result := val;
  end;
end;

class function TUser.get(id: integer): TUser;
const
  SQL = 'SELECT id, name, pass, isAdmin, token FROM users WHERE id = :id';
var
  row: TDictionary<String, variant>;
begin
  Result := TUser.Create; // default values
  Result.id := -1;
  row := TSQLite.queryRow(SQL, [id]);
  if (row.Count > 0) then
    Result := _getFromRow(row);
end;

class function TUser.getAll(txt: String): TList<TUser>;
const
  SQL = 'SELECT id, name, pass, isAdmin, "" AS token ' +
        'FROM users ' +
        'WHERE name LIKE :txt';
var
  rows: TList<TDictionary<String, variant>>;
  row: TDictionary<String, variant>;
  user: TUser;
begin
  Result := TList<TUser>.Create;
  rows := TSQLite.query(SQL, ['%' + txt + '%']);
  for row in rows do
  begin
    user := _getFromRow(row);
    Result.Add(user);
  end;
end;

class function TUser.isNameRepeated(name: String; id: integer): boolean;
const
  SQL = 'SELECT EXISTS(SELECT 1 FROM users WHERE name = :name AND id <> :id)';
begin
  Result := TSQLite.queryScalar(SQL, [name, id]);
end;

class procedure TUser.delete(id: integer);
const
  SQL = 'DELETE FROM users WHERE id = :id';
begin
  TSQLite.execSql(SQL, [id]);
end;

end.

