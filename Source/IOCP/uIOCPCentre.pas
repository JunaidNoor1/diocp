unit uIOCPCentre;


{$if CompilerVersion>= 23}
  {$define NEED_NativeUInt}
{$ifend}


interface

uses
  JwaWinsock2, Windows, SysUtils, uIOCPTools,
  uMemPool,
  uIOCPProtocol, uBuffer, SyncObjs, Classes, IdGlobal;

type
  TIOCPClientContext = class;
  TIOCPClientContextClass = class of TIOCPClientContext;

  TIOCPDecoder = class(TObject)
  public
    /// <summary>
    ///   �����յ�������,����н��յ�����,���ø÷���,���н���
    /// </summary>
    /// <returns>
    ///   ���ؽ���õĶ���
    /// </returns>
    /// <param name="inBuf"> ���յ��������� </param>
    function Decode(const inBuf: TBufferLink): TObject; virtual; abstract;
  end;

  TIOCPEncoder = class(TObject)
  public
    /// <summary>
    ///   ����Ҫ�����Ķ���
    /// </summary>
    /// <param name="pvDataObject"> Ҫ���б���Ķ��� </param>
    /// <param name="ouBuf"> ����õ����� </param>
    procedure Encode(pvDataObject:TObject; const ouBuf: TBufferLink); virtual;
        abstract;
  end;

  TIOCPContextPool = class(TObject)
  private
    FBusyCount:Integer;
    FCS:TCriticalSection;
    FContextClass:TIOCPClientContextClass;
    FList: TList;
    function DoInnerCreateContext: TIOCPClientContext;

    procedure clear;
    function GetCount: Integer;
  public
    constructor Create;

    destructor Destroy; override;
    
    function createContext(ASocket: TSocket): TIOCPClientContext;

    procedure freeContext(context: TIOCPClientContext);

    property BusyCount: Integer read FBusyCount;

    property count: Integer read Getcount;
  end;
  



  TIOCPObject = class(TObject)
  private
    FCS: TCriticalSection;

    //���ߵ��б�
    FContextOnLineList: TList;

    //������׽���
    FSSocket:Cardinal;

    //IOCP�ں˶˿�
    FIOCoreHandle:Cardinal;

    //�����˿�
    FPort: Integer;

    //��ӵ������б�
    procedure Add(pvContext:TIOCPClientContext);

    //�������б����Ƴ�
    procedure Remove(pvContext:TIOCPClientContext);

    function PostWSASendBlock(pvSocket: TSocket; pvIOData: POVERLAPPEDEx): Boolean;

  public
    constructor Create;

    destructor Destroy; override;
    // <summary>
    //   ����IOCP�˿�
    // </summary>
    function createIOCPCoreHandle: Boolean;

    //����һ���ͻ�������
    procedure acceptClient;

    //��������˶˿�
    function createSSocket: Boolean;

    //�رշ���˶˿�
    procedure closeSSocket;

    /// <summary>
    ///   �ر���������
    /// </summary>
    procedure DisconnectAllClientContext;


    //1 �ȴ���Դ�Ļع�
    procedure WaiteForResGiveBack;


    /// <summary>
    ///   Ͷ��һ���˳�����
    /// </summary>
    procedure PostExitIO;


    /// <summary>
    ///   ����һ��IO����
    /// </summary>
    function processIOQueued: Integer;


    /// <summary>
    ///    �������Ͷ�ݷ�����������
    /// </summary>
    /// <param name="pvSocket"> (TSocket) </param>
    /// <param name="ouBuf"> (TBufferLink) </param>
    procedure PostWSASend(pvSocket: TSocket; const ouBuf: TBufferLink);

    /// <summary>
    ///   ��IOCP������Ͷ�ݹرտͻ�������
    /// </summary>
    /// <param name="pvClientContext"> (TIOCPClientContext) </param>
    function PostWSAClose(pvClientContext:TIOCPClientContext): Boolean;

    /// <summary>
    ///    �������Ͷ��һ��������������
    /// </summary>
    procedure PostWSARecv(const pvClientContext: TIOCPClientContext);

    //���������˿�
    function ListenerBind: Boolean;

    //�����˿�
    property Port: Integer read FPort write FPort;

  end;


  TIOCPClientContext = class(TObject)
  private
    //����ʹ��
    FUsing:Boolean;

    //�Ѿ�Ͷ���˹ر�����
    FPostedCloseQuest:Boolean;

    FCS:TCriticalSection;

    FIOCPObject:TIOCPObject;

    FSocket: TSocket;

    FBuffers: TBufferLink;

    //�رտͻ�������
    procedure closeClientSocket;

    //Ͷ��һ���ر�����
    function PostWSAClose: Boolean;
  protected
    procedure DoConnect;virtual;
    procedure DoDisconnect;virtual;
    procedure DoOnWriteBack; virtual;

  public
    procedure notifyStopWork; virtual;

    constructor Create(ASocket: TSocket = 0);


    /// <summary>
    ///   ���ݴ���
    /// </summary>
    /// <param name="pvDataObject"> (TObject) </param>
    procedure dataReceived(const pvDataObject:TObject); virtual;

    procedure close;


    /// <summary>
    ///   �����ݷ��ظ��ͻ���
    /// </summary>
    /// <param name="pvDataObject"> (TObject) </param>
    procedure writeObject(const pvDataObject:TObject);

    procedure RecvBuffer(buf:PAnsiChar; len:Cardinal);

    function AppendBuffer(buf:PAnsiChar; len:Cardinal): Cardinal;

    function readBuffer(buf:PAnsiChar; len:Cardinal): Cardinal;

    destructor Destroy; override;

    property Buffers: TBufferLink read FBuffers;
    
    //property Socket: TSocket read FSocket;
  end;




  TIOCPContextFactory = class(TObject)
  private
    FIOCPContextPool: TIOCPContextPool;
    FDecoder:TIOCPDecoder;
    FEncoder:TIOCPEncoder;
  public
    class function instance: TIOCPContextFactory;
  public
    constructor Create;
    destructor Destroy; override;

    function createContext(ASocket: TSocket): TIOCPClientContext;

    procedure freeContext(context: TIOCPClientContext);

    /// <summary>
    ///   ע��ͻ��˴�����
    /// </summary>
    /// <param name="pvClass"> (TIOCPClientContextClass) </param>
    procedure registerClientContextClass(pvClass:TIOCPClientContextClass);
    
    /// <summary>
    ///   ע�������
    /// </summary>
    /// <param name="pvDecoder"> (TIOCPDecoder) </param>
    procedure registerDecoder(pvDecoder:TIOCPDecoder);

    /// <summary>
    ///   ע�������
    /// </summary>
    /// <param name="pvEncoder"> (TIOCPEncoder) </param>
    procedure registerEncoder(pvEncoder:TIOCPEncoder);
    
    property IOCPContextPool: TIOCPContextPool read FIOCPContextPool;
  end;

