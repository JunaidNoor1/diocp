unit uICDSOperator;

///  2014��1��14�� 17:40:58
///    IEncode��IDecode������As ��IGetLastError�ӿ�
///      ���Բ�ѯ���һ�β����Ĵ���
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

  DB_TYPE_MSSQL = 1;
  DB_TYPE_ORACLE = 2;
  DB_TYPE_Access = 3;

type
  IGetLastError = interface(IInterface)
    ['{FE339954-1E01-47B3-9449-F341A9FA3231}']
    function getLastErrorCode:Integer; stdcall;
    function getLastErrDesc:PAnsiChar; stdcall;
  end;

  //���ݿ�����ӿ�
  IDBAccessOperator = interface(IInterface)
    ['{EBD61421-4D50-48C5-81A6-5CAC70EB6852}']
    function executeSQL(pvCmdText:PAnsiChar): Integer; stdcall;
    function getTableFields(pvTable:PAnsiChar):PAnsiChar;stdcall;
  end;

  //CDS����ӿڣ���DLL�ṩ
  ICDSEncode = interface(IInterface)
    ['{770DCFA9-FF77-4DA0-B8BD-484CD0B572CF}']
    function getPackageData:PAnsiChar;stdcall;
    procedure setTableINfo(pvUpdateTable:PAnsiChar; pvKeyFields:PAnsiChar);stdcall;
    procedure setData(pvData:OleVariant; pvDelta:OleVariant);stdcall;
    function Execute: Integer; stdcall;
  end;


  //CDS����ӿ�, ��DLL�ṩ
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

  //CDS����ӿ�, ��DLL�ṩ
  ICDSDecodeTypeSetter = interface(IInterface)
    ['{037E41F9-8E53-478F-8574-2EE797025D32}']
    procedure setDBType(pvType:Integer);stdcall;
  end;

implementation

end.
