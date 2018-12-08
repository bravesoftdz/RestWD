unit uDWResponseTranslator;

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
 A. Brito                   - Admin - Administrador do CORE do pacote.
 Alexandre Abbade           - Admin - Administrador do desenvolvimento de DEMOS, coordenador do Grupo.
 Ari                        - Admin - Administrador do desenvolvimento de DEMOS, coordenador do Grupo.
 Alexandre Souza            - Admin - Administrador do Grupo de Organiza��o.
 Anderson Fiori             - Admin - Gerencia de Organiza��o dos Projetos
 Mizael Rocha               - Member Tester and DEMO Developer.
 Fl�vio Motta               - Member Tester and DEMO Developer.
 Itamar Gaucho              - Member Tester and DEMO Developer.
 Ico Menezes                - Commiter
}

interface

Uses uDWAbout,
     {$IFDEF FPC}
     SysUtils, Classes, ServerUtils, uDWConsts
     {$ELSE}
     {$IF CompilerVersion < 21}
     SysUtils, Classes,
     {$ELSE}
     System.SysUtils, System.Classes,
     {$IFEND}
     ServerUtils, uDWConsts
     {$ENDIF}
     , IdContext, IdTCPConnection, IdHTTPServer,        IdCustomHTTPServer, IdSSLOpenSSL,  IdSSL,
     IdAuthentication,             IdTCPClient,         IdHTTPHeaderInfo,   IdComponent,   IdBaseComponent,
     IdHTTP,                       IdMultipartFormData, IdMessageCoder,     IdMessage,     IdGlobalProtocols,
     IdGlobal,    uDWConstsData,   IdStack;

Type
 TOnWork       = Procedure (ASender           : TObject;
                            AWorkMode         : TWorkMode;
                            AWorkCount        : Int64)               Of Object;
 TOnWorkBegin  = Procedure (ASender           : TObject;
                            AWorkMode         : TWorkMode;
                            AWorkCountMax     : Int64)               Of Object;
 TOnWorkEnd    = Procedure (ASender           : TObject;
                            AWorkMode         : TWorkMode)           Of Object;
 TOnStatus     = Procedure (ASender           : TObject;
                            Const AStatus     : TIdStatus;
                            Const AStatusText : String)              Of Object;
 TPrepareGet   = Procedure (Var AUrl          : String;
                            Var AHeaders      : TStringList) Of Object;
 TPrepareEvent = Procedure (Var AUrl          : String;
                            Var AHeaders      : TStringList) Of Object;
 TAfterRequest = Procedure (AUrl              : String;
                            ResquestType      : TRequestType;
                            AResponse         : TStream)  Of Object;


Type
 TDWFieldDef = Class;
 TDWFieldDef = Class(TCollectionItem)
 Private
  vElementName,
  vFieldName    : String;
  vElementIndex,
  vFieldSize,
  vPrecision    : Integer;
  vDataType     : TObjectValue;
  vRequired     : Boolean;
 Public
  Function    GetDisplayName             : String;       Override;
  Procedure   SetDisplayName(Const Value : String);      Override;
  Constructor Create        (aCollection : TCollection); Override;
 Published
  Property    FieldName    : String       Read GetDisplayName Write SetDisplayName;
  Property    ElementName  : String       Read vElementName   Write vElementName;
  Property    ElementIndex : Integer      Read vElementIndex  Write vElementIndex;
  Property    FieldSize    : Integer      Read vFieldSize     Write vFieldSize;
  Property    Precision    : Integer      Read vPrecision     Write vPrecision;
  Property    DataType     : TObjectValue Read vDataType      Write vDataType;
  Property    Required     : Boolean      Read vRequired      Write vRequired;
End;

Type
 TDWFieldDefs = Class;
 TDWFieldDefs = Class(TOwnedCollection)
 Private
  fOwner      : TPersistent;
  Function    GetRec    (Index       : Integer) : TDWFieldDef;  Overload;
  Procedure   PutRec    (Index       : Integer;
                         Item        : TDWFieldDef);            Overload;
  Procedure   ClearList;
  Function    GetRecName(Index       : String)  : TDWFieldDef;  Overload;
  Procedure   PutRecName(Index       : String;
                         Item        : TDWFieldDef);            Overload;
 Public
  Constructor Create     (AOwner     : TPersistent;
                          aItemClass : TCollectionItemClass);
  Destructor  Destroy; Override;
  Procedure   Delete        (Index   : Integer);                   Overload;
  Property    Items         [Index   : Integer]   : TDWFieldDef Read GetRec     Write PutRec; Default;
  Property    FieldDefByName[Index   : String ]   : TDWFieldDef Read GetRecName Write PutRecName;
End;

