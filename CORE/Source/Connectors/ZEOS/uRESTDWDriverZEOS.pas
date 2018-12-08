unit uRESTDWDriverZEOS;

interface

uses
 {$IFDEF FPC}
 SysUtils,  Classes, DB, lconvencoding,
 {$ELSE}
 {$IF CompilerVersion < 21}
 SysUtils,          Classes, DB,
 {$ELSE}
 System.SysUtils,   System.Classes, Data.DB,
 {$IFEND}
 {$ENDIF}
 ZSqlUpdate,               ZAbstractRODataset,      ZAbstractDataset,
 ZDataset,                 ZConnection,             ZStoredProcedure,
 ZSqlProcessor,            uDWConsts,
 uDWConstsData,            uRESTDWPoolerDB,         uDWJSON,
 uDWJSONObject,            uDWMassiveBuffer,        Variants,
 uDWDatamodule,            SysTypes,                uSystemEvents;

Type
 TRESTDWDriverZeos   = Class(TRESTDWDriver)
 Private
  vZConnection                 : TZConnection;
  Procedure SetConnection(Value : TZConnection);
  Function  GetConnection       : TZConnection;
  protected procedure Notification(AComponent: TComponent; Operation: TOperation); override;
 Public
  Function ApplyUpdates         (Massive,
                                 SQL              : String;
                                 Params           : TDWParams;
                                 Var Error        : Boolean;
                                 Var MessageError : String)          : TJSONValue;Override;
  Procedure ApplyUpdates_MassiveCache(MassiveCache : String;
                                      Var Error    : Boolean;
                                      Var MessageError  : String);Override;
  Function ExecuteCommand       (SQL              : String;
                                 Var Error        : Boolean;
                                 Var MessageError : String;
                                 Execute          : Boolean = False) : String;Overload;Override;
  Function ExecuteCommand       (SQL              : String;
                                 Params           : TDWParams;
                                 Var Error        : Boolean;
                                 Var MessageError : String;
                                 Execute          : Boolean = False) : String;Overload;Override;
  Function InsertMySQLReturnID  (SQL              : String;
                                 Var Error        : Boolean;
                                 Var MessageError : String) : Integer;Overload;Override;
  Function InsertMySQLReturnID  (SQL              : String;
                                 Params           : TDWParams;
                                 Var Error        : Boolean;
                                 Var MessageError : String) : Integer;Overload;Override;
  Procedure ExecuteProcedure    (ProcName         : String;
                                 Params           : TDWParams;
                                 Var Error        : Boolean;
                                 Var MessageError : String);Override;
  Procedure ExecuteProcedurePure(ProcName         : String;
                                 Var Error        : Boolean;
                                 Var MessageError : String);Override;
  Function  OpenDatasets        (DatasetsLine     : String;
                                 Var Error        : Boolean;
                                 Var MessageError : String) : TJSONValue;Override;
  Procedure Close;Override;
  Class Procedure CreateConnection(Const ConnectionDefs : TConnectionDefs;
                                   Var Connection       : TObject);      Override;
  Procedure PrepareConnection     (Var ConnectionDefs : TConnectionDefs);Override;
 Published
  Property Connection : TZConnection Read GetConnection Write SetConnection;
End;



Procedure Register;

implementation

{$IFNDEF FPC}{$if CompilerVersion < 21}
{$R .\Package\D7\RESTDWDriverZEOS.dcr}
{$IFEND}{$ENDIF}

Uses uDWJSONTools;

Procedure Register;
Begin
 RegisterComponents('REST Dataware - CORE - Drivers', [TRESTDWDriverZeos]);
End;

Procedure TRESTDWDriverZeos.ApplyUpdates_MassiveCache(MassiveCache     : String;
                                                    Var Error        : Boolean;
                                                    Var MessageError : String);
