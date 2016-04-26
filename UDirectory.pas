unit UDirectory;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Forms, DBGrids, ComCtrls, UAbout, UFilterPanel, StdCtrls, UCard, UDBForm,
  UDBConnection, DB, UDBObjects, Dialogs, Controls, Classes;

type

  TFilterPanel = UFilterPanel.TFilterPanel;

  TFilterForm = class(TDBForm)
  protected
    FFilterPanels: TFilterPanels;
    procedure BeforeFilterDelete(FilterIndex: integer); virtual;
    procedure UpdateFilters;
    procedure DeleteFilters;
  public
    procedure AddFilterPanel(AFilterPanel: TFilterPanel); virtual;
    function FiltersCorrect: boolean;
    function FilterCount: integer;
    function ApplyFilters: boolean;
  published
    procedure FormCreate(Sender: TObject); override;
  end;

  TDirectory = class(TFilterForm)
  private
    FFocus: TPoint;
    procedure OnFiltersChange;
    procedure UpdateColumns;
    procedure CreateCard(CardType: TDBFormType);
    procedure NotificationRecieve(Sender: TObject);
    procedure MemFocus;
    procedure RestoreFocus;
    function FormHash: integer;
  protected
    procedure BeforeFilterDelete(FilterIndex: integer); override;
  public
    procedure InitConnection(DBConnection: TDbConnection); override;
    procedure Load(ANClass: TNClass; ATable: TDBTable; Params: TParams = nil); override;
    procedure AddFilterPanel(AFilterPanel: TFilterPanel); override;
  published
    FFiltersGBox: TGroupBox;
    FTableGBox: TGroupBox;
    FStatusBar: TStatusBar;
    FDBGrid: TDBGrid;
    FFiltersSBox: TScrollBox;
    FAddFilterBtn: TButton;
    FApplyBtn: TButton;
    FDelAllFiltersBtn: TButton;
    FAddElement: TButton;
    FDelElement: TButton;
    procedure FDBGridCellClick(Column: TColumn);
    procedure FAddElementClick(Sender: TObject);
    procedure FDBGridDblClick(Sender: TObject);
    procedure FDelElementClick(Sender: TObject);
    procedure FDelAllFiltersBtnClick(Sender: TObject);
    procedure FAddFilterBtnClick(Sender: TObject);
    procedure FApplyBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject); override;
  end;

implementation

{$R *.lfm}

procedure TFilterForm.FormCreate(Sender: TObject);
begin
  inherited FormCreate(Sender);
  FFilterPanels := TFilterPanels.Create;
end;

procedure TFilterForm.AddFilterPanel(AFilterPanel: TFilterPanel);
begin
  AFilterPanel.Index := FFilterPanels.Size;
  FFilterPanels.PushBack(AFilterPanel);
  AFilterPanel.BeforeDelete := @BeforeFilterDelete;
end;

procedure TFilterForm.UpdateFilters;
var
  i: integer;
begin
  for i := 0 to FFilterPanels.Size - 1 do begin
    FFilterPanels[i].Top := 5 + i * 25;
    FFilterPanels[i].Index := i;
  end;
end;

procedure TFilterForm.DeleteFilters;
var
  i: integer = 0;
  Size: integer;
begin
  if FFilterPanels.Size > 0 then begin
    if FiltersCorrect then
      if MessageDlg('Вы действительно хотите удалить все фильтры?',
        mtConfirmation, mbOKCancel, 0) = mrCancel then
        Exit;
    Size := FFilterPanels.Size;
    while i < Size do begin
      if FFilterPanels[i].Enabled then begin
        FFilterPanels[i].Free;
        FFilterPanels.DeleteIndS(i);
        i -= 1;
        Size -= 1;
      end;
      i += 1;
    end;
  end;
end;

function TFilterForm.FiltersCorrect: boolean;
var
  i: integer;
begin
  for i := 0 to FFilterPanels.Size - 1 do
    if not FFilterPanels[i].Correct then
      Exit(False);
  Exit(True);
end;

function TFilterForm.FilterCount: integer;
begin
  Exit(FFilterPanels.Size);
end;

function TFilterForm.ApplyFilters: boolean;
var
  Filters: TDBFilters;
  i: integer;
begin
  if FFilterPanels.Size > 0 then begin
    if not FiltersCorrect then begin
      ShowMessage('Нужно заполнить все фильтры');
      Exit;
    end;
    Filters := TDBFilters.Create;
    for i := 0 to FFilterPanels.Size - 1 do
      Filters.PushBack(FFilterPanels.Items[i].Filter);
    PerformQuery(Table.Query.Select(Filters));
    Exit(True);
  end
  else
    PerformQuery(FSelectAll);
  Exit(False);
end;

procedure TFilterForm.BeforeFilterDelete(FilterIndex: integer);
begin
  if FFilterPanels.Size > 0 then begin
    FFilterPanels.DeleteIndS(FilterIndex);
    UpdateFilters;
  end;
