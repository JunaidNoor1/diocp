unit uICDSOperator;

interface

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
    procedure Execute;stdcall;
  end;


  ICDSDecode = interface(IInterface)
    ['{BD95B72B-89C4-4B8E-AC51-06A89F4E9150}']
    
    //��ȡ����õ�SQL���
    function getUpdateSql():PAnsiChar;stdcall;

    procedure setData(pvEncodeData:PAnsiChar);stdcall;

    //�����ֵ��TabFields���Բ����и�ֵIDBAccessOperator
    procedure SetTableFields(pvValue: PAnsiChar);stdcall;

    //ͨ���ýӿڻ�ȡTableFields
    procedure setDBAccessOperator(dbOpera: IDBAccessOperator);stdcall;

    //���ܺ��SQL���ܱ���ѯ����������
    procedure setEncryptSQL(pvValue:Boolean);stdcall;

    //���н���
    procedure Execute;stdcall;

    //��������� IDBAccessOperatorִ�и������
    procedure ExecuteUpdate; stdcall;
  end;

implementation

end.
