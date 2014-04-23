unit uCDSApplyUpdateWrapper;

interface

uses
  DBClient, uICDSOperator, DB, SysUtils;

type
  TCDSApplyUpdateWrapper = class(TObject)
  public
    class procedure ExecuteApplyUpdate(pvCDS: TClientDataSet; const pvUpdateTable,
        pvUpdateKeyFields: String; const pvEncode: ICDSEncode; const pvDecode:
        ICDSDecode; const pvDBAccess: IDBAccessOperator);
  end;

implementation

class procedure TCDSApplyUpdateWrapper.ExecuteApplyUpdate(pvCDS:
    TClientDataSet; const pvUpdateTable, pvUpdateKeyFields: String; const
    pvEncode: ICDSEncode; const pvDecode: ICDSDecode; const pvDBAccess:
    IDBAccessOperator);
var
  lvUpdateKeyFields, lvUpdateTableName, lvPackDATA:AnsiString;

begin
  if pvCDS.State in [dsInsert, dsEdit] then
  begin
    pvCDS.Post;
  end;

  lvUpdateKeyFields := pvUpdateKeyFields;
  lvUpdateTableName := pvUpdateTable;

  if pvCDS.ChangeCount = 0 then exit;

  if pvEncode = nil then
    raise Exception.Create('ȱ��CDS����ӿ�!');

  if pvDecode = nil then
    raise Exception.Create('ȱ�ٽ���ӿ�!');

  pvEncode.setTableINfo(
     PAnsiChar(AnsiString(lvUpdateTableName)),
     PAnsiChar(AnsiString(lvUpdateKeyFields))
     );

  pvEncode.setData(pvCDs.Data, pvCDS.Delta);

  if pvEncode.Execute <> CDS_CODE_NO_ERROR then
  begin
    raise Exception.Create('CDS���ݱ���ʱ�����쳣:' + sLineBreak + (pvEncode as IGetLastError).getLastErrDesc);
  end;

  //��ȡ���������ַ���
  lvPackDATA := pvEncode.getPackageData;

  //������Ҫ����������ַ���
  if pvDecode.setData(PAnsiChar(AnsiString(lvPackDATA))) <> CDS_CODE_NO_ERROR then
  begin
    raise Exception.Create('CDS���ý�������ʱ�����쳣:' + sLineBreak + (pvDecode as IGetLastError).getLastErrDesc);
  end;

  //�������ݿ�����ӿ�
  pvDecode.setDBAccessOperator(pvDBAccess);
  if pvDecode.Execute <> CDS_CODE_NO_ERROR then
  begin
    raise Exception.Create('CDS����ʱ�����쳣:' + sLineBreak + (pvDecode as IGetLastError).getLastErrDesc);
  end;

  //�������ݽӿ�ִ�и������
  if pvDecode.ExecuteUpdate <> CDS_CODE_NO_ERROR then
  begin
    raise Exception.Create('CDSִ�б���SQL����쳣:' + sLineBreak + (pvDecode as IGetLastError).getLastErrDesc);
  end;                                  

  lvUpdateKeyFields := '';
  lvUpdateTableName := '';
  lvPackDATA := '';
end;

end.
