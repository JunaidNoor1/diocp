unit uMyObjectPool;
///
///
/// 2014��3��10�� 10:47:26
///    �Ƴ��ȴ�, ���ö���ʱ���ȴ�

interface

uses
  SyncObjs, Classes, Windows, SysUtils;

type
  TObjectBlock = record
  private
    FObject:TObject;
    FUsing:Boolean;
    FBorrowTime:Cardinal;       //���ʱ��
    FRelaseTime:Cardinal;       //�黹ʱ��
    FMarkWillFreeFlag:Boolean;  //�黹��������Ϊtrue,�ڹ黹ʱ�ͷ������
    FThreadID:Cardinal;         //�߳�ID   
  end;

  PObjectBlock = ^TObjectBlock;

  TMyObjectPool = class(TObject)
  private
    FObjectClass:TClass;

    FCurrentThreadID:Cardinal;

    FLocker: TCriticalSection;

    FBusyCount: Integer;

    //ȫ���黹�ź�
    FReleaseSingle: THandle;

    FMaxNum: Integer;

    /// <summary>
    ///   ���ӳ��еĶ����б�
    /// </summary>
    FObjectList: TList;

    FName: String;


    /// <summary>
    ///  ���ݵ�ǰ״̬���������ź�
    /// </summary>
    procedure makeSingle;


    function GetCount: Integer;

    /// <summary>
    ///  ����
    /// </summary>
    procedure lock;

    procedure SetMaxNum(const Value: Integer);

    /// <summary>
    ///  ����
    /// </summary>
    procedure unLock;
    
  protected
    /// <summary>
    ///   ������еĶ���
    /// </summary>
    procedure clear;

    /// <summary>
    ///  ����һ������
    /// </summary>
    function createObject: TObject; virtual;
  public
    constructor Create(pvObjectClass: TClass = nil);
    destructor Destroy; override;

    /// <summary>
    ///   ���ö����
    /// </summary>
    procedure resetPool;

    /// <summary>
    ///  ����һ������
    /// </summary>
    function borrowObject: TObject;


    /// <summary>
    ///   ��־������Ҫ�ͷ�
    /// </summary>
    procedure makeObjectWillFree(pvObject:TObject);


    /// <summary>
    ///   �Ƿ���еĶ���
    /// </summary>
    procedure clearFreeObjects;


    /// <summary>
    ///  ����Ѿ���ʱ�������Ķ���
    /// </summary>
    function killDeadLockObjects(pvTimeOut: Integer = 30 * 1000): Integer;


    /// <summary>
    ///   �黹һ������
    /// </summary>
    procedure releaseObject(pvObject:TObject);

    /// <summary>
    ///  ��ȡ����ʹ�õĸ���
    /// </summary>
    function getBusyCount:Integer;



    //�ȴ�ȫ������
    function waitForReleaseSingle: Boolean;

    /// <summary>
    ///  ��ǰ�ܵĸ���
    /// </summary>
    property Count: Integer read GetCount;

    /// <summary>
    ///  ���������
    /// </summary>
    property MaxNum: Integer read FMaxNum write SetMaxNum;



    /// <summary>
    ///  ���������
    /// </summary>
    property Name: String read FName write FName;

  end;

implementation

uses
  FileLogger;

procedure TMyObjectPool.clear;
var
  lvObj:PObjectBlock;
  i:Integer;
begin
  lock;
  try
    for i := 0 to FObjectList.Count -1 do
    begin
      lvObj := PObjectBlock(FObjectList[i]);
      lvObj.FObject.Free;
      FreeMem(lvObj, SizeOf(TObjectBlock));
    end;

    FObjectList.Clear;
  finally
    unLock;
  end;
end;

procedure TMyObjectPool.clearFreeObjects;
var
  lvObj:PObjectBlock;
  i:Integer;
