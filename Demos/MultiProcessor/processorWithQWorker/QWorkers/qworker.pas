unit qworker;

interface
{$I 'qdac.inc'}
{$DEFINE QWORKER_SIMPLE_LOCK}
uses
  classes,types,sysutils,SyncObjs
    {$IFDEF QDAC_UNICODE},system.Diagnostics{$ENDIF}
    {$IFDEF POSIX},Posix.Unistd{$ENDIF}
    ,qstring,qrbtree;
{*QWorker��һ����̨�����߹���������ڹ����̵߳ĵ��ȼ����С���QWorker�У���С��
������λ����Ϊ��ҵ��Job������ҵ���ԣ�
  1����ָ����ʱ����Զ����ƻ�ִ�У������ڼƻ�����ֻ��ʱ�ӵķֱ��ʿ��Ը���
  2���ڵõ���Ӧ���ź�ʱ���Զ�ִ����Ӧ�ļƻ�����
�����ơ�
  1.ʱ��������ʹ��0.1msΪ������λ����ˣ�32λ�������ֵΪ2147483647������
864000000��Ϳɵý��ԼΪ2.485�죬��ˣ�QWorker�е���ҵ�ӳٺͶ�ʱ�ظ�������Ϊ
2.485�졣
  2�����ٹ�������Ϊ2�����������ڵ����Ļ��Ƕ���Ļ����ϣ�����������ơ������
���õ����ٹ�������������ڵ���2������������û��ʵ�����ơ�
  3����ʱ����ҵ�������ó�����๤����������һ�룬����Ӱ��������ͨ��ҵ����Ӧ��
*}
const
  JOB_RUN_ONCE      =$01;//��ҵֻ����һ��
  JOB_IN_MAINTHREAD =$02;//��ҵֻ�������߳�������
  JOB_MAX_WORKERS   =$04;//�����ܶ�Ŀ������ܵĹ������߳���������ҵ���ݲ�֧��
  JOB_LONGTIME      =$08;//��ҵ��Ҫ�ܳ���ʱ�������ɣ��Ա���ȳ����������������ҵ��Ӱ��
  JOB_SIGNAL_WAKEUP =$10;//��ҵ�����ź���Ҫ����
  JOB_TERMINATED    =$20;//��ҵ����Ҫ�������У����Խ�����
  WORKER_ISBUSY     =$01;//������æµ
  WORKER_PROCESSLONG=$02;//��ǰ�����һ����ʱ����ҵ
  WORKER_RESERVED   =$04;//��ǰ��������һ������������
  Q1MillSecond      =10;//1ms
  Q1Second          =10000;//1s
  Q1Minute          =600000;//60s/1min
  Q1Hour            =36000000;//3600s/60min/1hour
  Q1Day             =864000000;//1day
type
  TQJobs=class;
  TQWorker=class;
  TQWorkers=class;
  PQSignal=^TQSignal;
  PQJob=^TQJob;
  ///<summary>��ҵ����ص�����</summary>
  ///<param name="AJob">Ҫ�������ҵ��Ϣ</param>
  TQJobProc=procedure (AJob:PQJob) of object;
  TQJob=record
    FirstRunTime:Int64;//��һ�ο�ʼ��ҵʱ��
    StartTime:Int64;//��һ����ҵ��ʼʱ��,8B
    PushTime:Int64;//���ʱ��
    PopTime:Int64;//����ʱ��
    NextTime:Int64;//��һ�����е�ʱ��,+8B=16B
    WorkerProc:TQJobProc;//��ҵ������+8/16B
    Owner:TQJobs;//��ҵ�������Ķ���
    Next:PQJob;//��һ�����
    Worker:TQWorker;//��ǰ��ҵ������
    Runs:Integer;//�Ѿ����еĴ���+4B
    MinUsedTime:Integer;//��С����ʱ��+4B
    TotalUsedTime:Integer;//�����ܼƻ��ѵ�ʱ�䣬TotalUsedTime/Runs���Եó�ƽ��ִ��ʱ��+4B
    MaxUsedTime:Integer;//�������ʱ��+4B
    Flags:Integer;//��ҵ��־λ+4B
    Data:Pointer;//������������
    case Integer of
      0:(
        SignalId: Integer;//�źű���
        Source: PQJob;//Դ��ҵ��ַ
        );
      1:
        (Interval:Integer;//����ʱ��������λΪ0.1ms��ʵ�ʾ����ܲ�ͬ����ϵͳ����+4B
        FirstDelay:Integer;//�״������ӳ٣���λΪ0.1ms��Ĭ��Ϊ0
        );
  end;
  /// <summary>�����߼�¼�ĸ�������</summary>
  TQJobHelper=record helper for TQJob
  private
    function GetAvgTime: Integer;inline;
    function GetInMainThread: Boolean;inline;
    function GetIsLongtimeJob: Boolean;inline;
    function GetIsSignalWakeup: Boolean;inline;
