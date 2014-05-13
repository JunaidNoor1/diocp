unit uDBOperator;

interface

uses
  uCDSProvider, uDBAccessOperator, uICDSOperator, ADODB;

type
  TDBOperator = class(TObject)
  private
    FCDSProvider: TCDSProvider;
    FDBAccessOperator:IDBAccessOperator;
  public
    constructor Create;
    destructor Destroy; override;
    procedure setConnection(pvConnection:TADOConnection);
  end;

implementation

constructor TDBOperator.Create;
var
  lvDBAccess:TDBAccessOperator;
begin
  inherited Create;
  FCDSProvider := TCDSProvider.Create();

  //���ݽ���ʹ��
  lvDBAccess := TDBAccessOperator.Create;
  FDBAccessOperator := lvDBAccess;
end;

destructor TDBOperator.Destroy;
begin
  FCDSProvider.Free;
  FDBAccessOperator := nil;
  inherited Destroy;
end;

procedure TDBOperator.setConnection(pvConnection:TADOConnection);
begin
  
end;

end.
