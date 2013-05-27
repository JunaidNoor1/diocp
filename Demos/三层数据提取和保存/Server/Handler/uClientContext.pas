unit uClientContext;

interface

uses
  Windows, JwaWinsock2, uBuffer, SyncObjs, Classes, SysUtils, uIOCPCentre, FileLogger;

type
  TClientContext = class(TIOCPClientContext)
  protected
    procedure DoConnect; override;
    procedure DoDisconnect; override;
    procedure DoOnWriteBack; override;
  public


    /// <summary>
    ///   ���ݴ���
    /// </summary>
    /// <param name="pvDataObject"> (TObject) </param>
    procedure dataReceived(const pvDataObject:TObject); override;


  end;

implementation

uses
  TesterINfo, JSonStream, udmMain;



procedure TClientContext.dataReceived(const pvDataObject:TObject);
var
  lvJsonStream:TJSonStream;
  lvFile:String;
  lvCmdIndex:Cardinal;
  lvXMLData, lvEncodeData:AnsiString;
  lvSQL:String;
begin
  lvJsonStream := TJSonStream(pvDataObject);

  lvCmdIndex := lvJsonStream.JSon.I['cmdIndex'];

  //echo����
  if lvCmdIndex= 1000 then
  begin
    InterlockedIncrement(TesterINfo.__RecvTimes);
    //��д����
    writeObject(lvJsonStream);
  end else if lvCmdIndex = 1001 then
  begin  //����sql��ȡһ�����ݣ�����Stream��
    try
      lvSQL := lvJsonStream.Json.S['sql'];

      lvXMLData := dmMain.CDSProvider.QueryXMLData(lvSQL);

      lvJsonStream.Clear();
      lvJsonStream.Stream.WriteBuffer(lvXMLData[1], Length(lvXMLData));
      lvJsonStream.setResult(True);
    except
      on e:Exception do
      begin
        lvJsonStream.Clear();
        lvJsonStream.setResult(False);
        lvJsonStream.setResultMsg(e.Message);
      end;
    end;
    
    //��д����
    writeObject(lvJsonStream);
  end else if lvCmdIndex = 1002 then  //�������ݵ����
  begin
    try
      lvJsonStream.Stream.Position := 0;
      SetLength(lvEncodeData, lvJSonStream.Stream.Size);
      lvJsonStream.Stream.ReadBuffer(lvEnCodeData[1], lvJSonStream.Stream.Size);

      TFileLogger.instance.logDebugMessage(lvEnCodeData);

      dmMain.ExecuteApplyUpdate(lvEncodeData);

      lvJsonStream.Clear();
      lvJsonStream.setResult(True);
    except
      on e:Exception do
      begin
        lvJsonStream.Clear();
        lvJsonStream.setResult(False);
        lvJsonStream.setResultMsg(e.Message);
      end;
    end;
    
    //��д����
    writeObject(lvJsonStream);
  end else
  begin
    //��������
    writeObject(lvJsonStream);
  end;
end;

procedure TClientContext.DoConnect;
begin
  inherited;
  InterlockedIncrement(TesterINfo.__ClientContextCount);
end;

procedure TClientContext.DoDisconnect;
begin
  inherited;
  InterlockedDecrement(TesterINfo.__ClientContextCount);
end;



procedure TClientContext.DoOnWriteBack;
begin
  inherited;
  InterlockedIncrement(TesterINfo.__SendTimes);
end;

end.
