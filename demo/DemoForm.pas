unit DemoForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Generics.Collections,
  Vcl.Samples.Spin, Vcl.CheckLst, Vcl.Mask, Vcl.ComCtrls, uComponentXmlBuilder;

type
  TXmlElementNames = (xmConfiguration=1, xmDatabase1, xmDatabase2, xmGeneral,
                      xmActive, xmDbType, xmUsername, xmPassword, xmServer, xmPort,
                      xmDescription, xmUseOption, xmCustomText, xmLabel,
                      xmPageControl, xmPage1, xmPage2, xmPage1Edt, xmPage2Edt, xmPage3Edt);

  TFormDemo = class(TForm)
    pnlTop: TPanel;
    pnlMain: TPanel;
    btnSave: TButton;
    edtUser1: TEdit;
    sePort1: TSpinEdit;
    lblUser1: TLabel;
    lblPort1: TLabel;
    lblServer1: TLabel;
    edtServer1: TEdit;
    edtPassword1: TEdit;
    lblPassword1: TLabel;
    pnlDatabase1: TPanel;
    lblDatabase1: TLabel;
    cmbDbType1: TComboBox;
    lblDbType1: TLabel;
    chkActive1: TCheckBox;
    pnlDatabase2: TPanel;
    lblPassword2: TLabel;
    Label2: TLabel;
    lblServer2: TLabel;
    lblUser2: TLabel;
    lblDatabase2: TLabel;
    lblDbType2: TLabel;
    sePort2: TSpinEdit;
    edtPassword2: TEdit;
    edtServer2: TEdit;
    edtUser2: TEdit;
    cmbDbType2: TComboBox;
    chkActive2: TCheckBox;
    btnLoad: TButton;
    grpbxGeneral: TGroupBox;
    memoDescr: TMemo;
    rdgrpUseOption: TRadioGroup;
    chkDefDescr: TCheckBox;
    medtCustom: TMaskEdit;
    cmbSaveOption: TComboBox;
    Label1: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    pnlTs1: TPanel;
    pnlTs2: TPanel;
    TabSheet3: TTabSheet;
    edtTs3: TEdit;
    edtTs1: TEdit;
    edtTs2: TEdit;
    procedure btnSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
  private
    FDictMarkers: TDictionary<Integer, string>;

    function StringEncode(pText: string) : string;
    function StringDecode(pText: string) : string;

    procedure SetDictMarkers;
    procedure SetTags;
    procedure SetTabOrder;

    procedure PrepareBuilder(pXmlBuilder: TComponentXmlBuilder);

    procedure SaveXmlWithNamesOption;
    procedure SaveXmlWithTagOption;

    procedure LoadConfigWithNamesOption;
    procedure LoadConfigWithTagOption;
  public
    { Public declarations }
  end;

var
  FormDemo: TFormDemo;

implementation

uses
  IOUtils, NetEncoding;

{$R *.dfm}

function XorCipher(const S: string; Key: Byte = $AA): string;
var
  I: Integer;
begin
  SetLength(Result, Length(S));
  for I := 1 to Length(S) do
    Result[I] := Char(Byte(S[I]) xor Key);
end;

{ TFormDemo }

function TFormDemo.StringDecode(pText: string): string;
begin
  Result := XorCipher(TNetEncoding.Base64.Decode(pText));
end;

function TFormDemo.StringEncode(pText: string): string;
begin
  Result := TNetEncoding.Base64.Encode(XorCipher(pText));
end;

procedure TFormDemo.FormCreate(Sender: TObject);
begin
  // tag number - xml element names
  FDictMarkers := TDictionary<Integer, string>.Create;

  edtPassword1.PasswordChar := '*'; // if PasswordChar is set, TComponentXmlBuilder will use assigned OnEncodeText, OnDecodeText functions for encryption
  edtPassword2.PasswordChar := '*';

  SetDictMarkers;
  SetTags;
  SetTabOrder;

  LoadConfigWithTagOption;
end;

procedure TFormDemo.btnLoadClick(Sender: TObject);
begin
  case cmbSaveOption.ItemIndex of
    0: LoadConfigWithNamesOption;
    1: LoadConfigWithTagOption;
  end;
end;

procedure TFormDemo.btnSaveClick(Sender: TObject);
begin
  case cmbSaveOption.ItemIndex of
    0: SaveXmlWithNamesOption;
    1: SaveXmlWithTagOption;
  end;
end;

