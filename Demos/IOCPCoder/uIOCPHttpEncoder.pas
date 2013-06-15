unit uIOCPHttpEncoder;

interface

uses
  uIOCPCentre, uBuffer, JSonStream, Classes, uNetworkTools, uZipTools, SysUtils;

type
  TIOCPHttpEncoder = class(TIOCPEncoder)
  public
    /// <summary>
    ///   ����Ҫ�����Ķ���
    /// </summary>
    /// <param name="pvDataObject"> Ҫ���б���Ķ��� </param>
    /// <param name="ouBuf"> ����õ����� </param>
    procedure Encode(pvDataObject:TObject; const ouBuf: TBufferLink); override;
  end;

implementation

procedure TIOCPHttpEncoder.Encode(pvDataObject:TObject; const ouBuf:
    TBufferLink);
var
  sData, sHead:AnsiString;
begin
  if pvDataObject = nil then exit;
  
  sData := TStrings(pvDataObject).Text;

  sHead := 'HTTP/1.1 200 OK' + sLineBreak +
           'Content-Type: text/plain'  + sLineBreak +
           'Content-Length:' + IntToStr(Length(sData)) + sLineBreak + sLineBreak;

  ouBuf.AddBuffer(@sHead[1], Length(sHead));



  ouBuf.AddBuffer(@sData[1], Length(sData));
end;

end.
