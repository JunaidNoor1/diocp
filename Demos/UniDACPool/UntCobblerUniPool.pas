(*******************************************************************************
  ��дunidac���ӳ�
  ������unidac�������


����:Cobbler
     2011-1-23
     �����Ż� �봫����һ�� ��лл��
     ����ID��eloveme
     ���䣺eloveme@tom.com
     QQ;250134558
********************************************************************************)

unit UntCobblerUniPool;

interface

uses
  classes, SysUtils, DateUtils, UntThreadTimer,
  Uni, DBAccess,
  SQLServerUniProvider, UniProvider, ActiveX;
//unidac����ĵ�Ԫ
//UniProvider, SQLServerUniProvider
//ODBCUniProvider,AccessUniProvider;
//���ݿ����ü�¼
//����;��½�û�;����;������;���ݿ�;�˿�;


type
  TUniCobbler = class
  private
    FFlag: boolean; //��ǰ�����Ƿ�ʹ��
    FConnObj: TUniConnection; //���ݿ����Ӷ���
    FConnStr: String;//�����ַ���
    FAStart: TDateTime;//���һ�λʱ��
  public
    constructor Create(tmpConnStr:string);overload;
    destructor Destroy;override;

    procedure checkConnect;

    property Flag:boolean  read FFlag write FFlag;
    property ConnObj: TUniConnection read FConnObj;
    property ConnStr: String read FConnStr write FConnStr;
    property AStart: TDateTime read FAStart write FAStart;
  end;

type
  TUniCobblerPool = class
    procedure OnMyTimer(Sender: TObject);//����ѯ��
  private
    FPOOLNUMBER:Integer; //�ش�С
    FMPollingInterval:Integer;//��ѯʱ�� �� ���� Ϊ��λ
    FList:TThreadList;//������������TADOCobbler
    FTime :TThreadedTimer;//��Ҫ����ѯ
    FSXunHuan:Integer;//��������� ��ѯһ�� Flist

    function GetListCount:Integer; //���س��� ������
    procedure SetPoolCount(Value:Integer);//��̬���óش�С
    function GetItems(Index: integer):TUniCobbler; //����ָ�� TUniCobbler
    procedure SetFSXunHuan(Value:Integer);

    function CreateUniCobbler(const tmpConnStr:string):TUniCobbler;
  public
    constructor Create(const MaxNumBer:Integer;FreeMinutes :Integer= 60;TimerTime:Integer = 5000);overload;
    destructor Destroy;override;
    function GetUniCon(const tmpConnStr:string):TUniCobbler;//�ӳ���ȡ�����õ�����
    procedure FreeBackPool(Instance: TUniCobbler);//�ͷŻع鵽����

    procedure FreeUniCon; //���ճ������δ�õ�����
    property Count:Integer read GetListCount;//�������óش�С
    property  PoolCount:Integer read FPOOLNUMBER write SetPoolCount; //����������
    property  Items[Index: integer]:TUniCobbler read GetItems;
    property Interval:Integer  read FSXunHuan write SetFSXunHuan;
  end;

implementation

uses
  ComObj;

{ TUniCobbler }
procedure TUniCobbler.checkConnect;
begin
  if not FConnObj.Connected then
  begin
    FConnObj.LoginPrompt := false;
    CoInitialize(nil);
    FConnObj.Connect;
  end;
end;

constructor TUniCobbler.Create(tmpConnStr: string);
begin
  FConnStr := tmpConnStr;
  FFlag := False;
  FAStart := Now;
  FConnObj := TUniConnection.Create(nil);
  FConnObj.ConnectString := tmpConnStr;
  FConnObj.LoginPrompt := False;
end;

destructor TUniCobbler.Destroy;
begin
  FFlag := False;
  FConnStr := '';
  FAStart := 0;
  if Assigned(FConnObj) then FreeAndNil(FConnObj);
  inherited;
end;

{ TUniCobblerPool }
constructor TUniCobblerPool.Create(const MaxNumBer:Integer;FreeMinutes :Integer= 60;TimerTime:Integer = 5000);
begin
  FPOOLNUMBER := MaxNumBer; //���óش�С
  FSXunHuan := TimerTime;//���ö���ʱ�� �� ȥ��ѯһ�� Flist
  FMPollingInterval := FreeMinutes;// ���ӳ��� N ���� ����û�õ� �Զ��������ӳ�
  FList := TThreadList.Create;
  FTime := TThreadedTimer.Create(nil);
  FTime.Enabled := False;
  FTime.Interval := TimerTime;//Ĭ��5����һ��
  FTime.OnTimer := OnMyTimer;
  FTime.Enabled := True;
