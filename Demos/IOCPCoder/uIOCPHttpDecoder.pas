unit uIOCPHttpDecoder;

interface

uses
  uIOCPCentre, uBuffer, Classes, uIOCPFileLogger, SysUtils;

type
  TIOCPHttpDecoder = class(TIOCPDecoder)
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

function TIOCPHttpDecoder.Decode(const inBuf: TBufferLink): TObject;
var
  lvData:AnsiString;
  lvBytes:TBytes;
  lvValidCount:Integer;
  l, j, r:Integer;
begin
  Result := nil;

  //��������е����ݳ��Ȳ�����ͷ���ȣ�����ʧ��<json�ַ�������,������>
  lvValidCount := inBuf.validCount;
  if (lvValidCount < 4) then   //#13#10#13#10
  begin
    Exit;
  end;

  
  //��¼��ȡλ��
  inBuf.markReaderIndex;


//  l := inBuf.readBuffer(@lvData[1], lvValidCount);
//
//  if lvData <> '' then
//  begin
//    if StrPos(lvData, #13#10#13#10) <> nil then
//    begin
//       Result := TStringList.Create;
//       TStrings(Result).Add(lvData);
//    end else
//    begin
//
//    end;
//  end;

  SetLength(lvBytes, 1);
  SetLength(lvData, lvValidCount);
  j := 0;
  r := 1;
  while True do
  begin
    l := inBuf.readBuffer(@lvBytes[0], 1);
    if l = 0 then
    begin
      Exit;
    end;
    Inc(j);
    lvData[j] := AnsiChar(lvBytes[0]);
    case lvBytes[0] of
      13:
        begin
          if r in [1,3] then
          begin
            Inc(r);
          end;
        end;
      10:
        begin
          if r in [2] then inc(r)
          else if r = 4 then
          begin
            Result := TStringList.Create;
            SetLength(lvData, j);
            TStrings(Result).Add(lvData);
            Break;
          end;
        end;
      else
        r:=1;
    end;
  end;

  if Result = nil then
  begin
     inBuf.restoreReaderIndex;
  end;
end;

end.
