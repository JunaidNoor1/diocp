unit uIOCPJSonStreamDecoder;

interface

uses
  uIOCPCentre, uBuffer, Classes, JSonStream, uIOCPFileLogger, SysUtils;

type
  TIOCPJSonStreamDecoder = class(TIOCPDecoder)
  protected
    /// <summary>
    ///   �����յ�������,����н��յ�����,���ø÷���,���н���
    /// </summary>
    /// <returns>
    ///   ���ؽ���õĶ���
    /// </returns>
    /// <param name="inBuf"> ���յ��������� </param>
    function Decode(const inBuf: TBufferLink): TObject; override;
  end;


implementation

uses
  Windows, uNetworkTools, superobject, uZipTools, FileLogger;

function TIOCPJSonStreamDecoder.Decode(const inBuf: TBufferLink): TObject;
var
  lvJSonLength, lvStreamLength:Integer;
  lvData:String;
  lvBuffer:array of Char;
  lvBufData:PAnsiChar;
  lvStream:TMemoryStream;
  lvJsonStream:TJsonStream;
  lvBytes:TBytes;
  lvValidCount:Integer;
begin
  Result := nil;

  //��������е����ݳ��Ȳ�����ͷ���ȣ�����ʧ��<json�ַ�������,������>
  lvValidCount := inBuf.validCount;
  if (lvValidCount < SizeOf(Integer) + SizeOf(Integer)) then
  begin
    Exit;
  end;

  //��¼��ȡλ��
  inBuf.markReaderIndex;
  inBuf.readBuffer(@lvJSonLength, SizeOf(Integer));
  inBuf.readBuffer(@lvStreamLength, SizeOf(Integer));

  lvJSonLength := TNetworkTools.ntohl(lvJSonLength);
  lvStreamLength := TNetworkTools.ntohl(lvStreamLength);

  //��������е����ݲ���json�ĳ��Ⱥ�������<˵�����ݻ�û����ȡ���>����ʧ��
  lvValidCount := inBuf.validCount;
  if lvValidCount < (lvJSonLength + lvStreamLength) then
  begin
    //����buf�Ķ�ȡλ��
    inBuf.restoreReaderIndex;
    exit;
  end else if (lvJSonLength + lvStreamLength) = 0 then
  begin
    //������Ϊ0<����0>�ͻ��˿���������Ϊ�Զ�����ʹ��
    TIOCPFileLogger.logDebugMessage('���յ�һ��[00]����!');
    Exit;
  end;



  //����ɹ�
  lvJsonStream := TJsonStream.Create;
  Result := lvJsonStream;

  //��ȡjson�ַ���
  if lvJSonLength > 0 then
  begin
    SetLength(lvBytes, lvJSonLength);
    ZeroMemory(@lvBytes[0], lvJSonLength);
    inBuf.readBuffer(@lvBytes[0], lvJSonLength);

    lvData := TNetworkTools.Utf8Bytes2AnsiString(lvBytes);

    lvJsonStream.Json := SO(lvData);
  end else
  begin
    TFileLogger.instance.logMessage('���յ�һ��JSonΪ�յ�һ����������!', 'IOCP_ALERT_');
  end;


  //��ȡ������ 
  if lvStreamLength > 0 then
  begin
    GetMem(lvBufData, lvStreamLength);
    try
      inBuf.readBuffer(lvBufData, lvStreamLength);
      lvJsonStream.Stream.Size := 0;
      lvJsonStream.Stream.WriteBuffer(lvBufData^, lvStreamLength);

      //��ѹ��
      if lvJsonStream.Json.B['config.stream.zip'] then
      begin
        //��ѹ
        TZipTools.unCompressStreamEX(lvJsonStream.Stream);
      end;
    finally
      FreeMem(lvBufData, lvStreamLength);
    end;
  end;
end;

end.