Var
 vTempQuery     : TZQuery;
 vStringStream  : TMemoryStream;
 bPrimaryKeys   : TStringList;
 vFieldType     : TFieldType;
 vMassiveLine   : Boolean;
 Function GetParamIndex(Params : TParams; ParamName : String) : Integer;
 Var
  I : Integer;
 Begin
  Result := -1;
  For I := 0 To Params.Count -1 Do
   Begin
    If UpperCase(Params[I].Name) = UpperCase(ParamName) Then
     Begin
      Result := I;
      Break;
     End;
   End;
 End;
 Function LoadMassive(Massive : String; Var Query : TZQuery) : Boolean;
 Var
  MassiveDataset : TMassiveDatasetBuffer;
  A,    X        : Integer;
  bJsonArray     : udwjson.TJsonArray;
  Procedure PrepareData(Var Query      : TZQuery;
                        MassiveDataset : TMassiveDatasetBuffer;
                        Var vError     : Boolean;
                        Var ErrorMSG   : String);
  Var
   vLineSQL,
   vFields,
   vParamsSQL : String;
   I          : Integer;
   Procedure SetUpdateBuffer;
   Var
    X : Integer;
   Begin
    If I = 0 Then
     Begin
      bPrimaryKeys := MassiveDataset.PrimaryKeys;
      Try
       For X := 0 To bPrimaryKeys.Count -1 Do
        Begin
         If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                                                                       ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                                                                       ftString,    ftWideString]    Then
          Begin
           If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).Size > 0 Then
            Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).Value := Copy(MassiveDataset.AtualRec.PrimaryValues[X].Value, 1, Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).Size)
           Else
            Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).Value := MassiveDataset.AtualRec.PrimaryValues[X].Value;
          End
         Else
          Begin
           If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftUnknown] Then
            Begin
             If Not (ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(bPrimaryKeys[X]).FieldType) in [ftUnknown]) Then
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType := ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(bPrimaryKeys[X]).FieldType)
             Else
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType := ftString;
            End;
           If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftInteger, ftSmallInt, ftWord,
                                                                        {$IFNDEF FPC}{$IF CompilerVersion >= 21}ftLongWord,{$IFEND}{$ENDIF}
                                                                        ftLargeint] Then
            Begin
             If Trim(MassiveDataset.AtualRec.PrimaryValues[X].Value) <> '' Then
              Begin
                {$IFNDEF FPC}
                {$IF CompilerVersion < 21}
                If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType = ftSmallInt Then
                begin
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsSmallInt := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                end
                else
                begin
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsInteger  := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                end;
                {$ELSE}
                // Alterado por: Alexandre Magno - 04/11/2017
                If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftLargeint
                                                                              {$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                begin
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsLargeInt := StrToInt64(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                end
                else If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType = ftSmallInt Then
                begin
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsSmallInt := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                end
                Else
                begin
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsInteger  := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                end;
                {$IFEND}
                {$ELSE}
                If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftLargeint
                                                                              {$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                begin
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsLargeInt := StrToInt64(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                end
                else If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType = ftSmallInt Then
                begin
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsSmallInt := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                end
                Else
                begin
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsInteger  := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                end;
                {$ENDIF}
              End;
            End
           Else If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftFloat,   ftCurrency, {$IFNDEF FPC}{$IF CompilerVersion >= 21}ftSingle, {$IFEND}{$ENDIF}ftBCD] Then
            Begin
             If Trim(MassiveDataset.AtualRec.PrimaryValues[X].Value) <> '' Then
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsFloat  := StrToFloat(BuildFloatString(MassiveDataset.AtualRec.PrimaryValues[X].Value));
            End
           Else If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
            Begin
             If Trim(MassiveDataset.AtualRec.PrimaryValues[X].Value) <> '' Then
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsDateTime  := UnixToDateTime(StrToInt64(MassiveDataset.AtualRec.PrimaryValues[X].Value))
             Else
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsDateTime  := Null;
            End  //Tratar Blobs de Parametros...
           Else If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftBytes, ftVarBytes, ftBlob,
                                                                              ftGraphic, ftOraBlob, ftOraClob,
                                                                              ftMemo {$IFNDEF FPC}
                                                                                      {$IF CompilerVersion > 21}
                                                                                       , ftWideMemo
                                                                                      {$IFEND}
                                                                                     {$ENDIF}] Then
            Begin
             vStringStream := TMemoryStream.Create;
             Try
              MassiveDataset.AtualRec.PrimaryValues[X].SaveToStream(vStringStream);
              vStringStream.Position := 0;
              If vStringStream.Size > 0 Then
               Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).LoadFromStream(vStringStream, ftBlob);
             Finally
              FreeAndNil(vStringStream);
             End;
            End
           Else
            Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).Value := MassiveDataset.AtualRec.PrimaryValues[X].Value;
          End;
        End;
       Finally
        FreeAndNil(bPrimaryKeys);
       End;
      End;
    If Query.Params[I].DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                          ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                          ftString,    ftWideString]    Then
     Begin
      If Query.Params[I].Size > 0 Then
       Query.Params[I].Value := Copy(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value, 1, Query.Params[I].Size)
      Else
       Query.Params[I].Value := MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value;
     End
    Else
     Begin
      If Query.Params[I].DataType in [ftUnknown] Then
       Begin
        If Not (ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).FieldType) in [ftUnknown]) Then
         Query.Params[I].DataType := ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).FieldType)
        Else
         Query.Params[I].DataType := ftString;
       End;
      If Query.Params[I].DataType in [ftInteger, ftSmallInt, ftWord, ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
       Begin
        If (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> '') And
           (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
         Begin
          {$IFNDEF FPC}
          {$IF CompilerVersion < 21}
           If Query.Params[I].DataType = ftSmallInt Then
           begin
             Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
           end
           else
           begin
             Query.Params[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
           end;
          {$ELSE}
           // Alterado por: Alexandre Magno - 04/11/2017
           If Query.Params[I].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
           begin
             Query.Params[I].AsLargeInt := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
           end
           else If Query.Params[I].DataType = ftSmallInt Then
           begin
             Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
           end
           Else
           begin
             Query.Params[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
           end;
           {$IFEND}
           {$ELSE}
            // Alterado por: Alexandre Magno - 04/11/2017
            If Query.Params[I].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
            begin
              Query.Params[I].AsLargeInt := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
            end
            else If Query.Params[I].DataType = ftSmallInt Then
            begin
              Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
            end
            Else
            begin
              Query.Params[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
            end;
          {$ENDIF}
         End;
       End
      Else If Query.Params[I].DataType in [ftFloat,   ftCurrency, {$IFNDEF FPC}{$IF CompilerVersion >= 21}ftSingle, {$IFEND}{$ENDIF}ftBCD] Then
       Begin
        If (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> '') And
           (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
         Query.Params[I].AsFloat  := StrToFloat(BuildFloatString(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value));
       End
      Else If Query.Params[I].DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
       Begin
        If (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> '') And
           (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
         Query.Params[I].AsDateTime  := UnixToDateTime(StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value))
        Else
         Query.Params[I].Clear;
       End
      Else If Query.Params[I].DataType in [ftMemo {$IFNDEF FPC}
                                                   {$IF CompilerVersion > 21}
                                                    , ftWideMemo
                                                   {$IFEND}
                                                  {$ENDIF}] Then   //altera��o necessaria para trabalhar com campo memo em sqlserver
      Begin
         If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value <> 'null') And
            (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value <> '') Then
          Begin
            Query.Params[I].AsString := HexStringToString(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);;
          End
         Else
          Query.Params[I].Clear;
      end  //Tratar Blobs de Parametros...
      Else If Query.Params[I].DataType in [ftBytes, ftVarBytes, ftBlob,
                                           ftGraphic, ftOraBlob, ftOraClob  ] Then
       Begin
        vStringStream := TMemoryStream.Create;
        Try
         If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value <> 'null') And
            (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value <> '') Then
          Begin
           MassiveDataset.Fields.FieldByName(Query.Params[I].Name).SaveToStream(vStringStream);
           vStringStream.Position := 0;
           Query.Params[I].LoadFromStream(vStringStream, ftBlob);
          End
         Else
          Query.Params[I].Clear;
        Finally
         FreeAndNil(vStringStream);
        End;
       End
      Else
       Query.Params[I].Value := MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value;
     End;
   End;
  Begin
   Query.Close;
   Query.SQL.Clear;
   vFields    := '';
   vParamsSQL := vFields;
   Case MassiveDataset.MassiveMode Of
    mmInsert : Begin
                vLineSQL := Format('INSERT INTO %s ', [MassiveDataset.TableName + ' (%s) VALUES (%s)']);
                For I := 0 To MassiveDataset.Fields.Count -1 Do
                 Begin
                  If (MassiveDataset.Fields.Items[I].AutoGenerateValue) And
                     (MassiveDataset.AtualRec.MassiveMode = mmInsert) Then
                   Continue;
                  If vFields = '' Then
                   Begin
                    vFields     := MassiveDataset.Fields.Items[I].FieldName;
                    vParamsSQL  := ':' + MassiveDataset.Fields.Items[I].FieldName;
                   End
                  Else
                   Begin
                    vFields     := vFields    + ', '  + MassiveDataset.Fields.Items[I].FieldName;
                    vParamsSQL  := vParamsSQL + ', :' + MassiveDataset.Fields.Items[I].FieldName;
                   End;
                 End;
                vLineSQL := Format(vLineSQL, [vFields, vParamsSQL]);
               End;
    mmUpdate : Begin
                vLineSQL := Format('UPDATE %s ',      [MassiveDataset.TableName + ' SET %s %s']);
                vFields  := '';
                For I := 0 To MassiveDataset.AtualRec.UpdateFieldChanges.Count -1 Do
                 Begin
                  If Lowercase(MassiveDataset.AtualRec.UpdateFieldChanges[I]) <> Lowercase(DWFieldBookmark) Then
                   Begin
                    If vFields = '' Then
                     vFields  := MassiveDataset.AtualRec.UpdateFieldChanges[I] + ' = :' + MassiveDataset.AtualRec.UpdateFieldChanges[I]
                    Else
                     vFields  := vFields + ', ' + MassiveDataset.AtualRec.UpdateFieldChanges[I] + ' = :' + MassiveDataset.AtualRec.UpdateFieldChanges[I];
                   End;
                 End;
                bPrimaryKeys := MassiveDataset.PrimaryKeys;
                Try
                 For I := 0 To bPrimaryKeys.Count -1 Do
                  Begin
                   If I = 0 Then
                    vParamsSQL := 'WHERE ' + bPrimaryKeys[I] + ' = :DWKEY_' + bPrimaryKeys[I]
                   Else
                    vParamsSQL := vParamsSQL + ' AND ' + bPrimaryKeys[I] + ' = :DWKEY_' + bPrimaryKeys[I]
                  End;
                Finally
                 FreeAndNil(bPrimaryKeys);
                End;
                vLineSQL := Format(vLineSQL, [vFields, vParamsSQL]);
               End;
    mmDelete : Begin
                vLineSQL := Format('DELETE FROM %s ', [MassiveDataset.TableName + ' %s ']);
                bPrimaryKeys := MassiveDataset.PrimaryKeys;
                Try
                 For I := 0 To bPrimaryKeys.Count -1 Do
                  Begin
                   If I = 0 Then
                    vParamsSQL := 'WHERE ' + bPrimaryKeys[I] + ' = :' + bPrimaryKeys[I]
                   Else
                    vParamsSQL := vParamsSQL + ' AND ' + bPrimaryKeys[I] + ' = :' + bPrimaryKeys[I]
                  End;
                Finally
                 FreeAndNil(bPrimaryKeys);
                End;
                vLineSQL := Format(vLineSQL, [vParamsSQL]);
               End;
   End;
   Query.SQL.Add(vLineSQL);
   //Params
   For I := 0 To Query.Params.Count -1 Do
    Begin
     If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name) <> Nil) Then
      Begin
       vFieldType := ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).FieldType);
       If MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value = 'null' Then
        Begin
         If vFieldType = ftUnknown Then
          Query.Params[I].DataType := ftString
         Else
          Query.Params[I].DataType := vFieldType;
         Query.Params[I].Clear;
        End;
       If MassiveDataset.MassiveMode <> mmUpdate Then
        Begin
         If Query.Params[I].DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                               ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                               ftString,    ftWideString]    Then
          Begin
           If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value <> Null) And
              (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
            Begin
             If Query.Params[I].Size > 0 Then
              Query.Params[I].Value := Copy(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value, 1, Query.Params[I].Size)
             Else
              Query.Params[I].Value := MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value;
            End
           Else
            Query.Params[I].Clear;
          End
         Else
          Begin
           If Query.Params[I].DataType in [ftUnknown] Then
            Begin
             If Not (ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).FieldType) in [ftUnknown]) Then
              Query.Params[I].DataType := ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).FieldType)
             Else
              Query.Params[I].DataType := ftString;
            End;
           If Query.Params[I].DataType in [ftInteger, ftSmallInt, ftWord, ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
            Begin
             If (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> '') And
                (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
              Begin
               If MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value <> Null Then
                Begin
                 {$IFNDEF FPC}
                  {$IF CompilerVersion < 21}
                   If Query.Params[I].DataType = ftSmallInt Then
                   begin
                    Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
                   end
                   else
                   begin
                    Query.Params[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
                   end;
                  {$ELSE}
                   If Query.Params[I].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                    Query.Params[I].AsLargeInt := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value)
                   Else If Query.Params[I].DataType = ftSmallInt Then
                    Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value)
                   Else
                    Query.Params[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
                  {$IFEND}
                  {$ELSE}
                   If Query.Params[I].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                    Query.Params[I].AsLargeInt := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value)
                   Else If Query.Params[I].DataType = ftSmallInt Then
                    Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value)
                   Else
                    Query.Params[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
                  {$ENDIF}
                End;
              End
             Else
              Query.Params[I].Clear;
            End
           Else If Query.Params[I].DataType in [ftFloat,   ftCurrency, ftBCD{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftSingle{$IFEND}{$ENDIF}] Then
            Begin
             If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value <> Null) And
                (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
              Query.Params[I].AsFloat  := StrToFloat(BuildFloatString(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value))
             Else
              Query.Params[I].Clear;
            End
           Else If Query.Params[I].DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
            Begin
             If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value <> Null) And
                (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
              Query.Params[I].AsDateTime  := UnixToDateTime(StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value))
             Else
              Query.Params[I].Clear;
            End  //Tratar Blobs de Parametros...
           Else If Query.Params[I].DataType in [ftBytes, ftVarBytes, ftBlob,
                                                ftGraphic, ftOraBlob, ftOraClob,
                                                ftMemo {$IFNDEF FPC}
                                                        {$IF CompilerVersion > 21}
                                                         , ftWideMemo
                                                        {$IFEND}
                                                       {$ENDIF}] Then
            Begin
             vStringStream := TMemoryStream.Create;
             Try
              If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value <> 'null') And
                 (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value <> '') Then
               Begin
                MassiveDataset.Fields.FieldByName(Query.Params[I].Name).SaveToStream(vStringStream);
                vStringStream.Position := 0;
                Query.Params[I].LoadFromStream(vStringStream, ftBlob);
               End
              Else
               Query.Params[I].Clear;
             Finally
              FreeAndNil(vStringStream);
             End;
            End
           Else If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value <> Null) And
                   (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
            Query.Params[I].Value := MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value
           Else
            Query.Params[I].Clear;
          End;
        End
       Else //Update
        Begin
         SetUpdateBuffer;
        End;
      End
     Else
      Begin
       If I = 0 Then
        SetUpdateBuffer;
      End;
    End;
  End;
 Begin
  MassiveDataset := TMassiveDatasetBuffer.Create(Nil);
  bJsonArray     := udwjson.TJsonArray.Create(MassiveCache);
  Result         := False;
  For x := 0 To bJsonArray.length -1 Do
   Begin
    If Not vZConnection.InTransaction Then
     Begin
      vZConnection.StartTransaction;
      If Self.Owner      Is TServerMethodDataModule Then
       Begin
        If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveAfterStartTransaction) Then
         TServerMethodDataModule(Self.Owner).OnMassiveAfterStartTransaction(MassiveDataset);
       End
      Else If Self.Owner Is TServerMethods Then
       Begin
        If Assigned(TServerMethods(Self.Owner).OnMassiveAfterStartTransaction) Then
         TServerMethods(Self.Owner).OnMassiveAfterStartTransaction(MassiveDataset);
       End;
     End;
    Try
     MassiveDataset.FromJSON(bJsonArray.get(X).toString);
     MassiveDataset.First;
     If Self.Owner      Is TServerMethodDataModule Then
      Begin
       If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveBegin) Then
        TServerMethodDataModule(Self.Owner).OnMassiveBegin(MassiveDataset);
      End
     Else If Self.Owner Is TServerMethods Then
      Begin
       If Assigned(TServerMethods(Self.Owner).OnMassiveBegin) Then
       TServerMethods(Self.Owner).OnMassiveBegin(MassiveDataset);
      End;
     For A := 1 To MassiveDataset.RecordCount Do
      Begin
       Query.SQL.Clear;
       If Self.Owner      Is TServerMethodDataModule Then
        Begin
         vMassiveLine := False;
         If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveProcess) Then
          Begin
           TServerMethodDataModule(Self.Owner).OnMassiveProcess(MassiveDataset, vMassiveLine);
           If vMassiveLine Then
            Begin
             MassiveDataset.Next;
             Continue;
            End;
          End;
        End
       Else If Self.Owner Is TServerMethods Then
        Begin
         vMassiveLine := False;
         If Assigned(TServerMethods(Self.Owner).OnMassiveProcess) Then
          Begin
           TServerMethods(Self.Owner).OnMassiveProcess(MassiveDataset, vMassiveLine);
           If vMassiveLine Then
            Begin
             MassiveDataset.Next;
             Continue;
            End;
          End;
        End;
       PrepareData(Query, MassiveDataset, Error, MessageError);
       Try
        Query.ExecSQL;
       Except
        On E : Exception do
         Begin
          Error  := True;
          Result := False;
          If vZConnection.InTransaction Then
           vZConnection.Rollback;
          MessageError := E.Message;
          Break;
         End;
       End;
       MassiveDataset.Next;
      End;
    Finally
     Query.SQL.Clear;
    End;
   End;
  If Not Error Then
   Begin
    Try
     Result        := True;
     If vZConnection.InTransaction Then
      Begin
       If Self.Owner      Is TServerMethodDataModule Then
        Begin
         If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveAfterBeforeCommit) Then
          TServerMethodDataModule(Self.Owner).OnMassiveAfterBeforeCommit(MassiveDataset);
        End
       Else If Self.Owner Is TServerMethods Then
        Begin
         If Assigned(TServerMethods(Self.Owner).OnMassiveAfterBeforeCommit) Then
          TServerMethods(Self.Owner).OnMassiveAfterBeforeCommit(MassiveDataset);
        End;
       vZConnection.Commit;
       If Self.Owner      Is TServerMethodDataModule Then
        Begin
         If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveAfterAfterCommit) Then
          TServerMethodDataModule(Self.Owner).OnMassiveAfterAfterCommit(MassiveDataset);
        End
       Else If Self.Owner Is TServerMethods Then
        Begin
         If Assigned(TServerMethods(Self.Owner).OnMassiveAfterAfterCommit) Then
          TServerMethods(Self.Owner).OnMassiveAfterAfterCommit(MassiveDataset);
        End;
      End;
    Except
     On E : Exception do
      Begin
       Error  := True;
       Result := False;
       If vZConnection.InTransaction Then
        vZConnection.Rollback;
       MessageError := E.Message;
      End;
    End;
   End;
  If Self.Owner      Is TServerMethodDataModule Then
   Begin
    If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveEnd) Then
     TServerMethodDataModule(Self.Owner).OnMassiveEnd(MassiveDataset);
   End
  Else If Self.Owner Is TServerMethods Then
   Begin
    If Assigned(TServerMethods(Self.Owner).OnMassiveEnd) Then
     TServerMethods(Self.Owner).OnMassiveEnd(MassiveDataset);
   End;
  FreeAndNil(MassiveDataset);
  FreeAndNil(bJsonArray);
 End;
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}
 Try
  Error      := False;
  vTempQuery := TZQuery.Create(Owner);
  If Not vZConnection.Connected Then
   vZConnection.Connected := True;
  vTempQuery.Connection   := vZConnection;
  vTempQuery.SQL.Clear;
  LoadMassive(MassiveCache, vTempQuery);
 Finally
  vTempQuery.Close;
  vTempQuery.Free;
 End;
