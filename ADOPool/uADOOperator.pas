unit uADOOperator;

interface

uses
  uCDSProvider, uDBAccessOperator, uICDSOperator,
  ADODB, CDSOperatorWrapper, uADOConnectionPool, superobject,
  uADOConnectionTools, DBClient, SysUtils;

type
  TADOOperator = class(TObject)
  private    
    FConnectionPool: TADOConnectionPool;
    FConnection:TADOConnection;
    FCDSProvider: TCDSProvider;
    FDBAccessObj:TDBAccessOperator;
    FDBAccessOperator:IDBAccessOperator;
    FTraceData: ISuperObject;

    
  public
    constructor Create;
    
    destructor Destroy; override;

    procedure ReOpen;

    procedure ExecuteApplyUpdate(const pvEncodeData: AnsiString);

    procedure ExecuteApplyUpdateCDS(const pvTable, pvUpdateKeyFields: AnsiString;
        const pvCDS: TClientDataSet);



    procedure executeScript(pvSQLScript:String);
    
    procedure setConnection(pvConnection:TADOConnection);

    property CDSProvider: TCDSProvider read FCDSProvider;
    
    property Connection: TADOConnection read FConnection;

    //��ʱ���
    property ConnectionPool: TADOConnectionPool read FConnectionPool write FConnectionPool;

    property TraceData: ISuperObject read FTraceData write FTraceData;



    
  end;

implementation

uses
  CDSOperatorDLL, FileLogger;


constructor TADOOperator.Create;
begin
  inherited Create;
  FCDSProvider := TCDSProvider.Create();

  //���ݽ���ʹ��
  FDBAccessObj := TDBAccessOperator.Create;
  FDBAccessOperator := FDBAccessObj;
end;

destructor TADOOperator.Destroy;
begin
  FCDSProvider.Free;
  FDBAccessOperator := nil;
  inherited Destroy;
end;

procedure TADOOperator.ExecuteApplyUpdate(const pvEncodeData: AnsiString);
var
  lvSQL:AnsiString;
  lvDecode:ICDSDecode;
begin

  lvDecode := TCDSOperatorWrapper.createCDSDecode;
  //���н���
  lvDecode.setDBAccessOperator(FDBAccessOperator);
  lvDecode.setData(PAnsiChar(pvEncodeData));
  lvDecode.Execute;
  TCDSOperatorWrapper.checkRaiseLastError(lvDecode);
  //�����õ�SQL�ű�
  lvSQL:= lvDecode.getUpdateSql;

  if FTraceData <> nil then
  begin
    FTraceData.S['sqls[]'] := lvSQL;
  end;

  //����ִ�нű�
  FConnection.BeginTrans;
  try
    FDBAccessOperator.executeSQL(PAnsiChar(lvSQL));
    FConnection.CommitTrans;
  except
    FConnection.RollbackTrans;
    raise;
  end;
  //������ǰ�ͷ�
  lvSQL := '';
end;

procedure TADOOperator.ExecuteApplyUpdateCDS(const pvTable, pvUpdateKeyFields:
    AnsiString; const pvCDS: TClientDataSet);
var
  lvSQL, lvEncodeData:AnsiString;
  lvCDSEncode:ICDSEncode;
  lvCDSDecode:ICDSDecode;
begin
  if pvCDS.ChangeCount = 0 then exit;

  lvCDSEncode := TCDSOperatorWrapper.createCDSEncode;
  try
    lvCDSEncode.setTableINfo(PAnsiChar(pvTable), PAnsiChar(pvUpdateKeyFields));
    
    TCDSOperatorWrapper.checkRaiseLastError(lvCDSEncode);
    
    lvCDSEncode.setData(pvCDS.Data, pvCDS.Delta);

    TCDSOperatorWrapper.checkRaiseLastError(lvCDSEncode);
    lvCDSEncode.Execute;

    TCDSOperatorWrapper.checkRaiseLastError(lvCDSEncode);

    lvEncodeData := lvCDSEncode.getPackageData;
    TCDSOperatorWrapper.checkRaiseLastError(lvCDSEncode);
  finally
    try
      lvCDSEncode := nil;
    except
      raise Exception.Create('�ͷ�CDSEncode�����쳣!');
    end;
  end;


  lvCDSDecode := TCDSOperatorWrapper.createCDSDecode;

  //���н���
  with lvCDSDecode do
  begin
    setDBAccessOperator(FDBAccessOperator);
    setData(PAnsiChar(lvEncodeData));

    TCDSOperatorWrapper.checkRaiseLastError(lvCDSDecode);

    Execute;

    TCDSOperatorWrapper.checkRaiseLastError(lvCDSDecode);
    
    //�����õ�SQL�ű�
    lvSQL:= getUpdateSql;
    
    TCDSOperatorWrapper.checkRaiseLastError(lvCDSDecode);

    if FTraceData <> nil then
    begin
      FTraceData.S['sqls[]'] := lvSQL;
    end;

    //����ִ�нű�
    FDBAccessOperator.executeSQL(PAnsiChar(lvSQL));
    
    //������ǰ�ͷ�
    lvSQL := '';
  end;

  lvEncodeData := '';
end;

procedure TADOOperator.executeScript(pvSQLScript: String);
begin

end;

procedure TADOOperator.ReOpen;
begin
  FConnection.Close;
  FConnection.Open();
end;

procedure TADOOperator.setConnection(pvConnection:TADOConnection);
begin
  if Self = nil then
  begin
    exit;
  end else
  begin
    if pvConnection = nil then
    begin
      try
        FConnection := pvConnection;
        FCDSProvider.Connection := pvConnection;
        FDBAccessObj.setConnection(pvConnection);
      except
        on E:Exception do
        begin
          TFileLogger.instance.logMessage(
            'setConnection(nil):' + e.Message,
            'ADOOpera_ERROR_');
        end;
      end;
    end else
    begin
      FConnection := pvConnection;
      FCDSProvider.Connection := pvConnection;
      FDBAccessObj.setConnection(pvConnection);
    end;

  end;
end;

end.