//    function GetRunMaxWorkers: Boolean;inline;
    function GetRunonce: Boolean;inline;
    procedure SetRunonce(const Value: Boolean);inline;
    procedure SetInMainThread(const Value: Boolean);inline;
    procedure SetIsLongtimeJob(const Value: Boolean);inline;
    procedure SetIsSignalWakeup(const Value: Boolean);inline;
    function GetIsTerminated: Boolean;inline;
    procedure SetIsTerminated(const Value: Boolean);inline;
    function GetEscapedTime: Int64;inline;
  protected
    procedure UpdateNextTime;
    procedure AfterRun(AUsedTime:Int64);
  public
    constructor Create(AProc:TQJobProc);overload;
    /// <summary>ֵ��������</summary>
    /// <remarks>Worker/Next/Source���Ḵ�Ʋ��ᱻ�ÿգ�Owner���ᱻ����</remarks>
    procedure Assign(const ASource:PQJob);
    /// <summary>�������ݣ��Ա�Ϊ�Ӷ����е�����׼��</summary>
    procedure Reset;inline;
    /// <summary>ƽ��ÿ������ʱ�䣬��λΪ0.1ms</summary>
    property AvgTime:Integer read GetAvgTime;
    /// <summmary>����������ʱ�䣬��λΪ0.1ms</summary>
    property EscapedTime:Int64 read GetEscapedTime;
    /// <summary>�Ƿ�ֻ����һ�Σ�Ͷ����ҵʱ�Զ�����</summary>
    property Runonce:Boolean read GetRunonce;
    /// <summary>�Ƿ�Ҫ�������߳�ִ����ҵ��ʵ��Ч����Windows��PostMessage����</summary>
    property InMainThread:Boolean read GetInMainThread;
    /// <summary>�Ƿ���һ������ʱ��Ƚϳ�����ҵ����Workers.LongtimeWork����</summary>
    property IsLongtimeJob:Boolean read GetIsLongtimeJob;
    /// <summary>�Ƿ���һ���źŴ�������ҵ</summary>
    property IsSignalWakeup:Boolean read GetIsSignalWakeup;
    /// <summary>�Ƿ�Ҫ�������ǰ��ҵ</summary>
    property IsTerminated:Boolean read GetIsTerminated write SetIsTerminated;
  end;
  //��ҵ���ж���Ļ��࣬�ṩ�����Ľӿڷ�װ
  TQJobs=class
  protected
    FOwner:TQWorkers;
    function InternalPush(AJob:PQJob):Boolean;virtual;abstract;
    function InternalPop:PQJob;virtual;abstract;
    function GetCount:Integer;virtual;abstract;
    function GetEmpty: Boolean;
    /// <summary>Ͷ��һ����ҵ</summary>
    /// <param name="AJob">ҪͶ�ĵ���ҵ</param>
    /// <remarks>�ⲿ��Ӧ����ֱ��Ͷ�����񵽶��У�����TQWorkers����Ӧ�����ڲ����á�</remarks>
    function Push(AJob:PQJob):Boolean;virtual;
    /// <summary>����һ����ҵ</summary>
    /// <returns>���ص�ǰ����ִ�еĵ�һ����ҵ</returns>
    function Pop:PQJob;virtual;
    /// <summary>���������ҵ</summary>
    procedure Clear;overload;virtual;
    /// <summary>���һ�����������������ҵ</summary>
    procedure Clear(AObject:Pointer);overload;virtual;abstract;
  public
    constructor Create(AOwner:TQWorkers);overload;virtual;
    destructor Destroy;override;
    ///���ɿ����棺Count��Emptyֵ����һ���ο����ڶ��̻߳����¿��ܲ�����֤��һ�����ִ��ʱ����һ��
    property Empty:Boolean read GetEmpty;//��ǰ�����Ƿ�Ϊ��
    property Count:Integer read GetCount;//��ǰ����Ԫ������
  end;
  {$IFDEF QWORKER_SIMPLE_LOCK}
  //һ������λ���ļ���������ʹ��ԭ�Ӻ�����λ
  TQSimpleLock=class
  private
    FFlags:Integer;
  public
    constructor Create;
    procedure Enter;inline;
    procedure Leave;inline;
  end;
  {$ELSE}
  TQSimpleLock=TCriticalSection;
  {$ENDIF}
  //TQSimpleJobs���ڹ���򵥵��첽���ã�û�д���ʱ��Ҫ�����ҵ
  TQSimpleJobs=class(TQJobs)
  protected
    FFirst:PQJob;
    FCount:Integer;
    FLocker:TQSimpleLock;
    function InternalPush(AJob:PQJob):Boolean;override;
    function InternalPop:PQJob;override;
    function GetCount:Integer;override;
    procedure Clear(AObject:Pointer);override;
  public
    constructor Create(AOwner:TQWorkers);override;
    destructor Destroy;override;
  end;

  //TQRepeatJobs���ڹ���ƻ���������Ҫ��ָ����ʱ��㴥��
  TQRepeatJobs=class(TQJobs)
  protected
    FItems:TQRBTree;
    FLocker:TCriticalSection;
    FFirstFireTime:Int64;
    function InternalPush(AJob:PQJob):Boolean;override;
    function InternalPop:PQJob;override;
    function DoTimeCompare(P1,P2:Pointer):Integer;
    procedure DoJobDelete(ATree:TQRBTree;ANode:TQRBNode);
    function GetCount:Integer;override;
    procedure Clear;override;
    procedure Clear(AObject:Pointer);override;
  public
    constructor Create(AOwner:TQWorkers);override;
    destructor Destroy;override;
  end;
  {�������߳�ʹ�õ���������������ǽ��������������Ϊ���ڹ������������ޣ�����
  �Ĵ���������ֱ����򵥵�ѭ��ֱ����Ч
  }
  TQWorker=class(TThread)
  private
    function GetInLongtimeJob: Boolean;
    function GetIsBusy: Boolean;
    function GetIsIdle: Boolean;
    function GetIsReserved: Boolean;
    procedure SetIsReserved(const Value: Boolean);
    procedure SetIsBusy(const Value: Boolean);
  protected
    FOwner:TQWorkers;
    FEvent:TEvent;
    FTimeout:Integer;
    FNext:TQWorker;
    FFlags:Integer;
    FActiveJob:PQJob;
    FActiveJobProc:TQJobProc;
    procedure Execute;override;
    procedure FireInMainThread;
  public
    constructor Create(AOwner:TQWorkers);overload;
    destructor Destroy;override;
    ///<summary>�жϵ�ǰ�Ƿ��ڳ�ʱ����ҵ���������</summary>
    property InLongtimeJob:Boolean read GetInLongtimeJob;
    ///<summary>�жϵ�ǰ�Ƿ����</summary>
    property IsIdle:Boolean read GetIsIdle;
    ///<summary>�жϵ�ǰ�Ƿ�æµ</summary>
    property IsBusy:Boolean read GetIsBusy;
    ///<summary>�жϵ�ǰ�������Ƿ����ڲ������Ĺ�����
    property IsReserved:Boolean read GetIsReserved;
  end;
  /// <summary>�źŵ��ڲ�����</summary>
  TQSignal=record
    Id:Integer;///<summary>�źŵı���</summary>
    Fired:Integer;//<summary>�ź��Ѵ�������</summary>
    Name:QStringW;///<summary>�źŵ�����</summary>
    First:PQJob;///<summary>�׸���ҵ</summary>
  end;
  /// <summary>��ҵ����ԭ���ڲ�ʹ��</summary>
  /// <remarks>
  ///  irNoJob : û����Ҫ�������ҵ����ʱ�����߻����15���ͷŵȴ�״̬�������15����
  ///   ������ҵ�����������߻ᱻ���ѣ�����ʱ��ᱻ�ͷ�
  ///  irTimeout : �������Ѿ��ȴ���ʱ�����Ա��ͷ�
  TWorkerIdleReason=(irNoJob,irTimeout);
  /// <summary>�����߹�����������������ߺ���ҵ</summary>
  TQWorkers=class
  protected
    FWorkers:array of TQWorker;
    FEnabled: Boolean;
    FMinWorkers: Integer;
    FLocker:TCriticalSection;
    FSimpleJobs:TQSimpleJobs;
    FRepeatJobs:TQRepeatJobs;
    FSignalJobs:TQHashTable;
