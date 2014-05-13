unit uFMIOCPDebugINfo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, ExtCtrls, uIOCPConsole, uIOCPCentre;

type
  TFMIOCPDebugINfo = class(TFrame)
    tmrTestINfo: TTimer;
    lblClientINfo: TLabel;
    lblRecvINfo: TLabel;
    lblSendINfo: TLabel;
    lblWorkCount: TLabel;
    lblMemINfo: TLabel;
    lblClientContextINfo: TLabel;
    lblSendAndRecvBytes: TLabel;
    lblSendBytes: TLabel;
    btnReset: TButton;
    lblRunTimeINfo: TLabel;
    procedure btnResetClick(Sender: TObject);
    procedure tmrTestINfoTimer(Sender: TObject);
  private
    FIOCPConsole: TIOCPConsole;
    function GetActive: Boolean;
    procedure SetActive(const Value: Boolean);
    { Private declarations }
  public
    class function createAsChild(pvParent:TWinControl;
      pvIOCPConsole:TIOCPConsole):TFMIOCPDebugINfo;
    property Active: Boolean read GetActive write SetActive;
    property IOCPConsole: TIOCPConsole read FIOCPConsole write FIOCPConsole; 
    
  end;

implementation

uses
  uIOCPDebugger, uIOCPFileLogger, uRunTimeINfoTools;

{$R *.dfm}

procedure TFMIOCPDebugINfo.btnResetClick(Sender: TObject);
begin
  TIOCPDebugger.resetDebugINfo;
end;

class function TFMIOCPDebugINfo.createAsChild(pvParent: TWinControl;
  pvIOCPConsole: TIOCPConsole): TFMIOCPDebugINfo;
begin
  Result := TFMIOCPDebugINfo.Create(pvParent.Owner);
  Result.Parent := pvParent;
  Result.Align := alClient;
  Result.Active := true;
end;

function TFMIOCPDebugINfo.GetActive: Boolean;
begin
  Result := tmrTestINfo.Enabled;
end;

procedure TFMIOCPDebugINfo.SetActive(const Value: Boolean);
begin
  tmrTestINfo.Enabled := Value;
end;

procedure TFMIOCPDebugINfo.tmrTestINfoTimer(Sender: TObject);
var
  lvCount, lvBusyCount:Integer;
begin
  try
    lblClientINfo.Caption := '������:' + IntToStr(TIOCPDebugger.clientCount);
    lblRecvINfo.Caption :=   '�������ݶ������:' + IntToStr(TIOCPDebugger.recvObjectCount);
    lblSendINfo.Caption :=   '�������ݶ������:' + IntToStr(TIOCPDebugger.sendObjectCount);
    if FIOCPConsole <> nil then
    begin
      lblWorkCount.Caption :=  '�����߳�:' + IntToStr(FIOCPConsole.WorkerCount);
    end;

    lblSendAndRecvBytes.Caption :=
      Format('����/�����ֽ���:%d/%d bytes, %d/%d blockCount',
        [TIOCPDebugger.recvBytes,
         TIOCPDebugger.sendBytes,
         TIOCPDebugger.recvBlockCount,
         TIOCPDebugger.sendBlockCount]);

    lblSendBytes.Caption :=
      Format('Ͷ��/�����ֽ���:%d/%d bytes',
        [TIOCPDebugger.WSASendBytes,
         TIOCPDebugger.sendBytes]);

    lblMemINfo.Visible := false;
//  ��ʹ��
//    lblMemINfo.Caption :=   Format(
//       'IO�ڴ��ع�(%d),����(%d)',
//       [TIODataMemPool.instance.getCount, TIODataMemPool.instance.getUseableCount]);

    lvCount := TIOCPContextFactory.instance.IOCPContextPool.count;
    lvBusyCount := TIOCPContextFactory.instance.IOCPContextPool.BusyCount;
    lblClientContextINfo.Caption :=   Format(
       'ClientContext�ع�(%d),����(%d)',
       [lvCount, lvCount - lvBusyCount]);

    lblRunTimeINfo.Caption :='�����Ѿ�����:' +  TRunTimeINfoTools.getRunTimeINfo;
  except
    on E:Exception do
    begin
       TIOCPFileLogger.logErrMessage(self.ClassName+ '.tmrTestINfoTimer, �������쳣:' + e.Message);
    end;
  end;

end;



end.