Type
 TDWClientREST = Class(TDWComponent) //Novo Componente de Acesso a Requisi��es REST para o Servidores Diversos
 Protected
  //Vari�veis, Procedures e  Fun��es Protegidas
  HttpRequest          : TIdHTTP;
  vRSCharset           : TEncodeSelect;
  vRedirectMaximum     : Integer;
  Procedure SetParams      (Const aHttpRequest : TIdHTTP);
  Procedure SetOnWork      (Value              : TOnWork);
  Procedure SetOnWorkBegin (Value              : TOnWorkBegin);
  Procedure SetOnWorkEnd   (Value              : TOnWorkEnd);
  Procedure SetOnStatus    (Value              : TOnStatus);
  Function  GetAllowCookies                    : Boolean;
  Procedure SetAllowCookies(Value              : Boolean);
  Function  GetHandleRedirects                 : Boolean;
  Procedure SetHandleRedirects(Value           : Boolean);
 Private
  //Vari�veis, Procedures e Fun��es Privadas
  vDefaultCustomHeader : TStrings;
  vSSLVersions      : TIdSSLVersions;
  ssl               : TIdSSLIOHandlerSocketOpenSSL;
  vOnWork           : TOnWork;
  vOnWorkBegin      : TOnWorkBegin;
  vOnWorkEnd        : TOnWorkEnd;
  vOnStatus         : TOnStatus;
  vServerParams     : TServerParams;
  vMaxAuthRetries   : Integer;
  vContentEncoding,
  vAccept,
  vAccessControlAllowOrigin,
  vUserAgent,
  vContentType      : String;
  vUseSSL,
  vVerifyCert       : Boolean;
  vTransparentProxy : TIdProxyConnectionInfo;
  vRequestTimeOut   : Integer;
  vOnBeforeGet      : TPrepareGet;
  vOnBeforePost,
  vOnBeforePut,
  vOnBeforeDelete,
  vOnBeforePatch    : TPrepareEvent;
  vOnAfterRequest   : TAfterRequest;
  Function  GetVerifyCert        : Boolean;
  Procedure SetVerifyCert(aValue : Boolean);
  {$IFNDEF FPC}
  {$IFNDEF DELPHI_10TOKYO_UP}
  Function IdSSLIOHandlerSocketOpenSSL1VerifyPeer(Certificate : TIdX509;
                                                  AOk         : Boolean): Boolean;Overload;
  Function IdSSLIOHandlerSocketOpenSSL1VerifyPeer(Certificate : TIdX509;
                                                  AOk         : Boolean;
                                                  ADepth      : Integer): Boolean;Overload;
  {$ENDIF}
  {$ENDIF}
  Function IdSSLIOHandlerSocketOpenSSL1VerifyPeer(Certificate : TIdX509;
                                                  AOk         : Boolean;
                                                  ADepth,
                                                  AError      : Integer): Boolean;Overload;
  Procedure SetHeaders (AHeaders       : TStringList;
                        Var SendParams : TIdMultipartFormDataStream);Overload;
  Procedure SetHeaders (AHeaders       : TStringList);Overload;
  Procedure SetRawHeaders(AHeaders       : TStringList;
                          Var SendParams : TIdMultipartFormDataStream);
  Procedure SetUseSSL  (Value     : Boolean);
  Procedure CopyStringList(const Source, Dest: TStringList);
  Procedure SetDefaultCustomHeader(Value: TStrings);
 Public
  Constructor Create   (AOwner    : TComponent);Override;
  Destructor  Destroy;Override;
  Procedure   Get      (AUrl            : String        = '';
                        CustomHeaders   : TStringList   = Nil;
                        Const AResponse : TStringStream = Nil;
                        IgnoreEvents    : Boolean       = False);Overload;
  Procedure   Get      (AUrl            : String        = '';
                        CustomHeaders   : TStringList   = Nil;
                        Const AResponse : TStream       = Nil;
                        IgnoreEvents    : Boolean       = False);Overload;
  Procedure   Post     (AUrl            : String        = '';
                        CustomHeaders   : TStringList   = Nil;
                        Const AResponse : TStringStream = Nil;
                        IgnoreEvents    : Boolean       = False;
                        RawHeaders      : Boolean       = False);Overload;
  Procedure   Post     (AUrl            : String        = '';
                        CustomHeaders   : TStringList   = Nil;
                        Const AResponse : TStream       = Nil;
                        IgnoreEvents    : Boolean       = False;
                        RawHeaders      : Boolean       = False);Overload;
  Procedure   Put      (AUrl            : String        = '';
                        CustomHeaders   : TStringList   = Nil;
                        Const AResponse : TStringStream = Nil;
                        IgnoreEvents    : Boolean       = False);
  Procedure   Patch    (AUrl            : String        = '';
                        CustomHeaders   : TStringList   = Nil;
                        Const AResponse : TStringStream = Nil;
                        IgnoreEvents    : Boolean       = False);
  Procedure   Delete   (AUrl            : String        = '';
                        CustomHeaders   : TStringList   = Nil;
                        Const AResponse : TStringStream = Nil;
                        IgnoreEvents    : Boolean       = False);
 Published
  Property UseSSL                   : Boolean                Read vUseSSL                   Write vUseSSL;
  Property SSLVersions              : TIdSSLVersions         Read vSSLVersions              Write vSSLVersions;
  Property UserAgent                : String                 Read vUserAgent                Write vUserAgent;
  Property Accept                   : String                 Read vAccept                   Write vAccept;
  Property ContentEncoding          : String                 Read vContentEncoding          Write vContentEncoding;
  Property MaxAuthRetries           : Integer                Read vMaxAuthRetries           Write vMaxAuthRetries;
  Property ContentType              : String                 Read vContentType              Write vContentType;
  Property RequestCharset           : TEncodeSelect          Read vRSCharset                Write vRSCharset;
  Property DefaultCustomHeader      : TStrings               Read vDefaultCustomHeader      Write SetDefaultCustomHeader;
  Property ProxyOptions             : TIdProxyConnectionInfo Read vTransparentProxy         Write vTransparentProxy;
  Property RequestTimeOut           : Integer                Read vRequestTimeOut           Write vRequestTimeOut;
  Property AllowCookies             : Boolean                Read GetAllowCookies           Write SetAllowCookies;
  Property HandleRedirects          : Boolean                Read GetHandleRedirects        Write SetHandleRedirects;
  Property RedirectMaximum          : Integer                Read vRedirectMaximum          Write vRedirectMaximum;
  Property VerifyCert               : Boolean                Read GetVerifyCert             Write SetVerifyCert;
  Property AuthOptions              : TServerParams          Read vServerParams             Write vServerParams;
  Property AccessControlAllowOrigin : String                 Read vAccessControlAllowOrigin Write vAccessControlAllowOrigin;
  Property OnWork                   : TOnWork                Read vOnWork                   Write SetOnWork;
  Property OnWorkBegin              : TOnWorkBegin           Read vOnWorkBegin              Write SetOnWorkBegin;
  Property OnWorkEnd                : TOnWorkEnd             Read vOnWorkEnd                Write SetOnWorkEnd;
  Property OnStatus                 : TOnStatus              Read vOnStatus                 Write SetOnStatus;
  Property OnBeforeGet              : TPrepareGet            Read vOnBeforeGet              Write vOnBeforeGet;
  Property OnBeforePost             : TPrepareEvent          Read vOnBeforePost             Write vOnBeforePost;
  Property OnBeforePut              : TPrepareEvent          Read vOnBeforePut              Write vOnBeforePut;
  Property OnBeforeDelete           : TPrepareEvent          Read vOnBeforeDelete           Write vOnBeforeDelete;
  Property OnBeforePatch            : TPrepareEvent          Read vOnBeforePatch            Write vOnBeforePatch;
  Property OnAfterRequest           : TAfterRequest          Read vOnAfterRequest           Write vOnAfterRequest;
End;

