unit uIOCPJSonStreamEncoder;

interface

uses
  uIOCPCentre, uBuffer, IdGlobal, JSonStream, Classes, uNetworkTools;

type
  TIOCPJSonStreamEncoder = class(TIOCPEncoder)
  public
    /// <summary>
    ///   ����Ҫ�����Ķ���
    /// </summary>
    /// <param name="pvDataObject"> Ҫ���б���Ķ��� </param>
    /// <param name="ouBuf"> ����õ����� </param>
    procedure Encode(pvDataObject:TObject; const ouBuf: TBufferLink); override;
  end;

implementation

procedure TIOCPJSonStreamEncoder.Encode(pvDataObject:TObject; const ouBuf:
    TBufferLink);
var
  lvJSonStream:TJsonStream;
  lvJSonLength:Integer;
  lvStreamLength:Integer;
  sData:String;
  lvStream:TStream;
  lvTempBuf:PAnsiChar;

  lvBytes, lvTempBytes:TIdBytes;
begin
  if pvDataObject = nil then exit;
  lvJSonStream := TJsonStream(pvDataObject);

  sData := lvJSonStream.JSon.AsJSon(True);


  lvBytes := ToBytes(sData, TIdTextEncoding.UTF8);

  lvJSonLength := Length(lvBytes);
  lvStream := lvJSonStream.Stream;

  lvJSonLength := TNetworkTools.htonl(lvJSonLength);
  ouBuf.AddBuffer(@lvJSonLength, SizeOf(lvJSonLength));


  if lvStream <> nil then
  begin
    lvStreamLength := lvStream.Size;
  end else
  begin
    lvStreamLength := 0;
  end;

  lvStreamLength := TNetworkTools.htonl(lvStreamLength);
  ouBuf.AddBuffer(@lvStreamLength, SizeOf(lvStreamLength));




  //json bytes
  ouBuf.AddBuffer(@lvBytes[0], Length(lvBytes));

  if lvStream.Size > 0 then
  begin
    //stream bytes
    GetMem(lvTempBuf, lvStream.Size);
    try
      lvStream.Position := 0;
      lvStream.ReadBuffer(lvTempBuf^, lvStream.Size);
      ouBuf.AddBuffer(lvTempBuf, lvStream.Size);
    finally
      FreeMem(lvTempBuf, lvStream.Size);
    end;
  end;

end;

end.
