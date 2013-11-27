unit uIOCPCentre;


{$IF CompilerVersion>= 23}
  {$define NEED_NativeUInt}
{$IFEND}


interface

uses
  JwaWinsock2, Windows, SysUtils, uIOCPTools,
  uMemPool,
  uIOCPProtocol, uBuffer, SyncObjs, Classes;

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
    ///   ����Ҫ���͵Ķ���
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
    FUsingList:TList;
    function DoInnerCreateContext: TIOCPClientContext;
    procedure clear;
    function GetCount: Integer;
  public
    constructor Create;

    destructor Destroy; override;

    function createContext(ASocket: TSocket): TIOCPClientContext;

    procedure getUsingList(pvList:TList);

    procedure freeContext(context: TIOCPClientContext);

    property BusyCount: Integer read FBusyCount;



    property count: Integer read Getcount;
  end;
  



  TIOCPObject = class(TObject)
  private
    FDebug_Locker:TCriticalSection;
    FCS: TCriticalSection;

    //���ߵ��б�
    FContextOnLineList: TList;

    //������׽���
    FSSocket:Cardinal;

    //IOCP�ں˶˿�
    FIOCoreHandle:Cardinal;

    //�����˿�
    FPort: Integer;
    FsystemSocketHeartState: Boolean;

    //��ӵ������б�
    procedure Add(pvContext:TIOCPClientContext);

    //�������б����Ƴ�
    function Remove(pvContext:TIOCPClientContext): Boolean;

    function PostWSASendBlock(pvSocket: TSocket; pvIOData: POVERLAPPEDEx): Boolean;

    procedure interlockIncDebugVar(var v:Cardinal; incValue:Cardinal);
    procedure interlockDecDebugVar(var v:Cardinal; decValue:Cardinal);
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

    //�Ƿ���Ĭ�ϵ�socket����
    property systemSocketHeartState: Boolean read FsystemSocketHeartState write
        FsystemSocketHeartState default true;



  end;


  TIOCPClientContext = class(TObject)
  private
    //�����ͷ�
    FNormalFree:Boolean;
    
    FRemoteAddr:String;
    FRemotePort:Integer;

    //����æ....
    //�Ƿ�����æ
    FIsBusying:Boolean;

    //�ȴ����ձ��,��æ����л���
    FWaitingGiveBack:Boolean;

    //����ʹ��
    FUsing:Boolean;

    //�Ѿ�Ͷ���˹ر�����
    FPostedCloseQuest:Boolean;

    FCS:TCriticalSection;

    FIOCPObject:TIOCPObject;

    FSocket: TSocket;

    FBuffers: TBufferLink;
    FStateINfo: String;

    //�رտͻ�������
    procedure closeClientSocket;
    function GetStateINfo: String;

    //Ͷ��һ���ر�����
    function PostWSAClose: Boolean;

    procedure getPeerINfo;

    procedure invokeConnect;
    procedure invokeDisconnect;
    procedure Lock;
    procedure unLock;

    procedure RecvBuffer(buf:PAnsiChar; len:Cardinal);

    function AppendBuffer(buf:PAnsiChar; len:Cardinal): Cardinal;

    function readBuffer(buf:PAnsiChar; len:Cardinal): Cardinal;
  protected
    //��λ<����ʱ���и�λ>
    procedure Reset; virtual;

    //�赽�����øú���
    procedure Initialize4Use; virtual;


    procedure DoConnect; virtual;
    procedure DoDisconnect; virtual;
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



    destructor Destroy; override;

    property Buffers: TBufferLink read FBuffers;
    property RemoteAddr: String read FRemoteAddr;
    property RemotePort: Integer read FRemotePort;

    //״̬��Ϣ
    property StateINfo: String read GetStateINfo write FStateINfo;

    
    
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

    //���Խ��йرտͻ��ˣ������л���
    procedure tryExecuteCloseContext(context: TIOCPClientContext);

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
  uIOCPFileLogger, uIOCPDebugger;


var
  __factoryInstance:TIOCPContextFactory;

constructor TIOCPObject.Create;
begin
  inherited Create;
  FsystemSocketHeartState := true;
  FContextOnLineList := TList.Create();
  FCS := TCriticalSection.Create();
  FDebug_Locker := TCriticalSection.Create();
end;

destructor TIOCPObject.Destroy;
begin
  FDebug_Locker.Free;
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

  addr: Tsockaddrin;
  addrlen: integer;