Type
 TDWResponseTranslator = Class(TDWComponent)
 Protected
 Private
  vOpenRequest,
  vInsertRequest,
  vEditRequest,
  vDeleteRequest        : TRequestType;
  vRequestOpenUrl,
  vRequestInsertUrl,
  vRequestEditUrl,
  vRequestDeleteUrl,
  vElementBaseName,
  aValue                : String;
  fOwner                : TPersistent;
  vDWClientREST         : TDWClientREST;
  vDWFieldDefs          : TDWFieldDefs;
  vElementBaseIndex     : Integer;
  vAutoReadElementIndex : Boolean;
  Procedure   ReadData    (Value  : String);
 Public
  Constructor Create      (AOwner : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                      //Destroy a Classe
  Function    Open        (ResquestType : TRequestType;
                           RequestURL   : String) : String;
  Procedure   ApplyUpdates(ResquestType : TRequestType);
  Procedure   GetFieldDefs;
 Published
  Property ElementAutoReadRootIndex : Boolean       Read vAutoReadElementIndex Write vAutoReadElementIndex;
  Property ElementRootBaseIndex     : Integer       Read vElementBaseIndex     Write vElementBaseIndex;
  Property ElementRootBaseName      : String        Read vElementBaseName      Write vElementBaseName;
  Property RequestOpen              : TRequestType  Read vOpenRequest          Write vOpenRequest;
  Property RequestInsert            : TRequestType  Read vInsertRequest        Write vInsertRequest;
  Property RequestEdit              : TRequestType  Read vEditRequest          Write vEditRequest;
  Property RequestDelete            : TRequestType  Read vDeleteRequest        Write vDeleteRequest;
  Property RequestOpenUrl           : String        Read vRequestOpenUrl       Write vRequestOpenUrl;
  Property RequestInsertUrl         : String        Read vRequestInsertUrl     Write vRequestInsertUrl;
  Property RequestEditUrl           : String        Read vRequestEditUrl       Write vRequestEditUrl;
  Property RequestDeleteUrl         : String        Read vRequestDeleteUrl     Write vRequestDeleteUrl;
  Property FieldDefs                : TDWFieldDefs  Read vDWFieldDefs          Write vDWFieldDefs;
  Property ClientREST               : TDWClientREST Read vDWClientREST         Write vDWClientREST;
End;

Implementation

Uses uDWJSONTools, uDWJSONObject, uRESTDWBase;

{ TDWResponseTranslator }

Procedure TDWResponseTranslator.ApplyUpdates(ResquestType : TRequestType);
Begin

End;

Constructor TDWResponseTranslator.Create(AOwner : TComponent);
Begin
 Inherited;
 fOwner                := AOwner;
 vElementBaseIndex     := -1;
 vElementBaseName      := '';
 vAutoReadElementIndex := True;
 vDWFieldDefs          := TDWFieldDefs.Create(Self, TDWFieldDef);
 vOpenRequest          := rtGet;
 vInsertRequest        := rtPost;
 vEditRequest          := rtPost;
 vDeleteRequest        := rtDelete;
End;

Destructor TDWResponseTranslator.Destroy;
begin
 FreeAndNil(vDWFieldDefs);
 Inherited;
end;

Procedure TDWResponseTranslator.GetFieldDefs;
Var
 vValue       : String;
 LDataSetList : TJSONValue;
Begin
 vValue := Open(RequestOpen, RequestOpenUrl);
 LDataSetList := TJSONValue.Create;
 Try
  LDataSetList.Encoded  := False;
  If Assigned(ClientREST) Then
   LDataSetList.Encoding := ClientREST.RequestCharset;
  LDataSetList.WriteToFieldDefs(vValue, Self);
 Finally
  FreeAndNil(LDataSetList);
 End;
End;

Function TDWResponseTranslator.Open(ResquestType : TRequestType;
                                    RequestURL   : String) : String;
Var
 vResult : TStringStream;
Begin
 Result  := '';
 {$IFDEF FPC}
  vResult  := TStringStream.Create('');
 {$ELSE}
  {$if CompilerVersion > 21}
   vResult := TStringStream.Create;
  {$ELSE}
   vResult := TStringStream.Create('');
  {$IFEND}
 {$ENDIF}
 Try
  Case ResquestType Of
   rtGet  : ClientREST.Get (RequestURL, Nil, vResult);
   rtPost : ClientREST.Post(RequestURL, Nil, vResult);
  End;
 Finally
  {$IFDEF FPC}
   Result  := StringReplace(vResult.DataString, #10, '', [rfReplaceAll]);
  {$ELSE}
   Result  := StringReplace(vResult.DataString, #$A, '', [rfReplaceAll]);
  {$ENDIF}
  FreeAndNil(vResult);
 End;
End;

Procedure TDWResponseTranslator.ReadData(Value : String);
Begin
 aValue := Value;

End;

{ TDWFieldDefs }

Procedure TDWFieldDefs.ClearList;
Var
 I : Integer;
Begin
 For I := Count - 1 Downto 0 Do
  Delete(I);
 Self.Clear;
End;

Constructor TDWFieldDefs.Create(AOwner     : TPersistent;
                                aItemClass : TCollectionItemClass);
Begin
 Inherited Create(AOwner, TDWFieldDef);
 Self.fOwner := AOwner;
End;

Procedure TDWFieldDefs.Delete(Index: Integer);
Begin
 If (Index < Self.Count) And (Index > -1) Then
  TOwnedCollection(Self).Delete(Index);
End;

Destructor TDWFieldDefs.Destroy;
Begin
 ClearList;
 Inherited;
End;

Function TDWFieldDefs.GetRec(Index: Integer): TDWFieldDef;
Begin
 Result := TDWFieldDef(inherited GetItem(Index));
End;

Function TDWFieldDefs.GetRecName(Index: String): TDWFieldDef;
Var
 I : Integer;
Begin
 Result := Nil;
 For I := 0 To Self.Count - 1 Do
  Begin
   If (Uppercase(Index) = Uppercase(Self.Items[I].FieldName))   Or
      (Uppercase(Index) = Uppercase(Self.Items[I].ElementName)) Then
    Begin
     Result := TDWFieldDef(Self.Items[I]);
     Break;
    End;
  End;
End;

Procedure TDWFieldDefs.PutRec(Index: Integer; Item: TDWFieldDef);
Begin
 If (Index < Self.Count) And (Index > -1) Then
  SetItem(Index, Item);
End;

Procedure TDWFieldDefs.PutRecName(Index: String; Item: TDWFieldDef);
Var
 I : Integer;
Begin
 For I := 0 To Self.Count - 1 Do
  Begin
   If (Uppercase(Index) = Uppercase(Self.Items[I].FieldName)) Then
    Begin
     Self.Items[I] := Item;
     Break;
    End;
  End;
End;

{ TDWFieldDef }

Constructor TDWFieldDef.Create(aCollection: TCollection);
Begin
 Inherited;
 vFieldName    :=  'dwFieldDef' + IntToStr(aCollection.Count);
 vElementName  := vFieldName;
 vDataType     := ovString;
 vFieldSize    := 20;
 vPrecision    := 0;
 vElementIndex := -1;
 vRequired     := False;
End;

Function TDWFieldDef.GetDisplayName: String;
Begin
 Result := vFieldName;
End;

Procedure TDWFieldDef.SetDisplayName(const Value: String);
Begin
 If Trim(Value) = '' Then
  Raise Exception.Create('Invalid FieldName')
 Else
  Begin
   vFieldName := Trim(Value);
   Inherited;
  End;
End;

Constructor TDWClientREST.Create(AOwner: TComponent);
Begin
 Inherited;
 HttpRequest                     := TIdHTTP.Create(Nil);
 vContentType                    := 'application/json';
 vContentEncoding                := 'multipart/form-data';
 vAccept                         := 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
 vMaxAuthRetries                 := 0;
 vUserAgent                      := HttpRequest.Request.UserAgent;
 HttpRequest.Request.ContentType := vContentType;
 HttpRequest.AllowCookies        := False;
 HttpRequest.HTTPOptions         := [hoKeepOrigProtocol];
 vTransparentProxy               := TIdProxyConnectionInfo.Create;
 vServerParams                   := TServerParams.Create(Self);
 vServerParams.HasAuthentication := False;
 vServerParams.UserName          := '';
 vServerParams.Password          := '';
 vAccessControlAllowOrigin       := '*';
 vRedirectMaximum                := 1;
 vDefaultCustomHeader            := TStringList.Create;
 {$IFDEF FPC}
  vRSCharset                     := esUtf8;
 {$ELSE}
   {$IF CompilerVersion < 21}
    vRSCharset                   := esAnsi;
   {$ELSE}
    vRSCharset                   := esUtf8;
   {$IFEND}
 {$ENDIF}
 vVerifyCert                     := False;
 vRequestTimeOut                 := 1000;
 {$if Defined(FPC)}
  vSSLVersions                   := [sslvTLSv1];
 {$ifend}
 {$if Defined(DELPHI_7)    Or Defined(DELPHI_2007) Or
      Defined(DELPHI_2009) Or Defined(DELPHI_2010)}
  vSSLVersions                   := [sslvTLSv1];
 {$ifend}
 {$if defined(DELPHI_XE) or defined(DELPHI_XE2)}
  vSSLVersions                   := [sslvTLSv1];
 {$ifend}
 {$IFDEF DELPHI_XE3_UP}
  vSSLVersions                   := [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
 {$ENDIF}
End;

Procedure TDWClientREST.SetDefaultCustomHeader(Value: TStrings);
Begin
 vDefaultCustomHeader.Assign(value);
End;

Function TDWClientREST.GetVerifyCert : boolean;
Begin
 Result := vVerifyCert;
End;

Procedure TDWClientREST.SetVerifyCert(aValue : Boolean);
Begin
 vVerifyCert := aValue;
End;

Procedure TDWClientREST.SetUseSSL(Value : Boolean);
Begin
 HttpRequest.IOHandler := Nil;
 If Value Then
  Begin
   If ssl = Nil Then
    Begin
     ssl               := TIdSSLIOHandlerSocketOpenSSL.Create(HttpRequest);
     {$IFDEF FPC}
      ssl.OnVerifyPeer := @IdSSLIOHandlerSocketOpenSSL1VerifyPeer;
     {$ELSE}
      ssl.OnVerifyPeer := IdSSLIOHandlerSocketOpenSSL1VerifyPeer;
     {$ENDIF}
    End;
   {$if Defined(DELPHI_7)    Or Defined(DELPHI_2007) Or
        Defined(DELPHI_2009) Or Defined(DELPHI_2010)}
    ssl.SSLOptions.Method      := vSSLVersions;
   {$ELSE}
    ssl.SSLOptions.SSLVersions := vSSLVersions;
   {$IFEND}
   HttpRequest.IOHandler := ssl;
  End
 Else
  Begin
   If Assigned(ssl) Then
    FreeAndNil(ssl);
  End;
End;

Procedure TDWClientREST.Delete(AUrl            : String        = '';
                               CustomHeaders   : TStringList   = Nil;
                               Const AResponse : TStringStream = Nil;
                               IgnoreEvents    : Boolean       = False);
Var
 Temp         : TStringStream;
 vTempHeaders : TStringList;
 tempResponse : TStringStream;
 SendParams   : TIdMultipartFormDataStream;
Begin
 Try
  tempResponse := Nil;
  SendParams   := Nil;
  SetParams(HttpRequest);
  SetUseSSL(vUseSSL);
  vTempHeaders := TStringList.Create;
  If Not Assigned(AResponse) Then
   Begin
    {$IFDEF FPC}
     tempResponse  := TStringStream.Create('');
    {$ELSE}
     {$IF CompilerVersion < 21}
      tempResponse := TStringStream.Create('');
     {$ELSE}
      tempResponse := TStringStream.Create;
     {$IFEND}
    {$ENDIF}
   End;
  Try
   //Copy Custom Headers
  // CopyStringList(TStringList(vDefaultCustomHeader), vTempHeaders);
   SetHeaders(TStringList(vDefaultCustomHeader));
   If Not IgnoreEvents Then
   If Assigned(vOnBeforeDelete) then
    If Not Assigned(CustomHeaders) Then
     vOnBeforeDelete(AUrl, vTempHeaders)
    Else
     vOnBeforeDelete(AUrl, CustomHeaders);
   //Copy New Headers
   CopyStringList(CustomHeaders, vTempHeaders);
   SetHeaders(vTempHeaders, SendParams);
   HttpRequest.Delete(AUrl, tempResponse);
   If Not IgnoreEvents Then
   If Assigned(vOnAfterRequest) then
    vOnAfterRequest(AUrl, rtDelete, tempResponse);
  Finally
   vTempHeaders.Free;
   If Assigned(tempResponse) Then
    tempResponse.Free;
  End;
 Except
  On E: EIdHTTPProtocolException Do
   Begin
    If Length(E.ErrorMessage) > 0 Then
     Begin
      temp := TStringStream.Create(E.ErrorMessage);
      AResponse.CopyFrom(temp, temp.Size);
      Temp.Free;
     End;
   End;
  On E : EIdSocketError do
   Begin
    HttpRequest.Disconnect(false);
    Raise
   End;
 End;
End;

Destructor TDWClientREST.Destroy;
Begin
 FreeAndNil(HttpRequest);
 FreeAndNil(vTransparentProxy);
 FreeAndNil(vServerParams);
 FreeAndNil(vDefaultCustomHeader);
 Inherited;
End;

Procedure TDWClientREST.CopyStringList(Const Source, Dest : TStringList);
Var
 I : Integer;
Begin
 If Assigned(Source) And Assigned(Dest) Then
  For I := 0 To Source.Count -1 Do
   Dest.Add(Source[I]);
End;

Procedure TDWClientREST.Get(AUrl            : String        = '';
                            CustomHeaders   : TStringList   = Nil;
                            Const AResponse : TStringStream = Nil;
                            IgnoreEvents    : Boolean       = False);
Var
 temp         : TStringStream;
 vTempHeaders : TStringList;
 atempResponse,
 tempResponse : TStringStream;
 SendParams   : TIdMultipartFormDataStream;
Begin
 Try
  AUrl := StringReplace(AUrl, #012, '', [rfReplaceAll]);
  tempResponse := Nil;
  SendParams   := Nil;
  SetParams(HttpRequest);
  SetUseSSL(vUseSSL);
  vTempHeaders := TStringList.Create;
  {$IFDEF FPC}
   atempResponse  := TStringStream.Create('');
  {$ELSE}
   {$IF CompilerVersion < 21}
    atempResponse := TStringStream.Create('');
   {$ELSE}
    atempResponse := TStringStream.Create;
   {$IFEND}
  {$ENDIF}
  If Not Assigned(AResponse) Then
   Begin
    {$IFDEF FPC}
     tempResponse  := TStringStream.Create('');
    {$ELSE}
     {$IF CompilerVersion < 21}
      tempResponse := TStringStream.Create('');
     {$ELSE}
      tempResponse := TStringStream.Create;
     {$IFEND}
    {$ENDIF}
   End;
  Try
   //Copy Custom Headers
//   CopyStringList(TStringList(vDefaultCustomHeader), vTempHeaders);
   SetHeaders(TStringList(vDefaultCustomHeader));
   If Not IgnoreEvents Then
   If Assigned(vOnBeforeGet) then
    If Not Assigned(CustomHeaders) Then
     vOnBeforeGet(AUrl, vTempHeaders)
    Else
     vOnBeforeGet(AUrl, CustomHeaders);
   //Copy New Headers
   CopyStringList(CustomHeaders, vTempHeaders);
   SetHeaders(vTempHeaders, SendParams);
   If Not Assigned(AResponse) Then
    Begin
     HttpRequest.Get(AUrl, atempResponse);
     atempResponse.Position := 0;
     If vRSCharset = esUtf8 Then
      tempResponse.WriteString(utf8Decode(atempResponse.DataString))
     Else
      tempResponse.WriteString(atempResponse.DataString);
     FreeAndNil(atempResponse);
     tempResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtGet, tempResponse);
    End
   Else
    Begin
     HttpRequest.Get(AUrl, atempResponse); // AResponse);
     atempResponse.Position := 0;
     If vRSCharset = esUtf8 Then
      AResponse.WriteString(utf8Decode(atempResponse.DataString))
     Else
      AResponse.WriteString(atempResponse.DataString);
     FreeAndNil(atempResponse);
     AResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtGet, AResponse);
    End;
  Finally
   vTempHeaders.Free;
   If Assigned(tempResponse) Then
    tempResponse.Free;
  End;
 Except
   { Ico - receber erros do servidor no verbo GET }
  On E: EIdHTTPProtocolException Do
   Begin
    If Length(E.ErrorMessage) > 0 Then
     Begin
      temp := TStringStream.Create(E.ErrorMessage);
      AResponse.CopyFrom(temp, temp.Size);
      temp.Free;
     End;
   End;
  On E: EIdSocketError Do
   Begin
    HttpRequest.Disconnect(false);
    Raise;
   End;
  {
  On E : Exception do
   Begin
    Exception.Create(E.Message);  //Raise;
   End;
  } // Exception anterior!
 End;
 If Assigned(atempResponse) Then
  FreeAndNil(atempResponse);
End;

procedure TDWClientREST.Get(AUrl            : String;
                            CustomHeaders   : TStringList;
                            Const AResponse : TStream;
                            IgnoreEvents    : Boolean);
Var
 temp         : TStringStream;
 vTempHeaders : TStringList;
 atempResponse,
 tempResponse : TMemoryStream;
 SendParams   : TIdMultipartFormDataStream;
Begin
 Try
  AUrl := StringReplace(AUrl, #012, '', [rfReplaceAll]);
  tempResponse := Nil;
  SendParams   := Nil;
  SetParams(HttpRequest);
  SetUseSSL(vUseSSL);
  vTempHeaders := TStringList.Create;
  atempResponse  := TMemoryStream.Create;
  If Not Assigned(AResponse) Then
   tempResponse  := TMemoryStream.Create;
  Try
   //Copy Custom Headers
//   CopyStringList(TStringList(vDefaultCustomHeader), vTempHeaders);
   SetHeaders(TStringList(vDefaultCustomHeader));
   If Not IgnoreEvents Then
   If Assigned(vOnBeforeGet) then
    If Not Assigned(CustomHeaders) Then
     vOnBeforeGet(AUrl, vTempHeaders)
    Else
     vOnBeforeGet(AUrl, CustomHeaders);
   //Copy New Headers
   CopyStringList(CustomHeaders, vTempHeaders);
   SetHeaders(vTempHeaders, SendParams);
   If Not Assigned(AResponse) Then
    Begin
     HttpRequest.Get(AUrl, atempResponse);
     atempResponse.Position := 0;
     tempResponse.CopyFrom(atempResponse, atempResponse.Size);
     FreeAndNil(atempResponse);
     tempResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtGet, tempResponse);
    End
   Else
    Begin
     HttpRequest.Get(AUrl, atempResponse); // AResponse);
     atempResponse.Position := 0;
     AResponse.CopyFrom(atempResponse, atempResponse.Size);
     FreeAndNil(atempResponse);
     AResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtGet, AResponse);
    End;
  Finally
   vTempHeaders.Free;
   If Assigned(tempResponse) Then
    tempResponse.Free;
  End;
 Except
  { Ico - receber erros do servidor no verbo GET }
  On E: EIdHTTPProtocolException Do
   Begin
    If Length(E.ErrorMessage) > 0 Then
     Begin
      temp := TStringStream.Create(E.ErrorMessage);
      AResponse.CopyFrom(temp, temp.Size);
      temp.Free;
     End;
   End;
  On E: EIdSocketError Do
   Begin
    HttpRequest.Disconnect(false);
    Raise;
   End;
 End;
 If Assigned(atempResponse) Then
  FreeAndNil(atempResponse);
End;

function TDWClientREST.GetAllowCookies: Boolean;
begin
 Result := HttpRequest.AllowCookies;
end;

function TDWClientREST.GetHandleRedirects: Boolean;
begin
 Result := HttpRequest.HandleRedirects;
end;

{$IFNDEF FPC}
{$IFNDEF DELPHI_10TOKYO_UP}
Function TDWClientREST.IdSSLIOHandlerSocketOpenSSL1VerifyPeer(Certificate : TIdX509;
                                                              AOk         : Boolean) : Boolean;
Begin
 Result := IdSSLIOHandlerSocketOpenSSL1VerifyPeer(Certificate, AOk, -1);
End;

Function TDWClientREST.IdSSLIOHandlerSocketOpenSSL1VerifyPeer(Certificate : TIdX509;
                                                              AOk         : Boolean;
                                                              ADepth      : Integer) : Boolean;
Begin
 Result := IdSSLIOHandlerSocketOpenSSL1VerifyPeer(Certificate, AOk, ADepth, -1);
End;
{$ENDIF}
{$ENDIF}

Function TDWClientREST.IdSSLIOHandlerSocketOpenSSL1VerifyPeer(Certificate : TIdX509;
                                                              AOk         : Boolean;
                                                              ADepth,
                                                              AError      : Integer) : Boolean;
Begin
 Result := AOk;
 If Not vVerifyCert then
  Result := True;
End;

Procedure TDWClientREST.Patch(AUrl            : String        = '';
                              CustomHeaders   : TStringList   = Nil;
                              Const AResponse : TStringStream = Nil;
                              IgnoreEvents    : Boolean       = False);
Var
 temp         : TStringStream;
 vTempHeaders : TStringList;
 atempResponse,
 tempResponse : TStringStream;
 SendParams   : TIdMultipartFormDataStream;
Begin
 Try
  tempResponse := Nil;
  SendParams   := Nil;
  SetParams(HttpRequest);
  SetUseSSL(vUseSSL);
  vTempHeaders := TStringList.Create;
  {$IFDEF FPC}
   atempResponse  := TStringStream.Create('');
  {$ELSE}
   {$IF CompilerVersion < 21}
    atempResponse := TStringStream.Create('');
   {$ELSE}
    atempResponse := TStringStream.Create;
   {$IFEND}
  {$ENDIF}
  If Not Assigned(AResponse) Then
   Begin
    {$IFDEF FPC}
     tempResponse  := TStringStream.Create('');
    {$ELSE}
     {$IF CompilerVersion < 21}
      tempResponse := TStringStream.Create('');
     {$ELSE}
      tempResponse := TStringStream.Create;
     {$IFEND}
    {$ENDIF}
   End;
  Try
   //Copy Custom Headers
//   CopyStringList(TStringList(vDefaultCustomHeader), vTempHeaders);
   SetHeaders(TStringList(vDefaultCustomHeader));
   If Not IgnoreEvents Then
   If Assigned(vOnBeforePatch) then
    If Not Assigned(CustomHeaders) Then
     vOnBeforePatch(AUrl, vTempHeaders)
    Else
     vOnBeforePatch(AUrl, CustomHeaders);
   //Copy New Headers
   CopyStringList(CustomHeaders, vTempHeaders);
   SetHeaders(vTempHeaders, SendParams);
   If Not Assigned(AResponse) Then
    Begin
     {$IFNDEF FPC}{$IF (CompilerVersion = 23) OR (CompilerVersion = 24)}
     //TODO
     {$ELSE}
      HttpRequest.Patch(AUrl, atempResponse);
     {$IFEND}
     {$ENDIF}
     atempResponse.Position := 0;
     If vRSCharset = esUtf8 Then
      tempResponse.WriteString(utf8Decode(atempResponse.DataString))
     Else
      tempResponse.WriteString(atempResponse.DataString);
     FreeAndNil(atempResponse);
     tempResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtPatch, tempResponse);
    End
   Else
    Begin
     {$IFNDEF FPC}{$IF (CompilerVersion = 23) OR (CompilerVersion = 24)}
     //TODO
     {$ELSE}
      HttpRequest.Patch(AUrl, atempResponse);
     {$IFEND}
     {$ENDIF}
     atempResponse.Position := 0;
     If vRSCharset = esUtf8 Then
      AResponse.WriteString(utf8Decode(atempResponse.DataString))
     Else
      AResponse.WriteString(atempResponse.DataString);
     FreeAndNil(atempResponse);
     AResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtPatch, AResponse);
    End;
  Finally
   vTempHeaders.Free;
   If Assigned(tempResponse) Then
    tempResponse.Free;
  End;
 Except
  On E: EIdHTTPProtocolException Do
   Begin
    If Length(E.ErrorMessage) > 0 Then
     Begin
      temp := TStringStream.Create(E.ErrorMessage);
      AResponse.CopyFrom(temp, temp.Size);
      temp.Free;
     End;
   End;
  On E: EIdSocketError Do
   Begin
    HttpRequest.Disconnect(false);
    Raise;
   End;
 End;
 If Assigned(atempResponse) Then
  FreeAndNil(atempResponse);