begin
  lock;
  try
    for i := FObjectList.Count -1  downto 0 do
    begin
      lvObj := PObjectBlock(FObjectList[i]);
      if not lvObj.FUsing then
      begin
        lvObj.FObject.Free;
        FreeMem(lvObj, SizeOf(TObjectBlock));
        FObjectList.Delete(i);
      end;
    end;

    //�����ź�
    makeSingle;
  finally
    unLock;
  end;
end;

constructor TMyObjectPool.Create(pvObjectClass: TClass = nil);
begin
  inherited Create;
  FObjectClass := pvObjectClass;
  
  FLocker := TCriticalSection.Create();

  FObjectList := TList.Create;

  //Ĭ�Ͽ���ʹ��5��
  FMaxNum := 5;

  //�����źŵ�,�ֶ�����
  FReleaseSingle := CreateEvent(nil, True, True, nil);

  makeSingle;
end;

function TMyObjectPool.createObject: TObject;
begin
  Result := nil;
  if FObjectClass <> nil then
  begin
    Result := FObjectClass.Create;
  end;      
end;

destructor TMyObjectPool.Destroy;
begin
  waitForReleaseSingle;  
  clear;
  FLocker.Free;
  FObjectList.Free;
  CloseHandle(FReleaseSingle);
  inherited Destroy;
end;

function TMyObjectPool.getBusyCount: Integer;
begin
  Result := FBusyCount;
end;

{ TMyObjectPool }

procedure TMyObjectPool.releaseObject(pvObject:TObject);
var
  i:Integer;
  lvObj:PObjectBlock;
begin
  lock;
  try
    for i := 0 to FObjectList.Count - 1 do
    begin
      lvObj := PObjectBlock(FObjectList[i]);
      if lvObj.FObject = pvObject then
      begin
        if lvObj.FMarkWillFreeFlag then
        begin          //��Ҫ�ͷŶ���
          try
            //�ͷŸö���
            pvObject.Free;
          except
            on E:Exception do
            begin
              TFileLogger.instance.logMessage(FName + '�ͷųض���������쳣:' + e.Message, 'POOL_ERROR_');
            end;
          end;
          lvObj.FObject := nil;
          FreeMem(lvObj, SizeOf(TObjectBlock));
          FObjectList.Delete(i);
        end else
        begin
          lvObj.FRelaseTime := GetTickCount;
          lvObj.FUsing := false;
        end;

        Dec(FBusyCount);
        
        Break;
      end;
    end;
  finally
    unLock;
  end;
  makeSingle;
end;

procedure TMyObjectPool.resetPool;
begin
  waitForReleaseSingle;

  clear;
end;

procedure TMyObjectPool.unLock;
begin
  if FCurrentThreadID <> GetCurrentThreadId then
  begin
    raise Exception.Create('�д�����');
  end;
  FLocker.Leave;
end;

function TMyObjectPool.borrowObject: TObject;
var
  i:Integer;
  lvObj:PObjectBlock;
  lvObject:TObject;
  lvType:Integer;
  lvThreadID:Cardinal;
