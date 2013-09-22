unit uClientContext;

interface

uses
  Windows, JwaWinsock2, uBuffer, SyncObjs, Classes, SysUtils,
  uIOCPCentre, JSonStream;

type
  TClientContext = class(TIOCPClientContext)
  protected
    procedure DoConnect; override;
    procedure DoDisconnect; override;
    procedure DoOnWriteBack; override;

  public
    /// <summary>
    ///   ���ݴ���
    /// </summary>
    /// <param name="pvDataObject"> (TObject) </param>
    procedure dataReceived(const pvDataObject:TObject); override;

  end;

implementation

uses
  uCRCTools, Math, uUniOperator, uUniPool, UntCobblerUniPool;





procedure TClientContext.dataReceived(const pvDataObject:TObject);
var
  lvJsonStream:TJSonStream;
  lvFile:String;
  lvCmdIndex:Cardinal;
  lvXMLData, lvEncodeData:AnsiString;
  lvSQL, lvID:String;
  lvDBDataOperator:TUniOperator;
  lvPoolObj:TUniCobbler;

begin
  lvJsonStream := TJSonStream(pvDataObject);
  try
    lvCmdIndex := lvJsonStream.JSon.I['cmdIndex'];

    //ִ��SQL������ID
    if lvCmdIndex= 1001 then
    begin
      //�ͻ��˴��ݹ���������ID
      lvID := lvJsonStream.Json.S['config.accountID'];
      if lvID = '' then
      begin
        raise Exception.Create('û��ָ������ID(config.accountID)');
      end;

      //�ͻ���ָ��Ҫִ�е�SQL
      lvSQL := lvJsonStream.Json.S['script.sql'];
      if lvSQL = '' then
      begin
        raise Exception.Create('û��ָ��Ҫִ�е�SQL!');
      end;

      //ͨ������ID��ȡһ�����ӳض���
      lvPoolObj := TUniPool.getConnObject(lvID);
      try
        //������
        lvPoolObj.checkConnect;

        //Uni���ݿ��������<���Ը��ö����Ч�ʸ���>
        lvDBDataOperator := TUniOperator.Create;
        try
          //����ʹ�õ����ӳ�
          lvDBDataOperator.Connection := lvPoolObj.ConnObj;
          self.StateINfo := '������һ��lvADOOpera,׼��������!';
          try
            //��ȡһ����ѯ������
            lvXMLData := lvDBDataOperator.CDSProvider.QueryXMLData(lvSQL);
            self.StateINfo := 'lvADOOpera,ִ��SQL������,׼����д����';
          except
            raise;
          end;

          lvJsonStream.Clear();
          lvJsonStream.Stream.WriteBuffer(lvXMLData[1], Length(lvXMLData));
          lvJsonStream.setResult(True);
        finally
          lvDBDataOperator.Free;
        end;
      finally
        //�黹���ӳ�
        TUniPool.releaseConnObject(lvPoolObj);
      end;
      //��д���ݸ��ͻ���
      writeObject(lvJsonStream);
    end else
    begin
      //��������
      writeObject(lvJsonStream);
    end;
  except
    on E:Exception do
    begin
      lvJsonStream.Clear();
      lvJsonStream.setResult(False);
      lvJsonStream.setResultMsg(e.Message);
      writeObject(lvJsonStream);
    end;

  end;
end;

procedure TClientContext.DoConnect;
begin
  inherited;
end;

procedure TClientContext.DoDisconnect;
begin
  inherited;
end;



procedure TClientContext.DoOnWriteBack;
begin
  inherited;
end;

end.
