unit uComponentXmlBuilder;

interface

uses
  Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Samples.Spin,
  Generics.Collections, Generics.Defaults, SysUtils,
  Classes, Xml.XMLDoc, Xml.XMLIntf, Variants, Vcl.ComCtrls;

type
  ///  <summary>
  ///  Builds XML from a panel hierarchy by binding controls to XML nodes,
  ///  either by component name or by Tag-to-node mapping.
  ///  </summary>
  ///  <remarks>
  ///  This class operates in one of two modes:
  ///  (1) Name-based binding (Create): Methods AddComponentBind, RemoveComponentBind.
  ///  (2) Tag-based binding (CreateWithTags): Methods AddCustomComponentValue, RemoveCustomComponent.
  ///  </remarks>
  TComponentXmlBuilder = class
    private
      FPanel: TPanel;
      FDictNodeNames: TDictionary<Integer, string>;    // [tag, node name]
      FComponentValuesToSave: TDictionary<string, string>; // [component name, value to save]
      FComponentValuesRead: TDictionary<string, string>; // [component name, loaded value]
      FComponentNodeBinds: TDictionary<string, string>; // [component name, node name]
      FWithTabOrder: Boolean;
      FBoolStrValue: Boolean;
      FUseComponentNameOnly: Boolean; // Bind type by name or by tag map

      function GetText(Node: IXMLNode; const Name: string; Default: string): string;
      function GetInt(Node: IXMLNode; const Name: string; Default: Integer): Integer;
      function GetFloat(Node: IXMLNode; const Name: string; Default: Double): Double;
      function GetBool(Node: IXMLNode; const Name: string; Default: Boolean): Boolean;

      procedure GetOrderedList(ComponentList: TList<TControl>; AControl: TWinControl);
      
      function ValidateData(AFileName: string): Boolean;
      
      function GetValueAsString(AControl: TControl): string;
      function AddNodeFromComponent(const Parent: IXMLNode; AControl: TControl): IXMLNode;

      procedure GetComponentValueFromNode(const Parent: IXMLNode; AControl: TControl);
      function GetChildByName(Parent: IXMLNode; const Name: string): IXMLNode;

      function GetComponentNodeName(AComponent: TControl): string;
      function IsComponentOnList(AComponent: TControl): Boolean;

      procedure AssignPanel(APanel: TPanel);

    public
      ///  <summary>Optional callback used to encode component values before saving to XML.</summary>
      ///  <remarks>Encoding will work on components with set PasswordChar property.</remarks>
      OnEncodeText: TFunc<string, string>;

      ///  <summary>Optional callback used to decode component values before saving to XML.</summary>
      ///  <remarks>Decoding will work on components with set PasswordChar property.</remarks>
      OnDecodeText: TFunc<string, string>;

      property PanelComponent: TPanel read FPanel write AssignPanel;

      /// <summary>Determines whether components are processed in TabOrder sequence.</summary>
      property WithTabOrder: Boolean read FWithTabOrder write FWithTabOrder;

      ///  <summary>Determines how Boolean values are serialized. True = 'true'/'false', False = '1'/'0'. Default is False.</summary>
      property BoolStrValue: Boolean read FBoolStrValue write FBoolStrValue;

      ///  <summary>Clears component binding lists.</summary>
      procedure ClearLists;

              {================================================}
              {  Name-based binding (Create constructor only)  }
              {================================================}

      ///  <summary>Associates a control with an XML node name.</summary>
      ///  <exception cref="EInvalidOperation">Raised if the builder was not created using CreateWithTags.</exception>
      procedure AddComponentBind(AComponent: TControl; ANodeName: string); overload;

      ///  <summary>Associates a control with an XML node name.</summary>
      ///  <param name="AValue">Fixed value to be written to XML instead of reading from the component.</param>
      ///  <exception cref="EInvalidOperation">Raised if the builder was not created using CreateWithTags.</exception>
      procedure AddComponentBind(AComponent: TControl; ANodeName: string; AValue: Variant); overload;

      ///  <summary>Removes component bind.</summary>
      ///  <exception cref="EInvalidOperation">Raised if the builder was not created using CreateWithTags.</exception>
      procedure RemoveComponentBind(AComponent: TControl);

              {======================================================}
              { Tag-based binding (CreateWithTags constructor only)  }
              {======================================================}

      ///  <summary>Adds component to list of components with bound fixed value.</summary>
      ///  <param name="AValue">Fixed value to be written to XML instead of reading from the component.</param>
      procedure AddCustomComponentValue(AComponent: TControl; AValue: Variant);

      ///  <summary>Removes component bind.</summary>
      ///  <exception cref="EInvalidOperation">Raised if the builder was not created using Create.</exception>
      procedure RemoveCustomComponent(AComponent: TControl);

              {========================}
              {   Read XML functions   }
              {========================}

      ///  <summary>Adds component to read list.
      ///  The value will not be assigned to the component and can be retrieved using GetComponentValue.</summary>
      procedure AddToReadList(AComponent: TControl);

      ///  <summary>Removes component from read list.</summary>
      procedure RemoveFromReadList(AComponent: TControl);

      ///  <summary>Returns read component value if it was added to read list with "AddToReadList".</summary>
      ///  <remarks>Raw string value read from XML.</remarks>
      function GetComponentValue(AComponent: TControl): string;

              {================================================}

      ///  <summary>Reads XML file and sets values to assigned and bound controls.</summary>
      ///  <param name="AFileName">Path for loading file.</param>
      ///  <returns>True if values were loaded successfully.</returns>
      ///  <exception cref="Exception">Raised if an I/O or XML parsing error occurs.</exception>
      function LoadXml(AFileName: string): Boolean;

      ///  <summary>Constructs XML structure from assigned components with set oprions and save to file.</summary>
      ///  <param name="AFileName">Path for saving file.</param>
      ///  <returns>True if file was saved successfully.</returns>
      ///  <exception cref="Exception">Raised if an I/O or XML parsing error occurs.</exception>
      function SaveXml(AFileName: string): Boolean;

      destructor Destroy; override;

      ///  <summary> Constructor for component bind operations </summary>
      ///  <param name="APanel">Root panel containing controls to be processed. The panel is not owned by the builder.</param>
      constructor Create(APanel: TPanel); overload;

      ///  <summary> Constructor for tag dictionary bind operations </summary>
      ///  <param name="APanel">Root panel containing controls to be processed. The panel is not owned by the builder.</param>
      ///  <param name="ADictNodeNames">Dictionary mapping Tag values to XML node names. Ownership is not transferred.</param>
      constructor CreateWithTags(APanel: TPanel; ADictNodeNames: TDictionary<Integer, string>); overload;
  end;

