unit uIDBAccess;

interface

type
  /// <summary>
  ///   ���ݿ�����ӿ�
  /// </summary>
  IDBAccessOperator = interface(IInterface)
    ['{EBD61421-4D50-48C5-81A6-5CAC70EB6852}']
    function executeSQL(pvCmdText:PAnsiChar): Integer; stdcall;
    function getTableFields(pvTable:PAnsiChar):PAnsiChar;stdcall;
  end;

implementation

end.