procedure TFormDemo.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FDictMarkers);
end;

{$region 'Names option'}
procedure TFormDemo.PrepareBuilder(pXmlBuilder: TComponentXmlBuilder);
begin
  with pXmlBuilder do begin
    // settings
    WithTabOrder := True; // optional ordering param (default True)
    BoolStrValue := False; // ckeckbox value format: False - 1/0; True - true/false (default False)
    OnEncodeText := StringEncode;  // assign functions to be used in encrypting/decrypting password edits (if Edit's PasswordChar <> #0)
    OnDecodeText := StringDecode;

    // prepare binding list
    AddComponentBind(pnlMain, 'CONFIGURATION');
    AddComponentBind(grpbxGeneral, 'GENERAL');

    {$region 'pnlDatabase1'}
      AddComponentBind(pnlDatabase1, 'DATABASE_1');
      AddComponentBind(chkActive1, 'ACTIVE');
      AddComponentBind(cmbDbType1, 'DB_TYPE');
      AddComponentBind(edtUser1, 'USERNAME');
      AddComponentBind(edtPassword1, 'PASSWORD');
      AddComponentBind(edtServer1, 'SERVER');
      AddComponentBind(sePort1, 'PORT');
    {$endregion}

    {$region 'pnlDatabase2'}
      AddComponentBind(pnlDatabase2, 'DATABASE_2');
      AddComponentBind(chkActive2, 'ACTIVE');
      AddComponentBind(cmbDbType2, 'DB_TYPE', cmbDbType2.Text); // works like combine with AddCustomComponentValue
      AddComponentBind(edtUser2, 'USERNAME');
      AddComponentBind(edtPassword2, 'PASSWORD');
      AddComponentBind(edtServer2, 'SERVER');
      AddComponentBind(sePort2, 'PORT');
    {$endregion}

    {$region 'grpbxGeneral'}
      AddComponentBind(memoDescr, 'DESCRIPTION');
      if chkDefDescr.Checked then // chkDefDescr is not added itself so it will be ommited
        AddCustomComponentValue(memoDescr, 'This is default description.'); // overwrite value

      AddComponentBind(rdgrpUseOption, 'USE_OPTION');
      AddComponentBind(medtCustom, 'CUSTOM_TEXT', medtCustom.Text); // TMaskEdit is not supported but can be custom saved
    {$endregion}

    AddComponentBind(lblDatabase1, 'LABEL', 'Static text');  // use dummy component for static text

    {$region 'PageControl'}
      AddComponentBind(PageControl1, 'PAGES');
      AddComponentBind(pnlTs1, 'PAGE_1');
      AddComponentBind(edtTs1, 'P1_TEXT');
      AddComponentBind(pnlTs2, 'PAGE_2');
      AddComponentBind(edtTs2, 'P2_TEXT');
      AddComponentBind(edtTs3, 'P3_TEXT');
    {$endregion}

    //assign components to be custom loaded
    AddToReadList(cmbDbType2); // add controls which values should be put into readlist instead of loading to component itself
    AddToReadList(medtCustom); // TMaskEdit is not supported so it will not be loaded until read explicitly
    AddToReadList(lblDatabase1); // dummy component
  end;
end;

procedure TFormDemo.SaveXmlWithNamesOption;
var
  XmlBuilder: TComponentXmlBuilder;
  logLine: string;
begin
// action for saving xml file
  XmlBuilder := TComponentXmlBuilder.Create(pnlMain);
  try
    try
      PrepareBuilder(XmlBuilder);

      XmlBuilder.SaveXml('panel.xml');
    except
      on E: Exception do
      begin
        ShowMessage('Error occurred while saving the file.');
        logLine := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ': ' + E.Message + sLineBreak;
        TFile.AppendAllText('logs.txt', logLine);
      end;
    end;
  finally
    XmlBuilder.Free;
  end;
end;

procedure TFormDemo.LoadConfigWithNamesOption;
var
  XmlBuilder: TComponentXmlBuilder;
  logLine, sValue: string;