End;

Procedure TRESTDWDriverZeos.Close;
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}
 If Connection <> Nil Then
  Connection.Disconnect;
End;

Class Procedure TRESTDWDriverZeos.CreateConnection(Const ConnectionDefs : TConnectionDefs;
                                                   Var Connection       : TObject);
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}

End;

function TRESTDWDriverZeos.ExecuteCommand(SQL              : String;
                                        Params           : TDWParams;
                                        Var Error        : Boolean;
                                        Var MessageError : String;
                                        Execute          : Boolean) : String;
Var
 vTempQuery    : TZQuery;
 A, I          : Integer;
 vParamName    : String;
 vStringStream : TMemoryStream;
 aResult       : TJSONValue;
 Function GetParamIndex(Params : TParams; ParamName : String) : Integer;
 Var
  I : Integer;
 Begin
  Result := -1;
  For I := 0 To Params.Count -1 Do
   Begin
    If UpperCase(Params[I].Name) = UpperCase(ParamName) Then
     Begin
      Result := I;
      Break;
     End;
   End;
 End;
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}
 Error  := False;
 aResult := TJSONValue.Create;
 vTempQuery               := TZQuery.Create(Owner);
 Try
  vTempQuery.Connection   := vZConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(SQL);
  If Params <> Nil Then
  Begin
   If vTempQuery.ParamCheck then
    Begin
      For I := 0 To Params.Count -1 Do
       Begin
        If vTempQuery.Params.Count > I Then
         Begin
          vParamName := Copy(StringReplace(Params[I].ParamName, ',', '', []), 1, Length(Params[I].ParamName));
          A          := GetParamIndex(vTempQuery.Params, vParamName);
          If A > -1 Then//vTempQuery.ParamByName(vParamName) <> Nil Then
           Begin
            If vTempQuery.Params[A].DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                                                  ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                                                  ftString,    ftWideString]    Then
             Begin
              If vTempQuery.Params[A].Size > 0 Then
               vTempQuery.Params[A].Value := Copy(Params[I].Value, 1, vTempQuery.Params[A].Size)
              Else
               vTempQuery.Params[A].Value := Params[I].Value;
             End
            Else
             Begin
              If vTempQuery.Params[A].DataType in [ftUnknown] Then
               Begin
                If Not (ObjectValueToFieldType(Params[I].ObjectValue) in [ftUnknown]) Then
                 vTempQuery.Params[A].DataType := ObjectValueToFieldType(Params[I].ObjectValue)
                Else
                 vTempQuery.Params[A].DataType := ftString;
               End;
              If vTempQuery.Params[A].DataType in [ftInteger, ftSmallInt, ftWord, ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
               Begin
                If (Params[I].Value <> Null) Then
                 Begin
                  {$IFNDEF FPC}
                  {$IF CompilerVersion < 21}
                  If vTempQuery.Params[A].DataType = ftSmallInt Then
                  begin
                   vTempQuery.Params[A].AsSmallInt := StrToInt(Params[I].Value);
                  end
                  Else
                  begin
                   vTempQuery.Params[A].AsInteger  := StrToInt64(Params[I].Value);
                  end;
                  {$ELSE}
                  If vTempQuery.Params[A].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                   vTempQuery.Params[A].AsLargeInt := StrToInt64(Params[I].Value)
                  Else If vTempQuery.Params[A].DataType = ftSmallInt Then
                   vTempQuery.Params[A].AsSmallInt := StrToInt(Params[I].Value)
                  Else
                   vTempQuery.Params[A].AsInteger  := StrToInt(Params[I].Value);
                  {$IFEND}
                  {$ELSE}
                  If vTempQuery.Params[A].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                   vTempQuery.Params[A].AsLargeInt := StrToInt64(Params[I].Value)
                  Else If vTempQuery.Params[A].DataType = ftSmallInt Then
                   vTempQuery.Params[A].AsSmallInt := StrToInt(Params[I].Value)
                  Else
                   vTempQuery.Params[A].AsInteger  := StrToInt(Params[I].Value);
                  {$ENDIF}
                 End
                Else
                 vTempQuery.Params[A].Clear;
               End
              Else If vTempQuery.Params[A].DataType in [ftFloat,   ftCurrency, ftBCD{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftSingle{$IFEND}{$ENDIF}] Then
               Begin
                If (Params[I].Value <> Null) Then
                 vTempQuery.Params[A].AsFloat  := StrToFloat(BuildFloatString(Params[I].Value))
                Else
                 vTempQuery.Params[A].Clear;
               End
              Else If vTempQuery.Params[A].DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
               Begin
                If (Params[I].Value <> Null) Then
                 vTempQuery.Params[A].AsDateTime  := Params[I].AsDateTime
                Else
                 vTempQuery.Params[A].Clear;
               End  //Tratar Blobs de Parametros...
              Else If vTempQuery.Params[A].DataType in [ftBytes, ftVarBytes, ftBlob,
                                                        ftGraphic, ftOraBlob, ftOraClob,
                                                        ftMemo {$IFNDEF FPC}
                                                                {$IF CompilerVersion > 21}
                                                                 , ftWideMemo
                                                                {$IFEND}
                                                               {$ENDIF}] Then
               Begin
                vStringStream := TMemoryStream.Create;
                Try
                 Params[I].SaveToStream(vStringStream);
                 vStringStream.Position := 0;
                 If vStringStream.Size > 0 Then
                  vTempQuery.Params[A].LoadFromStream(vStringStream, ftBlob);
                Finally
                 FreeAndNil(vStringStream);
                End;
               End
              Else If vTempQuery.Params[A].DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                                                        ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                                                        ftString,    ftWideString]    Then
               Begin
                If (Trim(Params[I].Value) <> '') Then
                 vTempQuery.Params[A].AsString := Params[I].Value
                Else
                 vTempQuery.Params[A].Clear;
               End
              Else
               vTempQuery.Params[A].Value    := Params[I].Value;
             End;
           End;
         End
        Else
         Break;
       End;
    End
   Else
    Begin
     For I := 0 To Params.Count -1 Do
      begin
       {$IFNDEF FPC}
        {$if CompilerVersion < 21}
          With vTempQuery.Params.Add do
        {$ELSE}
          With vTempQuery.Params.AddParameter do
        {$IFEND}
       {$ELSE}
       With vTempQuery.Params.Add do
       {$ENDIF}
        Begin
         vParamName := Copy(StringReplace(Params[I].ParamName, ',', '', []), 1, Length(Params[I].ParamName));
         Name := vParamName;
         {$IFNDEF FPC}
          {$IF CompilerVersion >= 21}
          ParamType := ptInput;
           If Not (ObjectValueToFieldType(Params[I].ObjectValue) in [ftUnknown]) Then
            DataType := ObjectValueToFieldType(Params[I].ObjectValue)
           Else
            DataType := ftString;
          {$IFEND}
         {$ENDIF}
         If vTempQuery.Params[I].DataType in [ftInteger, ftSmallInt, ftWord, ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
          Begin
           If (Params[I].Value <> Null) Then
            Begin
             {$IFNDEF FPC}
              {$IF CompilerVersion < 21}
             If vTempQuery.Params[I].DataType = ftSmallInt Then
             begin
              vTempQuery.Params[I].AsSmallInt := StrToInt(Params[I].Value);
             end
             Else
             begin
              vTempQuery.Params[I].AsInteger  := StrToInt64(Params[I].Value);
             end;
              {$ELSE}
              // Alterado por: Alexandre Magno - 04/11/2017
             If vTempQuery.Params[I].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
             begin
              vTempQuery.Params[I].AsLargeInt := StrToInt64(Params[I].Value);
             end
             else If vTempQuery.Params[I].DataType = ftSmallInt Then
             begin
              vTempQuery.Params[I].AsSmallInt := StrToInt(Params[I].Value);
             end
             Else
             begin
              vTempQuery.Params[I].AsInteger  := StrToInt(Params[I].Value);
             end;
             {$IFEND}
             {$ELSE}
             // Alterado por: Alexandre Magno - 04/11/2017
            If vTempQuery.Params[I].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
            begin
             vTempQuery.Params[I].AsLargeInt := StrToInt64(Params[I].Value);
            end
            else If vTempQuery.Params[I].DataType = ftSmallInt Then
            begin
             vTempQuery.Params[I].AsSmallInt := StrToInt(Params[I].Value);
            end
            Else
            begin
             vTempQuery.Params[I].AsInteger  := StrToInt(Params[I].Value);
            end;
            {$ENDIF}
            End
           Else
            vTempQuery.Params[I].Clear;
          End
          Else If vTempQuery.Params[I].DataType in [ftFloat,   ftCurrency, ftBCD{$IFNDEF FPC}{$if CompilerVersion >= 21}, ftSingle{$IFEND}{$ENDIF}] Then
           Begin
            If (Params[I].Value <> Null) Then
             vTempQuery.Params[I].AsFloat  := StrToFloat(BuildFloatString(Params[I].Value))
            Else
             vTempQuery.Params[I].Clear;
           End
          Else If vTempQuery.Params[I].DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
           Begin
            If (Params[I].Value <> Null) Then
             vTempQuery.Params[I].AsDateTime  := Params[I].AsDateTime
            Else
             vTempQuery.Params[I].Clear;
           End  //Tratar Blobs de Parametros...
          Else If vTempQuery.Params[I].DataType in [ftBytes, ftVarBytes, ftBlob,
                                                    ftGraphic, ftOraBlob, ftOraClob,
                                                    ftMemo {$IFNDEF FPC}
                                                            {$IF CompilerVersion > 21}
                                                             , ftWideMemo
                                                            {$IFEND}
                                                           {$ENDIF}] Then
           Begin
            vStringStream := TMemoryStream.Create;
            Try
             Params[I].SaveToStream(vStringStream);
             vStringStream.Position := 0;
             If vStringStream.Size > 0 Then
              vTempQuery.Params[I].LoadFromStream(vStringStream, ftBlob);
            Finally
             FreeAndNil(vStringStream);
            End;
           End
          Else If vTempQuery.Params[I].DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                                                    ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                                                    ftString,    ftWideString]    Then
           Begin
            If (Params[I].Value <> '') And
               (Params[I].Value <> Null) Then
             vTempQuery.Params[I].AsString := Params[I].Value
            Else
             vTempQuery.Params[I].Clear;
           End
          Else
           vTempQuery.Params[I].Value    := Params[I].Value;
        End;
      End;
    End;
  End;
  If Not Execute Then
   Begin
    vTempQuery.Active := True;
    If aResult = Nil Then
     aResult := TJSONValue.Create;
    aResult.Encoded         := EncodeStringsJSON;
    aResult.Encoding        := Encoding;
    {$IFDEF FPC}
     aResult.DatabaseCharSet := DatabaseCharSet;
    {$ENDIF}
    Try
     aResult.LoadFromDataset('RESULTDATA', vTempQuery, EncodeStringsJSON);
     Result := aResult.ToJson;
    Finally
    End;
   End
  Else
   Begin
    vTempQuery.ExecSQL;
    If aResult = Nil Then
     aResult := TJSONValue.Create;
    aResult.Encoded         := True;
    aResult.Encoding        := Encoding;
    {$IFDEF FPC}
     aResult.DatabaseCharSet := DatabaseCharSet;
    {$ENDIF}
    vZConnection.Commit;
    aResult.SetValue('COMMANDOK');
    Result := aResult.ToJSON;
   End;
 Except
  On E : Exception do
   Begin
    Try
     Error        := True;
     MessageError := E.Message;
     If aResult = Nil Then
      aResult := TJSONValue.Create;
     aResult.Encoded         := True;
     aResult.Encoding        := Encoding;
     {$IFDEF FPC}
      aResult.DatabaseCharSet := DatabaseCharSet;
     {$ENDIF}
     aResult.SetValue(GetPairJSON('NOK', MessageError));
     Result := aResult.ToJson;
     vZConnection.Rollback;
    Except
    End;
   End;
 End;
 If Assigned(aResult) Then
  FreeAndNil(aResult);
 vTempQuery.Close;
 vTempQuery.Free;
End;

procedure TRESTDWDriverZeos.ExecuteProcedure(ProcName         : String;
                                           Params           : TDWParams;
                                           Var Error        : Boolean;
                                           Var MessageError : String);
Var
 A, I            : Integer;
 vParamName      : String;
 vTempStoredProc : TZStoredProc;
 Function GetParamIndex(Params : TParams; ParamName : String) : Integer;
 Var
  I : Integer;
 Begin
  Result := -1;
  For I := 0 To Params.Count -1 Do
   Begin
    If UpperCase(Params[I].Name) = UpperCase(ParamName) Then
     Begin
      Result := I;
      Break;
     End;
   End;
 End;
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}
 Error  := False;
 vTempStoredProc                               := TZStoredProc.Create(Owner);
 Try
  vTempStoredProc.Connection                   := vZConnection;
  If Params <> Nil Then
   Begin
    Try
     vTempStoredProc.Prepare;
    Except
    End;
    For I := 0 To Params.Count -1 Do
     Begin
      If vTempStoredProc.Params.Count > I Then
       Begin
        vParamName := Copy(StringReplace(Params[I].ParamName, ',', '', []), 1, Length(Params[I].ParamName));
        A          := GetParamIndex(vTempStoredProc.Params, vParamName);
        If A > -1 Then//vTempQuery.ParamByName(vParamName) <> Nil Then
         Begin
          If vTempStoredProc.Params[A].DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                                                    ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                                                    ftString,    ftWideString]    Then
           Begin
            If vTempStoredProc.Params[A].Size > 0 Then
             vTempStoredProc.Params[A].Value := Copy(Params[I].Value, 1, vTempStoredProc.Params[A].Size)
            Else
             vTempStoredProc.Params[A].Value := Params[I].Value;
           End
          Else
           Begin
            If vTempStoredProc.Params[A].DataType in [ftUnknown] Then
             vTempStoredProc.Params[A].DataType := ObjectValueToFieldType(Params[I].ObjectValue);
            vTempStoredProc.Params[A].Value    := Params[I].Value;
           End;
         End;
       End
      Else
       Break;
     End;
   End;
  vTempStoredProc.ExecProc;
  vZConnection.Commit;
 Except
  On E : Exception do
   Begin
    Try
     vZConnection.Rollback;
    Except
    End;
    Error := True;
    MessageError := E.Message;
   End;
 End;
 vTempStoredProc.Free;
