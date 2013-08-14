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

    procedure wirteFileData(pvDataObject:TJsonStream);
    procedure readFileData(pvDataObject:TJsonStream);
  public
    /// <summary>
    ///   ���ݴ���
    /// </summary>
    /// <param name="pvDataObject"> (TObject) </param>
    procedure dataReceived(const pvDataObject:TObject); override;
    /// <summary>TClientContext.FileRename
    /// </summary>
    /// <returns> Boolean
    /// </returns>
    /// <param name="pvSrcFile"> �����ļ��� </param>
    /// <param name="pvNewFileName"> ����·���ļ��� </param>
    class function FileRename(pvSrcFile:String; pvNewFileName:string): Boolean;


  end;

implementation

uses
  uFrameConfig, uCRCTools, Math;





procedure TClientContext.dataReceived(const pvDataObject:TObject);
var
  lvJsonStream:TJSonStream;
  lvFile:String;
  lvCmdIndex:Cardinal;
begin
  lvJsonStream := TJSonStream(pvDataObject);
  try
    lvCmdIndex := lvJsonStream.JSon.I['cmdIndex'];

    //�ϴ��ļ�
    if lvCmdIndex= 1001 then
    begin
      //д���ļ�
      wirteFileData(lvJsonStream);

      lvJsonStream.Clear();
      lvJsonStream.setResult(True);

      //��д����
      writeObject(lvJsonStream);
    end else if lvCmdIndex= 1002 then
    begin
      //��ȡ�ļ���
      readFileData(lvJsonStream);

      //��д����
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

class function TClientContext.FileRename(pvSrcFile:String;
    pvNewFileName:string): Boolean;
var
  lvNewFile:String;
begin
  lvNewFile := ExtractFilePath(pvSrcFile) + ExtractFileName(pvNewFileName);
  Result := MoveFile(pchar(pvSrcFile), pchar(lvNewFile));
end;

procedure TClientContext.readFileData(pvDataObject: TJsonStream);
const
  SEC_SIZE = 1024 * 4;
var
  lvFileStream:TFileStream;
  lvFileName, lvRealFileName:String;
  lvCrc, lvSize:Cardinal;
begin
  lvFileName:= TFrameConfig.getBasePath;
  if lvFileName = '' then
  begin
    raise Exception.Create('�����û���趨�ļ�������Ŀ¼!');
  end;
  lvFileName := lvFileName + '\' + pvDataObject.Json.S['fileName'];

  //ɾ��ԭ���ļ�
  if not FileExists(lvFileName) then raise Exception.CreateFmt('(%s)�ļ�������!', [pvDataObject.Json.S['fileName']]);


  lvFileStream := TFileStream.Create(lvFileName, fmOpenRead or fmShareDenyWrite);
  try
    lvFileStream.Position := pvDataObject.Json.I['start'];
    pvDataObject.Clear();
    pvDataObject.Json.I['fileSize'] := lvFileStream.Size;
    lvSize := Min(SEC_SIZE, lvFileStream.Size-lvFileStream.Position);
    pvDataObject.Stream.CopyFrom(lvFileStream, lvSize);
    pvDataObject.Json.I['blockSize'] := lvSize;
    pvDataObject.Json.I['crc']:=TCRCTools.crc32Stream(pvDataObject.Stream);
  finally
    lvFileStream.Free;
  end;
  lvCrc := TCRCTools.crc32Stream(pvDataObject.Stream);

end;

procedure TClientContext.wirteFileData(pvDataObject: TJsonStream);
var
  lvFileStream:TFileStream;
  lvFileName, lvRealFileName:String;
  lvCrc:Cardinal;
begin
  lvCrc := TCRCTools.crc32Stream(pvDataObject.Stream);
  if lvCrc <> pvDataObject.Json.I['crc'] then
  begin
    raise Exception.CreateFmt('�ļ�crcУ��ʧ��' + sLineBreak + '�ļ�����Ϣ' + sLineBreak + '��ʼλ��:%d, ���С:%d',
      [pvDataObject.Json.I['start'], pvDataObject.Json.I['size']]);
  end;

//  if pvDataObject.Json.I['size'] <> pvDataObject.Stream.Size then
//  begin
//    raise Exception.Create('�����ļ�ʧ��');
//  end;


  lvFileName:= TFrameConfig.getBasePath;
  if lvFileName = '' then
  begin
    raise Exception.Create('�����û���趨�ļ�������Ŀ¼!');
  end;
  lvFileName := lvFileName + '\' + pvDataObject.Json.S['fileName'];

  //ɾ��ԭ���ļ�
  if FileExists(lvFileName) then DeleteFile(lvFileName);
  lvRealFileName := lvFileName;
  
  lvFileName := lvFileName + '.temp';

  //��һ����
  if pvDataObject.Json.I['start'] = 0 then
  begin
    if FileExists(lvFileName) then DeleteFile(lvFileName);
  end;

  if FileExists(lvFileName) then
  begin
    lvFileStream := TFileStream.Create(lvFileName, fmOpenReadWrite);
  end else
  begin
    lvFileStream :=  TFileStream.Create(lvFileName, fmCreate);
  end;
  try
    lvFileStream.Position := pvDataObject.Json.I['start'];
    pvDataObject.Stream.Position := 0;
    lvFileStream.CopyFrom(pvDataObject.Stream, pvDataObject.Stream.Size);

  finally
    lvFileStream.Free;
  end;

  if pvDataObject.Json.B['eof'] then
  begin
    FileRename(lvFileName, lvRealFileName);
  end;
end;

end.