begin
  XmlBuilder := TComponentXmlBuilder.Create(pnlMain);
  try
    try
      PrepareBuilder(XmlBuilder);
      XmlBuilder.LoadXml('panel.xml');

      // components on custom list will not be updated with read values, their values need to be get individually
      sValue := XmlBuilder.GetComponentValue(cmbDbType2);  // returned value is always a string
      sValue := sValue + ' : ' + XmlBuilder.GetComponentValue(lblDatabase1);
      memoDescr.Text := sValue;
      medtCustom.Text := XmlBuilder.GetComponentValue(medtCustom);
    except
      on E: Exception do
      begin
        ShowMessage('Error occurred while saving the file.');
        logLine := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ': ' + E.Message + sLineBreak;
        TFile.AppendAllText('logs.txt', logLine);
      end;
    end;
  finally
    XmlBuilder.Free;
  end;
end;
{$endregion}

{$region 'Tag option'}
procedure TFormDemo.LoadConfigWithTagOption;
var
  XmlBuilder: TComponentXmlBuilder;
  logLine, sValue: string;
begin
// action for loading xml file
  XmlBuilder := TComponentXmlBuilder.CreateWithTags(pnlMain, FDictMarkers);
  try
    try
      XmlBuilder.OnDecodeText := StringDecode;
      XmlBuilder.AddToReadList(cmbDbType2); // add controls which values should be put into readlist instead of loading to component itself
      XmlBuilder.AddToReadList(medtCustom); // TMaskEdit is not supported so it will not be loaded until read explicitly
      XmlBuilder.AddToReadList(lblDatabase1); // dummy component

      XmlBuilder.LoadXml('panel.xml');

      // components on custom list will not be updated with read values, their values need to be get individually
      sValue := XmlBuilder.GetComponentValue(cmbDbType2);  // returned value is always a string
      sValue := sValue + ' : ' + XmlBuilder.GetComponentValue(lblDatabase1);
      memoDescr.Text := sValue;
      medtCustom.Text := XmlBuilder.GetComponentValue(medtCustom);
    except
      on E: Exception do
      begin
        logLine := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ': ' + E.Message + sLineBreak;
        TFile.AppendAllText('logs.txt', logLine);
      end;
    end;
  finally
    XmlBuilder.Free;
  end;
end;

procedure TFormDemo.SaveXmlWithTagOption;
var
  XmlBuilder: TComponentXmlBuilder;
  logLine: string;
begin
// action for saving xml file
  XmlBuilder := TComponentXmlBuilder.CreateWithTags(pnlMain, FDictMarkers);
  try
    try
      XmlBuilder.WithTabOrder := True; // optional ordering param (default True)
      XmlBuilder.BoolStrValue := True; // ckeckbox value format: False - 1/0; True - true/false (default False)
      XmlBuilder.OnEncodeText := StringEncode;

      // component custom value save (Text instead of ItemIndex)
      XmlBuilder.AddCustomComponentValue(cmbDbType2, cmbDbType2.Text);
      XmlBuilder.AddCustomComponentValue(medtCustom, medtCustom.Text); // TMaskEdit is not supported but can be custom saved

      if chkDefDescr.Checked then
        XmlBuilder.AddCustomComponentValue(memoDescr, 'This is default description.'); // overwrite value

      XmlBuilder.AddCustomComponentValue(lblDatabase1, 'Static text'); // use dummy component for static text

      XmlBuilder.SaveXml('panel.xml');
    except
      on E: Exception do
      begin
        ShowMessage('Error occurred while saving the file.');
        logLine := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ': ' + E.Message + sLineBreak;
        TFile.AppendAllText('logs.txt', logLine);
      end;
    end;
  finally
    XmlBuilder.Free;
  end;
end;

procedure TFormDemo.SetDictMarkers;
begin
  if not Assigned(FDictMarkers) then Exit;

  // defining realtion between tag numbers and node names
  FDictMarkers.Add(Ord(xmConfiguration), 'CONFIGURATION');
  FDictMarkers.Add(Ord(xmDatabase1), 'DATABASE_1');
  FDictMarkers.Add(Ord(xmDatabase2), 'DATABASE_2');
  FDictMarkers.Add(Ord(xmGeneral), 'GENERAL');
  FDictMarkers.Add(Ord(xmActive), 'ACTIVE');
  FDictMarkers.Add(Ord(xmDbType), 'DB_TYPE');
  FDictMarkers.Add(Ord(xmUsername), 'USERNAME');
  FDictMarkers.Add(Ord(xmPassword), 'PASSWORD');
  FDictMarkers.Add(Ord(xmServer), 'SERVER');
  FDictMarkers.Add(Ord(xmPort), 'PORT');
  FDictMarkers.Add(Ord(xmDescription), 'DESCRIPTION');
  FDictMarkers.Add(Ord(xmUseOption), 'USE_OPTION');
  FDictMarkers.Add(Ord(xmCustomText), 'CUSTOM_TEXT');
  FDictMarkers.Add(Ord(xmLabel), 'LABEL');
  FDictMarkers.Add(Ord(xmPageControl), 'PAGES');
  FDictMarkers.Add(Ord(xmPage1), 'PAGE_1');
  FDictMarkers.Add(Ord(xmPage2), 'PAGE_2');
  FDictMarkers.Add(Ord(xmPage1Edt), 'P1_TEXT');
  FDictMarkers.Add(Ord(xmPage2Edt), 'P2_TEXT');
  FDictMarkers.Add(Ord(xmPage3Edt), 'P3_TEXT');