implementation

uses
  StrUtils;

{ TComponentXmlBuilder }

procedure TComponentXmlBuilder.AssignPanel(APanel: TPanel);
begin
  if not Assigned(APanel) then
    raise EArgumentNilException.Create('Assigned panel cannot be nil');

  FPanel := APanel;
end;

procedure TComponentXmlBuilder.AddComponentBind(AComponent: TControl; ANodeName: string);
begin
  if not FUseComponentNameOnly then
    raise EInvalidOperation.Create('Method can only be used with Create constructor');

  if Assigned(AComponent) and (ANodeName <> '') then
    FComponentNodeBinds.Add(AComponent.Name, ANodeName);
end;

procedure TComponentXmlBuilder.RemoveComponentBind(AComponent: TControl);
begin
  if not FUseComponentNameOnly then
    raise EInvalidOperation.Create('Method can only be used with Create constructor');

  if Assigned(AComponent) then
    FComponentNodeBinds.Remove(AComponent.Name);
end;

procedure TComponentXmlBuilder.ClearLists;
begin
  FComponentValuesToSave.Clear;
  FComponentValuesRead.Clear;
  FComponentNodeBinds.Clear;
end;

constructor TComponentXmlBuilder.Create(APanel: TPanel);
begin
  inherited Create;

  FPanel := APanel;
  FWithTabOrder := True;
  FBoolStrValue := False;
  FUseComponentNameOnly := True;

  FDictNodeNames := nil;
  FComponentValuesToSave := TDictionary<string, string>.Create;
  FComponentValuesRead := TDictionary<string, string>.Create;
  FComponentNodeBinds := TDictionary<string, string>.Create;
