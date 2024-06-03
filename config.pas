unit config;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils,
  Generics.Collections,
  sqlite;

type

  { TConfig }

  TConfig = class
    private
    public
      id: integer;
      isApiEnable: boolean;
      apiPort: Word;

      constructor create(
        id: integer;
        isApiEnable: boolean;
        apiPort: Word
      ); overload; // two constructors
      function ToString: String; override;

      class function get: TConfig; static;
      class procedure update(config: TConfig); static;
  end;

implementation

{ TConfig }

constructor TConfig.create(id: integer; isApiEnable: boolean; apiPort: Word);
begin
  self.id:=id;
  self.isApiEnable:=isApiEnable;
  self.apiPort:=apiPort;
end;

function TConfig.ToString: String;
begin
  //Result:=inherited ToString;
  Result := Format('TConfig: {id: %d, isApiEnable: %s, apiPort: %d}', [
    self.id,
    BoolToStr(self.isApiEnable, true),
    self.apiPort
  ]);
end;

class function TConfig.get: TConfig;
const
  SQL = 'SELECT id, isApiEnable, apiPort FROM config';
var
  row: TDictionary<String, variant>;
begin
  row := TSQLite.queryRow(SQL);
  Result := TConfig.create(
    row['id'],
    row['isApiEnable'],
    row['apiPort']
  );
end;

class procedure TConfig.update(config: TConfig);
const
  SQL = 'UPDATE config SET ' +
          'isApiEnable = :isApiEnable,' +
          'apiPort = :apiPort';
begin
  TSQLite.execSql(SQL, [
    config.isApiEnable,
    config.apiPort
  ]);
end;

end.

