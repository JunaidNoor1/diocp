unit ufrmMain;
{
  ics 7
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,  OverbyteIcsWSocket,
  ExtCtrls, OverbyteIcsWndControl, uBuffer;

type
  TfrmMain = class(TForm)
    edtIP: TEdit;
    btnC_01: TButton;
    btnSendJSonStreamObject: TButton;
    btnCloseSocket: TButton;
    edtPort: TEdit;
    mmoLog: TMemo;
    btnSend100: TButton;
    tmrEchoTester: TTimer;
    lblEchoINfo: TLabel;
    btnClearINfo: TButton;
    FICSSocket: TWSocket;
    procedure btnClearINfoClick(Sender: TObject);
    procedure btnCloseSocketClick(Sender: TObject);
    procedure btnC_01Click(Sender: TObject);
    procedure btnSend100Click(Sender: TObject);
    procedure btnSendJSonStreamObjectClick(Sender: TObject);
    procedure FICSSocketDataAvailable(Sender: TObject; ErrCode: Word);
    procedure tmrEchoTesterTimer(Sender: TObject);
  private
    //FICSSocket: TWSocket;
    FRecvBuffer:TBufferLink;

    FTesterList: TList;
  protected
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
  uSocketTools, JSonStream, IdGlobal, uNetworkTools,
  uICSClientJSonStreamCoder, uTesterTools;

{$R *.dfm}

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTesterList := TList.Create();
  FRecvBuffer := TBufferLink.Create;

end;

destructor TfrmMain.Destroy;
begin
  FRecvBuffer.Free;
  FreeAndNil(FTesterList);
  inherited Destroy;
end;

procedure TfrmMain.btnClearINfoClick(Sender: TObject);
begin
  mmoLog.Clear;
  __sendCount := 0;
  __recvCount := 0;
  TTesterTools.clearTesterInfo;
end;

procedure TfrmMain.btnCloseSocketClick(Sender: TObject);
begin
  FICSSocket.Close;
end;

procedure TfrmMain.btnC_01Click(Sender: TObject);
begin
  FICSSocket.Port := edtPort.Text;
  FICSSocket.Addr := edtIP.Text;
  FICSSocket.Connect;
  FICSSocket.ProcessMessages;
 // FICSSocket.Flush;
  if FICSSocket.State = wsConnected then
  begin
    ShowMessage('�ɹ�!');
  end else
  begin
    ShowMessage('��ʧ��!');
  end;

//  FICSClient.Host := edtIP.Text;
//  FICSClient.Port := edtPort.Text;
//  FICSClient.Open;

  

end;

procedure TfrmMain.btnSend100Click(Sender: TObject);
var
  i:Integer;
begin
  for i := 0 to 100 - 1 do
  begin
    btnSendJSonStreamObject.Click;
  end;
    
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
    lvJSonStream.Json.B['config.stream.zip'] := false;
    
    lvStream := lvJSonStream.Stream;
    SetLength(lvData, 1024 * 4);
    FillChar(lvData[1], 1024 * 4, Ord('1'));
    lvStream.WriteBuffer(lvData[1], Length(lvData));
    
    l:= TICSClientJSonStreamCoder.Encode(FICSSocket, lvJSonStream);
    InterlockedIncrement(__sendObjectCount);
    TTesterTools.incSendbytesSize(l);
    //TIdTcpClientJSonStreamCoder.Encode(self.IdTCPClient, lvJSonStream);

    TMemoLogger.infoMsg('���ݷ��ͳɹ����������ݴ�С:' + IntToStr(l), mmoLog.Lines);

  finally
    lvJSonStream.Free;
  end;
end;

procedure TfrmMain.FICSSocketDataAvailable(Sender: TObject; ErrCode: Word);
var
   lvRecvObject:TJsonStream;
   lvRecvCount, l:Integer;
   lvBuffer:Pointer;
begin
  lvRecvCount :=  FICSSocket.RcvdCount;
  if ErrCode <> 0 then
  begin
    TMemoLogger.infoMsg('==���ճ������쳣=======================' + sLineBreak
            + IntToStr(ErrCode)
            , mmoLog.Lines);
  end else if lvRecvCount > 0 then
  begin
    GetMem(lvBuffer, lvRecvCount);
    try    
      l := self.FICSSocket.Receive(lvBuffer, lvRecvCount);
      FRecvBuffer.AddBuffer(lvBuffer, l);
      TTesterTools.incRecvBytesSize(l);
      InterlockedIncrement(__recvCount);
    finally
      FreeMem(lvBuffer);
    end;

    //����
    lvRecvObject := TJsonStream(TICSClientJSonStreamCoder.Decode4Buffer(FRecvBuffer));
    while lvRecvObject <> nil do  //ֱ�����յ����ݲ��ܱ�����
    begin
      //����ɹ�
      if lvRecvObject <> nil then
      try
        InterlockedIncrement(__recvObjectCount);
        //�����߼�����

        //�����Ѿ���ȡ��buffer
        FRecvBuffer.clearHaveReadBuffer;
      finally
        lvRecvObject.Free;
      end;

      //�ٽ��н���
      lvRecvObject := TJsonStream(TICSClientJSonStreamCoder.Decode4Buffer(FRecvBuffer));
    end;
    



    TMemoLogger.infoMsg('==============================================' + sLineBreak
      //+ lvRecvObject.JSon.AsJSon(True)

      + sLineBreak
      + 'bufsize:' + IntToStr(FICSSocket.BufSize)
      + sLineBreak
      + 'recvCount:' + IntToStr(lvRecvCount) + '/' + IntToStr(FICSSocket.RcvdCount)
      + sLineBreak
      + 'readCount:' +  IntToStr(FICSSocket.ReadCount)
      , mmoLog.Lines);
//
//    lvRecvObject := TJsonStream.Create;
//    try
//      l:= TICSClientJSonStreamCoder.Decode(self.FICSSocket, lvRecvObject);
//      TTesterTools.incRecvBytesSize(l);
//      InterlockedIncrement(__recvCount);
//      TMemoLogger.infoMsg('==============================================' + sLineBreak
//        //+ lvRecvObject.JSon.AsJSon(True)
//
//        + sLineBreak
//        + 'bufsize:' + IntToStr(FICSSocket.BufSize)
//        + sLineBreak
//        + 'recvCount:' + IntToStr(lvRecvCount) + '/' + IntToStr(FICSSocket.RcvdCount)
//        + sLineBreak
//        + 'readCount:' +  IntToStr(FICSSocket.ReadCount)
//        , mmoLog.Lines);
//    finally
//       lvRecvObject.Free;
//    end;


  end;

end;

procedure TfrmMain.tmrEchoTesterTimer(Sender: TObject);
begin
  lblEchoINfo.Caption := Format('���ʹ���:%d', [__sendCount]) + sLineBreak +
                         Format('���մ���:%d', [__recvCount]) + sLineBreak +
                         Format('����/���Ͷ������:%d/%d', [__recvObjectCount, __sendObjectCount]) + sLineBreak +
                         Format('����/�����ֽ���:%d/%d', [__recvbytes_size, __sendbytes_size]) + sLineBreak;

end;

end.