end;

constructor TComponentXmlBuilder.CreateWithTags(APanel: TPanel; ADictNodeNames: TDictionary<Integer, string>);
begin
  Create(APanel);

  FUseComponentNameOnly := False;
  FDictNodeNames := ADictNodeNames;
end;

destructor TComponentXmlBuilder.Destroy;
begin
  FreeAndNil(FComponentValuesToSave);
  FreeAndNil(FComponentValuesRead);
  FreeAndNil(FComponentNodeBinds);

  inherited;
end;

function TComponentXmlBuilder.ValidateData(AFileName: string): Boolean;
begin
  if AFileName = '' then
     raise Exception.Create('No file path provided.');
  if not Assigned(FPanel) then
    raise Exception.Create('TPanel was not assigned.');

  if FUseComponentNameOnly then begin
    if FComponentNodeBinds.Count = 0 then
      raise Exception.Create('Component and XML node names not specified.');
  end
  else begin
    if not Assigned(FDictNodeNames) or (FDictNodeNames.Count = 0) then
      raise Exception.Create('Element names dictionary is empty.');
  end;

  if not IsComponentOnList(FPanel) then
    raise Exception.Create('No name provided for root element.');

  Result := True;
end;

function TComponentXmlBuilder.SaveXml(AFileName: string): Boolean;
var
  XmlDoc: IXMLDocument;
  pnlNode: IXMLNode;
  controlList: TList<TControl>;
begin
  controlList := TList<TControl>.Create;
  try
    try
      if not ValidateData(AFileName) then Exit(False);

      XmlDoc := NewXMLDocument;
      XmlDoc.Encoding := 'utf-8';
      XmlDoc.Options := [doNodeAutoIndent];

      // create root element from FPanel
      pnlNode := XmlDoc.AddChild(GetComponentNodeName(FPanel));

      if FWithTabOrder then begin
        //sort with TabOrder
        GetOrderedList(controlList, FPanel);
        
        for var CtrlTmp in controlList do
          AddNodeFromComponent(pnlNode, CtrlTmp);
      end
      else begin
        // order doesn't matter
        for var I := 0 to FPanel.ControlCount - 1 do begin
          AddNodeFromComponent(pnlNode, FPanel.Controls[I]);
        end;
      end;

      XmlDoc.SaveToFile(AFileName);
      Result := True;
    except
      on E: Exception do begin
        raise Exception.CreateFmt('%s: %s', [Self.ClassName, E.Message]);
      end;
    end;
  finally
    controlList.Free;
  end;
end;

function TComponentXmlBuilder.AddNodeFromComponent(const Parent: IXMLNode; AControl: TControl): IXMLNode;
var
  controlList: TList<TControl>;
