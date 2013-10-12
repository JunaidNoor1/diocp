unit uICDSOperator;
///
///  2013��5��27�� 15:43:41
///    Execute
///    ExecuteUpdate
///    Decode.setData
///    �޸ĳ��з���ֵ�ĺ���

interface

const
  CDS_CODE_NO_ERROR = 0;
  CDS_CODE_ERROR = -1;

type                                                           
  IDBAccessOperator = interface(IInterface)
    ['{EBD61421-4D50-48C5-81A6-5CAC70EB6852}']
    function executeSQL(pvCmdText:PAnsiChar): Integer; stdcall;
    function getTableFields(pvTable:PAnsiChar):PAnsiChar;stdcall;
  end;

  ICDSEncode = interface(IInterface)
    ['{770DCFA9-FF77-4DA0-B8BD-484CD0B572CF}']
    function getPackageData:PAnsiChar;stdcall;
    procedure setTableINfo(pvUpdateTable:PAnsiChar; pvKeyFields:PAnsiChar);stdcall;
    procedure setData(pvData:OleVariant;pvDelta:OleVariant);stdcall;
    function Execute: Integer; stdcall;
  end;


  ICDSDecode = interface(IInterface)
    ['{BD95B72B-89C4-4B8E-AC51-06A89F4E9150}']
    
    //��ȡ����õ�SQL���
    function getUpdateSql():PAnsiChar;stdcall;

    function setData(pvEncodeData:PAnsiChar): Integer; stdcall;

    //�����ֵ��TabFields���Բ����и�ֵIDBAccessOperator
    procedure SetTableFields(pvValue: PAnsiChar);stdcall;

    //ͨ���ýӿڻ�ȡTableFields
    procedure setDBAccessOperator(dbOpera: IDBAccessOperator);stdcall;

    //���ܺ��SQL���ܱ���ѯ����������
    procedure setEncryptSQL(pvValue:Boolean);stdcall;

    //���н���
    function Execute: Integer; stdcall;

    //��������� IDBAccessOperatorִ�и������
    function ExecuteUpdate: Integer; stdcall;
  end;

implementation

end.
