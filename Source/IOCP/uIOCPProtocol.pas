unit uIOCPProtocol;

interface

uses
  winsock2, Windows, SysUtils;

const
  //ÿ�ν��������ֽ���
  //OVERLAPPEDEx.DataBuf��ÿ�η���ռ���
  //ÿ�η��������ֽ���
  MAX_OVERLAPPEDEx_BUFFER_SIZE = 1024 * 2;  //8K

const
  IO_TYPE_Accept = 1;
  IO_TYPE_Recv = 2;
  IO_TYPE_Send = 3;   //��������
  IO_TYPE_Close = 4;  //�ر�socket

  {* IOCP�˳���־ *}
  IOCP_Queued_SHUTDOWN = $FFFFFFFF;

  //�߳��˳�
  IOCP_RESULT_EXIT = 1;

  //ִ�гɹ�
  IOCP_RESULT_OK = 0;

type
  POVERLAPPEDEx = ^OVERLAPPEDEx;

  OVERLAPPEDEx = packed record
    Overlapped: OVERLAPPED;
    IO_TYPE: Cardinal;
    DataBuf: TWSABUF;
    WorkBytes: Cardinal;    //����ǽ��գ����յ��ֽ���
    WorkFlag: Cardinal;
    pre:POVERLAPPEDEx;
    next:POVERLAPPEDEx;
  end;

  TIOCPBytes = array of Byte;

implementation

end.
