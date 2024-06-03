unit sqlite;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections,
  SQLite3Conn,
  SQLDB,
  SQLDBLib,
  Windows;

type

  { TSQLite }

  TSQLite = class
    private
      class var
        _lib: TSQLDBLibraryLoader;
        _con: TSQLite3Connection;
        _qry: TSQLQuery;
        _trs: TSQLTransaction;
    public
      class function queryScalar(sql: String; params: TArray<variant> = nil): variant; static;
      class function queryRow(sql: String; params: TArray<variant> = nil): TDictionary<String, variant>; static;
      class function query(sql: String; params: TArray<variant> = nil): TList<TDictionary<String, variant>>; static;
      class procedure execSql(sql: String; params: TArray<variant> = nil); static;
  end;

    {
var
  sql: String;
  row: TDictionary<String, variant>;
  rows: TList<TDictionary<String, variant>>;
  i: integer;
  val: variant;
  }

implementation

{ TSQLite }

class function TSQLite.queryScalar(sql: String; params: TArray<variant> = nil): variant;
var
  i: byte;
begin
  Result := null;
  _qry.Params.Clear; // before load SQL
  _qry.SQL.Text:=sql;
  if (params <> nil) then
  begin
    for i:=0 to Length(params) - 1 do
    begin
      _qry.Params[i].Value:=params[i];
    end;
  end;
  try
    try
      _qry.Open;
      if (_qry.RecordCount > 0) then
      begin
        Result := _qry.Fields[0].Value;
      end;
    except
      Windows.OutputDebugString(PChar('DB Error: queryScalar'));
    end;
  finally
    _con.Close(true);
  end;
end;

class function TSQLite.queryRow(sql: String; params: TArray<variant> = nil): TDictionary<String, variant>;
var
  i: byte;
begin
  Result := TDictionary<String, variant>.Create;
  _qry.Params.Clear; // before load SQL
  _qry.SQL.Text:=sql;
  if (params <> nil) then
  begin
    for i:=0 to Length(params) - 1 do
    begin
      _qry.Params[i].Value:=params[i];
    end;
  end;
  try
    try
      _qry.Open;
      if (_qry.RecordCount > 0) then
      begin
        for i:=0 to _qry.FieldCount - 1 do
          Result.Add(_qry.Fields[i].FieldName, _qry.Fields[i].Value);
      end;
    except
      Windows.OutputDebugString(PChar('DB Error: queryScalar'));
    end;
  finally
    _con.Close(true);
  end;
end;

class function TSQLite.query(sql: String; params: TArray<variant> = nil): TList<TDictionary<String, variant>>;
type
  TRow = TDictionary<String, variant>;
var
  row: TRow;
  i: byte;
begin
  Result := TList<TRow>.Create;
  _qry.Params.Clear; // before load SQL
  _qry.SQL.Text:=sql;
  if (params <> nil) then
  begin
    for i:=0 to Length(params) - 1 do
    begin
      _qry.Params[i].Value:=params[i];
    end;
  end;
  try
    try
      _qry.Open;
      if (_qry.RecordCount > 0) then
      begin
        while (not _qry.EOF) do
        begin
          row := TRow.Create;
          for i:=0 to _qry.FieldCount - 1 do
            row.Add(_qry.Fields[i].FieldName, _qry.Fields[i].Value);
          Result.Add(row);
          _qry.Next;
        end;
      end;
    except
      Windows.OutputDebugString(PChar('DB Error: queryScalar'));
    end;
  finally
    _con.Close(true);
  end;
end;

class procedure TSQLite.execSql(sql: String; params: TArray<variant> = nil);
var
  i: byte;
begin
  _qry.Params.Clear;  // before load SQL
  _qry.SQL.Text:=sql;
  if (params <> nil) then
  begin
    for i:=0 to Length(params) - 1 do
    begin
      _qry.Params[i].Value:=params[i];
    end;
  end;
  try
    try
      _qry.ExecSQL;
    except
      Windows.OutputDebugString(PChar('DB Error: queryScalar'));
    end;
  finally
    _con.Close(true);
  end;
end;

initialization
  with (TSQLite) do
  begin
    _lib := TSQLDBLibraryLoader.Create(nil);
    _lib.ConnectionType:='SQLite3';
    _lib.LibraryName:='.\sqlite3.dll';
    _lib.Enabled:=true;

    _con := TSQLite3Connection.Create(nil);
    _con.DatabaseName:='.\database.db';
    _con.Params.Add('foreign_keys=on'); // !important foreign-keys working

    _trs := TSQLTransaction.Create(nil);
    _trs.SQLConnection:=_con;

    _qry := TSQLQuery.Create(nil);
    _qry.SQLConnection:=_con;
    _qry.Options:=[TSQLQueryOption.sqoAutoCommit];

    {
    // test
    sql := 'SELECT * FROM config WHERE apiPort = :apiPort';
    rows := TSQLite.query(sql, [
        2222
    ]);
    for row in rows do
      Windows.OutputDebugString(PChar(String(row['apiPort'])));
    }
  end;
end.

