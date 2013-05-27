unit uZipTools;

///2013��5��27�� 15:26:37
///  �����XE֧��

///2013��5��27�� 09:35:03
///  ���������ѹ������

interface

uses
  ZLib, Windows, Types, Classes, SysUtils;

{$if CompilerVersion>= 23}
  {$define NEWZLib}
{$ifend}

type
  TZipTools = class(TObject)
  public
    //ѹ���ַ���(��JAVA����)
    class function compressStr(pvData: string): TByteDynArray;

    //��ѹ�ַ���(��JAVA����)
    class function unCompressStr(pvData: TByteDynArray; pvDataSize: Integer = 0):
        string;

    //ѹ��(��JAVA����)
    class procedure compressStreamEX(const pvStream:TStream);

    //��ѹ(��JAVA����)
    class procedure unCompressStreamEX(const pvStream:TStream);

    //ѹ��(��JAVA����)
    class function compressStream(const pvStream, pvZipStream:TStream): Boolean;

    //��ѹ(��JAVA����)
    class function unCompressStream(const pvZipStream, pvStream:TStream): Boolean;


    //ѹ��(��JAVA����)
    class function compressBuf(const Buffer; Count: Longint): TByteDynArray;

    //��ѹ(��JAVA����)
    class function unCompressBuf(const zipBuffer; Count: Longint): TByteDynArray;
  end;

implementation

class function TZipTools.compressBuf(const Buffer; Count: Longint):
    TByteDynArray;
var
  lvTmp: string;
  lvBytes: TByteDynArray;
  OutBuf: Pointer;
  OutBytes: Integer;
begin
  {$if defined(NEWZLib)}
    ZLib.ZCompress(@Buffer, Count, OutBuf, OutBytes);
  {$ELSE}
    ZLib.CompressBuf(@Buffer, Count, OutBuf, OutBytes);
  {$ifend}
    try
      SetLength(Result, OutBytes);
      CopyMemory(@Result[0], OutBuf, OutBytes);
    finally
      FreeMem(OutBuf, OutBytes);
    end;
end;

class function TZipTools.unCompressBuf(const zipBuffer; Count: Longint):
    TByteDynArray;
var
  lvSize:Cardinal;
  OutBuf: Pointer;
  OutBytes: Integer;
begin
  lvSize := Count;
  {$if defined(NEWZLib)}
    Zlib.ZDecompress(@zipBuffer, lvSize, OutBuf, OutBytes);
  {$ELSE}
    Zlib.DecompressBuf(@zipBuffer, lvSize, 0, OutBuf, OutBytes);
  {$ifend}
    try
      SetLength(Result, OutBytes);
      CopyMemory(@Result[0], OutBuf, OutBytes);
    finally
      FreeMem(OutBuf, OutBytes);
    end;

end;

class function TZipTools.compressStr(pvData: string): TByteDynArray;
begin
  result := compressBuf(PAnsiChar(AnsiString(pvData))^, Length(AnsiString(pvData)));
end;

class procedure TZipTools.compressStreamEX(const pvStream:TStream);
begin
  compressStream(pvStream, pvStream);
end;


class function TZipTools.compressStream(const pvStream, pvZipStream:TStream):
    Boolean;
var
  lvTmp: string;
  lvBytes: TBytes;
  OutBuf: Pointer;
  OutBytes: Integer;
  l: Integer;
begin
  Result := False;
  if pvStream= nil then exit;

  l := pvStream.Size;

  if l = 0 then Exit;

  setLength(lvBytes, l);
  pvStream.Position := 0;
  pvStream.ReadBuffer(lvBytes[0], l);

  {$if defined(NEWZLib)}
    ZLib.ZCompress(@lvBytes[0], l, OutBuf, OutBytes);
  {$ELSE}
    ZLib.CompressBuf(@lvBytes[0], l, OutBuf, OutBytes);
  {$ifend}
    try
      pvZipStream.Size := OutBytes;
      pvZipStream.Position := 0;
      pvZipStream.WriteBuffer(OutBuf^, OutBytes);
      Result := true;
    finally
      FreeMem(OutBuf, OutBytes);
    end;

end;

class procedure TZipTools.unCompressStreamEX(const pvStream:TStream);
begin
  unCompressStream(pvStream, pvStream)
end;



class function TZipTools.unCompressStream(const pvZipStream, pvStream:TStream):
    Boolean;
var
  l:Integer;
  lvBytes: TBytes;
  OutBuf: Pointer;
  OutBytes: Integer;

begin
  Result := false;
  if pvZipStream= nil then exit;
  l := pvZipStream.Size;
  if l = 0 then Exit;

  setLength(lvBytes, l);
  pvZipStream.Position := 0;
  pvZipStream.ReadBuffer(lvBytes[0], l);

  {$if defined(NEWZLib)}
    ZLib.ZDecompress(@lvBytes[0], l, OutBuf, OutBytes);
  {$ELSE}
    Zlib.DecompressBuf(@lvBytes[0], l, 0, OutBuf, OutBytes);
  {$ifend}
    try
      pvStream.Size := OutBytes;
      pvStream.Position := 0;
      pvStream.WriteBuffer(OutBuf^, OutBytes);
      Result := true;
    finally
      FreeMem(OutBuf, OutBytes);
    end;

end;

class function TZipTools.unCompressStr(pvData: TByteDynArray; pvDataSize:
    Integer = 0): string;
var
  lvSize:Cardinal;
  lvOutBytes:TByteDynArray;
  OutBuf: Pointer;
  OutBytes: Integer;

  s:AnsiString;
begin
  lvSize := pvDataSize;
  if lvSize = 0 then lvSize := Length(AnsiString(pvData));

  lvOutBytes := self.unCompressBuf(pvData[0], lvSize);
  SetLength(s, Length(lvOutBytes));
  CopyMemory(@s[1], @lvOutBytes[0], Length(lvOutBytes));
  Result := s;

end;


end.