implementation

uses
  uIOCPFileLogger;


var
  __factoryInstance:TIOCPContextFactory;

constructor TIOCPObject.Create;
begin
  inherited Create;
  FContextOnLineList := TList.Create();
  FCS := TCriticalSection.Create();
end;

destructor TIOCPObject.Destroy;
begin
  FreeAndNil(FCS);
  FreeAndNil(FContextOnLineList);
  inherited Destroy;
end;

procedure TIOCPObject.acceptClient;
var
  lvSocket: TSocket;

  lvPerIOPort:THandle;

  lvIOData:POVERLAPPEDEx;

  lvClientContext:TIOCPClientContext;

  lvErr:Integer;
begin
  //  If no error occurs, WSAAccept returns a value of type SOCKET
  //  that is a descriptor for the accepted socket.
  //  Otherwise, a value of INVALID_SOCKET is returned,
  //  and a specific error code can be retrieved by calling WSAGetLastError.
  
  lvSocket := WSAAccept(FSSocket, nil, nil, nil, 0);
  if (lvSocket = INVALID_SOCKET) then
  begin
    TIOCPFileLogger.logWSAError('�����µĿͻ������ӳ����쳣!');
  end else
  begin
    
    //��������
    TIOCPTools.socketInitializeHeart(lvSocket);

    ///
    lvClientContext := TIOCPContextFactory.instance.createContext(lvSocket);
    lvClientContext.FIOCPObject := Self;
    lvClientContext.DoConnect;

     //���׽��֡���ɶ˿ڿͻ��˶������һ��
     //2013��4��20�� 13:45:10
     lvPerIOPort := CreateIoCompletionPort(lvSocket, FIOCoreHandle, Cardinal(lvClientContext), 0);
     if (lvPerIOPort = 0) then
     begin
        Exit;
     end;
     ////----end

     //��ʼ�����ݰ�
     lvIOData := TIODataMemPool.instance.borrowIOData;

     //���ݰ��е�IO����:����������
     lvIOData.IO_TYPE := IO_TYPE_Accept;

     //֪ͨ�����߳�,���µ��׽�������<����������>
     if not PostQueuedCompletionStatus(
        FIOCoreHandle,
        1,   ///>>>��1, 0�Ļ���Ͽ�����
      {$if defined(NEED_NativeUInt)}
        NativeUInt(lvClientContext),
      {$ELSE}
        Cardinal(lvClientContext),
      {$ifend}
        POverlapped(lvIOData)) then
     begin     
       //Ͷ��ʧ��
       lvErr := GetLastError;
       TIOCPFileLogger.logErrMessage('acceptClient>>PostQueuedCompletionStatusͶ����������ʧ��!');

       //�ر�
       TIOCPContextFactory.instance.freeContext(lvClientContext);

       //�黹
       TIODataMemPool.instance.giveBackIOData(lvIOData);
     end;
  end;
