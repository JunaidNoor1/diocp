unit uMemPool;

interface

uses
  JwaWinsock2, Windows, SyncObjs, uIOCPProtocol;


type
  TIODataMemPool = class(TObject)
  private
    FCs: TCriticalSection;

    //��һ�����õ��ڴ��
    FHead: POVERLAPPEDEx;

    //���һ�����õ��ڴ濨
    FTail: POVERLAPPEDEx;

    //���õ��ڴ����
    FUseableCount:Integer;

    //����ʹ�õĸ���
    FUsingCount:Integer;

    /// <summary>
    ///   ��һ���ڴ����ӵ�β��
    /// </summary>
    /// <param name="pvIOData"> (POVERLAPPEDEx) </param>
    procedure AddData2Pool(pvIOData:POVERLAPPEDEx);

    /// <summary>
    ///   �õ�һ�����ʹ�õ��ڴ�
    /// </summary>
    /// <returns> POVERLAPPEDEx
    /// </returns>
    function getUsableData: POVERLAPPEDEx;

    /// <summary>
    ///   ����һ���ڴ�ռ�
    /// </summary>
    /// <returns> POVERLAPPEDEx
    /// </returns>
    function InnerCreateIOData: POVERLAPPEDEx;

    procedure clearMemBlock(pvIOData:POVERLAPPEDEx);

    //�ͷ����е��ڴ��
    procedure FreeAllBlock;
  public
    class function instance: TIODataMemPool;
    constructor Create;
    destructor Destroy; override;

    //��һ���ڴ�
    function borrowIOData: POVERLAPPEDEx;

    //����һ���ڴ�
    procedure giveBackIOData(const pvIOData: POVERLAPPEDEx);

    function getCount: Cardinal;
    function getUseableCount: Cardinal;
    function getUsingCount:Cardinal;

  end;

implementation

uses
  uIOCPFileLogger;

var
  __IODATA_instance:TIODataMemPool;

constructor TIODataMemPool.Create;
begin
  inherited Create;
  FCs := TCriticalSection.Create();
  FUseableCount := 0;
  FUsingCount := 0;
end;

destructor TIODataMemPool.Destroy;
begin
  FreeAllBlock;
  FCs.Free;
  inherited Destroy;
end;

{ TIODataMemPool }

procedure TIODataMemPool.AddData2Pool(pvIOData:POVERLAPPEDEx);
begin
  if FHead = nil then
  begin
    FHead := pvIOData;
    FHead.next := nil;
    FHead.pre := nil;
    FTail := pvIOData;
  end else
  begin
    FTail.next := pvIOData;
    pvIOData.pre := FTail;
    FTail := pvIOData;
  end;
  Inc(FUseableCount);
end;

function TIODataMemPool.InnerCreateIOData: POVERLAPPEDEx;
begin
  Result := POVERLAPPEDEx(GlobalAlloc(GPTR, sizeof(OVERLAPPEDEx)));

  GetMem(Result.DataBuf.buf, MAX_OVERLAPPEDEx_BUFFER_SIZE);

  Result.DataBuf.len := MAX_OVERLAPPEDEx_BUFFER_SIZE;

  //����һ���ڴ�
  clearMemBlock(Result);
end;

function TIODataMemPool.borrowIOData: POVERLAPPEDEx;
begin
  FCs.Enter;
  try
    Result := getUsableData;
    if Result = nil then
    begin
      //����һ���ڴ��
      Result := InnerCreateIOData;

      //ֱ�ӽ���<����ʹ�ü�����>
      Inc(FUsingCount);
    end;
  finally
    FCs.Leave;
  end;
end;

procedure TIODataMemPool.clearMemBlock(pvIOData: POVERLAPPEDEx);
begin
  //����һ���ڴ�
  pvIOData.IO_TYPE := 0;

  pvIOData.WorkBytes := 0;
  pvIOData.WorkFlag := 0;

  //ZeroMemory(@pvIOData.Overlapped, sizeof(OVERLAPPED));

  //��ԭ��С<����ʱ�Ĵ�С>
  pvIOData.DataBuf.len := MAX_OVERLAPPEDEx_BUFFER_SIZE;

  //ZeroMemory(pvIOData.DataBuf.buf, pvIOData.DataBuf.len);
end;

procedure TIODataMemPool.FreeAllBlock;
var
  lvNext, lvData:POVERLAPPEDEx;
begin
  lvData := FHead;
  while lvData <> nil do
  begin
    //��¼��һ��
    lvNext := lvData.next;

    //�ͷŵ�ǰData
    FreeMem(lvData.DataBuf.buf, lvData.DataBuf.len);
    GlobalFree(Cardinal(lvData));

    //׼���ͷ���һ��
    lvData := lvNext;
  end;

  FHead := nil;
  FTail := nil;

  FUsingCount := 0;
  FUseableCount := 0; 

end;

function TIODataMemPool.getCount: Cardinal;
begin
  Result := FUseableCount + FUsingCount;
end;

procedure TIODataMemPool.giveBackIOData(const pvIOData:
    POVERLAPPEDEx);
begin
  FCs.Enter;
  try
    if (pvIOData.pre <> nil) or (pvIOData.next <> nil) or (pvIOData = FHead) then
    begin
      TIOCPFileLogger.logErrMessage('�����ڴ���ǳ������쳣,���ڴ���Ѿ�����!');

    end else
    begin
      //�����ڴ��
      clearMemBlock(pvIOData);

      //���뵽����ʹ�õ��ڴ�ռ�
      AddData2Pool(pvIOData);

      //����ʹ�ü�����
      Dec(FUsingCount);
    end;
  finally
    FCs.Leave;
  end;
end;

function TIODataMemPool.getUsableData: POVERLAPPEDEx;
var
  lvPre:POVERLAPPEDEx;
begin
  if FTail = nil then
  begin
    Result := nil;
  end else  
  begin   
    Result := FTail;

    lvPre := FTail.pre;
    if lvPre <> nil then
    begin
      lvPre.next := nil;
      FTail := lvPre;
    end else  //FTail�ǵ�һ��Ҳ�����һ��,ֻ��һ��
    begin
      FHead := nil;
      FTail := nil;
    end;  

    Result.next := nil;
    Result.pre := nil;

    Dec(FUseableCount);
    Inc(FUsingCount);
  end;
end;

function TIODataMemPool.getUseableCount: Cardinal;
begin
  Result := FUseableCount;
end;

function TIODataMemPool.getUsingCount: Cardinal;
begin
  Result := FUsingCount;
end;

class function TIODataMemPool.instance: TIODataMemPool;
begin
  Result := __IODATA_instance;
end;


initialization
  __IODATA_instance := TIODataMemPool.Create;

finalization
  if __IODATA_instance <> nil then
  begin
    __IODATA_instance.Free;
    __IODATA_instance := nil;
  end;

end.
