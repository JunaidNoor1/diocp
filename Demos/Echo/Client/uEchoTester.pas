unit uEchoTester;

interface

uses
  Classes, IdTCPClient, SysUtils,
  IdGlobal, superobject,
  Windows, uClientSocket, FileLogger, uD10ClientSocket, uJSonStreamClientCoder,
  JSonStream;

type
  TEchoTester = class(TThread)
  private
    FCrc:Cardinal;
    FEchoCode: string;
    FClient: TD10ClientSocket;
    function createObject: TJSonStream;
    procedure echoWork(pvObject: TJSonStream);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Execute;override;

    property Client: TD10ClientSocket read FClient;

    property EchoCode: string read FEchoCode write FEchoCode;   

    
  end;

implementation

uses
  ComObj, uJSonStreamTools;

constructor TEchoTester.Create;
begin
  inherited Create(true);
  FClient := TD10ClientSocket.Create();
  FClient.registerCoder(TJSonStreamClientCoder.Create, True);
  FEchoCode := CreateClassID;
end;

destructor TEchoTester.Destroy;
begin
  FClient.Free;
  inherited Destroy;
end;

function TEchoTester.createObject: TJSonStream;
var
  lvStream:TMemoryStream;
  lvData:String;
begin
  Result := TJSonStream.Create;
  
  Result.JSon := SO();
  Result.JSon.I['cmdIndex'] := 1000;   //echo ���ݲ���
  Result.JSon.S['data'] := '���Է��ʹ������';
  Result.JSon.S['EchoCode'] := FEchoCode;
  
  SetLength(lvData, 1024 * 4);
  FillChar(lvData[1], 1024 * 4, Ord('1'));
  Result.Stream.WriteBuffer(lvData[1], Length(lvData));

end;

procedure TEchoTester.echoWork(pvObject: TJSonStream);
begin
  FClient.sendObject(pvObject);
  FClient.recvObject(pvObject);
end;

{ TEchoTester }

procedure TEchoTester.Execute;
var
  lvJSonObject:TJsonStream;
  i:Integer;
  lvCrc:Cardinal;
begin
  i:= 0;
  lvJSonObject := createObject;
  try
    FCrc := TJSonStreamTools.crcObject(lvJSonObject);
    while (not self.Terminated) do
    begin
      try
        if (i mod 1000 = 0) and (i > 0) then
        begin
          TFileLogger.instance.logDebugMessage(FEchoCode + ':1000��echo�����һ�ιرգ���������[' + IntToStr(i) + ']');
          FClient.close;
        end;

        if not FClient.Active then
        begin
          FClient.open;
        end;

        if FClient.Active then
        begin
          echoWork(lvJSonObject);
          lvCrc := TJSonStreamTools.crcObject(lvJSonObject);
          if lvCrc <> FCrc then
          begin
            TFileLogger.instance.logErrMessage(FEchoCode + ':���ݳ����쳣,����[' + IntToStr(i) + '],���˳�ѭ��');
            Break;
          end;

          Inc(i);
        end;

      except
        on E:Exception do
        begin
          TFileLogger.instance.logErrMessage(FEchoCode + E.Message);
          Break;
        end;
      end;
    end;
    TFileLogger.instance.logDebugMessage(FEchoCode + '�߳��Ѿ�ֹͣ[' + IntToStr(i) + ']');
    FClient.close;
  finally
    lvJSonObject.Free;
  end;

end;

end.