//    FSignals:array of TQSignal;
    FTimeWorker:TThread;
    FMaxWorkers:Integer;
    FLongTimeWorkers:Integer;//��¼�³�ʱ����ҵ�еĹ����ߣ���������ʱ�䲻�ͷ���Դ�����ܻ�������������޷���ʱ��Ӧ
    FMaxLongtimeWorkers:Integer;//�������ͬʱִ�еĳ�ʱ������������������MaxWorkers��һ��
    FWorkerCount:Integer;
    FMaxSignalId:Integer;
    FTerminating:Boolean;
    function Popup:PQJob;
    procedure SetMaxWorkers(const Value: Integer);
    procedure SetEnabled(const Value: Boolean);
    procedure SetMinWorkers(const Value: Integer);
    procedure WorkerIdle(AWorker:TQWorker;AReason:TWorkerIdleReason);
    procedure WorkerBusy(AWorker:TQWorker);
    procedure WorkerTerminate(AWorker:TObject);
    procedure FreeJob(AJob:PQJob);
    function LookupIdleWorker:TQWorker;
    procedure ClearWorkers;
    procedure SignalWorkDone(AJob:PQJob;AUsedTime:Int64);
    procedure DoJobFree(ATable:TQHashTable;AHash:Cardinal;AData:Pointer);
    function Post(AJob:PQJob):Boolean;overload;
    procedure SetMaxLongtimeWorkers(const Value: Integer);
    function SignalIdByName(const AName:QStringW):Integer;
    procedure FireSignalJob(ASignal:PQSignal);
  public
    constructor Create;overload;
    destructor Destroy;override;
    /// <summary>Ͷ��һ����̨������ʼ����ҵ</summary>
    /// <param name="AJob">Ҫִ�е���ҵ����</param>
    /// <param name="AData">��ҵ���ӵ��û�����ָ��</param>
    /// <param name="ARunInMainThread">��ҵҪ�������߳���ִ��</param>
    /// <returns>�ɹ�Ͷ�ķ���True�����򷵻�False</returns>
    function Post(AProc:TQJobProc;AData:Pointer;ARunInMainThread:Boolean=False):Boolean;overload;
    /// <summary>Ͷ��һ����̨��ʱ��ʼ����ҵ</summary>
    /// <param name="AJob">Ҫִ�е���ҵ����</param>
    /// <param name="AInterval">Ҫ��ʱִ�е���ҵʱ��������λΪ0.1ms����Ҫ���1�룬��ֵΪ10000</param>
    /// <param name="AData">��ҵ���ӵ��û�����ָ��</param>
    /// <param name="ARunInMainThread">��ҵҪ�������߳���ִ��</param>
    /// <returns>�ɹ�Ͷ�ķ���True�����򷵻�False</returns>
    function Post(AProc:TQJobProc;AInterval:Integer;AData:Pointer;ARunInMainThread:Boolean=False):Boolean;overload;
    /// <summary>Ͷ��һ���ӳٿ�ʼ����ҵ</summary>
    /// <param name="AJob">Ҫִ�е���ҵ����</param>
    /// <param name="AInterval">Ҫ�ӳٵ�ʱ�䣬��λΪ0.1ms����Ҫ���1�룬��ֵΪ10000</param>
    /// <param name="AData">��ҵ���ӵ��û�����ָ��</param>
    /// <param name="ARunInMainThread">��ҵҪ�������߳���ִ��</param>
    /// <returns>�ɹ�Ͷ�ķ���True�����򷵻�False</returns>
    function Delay(AProc:TQJobProc;ADelay:Integer;AData:Pointer;ARunInMainThread:Boolean=False):Boolean;
    /// <summary>Ͷ��һ���ȴ��źŲſ�ʼ����ҵ</summary>
    /// <param name="AJob">Ҫִ�е���ҵ����</param>
    /// <param name="ASignalId">�ȴ����źű��룬�ñ�����RegisterSignal��������</param>
    /// <param name="AData">��ҵ���ӵ��û�����ָ��</param>
    /// <param name="ARunInMainThread">��ҵҪ�������߳���ִ��</param>
    /// <returns>�ɹ�Ͷ�ķ���True�����򷵻�False</returns>
    function Wait(AProc:TQJobProc;ASignalId:Integer;AData:Pointer;ARunInMainThread:Boolean=False):Boolean;
    /// <summary>Ͷ��һ����ָ��ʱ��ſ�ʼ���ظ���ҵ</summary>
    /// <param name="AProc">Ҫ��ʱִ�е���ҵ����</param>
    /// <param name="ADelay">��һ��ִ��ǰ���ӳ�ʱ��</param>
    /// <param name="AInterval">������ҵ�ظ�Ƶ��</param>
    /// <param name="ARunInMainThread">�Ƿ�Ҫ����ҵ�����߳���ִ��</param>
    function At(AProc:TQJobProc;const ADelay,AInterval:Integer;AData:Pointer;ARunInMainThread:Boolean=False):Boolean;overload;
    /// <summary>Ͷ��һ����ָ��ʱ��ſ�ʼ���ظ���ҵ</summary>
    /// <param name="AProc">Ҫ��ʱִ�е���ҵ����</param>
    /// <param name="ATime">ִ��ʱ��</param>
    /// <param name="AInterval">������ҵ�ظ�Ƶ��</param>
    /// <param name="ARunInMainThread">�Ƿ�Ҫ����ҵ�����߳���ִ��</param>
    function At(AProc:TQJobProc;const ATime:TDateTime;const AInterval:Integer;AData:Pointer;ARunInMainThread:Boolean=False):Boolean;overload;
    /// <summary>Ͷ��һ����̨��ʱ��ִ�е���ҵ</summary>
    /// <param name="AJob">Ҫִ�е���ҵ����</param>
    /// <param name="AData">��ҵ���ӵ��û�����ָ��</param>
    /// <returns>�ɹ�Ͷ�ķ���True�����򷵻�False</returns>
    /// <remarks>��ʱ����ҵǿ���ں�̨�߳���ִ�У���������Ͷ�ݵ����߳���ִ��</remarks>
    function LongtimeJob(AProc:TQJobProc;AData:Pointer):Boolean;
    /// <summary>���һ��������ص�������ҵ</summary>
    /// <param name="AObject">Ҫ�ͷŵ���ҵ��������</param>
    /// <remarks>һ����������ƻ�����ҵ�������Լ��ͷ�ǰӦ���ñ������������������ҵ��
    ///  ����δ��ɵ���ҵ���ܻᴥ���쳣��</remarks>
    procedure Clear(AObject:Pointer);overload;
    /// <summary>�������Ͷ�ĵ�ָ��������ҵ</summary>
    /// <remarks>��ǰ�汾��ʱ��֧�֣������Ҫ�������Clear(AObject)������������ҵ�������¼����账����ҵ</remarks>
    procedure Clear(AProc:TQJobProc);overload;
    /// <summary>����һ���ź�</summary>
    /// <param name="AId">�źű��룬��RegisterSignal����</param>
    /// <remarks>����һ���źź�QWorkers�ᴥ��������ע����źŹ���������̵�ִ��</remarks>
    procedure Signal(AId:Integer);overload;
    /// <summary>�����ƴ���һ���ź�</summary>
    /// <param name="AName">�ź�����</param>
    /// <remarks>����һ���źź�QWorkers�ᴥ��������ע����źŹ���������̵�ִ��</remarks>
    procedure Signal(const AName:QStringW);overload;
    /// <summary>ע��һ���ź�</summary>
    /// <param name="AName">�ź�����</param>
    /// <remarks>
    /// 1.�ظ�ע��ͬһ���Ƶ��źŽ�����ͬһ������
    /// 2.�ź�һ��ע�ᣬ��ֻ�г����˳�ʱ�Ż��Զ��ͷ�
    ///</remarks>
    function RegisterSignal(const AName:QStringW):Integer;//ע��һ���ź�����
    /// <summary>���������������������С��2</summary>
    property MaxWorkers:Integer read FMaxWorkers write SetMaxWorkers;
    /// <summary>��С����������������С��2<summary>
    property MinWorkers:Integer read FMinWorkers write SetMinWorkers;
    /// <summary>�������ĳ�ʱ����ҵ�������������ȼ�������ʼ�ĳ�ʱ����ҵ����</summary>
    property MaxLongtimeWorkers:Integer read FMaxLongtimeWorkers write SetMaxLongtimeWorkers;
    /// <summary>�Ƿ�����ʼ��ҵ�����Ϊfalse����Ͷ�ĵ���ҵ�����ᱻִ�У�ֱ���ָ�ΪTrue</summary>
    /// <remarks>EnabledΪFalseʱ�Ѿ����е���ҵ����Ȼ���У���ֻӰ����δִ�е�����</remarks>
    property Enabled:Boolean read FEnabled write SetEnabled;
    /// <summary>�Ƿ������ͷ�TQWorkers��������</summary>
    property Terminating:Boolean read FTerminating;
  end;
//��ȡϵͳ��CPU�ĺ�������
function GetCPUCount:Integer;
//��ȡ��ǰϵͳ��ʱ�������߿ɾ�ȷ��0.1ms����ʵ���ܲ���ϵͳ����
function GetTimestamp:Int64;
//�����߳����е�CPU
procedure SetThreadCPU(AHandle:THandle;ACpuNo:Integer);
//ԭ������������
function AtomicAnd(var Dest:Integer;const AMask:Integer): Integer;
//ԭ������������
function AtomicOr(var Dest:Integer;const AMask:Integer):Integer;
{$IFNDEF QDAC_UNICODE}
//Ϊ��XE6���ݣ�InterlockedCompareExchange�ȼ�
function AtomicCmpExchange(var Target: Integer; Value: Integer; Comparand: Integer): Integer;inline;
//�ȼ���InterlockedExchanged
function AtomicExchange(var Target:Integer;Value:Integer):Integer;inline;
{$ENDIF}
var
  Workers:TQWorkers;
implementation
{$IFDEF MSWINDOWS}
  uses windows;
{$ENDIF}
resourcestring
  SNotSupportNow='��ǰ��δ֧�ֹ��� %s';
  STooFewWorkers='ָ������С����������̫��(������ڵ���2)��';
  STooManyLongtimeWorker='��������̫�೤ʱ����ҵ�߳�(�����������һ��)��';
{$IFDEF MSWINDOWS}
type
  TGetTickCount64=function:Int64;
  TJobPool=class
  protected
    FFirst:PQJob;
    FCount:Integer;
    FSize:Integer;
    FLocker:TQSimpleLock;
  public
    constructor Create(AMaxSize:Integer);overload;
    destructor Destroy;override;
    procedure Push(AJob:PQJob);
    function Pop:PQJob;
    property Count:Integer read FCount;
    property Size:Integer read FSize write FSize;
  end;

