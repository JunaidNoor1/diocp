unit qxml;

{$I 'qdac.inc'}
{
  ��Դ������QDAC��Ŀ����Ȩ��swish(QQ:109867294)���С�
  (1)��ʹ����ɼ�����
  ���������ɸ��ơ��ַ����޸ı�Դ�룬�������޸�Ӧ�÷��������ߣ������������ڱ�Ҫʱ��
�ϲ�������Ŀ���Թ�ʹ�ã��ϲ����Դ��ͬ����ѭQDAC��Ȩ�������ơ�
  ���Ĳ�Ʒ�Ĺ����У�Ӧ�������µİ汾����:
  ����Ʒʹ�õ�XML����������QDAC��Ŀ�е�QXML����Ȩ���������С�
  (2)������֧��
  �м������⣬�����Լ���QDAC�ٷ�QQȺ250530692��ͬ̽�֡�
  (3)������
  ����������ʹ�ñ�Դ�������Ҫ֧���κη��á���������ñ�Դ������а�������������
������Ŀ����ǿ�ƣ�����ʹ���߲�Ϊ�������ȣ��и���ľ���Ϊ�����ָ��õ���Ʒ��
  ������ʽ��
  ֧������ guansonghuan@sina.com �����������
  �������У�
    �����������
    �˺ţ�4367 4209 4324 0179 731
    �����У��������г����ŷ索����
}
//���Ի�����ΪDelphi 2007��XE6�������汾�Ŀ����������������޸�
{�޶���־
2014.5.14
=========
  + ����CopyIf/DeleteIf/FindIf����
  + ����for..in�﷨֧��

2014.5.6
========
  + ����ParseBlock����֧��
2014.5.1
========
  + ����AddRecord������֧��ֱ�ӱ����¼���ݣ����������͵ĳ�Ա�ᱻ����
    ����(Class)������(Method)���ӿ�(Interface)����������(ClassRef),ָ��(Pointer)������(Procedure)
    �������ܸ���ʵ����Ҫ�����Ƿ����֧��
  + ����ToRecord���������Jsonֱ�ӵ���¼���͵�ת��
  + ����Copy�������ڴ�����ǰ����һ������ʵ����ע��Ŀǰ�汾��¡�ڲ�������Copy�������������ܸĵ�
  * ������Assign������һ������
}
interface
uses classes,sysutils,qstring,typinfo,variants,qrbtree
  {$IFDEF QDAC_UNICODE}
  ,Generics.Collections,RegularExpressionsCore
  {$ENDIF}
  {$IFDEF QDAC_RTTI}
  ,Rtti
  {$ENDIF}
  ;

{$M+}
  ///����Ԫ��QDAC����ɲ��֣���QDAC��Ȩ���ƣ��������QDAC��վ�˽�
  /// <summary>
  /// XML������Ԫ�����ڿ��ٽ�����ά��XML�ṹ.ȫ�ֱ���XMLDateFormat��XMLDateTimeFormat
  /// Լ��������ʱ������ת��ΪXML����ʱ�����ݸ�ʽ
  /// QXML��������֧��DTD���壬������صĽ�����ԣ������XML�ļ�Ҳ�������DTD����
  /// </summary>
