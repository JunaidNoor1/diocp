unit uIOCPWorker;

interface

uses
  Classes, uIOCPCentre, uIOCPProtocol;

type
  TIOCPWorker = class(TThread)
  private
    FIOCPObject: TIOCPObject;
  public
    procedure Execute;override;
    procedure SetIOCPObject(const pvValue: TIOCPObject);
  end;

implementation

uses
  SysUtils, uIOCPFileLogger;

{ TIOCPWorker }

procedure TIOCPWorker.Execute;
var
   lvRET:Integer;
begin
   //�õ������߳��Ǵ��ݹ�����IOCP
   while(not self.Terminated) do
   begin
     try
       try
         lvRET := FIOCPObject.processIOQueued;
         if lvRET = IOCP_RESULT_EXIT then
         begin
           TIOCPFileLogger.logDebugMessage('TIOCPWorker.FIOCPObject.processIOQueued, �����߳��Ѿ��˳�!');
           Exit;
         end;
       except
          on E:Exception do
          begin
            TIOCPFileLogger.logErrMessage('TIOCPWorker.FIOCPObject.processIOQueued, �����쳣:' + e.Message);
          end;
       end;
     except
     end;
   end;
end;

procedure TIOCPWorker.SetIOCPObject(const pvValue: TIOCPObject);
begin
  FIOCPObject := pvValue;
end;

end.
