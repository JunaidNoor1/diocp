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

//  sHead := 'HTTP/1.1 200 OK' + sLineBreak +
//           'Content-Type: text/plain'  + sLineBreak +
//           'Content-Length:' + IntToStr(Length(sData)) + sLineBreak + sLineBreak;

  //Indy��ģʽ
  //2013��6��24�� 18:29:47 
  sHead := 'HTTP/1.1 200 OK' + sLineBreak +
           'Connection: close'  + sLineBreak +
           'Content-Type: text/html; charset=ISO-8859-1'  + sLineBreak +
           'Content-Length:' + IntToStr(Length(sData)) + sLineBreak + sLineBreak + sLineBreak;

  ouBuf.AddBuffer(@sHead[1], Length(sHead));



  ouBuf.AddBuffer(@sData[1], Length(sData));
end;

end.