end;

procedure TIOCPObject.Add(pvContext: TIOCPClientContext);
begin
  FCS.Enter;
  try
    FContextOnLineList.Add(pvContext);
  finally
    FCS.Leave;
  end;
end;

procedure TIOCPObject.closeSSocket;
begin
  CloseSocket(FSSocket);
  FSSocket := INVALID_HANDLE_VALUE;
end;

function TIOCPObject.createIOCPCoreHandle: Boolean;
begin
  // ����һ����ɶ˿ڣ��ں˶���
  FIOCoreHandle := CreateIoCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 0);
  Result := (FIOCoreHandle <> 0) and (FIOCoreHandle <> INVALID_HANDLE_VALUE);
  if not Result then
  begin
    TIOCPFileLogger.logErrMessage('����IOCP�ں˶���������쳣,�������:' + IntToStr(GetLastError));
  end;
end;

function TIOCPObject.createSSocket: Boolean;
begin    
  Result := false;
  
  FSSocket:=WSASocket(AF_INET,SOCK_STREAM,IPPROTO_IP,Nil,0,WSA_FLAG_OVERLAPPED);
  if FSSocket=SOCKET_ERROR then
  begin
    TIOCPFileLogger.logWSAError('��������˶˿�!');
    CloseSocket(FSSocket);
    FSSocket := INVALID_HANDLE_VALUE;
  end;
  
  //��������
  if TIOCPTools.socketInitializeHeart(FSSocket) then
  begin
    Result := true;
  end;
end;

procedure TIOCPObject.DisconnectAllClientContext;
var
  i:Integer;
begin
  FCS.Enter;
  try
    for i := FContextOnLineList.Count - 1 downto 0 do
    begin
       //֪ͨ�˳�
       TIOCPClientContext(FContextOnLineList[i]).notifyStopWork;
    end;
  finally
    FCS.Leave;
  end;