type
  TQXMLNode=class;
  PQXMLNode=^TQXMLNode;
  TQXMLAttr=class;
  PQXMLAttr=^TQXMLAttr;
  /// <summary>
  /// XML�����ඨ�壬���ڱ���һ��XML���Ե�ֵ
  /// </summary>
  TQXMLAttr=class
  private
    FName,FValue:QStringW;
    FNameHash:Integer;
    function GetAsInteger: Integer;
    procedure SetAsInteger(const Value: Integer);
    function GetAsInt64: Int64;
    procedure SetAsInt64(const Value: Int64);
    function GetAsFloat: Extended;
    procedure SetAsFloat(const Value: Extended);
    function GetAsBoolean: Boolean;
    procedure SetAsBoolean(const Value: Boolean);
    function GetAsDateTime: TDateTime;
    procedure SetAsDateTime(const Value: TDateTime);
    procedure SetName(const Value: QStringW);
  public
    /// <summary>��������</summary>
    property Name:QStringW read FName write SetName;
    /// <summary>����ֵ</summary>
    property Value:QStringW read FValue write FValue;
    /// <summary>���԰�����ֵ������ֵ����</summary>
    property AsInteger:Integer read GetAsInteger write SetAsInteger;
    /// <summary>������64λ������ʽ������ֵ����</summary>
    property AsInt64:Int64 read GetAsInt64 write SetAsInt64;
    /// <summary>�����Ը���������ʽ������ֵ����</summary>
    property AsFloat:Extended read GetAsFloat write SetAsFloat;
    /// <summary>�������ַ�������ʽ������ֵ���ݣ��ȼ��ڷ���Value)
    property AsString:QStringW read FValue write FValue;
    /// <summary>�����Բ�������ʽ����ֵ����
    property AsBoolean:Boolean read GetAsBoolean write SetAsBoolean;
    /// <summary>����������ʱ�����ͷ�������
    property AsDateTime:TDateTime read GetAsDateTime write SetAsDateTime;
  end;
  {$IFDEF QDAC_UNICODE}
  TQXMLAttrList=TList<TQXMLAttr>;
  {$ELSE}
  TQXMLAttrList=TList;
  {$ENDIF !QDAC_UNICODE}
  TQXMLAttrEnumerator=class;
  /// <summary>XML�����б��ڲ�ʹ��</summary>
  TQXMLAttrs=class
  private
    FItems:TQXMLAttrList;
    FOwner:TQXMLNode;
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQXMLAttr;
  public
    /// <summary>����һ��XML�����б�</summary>
    ///  <param name="AOwner">��������XML���</param>
    constructor Create(AOwner:TQXMLNode);overload;
    /// <summary>����һ��XML���Ե�����</summary>
    procedure Assign(ASource:TQXMLAttrs);
    /// <summary>���һ��XML����</summary>
    ///  <param name="AName">Ҫ��ӵ�XML��������</param>
    ///  <returns>������ӵ�XML���Զ���
    function Add(const AName:QStringW):TQXMLAttr;overload;
    /// <summary>���һ��XML���Ե�ֵ</summary>
    ///  <param name="AName">��������</param>
    ///  <param name="AValue">����ֵ</param>
    ///  <returns>������ӵ�XML���Ե�����</returns>
    ///  <remarks>QXML������Ƿ��ظ��������ȷ���Ƿ��Ѵ��ڣ������ǰ������
    /// ItemByName��IndexByName������Ƿ��������
    function Add(const AName,AValue:QStringW):Integer;overload;
    /// <summary>����ָ�����Ƶ�����</summary>
    /// <param name="AName">Ҫ���ҵ���������</param>
    /// <returns>�����ҵ������Զ���</returns>
    function ItemByName(const AName:QStringW):TQXMLAttr;
    /// <summary>��ȡָ�����Ƶ����Ե�������</summary>
    /// <param name="AName">Ҫ���ҵ���������</param>
    /// <returns>�����ҵ������Ե����������δ�ҵ�������-1</returns>
    function IndexOfName(const AName:QStringW):Integer;
    /// <summary>��ȡָ�����Ƶ����Ե�ֵ</summary>
    /// <param name="AName">��������</param>
    /// <param name="ADefVal">������Բ����ڣ����ص�Ĭ��ֵ</param>
    /// <returns>�����ҵ������Ե�ֵ�����δ�ҵ�������ADefVal������ֵ</returns>
    function ValueByName(const AName:QStringW;const ADefVal:QStringW=''):QStringW;
    /// <summary>ɾ��ָ������������ֵ</summary>
    /// <param name="AIndex">��������</param>
    procedure Delete(AIndex:Integer);overload;
    /// <summary>ɾ��ָ�����Ƶ�����ֵ</summary>
    /// <param name="AName">��������</param>
    /// <remarks>��������������ԣ�ֻ��ɾ����һ���ҵ�������</remarks>
    procedure Delete(AName:QStringW);overload;
    /// <summary>������е�����</summary>
    procedure Clear;
    /// <summary>��������</summary>
    destructor Destroy;override;
    /// <summary>for..in֧�ֺ���</summary>
    function GetEnumerator:TQXMLAttrEnumerator;
    /// <summary>���Ը���</summary>
    property Count:Integer read GetCount;
    /// <summary>�����б�</summary>
    property Items[AIndex:Integer]:TQXMLAttr read GetItems;default;
    /// <summary>���������߽��</summary>
    property Owner:TQXMLNode read FOwner;
  end;

  TQXMLAttrEnumerator=class
  private
    FIndex: Integer;
    FList: TQXMLAttrs;
  public
    constructor Create(AList: TQXMLAttrs);
    function GetCurrent: TQXMLAttr; inline;
    function MoveNext: Boolean;
    property Current: TQXMLAttr read GetCurrent;
  end;
  /// <summary>XML�������<summary>
  ///  <list>
  ///  <item><term>xntNode</term><description>��ͨ���</description></item>
  ///  <item><term>xntText</term><description>�ı�����</description></item>
  ///  <item><term>xntComment</term><description>ע��</description></item>
  ///  <item><term>xntCData</term><description>CDATA</description></item>
  ///  </list>
  TQXMLNodeType=(xntNode,xntText,xntComment,xntCData);
  {$IFDEF QDAC_UNICODE}
  TQXMLNodeList=TList<TQXMLNode>;
  {$IFDEF QDAC_RTTI}
  TQXMLRttiFilterEventA=reference to procedure (ASender:TQXMLNode;AObject:Pointer;AName:QStringW;AType:PTypeInfo;var Accept:Boolean;ATag:Pointer);
  /// <summary>
  /// �����˴�����������XE6��֧����������
  /// </summary>
  /// <param name="ASender">�����¼���TQJson����</param>
  /// <param name="AItem">Ҫ���˵Ķ���</param>
  /// <param name="Accept">�Ƿ�Ҫ����ö���</param>
  /// <param name="ATag">�û����ӵ�������</param>
  TQXMLFilterEventA=reference to procedure(ASender,AItem:TQXMLNode;var Accept:Boolean;ATag:Pointer);

  {$ENDIF QDAC_RTTI}
  {$ELSE}
  TQXMLNodeList=TList;
  {$ENDIF QDAC_UNICODE}
  TQXMLRttiFilterEvent=procedure (ASender:TQXMLNode;AObject:Pointer;AName:QStringW;AType:PTypeInfo;var Accept:Boolean;ATag:Pointer) of object;
  TQXMLFilterEvent=reference to procedure(ASender,AItem:TQXMLNode;var Accept:Boolean;ATag:Pointer);

  /// <summary>
  ///   AddObject/AddRecordʱ�ڲ�����ʱʹ�ø��ӵ�Tag���ͣ��������ڲ�ʹ��
  /// </summary>
  TQXMLTagType=(ttAnonEvent,ttNameFilter);
  /// <summary>�ڲ�ʹ�õı�����ݶ���</summary>
  PQXMLInternalTagData=^TQXMLInternalTagData;
  /// <summary>�ڲ�ʹ�õı�����ݶ���</summary>
  TQXMLInternalTagData=record
    /// <summary>Tag���ݵ�����</summary>
    TagType:TQXMLTagType;
    {$IFDEF QDAC_RTTI}
    /// <summary>����ʹ�õ���������</summary>
    OnEvent:TQXMLRttiFilterEventA;
    {$ENDIF}
    /// <summary>���ܵ�����(AddObject)���¼�ֶ�(AddRecord)���ƣ��������ͬʱ��IgnoreNames���֣���IgnoreNames�����Ϣ������</summary>
    AcceptNames:QStringW;
    /// <summary>���Ե�����(AddObject)���¼�ֶ�(AddRecord)���ƣ��������ͬʱ��AcceptNameds���AcceptNames����</summary>
    IgnoreNames:QStringW;
    /// <summary>ԭʼ���ݸ�AddObject��AddRecord�ĸ������ݳ�Ա�����������ݸ�OnEvent��Tag���Թ��û�ʹ��</summary>
    Tag:Pointer;
  end;
  TQXMLNodeEnumerator=class
  private
    FIndex: Integer;
    FList: TQXMLNode;
  public
    constructor Create(AList: TQXMLNode);
    function GetCurrent: TQXMLNode; inline;
    function MoveNext: Boolean;
    property Current: TQXMLNode read GetCurrent;
  end;
  ///<summary>�����ⲿ֧�ֶ���صĺ���������һ���µ�TQXMLNode����ע��ӳ��д����Ķ���</summary>
  ///  <returns>�����´�����QXMLNode����</returns>
  TQXMLCreateNode=function:TQXMLNode;
  ///<summary>�����ⲿ�����󻺴棬�Ա����ö���</summary>
  ///  <param name="ANode">Ҫ�ͷŵ�tQXMLNode����</param>
  TQXMLFreeNode=procedure (ANode:TQXMLNode);
  /// <summary>
  ///  TQXMLNode���ڽ�����ά��XML��ʽ���ݣ�Ҫʹ��ǰ����Ҫ���ڶ��д�����Ӧ��ʵ����
  ///  TQJson��TQXML�ھ�������ӿ��ϱ���һ�£�������Json����������Ϣ����XMLû������
  ///  ��Ϣ��ʼ����Ϊ���ַ�����������ٲ��ֽӿڻ����в�ͬ.
  ///  ������ʵ�ֲ�ͬ��QXMLû����ν���ĵ�����Ҳû����νһ���������ֻ����һ�����
  ///  �����ƣ��������������ж���ӽ�㣬�ڱ��浽�ļ�������ʱ����������û������
  ///  ����Զ�����һ��<xml></xml>������Ա�֤���ɵ��ļ�����XML��׼Ҫ��
  ///  ��������Ϊ���������ĵ���������һ����㶼����ֱ�Ӵ��ļ������м������ݣ�
  ///  ���߱��浽�ļ������С�
  /// </summary>
  TQXMLNode=class
  private
    FAttrs:TQXMLAttrs;
    FItems:TQXMLNodeList;
    FNodeType: TQXMLNodeType;
    FParent: TQXMLNode;
    FName: QStringW;
    FNameHash:Integer;//���ƵĹ�ϣֵ
    FData: Pointer;
    function GetCount: Integer;
    function GetItems(AIndex: Integer): TQXMLNode;
    function XMLEncode(const S:QStringW):QStringW;
    function XMLDecode(const S:QStringW):QStringW;overload;
    function XMLDecode(const p:PQCharW;l:Integer):QStringW;overload;
    function GetItemIndex: Integer;
    function GetText: QStringW;
    procedure SetText(const Value: QStringW);
    procedure SetName(const Value: QStringW);
    function GetAttrs: TQXMLAttrs;
    function GetPath: QStringW;
    function GetCapacity: Integer;
    procedure SetCapacity(const Value: Integer);
    function InternalEncode(ABuilder:TQStringCatHelperW;ADoFormat:Boolean;const AIndent:QStringW):TQStringCatHelperW;
    function GetName: QStringW;
    procedure InternalRttiFilter(ASender:TQXMLNode;AObject:Pointer;APropName:QStringW;APropType:PTypeInfo;var Accept:Boolean;ATag:Pointer);
    function InternalAddObject(AName: QStringW; AObject: TObject;
      AOnFilter: TQXMLRttiFilterEvent;ANest: Boolean;
      ATag: Pointer): TQXMLNode;
    function GetAsXML: QStringW;
    procedure SetAsXML(const Value: QStringW);
    procedure DoParse(p:PQCharW);
    procedure SetNodeType(const Value: TQXMLNodeType);
    function CreateNode:TQXMLNode;virtual;
    procedure FreeNode(ANode:TQXMLNode);inline;
    {$IFDEF QDAC_RTTI}
    function InternalAddRecord(ATypeInfo: PTypeInfo; ABaseAddr: Pointer;
      AOnFilter: TQXMLRttiFilterEvent; ATag: Pointer): Boolean;
    procedure InternalToRecord(ATypeInfo:PTypeInfo;ABaseAddr:Pointer);
    {$ENDIF}
  public
    /// <summary>���캯��</summary>
    constructor Create;overload;
    /// <summary>��������</summary>
    destructor Destroy;override;
    /// <summary>ֵ��������</summary>
    procedure Assign(ANode:TQXMLNode);
    /// <summary>���һ��δ�������</summary>
    /// <remarks>����������һ��δ������㣬����ʱ���ý��㼶�������Զ�ֱ�ӱ�����һ��</remarks>
    function Add: TQXMLNode;overload;
    /// <summary>���һ����㡢�ı���ע�ͻ�CData</summary>
    ///  <param name="AName_Text">���ƻ����ݣ�����ȡ����AType����</param>
    ///  <returns>������ӵĽ��ʵ��</returns>
    function Add(const AName_Text:QStringW;AType:TQXMLNodeType=xntNode):TQXMLNode;overload;
    /// <summary>���һ�����</summary>
    /// <param name="AName">�������</param>
    ///  <returns>������ӵĽ��ʵ��</returns>
    /// <remarks>�ȼ��ڵ���Add(AName,xntNode)</remarks>
    function AddNode(const AName:QStringW):TQXMLNode;virtual;
    /// <summary>���һ���ı����</summary>
    /// <param name="AText">Ҫ��ӵ��ı�����</param>
    /// <returns>������ӵĽ��ʵ��</returns>
    /// <remarks>�ȼ��ڵ���Add(AText,xntText)</remarks>
    function AddText(const AText:QStringW):TQXMLNode;
    /// <summary>���һ��ע��</summary>
    /// <param name="AText">Ҫ��ӵ�ע�����ݣ����ܰ���--&gt;</param>
    /// <returns>������ӵĽ��ʵ��</returns>
    /// <remarks>�ȼ��ڵ���Add(AText,xntComment)</remarks>
    function AddComment(const AText:QStringW):TQXMLNode;
    /// <summary>���һ��ע��</summary>
    /// <param name="AText">Ҫ��ӵ�CData�����ܰ���]]&gt;</param>
    /// <returns>������ӵĽ��ʵ��</returns>
    /// <remarks>�ȼ��ڵ���Add(AText,xntCData)</remarks>
    function AddCData(const AText:QStringW):TQXMLNode;
    {$IFDEF QDAC_RTTI}
    /// <summary>���һ�����󵽵�ǰ���</summary>
    ///  <param name="AName">Ҫ��ӵĶ���������</param>
    ///  <param name="AObject">Ҫ��ӵĶ���</param>
    ///  <param name="AOnFilter">ָ�����Թ����¼����Թ��˵�����Ҫת��������</param>
    ///  <param name="ANest">������Ե��Ƕ����Ƿ�ݹ�</param>
    ///  <param name="ATag">���ӵ����ݳɹ��������¼��ص����û��Լ�����;</param>
    function AddObject(AName:QStringW;AObject:TObject;AOnFilter:TQXMLRttiFilterEventA;ANest:Boolean;ATag:Pointer=nil):TQXMLNode;overload;
    /// ���һ����¼���ṹ�壩����ǰ���
    /// <param name="AName">Ҫ��ӵĶ���Ľ������</param>
    /// <param name="AObject">Ҫ��ӵļ�¼ʵ��</param>
    /// <returns>���ش����Ľ��ʵ��</returns>
    /// <remarks>
    function AddRecord<T>(AName:QStringW;const AObject:T;AcceptFields,AIgnoreFields:QStringW):TQXMLNode;overload;
    /// ���һ����¼���ṹ�壩����ǰ���
    /// <param name="AName">Ҫ��ӵĶ���Ľ������</param>
    /// <param name="AObject">Ҫ��ӵĶ���ʵ��</param>
    /// <returns>���ش����Ľ��ʵ��</returns>
    function AddRecord<T>(AName:QStringW;const AObject:T):TQXMLNode;overload;
    /// ���һ����¼���ṹ�壩����ǰ���
    /// <param name="AName">Ҫ��ӵĶ���Ľ������</param>
    /// <param name="AObject">Ҫ��ӵĶ���ʵ��</param>
    /// <param name="AOnFilter">ָ�����Թ����¼����Թ��˵�����Ҫת��������</param>
    /// <param name="ATag">���ӵ����ݳɹ��������¼��ص����û��Լ�����;</param>
    /// <returns>���ش����Ľ��ʵ��</returns>
    function AddRecord<T>(AName:QStringW;const AObject:T;AOnFilter:TQXMLRttiFilterEvent;ATag:Pointer):TQXMLNode;overload;
    /// ���һ����¼���ṹ�壩��Json��
    /// <param name="AName">Ҫ��ӵĶ���Ľ������</param>
    /// <param name="AObject">Ҫ��ӵĶ���ʵ��</param>
    /// <param name="AOnFilter">ָ�����Թ����¼����Թ��˵�����Ҫת��������</param>
    /// <param name="ATag">���ӵ����ݳɹ��������¼��ص����û��Լ�����;</param>
    /// <returns>���ش����Ľ��ʵ��</returns>
    function AddRecord<T>(AName:QStringW;const AObject:T;AOnFilter:TQXMLRttiFilterEventA;ATag:Pointer):TQXMLNode;overload;
    {$ENDIF}
    /// <summary>���һ�����󵽽��</summary>
    ///  <param name="AName">Ҫ��ӵĶ���������</param>
    ///  <param name="AObject">Ҫ��ӵĶ���</param>
    ///  <param name="AOnFilter">ָ�����Թ����¼����Թ��˵�����Ҫת��������</param>
    ///  <param name="ANest">������Ե��Ƕ����Ƿ�ݹ�</param>
    ///  <param name="ATag">���ӵ����ݳɹ��������¼��ص����û��Լ�����;</param>
    /// <returns>������ӵĽ��</returns>
    function AddObject(AName:QStringW;AObject:TObject;AOnFilter:TQXMLRttiFilterEvent;ANest:Boolean;ATag:Pointer=nil):TQXMLNode;overload;
    /// <summary>���һ������Json����</summary>
    ///  <param name="AName">Ҫ��ӵĶ���������</param>
    ///  <param name="AObject">Ҫ��ӵĶ���</param>
    ///  <param name="AcceptProps">������������/param>
    ///  <param name="AIgnoreProps">���Բ����������</param>
    /// <returns>������ӵĽ��</returns>
    function AddObject(AName:QStringW;AObject:TObject;ANest:Boolean;AcceptProps,AIgnoreProps:QStringW):TQXMLNode;overload;
    /// <summary>��ȡָ�����Ƶĵ�һ�����</summary>
    /// <param name="AName">�������</param>
    /// <returns>�����ҵ��Ľ�㣬���δ�ҵ������ؿ�(NULL/nil)</returns>
    /// <remarks>ע��XML������������ˣ�������������Ľ�㣬ֻ�᷵�ص�һ�����</remarks>
    function ItemByName(const AName:QStringW):TQXMLNode;overload;
    /// <summary>��ȡָ�����ƵĽ�㵽�б���</summary>
    /// <param name="AName">�������</param>
    ///  <param name="AList">���ڱ�������б����</param>
    ///  <param name="ANest">�Ƿ�ݹ�����ӽ��</param>
    /// <returns>�����ҵ��Ľ�����������δ�ҵ�������0</returns>
    function ItemByName(const AName:QStringW;AList:TQXMLNodeList;ANest:Boolean=False):Integer;overload;
    /// <summary>��ȡָ��·����JSON����</summary>
    ///  <param name="APath">·������"."��"/"��"\"�ָ�</param>
    ///  <returns>�����ҵ����ӽ�㣬���δ�ҵ�����NULL(nil)</returns>
    function ItemByPath(const APath:QStringW):TQXMLNode;
    /// <summary>��ȡ����ָ�����ƹ���Ľ�㵽�б���</summary>
    /// <param name="ARegex">������ʽ</param>
    ///  <param name="AList">���ڱ�������б����</param>
    ///  <param name="ANest">�Ƿ�ݹ�����ӽ��</param>
    /// <returns>�����ҵ��Ľ�����������δ�ҵ�������0</returns>
    function ItemByRegex(const ARegex:QStringW;AList:TQXMLNodeList;ANest:Boolean=False):Integer;overload;
    /// <summary>��ȡָ��·�������ı�����</summary>
    /// <param name="APath">·������"."��"/"��"\"�ָ�</param>
    /// <param name="ADefVal">��·�������ڣ����ص�Ĭ��ֵ</param>
    /// <returns>����ҵ���㣬�����ҵ��Ľ����ı����ݣ����򷵻�ADefVal������ֵ</returns>
    /// <remarks>
    function TextByPath(const APath,ADefVal:QStringW):QStringW;

    function ItemWithAttrValue(const APath:QStringW;const AttrName,AttrValue:QStringW):TQXMLNode;
    /// <summary>��ȡָ��·������ָ������</summary>
    /// <param name="APath">·������"."��"/"��"\"�ָ�</param>
    /// <param name="AttrName">��������</param>
    /// <returns>����ҵ������Ӧ�����ԣ������ҵ������ԣ����򷵻�NULL/nil</returns>
    /// <remarks>
    function AttrByPath(const APath,AttrName:QStringW):TQXMLAttr;
    /// <summary>��ȡָ��·������ָ������ֵ</summary>
    /// <param name="APath">·������"."��"/"��"\"�ָ�</param>
    /// <param name="AttrName">��������</param>
    /// <param name="ADefVal">��·�������ڣ����ص�Ĭ��ֵ</param>
    /// <returns>����ҵ������Ӧ�����ԣ������ҵ������Ե��ı����ݣ����򷵻�ADefVal������ֵ</returns>
    /// <remarks>
    function AttrValueByPath(const APath,AttrName,ADefVal:QStringW):QStringW;

    /// <summary>ǿ��һ��·������,���������,�����δ�����Ҫ�Ľ��</summary>
    /// <param name="APath">Ҫ��ӵĽ��·��</param>
    /// <returns>����·����Ӧ�Ķ���</returns>
    function ForcePath(APath:QStringW):TQXMLNode;
    /// <summary>����Ϊ�ַ���</summary>
    /// <param name="ADoFormat">�Ƿ��ʽ���ַ����������ӿɶ���</param>
    /// <param name="AIndent">ADoFormat����ΪTrueʱ���������ݣ�Ĭ��Ϊ�����ո�</param>
    /// <returns>���ر������ַ���</returns>
    ///  <remarks>AsXML�ȼ���Encode(True,'  ')</remarks>
    function Encode(ADoFormat:Boolean;AIndent:QStringW='  '):QStringW;
    /// <summary>��������һ���µ�ʵ��</summary>
    /// <returns>�����µĿ���ʵ��</returns>
    /// <remarks>��Ϊ�ǿ����������¾ɶ���֮������ݱ��û���κι�ϵ����������һ��
    ///  ���󣬲��������һ���������Ӱ�졣
    ///  </remarks>
    function Copy:TQXMLNode;
    {$IFDEF QDAC_RTTI}
    function CopyIf(const ATag:Pointer;AFilter:TQXMLFilterEventA):TQXMLNode;overload;
    {$ENDIF}
    function CopyIf(const ATag:Pointer;AFilter:TQXMLFilterEvent):TQXMLNode;overload;
    /// <summary>��¡����һ���µ�ʵ��</summary>
    /// <returns>�����µĿ���ʵ��</returns>
    /// <remarks>��Ϊʵ����ִ�е��ǿ����������¾ɶ���֮������ݱ��û���κι�ϵ��
    ///  ��������һ�����󣬲��������һ���������Ӱ�죬������Ϊ����������֤������
    ///  �����Ϊ���ã��Ա��໥Ӱ�졣
    ///  </remarks>
    function Clone:TQXMLNode;
    /// <summary>ɾ��ָ�������Ľ��</summary>
    /// <param name="AIndex">Ҫɾ���Ľ������</param>
    /// <remarks>
    /// ���ָ�������Ľ�㲻���ڣ����׳�EOutRange�쳣
    /// </remarks>
    procedure Delete(AIndex:Integer);overload;virtual;
    {$IFDEF QDAC_RTTI}
    ///<summary>
    /// ɾ�������������ӽ��
    ///</summary>
    ///  <param name="ATag">�û��Լ����ӵĶ�����</param>
    ///  <param name="ANest">�Ƿ�Ƕ�׵��ã����Ϊfalse����ֻ�Ե�ǰ�ӽ�����</param>
    ///  <param name="AFilter">���˻ص����������Ϊnil���ȼ���Clear</param>
    procedure DeleteIf(const ATag:Pointer;ANest:Boolean;AFilter:TQXMLFilterEventA);overload;
    {$ENDIF QDAC_RTTI}
    ///<summary>
    /// ɾ�������������ӽ��
    ///</summary>
    ///  <param name="ATag">�û��Լ����ӵĶ�����</param>
    ///  <param name="ANest">�Ƿ�Ƕ�׵��ã����Ϊfalse����ֻ�Ե�ǰ�ӽ�����</param>
    ///  <param name="AFilter">���˻ص����������Ϊnil���ȼ���Clear</param>
    procedure DeleteIf(const ATag:Pointer;ANest:Boolean;AFilter:TQXMLFilterEvent);overload;

    /// <summary>ɾ��ָ�����ƵĽ��</summary>
    ///  <param name="AName">Ҫɾ���Ľ������</param>
    ///  <param name="ADeleteAll">�Ƿ�ɾ��ȫ��ͬ���Ľ��</param>
    procedure Delete(AName:QStringW;ADeleteAll:Boolean=True);overload;
    /// <summary>����ָ�����ƵĽ�������</summary>
    ///  <param name="AName">Ҫ���ҵĽ������</param>
    ///  <returns>��������ֵ��δ�ҵ�����-1</returns>
    function IndexOf(const AName:QStringW):Integer;virtual;
    {$IFDEF QDAC_RTTI}
    ///<summary>���������ҷ��������Ľ��</summary>
    /// <param name="ATag">�û��Զ���ĸ��Ӷ�����</param>
    ///  <param name="ANest">�Ƿ�Ƕ�׵��ã����Ϊfalse����ֻ�Ե�ǰ�ӽ�����</param>
    ///  <param name="AFilter">���˻ص����������Ϊnil���򷵻�nil</param>
    function FindIf(const ATag:Pointer;ANest:Boolean;AFilter:TQXMLFilterEventA):TQXMLNode;overload;
    {$ENDIF QDAC_RTTI}
    ///<summary>���������ҷ��������Ľ��</summary>
    /// <param name="ATag">�û��Զ���ĸ��Ӷ�����</param>
    ///  <param name="ANest">�Ƿ�Ƕ�׵��ã����Ϊfalse����ֻ�Ե�ǰ�ӽ�����</param>
    ///  <param name="AFilter">���˻ص����������Ϊnil���򷵻�nil</param>
    function FindIf(const ATag:Pointer;ANest:Boolean;AFilter:TQXMLFilterEvent):TQXMLNode;overload;

    /// <summary>������еĽ��</summary>
    procedure Clear;virtual;
    /// <summary>����ָ����XML�ַ���</summary>
    /// <param name="p">Ҫ�������ַ���</param>
    /// <param name="l">�ַ������ȣ�<=0��Ϊ����\0(#0)��β��C���Ա�׼�ַ���</param>
    /// <remarks>���l>=0������p[l]�Ƿ�Ϊ\0�������Ϊ\0����ᴴ������ʵ������������ʵ��</remarks>
    procedure Parse(p:PQCharW;len:Integer=-1);overload;
    /// <summary>����ָ����JSON�ַ���</summary>
    /// <param name='s'>Ҫ������JSON�ַ���</param>
    procedure Parse(const s:QStringW);overload;
    /// <summmary>�����н����׸�XML���</summary>
    ///  <param name="AStream">������</param>
    ///  <param name="AEncoding">�����ݵı��뷽ʽ</param>
    /// <remarks>ParseBlock�ʺϽ����ֶ�ʽXML������ӵ�ǰλ�ÿ�ʼ����������ǰ�������Ϊֹ.
    ///  ���Ժܺõ����㽥��ʽ�������Ҫ</remarks>
    procedure ParseBlock(AStream:TStream;AEncoding:TTextEncoding);
    /// <summary>��ָ�����ļ��м��ص�ǰ����</summary>
    ///  <param name="AFileName">Ҫ���ص��ļ���</param>
    ///  <param name="AEncoding">Դ�ļ����룬���ΪteUnknown�����Զ��ж�</param>
    procedure LoadFromFile(AFileName:QStringW;AEncoding:TTextEncoding=teUnknown);
    /// <summary>�����ĵ�ǰλ�ÿ�ʼ����JSON����</summary>
    ///  <param name="AStream">Դ������</param>
    ///  <param name="AEncoding">Դ�ļ����룬���ΪteUnknown�����Զ��ж�</param>
    ///  <remarks>���ĵ�ǰλ�õ������ĳ��ȱ������2�ֽڣ�����������</remarks>
    procedure LoadFromStream(AStream:TStream;AEncoding:TTextEncoding=teUnknown);
    /// <summary>���浱ǰ�������ݵ��ļ���</summary>
    ///  <param name="AFileName">�ļ���</param>
    ///  <param name="AEncoding">�����ʽ</param>
    ///  <param name="AWriteBOM">�Ƿ�д��UTF-8��BOM</param>
    ///  <remarks>ע�⵱ǰ�������Ʋ��ᱻд��</remarks>
    procedure SaveToFile(AFileName:QStringW;AEncoding:TTextEncoding=teUTF8;AWriteBom:Boolean=False);
    /// <summary>���浱ǰ�������ݵ�����</summary>
    ///  <param name="AStream">Ŀ��������</param>
    ///  <param name="AEncoding">�����ʽ</param>
    ///  <param name="AWriteBom">�Ƿ�д��BOM</param>
    ///  <remarks>ע�⵱ǰ�������Ʋ��ᱻд��</remarks>
    procedure SaveToStream(AStream:TStream;AEncoding:TTextEncoding=teUTF8;AWriteBom:Boolean=False);
    /// <summary>����TObject.ToString����</summary>
    function ToString: string;{$IFDEF QDAC_UNICODE}override;{$ENDIF}
    /// ��XML�����ݻ�ԭ��ԭ���Ķ�������
    procedure ToObject(AObject:TObject);
    {$IFDEF QDAC_RTTI}
    /// <summary>��Json�����ݻ�ԭ��ԭ���Ľṹ�壨��¼���ֶ�ֵ</summary>
    /// <param name="ARecord">Ŀ��ṹ��ʵ��</param>
    procedure ToRecord<T>(const ARecord:T);
    {$ENDIF QDAC_RTTI}
    /// <summary>for..in֧�ֺ���</summary>
    function GetEnumerator:TQXMLNodeEnumerator;
    ///<summary>�ӽ������</<summary>summary>
    property Count:Integer read GetCount;
    ///<summary>�ӽ������</summary>
    property Items[AIndex:Integer]:TQXMLNode read GetItems;default;
    ///<summary>����ĸ������ݳ�Ա�����û�������������</summary>
    property Data:Pointer read FData write FData;
    ///<summary>����·�����м���"\"�ָ�</summary>
    property Path:QStringW read GetPath;
    ///<summary>����ڸ�����ϵ�����������Լ��Ǹ���㣬�򷵻�-1</summary>
    property ItemIndex:Integer read GetItemIndex;
    /// <summary>�����</summary>
    property Parent:TQXMLNode read FParent write FParent;
  published
    ///<summary>�������</summary>
    property Name:QStringW read GetName write SetName;
    ///<summary>���Ĵ��ı����ݣ�����ע�ͣ�ֻ����Text��CDATA)</summary>
    property Text:QStringW read GetText write SetText;
    ///<summary>�������</summary>
    property NodeType:TQXMLNodeType read FNodeType write SetNodeType;
     ///<summary>�����б�</summary>
    property Attrs:TQXMLAttrs read GetAttrs;
    ///<summary>�б�����</summary>
    property Capacity:Integer read GetCapacity write SetCapacity;
    ///<summary>����XML��ʽ������</summary>
    property AsXML:QStringW read GetAsXML write SetAsXML;
  end;

  TQHashedXMLNode=class(TQXMLNode)
  protected
    FHashTable:TQHashTable;
    function CreateNode:TQXMLNode;override;
  public
    constructor Create;overload;
    destructor Destroy;override;
    function AddNode(const AName:QStringW):TQXMLNode;override;
    function IndexOf(const AName:QStringW):Integer;override;
    procedure Delete(AIndex:Integer);override;
    procedure Clear;override;
  end;
