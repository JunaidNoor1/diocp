unit uICSClientJSonStreamCoder;


interface

uses
  Classes, JSonStream, superobject, 
  Windows,
  OverbyteIcsWSocket,
  uNetworkTools, uZipTools, Math, SysUtils, uBuffer, uMyTypes;


const
  BUF_BLOCK_SIZE = 1024;
  
type
  TICSClientJSonStreamCoder = class(TObject)
  private
    class function recvBuffer(pvSocket:TWSocket; buf: Pointer; len: Cardinal):
        Integer;
    class function sendBuffer(pvSocket:TWSocket; buf: Pointer; len: Cardinal):
        Integer;
    class function sendStream(pvSocket:TWSocket; pvStream:TStream):Integer;
  public
    /// <summary>
    ///   ���ս���
    /// </summary>
    /// <returns> Boolean
    /// </returns>
    /// <param name="pvSocket"> (TClientSocket) </param>
    /// <param name="pvObject"> (TObject) </param>
    class function Decode(pvSocket: TWSocket; pvObject: TObject): Integer;


    /// <summary>
    ///   ����ɶ���
    /// </summary>
    /// <returns> TObject
    /// </returns>
    /// <param name="inBuf"> (TBufferLink) </param>
    class function Decode4Buffer(const inBuf: TBufferLink): TObject;

    /// <summary>
    ///   ���뷢��
    /// </summary>
    /// <param name="pvSocket"> (TClientSocket) </param>
    /// <param name="pvObject"> (TObject) </param>
    class function Encode(pvSocket: TWSocket; pvObject: TObject): Integer;

  end;

implementation

uses
  FileLogger;

class function TICSClientJSonStreamCoder.Decode(pvSocket: TWSocket; pvObject:
    TObject): Integer;
var
  lvJSonLength, lvStreamLength:Integer;
  lvData, lvTemp:String;
  lvStream:TStream;

  lvJsonStream:TJsonStream;
  lvBytes:TBytes;

  l, lvRemain:Integer;
  lvBufBytes:array[0..1023] of byte;
begin
  Result := 0;
  lvJSonLength := 0;
  lvStreamLength := 0;
  //TFileLogger.instance.logDebugMessage('1100');
  l := recvBuffer(pvSocket, @lvJSonLength, SizeOf(Integer));
  Result := Result + l;

  l := recvBuffer(pvSocket, @lvStreamLength, SizeOf(Integer));

  Result := Result + l;

  if (lvJSonLength = 0) and (lvStreamLength = 0) then exit;
  
  

  lvJSonLength := TNetworkTools.ntohl(lvJSonLength);
  lvStreamLength := TNetworkTools.ntohl(lvStreamLength);


  //TFileLogger.instance.logDebugMessage('1102, ' + InttoStr(lvJSonLength) + ',' + intToStr(lvStreamLength));

  lvJsonStream := TJsonStream(pvObject);
  lvJsonStream.Clear(True);
  //TFileLogger.instance.logDebugMessage('1103');
  //��ȡjson�ַ���
  if lvJSonLength > 0 then
  begin
    //TFileLogger.instance.logDebugMessage('1104');

    lvStream:=TMemoryStream.Create();
    try
      lvRemain := lvJSonLength;
      while lvStream.Size < lvJSonLength do
      begin

        l := recvBuffer(pvSocket, @lvBufBytes[0], Min(lvRemain, (SizeOf(lvBufBytes))));
        Result := Result + l;
        lvStream.WriteBuffer(lvBufBytes[0], l);
        lvRemain := lvRemain - l;
      end;


      SetLength(lvBytes, lvStream.Size);
      lvStream.Position := 0;
      lvStream.ReadBuffer(lvBytes[0], lvStream.Size);
      lvData := TNetworkTools.Utf8Bytes2AnsiString(lvBytes);

      lvJsonStream.Json := SO(lvData);
      if (lvJsonStream.Json = nil) or (lvJsonStream.Json.DataType <> stObject) then
      begin
        TFileLogger.instance.logMessage('����JSon' + sLineBreak + lvData);
        TMemoryStream(lvStream).SaveToFile(ExtractFilePath(ParamStr(0)) + 'DEBUG_' + FormatDateTime('YYYYMMDDHHNNSS', Now()) + '.dat');
        raise Exception.Create('����JSon����ʧ��,���յ���JSon�ַ���Ϊ!');
      end;
            
    finally
      lvStream.Free;
    end;


  end;

  //��ȡ������ 
  if lvStreamLength > 0 then
  begin
    lvStream := lvJsonStream.Stream;
    lvStream.Size := 0;
    lvRemain := lvStreamLength;
    while lvStream.Size < lvStreamLength do
    begin
      l := recvBuffer(pvSocket, @lvBufBytes[0], Min(lvRemain, (SizeOf(lvBufBytes))));
      Result := Result + l;
      lvStream.WriteBuffer(lvBufBytes[0], l);
      lvRemain := lvRemain - l;
    end;

    //��ѹ��
    if (lvJsonStream.Json <> nil) and (lvJsonStream.Json.B['config.stream.zip']) then
    begin
      //��ѹ
      TZipTools.unCompressStreamEX(lvJsonStream.Stream);
    end;
  end;
