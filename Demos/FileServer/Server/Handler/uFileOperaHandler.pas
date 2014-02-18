unit uFileOperaHandler;

interface

uses
  JSonStream, SysUtils, Windows, Classes, uFrameConfig, Math, uCRCTools;

type
  TFileOperaHandler = class(TObject)
  private
    class function getBasePath():String;
  private
    class function BigFileSize(const AFileName: string): Int64;
    
    /// <summary>TFileOperaHandler.FileRename
    /// </summary>
    /// <returns> Boolean
    /// </returns>
    /// <param name="pvSrcFile"> �����ļ��� </param>
    /// <param name="pvNewFileName"> ����·���ļ��� </param>
    class function FileRename(pvSrcFile:String; pvNewFileName:string): Boolean;

    class procedure downFileData(pvDataObject:TJsonStream);

    class procedure uploadFileData(pvDataObject:TJsonStream);

    //��ȡ�ļ���Ϣ
    class procedure readFileINfo(pvDataObject:TJsonStream);

    //ɾ���ļ�
    class procedure FileDelete(pvDataObject:TJsonStream);
  public
    class procedure Execute(pvDataObject:TJsonStream);
  end;

implementation

{ TFTPWrapper_ProgressBar }

class function TFileOperaHandler.BigFileSize(const AFileName: string): Int64;
var
  sr: TSearchRec;
begin
  try
    if SysUtils.FindFirst(AFileName, faAnyFile, sr) = 0 then
      result := Int64(sr.FindData.nFileSizeHigh) shl Int64(32) + Int64(sr.FindData.nFileSizeLow)
    else
      result := -1;
  finally
    SysUtils.FindClose(sr);
  end;
end;

class procedure TFileOperaHandler.Execute(pvDataObject: TJsonStream);
var
  lvCMDIndex:Integer;
begin
  lvCMDIndex := pvDataObject.Json.I['cmd.index'];
  case lvCMDIndex of
    1:       // �����ļ�
      begin
        downFileData(pvDataObject);
      end;
    2:       //�ϴ��ļ�
      begin
        self.uploadFileData(pvDataObject);
      end;
    3:      //��ȡ�ļ���Ϣ
      begin
        self.readFileINfo(pvDataObject);
      end;
  end;
  
end;

class procedure TFileOperaHandler.FileDelete(pvDataObject: TJsonStream);
begin
  
end;

class function TFileOperaHandler.FileRename(pvSrcFile:String;
    pvNewFileName:string): Boolean;
var
  lvNewFile:String;
begin
  lvNewFile := ExtractFilePath(pvSrcFile) + ExtractFileName(pvNewFileName);
  Result := MoveFile(pchar(pvSrcFile), pchar(lvNewFile));
end;

class function TFileOperaHandler.getBasePath: String;
begin
   Result := TFrameConfig.getBasePath;
end;

class procedure TFileOperaHandler.readFileINfo(pvDataObject: TJsonStream);
const
  SEC_SIZE = 1024 * 4;
var
  lvFileStream:TFileStream;
  lvFileName, lvRealFileName:String;
  lvCrc, lvSize:Cardinal;
begin
  lvFileName:= getBasePath;
  if lvFileName = '' then
  begin
    raise Exception.Create('�����û���趨�ļ�������Ŀ¼!');
  end;

  lvFileName := lvFileName + '\' + pvDataObject.Json.S['fileName'];

  pvDataObject.Json.Delete('info');
  
  //ɾ��ԭ���ļ�
  if not FileExists(lvFileName) then
  begin
    pvDataObject.Json.I['info.exists'] := 0;  //������
    exit;
  end;

  pvDataObject.Json.I['info.size'] := BigFileSize(lvFileName);

end;

class procedure TFileOperaHandler.downFileData(pvDataObject:TJsonStream);
const
  SEC_SIZE = 1024 * 4;
var
  lvFileStream:TFileStream;
  lvFileName, lvRealFileName:String;
  lvCrc, lvSize:Cardinal;
begin
  lvFileName:= getBasePath;
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
    pvDataObject.Json.I['crc']:= TCRCTools.crc32Stream(pvDataObject.Stream);
  finally
    lvFileStream.Free;
  end;
  lvCrc := TCRCTools.crc32Stream(pvDataObject.Stream);
end;

class procedure TFileOperaHandler.uploadFileData(pvDataObject:TJsonStream);
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
  if FileExists(lvFileName) then SysUtils.DeleteFile(lvFileName);
  lvRealFileName := lvFileName;
  
  lvFileName := lvFileName + '.temp';

  //��һ����
  if pvDataObject.Json.I['start'] = 0 then
  begin
    if FileExists(lvFileName) then SysUtils.DeleteFile(lvFileName);
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