begin
  lock;
  try
    lvObject := nil;
    
    //�Ƿ��п���ֱ��ʹ�õ�
    if (FObjectList.Count - FBusyCount) > 0 then
    begin
      for i := 0 to FObjectList.Count - 1 do
      begin
        lvObj := PObjectBlock(FObjectList[i]);
        if (not lvObj.FUsing)
          and (not lvObj.FMarkWillFreeFlag)
          then
        begin    // ���У���־ʹ��
          lvObject := lvObj.FObject;
          break;
        end;
      end;

      if (lvObject = nil) or (lvObj.FUsing) then
      begin
         raise Exception.CreateFmt('��������,���ӳ�(%s-%s)�����˲�Ӧ�ó��ֵ�����!', [self.ClassName, self.FName]);
      end;

      lvType := 0;
    end;

    if lvObject = nil then
    begin         //���Դ�������

      if GetCount >= FMaxNum then
      begin
        raise exception.CreateFmt('���������[%s]����ķ�Χ[%d],�����ٴ����µĶ���', [self.ClassName, FMaxNum]);
      end;

      lvObject := createObject;

      if lvObject = nil then raise exception.CreateFmt('���ܵõ�����,�����[%s]δ�̳д���createObject����', [self.ClassName]);

      GetMem(lvObj, SizeOf(TObjectBlock));
      try
        ZeroMemory(lvObj, SizeOf(TObjectBlock));
        lvObj.FObject := lvObject;


        FObjectList.Add(lvObj);
      except
        lvObject.Free;
        FreeMem(lvObj, SizeOf(TObjectBlock));
        raise;
      end;

      lvType := 1;
    end;

    if lvObject = nil then
    begin
      raise Exception.CreateFmt('���������ж϶���,���ӳ�(%s-%s)�����˲�Ӧ�ó��ֵ�����!', [self.ClassName, self.FName]);
    end;

    if lvObj.FUsing then
    begin
      raise Exception.CreateFmt('���������ж�,���ӳ�(%s-%s)�����˲�Ӧ�ó��ֵ�����!', [self.ClassName, self.FName]);
    end;


    //����ʹ��
    lvObj.FUsing := true;
    lvObj.FThreadID := GetCurrentThreadId;
    lvObj.FMarkWillFreeFlag := False;
    lvObj.FBorrowTime := GetTickCount;
    lvObj.FRelaseTime := 0;
    Inc(FBusyCount);

    Result := lvObject;
  finally
    unLock;
  end;

end;

procedure TMyObjectPool.makeObjectWillFree(pvObject: TObject);
var
  i:Integer;
  lvObj:PObjectBlock;
begin
  lock;
  try
    for i := 0 to FObjectList.Count - 1 do
    begin
      lvObj := PObjectBlock(FObjectList[i]);
      if (lvObj.FObject = pvObject) then
      begin
        lvObj.FMarkWillFreeFlag := true;
        Break;
      end;    
    end;
  finally
    unLock;
  end;
end;

procedure TMyObjectPool.makeSingle;
begin
  if FBusyCount > 0 then
  begin
    //û���ź�
    ResetEvent(FReleaseSingle);
  end else
  begin
    //ȫ���黹���ź�
    SetEvent(FReleaseSingle)
  end;
end;

function TMyObjectPool.GetCount: Integer;
begin
  Result := FObjectList.Count;
end;

procedure TMyObjectPool.lock;
begin
  FLocker.Enter;
  FCurrentThreadID := GetCurrentThreadId;
end;

function TMyObjectPool.waitForReleaseSingle: Boolean;
var
  lvRet:DWORD;
begin
  Result := false;
  lvRet := WaitForSingleObject(FReleaseSingle, INFINITE);
  if lvRet = WAIT_OBJECT_0 then
  begin
    Result := true;
  end;
end;

function TMyObjectPool.killDeadLockObjects(pvTimeOut: Integer = 30 * 1000):
    Integer;
var
  i:Integer;
  lvCounter:Cardinal;
  lvObj:PObjectBlock;
begin
  Result := 0;
  lock;
  try
    lvCounter := GetTickCount;
    for i := FObjectList.Count - 1 downto 0 do
    begin
      lvObj := PObjectBlock(FObjectList[i]);
      if ((lvCounter - lvObj.FBorrowTime) >= pvTimeOut) or (lvObj.FMarkWillFreeFlag) then
      begin      //��ʱ
        if lvObj.FUsing then
        begin
          Dec(FBusyCount);
        end;

        try
          lvObj.FObject.Free;
        except
        end;
        FreeMem(lvObj, SizeOf(TObjectBlock));
        FObjectList.Delete(i); 
        Inc(Result);  
      end;
    end;
    makeSingle;
  finally
    unLock;
  end;
end;

procedure TMyObjectPool.SetMaxNum(const Value: Integer);
begin
  FMaxNum := Value;
  makeSingle;
end;

end.
