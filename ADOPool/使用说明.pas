/////////////////////��ʼ��
//�������ӳ���
FPoolGroup := TADOConnectionPoolGroup.Create();

//��������<��ʼ�����ӳ�>
TADOPoolGroupTools.loadconfig(FPoolGroup);
//�����ļ�
//{
//   "main":
//    {
//		"host": "192.168.1.2",
//		"user": "sa",
//		"password": "efsa",
//		"database": "EF_DATA"
//    },
//   "sys":
//    {
//		"host": "192.168.7.55",
//		  "user": "sa",
//		  "password": "efsa",
//		  "database": "EF_SYS"
//    },
//}


////////////ʹ�����ӳ�
var
  lvADOPool:TADOConnectionPool;
  lvConn:TADOConnection;
begin
  //���ӳ����л�ȡһ�����ӳ�
  lvADOPool := FPoolGroup.getPool('sys');
 
  //���ӳ��л�ȡһ������
  lvConn := TADOConnection(lvADOPool.beginUseObject);

  //�黹һ������
  lvADOPool.endUseObject(lvConn);