var
  /// ����ʱ������ת��ΪJson����ʱ��ת�����ַ���������������������θ�ʽ��
  XMLDateFormat,XMLDateTimeFormat,XMLTimeFormat:QStringW;
  /// ��ItemByName/ItemByPath/ValueByName/ValueByPath�Ⱥ������ж��У��Ƿ��������ƴ�Сд
  XMLCaseSensitive:Boolean;
  /// ǿ�Ʊ���ʱXML�ڵ����Ʊ�����Գ���,���ΪTrue���������Ӧ�Ľ��û���ӽ��ʱ����
  ///  ֱ����/>��β�����ΪFalse�����ǿ����Գ���
  XMLTagShortClose:Boolean;
  /// ����Ҫ�½�һ��TQXMLNode����ʱ����
  OnQXMLNodeCreate:TQXMLCreateNode;
  /// ����Ҫ�ͷ�һ��TQXMLNode����ʱ����
  OnQXMLNodeFree:TQXMLFreeNode;
implementation
uses math;

resourcestring
  SNodeWithoutName='ָ���Ľ������δָ�����޷�����XML���ݡ�';
  SBadXMLName='��Ч��XML������ƣ����Ʋ��������ֻ�xml��ͷ��Ҳ���ܰ����հ׻���Ʒ���';
  SBadXMLComment='��Ч��XMLע�ͣ�ע���в��ܰ�����--����';
  SUnterminateXMLComment='δ������XMLע�ͣ�';
  SBadXMLCData='��Ч��CData���ݣ�CData�����в��ܳ��֡�]]>����';
  SUnterminateXMLCData='δ������CDATA��ǣ�';
  SBadXMLEncoding='��Ч��XML���ݱ��룬QXMLֻ֧��UTF-8��UTF-16���롣';
  SXMLBadAttrValue='��Ч��XML����ֵ������ֵ����ʹ�����Ű�����';
  SXMLAttrValueMissed='δ�ҵ�XML����ֵ���塣';
  SUnterminatedXMLTag='δ������XML��ǩ���塣';
  SUnclosedXMLTag='δ�رյ�XML��ǩ���塣';
  SBadXMLEscape='��Ч��XMLת�����ж��塣';
  SNotSupport='��֧�ֵĺ���[%s]';
  SUnknownXMLEscape='δ֪��XMLת���ַ���[%s]��';
  SXMLNameNotSupport='��ǰ������Ͳ�֧�����ơ�';
  SValueNotNumeric='�ַ��� %s ������Ч����ֵ��';
  SValueNotBoolean='�ַ��� %s ������Ч�Ĳ���ֵ��';
  SValueNotDateTime='�ַ��� %s ������Ч������ʱ��ֵ��';
  SBadXMLTagStart='XML�ĵ���Ҫ��<��ʼһ��������ơ�';
  SXMLNameNeeded='XML����ڱ���ǰ����ָ��һ�����ơ�';
{ TQXMLAttrs }
{
�����е�λ��	 ������ַ�
�κ�λ��
["A"-"Z"]��["a"-"z"]��"_"��[0x00C0-0x02FF]��[0x0370-0x037D]��[0x037F-0x1FFF]��[0x200C-0x200D]��
[0x2070-0x218F]��[0x2C00-0x2FEF]��[0x3001-0xD7FF]��[0xF900-0xEFFF]
����һ��λ��֮����κ�λ��
"-"��"."��["0"-"9"]��0x00B7��[0x0300-0x036F]��[0x203F-0x2040]
Ԫ�ػ��������ƣ��ܹ�����ͼ�еĽڵ����ƣ���Ӣ�ı�ʾ�����ʵ���ɸ���Ϊ���¼��㣺
ʹ����ĸ�����ַ��������Ʋ�Ҫ�����ֿ�ͷ��

ʹ���»��� (_)�����ַ� (-)����� (.) ���м�� (��)��

��Ҫʹ�ÿո�

ʹ������Ȼ���Ա�ʾ�������嵥�ʻ򵥴ʵ���ϡ�
}
function ValidXMLName(const S:QStringW):Boolean;
var
  p:PQCharW;
  function InRange(const c,cmin,cmax:QCharW):Boolean;inline;
  begin
  Result:=(c>=cmin) and (c<=cmax);
  end;
