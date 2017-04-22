{{
—————————————————————————————————————————————————————————————————————————
 Project : Synopse Replication Test

 Using mORMot
     Synopse mORMot framework. Copyright (C) 2017 Arnaud Bouchez
     Synopse Informatique - http://synopse.info

  Module : SynTestTest1

  Last modified
    Date : 22.04.2017 09:07:47
  Author : Martin Doyle
   Email : martin.doyle@dakata.de
—————————————————————————————————————————————————————————————————————————

Test taken from SynSelfTests.pas
—————————————————————————————————————————————————————————————————————————
}
unit SynTestTest1;

interface
uses
  SysUtils, SynCommons, SynSQLite3, SynSQLite3Static, mORMot, mORMotSQLite3, SynTests;

type
  TSQLRecordPeople = class(TSQLRecord)
  private
    FData: TSQLRawBlob;
    FFirstName: RawUTF8;
    FLastName: RawUTF8;
    FYearOfBirth: Integer;
    FYearOfDeath: Word;
  published
    property Data: TSQLRawBlob read FData write FData;
    property FirstName: RawUTF8 read FFirstName write FFirstName;
    property LastName: RawUTF8 read FLastName write FLastName;
    property YearOfBirth: Integer read FYearOfBirth write FYearOfBirth;
    property YearOfDeath: Word read FYearOfDeath write FYearOfDeath;
  end;

  TSQLRecordPeopleVersioned = class(TSQLRecordPeople)
  protected
    FVersion: TRecordVersion;
  published
    property Version: TRecordVersion read FVersion write FVersion;
  end;

  TTestReplication = class(TSynTestCase)
  published
    procedure TestAddTenAndDeleteFirstRecord;
    procedure TestAddTenAndDeleteLastRecord;
    procedure TestAddOneAndDeleteRecord;
  end;

  TTestSuite = class(TSynTestsLogged)
  published
    procedure TestSuite;
  end;

implementation

procedure TestMasterSlave(Test: TSynTestCase; Master,Slave: TSQLRestServer; SynchronizeFromMaster: TSQLRest);
var res: TRecordVersion;
    Rec1,Rec2: TSQLRecordPeopleVersioned;
begin
  if SynchronizeFromMaster<>nil then
    res := Slave.RecordVersionSynchronizeSlave(TSQLRecordPeopleVersioned,SynchronizeFromMaster,500) else
    res := Slave.RecordVersionCurrent;
  Test.Check(res=Master.RecordVersionCurrent);
  Rec1 := TSQLRecordPeopleVersioned.CreateAndFillPrepare(Master,'order by ID','*');
  Rec2 := TSQLRecordPeopleVersioned.CreateAndFillPrepare(Slave,'order by ID','*');
  try
    Test.Check(Rec1.FillTable.RowCount=Rec2.FillTable.RowCount, 'RowCount Master: ' +  IntToStr(Rec1.FillTable.RowCount) + ' Slave: ' + IntToStr(Rec2.FillTable.RowCount));
    while Rec1.FillOne do begin
      Test.Check(Rec2.FillOne);
      Test.Check(Rec1.SameRecord(Rec2), 'SameRecord ID Master: ' +  IntToStr(Rec1.ID) + ' Slave: ' + IntToStr(Rec2.ID));
      Test.Check(Rec1.Version=Rec2.Version, 'Version Master: ' +  IntToStr(Rec1.Version) + ' Slave: ' + IntToStr(Rec2.Version));
    end;
  finally
    Rec1.Free;
    Rec2.Free;
  end;
end;

function CreateServer(var Model: TSQLModel; const DBFileName: TFileName; DeleteDBFile: boolean): TSQLRestServerDB;
begin
  if DeleteDBFile then
    DeleteFile(DBFileName);
  result := TSQLRestServerDB.Create(Model,DBFileName,false,'');
  result.DB.Synchronous := smOff;
  result.DB.LockingMode := lmExclusive;
  result.CreateMissingTables;
end;

procedure CreateMaster(var Model: TSQLModel; var Master: TSQLRestServerDB; var MasterAccess: TSQLRestClientURI; DeleteDBFile: Boolean);
begin
  Master := CreateServer(Model, 'testmaster.db3', DeleteDBFile);
  MasterAccess := TSQLRestClientDB.Create(Master);
end;

{
******************************* TTestReplication *******************************
}
procedure TTestReplication.TestAddTenAndDeleteFirstRecord;
var
  Model: TSQLModel;
  Master, Slave: TSQLRestServerDB;
  MasterAccess: TSQLRestClientURI;
  Rec: TSQLRecordPeopleVersioned;
  i, n: Integer;
  FirstID: TID;
begin
  Model := TSQLModel.Create(
    [TSQLRecordPeopleVersioned,TSQLRecordTableDeleted],'root0');
  CreateMaster(Model, Master, MasterAccess, true);
  Slave := CreateServer(Model, 'testversionreplicated.db3',true);
  try
    Rec := TSQLRecordPeopleVersioned.CreateAndFillPrepare(StringFromFile('Test1.json'));
    try
      TestMasterSlave(self, Master,Slave,MasterAccess);
      n := Rec.FillTable.RowCount;
      Check(n>100);
      // Add the first record
      Check(Rec.FillOne);
      // Keep the first ID
      FirstID := Rec.ID;
      // Add 9 additional records
      for i := 0 to 8 do begin
        Check(Rec.FillOne);
        Master.Add(Rec,true,true);
      end;
      TestMasterSlave(self, Master,Slave,MasterAccess);
      Master.Free;
      MasterAccess.Free;
      CreateMaster(Model, Master, MasterAccess, false);
      // Delete the first record
      Master.Delete(TSQLRecordPeopleVersioned, FirstID);
      TestMasterSlave(self, Master,Slave,MasterAccess);
    finally
      Rec.Free;
    end;
  finally
    Slave.Free;
    MasterAccess.Free;
    Master.Free;
    Model.Free;
  end;
end;

procedure TTestReplication.TestAddTenAndDeleteLastRecord;
var
  Model: TSQLModel;
  Master, Slave: TSQLRestServerDB;
  MasterAccess: TSQLRestClientURI;
  Rec: TSQLRecordPeopleVersioned;
  i, n: Integer;
  LastID: TID;
begin
  Model := TSQLModel.Create(
    [TSQLRecordPeopleVersioned,TSQLRecordTableDeleted],'root0');
  CreateMaster(Model, Master, MasterAccess, true);
  Slave := CreateServer(Model, 'testversionreplicated.db3',true);
  try
    Rec := TSQLRecordPeopleVersioned.CreateAndFillPrepare(StringFromFile('Test1.json'));
    try
      TestMasterSlave(self, Master,Slave,MasterAccess);
      n := Rec.FillTable.RowCount;
      Check(n>100);
      // Add 10 records
      for i := 0 to 9 do begin
        Check(Rec.FillOne);
        Master.Add(Rec,true,true);
      end;
      // Keep the last ID
      LastID := Rec.ID;
      TestMasterSlave(self, Master,Slave,MasterAccess);
      Master.Free;
      MasterAccess.Free;
      CreateMaster(Model, Master, MasterAccess, false);
      // Delete the last record
      Master.Delete(TSQLRecordPeopleVersioned, LastID);
      TestMasterSlave(self, Master,Slave,MasterAccess);
    finally
      Rec.Free;
    end;
  finally
    Slave.Free;
    MasterAccess.Free;
    Master.Free;
    Model.Free;
  end;
end;

procedure TTestReplication.TestAddOneAndDeleteRecord;
var
  Model: TSQLModel;
  Master, Slave: TSQLRestServerDB;
  MasterAccess: TSQLRestClientURI;
  Rec: TSQLRecordPeopleVersioned;
  n: Integer;
  ID: TID;
begin
  Model := TSQLModel.Create(
    [TSQLRecordPeopleVersioned,TSQLRecordTableDeleted],'root0');
  CreateMaster(Model, Master, MasterAccess, true);
  Slave := CreateServer(Model, 'testversionreplicated.db3',true);
  try
    Rec := TSQLRecordPeopleVersioned.CreateAndFillPrepare(StringFromFile('Test1.json'));
    try
      TestMasterSlave(self, Master,Slave,MasterAccess);
      n := Rec.FillTable.RowCount;
      Check(n>100);
      // Add one record
      Check(Rec.FillOne);
      Master.Add(Rec,true,true);
      // Keep the ID
      ID := Rec.ID;
      TestMasterSlave(self, Master,Slave,MasterAccess);
      Master.Free;
      MasterAccess.Free;
      CreateMaster(Model, Master, MasterAccess, false);
      // Delete the record again
      Master.Delete(TSQLRecordPeopleVersioned, ID);
      TestMasterSlave(self, Master,Slave,MasterAccess);
    finally
      Rec.Free;
    end;
  finally
    Slave.Free;
    MasterAccess.Free;
    Master.Free;
    Model.Free;
  end;
end;

{
********************************** TTestSuite **********************************
}
procedure TTestSuite.TestSuite;
begin
  AddCase([TTestReplication]);
end;


end.
