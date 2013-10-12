unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, uIOCPConsole, uIOCPJSonStreamDecoder, uIOCPJSonStreamEncoder,
  ExtCtrls, uZipTools, uIOCPProtocol;

type
  TfrmMain = class(TForm)
    edtPort: TEdit;
    btnIOCPAPIRun: TButton;
    btnStopSevice: TButton;
    pnlINfo: TPanel;
    lblClientINfo: TLabel;
    lblRecvINfo: TLabel;
    lblSendINfo: TLabel;
    lblWorkCount: TLabel;
    lblMemINfo: TLabel;
    tmrTestINfo: TTimer;
    lblClientContextINfo: TLabel;
    btnConnectConfig: TButton;
    Button1: TButton;
    procedure btnConnectConfigClick(Sender: TObject);
    procedure btnDiscountAllClientClick(Sender: TObject);
    procedure btnIOCPAPIRunClick(Sender: TObject);
    procedure btnStopSeviceClick(Sender: TObject);
    procedure tmrTestINfoTimer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FIOCPConsole: TIOCPConsole;
    FDecoder:TIOCPJSonStreamDecoder;
    FEncoder:TIOCPJSonStreamEncoder;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uIOCPCentre, uClientContext, TesterINfo, uBuffer, uMemPool, udmMain;

{$R *.dfm}

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDecoder := TIOCPJSonStreamDecoder.Create;
  FEncoder := TIOCPJSonStreamEncoder.Create;
  FIOCPConsole := TIOCPConsole.Create();

  //ע����չ�ͻ�����
  TIOCPContextFactory.instance.registerClientContextClass(TClientContext);

  //ע�������
  TIOCPContextFactory.instance.registerDecoder(FDecoder);

  //ע�������
  TIOCPContextFactory.instance.registerEncoder(FEncoder);
end;

destructor TfrmMain.Destroy;
begin
  FIOCPConsole.close;
  FDecoder.Free;
  FEncoder.Free;
  FreeAndNil(FIOCPConsole);
  inherited Destroy;
end;

procedure TfrmMain.btnConnectConfigClick(Sender: TObject);
begin
  dmMain.DoConnnectionConfig;
end;

procedure TfrmMain.btnDiscountAllClientClick(Sender: TObject);
begin
  FIOCPConsole.DisconnectAllClientContext;
end;

procedure TfrmMain.btnIOCPAPIRunClick(Sender: TObject);
begin
  if not FIOCPConsole.Active then
  begin
    FIOCPConsole.WorkerCount := 1;
    FIOCPConsole.Port := StrToInt(edtPort.Text);
    FIOCPConsole.open;
    tmrTestINfo.Enabled := true;
  end;

  btnIOCPAPIRun.Enabled := not FIOCPConsole.Active;
  btnStopSevice.Enabled := not btnIOCPAPIRun.Enabled;

end;

procedure TfrmMain.btnStopSeviceClick(Sender: TObject);
begin
  FIOCPConsole.close;
  btnIOCPAPIRun.Enabled := not FIOCPConsole.Active;
  btnStopSevice.Enabled := not btnIOCPAPIRun.Enabled;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
var
  lvData:AnsiString;
  lvBytes:TIOCPBytes;
  lvStream:TStream;
begin
  lvData := 'abcd�й���װ�ܹ�˾' + sLineBreak + '�ò���ʧ11111111111111111111111111111111' + sLineBreak +
            'abcd�й���װ�ܹ�˾' + sLineBreak + '�ò���ʧ11111111111111111111111111111111' + sLineBreak +
            'abcd�й���װ�ܹ�˾' + sLineBreak + '�ò���ʧ11111111111111111111111111111111' + sLineBreak +
            'abcd�й���װ�ܹ�˾' + sLineBreak + '�ò���ʧ11111111111111111111111111111111' + sLineBreak +
            'abcd�й���װ�ܹ�˾' + sLineBreak + '�ò���ʧ11111111111111111111111111111111' + sLineBreak +
            'abcd�й���װ�ܹ�˾' + sLineBreak + '�ò���ʧ11111111111111111111111111111111' + sLineBreak +
            'abcd�й���װ�ܹ�˾' + sLineBreak + '�ò���ʧ11111111111111111111111111111111' + sLineBreak +
            'abcd�й���װ�ܹ�˾' + sLineBreak + '�ò���ʧ11111111111111111111111111111111'
            ;
  lvBytes := TZipTools.compressStr(lvData);

  lvData := TZipTools.unCompressStr(lvBytes);
  showMessage(lvData);
  lvStream:=TMemoryStream.Create;
  try
    lvStream.WriteBuffer(lvData[1], Length(lvData));
    TZipTools.compressStreamEX(lvStream);
    TZipTools.unCompressStreamEX(lvStream);

    lvStream.Position := 0;
    setLength(lvData, lvStream.Size);
    lvStream.ReadBuffer(lvData[1], lvStream.Size);
    showMessage(lvData);
  finally
    lvStream.Free;
  end;
end;

procedure TfrmMain.tmrTestINfoTimer(Sender: TObject);
var
  lvCount, lvBusyCount:Integer;
begin
  lblClientINfo.Caption := '������:' + IntToStr(TesterINfo.__ClientContextCount);
  lblRecvINfo.Caption :=   '�������ݴ���:' + IntToStr(TesterINfo.__RecvTimes);
  lblSendINfo.Caption :=   '�������ݴ���:' + IntToStr(TesterINfo.__SendTimes);
  lblWorkCount.Caption :=  '�����߳�:' + IntToStr(FIOCPConsole.WorkerCount);
  lblMemINfo.Caption :=   Format(
     'IO�ڴ��ع�(%d),����(%d)',
     [TIODataMemPool.instance.getCount, TIODataMemPool.instance.getUseableCount]);

  lvCount := TIOCPContextFactory.instance.IOCPContextPool.count;
  lvBusyCount := TIOCPContextFactory.instance.IOCPContextPool.BusyCount;
  lblClientContextINfo.Caption :=   Format(
     'ClientContext�ع�(%d),����(%d)',
     [lvCount, lvCount - lvBusyCount]);
end;

end.