{$ENDIF}
var
  JobPool:TJobPool;
{$IFDEF QDAC_UNICODE}
  _Watch:TStopWatch;
{$ELSE}
  GetTickCount64:TGetTickCount64;
  _PerfFreq:Int64;
{$ENDIF}
//����2007���ԭ�Ӳ����ӿ�
{$IFNDEF QDAC_UNICODE}
function AtomicCmpExchange(var Target: Integer; Value: Integer; Comparand: Integer): Integer;inline;
begin
Result:=InterlockedCompareExchange(Target,Value,Comparand);
end;
function AtomicIncrement(var Target: Integer): Integer;inline;
begin
Result:=InterlockedIncrement(Target);
end;
function AtomicDecrement(var Target:Integer):Integer;inline;
begin
Result:=InterlockedDecrement(Target);
end;
function AtomicExchange(var Target:Integer;Value:Integer):Integer;
begin
Result:=InterlockedExchange(Target,Value);
end;
{$ENDIF !QDAC_UNICODE}
//λ�룬����ԭֵ
function AtomicAnd(var Dest:Integer;const AMask:Integer): Integer;inline;
var
  i:Integer;
begin
repeat
  Result:=Dest;
  i:=Result and AMask;
until AtomicCmpExchange(Dest,i,Result)=Result;
end;
//λ�򣬷���ԭֵ
function AtomicOr(var Dest:Integer;const AMask:Integer):Integer;inline;
var
  i:Integer;
begin
repeat
  Result:=Dest;
  i:=Result or AMask;
until AtomicCmpExchange(Dest,i,Result)=Result;
end;
{$IFDEF MSWINDOWS}
//function InterlockedCompareExchange64
{$ENDIF}

procedure SetThreadCPU(AHandle:THandle;ACpuNo:Integer);
begin
{$IFDEF MSWINDOWS}
SetThreadIdealProcessor(AHandle,ACpuNo);
{$ELSE}
//Linux/Andriod/iOS��ʱ����,XE6δ����sched_setaffinity����
{$ENDIF}
end;


//����ֵ��ʱ�侫��Ϊ100ns����0.1ms
function GetTimestamp:Int64;
begin
{$IFDEF QDAC_UNICODE}
Result:=_Watch.Elapsed.Ticks div 1000;
{$ELSE}
if _PerfFreq>0 then
  begin
  QueryPerformanceCounter(Result);
  Result:=Result * 10000 div _PerfFreq;
  end
else if Assigned(GetTickCount64) then
  Result:=GetTickCount64*10000
else
  Result:=GetTickCount*10000;
{$ENDIF}
end;

function GetCPUCount:Integer;
{$IFDEF MSWINDOWS}
var
  si:SYSTEM_INFO;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
GetSystemInfo(si);
Result:=si.dwNumberOfProcessors;
{$ELSE}//Linux,MacOS,iOS,Andriod{POSIX}
  {$IFDEF POSIX}
  Result := sysconf(_SC_NPROCESSORS_ONLN);
  {$ELSE}//����ʶ�Ĳ���ϵͳ��CPU��Ĭ��Ϊ1
  Result:=1;
  {$ENDIF !POSIX}
{$ENDIF !MSWINDOWS}
end;
{ TQJob }

procedure TQJobHelper.AfterRun(AUsedTime: Int64);
begin
Inc(Runs);
if AUsedTime>0 then
  begin
  Inc(TotalUsedTime,AUsedTime);
  if MinUsedTime=0 then
    MinUsedTime:=AUsedTime
  else if MinUsedTime>AUsedTime then
    MinUsedTime:=AUsedTime;
  if MaxUsedTime=0 then
    MaxUsedTime:=AUsedTime
  else if MaxUsedTime<AUsedTime then
    MaxUsedTime:=AUsedTime;
  end;
end;

procedure TQJobHelper.Assign(const ASource: PQJob);
begin
StartTime:=ASource.StartTime;
PushTime:=ASource.PushTime;//���ʱ��
PopTime:=ASource.PopTime;
NextTime:=ASource.NextTime;
WorkerProc:=ASource.WorkerProc;//��ҵ������+8/16B
Runs:=ASource.Runs;
MinUsedTime:=ASource.MinUsedTime;//��С����ʱ��+4B
TotalUsedTime:=ASource.TotalUsedTime;
MaxUsedTime:=ASource.MaxUsedTime;
Flags:=ASource.Flags;
Data:=ASource.Data;
SignalId:=ASource.SignalId;
//����������Ա������
Worker:=nil;
Next:=nil;
Source:=nil;
end;

constructor TQJobHelper.Create(AProc: TQJobProc);
begin
WorkerProc:=AProc;
SetRunOnce(True);
end;

function TQJobHelper.GetAvgTime: Integer;
begin
if Runs>0 then
  Result:=TotalUsedTime div Runs
else
  Result:=0;
end;

function TQJobHelper.GetInMainThread: Boolean;
begin
Result:=(Flags and JOB_IN_MAINTHREAD)<>0;
end;

function TQJobHelper.GetIsLongtimeJob: Boolean;
begin
Result:=(Flags and JOB_LONGTIME)<>0;
end;

function TQJobHelper.GetIsSignalWakeup: Boolean;
begin
Result:=(Flags and JOB_SIGNAL_WAKEUP)<>0;
end;

function TQJobHelper.GetIsTerminated: Boolean;
begin
if Assigned(Worker) then
  Result:=Worker.Terminated or ((Flags and JOB_TERMINATED)<>0)
else
  Result:=(Flags and JOB_TERMINATED)<>0;
end;

function TQJobHelper.GetEscapedTime: Int64;
begin
Result:=GetTimeStamp-StartTime;
end;

//function TQJobHelper.GetRunMaxWorkers: Boolean;
//begin
//Result:=(Flags and JOB_MAX_WORKERS)<>0;
//end;

function TQJobHelper.GetRunonce: Boolean;
begin
Result:=(Flags and JOB_RUN_ONCE)<>0;
end;

procedure TQJobHelper.Reset;
begin
FillChar(Self,SizeOf(TQJob),0);
end;

procedure TQJobHelper.SetInMainThread(const Value: Boolean);
begin
if Value then
  Flags:=Flags or JOB_IN_MAINTHREAD
else
  Flags:=Flags and (not JOB_IN_MAINTHREAD);
end;


procedure TQJobHelper.SetIsLongtimeJob(const Value: Boolean);
begin
if Value then
  Flags:=Flags or JOB_LONGTIME
else
  Flags:=Flags and (not JOB_LONGTIME);
end;

procedure TQJobHelper.SetIsSignalWakeup(const Value: Boolean);
begin
if Value then
  Flags:=Flags or JOB_SIGNAL_WAKEUP
else
  Flags:=Flags and (not JOB_SIGNAL_WAKEUP);
end;

procedure TQJobHelper.SetIsTerminated(const Value: Boolean);
begin
if Value then
  Flags:=Flags or JOB_TERMINATED
else
  Flags:=Flags and (not JOB_TERMINATED);
end;

//procedure TQJobHelper.SetRunMaxWorkers(const Value: Boolean);
//begin
//if Value then
//  Flags:=Flags or JOB_MAX_WORKERS
//else
//  Flags:=Flags and (not JOB_MAX_WORKERS);
//end;

procedure TQJobHelper.SetRunonce(const Value: Boolean);
begin
if Value then
  Flags:=Flags or JOB_RUN_ONCE
else
  Flags:=Flags and (not JOB_RUN_ONCE);
end;

procedure TQJobHelper.UpdateNextTime;
begin
if (Runs=0) and (FirstDelay<>0) then
  NextTime:=PushTime+FirstDelay
else if Interval<>0 then
  begin
  if NextTime=0 then
    NextTime:=GetTimeStamp+Interval
  else
    Inc(NextTime,Interval);
  end
else
  NextTime:=GetTimeStamp;
end;

{ TQSimpleJobs }


procedure TQSimpleJobs.Clear(AObject:Pointer);
var
  AJob,ANext:PQJob;
begin
//�Ƚ�SimpleJobs���е��첽��ҵ��գ��Է�ֹ������ִ��
FLocker.Enter;
AJob:=FFirst;
FFirst:=nil;
FLocker.Leave;
while AJob<>nil do
  begin
  ANext:=AJob.Next;
  if TMethod(AJob.WorkerProc).Data=AObject then
    begin
    AJob.Next:=nil;
    FOwner.FreeJob(AJob);
    end
  else
    InternalPush(AJob);
  AJob:=ANext;
  end;