end;

function TUniCobblerPool.CreateUniCobbler(
  const tmpConnStr: string): TUniCobbler;
begin
  Result := nil;
  Result := TUniCobbler.Create(tmpConnStr);
  if Assigned(Result) then
  begin
    Result.Flag := True;
    Result.AStart := Now;
  end;
end;

destructor TUniCobblerPool.Destroy;
var
  i:integer;
  LockedList: TList;
begin
  if Assigned(FTime) then FreeAndNil(FTime);
  if Assigned(FList) then
  begin
    LockedList := FList.LockList;
    try
      for i := LockedList.Count - 1 downto 0  do
        TUniCobbler(LockedList.Items[i]).Free;
    finally
      FList.UnlockList;
      FreeAndNil(FList);
    end;
  end;
end;

function TUniCobblerPool.GetItems(Index: integer): TUniCobbler;
var
  LockedList: TList;
begin
  Result := nil;
  LockedList := FList.LockList;
  try
    if (Index < 0) or (Index > LockedList.Count) then Exit;
    Result := TUniCobbler(LockedList.Items[Index]);
  finally
    FList.UnlockList;
  end;
end;

function TUniCobblerPool.GetListCount: Integer;
var
  LockedList: TList;
begin
  Result := 0;
  LockedList := FList.LockList;
  try
    Result := LockedList.Count;
  finally
    FList.UnlockList;
  end;
end;
//�����ַ������Ӳ��� ȡ����ǰ���ӳؿ�����
function TUniCobblerPool.GetUniCon(const tmpConnStr:string):TUniCobbler;
var
  i:Integer;
  LockedList: TList;
begin
  Result := nil;
  LockedList := FList.LockList;
  try
    for I := 0 to LockedList.Count - 1 do
    begin
      if not TUniCobbler(LockedList.Items[i]).Flag then //����
      begin
        if SameStr(LowerCase(tmpConnStr),LowerCase(TUniCobbler(LockedList.Items[i]).ConnStr)) then  //�ҵ�
        begin
          Result:= TUniCobbler(LockedList.Items[i]);
          Result.Flag := True; //����Ѿ���������
          Result.AStart := Now;//��¼ʱ��
          Break;//�˳�ѭ��
        end;
      end;
    end; // end for
    //�������δ�ҵ� �򴴽�
    if not Assigned(Result) then
    begin
      Result := CreateUniCobbler(tmpConnStr);
      if Assigned(Result) then
      begin
        //��δ������ӵ�����
        if LockedList.Count < FPOOLNUMBER then LockedList.Add(Result);
      end;
    end;
  finally
    FList.UnlockList;
  end;
end;
//�ͷ����ӳض���
procedure TUniCobblerPool.FreeBackPool(Instance: TUniCobbler);
var
  I: Integer;
  LockedList: TList;
  isPool:Boolean;
begin
  if not Assigned(Instance) then Exit;
  isPool:= False;
  LockedList := FList.LockList;
  try
    for i := 0 to LockedList.Count - 1 do
    begin
      if TUniCobbler(LockedList.Items[i]) = Instance then
      begin
        Instance.Flag := False;
        Instance.AStart := Now;
        isPool := True;
        Break;
      end
    end;
    if not isPool then FreeAndNil(Instance);
  finally
    FList.UnlockList;
  end;
end;

procedure TUniCobblerPool.FreeUniCon;
var
  i:Integer;
  LockedList: TList;
  function MyMinutesBetween(const ANow, AThen: TDateTime): Integer;
  begin
    Result := Round(MinuteSpan(ANow, AThen));
  end;
begin
  LockedList := FList.LockList;
  try
    for I := LockedList.Count - 1 downto 0 do
    begin
      if MyMinutesBetween(Now,TUniCobbler(LockedList.Items[i]).AStart) >= FMPollingInterval then //�ͷų�����ò��õ�ADO
      begin
        TUniCobbler(LockedList.Items[i]).Free;
        LockedList.Delete(I);
      end;
    end;
  finally
    FList.UnlockList;
  end;
end;

procedure TUniCobblerPool.OnMyTimer(Sender: TObject);
begin
  FreeUniCon;
end;

procedure TUniCobblerPool.SetFSXunHuan(Value: Integer);
begin
  if FSXunHuan <> Value then FSXunHuan := Value;
end;

procedure TUniCobblerPool.SetPoolCount(Value: Integer);
begin
  //�����õĳش�С ������ С�� �ϴ����õĴ�С
  if Value = 0 then Exit;
  if FPOOLNUMBER < Value then FPOOLNUMBER := Value;
end;



end.
