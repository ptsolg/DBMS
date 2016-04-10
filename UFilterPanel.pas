unit UFilterPanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, Controls, ExtCtrls, Graphics, DB, UDBObjects;

type

  TEvent = procedure of object;

  TFilterPanel = class(TPanel)
  strict private
    type
    TOperator = record
      Name: string;
      COperator: string;
    end;
    TOperators = array of TOperator;
  private
    FIndex: integer;
    FFilter: TDBFilter;
    FFieldsCBox: TComboBox;
    FOpsCBox: TComboBox;
    FEdit: TEdit;
    FTable: TDBTable;
    FCurrentOperators: TOperators;
    FNumOperators: TOperators;
    FStrOperators: TOperators;
    FOnChangeEvent: TEvent;
    procedure InitGUI(AParent: TWinControl; ATop, ALeft: integer);
    procedure Init(Component, AParent: TWinControl; ATop, ALeft, AWidth: integer);
    procedure InitOperators;
    procedure AddOperator(var Operators: TOperators; AName, ACOperator: string);
    procedure Load(Table: TDBTable);
    procedure LoadOperators(Operators: TOperators);
    procedure OnChangeEvent(Sender: TObject);
    procedure OnFieldsCBoxChange(Sender: TObject);
  public
    constructor Create(Table: TDBTable; AParent: TWinControl; ATop, ALeft: integer);
    function Correct: boolean;
  published
    property OnChange: TEvent write FOnChangeEvent;
    property Filter: TDBFilter read FFilter;
    property Index: integer read FIndex write FIndex;
  end;

implementation

constructor TFilterPanel.Create(Table: TDBTable; AParent: TWinControl;
  ATop, ALeft: integer);
begin
  InitGUI(AParent, ATop, ALeft);
  FFieldsCBox.OnSelect := @OnFieldsCBoxChange;
  FOpsCBox.OnChange := @OnChangeEvent;
  FEdit.OnChange := @OnChangeEvent;
  FFilter := TDBFilter.Create;
  FFilter.Assign(Table.Fields[0]);
  InitOperators;
  Load(Table);
end;

function TFilterPanel.Correct: boolean;
begin
  if FEdit.Text <> '' then
    Exit(True);
  Exit(False);
end;

procedure TFilterPanel.InitGUI(AParent: TWinControl; ATop, ALeft: integer);
const
  SPACE = 5;
  FIELDS_CBOX_WIDTH = 150;
  OPS_CBOX_WIDTH = 100;
  EDIT_WIDTH = 150;
  TOTAL_WIDTH = SPACE * 4 + FIELDS_CBOX_WIDTH + OPS_CBOX_WIDTH + EDIT_WIDTH;
begin
  inherited Create(AParent);
  Init(Self, AParent, ATop - 1, ALeft, TOTAL_WIDTH);
  Self.Height := 25;
  Self.BevelInner := bvNone;
  Self.BevelOuter := bvNone;
  FFieldsCBox := TComboBox.Create(Self);
  FOpsCBox := TComboBox.Create(Self);
  FEdit := TEdit.Create(Self);
  FFieldsCBox.ReadOnly := True;
  FOpsCBox.ReadOnly := True;
  Init(FFieldsCBox, Self, 1, 0, FIELDS_CBOX_WIDTH);
  Init(FOpsCBox, Self, 1, FIELDS_CBOX_WIDTH + SPACE, OPS_CBOX_WIDTH);
  Init(FEdit, Self, 1, FOpsCBox.Left + OPS_CBOX_WIDTH + SPACE, EDIT_WIDTH);
end;

procedure TFilterPanel.InitOperators;
begin
  AddOperator(FNumOperators, 'Равно', ' = ');
  AddOperator(FNumOperators, 'Больше', ' > ');
  AddOperator(FNumOperators, 'Меньше', ' < ');
  AddOperator(FStrOperators, 'Содержит', ' Containing ');
  AddOperator(FStrOperators, 'Не содержит', ' Not Containing ');
  AddOperator(FStrOperators, 'Начинается с', ' Starting With ');
end;

procedure TFilterPanel.Init(Component, AParent: TWinControl;
  ATop, ALeft, AWidth: integer);
begin
  Component.Parent := AParent;
  Component.Top := ATop;
  Component.Left := ALeft;
  Component.Width := AWidth;
end;

procedure TFilterPanel.Load(Table: TDBTable);
var
  i: integer;
begin
  FTable := Table;
  for i := 0 to FTable.Count - 1 do
    FFieldsCBox.Items.Add(FTable.Fields[i].Name);
  FFieldsCBox.ItemIndex := 0;
  LoadOperators(FNumOperators);
end;

procedure TFilterPanel.LoadOperators(Operators: TOperators);
var
  i: integer;
begin
  FOpsCBox.Items.Clear;
  for i := 0 to High(Operators) do
    FOpsCBox.Items.Add(Operators[i].Name);
  FCurrentOperators := Operators;
  FOpsCBox.ItemIndex := 0;
  FEdit.NumbersOnly := True;
end;

procedure TFilterPanel.OnChangeEvent(Sender: TObject);
begin
  FFilter.Assign(FTable.Fields[FFieldsCBox.ItemIndex]);
  FFilter.ConditionalOperator := FCurrentOperators[FOpsCBox.ItemIndex].COperator;
  FFilter.Param := FEdit.Text;
  if FOnChangeEvent <> nil then
    FOnChangeEvent;
end;

procedure TFilterPanel.OnFieldsCBoxChange(Sender: TObject);
begin
  with FTable.Fields[FFieldsCBox.ItemIndex] do begin
    if DataType = ftInteger then begin
      LoadOperators(FNumOperators);
      FEdit.NumbersOnly := True;
    end;
    if DataType = ftString then begin
      LoadOperators(FStrOperators);
      FEdit.NumbersOnly := False;
    end;
  end;
  if FOnChangeEvent <> nil then
    FOnChangeEvent;
end;

procedure TFilterPanel.AddOperator(var Operators: TOperators; AName, ACOperator: string);
begin
  SetLength(Operators, Length(Operators) + 1);
  Operators[High(Operators)].Name := AName;
  Operators[High(Operators)].COperator := ACOperator;
end;

end.