end;

constructor TQSimpleJobs.Create(AOwner:TQWorkers);
begin
inherited Create(AOwner);
FLocker:=TQSimpleLock.Create;
end;

destructor TQSimpleJobs.Destroy;
begin
inherited;
FreeObject(FLocker);
end;

function TQSimpleJobs.GetCount: Integer;
begin
Result:=FCount;
end;

function TQSimpleJobs.InternalPop: PQJob;
begin
FLocker.Enter;
Result:=FFirst;
if Result<>nil then
  begin
  FFirst:=Result.Next;
  Dec(FCount);
  end;
FLocker.Leave;
end;

function TQSimpleJobs.InternalPush(AJob: PQJob):Boolean;
begin
FLocker.Enter;
AJob.Next:=FFirst;
FFirst:=AJob;
Inc(FCount);
FLocker.Leave;
Result:=True;
end;

{ TQJobs }

procedure TQJobs.Clear;
var
  AItem:PQJob;
begin
repeat
  AItem:=Pop;
  if AItem<>nil then
    FOwner.FreeJob(AItem)
  else
    Break;
until 1>2;
end;

constructor TQJobs.Create(AOwner:TQWorkers);
begin
inherited Create;
FOwner:=AOwner;
end;

destructor TQJobs.Destroy;
begin
  Clear;
  inherited;
end;

function TQJobs.GetEmpty: Boolean;
begin
Result:=(Count=0);
end;

function TQJobs.Pop: PQJob;
begin
Result:=InternalPop;
if Result<>nil then
  begin
  Result.PopTime:=GetTimeStamp;
  Result.Next:=nil;
  end;
end;

function TQJobs.Push(AJob: PQJob):Boolean;
begin
AJob.Owner:=Self;
AJob.PushTime:=GetTimeStamp;
Result:=InternalPush(AJob);
if not Result then
  begin
  AJob.Next:=nil;
  FOwner.FreeJob(AJob);
  end;
end;

{ TQRepeatJobs }

procedure TQRepeatJobs.Clear;
begin
FItems.Clear;
end;

procedure TQRepeatJobs.Clear(AObject: Pointer);
var
  ANode,ANext:TQRBNode;
  APriorJob,AJob,ANextJob:PQJob;
  ACanDelete:Boolean;
begin
//��������ظ��ļƻ���ҵ
FLocker.Enter;
try
  ANode:=FItems.First;
  while ANode<>nil do
    begin
    ANext:=ANode.Next;
    AJob:=ANode.Data;
    ACanDelete:=True;
    APriorJob:=nil;
    while AJob<>nil do
      begin
      ANextJob:=AJob.Next;
      if TMethod(AJob.WorkerProc).Data=AObject then
        begin
        if ANode.Data=AJob then
          ANode.Data:=AJob.Next;
        if Assigned(APriorJob) then
          APriorJob.Next:=AJob.Next;
        AJob.Next:=nil;
        FOwner.FreeJob(AJob);
        end
      else
        begin
        ACanDelete:=False;
        APriorJob:=AJob;
        end;
      AJob:=ANextJob;
      end;
    if ACanDelete then
      FItems.Delete(ANode);
    ANode:=ANext;
    end;
finally
  FLocker.Leave;
end;
end;

constructor TQRepeatJobs.Create(AOwner:TQWorkers);
begin
inherited;
FItems:=TQRBTree.Create(DoTimeCompare);
FItems.OnDelete:=DoJobDelete;
FLocker:=TCriticalSection.Create;
end;

destructor TQRepeatJobs.Destroy;
begin
inherited;
FreeObject(FItems);
FreeObject(FLocker);
end;

procedure TQRepeatJobs.DoJobDelete(ATree: TQRBTree; ANode: TQRBNode);
begin
FOwner.FreeJob(ANode.Data);
end;

function TQRepeatJobs.DoTimeCompare(P1, P2: Pointer): Integer;
begin
Result:=PQJob(P1).NextTime-PQJob(P2).NextTime;
end;

function TQRepeatJobs.GetCount: Integer;
begin
Result:=FItems.Count;
end;

function TQRepeatJobs.InternalPop: PQJob;
var
  ANode:TQRBNode;
  ATick:Int64;
begin
Result:=nil;
ATick:=GetTimestamp;
FLocker.Enter;
try
  if FItems.Count>0 then
    begin
    ANode:=FItems.First;
    if PQJob(ANode.Data).NextTime<=ATick then
      begin
      Result:=ANode.Data;
//      OutputDebugString(PWideChar('Result.NextTime='+IntToStr(Result.NextTime)+',Current='+IntToStr(ATick)));
      if Result.Next<>nil then//���û�и�����Ҫִ�е���ҵ����ɾ����㣬����ָ����һ��
        ANode.Data:=Result.Next
      else
        begin
        ANode.Data:=nil;
        FItems.Delete(ANode);
        ANode:=FItems.First;
        if ANode<>nil then
          FFirstFireTime:=PQJob(ANode.Data).NextTime
        else//û�мƻ���ҵ�ˣ�����Ҫ��
          FFirstFireTime:=0;
        end;
      end;
    end;
finally
  FLocker.Leave;
end;
end;

function TQRepeatJobs.InternalPush(AJob: PQJob): Boolean;
var
  ANode:TQRBNode;
begin
//������ҵ���´�ִ��ʱ��
AJob.UpdateNextTime;
FLocker.Enter;
try
  ANode:=FItems.Find(AJob);
  if ANode=nil then
    begin
    FItems.Insert(AJob);
    FFirstFireTime:=PQJob(FItems.First.Data).NextTime;
    end
  else//����Ѿ�����ͬһʱ�̵���ҵ�����Լ��ҽӵ�������ҵͷ��
    begin
    AJob.Next:=PQJob(ANode.Data);
    ANode.Data:=AJob;//�׸���ҵ��Ϊ�Լ�
    end;
  Result:=True;
finally
  FLocker.Leave;
end;
end;

{ TQWorker }

constructor TQWorker.Create(AOwner: TQWorkers);
begin
inherited Create(true);
FOwner:=AOwner;
FTimeout:=1000;
FreeOnTerminate:=True;
FFlags:=0;
FEvent:=TEvent.Create(nil,False,False,'');
end;

destructor TQWorker.Destroy;
begin
FreeObject(FEvent);
  inherited;
end;

procedure TQWorker.Execute;
var
  wr:TWaitResult;
begin
try
//  PostLog(llHint,'������ %d ��ʼ����',[ThreadId]);
  while not (Terminated or FOwner.FTerminating) do
    begin
    if FOwner.FRepeatJobs.FFirstFireTime<>0 then
      begin
      FTimeout:=(FOwner.FRepeatJobs.FFirstFireTime-GetTimeStamp) div 10;
      if FTimeout<0 then//ʱ���Ѿ����ˣ���ô����ִ��
        FTimeout:=0;
      end
    else
      FTimeout:=15000;//15S�����û����ҵ���룬������Լ��Ǳ������̶߳��󣬷����ͷŹ�����
    if FTimeout<>0 then
      wr:=FEvent.WaitFor(FTimeout)
    else
      wr:=wrSignaled;
    if (wr=wrSignaled) or ((FOwner.FRepeatJobs.FFirstFireTime<>0) and (FOwner.FRepeatJobs.FFirstFireTime+10>=GetTimeStamp)) then
      begin
      if FOwner.FTerminating then
        Break;
      SetIsBusy(True);
      FOwner.WorkerBusy(Self);
      repeat
        FActiveJob:=FOwner.Popup;
        if FActiveJob<>nil then
          begin
          FActiveJob.Worker:=Self;
          FActiveJobProc:=FActiveJob.WorkerProc;//ΪClear(AObject)׼���жϣ��Ա���FActiveJob�̲߳���ȫ
          if FActiveJob.StartTime=0 then
            begin
            FActiveJob.StartTime:=GetTimeStamp;
            FActiveJob.FirstRunTime:=FActiveJob.StartTime;
            end
          else
            FActiveJob.StartTime:=GetTimeStamp;
          try
            if FActiveJob.InMainThread then
              Synchronize(Self,FireInMainThread)
            else
              FActiveJob.WorkerProc(FActiveJob);
          except
          end;
          FActiveJobProc:=nil;
          if not (FActiveJob.Runonce or FActiveJob.IsTerminated) then
            begin
            FActiveJob.AfterRun(GetTimeStamp-FActiveJob.StartTime);
            FActiveJob.Worker:=nil;
            FOwner.FRepeatJobs.Push(FActiveJob);//���¼������
            end
          else
            begin
            if FActiveJob.IsSignalWakeup then
              FOwner.SignalWorkDone(FActiveJob,GetTimeStamp-FActiveJob.StartTime)
            else if FActiveJob.IsLongtimeJob then
              AtomicDecrement(FOwner.FLongTimeWorkers);
            FActiveJob.Worker:=nil;
            FOwner.FreeJob(FActiveJob);
            end;
          end;
      until (FActiveJob=nil) or FOwner.FTerminating or Terminated or (not FOwner.Enabled);
      SetIsBusy(False);
      FOwner.WorkerIdle(Self,irNoJob);
      end
    else if not IsReserved then
      begin
      SetIsBusy(False);
      FOwner.WorkerIdle(Self,irTimeout);
      end;
    end;
