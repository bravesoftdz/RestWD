unit uRESTDWPoolerDB;

{$I uRESTDW.inc}

{
  REST Dataware vers�o CORE.
  Criado por XyberX (Gilbero Rocha da Silva), o REST Dataware tem como objetivo o uso de REST/JSON
 de maneira simples, em qualquer Compilador Pascal (Delphi, Lazarus e outros...).
  O REST Dataware tamb�m tem por objetivo levar componentes compat�veis entre o Delphi e outros Compiladores
 Pascal e com compatibilidade entre sistemas operacionais.
  Desenvolvido para ser usado de Maneira RAD, o REST Dataware tem como objetivo principal voc� usu�rio que precisa
 de produtividade e flexibilidade para produ��o de Servi�os REST/JSON, simplificando o processo para voc� programador.

 Membros do Grupo :

 XyberX (Gilberto Rocha)    - Admin - Criador e Administrador do CORE do pacote.
 Ivan Cesar                 - Admin - Administrador do CORE do pacote.
 Joanan Mendon�a Jr. (jlmj) - Admin - Administrador do CORE do pacote.
 Giovani da Cruz            - Admin - Administrador do CORE do pacote.
 Alexandre Abbade           - Admin - Administrador do desenvolvimento de DEMOS, coordenador do Grupo.
 Alexandre Souza            - Admin - Administrador do Grupo de Organiza��o.
 Anderson Fiori             - Admin - Gerencia de Organiza��o dos Projetos
 Mizael Rocha               - Member Tester and DEMO Developer.
 Fl�vio Motta               - Member Tester and DEMO Developer.
 Itamar Gaucho              - Member Tester and DEMO Developer.
 Ico Menezes                - Member Tester and DEMO Developer.
}


interface

uses SysUtils,  Classes,
     DB,        uDWPoolerMethod,
     uRESTDWMasterDetailData, uDWConstsData, uDWAbout,
     uDWMassiveBuffer,        SyncObjs, uDWJSONTools,
     uDWResponseTranslator,   uSystemEvents, uRESTDWBase
     // ReOrganiza��o das diretivas em 15/10/2018 - Thiago Pedro
     {$IFDEF FPC}
       {$IFDEF DWMEMTABLE}
       , uDWDataset
       {$ENDIF}
       {$IFDEF LAZDRIVER}
        memds
       {$ENDIF}
       , uDWConsts, uDWJSON, uDWJSONObject, Controls, Variants, Forms;
     {$ELSE}
       {$IFDEF CLIENTDATASET}
        ,  DBClient
       {$ENDIF}
       {$IFDEF RESJEDI}
       , JvMemoryDataset
       {$ENDIF}
       {$IFDEF RESTKBMMEMTABLE}
       , kbmmemtable
       {$ENDIF}
       {$IFDEF DWMEMTABLE}
       , uDWDataset
       {$ENDIF}
       {$IF CompilerVersion > 21} // Delphi 2010 pra cima
          {$IF Defined(HAS_FMX)}  // Inclu�do inicialmente para iOS/Brito
          , System.json,  uDWJSONObject
          , FMX.Platform, FMX.Types,   System.UITypes, FMX.Forms //FMX
          {$ELSE}
            {$IFDEF WINFMX} // FireMonkey Windows
            , FMX.Platform, FMX.Types, System.UITypes, FMX.Forms
            {$ENDIF}
            , uDWJSON,  uDWJSONObject, vcl.Controls, vcl.Forms
          {$IFEND}
          {$IFDEF RESTFDMEMTABLE}
          , FireDAC.Stan.Intf,    FireDAC.Stan.Option,  FireDAC.Stan.Param
          , FireDAC.Stan.Error,   FireDAC.DatS,         FireDAC.Phys.Intf
          , FireDAC.DApt.Intf,    FireDAC.Comp.DataSet, FireDAC.Comp.Client
          {$ENDIF}
       {$ELSE}
       , uDWJSON, uDWJSONObject, Controls, Forms
       {$IFEND}
       , Variants, uDWConsts;
     {$ENDIF}

Type
 TOnEventDB               = Procedure (DataSet            : TDataSet)        Of Object;
 TOnAfterScroll           = Procedure (DataSet            : TDataSet)        Of Object;
 TOnAfterOpen             = Procedure (DataSet            : TDataSet)        Of Object;
 TOnAfterClose            = Procedure (DataSet            : TDataSet)        Of Object;
 TOnCalcFields            = Procedure (DataSet            : TDataSet)        Of Object;
 TOnAfterCancel           = Procedure (DataSet            : TDataSet)        Of Object;
 TOnAfterInsert           = Procedure (DataSet            : TDataSet)        Of Object;
 TOnBeforeDelete          = Procedure (DataSet            : TDataSet)        Of Object;
 TOnBeforePost            = Procedure (DataSet            : TDataSet)        Of Object;
 TOnAfterPost             = Procedure (DataSet            : TDataSet)        Of Object;
 TOnEventConnection       = Procedure (Sucess             : Boolean;
                                       Const Error        : String)          Of Object;
 TOnEventBeforeConnection = Procedure (Sender             : TComponent)      Of Object;
 TOnEventTimer            = Procedure                                        Of Object;
 TBeforeGetRecords        = Procedure (Sender             : TObject;
                                       Var OwnerData      : OleVariant)      Of Object;
 TOnPrepareConnection     = Procedure (Var ConnectionDefs : TConnectionDefs) Of Object;

Type
 TFieldDefinition = Class
 Public
  FieldName : String;
  DataType  : TFieldType;
  Size,
  Precision : Integer;
  Required  : Boolean;
End;

Type
 TFieldsList = Array of TFieldDefinition;

Type
 TTimerData = Class(TThread)
 Private
  FValue : Integer;          //Milisegundos para execu��o
  FLock  : TCriticalSection; //Se��o cr�tica
  vEvent : TOnEventTimer;    //Evento a ser executado
 Public
  Property OnEventTimer : TOnEventTimer Read vEvent Write vEvent; //Evento a ser executado
 Protected
  Constructor Create(AValue: Integer; ALock: TCriticalSection);   //Construtor do Evento
  Procedure   Execute; Override;                                  //Procedure de Execu��o autom�tica
End;

Type
 TAutoCheckData = Class(TPersistent)
 Private
  vAutoCheck : Boolean;                            //Se tem Autochecagem
  vInTime    : Integer;                            //Em milisegundos o timer
  Timer      : TTimerData;                         //Thread do temporizador
  vEvent     : TOnEventTimer;                      //Evento a executar
  FLock      : TCriticalSection;                   //CriticalSection para execu��o segura
  Procedure  SetState(Value : Boolean);            //Ativa ou desativa a classe
  Procedure  SetInTime(Value : Integer);           //Diz o Timeout
  Procedure  SetEventTimer(Value : TOnEventTimer); //Seta o Evento a ser executado
 Public
  Constructor Create; //Cria o Componente
  Destructor  Destroy;Override;//Destroy a Classe
  Procedure   Assign(Source : TPersistent); Override;
 Published
  Property AutoCheck    : Boolean       Read vAutoCheck Write SetState;      //Se tem Autochecagem
  Property InTime       : Integer       Read vInTime    Write SetInTime;     //Em milisegundos o timer
  Property OnEventTimer : TOnEventTimer Read vEvent     Write SetEventTimer; //Evento a executar
End;

 TProxyOptions = Class(TPersistent)
 Private
  vServer,              //Servidor Proxy na Rede
  vLogin,               //Login do Servidor Proxy
  vPassword : String;   //Senha do Servidor Proxy
  vPort     : Integer;  //Porta do Servidor Proxy
 Public
  Constructor Create;
  Procedure   Assign(Source : TPersistent); Override;
 Published
  Property Server   : String  Read vServer   Write vServer;   //Servidor Proxy na Rede
  Property Port     : Integer Read vPort     Write vPort;     //Porta do Servidor Proxy
  Property Login    : String  Read vLogin    Write vLogin;    //Login do Servidor Proxy
  Property Password : String  Read vPassword Write vPassword; //Senha do Servidor Proxy
End;

Type
 TClientConnectionDefs = Class(TPersistent)
 Private
  vActive : Boolean;
  vConnectionDefs : TConnectionDefs;
  Procedure SetClientConnectionDefs(Value : Boolean);
  Procedure SetConnectionDefs(Value : TConnectionDefs);
 Public
  Constructor Create; //Cria o Componente
  Destructor  Destroy;Override;//Destroy a Classe
 Published
  Property Active         : Boolean         Read vActive         Write SetClientConnectionDefs;
  Property ConnectionDefs : TConnectionDefs Read vConnectionDefs Write SetConnectionDefs;
End;

