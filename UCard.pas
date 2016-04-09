unit UCard;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, StdCtrls, ComCtrls, sqldb, UDb, UCardControls, DB,
  UAbout, UDBForm, Dialogs, UDBObjects, UNotifications;

type

  { TCard }

  TCard = class(TDBForm)
  private
    FTop: integer;
    FLeft: integer;
    FControls: TControls;
    FRecordIndex: integer;
    FCboxNotifications: TSubscriber;
    function Correct: boolean;
    procedure LoadGUIControls;
    procedure SubscribeCBoxes;
    procedure LoadInterface; virtual; abstract;
    procedure Recreate;
    procedure OnNotificationRecieve(Sender: TObject);
  public
    procedure Load(ANotificationClass: TNotificationClass; ATable: TDBTable;
      Params: TParams = nil); override;
  published
    FStatusBar: TStatusBar;
    FApplyBtn: TButton;
    FCancelBtn: TButton;
    procedure FormCreate(Sender: TObject); override;
    procedure FApplyBtnClick(Sender: TObject); virtual; abstract;
    procedure FCancelBtnClick(Sender: TObject);
  end;

  TEditCard = class(TCard)
  private
    procedure UpdateTable;
    procedure LoadInterface; override;
  published
    procedure FApplyBtnClick(Sender: TObject); override;
  end;

  TInsertCard = class(TCard)
  private
    procedure TableInsert;
    procedure LoadInterface; override;
  published
    procedure FApplyBtnClick(Sender: TObject); override;
  end;

implementation

{$R *.lfm}

{ TCard }

procedure TCard.FormCreate(Sender: TObject);
begin
  inherited FormCreate(Sender);
  Self.Constraints.MinHeight := Self.Height;
  Self.Constraints.MaxHeight := Self.Height;
  Self.Constraints.MinWidth := Self.Width;
  FTop := 20;
  FLeft := 32;
end;

procedure TCard.Load(ANotificationClass: TNotificationClass; ATable: TDBTable;
  Params: TParams = nil);
begin
  Table := ATable;
  Self.Caption := APP_NAME + CURRENT_VERSION + ' - ' + Table.Name;
  Recreate;
  FRecordIndex := Params.ParamByName('Target').AsInteger;
  inherited Load(ANotificationClass, ATable);
  FSelectAll := Table.Select
  (
    TDBFilters.Create
    (
      TDBFilter.Create(Table.Front, ' = ', IntToStr(FRecordIndex))
    )
  );
  LoadGUIControls;
  LoadInterface;
end;

procedure TCard.SubscribeCBoxes;
var
  SameTable: TDBTable = nil;
  NClass: integer = 1;
  i: integer = 1;
begin
  With Table do
    while i < Count - 1 do begin
      if Fields[i].ParentTable = Fields[i + 1].ParentTable then begin
        SameTable := Fields[i].ParentTable;
        while (i < Count) and (Fields[i].ParentTable = SameTable) do begin
          FControls.Items[i - 1].Subscriber.NotificationClass := ToNotificationClass([NClass]);
          FCboxNotifications.Subscribe(FControls.Items[i - 1].Subscriber);
          i += 1;
        end;
        NClass += 1;
      end;
      i += 1;
    end;
end;

procedure TCard.LoadGUIControls;
var
  i: integer;
  Control: TDBControl;
  FieldIndex: integer = 1;
  SameFieldLeft: boolean = False;
begin
  with Table do
    for i := 1 to Count - 1 do begin
      Control := Fields[i].CreateControl;
      PerformQuery(Fields[i].ParentTable.Select(nil));
      SameFieldLeft := Fields[i - 1].ParentTable = Fields[i].ParentTable;

      if SameFieldLeft then
        FieldIndex += 1
      else
        FieldIndex := 2;

      Control.CreateGUI(Self, FTop, FLeft);
      while not Query.EOF do begin
        Control.LoadData
        (
          Query.Fields.FieldByNumber(FieldIndex).Value,
          Query.Fields.FieldByNumber(1).Value
        );
        Query.Next;
      end;
      FControls.PushBack(Control);
      FTop += 25;
    end;
  SubscribeCBoxes;
end;

function TCard.Correct: boolean;
var
  i: integer;
begin
  for i := 0 to FControls.Size - 1 do
    if FControls.Items[i].Correct = False then
      Exit(False);
  Exit(True);
end;

procedure TCard.Recreate;
var
  i: integer;
begin
  FTop := 20;
  FLeft := 32;
  for i := 3 to Self.ComponentCount - 1 do
    Self.Controls[3].Free;
  FControls.Free;
  FCboxNotifications.Free;
  FCboxNotifications := TSubscriber.Create(True);
  FControls := TControls.Create;
end;

procedure TCard.OnNotificationRecieve(Sender: TObject);
var
  Params: TParams;
begin
  Params := TParams.Create;
  Params.CreateParam(ftInteger, 'Target', ptUnknown);
  Params.ParamByName('Target').AsInteger := FRecordIndex;
  Self.Load(ThisSubscriber.NotificationClass, Table, Params);
end;

procedure TCard.FCancelBtnClick(Sender: TObject);
begin
  ThisSubscriber.Parent.UnSubscribe(ThisSubscriber);
  Close;
end;

procedure TEditCard.UpdateTable;
var
  i: integer;
begin
  for i := 0 to FControls.Size - 1 do
    ExecQuery(FControls.Items[i].UpdateTable);
end;

procedure TEditCard.LoadInterface;
var
  i: integer;
begin
  PerformQuery(FSelectAll);
  for i := 0 to FControls.Size - 1 do
    FControls.Items[i].Caption := Query.Fields[i + 1].Value;
end;

procedure TEditCard.FApplyBtnClick(Sender: TObject);
begin
  if not Correct then begin
    ShowMessage('Нужно заполнить все поля.');
    Exit;
  end;
  UpdateTable;
  ThisSubscriber.CreateNotification(nil, ThisSubscriber.NotificationClass);
  Close;
end;

procedure TInsertCard.TableInsert;
var
  Values: TParams;
  i: integer;
begin
   Values := TParams.Create;
   for i := 0 to FControls.Size - 1 do
     Values.AddParam(FControls.Items[i].Data);
   ExecQuery(Table.Insert(Values));
end;

procedure TInsertCard.LoadInterface;
var
  i: integer;
begin
  for i := 0 to FControls.Size - 1 do
    FControls.Items[i].Clear;
end;

procedure TInsertCard.FApplyBtnClick(Sender: TObject);
begin
  if not Correct then begin
    ShowMessage('Нужно заполнить все поля.');
    Exit;
  end;
  TableInsert;
  ThisSubscriber.CreateNotification(nil, ThisSubscriber.NotificationClass);
  Close;
end;

end.