end;

procedure TIOCPObject.PostExitIO;
begin
   //֪ͨ�����߳�,���µ��׽�������<����������>
   PostQueuedCompletionStatus(
      FIOCoreHandle,
      1,   ///>>>��1, 0�Ļ���Ͽ�����
      0,
      POverlapped(IOCP_Queued_SHUTDOWN)
    );
end;

procedure TIOCPObject.PostWSARecv(const pvClientContext: TIOCPClientContext);
var
  lvIOData:POVERLAPPEDEx;
  lvRet:Integer;
begin
  /////�����ڴ�<���Լ����ڴ��>
  lvIOData := TIODataMemPool.instance.borrowIOData;
  lvIOData.IO_TYPE := IO_TYPE_Recv;

  /////�첽��ȡ����
  if (WSARecv(pvClientContext.FSocket,
     @lvIOData.DataBuf,
     1,
     lvIOData.WorkBytes,
     lvIOData.WorkFlag,
     @lvIOData^, nil) = SOCKET_ERROR) then
  begin
    //MSDN:
    //If no error occurs and the receive operation has completed immediately,
    //WSARecv returns zero. In this case,
    //the completion routine will have already been scheduled to be called once the calling thread is in the alertable state.
    //Otherwise, a value of SOCKET_ERROR is returned, and a specific error code can be retrieved by calling WSAGetLastError.
    //The error code WSA_IO_PENDING indicates that the overlapped operation has been successfully
    //initiated and that completion will be indicated at a later time. Any other error code indicates that the overlapped operation
    //was not successfully initiated and no completion indication will occur.

    lvRet := WSAGetLastError();
    //�ص�IO,����ERROR_IO_PENDING�������ģ�
    //��ʾ������δ������ɣ���������ݽ��գ�GetQueuedCompletionStatus���з���ֵ
    if (lvRet <> WSA_IO_PENDING) then
    begin
      TIODataMemPool.instance.giveBackIOData(lvIOData);      
      
      TIOCPFileLogger.logErrMessage('TIOCPObject.PostWSARecv,Ͷ��WSARecv�����쳣,socket�����˹ر�, �������:' + IntToStr(lvRet));

      pvClientContext.PostWSAClose;
    end;
  end;
end;

procedure TIOCPObject.PostWSASend(pvSocket: TSocket; const ouBuf: TBufferLink);
var
  lvIOData:POVERLAPPEDEx;
  lvErrCode, lvRet:Integer;
begin
  while ouBuf.validCount > 0 do
  begin
    lvIOData := TIODataMemPool.instance.borrowIOData;
    lvIOData.IO_TYPE := IO_TYPE_Send;
    lvIOData.DataBuf.len := ouBuf.readBuffer(lvIOData.DataBuf.buf, lvIOData.DataBuf.len);

    //����һ���ڴ��
    if not PostWSASendBlock(pvSocket, lvIOData) then
    begin
      //���Ͳ��ɹ�
      TIODataMemPool.instance.giveBackIOData(lvIOData);
      closesocket(pvSocket);
      Break;
    end;
  end;
end;

function TIOCPObject.PostWSASendBlock(pvSocket: TSocket; pvIOData:
    POVERLAPPEDEx): Boolean;
var
  lvErrCode, lvRet, i:Integer;
