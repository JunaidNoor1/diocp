unit uMyObjectPool;

interface

uses
  SyncObjs, Classes, Windows, SysUtils;

type
  TObjectBlock = record
  private
    FObject:TObject;
    FUsing:Boolean;
    FBorrowTime:Cardinal;   //���ʱ��
    FRelaseTime:Cardinal;   //�黹ʱ��
  end;

  PObjectBlock = ^TObjectBlock;

  TMyObjectPool = class(TObject)
  private
    FLocker: TCriticalSection;

    //ȫ���黹�ź�
    FReleaseSingle: THandle;

    //�п��õĶ����źŵ�
    FUsableSingle: THandle;

    FMaxNum: Integer;
    FObjectList: TList;

    FBusyList:TList;
    FName: String;
    FTimeOut: Integer;
    FUsableList:TList;

    procedure makeSingle;
    function GetCount: Integer;
    procedure lock;
    procedure unLock;
  protected
    function createObject: TObject; virtual;
    procedure clear;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///  ����һ������
    /// </summary>
    function borrowObject: TObject;


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
    ///   �ȴ�ȫ���黹�źŵ�
    /// </summary>
    procedure checkWaitForUsableSingle;

    /// <summary>
    ///  ��ǰ�ܵĸ���
    /// </summary>
    property Count: Integer read GetCount;

    /// <summary>
    ///  ���������
    /// </summary>
    property MaxNum: Integer read FMaxNum write FMaxNum;



    /// <summary>
    ///  ���������
    /// </summary>
    property Name: String read FName write FName;

    /// <summary>
    ///   �ȴ���ʱ�źŵ�
    ///   ��λ����
    /// </summary>
    property TimeOut: Integer read FTimeOut write FTimeOut;
  end;

implementation

procedure TMyObjectPool.clear;
var
  lvObj:PObjectBlock;
begin
  lock;
  try
    while FUsableList.Count > 0 do
    begin
      lvObj := PObjectBlock(FUsableList[FObjectList.Count-1]);
      lvObj.FObject.Free;
      FreeMem(lvObj, SizeOf(TObjectBlock));
      FUsableList.Delete(FObjectList.Count-1);
    end; 
  finally
    unLock;
  end;
end;

constructor TMyObjectPool.Create;
begin
  inherited Create;
  FLocker := TCriticalSection.Create();
  FBusyList := TList.Create;
  FUsableList := TList.Create;

  //Ĭ�Ͽ���ʹ��5��
  FMaxNum := 5;

  //�ȴ���ʱ�źŵ� 5 ��
  FTimeOut := 5 * 1000;

  //
  FUsableSingle := CreateEvent(nil, True, True, nil);

  //�����źŵ�,�ֶ�����
  FReleaseSingle := CreateEvent(nil, True, True, nil);

  makeSingle;  
end;

function TMyObjectPool.createObject: TObject;
begin
  Result := nil;  
end;

destructor TMyObjectPool.Destroy;
begin
  waitForReleaseSingle;  
  clear;
  FLocker.Free;
  FBusyList.Free;
  FUsableList.Free;
  inherited Destroy;
end;

function TMyObjectPool.getBusyCount: Integer;
begin
  Result := FBusyList.Count;
end;

{ TMyObjectPool }

procedure TMyObjectPool.releaseObject(pvObject:TObject);
var
  i:Integer;
  lvObj:PObjectBlock;
begin
  lock;
  try
    for i := 0 to FBusyList.Count - 1 do
    begin
      lvObj := PObjectBlock(FBusyList[i]);
      if lvObj.FObject = pvObject then
      begin
        FUsableList.Add(lvObj);
        lvObj.FRelaseTime := GetTickCount;
        FBusyList.Delete(i);
        Break;
      end;
    end;             

    makeSingle;
  finally
    unLock;
  end;
end;

procedure TMyObjectPool.unLock;
begin
  FLocker.Leave;
end;

function TMyObjectPool.borrowObject: TObject;
var
  i:Integer;
  lvObj:PObjectBlock;
  lvObject:TObject;
begin
  Result := nil;
  
  //�Ƿ��п��õĶ���
  checkWaitForUsableSingle;
  
  lock;
  try
    lvObject := nil;
    if FUsableList.Count > 0 then
    begin
      lvObj := PObjectBlock(FUsableList[FUsableList.Count-1]);
      FUsableList.Delete(FUsableList.Count-1);
      FBusyList.Add(lvObj);
      lvObj.FBorrowTime := getTickCount;
      lvObj.FRelaseTime := 0;
      lvObject := lvObj.FObject;
    end else
    begin
      if GetCount >= FMaxNum then raise exception.CreateFmt('���������[%s]����ķ�Χ[%d]', [self.ClassName, FMaxNum]);
      lvObject := createObject;
      if lvObject = nil then raise exception.CreateFmt('���ܵõ�����,�����[%s]δ�̳д���createObject����', [self.ClassName]);

      GetMem(lvObj, SizeOf(TObjectBlock));
      try
        ZeroMemory(lvObj, SizeOf(TObjectBlock));
        
        lvObj.FObject := lvObject;
        lvObj.FBorrowTime := GetTickCount;
        lvObj.FRelaseTime := 0;
        FBusyList.Add(lvObj);
      except
        lvObject.Free;
        FreeMem(lvObj, SizeOf(TObjectBlock));
        raise;
      end;
    end;

    //�����źŵ�
    makeSingle;

    Result := lvObject;
  finally
    unLock;
  end;       
end;

procedure TMyObjectPool.makeSingle;
begin
  if (GetCount < FMaxNum)      //�����Դ���
     or (FUsableList.Count > 0)  //���п�ʹ�õ�
     then
  begin
    //�������ź�
    SetEvent(FUsableSingle);
  end else
  begin
    //û���ź�
    ResetEvent(FUsableSingle);
  end;

  if FUsableList.Count > 0 then
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
  Result := FUsableList.Count + FBusyList.Count;
end;

procedure TMyObjectPool.lock;
begin
  FLocker.Enter;
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

procedure TMyObjectPool.checkWaitForUsableSingle;
var
  lvRet:DWORD;
begin
  lvRet := WaitForSingleObject(FReleaseSingle, FTimeOut);
  if lvRet <> WAIT_OBJECT_0 then
  begin
    raise Exception.CreateFmt('�����[%s]�ȴ���ʹ�ö���ʱ,ʹ��״̬[%d/%d]!',
      [FName, getBusyCount, FMaxNum]);
  end;                                                                 
end;

end.
