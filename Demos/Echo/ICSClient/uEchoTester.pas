unit uEchoTester;

interface

uses
  Classes, Windows, SysUtils,
  SyncObjs,
  superobject,    OverbyteIcsWSocket,
  FileLogger, uICSClientJSonStreamCoder,
  JSonStream, uBuffer;

type
  TEchoTester = class(TThread)
  private
    FSocketCloseEvent: TEvent;
    FRecvEvent:TEvent;
    FEchoCode: string;
    FClient: TWSocket;
    FHost: String;
    FPort: string;
    FRecvBuffer:TBufferLink;
  protected
    procedure OnSocketDataAvailable(Sender: TObject; ErrCode: Word);
    procedure OnSocketSessionClosed(Sender: TObject; ErrCode: Word);
    procedure OnSocketSessionConnected(Sender: TObject; ErrCode: Word);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Execute;override;


    property EchoCode: string read FEchoCode write FEchoCode;   
    property Host: String read FHost write FHost;
    property Port: string read FPort write FPort;

  end;

var
  __threadCount:Integer;
  __sendCount:Integer;
  __recvCount:Integer;
  __recvAllCount:Integer;
  __recvErrCount:Integer;
  __errCount:Integer;
  __onlineCount:Integer;


procedure resetEchoINfo();


implementation

uses
  ComObj, uJSonStreamTools, uTesterTools;

procedure resetEchoINfo();
begin
  __onlineCount := 0;
  __threadcount:=0;
  __sendCount := 0;
  __recvCount := 0;
  __recvAllCount := 0;
  __errCount := 0;
  __recvErrCount := 0;
end;

constructor TEchoTester.Create;
begin
  inherited Create(true);
  InterlockedIncrement(__threadCount);
  FSocketCloseEvent := TEvent.Create(nil, true, False, '');
  FRecvEvent := TEvent.Create(nil, true, False, '');
  FRecvBuffer := TBufferLink.Create;
end;

destructor TEchoTester.Destroy;
begin
  FRecvBuffer.Free;
  FRecvEvent.Free;
  FSocketCloseEvent.Free;
  InterlockedDecrement(__threadCount);
  inherited Destroy;

end;

{ TEchoTester }

procedure TEchoTester.Execute;
var
  lvJSonObject, lvRecvObject:TJsonStream;
  i, l:Integer;
begin
  FClient := TWSocket.Create(nil);
  try
    FClient.Addr := FHost;
    FClient.Port := FPort;
    FClient.MultiThreaded := true;
    FClient.OnSessionConnected := self.OnSocketSessionConnected;
    FClient.OnSessionClosed := self.OnSocketSessionClosed;
    FClient.OnDataAvailable := self.OnSocketDataAvailable;

    lvJSonObject := TJSonStream.Create;
    lvRecvObject := TJsonStream.Create;
    try
      lvJSonObject.JSon := SO();
      lvJSonObject.JSon.I['cmdIndex'] := 1000;   //echo ���ݲ���
      lvJSonObject.JSon.S['__data'] := '���Է��ʹ������';
      lvJSonObject.JSon.S['EchoCode'] := FEchoCode;
      lvJSonObject.Json.B['config.stream.zip'] := false;
      lvJSonObject.Json.S['data.key'] := createClassID;
      while (not self.Terminated) do
      begin
        try
          if FClient.State = wsClosed then
          begin
              //icsͨ����Ϣ����
              FClient.Connect;
              FClient.ProcessMessages;
          end;

          while (FClient.State = wsConnecting) and (not self.Terminated) do
             FClient.ProcessMessages;



          if FClient.State = wsConnected then
          begin 
            l := TICSClientJSonStreamCoder.Encode(FClient, lvJSonObject);
            TTesterTools.incSendbytesSize(l);
            InterlockedIncrement(__sendObjectCount);
            
            FRecvEvent.SetEvent;

            i := 0;   //����10���������
            while (i < 100) and (not self.Terminated) do
            begin
              FClient.ProcessMessages;
              if FRecvEvent.WaitFor(100) = wrSignaled then
              begin
                Break;
              end;
              inc(i);
            end;

            //��Ϣ2��
            i := 0;
            while (i < 20) and (not self.Terminated) do
            begin
              Sleep(100);
              inc(i);
            end;



//            InterlockedIncrement(__sendCount);
//
//            while (FClient.RcvdCount = 0) and (not self.Terminated) do
//               FClient.ProcessMessages;
//
//            try
//              l :=TICSClientJSonStreamCoder.Decode(FClient, lvRecvObject);
//              TTesterTools.incRecvBytesSize(l);
//              if (lvRecvObject.Json.S['data.key']) <> (lvJSonObject.Json.S['data.key']) then
//              begin
//                InterlockedIncrement(__recvErrCount);
//              end else
//              begin
//                InterlockedIncrement(__recvCount);
//              end;
//            except
//              on E:Exception do
//              begin
//                InterlockedIncrement(__recvErrCount);
//                TFileLogger.instance.logErrMessage('�����쳣:' + FEchoCode + E.Message);
//              end;
//            end;
          end;
        except
          on E:Exception do
          begin
            TFileLogger.instance.logErrMessage(FEchoCode + E.Message);
          end;
        end;
      end;
      TFileLogger.instance.logDebugMessage(FEchoCode + '�߳��Ѿ�ֹͣ[' + IntToStr(i) + ']');
      FClient.Close;
      FClient.WaitForClose;
    finally
      lvJSonObject.Free;
      lvRecvObject.Free;
    end;
  finally
    FClient.Free;
  end;
end;

procedure TEchoTester.OnSocketDataAvailable(Sender: TObject; ErrCode: Word);
var
   lvRecvObject:TJsonStream;
   lvRecvCount, l:Integer;
   lvBuffer:Pointer;
begin
  lvRecvCount :=  FClient.RcvdCount;
  if ErrCode <> 0 then
  begin
    InterlockedIncrement(__recvErrCount);
  end else if lvRecvCount > 0 then
  begin
    GetMem(lvBuffer, lvRecvCount);
    try    
      l := self.FClient.Receive(lvBuffer, lvRecvCount);
      FRecvBuffer.AddBuffer(lvBuffer, l);
      TTesterTools.incRecvBytesSize(l);
      InterlockedIncrement(__recvCount);
    finally
      FreeMem(lvBuffer);
    end;

    //ֱ�����յ����ݲ��ܱ�����
    while true do
    begin
      lvRecvObject := TJsonStream(TICSClientJSonStreamCoder.Decode4Buffer(FRecvBuffer));
      if lvRecvObject <> nil then
      begin
        try
          //����Ϊ���ź�
          FRecvEvent.SetEvent;
          InterlockedIncrement(__recvObjectCount);
          //�����߼�����

          //�����Ѿ���ȡ��buffer
          FRecvBuffer.clearHaveReadBuffer;
        finally
          lvRecvObject.Free;
        end;
      end else
      begin
        Break;  //ʣ������ݲ����ٽ��н���
      end;
    end;
  end;
end;


procedure TEchoTester.OnSocketSessionClosed(Sender: TObject; ErrCode: Word);
begin
  InterlockedDecrement(__onlineCount);
  FSocketCloseEvent.SetEvent;  //���Խ��йر�
end;

procedure TEchoTester.OnSocketSessionConnected(Sender: TObject; ErrCode: Word);
begin
  //���źţ���waitFor���Լ���
//  if ErrCode = 0 then
//  begin
    InterlockedIncrement(__onlineCount);
  //end;
end;

end.