begin
  i := 1;
  Result := False;
  while i<=10 do    //����10��,��������ɹ��ͷ���false
  begin
    //������̷��ͳɹ�  0Ҳ�ᴥ������
    lvRet :=WSASend(pvSocket,
       @pvIOData.DataBuf,
       1,
       pvIOData.WorkBytes,
       pvIOData.WorkFlag,
       @pvIOData^, nil);
    if (lvRet = SOCKET_ERROR) then
    begin
      lvErrCode := GetLastError();
      case lvErrCode of
        ERROR_IO_PENDING:
         begin     //����ERROR_IO_PENDING�������ģ���ʾ������δ������ɣ�
                   //������ݷ��ͳɹ���GetQueuedCompletionStatus���з���ֵ
            Result := true;
            Break;
         end;

        //���ȣ�Winsock �쳣 10035 WSAEWOULDBLOCK (WSAGetLastError) ����ʶ�� Output Buffer �Ѿ����ˣ��޷���д�����ݡ�
        //ȷ�е�˵����ʵ�����Ǹ����󣬳��������쳣�ľ��󲿷�ʱ����ʵ�������� Output Buffer ������������Ǵ���һ�֡�æ����״̬��
        //�����֡�æ����״̬���ܴ�̶��������ڽ��շ���ɵġ�
        //��˼������Ҫ���͵Ķ��󣬶Է��յ�û�㷢�Ŀ���߶Է��Ľ��ܻ������ѱ����������Ծͷ�����һ����æ���ı�־������ʱ���ٷ��������ݶ�û�κ����壬
        //�������ϵͳ���׳��� WSAEWOULDBLOCK �쳣֪ͨ�㣬�������Ϲæ���ˡ�
        WSAEWOULDBLOCK:
          begin
             //��Ϣ100���ȴ��ٴη���
             TIOCPFileLogger.logErrMessage(Format('Ͷ�ݷ�������ʱ�����˴���������:%d', [lvErrCode]));
             Sleep(100);
          end;
        WSAECONNRESET:
          begin       //An existing connection was forcibly closed by the remote host
            TIOCPFileLogger.logErrMessage(Format('Ͷ�ݷ�������ʱ�����˴���������:%d', [lvErrCode]));
            Result := false;
            Break;
          end;
        WSAENETRESET:  //Network dropped connection on reset.
          begin //The connection has been broken due to keep-alive
                //activity detecting a failure while the operation was in progress.
            TIOCPFileLogger.logErrMessage(Format('Ͷ�ݷ�������ʱ�����˴���������:%d', [lvErrCode]));
            Result := false;
            Break;
          end;
      else
        begin     //�˳�ѭ��
          TIOCPFileLogger.logErrMessage(Format('Ͷ�ݷ�������ʱ�����˴���������:%d', [lvErrCode]));
          Result := false;
          Break;
        end;
      end;
    end else
    begin    //û�д���,�������
      Result := true;
      Break;
    end;
  end;
end;

function TIOCPObject.processIOQueued: Integer;
var
  BytesTransferred:Cardinal;
  lvResultStatus:BOOL;
  lvRet:Integer;
  lvIOData:POVERLAPPEDEx;

  lvDataObject:TObject;

  lvClientContext:TIOCPClientContext;
