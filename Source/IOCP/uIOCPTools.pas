unit uIOCPTools;

interface

uses
  winsock2, Windows, SysUtils, Classes;

const
  SIO_KEEPALIVE_VALS = IOC_IN or IOC_VENDOR or 4;

type
  TKeepAlive = record
    OnOff: Integer;
    KeepAliveTime: Integer;
    KeepAliveInterval: Integer;
  end;
  TTCP_KEEPALIVE = TKeepAlive;
  PTCP_KEEPALIVE = ^TKeepAlive;

  TIOCPTools = class(TObject)
  public
  
    /// <summary>
    ///   socket��������
    ///   �������������ϵͳ��ÿ�����м���һ�ε���������������ͻ��˶����Ժ����߶ϣ�������GetQueuedCompletionStatus�᷵��FALSE��
    /// if (GetQueuedCompletionStatus(CompletionPort, BytesTransferred,DWORD(
    /// PerHandleData), POverlapped(PerIoData), INFINITE) = False) then
    /// begin
    ///    //�����ﴦ��ͻ��˶�����Ϣ��
    /// ��continue;
    /// end;
    /// </summary>
    /// <param name="socket"> (TSocket) </param>
    class function socketInitializeHeart(const socket:TSocket): Boolean;

    
    class procedure checkSocketInitialize;

    class function getCPUNumbers: Integer;
  end;

implementation

uses
  uIOCPFileLogger;


var
  __initialized:Boolean;

class function TIOCPTools.socketInitializeHeart(const socket:TSocket): Boolean;
var
  Opt, insize, outsize: integer;
  outByte: DWORD;
  inKeepAlive, outKeepAlive: TTCP_KEEPALIVE;
begin
  Result := false;
  Opt := 1;
  if SetSockopt(socket, SOL_SOCKET, SO_KEEPALIVE,
     @Opt, sizeof(Opt)) = SOCKET_ERROR then
    CloseSocket(socket);

  inKeepAlive.OnOff := 1;

  //���ã�����ʱ����
  inKeepAlive.KeepAliveTime := 3000;

  //����ÿ�����з��ͣ��ε�����
  inKeepAlive.KeepAliveInterval := 1;
  insize := sizeof(TTCP_KEEPALIVE);
  outsize := sizeof(TTCP_KEEPALIVE);

  if WSAIoctl(socket,
     SIO_KEEPALIVE_VALS,
     @inKeepAlive, insize,
     @outKeepAlive,
    outsize, outByte, nil, nil) = SOCKET_ERROR then
  begin
    TIOCPFileLogger.logWSAError('�����������');
    closeSocket(socket);
  end else
  begin
    Result := true;
  end;

end;

class procedure TIOCPTools.checkSocketInitialize;
var
  lvRET: Integer;
  WSData: TWSAData;
begin
  if __initialized then exit;  
  //��WSAStartup()�ж�Windows Sockets DLL���г�ʼ����Э��Winsock�İ汾֧�֣�
  //�������Ҫ����Դ����Ӧ�ó���ر�Sockets�󣬻�����Ҫ����WSACleanup()��ֹ��Windows Sockets DLL��ʹ�ã����ͷ���Դ���Ա���һ��ʹ�á�
  lvRET := WSAStartup($0202, WSData);
  
  if lvRET <> 0 then
    raise Exception.Create(SysErrorMessage(GetLastError));
    
  __initialized := true;
end;

class function TIOCPTools.getCPUNumbers: Integer;
var
  lvSystemInfo: TSystemInfo;
begin
  GetSystemInfo(lvSystemInfo);
  Result := lvSystemInfo.dwNumberOfProcessors;
end;

end.