End;

procedure TRESTDWDriverZeos.ExecuteProcedurePure(ProcName         : String;
                                               Var Error        : Boolean;
                                               Var MessageError : String);
Var
 vTempStoredProc : TZStoredProc;
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}
 Error                                         := False;
 vTempStoredProc                               := TZStoredProc.Create(Owner);
 Try
  If Not vZConnection.Connected Then
   vZConnection.Connected                     := True;
  vTempStoredProc.Connection                   := vZConnection;
  vTempStoredProc.ExecProc;
  vZConnection.Commit;
 Except
  On E : Exception do
   Begin
    Try
     vZConnection.Rollback;
    Except
    End;
    Error := True;
    MessageError := E.Message;
   End;
 End;
 vTempStoredProc.Free;
End;

Function TRESTDWDriverZeos.ApplyUpdates(Massive,
                                      SQL               : String;
                                      Params            : TDWParams;
                                      Var Error         : Boolean;
                                      Var MessageError  : String) : TJSONValue;
Var
 vTempQuery     : TZQuery;
 A, I           : Integer;
 vParamName     : String;
 vStringStream  : TMemoryStream;
 bPrimaryKeys   : TStringList;
 vFieldType     : TFieldType;
 vMassiveLine   : Boolean;
 Function GetParamIndex(Params : TParams; ParamName : String) : Integer;
 Var
  I : Integer;
 Begin
  Result := -1;
  For I := 0 To Params.Count -1 Do
   Begin
    If UpperCase(Params[I].Name) = UpperCase(ParamName) Then
     Begin
      Result := I;
      Break;
     End;
   End;
 End;
 Function LoadMassive(Massive : String; Var Query : TZQuery) : Boolean;
 Var
  MassiveDataset : TMassiveDatasetBuffer;
  A, B           : Integer;
  Procedure PrepareData(Var Query      : TZQuery;
                        MassiveDataset : TMassiveDatasetBuffer;
                        Var vError     : Boolean;
                        Var ErrorMSG   : String);
  Var
   vLineSQL,
   vFields,
   vParamsSQL : String;
   I          : Integer;
   Procedure SetUpdateBuffer;
   Var
    X : Integer;
   Begin
    If I = 0 Then
     Begin
      bPrimaryKeys := MassiveDataset.PrimaryKeys;
      Try
       For X := 0 To bPrimaryKeys.Count -1 Do
        Begin
         If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                                                                       ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                                                                       ftString,    ftWideString]    Then
          Begin
           If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).Size > 0 Then
            Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).Value := Copy(MassiveDataset.AtualRec.PrimaryValues[X].Value, 1, Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).Size)
           Else
            Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).Value := MassiveDataset.AtualRec.PrimaryValues[X].Value;
          End
         Else
          Begin
           If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftUnknown] Then
            Begin
             If Not (ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(bPrimaryKeys[X]).FieldType) in [ftUnknown]) Then
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType := ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(bPrimaryKeys[X]).FieldType)
             Else
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType := ftString;
            End;
           If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftInteger, ftSmallInt, ftWord, ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
            Begin
             If Trim(MassiveDataset.AtualRec.PrimaryValues[X].Value) <> '' Then
              Begin
               {$IFNDEF FPC}
                {$IF CompilerVersion < 21}
                If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType = ftSmallInt Then
                begin
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsSmallInt := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                end
                Else
                begin
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsInteger  := StrToInt64(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                end;
                {$ELSE}
                // Alterado por: Alexandre Magno - 04/11/2017
                If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsLargeInt := StrToInt64(MassiveDataset.AtualRec.PrimaryValues[X].Value)
                else If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType = ftSmallInt Then
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsSmallInt := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value)
                Else
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsInteger  := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                {$IFEND}
                {$ELSE}
                // Alterado por: Alexandre Magno - 04/11/2017
                If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsLargeInt := StrToInt64(MassiveDataset.AtualRec.PrimaryValues[X].Value)
                else If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType = ftSmallInt Then
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsSmallInt := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value)
                Else
                  Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsInteger  := StrToInt(MassiveDataset.AtualRec.PrimaryValues[X].Value);
                {$ENDIF}
              End;
            End
           Else If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftFloat,   ftCurrency, ftBCD{$IFNDEF FPC}{$if CompilerVersion >= 21}, ftSingle{$IFEND}{$ENDIF}] Then
            Begin
             If Trim(MassiveDataset.AtualRec.PrimaryValues[X].Value) <> '' Then
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsFloat  := StrToFloat(BuildFloatString(MassiveDataset.AtualRec.PrimaryValues[X].Value));
            End
           Else If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
            Begin
             If Trim(MassiveDataset.AtualRec.PrimaryValues[X].Value) <> '' Then
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsDateTime  := UnixToDateTime(StrToInt64(MassiveDataset.AtualRec.PrimaryValues[X].Value))
             Else
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).AsDateTime  := Null;
            End  //Tratar Blobs de Parametros...
           Else If Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).DataType in [ftBytes, ftVarBytes, ftBlob,
                                                                              ftGraphic, ftOraBlob, ftOraClob,
                                                                              ftMemo {$IFNDEF FPC}
                                                                                      {$IF CompilerVersion > 21}
                                                                                       , ftWideMemo
                                                                                      {$IFEND}
                                                                                     {$ENDIF}] Then
            Begin
             vStringStream := TMemoryStream.Create;
             Try
              MassiveDataset.AtualRec.PrimaryValues[X].SaveToStream(vStringStream);
              vStringStream.Position := 0;
              Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).LoadFromStream(vStringStream, ftBlob);
             Finally
              FreeAndNil(vStringStream);
             End;
            End
           Else
            Query.ParamByName('DWKEY_' + bPrimaryKeys[X]).Value := MassiveDataset.AtualRec.PrimaryValues[X].Value;
          End;
        End;
       Finally
        FreeAndNil(bPrimaryKeys);
       End;
      End;
    If Query.Params[I].DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                          ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                          ftString,    ftWideString]    Then
     Begin
      If (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> '') And
         (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
       Begin
        If Query.Params[I].Size > 0 Then
         Query.Params[I].Value := Copy(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value, 1, Query.Params[I].Size)
        Else
         Query.Params[I].Value := MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value;
       End;
     End
    Else
     Begin
      If Query.Params[I].DataType in [ftUnknown] Then
       Begin
        If Not (ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).FieldType) in [ftUnknown]) Then
         Query.Params[I].DataType := ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).FieldType)
        Else
         Query.Params[I].DataType := ftString;
       End;
      If Query.Params[I].DataType in [ftInteger, ftSmallInt, ftWord, ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
       Begin
        If (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> '') And
           (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
         Begin
          {$IFNDEF FPC}
          {$IF CompilerVersion < 21}
           If Query.Params[I].DataType = ftSmallInt Then
           begin
             Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
           end
           Else
           begin
             Query.Params[I].AsInteger  := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
           end;
          {$ELSE}
          // Alterado por: Alexandre Magno - 04/11/2017
           If Query.Params[I].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
           begin
             Query.Params[I].AsLargeInt := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
           end
           else If Query.Params[I].DataType = ftSmallInt Then
           begin
             Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
           end
           Else
            Query.Params[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
           {$IFEND}
           {$ELSE}
           // Alterado por: Alexandre Magno - 04/11/2017
            If Query.Params[I].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
            begin
              Query.Params[I].AsLargeInt := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
            end
            else If Query.Params[I].DataType = ftSmallInt Then
            begin
              Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
            end
            Else
             Query.Params[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
          {$ENDIF}
         End
        Else
         Query.Params[I].Clear;
       End
      Else If Query.Params[I].DataType in [ftFloat,   ftCurrency, ftBCD{$IFNDEF FPC}{$if CompilerVersion >= 21}, ftSingle{$IFEND}{$ENDIF}] Then
       Begin
        If (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> '') And
           (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
         Query.Params[I].AsFloat  := StrToFloat(BuildFloatString(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value))
        Else
         Query.Params[I].Clear;
       End
      Else If Query.Params[I].DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
       Begin
        If (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> '') And
           (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
         Query.Params[I].AsDateTime  := UnixToDateTime(StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value))
        Else
         Query.Params[I].Clear;
       End  //Tratar Blobs de Parametros...
      Else If Query.Params[I].DataType in [ftBytes, ftVarBytes, ftBlob,
                                           ftGraphic, ftOraBlob, ftOraClob,
                                           ftMemo {$IFNDEF FPC}
                                                   {$IF CompilerVersion > 21}
                                                    , ftWideMemo
                                                   {$IFEND}
                                                  {$ENDIF}] Then
       Begin
        vStringStream := TMemoryStream.Create;
        Try
         If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value <> 'null') And
            (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value <> '') Then
          Begin
           MassiveDataset.Fields.FieldByName(Query.Params[I].Name).SaveToStream(vStringStream);
           vStringStream.Position := 0;
           Query.Params[I].LoadFromStream(vStringStream, ftBlob);
          End
         Else
          Query.Params[I].Clear;
        Finally
         FreeAndNil(vStringStream);
        End;
       End
      Else
       Query.Params[I].Value := MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value;
     End;
   End;
  Begin
   Query.Close;
   Query.SQL.Clear;
   vFields    := '';
   vParamsSQL := vFields;
   Case MassiveDataset.MassiveMode Of
    mmInsert : Begin
                vLineSQL := Format('INSERT INTO %s ', [MassiveDataset.TableName + ' (%s) VALUES (%s)']);
                For I := 0 To MassiveDataset.Fields.Count -1 Do
                 Begin
                  If (MassiveDataset.Fields.Items[I].AutoGenerateValue) And
                     (MassiveDataset.AtualRec.MassiveMode = mmInsert) Then
                   Continue;
                  If vFields = '' Then
                   Begin
                    vFields     := MassiveDataset.Fields.Items[I].FieldName;
                    vParamsSQL  := ':' + MassiveDataset.Fields.Items[I].FieldName;
                   End
                  Else
                   Begin
                    vFields     := vFields    + ', '  + MassiveDataset.Fields.Items[I].FieldName;
                    vParamsSQL  := vParamsSQL + ', :' + MassiveDataset.Fields.Items[I].FieldName;
                   End;
                 End;
                vLineSQL := Format(vLineSQL, [vFields, vParamsSQL]);
               End;
    mmUpdate : Begin
                vLineSQL := Format('UPDATE %s ',      [MassiveDataset.TableName + ' SET %s %s']);
                vFields  := '';
                For I := 0 To MassiveDataset.AtualRec.UpdateFieldChanges.Count -1 Do
                 Begin
                  If Lowercase(MassiveDataset.AtualRec.UpdateFieldChanges[I]) <> Lowercase(DWFieldBookmark) Then
                   Begin
                    If vFields = '' Then
                     vFields  := MassiveDataset.AtualRec.UpdateFieldChanges[I] + ' = :' + MassiveDataset.AtualRec.UpdateFieldChanges[I]
                    Else
                     vFields  := vFields + ', ' + MassiveDataset.AtualRec.UpdateFieldChanges[I] + ' = :' + MassiveDataset.AtualRec.UpdateFieldChanges[I];
                   End;
                 End;
                bPrimaryKeys := MassiveDataset.PrimaryKeys;
                Try
                 For I := 0 To bPrimaryKeys.Count -1 Do
                  Begin
                   If I = 0 Then
                    vParamsSQL := 'WHERE ' + bPrimaryKeys[I] + ' = :DWKEY_' + bPrimaryKeys[I]
                   Else
                    vParamsSQL := vParamsSQL + ' AND ' + bPrimaryKeys[I] + ' = :DWKEY_' + bPrimaryKeys[I]
                  End;
                Finally
                 FreeAndNil(bPrimaryKeys);
                End;
                vLineSQL := Format(vLineSQL, [vFields, vParamsSQL]);
               End;
    mmDelete : Begin
                vLineSQL := Format('DELETE FROM %s ', [MassiveDataset.TableName + ' %s ']);
                bPrimaryKeys := MassiveDataset.PrimaryKeys;
                Try
                 For I := 0 To bPrimaryKeys.Count -1 Do
                  Begin
                   If I = 0 Then
                    vParamsSQL := 'WHERE ' + bPrimaryKeys[I] + ' = :' + bPrimaryKeys[I]
                   Else
                    vParamsSQL := vParamsSQL + ' AND ' + bPrimaryKeys[I] + ' = :' + bPrimaryKeys[I]
                  End;
                Finally
                 FreeAndNil(bPrimaryKeys);
                End;
                vLineSQL := Format(vLineSQL, [vParamsSQL]);
               End;
   End;
   Query.SQL.Add(vLineSQL);
   //Params
   For I := 0 To Query.Params.Count -1 Do
    Begin
     If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name) <> Nil) Then
      Begin
       vFieldType := ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).FieldType);
       If MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value = 'null' Then
        Begin
         If vFieldType = ftUnknown Then
          Query.Params[I].DataType := ftString
         Else
          Query.Params[I].DataType := vFieldType;
         Query.Params[I].Clear;
        End;
       If MassiveDataset.MassiveMode <> mmUpdate Then
        Begin
         If Query.Params[I].DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                               ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                               ftString,    ftWideString]    Then
          Begin
           If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value <> Null) And
              (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
            Begin
             If Query.Params[I].Size > 0 Then
              Query.Params[I].Value := Copy(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value, 1, Query.Params[I].Size)
             Else
              Query.Params[I].Value := MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value;
            End
           Else
            Query.Params[I].Clear;
          End
         Else
          Begin
           If Query.Params[I].DataType in [ftUnknown] Then
            Begin
             If Not (ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).FieldType) in [ftUnknown]) Then
              Query.Params[I].DataType := ObjectValueToFieldType(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).FieldType)
             Else
              Query.Params[I].DataType := ftString;
            End;
           If Query.Params[I].DataType in [ftInteger, ftSmallInt, ftWord, ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
            Begin
             If (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> '') And
                (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
              Begin
               If MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value <> Null Then
                Begin
                 {$IFNDEF FPC}
                  {$IF CompilerVersion < 21}
                   If Query.Params[I].DataType = ftSmallInt Then
                   begin
                    Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value)
                   end
                   else
                   begin
                    Query.Params[I].AsInteger  := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
                   end;
                  {$ELSE}
                   If Query.Params[I].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                   begin
                    Query.Params[I].AsLargeInt := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
                   end
                   Else If Query.Params[I].DataType = ftSmallInt Then
                   begin
                    Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value)
                   end
                   else
                   begin
                    Query.Params[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
                   end;
                   {$IFEND}
                   {$ELSE}
                    If Query.Params[I].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                    begin
                     Query.Params[I].AsLargeInt := StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
                    end
                    Else If Query.Params[I].DataType = ftSmallInt Then
                    begin
                     Query.Params[I].AsSmallInt := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value)
                    end
                    else
                    begin
                     Query.Params[I].AsInteger  := StrToInt(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value);
                    end;
                  {$ENDIF}
                End;
              End
             Else
              Query.Params[I].Clear;
            End
           Else If Query.Params[I].DataType in [ftFloat,   ftCurrency, ftBCD{$IFNDEF FPC}{$if CompilerVersion >= 21}, ftSingle{$IFEND}{$ENDIF}] Then
            Begin
             If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value <> Null) And
                (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
              Query.Params[I].AsFloat  := StrToFloat(BuildFloatString(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value))
             Else
              Query.Params[I].Clear;
            End
           Else If Query.Params[I].DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
            Begin
             If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value <> Null) And
                (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
              Query.Params[I].AsDateTime  := UnixToDateTime(StrToInt64(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value))
             Else
              Query.Params[I].Clear;
            End  //Tratar Blobs de Parametros...
           Else If Query.Params[I].DataType in [ftBytes, ftVarBytes, ftBlob,
                                                ftGraphic, ftOraBlob, ftOraClob,
                                                ftMemo {$IFNDEF FPC}
                                                        {$IF CompilerVersion > 21}
                                                         , ftWideMemo
                                                        {$IFEND}
                                                       {$ENDIF}] Then
            Begin
             vStringStream := TMemoryStream.Create;
             Try
              If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value <> 'null') And
                 (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).value <> '') Then
               Begin
                MassiveDataset.Fields.FieldByName(Query.Params[I].Name).SaveToStream(vStringStream);
                vStringStream.Position := 0;
                Query.Params[I].LoadFromStream(vStringStream, ftBlob);
               End
              Else
               Query.Params[I].Clear;
             Finally
              FreeAndNil(vStringStream);
             End;
            End
           Else If (MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value <> Null) And
                   (Trim(MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value) <> 'null') Then
            Query.Params[I].Value := MassiveDataset.Fields.FieldByName(Query.Params[I].Name).Value
           Else
            Query.Params[I].Clear;
          End;
        End
       Else //Update
        Begin
         SetUpdateBuffer;
        End;
      End
     Else
      Begin
       If I = 0 Then
        SetUpdateBuffer;
      End;
    End;
  End;
 Begin
  MassiveDataset := TMassiveDatasetBuffer.Create(Nil);
  Try
   Result         := False;
   MassiveDataset.FromJSON(Massive);
   MassiveDataset.First;
   If Self.Owner      Is TServerMethodDataModule Then
    Begin
     If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveBegin) Then
      TServerMethodDataModule(Self.Owner).OnMassiveBegin(MassiveDataset);
    End
   Else If Self.Owner Is TServerMethods Then
    Begin
     If Assigned(TServerMethods(Self.Owner).OnMassiveBegin) Then
     TServerMethods(Self.Owner).OnMassiveBegin(MassiveDataset);
    End;
   B             := 1;
   Result        := True;
   For A := 1 To MassiveDataset.RecordCount Do
    Begin
     If Not vZConnection.InTransaction Then
      Begin
       vZConnection.StartTransaction;
       If Self.Owner      Is TServerMethodDataModule Then
        Begin
         If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveAfterStartTransaction) Then
          TServerMethodDataModule(Self.Owner).OnMassiveAfterStartTransaction(MassiveDataset);
        End
       Else If Self.Owner Is TServerMethods Then
        Begin
         If Assigned(TServerMethods(Self.Owner).OnMassiveAfterStartTransaction) Then
          TServerMethods(Self.Owner).OnMassiveAfterStartTransaction(MassiveDataset);
        End;
      End;
     Query.SQL.Clear;
     If Self.Owner      Is TServerMethodDataModule Then
      Begin
       vMassiveLine := False;
       If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveProcess) Then
        Begin
         TServerMethodDataModule(Self.Owner).OnMassiveProcess(MassiveDataset, vMassiveLine);
         If vMassiveLine Then
          Begin
           MassiveDataset.Next;
           Continue;
          End;
        End;
      End
     Else If Self.Owner Is TServerMethods Then
      Begin
       vMassiveLine := False;
       If Assigned(TServerMethods(Self.Owner).OnMassiveProcess) Then
        Begin
         TServerMethods(Self.Owner).OnMassiveProcess(MassiveDataset, vMassiveLine);
         If vMassiveLine Then
          Begin
           MassiveDataset.Next;
           Continue;
          End;
        End;
      End;
     PrepareData(Query, MassiveDataset, Error, MessageError);
     Try
      Query.ExecSQL;
     Except
      On E : Exception do
       Begin
        Error  := True;
        Result := False;
        If vZConnection.InTransaction Then
         vZConnection.Rollback;
        MessageError := E.Message;
        Break;
       End;
     End;
     If B >= CommitRecords Then
      Begin
       Try
        If vZConnection.InTransaction Then
         Begin
          If Self.Owner      Is TServerMethodDataModule Then
           Begin
            If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveAfterBeforeCommit) Then
             TServerMethodDataModule(Self.Owner).OnMassiveAfterBeforeCommit(MassiveDataset);
           End
          Else If Self.Owner Is TServerMethods Then
           Begin
            If Assigned(TServerMethods(Self.Owner).OnMassiveAfterBeforeCommit) Then
             TServerMethods(Self.Owner).OnMassiveAfterBeforeCommit(MassiveDataset);
           End;
          vZConnection.Commit;
          If Self.Owner      Is TServerMethodDataModule Then
           Begin
            If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveAfterAfterCommit) Then
             TServerMethodDataModule(Self.Owner).OnMassiveAfterAfterCommit(MassiveDataset);
           End
          Else If Self.Owner Is TServerMethods Then
           Begin
            If Assigned(TServerMethods(Self.Owner).OnMassiveAfterAfterCommit) Then
             TServerMethods(Self.Owner).OnMassiveAfterAfterCommit(MassiveDataset);
           End;
         End;
       Except
        On E : Exception do
         Begin
          Error  := True;
          Result := False;
          If vZConnection.InTransaction Then
           vZConnection.Rollback;
          MessageError := E.Message;
          Break;
         End;
       End;
       B := 1;
      End
     Else
      Inc(B);
     MassiveDataset.Next;
    End;
   Try
    If vZConnection.InTransaction Then
     Begin
      If Self.Owner      Is TServerMethodDataModule Then
       Begin
        If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveAfterBeforeCommit) Then
         TServerMethodDataModule(Self.Owner).OnMassiveAfterBeforeCommit(MassiveDataset);
       End
      Else If Self.Owner Is TServerMethods Then
       Begin
        If Assigned(TServerMethods(Self.Owner).OnMassiveAfterBeforeCommit) Then
         TServerMethods(Self.Owner).OnMassiveAfterBeforeCommit(MassiveDataset);
       End;
      vZConnection.Commit;
      If Self.Owner      Is TServerMethodDataModule Then
       Begin
        If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveAfterAfterCommit) Then
         TServerMethodDataModule(Self.Owner).OnMassiveAfterAfterCommit(MassiveDataset);
       End
      Else If Self.Owner Is TServerMethods Then
       Begin
        If Assigned(TServerMethods(Self.Owner).OnMassiveAfterAfterCommit) Then
         TServerMethods(Self.Owner).OnMassiveAfterAfterCommit(MassiveDataset);
       End;
     End;
   Except
    On E : Exception do
     Begin
      Error  := True;
      Result := False;
      If vZConnection.InTransaction Then
       vZConnection.Rollback;
      MessageError := E.Message;
     End;
   End;
  Finally
   If Self.Owner      Is TServerMethodDataModule Then
    Begin
     If Assigned(TServerMethodDataModule(Self.Owner).OnMassiveEnd) Then
      TServerMethodDataModule(Self.Owner).OnMassiveEnd(MassiveDataset);
    End
   Else If Self.Owner Is TServerMethods Then
    Begin
     If Assigned(TServerMethods(Self.Owner).OnMassiveEnd) Then
      TServerMethods(Self.Owner).OnMassiveEnd(MassiveDataset);
    End;
   FreeAndNil(MassiveDataset);
   Query.SQL.Clear;
  End;
 End;
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}
 Try
  Result     := Nil;
  Error      := False;
  vTempQuery := TZQuery.Create(Owner);
  If Not vZConnection.Connected Then
   vZConnection.Connected := True;
  vTempQuery.Connection   := vZConnection;
  vTempQuery.SQL.Clear;
  If LoadMassive(Massive, vTempQuery) Then
   Begin
    If SQL <> '' Then
     Begin
      Try
       vTempQuery.SQL.Clear;
       vTempQuery.SQL.Add(SQL);
       If Params <> Nil Then
        Begin
         For I := 0 To Params.Count -1 Do
          Begin
           If vTempQuery.Params.Count > I Then
            Begin
             vParamName := Copy(StringReplace(Params[I].ParamName, ',', '', []), 1, Length(Params[I].ParamName));
             A          := GetParamIndex(vTempQuery.Params, vParamName);
             If A > -1 Then//vTempQuery.ParamByName(vParamName) <> Nil Then
              Begin
               If vTempQuery.Params[A].DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                                                     ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                                                     ftString,    ftWideString]    Then
                Begin
                 If vTempQuery.Params[A].Size > 0 Then
                  vTempQuery.Params[A].Value := Copy(Params[I].Value, 1, vTempQuery.Params[A].Size)
                 Else
                  vTempQuery.Params[A].Value := Params[I].Value;
                End
               Else
                Begin
                 If vTempQuery.Params[A].DataType in [ftUnknown] Then
                  Begin
                   If Not (ObjectValueToFieldType(Params[I].ObjectValue) in [ftUnknown]) Then
                    vTempQuery.Params[A].DataType := ObjectValueToFieldType(Params[I].ObjectValue)
                   Else
                    vTempQuery.Params[A].DataType := ftString;
                  End;
                 If vTempQuery.Params[A].DataType in [ftInteger, ftSmallInt, ftWord, ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                  Begin
                   If Trim(Params[I].Value) <> '' Then
                    Begin
                     {$IFNDEF FPC}
                    {$IF CompilerVersion < 21}
                     if vTempQuery.Params[A].DataType = ftSmallInt Then
                     begin
                      vTempQuery.Params[A].AsSmallInt := StrToInt(Params[I].Value);
                     end
                     Else
                     begin
                      vTempQuery.Params[A].AsInteger  := StrToInt64(Params[I].Value);
                     end;
                    {$ELSE}
                     If vTempQuery.Params[A].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                     begin
                      vTempQuery.Params[A].AsLargeInt := StrToInt64(Params[I].Value);
                     end
                     Else if vTempQuery.Params[A].DataType = ftSmallInt Then
                     begin
                      vTempQuery.Params[A].AsSmallInt := StrToInt(Params[I].Value);
                     end
                     Else
                     begin
                      vTempQuery.Params[A].AsInteger  := StrToInt(Params[I].Value);
                     end;
                     {$IFEND}
                     {$ELSE}
                      If vTempQuery.Params[A].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                      begin
                       vTempQuery.Params[A].AsLargeInt := StrToInt64(Params[I].Value);
                      end
                      Else if vTempQuery.Params[A].DataType = ftSmallInt Then
                      begin
                       vTempQuery.Params[A].AsSmallInt := StrToInt(Params[I].Value);
                      end
                      Else
                      begin
                       vTempQuery.Params[A].AsInteger  := StrToInt(Params[I].Value);
                      end;
                    {$ENDIF}
                    End
                   Else
                    vTempQuery.Params[A].Clear;
                  End
                 Else If vTempQuery.Params[A].DataType in [ftFloat,   ftCurrency, ftBCD{$IFNDEF FPC}{$if CompilerVersion >= 21}, ftSingle{$IFEND}{$ENDIF}] Then
                  Begin
                   If Trim(Params[I].Value) <> '' Then
                    vTempQuery.Params[A].AsFloat  := StrToFloat(BuildFloatString(Params[I].Value))
                   Else
                    vTempQuery.Params[A].Clear;
                  End
                 Else If vTempQuery.Params[A].DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
                  Begin
                   If Trim(Params[I].Value) <> '' Then
                    vTempQuery.Params[A].AsDateTime  := Params[I].AsDateTime
                   Else
                    vTempQuery.Params[A].Clear;
                  End  //Tratar Blobs de Parametros...
                 Else If vTempQuery.Params[A].DataType in [ftBytes, ftVarBytes, ftBlob,
                                                           ftGraphic, ftOraBlob, ftOraClob,
                                                           ftMemo {$IFNDEF FPC}
                                                                   {$IF CompilerVersion > 21}
                                                                    , ftWideMemo
                                                                   {$IFEND}
                                                                  {$ENDIF}] Then
                  Begin
                   vStringStream := TMemoryStream.Create;
                   Try
                    Params[I].SaveToStream(vStringStream);
                    vStringStream.Position := 0;
                    If vStringStream.Size > 0 Then
                     vTempQuery.Params[A].LoadFromStream(vStringStream, ftBlob);
                   Finally
                    FreeAndNil(vStringStream);
                   End;
                  End
                 Else
                  vTempQuery.Params[A].Value    := Params[I].Value;
                End;
              End;
            End
           Else
            Break;
          End;
        End;
       vTempQuery.Open;
       If Result = Nil Then
        Result         := TJSONValue.Create;
       Result.Encoded         := EncodeStringsJSON;
       Result.Encoding        := Encoding;
       {$IFDEF FPC}
        Result.DatabaseCharSet := DatabaseCharSet;
       {$ENDIF}
       Result.LoadFromDataset('RESULTDATA', vTempQuery, EncodeStringsJSON);
       Error         := False;
      Except
       On E : Exception do
        Begin
         Try
          Error          := True;
          MessageError   := E.Message;
          If Result = Nil Then
           Result        := TJSONValue.Create;
          Result.Encoded         := True;
          Result.Encoding        := Encoding;
          {$IFDEF FPC}
           Result.DatabaseCharSet := DatabaseCharSet;
          {$ENDIF}
          Result.SetValue(GetPairJSON('NOK', MessageError));
          vZConnection.Rollback;
         Except
         End;
        End;
      End;
     End;
   End;
 Finally
  vTempQuery.Close;
  vTempQuery.Free;
 End;
End;

Function TRESTDWDriverZeos.ExecuteCommand(SQL              : String;
                                          Var Error        : Boolean;
                                          Var MessageError : String;
                                          Execute          : Boolean) : String;
Var
 vTempQuery   : TZQuery;
 aResult      : TJSONValue;
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}
 aResult := Nil;
 Result  := '';
 Error   := False;
 vTempQuery               := TZQuery.Create(Owner);
 Try
  If Not vZConnection.Connected Then
   vZConnection.Connected := True;
  vTempQuery.Connection   := vZConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(SQL);
  If Not Execute Then
   Begin
    vTempQuery.Open;
    aResult         := TJSONValue.Create;
    Try
     aResult.Encoded         := EncodeStringsJSON;
     aResult.Encoding        := Encoding;
     {$IFDEF FPC}
      aResult.DatabaseCharSet := DatabaseCharSet;
     {$ENDIF}
     aResult.LoadFromDataset('RESULTDATA', vTempQuery, EncodeStringsJSON);
     Error         := False;
     Result        := aResult.ToJson;
     FreeAndNil(aResult);
    Finally
    End;
   End
  Else
   Begin
    aResult := TJSONValue.Create;
    Try
     vTempQuery.ExecSQL;
     aResult.Encoded         := True;
     aResult.Encoding        := Encoding;
     {$IFDEF FPC}
      aResult.DatabaseCharSet := DatabaseCharSet;
     {$ENDIF}
     vZConnection.Commit;
     Error         := False;
     Result := aResult.ToJSON;
     aResult.SetValue('COMMANDOK');
    Finally
     FreeAndNil(aResult);
    End;
   End;
 Except
  On E : Exception do
   Begin
    aResult        := TJSONValue.Create;
    Try
     Error          := True;
     MessageError   := E.Message;
     aResult.Encoded         := True;
     aResult.Encoding        := Encoding;
     {$IFDEF FPC}
      aResult.DatabaseCharSet := DatabaseCharSet;
     {$ENDIF}
     aResult.SetValue(GetPairJSON('NOK', MessageError));
     vZConnection.Rollback;
     Result := aResult.ToJSON;
    Except
    End;
    FreeAndNil(aResult);
   End;
 End;
 vTempQuery.Close;
 vTempQuery.Free;