begin
  Result := IOCP_RESULT_OK;

  //�������̻߳�ֹͣ��GetQueuedCompletionStatus��������ֱ�����ܵ�����Ϊֹ
  lvResultStatus := GetQueuedCompletionStatus(FIOCoreHandle,
    BytesTransferred,
    {$if defined(NEED_NativeUInt)}
      NativeUInt(lvClientContext),
    {$ELSE}
      Cardinal(lvClientContext),
    {$ifend}

    POverlapped(lvIOData),
    INFINITE);

  if DWORD(lvIOData) = IOCP_Queued_SHUTDOWN then
  begin
    TIOCPFileLogger.logDebugMessage('�����̱߳�֪ͨ�˳�!');
    Result := IOCP_RESULT_EXIT;     //֪ͨ���������˳�
  end else if (lvResultStatus = False) then
  begin
    //���ͻ������ӶϿ����߿ͻ��˵���closesocket������ʱ��,����GetQueuedCompletionStatus�᷵�ش���������Ǽ���������������Ϳ������ж��׽����Ƿ���Ȼ�����ӡ�
    lvRet := GetLastError;

    //{ The specified network name is no longer available. }
    if lvRet = ERROR_NETNAME_DELETED then
    begin

    end;
    
    TIOCPFileLogger.logErrMessage('GetQueuedCompletionStatus����False,�������:' + IntToStr(lvRet));

    if (lvClientContext<>nil) then
    begin
      TIOCPContextFactory.instance.freeContext(lvClientContext);
    end;
    if lvIOData<>nil then
    begin
      TIODataMemPool.instance.giveBackIOData(lvIOData);
    end;
  end else if BytesTransferred = 0 then  //�ͻ��˶Ͽ�����
  begin
    TIOCPFileLogger.logDebugMessage('�ͻ��˶Ͽ�!');
    if (lvClientContext <> nil) then
    begin                       //�Ѿ��ر�
      TIOCPContextFactory.instance.freeContext(lvClientContext);
      lvClientContext := nil;
    end;
    if lvIOData<>nil then
    begin
      TIODataMemPool.instance.giveBackIOData(lvIOData);
    end;
  end else if (lvIOData<>nil) then
  begin
    if lvIOData.IO_TYPE = IO_TYPE_Accept then  //��������
    begin
      TIODataMemPool.instance.giveBackIOData(lvIOData);
      PostWSARecv(lvClientContext);
    end else if lvIOData.IO_TYPE = IO_TYPE_Recv then
    begin
      //���뵽�׽��ֶ�Ӧ�Ļ����У������߼�
      lvClientContext.RecvBuffer(lvIOData.DataBuf.buf,
        lvIOData.Overlapped.InternalHigh);

      TIODataMemPool.instance.giveBackIOData(lvIOData);

      //����Ͷ�ݽ�������
      PostWSARecv(lvClientContext);
    end else if lvIOData.IO_TYPE = IO_TYPE_Send then
    begin    //�����������<WSASend>���
      //�������ݿ�
      TIODataMemPool.instance.giveBackIOData(lvIOData);
      //����ҪͶ�ݽ�������
      
    end else if lvIOData.IO_TYPE = IO_TYPE_Close then
    begin    //�ر�����

      //�������ݿ�
      TIODataMemPool.instance.giveBackIOData(lvIOData);

      //�رջ���lvClientContext,iocp�����л����ڶ�Ӧsocket�Ľ�������
      TIOCPContextFactory.instance.freeContext(lvClientContext);
      //����ҪͶ�ݽ�������
    end;    
  end;
end;

procedure TIOCPObject.Remove(pvContext: TIOCPClientContext);
begin
  FCS.Enter;
  try
    FContextOnLineList.Remove(pvContext);
  finally
    FCS.Leave;
  end;                                   
end;

function TIOCPObject.ListenerBind: Boolean;
var
  lvAddr:TSockAddr;
  lvAddrSize:Integer;
begin
  result := false;
  lvAddr.sin_family:=AF_INET;
  lvAddr.sin_port:=htons(FPort);
  lvAddr.sin_addr.s_addr:=htonl(INADDR_ANY);
  if bind(FSSocket,@lvAddr,sizeof(lvAddr))=SOCKET_ERROR then
  begin
    TIOCPFileLogger.logWSAError('��(bind,FSSocket)�����쳣!');
    Closesocket(FSSocket);
    exit;
  end;

  //If no error occurs, listen returns zero. Otherwise,
  //a value of SOCKET_ERROR is returned, and a specific error code
  // can be retrieved by calling WSAGetLastError.
  if listen(FSSocket,20) = SOCKET_ERROR then
  begin
    TIOCPFileLogger.logWSAError('��(bind,FSSocket)�����쳣!');
    Closesocket(FSSocket);
    exit;
  end;

  Result := true;
end;

function TIOCPObject.PostWSAClose(pvClientContext:TIOCPClientContext): Boolean;
var
   lvIOData:POVERLAPPEDEx;
   lvErr:Integer;