begin
  Result := Parent;

  if not IsComponentOnList(AControl) then Exit; // ignore elements with no name assigned

  // Components treated as new section -> recursive node creation
  if (AControl is TPanel) or (AControl is TGroupBox) then begin
    Result := Parent.AddChild(GetComponentNodeName(AControl));

    controlList := TList<TControl>.Create;
    try
      if FWithTabOrder then begin
        //sort with TabOrder
        GetOrderedList(controlList, TWinControl(AControl));

        for var CtrlTmp in controlList do
          AddNodeFromComponent(Result, CtrlTmp);
      end
      else begin
        // order doesn't matter
        for var I := 0 to TWinControl(AControl).ControlCount - 1 do
          AddNodeFromComponent(Result, TWinControl(AControl).Controls[I]);
      end;
    finally
      controlList.Free;
    end;
  end else
  if AControl is TPageControl then begin
    Result := Parent.AddChild(GetComponentNodeName(AControl));

    //loop through pages
    for var J := 0 to TPageControl(AControl).PageCount - 1 do begin
      controlList := TList<TControl>.Create;
      try
        if FWithTabOrder then begin
          //sort with TabOrder
          GetOrderedList(controlList, TWinControl(TPageControl(AControl).Pages[J]));

          for var CtrlTmp in controlList do
            AddNodeFromComponent(Result, CtrlTmp);
        end
        else begin
          // order doesn't matter
          for var I := 0 to TWinControl(TPageControl(AControl).Pages[J]).ControlCount - 1 do
            AddNodeFromComponent(Result, TWinControl(TPageControl(AControl).Pages[J]).Controls[I]);
        end;
      finally
        controlList.Free;
      end;
    end;
  end else
  if FComponentValuesToSave.ContainsKey(AControl.Name) then begin
    // custom set components
    Result.AddChild(GetComponentNodeName(AControl)).Text := FComponentValuesToSave[AControl.Name];
  end else
  // save values of supported components
  if (AControl is TEdit) or
     (AControl is TSpinEdit) or
     (AControl is TComboBox) or
     (AControl is TCheckBox) or
     (AControl is TMemo) or
     (AControl is TRadioGroup)
  then begin
    Result.AddChild(GetComponentNodeName(AControl)).Text := GetValueAsString(AControl);
  end;
end;