Type
 TRESTDWDataBase = Class(TDWComponent)
 Private
  {$IFDEF FPC}
  vDatabaseCharSet     : TDatabaseCharSet;
  {$ENDIF}
  vOnWork              : TOnWork;
  vOnWorkBegin         : TOnWorkBegin;
  vOnWorkEnd           : TOnWorkEnd;
  vOnStatus            : TOnStatus;
  vAccessTag,
  vWelcomeMessage,
  vLogin,                                            //Login do Usu�rio caso haja autentica��o
  vPassword,                                         //Senha do Usu�rio caso haja autentica��o
  vRestWebService,                                   //Rest WebService para consultas
  vRestURL,                                          //URL do WebService REST
  vRestModule,                                       //Classe Principal do Servidor a ser utilizada
  vMyIP,                                             //Meu IP vindo do Servidor
  vRestPooler           : String;                     //Qual o Pooler de Conex�o do DataSet
  vPoolerPort           : Integer;                    //A Porta do Pooler
  vClientConnectionDefs : TClientConnectionDefs;
  vProxy                : Boolean;                    //Diz se tem servidor Proxy
  vProxyOptions         : TProxyOptions;              //Se tem Proxy diz quais as op��es
  vEncodeStrings,
  vCompression,                                      //Se Vai haver compress�o de Dados
  vConnected           : Boolean;                    //Diz o Estado da Conex�o
  vOnEventConnection   : TOnEventConnection;         //Evento de Estado da Conex�o
  vOnBeforeConnection  : TOnEventBeforeConnection;   //Evento antes de Connectar o Database
  vAutoCheckData       : TAutoCheckData;             //Autocheck de Conex�o
  vTimeOut             : Integer;
  vEncoding            : TEncodeSelect;              //Enconding se usar CORS usar UTF8 - Alexandre Abade
  vContentex           : String;                    //RestContexto - Alexandre Abade
  vStrsTrim,
  vStrsEmpty2Null,
  vStrsTrim2Len        : Boolean;
  vParamCreate         : Boolean;
  vTypeRequest         : Ttyperequest;
  Procedure SetOnWork     (Value : TOnWork);
  Procedure SetOnWorkBegin(Value : TOnWorkBegin);
  Procedure SetOnWorkEnd  (Value : TOnWorkEnd);
  Procedure SetOnStatus   (Value : TOnStatus);
  Procedure SetConnection (Value : Boolean);          //Seta o Estado da Conex�o
  Procedure SetRestPooler (Value : String);           //Seta o Restpooler a ser utilizado
  Procedure SetPoolerPort (Value : Integer);          //Seta a Porta do Pooler a ser usada
  Function  TryConnect : Boolean;                    //Tenta Conectar o Servidor para saber se posso executar comandos
  Procedure ExecuteCommand(Var SQL          : TStringList;
                           Var Params       : TParams;
                           Var Error        : Boolean;
                           Var MessageError : String;
                           Var Result       : TJSONValue;
                           Execute          : Boolean = False;
                           RESTClientPooler : TRESTClientPooler = Nil);
  Procedure ExecuteProcedure(ProcName         : String;
                             Params           : TParams;
                             Var Error        : Boolean;
                             Var MessageError : String);
  Function InsertMySQLReturnID(Var SQL          : TStringList;
                               Var Params       : TParams;
                               Var Error        : Boolean;
                               Var MessageError : String;
                               RESTClientPooler : TRESTClientPooler = Nil) : Integer;
  Procedure ApplyUpdates  (Massive          : TMassiveDatasetBuffer;
                           SQL              : TStringList;
                           Var Params       : TParams;
                           Var Error        : Boolean;
                           Var MessageError : String;
                           Var Result       : TJSONValue;
                           RESTClientPooler : TRESTClientPooler = Nil);Overload;
  Function  GetStateDB : Boolean;
  Procedure SetMyIp(Value : String);
 protected
   //Magno
   procedure Loaded; override;
 Public
  Function    GetServerEvents: TStringList;
  Function    GetRestPoolers : TStringList;          //Retorna a Lista de DataSet Sources do Pooler
  Constructor Create(AOwner  : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                      //Destroy a Classe
  Procedure   Close;
  Procedure   Open;
  Procedure   ApplyUpdates(Var MassiveCache   : TDWMassiveCache;
                           Var   Error        : Boolean;
                           Var   MessageError : String);Overload;
  Procedure   OpenDatasets(Datasets           : Array of {$IFDEF FPC}TRESTDWClientSQLBase{$ELSE}TObject{$ENDIF};
                           Var   Error        : Boolean;
                           Var   MessageError : String);Overload;
  Property Connected            : Boolean                  Read GetStateDB            Write SetConnection;
 Published
  Property OnConnection         : TOnEventConnection       Read vOnEventConnection    Write vOnEventConnection; //Evento relativo a tudo que acontece quando tenta conectar ao Servidor
  Property OnBeforeConnect      : TOnEventBeforeConnection Read vOnBeforeConnection   Write vOnBeforeConnection; //Evento antes de Connectar o Database
  Property Active               : Boolean                  Read vConnected            Write SetConnection;      //Seta o Estado da Conex�o
  Property Compression          : Boolean                  Read vCompression          Write vCompression;       //Compress�o de Dados
  Property MyIP                 : String                   Read vMyIP                 Write SetMyIp;
  Property Login                : String                   Read vLogin                Write vLogin;             //Login do Usu�rio caso haja autentica��o
  Property Password             : String                   Read vPassword             Write vPassword;          //Senha do Usu�rio caso haja autentica��o
  Property Proxy                : Boolean                  Read vProxy                Write vProxy;             //Diz se tem servidor Proxy
  Property ProxyOptions         : TProxyOptions            Read vProxyOptions         Write vProxyOptions;      //Se tem Proxy diz quais as op��es
  Property PoolerService        : String                   Read vRestWebService       Write vRestWebService;    //Host do WebService REST
  Property PoolerURL            : String                   Read vRestURL              Write vRestURL;           //URL do WebService REST
  Property PoolerPort           : Integer                  Read vPoolerPort           Write SetPoolerPort;      //A Porta do Pooler do DataSet
  Property PoolerName           : String                   Read vRestPooler           Write SetRestPooler;      //Qual o Pooler de Conex�o ligado ao componente
  Property RestModule           : String                   Read vRestModule           Write vRestModule;        //Classe do Servidor REST Principal
  Property StateConnection      : TAutoCheckData           Read vAutoCheckData        Write vAutoCheckData;     //Autocheck da Conex�o
  Property RequestTimeOut       : Integer                  Read vTimeOut              Write vTimeOut;           //Timeout da Requisi��o
  Property EncodeStrings        : Boolean                  Read vEncodeStrings        Write vEncodeStrings;
  Property Encoding             : TEncodeSelect            Read vEncoding             Write vEncoding;          //Encoding da string
  Property Context              : string                   Read vContentex            Write vContentex;         //Contexto
  Property StrsTrim             : Boolean                  Read vStrsTrim             Write vStrsTrim;
  Property StrsEmpty2Null       : Boolean                  Read vStrsEmpty2Null       Write vStrsEmpty2Null;
  Property StrsTrim2Len         : Boolean                  Read vStrsTrim2Len         Write vStrsTrim2Len;
  Property WelcomeMessage       : String                   Read vWelcomeMessage       Write vWelcomeMessage;
  Property OnWork               : TOnWork                  Read vOnWork               Write SetOnWork;
  Property OnWorkBegin          : TOnWorkBegin             Read vOnWorkBegin          Write SetOnWorkBegin;
  Property OnWorkEnd            : TOnWorkEnd               Read vOnWorkEnd            Write SetOnWorkEnd;
  Property OnStatus             : TOnStatus                Read vOnStatus             Write SetOnStatus;
  {$IFDEF FPC}
  Property DatabaseCharSet      : TDatabaseCharSet         Read vDatabaseCharSet      Write vDatabaseCharSet;
  {$ENDIF}
  Property AccessTag            : String                   Read vAccessTag            Write vAccessTag;
  Property ParamCreate          : Boolean                  Read vParamCreate          Write vParamCreate;
  Property TypeRequest          : TTypeRequest             Read vTypeRequest          Write vTypeRequest       Default trHttp;
  Property ClientConnectionDefs : TClientConnectionDefs    Read vClientConnectionDefs Write vClientConnectionDefs;
End;

Type
 TRESTDWClientSQL     = Class(TRESTDWClientSQLBase) //Classe com as funcionalidades de um DBQuery
 Protected
  vBookmark            : Integer;
  vActive,
  vInactive            : Boolean;
 Private
  vOldState             : TDatasetState;
  vOldCursor,
  vActionCursor         : TCursor;
  vDWResponseTranslator : TDWResponseTranslator;
  vMasterDetailItem     : TMasterDetailItem;
  vFieldsList           : TFieldsList;
//  vRESTClientPooler    : TRESTClientPooler;
  vMassiveCache         : TDWMassiveCache;
  vOldStatus            : TDatasetState;
  vDataSource           : TDataSource;
  vOnAfterScroll        : TOnAfterScroll;
  vOnAfterOpen          : TOnAfterOpen;
  vOnAfterClose         : TOnAfterClose;
  vOnCalcFields         : TDatasetEvents;
//  OldData              : TRESTDWClientSQLBase;
  vNewRecord,
  vBeforeOpen,
  vOnBeforeScroll,
  vBeforeEdit,
  vBeforeInsert,
  vBeforePost,
  vBeforeDelete,
  vAfterDelete, //Magno
  vAfterEdit,
  vAfterInsert,
  vAfterPost,
  vAfterCancel          : TDatasetEvents;
  vReflectChanges,
  vInDesignEvents,
  vAutoCommitData,
  vAutoRefreshAfterCommit,
  vInBlockEvents        : Boolean;
  vOldRecordCount,
  vDatapacks,
  vJsonCount,
//  vMaxBufferRegs,
  vParamCount,
  vActualRec            : Integer;
  vActualJSON,
  vOldSQL,
//  vLastBuffer,
  vMasterFields,
  vUpdateTableName      : String;                            //Tabela que ser� feito Update no Servidor se for usada Reflex�o de Dados
  vInitDataset,
  vInternalLast,
  vFiltered,
  vActiveCursor,
  vOnOpenCursor,
  vCacheUpdateRecords,
  vReadData,
  vOnPacks,
  vCascadeDelete,
  vBeforeClone,
  vDataCache,                                               //Se usa cache local
  vConnectedOnce,                                           //Verifica se foi conectado ao Servidor
  vCommitUpdates,
  vCreateDS,
  GetNewData,
  vErrorBefore,
  vNotRepage            : Boolean;                           //Estado do Dataset
  vSQL                  : TStringList;                       //SQL a ser utilizado na conex�o
  vParams               : TParams;                           //Parametros de Dataset
  vCacheDataDB          : TDataset;                          //O Cache de Dados Salvo para utiliza��o r�pida
  vOnGetDataError       : TOnEventConnection;                //Se deu erro na hora de receber os dados ou n�o
  vRESTDataBase         : TRESTDWDataBase;                   //RESTDataBase do Dataset
  //vOnAfterDelete       : TDataSetNotifyEvent;  //Magno
  FieldDefsUPD          : TFieldDefs;
  vMasterDataSet        : TRESTDWClientSQL;
  vMasterDetailList     : TMasterDetailList;                 //DataSet MasterDetail Function
  vMassiveDataset       : TMassiveDataset;
  {$IFDEF FPC}
  {$IFDEF LAZDRIVER}
  procedure CloneDefinitions(Source  : TMemDataset;
                             aSelf   : TMemDataset);
  {$ENDIF}
  {$IFDEF DWMEMTABLE}
  Procedure CloneDefinitions(Source  : TDWMemtable;
                             aSelf   : TDWMemtable); //Fields em Defini��es
  {$ENDIF}

  {$ELSE}
  {$IFDEF CLIENTDATASET}
  Procedure  CloneDefinitions    (Source  : TClientDataset;
                                  aSelf   : TClientDataset); //Fields em Defini��es
  {$ENDIF}
  {$IFDEF RESJEDI}
  Procedure  CloneDefinitions    (Source  : TJvMemoryData;
                                  aSelf   : TJvMemoryData); //Fields em Defini��es
  {$ENDIF}
  {$IFDEF RESTKBMMEMTABLE}
  Procedure  CloneDefinitions    (Source  : TKbmMemtable;
                                  aSelf   : TKbmMemtable); //Fields em Defini��es
  {$ENDIF}
  {$IFDEF RESTFDMEMTABLE}
  Procedure  CloneDefinitions    (Source  : TFdMemtable;
                                  aSelf   : TFdMemtable); //Fields em Defini��es
  {$ENDIF}
  {$IFDEF DWMEMTABLE}
  Procedure  CloneDefinitions    (Source  : TDWMemtable;
                                  aSelf   : TDWMemtable); //Fields em Defini��es
  {$ENDIF}
  {$ENDIF}
  Procedure   OnChangingSQL      (Sender  : TObject);       //Quando Altera o SQL da Lista
  Procedure   OnBeforeChangingSQL(Sender  : TObject);
  Procedure   SetActiveDB        (Value   : Boolean);       //Seta o Estado do Dataset
  Procedure   SetSQL             (Value   : TStringList);   //Seta o SQL a ser usado
  Procedure   CreateParams;                                 //Cria os Parametros na lista de Dataset
  Procedure   SetDataBase        (Value   : TRESTDWDataBase); //Diz o REST Database
  Function    GetData(DataSet   : TJSONValue = Nil) : Boolean;//Recebe os Dados da Internet vindo do Servidor REST
  Procedure   SetUpdateTableName (Value   : String);        //Diz qual a tabela que ser� feito Update no Banco
  Procedure   OldAfterPost       (DataSet : TDataSet);      //Eventos do Dataset para realizar o AfterPost
  Procedure   OldAfterDelete     (DataSet : TDataSet);      //Eventos do Dataset para realizar o AfterDelete
  Procedure   SetMasterDataSet     (Value : TRESTDWClientSQL);
  Procedure   SetCacheUpdateRecords(Value : Boolean);
  Function    FirstWord          (Value     : String) : String;
  Procedure   ProcBeforeScroll   (DataSet   : TDataSet);
  Procedure   ProcAfterScroll    (DataSet   : TDataSet);
  Procedure   ProcBeforeOpen     (DataSet   : TDataSet);
  Procedure   ProcAfterOpen      (DataSet   : TDataSet);
  Procedure   ProcAfterClose     (DataSet   : TDataSet);
  Procedure   ProcBeforeInsert   (DataSet   : TDataSet);
  Procedure   ProcAfterInsert    (DataSet   : TDataSet);
  Procedure   ProcNewRecord      (DataSet   : TDataSet);
  Procedure   ProcBeforeDelete   (DataSet   : TDataSet); //Evento para Delta
  Procedure   ProcBeforeEdit     (DataSet   : TDataSet); //Evento para Delta
  Procedure   ProcAfterEdit      (DataSet   : TDataSet);
  Procedure   ProcBeforePost     (DataSet   : TDataSet); //Evento para Delta
  Procedure   ProcAfterCancel    (DataSet   : TDataSet);
  Procedure   ProcCalcFields     (DataSet: TDataSet);
  procedure   CreateMassiveDataset;
  procedure   SetParams(const Value: TParams);
  Procedure   CleanFieldList;
  Procedure   GetTmpCursor;
  Procedure   SetCursor;
  Procedure   SetOldCursor;
  Procedure   ChangeCursor(OldCursor : Boolean = False);
  Function    GetRecordCount : Integer;Override;
  Procedure   SetDatapacks(Value : Integer);
  Procedure   SetReflectChanges(Value : Boolean);
 Public
  //M�todos
  Function    OpenJson(JsonValue : String = '') : Boolean;     //Recebe os Dados da Internet vindo do Servidor REST
  Procedure   SetInBlockEvents(const Value: Boolean);
  Procedure   SetInitDataset  (const Value: Boolean);
  Procedure   SetInDesignEvents(const Value: Boolean);Overload;
  Function    GetInBlockEvents : Boolean;
  Function    GetInDesignEvents : Boolean;
  Procedure   NewFieldList;
  Function    GetFieldListByName(aName : String) : TFieldDefinition;
  Procedure   NewDataField(Value : TFieldDefinition);
  Function    FieldListCount    : Integer;
  Procedure   Newtable;
  Procedure   PrepareDetailsNew;
  Procedure   PrepareDetails     (ActiveMode : Boolean);
  Procedure   FieldDefsToFields;
  Function    FieldDefExist      (Value   : String) : TFieldDef;
  Function    FieldExist         (Value   : String) : TField;
  Procedure   Open; Overload; Virtual;                     //M�todo Open que ser� utilizado no Componente
  Procedure   Open               (strSQL  : String);Overload; Virtual;//M�todo Open que ser� utilizado no Componente
  Procedure   ExecOrOpen;                                 //M�todo Open que ser� utilizado no Componente
  Procedure   Close;Virtual;                              //M�todo Close que ser� utilizado no Componente
  Procedure   CreateDataSet;
  Procedure   CreateDatasetFromList;
  Function    ExecSQL          (Var Error : String) : Boolean;   //M�todo ExecSQL que ser� utilizado no Componente
  Function    InsertMySQLReturnID : Integer;                     //M�todo de ExecSQL com retorno de Incremento
  Function    ParamByName          (Value : String) : TParam;    //Retorna o Parametro de Acordo com seu nome
  Function    ApplyUpdates     (Var Error : String) : Boolean;   //Aplica Altera��es no Banco de Dados
  Constructor Create              (AOwner : TComponent);Override;//Cria o Componente
  Destructor  Destroy;Override;                                  //Destroy a Classe
  Procedure   Loaded; Override;
  procedure   OpenCursor       (InfoQuery : Boolean); Override;  //Subscrevendo o OpenCursor para n�o ter erros de ADD Fields em Tempo de Design
  Procedure   GotoRec       (Const aRecNo : Integer);
  Function    ParamCount    : Integer;
  Procedure   DynamicFilter(cFields : Array of String;
                            Value   : String;
                            InText  : Boolean;
                            AndOrOR : String);
  Procedure   Refresh;
  Procedure   SaveToStream    (Var Stream : TRESTDWClientSQLBase);
  Procedure   LoadFromStream    (Stream : TRESTDWClientSQLBase);
  Procedure   ClearMassive;
  Function    MassiveCount  : Integer;
  Function    MassiveToJSON : String; //Transporte de MASSIVE em formato JSON
  Procedure   DWParams        (Var Value  : TDWParams);
  Procedure   RebuildMassiveDataset;
  Property    ServerFieldList     : TFieldsList           Read vFieldsList;
  Property    Inactive            : Boolean               Read vInactive                 Write vInactive;
  Procedure   RestoreDatasetPosition;
  Procedure   SetFiltered(aValue  : Boolean);
  Procedure   InternalLast;Override;
  Procedure   Setnotrepage (Value : Boolean);
  Procedure   SetRecordCount(aJsonCount, aRecordCount : Integer);
 Published
  Property MasterDataSet          : TRESTDWClientSQL      Read vMasterDataSet            Write SetMasterDataSet;
  Property MasterCascadeDelete    : Boolean               Read vCascadeDelete            Write vCascadeDelete;
  Property Datapacks              : Integer               Read vDatapacks                Write SetDatapacks;
  Property OnGetDataError         : TOnEventConnection    Read vOnGetDataError           Write vOnGetDataError;         //Recebe os Erros de ExecSQL ou de GetData
  Property AfterScroll            : TOnAfterScroll        Read vOnAfterScroll            Write vOnAfterScroll;
  Property AfterOpen              : TOnAfterOpen          Read vOnAfterOpen              Write vOnAfterOpen;
  Property AfterClose             : TOnAfterClose         Read vOnAfterClose             Write vOnAfterClose;
  Property Active                 : Boolean               Read vActive                   Write SetActiveDB;             //Estado do Dataset
  Property DataCache              : Boolean               Read vDataCache                Write vDataCache;              //Diz se ser� salvo o �ltimo Stream do Dataset
  Property Params                 : TParams               Read vParams                   Write SetParams;                 //Parametros de Dataset
  Property DataBase               : TRESTDWDataBase       Read vRESTDataBase             Write SetDataBase;             //Database REST do Dataset
  Property SQL                    : TStringList           Read vSQL                      Write SetSQL;                  //SQL a ser Executado
  Property UpdateTableName        : String                Read vUpdateTableName          Write SetUpdateTableName;      //Tabela que ser� usada para Reflex�o de Dados
  Property CacheUpdateRecords     : Boolean               Read vCacheUpdateRecords       Write SetCacheUpdateRecords;
  Property AutoCommitData         : Boolean               Read vAutoCommitData           Write vAutoCommitData;
  Property AutoRefreshAfterCommit : Boolean               Read vAutoRefreshAfterCommit   Write vAutoRefreshAfterCommit;
  Property MasterFields           : String                Read vMasterFields             Write vMasterFields;
  Property BeforeOpen             : TDatasetEvents        Read vBeforeOpen               Write vBeforeOpen;
  Property BeforeEdit             : TDatasetEvents        Read vBeforeEdit               Write vBeforeEdit;
  Property BeforeScroll           : TDatasetEvents        Read vOnBeforeScroll           Write vOnBeforeScroll;
  Property BeforeInsert           : TDatasetEvents        Read vBeforeInsert             Write vBeforeInsert;
  Property BeforePost             : TDatasetEvents        Read vBeforePost               Write vBeforePost;
  Property BeforeDelete           : TDatasetEvents        Read vBeforeDelete             Write vBeforeDelete;
  Property AfterDelete            : TDatasetEvents        Read vAfterDelete              Write vAfterDelete;
  Property AfterEdit              : TDatasetEvents        Read vAfterEdit                Write vAfterEdit;
  Property AfterInsert            : TDatasetEvents        Read vAfterInsert              Write vAfterInsert;
  Property AfterPost              : TDatasetEvents        Read vAfterPost                Write vAfterPost;
  Property AfterCancel            : TDatasetEvents        Read vAfterCancel              Write vAfterCancel;
  Property OnCalcFields           : TDatasetEvents        Read vOnCalcFields             Write vOnCalcFields;
  Property OnNewRecord            : TDatasetEvents        Read vNewRecord                Write vNewRecord;
  Property MassiveCache           : TDWMassiveCache       Read vMassiveCache             Write vMassiveCache;
  Property Filtered               : Boolean               Read vFiltered                 Write SetFiltered;
  Property DWResponseTranslator   : TDWResponseTranslator Read vDWResponseTranslator     Write vDWResponseTranslator;
  Property ActionCursor           : TCursor               Read vActionCursor             Write vActionCursor;
  Property ReflectChanges         : Boolean               Read vReflectChanges           Write SetReflectChanges;
End;

Type
 TRESTDWStoredProc = Class(TDWComponent)
 Private
  vParams       : TParams;
  vProcName     : String;
  vRESTDataBase : TRESTDWDataBase;
  procedure SetDataBase(Const Value : TRESTDWDataBase);
 Public
  Constructor Create   (AOwner      : TComponent);Override; //Cria o Componente
  Function    ExecProc (Var Error   : String) : Boolean;
  Destructor  Destroy;Override;                             //Destroy a Classe
  Function    ParamByName(Value : String) : TParam;
 Published
  Property DataBase            : TRESTDWDataBase     Read vRESTDataBase Write SetDataBase;             //Database REST do Dataset
  Property Params              : TParams             Read vParams       Write vParams;                 //Parametros de Dataset
  Property ProcName            : String              Read vProcName     Write vProcName;               //Procedure a ser Executada
End;

Type
 TRESTDWPoolerList = Class(TDWComponent)
 Private
  vEncoding            : TEncodeSelect;
  vAccessTag,
  vWelcomeMessage,
  vPoolerPrefix,                                     //Prefixo do WS
  vLogin,                                            //Login do Usu�rio caso haja autentica��o
  vPassword,                                         //Senha do Usu�rio caso haja autentica��o
  vRestWebService,                                   //Rest WebService para consultas
  vRestURL             : String;                     //Qual o Pooler de Conex�o do DataSet
  vPoolerPort          : Integer;                    //A Porta do Pooler
  vConnected,
  vProxy               : Boolean;                    //Diz se tem servidor Proxy
  vProxyOptions        : TProxyOptions;              //Se tem Proxy diz quais as op��es
  vPoolerList          : TStringList;
  Procedure SetConnection(Value : Boolean);          //Seta o Estado da Conex�o
  Procedure SetPoolerPort(Value : Integer);          //Seta a Porta do Pooler a ser usada
  Function  TryConnect : Boolean;                    //Tenta Conectar o Servidor para saber se posso executar comandos
//  Procedure SetConnectionOptions(Var Value : TRESTClientPooler); //Seta as Op��es de Conex�o
 Public
  Constructor Create(AOwner  : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                      //Destroy a Classe
 Published
  Property Active             : Boolean                  Read vConnected          Write SetConnection;      //Seta o Estado da Conex�o
  Property Login              : String                   Read vLogin              Write vLogin;             //Login do Usu�rio caso haja autentica��o
  Property Password           : String                   Read vPassword           Write vPassword;          //Senha do Usu�rio caso haja autentica��o
  Property WelcomeMessage     : String                   Read vWelcomeMessage     Write vWelcomeMessage;    //Welcome Message Event
  Property Proxy              : Boolean                  Read vProxy              Write vProxy;             //Diz se tem servidor Proxy
  Property ProxyOptions       : TProxyOptions            Read vProxyOptions       Write vProxyOptions;      //Se tem Proxy diz quais as op��es
  Property PoolerService      : String                   Read vRestWebService     Write vRestWebService;    //Host do WebService REST
  Property PoolerURL          : String                   Read vRestURL            Write vRestURL;           //URL do WebService REST
  Property PoolerPort         : Integer                  Read vPoolerPort         Write SetPoolerPort;      //A Porta do Pooler do DataSet
  Property PoolerPrefix       : String                   Read vPoolerPrefix       Write vPoolerPrefix;      //Prefixo do WebService REST
  Property Poolers            : TStringList              Read vPoolerList;
  Property AccessTag          : String                   Read vAccessTag          Write vAccessTag;
  Property Encoding           : TEncodeSelect            Read vEncoding             Write vEncoding;          //Encoding da string
 End;

Type
 TRESTDWDriver    = Class(TDWComponent)
 Private
  vStrsTrim,
  vStrsEmpty2Null,
  vStrsTrim2Len,
  vEncodeStrings,
  vCompression         : Boolean;
  vEncoding            : TEncodeSelect;
  vCommitRecords       : Integer;
  {$IFDEF FPC}
  vDatabaseCharSet     : TDatabaseCharSet;
  {$ENDIF}
  vParamCreate         : Boolean;
  vOnPrepareConnection : TOnPrepareConnection;
 Public
  Constructor Create(AOwner  : TComponent);Override; //Cria o Componente
  Function ApplyUpdates           (Massive,
                                   SQL               : String;
                                   Params            : TDWParams;
                                   Var Error         : Boolean;
                                   Var MessageError  : String) : TJSONValue;        Virtual;Abstract;
  Procedure ApplyUpdates_MassiveCache(MassiveCache   : String;
                                      Var Error      : Boolean;
                                      Var MessageError  : String);                  Virtual;Abstract;
  Function ExecuteCommand         (SQL              : String;
                                   Var Error        : Boolean;
                                   Var MessageError : String;
                                   Execute          : Boolean = False) : String;Overload;Virtual;Abstract;
  Function ExecuteCommand         (SQL              : String;
                                   Params           : TDWParams;
                                   Var Error        : Boolean;
                                   Var MessageError : String;
                                   Execute          : Boolean = False) : String;Overload;Virtual;Abstract;
  Function InsertMySQLReturnID    (SQL              : String;
                                   Var Error        : Boolean;
                                   Var MessageError : String)          : Integer;   Overload;Virtual;Abstract;
  Function InsertMySQLReturnID    (SQL              : String;
                                   Params           : TDWParams;
                                   Var Error        : Boolean;
                                   Var MessageError : String)          : Integer;   Overload;Virtual;Abstract;
  Procedure ExecuteProcedure      (ProcName         : String;
                                   Params           : TDWParams;
                                   Var Error        : Boolean;
                                   Var MessageError : String);                      Virtual;Abstract;
  Procedure ExecuteProcedurePure  (ProcName           : String;
                                   Var Error          : Boolean;
                                   Var MessageError   : String);                    Virtual;Abstract;
  Function  OpenDatasets          (DatasetsLine       : String;
                                   Var Error          : Boolean;
                                   Var MessageError   : String)        : TJSONValue;Virtual;Abstract;
  Class Procedure CreateConnection(Const ConnectionDefs : TConnectionDefs;
                                   Var Connection       : TObject);                 Virtual;Abstract;
  Procedure PrepareConnection     (Var ConnectionDefs : TConnectionDefs);           Virtual;Abstract;
  Procedure Close;Virtual;abstract;
  Procedure BuildDatasetLine(Var Query : TDataset; Massivedataset : TMassivedatasetBuffer);
  Property StrsTrim            : Boolean              Read vStrsTrim            Write vStrsTrim;
  Property StrsEmpty2Null      : Boolean              Read vStrsEmpty2Null      Write vStrsEmpty2Null;
  Property StrsTrim2Len        : Boolean              Read vStrsTrim2Len        Write vStrsTrim2Len;
  Property Compression         : Boolean              Read vCompression         Write vCompression;
  Property EncodeStringsJSON   : Boolean              Read vEncodeStrings       Write vEncodeStrings;
  Property Encoding            : TEncodeSelect        Read vEncoding            Write vEncoding;
  property ParamCreate         : Boolean              Read vParamCreate         Write vParamCreate;
 Published
 {$IFDEF FPC}
  Property DatabaseCharSet     : TDatabaseCharSet     Read vDatabaseCharSet     Write vDatabaseCharSet;
 {$ENDIF}
  Property CommitRecords       : Integer              Read vCommitRecords       Write vCommitRecords;
  Property OnPrepareConnection : TOnPrepareConnection Read vOnPrepareConnection Write vOnPrepareConnection;
End;

//PoolerDB Control
Type
 TRESTDWPoolerDBP = ^TDWComponent;
 TRESTDWPoolerDB  = Class(TDWComponent)
 Private
  FLock          : TCriticalSection;
  vRESTDriver    : TRESTDWDriver;
  vActive,
  vStrsTrim,
  vStrsEmpty2Null,
  vStrsTrim2Len,
  vCompression   : Boolean;
  vEncoding      : TEncodeSelect;
  vAccessTag,
  vMessagePoolerOff : String;
  vParamCreate   : Boolean;
  Procedure SetConnection(Value : TRESTDWDriver);
  Function  GetConnection  : TRESTDWDriver;
 protected
  procedure Notification(AComponent: TComponent; Operation: TOperation); override;
 Public
  Function ExecuteCommand(SQL        : String;
                          Var Error  : Boolean;
                          Var MessageError : String;
                          Execute    : Boolean = False) : String;Overload;
  Function ExecuteCommand(SQL              : String;
                          Params           : TDWParams;
                          Var Error        : Boolean;
                          Var MessageError : String;
                          Execute          : Boolean = False) : String;Overload;
  Function InsertMySQLReturnID(SQL              : String;
                               Var Error        : Boolean;
                               Var MessageError : String) : Integer;Overload;
  Function InsertMySQLReturnID(SQL              : String;
                               Params           : TDWParams;
                               Var Error        : Boolean;
                               Var MessageError : String) : Integer;Overload;
  Procedure ExecuteProcedure  (ProcName         : String;
                               Params           : TDWParams;
                               Var Error        : Boolean;
                               Var MessageError : String);
  Procedure ExecuteProcedurePure(ProcName         : String;
                                 Var Error        : Boolean;
                                 Var MessageError : String);
  Constructor Create(AOwner : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                     //Destroy a Classe
 Published
  Property    RESTDriver       : TRESTDWDriver Read GetConnection     Write SetConnection;
  Property    Compression      : Boolean       Read vCompression      Write vCompression;
  Property    Encoding         : TEncodeSelect Read vEncoding         Write vEncoding;
  Property    StrsTrim         : Boolean       Read vStrsTrim         Write vStrsTrim;
  Property    StrsEmpty2Null   : Boolean       Read vStrsEmpty2Null   Write vStrsEmpty2Null;
  Property    StrsTrim2Len     : Boolean       Read vStrsTrim2Len     Write vStrsTrim2Len;
  Property    Active           : Boolean       Read vActive           Write vActive;
  Property    PoolerOffMessage : String        Read vMessagePoolerOff Write vMessagePoolerOff;
  Property    AccessTag        : String        Read vAccessTag        Write vAccessTag;
  Property    ParamCreate      : Boolean       Read vParamCreate      Write vParamCreate;
End;

 Function GetDWParams(Params : TParams; Encondig : TEncodeSelect) : TDWParams;

implementation

Uses uDWJSONInterface;

Function GetDWParams(Params : TParams; Encondig : TEncodeSelect) : TDWParams;
Var
 I         : Integer;
 JSONParam : TJSONParam;
Begin
 Result := Nil;
 If Params <> Nil Then
  Begin
   If Params.Count > 0 Then
    Begin
     Result := TDWParams.Create;
     Result.Encoding := Encondig;
     For I := 0 To Params.Count -1 Do
      Begin
       JSONParam         := TJSONParam.Create(Result.Encoding);
       JSONParam.ParamName := Params[I].Name;
       JSONParam.Encoded   := True;
       JSONParam.LoadFromParam(Params[I]);
       Result.Add(JSONParam);
      End;
    End;
  End;
End;

Procedure TAutoCheckData.Assign(Source: TPersistent);
Var
 Src : TAutoCheckData;
Begin
 If Source is TAutoCheckData Then
  Begin
   Src        := TAutoCheckData(Source);
   vAutoCheck := Src.AutoCheck;
   vInTime    := Src.InTime;
//   vEvent     := Src.OnEventTimer;
  End
 Else
  Inherited;
End;

Procedure TProxyOptions.Assign(Source: TPersistent);
Var
 Src : TProxyOptions;
Begin
 If Source is TProxyOptions Then
  Begin
   Src := TProxyOptions(Source);
   vServer := Src.Server;
   vLogin  := Src.Login;
   vPassword := Src.Password;
   vPort     := Src.Port;
  End
 Else
  Inherited;
End;

Function  TRESTDWPoolerDB.GetConnection : TRESTDWDriver;
Begin
 Result := vRESTDriver;
End;

Procedure TRESTDWPoolerDB.SetConnection(Value : TRESTDWDriver);
Begin
  //Alexandre Magno - 25/11/2018
  if vRESTDriver <> Value then
    vRESTDriver := Value;
  if vRESTDriver <> nil then
    vRESTDriver.FreeNotification(Self);
End;

Function TRESTDWPoolerDB.InsertMySQLReturnID(SQL              : String;
                                           Var Error        : Boolean;
                                           Var MessageError : String) : Integer;
Begin
 Result := -1;
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   vRESTDriver.vParamCreate       := vParamCreate;
   Result := vRESTDriver.InsertMySQLReturnID(SQL, Error, MessageError);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Function TRESTDWPoolerDB.InsertMySQLReturnID(SQL              : String;
                                           Params           : TDWParams;
                                           Var Error        : Boolean;
                                           Var MessageError : String) : Integer;
Begin
 Result := -1;
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   vRESTDriver.vParamCreate       := vParamCreate;
   Result := vRESTDriver.InsertMySQLReturnID(SQL, Params, Error, MessageError);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

procedure TRESTDWPoolerDB.Notification(AComponent: TComponent; Operation: TOperation);
begin
  //Alexandre Magno - 25/11/2018
  if (Operation = opRemove) and (AComponent = vRESTDriver) then
  begin
    vRESTDriver := nil;
  end;
  inherited Notification(AComponent, Operation);
end;

Function TRESTDWPoolerDB.ExecuteCommand(SQL        : String;
                                      Var Error  : Boolean;
                                      Var MessageError : String;
                                      Execute    : Boolean = False) : String;
Begin
  Result := '';
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   vRESTDriver.vParamCreate       := vParamCreate;
   Result := vRESTDriver.ExecuteCommand(SQL, Error, MessageError, Execute);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Function TRESTDWPoolerDB.ExecuteCommand(SQL              : String;
                                        Params           : TDWParams;
                                        Var Error        : Boolean;
                                        Var MessageError : String;
                                        Execute          : Boolean = False) : String;
Begin
 Result := '';
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   vRESTDriver.vParamCreate       := vParamCreate;
   Result := vRESTDriver.ExecuteCommand(SQL, Params, Error, MessageError, Execute);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Procedure TRESTDWPoolerDB.ExecuteProcedure(ProcName         : String;
                                         Params           : TDWParams;
                                         Var Error        : Boolean;
                                         Var MessageError : String);
Begin
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   vRESTDriver.vParamCreate       := vParamCreate;
   vRESTDriver.ExecuteProcedure(ProcName, Params, Error, MessageError);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Procedure TRESTDWPoolerDB.ExecuteProcedurePure(ProcName         : String;
                                             Var Error        : Boolean;
                                             Var MessageError : String);
Begin
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   vRESTDriver.vParamCreate       := vParamCreate;
   vRESTDriver.ExecuteProcedurePure(ProcName, Error, MessageError);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Constructor TRESTDWPoolerDB.Create(AOwner : TComponent);
Begin
 Inherited;
 FLock             := TCriticalSection.Create;
 FLock.Acquire;
 vCompression      := True;
 vStrsTrim         := False;
 vStrsEmpty2Null   := False;
 vStrsTrim2Len     := True;
 vActive           := True;
 {$IFNDEF FPC}
 {$IF CompilerVersion > 21}
  vEncoding         := esUtf8;
 {$ELSE}
  vEncoding         := esAscii;
 {$IFEND}
 {$ELSE}
  vEncoding         := esUtf8;
 {$ENDIF}
 vMessagePoolerOff := 'RESTPooler not active.';
 vParamCreate      := True;
End;

Destructor  TRESTDWPoolerDB.Destroy;
Begin
 If Assigned(FLock) Then
  Begin
   {.$IFNDEF POSIX}
   FLock.Release;
   {.$ENDIF}
   FreeAndNil(FLock);
  End;
 Inherited;
End;

Constructor TAutoCheckData.Create;
Begin
 Inherited;
 vAutoCheck := False;
 vInTime    := 1000;
 vEvent     := Nil;
 Timer      := Nil;
 FLock      := TCriticalSection.Create;
End;

Destructor  TAutoCheckData.Destroy;
Begin
 SetState(False);
 FLock.Release;
 FLock.Free;
 Inherited;
End;

Procedure  TAutoCheckData.SetState(Value : Boolean);
Begin
 vAutoCheck := Value;
 If vAutoCheck Then
  Begin
   If Timer <> Nil Then
    Begin
     Timer.Terminate;
     Timer := Nil;
    End;
   Timer              := TTimerData.Create(vInTime, FLock);
   Timer.OnEventTimer := vEvent;
  End
 Else
  Begin
   If Timer <> Nil Then
    Begin
     Timer.Terminate;
     Timer := Nil;
    End;
  End;
End;

Procedure  TAutoCheckData.SetInTime(Value : Integer);
Begin
 vInTime    := Value;
 SetState(vAutoCheck);
End;

Procedure  TAutoCheckData.SetEventTimer(Value : TOnEventTimer);
Begin
 vEvent := Value;
 SetState(vAutoCheck);
End;

Constructor TTimerData.Create(AValue: Integer; ALock: TCriticalSection);
Begin
 FValue := AValue;
 FLock := ALock;
 Inherited Create(False);
End;

Procedure TTimerData.Execute;
Begin
 While Not Terminated do
  Begin
   Sleep(FValue);
   FLock.Acquire;
   if Assigned(vEvent) then
    vEvent;
   FLock.Release;
  End;
End;

Constructor TProxyOptions.Create;
Begin
 Inherited;
 vServer   := '';
 vLogin    := vServer;
 vPassword := vLogin;
 vPort     := 8888;
End;

{
Procedure TRESTDWPoolerList.SetConnectionOptions(Var Value : TRESTClientPooler);
Begin
 Value                   := TRESTClientPooler.Create(Nil);
 Value.TypeRequest       := trHttp;
 Value.Host              := vRestWebService;
 Value.Port              := vPoolerPort;
 Value.UrlPath           := vRestURL;
 Value.UserName          := vLogin;
 Value.Password          := vPassword;
 if vProxy then
  Begin
   Value.ProxyOptions.ProxyServer   := vProxyOptions.vServer;
   Value.ProxyOptions.ProxyPort     := vProxyOptions.vPort;
   Value.ProxyOptions.ProxyUsername := vProxyOptions.vLogin;
   Value.ProxyOptions.ProxyPassword := vProxyOptions.vPassword;
  End
 Else
  Begin
   Value.ProxyOptions.ProxyServer   := '';
   Value.ProxyOptions.ProxyPort     := 0;
   Value.ProxyOptions.ProxyUsername := '';
   Value.ProxyOptions.ProxyPassword := '';
  End;
End;
}

Procedure TRESTDWDataBase.SetOnStatus(Value : TOnStatus);
Begin
 {$IFDEF FPC}
  vOnStatus            := Value;
 {$ELSE}
  vOnStatus            := Value;
 {$ENDIF}
End;

Procedure TRESTDWDataBase.SetOnWork(Value : TOnWork);
Begin
 {$IFDEF FPC}
  vOnWork            := Value;
 {$ELSE}
  vOnWork            := Value;
 {$ENDIF}
End;

Procedure TRESTDWDataBase.SetOnWorkBegin(Value : TOnWorkBegin);
Begin
 {$IFDEF FPC}
  vOnWorkBegin            := Value;
 {$ELSE}
  vOnWorkBegin            := Value;
 {$ENDIF}
End;

Procedure TRESTDWDataBase.SetOnWorkEnd(Value : TOnWorkEnd);
Begin
 {$IFDEF FPC}
  vOnWorkEnd            := Value;
 {$ELSE}
  vOnWorkEnd            := Value;
 {$ENDIF}
End;

Procedure TRESTDWDataBase.ApplyUpdates(Massive          : TMassiveDatasetBuffer;
                                       SQL              : TStringList;
                                       Var Params       : TParams;
                                       Var Error        : Boolean;
                                       Var MessageError : String;
                                       Var Result       : TJSONValue;
                                       RESTClientPooler : TRESTClientPooler = Nil);
Var
 vRESTConnectionDB : TDWPoolerMethodClient;
 LDataSetList      : TJSONValue;
 DWParams          : TDWParams;
 Function GetLineSQL(Value : TStringList) : String;
 Var
  I : Integer;
 Begin
  Result := '';
  If Value <> Nil Then
   For I := 0 To Value.Count -1 do
    Begin
     If I = 0 then
      Result := Value[I]
     Else
      Result := Result + ' ' + Value[I];
    End;
 End;
 Procedure ParseParams;
 Var
  I : Integer;
 Begin
  If Params <> Nil Then
   For I := 0 To Params.Count -1 Do
    Begin
     If Params[I].DataType = ftUnknown then
      Params[I].DataType := ftString;
    End;
 End;
Begin
// Result := Nil;
 if vRestPooler = '' then
  Exit;
 ParseParams;
 vRESTConnectionDB                := TDWPoolerMethodClient.Create(Nil);
 vRESTConnectionDB.WelcomeMessage := vWelcomeMessage;
 vRESTConnectionDB.Host           := vRestWebService;
 vRESTConnectionDB.Port           := vPoolerPort;
 vRESTConnectionDB.Compression    := vCompression;
 vRESTConnectionDB.TypeRequest    := VtypeRequest;
 vRESTConnectionDB.Encoding       := vEncoding;
 vRESTConnectionDB.EncodeStrings  := EncodeStrings;
 vRESTConnectionDB.OnWork         := vOnWork;
 vRESTConnectionDB.OnWorkBegin    := vOnWorkBegin;
 vRESTConnectionDB.OnWorkEnd      := vOnWorkEnd;
 vRESTConnectionDB.OnStatus       := vOnStatus;
 vRESTConnectionDB.AccessTag      := vAccessTag;
 {$IFDEF FPC}
  vRESTConnectionDB.DatabaseCharSet := vDatabaseCharSet;
 {$ENDIF}
 Try
  If Params.Count > 0 Then
   DWParams     := GetDWParams(Params, vEncoding)
  Else
   DWParams     := Nil;
  LDataSetList := vRESTConnectionDB.ApplyUpdates(Massive,      vRestPooler,
                                                 vRestURL,  GetLineSQL(SQL),
                                                 DWParams,     Error,
                                                 MessageError, vTimeOut,
                                                 vLogin,       vPassword,
                                                 vClientConnectionDefs.vConnectionDefs,
                                                 RESTClientPooler);
  If Params.Count > 0 Then
   If DWParams <> Nil Then
    FreeAndNil(DWParams);
  If (LDataSetList <> Nil) Then
   Begin
    Result := Nil;
    Error  := Trim(MessageError) <> '';
    If (LDataSetList <> Nil) And
       (Not (Error))        Then
     Begin
      Try
       Result          := TJSONValue.Create;
       Result.Encoding := LDataSetList.Encoding;
       Result.SetValue(LDataSetList.value);
      Finally
      End;
     End;
    If (Not (Error)) Then
     Begin
      If Assigned(vOnEventConnection) Then
       vOnEventConnection(True, 'ApplyUpdates Ok');
     End
    Else
     Begin
      If Assigned(vOnEventConnection) then
       vOnEventConnection(False, MessageError)
      Else
       Raise Exception.Create(PChar(MessageError));
     End;
   End
  Else
   Begin
    If Assigned(vOnEventConnection) Then
     vOnEventConnection(False, MessageError);
   End;
 Except
  On E : Exception do
   Begin
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 FreeAndNil(vRESTConnectionDB);
 If Assigned(LDataSetList) then
  FreeAndNil(LDataSetList);
End;

Function TRESTDWDataBase.InsertMySQLReturnID(Var SQL          : TStringList;
                                             Var Params       : TParams;
                                             Var Error        : Boolean;
                                             Var MessageError : String;
                                             RESTClientPooler : TRESTClientPooler = Nil) : Integer;
Var
 vRESTConnectionDB : TDWPoolerMethodClient;
 LDataSetList      : Integer;
 DWParams          : TDWParams;
 Function GetLineSQL(Value : TStringList) : String;
 Var
  I : Integer;
 Begin
  Result := '';
  If Value <> Nil Then
   For I := 0 To Value.Count -1 do
    Begin
     If I = 0 then
      Result := Value[I]
     Else
      Result := Result + ' ' + Value[I];
    End;
 End;
 Procedure ParseParams;
 Var
  I : Integer;
 Begin
  If Params <> Nil Then
   For I := 0 To Params.Count -1 Do
    Begin
     If Params[I].DataType = ftUnknown then
      Params[I].DataType := ftString;
    End;
 End;
Begin
 Result := -1;
 if vRestPooler = '' then
  Exit;
 ParseParams;
 vRESTConnectionDB                := TDWPoolerMethodClient.Create(Nil);
 vRESTConnectionDB.WelcomeMessage := vWelcomeMessage;
 vRESTConnectionDB.Host           := vRestWebService;
 vRESTConnectionDB.Port           := vPoolerPort;
 vRESTConnectionDB.Compression    := vCompression;
 vRESTConnectionDB.TypeRequest     := VtypeRequest;
 vRESTConnectionDB.Encoding      := vEncoding;
 vRESTConnectionDB.OnWork        := vOnWork;
 vRESTConnectionDB.OnWorkBegin   := vOnWorkBegin;
 vRESTConnectionDB.OnWorkEnd     := vOnWorkEnd;
 vRESTConnectionDB.OnStatus      := vOnStatus;
 vRESTConnectionDB.AccessTag     := vAccessTag;
 {$IFDEF FPC}
  vRESTConnectionDB.DatabaseCharSet := vDatabaseCharSet;
 {$ENDIF}
 Try
  If Params.Count > 0 Then
   Begin
    DWParams     := GetDWParams(Params, vEncoding);
    LDataSetList := vRESTConnectionDB.InsertValue(vRestPooler,
                                                  vRestURL, GetLineSQL(SQL),
                                                  DWParams, Error,
                                                  MessageError, vTimeOut, vLogin, vPassword,
                                                  vClientConnectionDefs.vConnectionDefs, RESTClientPooler);
    FreeAndNil(DWParams);
   End
  Else
   LDataSetList := vRESTConnectionDB.InsertValuePure (vRestPooler,
                                                      vRestURL,
                                                      GetLineSQL(SQL), Error,
                                                      MessageError, vTimeOut, vLogin, vPassword,
                                                      vClientConnectionDefs.vConnectionDefs, RESTClientPooler);
  If (LDataSetList <> -1) Then
   Begin
//    If Not Assigned(Result) Then //Corre��o fornecida por romyllldo no Forum
    Result := -1;
    Error  := Trim(MessageError) <> '';
    If (LDataSetList <> -1) And
       (Not (Error))        Then
     Begin
      Try
       Result := LDataSetList;
      Finally
      End;
     End;
    If (Not (Error)) Then
     Begin
      If Assigned(vOnEventConnection) Then
       vOnEventConnection(True, 'InsertValue Ok');
     End
    Else
     Begin
      If Assigned(vOnEventConnection) then
       vOnEventConnection(False, MessageError)
      Else
       Raise Exception.Create(PChar(MessageError));
     End;
   End
  Else
   Begin
    If Assigned(vOnEventConnection) Then
     vOnEventConnection(False, MessageError);
   End;
 Except
  On E : Exception do
   Begin
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 FreeAndNil(vRESTConnectionDB);
 FreeAndNil(LDataSetList);
End;

procedure TRESTDWDataBase.Loaded;
begin
  inherited Loaded;
  if not (csDesigning in ComponentState) then
    SetConnection(False);
end;

Procedure TRESTDWDataBase.Open;
Begin
 SetConnection(True);
End;

Procedure TRESTDWDataBase.OpenDatasets(Datasets     : Array of {$IFDEF FPC}TRESTDWClientSQLBase{$ELSE}TObject{$ENDIF};
                                       Var Error        : Boolean;
                                       Var MessageError : String);
Var
 vJsonLine,
 vLinesDS          : String;
 vJsonCount,
 I                 : Integer;
 vRESTConnectionDB : TDWPoolerMethodClient;
 JSONValue         : TJSONValue;
 bJsonArray        : TJsonArray;
Begin
 vLinesDS := '';
 For I := 0 To Length(Datasets) -1 Do
  Begin
   TRESTDWClientSQL(Datasets[I]).ProcBeforeOpen(TRESTDWClientSQL(Datasets[I]));
   If I = 0 Then
    vLinesDS := DatasetRequestToJSON(TRESTDWClientSQL(Datasets[I]))
   Else
    vLinesDS := Format('%s, %s', [vLinesDS, DatasetRequestToJSON(TRESTDWClientSQL(Datasets[I]))]);
  End;
 If vLinesDS <> '' Then
  vLinesDS := Format('[%s]', [vLinesDS])
 Else
  vLinesDS := '[]';
 if vRestPooler = '' then
  Exit;
 vRESTConnectionDB                  := TDWPoolerMethodClient.Create(Nil);
 vRESTConnectionDB.WelcomeMessage   := vWelcomeMessage;
 vRESTConnectionDB.Host             := vRestWebService;
 vRESTConnectionDB.Port             := vPoolerPort;
 vRESTConnectionDB.Compression      := vCompression;
 vRESTConnectionDB.TypeRequest      := VtypeRequest;
 vRESTConnectionDB.Encoding         := vEncoding;
 vRESTConnectionDB.AccessTag        := vAccessTag;
 {$IFNDEF FPC}
  vRESTConnectionDB.OnWork          := vOnWork;
  vRESTConnectionDB.OnWorkBegin     := vOnWorkBegin;
  vRESTConnectionDB.OnWorkEnd       := vOnWorkEnd;
  vRESTConnectionDB.OnStatus        := vOnStatus;
 {$ELSE}
  vRESTConnectionDB.OnWork          := vOnWork;
  vRESTConnectionDB.OnWorkBegin     := vOnWorkBegin;
  vRESTConnectionDB.OnWorkEnd       := vOnWorkEnd;
  vRESTConnectionDB.OnStatus        := vOnStatus;
  vRESTConnectionDB.DatabaseCharSet := vDatabaseCharSet;
 {$ENDIF}
 Try
  vLinesDS := vRESTConnectionDB.OpenDatasets(vLinesDS, vRestPooler,  vRestURL,
                                             Error,    MessageError, vTimeOut,
                                             vLogin,   vPassword, vClientConnectionDefs.vConnectionDefs);
  If Not Error Then
   Begin
    JSONValue := TJSONValue.Create;
    Try
     JSONValue.Encoded  := True;
     JSONValue.Encoding := vEncoding;
     JSONValue.LoadFromJSON(vLinesDS);
     vJsonLine := JSONValue.value;
     FreeAndNil(JSONValue);
     {$IFNDEF FPC}
     {$IF CompilerVersion > 21}
      {$IF Defined(HAS_FMX)}
      {$ELSE}
       bJsonArray := TJsonArray.create(vJsonLine); //TODO 13/06/2018
       For I := 0 To bJsonArray.Length - 1 Do
        Begin
         vJsonCount := 0;
         JSONValue := TJSONValue.Create;
         JSONValue.Encoding := vEncoding;
         JSONValue.LoadFromJSON(bJsonArray.optJSONObject(I).ToString);
         JSONValue.Encoded := True;
         JSONValue.WriteToDataset(dtFull, JSONValue.ToJSON, TRESTDWClientSQL(Datasets[I]),
                                  vJsonCount, TRESTDWClientSQL(Datasets[I]).Datapacks);
         TRESTDWClientSQL(Datasets[I]).vActualJSON := JSONValue.ToJSON;
         TRESTDWClientSQL(Datasets[I]).CreateMassiveDataset;
        End;
      {$IFEND}
     {$ELSE}
     bJsonArray := TJsonArray.create(vJsonLine); //TODO 13/06/2018
     For I := 0 To bJsonArray.Length - 1 Do
      Begin
       vJsonCount := 0;
       JSONValue := TJSONValue.Create;
       JSONValue.Encoding := vEncoding;
       JSONValue.LoadFromJSON(bJsonArray.optJSONObject(I).ToString);
       JSONValue.Encoded := True;
       JSONValue.WriteToDataset(dtFull, JSONValue.ToJSON, TRESTDWClientSQL(Datasets[I]),
                                vJsonCount, TRESTDWClientSQL(Datasets[I]).Datapacks);
       TRESTDWClientSQL(Datasets[I]).vActualJSON := JSONValue.ToJSON;
       TRESTDWClientSQL(Datasets[I]).CreateMassiveDataset;
      End;
     {$IFEND}
     {$ELSE}
     bJsonArray := TJsonArray.create(vJsonLine); //TODO 13/06/2018
     For I := 0 To bJsonArray.Length - 1 Do
      Begin
       JSONValue := TJSONValue.Create;
       JSONValue.Encoding := vEncoding;
       JSONValue.LoadFromJSON(bJsonArray.optJSONObject(I).ToString);
       JSONValue.Encoded := True;
       JSONValue.WriteToDataset(dtFull, JSONValue.ToJSON, TRESTDWClientSQL(Datasets[I]));
       TRESTDWClientSQL(Datasets[I]).CreateMassiveDataset;
      End;
     {$ENDIF}
    Finally
     If bJsonArray <> Nil Then
      FreeAndNil(bJsonArray);
     FreeAndNil(JSONValue);
    End;
   End;
 Finally
  FreeAndNil(vRESTConnectionDB);
 End;
End;

Procedure TRESTDWDataBase.ExecuteCommand(Var SQL          : TStringList;
                                         Var Params       : TParams;
                                         Var Error        : Boolean;
                                         Var MessageError : String;
                                         Var Result       : TJSONValue;
                                         Execute          : Boolean = False;
                                         RESTClientPooler : TRESTClientPooler = Nil);
Var
 vRESTConnectionDB : TDWPoolerMethodClient;
 LDataSetList      : TJSONValue;
 DWParams          : TDWParams;
 vTempValue        : String;
 Function GetLineSQL(Value : TStringList) : String;
 Var
  I : Integer;
 Begin
  Result := '';
  If Value <> Nil Then
   For I := 0 To Value.Count -1 do
    Begin
     If I = 0 then
      Result := Value[I]
     Else
      Result := Result + ' ' + Value[I];
    End;
 End;
 Procedure ParseParams;
 Var
  I : Integer;
 Begin
 If Params <> Nil Then
   For I := 0 To Params.Count -1 Do
    Begin
     If Params[I].DataType = ftUnknown then
      Params[I].DataType := ftString;
    End;
 End;
Begin
 LDataSetList := Nil;
 If vRestPooler = '' Then
  Exit;
 ParseParams;
 vRESTConnectionDB                := TDWPoolerMethodClient.Create(Nil);
 vRESTConnectionDB.WelcomeMessage := vWelcomeMessage;
 vRESTConnectionDB.Host           := vRestWebService;
 vRESTConnectionDB.Port           := vPoolerPort;
 vRESTConnectionDB.Compression    := vCompression;
 vRESTConnectionDB.TypeRequest    := VtypeRequest;
 vRESTConnectionDB.Encoding       := vEncoding;
 vRESTConnectionDB.EncodeStrings  := EncodeStrings;
 vRESTConnectionDB.OnWork         := vOnWork;
 vRESTConnectionDB.OnWorkBegin    := vOnWorkBegin;
 vRESTConnectionDB.OnWorkEnd      := vOnWorkEnd;
 vRESTConnectionDB.OnStatus       := vOnStatus;
 vRESTConnectionDB.AccessTag      := vAccessTag;
 {$IFDEF FPC}
  vRESTConnectionDB.DatabaseCharSet := vDatabaseCharSet;
 {$ENDIF}
 Try
  If Params.Count > 0 Then
   Begin
    DWParams     := GetDWParams(Params, vEncoding);
    LDataSetList := vRESTConnectionDB.ExecuteCommandJSON(vRestPooler,
                                                         vRestURL, GetLineSQL(SQL),
                                                         DWParams, Error,
                                                         MessageError, Execute, vTimeOut, vLogin, vPassword,
                                                         vClientConnectionDefs.vConnectionDefs, RESTClientPooler);
    FreeAndNil(DWParams);
   End
  Else
   LDataSetList := vRESTConnectionDB.ExecuteCommandPureJSON(vRestPooler,
                                                            vRestURL,
                                                            GetLineSQL(SQL), Error,
                                                            MessageError, Execute, vTimeOut, vLogin, vPassword,
                                                            vClientConnectionDefs.vConnectionDefs, RESTClientPooler);

  If (LDataSetList <> Nil) Then
   Begin
//    If Not Assigned(Result) Then //Corre��o fornecida por romyllldo no Forum
    Result := TJSONValue.Create;
    Result.Encoding := vRESTConnectionDB.Encoding;
    Error  := Trim(MessageError) <> '';
    vTempValue := LDataSetList.ToJSON;
    If (Trim(vTempValue) <> '{}') And
       (Trim(vTempValue) <> '')    And
       (Not (Error))                       Then
     Begin
      Try
       {$IFDEF  ANDROID}
       Result.Free;
       Result := LDataSetList;
       {$ELSE}
       Result.LoadFromJSON(vTempValue); //Esse c�digo server para criar o Objeto, nao pode ser removido
       {$ENDIF}
      Finally
      End;
     End;
    vTempValue := '';
    If (Not (Error)) Then
     Begin
      If Assigned(vOnEventConnection) Then
       vOnEventConnection(True, 'ExecuteCommand Ok');
     End
    Else
     Begin
      If Assigned(vOnEventConnection) then
       vOnEventConnection(False, MessageError)
      Else
       Raise Exception.Create(PChar(MessageError));
     End;
   End
  Else
   Begin
    If Assigned(vOnEventConnection) Then
     vOnEventConnection(False, MessageError);
   End;
 Except
  On E : Exception do
   Begin
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 If LDataSetList <> Nil Then
  FreeAndNil(LDataSetList);
 FreeAndNil(vRESTConnectionDB);
End;

Procedure TRESTDWDataBase.ExecuteProcedure(ProcName         : String;
                                           Params           : TParams;
                                           Var Error        : Boolean;
                                           Var MessageError : String);
Begin
End;

Function TRESTDWDataBase.GetRestPoolers : TStringList;
Var
 vTempList   : TStringList;
 vConnection : TDWPoolerMethodClient;
 I           : Integer;
Begin
 vConnection                := TDWPoolerMethodClient.Create(Nil);
 vConnection.WelcomeMessage := vWelcomeMessage;
 vConnection.Host           := vRestWebService;
 vConnection.Port           := vPoolerPort;
 vConnection.Compression    := vCompression;
 vConnection.TypeRequest    := VtypeRequest;
 vConnection.AccessTag      := vAccessTag;
 vConnection.Encoding       := Encoding;
 Result := TStringList.Create;
 Try
  vTempList := vConnection.GetPoolerList(vRestURL, vTimeOut, vLogin, vPassword);
  Try
    For I := 0 To vTempList.Count -1 do
     Result.Add(vTempList[I]);
    If Assigned(vOnEventConnection) Then
     vOnEventConnection(True, 'GetRestPoolers Ok');
  Finally
   vTempList.Free;
  End;
 Except
  On E : Exception do
   Begin
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
End;

Function TRESTDWDataBase.GetServerEvents : TStringList;
Var
 vTempList   : TStringList;
 vConnection : TDWPoolerMethodClient;
 I           : Integer;
Begin
 vConnection                := TDWPoolerMethodClient.Create(Nil);
 vConnection.WelcomeMessage := vWelcomeMessage;
 vConnection.Host           := vRestWebService;
 vConnection.Port           := vPoolerPort;
 vConnection.Compression    := vCompression;
 vConnection.TypeRequest    := VtypeRequest;
 vConnection.AccessTag      := vAccessTag;
 vConnection.Encoding       := Encoding;
 Result := TStringList.Create;
 Try
  vTempList := vConnection.GetServerEvents(vRestURL, vTimeOut, vLogin, vPassword);
  Try
    For I := 0 To vTempList.Count -1 do
     Result.Add(vTempList[I]);
    If Assigned(vOnEventConnection) Then
     vOnEventConnection(True, 'GetServerEvents Ok');
  Finally
   vTempList.Free;
  End;
 Except
  On E : Exception do
   Begin
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
End;

Function TRESTDWDataBase.GetStateDB: Boolean;
Begin
 Result := vConnected;
End;

Constructor TRESTDWPoolerList.Create(AOwner : TComponent);
Begin
 Inherited;
 vLogin                    := '';
 vPassword                 := vLogin;
 vPoolerPort               := 8082;
 vProxy                    := False;
 vProxyOptions             := TProxyOptions.Create;
 vPoolerList               := TStringList.Create;
 vEncoding                 := esUtf8;
End;

Constructor TRESTDWDataBase.Create(AOwner : TComponent);
Begin
 Inherited;
 vLogin                    := 'testserver';
 vMyIP                     := '0.0.0.0';
 vRestWebService           := '127.0.0.1';
 vCompression              := True;
 vPassword                 := vLogin;
 vRestModule               := '';
 vRestPooler               := '';
 vPoolerPort               := 8082;
 vProxy                    := False;
 vEncodeStrings            := True;
 vProxyOptions             := TProxyOptions.Create;
 vAutoCheckData            := TAutoCheckData.Create;
 vClientConnectionDefs     := TClientConnectionDefs.Create;
 vAutoCheckData.vAutoCheck := False;
 vAutoCheckData.vInTime    := 1000;
 vTimeOut                  := 10000;
 {$IFNDEF FPC}
 {$IF CompilerVersion > 21}
  vEncoding                := esUtf8;
 {$ELSE}
  vEncoding                := esAscii;
 {$IFEND}
 {$ELSE}
  vEncoding                := esUtf8;
 {$ENDIF}
 vContentex                := '';
 vStrsTrim                 := False;
 vStrsEmpty2Null           := False;
 vStrsTrim2Len             := True;
 {$IFDEF FPC}
 vDatabaseCharSet := csUndefined;
 {$ENDIF}
 vParamCreate              := True;
End;

Destructor  TRESTDWPoolerList.Destroy;
Begin
 vProxyOptions.Free;
 If vPoolerList <> Nil Then
  vPoolerList.Free;
 Inherited;
End;

Destructor  TRESTDWDataBase.Destroy;
Begin
 vAutoCheckData.vAutoCheck := False;
 FreeAndNil(vProxyOptions);
 FreeAndNil(vAutoCheckData);
 FreeAndNil(vClientConnectionDefs);
 Inherited;
End;

Procedure TRESTDWDataBase.ApplyUpdates(Var MassiveCache : TDWMassiveCache;
                                       Var Error        : Boolean;
                                       Var MessageError : String);
Var
 vUpdateLine       : String;
 vRESTConnectionDB : TDWPoolerMethodClient;
Begin
 If MassiveCache.MassiveCount > 0 Then
  Begin
   vUpdateLine := MassiveCache.ToJSON;
   If vRestPooler = '' Then
    Exit;
   If Not vConnected Then
    SetConnection(True);
   If vConnected Then
    Begin
     vRESTConnectionDB                  := TDWPoolerMethodClient.Create(Nil);
     vRESTConnectionDB.WelcomeMessage   := vWelcomeMessage;
     vRESTConnectionDB.Host             := vRestWebService;
     vRESTConnectionDB.Port             := vPoolerPort;
     vRESTConnectionDB.Compression      := vCompression;
     vRESTConnectionDB.TypeRequest      := VtypeRequest;
     vRESTConnectionDB.Encoding         := vEncoding;
     vRESTConnectionDB.AccessTag        := vAccessTag;
     {$IFNDEF FPC}
     vRESTConnectionDB.OnWork          := vOnWork;
     vRESTConnectionDB.OnWorkBegin     := vOnWorkBegin;
     vRESTConnectionDB.OnWorkEnd       := vOnWorkEnd;
     vRESTConnectionDB.OnStatus        := vOnStatus;
     {$ELSE}
     vRESTConnectionDB.OnWork          := vOnWork;
     vRESTConnectionDB.OnWorkBegin     := vOnWorkBegin;
     vRESTConnectionDB.OnWorkEnd       := vOnWorkEnd;
     vRESTConnectionDB.OnStatus        := vOnStatus;
     vRESTConnectionDB.DatabaseCharSet := vDatabaseCharSet;
     {$ENDIF}
     Try
      vRESTConnectionDB.ApplyUpdates_MassiveCache(vUpdateLine, vRestPooler,  vRestURL,
                                                  Error,       MessageError, vTimeOut,
                                                  vLogin,      vPassword,
                                                  vClientConnectionDefs.vConnectionDefs);
//      If Not Error Then
     Finally
      MassiveCache.Clear;
      FreeAndNil(vRESTConnectionDB);
     End;
    End;
  End;
End;

Procedure TRESTDWDataBase.Close;
Begin
 SetConnection(False);
End;

Function  TRESTDWPoolerList.TryConnect : Boolean;
Var
 vConnection : TDWPoolerMethodClient;
Begin
 Result                     := False;
 vConnection                := TDWPoolerMethodClient.Create(Nil);
 vConnection.WelcomeMessage := vWelcomeMessage;
 vConnection.Host           := vRestWebService;
 vConnection.Port           := vPoolerPort;
 vConnection.AccessTag      := vAccessTag;
 vConnection.Encoding       := Encoding;
 Try
  vPoolerList.Clear;
  vPoolerList.Assign(vConnection.GetPoolerList(vPoolerPrefix, 3000, vLogin, vPassword));
  Result      := True;
 Except
 End;
 vConnection.Free;
End;

Function  TRESTDWDataBase.TryConnect : Boolean;
Var
 vTempSend   : String;
 vConnection : TDWPoolerMethodClient;
Begin
 vConnection                := TDWPoolerMethodClient.Create(Nil);
 vConnection.TypeRequest    := vTypeRequest;
 vConnection.WelcomeMessage := vWelcomeMessage;
 vConnection.Host           := vRestWebService;
 vConnection.Port           := vPoolerPort;
 vConnection.Compression    := vCompression;
 vConnection.EncodeStrings  := EncodeStrings;
 vConnection.Encoding       := Encoding;
 vConnection.AccessTag      := vAccessTag;
 {$IFNDEF FPC}
  vConnection.OnWork        := vOnWork;
  vConnection.OnWorkBegin   := vOnWorkBegin;
  vConnection.OnWorkEnd     := vOnWorkEnd;
  vConnection.OnStatus      := vOnStatus;
  vConnection.Encoding      := vEncoding;
 {$ELSE}
  vConnection.OnWork          := vOnWork;
  vConnection.OnWorkBegin     := vOnWorkBegin;
  vConnection.OnWorkEnd       := vOnWorkEnd;
  vConnection.OnStatus        := vOnStatus;
  vConnection.DatabaseCharSet := vDatabaseCharSet;
 {$ENDIF}
 Try
  Try
   vTempSend   := vConnection.EchoPooler(vRestURL, vRestPooler, vTimeOut, vLogin, vPassword);
   Result      := Trim(vTempSend) <> '';
   If Result Then
    vMyIP       := vTempSend
   Else
    vMyIP       := '';
   If csDesigning in ComponentState Then
    If Not Result Then Raise Exception.Create(PChar('Error : ' + #13 + 'Authentication Error...'));
   If Trim(vMyIP) = '' Then
    Begin
     Result      := False;
     If Assigned(vOnEventConnection) Then
      vOnEventConnection(False, 'Authentication Error...');
    End;
  Except
   On E : Exception do
    Begin
     Result      := False;
     vMyIP       := '';
     If csDesigning in ComponentState Then
      Raise Exception.Create(PChar(E.Message));
     If Assigned(vOnEventConnection) Then
      vOnEventConnection(False, E.Message)
     Else
      Raise Exception.Create(E.Message);
    End;
  End;
 Finally
  If vConnection <> Nil Then
   FreeAndNil(vConnection);
 End;
End;

Procedure TRESTDWDataBase.SetConnection(Value : Boolean);
Begin
 If (Value) And
    (Trim(vRestPooler) = '') Then
  Exit;
 if (Value) And Not(vConnected) then
  If Assigned(vOnBeforeConnection) Then
   vOnBeforeConnection(Self);
 If Not(vConnected) And (Value) Then
  Begin
   If Value then
    vConnected := TryConnect
   Else
    vMyIP := '';
  End
 Else If Not (Value) Then
  Begin
   vConnected := Value;
   vMyIP := '';
  End;
End;

Procedure TRESTDWPoolerList.SetConnection(Value : Boolean);
Begin
 vConnected := Value;
 If vConnected Then
  vConnected := TryConnect;
End;

Procedure TRESTDWDataBase.SetPoolerPort(Value : Integer);
Begin
 vPoolerPort := Value;
End;

Procedure TRESTDWPoolerList.SetPoolerPort(Value : Integer);
Begin
 vPoolerPort := Value;
End;

Procedure TRESTDWDataBase.SetRestPooler(Value : String);
Begin
 vRestPooler := Value;
End;

procedure TRESTDWClientSQL.SetDataBase(Value: TRESTDWDataBase);
Begin
 If Value is TRESTDWDataBase Then
  Begin
   vRESTDataBase   := Value;
   TMassiveDatasetBuffer(vMassiveDataset).Encoding := TRESTDWDataBase(Value).Encoding;
  End
 Else
  vRESTDataBase := Nil;
End;

Procedure TRESTDWClientSQL.SetDatapacks(Value: Integer);
Begin
 vDatapacks := Value;
 If vDatapacks = 0 Then
  vDatapacks := -1;
End;

Procedure TRESTDWClientSQL.SetFiltered(aValue: Boolean);
Begin
 vFiltered := aValue;
 TDataset(Self).Filtered := vFiltered;
 If vFiltered Then
  ProcAfterScroll(Self);
End;

procedure TRESTDWClientSQL.SetInBlockEvents(const Value: Boolean);
begin
 vInBlockEvents := Value;
end;

procedure TRESTDWClientSQL.SetInDesignEvents(const Value: Boolean);
begin
 vInDesignEvents := Value;
end;

procedure TRESTDWClientSQL.SetInitDataset(const Value: Boolean);
begin
 vInitDataset := Value;
end;

procedure TRESTDWClientSQL.SetMasterDataSet(Value: TRESTDWClientSQL);
Begin
 If (vMasterDataSet <> Nil) Then
  TRESTDWClientSQL(vMasterDataSet).vMasterDetailList.DeleteDS(TRESTClient(Self));
 If (Value = Self) And (Value <> Nil) Then
  Begin
   vMasterDataSet := Nil;
   MasterFields   := '';
   Exit;
  End;
 vMasterDataSet := Value;
 If (vMasterDataSet <> Nil) Then
  Begin
   If vMasterDetailItem = Nil Then
    Begin
     vMasterDetailItem    := TMasterDetailItem.Create;
     vMasterDetailItem.DataSet := TRESTClient(Self);
     TRESTDWClientSQL(vMasterDataSet).vMasterDetailList.Add(vMasterDetailItem);
    End;
   vDataSource.DataSet := Value;
  End
 Else
  Begin
   MasterFields := '';
  End;
End;

Procedure TRESTDWClientSQL.Setnotrepage(Value: Boolean);
Begin
 vNotRepage := Value;
End;

Procedure TRESTDWClientSQL.SetOldCursor;
{$IFNDEF FPC}
{$IFDEF WINFMX}
Var
 CS: IFMXCursorService;
{$ENDIF}
{$ENDIF}
Begin
{$IFNDEF FPC}
 {$IFDEF WINFMX}
  If TPlatformServices.Current.SupportsPlatformService(IFMXCursorService) Then
   CS := TPlatformServices.Current.GetPlatformService(IFMXCursorService) As IFMXCursorService;
  If Assigned(CS) then
   CS.SetCursor(vOldCursor);
 {$ELSE}
  {$IFNDEF HAS_FMX}
   Screen.Cursor := vOldCursor;
  {$ENDIF}
 {$ENDIF}
{$ELSE}
 Screen.Cursor := vOldCursor;
{$ENDIF}
End;

procedure TRESTDWClientSQL.SetParams(const Value: TParams);
begin
 vParams.Assign(Value);
end;

procedure TRESTDWClientSQL.SetRecordCount(aJsonCount, aRecordCount : Integer);
begin
 vJsonCount      := aJsonCount;
 vOldRecordCount := aRecordCount;
end;

Procedure TRESTDWClientSQL.SetReflectChanges(Value: Boolean);
Begin
 vReflectChanges := Value;
 TMassiveDatasetBuffer(vMassiveDataset).ReflectChanges := vReflectChanges;
End;

constructor TRESTDWClientSQL.Create(AOwner: TComponent);
Begin
 Inherited;
 vParamCount                       := 0;
 vJsonCount                        := 0;
 vOldRecordCount                   := -1;
 vActualJSON                       := '';
 vInitDataset                      := False;
 vOnPacks                          := False;
 vInternalLast                     := False;
 vNotRepage                        := False;
 vInactive                         := False;
 vInBlockEvents                    := False;
 vOnOpenCursor                     := False;
 vDataCache                        := False;
 vAutoCommitData                   := False;
 vAutoRefreshAfterCommit           := False;
 vFiltered                         := False;
 vConnectedOnce                    := True;
 GetNewData                        := True;
 vReflectChanges                   := True;
 vActive                           := False;
 vCacheUpdateRecords               := True;
 vBeforeClone                      := False;
 vReadData                         := False;
 vActiveCursor                     := False;
 vInDesignEvents                   := False;
 vDatapacks                        := -1;
 vCascadeDelete                    := True;
 vSQL                              := TStringList.Create;
 {$IFDEF FPC}
  vSQL.OnChanging                  := @OnBeforeChangingSQL;
  vSQL.OnChange                    := @OnChangingSQL;
 {$ELSE}
  vSQL.OnChanging                  := OnBeforeChangingSQL;
  vSQL.OnChange                    := OnChangingSQL;
 {$ENDIF}
 vParams                           := TParams.Create(Self);
 vUpdateTableName                  := '';
 FieldDefsUPD                      := TFieldDefs.Create(Self);
 FieldDefs                         := FieldDefsUPD;
 vMasterDetailList                 := TMasterDetailList.Create;
 vMasterDataSet                    := Nil;
 vDataSource                       := TDataSource.Create(Nil);
 {$IFDEF FPC}
 TDataset(Self).AfterScroll        := @ProcAfterScroll;
 TDataset(Self).BeforeScroll       := @ProcBeforeScroll;
 TDataset(Self).BeforeOpen         := @ProcBeforeOpen;
 TDataset(Self).AfterOpen          := @ProcAfterOpen;
 TDataset(Self).AfterClose         := @ProcAfterClose;
 TDataset(Self).BeforeInsert       := @ProcBeforeInsert;
 TDataset(Self).AfterInsert        := @ProcAfterInsert;
 TDataset(Self).BeforeEdit         := @ProcBeforeEdit;
 TDataset(Self).AfterEdit          := @ProcAfterEdit;
 TDataset(Self).BeforePost         := @ProcBeforePost;
 TDataset(Self).AfterCancel        := @ProcAfterCancel;
 TDataset(Self).BeforeDelete       := @ProcBeforeDelete;
 TDataset(Self).OnNewRecord        := @ProcNewRecord;
 TDataset(Self).OnCalcFields       := @ProcCalcFields;
// TDataset(Self).Last               := @Last;
 Inherited AfterPost               := @OldAfterPost;
 Inherited AfterDelete             := @OldAfterDelete;
 {$ELSE}
 TDataset(Self).AfterScroll        := ProcAfterScroll;
 TDataset(Self).BeforeScroll       := ProcBeforeScroll;
 TDataset(Self).BeforeOpen         := ProcBeforeOpen;
 TDataset(Self).AfterOpen          := ProcAfterOpen;
 TDataset(Self).AfterClose         := ProcAfterClose;
 TDataset(Self).BeforeInsert       := ProcBeforeInsert;
 TDataset(Self).AfterInsert        := ProcAfterInsert;
 TDataset(Self).BeforeEdit         := ProcBeforeEdit;
 TDataset(Self).AfterEdit          := ProcAfterEdit;
 TDataset(Self).BeforePost         := ProcBeforePost;
 TDataset(Self).BeforeDelete       := ProcBeforeDelete;
 TDataset(Self).AfterCancel        := ProcAfterCancel;
 TDataset(Self).OnNewRecord        := ProcNewRecord;
 TDataset(Self).OnCalcFields       := ProcCalcFields;
 Inherited AfterPost               := OldAfterPost;
 Inherited AfterDelete             := OldAfterDelete;
 {$ENDIF}
 vMassiveDataset                   := TMassiveDatasetBuffer.Create(Self);
 vActionCursor                     := crSQLWait;
End;

destructor TRESTDWClientSQL.Destroy;
Begin
 FreeAndNil(vSQL);
 FreeAndNil(vParams);
 FreeAndNil(FieldDefsUPD);
 If (vMasterDataSet <> Nil) Then
  If vMasterDetailItem <> Nil Then
   TRESTDWClientSQL(vMasterDataSet).vMasterDetailList.DeleteDS(vMasterDetailItem.DataSet);
 FreeAndNil(vDataSource);
 If Assigned(vCacheDataDB) Then
  FreeAndNil(vCacheDataDB);
 vInactive := False;
 FreeAndNil(vMassiveDataset);
 If Assigned(vMasterDetailList) Then
  FreeAndNil(vMasterDetailList);
 NewFieldList;
 Inherited;
End;

procedure TRESTDWClientSQL.DWParams(Var Value: TDWParams);
Begin
 Value := Nil;
 If vRESTDataBase <> Nil Then
  If ParamCount > 0 Then
    Value := GetDWParams(vParams, vRESTDataBase.Encoding);
End;

procedure TRESTDWClientSQL.DynamicFilter(cFields: array of String;
  Value: String; InText: Boolean; AndOrOR: String);
Var
 I : Integer;
begin
 ExecOrOpen;
 Filter := '';
 If vActive Then
  Begin
   If Length(Value) > 0 Then
    Begin
     Filtered := False;
     For I := 0 to High(cFields) do
      Begin
       If I = High(cFields) Then
        AndOrOR := '';
       If InText Then
        Filter := Filter + Format('%s Like ''%s'' %s ', [cFields[I], '%' + Value + '%', AndOrOR])
       Else
        Filter := Filter + Format('%s Like ''%s'' %s ', [cFields[I], Value + '%', AndOrOR]);
      End;
     If Not (Filtered) Then
      Filtered := True;
    End
   Else
    Begin
     Filter   := '';
     Filtered := False;
    End;
  End;
End;

Function ScanParams(SQL : String) : TStringList;
Var
 vTemp        : String;
 FCurrentPos  : PChar;
 vOldChar     : Char;
 vParamName   : String;
 Function GetParamName : String;
 Begin
  Result := '';
  If FCurrentPos^ = ':' Then
   Begin
    Inc(FCurrentPos);
    if vOldChar in [' ', '=', '-', '+', '<', '>', '(', ')', ':', '|'] then
     Begin
      While Not (FCurrentPos^ = #0) Do
       Begin
        if FCurrentPos^ in ['0'..'9', 'A'..'Z','a'..'z', '_'] then

         Result := Result + FCurrentPos^
        Else
         Break;
        Inc(FCurrentPos);
       End;
     End;
   End
  Else
   Inc(FCurrentPos);
  vOldChar := FCurrentPos^;
 End;
Begin
 Result := TStringList.Create;
 vTemp  := SQL;
 FCurrentPos := PChar(vTemp);
 While Not (FCurrentPos^ = #0) do
  Begin
   If Not (FCurrentPos^ in [#0..' ', ',',
                           '''', '"',
                           '0'..'9', 'A'..'Z',
                           'a'..'z', '_',
                           '$', #127..#255]) Then


    Begin
     vParamName := GetParamName;
     If Trim(vParamName) <> '' Then
      Begin
       Result.Add(vParamName);
       Inc(FCurrentPos);
      End;
    End
   Else
    Begin
     vOldChar := FCurrentPos^;
     Inc(FCurrentPos);
    End;
  End;
End;

Function ReturnParams(SQL : String) : TStringList;
Begin
 Result := ScanParams(SQL);
End;

Function ReturnParamsAtual(ParamsList : TParams) : TStringList;
Var
 I : Integer;
Begin
 Result := Nil;
 If ParamsList.Count > 0 Then
  Begin
   Result := TStringList.Create;
   For I := 0 To ParamsList.Count -1 Do
    Result.Add(ParamsList[I].Name);
  End;
End;

procedure TRESTDWClientSQL.CreateParams;
Var
 I         : Integer;
 ParamsListAtual,
 ParamList : TStringList;
 Procedure CreateParam(Value : String);
  Function ParamSeek (Name : String) : Boolean;
  Var
   I : Integer;
  Begin
   Result := False;
   For I := 0 To vParams.Count -1 Do
    Begin
     Result := LowerCase(vParams.items[i].Name) = LowerCase(Name);
     If Result Then
      Break;
    End;
  End;
 Var
  FieldDef : TField;
 Begin
  FieldDef := FindField(Value);
  If FieldDef <> Nil Then
   Begin
    If Not (ParamSeek(Value)) Then
     Begin
      vParams.CreateParam(FieldDef.DataType, Value, ptInput);
      vParams.ParamByName(Value).Size := FieldDef.Size;
//      If FieldDef.DataType in [ftSmallint, ftInteger, ftLargeint, ftWord,
//                               {$IFNDEF FPC}{$IF CompilerVersion > 21}ftLongWord,{$IFEND}{$ENDIF}
//                               ftBoolean, ftFloat, ftCurrency, ftBCD, ftFMTBcd] Then
//       vParams.ParamByName(Value).Value := -1;
     End;
   End
  Else If Not(ParamSeek(Value)) Then
   vParams.CreateParam(ftString, Value, ptInput);
 End;
 Function CompareParams(A, B : TStringList) : Boolean;
 Var
  I, X : Integer;
 Begin
  Result := (A <> Nil) And (B <> Nil);
  If Result Then
   Begin
    For I := 0 To A.Count -1 Do
     Begin
      For X := 0 To B.Count -1 Do
       Begin
        Result := lowercase(A[I]) = lowercase(B[X]);
        If Result Then
         Break;
       End;
      If Not Result Then
       Break;
     End;
   End;
  If Result Then
   Result := B.Count > 0;
 End;
Begin
 ParamList       := ReturnParams(vSQL.Text);
 ParamsListAtual := ReturnParamsAtual(vParams);
 vParamCount     := 0;
 If Not CompareParams(ParamsListAtual, ParamList) Then
  vParams.Clear;
 If ParamList <> Nil Then
 For I := 0 to ParamList.Count -1 Do
  CreateParam(ParamList[I]);
 If ParamList.Count > 0 Then
  vParamCount := vParams.Count;
 ParamList.Free;
  if Assigned(ParamsListAtual) then
   FreeAndNil(ParamsListAtual);
End;

procedure TRESTDWClientSQL.ProcCalcFields(DataSet: TDataSet);
Begin
 If (vInBlockEvents) Then
  Exit;
 If Assigned(vOnCalcFields) Then
  vOnCalcFields(Dataset);
End;

procedure TRESTDWClientSQL.ProcAfterScroll(DataSet: TDataSet);
Var
 JSONValue    : TJSONValue;
 vRecordCount : Integer;
Begin
 If vInBlockEvents Then
  Exit;
 If State = dsBrowse Then
  Begin
   If Not Active Then
    PrepareDetailsNew
   Else
    Begin
     vActualRec      := Recno;
     vRecordCount    := vOldRecordCount;
     If Not vNotRepage Then
      Begin
       If (vRESTDataBase <> Nil)                  And
          ((vDatapacks > -1) And (vActualRec > 0) And
           (vActualRec = vRecordCount)            And
           (vRecordCount < vJsonCount))           Then
        Begin
         vOnPacks := True;
         JSONValue := TJSONValue.Create;
         Try
          JSONValue.Encoding := vRESTDataBase.Encoding;
          JSONValue.Encoded  := vRESTDataBase.EncodeStrings;
          If vInternalLast Then
           Begin
            vInternalLast := False;
            JSONValue.WriteToDataset(dtFull, vActualJSON, Self, vJsonCount, vJsonCount - vActualRec, vActualRec);
            vOldRecordCount := vJsonCount;
            Last;
           End
          Else
           Begin
            JSONValue.WriteToDataset(dtFull, vActualJSON, Self, vJsonCount, vDatapacks, vActualRec);
            vOldRecordCount := Recno + vDatapacks;
            If vOldRecordCount > vJsonCount Then
             vOldRecordCount := vJsonCount;
           End;
         Finally
          JSONValue.Free;
          vOnPacks := False;
         End;
        End;
      End;
     vNotRepage := False;
     If RecordCount = 0 Then
      PrepareDetailsNew
     Else
      PrepareDetails(True)
    End;
  End
 Else If State = dsInactive Then
  PrepareDetails(False)
 Else If State = dsInsert Then
  PrepareDetailsNew;
 If Not ((vOnPacks) or (vInitDataset)) Then
  If Assigned(vOnAfterScroll) Then
   vOnAfterScroll(Dataset);
End;

procedure TRESTDWClientSQL.GotoRec(const aRecNo: Integer);
Var
 ActiveRecNo,
 Distance     : Integer;
Begin
 If (RecNo > 0) Then
  Begin
   ActiveRecNo := Self.RecNo;
   If (RecNo <> ActiveRecNo) Then
    Begin
     Self.DisableControls;
     Try
      Distance := RecNo - ActiveRecNo;
      Self.MoveBy(Distance);
     Finally
      Self.EnableControls;
     End;
    End;
  End;
End;

procedure TRESTDWClientSQL.ProcBeforeDelete(DataSet: TDataSet);
Var
 I             : Integer;
 vDetailClient : TRESTDWClientSQL;
 vBookmarkA    : ^TBookmarkStr;
Begin
 If Not vReadData Then
  Begin
   vReadData := True;
   vOldStatus   := State;
   Try
    vActualRec   := RecNo;
   Except
    vActualRec   := -1;
   End;
   Try
//    SaveToStream(OldData);
    If vCascadeDelete Then
     Begin
      For I := 0 To vMasterDetailList.Count -1 Do
       Begin
        vMasterDetailList.Items[I].ParseFields(TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
        vDetailClient        := TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet);
        If vDetailClient <> Nil Then
         Begin
          Try
           vDetailClient.First;
           While Not vDetailClient.Eof Do
            vDetailClient.Delete;
          Finally
           vReadData := False;
          End;
         End;
       End;
     End;
    If Not((vInBlockEvents) or (vInitDataset)) Then
     Begin
      If Trim(vUpdateTableName) <> '' Then
       Begin
        New(vBookmarkA);
        vBookmarkA^ := TBookmarkStr(Self.Bookmark); //TODO
//        TMassiveDatasetBuffer(vMassiveDataset).NewBuffer  (Self, mmDelete);
        TMassiveDatasetBuffer(vMassiveDataset).BuildBuffer(Self, mmDelete, vBookmarkA^);
        TMassiveDatasetBuffer(vMassiveDataset).SaveBuffer(Self);
        Dispose(vBookmarkA);
        If vMassiveCache <> Nil Then
         Begin
          vMassiveCache.Add(TMassiveDatasetBuffer(vMassiveDataset).ToJSON);
          TMassiveDatasetBuffer(vMassiveDataset).ClearBuffer;
         End;
       End;
      If Assigned(vBeforeDelete) Then
       vBeforeDelete(DataSet);
     End;
    vReadData := False;
   Except
     //Alexande Magno - 28/11/2018 - Pedido do Magnele
    on e : Exception do
    begin
     vReadData := False;
     raise Exception.Create(e.Message);
     Abort;
    end;
   End;
  End;
End;

procedure TRESTDWClientSQL.ProcBeforeEdit(DataSet: TDataSet);
Var
 vBookmarkA : TBookmarkStr;
Begin
 vBookmarkA := #0;
 If Not((vInBlockEvents) or (vInitDataset)) Then
  Begin
   If Trim(vUpdateTableName) <> '' Then
    Begin
     TMassiveDatasetBuffer(vMassiveDataset).NewBuffer  (Self, mmUpdate);
     TMassiveDatasetBuffer(vMassiveDataset).BuildBuffer(Self, mmUpdate, vBookmarkA);
    End;
   If Assigned(vBeforeEdit) Then
    vBeforeEdit(Dataset);
  End;
End;

procedure TRESTDWClientSQL.ProcBeforeInsert(DataSet: TDataSet);
Begin
 If Not((vInBlockEvents) or (vInitDataset)) Then
  Begin
   If Assigned(vBeforeInsert) Then
    vBeforeInsert(Dataset);
//   SaveToStream(OldData);
  End;
End;

procedure TRESTDWClientSQL.ProcBeforeOpen(DataSet: TDataSet);
Begin
 If Not((vInBlockEvents) or (vInitDataset)) Then
  If Assigned(vBeforeOpen) Then
   vBeforeOpen(Dataset);
End;

procedure TRESTDWClientSQL.ProcBeforePost(DataSet: TDataSet);
Var
 vBookmarkA : ^TBookmarkStr;
Begin
 If Not vReadData Then
  Begin
   vActualRec    := -1;
   vReadData     := True;
   vOldState     := State;
   vOldStatus    := State;
   Try
    If vOldState = dsInsert then
     vActualRec  := RecNo + 1
    Else
     vActualRec  := RecNo;
    Edit;
    vReadData     := False;
    If Not((vInBlockEvents) or (vInitDataset)) Then
     Begin
      If Assigned(vBeforePost) Then
       vBeforePost(DataSet);
      If (Trim(vUpdateTableName) <> '') And (vOldState = dsEdit) Then
       Begin
        New(vBookmarkA);
        vBookmarkA^ := TBookmarkStr(Self.Bookmark); //TODO
        TMassiveDatasetBuffer(vMassiveDataset).BuildBuffer(Self, DatasetStateToMassiveType(vOldState), vBookmarkA^, vOldState = dsEdit);
        Dispose(vBookmarkA);
        If vOldState = dsEdit Then
         Begin
          If TMassiveDatasetBuffer(vMassiveDataset).TempBuffer <> Nil Then
           Begin
            If TMassiveDatasetBuffer(vMassiveDataset).TempBuffer.UpdateFieldChanges <> Nil Then
             Begin
              If TMassiveDatasetBuffer(vMassiveDataset).TempBuffer.UpdateFieldChanges.Count = 0 Then
               TMassiveDatasetBuffer(vMassiveDataset).ClearLine
              Else
               TMassiveDatasetBuffer(vMassiveDataset).SaveBuffer(Self);
             End
            Else
             TMassiveDatasetBuffer(vMassiveDataset).ClearLine;
           End
          Else
           TMassiveDatasetBuffer(vMassiveDataset).ClearLine;
         End
        Else
         TMassiveDatasetBuffer(vMassiveDataset).SaveBuffer(Self);
        If vMassiveCache <> Nil Then
         Begin
          vMassiveCache.Add(TMassiveDatasetBuffer(vMassiveDataset).ToJSON);
          TMassiveDatasetBuffer(vMassiveDataset).ClearBuffer;
         End;
       End;
     End;
   Except
    //Alexande Magno - 28/11/2018 - Pedido do Magnele
    on e : Exception do
    begin
     vActualRec   := -1;
     vReadData    := False;
     raise Exception.Create(e.Message);
     Abort;
    end;
   End;
  End;
End;

Procedure TRESTDWClientSQL.ProcBeforeScroll(DataSet: TDataSet);
Begin
 If ((vInBlockEvents) or (vInitDataset)) Then
  Exit;
 If Not vOnPacks Then
  If Assigned(vOnBeforeScroll) Then
   vOnBeforeScroll(Dataset);
End;

procedure TRESTDWClientSQL.ProcNewRecord(DataSet: TDataSet);
begin
 If Not ((vInBlockEvents) or (vInitDataset)) Then
  Begin
   If Assigned(vNewRecord) Then
    vNewRecord(Dataset);
  End;
end;

procedure TRESTDWClientSQL.RebuildMassiveDataset;
Begin
 CreateMassiveDataset;
End;

procedure TRESTDWClientSQL.Refresh;
Var
 Cursor : Integer;
Begin
 Cursor := 0;
 If Active then
  Begin
   If RecordCount > 0 then
    Cursor := Self.CurrentRecord;
   Close;
   Open;
   If Active then
    Begin
     If RecordCount > 0 Then
      MoveBy(Cursor);
    End;
  End;
End;

procedure TRESTDWClientSQL.RestoreDatasetPosition;
begin
 vInBlockEvents := False;
// LoadfromStream(OldData);
 TMassiveDatasetBuffer(vMassiveDataset).ClearBuffer;

 RebuildMassiveDataset;
 vInBlockEvents := False;
end;

procedure TRESTDWClientSQL.ProcAfterClose(DataSet: TDataSet);
Var
 I : Integer;
 vDetailClient : TRESTDWClientSQL;
Begin
 vActualJSON   := '';
 If Assigned(vOnAfterClose) then
  vOnAfterClose(Dataset);
 If vCascadeDelete Then
  Begin
   For I := 0 To vMasterDetailList.Count -1 Do
    Begin
     vMasterDetailList.Items[I].ParseFields(TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
     vDetailClient        := TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet);
     If vDetailClient <> Nil Then
      vDetailClient.Close;
    End;
  End;
End;

procedure TRESTDWClientSQL.ProcAfterEdit(DataSet: TDataSet);
Begin
 If Not ((vInBlockEvents) or (vInitDataset)) Then
  If Assigned(vAfterEdit) Then
   vAfterEdit(Dataset);
End;

procedure TRESTDWClientSQL.ProcAfterInsert(DataSet: TDataSet);
Var
 I : Integer;
 vFields       : TStringList;
 vDetailClient : TRESTDWClientSQL;
 vBookmarkA    : TBookmarkStr;
 Procedure CloneDetails(Value : TRESTDWClientSQL; FieldName : String);
 Begin
  If (FindField(FieldName) <> Nil) And (Value.FindField(FieldName) <> Nil) Then
   FindField(FieldName).Value := Value.FindField(FieldName).Value;
 End;
 Procedure ParseFields(Value : String);
 Var
  vTempFields : String;
 Begin
  vFields.Clear;
  vTempFields := Value;
  While (vTempFields <> '') Do
   Begin
    If Pos(';', vTempFields) > 0 Then
     Begin
      vFields.Add(UpperCase(Trim(Copy(vTempFields, 1, Pos(';', vTempFields) -1))));
      System.Delete(vTempFields, 1, Pos(';', vTempFields));
     End
    Else
     Begin
      vFields.Add(UpperCase(Trim(vTempFields)));
      vTempFields := '';
     End;
    vTempFields := Trim(vTempFields);
   End;
 End;
Begin
 vBookmarkA    := #0;
 vDetailClient := vMasterDataSet;
 If (vDetailClient <> Nil) And (Fields.Count > 0) Then
  Begin
   vFields     := TStringList.Create;
   ParseFields(MasterFields);
   For I := 0 To vFields.Count -1 Do
    Begin
     If vDetailClient.FindField(vFields[I]) <> Nil Then
      CloneDetails(vDetailClient, vFields[I]);
    End;
   vFields.Free;
  End;
 If Not ((vInBlockEvents) or (vInitDataset)) Then
  Begin
   If Trim(vUpdateTableName) <> '' Then
    Begin
     TMassiveDatasetBuffer(vMassiveDataset).NewBuffer(mmInsert);
     TMassiveDatasetBuffer(vMassiveDataset).BuildBuffer(Self, mmInsert, vBookmarkA);
    End;
   If Assigned(vAfterInsert) Then
    vAfterInsert(Dataset);
  End;
End;

procedure TRESTDWClientSQL.ProcAfterOpen(DataSet: TDataSet);
Begin
 If Not ((vInBlockEvents) or (vInitDataset)) Then
  Begin
   If Assigned(vOnAfterOpen) Then
    vOnAfterOpen(Dataset);
  End;
End;

procedure TRESTDWClientSQL.ProcAfterCancel(DataSet: TDataSet);
Begin
 If Not ((vInBlockEvents) or (vInitDataset)) Then
  Begin
   If Trim(vUpdateTableName) <> '' Then
    TMassiveDatasetBuffer(vMassiveDataset).ClearLine;
   If Assigned(vAfterCancel) Then
    vAfterCancel(Dataset);
  End;
End;

function TRESTDWClientSQL.ApplyUpdates(Var Error: String): Boolean;
Var
 vError       : Boolean;
 vErrorMSG,
 vMassiveJSON : String;
 vResult      : TJSONValue;
Begin
 Result  := False;
 vResult := Nil;
 If TMassiveDatasetBuffer(vMassiveDataset).RecordCount = 0 Then
  Error := 'No have data to "Applyupdates"...'
 Else
  Begin
   vMassiveJSON := TMassiveDatasetBuffer(vMassiveDataset).ToJSON;
   Result       := vMassiveJSON <> '';
   If Result Then
    Begin
     Result     := False;
     If vRESTDataBase <> Nil Then
      Begin
       If vAutoRefreshAfterCommit Then
        vRESTDataBase.ApplyUpdates(TMassiveDatasetBuffer(vMassiveDataset), vSQL, vParams, vError, vErrorMSG, vResult, Nil)
       Else
        vRESTDataBase.ApplyUpdates(TMassiveDatasetBuffer(vMassiveDataset), Nil,  vParams, vError, vErrorMSG, vResult, Nil);
       Result := Not vError;
       Error  := vErrorMSG;
       If (Assigned(vResult) And (vAutoRefreshAfterCommit)) And
          (Not (TMassiveDatasetBuffer(vMassiveDataset).ReflectChanges)) Then
        Begin
         Try
          vActive := False;
          ProcBeforeOpen(Self);
          vInBlockEvents := True;
          Filter         := '';
          Filtered       := False;
          vActive        := GetData(vResult);
          If State = dsBrowse Then
           Begin
            If Trim(vUpdateTableName) <> '' Then
             TMassiveDatasetBuffer(vMassiveDataset).BuildDataset(Self, Trim(vUpdateTableName));
            PrepareDetails(True);
           End
          Else If State = dsInactive Then
           PrepareDetails(False);
          vInBlockEvents := False; //Alexandre Magno - 09/10/2018
         Except
          On E : Exception do
           Begin
            vInBlockEvents := False;
            If csDesigning in ComponentState Then
             Raise Exception.Create(PChar(E.Message))
            Else
             Begin
              If Assigned(vOnGetDataError) Then
               vOnGetDataError(False, E.Message)
              Else
               Raise Exception.Create(PChar(E.Message));
             End;
           End;
         End;
        End
       Else If Assigned(vResult) And
                       (TMassiveDatasetBuffer(vMassiveDataset).ReflectChanges) Then
        Begin
         //Edit Dataset with values back.
         vMassiveJSON := vResult.Value;

        End
       Else
        Begin
         If vError Then
          Begin
//           LoadFromStream(OldData);
           vInBlockEvents := False;
           TMassiveDatasetBuffer(vMassiveDataset).ClearBuffer;
           RebuildMassiveDataset;
           If Assigned(vOnGetDataError) Then
            vOnGetDataError(False, vErrorMSG);
          End;
        End;
       If Assigned(vResult) Then
        FreeAndNil(vResult);
      End
     Else
      Error := 'Empty Database Property';
    End;
   If Result Then
    TMassiveDatasetBuffer(vMassiveDataset).ClearBuffer
   Else
    Error := vErrorMSG;
  End;
End;

function TRESTDWClientSQL.ParamByName(Value: String): TParam;
Var
 I : Integer;
 vParamName,
 vTempParam : String;
 Function CompareValue(Value1, Value2 : String) : Boolean;
 Begin
   Result := Value1 = Value2;
 End;
Begin
 Result := Nil;
 For I := 0 to vParams.Count -1 do
  Begin
   vParamName := UpperCase(vParams[I].Name);
   vTempParam := UpperCase(Trim(Value));
   if CompareValue(vTempParam, vParamName) then
    Begin
     Result := vParams[I];
     Break;
    End;
  End;
End;

function TRESTDWClientSQL.ParamCount: Integer;
Begin
 Result := vParamCount; //vParams.Count;
End;

procedure TRESTDWClientSQL.FieldDefsToFields;
Var
 I          : Integer;
 FieldValue : TField;
Begin
 For I := 0 To FieldDefs.Count -1 Do
  Begin
   FieldValue           := TField.Create(Self);
   FieldValue.DataSet   := Self;
   FieldValue.FieldName := FieldDefs[I].Name;
   FieldValue.SetFieldType(FieldDefs[I].DataType);
   FieldValue.Size      := FieldDefs[I].Size;
//   FieldValue.Offset    := FieldDefs[I].Precision;
   Fields.Add(FieldValue);
  End;
End;

function TRESTDWClientSQL.FirstWord(Value: String): String;
Var
 vTempValue : PChar;
Begin
 vTempValue := PChar(Trim(Value));
 While Not (vTempValue^ = #0) Do
  Begin
   If (vTempValue^ <> ' ') Then
    Result := Result + vTempValue^
   Else
    Break;
   Inc(vTempValue);
  End;
End;

procedure TRESTDWClientSQL.ExecOrOpen;
Var
 vError : String;
 Function OpenSQL : Boolean;
 Var
  vSQLText : String;
 Begin
  vSQLText := UpperCase(Trim(vSQL.Text));
  Result := FirstWord(vSQLText) = 'SELECT';
 End;
Begin
 If OpenSQL Then
  Open
 Else
  Begin
   If Not ExecSQL(vError) Then
    Begin
     If csDesigning in ComponentState Then
      Raise Exception.Create(PChar(vError))
     Else
      Begin
       If Assigned(vOnGetDataError) Then
        vOnGetDataError(False, vError)
       Else
        Raise Exception.Create(PChar(vError));
      End;
    End;
  End;
End;

function TRESTDWClientSQL.ExecSQL(Var Error: String): Boolean;
Var
 vError        : Boolean;
 vMessageError : String;
 vResult       : TJSONValue;
Begin
 Try
  ChangeCursor;
  Result := False;
  Try
   If vRESTDataBase <> Nil Then
    Begin
     vRESTDataBase.ExecuteCommand(vSQL, vParams, vError, vMessageError, vResult, True, Nil);
     Result := Not vError;
     Error  := vMessageError;
     If Assigned(vResult) Then
      FreeAndNil(vResult);
    End
   Else
    Raise Exception.Create(PChar('Empty Database Property'));
  Except
  End;
 Finally
  ChangeCursor(True);
 End;
End;

function TRESTDWClientSQL.InsertMySQLReturnID: Integer;
Var
 vError        : Boolean;
 vMessageError : String;
Begin
 Result := -1;
 Try
  If vRESTDataBase <> Nil Then
   Result := vRESTDataBase.InsertMySQLReturnID(vSQL, vParams, vError, vMessageError,  Nil)
  Else 
   Raise Exception.Create(PChar('Empty Database Property')); 
 Except
 End;
End;

procedure TRESTDWClientSQL.OnBeforeChangingSQL(Sender: TObject);
begin
 vOldSQL := vSQL.Text;
end;

procedure TRESTDWClientSQL.OnChangingSQL(Sender: TObject);
Begin
 GetNewData := vSQL.Text <> vOldSQL;
 CreateParams;
End;

procedure TRESTDWClientSQL.SetSQL(Value: TStringList);
Var
 I : Integer;
Begin
 vSQL.Clear;
 For I := 0 To Value.Count -1 do
  vSQL.Add(Value[I]);
End;

procedure TRESTDWClientSQL.CreateDataSet;
Begin
 vCreateDS := True;
 SetInBlockEvents(True);
 Try
  {$IFDEF FPC}
   {$IFDEF ZEOSDRIVER} //TODO

   {$ENDIF}
   {$IFDEF DWMEMTABLE}
    TDWMemtable(Self).Close;
    TDWMemtable(Self).Open;
   {$ENDIF}
   {$IFDEF LAZDRIVER}
    TMemDataset(Self).CreateTable;
    TMemDataset(Self).Open;
   {$ENDIF}
  {$ELSE}
  {$IFDEF CLIENTDATASET}
   TClientDataset(Self).CreateDataSet;
   TClientDataset(Self).Open;
  {$ENDIF}
  {$IFDEF RESJEDI}
   TJvMemoryData(Self).Close;
   TJvMemoryData(Self).Open;
  {$ENDIF}
  {$IFDEF RESTKBMMEMTABLE}
   Tkbmmemtable(self).open;
  {$ENDIF}
  {$IFDEF RESTFDMEMTABLE}
   TFDmemtable(self).CreateDataSet;
   TFDmemtable(self).Open;
  {$ENDIF}
  {$IFDEF DWMEMTABLE}
   TDWMemtable(Self).Close;
   TDWMemtable(Self).Open;
   {$ENDIF}
  {$ENDIF}
  vCreateDS := False;
  vActive   := Not vCreateDS;
 Finally
 End;
End;

procedure TRESTDWClientSQL.CreateDatasetFromList;
Var
 I        : Integer;
 FieldDef : TFieldDef;
Begin
 TDataset(Self).Close;
 For I := 0 To Length(vFieldsList) -1 Do
  Begin
   FieldDef := FieldDefExist(vFieldsList[I].FieldName);
   If FieldDef = Nil Then
    Begin
     FieldDef          := TDataset(Self).FieldDefs.AddFieldDef;
     FieldDef.Name     := vFieldsList[I].FieldName;
     FieldDef.DataType := vFieldsList[I].DataType;
     FieldDef.Size     := vFieldsList[I].Size;
     If FieldDef.DataType In [ftFloat, ftCurrency, ftBCD, {$IFNDEF FPC}{$IF CompilerVersion > 21}ftExtended, ftSingle,
                                                          {$IFEND}{$ENDIF}ftFMTBcd] Then
      Begin
       FieldDef.Size      := vFieldsList[I].Size;
       FieldDef.Precision := vFieldsList[I].Precision;
      End;
     FieldDef.Required    :=  vFieldsList[I].Required;
    End
   Else
    FieldDef.Required    :=  vFieldsList[I].Required;
  End;
 CreateDataset;
End;

Procedure TRESTDWClientSQL.ChangeCursor(OldCursor : Boolean = False);
Begin
 If Not OldCursor Then
  Begin
   GetTmpCursor;
   SetCursor;
  End
 Else
  SetOldCursor;
End;

procedure TRESTDWClientSQL.CleanFieldList;
Var
 I : Integer;
Begin
 If Self is TRESTDWClientSQL Then
  For I := 0 To Length(vFieldsList) -1 Do
   FreeAndNil(vFieldsList[I]);
End;

procedure TRESTDWClientSQL.ClearMassive;
Begin
 If Trim(vUpdateTableName) <> '' Then
  If TMassiveDatasetBuffer(vMassiveDataset).RecordCount > 0 Then
   TMassiveDatasetBuffer(vMassiveDataset).ClearBuffer;
End;

procedure TRESTDWClientSQL.Close;
Begin
 vActive         := False;
 vInactive       := False;
 vInternalLast   := False;
 vOldRecordCount := -1;
 Inherited Close;
End;

procedure TRESTDWClientSQL.Open;
Begin
 Try
  If Not vInactive Then
   Begin
    If (vActive) And (Assigned(vDWResponseTranslator)) Then
     vActive := False;
    If Not vActive Then
     SetActiveDB(True);
   End;
//  vInBlockEvents := True;
  If vActive Then
   Begin
    ProcAfterOpen(Self);
    Inherited Open;
   End;
 Finally
  vInBlockEvents  := False;
 End;
End;

procedure TRESTDWClientSQL.Open(strSQL: String);
Begin
 If Not vActive Then
  Begin
   Close;
   vSQL.Clear;
   vSQL.Add(strSQL);
   SetActiveDB(True);
   Inherited Open;
  End;
End;

procedure TRESTDWClientSQL.OpenCursor(InfoQuery: Boolean);
Begin
 Try
  If (vRESTDataBase <> Nil) And
     ((Not(((vInBlockEvents) or (vInitDataset))) or (GetNewData)) Or (vInDesignEvents)) And
       Not(vActive) Then
   Begin
    GetNewData := False;
    If Not (vRESTDataBase.Active)   Then
     vRESTDataBase.Active := True;
    If  ((Self.FieldDefs.Count = 0) Or
         (vInDesignEvents))         And
        (Not (vActiveCursor))       Then
     Begin
      vActiveCursor := True;
      Try
       SetActiveDB(True);
       If vActive Then
        Begin
         Inherited Open;
         vActiveCursor := False;
         Exit;
        End;
      Except
      End;
      vActiveCursor := False;
     End
    Else If ((Self.FieldDefs.Count > 0) Or
             (Self.Fields.Count > 0)    Or
             (vInDesignEvents))         Then
     Begin
      Try
       Inherited OpenCursor(InfoQuery);
      Except
       If Not (csDesigning in ComponentState) Then
        Exception.Create(Name + ': ' + 'Error when try open Dataset...');
      End;
     End
    Else If (Self.FieldDefs.Count = 0)    And
            (Self.FieldListCount = 0) Then
     Raise Exception.Create(Name + ': ' + 'No Fields to add on Dataset...')
    Else If Not (csDesigning in ComponentState) Then
     Raise Exception.Create(Name + ': ' + 'Error when try open Dataset...');
   End
  Else If ((vRESTDataBase <> Nil) Or (Assigned(vDWResponseTranslator))) And
          ((Self.FieldDefs.Count > 0)) Then
   Begin
    Inherited OpenCursor(InfoQuery);
   End
  Else If csDesigning in ComponentState Then
   Begin
    If (vRESTDataBase = Nil) then
     Raise Exception.Create(Name + ': ' + 'Database not found...')
    Else If Not (csDesigning in ComponentState) Then
     Raise Exception.Create(Name + ': '+ ' Error when open dataset...');
   End;
 Except
  On E : Exception do
   Begin
    If csDesigning in ComponentState Then
     Raise Exception.Create(Name+': '+PChar(E.Message))
    Else
     Begin
      If Assigned(vOnGetDataError) Then
       vOnGetDataError(False, Name+': '+E.Message)
      Else
       Raise Exception.Create(PChar(Name+': '+E.Message));
     End;
   End;
 End;
End;

procedure TRESTDWClientSQL.OldAfterPost(DataSet: TDataSet);
Var
 vError     : String;
 vBookmarkA : ^TBookmarkStr;
Begin
 vErrorBefore := False;
 vError       := '';
 If Not vReadData Then
  Begin
   If Not ((vInBlockEvents) or (vInitDataset)) Then
    Begin
     Try
      If (Trim(vUpdateTableName) <> '') And (vOldState = dsInsert) Then
       Begin
        New(vBookmarkA);
        vBookmarkA^ := TBookmarkStr(Self.Bookmark); //TODO
        TMassiveDatasetBuffer(vMassiveDataset).BuildBuffer(Self, DatasetStateToMassiveType(vOldState), vBookmarkA^, vOldState = dsEdit);
        Dispose(vBookmarkA);
        TMassiveDatasetBuffer(vMassiveDataset).SaveBuffer(Self);
        If vMassiveCache <> Nil Then
         Begin
          vMassiveCache.Add(TMassiveDatasetBuffer(vMassiveDataset).ToJSON);
          TMassiveDatasetBuffer(vMassiveDataset).ClearBuffer;
         End;
       End;
      If (Trim(vUpdateTableName) <> '') Then
       If vAutoCommitData Then
        If TMassiveDatasetBuffer(vMassiveDataset).RecordCount > 0 Then
         ApplyUpdates(vError);
      If vError <> '' Then
       Raise Exception.Create(vError)
      Else
       Begin
        If Assigned(vAfterPost) Then
         vAfterPost(Dataset);
        ProcAfterScroll(Dataset);
       End;
     Except

     End;
    End;
  End;
End;

procedure TRESTDWClientSQL.OldAfterDelete(DataSet: TDataSet);
Var
 vError : String;
Begin
 vErrorBefore := False;
 vError       := '';
 Try
  If Not vReadData Then
   Begin
    Try
     If Trim(vUpdateTableName) <> '' Then
      If vAutoCommitData Then
       If TMassiveDatasetBuffer(vMassiveDataset).RecordCount > 0 Then
        ApplyUpdates(vError);
     If vError <> '' Then
      Raise Exception.Create(vError)
     Else
      Begin
       If Assigned(vAfterDelete) Then  //MAGNo
        vAfterDelete(Self);
       ProcAfterScroll(Dataset);
      End;
    Except
    End;
   End;
 Finally
  vReadData := False;
 End;
End;

procedure TRESTDWClientSQL.SetUpdateTableName(Value: String);
Begin
 vCommitUpdates    := Trim(Value) <> '';
 vUpdateTableName  := Value;
End;

Procedure TRESTDWClientSQL.InternalLast;
Begin
 If Not ((vInBlockEvents) or (vInitDataset)) Then
  Begin
   vActualRec    := vJsonCount;
   vInternalLast := True;
  End;
 Inherited InternalLast;
End;

procedure TRESTDWClientSQL.Loaded;
Begin
 Inherited Loaded;
  try
    if not (csDesigning in ComponentState) then
      SetActiveDB(False);
  except
    if not (csDesigning in ComponentState) then
      raise;
  end;
End;

procedure TRESTDWClientSQL.LoadFromStream(Stream: TRESTDWClientSQLBase);
begin
 DisableControls;
 CreateDatasetFromList;
 Close;
 {$IFDEF FPC}
  {$IFNDEF RESTKBMMEMTABLE}
   {$IFDEF DWMEMTABLE} //TODO
   {$ELSE}
    CopyFromDataset(Stream, True);
   {$ENDIF}
  {$ELSE}
//   LoadFromDataSet(Stream, []); //TODO
  {$ENDIF}
 {$ELSE}
  {$IFNDEF RESTKBMMEMTABLE}
   {$IFDEF DWMEMTABLE} //TODO
   {$ELSE}
    Data := Stream.Data;
   {$ENDIF}
  {$ELSE}
//   LoadFromDataSet(Stream, []); //TODO
  {$ENDIF}
 {$ENDIF}
 Self.RecNo := vBookmark;
 EnableControls;
end;

function TRESTDWClientSQL.MassiveCount: Integer;
Begin
 Result := 0;
 If Trim(vUpdateTableName) <> '' Then
  Result := TMassiveDatasetBuffer(vMassiveDataset).RecordCount;
End;

function TRESTDWClientSQL.MassiveToJSON: String;
Begin
 Result := '';
 If vMassiveDataset <> Nil Then
  If TMassiveDatasetBuffer(vMassiveDataset).RecordCount > 0 Then
   Result := TMassiveDatasetBuffer(vMassiveDataset).ToJSON;
End;

procedure TRESTDWClientSQL.NewDataField(Value: TFieldDefinition);
Var
 I : Integer;
begin
 SetLength(vFieldsList, Length(vFieldsList) +1);
 I := Length(vFieldsList) -1;
 vFieldsList[I] := TFieldDefinition.Create;
 vFieldsList[I].FieldName := Value.FieldName;
 vFieldsList[I].DataType  := Value.DataType;
 vFieldsList[I].Size      := Value.Size;
 vFieldsList[I].Required  := Value.Required;
end;

Function TRESTDWClientSQL.FieldListCount: Integer;
Begin
 Result := 0;
 If Self is TRESTDWClientSQL Then
  Result := Length(vFieldsList);
End;

procedure TRESTDWClientSQL.NewFieldList;
begin
 CleanFieldList;
 If Self is TRESTDWClientSQL Then
  SetLength(vFieldsList, 0);
end;

procedure TRESTDWClientSQL.Newtable;
Begin
 TRESTDWClientSQL(Self).Inactive   := True;
 Try
 {$IFNDEF FPC}
  Self.Close;
  Self.Open;
 {$ELSE}
  {$IFDEF ZEOSDRIVER} //TODO
  {$ELSE}
   {$IFDEF DWMEMTABLE} //TODO
    TDWMemtable(Self).Close;
    TDWMemtable(Self).Open;
   {$ELSE}
   If Self is TMemDataset Then
    TMemDataset(Self).CreateTable;
   {$ENDIF}
  {$ENDIF}
  Self.Open;
  TRESTDWClientSQL(Self).Active     := True;
 {$ENDIF}
 Finally
  TRESTDWClientSQL(Self).Inactive   := False;
 End;
end;

{$IFDEF FPC}
{$IFDEF LAZDRIVER}
procedure TRESTDWClientSQL.CloneDefinitions(Source  : TMemDataset;
                                            aSelf   : TMemDataset);
{$ENDIF}
{$IFDEF DWMEMTABLE}
Procedure TRESTDWClientSQL.CloneDefinitions(Source  : TDWMemtable;
                                            aSelf   : TDWMemtable); //Fields em Defini��es
{$ENDIF}
{$ELSE}
{$IFDEF CLIENTDATASET}
Procedure TRESTDWClientSQL.CloneDefinitions(Source : TClientDataset; aSelf : TClientDataset);
{$ENDIF}
{$IFDEF RESJEDI}
Procedure TRESTDWClientSQL.CloneDefinitions(Source : TJvMemoryData; aSelf : TJvMemoryData);
{$ENDIF}
{$IFDEF RESTKBMMEMTABLE}
Procedure TRESTDWClientSQL.CloneDefinitions(Source : TKbmmemtable; aSelf : TKbmmemtable);
{$ENDIF}
{$IFDEF RESTFDMEMTABLE}
Procedure TRESTDWClientSQL.CloneDefinitions(Source : TFDmemtable; aSelf : TFDmemtable);
{$ENDIF}
{$IFDEF DWMEMTABLE}
Procedure TRESTDWClientSQL.CloneDefinitions(Source  : TDWMemtable;
                                            aSelf   : TDWMemtable); //Fields em Defini��es
{$ENDIF}
{$ENDIF}
Var
 I, A : Integer;
Begin
 aSelf.Close;
 For I := 0 to Source.FieldDefs.Count -1 do
  Begin
   For A := 0 to aSelf.FieldDefs.Count -1 do
    If Uppercase(Source.FieldDefs[I].Name) = Uppercase(aSelf.FieldDefs[A].Name) Then
     Begin
      aSelf.FieldDefs.Delete(A);
      Break;
     End;
  End;
 For I := 0 to Source.FieldDefs.Count -1 do
  Begin
   If Trim(Source.FieldDefs[I].Name) <> '' Then
    Begin
     With aSelf.FieldDefs.AddFieldDef Do
      Begin
       Name     := Source.FieldDefs[I].Name;
       DataType := Source.FieldDefs[I].DataType;
       Size     := Source.FieldDefs[I].Size;
       Required := Source.FieldDefs[I].Required;
       CreateField(aSelf);
      End;
    End;
  End;
 If aSelf.FieldDefs.Count > 0 Then
  aSelf.Open;
End;

procedure TRESTDWClientSQL.PrepareDetailsNew;
Var
 I, J : Integer;
 vDetailClient : TRESTDWClientSQL;
 vOldInBlock   : Boolean;
Begin
 For I := 0 To vMasterDetailList.Count -1 Do
  Begin
   vMasterDetailList.Items[I].ParseFields(TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
   vDetailClient        := TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet);
   If vDetailClient <> Nil Then
    Begin
     for J := 0 to vDetailClient.Params.Count -1 do //Alexandre Magno - 09/10/2018 - Limpa parametros
       vDetailClient.Params[J].Clear;

     If vDetailClient.Active Then
      Begin
       vOldInBlock   := vDetailClient.GetInBlockEvents;
       Try
        vDetailClient.SetInBlockEvents(True);
        If Self.State = dsInsert Then
         vDetailClient.Newtable;
       Finally
        vDetailClient.SetInBlockEvents(vOldInBlock);
       End;
       vDetailClient.ProcAfterScroll(vDetailClient);
      End
     Else
      Begin
       If vDetailClient.Fields.Count > 0 Then
        Begin
         vOldInBlock   := vDetailClient.GetInBlockEvents;
         Try
          vDetailClient.SetInBlockEvents(True);
          vDetailClient.Active := True;
         Finally
          vDetailClient.SetInBlockEvents(vOldInBlock);
         End;
        End;
      End;
    End;
  End;
End;

procedure TRESTDWClientSQL.PrepareDetails(ActiveMode: Boolean);
Var
 I, j : Integer;
 vDetailClient : TRESTDWClientSQL;
 Function CloneDetails(Value : TRESTDWClientSQL) : Boolean;
 Var
  I : Integer;
 Begin
  Result := False;
  For I := 0 To Value.Params.Count -1 Do
   Begin
    If FindField(Value.Params[I].Name) <> Nil Then
     Begin
      If Not Result Then
       Result := Not (Value.Params[I].Value = FindField(Value.Params[I].Name).Value);
      If (Value.Params[I].Value = FindField(Value.Params[I].Name).Value) then
       Continue;

      Value.Params[I].DataType := FindField(Value.Params[I].Name).DataType;
      Value.Params[I].Size     := FindField(Value.Params[I].Name).Size;
      Value.Params[I].Value    := FindField(Value.Params[I].Name).Value;
     End;
   End;
 End;
Begin
 If vReadData Then
  Exit;
 If vMasterDetailList <> Nil Then
 For I := 0 To vMasterDetailList.Count -1 Do
  Begin
   vMasterDetailList.Items[I].ParseFields(TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
   vDetailClient        := TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet);
   If vDetailClient <> Nil Then
    Begin
     vDetailClient.vInactive := False;
     for J := 0 to vDetailClient.Params.Count -1 do //Alexandre Magno - 09/10/2018 - Limpa parametros
       vDetailClient.Params[J].Clear;

     If CloneDetails(vDetailClient) Then
      Begin
       vDetailClient.Active := False;
       vDetailClient.Active := ActiveMode;
      End;
    End;
  End;
End;

Function TRESTDWClientSQL.OpenJson(JsonValue : String = '') : Boolean;
Var
 LDataSetList  : TJSONValue;
 vMessageError : String;
Begin
 Result       := False;
 LDataSetList := Nil;
 Close;
 Try
 If Assigned(vDWResponseTranslator) Then
  Begin
   If JsonValue <> '' Then
    Begin
     LDataSetList          := TJSONValue.Create;
     LDataSetList.Encoded  := False;
     LDataSetList.Encoding := esUtf8;
     Try
      LDataSetList.WriteToDataset(JsonValue, Self, vDWResponseTranslator, rtJSONAll);
      Result := True;
     Except
     End;
    End;
   If (LDataSetList <> Nil) Then
    FreeAndNil(LDataSetList);
  End;
 Finally
  vInBlockEvents  := False;
 End;
End;

Function TRESTDWClientSQL.GetData(DataSet: TJSONValue): Boolean;
Var
 LDataSetList  : TJSONValue;
 vError        : Boolean;
 vValue,
 vMessageError : String;
Begin
 vValue       := '';
 Result       := False;
 LDataSetList := Nil;
 Self.Close;
 If Assigned(vDWResponseTranslator) Then
  Begin
   LDataSetList          := TJSONValue.Create;
   Try
    LDataSetList.Encoded  := False;
    If Assigned(vDWResponseTranslator.ClientREST) Then
     LDataSetList.Encoding := vDWResponseTranslator.ClientREST.RequestCharset;
    Try
     vValue := vDWResponseTranslator.Open(vDWResponseTranslator.RequestOpen,
                                          vDWResponseTranslator.RequestOpenUrl);
    Except
     Self.Close;
    End;
    If vValue = '[]' Then
     vValue := '';
    {$IFDEF FPC}
     vValue := StringReplace(vValue, #10, '', [rfReplaceAll]);
    {$ELSE}
     vValue := StringReplace(vValue, #$A, '', [rfReplaceAll]);
    {$ENDIF}
    vError := vValue = '';
    If (Assigned(LDataSetList)) And (Not (vError)) Then
     Begin
      Try
       LDataSetList.WriteToDataset(vValue, Self, vDWResponseTranslator, rtJSONAll);
       Result := True;
      Except
      End;
     End;
   Finally
    LDataSetList.Free;
   End;
  End
 Else If Assigned(vRESTDataBase) Then
  Begin
   Try
    If DataSet = Nil Then
     Begin
      vRESTDataBase.ExecuteCommand(vSQL, vParams, vError, vMessageError, LDataSetList, False, Nil);
      If LDataSetList <> Nil Then
       Begin
        LDataSetList.Encoded  := vRESTDataBase.EncodeStrings;
        LDataSetList.Encoding := DataBase.Encoding;
        {$IFDEF FPC}
        LDataSetList.DatabaseCharSet := DataBase.DatabaseCharSet;
        {$ENDIF}
        vValue := LDataSetList.ToJSON;
       End;
     End
    Else
     Begin
      vValue                := DataSet.Value;
      LDataSetList          := TJSONValue.Create;
      LDataSetList.Encoded  := vRESTDataBase.EncodeStrings;
      LDataSetList.Encoding := DataBase.Encoding;
      vError                := False;
     End;
    If (Assigned(LDataSetList)) And (Not (vError)) Then
     Begin
      Try
       vActualJSON := vValue;
       vActualRec  := 0;
       LDataSetList.WriteToDataset(dtFull, vValue, Self, vJsonCount, vDatapacks, vActualRec);
       If vDatapacks <> -1 Then
        Begin
         vOldRecordCount := vDatapacks;
         If vOldRecordCount > vJsonCount Then
          vOldRecordCount := vJsonCount;
        End;
       Result := True;
      Except
      End;
     End;
   Except
   End;
   If (LDataSetList <> Nil) Then
    FreeAndNil(LDataSetList);
   If vError Then
    Begin
     If csDesigning in ComponentState Then
      Raise Exception.Create(PChar(vMessageError))
     Else
      Begin
       If Assigned(vOnGetDataError) Then
        vOnGetDataError(Not(vError), vMessageError)
       Else
        Raise Exception.Create(PChar(vMessageError));
      End;
    End;
  End
 Else If csDesigning in ComponentState Then
  Raise Exception.Create(PChar('Empty Database Property'));
End;

function TRESTDWClientSQL.GetFieldListByName(aName: String): TFieldDefinition;
Var
 I : Integer;
Begin
 Result := Nil;
 For I := 0 To Length(vFieldsList) -1 Do
  Begin
   If UpperCase(vFieldsList[I].FieldName) = Uppercase(aName) Then
    Begin
     Result := vFieldsList[I];
     Break;
    End;
  End;
End;

function TRESTDWClientSQL.GetInBlockEvents: Boolean;
Begin
 Result := vInBlockEvents;
End;

function TRESTDWClientSQL.GetInDesignEvents: Boolean;
Begin
 Result := vInDesignEvents;
End;

Function TRESTDWClientSQL.GetRecordCount : Integer;
Begin
 Result := vJsonCount;
End;

Procedure TRESTDWClientSQL.GetTmpCursor;
{$IFNDEF FPC}
{$IFDEF WINFMX}
Var
 CS: IFMXCursorService;
{$ENDIF}
{$ENDIF}
Begin
{$IFNDEF FPC}
 {$IFDEF WINFMX}
  If TPlatformServices.Current.SupportsPlatformService(IFMXCursorService) Then
   CS := TPlatformServices.Current.GetPlatformService(IFMXCursorService) As IFMXCursorService;
  If Assigned(CS) then
   Begin
    If CS.GetCursor <> vActionCursor Then
     vOldCursor := CS.GetCursor;
    //CS.SetCursor(crHourGlass);
   End;
 {$ELSE}
  {$IFNDEF HAS_FMX}
  If Screen.Cursor <> vActionCursor Then
   vOldCursor := Screen.Cursor;
  {$ENDIF}
 {$ENDIF}
{$ELSE}
 If Screen.Cursor <> vActionCursor Then
  vOldCursor := Screen.Cursor;
{$ENDIF}
End;

procedure TRESTDWClientSQL.SaveToStream(Var Stream: TRESTDWClientSQLBase);
Begin
 vBookmark := Self.RecNo;
 Stream.Close;
 vInBlockEvents := True;
 Try
  {$IFDEF FPC}
   {$IFNDEF RESTKBMMEMTABLE}
    {$IFDEF DWMEMTABLE} //TODO
    {$ELSE}
    Stream.CopyFromDataset(Self, True);
    {$ENDIF}
   {$ELSE}
 //   Stream.LoadFromDataSet(Self, []); //TODO
   {$ENDIF}
  {$ELSE}
   {$IFNDEF RESTKBMMEMTABLE}
    {$IFDEF DWMEMTABLE} //TODO
    {$ELSE}
     Stream.Data := Data;
    {$ENDIF}
   {$ELSE}
 //   Stream.LoadFromDataSet(Self, []); //TODO
   {$ENDIF}
  {$ENDIF}
 Finally
  vInBlockEvents := False;
 End;
End;

procedure TRESTDWClientSQL.CreateMassiveDataset;
Begin
 If Trim(vUpdateTableName) <> '' Then
  TMassiveDatasetBuffer(vMassiveDataset).BuildDataset(Self, Trim(vUpdateTableName));
End;

procedure TRESTDWClientSQL.SetActiveDB(Value: Boolean);
Begin
 Try
  ChangeCursor;
  If (vInactive) And Not(vInDesignEvents) Then
   Begin
    vActive := (Value) And Not(vInDesignEvents);
    If vActive Then
     Begin
      {$IFDEF FPC}
       {$IFDEF DWMEMTABLE}
        TDWMemtable(Self).Open;
       {$ELSE}
        TMemDataset(Self).Open;
       {$ENDIF}
      {$ELSE}
      {$IFDEF CLIENTDATASET}
       TClientDataset(Self).Open;
      {$ENDIF}
      {$IFDEF RESJEDI}
       TJvMemoryData(Self).Open;
      {$ENDIF}
      {$IFDEF RESTKBMMEMTABLE}
       TKbmmemtable(Self).Open;
      {$ENDIF}
      {$IFDEF RESTFDMEMTABLE}
       TFDmemtable(Self).Open;
      {$ENDIF}
      {$IFDEF DWMEMTABLE}
       TDWMemtable(Self).Open;
      {$ENDIF}
      {$ENDIF}
     End
    Else
     Begin
      {$IFDEF FPC}
       {$IFDEF DWMEMTABLE}
        TDWMemtable(Self).Close;
       {$ELSE}
        TMemDataset(Self).Close;
       {$ENDIF}
      {$ELSE}
      {$IFDEF CLIENTDATASET}
       TClientDataset(Self).Close;
      {$ENDIF}
      {$IFDEF RESJEDI}
       TJvMemoryData(Self).Close;
      {$ENDIF}
      {$IFDEF RESTKBMMEMTABLE}
       Tkbmmemtable(Self).Close;
      {$ENDIF}
      {$IFDEF RESTFDMEMTABLE}
       TFDmemtable(Self).Close;
      {$ENDIF}
      {$IFDEF DWMEMTABLE}
       TDWMemtable(Self).Close;
      {$ENDIF}
      {$ENDIF}
      vinactive := False;
     End;
    Exit;
   End;
  If (vActive) And (Assigned(vDWResponseTranslator)) Then
   vActive := False;
  If Assigned(vDWResponseTranslator) Then
   Begin
    If vDWResponseTranslator.FieldDefs.Count <> FieldDefs.Count Then
     FieldDefs.Clear;
   End;
  If ((vDWResponseTranslator <> Nil) Or (vRESTDataBase <> Nil)) And (Value) Then
   Begin
    If Not Assigned(vDWResponseTranslator) Then
     Begin
      If vRESTDataBase <> Nil Then
       If Not vRESTDataBase.Active Then
        vRESTDataBase.Active := True;
      If Not vRESTDataBase.Active then
       Begin
        vActive := False;
        Exit;
       End;
     End;
    Try
     If (Not(vActive) And (Value)) Or (GetNewData) Or (vInDesignEvents) Then
      Begin
       If Not vInDesignEvents Then
        ProcBeforeOpen(Self);
       vInBlockEvents := True;
       Filter         := '';
       Filtered       := False;
       vInBlockEvents := False;
       GetNewData     := Filtered;
       vActive        := (GetData) And Not(vInDesignEvents);
       GetNewData     := Not vActive;
       If vInDesignEvents Then
        Begin
         vInactive       := False;
         vInDesignEvents := False;
         vInBlockEvents  := vInDesignEvents;
         Exit;
        End;
       If State = dsBrowse Then
        CreateMassiveDataset;
      End
     Else
      Begin
       If State = dsBrowse Then
        Begin
         CreateMassiveDataset;
         PrepareDetails(True);
        End
       Else If State = dsInactive Then
        PrepareDetails(False);
      End;
    Except
     On E : Exception do
      Begin
       vInBlockEvents := False;
       If csDesigning in ComponentState Then
        Raise Exception.Create(PChar(E.Message))
       Else
        Begin
         If Assigned(vOnGetDataError) Then
          vOnGetDataError(False, E.Message)
         Else
          Raise Exception.Create(PChar(E.Message));
        End;
      End;
    End;
   End
  Else
   Begin
    vInDesignEvents := False;
    vActive := False;
    Close;
    //Magno
    if not (csLoading in ComponentState) and not (csReading in ComponentState) then
      If Value Then
        If vRESTDataBase = Nil Then
          Raise Exception.Create(PChar('Empty Database Property'));
   End;
 Finally
  ChangeCursor(True);
 End;
End;

procedure TRESTDWClientSQL.SetCacheUpdateRecords(Value: Boolean);
Begin
 vCacheUpdateRecords := Value;
End;

Procedure TRESTDWClientSQL.SetCursor;
{$IFNDEF FPC}
{$IFDEF WINFMX}
Var
 CS: IFMXCursorService;
{$ENDIF}
{$ENDIF}
Begin
{$IFNDEF FPC}
 {$IFDEF WINFMX}
  If TPlatformServices.Current.SupportsPlatformService(IFMXCursorService) Then
   CS := TPlatformServices.Current.GetPlatformService(IFMXCursorService) As IFMXCursorService;
  If Assigned(CS) then
   Begin
    If vActionCursor <> crNone Then
     If CS.GetCursor <> vActionCursor Then
      CS.SetCursor(vActionCursor);
   End;
 {$ELSE}
  {$IFNDEF HAS_FMX}
  If vActionCursor <> crNone Then
   If Screen.Cursor <> vActionCursor Then
    Screen.Cursor := vActionCursor;
  {$ENDIF}
 {$ENDIF}
{$ELSE}
 If vActionCursor <> crNone Then
  If Screen.Cursor <> vActionCursor Then
   Screen.Cursor := vActionCursor;
{$ENDIF}
End;

constructor TRESTDWStoredProc.Create(AOwner: TComponent);
begin
 Inherited;
 vParams   := TParams.Create(Self);
 vProcName := '';
end;

destructor TRESTDWStoredProc.Destroy;
begin
 vParams.Free;
 Inherited;
end;

Function TRESTDWStoredProc.ExecProc(Var Error : String) : Boolean;
Begin
 If vRESTDataBase <> Nil Then
  Begin
   If vParams.Count > 0 Then
    vRESTDataBase.ExecuteProcedure(vProcName, vParams, Result, Error);
  End
 Else
  Raise Exception.Create(PChar('Empty Database Property'));
End;

Function TRESTDWStoredProc.ParamByName(Value: String): TParam;
Begin
 Result := Params.ParamByName(Value);
End;

procedure TRESTDWStoredProc.SetDataBase(const Value: TRESTDWDataBase);
begin
 vRESTDataBase := Value;
end;

Procedure TClientConnectionDefs.SetConnectionDefs(Value : TConnectionDefs);
Begin
 If vActive Then
  vConnectionDefs := Value;
End;

Constructor TClientConnectionDefs.Create;
Begin
 vActive := False;
End;

Destructor TClientConnectionDefs.Destroy;
Begin
 If Assigned(vConnectionDefs) Then
  FreeAndNil(vConnectionDefs);
 Inherited;
End;

Procedure TClientConnectionDefs.SetClientConnectionDefs(Value : Boolean);
Begin
 Case Value Of
  True  : Begin
           If Not Assigned(vConnectionDefs) Then
            vConnectionDefs := TConnectionDefs.Create;
          End;
  False : Begin
           If Assigned(vConnectionDefs) Then
            FreeAndNil(vConnectionDefs);
          End;
 End;
 vActive := Value;
End;

Procedure TRESTDWDataBase.SetMyIp(Value: String);
Begin
End;

function TRESTDWClientSQL.FieldDefExist(Value: String): TFieldDef;
Var
 I : Integer;
Begin
 Result := Nil;
 For I := 0 To FieldDefs.Count -1 Do
  Begin
   If UpperCase(Value) = UpperCase(FieldDefs[I].Name) Then
    Begin
     Result := FieldDefs[I];
     Break;
    End;
  End;
End;

function TRESTDWClientSQL.FieldExist(Value: String): TField;
Var
 I : Integer;
Begin
 Result := Nil;
 For I := 0 To Fields.Count -1 Do
  Begin
   If UpperCase(Value) = UpperCase(Fields[I].FieldName) Then
    Begin
     Result := Fields[I];
     Break;
    End;
  End;
End;

{ TRESTDWDriver }

procedure TRESTDWDriver.BuildDatasetLine(Var Query: TDataset; Massivedataset: TMassivedatasetBuffer);
Var
 I : Integer;
 vStringStream : TMemoryStream;
Begin
  For I := 0 To Query.Fields.Count -1 Do
   Begin
    If (MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName) <> Nil) Then
     Begin
//          vFieldType := ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).FieldType);
      If MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).value = 'null' Then
       Begin
        Query.Fields[I].Clear;
        Continue;
       End;
      If Query.Fields[I].DataType in [{$IFNDEF FPC}{$if CompilerVersion > 21} // Delphi 2010 pra baixo
                            ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                            ftString,    ftWideString]    Then
       Begin
        If (MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value <> Null) And
           (Trim(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value) <> 'null') Then
         Begin
          If Query.Fields[I].Size > 0 Then
           Query.Fields[I].Value := Copy(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value, 1, Query.Fields[I].Size)
          Else
           Query.Fields[I].Value := MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value;
         End
        Else
         Query.Fields[I].Clear;
       End
      Else
       Begin
        If Query.Fields[I].DataType in [ftInteger, ftSmallInt, ftWord, {$IFNDEF FPC}{$IF CompilerVersion > 21}ftLongWord, {$IFEND}{$ENDIF} ftLargeint] Then
         Begin
          If (Trim(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value) <> '') And
             (Trim(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value) <> 'null') Then
           Begin
            If MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value <> Null Then
             Begin
              If Query.Fields[I].DataType in [{$IFNDEF FPC}{$IF CompilerVersion > 21}ftLongWord, {$IFEND}{$ENDIF}ftLargeint] Then
               Query.Fields[I].AsLargeInt := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value)
              Else
               Query.Fields[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value);
             End;
           End
          Else
           Query.Fields[I].Clear;
         End
        Else If Query.Fields[I].DataType in [ftFloat,   ftCurrency, ftBCD, ftFMTBcd{$IFNDEF FPC}{$IF CompilerVersion > 21}, ftSingle{$IFEND}{$ENDIF}] Then
         Begin
          If (MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value <> Null) And
             (Trim(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value) <> 'null') Then
           Query.Fields[I].AsFloat  := StrToFloat(BuildFloatString(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value))
          Else
           Query.Fields[I].Clear;
         End
        Else If Query.Fields[I].DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
         Begin
          If (MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value <> Null) And
             (Trim(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value) <> 'null') Then
           Query.Fields[I].AsDateTime  := UnixToDateTime(StrToInt64(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value))
          Else
           Query.Fields[I].Clear;
         End  //Tratar Blobs de Parametros...
        Else If Query.Fields[I].DataType in [ftBytes, ftVarBytes, ftBlob,
                                             ftGraphic, ftOraBlob, ftOraClob,
                                             ftMemo {$IFNDEF FPC}
                                                     {$IF CompilerVersion > 21}
                                                      , ftWideMemo
                                                     {$IFEND}
                                                    {$ENDIF}] Then
         Begin
          vStringStream := TMemoryStream.Create;
          Try
           If (MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).value <> 'null') And
              (MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).value <> '') Then
            Begin
             MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).SaveToStream(vStringStream);
             vStringStream.Position := 0;
             TBlobfield(Query.Fields[I]).LoadFromStream(vStringStream); //, ftBlob);
            End
           Else
            Query.Fields[I].Clear;
          Finally
           FreeAndNil(vStringStream);
          End;
         End
        Else If (MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value <> Null) And
                (Trim(MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value) <> 'null') Then
         Query.Fields[I].Value := MassiveDataset.Fields.FieldByName(Query.Fields[I].FieldName).Value
        Else
         Query.Fields[I].Clear;
       End;
     End;
   End;
end;

Constructor TRESTDWDriver.Create(AOwner: TComponent);
Begin
 Inherited;
 vEncodeStrings   := True;
 {$IFDEF FPC}
 vDatabaseCharSet := csUndefined;
 {$ENDIF}
 vCommitRecords   := 100;
End;

end.
