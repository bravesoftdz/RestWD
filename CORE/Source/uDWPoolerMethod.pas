unit uDWPoolerMethod;

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
}

Interface

Uses {$IFDEF FPC}
     SysUtils,   uSystemEvents, uDWConstsData, Classes, SysTypes,   ServerUtils, {$IFDEF WINDOWS}Windows,{$ENDIF}
     uDWConsts,          uRESTDWBase,        uDWJSONTools,        uDWMassiveBuffer,  uDWJSONObject;
     {$ELSE}
     {$IF CompilerVersion < 21}
     SysUtils, Classes,
     {$ELSE}
     System.SysUtils, System.Classes,
     {$IFEND}
     uSystemEvents, uDWMassiveBuffer, SysTypes,   uDWConstsData, ServerUtils,        {$IFDEF WINDOWS} Windows, {$ENDIF}
     uDWConsts,  uRESTDWBase,        uDWJSONTools,     uDWJSONObject;
     {$ENDIF}

 Type
  TDWPoolerMethodClient  = Class(TComponent)
  Private
   vOnWork               : TOnWork;
   vOnWorkBegin          : TOnWorkBegin;
   vOnWorkEnd            : TOnWorkEnd;
   vOnStatus             : TOnStatus;
   vEncodeStrings,
   vCompression          : Boolean;
   vEncoding             : TEncodeSelect;
   {$IFDEF FPC}
   vDatabaseCharSet      : TDatabaseCharSet;
   {$ENDIF}
   vPoolerURL,
   vAccessTag,
   vWelcomeMessage,
   vHost : String;
   vPort : Integer;
   vTypeRequest: TtypeRequest;
   Procedure SetOnWork     (Value : TOnWork);
   Procedure SetOnWorkBegin(Value : TOnWorkBegin);
   Procedure SetOnWorkEnd  (Value : TOnWorkEnd);
   Procedure SetOnStatus   (Value : TOnStatus);
  Public
   Constructor Create(AOwner: TComponent);Override;
   Destructor  Destroy;Override;
   Function GetPoolerList         (Method_Prefix           : String;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   RESTClientPooler        : TRESTClientPooler = Nil)   : TStringList;Overload;
   Function GetServerEvents       (Method_Prefix           : String;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   RESTClientPooler        : TRESTClientPooler = Nil)   : TStringList;Overload;
   Function EchoPooler            (Method_Prefix,
                                   Pooler                  : String;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   RESTClientPooler        : TRESTClientPooler = Nil)   : String;
   //Roda Comando SQL
   Function InsertValue           (Pooler, Method_Prefix,
                                   SQL                     : String;
                                   Params                  : TDWParams;
                                   Var Error               : Boolean;
                                   Var MessageError        : String;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   ConnectionDefs          : TObject           = Nil;
                                   RESTClientPooler        : TRESTClientPooler = Nil)   : Integer;
   Function ExecuteCommand        (Pooler, Method_Prefix,
                                   SQL                     : String;
                                   Params                  : TDWParams;
                                   Var Error               : Boolean;
                                   Var MessageError        : String;
                                   Execute                 : Boolean;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   ConnectionDefs          : TObject           = Nil;
                                   RESTClientPooler        : TRESTClientPooler = Nil)   : TJSONValue;
   Function OpenDatasets          (LinesDataset,
                                   Pooler,
                                   Method_Prefix           : String;
                                   Var Error               : Boolean;
                                   Var MessageError        : String;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   ConnectionDefs          : TObject           = Nil;
                                   RESTClientPooler        : TRESTClientPooler = Nil)   : String;
   Function ApplyUpdates          (Massive                 : TMassiveDatasetBuffer;
                                   Pooler, Method_Prefix,
                                   SQL                     : String;
                                   Params                  : TDWParams;
                                   Var Error               : Boolean;
                                   Var MessageError        : String;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   ConnectionDefs          : TObject           = Nil;
                                   RESTClientPooler        : TRESTClientPooler = Nil)   : TJSONValue;
   Procedure ApplyUpdates_MassiveCache(MassiveCache,
                                       Pooler, Method_Prefix   : String;
                                       Var Error               : Boolean;
                                       Var MessageError        : String;
                                       TimeOut                 : Integer = 3000;
                                       UserName                : String  = '';
                                       Password                : String  = '';
                                       ConnectionDefs          : TObject           = Nil;
                                       RESTClientPooler        : TRESTClientPooler = Nil);
   Function ExecuteCommandJSON    (Pooler, Method_Prefix,
                                   SQL                     : String;
                                   Params                  : TDWParams;
                                   Var Error               : Boolean;
                                   Var MessageError        : String;
                                   Execute                 : Boolean;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   ConnectionDefs          : TObject           = Nil;
                                   RESTClientPooler        : TRESTClientPooler = Nil)   : TJSONValue;
   Function InsertValuePure       (Pooler, Method_Prefix,
                                   SQL                     : String;
                                   Var Error               : Boolean;
                                   Var MessageError        : String;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   ConnectionDefs          : TObject           = Nil;
                                   RESTClientPooler        : TRESTClientPooler = Nil)   : Integer;
   Function ExecuteCommandPureJSON(Pooler,
                                   Method_Prefix,
                                   SQL                     : String;
                                   Var Error               : Boolean;
                                   Var MessageError        : String;
                                   Execute                 : Boolean;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   ConnectionDefs          : TObject           = Nil;
                                   RESTClientPooler        : TRESTClientPooler = Nil)   : TJSONValue;
   //Lista todos os Pooler's do Servidor
   Procedure GetPoolerList        (Method_Prefix           : String;
                                   Var PoolerList          : TStringList;
                                   TimeOut                 : Integer = 3000;
                                   UserName                : String  = '';
                                   Password                : String  = '';
                                   RESTClientPooler        : TRESTClientPooler = Nil);Overload;
   //StoredProc
   Procedure  ExecuteProcedure    (Pooler,
                                   Method_Prefix,
                                   ProcName                : String;
                                   Params                  : TDWParams;
                                   Var Error               : Boolean;
                                   Var MessageError        : String;
                                   ConnectionDefs          : TObject           = Nil;
                                   RESTClientPooler        : TRESTClientPooler = Nil);
   Procedure  ExecuteProcedurePure(Pooler,
                                   Method_Prefix,
                                   ProcName                : String;
                                   Var Error               : Boolean;
                                   Var MessageError        : String;
                                   ConnectionDefs          : TObject           = Nil;
                                   RESTClientPooler        : TRESTClientPooler = Nil);
   Property Compression  : Boolean   Read vCompression Write vCompression;
   Property Encoding       : TEncodeSelect Read vEncoding       Write vEncoding;
   Property EncodeStrings  : Boolean       Read vEncodeStrings  Write vEncodeStrings;
   Property PoolerURL      : String        Read vPoolerURL      Write vPoolerURL;
   Property Host           : String        Read vHost           Write vHost;
   Property Port           : Integer       Read vPort           Write vPort;
   Property WelcomeMessage : String        Read vWelcomeMessage Write vWelcomeMessage;
   Property OnWork         : TOnWork       Read vOnWork         Write SetOnWork;
   Property OnWorkBegin    : TOnWorkBegin  Read vOnWorkBegin    Write SetOnWorkBegin;
   Property OnWorkEnd      : TOnWorkEnd    Read vOnWorkEnd      Write SetOnWorkEnd;
   Property OnStatus       : TOnStatus     Read vOnStatus       Write SetOnStatus;
   {$IFDEF FPC}
   Property DatabaseCharSet: TDatabaseCharSet Read vDatabaseCharSet Write vDatabaseCharSet;
   {$ENDIF}
   Property TypeRequest    : TTypeRequest  Read vTypeRequest    Write vTypeRequest       Default trHttp;
   Property AccessTag      : String        Read vAccessTag      Write vAccessTag;
  End;