finally
  FOwner.WorkerTerminate(Self);
end;
end;

procedure TQWorker.FireInMainThread;
begin
FActiveJob.WorkerProc(FActiveJob);
end;

function TQWorker.GetInLongtimeJob: Boolean;
begin
Result:=((FFlags and WORKER_PROCESSLONG)<>0);
end;

function TQWorker.GetIsBusy: Boolean;
begin
Result:=((FFlags and WORKER_ISBUSY)<>0);
end;

function TQWorker.GetIsIdle: Boolean;
begin
Result:=((FFlags and WORKER_ISBUSY)=0);
end;

function TQWorker.GetIsReserved: Boolean;
begin
Result:=((FFlags and WORKER_RESERVED)<>0);
end;

procedure TQWorker.SetIsBusy(const Value: Boolean);
begin
if Value then
  FFlags:=FFlags or WORKER_ISBUSY
else
  FFlags:=FFlags and (not WORKER_ISBUSY);
end;

procedure TQWorker.SetIsReserved(const Value: Boolean);
begin
if Value then
  FFlags:=FFlags or WORKER_RESERVED
else
  FFlags:=FFlags and (not WORKER_RESERVED);
end;

{ TQWorkers }

function TQWorkers.Post(AJob: PQJob):Boolean;
begin
if (not FTerminating) and Assigned(AJob.WorkerProc) then
  begin
  if AJob.Runonce and (AJob.FirstDelay=0) then
    Result:=FSimpleJobs.Push(AJob)
  else
    Result:=FRepeatJobs.Push(AJob);
  if Result then
    LookupIdleWorker;
  end
else
  begin
  AJob.Next:=nil;
  FreeJob(AJob);
  Result:=False;
  end;
end;

function TQWorkers.Post(AProc: TQJobProc; AData: Pointer;ARunInMainThread:Boolean):Boolean;
var
  AJob:PQJob;
begin
AJob:=JobPool.Pop;
AJob.WorkerProc:=AProc;
AJob.Data:=AData;
AJob.SetRunonce(True);
AJob.SetInMainThread(ARunInMainThread);
Result:=Post(AJob);
end;

function TQWorkers.Post(AProc: TQJobProc; AInterval: Integer; AData: Pointer;ARunInMainThread:Boolean):Boolean;
var
  AJob:PQJob;
begin
AJob:=JobPool.Pop;
AJob.WorkerProc:=AProc;
AJob.Data:=AData;
AJob.Interval:=AInterval;
AJob.SetInMainThread(ARunInMainThread);
if AInterval=0 then
  AJob.SetRunonce(True);
Result:=Post(AJob);
end;

procedure TQWorkers.Clear(AObject: Pointer);
  procedure ClearSignalJobs;
  var
    I:Integer;
    AJob,ANext,APrior:PQJob;
    AList:PQHashList;
    ASignal:PQSignal;
  begin
  FLocker.Enter;
  try
    for I := 0 to FSignalJobs.BucketCount-1 do
      begin
      AList:=FSignalJobs.Buckets[I];
      if AList<>nil then
        begin
        ASignal:=AList.Data;
        if ASignal.First<>nil then
          begin
          AJob:=ASignal.First;
          APrior:=nil;
          while AJob<>nil do
            begin
            ANext:=AJob.Next;
            if TMethod(AJob.WorkerProc).Data=AObject then
              begin
              if ASignal.First=AJob then
                ASignal.First:=ANext;
              if Assigned(APrior) then
                APrior.Next:=ANext;
              AJob.Next:=nil;
              FreeJob(AJob);
              end
            else
              APrior:=AJob;
            AJob:=ANext;
            end;
          end;
        end;
      end;
  finally
    FLocker.Leave;
  end;
  end;
  function HasJobRunning:Boolean;
  var
    I:Integer;
  begin
  Result:=False;
  FLocker.Enter;
  try
    for I := 0 to FWorkerCount-1 do
      begin
      if FWorkers[I].IsBusy then
        begin
        if TMethod(FWorkers[I].FActiveJobProc).Data=AObject then
          begin
          Result:=True;
          Break;
          end;
        end;
      end;
  finally
    FLocker.Leave;
  end;
  end;
  //�ȴ����������еĹ�����ҵ���
  procedure WaitRunningDone;
  var
    I:Integer;
  begin
  repeat
    if HasJobRunning then
      begin
      {$IFDEF QDAC_UNICODE}
      TThread.Yield;
      {$ELSE}
      SwitchToThread;
      {$ENDIF}
      end
    else//û�ҵ���Ϊ���������η���ʱ��Ƭ�������������߻���
      begin
      I:=FWorkerCount shl 1;
      while I>=0 do
        begin
        {$IFDEF QDAC_UNICODE}
        TThread.Yield;
        {$ELSE}
        SwitchToThread;
        {$ENDIF}
        Dec(I);
        end;
      Break;
      end;
  until 1>2;
  end;
begin
if Self<>nil then
  begin
  FSimpleJobs.Clear(AObject);
  FRepeatJobs.Clear(AObject);
  ClearSignalJobs;
  WaitRunningDone;
  end;
end;

function TQWorkers.At(AProc: TQJobProc; const ADelay, AInterval: Integer;
  AData: Pointer;ARunInMainThread:Boolean): Boolean;
var
  AJob:PQJob;
begin
AJob:=JobPool.Pop;
AJob.WorkerProc:=AProc;
AJob.Interval:=AInterval;
AJob.FirstDelay:=ADelay;
AJob.Data:=AData;
AJob.SetInMainThread(ARunInMainThread);
Result:=Post(AJob);
end;

function TQWorkers.At(AProc: TQJobProc; const ATime: TDateTime;
  const AInterval: Integer; AData: Pointer;ARunInMainThread:Boolean): Boolean;
var
  AJob:PQJob;
  ADelay:Integer;
  ANow,ATemp:TDateTime;
begin
AJob:=JobPool.Pop;
AJob.WorkerProc:=AProc;
AJob.Interval:=AInterval;
AJob.SetInMainThread(ARunInMainThread);
//ATime����ֻҪʱ�䲿�֣����ں���
ANow:=Now;
ANow:=ANow-Trunc(ANow);
ATemp:=ATime-Trunc(ATime);
if ANow>ATemp then //�ðɣ�����ĵ��Ѿ����ˣ�������
  ADelay:=Trunc(((1+ANow)-ATemp)*864000000)//�ӳٵ�ʱ�䣬��λΪ0.1ms
else
  ADelay:=Trunc((ATemp-ANow)*864000000);
AJob.FirstDelay:=ADelay;
AJob.Data:=AData;
Result:=Post(AJob);
end;

