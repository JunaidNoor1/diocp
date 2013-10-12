unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, uClientSocket, uD10ClientSocket,
  uJSonStreamClientCoder, ExtCtrls, Grids, DBGrids, DB, DBClient, ComCtrls,
  ADODB, uADOTools;

type
  TfrmMain = class(TForm)
    Panel1: TPanel;
    btnOpen: TButton;
    btnCloseSocket: TButton;
    edtIP: TEdit;
    edtPort: TEdit;
    mmoSQL: TMemo;
    btnOpenSQL: TButton;
    dsMain: TDataSource;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    mmoData: TMemo;
    DBGrid1: TDBGrid;
    qryMain: TADOQuery;
    procedure btnCloseSocketClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnOpenSQLClick(Sender: TObject);
  private
    { Private declarations }
    FClientSocket: TD10ClientSocket;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure refreshState;
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  ComObj, superobject, uMemoLogger,
  uSocketTools, JSonStream, IdGlobal, uNetworkTools;

{$R *.dfm}

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClientSocket := TD10ClientSocket.Create();
  FClientSocket.registerCoder(TJSonStreamClientCoder.Create, True);

  refreshState;

end;

destructor TfrmMain.Destroy;
begin
  FreeAndNil(FClientSocket);
  inherited Destroy;
end;

procedure TfrmMain.refreshState;
begin
  btnCloseSocket.Enabled := FClientSocket.Active;
  btnOpen.Enabled := not FClientSocket.Active;
  btnOpenSQL.Enabled := FClientSocket.Active;

end;

procedure TfrmMain.btnCloseSocketClick(Sender: TObject);
begin
  FClientSocket.close;
  refreshState;
end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  FClientSocket.close;
  FClientSocket.Host := edtIP.Text;
  FClientSocket.Port := StrToInt(edtPort.Text);
  FClientSocket.open;

  refreshState;
end;

procedure TfrmMain.btnOpenSQLClick(Sender: TObject);
var
  lvJSonStream, lvRecvObject:TJsonStream;
  lvStream:TStream;
  lvData:AnsiString;
  l, j, x:Integer;
  lvCounter:Integer;
  lvDebugStr:String;
begin
  lvJSonStream := TJsonStream.Create;
  try
    lvJSonStream.JSon := SO();
    lvJSonStream.JSon.I['cmdIndex'] := 1001;   //��һ��SQL�ű�����ȡ����
    lvJSonStream.Json.S['sql'] := mmoSQL.Lines.Text;

    FClientSocket.sendObject(lvJSonStream);
  finally
    lvJSonStream.Free;
  end;

  //��ȡ����
  lvRecvObject := TJsonStream.Create;
  try
    lvCounter := GetTickCount;
    FClientSocket.recvObject(lvRecvObject);
    lvCounter := GetTickCount-lvCounter;

    if not lvRecvObject.getResult then
    begin
      raise Exception.Create(lvRecvObject.getResultMsg);
    end;

    lvDebugStr := lvRecvObject.Json.S['debug'];

    lvDebugStr := lvDebugStr + sLineBreak + '���������ܺ�ʱ:' + IntToStr(lvCounter) + sLineBreak +
      '*��������˴���ִ��SQL,�������,ѹ������,�ͻ��˽�������,��ѹ����';

    qryMain.DisableControls;
    try
      if lvRecvObject.Stream.Size > 0 then
      begin
        lvRecvObject.Stream.Position := 0;
        lvCounter := GetTickCount;
        TADOTools.loadFromStream(qryMain, TMemoryStream(lvRecvObject.Stream));
        lvCounter := GetTickCount-lvCounter;
        lvDebugStr := lvDebugStr + sLineBreak + '��ѹ���ݵ����ݼ���ʱ:' + IntToStr(lvCounter);
      end;



    finally
      qryMain.EnableControls;
    end;

    ShowMessage(lvDebugStr);
  finally
     lvRecvObject.Free;
  end;
end;


end.
