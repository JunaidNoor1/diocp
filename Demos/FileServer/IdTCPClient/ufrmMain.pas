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
    procedure btnGetFileClick(Sender: TObject);
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

procedure TfrmMain.btnGetFileClick(Sender: TObject);

var
  lvFileStream:TFileStream;
  lvRecvObj, lvSendObj:TJsonStream;
  i, l, lvSize:Integer;
  lvFileName:String;
  lvCrc:Cardinal;
begin

  //���ļ��ֶ�����<ÿ�ι̶���С>
  //ѭ������
  //  {
  //     fileName:'xxxx',  //�ͻ��������ļ�
  //     start:0,          //�ͻ�������ʼλ��
  
  //     filesize:11111,   //�ļ��ܴ�С
  //     crc:xxxx,         //����˷���
  //     blockSize:4096   //����˷���
  //  }
  

  lvFileName := ExtractFilePath(ParamStr(0)) + 'tempFiles\' + edtRFile.Text;
  DeleteFile(lvFileName);

  lvFileStream := TFileStream.Create(lvFileName, fmCreate or fmShareDenyWrite);
  lvSendObj := TJsonStream.Create;
  lvRecvObj := TJsonStream.Create;
  try
    while true do
    begin
      lvSendObj.Clear();
      //�����ļ�����
      lvSendObj.Json.S['cmd.namespace'] := 'fileaccess'; 
      lvSendObj.Json.I['cmd.index'] := 1;
      lvSendObj.Json.I['start'] := lvFileStream.Position;
      lvSendObj.Json.S['fileName'] := edtRFile.Text;
      lvSendObj.Json.B['config.stream.zip'] := chkZip.Checked;

      TIdTcpClientJSonStreamCoder.Encode(self.IdTCPClient, lvSendObj);
      TIdTcpClientJSonStreamCoder.Decode(self.IdTCPClient, lvRecvObj);
      if not lvRecvObj.getResult then
      begin
        raise Exception.Create(lvRecvObj.getResultMsg);
      end;

      lvCrc := TCRCTools.crc32Stream(lvRecvObj.Stream);
      if lvCrc <> lvRecvObj.Json.I['crc'] then
      begin
        raise Exception.Create('crcУ��ʧ��!');
      end;
      lvRecvObj.Stream.Position := 0;
      lvFileStream.CopyFrom(lvRecvObj.Stream, lvRecvObj.Stream.Size);

      //�ļ��������
      if lvFileStream.Size = lvRecvObj.Json.I['fileSize'] then
      begin
        Break;
      end;
    end;
  finally
    lvFileStream.Free;
    lvSendObj.Free;
    lvRecvObj.Free;
  end;

  ShowMessage('���سɹ�!');
end;

procedure TfrmMain.btnStopEchoClick(Sender: TObject);
begin
  ClearTester;
end;

procedure TfrmMain.btnUploadClick(Sender: TObject);
const
  SEC_SIZE = 1024 * 4 * 1000;
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
      lvSendObj.Json.S['cmd.namespace'] := 'fileaccess'; 
      lvSendObj.Json.I['cmd.index'] := 2;   //�ϴ��ļ�
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