procedure TQWorkers.Clear(AProc: TQJobProc);
begin
raise Exception.CreateFmt(SNotSupportNow,['Clear(AJobProc)']);
end;

procedure TQWorkers.ClearWorkers;
var
  I: Integer;
begin
FTerminating:=True;
FLocker.Enter;
try
  FRepeatJobs.FFirstFireTime:=0;
  for I := 0 to FWorkerCount-1 do
    FWorkers[I].FEvent.SetEvent;
finally
  FLocker.Leave;
end;
while FWorkerCount>0 do
  {$IFDEF QDAC_UNICODE}
  TThread.Yield;
  {$ELSE}
  SwitchToThread;
  {$ENDIF}
end;

constructor TQWorkers.Create;
var
  ACpuCount:Integer;
begin
FEnabled:=True;
FSimpleJobs:=TQSimpleJobs.Create(Self);
FRepeatJobs:=TQRepeatJobs.Create(Self);
FSignalJobs:=TQHashTable.Create();
FSignalJobs.OnDelete:=DoJobFree;
FSignalJobs.AutoSize:=True;
ACpuCount:=GetCPUCount;
FMinWorkers:=1;//���ٹ�����Ϊ1��
FMaxWorkers:=ACpuCount*2+1;//Ĭ��ÿCPU���20���߳�
FLocker:=TCriticalSection.Create;
FTerminating:=False;
//����Ĭ�Ϲ�����
FWorkerCount:=1;
SetLength(FWorkers,FMaxWorkers);
FWorkers[0]:=TQWorker.Create(Self);
FWorkers[0].SetIsReserved(True);//����������Ҫ���м��
FWorkers[0].Suspended:=False;
//FWorkers[1]:=TQWorker.Create(Self);
//FWorkers[1].SetIsReserved(True);//����������Ҫ���м��
//FWorkers[1].Suspended:=False;
{$IFDEF MSWINDOWS}
if ACpuCount>1 then
  begin
  SetThreadCpu(FWorkers[0].Handle,0);
  SetThreadCpu(FWorkers[0].Handle,1);
  end;
{$ENDIF}
FMaxLongtimeWorkers:=(FMaxWorkers shr 1);
end;

function TQWorkers.Delay(AProc: TQJobProc; ADelay: Integer; AData: Pointer;ARunInMainThread:Boolean):Boolean;
var
  AJob:PQJob;
begin
AJob:=JobPool.Pop;
AJob.WorkerProc:=AProc;
AJob.SetRunonce(True);
AJob.FirstDelay:=ADelay;
AJob.Data:=AData;
AJob.SetInMainThread(ARunInMainThread);
Result:=Post(AJob);
end;

destructor TQWorkers.Destroy;
begin
ClearWorkers;
FLocker.Enter;
try
  FreeObject(FSimpleJobs);
  FreeObject(FRepeatJobs);
  FreeObject(FSignalJobs);
finally
  FreeObject(FLocker);
end;
inherited;
end;

procedure TQWorkers.DoJobFree(ATable: TQHashTable; AHash: Cardinal;
  AData: Pointer);
var
  ASignal:PQSignal;
begin
ASignal:=AData;
if ASignal.First<>nil then
  FreeJob(ASignal.First);
Dispose(ASignal);
end;

procedure TQWorkers.FireSignalJob(ASignal: PQSignal);
var
  AJob,ACopy:PQJob;
begin
Inc(ASignal.Fired);
AJob:=ASignal.First;
while AJob<>nil do
  begin
  ACopy:=JobPool.Pop;
  ACopy.Assign(AJob);
  ACopy.SetRunonce(True);
  ACopy.Source:=AJob;
  FSimpleJobs.Push(ACopy);
  AJob:=AJob.Next;
  end;
end;

procedure TQWorkers.FreeJob(AJob: PQJob);
var
  ANext:PQJob;
begin
while AJob<>nil do
  begin
  ANext:=AJob.Next;
  JobPool.Push(AJob);
  AJob:=ANext;
  end;
end;

function TQWorkers.LongtimeJob(AProc: TQJobProc; AData: Pointer): Boolean;
var
  AJob:PQJob;
begin
if AtomicIncrement(FLongTimeWorkers)<=FMaxLongTimeWorkers then
  begin
  Result:=True;
  AJob:=JobPool.Pop;
  AJob.WorkerProc:=AProc;
  AJob.Data:=AData;
  AJob.SetIsLongtimeJob(True);
  AJob.SetRunonce(True);
  Post(AJob);
  end
else
  Result:=False;
end;

function TQWorkers.LookupIdleWorker: TQWorker;
var
  I:Integer;
  AWorker:TQWorker;
begin
if not Enabled then
  begin
  Result:=nil;
  Exit;
  end;
Result:=nil;
FLocker.Enter;
try
  if not FTerminating then
    begin
    for I := 0 to FWorkerCount-1 do
      begin
      AWorker:=FWorkers[I];
      if (AWorker<>nil) and (AWorker.IsIdle) then
        begin
        Result:=AWorker;
        Break;
        end;
      end;
    if (Result=nil) and (FWorkerCount<MaxWorkers) then
      begin
      Result:=TQWorker.Create(Self);
      FWorkers[FWorkerCount]:=Result;
      {$IFDEF MSWINDOWS}
      SetThreadCpu(Result.Handle,FWorkerCount mod GetCpuCount);
      {$ENDIF}
      Inc(FWorkerCount);
      end;
    end;
finally
  FLocker.Leave;
end;
if Result<>nil then
  begin
  Result.Suspended:=False;
  Result.FEvent.SetEvent;
  end;
end;

function TQWorkers.Popup: PQJob;
begin
Result:=FSimpleJobs.Pop;
if Result=nil then
  Result:=FRepeatJobs.Pop;
end;

function TQWorkers.RegisterSignal(const AName: QStringW): Integer;
var
  ASignal:PQSignal;
begin
FLocker.Enter;
try
  Result:=SignalIdByName(AName);
  if Result<0 then
    begin
    Inc(FMaxSignalId);
    New(ASignal);
    ASignal.Id:=FMaxSignalId;
    ASignal.Fired:=0;
    ASignal.Name:=AName;
    ASignal.First:=nil;
    FSignalJobs.Add(ASignal,ASignal.Id);
    Result:=ASignal.Id;
//    OutputDebugString(PWideChar('Signal '+IntToStr(ASignal.Id)+' Allocate '+IntToHex(NativeInt(ASignal),8)));
    end;
finally
  FLocker.Leave;
end;
end;

procedure TQWorkers.SetEnabled(const Value: Boolean);
begin
if FEnabled<>Value then
  begin
  FEnabled := Value;
  if Enabled then
    begin
    if (FSimpleJobs.Count>0) or (FRepeatJobs.Count>0) then
      LookupIdleWorker;
    end;
  end;
end;

procedure TQWorkers.SetMaxLongtimeWorkers(const Value: Integer);
begin
if FMaxLongtimeWorkers <> Value then
  begin
  if Value>(MaxWorkers shr 1) then
    raise Exception.Create(STooManyLongtimeWorker);
  FMaxLongtimeWorkers:=Value;
  end;
end;

procedure TQWorkers.SetMaxWorkers(const Value: Integer);
var
  ATemp,AMaxLong:Integer;
begin
if (Value>=2) and (FMaxWorkers <> Value) then
  begin
  AtomicExchange(ATemp,FLongtimeWorkers);
  AtomicExchange(FLongTimeWorkers,0);//ǿ����0����ֹ������ĳ�ʱ����ҵ
  FLocker.Enter;
  try
    AMaxLong:=Value shr 1;
    if FLongtimeWorkers<AMaxLong then//�Ѿ����еĳ�ʱ����ҵ��С��һ��Ĺ�����
      begin
      if ATemp<AMaxLong then
        AMaxLong:=ATemp;
      if FMaxWorkers>Value then
        begin
        while Value<FWorkerCount do
          WorkerTerminate(FWorkers[FWorkerCount-1]);
        FMaxWorkers:=Value;
        SetLength(FWorkers,Value);
        end
      else
        begin
        FMaxWorkers:=Value;
        SetLength(FWorkers,Value);
        end;
      end;
  finally
    FLocker.Leave;
    AtomicExchange(FLongtimeWorkers,AMaxLong);
  end;
  end;
