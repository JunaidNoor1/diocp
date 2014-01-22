unit uClientContext;

interface

uses
  Windows, JwaWinsock2, uBuffer, SyncObjs, Classes, SysUtils, uIOCPCentre;

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
  TesterINfo, JSonStream;



procedure TClientContext.dataReceived(const pvDataObject:TObject);
var
  lvJsonStream:TJSonStream;
  lvFile:String;
  lvCmdIndex:Cardinal;
begin
  lvJsonStream := TJSonStream(pvDataObject);

  lvCmdIndex := lvJsonStream.JSon.I['cmdIndex'];

  //echo����
  if lvCmdIndex= 1000 then
  begin
    InterlockedIncrement(TesterINfo.__RecvTimes);
    //��д����
    writeObject(lvJsonStream);
  end else if lvCmdIndex= 2000 then
  begin
    Sleep(1000 * 60 * 1);
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