End;

procedure TDWClientREST.Post(AUrl            : String;
                             CustomHeaders   : TStringList;
                             Const AResponse : TStream;
                             IgnoreEvents,
                             RawHeaders      : Boolean);
Var
 temp         : TStringStream;
 vTempHeaders : TStringList;
 atempResponse,
 tempResponse : TMemoryStream;
 SendParams   : TIdMultipartFormDataStream;
Begin
 SendParams   := TIdMultipartFormDataStream.Create;
 Try
  tempResponse := Nil;
  SetParams(HttpRequest);
  SetUseSSL(vUseSSL);
  vTempHeaders := TStringList.Create;
  atempResponse  := TMemoryStream.Create;
  If Not Assigned(AResponse) Then
   tempResponse  := TMemoryStream.Create;
  Try
   //Copy Custom Headers
//   CopyStringList(TStringList(vDefaultCustomHeader), vTempHeaders);
   SetHeaders(TStringList(vDefaultCustomHeader));
   If Not IgnoreEvents Then
   If Assigned(vOnBeforePost) then
    If Not Assigned(CustomHeaders) Then
     vOnBeforePost(AUrl, vTempHeaders)
    Else
     vOnBeforePost(AUrl, CustomHeaders);
   //Copy New Headers
   CopyStringList(CustomHeaders, vTempHeaders);
   If Not RawHeaders Then
    SetHeaders(vTempHeaders, SendParams)
   Else
    Begin
     FreeAndNil(SendParams);
     SetRawHeaders(vTempHeaders, SendParams);
    End;
   If Not Assigned(AResponse) Then
    Begin
     HttpRequest.Post(AUrl, SendParams, atempResponse);
     atempResponse.Position := 0;
     tempResponse.CopyFrom(atempResponse, atempResponse.Size);
     FreeAndNil(atempResponse);
     tempResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtPost, tempResponse);
    End
   Else
    Begin
     temp := Nil;
     If Assigned(CustomHeaders) Then
      temp         := TStringStream.Create(CustomHeaders.Text);
     HttpRequest.Post(AUrl, temp, atempResponse);
     atempResponse.Position := 0;
     AResponse.CopyFrom(atempResponse, atempResponse.Size);
     FreeAndNil(atempResponse);
     AResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtPost, AResponse);
    End;
  Finally
   vTempHeaders.Free;
   If Assigned(tempResponse) Then
    tempResponse.Free;
   SendParams.Free;
   If Assigned(temp) Then
    temp.Free;
  End;
 Except
  On E: EIdHTTPProtocolException do
   Begin
    If (Length(E.ErrorMessage) > 0) Or (E.ErrorCode > 0) then
     Begin
      temp := TStringStream.Create(E.ErrorMessage);
      AResponse.CopyFrom(temp, temp.Size);
      temp.Free;
     End;
   End;
  On E: EIdSocketError do
   Begin
    HttpRequest.Disconnect(false);
    Raise;
   End;
 End;
 If Assigned(atempResponse) Then
  FreeAndNil(atempResponse);
