unit uObjectPool;

interface

uses
  Classes, SyncObjs, Windows, SysUtils;


type
  TObjectPool = class(TObject)
  private
    FObjectClass:TClass;
    
    //ȫ���黹���źŵ�
    FGiveBackSingle: THandle;
    
    FErrCode:Integer;

    FErrMsg:string;
    
    //
    FWaitTimeOut:Integer;
    
    //ʹ��ʱ�ȴ��ź�<���û���ź�ʱû���ź�>
    FWaitSingle:THandle;

    //
    FCS: TCriticalSection;

    //��ǰ����
    FCount:Integer;

    //�������
    FMaxCount: Integer;

    //�Ѿ�ʹ�õĸ���
    FUsingCount:Integer;

    FUsableList: TList;
    procedure lock();
    procedure unLock();
    procedure checkSingle;
    procedure SetMaxCount(const Value: Integer);
    procedure clearUsableList;
  protected
    function createObject:TObject;virtual;
  public
    //ֹͣʱʹ��
    procedure clearObjects;

    constructor Create(pvObjectClass: TClass = nil);

    destructor Destroy; override;
    
    function beginUseObject: TObject;

    procedure endUseObject(const pvObj:TObject);
    
    property Count: Integer read FCount;

    property MaxCount: Integer read FMaxCount write SetMaxCount;

    //�ȴ�ȫ������
    function waitForGiveBack: Boolean;

    property ErrMsg: string read FErrMsg;
    
    //����ʹ�õĸ���
    property UsingCount: Integer read FUsingCount;

    //�ȴ���ʱ
    property WaitTimeOut: Integer read FWaitTimeOut write FWaitTimeOut;
  end;

implementation

procedure TObjectPool.checkSingle;
begin
  if (FCount < FMaxCount)      //�����Դ���
     or (FUsingCount < FCount)  //���п�ʹ�õ�
     then
  begin
    //�������ź�
    SetEvent(FWaitSingle);
  end else
  begin
    //û���ź�
    ResetEvent(FWaitSingle);
  end;

  if FUsingCount > 0 then
  begin
    //û���ź�
    ResetEvent(FGiveBackSingle);
  end else
  begin
    //ȫ���黹���ź�
    SetEvent(FGiveBackSingle)
  end;
end;

constructor TObjectPool.Create(pvObjectClass: TClass = nil);
begin
  inherited Create;
  FObjectClass := pvObjectClass;

  //30�볬ʱ
  FWaitTimeOut := 1000 * 30;

  FWaitSingle := CreateEvent(nil, True, True, nil);

  //�����źŵ�,�ֶ�����
  FGiveBackSingle := CreateEvent(nil, True, True, nil);
  
  FMaxCount := 2;
  FCount := 0;
  FUsingCount := 0;
  FUsableList := TList.Create;
  FCS := TCriticalSection.Create();
  checkSingle;
end;

function TObjectPool.createObject: TObject;
begin
  Result := nil;
  if FObjectClass <> nil then
  begin
    Result := FObjectClass.Create;
  end;          
end;

destructor TObjectPool.Destroy;
begin
  //�ȴ�ȫ���黹
  waitForGiveBack;

  //�ͷ�
  clearUsableList;
  
  FUsableList.Free;
  FCS.Free;
  CloseHandle(FWaitSingle);
  CloseHandle(FGiveBackSingle);
  
  inherited Destroy;
end;

function TObjectPool.beginUseObject: TObject;
var
  i:Integer;
  lvRet:DWORD;
begin
  //�ȴ���ʱ
  lvRet := WaitForSingleObject(FWaitSingle, FWaitTimeOut);
  if lvRet = WAIT_TIMEOUT then
  begin
    Result := nil;
    FErrMsg := '�ȴ���ʱ';
  end else if lvRet = WAIT_OBJECT_0 then
  begin
    lock;
    try
      i := FUsableList.Count;
      if i > 0 then
      begin
        Result := TObject(FUsableList[i-1]);
        FUsableList.Delete(i-1);
      end else
      begin
        Result := createObject;
        if Result <> nil then
        begin
          Inc(FCount);
        end;
      end;  
      if Result <> nil then Inc(FUsingCount);

      checkSingle;
    finally
      unLock;
    end;
  end else
  begin
    Result := nil;
    FErrMsg := '�ȴ��쳣[' + intToStr(lvRet) + ']';
  end;
end;

procedure TObjectPool.clearObjects;
begin
  waitForGiveBack;
  clearUsableList;
end;

procedure TObjectPool.clearUsableList;
var
  i:Integer;
begin
  lock;
  try
    while FUsableList.Count > 0 do
    begin
      i:= FUsableList.Count - 1;
      TObject(FUsableList[i]).Free;
      FUsableList.Delete(i);
      Dec(FCount);
    end;

    checkSingle;
  finally
    unLock;
  end;
end;

procedure TObjectPool.endUseObject(const pvObj:TObject);
var
  i:Integer;
begin
  lock;
  try
    FUsableList.Add(pvObj);
    Dec(FUsingCount);
    checkSingle;
  finally
    unLock;
  end;
end;

procedure TObjectPool.lock;
begin
  FCS.Enter;
end;

procedure TObjectPool.SetMaxCount(const Value: Integer);
begin
  FMaxCount := Value;
  checkSingle;
end;

procedure TObjectPool.unLock;
begin
  FCS.Leave;
end;

function TObjectPool.waitForGiveBack: Boolean;
var
  lvRet:DWORD;
begin
  Result := false;
  lvRet := WaitForSingleObject(FGiveBackSingle, INFINITE);
  if lvRet = WAIT_OBJECT_0 then
  begin
    Result := true;
  end;
end;

end.