end;

procedure TDirectory.FormCreate(Sender: TObject);
begin
  inherited FormCreate(Sender);
  Constraints.MinWidth := 350;
  Constraints.MinHeight := 20;
  DoubleBuffered := True;
  FApplyBtn.Enabled := True;
  OnPerformQuery := @UpdateColumns;
  FFocus.X := 0;
  FFocus.Y := 1;
end;

procedure TDirectory.Load(ANClass: TNClass; ATable: TDBTable; Params: TParams = nil);
begin
  inherited Load(ANClass, ATable);
  ThisSubscriber.OnNotificationRecieve := @NotificationRecieve;
  Caption := APP_CAPTION + ' - ' + Table.Name;
  PerformQuery(FSelectAll);
  MemFocus;
end;

procedure TDirectory.FAddFilterBtnClick(Sender: TObject);
begin
  AddFilterPanel(TFilterPanel.Create(Table));
  FApplyBtn.Enabled := True;
end;

procedure TDirectory.BeforeFilterDelete(FilterIndex: integer);
begin
  if FFilterPanels[FilterIndex].Correct or (FFilterPanels.Size = 0) then
    FApplyBtn.Enabled := True;
  inherited BeforeFilterDelete(FilterIndex);
end;

procedure TDirectory.AddFilterPanel(AFilterPanel: TFilterPanel);
begin
  AFilterPanel.InitControls(FFiltersSBox, 5 + FilterCount * 25, 5);
  AFilterPanel.OnChange := @OnFiltersChange;
  inherited AddFilterPanel(AFilterPanel);
  FApplyBtn.Enabled := True;
end;

procedure TDirectory.FApplyBtnClick(Sender: TObject);
begin
  if ApplyFilters then
    FApplyBtn.Enabled := False;
end;

procedure TDirectory.FDelAllFiltersBtnClick(Sender: TObject);
begin
  DeleteFilters;
  FApplyBtn.Enabled := True;
end;

procedure TDirectory.FDelElementClick(Sender: TObject);
var
  Index: integer;
begin
  Index := FormQuery.Fields[0].Value;
  ExecQuery(Table.Query.Delete(Index));
  ThisSubscriber.CreateNotification(nil, ThisSubscriber.NClass);
end;

procedure TDirectory.FAddElementClick(Sender: TObject);
begin
  CreateCard(TInsertCard);
end;

procedure TDirectory.FDBGridDblClick(Sender: TObject);
begin
  CreateCard(TEditCard);
end;

procedure TDirectory.FDBGridCellClick(Column: TColumn);
begin
  MemFocus;
end;

procedure TDirectory.OnFiltersChange;
begin
  FApplyBtn.Enabled := True;
end;

procedure TDirectory.UpdateColumns;
var
  i: integer;
begin
  for i := 0 to FDBGrid.Columns.Count - 1 do
    Table.Fields[i].Load(FDBGrid.Columns[i]);
end;

procedure TDirectory.CreateCard(CardType: TDBFormType);
var
  TargetIndex: integer;
  Params: TParams;
begin
  TargetIndex := FormQuery.Fields[0].Value;
  Params := TParams.Create;
  Params.CreateParam(ftInteger, 'Target', ptUnknown);
  Params.ParamByName('Target').AsInteger := TargetIndex;
  CreateChildForm(ThisSubscriber.NClass, Table, CardType, Params, FormHash);
end;

procedure TDirectory.NotificationRecieve(Sender: TObject);
begin
  if FFilterPanels.Size > 0 then
    ApplyFilters
  else
    PerformQuery(FSelectAll);
  RestoreFocus;
end;

procedure TDirectory.MemFocus;
begin
  FFocus.X := FDBGrid.SelectedIndex;
  FFocus.Y := FDBGrid.DataSource.DataSet.RecNo;
end;

procedure TDirectory.RestoreFocus;
var
  RecCount: integer;
begin
  RecCount := FDBGrid.DataSource.DataSet.RecordCount;
  if RecCount > 0 then begin
    if FFocus.Y > RecCount then
      FFocus.Y := RecCount;
    FDBGrid.DataSource.DataSet.RecNo := FFocus.Y;
    FDBGrid.SelectedIndex := FFocus.X;
  end;
end;

function TDirectory.FormHash: integer;
begin
  Result := (FormQuery.Fields[0].AsInteger + 3);
  Result *= Result * (Result + 1);
  Result *= (FDBGrid.SelectedIndex + 11);
  Result *= Result;
end;

procedure TDirectory.InitConnection(DBConnection: TDbConnection);
begin
  inherited InitConnection(DBConnection);
  FDBGrid.DataSource := DataSource;
  FDBGrid.ReadOnly := True;
  FStatusBar.SimpleText := DBConnection.CurrentConnection;
end;

end.