implementation

Uses uRESTDWPoolerDB, uDWJSONInterface;
{ TDWPoolerMethodClient }

Function TDWPoolerMethodClient.ApplyUpdates(Massive                 : TMassiveDatasetBuffer;
                                            Pooler, Method_Prefix,
                                            SQL                     : String;
                                            Params                  : TDWParams;
                                            Var Error               : Boolean;
                                            Var MessageError        : String;
                                            TimeOut                 : Integer = 3000;
                                            UserName                : String  = '';
                                            Password                : String  = '';
                                            ConnectionDefs          : TObject           = Nil;
                                            RESTClientPooler        : TRESTClientPooler = Nil)   : TJSONValue;
Var
 RESTClientPoolerExec : TRESTClientPooler;
 lResponse            : String;
 JSONParam            : TJSONParam;
 DWParams             : TDWParams;
 bJsonValue           : TDWJSONObject;
Begin
 If Not Assigned(RESTClientPooler) Then
  RESTClientPoolerExec                := TRESTClientPooler.Create(Nil)
 Else
  RESTClientPoolerExec                := RESTClientPooler;
 RESTClientPoolerExec.WelcomeMessage  := vWelcomeMessage;
 RESTClientPoolerExec.Host            := Host;
 RESTClientPoolerExec.Port            := Port;
 RESTClientPoolerExec.UserName        := UserName;
 RESTClientPoolerExec.Password        := Password;
 RESTClientPoolerExec.RequestTimeOut  := TimeOut;
 RESTClientPoolerExec.UrlPath         := Method_Prefix;
 RESTClientPoolerExec.DataCompression := vCompression;
 RESTClientPoolerExec.TypeRequest     := vtyperequest;
 RESTClientPoolerExec.OnWork           := vOnWork;
 RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
 RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
 RESTClientPoolerExec.OnStatus         := vOnStatus;
 RESTClientPoolerExec.Encoding         := vEncoding;
 RESTClientPoolerExec.hEncodeStrings   := EncodeStrings;
 RESTClientPoolerExec.SetAccessTag(vAccessTag);
 {$IFDEF FPC}
 RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
 {$ENDIF}
 DWParams                        := TDWParams.Create;
 DWParams.Encoding               := RESTClientPoolerExec.Encoding;
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Massive';
 JSONParam.ObjectDirection       := odIn;
 If Massive <> Nil Then
  JSONParam.AsString             := TMassiveDatasetBuffer(Massive).ToJSON;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Pooler';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Pooler;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Method_Prefix';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Method_Prefix;
 DWParams.Add(JSONParam);
 If Assigned(ConnectionDefs) Then
  Begin
   JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName             := 'dwConnectionDefs';
   JSONParam.ObjectDirection       := odIn;
   JSONParam.AsString              := TConnectionDefs(ConnectionDefs).ToJSON;
   DWParams.Add(JSONParam);
  End;
 If Trim(SQL) <> '' Then
  Begin
   JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName             := 'SQL';
   JSONParam.ObjectDirection       := odIn;
   JSONParam.AsString              := SQL;
   DWParams.Add(JSONParam);
   If Params <> Nil Then
    Begin
     If Params.Count > 0 Then
      Begin
       JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
       JSONParam.ParamName             := 'Params';
       JSONParam.ObjectDirection       := odInOut;
       JSONParam.AsString              := Params.ToJSON;
       DWParams.Add(JSONParam);
      End;
    End;
  End;
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Error';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsBoolean             := False;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'MessageError';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsString              := MessageError;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Result';
 JSONParam.ObjectDirection       := odOUT;
 JSONParam.ObjectValue           := ovBlob;
 JSONParam.Encoded               := False;
 JSONParam.SetValue('', JSONParam.Encoded);
 DWParams.Add(JSONParam);
 Try
  Try
   lResponse := RESTClientPoolerExec.SendEvent('ApplyUpdates', DWParams);
   If (lResponse <> '') And
      (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
    Begin
     Result          := TJSONValue.Create;
     Result.Encoding := vEncoding;
     If DWParams.ItemsString['MessageError'] <> Nil Then
      MessageError  := DWParams.ItemsString['MessageError'].Value;
     If DWParams.ItemsString['Error'] <> Nil Then
      Error         := StringToBoolean(DWParams.ItemsString['Error'].Value);
     If DWParams.ItemsString['Result'] <> Nil Then
      Begin
       If DWParams.ItemsString['Result'].AsString <> '' Then
        Begin
         If Massive.ReflectChanges Then
          Begin
           bJsonValue  := TDWJSONObject.Create(DWParams.ItemsString['Result'].AsString);
           If bJsonValue.PairCount > 0 Then
            Result.SetValue(Decodestrings(TDWJSONObject(bJsonValue).Pairs[4].Value{$IFDEF FPC}, Result.DatabaseCharSet{$ENDIF}));
           FreeAndNil(bJsonValue);
          End
         Else
          Result.SetValue(DWParams.ItemsString['Result'].AsString);
        End;
      End;
    End
   Else
    Begin
     Error         := True;
     If (lResponse = '') Then
      MessageError  := Format('Unresolved Host : ''%s''', [Host])
     Else If (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      MessageError  := Format('Unauthorized Username : ''%s''', [UserName]);
     Raise Exception.Create(MessageError);
    End;
  Except
   On E : Exception Do
    Begin
     Error         := True;
     MessageError  := E.Message;
    End;
  End;
 Finally
  If Not Assigned(RESTClientPooler) Then
   FreeAndNil(RESTClientPoolerExec);
  FreeAndNil(DWParams);
 End;
End;

Procedure TDWPoolerMethodClient.SetOnStatus(Value : TOnStatus);
Begin
 {$IFDEF FPC}
  vOnStatus            := Value;
 {$ELSE}
  vOnStatus            := Value;
 {$ENDIF}
End;

Procedure TDWPoolerMethodClient.SetOnWork(Value : TOnWork);
Begin
 {$IFDEF FPC}
  vOnWork            := Value;
 {$ELSE}
  vOnWork            := Value;
 {$ENDIF}
End;

Procedure TDWPoolerMethodClient.SetOnWorkBegin(Value : TOnWorkBegin);
Begin
 {$IFDEF FPC}
  vOnWorkBegin            := Value;
 {$ELSE}
  vOnWorkBegin            := Value;
 {$ENDIF}
End;

Procedure TDWPoolerMethodClient.SetOnWorkEnd(Value : TOnWorkEnd);
Begin
 {$IFDEF FPC}
  vOnWorkEnd            := Value;
 {$ELSE}
  vOnWorkEnd            := Value;
 {$ENDIF}
End;

Procedure TDWPoolerMethodClient.ApplyUpdates_MassiveCache(MassiveCache,
                                                          Pooler, Method_Prefix   : String;
                                                          Var Error               : Boolean;
                                                          Var MessageError        : String;
                                                          TimeOut                 : Integer = 3000;
                                                          UserName                : String  = '';
                                                          Password                : String  = '';
                                                          ConnectionDefs          : TObject           = Nil;
                                                          RESTClientPooler        : TRESTClientPooler = Nil);
Var
 RESTClientPoolerExec : TRESTClientPooler;
 lResponse        : String;
 JSONParam        : TJSONParam;
 DWParams         : TDWParams;
Begin
 If Not Assigned(RESTClientPooler) Then
  RESTClientPoolerExec                := TRESTClientPooler.Create(Nil)
 Else
  RESTClientPoolerExec                := RESTClientPooler;
 RESTClientPoolerExec.WelcomeMessage  := vWelcomeMessage;
 RESTClientPoolerExec.Host            := Host;
 RESTClientPoolerExec.Port            := Port;
 RESTClientPoolerExec.UserName        := UserName;
 RESTClientPoolerExec.Password        := Password;
 RESTClientPoolerExec.RequestTimeOut  := TimeOut;
 RESTClientPoolerExec.UrlPath         := Method_Prefix;
 RESTClientPoolerExec.DataCompression := vCompression;
 RESTClientPoolerExec.TypeRequest     := vtyperequest;
 RESTClientPoolerExec.OnWork           := vOnWork;
 RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
 RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
 RESTClientPoolerExec.OnStatus         := vOnStatus;
 RESTClientPoolerExec.Encoding         := vEncoding;
 RESTClientPoolerExec.hEncodeStrings   := EncodeStrings;
 RESTClientPoolerExec.SetAccessTag(vAccessTag);
 {$IFDEF FPC}
 RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
 {$ENDIF}
 DWParams                        := TDWParams.Create;
 DWParams.Encoding               := RESTClientPoolerExec.Encoding;
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'MassiveCache';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := MassiveCache;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Pooler';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Pooler;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Method_Prefix';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Method_Prefix;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Error';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsBoolean             := False;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'MessageError';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsString              := MessageError;
 DWParams.Add(JSONParam);
 If Assigned(ConnectionDefs) Then
  Begin
   JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName             := 'dwConnectionDefs';
   JSONParam.ObjectDirection       := odIn;
   JSONParam.AsString              := TConnectionDefs(ConnectionDefs).ToJSON;
   DWParams.Add(JSONParam);
  End;
 Try
  Try
   lResponse := RESTClientPoolerExec.SendEvent('ApplyUpdates_MassiveCache', DWParams);
   If (lResponse <> '') And
      (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
    Begin
     If DWParams.ItemsString['MessageError'] <> Nil Then
      MessageError  := DWParams.ItemsString['MessageError'].Value;
     If DWParams.ItemsString['Error'] <> Nil Then
      Error         := StringToBoolean(DWParams.ItemsString['Error'].Value);
    End
   Else
    Begin
     Error         := True;
     If (lResponse = '') Then
      MessageError  := Format('Unresolved Host : ''%s''', [Host])
     Else If (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      MessageError  := Format('Unauthorized Username : ''%s''', [UserName]);
     Raise Exception.Create(MessageError);
    End;
  Except
   On E : Exception Do
    Begin
     Error         := True;
     MessageError  := E.Message;
    End;
  End;
 Finally
  If Not Assigned(RESTClientPooler) Then
   FreeAndNil(RESTClientPoolerExec);
  FreeAndNil(DWParams);
 End;
End;

Constructor TDWPoolerMethodClient.Create(AOwner: TComponent);
Begin
 Inherited;
 vCompression := True;
 vEncodeStrings := True;
 vEncoding  := esUtf8;
 {$IFNDEF FPC}
  {$if CompilerVersion < 21}
   vEncoding  := esASCII;
  {$IFEND}
 {$ENDIF}
 {$IFDEF FPC}
 vDatabaseCharSet := csUndefined;
 {$ENDIF}
 Host := '127.0.0.1';
 Port := 8082;
End;

Destructor TDWPoolerMethodClient.Destroy;
Begin
 Inherited;
End;

Function TDWPoolerMethodClient.GetPoolerList(Method_Prefix    : String;
                                             TimeOut          : Integer = 3000;
                                             UserName         : String  = '';
                                             Password         : String  = '';
                                             RESTClientPooler : TRESTClientPooler = Nil)   : TStringList;
Var
 RESTClientPoolerExec : TRESTClientPooler;
 vTempString,
 lResponse            : String;
 JSONParam            : TJSONParam;
 DWParams             : TDWParams;
Begin
 If Not Assigned(RESTClientPooler) Then
  RESTClientPoolerExec                := TRESTClientPooler.Create(Nil)
 Else
  RESTClientPoolerExec                := RESTClientPooler;
 RESTClientPoolerExec.WelcomeMessage  := vWelcomeMessage;
 RESTClientPoolerExec.Host            := Host;
 RESTClientPoolerExec.Port            := Port;
 RESTClientPoolerExec.UserName        := UserName;
 RESTClientPoolerExec.Password        := Password;
 RESTClientPoolerExec.RequestTimeOut  := TimeOut;
 RESTClientPoolerExec.UrlPath         := Method_Prefix;
 RESTClientPoolerExec.DataCompression := Compression;
 RESTClientPoolerExec.TypeRequest     := vtyperequest;
 RESTClientPoolerExec.OnWork           := vOnWork;
 RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
 RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
 RESTClientPoolerExec.OnStatus         := vOnStatus;
 RESTClientPoolerExec.Encoding     := vEncoding;
 RESTClientPoolerExec.SetAccessTag(vAccessTag);
 {$IFDEF FPC}
 RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
 {$ENDIF}
 DWParams  := TDWParams.Create;
 DWParams.Encoding               := RESTClientPoolerExec.Encoding;
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Result';
 JSONParam.ObjectDirection       := odOUT;
 JSONParam.ObjectValue           := ovString;
 JSONParam.Encoded               := True;
 JSONParam.SetValue('', JSONParam.Encoded);
 DWParams.Add(JSONParam);
 Try
  Try
   lResponse := RESTClientPoolerExec.SendEvent('GetPoolerList', DWParams);
   If (lResponse <> '') And
      (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
    Begin
     Result      := TStringList.Create;
     vTempString := DWParams.ItemsString['Result'].AsString;
     While Not (vTempString = '') Do
      Begin
       if Pos('|', vTempString) > 0 then
        Begin
         Result.Add(Copy(vTempString, 1, Pos('|', vTempString) -1));
         Delete(vTempString, 1, Pos('|', vTempString));
        End
       Else
        Begin
         Result.Add(Copy(vTempString, 1, Length(vTempString)));
         Delete(vTempString, 1, Length(vTempString));
        End;
      End;
    End
   Else
    Begin
     If (lResponse = '') Then
      lResponse  := Format('Unresolved Host : ''%s''', [Host])
     Else If (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      lResponse  := Format('Unauthorized Username : ''%s''', [UserName]);
     Raise Exception.Create(lResponse);
     lResponse := '';
    End;
  Except
   On E : Exception Do
    Begin
     Raise Exception.Create(E.Message);
    End;
  End;
 Finally
  If Not Assigned(RESTClientPooler) Then
   FreeAndNil(RESTClientPoolerExec);
  FreeAndNil(DWParams);
 End;
End;

Function TDWPoolerMethodClient.EchoPooler(Method_Prefix,
                                          Pooler                  : String;
                                          TimeOut                 : Integer = 3000;
                                          UserName                : String  = '';
                                          Password                : String  = '';
                                          RESTClientPooler        : TRESTClientPooler = Nil) : String;
Var
 RESTClientPoolerExec : TRESTClientPooler;
 lResponse            : String;
 JSONParam            : TJSONParam;
 DWParams             : TDWParams;
Begin
 If Not Assigned(RESTClientPooler) Then
  RESTClientPoolerExec                 := TRESTClientPooler.Create(Nil)
 Else
  RESTClientPoolerExec                 := RESTClientPooler;
 RESTClientPoolerExec.WelcomeMessage   := vWelcomeMessage;
 RESTClientPoolerExec.Host             := Host;
 RESTClientPoolerExec.Port             := Port;
 RESTClientPoolerExec.UserName         := UserName;
 RESTClientPoolerExec.Password         := Password;
 RESTClientPoolerExec.RequestTimeOut   := TimeOut;
 RESTClientPoolerExec.UrlPath          := Method_Prefix;
 RESTClientPoolerExec.DataCompression  := vCompression;
 RESTClientPoolerExec.TypeRequest      := vtyperequest;
 RESTClientPoolerExec.OnWork           := vOnWork;
 RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
 RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
 RESTClientPoolerExec.OnStatus         := vOnStatus;
 RESTClientPoolerExec.Encoding         := vEncoding;
 RESTClientPoolerExec.hEncodeStrings   := EncodeStrings;
 RESTClientPoolerExec.SetAccessTag(vAccessTag);
 {$IFDEF FPC}
 RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
 {$ENDIF}
 DWParams                        := TDWParams.Create;
 DWParams.Encoding               := RESTClientPoolerExec.Encoding;
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Pooler';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Pooler;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Result';
 JSONParam.ObjectDirection       := odOUT;
 JSONParam.ObjectValue           := ovString;
 JSONParam.Encoded               := True;
 JSONParam.SetValue('', JSONParam.Encoded);
 DWParams.Add(JSONParam);
 Try
  Try
   lResponse := RESTClientPoolerExec.SendEvent('EchoPooler', DWParams);
   If (lResponse <> '') And
      (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
    Result   := DWParams.ItemsString['Result'].AsString
   Else
    Begin
     If (lResponse = '') Then
      lResponse  := Format('Unresolved Host : ''%s''', [Host])
     Else If (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      lResponse  := Format('Unauthorized Username : ''%s''', [UserName]);
     Raise Exception.Create(lResponse);
     lResponse   := '';
    End;
  Except
   On E : Exception Do
    Begin
     Raise Exception.Create(E.Message);
    End;
  End;
 Finally
  If Not Assigned(RESTClientPooler) Then
   If Assigned(RESTClientPoolerExec) Then
    FreeAndNil(RESTClientPoolerExec);
  FreeAndNil(DWParams);
 End;
End;

Function TDWPoolerMethodClient.ExecuteCommand(Pooler, Method_Prefix,
                                              SQL                     : String;
                                              Params                  : TDWParams;
                                              Var Error               : Boolean;
                                              Var MessageError        : String;
                                              Execute                 : Boolean;
                                              TimeOut                 : Integer = 3000;
                                              UserName                : String  = '';
                                              Password                : String  = '';
                                              ConnectionDefs          : TObject           = Nil;
                                              RESTClientPooler        : TRESTClientPooler = Nil)   : TJSONValue;
Var
 RESTClientPoolerExec : TRESTClientPooler;
 lResponse            : String;
 JSONParam            : TJSONParam;
 DWParams             : TDWParams;
Begin
 If Not Assigned(RESTClientPooler) Then
  RESTClientPoolerExec                := TRESTClientPooler.Create(Nil)
 Else
  RESTClientPoolerExec                := RESTClientPooler;
 RESTClientPoolerExec.WelcomeMessage  := vWelcomeMessage;
 RESTClientPoolerExec.Host            := Host;
 RESTClientPoolerExec.Port            := Port;
 RESTClientPoolerExec.UserName        := UserName;
 RESTClientPoolerExec.Password        := Password;
 RESTClientPoolerExec.RequestTimeOut  := TimeOut;
 RESTClientPoolerExec.UrlPath         := Method_Prefix;
 RESTClientPoolerExec.DataCompression := vCompression;
 RESTClientPoolerExec.TypeRequest     := vtyperequest;
 RESTClientPoolerExec.OnWork           := vOnWork;
 RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
 RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
 RESTClientPoolerExec.OnStatus         := vOnStatus;
 RESTClientPoolerExec.Encoding         := vEncoding;
 RESTClientPoolerExec.hEncodeStrings   := EncodeStrings;
 RESTClientPoolerExec.SetAccessTag(vAccessTag);
 {$IFDEF FPC}
 RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
 {$ENDIF}
 DWParams                        := TDWParams.Create;
 DWParams.Encoding               := RESTClientPoolerExec.Encoding;
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Pooler';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Pooler;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Method_Prefix';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Method_Prefix;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'SQL';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := SQL;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Params';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Params.ToJSON;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Error';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsBoolean             := False;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'MessageError';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsString              := MessageError;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Execute';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsBoolean             := Execute;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Result';
 JSONParam.ObjectDirection       := odOUT;
 JSONParam.ObjectValue           := ovBlob;
 JSONParam.Encoded               := False;
 JSONParam.SetValue('', JSONParam.Encoded);
 DWParams.Add(JSONParam);
 If Assigned(ConnectionDefs) Then
  Begin
   JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName             := 'dwConnectionDefs';
   JSONParam.ObjectDirection       := odIn;
   JSONParam.AsString              := TConnectionDefs(ConnectionDefs).ToJSON;
   DWParams.Add(JSONParam);
  End;
 Try
  Try
   lResponse := RESTClientPoolerExec.SendEvent('ExecuteCommandJSON', DWParams);
   If (lResponse <> '') And
      (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
    Begin
     Result         := TJSONValue.Create;
     Result.Encoded := False;
     If DWParams.ItemsString['Error'] <> Nil Then
      Error         := StringToBoolean(DWParams.ItemsString['Error'].Value);
     If DWParams.ItemsString['MessageError'] <> Nil Then
      MessageError  := DWParams.ItemsString['MessageError'].Value;
     If DWParams.ItemsString['Result'] <> Nil Then
      Result.LoadFromJSON(DWParams.ItemsString['Result'].AsString);
    End
   Else
    Begin
     Error         := True;
     If (lResponse = '') Then
      MessageError  := Format('Unresolved Host : ''%s''', [Host])
     Else If (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      MessageError  := Format('Unauthorized Username : ''%s''', [UserName]);
     Raise Exception.Create(MessageError);
    End;
  Except
   On E : Exception Do
    Begin
     Error         := True;
     MessageError  := E.Message;
    End;
  End;
 Finally
  If Not Assigned(RESTClientPooler) Then
   FreeAndNil(RESTClientPoolerExec);
  FreeAndNil(DWParams);
 End;
End;

Function TDWPoolerMethodClient.ExecuteCommandJSON(Pooler, Method_Prefix,
                                                  SQL                     : String;
                                                  Params                  : TDWParams;
                                                  Var Error               : Boolean;
                                                  Var MessageError        : String;
                                                  Execute                 : Boolean;
                                                  TimeOut                 : Integer = 3000;
                                                  UserName                : String  = '';
                                                  Password                : String  = '';
                                                  ConnectionDefs          : TObject           = Nil;
                                                  RESTClientPooler        : TRESTClientPooler = Nil)   : TJSONValue;
Var
 RESTClientPoolerExec : TRESTClientPooler;
 lResponse        : String;
 JSONParam        : TJSONParam;
 DWParams         : TDWParams;
Begin
 If Not Assigned(RESTClientPooler) Then
  RESTClientPoolerExec                := TRESTClientPooler.Create(Nil)
 Else
  RESTClientPoolerExec                := RESTClientPooler;
 RESTClientPoolerExec.WelcomeMessage  := vWelcomeMessage;
 RESTClientPoolerExec.Host            := Host;
 RESTClientPoolerExec.Port            := Port;
 RESTClientPoolerExec.UserName        := UserName;
 RESTClientPoolerExec.Password        := Password;
 RESTClientPoolerExec.RequestTimeOut  := TimeOut;
 RESTClientPoolerExec.UrlPath         := Method_Prefix;
 RESTClientPoolerExec.DataCompression := vCompression;
 RESTClientPoolerExec.hEncodeStrings  := EncodeStrings;
 RESTClientPoolerExec.TypeRequest     := vtyperequest;
 RESTClientPoolerExec.OnWork           := vOnWork;
 RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
 RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
 RESTClientPoolerExec.OnStatus         := vOnStatus;
 RESTClientPoolerExec.Encoding         := vEncoding;
 RESTClientPoolerExec.hEncodeStrings   := EncodeStrings;
 RESTClientPoolerExec.SetAccessTag(vAccessTag);
 {$IFDEF FPC}
 RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
 {$ENDIF}
 DWParams                        := TDWParams.Create;
 DWParams.Encoding               := RESTClientPoolerExec.Encoding;
 JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Pooler';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Pooler;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Method_Prefix';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Method_Prefix;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'SQL';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := SQL;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Params';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsString              := Params.ToJSON;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Error';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsBoolean             := False;
 DWParams.Add(JSONParam);
 JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'MessageError';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsString              := MessageError;
 DWParams.Add(JSONParam);
 JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Execute';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsBoolean             := Execute;
 DWParams.Add(JSONParam);
 JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Result';
 JSONParam.ObjectDirection       := odOUT;
 JSONParam.ObjectValue           := ovBlob;
 JSONParam.Encoded               := False;
 JSONParam.SetValue('', JSONParam.Encoded);
 DWParams.Add(JSONParam);
 If Assigned(ConnectionDefs) Then
  Begin
   JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName             := 'dwConnectionDefs';
   JSONParam.ObjectDirection       := odIn;
   JSONParam.AsString              := TConnectionDefs(ConnectionDefs).ToJSON;
   DWParams.Add(JSONParam);
  End;
 Try
  Try
   lResponse := RESTClientPoolerExec.SendEvent('ExecuteCommandJSON', DWParams);
   If (lResponse <> '') And
      (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
    Begin
     Result         := TJSONValue.Create;
     Result.Encoded := False;
     Result.Encoding := RESTClientPoolerExec.Encoding;
     If DWParams.ItemsString['MessageError'] <> Nil Then
      MessageError  := DWParams.ItemsString['MessageError'].Value;
     If DWParams.ItemsString['Error'] <> Nil Then
      Error         := StringToBoolean(DWParams.ItemsString['Error'].Value);
     If DWParams.ItemsString['Result'] <> Nil Then
      Begin
       If DWParams.ItemsString['Result'].AsString <> '' Then
        Result.LoadFromJSON(DWParams.ItemsString['Result'].AsString);
      End;
    End
   Else
    Begin
     Error         := True;
     If (lResponse = '') Then
      MessageError  := Format('Unresolved Host : ''%s''', [Host])
     Else If (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      MessageError  := Format('Unauthorized Username : ''%s''', [UserName]);
     Raise Exception.Create(MessageError);
    End;
  Except
   On E : Exception Do
    Begin
     Error         := True;
     MessageError  := E.Message;
    End;
  End;
 Finally
  If Not Assigned(RESTClientPooler) Then
   FreeAndNil(RESTClientPoolerExec);
  FreeAndNil(DWParams);
 End;
End;

Function TDWPoolerMethodClient.ExecuteCommandPureJSON(Pooler,
                                                      Method_Prefix,
                                                      SQL                 : String;
                                                      Var Error           : Boolean;
                                                      Var MessageError    : String;
                                                      Execute             : Boolean;
                                                      TimeOut             : Integer = 3000;
                                                      UserName            : String  = '';
                                                      Password            : String  = '';
                                                      ConnectionDefs      : TObject           = Nil;
                                                      RESTClientPooler    : TRESTClientPooler = Nil)   : TJSONValue;
Var
 RESTClientPoolerExec : TRESTClientPooler;
 lResponse        : String;
 JSONParam        : TJSONParam;
 DWParams         : TDWParams;
Begin
 If Not Assigned(RESTClientPooler) Then
  RESTClientPoolerExec                := TRESTClientPooler.Create(Nil)
 Else
  RESTClientPoolerExec                := RESTClientPooler;
 RESTClientPoolerExec.WelcomeMessage  := vWelcomeMessage;
 RESTClientPoolerExec.Host            := Host;
 RESTClientPoolerExec.Port            := Port;
 RESTClientPoolerExec.UserName        := UserName;
 RESTClientPoolerExec.Password        := Password;
 RESTClientPoolerExec.RequestTimeOut  := TimeOut;
 RESTClientPoolerExec.UrlPath         := Method_Prefix;
 RESTClientPoolerExec.DataCompression := vCompression;
 RESTClientPoolerExec.TypeRequest     := vtyperequest;
 RESTClientPoolerExec.OnWork           := vOnWork;
 RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
 RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
 RESTClientPoolerExec.OnStatus         := vOnStatus;
 RESTClientPoolerExec.Encoding         := vEncoding;
 RESTClientPoolerExec.hEncodeStrings   := EncodeStrings;
 RESTClientPoolerExec.SetAccessTag(vAccessTag);
 {$IFDEF FPC}
 RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
 {$ENDIF}
 DWParams                        := TDWParams.Create;
 DWParams.Encoding               := RESTClientPoolerExec.Encoding;
 JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Pooler';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Pooler;
 DWParams.Add(JSONParam);
 JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Method_Prefix';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Method_Prefix;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'SQL';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := SQL;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Error';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsBoolean             := False;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'MessageError';
 JSONParam.ObjectDirection       := odOUT;
 JSONParam.AsString              := MessageError;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Execute';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsBoolean             := Execute;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Result';
 JSONParam.ObjectDirection       := odOUT;
 JSONParam.ObjectValue           := ovBlob;
 JSONParam.Encoded               := False;
 JSONParam.SetValue('', JSONParam.Encoded);
 DWParams.Add(JSONParam);
 If Assigned(ConnectionDefs) Then
  Begin
   JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName             := 'dwConnectionDefs';
   JSONParam.ObjectDirection       := odIn;
   JSONParam.AsString              := TConnectionDefs(ConnectionDefs).ToJSON;
   DWParams.Add(JSONParam);
  End;
 Try
  Try
   lResponse := RESTClientPoolerExec.SendEvent('ExecuteCommandPureJSON', DWParams);
   If (lResponse <> '') And
      (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
    Begin
     Result          := TJSONValue.Create;
     Result.Encoded  := False;
     Result.Encoding := RESTClientPoolerExec.Encoding;
     If DWParams.ItemsString['MessageError'] <> Nil Then
      MessageError  := DWParams.ItemsString['MessageError'].Value;
     If DWParams.ItemsString['Error'] <> Nil Then
      Error         := StringToBoolean(DWParams.ItemsString['Error'].Value);
     If DWParams.ItemsString['Result'] <> Nil Then
      Begin
       If Not (DWParams.ItemsString['Result'].IsEmpty) Then
        Result.LoadFromJSON(DWParams.ItemsString['Result'].AsString);
      End;
    End
   Else
    Begin
     Error         := True;
     If (lResponse = '') Then
      MessageError  := Format('Unresolved Host : ''%s''', [Host])
     Else If (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      MessageError  := Format('Unauthorized Username : ''%s''', [UserName]);
     Raise Exception.Create(MessageError);
    End;
  Except
   On E : Exception Do
    Begin
     Error         := True;
     MessageError  := E.Message;
    End;
  End;
 Finally
  If Not Assigned(RESTClientPooler) Then
   FreeAndNil(RESTClientPoolerExec);
  FreeAndNil(DWParams);
 End;
End;

Procedure TDWPoolerMethodClient.ExecuteProcedure(Pooler,
                                                 Method_Prefix,
                                                 ProcName            : String;
                                                 Params              : TDWParams;
                                                 Var Error           : Boolean;
                                                 Var MessageError    : String;
                                                 ConnectionDefs      : TObject           = Nil;
                                                 RESTClientPooler    : TRESTClientPooler = Nil);
Var
 JSONParam : TJSONParam;
Begin
 If Assigned(ConnectionDefs) Then
  Begin
   JSONParam                       := TJSONParam.Create(RESTClientPooler.Encoding);
   JSONParam.ParamName             := 'dwConnectionDefs';
   JSONParam.ObjectDirection       := odIn;
   JSONParam.AsString              := TConnectionDefs(ConnectionDefs).ToJSON;
   Params.Add(JSONParam);
  End;
End;

Procedure TDWPoolerMethodClient.ExecuteProcedurePure(Pooler,
                                                     Method_Prefix,
                                                     ProcName            : String;
                                                     Var Error           : Boolean;
                                                     Var MessageError    : String;
                                                     ConnectionDefs          : TObject           = Nil;
                                                     RESTClientPooler    : TRESTClientPooler = Nil);
Var
 JSONParam : TJSONParam;
 Params    : TDWParams;
Begin
 If Assigned(ConnectionDefs) Then
  Begin
   JSONParam                       := TJSONParam.Create(RESTClientPooler.Encoding);
   JSONParam.ParamName             := 'dwConnectionDefs';
   JSONParam.ObjectDirection       := odIn;
   JSONParam.AsString              := TConnectionDefs(ConnectionDefs).ToJSON;
   Params.Add(JSONParam);
  End;
End;

Procedure TDWPoolerMethodClient.GetPoolerList(Method_Prefix    : String;
                                              Var PoolerList   : TStringList;
                                              TimeOut          : Integer = 3000;
                                              UserName         : String  = '';
                                              Password         : String  = '';
                                              RESTClientPooler : TRESTClientPooler = Nil);
Begin

End;

Function TDWPoolerMethodClient.GetServerEvents(Method_Prefix    : String;
                                               TimeOut          : Integer;
                                               UserName,
                                               Password         : String;
                                               RESTClientPooler : TRESTClientPooler) : TStringList;
Var
 RESTClientPoolerExec : TRESTClientPooler;
 vTempString,
 lResponse            : String;
 JSONParam            : TJSONParam;
 DWParams             : TDWParams;
Begin
 If Not Assigned(RESTClientPooler) Then
  RESTClientPoolerExec                := TRESTClientPooler.Create(Nil)
 Else
  RESTClientPoolerExec                := RESTClientPooler;
 RESTClientPoolerExec.WelcomeMessage  := vWelcomeMessage;
 RESTClientPoolerExec.Host            := Host;
 RESTClientPoolerExec.Port            := Port;
 RESTClientPoolerExec.UserName        := UserName;
 RESTClientPoolerExec.Password        := Password;
 RESTClientPoolerExec.RequestTimeOut  := TimeOut;
 RESTClientPoolerExec.UrlPath         := Method_Prefix;
 RESTClientPoolerExec.DataCompression := Compression;
 RESTClientPoolerExec.TypeRequest     := vtyperequest;
 RESTClientPoolerExec.OnWork           := vOnWork;
 RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
 RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
 RESTClientPoolerExec.OnStatus         := vOnStatus;
 RESTClientPoolerExec.Encoding     := vEncoding;
 RESTClientPoolerExec.SetAccessTag(vAccessTag);
 {$IFDEF FPC}
 RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
 {$ENDIF}
 DWParams  := TDWParams.Create;
 DWParams.Encoding               := RESTClientPoolerExec.Encoding;
 JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Result';
 JSONParam.ObjectDirection       := odOUT;
 JSONParam.ObjectValue           := ovString;
 JSONParam.Encoded               := True;
 JSONParam.SetValue('', JSONParam.Encoded);
 DWParams.Add(JSONParam);
 Try
  Try
   lResponse := RESTClientPoolerExec.SendEvent('GetServerEventsList', DWParams);
   If (lResponse <> '') And
      (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
    Begin
     Result      := TStringList.Create;
     vTempString := DWParams.ItemsString['Result'].AsString;
     While Not (vTempString = '') Do
      Begin
       if Pos('|', vTempString) > 0 then
        Begin
         Result.Add(Copy(vTempString, 1, Pos('|', vTempString) -1));
         Delete(vTempString, 1, Pos('|', vTempString));
        End
       Else
        Begin
         Result.Add(Copy(vTempString, 1, Length(vTempString)));
         Delete(vTempString, 1, Length(vTempString));
        End;
      End;
    End
   Else
    Begin
     If (lResponse = '') Then
      lResponse  := Format('Unresolved Host : ''%s''', [Host])
     Else If (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      lResponse  := Format('Unauthorized Username : ''%s''', [UserName]);
     Raise Exception.Create(lResponse);
     lResponse := '';
    End;
  Except
   On E : Exception Do
    Begin
     Raise Exception.Create(E.Message);
    End;
  End;
 Finally
  If Not Assigned(RESTClientPooler) Then
   FreeAndNil(RESTClientPoolerExec);
  FreeAndNil(DWParams);
 End;
End;

Function TDWPoolerMethodClient.InsertValue(Pooler, Method_Prefix,
                                           SQL                     : String;
                                           Params                  : TDWParams;
                                           Var Error               : Boolean;
                                           Var MessageError        : String;
                                           TimeOut                 : Integer = 3000;
                                           UserName                : String  = '';
                                           Password                : String  = '';
                                           ConnectionDefs          : TObject           = Nil;
                                           RESTClientPooler        : TRESTClientPooler = Nil): Integer;
Var
 RESTClientPoolerExec : TRESTClientPooler;
 lResponse            : String;
 JSONParam            : TJSONParam;
 DWParams             : TDWParams;
Begin
 Result := -1;
 If Not Assigned(RESTClientPooler) Then
  RESTClientPoolerExec                := TRESTClientPooler.Create(Nil)
 Else
  RESTClientPoolerExec                := RESTClientPooler;
 RESTClientPoolerExec.WelcomeMessage  := vWelcomeMessage;
 RESTClientPoolerExec.Host            := Host;
 RESTClientPoolerExec.Port            := Port;
 RESTClientPoolerExec.UserName        := UserName;
 RESTClientPoolerExec.Password        := Password;
 RESTClientPoolerExec.RequestTimeOut  := TimeOut;
 RESTClientPoolerExec.UrlPath         := Method_Prefix;
 RESTClientPoolerExec.DataCompression := vCompression;
 RESTClientPoolerExec.TypeRequest     := vtyperequest;
 RESTClientPoolerExec.OnWork           := vOnWork;
 RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
 RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
 RESTClientPoolerExec.OnStatus         := vOnStatus;
 RESTClientPoolerExec.Encoding         := vEncoding;
 RESTClientPoolerExec.SetAccessTag(vAccessTag);
 {$IFDEF FPC}
 RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
 {$ENDIF}
 DWParams                        := TDWParams.Create;
 DWParams.Encoding               := RESTClientPoolerExec.Encoding;
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Pooler';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Pooler;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Method_Prefix';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Method_Prefix;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'SQL';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := SQL;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Params';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Params.ToJSON;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Error';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsBoolean             := False;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'MessageError';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsString              := MessageError;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Result';
 JSONParam.ObjectDirection       := odOUT;
 JSONParam.ObjectValue           := ovString;
 JSONParam.Encoded               := True;
 JSONParam.SetValue('', JSONParam.Encoded);
 DWParams.Add(JSONParam);
 If Assigned(ConnectionDefs) Then
  Begin
   JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName             := 'dwConnectionDefs';
   JSONParam.ObjectDirection       := odIn;
   JSONParam.AsString              := TConnectionDefs(ConnectionDefs).ToJSON;
   DWParams.Add(JSONParam);
  End;
 Try
  Try
   lResponse := RESTClientPoolerExec.SendEvent('InsertMySQLReturnID_PARAMS', DWParams);
   If (lResponse <> '') And
      (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
    Begin
     Result         := -1;
     If DWParams.ItemsString['Error'] <> Nil Then
      Error         := StringToBoolean(DWParams.ItemsString['Error'].Value);
     If DWParams.ItemsString['MessageError'] <> Nil Then
      MessageError  := DWParams.ItemsString['MessageError'].Value;
     If DWParams.ItemsString['Result'] <> Nil Then
      Result := StrToInt(DWParams.ItemsString['Result'].AsString);
    End
   Else
    Begin
     Error         := True;
     If (lResponse = '') Then
      MessageError  := Format('Unresolved Host : ''%s''', [Host])
     Else If (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      MessageError  := Format('Unauthorized Username : ''%s''', [UserName]);
     Raise Exception.Create(MessageError);
    End;
  Except
   On E : Exception Do
    Begin
     Error         := True;
     MessageError  := E.Message;
    End;
  End;
 Finally
  If Not Assigned(RESTClientPooler) Then
   FreeAndNil(RESTClientPoolerExec);
  FreeAndNil(DWParams);
 End;
End;

Function TDWPoolerMethodClient.InsertValuePure(Pooler, Method_Prefix,
                                               SQL                     : String;
                                               Var Error               : Boolean;
                                               Var MessageError        : String;
                                               TimeOut                 : Integer = 3000;
                                               UserName                : String  = '';
                                               Password                : String  = '';
                                               ConnectionDefs          : TObject           = Nil;
                                               RESTClientPooler        : TRESTClientPooler = Nil): Integer;
Var
 RESTClientPoolerExec : TRESTClientPooler;
 lResponse            : String;
 JSONParam            : TJSONParam;
 DWParams             : TDWParams;
Begin
 Result := -1;
 If Not Assigned(RESTClientPooler) Then
  RESTClientPoolerExec                := TRESTClientPooler.Create(Nil)
 Else
  RESTClientPoolerExec                := RESTClientPooler;
 RESTClientPoolerExec.WelcomeMessage  := vWelcomeMessage;
 RESTClientPoolerExec.Host            := Host;
 RESTClientPoolerExec.Port            := Port;
 RESTClientPoolerExec.UserName        := UserName;
 RESTClientPoolerExec.Password        := Password;
 RESTClientPoolerExec.RequestTimeOut  := TimeOut;
 RESTClientPoolerExec.UrlPath         := Method_Prefix;
 RESTClientPoolerExec.DataCompression := vCompression;
 RESTClientPoolerExec.TypeRequest     := vtyperequest;
 RESTClientPoolerExec.OnWork           := vOnWork;
 RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
 RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
 RESTClientPoolerExec.OnStatus         := vOnStatus;
 RESTClientPoolerExec.Encoding         := vEncoding;
 RESTClientPoolerExec.hEncodeStrings   := EncodeStrings;
 RESTClientPoolerExec.SetAccessTag(vAccessTag);
 {$IFDEF FPC}
 RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
 {$ENDIF}
 DWParams                        := TDWParams.Create;
 DWParams.Encoding               := RESTClientPoolerExec.Encoding;
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Pooler';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Pooler;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Method_Prefix';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := Method_Prefix;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'SQL';
 JSONParam.ObjectDirection       := odIn;
 JSONParam.AsString              := SQL;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Error';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsBoolean             := False;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'MessageError';
 JSONParam.ObjectDirection       := odInOut;
 JSONParam.AsString              := MessageError;
 DWParams.Add(JSONParam);
 JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
 JSONParam.ParamName             := 'Result';
 JSONParam.ObjectDirection       := odOUT;
 JSONParam.ObjectValue           := ovString;
 JSONParam.Encoded               := True;
 JSONParam.SetValue('', JSONParam.Encoded);
 DWParams.Add(JSONParam);
 If Assigned(ConnectionDefs) Then
  Begin
   JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName             := 'dwConnectionDefs';
   JSONParam.ObjectDirection       := odIn;
   JSONParam.AsString              := TConnectionDefs(ConnectionDefs).ToJSON;
   DWParams.Add(JSONParam);
  End;
 Try
  Try
   lResponse := RESTClientPoolerExec.SendEvent('InsertMySQLReturnID', DWParams);
   If (lResponse <> '') And
      (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
    Begin
     If DWParams.ItemsString['Error'] <> Nil Then
      Error         := StringToBoolean(DWParams.ItemsString['Error'].Value);
     If DWParams.ItemsString['MessageError'] <> Nil Then
      MessageError  := DWParams.ItemsString['MessageError'].Value;
     If DWParams.ItemsString['Result'] <> Nil Then
      Result := StrToInt(DWParams.ItemsString['Result'].AsString);
    End
   Else
    Begin
     Error         := True;
     If (lResponse = '') Then
      MessageError  := Format('Unresolved Host : ''%s''', [Host])
     Else If (Uppercase(lResponse) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      MessageError  := Format('Unauthorized Username : ''%s''', [UserName]);
     Raise Exception.Create(MessageError);
    End;
  Except
   On E : Exception Do
    Begin
     Error         := True;
     MessageError  := E.Message;
    End;
  End;
 Finally
  If Not Assigned(RESTClientPooler) Then
   FreeAndNil(RESTClientPoolerExec);
  FreeAndNil(DWParams);
 End;
End;

Function TDWPoolerMethodClient.OpenDatasets(LinesDataset,
                                            Pooler,
                                            Method_Prefix           : String;
                                            Var Error               : Boolean;
                                            Var MessageError        : String;
                                            TimeOut                 : Integer = 3000;
                                            UserName                : String  = '';
                                            Password                : String  = '';
                                            ConnectionDefs          : TObject           = Nil;
                                            RESTClientPooler        : TRESTClientPooler = Nil) : String;
Var
 RESTClientPoolerExec : TRESTClientPooler;
 JSONParam        : TJSONParam;
 DWParams         : TDWParams;
Begin
 Result := '';
 If LinesDataset <> '' Then
  Begin
   If Not Assigned(RESTClientPooler) Then
    RESTClientPoolerExec                := TRESTClientPooler.Create(Nil)
   Else
    RESTClientPoolerExec                := RESTClientPooler;
   RESTClientPoolerExec.WelcomeMessage  := vWelcomeMessage;
   RESTClientPoolerExec.Host            := Host;
   RESTClientPoolerExec.Port            := Port;
   RESTClientPoolerExec.UserName        := UserName;
   RESTClientPoolerExec.Password        := Password;
   RESTClientPoolerExec.RequestTimeOut  := TimeOut;
   RESTClientPoolerExec.UrlPath         := Method_Prefix;
   RESTClientPoolerExec.DataCompression := vCompression;
   RESTClientPoolerExec.TypeRequest     := vtyperequest;
   RESTClientPoolerExec.TypeRequest     := vtyperequest;
   RESTClientPoolerExec.OnWork           := vOnWork;
   RESTClientPoolerExec.OnWorkBegin      := vOnWorkBegin;
   RESTClientPoolerExec.OnWorkEnd        := vOnWorkEnd;
   RESTClientPoolerExec.OnStatus         := vOnStatus;
   RESTClientPoolerExec.Encoding         := vEncoding;
   RESTClientPoolerExec.hEncodeStrings   := EncodeStrings;
   RESTClientPoolerExec.SetAccessTag(vAccessTag);
   {$IFDEF FPC}
   RESTClientPoolerExec.DatabaseCharSet  := vDatabaseCharSet;
   {$ENDIF}
   DWParams                               := TDWParams.Create;
   DWParams.Encoding               := RESTClientPoolerExec.Encoding;
   JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName                    := 'LinesDataset';
   JSONParam.ObjectDirection              := odIn;
   JSONParam.AsString                     := LinesDataset;
   DWParams.Add(JSONParam);
   JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName                    := 'Pooler';
   JSONParam.ObjectDirection              := odIn;
   JSONParam.AsString                     := Pooler;
   DWParams.Add(JSONParam);
   JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName                    := 'Method_Prefix';
   JSONParam.ObjectDirection              := odIn;
   JSONParam.AsString                     := Method_Prefix;
   DWParams.Add(JSONParam);
   JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName                   := 'Error';
   JSONParam.ObjectDirection             := odInOut;
   JSONParam.AsBoolean                   := False;
   DWParams.Add(JSONParam);
   JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName                   := 'MessageError';
   JSONParam.ObjectDirection             := odInOut;
   JSONParam.AsString                    := MessageError;
   DWParams.Add(JSONParam);
   JSONParam                     := TJSONParam.Create(RESTClientPoolerExec.Encoding);
   JSONParam.ParamName                   := 'Result';
   JSONParam.ObjectDirection             := odOUT;
   JSONParam.ObjectValue                 := ovBlob;
   JSONParam.Encoded                     := True;
   JSONParam.SetValue('', JSONParam.Encoded);
   DWParams.Add(JSONParam);
   If Assigned(ConnectionDefs) Then
    Begin
     JSONParam                       := TJSONParam.Create(RESTClientPoolerExec.Encoding);
     JSONParam.ParamName             := 'dwConnectionDefs';
     JSONParam.ObjectDirection       := odIn;
     JSONParam.AsString              := TConnectionDefs(ConnectionDefs).ToJSON;
     DWParams.Add(JSONParam);
    End;
   Try
    Try
     Result := RESTClientPoolerExec.SendEvent('OpenDatasets', DWParams);
     If (Result <> '') And
        (Uppercase(Result) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
      Begin
       If DWParams.ItemsString['MessageError'] <> Nil Then
        MessageError  := DWParams.ItemsString['MessageError'].Value;
       If DWParams.ItemsString['Error'] <> Nil Then
        Error         := StringToBoolean(DWParams.ItemsString['Error'].Value);
       If DWParams.ItemsString['Result'] <> Nil Then
        Begin
         If DWParams.ItemsString['Result'].AsString <> '' Then
          Result := DWParams.ItemsString['Result'].AsByteString;
        End;
      End
     Else
      Begin
       Error         := True;
       If (Result = '') Then
        MessageError  := Format('Unresolved Host : ''%s''', [Host])
       Else If (Uppercase(Result) <> Uppercase('HTTP/1.1 401 Unauthorized')) Then
        MessageError  := Format('Unauthorized Username : ''%s''', [UserName]);
       Raise Exception.Create(MessageError);
      End;
    Except
     On E : Exception Do
      Begin
       Error         := True;
       MessageError  := E.Message;
      End;
    End;
   Finally
    If Not Assigned(RESTClientPooler) Then
     FreeAndNil(RESTClientPoolerExec);
    FreeAndNil(DWParams);
   End;
  End;
End;

end.

