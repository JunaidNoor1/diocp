unit CDSOperatorWrapper;


//// ��� checkRaiseLastError ����
///
///
//// ȥ��CDSGetErrorCode,CDSGetErrorDesc����
///  ��ï�� - 2014��2��14�� 10:32:22
///


///2013��5��27�� 15:41:59
///  ���CDSGetErrorCode,CDSGetErrorDesc����

///2013��5��27�� 15:41:39
///  ����XE�²��ܼ��ص�bug
///



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

    class procedure checkRaiseLastError(const pvCDSInterface:IInterface);


  end;

implementation

var
  __Handle:THandle=0;
  __CDSDecodeProc:function():ICDSDecode;stdcall;
  __CDSEncodeProc:function():ICDSEncode;stdcall;

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
  lvPath:String;
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

    @__CDSDecodeProc := GetProcAddress(__Handle, 'createCDSDecode');
    if @__CDSDecodeProc = nil then
    begin
      raise Exception.Create('�Ҳ�����Ӧ��createCDSDecode����,�Ƿ���CDSOperator��̬���ļ�');
    end;


    @__CDSEncodeProc := GetProcAddress(__Handle, 'createCDSEncode');
    if @__CDSEncodeProc = nil then
    begin
      raise Exception.Create('�Ҳ�����Ӧ��createCDSEncode����,�Ƿ���CDSOperator��̬���ļ�');
    end;

  end;
end;

class procedure TCDSOperatorWrapper.checkRaiseLastError(const pvCDSInterface: IInterface);
var
  lvErrorGetter:IGetLastError;
  lvErrorCode:Integer;
begin
  if pvCDSInterface.QueryInterface(IGetLastError, lvErrorGetter) = S_OK then
  begin
    lvErrorCode := lvErrorGetter.getLastErrorCode;
    if lvErrorCode <> 0 then
    begin
      if lvErrorCode <> -1 then
      begin
        raise Exception.Create('(' + inttoStr(lvErrorCode) + ')' + lvErrorGetter.getLastErrDesc);
      end else
      begin
        raise Exception.Create('CDSOperator�쳣:' + lvErrorGetter.getLastErrDesc);
      end;
    end;
  end;
  
end;

class function TCDSOperatorWrapper.createCDSDecode: ICDSDecode;
begin
  checkInitialize;
  Result := __CDSDecodeProc();
  if Result = nil then raise exception.Create('����CDSDecode�ӿ�ʧ��!');
end;

class function TCDSOperatorWrapper.createCDSEncode: ICDSEncode;
var
  lvInvoke:function():ICDSEncode; stdcall;
begin
  checkInitialize;
  Result := __CDSEncodeProc();
  if Result = nil then raise exception.Create('����CDSEncode�ӿ�ʧ��!');
  
end;

initialization
  @__CDSDecodeProc := nil;
  @__CDSEncodeProc := nil;

finalization
  TCDSOperatorWrapper.checkFinalization;


end.
