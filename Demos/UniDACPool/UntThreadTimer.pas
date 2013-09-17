(*


     �Լ���д���̼߳�ʱ����û�в�����Ϣ���ƣ�����Ч

     Cobbler��д

     ���� TTimer ��ԭ��:

     Ҫ˵TTimer���ʹ�����⣬��Ҫ˵һ������Ӧ�û�����Ļص�����(OnTimer)�ķ�����
     TTimerӵ��һ��HWnd���͵ĳ�Ա����FWindowHandle�����ڲ�׽ϵͳ��Ϣ��
     TTimer��Enable������£�ÿ��Intervalʱ�䣬����һ��ϵͳ��ϢWM_TIMER,FWindowHandle��׽�������Ϣ��
     �ͻ�ִ���û��Ļص�������ʵ���û���Ҫ�Ĺ��ܡ����������Ϣ���������������������⣺

   ����1: ���������أ�TTimer��ϵͳ����һ����Ϣ���У�Ҳ����˵�����û��ص�����������֮ǰ��
          ���е�ϵͳ��Ϣ����������״̬����������ĸ��µ���Ϣ��
          �����Ļص�����˲��ִ������Ǿ�һ�п��Ż������������Ҫִ��һ�����Ӻ�ʱ�Ĳ�����
          �������ݿ��ѯʲô�ģ���һ�������ݿ����Ӳ��������ȴ�20�룩��
          ����Ľ���ͱ������ɣ�ֱ���ص�����ִ���ꡣ����Ǻ�̨ϵͳ���ã�
          Ҫ�Ǹ��û�ʹ�õľ�û�������ˡ���ʹ�������߳�����ʹ��Ҳ�������ġ�

   ����2: һ��ϵͳ������Ϣ�����ȼ����û�������Ϣ�����ȼ�Ҫ�͡�
          �����߳���ʹ��TTimerʱ������̼߳�ͨ��Ҳ����ʹ���Զ�����Ϣ��
          �����û������Լ�����Ϣ����������WM_TIMER�����ͻᱻ�����ˣ�
          ��ʱ���ͳ���ʧЧ�ˡ�

   ժ��������

*)

unit UntThreadTimer;

interface

uses
  Windows, Classes;

type
  TTimerStatus = (TS_ENABLE, TS_CHANGEINTERVAL, TS_DISABLE, TS_SETONTIMER);
  TThreadedTimer = class;
  TTimerThread = class;
  PTimerThread = ^TTimerThread;

  TTimerThread = class(TThread)
    OwnerTimer: TThreadedTimer;
    Interval: DWord;
    Enabled : Boolean;
    Status : TTimerStatus;
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
    procedure Execute; override;
    procedure DoTimer;
  end;

  TThreadedTimer = class(TComponent)
  private
    FEnabled: Boolean;
    FInterval: DWord;
    FOnTimer: TNotifyEvent;
    FTimerThread: TTimerThread;
    FThreadPriority: TThreadPriority;
  protected
    procedure UpdateTimer;
    procedure SetEnabled(Value: Boolean);
    procedure SetInterval(Value: DWord);
    procedure SetOnTimer(Value: TNotifyEvent);
    procedure Timer; dynamic;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Interval: DWord read FInterval write SetInterval default 1000;
    property OnTimer: TNotifyEvent read FOnTimer write SetOnTimer;
  end;

implementation

procedure WakeupDownThrdproc(const evenFlag: Integer); stdcall;
begin

end;
{TTimerThread}
constructor TTimerThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  Interval := 1000;
  Enabled := False;
  Status := TS_DISABLE;
end;

destructor TTimerThread.Destroy;
begin
  inherited;
end;

procedure TTimerThread.Execute;
begin
  inherited;
  while not Terminated do
  begin
    SleepEx(Interval, True);
    if (not Terminated) and (Status = TS_ENABLE) then Synchronize(DoTimer);
    if Status <> TS_ENABLE then
    begin
      case Status of
        TS_CHANGEINTERVAL:
        begin
          Status := TS_ENABLE;
          SleepEx(0,True);
        end;
        TS_DISABLE:
        begin
          Status := TS_ENABLE;
          SleepEx(0, True);
          if not Terminated then Suspend;
        end;
        TS_SETONTIMER:
        begin
          Status := TS_ENABLE;
        end else
          Status := TS_ENABLE;
      end;
    end;
  end;
end;

procedure TTimerThread.DoTimer;
begin
  OwnerTimer.Timer;
end;
{TThreadedTimer}
constructor TThreadedTimer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInterval := 1000;
  FThreadPriority := tpNormal;
  FTimerThread := TTimerThread.Create(true);
  FTimerThread.OwnerTimer := self;
end;

destructor TThreadedTimer.Destroy;
begin
  inherited Destroy;
  FTimerThread.Terminate;
  QueueUserAPC(@WakeupDownThrdproc, FTimerThread.Handle, DWORD(FTimerThread));
  FTimerThread.Free;
end;

procedure TThreadedTimer.UpdateTimer;
begin
   if (FEnabled = False) then
   begin
     FTimerThread.OwnerTimer := Self;
     FTimerThread.Interval := FInterval;
     FTimerThread.Priority := FThreadPriority;
     FTimerThread.Resume;
   end;
   if (FEnabled = True) then
   begin
     QueueUserAPC(@WakeupDownThrdproc, FTimerThread.Handle, DWORD(FTimerThread));
   end;
end;

procedure TThreadedTimer.SetEnabled(Value: Boolean);
begin
   if Value <> FEnabled then
   begin
     FEnabled := Value;
     if Value then
     begin
       FTimerThread.Status := TS_ENABLE;
       FTimerThread.Resume;
     end else
     begin
       FTimerThread.Status := TS_DISABLE;
       QueueUserAPC(@WakeupDownThrdproc, FTimerThread.Handle, DWORD(FTimerThread));
     end;
   end;
end;

procedure TThreadedTimer.SetInterval(Value: DWord);
begin
   if Value <> FInterval then
   begin
      if (not Enabled) then
      begin
        FInterval := Value;
        FTimerThread.Interval := FInterval;
      end else
      begin
        FInterval := Value;
        FTimerThread.Interval := FInterval;
        FTimerThread.Status := TS_CHANGEINTERVAL;
        QueueUserAPC(@WakeupDownThrdproc, FTimerThread.Handle, DWORD(FTimerThread));
      end;
   end;
end;

procedure TThreadedTimer.SetOnTimer(Value: TNotifyEvent);
begin
  FOnTimer := Value;
end;

procedure TThreadedTimer.Timer;
begin
  if Assigned(FOnTimer) then FOnTimer(Self);
end;

end.


