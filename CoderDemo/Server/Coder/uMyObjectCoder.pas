unit uMyObjectCoder;

interface

uses
  uIOCPCentre, uBuffer, uMyObject, Classes, Variants, uOleVariantConverter,
  uIOCPFileLogger, uIOCPProtocol, Windows;

type
  TMyObjectDecoder = class(TIOCPDecoder)
  public
    /// <summary>
    ///   �����յ�������,����н��յ�����,���ø÷���,���н���
    /// </summary>
    /// <returns>
    ///   ���ؽ���õĶ���
    /// </returns>
    /// <param name="inBuf"> ���յ��������� </param>
    function Decode(const inBuf: TBufferLink): TObject; override;
  end;

  TMyObjectEncoder = class(TIOCPEncoder)
  public
    /// <summary>
    ///   ����Ҫ���͵Ķ���
    /// </summary>
    /// <param name="pvDataObject"> Ҫ���б���Ķ��� </param>
    /// <param name="ouBuf"> ����õ�����
    ///   �ַ�������+ole���� + �ַ������� + Ole����
    /// </param>
    procedure Encode(pvDataObject:TObject; const ouBuf: TBufferLink); override;
  end;

procedure VariantToStream(const Data: OleVariant; Stream: TStream);
function StreamToVariant(Stream: TStream): OleVariant;

implementation

procedure VariantToStream(const Data: OleVariant; Stream: TStream);
var p: Pointer;
begin
  p := VarArrayLock(Data);
  try
    Stream.Write(p^, VarArrayHighBound(Data, 1) + 1); //assuming low bound = 0
  finally
    VarArrayUnlock(Data);
  end;
end;

function StreamToVariant(Stream: TStream): OleVariant;
var p: Pointer;
begin
  Result := VarArrayCreate([0, Stream.Size - 1], varByte);
  p := VarArrayLock(Result);
  try
    Stream.Position := 0; //start from beginning of stream
    Stream.ReadBuffer(p^, Stream.Size);
  finally
    VarArrayUnlock(Result);
  end;
end;


function TMyObjectDecoder.Decode(const inBuf: TBufferLink): TObject;
var
  lvStringLen, lvStreamLength:Integer;
  lvData:AnsiString;
  lvBuffer:array of Char;
  lvBufData:PAnsiChar;
  lvStream:TMemoryStream;
  lvValidCount:Integer;
  lvBytes:TIOCPBytes;
begin
  Result := nil;

  //��������е����ݳ��Ȳ�����ͷ���ȣ�����ʧ��<�ַ�������,Ole������>
  lvValidCount := inBuf.validCount;
  if (lvValidCount < SizeOf(Integer) + SizeOf(Integer)) then
  begin
    Exit;
  end;

  //��¼��ȡλ��
  inBuf.markReaderIndex;
  inBuf.readBuffer(@lvStringLen, SizeOf(Integer));
  inBuf.readBuffer(@lvStreamLength, SizeOf(Integer));


  //��������е����ݲ���json�ĳ��Ⱥ�������<˵�����ݻ�û����ȡ���>����ʧ��
  lvValidCount := inBuf.validCount;
  if lvValidCount < (lvStringLen + lvStreamLength) then
  begin
    //����buf�Ķ�ȡλ��
    inBuf.restoreReaderIndex;
    exit;
  end else if (lvStringLen + lvStreamLength) = 0 then
  begin
    //������Ϊ0<����0>�ͻ��˿���������Ϊ�Զ�����ʹ��
    TIOCPFileLogger.logDebugMessage('���յ�һ��[00]����!');
    Exit;
  end;



  //����ɹ�
  Result := TMyObject.Create;

  //��ȡjson�ַ���
  if lvStringLen > 0 then
  begin
    SetLength(lvData, lvStringLen);
    inBuf.readBuffer(PAnsiChar(lvData), lvStringLen);
    TMyObject(Result).DataString := lvData;
  end;

  //��ȡOleֵ
  if lvStreamLength > 0 then
  begin
    GetMem(lvBufData, lvStreamLength);
    try
      inBuf.readBuffer(lvBufData, lvStreamLength);
      lvStream := TMemoryStream.Create;
      try
        lvStream.WriteBuffer(lvBufData^, lvStreamLength);
        lvStream.Position := 0;

        TMyObject(Result).Ole := ReadOleVariant(lvStream);
      finally
        lvStream.Free;
      end;
    finally
      FreeMem(lvBufData, lvStreamLength);
    end;
  end;
end;

{ TMyObjectEncoder }

procedure TMyObjectEncoder.Encode(pvDataObject: TObject;
  const ouBuf: TBufferLink);
var
  lvMyObj:TMyObject;
  lvOleStream:TMemoryStream;
  lvOleLen, lvStringLen:Integer;
begin
  lvMyObj := TMyObject(pvDataObject);

  lvOleStream := TMemoryStream.Create;
  try
    WriteOleVariant(lvMyObj.Ole, lvOleStream);
    lvOleLen := lvOleStream.Size;
    lvOleStream.Position := 0;

    //�ַ�������+ole���� + �ַ������� + Ole����
    lvStringLen := Length(AnsiString(lvMyObj.DataString));

    ouBuf.AddBuffer(@lvStringLen,sizeOf(Integer));

    ouBuf.AddBuffer(@lvOleLen,sizeOf(Integer));

    ouBuf.AddBuffer(PAnsiChar(AnsiString(lvMyObj.DataString)), lvStringLen);

    ouBuf.AddBuffer(lvOleStream.Memory, lvOleLen);
  finally
    lvOleStream.Free;
  end;
end;

end.