end;

class function TICSClientJSonStreamCoder.Decode4Buffer(const inBuf:
    TBufferLink): TObject;
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

class function TICSClientJSonStreamCoder.Encode(pvSocket: TWSocket; pvObject:
    TObject): Integer;
var
  lvJSonStream:TJsonStream;
  lvJSonLength:Integer;
  lvStreamLength:Integer;
  sData, lvTemp:String;
  lvStream, lvSendStream:TStream;
  lvTempBuf:PAnsiChar;

  lvBytes, lvTempBytes:TBytes;
  
  l:Integer;
  lvBufBytes:array[0..1023] of byte;
begin
  if pvObject = nil then exit;
  lvJSonStream := TJsonStream(pvObject);
  
  //�Ƿ�ѹ����
  if (lvJSonStream.Stream <> nil) then
  begin
    if lvJSonStream.Json.O['config.stream.zip'] <> nil then
    begin
      if lvJSonStream.Json.B['config.stream.zip'] then
      begin
        //ѹ����
        TZipTools.compressStreamEx(lvJSonStream.Stream);
      end;
    end else if lvJSonStream.Stream.Size > 0 then
    begin
      //ѹ����
      TZipTools.compressStreamEx(lvJSonStream.Stream);
      lvJSonStream.Json.B['config.stream.zip'] := true;
    end;
  end;

  sData := lvJSonStream.JSon.AsJSon(True, false);
  //ת����Utf8��ʽ��Bytes
  lvBytes := TNetworkTools.ansiString2Utf8Bytes(sData);
  lvJSonLength := Length(lvBytes);

  lvStream := lvJSonStream.Stream;
  if lvStream <> nil then
  begin
    lvStreamLength := lvStream.Size;
  end else
  begin
    lvStreamLength := 0;
  end;

  lvJSonLength := TNetworkTools.htonl(lvJSonLength);
  lvStreamLength := TNetworkTools.htonl(lvStreamLength);

//  pvSocket.sendBuffer(@lvJSonLength, SizeOf(lvJSonLength));
//  pvSocket.sendBuffer(@lvStreamLength, SizeOf(lvStreamLength));
//  //json bytes
//  pvSocket.sendBuffer(@lvBytes[0], Length(lvBytes));


  lvSendStream := TMemoryStream.Create;
  try
    lvSendStream.Write(lvJSonLength, SizeOf(lvJSonLength));
    lvSendStream.Write(lvStreamLength, SizeOf(lvStreamLength));
    lvSendStream.Write(lvBytes[0], Length(lvBytes));
    if (lvStream <> nil) and (lvStream.Size > 0) then
    begin
      lvStream.Position := 0;
      lvSendStream.CopyFrom(lvStream, lvStream.Size);
    end;

    
    //ͷ��Ϣ��JSon����
    Result := sendStream(pvSocket, lvSendStream);
  finally
    lvSendStream.Free;
  end;
end;

class function TICSClientJSonStreamCoder.recvBuffer(pvSocket: TWSocket;
    buf: Pointer; len: Cardinal): Integer;
begin
  Result := pvSocket.Receive(buf, len);
end;

class function TICSClientJSonStreamCoder.sendBuffer(pvSocket: TWSocket;
  buf: Pointer; len: Cardinal): Integer;
begin
  Result := pvSocket.Send(buf, len);
end;

class function TICSClientJSonStreamCoder.sendStream(pvSocket: TWSocket;
  pvStream: TStream): Integer;
var
  lvBufBytes:array[0..BUF_BLOCK_SIZE-1] of byte;
  l, j, lvTotal:Integer;
begin
  Result := -1;
  if pvStream = nil then Exit;
  if pvStream.Size = 0 then Exit;

  lvTotal :=0;

  pvStream.Position := 0;
  repeat
    l := pvStream.Read(lvBufBytes[0], SizeOf(lvBufBytes));
    if (l > 0) and (pvSocket.State <> wsClosed) then
    begin
      j:=sendBuffer(pvSocket, @lvBufBytes[0], l);
      if j <> l then
      begin
        raise Exception.CreateFmt('����Buffer����ָ������%d,ʵ�ʷ���:%d', [j, l]);
      end else
      begin
        lvTotal := lvTotal + j;
      end;
    end else Break;
  until (l = 0);
  Result := lvTotal;
end;

end.
