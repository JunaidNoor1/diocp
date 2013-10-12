unit uClientContext;

interface

uses
  Windows,  uBuffer, SyncObjs, Classes, SysUtils,
  uIOCPCentre, FileLogger, ADODB, uADOTools, ComObj, ActiveX;

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
  JSonStream, udmMain;



procedure TClientContext.dataReceived(const pvDataObject:TObject);
var
  lvJsonStream:TJSonStream;
  lvFile:String;
  lvCmdIndex:Cardinal;
  lvXMLData, lvEncodeData:AnsiString;
  lvSQL, lvDebug:String;
  lvStream:TMemoryStream;
  lvADOQuery:TADOQuery;
  lvCounter:Integer;
begin
  lvJsonStream := TJSonStream(pvDataObject);

  lvCmdIndex := lvJsonStream.JSon.I['cmdIndex'];

  //echo����
  if lvCmdIndex= 1000 then
  begin
    //��д����
    writeObject(lvJsonStream);
  end else if lvCmdIndex = 1001 then
  begin  //����sql��ȡһ�����ݣ�����Stream��
    try
      lvSQL := lvJsonStream.Json.S['sql'];
      lvJsonStream.Clear();
      CoInitialize(nil);
      lvADOQuery:=TADOQuery.Create(nil);
      try
        lvADOQuery.Connection := dmMain.conMain;
        lvCounter := GetTickCount;
        lvADOQuery.SQL.Clear;
        lvADOQuery.SQL.Text := lvSQL;
        lvADOQuery.Open;
        lvCounter := GetTickCount - lvCounter;

        lvDebug := '��SQL(ADOQuery.Open)��ʱ:' + intToStr(lvCounter) + sLineBreak;

        lvCounter := GetTickCount;
        lvStream := TADOTools.saveToStream(lvADOQuery);
        try
          lvCounter := GetTickCount - lvCounter;
          lvDebug := 'ADO�����ݴ�С:' + FloatToStr(lvStream.Size/1000.00) + 'KB' + sLineBreak + lvDebug + '���ADOQuery������ʱ:' + intToStr(lvCounter) + sLineBreak;
          lvStream.Position := 0;
          lvJsonStream.Json.S['debug'] := lvDebug;
          lvJsonStream.Stream.CopyFrom(lvStream, lvStream.Size);
          lvJsonStream.setResult(True);
        finally
          lvStream.Free;
        end;
      finally
        lvADOQuery.Free;
      end;
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
end;

procedure TClientContext.DoDisconnect;
begin
  inherited;
end;



procedure TClientContext.DoOnWriteBack;
begin
  inherited;

end;

end.
