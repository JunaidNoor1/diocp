unit uMyObjectCoder;

interface

uses
  uIOCPCentre, uBuffer;

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

implementation

{ TMyObjectDecoder }

function TMyObjectDecoder.Decode(const inBuf: TBufferLink): TObject;
begin

end;

{ TMyObjectEncoder }

procedure TMyObjectEncoder.Encode(pvDataObject: TObject;
  const ouBuf: TBufferLink);
begin
  inherited;

end;

end.