function TComponentXmlBuilder.GetValueAsString(AControl: TControl): string;
begin
  if AControl is TEdit then begin
    Result := TEdit(AControl).Text;
    if (TEdit(AControl).PasswordChar <> #0) and Assigned(OnEncodeText) then
      Result := OnEncodeText(Result);
  end;
  if AControl is TSpinEdit then begin
    Result := FloatToStr(TSpinEdit(AControl).Value);
  end;
  if (AControl is TComboBox) then begin
    Result := IntToStr(TComboBox(AControl).ItemIndex);
  end;
  if (AControl is TCheckBox) then begin
    if TCheckBox(AControl).Checked then
      Result := IfThen(FBoolStrValue, 'true', '1')
    else
      Result := IfThen(FBoolStrValue, 'false', '0');
  end;
  if (AControl is TMemo) then begin
    Result := TMemo(AControl).Text;  
  end;
  if (AControl is TRadioGroup) then begin
    Result := IntToStr(TRadioGroup(AControl).ItemIndex);  
  end;
end;

function TComponentXmlBuilder.LoadXml(AFileName: string): Boolean;
var
  XmlDoc: IXMLDocument;
  RootNode: IXMLNode;
begin
  XmlDoc := TXMLDocument.Create(nil);

  try
    if not ValidateData(AFileName) then Exit(False);
    
    XmlDoc.LoadFromFile(AFileName);
    XmlDoc.Active := True;
    RootNode := XmlDoc.DocumentElement;

    if RootNode = nil then raise Exception.Create('XML document empty or invalid.');
    if RootNode.NodeName <> GetComponentNodeName(FPanel) then
      raise Exception.Create('Incorrect XML root element.');
      
    for var I := 0 to FPanel.ControlCount - 1 do 
      GetComponentValueFromNode(RootNode, FPanel.Controls[I]);
      
    Result := True
  except
    on E: Exception do begin
      raise Exception.CreateFmt('%s: %s', [Self.ClassName, E.Message]);
    end;
  end;
end;

procedure TComponentXmlBuilder.GetComponentValueFromNode(const Parent: IXMLNode; AControl: TControl);
var
  Node: IXMLNode;
  strTmp: string;
begin
  if not (IsComponentOnList(AControl) or
         FComponentValuesRead.ContainsKey(AControl.Name)) then Exit; // ignore elements with no name assigned

  // Components treated as child nodes container -> recursive get node
  if (AControl is TPanel)  or (AControl is TGroupBox) then begin
    for var I := 0 to TWinControl(AControl).ControlCount - 1 do begin
      Node := GetChildByName(Parent, GetComponentNodeName(AControl));
      if Assigned(Node) then
        GetComponentValueFromNode(Node, TWinControl(AControl).Controls[I]);
    end;
  end else
  if AControl is TPageControl then begin
    //loop through pages
    for var J := 0 to TPageControl(AControl).PageCount - 1 do begin
      for var I := 0 to TPageControl(AControl).Pages[J].ControlCount - 1 do begin
        Node := GetChildByName(Parent, GetComponentNodeName(AControl));
        if Assigned(Node) then
          GetComponentValueFromNode(Node, TPageControl(AControl).Pages[J].Controls[I]);
      end;
    end;
  end else
  // load custom list
  if FComponentValuesRead.ContainsKey(AControl.Name) then begin
    strTmp := GetText(Parent, GetComponentNodeName(AControl), '');
    FComponentValuesRead.AddOrSetValue(AControl.Name, strTmp);
  end else
  // load values
  if (AControl is TEdit) then begin
    strTmp := GetText(Parent, GetComponentNodeName(AControl), '');
    if (TEdit(AControl).PasswordChar <> #0) and Assigned(OnDecodeText) then
      strTmp := OnDecodeText(strTmp);
    TEdit(AControl).Text := strTmp;
  end else
  if (AControl is TSpinEdit) then begin
    TSpinEdit(AControl).Value := GetInt(Parent, GetComponentNodeName(AControl), 0);
  end else
  if (AControl is TComboBox) then begin
    TComboBox(AControl).ItemIndex := GetInt(Parent, GetComponentNodeName(AControl), 0);
  end else
  if (AControl is TCheckBox) then begin
    TCheckBox(AControl).Checked := GetBool(Parent, GetComponentNodeName(AControl), False);
  end else
  if (AControl is TMemo) then begin
    TMemo(AControl).Lines.Text := GetText(Parent, GetComponentNodeName(AControl), '');
  end else
  if (AControl is TRadioGroup) then begin
    TRadioGroup(AControl).ItemIndex := GetInt(Parent, GetComponentNodeName(AControl), 0);
  end;
end;

procedure TComponentXmlBuilder.GetOrderedList(ComponentList: TList<TControl>; AControl: TWinControl);
begin
  try
    for var I := 0 to AControl.ControlCount - 1 do
      ComponentList.Add(AControl.Controls[I]);

    ComponentList.Sort(
      TComparer<TControl>.Construct(
        function(const A, B: TControl): Integer
        begin
          Result := TWinControl(A).TabOrder - TWinControl(B).TabOrder;
        end
      )
    );
  except
    raise;
  end;
end;

function TComponentXmlBuilder.GetChildByName(Parent: IXMLNode; const Name: string): IXMLNode;
begin
  Result := nil;
  for var I := 0 to Parent.ChildNodes.Count - 1 do
    if (Parent.ChildNodes[I].NodeName = Name) then
      Exit(Parent.ChildNodes[I]);
end;

function TComponentXmlBuilder.GetFloat(Node: IXMLNode; const Name: string; Default: Double): Double;
var
  Child: IXMLNode;
begin
  Child := GetChildByName(Node, Name);
  if Assigned(Child) then
    Result := Child.Text.ToDouble
  else
    Result := Default;
end;

function TComponentXmlBuilder.GetInt(Node: IXMLNode; const Name: string; Default: Integer): Integer;
var
  Child: IXMLNode;
begin
  Child := GetChildByName(Node, Name);
  if Assigned(Child) then
    Result := Child.Text.ToInteger
  else
    Result := Default;
end;

function TComponentXmlBuilder.GetText(Node: IXMLNode; const Name: string; Default: string): string;
var
  Child: IXMLNode;
begin
  Child := GetChildByName(Node, Name);
  if Assigned(Child) then
    Result := Child.Text
  else
    Result := Default;
end;

function TComponentXmlBuilder.GetBool(Node: IXMLNode; const Name: string; Default: Boolean): Boolean;
var
  Child: IXMLNode;
begin
  Child := GetChildByName(Node, Name);
  if Assigned(Child) then
    Result := Child.Text.ToBoolean
  else
    Result := Default;
end;

procedure TComponentXmlBuilder.AddComponentBind(AComponent: TControl; ANodeName: string; AValue: Variant);
begin
  if not FUseComponentNameOnly then
    raise EInvalidOperation.Create('Method can only be used with Create constructor');

  AddComponentBind(AComponent, ANodeName);
  AddCustomComponentValue(AComponent, AValue);
end;

procedure TComponentXmlBuilder.AddCustomComponentValue(AComponent: TControl; AValue: Variant);
var
  strValue: string;
begin
  try
    if VarIsNull(AValue) or VarIsEmpty(AValue) then begin
      strValue := '';
    end else
    if VarIsType(AValue, varBoolean) then begin
      if Boolean(AValue) then
        strValue := IfThen(FBoolStrValue, 'true', '1')
      else
        strValue := IfThen(FBoolStrValue, 'false', '0');
    end else begin
      strValue := VarToStr(AValue);
    end;

    FComponentValuesToSave.AddOrSetValue(AComponent.Name, strValue);
  except
    on E: Exception do raise Exception.CreateFmt('%s: %s', [Self.ClassName, E.Message]);
  end;
end;

procedure TComponentXmlBuilder.RemoveCustomComponent(AComponent: TControl);
begin
  if FUseComponentNameOnly then
    raise EInvalidOperation.Create('Method can only be used with CreateWithTags constructor');
  try
    FComponentValuesToSave.Remove(AComponent.Name);
  except
    on E: Exception do raise Exception.CreateFmt('%s: %s', [Self.ClassName, E.Message]);
  end;
end;

function TComponentXmlBuilder.GetComponentNodeName(AComponent: TControl): string;
begin
  if FUseComponentNameOnly then
    Result := FComponentNodeBinds[AComponent.Name]
  else
    Result := FDictNodeNames[AComponent.Tag];
end;

function TComponentXmlBuilder.GetComponentValue(AComponent: TControl): string;
begin
  try
    if FComponentValuesRead.ContainsKey(AComponent.Name) then
      Result := FComponentValuesRead[AComponent.Name]
    else
      Result := '';
  except
    on E: Exception do raise Exception.CreateFmt('%s: %s', [Self.ClassName, E.Message]);
  end;
end;

function TComponentXmlBuilder.IsComponentOnList(AComponent: TControl): Boolean;
begin
  if FUseComponentNameOnly then
    Result := FComponentNodeBinds.ContainsKey(AComponent.Name)
  else
    Result := FDictNodeNames.ContainsKey(AComponent.Tag);
end;

procedure TComponentXmlBuilder.AddToReadList(AComponent: TControl);
begin
  try
    FComponentValuesRead.AddOrSetValue(AComponent.Name, '');
  except
    on E: Exception do raise Exception.CreateFmt('%s: %s', [Self.ClassName, E.Message]);
  end;
end;

procedure TComponentXmlBuilder.RemoveFromReadList(AComponent: TControl);
begin
  try
    FComponentValuesRead.Remove(AComponent.Name);
  except
    on E: Exception do raise Exception.CreateFmt('%s: %s', [Self.ClassName, E.Message]);
  end;
end;

end.