End;

Procedure TDWClientREST.Post(AUrl            : String        = '';
                             CustomHeaders   : TStringList   = Nil;
                             Const AResponse : TStringStream = Nil;
                             IgnoreEvents    : Boolean       = False;
                             RawHeaders      : Boolean       = False);
Var
 temp         : TStringStream;
 vTempHeaders : TStringList;
 atempResponse,
 tempResponse : TStringStream;
 SendParams   : TIdMultipartFormDataStream;
Begin
 SendParams   := TIdMultipartFormDataStream.Create;
 Try
  tempResponse := Nil;
  SetParams(HttpRequest);
  SetUseSSL(vUseSSL);
  vTempHeaders := TStringList.Create;
  {$IFDEF FPC}
   atempResponse  := TStringStream.Create('');
  {$ELSE}
   {$IF CompilerVersion < 21}
    atempResponse := TStringStream.Create('');
   {$ELSE}
    atempResponse := TStringStream.Create;
   {$IFEND}
  {$ENDIF}
  If Not Assigned(AResponse) Then
   Begin
    {$IFDEF FPC}
     tempResponse  := TStringStream.Create('');
    {$ELSE}
     {$IF CompilerVersion < 21}
      tempResponse := TStringStream.Create('');
     {$ELSE}
      tempResponse := TStringStream.Create;
     {$IFEND}
    {$ENDIF}
   End;
  Try
   //Copy Custom Headers
