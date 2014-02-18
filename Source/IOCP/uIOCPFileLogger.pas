unit uIOCPFileLogger;

interface

uses
  FileLogger, SysUtils;

type
  TIOCPFileLogger = class(TObject)
  public
    class procedure checkInitialize;
    class procedure checkFinalize;
    class procedure logErrMessage(pvMsg:string);
    class procedure logMessage(pvMsg:string);
    class procedure logDebugMessage(pvMsg:string);

    class procedure logWSAError(pvPre: String = '');
  end;

implementation

uses
  Winsock2;

var
  FErrLogger:TFileLogger;
  FLogger:TFileLogger;
  FDebugger:TFileLogger;

class procedure TIOCPFileLogger.checkFinalize;
begin
  if (FErrLogger <> nil) then
  begin
    FErrLogger.Free;
    FErrLogger:=nil;
  end;
  if (FLogger <> nil) then
  begin
    FLogger.Free;
    FLogger:=nil;
  end;
  if (FDebugger <> nil) then
  begin
    FDebugger.Free;
    FDebugger:=nil;
  end;
end;

class procedure TIOCPFileLogger.checkInitialize;
begin
  if FErrLogger = nil then
  begin
    FErrLogger := TFileLogger.Create;
    FErrLogger.checkReady;
    FErrLogger.setFilePre('IOCP_ERR_');
    FErrLogger.setAddThreadINfo(True);
  end;
  if FLogger = nil then
  begin
    FLogger := TFileLogger.Create;
    FLogger.checkReady;
    FLogger.setFilePre('IOCP_LOG_');
    FLogger.setAddThreadINfo(True);
  end;
  if FDebugger = nil then
  begin
    FDebugger := TFileLogger.Create;
    FDebugger.checkReady;
    FDebugger.setFilePre('IOCP_DEBUG_');
    FDebugger.setAddThreadINfo(True);
  end;
end;

class procedure TIOCPFileLogger.logDebugMessage(pvMsg:string);
begin
  FDebugger.logMessage(pvMsg);
end;

class procedure TIOCPFileLogger.logErrMessage(pvMsg:string);
begin
  FErrLogger.logMessage(pvMsg);
end;

class procedure TIOCPFileLogger.logMessage(pvMsg:string);
begin
  FLogger.logMessage(pvMsg);
end;

class procedure TIOCPFileLogger.logWSAError(pvPre: String = '');
var
  lvErr:Integer;
  lvMsg:String;
begin
  lvMsg := '';
  lvErr := WSAGetLastError;
  case lvErr of
    WSAEINTR:
      BEGIN
        ///Interrupted function call.
        ////  A blocking operation was interrupted by a call to WSACancelBlockingCall.
        lvMsg :='һ���������������,����������WSACancelBlockingCall,';
      END;  
  end;
  TIOCPFileLogger.logErrMessage(pvPre + lvMsg + '�������:' + IntToStr(lvErr));
end;



initialization
  TIOCPFileLogger.checkInitialize;

finalization
  TIOCPFileLogger.checkFinalize;






end.