End;

Function TRESTDWDriverZeos.GetConnection: TZConnection;
Begin
 Result := vZConnection;
End;

Function TRESTDWDriverZeos.InsertMySQLReturnID(SQL              : String;
                                             Params           : TDWParams;
                                             Var Error        : Boolean;
                                             Var MessageError : String): Integer;
Var
 A, I        : Integer;
 vParamName  : String;
 ZCommand   : TZQuery;
 vStringStream : TMemoryStream;
 Function GetParamIndex(Params : TParams; ParamName : String) : Integer;
 Var
  I : Integer;
 Begin
  Result := -1;
  For I := 0 To Params.Count -1 Do
   Begin
    If UpperCase(Params[I].Name) = UpperCase(ParamName) Then
     Begin
      Result := I;
      Break;
     End;
   End;
 End;
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}
 Result := -1;
 Error  := False;
 ZCommand := TZQuery.Create(Owner);
 Try
  ZCommand.Connection := vZConnection;
  ZCommand.SQL.Clear;
  ZCommand.SQL.Add(SQL + '; SELECT LAST_INSERT_ID()ID');
  If Params <> Nil Then
   Begin
    Try
    // vTempQuery.Prepare;
    Except
    End;
    For I := 0 To Params.Count -1 Do
     Begin
      If ZCommand.Params.Count > I Then
       Begin
        vParamName := Copy(StringReplace(Params[I].ParamName, ',', '', []), 1, Length(Params[I].ParamName));
        A          := GetParamIndex(ZCommand.Params, vParamName);
        If A > -1 Then//vTempQuery.ParamByName(vParamName) <> Nil Then
         Begin
          If ZCommand.Params[A].DataType in [{$IFNDEF FPC}{$if CompilerVersion >= 21} // Delphi 2010 pra baixo
                                                ftFixedChar, ftFixedWideChar,{$IFEND}{$ENDIF}
                                                ftString,    ftWideString]    Then
           Begin
            If ZCommand.Params[A].Size > 0 Then
             ZCommand.Params[A].Value := Copy(Params[I].Value, 1, ZCommand.Params[A].Size)
            Else
             ZCommand.Params[A].Value := Params[I].Value;
           End
          Else
           Begin
            If ZCommand.Params[A].DataType in [ftUnknown] Then
             Begin
              If Not (ObjectValueToFieldType(Params[I].ObjectValue) in [ftUnknown]) Then
               ZCommand.Params[A].DataType := ObjectValueToFieldType(Params[I].ObjectValue)
              Else
               ZCommand.Params[A].DataType := ftString;
             End;
            If ZCommand.Params[A].DataType in [ftInteger, ftSmallInt, ftWord, ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
             Begin
              If Trim(Params[I].Value) <> '' Then
               Begin
                {$IFNDEF FPC}
                {$IF CompilerVersion < 21}
                 If ZCommand.Params[A].DataType = ftSmallInt Then
                 begin
                   ZCommand.Params[A].AsSmallInt := StrToInt(Params[I].Value);
                 end
                 else
                 begin
                   ZCommand.Params[A].AsInteger  := StrToInt64(Params[I].Value);
                 end;
                {$ELSE}
                  If ZCommand.Params[A].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                  begin
                   ZCommand.Params[A].AsLargeInt := StrToInt64(Params[I].Value)
                  end
                  else If ZCommand.Params[A].DataType = ftSmallInt Then
                  begin
                   ZCommand.Params[A].AsSmallInt := StrToInt(Params[I].Value)
                  end
                  Else
                  begin
                   ZCommand.Params[A].AsInteger  := StrToInt(Params[I].Value);
                  end;
                  {$IFEND}
                  {$ELSE}
                    If ZCommand.Params[A].DataType in [ftLargeint{$IFNDEF FPC}{$IF CompilerVersion >= 21}, ftLongWord{$IFEND}{$ENDIF}] Then
                    begin
                     ZCommand.Params[A].AsLargeInt := StrToInt64(Params[I].Value)
                    end
                    else If ZCommand.Params[A].DataType = ftSmallInt Then
                    begin
                     ZCommand.Params[A].AsSmallInt := StrToInt(Params[I].Value)
                    end
                    Else
                    begin
                     ZCommand.Params[A].AsInteger  := StrToInt(Params[I].Value);
                    end;
                {$ENDIF}
               End;
             End
            Else If ZCommand.Params[A].DataType in [ftFloat,   ftCurrency, ftBCD{$IFNDEF FPC}{$if CompilerVersion >= 21}, ftSingle{$IFEND}{$ENDIF}] Then
             Begin
              If Trim(Params[I].Value) <> '' Then
               ZCommand.Params[A].AsFloat  := StrToFloat(BuildFloatString(Params[I].Value));
             End
            Else If ZCommand.Params[A].DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
             Begin
              If Trim(Params[I].Value) <> '' Then
               ZCommand.Params[A].AsDateTime  := Params[I].AsDateTime
              Else
               ZCommand.Params[A].AsDateTime  := Null;
             End  //Tratar Blobs de Parametros...
            Else If ZCommand.Params[A].DataType in [ftBytes, ftVarBytes, ftBlob,
                                                    ftGraphic, ftOraBlob, ftOraClob,
                                                    ftMemo {$IFNDEF FPC}
                                                            {$IF CompilerVersion > 21}
                                                             , ftWideMemo
                                                            {$IFEND}
                                                           {$ENDIF}] Then
             Begin
              vStringStream := TMemoryStream.Create;
              Try
               Params[I].SaveToStream(vStringStream);
               vStringStream.Position := 0;
               If vStringStream.Size > 0 Then
                ZCommand.Params[A].LoadFromStream(vStringStream, ftBlob);
              Finally
               FreeAndNil(vStringStream);
              End;
             End
            Else
             ZCommand.Params[A].Value    := Params[I].Value;
           End;
         End;
       End
      Else
       Break;
     End;
   End;
  ZCommand.Open;
  If ZCommand.RecordCount > 0 Then
    Result := StrToInt(ZCommand.FindField('ID').AsString);
  vZConnection.Commit;
 Except
  On E : Exception do
   Begin
    vZConnection.Rollback;
    Error        := True;
    MessageError := E.Message;
   End;
 End;
 ZCommand.Close;
 FreeAndNil(ZCommand);
End;

procedure TRESTDWDriverZeos.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = vZConnection) then
  begin
    vZConnection := nil;
  end;
  inherited Notification(AComponent, Operation);