//   CopyStringList(TStringList(vDefaultCustomHeader), vTempHeaders);
   SetHeaders(TStringList(vDefaultCustomHeader));
   If Not IgnoreEvents Then
   If Assigned(vOnBeforePost) then
    If Not Assigned(CustomHeaders) Then
     vOnBeforePost(AUrl, vTempHeaders)
    Else
     vOnBeforePost(AUrl, CustomHeaders);
   //Copy New Headers
   CopyStringList(CustomHeaders, vTempHeaders);
   SetRawHeaders(vTempHeaders, SendParams);
   If Not Assigned(AResponse) Then
    Begin
     HttpRequest.Post(AUrl, SendParams, atempResponse);
     atempResponse.Position := 0;
     If vRSCharset = esUtf8 Then
      tempResponse.WriteString(utf8Decode(atempResponse.DataString))
     Else
      tempResponse.WriteString(atempResponse.DataString);
     FreeAndNil(atempResponse);
     tempResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtPost, tempResponse);
    End
   Else
    Begin
     temp := Nil;
     If Assigned(CustomHeaders) Then
      temp         := TStringStream.Create(CustomHeaders.Text);
     HttpRequest.Post(AUrl, temp, atempResponse);
//     HttpRequest.Post(AUrl, SendParams, atempResponse);
     atempResponse.Position := 0;
     If vRSCharset = esUtf8 Then
      AResponse.WriteString(utf8Decode(atempResponse.DataString))
     Else
      AResponse.WriteString(atempResponse.DataString);
     FreeAndNil(atempResponse);
     AResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtPost, AResponse);
    End;
  Finally
   vTempHeaders.Free;
   If Assigned(tempResponse) Then
    tempResponse.Free;
   SendParams.Free;
   If Assigned(temp) Then
    temp.Free;
  End;
 Except
  On E: EIdHTTPProtocolException do
   Begin
    If (Length(E.ErrorMessage) > 0) Or (E.ErrorCode > 0) then
     Begin
      temp := TStringStream.Create(E.ErrorMessage);
      AResponse.CopyFrom(temp, temp.Size);
      temp.Free;
     End;
   End;
  On E: EIdSocketError do
   Begin
    HttpRequest.Disconnect(false);
    Raise;
   End;
 End;
 If Assigned(atempResponse) Then
  FreeAndNil(atempResponse);