end;

procedure TFormDemo.SetTags;
begin
  // setting compontents tags - this will define related xml elements
  pnlMain.Tag := Ord(xmConfiguration);
  grpbxGeneral.Tag := Ord(xmGeneral);

  {$region 'pnlDatabase1'}
    pnlDatabase1.Tag := Ord(xmDatabase1);
    chkActive1.Tag   := Ord(xmActive);
    cmbDbType1.Tag   := Ord(xmDbType);
    edtUser1.Tag     := Ord(xmUsername);
    edtPassword1.Tag := Ord(xmPassword);
    edtServer1.Tag   := Ord(xmServer);
    sePort1.Tag      := Ord(xmPort);

    edtPassword1.PasswordChar := '*'; // if PasswordChar is set, TComponentXmlBuilder will use assigned OnEncodeText, OnDecodeText functions for encryption
  {$endregion}

  {$region 'pnlDatabase2'}
    pnlDatabase2.Tag := Ord(xmDatabase2);
    chkActive2.Tag   := Ord(xmActive);
    cmbDbType2.Tag   := Ord(xmDbType);  // this control will be custom saved but still needs binding with element name
    edtUser2.Tag     := Ord(xmUsername);
    edtPassword2.Tag := Ord(xmPassword);
    edtServer2.Tag   := Ord(xmServer);
    sePort2.Tag      := Ord(xmPort);

    edtPassword2.PasswordChar := '*';
  {$endregion}

  {$region 'grpbxGeneral'}
    memoDescr.Tag      := Ord(xmDescription);
    rdgrpUseOption.Tag := Ord(xmUseOption);
    medtCustom.Tag     := Ord(xmCustomText); // TMaskEdit is not supported but can be custom saved

    chkDefDescr.Tag := -1; // -1 is not in FDictMarkers so the control will not be saved
  {$endregion}

  {$region 'PageControl'}
    PageControl1.Tag := Ord(xmPageControl);
    pnlTs1.Tag := Ord(xmPage1);
    edtTs1.Tag := Ord(xmPage1Edt);
    pnlTs2.Tag := Ord(xmPage2);
    edtTs2.Tag := Ord(xmPage2Edt);
    edtTs3.Tag := Ord(xmPage3Edt);
  {$endregion}

  lblDatabase1.Tag := Ord(xmLabel); // TLabel has no edit value but can be used with custom save as dummy for static text
end;
{$endregion}

procedure TFormDemo.SetTabOrder;
begin
  //(OPTIONAL) set order in which elements will be saved
  grpbxGeneral.TabOrder := 0;
  pnlDatabase1.TabOrder := 1;
  pnlDatabase2.TabOrder := 2;

  {$region 'pnlDatabase1'}
    chkActive1.TabOrder   := 0;
    cmbDbType1.TabOrder   := 1;
    edtUser1.TabOrder     := 2;
    edtPassword1.TabOrder := 3;
    edtServer1.TabOrder   := 4;
    sePort1.TabOrder      := 5;
  {$endregion}

  {$region 'pnlDatabase2'}
    chkActive2.TabOrder   := 0;
    cmbDbType2.TabOrder   := 1;
    edtUser2.TabOrder     := 2;
    edtPassword2.TabOrder := 3;
    edtServer2.TabOrder   := 4;
    sePort2.TabOrder      := 5;
  {$endregion}

  {$region 'grpbxGeneral'}
    memoDescr.TabOrder      := 0;
    rdgrpUseOption.TabOrder := 1;
    medtCustom.TabOrder     := 2;
  {$endregion}

  // lblDatabase1 - TLabel has no TabOrder property so it will not be ordered
  // if ordering is needed, use components with TabOrder
end;

end.
