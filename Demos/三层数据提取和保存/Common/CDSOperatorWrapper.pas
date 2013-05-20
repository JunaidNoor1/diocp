unit CDSOperatorWrapper;



interface

uses
  Windows, SysUtils, Classes, Controls, Forms, uICDSOperator;

type
  TCDSOperatorWrapper = class(TObject)
  public
    class procedure checkInitialize;
    class procedure checkFinalization;
  public
    class function createCDSEncode: ICDSEncode;
    class function createCDSDecode: ICDSDecode;
  end;

implementation

var
  __Handle:THandle=0;



class procedure TCDSOperatorWrapper.checkFinalization;
begin
  if __Handle <> 0 then
  begin
    FreeLibrary(__Handle);
    __Handle := 0;
  end;
end;

class procedure TCDSOperatorWrapper.checkInitialize;
var
  lvPath:AnsiString;
begin
  if __Handle = 0 then
  begin
    lvPath := ExtractFilePath(ParamStr(0)) + 'Libs\CDSOperator.dll';
    __Handle := LoadLibrary(PChar(lvPath));
    if __Handle = 0 then
    begin
      raise Exception.Create('����CDSOperator����,�Ƿ��Ѿ���?');
    end;
    lvPath := '';
  end;
end;

class function TCDSOperatorWrapper.createCDSDecode: ICDSDecode;
var
  lvInvoke:function():ICDSDecode; stdcall;
begin
  checkInitialize;
  @lvInvoke := nil;
  @lvInvoke := GetProcAddress(__Handle, 'createCDSDecode');
  if @lvInvoke = nil then
  begin
    raise Exception.Create('�Ҳ�����Ӧ��createCDSDecode����,�Ƿ���CDSOperator��̬���ļ�');
  end;
  Result := lvInvoke();
end;

class function TCDSOperatorWrapper.createCDSEncode: ICDSEncode;
var
  lvInvoke:function():ICDSEncode; stdcall;
begin
  checkInitialize;
  @lvInvoke := nil;
  @lvInvoke := GetProcAddress(__Handle, 'createCDSEncode');
  if @lvInvoke = nil then
  begin
    raise Exception.Create('�Ҳ�����Ӧ��createCDSEncode����,�Ƿ���CDSOperator��̬���ļ�');
  end;
  Result := lvInvoke();
end;

initialization

finalization
  TCDSOperatorWrapper.checkFinalization;


end.