begin
p:=PQCharW(S);
if InRange(p^,'A','Z') or InRange(p^,'a','z') or (p^='_') or
  InRange(p^,#$00C0,#$02FF) or InRange(p^,#$0370,#$037D) or
  InRange(p^,#$037F,#$1FFF) or InRange(p^,#$200C,#$200D) or
  InRange(p^,#$2070,#$218F) or InRange(p^,#$2C00,#$2FEF) or
  InRange(p^,#$3001,#$D7FF) or InRange(p^,#$F900,#$EFFF) then
  begin
  Inc(p);
  while p^<>#0 do
    begin
    if InRange(p^,'A','Z') or InRange(p^,'a','z') or
      InRange(p^,'0','9') or (p^='_') or (p^='-') or
      (p^='.') or (p^=':') or (p^=#$00B7) or
      InRange(p^,#$00C0,#$02FF) or InRange(p^,#$0300,#$037D) or
      InRange(p^,#$037F,#$1FFF) or InRange(p^,#$200C,#$200D) or
      InRange(p^,#$203F,#$2040) or InRange(p^,#$2070,#$218F) or
      InRange(p^,#$2C00,#$2FEF) or InRange(p^,#$3001,#$D7FF) or
      InRange(p^,#$F900,#$EFFF) then
      Inc(p)
    else
      Break;
    end;
  Result:=(p^=#0);
  end
else
  Result:=False;
end;

function ValidXMLComment(const Value:QStringW):Boolean;
var
  ps:PQCharW;
begin
ps:=PQCharW(Value);
Result:=True;
while ps^<>#0 do
  begin
  if (ps[0]='-') and (ps[1]='-') then
    begin
    Result:=False;
    Break;
    end
  else
    Inc(ps);
  end;
end;

function ValidXMLCData(const Value:QStringW):Boolean;
var
  ps:PQCharW;
begin
ps:=PQCharW(Value);
Result:=True;
while ps^<>#0 do
  begin
  //CDATA�ﲻ�ܳ���]]>��
  if (ps[0]=']') and (ps[1]=']') and (ps[2]='>') then
    begin
    Result:=False;
    Break;
    end
  else
    Inc(ps);
  end;
end;

function TQXMLAttrs.Add(const AName, AValue: QStringW): Integer;
var
  Attr:TQXMLAttr;
begin
if ValidXMLName(AName) then
  begin
  Attr:=TQXMlAttr.Create;
  Attr.FName:=AName;
  Attr.FValue:=AValue;
  Result:=FItems.Add(Attr);

  end
else
  raise Exception.Create(SBadXMLName);
end;

function TQXMLAttrs.Add(const AName: QStringW): TQXMLAttr;
begin
if ValidXMLName(AName) then
  begin
  Result:=TQXMlAttr.Create;
  Result.FName:=AName;
  FItems.Add(Result);
  end
else
  raise Exception.Create(SBadXMLName);
end;

procedure TQXMLAttrs.Assign(ASource: TQXMLAttrs);
var
  I:Integer;
  Attr,ASrc:TQXMLAttr;
begin
Clear;
if (ASource<>nil) and (ASource.Count>0) then
  begin
  for I := 0 to ASource.Count-1 do
    begin
    ASrc:=ASource[I];
    Attr:=TQXMLAttr.Create;
    Attr.FName:=ASrc.FName;
    Attr.FValue:=ASrc.FValue;
    FItems.Add(Attr);
    end;
  end;
end;

procedure TQXMLAttrs.Clear;
var
  I:Integer;
begin
for I := 0 to FItems.Count-1 do
  FreeObject(Items[I]);
FItems.Clear;
end;

constructor TQXMLAttrs.Create(AOwner:TQXMLNode);
begin
inherited Create;
FOwner:=AOwner;
FItems:=TQXMLAttrList.Create;
end;

procedure TQXMLAttrs.Delete(AIndex: Integer);
begin
FreeObject(Items[AIndex]);
FItems.Delete(AIndex);
end;

procedure TQXMLAttrs.Delete(AName: QStringW);
var
  AIndex:Integer;
begin
AIndex:=IndexOfName(AName);
if AIndex<>-1 then
  Delete(AIndex);
end;

destructor TQXMLAttrs.Destroy;
begin
Clear;
FreeObject(FItems);
end;

function TQXMLAttrs.GetCount: Integer;
begin
Result:=FItems.Count;
end;

function TQXMLAttrs.GetEnumerator: TQXMLAttrEnumerator;
begin
Result:=TQXMLAttrEnumerator.Create(Self);
end;

function TQXMLAttrs.GetItems(AIndex: Integer): TQXMLAttr;
begin
Result:=FItems[AIndex];
end;

function TQXMLAttrs.IndexOfName(const AName: QStringW): Integer;
var
  I,L,AHash:Integer;
  AItem:TQXMLAttr;
begin
Result:=-1;
L:=Length(AName);
AHash:=HashOf(PQCharW(AName),L shl 1);
for I := 0 to Count-1 do
  begin
  AItem:=Items[I];
  if Length(AItem.FName)=L then
    begin
    if XMLCaseSensitive then
      begin
      if AItem.FNameHash=0 then
        AItem.FNameHash:=HashOf(PQCharW(AItem.FName),L shl 1);
      if AItem.FNameHash=AHash then
        begin
        if AItem.FName=AName then
          begin
          Result:=I;
          Break;
          end;
        end;
      end
    else if StartWithW(PQCharW(AItem.FName),PQCharW(AName),True) then
      begin
      Result:=I;
      Break;
      end;
    end;
  end;
end;

function TQXMLAttrs.ItemByName(const AName: QStringW): TQXMLAttr;
var
  I:Integer;
begin
Result:=nil;
I:=IndexOfName(AName);
if I<>-1 then
  Result:=Items[I];
end;

function TQXMLAttrs.ValueByName(const AName, ADefVal: QStringW): QStringW;
var
  I:Integer;
begin
I:=IndexOfName(AName);
if I<>-1 then
  Result:=Items[I].FValue
else
  Result:=ADefVal;
end;

{ TQXMLNode }

function TQXMLNode.Add: TQXMLNode;
begin
Result:=CreateNode;
Result.FParent:=Self;
if not Assigned(FItems) then
  FItems:=TQXMLNodeList.Create;
FItems.Add(Result);
end;

function TQXMLNode.Add(const AName_Text: QStringW;AType:TQXMLNodeType): TQXMLNode;
begin
if AType=xntNode then
  Result:=AddNode(AName_Text)
else
  begin
  Result:=Add;
  Result.FNodeType:=AType;
  Result.Text:=AName_Text;
  end;
end;
function TQXMLNode.AddCData(const AText: QStringW): TQXMLNode;
begin
Result:=Add(AText,xntCData);
end;

function TQXMLNode.AddComment(const AText: QStringW): TQXMLNode;
begin
Result:=Add(AText,xntComment);
end;

function TQXMLNode.AddNode(const AName: QStringW): TQXMLNode;
begin
ValidXMLName(AName);
Result:=Add;
Result.FNodeType:=xntNode;
Result.FName:=AName;
end;

function TQXMLNode.AddObject(AName: QStringW; AObject: TObject;
  AOnFilter: TQXMLRttiFilterEvent;ANest: Boolean;ATag:Pointer): TQXMLNode;
begin
Result:=InternalAddObject(AName,AObject,AOnFilter,ANest,ATag);
end;

function TQXMLNode.IndexOf(const AName: QStringW): Integer;
var
  I,L,AHash:Integer;
  AItem:TQXMLNode;
  AFound:Boolean;
begin
Result:=-1;
L:=Length(AName);
if L>0 then
  AHash:=HashOf(PQCharW(AName),L shl 1)
else
  AHash:=0;
AFound:=False;
for I := 0 to Count-1 do
  begin
  AItem:=Items[I];
  if (AItem.NodeType=xntNode) and (Length(AItem.FName)=L) then
    begin
    if XMLCaseSensitive then
      begin
      if AItem.FNameHash=0 then
        AItem.FNameHash:=HashOf(PQCharW(AItem.FName),Length(AItem.FName) shl 1);
      if AItem.FNameHash=AHash then
        begin
        if Items[I].FName=AName then
          AFound:=True;
        end;
      end
    else //���Դ�Сд�����Ƽ�
      AFound:=StartWithW(PQCharW(AItem.FName),PQCharW(AName),True);
    if AFound then
      begin
      Result:=I;
      Break;
      end;
    end;
  end;
end;

function TQXMLNode.InternalAddObject(AName: QStringW; AObject: TObject;
  AOnFilter: TQXMLRttiFilterEvent;ANest: Boolean;ATag:Pointer): TQXMLNode;
  function GetObjectName(AObj:TObject):String;
  begin
  if AObj<>nil then
    begin
    {$IFDEF TYPENAMEASMETHODPREF}
    Result:=TObject(AObj).ClassName;
    {$ELSE}
    if TObject(AObj) is TComponent then
      Result:=TComponent(AObj).GetNamePath
    else if GetPropInfo(AObj,'Name')<>nil then
      Result:=GetStrProp(AObj,'Name');
    if Length(Result)=0 then
      Result:=TObject(AObj).ClassName;
    {$ENDIF}
    end
  else
    SetLength(Result,0);
  end;

  function GetMethodName(AMethod:TMethod):String;
  var
    AMethodName:String;
  begin
  if AMethod.Data<>nil then
    begin
    Result:=GetObjectName(AMethod.Data);
    AMethodName:=TObject(AMethod.Data).MethodName(AMethod.Code);
    {$IFDEF CPUX64}
    if Length(Result)=0 then
      Result:=IntToHex(Int64(AMethod.Data),16);
    if Length(AMethodName)=0 then
      AMethodName:=IntToHex(Int64(AMethod.Code),16);
    {$ELSE}
    if Length(Result)=0 then
      Result:=IntToHex(IntPtr(AMethod.Data),8);
    if Length(AMethodName)=0 then
      AMethodName:=IntToHex(IntPtr(AMethod.Code),8);
    {$ENDIF}
    Result:=Result+'.'+AMethodName;
    end
  else if AMethod.Code<>nil then
    begin
    {$IFDEF CPUX64}
    Result:=IntToHex(Int64(AMethod.Code),16);
    {$ELSE}
    Result:=IntToHex(IntPtr(AMethod.Code),8);
    {$ENDIF}
    end
  else
    SetLength(Result,0);
  end;

  procedure AddChildren(AParent:TQXMLNode;AObj:TObject);
  var
    AList:PPropList;
    ACount:Integer;
    I:Integer;
    AChild:TQXMLNode;
    ACharVal:QStringA;
    V:Variant;
    Accept:Boolean;
  const
    AttrName:QStringW='value';
  begin
  if AObj=nil then
    Exit;
  if PTypeInfo(AObject.ClassInfo)=nil then//����û��RTTI��Ϣ
    Exit;
  AParent.Attrs.Add('class',AObject.ClassName);//��¼��������
  AList:=nil;
  ACount:=GetPropList(AObj,AList);
  try
    for I := 0 to ACount-1 do
      begin
      if Assigned(AOnFilter) then
        begin
        Accept:=True;
        {$IFDEF QDAC_RTTI_NAMEFIELD}
        AOnFilter(AParent,AObj,AList[I].NameFld.ToString,AList[I].PropType^,Accept,ATag);
        {$ELSE}
        AOnFilter(AParent,AObj,AList[I].Name,AList[I].PropType^,Accept,ATag);
        {$ENDIF}
        if not Accept then
          Continue;
        end;
      {$IFDEF QDAC_RTTI_NAMEFIELD}
      AChild:=AParent.Add(AList[I].NameFld.ToString);
      {$ELSE}
      AChild:=AParent.Add(AList[I].Name);
      {$ENDIF}
      case AList[I].PropType^.Kind of
        tkChar:
          begin
          ACharVal.Length:=1;
          ACharVal.Chars[0]:=GetOrdProp(AObj, AList[I]);
          AChild.Attrs.Add(AttrName,ACharVal);
          end;
        tkWChar:
          AChild.Attrs.Add(AttrName,QCharW(GetOrdProp(AObj, AList[I])));
        tkInteger:
          AChild.Attrs.Add(AttrName,IntToStr(GetOrdProp(AObj, AList[I])));
        tkClass:
          if ANest then
            AddChildren(AChild,TObject(GetOrdProp(AObj,AList[I])))
          else
            AChild.Attrs.Add(AttrName,GetObjectName(TObject(GetOrdProp(AObj,AList[I]))));
        tkEnumeration:
          AChild.Attrs.Add(AttrName,GetEnumProp(AObj,AList[I]));
        tkSet:
          AChild.Attrs.Add(AttrName,'['+GetSetProp(AObj,AList[I])+']');
        tkFloat:
          AChild.Attrs.Add(AttrName,FloatToStr(GetFloatProp(AObj, AList[I])));
        tkMethod:
          AChild.Attrs.Add(AttrName,GetMethodName(GetMethodProp(AObj,AList[I])));
        {$IFNDEF NEXTGEN}
        tkString, tkLString:
          AChild.Attrs.Add(AttrName,GetStrProp(AObj, AList[I]));
        tkWString:
          AChild.Attrs.Add(AttrName,GetWideStrProp(AObj, AList[I]));
        {$ENDIF !NEXTGEN}
        {$IFDEF QDAC_UNICODE}
        tkUString:
          AChild.Attrs.Add(AttrName,GetStrProp(AObj, AList[I]));
        {$ENDIF}
        tkVariant:
          AChild.Attrs.Add(AttrName,VarToStr(GetVariantProp(AObj, AList[I])));
        tkInt64:
          AChild.Attrs.Add(AttrName,IntToStr(GetInt64Prop(AObj, AList[I])));
        tkDynArray:
          begin
          DynArrayToVariant(V,GetDynArrayProp(AObj, AList[I]),AList[I].PropType^);
          AChild.Attrs.Add(AttrName,VarToStr(V));
          end;
      end;
      end;
  finally
    if AList<>nil then
      FreeMem(AList);
  end;
  end;
begin
//����RTTIֱ�ӻ�ȡ�����������Ϣ�����浽�����
Result:=Add(AName);
AddChildren(Result,AObject);
end;

{$IFDEF QDAC_UNICODE}
function TQXMLNode.AddObject(AName: QStringW; AObject: TObject; AOnFilter: TQXMLRttiFilterEventA;
  ANest: Boolean;ATag:Pointer): TQXMLNode;
  function AddWithAnonCallback:TQXMLNode;
  var
    ATagData:TQXMLInternalTagData;
  begin
  ATagData.TagType:=ttAnonEvent;
  ATagData.OnEvent:=AOnFilter;
  ATagData.Tag:=ATag;
  Result:=InternalAddObject(AName,AObject,InternalRttiFilter,ANest,Pointer(@ATagData));
  end;
begin
if Assigned(AOnFilter) then
  Result:=AddWithAnonCallback
else
  Result:=InternalAddObject(AName,AObject,nil,ANest,nil);
end;
{$ENDIF}
function TQXMLNode.AddObject(AName: QStringW; AObject: TObject; ANest: Boolean;
  AcceptProps, AIgnoreProps: QStringW): TQXMLNode;
var
  ATagData:TQXMLInternalTagData;
begin
ATagData.TagType:=ttNameFilter;
ATagData.AcceptNames:=AcceptProps;
ATagData.IgnoreNames:=AIgnoreProps;
Result:=AddObject(AName,AObject,InternalRttiFilter,ANest,@ATagData);
end;
function TQXMLNode.AddText(const AText: QStringW): TQXMLNode;
begin
Result:=Add(AText,xntText);
end;

{$IFDEF QDAC_RTTI}
function TQXMLNode.AddRecord<T>(AName: QStringW; const AObject: T; AcceptFields,
  AIgnoreFields: QStringW): TQXMLNode;
var
  ATagData:TQXMLInternalTagData;
begin
ATagData.TagType:=ttNameFilter;
ATagData.AcceptNames:=AcceptFields;
ATagData.IgnoreNames:=AIgnoreFields;
Result:=AddRecord(AName,AObject,InternalRttiFilter,@ATagData);
end;

function TQXMLNode.AddRecord<T>(AName: QStringW; const AObject: T): TQXMLNode;
begin
Result:=AddRecord(Aname,AObject,TQXMLRttiFilterEvent(nil),nil);
end;

function TQXMLNode.AddRecord<T>(AName: QStringW; const AObject: T;
  AOnFilter: TQXMLRttiFilterEvent; ATag: Pointer): TQXMLNode;
begin
Result:=Add(AName);
Result.InternalAddRecord(TypeInfo(T),@AObject,AOnFilter,ATag);
end;

function TQXMLNode.AddRecord<T>(AName:QStringW;const AObject:T;AOnFilter:TQXMLRttiFilterEventA;ATag:Pointer):TQXMLNode;
var
  ATagData:TQXMLInternalTagData;
begin
ATagData.TagType:=ttAnonEvent;
ATagData.Tag:=ATag;
ATagData.OnEvent:=AOnFilter;
Result:=AddRecord(AName,AObject,InternalRttiFilter,@ATagData);
end;

function TQXMLNode.InternalAddRecord(ATypeInfo: PTypeInfo;
  ABaseAddr: Pointer;AOnFilter:TQXMLRttiFilterEvent;ATag:Pointer): Boolean;
var
  AContext:TRttiContext;
  AType:TRttiType;
  I:Integer;
  AFields:TArray<TRttiField>;
  AChild:TQXMLNode;
  Accept:Boolean;
  function ValueToVariant(AValue:TValue):Variant;
  var
    J,L:Integer;
    AItemValue:TValue;
  begin
  L:=AValue.GetArrayLength;
  Result:=VarArrayCreate([0,L-1],varVariant);
  for J := 0 to L-1 do
    begin
    AItemValue:=AValue.GetArrayElement(J);
    if AItemValue.IsArray then
      Result[J]:=ValueToVariant(AItemValue)
    else
      Result[J]:=AItemValue.AsVariant;
    end;
  end;

  procedure ParseVariant(ANode:TQXMLNode;const Value:Variant);
  var
    I:Integer;
    vDouble:Double;
  begin
  if VarIsArray(Value) then
    begin
    ANode.Attrs.Add('type','array');
    //Ŀǰʵ��ֻ֧��һά����
    for I := VarArrayLowBound(Value,VarArrayDimCount(Value)) to VarArrayHighBound(Value,VarArrayDimCount(Value)) do
      ParseVariant(ANode.Add('item'),Value[I]);
    end
  else
    begin
    case VarType(Value) of
      varSmallInt,varInteger,varByte,varShortInt,varWord,varLongWord,varInt64:
        begin
        ANode.Attrs.Add('type','int');
        ANode.Attrs.Add('value',VarToStr(Value));
        end;
      varSingle,varDouble,varCurrency:
        begin
        ANode.Attrs.Add('type','float');
        ANode.Attrs.Add('value',VarToStr(Value));
        end;
      varDate:
        begin
        vDouble:=Value;
        if Trunc(vDouble)=0 then
          begin
          ANode.Attrs.Add('type','time');
          ANode.Attrs.Add('value',FormatDateTime(XMLTimeFormat,vDouble));
          end
        else if SameValue(vDouble,Trunc(vDouble)) then
          begin
          ANode.Attrs.Add('type','date');
          ANode.Attrs.Add('value',FormatDateTime(XMLDateFormat,vDouble));
          end
        else
          begin
          ANode.Attrs.Add('type','datetime');
          ANode.Attrs.Add('value',FormatDateTime(XMLDateTimeFormat,vDouble));
          end;
        end;
      varOleStr,varString{$IFDEF QDAC_UNICODE},varUString{$ENDIF}:
        begin
        ANode.Attrs.Add('type','string');
        ANode.Attrs.Add('value',VarToStr(Value));
        end;
      varBoolean:
        begin
        ANode.Attrs.Add('type','bool');
        ANode.Attrs.Add('value',BoolToStr(Value,true));
        end;
    end;
    end;
  end;

  procedure ParseDynArray;
  var
    AValue:TValue;
  begin
  AValue:=AFields[I].GetValue(ABaseAddr);
  if AValue.IsArray then
    ParseVariant(AChild,ValueToVariant(AValue))
  end;
begin
Result:=False;
if Assigned(ATypeInfo) then
  begin
  AType:=AContext.GetType(ATypeInfo);
  if AType<>nil then
    begin
    if AType.TypeKind=tkRecord then
      begin
      Result:=True;
      AFields:=AType.GetFields;
      for I := Low(AFields) to High(AFields) do
        begin
        Accept:=True;
        if Assigned(AOnFilter) then
          AOnFilter(Self,ABaseAddr,AFields[I].Name,AFields[I].FieldType.Handle,Accept,ATag);
        if not Accept then
          Continue;
        AChild:=Add(AFields[I].Name);
        case AFields[I].FieldType.TypeKind of
          tkInteger,tkInt64:
            begin
            AChild.Attrs.Add('type','int');
            AChild.Attrs.Add('value',IntToStr(AFields[I].GetValue(ABaseAddr).AsInt64));
            end;
          tkUString{$IFNDEF NEXTGEN},tkString,tkLString,tkWString,tkChar,tkWChar{$ENDIF}:
            begin
            AChild.Attrs.Add('type','string');
            AChild.Attrs.Add('value',AFields[I].GetValue(ABaseAddr).ToString);
            end;
          tkRecord:
            begin
            AChild.Attrs.Add('type','record');
            AChild.InternalAddRecord(AFields[I].FieldType.Handle,Pointer(IntPtr(ABaseAddr)+AFields[I].Offset),AOnFilter,ATag);
            end;
          tkEnumeration:
            begin
            AChild.Attrs.Add('type','enum');
            AChild.Attrs.Add('value',AFields[I].GetValue(ABaseAddr).ToString);
            end;
          tkSet:
            begin
            AChild.Attrs.Add('type','set');
            AChild.Attrs.Add('value',AFields[I].GetValue(ABaseAddr).ToString);
            end;
          tkFloat:
            begin
            if (AFields[I].FieldType.Handle=TypeInfo(TDate)) then
              begin
              AChild.Attrs.Add('type','date');
              AChild.Attrs.Add('value',FormatDateTime(XMLDateFormat,AFields[I].GetValue(ABaseAddr).AsExtended));
              end
            else if (AFields[I].FieldType.Handle=TypeInfo(TTime)) then
              begin
              AChild.Attrs.Add('type','time');
              AChild.Attrs.Add('value',FormatDateTime(XMLTimeFormat,AFields[I].GetValue(ABaseAddr).AsExtended));
              end
            else if (AFields[I].FieldType.Handle=TypeInfo(TDateTime)) then
              begin
              AChild.Attrs.Add('type','datetime');
              AChild.Attrs.Add('value',FormatDateTime(XMLDateTimeFormat,AFields[I].GetValue(ABaseAddr).AsExtended));
              end
            else
              begin
              AChild.Attrs.Add('type','float');
              AChild.Attrs.Add('value',FloatToStr(AFields[I].GetValue(ABaseAddr).AsExtended));
              end;
            end;
          tkVariant:
            ParseVariant(AChild,AFields[I].GetValue(ABaseAddr).AsVariant);
          tkArray,tkDynArray:
            ParseDynArray;
          tkClass,tkMethod,tkInterface,tkClassRef,tkPointer,tkProcedure:
            begin
//            AChild.AsString:='<OBJECT>';
            end;
        end;
        end;
      end;
    end;
  end;
end;
{$ENDIF !QDAC_RTTI}

procedure TQXMLNode.Assign(ANode: TQXMLNode);
var
  I:Integer;
begin
FName:=ANode.FName;
FNodeType:=ANode.NodeType;
Clear;
if Assigned(ANode.FAttrs) then
  Attrs.Assign(ANode.Attrs);
for I := 0 to ANode.Count - 1 do
  Add.Assign(ANode.Items[I]);
end;

function TQXMLNode.AttrByPath(const APath, AttrName: QStringW): TQXMLAttr;
var
  ANode:TQXMLNode;
begin
ANode:=ItemByPath(APath);
if Assigned(ANode) then
  Result:=ANode.Attrs.ItemByName(AttrName)
else
  Result:=nil;
end;

function TQXMLNode.AttrValueByPath(const APath, AttrName,
  ADefVal: QStringW): QStringW;
var
  Attr:TQXMLAttr;
begin
Attr:=AttrByPath(APath,AttrName);
if Assigned(Attr) then
  Result:=Attr.Value
else
  Result:=ADefVal;
end;

procedure TQXMLNode.Clear;
var
  I:Integer;
begin
if Assigned(FItems) then
  begin
  for I := 0 to FItems.Count-1 do
    FreeNode(Items[I]);
  FItems.Clear;
  end;
if Assigned(FAttrs) then
  FAttrs.Clear;
end;

function TQXMLNode.Clone: TQXMLNode;
begin
Result:=Copy;
end;

function TQXMLNode.Copy: TQXMLNode;
begin
Result:=CreateNode;
Result.Assign(Self);
end;
{$IFDEF QDAC_RTTI}
function TQXMLNode.CopyIf(const ATag: Pointer;
  AFilter: TQXMLFilterEventA): TQXMLNode;
  procedure NestCopy(AParentSource,AParentDest:TQXMLNode);
  var
    I:Integer;
    Accept:Boolean;
    AChildSource,AChildDest:TQXMLNode;
  begin
  for I := 0 to AParentSource.Count-1 do
    begin
    Accept:=True;
    AChildSource:=AParentSource[I];
    AFilter(Self,AChildSource,Accept,ATag);
    if Accept then
      begin
      AChildDest:=AParentDest.Add(AChildSource.FName,AChildSource.NodeType);
      if Assigned(AChildSource.FAttrs) then
        AChildDest.Attrs.Assign(AChildSource.Attrs);
      if AChildSource.Count>0 then
        NestCopy(AChildSource,AChildDest);
      end;
    end;
  end;
begin
if Assigned(AFilter) then
  begin
  Result:=CreateNode;
  Result.FNodeType:=NodeType;
  Result.FName:=FName;
  if Count>0 then
    NestCopy(Self,Result);
  end
else
  Result:=Copy;
end;
{$ENDIF QDAC_RTTI}
function TQXMLNode.CopyIf(const ATag: Pointer;
  AFilter: TQXMLFilterEvent): TQXMLNode;

  procedure NestCopy(AParentSource,AParentDest:TQXMLNode);
  var
    I:Integer;
    Accept:Boolean;
    AChildSource,AChildDest:TQXMLNode;
  begin
  for I := 0 to AParentSource.Count-1 do
    begin
    Accept:=True;
    AChildSource:=AParentSource[I];
    AFilter(Self,AChildSource,Accept,ATag);
    if Accept then
      begin
      AChildDest:=AParentDest.Add(AChildSource.FName,AChildSource.NodeType);
      if Assigned(AChildSource.FAttrs) then
        AChildDest.Attrs.Assign(AChildSource.Attrs);
      if AChildSource.Count>0 then
        NestCopy(AChildSource,AChildDest);
      end;
    end;
  end;

begin
if Assigned(AFilter) then
  begin
  Result:=CreateNode;
  Result.FNodeType:=NodeType;
  Result.FName:=FName;
  if Count>0 then
    NestCopy(Self,Result);
  end
else
  Result:=Copy;
end;

constructor TQXMLNode.Create;
begin
inherited;
end;

function TQXMLNode.CreateNode: TQXMLNode;
begin
if Assigned(OnQXMLNodeCreate) then
  Result:=OnQXMLNodeCreate
else
  Result:=TQXMLNode.Create;
end;

procedure TQXMLNode.Delete(AIndex: Integer);
begin
if Assigned(FItems) then
  begin
  FreeNode(Items[AIndex]);
  FItems.Delete(AIndex);
  end;
end;

procedure TQXMLNode.Delete(AName: QStringW; ADeleteAll: Boolean);
var
  I:Integer;
begin
I:=0;
while I<Count do
  begin
  if Items[I].FName=AName then
    begin
    Delete(I);
    if not ADeleteAll then
      Break;
    end
  else
    Inc(I);
  end;
end;
{$IFDEF QDAC_RTTI}
procedure TQXMLNode.DeleteIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQXMLFilterEventA);
  procedure DeleteChildren(AParent:TQXMLNode);
  var
    I:Integer;
    Accept:Boolean;
    AChild:TQXMLNode;
  begin
  I:=0;
  while I<AParent.Count do
    begin
    Accept:=True;
    AChild:=AParent.Items[I];
    if ANest then
      DeleteChildren(AChild);
    AFilter(Self,AChild,Accept,ATag);
    if Accept then
      AParent.Delete(I)
    else
      Inc(I);
    end;
  end;
begin
if Assigned(AFilter) then
  DeleteChildren(Self)
else
  Clear;
end;
{$ENDIF QDAC_RTTI}

procedure TQXMLNode.DeleteIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQXMLFilterEvent);
  procedure DeleteChildren(AParent:TQXMLNode);
  var
    I:Integer;
    Accept:Boolean;
    AChild:TQXMLNode;
  begin
  I:=0;
  while I<AParent.Count do
    begin
    Accept:=True;
    AChild:=AParent.Items[I];
    if ANest then
      DeleteChildren(AChild);
    AFilter(Self,AChild,Accept,ATag);
    if Accept then
      AParent.Delete(I)
    else
      Inc(I);
    end;
  end;
begin
if Assigned(AFilter) then
  DeleteChildren(Self)
else
  Clear;
end;

destructor TQXMLNode.Destroy;
begin
if Assigned(FItems) then
  begin
  Clear;
  FreeObject(FItems);
  end;
if Assigned(FAttrs) then
  FreeObject(FAttrs);
inherited;
end;

procedure TQXMLNode.DoParse(p: PQCharW);
var
  ACol,ARow:Integer;
  ps,pl:PQCharW;
  AttrName:QStringW;
  //����DTD���֣���QXML��֧��DTD���֣�����Ե����е�����
  function ParseDTD:Boolean;
  var
    APairCount:Integer;
  begin
  if StartWithW(p,'<!DOCTYPE',false) or
    StartWithW(p,'<!ELEMENT',false) or
    StartWithW(p,'<!ATTLIST',false)
    then
    begin
    APairCount:=1;
    Inc(p,9);//����9���ַ�����,:)
    while (p^<>#0) do
      begin
      if p^='<' then
        Inc(APairCount)
      else if p^='>' then
        begin
        Dec(APairCount);
        if APairCount=0 then
          begin
          Inc(p);
          SkipSpaceW(p);
          Break;
          end;
        end
      else
        Inc(p);
      end;
    Result:=True;
    end
  else
    Result:=False;
  end;
  procedure InternalParse(AParent:TQXMLNode);
  var
    AChild:TQXMLNode;
    ws:PQCharW;
    AClosed:Boolean;
  const
    TagStart:PQCharW='<';
    TagClose:PQCharW='>';
    Question:PQCharW='?';
    TagNameEnd:PQCharW=#9#10#13#32'/>';
    AttrNameEnd:PQCharW=#9#10#13#32'=/>';
  begin
  while p^<>#0 do
    begin
    SkipSpaceW(p);
    if p^='<' then //��ǩ��ʼ
      begin
      if p[1]='/' then//</AParent.Name>
        begin
        Inc(p,2);
        ws:=p;
        SkipUntilW(p,TagClose);
        if p^='>' then
          begin
          if (Length(AParent.Name)=(p-ws)) and StartWithW(ws,PQCharW(AParent.Name),false) then
            begin
            Inc(p);
            Exit;
            end
          else
            raise Exception.Create(SUnclosedXMLTag);
          end
        else
          raise Exception.Create(SUnclosedXMLTag);
        end
      else if p[1]='!' then
        begin
        if (p[2]='-') and (p[3]='-') then//ע��
          begin
          Inc(p,4);
          ws:=p;
          AClosed:=False;
          while p^<>#0 do
            begin
            if (p[0]='-') and (p[1]='-') then
              begin
              if p[2]='>' then
                begin
                AParent.Add(StrDupX(ws,p-ws),xntComment);
                Inc(p,3);
                AClosed:=True;
                Break;
                end
              else
                raise Exception.Create(SBadXMLComment);
              end
            else
              Inc(p);
            end;
          if not AClosed then
            raise Exception.Create(SUnterminateXMLComment);
          end
        else if StartWithW(p,'<![CDATA[',False) then//CDATA
          begin
          Inc(p,9);
          ws:=p;
          AClosed:=False;
          while p^<>#0 do
            begin
            if (p[0]=']') and (p[1]=']') then
              begin
              if p[2]='>' then
                begin
                AParent.Add(StrDupX(ws,p-ws),xntCDATA);
                Inc(p,3);
                AClosed:=True;
                Break;
                end
              else
                Inc(p);
              end
            else
              Inc(p);
            end;
          if not AClosed then
            raise Exception.Create(SUnterminateXMLCData);
          end
        else//DTD ���壿
          begin
          if not ParseDTD then
            raise Exception.Create(SBadXMLName);
          end;
        end
      else if p[1]='?' then
        begin
        if StartWithW(p,'<?xml',true) and IsSpaceW(p+5)  then
          begin
          Inc(p,6);
          SkipUntilW(p,Question);
          if StartWithW(p,'?>',False) then
            begin
            Inc(p,2);
            SkipSpaceW(p);
            end
          else
            raise Exception.Create(SUnclosedXMLTag);
          end
        else
          raise Exception.Create(SBadXMLName);
        end
      else//���
        begin
        Inc(p);
        SkipSpaceW(p);
        ws:=p;
        SkipUntilW(p,TagNameEnd);
        AChild:=AParent.Add(StrDupX(ws,p-ws),xntNode);
        if (p^<>'>') and (p^<>'/') then
          begin
        //��������
          while p^<>#0 do
            begin
            SkipSpaceW(p);
            ws:=p;
            SkipUntilW(p,AttrNameEnd);
            AttrName:=StrDupX(ws,p-ws);
            SkipSpaceW(p);
            if p^='=' then
              begin
              Inc(p);
              SkipSpaceW(p);
              if (p^='''') or (p^='"') then
                begin
                ws:=p;
                Inc(p);
                while p^<>#0 do
                  begin
                  if p^=ws^ then
                    begin
                    Inc(p);
                    Break;
                    end
                  else
                    Inc(p);
                  end;
                AChild.Attrs.Add(AttrName,XMLDecode(ws+1,p-ws-2));
                end
              else
                raise Exception.Create(SXMLBadAttrValue);
              end
            else if (p^='/') or (p^='>') then
              Break
            else
              raise Exception.Create(SXMLAttrValueMissed);
            end;
          end;
        if p^='>' then
          Inc(p)
        else if (p[0]='/') and (p[1]='>') then //ֱ�ӽ�����û�и������ݵĽ��
          begin
          Inc(p,2);
          Continue;
          end
        else
          raise Exception.Create(SUnterminatedXMLTag);
        SkipSpaceW(p);
        if p^='<' then
          InternalParse(AChild)
        else//���Ǳ�ǩ��ʼ,�м�����ı�������
          begin
          ws:=p;
          SkipUntilW(p,TagStart);
          AChild.Add(XMLDecode(ws,p-ws),xntText);
          if (p[0]='<') then
            InternalParse(AChild);
          end;
        end;
      end
    else if p^<>#0 then//����<��ʼ�ı�ǩ��Ϊ�ı�
      begin
      if p<>ps then
        begin
        ws:=p;
        SkipUntilW(p,TagStart);
        AParent.Add(StrDupX(ws,p-ws),xntText);
        end
      else
        raise Exception.Create(SBadXMLTagStart);
      end;
    end;
  end;
begin
ps:=p;
SkipSpaceW(p);
try
  InternalParse(Self);
except on E:Exception do
  begin
  pl:=StrPosW(ps,p,ACol,ARow);
  raise Exception.CreateFmt('%s'#13#10'λ��:��%d�� ��%d��'#13#10'�����ݣ�%s',[E.Message,ARow,ACol,DecodeLineW(pl)]);
  end;
end;
end;

//Redo:��ʽ������
function TQXMLNode.Encode(ADoFormat: Boolean; AIndent: QStringW): QStringW;
var
  ABuilder:TQStringCatHelperW;
begin
ABuilder:=TQStringCatHelperW.Create;//(16384);
try
  InternalEncode(ABuilder,ADoFormat,AIndent);
  Result:=ABuilder.Value;
finally
  FreeObject(ABuilder);
end;
end;
{$IFDEF QDAC_RTTI}
function TQXMLNode.FindIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQXMLFilterEventA): TQXMLNode;
  function DoFind(AParent:TQXMLNode):TQXMLNode;
  var
    I:Integer;
    AChild:TQXMLNode;
    Accept:Boolean;
  begin
  Result:=nil;
  for I := 0 to AParent.Count-1 do
    begin
    AChild:=AParent[I];
    Accept:=True;
    AFilter(Self,AChild,Accept,ATag);
    if Accept then
      Result:=AChild
    else if ANest then
      Result:=DoFind(AChild);
    if Result<>nil then
      Break;
    end;
  end;
begin
if Assigned(AFilter) then
  Result:=DoFind(Self)
else
  Result:=nil;
end;
{$ENDIF QDAC_RTTI}
function TQXMLNode.FindIf(const ATag: Pointer; ANest: Boolean;
  AFilter: TQXMLFilterEvent): TQXMLNode;
function DoFind(AParent:TQXMLNode):TQXMLNode;
  var
    I:Integer;
    AChild:TQXMLNode;
    Accept:Boolean;
  begin
  Result:=nil;
  for I := 0 to AParent.Count-1 do
    begin
    AChild:=AParent[I];
    Accept:=True;
    AFilter(Self,AChild,Accept,ATag);
    if Accept then
      Result:=AChild
    else if ANest then
      Result:=DoFind(AChild);
    if Result<>nil then
      Break;
    end;
  end;
begin
if Assigned(AFilter) then
  Result:=DoFind(Self)
else
  Result:=nil;
end;

function TQXMLNode.ForcePath(APath: QStringW): TQXMLNode;
var
  AName:QStringW;
  p:PQCharW;
  AParent:TQXMLNode;
const
  PathDelimiters:PWideChar='./\';
begin
p:=PQCharW(APath);
AParent:=Self;
Result:=Self;
while p^<>#0 do
  begin
  AName:=DecodeTokenW(p,PathDelimiters,WideChar(0),True);
  Result:=AParent.ItemByName(AName);
  if not Assigned(Result) then
    Result:=AParent.Add(AName);
  AParent:=Result;
  end;
end;

procedure TQXMLNode.FreeNode(ANode: TQXMLNode);
begin
if Assigned(OnQXMLNodeFree) then
  OnQXMLNodeFree(ANode)
else
  FreeObject(ANode);
end;

function TQXMLNode.GetAsXML: QStringW;
begin
Result:=Encode(True,'  ');
end;

function TQXMLNode.GetAttrs: TQXMLAttrs;
begin
if not Assigned(FAttrs) then
  FAttrs:=TQXMLAttrs.Create(Self);
Result:=FAttrs;
end;

function TQXMLNode.GetCapacity: Integer;
begin
if Assigned(FItems) then
  Result:=FItems.Capacity
else
  Result:=0;
end;

function TQXMLNode.GetCount: Integer;
begin
if Assigned(FItems) then
  Result:=FItems.Count
else
  Result:=0;
end;

function TQXMLNode.GetEnumerator: TQXMLNodeEnumerator;
begin
Result:=TQXMLNodeEnumerator.Create(Self);
end;

function TQXMLNode.GetItemIndex: Integer;
var
  I:Integer;
begin
Result:=-1;
if Assigned(FParent) then
  begin
  for I := 0 to FParent.Count-1 do
    begin
    if FParent.Items[I]=Self then
      begin
      Result:=I;
      Break;
      end;
    end;
  end;
end;

function TQXMLNode.GetItems(AIndex: Integer): TQXMLNode;
begin
Result:=FItems[AIndex];
end;

function TQXMLNode.GetName: QStringW;
begin
if NodeType=xntNode then
  Result:=FName
else
  SetLength(Result,0);
end;

function TQXMLNode.GetPath: QStringW;
var
  AParent:TQXMLNode;
begin
Result:=Name;
AParent:=FParent;
while Assigned(AParent) do
  begin
  if Length(AParent.Name)>0 then
    Result:=AParent.Name+'\'+Result;
  AParent:=AParent.FParent;
  end;
end;

function TQXMLNode.GetText: QStringW;
var
  ABuilder:TQStringCatHelperW;
  procedure InternalGetText(ANode:TQXMLNode);
  var
    I:Integer;
  begin
  if ANode.NodeType=xntNode then
    begin
    for I := 0 to ANode.Count-1 do
      InternalGetText(ANode.Items[I]);
    end
  else //if ANode.NodeType<>xntComment then //ע�Ͳ�������Text�У��ı���CDATA���ݷ���
    ABuilder.Cat(ANode.FName);
  end;
begin
ABuilder:=TQStringCatHelperW.Create;
try
  InternalGetText(Self);
  Result:=ABuilder.Value;
finally
  ABuilder.Free;
end;
end;

function TQXMLNode.ItemByName(const AName: QStringW): TQXMLNode;
var
  AIndex:Integer;
begin
AIndex:=IndexOf(AName);
if AIndex<>-1 then
  Result:=Items[AIndex]
else
  Result:=nil;
end;

function TQXMLNode.InternalEncode(ABuilder: TQStringCatHelperW;
  ADoFormat: Boolean; const AIndent: QStringW):TQStringCatHelperW;
const
  TagStart:PWideChar='<';
  TagEnd:PWideChar='/>';
  TagClose:PWideChar='>';
  TagCloseStart:PWideChar='</';
  Space:PWideChar=' ';
  ValueStart:PWideChar='="';
  Quoter:PWideChar='"';
  CommentStart:PWideChar='<!--';
  CommentEnd:PWideChar='-->';
  CDataStart:PWideChar='<![CDATA[';
  CDataEnd:PWideChar=']]>';
  procedure DoEncode(AItem:TQXMLNode;ALevel:Integer);
  var
    I:Integer;
    ANode:TQXMLNode;
  begin
  if ADoFormat then
      ABuilder.Replicate(AIndent,ALevel);
  if (Length(AItem.FName)>0) then
    ABuilder.Cat(TagStart,1).Cat(AItem.FName)
  else if (AItem.Parent<>nil) and (NodeType in [xntNode]) then
    raise Exception.Create(SNodeWithoutName);
  if Assigned(AItem.FAttrs) then
    begin
    for I := 0 to AItem.FAttrs.Count-1 do
      ABuilder.Cat(Space,1).Cat(AItem.Attrs[I].FName).Cat(ValueStart,2).Cat(XMLEncode(AItem.Attrs[I].FValue)).Cat(Quoter);
    end;
  if AItem.Count=0 then
    begin
    if XMLTagShortClose then
      ABuilder.Cat(TagEnd,2)
    else if Length(AItem.FName)>0 then
      ABuilder.Cat(TagClose,1).Cat(TagCloseStart,2).Cat(AItem.FName).Cat(TagClose,1);
    end
  else
    begin
    if Length(AItem.Name)>0 then
      ABuilder.Cat(TagClose,1).Cat(SLineBreak);
    for I := 0 to AItem.Count-1 do
      begin
      ANode:=AItem[I];
      case ANode.NodeType of
        xntNode:
          begin
          if Length(ANode.Name)=0 then
            raise Exception.Create(SXMLNameNeeded);
          DoEncode(ANode,ALevel+1);
          end;
        xntText:
          begin
          if ADoFormat then
            ABuilder.Replicate(AIndent,ALevel);
          ABuilder.Cat(XMLEncode(ANode.FName));
          end;
        xntComment:
          begin
          if ADoFormat then
            ABuilder.Replicate(AIndent,ALevel);
          ABuilder.Cat(CommentStart,4).Cat(ANode.FName).Cat(CommentEnd,3);
          end;
        xntCData:
          begin
          if ADoFormat then
            ABuilder.Replicate(AIndent,ALevel);
          ABuilder.Cat(CDataStart,9).Cat(ANode.FName).Cat(CDataEnd,3);
          end;
      end;
      if ADoFormat then
        ABuilder.Cat(SLineBreak);
      end;
    if ADoFormat then
      ABuilder.Replicate(AIndent,ALevel);
    if (Length(AItem.FName)>0) then
      ABuilder.Cat(TagCloseStart,2).Cat(AItem.FName).Cat(TagClose,1);
    end;
  end;
begin
Result:=ABuilder;
DoEncode(Self,0);
end;

procedure TQXMLNode.InternalRttiFilter(ASender: TQXMLNode; AObject: Pointer;
  APropName: QStringW; APropType: PTypeInfo; var Accept: Boolean;
  ATag: Pointer);
var
  AFilter:PQXMLInternalTagData;
  procedure DoNameFilter;
  var
    ps:PQCharW;
  begin
  if Length(AFilter.AcceptNames)>0 then
    begin
    Accept:=False;
    ps:=StrIStrW(PQCharW(AFilter.AcceptNames),PQCharW(APropName));
    if (ps<>nil) and ((ps=PQCharW(AFilter.AcceptNames)) or (ps[-1]=',') or (ps[-1]=';')) then
      begin
      ps:=ps+Length(APropName);
      Accept:=(ps^=',') or (ps^=';') or (ps^=#0);
      end;
    end
  else if Length(AFilter.IgnoreNames)>0 then
    begin
    ps:=StrIStrW(PQCharW(AFilter.IgnoreNames),PQCharW(APropName));
    Accept:=True;
    if (ps<>nil) and ((ps=PQCharW(AFilter.IgnoreNames)) or (ps[-1]=',') or (ps[-1]=';')) then
      begin
      ps:=ps+Length(APropName);
      Accept:=not ((ps^=',') or (ps^=';') or (ps^=#0));
      end;
    end;
  end;
begin
AFilter:=PQXMLInternalTagData(ATag);
{$IFDEF QDAC_UNICODE}
if AFilter.TagType=ttAnonEvent then
  AFilter.OnEvent(ASender,AObject,APropName,APropType,Accept,AFilter.Tag)
else
{$ENDIF}
if AFilter.TagType=ttNameFilter then
  DoNameFilter;
end;
{$IFDEF QDAC_RTTI}
procedure TQXMLNode.InternalToRecord(ATypeInfo: PTypeInfo; ABaseAddr: Pointer);
var
  AContext:TRttiContext;
  AType:TRttiType;
  I:Integer;
  AFields:TArray<TRttiField>;
  AChild:TQXMLNode;
  Attr:TQXMLAttr;
  procedure SetAsIntValue(AValue:Int64);
  begin
  if AFields[I].FieldType.TypeKind=tkInt64 then
    PInt64(IntPtr(ABaseAddr)+AFields[I].Offset)^:=AValue
  else
    begin
    case GetTypeData(AFields[I].FieldType.Handle)^.OrdType
      //AFields[I].FieldType.Handle.TypeData.OrdType
      of
        otSByte, otUByte:
          PByte(IntPtr(ABaseAddr)+AFields[I].Offset)^:=AValue;
        otSWord, otUWord:
          PSmallint(IntPtr(ABaseAddr)+AFields[I].Offset)^:=AValue;
        otSLong, otULong:
          PInteger(IntPtr(ABaseAddr)+AFields[I].Offset)^:=AValue;
      end;
    end
  end;

  function AttrAsVariant(ANode:TQXMLNode):Variant;
  var
    ATypeAttr,AValueAttr:TQXMLAttr;
    I:Integer;
    AList:TQXMLNodeList;
  begin
  ATypeAttr:=ANode.Attrs.ItemByName('type');
  if Assigned(ATypeAttr) then
    begin
    if ATypeAttr.Value='array' then
      begin
      AList:=TQXMLNodeList.Create;
      try
        ANode.ItemByName('item',AList,false);
        if AList.Count>0 then
          begin
          Result:=VarArrayCreate([0,AList.Count-1],varVariant);
          for I := 0 to AList.Count-1 do
            Result[I]:=AttrAsVariant(AList[I]);
          end
      finally
        FreeObject(AList);
      end;
      end
    else
      begin
      AValueAttr:=ANode.Attrs.ItemByName('value');
      if AValueAttr=nil then
        begin
        Result:=Null;
        Exit;
        end;
      if ATypeAttr.Value='int' then
        Result:=AValueAttr.AsInt64
      else if ATypeAttr.Value='float' then
        Result:=AValueAttr.AsFloat
      else if (ATypeAttr.Value='time') or (ATypeAttr.Value='date') or (ATypeAttr.Value='datetime') then
        Result:=AValueAttr.AsDateTime
      else if ATypeAttr.Value='string' then
        Result:=AValueAttr.AsString
      else if ATypeAttr.Value='bool' then
        Result:=AValueAttr.AsBoolean
      end;
    end;
  end;

  procedure ParseDynArray;
  var
    AValue:array of TValue;
    J:Integer;
  begin
  SetLength(AValue,AChild.Count);
  for J := 0 to AChild.Count-1 do
   AValue[J]:=TValue.FromVariant(AttrAsVariant(AChild));
  AFields[I].SetValue(ABaseAddr,TValue.FromArray(AFields[I].FieldType.Handle,AValue));
  end;

  {$IFNDEF NEXTGEN}
  procedure ParseShortString;
  var
    S: ShortString;
    AValue:TValue;
  begin
  S:= ShortString(Attr.AsString);
  TValue.Make(@S, AFields[I].FieldType.Handle, AValue);
  AFields[I].SetValue(ABaseAddr,AValue);
  end;
  {$ENDIF}
begin
if not Assigned(ATypeInfo) then
  Exit;
AType:=AContext.GetType(ATypeInfo);
if AType=nil then
  Exit;
if AType.TypeKind<>tkRecord then
  Exit;
AFields:=AType.GetFields;
for I := Low(AFields) to High(AFields) do
  begin
  AChild:=ItemByName(AFields[I].Name);
  if Assigned(AChild) then
    begin
    Attr:=AChild.Attrs.ItemByName('value');
    if Assigned(Attr) then
      begin
      if  AFields[I].FieldType.TypeKind =tkInteger then
        SetAsIntValue(Attr.AsInt64)
      else if AFields[I].FieldType.TypeKind=tkInt64 then
        SetAsIntValue(Attr.AsInt64)
      else if AFields[I].FieldType.TypeKind in [tkUString{$IFNDEF NEXTGEN},tkString,tkLString,tkWString,tkChar,tkWChar{$ENDIF}] then
        begin
        {$IFDEF NEXTGEN}
        AFields[I].SetValue(ABaseAddr,TValue.From(Attr.AsString));
        {$ELSE}
        if AFields[I].FieldType.TypeKind=tkString then
          ParseShortString
        else
          AFields[I].SetValue(ABaseAddr,TValue.From(Attr.AsString));
        {$ENDIF}
        end
      else if AFields[I].FieldType.TypeKind=tkRecord then
        InternalToRecord(AFields[I].FieldType.Handle,Pointer(IntPtr(ABaseAddr)+AFields[I].Offset))
      else if AFields[I].FieldType.TypeKind=tkEnumeration then
        SetAsIntValue(GetEnumValue(AFields[I].FieldType.Handle,Attr.AsString))
      else if AFields[I].FieldType.TypeKind=tkSet then
        SetAsIntValue(StringToSet(AFields[I].FieldType.Handle,Attr.AsString))
      else if AFields[I].FieldType.TypeKind=tkFloat then
        begin
        if (AFields[I].FieldType.Handle=TypeInfo(TDate)) or
          (AFields[I].FieldType.Handle=TypeInfo(TTime)) or
          (AFields[I].FieldType.Handle=TypeInfo(TDateTime))
          then
          AFields[I].SetValue(ABaseAddr,TValue.From(Attr.AsDateTime))
        else
          AFields[I].SetValue(ABaseAddr,TValue.From(Attr.AsFloat));
        end
      else if (AFields[I].FieldType.TypeKind=tkVariant) then
        begin
        AFields[I].SetValue(ABaseAddr,TValue.From(AttrAsVariant(AChild)))
        end
      else if (AFields[I].FieldType.TypeKind in [tkArray,tkDynArray]) then
        ParseDynArray
      else//
        begin
  //      tkClass,tkMethod,tkInterface,tkClassRef,tkPointer,tkProcedure:
          {����֧�ֵ����ͣ�����};
        end;
      end;
    end;
  end;
end;
{$ENDIF}
function TQXMLNode.ItemByName(const AName: QStringW;
  AList: TQXMLNodeList;ANest:Boolean): Integer;
var
  ANode:TQXMLNode;
  function InternalFind(AParent:TQXMLNode):Integer;
  var
    I:Integer;
  begin
  Result:=0;
  for I := 0 to AParent.Count-1 do
    begin
    ANode:=AParent.Items[I];
    if ANode.Name=AName then
      begin
      AList.Add(ANode);
      Inc(Result);
      end;
    if ANest then
      Inc(Result,InternalFind(ANode));
    end;
  end;
begin
Result:=InternalFind(Self);
end;

function TQXMLNode.ItemByPath(const APath: QStringW): TQXMLNode;
var
  AName:QStringW;
  pPath:PQCharW;
  AParent,AItem:TQXMLNode;
const
  PathDelimiters:PWideChar='/\.';
begin
if Length(APath)>0 then
  begin
  pPath:=PQCharW(APath);
  AParent:=Self;
  AItem:=nil;
  while pPath^<>#0 do
    begin
    AName:=DecodeTokenW(pPath,PathDelimiters,WideChar(0),False);
    AItem:=AParent.ItemByName(AName);
    if Assigned(AItem) then
      AParent:=AItem
    else
      Break;
    end;
  if AParent=AItem then
    Result:=AParent
  else
    Result:=nil;
  end
else
  Result:=Self;
end;

function TQXMLNode.ItemByRegex(const ARegex: QStringW; AList: TQXMLNodeList;
  ANest: Boolean): Integer;
var
  ANode:TQXMLNode;
{$IFDEF QDAC_UNICODE}
  APcre:TPerlRegEx;
{$ENDIF}
  function InternalFind(AParent:TQXMLNode):Integer;
  var
    I:Integer;
  begin
  Result:=0;
  for I := 0 to AParent.Count-1 do
    begin
    ANode:=AParent.Items[I];
    {$IFDEF QDAC_UNICODE}
    APcre.Subject:=ANode.Name;
    if APcre.Match then
    {$ELSE}
    if ANode.Name=ARegex then
    {$ENDIF}
      begin
      AList.Add(ANode);
      Inc(Result);
      end;
    if ANest then
      Inc(Result,InternalFind(ANode));
    end;
  end;
begin
{$IFDEF QDAC_UNICODE}
APcre:=TPerlRegex.Create;
try
  APcre.RegEx:=ARegex;
  APcre.Compile;
  Result:=InternalFind(Self);
finally
  FreeObject(APcre);
end;
{$ELSE}
raise Exception.Create(Format(SNotSupport,['ItemByRegex']));
{$ENDIF}
end;

function TQXMLNode.ItemWithAttrValue(const APath, AttrName,
  AttrValue: QStringW): TQXMLNode;
var
  ANode:TQXMLNode;
  I:Integer;
  Attr:TQXMLAttr;
  AFound:Boolean;
begin
Result:=nil;
ANode:=ItemByPath(APath);
if Assigned(ANode) then
  begin
  I:=ANode.ItemIndex;
  while I<ANode.Parent.Count do
    begin
    ANode:=ANode.Parent[I];
    Attr:=ANode.Attrs.ItemByName(AttrName);
    if Attr<>nil then
      begin
      if Length(Attr.Value)=Length(AttrValue) then
        begin
        if XMLCaseSensitive then
          AFound:=Attr.Value=AttrValue
        else
          AFound:=StartWithW(PQCharW(Attr.Value),PQCharW(AttrValue),True);
        if AFound then
          begin
          Result:=ANode;
          Break;
          end;
        end;
      end;
    end;
  end;
end;

procedure TQXMLNode.LoadFromFile(AFileName: QStringW;AEncoding:TTextEncoding);
var
  AStream:TFileStream;
begin
AStream:=TFileStream.Create(AFileName,fmOpenRead or fmShareDenyWrite);
try
  LoadFromStream(AStream);
finally
  FreeObject(AStream);
end;
end;

procedure TQXMLNode.LoadFromStream(AStream: TStream;AEncoding:TTextEncoding);
var
  S:QStringW;
  procedure DetectXMLEncoding;
  //����ͨ��xml��ͷ���������ж�XML�ļ��ı��룬���δ���壬��ͨ��LoadText���ж�
  var
    APos:Int64;
    S:TBytes;
    I:Integer;
  const
    UTF8Code:array[0..4] of Byte=($55,$54,$46,$2D,$38);//UTF8�ı��봮��ASCII��
    UTF16LECode:array[0..11] of Byte=($55,$00,$54,$00,$46,$00,$2D,$00,$31,$00,$36,$00);
    UTF16BECode:array[0..11] of Byte=($00,$55,$00,$54,$00,$46,$00,$2D,$00,$31,$00,$36);
  begin
  APos:=AStream.Position;
  SetLength(S,1024);//��ȡǰ1024���ֽ����ж�
  AStream.Read((@S[0])^,1024);
  //BOM?
  if (S[0]=$EF) and (S[1]=$BB) and (S[2]=$BF) then
    begin
    AEncoding:=teUtf8;
    AStream.Position:=APos+3;
    end
  else if (S[0]=$FF) and (S[1]=$FE) then
    begin
    AEncoding:=teUnicode16LE;
    AStream.Position:=APos+2;
    end
  else if (S[0]=$FE) and (S[1]=$FF) then
    begin
    AEncoding:=teUnicode16BE;
    AStream.Position:=APos+2;
    end
  else //����xmlͷ��,����UTF-8��UTF-16��UTF-16BE
    begin
    I:=0;
    AStream.Position:=APos;
    while I<1024 do
      begin
      if (S[I]=0) and (S[I+1]=$55) then
        begin
        if CompareMem(@S[I],@UTF16BECode[0],12) then
          begin
          AEncoding:=teUnicode16BE;
          Break;
          end;
        end
      else if S[I]=$55 then
        begin
        if CompareMem(@S[I],@Utf8Code[0],5) then
          begin
          AEncoding:=teUTF8;
          Break;
          end
        else if CompareMem(@S[I],@UTF16LECode[0],12) then
          begin
          AEncoding:=teUnicode16LE;
          Break;
          end;
        end;
      Inc(I);
      end;
    end;
  end;
begin
if AEncoding=teUnknown then
  DetectXMLEncoding;
S:=LoadTextW(AStream,AEncoding);
Parse(S);
end;

procedure TQXMLNode.Parse(const s: QStringW);
begin
Parse(PQCharW(s),Length(s));
end;

procedure TQXMLNode.ParseBlock(AStream: TStream; AEncoding: TTextEncoding);
var
  AMS:TMemoryStream;
  procedure ParseUCS2;
  var
    c:QCharW;
    ATagStart,ACharSize:Integer;
    ATagName,ATag:QStringW;
    ps,p:PQCharW;
  const
    XMLTagNameEnd:PWideChar=' '#9#10#13'/>';
  begin
  //���ұ�ǩ��ʼ������¼��ǩ������
  repeat
    AStream.ReadBuffer(c,SizeOf(QCharW));
    AMS.WriteBuffer(c,SizeOf(QCharW));
    until c='<';
  ATagStart:=AMS.Position-2;
  //��ȡTag����
  repeat
    AStream.Read(c,SizeOf(QCharW));
    AMS.WriteBuffer(c,SizeOf(QCharW));
  until c='>';
  ATag:=StrDupW(PQCharW(AMS.Memory),ATagStart,(AMS.Position-ATagStart) shr 1);
  ps:=PQCharW(ATag);
  if StartWithW(ps,'<?xml',true) then
    begin
    AMS.Size:=0;
    ParseUCS2;
    end
  else if ps[1]<>'!' then//��ע�ͣ�CDATA��DTD
    begin
    p:=ps;
    while not CharInW(p,XMLTagNameEnd,@ACharSize) do
      Inc(p);
    ATagName:=StrDupW(ps,1,p-ps-1);
    //����Ƿ��Ƕ̱�ǩ<xxx />
    if StartWithW(ps+Length(ATag)-2,'/>',false) then
      DoParse(PQCharW(ATag))
    else
      begin
      //�ظ�ֱ���ҵ�</ATagName>ֹ
      ATagStart:=0;
      ATagName:='</'+ATagName+'>';
      repeat
        AStream.ReadBuffer(c,SizeOf(QCharW));
        AMS.WriteBuffer(c,SizeOf(QCharW));
        if c='<' then
          ATagStart:=AMS.Position-2
        else if ATagStart<>0 then
          begin
          if AMS.Position-ATagStart=(Length(ATagName) shl 1) then
            begin
            if StartWithW(PWideChar(AMS.Memory)+(ATagStart shr 1),PQCharW(ATagName),false) then
              begin
              //OK,Found Close
              c:=#0;
              AMS.Write(c,sizeof(QCharW));
              DoParse(AMS.Memory);
              Exit;
              end
            else
              ATagStart:=0;
            end;
          end;
      until 1>2;
      end;
    end
  else//ע�ͣ�CDATA��DocType
    begin
    //DTD,����
    if StartWithW(ps,'<!DOCTYPE',false) or
      StartWithW(ps,'<!ELEMENT',false) or
      StartWithW(ps,'<!ATTLIST',false) then
      begin
      AMS.Size:=0;
      ParseUCS2;
      end
    else
      DoParse(PQCharW(ATag));
    end;
  end;

 
  procedure ParseUtf8;
  var
    c:QCharA;
    ATagStart,ACharSize:Integer;
    ATagName,ATag:QStringA;
    ps,p:PQCharA;
  const
    XMLTagNameEnd:array [0..5] of QCharA=($9,$A,$D,$20,$2F,$3E);
    XMLTagStart:QCharA=$3C;
    XMLTagEnd:QCharA=$3E;
    XMLTagClose:array[0..1] of QCharA=($2F,$3E);// />
    XMLDeclare:array [0..4] of QCharA=($3C,$3F,$78,$6D,$6C);//<?xml
    XMLComment:QCharA=$21;
    DTDDocType:array [0..8] of QCharA=(Ord('<'),Ord('!'),Ord('D'),Ord('O'),Ord('C'),Ord('T'),Ord('Y'),Ord('P'),Ord('E'));
    DTDElement:array [0..8] of QCharA=(Ord('<'),Ord('!'),Ord('E'),Ord('L'),Ord('E'),Ord('M'),Ord('E'),Ord('N'),Ord('T'));
    DTDAttrList:array [0..8] of QCharA=(Ord('<'),Ord('!'),Ord('A'),Ord('T'),Ord('T'),Ord('L'),Ord('I'),Ord('S'),Ord('T'));
  begin
  //���ұ�ǩ��ʼ������¼��ǩ������
  repeat
    AStream.ReadBuffer(c,SizeOf(QCharA));
    AMS.WriteBuffer(c,SizeOf(QCharA));
    until c=XMLTagStart;
  ATagStart:=AMS.Position-1;
  //��ȡTag����
  repeat
    AStream.Read(c,SizeOf(QCharA));
    AMS.WriteBuffer(c,SizeOf(QCharA));
  until c=XMLTagEnd;
  ATag.From(PQCharA(AMS.Memory),ATagStart,(AMS.Position-ATagStart));
  ps:=PQCharA(ATag);
  p:=ps;
  Inc(p);
  if CompareMem(ps,@XMLDeclare[0],5) then
    begin
    AMS.Size:=0;
    ParseUTF8;
    end
  else if p^<>XMLComment then//��ע�ͣ�CDATA��DTD
    begin
    p:=ps;
    while not CharInA(p,XMLTagNameEnd,@ACharSize) do
      Inc(p);
    ATagName.Length:=IntPtr(p)-IntPtr(ps)+2;
    ATagName[0]:=XMLTagStart;
    ATagName[1]:=$2F;// </
    ATagName[ATagName.Length-1]:=XMLTagEnd;
    p:=PQCharA(ATagName);
    Inc(p,2);
    Inc(ps);
    Move(ps^,p^,ATagName.Length-3);
    //����Ƿ��Ƕ̱�ǩ<xxx />
    p:=ps;
    Inc(p,ATag.Length-1);
    if CompareMem(p,@XMLTagClose[0],2) then
      DoParse(PQCharW(QString.Utf8Decode(ATag)))
    else
      begin
      //�ظ�ֱ���ҵ�</ATagName>ֹ
      ATagStart:=0;
      repeat
        AStream.ReadBuffer(c,SizeOf(QCharA));
        AMS.WriteBuffer(c,SizeOf(QCharA));
        if c=XMLTagStart then
          ATagStart:=AMS.Position-1
        else if ATagStart<>0 then
          begin
          if AMS.Position-ATagStart=ATagName.Length then
            begin
            p:=PQCharA(AMS.Memory);
            Inc(p,ATagStart);
            if CompareMem(p,PQCharA(ATagName),ATagName.Length) then
              begin
              //OK,Found Close
              ATag.From(AMS.Memory,0,AMS.Size);
              DoParse(PQCharW(QString.Utf8Decode(ATag)));
              Exit;
              end
            else
              ATagStart:=0;
            end;
          end;
      until 1>2;
      end;
    end
  else//ע�ͣ�CDATA��DocType
    begin
    //DTD,����
    if CompareMem(ps,@DTDDocType[0],9) or
      CompareMem(ps,@DTDElement[0],9) or
      CompareMem(ps,@DTDAttrList[0],9) then
      begin
      AMS.Size:=0;
      ParseUtf8;
      end
    else
      DoParse(PQCharW(QString.Utf8Decode(ATag)));
    end;
  end;

begin
AMS:=TMemoryStream.Create;
try
  if AEncoding=teUtf8 then
    ParseUtf8
  else if AEncoding=teUnicode16LE then
    ParseUCS2
  else
    raise Exception.Create(SBadXMLEncoding);
finally
  AMS.Free;
end;
end;

procedure TQXMLNode.Parse(p: PQCharW; len: Integer);
  procedure ParseCopy;
  var
    S:QStringW;
  begin
  S:=StrDupX(p,len);
  p:=PQCharW(S);
  DoParse(p);
  end;
begin
Clear;
if (len>0) and (p[len]<>#0) then
  ParseCopy
else
  begin
  DoParse(p);
  end;
end;

procedure TQXMLNode.SaveToFile(AFileName: QStringW; AEncoding: TTextEncoding;
  AWriteBom: Boolean);
var
  AStream:TMemoryStream;
begin
AStream:=TMemoryStream.Create;
try
  SaveToStream(AStream,AEncoding,AWriteBOM);
  AStream.SaveToFile(AFileName);
finally
  FreeObject(AStream);
end;
end;

procedure TQXMLNode.SaveToStream(AStream: TStream; AEncoding: TTextEncoding;
  AWriteBom: Boolean);
var
  ABuilder:TQStringCatHelperW;
const
  XMLHeader:PQCharW='<?xml version="1.0" encoding="';
  UTF8Format:PQCharW='UTF-8"?>';
  UTF16Format:PQCharW='UTF-16"?>';
  XMLTagStart:PQCharW='<xml>';
  XMLTagEnd:PQCharW='</xml>';
begin
ABuilder:=TQStringCatHelperW.Create;
try
  ABuilder.Cat(XMLHeader,30);
  if AEncoding=teUTF8 then
    begin
    ABuilder.Cat(UTF8Format,8).Cat(SLineBreak);
    if Count<>1 then
      ABuilder.Cat(XMLTagStart,5).Cat(SLineBreak);
    InternalEncode(ABuilder,True,' ');
    if Count<>1 then
      ABuilder.Cat(XMLTagEnd,6);
    SaveTextU(AStream,QString.Utf8Encode(ABuilder.Value),AWriteBom)
    end
  else if AEncoding=teUnicode16LE then
    begin
    ABuilder.Cat(UTF16Format,9).Cat(SLineBreak);
    if Count<>1 then
      ABuilder.Cat(XMLTagStart,5).Cat(SLineBreak);
    InternalEncode(ABuilder,True,' ');
    if Count<>1 then
      ABuilder.Cat(XMLTagEnd,6);
    SaveTextW(AStream,ABuilder.Value,AWriteBom)
    end
  else
    raise Exception.Create(SBadXMLEncoding);
finally
  FreeObject(ABuilder);
end;
end;

procedure TQXMLNode.SetAsXML(const Value: QStringW);
begin
Clear;
Parse(Value);
end;

procedure TQXMLNode.SetCapacity(const Value: Integer);
begin
if not Assigned(FItems) then
  FItems:=TQXMLNodeList.Create;
FItems.Capacity:=Value;
end;

procedure TQXMLNode.SetName(const Value: QStringW);
  procedure ValidName;
  begin
  if not ValidXMLName(Value) then
    raise Exception.Create(SBadXMLName);
  end;
begin
if FName<>Value then
  begin
  if NodeType=xntNode then
    begin
    ValidName;
    FName := Value;
    FNameHash := 0;
    end
  else
    raise Exception.Create(SXMLNameNotSupport);
  end;
end;

procedure TQXMLNode.SetNodeType(const Value: TQXMLNodeType);
var
  S:QStringW;
begin
if FNodeType <> Value then
  begin
  if FNodeType=xntNode then
    begin
    S:=Text;//Nodeת��Ϊ��������ʱ,�ı����ݱ������������Ժ��ӽ�����Ϣ����ʧ
    if Value=xntComment then
      begin
      if not ValidXMLComment(S) then
        raise Exception.Create(SBadXMLComment);
      end
    else if Value=xntCData then
      begin
      if not ValidXMLCData(S) then
        raise Exception.Create(SBadXMLCData);
      end;
    Clear;
    FName:=S;
    end
  else if Value=xntNode then
    SetLength(FName,0)
  else
    begin
    if Value=xntComment then
      begin
      if not ValidXMLComment(FName) then
        raise Exception.Create(SBadXMLComment);
      end
    else if Value=xntCData then
      begin
      if not ValidXMLCData(FName) then
        raise Exception.Create(SBadXMLCData);
      end;
    end;
  FNodeType:=Value;
  end;
end;

procedure TQXMLNode.SetText(const Value: QStringW);
begin
if NodeType=xntNode then
  Parse(Value)
else if NodeType=xntComment then
  begin
  if not ValidXMLComment(Value) then
    raise Exception.Create(SBadXMLComment);
  FName:=Value;
  end
else if NodeType=xntCData then
  begin
  if not ValidXMLCData(Value) then
    raise Exception.Create(SBadXMLCData);
  FName:=Value;
  end
else//Textû���κ����ƣ�����ʱ����б�Ҫ��ת��
  FName:=Value;
end;

function TQXMLNode.TextByPath(const APath, ADefVal: QStringW): QStringW;
var
  ANode:TQXMLNode;
begin
ANode:=ItemByPath(APath);
if Assigned(ANode) then
  Result:=ANode.Text
else
  Result:=ADefVal;
end;

procedure TQXMLNode.ToObject(AObject: TObject);
  procedure AssignProp(AParent:TQXMLNode;AObj:TObject);
  var
    APropInfo:PPropInfo;
    I,AValIdx:Integer;
    AChild:TQXMLNode;
  begin
  if AObj=nil then
    Exit;
  for I := 0 to Count-1 do
    begin
    AChild:=AParent[I];
    APropInfo:=GetPropInfo(AObj,AChild.Name);
    if Assigned(APropInfo) then
      begin
      AValIdx:=AChild.Attrs.IndexOfName('value');
      if AValIdx<>-1 then
        begin
        case APropInfo.PropType^.Kind of
          tkChar:
            SetOrdProp(AObj,APropInfo,QString.AnsiEncode(AChild.Attrs[AValIdx].Value)[0]);
          tkWChar:
            SetOrdProp(AObj,APropInfo,PWord(PWideChar(AChild.Attrs[AValIdx].Value))^);
          tkInteger:
            SetOrdProp(AObj,APropInfo,StrToInt(AChild.Attrs[AValIdx].Value));
          tkClass:
            AChild.ToObject(TObject(GetOrdProp(AObj,APropInfo)));
          tkEnumeration:
            SetEnumProp(AObj,APropInfo,AChild.Attrs[AValIdx].Value);
          tkSet:
            SetSetProp(AObj,APropInfo,AChild.Attrs[AValIdx].Value);
          tkFloat:
            SetFloatProp(AObj,APropInfo,StrToFloat(AChild.Attrs[AValIdx].Value));
          tkMethod:
            {�󶨺�����ֵ��ʱ����};
          {$IFNDEF NEXTGEN}
          tkString, tkLString,tkWString:
            SetStrProp(AObj,APropInfo,AChild.Attrs[AValIdx].Value);
          {$ENDIF !NEXTGEN}
          {$IFDEF QDAC_UNICODE}
          tkUString:
            SetStrProp(AObj,APropInfo,AChild.Attrs[AValIdx].Value);
          {$ENDIF}
          tkVariant:
            {�������͵�������ʱ����
            SetVariantProp(AObj,APropInfo,AChild.AsVariant);};
          tkInt64:
            SetInt64Prop(AObj,APropInfo,StrToInt64(AChild.Attrs[AValIdx].Value));
          tkDynArray:
            begin
            {��̬�������͵�������ʱ����
            dynArray:=nil;
            DynArrayFromVariant(dynArray,AChild.AsVariant,APropInfo.PropType^);
            SetDynArrayProp(AObj,APropInfo,dynArray);}
            end;
        end;
        end;
      end;
    end;
  end;
begin
if Assigned(AObject) then
  AssignProp(Self,AObject);
end;
{$IFDEF QDAC_RTTI}
procedure TQXMLNode.ToRecord<T>(const ARecord:T);
begin
InternalToRecord(TypeInfo(T),@ARecord);
end;
{$ENDIF}
function TQXMLNode.ToString: string;
begin
Result:=Text;
end;

function TQXMLNode.XMLDecode(const S: QStringW): QStringW;
begin
Result:=XMLDecode(PQCharW(s),Length(S));
end;

function TQXMLNode.XMLDecode(const p: PQCharW; l: Integer): QStringW;
var
  ps,ws,pd:PQCharW;
  c:QCharW;
const
  EscapeEnd:PQCharW=';';
begin
SetLength(Result,l);
ps:=p;
pd:=PQCharW(Result);
while ps-p<l do
  begin
  if ps^='&' then
    begin
    ws:=ps;
    SkipUntilW(ps,EscapeEnd);
    if ps^=';' then
      begin
      Inc(ps);
      c:=PQCharW(HTMLUnescape(StrDupX(ws,ps-ws)))^;
      if c<>#0 then
        pd^:=c
      else
        raise Exception.Create(Format(SUnknownXMLEscape,[StrDupX(ws,ps-ws)]));
      Inc(pd);
      end
    else
      raise Exception.Create(SBadXMLEscape);
    end
  else
    begin
    pd^:=ps^;
    Inc(ps);
    Inc(pd);
    end;
  end;
SetLength(Result,pd-PQCharW(Result));
end;

function TQXMLNode.XMLEncode(const S: QStringW): QStringW;
var
  ps,pd:PQCharW;
  procedure StrCat(var d:PQCharW;s:PQCharW);
  begin
  while s^<>#0 do
    begin
    d^:=s^;
    Inc(d);
    Inc(s);
    end;
  end;
begin
{
&lt;	<	С��
&gt;	>	����
&amp;	&	�ͺ�
&apos;	'	������
&quot;	"	����
}
SetLength(Result,Length(S)*6);
ps:=PQCharW(S);
pd:=PQCharW(Result);
while ps^<>#0 do
  begin
  case ps^ of
    '<':StrCat(pd,'&lt;');
    '>':StrCat(pd,'&gt;');
    '&':StrCat(pd,'&amp;');
    '''':StrCat(pd,'&apos;');
    '"':StrCat(pd,'&quot;')
    else
      begin
      pd^:=ps^;
      Inc(pd);
      end;
  end;
  Inc(ps);
  end;
SetLength(Result,pd-PQCharW(Result));
end;
{ TQXMLAttr }

function TQXMLAttr.GetAsBoolean: Boolean;
begin
if not TryStrToBool(FValue,Result) then
  begin
  try
    Result:=(AsInt64<>0);
  except
    raise Exception.Create(SValueNotBoolean);
  end;
  end;
end;

function TQXMLAttr.GetAsDateTime: TDateTime;
begin
if not ParseDateTime(PQCharW(FValue),Result) then
  Result:=GetAsFloat;
end;

function TQXMLAttr.GetAsFloat: Extended;
var
  p:PQCharW;
begin
p:=PQCharW(FValue);
if not ParseNumeric(p,Result) then
  raise Exception.CreateFmt(SValueNotNumeric,[FValue]);
end;

function TQXMLAttr.GetAsInt64: Int64;
begin
Result:=Trunc(AsFloat);
end;

function TQXMLAttr.GetAsInteger: Integer;
begin
Result:=AsInt64;
end;

procedure TQXMLAttr.SetAsBoolean(const Value: Boolean);
begin
FValue:=BoolToStr(Value,true);
end;

procedure TQXMLAttr.SetAsDateTime(const Value: TDateTime);
begin

end;

procedure TQXMLAttr.SetAsFloat(const Value: Extended);
begin
FValue:=FloatToStr(Value);
end;

procedure TQXMLAttr.SetAsInt64(const Value: Int64);
begin
FValue:=IntToStr(Value);
end;

procedure TQXMLAttr.SetAsInteger(const Value: Integer);
begin
SetAsInt64(Value);
end;

procedure TQXMLAttr.SetName(const Value: QStringW);
begin
if FName <> Value then
  begin
  FName:=Value;
  FNameHash:=0;
  end;
end;

{ TQXMLAttrEnumerator }

constructor TQXMLAttrEnumerator.Create(AList: TQXMLAttrs);
begin
FList:=AList;
FIndex:=-1;
end;

function TQXMLAttrEnumerator.GetCurrent: TQXMLAttr;
begin
Result:=FList[FIndex];
end;

function TQXMLAttrEnumerator.MoveNext: Boolean;
begin
if FIndex<FList.Count-1 then
  begin
  Inc(FIndex);
  Result:=True;
  end
else
  Result:=False;
end;

{ TQXMLNodeEnumerator }

constructor TQXMLNodeEnumerator.Create(AList: TQXMLNode);
begin
inherited Create;
FList:=AList;
FIndex:=-1;
end;

function TQXMLNodeEnumerator.GetCurrent: TQXMLNode;
begin
Result:=FList[FIndex];
end;

function TQXMLNodeEnumerator.MoveNext: Boolean;
begin
if FIndex+1<FList.Count then
  begin
  Inc(FIndex);
  Result:=True;
  end
else
  Result:=False;
end;

{ TQHashedXMLNode }

function TQHashedXMLNode.AddNode(const AName: QStringW): TQXMLNode;
begin
Result:=inherited AddNode(AName);
Result.FNameHash:=HashOf(PQCharW(AName),Length(AName) shl 1);
FHashTable.Add(Pointer(Count-1),Result.FNameHash);
end;

procedure TQHashedXMLNode.Clear;
begin
inherited;
FHashTable.Clear;
end;

constructor TQHashedXMLNode.Create;
begin
inherited;
FHashTable:=TQHashTable.Create();
FHashTable.AutoSize:=True;
end;

function TQHashedXMLNode.CreateNode: TQXMLNode;
begin
if Assigned(OnQXMLNodeCreate) then
  Result:=OnQXMLNodeCreate
else
  Result:=TQHashedXMLNode.Create;
end;

procedure TQHashedXMLNode.Delete(AIndex: Integer);
var
  AItem:TQXMLNode;
begin
AItem:=Items[AIndex];
FHashTable.Delete(Pointer(AIndex),AItem.FNameHash);
inherited;
end;

destructor TQHashedXMLNode.Destroy;
begin
inherited;
FreeObject(FHashTable);
end;

function TQHashedXMLNode.IndexOf(const AName: QStringW): Integer;
var
  AIndex,AHash:Integer;
  AList:PQHashList;
  AItem:TQXMLNode;
begin
AHash:=HashOf(PQCharW(AName),Length(AName) shl 1);
AList:=FHashTable.FindFirst(AHash);
Result:=-1;
while AList<>nil do
  begin
  AIndex:=Integer(AList.Data);
  AItem:=Items[AIndex];
  if AItem.Name=AName then
    begin
    Result:=AIndex;
    Break;
    end
  else
    AList:=FHashTable.FindNext(AList);
  end;
end;

initialization
  XMLDateFormat:='yyyy-mm-dd';
  XMLDateTimeFormat:='yyyy-mm-dd''T''hh:nn:ss.zzz';
  XMLTimeFormat:='hh:nn:ss.zzz';
  XMLCaseSensitive:=True;
  XMLTagShortClose:=True;
  OnQXMLNodeCreate:=nil;
  OnQXMLNodeFree:=nil;
end.
