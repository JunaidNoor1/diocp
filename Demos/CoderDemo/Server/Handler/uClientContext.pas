unit uClientContext;

interface

uses
  Windows, JwaWinsock2, uBuffer, SyncObjs, Classes, SysUtils,
  uIOCPCentre, uMyObject;

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
  Math;





procedure TClientContext.dataReceived(const pvDataObject:TObject);
var
  lvMyObject:TMyObject;
begin
  lvMyObject := TMyObject(pvDataObject);
  try
    //ֱ�ӻش�
    writeObject(lvMyObject);
  except
    on E:Exception do
    begin
      lvMyObject.DataString := E.Message;
      writeObject(lvMyObject);
    end;
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