end;

Function TRESTDWDriverZeos.OpenDatasets       (DatasetsLine     : String;
                                             Var Error        : Boolean;
                                             Var MessageError : String): TJSONValue;
Var
 vTempQuery  : TZQuery;
 vTempJSON   : TJSONValue;
 vJSONLine   : String;
 I, X        : Integer;
 DWParams    : TDWParams;
 bJsonValue  : udwjson.TJsonObject;
 bJsonArray  : udwjson.TJsonArray;
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}
 Error  := False;
 bJsonArray := Nil;
 vTempQuery               := TZQuery.Create(Nil);
 Try
  If Not vZConnection.Connected Then
   vZConnection.Connected := True;
  vTempQuery.Connection   := vZConnection;
  bJsonArray := udwjson.TJsonArray.create(DatasetsLine);
  For I := 0 To bJsonArray.Length - 1 Do
   Begin
    bJsonValue := bJsonArray.optJSONObject(I);
    vTempQuery.Close;
    vTempQuery.SQL.Clear;
    vTempQuery.SQL.Add(DecodeStrings(bJsonValue.opt(bJsonValue.names.get(0).ToString).ToString{$IFDEF FPC}, csUndefined{$ENDIF}));
    If bJsonValue.names.length > 1 Then
     Begin
      DWParams := TDWParams.Create;
      Try
       DWParams.FromJSON(DecodeStrings(bJsonValue.opt(bJsonValue.names.get(1).ToString).ToString{$IFDEF FPC}, csUndefined{$ENDIF}));
       For X := 0 To DWParams.Count -1 Do
        Begin
         If vTempQuery.ParamByName(DWParams[X].ParamName) <> Nil Then
          Begin
           vTempQuery.ParamByName(DWParams[X].ParamName).DataType := ObjectValueToFieldType(DWParams[X].ObjectValue);
           vTempQuery.ParamByName(DWParams[X].ParamName).Value    := DWParams[X].Value;
          End;
        End;
      Finally
       DWParams.Free;
      End;
     End;
    vTempQuery.Open;
    vTempJSON          := TJSONValue.Create;
    vTempJSON.Encoded  := EncodeStringsJSON;
    vTempJSON.Encoding := Encoding;
    vTempJSON.LoadFromDataset('RESULTDATA', vTempQuery, EncodeStringsJSON);
    Try
     If Length(vJSONLine) = 0 Then
      vJSONLine := Format('%s', [vTempJSON.ToJSON])
     Else
      vJSONLine := vJSONLine + Format(', %s', [vTempJSON.ToJSON]);
    Finally
     vTempJSON.Free;
    End;
   End;
 Except
  On E : Exception do
   Begin
    Try
     Error          := True;
     MessageError   := E.Message;
     vJSONLine      := GetPairJSON('NOK', MessageError);
    Except
    End;
   End;
 End;
 Result         := TJSONValue.Create;
 Try
  vJSONLine     := Format('[%s]', [vJSONLine]);
  Result.Encoded         := True;
  Result.Encoding        := Encoding;
  {$IFDEF FPC}
   Result.DatabaseCharSet := DatabaseCharSet;
  {$ENDIF}
  Result.SetValue(vJSONLine);
 Finally

 End;
 vTempQuery.Close;
 vTempQuery.Free;
 If bJsonArray <> Nil Then
  FreeAndNil(bJsonArray);