begin
   if pvClientContext.FPostedCloseQuest then Exit;
   
   //��ʼ�����ݰ�
   lvIOData := TIODataMemPool.instance.borrowIOData;
   //���ݰ��е�IO����:�ر�����
   lvIOData.IO_TYPE := IO_TYPE_Close;

   //֪ͨ�����߳�,���µ��׽�������<����������>
   if not PostQueuedCompletionStatus(
      FIOCoreHandle,
      1,   ///>>>��1, 0�Ļ���Ͽ�����
      Cardinal(pvClientContext),
      POverlapped(lvIOData)) then
   begin
     lvErr := GetLastError;
     TIOCPFileLogger.logErrMessage('PostWSAClose>>PostQueuedCompletionStatusͶ�ݹر�����ʧ��!');
   end else
   begin   
    pvClientContext.FPostedCloseQuest := true;
    Result := true;
   end;
end;

procedure TIOCPObject.WaiteForResGiveBack;
begin
  TIODataMemPool.instance.waiteForGiveBack;
end;

procedure TIOCPClientContext.close;
begin
  PostWSAClose;
end;

procedure TIOCPClientContext.closeClientSocket;
begin
  if (FSocket <> INVALID_SOCKET) and (FSocket <> 0) then
  begin
    DoDisconnect;
    closesocket(FSocket);
    FSocket := INVALID_SOCKET;
    FBuffers.clearBuffer;
  end;
end;

constructor TIOCPClientContext.Create(ASocket: TSocket = 0);
begin
  inherited Create;
  FUsing := false;
  FCS := TCriticalSection.Create;
  FSocket := ASocket;
  FBuffers := TBufferLink.Create();
end;

destructor TIOCPClientContext.Destroy;
begin
  FBuffers.Free;
  FBuffers := nil;
  closeClientSocket;
  FCS.Free;
  FCS := nil;
  inherited Destroy;
end;

procedure TIOCPClientContext.DoConnect;
begin
  FIOCPObject.Add(Self);  
end;

procedure TIOCPClientContext.DoDisconnect;
begin
  FIOCPObject.Remove(Self);
end;

function TIOCPClientContext.AppendBuffer(buf:PAnsiChar; len:Cardinal): Cardinal;
begin
  FBuffers.AddBuffer(buf, len);
end;

procedure TIOCPClientContext.notifyStopWork;
begin
  //��ֹ����
  shutdown(FSocket, SD_BOTH);

  //Ͷ�ݹر��¼�
  postWSAClose;
  //shutdown(FSocket, SD_BOTH);
  //CancelIo(FSocket);
end;

procedure TIOCPClientContext.dataReceived(const pvDataObject:TObject);
begin
  
end;

procedure TIOCPClientContext.DoOnWriteBack;
begin
  
end;

function TIOCPClientContext.PostWSAClose: Boolean;
begin
  //�Ѿ�����
  if self.FUsing = false then Exit;

  Result :=FIOCPObject.PostWSAClose(Self);
end;

function TIOCPClientContext.readBuffer(buf:PAnsiChar; len:Cardinal): Cardinal;
begin
  Result := FBuffers.readBuffer(buf, len);
end;

procedure TIOCPClientContext.RecvBuffer(buf:PAnsiChar; len:Cardinal);
var
  lvObject:TObject;
begin
  FCS.Enter;
  try
    //���뵽�׽��ֶ�Ӧ�Ļ���
    FBuffers.AddBuffer(buf, len);

    //����ע��Ľ�����<���н���>
    lvObject := TIOCPContextFactory.instance.FDecoder.Decode(FBuffers);
    if lvObject <> nil then
    try
      //����ɹ�������ҵ���߼��Ĵ�����
      dataReceived(lvObject);

      //�������һ�η�����ڴ�
      FBuffers.clearBuffer;
    finally
      lvObject.Free;
    end;
  finally
    FCS.Leave;
  end;
