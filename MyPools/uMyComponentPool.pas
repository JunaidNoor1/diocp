unit uMyComponentPool;

interface

uses
  uMyObjectPool, Classes, SysUtils;

type
  TMyComponentPool = class(TMyObjectPool)
  private
    FComponentClass:TComponentClass;
  protected
    /// <summary>
    ///  ����һ������
    /// </summary>
    function createObject: TObject; override;
  public
    constructor Create(pvComponentClass: TComponentClass);
  end;

implementation

constructor TMyComponentPool.Create(pvComponentClass: TComponentClass);
begin
  inherited Create();
  FComponentClass := pvComponentClass;
end;

function TMyComponentPool.createObject: TObject;
begin
  if FComponentClass = nil then
  begin
    raise MyPoolException.Create('û�����������,�����ض���ʧ��!');
  end;
  Result := FComponentClass.Create(nil);
end;

end.
