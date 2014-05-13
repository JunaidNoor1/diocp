unit uCDSProvider;

interface

uses
  DBClient, Provider, SysUtils, ActiveX, Uni, DB;

type
  TMyUniQuery = class(TUniQuery)
  protected
    /// <summary>
    ///   ���ǵ�������TDataSetProvider.dataʱִ��PSResetʱ�ظ�ˢ��
    /// </summary>
    procedure PSReset;override;

  end;

  TCDSProvider = class(TObject)
  private
    FQuery: TMyUniQuery;
    FCDSTemp:TClientDataSet;
    FConnection: TUniConnection;
    FProvider: TDataSetProvider;
    procedure SetConnection(const AValue: TUniConnection);
  public
    constructor Create;
    
    destructor Destroy; override;
    
    //��ȡһ��CDS.DATA���ݰ�
    function QueryData(pvCmdText: string; pvOperaMsg: string = ''): OleVariant;

    //��ȡһ��CDS.XMLDATA���ݰ�
    function QueryXMLData(pvCmdText: string): string;

    function Query(pvCmdText: string; pvOperaMsg: string = ''): TDataSet;

    function createQuery(pvCmdText: string; pvOperaMsg: string = ''): TDataSet;

    procedure ExecuteScript(pvCmdText:String; pvOperaMsg: string = '');

    property Connection: TUniConnection read FConnection write SetConnection;
  end;

implementation

constructor TCDSProvider.Create;
begin
  inherited Create;
  CoInitialize(nil);
  FCDSTemp := TClientDataSet.Create(nil);
  FProvider := TDataSetProvider.Create(nil);

  //TDataPacketWriter.AddIndexDefs�������ʱ�������ǣ�ԭ�����ݼ���Order by
  //        if not (poRetainServerOrder in Options) then
  //          DefIdx := (DataSet as IProviderSupport).PSGetDefaultOrder
  FProvider.Options := FProvider.Options + [poIncFieldProps] + [poRetainServerOrder];

  FQuery := TMyUniQuery.Create(nil);

  FQuery.DisableControls;
  FQuery.ParamCheck := false;
  FProvider.DataSet := FQuery;
end;

function TCDSProvider.createQuery(pvCmdText, pvOperaMsg: string): TDataSet;
begin
  Result := TUniQuery.Create(nil);
  try
    TUniQuery(Result).Connection := FConnection;
    TUniQuery(Result).Close;
    TUniQuery(Result).SQL.Clear;
    TUniQuery(Result).SQL.Add(pvCmdText);
    TUniQuery(Result).Open;
  except
    Result.Free;
    Result := nil;
    raise;
  end;
end;

destructor TCDSProvider.Destroy;
begin
  FreeAndNil(FCDSTemp);
  FreeAndNil(FQuery);
  FreeAndNil(FProvider);
  inherited Destroy;
end;

procedure TCDSProvider.ExecuteScript(pvCmdText, pvOperaMsg: string);
begin
  try
    FQuery.Close;
    FQuery.SQL.Clear;
    FQuery.SQL.Add(pvCmdText);
    FQuery.ExecSQL;
  except on e: Exception do
    begin
       raise;
    end;
  end;
end;

function TCDSProvider.Query(pvCmdText, pvOperaMsg: string): TDataSet;
begin
  try
    FQuery.Close;
    FQuery.SQL.Clear;
    FQuery.SQL.Add(pvCmdText);
    FQuery.Open;
    Result := FQuery;
  except on e: Exception do
    begin
       raise;
    end;
  end;
end;

function TCDSProvider.QueryData(pvCmdText: string; pvOperaMsg: string = ''):
    OleVariant;
var
  i: Integer;
begin
  try
    FQuery.Close;
    FQuery.SQL.Clear;
    FQuery.SQL.Add(pvCmdText);
    FQuery.Open;
    for i := 0 to FQuery.FieldCount - 1 do
    begin
      FQuery.Fields[i].ReadOnly := false;
    end;
    Result := FProvider.Data;
  except on e: Exception do
    begin
       raise;
    end;
  end;

end;

function TCDSProvider.QueryXMLData(pvCmdText: string): string;
var
  i: Integer;
begin
  FQuery.Close;
  FQuery.SQL.Clear;
  FQuery.SQL.Add(pvCmdText);
  FQuery.Open;
  for i := 0 to FQuery.FieldCount - 1 do
  begin
    FQuery.Fields[i].ReadOnly := false;
  end;

  FProvider.DataSet := FQuery;
  FCDSTemp.Data := FProvider.Data;
  Result := FCDSTemp.XMLData;
  FQuery.Close;
end;

procedure TCDSProvider.SetConnection(const AValue: TUniConnection);
begin
  FConnection := AValue;
  FQuery.Connection := FConnection;
end;

procedure TMyUniQuery.PSReset;
begin
end;

end.