end;

procedure TQWorkers.SetMinWorkers(const Value: Integer);
begin
if FMinWorkers<>Value then
  begin
  if Value<2 then
    raise Exception.Create(STooFewWorkers);
  FMinWorkers := Value;
  end;
end;

procedure TQWorkers.Signal(AId: Integer);
var
  AFound:Boolean;
  ASignal:PQSignal;
begin
AFound:=False;
FLocker.Enter;
try
  ASignal:=FSignalJobs.FindFirstData(AId);
  if ASignal<>nil then
    begin
    AFound:=True;
    FireSignalJob(ASignal);
    end;
finally
  FLocker.Leave;
end;
if AFound then
  LookupIdleWorker;
end;

procedure TQWorkers.Signal(const AName: QStringW);
var
  I:Integer;
  ASignal:PQSignal;
  AFound:Boolean;
begin
AFound:=False;
FLocker.Enter;
try
  for I := 0 to FSignalJobs.BucketCount-1 do
    begin
    if FSignalJobs.Buckets[I]<>nil then
      begin
      ASignal:=FSignalJobs.Buckets[I].Data;
      if (Length(ASignal.Name)=Length(AName)) and (ASignal.Name=AName) then
        begin
        AFound:=True;
        FireSignalJob(ASignal);
        Break;
        end;
      end;
    end;
finally
  FLocker.Leave;
end;
if AFound then
  LookupIdleWorker;
end;

function TQWorkers.SignalIdByName(const AName: QStringW): Integer;
var
  I:Integer;
  ASignal:PQSignal;
begin
Result:=-1;
for I := 0 to FSignalJobs.BucketCount-1 do
  begin
  if FSignalJobs.Buckets[I]<>nil then
    begin
    ASignal:=FSignalJobs.Buckets[I].Data;
    if (Length(ASignal.Name)=Length(AName)) and (ASignal.Name=AName) then
      begin
      Result:=ASignal.Id;
      Exit;
      end;
    end;
  end;
end;

procedure TQWorkers.SignalWorkDone(AJob: PQJob;AUsedTime:Int64);
var
  ASignal:PQSignal;
  ATemp:PQJob;
begin
FLocker.Enter;
try
  ASignal:=FSignalJobs.FindFirstData(AJob.SignalId);
  ATemp:=ASignal.First;
  while ATemp<>nil do
    begin
    if ATemp=AJob.Source then
      begin
      //�����ź���ҵ��ͳ����Ϣ
      Inc(ATemp.Runs);
      if AUsedTime>0 then
        begin
        if ATemp.MinUsedTime=0 then
          ATemp.MinUsedTime:=AUsedTime
        else if AUsedTime<ATemp.MinUsedTime then
          ATemp.MinUsedTime:=AUsedTime;
        if ATemp.MaxUsedTime=0 then
          ATemp.MaxUsedTime:=AUsedTime
        else if AUsedTime>ATemp.MaxUsedTime then
          ATemp.MaxUsedTime:=AUsedTime;
        Break;
        end;
      end;
    ATemp:=ATemp.Next;
    end;
finally
  FLocker.Leave;
end;
end;

procedure TQWorkers.WorkerBusy(AWorker: TQWorker);
begin
end;

procedure TQWorkers.WorkerIdle(AWorker:TQWorker;AReason:TWorkerIdleReason);
var
  I,J:Integer;
begin
FLocker.Enter;
try
  if (AWorker<>FWorkers[0]) and (AWorker<>FWorkers[1]) and (AReason=irTimeout) then
    begin
    for I := FMinWorkers to FWorkerCount-1 do
      begin
      if AWorker=FWorkers[I] then
        begin
        AWorker.Terminate;
        for J := I+1 to FWorkerCount-1 do
          FWorkers[J-1]:=FWorkers[J];
        FWorkers[FWorkerCount-1]:=nil;
        Dec(FWorkerCount);
        Break;
        end;
      end;
    end;
finally
  FLocker.Leave;
end;
end;

procedure TQWorkers.WorkerTerminate(AWorker: TObject);
var
  I,J:Integer;
begin
FLocker.Enter;
for I := 0 to FWorkerCount-1 do
  begin
  if FWorkers[I]=AWorker then
    begin
    for J := I to FWorkerCount-2 do
      FWorkers[J]:=FWorkers[J+1];
    FWorkers[FWorkerCount-1]:=nil;
    Dec(FWorkerCount);
    Break;
    end;
  end;
FLocker.Leave;
//PostLog(llHint,'������ %d ������������ %d',[TQWorker(AWorker).ThreadID,FWorkerCount]);
end;

function TQWorkers.Wait(AProc: TQJobProc; ASignalId: Integer; AData: Pointer;ARunInMainThread:Boolean):Boolean;
var
  AJob:PQJob;
  ASignal:PQSignal;
begin
if not FTerminating then
  begin
  AJob:=JobPool.Pop;
  AJob.WorkerProc:=AProc;
  AJob.Data:=AData;
  AJob.SignalId:=ASignalId;
  AJob.SetIsSignalWakeup(True);
  AJob.PushTime:=GetTimeStamp;
  AJob.SetInMainThread(ARunInMainThread);
  Result:=False;
  FLocker.Enter;
  try
    ASignal:=FSignalJobs.FindFirstData(ASignalId);
    if ASignal<>nil then
      begin
      AJob.Next:=ASignal.First;
      ASignal.First:=AJob;
      Result:=True;
      end;
  finally
    FLocker.Leave;
    if not Result then
      JobPool.Push(AJob);
  end;
  end
else
  Result:=False;
end;

{ TJobPool }

constructor TJobPool.Create(AMaxSize: Integer);
begin
inherited Create;
FSize:=AMaxSize;
FLocker:=TQSimpleLock.Create;
end;

destructor TJobPool.Destroy;
var
  AJob:PQJob;
begin
FLocker.Enter;
while FFirst<>nil do
  begin
  AJob:=FFirst.Next;
  Dispose(FFirst);
  FFirst:=AJob;
  end;
FreeObject(FLocker);
inherited;
end;

function TJobPool.Pop: PQJob;
begin
FLocker.Enter;
Result:=FFirst;
if Result<>nil then
  begin
  FFirst:=Result.Next;
  Dec(FCount);
  end;
FLocker.Leave;
if Result=nil then
  GetMem(Result,SizeOf(TQJob));
Result.Reset;
end;

procedure TJobPool.Push(AJob: PQJob);
var
  ADoFree:Boolean;
begin
FLocker.Enter;
ADoFree:=(FCount=FSize);
if not ADoFree then
  begin
  AJob.Next:=FFirst;
  FFirst:=AJob;
  Inc(FCount);
  end;
FLocker.Leave;
if ADoFree then
  begin
  FreeMem(AJob);
  end;
end;

{ TQSimpleLock }
{$IFDEF QWORKER_SIMPLE_LOCK}

constructor TQSimpleLock.Create;
begin
inherited;
FFlags:=0;
end;

procedure TQSimpleLock.Enter;
begin
while (AtomicOr(FFlags,$01) and $01)<>0 do
  begin
  {$IFDEF QDAC_UNICODE}
  TThread.Yield;
  {$ELSE}
  SwitchToThread;
  {$ENDIF}
  end;
end;

procedure TQSimpleLock.Leave;
begin
AtomicAnd(FFlags,Integer($FFFFFFFE));
end;
{$ENDIF QWORKER_SIMPLE_JOB}
initialization
  {$IFNDEF QDAC_UNICODE}
  GetTickCount64:=GetProcAddress(GetModuleHandle(kernel32),'GetTickCount64');
  if not QueryPerformanceFrequency(_PerfFreq) then
    _PerfFreq:=-1;
  {$ELSE}
  _Watch:=TStopWatch.Create;
  _Watch.Start;
  {$ENDIF}
  JobPool:=TJobPool.Create(1024);
  Workers:=TQWorkers.Create;
finalization
  FreeObject(Workers);
  FreeObject(JobPool);
end.
