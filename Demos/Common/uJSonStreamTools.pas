unit uJSonStreamTools;

interface

uses
  JSonStream, uCRCTools, SysUtils, Classes, uNetworkTools, Windows, superobject;

type
  TJSonStreamTools = class(TObject)
  public
    class function crcObject(pvObject: TJSonStream): Cardinal;

    class function pack2Stream(pvObject:TJsonStream; pvStream:TStream): Boolean;
    class function unPackFromStream(pvObject:TJsonStream; pvStream:TStream):
        Boolean;


  end;

implementation


class function TJSonStreamTools.crcObject(pvObject: TJSonStream): Cardinal;
var
  lvPack:TStream;
  lvStream:TStream;
  lvTempBuf:PAnsiChar;
  lvBufBytes:array[0..1023] of byte;
  sData:string;
  l:Integer;
begin
  lvPack := TMemoryStream.Create;
  try
    sData := '';
    if pvObject.JSon <> nil then
    begin
      sData := pvObject.JSon.AsJSon(True);
      lvPack.WriteBuffer(sData[1], Length(sData));
    end;

    lvStream := pvObject.Stream;
    if lvStream <> nil then
    begin
      lvStream.Position := 0;
      lvPack.CopyFrom(lvStream, lvStream.Size);
    end;

    lvPack.Position := 0;
    Result := TCRCTools.crc32Stream(lvPack);
  finally
    lvPack.Free;
  end;


end;

class function TJSonStreamTools.pack2Stream(pvObject:TJsonStream;
    pvStream:TStream): Boolean;
var
  lvJSonStream:TJsonStream;
  lvJSonLength:Integer;
  lvStreamLength:Integer;
  sData:String;
  lvStream:TStream;
  lvTempBuf:PAnsiChar;
  lvBytes, lvTempBytes:TBytes;
begin
  Result := False;
  if pvObject = nil then exit;
  lvJSonStream := pvObject;

  sData := lvJSonStream.JSon.AsJSon(True);
  lvBytes := TNetworkTools.ansiString2Utf8Bytes(sData);
  lvJSonLength := Length(lvBytes);
  lvStream := lvJSonStream.Stream;

  lvJSonLength := TNetworkTools.htonl(lvJSonLength);
  pvStream.WriteBuffer(lvJSonLength, SizeOf(lvJSonLength));


  if lvStream <> nil then
  begin
    lvStreamLength := lvStream.Size;
  end else
  begin
    lvStreamLength := 0;
  end;

  lvStreamLength := TNetworkTools.htonl(lvStreamLength);
  pvStream.WriteBuffer(lvStreamLength, SizeOf(lvStreamLength));

  //json bytes
  pvStream.WriteBuffer(lvBytes[0], Length(lvBytes));
  if lvStream.Size > 0 then
  begin
    lvStream.Position := 0;
    pvStream.CopyFrom(lvStream, lvStream.Size);
  end;

  Result := true;  
end;

class function TJSonStreamTools.unPackFromStream(pvObject:TJsonStream;
    pvStream:TStream): Boolean;
var
  lvJSonLength, lvStreamLength:Integer;
  lvMsg, lvData:String;


  lvBufData:PAnsiChar;
  lvStream:TMemoryStream;
  lvJsonStream:TJsonStream;
  lvBytes:TBytes;
  lvValidCount:Integer;
begin
  Result := False;

  //��������е����ݳ��Ȳ�����ͷ���ȣ�����ʧ��<json�ַ�������,������>
  lvValidCount := pvStream.Size - pvStream.Position;
  if (lvValidCount < SizeOf(Integer) + SizeOf(Integer)) then
  begin
    Exit;
  end;

  pvStream.Read(lvJSonLength, SizeOf(Integer));
  pvStream.Read(lvStreamLength, SizeOf(Integer));

  lvJSonLength := TNetworkTools.ntohl(lvJSonLength);
  lvStreamLength := TNetworkTools.ntohl(lvStreamLength);


  ///������ݹ���
  if (lvJSonLength > lvValidCount)
     or (lvStreamLength > lvValidCount)
     or ((lvJSonLength + lvStreamLength) >= lvValidCount)  then
  begin
     raise Exception.Create('���������ʽ!');
  end;
  

  //��������е����ݲ���json�ĳ��Ⱥ�������<˵�����ݻ�û����ȡ���>����ʧ��
  lvValidCount := pvStream.Size - pvStream.Position;
  if lvValidCount < (lvJSonLength + lvStreamLength) then
  begin
     raise Exception.Create('���������ʽ!');
  end;

  //����ɹ�
  lvJsonStream := pvObject;

  //��ȡjson�ַ���
  if lvJSonLength > 0 then
  begin
    SetLength(lvBytes, lvJSonLength);
    ZeroMemory(@lvBytes[0], lvJSonLength);
    pvStream.readBuffer(lvBytes[0], lvJSonLength);

    lvData := TNetworkTools.Utf8Bytes2AnsiString(lvBytes);

    lvJsonStream.Json := SO(lvData);
  end;


  //��ȡ������ 
  if lvStreamLength > 0 then
  begin
    lvValidCount := pvStream.Size - pvStream.Position;
    if lvValidCount < ( lvStreamLength) then
    begin
       raise Exception.Create('���������ʽ!');
    end;
    lvJsonStream.Stream.Position := 0;
    lvJsonStream.Stream.CopyFrom(pvStream, lvStreamLength);
  end;

  Result := true;
end;

end.