end;

procedure TIOCPClientContext.writeObject(const pvDataObject:TObject);
var
  lvOutBuffer:TBufferLink;
begin
  lvOutBuffer := TBufferLink.Create;
  try
    TIOCPContextFactory.instance.FEncoder.Encode(pvDataObject, lvOutBuffer);
    FIOCPObject.PostWSASend(self.FSocket, lvOutBuffer);
    DoOnWriteBack;
  finally
    lvOutBuffer.Free;
  end;
end;

constructor TIOCPContextFactory.Create;
begin
  inherited Create;
  FIOCPContextPool := TIOCPContextPool.Create();
end;

destructor TIOCPContextFactory.Destroy;
begin
  FreeAndNil(FIOCPContextPool);
  inherited Destroy;
end;

function TIOCPContextFactory.createContext(ASocket: TSocket):
    TIOCPClientContext;
begin
  Result := FIOCPContextPool.createContext(ASocket);
end;

procedure TIOCPContextFactory.freeContext(context: TIOCPClientContext);
begin
  FIOCPContextPool.freeContext(context);
end;

class function TIOCPContextFactory.instance: TIOCPContextFactory;
begin
  Result := __factoryInstance;
end;

procedure TIOCPContextFactory.registerClientContextClass(
    pvClass:TIOCPClientContextClass);
begin
  FIOCPContextPool.FContextClass := pvClass;
end;

procedure TIOCPContextFactory.registerDecoder(pvDecoder:TIOCPDecoder);
begin
  FDecoder := pvDecoder;
end;

procedure TIOCPContextFactory.registerEncoder(pvEncoder:TIOCPEncoder);
begin
  FEncoder := pvEncoder;
end;

constructor TIOCPContextPool.Create;
begin
  inherited Create;
  FBusyCount := 0;
  FCS := TCriticalSection.Create;
  FList := TList.Create();
end;

function TIOCPContextPool.createContext(ASocket: TSocket): TIOCPClientContext;
begin
  FCS.Enter;
  try
    if FList.Count = 0 then
    begin
      Result := DoInnerCreateContext;
    end else
    begin
      Result := TIOCPClientContext(FList[0]);
      FList.Delete(0);
    end;
    Result.FSocket := ASocket;
    Result.FUsing := true;
    Inc(FBusyCount);
  finally
    FCS.Leave;
  end;
end;

destructor TIOCPContextPool.Destroy;
begin
  clear;
  FCS.Free;
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TIOCPContextPool.clear;
begin
  FCS.Enter;
  try
    while FList.Count > 0 do
    begin
      TIOCPClientContext(FList[0]).Free;
      FList.Delete(0);
    end;
  finally
    FCS.Leave;
  end;
end;

function TIOCPContextPool.DoInnerCreateContext: TIOCPClientContext;
begin
  if FContextClass = nil then raise Exception.Create('û��ע��FContextClass');
  Result := FContextClass.Create();
end;


procedure TIOCPContextPool.freeContext(context: TIOCPClientContext);
begin
  FCS.Enter;
  try
    if not context.FUsing then exit;  //�Ѿ�����

    try
      //�ر�
      context.CloseClientSocket;
    except
      on E:Exception do
      begin
        TIOCPFileLogger.logErrMessage('����contextʱִ��CloseClientSocket�������쳣!' + e.Message);
      end;                                                                                                  
    end;
    
    //����ʹ��
    context.FUsing := False;
    
    FList.Add(context);

    Dec(FBusyCount);
  finally
    FCS.Leave;
  end;
end;

function TIOCPContextPool.GetCount: Integer;
begin
  FCS.Enter;
  try
    Result := FBusyCount + FList.Count;
  finally
    FCS.Leave;
  end;
end;

initialization
  __factoryInstance := TIOCPContextFactory.Create;

finalization
  __factoryInstance.Free;
  __factoryInstance := nil;

end.
