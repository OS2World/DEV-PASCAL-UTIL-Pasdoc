{ @abstract(defines all items that can appear within a Pascal unit's interface)
  @created(11 Mar 1999)
  @cvs($Date: 2004/05/06 19:50:31 $)
  @author(Johannes Berg <johannes@sipsolutions.de>)
  @author(Ralf Junker (delphi@zeitungsjunge.de))
  @author(Marco Schmidt (marcoschmidt@geocities.com))

For each type, variable, class etc. (short: item) that may appear in a Pascal
source code file and can thus be taken into the documentation, this unit
provides an object type which will store name, unit, description and more
on this item. }

unit PasDoc_Items;

interface

uses
  StringVector,
  ObjectVector,
  Hashes,
  Classes,
  PasDoc_Serialize;

type
  { Accessibility of a field/method }
  { DO NOT CHANGE THE ORDER OF THESE FIELDS WITHOUT ADAPTING THE STRING
    TABLE BELOW - Carl
  }
  TAccessibility = (
    { indicates field or method is published }
    STATE_PUBLISHED,
    { indicates field or method is public }
    STATE_PUBLIC,
    { indicates field or method is protected }
    STATE_PROTECTED,
    { indicates field or method is private }
    STATE_PRIVATE,
    { indicates field or method is automated }
    STATE_AUTOMATED
    );

  TAccessibilities = set of TAccessibility;
  
const
  AccessibilityStr: Array[STATE_PUBLISHED..STATE_AUTOMATED] of string[16] =
  (
   'published',
   'public',
   'protected',
   'private',
   'automated'
  );

type
  TPasCio = class;
  TPasMethod = class;
  TPasProperty = class;
  TPasUnit = class;

  TPasItems = class;
  TPasMethods = class;
  TPasProperties = class;

  { basic linkable item in pasdoc hierarchy }
  TPasItem = class(TSerializable)
  protected
    FFullLink: string;
    FLastMod: string;
    FName: string;
    FState: TAccessibility;
    FMyObject: TPasCio;
    FMyUnit: TPasUnit;
    FDeprecated: boolean;
    FPlatform: boolean;
    FAbbreviations: TStringList;
    { list of strings, each representing one author of this item }
    FAuthors: TStringVector;
    { if assigned, contains string with date of creation }
    FCreated: string;
    procedure Unabbreviate(var s: string);
    procedure SetAuthors(const Value: TStringVector);
    procedure Serialize(const ADestination: TStream); override;
    procedure Deserialize(const ASource: TStream); override;
  public
    // THIS IS A BAD HACK
    FDescription: string;
    FDetailedDescription: string;
    { }
    constructor Create; override;
    destructor Destroy; override;

    procedure DescriptionExtractTag(var ADescription: string; const Offs1,
      Offs2, Offs3: Integer; var s: string);
    function DescriptionFindTag(const ADescription, TagName: string; var
      Offs1, Offs2, Offs3: Integer): Boolean;
    function DescriptionFindTagParameters(const ADescription: string; var
      Offs1, Offs2: Integer): Boolean;
    function DescriptionGetTagName(const ADescription: string; var Offset:
      Integer): string;
    procedure DescriptionGetTag(var ADescription: string; const Remove:
      Boolean; const Offs1, Offs2, Offs3: Integer; var s: string);

    function FindItem(const ItemName: string): TPasItem; virtual;
    { }
    function FindName(S1, S2, S3: string; n: Integer): TPasItem; virtual;
    { Returns DetailedDescription if available, otherwise Description,
      otherwise nil. }
    function GetDescription: string;
    { Searches for an abstract tag within the Description field of
      this item. If one is found, Description is copied to DetailedDescription
      and the abstract tag becomes the new Description. This procedure
      should be called after the dates (created and lastmod) and the
      author tags have been handled, as they are searched in Description. }
    procedure HandleAbstractTag;
    { }
    procedure HandleAuthorTags;
    { }
    procedure HandleCreatedTag;
    { }
    procedure HandleLastModTag;
    { }
    procedure HandleCVSTag;
    { handles a @@param tag }
    procedure HandleParamTag; virtual;
    { handles a @@returns tag }
    procedure HandleReturnsTag; virtual;
    { handles a @@raises tag }
    procedure HandleRaisesTag; virtual;
    property Abbreviations: TStringList read FAbbreviations write FAbbreviations;
    { Returns true if there is a detailled or a normal description available. }
    function HasDescription: Boolean;
    { returns the qualified name of the item }
    function QualifiedName: String;

    { pointer to unit this item belongs to }
    property MyUnit: TPasUnit read FMyUnit write FMyUnit;
    { if this item is part of an object or class, the corresponding info object is stored here, nil otherwise }
    property MyObject: TPasCio read FMyObject write FMyObject;

    { description of this item, a single sentence }
    property Description: string read FDescription write FDescription;
    { more detailed description of this item, mostly more than one
      sentence }
    property DetailedDescription: string read FDetailedDescription write FDetailedDescription;
    { a full link that should be enough to link this item from anywhere else }
    property FullLink: string read FFullLink write FFullLink;
    { if assigned, contains string with date of last modification }
    property LastMod: string read FLastMod write FLastMod;
    { name of the item }
    property Name: string read FName write FName;
    { One of the STATE_xxx constants, determines access rights
      (public, private, etc.). }
    property State: TAccessibility read FState write FState;
    { is this item deprecated? }
    property IsDeprecated: boolean read FDeprecated write FDeprecated;
    { is this item platform specific? }
    property IsPlatform: boolean read FPlatform write FPlatform;
    property Authors: TStringVector read FAuthors write SetAuthors;
    property Created: string read FCreated;
  end;

  { @abstract(used for constants/variables) }
  TPasVarConst = class(TPasItem)
  protected
    FFullDeclaration: string;
    procedure Serialize(const ADestination: TStream); override;
    procedure Deserialize(const ASource: TStream); override;
  public
    { full declaration, including type, default values, etc }
    property FullDeclaration: string read FFullDeclaration write FFullDeclaration;
  end;

  { @abstract(Enumerated types) }
  TPasEnum = class(TPasVarConst)
  protected
    FMembers: TPasItems;
    procedure Serialize(const ADestination: TStream); override;
    procedure Deserialize(const ASource: TStream); override;
  public
    destructor Destroy; override;
    constructor Create; override;
    property Members: TPasItems read FMembers;
  end;

  { ---------------------------------------------------------------------------- }

  { Methodtype for @link(TPasMethod) }
  TMethodType = (METHOD_CONSTRUCTOR, METHOD_DESTRUCTOR,
    METHOD_FUNCTION_PROCEDURE);

  { extends @link(TPasItem) to store method and function-/procedure-specific
    information }
  TPasMethod = class(TPasItem)
  protected
    FParams: TStringVector;
    FReturns: string;
    FRaises: TStringVector;
    FFullDecl: string;
    FWhat: TMethodType;
    procedure Serialize(const ADestination: TStream); override;
    procedure Deserialize(const ASource: TStream); override;
    procedure SetParams(const Value: TStringVector);
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure HandleParamTag; override;
    procedure HandleReturnsTag; override;
    procedure HandleRaisesTag; override;
    { full declaration, including parameter list and procedural directives }
    property FullDeclaration: string read FFullDecl write FFullDecl;
    { }
    property What: TMethodType read FWhat write FWhat;
    property Params: TStringVector read FParams write SetParams;
    property Returns: string read FReturns;
    property Raises: TStringVector read FRaises;
  end;

  TPasProperty = class(TPasItem)
  protected
    FDefault: Boolean;
    FNoDefault: Boolean;
    FIndexDecl: string;
    FStoredID: string;
    FDefaultID: string;
    FWriter: string;
    FFullDeclaration: string;
    FPropType: string;
    FReader: string;
    procedure Serialize(const ADestination: TStream); override;
    procedure Deserialize(const ASource: TStream); override;
  public
    { full declaration, including read/write and storage specifiers }
    property FullDeclaration: string read FFullDeclaration write FFullDeclaration;
    { contains the optional index declaration, including brackets }
    property IndexDecl: string read FIndexDecl write FIndexDecl;
    { contains the type of the property }
    property Proptype: string read FPropType write FPropType;
    { read specifier }
    property Reader: string read FReader write FReader;
    { write specifier }
    property Writer: string read FWriter write FWriter;
    { true if the property is the default property }
    property Default: Boolean read FDefault write FDefault;
    { keeps default value specifier }
    property DefaultID: string read FDefaultID write FDefaultID;
    { true if Nodefault property }
    property NoDefault: Boolean read FNoDefault write FNoDefault;
    { keeps Stored specifier }
    property StoredId: string read FStoredID write FStoredID;
  end;

  { enumeration type to determine type of TObjectInfo item: class,
    interface or object }
  TCIOType = (CIO_CLASS, CIO_SPINTERFACE, CIO_INTERFACE, CIO_OBJECT, CIO_RECORD, CIO_PACKEDRECORD);

  { Extends @link(TPasItem) to store all items in a class / an object, e.g.
    fields. }
  TPasCio = class(TPasItem)
  protected
    FFields: TPasItems;
    FMethods: TPasMethods;
    FProperties: TPasProperties;
    FAncestors: TStringVector;
    FOutputFileName: string;
    FMyType: TCIOType;
    procedure Serialize(const ADestination: TStream); override;
    procedure Deserialize(const ASource: TStream); override;
  public
    constructor Create; override;
    destructor Destroy; override;

    { Simply returns the result of a call to @link(FindFieldMethodProperty). }
    function FindItem(const ItemName: string): TPasItem; override;
    { If this class (or interface or object) contains a field, method or
      property with the name of ItemName, the corresponding item pointer is
      returned. }
    function FindFieldMethodProperty(const ItemName: string): TPasItem;

    procedure SortPasItems;
  public
    { name of the ancestor class / object }
    property Ancestors: TStringVector read FAncestors;
    { list of all fields }
    property Fields: TPasItems read FFields;
    { list of all methods }
    property Methods: TPasMethods read FMethods;
    { list of properties }
    property Properties: TPasProperties read FProperties;
    { determines if this is a class, an interface or an object }
    property MyType: TCIOType read FMyType write FMyType;
    { name of documentation output file (if each class / object gets
      its own file, that's the case for HTML, but not for TeX) }
    property OutputFileName: string read FOutputFileName write FOutputFileName;
  end;

  { extends @link(TPasItem) to store anything about a unit, its constants,
    types etc.; also provides methods for parsing a complete unit }
  TPasUnit = class(TPasItem)
  protected
    FTypes: TPasItems;
    FVariables: TPasItems;
    FCIOs: TPasItems;
    FConstants: TPasItems;
    FFuncsProcs: TPasMethods;
    FUsesUnits: TStringVector;
    FSourceFilename: string;
    FOutputFileName: string;
    FSourceFileDate: TDateTime;
    procedure Serialize(const ADestination: TStream); override;
    procedure Deserialize(const ASource: TStream); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure AddCIO(const i: TPasCio);
    procedure AddConstant(const i: TPasItem);
    procedure AddType(const i: TPasItem);
    procedure AddVariable(const i: TPasItem);
    function FindFieldMethodProperty(const S1, S2: string): TPasItem;
    function FindItem(const ItemName: string): TPasItem; override;

    procedure SortPasItems;
  public
    { list of classes and objects defined in this unit }
    property CIOs: TPasItems read FCIOs;
    { list of constants defined in this unit }
    property Constants: TPasItems read FConstants;
    { list of functions and procedures defined in this unit }
    property FuncsProcs: TPasMethods read FFuncsProcs;
    { the names of all units mentioned in a uses clause in the interface
      section of this unit }
    property UsesUnits: TStringVector read FUsesUnits;
    { list of types defined in this unit }
    property Types: TPasItems read FTypes;
    { list of variables defined in this unit }
    property Variables: TPasItems read FVariables;
    { name of documentation output file
      THIS SHOULD NOT BE HERE! }
    property OutputFileName: string read FOutputFileName write FOutputFileName;
    property SourceFileName: string read FSourceFilename write FSourceFilename;

    property SourceFileDate: TDateTime read FSourceFileDate write FSourceFileDate; 
  end;

  { ---------------------------------------------------------------------------- }

  { Container class to store a list of @link(TPasItem)s. }
  TPasItems = class(TObjectVector)
  private
    FHash: TObjectHash;
    function GetPasItemAt(const AIndex: Integer): TPasItem;
    procedure SetPasItemAt(const AIndex: Integer; const Value: TPasItem);
    procedure Serialize(const ADestination: TStream);
    procedure Deserialize(const ASource: TStream);
  public
    { Copies all Items from c to this object, not changing c at all. }
    procedure CopyItems(const c: TPasItems);
    { Counts classes, interfaces and objects within this collection. }
    procedure CountCIO(var c, i, o: Integer);
    { Compares each element's name field with Name and returns the item on
      success, nil otherwise.
      Name's case is not regarded. }
    function FindName(const AName: string): TPasItem;
    { Inserts all items of C into this collection.
      Disposes C and sets it to nil. }
    procedure InsertItems(const c: TPasItems);
    { Checks each element's State field and removes all elements with a value
      of STATE_PRIVATE. }
    procedure RemovePrivateItems;

    property PasItemAt[const AIndex: Integer]: TPasItem read GetPasItemAt
      write SetPasItemAt;

    procedure SortByPasItemName;

    procedure Add(const AObject: TPasItem);
    procedure DeleteAt(const AIndex: Integer);
    constructor Create(const AOwnsObject: Boolean); override;
    destructor Destroy; override;
    procedure Clear; override;
  end;

  { ---------------------------------------------------------------------------- }

  { @Name holds a collection of methods. It introduces no
    new methods compared to @link(TPasItems), but this may be
    implemented in a later stage. }
  TPasMethods = class(TPasItems)
  end;

  { @Name holds a collection of properties. It introduces no
    new methods compared to @link(TPasItems), but this may be
    implemented in a later stage. }
  TPasProperties = class(TPasItems)
  end;

  { ---------------------------------------------------------------------------- }
  { TPasUnits }
  { ---------------------------------------------------------------------------- }

  { @abstract(Holds a collection of units.) }
  TPasUnits = class(TPasItems)
  private
    function GetUnitAt(const AIndex: Integer): TPasUnit;
    procedure SetUnitAt(const AIndex: Integer; const Value: TPasUnit);
  public
    property UnitAt[const AIndex: Integer]: TPasUnit
      read GetUnitAt
      write SetUnitAt;
    function ExistsUnit(const AUnit: TPasUnit): Boolean;
  end;

const
  CIO_NonHierarchy = [Low(TCIOType)..High(TCIOType)] - [CIO_CLASS, CIO_SPINTERFACE, CIO_INTERFACE, CIO_OBJECT];

implementation

uses
  SysUtils;

function ComparePasItemsByName(PItem1, PItem2: Pointer): Integer;
begin
  Result := CompareText(TPasItem(PItem1).Name, TPasItem(PItem2).Name);
  // Sort duplicate class names by unit name if available.
  if (Result = 0) and
    (TObject(PItem1).ClassType = TPasCio) and
    (TObject(PItem2).ClassType = TPasCio) then
    if TPasCio(PItem1).MyUnit = nil then begin
      Result := -1
    end else begin
      if TPasCio(PItem2).MyUnit = nil then begin
        Result := 1
      end else begin
        Result := CompareText(TPasCio(PItem1).MyUnit.Name, TPasCio(PItem2).MyUnit.Name);
      end;
    end;
end;

function ComparePasMethods(PItem1, PItem2: Pointer): Integer;
var
  P1: TPasMethod;
  P2: TPasMethod;
begin
  P1 := TPasMethod(PItem1);
  P2 := TPasMethod(PItem2);
  { compare 'method type', order is constructor > destructor > visibility > function, procedure }
  if P1.What = P2.What then begin
    { if 'method type' is equal, compare names }
    if P1.State = P2.State then begin
      Result := CompareText(P1.Name, P2.Name)
    end else begin
      if P1.State < P2.State then begin
        Result := -1
      end else begin
        Result := 1;
      end;
    end;
  end else begin
    if P1.What < P2.What then begin
      Result := -1
    end else begin
      Result := 1;
    end;
  end;
end;

{ ---------------------------------------------------------------------------- }
{ TPasItem }
{ ---------------------------------------------------------------------------- }

destructor TPasItem.Destroy;
begin
  Authors.Free;
  inherited;
end;

procedure TPasItem.DescriptionExtractTag(var ADescription: string; const
  Offs1, Offs2, Offs3: Integer; var s: string);
begin
  DescriptionGetTag(ADescription, True, Offs1, Offs2, Offs3, s);
  Unabbreviate(s);
end;

function TPasItem.DescriptionFindTag(const ADescription, TagName: string; var
  Offs1, Offs2, Offs3: Integer): Boolean;
var
  i: Integer;
  j: Integer;
  s: string;
  l: Integer;
  LTagName: string;
begin
  Result := False;
  if ADescription = '' then Exit;
  LTagName := LowerCase(TagName);
  l := Length(ADescription);

  i := Offs1;

  if (ADescription[i] = '@') then begin
    if (i + 1 = l) then Exit;

    Offs1 := i;
    j := i + 1;
    s := DescriptionGetTagName(ADescription, j);

    if LTagName <> LowerCase(s) then Exit;

    Offs2 := j;
    Result := DescriptionFindTagParameters(ADescription, Offs2, Offs3);
  end;
end;

function TPasItem.DescriptionFindTagParameters(const ADescription: string; var
  Offs1, Offs2: Integer): Boolean;
var
  Counter: Integer;
  i: Integer;
  l: Integer;
begin
  Result := False;
  i := Offs1;
  l := Length(ADescription);
  if (i < 1) or (i > l) then Exit;

  while (i <= l) and (ADescription[i] <> '(') do
    Inc(i);
  if i > l then Exit; { no ( found }

  Offs1 := i;
  Inc(i);
  Counter := 1;
  repeat
    case ADescription[i] of
      '(': Inc(Counter);
      ')': Dec(Counter);
    end;
    Inc(i);
  until (i > l) or (Counter = 0);
  if (Counter = 0) then begin
    Offs2 := i - 1;
    Result := True;
  end;
end;

function TPasItem.DescriptionGetTagName(const ADescription: string; var
  Offset: Integer): string;
var
  l: Integer;
begin
  Result := '';
  l := Length(ADescription);
  while (Offset < l) and (ADescription[Offset] in ['A'..'Z', 'a'..'z']) do
    begin
    Result := Result + UpCase(ADescription[Offset]);
    Inc(Offset);
  end;
end;

procedure TPasItem.DescriptionGetTag(var ADescription: string; const Remove:
  Boolean; const Offs1, Offs2, Offs3: Integer; var s: string);
var
  l: Integer;
begin
  l := Offs3 - Offs2 - 1;
  if l < 0 then l := 0;
  s := Copy(ADescription, Offs2 + 1, l);
  if Remove then Delete(ADescription, Offs1, Offs3 - Offs1 + 1);
end;

function TPasItem.FindItem(const ItemName: string): TPasItem;
begin
  Result := nil;
end;

function TPasItem.FindName(S1, S2, S3: string; n: Integer): TPasItem;
var
  p: TPasItem;
  LS1: string;
begin
  Result := nil;
  LS1 := LowerCase(S1);
  case n of
    0: begin
        if Assigned(MyObject) then begin { this item is a method or field }
          p := MyObject.FindFieldMethodProperty(S1);
          if Assigned(p) then begin
            Result := p;
            Exit;
          end;
        end;

        if Assigned(MyUnit) then begin
          p := MyUnit.FindItem(S1);
          if Assigned(p) then begin
            Result := p;
            Exit;
          end;
        end;

        if Assigned(MyUnit) and (LS1 = LowerCase(MyUnit.Name)) then begin
          Result := MyUnit;
          Exit;
        end;

      end;

    1: begin
        if Assigned(MyObject) then begin
          if LowerCase(MyObject.Name) = LS1 then begin
            p := MyObject.FindFieldMethodProperty(S2);
            if Assigned(p) then begin
              Result := p;
              Exit;
            end;
          end;
        end;

        // RJ: To find links in Unit's objects!
        if Assigned(MyUnit) then begin
          p := MyUnit.FindFieldMethodProperty(S1, S2);
          if Assigned(p) then begin
            Result := p;
            Exit;
          end;
        end;
      end;
  end;
end;

function TPasItem.GetDescription: string;
begin
  if Length(DetailedDescription) > 0 then begin
    Result := DetailedDescription
  end else begin
    Result := Description
  end;
end;

{ ---------- }

procedure TPasItem.HandleAbstractTag;
var
  Offs1: Integer;
  Offs2: Integer;
  Offs3: Integer;
  s: string;
begin
  if DetailedDescription = '' then Exit;
  Offs1 := 1;

  while Offs1 < Length(DetailedDescription) do begin
    if (DetailedDescription[Offs1] = '@') and
      DescriptionFindTag(DetailedDescription, 'ABSTRACT', Offs1, Offs2, Offs3) then
    begin
      DescriptionExtractTag(FDetailedDescription, Offs1, Offs2, Offs3, s);
      if (Length(s) <= 0) then Continue;
      Description := s;
      Exit;
    end;
    Inc(Offs1);
  end;
end;

procedure TPasItem.HandleParamTag;
begin
  // does nothing for a normal TPasItem, but only for a TPasMethod
end;

procedure TPasItem.HandleReturnsTag;
begin
  // does nothing for a normal TPasItem, but only for a TPasMethod
end;

procedure TPasItem.HandleRaisesTag;
begin
  // does nothing for a normal TPasItem, but only for a TPasMethod
end;

{ ---------- }

procedure TPasItem.HandleAuthorTags;
var
  Offs1: Integer;
  Offs2: Integer;
  Offs3: Integer;
  s: string;
  l: Integer;
begin
  if DetailedDescription = '' then Exit;
  Offs1 := 1;
  l := Length(DetailedDescription);
  { we could have more than one author, so repeat until we have all }
  while Offs1 < l do begin
    if (DetailedDescription[Offs1] = '@') and
      DescriptionFindTag(DetailedDescription, 'AUTHOR', Offs1, Offs2, Offs3) then
        begin
          { we found one, remove it from the description and add it to the author list }
      DescriptionExtractTag(FDetailedDescription, Offs1, Offs2, Offs3, s);
      l := Length(DetailedDescription);
      if s <> '' then begin
        if Authors = nil then FAuthors := NewStringVector;
        Authors.Add(s);
      end;
    end;
    Inc(Offs1);
  end;
end;

procedure TPasItem.HandleCreatedTag;
var
  Offs1: Integer;
  Offs2: Integer;
  Offs3: Integer;
  l: Integer;
begin
  if DetailedDescription = '' then Exit;
  Offs1 := 1;
  l := Length(DetailedDescription);
  while Offs1 < l do begin
    if (DetailedDescription[Offs1] = '@') and
      DescriptionFindTag(DetailedDescription, 'CREATED', Offs1, Offs2, Offs3) then
        begin
      DescriptionExtractTag(FDetailedDescription, Offs1, Offs2, Offs3, FCreated);
      Exit;
    end;
    Inc(Offs1);
  end;
end;

procedure TPasItem.HandleLastModTag;
var
  Offs1: Integer;
  Offs2: Integer;
  Offs3: Integer;
  l: Integer;
begin
  if DetailedDescription = '' then Exit;
  Offs1 := 1;
  l := Length(DetailedDescription);
  while Offs1 < l do begin
    if (DetailedDescription[Offs1] = '@') and
      DescriptionFindTag(DetailedDescription, 'LASTMOD', Offs1, Offs2, Offs3) then
        begin
      DescriptionExtractTag(FDetailedDescription, Offs1, Offs2, Offs3, FLastMod);
      Exit;
    end;
    Inc(Offs1);
  end;
end;

function TPasItem.HasDescription: Boolean;
begin
  HasDescription := (Description <> '') or (DetailedDescription <> '');
end;

{ ---------------------------------------------------------------------------- }
{ TPasItems }
{ ---------------------------------------------------------------------------- }

procedure TPasItems.CopyItems(const c: TPasItems);
var
  i: Integer;
begin
  if ObjectVectorIsNilOrEmpty(c) then Exit;
  for i := 0 to c.Count - 1 do
    Add(TPasItem(c.GetPasItemAt(i)));
end;

{ ---------------------------------------------------------------------------- }

procedure TPasItems.CountCIO(var c, i, o: Integer);
var
  j: Integer;
begin
  c := 0;
  i := 0;
  o := 0;

  for j := 0 to Count - 1 do
    case TPasCio(GetPasItemAt(j)).MyType of
      CIO_CLASS:
        Inc(c);
      CIO_INTERFACE:
        Inc(i);
      CIO_OBJECT:
        Inc(o);
    end;
end;

{ ---------------------------------------------------------------------------- }

constructor TPasItems.Create(const AOwnsObject: Boolean);
begin
  inherited;
  FHash := TObjectHash.Create;
end;

procedure TPasItems.DeleteAt(const AIndex: Integer);
var
  LObj: TPasItem;
begin
  LObj := GetPasItemAt(AIndex);
  FHash.Delete(LowerCase(LObj.Name));
  inherited DeleteAt(AIndex);
end;

destructor TPasItems.Destroy;
begin
  FHash.Free;
  FHash := nil;
  inherited;
end;

function TPasItems.FindName(const AName: string): TPasItem;
begin
  Result := nil;
  if Length(AName) > 0 then begin
    result := TPasItem(FHash.Items[LowerCase(AName)]);
  end;
end;

{ ---------------------------------------------------------------------------- }

function TPasItems.GetPasItemAt(const AIndex: Integer): TPasItem;
begin
  Result := TPasItem(Items[AIndex]);
end;

{ ---------------------------------------------------------------------------- }

procedure TPasItems.InsertItems(const c: TPasItems);
var
  i: Integer;
begin
  if ObjectVectorIsNilOrEmpty(c) then Exit;
  for i := 0 to c.Count - 1 do
    Add(TPasItem(c.Items[i]));
end;

{ ---------------------------------------------------------------------------- }

procedure TPasItems.Add(const AObject: TPasItem);
begin
  inherited Insert(AObject);
  FHash.Items[LowerCase(AObject.Name)] := AObject;
end;

procedure TPasItems.RemovePrivateItems;
var
  i: Integer;
  Item: TPasItem;
begin
  i := 0;
  while (i < Count) do begin
    Item := PasItemAt[i];
    if Assigned(Item) and (Item.State = STATE_PRIVATE) then
      DeleteAt(i)
    else
      Inc(i);
  end;
end;

{ TPasCio }

destructor TPasCio.Destroy;
begin
  Ancestors.Free;
  Fields.Free;
  Methods.Free;
  Properties.Free;
  inherited;
end;

{ ---------------------------------------------------------------------------- }

function TPasCio.FindItem(const ItemName: string): TPasItem;
begin
  FindItem := FindFieldMethodProperty(ItemName);
end;

{ ---------------------------------------------------------------------------- }

function TPasCio.FindFieldMethodProperty(const ItemName: string): TPasItem;
begin
  if Fields <> nil then begin
    Result := Fields.FindName(ItemName);
    if Result <> nil then Exit;
  end;

  if Methods <> nil then begin
    Result := Methods.FindName(ItemName);
    if Result <> nil then Exit;
  end;

  if Properties <> nil then begin
    Result := Properties.FindName(ItemName);
    if Result <> nil then Exit;
  end;

  Result := nil;
end;

{ ---------------------------------------------------------------------------- }

procedure TPasCio.SortPasItems;
begin
  if Fields <> nil then Fields.SortByPasItemName;
  if Methods <> nil then Methods.Sort(@ComparePasMethods);
  if Properties <> nil then Properties.SortByPasItemName;
end;

{ ---------------------------------------------------------------------------- }
{ TPasUnit }
{ ---------------------------------------------------------------------------- }

destructor TPasUnit.Destroy;
begin
  FCIOs.Free;
  FConstants.Free;
  FFuncsProcs.Free;
  FTypes.Free;
  FUsesUnits.Free;
  FVariables.Free;
  inherited;
end;

procedure TPasUnit.AddCIO(const i: TPasCio);
begin
  CIOs.Add(i);
end;

procedure TPasUnit.AddConstant(const i: TPasItem);
begin
  Constants.Add(i);
end;

procedure TPasUnit.AddType(const i: TPasItem);
begin
  Types.Add(i);
end;

procedure TPasUnit.AddVariable(const i: TPasItem);
begin
  Variables.Add(i);
end;

function TPasUnit.FindFieldMethodProperty(const S1, S2: string): TPasItem;
var
  PI: TPasItem;
  po: TPasCio;
begin
  Result := nil;
  if CIOs = nil then Exit;

  po := TPasCio(CIOs.FindName(S1));
  if Assigned(po) then begin
    PI := po.FindFieldMethodProperty(S2);
    if Assigned(PI) then FindFieldMethodProperty := PI;
  end;
end;

function TPasUnit.FindItem(const ItemName: string): TPasItem;
{ // these belong to the commented out code below
var
  i: Integer;
  CioItem: TPasCio;
}
begin
  if LowerCase(Name) = LowerCase(ItemName) then begin
    Result := Self;
    Exit;
  end;

  if Constants <> nil then begin
    Result := Constants.FindName(ItemName);
    if Result <> nil then Exit;
  end;

  if Types <> nil then begin
    Result := Types.FindName(ItemName);
    if Result <> nil then Exit;
  end;

  if Variables <> nil then begin
    Result := Variables.FindName(ItemName);
    if Result <> nil then Exit;
  end;

  if FuncsProcs <> nil then begin
    Result := FuncsProcs.FindName(ItemName);
    if Result <> nil then Exit;
  end;

  if CIOs <> nil then begin
    Result := CIOs.FindName(ItemName);
    if Result <> nil then Exit;
  end;
{ // JMB: I removed this so that no cross-linking between units would occur
  // for simple properties etc. Yes, it means you have to do more typing,
  // but it also makes linking much more sensible
  if CIOs <> nil then
    for i := 0 to CIOs.Count - 1 do begin
      CioItem := TPasCio(CIOs.PasItemAt[i]);
      if CioItem <> nil then begin
        Result := CioItem.FindFieldMethodProperty(ItemName);
        if Result <> nil then Exit;
      end;
    end;
}
  Result := nil;
end;

{ ---------------------------------------------------------------------------- }
{ TPasUnits }
{ ---------------------------------------------------------------------------- }

function TPasUnits.ExistsUnit(const AUnit: TPasUnit): Boolean;
begin
  Result := FindName(AUnit.Name) <> nil;
end;

{ ---------------------------------------------------------------------------- }

function TPasUnits.GetUnitAt(const AIndex: Integer): TPasUnit;
begin
  Result := TPasUnit(Items[AIndex]);
end;

{ ---------------------------------------------------------------------------- }

procedure TPasUnits.SetUnitAt(const AIndex: Integer; const Value: TPasUnit);
begin
  Items[AIndex] := Value;
end;

{ ---------------------------------------------------------------------------- }

procedure TPasItems.SetPasItemAt(const AIndex: Integer; const Value:
  TPasItem);
begin
  Items[AIndex] := Value;
end;

procedure TPasItems.SortByPasItemName;
begin
  Sort(@ComparePasItemsByName);
end;

function TPasItem.QualifiedName: String;
begin
  Result := '';
  if MyUnit <> nil then begin
    Result := Result + MyUnit.Name + '.';
  end;
  if MyObject <> nil then begin
    Result := Result + MyObject.Name + '.';
  end;
  Result := Result + Name;
end;

procedure TPasUnit.SortPasItems;
var
  i: Integer;
begin
  if CIOs <> nil then
    begin
      CIOs.SortByPasItemName;
      { Also sort Fields / Methods / Properties of each CIO. }
      for i := 0 to CIOs.Count - 1 do
        TPasCio(CIOs.PasItemAt[i]).SortPasItems;
    end;
  if Constants <> nil then Constants.SortByPasItemName;
  if FuncsProcs <> nil then FuncsProcs.SortByPasItemName;
  if Types <> nil then Types.SortByPasItemName;
  if Variables <> nil then Variables.SortByPasItemName;
end;

procedure TPasItem.HandleCVSTag;
var
  Offs1: Integer;
  Offs2: Integer;
  Offs3: Integer;
  l: Integer;
  LTagData: string;
begin
  if DetailedDescription = '' then Exit;
  Offs1 := 1;
  l := Length(DetailedDescription);
  while Offs1 < l do begin
    if (DetailedDescription[Offs1] = '@') and
        DescriptionFindTag(DetailedDescription, 'CVS', Offs1, Offs2, Offs3) then begin
      DescriptionExtractTag(FDetailedDescription, Offs1, Offs2, Offs3, LTagData);
      l := length(DetailedDescription);
      if Length(LTagData)>1 then begin
        case LTagData[2] of
          'D': begin
                 if Copy(LTagData,1,7) = '$Date: ' then begin
                   LastMod := Trim(Copy(LTagData, 7, Length(LTagData)-7-1)) + ' UTC';
                 end;
               end;
          'A': begin
                 if Copy(LTagData,1,9) = '$Author: ' then begin
                   LTagData := Trim(Copy(LTagData, 9, Length(LTagData)-9-1));
                   Unabbreviate(LTagData);
                   if Length(LTagData) > 0 then begin
                     if not Assigned(Authors) then FAuthors := NewStringVector;
                     Authors.AddNotExisting(LTagData);
                   end;
                 end;
               end;
          else begin
          end;
        end;
      end;
    end;
    Inc(Offs1);
  end;
end;

procedure TPasItem.Unabbreviate(var s: string);
var
  idx: Integer;
begin
  if Assigned(Abbreviations) then begin
    idx := Abbreviations.IndexOfName(s);
    if idx>=0 then begin
      s := Abbreviations.Values[s];
    end;
  end;
end;

constructor TPasCio.Create;
begin
  inherited;
  FFields := TPasItems.Create(True);
  FMethods := TPasMethods.Create(True);
  FProperties := TPasProperties.Create(True);
  FAncestors := TStringVector.Create;
end;

procedure TPasCio.Deserialize(const ASource: TStream);
begin
  inherited;
  FFields.Deserialize(ASource);
  FMethods.Deserialize(ASource);
  FProperties.Deserialize(ASource);
  Ancestors.Text := LoadStringFromStream(ASource);
  FOutputFileName := LoadStringFromStream(ASource);
  ASource.Read(FMyType, SizeOf(FMyType));
end;

procedure TPasCio.Serialize(const ADestination: TStream);
begin
  inherited;
  FFields.Serialize(ADestination);
  FMethods.Serialize(ADestination);
  FProperties.Serialize(ADestination);
  SaveStringToStream(Ancestors.Text, ADestination);
  SaveStringToStream(FOutputFileName, ADestination);
  ADestination.Write(FMyType, SizeOf(FMyType));
end;

{ TPasEnum }

constructor TPasEnum.Create;
begin
  inherited Create;
  FMembers := TPasItems.Create(True);
end;

procedure TPasEnum.Deserialize(const ASource: TStream);
begin
  inherited;
  Members.Deserialize(ASource);
end;

destructor TPasEnum.Destroy;
begin
  FMembers.Free;
  inherited;
end;

procedure TPasItem.SetAuthors(const Value: TStringVector);
begin
  FAuthors.Assign(Value);
end;

constructor TPasUnit.Create;
begin
  inherited Create;
  FTypes := TPasItems.Create(True);
  FVariables := TPasItems.Create(True);
  FCIOs := TPasItems.Create(True);
  FConstants := TPasItems.Create(True);
  FFuncsProcs := TPasMethods.Create(True);
  FUsesUnits := TStringVector.Create;
end;

constructor TPasItem.Create;
begin
  inherited Create;
  FAuthors := TStringVector.Create;
end;

procedure TPasEnum.Serialize(const ADestination: TStream);
begin
  inherited;
  Members.Serialize(ADestination);
end;

{ TPasMethod }

destructor TPasMethod.Destroy;
begin
  FParams.Free;
  FRaises.Free;
  inherited Destroy;
end;

procedure TPasMethod.HandleRaisesTag;
var
  Offs1: Integer;
  Offs2: Integer;
  Offs3: Integer;
  s: string;
  l: Integer;
begin
  if DetailedDescription = '' then Exit;
  Offs1 := 1;
  l := Length(DetailedDescription);
  { we could have more than one parameter, so repeat until we have all }
  while Offs1 < l do begin
    if (DetailedDescription[Offs1] = '@') and
      DescriptionFindTag(DetailedDescription, 'RAISES', Offs1, Offs2, Offs3) then
    begin
      { we found one, remove it from the description and add it to the parameter list }
      DescriptionExtractTag(FDetailedDescription, Offs1, Offs2, Offs3, s);
      l := length(DetailedDescription);
      if s <> '' then begin
        FRaises.Add(s);
      end;
    end;
    Inc(Offs1);
  end;
end;

procedure TPasMethod.HandleParamTag;
var
  Offs1: Integer;
  Offs2: Integer;
  Offs3: Integer;
  s: string;
  l: Integer;
begin
  if DetailedDescription = '' then Exit;
  Offs1 := 1;
  l := Length(DetailedDescription);
  { we could have more than one exception, so repeat until we have all }
  while Offs1 < l do begin
    if (DetailedDescription[Offs1] = '@') and
      DescriptionFindTag(DetailedDescription, 'PARAM', Offs1, Offs2, Offs3) then
    begin
      { we found one, remove it from the description and add it to the parameter list }
      DescriptionExtractTag(FDetailedDescription, Offs1, Offs2, Offs3, s);
      l := length(DetailedDescription);
      if s <> '' then begin
        FParams.Add(s);
      end;
    end;
    Inc(Offs1);
  end;
end;

procedure TPasMethod.HandleReturnsTag;
var
  Offs1: Integer;
  Offs2: Integer;
  Offs3: Integer;
  s: string;
begin
  if DetailedDescription = '' then Exit;
  Offs1 := 1;

  while Offs1 < Length(DetailedDescription) do begin
    if (DetailedDescription[Offs1] = '@') and
      (DescriptionFindTag(DetailedDescription, 'RETURN', Offs1, Offs2, Offs3) or
       DescriptionFindTag(DetailedDescription, 'RETURNS', Offs1, Offs2, Offs3)) then
    begin
      DescriptionExtractTag(FDetailedDescription, Offs1, Offs2, Offs3, s);
      if (Length(s) <= 0) then Continue;
        FReturns := s;
      Exit;
    end;
    Inc(Offs1);
  end;
end;

procedure TPasItem.Deserialize(const ASource: TStream);
begin
  inherited;
  Name := LoadStringFromStream(ASource);
  Description := LoadStringFromStream(ASource);
  DetailedDescription := LoadStringFromStream(ASource);
  FullLink := LoadStringFromStream(ASource);
  LastMod := LoadStringFromStream(ASource);
  ASource.Read(FState, SizeOf(State));
  ASource.Read(FDeprecated, SizeOf(IsDeprecated));
  ASource.Read(FPlatform, SizeOf(IsPlatform));
  Authors.Text := LoadStringFromStream(ASource);
  FCreated := LoadStringFromStream(ASource);
end;

procedure TPasItem.Serialize(const ADestination: TStream);
begin
  SaveStringToStream(Name, ADestination);
  SaveStringToStream(Description, ADestination);
  SaveStringToStream(DetailedDescription, ADestination);
  SaveStringToStream(FullLink, ADestination);
  SaveStringToStream(LastMod, ADestination);
  ADestination.Write(FState, SizeOf(State));
  ADestination.Write(FDeprecated, SizeOf(IsDeprecated));
  ADestination.Write(FPlatform, SizeOf(IsPlatform));
  SaveStringToStream(Authors.Text, ADestination);
  SaveStringToStream(Created, ADestination);
end;

procedure TPasMethod.Deserialize(const ASource: TStream);
begin
  inherited;
  Params.Text := LoadStringFromStream(ASource);
  FReturns := LoadStringFromStream(ASource);
  FRaises.Text := LoadStringFromStream(ASource);
  FFullDecl := LoadStringFromStream(ASource);
  ASource.Read(FWhat, SizeOf(FWhat));
end;

procedure TPasMethod.Serialize(const ADestination: TStream);
begin
  inherited;
  SaveStringToStream(Params.Text, ADestination);
  SaveStringToStream(FReturns, ADestination);
  SaveStringToStream(FRaises.Text, ADestination);
  SaveStringToStream(FFullDecl, ADestination);
  ADestination.Write(FWhat, SizeOf(FWhat));
end;

constructor TPasMethod.Create;
begin
  inherited;
  FParams := TStringVector.Create;
  FRaises := TStringVector.Create;
end;

procedure TPasMethod.SetParams(const Value: TStringVector);
begin
  FParams.Assign(Value);
end;

{ TPasVarConst }

procedure TPasVarConst.Deserialize(const ASource: TStream);
begin
  inherited;
  FullDeclaration := LoadStringFromStream(ASource);
end;

procedure TPasVarConst.Serialize(const ADestination: TStream);
begin
  inherited;
  SaveStringToStream(FullDeclaration, ADestination);
end;

procedure TPasItems.Clear;
begin
  if Assigned(FHash) then begin
    // not assigned if destroying
    FHash.Free;
    FHash := TObjectHash.Create;
  end;
  inherited;
end;

procedure TPasItems.Deserialize(const ASource: TStream);
var
  LCount: Integer;
begin
  Clear;
  ASource.Read(LCount, SizeOf(LCount));
  while LCount>0 do begin
    Add(TPasItem(TPasItem.DeserializeObject(ASource)));
    Dec(LCount);
  end;
end;

procedure TPasItems.Serialize(const ADestination: TStream);
var
  LCount: Integer;
begin
  LCount := Count;
  ADestination.Write(LCount, SizeOf(LCount));
  while LCount > 0 do begin
    Dec(LCount);
    TSerializable.SerializeObject(PasItemAt[LCount], ADestination);
  end;
end;

{ TPasProperty }

procedure TPasProperty.Deserialize(const ASource: TStream);
begin
  inherited;
  ASource.Read(FDefault, SizeOf(FDefault));
  ASource.Read(FNoDefault, SizeOf(FNoDefault));
  FIndexDecl := LoadStringFromStream(ASource);
  FStoredID := LoadStringFromStream(ASource);
  FDefaultID := LoadStringFromStream(ASource);
  FWriter := LoadStringFromStream(ASource);
  FFullDeclaration := LoadStringFromStream(ASource);
  FPropType := LoadStringFromStream(ASource);
  FReader := LoadStringFromStream(ASource);
end;

procedure TPasProperty.Serialize(const ADestination: TStream);
begin
  inherited;
  ADestination.Write(FDefault, SizeOf(FDefault));
  ADestination.Write(FNoDefault, SizeOf(FNoDefault));
  SaveStringToStream(FIndexDecl, ADestination);
  SaveStringToStream(FStoredID, ADestination);
  SaveStringToStream(FDefaultID, ADestination);
  SaveStringToStream(FWriter, ADestination);
  SaveStringToStream(FFullDeclaration, ADestination);
  SaveStringToStream(FPropType, ADestination);
  SaveStringToStream(FReader, ADestination);
end;

procedure TPasUnit.Deserialize(const ASource: TStream);
begin
  inherited;
  FTypes.Deserialize(ASource);
  FVariables.Deserialize(ASource);
  FCIOs.Deserialize(ASource);
  FConstants.Deserialize(ASource);
  FFuncsProcs.Deserialize(ASource);
  FUsesUnits.Text := LoadStringFromStream(ASource);
  FSourceFilename := LoadStringFromStream(ASource);
  FOutputFileName := LoadStringFromStream(ASource);
  FSourceFileDate := LoadDoubleFromStream(ASource);
end;

procedure TPasUnit.Serialize(const ADestination: TStream);
begin
  inherited;
  FTypes.Serialize(ADestination);
  FVariables.Serialize(ADestination);
  FCIOs.Serialize(ADestination);
  FConstants.Serialize(ADestination);
  FFuncsProcs.Serialize(ADestination);
  SaveStringToStream(FUsesUnits.Text, ADestination);
  SaveStringToStream(FSourceFilename, ADestination);
  SaveStringToStream(FOutputFileName, ADestination);
  SaveDoubleToStream(SourceFileDate, ADestination);
end;

initialization
  TSerializable.Register(TPasItem);
  TSerializable.Register(TPasVarConst);
  TSerializable.Register(TPasEnum);
  TSerializable.Register(TPasMethod);
  TSerializable.Register(TPasProperty);
  TSerializable.Register(TPasCio);
  TSerializable.Register(TPasUnit);
end.
