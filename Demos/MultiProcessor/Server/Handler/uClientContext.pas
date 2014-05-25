unit uClientContext;
                               
interface

uses
  Windows, uBuffer, SyncObjs, Classes, SysUtils,
  uIOCPCentre, JSonStream, uIOCPFileLogger;

type
  TClientContext = class(TIOCPClientContext)
  protected
    procedure DoConnect; override;
    procedure DoDisconnect; override;
    procedure DoOnWriteBack; override;

    procedure recvBuffer(buf:PAnsiChar; len:Cardinal); override;

  public


    

  end;

implementation

uses
  uIOCPDebugger, uWorkDispatcher;

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

procedure TClientContext.recvBuffer(buf:PAnsiChar; len:Cardinal);
var
  lvObject:TObject;
begin
  add2Buffer(buf, len);

  self.StateINfo := '���յ�����,׼�����н���';

  while True do
  begin
    //����ע��Ľ�����<���н���>
    lvObject := decodeObject;
    if lvObject <> nil then
    begin
      try
        self.StateINfo := '����ɹ�,׼��Ͷ�ݵ��������';

        TIOCPDebugger.incRecvObjectCount;

        //����ɹ���Ͷ�ݵ�����
        workDispatcher.push(lvObject, self);
      except
        on E:Exception do
        begin
          TIOCPFileLogger.logErrMessage('�ػ����߼��쳣!' + e.Message);
        end;
      end;
    end else
    begin
      //������û�п���ʹ�õ��������ݰ�,����ѭ��
      Break;
    end;
  end;

  //������<���û�п��õ��ڴ��>����
  clearRecvedBuffer;
end;

end.