End;

Procedure TRESTDWDriverZeos.PrepareConnection(Var ConnectionDefs : TConnectionDefs);
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}

End;

Function TRESTDWDriverZeos.InsertMySQLReturnID(SQL              : String;
                                             Var Error        : Boolean;
                                             Var MessageError : String): Integer;
Var
 ZCommand : TZQuery;
Begin
 {$IFNDEF FPC}Inherited;{$ENDIF}
 Result := -1;
 Error  := False;
 ZCommand := TZQuery.Create(Owner);
 Try
  ZCommand.Connection := vZConnection;
  ZCommand.SQL.Clear;
  ZCommand.SQL.Add(SQL + '; SELECT LAST_INSERT_ID()ID');
  ZCommand.Open;
  If ZCommand.RecordCount > 0 Then
    Result := StrToInt(ZCommand.FindField('ID').AsString);
  vZConnection.Commit;
 Except
  On E : Exception do
   Begin
    vZConnection.Rollback;
    Error        := True;
    MessageError := E.Message;
   End;
 End;
 ZCommand.Close;
 FreeAndNil(ZCommand);
End;

Procedure TRESTDWDriverZeos.SetConnection(Value: TZConnection);
Begin
  if vZConnection <> Value then
    vZConnection := Value;
  if vZConnection <> nil then
    vZConnection.FreeNotification(Self);
End;

end.