End;

Procedure TDWClientREST.Put(AUrl            : String        = '';
                            CustomHeaders   : TStringList   = Nil;
                            Const AResponse : TStringStream = Nil;
                            IgnoreEvents    : Boolean       = False);
Var
 temp         : TStringStream;
 vTempHeaders : TStringList;
 atempResponse,
 tempResponse : TStringStream;
 SendParams   : TIdMultipartFormDataStream;
Begin
 Try
  tempResponse := Nil;
  SendParams   := Nil;
  SetParams(HttpRequest);
  SetUseSSL(vUseSSL);
  vTempHeaders := TStringList.Create;
  {$IFDEF FPC}
   atempResponse  := TStringStream.Create('');
  {$ELSE}
   {$IF CompilerVersion < 21}
    atempResponse := TStringStream.Create('');
   {$ELSE}
    atempResponse := TStringStream.Create;
   {$IFEND}
  {$ENDIF}
  If Not Assigned(AResponse) Then
   Begin
    {$IFDEF FPC}
     tempResponse  := TStringStream.Create('');
    {$ELSE}
     {$IF CompilerVersion < 21}
      tempResponse := TStringStream.Create('');
     {$ELSE}
      tempResponse := TStringStream.Create;
     {$IFEND}
    {$ENDIF}
   End;
  Try
   //Copy Custom Headers
//   CopyStringList(TStringList(vDefaultCustomHeader), vTempHeaders);
   SetHeaders(TStringList(vDefaultCustomHeader));
   If Not IgnoreEvents Then
   If Assigned(vOnBeforePut) then
    If Not Assigned(CustomHeaders) Then
     vOnBeforePut(AUrl, vTempHeaders)
    Else
     vOnBeforePut(AUrl, CustomHeaders);
   //Copy New Headers
   CopyStringList(CustomHeaders, vTempHeaders);
   SetHeaders(vTempHeaders, SendParams);
   If Not Assigned(AResponse) Then
    Begin
     HttpRequest.Put(AUrl, SendParams, atempResponse);
     atempResponse.Position := 0;
     If vRSCharset = esUtf8 Then
      tempResponse.WriteString(utf8Decode(atempResponse.DataString))
     Else
      tempResponse.WriteString(atempResponse.DataString);
     FreeAndNil(atempResponse);
     tempResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtPut, tempResponse);
    End
   Else
    Begin
     HttpRequest.Put(AUrl, SendParams, atempResponse);
     atempResponse.Position := 0;
     If vRSCharset = esUtf8 Then
      AResponse.WriteString(utf8Decode(atempResponse.DataString))
     Else
      AResponse.WriteString(atempResponse.DataString);
     FreeAndNil(atempResponse);
     AResponse.Position := 0;
     If Not IgnoreEvents Then
     If Assigned(vOnAfterRequest) then
      vOnAfterRequest(AUrl, rtPut, AResponse);
    End;
  Finally
   vTempHeaders.Free;
   If Assigned(tempResponse) Then
    tempResponse.Free;
  End;
 Except
  On E: EIdHTTPProtocolException Do
   Begin
    If Length(E.ErrorMessage) > 0 Then
     Begin
      temp := TStringStream.Create(E.ErrorMessage);
      AResponse.CopyFrom(temp, temp.Size);
      temp.Free;
     End;
   End;
  On E: EIdSocketError Do
   Begin
    HttpRequest.Disconnect(false);
    Raise;
   End;
 End;
 If Assigned(atempResponse) Then
  FreeAndNil(atempResponse);
End;

procedure TDWClientREST.SetAllowCookies(Value: Boolean);
begin
 HttpRequest.AllowCookies    := Value;
end;

procedure TDWClientREST.SetHandleRedirects(Value: Boolean);
begin
 HttpRequest.HandleRedirects := Value;
end;

procedure TDWClientREST.SetHeaders(AHeaders: TStringList);
Var
 I : Integer;
Begin
 HttpRequest.Request.CustomHeaders.Clear;
 If vAccessControlAllowOrigin <> '' Then
  Begin
   {$IFNDEF FPC}
    {$if CompilerVersion > 21}
     HttpRequest.Request.CustomHeaders.AddValue('Access-Control-Allow-Origin', vAccessControlAllowOrigin);
    {$ELSE}                                    // Ico Menezes 30/07/2018 - para compatibilidade com delphis velhos !
     HttpRequest.Request.CustomHeaders.AddValue('Access-Control-Allow-Origin', vAccessControlAllowOrigin);
    {$IFEND}
   {$ELSE}
    HttpRequest.Request.CustomHeaders.AddValue('Access-Control-Allow-Origin',  vAccessControlAllowOrigin);
   {$ENDIF}
  End;
 If Assigned(AHeaders) Then
  Begin
   If AHeaders.Count > 0 Then
    Begin
     For i := 0 to AHeaders.Count-1 do
      HttpRequest.Request.CustomHeaders.AddValue(AHeaders.Names[i], AHeaders.ValueFromIndex[i]);
    End;
  End;
End;

Procedure TDWClientREST.SetHeaders(AHeaders       : TStringList;
                                   Var SendParams : TIdMultipartFormDataStream);
Var
 I : Integer;
