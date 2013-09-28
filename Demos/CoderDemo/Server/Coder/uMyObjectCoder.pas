unit uMyObjectCoder;

interface

uses
  uIOCPCentre, uBuffer, uMyObject, Classes, Variants;

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
    /// <param name="ouBuf"> ����õ����� </param>
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
begin

end;

{ TMyObjectEncoder }

procedure TMyObjectEncoder.Encode(pvDataObject: TObject;
  const ouBuf: TBufferLink);
var
  lvMyObj:TMyObject;
  lvOleLen, lvStringLen:Integer;

begin
  lvMyObj := TMyObject(pvDataObject);
  lvStringLen := Length(lvMyObj.DataString);
  ouBuf.AddBuffer(@lvStringLen,sizeOf(Integer));



end;

end.