begin
  //  If no error occurs, WSAAccept returns a value of type SOCKET
  //  that is a descriptor for the accepted socket.
  //  Otherwise, a value of INVALID_SOCKET is returned,
  //  and a specific error code can be retrieved by calling WSAGetLastError.

  addrlen := sizeof(addr);
  //lvSocket := Accept(FSSocket, @addr, @addrlen);
  lvSocket := WSAAccept(FSSocket, nil, nil, nil, 0);
  if (lvSocket = INVALID_SOCKET) then
  begin
    TIOCPFileLogger.logWSAError('�����µĿͻ������ӳ����쳣!');
  end else
  begin

    if FsystemSocketHeartState then
    begin
      //��������
      TIOCPTools.socketInitializeHeart(lvSocket);
    end;


    ///����һ������
    lvClientContext := TIOCPContextFactory.instance.createContext(lvSocket);

     //���׽��֡���ɶ˿ڿͻ��˶������һ��
     //2013��4��20�� 13:45:10
     lvPerIOPort := CreateIoCompletionPort(lvSocket, FIOCoreHandle, Cardinal(lvClientContext), 0);
     if (lvPerIOPort = 0) then
     begin
        Exit;
     end;

    lvClientContext.Initialize4Use;
    lvClientContext.FIOCPObject := Self;
    lvClientContext.getPeerINfo;
    lvClientContext.invokeConnect;


     ////----end

     //�����ӽ��룬Ͷ��һ������
     PostWSARecv(lvClientContext);
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

  if FsystemSocketHeartState then
  begin
    //��������
    if TIOCPTools.socketInitializeHeart(FSSocket) then
    begin
      Result := true;
    end;
  end else
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

procedure TIOCPObject.interlockDecDebugVar(var v: Cardinal; decValue: Cardinal);
begin
  FDebug_Locker.Enter;
  try
    v := v - decValue;
  finally
    FDebug_Locker.Leave;
  end;
end;

procedure TIOCPObject.interlockIncDebugVar(var v: Cardinal; incValue: Cardinal);
begin
  FDebug_Locker.Enter;
  try
    v := v + incValue;
  finally
    FDebug_Locker.Leave;
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
    lvIOData.DataBuf.len :=
      ouBuf.readBuffer(lvIOData.DataBuf.buf, lvIOData.DataBuf.len);

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
  lvErrCode, lvRet, i, l:Integer;
begin
  i := 1;
  Result := False;
  l := pvIOData.DataBuf.len;
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
            TIOCPDebugger.incWSASendbytesSize(l);
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
    end else if lvRet = 0 then
    begin    //û�д���,�������
      //�ɹ�Ͷ��
      //l := pvIOData.DataBuf.len;
      TIOCPDebugger.incWSASendbytesSize(l);
      Result := true;
      Break;
    end else
    begin
      TIOCPFileLogger.logErrMessage(Format('Ͷ�ݷ�������ʱ�����˴���������:%d', [lvErrCode]));
      Result := false;
      Break;
    end;
  end;
end;

function TIOCPObject.processIOQueued: Integer;
var
  lvBytesTransferred:Cardinal;
  lvResultStatus:BOOL;
  lvRet:Integer;
  lvIOData:POVERLAPPEDEx;

  lvDataObject:TObject;

  lvClientContext:TIOCPClientContext;
