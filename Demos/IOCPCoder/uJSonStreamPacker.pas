unit uJSonStreamPacker;

interface


type
  TPackerHead = packed record
    signature : string[4];   //4���ַ���ǩ��
    headCRC: Cardinal;       //ͷ�ļ���crc
    jsonLength: Cardinal;    //json������
    streamLength: Cardinal;  //������
  end;

  TJSonStreamPacker = class(TObject)
  private
    
  public

  end;

implementation

end.
