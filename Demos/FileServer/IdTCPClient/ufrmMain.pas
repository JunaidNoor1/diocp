unit ufrmMain;
{
  Indy�õİ汾��10.x�İ汾
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, 
  IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, ExtCtrls;

type
  TfrmMain = class(TForm)
    edtIP: TEdit;
    btnC_01: TButton;
    btnCloseSocket: TButton;
    edtPort: TEdit;
    mmoLog: TMemo;
    IdTCPClient: TIdTCPClient;
    tmrEchoTester: TTimer;
    edtRFile: TEdit;
    btnGetFile: TButton;
    lblFile: TLabel;
    btnUpload: TButton;
    dlgOpen: TOpenDialog;
    chkZip: TCheckBox;
    procedure btnCloseSocketClick(Sender: TObject);
    procedure btnC_01Click(Sender: TObject);
    procedure btnSendJSonStreamObjectClick(Sender: TObject);
    procedure btnStopEchoClick(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
  private
    { Private declarations }
    FTesterList: TList;
    procedure ClearTester;
    procedure refreshState;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  ComObj, superobject, uMemoLogger,
  uEchoTester, uSocketTools, JSonStream, IdGlobal, uNetworkTools,
  uIdTcpClientJSonStreamCoder, uCRCTools, Math;

{$R *.dfm}

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FTesterList := TList.Create();

  refreshState;

end;

destructor TfrmMain.Destroy;
begin
  ClearTester;
  FreeAndNil(FTesterList);
  inherited Destroy;
end;

procedure TfrmMain.refreshState;
begin
  btnCloseSocket.Enabled := IdTCPClient.Connected;
  btnC_01.Enabled := not IdTCPClient.Connected;

  btnUpload.Enabled := btnCloseSocket.Enabled;
  btnGetFile.Enabled := btnCloseSocket.Enabled;
end;

procedure TfrmMain.btnCloseSocketClick(Sender: TObject);
begin
  try
    IdTCPClient.Disconnect;
  finally
    refreshState;
  end;
end;

procedure TfrmMain.btnC_01Click(Sender: TObject);
begin
  IdTCPClient.Disconnect;
  IdTCPClient.Host := edtIP.Text;
  IdTCPClient.Port := StrToInt(edtPort.Text);
  IdTCPClient.Connect;

  refreshState;

end;

procedure TfrmMain.btnSendJSonStreamObjectClick(Sender: TObject);
var
  lvJSonStream, lvRecvObject:TJsonStream;
  lvStream:TStream;
  lvData:String;
  l, j, x:Integer;
begin
  lvJSonStream := TJsonStream.Create;
  try
    lvJSonStream.JSon := SO();
    lvJSonStream.JSon.I['cmdIndex'] := 1000;   //echo ���ݲ���
    lvJSonStream.JSon.S['data'] := '���Է��ʹ������';
    lvJSonStream.JSon.S['key'] := CreateClassID;
    lvStream := lvJSonStream.Stream;

    SetLength(lvData, 1024 * 1);
    FillChar(lvData[1], 1024 * 1, Ord('1'));
    lvStream.WriteBuffer(lvData[1], Length(lvData));

    TIdTcpClientJSonStreamCoder.Encode(self.IdTCPClient, lvJSonStream);

    TMemoLogger.infoMsg('���ݷ��ͳɹ���', mmoLog.Lines);
    lvRecvObject := TJsonStream.Create;
    try
      // TMemoLogger.infoMsg('���ݽ��ճɹ���', mmoLog.Lines);
      TIdTcpClientJSonStreamCoder.Decode(self.IdTCPClient, lvRecvObject);
      
      TMemoLogger.infoMsg('==============================================' + sLineBreak
        + lvRecvObject.JSon.AsJSon(True)
        , mmoLog.Lines);
    finally
       lvRecvObject.Free;
    end;
  finally
    lvJSonStream.Free;
  end;   
end;

procedure TfrmMain.btnStopEchoClick(Sender: TObject);
begin
  ClearTester;
end;

procedure TfrmMain.btnUploadClick(Sender: TObject);

const
  SEC_SIZE = 1024 * 4;
  //SEC_SIZE = 10;
var
  lvFileStream:TFileStream;
  lvRecvObj, lvSendObj:TJsonStream;
  i, l, lvSize:Integer;

begin
  //���ļ��ֶδ���<ÿ�ι̶���С> 4K
  //ѭ������
  //  {
  //     fileName:'xxxx',
  //     crc:xxxx,
  //     start:0,   //��ʼλ��
  //     eof:true,  //���һ��
  //  }

  if not dlgOpen.Execute() then exit;

  lvFileStream := TFileStream.Create(dlgOpen.FileName, fmOpenRead);
  lvSendObj := TJsonStream.Create;
  lvRecvObj := TJsonStream.Create;
  try
//    lvFileStream.Position := 106496;
//    lvSendObj.Clear();
//    l := lvSendObj.Stream.CopyFrom(lvFileStream, SEC_SIZE);
//    if l <=SEC_SIZE then
//    begin
//      ShowMessage('OK');
//    end;
//    exit;

    while true do
    begin
      lvSendObj.Clear();
      lvSendObj.Json.I['cmdIndex'] := 1001;
      lvSendObj.Json.I['start'] := lvFileStream.Position;
      lvSendObj.Json.S['fileName'] := ExtractFileName(dlgOpen.FileName);
      lvSendObj.Json.B['config.stream.zip'] := chkZip.Checked;
      lvSize := Min(SEC_SIZE, lvFileStream.Size-lvFileStream.Position);
      l := lvSendObj.Stream.CopyFrom(lvFileStream, lvSize);
      if l = 0 then
      begin
        Break;
      end;
      lvSendObj.Json.I['size'] := l;
      lvSendObj.Json.B['eof'] := (lvFileStream.Position = lvFileStream.Size);
      lvSendObj.Json.I['crc'] := TCRCTools.crc32Stream(lvSendObj.Stream);
      TIdTcpClientJSonStreamCoder.Encode(self.IdTCPClient, lvSendObj);
      TIdTcpClientJSonStreamCoder.Decode(self.IdTCPClient, lvRecvObj);
      if not lvRecvObj.getResult then
      begin
        raise Exception.Create(lvRecvObj.getResultMsg);
      end;
      if (lvFileStream.Position = lvFileStream.Size) then
      begin
        Break;
      end;
    end;
  finally
    lvFileStream.Free;
    lvSendObj.Free;
    lvRecvObj.Free;
  end;

  ShowMessage('�ϴ��ɹ�!');
end;

procedure TfrmMain.ClearTester;
begin

end;

end.