begin
  Result := IOCP_RESULT_OK;

  //�������̻߳�ֹͣ��GetQueuedCompletionStatus��������ֱ�����ܵ�����Ϊֹ
  lvResultStatus := GetQueuedCompletionStatus(FIOCoreHandle,
    lvBytesTransferred,
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
    if lvRet = ERROR_NETNAME_DELETED then  //64
    begin

    end;

    TIOCPFileLogger.logDebugMessage('GetQueuedCompletionStatus����False,�������:' + IntToStr(lvRet));

    if (lvClientContext<>nil) then
    begin
      //2013��10��24�� 14:56:33
      //����߼����ڴ������߿������ᵼ�¹����̱߳�����
      //���Թرղ��黹ClientContext
      TIOCPContextFactory.instance.tryExecuteCloseContext(lvClientContext);
      lvClientContext := nil;
    end;
    if lvIOData<>nil then
    begin
      TIODataMemPool.instance.giveBackIOData(lvIOData);
    end;
  end else if lvBytesTransferred = 0 then  //�ͻ��˶Ͽ�����
  begin
    if (lvClientContext <> nil) then
    begin                       //�Ѿ��ر�
      //���Թرղ��黹ClientContext
      TIOCPContextFactory.instance.tryExecuteCloseContext(lvClientContext);

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
      try
        try
          //�Ѿ������ֽ���
          TIOCPDebugger.incRecvBytesSize(lvBytesTransferred);
          TIOCPDebugger.incRecvBlockCount;

          lvClientContext.Lock;
          try
            lvClientContext.FIsBusying := true;
            //���뵽�׽��ֶ�Ӧ�Ļ����У������߼�
            lvClientContext.RecvBuffer(lvIOData.DataBuf.buf,
              lvIOData.Overlapped.InternalHigh);
          finally
            lvClientContext.FIsBusying := false;
            lvClientContext.unLock;
          end;

          //��Ҫ���л���
          if lvClientContext.FWaitingGiveBack then
          begin
            TIOCPContextFactory.instance.tryExecuteCloseContext(lvClientContext);
          end else
          begin   //���ٽ����߼��Ĵ���
            //����Ͷ�ݽ�������
            PostWSARecv(lvClientContext);
          end;
        except
          ON E:Exception do
          begin
             TIOCPFileLogger.logErrMessage(
               'TIOCPObject.processIOQueued.IO_TYPE_Recv, �����쳣:' + e.Message);
          end;
        end;
      finally
        //�ڴ��Ļ����Ǳ����
        TIODataMemPool.instance.giveBackIOData(lvIOData);
      end;  
    end else if lvIOData.IO_TYPE = IO_TYPE_Send then
    begin    //�����������<WSASend>���

      if lvIOData.DataBuf.len <> lvBytesTransferred then
      begin
        TIOCPFileLogger.logDebugMessage('�����ֽڲ�һ��.');
      end;

      //�Ѿ������ֽ���
      TIOCPDebugger.incSendbytesSize(lvBytesTransferred);
      TIOCPDebugger.incSendBlockCount;

      //�������ݿ�
      TIODataMemPool.instance.giveBackIOData(lvIOData);
      //����ҪͶ�ݽ�������
      
    end else if lvIOData.IO_TYPE = IO_TYPE_Close then
    begin    //�ر�����

      //�������ݿ�
      TIODataMemPool.instance.giveBackIOData(lvIOData);

      //���Թرղ��黹ClientContext
      TIOCPContextFactory.instance.tryExecuteCloseContext(lvClientContext);
    end;
  end;
end;

function TIOCPObject.Remove(pvContext:TIOCPClientContext): Boolean;
begin
  FCS.Enter;
  try
    Result := FContextOnLineList.Remove(pvContext) <> -1;
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


   //  �����л��⣬ֻ��Ͷ�ݵ�����IO������
   //    2013��11��27�� 19:25:55
   //
   //  ���û��⣨�����ڴ��������ʱ��Ͷ�ݹر���Ϣ�����ڹ����߳��н����˴���)
   //pvClientContext.Lock;
   try
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
   finally
      // pvClientContext.unLock;
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
    invokeDisconnect;
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
  if not FNormalFree then
  begin
    //������Free,��¼��־
    TIOCPFileLogger.logErrMessage('TIOCPClientContext.Destroy,���������ͷ�,�������');
  end;
  
  closeClientSocket;
  FBuffers.Free;
  FBuffers := nil;
  FCS.Free;
  FCS := nil;
  inherited Destroy;
end;

procedure TIOCPClientContext.DoConnect;
begin

end;

procedure TIOCPClientContext.DoDisconnect;
begin

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

procedure TIOCPClientContext.getPeerINfo;
var
  SockAddrIn: TSockAddrIn;
  Size: Integer;
  HostEnt: PHostEnt;
begin
  Size := SizeOf(SockAddrIn);
  getpeername(FSocket, @SockAddrIn, Size);
  FRemoteAddr := inet_ntoa(SockAddrIn.sin_addr);
  FRemotePort := ntohs(SockAddrIn.sin_port);
end;

function TIOCPClientContext.GetStateINfo: String;
begin
  Result := FStateINfo;
end;

procedure TIOCPClientContext.Initialize4Use;
begin
  FPostedCloseQuest := false;
  FWaitingGiveBack := false;
  FBuffers.clearBuffer;
end;

procedure TIOCPClientContext.invokeConnect;
begin
  FIOCPObject.Add(Self);
  TIOCPDebugger.incClientCount;  
  DoConnect;
end;

procedure TIOCPClientContext.invokeDisconnect;
begin
  if FIOCPObject.Remove(Self) then
  begin
    TIOCPDebugger.decClientCount;
    DoDisconnect;
  end else
  begin
    TIOCPFileLogger.logErrMessage('procedure TIOCPClientContext.invokeDisconnect�Ѿ��Ͽ�!');
  end;                                                                                        
end;

procedure TIOCPClientContext.Lock;
begin
  FCS.Enter;
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
  //���뵽�׽��ֶ�Ӧ�Ļ���
  FBuffers.AddBuffer(buf, len);

  self.StateINfo := '���յ�����,׼�����н���';

  ////����һ���յ������ʱ����ֻ������һ���߼��Ĵ���(dataReceived);
  ///  2013��9��26�� 08:57:20
  ///    ��лȺ��JOE�ҵ�bug��
  while True do
  begin
    lvObject := nil;
    //����ע��Ľ�����<���н���>
    lvObject := TIOCPContextFactory.instance.FDecoder.Decode(FBuffers);
    if lvObject <> nil then
    begin
      try
        try
          self.StateINfo := '����ɹ�,׼������dataReceived�����߼�����';

          TIOCPDebugger.incRecvObjectCount;

          //����ɹ�������ҵ���߼��Ĵ�����
          dataReceived(lvObject);

          self.StateINfo := 'dataReceived�߼��������!';
        except
          on E:Exception do
          begin
            TIOCPFileLogger.logErrMessage('�ػ����߼��쳣!' + e.Message);
          end;
        end;
      finally
        lvObject.Free;
      end;
    end else
    begin
      //������û�п���ʹ�õ��������ݰ�,����ѭ��
      Break;
    end;
  end;

  //������<���û�п��õ��ڴ��>����
  if FBuffers.validCount = 0 then
  begin
    FBuffers.clearBuffer;
  end else
  begin
    FBuffers.clearHaveReadBuffer;
  end;

end;

procedure TIOCPClientContext.Reset;
begin
  FUsing := false;
  FPostedCloseQuest := false;
  FWaitingGiveBack := false;
  FBuffers.clearBuffer;
end;

procedure TIOCPClientContext.unLock;
begin
  FCS.Leave;
end;

procedure TIOCPClientContext.writeObject(const pvDataObject:TObject);
var
  lvOutBuffer:TBufferLink;
begin
  lvOutBuffer := TBufferLink.Create;
  try
    self.StateINfo := 'TIOCPClientContext.writeObject,׼���������lvOutBuffer';
    TIOCPContextFactory.instance.FEncoder.Encode(pvDataObject, lvOutBuffer);
    FIOCPObject.PostWSASend(self.FSocket, lvOutBuffer);
    
    TIOCPDebugger.incSendObjectCount;
    
    self.StateINfo := 'TIOCPClientContext.writeObject,Ͷ�����';
    DoOnWriteBack;

  finally
    lvOutBuffer.Free;
  end;
end;

procedure TIOCPContextFactory.tryExecuteCloseContext(context:
    TIOCPClientContext);
begin
    //�������æ�򲻽��л���,�ȴ�æ����ڽ��л���
    if context.FIsBusying then
    begin
      context.FWaitingGiveBack := true;
    end else
    begin
      //����������ڴ����߼�,�ᵼ������
      context.Lock;
      try
        //�رջ���lvClientContext,iocp�����л����ڶ�Ӧsocket�Ľ�������
        freeContext(context);
        //����ҪͶ�ݽ�������
      finally
        context.unLock;
      end;
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
  FUsingList := TList.Create();
end;

function TIOCPContextPool.createContext(ASocket: TSocket): TIOCPClientContext;
begin
//  Result := DoInnerCreateContext;
//  Result.FSocket := ASocket;
//  Result.FUsing := true;

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
    
    FUsingList.Add(Result);
  finally
    FCS.Leave;
  end;
end;

destructor TIOCPContextPool.Destroy;
begin
  clear;
  FCS.Free;
  FreeAndNil(FList);
  FUsingList.Free;
  inherited Destroy;
end;

procedure TIOCPContextPool.clear;
begin
  FCS.Enter;
  try
    while FList.Count > 0 do
    begin
      try
        TIOCPClientContext(FList[0]).FNormalFree := true;
        TIOCPClientContext(FList[0]).Free;
      except    //���ηǷ�����
        on E:Exception do
        begin
          TIOCPFileLogger.logDebugMessage('TIOCPContextPool.clear,���Ĵ������BUG(�Ƿ�����һ��TIOCPClientContext��������ֶ��ͷ�),�ͷ�һ��TIOCPClientContext����ʱ����,' + e.Message);
        end;
      end;
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
  //  context.Free;
  //  context := nil;
  FCS.Enter;
  try
    try
      if not context.FUsing then exit;  //�Ѿ�����

      //�ر�
      context.CloseClientSocket;
      context.StateINfo := '�ر�����';


      //����<��λ>
      context.Reset;

      FList.Add(context);
      context.StateINfo := '�Ѿ��ع鵽��!';

      FUsingList.Remove(context);

      Dec(FBusyCount);
    except
      on E:Exception do
      begin
        TIOCPFileLogger.logErrMessage(
          '����contextʱִ��TIOCPContextPool.freeContext�������쳣,��������Ѿ�����(���ж�����ͷ�)!' + e.Message);

        try
           if FUsingList.Remove(context) > 0 then Dec(FBusyCount);
           FList.Remove(context);            
           TIOCPClientContext(FList[0]).FNormalFree := true;
           TIOCPClientContext(FList[0]).Free;
        except
        end;  
      end;
    end;
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

procedure TIOCPContextPool.getUsingList(pvList: TList);
var
  i:Integer;
begin
  FCS.Enter;
  try
    for I := 0 to FUsingList.Count - 1 do
    begin
      pvList.Add(FUsingList[i]);
    end;                            
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