Begin
// HttpRequest.Request.CustomHeaders.Clear;
 If vAccessControlAllowOrigin <> '' Then
  Begin
   If SendParams <> Nil Then
    Begin
     {$IFNDEF FPC}
      {$if CompilerVersion > 21}
       HttpRequest.Request.CustomHeaders.AddValue('Access-Control-Allow-Origin', vAccessControlAllowOrigin);
      {$ELSE}                                    // Ico Menezes 30/07/2018 - para compatibilidade com delphis velhos !
       HttpRequest.Request.CustomHeaders.AddValue('Access-Control-Allow-Origin', vAccessControlAllowOrigin);
      {$IFEND}
     {$ELSE}
      HttpRequest.Request.CustomHeaders.AddValue('Access-Control-Allow-Origin',  vAccessControlAllowOrigin);
     {$ENDIF}
    End;
  End;
 If Assigned(AHeaders) Then
  Begin
   If AHeaders.Count > 0 Then
    Begin
     For i := 0 to AHeaders.Count-1 do
      Begin
       If SendParams = Nil Then
        Begin
         If vRSCharset = esUtf8 Then
          HttpRequest.Request.CustomHeaders.AddValue(AHeaders.Names[i], utf8Decode(AHeaders.ValueFromIndex[i]))
         Else
          HttpRequest.Request.CustomHeaders.AddValue(AHeaders.Names[i], AHeaders.ValueFromIndex[i]);
        End
       Else
        Begin
         If vRSCharset = esUtf8 Then
          SendParams.AddFormField(AHeaders.Names[i],  utf8Decode(AHeaders.ValueFromIndex[i]))
         Else
          SendParams.AddFormField(AHeaders.Names[i],  AHeaders.ValueFromIndex[i]);
        End;
      End;
    End;
  End;
End;

procedure TDWClientREST.SetOnStatus(Value: TOnStatus);
begin
 {$IFDEF FPC}
  vOnStatus            := Value;
  HttpRequest.OnStatus := vOnStatus;
 {$ELSE}
  vOnStatus            := Value;
  HttpRequest.OnStatus := vOnStatus;
 {$ENDIF}
end;

procedure TDWClientREST.SetOnWork(Value: TOnWork);
begin
 {$IFDEF FPC}
  vOnWork            := Value;
  HttpRequest.OnWork := vOnWork;
 {$ELSE}
  vOnWork            := Value;
  HttpRequest.OnWork := vOnWork;
 {$ENDIF}
end;

procedure TDWClientREST.SetOnWorkBegin(Value: TOnWorkBegin);
begin
 {$IFDEF FPC}
  vOnWorkBegin            := Value;
  HttpRequest.OnWorkBegin := vOnWorkBegin;
 {$ELSE}
  vOnWorkBegin            := Value;
  HttpRequest.OnWorkBegin := vOnWorkBegin;
 {$ENDIF}
end;

procedure TDWClientREST.SetOnWorkEnd(Value: TOnWorkEnd);
begin
 {$IFDEF FPC}
  vOnWorkEnd            := Value;
  HttpRequest.OnWorkEnd := vOnWorkEnd;
 {$ELSE}
  vOnWorkEnd            := Value;
  HttpRequest.OnWorkEnd := vOnWorkEnd;
 {$ENDIF}
end;

Procedure TDWClientREST.SetParams(Const aHttpRequest: TIdHTTP);
begin
 aHttpRequest.Request.BasicAuthentication := vServerParams.HasAuthentication;
 If aHttpRequest.Request.BasicAuthentication Then
  Begin
   If aHttpRequest.Request.Authentication = Nil Then
    aHttpRequest.Request.Authentication         := TIdBasicAuthentication.Create;
   aHttpRequest.Request.Authentication.Password := vServerParams.Password;
   aHttpRequest.Request.Authentication.Username := vServerParams.UserName;
  End;
 aHttpRequest.ProxyParams.BasicAuthentication   := vTransparentProxy.BasicAuthentication;
 aHttpRequest.ProxyParams.ProxyUsername         := vTransparentProxy.ProxyUsername;
 aHttpRequest.ProxyParams.ProxyServer           := vTransparentProxy.ProxyServer;
 aHttpRequest.ProxyParams.ProxyPassword         := vTransparentProxy.ProxyPassword;
 aHttpRequest.ProxyParams.ProxyPort             := vTransparentProxy.ProxyPort;
 aHttpRequest.ReadTimeout                       := vRequestTimeout;
 aHttpRequest.Request.ContentType               := HttpRequest.Request.ContentType;
 aHttpRequest.AllowCookies                      := HttpRequest.AllowCookies;
 aHttpRequest.HandleRedirects                   := HttpRequest.HandleRedirects;
 aHttpRequest.RedirectMaximum                   := vRedirectMaximum;
 aHttpRequest.HTTPOptions                       := HttpRequest.HTTPOptions;
 If vRSCharset = esUtf8 Then
  Begin
   aHttpRequest.Request.Charset                  := 'utf-8';
   aHttpRequest.Request.AcceptCharSet            := aHttpRequest.Request.Charset;
  End
 Else If vRSCharset = esASCII Then
  Begin
   aHttpRequest.Request.Charset                  := 'ascii';
   aHttpRequest.Request.AcceptCharSet            := aHttpRequest.Request.Charset;
  End
 Else If vRSCharset = esANSI Then
  Begin
   aHttpRequest.Request.Charset                  := 'ansi';
   aHttpRequest.Request.AcceptCharSet            := aHttpRequest.Request.Charset;
  End;
 aHttpRequest.Request.ContentType               := vContentType;
 aHttpRequest.Request.Accept                    := vAccept;
 aHttpRequest.Request.ContentEncoding           := vContentEncoding;
 aHttpRequest.Request.UserAgent                 := vUserAgent;
 aHttpRequest.MaxAuthRetries                    := vMaxAuthRetries;
end;

procedure TDWClientREST.SetRawHeaders(AHeaders: TStringList;
  var SendParams: TIdMultipartFormDataStream);
Var
 I : Integer;
Begin
 HttpRequest.Request.RawHeaders.Clear;
// HttpRequest.Request.CustomHeaders.Clear;
 If vAccessControlAllowOrigin <> '' Then
  Begin
   If SendParams <> Nil Then
    Begin
     {$IFNDEF FPC}
      {$if CompilerVersion > 21}
       SendParams.AddFormField('Access-Control-Allow-Origin', vAccessControlAllowOrigin);
      {$ELSE}                                    // Ico Menezes 30/07/2018 - para compatibilidade com delphis velhos !
       SendParams.AddFormField('Access-Control-Allow-Origin', vAccessControlAllowOrigin);
      {$IFEND}
     {$ELSE}
      SendParams.AddFormField('Access-Control-Allow-Origin',  vAccessControlAllowOrigin);
     {$ENDIF}
    End;
  End;
 If Assigned(AHeaders) Then
  Begin
   If AHeaders.Count > 0 Then
    Begin
     For i := 0 to AHeaders.Count-1 do
      Begin
       If SendParams = Nil Then
        Begin
         If vRSCharset = esUtf8 Then
          HttpRequest.Request.RawHeaders.Add(utf8Decode(AHeaders[i]))
         Else
          HttpRequest.Request.RawHeaders.Add(AHeaders[i]);
        End
       Else
        Begin
         If vRSCharset = esUtf8 Then
          SendParams.AddFormField(AHeaders.Names[i],  utf8Decode(AHeaders.ValueFromIndex[i]))
         Else
          SendParams.AddFormField(AHeaders.Names[i],  AHeaders.ValueFromIndex[i]);
        End;
      End;
    End;
  End;
End;

end.
